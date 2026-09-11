import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_norms.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;
  late HikerProfileRepository repo;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = HikerProfileRepository(db: db, prefs: prefs);
  });

  tearDown(() async {
    await db.close();
  });

  group('Profil — persistance duale prefs + miroir Drift', () {
    test('profil vide si rien sauvegarde', () async {
      final p = await repo.load();
      expect(p.isEmpty, isTrue);
    });

    test('saveProfile ecrit prefs ET miroir Drift, horodate', () async {
      final saved = await repo.saveProfile(
        const HikerProfile(
          age: 40,
          heightCm: 175,
          weightKg: 70,
          sex: HikerSex.female,
          countryIso: 'FR',
        ),
      );
      expect(saved.updatedAt, isNotNull, reason: 'updatedAt rafraichi');

      // Prefs (source durable) : relecture independante.
      final reloaded = await repo.getProfile();
      expect(reloaded.age, 40);
      expect(reloaded.heightCm, 175);
      expect(reloaded.bmi, closeTo(22.857, 0.01));

      // Miroir Drift.
      final drift = await db.hikerProfileDao.getByUserId(kHikerLocalUserId);
      expect(drift, isNotNull);
      expect(drift!.age, 40);
      expect(drift.sex, HikerSex.female);
      expect(drift.countryIso, 'FR');
    });

    test('load rehydrate le miroir Drift depuis les prefs (DB volatile)',
        () async {
      // On simule un profil deja present en prefs (ecrit via repo courant),
      // puis un "redemarrage" : nouvelle DB volatile vierge + memes prefs.
      // load() doit relire les prefs (source durable) et re-remplir Drift.
      await repo.saveProfile(const HikerProfile(heightCm: 180, weightKg: 80));

      final db2 = AppDatabase(NativeDatabase.memory());
      addTearDown(db2.close);
      final repo2 = HikerProfileRepository(db: db2, prefs: prefs);

      // Apres load : profil relu depuis prefs ET miroir Drift (re)hydrate.
      final p = await repo2.load();
      expect(p.heightCm, 180);
      expect(await db2.hikerProfileDao.getByUserId(kHikerLocalUserId),
          isNotNull);
    });

    test('deleteProfile efface prefs ET Drift (droit a l effacement)',
        () async {
      await repo.saveProfile(const HikerProfile(heightCm: 175, weightKg: 70));
      await repo.deleteProfile();
      expect((await repo.getProfile()).isEmpty, isTrue);
      expect(await db.hikerProfileDao.getByUserId(kHikerLocalUserId), isNull);
    });
  });

  group('Randos passees — max 5, tri par date', () {
    test('savePastHikes plafonne a 5 et trie par date decroissante', () async {
      final hikes = List.generate(
        7,
        (i) => PastHike(
          date: DateTime(2026, 1, 1).add(Duration(days: i * 10)),
          days: i + 1,
          totalDistanceKm: (i + 1) * 10.0,
        ),
      );
      final saved = await repo.savePastHikes(hikes);
      expect(saved, hasLength(5), reason: 'plafonne a kMaxPastHikes');
      // La plus recente d'abord.
      expect(saved.first.date.isAfter(saved.last.date), isTrue);
      // Miroir Drift coherent.
      final drift = await db.pastHikesDao.getByUserId(kHikerLocalUserId);
      expect(drift, hasLength(5));
    });

    test('loadPastHikes relit depuis prefs et rehydrate Drift', () async {
      await repo.savePastHikes([
        PastHike(date: DateTime(2026, 6, 1), days: 2, totalDistanceKm: 30),
      ]);
      final loaded = await repo.loadPastHikes();
      expect(loaded, hasLength(1));
      expect(loaded.first.days, 2);
      expect(loaded.first.avgDistancePerDayKm, 15);
    });
  });

  group('Note d experience globale (texte libre)', () {
    test('save + get de la note globale', () async {
      expect(await repo.getExperienceNote(), '');
      await repo.saveExperienceNote('genoux en descente, coup de chaud');
      expect(await repo.getExperienceNote(),
          'genoux en descente, coup de chaud');
      final drift = await db.pastHikesDao.getNote(kHikerLocalUserId);
      expect(drift?.freeTextDifficulties, 'genoux en descente, coup de chaud');
    });
  });

  group('Test 6 min — resultat date (fallback si absent)', () {
    test('null si jamais fait', () async {
      expect(await repo.getWalkTestResult(), isNull);
    });

    test('save + get du dernier resultat (remplace le precedent)', () async {
      await repo.saveWalkTestResult(WalkTestResult(
        distanceMeters: 620,
        level: WalkTestLevel.good,
        takenAt: DateTime(2026, 9, 1),
      ));
      var r = await repo.getWalkTestResult();
      expect(r, isNotNull);
      expect(r!.distanceMeters, 620);
      expect(r.level, WalkTestLevel.good);

      // Nouveau test -> remplace.
      await repo.saveWalkTestResult(WalkTestResult(
        distanceMeters: 680,
        level: WalkTestLevel.excellent,
        takenAt: DateTime(2026, 10, 1),
      ));
      r = await repo.getWalkTestResult();
      expect(r!.distanceMeters, 680);
      expect(r.level, WalkTestLevel.excellent);
    });
  });
}
