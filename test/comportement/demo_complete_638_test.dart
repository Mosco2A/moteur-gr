import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/routing/home_location_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/pilote_demo.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/features/checklist/providers/checklist_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/cadre_demo.dart';
import 'package:moteur_gr/shared/widgets/grise_en_demo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 638 — LE LOT DEMO DU BUILD 8, BUG PAR BUG.
///
/// Les huit retours de test de Christophe du 30/09 que ce lot couvre, verbatim :
///   * BUG 1  (DEM-260930-1005) « il reste Mare a Mare Centre Demo gratuite en
///     doublon avec Essayer la demo » ;
///   * BUG 5a (DEM-260930-1012) « demo : on part sur le resultat de faisabilite
///     directement, sans avoir de vision des informations collectees pour le
///     faire » ;
///   * BUG 8  (DEM-260930-1014) « la demo de Mare a Mare ce doit etre la demo de
///     Mare a Mare, pas un truc avec 2 etapes !! » ;
///   * BUG 11 (DEM-260930-1020) « le bandeau du bas du mode demo cache une partie
///     de l appli. En haut un Quitter orange suffirait et il ne faut pas qu il
///     pete le visuel de la page » ;
///   * BUG 14 (DEM-260930-1022) « sac ne fonctionne pas en mode demo, laisser 2
///     menus et griser les autres sinon le comportement doit rester le meme » ;
///   * BUG 16 (DEM-260930-1024) « le bouton demarrer la rando doit etre accessible
///     en mode demo ! » ;
///   * BUG 18 (DEM-260930-1027) « Quand on quitte le mode demo, on doit mettre le
///     bouton quelque part pour pouvoir le relancer et dire ou il sera » — precise
///     le 30/09 a 10:30 : une case a cocher « Cacher le mode demo » au moment de
///     quitter, et la demo se retrouve alors dans Mon compte ;
///   * BUG 19 (DEM-260930-1028) « quand on quitte le mode demo, ca doit revenir a
///     Mes treks !!! la on se retrouve dans un mode demo batard ! on est toujours
///     en mode demo sans le savoir !!!! ».
class _FauxReseau extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ===========================================================================
  // BUG 1 — PLUS DE DOUBLON AU CATALOGUE
  // ===========================================================================
  group('BUG 1 — le sentier « Mare a Mare Centre Demo » n existe plus', () {
    test('il a disparu du catalogue, et de tout le depot', () {
      expect(
        TrailCatalog.byId('mare-a-mare-centre-demo'),
        isNull,
        reason: 'c etait le doublon : deux entrees pour la meme chose',
      );
      expect(TrailCatalog.ids, isNot(contains('mare-a-mare-centre-demo')));
    });

    test('il ne reste qu UNE seule entree nommee « Mare a Mare Centre »', () {
      final homonymes = TrailCatalog.all
          .where((c) => c.displayName == mareAMareCentreTrailConfig.displayName)
          .toList();
      expect(
        homonymes.length,
        1,
        reason:
            'le displayName identique des deux entrees etait le point ouvert '
            'du lot 634 : il se ferme en supprimant la seconde',
      );
    });

    test('et AUCUN sentier gratuit ne le remplace : on n a droit a rien', () {
      // DECISION DE CHRISTOPHE, scenario d acceptation du 29/09 14:17, verbatim :
      // « Donc la prochaine fois que j ouvre l application je n ai droit a
      // rien. » Le niveau gratuit du modele eco, c est la DEMO (bouton orange),
      // pas un sentier offert : un sentier gratuit au catalogue lui donnerait
      // droit a quelque chose sans qu il ait rien achete.
      expect(
        TrailCatalog.freeIds,
        isEmpty,
        reason: 'aucun sentier du catalogue ne doit etre jouable sans achat',
      );
      // LE MODELE, LUI, RESTE ECRIT ET TESTE : un prix nul fait un sentier
      // gratuit. Il n a simplement plus d instance livree, et c est un etat
      // legitime — achat_et_video_614_test pose la sienne pour le verifier.
      expect(
        TrailCatalog.all.every((c) => c.priceInStages > 0),
        isTrue,
        reason: 'tout sentier livre a un prix',
      );
    });
  });

  // ===========================================================================
  // BUG 8 — LA DEMO EST LE VRAI SENTIER, ENTIER
  // ===========================================================================
  group('BUG 8 — la demo porte le Mare a Mare Centre COMPLET', () {
    test('le sentier de la demo est le sentier reel, sept etapes', () {
      expect(kSentierDeDemo, mareAMareCentreTrailConfig.id);
      expect(mareAMareCentreTrailConfig.totalStages, 7);
      expect(mareAMareCentreTrailConfig.totalDistanceKm, 84.0);
    });

    testWidgets('entrer en demo SELECTIONNE ce sentier', (tester) async {
      late WidgetRef capture;
      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              capture = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      entrerEnDemo(capture);
      await tester.pump();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(SizedBox)),
      );
      expect(container.read(enDemoProvider), isTrue);
      expect(container.read(selectedTrailIdProvider), kSentierDeDemo);
      expect(container.read(trailConfigProvider).totalStages, 7);
    });

    test('la demo n accorde AUCUN droit sur ce sentier', () async {
      // LE GARDE-FOU DU LOT 601, MESURE SUR LE NOUVEAU PERIMETRE. La demo ouvre
      // maintenant un sentier PAYANT : la seule preuve qu'elle ne le debloque
      // pas, c'est que les trois verdicts de droit repondent la MEME chose en
      // demo et hors demo.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final prefs = await SharedPreferences.getInstance();
      final wallet = WalletStore(db: db, prefs: prefs);
      addTearDown(wallet.dispose);
      var enDemo = false;
      final iap = WalletIapService(
        walletStore: wallet,
        noAdsDao: db.noAdsDao,
        testMode: true,
      );
      addTearDown(iap.stopListening);
      final svc = MonetizationService(
        walletStore: wallet,
        entitlementsDao: db.trekEntitlementsDao,
        noAdsDao: db.noAdsDao,
        iapService: iap,
        connectivityMonitor: _FauxReseau(),
        prefs: prefs,
        stagesOf: (id) => 7,
        enDemo: () => enDemo,
      );
      await svc.load();

      final possedeAvant = await svc.ownsTrail(kSentierDeDemo);
      final realisableAvant = await svc.canRealizeTrail(kSentierDeDemo);
      final brideAvant = await svc.isDemoMode(kSentierDeDemo);

      enDemo = true;

      expect(await svc.ownsTrail(kSentierDeDemo), possedeAvant);
      expect(await svc.canRealizeTrail(kSentierDeDemo), realisableAvant);
      expect(await svc.isDemoMode(kSentierDeDemo), brideAvant);
      expect(possedeAvant, isFalse);
      expect(realisableAvant, isFalse);
    });
  });

  // ===========================================================================
  // BUG 11 — UNE PASTILLE EN HAUT, QUI NE MASQUE RIEN D ACTIF
  // ===========================================================================
  group('BUG 11 — la pastille de sortie ne masque rien d actif', () {
    /// Un ecran ORDINAIRE de l'application : barre de titre avec un retour a
    /// gauche, des actions a droite, un titre au centre — la forme que prennent
    /// les trente-neuf ecrans a `AppHeader` et les vingt-et-un a `AppBar`.
    Widget ecranType(ProviderContainer c) => UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: CadreDemo(
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              leading: IconButton(
                key: const ValueKey('test-retour'),
                icon: const Icon(Icons.arrow_back),
                onPressed: () {},
              ),
              title: const Text('Un ecran'),
              actions: [
                IconButton(
                  key: const ValueKey('test-action'),
                  icon: const Icon(Icons.home),
                  onPressed: () {},
                ),
              ],
            ),
            body: const Center(child: Text('contenu')),
          ),
        ),
      ),
    );

    // Les trois tailles de reference : iPhone SE, petit Android, Pixel 5.
    const tailles = <(String, Size)>[
      ('iPhone SE', Size(375, 667)),
      ('petit Android', Size(360, 640)),
      ('Pixel 5', Size(393, 851)),
    ];

    for (final (nom, taille) in tailles) {
      testWidgets(
        '$nom — la pastille ne recouvre ni le retour ni les actions',
        (tester) async {
          tester.view.physicalSize = taille;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final c = ProviderContainer();
          addTearDown(c.dispose);
          c.read(sessionDemoProvider.notifier).entrer();

          await tester.pumpWidget(ecranType(c));
          await tester.pump();

          final pastille = tester.getRect(
            find.byKey(const ValueKey('demo-sortie')),
          );
          final retour = tester.getRect(
            find.byKey(const ValueKey('test-retour')),
          );
          final action = tester.getRect(
            find.byKey(const ValueKey('test-action')),
          );

          expect(
            pastille.overlaps(retour),
            isFalse,
            reason:
                '$nom : la pastille recouvre le bouton RETOUR — un geste '
                'actif masque, c est exactement ce que le bug 11 reproche au '
                'bandeau du bas',
          );
          expect(
            pastille.overlaps(action),
            isFalse,
            reason: '$nom : la pastille recouvre une ACTION de l en-tete',
          );
          expect(
            pastille.width,
            lessThanOrEqualTo(kLargeurMaxPastilleDemo),
            reason:
                'la pastille est bornee en largeur, c est ce qui la tient '
                'loin des deux bords ou vivent les gestes',
          );
        },
      );

      testWidgets('$nom — la pastille ne DECALE aucun element', (tester) async {
        tester.view.physicalSize = taille;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final horsDemo = ProviderContainer();
        addTearDown(horsDemo.dispose);
        await tester.pumpWidget(ecranType(horsDemo));
        await tester.pump();
        final avant = tester.getRect(find.text('contenu'));
        final retourAvant = tester.getRect(
          find.byKey(const ValueKey('test-retour')),
        );

        final enDemo = ProviderContainer();
        addTearDown(enDemo.dispose);
        enDemo.read(sessionDemoProvider.notifier).entrer();
        await tester.pumpWidget(ecranType(enDemo));
        await tester.pump();

        expect(
          tester.getRect(find.text('contenu')),
          avant,
          reason:
              '$nom : le contenu de l ecran s est deplace — la pastille est '
              'PEINTE par-dessus, elle ne prend pas de place',
        );
        expect(
          tester.getRect(find.byKey(const ValueKey('test-retour'))),
          retourAvant,
        );
      });
    }

    testWidgets('plus de bandeau en bas, plus de cadre sur les bords', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();
      await tester.pumpWidget(ecranType(c));
      await tester.pump();

      expect(find.byKey(const ValueKey('demo-barre-simulation')), findsNothing);
      expect(find.byKey(const ValueKey('demo-cadre')), findsNothing);
      expect(find.byKey(const ValueKey('demo-rien-ne-compte')), findsNothing);
    });
  });

  // ===========================================================================
  // BUG 14 — ACTIF ET IDENTIQUE, OU GRISE ET VISIBLEMENT INDISPONIBLE
  // ===========================================================================
  group('BUG 14 — dans le sac, la coche MARCHE et n ecrit rien', () {
    late AppDatabase db;
    late ProviderContainer c;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
    });

    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<void> pret() =>
        Future<void>.delayed(const Duration(milliseconds: 250));

    test('cocher un article change bien l etat a l ecran, en demo', () async {
      c.read(sessionDemoProvider.notifier).entrer();
      c.read(checklistProvider);
      await pret();

      final etat = c.read(checklistProvider);
      expect(etat.items, isNotEmpty, reason: 'le sac se REMPLIT en demo');
      final article = etat.items.first.template.id;
      expect(c.read(checklistProvider).checkedCount, 0);

      await c.read(checklistProvider.notifier).toggle(article);

      expect(
        c.read(checklistProvider).checkedCount,
        1,
        reason:
            'LE DEFAUT DU BUG 14 : la case ne bougeait pas d un pixel. Le '
            'comportement doit rester le meme qu en reel',
      );
      expect(c.read(checklistProvider).items.first.isChecked, isTrue);
    });

    test('... et RIEN n atteint la base', () async {
      c.read(sessionDemoProvider.notifier).entrer();
      c.read(checklistProvider);
      await pret();

      final article = c.read(checklistProvider).items.first.template.id;
      await c.read(checklistProvider.notifier).toggle(article);

      final lignes = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      expect(
        lignes,
        isEmpty,
        reason:
            'ni les 84 lignes du template, ni la coche : le sac de demo vit '
            'en memoire, et le vrai sac du randonneur reste intact',
      );
    });

    test('hors demo, la coche est PERSISTEE comme avant', () async {
      c.read(checklistProvider);
      await pret();
      final article = c.read(checklistProvider).items.first.template.id;
      await c.read(checklistProvider.notifier).toggle(article);

      final lignes = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      expect(lignes, isNotEmpty);
      expect(lignes.firstWhere((l) => l.itemId == article).isChecked, isTrue);
    });

    test('les ecritures NON retenues restent barrees en demo', () async {
      // La regle a deux branches : actif-identique (la coche) ou grise. Ce qui
      // est grise doit AUSSI rester barre cote provider — le grisage est le
      // premier rempart, la barriere est le dernier.
      c.read(sessionDemoProvider.notifier).entrer();
      c.read(checklistProvider);
      await pret();

      final notifier = c.read(checklistProvider.notifier);
      await notifier.addCustomItem('backpack', 'Article de demo', 500);
      await notifier.resetAll();

      final lignes = await ChecklistDao(db).getByTrailId(testTrailConfig.id);
      expect(lignes, isEmpty);
    });
  });

  group('BUG 14 — une fonction grisee se VOIT, et elle DIT pourquoi', () {
    Widget avecBouton(ProviderContainer c, VoidCallback onTap) =>
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: GriseEnDemo(
                child: ElevatedButton(
                  key: const ValueKey('test-ecriture'),
                  onPressed: onTap,
                  child: const Text('Ecrire'),
                ),
              ),
            ),
          ),
        );

    testWidgets('hors demo, le bouton repond normalement', (tester) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      var appuis = 0;
      await tester.pumpWidget(avecBouton(c, () => appuis++));
      await tester.tap(find.byKey(const ValueKey('test-ecriture')));
      await tester.pump();
      expect(appuis, 1);
    });

    testWidgets('en demo, il est grise, inerte, et il dit pourquoi', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();
      var appuis = 0;
      await tester.pumpWidget(avecBouton(c, () => appuis++));
      await tester.pump();

      // GRISE : l'opacite le dit a l'oeil.
      final opacite = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(opacite.opacity, kOpaciteGriseeDemo);

      await tester.tap(find.byKey(const ValueKey('test-ecriture')));
      await tester.pump();

      expect(
        appuis,
        0,
        reason:
            'JAMAIS un bouton qui a l air actif et ne fait rien : ici il a '
            'l air grise, et il est grise',
      );
      expect(
        find.text(t.demo.indisponible),
        findsOneWidget,
        reason: 'et il DIT pourquoi plutot que de rester muet',
      );
    });
  });

  // ===========================================================================
  // BUG 16 — DEMARRER LA RANDO EST ACTIF EN DEMO, ET IL SIMULE
  // ===========================================================================
  group('BUG 16 — le depart est actif en demo, et rien ne s ecrit', () {
    late AppDatabase db;
    late MonetizationService svc;
    var enDemoService = false;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final prefs = await SharedPreferences.getInstance();
      final wallet = WalletStore(db: db, prefs: prefs);
      addTearDown(wallet.dispose);
      final iap = WalletIapService(
        walletStore: wallet,
        noAdsDao: db.noAdsDao,
        testMode: true,
      );
      addTearDown(iap.stopListening);
      enDemoService = false;
      svc = MonetizationService(
        walletStore: wallet,
        entitlementsDao: db.trekEntitlementsDao,
        noAdsDao: db.noAdsDao,
        iapService: iap,
        connectivityMonitor: _FauxReseau(),
        prefs: prefs,
        stagesOf: (id) => 7,
        enDemo: () => enDemoService,
      );
      await svc.load();
    });

    tearDown(() => db.close());

    ProviderContainer conteneur() => ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monetizationServiceProvider.overrideWithValue(svc),
        trailConfigProvider.overrideWithValue(mareAMareCentreTrailConfig),
      ],
    );

    test('hors demo, un sentier non achete est REFUSE (inchange)', () async {
      final c = conteneur();
      addTearDown(c.dispose);
      final issue = await c
          .read(trekSessionManagerProvider.notifier)
          .ensureSingleActiveThenStart(
            kSentierDeDemo,
            resolve: (_) async => ActiveTrekConflictChoice.cancel,
          );
      expect(issue, StartOutcome.purchaseRequired);
    });

    test('en demo, le depart PART — et il ne touche pas la base', () async {
      final c = conteneur();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();
      enDemoService = true;

      final issue = await c
          .read(trekSessionManagerProvider.notifier)
          .ensureSingleActiveThenStart(
            kSentierDeDemo,
            resolve: (_) async => ActiveTrekConflictChoice.cancel,
          );

      expect(
        issue,
        StartOutcome.started,
        reason:
            'LE BUG 16 : « le bouton demarrer la rando doit etre accessible '
            'en mode demo ! »',
      );
      expect(
        c.read(trekSessionManagerProvider).status,
        TrackingSessionStatus.recording,
        reason:
            'la randonnee simulee est bien en cours : le cockpit, la carte '
            'et le journal ont de quoi se remplir',
      );
      expect(
        await db.trekSessionsDao.findActiveSessions(),
        isEmpty,
        reason: 'la session simulee vit EN MEMOIRE : rien en base',
      );
      expect(
        await svc.canRealizeTrail(kSentierDeDemo),
        isFalse,
        reason:
            'et le droit n a pas bouge : la demo montre, elle ne debloque '
            'rien',
      );
    });

    test('la simulation avance d etape sans rien ecrire', () async {
      final c = conteneur();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();
      enDemoService = true;

      final notifier = c.read(trekSessionManagerProvider.notifier);
      await notifier.ensureSingleActiveThenStart(
        kSentierDeDemo,
        resolve: (_) async => ActiveTrekConflictChoice.cancel,
      );
      notifier.recordStageCompleted('mam-c-s1');

      expect(
        c.read(trekSessionManagerProvider).session?.completedStages,
        contains('mam-c-s1'),
        reason:
            'l etape est marchee A L ECRAN — c est ce que la simulation '
            'doit montrer',
      );
      expect(
        await db.trekSessionsDao.findActiveSessions(),
        isEmpty,
        reason: 'et elle ne compte pas : pas d etape gagnee, rien en base',
      );
    });
  });

  // ===========================================================================
  // BUG 18 — LE BOUTON RESTE TROUVABLE, ET LE RANDONNEUR CHOISIT OU
  // ===========================================================================
  group('BUG 18 — ou retrouver la demo apres l avoir quittee', () {
    test('par defaut, le bouton est VISIBLE au catalogue', () async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      expect(
        c.read(boutonDemoCacheProvider),
        isFalse,
        reason:
            'aucun drapeau « deja vue » ne cache le bouton : il est en tete '
            'du catalogue avant ET apres une demo',
      );
    });

    test('le reglage « cacher » se pose, se relit, et se defait', () async {
      final premier = ProviderContainer();
      await premier.read(boutonDemoCacheProvider.notifier).definir(true);
      expect(premier.read(boutonDemoCacheProvider), isTrue);
      premier.dispose();

      // IL EST PERSISTANT — contrairement a l'etat de la demo, qui ne vit qu'en
      // memoire. C'est un reglage d'affichage, demande par Christophe le 30/09 a
      // 10:30, et il survit a la fermeture de l'application.
      final second = ProviderContainer();
      addTearDown(second.dispose);
      second.read(boutonDemoCacheProvider);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(second.read(boutonDemoCacheProvider), isTrue);

      // ET IL EST REVERSIBLE depuis Mon compte.
      await second.read(boutonDemoCacheProvider.notifier).definir(false);
      expect(second.read(boutonDemoCacheProvider), isFalse);
    });

    testWidgets('le dialogue de sortie porte la case et dit OU la retrouver', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: CadreDemo(child: Scaffold(body: Text('ecran'))),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('demo-sortie')));
      await tester.pumpAndSettle();

      // Case DECOCHEE : la demo reste en tete du catalogue, et le message le dit.
      expect(find.text(t.demo.sortieEnTeteCatalogue), findsOneWidget);
      expect(find.text(t.demo.cacherLabel), findsOneWidget);

      // Case COCHEE : le message change, parce que l endroit change.
      await tester.tap(find.byKey(const ValueKey('demo-sortie-cacher')));
      await tester.pumpAndSettle();
      expect(find.text(t.demo.sortieDansMonCompte), findsOneWidget);
      expect(
        find.text(t.demo.sortieEnTeteCatalogue),
        findsNothing,
        reason:
            'un message qui annonce autre chose que ce que le reglage va '
            'faire serait un mensonge',
      );
    });

    testWidgets('confirmer avec la case cochee cache le bouton', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: CadreDemo(child: Scaffold(body: Text('ecran'))),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('demo-sortie')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-sortie-cacher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-sortie-confirmer')));
      await tester.pumpAndSettle();

      expect(c.read(enDemoProvider), isFalse);
      expect(c.read(boutonDemoCacheProvider), isTrue);
    });

    testWidgets('annuler ne quitte pas la demo et ne cache rien', (
      tester,
    ) async {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(sessionDemoProvider.notifier).entrer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: CadreDemo(child: Scaffold(body: Text('ecran'))),
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('demo-sortie')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-sortie-cacher')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('demo-sortie-annuler')));
      await tester.pumpAndSettle();

      expect(c.read(enDemoProvider), isTrue);
      expect(c.read(boutonDemoCacheProvider), isFalse);
    });
  });

  // ===========================================================================
  // BUG 19 — QUITTER = SORTIE COMPLETE ET ATOMIQUE
  // ===========================================================================
  group('BUG 19 — quitter la demo n y laisse RIEN', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() => db.close());

    /// Une application MINIMALE avec deux ecrans routes, pour mesurer le retour
    /// a « Mes treks » : c'est la moitie du bug 19 (« ca doit revenir a Mes
    /// treks !!! »), et elle ne se mesure pas sans routeur.
    Future<WidgetRef> monter(WidgetTester tester, ProviderContainer c) async {
      late WidgetRef capture;
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                capture = ref;
                return const Scaffold(body: Text('COCKPIT'));
              },
            ),
          ),
          GoRoute(
            path: HomeLocations.maison,
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                capture = ref;
                return const Scaffold(body: Text('MES TREKS'));
              },
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return capture;
    }

    testWidgets(
      'entrer, simuler une etape, quitter : etat demo nul, sentier restaure, '
      'ecran Mes treks',
      (tester) async {
        var enDemoService = false;
        late MonetizationService svc;
        await tester.runAsync(() async {
          final prefs = await SharedPreferences.getInstance();
          final wallet = WalletStore(db: db, prefs: prefs);
          addTearDown(wallet.dispose);
          final iap = WalletIapService(
            walletStore: wallet,
            noAdsDao: db.noAdsDao,
            testMode: true,
          );
          addTearDown(iap.stopListening);
          svc = MonetizationService(
            walletStore: wallet,
            entitlementsDao: db.trekEntitlementsDao,
            noAdsDao: db.noAdsDao,
            iapService: iap,
            connectivityMonitor: _FauxReseau(),
            prefs: prefs,
            stagesOf: (id) => 7,
            enDemo: () => enDemoService,
          );
          await svc.load();
        });

        final c = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            monetizationServiceProvider.overrideWithValue(svc),
          ],
        );
        addTearDown(c.dispose);

        // L'ETAT D'AVANT : un autre sentier est selectionne.
        c.read(selectedTrailIdProvider.notifier).state = testTrailConfig.id;

        final ref = await monter(tester, c);
        expect(find.text('COCKPIT'), findsOneWidget);

        // ENTRER.
        entrerEnDemo(ref);
        enDemoService = true;
        await tester.pumpAndSettle();
        expect(c.read(enDemoProvider), isTrue);
        expect(c.read(selectedTrailIdProvider), kSentierDeDemo);

        // SIMULER : demarrer, puis marcher une etape.
        final trek = c.read(trekSessionManagerProvider.notifier);
        await tester.runAsync(
          () => trek.ensureSingleActiveThenStart(
            kSentierDeDemo,
            resolve: (_) async => ActiveTrekConflictChoice.cancel,
          ),
        );
        trek.recordStageCompleted('mam-c-s1');
        expect(
          c.read(trekSessionManagerProvider).status,
          TrackingSessionStatus.recording,
        );

        // QUITTER.
        await tester.runAsync(
          () =>
              quitterLaDemo(ref, context: tester.element(find.text('COCKPIT'))),
        );
        enDemoService = false;
        await tester.pumpAndSettle();

        // 1. L'ETAT DEMO EST NUL.
        expect(c.read(enDemoProvider), isFalse);
        expect(c.read(sessionDemoProvider).trailId, isNull);

        // 2. LA SIMULATION EST ARRETEE, ET ELLE N A RIEN LAISSE.
        expect(
          c.read(trekSessionManagerProvider).status,
          TrackingSessionStatus.idle,
          reason:
              'une simulation qui survit a la sortie, c est le « mode demo '
              'batard » du bug 19',
        );
        expect(c.read(trekSessionManagerProvider).session, isNull);
        expect(
          await tester.runAsync(() => db.trekSessionsDao.findActiveSessions()),
          isEmpty,
        );

        // 3. LE SENTIER D AVANT EST REVENU.
        expect(
          c.read(selectedTrailIdProvider),
          testTrailConfig.id,
          reason:
              'sans cela, « Mes treks » s ouvrait sur le sentier de la demo '
              '— on etait toujours en demo sans le savoir',
        );

        // 4. ON EST SUR MES TREKS.
        expect(find.text('MES TREKS'), findsOneWidget);
        expect(find.text('COCKPIT'), findsNothing);
      },
    );

    testWidgets('une VRAIE ecriture faite APRES la sortie est persistee', (
      tester,
    ) async {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
      addTearDown(c.dispose);

      final ref = await monter(tester, c);

      entrerEnDemo(ref);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => quitterLaDemo(ref, context: tester.element(find.text('COCKPIT'))),
      );
      await tester.pumpAndSettle();

      // LA PREUVE QUE LES BARRIERES SONT TOUTES LEVEES : cocher un article du
      // sac, apres la sortie, doit s ecrire normalement.
      final lignes = await tester.runAsync(() async {
        c.read(checklistProvider);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final article = c.read(checklistProvider).items.first.template.id;
        await c.read(checklistProvider.notifier).toggle(article);
        return (
          article,
          await ChecklistDao(db).getByTrailId(testTrailConfig.id),
        );
      });
      expect(lignes!.$2, isNotEmpty);
      expect(
        lignes.$2.firstWhere((l) => l.itemId == lignes.$1).isChecked,
        isTrue,
      );
    });

    testWidgets('les changements faits EN DEMO ne survivent pas a la sortie', (
      tester,
    ) async {
      final c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
      addTearDown(c.dispose);

      final ref = await monter(tester, c);
      entrerEnDemo(ref);
      await tester.pumpAndSettle();

      // Cocher un article PENDANT la demo (en memoire).
      await tester.runAsync(() async {
        c.read(checklistProvider);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final article = c.read(checklistProvider).items.first.template.id;
        await c.read(checklistProvider.notifier).toggle(article);
      });
      expect(c.read(checklistProvider).checkedCount, 1);

      await tester.runAsync(
        () => quitterLaDemo(ref, context: tester.element(find.text('COCKPIT'))),
      );
      await tester.pumpAndSettle();

      // Le sac est RELU depuis le telephone : la coche de demo a disparu.
      await tester.runAsync(() async {
        c.read(checklistProvider);
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      expect(
        c.read(checklistProvider).checkedCount,
        0,
        reason:
            'l etat d apres la sortie doit etre l etat exact d AVANT la '
            'demo',
      );
    });
  });

  // ===========================================================================
  // BUG 5a — LA DEMO MONTRE LA COLLECTE AVANT LE VERDICT
  // ===========================================================================
  group('BUG 5a — les cinq langues nomment la collecte de la faisabilite', () {
    test('les libelles du recapitulatif existent partout', () {
      for (final langue in AppLocale.values) {
        final d = langue.buildSync().demo;
        for (final libelle in [
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
      }
    });

    test('la section est POSEE AVANT la reponse, et seulement en demo', () {
      // MESURE SUR LA SOURCE, et c'est assume : monter l'ecran de faisabilite
      // demande la base, les etapes seedees, le profil, le programme et la trace
      // GPX — six providers asynchrones pour verifier un ORDRE de deux widgets.
      // Ce que l'on doit garantir tient en deux faits verifiables ici : la
      // section n'existe qu'en demo, et elle passe avant le verdict.
      final source = File(
        'lib/features/feasibility/presentation/trek_feasibility_screen.dart',
      ).readAsStringSync();
      final garde = source.indexOf('if (ref.watch(enDemoProvider))');
      final collecte = source.indexOf('_CollecteDeLaDemo(assessment:');
      final reponse = source.indexOf('_LaReponse(assessment: assessment)');
      expect(
        garde,
        greaterThan(-1),
        reason: 'la section est gardee par la demo',
      );
      expect(collecte, greaterThan(garde));
      expect(
        collecte,
        lessThan(reponse),
        reason:
            'BUG 5a : « on part sur le resultat de faisabilite directement, '
            'sans avoir de vision des informations collectees » — la collecte '
            'passe AVANT',
      );
    });
  });
}
