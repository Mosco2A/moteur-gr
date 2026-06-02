import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/profile_screen.dart';
import '../../features/checklist/presentation/checklist_screen.dart';
import '../../features/diploma/presentation/diploma_screen.dart';
import '../../features/feasibility/presentation/feasibility_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/journal/presentation/journal_screen.dart';
import '../../features/map/presentation/trail_map_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tips/presentation/tips_screen.dart';
import '../../features/trail/presentation/no_data_screen.dart';
import '../../features/trail/presentation/stage_detail_screen.dart';
import '../../features/trail/presentation/trail_detail_screen.dart';
import '../../features/trail/presentation/trail_list_screen.dart';
import '../../features/group/presentation/group_screen.dart';
import '../../features/trail/presentation/trail_catalog_screen.dart';
import '../../features/goodies/presentation/goodies_catalog_screen.dart';
import '../../features/booking/presentation/booking_screen.dart';
import '../../features/safety/presentation/emergency_screen.dart';
import '../config/feature_flags.dart';
import '../../features/trek/presentation/map/map_screen.dart';
import '../../features/trek/presentation/stages/stage_list_screen.dart'
    as trek_stages;
import '../../features/trek/presentation/planning/planning_screen.dart'
    as trek_planning;
import '../../features/trek/presentation/stages/stage_detail_screen.dart'
    as trek_detail;

/// Configuration du routeur GoRouter.
///
/// Routes :
///   /trails                      - Liste des sentiers
///   /trail/:id                   - Detail d'un sentier
///   /trail/:id/stage/:num        - Detail d'une etape
///   /trail/:id/map               - Carte du trace GPX
///   /trail/:id/planning          - Planning de repartition
///   /trail/:id/checklist         - Checklist materiel
///   /trail/:id/feasibility       - Questionnaire faisabilite
///   /trail/:id/tips              - Fiches conseils
///   /trail/:id/journal           - Journal de trek
///   /trail/:id/diploma           - Diplome de fin de trek
///   /trail/:id/feedback          - Feedback in-app
///   /settings                    - Parametres
///   /profile                     - Profil utilisateur
///   /group/:id                   - Groupe localisation partagee
///   /planning                    - Planning itineraire (trek)
///   /stages                      - Liste des etapes (trek)
///   /stages/:id                  - Detail d'une etape (trek)
///   /catalog                     - Catalogue de sentiers (telechargement)
///   /goodies                     - Boutique goodies (gardee par FeatureFlags)
///   /booking                     - Reservation (stub, gardee par FeatureFlags)
///   /emergency                   - Contacts d'urgence (112, PGHM, personnels)
///   /no-data                     - Ecran bloquant sans donnees telechargees
final appRouter = GoRouter(
  initialLocation: '/trails',
  redirect: _guardNoData,
  routes: [
    GoRoute(
      path: '/trails',
      name: 'trails',
      builder: (context, state) => const TrailListScreen(),
    ),
    GoRoute(
      path: '/trail/:id',
      name: 'trail-detail',
      builder: (context, state) {
        final trailId = state.pathParameters['id'] ?? '';
        return TrailDetailScreen(trailId: trailId);
      },
      routes: [
        GoRoute(
          path: 'stage/:num',
          name: 'stage-detail',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            final stageNum =
                int.tryParse(state.pathParameters['num'] ?? '') ?? 1;
            return StageDetailScreen(
              trailId: trailId,
              stageNumber: stageNum,
            );
          },
        ),
        GoRoute(
          path: 'map',
          name: 'trail-map',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return TrailMapScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'planning',
          name: 'trail-planning',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return PlanningScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'checklist',
          name: 'trail-checklist',
          builder: (context, state) => const ChecklistScreen(),
        ),
        GoRoute(
          path: 'feasibility',
          name: 'trail-feasibility',
          builder: (context, state) => const FeasibilityScreen(),
        ),
        GoRoute(
          path: 'tips',
          name: 'trail-tips',
          builder: (context, state) => const TipsScreen(),
        ),
        GoRoute(
          path: 'journal',
          name: 'trail-journal',
          builder: (context, state) {
            final trailId = state.pathParameters['id'] ?? '';
            return JournalScreen(trailId: trailId);
          },
        ),
        GoRoute(
          path: 'diploma',
          name: 'trail-diploma',
          builder: (context, state) => const DiplomaScreen(),
        ),
        GoRoute(
          path: 'feedback',
          name: 'trail-feedback',
          builder: (context, state) => const FeedbackScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/stages',
      name: 'stages',
      builder: (context, state) {
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        return trek_stages.StageListScreen(trailId: trailId);
      },
      routes: [
        GoRoute(
          path: ':id',
          name: 'stage-by-id',
          builder: (context, state) {
            final trailId = state.uri.queryParameters['trailId'] ?? '';
            final stageId =
                int.tryParse(state.pathParameters['id'] ?? '') ?? 1;
            return trek_detail.StageDetailScreen(
              trailId: trailId,
              stageId: stageId,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/map',
      name: 'map',
      builder: (context, state) {
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        return MapScreen(trailId: trailId);
      },
    ),
    GoRoute(
      path: '/planning',
      name: 'trek-planning',
      builder: (context, state) =>
          const trek_planning.TrekPlanningScreen(),
    ),
    GoRoute(
      path: '/group/:id',
      name: 'group',
      builder: (context, state) {
        final trailId = state.pathParameters['id'] ?? '';
        return GroupScreen(trailId: trailId);
      },
    ),
    GoRoute(
      path: '/catalog',
      name: 'catalog',
      builder: (context, state) => const TrailCatalogScreen(),
    ),
    GoRoute(
      path: '/goodies',
      name: 'goodies',
      redirect: (context, state) {
        // Garde par feature flag -- redirige vers /trails si desactive
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        if (!FeatureFlags.isGoodiesEnabled(trailId)) return '/trails';
        return null;
      },
      builder: (context, state) => const GoodiesCatalogScreen(),
    ),
    // E5.13 : Reservation (stub) -- garde par FeatureFlags
    GoRoute(
      path: '/booking',
      name: 'booking',
      redirect: (context, state) {
        // Garde par feature flag -- redirige vers /trails si desactive
        final trailId = state.uri.queryParameters['trailId'] ?? '';
        if (!FeatureFlags.isBookingEnabled(trailId)) return '/trails';
        return null;
      },
      builder: (context, state) => const BookingScreen(),
    ),
    // E5.14a : Contacts d'urgence (112, PGHM, contacts personnels)
    GoRoute(
      path: '/emergency',
      name: 'emergency',
      builder: (context, state) => const EmergencyScreen(),
    ),
    GoRoute(
      path: '/no-data',
      name: 'no-data',
      builder: (context, state) => const NoDataScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(
      child: Text('Page introuvable : ${state.uri.path}'),
    ),
  ),
);

/// Flag indiquant si des sentiers sont telecharges.
///
/// Mis a jour par le CatalogNotifier apres chaque chargement.
/// Quand false, le guard redirige vers /no-data.
/// Quand true, navigation normale.
bool hasDownloadedTrails = true;

/// Guard de redirection : si aucun sentier telecharge,
/// redirige vers /no-data (sauf /catalog et /no-data eux-memes).
String? _guardNoData(BuildContext context, GoRouterState state) {
  // Routes exclues du guard (doivent rester accessibles)
  final excludedPaths = ['/no-data', '/catalog', '/settings', '/profile', '/emergency'];
  if (excludedPaths.contains(state.uri.path)) return null;

  // Si aucun sentier telecharge, rediriger vers l'ecran bloquant
  if (!hasDownloadedTrails) return '/no-data';

  return null;
}
