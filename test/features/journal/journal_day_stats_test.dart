import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/journal/providers/journal_day_providers.dart';

/// CORRECTIF L4-3 — RESUME CHIFFRE DU JOUR ET CUMUL DEPUIS LE DEPART.
///
/// Les chiffres sont MESURES sur la trace GPS : ni somme d'etapes nominale,
/// ni total theorique. Le denivele passe par le seuil de bruit de TrekStats
/// (3 m) — sans lui, le tremblement de l'altimetre fabrique plusieurs
/// centaines de metres de D+ sur une journee plate.
void main() {
  const trailId = 'sentier-bleu';

  SessionTrackPoint point(DateTime at, double lat, double alt) {
    return SessionTrackPoint(
      id: 0,
      trailId: trailId,
      lat: lat,
      lng: 9.0,
      altitude: alt,
      recordedAt: at,
    );
  }

  group('L4-3 — calcul des chiffres du jour', () {
    test('moins de deux points : aucun chiffre a montrer', () {
      expect(computeDayStats(const []).hasData, isFalse);
      expect(
        computeDayStats([point(DateTime(2026, 6, 10, 9), 42.0, 900)]).hasData,
        isFalse,
      );
    });

    test('distance, D+, D- et duree sortent de la trace', () {
      final base = DateTime(2026, 6, 10, 8);
      final stats = computeDayStats([
        point(base, 42.000, 900),
        point(base.add(const Duration(hours: 1)), 42.010, 1000),
        point(base.add(const Duration(hours: 2)), 42.020, 950),
      ]);

      // ~1,11 km par centieme de degre de latitude, deux fois.
      expect(stats.distanceKm, closeTo(2.22, 0.05));
      expect(stats.elevationGainM, 100);
      expect(stats.elevationLossM, 50);
      expect(stats.duration, const Duration(hours: 2));
      expect(stats.maxAltitudeM, 1000);
      expect(stats.hasData, isTrue);
    });

    test('le tremblement d altimetre sous 3 m ne fabrique pas de denivele',
        () {
      final base = DateTime(2026, 6, 10, 8);
      final stats = computeDayStats([
        for (var i = 0; i < 40; i++)
          point(
            base.add(Duration(minutes: i)),
            42.0 + i * 0.0001,
            // Oscillation de 2 m autour de 900 : du bruit, pas du relief.
            900 + (i.isEven ? 2.0 : 0.0),
          ),
      ]);

      expect(stats.elevationGainM, 0);
      expect(stats.elevationLossM, 0);
      expect(stats.distanceKm, greaterThan(0));
    });
  });

  group('L4-3 — cumul depuis le depart', () {
    Future<void> noteAt(AppDatabase db, DateTime at) {
      return db.journalDao.insertEntry(
        JournalEntriesCompanion.insert(
          trailId: trailId,
          stageNumber: 1,
          content: const Value('note'),
          createdAt: at,
        ),
      );
    }

    Future<void> traceAt(AppDatabase db, DateTime at, double lat) {
      return db.sessionTrackPointsDao.insertPoint(
        trailId: trailId,
        sessionId: 'session-a',
        lat: lat,
        lng: 9.0,
        altitude: 900,
        recordedAt: at,
      );
    }

    test('le cumul s arrete a la journee affichee, jours transferts exclus',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteAt(db, DateTime(2026, 6, 10, 9));
      await noteAt(db, DateTime(2026, 6, 11, 9));
      await noteAt(db, DateTime(2026, 6, 12, 9));
      // Jour 1 : deux points proches. Jour 2 : deux points proches, mais
      // TRES loin du jour 1 (transfert nocturne). Jour 3 : idem.
      await traceAt(db, DateTime(2026, 6, 10, 8), 42.000);
      await traceAt(db, DateTime(2026, 6, 10, 9), 42.010);
      await traceAt(db, DateTime(2026, 6, 11, 8), 43.000);
      await traceAt(db, DateTime(2026, 6, 11, 9), 43.010);
      await traceAt(db, DateTime(2026, 6, 12, 8), 44.000);
      await traceAt(db, DateTime(2026, 6, 12, 9), 44.010);

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        trailIdProvider.overrideWithValue(trailId),
      ]);
      addTearDown(container.dispose);
      container.read(journalDaysProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Sur le jour 2 : cumul = jour 1 + jour 2, PAS le jour 3.
      container
          .read(journalSelectedDayRawProvider.notifier)
          .select(DateTime(2026, 6, 11));
      final cumul = await container.read(journalCumulativeStatsProvider.future);

      // 2 x ~1,11 km, et surtout PAS les ~111 km du transfert nocturne :
      // additionner les journees separement est ce qui l'evite.
      expect(cumul.distanceKm, closeTo(2.22, 0.1));
      expect(cumul.pointCount, 4);
    });
  });
}
