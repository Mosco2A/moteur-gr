import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/app_branding.dart';
import 'package:moteur_gr/shared/widgets/app_logo.dart';

/// TACHE 632 — LES TRACES DE CHRISTOPHE PASSENT-ELLES VRAIMENT DANS FLUTTER ?
///
/// Un SVG qui s'ouvre dans un navigateur ne s'affiche pas forcement dans une
/// application : `flutter_svg` ne comprend qu'un sous-ensemble du format. Ces
/// logos utilisent des pointilles (`stroke-dasharray`), des bouts de trait
/// arrondis et du texte deja converti en courbes — trois choses qu'il faut
/// avoir vues rendre AVANT de decouvrir un cadre vide sur le telephone.
///
/// Les trois familles sont eprouvees, pas seulement celle qui est active : le
/// jour ou Christophe change d'avis, le changement doit etre un geste d'une
/// minute, pas une enquete.
void main() {
  Future<void> montrer(WidgetTester tester, Widget logo) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: logo)),
      ),
    );
    // Le decodage du SVG est asynchrone : sans cette passe, on mesurerait le
    // cadre vide d'avant le rendu et le test passerait pour de mauvaises
    // raisons.
    await tester.pumpAndSettle();
  }

  testWidgets('le picto se rend et tient la taille demandee', (tester) async {
    await montrer(tester, const AppLogo.picto(taille: 64));
    expect(tester.takeException(), isNull);
    final taille = tester.getSize(find.byType(AppLogo));
    expect(taille.width, closeTo(64, 0.01));
    expect(taille.height, closeTo(64, 0.01));
  });

  testWidgets('le logo horizontal garde le rapport du fichier livre', (
    tester,
  ) async {
    await montrer(tester, const AppLogo.horizontal(hauteur: 40));
    expect(tester.takeException(), isNull);
    final taille = tester.getSize(find.byType(AppLogo));
    expect(taille.height, closeTo(40, 0.01));
    // 747.44 / 190 = 3.934...
    expect(taille.width / taille.height, closeTo(3.934, 0.01));
  });

  testWidgets('le logo vertical garde le rapport du fichier livre', (
    tester,
  ) async {
    await montrer(tester, const AppLogo.vertical(largeur: 200));
    expect(tester.takeException(), isNull);
    final taille = tester.getSize(find.byType(AppLogo));
    expect(taille.width, closeTo(200, 0.01));
    // 528.48 / 474.22 = 1.114...
    expect(taille.width / taille.height, closeTo(1.114, 0.01));
  });

  testWidgets('le trace clair est choisi sur un fond sombre', (tester) async {
    // Sur fond sombre il faut le fichier « -clair » : le trace sombre y serait
    // invisible. C'est exactement ce qui se passe au premier ecran, sur le vert
    // #1F3D2B du splash.
    await montrer(
      tester,
      const AppLogo.horizontal(hauteur: 40, surFondSombre: true),
    );
    expect(tester.takeException(), isNull);
    expect(AppBranding.logoHorizontalClair, contains('-clair'));
    expect(AppBranding.logoSurFondSplash, AppBranding.logoHorizontalClair);
  });

  testWidgets('la luminosite du theme decide quand rien n\'est precise', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(body: Center(child: AppLogo.picto(taille: 48))),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('les six traces des trois familles se rendent sans exception', (
    tester,
  ) async {
    for (final famille in ['sentier', 'marches', 'courbes']) {
      for (final forme in [
        'picto',
        'picto-clair',
        'logo-vertical',
        'logo-horizontal',
        'logo-horizontal-clair',
        'icone-app',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                // Directement `SvgPicture`, sans passer par [AppLogo] : on
                // eprouve ici les familles INACTIVES, que [AppBranding] ne
                // designe pas.
                child: SvgPicture.asset(
                  'assets/branding/svg/$famille/$famille-$forme.svg',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$famille-$forme ne se rend pas dans Flutter',
        );
      }
    }
  });
}
