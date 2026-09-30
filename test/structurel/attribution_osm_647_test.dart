import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GARDE STRUCTURELLE — AUCUNE CARTE SANS SON ATTRIBUTION OPENSTREETMAP
/// (integration 647, point N01 du chiffrage 608, base #100941).
///
/// CE QUI MANQUAIT, ET CE QUE CELA COUTAIT. Quatre ecrans posent une
/// `FlutterMap`, et le fond vient d OpenStreetMap — en ligne
/// (`tile.openstreetmap.org`) comme hors ligne, puisque les `.mbtiles` fabriques
/// par `tool/cartes_hors_ligne` (lot 648) sont rendus depuis des donnees OSM. La
/// mention « © OpenStreetMap contributors » n existait dans AUCUN fichier de
/// `lib/`. La licence ODbL l exige des que l on DISTRIBUE ces donnees : en
/// embarquant les tuiles dans le telephone, le build 8 franchit exactement cette
/// ligne. Le manquement cessait donc d etre theorique.
///
/// POURQUOI UNE GARDE ET PAS SEULEMENT UNE CORRECTION. Une mention posee a la
/// main sur quatre ecrans est une mention qu on oubliera sur le cinquieme. Le
/// widget [AttributionOsm] la porte une fois pour toutes ; ce test verifie que
/// toute carte l utilise, y compris celles qui n existent pas encore.
///
/// CE QU ELLE EXIGE, DANS LES DEUX SENS : tout fichier de `lib/` qui construit
/// une `FlutterMap` pose une `AttributionOsm`, et le widget d attribution nomme
/// vraiment OpenStreetMap et pointe vers sa licence.
void main() {
  group('647 — aucune carte ne se dessine sans crediter OpenStreetMap', () {
    /// Les fichiers de `lib/` qui construisent VRAIMENT une carte.
    ///
    /// `lib/docs/` est exclu : ce dossier ne contient que de la documentation,
    /// et ses `FlutterMap(` sont dans des commentaires — du texte, pas un ecran.
    List<File> fichiersAvecUneCarte() {
      final trouves = <File>[];
      for (final entite in Directory('lib').listSync(recursive: true)) {
        if (entite is! File || !entite.path.endsWith('.dart')) continue;
        final chemin = entite.path.replaceAll(r'\', '/');
        if (chemin.startsWith('lib/docs/')) continue;
        if (chemin.endsWith('.g.dart') || chemin.endsWith('.freezed.dart')) {
          continue;
        }
        if (entite.readAsStringSync().contains('FlutterMap(')) {
          trouves.add(entite);
        }
      }
      return trouves;
    }

    test('il y a bien des cartes a verifier', () {
      expect(
        fichiersAvecUneCarte(),
        isNotEmpty,
        reason:
            'si plus aucun fichier ne construit de carte, cette garde ne garde '
            'plus rien — il faut le savoir',
      );
    });

    test('chaque carte pose une AttributionOsm', () {
      final sansAttribution = <String>[];
      for (final fichier in fichiersAvecUneCarte()) {
        if (!fichier.readAsStringSync().contains('AttributionOsm()')) {
          sansAttribution.add(fichier.path.replaceAll(r'\', '/'));
        }
      }
      expect(
        sansAttribution,
        isEmpty,
        reason:
            'la licence ODbL exige le credit des que l application distribue '
            'des donnees OpenStreetMap, et elle le fait : poser '
            'const AttributionOsm() dans les children de la carte',
      );
    });

    test('le widget d attribution nomme OSM et pointe vers sa licence', () {
      final widget = File('lib/shared/widgets/attribution_osm.dart');
      expect(widget.existsSync(), isTrue, reason: widget.path);
      final source = widget.readAsStringSync();

      expect(
        source,
        contains('OpenStreetMap contributors'),
        reason: 'c est la formule exacte que demande la licence',
      );
      expect(
        source,
        contains('https://www.openstreetmap.org/copyright'),
        reason: 'le credit doit mener a la licence, pas seulement la citer',
      );
      expect(
        source,
        contains('t.map.attribution.licence'),
        reason:
            'le libelle passe par slang, comme tout le reste — cinq langues, '
            'zero texte en dur',
      );
    });

    test('le libelle existe dans les cinq langues', () {
      for (final langue in const ['fr', 'en', 'de', 'it', 'es']) {
        final source = File('assets/i18n/$langue.i18n.json').readAsStringSync();
        expect(
          source,
          contains('"attribution"'),
          reason: 'la cle map.attribution manque en $langue',
        );
      }
    });
  });
}
