// GARDE DE PLAFOND — VAC-01 : AUCUNE VALEUR A COMPLETER NE PART EN PRODUCTION
// (tache 645-01).
//
// CE QUE CETTE GARDE MESURE. Les marqueurs de valeur non renseignee dans le
// CODE de `lib/` : `example.org`, `example.com`, « a completer », `CHANGEME`,
// `votre-`, `your-`, `localhost`, « lorem ipsum », `dummy`.
//
// POURQUOI C'EST LE PLUS VISIBLE DES DEFAUTS. Une valeur a completer n'echoue
// pas : elle s'affiche. Une adresse `example.org` dans un ecran de contact
// envoie l'utilisateur nulle part sans jamais lever d'exception ; un
// `localhost` dans une URL de service marche chez le developpeur et seulement
// chez lui. Ces 45 marqueurs sont du texte que l'utilisateur peut LIRE.
//
// ---------------------------------------------------------------------------
// LES LIGNES DE COMMENTAIRE NE COMPTENT PAS, ET C'EST INDISPENSABLE
// ---------------------------------------------------------------------------
//
// Une ligne qui commence par `//`, `///` ou `*` est ignoree. Sans ce filtre,
// l'en-tete que vous lisez ferait rougir sa propre garde : il cite `localhost`
// et `example.org` pour les expliquer. Un defaut EXPLIQUE n'est pas un defaut
// LIVRE. L'audit 644 suit les 25 marqueurs en commentaire a part, sous VAC-02,
// et ils ne sont pas bloquants.
//
// ---------------------------------------------------------------------------
// PIEGE DE MESURE : ANCREZ VOS MOTIFS. CELUI-CI A DEJA COUTE
// ---------------------------------------------------------------------------
//
// Deux motifs mal ancres ont failli entrer dans la mesure de depart :
//
//   - `changeme` SANS frontiere de mot et sans egard a la casse attrape le mot
//     FRANCAIS « changeMEnt » — mesure du 02/10/2026 : 93 fausses prises, soit
//     deux fois le total reel. D'ou `\bCHANGE_?ME\b` : frontieres de mot aux
//     DEUX bouts.
//   - `placeholder` attrape le parametre LEGITIME `placeholder:` de Flutter,
//     present dans tout champ de saisie. Il est donc absent de la liste.
//
// Un motif non ancre ne rend pas la garde « plus prudente » : il la rend
// FAUSSE, et un plafond faux ne protege rien. Si vous ajoutez un marqueur,
// ancrez-le et verifiez ce qu'il attrape AVANT de l'inscrire.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 147ca32d : 45 marqueurs dans le code de `lib/`
/// (39 « a completer » + 6 `example.org`), hors lignes de commentaire.
const plafondValeursACompleter = 45;

/// Les marqueurs cherches, TOUS ancres par frontiere de mot.
///
/// Chaque entree est un nom lisible et son motif. Le nom sert au rapport
/// d'echec : « 3 de plus » n'aide personne, « 3 `localhost` de plus » si.
const marqueurs = <String, String>{
  'example.org': r'example\.org',
  'example.com': r'example\.com',
  'a completer': r'[AÀ]\s*COMPL[EÉ]TER|a\s+completer',
  'CHANGEME': r'\bCHANGE_?ME\b',
  'votre- / your-': r'\bvotre-|\byour-',
  'localhost': r'\blocalhost\b',
  'lorem ipsum': r'[Ll]orem\s+ipsum',
  'dummy': r'\bdummy\b',
};

