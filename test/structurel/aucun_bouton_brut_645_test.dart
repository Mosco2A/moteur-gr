// GARDE DE PLAFOND — ECR-19 : UN SEUL COMPOSANT BOUTON (tache 645-01).
//
// CE QUE CETTE GARDE MESURE. Les appels aux quatre boutons du framework —
// `ElevatedButton`, `TextButton`, `OutlinedButton`, `FilledButton` — partout
// dans `lib/` SAUF dans les deux zones ou ils sont legitimes.
//
// POURQUOI UN COMPOSANT UNIQUE. Un bouton brut porte sa propre apparence et
// son propre comportement : taille de cible tactile, etat de chargement,
// desactivation, retour haptique, contraste. Multiplie par 153 appels, cela
// fait 153 decisions prises separement — donc une interface qui ne se tient
// pas, et une correction d accessibilite qui doit etre faite 153 fois. Le
// composant unique `AppButton` est l endroit ou cette decision se prend UNE
// fois.
//
// LES DEUX ZONES LEGITIMES, ET POURQUOI ELLES LE SONT :
//
//   - `lib/shared/widgets/app_button.dart` : c'est LE composant unique. Il est
//     bati sur les boutons du framework — c'est son travail.
//   - `lib/core/theme/` : un theme DOIT citer `ElevatedButtonThemeData` et
//     `ElevatedButton.styleFrom`, c'est la seule facon de dire a quoi
//     ressemble un bouton. Verifie le 02/10/2026 dans `app_theme.dart`,
//     lignes 265 a 287 et 407.
//
// PERIMETRE STRICT, ET IL EST VOULU. `IconButton` et `CupertinoButton` sont
// hors mesure : l'audit 644 en compte 50 de plus, suivis a part sous ECR-19e.
// Les melanger ici rendrait ce plafond incomparable a la mesure de depart.
//
// UN APPEL, PAS UNE MENTION (correction du 02/10/2026, tache 645-03). Cette
// garde comptait aussi les noms de boutons ECRITS DANS LES COMMENTAIRES. Au
// 02/10, sur les 153 lignes qu'elle relevait, 31 etaient des phrases comme
// « SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary » : la trace, dans
// le code, d'une conversion DEJA FAITE. La garde reprochait au depot d'avoir
// documente son propre assainissement, et exigeait, pour atteindre zero, qu'on
// efface cette tracabilite.
//
// `estLigneDeCommentaire` existait pourtant depuis 645-01, dans
// `mesure_des_sources_645.dart`, avec sa consigne ecrite : « les gardes qui
// cherchent des motifs dans le code doivent l'appeler ». La garde des valeurs
// a completer l'appelle. Celle-ci l'avait oubliee. Elle l'appelle desormais.
//
// CE QUE CELA CHANGE POUR LE PLAFOND. Le nombre descend de 31 d'un coup sans
// qu'une ligne de code ait bouge : ce sont 31 faux positifs qui sortent, pas
// 31 boutons. Le plafond ne mesure plus la meme chose qu'au 02/10 au matin —
// il mesure ce que son titre annonce : des APPELS. Les deux mesures sont
// consignees sur le plafond pour que la comparaison reste possible.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// LE PLAFOND, ET LES DEUX MESURES QUI L'ENCADRENT.
///
///   - 02/10/2026, tete 147ca32d : 153 LIGNES relevees hors des deux zones
///     legitimes — dont 31 simples mentions en commentaire. 122 appels reels.
///   - 02/10/2026, fin du lot 645-03 : 10 appels reels. Les 112 autres passent
///     par `AppButton`.
///
/// LES 10 QUI RESTENT NE SONT PAS UN OUBLI, ils sont en arbitrage (regle R3 du
/// lot : ce qui n'est pas exprimable en parametre ne se force pas). Six
/// fichiers, tous des affordances en ligne volontairement PLUS PETITES que la
/// cible tactile de 44px qu'`AppButton` garantit (`minimumSize: Size.zero`,
/// `tapTargetSize: shrinkWrap`), ou dont le libelle redefinit toute sa
/// typographie via `textTheme.X.copyWith(...)` :
///
///   - lib/shared/widgets/section_header.dart (le « Tout voir » d'en-tete)
///   - lib/shared/widgets/lien_vers_les_cartes.dart
///   - lib/features/weather/presentation/fire_risk_screen.dart
///   - lib/features/checklist/widgets/checklist_category_section.dart
///   - lib/features/onboarding/presentation/onboarding_screen.dart
///   - lib/features/trek/presentation/stages/trek_stage_detail_screen.dart
///
/// Les ramener demanderait soit de grossir leur cible tactile (donc de changer
/// l'apparence, ce que le lot n'a pas le droit de faire), soit d'ouvrir dans
/// `AppButton` un passe-droit typographique. Christophe tranche.
///
/// Le plafond ne remonte JAMAIS.
const plafondBoutonsBruts = 10;

