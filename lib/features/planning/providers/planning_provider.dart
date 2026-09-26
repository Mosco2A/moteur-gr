import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../../features/trail/providers/stages_provider.dart';
import '../../feasibility/domain/feasibility_formula.dart';
import '../../feasibility/domain/program_plan_search.dart';
import '../../feasibility/providers/advised_program_provider.dart';
import '../data/retained_plan_store.dart';
import '../domain/planning_calculator.dart';
import '../models/day_plan.dart';

/// Acces au stockage durable du decoupage retenu (surchargeable en test).
final retainedPlanStoreProvider =
    Provider<RetainedPlanStore>((ref) => const RetainedPlanStore());

/// DECOUPAGE RETENU par le randonneur pour le sentier courant — `null` tant
/// qu'il n'a rien choisi (correctif N2 / D2, mandat #100293).
///
/// C'est la DECISION, pas l'etat d'ecran : appliquer la reco de la faisabilite
/// ou bouger le curseur du Programme ecrit ici, et ce qui est ecrit ici
/// SURVIT au redemarrage (cf. [RetainedPlanStore]). Avant ce correctif, le
/// choix ne vivait qu'en memoire : choisir « 8 jours » ne laissait aucune
/// trace, ce qui rendait le bouton indistinguable d'un bouton mort.
///
/// Une valeur PAR SENTIER : changer de sentier recharge le plan de ce sentier.
class RetainedDurationNotifier extends Notifier<int?> {
  /// Sentier dont on porte le decoupage (re-lu a chaque bascule de sentier).
  String _trailId = '';

  @override
  int? build() {
    _trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    // Hydratation depuis le stockage durable. Asynchrone par nature : on rend
    // d'abord « aucun choix » (le sentier garde sa duree par defaut), puis on
    // pose la valeur retenue des qu'elle arrive. Meme patron que
    // `DownloadReminderNotifier` — `ref.mounted` protege du « Ref used after
    // dispose » si le provider est recycle pendant l'attente.
    _restore(_trailId);
    return null;
  }

  Future<void> _restore(String trailId) async {
    final days = await ref.read(retainedPlanStoreProvider).read(trailId);
    if (!ref.mounted || days == null) return;
    // Un changement de sentier pendant l'attente rendrait la valeur caduque.
    if (trailId != _trailId) return;
    state = days;
  }

  /// RETIENT [days] jours pour le sentier courant : effet immediat a l'ecran
  /// (le Programme, l'Itineraire et le Calendrier suivent) ET ecriture durable.
  Future<void> retain(int days) async {
    if (days <= 0) return;
    state = days;
    await ref.read(retainedPlanStoreProvider).write(_trailId, days);
  }

  /// Oublie le decoupage retenu : le sentier revient a sa duree par defaut.
  Future<void> forget() async {
    state = null;
    await ref.read(retainedPlanStoreProvider).clear(_trailId);
  }
}

final retainedDurationProvider =
    NotifierProvider<RetainedDurationNotifier, int?>(
        RetainedDurationNotifier.new);

/// REPOS CONSEILLES pour le sentier courant : COMBIEN de jours de repos
/// ramenent la monotonie de la pire semaine sous son seuil publie.
///
/// POURQUOI CE PROVIDER EXISTE (GO-61 du 22/09). Le programme par defaut ne
/// portait AUCUN jour de repos : le randonneur partait d'un itineraire qu'il
/// devait reparer sans savoir comment, et le chiffre du repos criait au rouge
/// pour tout le monde, expert compris. Il pose desormais les repos CONSEILLES.
/// Le repos ne decide plus du verdict — il conseille, et le conseil est
/// applique par defaut plutot que laisse a la charge du randonneur.
///
/// LE CALCUL N'EST PAS ICI, ET C'EST VOULU : il est dans le moteur
/// ([FeasibilityFormula.recommendedRestAfterStageIndex]), sur le meme seuil et
/// la meme fenetre que la contrainte C3 affichee. Deux calculs separes
/// finiraient par diverger, et l'ecran afficherait un chiffre pendant que le
/// programme en appliquerait un autre.
///
/// SENS DE MARCHE : le compte est fait sur l'ordre des etapes du sentier.
/// Inverser le sens ne change ni l'ensemble des energies ni, par symetrie de la
/// fenetre glissante, la pire d'entre elles — seul le placement arrondi des
/// repos pourrait, dans un cas limite, deplacer le compte d'une unite. C'est
/// une valeur PAR DEFAUT, que le randonneur reste libre de changer.
final recommendedRestDaysProvider =
    Provider.family<int, String>((ref, trailId) {
  final stages = ref.watch(stagesProvider(trailId)).maybeWhen(
        data: (list) => List<StageModel>.of(list)
          ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)),
        orElse: () => const <StageModel>[],
      );
  if (stages.length < 2) return 0;
  final energies = [
    for (final s in stages)
      FeasibilityScale.v2.energyOf(
        distanceKm: s.distanceKm,
        elevationGainM: s.elevationGainM,
      ),
  ];
  return FeasibilityFormula.recommendedRestAfterStageIndex(energies).length;
});

