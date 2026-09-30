import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/cadre_demo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 634 — RETOUR 1 DE CHRISTOPHE (DEM-260929-1123), MIS A JOUR PAR LA
/// TACHE 638 (test du 30/09).
///
/// Verbatim du 29/09 11:23, pendant son premier test sur telephone : « il faut
/// mettre demo en haut des sentiers juste un bouton "paasez en mode demo", le
/// tour des ecran devient orange ». Puis, precise ensuite : « UN BOUTON DEMO
/// ORANGE TOUT BETE, au-dessus des sentiers non achetes » ; « LE MODE DEMO
/// c est juste un mode demo, on prend Mare a Mare, ce sera toujours lui » ;
/// « un bouton demo qui montre comment marche l appli de A a Z » ; « simuler le
/// trek ca serait bien » ; « ON EST EN MODE DEMO » = rien ne compte.
///
/// DEUX DE SES DECISIONS ONT ETE RENVERSEES PAR SON TEST DU 30/09, et ce fichier
/// suit :
///   * le sentier de la demo n'est plus une config amputee a deux etapes, c'est
///     le MARE A MARE CENTRE COMPLET (bug 8, DEM-260930-1014) ;
///   * « le tour des ecran devient orange » et la barre du bas sont remplaces par
///     une seule pastille « Quitter » en haut (bug 11, DEM-260930-1020 : « le
///     bandeau du bas du mode demo cache une partie de l appli »).
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

    test('la demo porte le MARE A MARE CENTRE COMPLET, sept etapes', () {
      // « on prend Mare a Mare, ce sera toujours lui » (29/09), et « la demo de
      // Mare a Mare ce doit etre la demo de Mare a Mare, pas un truc avec 2
      // etapes !! » (30/09, bug 8).
      expect(kSentierDeDemo, mareAMareCentreTrailConfig.id);
      expect(mareAMareCentreTrailConfig.totalStages, 7);
    });
  });

  group('LA DEMO MONTRE, ELLE NE DEBLOQUE JAMAIS (garde-fou du lot 601)', () {
    test('elle refuse d ouvrir un AUTRE sentier que celui de la demo', () {
      // LE TROU QUE LE LOT 601 A FERME, ET QU ON NE ROUVRE PAS. Ce lot avait
      // supprime le drapeau `isShowcaseTrail` parce qu'une exemption d'acces est
      // un trou dans le modele. La demo porte UN sentier, et un seul : lui en
      // faire ouvrir un autre serait rouvrir ce trou sous un autre nom.
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c
          .read(sessionDemoProvider.notifier)
          .entrer(trailId: pyreneesTrailConfig.id);
      expect(
        c.read(enDemoProvider),
        isFalse,
        reason: 'la demo ne porte que le Mare a Mare Centre',
      );
    });

    test('entrer en demo ne rend GRATUIT aucun sentier', () {
      // LE GARDE-FOU, MESURE APRES LA TACHE 638. La demo ouvre desormais un
      // sentier PAYANT : la seule chose qui garantit qu'elle ne le debloque pas,
      // c'est qu'aucun verdict de droit ne change. Le prix du Mare a Mare reste
      // le meme, et la liste des sentiers gratuits ne bouge pas d'un iota.
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final gratuitsAvant = TrailCatalog.freeIds;
      expect(mareAMareCentreTrailConfig.isFreeTrail, isFalse);

      c.read(sessionDemoProvider.notifier).entrer();
      expect(TrailCatalog.freeIds, gratuitsAvant);
      expect(
        mareAMareCentreTrailConfig.isFreeTrail,
        isFalse,
        reason: 'la demo MONTRE le sentier payant, elle ne le rend pas gratuit',
      );
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

  group('une pastille QUITTER en haut, et rien d autre (bug 11)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Widget pomper(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(
        home: CadreDemo(child: Scaffold(body: Text('ecran'))),
      ),
    );

    testWidgets('hors demo, aucun signal de demo n existe', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await tester.pumpWidget(pomper(c));
      await tester.pump();

      expect(find.byKey(const ValueKey('demo-sortie')), findsNothing);
      expect(find.text('ecran'), findsOneWidget);
    });

    testWidgets('en demo, la pastille de sortie est la — et elle seule', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(pomper(c));
      await tester.pump();

      expect(find.byKey(const ValueKey('demo-sortie')), findsOneWidget);
      // L'ecran est toujours la : la pastille est PEINTE par-dessus, elle ne
      // remplace rien et ne deplace rien.
      expect(find.text('ecran'), findsOneWidget);

      // BUG 11 : PLUS DE CADRE QUI ROGNE, PLUS DE BANDEAU EN BAS.
      expect(
        find.byKey(const ValueKey('demo-cadre')),
        findsNothing,
        reason: 'le liston orange des quatre bords est supprime',
      );
      expect(
        find.byKey(const ValueKey('demo-barre-simulation')),
        findsNothing,
        reason:
            'le bandeau du bas est supprime : il cachait une partie de '
            'l application',
      );
    });

    testWidgets('la pastille ouvre le dialogue de fin de demo', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(pomper(c));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('demo-sortie')));
      await tester.pumpAndSettle();

      // La sortie n'est plus immediate : elle passe par le dialogue qui dit OU
      // retrouver la demo et propose de la cacher (bug 18).
      expect(
        find.byKey(const ValueKey('demo-dialogue-sortie')),
        findsOneWidget,
      );
      expect(c.read(enDemoProvider), isTrue);
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
          // Les libelles ajoutes par la tache 638.
          d.sortieTitre,
          d.sortieEnTeteCatalogue,
          d.sortieDansMonCompte,
          d.cacherLabel,
          d.sortieConfirmer,
          d.sortieAnnuler,
          d.indisponible,
          d.departSimule,
          d.compteTitre,
          d.compteRelancer,
          d.compteRelancerSous,
          d.compteReafficher,
          d.compteReafficherSous,
          d.collecteTitre,
          d.collecteIntro,
          d.collecteProfil,
          d.collecteForme,
          d.collecteExperience,
          d.collecteSaison,
          d.collecteSentier,
          d.collecteJours,
          d.collecteAbsent,
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
