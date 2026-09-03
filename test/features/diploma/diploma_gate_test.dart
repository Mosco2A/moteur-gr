import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/features/diploma/presentation/diploma_screen.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20, LOT 3 (#99433), point 3.B / critere (a) — le Diplome est
/// VERROUILLE sur un vrai trek non fini et DEVERROUILLE sur une vitrine.
void main() {
  const trailId = 'test-trail-diploma';

  const config = TrailConfig(
    id: trailId,
    name: 'Test Trail',
    displayName: 'Test Trail',
    tagline: 'tagline',
    totalStages: 4,
    totalDistanceKm: 40.0,
    totalElevationGain: 2000,
    region: 'Region',
    country: 'France',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/gpx/test.gpx',
    defaultDuration: 4,
    availableDurations: [2, 4, 6],
  );

  late AppDatabase db;

  StagesCompanion stage(int n) => StagesCompanion(
        trailId: const Value(trailId),
        stageNumber: Value(n),
        name: Value('Etape $n'),
        distanceKm: const Value(10.0),
        elevationGainM: const Value(500),
        elevationLossM: const Value(400),
        description: const Value('desc'),
        startLat: const Value(42.0),
        startLng: const Value(9.0),
        endLat: const Value(42.1),
        endLng: const Value(9.1),
        difficulty: const Value('moderate'),
      );

  Future<void> pumpDiploma(
    WidgetTester tester, {
    bool showcase = false,
  }) async {
    LocaleSettings.setLocaleRaw('fr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(config),
          currentTrailIdProvider.overrideWith((ref) => trailId),
          demoModeServiceProvider.overrideWithValue(
            DemoModeService(
              showcaseTrailIds: showcase ? {trailId} : <String>{},
            ),
          ),
        ],
        child: const MaterialApp(home: DiplomaScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 400));
  }

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('VRAI trek non fini (non-vitrine) : diplome VERROUILLE',
      (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    // Session terminee mais parcours PAS entierement marche.
    await db.trekSessionsDao.upsertSession(TrekSession(
      id: 'sess',
      trailId: trailId,
      startedAt: DateTime.utc(2026, 6, 15),
      finishedAt: DateTime.utc(2026, 6, 16),
      status: 'completed',
      completedStages: const ['1', '2'],
      parcoursFullyWalked: false,
    ));

    await pumpDiploma(tester);

    // Etat verrouille : titre + cadenas ; pas de champ « votre nom ».
    expect(find.text(t.diploma.lockedTitle), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text(t.diploma.yourName), findsNothing);
  });

  testWidgets('VITRINE : diplome DEVERROUILLE (demo)', (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    // Aucune session : sur un vrai trek ce serait verrouille.
    await pumpDiploma(tester, showcase: true);

    // Deverrouille : pas de cadenas, le contenu du diplome est present.
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text(t.diploma.yourName), findsOneWidget);
    expect(find.text(t.diploma.recapStats), findsOneWidget);
  });

  testWidgets(
      'FINISHER reel : diplome deverrouille + libelle Integral + chiffres reels',
      (tester) async {
    await db.stagesDao.insertAll([stage(1), stage(2), stage(3), stage(4)]);
    await db.trekSessionsDao.upsertSession(TrekSession(
      id: 'sess',
      trailId: trailId,
      startedAt: DateTime.utc(2026, 6, 15),
      finishedAt: DateTime.utc(2026, 6, 18),
      status: 'completed',
      completedStages: const ['1', '2', '3', '4'],
      parcoursFullyWalked: true,
    ));

    await pumpDiploma(tester);

    // Deverrouille + libelle Integral (parcours entier reellement fini).
    expect(find.byIcon(Icons.lock_outline), findsNothing);
    expect(find.text(t.diploma.labelIntegral), findsOneWidget);
    // Chiffres REELS (4 etapes / 40 km / 2000 m) — ici egaux au sentier car
    // parcours entier, mais issus de la session (etapes marchees).
    expect(
      find.text(t.diploma.recapStages.replaceAll('{count}', '4')),
      findsOneWidget,
    );
    expect(
      find.text(t.diploma.recapDistance.replaceAll('{km}', '40')),
      findsOneWidget,
    );
  });
}
