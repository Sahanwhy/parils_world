import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routing/app_router.dart';

/// Birthday screen — shows a locked teaser with countdown until Jan 18.
/// On Jan 18, the full birthday experience unlocks.
class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen>
    with TickerProviderStateMixin {
  late Timer _ticker;
  late AnimationController _pulseCtrl;
  late AnimationController _floatCtrl;
  late AnimationController _confettiCtrl;
  late AnimationController _lockShakeCtrl;
  late AnimationController _glowCtrl;

  Duration _remaining = Duration.zero;
  bool _isBirthdayToday = false;

  // Next birthday: Jan 18 every year
  static DateTime _nextBirthday() {
    final now = DateTime.now();
    var bday = DateTime(now.year, 1, 18);
    if (now.isAfter(bday)) {
      bday = DateTime(now.year + 1, 1, 18);
    }
    return bday;
  }

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _lockShakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _updateCountdown();
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bday = DateTime(now.year, 1, 18);

    final next = _nextBirthday();
    final diff = next.difference(now);

    if (mounted) {
      setState(() {
        _isBirthdayToday = today == bday;
        _remaining = diff.isNegative ? Duration.zero : diff;
      });
    }
  }

  @override
  void dispose() {
    _ticker.cancel();
    _pulseCtrl.dispose();
    _floatCtrl.dispose();
    _confettiCtrl.dispose();
    _lockShakeCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  int get _days => _remaining.inDays;
  int get _hours => _remaining.inHours % 24;
  int get _minutes => _remaining.inMinutes % 60;
  int get _seconds => _remaining.inSeconds % 60;
  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDeep,
      body: Stack(
        children: [
          // Background photo
          Positioned.fill(
            child: Image.asset(
              'assets/images/birthday_image.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Dark gradient overlay so countdown and text are clearly readable
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xD90A0614),
                    Color(0xE60D071E),
                    Color(0xF5090412),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Animated ambient glow pulse
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [
                    const Color(0xFFDF4F9B).withValues(alpha: 0.12 * _pulseCtrl.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Floating particles
          _ParticlesLayer(
            controller: _confettiCtrl,
            isBirthday: _isBirthdayToday,
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    onPressed: () => context.go(AppRoutes.dashboard),
                  ),
                ),
                Expanded(
                  child: _isBirthdayToday
                      ? _BirthdayUnlockedView(pulse: _pulseCtrl, float: _floatCtrl)
                      : _LockedView(
                          days: _days,
                          hours: _pad(_hours),
                          minutes: _pad(_minutes),
                          seconds: _pad(_seconds),
                          pulse: _pulseCtrl,
                          float: _floatCtrl,
                          glow: _glowCtrl,
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

// ═══════════════════════════════════════════════════════════════════════════════
// LOCKED VIEW — shown every day except Jan 18
// ═══════════════════════════════════════════════════════════════════════════════
class _LockedView extends StatelessWidget {
  const _LockedView({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.pulse,
    required this.float,
    required this.glow,
  });

  final int days;
  final String hours, minutes, seconds;
  final AnimationController pulse, float, glow;

  // Teaser features that will unlock
  static const _teaserFeatures = [
    (Icons.photo_album_rounded, '📸 Secret Photo Album', 'A collection of your most treasured memories, hidden just for this day'),
    (Icons.music_note_rounded, '🎵 Birthday Playlist', 'A handcrafted playlist of songs that remind me of you'),
    (Icons.favorite_rounded, '💌 A Letter From the Heart', 'Words I\'ve been saving just for your special day'),
    (Icons.auto_stories_rounded, '📖 Our Story: Chapter You', 'Every beautiful moment we\'ve shared, relived'),
    (Icons.stars_rounded, '✨ Surprise Memories', 'Something magical is waiting — only for you'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 4),

          // Floating Birthday Emblem with glowing aura
          AnimatedBuilder(
            animation: float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -6 * math.sin(float.value * math.pi)),
              child: AnimatedBuilder(
                animation: glow,
                builder: (_, __) => Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF4A1080), const Color(0xFF7B20A0), glow.value)!,
                        Color.lerp(const Color(0xFF7A1060), const Color(0xFFA02080), glow.value)!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDF4F9B).withValues(
                          alpha: 0.5 + 0.2 * glow.value,
                        ),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(
                          alpha: 0.25 * glow.value,
                        ),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Color.lerp(
                        const Color(0xFFAF7FDF),
                        const Color(0xFFFFD700),
                        glow.value,
                      )!.withValues(alpha: 0.85),
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Text('🎂', style: TextStyle(fontSize: 44)),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Title
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFDF9FFF), Color(0xFFFF7FBF), Color(0xFFFFD700)],
            ).createShader(b),
            child: Text(
              'Her Birthday',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'January 18 ✨',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 24),

          // Locked message card
          AnimatedBuilder(
            animation: glow,
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFF1A0A30), const Color(0xFF250D42), glow.value)!,
                    Color.lerp(const Color(0xFF200830), const Color(0xFF2A0E3A), glow.value)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Color.lerp(
                    const Color(0xFF7B4FBF),
                    const Color(0xFFDF6F9B),
                    glow.value,
                  )!.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B4FBF).withValues(alpha: 0.12 * glow.value),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '🎁 Something Special is Coming...',
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This entire section unlocks on your birthday — January 18. I\'ve been preparing something only for you. A surprise worth waiting for. 💕',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: AppTheme.textSecondary,
                      height: 1.65,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Countdown timer
          _CountdownWidget(
            days: days,
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            pulse: pulse,
          ),

          const SizedBox(height: 32),

          // Teaser features — blurred/locked
          _TeaserFeaturesSection(features: _teaserFeatures, glow: glow),

          const SizedBox(height: 32),

          // Bottom motivation line
          _BottomMotivation(days: days),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ── Countdown Widget ───────────────────────────────────────────────────────────
class _CountdownWidget extends StatelessWidget {
  const _CountdownWidget({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.pulse,
  });

  final int days;
  final String hours, minutes, seconds;
  final AnimationController pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'UNLOCKS IN',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDF6F9B),
            letterSpacing: 5,
          ),
        ),
        const SizedBox(height: 16),

        // Big days bubble
        AnimatedBuilder(
          animation: pulse,
          builder: (_, __) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.lerp(const Color(0xFF2E1060), const Color(0xFF4A1B80), pulse.value)!,
                  Color.lerp(const Color(0xFF4A0A48), const Color(0xFF6A1068), pulse.value)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Color.lerp(
                  const Color(0xFF7B4FBF),
                  const Color(0xFFFFD700),
                  pulse.value,
                )!.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9B3FAF).withValues(
                    alpha: 0.2 + 0.15 * pulse.value,
                  ),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  '$days',
                  style: GoogleFonts.outfit(
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        blurRadius: 28,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'DAYS',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 6,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // H:M:S
        Row(
          children: [
            Expanded(child: _Seg(value: hours, label: 'HRS')),
            _Colon(),
            Expanded(child: _Seg(value: minutes, label: 'MIN')),
            _Colon(),
            Expanded(child: _Seg(value: seconds, label: 'SEC')),
          ],
        ),
      ],
    );
  }
}

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
            border: Border.all(
              color: const Color(0xFF9B3FAF).withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B3FAF).withValues(alpha: 0.12),
                blurRadius: 16,
              ),
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _Colon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Text(
        ':',
        style: GoogleFonts.outfit(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: const Color(0xFFFFD700),
        ),
      ),
    );
  }
}

