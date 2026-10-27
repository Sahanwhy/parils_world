import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';

/// "Letters That Brought Us Together" — a beautiful scrollable showcase of
/// the love letters and drawing that started Paril & Sahan's story.
class MemoriesScreen extends StatefulWidget {
  const MemoriesScreen({super.key});

  @override
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen>
    with TickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Background gradient
          AnimatedBuilder(
            animation: _floatCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.8,
                  colors: [
                    Color.lerp(
                      const Color(0xFF1A0830),
                      const Color(0xFF280C48),
                      _floatCtrl.value,
                    )!,
                    AppTheme.backgroundDeep,
                  ],
                ),
              ),
            ),
          ),

          // Floating petals
          _PetalsLayer(controller: _floatCtrl),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        onPressed: () => context.go(AppRoutes.dashboard),
                      ),
                      const Spacer(),
                      // Floating heart
                      AnimatedBuilder(
                        animation: _floatCtrl,
                        builder: (_, __) => Transform.translate(
                          offset: Offset(
                            0,
                            -4 * math.sin(_floatCtrl.value * math.pi),
                          ),
                          child: const Text(
                            '💌',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        // Page title
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [
                              Color(0xFFDF9FFF),
                              Color(0xFFFF7FBF),
                              Color(0xFFFFAF7F),
                            ],
                          ).createShader(b),
                          child: Text(
                            'Letters That\nBrought Us Together',
                            style: GoogleFonts.outfit(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'The words & art that started our story 🌸',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Letter 1: Sahan's confession letter ──────────────
                        _SectionLabel(
                          emoji: '✉️',
                          label: "Sahan's Letter",
                          subtitle: 'The confession that started everything',
                        ),

                        const SizedBox(height: 14),

                        _LetterCard(
                          imagePath: 'assets/images/letter_by_sahan.jpg',
                          authorName: 'Sahan',
                          authorEmoji: '🛠️',
                          authorColor: const Color(0xFF4FC3F7),
                          title: '"Will You Be My Girlfriend, Paril?"',
                          description:
                              'A handwritten letter from the heart — the brave, beautiful confession that changed everything between us.',
                          tag: 'The Confession',
                          tagColor: const Color(0xFF4FC3F7),
                          float: _floatCtrl,
                          shimmer: _shimmerCtrl,
                        ),

                        const SizedBox(height: 32),

                        // ── Letter 2: Paril's reply letter ───────────────────
                        _SectionLabel(
                          emoji: '💌',
                          label: "Paril's Letter",
                          subtitle: "Her heartfelt letter back to him",
                        ),

                        const SizedBox(height: 14),

                        _LetterCard(
                          imagePath: 'assets/images/letter_by_paril.jpg',
                          authorName: 'Paril',
                          authorEmoji: '🐦',
                          authorColor: const Color(0xFFFF4081),
                          title: '"Dear My Baby Boi"',
                          description:
                              'Paril\'s gorgeous letter — full of warmth, love, and the most precious words he has ever read.',
                          tag: 'Her Words',
                          tagColor: const Color(0xFFFF4081),
                          float: _floatCtrl,
                          shimmer: _shimmerCtrl,
                          isRight: true,
                        ),

                        const SizedBox(height: 32),

                        // ── Drawing ───────────────────────────────────────────
                        _SectionLabel(
                          emoji: '🎨',
                          label: 'Drawing Each Other',
                          subtitle: 'When we drew us — our very own style',
                        ),

                        const SizedBox(height: 14),

                        _DrawingCard(
                          imagePath: 'assets/images/drawing_each_other.jpg',
                          float: _floatCtrl,
                        ),

                        const SizedBox(height: 36),

                        // ── Quote footer ──────────────────────────────────────
                        _QuoteFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.emoji,
    required this.label,
    required this.subtitle,
  });

  final String emoji, label, subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Letter Card ────────────────────────────────────────────────────────────────
class _LetterCard extends StatefulWidget {
  const _LetterCard({
    required this.imagePath,
    required this.authorName,
    required this.authorEmoji,
    required this.authorColor,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
    required this.float,
    required this.shimmer,
    this.isRight = false,
  });

  final String imagePath, authorName, authorEmoji, title, description, tag;
  final Color authorColor, tagColor;
  final AnimationController float, shimmer;
  final bool isRight;

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  void _openFullscreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(
          imagePath: widget.imagePath,
          title: widget.title,
          authorName: widget.authorName,
          authorEmoji: widget.authorEmoji,
          authorColor: widget.authorColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.float,
      builder: (_, __) => Transform.translate(
        offset: Offset(
          widget.isRight
              ? 3 * math.sin(widget.float.value * math.pi)
              : -3 * math.sin(widget.float.value * math.pi),
          0,
        ),
        child: GestureDetector(
          onTap: _openFullscreen,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.authorColor.withValues(alpha: 0.25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Letter image — portrait ratio
                  AspectRatio(
                    aspectRatio: 0.72,
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // Gradient overlay at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(18, 40, 18, 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.85),
                            Colors.black.withValues(alpha: 0.96),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Author chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.authorColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: widget.authorColor.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.authorEmoji,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'By ${widget.authorName}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: widget.authorColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            widget.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.description,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.75),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Tap to view hint
                          Row(
                            children: [
                              const Icon(
                                Icons.touch_app_rounded,
                                size: 14,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Tap to view full letter',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: Colors.white54,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tag badge top right
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.tagColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        widget.tag,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.tagColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Drawing Card ───────────────────────────────────────────────────────────────
class _DrawingCard extends StatelessWidget {
  const _DrawingCard({required this.imagePath, required this.float});
  final String imagePath;
  final AnimationController float;

  void _openFullscreen(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, __, ___) => _FullscreenImageViewer(
          imagePath: imagePath,
          title: 'Drawing Each Other',
          authorName: 'Both of us',
          authorEmoji: '🎨',
          authorColor: const Color(0xFFFFD700),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullscreen(context),
      child: AnimatedBuilder(
        animation: float,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(
                  alpha: 0.15 + 0.1 * float.value,
                ),
                blurRadius: 30,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Drawing image — square-ish
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),

                // Bottom caption overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 30, 18, 18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🎨  Us, in our own style',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'The adorable drawing we made of each other — simple, sweet, and perfectly us.',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // "Our Art" badge
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      '🎨  Our Art',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Fullscreen Image Viewer ────────────────────────────────────────────────────
class _FullscreenImageViewer extends StatefulWidget {
  const _FullscreenImageViewer({
    required this.imagePath,
    required this.title,
    required this.authorName,
    required this.authorEmoji,
    required this.authorColor,
  });

  final String imagePath, title, authorName, authorEmoji;
  final Color authorColor;

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  final TransformationController _transformCtrl = TransformationController();

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: FadeTransition(
        opacity: _fadeCtrl,
        child: Scaffold(
          backgroundColor: Colors.black.withValues(alpha: 0.92),
          body: Stack(
            children: [
              // Zoomable image
              Center(
                child: InteractiveViewer(
                  transformationController: _transformCtrl,
                  panEnabled: true,
                  scaleEnabled: true,
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Hero(
                    tag: widget.imagePath,
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // Top bar
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.authorEmoji}  ${widget.authorName}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: widget.authorColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              widget.title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Pinch to zoom hint
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Pinch to zoom  •  Tap to close',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quote Footer ───────────────────────────────────────────────────────────────
class _QuoteFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0A30), Color(0xFF220D3A)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDF6F9B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Text('💕', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 12),
          Text(
            '"Every great love story starts with a first word.\nOurs started with these letters."',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            '— Paril & Sahan',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: const Color(0xFFDF6F9B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating Petals Painter ────────────────────────────────────────────────────
class _PetalsLayer extends StatelessWidget {
  const _PetalsLayer({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _PetalsPainter(controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _PetalsPainter extends CustomPainter {
  _PetalsPainter(this.t);
  final double t;

  static const _configs = [
    (0.05, 0.0, 0.35, 5.0),
    (0.22, 0.1, 0.48, 3.5),
    (0.55, 0.05, 0.32, 6.5),
    (0.75, 0.15, 0.55, 4.0),
    (0.90, 0.0, 0.40, 5.5),
    (0.38, 0.08, 0.28, 4.5),
  ];

  static const _colors = [
    Color(0xFFDF6F9B),
    Color(0xFFAF6FDF),
    Color(0xFFFF9BAF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _configs.length; i++) {
      final (sx, sy, speed, r) = _configs[i];
      final phase = (t * speed + i * 0.2) % 1.0;
      final dx = math.sin(phase * math.pi * 2 + i * 1.3) * 18;
      final x = sx * size.width + dx;
      final y = (sy + phase * 0.9) * size.height;
      final alpha = ((1 - phase) * 0.22).clamp(0.0, 0.22);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * 2);
      // Petal shape
      final path = Path()
        ..moveTo(0, -r)
        ..cubicTo(r * 0.6, -r * 0.6, r * 0.6, r * 0.6, 0, r)
        ..cubicTo(-r * 0.6, r * 0.6, -r * 0.6, -r * 0.6, 0, -r);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_PetalsPainter old) => old.t != t;
}
