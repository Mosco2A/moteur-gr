import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/journal/data/journal_repository.dart';

/// R10 (retour Chris, LOT L10) — UNE ENTREE DE JOURNAL PEUT PORTER UNE PHOTO.
///
/// Avant ce lot, la table, le modele et l'affichage savaient tous gerer
/// `photoPath` / `photoSizeBytes`, mais AUCUN chemin de code n'inserait jamais
/// ces champs : toute entree naissait sans photo. Consequence en CASCADE,
/// constatee en QA : la galerie du Diplome (`diploma_screen.dart`) construit sa
/// grille en filtrant les entrees de journal POSSEDANT une photo — elle restait
/// donc structurellement vide, quoi que fasse l'utilisateur.
///
/// Ces tests verrouillent le maillon manquant : l'ECRITURE d'une entree avec
/// photo, et sa relecture avec le chemin intact.
void main() {
  late AppDatabase db;
  late JournalRepository repo;

  const trailId = 'sentier-bleu';
  const photoPath = '/data/journal_photos/1700000000000.jpg';

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = JournalRepository(JournalDao(db));
  });

  tearDown(() => db.close());

  test('addPhotoNote persiste le chemin et la taille de la photo', () async {
    final created = await repo.addPhotoNote(
      trailId: trailId,
      stageNumber: 3,
      text: 'Le col sous la brume.',
      photoPath: photoPath,
      photoSizeBytes: 123456,
    );

    expect(created.photoPath, photoPath);
    expect(created.photoSizeBytes, 123456);

    // Relecture depuis la base : le chemin survit a l'aller-retour Drift.
    final entries = await repo.getByTrailId(trailId);
    expect(entries, hasLength(1));
    expect(entries.single.photoPath, photoPath);
    expect(entries.single.stageNumber, 3);
    expect(entries.single.text, 'Le col sous la brume.');
  });

  test('une PHOTO SEULE (sans texte) est une entree valide', () async {
    await repo.addPhotoNote(
      trailId: trailId,
      stageNumber: 1,
      text: '',
      photoPath: photoPath,
      photoSizeBytes: 2048,
    );

    final entries = await repo.getByTrailId(trailId);
    expect(entries.single.text, isEmpty);
    expect(entries.single.photoPath, isNotNull);
  });

  test('la galerie du Diplome a enfin de quoi se remplir', () async {
    // Meme filtre que `diploma_screen.dart` : les entrees AVEC photo.
    await repo.addNote(
      trailId: trailId,
      stageNumber: 1,
      text: 'Note sans photo',
    );
    await repo.addPhotoNote(
      trailId: trailId,
      stageNumber: 2,
      text: 'Avec photo',
      photoPath: photoPath,
      photoSizeBytes: 4096,
    );

    final entries = await repo.getByTrailId(trailId);
    final withPhoto =
        entries.where((e) => e.photoPath != null).toList(growable: false);

    expect(entries, hasLength(2));
    expect(withPhoto, hasLength(1),
        reason: 'Avant L10 ce filtre renvoyait TOUJOURS une liste vide');
    expect(withPhoto.single.photoPath, photoPath);
  });

  test('addNote (texte seul) ne porte toujours aucune photo', () async {
    await repo.addNote(trailId: trailId, stageNumber: 1, text: 'Juste du texte');

    final entries = await repo.getByTrailId(trailId);
    expect(entries.single.photoPath, isNull);
    expect(entries.single.photoSizeBytes, isNull);
  });
}
