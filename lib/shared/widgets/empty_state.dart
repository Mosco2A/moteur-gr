import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = 64,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: iconSize, color: iconColor ?? AppTheme.grisTexteSecondaire.withAlpha(120)),
          const SizedBox(height: AppTheme.spacingBase),
          Text(title, style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.grisTexteSecondaire),
            textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(subtitle!, style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire.withAlpha(180)), textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: AppTheme.spacingLg), action!],
        ]),
      ),
    );
  }
}
