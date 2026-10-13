import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — LES RESSOURCES XML ANDROID RESTENT LISIBLES PAR LE
/// COMPILATEUR DE RESSOURCES (StepWays tache 619).
///
/// CE QUI S EST PASSE, ET C EST MESURE. Le fichier
/// `android/app/src/main/res/xml/regles_sauvegarde_donnees.xml`, reecrit par la
/// tache 617, separait les parties de son long commentaire par des lignes de
/// tirets. Or LA SUITE `--` EST INTERDITE DANS UN COMMENTAIRE XML : c est une
/// regle de la norme, pas une preference de style. Le fichier n etait donc plus
/// du XML bien forme, et le compilateur de ressources Android s arretait dessus :
///
///   Failed to compile resource file: .../regles_sauvegarde_donnees.xml
///   javax.xml.stream.XMLStreamException: ParseError at [row,col]:[16,8]
///   Message: La chaine "--" n est pas autorisee dans les commentaires.
///
/// AUCUN PAQUET ANDROID NE SORTAIT. Ni AAB, ni APK, ni debug, ni release.
///
/// POURQUOI CE PIEGE VA REVENIR SANS GARDE. Ce depot ecrit de longs commentaires
/// explicatifs — c est une bonne habitude, et celui-la fait cent lignes. Une
/// ligne de separation en tirets est le geste le plus naturel du monde dans un
/// texte pareil, et RIEN dans l editeur ne signale l interdiction. Elle ne se
/// paie qu au build Android, que personne ne lance en ecrivant du Dart.
///
/// ET CE FICHIER-LA N EST PAS DECORATIF : il declare ce qui part du telephone du
/// randonneur vers la sauvegarde Google. Le rendre illisible ne le rend pas
/// permissif — Android refuse simplement de construire l application.
void main() {
  group('619 — les ressources XML Android sont bien formees', () {
    /// TOUT l arbre Android : le manifeste ET les ressources.
    ///
    /// Le perimetre est large a dessein. Le premier balayage ne couvrait que
    /// `res/`, et le build a rechute immediatement sur `AndroidManifest.xml`,
    /// ou la tache 595 avait ecrit le nom d une option en ligne de commande avec
    /// ses deux tirets de tete, dans un commentaire. Deux fichiers differents,
    /// deux taches differentes, la meme regle enfreinte : la garde doit donc
    /// couvrir tout ce que le compilateur de ressources et le fusionneur de
    /// manifestes vont lire.
    final dossiers = [Directory('android')];

    test(
      'aucun commentaire XML ne contient la suite `--`, interdite par la norme '
      '— sinon le compilateur de ressources Android arrete le build',
      () {
        final fautifs = <String>[];

        for (final dossier in dossiers) {
          if (!dossier.existsSync()) continue;

          for (final entite in dossier.listSync(recursive: true)) {
            if (entite is! File) continue;
            final chemin = entite.path.replaceAll(r'\', '/');
            if (!chemin.endsWith('.xml')) continue;
            // Les sorties de build et les caches Gradle ne sont pas ecrits a la
            // main : les balayer ferait dependre le resultat de ce qui traine
            // sur la machine.
            if (chemin.contains('/build/') ||
                chemin.contains('/.gradle/') ||
                chemin.contains('/.idea/')) {
              continue;
            }

            final source = entite.readAsStringSync();

            var debut = source.indexOf('<!--');
            while (debut != -1) {
              final fin = source.indexOf('-->', debut + 4);
              expect(
                fin,
                isNot(-1),
                reason: '$chemin : un commentaire XML n est jamais ferme',
              );

              final corps = source.substring(debut + 4, fin);
              if (corps.contains('--')) {
                // On nomme la ligne, pas le decalage : c est ce que le
                // developpeur voit dans son editeur.
                final ligne = '\n'
                    .allMatches(source.substring(0, debut))
                    .length;
                fautifs.add(
                  '$chemin : commentaire ouvert ligne ${ligne + 1} '
                  'contenant la suite interdite `--`',
                );
              }

              debut = source.indexOf('<!--', fin + 3);
            }
          }
        }

        expect(
          fautifs,
          isEmpty,
          reason:
              'La suite `--` est interdite dans un commentaire XML. Le '
              'compilateur de ressources Android refuse le fichier et AUCUN '
              'paquet ne sort (ni AAB, ni APK, ni debug, ni release). Pour '
              'separer des parties dans un long commentaire, utiliser des '
              'signes `=` :\n${fautifs.join('\n')}',
        );
      },
    );

    test(
      'les deux fichiers de regles de sauvegarde sont bien la et bien formes '
      '— ils declarent ce qui part du telephone du randonneur',
      () {
        for (final nom in [
          'regles_sauvegarde_donnees.xml',
          'regles_sauvegarde_complete.xml',
        ]) {
          final fichier = File('android/app/src/main/res/xml/$nom');
          expect(
            fichier.existsSync(),
            isTrue,
            reason:
                '$nom a disparu : sans lui la sauvegarde Google reprend '
                'ses reglages par defaut, qui emportent tout',
          );

          final source = fichier.readAsStringSync();
          expect(
            '<!--'.allMatches(source).length,
            '-->'.allMatches(source).length,
            reason:
                '$nom : commentaires ouverts et fermes en nombres '
                'differents, le fichier n est pas bien forme',
          );
        }
      },
    );
  });
}
