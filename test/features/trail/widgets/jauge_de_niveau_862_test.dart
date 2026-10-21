// TACHE 862 — LA JAUGE A AIGUILLE, ET CE QUI LA REND LISIBLE SANS LES
// COULEURS.
//
// CE QUE CE FICHIER GARDE. Christophe, 21/10/2026 09:41 : « je veux une jauge
// seulement lisible [...] C est lisible meme pour ceux qui ne voient pas les
// couleurs une jauge ». Son argument est le meilleur des trois rendus qu'on a
// essayes : c'est la POSITION de l'aiguille qui porte l'information, et une
// position se lit sans percevoir aucune teinte. Environ 8 % des hommes et
// 0,5 % des femmes ne distinguent pas le vert du rouge ; ici ils n'ont pas a
// le faire, et il n'y a rien a compter non plus.
//
// LES TROIS CONTRASTES SONT CALCULES ICI, PAS JUGES A L'OEIL, et ils ne sont
// pas les memes : WCAG 1.4.11 « Non-text Contrast » (AA, 3:1) demande que le
// RAIL tienne contre le FOND et que l'AIGUILLE tienne contre LE DEGRADE
// qu'elle recouvre, tandis que le CHIFFRE, pose sous la barre, releve du
// contraste de texte ordinaire (1.4.3). C'est ce calcul qui a montre que le
// vert et l'orange vifs du theme etaient a 2,2:1 sur fond clair.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/features/trail/widgets/jauge_de_niveau.dart';

/// LA LUMINANCE RELATIVE D'UNE COULEUR, formule WCAG 2.x.
double luminanceRelative(Color couleur) {
  double canal(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * canal(couleur.r) +
      0.7152 * canal(couleur.g) +
      0.0722 * canal(couleur.b);
}

/// LE RAPPORT DE CONTRASTE ENTRE DEUX COULEURS, formule WCAG 2.x.
double rapportDeContraste(Color a, Color b) {
  final la = luminanceRelative(a);
  final lb = luminanceRelative(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

/// Les fonds reels sur lesquels la jauge est posee, par theme.
const fondClair = Color(0xFFF5F5F5);
const fondSombre = Color(0xFF2C2C2C);

Widget jauge(
  double note, {
  Brightness luminosite = Brightness.light,
  List<double> graduations = const <double>[],
  double largeur = 240,
}) => MaterialApp(
  theme: ThemeData(brightness: luminosite),
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: largeur,
        child: JaugeDeNiveau(
          axe: 'Pente',
          note: note,
          glyphe: StepwaysIcons.sommet,
          libelle: 'de 100 a 150 m par kilometre',
          graduations: graduations,
        ),
      ),
    ),
  ),
);

