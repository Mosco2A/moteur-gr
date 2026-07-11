import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';

/// Tuile meteo du jour du HUB (AM-3) — STUB en LOT-A.
///
/// D3 (arbitrage #94902) : la tuile meteo est un STUB. La meteo reelle depend
/// de l'ecran E31 (LOT-D) ; on ne branche AUCUN provider meteo ici (ni
/// `weatherProvider`, ni pastille d'alerte neige/orage). La tuile occupe la
/// place cible et annonce l'arrivee prochaine de la fonction, sans bouton mort
/// (regle S8 « zero route morte » : aucun tap vers un ecran E31 inexistant).
class HubWeatherCard extends StatelessWidget {
  const HubWeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      // Pas d'onTap : la cible (E31) n'existe pas en LOT-A (S8).
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(
        children: [
          Icon(
            Icons.wb_cloudy_outlined,
            size: 32,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.hub.weather.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  t.hub.weather.stub,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
