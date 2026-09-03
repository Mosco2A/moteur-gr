import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../features/trek/domain/models/trek_session.dart';
import '../database.dart';
import '../tables/trek_sessions_table.dart';

part 'trek_sessions_dao.g.dart';

/// DAO des sessions de trek (PARITE GR20, LOT 2, #99433).
///
/// Persiste une [TrekSession] en local Drift et la relit a l'identique
/// (round-trip), y compris la memoire du finisher : `completedStages` (JSON) et
/// `parcoursFullyWalked`. C'est le branchement REEL de `onSessionPersist`
/// (vide au LOT 1), pour que la progression SURVIVE a un redemarrage.
///
/// Mapping domaine <-> Drift centralise ici (encode/decode de la liste
/// d'etapes). Upsert par [TrekSession.id].
@DriftAccessor(tables: [TrekSessions])
class TrekSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$TrekSessionsDaoMixin {
  TrekSessionsDao(super.db);

  /// Cree ou met a jour la session [session] (upsert par id).
  ///
  /// Serialise `completedStages` en JSON. `onConflict: replace` garantit
  /// l'idempotence sur la cle primaire (id) : chaque persist ecrase la version
  /// precedente de CETTE session (etapes marchees + flag inclus).
  Future<void> upsertSession(TrekSession session) async {
    await into(trekSessions).insertOnConflictUpdate(_toCompanion(session));
  }

  /// Relit la session [id], ou null si absente.
  Future<TrekSession?> getById(String id) async {
    final row = await (select(trekSessions)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Relit la DERNIERE session persistee du sentier [trailId], ou null si
  /// aucune (PARITE GR20, LOT 3, #99433).
  ///
  /// « Derniere » = la plus recemment demarree ([TrekSession.startedAt] le plus
  /// grand), avec la date de fin comme second critere (une session terminee
  /// prime a horodatage egal). C'est la source de verite « apres le trek » : le
  /// gate du diplome (finisher reel) et l'ecran Recap « Mon aventure » lisent
  /// cette session pour refleter le parcours REELLEMENT effectue (etapes
  /// marchees + drapeau finisher), y compris apres un redemarrage.
  Future<TrekSession?> getLatestByTrailId(String trailId) async {
    final row = await (select(trekSessions)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.finishedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  /// Sessions au statut `active` (candidates a la reprise apres crash).
  ///
  /// Alimente le detecteur de session orpheline ([TrekSessionManager]) : une
  /// session `active` en base signale une fermeture brutale.
  Future<List<TrekSession>> findActiveSessions() async {
    final rows = await (select(trekSessions)
          ..where((t) => t.status.equals('active')))
        .get();
    return rows.map(_fromRow).toList();
  }

  /// Met a jour le seul statut de la session [id] (ex. `abandoned`).
  Future<void> updateStatus(String id, String status) async {
    await (update(trekSessions)..where((t) => t.id.equals(id)))
        .write(TrekSessionsCompanion(status: Value(status)));
  }

  /// Supprime la session [id].
  Future<void> deleteSession(String id) async {
    await (delete(trekSessions)..where((t) => t.id.equals(id))).go();
  }

  // --- Mapping domaine <-> Drift ---

  TrekSessionsCompanion _toCompanion(TrekSession s) {
    return TrekSessionsCompanion(
      id: Value(s.id),
      trailId: Value(s.trailId),
      startedAt: Value(s.startedAt),
      finishedAt: Value(s.finishedAt),
      status: Value(s.status),
      completedStagesJson: Value(jsonEncode(s.completedStages)),
      parcoursFullyWalked: Value(s.parcoursFullyWalked),
    );
  }

  TrekSession _fromRow(TrekSessionRow row) {
    return TrekSession(
      id: row.id,
      trailId: row.trailId,
      startedAt: row.startedAt,
      finishedAt: row.finishedAt,
      status: row.status,
      completedStages: _decodeStages(row.completedStagesJson),
      parcoursFullyWalked: row.parcoursFullyWalked,
    );
  }

  /// Decode la liste d'etapes JSON en `List<String>`. Robuste : toute valeur
  /// invalide (legacy, corrompue) retombe sur une liste vide -> jamais de faux
  /// finisher au rechargement.
  List<String> _decodeStages(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } on FormatException {
      // Valeur non-JSON : on ignore et on retourne une liste vide.
    }
    return const <String>[];
  }
}
