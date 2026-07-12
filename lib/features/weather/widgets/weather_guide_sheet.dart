import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Bottom-sheet « Comprendre la météo » (guide (i), RF-1).
///
/// Contenu éditorial i18n (5 langues), sans dépendance sentier.
class WeatherGuideSheet extends StatelessWidget {
  const WeatherGuideSheet({super.key});

  /// Affiche le guide en modal bottom-sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const WeatherGuideSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = Translations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: theme.colorScheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(t.weather.guideTitle,
                      style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(t.weather.guideBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingLg),
          ],
        ),
      ),
    );
  }
}
