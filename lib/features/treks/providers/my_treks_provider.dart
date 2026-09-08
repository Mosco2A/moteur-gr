import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../trek/domain/models/trek_session.dart';
import '../domain/trek_lifecycle_state.dart';
import '../domain/trek_state_deriver.dart';
import '../domain/trek_summary.dart';
import 'entitlements_provider.dart';

/// Liste des treks de l'utilisateur pour l'accueil « Mes treks » (StepWays
/// LOT 2, Phase 2 / §2).
///
/// Itere les treks POSSEDES ([ownedTrailIdsProvider] = achats ∪ vitrine),
/// resout chacun en [TrekSummary] (config + etat derive + derniere session +
/// progression) et TRIE la liste pour l'affichage. Un id possede mais absent du
/// catalogue (sentier retire) est ignore (genericite robuste).
///
/// Tri (spec §2, ordre d'affichage de l'ecran) :
///   1. EN COURS d'abord (inProgress) ;
///   2. puis PREPARES + POSSEDES-vierges, par derniere activite desc ;
///   3. puis TERMINES, par date de fin desc.
/// A cle de tri egale, ordre du catalogue (stable).
///
/// FutureProvider : agrege plusieurs lectures Drift (sessions + progression) par
/// trek. Zero etat persiste en plus — tout est derive a la volee.
final myTreksProvider = FutureProvider<List<TrekSummary>>((ref) async {
  final ownedIds = await ref.watch(ownedTrailIdsProvider.future);
  final db = ref.watch(databaseProvider);

  // Catalogue via le provider (overridable en test + futur catalogue distant),
  // coherent avec `ownedTrailIdsProvider` (jamais le catalogue statique en dur).
  final catalog = {
    for (final c in ref.watch(availableTrailsProvider)) c.id: c,
  };

  final summaries = <TrekSummary>[];
  for (final trailId in ownedIds) {
    final config = catalog[trailId];
    if (config == null) continue; // sentier retire du catalogue : on ignore.

    final latestSession = await db.trekSessionsDao.getLatestByTrailId(trailId);
    final progress = await db.progressDao.getByTrailId(trailId);

    final hasPlanningOrProgress = progress != null;
    final state = deriveState(
      latestSession: latestSession,
      hasPlanningOrProgress: hasPlanningOrProgress,
    );

    summaries.add(TrekSummary(
      config: config,
      state: state,
      latestSession: latestSession,
      progress: progress,
    ));
  }

  _sortForHome(summaries);
  return summaries;
});

/// Rang de tri d'un etat (plus petit = plus haut dans la liste).
int _stateRank(TrekLifecycleState state) {
  switch (state) {
    case TrekLifecycleState.inProgress:
      return 0;
    case TrekLifecycleState.prepared:
    case TrekLifecycleState.owned:
      return 1;
    case TrekLifecycleState.completed:
      return 2;
  }
}

/// Trie en place selon l'ordre d'affichage de l'ecran « Mes treks » (§2).
///
/// Comparateur STABLE (le tri de Dart l'est) : a cle egale, l'ordre d'insertion
/// — celui du catalogue — est conserve.
void _sortForHome(List<TrekSummary> summaries) {
  summaries.sort((a, b) {
    final rank = _stateRank(a.state).compareTo(_stateRank(b.state));
    if (rank != 0) return rank;
    // Meme groupe : les plus recemment actifs d'abord (activite/fin desc).
    final da = a.lastActivityAt;
    final db = b.lastActivityAt;
    if (da == null && db == null) return 0;
    if (da == null) return 1; // sans activite -> apres ceux qui en ont.
    if (db == null) return -1;
    return db.compareTo(da); // desc
  });
}

/// [TrekSummary] du sentier ACTIF (celui du cockpit `/home`), ou null si son
/// id est absent du catalogue (StepWays LOT 2, Phase 5 — cockpit).
///
/// Derive l'etat ([TrekLifecycleState]) du sentier courant
/// ([trailConfigProvider.id]) a la volee, exactement comme [myTreksProvider] le
/// fait par trek, mais SANS dependre des droits ([ownedTrailIdsProvider]) : le
/// cockpit reflete l'etat du sentier affiche qu'il soit « possede » ou non
/// (vitrine, achat en cours de migration...). C'est la source unique de la
/// carte principale du HUB ([HubTrekCard]) pour choisir entre « Démarrer »
/// (owned/prepared), la carte active (inProgress) et « Revoir/Diplôme »
/// (completed). Re-derive automatiquement au changement de sentier
/// (`selectedTrailIdProvider`) ou de session.
final currentTrailSummaryProvider = FutureProvider<TrekSummary?>((ref) async {
  final config = ref.watch(trailConfigProvider);
  final db = ref.watch(databaseProvider);

  final latestSession = await db.trekSessionsDao.getLatestByTrailId(config.id);
  final progress = await db.progressDao.getByTrailId(config.id);

  final state = deriveState(
    latestSession: latestSession,
    hasPlanningOrProgress: progress != null,
  );

  return TrekSummary(
    config: config,
    state: state,
    latestSession: latestSession,
    progress: progress,
  );
});

/// Identifiant du trek ACTUELLEMENT en cours (session `active`|`paused`), ou
/// null si aucun (StepWays LOT 2, Phase 2 — invariant C4 : au plus 1).
///
/// Derive de la source d'unicite [TrekSessionsDao.findActiveSessions] (qui
/// inclut desormais `paused`, gap C4a) : s'il existe une session en cours, on
/// renvoie le sentier de la PLUS RECENTE (defense en profondeur si l'invariant
/// « au plus 1 » etait viole — ex. donnees heritees). C'est le trek que l'UI
/// met en avant (carte active du cockpit) et que la garde de demarrage
/// [ensureSingleActiveThenStart] doit resoudre avant d'en lancer un autre.
final activeTrekIdProvider = FutureProvider<String?>((ref) async {
  final db = ref.watch(databaseProvider);
  final ongoing = await db.trekSessionsDao.findActiveSessions();
  if (ongoing.isEmpty) return null;
  final TrekSession mostRecent = ongoing.reduce(
    (a, b) => a.startedAt.isAfter(b.startedAt) ? a : b,
  );
  return mostRecent.trailId;
});
