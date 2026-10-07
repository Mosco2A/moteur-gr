/// La section « Preparer » du cockpit et ses douze cartes d'acces.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/quick_access_card.dart';
import '../../../../shared/widgets/step_status_icon.dart';
import '../../providers/prepare_progress_providers.dart';
import 'collapsible_prepare_section.dart';

/// La section « Preparer » du cockpit.
///
/// POURQUOI LES CARTES NE SONT PAS, ELLES, DES SOUS-WIDGETS. La signature
/// publique de [CollapsiblePrepareSection] exige une `List<QuickAccessCard>` :
/// envelopper une carte dans un widget a elle la changerait en `Widget` et
/// casserait cette signature, ce que le lot interdit. Les cartes restent donc
/// litterales, groupees par moment de la preparation.
///
/// LA COCHE DE CHAQUE CARTE (lot coche de preparation, 07/10). Chaque carte
/// recoit son statut de [statutDePreparationProvider], calcule depuis ce qui
/// est DEJA persiste. Neuf cartes portent une coche ; Transport,
/// Ravitaillement et Resume n'en portent pas, parce que rien de ce que le
/// randonneur y fait n'est enregistre — et qu'une coche qui ment est pire
/// qu'aucune coche.
class HubPrepareSection extends ConsumerWidget {
  const HubPrepareSection({
    required this.trailId,
    required this.initiallyExpanded,
    super.key,
  });

  /// L'identifiant du sentier courant, pose dans chaque route ouverte.
  final String trailId;

