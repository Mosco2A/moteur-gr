/// Les trois sections depliables du verdict : comment il est
/// calcule, le circuit, les conditions.
///
/// Bibliotheque de l'ecran `trek_feasibility_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../i18n/translations.g.dart';
import '../../../domain/feasibility_formula.dart';
import '../../../core/branding/stepways_icons.dart';
import 'feasibility_labels.dart';

/// LE CALCUL, MONTRE LA OU LE VERDICT TOMBE (tache 569, R3).
///
/// CE QUE CHRIS A ECRIT, MOT POUR MOT : « Le verdict c'est du blabla d'IA, tu
/// mexplique comment c'est calcule au moment ou ca le fait? » et « score 1,30
/// sans echelle ca ne veut rien dire ».
///
/// IL N'Y A AUCUNE IA DANS CETTE APPLICATION — zero dependance, verifie — et
/// c'est precisement le probleme : le moteur est une formule deterministe et
/// sourcee, mais l'ecran affichait un verdict et un score nu, ce qui se lit
/// exactement comme une boite noire. Un chiffre sans son echelle n'informe de
/// rien : 1,30 peut etre bon ou catastrophique selon ou tombe le seuil.
///
/// CE BLOC MONTRE LA DIVISION, AVEC LES CHIFFRES REELS DU RANDONNEUR : la
/// journee la plus dure et sa geometrie, sa conversion en km-energie (distance +
/// D+ / 42, Minetti 2002), le plafond du jour du randonneur, le rapport des deux,
/// et l'echelle qui dit ou tombent le vert et l'orange. Il ne dit JAMAIS « ce
/// n'est pas une IA » — on ne se defend pas d'une accusation, on montre le
/// calcul et on nomme les travaux qui le nourrissent.
class FeasibilityVerdictHowSection extends StatelessWidget {
  const FeasibilityVerdictHowSection({super.key, required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final hardest = assessment.hardestStage;
    if (hardest == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    const thresholds = FeasibilityThresholds.median;

    // Les memes chiffres que ceux qui ont produit la couleur, formates une
    // seule fois : deux arrondis differents dans une division affichee se
    // liraient comme une erreur de calcul.
    final distance = formatEnergyKm(hardest.stage.distanceKm);
    final energy = formatEnergyKm(hardest.energyKm);
    final capacity = formatEnergyKm(hardest.capacityKm);

    final lines = <String>[
      f.verdictHowStage(
        stage: hardest.stage.name,
        distance: distance,
        elevation: hardest.stage.elevationGainM,
      ),
      f.verdictHowEnergy(
        distance: distance,
        elevation: hardest.stage.elevationGainM,
        energy: energy,
      ),
      f.verdictHowCeiling(
        capacity: capacity,
        level: hikerLevelLabel(assessment.level),
      ),
      f.verdictHowRatio(
        energy: energy,
        capacity: capacity,
        score: formatTwoDecimals(hardest.score),
        green: formatTwoDecimals(thresholds.green),
        orange: formatTwoDecimals(thresholds.orange),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.verdictHowTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          key: const ValueKey('feasibility-verdict-how'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines) ...[
                Text(line, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppTheme.spacingXs),
              ],
              Text(
                f.verdictHowNoBlackBox,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// LE SCORE DE CIRCUIT (#2-m a #2-t) — les quatre contraintes, celle qui mord,
/// et l'explication OBLIGATOIRE d'ARB-004.
///
/// CE QUE CETTE SECTION EVITE. Le verdict global n'est plus la pire etape : il
/// est le maximum de trois contraintes normalisees, dont deux ne se voient dans
/// AUCUNE etape prise isolement. Sans cette section, un randonneur verrait sept
/// etapes vertes surmontees d'un circuit rouge et conclurait a un bug — c'est
/// exactement pour cela que la spec rend l'explication obligatoire.
class FeasibilityCircuitSection extends StatelessWidget {
  const FeasibilityCircuitSection({super.key, required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final circuit = assessment.circuit;
    if (circuit == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final color = verdictColor(circuit.verdict);

    final lines = <Widget>[];

    // LE SCORE NE S'AFFICHE PLUS JAMAIS NU (tache 569, R3). Chris : « score 1,30
    // sans echelle ca ne veut rien dire ». Il porte desormais ses deux seuils,
    // au meme endroit et dans la meme phrase.
    lines.add(
      Text(
        f.circuitScore(
          value: formatTwoDecimals(circuit.score),
          green: formatTwoDecimals(FeasibilityThresholds.median.green),
          orange: formatTwoDecimals(FeasibilityThresholds.median.orange),
        ),
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
    lines.add(const SizedBox(height: AppTheme.spacingXs));
    // CE QUI DECIDE, DIT EN CLAIR. Le verdict du circuit est celui de sa pire
    // journee, et rien d'autre ne peut le durcir : la phrase le dit, pour que
    // le randonneur sache ou regarder quand il veut le faire bouger.
    lines.add(
      Text(
        f.circuitIsWorstStage,
        key: const ValueKey('feasibility-circuit-is-worst-stage'),
        style: theme.textTheme.bodySmall,
      ),
    );

    // --- CE QUI S'AFFICHE ET NE DECIDE PAS ---------------------------------
    final infoStyle = theme.textTheme.bodySmall?.copyWith(
      fontStyle: FontStyle.italic,
      color: theme.colorScheme.onSurface.withAlpha(150),
    );

    // C3, LE REPOS : sa fenetre, son chiffre, le conseil qui va avec — ou sa
    // NON-APPLICABILITE declaree (#10-e).
    //
    // IL A CHANGE DE STATUT (GO-61) : il etait la seule grandeur extrapolee du
    // modele autorisee a mettre au rouge, il rejoint C2 et C4 dans ce qui
    // s'affiche et ne decide pas. Ce qui reste — et qui compte — c'est le
    // CONSEIL : combien de jours de repos, et apres quelles etapes.
    lines.add(const SizedBox(height: AppTheme.spacingSm));
    if (!circuit.isRestApplicable) {
      lines.add(
        Text(
          f.restNotApplicable,
          key: const ValueKey('feasibility-rest-not-applicable'),
          style: theme.textTheme.bodySmall,
        ),
      );
    } else {
      lines.add(
        Text(
          circuit.monotonyCoversWholeTrek
              ? f.restWindowWhole(days: circuit.totalDays)
              : f.restWindowSlice(
                  start: circuit.monotonyWindowStartDay ?? 1,
                  end: circuit.monotonyWindowEndDay ?? circuit.totalDays,
                ),
          style: theme.textTheme.bodySmall,
        ),
      );
      // LE LIEN ENTRE LE PROGRAMME ET CE CHIFFRE, ECRIT. Sans cette ligne, le
      // randonneur ne voit pas que c'est SON programme qui le produit, ni que
      // changer le programme le fait bouger.
      lines.add(const SizedBox(height: 2));
      lines.add(
        Text(
          assessment.restDaysPlanned > 0
              ? f.restDaysCounted(count: assessment.restDaysPlanned)
              : f.restDaysNone,
          key: const ValueKey('feasibility-rest-days-counted'),
          style: theme.textTheme.bodySmall,
        ),
      );
      if (assessment.isRestAdvised) {
        lines.add(const SizedBox(height: 2));
        lines.add(
          Text(
            f.restAdvisedLine(days: assessment.recommendedRestDays),
            key: const ValueKey('feasibility-rest-advised'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        lines.add(const SizedBox(height: 2));
        lines.add(Text(f.restTwoDays, style: theme.textTheme.bodySmall));
      }
      // Le transfert du seuil de Foster des athletes aux randonneurs est une
      // extrapolation DECLAREE (#M08), et c'est elle qui lui a coute le droit
      // de decider. On la dit la ou le chiffre est montre.
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.restNotDecisive, style: infoStyle));
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.restExtrapolation, style: infoStyle));
    }

    // C2, la charge moyenne : sortie du maximum (elle est la moyenne d'une
    // serie dont C1 est le maximum, donc elle ne pouvait rien decider), mais
    // elle informe reellement — lue AVEC C1, elle distingue « une journee
    // dure » de « dur tous les jours ».
    if (circuit.averageLoad.isFinite) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(
        Text(
          f.averageLoad(
            value: formatTwoDecimals(circuit.averageLoad),
            worst: formatTwoDecimals(circuit.worstStage),
          ),
          key: const ValueKey('feasibility-average-load'),
          style: theme.textTheme.bodySmall,
        ),
      );
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.averageLoadInfo, style: infoStyle));
    }

    // C4, l'ecart a l'habitude : AFFICHE, JAMAIS DECISIF (#2-q).
    final habit = circuit.habitGap;
    if (habit != null && habit.isFinite) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(
        Text(
          f.habitGap(value: formatTwoDecimals(habit)),
          style: theme.textTheme.bodySmall,
        ),
      );
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.habitGapNotDecisive, style: infoStyle));
    }

    // LA DUREE, ENONCEE. Le modele ne la capte nulle part : C3 mesure une
    // REGULARITE, pas une LONGUEUR, et rend le meme chiffre pour trois jours et
    // pour dix-sept. Aucun seuil publie n'existe pour la scorer, donc on
    // n'invente rien — on dit le fait et le randonneur juge.
    if (assessment.hasDurationStatement) {
      lines.add(const SizedBox(height: AppTheme.spacingSm));
      lines.add(
        Text(
          f.durationStatement(
            days: assessment.walkingDays,
            done: assessment.longestConsecutiveDaysDone,
          ),
          key: const ValueKey('feasibility-duration-statement'),
          style: theme.textTheme.bodySmall,
        ),
      );
      lines.add(const SizedBox(height: 2));
      lines.add(Text(f.durationStatementInfo, style: infoStyle));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.circuitTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          backgroundColor: color.withAlpha(14),
          borderColor: color.withAlpha(60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      ],
    );
  }
}

/// CE QUI EST ENTRE DANS CE VERDICT, ET CE QUI N'Y EST PAS ENTRE (#8-b).
///
/// LA DISTINCTION QUE CETTE SECTION PORTE. « L'altitude ne change rien ici »
/// peut vouloir dire deux choses opposees : que le sentier culmine sous le
/// seuil ou QUE LA TRACE N'EN PORTE PAS. Dans le premier cas le verdict est
/// complet, dans le second il est aveugle sur une dimension. Une application de
/// securite en montagne doit dire laquelle des deux.
class FeasibilityConditionsSection extends StatelessWidget {
  const FeasibilityConditionsSection({super.key, required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final conditions = assessment.conditions;
    final lines = <String>[];

    // 1. L'unite d'energie, dite une fois : le chiffre affiche partout en
    // decoule, et 42 n'est pas un nombre qu'on devine.
    lines.add(f.energyUnitNotice);

    // 2. Le plancher demontre, quand il a REELLEMENT releve la capacite.
    if (assessment.isDemonstratedFloorActive) {
      lines.add(
        f.floorActive(
          value: formatEnergyKm(assessment.demonstratedFloorEnergyKm),
        ),
      );
    }

    // 3. L'altitude : appliquee, sous le seuil, ou absente de la trace.
    final altitude = conditions.maxAltitudeM;
    switch (conditions.altitudeNeutralReason) {
      case NeutralReason.missingData:
        lines.add(f.altitudeMissing);
        break;
      case NeutralReason.belowThreshold:
        lines.add(f.altitudeBelowThreshold(value: altitude!.round()));
        break;
      default:
        lines.add(
          f.altitudeApplied(
            value: (altitude ?? 0).round(),
            pct: formatEnergyKm((1 - conditions.altitudeFactor) * 100),
          ),
        );
    }

    // 4. La saison : ete chiffre, printemps/automne sans source, ou pas de
    // date de depart posee. L'hiver est deja declare plus haut.
    if (!conditions.isWinterDeparture) {
      switch (conditions.seasonNeutralReason) {
        case NeutralReason.missingData:
          lines.add(f.seasonMissing);
          break;
        case NeutralReason.noPublishedSource:
          lines.add(f.seasonNoSource);
          break;
        default:
          lines.add(f.heatApplied);
      }
    }

    // 5. La masse : hors du verdict, ET C'EST UNE PROPRIETE ASSUMEE (#3-d).
    lines.add(f.massNotCounted);

    // 6. L'AGE : DANS le verdict, et il fallait le dire (tache 570, S1).
    //
    // CETTE SECTION AVAIT UN TROU, ET IL ETAIT DU MAUVAIS COTE. Elle declarait
    // ce que le poids NE FAIT PAS (« ni ton poids ni celui de ton sac
    // n'entrent dans ce verdict ») et taisait ce que l'age FAIT. Le randonneur
    // pouvait donc en deduire l'inverse de la verite : que sa morphologie pese
    // et que son age est decoratif. C'est exactement la lecture qui a fait
    // conclure que « l'age ne sert a rien ».
    //
    // L'age agit a deux endroits : il retire un cran de niveau a partir de 60
    // ans et deux a partir de 75 (`FeasibilityFormula.deriveLevel`), et il fixe
    // la distance de reference du test de marche (`WalkTestNorms.predictedFor`,
    // equations d'Enright). La ligne est STATIQUE comme celle de la masse : elle
    // enonce la regle, pas la valeur de ce randonneur — la valeur, c'est sa
    // fiche qui la porte, et cette section dit ce qui entre, pas ce qu'on sait
    // de lui.
    lines.add(f.ageCounted);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(f.conditionsTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          key: const ValueKey('feasibility-conditions'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: StepIcon(
                        StepwaysIcons.pastille,
                        size: 6,
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(line, style: theme.textTheme.bodySmall),
                    ),
                  ],
                ),
                if (line != lines.last)
                  const SizedBox(height: AppTheme.spacingXs),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
