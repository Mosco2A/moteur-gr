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
///
/// FIX-2 (finding M3bis) — LE LIBELLE DISAIT LE CONTRAIRE DE LA VALEUR. Ce
/// bandeau reutilisait `checklist.weight.title` (« Poids du sac ») devant une
/// valeur qui n'est PAS le poids du sac mais la RECOMMANDATION. Sac vide
/// (0 g, 0 article coche) il annoncait quand meme « Poids du sac : 13.3 kg »,
/// et avec le poids corporel non borne d'avant FIX-1 il allait jusqu'a
/// « Poids du sac : 133.5 kg ». Le libelle est desormais
/// `checklist.weight.recommended` (« Poids recommande », wording GR20
/// `backpack_screen.dart` : « Poids recommande : X kg ») : le bandeau dit ce
/// qu'il montre. Le poids REEL du sac reste celui de [ChecklistWeightBanner].
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
              // Libelle DEDIE a la recommandation (jamais « Poids du sac » :
              // cette valeur ne depend pas du contenu du sac, M3bis).
              '${w.recommended} : '
              '${recommendedKg.toStringAsFixed(1)} ${w.kilograms}',
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
