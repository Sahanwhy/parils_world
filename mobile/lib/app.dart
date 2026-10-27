import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root MaterialApp.router that wires up theme and navigation.
class AppParil extends StatelessWidget {
  const AppParil({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'App Paril',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
