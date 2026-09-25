import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
///
/// DEUX NOMBRES, PLUS JAMAIS UN TOTAL (retour Chris 25/09, tache 552). Mot pour
/// mot : « Descente et poid du sac, je ne comprends pas le texte ». Le texte
/// additionnait dans un seul chiffre les kilos du SAC et les kilos AU-DESSUS DU
/// POIDS DE FORME — or l'utilisateur ne peut agir que sur le sac, et il ne
/// savait pas ce qui venait de quoi. Les deux nombres sont desormais ENONCES
/// SEPAREMENT, le chiffre mecanique est UNIQUE et source (#S23-a Kutzner 2010 :
/// 3,46 fois le poids en descente contre 2,61 a plat), et l'action est UNIQUE :
/// alleger le sac. Quand il n'y a rien au-dessus du poids de forme, on n'ecrit
/// pas « 0,0 kg » : le texte bascule sur la variante SAC SEUL — on se tait sur
/// ce qu'on n'a pas.
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

    // LES DEUX PARTS, SEPAREES (tache 552). Meme arithmetique que
    // `excessLoadKg` — dont elles sont exactement les deux termes — mais
    // affichees une par une : le sac est la part sur laquelle l'utilisateur
    // peut agir, l'autre ne se regle pas en bouclant un sac.
    final packKg = math.max(0.0, state.checkedWeightKg);
    final reference =
        BodyWeightReference.referenceMassKg(state.bodyHeightCm) ?? 0.0;
    final aboveReferenceKg = math.max(0.0, state.bodyWeightKg - reference);

    // LE SEPARATEUR DECIMAL SUIT LA LANGUE. Sans ca, la phrase francaise
    // melangeait « 10.0 kg » (point) et « 3,46 fois » (virgule) dans la meme
    // ligne : deux conventions dans une phrase que Chris a justement dit ne pas
    // comprendre. L'anglais garde le point, les quatre autres langues la
    // virgule — c'est intl qui le sait, pas nous.
    final nombre = NumberFormat.decimalPatternDigits(
      locale: LocaleSettings.currentLocale.languageCode,
      decimalDigits: 1,
    );

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
            // Sous 0,05 kg l'arrondi afficherait « 0,0 kg au-dessus de ton
            // poids de forme » : un nombre nul enonce comme un fait. On passe
            // alors a la variante qui ne parle que du sac.
            aboveReferenceKg >= 0.05
                ? w.descentAlertBody
                    .replaceAll('{pack}', nombre.format(packKg))
                    .replaceAll('{above}', nombre.format(aboveReferenceKg))
                : w.descentAlertBodyPackOnly
                    .replaceAll('{pack}', nombre.format(packKg)),
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
