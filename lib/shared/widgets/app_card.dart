import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.elevation = 2,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  /// Epaisseur du liseré quand [borderColor] est fourni (defaut 1.0). Permet de
  /// conserver un contour semantique existant a l'identique — ex. la carte de
  /// prevision en etat alerte, liseré rouge 1.5px (SW-SKIN-L3b) — sans recourir
  /// a un parametre jetable. Sans effet si [borderColor] est null.
  final double? borderWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppTheme.radiusCard);
    final effectiveBg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;

    // Le contenu est enveloppe dans un Material transparent : comme la `Card`
    // Material (qu'AppCard remplace, SW-SKIN-L3), cela fournit l'ancetre
    // Material requis par les widgets a encre (ListTile, InkWell, Switch...) et
    // borne les splashs au rayon de la carte. Transparent + meme rayon => aucun
    // changement visuel pour les appelants existants (le fond/ombre restent
    // peints par le Container ci-dessous) ; on ne fait qu'ajouter le support
    // d'encre qui manquait, evitant "No Material widget found" hors Scaffold.
    final Widget inner = Material(
      type: MaterialType.transparency,
      borderRadius: effectiveRadius,
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, borderRadius: effectiveRadius, child: Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.spacingBase),
              child: child))
          : Padding(
              padding: padding ?? const EdgeInsets.all(AppTheme.spacingBase),
              child: child),
    );

    final cardContent = Container(
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth ?? 1.0)
            : null,
        boxShadow: elevation > 0
            ? [BoxShadow(color: Colors.black.withAlpha((elevation * 15).round()),
                blurRadius: elevation * 2, offset: Offset(0, elevation))]
            : null,
      ),
      child: inner,
    );

    return Padding(padding: margin ?? EdgeInsets.zero, child: cardContent);
  }
}
