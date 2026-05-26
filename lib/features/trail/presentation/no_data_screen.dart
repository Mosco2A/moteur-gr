import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';

/// Ecran bloquant affiche quand aucun sentier n'est telecharge.
///
/// Guide l'utilisateur vers le catalogue pour telecharger
/// son premier sentier. Design coherent avec le theme dark.
class NoDataScreen extends StatelessWidget {
  const NoDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingXl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icone principale
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.downloading_rounded,
                    size: 64,
                    color: theme.colorScheme.primary.withAlpha(180),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Titre
                Text(
                  'Aucun sentier telecharge',
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingBase),

                // Message explicatif
                Text(
                  'Telechargez un sentier pour commencer',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Les donnees seront disponibles hors ligne '
                  'pour votre randonnee.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisGranite.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingXl),

                // Bouton action principal
                ElevatedButton.icon(
                  onPressed: () => context.go('/catalog'),
                  icon: const Icon(Icons.explore),
                  label: const Text('Parcourir les sentiers'),
                ),
                const SizedBox(height: AppTheme.spacingBase),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
