import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Provider qui indique si des sentiers sont disponibles localement.
///
/// Utilise par [NoDataScreen] pour rediriger vers la liste des
/// sentiers des qu un sentier devient disponible (fin de
/// telechargement catalogue). Mis a jour par le CatalogNotifier.
final hasLocalTrailsProvider = StateProvider<bool>((ref) => false);

/// Ecran bloquant affiche quand aucun sentier n'est telecharge (E4.10).
///
/// Guide l'utilisateur vers le catalogue pour telecharger
/// son premier sentier. Design coherent avec le theme dark.
/// Redirige automatiquement vers /trails via [hasLocalTrailsProvider].
/// Textes via Slang (t.noData.*) — zero texte en dur.
class NoDataScreen extends ConsumerWidget {
  const NoDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasTrails = ref.watch(hasLocalTrailsProvider);

    // Si des sentiers sont maintenant disponibles, rediriger
    if (hasTrails) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/trails');
      });
    }

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
                  t.noData.title,
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingBase),

                // Message explicatif
                Text(
                  t.noData.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  t.noData.offlineHint,
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
                  label: Text(t.noData.browseCta),
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
