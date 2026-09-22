import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/planning/models/planned_day.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';

/// LES JOURS DE REPOS DU PROGRAMME ARRIVENT-ILS JUSQU'AU MOTEUR ? (#2-p)
///
/// LE DEFAUT QUE CE FICHIER INTERDIT DE REFAIRE. La contrainte C3 vaut
/// monotonie ÷ 2,0, et la monotonie de Foster vaut moyenne ÷ ecart-type des
/// charges journalieres, JOURS DE REPOS COMPTES COMME CHARGE NULLE. Si le
/// provider ne transmet pas les jours de repos, toutes les charges sont non
/// nulles, l'ecart-type s'effondre et la monotonie explose : mesure sur le
/// sentier de production, 4,04 — donc C3 a 2,02, donc circuit ROUGE sur les
/// 24 cellules de la campagne, y compris pour un profil expert dont la pire
/// etape est a 0,54, c'est-a-dire vert franc. Le calcul etait juste ; c'est
/// l'ALIMENTATION qui manquait.
///
/// Et depuis le retrait de C2 du maximum, C3 est le SEUL mecanisme capable de
/// rendre un circuit plus severe que toutes ses etapes : une C3 alimentee par
/// une donnee fausse serait un decideur unique qui decide faux.
void main() {
  const trailId = 'test-trail';

  StageModel stage(int n, double km, int gain) => StageModel(
        trailId: trailId,
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: km,
        elevationGainM: gain,
        elevationLossM: 0,
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      );

  final etapes = [stage(1, 10, 200), stage(2, 12, 300), stage(3, 11, 250)];

  /// Programme : chaque entree est soit une etape (1-based), soit un repos.
  List<PlannedDay> programme(List<int?> jours) => [
        for (var i = 0; i < jours.length; i++)
          PlannedDay(
            dayNumber: i + 1,
            stages:
                jours[i] == null ? const [] : [etapes[jours[i]! - 1]],
            isRestDay: jours[i] == null,
          ),
      ];

  ProviderContainer conteneur(List<PlannedDay> days) {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        plannedDaysProvider(trailId)
            .overrideWith((ref) => _ProgrammeFige(ref, days)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('traduction du PROGRAMME en jours de repos', () {
    test('aucun repos pose -> aucun repos transmis', () {
      final c = conteneur(programme([1, 2, 3]));
      expect(c.read(restDaysAfterStageProvider), isEmpty);
    });

    test('un repos apres l etape 2 -> index 1 (0-based)', () {
      final c = conteneur(programme([1, 2, null, 3]));
      expect(c.read(restDaysAfterStageProvider), {1});
    });

    test('deux repos -> les deux index', () {
      final c = conteneur(programme([1, null, 2, null, 3]));
      expect(c.read(restDaysAfterStageProvider), {0, 1});
    });

    test('un repos AVANT la premiere etape ne repose de rien', () {
      final c = conteneur(programme([null, 1, 2, 3]));
      expect(c.read(restDaysAfterStageProvider), isEmpty);
    });

    test('un jour qui REGROUPE deux etapes fait avancer l index de deux', () {
      final days = [
        PlannedDay(dayNumber: 1, stages: [etapes[0], etapes[1]]),
        const PlannedDay(dayNumber: 2, stages: [], isRestDay: true),
        PlannedDay(dayNumber: 3, stages: [etapes[2]]),
      ];
      final c = conteneur(days);
      // Le repos suit la DEUXIEME etape marchee, pas la premiere.
      expect(c.read(restDaysAfterStageProvider), {1});
    });
  });

  group('le repos change REELLEMENT le verdict rendu', () {
    Future<FeasibilityAssessment?> evaluerAvec(List<PlannedDay> days) async {
      final container = ProviderContainer(
        overrides: [
          trailIdProvider.overrideWithValue(trailId),
          plannedDaysProvider(trailId)
              .overrideWith((ref) => _ProgrammeFige(ref, days)),
          stageEffortsProvider.overrideWith((ref) async => const [
                StageEffort(
                    index: 0,
                    name: 'Etape 1',
                    distanceKm: 10,
                    elevationGainM: 200),
                StageEffort(
                    index: 1,
                    name: 'Etape 2',
                    distanceKm: 12,
                    elevationGainM: 300),
                StageEffort(
                    index: 2,
                    name: 'Etape 3',
                    distanceKm: 11,
                    elevationGainM: 250),
              ]),
          objectiveProfileProvider.overrideWith(
            (ref) async => const ObjectiveProfile(
              maxElevationGainPerDayDone: 1300,
              maxDistancePerDayDone: 30,
              maxConsecutiveDaysDone: 8,
              maxDailyEnergyKmDone: 0,
              habitualDailyEnergyKm: null,
              fitnessLevelRank: 1,
              hasWalkTest: false,
            ),
          ),
          hikerProfileProvider.overrideWith(() => _FicheFigee(
              const HikerProfile(age: 40, heightCm: 178, weightKg: 75))),
          trekConditionsProvider
              .overrideWith((ref) async => TrekConditions.unknown),
        ],
      );
      addTearDown(container.dispose);
      return container.read(feasibilityAssessmentProvider.future);
    }

    test('EXPERT sans repos : circuit ROUGE alors que ses etapes sont VERTES',
        () async {
      final a = await evaluerAvec(programme([1, 2, 3]));
      expect(a!.level, HikerLevel.expert);
      expect(a.stageVerdicts.every((v) => !v.isOverCapacity), isTrue,
          reason: 'chaque etape est tres en dessous de sa capacite');
      expect(a.worstStageVerdict, FeasibilityVerdict.green);
      expect(a.globalVerdict, FeasibilityVerdict.red);
      expect(a.circuit!.dominant, CircuitConstraint.rest);
      expect(a.restDaysPlanned, 0);
    });

    test('LE MEME EXPERT avec deux repos : circuit VERT', () async {
      final sans = await evaluerAvec(programme([1, 2, 3]));
      final avec = await evaluerAvec(programme([1, null, 2, null, 3]));
      expect(avec!.restDaysPlanned, 2);
      expect(avec.globalVerdict, FeasibilityVerdict.green);
      // La contrainte repos reste la plus haute des trois — c'est normal, elle
      // mesure une regularite et non un depassement — mais elle est redescendue
      // SOUS SON SEUIL, donc elle ne condamne plus le circuit.
      expect(avec.circuit!.rest, lessThan(1.0));
      expect(avec.circuit!.rest, lessThan(sans!.circuit!.rest!));
      // Le verdict, lui, a bien change de couleur.
      expect(sans.globalVerdict, FeasibilityVerdict.red);
    });
  });
}

/// Programme fige (evite tout le pipeline etapes / repartition).
class _ProgrammeFige extends PlannedDaysNotifier {
  _ProgrammeFige(Ref ref, List<PlannedDay> days) : super(const [], 1, ref) {
    state = days;
  }
}

/// Fiche d'info figee (evite la couche de persistance dans un test pur).
class _FicheFigee extends HikerProfileNotifier {
  _FicheFigee(this._profile);

  final HikerProfile _profile;

  @override
  Future<HikerProfile> build() async => _profile;
}
