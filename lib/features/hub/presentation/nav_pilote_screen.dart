import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icon_colors.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../safety/presentation/sos_confirmation_dialog.dart';
import '../../settings/providers/settings_provider.dart';
import '../../treks/domain/trek_lifecycle_state.dart';
import '../../treks/providers/my_treks_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../../weather/providers/current_stage_provider.dart';
import '../../weather/providers/weather_providers.dart';
import 'cockpit_phase.dart';
import 'widgets/hub_section.dart';
import 'widgets/hub_trek_card.dart';
import 'widgets/hub_weather_card.dart';
import 'widgets/quick_access_card.dart';
import 'widgets/step_status_icon.dart';

/// ECRAN-PILOTE de la refonte NAVIGATION StepWays (LOT 3, methode D2) —
/// COCKPIT PAR PHASES (nav V2, retours Chris R3→R10).
///
/// DEMONSTRATEUR VISUEL JETABLE, expose HORS-SHELL sur `/nav-pilote`, destine a
/// la validation visuelle par Chris AVANT de derouler les ~40 ecrans. Il ne
/// touche PAS au `StatefulShellRoute` : le reste de l'app tourne a l'identique.
///
/// COCKPIT PAR PHASES (R7, STRUCTURANT) : au lieu d'empiler les 3 sections
/// (Préparer/Randonner/Après) en simultane comme GR20, on n'affiche qu'UN mode
/// a la fois, pilote par le [TrekLifecycleState] du sentier actif
/// ([currentTrailSummaryProvider]) via [CockpitPhase.fromLifecycle] :
///  - prepared/owned -> Préparer (+ bouton « Démarrer le trek », R6) ;
///  - inProgress     -> Randonner (+ bouton « Terminer le trek », + SOS R9) ;
///  - completed      -> Après.
/// Chaine : prepared → [Démarrer] → inProgress → [Terminer] → completed.
///
/// R3 (couleur de PHASE) : chaque phase teinte SOBREMENT le fond du cockpit +
/// un bandeau d'en-tete de phase ([CockpitPhase.color]). Les ICONES gardent
/// leur couleur categorielle ([CategoryIconColors]) — jamais recolorisees.
///
/// R9/R10 (thumb zone / lateralite) : le SOS (mode Randonner UNIQUEMENT)
/// et les commandes critiques se placent du cote de la MAIN DOMINANTE
/// (`settingsProvider.dominantHand`, defaut droitier=droite). L'action
/// principale (CTA de transition de phase) reste en BAS-CENTRE (zone verte
/// universelle, atteignable droitier ET gaucher). Cibles >= 48 dp.
///
/// R8/R16 (démo = PREPARATION seulement) : le toggle démo revele les selecteurs
/// de phase pour PREVISUALISER la structure Préparer/Randonner/Après, MAIS seule
/// la PREPARATION est jouable. Conformement au MODELE_ECO (démo gratuite = prépa
/// jouable, réalisation terrain = achat), previsualiser Randonner ou Après en
/// démo affiche un APERCU VERROUILLE (teaser premium qui incite a l'achat), pas
/// un cockpit jouable. Le SOS suit le SEUL mode trek reel (jamais forcé en démo).
///
/// GARDE-FOUS LOOK & FEEL : le CORPS reutilise les briques du HUB ([HubHeader],
/// [HubWeatherCard], [HubTrekCard], [HubSection] + [QuickAccessCard]) — aucun
/// style reinvente, tokens `AppTheme` inchanges. Zero texte en dur (Slang).
class NavPiloteScreen extends ConsumerStatefulWidget {
  const NavPiloteScreen({super.key});

  @override
  ConsumerState<NavPiloteScreen> createState() => _NavPiloteScreenState();
}

class _NavPiloteScreenState extends ConsumerState<NavPiloteScreen> {
  // DEMO UNIQUEMENT (branche jetable) : revele les selecteurs d'apercu des
  // phases (R8) dans la barre, pour montrer a Chris la STRUCTURE Préparer/
  // Randonner/Après. R16 : la démo ne rend JOUABLE que la préparation ; les
  // aperçus Randonner/Après sont VERROUILLES (teaser premium). Ce toggle ne
  // force PLUS le SOS (qui suit le seul mode trek reel). A retirer avant merge.
  bool _demoTrekMode = false;

  // Phase previsualisee en mode démo (R8). `null` = suit la phase reelle.
  // Permet a Chris de parcourir la structure des 3 phases sans muter l'etat en
  // base (Randonner/Après = aperçu verrouille en démo, R16).
  CockpitPhase? _previewPhase;

