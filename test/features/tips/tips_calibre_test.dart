import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';
import 'package:moteur_gr/features/tips/presentation/tip_points_list.dart';

/// Tests du CALIBRE des fiches conseil (tache 555).
///
/// Retour Chris : « fiches conseil toujours aussi light, voir les fiches GR20
/// que l'on peut recuperer, leur contenu est calibre ». Le calibre de reference,
/// ce sont les fiches FC01-FC25 du GR20 : CINQ points autonomes et chiffres par
/// fiche, pas un paragraphe. Ces tests sont le garde-fou contre un retour a la
/// fiche maigre, et contre la contamination du socle generique par du contenu
/// propre a un sentier (StepWays sert plusieurs sentiers).
void main() {
  /// Les deux assets REELLEMENT charges par l'application (socle + sentier).
  const socleAsset = 'assets/tips/general_tips.json';
  const trailAsset = 'assets/tips/mare_a_mare_tips.json';

  /// Nombre de points attendu par fiche et par langue (calibre GR20).
  const pointsPerCard = 5;

  /// Les cinq langues du produit.
  const langs = <String>['Fr', 'En', 'De', 'It', 'Es'];

  /// Termes propres a un sentier : ils n'ont rien a faire dans le socle commun.
  /// Le contenu corse appartient aux fiches du sentier corse, jamais aux fiches
  /// generiques multi-sentiers.
  const trailSpecificTerms = <String>[
    'GR20',
    'Cirque de la Solitude',
    'Monte Cinto',
    'Cintu',
    'Bavella',
    'Calenzana',
    'Vizzavona',
    'Corse',
    'Corsica',
    'PNRC',
    'brocciu',
    'maquis',
    'Mare a Mare',
    'Laparo',
    'Ghisonaccia',
    'Porticcio',
  ];

  List<Map<String, dynamic>> readRaw(String path) {
    final file = File(path);
    expect(file.existsSync(), isTrue, reason: 'Asset introuvable: $path');
    final decoded = jsonDecode(file.readAsStringSync()) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  List<TipCard> readCards(String path) =>
      readRaw(path).map(TipCard.fromJson).toList();

  List<String> pointsFor(Map<String, dynamic> raw, String lang) =>
      (raw['points$lang'] as List<dynamic>? ?? const <dynamic>[])
          .cast<String>();

  group('Calibre des fiches — 5 points chiffres, 5 langues', () {
    for (final asset in const [socleAsset, trailAsset]) {
      test('$asset : 5 points par fiche dans les 5 langues', () {
        final raws = readRaw(asset);
        expect(raws, isNotEmpty, reason: '$asset ne contient aucune fiche');
        for (final raw in raws) {
          final id = raw['id'];
          for (final lang in langs) {
            final points = pointsFor(raw, lang);
            expect(
              points.length,
              pointsPerCard,
              reason: '$asset/$id: points$lang = ${points.length}, '
                  '$pointsPerCard attendus (calibre GR20)',
            );
            for (var i = 0; i < points.length; i++) {
              expect(
                points[i].trim().length,
                greaterThanOrEqualTo(40),
                reason: '$asset/$id: points$lang[$i] est un moignon, '
                    'pas un point de conseil',
              );
            }
          }
        }
      });

      test('$asset : plus aucun paragraphe unique contentXx', () {
        for (final raw in readRaw(asset)) {
          for (final lang in langs) {
            expect(
              raw.containsKey('content$lang'),
              isFalse,
              reason: '${raw['id']}: content$lang subsiste, la fiche doit '
                  'porter des points',
            );
          }
        }
      });

      test('$asset : toute fiche est au calibre (isAtCalibre)', () {
        for (final card in readCards(asset)) {
          expect(
            card.isAtCalibre,
            isTrue,
            reason: '${card.id} n est pas au calibre '
                '(${card.localizedPoints.length} points)',
          );
        }
      });
    }

    test('le socle reste substantiel (>= 450 caracteres FR par fiche)', () {
      // Garde-fou anti-regression : la mesure d'avant 555 etait de 228
      // caracteres de contenu francais par fiche, un seul paragraphe. Le GR20
      // est a 689. On refuse tout retour vers la fiche maigre.
      final cards = readCards(socleAsset);
      for (final card in cards) {
        final length = card.pointsFr.fold<int>(0, (sum, p) => sum + p.length);
        expect(
          length,
          greaterThanOrEqualTo(450),
          reason: '${card.id}: $length caracteres FR, fiche trop legere',
        );
      }
    });
  });

  group('Etancheite du socle generique', () {
    test('aucun terme propre a un sentier dans le socle', () {
      final blob = File(socleAsset).readAsStringSync().toLowerCase();
      for (final term in trailSpecificTerms) {
        expect(
          blob.contains(term.toLowerCase()),
          isFalse,
          reason: 'Le socle multi-sentiers contient le terme '
              'sentier-specifique "$term" : il appartient aux fiches du '
              'sentier concerne, pas au socle commun',
        );
      }
    });

    test('le socle est integralement scope=all', () {
      for (final card in readCards(socleAsset)) {
        expect(card.scope, 'all', reason: '${card.id}: scope ${card.scope}');
      }
    });

    test('les fiches du sentier portent bien son scope', () {
      for (final card in readCards(trailAsset)) {
        expect(card.scope, 'mare_a_mare', reason: '${card.id}: ${card.scope}');
      }
    });
  });

  group('Modele — points, repli et contenu a plat', () {
    test('localizedPoints rend les points quand ils existent', () {
      const card = TipCard(
        id: 'x',
        titleFr: 'T',
        pointsFr: ['un point assez long pour etre credible', 'un second point'],
      );
      expect(card.localizedPoints.length, 2);
      expect(card.isAtCalibre, isFalse);
    });

    test('localizedPoints se replie sur le paragraphe historique', () {
      // Les fiches non converties (securite_neige, securite_incendie) doivent
      // continuer a s'afficher : un paragraphe devient un point unique.
      const legacy = TipCard(
        id: 'legacy',
        titleFr: 'T',
        contentFr: 'Un paragraphe historique, non converti en points.',
      );
      expect(legacy.localizedPoints, [
        'Un paragraphe historique, non converti en points.',
      ]);
      expect(legacy.localizedContent, contains('paragraphe historique'));
    });

    test('localizedContent joint les points quand il n y a pas de paragraphe',
        () {
      const card = TipCard(
        id: 'x',
        titleFr: 'T',
        pointsFr: ['premier point', 'second point'],
      );
      expect(card.localizedContent, 'premier point\nsecond point');
    });

    test('une fiche sans contenu du tout ne casse pas', () {
      const empty = TipCard(id: 'vide', titleFr: 'T');
      expect(empty.localizedPoints, isEmpty);
      expect(empty.localizedContent, isEmpty);
      expect(empty.isAtCalibre, isFalse);
    });
  });

  group('TipPointsList — rendu en puces', () {
    testWidgets('affiche un texte par point, sans troncature', (tester) async {
      final card = readCards(socleAsset).first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: TipPointsList.fromCard(card: card),
            ),
          ),
        ),
      );
      for (final point in card.pointsFr) {
        expect(find.text(point), findsOneWidget);
      }
      // Aucun point n'est tronque : pas de maxLines pose sur les puces.
      final texts = tester.widgetList<Text>(find.byType(Text));
      for (final text in texts) {
        expect(text.maxLines, isNull, reason: 'puce tronquee: ${text.data}');
      }
    });

    testWidgets('maxPoints limite l apercu sans perdre le reste', (tester) async {
      final card = readCards(socleAsset).first;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TipPointsList.fromCard(card: card, maxPoints: 2),
          ),
        ),
      );
      expect(find.text(card.pointsFr[0]), findsOneWidget);
      expect(find.text(card.pointsFr[1]), findsOneWidget);
      expect(find.text(card.pointsFr[2]), findsNothing);
    });

    testWidgets('une liste vide ne rend rien', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: TipPointsList(points: <String>[])),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });
}
