import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

import 'banc_du_trace_671.dart';

/// LOT 671-06 — LES STATISTIQUES SUR LE TRACE, PROUVEES SANS AUCUN CAPTEUR.
///
/// Faux trace fabrique (`banc_du_trace_671.dart`), fausse horloge, base Drift
/// en memoire, fausse position courante. Personne ne marchera et personne ne
/// regardera une capture d'ecran : ce que ce lot affirme, il le chiffre ici.
void main() {
  final trace = fabricatedTrace();
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Future<void> store(
    List<SessionTrackPoint> points, {
    TrackPointSource source = TrackPointSource.gps,
    int? dayIndex,
  }) async {
    for (final p in points) {
      await db.sessionTrackPointsDao.insertPoint(
        trailId: testTrailConfig.id,
        sessionId: p.sessionId,
        dayIndex: dayIndex,
        lat: p.lat,
        lng: p.lng,
        altitude: p.altitude,
        recordedAt: p.recordedAt,
        source: source,
      );
    }
  }

  final session = TrekSession(
    id: 'banc',
    trailId: testTrailConfig.id,
    startedAt: benchStart,
    status: 'active',
  );

  ProviderContainer container({TrackPositionState? position}) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(testTrailConfig.id).overrideWith((ref) async => trace),
        trekSessionManagerProvider.overrideWith(
          () => _FixedSession(
            TrackingSessionState(
              status: TrackingSessionStatus.recording,
              session: session,
            ),
          ),
        ),
        if (position != null)
          trackPositionProvider.overrideWithValue(AsyncData(position)),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  TrackPositionState at(double meters) {
    final p = TrackProjector.locate(
      trackPoints: trace,
      distanceFromStartM: meters,
    );
    return TrackPositionState(
      userLat: p.lat,
      userLng: p.lng,
      projectedLat: p.lat,
      projectedLng: p.lng,
      distanceToTrackM: 0,
      distanceFromStartM: meters,
      distanceRemainingM: trace.last.distanceFromStart - meters,
      trackIndex: p.segmentIndex,
      stageDetection: (stageNumber: 1, event: 'between'),
      isOffTrack: false,
      isEstimated: true,
    );
  }

  group('671-06 (3) — la duree et la vitesse sont toujours la', () {
    test('LA DUREE DU JOUR ET LA VITESSE MOYENNE SONT RENSEIGNEES ET VALENT CE '
        'QU ELLES VALAIENT AVANT LE LOT, seconde et centieme', () async {
      // Une journee sur la montee en ligne droite : la corde y vaut le
      // sentier, la distance ne bouge donc pas, et la vitesse non plus.
      final readings = walk(trace, everyM: batteryFirstSpacingM, untilM: 2000);
      await store(readings);

      final before = computeTrackStats(readings);
      final after = await container().read(liveTrekStatsProvider.future);

      expect(
        after.duration,
        before.duration,
        reason:
            'duree APRES ${after.duration}, AVANT ${before.duration} ; vitesse '
            'APRES ${after.averageSpeedKmh}, AVANT ${before.averageSpeedKmh}',
      );
      expect(after.duration, const Duration(minutes: 30));
      expect(
        after.averageSpeedKmh,
        isNotNull,
        reason:
            'VITESSE ABSENTE : duree APRES ${after.duration}. Une tranche de '
            'trace n a pas d horodatage ; le temps doit venir des releves.',
      );
      expect(after.averageSpeedKmh!, closeTo(before.averageSpeedKmh!, 0.005));
      expect(after.averageSpeedKmh!, closeTo(4.0, 0.005));
    });

    test('UN SEUL RELEVE REEL : duree nulle, vitesse nulle, et la distance et '
        'le denivele de la tranche rendus quand meme', () async {
      await store(walk(trace, everyM: 100, untilM: 0));

      final stats = await container(
        position: at(300),
      ).read(liveTrekStatsProvider.future);

      // De 0 m (le releve) a 300 m (la position estimee) : 45 m de montee.
      expect(stats.duration, Duration.zero);
      expect(stats.averageSpeedKmh, isNull);
      expect(stats.hasData, isFalse);
      expect(stats.distanceKm, closeTo(0.3, 0.0005));
      expect(stats.elevationGainM, 45);
    });

    test('LA CARTE BORNE LA TRANCHE A LA POSITION COURANTE, le temps aux '
        'releves', () async {
      await store(walk(trace, everyM: batteryFirstSpacingM, untilM: 1000));

      final onFix = await container().read(liveTrekStatsProvider.future);
      final ahead = await container(
        position: at(1150),
      ).read(liveTrekStatsProvider.future);

      expect(onFix.distanceKm, closeTo(1.0, 0.0005));
      expect(ahead.distanceKm, closeTo(1.15, 0.0005));
      expect(ahead.duration, onFix.duration);
    });
  });

  group('671-06 (6) — le temoin du lot 671-03, avec la duree', () {
    test('AJOUTER DES POINTS ESTIMES EN BASE NE CHANGE NI LA DISTANCE, NI LE '
        'DENIVELE, NI LA DUREE, NI LA VITESSE', () async {
      // TRIVIAL POUR LA GEOMETRIE, ET C'EST VOULU : elle vient du trace. Pas
      // pour le temps : ces points estimes sont dates APRES le dernier
      // releve, et ils allongeraient la duree s'ils y entraient.
      final readings = walk(trace, everyM: batteryFirstSpacingM, untilM: 3200);
      await store(readings);
      final before = await container().read(liveTrekStatsProvider.future);

      await store([
        for (var i = 0; i < 10; i++)
          SessionTrackPoint(
            id: 0,
            trailId: testTrailConfig.id,
            sessionId: 'banc',
            lat: 42.5 + i * 0.01,
            lng: 9.3,
            altitude: i.isEven ? 3000 : 100,
            recordedAt: readings.last.recordedAt.add(Duration(minutes: i + 1)),
          ),
      ], source: TrackPointSource.estimated);
      final after = await container().read(liveTrekStatsProvider.future);

      expect(after.distanceKm, before.distanceKm);
      expect(after.elevationGainM, before.elevationGainM);
      expect(after.elevationLossM, before.elevationLossM);
      expect(after.duration, before.duration);
      expect(after.averageSpeedKmh, before.averageSpeedKmh);
      expect(before.elevationGainM, 300);
      expect(before.averageSpeedKmh, isNotNull);
    });
  });

  group('671-06 — le perimetre de la carte n a pas change', () {
    test('LA CARTE : TOUTE LA SESSION, deux journees comprises', () async {
      final day1 = walk(trace, everyM: batteryFirstSpacingM, untilM: 2000);
      await store(day1, dayIndex: 1);
      // Le lendemain, la marche reprend la ou elle s'etait arretee.
      final day2 = [
        for (final p in walk(trace, everyM: batteryFirstSpacingM, untilM: 3200))
          if (p.recordedAt.difference(benchStart).inMinutes > 30)
            p.copyWith(recordedAt: p.recordedAt.add(const Duration(days: 1))),
      ];
      await store(day2, dayIndex: 2);

      final stats = await container().read(liveTrekStatsProvider.future);

      expect(stats.distanceKm, closeTo(3.2, 0.002));
      expect(stats.pointCount, day1.length + day2.length);
      expect(
        stats.duration,
        day2.last.recordedAt.difference(day1.first.recordedAt),
      );
    });
  });

  group(
    '671-06 (8) — la distance parcourue de l etape n a pas ete touchee',
    () {
      test('stageDistanceCoveredProvider rend la distance PROJETEE, zero sans '
          'projection', () {
        final c = ProviderContainer(
          overrides: [
            trackPositionProvider.overrideWithValue(AsyncData(at(812))),
          ],
        );
        addTearDown(c.dispose);
        final none = ProviderContainer(
          overrides: [
            trackPositionProvider.overrideWithValue(const AsyncLoading()),
          ],
        );
        addTearDown(none.dispose);

        expect(c.read(stageDistanceCoveredProvider), 812);
        expect(none.read(stageDistanceCoveredProvider), 0);
      });
    },
  );
}

/// Session figee (meme principe que les autres tests de tracking).
class _FixedSession extends TrekSessionManagerNotifier {
  _FixedSession(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
