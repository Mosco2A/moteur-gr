import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// Correctif L6-2 — les chiffres de la barre de carte sont MESURES.
///
/// Le point sensible de ce correctif n'est pas le calcul (il est partage avec
/// le journal et le recapitulatif) mais la SOURCE : `TrekStats` n'est
/// alimente par personne, la seule source vivante est la trace persistee de
/// la session. Ces tests verifient que c'est bien elle qui est lue, et que
/// rien n'est invente quand elle est vide.
///
/// LOT 671-06 — LE SUJET A CHANGE PAR DECISION DE CHRISTOPHE : la distance et
/// le denivele se mesurent desormais SUR LE TRACE, entre le premier releve
/// reel de la session et le dernier ; les releves ne font plus que borner et
/// dater la tranche. Ces tests recoivent donc un trace, et ce trace passe par
/// leurs releves avec les memes altitudes : les chiffres attendus n'ont pas
/// bouge d'une unite. Sans lui, le conteneur chargeait le trace du sentier
/// par defaut, a des centaines de kilometres des releves.
void main() {
  late AppDatabase db;

  /// Le trace du test, le long du meridien 3° E, par les releves des tests.
  final trace = <TrackPoint>[];
  for (final (lat, alt) in [
    (45.000, 1000.0),
    (45.005, 1050.0),
    (45.010, 1200.0),
    (45.020, 1100.0),
  ]) {
    trace.add(
      TrackPoint(
        lat: lat,
        lng: 3.0,
        altitude: alt,
        distanceFromStart: (lat - 45.0) * 111194.93,
      ),
    );
  }

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  TrekSession session(String id) => TrekSession(
    id: id,
    trailId: 'sentier-bleu',
    startedAt: DateTime.utc(2026, 6, 15, 8),
    status: 'active',
  );

  ProviderContainer conteneur({
    required TrackingSessionStatus status,
    TrekSession? active,
  }) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(testTrailConfig.id).overrideWith((ref) async => trace),
        trekSessionManagerProvider.overrideWith(
          () => _FixedSessionNotifier(
            TrackingSessionState(status: status, session: active),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> tracer(
    String sessionId,
    List<(double lat, double lng, double alt, int minute)> points,
  ) async {
    for (final p in points) {
      await db.sessionTrackPointsDao.insertPoint(
        trailId: 'sentier-bleu',
        lat: p.$1,
        lng: p.$2,
        altitude: p.$3,
        recordedAt: DateTime.utc(2026, 6, 15, 8, p.$4),
        sessionId: sessionId,
        source: TrackPointSource.gps,
      );
    }
  }

  group('liveTrekStatsProvider', () {
    test(
      'mesure denivele et vitesse sur la trace de la session en cours',
      () async {
        await tracer('sess-1', [
          (45.000, 3.000, 1000, 0),
          (45.010, 3.000, 1200, 30),
          (45.020, 3.000, 1100, 60),
        ]);

        final container = conteneur(
          status: TrackingSessionStatus.recording,
          active: session('sess-1'),
        );
        final stats = await container.read(liveTrekStatsProvider.future);

        expect(stats.hasData, isTrue);
        expect(stats.pointCount, 3);
        // Montee de 200 m puis descente de 100 m, au-dessus du seuil de bruit.
        expect(stats.elevationGainM, 200);
        expect(stats.elevationLossM, 100);
        expect(stats.maxAltitudeM, 1200);
        // Environ 2,2 km en une heure : une vitesse de marche plausible.
        expect(stats.duration, const Duration(hours: 1));
        expect(stats.averageSpeedKmh, isNotNull);
        expect(stats.averageSpeedKmh!, inInclusiveRange(1.0, 4.0));
      },
    );

    test(
      'ne lit QUE la session en cours, pas la randonnee precedente',
      () async {
        await tracer('sess-precedente', [
          (44.000, 2.000, 500, 0),
          (44.050, 2.000, 2000, 30),
        ]);
        await tracer('sess-2', [
          (45.000, 3.000, 1000, 0),
          (45.005, 3.000, 1050, 20),
        ]);

        final container = conteneur(
          status: TrackingSessionStatus.recording,
          active: session('sess-2'),
        );
        final stats = await container.read(liveTrekStatsProvider.future);

        expect(stats.pointCount, 2);
        expect(stats.elevationGainM, 50);
      },
    );

    test('RIEN hors trek : aucune lecture, aucun chiffre', () async {
      await tracer('sess-3', [
        (45.000, 3.000, 1000, 0),
        (45.010, 3.000, 1200, 30),
      ]);

      final container = conteneur(status: TrackingSessionStatus.idle);
      final stats = await container.read(liveTrekStatsProvider.future);

      expect(stats.hasData, isFalse);
      expect(stats.pointCount, 0);
      expect(stats.averageSpeedKmh, isNull);
    });

    test('un seul point ne fabrique ni vitesse ni denivele', () async {
      await tracer('sess-4', [(45.000, 3.000, 1000, 0)]);

      final container = conteneur(
        status: TrackingSessionStatus.recording,
        active: session('sess-4'),
      );
      final stats = await container.read(liveTrekStatsProvider.future);

      expect(stats.hasData, isFalse);
      expect(stats.averageSpeedKmh, isNull);
      expect(stats.elevationGainM, 0);
    });

    test('la trace continue d etre lue pendant une PAUSE', () async {
      await tracer('sess-5', [
        (45.000, 3.000, 1000, 0),
        (45.010, 3.000, 1200, 30),
      ]);

      final container = conteneur(
        status: TrackingSessionStatus.paused,
        active: session('sess-5'),
      );
      final stats = await container.read(liveTrekStatsProvider.future);

      expect(stats.hasData, isTrue);
      expect(stats.elevationGainM, 200);
    });
  });
}

/// Session figee (meme principe que les autres tests de tracking).
class _FixedSessionNotifier extends TrekSessionManagerNotifier {
  _FixedSessionNotifier(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
