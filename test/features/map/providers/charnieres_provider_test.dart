import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/community/community_facade.dart';
import 'package:moteur_gr/features/map/map_facade.dart' show gpxTrackProvider;
import 'package:moteur_gr/features/map/providers/charnieres_provider.dart';

import '../../../comportement/traces_fabriquees_671.dart';

/// LOT 671-04 — LES CHARNIERES DU SENTIER ENRICHIES PAR LES JONCTIONS (fiche
/// E2 (5)) : chaque jonction projetee SEULE sur tout le trace (la fenetre de
/// 50 segments de project ratait un repere eloigne), ignoree au-dela de 80 m
/// du trace, et zero jonction — le cas d'aujourd'hui — sans effet.
void main() {
  group('l enrichissement par les reperes de type jonction', () {
    // 300 segments de 10 m vers l'est, puis 300 vers le nord.
    final trace = traceDesSommets([(0, 0), (3000, 0), (3000, 3000)]);

    test('un repere LOIN du dernier projete est trouve : chaque jonction est '
        'projetee seule, sur tout le trace', () {
      final pres = versDegres(200, 5);
      final loin = versDegres(3005, 2500);
      final c = projeterLesJonctions(trace, [pres, loin]);
      // Les metres du plan local et ceux de Haversine different de 0,1 %.
      expect(c.first.abscisseM, closeTo(200, 1));
      expect(c.last.abscisseM, closeTo(5500, 10));
      // Le piege mesure : en passant l'index du precedent, la fenetre de 50
      // segments de project ne va pas jusqu'au second repere.
      final premier = TrackProjector.project(
        userLat: pres.lat,
        userLng: pres.lng,
        trackPoints: trace,
      );
      final glisse = TrackProjector.project(
        userLat: loin.lat,
        userLng: loin.lng,
        trackPoints: trace,
        lastKnownIndex: premier.trackIndexPosition,
      );
      expect(glisse.distanceFromStartM, lessThan(1000));
    });

    test('une jonction a plus de 80 m du trace est IGNOREE', () {
      final c = projeterLesJonctions(trace, [
        versDegres(1000, 79),
        versDegres(1000, 81),
      ]);
      expect(c, hasLength(1));
      expect(c.single.enrichie, isTrue);
    });

    test(
      'le fournisseur lit la base : une jonction du sentier s ajoute aux '
      'charnieres calculees ; un autre type de repere ne compte pas',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final id = testTrailConfig.id;
        final j = versDegres(1500, 3);
        final eau = versDegres(2000, 3);
        for (final (cle, type, p) in [
          ('j1', WaypointType.jonction, j),
          ('e1', WaypointType.eau, eau),
        ]) {
          await db.waypointsDao.upsertWaypoints([
            WaypointCompanion.insert(
              id: cle,
              trailId: id,
              type: type,
              latitude: p.lat,
              longitude: p.lng,
              titre: cle,
              lastUpdatedAt: DateTime.utc(2026, 10, 7),
            ),
          ]);
        }
        final container = ProviderContainer(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            databaseProvider.overrideWithValue(db),
            gpxTrackProvider(id).overrideWith((ref) async => trace),
          ],
        );
        addTearDown(container.dispose);
        final c = await container.read(charnieresDuSentierProvider(id).future);
        // Les metres du plan local et ceux de Haversine different de 0,1 %.
        expect(c.map((x) => x.enrichie), [true, false]);
        expect(c.first.abscisseM, closeTo(1500, 3));
        expect(c.last.abscisseM, closeTo(3000, 5));
      },
    );

    test('ZERO jonction declaree, le cas d aujourd hui : les charnieres '
        'calculees, rien d autre', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final id = testTrailConfig.id;
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          databaseProvider.overrideWithValue(db),
          gpxTrackProvider(id).overrideWith((ref) async => trace),
        ],
      );
      addTearDown(container.dispose);
      final c = await container.read(charnieresDuSentierProvider(id).future);
      expect(c.where((x) => x.enrichie), isEmpty);
      expect(c, hasLength(1));
    });
  });
}
