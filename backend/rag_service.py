"""
rag_service.py – RAG (Retrieval-Augmented Generation) service for ParilGPT.

Handles:
  - Loading the ChromaDB collection
  - Embedding user queries with Mistral
  - Retrieving relevant chat context
  - Building prompt and calling Mistral LLM
"""

import time
from typing import List, Literal, Optional

import chromadb
from chromadb.config import Settings as ChromaSettings
try:
    from mistralai import Mistral
except ImportError:
    from mistralai.client import Mistral

from config import settings
from prompts import PARIL_SYSTEM_PROMPT, SAHAN_SYSTEM_PROMPT

COLLECTION_NAME = "parilgpt_chat"
MISTRAL_EMBED_MODEL = "mistral-embed"
TOP_K = 6   # How many context chunks to retrieve per query


class RAGService:
    """Singleton-style RAG service. Initialise once, reuse across requests."""

    def __init__(self):
        self._mistral = Mistral(api_key=settings.mistral_api_key)
        self._chroma = self._load_chroma()
        self._collection = self._load_collection()

    # ── Private helpers ────────────────────────────────────────────────────────

    def _load_chroma(self) -> chromadb.ClientAPI:
        import os
        persist_dir = os.path.abspath(settings.chroma_persist_dir)
        return chromadb.PersistentClient(
            path=persist_dir,
            settings=ChromaSettings(anonymized_telemetry=False),
        )

    def _load_collection(self):
        try:
            return self._chroma.get_collection(COLLECTION_NAME)
        except Exception:
            return None  # collection not yet created; ingest must be run first

    def _embed(self, text: str) -> Optional[List[float]]:
        """Embed a single text with Mistral, with retry on rate-limit or network drops."""
        for attempt in range(4):
            try:
                resp = self._mistral.embeddings.create(
                    model=MISTRAL_EMBED_MODEL,
                    inputs=[text],
                )
                return resp.data[0].embedding
            except Exception as exc:
                wait = 2 ** attempt
                print(f"[RAG] Embed attempt {attempt + 1} failed: {exc}. Retrying in {wait}s...", flush=True)
                time.sleep(wait)
        return None

    def _retrieve_context(
        self, query: str, persona: Literal["paril", "sahan"]
    ) -> str:
        """Return relevant dialogue snippets filtered by speaker."""
        if self._collection is None:
            return "(No context available - please run ingest.py first.)"

        speaker_label = "Paril" if persona == "paril" else "Sahan"
        try:
            vector = self._embed(query)
            if vector is None:
                return "(No context retrieved due to temporary network delay.)"
        except Exception:
            return "(No context retrieved.)"

        # Try to retrieve speaker-specific chunks first
        try:
            results = self._collection.query(
                query_embeddings=[vector],
                n_results=min(TOP_K, self._collection.count()),
                where={"speaker": speaker_label},
                include=["documents"],
            )
            docs = results.get("documents", [[]])[0]
        except Exception:
            docs = []

        # Fall back to unrestricted search if not enough
        if len(docs) < 3:
            try:
                results_all = self._collection.query(
                    query_embeddings=[vector],
                    n_results=min(TOP_K, self._collection.count()),
                    include=["documents"],
                )
                extra = results_all.get("documents", [[]])[0]
                # merge deduped
                seen = set(docs)
                for d in extra:
                    if d not in seen:
                        docs.append(d)
                        seen.add(d)
                docs = docs[:TOP_K]
            except Exception:
                pass

        if not docs:
            return "(No relevant chat context found.)"

        return "\n\n---\n\n".join(docs)

    # ── Public API ─────────────────────────────────────────────────────────────

    def chat(
        self,
        user_message: str,
        persona: Literal["paril", "sahan"],
        history: List[dict],
    ) -> str:
        """
        Generate a response in the given persona.

        Args:
            user_message: Latest message from the user.
            persona: "paril" or "sahan".
            history: List of previous {role, content} dicts.

        Returns:
            The AI reply as a string.
        """
        context = self._retrieve_context(user_message, persona)

        # Format history for the system prompt insertion
        history_text = ""
        if history:
            lines = []
            for msg in history[-10:]:  # last 10 turns to keep context short
                role = "User" if msg["role"] == "user" else (
                    "Paril" if persona == "paril" else "Sahan"
                )
                lines.append(f"{role}: {msg['content']}")
            history_text = "\n".join(lines)

        template = PARIL_SYSTEM_PROMPT if persona == "paril" else SAHAN_SYSTEM_PROMPT
        system_prompt = template.format(context=context, history=history_text)

        # Build messages list for Mistral chat
        messages = [{"role": "system", "content": system_prompt}]
        # Include prior history
        for msg in history[-10:]:
            messages.append({"role": msg["role"], "content": msg["content"]})
        # Append the current user message
        messages.append({"role": "user", "content": user_message})

        for attempt in range(4):
            try:
                resp = self._mistral.chat.complete(
                    model=settings.mistral_model,
                    messages=messages,
                    max_tokens=512,
                    temperature=0.85,
                )
                return resp.choices[0].message.content.strip()
            except Exception as exc:
                wait = 2 ** attempt
                print(f"[RAG] Chat attempt {attempt + 1} failed: {exc}. Retrying in {wait}s...", flush=True)
                time.sleep(wait)

        raise RuntimeError("LLM call failed after retries.")

    def is_ready(self) -> bool:
        """Returns True if the ChromaDB collection is loaded and has data."""
        try:
            return self._collection is not None and self._collection.count() > 0
        except Exception:
            return False
