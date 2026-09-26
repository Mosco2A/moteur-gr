import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_plan.freezed.dart';
part 'training_plan.g.dart';

/// Plan d'entrainement EXTERNALISE par sentier (StepWays LOT 5, sous-ensemble A).
///
/// Le plan (duree + phases + seances + objectif) est une DONNEE chargee depuis
/// `assets/data/training_plans.json`, PAS du code (prepare la V2 : plan adaptatif
/// par curseur, L11). La duree ([durationWeeks]) est un CHAMP DE DONNEES reglable
/// (6/8/12 sem) sans recompilation — leve l'arbitrage A9 sans le figer.
///
/// AGNOSTIQUE AU SENTIER : le plan cite des reperes du sentier charge (objectif
/// = une etape-repere), jamais « GR20 » en dur. i18n 5 langues INLINE (meme
/// patron que [TipCard]) : fr base + en/de/it/es, resolus par langue courante.
@freezed
abstract class TrainingPlan with _$TrainingPlan {
  const TrainingPlan._();

  const factory TrainingPlan({
    /// Identifiant du sentier cible (`mare-a-mare-centre`, ...) ou `default`.
    required String trailId,

    /// Duree totale du plan en semaines (CHAMP DE DONNEES, reglable 6/8/12).
    @Default(8) int durationWeeks,

    /// Phases progressives (Fondation / Denivele / Endurance), ordonnees.
    @Default(<TrainingPhase>[]) List<TrainingPhase> phases,

    /// Objectif chiffre a atteindre avant le depart (encart orange).
    TrainingObjective? objective,
  }) = _TrainingPlan;

  /// Nombre total de seances du plan (toutes phases confondues).
  int get totalSessions =>
      phases.fold(0, (sum, p) => sum + p.sessions.length);

  /// Deserialisation depuis JSON (asset `training_plans.json`).
  factory TrainingPlan.fromJson(Map<String, dynamic> json) =>
      _$TrainingPlanFromJson(json);
}

/// Une phase progressive du plan (bloc depliable de la maquette).
///
/// Ex : Fondation (S1-2), Denivele (S3-5), Endurance (S6-8). Chaque phase porte
/// ses semaines de debut/fin (pour le libelle « Semaines X-Y »), un intitule +
/// une accroche i18n, une icone, et ses seances cochables.
@freezed
abstract class TrainingPhase with _$TrainingPhase {
  const TrainingPhase._();

  const factory TrainingPhase({
    /// Identifiant stable de la phase (`foundation`, `elevation`, `endurance`).
    required String id,

    /// Premiere semaine de la phase (1-based, pour « Semaines X-Y »).
    required int weekStart,

    /// Derniere semaine de la phase (1-based).
    required int weekEnd,

    /// Nom de l'icone Material (resolu cote UI, jamais d'IconData en donnee).
    @Default('directions_walk') String icon,

    /// Intitule de la phase — francais (base).
    required String titleFr,
    @Default('') String titleEn,
    @Default('') String titleDe,
    @Default('') String titleIt,
    @Default('') String titleEs,

    /// Accroche courte de la phase — francais (base).
    @Default('') String subtitleFr,
    @Default('') String subtitleEn,
    @Default('') String subtitleDe,
    @Default('') String subtitleIt,
    @Default('') String subtitleEs,

    /// Seances cochables de la phase.
    @Default(<TrainingSession>[]) List<TrainingSession> sessions,
  }) = _TrainingPhase;

  factory TrainingPhase.fromJson(Map<String, dynamic> json) =>
      _$TrainingPhaseFromJson(json);
}

/// Rythme d'une seance : combien de fois, et quand (tache 570, S3-a).
///
/// Une seance sans rythme n'est pas une seance, c'est un TYPE de seance. Toutes
/// les valeurs ici sont SOURCEES (voir [TrainingSession.timesPerWeek]).
enum SessionOccurrence {
  /// Seance HEBDOMADAIRE : [TrainingSession.timesPerWeek] fois par semaine.
  weekly,