/// DUREE PAR DEFAUT DU SENTIER, REPOS CONSEILLES COMPRIS (GO-61).
///
/// C'est la duree qu'applique l'application tant que le randonneur n'a RETENU
/// aucun decoupage : les jours de marche du sentier, plus les jours de repos
/// que le moteur conseille. Bornee aux durees possibles du sentier, pour que la
/// valeur par defaut reste toujours atteignable par le selecteur.
final defaultDurationWithRestProvider =
    Provider.family<int, String>((ref, trailId) {
  final base = ref.watch(trailConfigProvider.select((c) => c.defaultDuration));
  final rest = ref.watch(recommendedRestDaysProvider(trailId));
  // Borne a la duree NATURELLE (tache 558) et non a la borne haute du curseur :
  // depuis que le curseur permet de COUPER les etapes, s'aligner sur son
  // maximum ferait s'ouvrir le sentier sur des etapes deja coupees en deux —
  // un decoupage que personne n'a demande.
  return ref
      .watch(durationBoundsProvider(trailId))
      .clampDefaultDuration(base + rest);
});

/// Duree EFFECTIVE du programme, en jours — source unique lue par le
/// Programme, l'Itineraire, le Calendrier et le Resume.
///
/// = le decoupage RETENU par le randonneur s'il en a choisi un
/// ([retainedDurationProvider]), sinon LA DUREE CONSEILLEE quand elle existe
/// (tache 569, R1-a), sinon la duree par defaut du sentier REPOS CONSEILLES
/// COMPRIS ([defaultDurationWithRestProvider], GO-61).
///
/// LE CURSEUR S'OUVRE SUR LA VALEUR CONSEILLEE (tache 569, R1-a).
///
/// DECISION DE CHRIS DU 26/09, VERBATIM : « OK mais le curseur est celui
/// conseille et il n'est jamais en rouge quand il est conseille en orange max ».
/// Avant, le curseur s'ouvrait sur le decoupage du TOPO — sept jours de marche
/// plus les repos conseilles — pendant que l'ecran Faisabilite conseillait une
/// autre valeur quelques lignes plus haut. Le randonneur lisait donc deux
/// chiffres, et celui sur lequel le curseur etait pose pouvait etre rouge.
///
/// LA VALEUR CONSEILLEE A ETE ESSAYEE AVANT D'ETRE PROPOSEE
/// ([ProgramPlanSearch.firstNonRed]) : son verdict est vert ou orange, jamais
/// rouge. Elle n'existe que si le profil est complet — un conseil est une sortie
/// du moteur de verdict, il n'existe pas la ou le verdict n'existe pas.
///
/// HYDRATATION ASYNCHRONE, MEME PATRON QUE LE DECOUPAGE RETENU : tant que le
/// conseil n'est pas calcule, on rend la duree par defaut du sentier, puis la
/// valeur conseillee des qu'elle arrive. Un choix deja RETENU l'emporte toujours
/// sur le conseil : le randonneur decide, l'application propose.
class SelectedDurationNotifier extends Notifier<int> {
  @override
  int build() {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final fallback = ref.watch(defaultDurationWithRestProvider(trailId));
    final retained = ref.watch(retainedDurationProvider);
    if (retained != null) return retained;
    final advised = ref.watch(advisedTotalDaysProvider).maybeWhen(
          data: (days) => days,
          orElse: () => null,
        );
    return advised ?? fallback;
  }

