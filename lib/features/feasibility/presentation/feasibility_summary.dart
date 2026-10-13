/// La synthese globale du verdict et son badge.
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

/// Avertit que le verdict repose sur un profil partiel.
class PartialProfileNotice extends StatelessWidget {
  /// Avertissement sans donnees : son texte est lu dans les traductions.
  const PartialProfileNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const color = AppTheme.orangeDifficile;
    return AppCard(
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(80),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepIcon(StepwaysIcons.info, size: 20, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.feasibility.flow.partialNotice,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Synthese textuelle du verdict global (hors tout vert).
class FeasibilityGlobalSummary extends StatelessWidget {
  const FeasibilityGlobalSummary({super.key, required this.assessment});
  final FeasibilityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.formula;
    final color = verdictColor(assessment.globalVerdict);

    final lines = <Widget>[];

    // Etape la plus dure (nommee) si le trek n'est pas tout vert.
    final hardest = assessment.hardestStage;
    if (hardest != null &&
        assessment.globalVerdict != FeasibilityVerdict.green) {
      lines.add(
        _summaryLine(
          theme,
          StepwaysIcons.denivelePlus,
          f.hardestStage(stage: hardest.stage.name),
          color,
        ),
      );
    }

    // LE JARGON « X JOUR(S) AU-DESSUS DE TON PLAFOND » EST PARTI (retour Chris
    // 4 du 25/09). Mot pour mot : « je suis 3 jours au-dessus du plafond, ce qui
    // ne veut rien dire ». Ce comptage est une grandeur INTERNE du moteur
    // ([FeasibilityAssessment.daysOverCapacity], qui sert a nommer le facteur
    // limitant quand plusieurs journees dures s'enchainent) : elle a sa place
    // dans le calcul, aucune a l'ecran. Ce que le randonneur doit lire a la
    // place, c'est le nombre de jours a viser — il est desormais EN TETE
    // d'ecran ([FeasibilityAdviceFirst]).

    // Facteur limitant nomme (si present).
    if (assessment.limitingFactor != LimitingFactor.none) {
      lines.add(
        _summaryLine(
          theme,
          StepwaysIcons.danger,
          f.limitingLabel(
            factor: limitingFactorLabel(assessment.limitingFactor),
          ),
          color,
        ),
      );
    }

    // Reco entrainement (si non-vert).
    if (assessment.recommendedTrainingWeeks > 0) {
      lines.add(
        _summaryLine(
          theme,
          StepwaysIcons.calendrier,
          f.trainingReco(weeks: assessment.recommendedTrainingWeeks),
          theme.colorScheme.primary,
        ),
      );
    }

    // Plus une ligne a dire (verdict vert, aucun facteur limitant, aucune reco)
    // -> aucune carte vide : un encart sans contenu n'informe de rien.
    if (lines.isEmpty) return const SizedBox.shrink();

    return AppCard(
      backgroundColor: color.withAlpha(14),
      borderColor: color.withAlpha(60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lines.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTheme.spacingSm),
            lines[i],
          ],
        ],
      ),
    );
  }

  Widget _summaryLine(ThemeData theme, String icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepIcon(icon, size: 20, color: color),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}

/// Badge du verdict global (feu tricolore).
class FeasibilityVerdictBadge extends StatelessWidget {
  const FeasibilityVerdictBadge({super.key, required this.verdict});
  final FeasibilityVerdict verdict;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = verdictColor(verdict);
    final icon = verdictIcon(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingBase,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StepIcon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(
            child: Text(
              verdictLabel(verdict),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
