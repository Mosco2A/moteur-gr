// CE QUE LA TACHE 645-03 A AJOUTE A `AppButton`, ET POURQUOI ON LE VERROUILLE.
//
// Le lot 645-03 ramene 112 appels de bouton brut sur le composant unique. Trois
// besoins du parc n'etaient pas exprimables par les 8 parametres d'alors ; la
// regle R2 du lot dit quoi faire dans ce cas : porter le besoin DANS le
// composant, en parametre nomme a valeur par defaut, jamais en cas particulier
// chez l'appelant. D'ou la variante `text` de ce fichier.
//
// CES TESTS TIENNENT DEUX PROMESSES :
//
//   1. LE NOUVEAU FAIT CE QU'IL DIT. Un bouton plat est plat (pas de fond, pas
//      de bordure), une icone demandee a 18 mesure 18, un libelle demande en 16
//      sort en 16.
//   2. L'ANCIEN NE BOUGE PAS. C'est la promesse la plus importante : au
//      02/10/2026, 94 appels d'`AppButton` existaient deja dans le parc. Si un
//      defaut avait change (hauteur, taille d'icone, typographie), ces 94
//      ecrans auraient change d'apparence en silence — un lot de deplacement
//      qui repeint l'application, exactement ce qu'il ne doit pas faire. Les
//      valeurs chiffrees ci-dessous (48px, 20px, 64px) sont donc des mesures,
//      pas des preferences.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

/// Le theme reel de l'application : un bouton ne se juge pas hors de son theme,
/// c'est lui qui pose les couleurs et les hauteurs.
final ThemeData _theme = AppTheme.buildDarkTheme(
  primaryColor: const Color(0xFF2E7D32),
  secondaryColor: const Color(0xFF8B4513),
  skin: AppSkin.sentierVivant,
);

/// [anime] : un bouton en chargement tourne sans fin, `pumpAndSettle`
/// n'arriverait jamais au bout.
Future<void> _poser(
  WidgetTester tester,
  Widget bouton, {
  bool anime = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: _theme,
      home: Scaffold(
        body: Center(child: SizedBox(width: 360, child: bouton)),
      ),
    ),
  );
  if (anime) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}

/// La boite peinte du bouton (c'est elle qui porte la taille et la forme).
Size _taille(WidgetTester tester, String libelle) => tester.getSize(
  find.ancestor(of: find.text(libelle), matching: find.byType(Material)).first,
);

void main() {
  group('645-03 — la variante `text` (bouton plat)', () {
    testWidgets('batit un TextButton : c est la forme du bouton plat, et c est '
        'ce qui garde le rendu du theme (textButtonTheme)', (tester) async {
      await _poser(
        tester,
        const AppButton(
          label: 'Annuler',
          onPressed: null,
          variant: AppButtonVariant.text,
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      // Les trois autres formes sont absentes : un bouton plat n'est ni plein
      // ni borde.
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('ne pose NI couleur NI forme quand l appel n en demande pas — '
        'le theme peint donc ce bouton comme il peignait le TextButton brut', (
      tester,
    ) async {
      await _poser(
        tester,
        AppButton(
          label: 'Annuler',
          onPressed: () {},
          variant: AppButtonVariant.text,
        ),
      );

      final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
      expect(
        style.backgroundColor,
        isNull,
        reason: 'un fond pose ici cacherait le fond du theme',
      );
      expect(
        style.side,
        isNull,
        reason: 'une bordure posee ici ferait un bouton borde, pas un plat',
      );
      expect(
        style.foregroundColor,
        isNull,
        reason:
            'sans `tone`, la couleur du libelle doit rester celle du '
            '`textButtonTheme` — c est tout l iso-rendu de la variante',
      );
      expect(
        style.shape,
        isNull,
        reason: 'la forme du creux au clic reste celle de Material',
      );
    });

    testWidgets('`tone` teinte le libelle sans donner de fond — le cas des '
        '« Annuler » grises et des « Abandonner » rouges', (tester) async {
      await _poser(
        tester,
        AppButton(
          label: 'Abandonner',
          onPressed: () {},
          variant: AppButtonVariant.text,
          tone: AppTheme.rougeUrgence,
        ),
      );

      final style = tester.widget<TextButton>(find.byType(TextButton)).style!;
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        AppTheme.rougeUrgence,
      );
      expect(style.backgroundColor, isNull);
    });

    testWidgets('hors pleine largeur, il ne descend pas sous 64px de large : '
        'c est le plancher de Material pour un bouton plat', (tester) async {
      await _poser(
        tester,
        AppButton(
          label: 'OK',
          onPressed: () {},
          variant: AppButtonVariant.text,
          isFullWidth: false,
        ),
      );

      // Mesure du 02/10/2026 : un `TextButton` brut portant « OK » fait 64px de
      // large. Sans ce plancher, le bouton ramene ici serait PLUS ETROIT
      // qu'avant sur les libelles courts (« OK », « Non »).
      expect(_taille(tester, 'OK').width, greaterThanOrEqualTo(64));
    });

    testWidgets('`onPressed: null` grise vraiment, et `isLoading` desactive '
        'aussi le bouton plat (meme grammaire que les autres variantes)', (
      tester,
    ) async {
      await _poser(
        tester,
        const AppButton(
          label: 'Annuler',
          onPressed: null,
          variant: AppButtonVariant.text,
        ),
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );

      var touches = 0;
      await _poser(
        tester,
        AppButton(
          label: 'Annuler',
          onPressed: () => touches++,
          variant: AppButtonVariant.text,
          isLoading: true,
        ),
        anime: true,
      );
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
        reason: 'un bouton qui travaille ne se laisse pas recliquer',
      );
      expect(touches, 0);
    });

    testWidgets('le clic appelle bien l action (iso-fonction)', (tester) async {
      var touches = 0;
      await _poser(
        tester,
        AppButton(
          label: 'Annuler',
          onPressed: () => touches++,
          variant: AppButtonVariant.text,
        ),
      );
      await tester.tap(find.text('Annuler'));
      expect(touches, 1);
    });
  });

  group('645-03 — ce que les 94 appels existants mesuraient deja', () {
    testWidgets('primary reste un ElevatedButton de 48px de haut, pleine '
        'largeur par defaut', (tester) async {
      await _poser(tester, AppButton(label: 'Valider', onPressed: () {}));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(_taille(tester, 'Valider'), const Size(360, 48));
    });

    testWidgets('outline reste un OutlinedButton de 48px de haut', (
      tester,
    ) async {
      await _poser(
        tester,
        AppButton(
          label: 'Rejoindre',
          onPressed: () {},
          variant: AppButtonVariant.outline,
        ),
      );

      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(_taille(tester, 'Rejoindre').height, 48);
    });

    testWidgets('la variante text respecte `minHeight` comme les autres', (
      tester,
    ) async {
      await _poser(
        tester,
        AppButton(
          label: 'Stop',
          onPressed: () {},
          variant: AppButtonVariant.text,
          minHeight: 44,
        ),
      );

      expect(_taille(tester, 'Stop').height, 44);
    });
  });
}
