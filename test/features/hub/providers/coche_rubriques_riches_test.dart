import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/checklist_dao.dart';
import 'package:moteur_gr/core/data/daos/nuitee_selections_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/checklist/data/checklist_template.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/hub/providers/prepare_progress_providers.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/safety/providers/health_prepare_providers.dart';
import 'package:moteur_gr/features/training/models/training_plan.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';
import 'package:moteur_gr/shared/widgets/step_status_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coche_de_preparation_banc.dart';

/// LA COCHE DE PREPARATION, CALCULEE — LES QUATRE RUBRIQUES A TROIS ETATS PLEINS
/// (Materiel, Nuitees, Preparation physique, Fiche medicale), et les regles pures.
///
/// Chaque rubrique est nourrie par SA VRAIE SOURCE PERSISTEE, fabriquee ici :
/// preferences simulees pour les signaux en preferences, base Drift EN MEMOIRE
/// pour le sac et les nuitees, dossier temporaire pour la carte hors ligne.
/// Rien n'est pose a la main dans le calculateur : si une source change de
/// forme, c'est ce fichier qui rougit, pas l'ecran de Christophe.
///
/// Pour chaque rubrique : le cas VIDE (rien de persiste), le cas PARTIEL et le
/// cas COMPLET. Les rubriques a deux etats le disent, et les trois rubriques
/// sans source le prouvent : pas de coche, jamais.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final banc = BancDeCoche();
  final trailId = banc.trailId;
  ProviderContainer conteneur({
    HikerProfile profil = HikerProfile.empty,
    List<Override> plus = const [],
  }) => banc.conteneur(profil: profil, plus: plus);
  Future<PlanningStepStatus?> coche(
    ProviderContainer c,
    SujetDePreparation s,
  ) => banc.coche(c, s);

  group('les regles pures', () {
    test('trois etats depuis un compte, et zero sur zero n est pas fait', () {
      expect(
        statutParCompte(faits: 0, total: 5),
        PlanningStepStatus.notStarted,
      );
      expect(
        statutParCompte(faits: 2, total: 5),
        PlanningStepStatus.inProgress,
      );
      expect(statutParCompte(faits: 5, total: 5), PlanningStepStatus.completed);
      expect(
        statutParCompte(faits: 0, total: 0),
        PlanningStepStatus.notStarted,
      );
    });

    test('le sac : une ligne orpheline d un ancien modele ne compte pas', () {
      ChecklistItem ligne(
        String id, {
        bool coche = false,
        bool perso = false,
      }) => ChecklistItem(
        id: 0,
        trailId: trailId,
        itemId: id,
        category: 'test',
        isChecked: coche,
        weightGrams: 0,
        quantity: 1,
        isCustom: perso,
        inShoppingList: false,
      );
      expect(
        statutMateriel(
          lignes: [ligne('a', coche: true), ligne('retire', coche: true)],
          idsDuModele: {'a', 'b'},
        ),
        PlanningStepStatus.inProgress,
        reason: 'b n est pas coche ; « retire » n est plus au modele',
      );
      expect(
        statutMateriel(
          lignes: [ligne('a', coche: true), ligne('b', coche: true)],
          idsDuModele: {'a', 'b'},
        ),
        PlanningStepStatus.completed,
      );
    });

    test('« fait » l emporte sur « entame »', () {
      expect(
        statutATroisEtats(fait: true, entame: true),
        PlanningStepStatus.completed,
      );
    });
  });

  group('MATERIEL — articles coches parmi ceux du sac', () {
    final modele = [for (final a in defaultChecklistTemplate) a.id];
    Future<void> poser(
      String itemId, {
      bool coche = false,
      bool perso = false,
    }) => ChecklistDao(banc.db).upsertItem(
      ChecklistItemsCompanion(
        trailId: Value(trailId),
        itemId: Value(itemId),
        category: const Value('test'),
        isChecked: Value(coche),
        isCustom: Value(perso),
      ),
    );

    test('VIDE : sac jamais ouvert, aucune ligne -> a faire', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.materiel),
        PlanningStepStatus.notStarted,
      );
    });

    test('VIDE : sac amorce, rien de coche -> a faire', () async {
      for (final id in modele) {
        await poser(id);
      }
      expect(
        await coche(conteneur(), SujetDePreparation.materiel),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : un article coche sur tout le sac -> entame', () async {
      for (final id in modele) {
        await poser(id, coche: id == modele.first);
      }
      expect(
        await coche(conteneur(), SujetDePreparation.materiel),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : tout le modele coche -> fait', () async {
      for (final id in modele) {
        await poser(id, coche: true);
      }
      expect(
        await coche(conteneur(), SujetDePreparation.materiel),
        PlanningStepStatus.completed,
      );
    });

    test(
      'un article PERSONNEL non coche retient la coche, comme a l ecran',
      () async {
        for (final id in modele) {
          await poser(id, coche: true);
        }
        await poser('custom_frontale_de_rechange', perso: true);
        expect(
          await coche(conteneur(), SujetDePreparation.materiel),
          PlanningStepStatus.inProgress,
        );
      },
    );

    test(
      'le cockpit relit le sac quand on l invalide (retour de l ecran)',
      () async {
        for (final id in modele) {
          await poser(id, coche: id != modele.last);
        }
        final c = conteneur();
        expect(
          await coche(c, SujetDePreparation.materiel),
          PlanningStepStatus.inProgress,
        );
        await ChecklistDao(banc.db).toggleItem(trailId, modele.last, true);
        c.invalidate(lignesDuSacProvider(trailId));
        expect(
          await coche(c, SujetDePreparation.materiel),
          PlanningStepStatus.completed,
        );
      },
    );
  });

  group('NUITEES — nuits reservees parmi celles du programme', () {
    StageModel etape(int n) => StageModel(
      trailId: trailId,
      stageNumber: n,
      name: 'Etape $n',
      distanceKm: 10,
      elevationGainM: 500,
      elevationLossM: 400,
      startLat: 42,
      startLng: 9,
      endLat: 42.1,
      endLng: 9.1,
    );

    /// Trois jours de marche : quatre nuits a reserver, veille du depart (N0)
    /// comprise — exactement le compte de l'ecran Nuitees.
    ProviderContainer avecProgramme() => conteneur(
      plus: [
        plannedDaysProvider(trailId).overrideWith(
          (ref) => PlannedDaysNotifier([etape(1), etape(2), etape(3)], 3, ref),
        ),
      ],
    );

    Future<void> reserver(List<int> jours) async {
      for (final j in jours) {
        await NuiteeSelectionsDao(banc.db).setBooked(trailId, j, true);
      }
    }

    test('VIDE : aucune nuit reservee -> a faire', () async {
      expect(
        await coche(avecProgramme(), SujetDePreparation.nuitees),
        PlanningStepStatus.notStarted,
      );
    });

    test(
      'PARTIEL : les trois nuits du programme, pas la veille -> entame',
      () async {
        await reserver([1, 2, 3]);
        expect(
          await coche(avecProgramme(), SujetDePreparation.nuitees),
          PlanningStepStatus.inProgress,
        );
      },
    );

    test('COMPLET : les quatre nuits, veille comprise -> fait', () async {
      await reserver([0, 1, 2, 3]);
      expect(
        await coche(avecProgramme(), SujetDePreparation.nuitees),
        PlanningStepStatus.completed,
      );
    });

    test('le cockpit relit les nuits quand on l invalide', () async {
      await reserver([0, 1, 2]);
      final c = avecProgramme();
      expect(
        await coche(c, SujetDePreparation.nuitees),
        PlanningStepStatus.inProgress,
      );
      await reserver([3]);
      c.invalidate(nuitsReserveesProvider(trailId));
      expect(
        await coche(c, SujetDePreparation.nuitees),
        PlanningStepStatus.completed,
      );
    });

    test('une nuit hors programme ne gonfle pas le compte', () async {
      await reserver([0, 1, 2, 9]);
      expect(
        await coche(avecProgramme(), SujetDePreparation.nuitees),
        PlanningStepStatus.inProgress,
      );
    });
  });

  group('PREPARATION PHYSIQUE — seances cochees parmi celles du plan', () {
    const plan = TrainingPlan(
      trailId: 'test-trail',
      phases: [
        TrainingPhase(
          id: 'fondation',
          weekStart: 1,
          weekEnd: 4,
          titleFr: 'Fondation',
          sessions: [
            TrainingSession(id: 's1', labelFr: 'Marche'),
            TrainingSession(id: 's2', labelFr: 'Cote'),
          ],
        ),
        TrainingPhase(
          id: 'endurance',
          weekStart: 5,
          weekEnd: 8,
          titleFr: 'Endurance',
          sessions: [TrainingSession(id: 's3', labelFr: 'Sortie longue')],
        ),
      ],
    );

    ProviderContainer avecPlan() => conteneur(
      plus: [trainingPlanProvider.overrideWith((ref) async => plan)],
    );

    void fait(List<String> seances) => SharedPreferences.setMockInitialValues({
      trainingDoneKey(trailId): seances,
    });

    test('VIDE : aucune seance -> a faire', () async {
      expect(
        await coche(avecPlan(), SujetDePreparation.preparationPhysique),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : une seance sur trois -> entame', () async {
      fait(['s2']);
      expect(
        await coche(avecPlan(), SujetDePreparation.preparationPhysique),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : les trois seances -> fait', () async {
      fait(['s1', 's2', 's3']);
      expect(
        await coche(avecPlan(), SujetDePreparation.preparationPhysique),
        PlanningStepStatus.completed,
      );
    });

    test('une coche orpheline d un ancien plan ne compte pas', () async {
      fait(['ancienne', 's1', 's2']);
      expect(
        await coche(avecPlan(), SujetDePreparation.preparationPhysique),
        PlanningStepStatus.inProgress,
      );
    });
  });

  group('FICHE MEDICALE — remplie ET conseils lus', () {
    void signaux(List<String> s) =>
        SharedPreferences.setMockInitialValues({kHealthPrepareStepsKey: s});

    test('VIDE : aucun signal -> a faire', () async {
      expect(
        await coche(conteneur(), SujetDePreparation.ficheMedicale),
        PlanningStepStatus.notStarted,
      );
    });

    test('PARTIEL : remplie, conseils non lus -> entame', () async {
      signaux(['filled']);
      expect(
        await coche(conteneur(), SujetDePreparation.ficheMedicale),
        PlanningStepStatus.inProgress,
      );
    });

    test('PARTIEL : recopiee dans le telephone seulement -> entame', () async {
      signaux(['phoneCardCopied']);
      expect(
        await coche(conteneur(), SujetDePreparation.ficheMedicale),
        PlanningStepStatus.inProgress,
      );
    });

    test('COMPLET : remplie et conseils lus -> fait', () async {
      signaux(['filled', 'adviceRead']);
      expect(
        await coche(conteneur(), SujetDePreparation.ficheMedicale),
        PlanningStepStatus.completed,
      );
    });
  });
}
