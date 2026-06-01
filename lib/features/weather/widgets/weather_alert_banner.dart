import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../tips/domain/models/tip_card.dart';
import '../../tips/presentation/tip_detail_sheet.dart';
import '../models/weather_alert.dart';

/// Bandeau d'alerte meteo en haut de l'ecran.
///
/// Affiche les alertes actives avec un code couleur
/// selon la severite (warning = orange, danger = rouge).
/// Pour les alertes incendie (type == fire), affiche un CTA
/// vers la fiche conseil securite_incendie.
class WeatherAlertBanner extends StatelessWidget {
  const WeatherAlertBanner({
    super.key,
    required this.alerts,
    this.fireTipCard,
  });

  final List<WeatherAlert> alerts;

  /// Fiche conseil incendie a afficher quand le CTA est tape.
  /// null = pas de CTA incendie.
  final TipCard? fireTipCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDanger = alerts.any((a) => a.severity == 'danger');
    final hasFireAlert = alerts.any((a) => a.type == AlertType.fire);

    return Container(
      decoration: BoxDecoration(
        color: hasDanger
            ? AppTheme.rougeUrgence.withAlpha(30)
            : AppTheme.orangeDifficile.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: hasDanger ? AppTheme.rougeUrgence : AppTheme.orangeDifficile,
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasFireAlert ? Icons.local_fire_department : Icons.warning_amber_rounded,
                color:
                    hasDanger ? AppTheme.rougeUrgence : AppTheme.orangeDifficile,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                '${alerts.length} alerte${alerts.length > 1 ? 's' : ''}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasDanger
                      ? AppTheme.rougeUrgence
                      : AppTheme.orangeDifficile,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          ...alerts.map(
            (alert) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconForAlert(alert),
                    size: 16,
                    color: alert.severity == 'danger'
                        ? AppTheme.rougeUrgence
                        : AppTheme.orangeDifficile,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      '${alert.title} — ${alert.description}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // CTA vers fiche incendie si alerte fire active et fiche disponible
          if (hasFireAlert && fireTipCard != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => TipDetailSheet.show(context, fireTipCard!),
                icon: const Icon(Icons.local_fire_department, size: 18),
                label: const Text('Consignes incendie'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.rougeUrgence,
                  side: const BorderSide(color: AppTheme.rougeUrgence),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Icone adaptee au type d'alerte
  IconData _iconForAlert(WeatherAlert alert) {
    if (alert.type == AlertType.fire) return Icons.local_fire_department;
    if (alert.severity == 'danger') return Icons.dangerous;
    return Icons.warning;
  }
}
