import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';

/// Tests du DAO Progress sur une base in-memory.
void main() {
  late AppDatabase db;
  late ProgressDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = ProgressDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ProgressDao', () {
    test('getByTrailId retourne null si aucune progression', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isNull);
    });

    test('upsert cree une nouvelle progression', () async {
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
        currentStage: const Value(3),
        totalDistanceWalkedKm: const Value(25.5),
        totalElevationGainedM: const Value(1500),
      ));

      final result = await dao.getByTrailId('trail1');
      expect(result, isNotNull);
      expect(result!.trailId, 'trail1');
      expect(result.currentStage, 3);
      expect(result.totalDistanceWalkedKm, 25.5);
      expect(result.totalElevationGainedM, 1500);
    });

    test('upsert met a jour une progression existante', () async {
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
        currentStage: const Value(1),
      ));

      await dao.upsert(const UserProgressEntriesCompanion(
        trailId: Value('trail1'),
        currentStage: Value(5),
        totalDistanceWalkedKm: Value(42.0),
      ));

      final result = await dao.getByTrailId('trail1');
      expect(result!.currentStage, 5);
      expect(result.totalDistanceWalkedKm, 42.0);
    });

    test('updateCurrentStage cree une progression si inexistante', () async {
      await dao.updateCurrentStage('trail_new', 3);

      final result = await dao.getByTrailId('trail_new');
      expect(result, isNotNull);
      expect(result!.currentStage, 3);
      expect(result.startedAt, isNotNull);
    });

    test('updateCurrentStage met a jour letape courante', () async {
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
        currentStage: const Value(1),
      ));

      await dao.updateCurrentStage('trail1', 7);

      final result = await dao.getByTrailId('trail1');
      expect(result!.currentStage, 7);
    });

    test('markCompleted marque le sentier comme termine', () async {
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
        currentStage: const Value(10),
      ));

      await dao.markCompleted('trail1');

      final result = await dao.getByTrailId('trail1');
      expect(result!.isCompleted, isTrue);
      expect(result.completedAt, isNotNull);
    });

    test('markCompleted ne fait rien si progression inexistante', () async {
      // Pas d'exception levee
      await dao.markCompleted('inexistant');
      final result = await dao.getByTrailId('inexistant');
      expect(result, isNull);
    });

    test('isCompleted est false par defaut', () async {
      await dao.upsert(UserProgressEntriesCompanion.insert(
        trailId: 'trail1',
      ));

      final result = await dao.getByTrailId('trail1');
      expect(result!.isCompleted, isFalse);
      expect(result.completedAt, isNull);
    });
  });
}
