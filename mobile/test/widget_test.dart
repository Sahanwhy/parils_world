import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_paril/core/config/app_role.dart';
import 'package:app_paril/core/config/app_config.dart';
import 'package:app_paril/core/storage/local_storage_service.dart';
import 'package:app_paril/core/theme/app_theme.dart';
import 'package:app_paril/features/welcome/presentation/welcome_screen.dart';
import 'package:app_paril/features/developer_message/presentation/developer_message_screen.dart';
import 'package:app_paril/features/dashboard/presentation/dashboard_screen.dart';
import 'package:app_paril/features/settings_privacy/presentation/settings_screen.dart';
import 'package:app_paril/features/flappy_bird/presentation/paril_bird_screen.dart';
import 'package:app_paril/features/flappy_bird/domain/models/game_models.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Returns a testable MaterialApp wrapper using an in-memory GoRouter.
Widget _wrappedApp(Widget child) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (ctx, _) => child),
      GoRoute(
        path: '/developer-message',
        builder: (ctx, _) => const DeveloperMessageScreen(),
      ),
      GoRoute(
        path: '/song-dedication',
        builder: (ctx, _) => const SizedBox(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (ctx, _) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (ctx, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/paril-bird',
        builder: (ctx, _) => const ParilBirdScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (ctx, _) => const WelcomeScreen(),
      ),
    ],
  );
  return MaterialApp.router(
    theme: AppTheme.darkTheme,
    routerConfig: router,
  );
}

// ---------------------------------------------------------------------------
// Unit tests - AppRole
// ---------------------------------------------------------------------------

