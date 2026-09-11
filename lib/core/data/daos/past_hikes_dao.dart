import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/past_hikes_table.dart';

part 'past_hikes_dao.g.dart';

/// Nombre maximum de randos passees conservees par utilisateur (spec §3.3).
const int kMaxPastHikes = 5;

/// DAO des randos passees + note d'experience globale (StepWays LOT 4, Ph3).
///
/// [PastHikeEntries] : jusqu'a [kMaxPastHikes] lignes par [userId] (hash
/// SHA-256). [HikerExperienceNote] : singleton par [userId] (texte libre
/// global).
///
/// Meme regle de persistance que le profil : Drift CANONIQUE, source durable
/// en prefs (hydratation au boot par le repository). Les randos sont triees par
/// date decroissante (la plus recente d'abord).
@DriftAccessor(tables: [PastHikeEntries, HikerExperienceNote])
class PastHikesDao extends DatabaseAccessor<AppDatabase>
    with _$PastHikesDaoMixin {
  PastHikesDao(super.db);

  /// Relit les randos de [userId], la plus recente d'abord.
  Future<List<PastHikeEntry>> getByUserId(String userId) {
    return (select(pastHikeEntries)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
  }

  /// Observe les randos de [userId] (emet a chaque modification).
  Stream<List<PastHikeEntry>> watchByUserId(String userId) {
    return (select(pastHikeEntries)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  /// Insere une rando et retourne son id.
  Future<int> insertHike(PastHikeEntriesCompanion entry) {
    return into(pastHikeEntries).insert(entry);
  }

  /// Supprime une rando par [id].
  Future<int> deleteHike(int id) {
    return (delete(pastHikeEntries)..where((t) => t.id.equals(id))).go();
  }

  /// Supprime toutes les randos de [userId] (droit a l'effacement RGPD).
  Future<int> deleteAllForUser(String userId) {
    return (delete(pastHikeEntries)..where((t) => t.userId.equals(userId)))
        .go();
  }

  // --- Note d'experience globale (singleton par userId) --------------------

  /// Relit la note d'experience globale de [userId], ou null si absente.
  Future<HikerExperienceNoteData?> getNote(String userId) {
    return (select(hikerExperienceNote)..where((t) => t.userId.equals(userId)))
        .getSingleOrNull();
  }

  /// Observe la note d'experience globale de [userId] (null si absente).
  Stream<HikerExperienceNoteData?> watchNote(String userId) {
    return (select(hikerExperienceNote)..where((t) => t.userId.equals(userId)))
        .watchSingleOrNull();
  }

  /// Cree ou met a jour la note d'experience globale (upsert par [userId]).
  Future<void> upsertNote(HikerExperienceNoteCompanion entry) async {
    await into(hikerExperienceNote).insertOnConflictUpdate(entry);
  }
}
