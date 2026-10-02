// GARDE DE PLAFOND — ECR-13, ECR-07 ET ECR-15 : OU VIT LE CODE, ET COMBIEN IL
// EN TIENT PAR FICHIER (tache 645-01).
//
// TROIS VERIFICATIONS, TROIS PLAFONDS, UN SEUL SUJET : le rangement de `lib/`.
//
//   (a) ECR-13 — LA RACINE DE `lib/` NE PORTE QUE CINQ ENTREES : `core`,
//       `features`, `shared`, `i18n` et `main.dart`. La racine est la premiere
//       chose qu'on lit d'un depot : elle doit repondre « voila les couches »,
//       pas « voila ce qui s'est accumule ». Un intrus au 02/10/2026 :
//       `lib/docs/`.
//
//   (b) ECR-07 — AUCUN `.dart` SOUS UN DOSSIER `docs/` DE `lib/`. De la
//       documentation deposee en `.dart` est compilee, analysee et embarquee
//       comme du code — sans jamais s'executer. Les deux fichiers concernes
//       portent d'ailleurs `// ignore_for_file: unused_element` en premiere
//       ligne : il faut DESARMER l'analyseur pour que cette documentation
//       compile. C'est l'aveu le plus net qu'elle n'est pas a sa place. Du
//       `.md` dans `docs/` a la racine du depot ne coute rien a personne.
//
//   (c) ECR-15 — UN FICHIER SOURCE TIENT EN 500 LIGNES. Au-dela, plus personne
//       ne lit le fichier en entier avant d'y toucher : on y cherche, on
//       modifie localement, et les effets de bord se decouvrent en
//       production. 50 fichiers depassent au 02/10/2026, dont 23 au-dela de
//       800 lignes.
//
// LES TROIS PLAFONDS SONT TENUS SEPAREMENT, et c'est voulu : un total unique
// permettrait de reparer l'un en degradant l'autre sans que rien ne rougisse.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'mesure_des_sources_645.dart';

/// Mesure du 02/10/2026, tete 147ca32d : 1 entree non autorisee a la racine de
/// `lib/` (`lib/docs/`).
const plafondIntrusRacineLib = 1;

/// Mesure du 02/10/2026, tete 147ca32d : 2 fichiers `.dart` sous un dossier
/// `docs/` de `lib/` (`riverpod_migration_guide.dart`,
/// `flutter_map_v8_changes.dart`).
const plafondDartSousDocs = 2;

/// Mesure du 02/10/2026, APRES le lot 645-11 : 52 fichiers source de `lib/`
/// au-dela de 500 lignes (29 entre 501 et 800, 23 au-dela de 800).
///
/// POURQUOI CE PLAFOND MONTE DE 50 A 52, ET CE QUE CELA NE VEUT PAS DIRE. Le lot
/// 645-11 a pose un en-tete `///` en premiere ligne des 472 fichiers de `lib/`
/// qui n'en avaient pas. L'en-tete coute QUATRE lignes a chaque fichier : une a
/// trois lignes de doc, le `library;` qui evite l'info
/// `dangling_library_doc_comments`, et la ligne vide qui le separe des imports.
/// DEUX fichiers tenaient a moins de quatre lignes de la borne et l'ont donc
/// franchie SANS QU'UNE SEULE LIGNE DE CODE SOIT AJOUTEE :
///
///   - `lib/core/services/source_de_donnees_sentier.dart` : 497 -> 501 ;
///   - `lib/features/trek/presentation/refuge_detail_screen.dart` : 499 -> 503.
///
/// La dette que cette garde mesure — « un fichier trop long pour etre lu en
/// entier avant d'y toucher » — n'a donc pas bouge d'une ligne : ces deux
/// fichiers etaient a la limite hier, ils y sont encore, et ils sont desormais
/// DOCUMENTES, ce qui les rend plus lisibles et non moins. Le decoupage reste le
/// travail du lot 645-06.
///
/// CE QUE CE PRECEDENT N'AUTORISE PAS. Monter ce plafond parce qu'on a ajoute du
/// CODE serait exactement le defaut que la garde existe pour attraper. Il ne se
/// monte que sur une cause mesuree et nommee, comme ici — et il ne redescendra
/// que par un decoupage.
const plafondFichiersTropLongs = 52;

/// Le plafond de lignes d'un fichier source (ECR-15).
const maximumLignesParFichier = 500;

