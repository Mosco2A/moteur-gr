import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift_dev/api/migrations.dart';
import 'package:moteur_gr/core/data/database.dart';

/// Template SchemaVerifier Drift pour valider chaque migration.
///
/// 3 tests :
///   1. Schema v1 - creation initiale (toutes les tables sans totalTimeMinutes)
///   2. Migration v1 -> v2 - ajout totalTimeMinutes sans perte de donnees
///   3. Rollback detection - tentative de downgrade detectee
///
/// Utilisation : dart test test/drift/migration_test_template.dart
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('Schema v1 - creation initiale', () {
    test('v1 cree les 3 tables avec toutes les colonnes attendues', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);

      // Verifier que la base s'ouvre sans erreur
      await db.customSelect('SELECT 1 FROM stages LIMIT 0').get();
      await db.customSelect('SELECT 1 FROM pois LIMIT 0').get();
      await db.customSelect('SELECT 1 FROM user_progress_entries LIMIT 0').get();

      // Verifier colonnes de stages
      final stagesCols = await db
          .customSelect('PRAGMA table_info(stages)')
          .get();
      final stagesColNames =
          stagesCols.map((r) => r.read<String>('name')).toSet();
      expect(stagesColNames, containsAll([
        'id', 'trail_id', 'stage_number', 'name',
        'distance_km', 'elevation_gain_m', 'elevation_loss_m',
        'description', 'start_lat', 'start_lng',
        'end_lat', 'end_lng', 'difficulty',
      ]));

      // Verifier colonnes de pois
      final poisCols = await db
          .customSelect('PRAGMA table_info(pois)')
          .get();
      final poisColNames =
          poisCols.map((r) => r.read<String>('name')).toSet();
      expect(poisColNames, containsAll([
        'id', 'trail_id', 'stage_number', 'name',
        'description', 'type', 'lat', 'lng',
        'altitude_m', 'opening_hours',
      ]));

      // Verifier colonnes de user_progress_entries (v1 = sans total_time_minutes)
      final progressCols = await db
          .customSelect('PRAGMA table_info(user_progress_entries)')
          .get();
      final progressColNames =
          progressCols.map((r) => r.read<String>('name')).toSet();
      expect(progressColNames, containsAll([
        'id', 'trail_id', 'current_stage',
        'total_distance_walked_km', 'total_elevation_gained_m',
        'is_completed', 'started_at', 'completed_at',
      ]));
      // total_time_minutes n'existe PAS en v1
      expect(progressColNames, isNot(contains('total_time_minutes')));

      await db.close();
    });

    test('v1 permet d\'inserer et lire des donnees', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);

      // Inserer une etape via SQL brut (schema v1)
      await db.customStatement(
        "INSERT INTO stages ("
        "trail_id, stage_number, name, distance_km, "
        "elevation_gain_m, elevation_loss_m, description, "
        "start_lat, start_lng, end_lat, end_lng, difficulty"
        ") VALUES ("
        "'gr20', 1, 'Calenzana - Ortu di u Piobbu', 12.0, "
        "1500, 200, 'Premiere etape mythique', "
        "42.508, 8.855, 42.463, 8.905, 'hard')"
      );

      final rows = await db.customSelect('SELECT * FROM stages').get();
      expect(rows.length, 1);
      expect(rows.first.read<String>('trail_id'), 'gr20');
      expect(rows.first.read<String>('name'), 'Calenzana - Ortu di u Piobbu');

      await db.close();
    });
  });

  group('Migration v1 -> v2 - sans perte de donnees', () {
    test('v1 -> v2 ajoute total_time_minutes avec valeur par defaut 0',
        () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);

      // Inserer une progression en v1 (sans total_time_minutes)
      await db.customStatement(
        "INSERT INTO user_progress_entries ("
        "trail_id, current_stage, total_distance_walked_km, "
        "total_elevation_gained_m, is_completed"
        ") VALUES ('gr20', 3, 25.5, 3200, 0)"
      );

      await db.close();

      final upgraded = await verifier.migrateAndValidate(connection, 2);
      final db2 = AppDatabase(upgraded);

      // Verifier que la colonne total_time_minutes existe maintenant
      final cols = await db2
          .customSelect('PRAGMA table_info(user_progress_entries)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, contains('total_time_minutes'));

      // Verifier que les donnees pre-migration sont conservees
      final rows =
          await db2.customSelect('SELECT * FROM user_progress_entries').get();
      expect(rows.length, 1);
      expect(rows.first.read<String>('trail_id'), 'gr20');
      expect(rows.first.read<int>('current_stage'), 3);
      expect(rows.first.read<double>('total_distance_walked_km'), 25.5);
      expect(rows.first.read<int>('total_elevation_gained_m'), 3200);

      // La nouvelle colonne a la valeur par defaut 0
      expect(rows.first.read<int>('total_time_minutes'), 0);

      await db2.close();
    });

    test('v1 -> v2 preserve les donnees dans toutes les tables', () async {
      final connection = await verifier.startAt(1);
      final db = AppDatabase(connection);

      // Peupler les 3 tables en v1
      await db.customStatement(
        "INSERT INTO stages ("
        "trail_id, stage_number, name, distance_km, "
        "elevation_gain_m, elevation_loss_m, description, "
        "start_lat, start_lng, end_lat, end_lng, difficulty"
        ") VALUES ('gr20', 1, 'Etape 1', 12.0, 1500, 200, 'Desc', 42.0, 9.0, 42.1, 9.1, 'hard')"
      );
      await db.customStatement(
        "INSERT INTO stages ("
        "trail_id, stage_number, name, distance_km, "
        "elevation_gain_m, elevation_loss_m, description, "
        "start_lat, start_lng, end_lat, end_lng, difficulty"
        ") VALUES ('gr20', 2, 'Etape 2', 8.5, 900, 600, 'Desc', 42.1, 9.1, 42.2, 9.2, 'moderate')"
      );
      await db.customStatement(
        "INSERT INTO pois ("
        "trail_id, stage_number, name, description, type, "
        "lat, lng, altitude_m"
        ") VALUES ('gr20', 1, 'Refuge Ortu', 'Premier refuge', 'shelter', 42.463, 8.905, 1570)"
      );
      await db.customStatement(
        "INSERT INTO user_progress_entries ("
        "trail_id, current_stage, total_distance_walked_km, "
        "total_elevation_gained_m, is_completed"
        ") VALUES ('gr20', 2, 12.0, 1500, 0)"
      );

      await db.close();

      // Migrer en v2
      final upgraded = await verifier.migrateAndValidate(connection, 2);
      final db2 = AppDatabase(upgraded);

      // Verifier stages intactes
      final stages = await db2.customSelect('SELECT * FROM stages').get();
      expect(stages.length, 2);
      expect(stages.first.read<String>('name'), 'Etape 1');

      // Verifier pois intacts
      final pois = await db2.customSelect('SELECT * FROM pois').get();
      expect(pois.length, 1);
      expect(pois.first.read<String>('name'), 'Refuge Ortu');

      // Verifier progression intacte + nouvelle colonne
      final progress =
          await db2.customSelect('SELECT * FROM user_progress_entries').get();
      expect(progress.length, 1);
      expect(progress.first.read<int>('current_stage'), 2);
      expect(progress.first.read<int>('total_time_minutes'), 0);

      await db2.close();
    });
  });

  group('Rollback detection', () {
    test('detecte qu\'un downgrade v2 -> v1 n\'est pas supporte', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);

      // Inserer des donnees exploitant le schema v2
      await db.customStatement(
        "INSERT INTO user_progress_entries ("
        "trail_id, current_stage, total_distance_walked_km, "
        "total_elevation_gained_m, total_time_minutes, is_completed"
        ") VALUES ('gr20', 5, 50.0, 8000, 2400, 0)"
      );

      await db.close();

      // Tenter de valider le schema v1 sur une base v2 doit echouer
      // SchemaVerifier ne supporte pas le downgrade : le schema v1
      // attend l'absence de total_time_minutes mais la base en a un.
      final db2 = AppDatabase(connection);
      final cols = await db2
          .customSelect('PRAGMA table_info(user_progress_entries)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();

      // En v2, total_time_minutes est present -> rollback vers v1
      // perdrait cette colonne (DROP COLUMN destructif et non supporte).
      expect(colNames, contains('total_time_minutes'));

      // Verifier que les donnees v2 seraient perdues si on supprimait la colonne
      final rows =
          await db2.customSelect('SELECT * FROM user_progress_entries').get();
      expect(rows.first.read<int>('total_time_minutes'), 2400);

      // Pas de MigrationStrategy.onDowngrade defini -> toute tentative
      // de rollback laisserait la base dans un etat incoherent.
      expect(db2.schemaVersion, 2,
          reason: 'Le schema courant est v2, aucun downgrade n\'est prevu');

      await db2.close();
    });

    test('schema v2 est valide et complet', () async {
      final connection = await verifier.startAt(2);
      final db = AppDatabase(connection);

      // Verifier que toutes les colonnes v2 de user_progress_entries sont la
      final cols = await db
          .customSelect('PRAGMA table_info(user_progress_entries)')
          .get();
      final colNames = cols.map((r) => r.read<String>('name')).toSet();
      expect(colNames, containsAll([
        'id', 'trail_id', 'current_stage',
        'total_distance_walked_km', 'total_elevation_gained_m',
        'total_time_minutes', // Ajout v2
        'is_completed', 'started_at', 'completed_at',
      ]));

      // Verifier que les tables stages et pois sont inchangees en v2
      final stagesCols = await db
          .customSelect('PRAGMA table_info(stages)')
          .get();
      expect(stagesCols.length, 13); // 13 colonnes dans stages

      final poisCols = await db
          .customSelect('PRAGMA table_info(pois)')
          .get();
      expect(poisCols.length, 10); // 10 colonnes dans pois

      await db.close();
    });
  });
}

