import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/core/theme/skin_provider.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/planning/presentation/trek_adjust_screen.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CAPTURES DE PREUVE R12 (LOT L9) — « Adapter l'itineraire ».
///
/// Scenario joue SUR L'EMULATEUR : cockpit en phase RANDONNER (trek demarre,
/// etapes 1 et 2 reellement marchees), puis ouverture de l'ecran d'adaptation
/// par la carte de la section Randonner — le vrai chemin utilisateur.
///
/// Le test IMPRIME un marqueur (`L9_SHOT_1` / `L9_SHOT_2`) puis IMMOBILISE
/// l'ecran quelques dizaines de secondes : c'est l'hote qui declenche
/// `adb exec-out screencap` sur ce marqueur (procedure du mandat). Aucun demon,
/// aucune boucle infinie : le test se termine seul.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const hold = Duration(seconds: 40);

  StageModel makeStage(int num, String name) => StageModel(
        trailId: 'test-trail',
        stageNumber: num,
        name: name,
        distanceKm: 9.0 + num,
        elevationGainM: 400 + num * 60,
        elevationLossM: 350 + num * 50,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );

  // Etapes du sentier FICTIF de test ([testTrailConfig] — « Sentier des
  // Volcans », 5 etapes en Auvergne). CLOISONNEMENT (#326) : aucun toponyme
  // GR20 ni corse ici, meme dans un fichier de test — StepWays est un moteur
  // independant et ses jeux de donnees ne doivent jamais emprunter a l'app de
  // reference. Noms inventes, sans correspondance reelle, comme la config.
  final stages = [
    makeStage(1, 'Col des Cheires - Refuge de Vaubrune'),
    makeStage(2, 'Refuge de Vaubrune - Burons de Montgarel'),
    makeStage(3, 'Burons de Montgarel - Cratere de Sauvagnac'),
    makeStage(4, 'Cratere de Sauvagnac - Refuge de Pierre-Laire'),
    makeStage(5, 'Refuge de Pierre-Laire - Plateau de Chandelac'),
  ];

  testWidgets('R12 — captures Randonner + ecran d adaptation', (tester) async {
    final container = ProviderContainer(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // GPS NEUTRALISE : sans cela, le cockpit ouvre le flux de position des
        // l'affichage et Android empile sa boite de dialogue de permission
        // PAR-DESSUS l'ecran -> la capture ne montrerait plus l'app. Le scenario
        // n'a besoin d'aucune position reelle (l'etat de rando est deja impose
        // par la session de tracking ci-dessous).
        positionStreamProvider.overrideWith((ref) => const Stream.empty()),
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
        arrivalEventsProvider.overrideWith((ref) => const Stream.empty()),
        stagesProvider('test-trail')
            .overrideWith((ref) => Future.value(stages)),
        // Trek DEMARRE : la section « Randonner » n'existe qu'en phase hike.
        trekSessionManagerProvider.overrideWith(
          () => _HikingNotifier(
            TrackingSessionState(
              status: TrackingSessionStatus.recording,
              distanceKm: 21.4,
              elevationGainM: 1180,
              elapsedDuration: const Duration(hours: 9, minutes: 20),
              session: TrekSession(
                id: 'l9-capture',
                trailId: 'test-trail',
                startedAt: DateTime.now().subtract(const Duration(days: 2)),
                // Etapes 1 et 2 REELLEMENT marchees -> jours 1 et 2 figes.
                completedStages: const ['1', '2'],
              ),
            ),
          ),
        ),
        currentTrailSummaryProvider.overrideWith(
          (ref) async => TrekSummary(
            config: ref.watch(trailConfigProvider),
            state: TrekLifecycleState.inProgress,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(stagesProvider('test-trail').future);
    container.read(selectedDurationProvider.notifier).set(5);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HubScreen()),
        GoRoute(
          path: '/trail/:id/adjust',
          builder: (_, state) =>
              TrekAdjustScreen(trailId: state.pathParameters['id'] ?? ''),
        ),
        // Cibles neutres des autres cartes du cockpit.
        for (final p in const [
          '/map',
          '/journal',
          '/profile',
          '/settings',
          '/my-treks',
          '/training',
          '/accommodations-nearby',
          '/trail/:id/weather',
          '/trail/:id/fire-risk',
          '/trail/:id/feasibility',
          '/trail/:id/itinerary',
          '/trail/:id/planning',
          '/trail/:id/calendar',
          '/trail/:id/nuitees',
          '/trail/:id/transport',
          '/trail/:id/shop',
          '/trail/:id/summary',
          '/trail/:id/checklist',
          '/trail/:id/tips',
          '/trail/:id/guides',
        ])
          GoRoute(path: p, builder: (_, __) => const SizedBox()),
      ],
    );

    // THEME REEL DE L'APP (meme recette que `lib/main.dart`) : sans cela, la
    // `MaterialApp` du harnais retombe sur la palette Material 3 par defaut
    // (violet clair) et la capture ne montrerait PAS les couleurs de
    // l'application — ni la peau, ni la couleur du sentier, ni le mode sombre
    // qui est le defaut produit. Les couleurs viennent de la config du sentier
    // ([TrailConfig.primaryColorValue]), la peau du provider qui l'applique.
    final skin = container.read(effectiveSkinProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.buildLightTheme(
              primaryColor: Color(testTrailConfig.primaryColorValue),
              secondaryColor: Color(testTrailConfig.secondaryColorValue),
              skin: skin,
            ),
            darkTheme: AppTheme.buildDarkTheme(
              primaryColor: Color(testTrailConfig.primaryColorValue),
              secondaryColor: Color(testTrailConfig.secondaryColorValue),
              skin: skin,
            ),
            // Defaut produit (design trek), comme `lib/main.dart`.
            themeMode: ThemeMode.dark,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // --- CAPTURE 1 : l'entree « Adapter l'itineraire » dans Randonner ---
    final adjustCard = find.text(t.hub.cards.adjust);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(adjustCard, 220, scrollable: scrollable);
    await tester.pumpAndSettle();
    // Remonte un peu pour CADRER : la carte doit apparaitre entiere, sous le
    // titre de la section « Randonner » — c'est cette appartenance a la phase
    // terrain que la capture doit prouver, pas seulement l'existence du libelle.
    await tester.drag(scrollable, const Offset(0, 340));
    await tester.pumpAndSettle();
    expect(adjustCard, findsOneWidget,
        reason: 'la carte d entree R12 doit etre visible en phase Randonner');
    expect(find.text(t.hub.sections.hike), findsOneWidget,
        reason: 'la carte doit etre cadree AVEC l intitule de sa section');

    debugPrint('L9_SHOT_1 randonner_modifier');
    await Future<void>.delayed(hold);

    // --- CAPTURE 2 : l'ecran d adaptation, jours faits non editables ---
    await tester.tap(adjustCard);
    await tester.pumpAndSettle(const Duration(seconds: 3));
    expect(find.text(t.programme.inTrek.doneSection), findsOneWidget);
    expect(find.text(t.programme.inTrek.doneBadge), findsNWidgets(2));

    debugPrint('L9_SHOT_2 modif_jours_non_faits');
    await Future<void>.delayed(hold);
  });
}

/// Notifier de tracking fige sur un etat donne (meme recette que les tests du
/// HUB) : permet de placer le cockpit en phase RANDONNER sans GPS reel.
class _HikingNotifier extends TrekSessionManagerNotifier {
  _HikingNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
