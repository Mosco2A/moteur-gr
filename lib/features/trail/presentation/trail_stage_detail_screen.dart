import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../shared/widgets/stage_number_badge.dart';
import '../providers/pois_provider.dart';
import '../providers/stages_provider.dart';
import '../widgets/difficulty_badge.dart';
import '../widgets/poi_tile.dart';
import '../widgets/stage_list_tile.dart';
import '../widgets/stage_stats_section.dart';

/// Écran détail d'une étape.
///
/// Affiche toutes les infos de l'étape : nom, description,
/// distance, dénivelé D+/D-, difficulté, durée estimée,
/// coordonnées départ/arrivée. Liste les POIs associés.
/// Bouton vers la carte centré sur l'étape.
class TrailStageDetailScreen extends ConsumerWidget {
  const TrailStageDetailScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
  });

  /// Identifiant du sentier parent
  final String trailId;

  /// Numéro de l'étape à afficher
  final int stageNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(stagesProvider(trailId));
    final poisAsync = ref.watch(poisProvider(trailId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Étape $stageNumber')),
      body: stagesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Impossible de charger l\'étape',
          subtitle: error.toString(),
        ),
        data: (stages) {
          final stage = stages.where(
            (s) => s.stageNumber == stageNumber,
          ).firstOrNull;

          if (stage == null) {
            return const EmptyState(
              icon: Icons.hiking,
              title: 'Étape introuvable',
            );
          }

          // Filtrer les POIs de cette étape
          final pois = poisAsync.valueOrNull
                  ?.where((p) => p.stageNumber == stageNumber)
                  .toList() ??
              [];

          final duration = StageListTile.estimatedHours(stage);
          final formattedDuration =
              StageListTile.formatDuration(duration);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro (Hero depuis la liste — E5.5a), nom et difficulté
                Row(
                  children: [
                    StageNumberBadge(number: stage.stageNumber),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        stage.name,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    DifficultyBadge(difficulty: stage.difficulty),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingMd),
                // Description (si présente)
                if (stage.description.isNotEmpty) ...[
                  Text(
                    stage.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                ],
                // Statistiques
                StageStatsSection(
                  stage: stage,
                  formattedDuration: formattedDuration,
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // Coordonnées
                StageCoordinatesSection(stage: stage),
                const SizedBox(height: AppTheme.spacingLg),
                // Points d'intérêt
                const SectionHeader(
                  title: 'Points d\'intérêt',
                  icon: Icons.place,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                if (pois.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.spacingBase,
                    ),
                    child: Text(
                      'Aucun point d\'intérêt pour cette étape.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  )
                else
                  ...pois.map((poi) => PoiTile(poi: poi)),
                const SizedBox(height: AppTheme.spacingLg),
                // Bouton vers la carte
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => GoRouter.of(context).go(
                      '/trail/$trailId/map',
                    ),
                    icon: const Icon(Icons.terrain),
                    label: const Text('Voir sur la carte'),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingBase),
              ],
            ),
          );
        },
      ),
    );
  }
}
