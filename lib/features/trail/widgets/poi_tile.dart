import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';

/// Tuile d'affichage pour un point d'intérêt.
///
/// Affiche l'icône typée, le nom, la description
/// et l'altitude si disponible.
class PoiTile extends StatelessWidget {
  const PoiTile({super.key, required this.poi});

  final PoiModel poi;

  /// Icône selon le type de POI
  static IconData iconFor(PoiType type) {
    return switch (type) {
      PoiType.shelter => Icons.cabin,
      PoiType.water => Icons.water_drop,
      PoiType.viewpoint => Icons.landscape,
      PoiType.campsite => Icons.holiday_village,
      PoiType.restaurant => Icons.restaurant,
      PoiType.emergency => Icons.local_hospital,
      PoiType.danger => Icons.warning,
      PoiType.shop => Icons.store,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            iconFor(poi.type),
            size: 20,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poi.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (poi.description.isNotEmpty)
                  Text(
                    poi.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(160),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (poi.altitudeM > 0)
            Text(
              '${poi.altitudeM}m',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
        ],
      ),
    );
  }
}
