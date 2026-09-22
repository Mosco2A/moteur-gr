import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/presentation/trek_feasibility_screen.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/walk_test_provider.dart';
import 'package:moteur_gr/features/planning/data/retained_plan_store.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CORRECTION N2 — les deux defauts trouves par Chris a l'ecran (mandat
/// #100293, 22/09/2026).
///
/// D1 — LE VERDICT TOMBAIT DES LA SAISIE MORPHOLOGIQUE. Saisir age / taille /
/// poids suffisait a faire apparaitre le feu tricolore. Or le niveau du
/// randonneur ne se deduit PAS de la morphologie : il se deduit des randos
/// deja faites (D+/jour et km/jour realises), corrige par la forme (test 6
/// min) puis par l'age. Un verdict pose sur la seule morphologie est donc un
/// verdict pose sur rien. GR20 attend, lui, que TOUS les criteres soient
/// remplis avant de proposer quoi que ce soit
/// (`feasibility_questionnaire_screen.dart` : `_submitQuestionnaire` ne pousse
/// vers le resultat que `if (answers.isComplete)`, et la preview live n'est
/// montree que dans ce meme cas). On reproduit ce comportement, en mieux : on
/// DIT ce qui manque au lieu de ne rien faire.
///
/// D2 — LE DECOUPAGE CHOISI NE SE VOYAIT NULLE PART ET NE SURVIVAIT A RIEN.
/// Le bouton « Generer mon programme (N jours) » ecrivait la duree dans un
/// `Notifier` PUREMENT EN MEMOIRE, jamais persiste : rien a l'ecran ne disait
/// que N jours etait le plan retenu, et le moindre redemarrage ramenait la
/// duree par defaut du sentier. Les tests d'avant ne le voyaient pas : ils
/// relisaient le provider DANS LE MEME container, juste apres le tap.
///
/// Ces tests VERIFIENT L'EFFET, pas la presence d'un bouton.
void main() {
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  StageEffort effort(int i, String name, double dist, int elev) => StageEffort(
        index: i,
        name: name,
        distanceKm: dist,
        elevationGainM: elev,
      );

  /// Une etape seedee du sentier de test (5 etapes -> bornes de duree [3..7]).
  StageModel stage(int n) => StageModel(
        trailId: 'test-trail',
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: 10,
        elevationGainM: 400,
        elevationLossM: 300,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      );

  /// Rando passee credible : elle remplit le critere « au moins une rando ».
  PastHike aPastHike() => PastHike(
        date: DateTime(2026, 6, 1),
        days: 3,
        avgWalkHoursPerDay: 6,
        totalElevationGain: 2400,
        totalDistanceKm: 54,
      );

  /// Evaluation dont le decoupage conseille (7 jours) DIFFERE de la duree par
  /// defaut du sentier de test (5) : sans cet ecart, « appliquer » et « ne
  /// rien faire » seraient indiscernables a l'ecran comme en test.
  FeasibilityAssessment assessmentSuggesting7Days() {
    final a = FeasibilityFormula.evaluate(
      stages: [
        effort(0, 'Depart -> Col', 26, 1700), // rouge
        effort(1, 'Col -> Breche', 24, 1500), // rouge
        effort(2, 'Breche -> Refuge', 12, 400),
        effort(3, 'Refuge -> Bergerie', 11, 350),
        effort(4, 'Bergerie -> Village', 9, 200),
      ],
      level: HikerLevel.intermediate,
    );
    // Garde-fou du test : si la formule evolue, on veut le savoir ICI, pas par
    // un echec obscur trois assertions plus bas.
    expect(a.suggestedDays, 7);
    return a;
  }

  /// Monte l'ecran de faisabilite sur le VRAI chainage de providers.
  ///
  /// On n'override NI la completude du profil NI les criteres : c'est
  /// justement la regle de declenchement du verdict qui est sous test.
  Future<ProviderContainer> pumpFeasibility(
    WidgetTester tester, {
    required HikerProfile profile,
    required List<PastHike> pastHikes,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => const TrekFeasibilityScreen()),
        GoRoute(
          path: '/trail/:id/planning',
          // AppBar : donne le bouton retour dont `pageBack()` a besoin pour
          // rejouer le geste reel « je reviens sur la faisabilite ».
          builder: (_, state) => Scaffold(
            appBar: AppBar(title: const Text('Programme')),
            body: Text('PLANNING ${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
    late ProviderContainer container;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([for (var n = 1; n <= 5; n++) stage(n)])),
          feasibilityAssessmentProvider
              .overrideWith((ref) async => assessmentSuggesting7Days()),
          hikerProfileProvider.overrideWith(() => _FixedProfile(profile)),
          pastHikesProvider.overrideWith(() => _FixedHikes(pastHikes)),
          walkTestResultProvider.overrideWith((ref) async => null),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(
              locale: const Locale('fr'),
              routerConfig: router,
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    return container;
  }

  // =========================================================================
  // D1 — AUCUN VERDICT TANT QUE LES CRITERES NE SONT PAS TOUS LA
  // =========================================================================
  group('D1 — le verdict attend TOUS les criteres (parite GR20)', () {
    testWidgets('morphologie SEULE -> aucun verdict, l ecran dit ce qui manque',
        (tester) async {
      // Exactement le geste de Chris : age + taille + poids, rien d'autre.
      await pumpFeasibility(
        tester,
        profile: const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
        pastHikes: const [],
      );

      // AUCUN verdict : ni feu tricolore, ni tableau etape par etape, ni
      // conseils de programme.
      expect(find.text(t.feasibility.formula.stagesTitle), findsNothing);
      expect(find.text(t.feasibility.formula.verdicts.red), findsNothing);
      expect(find.text(t.feasibility.formula.verdicts.orange), findsNothing);
      expect(find.text(t.feasibility.formula.verdicts.green), findsNothing);
      expect(find.text(t.feasibility.formula.adviceTitle), findsNothing);

      // A la place : ce qu'il manque, nomme.
      expect(find.text(t.feasibility.flow.missingTitle), findsOneWidget);
      expect(find.text(t.feasibility.flow.missingPastHikes), findsOneWidget);
      // La fiche est remplie : elle ne doit PAS etre listee comme manquante.
      expect(find.text(t.feasibility.flow.missingProfile), findsNothing);
    });

    testWidgets('fiche INCOMPLETE (age seul) -> la fiche est listee manquante',
        (tester) async {
      await pumpFeasibility(
        tester,
        profile: const HikerProfile(age: 45),
        pastHikes: const [],
      );
      expect(find.text(t.feasibility.formula.stagesTitle), findsNothing);
      expect(find.text(t.feasibility.flow.missingProfile), findsOneWidget);
      expect(find.text(t.feasibility.flow.missingPastHikes), findsOneWidget);
    });

    testWidgets('bouton « Valider » DESACTIVE tant que les criteres manquent',
        (tester) async {
      await pumpFeasibility(
        tester,
        profile: const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
        pastHikes: const [],
      );
      final finder =
          find.widgetWithText(ElevatedButton, t.feasibility.flow.validate);
      expect(finder, findsOneWidget);
      expect(tester.widget<ElevatedButton>(finder).onPressed, isNull,
          reason: 'incomplet -> le bouton ne doit mener a aucun verdict');

      // Et taper dessus ne fait apparaitre aucun verdict.
      await tester.tap(finder, warnIfMissed: false);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text(t.feasibility.formula.stagesTitle), findsNothing);
    });

    testWidgets('criteres AU COMPLET -> le verdict apparait', (tester) async {
      await pumpFeasibility(
        tester,
        profile: const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
        pastHikes: [aPastHike()],
      );
      expect(find.text(t.feasibility.formula.stagesTitle), findsOneWidget);
      expect(find.text(t.feasibility.flow.missingTitle), findsNothing);
      // Le test 6 min manque encore : le resultat est annonce provisoire.
      expect(find.text(t.feasibility.flow.partialNotice), findsOneWidget);
    });
  });

  // =========================================================================
  // D2 — CHOISIR LE DECOUPAGE PRODUIT UN EFFET, VISIBLE ET PERSISTANT
  // =========================================================================
  group('D2 — choisir le decoupage propose l APPLIQUE vraiment', () {
    /// Tous les criteres remplis : on atteint le verdict, donc le bouton.
    Future<ProviderContainer> pumpVerdict(WidgetTester tester) =>
        pumpFeasibility(
          tester,
          profile: const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
          pastHikes: [aPastHike()],
        );

    testWidgets('AVANT le choix : l ecran dit qu aucun decoupage n est retenu',
        (tester) async {
      await pumpVerdict(tester);
      expect(
        find.text(t.feasibility.formula
            .retainedPlanNone(days: testTrailConfig.defaultDuration)),
        findsOneWidget,
      );
    });

    testWidgets('taper le decoupage CHANGE LE PROGRAMME REEL', (tester) async {
      final container = await pumpVerdict(tester);

      // ETAT AVANT : le programme suit la duree par defaut du sentier (5).
      expect(
        container.read(plannedDaysProvider('test-trail')).length,
        testTrailConfig.defaultDuration,
      );

      final button = find.widgetWithText(
        ElevatedButton,
        t.feasibility.formula.generateProgram(days: 7),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // EFFET MESURE SUR LE PROGRAMME, pas sur le bouton : 7 jours reels.
      expect(container.read(plannedDaysProvider('test-trail')).length, 7);
      expect(container.read(selectedDurationProvider), 7);
      // Et le decoupage retenu est ECRIT dans le stockage durable.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(retainedDurationPrefsKey('test-trail')), 7);
    });

    testWidgets('le decoupage retenu est VISIBLE au retour sur l ecran',
        (tester) async {
      await pumpVerdict(tester);
      final button = find.widgetWithText(
        ElevatedButton,
        t.feasibility.formula.generateProgram(days: 7),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Retour sur la faisabilite : l'ecran AFFICHE le decoupage retenu.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(
          find.text(t.feasibility.formula.retainedPlan(days: 7)));
      expect(
        find.text(t.feasibility.formula.retainedPlan(days: 7)),
        findsOneWidget,
      );
    });
  });

  // =========================================================================
  // D2 — PERSISTANCE : le choix survit a un redemarrage de l application
  // =========================================================================
  group('D2 — le decoupage retenu SURVIT au redemarrage', () {
    test('un container tout neuf relit le decoupage retenu', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      // Session 1 : le randonneur retient 7 jours.
      final first = ProviderContainer(
        overrides: [trailConfigProvider.overrideWithValue(testTrailConfig)],
      );
      addTearDown(first.dispose);
      first.listen(selectedDurationProvider, (_, __) {});
      expect(first.read(selectedDurationProvider),
          testTrailConfig.defaultDuration);
      first.read(selectedDurationProvider.notifier).set(7);
      expect(first.read(selectedDurationProvider), 7);
      // Laisse l'ecriture durable se faire.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Session 2 : application relancee (container tout neuf).
      final second = ProviderContainer(
        overrides: [trailConfigProvider.overrideWithValue(testTrailConfig)],
      );
      addTearDown(second.dispose);
      second.listen(selectedDurationProvider, (_, __) {});
      // Hydratation asynchrone depuis le stockage durable.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(second.read(selectedDurationProvider), 7,
          reason: 'le decoupage retenu doit survivre au redemarrage');
    });
  });
}

/// Notifier de test : profil fige (aucune lecture de stockage).
class _FixedProfile extends HikerProfileNotifier {
  _FixedProfile(this._profile);
  final HikerProfile _profile;
  @override
  Future<HikerProfile> build() async => _profile;
}

/// Notifier de test : randos passees figees.
class _FixedHikes extends PastHikesNotifier {
  _FixedHikes(this._hikes);
  final List<PastHike> _hikes;
  @override
  Future<List<PastHike>> build() async => _hikes;
}
