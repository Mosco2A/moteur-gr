import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import '../../poi/domain/poi_type_config.dart';

/// Tuile d'affichage pour un point d'interet.
///
/// Affiche l'icone typee, le nom, la description
/// et l'altitude si disponible.
class PoiTile extends StatelessWidget {
  const PoiTile({super.key, required this.poi});

  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = PoiTypeConfig.getStyle(poi.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(
            style.icon,
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
