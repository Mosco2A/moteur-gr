import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/trail_providers.dart';

/// Ecran detail d'une etape en mode trek.
///
/// Affiche les informations completes d'une etape chargee
/// via [stageByIdProvider]. Parametree par [stageId] (format: 'trailId-N').
/// Bouton retour vers /stages.
class TrekStageDetailScreen extends ConsumerWidget {
  const TrekStageDetailScreen({
    super.key,
    required this.stageId,
  });

  /// Identifiant de l'etape (format: 'trailId-N')
  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(stageByIdProvider(stageId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail etape'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/stages'),
        ),
      ),
      body: stageAsync.when(
        loading: () =>
            const LoadingOverlay(message: 'Chargement de l\'etape...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Impossible de charger l\'etape',
          subtitle: error.toString(),
        ),
        data: (stage) {
          if (stage == null) {
            return const EmptyState(
              icon: Icons.hiking,
              title: 'Etape introuvable',
            );
          }

          final hours = stage.estimatedDurationMinutes ~/ 60;
          final minutes = stage.estimatedDurationMinutes % 60;
          final duration = minutes > 0
              ? '${hours}h${minutes.toString().padLeft(2, '0')}'
              : '${hours}h';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stage.nameFr,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Chip(label: Text(stage.difficulty)),
                const SizedBox(height: 16),
                if (stage.descriptionFr.isNotEmpty) ...[
                  Text(
                    stage.descriptionFr,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                _InfoRow(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${stage.distance.toStringAsFixed(1)} km',
                ),
                _InfoRow(
                  icon: Icons.trending_up,
                  label: 'Denivele +',
                  value: '${stage.elevationGain} m',
                ),
                _InfoRow(
                  icon: Icons.trending_down,
                  label: 'Denivele -',
                  value: '${stage.elevationLoss} m',
                ),
                _InfoRow(
                  icon: Icons.schedule,
                  label: 'Duree estimee',
                  value: duration,
                ),
                const SizedBox(height: 24),
                Text(
                  'Coordonnees',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.flag,
                  label: 'Depart',
                  value:
                      '${stage.startLat.toStringAsFixed(4)}, ${stage.startLng.toStringAsFixed(4)}',
                ),
                _InfoRow(
                  icon: Icons.sports_score,
                  label: 'Arrivee',
                  value:
                      '${stage.endLat.toStringAsFixed(4)}, ${stage.endLng.toStringAsFixed(4)}',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Ligne d'information avec icone, label et valeur.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
