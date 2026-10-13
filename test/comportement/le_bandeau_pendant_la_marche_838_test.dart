// TACHE 838, VOLET D4 (SUITE) — LE CYCLE QUITTER-REVENIR AVEC LA MARCHE
// SIMULEE DEJA DEMARREE.
//
// POURQUOI CE TEST VIT DANS SON PROPRE FICHIER, ET C'EST UNE MESURE, PAS UN
// GOUT DE RANGEMENT. Il monte l'application REELLE, et `monterAppliReelle`
// utilise le routeur de production — `appRouter`, une variable GLOBALE du
// module `core/routing/app_router.dart`. Deux montages complets dans le MEME
// fichier partagent donc ce routeur, sa pile et sa derniere adresse.
//
// CE QUI A ETE MESURE : ce test passe seul, trois fois sur trois, et echoue
// trois fois sur trois quand il tourne APRES le test de cycle de
// `le_bandeau_de_demo_revient_838_test.dart` — toujours au meme endroit, le
// bouton orange du catalogue qui n'arrive jamais. Le premier test finit EN
// DEMONSTRATION, sur le sentier de demo ; le second repart donc d'un routeur
// qui n'est pas celui d'une application fraiche.
//
// `flutter test` isole les fichiers les uns des autres. Mettre ce test ici,
// c'est donc lui rendre l'application fraiche dont il a besoin — plutot que de
// bricoler une remise a zero du routeur global, qui mentirait sur ce que le
// test mesure.
//
// CE QU'IL MESURE, LUI : la sequence exacte decrite par le testeur du 11/10 —
// la marche simulee avait ete DEMARREE avant de quitter (le marcheur avancait
// a 4 km/h, temps accelere), et c'est en revenant sans relancer l'application
// que les deux bandeaux ne sont pas revenus.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/shared/widgets/cadre_demo.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../structurel/parcours_reel.dart';

/// Le bandeau orange et sa sortie.
const _bandeau = ValueKey('demo-bandeau');

