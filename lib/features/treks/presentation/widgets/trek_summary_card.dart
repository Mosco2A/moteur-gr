import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/trek_lifecycle_state.dart';
import '../../domain/trek_summary.dart';

/// Carte d'un trek POSSEDE pour l'accueil « Mes treks » (StepWays LOT 2,
/// Phase 4 / §2).
///
/// Calque le rendu des cartes de sentier du catalogue (`_AvailableTrailCard` /
/// `_TrailChoiceCard`) — [AppCard] + titre + region + stats etapes/distance —
/// et lui AJOUTE :
///   * un badge d'[TrekLifecycleState] (style du badge « actif » de
///     `trail_selection_screen`, teinte semantique selon l'etat) ;
///   * une barre de progression quand le trek est engage
///     ([TrekSummary.progressFraction] > 0), masquee pour un trek juste
///     possede/termine sans matiere.
///
/// La carte est PUREMENT presentationnelle : elle recoit un [TrekSummary]
/// (deja derive par `myTreksProvider`) et delegue le geste de selection a
/// [onTap]. Aucune lecture de provider, aucun texte en dur (Slang `myTreks.*`),
/// a11y via Semantics — coherent avec le reste du socle.
class TrekSummaryCard extends StatelessWidget {
  const TrekSummaryCard({
    super.key,
    required this.summary,
    required this.onTap,
  });

  /// Vue synthetique du trek (config + etat derive + progression).
  final TrekSummary summary;

  /// Geste de selection du trek (ecrit `selectedTrailIdProvider` + `go('/home')`
  /// cote ecran — la carte ne connait pas la navigation).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final config = summary.config;
    final fraction = summary.progressFraction;
    final stateLabel = _stateLabel(t);

    return Semantics(
      container: true,
      button: true,
      label: t.myTreks.a11y.trekCard(
        nom: config.displayName,
        state: stateLabel,
      ),
      child: AppCard(
        key: ValueKey('trek-summary-${config.id}'),
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre + badge d'etat (calque du badge « actif » de la selection).
            Row(
              children: [
                Expanded(
                  child: Text(
                    config.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _StateBadge(state: summary.state, label: stateLabel),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Region + pays (iso-rendu carte catalogue).
            Text(
              '${config.region}, ${config.country}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // Stats principales (etapes + distance) — cle Slang partagee avec
            // l'ecran de selection (pas de doublon de libelle).
            Text(
              t.trailSelection.stagesDistance(
                stages: config.totalStages,
                km: config.totalDistanceKm.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            // Barre de progression : uniquement si le trek est engage (evite un
            // 0 % inutile sur un trek juste possede, ou un 100 % redondant avec
            // le badge « Terminé »).
            if (fraction > 0 && summary.state != TrekLifecycleState.completed)
              ...[
              const SizedBox(height: AppTheme.spacingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                t.myTreks.progressLabel(percent: (fraction * 100).round()),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Libelle localise du badge selon l'etat derive.
  String _stateLabel(Translations t) {
    switch (summary.state) {
      case TrekLifecycleState.owned:
        return t.myTreks.badge.owned;
      case TrekLifecycleState.prepared:
        return t.myTreks.badge.prepared;
      case TrekLifecycleState.inProgress:
        return t.myTreks.badge.inProgress;
      case TrekLifecycleState.completed:
        return t.myTreks.badge.completed;
    }
  }
}

/// Badge d'etat (pastille teintee) — calque du badge « Sentier actif » de
/// `trail_selection_screen` : fond a faible alpha de la teinte semantique,
/// texte `labelSmall` gras a la meme teinte.
class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.label});

  final TrekLifecycleState state;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _stateColor(theme);

    return Container(
      key: ValueKey('trek-state-badge-${state.name}'),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Teinte semantique du badge (tokens AppTheme, pas de couleur ad hoc) :
  ///   * inProgress -> vert « en cours » (actionStart) ;
  ///   * completed  -> vert facile (finisher) ;
  ///   * prepared   -> primaire du sentier ;
  ///   * owned      -> gris granite (neutre, rien fait).
  Color _stateColor(ThemeData theme) {
    switch (state) {
      case TrekLifecycleState.inProgress:
        return AppTheme.actionStart;
      case TrekLifecycleState.completed:
        return AppTheme.vertFacile;
      case TrekLifecycleState.prepared:
        return theme.colorScheme.primary;
      case TrekLifecycleState.owned:
        return AppTheme.grisGranite;
    }
  }
}