  /// L'accordeon s'ouvre en preparation, se replie une fois parti ou rentre.
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return // --- Section Preparer (RF-6) — ACCORDÉON (D3, R8+R13) ---
    // Parité GR20 modèle A : Préparer reste TOUJOURS présente dans le
    // scroll, mais REPLIÉE une fois parti (phase hike) ou rentré (after)
    // pour dégager le cockpit ; DÉPLIÉE en préparation (le cœur du moment).
    // Jamais masquée : le randonneur la déplie d'un tap pour revoir un
    // point (R13). L'état initial suit la phase (déplié si !hike && !after).
    CollapsiblePrepareSection(
      initiallyExpanded: initiallyExpanded,
      cards: [
        ..._cartesDuProjet(context, ref),
        ..._cartesDuCorps(context, ref),
        ..._cartesDuCouchage(context, ref),
        ..._cartesDeLaLogistique(context, ref),
        ..._packCards(context, ref),
      ],
    );
  }

  /// La coche d'un sujet pour le sentier courant ; `null` = pas de coche.
  PlanningStepStatus? _coche(WidgetRef ref, SujetDePreparation sujet) =>
      ref.watch(statutDePreparationProvider((trailId: trailId, sujet: sujet)));

  /// Le projet de trek : ce qu'on decide d'abord — faisabilite, itineraire,
  /// programme, dates.
  List<QuickAccessCard> _cartesDuProjet(BuildContext context, WidgetRef ref) =>
      [
        QuickAccessCard(
          rubrique: RubriqueStepways.faisabilite,
          title: t.hub.cards.feasibility,
          subtitle: t.hub.cards.feasibilitySub,
          stepStatus: _coche(ref, SujetDePreparation.faisabilite),
          onTap: () => context.push('/trail/$trailId/feasibility'),
        ),
        QuickAccessCard(
          rubrique: RubriqueStepways.itineraire,
          title: t.hub.cards.itinerary,
          subtitle: t.hub.cards.itinerarySub,
          stepStatus: _coche(ref, SujetDePreparation.itineraire),
          // PARITE GR20 (#99433) + fix crash retour : « Itineraire »
          // ouvre desormais l'ecran deroule des etapes (route hors-shell
          // via push) au lieu de context.go('/map') qui remplacait la
          // pile (bascule d'onglet) et plantait au retour
          // (currentConfiguration.isNotEmpty).
          onTap: () => context.push('/trail/$trailId/itinerary'),
        ),
        QuickAccessCard(
          rubrique: RubriqueStepways.programme,
          title: t.hub.cards.programme,
          subtitle: t.hub.cards.programmeSub,
          stepStatus: _coche(ref, SujetDePreparation.programme),
          onTap: () => context.push('/trail/$trailId/planning'),
        ),
        // PARITE GR20 (#99460) — CALENDRIER : outil de DATES (depart +
        // arrivee calculee, calendrier visuel des jours de marche/repos
        // du programme). Icone `calendar_month`, sous-titre « Choisir
        // les dates » (parite GR20). Route hors-shell atteinte via
        // `context.push` -> retour propre (jamais context.go qui viderait
        // la pile).
        QuickAccessCard(
          rubrique: RubriqueStepways.calendrier,
          title: t.hub.cards.calendar,
          subtitle: t.hub.cards.calendarSub,
          stepStatus: _coche(ref, SujetDePreparation.calendrier),
          onTap: () => context.push('/trail/$trailId/calendar'),
        ),
      ];

  /// Ce qui concerne le corps du randonneur : entrainement et fiche medicale.
  List<QuickAccessCard> _cartesDuCorps(BuildContext context, WidgetRef ref) => [
    // RETOUR CHRIS #6 (tache 553) — « preparation physique doit
    // aller en dessous de calendrier ». La carte « Preparation
    // physique » fermait la section : c'etait la DERNIERE des dix
    // cartes de prepa, alors qu'elle se decide avec les DATES (on
    // s'entraine N semaines avant le depart, donc on la lit juste
    // apres avoir pose le calendrier). Elle est donc ICI, juste
    // sous « Calendrier », et plus en fin de liste.
    QuickAccessCard(
      rubrique: RubriqueStepways.preparationPhysique,
      title: t.hub.cards.training,
      subtitle: t.hub.cards.trainingSub,
      stepStatus: _coche(ref, SujetDePreparation.preparationPhysique),
      onTap: () => context.push('/training'),
    ),
    // FICHE MEDICALE — PORTE D'ENTREE CREEE (tache 568, LOT Q, Q4b).
    //
    // CE QU'IL Y AVAIT AVANT : la fiche medicale (`/health`) n'etait
    // atteignable QUE depuis l'ecran d'urgence — lui-meme sans
    // aucune porte d'entree dans tout `lib/` (zero push/go vers
    // `/emergency`). Une fonction entiere derriere une fonction
    // fermee : personne ne pouvait remplir sa fiche.
    //
    // DECISION DE CHRIS DU 26/09 10:29, verbatim : « ca doit faire
    // partie de la prepa, on ne demarre pas un trek sans avoir
    // rempli sa fiche medicale et lu les conseils pour qu'elle soit
    // applicable sur le sentier ». Elle est donc ICI, dans
    // « Preparer » : GRATUITE (le SOS lui-meme reste au terrain
    // paye, decision #99410) et atteignable HORS RANDO — la section
    // Preparer est toujours presente, simplement repliee une fois
    // parti ou rentre. Elle est aussi devenue une CONDITION DE
    // DEMARRAGE (cf. `prepareCoreDoneProvider`) : la carte doit
    // exister avant qu'on puisse exiger qu'elle soit faite.
    //
    // Place juste apres « Preparation physique » : c'est le meme
    // moment de la prepa — ce qui concerne le corps du randonneur.
    QuickAccessCard(
      rubrique: RubriqueStepways.ficheMedicale,
      title: t.hub.cards.health,
      subtitle: t.hub.cards.healthSub,
      stepStatus: _coche(ref, SujetDePreparation.ficheMedicale),
      onTap: () => context.push('/health'),
    ),
  ];

  /// Les cartes hors ligne et le couchage : ce qu'on emporte et ou on dort.
  List<QuickAccessCard> _cartesDuCouchage(
    BuildContext context,
    WidgetRef ref,
  ) => [
    // CARTES HORS LIGNE — UN SEUL GESTE, TOUT LE CIRCUIT (tache 640).
    //
    // CETTE CARTE MENAIT A UNE FACADE. Elle ouvrait le magasin de
    // packs de la tache 568, qui proposait quatre demi-circuits et
    // ne telechargeait rien : sa source de fichiers levait a chaque
    // appel et son stockage ecrivait dans un dossier que la carte ne
    // lit pas. C'etait la seule porte atteignable, donc celle que
    // Christophe a poussee le 30/09 — d'ou « telecharger les cartes
    // plante » (bug 9) et « on ne propose pas de demi-Mare a Mare »
    // (bug 10).
    //
    // Elle mene desormais a l'unique telechargeur de cartes du
    // depot. Telecharger les cartes d'un circuit reste un geste de
    // PREPARATION (on part couvert), pas de terrain : c'est trop
    // tard une fois sans reseau.
    QuickAccessCard(
      icon: StepwaysIcons.horsLigne,
      title: t.hub.cards.cartes,
      subtitle: t.hub.cards.cartesSub,
      stepStatus: _coche(ref, SujetDePreparation.cartesHorsLigne),
      // La coche est relue au RETOUR : le disque ne previent personne.
      onTap: () async {
        await context.push('/trail/$trailId/cartes');
        if (context.mounted) {
          ref.invalidate(cartesSurLeTelephoneProvider(trailId));
        }
      },
    ),
    // PARITE GR20 (#99460) — NUITEES : assistant « Reserver vos
    // nuits » (type de nuitee + reserve par nuit du programme).
    // Route hors-shell atteinte via `context.push` -> retour propre
    // (pile preservee, jamais context.go qui viderait la pile).
    QuickAccessCard(
      rubrique: RubriqueStepways.nuitees,
      title: t.hub.cards.nuitees,
      subtitle: t.hub.cards.nuiteesSub,
      stepStatus: _coche(ref, SujetDePreparation.nuitees),
      // La coche est relue au RETOUR : la table ne previent personne.
      onTap: () async {
        await context.push('/trail/$trailId/nuitees');
        if (context.mounted) ref.invalidate(nuitsReserveesProvider(trailId));
      },
    ),
  ];

  /// La logistique du sentier : transport, ravitaillement, synthese du plan.
  List<QuickAccessCard> _cartesDeLaLogistique(
    BuildContext context,
    WidgetRef ref,
  ) => [
    // PARITE GR20 (#99460) — TRANSPORT : carte « Aller & retour »
    // (clone GR20 `TransportScreen`, data-driven). Deux onglets
    // aller/retour, endpoints resolus depuis les donnees du sentier
    // (direction-aware), contenu venant du catalogue transport du
    // sentier. Route hors-shell atteinte via `context.push` (retour
    // propre, pile preservee — jamais context.go qui viderait la
    // pile). Generique multi-sentiers, zero hardcode de localite.
    QuickAccessCard(
      rubrique: RubriqueStepways.transport,
      title: t.hub.cards.transport,
      subtitle: t.hub.cards.transportSub,
      stepStatus: _coche(ref, SujetDePreparation.transport),
      onTap: () => context.push('/trail/$trailId/transport'),
    ),
    // PARITE GR20 (#99460) — RAVITAILLEMENT : carte « Epiceries,
    // pharmacies, gaz » (clone GR20 `ShopDetailScreen`, data-driven).
    // Liste des commerces du sentier groupee par etape, filtres par
    // type, alerte de « gap » de ravitaillement — contenu venant du
    // catalogue ravitaillement du sentier (aucun commerce hardcode).
    // Icone `shopping_cart` (parite GR20). Route hors-shell atteinte
    // via `context.push` (retour propre, pile preservee — jamais
    // context.go qui viderait la pile). Generique multi-sentiers,
    // zero hardcode de localite.
    QuickAccessCard(
      rubrique: RubriqueStepways.ravitaillement,
      title: t.hub.cards.shop,
      subtitle: t.hub.cards.shopSub,
      stepStatus: _coche(ref, SujetDePreparation.ravitaillement),
      onTap: () => context.push('/trail/$trailId/shop'),
    ),
    // PARITE GR20 (#99460) — RESUME : carte « Synthese du plan »
    // (clone GR20 `PlanSummaryScreen`). Agregateur : synthetise le
    // programme, les stats, les nuitees et les dates du sentier
    // courant (aucune donnee inventee). Icone `summarize`, sous-titre
    // « Synthese du plan » (parite GR20). Route hors-shell atteinte
    // via `context.push` -> retour propre (jamais context.go qui
    // viderait la pile). Generique multi-sentiers, zero hardcode.
    QuickAccessCard(
      icon: StepwaysIcons.programme,
      title: t.hub.cards.resume,
      subtitle: t.hub.cards.resumeSub,
      stepStatus: _coche(ref, SujetDePreparation.resume),
      onTap: () => context.push('/trail/$trailId/summary'),
    ),
  ];

  /// Le sac a dos — et, en commentaire, les cartes qui n'y sont plus.
  List<QuickAccessCard> _packCards(BuildContext context, WidgetRef ref) => [
    QuickAccessCard(
      rubrique: RubriqueStepways.sacADos,
      title: t.hub.cards.checklist,
      subtitle: t.hub.cards.checklistSub,
      stepStatus: _coche(ref, SujetDePreparation.materiel),
      // La coche est relue au RETOUR : la table ne previent personne.
      onTap: () async {
        await context.push('/trail/$trailId/checklist');
        if (context.mounted) ref.invalidate(lignesDuSacProvider(trailId));
      },
    ),
    // « Preparation physique » n'est PLUS ICI (retour Chris #6,
    // tache 553) : elle etait la DERNIERE carte de la prepa, donc
    // la derniere chose qu'on lit, alors que l'entrainement se
    // decide en meme temps que les DATES. Elle est remontee juste
    // apres « Calendrier », ci-dessus.
    // R6 (retour Chris) : la carte « Decouvrir des sentiers »
    // (-> /catalog) a ete RETIREE de la section Preparer. Choisir un
    // autre sentier est de l'AMONT (choix du trek), pas de la prepa
    // d'un trek en cours. « Decouvrir » reste accessible depuis
    // l'accueil « maison » (MyTreksScreen : barre contextuelle +
    // bandeau « Decouvrir / Mon compte », cf. DECISIONS §5.2). NB :
    // malgre le nom de cle `offline`, cette carte ne telechargeait
    // AUCUNE carte hors-ligne du trek courant — elle ouvrait juste le
    // catalogue (libelle « Decouvrir des sentiers ») : rien a separer.
    // GROUPE — carte « Mon groupe » RETIREE en StepWays L8 (decision
    // Chris #99615-2). Le suivi de groupe en direct (code mort/demo)
    // sort du perimetre V1 : plus de porte d'entree vers /group/:id
    // (route + code CONSERVES dormants, cf. app_router.dart et
    // INVENTAIRE_ORPHELINS_L8.md). Ne PAS remettre sans decision Chris.
  ];
}
