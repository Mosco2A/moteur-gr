import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/step_status_icon.dart';
import '../domain/models/health_info.dart';

/// La COCHE A TROIS ETATS de la fiche medicale (tache 837).
///
/// Christophe : « Fiche medicale dans profil », et elle reste listee dans la
/// check-list de preparation de chaque randonnee, « cochee ou non selon sa
/// completude ». La fiche devient donc une DONNEE DU PROFIL, remplie une fois
/// pour toutes ; la check-list ne la remplit plus, elle CONSTATE son etat.
///
/// Ce widget est le seul endroit ou l'etat se traduit en pixels : le profil et
/// la check-list l'utilisent tous les deux, donc ils ne peuvent pas afficher
/// deux verdicts differents de la meme fiche.
///
/// Rendu : reutilise [StepStatusIcon], la coche a trois etats qui DORMAIT dans
/// le depot (`PlanningStepStatus`, aucun appelant). Ses trois etats ont des
/// FORMES distinctes (cercle vide / sablier / coche pleine) et pas seulement
/// trois couleurs — lisible en vision des couleurs deficiente. Le libelle part
/// en [Semantics] : un lecteur d'ecran annonce « A remplir / Partiellement
/// remplie / Complete », jamais « image ».
class HealthSheetCheck extends StatelessWidget {
  const HealthSheetCheck({super.key, required this.completion, this.size = 20});

  /// L'etat constate de la fiche.
  final HealthSheetCompletion completion;

  /// Taille de l'icone (defaut 20, iso-[StepStatusIcon]).
  final double size;

  /// Le libelle traduit de l'etat [c] (5 langues, cles `health.completion.*`).
  static String label(Translations i18n, HealthSheetCompletion c) {
    switch (c) {
      case HealthSheetCompletion.empty:
        return i18n.health.completion.empty;
      case HealthSheetCompletion.partial:
        return i18n.health.completion.partial;
      case HealthSheetCompletion.complete:
        return i18n.health.completion.complete;
    }
  }

  /// Correspondance etat de fiche -> etat de coche. Ecrite UNE fois ici pour
  /// que « partielle » ne devienne jamais « traite » dans un coin de l'app.
  static PlanningStepStatus statusOf(HealthSheetCompletion c) {
    switch (c) {
      case HealthSheetCompletion.empty:
        return PlanningStepStatus.notStarted;
      case HealthSheetCompletion.partial:
        return PlanningStepStatus.inProgress;
      case HealthSheetCompletion.complete:
        return PlanningStepStatus.completed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = Translations.of(context);
    return Semantics(
      label: label(i18n, completion),
      child: StepStatusIcon(status: statusOf(completion), size: size),
    );
  }
}
