// TACHE 862 — LA RANGEE D'ICONES, ET LA COULEUR N'Y EST JAMAIS SEULE.
//
// CE QUE CE FICHIER GARDE, ET C'EST LA DEUXIEME DES TROIS EXIGENCES DU LOT.
// Un homme sur douze environ ne distingue pas le vert du rouge (8 % des
// hommes, 0,5 % des femmes, deficience rouge-vert). Une application de
// montagne qui cache un danger dans une teinte est une application qui blesse
// quelqu'un. L'information est donc portee TROIS fois :
//   - par la COULEUR, pour le coup d'oeil ;
//   - par le NOMBRE d'icones, pour qui ne distingue pas les teintes — c'est la
//     trouvaille de Christophe, et elle satisfait WCAG 1.4.1 « Use of Color »,
//     de niveau A, sans rien ajouter a l'ecran ;
//   - par un LIBELLE, pour qui ne voit pas l'ecran du tout.
//
// ET LE CONTRASTE EST MESURE ICI, PAS SUPPOSE. WCAG 1.4.11 « Non-text
// Contrast », niveau AA, exige au moins 3:1 contre la couleur adjacente pour
// un objet graphique porteur de sens. Ce fichier recalcule la luminance
// relative de chaque couleur de la palette, sur LES DEUX THEMES, et refuse
// celles qui passent sous le seuil. C'est ce calcul qui a montre que le vert
// et l'orange vifs du theme etaient a 2,2:1 sur fond clair, et que le noir des
// pistes tombait a 1,15:1 sur la carte sombre.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/niveau_des_icones.dart';
import 'package:moteur_gr/features/trail/widgets/icones_de_niveau.dart';

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
  final haut = max(la, lb);
  final bas = min(la, lb);
  return (haut + 0.05) / (bas + 0.05);
}

/// Les fonds reels sur lesquels la rangee est posee, par theme.
const fondClair = Color(0xFFF5F5F5);
const fondSombre = Color(0xFF2C2C2C);

Widget rangee(
  NiveauDIcone niveau, {
  Brightness luminosite = Brightness.light,
}) => MaterialApp(
  theme: ThemeData(brightness: luminosite),
  home: Scaffold(
    body: IconesDeNiveau(
      niveau: niveau,
      glyphe: 'assets/icons/sommet.svg',
      axe: 'Raideur',
      noteLue: '12,8',
      libelle: 'de 100 a 150 m par kilometre',
    ),
  ),
);

