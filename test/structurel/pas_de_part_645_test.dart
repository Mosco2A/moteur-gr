// GARDE A ZERO — REGLE 12 : PAS DE `part` HORS CODE GENERE (lot 645-06b).
//
// CE QUE CETTE GARDE MESURE. Dans `lib/`, `test/`, `tool/` et
// `integration_test/` :
//
//   (a) les fichiers ecrits a la main (hors `.g.dart`, `.freezed.dart`...)
//       qui portent une directive `part of` ;
//   (b) les directives `part '...'` qui visent un fichier ecrit a la main —
//       une racine qui ramasse des morceaux, meme si le morceau a disparu.
//
// POURQUOI ZERO ET PAS UN PLAFOND. Decision de Christophe du 03/10/2026,
// verbatim : « Moi je veux que se soit propre et aux normes ». Le lot 645-06
// (vague 2) avait scinde les cinq plus gros fichiers en 29 morceaux `part`
// d'UNE SEULE bibliotheque : des morceaux sans imports, dont les membres
// prives se voyaient entre eux. La convention a ete REFUSEE, et le lot
// 645-06b l'a remplacee par de vraies bibliotheques, chacune avec ses imports.
// Il n'y a plus aucun `part` ecrit a la main dans le depot : il n'y a donc
// aucune raison d'en tolerer un.
//
// CE QUE `part` RESTE AUTORISE A FAIRE : relier un fichier a son code GENERE
// (`part 'x.g.dart';`, `part 'x.freezed.dart';`). C'est la forme qu'imposent
// json_serializable, freezed et drift, et elle n'est pas un choix de
// rangement.
//
// POURQUOI L'UNITE COMPTE. Une bibliotheque a `part` se lit a plusieurs
// fichiers : toute garde qui mesure du texte source doit alors lire la racine
// ET ses morceaux, sinon elle ne lit plus que des imports — et une garde
// NEGATIVE passe au vert en silence. C'est arrive en vague 2 (la garde du
// laius des tirets de la carte, `cadrage_et_forme_558_test.dart`). Interdire
// les `part` ecrits a la main, c'est garder vraie l'equation « un fichier =
// une bibliotheque » sur laquelle reposent toutes les autres gardes.
library;

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Les dossiers du depot ou du Dart est ecrit a la main.
const dossiersMesures = <String>['lib', 'test', 'tool', 'integration_test'];

final _partOf = RegExp(r'^part\s+of\b', multiLine: true);
final _part = RegExp(r"^part\s+'([^']+)'\s*;", multiLine: true);

/// Les infractions a la regle 12 dans [chemin], dont le texte est [source].
List<String> infractionsDe(String chemin, String source) {
  final trouvees = <String>[];
  if (_partOf.hasMatch(source)) trouvees.add('$chemin : part of');
  for (final m in _part.allMatches(source)) {
    final cible = m.group(1)!;
    if (!estGenere(cible)) trouvees.add('$chemin : part \'$cible\'');
  }
  return trouvees;
}

void main() {
  group('645-06b / regle 12 — pas de part hors code genere', () {
    test('aucun `part` ni `part of` ecrit a la main dans le depot', () {
      final infractions = <String>[
        for (final dossier in dossiersMesures)
          for (final f in listerDart(dossier))
            ...infractionsDe(f, lireSource(f)),
      ];
      expect(
        infractions,
        isEmpty,
        reason:
            'REGLE 12 (docs/conventions.md, decision de Christophe du '
            '03/10/2026) : une bibliotheque = un fichier avec ses imports. '
            '`part` et `part of` sont reserves au code genere (.g.dart, '
            '.freezed.dart). Un morceau a besoin d un symbole prive d un '
            'autre fichier ? Le symbole devient public dans un fichier de la '
            'feature (la facade, elle, ne le re-exporte pas), et un widget '
            'prive devient une classe nommee a parametres nommes.\n'
            '  ${infractions.join('\n  ')}',
      );
    });

    test('la mesure voit bien ce qu elle interdit — sinon zero ne prouve '
        'rien', () {
      expect(
        infractionsDe('a.dart', "part of 'racine.dart';\n"),
        hasLength(1),
        reason: 'un morceau `part of` ecrit a la main doit etre vu',
      );
      expect(
        infractionsDe('racine.dart', "library;\n\npart 'morceau.dart';\n"),
        hasLength(1),
        reason: 'une racine qui ramasse un morceau ecrit a la main aussi',
      );
      expect(
        infractionsDe(
          'modele.dart',
          "part 'modele.freezed.dart';\npart 'modele.g.dart';\n",
        ),
        isEmpty,
        reason: 'le lien vers le code GENERE reste autorise',
      );
      expect(
        infractionsDe('x.dart', "// part of 'commentaire.dart';\n"),
        isEmpty,
        reason: 'un commentaire n est pas une directive',
      );
    });
  });
}
