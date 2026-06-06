import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/features/journal/data/photo_service.dart';

/// Tests du PhotoService (E3.1b).
///
/// Test 1 : compression fonctionne (photo sous 500 Ko retournee telle quelle)
/// Test 2 : limite 3 photos/jour respectee
void main() {
  late AppDatabase db;
  late JournalDao dao;
  late PhotoService service;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    dao = JournalDao(db);
    tempDir = await Directory.systemTemp.createTemp('photo_test_');
    service = PhotoService(journalDao: dao, storagePath: tempDir.path);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('PhotoService', () {
    test('compression retourne les octets tels quels si deja sous 500 Ko',
        () async {
      // Creer des octets factices sous la limite (100 octets)
      final smallBytes = Uint8List(100);
      for (var i = 0; i < 100; i++) {
        smallBytes[i] = i % 256;
      }

      final result = await service.compressPhoto(smallBytes);

      expect(result, isNotNull);
      expect(result!.length, equals(100));
      expect(result.length, lessThanOrEqualTo(PhotoService.maxSizeBytes));
    });

    test('limite 3 photos/jour respectee — la 4eme est refusee', () async {
      const trailId = 'gr20';
      final today = DateTime.now();

      // Inserer 3 photos pour aujourd'hui
      for (var i = 0; i < 3; i++) {
        await dao.insertEntry(JournalEntriesCompanion(
          trailId: const Value(trailId),
          stageNumber: const Value(1),
          content: Value('photo $i'),
          photoPath: Value('/photos/$i.jpg'),
          photoSizeBytes: const Value(1024),
          createdAt: Value(today),
        ));
      }

      // La 4eme photo doit etre refusee
      final smallBytes = Uint8List(100);
      final result = await service.savePhoto(
        trailId: trailId,
        sourceBytes: smallBytes,
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, equals(PhotoError.dailyLimitReached));

      // Verifier que canAddPhoto retourne false
      final canAdd = await service.canAddPhoto(trailId);
      expect(canAdd, isFalse);

      // Verifier le compteur
      final count = await service.photosToday(trailId);
      expect(count, equals(3));
    });

    test('savePhoto reussit quand la limite n est pas atteinte', () async {
      const trailId = 'tmb';
      final smallBytes = Uint8List(100);
      for (var i = 0; i < 100; i++) {
        smallBytes[i] = i % 256;
      }

      final result = await service.savePhoto(
        trailId: trailId,
        sourceBytes: smallBytes,
      );

      expect(result.isSuccess, isTrue);
      expect(result.path, isNotNull);
      expect(result.sizeBytes, equals(100));

      // Verifier que le fichier existe sur disque
      final file = File(result.path!);
      expect(file.existsSync(), isTrue);
    });

    test('deletePhoto supprime le fichier', () async {
      // Creer un fichier temporaire
      final file = File('${tempDir.path}/journal_photos/test_delete.jpg');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(Uint8List(10));
      expect(file.existsSync(), isTrue);

      final deleted = await service.deletePhoto(file.path);
      expect(deleted, isTrue);
      expect(file.existsSync(), isFalse);
    });

    test('getLocalPhotos retourne une liste vide si pas de photos', () async {
      final photos = await service.getLocalPhotos();
      expect(photos, isEmpty);
    });

    test('maxSizeBytes vaut 500 Ko', () {
      expect(PhotoService.maxSizeBytes, equals(500 * 1024));
    });

    test('maxPhotosPerDay vaut 3', () {
      expect(PhotoService.maxPhotosPerDay, equals(3));
    });
  });
}
