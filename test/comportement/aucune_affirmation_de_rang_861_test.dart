// GARDE — TACHE 861 : PLUS AUCUNE AFFIRMATION DE RANG, NI DANS LE CODE NI
// DANS LES FICHES VENDUES AUX CLIENTS.
//
// POURQUOI CETTE GARDE EXISTE, ET ELLE EST NEE D'UNE VRAIE FAUTE. La jauge de
// la 860 etait un RANG : elle repondait « plus dure que les trois quarts des
// etapes officielles du monde », et c'etait VRAI. Deux textes clients le
// disaient — la fiche du chapitre nord et la legende du selecteur d'allure.
// La 861 remplace cette jauge par une graduation sur des SEUILS PUBLIES, qui
// ne calcule aucun rang. Les deux phrases sont donc devenues FAUSSES sans que
// personne ne les touche, et les trois portes de qualite restaient vertes
// parce qu'AUCUN TEST NE LES REGARDAIT.
//
// LA LECON, ET ELLE DEPASSE ce lot : changer un bareme peut rendre faux un
// texte COMMERCIAL qui ne parle pas de bareme. Un test vert ne prouve que ce
// qu'il regarde. Cette garde regarde.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// VRAI quand cette ligne est un commentaire : une garde qui lit les
/// commentaires s'eteint en PARLANT de ce qu'elle surveille. Les en-tetes de
/// ce depot racontent l'histoire des jauges retirees, et ils en ont le droit.
bool estUnCommentaire(String ligne) {
  final nue = ligne.trimLeft();
  return nue.startsWith('//') || nue.startsWith('*') || nue.startsWith('///');
}

/// Le CODE d'un fichier : ses lignes, commentaires retires.
String codeDe(File fichier) =>
    fichier.readAsLinesSync().where((l) => !estUnCommentaire(l)).join(' ');

/// Les fichiers Dart de `lib/`, sans le code genere ni les traductions.
List<File> sourcesDeLib() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where(
      (f) =>
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart') &&
          !f.path.contains('i18n'),
    )
    .toList(growable: false);

/// Les fiches vendues : ce sont elles qui parlent aux clients.
List<File> fichesDesSentiers() => <File>[
  for (final dossier in <String>[
    'gr20',
    'gr20-nord',
    'gr20-sud',
    'mare_a_mare_centre',
  ])
    if (File('assets/data/$dossier/fiche.json').existsSync())
      File('assets/data/$dossier/fiche.json'),
];

/// LES TOURNURES QUI AFFIRMENT UN RANG. La jauge n'en calcule plus aucun,
/// donc aucune ne peut plus etre vraie.
const affirmationsDeRang = <String>[
  'plus dur que les 106',
  'plus dure que les 106',
  '106 etapes officielles',
  'trois quarts des etapes',
  'corpus de calage',
  'percentile',
  'parmi les etapes officielles du monde',
];

void main() {
  group('861 — aucune affirmation de rang ne subsiste', () {
    test('AUCUNE CHAINE DE lib/ N AFFIRME UN RANG', () {
      final fautes = <String>[];
      for (final fichier in sourcesDeLib()) {
        final code = codeDe(fichier);
        for (final tournure in affirmationsDeRang) {
          if (code.contains(tournure)) {
            fautes.add('${fichier.path} : « $tournure »');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'la jauge ne calcule plus de rang, donc ces phrases sont '
            'devenues fausses :\n${fautes.join('\n')}',
      );
    });

    test('AUCUNE FICHE VENDUE N AFFIRME UN RANG A SES CLIENTS', () {
      final fiches = fichesDesSentiers();
      expect(fiches, isNotEmpty, reason: 'les fiches doivent etre verifiees');
      final fautes = <String>[];
      for (final fichier in fiches) {
        final texte = fichier.readAsStringSync();
        for (final tournure in affirmationsDeRang) {
          if (texte.contains(tournure)) {
            fautes.add('${fichier.path} : « $tournure »');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'une fiche promet a ses clients un rang qui n est plus '
            'calcule :\n${fautes.join('\n')}',
      );
    });

    test('ET LES FICHES QUI CITENT UNE NOTE NOMMENT SON AXE', () {
      // DES QU IL Y A DEUX AXES, un « 16,1 sur 20 » sans nom d'axe ne veut
      // plus rien dire. Les deux chapitres citent leurs notes : elles doivent
      // dire LAQUELLE.
      for (final dossier in <String>['gr20-nord', 'gr20-sud']) {
        final fichier = File('assets/data/$dossier/fiche.json');
        if (!fichier.existsSync()) continue;
        final fiche =
            json.decode(fichier.readAsStringSync()) as Map<String, dynamic>;
        final description = fiche['description'] as Map<String, dynamic>?;
        final texte = description?['a_quoi_s_attendre'] as String?;
        if (texte == null || !texte.contains('sur 20')) continue;
        expect(
          texte.contains('effort') || texte.contains('Effort'),
          isTrue,
          reason: '$dossier cite une note sans nommer son axe',
        );
      }
    });
  });
}
