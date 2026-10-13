// GARDE DE PLAFOND — LES DIALOGUES NE S'OUVRENT PLUS HORS DU ROUTEUR
// (tache 645-01).
//
// CE QUE CETTE GARDE MESURE. Les appels `showDialog` et
// `showModalBottomSheet` de `lib/` qui ne passent PAS par le routeur.
//
// ===========================================================================
// LE CRITERE RETENU POUR « PASSE PAR LE ROUTEUR » — ECRIT, PARCE QU'UN PLAFOND
// SANS CRITERE NE VAUT RIEN
// ===========================================================================
//
// Un appel est declare « par le routeur » quand L'UNE des deux conditions
// suivantes est vraie :
//
//   (1) le fichier vit dans `lib/core/routing/` — c'est la couche de
//       navigation elle-meme, elle a le droit d'ouvrir ce qu'elle route ;
//
//   (2) le fichier CITE, dans son CODE (hors commentaires et hors chaines),
//       `contexteDeDialogue` ou `cleNavigateurRacine` — les deux seuls
//       fournisseurs de contexte adosses au routeur, declares dans
//       `lib/core/routing/navigateur_racine.dart`.
//
// POURQUOI CES DEUX NOMS-LA, ET PAS UN CRITERE INVENTE ICI. Ce ne sont pas des
// conventions choisies pour les besoins du test : ce sont les deux symboles que
// le depot a CREES en reponse a un plantage mesure en production. Crashlytics,
// builds 6 et 7, 28 plantages, 9 utilisateurs, ZERO session sans plantage sur
// sept jours : `Null check operator used on a null value` dans `showDialog`,
// parce que `Navigator.of(context)` rendait null — les gardes d'ouverture sont
// posees dans le `builder` de `MaterialApp.router`, donc AU-DESSUS du
// `Navigator` que GoRouter construit. Lisez l'en-tete de
// `lib/core/routing/navigateur_racine.dart` : il raconte le defaut en entier.
// `contexteDeDialogue` est la reponse. L'appeler, c'est obtenir un contexte qui
// porte VRAIMENT un navigateur ; ne pas l'appeler, c'est parier que le contexte
// qu'on a sous la main en porte un.
//
// ---------------------------------------------------------------------------
// CE QUE CE CRITERE NE VOIT PAS, ET DANS QUEL SENS IL SE TROMPE
// ---------------------------------------------------------------------------
//
// La condition (2) est posee au niveau du FICHIER, pas de l'appel. Un fichier
// qui resout correctement UN dialogue par `contexteDeDialogue` voit donc TOUS
// ses dialogues declares conformes. C'est une indulgence, et elle est assumee
// pour une raison precise : decider par appel demanderait de suivre la valeur
// passee en `context:` a travers variables locales, fermetures et fonctions
// appelees — une analyse de flot que ce test, lecture de texte, ne peut pas
// faire honnetement. Mieux vaut un critere LARGE et ECRIT qu'un critere etroit
// et faux.
//
// LE SENS DE L'ERREUR EST LE BON. Le critere ne peut que SOUS-estimer la dette,
// jamais la surestimer : 55 est donc un PLANCHER de ce qui reste a reprendre.
// Et il garde ce qui compte — un dialogue ajoute dans un fichier qui n'avait
// rien du routeur fait monter le compte et rougir la garde. Le trou connu est
// l'ajout d'un dialogue dans l'un des 2 fichiers deja conformes ; c'est le prix
// de l'honnetete de la mesure, et il est ecrit ici pour que personne ne le
// decouvre a ses frais.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 147ca32d, par la methode decrite dans l'en-tete
/// de ce fichier : 57 appels de dialogue dans `lib/`, dont 2 passent par le
/// routeur — il en reste **55** hors routeur.
///
/// Ce chiffre a ete mesure par ce lot (645-01) et n'existe pas dans l'audit
/// 644 : `tool/audit_global.py` compte les 57 appels SANS distinguer ceux qui
/// passent par le routeur.
const plafondDialoguesHorsRouteur = 55;

/// La couche de navigation : elle a le droit d'ouvrir ce qu'elle route.
const coucheDeRoutage = 'lib/core/routing/';

/// Les deux seuls fournisseurs de contexte adosses au routeur.
const fournisseursDeContexteRouteur = <String>[
  'contexteDeDialogue',
  'cleNavigateurRacine',
];

/// Le motif d'un appel de dialogue : `showDialog(`, `showDialog<`,
/// `showModalBottomSheet(` ou `showModalBottomSheet<`.
final motifDialogue = RegExp(
  r'\bshowDialog\s*[(<]|\bshowModalBottomSheet\s*[(<]',
);

/// Vrai si [fichier] resout son contexte par le routeur, au sens du critere
/// ecrit dans l'en-tete de ce fichier.
bool passeParLeRouteur(String fichier, String source) {
  if (fichier.startsWith(coucheDeRoutage)) return true;
  // HORS COMMENTAIRES ET HORS CHAINES : un fichier qui se contente de PARLER
  // de `contexteDeDialogue` dans sa documentation ne l appelle pas. Sans ce
  // filtre, la garde s eteindrait en citant le nom du fournisseur dans un
  // commentaire — et quatre fichiers de lib/ le citent justement en
  // commentaire sans l appeler.
  final mots = identifiants(source).toSet();
  return fournisseursDeContexteRouteur.any(mots.contains);
}

