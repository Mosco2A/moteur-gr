import 'package:flutter/material.dart';

import '../../shared/widgets/app_button.dart';

/// Widget generique pour afficher une erreur avec bouton retry.
///
/// Utilise dans toute l'app pour un affichage homogene des erreurs.
/// Affiche un message utilisateur lisible et un bouton de relance.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  /// Message d'erreur affiche a l'utilisateur.
  final String message;

  /// Callback de relance. Si null, le bouton retry n'est pas affiche.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5). isFullWidth:false : FilledButton n'est pas force pleine
              // largeur par le theme, il restait dimensionne au contenu et
              // centre dans la Column (iso-rendu). Libelle inchange.
              AppButton(
                isFullWidth: false,
                icon: Icons.refresh,
                label: 'Reessayer',
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
