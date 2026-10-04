/// Les deux questions que pose la fiche medicale : confirmer son effacement,
/// et redemander le consentement apres une modification.
///
/// Bibliotheque de l'ecran `health_info_screen.dart` (lot 645-06b) : ces deux
/// dialogues etaient des methodes de l'etat de l'ecran. Ils ne lisent rien de
/// cet etat : ils recoivent le contexte (et `ref`) en parametre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../consent/consent_facade.dart' show consentControllerProvider;

/// Demande la confirmation de l'effacement de la fiche : `true` pour effacer.
Future<bool?> confirmHealthInfoDeletion(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.health.delete.confirmTitle),
      content: Text(t.health.delete.confirmBody),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          label: t.health.delete.cancel,
          isFullWidth: false,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        // Action DEFINITIVE : bouton rouge (couleur semantique d'urgence).
        AppButton(
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.emergencyRed,
          isFullWidth: false,
          label: t.health.delete.confirm,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
}

/// LA FICHE A CHANGE, DONC ON REPOSE LA QUESTION (DEM du 30/09 12:33).
///
/// DECISION DE CHRISTOPHE, verbatim : « en cas de modification des donnees, on
/// redemande le consentement ». Un consentement donne il y a six mois porte sur
/// ce qu'il y avait dans la fiche il y a six mois ; le randonneur qui ajoute
/// aujourd'hui un traitement ou une allergie n'a jamais consenti POUR CELA.
///
/// UNE FOIS PAR MODIFICATION, JAMAIS AU SIMPLE AFFICHAGE, et c'est structurel
/// et non une precaution : la question ne se pose que depuis cette fonction,
/// appelee par l'enregistrement de la fiche, donc uniquement quand une
/// ECRITURE a eu lieu. Ouvrir la fiche, la relire, en sortir : rien n'est
/// ecrit, rien n'est demande. Et la decision prise ici CAPTURE la nouvelle
/// revision des donnees, donc `needsPrompt` retombe a faux tout de suite —
/// sans quoi l'application reposerait la question a chaque enregistrement
/// suivant.
///
/// ON PASSE PAR LE CONTROLEUR, PAS PAR LE SERVICE, et c'est deliberé : c'est
/// lui qui sait CE QUE LE RETRAIT DE CETTE FINALITE EMPORTE de l'appareil
/// (tache 560). Appeler `ConsentService.revoke` en direct d'ici donnerait une
/// seconde definition de « ce que ce consentement protege », et c'est
/// exactement l'ecart que la tache 564 a paye.
///
/// ELLE NE LEVE JAMAIS. Un stockage de consentement illisible ne doit pas faire
/// echouer l'enregistrement d'une fiche medicale — la fiche est deja ecrite a ce
/// stade, et c'est elle qui compte pour un secouriste.
Future<void> askHealthConsentAgainAfterChange(
  BuildContext context,
  WidgetRef ref,
) async {
  final service = ref.read(consentServiceProvider);
  try {
    await service.initialize();
    await service.noterUneModificationDesDonnees(ConsentPurpose.healthData);
    if (!service.needsPrompt(ConsentPurpose.healthData)) return;
  } on Object catch (e) {
    debugPrint('[FicheSante] consentement illisible ($e) — pas de re-demande');
    return;
  }

  if (!context.mounted) return;
  // PAS DE FERMETURE PAR L'EXTERIEUR : une question de consentement se repond,
  // et les deux reponses sont aussi accessibles l'une que l'autre (RGPD art.
  // 7-3 : le retrait doit etre aussi simple que l'octroi).
  final accorde = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(t.consent.purposes.healthData),
      content: Text(t.health.consent.purpose),
      actions: [
        AppButton(
          variant: AppButtonVariant.text,
          label: t.consent.revoke,
          isFullWidth: false,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppButton(
          variant: AppButtonVariant.filledTone,
          isFullWidth: false,
          label: t.consent.grant,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  if (accorde == null) return;

  final controleur = ref.read(consentControllerProvider);
  if (accorde) {
    await controleur.grant(
      ConsentPurpose.healthData,
      declencheur: ConsentTrigger.modificationDesDonnees,
    );
  } else {
    await controleur.revoke(
      ConsentPurpose.healthData,
      declencheur: ConsentTrigger.modificationDesDonnees,
    );
  }
}