  /// Change la duree ET la retient durablement (D2) : toute duree choisie par
  /// le randonneur est une decision, d'ou qu'elle vienne — reco de la
  /// faisabilite ou curseur du Programme.
  void set(int duration) =>
      ref.read(retainedDurationProvider.notifier).retain(duration);
}

final selectedDurationProvider =
    NotifierProvider<SelectedDurationNotifier, int>(
        SelectedDurationNotifier.new);

/// Provider du planning calcule.
///
/// Combine les etapes du sentier (stagesProvider) et la duree
/// choisie (selectedDurationProvider) pour recalculer le planning
/// via PlanningCalculator a chaque changement.
final planningProvider =
    FutureProvider.family<List<DayPlan>, String>((ref, trailId) async {
  final stages = await ref.watch(stagesProvider(trailId).future);
  final duration = ref.watch(selectedDurationProvider);

  // Tache 558 : meme regle que le PROGRAMME editable — au-dela du budget de
  // repos du sentier, un jour de plus COUPE la journee la plus lourde au lieu
  // d'ajouter un repos de plus. Sans ce parametre, cette repartition et le
  // programme affiche finiraient par decrire deux itineraires differents.
  final maxRest = ref.watch(durationBoundsProvider(trailId)).restAllowance;
  return PlanningCalculator.distribute(stages, duration, maxRestDays: maxRest);
});

/// Bornes de duree (en jours) DERIVEES du nombre d'etapes du sentier.
///
/// Generique, jamais hardcode (pas de « 16 » en dur) : les bornes suivent le
/// nombre reel d'etapes charge pour le sentier courant, a la maniere de GR20
/// qui borne le curseur de duree selon le parcours.
///
/// Modele de duree = CIBLE (parite GR20) :
///  - `jours >= etapes` : une etape par jour, le surplus devient des jours de
///    repos (jusqu'a [maxDuration]) ;
///  - `jours < etapes`  : regroupement d'etapes (jusqu'a [minDuration]).
///
/// Bornes :
///  - min = moitie du nombre d'etapes (arrondi au superieur, plancher 1) :
///    borne basse raisonnable de regroupement (~2 etapes/jour au plus dense) ;
///  - max = tous les jours de marche atteignables (une etape peut occuper
///    jusqu'a [PlanningCalculator.maxDaysPerStage] journees) + la marge de
///    repos. Voir ci-dessous.
///
/// TACHE 558 — POURQUOI LA BORNE HAUTE A ETE ELARGIE. Elle valait « nombre
/// d'etapes + un tiers » : pour les 7 etapes du sentier de reference, 9 jours,
/// et Chris s'y est cogne — mot pour mot, « ca me propose 9jours, je peux pas
/// augmenter et ca met tout en rouge !!! ». Or entre 7 et 9, les deux seuls
/// jours disponibles ne pouvaient etre que du REPOS, et le repos ne change
/// RIEN a la pire journee, donc rien au verdict (GO-61). Le curseur butait
/// exactement la ou il aurait commence a servir. La borne haute couvre
/// desormais le DECOUPAGE : jusqu'a deux journees par etape, plus les repos.
class DurationBounds implements DurationSearchBounds {
  const DurationBounds({
    required this.min,
    required this.max,
    int? naturalMax,
    int? restAllowance,
  })  : _naturalMax = naturalMax,
        _restAllowance = restAllowance;

  @override
  final int min;

  @override
  final int max;

  final int? _naturalMax;
  final int? _restAllowance;

  /// JOURS DE REPOS QUE LE PROGRAMME POSE TOUT SEUL (tache 558).
  ///
  /// C'est le budget de repos AUTOMATIQUE : au-dela, un jour de plus n'est plus
  /// un repos mais un DECOUPAGE de la journee la plus dure. Sans ce plafond, le
  /// curseur ne saurait toujours qu'empiler des jours de repos — et le repos ne
  /// change rien a la pire journee, donc rien au verdict (GO-61).
  @override
  int get restAllowance => _restAllowance ?? (max - min).clamp(0, max);

