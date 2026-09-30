import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/routing/navigateur_racine.dart';
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
  /// ---------------------------------------------------------------------------
  /// TACHE 637 — CETTE METHODE PLANTAIT A TOUS LES LANCEMENTS, SANS QUE CA SE
  /// VOIE
  /// ---------------------------------------------------------------------------
  ///
  /// Crashlytics, builds 6 ET 7 : 28 plantages, 9 utilisateurs, ZERO session sans
  /// plantage sur sept jours. `Null check operator used on a null value`,
  /// premiere frame applicative ici meme — ligne 96 dans la numerotation du
  /// build 6, c'est-a-dire l'appel a `showDialog` lui-meme.
  ///
  /// Le `!` n'etait pas dans ce fichier : `Navigator.of` finit par
  /// `return navigator!` (`navigator.dart:2937`), et il etait atteint parce que
  /// le contexte recu venait d'une garde posee AU-DESSUS du `Navigator`. Tout est
  /// mesure et explique dans [contexteDeDialogue], qui est la reponse : elle rend
  /// un contexte qui porte VRAIMENT un navigateur, ou rien — et « rien » fait
  /// RENONCER au lieu de lever.
  ///
  /// LE VRAI PRIX DU DEFAUT N'ETAIT PAS LE PLANTAGE, C'ETAIT SON SILENCE : la
  /// question n'etait JAMAIS posee. L'exception partait d'un
  /// `addPostFrameCallback`, donc le filet d'erreurs de Flutter l'avalait et
  /// l'application continuait. Le randonneur restait protege (le refus est le
  /// defaut) mais ne pouvait pas choisir la commodite — c'est-a-dire exactement
  /// le trou que la tache 617 etait censee fermer.
  ///
  /// UN SEUL DIALOGUE EN VOL DANS TOUTE L'APPLICATION. Deux appelants existent
  /// (la porte de l'ouverture et l'ecran de profil apres connexion Google) et ils
  /// peuvent se croiser : une connexion Google pendant que la question de
  /// l'ouverture est encore en vol en posait DEUX, et la premiere reponse
  /// invalidait le provider que la seconde attendait encore — c'est le SECOND
  /// rapport Crashlytics, `Cannot use the Ref of FutureProvider<bool> after it
  /// has been disposed`. Le verrou [_enVol] ferme les deux defauts d'un geste.
  static Future<void> poserSiNecessaire(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final enCours = _enVol;
    if (enCours != null) return enCours;
    final futur = _poser(context, ref);
    _enVol = futur;
    try {
      await futur;
    } finally {
      _enVol = null;
    }
  }

  /// Le dialogue en vol, s'il y en a un. Voir [poserSiNecessaire].
  static Future<void>? _enVol;

  /// Relache le verrou entre deux tests — il est statique, donc partage.
  @visibleForTesting
  static void reinitialiserLeVerrou() => _enVol = null;

  /// Le journal des miettes — et il ne peut PAS faire echouer ce qu'il instrumente.
  ///
  /// TACHE 637 (VOLET 2) — CE FILET EXISTE PARCE QUE LE VOLET 1 AVAIT OUVERT LE
  /// MEME TROU QU'IL FERMAIT. `analyticsServiceProvider` construit les puits
  /// Firebase, dont les constructeurs touchent `FirebaseAnalytics.instance` : une
  /// application native injoignable (`[core/no-app]`, services Google Play absents
  /// ou trop vieux) faisait LEVER ce `ref.read`, donc lever `poserSiNecessaire`
  /// depuis un `addPostFrameCallback` — le chemin exact du plantage du volet 1. Le
  /// provider est corrige a la source ; ce filet reste, parce qu'un traceur qui
  /// casse la trace est le genre de defaut qu'on ne veut pas revoir.
  static AnalyticsService _journal(WidgetRef ref) {
    try {
      return ref.read(analyticsServiceProvider);
    } catch (_) {
      return AnalyticsService.disabled();
    }
  }

  static Future<void> _poser(BuildContext context, WidgetRef ref) async {
    final journal = _journal(ref);
    // L'HOTE EST RESOLU AVANT LA MOINDRE ATTENTE, ET C'EST VOULU : aucun
    // `BuildContext` ne traverse ainsi de trou asynchrone. Ce que
    // [contexteDeDialogue] rend est, dans l'application reelle, le contexte du
    // navigateur RACINE — celui qui vit aussi longtemps que l'application. Il est
    // tout de meme re-verifie apres les attentes, plus bas : un contexte valide a
    // l'aller n'est pas un contexte valide au retour.
    final hote = contexteDeDialogue(context);
    await journal.marquerEtape(Etape.sauvegardeDemandee);

    final bool dejaTranche;
    try {
      dejaTranche = await ref.read(
        decisionSauvegardeSystemePriseProvider.future,
      );
    } catch (erreur, pile) {
      // LA LECTURE PEUT ETRE PERDUE, ET RENONCER EST ALORS LE BON CHOIX.
      //
      // Le provider est invalide par [RefusSauvegardeSystemeNotifier.definir]
      // des qu'une decision est prise : une lecture encore en vol a ce
      // moment-la meurt avec lui (`UnmountedRefException` — le second rapport
      // Crashlytics du build 6). Ce type n'est PAS exporte par l'API publique de
      // Riverpod 3.3.2, d'ou une prise large, assumee, et TRACEE : l'erreur
      // remonte en non-fatale, donc elle reste visible ; elle ne plante plus.
      //
      // Renoncer est sans consequence : le refus s'applique deja
      // ([kRefusSauvegardeSystemeParDefaut]) et la question sera reposee au
      // lancement suivant si elle n'a pas ete tranchee.
      await journal.marquerEtape(Etape.sauvegardeLecturePerdue);
      await journal.recordError(erreur, pile);
      return;
    }
    await journal.marquerEtape(Etape.sauvegardeDecisionLue);
    if (dejaTranche) return;

    // AUCUN NAVIGATEUR, OU PLUS DE NAVIGATEUR : ON RENONCE, ON NE LEVE PAS.
    // C'est le cas qui plantait 28 fois. La question revient au lancement
    // suivant, et la protection n'a jamais dependu de cette question.
    if (hote == null) {
      await journal.marquerEtape(Etape.sauvegardeSansNavigateur);
      return;
    }
    if (!hote.mounted || !porteUnNavigateur(hote)) {
      await journal.marquerEtape(Etape.sauvegardeSansNavigateur);
      return;
    }
    // LA MIETTE N'EST PAS ATTENDUE, ET CE N'EST PAS UN OUBLI. Toute attente
    // placee entre la garde `mounted` ci-dessus et l'ouverture ci-dessous
    // ROUVRIRAIT la fenetre que la garde vient de fermer — c'est-a-dire le
    // defaut meme de ce lot. L'analyseur le signale (`use_build_context_
    // synchronously`), et il a raison : rien ne doit s'intercaler ici.
    unawaited(journal.marquerEtape(Etape.sauvegardeDialogueOuvert));
    await showDialog<void>(
      context: hote,
      barrierDismissible: false,
      builder: (_) => const RefusSauvegardeSystemeDialog(),
    );
    await journal.marquerEtape(Etape.sauvegardeDialogueFerme);
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
    final surIphone =
        theme.platform == TargetPlatform.iOS ||
        theme.platform == TargetPlatform.macOS;
    final libelle = surIphone ? textes.refuseApple : textes.refuseGoogle;
    final explication = surIphone ? textes.explainApple : textes.explainGoogle;

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
                  StepIcon(
                    StepwaysIcons.cadenas,
                    size: 18,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      textes.notOurServers,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                      ),
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
            // `maybeOf` ET `mounted`, PAS `of` (tache 637). `definir` traverse
            // trois attentes (disque + les deux copies) : le dialogue peut avoir
            // ete depile entre-temps, et `Navigator.of` sur un contexte retire
            // finit par `return navigator!` — le meme `!` du framework, au meme
            // endroit, que celui qui a coûte deux builds. `mounted` seul ne
            // suffit pas : un element desactive mais pas encore demonte le dit
            // encore vrai.
            if (!context.mounted) return;
            Navigator.maybeOf(context)?.pop();
          },
        ),
      ],
    );
  }
}