  /// Ouvre la confirmation SOS avec la position GPS courante (parite SosButton).
  void _showSos(BuildContext context) {
    double? latitude;
    double? longitude;
    double? altitude;
    final positionAsync = ref.read(positionStreamProvider);
    positionAsync.whenData((position) {
      latitude = position.latitude;
      longitude = position.longitude;
      altitude = position.altitude;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SosConfirmationDialog(
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
      ),
    );
  }

  /// Fiche d'aide « Informations » — action (i) de l'AppHeader (PARITE hub
  /// origine, hub_screen.dart `_showInfoSheet`). Contenu editorial minimal via
  /// Slang (`t.hub.infoSheetBody`), zero texte en dur.
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

  @override
  Widget build(BuildContext context) {
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final cat = CategoryIconColors.of(context);

    // Etat de cycle de vie DERIVE du sentier actif -> phase principale (R7).
    final summary = ref.watch(currentTrailSummaryProvider).value;
    final lifecycle = summary?.state;
    final realPhase = CockpitPhase.fromLifecycle(lifecycle);
    // En démo, Chris peut previsualiser une autre phase (R8) ; sinon phase reelle.
    final phase = _demoTrekMode ? (_previewPhase ?? realPhase) : realPhase;

    // MODE TREK : rando active|paused -> SOS present. Sinon absent (AUDIT §M-2).
    // R16 : le mode démo NE simule PLUS un Randonner jouable — la démo ne couvre
    // QUE la préparation (Randonner/Après sont des aperçus verrouillés). Le SOS
    // suit donc le SEUL mode trek REEL (`activeTrekId != null`) : plus de force
    // par le toggle démo (qui ne sert qu'a reveler les selecteurs d'apercu R8).
    final activeTrekId = ref.watch(activeTrekIdProvider).value;
    final inTrekMode = activeTrekId != null;
    // R9 : le SOS n'apparait QU'en phase Randonner ET en mode trek reel.
    final showSos = inTrekMode && phase == CockpitPhase.hike;

    // R9/R10 : main dominante (defaut droitier) -> cote des commandes critiques.
    final dominantHand = ref.watch(
      settingsProvider.select((s) => s.dominantHand),
    );
    final sosOnRight = DominantHandValues.isRight(dominantHand);

    // Progression derivee (R5) pour les coches des cartes de preparation.
    final prepProgress = _derivePrepProgress(lifecycle);

    // R13 : la tuile météo du haut ne s'affiche QUE si la météo est reellement
    // disponible (prevision en cache/API) ou en cours de chargement — sinon on
    // la MASQUE proprement plutot que d'exposer « Météo indisponible » (l'acces
    // meteo reste offert par la carte « Météo » de la phase Randonner). On ne
    // touche PAS a [HubWeatherCard] (partagee avec le vrai hub + tests) : le
    // filtre est porte ici, au niveau du pilote.
    final weatherParams = WeatherStageParams(
      trailId: trailId,
      stageNumber: ref.watch(referenceStageNumberProvider),
    );
    final weatherHasForecast =
        ref.watch(weatherForecastProvider(weatherParams)) != null;
    final weatherLoading = ref.watch(weatherLoadingProvider(weatherParams));
    final showWeatherTile = weatherHasForecast || weatherLoading;

    return Scaffold(
      // AppHeader : titre + Retour + actions Informations / Profil + Accueil.
      // R17 : la barre du HAUT porte la MARQUE de l'app (« StepWays »), PAS le
      // nom du trek (parite GR20, qui affiche le nom du produit dans sa barre).
      // Le nom du trek n'apparait plus qu'UNE fois, dans le corps (HubTrekCard).
      // PARITE HUB ORIGINE (retours Chris) : acces Informations (i) + Profil
      // (person) remis a l'identique, places AVANT le bouton Accueil.
      appBar: AppHeader(
        title: t.navPilote.appTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: t.hub.infoTooltip,
            onPressed: () => _showInfoSheet(context, trailTitle),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: t.hub.profileTooltip,
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      // Barre d'ACTIONS en bas (BottomAppBar, pas une NavigationBar) : CTA de
      // transition de phase en BAS-CENTRE (R10 zone verte) + SOS cote main
      // dominante en phase Randonner (R9). En démo, selecteurs d'apercu.
      bottomNavigationBar: _CockpitActionBar(
        phase: phase,
        showSos: showSos,
        sosOnRight: sosOnRight,
        demoPreview: _demoTrekMode,
        onSos: () => _showSos(context),
        onTransition: () => _onTransition(context, phase),
        onSelectPhase: (p) => setState(() => _previewPhase = p),
      ),
      // R3 : fond du cockpit TRES legerement teinte de la couleur de phase, en
      // surcouche du fond sombre dominant. Sobre (alpha faible) : signale l'etape
      // du cycle sans repeindre l'UI ni les icones.
      body: DecoratedBox(
        decoration: BoxDecoration(color: phase.color.withAlpha(14)),
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              // --- TOGGLE DE DEMO (branche jetable) : revele l'apercu des
              // phases (R8) + force le mode trek pour montrer le SOS. PUREMENT
              // visuel — a retirer avant merge.
              Card(
                child: SwitchListTile(
                  value: _demoTrekMode,
                  onChanged: (v) => setState(() {
                    _demoTrekMode = v;
                    if (!v) _previewPhase = null; // sortie démo -> phase reelle
                  }),
                  secondary: const Icon(Icons.science_outlined),
                  title: Text(t.navPilote.demoTrekMode),
                  subtitle: _demoTrekMode ? Text(t.navPilote.demoPreview) : null,
                ),
              ),
              const SizedBox(height: AppTheme.spacingBase),

              // --- CORPS : briques du HUB (look inchange) ---
              // R17 : la banniere « Bonjour, Randonneur ! » ([HubHeader]) est
              // RETIREE (remplissage inutile ; le nom du trek n'apparait qu'une
              // fois, porte par la [HubTrekCard] en phase Préparer).
              // R13 : tuile météo affichee seulement si donnees dispo/chargement.
              if (showWeatherTile) ...[
                const HubWeatherCard(),
                const SizedBox(height: AppTheme.spacingBase),
              ],

              // --- Bandeau d'EN-TETE de phase (R3, teinte pleine) ---
              // R11 : ce bandeau EST le titre de la phase. Les sections du corps
              // ne re-affichent donc PLUS de titre (`showHeader: false`), pour
              // eviter le doublon « Randonner »/« Préparer » juste en dessous.
              _PhaseHeaderBanner(phase: phase),
              const SizedBox(height: AppTheme.spacingBase),

              // R15 : le bloc « Prêt à partir / Démarrer la randonnée »
              // ([HubTrekCard] etat prepared) n'a de sens qu'en PREPARATION.
              // - EN PROD (phase == lifecycle) : la [HubTrekCard] suit le
              //   lifecycle — son switch n'affiche « Démarrer » (etat prepared)
              //   QU'en phase Préparer, la carte « en cours » en Randonner et la
              //   carte « terminé » en Après. On la garde donc dans ces 3 cas.
              // - EN DEMO : la phase previsualisee est DECOUPLEE du lifecycle
              //   reel (bug R15 : preview Randonner mais lifecycle prepared ->
              //   « Démarrer » qui persiste). On ne montre alors la [HubTrekCard]
              //   QUE si l'apercu porte sur Préparer ; en Randonner/Après démo,
              //   c'est l'apercu VERROUILLE ([_LockedPhaseTeaser]) qui s'affiche.
              if (!_demoTrekMode || phase == CockpitPhase.prepare) ...[
                const HubTrekCard(),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // --- UNE seule phase visible (R7) ---
              // R16 : en démo, seule la PREPARATION est jouable ; Randonner et
              // Après sont VERROUILLES (aperçu non jouable qui incite a l'achat).
              ..._buildPhase(context, phase, trailId, cat, prepProgress),
            ],
          ),
        ),
      ),
    );
  }

