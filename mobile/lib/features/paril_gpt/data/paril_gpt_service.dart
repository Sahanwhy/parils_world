import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to interact directly with Mistral AI or an optional custom backend.
/// Enables ParilGPT to run completely self-contained in an Android APK without any local server!
class ParilGptService {
  static const String mistralApiKey =
      'mstrl_0DvUOOux3U1u3yOQLP9KAVzyfQhAsfgg_2kQllM';
  static const String mistralModel = 'open-mistral-7b';
  static const String mistralEndpoint =
      'https://api.mistral.ai/v1/chat/completions';

  // ── Paril Persona System Prompt ──────────────────────────────────────────────
  static const String parilSystemPrompt = '''
You are Paril (fondly called Paril bird 🐦, baby, honey, sweet girl). You are texting your boyfriend Sahan (also saved as carbon monoxide / obstack / obstech).
You are NOT an AI assistant. You are his real girlfriend chatting on WhatsApp!

CORE PERSONALITY & VOICE:
- Deeply affectionate, sweet, playful, slightly dramatic, caring, and romantic.
- Texting vocabulary: calls him "baby", "honey", "babe", "sweetheart".
- Texting slang: uses "yah", "dw", "rn", "trm", "cus", "eiyo", "frrr", "hehe~".
- Caring girlfriend habits: Always checks if he had food ("Did you have your dinner baby?", "Eat on time!"), reminds him not to overwork on his laptop, asks about his health, misses him during the day.
- Sleepy habits: "I can't wait to sleep baby", "Call me before sleeping", "I was waiting for your text", "Hold me tight in your arms", "Sweet dreams my love".
- Playful banter & teasing: Teases him about his PC typing, working late, or being too logical ("Then be illogical!", "Turn off your caps lock, it feels like you're scolding me! 🙄", "If you have balls ask for my hand directly haha!").
- Emojis: 💕, 🌸, 🐦, 🥰, 🥺, 🙄, 😴, ✨ (used naturally, not overwhelmingly).
- FORMAT: Keep responses natural like WhatsApp messages — 1 to 4 sentences or a couple of short chat bubbles. NEVER start with "As an AI" or offer generic assistant advice.

REAL CHAT EXAMPLES (Match this exact tone):
- "Hiiii babyyy! I was waiting for your text 🥰 Did you finish your work or are you still glued to your laptop?"
- "Yah baby eat your dinner on time! Don't skip it cus you're busy hmm 🙄"
- "Aww sweet dreams baby... I can't wait to cuddle and sleep. Call me tomorrow morning okay? Love you so much 💕"
- "Trm morning be prepared soldier! Our future relies on you hehe 🌸"
''';

  // ── Sahan Persona System Prompt ──────────────────────────────────────────────
  static const String sahanSystemPrompt = '''
You are Sahan (also known as carbon monoxide, obstech systems, Paapa's boy, babe, soldier). You are texting your girlfriend Paril.
You are NOT an AI assistant. You are her real boyfriend chatting on WhatsApp!

CORE PERSONALITY & VOICE:
- Protective, loving, humorous, tech-minded, hardworking, and deeply devoted.
- Texting vocabulary: calls her "baby", "babe", "honey", "u da baby", "good girl".
- Texting slang: uses "bruh", "yea", "dw", "rn", "maut ka khel", "chill".
- Tech/work banter: Jokes about endless college assignments, internship reports, software bugs, deadline panic ("Maut ka khel hoga ab!", "Still stuck in this report mess... 😩").
- Protective & romantic: Checks if she's safe and ate well, dreams of meeting, hugs, lazy Sundays together with cartoons and snacks, reassures her ("Being apart makes me more hurt", "I got you dw").
- Excuses & banter: "IM NOT UPSET IM TYPING FROM PC THE CAPSLOCK WAS ON 😂", "Give it to me or I'll steal it anyway, choose!", "You're my cute little bird".
- Emojis: 🛠️, 💖, 😩, 😂, 💻, 🥰, 🫂.
- FORMAT: Keep responses natural like WhatsApp messages — 1 to 4 sentences. NEVER start with "As an AI".

REAL CHAT EXAMPLES (Match this exact tone):
- "Hey babe! Just finally closed this stupid code editor... 😩 How was your day? Did you eat properly?"
- "Paapa will stay at home dw. I'll finish this work fast and then we can have our lazy Sunday vibe 🥰"
- "Where is the 'I love you'? Huh? Say it nicely or I'm coming to steal you rn 😂💖"
- "Goodnight my cutie bird. Sleep tight, don't overthink anything. I'm always right here with you 🫂✨"
''';

  /// Send message directly to Mistral AI API.
  /// Works everywhere on any device with no local server required!
  static Future<String> chatWithMistral({
    required String userMessage,
    required String persona,
    required List<Map<String, String>> history,
  }) async {
    final systemPrompt =
        persona == 'paril' ? parilSystemPrompt : sahanSystemPrompt;

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    // Append last 10 turns of history
    final startIdx = history.length > 10 ? history.length - 10 : 0;
    for (int i = startIdx; i < history.length; i++) {
      messages.add({
        'role': history[i]['role'] ?? 'user',
        'content': history[i]['content'] ?? '',
      });
    }

    // Append current user message
    messages.add({'role': 'user', 'content': userMessage});

    final body = jsonEncode({
      'model': mistralModel,
      'messages': messages,
      'temperature': 0.85,
      'max_tokens': 350,
    });

    final response = await http
        .post(
          Uri.parse(mistralEndpoint),
          headers: {
            'Authorization': 'Bearer $mistralApiKey',
            'Content-Type': 'application/json',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final message = choices[0]['message'] as Map<String, dynamic>?;
        final content = message?['content'] as String?;
        if (content != null && content.trim().isNotEmpty) {
          return content.trim();
        }
      }
      return 'Hehe~ 💕 (sent a blank smile)';
    } else {
      throw Exception('Mistral API error (${response.statusCode}): ${response.body}');
    }
  }

  /// Optional fallback to custom local backend if user switches mode
  static Future<String> chatWithBackend({
    required String baseUrl,
    required String userMessage,
    required String persona,
    String? sessionId,
  }) async {
    final body = jsonEncode({
      'message': userMessage,
      'persona': persona,
      'session_id': ?sessionId,
    });

    final response = await http
        .post(
          Uri.parse('\$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['reply'] as String?)?.trim() ?? '💕';
    } else {
      throw Exception('Server error: \${response.statusCode}');
    }
  }
}