  /// Seance a faire UNE FOIS dans la phase (ex. le test du materiel sur deux
  /// jours enchaines : ce n'est pas un rythme, c'est un rendez-vous).
  oncePerPhase,

  /// Seance de la DERNIERE SEMAINE seulement (l'affutage).
  finalWeek,
}

/// Une seance d'entrainement cochable (ligne d'un bloc de phase).
///
/// L'identifiant [id] est STABLE et sert de cle de persistance locale (seances
/// faites) — jamais un index, pour que le coche survive a un changement de plan.
@freezed
abstract class TrainingSession with _$TrainingSession {
  const TrainingSession._();

  const factory TrainingSession({
    /// Identifiant STABLE de la seance (cle de persistance du coche).
    required String id,

    /// Libelle de la seance — francais (base).
    required String labelFr,
    @Default('') String labelEn,
    @Default('') String labelDe,
    @Default('') String labelIt,
    @Default('') String labelEs,

    /// FREQUENCE HEBDOMADAIRE de la seance (tache 570, S3-a).
    ///
    /// LE DEFAUT QUE CE CHAMP CORRIGE. Le plan listait des TYPES de seances
    /// (« sortie cardio », « marche ») et l'ecran les presentait comme des
    /// seances UNIQUES cochables : deux semaines de Fondation semblaient donc
    /// ne demander qu'UNE sortie cardio. Retour Chris du 26/09, mot pour mot :
    /// « une seule sortie cardio c'est vraiment peu idem pour la sortie
    /// marche ». Le plan ne disait pas combien de fois — il le dit maintenant.
    ///
    /// AUCUN CHIFFRE N'EST INVENTE (regle #6178). La semaine de reference est
    /// celle de REI Expert Advice, « Conditioning for Backpacking & Hiking » :
    /// 3 seances de cardio non consecutives + 2 jours de renforcement non
    /// consecutifs + 2 jours de repos. Le renforcement a 2 jours est confirme
    /// par les recommandations 2020 de l'OMS (« muscle-strengthening activities
    /// on 2 or more days a week »). La sortie longue hebdomadaire vient de
    /// Terres d'Aventure (« marchez tous les week-ends, 5 a 6 h minimum, avec
    /// un sac a dos de 5 a 10 kg »), le travail de denivele deux fois par
    /// semaine de Randonner Malin (« monter 1500 marches et descendre 1500
    /// marches 2 fois par semaine »).
    ///
    /// Ignore quand [occurrence] n'est pas [SessionOccurrence.weekly].
    @Default(0) int timesPerWeek,

    /// Rythme de la seance (hebdomadaire par defaut).
    @Default(SessionOccurrence.weekly) SessionOccurrence occurrence,
  }) = _TrainingSession;

  /// Vrai si la seance porte un rythme exploitable (affichable a l'ecran).
  ///
  /// Une seance hebdomadaire sans frequence est une DONNEE INCOMPLETE : l'ecran
  /// n'affiche alors aucun rythme plutot qu'un « 0x par semaine » absurde.
  bool get hasFrequency =>
      occurrence != SessionOccurrence.weekly || timesPerWeek > 0;

  factory TrainingSession.fromJson(Map<String, dynamic> json) =>
      _$TrainingSessionFromJson(json);
}

/// Objectif chiffre du plan (encart orange « objectif cle » de la maquette).
///
/// Reprend un REPERE du sentier charge (ex. l'etape la plus dure) : « tenir N h
/// de marche avec M m de montee ». Les chiffres viennent de la DONNEE du sentier
/// (jamais en dur). i18n INLINE.
@freezed
abstract class TrainingObjective with _$TrainingObjective {
  const TrainingObjective._();

  const factory TrainingObjective({
    /// Enonce de l'objectif — francais (base).
    required String labelFr,
    @Default('') String labelEn,
    @Default('') String labelDe,
    @Default('') String labelIt,
    @Default('') String labelEs,
  }) = _TrainingObjective;

  factory TrainingObjective.fromJson(Map<String, dynamic> json) =>
      _$TrainingObjectiveFromJson(json);
}
