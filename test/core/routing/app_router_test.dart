import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/routing/app_router.dart';

/// Tests du routeur GoRouter (E2.9b + HUB E07/AM-1 — bottom nav 5 onglets).
///
/// Couvre :
///   - structure de premier niveau (1 shell + routes racine) ;
///   - composition du StatefulShellRoute (5 branches Accueil/Carte/Etapes/
///     Journal/Plus, chemins, cles) ;
///   - PROGRAMME (parite GR20) atteint via /trail/:id/planning (sous-route),
///     l'ancienne route hors-shell /planning (orpheline) ayant ete retiree ;
///   - preservation des liens profonds existants (/trail/:id et sous-routes) ;
///   - navigation entre onglets via la NavigationBar ;
///   - restauration d'etat par onglet (IndexedStack natif).
void main() {
  group('AppRouter — structure', () {
    test('la route initiale est /my-treks (retablie, L7 avant-merge)', () {
      // StepWays LOT 3 Ph6 (L7) : l'entree demo '/nav-pilote' a ete RETIREE de
      // initialLocation ; l'entree de PROD « Mes treks » (/my-treks, accueil
      // « maison », StepWays LOT 2 — option A) est retablie. StepWays L8 : la
      // ROUTE /nav-pilote elle-meme a ete SUPPRIMEE du routeur (demonstrateur
      // jetable, fichier conserve dormant) — verifie plus bas (25 -> 24 routes).
      expect(appRouter.routeInformationProvider.value.uri.path, '/my-treks');
    });

    test('Ph4 hub-and-push : PLUS de StatefulShellRoute, tout en routes racine',
        () {
      // Big-bang (SPEC §5) : le StatefulShellRoute.indexedStack + AppShell est
      // SUPPRIME. Les 6 ex-onglets deviennent des routes racine plein ecran.
      final routes = appRouter.configuration.routes;
      expect(routes.whereType<StatefulShellRoute>(), isEmpty,
          reason: 'plus d onglets persistants (hub-and-push)');
      expect(routes.every((r) => r is GoRoute), isTrue,
          reason: 'toutes les routes de 1er niveau sont des GoRoute');
      // 6 ex-shell (my-treks/home/map/stages/journal/more) + 18 racines = 24.
      // StepWays L8 : la route de demo '/nav-pilote' a ete retiree (25 -> 24).
      expect(routes.whereType<GoRoute>().length, 24);
    });

    test('les 6 ex-onglets sont desormais des routes racine', () {
      final paths = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      // Les 6 ex-shell, EN TETE (ordre de declaration), puis les racines.
      expect(paths.take(6).toList(),
          ['/my-treks', '/home', '/map', '/stages', '/journal', '/more']);
      // Les racines historiques suivent, inchangees.
      expect(paths.skip(6).toList(), [
        '/trails',
        '/trail/:id',
        '/group/:id',
        '/follow/:code',
        '/catalog',
        '/trail-selection',
        '/goodies',
        '/booking',
        '/accommodations-nearby',
        '/emergency',
        // E57 (LOT D/D1) : fiche infos sante LOCAL ONLY (via Urgence E29).
        '/health',
        '/signalement',
        '/training',
        '/onboarding',
        '/no-data',
        '/settings',
        '/consent',
        '/profile',
        // StepWays L8 : la route de demo '/nav-pilote' (ecran-pilote refonte nav,
        // hors-shell) a ete RETIREE du routeur (fichier conserve dormant).
      ]);
    });

    test('les routes racine sont nommees correctement', () {
      final names = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toList();
      expect(names, [
        'my-treks',
        'home',
        'map',
        'stages',
        'journal',
        'more',
        'trails',
        'trail-detail',
        'group',
        'follow',
        'catalog',
        'trail-selection',
        'goodies',
        'booking',
        'accommodations-nearby',
        'emergency',
        'health',
        'signalement',
        'training',
        'onboarding',
        'no-data',
        'settings',
        'consent',
        'profile',
        // StepWays L8 : 'nav-pilote' retiree (route de demo supprimee).
      ]);
    });
  });

  group('AppRouter — hub-and-push (ex-onglets en routes racine)', () {
    GoRoute rootRoute(String path) => appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == path);

    test('les 6 ex-onglets resolvent le bon ecran (nom de route)', () {
      expect(rootRoute('/my-treks').name, 'my-treks');
      expect(rootRoute('/home').name, 'home');
      expect(rootRoute('/map').name, 'map');
      expect(rootRoute('/stages').name, 'stages');
      expect(rootRoute('/journal').name, 'journal');
      expect(rootRoute('/more').name, 'more');
    });

    test('/stages conserve sa sous-route /stages/:id', () {
      final stagesRoute = rootRoute('/stages');
      expect(stagesRoute.routes.length, 1);
      expect((stagesRoute.routes.first as GoRoute).path, ':id');
      expect((stagesRoute.routes.first as GoRoute).name, 'stage-by-id');
    });

    test('/home (cockpit) et /my-treks (maison) sont 2 routes racine distinctes',
        () {
      // Ex-branche Accueil (my-treks + home) : desormais 2 racines separees.
      expect(rootRoute('/my-treks').name, 'my-treks');
      expect(rootRoute('/home').name, 'home');
    });
  });

  group('AppRouter — liens profonds preserves', () {
    GoRoute trailRoute() => appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/trail/:id');

    test('la route /trail/:id conserve ses 24 sous-routes (+ faisabilite L4)',
        () {
      // +1 : 'guides' (E33/E34 LOT D/D2, feature Guides villes cablee).
      // +1 : 'recap' (PARITE GR20 LOT 3 #99433, recap « Mon aventure »).
      // +1 : 'itinerary' (PARITE GR20 #99433, deroule des etapes + fix nav).
      // +1 : 'nuitees' (PARITE GR20 #99460, assistant « Reserver vos nuits »).
      // +1 : 'calendar' (PARITE GR20 #99460, outil de DATES : depart/arrivee +
      //      calendrier des jours de marche/repos).
      // +1 : 'transport' (PARITE GR20 #99460, ecran « Aller & retour »
      //      data-driven : 2 onglets, endpoints resolus des donnees du sentier).
      // +1 : 'shop' (PARITE GR20 #99460, ecran « Ravitaillement » data-driven :
      //      commerces par etape, filtres par type, alerte de gap).
      // +1 : 'summary' (PARITE GR20 #99460, ecran « Synthese du plan »
      //      agregateur : programme, stats, nuitees, dates du sentier courant).
      // +1 : 'fire-risk' (PARITE GR20 #99460, ecran « Risque incendie »
      //      data-driven : niveaux derives meteo, reglementation + secours du
      //      sentier). Place apres 'weather' (meme feature).
      // +1 : 'import-gpx' (PARITE GR20 Import GPX, decision Skynet : clone GR20
      //      generalise data-driven de l'ecran ORPHELIN cote GR20 + point
      //      d'entree HUB). Place apres 'recap' (meme section « Apres »).
      // +4 : StepWays LOT 4 (faisabilite) — 'feasibility-quiz' (fallback
      //      questionnaire, l'ancien /feasibility), 'hiker-profile' (fiche
      //      info), 'walk-test' (test 6 min), 'past-hikes' (5 dernieres randos).
      //      Placees apres 'feasibility' (desormais le verdict objectif).
      final trail = trailRoute();
      expect(trail.routes.length, 24);
      final subPaths = trail.routes.map((r) => (r as GoRoute).path).toList();
      expect(subPaths, [
        'stage/:num',
        'map',
        'planning',
        'calendar',
        'transport',
        'shop',
        'summary',
        'itinerary',
        'checklist',
        'nuitees',
        'feasibility',
        'feasibility-quiz',
        'hiker-profile',
        'walk-test',
        'past-hikes',
        'tips',
        'journal',
        'diploma',
        'recap',
        'import-gpx',
        'feedback',
        'weather',
        'fire-risk',
        'guides',
      ]);
    });

    test('les sous-routes /trail/:id sont nommees correctement', () {
      final trail = trailRoute();
      final names = trail.routes.map((r) => (r as GoRoute).name).toList();
      expect(names, [
        'stage-detail',
        'trail-map',
        'trail-planning',
        'trail-calendar',
        'trail-transport',
        'trail-shop',
        'trail-summary',
        'trail-itinerary',
        'trail-checklist',
        'trail-nuitees',
        'trail-feasibility',
        'trail-feasibility-quiz',
        'trail-hiker-profile',
        'trail-walk-test',
        'trail-past-hikes',
        'trail-tips',
        'trail-journal',
        'trail-diploma',
        'trail-recap',
        'trail-import-gpx',
        'trail-feedback',
        'trail-weather',
        'trail-fire-risk',
        'trail-guides',
      ]);
    });

    test('la sous-route guides porte le detail /trail/:id/guides/:guideId', () {
      // E34 (LOT D/D2) : deeplink du detail d'un guide ville.
      final trail = trailRoute();
      final guides = trail.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == 'guides');
      expect(guides.routes.length, 1);
      final detail = guides.routes.first as GoRoute;
      expect(detail.path, ':guideId');
      expect(detail.name, 'trail-guide-detail');
    });
  });

  group('AppRouter — comportement', () {
    testWidgets('page erreur saffiche pour route inconnue', (tester) async {
      final testRouter = GoRouter(
        initialLocation: '/route-inexistante',
        routes: appRouter.configuration.routes,
        errorBuilder: (context, state) =>
            Scaffold(body: Center(child: Text('Erreur: ${state.uri.path}'))),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: testRouter));
      await tester.pumpAndSettle();

      expect(find.textContaining('Erreur'), findsOneWidget);
    });
  });

  // ===========================================================================
  // Cablage nav (#88246) : stub /trails neutralise + currentTrailGuard.
  // On manipule les drapeaux globaux du module (hasCompletedOnboarding /
  // hasDownloadedTrails) et on les restaure systematiquement apres chaque test.
  // ===========================================================================
  group('AppRouter — cablage nav (#88246)', () {
    late bool savedOnboarding;
    late bool savedDownloaded;

    setUp(() {
      savedOnboarding = hasCompletedOnboarding;
      savedDownloaded = hasDownloadedTrails;
      // Conditions nominales : onboarding fait, un sentier dispo.
      hasCompletedOnboarding = true;
      hasDownloadedTrails = true;
    });

    tearDown(() {
      hasCompletedOnboarding = savedOnboarding;
      hasDownloadedTrails = savedDownloaded;
    });

    test('la route /trails est une redirection (plus de builder de stub)', () {
      final trails = appRouter.configuration.routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == '/trails');
      expect(trails.redirect, isNotNull,
          reason: '/trails doit rediriger, pas afficher TrailListScreen');
    });

    test('onboarding non fait : toute route renvoie vers /onboarding', () {
      hasCompletedOnboarding = false;
      expect(redirectForPath('/catalog'), '/onboarding');
      expect(redirectForPath('/map'), '/onboarding');
      // /onboarding lui-meme n'est jamais redirige (pas de boucle).
      expect(redirectForPath('/onboarding'), isNull);
    });

    test('sans sentier dispo, les routes du shell renvoient au catalogue', () {
      hasDownloadedTrails = false;
      // StepWays LOT 2 (option A) : /my-treks (entree Accueil) + /home (cockpit)
      // sont dans la meme branche, tous deux proteges comme onglets coeur.
      for (final tab in [
        '/my-treks',
        '/home',
        '/map',
        '/stages',
        '/journal',
        '/more',
      ]) {
        expect(redirectForPath(tab), '/catalog',
            reason: '$tab (coeur) doit renvoyer au catalogue sans sentier');
      }
      // Une autre route hors-shell retombe sur l'ecran bloquant historique.
      expect(redirectForPath('/trail/test-trail'), '/no-data');
    });

    test('routes toujours accessibles : aucune redirection', () {
      hasDownloadedTrails = false; // meme sans sentier
      for (final p in [
        '/catalog',
        '/trail-selection',
        '/no-data',
        '/settings',
        '/profile',
        '/emergency',
        // E57 (LOT D/D1) : fiche sante = donnee perso, accessible sans sentier.
        '/health',
      ]) {
        expect(redirectForPath(p), isNull, reason: '$p doit rester accessible');
      }
    });

    test('avec sentier dispo + onboarding fait : navigation libre', () {
      // Conditions nominales (cf. setUp) -> shell atteignable directement.
      expect(redirectForPath('/my-treks'), isNull);
      expect(redirectForPath('/home'), isNull);
      expect(redirectForPath('/map'), isNull);
      expect(redirectForPath('/stages'), isNull);
    });

    // FIX LOT 0 (boucle /catalog -> /onboarding) : le guard lit la GLOBALE
    // `hasCompletedOnboarding` (pas le provider). `completeOnboarding` doit
    // desormais la passer a true ; alors le guard laisse passer /catalog.
    // Regression guard : globale true -> /catalog non redirige ; false -> boucle.
    test('LOT 0 — globale onboarding true : /catalog n est plus redirige', () {
      hasCompletedOnboarding = true;
      expect(redirectForPath('/catalog'), isNull,
          reason: 'onboarding termine -> /catalog accessible (fin de boucle)');
    });

    test('LOT 0 — globale onboarding false : /catalog renvoie a /onboarding', () {
      hasCompletedOnboarding = false;
      expect(redirectForPath('/catalog'), '/onboarding',
          reason: 'onboarding non termine -> retour /onboarding');
    });
  });

  // ===========================================================================
  // Contrat de navigation : StatefulShellRoute.indexedStack preserve l'etat de
  // chaque onglet. Teste sur un routeur minimal (ecrans-stub a compteur) pour
  // isoler le comportement de navigation, sans dependances (DB, providers).
  // ===========================================================================
  group('StatefulShellRoute.indexedStack — navigation + restauration', () {
    final mapKey = GlobalKey<NavigatorState>(debugLabel: 't-map');
    final stagesKey = GlobalKey<NavigatorState>(debugLabel: 't-stages');
    final moreKey = GlobalKey<NavigatorState>(debugLabel: 't-more');

    GoRouter buildStubRouter() {
      return GoRouter(
        initialLocation: '/tab-map',
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) => Scaffold(
              body: navigationShell,
              bottomNavigationBar: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (i) => navigationShell.goBranch(
                  i,
                  initialLocation: i == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.map), label: 'Carte'),
                  NavigationDestination(
                    icon: Icon(Icons.terrain),
                    label: 'Etapes',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.more_horiz),
                    label: 'Plus',
                  ),
                ],
              ),
            ),
            branches: [
              StatefulShellBranch(
                navigatorKey: mapKey,
                routes: [
                  GoRoute(
                    path: '/tab-map',
                    builder: (c, s) => const _CounterStub(label: 'Carte'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: stagesKey,
                routes: [
                  GoRoute(
                    path: '/tab-stages',
                    builder: (c, s) => const _CounterStub(label: 'Etapes'),
                  ),
                ],
              ),
              StatefulShellBranch(
                navigatorKey: moreKey,
                routes: [
                  GoRoute(
                    path: '/tab-more',
                    builder: (c, s) => const _CounterStub(label: 'Plus'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('la NavigationBar affiche les onglets et bascule de contenu', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildStubRouter()),
      );
      await tester.pumpAndSettle();

      // Onglet initial : Carte.
      expect(find.text('Ecran Carte'), findsOneWidget);

      // Bascule vers l'onglet Etapes.
      await tester.tap(find.text('Etapes'));
      await tester.pumpAndSettle();
      expect(find.text('Ecran Etapes'), findsOneWidget);

      // Bascule vers l'onglet Plus.
      await tester.tap(find.text('Plus'));
      await tester.pumpAndSettle();
      expect(find.text('Ecran Plus'), findsOneWidget);
    });

    testWidgets('l etat d un onglet est restaure apres bascule', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: buildStubRouter()),
      );
      await tester.pumpAndSettle();

      // Incremente le compteur de l'onglet Carte (0 -> 2).
      await tester.tap(find.byKey(const ValueKey('inc-Carte')));
      await tester.tap(find.byKey(const ValueKey('inc-Carte')));
      await tester.pumpAndSettle();
      expect(find.text('Carte: 2'), findsOneWidget);

      // Va sur Etapes puis revient sur Carte.
      await tester.tap(find.text('Etapes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carte'));
      await tester.pumpAndSettle();

      // L'etat (compteur a 2) est preserve : indexedStack garde la branche.
      expect(find.text('Carte: 2'), findsOneWidget);
    });
  });
}

/// Ecran-stub a compteur, pour observer la preservation d'etat par onglet.
class _CounterStub extends StatefulWidget {
  const _CounterStub({required this.label});

  final String label;

  @override
  State<_CounterStub> createState() => _CounterStubState();
}

class _CounterStubState extends State<_CounterStub> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Ecran ${widget.label}'),
            Text('${widget.label}: $_count'),
            IconButton(
              key: ValueKey('inc-${widget.label}'),
              icon: const Icon(Icons.add),
              onPressed: () => setState(() => _count++),
            ),
          ],
        ),
      ),
    );
  }
}
