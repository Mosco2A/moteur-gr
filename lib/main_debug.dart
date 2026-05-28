import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/test_trail_config.dart';
import 'core/debug/debug_config.dart';
import 'core/debug/emulator_detector.dart';
import 'core/debug/gps_simulator.dart';
import 'core/engine/trail_engine.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Provider du simulateur GPS, injectable en debug.
final gpsSimulatorProvider = Provider<GpsSimulator?>((ref) {
  return null;
});

/// Provider de la configuration debug.
final debugConfigProvider = Provider<DebugConfig>((ref) {
  return const DebugConfig();
});

/// Point d'entree debug du Moteur GR.
///
/// Usage : flutter run -t lib/main_debug.dart
/// Garde par kDebugMode -- JAMAIS en release.
void main() {
  if (!kDebugMode) {
    throw StateError(
      'main_debug.dart ne doit JAMAIS etre lance en release mode. '
      'Utilisez main.dart pour la production.',
    );
  }

  final config = testTrailConfig;
  final isEmulator = EmulatorDetector.detect();

  final debugConfig = DebugConfig.auto(
    isEmulator: isEmulator,
    simulateGps: isEmulator,
  );

  debugPrint('[MoteurGR Debug] $debugConfig');

  runApp(
    ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(config),
        debugConfigProvider.overrideWithValue(debugConfig),
      ],
      child: MaterialApp.router(
        title: '${config.displayName} [DEBUG]',
        debugShowCheckedModeBanner: true,
        theme: AppTheme.buildDarkTheme(
          primaryColor: Color(config.primaryColorValue),
          secondaryColor: Color(config.secondaryColorValue),
        ),
        routerConfig: appRouter,
      ),
    ),
  );
}
