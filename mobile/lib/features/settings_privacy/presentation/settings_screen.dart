import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shared_widgets.dart';

/// Settings & Privacy screen.
/// For Milestone 1: edit developer message, view role, clear stored data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentRole = '';
  String? _relationshipDate;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await LocalStorageService.getInstance();
    if (!mounted) return;
    setState(() {
      _currentRole = storage.getRole().displayName;
      _relationshipDate = storage.getRelationshipStartDate();
      _loaded = true;
    });
  }

  Future<void> _switchRole() async {
    context.go(AppRoutes.welcome);
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
            onPressed: () => context.go(AppRoutes.dashboard),
          ),
          Text(
            'Settings & Privacy',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Current Role'),
          _buildRoleCard(),
          const SizedBox(height: AppTheme.spacingL),
          _buildSectionHeader('Relationship Date'),
          _buildRelationshipDateCard(),
          const SizedBox(height: AppTheme.spacingL),
          _buildSectionHeader('About'),
          _buildAboutCard(),
          const SizedBox(height: AppTheme.spacingXXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppTheme.spacingXS,
        bottom: AppTheme.spacingS,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.accentViolet,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.person_rounded,
            color: AppTheme.accentVioletLight,
            size: 22,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Role', style: Theme.of(context).textTheme.labelMedium),
                Text(
                  _currentRole,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _switchRole,
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipDateCard() {
    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            color: AppTheme.accentRose,
            size: 22,
          ),
          const SizedBox(width: AppTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start date',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  _relationshipDate ?? 'Not set — configure in Milestone 2',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _relationshipDate != null
                        ? AppTheme.textPrimary
                        : AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // Relationship date configuration comes in Milestone 2
          const ComingSoonBadge(),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return AppCard(
      child: Column(
        children: [
          _buildAboutRow(Icons.apps_rounded, 'App name', AppConfig.appName),
          const Divider(height: AppTheme.spacingL),
          _buildAboutRow(
            Icons.code_rounded,
            'Version',
            AppConfig.appVersion,
          ),
          const Divider(height: AppTheme.spacingL),
          _buildAboutRow(
            Icons.developer_mode_rounded,
            'Developer',
            AppConfig.developerName,
          ),
          const Divider(height: AppTheme.spacingL),
          _buildAboutRow(
            Icons.lock_outline_rounded,
            'Data storage',
            'Local on this device only',
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: AppTheme.spacingM),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