  /// Progression derivee des cartes de preparation (R5), a defaut d'un
  /// `planningProgressProvider` persiste (LOT-A differe cote StepWays).
  ///
  /// Heuristique SOBRE sur le lifecycle : une fois le trek prepare/en cours/
  /// termine, les sujets de prepa sont consideres traites (coche verte) ; a
  /// l'etat `owned`/inconnu, ils sont « a faire ». C'est un signal d'apercu
  /// fidele au rendu GR20 (3 etats) sans inventer de persistance.
  PlanningStepStatus _derivePrepProgress(TrekLifecycleState? lifecycle) {
    switch (lifecycle) {
      case TrekLifecycleState.prepared:
      case TrekLifecycleState.inProgress:
      case TrekLifecycleState.completed:
        return PlanningStepStatus.completed;
      case TrekLifecycleState.owned:
      case null:
        return PlanningStepStatus.notStarted;
    }
  }

  /// Transition de phase (R7) : prepared → inProgress → completed.
  ///
  /// PILOTE (branche jetable) : en démo, on fait avancer l'apercu de phase sans
  /// muter la base. En prod, la vraie transition passe par les gardes existantes
  /// (démarrage via C4 `ensureSingleActiveThenStart`, fin de session) portees
  /// par la [HubTrekCard] / le suivi — le cockpit ne recree pas cette logique.
  void _onTransition(BuildContext context, CockpitPhase phase) {
    if (_demoTrekMode) {
      setState(() {
        _previewPhase = switch (phase) {
          CockpitPhase.prepare => CockpitPhase.hike,
          CockpitPhase.hike => CockpitPhase.after,
          CockpitPhase.after => CockpitPhase.prepare,
        };
      });
      return;
    }
    // Prod (apercu pilote) : le CTA « Démarrer » ouvre la carte/le suivi via la
    // HubTrekCard (garde C4). Ici, on route vers la carte pour demarrer/reprendre.
    switch (phase) {
      case CockpitPhase.prepare:
      case CockpitPhase.hike:
        context.push('/map');
      case CockpitPhase.after:
        context.push('/trail/${ref.read(trailConfigProvider).id}/recap');
    }
  }

