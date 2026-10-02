import 'package:flutter/material.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';

/// Les formes de bouton de la grammaire StepWays.
enum AppButtonVariant {
  /// Fond plein a la couleur principale du theme : l'action primaire d'un ecran.
  primary,

  /// Fond plein a la couleur secondaire : une action primaire de second plan.
  secondary,

  /// Contour seul, sans fond : l'action secondaire, et le support de `tone`.
  outline,

  /// Fond plein a une couleur SEMANTIQUE donnee par `tone` (danger, depart...).
  filledTone,

  /// Plat : ni fond ni contour. La forme des actions de dialogue
  /// (« Annuler », « Plus tard ») et des liens d'action (tache 645-03).
  text,
}

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
    this.labelFontSize,
    this.iconSize = 20,
    this.minHeight = 48,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;

  /// Chemin d'une icone Stepways ([StepwaysIcons]), tache 632. Rendue en
  /// MONOCHROME : elle doit suivre la couleur du bouton (blanc sur fond plein,
  /// teinte du theme en contour, grisee quand le bouton est desactive), ce
  /// qu'un trace bicolore fige ne saurait pas faire.
  final String? icon;

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
  /// Pour la variante `text` (bouton plat), `tone` est la couleur du LIBELLE
  /// et de l'icone (le fond reste transparent) : sert aux « Annuler » de
  /// dialogue que leur appel grisait deja (tache 645-03).
  /// `null` => couleur du theme (primary). Ignore pour primary/secondary
  /// (fonds pleins geres au theme).
  final Color? tone;

  /// Taille de police du libelle, quand l'appel doit s'ecarter de la
  /// typographie que le bouton tient du theme. `null` (defaut) = le bouton
  /// decide, comme avant.
  ///
  /// POURQUOI CE PARAMETRE EXISTE (tache 645-03). Cinq boutons du parc
  /// ecrivaient leur libelle dans une taille choisie sur place : les « J'ai
  /// compris » de feuille d'information en 16, le « Appeler » d'une nuitee en
  /// 14, l'« Annuler » du dialogue SOS en 15. Les ramener ici sans ce
  /// parametre aurait change la taille de leur texte — une correction
  /// d'apparence, pas un deplacement.
  ///
  /// SEULE LA TAILLE PASSE PAR ICI, et c'est voulu : le reste de la
  /// typographie (graisse, famille, couleur) reste la decision du bouton et du
  /// theme. Un libelle qui demande plus que sa taille n'a pas sa place dans un
  /// parametre : c'est le signe que l'ecran veut un autre composant.
  final double? labelFontSize;

  /// Taille du dessin de l'icone, en pixels (defaut 20px).
  ///
  /// POURQUOI CE PARAMETRE EXISTE (tache 645-03). Les `*Button.icon` du
  /// framework peignent leur icone a 18px — c'est la taille que Material pose
  /// dans l'`IconTheme` du bouton, mesuree sur les quatre boutons. Les appels
  /// que la tache 645-03 a ramenes ici demandaient donc 18, parfois 22 (le CTA
  /// « Demarrer » du cockpit), parfois 14. Sans ce parametre, les ramener
  /// aurait grossi ou rapetisse leur icone de 2 a 6px : un ecart d'apparence,
  /// exactement ce que le deplacement devait eviter.
  ///
  /// Le defaut reste 20 : les 94 appels d'AppButton existants au 02/10/2026 ne
  /// bougent pas d'un pixel.
  final double iconSize;

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
              // Pas de couleur passee : StepIcon prend celle de l'IconTheme,
              // que le style du bouton pose deja. L'icone suit donc le bouton,
              // y compris desactive.
              if (icon case final asset?) ...[
                StepIcon(asset, size: iconSize),
                const SizedBox(width: AppTheme.spacingSm),
              ],
              // Le libelle est `Flexible` (comme `ElevatedButton.icon`/
              // `FilledButton.icon` de Material qui enveloppent leur label
              // ainsi) : il peut se contraindre au lieu de deborder la Row
              // interne quand le bouton est etroit et le texte long (ex.
              // textScale 2x sur ecran 360px, cartes catalogue) — SW-SKIN-L3e.
              // Sans effet quand le texte tient : la Row reste `min`.
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: labelFontSize == null
                      ? null
                      : TextStyle(fontSize: labelFontSize),
                ),
              ),
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
      case AppButtonVariant.text:
        // BOUTON PLAT : aucun fond, aucune bordure, aucune elevation — la forme
        // des actions de dialogue (« Annuler », « Plus tard ») et des liens
        // d'action en bas de feuille. C'est la seule forme de bouton que les
        // lots SW-SKIN-L3a..e ont du laisser en Material brut, faute
        // d'equivalent ici : deux commentaires du parc le disaient mot pour mot
        // (« le TextButton Annuler laisse tel quel »). D'ou cette variante,
        // tache 645-03.
        //
        // ISO-RENDU VOULU. On ne pose NI couleur NI forme quand l'appelant n'en
        // demande pas : le `textButtonTheme` du theme peint donc ce bouton
        // exactement comme il peignait le `TextButton` brut d'avant. `tone`
        // teinte le libelle et l'icone quand l'appel le demandait (ex. un
        // « Annuler » grise au contraste reduit).
        //
        // LARGEUR : `Size(64, ...)` quand le bouton n'est pas pleine largeur,
        // c'est le plancher de largeur de Material pour un bouton plat — sans
        // lui, un libelle de deux lettres donnerait un bouton plus etroit
        // qu'avant.
        return TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: tone,
            minimumSize: isFullWidth
                ? Size(double.infinity, minHeight)
                : Size(64, minHeight),
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
