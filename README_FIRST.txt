APP PARIL — ANTI GRAVITY PROJECT BRIEF
======================================

Purpose
-------
Build a private, romantic Android app called "App Paril" using Flutter/Dart. This folder is a project blueprint for an AI coding agent (Antigravity). Read PROJECT_SPEC.txt before writing code.

IMPORTANT WORKING RULES FOR THE CODING AGENT
--------------------------------------------
1. Inspect the existing workspace before changing files. If a Flutter project already exists, adapt it instead of replacing it.
2. Implement in small, testable phases. Run flutter analyze and tests after each phase.
3. Do not create fake API keys, fake credentials, or claim external integrations work without testing.
4. Never put the Mistral API key, database credentials, or other secrets in Flutter code or the APK. Keep secrets on the backend in environment variables.
5. Do not hard-code private photos, personal chats, voice recordings, dates, or credentials. Use setup screens/placeholders until the owner supplies them.
6. Treat imported WhatsApp/Instagram messages as sensitive. Only process messages with appropriate consent, provide deletion controls, and never imply AI-generated replies are actually Paril's words or real feelings.
7. Do not upload the user's private media/chat exports without a clear, explicit action and explanation of where the data goes.
8. Alarm reliability is Android-specific. Do not promise alarms will play a voice clip in every OS state until tested on a physical Android device.
9. Keep the app dark, polished, responsive, accessible, and suitable for an Android APK.
10. If a requirement is ambiguous, choose a safe, maintainable default and document it. Do not silently invent personal details.

Recommended implementation order
--------------------------------
Phase 1: Flutter foundation, dark theme, navigation, welcome/role selection, developer message.
Phase 2: Dashboard, relationship timer (configured date), memories, photo gallery.
Phase 3: Flappy Bird using Flame; scoring and local high-score persistence.
Phase 4: Voice clips library and alarm scheduling; test Android permissions and reboot behavior.
Phase 5: Python FastAPI backend, MongoDB connection, health endpoint, configuration.
Phase 6: Chat export import/consent, preprocessing, embeddings/vector search, LangChain + Mistral RAG chatbot.
Phase 7: privacy review, tests, documentation, Android release build.

Start with a working MVP. Do not attempt all features in one untested code generation pass.
