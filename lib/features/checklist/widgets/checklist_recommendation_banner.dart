import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Bandeau « Poids recommande » — CLONE GR20 (BackpackRecommendationBanner).
///
/// GR20 calcule le poids recommande selon le PROFIL DE NUITEES (bivouac /
/// refuge / gite) du planning. StepWays (moteur generique multi-sentiers) n'a
/// pas ce profil de nuitees par etape ; on clone donc le rendu du bandeau avec
/// la recommandation par defaut de GR20 (= max(poids refuge de reference,
/// 15% du poids corporel)), exactement comme GR20 le fait quand aucune nuitee
/// n'est configuree. Le detail par type de nuitee est un ecart residuel
/// documente (couplage planning GR20 absent du modele generique).
class ChecklistRecommendationBanner extends StatelessWidget {
  const ChecklistRecommendationBanner({super.key, required this.bodyWeightKg});

  final double bodyWeightKg;

  /// Poids de reference « refuge » (parite GR20 BackpackReferenceWeights.refuge).
  static const double _refugeReferenceKg = 8.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = t.checklist.weight;

    // Parite GR20 (branche isEmpty) : max(reference refuge, 15% du corps).
    final minByBody = bodyWeightKg * 0.15;
    final recommendedKg =
        _refugeReferenceKg > minByBody ? _refugeReferenceKg : minByBody;
    const color = AppTheme.orangeDifficile;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingXs,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.cabin, size: 24, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              // Reutilise le libelle « X kg » (unite kg via Slang).
              '${w.title} : ${recommendedKg.toStringAsFixed(1)} ${w.kilograms}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