void main() {
  group('862 — le NOMBRE d icones porte le niveau', () {
    for (final niveau in NiveauDIcone.values) {
      testWidgets('${niveau.name} dessine ${niveau.nombreDIcones} icone(s)', (
        tester,
      ) async {
        await tester.pumpWidget(rangee(niveau));
        expect(
          find.byType(SvgPicture),
          findsNWidgets(niveau.nombreDIcones),
          reason: '${niveau.name} doit dessiner ${niveau.nombreDIcones}',
        );
      });
    }

    testWidgets('LA RANGEE EXISTE POUR CHAQUE NIVEAU, et le niveau zero ne '
        'dessine rien', (tester) async {
      for (final niveau in NiveauDIcone.values) {
        await tester.pumpWidget(rangee(niveau));
        final boite = tester.widget<SizedBox>(
          find
              .descendant(
                of: find.byType(IconesDeNiveau),
                matching: find.byType(SizedBox),
              )
              .first,
        );
        // LA LARGEUR EST CELLE DE QUATRE ICONES, QUEL QUE SOIT LE NIVEAU :
        // une colonne dont la largeur change d'une ligne a l'autre se
        // parcourt mal.
        expect(boite.width, 4 * 16 + 3 * 4.0, reason: niveau.name);
      }
    });

    testWidgets('LA LARGEUR RESERVEE NE DEPEND PAS DU NIVEAU', (tester) async {
      final largeurs = <double?>{};
      for (final niveau in NiveauDIcone.values) {
        await tester.pumpWidget(rangee(niveau));
        largeurs.add(
          tester
              .widget<SizedBox>(
                find
                    .descendant(
                      of: find.byType(IconesDeNiveau),
                      matching: find.byType(SizedBox),
                    )
                    .first,
              )
              .width,
        );
      }
      expect(largeurs, hasLength(1), reason: 'une seule largeur pour tous');
    });
  });

  group('862 — le LIBELLE porte le niveau pour qui ne voit pas l ecran', () {
    testWidgets('LA RANGEE ANNONCE L AXE, LA NOTE ET LA BANDE', (tester) async {
      final poignee = tester.ensureSemantics();
      await tester.pumpWidget(rangee(NiveauDIcone.deux));
      expect(
        find.bySemanticsLabel(
          'Raideur 12,8 sur 20, de 100 a 150 m par '
          'kilometre',
        ),
        findsOneWidget,
      );
      poignee.dispose();
    });

    testWidgets('LE LIBELLE EST DIT UNE SEULE FOIS, pas une fois par icone', (
      tester,
    ) async {
      final poignee = tester.ensureSemantics();
      await tester.pumpWidget(rangee(NiveauDIcone.quatre));
      expect(find.bySemanticsLabel(RegExp('^Raideur')), findsOneWidget);
      poignee.dispose();
    });
  });

  group('862 — LA COULEUR TIENT WCAG 1.4.11 SUR LES DEUX THEMES', () {
    test('CHAQUE NIVEAU DESSINE EST A AU MOINS 3:1 CONTRE SON FOND', () {
      // On n'exige rien du niveau `aucun` : il ne dessine aucune icone, donc
      // sa couleur n'est jamais peinte.
      final dessines = NiveauDIcone.values
          .where((n) => n.nombreDIcones > 0)
          .toList(growable: false);
      expect(dessines, hasLength(4));
      for (final niveau in dessines) {
        final clair = rapportDeContraste(
          couleurDuNiveau(niveau, Brightness.light),
          fondClair,
        );
        final sombre = rapportDeContraste(
          couleurDuNiveau(niveau, Brightness.dark),
          fondSombre,
        );
        expect(
          clair,
          greaterThanOrEqualTo(3.0),
          reason: '${niveau.name} en theme clair : ${clair.toStringAsFixed(2)}',
        );
        expect(
          sombre,
          greaterThanOrEqualTo(3.0),
          reason:
              '${niveau.name} en theme sombre : ${sombre.toStringAsFixed(2)}',
        );
      }
    });

    test('LE NOIR DES PISTES SERAIT INVISIBLE SUR LA CARTE SOMBRE, et c est '
        'pourquoi la palette sombre existe', () {
      // LA MESURE QUI A IMPOSE DEUX PALETTES. Si un jour quelqu'un unifie les
      // deux, ce test rappelle ce qu'il casserait : le niveau le PLUS ELEVE
      // deviendrait invisible, sur le theme qui est le DEFAUT de
      // l'application.
      const noirDesPistes = Color(0xFF212121);
      expect(rapportDeContraste(noirDesPistes, fondSombre), lessThan(1.3));
      expect(rapportDeContraste(noirDesPistes, fondClair), greaterThan(10));
      // Et la couleur reellement employee en sombre, elle, passe largement.
      expect(
        rapportDeContraste(
          couleurDuNiveau(NiveauDIcone.quatre, Brightness.dark),
          fondSombre,
        ),
        greaterThan(10),
      );
    });

    test('LES TROIS PREMIERES TEINTES NE SE DISTINGUENT PAS PAR LA CLARTE, '
        'et c est le comptage qui les distingue', () {
      // CE N EST PAS UN DEFAUT, C EST LE CONSTAT QUI JUSTIFIE LE COMPTAGE :
      // vert, bleu et rouge des pistes ont des luminances presque egales.
      // Sans le nombre d'icones, une personne qui ne percoit pas les teintes
      // ne pourrait pas les separer du tout.
      final luminances = <double>[
        for (final n in <NiveauDIcone>[
          NiveauDIcone.une,
          NiveauDIcone.deux,
          NiveauDIcone.trois,
        ])
          luminanceRelative(couleurDuNiveau(n, Brightness.light)),
      ];
      for (var i = 1; i < luminances.length; i++) {
        final rapport =
            max(luminances[i], luminances[i - 1]) /
            min(luminances[i], luminances[i - 1]);
        expect(
          rapport,
          lessThan(1.5),
          reason:
              'les teintes voisines sont proches en clarte, donc seul le '
              'comptage les separe',
        );
      }
      // Les nombres d'icones, eux, sont tous differents.
      expect(<int>{
        NiveauDIcone.une.nombreDIcones,
        NiveauDIcone.deux.nombreDIcones,
        NiveauDIcone.trois.nombreDIcones,
        NiveauDIcone.quatre.nombreDIcones,
      }, hasLength(4));
    });

    test('CHAQUE NIVEAU A SA PROPRE COULEUR, sur chaque theme', () {
      for (final luminosite in Brightness.values) {
        final couleurs = <int>{
          for (final n in NiveauDIcone.values)
            if (n.nombreDIcones > 0) couleurDuNiveau(n, luminosite).toARGB32(),
        };
        expect(couleurs, hasLength(4), reason: luminosite.name);
      }
    });
  });
}