  /// Construit le contenu de LA phase active (R7) — une section clonee GR20.
  ///
  /// R16 : en démo, seule la PREPARATION est jouable. Previsualiser Randonner ou
  /// Après en démo affiche un APERCU VERROUILLE (teaser premium) au lieu du
  /// cockpit jouable — cohérent MODELE_ECO (réalisation terrain = achat).
  List<Widget> _buildPhase(
    BuildContext context,
    CockpitPhase phase,
    String trailId,
    CategoryIconColors cat,
    PlanningStepStatus prepProgress,
  ) {
    // R16 : démo = prépa seulement. Randonner/Après en démo -> aperçu verrouille.
    if (_demoTrekMode && phase != CockpitPhase.prepare) {
      return [_LockedPhaseTeaser(phase: phase)];
    }
    switch (phase) {
      case CockpitPhase.prepare:
        return _buildPrepare(context, trailId, cat, prepProgress);
      case CockpitPhase.hike:
        return _buildHike(context, trailId, cat);
      case CockpitPhase.after:
        return _buildAfter(context, trailId, cat);
    }
  }

  /// Phase « Préparer » — clone COMPLET de la section GR20 « Préparer »
  /// (`home_screen.dart:142-288` : Faisabilité, Itinéraire, Programme, Nuitées,
  /// Matériel & Sac, Calendrier, Offline, Mon groupe, Transport, Résumé) +
  /// cartes StepWays (Préparation physique). Coches R5 sur les sujets suivis.
  ///
  /// R11 : `showHeader: false` — le bandeau de phase porte deja le titre
  /// « Préparer », on ne le repete pas ici (fin du doublon).
  /// R14 : « Ravitaillement » N'EST PLUS ici — c'est une carte de la phase
  /// Randonner (parite GR20 `:379-388`), voir [_buildHike].
  List<Widget> _buildPrepare(
    BuildContext context,
    String trailId,
    CategoryIconColors cat,
    PlanningStepStatus prepProgress,
  ) {
    return [
      HubSection(
        title: t.hub.sections.prepare,
        showHeader: false,
        icon: Icons.assignment_outlined,
        iconColor: cat.blue, // GR20 Preparer -> bleu
        cards: [
          QuickAccessCard(
            icon: Icons.quiz_outlined,
            title: t.hub.cards.feasibility,
            subtitle: t.hub.cards.feasibilitySub,
            iconColor: cat.blue,
            stepStatus: prepProgress,
            onTap: () => context.push('/trail/$trailId/feasibility'),
          ),
          QuickAccessCard(
            icon: Icons.route_outlined,
            title: t.hub.cards.itinerary,
            subtitle: t.hub.cards.itinerarySub,
            iconColor: cat.green,
            stepStatus: prepProgress,
            onTap: () => context.push('/trail/$trailId/itinerary'),
          ),
          QuickAccessCard(
            icon: Icons.event_note_outlined,
            title: t.hub.cards.programme,
            subtitle: t.hub.cards.programmeSub,
            iconColor: cat.orange,
            stepStatus: prepProgress,
            onTap: () => context.push('/trail/$trailId/planning'),
          ),
          QuickAccessCard(
            icon: Icons.calendar_month,
            title: t.hub.cards.calendar,
            subtitle: t.hub.cards.calendarSub,
            iconColor: cat.blue,
            stepStatus: prepProgress,
            onTap: () => context.push('/trail/$trailId/calendar'),
          ),
          QuickAccessCard(
            icon: Icons.cabin,
            title: t.hub.cards.nuitees,
            subtitle: t.hub.cards.nuiteesSub,
            iconColor: cat.greenLight,
            onTap: () => context.push('/trail/$trailId/nuitees'),
          ),
          QuickAccessCard(
            icon: Icons.directions_bus,
            title: t.hub.cards.transport,
            subtitle: t.hub.cards.transportSub,
            iconColor: cat.orange,
            onTap: () => context.push('/trail/$trailId/transport'),
          ),
          QuickAccessCard(
            icon: Icons.summarize,
            title: t.hub.cards.resume,
            subtitle: t.hub.cards.resumeSub,
            iconColor: cat.blue,
            onTap: () => context.push('/trail/$trailId/summary'),
          ),
          QuickAccessCard(
            icon: Icons.checklist_rtl,
            title: t.hub.cards.checklist,
            subtitle: t.hub.cards.checklistSub,
            iconColor: cat.teal,
            stepStatus: prepProgress,
            onTap: () => context.push('/trail/$trailId/checklist'),
          ),
          QuickAccessCard(
            icon: Icons.fitness_center,
            title: t.hub.cards.training,
            subtitle: t.hub.cards.trainingSub,
            iconColor: cat.teal,
            onTap: () => context.push('/training'),
          ),
          QuickAccessCard(
            icon: Icons.explore_outlined,
            title: t.hub.cards.offline,
            subtitle: t.hub.cards.offlineSub,
            iconColor: cat.blue,
            onTap: () => context.push('/catalog'),
          ),
          QuickAccessCard(
            icon: Icons.groups_outlined,
            title: t.hub.cards.group,
            subtitle: t.hub.cards.groupSub,
            iconColor: cat.greenLight,
            onTap: () => context.push('/group/$trailId'),
          ),
        ],
      ),
    ];
  }

