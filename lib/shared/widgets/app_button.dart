import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, outline, filledTone }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.isFullWidth = true,
    this.tone,
    this.minHeight = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool isFullWidth;

  /// Couleur semantique optionnelle (danger, succes...) appliquee a la variante
  /// `outline` : teinte le texte, l'icone et la bordure sans changer la forme,
  /// la taille ni le comportement. Sert aux CTA a sens fort (ex. conseil
  /// securite incendie en rouge dans un bandeau d'alerte, SW-SKIN-L3b) tout en
  /// gardant la grammaire unifiee du bouton. Pour la variante `filledTone`,
  /// `tone` est la couleur de FOND pleine (texte/icone blancs) : sert aux CTA
  /// a couleur d'action forte de l'overlay de suivi (Demarrer=actionStart,
  /// Pause=actionPause, Stop=rougeUrgence, SW-SKIN-L3c) — le contraste blanc
  /// >= AA sur ces tokens est prouve par test/core/a11y/a11y_audit_test.dart.
  /// `null` => couleur du theme (primary). Ignore pour primary/secondary
  /// (fonds pleins geres au theme).
  final Color? tone;

  /// Hauteur mini de la cible tactile (defaut 48px, plancher a11y Material).
  /// L'overlay de suivi (HUD carte) utilise 44px historiquement — expose ici
  /// pour un iso-rendu STRICT de cet ecran actif sans figer 48 pour tous les
  /// appelants (SW-SKIN-L3c). Ne jamais descendre sous 44 (cible tactile AA).
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final theme = Theme.of(context);
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppTheme.spacingSm),
              ],
              Text(label),
            ],
          );
    final minSize = isFullWidth
        ? Size(double.infinity, minHeight)
        : Size(0, minHeight);
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: Colors.white,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.secondary:
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.outline:
        // tone : couleur semantique optionnelle (rouge danger...) ; defaut = primary.
        final outlineColor = tone ?? theme.colorScheme.primary;
        return OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: outlineColor,
            minimumSize: minSize,
            side: BorderSide(color: outlineColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
          ),
          child: child,
        );
      case AppButtonVariant.filledTone:
        // Bouton plein a couleur semantique forte (fond = tone, texte/icone
        // blancs). Reprend a l'identique un ElevatedButton.icon a fond custom
        // de l'overlay de suivi (SW-SKIN-L3c) : meme rendu qu'avant, grammaire
        // unifiee en plus. `tone` requis ; fallback theme.primary par prudence.
        final fillColor = tone ?? theme.colorScheme.primary;
        return ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: fillColor,
            foregroundColor: Colors.white,
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
          ),
          child: child,
        );
    }
  }
}
