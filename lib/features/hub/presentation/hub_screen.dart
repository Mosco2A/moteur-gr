import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../../safety/presentation/sos_button.dart';
import '../../trek/providers/tracking_providers.dart';
import 'widgets/hub_header.dart';
import 'widgets/hub_section.dart';
import 'widgets/hub_trek_card.dart';
import 'widgets/hub_weather_card.dart';
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
///   * D3 — tuile meteo = STUB ([HubWeatherCard]) ;
///   * D4 — aucune section Communaute/social ;
///   * D5 — cartes sans ecran cible (Ravitaillement / Transport / Recap)
///     DIFFEREES.
///
/// Regle S8 « zero route morte » : seules les cartes dont la cible existe
/// (routes R01..R13 + `/training`) sont rendues. Tous les libelles passent par
/// Slang (`t.hub.*`, `t.nav.*`) — zero texte en dur, aucun libelle propre a un
/// sentier particulier (cloisonnement moteur generique).
class HubScreen extends ConsumerWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailTitle = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    // CTA « Demarrer » (RF-7) et FAB SOS ne s'affichent que hors trek reel actif.
    final trekStatus = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final isTrekActive =
        trekStatus == TrackingSessionStatus.recording ||
        trekStatus == TrackingSessionStatus.paused;

    return Scaffold(
      appBar: AppBar(
        title: Text(trailTitle),
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
      // FAB : Feedback (toujours) + SOS (si trek actif, gere par SosButton qui
      // se masque lui-meme hors trek). RF-12/RM-3.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SosButton(),
          const SizedBox(height: AppTheme.spacingMd),
          FloatingActionButton.extended(
            heroTag: 'hub_feedback',
            onPressed: () => context.push('/trail/$trailId/feedback'),
            icon: const Icon(Icons.feedback_outlined),
            label: Text(t.hub.fab.feedback),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            // Salutation (RF-3) — SW-SKIN-L5 : en-tete a degrade d'accent
            // (AppGradientHeader). L'espacement bas, jadis porte par HubHeader,
            // est ici explicite (le header est desormais un bandeau plein).
            const HubHeader(),
            const SizedBox(height: AppTheme.spacingLg),
            // Tuile meteo reelle (AM-3, LOT-B) : ConsumerWidget (const OK).
            const HubWeatherCard(),
            const SizedBox(height: AppTheme.spacingBase),
            // Carte principale trek (RF-4, 2 etats).
            const HubTrekCard(),
            // CTA « Demarrer » plein largeur si aucun trek reel actif (RF-7).
            if (!isTrekActive) ...[
              const SizedBox(height: AppTheme.spacingBase),
              // SW-SKIN-L3e : OutlinedButton.icon -> AppButton outline, pleine
              // largeur (SizedBox width infinity conserve). Libelle inchange.
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  icon: Icons.play_arrow,
                  label: t.hub.startCta,
                  onPressed: () => context.push('/trail/$trailId/planning'),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Preparer (RF-6) ---
            HubSection(
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
                  // PARITE GR20 (#99433) + fix crash retour : « Itineraire »
                  // ouvre desormais l'ecran deroule des etapes (route hors-shell
                  // via push) au lieu de context.go('/map') qui remplacait la
                  // pile (bascule d'onglet) et plantait au retour
                  // (currentConfiguration.isNotEmpty).
                  onTap: () => context.push('/trail/$trailId/itinerary'),
                ),
                QuickAccessCard(
                  icon: Icons.event_note_outlined,
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
                  icon: Icons.calendar_month,
                  title: t.hub.cards.calendar,
                  subtitle: t.hub.cards.calendarSub,
                  onTap: () => context.push('/trail/$trailId/calendar'),
                ),
                // PARITE GR20 (#99460) — NUITEES : assistant « Reserver vos
                // nuits » (type de nuitee + reserve par nuit du programme).
                // Route hors-shell atteinte via `context.push` -> retour propre
                // (pile preservee, jamais context.go qui viderait la pile).
                QuickAccessCard(
                  icon: Icons.cabin,
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
                  icon: Icons.directions_bus,
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
                  icon: Icons.shopping_cart,
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

            // --- Section Randonner (RF-8) ---
            HubSection(
              title: t.hub.sections.hike,
              icon: Icons.hiking,
              cards: [
                QuickAccessCard(
                  icon: Icons.navigation_outlined,
                  title: t.hub.cards.navigation,
                  subtitle: t.hub.cards.navigationSub,
                  onTap: () => context.go('/map'),
                ),
                QuickAccessCard(
                  icon: Icons.menu_book_outlined,
                  title: t.hub.cards.journal,
                  subtitle: t.hub.cards.journalSub,
                  onTap: () => context.go('/journal'),
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
                  icon: Icons.local_fire_department,
                  title: t.hub.cards.fire,
                  subtitle: t.hub.cards.fireSub,
                  onTap: () => context.push('/trail/$trailId/fire-risk'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Informations (RF-9) ---
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
                // E33/E34 (LOT D/D2) : cablage feature Guides villes (orpheline).
                // Route existante -> carte autorisee (regle S8 zero route morte).
                QuickAccessCard(
                  icon: Icons.location_city,
                  title: t.hub.cards.townGuides,
                  subtitle: t.hub.cards.townGuidesSub,
                  onTap: () => context.push('/trail/$trailId/guides'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- Section Apres le trek (RF-10) ---
            // PARITE GR20, LOT 3 (#99433) : la section « Apres le trek » expose
            // desormais la carte « Mon aventure » (recap des stats de la session
            // reelle) EN PLUS du Diplome, comme le HUB GR20 (#U04). Les deux
            // routes existent toujours (regle S8 « zero route morte ») ; la garde
            // (recap accessible si termine/abandonne/vitrine ; diplome verrouille
            // hors finisher, deverrouille en vitrine) est portee par les ecrans.
            HubSection(
              title: t.hub.sections.after,
              icon: Icons.emoji_events_outlined,
              cards: [
                QuickAccessCard(
                  icon: Icons.landscape_outlined,
                  title: t.hub.cards.recap,
                  subtitle: t.hub.cards.recapSub,
                  onTap: () => context.push('/trail/$trailId/recap'),
                ),
                // PARITE GR20 (Import GPX) — decision Skynet : point d'entree du
                // HUB vers l'ecran d'import (clone GR20 generalise, data-driven).
                // Cote GR20 l'ecran existait mais etait ORPHELIN (aucune entree
                // UI) ; on comble le manque cote StepWays. Importer une trace
                // enregistree par une autre app (Strava, Garmin…) pour generer
                // un recapitulatif. Icone `upload_file` (parite GR20). Route
                // hors-shell atteinte via `context.push` (retour propre, pile
                // preservee — jamais context.go qui viderait la pile).
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
