import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/map_pois_provider.dart';
import 'poi_marker.dart';

/// Barre horizontale de chips togglables pour filtrer les POIs par type.
///
/// Affiche un chip par type de POI present dans les donnees du sentier.
/// Chip active = type visible sur la carte.
/// Chip desactive = type masque.
class PoiFilterBar extends ConsumerWidget {
  const PoiFilterBar({super.key, required this.trailId});

  /// Identifiant du sentier pour charger les types disponibles
  final String trailId;

  /// Libelle francais court pour chaque type de POI
  static String labelFor(PoiType type) {
    return switch (type) {
      PoiType.shelter => 'Refuge',
      PoiType.water => 'Eau',
      PoiType.viewpoint => 'Vue',
      PoiType.campsite => 'Bivouac',
      PoiType.restaurant => 'Restaurant',
      PoiType.emergency => 'Urgence',
      PoiType.danger => 'Danger',
      PoiType.shop => 'Commerce',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableAsync = ref.watch(availablePoiTypesProvider(trailId));
    final activeTypes = ref.watch(activePoiTypesProvider);

    return availableAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (availableTypes) {
        if (availableTypes.isEmpty) return const SizedBox.shrink();

        // Trier les types dans l'ordre de l'enum pour un affichage stable
        final sortedTypes = availableTypes.toList()
          ..sort((a, b) => a.index.compareTo(b.index));

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
              final isActive = activeTypes.contains(type);
              final color = PoiMarker.colorFor(type);

              return FilterChip(
                avatar: Icon(
                  PoiMarker.iconFor(type),
                  size: 16,
                  color: isActive ? Colors.white : color,
                ),
                label: Text(labelFor(type)),
                selected: isActive,
                selectedColor: color,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isActive ? Colors.white : null,
                  fontSize: 12,
                ),
                onSelected: (_) {
                  ref.read(activePoiTypesProvider.notifier).toggle(type);
                },
              );
            },
          ),
        );
      },
    );
  }
}
