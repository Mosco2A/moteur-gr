import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../after/providers/adventure_recap_provider.dart'
    show latestTrekSessionProvider;
import '../../trek/providers/tracking_providers.dart';
import '../domain/trek_edit_lock.dart';

/// Verrou d'edition du programme pendant la rando (R12, LOT L9).
///
/// Source unique de la contrainte « on ne modifie que ce qui n'est pas encore
/// fait ». Agrege les DEUX vues de la session de rando, sans en inventer une
/// troisieme :
///
///   * la session VIVANTE du tracking ([trekSessionManagerProvider]) : a jour a
///     la seconde pendant la marche (chaque arrivee detectee alimente
///     `completedStages` via `recordStageCompleted`) ;
///   * la session PERSISTEE ([latestTrekSessionProvider], Drift) : indispensable
///     apres un redemarrage de l'app en pleine rando, ou la session vivante
///     repart vide tant que la reprise n'a pas eu lieu. Sans elle, un
///     redemarrage rouvrirait l'edition des jours deja marches.
///
/// Les deux listes d'etapes faites sont UNIES (jamais l'une a la place de
/// l'autre) : une etape marchee reste marchee, quelle que soit la vue qui s'en
/// souvient. Le trek est considere DEMARRE si le tracking enregistre/est en
/// pause, ou si la session persistee est encore `active`/`paused`.
///
/// Hors rando, renvoie [TrekEditLock.none] : le programme de PREPARATION reste
/// editable exactement comme avant R12 (aucune regression sur le flux amont).
final trekEditLockProvider = Provider<TrekEditLock>((ref) {
  // --- Vue vivante (tracking en memoire) ---
  final tracking = ref.watch(trekSessionManagerProvider);
  final liveActive = tracking.status == TrackingSessionStatus.recording ||
      tracking.status == TrackingSessionStatus.paused;
  final liveDone = tracking.session?.completedStages ?? const <String>[];

  // --- Vue persistee (Drift) ---
  // `.value` : tant que la lecture n'a pas abouti (ou si elle echoue), on
  // retombe proprement sur la seule vue vivante — jamais d'exception, jamais de
  // blocage de l'ecran.
  final persisted = ref.watch(latestTrekSessionProvider).value;
  final persistedOngoing =
      persisted != null && (persisted.status == 'active' || persisted.status == 'paused');
  final persistedDone = persisted?.completedStages ?? const <String>[];

  final started = liveActive || persistedOngoing;
  final done = <String>{...liveDone, ...persistedDone};

  if (!started && done.isEmpty) return TrekEditLock.none;
  return TrekEditLock(trekStarted: started, doneStageIds: done);
});
