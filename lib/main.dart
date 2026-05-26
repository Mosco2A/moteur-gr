import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/trail_config.dart';
import 'core/config/test_trail_config.dart';
import 'core/engine/trail_engine.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const MoteurGrApp(config: testTrailConfig));
}

/// Application racine du Moteur GR.
///
/// Wrappee dans ProviderScope pour Riverpod,
/// utilise GoRouter pour la navigation.
class MoteurGrApp extends StatelessWidget {
  const MoteurGrApp({super.key, required this.config});

  final TrailConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp.router(
        title: config.displayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildDarkTheme(
          primaryColor: Color(config.primaryColorValue),
          secondaryColor: Color(config.secondaryColorValue),
        ),
        routerConfig: appRouter,
      ),
    );
  }
}
