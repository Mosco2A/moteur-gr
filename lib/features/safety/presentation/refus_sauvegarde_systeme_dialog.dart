import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/refus_sauvegarde_systeme_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// LA CASE PRE-COCHEE DE REFUS — UNE SEULE, POUR TOUT CE QUE LE RANDONNEUR
/// CONFIE (tache 612 pour le montage, tache 617 pour la portee).
///
/// REGLE GENERALE DE CHRISTOPHE, 28/09 14:31, verbatim : « on ne partage aucune
/// donnee confiee sauf si le client decoche volontairement ». Elle repondait a
/// une question sur le poids et la taille, et elle vaut pour tout : profil, age,
/// taille, poids, randonnees passees, progression, journal, photos, solde, fiche
/// medicale.
///
/// ---------------------------------------------------------------------------
/// UNE SEULE CASE, ET CE N'EST PAS DE LA PARESSE D'ECRAN
/// ---------------------------------------------------------------------------
///
/// Une case par famille de donnees ferait un formulaire de consentement, et un
/// formulaire de consentement est exactement ce que Christophe reproche aux
/// conditions generales (decision du 28/09 10:19 : un resume court, parce que
/// « ils ne lisent jamais les conditions generales »). Sept cases produiraient
/// sept clics reflexes et zero decision. Une seule case, pre-cochee, qui dit tout
/// et dit ce qu'elle coûte, produit une decision.
///
/// LE COROLLAIRE EST ASSUME : le randonneur ne peut pas accepter la sauvegarde de
/// sa progression en refusant celle de sa fiche medicale. Ce n'est pas un oubli,
/// c'est le prix de la simplicite — et il est faible, parce que la fiche medicale
/// est protegee PAR AILLEURS et de deux facons qui ne dependent pas de cette
/// case : elle ne va JAMAIS vers nos serveurs, et elle est explicitement exclue
/// de la sauvegarde systeme en plus de l'etre par defaut
/// ([SauvegardeSysteme.exclusions]). Decocher fait apparaitre une copie ; la
/// fiche elle-meme ne bouge pas.
///
/// ---------------------------------------------------------------------------
/// PRESENTEE A L'OUVERTURE, PLUS SEULEMENT A LA CONNEXION GOOGLE
/// ---------------------------------------------------------------------------
///
/// La tache 612 la posait APRES la connexion Google, et son auteur avait nomme le
/// trou : « le randonneur anonyme ne la voit jamais, il est protege par le defaut
/// mais il ne peut pas choisir la commodite ». Ce trou est ferme
/// ([PorteConsentementSauvegarde], dans l'arbre de `main.dart`) : la question est
/// posee UNE FOIS a l'ouverture, a tout le monde. L'appel de l'ecran de profil
/// reste, et il ne fait pas doublon : une fois la decision prise, elle ne se
/// repose pas.
///
/// ---------------------------------------------------------------------------
/// LE TEXTE DIT CE QUE LA CASE COUTE, SANS ENJOLIVER
/// ---------------------------------------------------------------------------
///
/// Trois blocs, et aucun n'est decoratif :
///  * `explain` NOMME les familles. « Mes donnees » ne veut rien dire ; « ton
///    profil, ton age, ta taille, ton poids, tes randonnees passees, ta
///    progression, ton journal, tes photos, ta fiche medicale » veut dire
///    quelque chose.
///  * `cost` dit la perte : cochee, un changement de telephone repart de zero. Le
///    modele economique promet qu'un trek realise garde sa trace et son carnet A
///    VIE ; ce n'est pas une contradiction (a vie veut dire que l'application ne
///    les efface pas) mais le randonneur le comprendrait autrement, donc le texte
///    le dit lui-meme : sur CE telephone, a vie ; sur un autre, non.
///  * `whatComesBack` dit ce que decocher rend vraiment, ET ce qu'il ne rend pas
///    (les photos et les reglages). Promettre les photos serait faux : les
///    copier doublerait la place prise sur le telephone.
///  * `notOurServers` empeche le malentendu qui annulerait tout le reste.
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
    final textes = t.systemBackup;
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
            // LA CASE EST HAUT, ET LE PRIX EST JUSTE DESSOUS. C'EST UNE
            // CORRECTION MESUREE, PAS UN GOUT DE MISE EN PAGE.
            //
            // Deux versions de ce lot ont ete MESUREES sur trois tailles de
            // telephone (iPhone SE 375x667, petit Android 360x640, Pixel 5
            // 393x851), dans un VRAI dialogue :
            //  * prix et retour AVANT la case, au nom de la decision eclairee :
            //    la case tombait a plus de deux ecrans sous le pli et un appui a
            //    l'endroit ou le randonneur la cherche NE CHANGEAIT RIEN ;
            //  * prix en sous-titre de la case : la ligne devenait haute de 644
            //    pixels, son centre restait hors ecran, et l'appui ne changeait
            //    toujours rien.
            //
            // La tache 612 avait nomme comme trou le fait que « le randonneur ne
            // peut pas choisir la commodite ». Une case hors d'atteinte le
            // rouvre, et une case qu'on ne peut pas cocher n'est pas un choix.
            //
            // LE PRIX N'EST PAS RELEGUE POUR AUTANT : il est la ligne SUIVANTE.
            // Et l'ordre se defend tout seul, parce que la case est PRE-COCHEE :
            // celui qui ne lit rien reste protege, et celui qui envisage de la
            // decocher lit juste en dessous ce que cela lui rend et ce que cela
            // lui coûte.
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
            Text(textes.cost, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingSm),
            // CE QUE DECOCHER REND VRAIMENT, ET CE QU'IL NE REND PAS.
            Text(textes.whatComesBack, style: theme.textTheme.bodySmall),
            const SizedBox(height: AppTheme.spacingMd),
            // LA PHRASE QUI EMPECHE LE MALENTENDU. Elle n'est pas decorative :
            // sans elle, decocher voudrait dire « StepWays recupere mon journal »
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
                  StepIcon(StepwaysIcons.cadenas, size: 18, color: colors.primary),
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