  /// Phase « Randonner » — clone COMPLET de la section GR20 « Randonner »
  /// (`home_screen.dart:297-414`) : Navigation, Journal, Groupe live,
  /// Ravitaillement, Météo, Incendie — AUGMENTE des cartes « Informations » GR20
  /// (`:418-448` : Hébergements, Fiches conseils) que Chris rattache a Randonner
  /// (R14 : « sur GR20 c'est DANS Randonner »).
  ///
  /// R14 : le pilote V1 ne clonait que Navigation/Journal/Incendie — RAVITAILLE-
  /// MENT, METEO et FICHES INFO manquaient. La liste ci-dessous est desormais
  /// l'INTEGRALITE des cartes « en rando » (pas un extrait).
  /// R11 : `showHeader: false` — le bandeau de phase porte deja « Randonner ».
  ///
  /// VIGILANCE Chris (R7) : les fiches de PREPA TERRAIN (checklist/sac, dangers)
  /// restent ACCESSIBLES en rando via une ENTREE SECONDAIRE (« Revoir la
  /// préparation ») — on ne masque pas Préparer, on ne le met pas en principal.
  List<Widget> _buildHike(
    BuildContext context,
    String trailId,
    CategoryIconColors cat,
  ) {
    return [
      HubSection(
        title: t.hub.sections.hike,
        showHeader: false,
        icon: Icons.hiking,
        iconColor: cat.greenLight, // GR20 Randonner -> vertMaquisLight
        cards: [
          // Navigation — GR20 :328-350 (Icons.map, vertMaquis).
          QuickAccessCard(
            icon: Icons.navigation_outlined,
            title: t.hub.cards.navigation,
            subtitle: t.hub.cards.navigationSub,
            iconColor: cat.green,
            onTap: () => context.push('/map'),
          ),
          // Journal — GR20 :352-360 (Icons.book, orangeTerre).
          QuickAccessCard(
            icon: Icons.menu_book_outlined,
            title: t.hub.cards.journal,
            subtitle: t.hub.cards.journalSub,
            iconColor: cat.orange,
            onTap: () => context.push('/journal'),
          ),
          // Groupe live — GR20 :368-376 (Icons.group, bleuLight) -> /group/:id.
          QuickAccessCard(
            icon: Icons.groups_outlined,
            title: t.hub.cards.group,
            subtitle: t.hub.cards.groupSub,
            iconColor: cat.blue,
            onTap: () => context.push('/group/$trailId'),
          ),
          // Ravitaillement — GR20 :379-388 (Icons.shopping_cart,
          // vertMaquisLight) -> /trail/:id/shop (ShopScreen data-driven).
          QuickAccessCard(
            icon: Icons.shopping_cart,
            title: t.hub.cards.shop,
            subtitle: t.hub.cards.shopSub,
            iconColor: cat.greenLight,
            onTap: () => context.push('/trail/$trailId/shop'),
          ),
          // Météo — GR20 :395-402 (Icons.wb_sunny, orangeTerre) ->
          // /trail/:id/weather (WeatherScreen). R13 : la carte se degrade
          // proprement si la meteo est indisponible (voir HubWeatherCard).
          QuickAccessCard(
            icon: Icons.wb_sunny_outlined,
            title: t.hub.cards.weather,
            subtitle: t.hub.cards.weatherSub,
            iconColor: cat.orange,
            onTap: () => context.push('/trail/$trailId/weather'),
          ),
          // Incendie — GR20 :404-412 (Icons.local_fire_department, rougeUrgence).
          QuickAccessCard(
            icon: Icons.local_fire_department,
            title: t.hub.cards.fire,
            subtitle: t.hub.cards.fireSub,
            iconColor: cat.red,
            onTap: () => context.push('/trail/$trailId/fire-risk'),
          ),
          // Hébergements — GR20 Informations :427-435 (Icons.hotel, bleuMed) ->
          // /accommodations-nearby (facilitateur). Rattache a Randonner (R14).
          QuickAccessCard(
            icon: Icons.hotel_outlined,
            title: t.hub.cards.accommodations,
            subtitle: t.hub.cards.accommodationsSub,
            iconColor: cat.blue,
            onTap: () => context.push('/accommodations-nearby?trailId=$trailId'),
          ),
          // Fiches conseils (fiches information) — GR20 Informations :438-446
          // (Icons.menu_book, bleuMed) -> /trail/:id/tips. Rattache a Randonner
          // (R14 : « fiches information » DANS Randonner).
          QuickAccessCard(
            icon: Icons.menu_book,
            title: t.hub.cards.tips,
            subtitle: t.hub.cards.tipsSub,
            iconColor: cat.blue,
            onTap: () => context.push('/trail/$trailId/tips'),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spacingBase),
      // VIGILANCE R7 : entree secondaire vers la prepa terrain (checklist/sac,
      // dangers) — reste atteignable en rando sans quitter la phase Randonner.
      _ReviewPrepEntry(
        onTap: () => context.push('/trail/$trailId/checklist'),
      ),
    ];
  }

  /// Phase « Après » — clone de la section GR20 « Après le trek »
  /// (`home_screen.dart:452-496` : Récapitulatif + Diplôme verrouillable
  /// `:471-494`) + carte StepWays « Import GPX ». R11 : `showHeader: false`.
  List<Widget> _buildAfter(
    BuildContext context,
    String trailId,
    CategoryIconColors cat,
  ) {
    // Diplome verrouille tant que le trek n'est pas termine (parite GR20 B40).
    final lifecycle = ref.watch(
      currentTrailSummaryProvider.select((a) => a.value?.state),
    );
    final isCompleted = lifecycle == TrekLifecycleState.completed;

    return [
      HubSection(
        title: t.hub.sections.after,
        showHeader: false, // R11 : le bandeau de phase porte deja « Après ».
        icon: Icons.emoji_events_outlined,
        iconColor: cat.yellow, // GR20 Apres -> jaune
        cards: [
          QuickAccessCard(
            icon: Icons.landscape_outlined,
            title: t.hub.cards.recap,
            subtitle: t.hub.cards.recapSub,
            iconColor: cat.green,
            onTap: () => context.push('/trail/$trailId/recap'),
          ),
          QuickAccessCard(
            icon: Icons.upload_file,
            title: t.hub.cards.importGpx,
            subtitle: t.hub.cards.importGpxSub,
            iconColor: cat.blue,
            onTap: () => context.push('/trail/$trailId/import-gpx'),
          ),
          QuickAccessCard(
            icon: Icons.workspace_premium_outlined,
            title: t.hub.cards.diploma,
            subtitle: t.hub.cards.diplomaSub,
            iconColor: cat.yellow, // GR20 Diplome -> jaune
            // Verrou parite GR20 : diplome accessible seulement une fois termine
            // (en démo, deverrouille pour l'apercu).
            enabled: isCompleted || _demoTrekMode,
            lockedLabel: t.recap.lockedTitle,
            onTap: () => context.push('/trail/$trailId/diploma'),
          ),
        ],
      ),
    ];
  }
}

/// Bandeau d'EN-TETE de phase (R3) : titre de la phase + sous-titre, sur un fond
/// en teinte PLEINE de la phase (contraste fort, lisible). Signale « ou tu es
/// dans le cycle » sans recoloriser les icones categorielles.
class _PhaseHeaderBanner extends StatelessWidget {
  const _PhaseHeaderBanner({required this.phase});

  final CockpitPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, subtitle, icon) = switch (phase) {
      CockpitPhase.prepare => (
          t.hub.sections.prepare,
          t.navPilote.phasePrepareSub,
          Icons.assignment_outlined,
        ),
      CockpitPhase.hike => (
          t.hub.sections.hike,
          t.navPilote.phaseHikeSub,
          Icons.hiking,
        ),
      CockpitPhase.after => (
          t.hub.sections.after,
          t.navPilote.phaseAfterSub,
          Icons.emoji_events_outlined,
        ),
    };

    // Fond en teinte pleine de la phase ; texte/icone en couleur lisible dessus.
    // Les phases claires (jaune/vertLight/bleuLight) demandent un texte SOMBRE
    // pour le contraste AA -> on force le noir (parite « pastille pleine » R4).
    final onPhase = ThemeData.estimateBrightnessForColor(phase.color) ==
            Brightness.dark
        ? Colors.white
        : AppTheme.noir;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: phase.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, color: onPhase, size: 24),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: onPhase,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: onPhase.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Entree secondaire « Revoir la préparation » (VIGILANCE R7) : garde les fiches
/// de prepa terrain (checklist/sac, dangers) atteignables pendant la rando.
class _ReviewPrepEntry extends StatelessWidget {
  const _ReviewPrepEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(t.navPilote.reviewPrep),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        // Cible tactile >= 48 dp (Material) — ListTile garantit deja ~56 dp.
        titleTextStyle: theme.textTheme.titleMedium,
      ),
    );
  }
}

