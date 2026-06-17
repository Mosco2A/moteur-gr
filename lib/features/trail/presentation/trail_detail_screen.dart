import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../providers/stages_provider.dart';
import '../widgets/stage_list_tile.dart';

/// Écran détail d'un sentier.
///
/// Affiche un header avec les infos du sentier (nom, région,
/// distance totale, dénivelé total) puis la liste scrollable
/// des étapes chargées via stagesProvider.
/// Gère les états loading / error / data / vide.
class TrailDetailScreen extends ConsumerWidget {
  const TrailDetailScreen({super.key, required this.trailId});

  /// Identifiant du sentier à afficher
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(trailConfigProvider);
    final stagesAsync = ref.watch(stagesProvider(trailId));
    final theme = Theme.of(context);
    final t = Translations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(config.displayName)),
      body: Column(
        children: [
          // Header du sentier avec infos principales
          _TrailHeader(config: config, theme: theme),
          const SizedBox(height: AppTheme.spacingSm),
          // Titre de section
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
            ),
            child: SectionHeader(
              title: 'Étapes',
              icon: Icons.hiking,
            ),
          ),
          // Liste des étapes (AsyncValue)
          Expanded(
            child: stagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Impossible de charger les étapes',
                subtitle: error.toString(),
              ),
              data: (stages) {
                if (stages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.hiking,
                    title: 'Aucune étape disponible',
                    subtitle: 'Les données du sentier ne sont pas '
                        'encore chargées.',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(
                    top: AppTheme.spacingSm,
                    bottom: AppTheme.spacingXl,
                  ),
                  itemCount: stages.length,
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    return StageListTile(
                      stage: stage,
                      onTap: () => context.go(
                        '/trail/$trailId/stage/${stage.stageNumber}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Boutons d'action en bas
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action primaire : ENTRER dans le sentier (cablage nav #88246).
              // Active ce sentier (selectedTrailIdProvider) puis ouvre le shell
              // sur /map -> entree du coeur de l'app depuis le lien profond.
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: t.catalog.a11y.enterButton(nom: config.displayName),
                  child: FilledButton.icon(
                    key: const ValueKey('trail-detail-enter'),
                    onPressed: () => _enterTrail(context, ref),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(t.catalog.enter),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              // Actions secondaires cote a cote (compactes) : planifier / carte
              // hors-shell. Disposees en Row pour ne pas allonger la barre.
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/trail/$trailId/planning'),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Planifier'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/trail/$trailId/map'),
                      icon: const Icon(Icons.terrain),
                      label: const Text('Voir la carte'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Entre dans le sentier affiche : ecrit la selection (le moteur entier suit
  /// via trailConfigProvider) puis ouvre le shell sur l'onglet Carte.
  void _enterTrail(BuildContext context, WidgetRef ref) {
    ref.read(selectedTrailIdProvider.notifier).state = trailId;
    context.go('/map');
  }
}

/// Header affichant les infos principales du sentier
class _TrailHeader extends StatelessWidget {
  const _TrailHeader({required this.config, required this.theme});

  final dynamic config;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withAlpha(60),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nom d'affichage
          Text(
            config.displayName,
            style: theme.textTheme.headlineMedium,
          ),
          if ((config.tagline as String).isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              config.tagline,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingMd),
          // Infos chiffrées — Wrap pour ne pas déborder à textScale 2x
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            children: [
              _InfoChip(
                icon: Icons.place,
                label: config.region,
                theme: theme,
              ),
              _InfoChip(
                icon: Icons.straighten,
                label: '${config.totalDistanceKm} km',
                theme: theme,
              ),
              _InfoChip(
                icon: Icons.trending_up,
                label: '${config.totalElevationGain} m D+',
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petit chip d'information avec icône
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            icon,
            size: 16,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