// ── Teaser / Locked Features Section ──────────────────────────────────────────
class _TeaserFeaturesSection extends StatelessWidget {
  const _TeaserFeaturesSection({
    required this.features,
    required this.glow,
  });

  final List<(IconData, String, String)> features;
  final AnimationController glow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎁', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              'What\'s Waiting for You',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Unlocks exclusively on January 18',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppTheme.textMuted,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),

        ...features.asMap().entries.map((entry) {
          final i = entry.key;
          final (icon, title, desc) = entry.value;
          return _LockedFeatureCard(
            icon: icon,
            title: title,
            description: desc,
            delay: i * 0.04,
            glow: glow,
          );
        }),
      ],
    );
  }
}

class _LockedFeatureCard extends StatelessWidget {
  const _LockedFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.glow,
  });

  final IconData icon;
  final String title, description;
  final double delay;
  final AnimationController glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF3A1A5A).withValues(alpha: 0.8),
        ),
        gradient: const LinearGradient(
          colors: [Color(0xFF12102A), Color(0xFF1A1030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Blurred/frosted content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1050).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF7B4FBF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF9B7FDF).withValues(alpha: 0.5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title with blur effect (opacity trick)
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: AppTheme.textMuted.withValues(alpha: 0.5),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Lock badge
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1050),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7B4FBF).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Color(0xFF9B7FDF),
                    ),
                  ),
                ],
              ),
            ),

            // Shimmer overlay line at top
            AnimatedBuilder(
              animation: glow,
              builder: (_, __) => Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color.lerp(
                          const Color(0xFF7B4FBF),
                          const Color(0xFFFFD700),
                          glow.value,
                        )!.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom Motivation ──────────────────────────────────────────────────────────
class _BottomMotivation extends StatelessWidget {
  const _BottomMotivation({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) {
    final msg = days == 0
        ? 'Opening today... 🎉'
        : days == 1
            ? 'Just one more sleep! 🌙'
            : days <= 7
                ? 'Almost there — the wait is almost over! 🌸'
                : 'Every day that passes is a day closer to celebrating you 💕';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E0A20), Color(0xFF160C28)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF5A3080).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          const Text('💝', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Text(
            msg,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3A1060).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7B4FBF).withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              '🔓  Unlocks January 18',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFAF8FDF),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BIRTHDAY UNLOCKED VIEW — shown only on Jan 18
// ═══════════════════════════════════════════════════════════════════════════════
class _BirthdayUnlockedView extends StatelessWidget {
  const _BirthdayUnlockedView({required this.pulse, required this.float});
  final AnimationController pulse, float;

  static const _wishes = [
    ('🌸', 'Endless Smiles', 'May every day bring you pure joy'),
    ('💫', 'Dreams Come True', 'All your wishes, beautifully fulfilled'),
    ('💕', 'Endless Love', 'Wrapped in warmth and care forever'),
    ('🌙', 'Sweet Memories', 'More beautiful days ahead for us'),
    ('🎵', 'Songs of You', 'Every melody reminds me of you'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Bouncing cake
          AnimatedBuilder(
            animation: float,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, -10 * math.sin(float.value * math.pi)),
              child: const Text('🎂', style: TextStyle(fontSize: 72)),
            ),
          ),

          const SizedBox(height: 16),

          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFDF6F9B), Color(0xFFAF6FDF)],
            ).createShader(b),
            child: Text(
              '🎉 HAPPY BIRTHDAY! 🎉',
              style: GoogleFonts.outfit(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'January 18 — Your Day ✨',
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),

          const SizedBox(height: 28),

          // Unlocked banner
          AnimatedBuilder(
            animation: pulse,
            builder: (_, __) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(const Color(0xFF4A1580), const Color(0xFF6A20A0), pulse.value)!,
                    Color.lerp(const Color(0xFF8A1560), const Color(0xFFAA2080), pulse.value)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withValues(
                      alpha: 0.2 + 0.15 * pulse.value,
                    ),
                    blurRadius: 40,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🔓', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 10),
                  Text(
                    'Birthday Mode Unlocked!',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD700),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Today is your day, Paril. Every moment of this app is dedicated to you — with all my heart. 💕',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.65,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Birthday wishes
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Birthday Wishes 🌸',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ..._wishes.map((w) {
                final (emoji, title, subtitle) = w;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1030), Color(0xFF221040)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF9B3FAF).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFDF6F9B),
                        size: 16,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARTICLES LAYER
