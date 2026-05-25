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
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double elevation;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppTheme.radiusCard);
    final effectiveBg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final cardContent = Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveRadius,
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: elevation > 0
            ? [BoxShadow(color: Colors.black.withAlpha((elevation * 15).round()),
                blurRadius: elevation * 2, offset: Offset(0, elevation))]
            : null,
      ),
      child: child,
    );
    if (onTap != null) {
      return Padding(padding: margin ?? EdgeInsets.zero,
        child: InkWell(onTap: onTap, borderRadius: effectiveRadius, child: cardContent));
    }
    return Padding(padding: margin ?? EdgeInsets.zero, child: cardContent);
  }
}
