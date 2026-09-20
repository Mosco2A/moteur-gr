import 'package:drift/drift.dart';

import '../../../core/data/daos/journal_dao.dart';
import '../../../core/data/database.dart';
import '../domain/models/journal_entry.dart';

/// Repository du journal de trek.
///
/// Facade CRUD au-dessus de JournalDao (Drift).
/// Convertit les lignes Drift en JournalEntryModel (Freezed).
class JournalRepository {
  JournalRepository(this._dao);

  final JournalDao _dao;

  /// Recupere toutes les entrees d'un sentier, triees par date descendante
  Future<List<JournalEntryModel>> getByTrailId(String trailId) async {
    final rows = await _dao.getByTrailId(trailId);
    return rows.map(JournalEntryModel.fromDb).toList();
  }

  /// Recupere les entrees d'une etape pour un sentier
  Future<List<JournalEntryModel>> getByStage(
    String trailId,
    int stageNumber,
  ) async {
    final rows = await _dao.getByStage(trailId, stageNumber);
    return rows.map(JournalEntryModel.fromDb).toList();
  }

  /// Ajoute une nouvelle note textuelle au journal
  Future<JournalEntryModel> addNote({
    required String trailId,
    required int stageNumber,
    required String text,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insertEntry(JournalEntriesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(text),
      createdAt: Value(now),
    ));
    return JournalEntryModel(
      id: id,
      trailId: trailId,
      stageNumber: stageNumber,
      text: text,
      createdAt: now,
    );
  }

  /// Ajoute une entree de journal PORTANT UNE PHOTO (R10, LOT L10).
  ///
  /// La table et le modele savaient deja stocker `photoPath` / `photoSizeBytes`
  /// (et [JournalScreen] savait deja les AFFICHER), mais aucun chemin de code
  /// n'inserait jamais ces champs : toute entree naissait sans photo. Effet en
  /// cascade constate : la galerie du Diplome, qui filtre les entrees possedant
  /// une photo, restait STRUCTURELLEMENT vide. [text] peut etre vide (photo
  /// seule). Le fichier est deja compresse et copie en local par `PhotoService`
  /// AVANT cet appel : on ne stocke ici que le chemin et la taille finale.
  Future<JournalEntryModel> addPhotoNote({
    required String trailId,
    required int stageNumber,
    required String text,
    required String photoPath,
    required int photoSizeBytes,
  }) async {
    final now = DateTime.now();
    final id = await _dao.insertEntry(JournalEntriesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(text),
      photoPath: Value(photoPath),
      photoSizeBytes: Value(photoSizeBytes),
      createdAt: Value(now),
    ));
    return JournalEntryModel(
      id: id,
      trailId: trailId,
      stageNumber: stageNumber,
      text: text,
      photoPath: photoPath,
      photoSizeBytes: photoSizeBytes,
      createdAt: now,
    );
  }

  /// Met a jour le texte d'une entree existante
  Future<void> updateNote(int entryId, String text) async {
    await _dao.updateEntry(
      JournalEntriesCompanion(
        content: Value(text),
        updatedAt: Value(DateTime.now()),
      ),
      entryId,
    );
  }

  /// Supprime une entree par son identifiant
  Future<void> deleteEntry(int entryId) async {
    await _dao.deleteEntry(entryId);
  }

  /// Supprime toutes les entrees d'un sentier
  Future<void> deleteByTrailId(String trailId) async {
    await _dao.deleteByTrailId(trailId);
  }

  /// Compte le total d'entrees pour un sentier
  Future<int> countByTrailId(String trailId) async {
    return _dao.countByTrailId(trailId);
  }
}
