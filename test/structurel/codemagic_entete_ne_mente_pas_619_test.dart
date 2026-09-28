import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — L EN-TETE DE `codemagic.yaml` DIT LA VERITE SUR LES
/// CHAINES QU IL CONTIENT (StepWays tache 619).
///
/// POURQUOI CETTE GARDE EXISTE. L en-tete du fichier enumere les chaines de
/// compilation. Il en listait QUATRE alors que le fichier en portait CINQ : la
/// chaine `ios_compile`, ajoutee par la tache 618, n y figurait pas. Un
/// en-tete qui enumere faux est pire qu absent — on le lit pour savoir ce qui
/// tourne, et il repond a cote. Ce depot a deja corrige plusieurs commentaires
/// menteurs cette semaine ; celui-la se verifie desormais tout seul.
///
/// CE QUE LA GARDE EXIGE, DANS LES DEUX SENS : toute chaine definie sous
/// `workflows:` est nommee dans l en-tete, et tout nom cite dans l en-tete
/// correspond a une chaine qui existe vraiment. Une chaine ajoutee sans etre
/// annoncee echoue ; une chaine supprimee dont le nom reste ecrit echoue aussi.
void main() {
  group('619 — l en-tete de codemagic.yaml ne ment pas', () {
    final fichier = File('codemagic.yaml');

    /// Les noms de chaines REELS : les cles de deux espaces sous `workflows:`.
    Set<String> chainesReelles(List<String> lignes) {
      final noms = <String>{};
      var dansWorkflows = false;
      final cle = RegExp(r'^  ([a-z0-9_]+):\s*$');
      for (final ligne in lignes) {
        if (ligne.startsWith('workflows:')) {
          dansWorkflows = true;
          continue;
        }
        if (!dansWorkflows) continue;
        final m = cle.firstMatch(ligne);
        if (m != null) noms.add(m.group(1)!);
      }
      return noms;
    }

    /// L en-tete : les lignes de commentaire AVANT `workflows:`.
    String enTete(List<String> lignes) {
      final tampon = <String>[];
      for (final ligne in lignes) {
        if (ligne.startsWith('workflows:')) break;
        tampon.add(ligne);
      }
      return tampon.join('\n');
    }

    test('chaque chaine definie est nommee dans l en-tete', () {
      expect(fichier.existsSync(), isTrue);
      final lignes = fichier.readAsLinesSync();
      final reelles = chainesReelles(lignes);
      final tete = enTete(lignes);

      expect(
        reelles,
        isNotEmpty,
        reason: 'aucune chaine trouvee : le format du fichier a change',
      );

      final absentes = reelles.where((nom) => !tete.contains(nom)).toList()
        ..sort();
      expect(
        absentes,
        isEmpty,
        reason:
            'ces chaines existent mais l en-tete ne les annonce pas, '
            'donc il enumere faux : ${absentes.join(', ')}',
      );
    });

    test('aucun nom de l en-tete ne designe une chaine disparue', () {
      final lignes = fichier.readAsLinesSync();
      final reelles = chainesReelles(lignes);
      final tete = enTete(lignes);

      // On ne cherche que des noms de la forme utilisee par les chaines, pour
      // ne pas prendre un mot de prose pour un nom de chaine.
      final cites = RegExp(r'\b([a-z]+_[a-z_]+)\b')
          .allMatches(tete)
          .map((m) => m.group(1)!)
          .where(
            (n) =>
                n.endsWith('_gate') ||
                n.endsWith('_test') ||
                n.endsWith('_compile') ||
                n.endsWith('_release'),
          )
          .toSet();

      final fantomes = cites.difference(reelles).toList()..sort();
      expect(
        fantomes,
        isEmpty,
        reason:
            'l en-tete cite des chaines qui n existent plus : '
            '${fantomes.join(', ')}',
      );
    });

    test('la chaine qui LIVRE un installable depuis toute branche existe '
        'et ne recoit aucune valeur de signature', () {
      final source = fichier.readAsStringSync();
      expect(
        source,
        contains('android_test:'),
        reason:
            'sans elle, rien d installable ne sort d une branche '
            'd integration : main est la seule a produire un APK',
      );

      // Le bloc de la chaine : de sa cle jusqu a la PREMIERE ligne suivante qui
      // n appartient plus a la chaine, c est-a-dire une autre cle de deux
      // espaces OU un commentaire de deux espaces (l en-tete de la chaine
      // d apres). Decouper sur la cle suivante seulement ferait avaler le long
      // commentaire de `ios_compile`, qui parle justement de groupes de
      // variables et de publication — et le controle se croirait en faute.
      final lignes = fichier.readAsLinesSync();
      final debut = lignes.indexWhere((l) => l.startsWith('  android_test:'));
      expect(debut, isNot(-1));
      final corps = <String>[lignes[debut]];
      for (var i = debut + 1; i < lignes.length; i++) {
        final l = lignes[i];
        if (RegExp(r'^  ([a-z0-9_]+:|#)').hasMatch(l)) break;
        corps.add(l);
      }
      final bloc = corps.join('\n');

      expect(
        bloc,
        contains("pattern: '*'"),
        reason: 'la chaine doit se declencher sur TOUTE branche',
      );
      expect(
        bloc,
        contains('build/**/outputs/**/*.apk'),
        reason: 'sans artefact, Christophe n a rien a telecharger',
      );
      expect(
        bloc.contains('groups:'),
        isFalse,
        reason:
            'un APK debug est signe par la cle de debogage de Flutter : '
            'cette chaine ne doit recevoir aucun groupe de variables',
      );
      expect(
        bloc.contains('publishing:'),
        isFalse,
        reason: 'cette chaine depose un artefact, elle ne publie nulle part',
      );
    });
  });
}
