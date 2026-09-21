import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';
import '../services/location_permission_service.dart';

/// PRE-VOL EXPLIQUE du suivi de fond (campagne personas 21/09, MAJEUR-1).
///
/// CE QUI S'EST PASSE : au tout premier « Démarrer la randonnée », l'ecran
/// systeme « Toujours autoriser en arrière-plan ? » surgissait PAR-DESSUS la
/// carte, sans un mot d'explication, lance depuis DEUX endroits a la fois. Dans
/// un run l'application est restee sept minutes derriere cet ecran systeme,
/// debloquee seulement par un retour manuel.
///
/// LA REGLE ICI, dans l'ordre :
///   1. on n'ouvre RIEN si l'utilisateur a deja tout accorde, ou s'il a deja
///      decline l'explication ([LocationPermissionService.shouldAskBackgroundRationale]) ;
///   2. on EXPLIQUE d'abord, dans l'application et dans sa langue, a quoi sert
///      la permission et ce qui se passe s'il refuse ;
///   3. seulement s'il accepte, on laisse Android poser SA question — et on
///      l'attend, AVANT d'ouvrir la carte, pour qu'aucun ecran systeme ne
///      recouvre la rando ;
///   4. quelle que soit la reponse — « Plus tard », refus systeme, erreur — la
///      fonction rend la main et la rando demarre. Le suivi premier plan
///      fonctionne sans la permission de fond : jamais d'ecran mort.
///
/// Ne jette jamais. Ne bloque jamais le demarrage.
Future<void> ensureBackgroundTrackingExplained(
  BuildContext context,
  WidgetRef ref,
) async {
  final service = ref.read(locationPermissionServiceProvider);

  if (!await service.shouldAskBackgroundRationale()) return;
  if (!context.mounted) return;

  final accepted = await _showRationaleDialog(context);

  if (accepted != true) {
    // « Plus tard » ou fermeture : on note le refus et on part en premier plan.
    await service.rememberBackgroundRationaleDeclined();
    return;
  }

  // Accepte : Android peut poser sa question, on l'attend ici et pas sur la
  // carte. Le statut ne conditionne RIEN — le trek demarre dans tous les cas.
  await service.ensureBackgroundTracking();
}

/// Feuille d'explication « pourquoi le suivi en arrière-plan ».
///
/// Renvoie true si l'utilisateur accepte de voir la demande systeme, false ou
/// null sinon (« Plus tard », barriere, retour systeme = le choix le plus sur).
Future<bool?> _showRationaleDialog(BuildContext context) {
  final tr = Translations.of(context).tracking.backgroundRationale;
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      key: const ValueKey('background-tracking-rationale-dialog'),
      icon: const Icon(Icons.my_location),
      title: Text(tr.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr.body),
          const SizedBox(height: AppTheme.spacingSm),
          // Ce que ca coute de dire non : dit AVANT, pas apres.
          Text(
            tr.ifRefused,
            style: Theme.of(dialogContext).textTheme.bodySmall,
          ),
        ],
      ),
      actionsOverflowButtonSpacing: AppTheme.spacingSm,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(tr.later),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(tr.allow),
        ),
      ],
    ),
  );
}
