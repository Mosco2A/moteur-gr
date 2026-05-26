import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import 'poi_marker.dart';

/// Popup affiché au tap sur un marqueur POI.
///
/// Présente le nom en gras, la description,
/// l'altitude et les horaires si disponibles.
/// Card avec ombre, coins arrondis, max 200px de large.
class PoiPopup extends StatelessWidget {
  const PoiPopup({super.key, required this.poi});

  /// Le POI dont on affiche les détails
  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PoiMarker.colorFor(poi.type);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête : icône + nom
              Row(
                children: [
                  Icon(
                    PoiMarker.iconFor(poi.type),
                    color: color,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      poi.name,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Description
              if (poi.description.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  poi.description,
                  style: theme.textTheme.bodySmall,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Altitude
              if (poi.altitudeM > 0) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: [
                    const Icon(
                      Icons.terrain,
                      size: 14,
                      color: AppTheme.grisGranite,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      '${poi.altitudeM} m',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisGranite,
                      ),
                    ),
                  ],
                ),
              ],

              // Horaires
              if (poi.openingHours != null) ...[
                const SizedBox(height: AppTheme.spacingXs),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 14,
                      color: AppTheme.grisGranite,
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Expanded(
                      child: Text(
                        poi.openingHours!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisGranite,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
