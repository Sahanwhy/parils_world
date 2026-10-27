import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/welcome/presentation/welcome_screen.dart';
import '../../features/developer_message/presentation/developer_message_screen.dart';
import '../../features/song_dedication/presentation/song_dedication_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/settings_privacy/presentation/settings_screen.dart';
import '../../features/flappy_bird/presentation/paril_bird_screen.dart';
import '../../features/paril_gpt/presentation/paril_gpt_screen.dart';
import '../../features/photo_dump/presentation/photo_dump_screen.dart';
import '../../features/relationship_timer/presentation/relationship_timer_screen.dart';
import '../../features/birthday/presentation/birthday_screen.dart';
import '../../features/memories/presentation/memories_screen.dart';
import '../../features/reminding_songs/presentation/reminding_songs_screen.dart';

/// Named route paths. Keep route strings here to avoid magic strings.
abstract class AppRoutes {
  static const String welcome = '/';
  static const String developerMessage = '/developer-message';
  static const String songDedication = '/song-dedication';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String flappyBird = '/paril-bird';
  static const String parilGpt = '/paril-gpt';
  static const String photoDump = '/photo-dump';
  static const String relationshipTimer = '/relationship-timer';
  static const String birthday = '/birthday';
  static const String memories = '/memories';
  static const String remindingSongs = '/reminding-songs';
}

/// Application router using go_router with a fade transition.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.welcome,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      name: 'welcome',
      pageBuilder: (context, state) =>
          _fadePage(state, const WelcomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.developerMessage,
      name: 'developerMessage',
      pageBuilder: (context, state) =>
          _fadePage(state, const DeveloperMessageScreen()),
    ),
    GoRoute(
      path: AppRoutes.songDedication,
      name: 'songDedication',
      pageBuilder: (context, state) =>
          _fadePage(state, const SongDedicationScreen()),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: 'dashboard',
      pageBuilder: (context, state) =>
          _fadePage(state, const DashboardScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: 'settings',
      pageBuilder: (context, state) =>
          _fadePage(state, const SettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.flappyBird,
      name: 'flappyBird',
      pageBuilder: (context, state) =>
          _fadePage(state, const ParilBirdScreen()),
    ),
    GoRoute(
      path: AppRoutes.parilGpt,
      name: 'parilGpt',
      pageBuilder: (context, state) =>
          _fadePage(state, const ParilGptScreen()),
    ),
    GoRoute(
      path: AppRoutes.photoDump,
      name: 'photoDump',
      pageBuilder: (context, state) =>
          _fadePage(state, const PhotoDumpScreen()),
    ),
    GoRoute(
      path: AppRoutes.relationshipTimer,
      name: 'relationshipTimer',
      pageBuilder: (context, state) =>
          _fadePage(state, const RelationshipTimerScreen()),
    ),
    GoRoute(
      path: AppRoutes.birthday,
      name: 'birthday',
      pageBuilder: (context, state) =>
          _fadePage(state, const BirthdayScreen()),
    ),
    GoRoute(
      path: AppRoutes.memories,
      name: 'memories',
      pageBuilder: (context, state) =>
          _fadePage(state, const MemoriesScreen()),
    ),
    GoRoute(
      path: AppRoutes.remindingSongs,
      name: 'remindingSongs',
      pageBuilder: (context, state) =>
          _fadePage(state, const RemindingSongsScreen()),
    ),
  ],
  errorBuilder: (context, state) => _NotFoundPage(state.error),
);

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage(this.error);
  final Exception? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Page not found'),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
