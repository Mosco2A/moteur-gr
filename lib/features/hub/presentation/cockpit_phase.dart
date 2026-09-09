import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../treks/domain/trek_lifecycle_state.dart';

/// Les trois PHASES visibles du cockpit par phases (nav V2, retour Chris R7).
///
/// Le cockpit n'affiche qu'UN mode a la fois (pas les 3 sections empilees de
/// GR20). La phase courante est DERIVEE du [TrekLifecycleState] du sentier
/// actif via [CockpitPhase.fromLifecycle] :
///  - owned / prepared -> [prepare] (bouton « Démarrer le trek », R6) ;
///  - inProgress       -> [hike]    (bouton « Terminer le trek ») ;
///  - completed        -> [after].
enum CockpitPhase {
  /// Phase « Préparer » : faisabilite, itineraire, programme, materiel...
  prepare,

  /// Phase « Randonner » : navigation, journal, incendie + bouton Démarrer.
  hike,

  /// Phase « Après » : recap, diplome (verrouille tant que non termine).
  after;

  /// PHASE PRINCIPALE derivee de l'etat de cycle de vie du trek (R7).
  ///
  /// `null` (aucun trek/etat non resolu) retombe sur [prepare] : le cockpit
  /// montre par defaut la preparation (point de depart du cycle).
  static CockpitPhase fromLifecycle(TrekLifecycleState? state) {
    switch (state) {
      case TrekLifecycleState.inProgress:
        return CockpitPhase.hike;
      case TrekLifecycleState.completed:
        return CockpitPhase.after;
      case TrekLifecycleState.owned:
      case TrekLifecycleState.prepared:
      case null:
        return CockpitPhase.prepare;
    }
  }

  /// Teinte d'AMBIANCE de la phase (R3) — token unique de verite reutilise par
  /// le fond discret du cockpit ET le bandeau d'en-tete de phase.
  ///
  /// Valeurs iso-`SectionHeader` GR20 (home_screen.dart :142/:297/:452), portees
  /// par les tokens [AppTheme] (jamais en dur ecran par ecran). SOBRE : elle
  /// signale l'etape du cycle, ne recolorise JAMAIS les icones categorielles.
  Color get color {
    switch (this) {
      case CockpitPhase.prepare:
        return AppTheme.phasePrepare; // bleuLight GR20
      case CockpitPhase.hike:
        return AppTheme.phaseHike; // vertMaquisLight GR20
      case CockpitPhase.after:
        return AppTheme.phaseAfter; // jaune diplome GR20
    }
  }
}
