import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Niveau de difficulte derive du ratio etapes / jours de marche (parite GR20).
///
/// GR20 (`ItineraryConfigScreen`) colore le curseur de duree selon
/// `stagesPerDay = nbEtapes / nbJours` : peu d'etapes par jour = confortable
/// (vert), beaucoup = tres exigeant (rouge). On reprend a l'identique les memes
/// seuils et la meme echelle de couleurs semantiques.
enum DurationDifficulty { comfortable, standard, sporty, demanding }

/// Calcule le niveau de difficulte a partir du ratio etapes / jours de marche.
///
/// Memes seuils que GR20 : <=0.8 confortable, <=1.0 standard, <=1.3 sportif,
/// au-dela tres exigeant. [walkingDays] = jours de MARCHE (repos exclus) pour
/// que la couleur reflete l'effort reel ; retombe sur « standard » si aucun
/// jour de marche (cas degenere).
DurationDifficulty durationDifficultyFor(int stageCount, int walkingDays) {
  if (walkingDays <= 0) return DurationDifficulty.standard;
  final stagesPerDay = stageCount / walkingDays;
  if (stagesPerDay <= 0.8) return DurationDifficulty.comfortable;
  if (stagesPerDay <= 1.0) return DurationDifficulty.standard;
  if (stagesPerDay <= 1.3) return DurationDifficulty.sporty;
  return DurationDifficulty.demanding;
}

/// Couleur semantique StepWays associee a un niveau de difficulte (parite GR20).
Color durationDifficultyColor(DurationDifficulty difficulty) {
  switch (difficulty) {
    case DurationDifficulty.comfortable:
      return AppTheme.vertFacile;
    case DurationDifficulty.standard:
      return AppTheme.jauneModere;
    case DurationDifficulty.sporty:
      return AppTheme.orangeDifficile;
    case DurationDifficulty.demanding:
      return AppTheme.rougeExtreme;
  }
}

/// Libelle i18n du niveau de difficulte (parite GR20 « Confortable / Standard /
/// Sportif / Tres exigeant »).
String durationDifficultyLabel(DurationDifficulty difficulty) {
  switch (difficulty) {
    case DurationDifficulty.comfortable:
      return t.programme.duration.difficulty.comfortable;
    case DurationDifficulty.standard:
      return t.programme.duration.difficulty.standard;
    case DurationDifficulty.sporty:
      return t.programme.duration.difficulty.sporty;
    case DurationDifficulty.demanding:
      return t.programme.duration.difficulty.demanding;
  }
}

/// Selecteur de duree pour le programme (parite GR20 : le CURSEUR de duree).
///
/// Reprend le curseur d'origine de GR20 (`ItineraryConfigScreen`) : un [Slider]
/// borne par le nombre d'etapes du sentier ([minDuration]..[maxDuration],
/// divisions entieres), dont la piste active et le pouce prennent la COULEUR de
/// la DIFFICULTE = ratio etapes / jours de marche. Au-dessus, la valeur courante
/// « {n} jours » est affichee en grand dans la meme couleur, avec un petit label
/// de difficulte (Confortable / Standard / Sportif / Tres exigeant), exactement
/// comme GR20. Sous le curseur, les bornes min / max encadrent la plage.
///
/// Hors systeme de peaux : les couleurs vert / jaune / orange / rouge sont des
/// couleurs SEMANTIQUES de difficulte (AppTheme), jamais la peau du sentier.
/// Tout libelle passe par Slang (t.programme.duration.*).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.minDuration,
    required this.maxDuration,
    required this.selectedDuration,
    required this.stageCount,
    required this.walkingDays,
    required this.onDurationChanged,
  });

  /// Nombre minimal de jours (borne basse du sentier).
  final int minDuration;

  /// Nombre maximal de jours (borne haute du sentier).
  final int maxDuration;

  /// Duree actuellement selectionnee (en jours).
  final int selectedDuration;

  /// Nombre total d'etapes du sentier (numerateur du ratio de difficulte).
  final int stageCount;

  /// Nombre de jours de MARCHE du programme courant (repos exclus) : denominateur
  /// du ratio de difficulte, pour que la couleur reflete l'effort reel.
  final int walkingDays;

  /// Callback appele quand l'utilisateur change la duree.
  final ValueChanged<int> onDurationChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final difficulty = durationDifficultyFor(stageCount, walkingDays);
    final sliderColor = durationDifficultyColor(difficulty);

    // Bornes securisees : un slider exige min < max et au moins 1 division.
    final min = minDuration.toDouble();
    final max = maxDuration.toDouble();
    final hasRange = max > min;
    final clamped = selectedDuration.toDouble().clamp(min, max);
    final divisions = hasRange ? (max - min).round() : 1;

    final daysLabel =
        t.programme.duration.days.replaceAll('{count}', '$selectedDuration');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Libelle de section + valeur courante coloree + label difficulte.
          Row(
            children: [
              Text(
                t.programme.duration.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Pastille de difficulte (couleur semantique + libelle i18n).
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: sliderColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(color: sliderColor.withAlpha(90)),
                ),
                child: Text(
                  durationDifficultyLabel(difficulty),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: sliderColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Valeur courante en grand, dans la couleur de difficulte (parite GR20).
          Text(
            daysLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: sliderColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Le curseur : couleur active = difficulte (parite GR20).
          Slider(
            value: clamped,
            min: min,
            max: hasRange ? max : min + 1,
            divisions: divisions,
            label: t.programme.duration.days
                .replaceAll('{count}', '${clamped.round()}'),
            activeColor: sliderColor,
            inactiveColor: AppTheme.grisGranite.withAlpha(40),
            onChanged: hasRange
                ? (value) => onDurationChanged(value.round())
                : null,
          ),
          // Bornes min / max sous le curseur (parite GR20).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.programme.duration.days.replaceAll('{count}', '$minDuration'),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                t.programme.duration.days.replaceAll('{count}', '$maxDuration'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
