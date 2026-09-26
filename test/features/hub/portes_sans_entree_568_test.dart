import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/routing/app_router.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/packs/presentation/pack_store_screen.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Q4 (tache 568, LOT Q) — TROIS FONCTIONS ENTIERES SANS AUCUNE PORTE D ENTREE.
///
/// LE CONSTAT, mesure sur 708b82c :
///  (a) L'ecran d'URGENCE (`/emergency` : 112, secours regionaux du sentier,
///      contacts personnels, position GPS) n'avait AUCUNE porte : zero
///      `push('/emergency')` ni `go('/emergency')` dans tout `lib/`. La route
///      existait, l'ecran etait ecrit, personne ne pouvait l'atteindre.
///  (b) La FICHE MEDICALE (`/health`) n'etait atteignable QUE depuis cet ecran
///      inatteignable (`emergency_screen.dart` l.184, unique porte). Une
///      fonction derriere une fonction fermee.
///  (c) La BOUTIQUE DE CARTES HORS LIGNE (`PackStoreScreen`, `PackCard`,
///      `pack_providers.dart`) n'avait MEME PAS DE ROUTE declaree.
///
/// DECISION DE CHRIS DU 26/09 10:29, verbatim : « ca doit faire partie de la
/// prepa, on ne demarre pas un trek sans avoir rempli sa fiche medicale et lu
/// les conseils pour qu'elle soit applicable sur le sentier ». La fiche medicale
/// devient donc une CARTE DE LA PREPARATION (gratuite, hors rando) — le SOS
/// lui-meme reste au terrain paye (#99410), mais il recoit enfin sa porte
/// visible en rando.
///
/// TOUS CES TESTS ONT ETE ECRITS ROUGES : aucune des trois portes n'existait, et
/// la route des packs n'existait pas du tout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String trailId = testTrailConfig.id;

  // ==========================================================================
  // (c) LA ROUTE QUI N EXISTAIT PAS
  // ==========================================================================
  group('Q4c — la boutique de cartes hors ligne a enfin une ROUTE', () {
    GoRoute trailRoute() => appRouter.configuration.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == '/trail/:id');

    test('/trail/:id/packs est declaree et nommee', () {
      final sous = trailRoute().routes.whereType<GoRoute>();
      final packs = sous.where((r) => r.path == 'packs');
      expect(
        packs,
        hasLength(1),
        reason: 'PackStoreScreen etait ecrit, teste, et sans route : un ecran '
            'qu aucune URL ne designe est un ecran mort',
      );
      expect(packs.first.name, 'trail-packs');
    });

    testWidgets('la route construit bien la boutique de packs', (tester) async {
      final router = GoRouter(
        initialLocation: '/trail/$trailId/packs',
        routes: appRouter.configuration.routes,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [trailConfigProvider.overrideWithValue(testTrailConfig)],
          child: TranslationProvider(
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PackStoreScreen), findsOneWidget);
    });
  });

  // ==========================================================================
  // (a) + (b) + (c) LES PORTES D ENTREE DU COCKPIT
  // ==========================================================================
  group('Q4 — les portes d entree du cockpit', () {
    /// Routes REELLES visees par les nouvelles portes, plus les cibles deja
    /// cablees (pour qu aucun tap ne casse la navigation).
    Widget wrap({
      required Widget child,
      List<Override> overrides = const [],
    }) {
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(path: '/home', builder: (_, __) => child),
          GoRoute(
            path: '/emergency',
            builder: (_, __) => const Scaffold(body: Text('URGENCE_CIBLE')),
          ),
          GoRoute(
            path: '/health',
            builder: (_, __) => const Scaffold(body: Text('FICHE_CIBLE')),
          ),
          GoRoute(path: '/map', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/journal', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/profile', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/settings', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/training', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/accommodations-nearby',
            builder: (_, __) => const SizedBox(),
          ),
          GoRoute(
            path: '/trail/:id',
            builder: (_, __) => const SizedBox(),
            routes: [
              for (final p in <String>[
                'feasibility',
                'itinerary',
                'planning',
                'calendar',
                'nuitees',
                'transport',
                'shop',
                'summary',
                'checklist',
                'tips',
                'adjust',
                'weather',
                'fire-risk',
              ])
                GoRoute(path: p, builder: (_, __) => const SizedBox()),
              GoRoute(
                path: 'packs',
                builder: (_, __) => const Scaffold(body: Text('PACKS_CIBLE')),
              ),
            ],
          ),
        ],
      );
      return ProviderScope(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          ...overrides,
        ],
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    Override trekWith(TrackingSessionStatus status) =>
        trekSessionManagerProvider.overrideWith(
          () => _FakeTrek(TrackingSessionState(status: status)),
        );

    Override lifecycleWith(TrekLifecycleState state) =>
        currentTrailSummaryProvider.overrideWith(
          (ref) async =>
              TrekSummary(config: ref.watch(trailConfigProvider), state: state),
        );

    /// Le cockpit sur une surface TRES haute : le [ListView] monte alors toutes
    /// ses sections d'un coup (sinon les cartes sous la ligne de flottaison ne
    /// sont pas construites, donc introuvables).
    Future<void> pumpCockpit(
      WidgetTester tester, {
      TrackingSessionStatus status = TrackingSessionStatus.idle,
      TrekLifecycleState? lifecycle,
    }) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        wrap(
          child: const HubScreen(),
          overrides: [
            trekWith(status),
            if (lifecycle != null) lifecycleWith(lifecycle),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Q4b — la FICHE MEDICALE est une carte de la PREPARATION, atteignable '
      'hors rando et sans achat',
      (tester) async {
        await pumpCockpit(tester);

        expect(
          find.text(t.hub.cards.health),
          findsOneWidget,
          reason: 'decision Chris : « ca doit faire partie de la prepa »',
        );

        await tester.tap(find.text(t.hub.cards.health));
        await tester.pumpAndSettle();
        expect(
          find.text('FICHE_CIBLE'),
          findsOneWidget,
          reason: 'la carte ouvre bien /health (et non un cul-de-sac)',
        );
      },
    );

    testWidgets(
      'Q4c — la BOUTIQUE DE CARTES HORS LIGNE a une carte de preparation qui '
      'ouvre sa route',
      (tester) async {
        await pumpCockpit(tester);

        expect(find.text(t.hub.cards.packs), findsOneWidget);
        await tester.tap(find.text(t.hub.cards.packs));
        await tester.pumpAndSettle();
        expect(find.text('PACKS_CIBLE'), findsOneWidget);
      },
    );

    testWidgets(
      'Q4a — l ECRAN D URGENCE a enfin une porte, dans la section Randonner',
      (tester) async {
        await pumpCockpit(tester, status: TrackingSessionStatus.recording);

        expect(
          find.text(t.hub.cards.emergency),
          findsOneWidget,
          reason: 'zero push(/emergency) existait dans tout lib/ : la fonction '
              'entiere etait inatteignable',
        );

        await tester.tap(find.text(t.hub.cards.emergency));
        await tester.pumpAndSettle();
        expect(find.text('URGENCE_CIBLE'), findsOneWidget);
      },
    );

    testWidgets(
      'Q4a — la porte d urgence ne s affiche QU EN RANDO (le terrain paye '
      'garde son perimetre, decision #99410)',
      (tester) async {
        await pumpCockpit(tester); // phase preparation
        expect(find.text(t.hub.cards.emergency), findsNothing);
      },
    );

    testWidgets(
      'la fiche medicale reste atteignable APRES le trek aussi (la prepa est '
      'un accordeon, jamais une section qui disparait)',
      (tester) async {
        await pumpCockpit(tester, lifecycle: TrekLifecycleState.completed);

        // La section n'est JAMAIS masquee : son en-tete est toujours la.
        expect(find.text(t.hub.sections.prepare), findsWidgets);

        // Repliee, on la deplie d'un tap ; deja depliee, on n'y touche pas.
        if (find.text(t.hub.cards.health).evaluate().isEmpty) {
          await tester.tap(find.text(t.hub.sections.prepare).first);
          await tester.pumpAndSettle();
        }
        expect(
          find.text(t.hub.cards.health),
          findsOneWidget,
          reason: 'la fiche medicale est une donnee de personne : elle reste '
              'atteignable dans toutes les phases du trek',
        );
      },
    );
  });
}

class _FakeTrek extends TrekSessionManagerNotifier {
  _FakeTrek(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
