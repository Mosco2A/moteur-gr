import 'dart:io';

// `hide` : drift exporte des matchers `isNull`/`isNotNull` qui entrent en
// collision avec ceux de `flutter_test`. On masque ceux de drift ; on n'utilise
// de drift que `Value` (companions).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v24 -> v25 (StepWays LOT 4, socle faisabilite).
///
/// La v25 est STRICTEMENT ADDITIVE : elle cree 3 nouvelles tables via
/// `createTable` (`hiker_profile`, `past_hike_entries`, `hiker_experience_note`)
/// et ne touche a AUCUNE table ni colonne existante. Meme methode que le test
/// v23->v24 : on fabrique une base "v24" persistee (schema courant, puis on
/// retire les 3 tables v25 et on rembobine `user_version` a 24), on insere une
/// donnee metier, on ferme, on rouvre : Drift joue `onUpgrade`.
void main() {
  group('Drift migration v24 -> v25 (socle faisabilite StepWays)', () {
    test('la version du schema est au moins 25', () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      expect(db.schemaVersion, greaterThanOrEqualTo(25));
    });

    test(
        'migration reelle 24 -> 25 : cree les 3 tables faisabilite et preserve '
        'les donnees existantes', () async {
      final dir = await Directory.systemTemp.createTemp('gr_mig_v25_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final file = File('${dir.path}/app.sqlite');

      // --- 1. Fabrique une base "v24" persistee -----------------------------
      final seedDb = AppDatabase(NativeDatabase(file));
      await seedDb.customStatement('SELECT 1');

      // Donnee metier a preserver (une etape).
      await seedDb.customStatement(
        "INSERT INTO stages (trail_id, stage_number, name, distance_km, "
        "elevation_gain_m, elevation_loss_m, start_lat, start_lng, end_lat, "
        "end_lng) VALUES ('gr20', 1, 'Calenzana - Ortu di u Piobbu', 10.5, "
        "1350, 100, 42.5, 8.85, 42.42, 8.9)",
      );

      // Retire les tables v25 et rembobine la version -> etat "v24".
      await seedDb
          .customStatement('DROP TABLE IF EXISTS hiker_experience_note');
      await seedDb.customStatement('DROP TABLE IF EXISTS past_hike_entries');
      await seedDb.customStatement('DROP TABLE IF EXISTS hiker_profile');
      await seedDb.customStatement('PRAGMA user_version = 24');
      await seedDb.close();

      // --- 2. Rouvre : Drift voit 24 < 25 -> joue onUpgrade -----------------
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();

      expect(tableNames, contains('hiker_profile'),
          reason: 'Table hiker_profile creee en migration v25');
      expect(tableNames, contains('past_hike_entries'),
          reason: 'Table past_hike_entries creee en migration v25');
      expect(tableNames, contains('hiker_experience_note'),
          reason: 'Table hiker_experience_note creee en migration v25');

      // --- 3. Aucune perte : l'etape preexistante est intacte ---------------
      final stagesRows = await db.customSelect('SELECT * FROM stages').get();
      expect(stagesRows, hasLength(1),
          reason: 'La donnee metier v24 survit a la migration');
      expect(stagesRows.first.read<String>('trail_id'), 'gr20');

      final userVersion = await db
          .customSelect('PRAGMA user_version')
          .map((r) => r.read<int>('user_version'))
          .getSingle();
      expect(userVersion, greaterThanOrEqualTo(25));
    });

    test('les 3 nouvelles tables sont utilisables (DAOs + valeurs par defaut)',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // HikerProfile : upsert minimal -> defauts (0 / null / '').
      await db.hikerProfileDao.upsert(
        HikerProfileCompanion.insert(
          userId: 'user-hash-abc',
          updatedAt: DateTime(2026, 9, 11),
        ),
      );
      final profile = await db.hikerProfileDao.getByUserId('user-hash-abc');
      expect(profile, isNotNull);
      expect(profile!.age, 0);
      expect(profile.heightCm, 0);
      expect(profile.weightKg, 0);
      expect(profile.sex, isNull);
      expect(profile.countryIso, '');

      // PastHikeEntries : insert d'une rando.
      await db.pastHikesDao.insertHike(
        PastHikeEntriesCompanion.insert(
          userId: 'user-hash-abc',
          date: DateTime(2026, 7, 1),
          days: const Value(3),
          totalDistanceKm: const Value(42),
          totalElevationGain: const Value(2100),
          updatedAt: DateTime(2026, 9, 11),
        ),
      );
      final hikes = await db.pastHikesDao.getByUserId('user-hash-abc');
      expect(hikes, hasLength(1));
      expect(hikes.first.days, 3);
      expect(hikes.first.totalDistanceKm, 42);

      // HikerExperienceNote : upsert de la note globale.
      await db.pastHikesDao.upsertNote(
        HikerExperienceNoteCompanion.insert(
          userId: 'user-hash-abc',
          freeTextDifficulties: const Value('genoux en descente'),
          updatedAt: DateTime(2026, 9, 11),
        ),
      );
      final note = await db.pastHikesDao.getNote('user-hash-abc');
      expect(note, isNotNull);
      expect(note!.freeTextDifficulties, 'genoux en descente');
    });
  });
}
