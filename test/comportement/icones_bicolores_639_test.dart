import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/app_branding.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_section.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/quick_access_card.dart';

/// TACHE 639 — BUG 3 : LES TUILES PRINCIPALES SONT BICOLORES, ET C'EST UNE
/// REGLE, PAS UN REGLAGE PAR ECRAN.
///
/// LE RETOUR DE CHRISTOPHE, MOT POUR MOT (30/09 10:09, telephone, build 0.1.3
/// (7)) : « les icones de Mes treks ne sont pas bicolores / Compte etapes et
/// pret a partir non plus ».
///
/// CE QUI ETAIT MESURE AVANT DE CHANGER QUOI QUE CE SOIT. Le lot 632 avait bien
/// livre les trois familles bicolores et le widget qui les rend. Mais le duo ne
/// s'obtenait qu'en NOMMANT la rubrique a l'appel : `IconeStepways` n'apparait
/// que DEUX fois dans lib/ (l'en-tete de section et la carte d'acces), et le
/// parametre `rubrique:` que DIX-SEPT fois, toutes dans `hub_screen.dart`. Les
/// quatorze autres tuiles — dont les trois du bandeau de « Mes treks » — passaient
/// le chemin A PLAT, donc retombaient sur le monochrome teinte. Le cockpit etait
/// bicolore, le reste non : deux langages pour la meme carte.
///
/// CE QUE CES TESTS VERROUILLENT :
///   1. la regle est UNE fonction ([iconeBicolorePour]), consultable, et les
///      quatre traces d'un meme dessin y mènent au meme endroit ;
///   2. les tuiles principales que Christophe a nommees sortent un fichier d'un
///      dossier duo — verifie sur le fichier REELLEMENT charge, pas sur l'appel ;
///   3. les deux garde-fous de la regle tiennent : couleur imposee -> monochrome,
///      dessin sans trace duo -> monochrome.
void main() {
  /// Le fichier que ce `SvgPicture` charge vraiment. C'est la seule mesure qui
  /// vaut : un appel peut demander du bicolore et rendre du monochrome.
  String cheminCharge(WidgetTester tester, Finder ou) {
    final svg = tester.widget<SvgPicture>(ou);
    final loader = svg.bytesLoader;
    expect(
      loader,
      isA<SvgAssetLoader>(),
      reason: 'ce dessin ne vient pas d un fichier du depot',
    );
    return (loader as SvgAssetLoader).assetName.replaceAll(r'\', '/');
  }

  /// Vrai quand ce chemin est l'un des traces BICOLORES livres par Christophe.
  bool estBicolore(String chemin) =>
      chemin.contains('/rubriques-duo/') ||
      chemin.contains('/rubriques-duo-clair/') ||
      chemin.contains('/ico-duo/') ||
      chemin.contains('/ico-duo-clair/') ||
      chemin.contains('/mat-duo/') ||
      chemin.contains('/mat-duo-clair/');

  Future<void> poser(WidgetTester tester, Widget enfant) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: enfant)),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }

  group('la regle mono / duo est ecrite une fois', () {
    test('les quatre traces d un dessin menent au meme dessin', () {
      for (final IconeBicolore dessin in <IconeBicolore>[
        ...RubriqueStepways.values,
        ...IcoStepways.values,
        ...MatStepways.values,
      ]) {
        for (final chemin in [dessin.mono, dessin.duo, dessin.duoClair]) {
          expect(
            iconeBicolorePour(chemin),
            same(dessin),
            reason: '$chemin ne se resout pas sur $dessin',
          );
        }
      }
    });

    test('le chemin A PLAT d une rubrique se resout aussi', () {
      // C'est LE cas du bug : les ecrans passent `StepwaysIcons.carte`, c'est-a-
      // dire `assets/icons/carte.svg`, et non `rubriques-duo-mono/carte.svg`.
      // Sans cette resolution, la regle ne les aurait jamais vus.
      expect(
        iconeBicolorePour(StepwaysIcons.carte),
        same(RubriqueStepways.carte),
      );
      expect(
        iconeBicolorePour(StepwaysIcons.catalogueSentiers),
        same(RubriqueStepways.catalogueSentiers),
      );
      expect(
        iconeBicolorePour(StepwaysIcons.portefeuille),
        same(IcoStepways.portefeuille),
      );
    });

    test('les 101 noms des trois familles sont distincts', () {
      // La table de resolution est indexee par nom de fichier. Deux familles qui
      // porteraient le meme nom feraient silencieusement gagner la derniere.
      final noms = <String>[
        ...RubriqueStepways.values.map((e) => e.fichier),
        ...IcoStepways.values.map((e) => e.fichier),
        ...MatStepways.values.map((e) => e.fichier),
      ];
      expect(
        noms.toSet().length,
        noms.length,
        reason: 'nom de fichier en double',
      );
      expect(noms.length, 101);
    });

    test('un dessin hors des trois familles ne se resout pas', () {
      // Les icones du terrain n'ont qu'un seul trace : la regle doit le dire,
      // pas inventer un fichier duo qui n'existe pas.
      expect(iconeBicolorePour(StepwaysIcons.sommet), isNull);
      expect(iconeBicolorePour('assets/icons/pas.svg'), isNull);
    });
  });

  group('les tuiles principales sortent un fichier bicolore', () {
    // LA LISTE EST ECRITE ICI, NOMMEMENT. Une tuile qui repasserait en
    // monochrome fait tomber ce test, et on sait laquelle.
    const tuiles = <String, String>{
      'Pret a partir (cockpit)': StepwaysIcons.carte,
      'Compte-etapes (portefeuille)': StepwaysIcons.portefeuille,
      'Mes treks — Decouvrir': StepwaysIcons.catalogueSentiers,
      'Mes treks — Mon compte': StepwaysIcons.monCompte,
      'Mes treks — Reglages': StepwaysIcons.reglages,
      'Trek termine — Diplome': StepwaysIcons.diplome,
      'Faisabilite': StepwaysIcons.faisabilite,
      'Programme': StepwaysIcons.programme,
      'Materiel & sac': StepwaysIcons.sacADos,
      'Journal': StepwaysIcons.journal,
      'Meteo': StepwaysIcons.meteo,
      'Transport': StepwaysIcons.transport,
      'Ravitaillement': StepwaysIcons.ravitaillement,
      'Hebergement': StepwaysIcons.hebergement,
      'Cartes hors ligne': StepwaysIcons.carte,
    };

    for (final tuile in tuiles.entries) {
      testWidgets('${tuile.key} est bicolore', (tester) async {
        await poser(tester, StepIcon.tuile(tuile.value));
        final chemin = cheminCharge(tester, find.byType(SvgPicture));
        expect(
          estBicolore(chemin),
          isTrue,
          reason: '${tuile.key} charge « $chemin », qui n est pas un trace duo',
        );
      });
    }

    testWidgets('la carte d acces de « Mes treks » est bicolore', (
      tester,
    ) async {
      // L'ecran passe le chemin A PLAT (`icon:`), jamais `rubrique:` — c'est
      // exactement l'appel qui produisait le defaut.
      await poser(
        tester,
        QuickAccessCard(
          icon: StepwaysIcons.catalogueSentiers,
          title: 'Decouvrir',
          subtitle: 'Parcourez le catalogue',
          onTap: () {},
        ),
      );
      final chemin = cheminCharge(tester, find.byType(SvgPicture).first);
      expect(estBicolore(chemin), isTrue, reason: 'charge « $chemin »');
    });

    testWidgets('l en-tete de section de « Mes treks » est bicolore', (
      tester,
    ) async {
      await poser(
        tester,
        SizedBox(
          width: 360,
          child: HubSection(
            title: 'Mes treks',
            icon: StepwaysIcons.catalogueSentiers,
            cards: const [],
          ),
        ),
      );
      final chemin = cheminCharge(tester, find.byType(SvgPicture).first);
      expect(estBicolore(chemin), isTrue, reason: 'charge « $chemin »');
    });
  });

  group('les deux garde-fous de la regle', () {
    testWidgets('une couleur imposee retombe sur le monochrome', (
      tester,
    ) async {
      // Un onglet actif, une carte verrouillee, une alerte : la couleur PORTE
      // l etat. Un trace bicolore fige l aurait ignoree.
      await poser(
        tester,
        const StepIcon.tuile(StepwaysIcons.carte, color: Color(0xFFAA0000)),
      );
      expect(
        estBicolore(cheminCharge(tester, find.byType(SvgPicture))),
        isFalse,
      );
    });

    testWidgets('une carte verrouillee reste monochrome', (tester) async {
      await poser(
        tester,
        QuickAccessCard(
          icon: StepwaysIcons.diplome,
          title: 'Diplome',
          subtitle: 'Verrouille',
          enabled: false,
          onTap: () {},
        ),
      );
      expect(
        estBicolore(cheminCharge(tester, find.byType(SvgPicture).first)),
        isFalse,
        reason: 'une carte grisee garderait une icone vive',
      );
    });

    testWidgets('un dessin du terrain reste monochrome, meme en tuile', (
      tester,
    ) async {
      await poser(tester, const StepIcon.tuile(StepwaysIcons.sommet));
      final chemin = cheminCharge(tester, find.byType(SvgPicture));
      expect(estBicolore(chemin), isFalse);
      expect(chemin, StepwaysIcons.sommet);
    });

    testWidgets('la mecanique d interface reste monochrome, meme en tuile', (
      tester,
    ) async {
      // Les 38 MAT existent en bicolore mais [AppBranding.mecaniqueEnDuo] est
      // faux : un chevron orange sur chaque ligne crierait partout. La regle
      // suit l interrupteur, pas l appelant.
      expect(AppBranding.mecaniqueEnDuo, isFalse);
      await poser(tester, const StepIcon.tuile(StepwaysIcons.chevronDroite));
      expect(
        estBicolore(cheminCharge(tester, find.byType(SvgPicture))),
        isFalse,
      );
    });

    testWidgets('un StepIcon ordinaire n est JAMAIS bicolore', (tester) async {
      // L autre moitie de la regle : les icones de service ne changent pas.
      await poser(tester, const StepIcon(StepwaysIcons.carte));
      expect(
        estBicolore(cheminCharge(tester, find.byType(SvgPicture))),
        isFalse,
      );
    });
  });
}
