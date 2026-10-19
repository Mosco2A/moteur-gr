// GARDE — TACHE 858 : CE QUE LA FICHE AFFICHE DESORMAIS, ET CE QU'ELLE
// N'AFFICHE PLUS.
//
// DEUX NOMBRES, DEUX NOMS. L'INDICE DE TERRAIN dit ce que le chemin demande ;
// LE TEMPS DE MARCHE dit combien d'heures il prend. Les deux sont a l'ecran,
// sous deux libelles distincts, et aucun des deux ne se deduit de l'autre.
// C'est la decision de Christophe du 18/10/2026 19:32, et c'est la confusion
// que ce lot repare : le compte precedent valait les minutes divisees par
// 13,64.
//
// ET AUCUN MOT DE NIVEAU. Les bandes facile / moyen / difficile / tres
// difficile sont retirees avec le kilometre-effort qui les alimentait. Elles
// reviendront quand Christophe aura donne ses seuils, et pas avant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/features/trail/widgets/indice_du_terrain_affiche.dart';

/// UN SENTIER D'ESSAI DE DIX KILOMETRES, dont la premiere moitie monte 800 m
/// d'un seul tenant et la seconde les redescend doucement.
///
/// Il est fabrique a la main pour que la reponse soit connue : la premiere
/// journee doit etre LA PLUS DURE, et de loin, parce que monter coute et que
/// descendre doucement coute moins que le plat.
ProfilDuTerrain profilDEssai() => ProfilDuTerrain(<SegmentDeProfil>[
  for (var i = 0; i < 20; i++)
    SegmentDeProfil(pkDebutM: i * 250.0, longueurM: 250, deniveleM: 40),
  for (var i = 0; i < 20; i++)
    SegmentDeProfil(pkDebutM: 5000 + i * 250.0, longueurM: 250, deniveleM: -40),
]);

NuitPossible nuit({
  required String nom,
  required double pkKm,
  required int finDEtape,
}) => NuitPossible(
  nom: nom,
  osm: const <String>[],
  pkKm: pkKm,
  altitudeM: 1000,
  lat: 42.0,
  lon: 9.0,
  minutesAller: 0,
  minutesRetour: 0,
  lits: null,
  finDEtape: finDEtape,
);

/// Deux nuits, donc deux segments, donc deux journees possibles.
DecoupageDeNuits nuitsDEssai() => DecoupageDeNuits(
  trailId: 'essai',
  teteDeSentier: 'Depart',
  nuits: <NuitPossible>[
    nuit(nom: 'Le col', pkKm: 5.0, finDEtape: 1),
    nuit(nom: 'La vallee', pkKm: 10.0, finDEtape: 2),
  ],
  segments: const <SegmentEntreNuits>[
    SegmentEntreNuits(
      rang: 1,
      depart: 'Depart',
      arrivee: 'Le col',
      km: 5.0,
      deniveleM: 800,
      descenteM: 0,
      minutes: 195,
    ),
    SegmentEntreNuits(
      rang: 2,
      depart: 'Le col',
      arrivee: 'La vallee',
      km: 5.0,
      deniveleM: 0,
      descenteM: 800,
      minutes: 97,
    ),
  ],
);

Widget bloc({
  ProfilDuTerrain? profil,
  DecoupageDeNuits? nuits,
  List<int> allures = const <int>[1, 2],
  int conseillee = 2,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: IndiceDuTerrainAffiche(
        stages: const [],
        allures: allures,
        allureParDefaut: conseillee,
        profil: profil ?? profilDEssai(),
        nuits: nuits ?? nuitsDEssai(),
      ),
    ),
  ),
);

