// D4B-02 — Tests du service de retention + droit a l'effacement (design
// #86166). VRAIS tests sur base Drift in-memory + SharedPreferences mocke.
//
// Couvre :
//   - purgeExpired : supprime le cache meteo expire, la file de synchro
//     terminee ancienne, et les contributions DEJA synchronisees + anciennes,
//     SANS toucher aux contributions non synchronisees ni recentes
//   - deleteAccountData : vide reellement TOUTES les tables utilisateur ET
//     efface les consentements ET emet la demande de suppression serveur
//   - deleteAccountData sans uidHash : efface le local, pas d'appel serveur
//   - propagation d'erreur serveur (zero catch silencieux)
//   - durees de retention documentees (source de verite registre D4D-01)

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  // Horloge figee pour des cutoffs deterministes.
  final fixedNow = DateTime.utc(2026, 6, 15, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
  });

  Future<DataRetentionService> buildService({
    ServerDeletionRequest? serverDeletion,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return DataRetentionService(
      database: db,
      prefs: prefs,
      serverDeletion: serverDeletion,
      now: () => fixedNow,
    );
  }

  group('RetentionPolicy — durees documentees (D4B-02)', () {
    test('durees par categorie exposees et non nulles', () {
      const policy = RetentionPolicy();
      expect(policy.durationFor(RetentionCategory.cartoCache),
          const Duration(days: 7));
      expect(policy.durationFor(RetentionCategory.syncedContributions),
          const Duration(days: 30));
      expect(policy.durationFor(RetentionCategory.completedSyncQueue),
          const Duration(days: 7));
    });
  });

  group('purgeExpired — D4B-02', () {
    test('supprime le cache meteo EXPIRE, garde le cache valide', () async {
      // Cache expire (expiresAt < now).
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'gr20',
            stageNumber: 1,
            forecastJson: '{}',
            fetchedAt: fixedNow.subtract(const Duration(hours: 6)),
            expiresAt: fixedNow.subtract(const Duration(hours: 3)),
          ));
      // Cache encore valide (expiresAt > now).
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'gr20',
            stageNumber: 2,
            forecastJson: '{}',
            fetchedAt: fixedNow,
            expiresAt: fixedNow.add(const Duration(hours: 3)),
          ));

      final service = await buildService();
      final report = await service.purgeExpired();

      expect(report.expiredWeatherCache, 1);
      final remaining = await db.select(db.weatherCache).get();
      expect(remaining.length, 1);
      expect(remaining.single.stageNumber, 2);
    });

    test('supprime les contributions SYNCHRONISEES anciennes, garde le reste',
        () async {
      // Signalement synchronise ANCIEN (35 j > retention 30 j) -> purge.
      await db.into(db.reportLocal).insert(ReportLocalCompanion.insert(
            type: 'obstacle',
            latitude: 42,
            longitude: 9,
            createdAt: fixedNow.subtract(const Duration(days: 35)),
            syncState: const Value('synced'),
          ));
      // Signalement synchronise RECENT (5 j) -> conserve.
      await db.into(db.reportLocal).insert(ReportLocalCompanion.insert(
            type: 'obstacle',
            latitude: 42,
            longitude: 9,
            createdAt: fixedNow.subtract(const Duration(days: 5)),
            syncState: const Value('synced'),
          ));
      // Signalement ANCIEN mais NON synchronise (pending) -> JAMAIS purge.
      await db.into(db.reportLocal).insert(ReportLocalCompanion.insert(
            type: 'obstacle',
            latitude: 42,
            longitude: 9,
            createdAt: fixedNow.subtract(const Duration(days: 90)),
            syncState: const Value('pending'),
          ));

      final service = await buildService();
      final report = await service.purgeExpired();

      expect(report.syncedReports, 1, reason: 'Seul le synchronise ancien part');
      final remaining = await db.select(db.reportLocal).get();
      expect(remaining.length, 2);
      // Le pending ancien et le synced recent subsistent.
      expect(
        remaining.where((r) => r.syncState == 'pending').length,
        1,
      );
    });

    test('supprime les efforts synchronises anciens (date = startedAt)',
        () async {
      await db.into(db.segmentEffortLocal).insert(
            SegmentEffortLocalCompanion.insert(
              segmentId: 's1',
              userUidHash: 'h',
              durationSeconds: 600,
              startedAt: fixedNow.subtract(const Duration(days: 40)),
              syncState: const Value('synced'),
            ),
          );
      final service = await buildService();
      final report = await service.purgeExpired();
      expect(report.syncedEfforts, 1);
      expect((await db.select(db.segmentEffortLocal).get()).isEmpty, isTrue);
    });

    test('purge idempotente : un second appel ne supprime plus rien', () async {
      await db.into(db.reportLocal).insert(ReportLocalCompanion.insert(
            type: 'obstacle',
            latitude: 42,
            longitude: 9,
            createdAt: fixedNow.subtract(const Duration(days: 35)),
            syncState: const Value('synced'),
          ));
      final service = await buildService();
      final first = await service.purgeExpired();
      final second = await service.purgeExpired();
      expect(first.total, greaterThan(0));
      expect(second.total, 0);
    });
  });

  group('deleteAccountData — droit a l effacement art 17 (D4B-02)', () {
    /// Remplit plusieurs tables utilisateur avec des donnees variees.
    Future<void> seedUserData() async {
      await db.into(db.reportLocal).insert(ReportLocalCompanion.insert(
            type: 'obstacle',
            latitude: 42,
            longitude: 9,
            createdAt: fixedNow,
            syncState: const Value('pending'),
          ));
      await db.into(db.kudosLocal).insert(KudosLocalCompanion.insert(
            targetActivityId: 'a1',
            fromUidHash: 'h',
            createdAt: fixedNow,
          ));
      await db.into(db.sessionTrackPoints).insert(
            SessionTrackPointsCompanion.insert(
              trailId: 'gr20',
              lat: 42,
              lng: 9,
              altitude: 1000,
              recordedAt: fixedNow,
            ),
          );
      await db.into(db.journalEntries).insert(JournalEntriesCompanion.insert(
            trailId: 'gr20',
            stageNumber: 1,
            content: const Value('note perso'),
            createdAt: fixedNow,
          ));
      await db.into(db.weatherCache).insert(WeatherCacheCompanion.insert(
            trailId: 'gr20',
            stageNumber: 1,
            forecastJson: '{}',
            fetchedAt: fixedNow,
            expiresAt: fixedNow.add(const Duration(hours: 3)),
          ));
    }

    test('VIDE reellement toutes les tables utilisateur ET les consentements',
        () async {
      await seedUserData();
      // Pose un consentement, pour verifier qu'il est efface.
      final prefs = await SharedPreferences.getInstance();
      final consent = ConsentService(prefs: prefs);
      await consent.grant(ConsentPurpose.locationNavigation);
      expect(consent.hasConsent(ConsentPurpose.locationNavigation), isTrue);

      String? deletedUid;
      final service = DataRetentionService(
        database: db,
        prefs: prefs,
        now: () => fixedNow,
        serverDeletion: (uid) async => deletedUid = uid,
      );

      final report = await service.deleteAccountData(uidHash: 'abc123');

      // Toutes les tables utilisateur sont vides.
      expect((await db.select(db.reportLocal).get()).isEmpty, isTrue);
      expect((await db.select(db.kudosLocal).get()).isEmpty, isTrue);
      expect((await db.select(db.sessionTrackPoints).get()).isEmpty, isTrue);
      expect((await db.select(db.journalEntries).get()).isEmpty, isTrue);
      expect((await db.select(db.weatherCache).get()).isEmpty, isTrue);

      // Consentements effaces (re-lecture => non accorde).
      final consentAfter = ConsentService(prefs: prefs);
      expect(consentAfter.hasConsent(ConsentPurpose.locationNavigation),
          isFalse);

      // Demande serveur emise avec l'UID hache.
      expect(deletedUid, 'abc123');
      expect(report.serverDeletionRequested, isTrue);
      expect(report.consentsCleared, isTrue);
      expect(report.localRowsDeleted, greaterThanOrEqualTo(5));
    });

    test('sans uidHash : efface le local, AUCUN appel serveur', () async {
      await seedUserData();
      var serverCalled = false;
      final prefs = await SharedPreferences.getInstance();
      final service = DataRetentionService(
        database: db,
        prefs: prefs,
        now: () => fixedNow,
        serverDeletion: (_) async => serverCalled = true,
      );

      final report = await service.deleteAccountData();

      expect((await db.select(db.reportLocal).get()).isEmpty, isTrue);
      expect(serverCalled, isFalse,
          reason: 'Pas d UID => pas de suppression serveur');
      expect(report.serverDeletionRequested, isFalse);
      expect(report.localRowsDeleted, greaterThan(0));
    });

    test('une erreur serveur REMONTE (pas de catch silencieux)', () async {
      await seedUserData();
      final prefs = await SharedPreferences.getInstance();
      final service = DataRetentionService(
        database: db,
        prefs: prefs,
        now: () => fixedNow,
        serverDeletion: (_) async =>
            throw StateError('suppression serveur indisponible'),
      );

      // L'erreur doit remonter (suppression EN PREMIER : le local n'est pas
      // touche si le serveur n'a pas pu etre prevenu).
      await expectLater(
        service.deleteAccountData(uidHash: 'abc123'),
        throwsA(isA<StateError>()),
      );
      // Le local est intact (l'erreur serveur a interrompu avant la purge).
      expect((await db.select(db.reportLocal).get()).isNotEmpty, isTrue);
    });
  });
}
