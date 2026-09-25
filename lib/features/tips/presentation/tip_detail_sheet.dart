import 'package:flutter/material.dart';

import '../../../core/config/trail_catalog.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../data/tip_category_config.dart';
import '../domain/models/tip_card.dart';
import 'tip_carousel.dart';
import 'tip_points_list.dart';

/// Nom LISIBLE du sentier couvert par une fiche conseil (tâche 557).
///
/// CE QUI S'AFFICHAIT AVANT : la valeur brute du champ — « all », puis
/// « mare_a_mare ». Un identifiant technique, sous un intitulé « Sentier »,
/// dans une langue quelconque.
///
/// CE QUI S'AFFICHE MAINTENANT : « Tous les sentiers » (`t.tips.scopeAll`,
/// traduite par la tâche 552) quand la fiche vaut pour tout le monde, et sinon
/// LE NOM DU SENTIER que l'application connaît déjà — [TrailCatalog] porte le
/// `displayName` de chaque sentier du catalogue, aucun nom n'est réécrit ici.
///
/// Repli assumé sur la valeur brute pour un sentier hors catalogue : mieux vaut
/// l'identifiant que le nom d'un AUTRE sentier ou une case vide.
String tipScopeLabel(String scope) {
  final normalized = scope.trim();
  if (normalized.isEmpty || normalized == 'all') return t.tips.scopeAll;
  return TrailCatalog.byId(normalized)?.displayName ?? normalized;
}

/// Saison couverte par une fiche conseil, dans la langue de l'application.
///
/// Même défaut que le scope : « summer » s'affichait tel quel. Les cinq valeurs
/// du champ ont leur clé depuis la tâche 552 (`t.tips.seasons.*`). Repli sur la
/// valeur brute pour une saison inconnue du modèle — extensible par
/// construction ([TipCard] garde des `String`, jamais des enums).
String tipSeasonLabel(String season) {
  final seasons = t.tips.seasons;
  switch (season.trim()) {
    case '':
    case 'all':
      return seasons.all;
    case 'winter':
      return seasons.winter;
    case 'spring':
      return seasons.spring;
    case 'summer':
      return seasons.summer;
    case 'autumn':
      return seasons.autumn;
    default:
      return season;
  }
}

/// Bottom sheet affichant le detail complet d une fiche conseil.
///
/// Affiche le titre, le contenu integral EN PUCES (calibre GR20, tache 555), la
/// categorie, les tags et les metadonnees (scope, season, altitude). Couleur par
/// categorie. Titre et points localises (5 langues, repli FR).
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
                Text(card.localizedTitle, style: theme.textTheme.headlineSmall),
                const SizedBox(height: AppTheme.spacingBase),
                // Contenu integral EN PUCES (calibre, tache 555)
                TipPointsList.fromCard(
                  card: card,
                  bulletColor: color,
                  textStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
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
                // LES TROIS INTITULES ETAIENT ECRITS EN DUR EN FRANCAIS
                // (« Sentier », « Saison », « Altitude min. ») : un Allemand
                // lisait une fiche allemande sous des intitules francais. Les
                // cles existent (`t.tips.scope`, `t.tips.season`,
                // `t.tips.altitude`) et sont branchees ici (tache 557).
                _MetadataRow(
                  icon: Icons.hiking,
                  label: t.tips.scope,
                  value: tipScopeLabel(card.scope),
                ),
                _MetadataRow(
                  icon: Icons.calendar_today,
                  label: t.tips.season,
                  value: tipSeasonLabel(card.season),
                ),
                if (card.minAltitudeM != null)
                  _MetadataRow(
                    icon: Icons.terrain,
                    label: t.tips.altitude,
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