/// La ligne « marche simulee », sous le bandeau.
const _mention = ValueKey('demo-marche-simulee');

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// QUITTE LA DEMO PAR LE BOUTON, puis laisse passer le message de sortie.
  ///
  /// `sortirDeLaDemoDUnAppui` pose un message de fin et un minuteur pour le
  /// fermer lui-meme (bug 11 du lot 649). Un test qui part sans l'avoir laisse
  /// expirer echoue sur « A Timer is still pending ».
  Future<void> quitterParLeBouton(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('demo-sortie')));
    await tester.pumpAndSettle();
    await tester.pump(kDureeMessageSortieDemo);
    await tester.pumpAndSettle();
  }

  group('838 D4 — la marche demarree, la sortie, et le retour', () {
    // =========================================================================
    // LA SEQUENCE EXACTE DU TESTEUR : LA MARCHE ETAIT DEMARREE
    // =========================================================================
    //
    // CE QUE LES TROIS COUCHES PRECEDENTES NE COUVRAIENT PAS, et c'est la
    // precision qui a ete donnee apres coup : la marche simulee avait ete
    // DEMARREE avant de quitter. Le testeur refaisait le parcours pour
    // atteindre la fin du trek — donc le marcheur avancait, a 4 km/h, avec le
    // temps accelere soixante fois. C'est en quittant la demo DANS CET ETAT,
    // puis en y revenant sans relancer l'application, que les deux bandeaux ne
    // sont pas revenus. Seul un arret force de l'application les a fait
    // reapparaitre.
    //
    // POURQUOI CET ETAT PEUT TOUT CHANGER. Le marcheur simule est un objet de
    // PROCESSUS, pas un objet de demo : « IL N'EST PAS CREE PAR LA DEMO : il
    // existe toujours, et il ne fait rien tant que personne ne l'a fait
    // demarrer » (`marcheur_simule_providers.dart`). Il porte une minuterie
    // periodique et un flux de positions, et le seul geste qui les arrete est
    // `arreterSimulationDemo`, appele par la sortie de demo. Une marche en
    // cours au moment de la sortie fait donc traverser a cette sortie un
    // chemin qu'une demo jamais demarree ne traverse pas.
    //
    // ON UTILISE LE VRAI MARCHEUR, PAS SON ETAT SURCHARGE. Les couches 2 et 3
    // remplacaient `etatDuMarcheurSimuleProvider` par une valeur fixe, ce qui
    // mesurait la garde de demo des bandeaux mais JAMAIS le moteur de marche.
    // Ici le marcheur tourne pour de vrai, sur la trace reellement seedee
    // (3 590 points), et c'est lui qui dit s'il marche.
    testWidgets(
      'la marche DEMARREE, on quitte, on revient : les bandeaux reviennent',
      (tester) async {
        RefusSauvegardeSystemeDialog.resetLock();
        await monterAppliReelle(
          tester,
          depart: '/catalog',
          avecEnveloppesDeMain: true,
        );

        if (find
            .byKey(RefusSauvegardeSystemeDialog.validateKey)
            .evaluate()
            .isNotEmpty) {
          await tester.tap(
            find.byKey(RefusSauvegardeSystemeDialog.validateKey),
          );
          await stabiliser(tester);
        }

        final boutonDemo = find.byKey(const ValueKey('catalog-demo-button'));
        expect(await attendreLEcran(tester, boutonDemo), isTrue);

        /// Le conteneur de l'application montee, pour LIRE et AGIR sans pixel.
        ProviderContainer conteneur() => ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp).first),
          listen: false,
        );

        void entrerParLeCatalogue() {
          tester.widget<InkWell>(boutonDemo).onTap!();
        }

        /// DEMARRE LA MARCHE SIMULEE PAR LE GESTE DE PRODUCTION.
        ///
        /// `demarrerSimulationDemo` est exactement ce qu'appelle le bouton
        /// « demarrer » du cockpit en demonstration (`hub_start_trek_button`).
        /// On l'appelle directement plutot que de chercher ce bouton a travers
        /// un cockpit entier : c'est le meme chemin, sans la geometrie.
        Future<void> demarrerLaMarche() async {
          final resultat = await conteneur()
              .read(trekSessionManagerProvider.notifier)
              .demarrerSimulationDemo(kSentierDeDemo);
          expect(
            resultat,
            anyOf(StartOutcome.started, StartOutcome.alreadyActiveSameTrail),
            reason:
                'si la simulation ne demarre pas, ce test ne mesure plus la '
                'sequence du testeur — il mesure une demo immobile, et les '
                'trois couches precedentes le font deja',
          );
          await stabiliser(tester);
        }

        // ---- PREMIER TOUR : on entre, ON MARCHE, on quitte ----
        entrerParLeCatalogue();
        expect(
          await attendreLEcran(tester, find.byKey(_bandeau)),
          isTrue,
          reason: 'premiere entree : le bandeau est la',
        );

        await demarrerLaMarche();
        expect(
          conteneur().read(etatDuMarcheurSimuleProvider),
          anyOf(EtatDuMarcheur.enMarche, EtatDuMarcheur.enPause),
          reason: 'le marcheur doit reellement avancer : c est la condition',
        );
        expect(
          await attendreLEcran(tester, find.byKey(_mention)),
          isTrue,
          reason:
              'la marche simulee tourne : la mention d honnetete doit etre '
              'la, avec son facteur de temps',
        );

        // ET ELLE SE CONSTRUIT SANS LEVER, CE QUI N'ETAIT PAS LE CAS.
        //
        // C'EST LE DEFAUT QUE CE TEST A TROUVE EN CHEMIN, et il ne sortait
        // QUE dans cet etat — marche simulee en cours, donc mention montee
        // avec sa commande « simuler » :
        //
        //     No Overlay widget found.
        //     RawTooltip widgets require an Overlay widget ancestor [...]
        //     The relevant error-causing widget was:
        //       IconButton-[<'demo-simuler'>]
        //
        // La variante compacte du bouton de simulation portait une bulle
        // d'aide ; elle vit depuis la tache 747 dans le bandeau de demo, donc
        // AU-DESSUS du `Navigator`, ou aucun `Overlay` n'existe. Meme famille
        // que le « Quitter » muet du build 8 (tache 649).
        //
        // LE SOCLE CAPTURE LES ERREURS DE RENDU AU LIEU DE LES LAISSER
        // ECHOUER : sans cette affirmation, le test passait AU VERT avec
        // l'exception dans le journal. C'est exactement le genre de silence
        // que ce depot refuse.
        expect(
          erreursDeRendu(tester).where((e) => !estDebordement(e)).toList(),
          isEmpty,
          reason:
              'le bandeau de demonstration ne doit rien lever en se '
              'construisant : il est pose au-dessus du Navigator, et tout ce '
              'qui reclame un Overlay y est impossible',
        );

        await quitterParLeBouton(tester);
        expect(find.byKey(_bandeau), findsNothing);
        expect(find.byKey(_mention), findsNothing);
        expect(
          conteneur().read(etatDuMarcheurSimuleProvider),
          isNot(EtatDuMarcheur.enMarche),
          reason:
              'LA SORTIE DOIT ARRETER LE MARCHEUR. S il continue d avancer '
              'apres la sortie, il reste une minuterie orpheline dans le '
              'processus — et c est elle que le testeur voyait tourner',
        );

        // ---- SECOND TOUR : on revient, ON REMARCHE ----
        await allerA(tester, '/catalog');
        expect(await attendreLEcran(tester, boutonDemo), isTrue);
        entrerParLeCatalogue();
        final bandeauRevenu = await attendreLEcran(
          tester,
          find.byKey(_bandeau),
        );

        expect(
          conteneur().read(enDemoProvider),
          isTrue,
          reason: 'on est bien rentre en demonstration',
        );
        expect(
          bandeauRevenu,
          isTrue,
          reason:
              'LE DEFAUT DECRIT LE 11/10, DANS SA SEQUENCE EXACTE : la marche '
              'avait ete demarree avant de quitter, et au retour le bandeau '
              'orange ne revenait plus. Seul un arret force de l application '
              'le ramenait',
        );

        await demarrerLaMarche();
        expect(
          await attendreLEcran(tester, find.byKey(_mention)),
          isTrue,
          reason:
              'et la mention « marche simulee » non plus ne revenait pas, '
              'alors que le marcheur, lui, repartait a 4 km/h',
        );

        // ON ARRETE LA MARCHE AVANT DE PARTIR : une minuterie periodique
        // survivante fait echouer le cadre de test, et masquerait le resultat.
        await quitterParLeBouton(tester);
        await demonterAppli(tester);
      },
    );
  });
}
