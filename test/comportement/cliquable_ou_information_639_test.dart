import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

/// TACHE 639 — BUG 4 : CE QUI EST CLIQUABLE NE SE DESSINE PLUS COMME CE QUI NE
/// L'EST PAS.
///
/// LE RETOUR DE CHRISTOPHE, MOT POUR MOT (30/09 10:10, telephone, build 0.1.3
/// (7)) : « pret a partir on ne dirait pas une info mais un bouton, il faut
/// differencier visuellement ce qui est clicable de ce qui ne l est pas ».
///
/// CE QUI ETAIT MESURE. Sur les 124 [AppCard] de `lib/`, SEIZE portent un geste
/// et CENT HUIT n'en portent aucun — et les 124 se dessinaient a l'identique :
/// fond plein, ombre portee, rayon 8. Cent huit blocs d'information avaient le
/// relief d'un bouton. La correction ne pouvait pas etre locale : « Pret a
/// partir » n'etait qu'un exemplaire sur cent huit.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. la regle vit dans la BRIQUE : geste -> relief, pas de geste -> a plat ;
///   2. ce que l'appelant impose pour du SENS (fond d'alerte, liseré rouge,
///      carte flottante) n'est pas ecrase par la regle ;
///   3. aucune fleche « il y a quelque chose derriere » ne subsiste sur un
///      element qui ne repond a rien — la faute symetrique, verifiee sur la
///      source de tout `lib/`.
void main() {
  BoxDecoration decorationDe(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppCard),
            matching: find.byType(Container),
            matchRoot: true,
          )
          .first,
    );
    return container.decoration as BoxDecoration;
  }

  Future<void> poser(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: card)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('la regle vit dans la brique', () {
    testWidgets('une carte SANS geste est a plat, et delimitee', (
      tester,
    ) async {
      await poser(tester, const AppCard(child: Text('Pret a partir ?')));
      final deco = decorationDe(tester);
      expect(
        deco.boxShadow,
        isNull,
        reason:
            'une information ne se souleve pas : c est ce que Christophe a '
            'pris pour un bouton',
      );
      expect(
        deco.border,
        isNotNull,
        reason: 'sans ombre, il faut un liseré pour que le bloc se lise encore',
      );
      // LE LISERE NE DEPLACE RIEN. Un `Border` ordinaire compte dans la taille
      // (BoxDecoration.padding = epaisseur du trait) : sur 108 cartes, deux
      // points par carte avaient suffi a pousser la derniere carte de la
      // selection de sentier hors de la fenetre de test, et le test est tombe.
      expect(
        (deco.border! as Border).top.strokeAlign,
        BorderSide.strokeAlignOutside,
        reason: 'un liseré qui compte dans la taille decale toute la page',
      );
      expect(
        deco.padding,
        anyOf(isNull, EdgeInsets.zero),
        reason: 'la mise en page doit etre RIGOUREUSEMENT celle d avant',
      );
    });

    testWidgets('une carte AVEC onTap est en relief', (tester) async {
      await poser(
        tester,
        AppCard(onTap: () {}, child: const Text('Recharger')),
      );
      final deco = decorationDe(tester);
      expect(deco.boxShadow, isNotNull);
      expect(deco.boxShadow!.single.offset.dy, 2);
      expect(
        deco.border,
        isNull,
        reason:
            'le relief suffit : liseré ET ombre feraient un troisieme '
            'langage',
      );
    });

    testWidgets('une carte dont le geste est DECLARE est en relief aussi', (
      tester,
    ) async {
      // Les huit cartes de l'application dont le geste est pose a l'interieur
      // (InkWell / ListTile enfant) : sans cette declaration elles auraient ete
      // dessinees comme des informations alors qu'elles repondent a l'appui.
      await poser(
        tester,
        AppCard(
          interactif: true,
          child: InkWell(onTap: () {}, child: const Text('Compte-etapes')),
        ),
      );
      expect(decorationDe(tester).boxShadow, isNotNull);
    });

    testWidgets('les deux fonds sont DIFFERENTS, pas seulement l ombre', (
      tester,
    ) async {
      await poser(tester, const AppCard(child: Text('info')));
      final fondInfo = decorationDe(tester).color;
      await poser(tester, AppCard(onTap: () {}, child: const Text('action')));
      final fondAction = decorationDe(tester).color;
      expect(
        fondInfo,
        isNot(fondAction),
        reason:
            'deux langages VISUELS distincts — une ombre seule se voit mal '
            'sur un telephone en plein soleil',
      );
    });

    testWidgets('interactif: false force l information malgre un onTap', (
      tester,
    ) async {
      // Cas limite verrouille pour que la declaration reste la SOURCE : si un
      // jour quelqu un veut une zone tactile sans relief, il l ecrit.
      await poser(
        tester,
        AppCard(interactif: false, onTap: () {}, child: const Text('x')),
      );
      expect(decorationDe(tester).boxShadow, isNull);
    });
  });

  group('ce que l appelant impose pour du SENS n est pas ecrase', () {
    testWidgets('un fond semantique gagne', (tester) async {
      await poser(
        tester,
        const AppCard(
          backgroundColor: Color(0xFF123456),
          child: Text('alerte'),
        ),
      );
      expect(decorationDe(tester).color, const Color(0xFF123456));
    });

    testWidgets('un liseré semantique gagne, et reste a plat', (tester) async {
      await poser(
        tester,
        const AppCard(
          borderColor: AppTheme.emergencyRed,
          borderWidth: 1.5,
          child: Text('orage'),
        ),
      );
      final deco = decorationDe(tester);
      expect(deco.border, isNotNull);
      expect((deco.border! as Border).top.color, AppTheme.emergencyRed);
      expect((deco.border! as Border).top.width, 1.5);
      expect(deco.boxShadow, isNull);
    });

    testWidgets('une elevation explicite gagne : la carte qui FLOTTE', (
      tester,
    ) async {
      // La bulle d un point d interet sur la carte : elle doit se detacher du
      // fond cartographique, cliquable ou non.
      await poser(tester, const AppCard(elevation: 6, child: Text('POI')));
      expect(decorationDe(tester).boxShadow!.single.offset.dy, 6);
    });
  });

  group('aucune fleche ne promet ce qui n existe pas', () {
    // GARDE-FOU SUR LA SOURCE, pas sur un ecran : la faute symetrique de celle
    // de Christophe est un chevron (« il y a quelque chose derriere ») pose sur
    // un element qui ne repond a rien. Elle avait ete trouvee une fois, sur la
    // liste des etapes.
    List<File> fichiersDart() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('.g.dart'))
        .toList();

    /// Le corps parenthese qui suit [depuis] dans [source].
    String corps(String source, int depuis) {
      var profondeur = 0;
      for (var i = depuis; i < source.length; i++) {
        if (source[i] == '(') profondeur++;
        if (source[i] == ')') {
          profondeur--;
          if (profondeur == 0) return source.substring(depuis, i + 1);
        }
      }
      return source.substring(depuis);
    }

    /// Vrai si un geste est declare dans ce fragment de source.
    bool porteUnGeste(String fragment) =>
        fragment.contains('onTap:') ||
        fragment.contains('onPressed:') ||
        fragment.contains('interactif: true');

    test('ni AppCard ni ListTile ne porte un chevron sans geste', () {
      final fautes = <String>[];
      for (final fichier in fichiersDart()) {
        final source = fichier.readAsStringSync();
        for (final motif in ['AppCard(', 'ListTile(']) {
          var depuis = 0;
          while (true) {
            final i = source.indexOf(motif, depuis);
            if (i < 0) break;
            depuis = i + motif.length;
            final bloc = corps(source, i + motif.length - 1);
            final promet =
                bloc.contains('chevronDroite') ||
                bloc.contains('flecheAvant') ||
                bloc.contains('chevron_right') ||
                bloc.contains('arrow_forward');
            if (!promet) continue;
            // LE GESTE PEUT ETRE SUR LE PARENT, et c est legitime : une carte
            // cliquable qui contient un ListTile decore (cf. [StageCard], dont
            // l `onTap` est porte par l AppCard et le chevron par le ListTile
            // qu elle enveloppe). On remonte donc jusqu au debut de l expression
            // de widget — le `return` ou la flechette qui l ouvre.
            final avant = source.substring(0, i);
            final debutExpression = [
              avant.lastIndexOf('return '),
              avant.lastIndexOf('=> '),
            ].reduce((a, b) => a > b ? a : b);
            final prefixe = debutExpression < 0
                ? ''
                : avant.substring(debutExpression);
            if (porteUnGeste(bloc) || porteUnGeste(prefixe)) continue;
            final ligne = avant.split('\n').length;
            fautes.add('${fichier.path}:$ligne ($motif)');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'une fleche « il y a quelque chose derriere » sur un element '
            'qui ne repond a rien :\n  ${fautes.join('\n  ')}',
      );
    });
  });
}