void main() {
  group('858 — l indice de terrain est a l ecran, en nombre', () {
    testWidgets('LE BLOC PORTE LA NOTE SUR VINGT DE LA PIRE JOURNEE, ET C '
        'EST CELLE QUI MONTE', (tester) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('indice-du-terrain')), findsOneWidget);
      expect(find.text('Difficulte, journee par journee'), findsOneWidget);

      // LA PIRE JOURNEE EST LA MONTEE, ET SON INDICE EST AFFICHE. Le sentier
      // d'essai monte 800 m d'un seul tenant sur ses cinq premiers kilometres.
      final pire = IndiceDuTerrainAffiche(
        stages: const [],
        allures: const <int>[2],
        allureParDefaut: 2,
        profil: profilDEssai(),
        nuits: nuitsDEssai(),
      );
      expect(pire.profil.segments, hasLength(40));

      final ligne = tester.widget<Text>(
        find.byKey(const ValueKey('note-de-la-pire-journee')),
      );
      expect(ligne.data, startsWith('Journee la plus dure : '));
      expect(ligne.data, endsWith(' sur 20'));
      // Une montee de 800 m a 16 % vaut un indice d'environ 24 points, donc
      // une note de l'ordre de quatre a cinq sur vingt : c'est une etape
      // honnete, pas une epreuve mondiale.
      final chiffre = double.parse(
        ligne.data!
            .replaceAll('Journee la plus dure : ', '')
            .replaceAll(' sur 20', '')
            .replaceAll(',', '.'),
      );
      expect(chiffre, greaterThan(0.0));
      expect(chiffre, lessThan(20.0));
    });

    testWidgets('LE TEMPS DE MARCHE EST AFFICHE A PART, SOUS SON PROPRE '
        'NOM', (tester) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      final temps = tester.widget<Text>(
        find.byKey(const ValueKey('temps-de-marche')),
      );
      expect(temps.data, contains('Temps de marche de cette journee'));
      expect(
        temps.data,
        contains('3h15'),
        reason: 'les 195 minutes du segment, par le modele de temps du depot',
      );
      expect(
        temps.data,
        contains('ne s\'en deduit pas'),
        reason: 'l ecran dit que les deux nombres sont independants',
      );
    });

    testWidgets('LES DEUX FAITS SANS ECHELLE SONT A COTE DE LA NOTE : la '
        'montee continue et le kilometrage', (tester) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      final faits = tester.widget<Text>(
        find.byKey(const ValueKey('les-deux-faits')),
      );
      expect(faits.data, contains('une montee de 800 m d\'un seul tenant'));
      expect(faits.data, contains('km de marche'));
      // ET LES QUATRE LECTURES DU PLAN SONT LA, SANS AUCUN TOTAL.
      expect(find.byKey(const ValueKey('lectures-du-plan')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('lecture-nombre-de-jours')),
        findsOneWidget,
      );
      final pasDeNote = tester.widget<Text>(
        find.byKey(const ValueKey('pas-de-note-de-sentier')),
      );
      expect(pasDeNote.data, contains('Un sentier n\'a pas de note'));
    });

    testWidgets('LA REGLE AFFICHEE EST LA REGLE APPLIQUEE', (tester) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      final regle = tester.widget<Text>(
        find.byKey(const ValueKey('regle-de-l-indice')),
      );
      expect(regle.data, LoiDeLIndice.retenue.regleAffichee);
      expect(regle.data, contains('un point vaut un kilometre de plat'));
      expect(regle.data, contains('15 minutes de terrain reposant'));
      expect(regle.data, contains('2,1 fois'));
      // ET CE QUE LA NOTE VEUT DIRE EST DIT, avec la date du corpus.
      final sens = tester.widget<Text>(
        find.byKey(const ValueKey('ce-que-la-note-veut-dire')),
      );
      expect(sens.data, contains('106 etapes officielles'));
      expect(sens.data, contains('19/10/2026'));
      expect(sens.data, contains('six kilometres de plat'));
    });

    testWidgets('CHAQUE ALLURE PORTE SON CHIFFRE, ET SERRER L ALLURE LE FAIT '
        'MONTER', (tester) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      // DEUX ALLURES : une journee (tout d'un trait) ou deux.
      expect(find.byKey(const ValueKey('allure-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('allure-2')), findsOneWidget);
      final aUnJour = tester.widget<Text>(
        find.byKey(const ValueKey('note-de-l-allure-1')),
      );
      final aDeuxJours = tester.widget<Text>(
        find.byKey(const ValueKey('note-de-l-allure-2')),
      );
      final unJour = double.parse(aUnJour.data!.replaceAll(',', '.'));
      final deuxJours = double.parse(aDeuxJours.data!.replaceAll(',', '.'));
      expect(
        unJour,
        greaterThan(deuxJours),
        reason:
            'tout marcher d un trait est plus dur que de couper au col : '
            'c est la valeur d une nuit, et elle se chiffre',
      );
    });

    testWidgets('CHANGER D ALLURE RECALCULE LE CHIFFRE AFFICHE', (
      tester,
    ) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      final avant = tester
          .widget<Text>(find.byKey(const ValueKey('note-de-la-pire-journee')))
          .data;
      await tester.tap(find.byKey(const ValueKey('allure-1')));
      await tester.pumpAndSettle();
      final apres = tester
          .widget<Text>(find.byKey(const ValueKey('note-de-la-pire-journee')))
          .data;
      expect(apres, isNot(avant));
    });

    testWidgets('AUCUN MOT DE NIVEAU N EST AFFICHE (tache 858)', (
      tester,
    ) async {
      await tester.pumpWidget(bloc());
      await tester.pumpAndSettle();

      for (final mot in <String>[
        'Facile',
        'Moyen',
        'Difficile',
        'Tres difficile',
        'Expert',
      ]) {
        expect(
          find.text(mot, skipOffstage: false),
          findsNothing,
          reason: 'le mot « $mot » attend les seuils de Christophe',
        );
      }
      expect(
        find.textContaining('km-effort', skipOffstage: false),
        findsNothing,
      );
    });

    testWidgets('SANS PROFIL, LE BLOC DIT LA MESURE MANQUANTE ET GARDE LE '
        'COMPTE DES JOURNEES', (tester) async {
      await tester.pumpWidget(bloc(profil: ProfilDuTerrain.vide));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('note-de-la-pire-journee')),
        findsNothing,
      );
      expect(find.text('2 journees de marche a cette allure.'), findsOneWidget);
      final manquantes = tester.widget<Text>(
        find.byKey(const ValueKey('mesures-manquantes')),
      );
      expect(manquantes.data, contains('la trace altimetrisee du sentier'));
    });

    testWidgets('SANS JOURNEE DU TOUT, LE BLOC N OCCUPE RIEN', (tester) async {
      await tester.pumpWidget(
        bloc(profil: ProfilDuTerrain.vide, nuits: DecoupageDeNuits.aucun),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('indice-du-terrain')), findsNothing);
      expect(find.text('Difficulte, journee par journee'), findsNothing);
    });
  });
}
