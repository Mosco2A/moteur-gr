import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// LOT 671-03 — LE RECALAGE SUR LE TRACE, PROUVE SANS AUCUN CAPTEUR REEL.
///
/// Faux robinet GPS (le vrai `PositionController`, branche sur un faux flux
/// et de faux tirs), fausse horloge des tirs, faux flux de points estimes,
/// faux trace, fausses preferences, base Drift en memoire. Personne ne
/// marchera avec un telephone : ce que ce lot affirme, il le prouve ici.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('(4) LES CHIFFRES DU JOUR NE BOUGENT PAS', () {
    test('la distance et le denivele du jour sont IDENTIQUES au metre pres '
        'avec et sans points estimes en base', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      Future<void> add(TrackPointSource s, double lat, double alt, int min) =>
          db.sessionTrackPointsDao.insertPoint(
            trailId: 'sentier-bleu',
            sessionId: 'sess',
            lat: lat,
            lng: 3.0,
            altitude: alt,
            recordedAt: DateTime.utc(2026, 6, 15, 8, min),
            source: s,
          );
      for (var i = 0; i <= 6; i++) {
        await add(TrackPointSource.gps, 45 + i * 0.002, 1000.0 + i * 40, i * 3);
      }
      final session = TrekSession(
        id: 'sess',
        trailId: 'sentier-bleu',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );
      Future<dynamic> stats() async {
        final c = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trekSessionManagerProvider.overrideWith(
              () => _FixedSession(
                TrackingSessionState(
                  status: TrackingSessionStatus.recording,
                  session: session,
                ),
              ),
            ),
          ],
        );
        addTearDown(c.dispose);
        return c.read(liveTrekStatsProvider.future);
      }

      final before = await stats();
      // Des points estimes qui, comptes, ajouteraient des kilometres et des
      // centaines de metres de denivele.
      for (var i = 0; i < 6; i++) {
        await add(
          TrackPointSource.estimated,
          45.5 + (i.isEven ? 0.05 : -0.05),
          i.isEven ? 3000 : 200,
          i * 3 + 1,
        );
      }
      final after = await stats();
      expect(after.distanceKm, before.distanceKm);
      expect(after.elevationGainM, before.elevationGainM);
      expect(after.elevationLossM, before.elevationLossM);
      expect(after.pointCount, before.pointCount);
      expect(after.duration, before.duration);
    });
  });
}

class _FixedSession extends TrekSessionManagerNotifier {
  _FixedSession(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
