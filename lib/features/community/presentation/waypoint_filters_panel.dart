import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/waypoint_type_config.dart';
import '../providers/waypoint_ui_providers.dart';

/// Panneau de FILTRES des waypoints facon FarOut (F8A-04, Comment Filtering R1).
///
/// Permet de filtrer la carte par TYPE (eau/ravitaillement/danger/camp/
/// connectivite/jonction) et par CONDITION RECENTE. Pure UI : agit sur
/// [waypointFilterProvider] (etat), AUCUNE logique reseau. a11y via [Semantics],
/// libelles Slang (`waypoints.filters.*` + `waypoints.types.*`).
class WaypointFiltersPanel extends ConsumerWidget {
  const WaypointFiltersPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final filter = ref.watch(waypointFilterProvider);
    final notifier = ref.read(waypointFilterProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.waypoints.filters.title,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Semantics(
                button: true,
                label: t.waypoints.filters.showAll,
                child: TextButton(
                  key: const ValueKey('waypoint-filter-show-all'),
                  onPressed: notifier.showAll,
                  child: Text(t.waypoints.filters.showAll),
                ),
              ),
              Semantics(
                button: true,
                label: t.waypoints.filters.hideAll,
                child: TextButton(
                  key: const ValueKey('waypoint-filter-hide-all'),
                  onPressed: notifier.hideAll,
                  child: Text(t.waypoints.filters.hideAll),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Filtres par type (chips bascule).
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingSm,
            children: WaypointTypeConfig.allTypes.map((type) {
              final style = WaypointTypeConfig.getStyle(type);
              final selected = filter.isTypeVisible(type);
              final label = _typeLabel(t, type);
              return Semantics(
                button: true,
                selected: selected,
                label: label,
                child: FilterChip(
                  key: ValueKey('waypoint-filter-type-$type'),
                  avatar: Icon(
                    style.icon,
                    size: 18,
                    color: selected ? Colors.white : style.color,
                  ),
                  label: Text(label),
                  selected: selected,
                  selectedColor: style.color,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                  ),
                  onSelected: (_) => notifier.toggleType(type),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Filtre condition recente (FarOut : eau coule vs eau a sec...).
          Semantics(
            label: t.waypoints.filters.recentConditionOnly,
            toggled: filter.recentConditionOnly,
            child: SwitchListTile(
              key: const ValueKey('waypoint-filter-recent-condition'),
              contentPadding: EdgeInsets.zero,
              title: Text(t.waypoints.filters.recentConditionOnly),
              value: filter.recentConditionOnly,
              onChanged: (_) => notifier.toggleRecentConditionOnly(),
            ),
          ),
        ],
      ),
    );
  }

  /// Libelle i18n d'un type de waypoint (`waypoints.types.<labelKey>`).
  String _typeLabel(Translations t, String type) {
    final key = WaypointTypeConfig.getStyle(type).labelKey;
    final types = t.waypoints.types;
    switch (key) {
      case 'eau':
        return types.eau;
      case 'ravitaillement':
        return types.ravitaillement;
      case 'danger':
        return types.danger;
      case 'camp':
        return types.camp;
      case 'connectivite':
        return types.connectivite;
      case 'jonction':
        return types.jonction;
      default:
        return key; // fallback : type brut (jamais de crash)
    }
  }
}
