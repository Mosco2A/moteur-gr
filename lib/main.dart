import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/trail_config.dart';
import 'core/engine/trail_engine.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  const devConfig = TrailConfig(
    id: 'dev',
    name: 'DEV',
    displayName: 'Moteur GR',
    tagline: 'Votre compagnon de trek',
    totalStages: 10,
    totalDistanceKm: 100,
    totalElevationGain: 5000,
    region: 'Dev',
    country: 'France',
    primaryColorValue: 0xFF2D5016,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/dev.gpx',
  );

  runApp(const MoteurGrApp(config: devConfig));
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