void main() {
  late List<String> dansLeCode;

  setUpAll(() {
    final fichiers = sourcesLib();
    expect(
      fichiers,
      isNotEmpty,
      reason: 'aucun source dans lib/ : la garde mesurerait le vide',
    );

    final compiles = marqueurs.entries
        .map((e) => MapEntry(e.key, RegExp(e.value)))
        .toList();

    dansLeCode = <String>[];
    for (final f in fichiers) {
      final lignes = lignesDe(f);
      for (var i = 0; i < lignes.length; i++) {
        final ligne = lignes[i];
        // UN DEFAUT EXPLIQUE N EST PAS UN DEFAUT LIVRE : sans ce filtre,
        // l en-tete de cette garde la ferait rougir.
        if (estLigneDeCommentaire(ligne)) continue;
        for (final m in compiles) {
          if (m.value.hasMatch(ligne)) {
            // UN SEUL compte par ligne, comme l audit 644 : une ligne qui
            // porte deux marqueurs reste UNE valeur a renseigner.
            dansLeCode.add('$f:${i + 1}: ${m.key} | ${ligne.trim()}');
            break;
          }
        }
      }
    }
  });

  group('645-01 / VAC-01 — pas une valeur a completer de plus', () {
    test('pas plus de valeurs a completer dans le code qu au 02/10', () {
      expect(
        dansLeCode.length,
        lessThanOrEqualTo(plafondValeursACompleter),
        reason:
            'UNE VALEUR A COMPLETER DE PLUS PART EN PRODUCTION : '
            '${dansLeCode.length} marqueurs dans le code de lib/, contre '
            '$plafondValeursACompleter au 02/10/2026. Ce defaut n echoue pas, '
            'il S AFFICHE : une adresse `example.org` envoie l utilisateur '
            'nulle part sans jamais lever d exception, et un `localhost` '
            'marche chez vous et seulement chez vous.\n'
            'RENSEIGNEZ LA VALEUR, ou retirez l ecran qui l affiche. La '
            'troisieme voie — masquer — est une decision produit de '
            'Christophe (lot 645-08), pas un choix de code.\n'
            '  ${dansLeCode.join('\n  ')}',
      );
    });

    test('les motifs sont ancres — un motif large rend le plafond faux', () {
      // CE TEST GARDE LA MESURE ELLE-MEME. Les deux pieges ci-dessous ont
      // reellement failli entrer dans la mesure de depart, et chacun aurait
      // rendu le plafond incomparable a la realite.
      final changeme = RegExp(marqueurs['CHANGEME']!);
      expect(
        changeme.hasMatch('final changement = 1;'),
        isFalse,
        reason:
            'LE PIEGE MESURE : un motif `changeme` non ancre attrape le '
            'mot francais « changeMEnt » — 93 fausses prises au 02/10/2026, '
            'deux fois le total reel de la mesure',
      );
      expect(
        changeme.hasMatch('const cle = CHANGEME;'),
        isTrue,
        reason: 'le vrai marqueur doit rester attrape',
      );
      expect(
        changeme.hasMatch('const cle = CHANGE_ME;'),
        isTrue,
        reason: 'la variante soulignee doit rester attrapee',
      );

      expect(
        marqueurs.containsKey('placeholder'),
        isFalse,
        reason:
            'LE SECOND PIEGE : `placeholder` attrape le parametre '
            'LEGITIME `placeholder:` de Flutter, present dans tout champ de '
            'saisie. Il ne doit pas entrer dans cette liste.',
      );

      final localhost = RegExp(marqueurs['localhost']!);
      expect(
        localhost.hasMatch("const url = 'http://localhost:8080';"),
        isTrue,
      );
      expect(
        localhost.hasMatch('const nom = monlocalhostprive;'),
        isFalse,
        reason: 'les frontieres de mot doivent tenir aux deux bouts',
      );
    });

    test('les lignes de commentaire sont bien ecartees', () {
      // Sans ce filtre, l en-tete de CE fichier ferait rougir CETTE garde :
      // il cite `localhost` et `example.org` pour les expliquer.
      expect(estLigneDeCommentaire('// localhost'), isTrue);
      expect(estLigneDeCommentaire('   /// example.org'), isTrue);
      expect(estLigneDeCommentaire(' * a completer'), isTrue);
      expect(
        estLigneDeCommentaire("const url = 'http://localhost';"),
        isFalse,
        reason: 'une ligne de CODE doit rester comptee',
      );
      // Et la preuve par le depot : ce fichier-ci cite les marqueurs en
      // commentaire et ne doit apparaitre dans aucune prise.
      expect(
        dansLeCode.where((e) => e.contains('aucune_valeur_a_completer')),
        isEmpty,
        reason: 'la garde ne doit pas se compter elle-meme',
      );
    });
  });
}
