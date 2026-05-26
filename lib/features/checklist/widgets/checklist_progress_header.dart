import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// En-tete avec la progression globale de la checklist.
///
/// Affiche un cercle de progression, le compteur et un message.
class ChecklistProgressHeader extends StatelessWidget {
  const ChecklistProgressHeader({
    super.key,
    required this.checkedCount,
    required this.totalCount,
    required this.progressLabel,
    required this.completeLabel,
  });

  /// Nombre d items coches
  final int checkedCount;

  /// Nombre total d items
  final int totalCount;

  /// Label de progression (ex: '12/25 prepares')
  final String progressLabel;

  /// Label quand tout est coche
  final String completeLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;
    final isComplete = checkedCount == totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        children: [
          // Cercle de progression
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 8,
                  backgroundColor:
                      theme.colorScheme.onSurface.withAlpha(30),
                  valueColor: AlwaysStoppedAnimation(
                    isComplete
                        ? AppTheme.vertFacile
                        : theme.colorScheme.primary,
                  ),
                ),
                Center(
                  child: isComplete
                      ? const Icon(
                          Icons.check_circle,
                          size: 48,
                          color: AppTheme.vertFacile,
                        )
                      : Text(
                          '${(progress * 100).round()}%',
                          style:
                              theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Label progression
          Text(
            isComplete ? completeLabel : progressLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isComplete
                  ? AppTheme.vertFacile
                  : theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
