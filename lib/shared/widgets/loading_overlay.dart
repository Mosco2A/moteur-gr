import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message, this.opacity = 0.6});

  final String? message;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: Colors.black.withAlpha((opacity * 255).round()),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: theme.colorScheme.primary, strokeWidth: 3),
          if (message != null) ...[
            const SizedBox(height: AppTheme.spacingBase),
            Text(message!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
              textAlign: TextAlign.center),
          ],
        ]),
      ),
    );
  }
}
