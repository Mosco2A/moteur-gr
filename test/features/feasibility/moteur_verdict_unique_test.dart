import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/objective_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/feasibility/providers/trek_feasibility_provider.dart';
import 'package:moteur_gr/features/training/providers/training_plan_providers.dart';

/// UN SEUL MOTEUR DE VERDICT — non-regression du defaut MAJEUR-4 de la campagne
/// personas du 21/09 (rapport #100277).
///
/// CE QUI S'EST PASSE : l'ecran Faisabilite lisait le feu tricolore
/// ([FeasibilityFormula], seuils 0.85 / 1.10) pendant que l'ecran Entrainement
/// lisait un SECOND moteur (croisement par seuils 1.3 / 1.8). Mesure sur
/// l'appareil : 3 profils sur 6 — dont les deux plus courants — recevaient
/// « Faisable » d'un cote et « Votre faisabilite invite a la prudence » de
/// l'autre, pour le MEME randonneur et le MEME trek.
///
/// CE QUE CE TEST VERROUILLE : les deux lecteurs traversent desormais la MEME
/// chaine de providers reels (`objectiveProfile` -> `hikerLevel` ->
/// `feasibilityAssessment`). Seules les donnees BRUTES sont injectees. On
/// rejoue les 6 profils de la campagne et on exige l'egalite stricte des deux
/// lectures, profil par profil.
void main() {
  /// Trek de reference : 3 etapes, la plus dure a 37,8 km-energie (14 km +
  /// 1000 m de D+, unite V2). Rouge sous la capacite debutant (25,14), vert des
  /// la capacite confirme (55,57).
  ///
  /// RE-ANCRAGE DU 22/09 : les verdicts attendus ci-dessous ont ete remesures
  /// sur le moteur V2. Deux profils passent de VERT a ORANGE — l occasionnel et
  /// le senior — parce que l unite d energie de 42 m alourdit une etape a
  /// 71 m de D+ par kilometre, bien au-dessus du point de bascule de leur cran.
  /// Ce sont des bascules ATTENDUES, listees par la campagne (#9-c).
  const stages = <StageEffort>[
    StageEffort(index: 0, name: 'Depart -> Col', distanceKm: 14, elevationGainM: 1000),
    StageEffort(index: 1, name: 'Col -> Refuge', distanceKm: 12, elevationGainM: 600),
    StageEffort(index: 2, name: 'Refuge -> Village', distanceKm: 9, elevationGainM: 250),
  ];

  /// Un profil de la campagne : ce qu'il a deja fait + son age.
  ///
  /// [attendu] est le verdict du CIRCUIT, remesure sur le moteur V2.
  ({
    String cle,
    ObjectiveProfile objectif,
    HikerProfile fiche,
    FeasibilityVerdict attendu,
  }) profil(
    String cle, {
    required double dPlusParJour,
    required double kmParJour,
    required int joursConsecutifs,
    int age = 0,
    required FeasibilityVerdict attendu,
  }) {
    return (
      cle: cle,
      objectif: ObjectiveProfile(
        maxElevationGainPerDayDone: dPlusParJour,
        maxDistancePerDayDone: kmParJour,
        maxConsecutiveDaysDone: joursConsecutifs,
        // E_max_realise et charge habituelle, dans l unite d energie V2 : la
        // MEME journee sert aux deux, sinon on fabriquerait une journee que
        // personne n a faite (#2-g).
        maxDailyEnergyKmDone:
            FeasibilityScale.v2.energyOf(distanceKm: kmParJour, elevationGainM: dPlusParJour),
        habitualDailyEnergyKm: kmParJour <= 0 && dPlusParJour <= 0
            ? null
            : FeasibilityScale.v2.energyOf(distanceKm: kmParJour, elevationGainM: dPlusParJour),
        // Rang de forme median (aucun test 6 min) : le fallback de prod.
        fitnessLevelRank: 1,
        hasWalkTest: false,
      ),
      fiche: HikerProfile(age: age, heightCm: age == 0 ? 0 : 172, weightKg: age == 0 ? 0 : 70),
      attendu: attendu,
    );
  }

  /// Les 6 profils de la campagne personas (rapport #100277, famille 3).
  final profils = [
    profil('vierge',
        dPlusParJour: 0,
        kmParJour: 0,
        joursConsecutifs: 0,
        attendu: FeasibilityVerdict.red),
    profil('debutante',
        dPlusParJour: 200,
        kmParJour: 10,
        joursConsecutifs: 1,
        age: 32,
        attendu: FeasibilityVerdict.red),
    // Les 3 profils qui se contredisaient : ecran « Faisable », entrainement
    // « prudence ». C'est LE coeur de la non-regression.
    // Bascule V2 assumee : 0,68 (vert) en V1 -> 0,98 (orange) en V2.
    profil('occasionnel',
        dPlusParJour: 500,
        kmParJour: 16,
        joursConsecutifs: 2,
        age: 38,
        attendu: FeasibilityVerdict.orange),
    profil('confirme',
        dPlusParJour: 900,
        kmParJour: 23,
        joursConsecutifs: 5,
        age: 45,
        attendu: FeasibilityVerdict.green),
    // Bascule V2 assumee : l age lui coute un cran, et son plancher demontre
    // (44,4) devient sa base -> 0,85 franchi d un cheveu.
    profil('senior',
        dPlusParJour: 900,
        kmParJour: 23,
        joursConsecutifs: 5,
        age: 68,
        attendu: FeasibilityVerdict.orange),
    profil('expert',
        dPlusParJour: 1300,
        kmParJour: 28,
        joursConsecutifs: 8,
        age: 40,
        attendu: FeasibilityVerdict.green),
  ];

  ProviderContainer conteneurPour(
    ObjectiveProfile objectif,
    HikerProfile fiche,
  ) {
    final container = ProviderContainer(
      overrides: [
        // Donnees BRUTES seulement : tout le calcul reste celui de la prod.
        stageEffortsProvider.overrideWith((ref) async => stages),
        objectiveProfileProvider.overrideWith((ref) async => objectif),
        hikerProfileProvider
            .overrideWith(() => _FicheFigee(fiche)),
        // PROGRAMME AVEC DEUX JOURS DE REPOS. Sans repos, la monotonie de
        // Foster rend C3 dominante pour TOUT LE MONDE et les six profils
        // deviennent rouges : le test ne discriminerait plus rien, et ce
        // serait un artefact de fixture, pas une propriete du moteur. On pose
        // donc un programme realiste, et C1 redevient la contrainte qui mord.
        restDaysAfterStageProvider.overrideWithValue(const {0, 1}),
        // Conditions NEUTRES : ce test porte sur l unicite du moteur, pas sur
        // l altitude ni sur la saison. Les figer evite aussi d aller chercher
        // la trace GPX et les prefs, absentes d un test pur.
        trekConditionsProvider
            .overrideWith((ref) async => TrekConditions.unknown),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  for (final p in profils) {
    test('${p.cle} : Faisabilite et Entrainement rendent le MEME verdict',
        () async {
      final container = conteneurPour(p.objectif, p.fiche);

      // Lecture 1 — ce qu'affiche l'ecran Faisabilite (feu tricolore).
      final assessment =
          await container.read(feasibilityAssessmentProvider.future);
      // Lecture 2 — ce que lit le bandeau de l'ecran Entrainement.
      final perso =
          await container.read(trainingPersonalizationProvider.future);

      expect(assessment, isNotNull,
          reason: '${p.cle} : l ecran Faisabilite doit rendre un verdict');
      expect(assessment!.globalVerdict, p.attendu,
          reason: '${p.cle} : verdict remesure sur le moteur V2');
      // L'EGALITE STRICTE : un seul moteur, donc une seule reponse.
      expect(perso.verdict, assessment.globalVerdict,
          reason: '${p.cle} : les deux ecrans doivent dire la meme chose');
      // Et sa traduction UI : le bandeau de prudence suit le feu tricolore.
      expect(perso.needsCaution,
          assessment.globalVerdict != FeasibilityVerdict.green,
          reason: '${p.cle} : bandeau de prudence = tout sauf le vert');
    });
  }

  test('aucun trek charge : verdict indisponible des deux cotes', () async {
    final container = ProviderContainer(
      overrides: [
        stageEffortsProvider.overrideWith((ref) async => const <StageEffort>[]),
        objectiveProfileProvider.overrideWith(
          (ref) async => ObjectiveProfile.from(
            pastHikes: const [],
            walkTest: null,
          ),
        ),
        hikerProfileProvider
            .overrideWith(() => _FicheFigee(HikerProfile.empty)),
        restDaysAfterStageProvider.overrideWithValue(const <int>{}),
        trekConditionsProvider
            .overrideWith((ref) async => TrekConditions.unknown),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(feasibilityAssessmentProvider.future), isNull);
    final perso = await container.read(trainingPersonalizationProvider.future);
    expect(perso.verdict, isNull);
    // Pas de verdict -> pas de bandeau de prudence invente.
    expect(perso.needsCaution, isFalse);
  });
}

/// Fiche d'info figee (evite la couche de persistance dans un test pur).
class _FicheFigee extends HikerProfileNotifier {
  _FicheFigee(this._profile);

  final HikerProfile _profile;

  @override
  Future<HikerProfile> build() async => _profile;
}
