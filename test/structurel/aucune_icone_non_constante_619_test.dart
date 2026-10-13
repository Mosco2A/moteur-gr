import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — AUCUNE ICONE CONSTRUITE A L EXECUTION DANS `lib/`
/// (StepWays tache 619).
///
/// CE QUE CETTE GARDE EMPECHE, ET POURQUOI ELLE EXISTE MAINTENANT. Une seule
/// ligne de `lib/` fabriquait son icone a l execution
/// (`IconData(cp, fontFamily: 'MaterialIcons')`, dans la section de categorie de
/// la checklist). La compilation release retire de la police d icones tous les
/// glyphes qu elle ne voit pas utilises, et elle ne peut les voir que dans des
/// `IconData` CONST. Devant une construction non constante elle ne devine pas :
/// elle ARRETE LE BUILD. Resultat mesure le 28/09 : `flutter build appbundle
/// --release` echouait, donc AUCUN paquet installable ne sortait du depot — ni
/// AAB pour Google, ni IPA pour Apple. C etait le seul obstacle entre trois jours
/// de travail et un telephone.
///
/// POURQUOI PERSONNE NE L AVAIT VU, ET POURQUOI UN TEST EST LE BON FILET. Le
/// defaut ne se voit sur AUCUNE chaine existante : le seul build automatise qui
/// va jusqu au bout est un APK DEBUG (workflow `merge` de codemagic.yaml), et le
/// retrait des glyphes n a pas lieu en debug ; les deux chaines release
/// s arretent AVANT le build, faute de secrets de signature. L etape qui echoue
/// n avait donc jamais ete atteinte. Un test l atteint a chaque suite, sans
/// secret, sans magasin et sans machine Apple.
void main() {
  group('619 — aucune icone non constante dans lib/', () {
    test(
      'aucun fichier de lib/ ne construit un String a l execution — '
      'sinon la compilation release s arrete et aucun paquet installable ne sort',
      () {
        final racine = Directory('lib');
        expect(
          racine.existsSync(),
          isTrue,
          reason: 'le test doit tourner a la racine du paquet Flutter',
        );

        // `IconData(` precede d un caractere qui n est ni `const` ni un point :
        // on cherche les CONSTRUCTIONS, pas les mentions en commentaire ni les
        // occurrences dans du code genere.
        final construction = RegExp(r'String\s*\(');

        final fautifs = <String>[];

        for (final entite in racine.listSync(recursive: true)) {
          if (entite is! File) continue;
          final chemin = entite.path.replaceAll(r'\', '/');
          if (!chemin.endsWith('.dart')) continue;
          // Le code genere (.g.dart, .freezed.dart) n est pas ecrit a la main :
          // il ne construit pas d icones, et le tolerer evite un faux positif
          // au premier changement de generateur.
          if (chemin.endsWith('.g.dart') || chemin.endsWith('.freezed.dart')) {
            continue;
          }

          final lignes = entite.readAsLinesSync();
          for (var i = 0; i < lignes.length; i++) {
            final ligne = lignes[i];
            final nue = ligne.trimLeft();
            // Les commentaires expliquent justement ce piege : ils ne comptent pas.
            if (nue.startsWith('//') || nue.startsWith('///')) continue;
            if (nue.startsWith('*')) continue;

            for (final occurrence in construction.allMatches(ligne)) {
              final avant = ligne.substring(0, occurrence.start);
              // `const IconData(...)` est exactement ce qu on veut, et
              // `MyIconData(` / `.IconData(` ne sont pas la classe visee.
              if (avant.trimRight().endsWith('const')) continue;
              if (avant.endsWith('.')) continue;
              if (RegExp(r'[A-Za-z0-9_]$').hasMatch(avant)) continue;
              fautifs.add('$chemin:${i + 1}: ${ligne.trim()}');
            }
          }
        }

        expect(
          fautifs,
          isEmpty,
          reason:
              'Ces lignes construisent une icone a l execution. La '
              'compilation release refusera de produire un paquet '
              '(« Avoid non-constant invocations of String »). Rangez '
              'l icone dans une table `const Map<String, String>` — voir '
              '`checklistCategoryIcons` dans '
              'lib/features/checklist/data/checklist_template.dart :\n'
              '${fautifs.join('\n')}',
        );
      },
    );

    test('la table des icones de categorie porte bien des String const, '
        'et plus des codepoints', () {
      final fichier = File(
        'lib/features/checklist/data/checklist_template.dart',
      );
      expect(fichier.existsSync(), isTrue);

      final source = fichier.readAsStringSync();
      expect(
        source,
        contains('const Map<String, String> checklistCategoryIcons'),
        reason: 'la table doit ranger des icones, pas des entiers',
      );
      expect(
        source,
        isNot(contains('checklistCategoryIconCodepoints')),
        reason:
            'la table de codepoints etait la source du defaut : '
            'la laisser en place invite a la reutiliser',
      );
    });
  });
}