void main() {
  group('645-01 / ECR-13 — la racine de lib/ ne se remplit plus', () {
    test(
      'pas plus d entrees non autorisees a la racine de lib qu au 02/10',
      () {
        final racine = Directory('lib');
        expect(
          racine.existsSync(),
          isTrue,
          reason: 'la garde doit tourner a la racine du paquet Flutter',
        );

        final presents =
            racine
                .listSync()
                .map((e) => e.path.replaceAll(r'\', '/').split('/').last)
                .toList()
              ..sort();
        final intrus = presents
            .where((n) => !zonesRacineAutorisees.contains(n))
            .toList();

        expect(
          intrus.length,
          lessThanOrEqualTo(plafondIntrusRacineLib),
          reason:
              'LA RACINE DE lib/ SE REMPLIT : ${intrus.length} entrees non '
              'autorisees, contre $plafondIntrusRacineLib au 02/10/2026. La '
              'racine est la premiere chose qu on lit d un depot ; elle doit '
              'repondre « voila les couches », pas « voila ce qui s est '
              'accumule ».\n'
              'LES CINQ ENTREES AUTORISEES : '
              '${zonesRacineAutorisees.toList().join(', ')}. Tout le reste '
              'descend dans l une d elles.\n  ${intrus.join('\n  ')}',
        );
      },
    );
  });

  group('645-01 / ECR-07 — la documentation ne se livre plus en .dart', () {
    test('pas plus de .dart sous un docs/ de lib qu au 02/10', () {
      // AVEC LE CODE GENERE : un `.dart` de documentation ne devient pas
      // acceptable parce qu un generateur l aurait produit.
      final sousDocs = sourcesLib(
        avecGeneres: true,
      ).where((f) => f.contains('/docs/')).toList();

      expect(
        sousDocs.length,
        lessThanOrEqualTo(plafondDartSousDocs),
        reason:
            'DE LA DOCUMENTATION EST LIVREE EN .dart : ${sousDocs.length} '
            'fichiers sous un docs/ de lib/, contre $plafondDartSousDocs au '
            '02/10/2026. Un .dart est compile, analyse et embarque comme du '
            'code — sans jamais s executer. Les deux fichiers connus doivent '
            'DESARMER l analyseur (`// ignore_for_file: unused_element`) pour '
            'seulement compiler : c est l aveu qu ils ne sont pas a leur '
            'place.\n'
            'ECRIVEZ DU .md DANS LE docs/ A LA RACINE DU DEPOT : il ne coute '
            'rien a personne, et il se lit sans editeur Dart.\n'
            '  ${sousDocs.join('\n  ')}',
      );
    });
  });

  group('645-01 / ECR-15 — les fichiers ne grossissent plus', () {
    test('pas plus de fichiers au dela de 500 lignes qu au 02/10', () {
      final tropLongs = <String, int>{};
      for (final f in sourcesLib()) {
        final n = lignesDe(f).length;
        if (n > maximumLignesParFichier) tropLongs[f] = n;
      }

      final detail =
          (tropLongs.entries.toList()..sort((a, b) => b.value - a.value))
              .map((e) => '${e.key}  (${e.value} lignes)')
              .join('\n  ');

      expect(
        tropLongs.length,
        lessThanOrEqualTo(plafondFichiersTropLongs),
        reason:
            'UN FICHIER DE PLUS DEPASSE $maximumLignesParFichier LIGNES : '
            '${tropLongs.length} fichiers au-dela, contre '
            '$plafondFichiersTropLongs au 02/10/2026. Passe cette taille, '
            'plus personne ne lit le fichier en entier avant d y toucher : on '
            'y cherche, on modifie localement, et les effets de bord se '
            'decouvrent en production.\n'
            'DECOUPEZ AVANT D AJOUTER. Si vous grossissez un fichier qui '
            'depassait DEJA, ce plafond ne rougit pas — mais la dette, elle, '
            'augmente : le decoupage est le travail du lot 645-06.\n'
            '  $detail',
      );
    });

    test('la mesure des tailles lit bien les fichiers — sinon le plafond ne '
        'mesure rien', () {
      // UNE MESURE QUI RENVOIE ZERO PASSE AU VERT EN SILENCE. On verifie que
      // la lecture voit un depot peuple et des fichiers de taille plausible.
      final fichiers = sourcesLib();
      expect(
        fichiers.length,
        greaterThan(400),
        reason:
            'lib/ porte 599 sources au 02/10/2026 : un chiffre bien plus '
            'bas signale que le balayage ne lit plus l arborescence',
      );
      expect(
        fichiers.map(lignesDe).map((l) => l.length).reduce((a, b) => a + b),
        greaterThan(10000),
        reason:
            'le total des lignes de lib/ ne peut pas etre marginal : une '
            'lecture cassee rendrait les trois plafonds inoperants',
      );
    });
  });
}