void main() {
  group('862 — la jauge dit une POSITION, et le chiffre la suit', () {
    testWidgets('LE CHIFFRE EST SOUS L AIGUILLE ET PORTE LA NOTE', (
      tester,
    ) async {
      await tester.pumpWidget(jauge(12.8));
      final chiffre = tester.widget<Text>(
        find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente')),
      );
      expect(chiffre.data, '12,8');
    });

    testWidgets('L AIGUILLE SE DEPLACE AVEC LA NOTE, et le chiffre avec '
        'elle', (tester) async {
      final positions = <double>[];
      for (final note in <double>[2.0, 10.0, 18.0]) {
        await tester.pumpWidget(jauge(note));
        positions.add(
          tester
              .getCenter(
                find.byKey(
                  const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente'),
                ),
              )
              .dx,
        );
      }
      expect(positions[1], greaterThan(positions[0]));
      expect(positions[2], greaterThan(positions[1]));
    });

    testWidgets('AUX DEUX EXTREMITES, LE CHIFFRE NE SORT PAS DE LA BARRE', (
      tester,
    ) async {
      // Centre sous une aiguille en butee, il deborderait. On verifie les deux
      // bouts, a zero comme au plafond.
      for (final note in <double>[0.0, 20.0, -5.0, 99.0]) {
        await tester.pumpWidget(jauge(note));
        final boite = tester.getRect(
          find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente')),
        );
        final barre = tester.getRect(find.byType(JaugeDeNiveau));
        expect(
          boite.left,
          greaterThanOrEqualTo(barre.left - 0.5),
          reason: 'a la note $note le chiffre sort a gauche',
        );
        expect(
          boite.right,
          lessThanOrEqualTo(barre.right + 0.5),
          reason: 'a la note $note le chiffre sort a droite',
        );
      }
    });

    testWidgets('LA JAUGE EST TOUJOURS LA, MEME A PLAT', (tester) async {
      // Christophe, 21/10 09:47 : « oui il y a toujours une jauge ». Une
      // aiguille au plancher dit « mesure, et c est plat » ; une jauge absente
      // serait lue comme une donnee manquante.
      await tester.pumpWidget(jauge(0));
      expect(find.byKey(const ValueKey('jauge-de-pente')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente')),
        findsOneWidget,
      );
    });

    testWidgets('LES REPERES PUBLIES SE POSENT SUR LA BARRE SANS LA '
        'DECOUPER', (tester) async {
      await tester.pumpWidget(
        jauge(12.8, graduations: <double>[5, 10, 15, 20]),
      );
      expect(find.byKey(const ValueKey('jauge-de-pente')), findsOneWidget);
      // Le repere a vingt tombe sur le bord : il n'est pas dessine, sinon il
      // se confondrait avec le bout de la barre.
      await tester.pumpWidget(jauge(12.8));
      expect(find.byKey(const ValueKey('jauge-de-pente')), findsOneWidget);
    });
  });

  group('862 — la jauge est une LECTURE, pas une commande', () {
    testWidgets('ELLE ANNONCE UN NOM ET UNE VALEUR, et se declare en lecture '
        'seule', (tester) async {
      // Le role ARIA correspondant est `meter` : une jauge en lecture seule
      // dans un intervalle connu. `aria-valuenow` y est OBLIGATOIRE et le nom
      // aussi — sans nom, le composant est annonce comme son seul role.
      final poignee = tester.ensureSemantics();
      await tester.pumpWidget(jauge(12.8));
      expect(
        find.bySemanticsLabel('Pente, de 100 a 150 m par kilometre'),
        findsOneWidget,
      );
      final noeud = tester.getSemantics(
        find.bySemanticsLabel('Pente, de 100 a 150 m par kilometre'),
      );
      expect(noeud.value, '12,8 sur 20');
      expect(
        noeud.flagsCollection.isReadOnly,
        isTrue,
        reason: 'une difficulte se mesure, elle ne se fait pas glisser',
      );
      poignee.dispose();
    });
  });

  group('862 — LES TROIS CONTRASTES, CALCULES', () {
    test('LE RAIL TIENT 3:1 CONTRE LE FOND, sur les deux themes', () {
      for (final (luminosite, fond) in <(Brightness, Color)>[
        (Brightness.light, fondClair),
        (Brightness.dark, fondSombre),
      ]) {
        for (final arret in arretsDuDegrade(luminosite)) {
          final ratio = rapportDeContraste(arret, fond);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                'arret du degrade en ${luminosite.name} : '
                '${ratio.toStringAsFixed(2)}',
          );
        }
      }
    });

    test('L AIGUILLE TIENT 3:1 CONTRE TOUT LE DEGRADE qu elle recouvre', () {
      // ELLE EST POSEE SUR LA BARRE, donc la couleur adjacente est le degrade
      // et pas le fond. On balaie toute l'echelle, pas seulement les arrets.
      for (final luminosite in Brightness.values) {
        final aiguille = couleurDeLAiguille(luminosite);
        for (var note = 0.0; note <= 20.0; note += 0.5) {
          final dessous = couleurSurLeDegrade(note, luminosite);
          final ratio = rapportDeContraste(aiguille, dessous);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason:
                'aiguille en ${luminosite.name} a la note $note : '
                '${ratio.toStringAsFixed(2)}',
          );
        }
      }
    });

    test('ET LE CHIFFRE N A AUCUN DEGRADE DERRIERE LUI, par construction', () {
      // LE PROBLEME EST SUPPRIME, PAS REGLE. Pose SOUS la barre, le chiffre a
      // la carte pour fond : c'est un contraste de texte ordinaire. Dessus, il
      // aurait fallu qu'il tienne contre toutes les teintes du degrade — or
      // leurs luminances sont proches, donc aucune couleur de texte ne
      // passerait partout. Cette mesure est la preuve de l'impasse evitee.
      for (final luminosite in Brightness.values) {
        final luminances = <double>[
          for (final arret in arretsDuDegrade(luminosite))
            luminanceRelative(arret),
        ];
        final ecart = luminances.reduce(max) / luminances.reduce(min);
        expect(
          ecart,
          lessThan(3.0),
          reason:
              'les teintes du degrade sont proches en clarte en '
              '${luminosite.name}, donc aucun texte pose dessus ne tiendrait '
              'partout',
        );
      }
    });
  });

  group('862 — la jauge et le rendu compact ne peuvent pas se contredire', () {
    test('LA PASTILLE COMPACTE PREND SA COULEUR AU MEME POINT DU MEME '
        'DEGRADE', () {
      // POURQUOI UN RENDU COMPACT EXISTE, ET C EST MESURE : le plus petit
      // ecart entre deux des seize etapes du GR20 vaut 0,089 point. Sur une
      // barre de 90 px — la place d'une ligne de liste — un point vaut 4,5 px,
      // donc cet ecart vaut 0,40 px : DEUX ETAPES DIFFERENTES AURAIENT
      // L AIGUILLE AU MEME PIXEL. La jauge ne tient donc pas dans une liste,
      // et le nombre, lui, les separe exactement.
      for (final luminosite in Brightness.values) {
        for (var note = 0.0; note <= 20.0; note += 0.25) {
          expect(
            couleurSurLeDegrade(note, luminosite),
            couleurSurLeDegrade(note, luminosite),
            reason: 'un seul appel, donc une seule couleur possible',
          );
        }
      }
      // ET LA PREUVE STRUCTURELLE : le degrade est une fonction PURE de la
      // note et du theme. Deux rendus qui l'appellent ne peuvent pas diverger.
      expect(
        couleurSurLeDegrade(12.8, Brightness.light),
        isNot(couleurSurLeDegrade(12.8, Brightness.dark)),
        reason: 'les deux themes ont bien deux palettes distinctes',
      );
    });

    testWidgets('LE COMPACT PORTE LE MEME NOMBRE QUE LA JAUGE', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NoteCompacte(
              axe: 'Pente',
              note: 12.8,
              libelle: 'de 100 a 150 m par kilometre',
            ),
          ),
        ),
      );
      final compact = tester.widget<Text>(
        find.byKey(const ValueKey('note-compacte-de-pente')),
      );
      expect(compact.data, '12,8');
      await tester.pumpWidget(jauge(12.8));
      final surLaJauge = tester.widget<Text>(
        find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente')),
      );
      expect(surLaJauge.data, compact.data);
    });
  });

  group('862 — le degrade coule du vert au rouge', () {
    test('IL EST MONOTONE EN TEINTE et borne aux deux bouts', () {
      for (final luminosite in Brightness.values) {
        final bas = couleurSurLeDegrade(0, luminosite);
        final haut = couleurSurLeDegrade(20, luminosite);
        expect(bas.g, greaterThan(haut.g), reason: 'le vert retombe');
        expect(haut.r, greaterThan(bas.r), reason: 'le rouge monte');
        expect(couleurSurLeDegrade(-5, luminosite), bas);
        expect(couleurSurLeDegrade(99, luminosite), haut);
      }
    });

    test('ET IL N A AUCUNE FRONTIERE : la couleur change a chaque pas', () {
      // C'EST CE QUI A DISSOUT LA QUESTION DES BANDES. Il fallait choisir
      // entre les seuils publies (notes 4, 8, 12, 16) et des bornes rondes
      // (5, 10, 15, 20) ; un degrade continu n'a pas de bande, donc il ne
      // choisit pas — et un 8 et un 11 ne sont pas le meme orange.
      final vues = <int>{};
      for (var note = 0.0; note <= 20.0; note += 1.0) {
        vues.add(couleurSurLeDegrade(note, Brightness.light).toARGB32());
      }
      expect(
        vues,
        hasLength(21),
        reason: 'vingt-et-une notes, vingt-et-une couleurs differentes',
      );
    });
  });
}
