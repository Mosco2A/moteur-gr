import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Badge coloré indiquant la difficulté d'une étape.
///
/// Couleurs par niveau :
///   easy     → vert
///   moderate → orange
///   hard     → rouge
///   expert   → violet
///
/// Le libellé est traduit en français pour l'affichage.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({super.key, required this.difficulty});

  /// Clé de difficulté (easy, moderate, hard, expert)
  final String difficulty;

  /// Associe chaque niveau à sa couleur
  static Color colorFor(String difficulty) {
    return switch (difficulty) {
      'easy' => AppTheme.vertFacile,
      'moderate' => AppTheme.orangeDifficile,
      'hard' => AppTheme.rougeExtreme,
      'expert' => const Color(0xFF7B1FA2),
      _ => AppTheme.grisGranite,
    };
  }

  /// Libellé traduit pour chaque niveau de difficulté
  static String labelFor(String difficulty) {
    return switch (difficulty) {
      'easy' => 'Facile',
      'moderate' => 'Modéré',
      'hard' => 'Difficile',
      'expert' => 'Expert',
      _ => difficulty,
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(difficulty);
    final label = labelFor(difficulty);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
