/// Ce qu'un point raconte quand on le touche : nom, description, altitude et
/// horaires s'ils existent.
library;

import 'package:flutter/material.dart';

import '../../../core/models/poi.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import 'poi_marker.dart';
import '../../../core/branding/stepways_icons.dart';

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
      // SW-SKIN-L3e : Card -> AppCard. elevation 6 conservee ; le rayon de
      // carte (radiusCard) est le defaut d'AppCard ; padding md porte par
      // AppCard (iso-rendu du popup POI, contrainte maxWidth 200 inchangee).
      child: AppCard(
        elevation: 6,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : icône + nom
            Row(
              children: [
                StepIcon(PoiMarker.iconFor(poi.type), color: color, size: 20),
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
                  const StepIcon(
                    StepwaysIcons.sommet,
                    size: 14,
                    color: AppTheme.grisTexteSecondaire,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    '${poi.altitudeM} m',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
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
                  const StepIcon(
                    StepwaysIcons.duree,
                    size: 14,
                    color: AppTheme.grisTexteSecondaire,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      poi.openingHours!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
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
    );
  }
}
