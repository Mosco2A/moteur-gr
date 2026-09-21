import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// Correctif L6-2 — les chiffres de la barre de carte sont MESURES.
///
/// Le point sensible de ce correctif n'est pas le calcul (il est partage avec
/// le journal et le recapitulatif) mais la SOURCE : `TrekStats` n'est
/// alimente par personne, la seule source vivante est la trace persistee de
/// la session. Ces tests verifient que c'est bien elle qui est lue, et que
/// rien n'est invente quand elle est vide.
void main() {
  late AppDatabase db;

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
      );
    }
  }

  group('liveTrekStatsProvider', () {
    test('mesure denivele et vitesse sur la trace de la session en cours',
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
    });

    test('ne lit QUE la session en cours, pas la randonnee precedente',
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
    });

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
