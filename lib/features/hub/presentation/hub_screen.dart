/// Le cockpit, point d'entree de l'app apres le catalogue, qui ne cree aucun
/// etat metier et ne fait que deriver l'existant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/branding/stepways_icons.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/services/mise_a_jour_a_la_source.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/quick_access_card.dart';
import '../../ads/ads_facade.dart' show BannerAdSlot;
import '../../safety/safety_facade.dart'
    show SosQuiReserveSaPlace, reserveSousLeSosProvider;
import 'cockpit_phase.dart';
import 'widgets/hub_app_bar.dart';
import 'widgets/hub_cockpit_scroll.dart';
import 'widgets/hub_hike_section.dart';
import 'widgets/hub_info_section.dart';
import 'widgets/hub_prepare_section.dart';
import 'widgets/localized_conditions_banner.dart';

/// Ecran d'accueil — HUB E07 (LOT-A, socle structurel).
///
/// Point d'entree de l'app apres le catalogue (onglet « Accueil », position 1
/// de la bottom-nav, AM-1). Le HUB agrege l'etat du trek et les points d'entree
/// vers les fonctions du sentier, organises en sections (Preparer / Randonner /
/// Informations / Apres le trek).
///
/// Perimetre LOT-A (arbitrage #94902) :
///   * D1 — mode demo MASQUE : aucun bandeau demo ni trek demo ([HubHeader],
///     [HubTrekCard]) ;
///   * D2 — cartes « Preparer » SIMPLES : pas d'indicateur de statut ni appui
///     long ([QuickAccessCard]) ;
///   * D3 — tuile meteo : RETIREE du cockpit (R2e, LOT L8) — la meteo ne vit
///     plus qu'en rando (section Randonner, [LocalizedConditionsBanner]) ;
///   * D4 — aucune section Communaute/social ;
///   * D5 — cartes sans ecran cible (Ravitaillement / Transport / Recap)
///     DIFFEREES.
///
/// Regle S8 « zero route morte » : seules les cartes dont la cible existe
/// (routes R01..R13 + `/training`) sont rendues. Tous les libelles passent par
/// Slang (`t.hub.*`, `t.nav.*`) — zero texte en dur, aucun libelle propre a un
/// sentier particulier (cloisonnement moteur generique).
///
/// UNE SEULE EXCEPTION A S8, ARBITREE PAR CHRIS (retour #13, tache 553) : la
/// carte « Guides des villes » est MASQUEE alors que sa route vit toujours. S8
/// interdit une carte sans cible, pas une cible sans carte : c'est Chris qui
/// decide de ce qu'il montre. Rien n'est supprime (routes, ecrans et tests de la
/// feature guides restent en place), la carte est juste retiree du cockpit.
///
/// ACCUEIL TERRAIN (StepWays refonte nav — hub-and-push PUR, parité GR20 modèle A)
/// : c'est le cockpit « terrain » (`/home`, rando active). Il CONSERVE son
/// `AppBar` (accès Informations / Profil / Mes treks / Réglages, retours Chris) et
/// présente TOUTES ses sections dans UN seul scroll (parité GR20 `HomeScreen`),
/// visibles SELON LA PHASE dérivée du cycle de vie du trek :
///   * **Préparer** : ABSENTE pendant la marche (tâche 809, « préparer devrait
///     disparaître quand tu es en cours de trek »), présente avant et après, en
///     ACCORDÉON (dépliée en préparation, repliée une fois rentré — D3, R8) ;
///   * **Randonner** : uniquement en rando active (phase hike) ;
///   * **Informations** : toujours présente ;
///   * **Après le trek** : uniquement une fois terminé (phase after).
///
/// Hors sections, une seule carte vit SEULE dans le scroll : le **Journal**
/// (retour Chris #11, tache 553). Elle est posée juste sous la carte du trek,
/// sans aucune garde de phase — donc au MÊME endroit en préparation, en rando et
/// après. Avant, elle changeait de section selon la phase (« Randonner » en
/// rando, « Informations » sinon) : une porte qui déménage est une porte qu'on ne
/// retrouve pas.
///
/// PAS DE BOTTOM BAR (D1, parité GR20 pure) : le cockpit n'a plus de barre du bas
/// contextuelle (l'ancien raccourci de défilement Préparer/Randonner/Après, dernier
/// résidu du « cockpit par phases », est retiré). La navigation est hub-and-push :
/// on POUSSE les écrans depuis les cartes, on revient par la pile. Le seul élément
/// flottant est le FAB SOS (masqué hors trek).
class HubScreen extends ConsumerStatefulWidget {
  const HubScreen({super.key});

  @override
  ConsumerState<HubScreen> createState() => _HubScreenState();
}

