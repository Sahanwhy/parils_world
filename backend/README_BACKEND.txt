# ParilGPT Backend — Setup Guide

## What is this?
FastAPI + Mistral AI + ChromaDB backend that powers the ParilGPT chat feature.
The AI learns from your actual WhatsApp chats and replies in Paril's or Sahan's style.

## Architecture
```
Flutter app  ──────►  FastAPI (main.py)
                           │
                     rag_service.py
                      /         \
              ChromaDB          Mistral AI
           (vector store)   (LLM + embeddings)
                 │
          chat_parser.py
                 │
        WhatsApp .txt files
```

## First-Time Setup

### 1. Create virtual environment
```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

### 2. Ingest WhatsApp chats (run once)
This parses the chat files, embeds them, and stores in ChromaDB.
Takes a few minutes due to Mistral's free-tier rate limits.
```powershell
python ingest.py
```
You should see output like:
```
=== ParilGPT Ingest ===
  Parsing: WhatsApp Chat with PARIL.txt
    → 8423 turns parsed
    → 8423 dialogue chunks
  Parsing: WhatsApp Chat with Paril About To Sleep.txt
    → 1921 turns parsed
  Total unique chunks: 9344
  Embedding batch 1 / 584 …
  ...
✅ Ingested 9344 chunks into ChromaDB collection 'parilgpt_chat'.
```

### 3. Start the server
```powershell
python main.py
# OR with auto-reload:
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

### 4. Test it
```powershell
# Health check
curl http://localhost:8000/health

# Chat as Paril
curl -X POST http://localhost:8000/chat `
  -H "Content-Type: application/json" `
  -d '{"message": "how are you?", "persona": "paril"}'

# Chat as Sahan
curl -X POST http://localhost:8000/chat `
  -H "Content-Type: application/json" `
  -d '{"message": "what are you doing?", "persona": "sahan"}'
```

### 5. Interactive API docs
Open in browser: http://localhost:8000/docs

## Flutter App Setup
The ParilGPT screen connects to `http://10.0.2.2:8000` (Android emulator loopback).

**For a real device on the same WiFi:**
1. Find your PC's local IP: `ipconfig` → look for IPv4 Address (e.g. 192.168.1.100)
2. Edit `paril_gpt_screen.dart` line with `_baseUrl`:
   ```dart
   static const String _baseUrl = 'http://192.168.1.100:8000';
   ```

## API Endpoints

| Method | Path       | Description                         |
|--------|------------|-------------------------------------|
| GET    | /health    | Server + ChromaDB status            |
| GET    | /personas  | List available personas             |
| POST   | /chat      | Send message, get persona reply      |
| POST   | /reset     | Clear conversation history           |
| GET    | /docs      | Interactive Swagger UI              |

## Chat Request Format
```json
{
  "message": "heyyy",
  "persona": "paril",
  "session_id": "optional-uuid-for-history"
}
```

## Notes
- The AI uses RAG: it retrieves relevant real chat snippets as context before replying
- `persona: "paril"` → replies in Paril's sweet, emoji-filled style 🐦💕
- `persona: "sahan"` → replies in Sahan's caring, tech-brained style 🛠️
- Sessions are in-memory (lost on server restart)
- Run `ingest.py` again if you add new chat files
