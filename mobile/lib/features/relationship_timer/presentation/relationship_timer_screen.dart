import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';

class RelationshipTimerScreen extends StatefulWidget {
  const RelationshipTimerScreen({super.key});
  @override
  State<RelationshipTimerScreen> createState() => _RelationshipTimerScreenState();
}

class _RelationshipTimerScreenState extends State<RelationshipTimerScreen>
    with TickerProviderStateMixin {
  // June 4 2026 00:00:00 IST = June 3 2026 18:30:00 UTC
  static final DateTime _startUtc = DateTime.utc(2026, 6, 3, 18, 30, 0);

  late Timer _ticker;
  late AnimationController _pulseCtrl;
  late AnimationController _heartCtrl;

  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _heartCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _updateElapsed();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    final diff = DateTime.now().toUtc().difference(_startUtc);
    if (mounted) setState(() => _elapsed = diff.isNegative ? Duration.zero : diff);
  }

  @override
  void dispose() {
    _ticker.cancel();
    _pulseCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  int get _days    => _elapsed.inDays;
  int get _hours   => _elapsed.inHours % 24;
  int get _minutes => _elapsed.inMinutes % 60;
  int get _seconds => _elapsed.inSeconds % 60;
  String _pad(int n) => n.toString().padLeft(2, '0');

  String get _loveNote {
    if (_days < 30)  return 'Every single day with you is a whole new adventure 🌸';
    if (_days < 100) return 'More than a month of smiles, warmth, and you 💫';
    if (_days < 200) return '$_days days and every one of them has been my favourite 💕';
    if (_days < 365) return 'Almost a year and I fall more in love every single day 🌙';
    return 'Over a year of loving you — and forever more to go 💍';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Pulsing gradient background
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [
                    Color.lerp(const Color(0xFF1A0830), const Color(0xFF2A0D45), _pulseCtrl.value)!,
                    AppTheme.backgroundDeep,
                  ],
                ),
              ),
            ),
          ),

          // Floating hearts
          _FloatingHearts(controller: _pulseCtrl),

          // Content
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textSecondary),
                    onPressed: () => context.go(AppRoutes.dashboard),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),

                        // Beating heart emoji
                        AnimatedBuilder(
                          animation: _heartCtrl,
                          builder: (_, _) => Transform.scale(
                            scale: 1.0 + 0.12 * _heartCtrl.value,
                            child: const Text('💖', style: TextStyle(fontSize: 48)),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Title
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [Color(0xFFDF6F9B), Color(0xFF9B6FDF), Color(0xFFDF6F9B)],
                          ).createShader(b),
                          child: Text(
                            'Us, Together',
                            style: GoogleFonts.outfit(
                              fontSize: 32, fontWeight: FontWeight.w800,
                              color: Colors.white, letterSpacing: -0.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Since June 4, 2026 ✨',
                          style: GoogleFonts.outfit(fontSize: 14, color: AppTheme.textSecondary),
                        ),

                        const SizedBox(height: 32),

                        // Day bubble
                        _DayBubble(days: _days, pulse: _pulseCtrl),

                        const SizedBox(height: 24),

                        // HH:MM:SS
                        Row(
                          children: [
                            Expanded(child: _Seg(value: _pad(_hours),   label: 'HRS')),
                            _Col(),
                            Expanded(child: _Seg(value: _pad(_minutes), label: 'MIN')),
                            _Col(),
                            Expanded(child: _Seg(value: _pad(_seconds), label: 'SEC')),
                          ],
                        ),

                        const SizedBox(height: 36),

                        // Couple art hero image on the lower side
                        AnimatedBuilder(
                          animation: _heartCtrl,
                          builder: (_, _) => Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDF6F9B).withValues(
                                    alpha: 0.35 + 0.20 * _heartCtrl.value,
                                  ),
                                  blurRadius: 40,
                                  spreadRadius: 6,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF9B6FDF).withValues(
                                    alpha: 0.20 + 0.15 * _heartCtrl.value,
                                  ),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Color.lerp(
                                    const Color(0xFFDF6F9B),
                                    const Color(0xFF9B6FDF),
                                    _heartCtrl.value,
                                  )!.withValues(alpha: 0.85),
                                  width: 3.5,
                                ),
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/cover_relationship.jpg',
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0.0, -0.15),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 36),

                        // Love note
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A0A30), Color(0xFF1E0E38)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.accentRose.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '"$_loveNote"',
                            style: GoogleFonts.outfit(
                              fontSize: 15, color: AppTheme.textSecondary,
                              fontStyle: FontStyle.italic, height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Milestones
                        _Milestones(days: _days),

                        const SizedBox(height: 48),
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

// ── Day Bubble ────────────────────────────────────────────────────────────────
class _DayBubble extends StatelessWidget {
  const _DayBubble({required this.days, required this.pulse});
  final int days;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(const Color(0xFF2E1060), const Color(0xFF3D1580), pulse.value)!,
              Color.lerp(const Color(0xFF1A0A40), const Color(0xFF260E5A), pulse.value)!,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Color.lerp(const Color(0xFF7B4FBF), const Color(0xFFBF4F7B), pulse.value)!
                .withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7B4FBF).withValues(alpha: 0.2 + 0.15 * pulse.value),
              blurRadius: 40, spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$days',
              style: GoogleFonts.outfit(
                fontSize: 88, fontWeight: FontWeight.w900,
                color: Colors.white, height: 1.0,
                shadows: [Shadow(color: const Color(0xFFBF4F7B).withValues(alpha: 0.7), blurRadius: 24)],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'DAYS',
              style: GoogleFonts.outfit(
                fontSize: 16, fontWeight: FontWeight.w600,
                color: const Color(0xFFDF6F9B), letterSpacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Segment ───────────────────────────────────────────────────────────────────
class _Seg extends StatelessWidget {
  const _Seg({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A30),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.accentViolet.withValues(alpha: 0.4)),
            boxShadow: [BoxShadow(color: AppTheme.accentViolet.withValues(alpha: 0.12), blurRadius: 16)],
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white, height: 1.0),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMuted, letterSpacing: 3)),
      ],
    );
  }
}

