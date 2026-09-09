import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Statut de completion d'un sujet de preparation (coche « sujet traite »),
/// clone du `PlanningStepStatus` de GR20 (home_screen.dart B-19c).
///
/// StepWays n'a PAS (encore) de `planningProgressProvider` persiste (LOT-A
/// differe) : le statut est DERIVE a la volee cote cockpit depuis les faits
/// deja connus (progression / planification du sentier). L'enum reste identique
/// a GR20 (3 etats) pour cloner le rendu a l'identique.
enum PlanningStepStatus {
  /// Rien fait sur ce sujet.
  notStarted,

  /// Sujet entame mais pas termine.
  inProgress,

  /// Sujet traite (coche verte).
  completed,
}

/// Icone de statut de progression d'un sujet — CLONE GR20 `_buildStepStatusIcon`
/// (home_screen.dart:1186-1207), memes icones et memes couleurs :
///  - [PlanningStepStatus.completed]  -> `check_circle` vert (vertMaquisLight) ;
///  - [PlanningStepStatus.inProgress] -> `timelapse` orange (orangeTerre) ;
///  - [PlanningStepStatus.notStarted] -> `radio_button_unchecked` gris.
///
/// FORME DISTINCTE par etat (unchecked / timelapse / check) : la lisibilite ne
/// repose PAS sur la seule couleur -> OK daltonisme (parite intention GR20).
/// Zero couleur en dur : les teintes viennent des tokens `AppTheme` /
/// `CategoryIconColors` (parite GR20 vertMaquisLight/orangeTerre/grisGranite).
class StepStatusIcon extends StatelessWidget {
  const StepStatusIcon({super.key, required this.status, this.size = 20});

  /// Statut a representer.
  final PlanningStepStatus status;

  /// Taille de l'icone (defaut 20, iso-GR20).
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case PlanningStepStatus.notStarted:
        return Icon(
          Icons.radio_button_unchecked,
          size: size,
          // Gris neutre (parite GR20 : gris 0xFF9E9E9E ~ grisGranite du socle).
          color: AppTheme.grisGranite,
        );
      case PlanningStepStatus.inProgress:
        return Icon(
          Icons.timelapse,
          size: size,
          // Orange (parite GR20 orangeTerre -> token categoriel orange).
          color: AppTheme.orangeDifficile,
        );
      case PlanningStepStatus.completed:
        return Icon(
          Icons.check_circle,
          size: size,
          // Vert (parite GR20 vertMaquisLight -> token phase Randonner / vert).
          color: AppTheme.phaseHike,
        );
    }
  }
}
