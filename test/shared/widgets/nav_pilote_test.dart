import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/hub/presentation/nav_pilote_screen.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_header.dart';
import 'package:moteur_gr/shared/widgets/contextual_action_bar.dart';

/// Tests widget — ECRAN-PILOTE refonte nav StepWays (LOT 3, methode D2).
///
/// Couvre les 3 briques additives du pilote :
///   - [AppHeader] : titre + bouton Retour (tooltip) + bouton Accueil ;
///     l'Accueil route vers `/my-treks` (et ne quitte jamais l'app) ;
///   - [ContextualActionBar] : rend des ACTIONS (pas des onglets), avec une
///     action saillante (SOS) accentuee en `rougeUrgence` ;
///   - [NavPiloteScreen] : SOS PRESENT en MODE TREK (activeTrekIdProvider
///     non-null) et ABSENT hors mode trek (null) — parite securite AUDIT §M-2.
void main() {
  // ---------------------------------------------------------------------------
  // AppHeader (isole)
  // ---------------------------------------------------------------------------
  group('AppHeader', () {
    /// Monte l'AppHeader dans un routeur minimal : la route initiale a un
    /// bouton pour empiler une page qui porte l'AppHeader (donc `canPop` vrai
    /// -> Retour = pop). La cible `/my-treks` sert de cible au bouton Accueil.
    Widget wrapHeader({required Widget headerHost}) {
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (context, __) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/page'),
                  child: const Text('PUSH'),
                ),
              ),
            ),
          ),
          GoRoute(path: '/page', builder: (_, __) => headerHost),
          GoRoute(
            path: '/my-treks',
            builder: (_, __) => const Scaffold(body: Text('MY_TREKS_STUB')),
          ),
        ],
      );
      return ProviderScope(
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    testWidgets('rend le titre + boutons Retour et Accueil', (tester) async {
      await tester.pumpWidget(wrapHeader(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre pilote'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.text('Titre pilote'), findsOneWidget);
      // Bouton Retour (tooltip Slang) + bouton Accueil (tooltip Slang).
      expect(find.byTooltip(t.nav.back), findsOneWidget);
      expect(find.byTooltip(t.nav.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('le bouton Accueil route vers /my-treks (ne quitte pas l\'app)',
        (tester) async {
      await tester.pumpWidget(wrapHeader(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre pilote'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(t.nav.home));
      await tester.pumpAndSettle();
      expect(find.text('MY_TREKS_STUB'), findsOneWidget);
    });

    testWidgets('le bouton Retour depile (retour a l\'ecran precedent)',
        (tester) async {
      await tester.pumpWidget(wrapHeader(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Titre pilote'),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();
      expect(find.text('Titre pilote'), findsOneWidget);

      await tester.tap(find.byTooltip(t.nav.back));
      await tester.pumpAndSettle();
      // Retour a l'ecran de depart (le bouton PUSH est de nouveau visible).
      expect(find.text('PUSH'), findsOneWidget);
      expect(find.text('Titre pilote'), findsNothing);
    });

    testWidgets('showBack=false : pas de bouton Retour', (tester) async {
      await tester.pumpWidget(wrapHeader(
        headerHost: const Scaffold(
          appBar: AppHeader(title: 'Racine', showBack: false),
          body: SizedBox(),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PUSH'));
      await tester.pumpAndSettle();

      expect(find.byTooltip(t.nav.back), findsNothing);
      // Le bouton Accueil reste present (showHome defaut true).
      expect(find.byTooltip(t.nav.home), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // ContextualActionBar (isole)
  // ---------------------------------------------------------------------------
  group('ContextualActionBar', () {
    Widget wrapBar(List<ContextualAction> actions) {
      return TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            bottomNavigationBar: ContextualActionBar(actions: actions),
            body: const SizedBox(),
          ),
        ),
      );
    }

    testWidgets('rend les actions (labels visibles)', (tester) async {
      var tapped = '';
      await tester.pumpWidget(wrapBar([
        ContextualAction(
          icon: Icons.assignment_outlined,
          label: t.navPilote.prepare,
          onPressed: () => tapped = 'prepare',
        ),
        ContextualAction(
          icon: Icons.hiking,
          label: t.navPilote.hike,
          onPressed: () {},
        ),
        ContextualAction(
          icon: Icons.emoji_events_outlined,
          label: t.navPilote.after,
          onPressed: () {},
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text(t.navPilote.prepare), findsOneWidget);
      expect(find.text(t.navPilote.hike), findsOneWidget);
      expect(find.text(t.navPilote.after), findsOneWidget);
      // C'est une barre d'ACTIONS (BottomAppBar), pas une NavigationBar.
      expect(find.byType(BottomAppBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tester.tap(find.text(t.navPilote.prepare));
      expect(tapped, 'prepare');
    });

    testWidgets('barre vide -> rien (SizedBox.shrink)', (tester) async {
      await tester.pumpWidget(wrapBar(const []));
      await tester.pumpAndSettle();
      expect(find.byType(BottomAppBar), findsNothing);
    });

    testWidgets('action saillante SOS : accent rougeUrgence', (tester) async {
      await tester.pumpWidget(wrapBar([
        ContextualAction(
          icon: Icons.emergency,
          label: t.navPilote.sos,
          onPressed: () {},
          salient: true,
          color: AppTheme.rougeUrgence,
        ),
      ]));
      await tester.pumpAndSettle();

      expect(find.text(t.navPilote.sos), findsOneWidget);
      // La pastille saillante est un Material peint en rougeUrgence.
      final material = tester.widget<Material>(
        find.ancestor(
          of: find.byIcon(Icons.emergency),
          matching: find.byType(Material),
        ).first,
      );
      expect(material.color, AppTheme.rougeUrgence);
    });
  });

  // ---------------------------------------------------------------------------
  // NavPiloteScreen — SOS present/absent selon le mode trek
  // ---------------------------------------------------------------------------
  group('NavPiloteScreen (SOS mode trek)', () {
    /// Enveloppe le pilote dans un routeur minimal + overrides.
    Widget wrapPilote({List<Override> overrides = const []}) {
      final router = GoRouter(
        initialLocation: '/nav-pilote',
        routes: [
          GoRoute(path: '/nav-pilote', builder: (_, __) => const NavPiloteScreen()),
          // Cibles neutres pour ne casser aucune navigation au tap.
          GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/map', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/journal', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/catalog', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/training', builder: (_, __) => const SizedBox()),
          GoRoute(
            path: '/accommodations-nearby',
            builder: (_, __) => const SizedBox(),
          ),
          GoRoute(path: '/group/:id', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/feasibility', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/itinerary', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/planning', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/calendar', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/nuitees', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/transport', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/shop', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/summary', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/checklist', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/fire-risk', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/tips', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/guides', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/recap', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/import-gpx', builder: (_, __) => const SizedBox()),
          GoRoute(path: '/trail/:id/diploma', builder: (_, __) => const SizedBox()),
        ],
      );
      return ProviderScope(
        overrides: overrides,
        child: TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      );
    }

    /// Utilisateur sans pseudonyme (repli localise, evite toute PII en test).
    final userNull = authStateProvider.overrideWithValue(null);

    /// Etat de suivi idle (la HubTrekCard suit cet etat neutre).
    final trekIdle = trekSessionManagerProvider.overrideWith(
      () => _FakeTrekNotifier(const TrackingSessionState()),
    );

    /// Mode trek ON : un trek est actif|en pause (discriminant du SOS).
    Override activeTrek(String? trailId) =>
        activeTrekIdProvider.overrideWith((ref) async => trailId);

    /// Rend le pilote sur une surface tres haute pour monter toute la liste
    /// (barre d'actions comprise). Reinitialise a la fin du test.
    Future<void> pumpTall(
      WidgetTester tester, {
      required String? activeTrailId,
    }) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrapPilote(overrides: [
        userNull,
        trekIdle,
        activeTrek(activeTrailId),
      ]));
      await tester.pumpAndSettle();
    }

    // NB : les labels « Préparer »/« Randonner » de la barre d'actions sont
    // identiques aux titres de section (t.hub.sections.*) rendus dans le corps.
    // On SCOPE donc les finds a la barre (BottomAppBar) pour ne compter que les
    // items de la barre d'actions, pas les titres de section homonymes.
    Finder inBar(Finder f) =>
        find.descendant(of: find.byType(BottomAppBar), matching: f);

    testWidgets('MODE TREK (trek actif) : SOS present dans la barre',
        (tester) async {
      await pumpTall(tester, activeTrailId: 'volcans');

      // Barre d'actions : Preparer / Randonner / Apres + SOS saillant.
      expect(inBar(find.text(t.navPilote.prepare)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.hike)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.after)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.sos)), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
    });

    testWidgets('HORS MODE TREK (aucun trek actif) : PAS de SOS',
        (tester) async {
      await pumpTall(tester, activeTrailId: null);

      // Les 3 actions de navigation restent ; le SOS est ABSENT (AUDIT §M-2).
      expect(inBar(find.text(t.navPilote.prepare)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.hike)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.after)), findsOneWidget);
      expect(inBar(find.text(t.navPilote.sos)), findsNothing);
      expect(find.byIcon(Icons.emergency), findsNothing);
    });

    testWidgets('le pilote n\'affiche PAS de NavigationBar (hors-shell)',
        (tester) async {
      await pumpTall(tester, activeTrailId: null);
      // Pas de double bottom bar : la barre est une BottomAppBar d'actions.
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(ContextualActionBar), findsOneWidget);
      // L'AppHeader coiffe l'ecran.
      expect(find.byType(AppHeader), findsOneWidget);
    });
  });
}

/// Notifier factice pilotant l'etat expose du trek (parite hub_screen_test).
class _FakeTrekNotifier extends TrekSessionManagerNotifier {
  _FakeTrekNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
