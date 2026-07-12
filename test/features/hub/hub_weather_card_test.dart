import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/weather_cache_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_weather_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests LOT-B de la tuile météo réelle du HUB : rendu (données + pastille
/// orage) + NON-RÉGRESSION overflow aux largeurs mobiles (retour Lot A #95062).
void main() {
  late AppDatabase db;

  /// Prévision cache avec un orage le jour même (déclenche la pastille).
  String stormForecastJson() {
    final now = DateTime.now();
    return jsonEncode({
      'latitude': 45.51,
      'longitude': 2.96,
      'days': [
        {
          'date': DateTime(now.year, now.month, now.day).toIso8601String(),
          'temperatureMax': 24.0,
          'temperatureMin': 14.0,
          'precipitationMm': 12.0,
          'windSpeedKmh': 35.0,
          'uvIndex': 5.0,
          'weatherCode': 95, // orage -> stormProbability 100
          'precipitationProbabilityMax': 80.0,
        },
      ],
    });
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await StagesDao(db).insertAll([
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(1),
        name: Value('Départ - Refuge haut'),
        distanceKm: Value(12.0),
        elevationGainM: Value(900),
        elevationLossM: Value(200),
        startLat: Value(45.51),
        startLng: Value(2.96),
        endLat: Value(45.55),
        endLng: Value(2.99),
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap() {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topCenter,
                child: HubWeatherCard(),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/trail/:id/weather',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        databaseProvider.overrideWithValue(db),
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatusValues.offline),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('affiche le titre et la pastille orage quand orage prévu',
      (tester) async {
    await WeatherCacheDao(db).upsertForecast(
      trailId: 'test-trail',
      stageNumber: 1,
      forecastJson: stormForecastJson(),
    );

    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(t.hub.weather.title), findsOneWidget);
    // Pastille orage visible (données cache avec code 95).
    expect(find.text(t.hub.weather.alertStorm), findsOneWidget);
  });

  testWidgets('sans données, affiche un état indisponible (pas de crash)',
      (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text(t.hub.weather.title), findsOneWidget);
    expect(find.text(t.hub.weather.unavailable), findsOneWidget);
    expect(find.text(t.hub.weather.alertStorm), findsNothing);
  });

  // --- Non-régression overflow mobile (retour Lot A #95062) ---
  group('non-regression overflow largeurs mobiles', () {
    const mobileWidths = <double>[360, 390, 412];

    Future<List<String>> overflowsAt(
      WidgetTester tester,
      double width,
    ) async {
      // Cache avec orage : cas le plus large (titre + pastille orage).
      await WeatherCacheDao(db).upsertForecast(
        trailId: 'test-trail',
        stageNumber: 1,
        forecastJson: stormForecastJson(),
      );

      final captured = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          captured.add(message.split('\n').first);
        } else {
          (previous ?? FlutterError.presentError)(details);
        }
      };

      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }

      for (var guard = 0; guard < captured.length + 8; guard++) {
        final pending = tester.takeException();
        if (pending == null) break;
        if (!pending.toString().contains('overflowed')) {
          throw pending;
        }
      }
      return captured;
    }

    for (final width in mobileWidths) {
      testWidgets('aucun overflow a ${width.toInt()} px', (tester) async {
        final overflows = await overflowsAt(tester, width);
        expect(
          overflows,
          isEmpty,
          reason: 'HubWeatherCard deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });
}
