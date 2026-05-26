import 'package:flutter/material.dart';

import '../../../core/models/stage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_header.dart';
import 'elevation_indicator.dart';

/// Section statistiques d'une étape : distance, durée, dénivelé.
///
/// Affiche dans un conteneur arrondi la distance en km,
/// la durée estimée formatée, et les indicateurs D+/D-.
class StageStatsSection extends StatelessWidget {
  const StageStatsSection({
    super.key,
    required this.stage,
    required this.formattedDuration,
  });

  final StageModel stage;
  final String formattedDuration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: '${stage.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.schedule,
                  label: 'Durée estimée',
                  value: formattedDuration,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ElevationIndicator(
            gainM: stage.elevationGainM,
            lossM: stage.elevationLossM,
            fontSize: 15,
            iconSize: 18,
          ),
        ],
      ),
    );
  }
}

/// Item de statistique individuel (icône + label + valeur)
class _StatItem extends StatelessWidget {
  const _StatItem({
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
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: AppTheme.spacingSm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ],
    );
  }
}

/// Section coordonnées départ / arrivée d'une étape
class StageCoordinatesSection extends StatelessWidget {
  const StageCoordinatesSection({
    super.key,
    required this.stage,
  });

  final StageModel stage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Coordonnées',
          icon: Icons.my_location,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _CoordRow(
          label: 'Départ',
          lat: stage.startLat,
          lng: stage.startLng,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        _CoordRow(
          label: 'Arrivée',
          lat: stage.endLat,
          lng: stage.endLng,
        ),
      ],
    );
  }
}

/// Ligne de coordonnées (départ ou arrivée)
class _CoordRow extends StatelessWidget {
  const _CoordRow({
    required this.label,
    required this.lat,
    required this.lng,
  });

  final String label;
  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          Icons.circle,
          size: 10,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          '$label : ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
        ),
      ],
    );
  }
}