// ═══════════════════════════════════════════════════════════════════════════════
class _ParticlesLayer extends StatelessWidget {
  const _ParticlesLayer({required this.controller, required this.isBirthday});
  final AnimationController controller;
  final bool isBirthday;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _ParticlesPainter(controller.value, isBirthday),
        size: Size.infinite,
      ),
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter(this.t, this.isBirthday);
  final double t;
  final bool isBirthday;

  static const _colors = [
    Color(0xFFFFD700),
    Color(0xFFDF6F9B),
    Color(0xFFAF6FDF),
    Color(0xFF6FD7DF),
    Color(0xFFFF9B6F),
  ];

  static const _configs = [
    (0.08, 0.0, 0.3, 5.0),
    (0.25, 0.05, 0.45, 3.5),
    (0.48, 0.1, 0.35, 6.0),
    (0.68, 0.0, 0.55, 4.0),
    (0.88, 0.08, 0.4, 5.5),
    (0.18, 0.15, 0.5, 3.0),
    (0.62, 0.02, 0.28, 7.0),
    (0.38, 0.12, 0.6, 4.5),
    (0.78, 0.18, 0.38, 3.8),
    (0.55, 0.06, 0.48, 5.2),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _configs.length; i++) {
      final (sx, startY, speed, r) = _configs[i];
      final phase = (t * speed + i * 0.18) % 1.0;
      final dx = math.sin(phase * math.pi * 2 + i * 1.5) * 20.0;
      final x = sx * size.width + dx;
      final y = (startY + phase) * size.height;
      final maxAlpha = isBirthday ? 0.55 : 0.2;
      final alpha = ((1.0 - phase) * maxAlpha).clamp(0.0, maxAlpha);
      final color = _colors[i % _colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(phase * math.pi * 3 + i.toDouble());
      // Tiny diamond shape
      final path = Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.6, 0)
        ..lineTo(0, r)
        ..lineTo(-r * 0.6, 0)
        ..close();
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter old) => old.t != t;
}
