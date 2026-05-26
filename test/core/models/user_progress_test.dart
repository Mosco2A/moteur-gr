import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/models/user_progress.dart';

/// Tests du modele UserProgressModel (fromDb, toCompanion).
void main() {
  group('UserProgressModel', () {
    test('fromDb construit correctement depuis une ligne DB', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = ProgressDao(db);
      final now = DateTime.now();

      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
        currentStage: const Value(5),
        totalDistanceWalkedKm: const Value(35.2),
        totalElevationGainedM: const Value(2100),
        isCompleted: const Value(false),
        startedAt: Value(now),
      ));

      final row = await dao.getByTrailId('trail1');
      final model = UserProgressModel.fromDb(row!);

      expect(model.trailId, 'trail1');
      expect(model.currentStage, 5);
      expect(model.totalDistanceWalkedKm, 35.2);
      expect(model.totalElevationGainedM, 2100);
      expect(model.isCompleted, isFalse);
      expect(model.startedAt, isNotNull);
      expect(model.completedAt, isNull);

      await db.close();
    });

    test('toCompanion genere un companion valide', () {
      final now = DateTime.now();
      final model = UserProgressModel(
        trailId: 'trail1',
        currentStage: 3,
        totalDistanceWalkedKm: 20.0,
        totalElevationGainedM: 1000,
        startedAt: now,
      );

      final companion = model.toCompanion();
      expect(companion.trailId.value, 'trail1');
      expect(companion.currentStage.value, 3);
      expect(companion.totalDistanceWalkedKm.value, 20.0);
      expect(companion.isCompleted.value, isFalse);
    });

    test('roundtrip fromDb -> toCompanion -> insertion -> fromDb', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = ProgressDao(db);

      // Creer une progression initiale
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'roundtrip',
        currentStage: const Value(2),
        totalDistanceWalkedKm: const Value(15.0),
      ));

      // Lire, convertir en modele, modifier, reinserer
      final row1 = await dao.getByTrailId('roundtrip');
      final model1 = UserProgressModel.fromDb(row1!);
      final modified = model1.copyWith(currentStage: 4, totalDistanceWalkedKm: 30.0);
      await dao.upsert(modified.toCompanion());

      // Verifier le resultat
      final row2 = await dao.getByTrailId('roundtrip');
      final model2 = UserProgressModel.fromDb(row2!);
      expect(model2.currentStage, 4);
      expect(model2.totalDistanceWalkedKm, 30.0);

      await db.close();
    });

    test('valeurs par defaut sont correctes', () {
      const model = UserProgressModel(trailId: 'trail1');
      expect(model.id, 0);
      expect(model.currentStage, 1);
      expect(model.totalDistanceWalkedKm, 0.0);
      expect(model.totalElevationGainedM, 0);
      expect(model.isCompleted, isFalse);
      expect(model.startedAt, isNull);
      expect(model.completedAt, isNull);
    });

    test('equality fonctionne avec freezed', () {
      const a = UserProgressModel(trailId: 't1', currentStage: 3);
      const b = UserProgressModel(trailId: 't1', currentStage: 3);
      expect(a, equals(b));
    });
  });
}
