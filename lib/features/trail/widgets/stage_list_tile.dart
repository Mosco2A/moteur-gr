/// Une etape en ligne de liste, avec sa duree ESTIMEE (calculee, non stockee)
/// et sa pastille de difficulte.
library;

import 'package:flutter/material.dart';

import '../../../core/models/stage_duration.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/stage_number_badge.dart';
import 'difficulty_badge.dart';
import 'elevation_indicator.dart';
import '../../../core/branding/stepways_icons.dart';

/// Carte d'étape pour la liste scrollable.
///
/// Affiche : numéro, nom, distance (km), dénivelé D+/D- (m),
/// durée estimée (calculée), badge de difficulté coloré.
/// Un tap déclenche [onTap] pour naviguer vers le détail.
class StageListTile extends StatelessWidget {
  const StageListTile({super.key, required this.stage, this.onTap});

  /// Modèle de l'étape à afficher
  final StageModel stage;

  /// Callback au tap (navigation vers détail)
  final VoidCallback? onTap;

  /// LA DURÉE DE L'ÉTAPE, PAR LA SOURCE UNIQUE DU DÉPÔT (tâche 839).
  ///
  /// CE QUI VIVAIT ICI, ET POURQUOI C'ÉTAIT UN DÉFAUT ET PAS SEULEMENT UNE
  /// REDITE. Cette ligne portait sa PROPRE arithmétique de temps de marche —
  /// `distanceKm / 4 + elevationGainM / 400` — et son propre formateur. Elle
  /// faisait donc deux choses que personne n'avait décidées :
  ///  1. elle IGNORAIT la durée fournie par la donnée du sentier
  ///     ([StageModel.estimatedDurationMinutes]), qui FAIT AUTORITÉ partout
  ///     ailleurs : la liste des étapes pouvait annoncer une durée et la fiche
  ///     de la MÊME étape une autre ;
  ///  2. elle ne payait pas la DESCENTE, que le modèle unique paie depuis la
  ///     tâche 839.
  /// [stageDurationMinutes] fait les deux correctement, et il ne reste aucune
  /// arithmétique de temps de marche dans ce fichier.
  static int durationMinutes(StageModel stage) => stageDurationMinutes(stage);

  /// Formate la durée en heures et minutes (ex: « 3h45 »).
  ///
  /// Délègue à [formatDurationMinutes], le formateur maison : « 4h » quand les
  /// minutes sont nulles, zéro-paddé sinon — exactement comme la fiche d'étape
  /// et l'écran d'itinéraire.
  static String formatDuration(int minutes) => formatDurationMinutes(minutes);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = durationMinutes(stage);

    return AppCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm / 2,
      ),
      child: Row(
        children: [
          // Numéro de l'étape dans un cercle (Hero vers le détail — E5.5a)
          StageNumberBadge(number: stage.stageNumber),
          const SizedBox(width: AppTheme.spacingMd),
          // Infos principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom + badge difficulté
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    DifficultyBadge(difficulty: stage.difficulty),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Distance + durée
                Row(
                  children: [
                    StepIcon(
                      StepwaysIcons.distance,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${stage.distanceKm.toStringAsFixed(1)} km',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: AppTheme.spacingMd),
                    StepIcon(
                      StepwaysIcons.clock,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formatDuration(duration),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXs),
                // Dénivelé D+ / D-
                ElevationIndicator(
                  gainM: stage.elevationGainM,
                  lossM: stage.elevationLossM,
                ),
              ],
            ),
          ),
          // Chevron de navigation
          StepIcon(
            StepwaysIcons.chevronDroite,
            color: theme.colorScheme.onSurface.withAlpha(120),
          ),
        ],
      ),
    );
  }
}