class _Col extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Text(':', style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.w900, color: AppTheme.accentVioletLight)),
    );
  }
}

// ── Milestones ────────────────────────────────────────────────────────────────
class _Milestones extends StatelessWidget {
  const _Milestones({required this.days});
  final int days;

  static const _list = [
    (7,   '1 Week',   '🌷'),
    (30,  '1 Month',  '🌙'),
    (100, '100 Days', '💯'),
    (200, '200 Days', '🎊'),
    (365, '1 Year',   '🎂'),
    (500, '500 Days', '🚀'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Milestones', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 14),
        ..._list.map((m) {
          final (target, label, emoji) = m;
          final achieved = days >= target;
          final progress = (days / target).clamp(0.0, 1.0);
          final left = target - days;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: achieved ? AppTheme.accentViolet.withValues(alpha: 0.15) : const Color(0xFF141428),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: achieved ? AppTheme.accentViolet.withValues(alpha: 0.5) : AppTheme.dividerColor,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(label, style: GoogleFonts.outfit(
                        fontSize: 14, fontWeight: FontWeight.w600,
                        color: achieved ? Colors.white : AppTheme.textSecondary,
                      )),
                    ),
                    if (achieved)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppTheme.accentViolet, AppTheme.accentRose]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('✓ Done', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                      )
                    else
                      Text('$left days left', style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      achieved ? AppTheme.accentViolet : const Color(0xFF5A3090),
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ── Floating hearts ───────────────────────────────────────────────────────────
class _FloatingHearts extends StatelessWidget {
  const _FloatingHearts({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _HeartsPainter(controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _HeartsPainter extends CustomPainter {
  _HeartsPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    const configs = [
      (0.08, 0.9, 0.6, 11.0),
      (0.22, 0.8, 0.35, 7.0),
      (0.55, 0.88, 0.5, 9.0),
      (0.78, 0.75, 0.28, 6.5),
      (0.42, 0.95, 0.55, 8.0),
      (0.92, 0.85, 0.42, 5.5),
    ];
    for (int i = 0; i < configs.length; i++) {
      final (sx, sy, speed, r) = configs[i];
      final phase = (t * speed + i * 0.28) % 1.0;
      final dx = math.sin(phase * math.pi * 2 + i) * 22.0;
      final x = sx * size.width + dx;
      final y = sy * size.height - phase * size.height * 0.45;
      final alpha = ((1.0 - phase) * 0.28).clamp(0.0, 0.28);
      final paint = Paint()
        ..color = const Color(0xFFBF4F7B).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      final c = Offset(x, y);
      final path = Path()
        ..moveTo(c.dx, c.dy + r * 0.4)
        ..cubicTo(c.dx - r, c.dy - r * 0.4, c.dx - r * 0.6, c.dy - r, c.dx, c.dy - r * 0.4)
        ..cubicTo(c.dx + r * 0.6, c.dy - r, c.dx + r, c.dy - r * 0.4, c.dx, c.dy + r * 0.4);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_HeartsPainter old) => old.t != t;
}
