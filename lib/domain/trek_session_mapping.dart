/// Le pont entre une [TrekSession] et sa ligne Drift : seul endroit du depot
/// qui sait traduire l'une en l'autre, dans les deux sens.
library;

// POURQUOI CE FICHIER EXISTE, ET POURQUOI IL VIT DANS `lib/domain/`
// (ARB-645-05-c, decision B de Christophe, 03/10/2026).
//
// LE SOCLE NE CONNAIT PAS LE METIER.
// `lib/core/data/daos/trek_sessions_dao.dart` portait ces quatre methodes et ce
// mapping, et importait donc `lib/domain/trek_session.dart` : un fichier de
// `core/` lisait la couche au-dessus de lui. C'etait la derniere des trois
// fleches interdites du lot 645-05b, et elle venait d'un seul endroit — le
// mapping, qui EST par definition le morceau qui connait le metier.
//
// UNE EXTENSION, ET PAS UN NOUVEAU SERVICE. C'est ce qui rend ce deplacement
// gratuit pour les appelants : `dao.upsertSession(session)` s'ecrit exactement
// comme avant, avec le meme nom, la meme signature et le meme resultat. Un
// fichier qui utilise ces methodes importe ce fichier-ci en plus du DAO, et
// rien d'autre ne change. Aucune attente de test n'a donc eu a bouger.
//
// LE SENS EST DESORMAIS LE BON. `lib/domain/` a le DROIT de lire le socle : ce
// fichier importe `core/data/database.dart` pour les types Drift engendres
// ([TrekSessionRow], [TrekSessionsCompanion]) et le DAO pour l'etendre. C'est
// la direction autorisee, celle que la garde
// `test/structurel/couches_respectees_645_test.dart` laisse passer ; l'inverse
// est desormais plafonne a zero.
//
// CE QUI N'A PAS CHANGE : l'encodage JSON de `completedStages`, la tolerance
// aux valeurs invalides, et le fait que la lecture d'une ligne absente rende
// `null`. Le code ci-dessous est celui du DAO, deplace sans retouche de
// logique.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../core/data/daos/trek_sessions_dao.dart';
import '../core/data/database.dart';
import 'trek_session.dart';

/// Les methodes de [TrekSessionsDao] qui parlent [TrekSession].
///
/// Le DAO lui-meme ne parle que lignes et colonnes ; c'est ici que la ligne
/// devient une session de trek, et l'inverse.
extension TrekSessionPersistence on TrekSessionsDao {
  /// Cree ou met a jour la session [session] (upsert par id).
  ///
  /// Serialise `completedStages` en JSON. L'idempotence sur la cle primaire est
  /// celle de [TrekSessionsDao.upsertRow] : chaque persist ecrase la version
  /// precedente de CETTE session (etapes marchees + drapeau finisher inclus).
  Future<void> upsertSession(TrekSession session) =>
      upsertRow(_toCompanion(session));

  /// Relit la session [id], ou null si absente.
  Future<TrekSession?> getById(String id) async {
    final row = await rowById(id);
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
    final row = await latestRowByTrailId(trailId);
    return row == null ? null : _fromRow(row);
  }

  /// Sessions EN COURS (statut `active` OU `paused`) — StepWays LOT 2, gap C4a.
  ///
  /// Alimente (1) le detecteur de session orpheline au boot et (2) la garde
  /// d'unicite cross-trail : une session `active` OU `paused` en base signale
  /// un trek deja en cours (fermeture brutale ou simple mise en pause). Les
  /// deux statuts retenus sont ceux de [TrekSessionsDao.kOngoingStatuses].
  Future<List<TrekSession>> findActiveSessions() async {
    final rows = await ongoingRows();
    return rows.map(_fromRow).toList();
  }
}

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
