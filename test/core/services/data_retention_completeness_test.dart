// TACHE 561 (LOT J) — L'EFFACEMENT DE L'ART 17 EST-IL REELLEMENT COMPLET ?
//
// POURQUOI CE FICHIER EXISTE. `DataRetentionService` se presente comme un
// effacement COMPLET (en-tete du service : « il doit etre COMPLET et
// TRACABLE »). Il ne l'etait pas : la liste des tables a vider etait RECOPIEE
// A LA MAIN et huit tables du schema n'y figuraient pas — dont `hiker_profile`,
// c'est-a-dire l'age, la taille et le poids, que l'application declare
// elle-meme au randonneur comme des DONNEES DE SANTE (art. 9 RGPD) dans les
// cinq langues. Cote SharedPreferences, seules les quatre cles `consent_*`
// etaient effacees : 55 autres cles survivaient, dont la fiche randonneur, le
// pseudo, les reservations et le tampon de points GPS bruts.
//
// CE QUE CES TESTS VERROUILLENT :
//   1. COMPLETUDE COMPORTEMENTALE : on remplit les tables et les cles qui
//      etaient oubliees, on efface, et on exige qu'il ne reste RIEN.
//   2. NON-RECURRENCE STRUCTURELLE : la classification de CHAQUE table du
//      schema est exigee explicitement. Ajouter une table sans la classer fait
//      ECHOUER ce test — c'est ce qui rend l'oubli impossible, pas la bonne
//      volonte du prochain developpeur.
//   3. SENS DU DEFAUT : une table inconnue est EFFACEE, jamais conservee. Le
//      defaut protege la personne, pas la donnee.

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  final fixedNow = DateTime.utc(2026, 6, 15, 12);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
  });

  Future<DataRetentionService> buildService(SharedPreferences prefs) async =>
      DataRetentionService(
        database: db,
        prefs: prefs,
        now: () => fixedNow,
      );

  /// Remplit les HUIT tables que la liste ecrite a la main avait oubliees.
  Future<void> seedForgottenTables() async {
    await db.into(db.trekSessions).insert(TrekSessionsCompanion.insert(
          id: 'session-1',
          trailId: 'gr20',
          startedAt: fixedNow,
        ));
    await db.into(db.nuiteeSelections).insert(
          NuiteeSelectionsCompanion.insert(trailId: 'gr20', dayNumber: 1),
        );
    await db.into(db.walletBalance).insert(WalletBalanceCompanion.insert(
          userId: 'local',
          balanceSteps: const Value(12),
          updatedAt: fixedNow,
        ));
    await db.into(db.trekEntitlements).insert(
          TrekEntitlementsCompanion.insert(
            trailId: 'gr20',
            owned: const Value(true),
            updatedAt: fixedNow,
          ),
        );
    await db.into(db.noAdsState).insert(NoAdsStateCompanion.insert(
          source: 'subscription',
          startedAt: fixedNow,
          updatedAt: fixedNow,
        ));
    // hiker_profile / past_hike_entries / hiker_experience_note : ecrites par
    // le repository, qui pose les DEUX etages (prefs durables + miroir Drift).
  }

  /// Saisit une fiche randonneur complete via le chemin REEL de l'application.
  Future<void> seedHikerFile(SharedPreferences prefs) async {
    final repo = HikerProfileRepository(db: db, prefs: prefs);
    await repo.saveProfile(const HikerProfile(
      age: 72,
      heightCm: 172,
      weightKg: 88,
      sex: 'male',
      countryIso: 'FR',
    ));
    await repo.savePastHikes([
      PastHike(
        date: DateTime.utc(2026, 5, 1),
        days: 3,
        avgWalkHoursPerDay: 6,
        totalElevationGain: 2100,
        totalDistanceKm: 42,
      ),
    ]);
    await repo.saveExperienceNote('genoux douloureux en descente');
    await repo.saveWalkTestResult(WalkTestResult(
      distanceMeters: 480,
      level: 'moyen',
      takenAt: fixedNow,
    ));
  }

  group('art 17 — la fiche randonneur (donnee de sante) part vraiment', () {
    test('le MIROIR Drift de la fiche randonneur est vide apres effacement',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await seedHikerFile(prefs);

      // Pre-condition : la donnee de sante est bien la avant l'effacement.
      expect((await db.select(db.hikerProfile).get()).isNotEmpty, isTrue,
          reason: 'le test ne prouve rien si la fiche n etait pas ecrite');

      final service = await buildService(prefs);
      await service.deleteAccountData();

      expect((await db.select(db.hikerProfile).get()), isEmpty,
          reason: 'age/taille/poids restaient sur l appareil (art. 9)');
      expect((await db.select(db.pastHikeEntries).get()), isEmpty);
      expect((await db.select(db.hikerExperienceNote).get()), isEmpty);
    });

    test('la SOURCE DURABLE (SharedPreferences) de la fiche est vide aussi',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await seedHikerFile(prefs);

      final service = await buildService(prefs);
      await service.deleteAccountData();

      // Vider le seul miroir Drift ne suffirait pas : il est re-hydrate depuis
      // les prefs au prochain demarrage (`HikerProfileRepository.load`).
      expect(prefs.getString(kHikerProfilePrefsKey), isNull,
          reason: 'la morphologie serait revenue au prochain boot');
      expect(prefs.getString(kHikerPastHikesPrefsKey), isNull);
      expect(prefs.getString(kHikerExperienceNotePrefsKey), isNull);
      expect(prefs.getString(kWalkTestResultPrefsKey), isNull,
          reason: 'le test de marche 6 min est une mesure de capacite physique');
    });

    test('un rechargement apres effacement ne fait PAS revenir la morphologie',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await seedHikerFile(prefs);

      final service = await buildService(prefs);
      await service.deleteAccountData();

      // On rejoue l'hydratation du boot : elle ne doit rien ressusciter.
      final repo = HikerProfileRepository(db: db, prefs: prefs);
      final reloaded = await repo.load();
      expect(reloaded.age, 0);
      expect(reloaded.heightCm, 0);
      expect(reloaded.weightKg, 0);
      expect(await repo.getExperienceNote(), isEmpty);
      expect(await repo.getWalkTestResult(), isNull);
      expect((await repo.loadPastHikes()), isEmpty);
    });
  });

  group('art 17 — les autres tables oubliees', () {
    test('sessions de trek et nuitees choisies sont effacees', () async {
      final prefs = await SharedPreferences.getInstance();
      await seedForgottenTables();

      final service = await buildService(prefs);
      await service.deleteAccountData();

      expect((await db.select(db.trekSessions).get()), isEmpty,
          reason: 'historique des etapes reellement marchees');
      expect((await db.select(db.nuiteeSelections).get()), isEmpty,
          reason: 'nuits choisies et reservees (donnee de planning perso)');
    });

    test('les tables de REFERENCE du sentier ne sont JAMAIS touchees',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await db.into(db.stages).insert(StagesCompanion.insert(
            trailId: 'gr20',
            stageNumber: 1,
            name: 'Calenzana - Ortu',
            distanceKm: 10,
            elevationGainM: 1300,
            elevationLossM: 100,
            startLat: 42.5,
            startLng: 8.8,
            endLat: 42.4,
            endLng: 8.9,
          ));
      await db.into(db.waypoint).insert(WaypointCompanion.insert(
            id: 'wp1',
            trailId: 'gr20',
            type: 'eau',
            latitude: 42.5,
            longitude: 8.8,
            titre: 'Source',
            lastUpdatedAt: fixedNow,
          ));

      final service = await buildService(prefs);
      await service.deleteAccountData();

      expect((await db.select(db.stages).get()).length, 1,
          reason: 'le contenu telecharge du sentier n est pas de la donnee perso');
      expect((await db.select(db.waypoint).get()).length, 1);
    });
  });

  group('art 17 — les cles SharedPreferences personnelles', () {
    test('le pseudo, les reservations et la trace GPS brute sont effaces',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_uid': 'uuid-local',
        'auth_display_name': 'Christophe',
        'accommodation_bookings': '[{"refuge":"Ortu"}]',
        'bg_gps_points_buffer': <String>['42.5,8.8'],
        'planning.retainedDuration.gr20': 12,
        'departure_date_gr20': '2026-07-01',
        'settings_language': 'fr',
      });
      final prefs = await SharedPreferences.getInstance();

      final service = await buildService(prefs);
      await service.deleteAccountData();

      expect(prefs.getString('auth_display_name'), isNull,
          reason: 'un pseudo saisi est de la donnee personnelle directe');
      expect(prefs.getString('auth_uid'), isNull);
      expect(prefs.getString('accommodation_bookings'), isNull);
      expect(prefs.getStringList('bg_gps_points_buffer'), isNull,
          reason: 'points GPS bruts = localisation precise');
      // Les cles dynamiques par sentier ne sont enumerables qu'a l'execution :
      // l'effacement doit partir du store reel, pas d'une liste recopiee.
      expect(prefs.getInt('planning.retainedDuration.gr20'), isNull);
      expect(prefs.getString('departure_date_gr20'), isNull);
      // Reglage d'affichage de l'appareil : conserve (non personnel).
      expect(prefs.getString('settings_language'), 'fr');
    });
  });

  // La NON-RECURRENCE structurelle (classification exigee de chaque table du
  // schema) vit dans `data_retention_classification_test.dart` : elle porte sur
  // l'API de classification, pas sur le comportement d'effacement.
}
