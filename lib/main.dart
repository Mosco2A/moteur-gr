import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/trail_config.dart';
import 'core/engine/trail_engine.dart';
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

class MoteurGrApp extends StatelessWidget {
  const MoteurGrApp({super.key, required this.config});

  final TrailConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp(
        title: config.displayName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.buildDarkTheme(
          primaryColor: Color(config.primaryColorValue),
          secondaryColor: Color(config.secondaryColorValue),
        ),
        home: _HomeScreen(config: config),
      ),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.config});
  final TrailConfig config;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(config.displayName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hiking, size: 80,
              color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(config.displayName,
              style: theme.textTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(config.tagline,
              style: theme.textTheme.bodyLarge),
            const SizedBox(height: 32),
            Text('Moteur GR v0.1.0',
              style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
