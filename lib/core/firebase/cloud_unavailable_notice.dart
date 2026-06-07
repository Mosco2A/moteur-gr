import 'package:flutter/material.dart';

import '../../i18n/translations.g.dart';
import '../theme/app_theme.dart';

/// Etat explicite du mode local (P1-4 audit #327).
///
/// Affiche quand Firebase n est pas configure (isAvailable=false) a la
/// place des formulaires/boutons cloud qui ne pourraient qu echouer en
/// silence : suivi temps reel, sauvegarde en ligne, compte.
/// Textes via Slang (t.cloud.*) — zero texte en dur.
class CloudUnavailableNotice extends StatelessWidget {
  const CloudUnavailableNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = Translations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: AppTheme.grisGranite,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              tr.cloud.localModeTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              tr.cloud.localModeBody,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
