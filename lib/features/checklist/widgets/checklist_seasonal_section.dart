import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';

/// Section « Sac adaptatif » (StepWays LOT 5, sous-ensemble B).
///
/// ADDITIVE au Sac de base (parite GR20 intacte : la liste des 84 articles ne
/// change pas) : elle propose des articles pertinents pour le SENTIER charge et
/// la SAISON du depart (ou du jour). Chaque suggestion s'AJOUTE au sac d'un tap
/// ([ChecklistNotifier.addSuggestedItem], idempotent) et compte alors dans la
/// jauge — c'est la « liste ET jauge adaptees au trek + saison » demandee, sans
/// injecter d'articles dans le template de base (ce qui casserait la parite).
///
/// Donnees EXTERNALISEES (`assets/data/checklist_seasonal.json`). Si aucune
/// suggestion pour ce sentier/saison, la section ne s'affiche pas (rien a
/// adapter). Tout texte via Slang (5 langues) ; nom d'article via
/// `checklist.items.*`. Look GR20 conserve ([AppCard], tokens `AppTheme`).
class ChecklistSeasonalSection extends ConsumerWidget {
  const ChecklistSeasonalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final season = ref.watch(checklistSeasonFromDepartureProvider);
    final suggestionsAsync = ref.watch(checklistSeasonalSuggestionsProvider);

    final suggestions = suggestionsAsync.value ?? const [];
    // Rien a adapter (pas de donnee saison/trek) -> section masquee.
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final seasonLabelRaw = t['checklist.seasons.$season'];
    final seasonLabel = seasonLabelRaw is String ? seasonLabelRaw : season;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingSm,
        AppTheme.spacingBase,
        0,
      ),
      child: AppCard(
        backgroundColor: AppTheme.bleuRepos.withAlpha(18),
        borderColor: AppTheme.bleuRepos.withAlpha(70),
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_twilight,
                    size: 20, color: AppTheme.bleuRepos),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    t.checklist.seasonalBanner(season: seasonLabel),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            for (final item in suggestions)
              _SuggestionRow(item: item),
          ],
        ),
      ),
    );
  }
}

/// Ligne d'une suggestion saisonniere : nom + poids + bouton « Ajouter ».
class _SuggestionRow extends ConsumerWidget {
  const _SuggestionRow({required this.item});

  final ChecklistTemplateItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nameRaw = t['checklist.items.${item.nameKey}'];
    final name = nameRaw is String ? nameRaw : item.nameKey;

    // Deja au sac ? (par nom, coherent avec l'idempotence de addSuggestedItem)
    final already = ref.watch(
      checklistProvider.select(
        (s) => s.items.any((i) => i.isCustom && i.customName?.trim() == name),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                if (item.weightGrams > 0)
                  Text(
                    t.checklist.seasonalWeight(g: item.weightGrams),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(150),
                    ),
                  ),
              ],
            ),
          ),
          if (already)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    size: 18, color: AppTheme.vertFacile),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  t.checklist.seasonalAdded,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppTheme.vertFacile),
                ),
              ],
            )
          else
            TextButton.icon(
              onPressed: () => ref
                  .read(checklistProvider.notifier)
                  .addSuggestedItem(
                    category: item.category,
                    name: name,
                    weightGrams: item.weightGrams,
                  ),
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: Text(t.checklist.seasonalAdd),
            ),
        ],
      ),
    );
  }
}
