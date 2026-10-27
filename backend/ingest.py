"""
ingest.py – Parse WhatsApp chat files and load them into ChromaDB.

Run this once (or when chats change):
    python ingest.py

It will:
  1. Parse both WhatsApp .txt files using chat_parser.py
  2. Split into dialogue-window chunks
  3. Embed with Mistral's free embedding endpoint
  4. Persist to ChromaDB at the configured persist directory
"""

import os
import sys
import json
import time
from typing import List

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
        sys.stderr.reconfigure(encoding='utf-8')
    except Exception:
        pass

import chromadb
from chromadb.config import Settings as ChromaSettings
try:
    from mistralai import Mistral
except ImportError:
    from mistralai.client import Mistral

from config import settings
from chat_parser import parse_whatsapp_file, group_turns_into_dialogue_chunks

# ── Constants ──────────────────────────────────────────────────────────────────
CHAT_FILES = [
    os.path.join(os.path.dirname(__file__), "..", "mobile", "assets", "resources",
                 "WhatsApp Chat with PARIL.txt"),
    os.path.join(os.path.dirname(__file__), "..", "mobile", "assets", "resources",
                 "WhatsApp Chat with Paril About To Sleep.txt"),
]
COLLECTION_NAME = "parilgpt_chat"
MISTRAL_EMBED_MODEL = "mistral-embed"
BATCH_SIZE = 32          # Mistral embed supports up to 64/128 per request
DIALOGUE_WINDOW = 4      # conversational exchanges per chunk
MAX_CHUNKS = 1200        # balance complete timeline coverage with free-tier quota


def get_chroma_client() -> chromadb.ClientAPI:
    persist_dir = os.path.abspath(settings.chroma_persist_dir)
    os.makedirs(persist_dir, exist_ok=True)
    return chromadb.PersistentClient(
        path=persist_dir,
        settings=ChromaSettings(anonymized_telemetry=False),
    )


def embed_batch(client: Mistral, texts: List[str]) -> List[List[float]]:
    """Call Mistral embed with retry on rate-limit."""
    for attempt in range(5):
        try:
            resp = client.embeddings.create(model=MISTRAL_EMBED_MODEL, inputs=texts)
            return [d.embedding for d in resp.data]
        except Exception as exc:
            if "429" in str(exc) or "rate" in str(exc).lower():
                wait = 2 ** attempt
                print(f"  Rate-limited, waiting {wait}s …", flush=True)
                time.sleep(wait)
            else:
                raise
    raise RuntimeError("Failed to embed after 5 attempts.")


def ingest():
    print("=== ParilGPT Ingest ===")

    mistral_client = Mistral(api_key=settings.mistral_api_key)
    chroma = get_chroma_client()

    # Wipe & recreate collection so we start fresh each ingest
    try:
        chroma.delete_collection(COLLECTION_NAME)
        print("Cleared existing collection.")
    except Exception:
        pass

    collection = chroma.create_collection(
        name=COLLECTION_NAME,
        metadata={"hnsw:space": "cosine"},
    )

    all_chunks: List[dict] = []

    for path in CHAT_FILES:
        abs_path = os.path.abspath(path)
        if not os.path.exists(abs_path):
            print(f"  [SKIP] File not found: {abs_path}")
            continue

        print(f"  Parsing: {os.path.basename(abs_path)}")
        turns = parse_whatsapp_file(abs_path)
        print(f"    -> {len(turns)} turns parsed")

        chunks = group_turns_into_dialogue_chunks(turns, window_size=DIALOGUE_WINDOW)
        print(f"    -> {len(chunks)} dialogue chunks")
        all_chunks.extend(chunks)

    if not all_chunks:
        print("No chunks produced. Exiting.")
        sys.exit(1)

    # Deduplicate by content
    seen = set()
    unique_chunks = []
    for c in all_chunks:
        key = c["content"].strip()
        if key not in seen and len(key) > 20:
            seen.add(key)
            unique_chunks.append(c)

    print(f"\nTotal extracted chunks: {len(unique_chunks)}")

    if len(unique_chunks) > MAX_CHUNKS:
        step = len(unique_chunks) / MAX_CHUNKS
        sampled = [unique_chunks[int(i * step)] for i in range(MAX_CHUNKS)]
        print(f"Sampled {len(sampled)} chronologically balanced dialogue chunks across all chats.")
        final_chunks = sampled
    else:
        final_chunks = unique_chunks

    print("Embedding and storing in ChromaDB ...")

    ids, docs, metas = [], [], []
    for i, chunk in enumerate(final_chunks):
        ids.append(f"chunk_{i:06d}")
        docs.append(chunk["content"])
        metas.append({
            "speaker": chunk.get("speaker", ""),
            "date": chunk.get("date", ""),
            "turn_index": chunk.get("turn_index", i),
        })

    # Process in batches
    for start in range(0, len(docs), BATCH_SIZE):
        end = min(start + BATCH_SIZE, len(docs))
        batch_docs = docs[start:end]
        batch_ids = ids[start:end]
        batch_metas = metas[start:end]

        print(f"  Embedding batch {start // BATCH_SIZE + 1} / "
              f"{(len(docs) + BATCH_SIZE - 1) // BATCH_SIZE} "
              f"({start}-{end}) ...", flush=True)

        vectors = embed_batch(mistral_client, batch_docs)

        collection.add(
            ids=batch_ids,
            documents=batch_docs,
            embeddings=vectors,
            metadatas=batch_metas,
        )
        time.sleep(0.5)   # gentle pacing for free tier

    print(f"\n✅ Ingested {len(docs)} chunks into ChromaDB collection '{COLLECTION_NAME}'.")
    print(f"   Persist dir: {os.path.abspath(settings.chroma_persist_dir)}")


if __name__ == "__main__":
    ingest()
