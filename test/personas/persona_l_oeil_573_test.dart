// PERSONA — L'OEIL (tache 573, LOT V).
//
// CE QU'IL FAIT. Il REGARDE l'ecran au lieu d'en lire les textes. Il voit les
// superpositions, les debordements, les textes coupes. Et il confronte ce qui est
// ECRIT a ce que l'application FAIT ensuite : quand la page dit « vise 9 jours »
// et que 9 jours s'affichent en rouge deux centimetres plus bas, il le voit tout
// de suite. C'est ce qu'a fait Chris, et c'est la seule facon dont cette
// incoherence pouvait etre trouvee.
//
// CE QU'IL AURAIT ATTRAPE :
//
//   * retour 13, verbatim : « 14rando les numeros d'etapes son caches par les
//     refucge, il ne faut pas que les icones se superposent ». Ce n'est pas un
//     accident d'affichage : une etape se TERMINE a un refuge, donc les deux
//     marqueurs sont au meme point PAR CONSTRUCTION, et la couche des points
//     d'interet est peinte APRES celle des numeros.
//   * QUE-003 du 26/09, verbatim : « le curseur est celui conseille et il n'est
//     jamais en rouge quand il est conseille en orange max » — l'application
//     conseillait une valeur qu'elle declarait mauvaise dans la meme page.
//   * les debordements : deux ecrans debordent de 67 et 117 pixels sur la droite,
//     ce qui coupe du texte a l'ecran. Personne ne l'avait jamais releve.
//
// POURQUOI AUCUN PERSONA NE L'A VU. La campagne LIT des textes : elle cherche une
// chaine, la trouve, et coche. Un texte cache derriere une icone est present dans
// l'arbre des widgets — donc trouve, donc coche. Un texte coupe par un
// debordement est present aussi. La campagne ne peut structurellement pas voir ce
// que l'oeil voit.
//
// LE TROU DE GRILLE QU'IL FERME : (G) on ne REGARDE pas l'ecran, on lit ses
// textes — d'ou les numeros d'etape caches par les refuges, invisibles a la
// campagne.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/presentation/map/layers/trail_markers_layer.dart';

import '../structurel/parcours_reel.dart';

/// Les debordements ADMIS, et la raison de chacun.
const debordementsAdmis = <String, String>{};