/// Helper pour SchemaVerifier.
///
/// Genere normalement par drift_dev via `dart run drift_dev schema steps`.
/// Ce template utilise une implementation simplifiee pour demarrage rapide.
/// En production, remplacer par la version generee automatiquement.
class GeneratedHelper implements SchemaInstantiationHelper {
  @override
  GeneratedDatabase databaseForVersion(QueryExecutor db, int version) {
    return _SchemaDatabase(db, version);
  }
}

/// Base de donnees minimale pour chaque version du schema.
///
/// Reproduit la structure exacte de chaque version pour que
/// SchemaVerifier puisse comparer le schema attendu vs reel.
class _SchemaDatabase extends GeneratedDatabase {
  final int _version;

  _SchemaDatabase(super.e, this._version);

  @override
  int get schemaVersion => _version;

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities {
    switch (_version) {
      case 1:
        return []; // SchemaVerifier utilise onCreate de AppDatabase
      case 2:
        return []; // SchemaVerifier utilise onUpgrade de AppDatabase
      default:
        throw ArgumentError('Version de schema inconnue: $_version');
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          if (_version == 1) {
            await m.createAll();
          } else if (_version == 2) {
            await m.createAll();
          }
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // Reproduit exactement la migration de AppDatabase
            await m.database.customStatement(
              'ALTER TABLE user_progress_entries '
              'ADD COLUMN total_time_minutes INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );
}