void main() {
  late List<String> horsRouteur;
  late List<String> parLeRouteur;
  late int total;

  setUpAll(() {
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason: 'aucun source dans lib/ : la garde mesurerait le vide',
    );

    horsRouteur = <String>[];
    parLeRouteur = <String>[];
    total = 0;

    for (final f in fichiers) {
      final lignes = lignesDe(f);
      final sites = <String>[];
      for (var i = 0; i < lignes.length; i++) {
        if (motifDialogue.hasMatch(lignes[i])) sites.add('$f:${i + 1}');
      }
      if (sites.isEmpty) continue;
      total += sites.length;
      if (passeParLeRouteur(f, lireSource(f))) {
        parLeRouteur.addAll(sites);
      } else {
        horsRouteur.addAll(sites);
      }
    }
  });

  group('645-01 — pas un dialogue hors routeur de plus', () {
    test('pas plus de dialogues hors routeur qu au 02/10', () {
      expect(
        horsRouteur.length,
        lessThanOrEqualTo(plafondDialoguesHorsRouteur),
        reason:
            'UN DIALOGUE DE PLUS S OUVRE HORS DU ROUTEUR : '
            '${horsRouteur.length} appels, contre '
            '$plafondDialoguesHorsRouteur au 02/10/2026. Ce defaut a DEJA '
            'coute : 28 plantages en production sur les builds 6 et 7, 9 '
            'utilisateurs, zero session sans plantage sur sept jours, parce '
            'que `Navigator.of(context)` rendait null au-dessus du Router.\n'
            'RESOLVEZ VOTRE CONTEXTE PAR `contexteDeDialogue(context)` '
            '(lib/core/routing/navigateur_racine.dart) : il rend un contexte '
            'qui porte VRAIMENT un navigateur, ou null — et null se traite, '
            'contrairement a un `!` dans le framework dont le message ne dit '
            'rien.\n  ${horsRouteur.join('\n  ')}',
      );
    });

    test('la mesure voit bien les deux cotes — sinon le plafond ne mesure '
        'rien', () {
      // UNE GARDE QUI NE TROUVE PLUS D APPEL PASSE AU VERT EN SILENCE. Si le
      // motif cessait d attraper `showDialog`, `horsRouteur` tomberait a zero
      // et cette garde declarerait le depot sain. Et si le critere (2) se
      // mettait a tout accepter, elle ferait de meme. On verifie donc que les
      // DEUX cotes de la balance sont encore peuples.
      expect(
        total,
        greaterThanOrEqualTo(50),
        reason:
            'le depot porte 57 appels de dialogue au 02/10/2026 : un '
            'total bien plus bas signale que le motif ne lit plus rien',
      );
      expect(
        parLeRouteur,
        isNotEmpty,
        reason:
            'PLUS AUCUN appel ne passe par le routeur : soit le critere ne '
            'reconnait plus `contexteDeDialogue`, soit les deux seuls appels '
            'conformes du depot ont ete defaits. Les deux sont graves.',
      );
      expect(
        horsRouteur.length + parLeRouteur.length,
        total,
        reason: 'tout appel trouve doit tomber d un cote ou de l autre',
      );
    });

    test('le critere ecrit est bien celui qui est applique', () {
      // UN CRITERE ECRIT DANS UN COMMENTAIRE ET UN AUTRE DANS LE CODE, C EST
      // PIRE QUE PAS DE CRITERE. Ces verifications attachent l en-tete au
      // comportement reel.
      expect(
        passeParLeRouteur(
          'lib/core/routing/navigateur_racine.dart',
          'rien du tout',
        ),
        isTrue,
        reason: 'critere (1) : la couche de routage est conforme par position',
      );
      expect(
        passeParLeRouteur(
          'lib/features/x/presentation/y.dart',
          'final hote = contexteDeDialogue(context);',
        ),
        isTrue,
        reason: 'critere (2) : citer le fournisseur dans le CODE est conforme',
      );
      expect(
        passeParLeRouteur(
          'lib/features/x/presentation/y.dart',
          '/// voir [contexteDeDialogue], qui explique le defaut.',
        ),
        isFalse,
        reason:
            'EN PARLER N EST PAS L APPELER : un fichier qui cite le '
            'fournisseur en COMMENTAIRE sans l appeler reste hors routeur, '
            'sinon la garde s eteint par la documentation',
      );
      expect(
        passeParLeRouteur(
          'lib/features/x/presentation/y.dart',
          'showDialog(context: context, builder: (c) => const Truc());',
        ),
        isFalse,
        reason: 'un appel qui parie sur le contexte recu reste hors routeur',
      );
      expect(motifDialogue.hasMatch('await showDialog<bool>('), isTrue);
      expect(motifDialogue.hasMatch('showModalBottomSheet('), isTrue);
      expect(
        motifDialogue.hasMatch('maFonctionShowDialogue('),
        isFalse,
        reason: 'la frontiere de mot doit ecarter les noms composes',
      );
    });
  });
}
