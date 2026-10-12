// TACHE 838, VOLET D4 — LE BANDEAU DE DEMO QUI NE REVIENT PAS, REPRODUIT PUIS
// FERME.
//
// CE QUI A ETE VU LE 11/10/2026. On quitte la demonstration, on y revient SANS
// relancer l'application, et les deux bandeaux ne s'affichent plus : ni le
// bandeau orange « MODE DEMO » avec son « Quitter », ni la ligne « marche
// simulee ». La demonstration, elle, TOURNE : la marche simulee demarre et le
// marcheur avance a 4 km/h. Un testeur peut donc se croire SORTI alors qu'il y
// est encore — c'est le « mode demo batard » que la tache 638 avait ferme (bug
// 19, verbatim de Christophe : « on est toujours en mode demo sans le savoir
// !!!! »), rouvert par un chemin que la tache 638 ne couvrait pas : le RETOUR.
//
// POURQUOI LE DEPOT NE L'A PAS VU, ET C'EST UN TROU DE COUVERTURE, PAS UNE
// MALCHANCE. `demo-bandeau` n'est affirme qu'a UN endroit du depot
// (`demo_complete_638_test.dart`), et ce test construit DEUX conteneurs
// separes — un hors demo, un en demo — puis monte un arbre par conteneur. Il
// mesure donc deux ETATS, jamais une TRANSITION, et encore moins un
// aller-retour dans le meme conteneur. `demo-marche-simulee`, lui, n'apparait
// nulle part dans `test/`. Le cycle que tout testeur fait en premier — entrer,
// sortir, rentrer — n'etait mesure par rien.
//
// CE QUE CE FICHIER MESURE, EN DEUX COUCHES SEPAREES, parce que les deux
// peuvent casser independamment :
//   1. L'ETAT, sans aucun widget : `enDemoProvider` redit-il OUI a la seconde
//      entree ? C'est la couche ou vit le piege de Riverpod que
//      `session_demo.dart` nomme lui-meme dans l'en-tete de
//      `generationDeDemoProvider` : « Riverpod ne RECALCULE pas un provider
//      dont la dependance a retrouve sa valeur precedente ».
//   2. LES BANDEAUX, dans l'arbre REEL — `CadreDemo` pose dans le `builder` de
//      `MaterialApp.router`, donc AU-DESSUS du `Navigator` de GoRouter, comme
//      en production et comme l'exige la lecon de la tache 649.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/navigateur_racine.dart';
import 'package:moteur_gr/core/services/pilote_demo.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import 'package:moteur_gr/features/trek/presentation/mention_marche_simulee.dart';
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

  // ===========================================================================
  // COUCHE 1 — L'ETAT, SANS UN SEUL WIDGET
  // ===========================================================================
  //
  // AUCUN AUDITEUR N'EST POSE, ET C'EST LA CONDITION DU DEFAUT. En production,
  // entrer en demo comme en sortir appelle `chooseTrail`, qui change le sentier
  // actif ; `appBootstrapProvider` re-seede alors, et `main.dart` rend le
  // loader a sa place (« if (bootstrap.isLoading) return loader() »). TOUT
  // l'arbre route est demonte pendant ce temps, bandeaux compris : plus
  // personne n'ecoute l'etat de la demo au moment precis ou il bascule. Ces
  // tests reproduisent cette condition en lisant l'etat SANS l'ecouter.
  group('838 D4 — l etat de la demo survit au cycle quitter-revenir', () {
    test('entrer, sortir, rentrer : la demo se redit ACTIVE', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      expect(c.read(enDemoProvider), isTrue, reason: 'premiere entree');

      c.read(sessionDemoProvider.notifier).sortir();
      expect(c.read(enDemoProvider), isFalse, reason: 'la sortie coupe bien');

      c.read(sessionDemoProvider.notifier).entrer();
      expect(
        c.read(enDemoProvider),
        isTrue,
        reason:
            'C EST LE DEFAUT DU 11/10 : on revient en demo, la marche simulee '
            'repart, et l etat de demo repond encore NON — donc plus aucun '
            'bandeau ne le dit',
      );
    });

    test('le NUMERO de demo monte a chaque entree, il ne redescend jamais', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      final depart = c.read(generationDeDemoProvider);
      c.read(sessionDemoProvider.notifier).entrer();
      final premiere = c.read(generationDeDemoProvider);
      c.read(sessionDemoProvider.notifier).sortir();
      c.read(sessionDemoProvider.notifier).entrer();
      final seconde = c.read(generationDeDemoProvider);

      expect(premiere, greaterThan(depart));
      expect(
        seconde,
        greaterThan(premiere),
        reason:
            'c est ce numero TOUJOURS NEUF qui rend la reconstruction reelle '
            'la ou un booleen revenu a sa valeur d avant ne la declenche pas '
            '(cf. l en-tete de generationDeDemoProvider)',
      );
    });

    test('la sortie du pilote complet laisse la demo REELLEMENT coupee', () {
      final c = ProviderContainer();
      addTearDown(c.dispose);

      c.read(sessionDemoProvider.notifier).entrer();
      c.read(sessionDemoProvider.notifier).sortir();

      expect(c.read(sessionDemoProvider).active, isFalse);
      expect(c.read(enDemoProvider), isFalse);
    });
  });

  // ===========================================================================
  // COUCHE 2 — LES DEUX BANDEAUX, DANS L'ARBRE REEL
  // ===========================================================================

  /// L'ARBRE DE `main.dart`, PAS UN ARBRE DE TEST (lecon de la tache 649).
  ///
  /// `CadreDemo` enveloppe le `child` fourni au `builder` de
  /// `MaterialApp.router` : il est donc AU-DESSUS du `Navigator` de GoRouter,
  /// exactement comme en production. Et il recoit `sousLeBandeau`, la mention
  /// « marche simulee », comme `main.dart` le fait (ligne 604) — sans quoi la
  /// moitie du defaut ne serait pas sous mesure.
  ///
  /// La route `/catalog` porte le geste de RETOUR en demo : c'est la porte
  /// qu'emprunte un testeur (le bouton orange en tete du catalogue), et elle
  /// passe par [entrerEnDemo], la seule entree du depot.
  ({Widget appli, GoRouter routeur}) appliReelle(ProviderContainer c) {
    final routeur = GoRouter(
      navigatorKey: cleNavigateurRacine,
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('COCKPIT DEMO')),
        ),
        GoRoute(
          path: '/my-treks',
          builder: (_, __) => Scaffold(
            body: Column(
              children: [
                const Text('MES TREKS'),
                Consumer(
                  builder: (context, ref, _) => TextButton(
                    key: const ValueKey('test-rentrer-en-demo'),
                    onPressed: () {
                      entrerEnDemo(ref);
                      GoRouter.of(context).go('/home');
                    },
                    child: const Text('REVENIR EN DEMO'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    return (
      appli: UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          routerConfig: routeur,
          builder: (context, child) => CadreDemo(
            sousLeBandeau: const MentionMarcheSimulee(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
      routeur: routeur,
    );
  }

  /// QUITTE LA DEMO PAR LE BOUTON, puis laisse passer le message de sortie.
  ///
  /// `sortirDeLaDemoDUnAppui` pose un message de fin et un minuteur de
  /// [kDureeMessageSortieDemo] pour le fermer lui-meme (bug 11 du lot 649). Un
  /// test qui part sans l'avoir laisse expirer echoue sur « A Timer is still
  /// pending » — ce qui MASQUERAIT le defaut que ce fichier mesure.
  Future<void> quitterParLeBouton(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('demo-sortie')));
    await tester.pumpAndSettle();
    await tester.pump(kDureeMessageSortieDemo);
    await tester.pumpAndSettle();
  }

  /// Le marcheur est EN MARCHE : la mention doit alors s'afficher.
  ///
  /// On surcharge l'ETAT du marcheur plutot que de demarrer une vraie
  /// simulation : ce qui est sous mesure ici est la GARDE DE DEMO des deux
  /// bandeaux, pas le moteur de marche, qui a ses propres tests.
  ///
  /// Le type `Override` vient de `flutter_riverpod/misc.dart` : l'export
  /// principal de Riverpod 3.3.2 ne le porte pas (meme import que
  /// `acheter_ou_preparer_639_test.dart`).
  List<Override> marcheurEnMarche() => [
    etatDuMarcheurSimuleProvider.overrideWithValue(EtatDuMarcheur.enMarche),
  ];

  group('838 D4 — les deux bandeaux reviennent avec la demo', () {
    testWidgets('quitter puis REVENIR : le bandeau orange est de retour', (
      tester,
    ) async {
      final c = ProviderContainer(overrides: marcheurEnMarche());
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      final (:appli, :routeur) = appliReelle(c);
      addTearDown(routeur.dispose);
      await tester.pumpWidget(appli);
      await tester.pumpAndSettle();

      expect(
        find.byKey(_bandeau),
        findsOneWidget,
        reason: 'premiere entree : le bandeau est la',
      );

      // ON QUITTE PAR LE BOUTON, comme un testeur.
      await quitterParLeBouton(tester);

      expect(
        find.byKey(_bandeau),
        findsNothing,
        reason: 'sorti de la demo, plus de bandeau',
      );
      expect(find.text('MES TREKS'), findsOneWidget);

      // ON Y REVIENT, SANS RELANCER L'APPLICATION.
      await tester.tap(find.byKey(const ValueKey('test-rentrer-en-demo')));
      await tester.pumpAndSettle();

      expect(
        c.read(enDemoProvider),
        isTrue,
        reason: 'la demo tourne : c est ce que le testeur constate (4 km/h)',
      );
      expect(
        find.byKey(_bandeau),
        findsOneWidget,
        reason:
            'LE DEFAUT DU 11/10 : la demo tourne et le bandeau orange ne le '
            'dit plus. Un testeur se croit sorti alors qu il y est encore',
      );
      expect(
        find.byKey(const ValueKey('demo-sortie')),
        findsOneWidget,
        reason: 'sans ce bouton, on ne peut plus sortir de la demo du tout',
      );
    });

    testWidgets('quitter puis REVENIR : la mention « marche simulee » aussi', (
      tester,
    ) async {
      final c = ProviderContainer(overrides: marcheurEnMarche());
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      final (:appli, :routeur) = appliReelle(c);
      addTearDown(routeur.dispose);
      await tester.pumpWidget(appli);
      await tester.pumpAndSettle();

      expect(
        find.byKey(_mention),
        findsOneWidget,
        reason: 'premiere entree, marcheur en marche : la mention est la',
      );

      await quitterParLeBouton(tester);
      expect(find.byKey(_mention), findsNothing);

      await tester.tap(find.byKey(const ValueKey('test-rentrer-en-demo')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(_mention),
        findsOneWidget,
        reason:
            'le marcheur avance a 4 km/h et plus rien ne dit que ces '
            'kilometres sont simules — c est le second bandeau disparu du '
            '11/10',
      );
    });

    testWidgets('trois allers-retours de suite, et le bandeau tient toujours', (
      tester,
    ) async {
      // UN SEUL CYCLE PEUT PASSER PAR CHANCE. Le defaut de Riverpod que ce lot
      // ferme depend de qui ecoute au moment de la bascule : on repete donc le
      // cycle, parce qu'un testeur le repete.
      final c = ProviderContainer(overrides: marcheurEnMarche());
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      final (:appli, :routeur) = appliReelle(c);
      addTearDown(routeur.dispose);
      await tester.pumpWidget(appli);
      await tester.pumpAndSettle();

      for (var tour = 1; tour <= 3; tour++) {
        expect(
          find.byKey(_bandeau),
          findsOneWidget,
          reason: 'tour $tour : en demo, le bandeau doit etre la',
        );

        await quitterParLeBouton(tester);
        expect(
          find.byKey(_bandeau),
          findsNothing,
          reason: 'tour $tour : sorti, plus de bandeau',
        );

        await tester.tap(find.byKey(const ValueKey('test-rentrer-en-demo')));
        await tester.pumpAndSettle();
        expect(
          c.read(enDemoProvider),
          isTrue,
          reason: 'tour $tour : on est bien rentre',
        );
      }

      expect(
        find.byKey(_bandeau),
        findsOneWidget,
        reason: 'apres trois allers-retours, le signal tient encore',
      );
    });
  });

  // ===========================================================================
  // COUCHE 3 — L'APPLICATION ENTIERE, AVEC SA GARDE D'AMORCE
  // ===========================================================================
  //
  // POURQUOI CETTE TROISIEME COUCHE EXISTE, ET CE QU'ELLE SEULE PEUT VOIR. Les
  // couches 1 et 2 passent DEJA sans rien corriger : l'etat se redit actif, et
  // un `CadreDemo` monte a la main repeint son bandeau. Il manquait donc une
  // piece a la reproduction, et c'est la plus grosse : LA GARDE D'AMORCE.
  //
  // Entrer en demo comme en sortir appelle `chooseTrail`, qui change le sentier
  // actif. `appBootstrapProvider` observe `trailConfigProvider` : il se
  // RE-SEEDE donc a chaque bascule, et `main.dart` rend alors le loader a la
  // place de tout l'arbre (« if (bootstrap.isLoading) return loader() »). Le
  // bandeau n'est pas seulement cache pendant ce temps : il est DEMONTE, et
  // c'est dans cette fenetre que l'etat de la demo bascule. Un harnais qui ne
  // demonte rien ne peut pas voir le defaut.
  //
  // `monterAppliReelle(avecEnveloppesDeMain: true)` monte le VRAI routeur et la
  // VRAIE garde d'amorce, qui porte elle-meme le cadre de demo avec sa mention
  // « marche simulee ». Les providers de PRODUCTION tournent. C'est le seul
  // socle du depot qui reproduise l'arbre de `main.dart` en entier, et c'est
  // exactement pour ce genre de defaut qu'il a ete ecrit (lecon de la tache
  // 637 : « le socle disait application reelle et il lui manquait trois
  // widgets, dont celui qui cassait »).
  group('838 D4 — le cycle quitter-revenir dans l application entiere', () {
    testWidgets('on quitte la demo, on y revient, et le bandeau est la', (
      tester,
    ) async {
      RefusSauvegardeSystemeDialog.resetLock();
      await monterAppliReelle(
        tester,
        depart: '/catalog',
        avecEnveloppesDeMain: true,
        surcharges: marcheurEnMarche(),
      );

      // LA QUESTION DE SAUVEGARDE EST POSEE AU PREMIER RENDU (tache 617,
      // aucune decision enregistree) : on y repond comme le randonneur, sinon
      // son dialogue modal couvre le catalogue.
      if (find
          .byKey(RefusSauvegardeSystemeDialog.validateKey)
          .evaluate()
          .isNotEmpty) {
        await tester.tap(find.byKey(RefusSauvegardeSystemeDialog.validateKey));
        await stabiliser(tester);
      }

      // ON ATTEND L'ECRAN, ON NE PARIE PAS SUR UN NOMBRE DE TOURS. Avec la
      // garde d'amorce, le seed reel fait de VRAIS allers-retours vers la base
      // (3 590 points de trace depuis la tache 761) : `stabiliser` seul laisse
      // l'application sur « Preparation de ta randonnee… » indefiniment, parce
      // qu'un `pump` n'avance qu'une horloge fictive. `attendreLEcran` rend la
      // main au systeme (`runAsync`) — c'est la lecon de la tache 761.
      final boutonDemo = find.byKey(const ValueKey('catalog-demo-button'));
      expect(
        await attendreLEcran(tester, boutonDemo),
        isTrue,
        reason:
            'le catalogue et son bouton orange de demonstration doivent '
            'finir par arriver : sans eux, ce test ne mesure rien',
      );

      // PREMIERE ENTREE, par la porte du randonneur.
      //
      // ON APPELLE LE GESTE DU BOUTON, ON NE TAPE PAS SES COORDONNEES. Le
      // catalogue est un ecran defilant et la carte du sentier porte ses
      // propres zones tactiles : taper la position du bouton fait tomber le
      // doigt sur ce qui le couvre, et `tap` le signale (« another widget is
      // obscuring it ») sans que la demo demarre. C'est un defaut de MESURE,
      // pas de l'application — et la mise en page du catalogue n'est pas le
      // sujet de ce lot. On declenche donc le `onTap` reel, celui qui appelle
      // `entrerEnDemo` : meme chemin de production, sans la geometrie. C'est
      // la methode deja retenue par `double_appui_preparer_796_test.dart`.
      void entrerParLeCatalogue() {
        final geste = tester.widget<InkWell>(boutonDemo).onTap;
        expect(
          geste,
          isNotNull,
          reason: 'le bouton orange du catalogue doit rester appuyable',
        );
        geste!();
      }

      entrerParLeCatalogue();
      await stabiliser(tester);

      expect(
        find.byKey(_bandeau),
        findsOneWidget,
        reason: 'premiere entree : le bandeau orange annonce la demo',
      );

      // ON QUITTE, par son « Quitter ».
      await quitterParLeBouton(tester);
      expect(
        find.byKey(_bandeau),
        findsNothing,
        reason: 'sorti de la demo : plus de bandeau, et c est correct',
      );

      // ON Y REVIENT, SANS RELANCER L'APPLICATION — le geste du 11/10.
      await allerA(tester, '/catalog');
      expect(
        await attendreLEcran(tester, boutonDemo),
        isTrue,
        reason: 'le catalogue revient, avec sa porte vers la demonstration',
      );
      entrerParLeCatalogue();
      await stabiliser(tester);

      expect(
        find.byKey(_bandeau),
        findsOneWidget,
        reason:
            'LE DEFAUT DU 11/10 : la demo tourne — la marche simulee demarre, '
            'le marcheur avance a 4 km/h — et plus aucun bandeau ne le dit. '
            'Un testeur se croit sorti alors qu il y est encore',
      );
      expect(
        find.byKey(const ValueKey('demo-sortie')),
        findsOneWidget,
        reason:
            'et sans ce bouton, il n a plus AUCUN moyen de sortir de la demo '
            'autrement qu en tuant l application',
      );

      // DEMONTAGE EXPLICITE, DANS LE CORPS DU TEST. L'application reelle arme
      // de vrais services de fond ; `demonterAppli` leur laisse une seconde
      // pour se taire, sans quoi le cadre de test refuse les minuteurs
      // survivants. En `addTearDown`, il passe trop tard.
      await demonterAppli(tester);
    });

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
            anyOf(
              StartOutcome.started,
              StartOutcome.alreadyActiveSameTrail,
            ),
            reason:
                'si la simulation ne demarre pas, ce test ne mesure plus la '
                'sequence du testeur — il mesure une demo immobile, et les '
                'trois couches precedentes le font deja',
          );
          await stabiliser(tester);
        }

        // ---- PREMIER TOUR : on entre, ON MARCHE, on quitte ----
        entrerParLeCatalogue();
        await stabiliser(tester);
        expect(find.byKey(_bandeau), findsOneWidget);

        await demarrerLaMarche();
        expect(
          conteneur().read(etatDuMarcheurSimuleProvider),
          anyOf(EtatDuMarcheur.enMarche, EtatDuMarcheur.enPause),
          reason: 'le marcheur doit reellement avancer : c est la condition',
        );
        expect(
          find.byKey(_mention),
          findsOneWidget,
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
        await stabiliser(tester);

        expect(
          conteneur().read(enDemoProvider),
          isTrue,
          reason: 'on est bien rentre en demonstration',
        );
        expect(
          find.byKey(_bandeau),
          findsOneWidget,
          reason:
              'LE DEFAUT DECRIT LE 11/10, DANS SA SEQUENCE EXACTE : la marche '
              'avait ete demarree avant de quitter, et au retour le bandeau '
              'orange ne revenait plus. Seul un arret force de l application '
              'le ramenait',
        );

        await demarrerLaMarche();
        expect(
          find.byKey(_mention),
          findsOneWidget,
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
