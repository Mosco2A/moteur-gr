import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/trek_completion.dart';

/// Helper : cree une Stage minimale identifiee par [id] / [orderIndex].
/// Les coordonnees ne servent pas a la logique de completion (pure ordre).
Stage _stage(String id, int orderIndex) => Stage(
      id: id,
      nameFr: 'Etape $orderIndex',
      distance: 10.0,
      elevationGain: 500,
      elevationLoss: 300,
      orderIndex: orderIndex,
      startLat: 0,
      startLng: 0,
      endLat: 0,
      endLng: 0,
    );

void main() {
  // Sentier fictif a 4 etapes (ordre officiel = orderIndex croissant).
  // On modelise un sentier « oriente » a la GR20 : forward = 'NS'.
  final stages = [
    _stage('s1', 1),
    _stage('s2', 2),
    _stage('s3', 3),
    _stage('s4', 4),
  ];

  group('TrekPlan.fromStages — sens de marche', () {
    test('NS (sens de reference) : ordre croissant, depart s1, fin s4', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );

      expect(plan.orderedStageIds, ['s1', 's2', 's3', 's4']);
      expect(plan.startStageId, 's1');
      expect(plan.finalStageId, 's4');
      expect(plan.stageCount, 4);
      expect(plan.isFullTrail, isTrue);
    });

    test('SN (sens inverse) : ordre inverse, depart s4, fin s1', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );

      expect(plan.orderedStageIds, ['s4', 's3', 's2', 's1']);
      // La « fin reelle » en SN est l'etape 1 — surtout PAS la derniere du JSON.
      expect(plan.startStageId, 's4');
      expect(plan.finalStageId, 's1');
      expect(plan.isFullTrail, isTrue);
    });

    test('ordre d entree quelconque : re-trie par orderIndex', () {
      final shuffled = [
        _stage('s3', 3),
        _stage('s1', 1),
        _stage('s4', 4),
        _stage('s2', 2),
      ];
      final plan = TrekPlan.fromStages(
        shuffled,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      expect(plan.orderedStageIds, ['s1', 's2', 's3', 's4']);
    });

    test('codes de direction propres au sentier (EW/WE) supportes', () {
      // Un sentier GR10-like : forward = 'EW'. Marcher 'WE' inverse la sequence.
      final planEw = TrekPlan.fromStages(
        stages,
        direction: 'EW',
        forwardDirectionCode: 'EW',
      );
      expect(planEw.finalStageId, 's4');

      final planWe = TrekPlan.fromStages(
        stages,
        direction: 'WE',
        forwardDirectionCode: 'EW',
      );
      expect(planWe.finalStageId, 's1');
      expect(planWe.startStageId, 's4');
    });
  });

  group('TrekPlan — parcours partiel (moitie / section)', () {
    test('sous-ensemble (moitie nord) : entier=false, bornes sur le sous-ens.',
        () {
      // Moitie « nord » = s1..s2, en NS.
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
        stageIds: ['s1', 's2'],
      );
      expect(plan.orderedStageIds, ['s1', 's2']);
      expect(plan.startStageId, 's1');
      expect(plan.finalStageId, 's2');
      expect(plan.isFullTrail, isFalse);
    });

    test('sous-ensemble en sens inverse (moitie sud en SN)', () {
      // Moitie « sud » = s3..s4 ; marchee en SN => depart s4, fin s3.
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
        stageIds: ['s3', 's4'],
      );
      expect(plan.orderedStageIds, ['s4', 's3']);
      expect(plan.startStageId, 's4');
      expect(plan.finalStageId, 's3');
      expect(plan.isFullTrail, isFalse);
    });

    test('forceFull surclasse la deduction', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
        stageIds: ['s1', 's2', 's3', 's4'],
        forceFull: true,
      );
      expect(plan.isFullTrail, isTrue);
    });
  });

  group('TrekPlan — isStartStage / isFinalStage / nextStageId', () {
    test('NS : depart = s1, fin = s4, suivant chaine s1->s2->s3->s4->null', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      expect(plan.isStartStage('s1'), isTrue);
      expect(plan.isStartStage('s4'), isFalse);
      expect(plan.isFinalStage('s4'), isTrue);
      expect(plan.isFinalStage('s1'), isFalse);

      expect(plan.nextStageId('s1'), 's2');
      expect(plan.nextStageId('s3'), 's4');
      expect(plan.nextStageId('s4'), isNull); // derniere : pas de suivant
      expect(plan.nextStageId('inconnue'), isNull);
    });

    test('SN : depart = s4, fin = s1, suivant chaine s4->s3->s2->s1->null', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );
      expect(plan.isStartStage('s4'), isTrue);
      expect(plan.isFinalStage('s1'), isTrue);
      expect(plan.nextStageId('s4'), 's3');
      expect(plan.nextStageId('s2'), 's1');
      expect(plan.nextStageId('s1'), isNull);
    });
  });

  group('TrekPlan.resolveArrival — logique de fin de trek', () {
    test('NS : arrivee etape intermediaire -> avancer', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      final outcome = plan.resolveArrival('s2');
      expect(outcome.action, TrekArrivalAction.advance);
      expect(outcome.nextStageId, 's3');
      expect(outcome.isAdvance, isTrue);
      expect(outcome.isComplete, isFalse);
    });

    test('NS : arrivee derniere etape (s4) -> completer le trek', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      final outcome = plan.resolveArrival('s4');
      expect(outcome.action, TrekArrivalAction.complete);
      expect(outcome.isComplete, isTrue);
      expect(outcome.nextStageId, isNull);
    });

    test('SN : arrivee derniere etape reelle (s1) -> completer le trek', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );
      final outcome = plan.resolveArrival('s1');
      expect(outcome.isComplete, isTrue);
    });

    test('SN : s4 = etape de DEPART -> ignore (anti-felicitations prematurees)',
        () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'SN',
        forwardDirectionCode: 'NS',
      );
      // En SN, s4 (plus grand orderIndex) est le DEPART : jamais une fin de trek.
      final outcome = plan.resolveArrival('s4');
      expect(outcome.action, TrekArrivalAction.ignore);
      expect(outcome.isComplete, isFalse);
      expect(outcome.isAdvance, isFalse);
    });

    test('NS : s1 = etape de DEPART -> ignore (anti-felicitations prematurees)',
        () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      final outcome = plan.resolveArrival('s1');
      expect(outcome.action, TrekArrivalAction.ignore);
    });

    test('etape hors parcours -> ignore', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
        stageIds: ['s1', 's2'],
      );
      // s3 n'est pas dans le parcours (moitie nord).
      expect(plan.resolveArrival('s3').action, TrekArrivalAction.ignore);
    });

    test('parcours partiel : la fin du sous-ensemble complete le trek', () {
      // Moitie nord s1..s2 : arriver a s2 (fin de la moitie) termine le trek,
      // meme si s2 n'est pas la derniere etape du sentier entier.
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
        stageIds: ['s1', 's2'],
      );
      expect(plan.resolveArrival('s2').isComplete, isTrue);
    });
  });

  group('TrekCongratulations — complet vs partiel', () {
    test('parcours entier -> felicitations completes', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      final congrats = TrekCongratulations.forPlan(plan);
      expect(congrats.isFull, isTrue);
      expect(congrats.isPartial, isFalse);
      expect(congrats.kind, TrekCompletionKind.full);
      expect(congrats.partialLabel, isNull);
    });

    test('parcours partiel -> felicitations partielles + libelle', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
        stageIds: ['s1', 's2'],
      );
      final congrats = TrekCongratulations.forPlan(plan, partialLabel: 'Nord');
      expect(congrats.isPartial, isTrue);
      expect(congrats.isFull, isFalse);
      expect(congrats.kind, TrekCompletionKind.partial);
      expect(congrats.partialLabel, 'Nord');
    });

    test('parcours entier ignore un libelle partiel fourni par erreur', () {
      final plan = TrekPlan.fromStages(
        stages,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      final congrats = TrekCongratulations.forPlan(plan, partialLabel: 'Nord');
      expect(congrats.partialLabel, isNull);
    });
  });

  group('TrekPlan — cas limites', () {
    test('parcours vide : bornes nulles, resolveArrival ignore', () {
      const plan = TrekPlan(
        orderedStageIds: [],
        direction: 'NS',
        isFullTrail: true,
      );
      expect(plan.startStageId, isNull);
      expect(plan.finalStageId, isNull);
      expect(plan.resolveArrival('s1').action, TrekArrivalAction.ignore);
    });

    test('sentier mono-etape : depart == fin (une seule etape)', () {
      // Un sentier a une seule etape : la garde anti-depart prime, donc arriver
      // a cette etape n'auto-complete pas (coherent : depart == fin ambigu,
      // l'arret reste manuel). Pas de crash, pas d'avancement.
      final mono = [_stage('only', 1)];
      final plan = TrekPlan.fromStages(
        mono,
        direction: 'NS',
        forwardDirectionCode: 'NS',
      );
      expect(plan.startStageId, 'only');
      expect(plan.finalStageId, 'only');
      expect(plan.resolveArrival('only').action, TrekArrivalAction.ignore);
    });
  });
}
