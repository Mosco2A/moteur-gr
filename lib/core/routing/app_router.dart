import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/map/presentation/trail_map_screen.dart';
import '../../features/trek/presentation/map/map_screen.dart';
import '../../features/trek/presentation/stage_detail_screen.dart';
import '../../features/trek/presentation/stage_list_screen.dart';
import '../../features/planning/presentation/planning_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/trail/presentation/stage_detail_screen.dart';
import '../../features/trail/presentation/trail_detail_screen.dart';
import '../../features/trail/presentation/trail_list_screen.dart';

/// Configuration du routeur GoRouter.
///
/// Routes :
///   /trails                — Liste des sentiers
///   /trail/:id             — Détail d'un sentier
///   /trail/:id/stage/:num  — Détail d'une étape
///   /trail/:id/map         — Carte du tracé GPX
///   /trail/:id/planning    — Planning de répartition
///   /settings              — Paramètres
///   /map                   — Carte trek (assemblage complet)
///   /stages                — Liste des étapes (mode trek)
///   /stages/:id            — Détail d'une étape (mode trek)
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
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/map',
      name: 'trek-map',
      builder: (context, state) => const MapScreen(),
    ),
    GoRoute(
      path: '/stages',
      name: 'trek-stages',
      builder: (context, state) => const StageListScreen(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'trek-stage-detail',
          builder: (context, state) {
            final stageId = state.pathParameters['id'] ?? '';
            return TrekStageDetailScreen(stageId: stageId);
          },
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(
      child: Text('Page introuvable : ${state.uri.path}'),
    ),
  ),
);
