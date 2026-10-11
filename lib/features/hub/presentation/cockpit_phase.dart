/// Le cockpit n'affiche qu'UNE phase a la fois, DERIVEE du cycle de vie du
/// sentier : preparer, randonner, ou apres.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../trek/trek_facade.dart'
    show TrackingSessionStatus, trekSessionManagerProvider;
import '../../treks/treks_facade.dart'
    show
        TrekLifecycleState,
        currentTrailSummaryProvider,
        kSessionStatusCompleted;

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
  ///
  /// PRIVEE DEPUIS LA TACHE 809, ET C'EST LA TOUTE LA GARANTIE. Elle etait
  /// publique, et deux ecrans la rappelaient chacun pour son compte en
  /// y ajoutant leur propre interpretation de l'etat vivant : trois lectures de
  /// la meme chose, qui ne tombaient pas d'accord en demonstration. Le seul
  /// moyen PUBLIC d'obtenir une phase est desormais [cockpitPhaseProvider] —
  /// pas par discipline, par portee de fichier. Le bouton qu'on ajoutera demain
  /// ne PEUT PLUS se deriver une phase a lui.
  static CockpitPhase _fromLifecycle(TrekLifecycleState? state) {
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

/// LA PHASE DE LA RANDONNEE — SOURCE UNIQUE, ET LA SEULE PORTE (tache 809).
///
/// CE QUE CHRISTOPHE A VU LE 10/10, EN MODE DEMO, ET QU'IL A DIT EN TROIS FOIS.
/// Verbatim, dans son ordre :
///   (a) « meme en mode demo preparer devrait disparaitre quand tu es en cours
///       de trek » ;
///   (b) « demarrer la randonne, le bouton aparait encore une fois la randonnee
///       finie au lieu d acceder a la post rando » ;
///   (c) « enlever le bouton acheter quand on est en trek et en post dtrek car
///       le circuit a forcement ete achete ».
///
/// UNE SEULE MALADIE, MAIS TROIS CAUSES DIFFERENTES — mesurees une par une :
///
///   1. « Préparer » et « Démarrer » etaient DEJA commandes par la phase, mais
///      chaque ecran la recalculait pour son compte en melangeant l'etat vivant
///      du suivi et l'etat derive de la base. Trois recalculs du meme fait.
///   2. « Acheter » etait rendu ENTIEREMENT HORS du mecanisme de phase : il ne
///      consultait que la POSSESSION (`isDemoModeProvider`, « ce sentier est
///      encore a vendre »). Il n'a jamais rien su de la marche, ni en demo ni
///      ailleurs — d'ou sa presence pendant et apres.
///   3. APRES L'ARRIVEE EN DEMO, la phase retombait sur [CockpitPhase.prepare].
///      C'est le defaut (b), et voici sa mecanique exacte : la demo n'ecrit
///      RIEN (tache 760, quatre barrieres dans `tracking_providers.dart`), donc
///      aucune ligne de session n'existe en base, donc `deriveState` ne peut
///      repondre que `owned` ou `prepared`. PENDANT la marche simulee cela
///      passait inapercu — le suivi vivant valait `recording` et les ecrans
///      l'ORaient. A la seconde de l'arrivee, ce suivi passait a `stopped` et
///      la memoire de la session etait effacee : plus rien, nulle part, ne
///      savait que la randonnee venait de finir.
///
/// CE QUE VALAIT REELLEMENT [TrekLifecycleState] PENDANT UNE MARCHE SIMULEE :
/// `owned` ou `prepared` — JAMAIS `inProgress`, JAMAIS `completed`. La garde
/// `test/features/hub/un_seul_etat_de_rando_809_test.dart` le mesure au lieu de
/// le croire.
///
/// LES TROIS REGLES, DANS CET ORDRE, ET L'ORDRE EST LE RAISONNEMENT :
///
///   1. LA MARCHE VIVANTE PRIME. Un suivi `recording` ou `paused` en memoire
///      est le fait le plus frais qui existe : la session persistee peut ne pas
///      etre encore relue apres un demarrage, et en demo elle n'existera
///      jamais. Parite avec ce que [HubTrekCard] faisait deja seul.
///   2. L'ARRIVEE QU'AUCUNE BASE N'A VUE. Un suivi arrete qui porte encore sa
///      session TERMINEE sur CE sentier dit l'apres-randonnee. C'est la regle
///      qui repare la demo, et elle ne s'appuie sur aucun drapeau neuf : elle
///      lit `status` sur la session que `_finalize` garde desormais en memoire.
///      Un ABANDON ne passe pas par ici (`status` vaut alors `abandoned`) et
///      retombe en regle 3, ou `deriveState` le rend `prepared` — un abandon
///      est rejouable, ce n'est pas une arrivee.
///   3. LA BASE, QUI SURVIT AU REDEMARRAGE. C'est la verite de la randonnee
///      reelle, inchangee depuis R7.
///
/// LE SENTIER EST VERIFIE EN REGLE 2, PAS EN REGLE 1. La regle 2 est neuve :
/// elle ne doit jamais declarer « arrivee » le cockpit d'un sentier B parce
/// qu'un sentier A s'est termine. La regle 1 garde le comportement livre
/// (aucune comparaison de sentier), parce que la garde d'unicite C4 n'autorise
/// de toute facon qu'UNE randonnee active : la rendre plus stricte serait un
/// autre lot, et elle est signalee comme telle.
final cockpitPhaseProvider = Provider<CockpitPhase>((ref) {
  final suivi = ref.watch(trekSessionManagerProvider);

  // 1. LA MARCHE VIVANTE PRIME.
  if (suivi.status == TrackingSessionStatus.recording ||
      suivi.status == TrackingSessionStatus.paused) {
    return CockpitPhase.hike;
  }

  // 2. L'ARRIVEE QU'AUCUNE BASE N'A VUE (le cas de la demonstration).
  final finie = suivi.session;
  final sentier = ref.watch(trailConfigProvider.select((c) => c.id));
  if (finie != null &&
      finie.status == kSessionStatusCompleted &&
      finie.trailId == sentier) {
    return CockpitPhase.after;
  }

  // 3. LA BASE, QUI SURVIT AU REDEMARRAGE.
  return CockpitPhase._fromLifecycle(
    ref.watch(currentTrailSummaryProvider.select((a) => a.value?.state)),
  );
});
