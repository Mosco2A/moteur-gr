import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_demo_trail_config.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/cadre_demo.dart';

/// TACHE 634 — RETOUR 1 DE CHRISTOPHE (DEM-260929-1123).
///
/// Verbatim du 29/09 11:23, pendant son premier test sur telephone : « il faut
/// mettre demo en haut des sentiers juste un bouton "paasez en mode demo", le
/// tour des ecran devient orange ». Puis, precise ensuite : « UN BOUTON DEMO
/// ORANGE TOUT BETE, au-dessus des sentiers non achetes » ; « LE MODE DEMO
/// c est juste un mode demo, on prend Mare a Mare, ce sera toujours lui » ;
/// « un bouton demo qui montre comment marche l appli de A a Z » ; « simuler le
/// trek ca serait bien » ; « ON EST EN MODE DEMO » = rien ne compte. Et le
/// refus du mode SUBI : « MAIS NON !!! il s ouvre en mode prepa AVEC PUB !!! ».
void main() {
  group('la demo se CHOISIT, elle ne se subit plus', () {
    test('au demarrage, on n est pas en demo', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(c.read(enDemoProvider), isFalse);
      expect(c.read(sessionDemoProvider).trailId, isNull);
    });

    test('on y entre et on en sort par un geste', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      expect(c.read(enDemoProvider), isTrue);
      expect(c.read(sessionDemoProvider).trailId, kSentierDeDemo);

      c.read(sessionDemoProvider.notifier).sortir();
      expect(c.read(enDemoProvider), isFalse);
    });

    test('la demo ne porte QUE le sentier de demonstration', () {
      // « on prend Mare a Mare, ce sera toujours lui ».
      expect(kSentierDeDemo, mareAMareCentreDemoTrailConfig.id);
      expect(mareAMareCentreDemoTrailConfig.totalStages, 2);
    });
  });

  group('LA DEMO MONTRE, ELLE NE DEBLOQUE JAMAIS (garde-fou du lot 601)', () {
    test('elle refuse d ouvrir un sentier PAYANT', () {
      // LE TROU QUE LE LOT 601 A FERME, ET QU ON NE ROUVRE PAS. Ce lot avait
      // supprime le drapeau `isShowcaseTrail` parce qu'une exemption d'acces
      // est un trou dans le modele. Faire ouvrir un sentier payant par la demo
      // serait le meme trou sous un autre nom.
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c
          .read(sessionDemoProvider.notifier)
          .entrer(trailId: mareAMareCentreTrailConfig.id);
      expect(
        c.read(enDemoProvider),
        isFalse,
        reason: 'la demo ne doit pas pouvoir ouvrir le sentier payant',
      );
    });

    test('le sentier de demonstration est GRATUIT pour tout le monde', () {
      // C'est ce qui rend la demo inoffensive : elle n'accorde aucun droit,
      // elle ouvre un sentier que le catalogue donne deja a tous.
      expect(mareAMareCentreDemoTrailConfig.isFreeTrail, isTrue);
      expect(mareAMareCentreTrailConfig.isFreeTrail, isFalse);
    });

    test('la demo ne vit QU EN MEMOIRE : rien a persister, rien a nettoyer', () {
      // La preuve la plus forte de « rien ne compte » : deux conteneurs
      // independants ne partagent rien. Fermer l'application met fin a la demo,
      // parce qu'il n'y a aucun disque derriere.
      final premier = ProviderContainer();
      premier.read(sessionDemoProvider.notifier).entrer();
      expect(premier.read(enDemoProvider), isTrue);
      premier.dispose();

      final second = ProviderContainer();
      addTearDown(second.dispose);
      expect(second.read(enDemoProvider), isFalse);
    });
  });

  group('le tour de l ecran devient orange, et la sortie est visible', () {
    Widget pomper(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: CadreDemo(child: Scaffold(body: Text('ecran'))),
      ),
    );

    testWidgets('hors demo, le cadre n existe pas du tout', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(pomper(c));
      await tester.pump();

      expect(find.byKey(const ValueKey('demo-cadre')), findsNothing);
      expect(find.byKey(const ValueKey('demo-sortie')), findsNothing);
      expect(find.text('ecran'), findsOneWidget);
    });

    testWidgets('en demo, le cadre orange et la sortie sont la', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(pomper(c));
      await tester.pump();

      expect(find.byKey(const ValueKey('demo-cadre')), findsOneWidget);
      expect(find.byKey(const ValueKey('demo-sortie')), findsOneWidget);
      // L'ecran est toujours la : le cadre est PEINT par-dessus, il ne
      // remplace rien et ne deplace rien.
      expect(find.text('ecran'), findsOneWidget);

      // ET LA PHRASE QUI COMPTE EST SOUS LES YEUX DU RANDONNEUR.
      expect(find.byKey(const ValueKey('demo-rien-ne-compte')), findsOneWidget);
    });

    testWidgets('la sortie fonctionne, et le cadre disparait', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(pomper(c));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('demo-sortie')));
      await tester.pump();

      expect(c.read(enDemoProvider), isFalse);
      expect(find.byKey(const ValueKey('demo-cadre')), findsNothing);
    });

    testWidgets('le cadre est bien ORANGE, et de la bonne epaisseur', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();
      await tester.pumpWidget(pomper(c));
      await tester.pump();

      final decore = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('demo-cadre')),
      );
      final bordure = (decore.decoration as BoxDecoration).border!.top;
      expect(bordure.width, kEpaisseurCadreDemo);
      expect(bordure.color.a, 1.0);
      // Orange : rouge fort, vert moyen, bleu nul.
      expect(bordure.color.r, greaterThan(0.9));
      expect(bordure.color.b, lessThan(0.1));
    });
  });

  group('les cinq langues portent les libelles de la demo', () {
    test('aucun libelle de demo n est vide', () {
      for (final langue in AppLocale.values) {
        final d = langue.buildSync().demo;
        for (final libelle in [
          d.bandeau,
          d.quitter,
          d.boutonTitre,
          d.boutonSous,
          d.rienNeCompte,
          d.simulerEtape,
          d.simulerFin,
        ]) {
          expect(libelle.trim(), isNotEmpty, reason: langue.languageCode);
        }
        // Le refus d'achat en demo se DIT, il n'est pas muet.
        expect(
          langue.buildSync().monetization.buyOutcomeDemo.trim(),
          isNotEmpty,
          reason: langue.languageCode,
        );
      }
    });
  });
}
