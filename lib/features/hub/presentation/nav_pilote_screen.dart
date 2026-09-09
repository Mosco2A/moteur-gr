import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icon_colors.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_header.dart';
import '../../safety/presentation/sos_confirmation_dialog.dart';
import '../../settings/providers/settings_provider.dart';
import '../../treks/domain/trek_lifecycle_state.dart';
import '../../treks/providers/my_treks_provider.dart';
import '../../trek/providers/gps_providers.dart';
import 'cockpit_phase.dart';
import 'widgets/hub_header.dart';
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
/// R8 (démo = apercu des phases) : le toggle démo revele les selecteurs de
/// phase dans la barre pour PREVISUALISER Préparer/Randonner/Après (aperçu),
/// meme sans trek reel — vitrine coherente MODELE_ECO. En prod, la phase suit
/// le seul lifecycle et le SOS le seul mode trek reel.
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
  // DEMO UNIQUEMENT (branche jetable) : revele l'apercu des phases (R8) — les
  // selecteurs Préparer/Randonner/Après dans la barre — ET force le SOS en mode
  // trek sans vraie rando, pour montrer a Chris le cockpit de chaque phase. EN
  // PROD la phase suit le SEUL lifecycle et le SOS le SEUL activeTrekIdProvider
  // (mode trek reel) : ce toggle DOIT disparaitre avant merge.
  bool _demoTrekMode = false;

  // Phase previsualisee en mode démo (R8). `null` = suit la phase reelle.
  // Permet a Chris de parcourir les 3 phases sans muter l'etat en base.
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
    final activeTrekId = ref.watch(activeTrekIdProvider).value;
    // PROD : `activeTrekId != null` est le SEUL discriminant. Le `|| _demoTrekMode`
    // est un ADDITIF DE DEMO (branche jetable) — a retirer avant merge.
    final inTrekMode = activeTrekId != null || _demoTrekMode;
    // R9 : le SOS n'apparait QU'en phase Randonner ET en mode trek reel/démo.
    final showSos = inTrekMode && phase == CockpitPhase.hike;

    // R9/R10 : main dominante (defaut droitier) -> cote des commandes critiques.
    final dominantHand = ref.watch(
      settingsProvider.select((s) => s.dominantHand),
    );
    final sosOnRight = DominantHandValues.isRight(dominantHand);

    // Progression derivee (R5) pour les coches des cartes de preparation.
    final prepProgress = _derivePrepProgress(lifecycle);

    return Scaffold(
      // AppHeader : titre + Retour + actions Informations / Profil + Accueil.
      // PARITE HUB ORIGINE (retours Chris) : acces Informations (i) + Profil
      // (person) remis a l'identique, places AVANT le bouton Accueil.
      appBar: AppHeader(
        title: trailTitle,
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
              const HubHeader(),
              const SizedBox(height: AppTheme.spacingLg),
              const HubWeatherCard(),
              const SizedBox(height: AppTheme.spacingBase),
              const HubTrekCard(),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Bandeau d'EN-TETE de phase (R3, teinte pleine) ---
              _PhaseHeaderBanner(phase: phase),
              const SizedBox(height: AppTheme.spacingBase),

              // --- UNE seule phase visible (R7) ---
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
  List<Widget> _buildPhase(
    BuildContext context,
    CockpitPhase phase,
    String trailId,
    CategoryIconColors cat,
    PlanningStepStatus prepProgress,
  ) {
    switch (phase) {
      case CockpitPhase.prepare:
        return _buildPrepare(context, trailId, cat, prepProgress);
      case CockpitPhase.hike:
        return _buildHike(context, trailId, cat);
      case CockpitPhase.after:
        return _buildAfter(context, trailId, cat);
    }
  }

  /// Phase « Préparer » (clone section GR20 :142) + coches R5 sur les sujets.
  List<Widget> _buildPrepare(
    BuildContext context,
    String trailId,
    CategoryIconColors cat,
    PlanningStepStatus prepProgress,
  ) {
    return [
      HubSection(
        title: t.hub.sections.prepare,
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
            icon: Icons.shopping_cart,
            title: t.hub.cards.shop,
            subtitle: t.hub.cards.shopSub,
            iconColor: cat.green,
            onTap: () => context.push('/trail/$trailId/shop'),
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

  /// Phase « Randonner » (clone section GR20 :297).
  ///
  /// VIGILANCE Chris (R7) : les fiches de PREPA TERRAIN (checklist/sac,
  /// dangers/incendie) restent ACCESSIBLES en rando via une ENTREE SECONDAIRE
  /// (« Revoir la préparation ») — on ne masque pas Préparer, on ne le met juste
  /// pas en mode principal.
  List<Widget> _buildHike(
    BuildContext context,
    String trailId,
    CategoryIconColors cat,
  ) {
    return [
      HubSection(
        title: t.hub.sections.hike,
        icon: Icons.hiking,
        iconColor: cat.greenLight, // GR20 Randonner -> vertMaquisLight
        cards: [
          QuickAccessCard(
            icon: Icons.navigation_outlined,
            title: t.hub.cards.navigation,
            subtitle: t.hub.cards.navigationSub,
            iconColor: cat.green,
            onTap: () => context.push('/map'),
          ),
          QuickAccessCard(
            icon: Icons.menu_book_outlined,
            title: t.hub.cards.journal,
            subtitle: t.hub.cards.journalSub,
            iconColor: cat.orange,
            onTap: () => context.push('/journal'),
          ),
          QuickAccessCard(
            icon: Icons.local_fire_department,
            title: t.hub.cards.fire,
            subtitle: t.hub.cards.fireSub,
            iconColor: cat.red, // GR20 Incendie -> rougeUrgence
            onTap: () => context.push('/trail/$trailId/fire-risk'),
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

  /// Phase « Après » (clone section GR20 :452 + diplome verrouillable :471-494).
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
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          if (demoPreview) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PhaseChip(
                  label: t.navPilote.prepare,
                  selected: phase == CockpitPhase.prepare,
                  onTap: () => onSelectPhase(CockpitPhase.prepare),
                ),
                _PhaseChip(
                  label: t.navPilote.hike,
                  selected: phase == CockpitPhase.hike,
                  onTap: () => onSelectPhase(CockpitPhase.hike),
                ),
                _PhaseChip(
                  label: t.navPilote.after,
                  selected: phase == CockpitPhase.after,
                  onTap: () => onSelectPhase(CockpitPhase.after),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        child: Text(
          label,
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
