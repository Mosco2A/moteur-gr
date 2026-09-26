import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/features/trek/presentation/map/marker_overlap.dart';

/// TACHE 571 — LA REGLE QUI DECIDE QUE DEUX REPERES DESIGNENT LE MEME LIEU.
///
/// Retour de Chris, mot pour mot : « 14rando les numeros d'etapes son caches
/// par les refucge, il ne faut pas que les icones se superposent ».
///
/// POURQUOI CES TESTS SONT PURS : la superposition se mesure en pixels, donc en
/// geometrie, et la geometrie se teste sans carte. La regle est extraite dans
/// [MarkerOverlap] precisement pour cela — et elle est eprouvee sur les
/// COORDONNEES REELLES du Mare a Mare Centre, lues dans
/// `assets/data/mare_a_mare_centre/`, pas sur des chiffres choisis pour que le
/// test passe.
///
/// LA GARANTIE CENTRALE, celle que Chris a demandee : a TOUS LES ZOOMS, aucun
/// couple de reperes rendus ne se recouvre. Elle est verifiee zoom par zoom sur
/// les 7 departs d'etape et les 20 points d'interet du sentier.
void main() {
  /// Diametre retenu par la carte pour juger du recouvrement : la taille d'un
  /// repere FUSIONNE, la plus grande qu'un repere puisse prendre.
  const pinDiameterPx = 48.0;

  /// Bande de zoom utile d'une carte de randonnee, du sentier entier au detail
  /// d'un hameau.
  const zoomLevels = [
    1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0,
    12.0, 13.0, 14.0, 15.0, 16.0, 17.0, 18.0, 19.0, 20.0, 21.0, 22.0,
  ];

  MapMarkerCandidate<String> pin(String label, double lat, double lng) =>
      MapMarkerCandidate<String>(
        position: LatLng(lat, lng),
        diameterPx: pinDiameterPx,
        data: label,
      );

  // --- Cozzano : le cas exact rapporte par Chris ------------------------
  // Depart de l'etape 3 (stages.json) et « Gite d etape de Cozzano »
  // (pois.json) : MEME latitude, MEME longitude, au chiffre pres.
  final departEtape3 = pin('etape 3', 41.9392, 9.1978);
  final giteCozzano = pin('gite de Cozzano', 41.9392, 9.1978);
  // L'epicerie du village, a 37 m du gite.
  final epicerieCozzano = pin('epicerie de Cozzano', 41.9395, 9.198);

  /// Les reperes reels du sentier, dans l'ordre de priorite de la carte :
  /// les departs d'etape d'abord, les points d'interet ensuite.
  List<MapMarkerCandidate<String>> reperesReelsDuSentier() {
    final stages = (jsonDecode(
      File('assets/data/mare_a_mare_centre/stages.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();
    final pois = (jsonDecode(
      File('assets/data/mare_a_mare_centre/pois.json').readAsStringSync(),
    ) as List)
        .cast<Map<String, dynamic>>();

    return [
      for (final stage in stages)
        pin(
          'etape ${stage['stageNumber']}',
          (stage['startLat'] as num).toDouble(),
          (stage['startLng'] as num).toDouble(),
        ),
      for (final poi in pois)
        pin(
          '${poi['type']} ${poi['nameFr']}',
          (poi['lat'] as num).toDouble(),
          (poi['lng'] as num).toDouble(),
        ),
    ];
  }

  group('MarkerOverlap — echelle de la carte', () {
    test('un pixel couvre la distance attendue par la projection carto', () {
      // Valeur de reference de la projection slippy map : a l'equateur et au
      // zoom 0, une tuile de 256 px couvre la Terre entiere.
      expect(
        MarkerOverlap.metersPerPixel(0, 0),
        closeTo(156543.03, 0.01),
      );
      // A la latitude du sentier (42° N), un pixel couvre 26 % de metres en
      // moins qu'a l'equateur : ignorer la latitude ferait fusionner trop tard.
      expect(
        MarkerOverlap.metersPerPixel(14, 41.9392),
        closeTo(7.11, 0.02),
      );
      // Un niveau de zoom en plus = deux fois plus fin.
      expect(
        MarkerOverlap.metersPerPixel(15, 41.9392) * 2,
        closeTo(MarkerOverlap.metersPerPixel(14, 41.9392), 1e-9),
      );
    });

    test('l ecart en pixels grandit avec le zoom, et il est nul a 0 m', () {
      expect(
        MarkerOverlap.screenGapPx(
          departEtape3.position,
          giteCozzano.position,
          14,
        ),
        0,
      );
      var precedent = 0.0;
      for (final zoom in zoomLevels) {
        final gap = MarkerOverlap.screenGapPx(
          giteCozzano.position,
          epicerieCozzano.position,
          zoom,
        );
        expect(gap, greaterThan(precedent));
        precedent = gap;
      }
    });
  });

  group('MarkerOverlap — deux reperes au MEME point', () {
    test(
      'le depart de l etape 3 et le gite de Cozzano sont fusionnes A TOUS LES '
      'ZOOMS : aucun zoom ne peut separer un seul et meme lieu',
      () {
        for (final zoom in zoomLevels) {
          final groups = MarkerOverlap.groupByLocation(
            [departEtape3, giteCozzano],
            zoom: zoom,
          );
          expect(
            groups.length,
            1,
            reason: 'au zoom $zoom les deux reperes doivent n en faire qu un',
          );
          expect(groups.single.count, 2);
        }
      },
    );

    test(
      'le repere fusionne est pose sur l ETAPE, a sa position EXACTE — jamais '
      'sur un centroide',
      () {
        final groups = MarkerOverlap.groupByLocation(
          [departEtape3, giteCozzano, epicerieCozzano],
          zoom: 14,
        );
        expect(groups.length, 1);
        final groupe = groups.single;
        expect(groupe.anchor.data, 'etape 3');
        expect(groupe.position.latitude, departEtape3.position.latitude);
        expect(groupe.position.longitude, departEtape3.position.longitude);
      },
    );
  });

  group('MarkerOverlap — deux reperes VOISINS mais distincts', () {
    test(
      'le gite et l epicerie de Cozzano (37 m) fusionnent en vue large et se '
      'separent des que le zoom les rend distinguables',
      () {
        final enVueLarge = MarkerOverlap.groupByLocation(
          [giteCozzano, epicerieCozzano],
          zoom: 14,
        );
        expect(enVueLarge.length, 1, reason: '37 m tiennent dans une icone');

        final auPlusPresDuVillage = MarkerOverlap.groupByLocation(
          [giteCozzano, epicerieCozzano],
          zoom: 20,
        );
        expect(
          auPlusPresDuVillage.length,
          2,
          reason: 'a ce zoom les deux lieux sont a des dizaines de pixels : ils '
              'meritent deux reperes',
        );
      },
    );

    test(
      'la decision suit l ecart REEL a l ecran, zoom par zoom — aucun palier '
      'invente',
      () {
        for (final zoom in zoomLevels) {
          final gap = MarkerOverlap.screenGapPx(
            giteCozzano.position,
            epicerieCozzano.position,
            zoom,
          );
          final fusionnes = MarkerOverlap.groupByLocation(
            [giteCozzano, epicerieCozzano],
            zoom: zoom,
          ).length ==
              1;
          expect(
            fusionnes,
            gap < pinDiameterPx,
            reason: 'au zoom $zoom l ecart vaut ${gap.toStringAsFixed(1)} px '
                'pour des reperes de $pinDiameterPx px',
          );
        }
      },
    );
  });

  group('MarkerOverlap — le sentier entier, a tous les zooms', () {
    test(
      'AUCUN couple de reperes rendus ne se recouvre, a aucun zoom '
      '(7 departs d etape + 20 points d interet reels)',
      () {
        final reperes = reperesReelsDuSentier();
        expect(reperes.length, 27, reason: 'les donnees du sentier ont change');

        for (final zoom in zoomLevels) {
          final groups = MarkerOverlap.groupByLocation(reperes, zoom: zoom);
          for (var i = 0; i < groups.length; i++) {
            for (var j = i + 1; j < groups.length; j++) {
              final gap = MarkerOverlap.screenGapPx(
                groups[i].position,
                groups[j].position,
                zoom,
              );
              expect(
                gap,
                greaterThanOrEqualTo(pinDiameterPx),
                reason: 'zoom $zoom : « ${groups[i].anchor.data} » et '
                    '« ${groups[j].anchor.data} » sont a '
                    '${gap.toStringAsFixed(1)} px — deux icones se marchent '
                    'dessus',
              );
            }
          }
        }
      },
    );

    test(
      'AUCUN repere ne mente sur sa position : il couvre a l ecran la position '
      'reelle de chacun de ses membres',
      () {
        final reperes = reperesReelsDuSentier();
        for (final zoom in zoomLevels) {
          for (final groupe in MarkerOverlap.groupByLocation(
            reperes,
            zoom: zoom,
          )) {
            // La position du repere est celle d'un membre REEL, a l'identique.
            expect(groupe.position, groupe.anchor.position);
            for (final membre in groupe.members) {
              final gap = MarkerOverlap.screenGapPx(
                groupe.position,
                membre.position,
                zoom,
              );
              expect(
                gap,
                lessThan(pinDiameterPx),
                reason: 'zoom $zoom : « ${membre.data} » est a '
                    '${gap.toStringAsFixed(1)} px du repere qui le represente',
              );
            }
          }
        }
      },
    );

    test(
      'tous les reperes du sentier sont representes une fois et une seule',
      () {
        final reperes = reperesReelsDuSentier();
        for (final zoom in zoomLevels) {
          final vus = <String>[];
          for (final groupe in MarkerOverlap.groupByLocation(
            reperes,
            zoom: zoom,
          )) {
            vus.addAll(groupe.members.map((m) => m.data));
          }
          expect(vus.length, reperes.length, reason: 'zoom $zoom');
          expect(vus.toSet().length, reperes.length, reason: 'zoom $zoom');
        }
      },
    );

    test(
      'en vue large le sentier ne montre plus 27 icones empilees mais une '
      'poignee de reperes lisibles',
      () {
        final reperes = reperesReelsDuSentier();
        final enVueLarge = MarkerOverlap.groupByLocation(reperes, zoom: 11);
        expect(enVueLarge.length, lessThan(reperes.length));

        // Au plus fin, chaque lieu retrouve son propre repere — SAUF UN
        // COUPLE, et c'est la preuve que le critere est bien geographique :
        // le depart de l'etape 3 et le « Gite d etape de Cozzano » sont au MEME
        // point (0,0 m). Aucun zoom ne peut separer un seul et meme lieu, et
        // c'est precisement pour ce cas qu'un decalage de quelques pixels
        // n'aurait rien regle.
        final auPlusFin = MarkerOverlap.groupByLocation(reperes, zoom: 22);
        expect(auPlusFin.length, reperes.length - 1);
        final encoreFusionne = auPlusFin.singleWhere((g) => g.isMerged);
        expect(encoreFusionne.anchor.data, 'etape 3');
        expect(
          encoreFusionne.members.map((m) => m.data),
          contains('shelter Gite d etape de Cozzano'),
        );
      },
    );
  });

  group('MarkerOverlap — la bande de zoom arrondie de la carte', () {
    test('la bande est evaluee a son plus petit zoom, du cote prudent', () {
      expect(MarkerOverlap.lowestZoomOfBand(16), 15.5);
      expect(MarkerOverlap.lowestZoomOfBand(10), 9.5);
    });

    test(
      'a 16,4 de zoom reel — arrondi a 16 par la carte — le gite et l epicerie '
      'se marchent encore dessus, et la regle les garde donc fusionnes',
      () {
        // Ce que l'oeil voit a 16,4 : moins de 48 px entre les deux centres.
        expect(
          MarkerOverlap.screenGapPx(
            giteCozzano.position,
            epicerieCozzano.position,
            16.4,
          ),
          lessThan(pinDiameterPx),
        );
        // Ce que la regle decide avec le seul zoom que la carte lui donne (16).
        final groups = MarkerOverlap.groupByLocation(
          [giteCozzano, epicerieCozzano],
          zoom: MarkerOverlap.lowestZoomOfBand(16),
        );
        expect(
          groups.length,
          1,
          reason: 'evaluer la bande a 16 tout rond aurait separe deux icones '
              'qui se recouvrent encore',
        );
      },
    );
  });

  group('MarkerOverlap — cas limites', () {
    test('une liste vide ne produit aucun repere', () {
      expect(
        MarkerOverlap.groupByLocation(
          <MapMarkerCandidate<String>>[],
          zoom: 14,
        ),
        isEmpty,
      );
    });

    test('un repere seul reste un repere seul, non fusionne', () {
      final groups = MarkerOverlap.groupByLocation([giteCozzano], zoom: 14);
      expect(groups.length, 1);
      expect(groups.single.isMerged, isFalse);
      expect(groups.single.count, 1);
    });

    test(
      'sans etape en jeu, le regroupement marche aussi : deux points d interet '
      'voisins n en font qu un, ancre sur le premier recu',
      () {
        final groups = MarkerOverlap.groupByLocation(
          [epicerieCozzano, giteCozzano],
          zoom: 14,
        );
        expect(groups.length, 1);
        expect(groups.single.anchor.data, 'epicerie de Cozzano');
        expect(groups.single.position, epicerieCozzano.position);
      },
    );
  });
}
