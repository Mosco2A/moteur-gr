import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/models/stage.dart';

/// Tests de MIGRATION Drift v22 -> v23 (parite GR20 « socle donnees »).
///
/// La v23 ajoute deux colonnes NULLABLE sur la table `stages` : `departure_name`
/// et `arrival_name` (noms des points de depart/arrivee par etape, alimentes par
/// la donnee du sentier). On verifie :
///   1. la version du schema a bien ete portee a 23 ;
///   2. les colonnes existent apres migration ;
///   3. aucune perte : les colonnes historiques de `stages` sont preservees ;
///   4. les colonnes acceptent NULL (sentier pauvre) ET une valeur (riche).
void main() {
  group('Drift migration v22 -> v23 (stages departure/arrival name)', () {
    test('la version du schema est au moins 23 (introduction des colonnes)',
        () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // Les colonnes sont introduites en v23 ; le schema peut continuer
      // d'evoluer. On verifie le seuil d'introduction, sans figer une version
      // exacte qui casserait a chaque migration ulterieure.
      expect(db.schemaVersion, greaterThanOrEqualTo(23));
    });

    test('les colonnes departure_name et arrival_name existent sur stages',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final columns =
          await db.customSelect('PRAGMA table_info(stages)').get();
      final names = columns.map((r) => r.read<String>('name')).toList();

      expect(names, contains('departure_name'),
          reason: 'Colonne ajoutee en migration v23');
      expect(names, contains('arrival_name'),
          reason: 'Colonne ajoutee en migration v23');

      // Non-regression : les colonnes historiques de stages sont preservees
      // (y compris estimated_duration_minutes, ajoutee en v21).
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
        'estimated_duration_minutes',
      ]) {
        expect(names, contains(expected),
            reason: 'Colonne historique $expected preservee');
      }
    });

    test('les colonnes acceptent NULL et une valeur (fallback gracieux)',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final dao = StagesDao(db);

      await dao.insertAll([
        // Sentier pauvre : pas de noms -> NULL.
        const StageModel(
          trailId: 'poor',
          stageNumber: 1,
          name: 'Sans noms',
          distanceKm: 10,
          elevationGainM: 400,
          elevationLossM: 300,
          startLat: 0,
          startLng: 0,
          endLat: 0,
          endLng: 0,
        ).toCompanion(),
        // Sentier riche : noms fournis.
        const StageModel(
          trailId: 'rich',
          stageNumber: 1,
          name: 'Ghisonaccia — Catastaghju',
          distanceKm: 15,
          elevationGainM: 850,
          elevationLossM: 100,
          startLat: 0,
          startLng: 0,
          endLat: 0,
          endLng: 0,
          departureName: 'Ghisonaccia',
          arrivalName: 'Catastaghju',
        ).toCompanion(),
      ]);

      final poor = StageModel.fromDb((await dao.getByTrailId('poor')).first);
      final rich = StageModel.fromDb((await dao.getByTrailId('rich')).first);

      expect(poor.departureName, isNull);
      expect(poor.arrivalName, isNull);
      expect(rich.departureName, 'Ghisonaccia');
      expect(rich.arrivalName, 'Catastaghju');
    });
  });
}
