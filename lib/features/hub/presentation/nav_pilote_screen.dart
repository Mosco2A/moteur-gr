import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/contextual_action_bar.dart';
import '../../safety/presentation/sos_confirmation_dialog.dart';
import '../../treks/providers/my_treks_provider.dart';
import '../../trek/providers/gps_providers.dart';
import 'widgets/hub_header.dart';
import 'widgets/hub_section.dart';
import 'widgets/hub_trek_card.dart';
import 'widgets/hub_weather_card.dart';
import 'widgets/quick_access_card.dart';

/// ECRAN-PILOTE de la refonte NAVIGATION StepWays (LOT 3, methode D2).
///
/// DEMONSTRATEUR VISUEL JETABLE, expose HORS-SHELL sur `/nav-pilote`, destine a
/// la validation visuelle par Chris AVANT de derouler les ~40 ecrans. Il ne
/// touche PAS au `StatefulShellRoute` : le reste de l'app continue de tourner a
/// l'identique. Le pilote redessine le COCKPIT (contenu du [HubScreen]) avec la
/// NOUVELLE enveloppe de nav :
///  - en HAUT : [AppHeader] (barre systeme heritee de l'AppBarTheme — meme look
///    que l'AppBar actuelle ; back Android centralise via PopScope) ;
///  - en BAS : [ContextualActionBar] (barre d'ACTIONS, PAS d'onglets) —
///    Preparer / Randonner / Apres, plus SOS SAILLANT UNIQUEMENT en MODE TREK.
///
/// Comme le pilote est HORS du shell, la `NavigationBar` du shell n'apparait
/// pas : pas de double bottom bar (exigence de la tache).
///
/// MODE TREK (SOS) : le discriminant est [activeTrekIdProvider] (non-null =
/// rando active|paused, `TrekLifecycleState.inProgress`). Hors mode trek : PAS
/// de SOS dans la barre (AUDIT §3 #E03 / §M-2 — SOS = action de securite
/// saillante, jamais un item de nav ; present seulement quand il a du sens).
///
/// GARDE-FOUS LOOK & FEEL : le CORPS reutilise tel quel les briques du HUB
/// existant ([HubHeader] banniere de marque, [HubWeatherCard], [HubTrekCard],
/// [HubSection] + [QuickAccessCard]) — aucun style reinvente, `AppGradientHeader`
/// intact (G2), tokens `AppTheme` inchanges (G3). Zero texte en dur (Slang).
class NavPiloteScreen extends ConsumerStatefulWidget {
  const NavPiloteScreen({super.key});

  @override
  ConsumerState<NavPiloteScreen> createState() => _NavPiloteScreenState();
}

class _NavPiloteScreenState extends ConsumerState<NavPiloteScreen> {
  // Ancres de defilement : la barre d'actions Preparer/Randonner/Apres amene la
  // section correspondante a l'ecran (demonstrateur — comportement visible).
  final _prepareKey = GlobalKey();
  final _hikeKey = GlobalKey();
  final _afterKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    // MODE TREK : rando active|paused -> SOS present. Sinon absent.
    // activeTrekIdProvider est un FutureProvider<String?> : on ne montre le SOS
    // qu'une fois resolu ET non-null (etat neutre non clignotant pendant le
    // loading — AUDIT §m-1).
    final activeTrekId = ref.watch(activeTrekIdProvider).value;
    final inTrekMode = activeTrekId != null;

    // Barre d'ACTIONS du cockpit : Preparer / Randonner / Apres (+ SOS si trek).
    final actions = <ContextualAction>[
      ContextualAction(
        icon: Icons.assignment_outlined,
        label: t.navPilote.prepare,
        onPressed: () => _scrollTo(_prepareKey),
      ),
      ContextualAction(
        icon: Icons.hiking,
        label: t.navPilote.hike,
        onPressed: () => _scrollTo(_hikeKey),
      ),
      ContextualAction(
        icon: Icons.emoji_events_outlined,
        label: t.navPilote.after,
        onPressed: () => _scrollTo(_afterKey),
      ),
      if (inTrekMode)
        ContextualAction(
          icon: Icons.emergency,
          label: t.navPilote.sos,
          onPressed: () => _showSos(context),
          salient: true,
          color: AppTheme.rougeUrgence,
          semanticLabel: t.a11y.sos,
        ),
    ];

