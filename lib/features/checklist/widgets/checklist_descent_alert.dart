import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../feasibility/domain/body_weight_reference.dart';
import '../../feasibility/domain/feasibility_formula.dart';
import '../../feasibility/providers/trek_feasibility_provider.dart';
import '../providers/checklist_provider.dart';

/// ALERTE DESCENTE — SORTIE 2 DU DISPOSITIF POIDS (#4-c, #4-j, #4-l).
///
/// POURQUOI ELLE VIT DANS LE SAC ET NON DANS LE MOTEUR. Le moteur de
/// faisabilite ne porte aucun terme de masse et aucun terme de descente : il n'y
/// a pas de coefficient energetique publie pour le denivele negatif (#M05). La
/// charge transportee, elle, est un fait que le Sac connait. L'alerte est donc
/// portee ici, par le dispositif poids, exactement la ou l'utilisateur peut y
/// faire quelque chose.
///
/// LA GRANDEUR EST SOURCEE, LE DECLENCHEUR NE L'EST PAS — ET ON NE L'INVENTE
/// PAS. Le travail excentrique est proportionnel a masse × D−, et les forces du
/// genou s'expriment en multiples du poids (#S23-a Kutzner 2010 : 261 % a plat,
/// 346 % en descente ; #S23-b Kuster 1995 : moment de flexion +117 %, puissance
/// +490 % a 11°). MAIS AUCUN SEUIL DE D− DANGEREUX N'EST PUBLIE (#M11).
///
/// LE DECLENCHEUR PAR PENTE MOYENNE A ETE INVALIDE PAR LA MESURE. Au seuil
/// publie de Langmuir (12°), l'etape 7 du Mare a Mare — 1 115 m de descente sur
/// 17,7 km — donne une pente moyenne de 3,6° : le seuil ne declencherait PAS sur
/// l'etape meme qui justifie l'alerte, parce que la moyenne dilue la descente.
/// Le dispositif CLASSE donc les etapes par D− decroissant et enonce la charge
/// une seule fois. Aucun seuil a inventer, donc aucun seuil a defendre.
///
/// GARDE-FOU DE REDACTION (#7-c). Le texte parle de masse TRANSPORTEE et de
/// charge mecanique. Il ne glisse pas vers « tu risques de te blesser » : #S14
/// (Zwolinski 2025, 162 randonneurs, p = 0,708) ne montre AUCUNE relation entre
/// categorie d'IMC et blessure en randonnee.
class ChecklistDescentAlert extends ConsumerWidget {
  const ChecklistDescentAlert({super.key, this.maxStages = 3});

  /// Nombre d'etapes citees (les plus descendantes).
  final int maxStages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(checklistProvider);
    final excess = BodyWeightReference.excessLoadKg(
      heightCm: state.bodyHeightCm,
      bodyWeightKg: state.bodyWeightKg,
      backpackKg: state.checkedWeightKg,
    );
    // Aucune reference calculable, ou aucune charge au-dela de la reference :
    // rien a dire, donc on ne dit rien. Une alerte qui se declenche toujours
    // n'alerte plus.
    if (excess == null || excess <= 0) return const SizedBox.shrink();

    final assessment = ref.watch(feasibilityAssessmentProvider).value;
    final stages = assessment == null
        ? const <StageVerdict>[]
        : assessment.stagesByDescentDesc
            .where((v) => v.stage.elevationLossM > 0)
            .take(maxStages)
            .toList();

    final theme = Theme.of(context);
    final w = t.checklist.weight;
    const color = AppTheme.orangeDifficile;

    return Container(
      key: const ValueKey('checklist-descent-alert'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_down, size: 20, color: color),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  w.descentAlertTitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            w.descentAlertBody.replaceAll('{kg}', excess.toStringAsFixed(1)),
            style: theme.textTheme.bodySmall,
          ),
          // Les etapes qui descendent le plus, nommees. Pas de seuil : un
          // classement.
          for (final v in stages) ...[
            const SizedBox(height: 2),
            Text(
              w.descentStage
                  .replaceAll('{stage}', v.stage.name)
                  .replaceAll('{loss}', '${v.stage.elevationLossM}'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
