import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_role.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Dashboard shell screen.
/// Shows feature tiles; unimplemented ones display "Coming soon".
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  AppRole _role = AppRole.paril;
  bool _loaded = false;
  late AnimationController _staggerController;

  static const List<_FeatureTile> _allTiles = [
    _FeatureTile(
      id: 'timer',
      label: 'Relationship\nTimer',
      icon: Icons.timer_rounded,
      description: 'Every second counts.',
      gradient: LinearGradient(
        colors: [Color(0xFF7B4FBF), Color(0xFF9B3F7F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/cover_relationship.jpg',
      badgeText: 'Live 💕',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'photos',
      label: 'Photo Dump',
      icon: Icons.photo_library_rounded,
      description: 'Growing up through the years.',
      gradient: LinearGradient(
        colors: [Color(0xFF3F7FBF), Color(0xFF3F5FBF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/photo_dump_cover.jpg',
      badgeText: 'Childhood & Teen',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'memories',
      label: 'Letters That\nBrought Us',
      icon: Icons.auto_stories_rounded,
      description: 'The letters that started it all 💌',
      gradient: LinearGradient(
        colors: [Color(0xFF5F3FAF), Color(0xFF7F3FAF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/drawing_each_other.jpg',
      badgeText: '💌 Letters',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'gpt',
      label: 'ParilGPT',
      icon: Icons.chat_bubble_rounded,
      description: 'AI chat — Paril & Sahan style.',
      gradient: LinearGradient(
        colors: [Color(0xFF2F6F4F), Color(0xFF3F8F6F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/cover_photo_parilgpt.jpg',
      badgeText: 'AI Chat 🐦',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'alarm',
      label: 'Voice Alarm',
      icon: Icons.alarm_rounded,
      description: 'Wake up to her voice ⏰',
      gradient: LinearGradient(
        colors: [Color(0xFFAF6F2F), Color(0xFFBF4F4F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      isImplemented: false,
    ),
    _FeatureTile(
      id: 'flappy',
      label: 'Paril Bird',
      icon: Icons.sports_esports_rounded,
      description: 'Tap to fly!',
      gradient: LinearGradient(
        colors: [Color(0xFF5F8F3F), Color(0xFF3F6F2F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/paril_bird.png',
      badgeText: 'Mini Game 🎮',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'birthday',
      label: 'Her Birthday',
      icon: Icons.cake_rounded,
      description: 'Countdown to Jan 18 🎂',
      gradient: LinearGradient(
        colors: [Color(0xFF9B3FAF), Color(0xFFAF3F6F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/birthday_image.jpg',
      coverAlignment: Alignment.topCenter,
      badgeText: '🎂 Jan 18',
      isImplemented: true,
    ),
    _FeatureTile(
      id: 'songs',
      label: 'Songs That\nRemind Us',
      icon: Icons.library_music_rounded,
      description: 'The songs that belong to us 🎵',
      gradient: LinearGradient(
        colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      coverImage: 'assets/images/sajde_song_cover.jpg',
      badgeText: '🎵 Playlist',
      isImplemented: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _loadRole();
  }

  Future<void> _loadRole() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _role = storage.getRole();
      _loaded = true;
    });
    _staggerController.forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  List<_FeatureTile> get _visibleTiles => _allTiles;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              Expanded(
                child: _loaded
                    ? _buildGrid()
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentViolet,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingL,
        AppTheme.spacingM,
        AppTheme.spacingM,
        AppTheme.spacingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => AppTheme.accentGradient
                      .createShader(bounds),
                  child: Text(
                    'App Paril',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGlow.withAlpha(80),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _role.displayName,
                        style: const TextStyle(
                          color: AppTheme.accentVioletLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Settings icon
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: AppTheme.textSecondary,
            tooltip: 'Settings',
            onPressed: () => context.go(AppRoutes.settings),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final tiles = _visibleTiles;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingM,
            AppTheme.spacingS,
            AppTheme.spacingM,
            AppTheme.spacingXXL,
          ),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacingM,
              crossAxisSpacing: AppTheme.spacingM,
              childAspectRatio: 0.88,
            ),
            itemCount: tiles.length,
            itemBuilder: (context, index) {
              final tile = tiles[index];
              final delay = index * 0.12;
              final start = delay.clamp(0.0, 0.8);
              final end = (delay + 0.4).clamp(0.1, 1.0);
              final animation = CurvedAnimation(
                parent: _staggerController,
                curve: Interval(start, end, curve: Curves.easeOutCubic),
              );
              return AnimatedBuilder(
                animation: animation,
                builder: (_, child) => Opacity(
                  opacity: animation.value,
                  child: Transform.translate(
                    offset: Offset(0, 24 * (1 - animation.value)),
                    child: child,
                  ),
                ),
                child: _DashboardTile(tile: tile, role: _role),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardTile extends StatelessWidget {
  const _DashboardTile({required this.tile, required this.role});

  final _FeatureTile tile;
  final AppRole role;

  @override
  Widget build(BuildContext context) {
    final isAvailable = tile.isImplemented;
    final hasCover = tile.coverImage != null && isAvailable;

    return GestureDetector(
      onTap: isAvailable ? () => _navigate(context) : _showComingSoon(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          boxShadow: [
            BoxShadow(
              color: isAvailable
                  ? AppTheme.backgroundDeep.withAlpha(160)
                  : Colors.transparent,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base Layer: Either Cover Image or Theme Gradient
              if (hasCover) ...[
                Image.asset(
                  tile.coverImage!,
                  fit: BoxFit.cover,
                  alignment: tile.coverAlignment ?? Alignment.center,
                  errorBuilder: (context, error, stackTrace) => Container(
                    decoration: BoxDecoration(gradient: tile.gradient),
                  ),
                ),
                // Exquisite multi-stop vignette scrim for max contrast
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.12),
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.94),
                      ],
                      stops: const [0.0, 0.30, 0.65, 1.0],
                    ),
                  ),
                ),
              ] else ...[
                Container(
                  decoration: BoxDecoration(
                    gradient: isAvailable
                        ? tile.gradient
                        : LinearGradient(
                            colors: [
                              AppTheme.cardColor,
                              AppTheme.cardColorElevated,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  ),
                ),
              ],

              // 2. Interactive InkWell & Content
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isAvailable
                      ? () => _navigate(context)
                      : _showComingSoon(context),
                  splashColor: Colors.white.withAlpha(25),
                  highlightColor: Colors.white.withAlpha(10),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row: Frosted icon button + Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: hasCover
                                    ? Colors.black.withValues(alpha: 0.40)
                                    : Colors.white.withValues(
                                        alpha: isAvailable ? 0.20 : 0.08),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                      alpha: hasCover ? 0.30 : 0.15),
                                  width: 1,
                                ),
                                boxShadow: hasCover
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                tile.icon,
                                color: isAvailable
                                    ? Colors.white
                                    : AppTheme.textMuted,
                                size: 22,
                              ),
                            ),
                            if (!isAvailable)
                              const ComingSoonBadge()
                            else if (tile.badgeText != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.50),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.28),
                                    width: 0.8,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  tile.badgeText!,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),

                        // Title
                        Text(
                          tile.label,
                          style: GoogleFonts.outfit(
                            color: isAvailable
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.25,
                            shadows: hasCover
                                ? const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Description
                        Text(
                          tile.description,
                          style: GoogleFonts.outfit(
                            color: isAvailable
                                ? Colors.white.withValues(alpha: 0.88)
                                : AppTheme.textMuted,
                            fontSize: 11,
                            height: 1.3,
                            shadows: hasCover
                                ? const [
                                    Shadow(
                                      color: Colors.black,
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Crisp Glass Border
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                    border: Border.all(
                      color: isAvailable
                          ? Colors.white.withValues(alpha: hasCover ? 0.22 : 0.15)
                          : AppTheme.dividerColor,
                      width: 1.1,
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

  void _navigate(BuildContext context) {
    if (tile.id == 'timer') {
      context.go(AppRoutes.relationshipTimer);
    } else if (tile.id == 'flappy') {
      context.go(AppRoutes.flappyBird);
    } else if (tile.id == 'gpt') {
      context.go(AppRoutes.parilGpt);
    } else if (tile.id == 'photos') {
      context.go(AppRoutes.photoDump);
    } else if (tile.id == 'birthday') {
      context.go(AppRoutes.birthday);
    } else if (tile.id == 'memories') {
      context.go(AppRoutes.memories);
    } else if (tile.id == 'songs') {
      context.go(AppRoutes.remindingSongs);
    }
  }

  VoidCallback _showComingSoon(BuildContext context) {
    return () {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E142B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppTheme.accentViolet.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Text(
                tile.id == 'alarm' ? '⏰' : '✨',
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${tile.label.replaceAll('\n', ' ')} — Coming Soon!',
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
            tile.id == 'alarm'
                ? 'Voice Alarm is in the workshop! Soon, you\'ll be able to wake up to her sweet voice recordings, morning motivation, and gentle alarms. 🎙️💕'
                : 'This magical feature is currently being crafted with love. Stay tuned for the upcoming update! 💫',
            style: GoogleFonts.outfit(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Can\'t Wait! ✨',
                style: GoogleFonts.outfit(
                  color: AppTheme.accentRose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    };
  }
}

/// Data model for a dashboard feature tile.
class _FeatureTile {
  const _FeatureTile({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
    required this.gradient,
    this.coverImage,
    this.coverAlignment,
    this.badgeText,
    this.isImplemented = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final String description;
  final LinearGradient gradient;
  final String? coverImage;
  final Alignment? coverAlignment;
  final String? badgeText;
  final bool isImplemented;
}
