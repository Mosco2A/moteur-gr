import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';

/// Tests du DAO Journal sur une base in-memory.
void main() {
  late AppDatabase db;
  late JournalDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = JournalDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Helper : crée un companion d'entrée journal de test
  JournalEntriesCompanion makeEntry({
    required String trailId,
    required int stageNumber,
    String content = 'Belle journée de trek',
    String? photoPath,
    int? photoSizeBytes,
    DateTime? createdAt,
  }) {
    return JournalEntriesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(content),
      photoPath: Value(photoPath),
      photoSizeBytes: Value(photoSizeBytes),
      createdAt: Value(createdAt ?? DateTime.now()),
    );
  }

  group('JournalDao', () {
    test('insertEntry insère une entrée correctement', () async {
      final id = await dao.insertEntry(
        makeEntry(trailId: 'sentier-bleu', stageNumber: 1),
      );
      expect(id, greaterThan(0));

      final entries = await dao.getByTrailId('sentier-bleu');
      expect(entries.length, 1);
      expect(entries.first.stageNumber, 1);
    });

    test('getByTrailId retourne vide si aucun sentier', () async {
      final result = await dao.getByTrailId('inexistant');
      expect(result, isEmpty);
    });

    test('getByTrailId filtre par sentier', () async {
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 1));
      await dao.insertEntry(makeEntry(trailId: 'tmb', stageNumber: 1));
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 2));

      final sentierBleu = await dao.getByTrailId('sentier-bleu');
      final tmb = await dao.getByTrailId('tmb');
      expect(sentierBleu.length, 2);
      expect(tmb.length, 1);
    });

    test('getByStage filtre par étape', () async {
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 1));
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 2));
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 1));

      final stage1 = await dao.getByStage('sentier-bleu', 1);
      final stage2 = await dao.getByStage('sentier-bleu', 2);
      expect(stage1.length, 2);
      expect(stage2.length, 1);
    });

    test('updateEntry met à jour le contenu', () async {
      final id = await dao.insertEntry(
        makeEntry(trailId: 'sentier-bleu', stageNumber: 1, content: 'avant'),
      );

      await dao.updateEntry(
        JournalEntriesCompanion(
          content: const Value('après'),
          updatedAt: Value(DateTime.now()),
        ),
        id,
      );

      final entries = await dao.getByTrailId('sentier-bleu');
      expect(entries.first.content, 'après');
    });

    test('deleteEntry supprime l\'entrée', () async {
      final id = await dao.insertEntry(
        makeEntry(trailId: 'sentier-bleu', stageNumber: 1),
      );
      await dao.insertEntry(
        makeEntry(trailId: 'sentier-bleu', stageNumber: 2),
      );

      final deleted = await dao.deleteEntry(id);
      expect(deleted, 1);

      final entries = await dao.getByTrailId('sentier-bleu');
      expect(entries.length, 1);
    });

    test('countPhotosToday compte les photos du jour', () async {
      final today = DateTime.now();
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        photoPath: '/photos/1.jpg',
        photoSizeBytes: 1024,
        createdAt: today,
      ));
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        photoPath: '/photos/2.jpg',
        photoSizeBytes: 2048,
        createdAt: today,
      ));
      // Note sans photo
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        createdAt: today,
      ));

      final count = await dao.countPhotosToday('sentier-bleu');
      expect(count, 2);
    });

    test('canAddPhoto retourne true si < 3 photos', () async {
      final today = DateTime.now();
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        photoPath: '/photos/1.jpg',
        photoSizeBytes: 1024,
        createdAt: today,
      ));

      final canAdd = await dao.canAddPhoto('sentier-bleu');
      expect(canAdd, true);
    });

    test('canAddPhoto retourne false si >= 3 photos', () async {
      final today = DateTime.now();
      for (var i = 0; i < 3; i++) {
        await dao.insertEntry(makeEntry(
          trailId: 'sentier-bleu',
          stageNumber: 1,
          photoPath: '/photos/$i.jpg',
          photoSizeBytes: 1024,
          createdAt: today,
        ));
      }

      final canAdd = await dao.canAddPhoto('sentier-bleu');
      expect(canAdd, false);
    });

    test('deleteByTrailId supprime les entrées du bon sentier', () async {
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 1));
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 2));
      await dao.insertEntry(makeEntry(trailId: 'tmb', stageNumber: 1));

      final deleted = await dao.deleteByTrailId('sentier-bleu');
      expect(deleted, 2);

      final remaining = await dao.getByTrailId('tmb');
      expect(remaining.length, 1);
    });

    test('countByTrailId retourne le bon nombre', () async {
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 1));
      await dao.insertEntry(makeEntry(trailId: 'sentier-bleu', stageNumber: 2));

      final count = await dao.countByTrailId('sentier-bleu');
      expect(count, 2);
    });

    test('maxPhotosPerDay vaut 3', () {
      expect(JournalDao.maxPhotosPerDay, 3);
    });

    test('maxPhotoSizeBytes vaut 500 Ko', () {
      expect(JournalDao.maxPhotoSizeBytes, 500 * 1024);
    });

    test('entries triées par date décroissante', () async {
      final now = DateTime.now();
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        content: 'ancien',
        createdAt: now.subtract(const Duration(hours: 2)),
      ));
      await dao.insertEntry(makeEntry(
        trailId: 'sentier-bleu',
        stageNumber: 2,
        content: 'récent',
        createdAt: now,
      ));

      final entries = await dao.getByTrailId('sentier-bleu');
      expect(entries.first.content, 'récent');
      expect(entries.last.content, 'ancien');
    });
  });
}
