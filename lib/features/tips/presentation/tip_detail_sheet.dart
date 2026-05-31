import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/tip_category_config.dart';
import '../domain/models/tip_card.dart';
import 'tip_carousel.dart';

/// Bottom sheet affichant le detail complet d une fiche conseil.
///
/// Affiche le titre, le contenu integral, la categorie, les tags,
/// et les metadonnees (scope, season, altitude). Couleur par categorie.
class TipDetailSheet extends StatelessWidget {
  const TipDetailSheet({super.key, required this.card});

  final TipCard card;

  /// Affiche le bottom sheet de detail pour une fiche conseil.
  static void show(BuildContext context, TipCard card) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
      ),
      builder: (_) => TipDetailSheet(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = TipCategoryConfig.getConfig(card.category);
    final color = categoryColor(card.category, theme);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poignee de drag
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withAlpha(80),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // En-tete categorie
                Row(
                  children: [
                    Icon(resolveIcon(meta.icon), color: color, size: 24),
                    const SizedBox(width: AppTheme.spacingSm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingXs,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(30),
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Text(
                        card.category,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (card.priority >= 8)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.rougeUrgence.withAlpha(20),
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.priority_high,
                              color: AppTheme.rougeUrgence,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "Priorite haute",
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.rougeUrgence,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // Titre
                Text(card.titleFr, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacingBase),
                // Contenu integral
                Text(
                  card.contentFr,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: AppTheme.spacingLg),
                // Tags
                if (card.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: AppTheme.spacingSm,
                    runSpacing: AppTheme.spacingSm,
                    children: card.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spacingBase),
                ],
                // Metadonnees (scope, season, altitude)
                const Divider(),
                const SizedBox(height: AppTheme.spacingSm),
                _MetadataRow(
                  icon: Icons.hiking,
                  label: "Sentier",
                  value: card.scope,
                ),
                _MetadataRow(
                  icon: Icons.calendar_today,
                  label: "Saison",
                  value: card.season,
                ),
                if (card.minAltitudeM != null)
                  _MetadataRow(
                    icon: Icons.terrain,
                    label: "Altitude min.",
                    value: "${card.minAltitudeM} m",
                  ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ligne de metadonnee dans le detail (icone + label + valeur).
class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurface.withAlpha(150)),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Text(value, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
