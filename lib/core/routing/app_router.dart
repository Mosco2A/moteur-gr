import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/settings_screen.dart';
import '../../features/trail/presentation/stage_detail_screen.dart';
import '../../features/trail/presentation/trail_detail_screen.dart';
import '../../features/trail/presentation/trail_list_screen.dart';

/// Configuration du routeur GoRouter.
///
/// Routes :
///   /trails              — Liste des sentiers
///   /trail/:id           — Detail d'un sentier
///   /trail/:id/stage/:num — Detail d'une etape
///   /settings            — Parametres
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
      ],
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(
      child: Text('Page introuvable : ${state.uri.path}'),
    ),
  ),
);
