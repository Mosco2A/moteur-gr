import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/refus_sauvegarde_systeme_provider.dart';

/// LA CASE PRE-COCHEE DE REFUS, PRESENTEE AU MOMENT DE LA CONNEXION (tache 612,
/// decision de Christophe du 28/09 10:49, verbatim : « option prechochee, Je
/// refuse la sauvegarde sur le cloud google de mes donnees medicales, quand il se
/// connecte »).
///
/// LE REFUS EST LE DEFAUT, COCHE D'AVANCE. Le randonneur peut le decocher s'il
/// prefere la commodite : c'est son choix, eclaire, et la protection ne depend pas
/// de sa vigilance. Present AU MOMENT OU IL SE CONNECTE, pas enterre dans les
/// reglages.
///
/// DEUX SUJETS QUE CE DIALOGUE NE CONFOND PAS, ET C'EST SA RAISON D'ETRE.
/// La fiche medicale ne part JAMAIS vers NOS serveurs, case cochee ou non : c'est
/// acquis ailleurs, par construction. Cette case ne concerne QUE la sauvegarde du
/// telephone par son PROPRE systeme, Google ou Apple, qui ne nous appartient pas.
/// Sans cette phrase a l'ecran (`notOurServers`), le randonneur qui decoche
/// croirait que NOUS recuperons sa fiche. Nous ne l'avons jamais, dans aucun cas.
///
/// LE TEXTE SUIT LA PLATEFORME. « cloud Google » sur Android, « iCloud » sur
/// iPhone : une case qui parle de Google sur un iPhone decredibilise tout le
/// reste. La plateforme est lue sur le THEME (`Theme.of(context).platform`) et non
/// sur `dart:io`, pour que les deux formulations soient testables sans emulateur.
class RefusSauvegardeSystemeDialog extends ConsumerStatefulWidget {
  const RefusSauvegardeSystemeDialog({super.key});

  /// Cle de l'interrupteur, pour les tests et l'accessibilite.
  static const Key cleCase = ValueKey('refus-sauvegarde-systeme-case');

  /// Cle du bouton de validation.
  static const Key cleValider = ValueKey('refus-sauvegarde-systeme-valider');

  /// POSE LA QUESTION SI ELLE N'A PAS DEJA ETE TRANCHEE.
  ///
  /// Retourne quand le randonneur a ferme le dialogue. Ne repose pas la question
  /// une fois la decision enregistree : la protection, elle, s'applique des le
  /// depart ([kRefusSauvegardeSystemeParDefaut]) — poser la question et proteger
  /// sont deux choses, et les confondre ferait l'un des deux defauts (redemander
  /// sans cesse, ou ne pas proteger avant d'avoir demande).
  static Future<void> poserSiNecessaire(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final dejaTranche =
        await ref.read(decisionSauvegardeSystemePriseProvider.future);
    if (dejaTranche || !context.mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const RefusSauvegardeSystemeDialog(),
    );
  }

  @override
  ConsumerState<RefusSauvegardeSystemeDialog> createState() =>
      _RefusSauvegardeSystemeDialogState();
}

class _RefusSauvegardeSystemeDialogState
    extends ConsumerState<RefusSauvegardeSystemeDialog> {
  /// PRE-COCHEE. C'est la demande de Christophe, mot pour mot, et c'est aussi
  /// l'etat qui s'applique deja avant l'ouverture de ce dialogue.
  bool _refuse = kRefusSauvegardeSystemeParDefaut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textes = t.health.systemBackup;
    final surIphone = theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final libelle = surIphone ? textes.refuseApple : textes.refuseGoogle;
    final explication =
        surIphone ? textes.explainApple : textes.explainGoogle;

    return AlertDialog(
      title: Text(textes.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(explication, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingMd),
            Semantics(
              checked: _refuse,
              label: textes.a11yCheckbox,
              child: CheckboxListTile(
                key: RefusSauvegardeSystemeDialog.cleCase,
                value: _refuse,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(libelle, style: theme.textTheme.bodyMedium),
                onChanged: (v) => setState(() => _refuse = v ?? true),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // LA PHRASE QUI EMPECHE LE MALENTENDU. Elle n'est pas decorative :
            // sans elle, decocher voudrait dire « StepWays recupere ma fiche »
            // dans la tete du randonneur, et ce serait faux.
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: colors.primary.withAlpha(24),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: colors.primary.withAlpha(70)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 18, color: colors.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      textes.notOurServers,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: colors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          key: RefusSauvegardeSystemeDialog.cleValider,
          isFullWidth: false,
          label: textes.confirm,
          onPressed: () async {
            // ON ENREGISTRE AVANT DE FERMER. Fermer d'abord laisserait la
            // decision en vol : un dialogue barrierDismissible: false qui se
            // referme sans avoir ecrit serait un faux succes de plus.
            await ref
                .read(refusSauvegardeSystemeProvider.notifier)
                .definir(refuse: _refuse);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
