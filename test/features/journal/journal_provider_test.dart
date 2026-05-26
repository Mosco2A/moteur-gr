import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/journal/providers/journal_provider.dart';

/// Tests du provider journal.
void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailIdProvider.overrideWithValue('gr20'),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('journalDaoProvider retourne un JournalDao valide', () {
    final dao = container.read(journalDaoProvider);
    expect(dao, isA<JournalDao>());
  });

  test('JournalNotifier initialise avec isLoading puis charge', () async {
    // Créer le notifier implicitement en lisant le provider
    container.read(journalProvider.notifier);
    // Attendre le chargement
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final state = container.read(journalProvider);
    expect(state.isLoading, false);
    expect(state.entries, isEmpty);
    expect(state.canAddPhoto, true);
  });

  test('addNote ajoute une entrée', () async {
    final notifier = container.read(journalProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await notifier.addNote(stageNumber: 1, content: 'Super étape !');
    final state = container.read(journalProvider);
    expect(state.entries.length, 1);
    expect(state.entries.first.content, 'Super étape !');
  });

  test('addPhoto respecte la limite de taille', () async {
    final notifier = container.read(journalProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Photo trop grande (> 500 Ko)
    final success = await notifier.addPhoto(
      stageNumber: 1,
      photoPath: '/test/photo.jpg',
      photoSizeBytes: 600 * 1024,
    );
    expect(success, false);
  });

  test('addPhoto respecte la limite quotidienne de 3', () async {
    final notifier = container.read(journalProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    // Ajouter 3 photos
    for (var i = 0; i < 3; i++) {
      await notifier.addPhoto(
        stageNumber: 1,
        photoPath: '/test/photo_$i.jpg',
        photoSizeBytes: 100 * 1024,
      );
    }

    // La 4e doit échouer
    final success = await notifier.addPhoto(
      stageNumber: 1,
      photoPath: '/test/photo_4.jpg',
      photoSizeBytes: 100 * 1024,
    );
    expect(success, false);
  });

  test('deleteEntry supprime et recharge', () async {
    final notifier = container.read(journalProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await notifier.addNote(stageNumber: 1, content: 'A supprimer');
    var state = container.read(journalProvider);
    final id = state.entries.first.id;

    await notifier.deleteEntry(id);
    state = container.read(journalProvider);
    expect(state.entries, isEmpty);
  });

  test('updateNote met à jour le contenu', () async {
    final notifier = container.read(journalProvider.notifier);
    await Future<void>.delayed(const Duration(milliseconds: 100));

    await notifier.addNote(stageNumber: 1, content: 'Avant');
    var state = container.read(journalProvider);
    final id = state.entries.first.id;

    await notifier.updateNote(id, 'Après modification');
    state = container.read(journalProvider);
    expect(state.entries.first.content, 'Après modification');
  });
}
