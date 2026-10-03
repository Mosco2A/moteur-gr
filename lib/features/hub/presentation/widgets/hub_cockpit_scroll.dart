/// Le haut et le bas du scroll du cockpit, en deux sous-widgets nommes : ce
/// qu'on lit des l'ouverture, et les boutons de fin de scroll.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/demo_simulation_button.dart';
import '../../../ads/presentation/ad_state_badge.dart';
import 'finish_trek_button.dart';
import 'hub_buy_trek_button.dart';
import 'hub_start_trek_button.dart';
import 'hub_trek_card.dart';
import 'hub_wallet_card.dart';

/// La tete du cockpit : la marque de l'etat publicitaire, le compte-etapes, la
/// carte du trek et la porte d'achat — ce qu'on lit des l'ouverture.
class HubCockpitTop extends StatelessWidget {
  const HubCockpitTop({required this.trailId, super.key});

  /// L'identifiant du sentier courant, pose dans la porte d'achat.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HubAdStateMark(),
        _HubTrekBlock(trailId: trailId),

        // --- LE JOURNAL N'EXISTE PAS EN PHASE PREPARATION (tache 558) ---
        //
        // Decision de Chris, mot pour mot : « MAIS JOURNAL CE N'est JUSTE
        // PAS DU TOUT EN PHASE PREPARER. En rando pour le rempli, en
        // postrando pour le remplir et le lire ». La carte etait ICI, en
        // tete du cockpit, AU-DESSUS de « Preparer ».
        //
        // DEUX ERREURS EMPILEES, corrigees ensemble. La premiere : montrer
        // le journal en PREPARATION, ou un carnet de randonnee n'a rien a
        // dire — il est vide, et il le restera jusqu'au depart. La seconde,
        // qui aggravait la premiere : le poser tout en haut, donc avant la
        // preparation, qui est le seul travail du moment. « Atteignable
        // dans les trois phases » n'etait pas une vertu en soi.
        //
        // CE QUE DEVIENT L'ACCES REPARE EN R10 / LOT L10 : son intention
        // reste tenue — le journal n'est jamais inatteignable alors que la
        // fonction est entiere — mais le vrai trou de R10 etait
        // l'APRES-TREK, pas la preparation. Le journal vit donc la ou on
        // l'ECRIT et la ou on le RELIT : dans la section « Randonner »
        // pendant la rando (place de la reference), et en carte autonome
        // apres le trek, la ou cette section n'existe plus. UNE SEULE carte
        // a l'ecran a tout instant : les deux emplacements s'excluent par
        // construction (`showHike` et `showAfter` ne sont jamais vrais
        // ensemble).
      ],
    );
  }
}

/// La marque de l'etat publicitaire de la preparation, en une ligne.
class _HubAdStateMark extends StatelessWidget {
  const _HubAdStateMark();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // L'ETAT PUBLICITAIRE DE LA PREPARATION, EN UNE LIGNE
        // (tache 639 avenant, DEM-260930-1241).
        //
        // Verbatim de Christophe (30/09 12:41) : « Il faut que l on fasse la
        // diff entre = je suis abonne et je n ai pas de pub en prepa, j ai
        // achete un trek sans pub, je suis en prepa avec pub ». Les trois
        // etats doivent se distinguer « sur la carte du sentier ET EN
        // PREPARATION » : la carte du catalogue porte sa marque, voici celle
        // de la preparation.
        //
        // POURQUOI ICI ET PAS SUR L'EMPLACEMENT PUBLICITAIRE : deux des trois
        // etats (abonne, achete) sont precisement ceux ou aucune banniere ne
        // s'affiche, et [BannerAdSlot] doit garder sa hauteur NULLE quand il
        // n'y a pas de publicite — un abonne ne paie rien, pas meme en
        // pixels. La marque parle de l'etat des DROITS, l'emplacement parle
        // de ce que la regie a rendu : deux choses, deux endroits.
        const AdStateBanner(),
        const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }
}

/// Le compte-etapes, la carte du trek et la porte d'achat du cockpit.
class _HubTrekBlock extends StatelessWidget {
  const _HubTrekBlock({required this.trailId});

  /// L'identifiant du sentier courant, pose dans la porte d'achat.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // LOT 1 (retour Chris #2) : le bandeau de salutation « Bonjour,
        // randonneur » + nom du sentier (HubHeader) a ete RETIRE : il faisait
        // DOUBLON avec le titre du sentier deja affiche dans l'AppBar juste
        // au-dessus.
        //
        // R2e (retour Chris, LOT L8) — AUCUNE MÉTÉO EN PRÉPARATION. La tuile
        // météo du jour ([HubWeatherCard]) qui ouvrait ce cockpit a été
        // RETIRÉE : elle s'affichait AVANT tout le reste, donc pendant la
        // PRÉPARATION, où la météo n'a aucun sens (on prépare un trek des
        // mois à l'avance, les prévisions ne portent que sur 7 jours). Elle
        // était en plus indexée sur l'étape de RÉFÉRENCE (D-3, étape 1 par
        // défaut), pas sur l'étape réellement parcourue.
        // PARITÉ GR20 : le HUB GR20 n'a aucune météo dans « Préparer » — la
        // météo vit en TERRAIN, dans la section « Randonner ». La météo est
        // donc déplacée telle quelle dans la section Randonner ci-dessous
        // ([LocalizedConditionsBanner], R11), qui n'est rendue qu'en rando
        // active. Le widget [HubWeatherCard] et son écran cible restent en
        // place (route `/trail/:id/weather` toujours vivante, atteinte par le
        // bandeau et la carte « Météo » de la section Randonner).
        // Carte principale trek (RF-4), enrichie du cycle de vie multi-trek
        // (StepWays LOT 2, Phase 5) : elle porte desormais elle-meme le CTA
        // « Démarrer » (owned/prepared, via la garde d'unicite C4), la carte
        // active (inProgress) ou « Revoir/Diplôme » (completed). L'ancien CTA
        // « Démarrer » plein largeur au niveau de l'ecran (qui poussait vers
        // la planification) est retire : la carte est la source unique du
        // demarrage, garde C4 comprise (plus de double bouton).
        // COMPTE-ÉTAPES en tête du cockpit (correctif L7-1). Le
        // portefeuille existait en entier — table, DAO, recharge, débit —
        // mais son solde n'apparaissait sur AUCUN écran. Il se rend juste
        // au-dessus de la carte du trek, et reste invisible tant que le
        // solde n'est pas connu (jamais de « 0 » de chargement).
        const HubWalletCard(),
        const SizedBox(height: AppTheme.spacingBase),

