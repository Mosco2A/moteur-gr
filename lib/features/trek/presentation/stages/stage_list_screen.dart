import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/stage.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../trail/providers/stages_provider.dart';

/// Ecran liste des etapes d'un sentier.
///
/// Consumer widget utilisant AsyncValue.when() sur stagesProvider.
/// Affiche LoadingView / ErrorView / ListView.builder avec _StageCard.
/// Les etapes sont triees par stageNumber (ordre d'affichage).
/// Utilise select() pour eviter un full rebuild.
class StageListScreen extends ConsumerWidget {
  const StageListScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on affiche les etapes.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(
      stagesProvider(trailId).select((async) => async),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Etapes'),
      ),
      body: stagesAsync.when(
        loading: () => const LoadingView(
          message: 'Chargement des etapes...',
        ),
        error: (error, _) => ErrorView(
          message: 'Impossible de charger les etapes',
          onRetry: () => ref.invalidate(stagesProvider(trailId)),
        ),
        data: (stages) {
          if (stages.isEmpty) {
            return const Center(
              child: Text('Aucune etape disponible'),
            );
          }

          // Tri par stageNumber (orderIndex)
          final sorted = List.of(stages)
            ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _StageCard(stage: sorted[index]);
            },
          );
        },
      ),
    );
  }
}

/// Carte placeholder pour une etape.
///
/// ListTile dans un Card -- sera remplacee par un widget riche en E2.4b.
class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});

  final StageModel stage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text('${stage.stageNumber}'),
        ),
        title: Text(stage.name),
        subtitle: Text(
          '${stage.distanceKm.toStringAsFixed(1)} km  '
          'D+ ${stage.elevationGainM} m',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
