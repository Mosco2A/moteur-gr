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

import 'package:flutter_test/flutter_test.dart';

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
    test('les numeros d etape ne sont pas caches par les points d interet', () {
      // LE DEFAUT EST STRUCTUREL, PAS ACCIDENTEL. Une etape se termine a un
      // refuge ou dans un village : le marqueur de l'etape et celui du lieu sont
      // au MEME point geographique. La carte pose deux couches distinctes, la
      // seconde par-dessus la premiere. Aucun decalage ne reglera ca : il faut
      // FUSIONNER le marqueur quand les deux coincident.
      final trail = File('assets/data/mare_a_mare_centre.json');
      expect(trail.existsSync(), isTrue);
      final data = jsonDecode(trail.readAsStringSync()) as Map<String, dynamic>;
      final stages = (data['stages'] as List).cast<Map<String, dynamic>>();
      final pois = (data['pois'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      double distanceKm(double la1, double ln1, double la2, double ln2) {
        // Approximation plane, suffisante a l'echelle de quelques centaines de
        // metres et sous la latitude de la Corse.
        final dy = (la1 - la2) * 111.0;
        final dx = (ln1 - ln2) * 83.0;
        return math.sqrt(dx * dx + dy * dy);
      }

      final coincidences = <String>[];
      for (final s in stages) {
        final la = (s['endLat'] as num).toDouble();
        final ln = (s['endLng'] as num).toDouble();
        for (final p in pois) {
          final pla = (p['lat'] as num?)?.toDouble();
          final pln = (p['lng'] as num?)?.toDouble();
          if (pla == null || pln == null) continue;
          // 300 m : a l'echelle d'affichage de la carte, deux marqueurs aussi
          // proches se chevauchent.
          if (distanceKm(la, ln, pla, pln) > 0.3) continue;
          coincidences.add('etape ${s['stageNumber']} et '
              '${p['type']} « ${p['nameFr']} »');
        }
      }
      expect(coincidences, isNotEmpty,
          reason: 'aucune coincidence trouvee dans les donnees livrees : la '
              'lecture est cassee, et ce test ne prouverait plus rien');

      // LA CARTE DOIT FUSIONNER CES CAS. Le mecanisme de regroupement existe
      // deja dans le meme dossier (`marker_cluster.dart`) et n'est pas utilise
      // pour cette situation.
      final carte = File('lib/features/trek/presentation/map/map_screen.dart');
      expect(carte.existsSync(), isTrue);
      final src = carte.readAsStringSync();
      final fusionne = src.contains('MarkerCluster') ||
          src.contains('marker_cluster') ||
          src.contains('fusionMarqueurs');
      expect(fusionne, isTrue,
          reason: 'LES MARQUEURS SE SUPERPOSENT : ${coincidences.length} '
              'coincidences a moins de 300 m dans les donnees LIVREES '
              '(${coincidences.join(' ; ')}), et la carte pose deux couches '
              'independantes sans jamais les fusionner. Le numero d etape passe '
              'sous l icone du lieu — exactement le retour 13 de Chris.');
    });
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