        const HubTrekCard(),
        const SizedBox(height: AppTheme.spacingBase),

        // ACHETER DEPUIS LA PREPARATION (tache 614) — le deuxieme des trois
        // points d'entree de l'achat, demande de Christophe du 28/09 11:41.
        //
        // ICI, ET PAS EN BAS AVEC « Démarrer ». Le randonneur qui prepare
        // depuis trois semaines et se decide un soir ne doit pas avoir a
        // scroller tout le cockpit, ni a finir sa preparation, pour trouver
        // comment payer : le bouton de depart est GRISE tant que les trois
        // cartes coeur ne sont pas faites, il ne pouvait donc rien vendre a
        // celui-la. Ce bouton-ci se lit des l'ouverture, juste sous la carte
        // du trek, et il s'efface de lui-meme des que le sentier est acquis.
        HubBuyTrekButton(trailId: trailId),
        const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }
}

/// Les boutons de fin de scroll du cockpit : le depart, la simulation de la
/// demo et la fin manuelle du trek.
///
/// Chacun se masque lui-meme quand il n'a pas lieu d'etre ; seule la garde de
/// phase du depart vient du parent, par [showStartButton].
class HubCockpitFooter extends StatelessWidget {
  const HubCockpitFooter({
    required this.trailId,
    required this.showStartButton,
    super.key,
  });

  /// L'identifiant du sentier courant.
  final String trailId;

  /// Vrai en preparation seulement (ni rando active, ni trek termine).
  final bool showStartButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // --- Section Apres le trek : RETIREE (CORRECTIF L5-8) ---
        //
        // Elle exposait « Mon aventure » et « Diplome » alors que la carte
        // de trek termine, juste au-dessus, portait DEJA les deux memes
        // commandes vers les deux memes destinations, memes libelles, sur
        // le meme ecran en meme temps : quatre commandes pour deux
        // destinations. Cette duplication est une invention de StepWays,
        // le cockpit de reference n'en a aucune.
        //
        // ZERO ROUTE MORTE (regle S8) : les deux routes existent toujours
        // et restent atteignables. « Mon aventure » est la porte unique
        // (carte de trek termine) et ouvre le diplome, le journal, le
        // partage et l'export GPX. La carte Journal, elle, n'a jamais
        // appartenu a ce bloc : elle vit dans « Informations » et reste
        // rendue dans les trois phases.

        // --- « Démarrer la randonnée » (retour Chris #3, LOT 2) ---
        // Le bouton de demarrage est ICI, EN BAS du cockpit (apres les
        // cartes de preparation), et non plus en haut (il etait porte par la
        // [HubTrekCard], toujours actif). Il est GRISE tant que les infos
        // minimum ne sont pas saisies (Itineraire + Date + Programme, gate
        // [prepareCoreDoneProvider]) avec un message d'aide. Ne s'affiche
        // QU'en phase de preparation (owned/prepared) : une fois parti ou
        // termine, il n'a plus lieu d'etre (la carte active / le recap
        // prennent le relais). Reutilise la garde d'unicite C4 + le filet de
        // proximite GPS (jamais de cul-de-sac).
        if (showStartButton) HubStartTrekButton(trailId: trailId),

        // --- LA SIMULATION DE LA DEMO VIT ICI (tache 638, bugs 11 et 16) ---
        // Le lot 634 la portait dans un bandeau pose EN BAS DE TOUS LES
        // ECRANS, qui masquait le bas de chacun — c'est le defaut du bug 11
        // (DEM-260930-1020 : « le bandeau du bas du mode demo cache une
        // partie de l appli »). Elle est desormais un bouton, dans le
        // cockpit, invisible hors demo et invisible tant que la randonnee
        // simulee n'est pas partie.
        const DemoSimulationButton(),

        // --- « Terminer le trek » (Finitions V1, point 3) ---
        // Bouton ORANGE en FIN DE SCROLL (décision Chris), symétrique du
        // « Démarrer » porté par la HubTrekCard. Ne s'affiche QUE si un trek
        // est en cours (le widget se masque lui-même sinon). Rétablit une fin
        // MANUELLE atteignable — l'app ne dépend plus uniquement de la
        // détection GPS d'arrivée pour terminer un trek.
        const FinishTrekButton(),
      ],
    );
  }
}
