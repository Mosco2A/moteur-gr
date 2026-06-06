import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/features/journal/data/journal_repository.dart';

/// Tests du JournalRepository sur une base in-memory.
///
/// Verifie la persistance des notes et la lecture filtree par etape.
void main() {
  late AppDatabase db;
  late JournalDao dao;
  late JournalRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = JournalDao(db);
    repository = JournalRepository(dao);
  });

  tearDown(() async {
    await db.close();
  });

  group('JournalRepository', () {
    test('addNote persiste la note et retourne le modele', () async {
      // Ajouter une note
      final entry = await repository.addNote(
        trailId: 'sentier-bleu',
        stageNumber: 3,
        text: 'Magnifique vue depuis le Monte Cinto',
      );

      // Verifier le modele retourne
      expect(entry.id, greaterThan(0));
      expect(entry.trailId, 'sentier-bleu');
      expect(entry.stageNumber, 3);
      expect(entry.text, 'Magnifique vue depuis le Monte Cinto');
      expect(entry.createdAt, isNotNull);

      // Verifier la persistance en base
      final entries = await repository.getByTrailId('sentier-bleu');
      expect(entries.length, 1);
      expect(entries.first.text, 'Magnifique vue depuis le Monte Cinto');
    });

    test('getByStage retourne uniquement les notes de l etape demandee',
        () async {
      // Ajouter des notes sur differentes etapes
      await repository.addNote(
        trailId: 'sentier-bleu',
        stageNumber: 1,
        text: 'Depart de Calenzana',
      );
      await repository.addNote(
        trailId: 'sentier-bleu',
        stageNumber: 2,
        text: 'Refuge de Carozzu',
      );
      await repository.addNote(
        trailId: 'sentier-bleu',
        stageNumber: 2,
        text: 'Piscine naturelle geniale',
      );
      await repository.addNote(
        trailId: 'sentier-bleu',
        stageNumber: 3,
        text: 'Haut Asco',
      );

      // Lecture filtree par etape 2
      final stage2Entries = await repository.getByStage('sentier-bleu', 2);
      expect(stage2Entries.length, 2);
      for (final entry in stage2Entries) {
        expect(entry.stageNumber, 2);
      }

      // Etape 1 = 1 note
      final stage1Entries = await repository.getByStage('sentier-bleu', 1);
      expect(stage1Entries.length, 1);
      expect(stage1Entries.first.text, 'Depart de Calenzana');

      // Etape inexistante = vide
      final stage99 = await repository.getByStage('sentier-bleu', 99);
      expect(stage99, isEmpty);
    });
  });
}
