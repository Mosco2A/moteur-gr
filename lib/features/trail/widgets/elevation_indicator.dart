import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Indicateurs de dénivelé positif (D+) et négatif (D-).
///
/// D+ : flèche vers le haut verte avec la valeur en mètres.
/// D- : flèche vers le bas rouge avec la valeur en mètres.
class ElevationIndicator extends StatelessWidget {
  const ElevationIndicator({
    super.key,
    required this.gainM,
    required this.lossM,
    this.fontSize = 13,
    this.iconSize = 16,
  });

  /// Dénivelé positif en mètres
  final int gainM;

  /// Dénivelé négatif en mètres
  final int lossM;

  /// Taille du texte
  final double fontSize;

  /// Taille des icônes flèches
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dénivelé positif (D+)
        Icon(
          Icons.arrow_upward,
          size: iconSize,
          color: AppTheme.vertFacile,
        ),
        const SizedBox(width: 2),
        Text(
          '${gainM}m',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.vertFacile,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        // Dénivelé négatif (D-)
        Icon(
          Icons.arrow_downward,
          size: iconSize,
          color: AppTheme.rougeUrgence,
        ),
        const SizedBox(width: 2),
        Text(
          '${lossM}m',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: AppTheme.rougeUrgence,
          ),
        ),
      ],
    );
  }
}
