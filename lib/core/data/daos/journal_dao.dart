import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/journal_entries_table.dart';

part 'journal_dao.g.dart';

/// DAO pour les opérations sur le journal de trek.
///
/// Fournit les méthodes CRUD pour la table JournalEntries,
/// filtrées par sentier et/ou étape. Limite à 3 photos/jour.
@DriftAccessor(tables: [JournalEntries])
class JournalDao extends DatabaseAccessor<AppDatabase>
    with _$JournalDaoMixin {
  JournalDao(super.db);

  /// Nombre maximum de photos par jour
  static const int maxPhotosPerDay = 3;

  /// Taille maximum d'une photo en octets (500 Ko)
  static const int maxPhotoSizeBytes = 500 * 1024;

  /// Récupère toutes les entrées pour un sentier, triées par date
  Future<List<JournalEntry>> getByTrailId(String trailId) {
    return (select(journalEntries)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Récupère les entrées d'une étape pour un sentier
  Future<List<JournalEntry>> getByStage(String trailId, int stageNumber) {
    return (select(journalEntries)
          ..where((t) =>
              t.trailId.equals(trailId) &
              t.stageNumber.equals(stageNumber))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Insère une nouvelle entrée de journal
  Future<int> insertEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  /// Met à jour une entrée existante
  Future<int> updateEntry(JournalEntriesCompanion entry, int entryId) {
    return (update(journalEntries)..where((t) => t.id.equals(entryId)))
        .write(entry);
  }

  /// Supprime une entrée par son identifiant
  Future<int> deleteEntry(int entryId) {
    return (delete(journalEntries)..where((t) => t.id.equals(entryId))).go();
  }

  /// Compte le nombre de photos ajoutées aujourd'hui pour un sentier
  Future<int> countPhotosToday(String trailId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final entries = await (select(journalEntries)
          ..where((t) =>
              t.trailId.equals(trailId) &
              t.photoPath.isNotNull() &
              t.createdAt.isBiggerOrEqualValue(startOfDay) &
              t.createdAt.isSmallerThanValue(endOfDay)))
        .get();
    return entries.length;
  }

  /// Vérifie si on peut encore ajouter une photo aujourd'hui
  Future<bool> canAddPhoto(String trailId) async {
    final count = await countPhotosToday(trailId);
    return count < maxPhotosPerDay;
  }

  /// Supprime toutes les entrées d'un sentier
  Future<int> deleteByTrailId(String trailId) {
    return (delete(journalEntries)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Compte le total d'entrées pour un sentier
  Future<int> countByTrailId(String trailId) async {
    final entries = await getByTrailId(trailId);
    return entries.length;
  }
}
