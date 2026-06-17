import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_selection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';

/// Ecran catalogue des sentiers disponibles.
///
/// Cablage navigation (design #88246) : en P2-P3 (donnees fictives, sans
/// Firebase, #84627) le catalogue affiche la liste des sentiers EMBARQUES
/// ([availableTrailsProvider] = catalogue statique [TrailCatalog]) — toujours
/// presents et resolvables, donc navigables hors ligne. Le manifeste distant
/// Drift ([catalogStateProvider]) reste reserve a la Phase 4 (telechargement
/// reel). Chaque sentier propose un bouton "Entrer" qui ecrit la selection
/// ([selectedTrailIdProvider]) puis ouvre le shell sur /map : c'est l'entree
/// du coeur de l'app (anciennement orpheline).
class TrailCatalogScreen extends ConsumerWidget {
  const TrailCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final trails = ref.watch(availableTrailsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.catalog.title)),
      body: trails.isEmpty
          ? EmptyState(
              icon: Icons.explore_off,
              title: t.catalog.emptyTitle,
              subtitle: t.catalog.emptySubtitle,
            )
          : ListView(
              key: const ValueKey('trail-catalog-list'),
              padding: const EdgeInsets.only(
                top: AppTheme.spacingSm,
                bottom: AppTheme.spacingXl,
              ),
              children: [
                for (final trail in trails)
                  _AvailableTrailCard(
                    trail: trail,
                    onEnter: () => _enterTrail(context, ref, trail.id),
                  ),
              ],
            ),
    );
  }

  /// Entre dans le sentier [trailId] : ecrit la selection (le moteur entier
  /// suit via trailConfigProvider) puis ouvre le shell sur l'onglet Carte.
  void _enterTrail(BuildContext context, WidgetRef ref, String trailId) {
    ref.read(selectedTrailIdProvider.notifier).state = trailId;
    context.go('/map');
  }
}

/// Carte d'un sentier disponible au catalogue : nom, region, stats + bouton
/// primaire "Entrer". Pas de notion de telechargement en P2-P3 (donnees
/// embarquees) : le sentier est directement utilisable.
class _AvailableTrailCard extends StatelessWidget {
  const _AvailableTrailCard({required this.trail, required this.onEnter});

  final TrailConfig trail;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Card(
      key: ValueKey('catalog-trail-${trail.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + icone.
            Row(
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.terrain, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    trail.displayName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Region + pays.
            Text(
              '${trail.region}, ${trail.country}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppTheme.grisTexteSecondaire),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Stats principales — Wrap pour ne pas deborder a textScale 2x.
            Wrap(
              spacing: AppTheme.spacingBase,
              runSpacing: AppTheme.spacingXs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _InfoChip(
                  icon: Icons.straighten,
                  label: '${trail.totalDistanceKm.toStringAsFixed(0)} km',
                  theme: theme,
                ),
                _InfoChip(
                  icon: Icons.trending_up,
                  label: '${trail.totalElevationGain} m D+',
                  theme: theme,
                ),
                _InfoChip(
                  icon: Icons.flag,
                  label: '${trail.totalStages}',
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Action primaire : entrer dans le sentier (cablage nav #88246).
            SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: t.catalog.a11y.enterButton(nom: trail.displayName),
                child: FilledButton.icon(
                  key: ValueKey('catalog-enter-${trail.id}'),
                  onPressed: onEnter,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(t.catalog.enter),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Petit chip d'information avec icone (region, distance, etapes).
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
          child: Icon(icon, size: 14, color: AppTheme.grisTexteSecondaire),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
      ],
    );
  }
}
