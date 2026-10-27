import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';
import '../data/paril_gpt_service.dart';

/// Represents one chat bubble in the conversation.
class _ChatMessage {
  const _ChatMessage({
    required this.role,
    required this.content,
    required this.persona,
    required this.timestamp,
  });

  final String role;      // 'user' | 'assistant'
  final String content;
  final String persona;   // 'paril' | 'sahan'
  final DateTime timestamp;
}

/// ParilGPT Chat Screen — talk to an AI that mimics Paril or Sahan.
class ParilGptScreen extends StatefulWidget {
  const ParilGptScreen({super.key});

  @override
  State<ParilGptScreen> createState() => _ParilGptScreenState();
}

class _ParilGptScreenState extends State<ParilGptScreen>
    with TickerProviderStateMixin {
  // ── Config ──────────────────────────────────────────────────────────────────
  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  late String _baseUrl = _defaultBaseUrl;

  // ── State ───────────────────────────────────────────────────────────────────
  bool _useDirectCloud = true; // DEFAULT: APK runs everywhere with zero server!
  String _persona = 'paril';
  String? _sessionId;
  bool _isLoading = false;
  bool _serverReady = true;
  String _serverStatus = '✨ Direct Cloud AI (Ready)';

  final List<_ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _typingAnimController;

  @override
  void initState() {
    super.initState();
    _typingAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    if (!_useDirectCloud) {
      _checkServerHealth();
    }
  }

  @override
  void dispose() {
    _typingAnimController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Network helpers ─────────────────────────────────────────────────────────

  Future<void> _checkServerHealth() async {
    if (_useDirectCloud) {
      setState(() {
        _serverReady = true;
        _serverStatus = '✨ Direct Cloud AI (Ready)';
      });
      return;
    }

    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final ready = data['collection_ready'] as bool? ?? false;
        final size = data['collection_size'] as int? ?? 0;
        setState(() {
          _serverReady = ready;
          _serverStatus = ready
              ? '✅ $size chunks loaded'
              : '⚠️ Run ingest.py first';
        });
      } else {
        setState(() {
          _serverReady = false;
          _serverStatus = '❌ Server error ${resp.statusCode}';
        });
      }
    } catch (_) {
      setState(() {
        _serverReady = false;
        _serverStatus = '❌ Server offline — start backend';
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _inputController.clear();

    final userMsg = _ChatMessage(
      role: 'user',
      content: text,
      persona: _persona,
      timestamp: DateTime.now(),
    );
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      String reply;
      if (_useDirectCloud) {
        final history = _messages
            .where((m) => m != userMsg)
            .map((m) => {'role': m.role, 'content': m.content})
            .toList();
        reply = await ParilGptService.chatWithMistral(
          userMessage: text,
          persona: _persona,
          history: history,
        );
      } else {
        reply = await ParilGptService.chatWithBackend(
          baseUrl: _baseUrl,
          userMessage: text,
          persona: _persona,
          sessionId: _sessionId,
        );
      }

      final botMsg = _ChatMessage(
        role: 'assistant',
        content: reply,
        persona: _persona,
        timestamp: DateTime.now(),
      );
      setState(() {
        _messages.add(botMsg);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _addError('Error: $e');
    }

    _scrollToBottom();
  }

  void _addError(String msg) {
    setState(() {
      _isLoading = false;
      _messages.add(_ChatMessage(
        role: 'assistant',
        content: '⚠️ $msg',
        persona: _persona,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _resetSession() async {
    if (_sessionId != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/reset'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'session_id': _sessionId}),
        );
      } catch (_) {}
    }
    setState(() {
      _messages.clear();
      _sessionId = null;
      _isLoading = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background photo
          Image.asset(
            'assets/images/parilgpt_main.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Dark overlay so chat stays readable
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xCC0A0714),
                  Color(0xE60A0714),
                  Color(0xF20A0714),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),
          // Chat UI
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildPersonaSelector(),
                _buildStatusBar(),
                const Divider(height: 1, color: Color(0xFF2A2040)),
                Expanded(child: _buildMessageList()),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 4),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF4081),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/cover_photo_parilgpt.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.2),
              ),
            ),
          ),
          ShaderMask(
            shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
            child: Text(
              'ParilGPT',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'About ParilGPT\'s Voice 💌',
            onPressed: _showSpeakingStyleNote,
            icon: const Icon(Icons.favorite_rounded, color: Color(0xFFFF4081)),
          ),
          IconButton(
            tooltip: 'Clear conversation',
            onPressed: _resetSession,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
          IconButton(
            tooltip: 'Refresh server status',
            onPressed: _checkServerHealth,
            icon: const Icon(Icons.wifi_tethering_rounded, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _showSpeakingStyleNote() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E142B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF4081), width: 1.2),
        ),
        title: Row(
          children: [
            const Text('💌', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'A Little Note From Sahan',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This AI\'s conversational style is uniquely drawn from how Sahan and Paril talk privately with each other—our inside jokes, teasing, and affection that belong only to us, not with anyone else.\n\nWhile it echoes those sweet memories, no AI could ever truly sound identical to how she speaks in real life... because Paril is one of a kind, and completely irreplaceable 💕✨',
          style: GoogleFonts.outfit(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Understood 💕',
              style: GoogleFonts.outfit(
                color: const Color(0xFFFF4081),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Talking as:',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          _PersonaChip(
            label: 'Paril 🐦',
            selected: _persona == 'paril',
            selectedColor: const Color(0xFFFF4081),
            onTap: () {
              if (_persona != 'paril') {
                setState(() => _persona = 'paril');
              }
            },
          ),
          const SizedBox(width: 8),
          _PersonaChip(
            label: 'Sahan 🛠️',
            selected: _persona == 'sahan',
            selectedColor: const Color(0xFF4FC3F7),
            onTap: () {
              if (_persona != 'sahan') {
                setState(() => _persona = 'sahan');
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editServerUrl() async {
    final controller = TextEditingController(text: _baseUrl);
    bool useCloud = _useDirectCloud;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1F1B2E),
          title: Text(
            'Connection Mode',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setDialogState(() => useCloud = true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: useCloud ? const Color(0xFFFF4081).withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: useCloud ? const Color(0xFFFF4081) : const Color(0xFF3A2E50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        useCloud ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: useCloud ? const Color(0xFFFF4081) : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✨ Direct Cloud AI (Default)',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Best for APK! No server needed, works on any phone.',
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => setDialogState(() => useCloud = false),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: !useCloud ? const Color(0xFF4FC3F7).withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !useCloud ? const Color(0xFF4FC3F7) : const Color(0xFF3A2E50),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        !useCloud ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: !useCloud ? const Color(0xFF4FC3F7) : Colors.white54,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🖥️ Local Backend Server',
                              style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'For developers running FastAPI + ChromaDB locally.',
                              style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!useCloud) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  style: GoogleFonts.outfit(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Backend URL',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Color(0xFF2A2040),
                    border: OutlineInputBorder(),
                    hintText: 'http://10.0.2.2:8000',
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _useDirectCloud = useCloud;
                  if (!useCloud) {
                    _baseUrl = controller.text.trim();
                  }
                });
                Navigator.of(ctx).pop();
                _checkServerHealth();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final color = _serverReady
        ? const Color(0xFF66BB6A)
        : const Color(0xFFFF7043);
    return InkWell(
      onTap: _editServerUrl,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _serverReady ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              _serverStatus,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit, size: 11, color: color.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _isLoading) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        return _ChatBubble(message: msg, persona: _persona);
      },
    );
  }

  Widget _buildEmptyState() {
    final isParil = _persona == 'paril';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isParil)
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4081).withValues(alpha: 0.45),
                        blurRadius: 22,
                        spreadRadius: 3,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFFF4081),
                      width: 3.5,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/cover_photo_parilgpt.jpg',
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.0, -0.2),
                    ),
                  ),
                ),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.cardColorElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF4081),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Image.asset(
                    'assets/images/paril_bird.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            )
          else
            const Text(
              '🛠️',
              style: TextStyle(fontSize: 56),
            ),
          const SizedBox(height: 16),
          ShaderMask(
            shaderCallback: (b) => AppTheme.accentGradient.createShader(b),
            child: Text(
              isParil ? 'Chat with Paril!' : 'Chat with Sahan!',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isParil
                ? 'Say something sweet 💕'
                : 'Ask him anything 🤙',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          // Heartfelt note about AI talking style
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF281438).withValues(alpha: 0.85),
                  const Color(0xFF1E0E2C).withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFFF4081).withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4081).withValues(alpha: 0.12),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💌', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Text(
                      'A Note From Sahan',
                      style: GoogleFonts.outfit(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF80AB),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'The AI\'s talking style is inspired by how Sahan and Paril talk privately with each other—our inside jokes and teasing, not how she talks to anyone else. It\'s a sweet playful echo, but no AI could ever truly sound identical to her in real life... because Paril is one of a kind, and completely irreplaceable 💕✨',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.90),
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (!_serverReady) ...[
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7043).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF7043).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Backend is offline.\n\nRun from your PC:\n  cd backend\n  python main.py',
                textAlign: TextAlign.center,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: const Color(0xFFFF7043),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isParil = _persona == 'paril';
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isParil ? '🐦' : '🛠️',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          AnimatedBuilder(
            animation: _typingAnimController,
            builder: (_, _) => Row(
              children: List.generate(3, (i) {
                final delay = i * 0.3;
                final t = ((_typingAnimController.value - delay).clamp(0.0, 1.0));
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isParil
                            ? const Color(0xFFFF4081)
                            : const Color(0xFF4FC3F7))
                        .withValues(alpha: 0.4 + t * 0.6),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'typing…',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundDeep,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _persona == 'paril'
                      ? 'Say something to Paril… 🐦'
                      : 'Say something to Sahan… 🛠️',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: _isLoading
                    ? null
                    : AppTheme.accentGradient,
                color: _isLoading ? AppTheme.cardColorElevated : null,
                shape: BoxShape.circle,
                boxShadow: _isLoading
                    ? null
                    : [
                        BoxShadow(
                          color: AppTheme.accentRose.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white70,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _PersonaChip extends StatelessWidget {
  const _PersonaChip({
    required this.label,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.18)
              : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? selectedColor : AppTheme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? selectedColor : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.persona});

  final _ChatMessage message;
  final String persona;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    final isParil = persona == 'paril';
    final botColor =
        isParil ? const Color(0xFFFF4081) : const Color(0xFF4FC3F7);

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 6, bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: botColor.withValues(alpha: 0.18),
                border: Border.all(color: botColor.withValues(alpha: 0.6), width: 1.2),
              ),
              child: ClipOval(
                child: isParil
                    ? Image.asset(
                        'assets/images/cover_photo_parilgpt.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0.0, -0.2),
                      )
                    : const Center(
                        child: Text(
                          '🛠️',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
              ),
            ),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied to clipboard'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isUser
                      ? AppTheme.accentViolet.withValues(alpha: 0.85)
                      : AppTheme.cardColorElevated,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: isUser
                        ? const Radius.circular(18)
                        : const Radius.circular(4),
                    bottomRight: isUser
                        ? const Radius.circular(4)
                        : const Radius.circular(18),
                  ),
                  border: Border.all(
                    color: isUser
                        ? Colors.transparent
                        : botColor.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isUser ? AppTheme.accentViolet : botColor)
                          .withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.content,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