/// Aperçu VERROUILLE d'une phase (R16) — démo/gratuit uniquement.
///
/// Le mode démo ne rend jouable que la PREPARATION (frontière d'or MODELE_ECO :
/// prépa informative gratuite / réalisation terrain payante). Previsualiser
/// Randonner ou Après en démo affiche donc ce teaser NON JOUABLE (cadenas +
/// invitation a débloquer le trek) au lieu du cockpit reel — il informe sur ce
/// que l'utilisateur obtiendra apres achat et incite a l'achat (R8 : montrer la
/// structure ; R16 : sans la rendre jouable). Reutilise [AppCard] + tokens
/// `AppTheme`, zero texte en dur (Slang `t.navPilote.demoLocked*`).
class _LockedPhaseTeaser extends StatelessWidget {
  const _LockedPhaseTeaser({required this.phase});

  final CockpitPhase phase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Libelle de la phase verrouillee (Randonner / Après) pour le message.
    final phaseLabel = switch (phase) {
      CockpitPhase.prepare => t.hub.sections.prepare,
      CockpitPhase.hike => t.hub.sections.hike,
      CockpitPhase.after => t.hub.sections.after,
    };
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cadenas dans une pastille sobre (fond attenue) — signal « verrouille ».
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: scheme.onSurface.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline,
              size: 32,
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            t.navPilote.demoLockedTitle(phase: phaseLabel),
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.navPilote.demoLockedBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Barre d'ACTIONS du cockpit par phases (R6/R7/R9/R10).
///
/// - **Action principale** = CTA de TRANSITION de phase, en BAS-CENTRE (R10,
///   zone verte universelle, atteignable droitier ET gaucher) :
///   Préparer→« Démarrer le trek » (R6) / Randonner→« Terminer le trek ».
///   Phase Après TERMINALE -> pas de CTA (actions dans les cartes du corps).
///   Rendu « pastille pleine accentuee » lisible (R4).
/// - **SOS** (R9) : phase Randonner UNIQUEMENT, place du COTE de la main
///   dominante ([sosOnRight] : droitier=droite, gaucher=gauche). Pastille pleine
///   rouge, cible >= 56 dp. Pas de chevauchement : le SOS occupe le bord (cote
///   dominant), la transition le centre — jamais superposes.
/// - **Démo** ([demoPreview]) : ajoute les selecteurs d'apercu des 3 phases (R8).
///
/// C'est une [BottomAppBar] (barre d'actions), PAS une [NavigationBar]
/// d'onglets (garde-fou G4).
class _CockpitActionBar extends StatelessWidget {
  const _CockpitActionBar({
    required this.phase,
    required this.showSos,
    required this.sosOnRight,
    required this.demoPreview,
    required this.onSos,
    required this.onTransition,
    required this.onSelectPhase,
  });

