import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/services/mise_a_jour_a_la_source.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/bouton_simulation_demo.dart';
import '../../ads/presentation/badge_etat_publicite.dart';
import '../../ads/presentation/banner_ad_slot.dart';
import '../../safety/presentation/sos_button.dart';
import '../../treks/providers/my_treks_provider.dart';
import '../../trek/providers/tracking_providers.dart';
import 'cockpit_phase.dart';
import 'widgets/collapsible_prepare_section.dart';
import 'widgets/finish_trek_button.dart';
import 'widgets/hub_buy_trek_button.dart';
import 'widgets/hub_section.dart';
import 'widgets/hub_start_trek_button.dart';
import 'widgets/hub_trek_card.dart';
import 'widgets/hub_wallet_card.dart';
import 'widgets/localized_conditions_banner.dart';
import 'widgets/quick_access_card.dart';

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
///   * **Préparer** : toujours présente, en ACCORDÉON (dépliée en préparation,
///     repliée une fois parti/rentré — D3, R8+R13) ;
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

class _HubScreenState extends ConsumerState<HubScreen> {
  @override
  Widget build(BuildContext context) {
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    // OUVRIR UN SENTIER, C EST DEMANDER CE QUI A CHANGE DESSUS (tache 641).
    //
    // « Je veux que l'application vienne mettre a jour ses donnees a cette
    // source » (Christophe, 30/09 11:54). Cet ecran est la porte d'entree du
    // sentier : les rubriques qu'il ouvre — transport, ravitaillement, nuitees,
    // etapes — sont precisement celles que Christophe a trouvees vides. La mise
    // a jour part ICI, en arriere-plan, sans rien faire attendre : la copie
    // locale est deja affichee, la base la complete quand elle repond.
    ref.watch(miseAJourAlOuvertureProvider(trailId));

    // Retour Chris #13 (LOT 2) : le menu du cockpit est CONTEXTUEL a l'etat du
    // trek (DECISIONS.md §5.2, accueil « maison »/« terrain »). La PHASE est
    // DERIVEE du cycle de vie reel du sentier actif ([currentTrailSummaryProvider]
    // -> [TrekLifecycleState]) via [CockpitPhase.fromLifecycle] — jamais un flag
    // invente. Regle :
    //   * Préparer + Informations : TOUJOURS visibles (la prepa se fait avant/
    //     pendant/apres) ;
    //   * Randonner : visible UNIQUEMENT en mode rando active (phase hike,
    //     lifecycle inProgress) ;
    //   * Après le trek : visible UNIQUEMENT une fois le trek termine (phase
    //     after, lifecycle completed).
    // Tant qu'on n'est pas en rando, ni « Randonner » ni « Après-trek » ne
    // s'affichent (retour Chris #13, « on en a deja parle »).
    //
    // PRIORITE A L'ETAT VIVANT (parite [HubTrekCard]) : une session de tracking
    // `recording`/`paused` en memoire prime sur l'etat DERIVE (la session
    // persistee peut ne pas etre encore reprise dans `currentTrailSummaryProvider`
    // apres un demarrage). On considere donc « rando active » des que le tracking
    // vit OU que le lifecycle vaut inProgress -> phase hike coherente avec la
    // carte principale et le bouton de demarrage.
    final tracking = ref.watch(trekSessionManagerProvider);
    final liveActive =
        tracking.status == TrackingSessionStatus.recording ||
        tracking.status == TrackingSessionStatus.paused;
    final lifecycle = ref.watch(currentTrailSummaryProvider).value?.state;
    final phase = liveActive
        ? CockpitPhase.hike
        : CockpitPhase.fromLifecycle(lifecycle);
    final showHike = phase == CockpitPhase.hike;
    final showAfter = phase == CockpitPhase.after;

    return Scaffold(
      // Parité GR20 pure (D1) : AUCUNE barre du bas sur le cockpit. Les sections
      // vivent dans le scroll ; la navigation est hub-and-push (push/pop).
      appBar: AppBar(
        title: Text(trailTitle),
        actions: [
          // StepWays LOT 2 (Phase 5) : retour a l'accueil « Mes treks » (option
          // A) — l'entree de l'onglet Accueil liste tous les treks possedes.
          IconButton(
            icon: const StepIcon(StepwaysIcons.chaussure),
            tooltip: t.nav.myTreks,
            onPressed: () => context.go('/my-treks'),
          ),
          IconButton(
            icon: const StepIcon(StepwaysIcons.info),
            tooltip: t.hub.infoTooltip,
            onPressed: () => _showInfoSheet(context, trailTitle),
          ),
          IconButton(
            icon: const StepIcon(StepwaysIcons.monCompte),
            tooltip: t.hub.profileTooltip,
            onPressed: () => context.push('/profile'),
          ),
          // Finitions V1 (point 1) : acces REGLAGES depuis le cockpit. Le
          // big-bang hub-and-push (L3) a supprime l'onglet « Plus » qui etait la
          // SEULE porte vers /settings -> langue/unites/theme/confidentialite
          // devenaient inatteignables apres l'onboarding. On retablit un acces
          // atteignable via le header standard du cockpit (SPEC §4 : « Mon compte
          // / reglages / ecrans info : header standard »). push -> retour propre.
          IconButton(
            icon: const StepIcon(StepwaysIcons.reglages),
            tooltip: t.nav.settings,
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
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
      floatingActionButton: const SosButton(),
      // PARITE GR20 (`home_screen.dart` : FloatingActionButtonLocation
      // .startFloat) + fix d'un vrai defaut d'acces : au coin BAS-DROIT par
      // defaut, la pastille SOS se posait SUR le bouton pleine largeur
      // « Terminer le trek » en fin de scroll et en masquait la fin (constate
      // sur la capture S3_Steve_11_apres_terminer du round 1). Bas-GAUCHE :
      // plus aucun recouvrement, et le SOS se trouve au MEME endroit que sur la
      // carte -> une seule position a memoriser pour un geste d'urgence.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
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
      bottomNavigationBar: showHike ? null : BannerAdSlot(trailId: trailId),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
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
            const BandeauEtatPublicite(),
            const SizedBox(height: AppTheme.spacingSm),
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

            // --- Section Preparer (RF-6) — ACCORDÉON (D3, R8+R13) ---
            // Parité GR20 modèle A : Préparer reste TOUJOURS présente dans le
            // scroll, mais REPLIÉE une fois parti (phase hike) ou rentré (after)
            // pour dégager le cockpit ; DÉPLIÉE en préparation (le cœur du moment).
            // Jamais masquée : le randonneur la déplie d'un tap pour revoir un
            // point (R13). L'état initial suit la phase (déplié si !hike && !after).
            CollapsiblePrepareSection(
              initiallyExpanded: !showHike && !showAfter,
              cards: [
                QuickAccessCard(
                  rubrique: RubriqueStepways.faisabilite,
                  title: t.hub.cards.feasibility,
                  subtitle: t.hub.cards.feasibilitySub,
                  onTap: () => context.push('/trail/$trailId/feasibility'),
                ),
                QuickAccessCard(
                  rubrique: RubriqueStepways.itineraire,
                  title: t.hub.cards.itinerary,
                  subtitle: t.hub.cards.itinerarySub,
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
                  onTap: () => context.push('/trail/$trailId/calendar'),
                ),
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
                  onTap: () => context.push('/health'),
                ),
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
                  onTap: () => context.push('/trail/$trailId/cartes'),
                ),
                // PARITE GR20 (#99460) — NUITEES : assistant « Reserver vos
                // nuits » (type de nuitee + reserve par nuit du programme).
                // Route hors-shell atteinte via `context.push` -> retour propre
                // (pile preservee, jamais context.go qui viderait la pile).
                QuickAccessCard(
                  rubrique: RubriqueStepways.nuitees,
                  title: t.hub.cards.nuitees,
                  subtitle: t.hub.cards.nuiteesSub,
                  onTap: () => context.push('/trail/$trailId/nuitees'),
                ),
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
                  onTap: () => context.push('/trail/$trailId/summary'),
                ),
                QuickAccessCard(
                  rubrique: RubriqueStepways.sacADos,
                  title: t.hub.cards.checklist,
                  subtitle: t.hub.cards.checklistSub,
                  onTap: () => context.push('/trail/$trailId/checklist'),
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
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Randonner (RF-8) ---
            // Retour Chris #13 : MASQUEE tant qu'on n'est pas en rando active
            // (phase hike / lifecycle inProgress). En preparation, elle n'a pas
            // lieu d'etre (les outils terrain — navigation, journal, incendie —
            // ne servent qu'une fois parti). Rendue conditionnellement.
            if (showHike) ...[
              // R11 (retour Chris, LOT L8) — LA MÉTÉO EST ICI, PENDANT LA RANDO.
              // Bandeau « ici et maintenant » EN TÊTE de la section Randonner :
              // météo du JOUR + risque incendie de l'étape COURANTE détectée par
              // le GPS ([localizedStageNumberProvider]), et non l'étape de
              // référence D-3 qu'utilisait la tuile de préparation retirée (R2e).
              // Parité GR20 : la météo n'est joignable qu'en terrain, jamais en
              // prépa. Comme toute la section, il n'est rendu qu'en phase `hike`
              // -> invisible en préparation, par construction.
              LocalizedConditionsBanner(trailId: trailId),
              const SizedBox(height: AppTheme.spacingBase),
              HubSection(
                title: t.hub.sections.hike,
                icon: StepwaysIcons.chaussure,
                cards: [
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
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // --- JOURNAL APRES LE TREK (tache 558) ---
            //
            // Decision de Chris : « en postrando pour le remplir et le lire ».
            // La section « Randonner » n'existe plus une fois rentre : la carte
            // se pose ici, a la MEME hauteur de scroll qu'en rando (entre
            // « Preparer » et « Informations »), pour qu'on la retrouve au meme
            // endroit d'une phase a l'autre. C'etait le VRAI trou d'acces que
            // R10 / LOT L10 avait repere — il reste bouche.
            if (showAfter) ...[
              QuickAccessCard(
                rubrique: RubriqueStepways.journal,
                title: t.hub.cards.journal,
                subtitle: t.hub.cards.journalSub,
                onTap: () => context.push('/journal'),
              ),
              const SizedBox(height: AppTheme.spacingLg),
            ],

            // --- Section Informations (RF-9) ---
            // TOUJOURS rendue (aucune garde de phase).
            HubSection(
              title: t.hub.sections.info,
              icon: StepwaysIcons.info,
              cards: [
                // JOURNAL : PLUS ICI (retour Chris #11, tache 553). Mot pour
                // mot : « journal est dans information dans preparation??? ».
                // La carte etait rendue ici hors rando (correctif d'acces R10 /
                // LOT L10) et dans « Randonner » en rando : elle changeait de
                // place selon le moment, et « Informations » est une rubrique
                // qu'on LIT, pas ou l'on ECRIT son carnet.
                // Depuis la tache 558 elle n'existe PLUS DU TOUT en phase de
                // preparation (decision Chris) : elle vit dans « Randonner »
                // pendant la rando, et juste au-dessus de cette section une
                // fois le trek termine.
                QuickAccessCard(
                  rubrique: RubriqueStepways.hebergement,
                  title: t.hub.cards.accommodations,
                  subtitle: t.hub.cards.accommodationsSub,
                  onTap: () => context.push('/accommodations-nearby'),
                ),
                QuickAccessCard(
                  rubrique: RubriqueStepways.ficheConseil,
                  title: t.hub.cards.tips,
                  subtitle: t.hub.cards.tipsSub,
                  onTap: () => context.push('/trail/$trailId/tips'),
                ),
                // « GUIDES DES VILLES » — CARTE MASQUEE SUR DECISION DE CHRIS
                // (retour #13, tache 553). Mot pour mot : « guide des villes, on
                // en a pas assez parle voire pas du tout tu cache pour
                // l'instant ». La feature a ete cablee en E33/E34 (LOT D/D2)
                // sans jamais avoir ete discutee : on retire la PORTE du
                // cockpit, le temps d'en parler.
                //
                // CE QUI RESTE EN PLACE, INTACT : les routes
                // `/trail/:id/guides` et `/guides/:guideId`, les ecrans, les
                // providers, les donnees et les tests de la feature. Rien n'est
                // supprime — seule la carte du cockpit disparait. Remettre ces
                // six lignes suffit a rouvrir la porte.
                //
                // CETTE DECISION SURCLASSE LA REGLE S8 « zero route morte » :
                // S8 interdit une carte SANS cible, pas une cible sans carte, et
                // c'est Chris qui arbitre ce qu'il montre de son application.
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

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
            if (!showHike && !showAfter) HubStartTrekButton(trailId: trailId),

            // --- LA SIMULATION DE LA DEMO VIT ICI (tache 638, bugs 11 et 16) ---
            // Le lot 634 la portait dans un bandeau pose EN BAS DE TOUS LES
            // ECRANS, qui masquait le bas de chacun — c'est le defaut du bug 11
            // (DEM-260930-1020 : « le bandeau du bas du mode demo cache une
            // partie de l appli »). Elle est desormais un bouton, dans le
            // cockpit, invisible hors demo et invisible tant que la randonnee
            // simulee n'est pas partie.
            const BoutonSimulationDemo(),

            // --- « Terminer le trek » (Finitions V1, point 3) ---
            // Bouton ORANGE en FIN DE SCROLL (décision Chris), symétrique du
            // « Démarrer » porté par la HubTrekCard. Ne s'affiche QUE si un trek
            // est en cours (le widget se masque lui-même sinon). Rétablit une fin
            // MANUELLE atteignable — l'app ne dépend plus uniquement de la
            // détection GPS d'arrivée pour terminer un trek.
            const FinishTrekButton(),
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
