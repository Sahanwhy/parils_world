import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_role.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/services/mongo_db_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Welcome / role-selection screen.
/// Lets the user choose: Paril | Friends | Family.
/// Persists the choice but does NOT gate private data by itself.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  AppRole? _selectedRole;
  bool _isLoading = false;
  late AnimationController _titleController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOut),
    );
    _titleSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutCubic),
    );
    _titleController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_selectedRole == null) return;

    // For Friends or Family — ask for their name first
    if (_selectedRole == AppRole.friends || _selectedRole == AppRole.family) {
      final name = await _showNameDialog();
      final effectiveName = (name != null && name.trim().isNotEmpty)
          ? name.trim()
          : (_selectedRole == AppRole.friends ? 'Friend' : 'Family Member');
      // Save locally and register to MongoDB (fire and forget)
      final storage = await LocalStorageService.getInstance();
      await storage.setPlayerName(effectiveName);
      MongoDbService().registerPlayer(
        name: effectiveName,
        role: _selectedRole!.name,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    final storage = await LocalStorageService.getInstance();
    await storage.setRole(_selectedRole!);
    if (!mounted) return;
    setState(() => _isLoading = false);
    // Show developer message for everyone
    context.go(AppRoutes.developerMessage);
  }

  /// Shows a dialog asking for the visitor's name.
  Future<String?> _showNameDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppTheme.accentViolet.withAlpha(80)),
        ),
        title: Row(
          children: [
            const Text('👋 ', style: TextStyle(fontSize: 22)),
            Text(
              'What\'s your name?',
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'So Sahan knows who\'s visiting! 💜',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name…',
                prefixIcon: const Icon(Icons.person_outline_rounded,
                    color: AppTheme.accentVioletLight),
              ),
              onSubmitted: (value) {
                Navigator.pop(ctx, value.trim());
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(
              'Skip',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentViolet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx, controller.text.trim());
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingL,
              vertical: AppTheme.spacingXL,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    AppTheme.spacingXL * 2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppTheme.spacingXXL),
                  _buildRoleCards(),
                  const SizedBox(height: AppTheme.spacingXL),
                  _buildContinueButton(),
                  const SizedBox(height: AppTheme.spacingL),
                  _buildFootnote(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SlideTransition(
      position: _titleSlide,
      child: FadeTransition(
        opacity: _titleFade,
        child: Column(
          children: [
            // Decorative hearts
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingHeart(
                  size: 12,
                  delay: const Duration(milliseconds: 0),
                ),
                const SizedBox(width: 12),
                FloatingHeart(
                  size: 18,
                  color: AppTheme.accentViolet.withAlpha(180),
                  delay: const Duration(milliseconds: 400),
                ),
                const SizedBox(width: 12),
                FloatingHeart(
                  size: 12,
                  delay: const Duration(milliseconds: 800),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              'App Paril',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
                foreground: Paint()
                  ..shader = const LinearGradient(
                    colors: [AppTheme.accentVioletLight, AppTheme.accentRoseLight],
                  ).createShader(const Rect.fromLTWH(0, 0, 220, 60)),
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Who\'s using the app?',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCards() {
    return Column(
      children: [
        _RoleCard(
          role: AppRole.paril,
          icon: Icons.favorite_rounded,
          description: 'Your private world — memories, messages & more.',
          isSelected: _selectedRole == AppRole.paril,
          onTap: () => setState(() => _selectedRole = AppRole.paril),
          accentColor: AppTheme.accentRose,
        ),
        const SizedBox(height: AppTheme.spacingM),
        _RoleCard(
          role: AppRole.friends,
          icon: Icons.people_rounded,
          description: 'See shared moments and public memories.',
          isSelected: _selectedRole == AppRole.friends,
          onTap: () => setState(() => _selectedRole = AppRole.friends),
          accentColor: AppTheme.accentViolet,
        ),
        const SizedBox(height: AppTheme.spacingM),
        _RoleCard(
          role: AppRole.family,
          icon: Icons.home_rounded,
          description: 'Family-shared content and highlights.',
          isSelected: _selectedRole == AppRole.family,
          onTap: () => setState(() => _selectedRole = AppRole.family),
          accentColor: AppTheme.accentVioletLight,
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return AnimatedOpacity(
      opacity: _selectedRole != null ? 1.0 : 0.4,
      duration: const Duration(milliseconds: 250),
      child: GradientButton(
        label: 'Continue',
        icon: Icons.arrow_forward_rounded,
        onPressed: _selectedRole != null && !_isLoading ? _onContinue : null,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildFootnote() {
    return Text(
      'Your selection is saved locally on this device.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppTheme.textMuted,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.description,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  final AppRole role;
  final IconData icon;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accentColor.withAlpha(40),
                  AppTheme.cardColor,
                ],
              )
            : AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: isSelected ? accentColor : AppTheme.dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: accentColor.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          splashColor: accentColor.withAlpha(20),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              children: [
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withAlpha(30)
                        : AppTheme.dividerColor.withAlpha(80),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? accentColor : AppTheme.textMuted,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSelected
                              ? accentColor
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: accentColor,
                    size: 22,
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
