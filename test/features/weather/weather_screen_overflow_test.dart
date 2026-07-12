import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/weather/presentation/weather_screen.dart';
import 'package:moteur_gr/features/weather/widgets/today_stage_weather_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests LOT-B de l'écran météo E31 : rendu + NON-RÉGRESSION overflow mobile.
///
/// Retour d'expérience du Lot A (#95062) : un layout qui ne déborde pas à
/// 1200 px peut déborder à 360/390/412 px. Ce fichier rend l'écran COMPLET à
/// chaque largeur mobile et échoue si le moindre RenderFlex signale un overflow.
///
/// Mode hors-ligne + DB seedée : l'écran bascule sur le seed de démonstration
/// (déterministe, aucun réseau) et affiche toute l'UX (carte du jour, J+1/J+2,
/// « toutes les étapes », bandeau source).
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // 3 étapes fictives pour test-trail (coords Auvergne inventées).
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
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(2),
        name: Value('Refuge haut - Col des cratères oubliés du massif'),
        distanceKm: Value(15.0),
        elevationGainM: Value(1100),
        elevationLossM: Value(400),
        startLat: Value(45.55),
        startLng: Value(2.99),
        endLat: Value(45.60),
        endLng: Value(3.05),
      ),
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(3),
        name: Value('Col - Arrivée'),
        distanceKm: Value(10.0),
        elevationGainM: Value(300),
        elevationLossM: Value(1200),
        startLat: Value(45.60),
        startLng: Value(3.05),
        endLat: Value(45.58),
        endLng: Value(3.10),
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        databaseProvider.overrideWithValue(db),
        // Hors-ligne : force le repli seed démo (déterministe, sans réseau).
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatusValues.offline),
        ),
      ],
      child: TranslationProvider(
        child: const MaterialApp(
          home: WeatherScreen(
            trailId: 'test-trail',
            stageNumber: 1,
            region: 'Auvergne',
          ),
        ),
      ),
    );
  }

  group('WeatherScreen — rendu', () {
    testWidgets('affiche la carte du jour et le titre', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.weather.title), findsWidgets);
      // Carte « aujourd'hui » présente (seed démo).
      expect(find.byType(TodayStageWeatherCard), findsOneWidget);
      expect(find.text(t.weather.today), findsOneWidget);
      // Vue « toutes les étapes » présente.
      expect(find.text(t.weather.allStages), findsOneWidget);
    });

    testWidgets('cloisonnement : aucun libellé GR20 / Fra li Monti',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.textContaining('GR20'), findsNothing);
      expect(find.textContaining('Fra li Monti'), findsNothing);
    });
  });

  // --- Non-régression overflow largeurs mobiles (retour Lot A #95062) ---
  group('non-regression overflow largeurs mobiles', () {
    const mobileWidths = <double>[360, 390, 412];

    Future<List<String>> overflowsAt(
      WidgetTester tester,
      double width,
    ) async {
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

      tester.view.physicalSize = Size(width, 3200);
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
          reason:
              'WeatherScreen deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });
}
