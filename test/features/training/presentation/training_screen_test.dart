import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests widget de l'ECRAN ENTRAINEMENT payant (StepWays LOT 5, A).
///
/// Verifie les DEUX faces du verrou premium (verrouille = teaser + paywall ;
/// debloque = plan cochable + objectif + progression) et l'etat « sans plan »
/// (message neutre). L'acces est pilote en injectant [isDemoModeProvider]
/// (offline-safe : c'est la source unique du verrou) ; le plan est injecte via
/// [trainingPlanProvider] pour un rendu deterministe sans assets/DB.
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
          TrainingSession(id: 'foundation-s2', labelFr: 'Marche + renfo'),
        ],
      ),
      TrainingPhase(
        id: 'endurance',
        weekStart: 6,
        weekEnd: 8,
        titleFr: 'Endurance',
        sessions: [
          TrainingSession(id: 'endurance-s1', labelFr: 'Sortie longue'),
        ],
      ),
    ],
    objective: TrainingObjective(labelFr: 'Tenir 6 h de marche'),
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// LA DATE DE DEPART EST DESORMAIS UNE CONDITION D'AFFICHAGE (tache 570, S3).
  ///
  /// Ces tests montaient l'ecran SANS date et attendaient le plan : c'etait
  /// precisement le defaut releve par Chris (« tu fais un plan sans savoir quand
  /// il part »). Le plan ne s'affiche plus sans date, ni sous huit semaines : la
  /// rampe par defaut est donc un depart LOIN (90 jours), et les deux refus ont
  /// leurs propres tests dans `training_frequency_and_floor_test.dart`.
  Widget wrap({
    required bool isDemo,
    TrainingPlan? planOverride,
    int daysUntilDeparture = 90,
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        isDemoModeProvider(testTrailConfig.id)
            .overrideWith((ref) async => isDemo),
        trainingPlanProvider.overrideWith(
          (ref) async => planOverride ?? plan,
        ),
        trainingDepartureDateProvider.overrideWithValue(
          DateTime.now().add(Duration(days: daysUntilDeparture)),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/training',
            routes: [
              GoRoute(path: '/training', builder: (_, __) => const TrainingScreen()),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('TrainingScreen — verrou premium', () {
    testWidgets('verrouille : teaser + bouton Debloquer, pas de seance cochable',
        (tester) async {
      await tester.pumpWidget(wrap(isDemo: true));
      await tester.pumpAndSettle();

      // Titre de l'ecran + encart paywall + CTA « Debloquer ».
      expect(find.text(t.training.title), findsWidgets);
      expect(find.text(t.training.unlock), findsOneWidget);
      expect(find.text(t.training.paywallTitle), findsOneWidget);
      // Le detail (seances cochables) reste masque en verrouille.
      expect(find.byType(CheckboxListTile), findsNothing);
    });

    testWidgets('debloque : plan cochable + objectif + progression',
        (tester) async {
      await tester.pumpWidget(wrap(isDemo: false));
      await tester.pumpAndSettle();

      // Pas de paywall ; l'objectif et la progression sont dans l'arbre.
      //
      // `skipOffstage: false` : la ligne qui NOMME LES SOURCES des frequences
      // (tache 570, S3-a) s'insere entre les phases et l'objectif, et pousse ce
      // dernier sous le pli du viewport de test par defaut. Ce qui est sous test
      // ici est la PRESENCE de l'objectif dans un plan debloque, pas la hauteur
      // du telephone : le defilement est verifie ailleurs.
      expect(find.text(t.training.unlock), findsNothing);
      expect(find.text(t.training.objectiveTitle, skipOffstage: false),
          findsOneWidget);
      // La 1re phase est ouverte par defaut -> ses seances sont cochables.
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('debloque : cocher une seance fait avancer le suivi',
        (tester) async {
      await tester.pumpWidget(wrap(isDemo: false));
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final checked = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((c) => c.value == true);
      expect(checked, isNotEmpty);
    });
  });

  group('TrainingScreen — etat sans plan', () {
    // RETOURNE PAR LA TACHE 552. Ce test exigeait le message « Programme
    // d'entrainement bientot disponible pour ce sentier » — une date qu'aucune
    // ligne de code ne porte. Retour Chris du 25/09 : « si tu ne les a pas tu ne
    // met rien ». La cle est supprimee des cinq langues, l'ecran ne promet plus
    // rien, et ce test verrouille qu'il reste DEBOUT et MUET : aucune exception,
    // aucune seance fantome, et aucune promesse revenue par une autre porte.
    testWidgets('plan vide (aucune phase) -> aucune promesse, aucun crash',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          isDemo: false,
          planOverride: const TrainingPlan(trailId: trailId, phases: []),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsNothing);
      expect(tester.takeException(), isNull);
      for (final promesse in <String>[
        'bientôt',
        'bientot',
        'prochainement',
        'en cours de développement',
      ]) {
        expect(find.textContaining(promesse, skipOffstage: false), findsNothing,
            reason: 'l ecran sans plan promet encore « $promesse »');
      }
    });
  });
}
