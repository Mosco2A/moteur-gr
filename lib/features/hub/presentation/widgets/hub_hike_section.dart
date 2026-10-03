/// La section « Randonner » du cockpit : les outils du terrain.
library;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../i18n/translations.g.dart';
import 'hub_section.dart';
import 'quick_access_card.dart';

/// La section « Randonner » du cockpit.
///
/// Le parent ne la rend qu'en rando active : la garde de phase reste chez lui.
/// Les cartes restent litterales — [HubSection] exige une
/// `List<QuickAccessCard>`.
class HubHikeSection extends StatelessWidget {
  const HubHikeSection({required this.trailId, super.key});

  /// L'identifiant du sentier courant, pose dans chaque route ouverte.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return HubSection(
      title: t.hub.sections.hike,
      icon: StepwaysIcons.chaussure,
      cards: [
        ..._cartesDeLaNavigation(context),
        ..._cartesDuCarnet(context),
        ..._cartesDeLaMeteo(context),
        ..._cartesDuRisque(context),
      ],
    );
  }

  /// La navigation et l'urgence : les deux gestes du terrain.
  List<QuickAccessCard> _cartesDeLaNavigation(BuildContext context) => [
    QuickAccessCard(
      rubrique: RubriqueStepways.carte,
      title: t.hub.cards.navigation,
      subtitle: t.hub.cards.navigationSub,
      // Ph4 (hub-and-push, SPEC §5) : push (pas go) pour PRESERVER la
      // pile -> retour propre vers le cockpit. go() ecrasait la pile
      // (heritage shell/onglets, supprime).
      onTap: () => context.push('/map'),
    ),
    // URGENCE — PORTE D'ENTREE CREEE (tache 568, LOT Q, Q4a).
    //
    // LE DEFAUT LE PLUS GRAVE DU LOT : l'ecran des contacts
    // d'urgence (112, secours regionaux du sentier, contacts
    // personnels, position GPS a lire aux secours) etait ECRIT,
    // ROUTE (`/emergency`), EXCLU DU GUARD pour rester atteignable
    // sans sentier... et sans AUCUNE porte : zero `push` et zero
    // `go` vers `/emergency` dans tout `lib/`. La fonction entiere
    // etait inatteignable, et elle emportait la fiche medicale
    // avec elle (seule porte vers `/health`).
    //
    // PLACE RETENUE : section « Randonner », donc VISIBLE
    // UNIQUEMENT EN RANDO ACTIVE. Cela respecte la decision du
    // 02/09 (#99410) : la securite est NATIVE AU TERRAIN. La
    // PREPARATION de cette securite (la fiche medicale) est, elle,
    // native a la preparation — c'est pourquoi les deux portes ne
    // sont pas dans la meme section.
    //
    // ICONE DISTINCTE DU SOS, VOLONTAIREMENT : la pastille
    // flottante [SosButton] (`Icons.emergency`) declenche l'APPEL
    // direct du 112 ; cette carte ouvre l'ECRAN des contacts. Deux
    // gestes differents, deux icones differentes — sans quoi on
    // recreerait le soupcon de « double acces SOS » qui a coute
    // une campagne QA (faux positif M1, #100175).
    QuickAccessCard(
      icon: StepwaysIcons.secours,
      title: t.hub.cards.emergency,
      subtitle: t.hub.cards.emergencySub,
      onTap: () => context.push('/emergency'),
    ),
  ];

  /// Le signalement et le journal : ce que le randonneur ecrit du sentier.
  List<QuickAccessCard> _cartesDuCarnet(BuildContext context) => [
    // SIGNALEMENT TERRAIN — LA TROISIEME FONCTION QUE PERSONNE NE
    // POUVAIT ATTEINDRE (tache 582, LOT Z).
    //
    // Le LOT Q (tache 568) a donne leur porte aux contacts
    // d'urgence et a la fiche medicale. `/signalement` est reste
    // en arriere : route declaree (F6C-03), ecran ecrit, traduit
    // en cinq langues, table locale et file de synchronisation
    // completes — et ZERO `push` vers lui dans tout `lib/`. Il
    // n'avait pas perdu sa porte comme les guides des villes
    // (masques sur decision de Chris) ou le groupe (parke) : il
    // n'en avait JAMAIS EU. C'est LE CURIEUX qui l'a dit, et
    // c'etait le dernier de ses trois reproches encore debout.
    //
    // PLACE RETENUE : « Randonner », a cote de l'urgence, donc
    // visible uniquement en rando active. Signaler un obstacle,
    // un point d'eau a sec ou un danger est un geste de TERRAIN —
    // on ne signale pas ce qu'on n'a pas encore vu. Meme
    // raisonnement que la decision du 02/09 (#99410) qui a mis la
    // securite au terrain et sa PREPARATION a la preparation.
    QuickAccessCard(
      icon: StepwaysIcons.signaler,
      title: t.hub.cards.signalement,
      subtitle: t.hub.cards.signalementSub,
      onTap: () => context.push('/signalement'),
    ),
    // JOURNAL — ICI PENDANT LA RANDO (tache 558, decision Chris
    // « En rando pour le rempli »). C'est la place de la
    // reference, et c'est un outil de TERRAIN : on ecrit son
    // carnet le soir a l'etape, pas des mois avant le depart.
    // Cette section n'est rendue qu'en rando active, donc la
    // carte disparait d'elle-meme en preparation — aucune garde
    // supplementaire n'est necessaire ici.
    QuickAccessCard(
      rubrique: RubriqueStepways.journal,
      title: t.hub.cards.journal,
      subtitle: t.hub.cards.journalSub,
      onTap: () => context.push('/journal'),
    ),
  ];

  /// L'adaptation de l'itineraire et la meteo par etape.
  List<QuickAccessCard> _cartesDeLaMeteo(BuildContext context) => [
    // R11 (retour Chris, LOT L8) — MÉTÉO : carte « Prévisions par
    // étape » -> écran météo E31 (`/trail/:id/weather`). PARITÉ
    // GR20 : le HUB GR20 expose « Météo » et « Incendie » COTE A
    // COTE dans sa section « Randonner » (jamais dans
    // « Préparer »). Le bandeau ci-dessus donne le jour J localisé ;
    // cette carte ouvre le détail étape par étape. Route hors-shell
    // atteinte via `context.push` (retour propre, pile préservée —
    // jamais context.go qui viderait la pile). Libellés Slang
    // existants (`t.hub.cards.weather`/`weatherSub`, 5 langues).
    // R12 (retour Chris, LOT L9) — ADAPTER L'ITINERAIRE. La rando
    // ne se passe jamais comme prevu : le randonneur doit pouvoir
    // MODIFIER la repartition de ses jours et de ses etapes sans
    // sortir de la phase terrain. Place GR20 : ce geste y est
    // offert depuis l'ecran de l'etape en cours (bouton « Adapter
    // itineraire », icone `edit_road`) — on garde l'icone et le
    // vocabulaire, en le posant sur la carte de la section
    // Randonner (qui n'existe qu'en rando active, R8/#13). La
    // regle metier est portee par l'ecran cible : seuls les jours
    // et etapes NON FAITS sont modifiables, et l'ordre des etapes
    // ne s'inverse jamais. Route hors-shell via `context.push`
    // (retour propre, pile preservee).
    QuickAccessCard(
      icon: StepwaysIcons.filtres,
      title: t.hub.cards.adjust,
      subtitle: t.hub.cards.adjustSub,
      onTap: () => context.push('/trail/$trailId/adjust'),
    ),
    QuickAccessCard(
      rubrique: RubriqueStepways.meteo,
      title: t.hub.cards.weather,
      subtitle: t.hub.cards.weatherSub,
      onTap: () => context.push('/trail/$trailId/weather'),
    ),
  ];

  /// Le risque incendie du sentier.
  List<QuickAccessCard> _cartesDuRisque(BuildContext context) => [
    // PARITE GR20 (#99460) — INCENDIE : carte « Risques & alertes »
    // (clone GR20 `FireRiskScreen`, data-driven). Niveaux de risque
    // (0-5) derives de la meteo (socle meteo reutilise + calcul
    // identique GR20), reglementation + secours regionaux venant de
    // la donnee du sentier (aucune localite en dur). Icone
    // `local_fire_department` (rouge urgence, parite GR20). Route
    // hors-shell atteinte via `context.push` (retour propre, pile
    // preservee — jamais context.go qui viderait la pile). Generique
    // multi-sentiers, fallback si aucune donnee meteo.
    QuickAccessCard(
      rubrique: RubriqueStepways.incendie,
      title: t.hub.cards.fire,
      subtitle: t.hub.cards.fireSub,
      onTap: () => context.push('/trail/$trailId/fire-risk'),
    ),
  ];
}