    return Scaffold(
      appBar: AppHeader(title: trailTitle),
      // Barre d'ACTIONS en bas (BottomAppBar) — distincte d'une NavigationBar
      // (garde-fou G4/M-1). Absente si aucune action (jamais le cas ici).
      bottomNavigationBar: ContextualActionBar(actions: actions),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            // --- CORPS : reutilise les briques du HUB (look inchange) ---
            const HubHeader(),
            const SizedBox(height: AppTheme.spacingLg),
            const HubWeatherCard(),
            const SizedBox(height: AppTheme.spacingBase),
            const HubTrekCard(),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Preparer (ancre barre d'actions) ---
            HubSection(
              key: _prepareKey,
              title: t.hub.sections.prepare,
              icon: Icons.assignment_outlined,
              cards: [
                QuickAccessCard(
                  icon: Icons.quiz_outlined,
                  title: t.hub.cards.feasibility,
                  subtitle: t.hub.cards.feasibilitySub,
                  onTap: () => context.push('/trail/$trailId/feasibility'),
                ),
                QuickAccessCard(
                  icon: Icons.route_outlined,
                  title: t.hub.cards.itinerary,
                  subtitle: t.hub.cards.itinerarySub,
                  onTap: () => context.push('/trail/$trailId/itinerary'),
                ),
                QuickAccessCard(
                  icon: Icons.event_note_outlined,
                  title: t.hub.cards.programme,
                  subtitle: t.hub.cards.programmeSub,
                  onTap: () => context.push('/trail/$trailId/planning'),
                ),
                QuickAccessCard(
                  icon: Icons.calendar_month,
                  title: t.hub.cards.calendar,
                  subtitle: t.hub.cards.calendarSub,
                  onTap: () => context.push('/trail/$trailId/calendar'),
                ),
                QuickAccessCard(
                  icon: Icons.cabin,
                  title: t.hub.cards.nuitees,
                  subtitle: t.hub.cards.nuiteesSub,
                  onTap: () => context.push('/trail/$trailId/nuitees'),
                ),
                QuickAccessCard(
                  icon: Icons.directions_bus,
                  title: t.hub.cards.transport,
                  subtitle: t.hub.cards.transportSub,
                  onTap: () => context.push('/trail/$trailId/transport'),
                ),
                QuickAccessCard(
                  icon: Icons.shopping_cart,
                  title: t.hub.cards.shop,
                  subtitle: t.hub.cards.shopSub,
                  onTap: () => context.push('/trail/$trailId/shop'),
                ),
                QuickAccessCard(
                  icon: Icons.summarize,
                  title: t.hub.cards.resume,
                  subtitle: t.hub.cards.resumeSub,
                  onTap: () => context.push('/trail/$trailId/summary'),
                ),
                QuickAccessCard(
                  icon: Icons.checklist_rtl,
                  title: t.hub.cards.checklist,
                  subtitle: t.hub.cards.checklistSub,
                  onTap: () => context.push('/trail/$trailId/checklist'),
                ),
                QuickAccessCard(
                  icon: Icons.fitness_center,
                  title: t.hub.cards.training,
                  subtitle: t.hub.cards.trainingSub,
                  onTap: () => context.push('/training'),
                ),
                QuickAccessCard(
                  icon: Icons.explore_outlined,
                  title: t.hub.cards.offline,
                  subtitle: t.hub.cards.offlineSub,
                  onTap: () => context.push('/catalog'),
                ),
                QuickAccessCard(
                  icon: Icons.groups_outlined,
                  title: t.hub.cards.group,
                  subtitle: t.hub.cards.groupSub,
                  onTap: () => context.push('/group/$trailId'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Randonner (ancre barre d'actions) ---
            HubSection(
              key: _hikeKey,
              title: t.hub.sections.hike,
              icon: Icons.hiking,
              cards: [
                QuickAccessCard(
                  icon: Icons.navigation_outlined,
                  title: t.hub.cards.navigation,
                  subtitle: t.hub.cards.navigationSub,
                  // Pilote : push (retour propre via AppHeader) plutot que go
                  // (qui basculait d'onglet dans le shell). Coherent avec la
                  // logique hub-and-push cible (SPEC §5).
                  onTap: () => context.push('/map'),
                ),
                QuickAccessCard(
                  icon: Icons.menu_book_outlined,
                  title: t.hub.cards.journal,
                  subtitle: t.hub.cards.journalSub,
                  onTap: () => context.push('/journal'),
                ),
                QuickAccessCard(
                  icon: Icons.local_fire_department,
                  title: t.hub.cards.fire,
                  subtitle: t.hub.cards.fireSub,
                  onTap: () => context.push('/trail/$trailId/fire-risk'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Informations ---
            HubSection(
              title: t.hub.sections.info,
              icon: Icons.info_outline,
              cards: [
                QuickAccessCard(
                  icon: Icons.hotel_outlined,
                  title: t.hub.cards.accommodations,
                  subtitle: t.hub.cards.accommodationsSub,
                  onTap: () => context.push('/accommodations-nearby'),
                ),
                QuickAccessCard(
                  icon: Icons.lightbulb_outline,
                  title: t.hub.cards.tips,
                  subtitle: t.hub.cards.tipsSub,
                  onTap: () => context.push('/trail/$trailId/tips'),
                ),
                QuickAccessCard(
                  icon: Icons.location_city,
                  title: t.hub.cards.townGuides,
                  subtitle: t.hub.cards.townGuidesSub,
                  onTap: () => context.push('/trail/$trailId/guides'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Apres le trek (ancre barre d'actions) ---
            HubSection(
              key: _afterKey,
              title: t.hub.sections.after,
              icon: Icons.emoji_events_outlined,
              cards: [
                QuickAccessCard(
                  icon: Icons.landscape_outlined,
                  title: t.hub.cards.recap,
                  subtitle: t.hub.cards.recapSub,
                  onTap: () => context.push('/trail/$trailId/recap'),
                ),
                QuickAccessCard(
                  icon: Icons.upload_file,
                  title: t.hub.cards.importGpx,
                  subtitle: t.hub.cards.importGpxSub,
                  onTap: () => context.push('/trail/$trailId/import-gpx'),
                ),
                QuickAccessCard(
                  icon: Icons.workspace_premium_outlined,
                  title: t.hub.cards.diploma,
                  subtitle: t.hub.cards.diplomaSub,
                  onTap: () => context.push('/trail/$trailId/diploma'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
