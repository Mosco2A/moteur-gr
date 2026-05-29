import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/poi_type_config.dart';

/// Bottom sheet affichant le detail d'un point d'interet.
///
/// Affiche le nom, l'icone du type (via [PoiTypeConfig]), la description,
/// les coordonnees GPS et un bouton "Voir sur la carte" qui navigue
/// vers /trail/:trailId/map avec centrage sur le POI.
class PoiInfoSheet extends StatelessWidget {
  const PoiInfoSheet({super.key, required this.poi});

  /// Point d'interet a afficher.
  final Poi poi;

  /// Affiche le bottom sheet pour un POI donne.
  ///
  /// Usage typique :
  /// ```dart
  /// onPoiTap: (poi) => PoiInfoSheet.show(context, poi);
  /// ```
  static Future<void> show(BuildContext context, Poi poi) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
      ),
      builder: (_) => PoiInfoSheet(poi: poi),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = PoiTypeConfig.getStyle(poi.type);

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingBase,
        right: AppTheme.spacingBase,
        top: AppTheme.spacingBase,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poignee de drag
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingBase),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // En-tete : icone type + nom
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poi.name,
                      style: theme.textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      style.labelKey,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: style.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Description
          if (poi.description.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              poi.description,
              style: theme.textTheme.bodyMedium,
            ),
          ],

          // Coordonnees GPS
          const SizedBox(height: AppTheme.spacingBase),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                '${poi.lat.toStringAsFixed(5)}, ${poi.lng.toStringAsFixed(5)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              if (poi.altitudeM > 0) ...[
                const SizedBox(width: AppTheme.spacingMd),
                Icon(
                  Icons.terrain,
                  size: 18,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  '${poi.altitudeM} m',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ],
          ),

          // Bouton "Voir sur la carte"
          const SizedBox(height: AppTheme.spacingLg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.push(
                  '/trail/${poi.trailId}/map',
                  extra: {'lat': poi.lat, 'lng': poi.lng},
                );
              },
              icon: const Icon(Icons.map_outlined),
              label: const Text('Voir sur la carte'),
            ),
          ),
        ],
      ),
    );
  }
}
