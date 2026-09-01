import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/a11y/wcag_contrast.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/core/theme/skin_theme.dart';
import 'package:moteur_gr/shared/widgets/app_gradient_header.dart';

/// Tests widget d'AppGradientHeader (SW-SKIN-L5).
///
/// Couvre : le calcul de contraste (couleur de texte selon la luminance du fond,
/// plusieurs accents clairs/foncés), le rendu du titre/sous-titre/trailing/child,
/// et les 3 traitements de peau (gradient / topoFilet / photo-fallback).
void main() {
  // Accents de test : un fonce (vert sentier) et un tres clair (jaune pale) —
  // le cas critique du garde-fou de contraste (§1.6).
  const darkAccent = Color(0xFF2E7D32); // vert Pyrenees
  const lightAccent = Color(0xFFFFF176); // jaune pale (blanc illisible dessus)
  const midAccent = Color(0xFF1565C0); // bleu soutenu

  group('resolveHeaderTextTreatment (garde-fou contraste §1.6)', () {
    test('accent fonce -> texte BLANC, degrade tel quel', () {
      final t = resolveHeaderTextTreatment(
        headerStyle: SkinHeaderStyle.gradient,
        primary: darkAccent,
        paperSurface: AppTheme.blancNeige,
      );
      expect(t.textColor, Colors.white);
      expect(t.gradient, isA<LinearGradient>());
      final grad = t.gradient! as LinearGradient;
      // Extremite claire = lighten(primary) : le blanc y tient l'AA.
      expect(WcagContrast.meetsAA(Colors.white, grad.colors.first), isTrue);
      expect(WcagContrast.meetsAA(Colors.white, grad.colors.last), isTrue);
    });

    test('accent tres clair -> degrade ASSOMBRI pour garder le blanc lisible',
        () {
      final t = resolveHeaderTextTreatment(
        headerStyle: SkinHeaderStyle.gradient,
        primary: lightAccent,
        paperSurface: AppTheme.blancNeige,
      );
      final grad = t.gradient! as LinearGradient;
      // Le texte reste lisible (AA) sur les DEUX extremites du degrade final,
      // quelle que soit la couleur choisie (blanc apres assombrissement, ou
      // encre en repli). C'est la garantie du §1.6.
      expect(WcagContrast.meetsAA(t.textColor, grad.colors.first), isTrue);
      expect(WcagContrast.meetsAA(t.textColor, grad.colors.last), isTrue);
    });

    test('accent moyen -> contraste AA garanti sur tout le degrade', () {
      final t = resolveHeaderTextTreatment(
        headerStyle: SkinHeaderStyle.gradient,
        primary: midAccent,
        paperSurface: AppTheme.blancNeige,
      );
      final grad = t.gradient! as LinearGradient;
      expect(WcagContrast.meetsAA(t.textColor, grad.colors.first), isTrue);
      expect(WcagContrast.meetsAA(t.textColor, grad.colors.last), isTrue);
    });

    test('mode papier (topoFilet) -> fond surface, pas de degrade, AA garanti',
        () {
      final t = resolveHeaderTextTreatment(
        headerStyle: SkinHeaderStyle.topoFilet,
        primary: darkAccent,
        paperSurface: const Color(0xFFF4F1EA), // papier topo
      );
      expect(t.gradient, isNull);
      expect(t.solidBackground, const Color(0xFFF4F1EA));
      // Sur papier clair -> encre, contraste AA.
      expect(WcagContrast.meetsAA(t.textColor, t.solidBackground!), isTrue);
    });

    test('mode photo sans image -> FALLBACK degrade (jamais de trou)', () {
      final t = resolveHeaderTextTreatment(
        headerStyle: SkinHeaderStyle.photo,
        primary: darkAccent,
        paperSurface: AppTheme.blancNeige,
      );
      expect(t.gradient, isA<LinearGradient>());
      expect(t.solidBackground, isNull);
    });
  });

  group('AppGradientHeader rendu', () {
    Widget wrap({
      required AppSkin skin,
      Color primary = darkAccent,
      required Widget child,
    }) {
      return MaterialApp(
        theme: AppTheme.buildLightTheme(
          primaryColor: primary,
          secondaryColor: const Color(0xFF1565C0),
          skin: skin,
        ),
        home: Scaffold(body: child),
      );
    }

    testWidgets('affiche titre + sous-titre + trailing + child', (tester) async {
      await tester.pumpWidget(
        wrap(
          skin: AppSkin.sentierVivant,
          child: const AppGradientHeader(
            title: 'Refuge Arremoulit',
            subtitle: 'GR20',
            trailing: Icon(Icons.flag),
            child: Text('contenu-enfant'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Refuge Arremoulit'), findsOneWidget);
      expect(find.text('GR20'), findsOneWidget);
      expect(find.byIcon(Icons.flag), findsOneWidget);
      expect(find.text('contenu-enfant'), findsOneWidget);
      // Le fond degrade est peint (DecoratedBox avec gradient).
      expect(
        find.byWidgetPredicate((w) =>
            w is DecoratedBox &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient != null),
        findsWidgets,
      );
    });

    testWidgets('titre en BLANC sur accent fonce (contraste)', (tester) async {
      await tester.pumpWidget(
        wrap(
          skin: AppSkin.sentierVivant,
          child: const AppGradientHeader(title: 'Titre'),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Titre'));
      expect(textWidget.style?.color, Colors.white);
    });

    testWidgets('peau topographique -> filet bas + fond papier (pas de gradient)',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          skin: AppSkin.topographique,
          child: const AppGradientHeader(title: 'Titre topo'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Titre topo'), findsOneWidget);
      // En mode papier, aucun DecoratedBox du header ne porte de gradient.
      final gradientBoxes = find.byWidgetPredicate((w) =>
          w is DecoratedBox &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).gradient != null);
      expect(gradientBoxes, findsNothing);
    });
  });
}