void main() {
  group('L OEIL — rien ne deborde de l ecran', () {
    testWidgets('aucun ecran ne coupe son contenu sur un telephone courant',
        (tester) async {
      // MESURE DU 26/09 sur ce depot : deux ecrans debordent — `/follow/:code`
      // de 67 pixels et `/accommodations-nearby` de 117. Un debordement coupe du
      // texte a l'ecran sans rien lever : l'utilisateur voit une phrase
      // tronquee, et tous les tests restent verts parce que la chaine est bien
      // dans l'arbre des widgets.
      final debordent = <String>[];
      for (final r in routesDeclarees()) {
        final concret = cheminConcret(r.gabarit);
        if (concret == null) continue;
        await monterAppliReelle(tester, depart: concret);
        final erreurs = erreursDeRendu(tester).where(estDebordement).toList();
        if (erreurs.isEmpty) continue;
        if (debordementsAdmis.containsKey(r.gabarit)) continue;
        final premiere = erreurs.first.split('\n').first;
        debordent.add('$concret : $premiere');
      }
      await demonterAppli(tester);
      erreursDeRendu(tester);
      expect(debordent, isEmpty,
          reason: 'DU CONTENU EST COUPE A L ECRAN. La campagne ne peut pas le '
              'voir : le texte tronque est bien present dans l arbre des '
              'widgets, donc « trouve ».\n  ${debordent.join('\n  ')}');
    });
  });

  group('L OEIL — deux marqueurs au meme point se superposent', () {
    // CE TEST A ETE REECRIT (tache 580, point Y5), ET LA RAISON MERITE D'ETRE
    // ECRITE ICI PLUTOT QU'EN MESSAGE DE COMMIT.
    //
    // LA PREMIERE VERSION CHERCHAIT, DANS `map_screen.dart`, LES CHAINES
    // `MarkerCluster`, `marker_cluster` OU `fusionMarqueurs`. Elle avait devine
    // COMMENT la fusion serait ecrite et verifiait cette devinette. Le LOT T
    // (tache 571) a justement refuse de reutiliser `marker_cluster.dart` — il
    // ne s'active qu'au-dela de 50 marqueurs, travaille couche par couche, rate
    // les couples a cheval sur une frontiere de cellule et pose la bulle sur un
    // centroide, donc deplace le repere — et a construit [MarkerOverlap] +
    // [TrailMarkersLayer]. Resultat : le retour 13 de Chris etait FERME dans le
    // code, et ce test restait ROUGE.
    //
    // UN FAUX ROUGE DANS UNE GARDE EST PIRE QU'UNE GARDE ABSENTE : il apprend a
    // tout le monde a ignorer les rouges. Et c'est exactement la faute de
    // methode que le LOT V denoncait chez les autres — mesurer une
    // IMPLEMENTATION au lieu d'une PROPRIETE.
    //
    // LA PROPRIETE, ELLE, NE SE PERIME PAS : sur les donnees LIVREES du
    // sentier, a tous les zooms, AUCUN COUPLE DE MARQUEURS RENDUS PAR LA CARTE
    // NE SE RECOUVRE. Elle se mesure sur la liste de [Marker] que la couche
    // remet a flutter_map — position, largeur, hauteur — avec une regle
    // arithmetique ecrite ICI, independante du module mesure. Reecrire la
    // fusion autrement, ou la supprimer, se voit ; la renommer ne se voit pas,
    // et c'est bien ainsi.

    /// Les donnees SEEDEES du sentier : celles que la carte dessine.
    ///
    /// L'ancienne version lisait `assets/data/mare_a_mare_centre.json`, qui ne
    /// sert qu'aux hebergements ; les etapes et les points d'interet de la
    /// carte viennent du dossier `mare_a_mare_centre/` (cf.
    /// `mare_a_mare_centre_trail_config.dart`, `seedAssetsBase`). Le test
    /// mesurait donc des coincidences sur des donnees que l'ecran n'affiche
    /// pas.
    List<Map<String, dynamic>> lire(String fichier) =>
        (jsonDecode(File('assets/data/mare_a_mare_centre/$fichier')
                .readAsStringSync()) as List)
            .cast<Map<String, dynamic>>();

    /// Distance geodesique en metres (haversine), calculee ici : le test ne
    /// doit rien emprunter au code qu'il juge.
    double metres(double la1, double ln1, double la2, double ln2) {
      const r = 6371008.8;
      double rad(double d) => d * math.pi / 180.0;
      final dLat = rad(la2 - la1);
      final dLng = rad(ln2 - ln1);
      final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
          math.cos(rad(la1)) *
              math.cos(rad(la2)) *
              math.sin(dLng / 2) *
              math.sin(dLng / 2);
      return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    }

    /// Metres couverts par un pixel d'ecran (formule slippy map standard).
    double metresParPixel(double zoom, double latitude) =>
        40075016.686 *
        math.cos(latitude * math.pi / 180.0).abs() /
        (256.0 * math.pow(2, zoom));

    /// Les etapes et les lieux reels, prets pour la couche de la carte.
    (List<Stage>, List<PoiModel>) sentierReel() {
      final stages = [
        for (final s in lire('stages.json'))
          Stage(
            id: s['id'] as String,
            nameFr: s['nameFr'] as String,
            distance: (s['distanceKm'] as num).toDouble(),
            elevationGain: (s['elevationGainM'] as num).toInt(),
            elevationLoss: (s['elevationLossM'] as num).toInt(),
            orderIndex: (s['stageNumber'] as num).toInt(),
            startLat: (s['startLat'] as num).toDouble(),
            startLng: (s['startLng'] as num).toDouble(),
            endLat: (s['endLat'] as num).toDouble(),
            endLng: (s['endLng'] as num).toDouble(),
          ),
      ];
      final pois = [
        for (final p in lire('pois.json'))
          PoiModel(
            trailId: 'mare-a-mare-centre',
            stageNumber: 0,
            name: p['nameFr'] as String,
            type: p['type'] as String,
            lat: (p['lat'] as num).toDouble(),
            lng: (p['lng'] as num).toDouble(),
          ),
      ];
      return (stages, pois);
    }

    /// La bande de zoom utile d'une carte de randonnee, du sentier entier au
    /// detail d'un hameau.
    const zooms = <double>[
      1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
      12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
    ];

    /// Monte la couche de reperes du sentier et rend CE QUE LA CARTE DESSINE.
    Future<List<Marker>> reperesRendus(
      WidgetTester tester, {
      required List<Stage> stages,
      required List<PoiModel> pois,
      required double zoom,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(stages.first.startLat,
                    stages.first.startLng),
                initialZoom: zoom,
              ),
              children: [
                TrailMarkersLayer(stages: stages, pois: pois, zoom: zoom),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final couches = tester.widgetList<MarkerLayer>(find.byType(MarkerLayer));
      return [for (final c in couches) ...c.markers];
    }

    test('les donnees LIVREES posent bien des reperes au meme endroit — sans '
        'quoi ce test ne prouverait rien', () {
      // LE DEFAUT EST STRUCTUREL, PAS ACCIDENTEL. Une etape se TERMINE a un
      // refuge ou dans un village et la suivante en REPART : le marqueur de
      // l'etape et celui du lieu sont au MEME point par construction.
      final (stages, pois) = sentierReel();
      expect(stages, isNotEmpty, reason: 'lecture des etapes cassee');
      expect(pois, isNotEmpty, reason: 'lecture des lieux cassee');

      final coincidences = <String>[];
      for (final s in stages) {
        for (final p in pois) {
          // 300 m : a l'echelle d'affichage de la carte, deux marqueurs aussi
          // proches se chevauchent.
          if (metres(s.startLat, s.startLng, p.lat, p.lng) > 300) continue;
          coincidences.add('etape ${s.orderIndex} et ${p.type} « ${p.name} »');
        }
      }
      expect(coincidences, isNotEmpty,
          reason: 'aucune coincidence trouvee dans les donnees livrees : la '
              'lecture est cassee, et ce test ne prouverait plus rien');
    });

    testWidgets(
      'AUCUN couple de marqueurs rendus ne se recouvre, a aucun zoom',
      (tester) async {
        final (stages, pois) = sentierReel();
        final recouvrements = <String>[];

        for (final zoom in zooms) {
          final reperes = await reperesRendus(
            tester,
            stages: stages,
            pois: pois,
            zoom: zoom,
          );
          expect(reperes, isNotEmpty, reason: 'zoom $zoom : rien n est rendu');

          for (var i = 0; i < reperes.length; i++) {
            for (var j = i + 1; j < reperes.length; j++) {
              final a = reperes[i];
              final b = reperes[j];
              final ecartM = metres(
                a.point.latitude,
                a.point.longitude,
                b.point.latitude,
                b.point.longitude,
              );
              final echelle = metresParPixel(
                zoom,
                (a.point.latitude + b.point.latitude) / 2,
              );
              final ecartPx = ecartM / echelle;
              // Deux disques se touchent des que l'ecart entre leurs centres
              // descend sous la somme de leurs rayons.
              final minimum = (a.width + b.width) / 2;
              if (ecartPx >= minimum) continue;
              recouvrements.add('zoom $zoom : deux reperes a '
                  '${ecartPx.toStringAsFixed(1)} px l un de l autre, alors '
                  'qu il en faut ${minimum.toStringAsFixed(0)}');
            }
          }
        }

        expect(recouvrements, isEmpty,
            reason: 'DES MARQUEURS SE MARCHENT DESSUS SUR LA CARTE LIVREE. Le '
                'numero d etape passe sous l icone du lieu — le retour 13 de '
                'Chris, verbatim : « 14rando les numeros d etapes son caches '
                'par les refucge, il ne faut pas que les icones se '
                'superposent ».\n  ${recouvrements.take(10).join('\n  ')}');
      },
    );

    testWidgets(
      'la fusion a bien LIEU : en vue large, le sentier ne montre plus une '
      'icone par lieu mais une poignee de reperes',
      (tester) async {
        // SANS CE TEST, LE PRECEDENT SERAIT SATISFAIT PAR UNE CARTE QUI NE
        // DESSINE RIEN. On exige donc que le nombre de reperes DIMINUE quand
        // on s'eloigne, et qu'au plus fin chacun retrouve le sien — sauf les
        // points reellement confondus, qu'aucun zoom ne peut separer.
        final (stages, pois) = sentierReel();
        final total = stages.length + pois.length;

        final large = await reperesRendus(tester,
            stages: stages, pois: pois, zoom: 11);
        expect(large.length, lessThan(total),
            reason: 'en vue large, $total icones restent empilees : rien n est '
                'fusionne');

        final fin = await reperesRendus(tester,
            stages: stages, pois: pois, zoom: 22);
        expect(fin.length, lessThanOrEqualTo(total));
        expect(fin.length, greaterThan(large.length),
            reason: 'au plus fin, les lieux distincts doivent reprendre chacun '
                'leur repere : on ne fusionne pas ce qui se distingue');
      },
    );
  });

  group('L OEIL — ce qui est ECRIT et ce que l appli FAIT', () {
    testWidgets('la page de faisabilite ne conseille pas une valeur qu elle '
        'declare mauvaise', (tester) async {
      // CE QUE CHRIS A LU, SUR UN SEUL ECRAN : « vise 9 jours » au-dessus de
      // « Decoupage trop serre ». Deux phrases contradictoires a deux
      // centimetres l'une de l'autre. Le test de l'invariante (LOT R) verifie
      // l'ACCORD DES MOTEURS ; celui-ci verifie l'ACCORD DES PHRASES, parce que
      // c'est la forme sous laquelle l'utilisateur le rencontre.
      final concret = cheminConcret('/trail/:id/feasibility')!;
      await monterAppliReelle(tester, depart: concret);
      final textes = textesVisibles(tester);
      await demonterAppli(tester);
      erreursDeRendu(tester);

      final conseil = textes.where((t) => t.toLowerCase().contains('vise ')).toList();
      // Le libelle rouge du verdict, tel que l'i18n le definit.
      final i18n = jsonDecode(
              File('assets/i18n/fr.i18n.json').readAsStringSync())
          as Map<String, dynamic>;
      final rouge = ((((i18n['feasibility'] as Map)['formula'] as Map)['verdicts']
              as Map)['red'] as String)
          .trim();
      final verdictRouge = textes.any((t) => t.trim() == rouge);

      expect(
        conseil.isNotEmpty && verdictRouge,
        isFalse,
        reason: 'LA MEME PAGE CONSEILLE ET CONDAMNE : elle affiche '
            '${conseil.join(' / ')} et le verdict « $rouge ». C est ce que '
            'Chris a lu le 26/09 a 10:30. Quand aucune duree ne convient, '
            'l application doit le DIRE au lieu de pointer une valeur.',
      );
    });

    testWidgets('aucun ecran ne promet une fonction en la nommant sans y mener',
        (tester) async {
      // Un texte qui nomme une fonction s'engage. Le guide des icones de la
      // carte documentait un bouton SOS que l'application n'offrait nulle part :
      // on avait fait ecrire le mode d'emploi d'un bouton fantome. Ici, version
      // visuelle du meme controle : un ecran qui affiche le mot d'une fonction
      // doit offrir un geste vers elle.
      final concret = cheminConcret('/map')!;
      await monterAppliReelle(tester, depart: concret);
      final textes = textesVisibles(tester).join(' | ').toLowerCase();
      final gestes = gestesDisponibles(tester).map((g) => g.libelle).toList();
      await demonterAppli(tester);
      erreursDeRendu(tester);

      if (!textes.contains('sos') && !textes.contains('urgence')) return;
      final offreSos = gestes.any((l) {
        final b = l.toLowerCase();
        return b.contains('sos') || b.contains('urgence');
      });
      expect(offreSos, isTrue,
          reason: 'LA CARTE PARLE DU SOS ET NE L OFFRE PAS : les textes de '
              'l ecran mentionnent l urgence, aucun geste visible n y mene. '
              'Gestes disponibles : ${gestes.join(' / ')}');
    });
  });
}
