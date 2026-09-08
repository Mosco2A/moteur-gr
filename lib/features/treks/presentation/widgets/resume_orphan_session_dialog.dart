import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';

/// Choix de l'utilisateur face a une session ORPHELINE detectee au boot
/// (StepWays LOT 2, C4 — reprise orpheline, complement §3).
///
/// Distinct du CONFLIT de demarrage ([ActiveTrekConflictChoice]) : ici l'app
/// vient de detecter, AU LANCEMENT, une rando laissee `active`|`paused` par un
/// arret brutal ([pendingSessionProvider]). On propose simplement de la
/// **Reprendre** (rejoindre le cockpit) ou de l'**Abandonner** (status=abandoned,
/// jamais `parcoursFullyWalked` : pas de faux finisher).
enum ResumeOrphanChoice {
  /// Reprendre la rando orpheline : selectionner son sentier + rejoindre le
  /// cockpit. La session reste `active`|`paused`.
  resume,

  /// Abandonner la rando orpheline (`abandoned`). Le trek retombe `prepared`
  /// (rejouable) — aucun drapeau finisher pose.
  abandon,
}

/// Presente le dialog de reprise de session orpheline et renvoie le choix.
///
/// Calque le style de `showActiveTrekConflictDialog` (AlertDialog, cles de test,
/// couleur d'abandon). On N'AFFICHE PAS l'identifiant technique du sentier : le
/// message reste generique et localise (5 langues, `trekState.resumeOrphanDialog`).
///
/// La barriere / le retour systeme NE sont PAS dismissibles : au boot, laisser la
/// session dans un etat indetermine reintroduirait l'orpheline au prochain
/// lancement. L'utilisateur DOIT trancher Reprendre / Abandonner. Le `Future` ne
/// se resout donc jamais sur `null` par fermeture accidentelle.
Future<ResumeOrphanChoice?> showResumeOrphanSessionDialog(
  BuildContext context,
) {
  final t = Translations.of(context);

  return showDialog<ResumeOrphanChoice>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        key: const ValueKey('resume-orphan-session-dialog'),
        title: Text(t.trekState.resumeOrphanDialog.title),
        content: Text(t.trekState.resumeOrphanDialog.message),
        actionsOverflowButtonSpacing: AppTheme.spacingSm,
        actions: [
          // Abandonner la rando orpheline (status=abandoned) : le trek redevient
          // rejouable, aucun drapeau finisher.
          TextButton(
            key: const ValueKey('resume-orphan-abandon'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(ResumeOrphanChoice.abandon),
            child: Text(
              t.trekState.resumeOrphanDialog.abandon,
              style: const TextStyle(color: AppTheme.rougeUrgence),
            ),
          ),
          // Reprendre : rejoindre le cockpit du trek en cours (action primaire).
          FilledButton(
            key: const ValueKey('resume-orphan-resume'),
            onPressed: () =>
                Navigator.of(dialogContext).pop(ResumeOrphanChoice.resume),
            child: Text(t.trekState.resumeOrphanDialog.resume),
          ),
        ],
      );
    },
  );
}
