/// Le choix propose quand une AUTRE rando est deja en cours : terminer,
/// abandonner, annuler. La couche data reste sans Flutter.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../trek/trek_facade.dart' show ActiveTrekConflictChoice;

/// UI de resolution du CONFLIT d'unicite de rando active (StepWays LOT 2, C4).
///
/// Concretise le contrat data<->UI [ActiveTrekConflictResolver] : quand
/// [TrekSessionManagerNotifier.ensureSingleActiveThenStart] detecte qu'un AUTRE
/// trek est deja en cours, il appelle ce resolver qui presente un dialog
/// « Terminer / Abandonner / Annuler » et renvoie le [ActiveTrekConflictChoice]
/// choisi. La couche data reste sans dependance Flutter — c'est ici, cote UI,
/// qu'on branche un vrai dialog.
///
/// Fermer le dialog (barriere / retour systeme) equivaut a [cancel] (choix le
/// plus sur : on ne demarre pas, on ne touche pas la rando en cours).
///
/// [ongoingTrailId] est fourni par la garde (le sentier deja en cours) ; on ne
/// l'affiche pas tel quel (id technique) mais il reste disponible pour un
/// libelle enrichi ulterieur — le message reste generique et localise.
Future<ActiveTrekConflictChoice> showActiveTrekConflictDialog(
  BuildContext context,
  // ignore: avoid_unused_constructor_parameters
  String ongoingTrailId,
) async {
  final t = Translations.of(context);

  final choice = await showDialog<ActiveTrekConflictChoice>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AlertDialog(
        key: const ValueKey('active-trek-conflict-dialog'),
        title: Text(t.trekState.abandonDialog.title),
        content: Text(t.trekState.abandonDialog.message),
        actionsOverflowButtonSpacing: AppTheme.spacingSm,
        actions: [
          // Annuler : ne rien faire (garder la rando en cours).
          AppButton(
            key: const ValueKey('conflict-cancel'),
            variant: AppButtonVariant.text,
            label: t.trekState.abandonDialog.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ActiveTrekConflictChoice.cancel),
          ),
          // Abandonner la rando en cours (status=abandoned), puis demarrer.
          AppButton(
            key: const ValueKey('conflict-abandon'),
            variant: AppButtonVariant.text,
            tone: AppTheme.rougeUrgence,
            label: t.trekState.abandonDialog.abandon,
            isFullWidth: false,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ActiveTrekConflictChoice.abandonCurrent),
          ),
          // Terminer la rando en cours (status=completed), puis demarrer.
          AppButton(
            key: const ValueKey('conflict-finish'),
            label: t.trekState.abandonDialog.finish,
            isFullWidth: false,
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(ActiveTrekConflictChoice.finishCurrent),
          ),
        ],
      );
    },
  );

  // Barriere/retour systeme -> choix le plus sur : ne pas demarrer.
  return choice ?? ActiveTrekConflictChoice.cancel;
}
