import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/hub/presentation/nav_pilote_screen.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
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
  // NavPiloteScreen — COCKPIT PAR PHASES (nav V2, R3→R10)
  // ---------------------------------------------------------------------------
  group('NavPiloteScreen (cockpit par phases)', () {
    /// Enveloppe le pilote dans un routeur minimal + overrides.
    Widget wrapPilote({List<Override> overrides = const []}) {
      final router = GoRouter(
        initialLocation: '/nav-pilote',
        routes: [
          GoRoute(path: '/nav-pilote', builder: (_, __) => const NavPiloteScreen()),
          // Cibles neutres pour ne casser aucune navigation au tap.
          GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
          // Cible du bouton Profil de l'AppHeader (parite hub origine).
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Scaffold(body: Text('PROFILE_STUB')),
          ),
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

    /// Phase du cockpit = lifecycle DERIVE du sentier actif (R7).
    Override summaryWith(TrekLifecycleState state) =>
        currentTrailSummaryProvider.overrideWith(
          (ref) async => TrekSummary(
            config: ref.watch(trailConfigProvider),
            state: state,
          ),
        );

    /// Rend le pilote sur une surface tres haute pour monter toute la liste
    /// (barre d'actions comprise). Reinitialise a la fin du test.
    Future<void> pumpTall(
      WidgetTester tester, {
      required String? activeTrailId,
      required TrekLifecycleState lifecycle,
      List<Override> extra = const [],
    }) async {
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(wrapPilote(overrides: [
        userNull,
        trekIdle,
        activeTrek(activeTrailId),
        summaryWith(lifecycle),
        ...extra,
      ]));
      await tester.pumpAndSettle();
    }

    Finder inBar(Finder f) =>
        find.descendant(of: find.byType(BottomAppBar), matching: f);

    testWidgets(
        'phase Randonner (inProgress + trek actif) : SOS present + CTA Terminer',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // SOS present (phase Randonner + mode trek reel) — R9.
      expect(inBar(find.text(t.navPilote.sos)), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      // CTA de transition = « Terminer le trek » (R7).
      expect(inBar(find.text(t.navPilote.finishTrek)), findsOneWidget);
      // Section Randonner affichee (titre de section dans le corps).
      expect(find.text(t.hub.cards.navigation), findsOneWidget);
    });

    testWidgets(
        'phase Preparer (prepared, pas de trek actif) : PAS de SOS + CTA '
        'Demarrer (R6)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // Hors phase Randonner -> pas de SOS (AUDIT §M-2 / R9).
      expect(inBar(find.text(t.navPilote.sos)), findsNothing);
      expect(find.byIcon(Icons.emergency), findsNothing);
      // R6 : le CTA « Démarrer le trek » est le bouton de transition de phase.
      expect(inBar(find.text(t.navPilote.startTrek)), findsOneWidget);
      // Section Preparer affichee (une carte de prepa presente).
      expect(find.text(t.hub.cards.feasibility), findsOneWidget);
    });

    testWidgets('R7 : UNE seule phase visible a la fois (Preparer pas de '
        'Randonner)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // En phase Préparer, les cartes de la phase Randonner (Navigation/Journal)
      // ne sont PAS montees (mode unique contextuel).
      expect(find.text(t.hub.cards.feasibility), findsOneWidget);
      expect(find.text(t.hub.cards.journal), findsNothing);
    });

    testWidgets('phase Apres (completed) : section Apres, PAS de SOS',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.completed);

      expect(inBar(find.text(t.navPilote.sos)), findsNothing);
      // Section Après : la carte Import GPX (unique a la phase Après, absente de
      // la HubTrekCard) prouve que la section Après est bien montee.
      expect(find.text(t.hub.cards.importGpx), findsOneWidget);
      // Aucune pastille de transition (phase terminale) : ni Démarrer ni Terminer.
      expect(inBar(find.text(t.navPilote.startTrek)), findsNothing);
      expect(inBar(find.text(t.navPilote.finishTrek)), findsNothing);
    });

    testWidgets('R9 : SOS a DROITE par defaut (droitier)', (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // Le SOS (Icons.emergency) est a droite du CTA de transition (flag_outlined)
      // : sa position horizontale (dx) est superieure.
      final sosX = tester.getCenter(find.byIcon(Icons.emergency)).dx;
      final ctaX = tester.getCenter(find.byIcon(Icons.flag_outlined)).dx;
      expect(sosX, greaterThan(ctaX));
    });

    testWidgets('R9 : SOS a GAUCHE si main dominante gauche (gaucher)',
        (tester) async {
      await pumpTall(
        tester,
        activeTrailId: 'volcans',
        lifecycle: TrekLifecycleState.inProgress,
        extra: [
          settingsProvider.overrideWith(
            () => _FakeSettingsNotifier(const AppSettings(
              dominantHand: DominantHandValues.left,
            )),
          ),
        ],
      );

      final sosX = tester.getCenter(find.byIcon(Icons.emergency)).dx;
      final ctaX = tester.getCenter(find.byIcon(Icons.flag_outlined)).dx;
      expect(sosX, lessThan(ctaX));
    });

    testWidgets('le pilote n\'affiche PAS de NavigationBar (hors-shell)',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);
      // Pas de double bottom bar : la barre est une BottomAppBar d'actions.
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomAppBar), findsOneWidget);
      // L'AppHeader coiffe l'ecran.
      expect(find.byType(AppHeader), findsOneWidget);
    });

    // PARITE HUB ORIGINE (retours Chris) : Informations (i) + Profil (person).
    testWidgets('AppHeader : actions Informations + Profil presentes (parite '
        'hub origine)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);
      expect(find.byTooltip(t.hub.infoTooltip), findsOneWidget);
      expect(find.byTooltip(t.hub.profileTooltip), findsOneWidget);
      final inHeader = find.descendant(
        of: find.byType(AppBar),
        matching: find.byIcon(Icons.info_outline),
      );
      expect(inHeader, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.person_outline),
        ),
        findsOneWidget,
      );
    });

    testWidgets('AppHeader : le bouton Profil route vers /profile',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);
      await tester.tap(find.byTooltip(t.hub.profileTooltip));
      await tester.pumpAndSettle();
      expect(find.text('PROFILE_STUB'), findsOneWidget);
    });

    testWidgets('AppHeader : le bouton Informations ouvre la fiche d\'aide',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);
      await tester.tap(find.byTooltip(t.hub.infoTooltip));
      await tester.pumpAndSettle();
      expect(find.text(t.hub.infoSheetBody), findsOneWidget);
    });
  });
}

/// Notifier factice de settings (parite pattern _FakeTrekNotifier) pour piloter
/// la main dominante en test (R9).
class _FakeSettingsNotifier extends SettingsNotifier {
  _FakeSettingsNotifier(this._initial);
  final AppSettings _initial;

  @override
  AppSettings build() => _initial;
}

/// Notifier factice pilotant l'etat expose du trek (parite hub_screen_test).
class _FakeTrekNotifier extends TrekSessionManagerNotifier {
  _FakeTrekNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
