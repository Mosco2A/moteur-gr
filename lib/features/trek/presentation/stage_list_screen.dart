import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/trail_providers.dart';

/// Ecran liste des etapes du sentier actif en mode trek.
///
/// Affiche toutes les etapes chargees via [trekStagesProvider].
/// Chaque etape est un ListTile navigant vers /stages/:id.
/// Utilise [trailConfigProvider] pour le nom du sentier dans l'AppBar.
class StageListScreen extends ConsumerWidget {
  const StageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(trekStagesProvider);
    final trailName = ref.watch(
      trailConfigProvider.select((config) => config.displayName),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Etapes - $trailName'),
      ),
      body: stagesAsync.when(
        loading: () =>
            const LoadingOverlay(message: 'Chargement des etapes...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Impossible de charger les etapes',
          subtitle: error.toString(),
        ),
        data: (stages) {
          if (stages.isEmpty) {
            return const EmptyState(
              icon: Icons.hiking,
              title: 'Aucune etape',
              subtitle: 'Ce sentier ne contient pas encore d\'etapes.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: stages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final stage = stages[index];
              final hours = stage.estimatedDurationMinutes ~/ 60;
              final minutes = stage.estimatedDurationMinutes % 60;
              final duration = minutes > 0
                  ? '${hours}h${minutes.toString().padLeft(2, '0')}'
                  : '${hours}h';

              return ListTile(
                leading: CircleAvatar(
                  child: Text('${stage.orderIndex + 1}'),
                ),
                title: Text(stage.nameFr),
                subtitle: Text(
                  '${stage.distance.toStringAsFixed(1)} km · '
                  'D+ ${stage.elevationGain} m · $duration',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/stages/${stage.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
