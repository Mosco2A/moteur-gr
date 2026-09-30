import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MESURE — TACHE 651, DEFAUT B, DEUXIEME CAUSE : L'ECRAN, SUR LA CHAINE REELLE.
///
/// CE QUE LE PREMIER CORRECTIF NE COUVRAIT PAS. Le rejeu du persona S1 sur
/// l'emulateur (30/09, build/qa651/captures/S1) mesure `verrouille=false,
/// debloque=true` : l'ecran Preparation physique servait son PROGRAMME COMPLET
/// (le titre « Plan sur N semaines » n'existe que dans cette branche), donc PAS
/// la branche de refus corrigee par ailleurs. Et le rappel de prudence restait
/// absent six secondes apres l'ouverture, alors que la Faisabilite venait de
/// rendre « Rythme a alleger ».
///
/// Le test `moteur_verdict_unique_test.dart` prouve deja que les deux LECTURES
/// du verdict sont egales. Ce test-ci monte l'ECRAN sur la meme chaine reelle —
/// seules les donnees BRUTES sont injectees, tout le calcul est celui de la
/// production — et exige que le bandeau soit A L'ECRAN une fois l'arbre pose.
/// C'est le maillon que personne ne verrouillait : entre un provider juste et un
/// bandeau visible, il reste un ecran.
void main() {
  const trailId = 'test-trail';

  /// Trek de reference du test d'unicite du moteur : la premiere journee est
  /// au-dessus de la capacite d'une debutante.
  const stages = <StageEffort>[
    StageEffort(
      index: 0,
      name: 'Depart -> Col',
      distanceKm: 14,
      elevationGainM: 1000,
    ),
    StageEffort(
      index: 1,
      name: 'Col -> Refuge',
      distanceKm: 12,
      elevationGainM: 600,
    ),
    StageEffort(
      index: 2,
      name: 'Refuge -> Village',
      distanceKm: 9,
      elevationGainM: 250,
    ),
  ];

  const plan = TrainingPlan(
    trailId: trailId,
    durationWeeks: 8,
    phases: [
      TrainingPhase(
        id: 'foundation',
        weekStart: 1,
        weekEnd: 2,
        titleFr: 'Fondation',
        sessions: [
          TrainingSession(id: 'foundation-s1', labelFr: 'Sortie cardio 1 h'),
        ],
      ),
    ],
    objective: TrainingObjective(labelFr: 'Tenir 6 h de marche'),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// L'ecran, monte sur la CHAINE REELLE du verdict.
  ///
  /// Les memes overrides de donnees brutes que `moteur_verdict_unique_test`
  /// (c'est voulu : une seule fixture pour un seul moteur), plus ce dont
  /// l'ecran a besoin pour derouler son programme (plan, depart LOIN, sentier
  /// possede).
  /// Objectif bati comme dans le test d'unicite du moteur : la MEME journee
  /// sert d'energie max et de charge habituelle (jamais une journee que
  /// personne n'a faite).
  ObjectiveProfile objectif({
    required double dPlusParJour,
    required double kmParJour,
    required int joursConsecutifs,
  }) {
    final energie = FeasibilityScale.v2.energyOf(
      distanceKm: kmParJour,
      elevationGainM: dPlusParJour,
    );
    return ObjectiveProfile(
      maxElevationGainPerDayDone: dPlusParJour,
      maxDistancePerDayDone: kmParJour,
      maxConsecutiveDaysDone: joursConsecutifs,
      maxDailyEnergyKmDone: energie,
      habitualDailyEnergyKm: energie,
      fitnessLevelRank: 1,
      hasWalkTest: false,
    );
  }

  Widget wrap({
    required ObjectiveProfile objectif,
    required HikerProfile fiche,
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // --- donnees brutes du verdict (tout le calcul reste celui de la prod)
        stageEffortsProvider.overrideWith((ref) async => stages),
        objectiveProfileProvider.overrideWith((ref) async => objectif),
        hikerProfileProvider.overrideWith(() => _FicheFigee(fiche)),
        restDaysAfterStageProvider.overrideWithValue(const {0, 1}),
        trekConditionsProvider.overrideWith(
          (ref) async => TrekConditions.unknown,
        ),
        // --- ce que l'ecran Preparation physique demande en plus
        isDemoModeProvider(
          testTrailConfig.id,
        ).overrideWith((ref) async => false),
        trainingPlanProvider.overrideWith((ref) async => plan),
        trainingDepartureDateProvider.overrideWithValue(
          DateTime.now().add(const Duration(days: 90)),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/training',
            routes: [
              GoRoute(
                path: '/training',
                builder: (_, __) => const TrainingScreen(),
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets(
    'DEFAUT B (2e cause) — programme deroule sur la chaine REELLE : le '
    'bandeau de prudence est A L ECRAN pour une debutante',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          // Une sortie modeste : la debutante de la campagne (verdict rouge).
          objectif: objectif(
            dPlusParJour: 200,
            kmParJour: 10,
            joursConsecutifs: 1,
          ),
          fiche: const HikerProfile(age: 32, heightCm: 170, weightKg: 62),
        ),
      );
      await tester.pumpAndSettle();

      // Le programme EST deroule (c'est l'etat mesure sur l'emulateur).
      expect(
        find.textContaining('Plan sur ', skipOffstage: false),
        findsOneWidget,
        reason:
            'la fixture doit reproduire l etat mesure : '
            'verrouille=false, debloque=true',
      );

      // Et le rappel de prudence est la, sur la chaine reelle.
      expect(
        find.text(t.training.cautionVerdictNotice, skipOffstage: false),
        findsOneWidget,
        reason:
            'MAJEUR-4 : la Faisabilite rend autre chose que le vert, cet '
            'ecran doit porter le rappel. C est le maillon ECRAN, celui que le '
            'test d unicite du moteur ne traverse pas.',
      );
    },
  );

  testWidgets(
    'CONTRE-EPREUVE — un profil confirme (vert) ne declenche aucun rappel',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          objectif: objectif(
            dPlusParJour: 900,
            kmParJour: 23,
            joursConsecutifs: 5,
          ),
          fiche: const HikerProfile(age: 45, heightCm: 178, weightKg: 76),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Plan sur ', skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.text(t.training.cautionVerdictNotice, skipOffstage: false),
        findsNothing,
        reason: 'le bandeau suit le feu : rien a signaler sur du vert',
      );
    },
  );
}

/// Fiche figee (meme fake que le test d'unicite du moteur).
class _FicheFigee extends HikerProfileNotifier {
  _FicheFigee(this._fiche);
  final HikerProfile _fiche;

  @override
  Future<HikerProfile> build() async => _fiche;
}
