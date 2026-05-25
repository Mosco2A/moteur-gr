import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.onSeeAll,
    this.seeAllLabel = 'Voir tout',
    this.trailing,
  });

  final String title;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onSeeAll;
  final String seeAllLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
        ],
        Expanded(child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontSize: 18))),
        if (trailing != null) trailing!
        else if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
              minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(seeAllLabel, style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.secondary),
            ]),
          ),
      ]),
    );
  }
}
