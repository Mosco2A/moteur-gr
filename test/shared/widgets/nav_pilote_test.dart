import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
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
        'phase Randonner (inProgress + trek actif) : SOS present + CTA '
        'Navigation dans la barre + Terminer dans le corps (R21/R22)',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // SOS present (phase Randonner + mode trek reel) — R9.
      expect(inBar(find.text(t.navPilote.sos)), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      // R22 : le CTA de la barre du bas est desormais « Navigation » (route
      // vers la carte), plus « Terminer le trek ».
      expect(inBar(find.text(t.hub.cards.navigation)), findsOneWidget);
      // R21 : « Terminer le trek » a QUITTE la barre — il est dans le corps
      // (bouton orange de fin de phase), plus dans la BottomAppBar.
      expect(inBar(find.text(t.navPilote.finishTrek)), findsNothing);
      expect(find.text(t.navPilote.finishTrek), findsOneWidget);
    });

    testWidgets(
        'R14/R23 : phase Randonner = 7 cartes (Mon groupe RETIRÉ, R23) '
        '(ravitaillement + meteo + fiches info inclus)', (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // R23 : liste finale de 7 cartes « en rando » — « Mon groupe » (groupe
      // live) est RETIRÉ (non fait dans cette version). « Navigation » figure
      // dans le corps (carte) ET dans la barre (CTA R22) -> on scope le corps
      // en excluant la BottomAppBar.
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(t.hub.cards.navigation),
        ),
        findsOneWidget,
      );
      expect(find.text(t.hub.cards.journal), findsOneWidget);
      expect(find.text(t.hub.cards.group), findsNothing); // Mon groupe RETIRÉ (R23)
      expect(find.text(t.hub.cards.shop), findsOneWidget); // Ravitaillement
      expect(find.text(t.hub.cards.weather), findsOneWidget); // Météo
      expect(find.text(t.hub.cards.fire), findsOneWidget); // Incendie
      expect(find.text(t.hub.cards.accommodations), findsOneWidget); // Hébergements
      expect(find.text(t.hub.cards.tips), findsOneWidget); // Fiches conseils
    });

    testWidgets('R11/R24 : bandeau = « <nom du trek> en cours », pas de titre '
        'de section redondant', (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // R24 : le bandeau de phase Randonner affiche « <nom du trek> en cours »
      // (nom du sentier courant), plus le generique « Randonner ». Le nom vient
      // du sentier par defaut du catalogue (aucune localite hardcodee).
      final trekName = TrailCatalog.defaultTrail.displayName;
      expect(
        find.text(t.navPilote.phaseHikeInProgress(trek: trekName)),
        findsOneWidget,
      );
      // R11 : pas de titre de section redondant. Le libelle generique
      // « Randonner » (t.hub.sections.hike) n'apparait plus du tout en Randonner
      // (ni bandeau — remplace par le nom du trek — ni en-tete de section masquee).
      expect(find.text(t.hub.sections.hike), findsNothing);
    });

    testWidgets('R19 : « Prêt à partir / Démarrer la randonnée » (HubTrekCard) '
        'ABSENT en Préparer (retiré, doublon)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // R19 (V3) : le bloc « Prêt à partir » (HubTrekCard état prepared -> CTA
      // « Démarrer la randonnée ») est RETIRÉ de Préparer. Le seul démarrage est
      // le bouton « Démarrer le trek » orange en fin de scroll (Q1/Q2).
      expect(find.text(t.hub.startCta), findsNothing);
      // La HubTrekCard « Prêt à partir » n'est plus là (son titre non plus).
      expect(find.text(t.hub.trekCard.noTrekTitle), findsNothing);
      // Q2 : « Démarrer le trek » n'est PLUS dans la barre (pastille supprimée),
      // il est dans le CORPS (fin de scroll).
      expect(inBar(find.text(t.navPilote.startTrek)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(t.navPilote.startTrek),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Q3/Groupe : « Découvrir » et « Groupe » ABSENTS du cockpit '
        'Préparer (§12.3/§12.4)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // Q3 (§12.3) : « Découvrir les sentiers » (t.hub.cards.offline) retiré du
      // cockpit Préparer (vit dans « Mes treks »).
      expect(find.text(t.hub.cards.offline), findsNothing);
      // Scope Groupe (§12.4 b) : « Groupe » (t.hub.cards.group) retiré aussi.
      expect(find.text(t.hub.cards.group), findsNothing);
      // Les autres cartes de prépa restent (parité) — ex. Itinéraire, Programme.
      expect(find.text(t.hub.cards.itinerary), findsOneWidget);
      expect(find.text(t.hub.cards.programme), findsOneWidget);
    });

    testWidgets('Q1 : « Démarrer le trek » DÉSACTIVÉ tant que la gate 3 cartes '
        'est fermée (§12.1/§12.5)', (tester) async {
      // Gate par défaut fermée (aucune carte cœur faite en test) -> bouton grisé
      // (onPressed null) + sous-texte d'explication présent.
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      final startBtn = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(t.navPilote.startTrek),
          matching: find.byType(FilledButton),
        ),
      );
      expect(startBtn.onPressed, isNull,
          reason: 'gate fermée -> bouton Démarrer désactivé (grisé)');
      // Sous-texte d'explication de la gate (§12.5).
      expect(find.text(t.navPilote.startGateSubtitle), findsOneWidget);
    });

    testWidgets('R19 : « Démarrer la randonnée » (HubTrekCard) ABSENT en '
        'Randonner aussi', (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // En Randonner (trek actif), la HubTrekCard montre la carte « en cours »
      // (jamais « Démarrer ») : aucun CTA « Démarrer la randonnée ».
      expect(find.text(t.hub.startCta), findsNothing);
    });

    testWidgets('R18 : BANDEAU météo/incendie localisé PRÉSENT en Randonner',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: 'volcans', lifecycle: TrekLifecycleState.inProgress);

      // Le bandeau « ici et maintenant » porte son titre + le bouton « météo
      // des étapes » (accès au détail par étape). Sans données de test, il se
      // dégrade proprement mais reste présent (accès préservé).
      expect(find.text(t.navPilote.weatherBannerTitle), findsOneWidget);
      expect(find.text(t.navPilote.weatherBannerStages), findsOneWidget);
    });

    testWidgets('R18 : PAS de météo en Préparer (ni bandeau ni tuile)',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // Préparer = aucune météo : ni le bandeau localisé (titre/bouton), ni une
      // tuile météo du jour (t.hub.weather.title). Le climat/saison/incendie de
      // la zone vit dans les fiches d'info du trek (éditorial), pas ici.
      expect(find.text(t.navPilote.weatherBannerTitle), findsNothing);
      expect(find.text(t.navPilote.weatherBannerStages), findsNothing);
      expect(find.text(t.hub.weather.title), findsNothing);
    });

    testWidgets(
        'phase Preparer (prepared, pas de trek actif) : PAS de SOS + bouton '
        'Demarrer en fin de scroll (Q1/Q2)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // Hors phase Randonner -> pas de SOS (AUDIT §M-2 / R9).
      expect(inBar(find.text(t.navPilote.sos)), findsNothing);
      expect(find.byIcon(Icons.emergency), findsNothing);
      // Q2 : « Démarrer le trek » est en fin de scroll (corps), PAS dans la barre
      // (pastille de transition supprimée).
      expect(inBar(find.text(t.navPilote.startTrek)), findsNothing);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(t.navPilote.startTrek),
        ),
        findsOneWidget,
      );
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

      // Le SOS (Icons.emergency) est a droite du CTA de la barre (R22 :
      // « Navigation », icone navigation_outlined) : dx superieur. On scope la
      // BottomAppBar (l'icone flag du bouton « Terminer » vit dans le corps).
      final sosX = tester.getCenter(inBar(find.byIcon(Icons.emergency))).dx;
      final ctaX =
          tester.getCenter(inBar(find.byIcon(Icons.navigation_outlined))).dx;
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

      final sosX = tester.getCenter(inBar(find.byIcon(Icons.emergency))).dx;
      final ctaX =
          tester.getCenter(inBar(find.byIcon(Icons.navigation_outlined))).dx;
      expect(sosX, lessThan(ctaX));
    });

    testWidgets('R16 : en démo, previsualiser Randonner affiche l\'apercu '
        'VERROUILLE (pas le cockpit jouable)', (tester) async {
      // Trek prepared, pas de trek reel actif : phase reelle = Préparer.
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      // Active la démo (revele les selecteurs d'apercu des phases, R8).
      await tester.tap(find.text(t.navPilote.demoTrekMode));
      await tester.pumpAndSettle();

      // Previsualise la phase Randonner via le selecteur d'apercu (dans la
      // barre : le meme libelle peut apparaitre dans le bandeau de phase).
      await tester.tap(inBar(find.text(t.navPilote.hike)));
      await tester.pumpAndSettle();

      // R16 : la démo ne rend PAS Randonner jouable -> teaser verrouille, PAS
      // les cartes de la section (carte Navigation absente DU CORPS ; le CTA
      // « Navigation » de la barre R22 reste, on scope donc le ListView), et
      // PAS de SOS.
      expect(find.text(t.navPilote.demoLockedBody), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(t.hub.cards.navigation),
        ),
        findsNothing,
      );
      expect(find.byIcon(Icons.emergency), findsNothing);
    });

    testWidgets('R16 : en démo, la PREPARATION reste jouable (cartes visibles)',
        (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      await tester.tap(find.text(t.navPilote.demoTrekMode));
      await tester.pumpAndSettle();
      // Selecteur sur Préparer (phase par defaut) : cartes de prépa jouables.
      // Tap dans la barre (le libelle « Préparer » figure aussi dans le bandeau).
      await tester.tap(inBar(find.text(t.navPilote.prepare)));
      await tester.pumpAndSettle();

      expect(find.text(t.hub.cards.feasibility), findsOneWidget);
      expect(find.text(t.navPilote.demoLockedBody), findsNothing);
    });

    testWidgets('R17 : l\'AppHeader affiche la MARQUE « StepWays » (pas le nom '
        'du trek)', (tester) async {
      await pumpTall(tester,
          activeTrailId: null, lifecycle: TrekLifecycleState.prepared);

      final titleInHeader = find.descendant(
        of: find.byType(AppHeader),
        matching: find.text(t.navPilote.appTitle),
      );
      expect(titleInHeader, findsOneWidget);
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
