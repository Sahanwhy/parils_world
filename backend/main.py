"""
main.py – FastAPI server for ParilGPT.

Endpoints:
  GET  /health        – health + readiness check
  POST /chat          – send a message, get a persona reply
  POST /reset         – clear conversation history for a session
  GET  /personas      – list available personas
"""

from __future__ import annotations

import uuid
from collections import defaultdict
from typing import Dict, List, Literal, Optional

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from config import settings
from rag_service import RAGService

# ── App setup ─────────────────────────────────────────────────────────────────

app = FastAPI(
    title="ParilGPT API",
    description="Chat with an AI that talks like Paril 💕 or Sahan 🛠️",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialise RAG service on startup (lazy – doesn't crash if ChromaDB empty)
_rag: Optional[RAGService] = None


def get_rag() -> RAGService:
    global _rag
    if _rag is None:
        _rag = RAGService()
    return _rag


# In-memory session store  {session_id -> list of {role, content}}
_sessions: Dict[str, List[dict]] = defaultdict(list)

# ── Schemas ───────────────────────────────────────────────────────────────────


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    persona: Literal["paril", "sahan"] = "paril"
    session_id: Optional[str] = Field(
        default=None,
        description="Pass the session_id returned from a prior response to maintain conversation history. Omit for a fresh conversation.",
    )


class ChatResponse(BaseModel):
    reply: str
    persona: str
    session_id: str


class ResetRequest(BaseModel):
    session_id: str


class HealthResponse(BaseModel):
    status: str
    collection_ready: bool
    collection_size: int


# ── Routes ────────────────────────────────────────────────────────────────────


@app.get("/health", response_model=HealthResponse, tags=["System"])
def health():
    rag = get_rag()
    ready = rag.is_ready()
    size = 0
    try:
        if rag._collection is not None:
            size = rag._collection.count()
    except Exception:
        pass
    return HealthResponse(
        status="ok" if ready else "degraded – run ingest.py",
        collection_ready=ready,
        collection_size=size,
    )


@app.get("/personas", tags=["Config"])
def list_personas():
    return {
        "personas": [
            {
                "id": "paril",
                "name": "Paril 🐦",
                "description": "Sweet, playful, emoji-loving Paril 💕",
            },
            {
                "id": "sahan",
                "name": "Sahan 🛠️",
                "description": "Caring, tech-brained Sahan (carbon monoxide / obstech systems)",
            },
        ]
    }


@app.post("/chat", response_model=ChatResponse, tags=["Chat"])
def chat(req: ChatRequest):
    rag = get_rag()

    # Create or reuse session
    session_id = req.session_id or str(uuid.uuid4())
    history = _sessions[session_id]

    try:
        reply = rag.chat(
            user_message=req.message,
            persona=req.persona,
            history=history,
        )
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc))

    # Update session history
    history.append({"role": "user", "content": req.message})
    history.append({"role": "assistant", "content": reply})

    # Keep history bounded (last 40 messages = 20 turns)
    if len(history) > 40:
        _sessions[session_id] = history[-40:]

    return ChatResponse(reply=reply, persona=req.persona, session_id=session_id)


@app.post("/reset", tags=["Chat"])
def reset(req: ResetRequest):
    _sessions.pop(req.session_id, None)
    return {"message": f"Session {req.session_id} cleared."}


@app.get("/", tags=["System"])
def root():
    return {
        "app": "ParilGPT",
        "docs": "/docs",
        "health": "/health",
        "chat": "POST /chat",
    }


# ── Entrypoint ────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=settings.port, reload=True)