  final CockpitPhase phase;
  final bool showSos;
  final bool sosOnRight;
  final bool demoPreview;
  final VoidCallback onSos;
  final VoidCallback onTransition;
  final ValueChanged<CockpitPhase> onSelectPhase;

  @override
  Widget build(BuildContext context) {
    // CTA de transition selon la phase (R6/R7). L'AVANCEE du cycle est
    // prepared→[Démarrer]→inProgress→[Terminer]→completed : la phase Après est
    // TERMINALE (pas de phase suivante) -> AUCUNE pastille de transition (les
    // actions Après vivent dans les cartes Recap/Diplome du corps).
    final (String, IconData)? transitionSpec = switch (phase) {
      CockpitPhase.prepare => (t.navPilote.startTrek, Icons.play_arrow),
      CockpitPhase.hike => (t.navPilote.finishTrek, Icons.flag_outlined),
      CockpitPhase.after => null,
    };

    // Bouton SOS (R9) — pastille pleine rouge, cible >= 56 dp, cote dominant.
    final sos = _SosPill(onPressed: onSos);

    // CTA principal en pastille pleine accentuee (R4) — vertMaquisLight (phase
    // Randonner) + texte/icone blanc, contraste AA sur fond sombre. Absent en
    // phase Après (spacer pour garder le SOS a sa place laterale si present).
    final Widget center = transitionSpec == null
        ? const Spacer()
        : _TransitionPill(
            label: transitionSpec.$1,
            icon: transitionSpec.$2,
            onPressed: onTransition,
          );

    return BottomAppBar(
      // R12 : quand les selecteurs d'apercu (démo) ajoutent une 2e rangee, la
      // BottomAppBar doit etre plus HAUTE pour les contenir (rangee principale
      // ~68 dp + selecteurs 48 dp + espacement) — sinon la Column deborde
      // verticalement (rayures jaune/noir). Hauteur nulle (defaut theme) sans
      // démo. Padding vertical retire au profit de cette hauteur maitrisee.
      height: demoPreview ? 132 : null,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rangee principale : SOS (cote main dominante) + CTA transition
          // (centre). Le SOS prend le bord dominant, la transition s'etire au
          // centre -> jamais de chevauchement (R9/R10).
          Row(
            children: [
              if (showSos && !sosOnRight) ...[
                sos,
                const SizedBox(width: AppTheme.spacingSm),
              ],
              transitionSpec == null ? center : Expanded(child: center),
              if (showSos && sosOnRight) ...[
                const SizedBox(width: AppTheme.spacingSm),
                sos,
              ],
            ],
          ),
          // Selecteurs d'APERCU des phases (R8) — démo uniquement.
          //
          // R12 : chaque puce est `Expanded` (part egale de la largeur) avec
          // libelle centre + ellipsis -> plus d'OVERFLOW ~11 px (rayures jaune/
          // noir) aux largeurs mobiles (360 px). L'ancien `spaceAround` sur des
          // puces a largeur intrinseque debordait quand la somme depassait la
          // ligne. Chaque puce reste une cible tactile >= 48 dp de haut.
          if (demoPreview) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              children: [
                Expanded(
                  child: _PhaseChip(
                    label: t.navPilote.prepare,
                    selected: phase == CockpitPhase.prepare,
                    onTap: () => onSelectPhase(CockpitPhase.prepare),
                  ),
                ),
                Expanded(
                  child: _PhaseChip(
                    label: t.navPilote.hike,
                    selected: phase == CockpitPhase.hike,
                    onTap: () => onSelectPhase(CockpitPhase.hike),
                  ),
                ),
                Expanded(
                  child: _PhaseChip(
                    label: t.navPilote.after,
                    selected: phase == CockpitPhase.after,
                    onTap: () => onSelectPhase(CockpitPhase.after),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Pastille pleine du CTA de transition (R4) : fond `phaseHike` (vertMaquisLight)
/// + icone/texte blanc, contraste AA sur fond sombre. Cible >= 48 dp.
class _TransitionPill extends StatelessWidget {
  const _TransitionPill({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: AppTheme.phaseHike,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          onTap: onPressed,
          child: Container(
            // Cible tactile confortable (>= 48 dp, ici 52 dp comme les boutons).
            constraints: const BoxConstraints(minHeight: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: AppTheme.spacingSm),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille SOS (R9) — pleine rouge, icone + « SOS » blanc, cible >= 56 dp.
/// Clone de l'intention `SosButton` GR20 (rouge urgence, label a11y explicite).
class _SosPill extends StatelessWidget {
  const _SosPill({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: t.a11y.sos,
      excludeSemantics: true,
      child: Material(
        color: AppTheme.rougeUrgence,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 56),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emergency, color: Colors.white, size: 22),
                Text(
                  t.navPilote.sos,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Puce de selection d'apercu de phase (R8, démo uniquement).
class _PhaseChip extends StatelessWidget {
  const _PhaseChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      onTap: onTap,
      child: Container(
        // Cible tactile >= 48 dp (Material) ; centre le libelle dans sa part
        // `Expanded` (R12 : plus d'overflow, largeur pilotee par le parent).
        constraints: const BoxConstraints(minHeight: 48),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXs,
          vertical: AppTheme.spacingXs,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            color: selected ? scheme.primary : scheme.onSurface,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            decoration: selected ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }
}
