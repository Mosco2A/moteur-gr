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
import '../../features/trail/presentation/stage_detail_screen.dart';
import '../../features/trail/presentation/trail_detail_screen.dart';
import '../../features/trail/presentation/trail_list_screen.dart';
import '../../features/trail/presentation/trail_catalog_screen.dart';

/// Configuration du routeur GoRouter.
///
/// Routes :
///   /trails                      - Liste des sentiers
///   /trail/:id                   - Détail d'un sentier
///   /trail/:id/stage/:num        - Détail d'une étape
///   /trail/:id/map               - Carte du tracé GPX
///   /trail/:id/planning          - Planning de répartition
///   /trail/:id/checklist         - Checklist matériel
///   /trail/:id/feasibility       - Questionnaire faisabilité
///   /trail/:id/tips              - Fiches conseils
///   /trail/:id/journal           - Journal de trek
///   /trail/:id/diploma           - Diplôme de fin de trek
///   /trail/:id/feedback          - Feedback in-app
///   /settings                    - Paramètres
///   /profile                     - Profil utilisateur
///   /catalog                     - Catalogue de sentiers (telechargement)
final appRouter = GoRouter(
  initialLocation: '/trails',
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
      path: '/catalog',
      name: 'catalog',
      builder: (context, state) => const TrailCatalogScreen(),
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
