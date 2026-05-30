import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../poi/domain/poi_type_config.dart';
import '../providers/map_pois_provider.dart';

/// Barre horizontale de chips togglables pour filtrer les POIs par type.
///
/// Affiche un chip par type de POI present dans les donnees du sentier.
/// Chip active = type visible sur la carte.
/// Chip desactive = type masque.
class PoiFilterBar extends ConsumerWidget {
  const PoiFilterBar({super.key, required this.trailId});

  /// Identifiant du sentier pour charger les types disponibles
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availablePoiTypesProvider(trailId));
    final activeTypes = ref.watch(activePoiTypesProvider);

    return availableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (availableTypes) {
        if (availableTypes.isEmpty) return const SizedBox.shrink();

        // Initialiser activeTypes si null (premier affichage)
        final currentActive = activeTypes ?? availableTypes;

        // Trier les types alphabetiquement pour un affichage stable
        final sortedTypes = availableTypes.toList()..sort();

        return SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            itemCount: sortedTypes.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppTheme.spacingSm),
            itemBuilder: (context, index) {
              final type = sortedTypes[index];
              final isActive = currentActive.contains(type);
              final style = PoiTypeConfig.getStyle(type);
              final color = style.color;

              return FilterChip(
                avatar: Icon(
                  style.icon,
                  size: 16,
                  color: isActive ? Colors.white : color,
                ),
                label: Text(style.labelKey),
                selected: isActive,
                selectedColor: color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : null,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  final notifier = ref.read(activePoiTypesProvider.notifier);
                  final current = Set<String>.from(currentActive);
                  if (selected) {
                    current.add(type);
                  } else {
                    current.remove(type);
                  }
                  notifier.state = current;
                },
              );
            },
          ),
        );
      },
    );
  }
}
