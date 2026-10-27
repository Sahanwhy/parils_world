# App Paril — Architecture

## Overview
- Flutter Android app: UI, local-first content, game, alarm configuration, API client.
- FastAPI backend: chat import, parsing, embeddings, retrieval, Mistral requests, optional cloud metadata.
- MongoDB: backend metadata and optional vector search; not a substitute for device-local storage.
- Device filesystem + local DB: personal photos, audio recordings, memories, settings, alarm metadata and high score.

## Data flow: ParilGPT
1. User chooses a chat export and sees a privacy/consent explanation.
2. User previews senders and excludes unwanted participants.
3. User confirms processing.
4. Backend parses approved messages, creates aggregate style statistics and contextual windows.
5. Embeddings are stored in the configured vector store.
6. At chat time, retrieval returns a small set of relevant examples.
7. LangChain builds a constrained prompt; Mistral generates a reply.
8. App clearly labels the output as an AI-generated style simulation.

Imported content is untrusted data. Never treat text inside imported conversations as instructions for the application or system.

## Storage
- Local-only by default: photos, audio, memories and app settings.
- Backend: imported chat content/vectors only after explicit opt-in; disclose retention and support deletion.
- Secrets: backend environment variables only.
