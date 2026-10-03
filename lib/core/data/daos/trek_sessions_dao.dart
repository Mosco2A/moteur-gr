/// Sessions de trek persistees puis relues a l'identique, memoire du finisher
/// comprise, pour que la progression survive a un redemarrage.
library;

// CE DAO PARLE LIGNES, PAS SESSIONS (ARB-645-05-c, decision B de Christophe,
// 03/10/2026).
//
// LE SOCLE NE CONNAIT PAS LE METIER. Ce fichier importait
// `lib/domain/trek_session.dart` : un fichier de `core/` lisait un modele de la
// couche au-dessus de lui, et c etait la derniere des trois fleches interdites
// du lot. Elle venait d un endroit precis, et d un seul : le MAPPING
// [TrekSession] <-> Drift, qui est par definition le morceau qui connait le
// metier.
//
// CE QUI EST PARTI, ET OU. Le mapping et les quatre methodes typees
// [TrekSession] (`upsertSession`, `getById`, `getLatestByTrailId`,
// `findActiveSessions`) vivent desormais dans
// `lib/domain/trek_session_mapping.dart`, en EXTENSION de cette meme classe.
// `lib/domain/` a le droit de lire le socle : c est le sens autorise. Les
// appelants gardent donc exactement les memes appels, les memes noms et les
// memes signatures — `dao.upsertSession(session)` s ecrit comme avant — et il
// leur suffit d importer le fichier d extension.
//
// CE QUI RESTE ICI : les requetes Drift, en LIGNES (`upsertRow`, `rowById`,
// `latestRowByTrailId`, `ongoingRows`), plus ce qui ne parle que de colonnes
// (`updateStatus`, `deleteSession`, [kOngoingStatuses]). Aucun ordre SQL n a
// change : les `where`, les `orderBy`, le `limit` et le `onConflict` sont ceux
// d avant, deplaces d un cran vers l appelant.

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/trek_sessions_table.dart';

part 'trek_sessions_dao.g.dart';

/// DAO des sessions de trek (PARITE GR20, LOT 2, #99433).
///
/// Persiste une session en local Drift et la relit a l'identique (round-trip),
/// y compris la memoire du finisher : `completedStagesJson` et
/// `parcoursFullyWalked`. C'est le branchement REEL de `onSessionPersist`
/// (vide au LOT 1), pour que la progression SURVIVE a un redemarrage.
///
/// IL PARLE LIGNES ET COLONNES, JAMAIS MODELE DE DOMAINE. Le mapping
/// `TrekSession` <-> Drift et les quatre methodes qui le portent vivent dans
/// `lib/domain/trek_session_mapping.dart`, en extension de cette classe : le
/// socle ne connait pas le metier (ARB-645-05-c). Voir l'en-tete du fichier.
@DriftAccessor(tables: [TrekSessions])
class TrekSessionsDao extends DatabaseAccessor<AppDatabase>
    with _$TrekSessionsDaoMixin {
  TrekSessionsDao(super.db);

  /// Cree ou met a jour la ligne [companion] (upsert par id).
  ///
  /// `onConflict: replace` garantit l'idempotence sur la cle primaire (id) :
  /// chaque ecriture ecrase la version precedente de CETTE session (etapes
  /// marchees + drapeau finisher inclus).
  Future<void> upsertRow(TrekSessionsCompanion companion) async {
    await into(trekSessions).insertOnConflictUpdate(companion);
  }

  /// Relit la ligne [id], ou null si absente.
  Future<TrekSessionRow?> rowById(String id) async {
    return (select(
      trekSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Relit la DERNIERE ligne persistee du sentier [trailId], ou null si aucune
  /// (PARITE GR20, LOT 3, #99433).
  ///
  /// « Derniere » = la plus recemment demarree (`startedAt` le plus grand),
  /// avec la date de fin comme second critere (une session terminee prime a
  /// horodatage egal). C'est la source de verite « apres le trek » : le gate du
  /// diplome (finisher reel) et l'ecran Recap « Mon aventure » lisent cette
  /// session pour refleter le parcours REELLEMENT effectue (etapes marchees +
  /// drapeau finisher), y compris apres un redemarrage.
  Future<TrekSessionRow?> latestRowByTrailId(String trailId) async {
    return (select(trekSessions)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.startedAt),
            (t) => OrderingTerm.desc(t.finishedAt),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Statuts consideres « en cours » : une session `active` OU `paused` occupe
  /// l'unique creneau de rando active (invariant C4, StepWays LOT 2).
  static const List<String> kOngoingStatuses = <String>['active', 'paused'];

  /// Lignes des sessions EN COURS (statut `active` OU `paused`) — StepWays LOT
  /// 2, gap C4a.
  ///
  /// Alimente (1) le detecteur de session orpheline au boot
  /// ([TrekSessionManager.checkPendingSession] / [cleanOrphans]) et (2) la
  /// garde d'unicite cross-trail [ensureSingleActiveThenStart] : une session
  /// `active` OU `paused` en base signale un trek deja en cours (fermeture
  /// brutale ou simple mise en pause). AVANT LOT 2 seul `active` etait remonte
  /// -> une rando mise en pause echappait a l'invariant « au plus 1 rando en
  /// cours » et a la reprise orpheline. On inclut donc `paused`
  /// ([kOngoingStatuses]).
  Future<List<TrekSessionRow>> ongoingRows() async {
    return (select(
      trekSessions,
    )..where((t) => t.status.isIn(kOngoingStatuses))).get();
  }

  /// Met a jour le seul statut de la session [id] (ex. `abandoned`).
  Future<void> updateStatus(String id, String status) async {
    await (update(trekSessions)..where((t) => t.id.equals(id))).write(
      TrekSessionsCompanion(status: Value(status)),
    );
  }

  /// Supprime la session [id].
  Future<void> deleteSession(String id) async {
    await (delete(trekSessions)..where((t) => t.id.equals(id))).go();
  }
}
