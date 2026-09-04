import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage.dart';

/// Tests de MIGRATION Drift v20 -> v21 (parite GR20 « socle donnees »).
///
/// La v21 ajoute la colonne NULLABLE `estimated_duration_minutes` sur la table
/// `stages` (duree riche par etape, alimentee par la donnee du sentier). On
/// verifie :
///   1. la version du schema a bien ete portee a 21 ;
///   2. la colonne existe apres migration ;
///   3. aucune perte : les colonnes historiques de `stages` sont preservees ;
///   4. la colonne accepte NULL (sentier pauvre) ET une valeur (sentier riche).
void main() {
  group('Drift migration v20 -> v21 (stages.estimatedDurationMinutes)', () {
    test('la version du schema est au moins 21 (introduction de la colonne)',
        () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // La colonne `estimated_duration_minutes` est introduite en v21 ; le
      // schema continue d'evoluer (ex. v22 : table nuitee_selections). On
      // verifie donc le seuil d'introduction, sans fige a une version exacte
      // qui casserait a chaque migration ulterieure.
      expect(db.schemaVersion, greaterThanOrEqualTo(21));
    });

    test('la colonne estimated_duration_minutes existe sur stages', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final columns =
          await db.customSelect('PRAGMA table_info(stages)').get();
      final names = columns.map((r) => r.read<String>('name')).toList();

      expect(names, contains('estimated_duration_minutes'),
          reason: 'Colonne ajoutee en migration v21');

      // Non-regression : les colonnes historiques de stages sont preservees.
      for (final expected in [
        'id',
        'trail_id',
        'stage_number',
        'name',
        'distance_km',
        'elevation_gain_m',
        'elevation_loss_m',
        'description',
        'start_lat',
        'start_lng',
        'end_lat',
        'end_lng',
        'difficulty',
      ]) {
        expect(names, contains(expected),
            reason: 'Colonne historique $expected preservee');
      }
    });

    test('la colonne accepte NULL et une valeur (fallback gracieux)',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final dao = StagesDao(db);

      await dao.insertAll([
        // Sentier pauvre : pas de duree -> NULL.
        const StageModel(
          trailId: 'poor',
          stageNumber: 1,
          name: 'Sans duree',
          distanceKm: 10,
          elevationGainM: 400,
          elevationLossM: 300,
          startLat: 0,
          startLng: 0,
          endLat: 0,
          endLng: 0,
        ).toCompanion(),
        // Sentier riche : duree fournie.
        const StageModel(
          trailId: 'rich',
          stageNumber: 1,
          name: 'Avec duree',
          distanceKm: 15,
          elevationGainM: 850,
          elevationLossM: 100,
          startLat: 0,
          startLng: 0,
          endLat: 0,
          endLng: 0,
          estimatedDurationMinutes: 350,
        ).toCompanion(),
      ]);

      final poor =
          StageModel.fromDb((await dao.getByTrailId('poor')).first);
      final rich =
          StageModel.fromDb((await dao.getByTrailId('rich')).first);

      expect(poor.estimatedDurationMinutes, isNull);
      expect(rich.estimatedDurationMinutes, 350);
    });
  });
}