  /// DUREE NATURELLE MAXIMALE : une etape par jour de marche, plus le repos.
  ///
  /// C'est l'ancienne borne haute, et elle reste celle du programme PAR DEFAUT
  /// — au-dela, on ne repartit plus, on COUPE, et une coupe est une decision du
  /// randonneur, jamais un defaut qu'on lui impose.
  int get naturalMax => _naturalMax ?? max;

  /// Calcule les bornes a partir du nombre d'etapes.
  ///
  /// [recommendedRestDays] : repos CONSEILLES par le moteur (GO-61). La borne
  /// haute ne peut pas etre PLUS BASSE que le conseil, sinon l'application
  /// proposerait un programme que son propre selecteur refuserait d'atteindre —
  /// et le randonneur verrait un conseil qu'il ne peut pas appliquer.
  factory DurationBounds.fromStageCount(int stageCount,
      {int recommendedRestDays = 0}) {
    if (stageCount <= 0) {
      return const DurationBounds(
          min: 1, max: 1, naturalMax: 1, restAllowance: 0);
    }
    if (stageCount == 1) {
      // Une seule etape : rien a regrouper, mais elle se COUPE comme les
      // autres — sinon un sentier d'une etape n'aurait aucun curseur du tout,
      // et aucun moyen d'alleger sa seule journee.
      return DurationBounds(
        min: 1,
        max: PlanningCalculator.maxWalkingDaysFor(1) + recommendedRestDays,
        naturalMax: 1 + recommendedRestDays,
        restAllowance: recommendedRestDays,
      );
    }
    final int min = (stageCount / 2).ceil().clamp(1, stageCount);
    final int restMargin = (stageCount / 3).round().clamp(1, stageCount);
    final int rest = math.max(restMargin, recommendedRestDays);
    // Tous les jours de MARCHE atteignables (decoupage compris) + le repos.
    return DurationBounds(
      min: min,
      max: PlanningCalculator.maxWalkingDaysFor(stageCount) + rest,
      naturalMax: stageCount + rest,
      restAllowance: rest,
    );
  }

  /// Liste discrete des durees proposees (min..max inclus), pour le selecteur.
  @override
  List<int> get options =>
      List<int>.generate(max - min + 1, (i) => min + i);

  /// Ramene une duree dans les bornes.
  int clampDuration(int duration) => duration.clamp(min, max);

  /// Ramene une duree dans les bornes du programme PAR DEFAUT (tache 558) :
  /// jamais au-dela de [naturalMax], pour qu'aucun sentier ne s'ouvre sur des
  /// etapes deja coupees en deux. Le decoupage se demande, il ne s'impose pas.
  int clampDefaultDuration(int duration) => duration.clamp(min, naturalMax);
}

/// Bornes de duree du sentier courant (derivees du nombre d'etapes charge).
///
/// Tant que les etapes ne sont pas chargees, se rabat sur les bornes de la
/// config du sentier ([TrailConfig.availableDurations]) pour rester coherent
/// avant l'arrivee des donnees.
final durationBoundsProvider =
    Provider.family<DurationBounds, String>((ref, trailId) {
  final stagesAsync = ref.watch(stagesProvider(trailId));
  final recommendedRest = ref.watch(recommendedRestDaysProvider(trailId));
  return stagesAsync.maybeWhen(
    data: (stages) => DurationBounds.fromStageCount(
      stages.length,
      recommendedRestDays: recommendedRest,
    ),
    orElse: () {
      final config = ref.watch(trailConfigProvider);
      final durations = config.availableDurations;
      if (durations.isEmpty) {
        return DurationBounds(
            min: config.defaultDuration, max: config.defaultDuration);
      }
      return DurationBounds(
        min: durations.reduce((a, b) => a < b ? a : b),
        max: durations.reduce((a, b) => a > b ? a : b),
      );
    },
  );
});