/// Les quatre boutons nommes par ECR-19.
const boutonsStricts = <String>[
  'ElevatedButton',
  'TextButton',
  'OutlinedButton',
  'FilledButton',
];

/// Les deux zones ou citer un bouton du framework est le travail du fichier.
const zonesLegitimes = <String>[
  'lib/shared/widgets/app_button.dart',
  'lib/core/theme/',
];

/// Vrai si [fichier] a le droit de citer les boutons du framework.
bool estZoneLegitime(String fichier) =>
    zonesLegitimes.any((z) => fichier == z || fichier.startsWith(z));

/// Le motif qui attrape un APPEL de [bouton] : `Bouton(`, `Bouton (`,
/// `Bouton.icon` ou `Bouton.styleFrom`.
///
/// La frontiere de mot en tete est ce qui evite d'attraper
/// `MonElevatedButton(` ou `ElevatedButtonThemeData`.
RegExp motifBouton(String bouton) =>
    RegExp('\\b$bouton\\s*\\(|\\b$bouton\\.(?:icon|styleFrom)');

void main() {
  late List<String> trouves;

  setUpAll(() {
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason: 'aucun source dans lib/ : la garde mesurerait le vide',
    );

    final motifs = {for (final b in boutonsStricts) b: motifBouton(b)};
    trouves = <String>[];
    for (final f in fichiers) {
      if (estZoneLegitime(f)) continue;
      final lignes = lignesDe(f);
      for (var i = 0; i < lignes.length; i++) {
        // UN NOM DANS UN COMMENTAIRE N'APPELLE RIEN, IL EN PARLE. Voir
        // l'en-tete : sans ce filtre, la garde compte la documentation de ses
        // propres conversions et exige qu'on l'efface pour atteindre zero.
        if (estLigneDeCommentaire(lignes[i])) continue;
        for (final b in boutonsStricts) {
          if (motifs[b]!.hasMatch(lignes[i])) {
            trouves.add('$f:${i + 1}: $b');
          }
        }
      }
    }
  });

  group('645-01 / ECR-19 — pas un bouton brut de plus', () {
    test('ECR-19 : pas plus de boutons bruts qu au 02/10', () {
      expect(
        trouves.length,
        lessThanOrEqualTo(plafondBoutonsBruts),
        reason:
            'LES BOUTONS BRUTS AUGMENTENT : ${trouves.length} appels hors des '
            'deux zones legitimes, contre $plafondBoutonsBruts au 02/10/2026. '
            'UTILISEZ `AppButton` (lib/shared/widgets/app_button.dart). Un '
            'bouton brut porte sa propre taille de cible, son propre etat de '
            'chargement et son propre contraste : chaque appel est une '
            'decision d interface prise a part, et une correction d '
            'accessibilite a refaire une fois de plus.\n'
            'SI `AppButton` NE SAIT PAS FAIRE CE QU IL VOUS FAUT, c est '
            '`AppButton` qu il faut etendre — la, une fois, pour tout le '
            'monde.\n  ${trouves.join('\n  ')}',
      );
    });

    test('les deux zones legitimes citent bien les boutons du framework — '
        'sinon leur exemption ne protege plus rien', () {
      // UNE EXEMPTION QUI NE COUVRE PLUS RIEN DOIT TOMBER. Si `app_button.dart`
      // ou le theme cessaient de citer ces boutons — fichier renomme,
      // composant reecrit — l exemption resterait en place et couvrirait en
      // silence le PROCHAIN fichier qui prendrait ce chemin. C est le defaut
      // exact du `registre_des_dormants` avant la tache 580 : une exception
      // pour quelque chose qui n existe plus.
      final composant = sourcesLib()
          .where((f) => f == 'lib/shared/widgets/app_button.dart')
          .toList();
      expect(
        composant,
        hasLength(1),
        reason:
            'le composant unique a disparu de '
            'lib/shared/widgets/app_button.dart : l exemption la plus large '
            'de cette garde ne designe plus rien',
      );
      expect(
        motifBouton('ElevatedButton').hasMatch(lireSource(composant.single)),
        isTrue,
        reason:
            'le composant unique ne batit plus sur les boutons du '
            'framework : son exemption n a plus de raison d etre',
      );

      final theme = sourcesLib()
          .where((f) => f.startsWith('lib/core/theme/'))
          .where((f) => motifBouton('ElevatedButton').hasMatch(lireSource(f)))
          .toList();
      expect(
        theme,
        isNotEmpty,
        reason:
            'plus aucun fichier de lib/core/theme/ ne cite '
            'ElevatedButton : l exemption du theme ne protege plus rien et '
            'doit etre retiree de `zonesLegitimes`',
      );
    });

    test('le motif n attrape ni les derives ni les noms composes', () {
      // Un motif trop large gonflerait le compte avec des faux positifs et
      // rendrait le plafond incomparable a la mesure de depart ; un motif trop
      // etroit laisserait passer de vrais boutons. Les deux cassent la garde.
      final m = motifBouton('ElevatedButton');
      expect(m.hasMatch('const ElevatedButton('), isTrue);
      expect(m.hasMatch('ElevatedButton ('), isTrue);
      expect(m.hasMatch('ElevatedButton.icon('), isTrue);
      expect(m.hasMatch('ElevatedButton.styleFrom('), isTrue);
      expect(
        m.hasMatch('MonElevatedButton('),
        isFalse,
        reason: 'la frontiere de mot en tete doit ecarter les noms composes',
      );
      expect(
        m.hasMatch('ElevatedButtonThemeData('),
        isFalse,
        reason: 'le type de theme n est pas un appel de bouton',
      );
    });

    test('une mention en commentaire n est pas un appel', () {
      // LE FAUX POSITIF QUI COUTAIT 31 LIGNES (correction du 02/10/2026). Le
      // motif, lui, DOIT continuer d attraper ces lignes — c est le filtre de
      // commentaire, et lui seul, qui les ecarte. Les deux attentes ensemble
      // disent ou vit la decision.
      final m = motifBouton('ElevatedButton');
      const mention =
          '// SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary';
      expect(
        m.hasMatch(mention),
        isTrue,
        reason: 'le motif ne regarde pas si la ligne est du code',
      );
      expect(
        estLigneDeCommentaire(mention),
        isTrue,
        reason:
            'c est ce filtre qui fait la difference entre un appel et une '
            'phrase qui en parle',
      );
      expect(estLigneDeCommentaire('  /// un ElevatedButton('), isTrue);
      expect(estLigneDeCommentaire(' * un ElevatedButton('), isTrue);
      expect(
        estLigneDeCommentaire('    child: ElevatedButton('),
        isFalse,
        reason: 'une ligne de code reste une ligne de code',
      );
    });
  });
}