// LA CHROME DU COCKPIT. Les trois blocs qui suivent portent, mot pour mot, les
// raisons des trois proprietes que `build()` pose encore elle-meme sur le
// Scaffold : `floatingActionButton`, `floatingActionButtonLocation` et
// `bottomNavigationBar`. Elles ne peuvent pas partir en sous-widget :
// `bottomNavigationBar` doit rester un [BannerAdSlot] LITTERAL (verrouille par
// `test/features/hub/hub_screen_test.dart`, qui lit `scaffold
// .bottomNavigationBar` et exige `isA<BannerAdSlot>()`), et la pastille SOS est
// deja le sous-widget [SosButton].
// FAB : SOS uniquement (si trek actif, gere par SosButton qui se masque
// lui-meme hors trek). RM-3. Le FAB « Donner mon avis » (feedback) a ete
// retire du hub (jamais decide, retour Chris LOT 3).
//
// ACCES SOS UNIQUE (FIX-2, finding M1) : c'est le SEUL acces SOS du
// cockpit — il n'y a NI action SOS en barre contextuelle (la barre du
// cockpit n'existe pas, D1) NI carte SOS dans le scroll. Sur la carte,
// l'unique acces est l'overlay [SosButton] du Stack ; depuis le correctif
// L6-3 la carte n'a PLUS DU TOUT de barre du bas, donc plus aucun endroit
// ou un second SOS pourrait reapparaitre.
// Verrouille par `test/features/safety/sos_acces_unique_test.dart`.
// PARITE GR20 (`home_screen.dart` : FloatingActionButtonLocation
// .startFloat) + fix d'un vrai defaut d'acces : au coin BAS-DROIT par
// defaut, la pastille SOS se posait SUR le bouton pleine largeur
// « Terminer le trek » en fin de scroll et en masquait la fin (constate
// sur la capture S3_Steve_11_apres_terminer du round 1). Bas-GAUCHE :
// plus aucun recouvrement, et le SOS se trouve au MEME endroit que sur la
// carte -> une seule position a memoriser pour un geste d'urgence.
// --- LA BANNIERE PUBLICITAIRE (tache 595, B1) ---
//
// ICI, PARCE QUE C'EST LE MOMENT DE LA PREPARATION. Le modele economique
// dit « gratuit = consultation + demo bridee, AVEC pub » : le cockpit est
// l'ecran ou un randonneur qui n'a pas encore achete passe son temps. La
// banniere est indexee sur le trek courant — « trek achete = sans pub sur
// CE trek » — et l'abonnement comme la recompense de 24 h la coupent
// partout, par la meme source unique (#99404). Aucune regle n'est
// recalculee ici.
//
// PAS EN PHASE RANDO, ET CE QUE CETTE LIGNE TIENT EST LA GEOMETRIE — PAS
// UNE REGLE DE PUBLICITE.
//
// En phase rando, le bas de l'ecran appartient a la pastille SOS
// ([SosButton] se masque lui-meme hors trek). On n'y pose pas un
// emplacement publicitaire, meme un emplacement qui ne demandera rien : un
// doigt qui vise le secours ne doit jamais rencontrer une regie. Le SOS ne
// porte AUCUNE publicite, nulle part (test B5).
//
// ET IL N'Y A PLUS DE REGLE « EN MODE TREK JAMAIS » A HERITER. Elle a
// existe une demi-journee dans la decision publicitaire, et Chris l'a
// retiree le 27/09 14:41, verbatim : « TOUT PORTER LA PUB sauf si tu es
// abonne ou sur le trek que tu as achete .. Pas la peine de mettre plus de
// regles ». Deux exceptions, plus la recompense de 24 h du modele du 08/09.
// Ce cockpit-ci n'affiche de toute facon pas d'emplacement en rando, pour
// la raison de geometrie ci-dessus — mais ailleurs, un randonneur qui
// marche un sentier GRATUIT verra de la publicite, et c'est assume : voir
// `shouldShowBannerProvider`, qui porte la raison en entier.
// OUVRIR UN SENTIER, C EST DEMANDER CE QUI A CHANGE DESSUS (tache 641).
//
// « Je veux que l'application vienne mettre a jour ses donnees a cette
// source » (Christophe, 30/09 11:54). Cet ecran est la porte d'entree du
// sentier : les rubriques qu'il ouvre — transport, ravitaillement, nuitees,
// etapes — sont precisement celles que Christophe a trouvees vides. La mise
// a jour part ICI, en arriere-plan, sans rien faire attendre : la copie
// locale est deja affichee, la base la complete quand elle repond.
class _HubScreenState extends ConsumerState<HubScreen> {
  // Retour Chris #13 (LOT 2) : le menu du cockpit est CONTEXTUEL a l'etat du
  // trek (DECISIONS.md §5.2, accueil « maison »/« terrain »). Regle :
  //   * Informations : TOUJOURS visible ;
  //   * Préparer : visible AVANT et APRES, ABSENTE en rando (tache 809) ;
  //   * Randonner : visible UNIQUEMENT en rando active (phase hike) ;
  //   * Après le trek : visible UNIQUEMENT une fois le trek termine (phase
  //     after).
  // Tant qu'on n'est pas en rando, ni « Randonner » ni « Après-trek » ne
  // s'affichent (retour Chris #13, « on en a deja parle »).
  //
  // CET ECRAN NE CALCULE PLUS LA PHASE, IL LA LIT (tache 809). Il la derivait
  // lui-meme, et deux widgets en faisaient autant de leur cote : trois lectures
  // du meme fait, qui ne tombaient pas d'accord en demonstration. La phase est
  // desormais [cockpitPhaseProvider], source unique et seule porte publique.