void main() {
  group('AppRole', () {
    test('fromString returns correct role for known values', () {
      expect(AppRole.fromString('paril'), AppRole.paril);
      expect(AppRole.fromString('friends'), AppRole.friends);
      expect(AppRole.fromString('family'), AppRole.family);
    });

    test('fromString falls back to paril for unknown values', () {
      expect(AppRole.fromString('unknown'), AppRole.paril);
      expect(AppRole.fromString(''), AppRole.paril);
    });

    test('isPrivate is true only for Paril', () {
      expect(AppRole.paril.isPrivate, isTrue);
      expect(AppRole.friends.isPrivate, isFalse);
      expect(AppRole.family.isPrivate, isFalse);
    });

    test('displayName values are correct', () {
      expect(AppRole.paril.displayName, 'Paril');
      expect(AppRole.friends.displayName, 'Friends');
      expect(AppRole.family.displayName, 'Family');
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests - LocalStorageService
  // ---------------------------------------------------------------------------

  group('LocalStorageService', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.getInstance();
    });

    test('getRole returns paril by default', () async {
      final storage = await LocalStorageService.getInstance();
      expect(storage.getRole(), AppRole.paril);
    });

    test('setRole and getRole round-trip correctly', () async {
      final storage = await LocalStorageService.getInstance();
      await storage.setRole(AppRole.friends);
      expect(storage.getRole(), AppRole.friends);
    });

    test('getDeveloperMessage returns default when not set', () async {
      final storage = await LocalStorageService.getInstance();
      expect(
        storage.getDeveloperMessage(),
        AppConfig.defaultDeveloperMessage,
      );
    });

    test('setDeveloperMessage and getDeveloperMessage round-trip', () async {
      final storage = await LocalStorageService.getInstance();
      const custom = 'Hello Paril';
      await storage.setDeveloperMessage(custom);
      expect(storage.getDeveloperMessage(), custom);
    });

    test('getRelationshipStartDate returns null when not set', () async {
      final storage = await LocalStorageService.getInstance();
      expect(storage.getRelationshipStartDate(), isNull);
    });

    test('setRelationshipStartDate persists correctly', () async {
      final storage = await LocalStorageService.getInstance();
      const iso = '2023-06-15T00:00:00.000Z';
      await storage.setRelationshipStartDate(iso);
      expect(storage.getRelationshipStartDate(), iso);
    });

    test('clearRelationshipStartDate removes the value', () async {
      final storage = await LocalStorageService.getInstance();
      await storage.setRelationshipStartDate('2023-01-01T00:00:00.000Z');
      await storage.clearRelationshipStartDate();
      expect(storage.getRelationshipStartDate(), isNull);
    });

    test('isSetupComplete defaults to false', () async {
      final storage = await LocalStorageService.getInstance();
      expect(storage.isSetupComplete(), isFalse);
    });

    test('setSetupComplete and isSetupComplete round-trip', () async {
      final storage = await LocalStorageService.getInstance();
      await storage.setSetupComplete(complete: true);
      expect(storage.isSetupComplete(), isTrue);
    });

    test('getFlappyHighScore defaults to 0 and setFlappyHighScore persists', () async {
      final storage = await LocalStorageService.getInstance();
      expect(storage.getFlappyHighScore(), 0);
      await storage.setFlappyHighScore(42);
      expect(storage.getFlappyHighScore(), 42);
    });

    test('getFlappyIceCreamCount defaults to 0 and setFlappyIceCreamCount persists', () async {
      final storage = await LocalStorageService.getInstance();
      expect(storage.getFlappyIceCreamCount(), 0);
      await storage.setFlappyIceCreamCount(15);
      expect(storage.getFlappyIceCreamCount(), 15);
    });
  });

  // ---------------------------------------------------------------------------
  // Unit tests - AppConfig
  // ---------------------------------------------------------------------------

  group('AppConfig', () {
    test('defaultDeveloperMessage is not empty', () {
      expect(AppConfig.defaultDeveloperMessage, isNotEmpty);
    });

    test('developerName is Sahan', () {
      expect(AppConfig.developerName, 'Sahan');
    });

    test('appName is App Paril', () {
      expect(AppConfig.appName, 'App Paril');
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests - WelcomeScreen
  // ---------------------------------------------------------------------------

  group('WelcomeScreen widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders App Paril title', (tester) async {
      await tester.pumpWidget(_wrappedApp(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('App Paril'), findsOneWidget);
      // Advance past the repeating FloatingHeart animation cycles
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders all three role options', (tester) async {
      await tester.pumpWidget(_wrappedApp(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Paril'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('shows subtitle text', (tester) async {
      await tester.pumpWidget(_wrappedApp(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining("Who's using the app"), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('Continue button is visible', (tester) async {
      await tester.pumpWidget(_wrappedApp(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Continue'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('tapping a role card selects it without error', (tester) async {
      await tester.pumpWidget(_wrappedApp(const WelcomeScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('Friends'));
      await tester.pump();
      expect(find.text('Friends'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests - DashboardScreen
  // ---------------------------------------------------------------------------

  group('DashboardScreen widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders App Paril heading', (tester) async {
      await tester.pumpWidget(_wrappedApp(const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('App Paril'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('renders Coming soon badges for unimplemented tiles',
        (tester) async {
      await tester.pumpWidget(_wrappedApp(const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Coming soon'), findsWidgets);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('shows settings icon', (tester) async {
      await tester.pumpWidget(_wrappedApp(const DashboardScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests - DeveloperMessageScreen
  // ---------------------------------------------------------------------------

  group('DeveloperMessageScreen widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders developer name after loading', (tester) async {
      await tester.pumpWidget(_wrappedApp(const DeveloperMessageScreen()));
      // First pump triggers the FutureBuilder / setState in _loadMessage
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining(AppConfig.developerName), findsWidgets);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('renders A Song Dedicated to My Love button', (tester) async {
      await tester.pumpWidget(_wrappedApp(const DeveloperMessageScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('A Song Dedicated to My Love'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });
  });

  // ---------------------------------------------------------------------------
  // Widget tests - SettingsScreen
  // ---------------------------------------------------------------------------

  group('SettingsScreen widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders Settings and Privacy title', (tester) async {
      await tester.pumpWidget(_wrappedApp(const SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Settings & Privacy'), findsOneWidget);
    });

    testWidgets('renders App Paril in about section', (tester) async {
      await tester.pumpWidget(_wrappedApp(const SettingsScreen()));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text(AppConfig.appName), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Unit & Widget tests - Paril Bird Game
  // ---------------------------------------------------------------------------

  group('Paril Bird Game Models', () {
    test('VegetableObstacle calculates top and bottom rects accurately', () {
      final obs = VegetableObstacle(
        x: 100,
        width: 60,
        topHeight: 120,
        gap: 180,
        type: VegetableType.carrot,
      );

      expect(obs.topRect, const Rect.fromLTWH(100, 0, 60, 120));
      expect(
        obs.bottomRect(800, 75),
        const Rect.fromLTWH(100, 300, 60, 425),
      );
      expect(obs.type.displayName, 'Carrot Wall');
    });

    test('IceCreamBonus bounds and states', () {
      final bonus = IceCreamBonus(x: 150, y: 220, radius: 18);
      expect(bonus.bounds, Rect.fromCircle(center: const Offset(150, 220), radius: 18));
      expect(bonus.collected, isFalse);
    });

    test('GameParticle updates decay and life', () {
      final particle = GameParticle(
        x: 10,
        y: 10,
        vx: 10,
        vy: 10,
        size: 5,
        color: Colors.pink,
        life: 1.0,
        decay: 0.5,
      );
      expect(particle.isDead, isFalse);
      particle.update(1.0);
      expect(particle.life, 0.5);
      particle.update(1.0);
      expect(particle.isDead, isTrue);
    });
  });

  group('ParilBirdScreen widget', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders ready overlay with title and rules', (tester) async {
      await tester.pumpWidget(_wrappedApp(const ParilBirdScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Paril Bird'), findsOneWidget);
      expect(find.textContaining('Avoid vegetable walls'), findsOneWidget);
      expect(find.textContaining('Collect ice cream'), findsOneWidget);
      expect(find.textContaining('Tap anywhere to flap'), findsOneWidget);
      expect(find.text('Tap Screen to Start!'), findsOneWidget);
    });

    testWidgets('tapping starts game from ready state', (tester) async {
      await tester.pumpWidget(_wrappedApp(const ParilBirdScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Tap Screen to Start!'), findsOneWidget);

      // Tap screen to start flying
      await tester.tap(find.text('Tap Screen to Start!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ready overlay should be dismissed once playing
      expect(find.text('Tap Screen to Start!'), findsNothing);
    });
  });
}

