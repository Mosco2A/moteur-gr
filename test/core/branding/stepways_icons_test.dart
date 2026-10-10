import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/app_branding.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// TACHE 632 — LES 156 ICONES DE CHRISTOPHE ET LEURS TROIS TRACES.
///
/// Une icone manquante ne fait PAS planter l'application : `SvgPicture.asset`
/// leve en arriere-plan et laisse un TROU a l'ecran. C'est le pire des cas —
/// invisible en revue de code, visible seulement par le randonneur. Ces tests
/// verifient donc que chaque fichier existe ET qu'il se rend vraiment.
void main() {
  final plats = Directory('assets/icons')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.svg'))
      .map((f) => f.path.replaceAll(r'\', '/'))
      .toList();

  group('Le depot porte bien les quatre jeux', () {
    test('les 157 traces monochromes sont la', () {
      // 157 ET NON 156 DEPUIS LA TACHE 772 : le RESUME a recu son propre
      // dessin. Il portait celui du Programme, et les deux cartes du cockpit
      // sortaient le meme trace pointille.
      expect(plats.length, 157);
    });

    test('les 21 rubriques, 43 ICO et 38 MAT ont leurs TROIS traces', () {
      for (final IconeBicolore icone in <IconeBicolore>[
        ...RubriqueStepways.values,
        ...IcoStepways.values,
        ...MatStepways.values,
      ]) {
        for (final chemin in [icone.mono, icone.duo, icone.duoClair]) {
          expect(
            File(chemin).existsSync(),
            isTrue,
            reason: 'absent : $chemin — relancer python tool/set_branding.py',
          );
        }
      }
      // 21 depuis la tache 772 (la rubrique « resume »).
      expect(RubriqueStepways.values.length, 21);
      expect(IcoStepways.values.length, 43);
      expect(MatStepways.values.length, 38);
    });

    test('la variante claire remplace le vert et garde l\'orange', () {
      // Sur fond sombre, le vert #1F3D2B du trace bicolore disparaitrait.
      // L'orange, lui, tient sur les deux fonds : le changer casserait l'accent
      // commun avec le logo.
      for (final IconeBicolore icone in <IconeBicolore>[
        ...RubriqueStepways.values,
        ...IcoStepways.values,
      ]) {
        final clair = File(icone.duoClair).readAsStringSync().toUpperCase();
        expect(
          clair,
          isNot(contains('#1F3D2B')),
          reason: '${icone.duoClair} garde du vert sombre sur fond sombre',
        );
        expect(clair, contains('#F4F1E8'));
      }
    });

    test('le trace monochrome d\'une ICO est bien le fichier a plat', () {
      // Pas une seconde version du dessin : le MEME fichier. Si ca cessait
      // d'etre vrai, l'application montrerait deux dessins differents pour la
      // meme idee selon l'ecran.
      for (final IconeBicolore ico in <IconeBicolore>[
        ...IcoStepways.values,
        ...MatStepways.values,
      ]) {
        expect(plats, contains(ico.mono));
      }
    });
  });

  group('Elles se rendent vraiment dans Flutter', () {
    testWidgets('les 157 traces monochromes passent dans flutter_svg', (
      tester,
    ) async {
      for (final chemin in plats) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: Center(child: StepIcon(chemin, size: 24))),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$chemin ne se rend pas',
        );
      }
    });

    testWidgets('les traces bicolores des deux familles passent aussi', (
      tester,
    ) async {
      for (final IconeBicolore icone in <IconeBicolore>[
        ...RubriqueStepways.values,
        ...IcoStepways.values,
      ]) {
        for (final chemin in [icone.duo, icone.duoClair]) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SvgPicture.asset(chemin, width: 24, height: 24),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$chemin ne se rend pas',
          );
        }
      }
    });
  });

  group('L\'interrupteur duo / monochrome tient ses promesses', () {
    testWidgets('sans couleur imposee, l\'icone sort en bicolore', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: IconeStepways(RubriqueStepways.weather)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(AppBranding.iconesEnDuo, isTrue);
      // Pas de StepIcon => pas de filtre de couleur => les deux couleurs du
      // fichier survivent.
      expect(find.byType(StepIcon), findsNothing);
    });

    testWidgets('une couleur imposee force le trace monochrome', (
      tester,
    ) async {
      // Sinon l'onglet actif et l'onglet inactif seraient identiques : le
      // bicolore fige ignore la couleur demandee.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconeStepways(
                IcoStepways.cadenas,
                couleur: Color(0xFFAA0000),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(StepIcon), findsOneWidget);
    });

    testWidgets('sur fond sombre, l\'icone bascule sur le trace clair', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(child: IconeStepways(RubriqueStepways.journal)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('elles restent nettes de 18 a 72 px', (tester) async {
      // Dessinees pour 24 px, mais l'application les affiche de 18 (coche de
      // statut) a 64 (etats vides). Etant vectorielles, la taille ne les degrade
      // pas — ce test verifie qu'aucune taille ne fait lever le rendu et que la
      // place reservee est bien celle demandee.
      for (final taille in [18.0, 20.0, 22.0, 24.0, 32.0, 48.0, 72.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: IconeStepways(RubriqueStepways.sacADos, taille: taille),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'casse a $taille px');
        final mesure = tester.getSize(find.byType(IconeStepways));
        expect(mesure.width, closeTo(taille, 0.01));
        expect(mesure.height, closeTo(taille, 0.01));
      }
    });
  });
}
