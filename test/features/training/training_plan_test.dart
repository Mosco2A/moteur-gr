import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/training/data/training_plan_loader.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';

/// Tests du plan d'entrainement EXTERNALISE (StepWays LOT 5, A).
///
/// Verifie : le contrat du JSON `assets/data/training_plans.json` (bloc default
/// valide, 3 phases, duree = donnee), la deserialisation [TrainingPlan.fromJson],
/// et la resolution par sentier du [TrainingPlanLoader] (specifique vs repli
/// default). i18n INLINE : les 5 langues sont presentes pour le contenu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(TrainingPlanLoader.clearCache);

  group('training_plans.json (contrat de donnees)', () {
    test('le bloc default a 3 phases, une duree et un objectif', () async {
      final raw =
          await rootBundle.loadString('assets/data/training_plans.json');
      final data = json.decode(raw) as Map<String, dynamic>;

      final def = data['default'] as Map<String, dynamic>;
      final plan = TrainingPlan.fromJson(def);

      // Duree = CHAMP DE DONNEES (structure maquette : 8 semaines).
      expect(plan.durationWeeks, 8);
      // 3 phases progressives (Fondation / Denivele / Endurance).
      expect(plan.phases.length, 3);
      expect(plan.phases.map((p) => p.id),
          containsAll(<String>['foundation', 'elevation', 'endurance']));
      // Objectif chiffre present.
      expect(plan.objective, isNotNull);
      // Au moins une seance par phase (cochable).
      for (final phase in plan.phases) {
        expect(phase.sessions, isNotEmpty);
      }
    });

    test('chaque seance porte un id STABLE unique (cle de persistance)',
        () async {
      final raw =
          await rootBundle.loadString('assets/data/training_plans.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final plan =
          TrainingPlan.fromJson(data['default'] as Map<String, dynamic>);

      final ids = [
        for (final ph in plan.phases)
          for (final s in ph.sessions) s.id,
      ];
      expect(ids.toSet().length, ids.length, reason: 'ids doivent etre uniques');
      expect(ids.every((id) => id.isNotEmpty), isTrue);
    });

    test('les 5 langues sont renseignees pour les titres de phase', () async {
      final raw =
          await rootBundle.loadString('assets/data/training_plans.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final plan =
          TrainingPlan.fromJson(data['default'] as Map<String, dynamic>);

      for (final phase in plan.phases) {
        expect(phase.titleFr, isNotEmpty);
        expect(phase.titleEn, isNotEmpty);
        expect(phase.titleDe, isNotEmpty);
        expect(phase.titleIt, isNotEmpty);
        expect(phase.titleEs, isNotEmpty);
      }
    });
  });

  group('TrainingPlanLoader (resolution par sentier)', () {
    test('sentier connu -> plan specifique', () async {
      final plan = await TrainingPlanLoader.loadForTrail('mare-a-mare-centre');
      expect(plan.trailId, 'mare-a-mare-centre');
      expect(await TrainingPlanLoader.hasSpecificPlan('mare-a-mare-centre'),
          isTrue);
    });

    test('sentier inconnu -> repli sur le plan default (jamais casse)',
        () async {
      final plan = await TrainingPlanLoader.loadForTrail('sentier-inexistant');
      expect(plan.trailId, 'default');
      expect(plan.phases, isNotEmpty);
      expect(await TrainingPlanLoader.hasSpecificPlan('sentier-inexistant'),
          isFalse);
    });
  });
}