  @override
  void initState() {
    super.initState();
    observeScreenEntry(ref, ScreenBreadcrumb.hub);
  }

  @override
  Widget build(BuildContext context) {
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    ref.watch(miseAJourAlOuvertureProvider(trailId));

    final phase = ref.watch(cockpitPhaseProvider);
    final showHike = phase == CockpitPhase.hike;
    final showAfter = phase == CockpitPhase.after;

    // LA BANDE QUE LA PASTILLE SOS RECOUVRE, MESUREE SUR LE BOUTON RENDU
    // (tache 836). Un `floatingActionButton` FLOTTE : il est peint par-dessus
    // le `body` et ne retire rien a la place que le `body` croit avoir. Le
    // sous-titre de « Adapter l'itineraire », le bouton « Terminer le trek » et
    // le titre « Informations » finissaient donc SOUS le disque rouge. La
    // reserve vaut 0 quand le bouton est masque, et le cockpit retrouve alors
    // exactement son padding d'avant. Voir `reserve_sous_le_sos.dart` pour la
    // raison de ne PAS deplacer le bouton.
    final reserveDuSos = ref.watch(reserveSousLeSosProvider);

    return Scaffold(
      appBar: HubAppBar(
        trailTitle: trailTitle,
        onInfoTap: () => _showInfoSheet(context, trailTitle),
      ),
      floatingActionButton: const SosQuiReserveSaPlace(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      bottomNavigationBar: showHike ? null : BannerAdSlot(trailId: trailId),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingBase,
            AppTheme.spacingBase,
            AppTheme.spacingBase,
            AppTheme.spacingBase + reserveDuSos,
          ),
          children: [
            HubCockpitTop(trailId: trailId),
            // --- « PRÉPARER » DISPARAIT PENDANT LA MARCHE (tache 809) ---
            //
            // Christophe, 10/10, verbatim : « meme en mode demo preparer
            // devrait disparaitre quand tu es en cours de trek ».
            //
            // ELLE ETAIT REPLIEE, PAS ABSENTE, et c'etait l'arbitrage R13 :
            // « jamais masquee, juste repliee — le randonneur la deplie d'un
            // tap pour revoir un point ». Christophe a tranche l'inverse apres
            // l'avoir vue sur le telephone : en pleine marche, les douze cartes
            // de la preparation n'ont plus rien a preparer, et leur en-tete
            // mange le haut du cockpit au moment ou tout ce qui compte est la
            // trace. Son mot est « disparaitre », pas « replier ».
            //
            // ELLE REVIENT APRES L'ARRIVEE, ET CE N'EST PAS UNE DEMI-MESURE.
            // Christophe n'a parle que du « en cours de trek », et la garder en
            // phase « apres » est le choix PRUDENT pour une raison mesurable :
            // la section « Randonner » n'existe plus a ce moment-la, et c'est
            // elle qui porte la porte vers l'urgence. La fiche medicale
            // (`/health`) n'a plus alors que CETTE section pour porte dans tout
            // le cockpit — la retirer ici l'enfermerait. Repliee, donc
            // discrete, mais atteignable.
            // SON ESPACEMENT PART AVEC ELLE. Un blanc de la taille d'une
            // section absente est le defaut que la porte d'achat documente
            // deja quelques lignes plus bas : ce qui s'efface doit emporter
            // la place qu'il occupait.
            if (!showHike) ...[
              HubPrepareSection(
                trailId: trailId,
                initiallyExpanded: !showAfter,
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
            if (showHike) ...[
              LocalizedConditionsBanner(trailId: trailId),
              const SizedBox(height: AppTheme.spacingBase),
              HubHikeSection(trailId: trailId),
              const SizedBox(height: AppTheme.spacingLg),
            ],
            if (showAfter) ...[
              QuickAccessCard(
                rubrique: RubriqueStepways.journal,
                title: t.hub.cards.journal,
                subtitle: t.hub.cards.journalSub,
                onTap: () => context.push('/journal'),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],
            HubInfoSection(trailId: trailId),
            const SizedBox(height: AppTheme.spacingLg),
            HubCockpitFooter(
              trailId: trailId,
              // LE DEPART N'EXISTE QU'AVANT, ET NE REVIENT PAS (tache 809).
              // Christophe : « demarrer la randonne, le bouton aparait encore
              // une fois la randonnee finie au lieu d acceder a la post
              // rando ».
              // La condition n'a pas change de forme — c'est sa SOURCE qui est
              // devenue juste, y compris en demonstration.
              showStartButton: phase == CockpitPhase.prepare,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom-sheet d'aide (action (i) de l'AppBar, RF-1).
  ///
  /// Contenu editorial minimal (le detail par sentier sera enrichi par Lia).
  void _showInfoSheet(BuildContext context, String trailTitle) {
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(trailTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            Text(t.hub.infoSheetBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}
