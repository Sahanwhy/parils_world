import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Developer message screen — shows Sahan's heartfelt note to Paril.
/// Text is stored in SharedPreferences and editable via Settings.
/// Ships with placeholder text until the owner supplies the real message.
class DeveloperMessageScreen extends StatefulWidget {
  const DeveloperMessageScreen({super.key});

  @override
  State<DeveloperMessageScreen> createState() => _DeveloperMessageScreenState();
}

class _DeveloperMessageScreenState extends State<DeveloperMessageScreen>
    with SingleTickerProviderStateMixin {
  String _message = AppConfig.defaultDeveloperMessage;
  bool _loaded = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _loadMessage();
  }

  Future<void> _loadMessage() async {
    if (!mounted) return;
    setState(() {
      _message = AppConfig.defaultDeveloperMessage;
      _loaded = true;
    });
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: _loaded
                    ? _buildContent(context)
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

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingM,
        vertical: AppTheme.spacingS,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppTheme.textSecondary,
            onPressed: () => context.go(AppRoutes.welcome),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppTheme.spacingM),
              // Decorative accent bar
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Text(
                'A message from the developer',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Text(
                    'Written with love by ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  Text(
                    AppConfig.developerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accentVioletLight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(width: 6),
                  const FloatingHeart(size: 14),
                ],
              ),
              const SizedBox(height: AppTheme.spacingXL),
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spacingL),
                borderColor: AppTheme.accentViolet.withAlpha(60),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentViolet.withAlpha(15),
                    AppTheme.cardColor,
                    AppTheme.accentRose.withAlpha(10),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Opening quotation mark
                    Text(
                      '\u201C',
                      style: TextStyle(
                        fontSize: 56,
                        height: 0.6,
                        color: AppTheme.accentViolet.withAlpha(120),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingM),
                    Text(
                      _message,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.75,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingL),
                    // Closing hearts row
                    Row(
                      children: [
                        const Spacer(),
                        FloatingHeart(
                          size: 14,
                          color: AppTheme.accentRose.withAlpha(180),
                          delay: const Duration(milliseconds: 0),
                        ),
                        const SizedBox(width: 6),
                        FloatingHeart(
                          size: 10,
                          delay: const Duration(milliseconds: 300),
                        ),
                        const SizedBox(width: 6),
                        FloatingHeart(
                          size: 14,
                          color: AppTheme.accentViolet.withAlpha(180),
                          delay: const Duration(milliseconds: 600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXXL),
              GradientButton(
                label: 'A Song Dedicated to My Love',
                icon: Icons.music_note_rounded,
                onPressed: () => context.go(AppRoutes.songDedication),
              ),
              const SizedBox(height: AppTheme.spacingL),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit this message in Settings'),
                  onPressed: () => context.go(AppRoutes.settings),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXL),
            ],
          ),
        ),
      ),
    );
  }
}
