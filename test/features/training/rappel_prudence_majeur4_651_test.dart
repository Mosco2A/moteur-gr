import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NON-REGRESSION — TACHE 651, DEFAUT B (MAJEUR) : LE RAPPEL DE PRUDENCE
/// DISPARAISSAIT DES QUE LE PROGRAMME N'ETAIT PAS PROPOSABLE.
///
/// MAJEUR-4 (campagne personas du 21/09, corrige par d2e8f3ca) exige que les
/// deux ecrans NE PUISSENT PLUS SE CONTREDIRE : quand la Faisabilite rend autre
/// chose que le vert, l'ecran Preparation physique porte le rappel de prudence.
///
/// REGRESSION MESUREE PAR LA CAMPAGNE 650 (S1 Lea, reproduite trois fois) : la
/// Faisabilite rend « Rythme a alleger » et l'ecran Preparation physique
/// n'affiche AUCUN rappel de prudence.
///
/// CAUSE RACINE MESUREE, ET LE LOT QUI L'A DEFAIT. Le commit 2c6dfe91 (tache
/// 570, LOT S, 26/09) a remplace l'affichage conditionnel du plan par DEUX
/// RETOURS ANTICIPES vers `_NoPlanYet` — sans date de depart, et sous le
/// plancher de huit semaines. Le rappel de prudence, lui, vivait (et vit
/// toujours) plus bas dans la SEULE branche « plan deroule ». Les deux refus
/// court-circuitaient donc le bandeau. Le persona S1 visite la Preparation
/// physique AVANT de poser sa date de depart : il tombait exactement dans le
/// premier refus. Le verdict n'etait pas faux, le moteur unique n'a pas bouge :
/// c'est l'ECRAN qui rendait avant d'arriver au rappel.
///
/// CE QUE CE TEST VERROUILLE : le rappel de prudence suit le VERDICT, pas la
/// disponibilite du programme — et il le suit dans les TROIS etats de l'ecran.
/// La decision de la tache 570 est conservee telle quelle : sans date et sous
/// huit semaines, on ne propose toujours AUCUN programme, et le motif du refus
/// reste affiche. Prudence et refus cohabitent : quand aucun programme n'est
/// proposable, le rappel compte MEME PLUS que d'habitude.
void main() {
  const trailId = 'test-trail';

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

  /// Monte l'ecran avec un VERDICT injecte et un depart choisi.
  ///
  /// `daysUntilDeparture: null` = aucune date posee (refus S3-b, l'etat du
  /// persona S1). `20` = sous le plancher de huit semaines (refus S3-c). `90` =
  /// programme deroule (l'etat que MAJEUR-4 couvrait deja).
  Widget wrap({
    required FeasibilityVerdict? verdict,
    int? daysUntilDeparture,
    bool hasProfile = true,
    bool enDemo = false,
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        isDemoModeProvider(
          testTrailConfig.id,
        ).overrideWith((ref) async => enDemo),
        trainingPlanProvider.overrideWith((ref) async => plan),
        trainingDepartureDateProvider.overrideWithValue(
          daysUntilDeparture == null
              ? null
              : DateTime.now().add(Duration(days: daysUntilDeparture)),
        ),
        // Le verdict vient du MOTEUR UNIQUE ; ici on injecte sa sortie pour
        // rendre l'ecran deterministe, sans toucher a la chaine de calcul (elle
        // a ses propres tests : `moteur_verdict_unique_test.dart`).
        trainingPersonalizationProvider.overrideWith(
          (ref) async =>
              TrainingPersonalization(hasProfile: hasProfile, verdict: verdict),
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

  final rappel = find.text(
    t.training.cautionVerdictNotice,
    skipOffstage: false,
  );

  testWidgets(
    'DEFAUT B — SANS DATE DE DEPART, le rappel de prudence est la (etat du '
    'persona S1) et le refus reste motive',
    (tester) async {
      await tester.pumpWidget(
        wrap(verdict: FeasibilityVerdict.orange, daysUntilDeparture: null),
      );
      await tester.pumpAndSettle();

      expect(
        rappel,
        findsOneWidget,
        reason:
            'la Faisabilite rend « Rythme a alleger » : les deux ecrans ne '
            'peuvent pas se contredire (MAJEUR-4). Le retour anticipe de la '
            'tache 570 sautait le bandeau.',
      );
      // LA DECISION 570 EST INTACTE : aucun programme, et on dit pourquoi.
      expect(
        find.byKey(const ValueKey('training-no-date-why')),
        findsOneWidget,
      );
      expect(
        find.text(t.training.objectiveTitle, skipOffstage: false),
        findsNothing,
      );
    },
  );

  testWidgets(
    'DEFAUT B — SOUS LE PLANCHER DE HUIT SEMAINES, le rappel est la et le '
    'refus reste motive',
    (tester) async {
      await tester.pumpWidget(
        wrap(verdict: FeasibilityVerdict.red, daysUntilDeparture: 20),
      );
      await tester.pumpAndSettle();

      expect(
        rappel,
        findsOneWidget,
        reason:
            'un verdict rouge a moins de trois semaines du depart est le '
            'cas ou le rappel compte le plus',
      );
      expect(
        find.byKey(const ValueKey('training-too-short-why')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'NON-REGRESSION 21/09 — programme deroule : le rappel suit toujours le '
    'verdict',
    (tester) async {
      await tester.pumpWidget(
        wrap(verdict: FeasibilityVerdict.orange, daysUntilDeparture: 90),
      );
      await tester.pumpAndSettle();

      expect(rappel, findsOneWidget);
      // Le programme EST propose dans cet etat (aucun refus).
      expect(find.byKey(const ValueKey('training-no-date-why')), findsNothing);
      expect(
        find.byKey(const ValueKey('training-too-short-why')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'DEFAUT B — EN DEMO, l essai bride porte AUSSI le rappel de prudence '
    '(c est l etat ou le persona S1 rencontrait la contradiction)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          verdict: FeasibilityVerdict.red,
          daysUntilDeparture: 90,
          enDemo: true,
        ),
      );
      await tester.pumpAndSettle();

      // L'essai bride SERT UN PROGRAMME : phases et seances sont la, jouables.
      expect(
        find.byKey(const ValueKey('training-demo-banner')),
        findsOneWidget,
      );
      expect(
        rappel,
        findsOneWidget,
        reason:
            'un plan d entrainement complet servi pendant que la '
            'Faisabilite dit « Rythme a alleger », c est la contradiction de '
            'MAJEUR-4 — et c est l ecran que tout le monde voit AVANT d acheter',
      );
    },
  );

  testWidgets(
    'EN DEMO, verdict vert — aucun rappel non plus (le bandeau suit le feu)',
    (tester) async {
      await tester.pumpWidget(
        wrap(
          verdict: FeasibilityVerdict.green,
          daysUntilDeparture: 90,
          enDemo: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('training-demo-banner')),
        findsOneWidget,
      );
      expect(rappel, findsNothing);
    },
  );

  testWidgets(
    'VERDICT VERT — aucun rappel, dans les trois etats (jamais de fausse alerte)',
    (tester) async {
      for (final jours in <int?>[null, 20, 90]) {
        await tester.pumpWidget(
          wrap(verdict: FeasibilityVerdict.green, daysUntilDeparture: jours),
        );
        await tester.pumpAndSettle();
        expect(
          rappel,
          findsNothing,
          reason: 'verdict vert, depart=$jours : rien a signaler',
        );
      }
    },
  );

  testWidgets('VERDICT INDISPONIBLE — aucun rappel invente (fail-closed)', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(verdict: null, daysUntilDeparture: null));
    await tester.pumpAndSettle();
    expect(rappel, findsNothing);
    // Verdict indisponible ET fiche vide : toujours aucun rappel invente, et
    // l'ecran garde son motif de refus. Le bandeau « remplissez votre fiche »
    // reste, lui, reserve a la branche « programme deroule » : inviter a
    // adapter un plan qu'on ne propose pas serait une promesse vide.
    await tester.pumpWidget(
      wrap(verdict: null, daysUntilDeparture: null, hasProfile: false),
    );
    await tester.pumpAndSettle();
    expect(rappel, findsNothing);
    expect(find.byKey(const ValueKey('training-no-date-why')), findsOneWidget);
  });
}
