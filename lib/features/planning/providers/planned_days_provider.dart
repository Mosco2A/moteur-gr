import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/stage.dart';
import '../../trail/providers/stages_provider.dart';
import '../../trek/providers/gps_providers.dart';
import '../domain/planning_calculator.dart';
import '../domain/trek_edit_lock.dart';
import '../models/day_plan.dart';
import '../models/planned_day.dart';
import 'planning_provider.dart';
import 'trek_edit_lock_provider.dart';

/// PROGRAMME editable (parite GR20 `plannedDaysProvider`).
///
/// Source generique : les etapes du sentier courant ([stagesProvider]) reparties
/// sur la duree choisie ([selectedDurationProvider], deja pilotee par l'ecran
/// Programme et le reste de l'app). Le calcul initial reutilise
/// [PlanningCalculator.distribute] (meme moteur que la repartition), puis
/// l'utilisateur EDITE : reorganiser, regrouper / separer des etapes, ajouter /
/// supprimer des jours de repos, replanifier. Aucune localite en dur.
///
/// Famille indexee par `trailId` (multi-sentiers). Recree quand les etapes, la
/// duree OU LE SENS de marche changent (via `ref.watch`), en preservant les
/// jours de repos manuels (cache externe [manualRestDayCacheProvider], meme
/// strategie que GR20).
///
/// SENS de marche (retour QA polish, coherence Itineraire<->Programme) : le
/// programme honore [selectedDirectionProvider] a l'identique de l'itineraire
/// (itinerary_providers.dart). Quand l'utilisateur inverse le sens, l'ORDRE des
/// etapes est inverse AVANT la repartition en jours -> Jour 1 = etape de depart
/// du sens choisi. Sens de reference (ordre croissant) = 1er code de
/// `TrailConfig.directions` (fourni par le sentier, jamais devine).
final plannedDaysProvider = StateNotifierProvider.family<PlannedDaysNotifier,
    List<PlannedDay>, String>((ref, trailId) {
  // Etapes du sentier courant (asynchrones). Tant qu'elles ne sont pas la, on
  // part d'une liste vide : l'ecran affiche alors son etat vide, puis le
  // provider est recree avec les etapes reelles (ref.watch).
  final stagesAsync = ref.watch(stagesProvider(trailId));
  final duration = ref.watch(selectedDurationProvider);
  final sorted = stagesAsync.maybeWhen(
    data: (list) => List<StageModel>.of(list)
      ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber)),
    orElse: () => const <StageModel>[],
  );

  // Sens de marche : inverse l'ordre des etapes si le sens choisi n'est pas le
  // sens de reference (parite avec itineraryProvider #12b). Direction-aware,
  // sans nombre en dur ; le sens de reference est le 1er declare par le sentier.
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final reversed = forward != null && selected != null && selected != forward;
  final stages = reversed ? sorted.reversed.toList() : sorted;

  // TACHE 558 — LE JOUR EN TROP DEVIENT UN DECOUPAGE, PAS UN REPOS DE PLUS.
  // Au-dela du budget de repos du sentier ([DurationBounds.restAllowance], qui
  // couvre le repos CONSEILLE de GO-61), un jour supplementaire COUPE la
  // journee la plus lourde au lieu d'ajouter un repos : c'est le seul levier
  // qui allege la pire journee, donc le seul qui peut changer le verdict.
  final maxRest = ref.watch(durationBoundsProvider(trailId)).restAllowance;

  final cachedRestDays = ref.read(manualRestDayCacheProvider);
  final notifier =
      PlannedDaysNotifier(stages, duration, ref, maxRestDays: maxRest);
  if (cachedRestDays.isNotEmpty) {
    notifier.restoreRestDaysFromCache(cachedRestDays);
  }

  // R12 (LOT L9) — VERROU « rando en cours ». Le verrou est INJECTE par
  // `ref.listen` et NON par `ref.watch` : c'est volontaire. Un `watch`
  // RECREERAIT le notifier a chaque etape terminee, effacant les modifications
  // que le randonneur vient justement de faire sur ses jours a venir. Avec
  // `listen`, le notifier vit, et seul son verrou se met a jour (fireImmediately
  // pose l'etat initial des la creation, avant tout affichage).
  ref.listen<TrekEditLock>(
    trekEditLockProvider,
    (_, next) => notifier.applyEditLock(next),
    fireImmediately: true,
  );

  return notifier;
});

/// Cache externe des positions (index) des jours de repos manuels.
///
/// Survit aux recreations du notifier par `ref.watch` (parite GR20 : les repos
/// ajoutes a la main ne doivent pas disparaitre a chaque changement de duree).
///
/// PUBLIC DEPUIS LA TACHE 565 (LOT N, N1), ET POUR UNE SEULE RAISON : c'est la
/// SEULE trace du programme edite a la main qui echappe a l'invalidation du
/// notifier — elle est faite pour lui survivre. Le droit a l'effacement doit
/// donc pouvoir la nommer (`account_erasure_provider.dart`), et un test doit
/// pouvoir prouver qu'elle est bien partie. Le rendre prive rendait
/// l'effacement de ce point aveugle.
final manualRestDayCacheProvider = StateProvider<List<int>>((ref) => const []);

/// Notifier du PROGRAMME editable (drag & drop, regrouper / separer, repos).
///
/// Porte a l'identique la grammaire d'edition de GR20 (`PlannedDaysNotifier`),
/// mais generique : il opere sur des [StageModel] du sentier courant et non sur
/// une base d'etapes en dur.
class PlannedDaysNotifier extends StateNotifier<List<PlannedDay>> {
  PlannedDaysNotifier(this._stages, this._duration, this._ref,
      {int? maxRestDays})
      : _maxRestDays = maxRestDays,
        _hasManualEdits = false,
        super(_generate(_stages, _duration, maxRestDays));

  final List<StageModel> _stages;
  final int _duration;
  final Ref _ref;

  /// Repos CONSEILLE par le moteur (GO-61) — plafond du repos AUTOMATIQUE.
  ///
  /// Au-dela, un jour de plus est un DECOUPAGE et non un repos (tache 558).
  /// `null` = plafond absent, tout le surplus part en repos (comportement
  /// d'origine, conserve pour les appels qui ne connaissent pas le conseil).
  final int? _maxRestDays;

  bool _hasManualEdits;

  /// Verrou « rando en cours » (R12). [TrekEditLock.none] en preparation.
  TrekEditLock _editLock = TrekEditLock.none;

  /// Limite de temps de marche pour un regroupement manuel (parite GR20 : 16 h).
  static const double maxManualHoursPerDay = 16.0;

  // --- R12 : garde « on ne modifie que ce qui n'est pas encore fait » ---

  /// Injecte l'etat de rando observe (appele par le provider via `ref.listen`).
  ///
  /// Ne touche PAS a `state` : le verrou ne reecrit jamais le programme, il ne
  /// fait qu'interdire certaines mutations. Un changement de verrou ne provoque
  /// donc aucun rebuild inutile ni aucune perte d'edition.
  void applyEditLock(TrekEditLock lock) => _editLock = lock;

  /// Verrou courant (expose pour l'UI : libelles, badges « fait »).
  TrekEditLock get editLock => _editLock;

  /// L'etape [stageNumber] est-elle deja MARCHEE ?
  bool isStageDone(int stageNumber) => _editLock.isStageDone(stageNumber);

  /// Nombre de jours FIGES en tete de programme (R12).
  ///
  /// Un jour est fige des qu'il contient au moins une etape deja marchee ; tous
  /// les jours qui le PRECEDENT le sont aussi — un jour de repos deja passe est
  /// passe, meme s'il ne porte aucune etape. On calcule donc l'index du DERNIER
  /// jour contenant une etape faite, et tout ce qui est avant (inclus) est fige.
  /// Vaut 0 en preparation (aucune etape faite) : programme entierement libre.
  int get lockedDayCount {
    if (_editLock.doneStageIds.isEmpty) return 0;
    var last = -1;
    for (var i = 0; i < state.length; i++) {
      final day = state[i];
      if (day.stages.any((s) => _editLock.isStageDone(s.stageNumber))) {
        last = i;
      }
    }
    return last + 1;
  }

  /// Le jour [index] est-il fige (deja fait) ?
  bool isDayLocked(int index) => index < lockedDayCount;

  /// L'ordre des jours peut-il encore etre change ?
  ///
  /// NON des que le trek est demarre : regle metier « AUCUNE inversion de
  /// l'ordre des etapes » (on ne peut pas marcher l'etape 6 avant la 5 apres
  /// coup). Vaut aussi pour l'ecran Programme de la preparation, qui reste
  /// joignable pendant la rando via l'accordeon « Preparer ».
  bool get canReorder => !_editLock.trekStarted;

  /// Genere le programme initial : repartition des etapes sur la duree via le
  /// meme calculateur que l'ecran de repartition, converti en jours editables.
  static List<PlannedDay> _generate(
    List<StageModel> stages,
    int duration, [
    int? maxRestDays,
  ]) {
    if (stages.isEmpty) return const [];
    final plans = PlanningCalculator.distribute(
      stages,
      duration,
      maxRestDays: maxRestDays,
    );
    return _fromDayPlans(plans);
  }

  /// Convertit les [DayPlan] (calcul) en [PlannedDay] (editables) puis
  /// renumerote. Un [DayPlan.isRestDay] devient un jour de repos sans etape.
  static List<PlannedDay> _fromDayPlans(List<DayPlan> plans) {
    final days = <PlannedDay>[];
    for (final p in plans) {
      days.add(PlannedDay(
        dayNumber: p.dayNumber,
        stages: p.isRestDay ? const [] : List<StageModel>.of(p.stages),
        isRestDay: p.isRestDay,
      ));
    }
    return _renumber(days);
  }

  // --- Etat derive ---

  /// Indique si le programme contient au moins un jour de repos.
  bool get hasManualRestDays => state.any((d) => d.isRestDay);

  /// Indique si l'utilisateur a fait des modifications manuelles.
  bool get hasManualEdits => _hasManualEdits;

  // --- Edition : reorganiser ---

  /// Reordonne les jours (drag & drop). Corrige l'index cible comme le
  /// `ReorderableListView` de Material (parite GR20).
  ///
  /// R12 : REFUSE des que le trek est demarre (aucune inversion possible) —
  /// la garde est ici, au niveau du domaine, pour qu'aucune porte d'entree
  /// (ecran Programme de la prepa comprise) ne puisse la contourner.
  void reorder(int oldIndex, int newIndex) {
    if (!canReorder) return;
    final days = List<PlannedDay>.of(state);
    if (newIndex > oldIndex) newIndex--;
    final item = days.removeAt(oldIndex);
    days.insert(newIndex, item);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Edition : jours de repos ---

  /// Le repos peut-il etre insere apres le jour [afterIndex] ?
  ///
  /// R12 : oui seulement si le repos atterrit dans le FUTUR. Inserer apres un
  /// jour fige qui n'est pas le dernier fige decalerait des jours deja faits.
  bool canAddRestDayAfter(int afterIndex) => afterIndex + 1 >= lockedDayCount;

  /// Ajoute un jour de repos apres [afterIndex] (parite GR20).
  ///
  /// R12 : refuse si l'insertion tomberait dans la partie deja faite.
  void addRestDay(int afterIndex) {
    if (!canAddRestDayAfter(afterIndex)) return;
    final days = List<PlannedDay>.of(state);
    days.insert(
      afterIndex + 1,
      const PlannedDay(dayNumber: 0, stages: [], isRestDay: true),
    );
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  /// Supprime le jour de repos a [index] (parite GR20).
  ///
  /// R12 : un jour de repos DEJA PASSE (dans le prefixe fige) ne se supprime
  /// pas — il a eu lieu.
  void removeRestDay(int index) {
    if (index < 0 || index >= state.length) return;
    if (!state[index].isRestDay) return;
    if (isDayLocked(index)) return;
    final days = List<PlannedDay>.of(state)..removeAt(index);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Edition : regrouper / separer (parite GR20 merge / split) ---

  double _hoursFor(List<StageModel> stages) => stages.fold<double>(
      0, (sum, s) => sum + PlanningCalculator.estimatedHours(s));

  /// Message explicatif si le regroupement avec le jour suivant est impossible.
  /// `null` si le regroupement est possible (parite GR20 `mergeBlockedReason`,
  /// libelles i18n a l'appelant : ici on ne renvoie qu'un code semantique).
  String? mergeBlockedReason(int dayIndex) {
    if (dayIndex < 0 || dayIndex + 1 >= state.length) return 'no-next';
    // R12 : un jour deja fait ne se regroupe pas (le prefixe fige est un bloc,
    // donc verrouiller le jour courant suffit : son suivant est libre des que
    // lui l'est).
    if (isDayLocked(dayIndex)) return 'locked';
    final a = state[dayIndex];
    final b = state[dayIndex + 1];
    if (a.isRestDay || b.isRestDay) return 'rest';
    final hours = _hoursFor([...a.stages, ...b.stages]);
    if (hours > maxManualHoursPerDay) return 'too-long';
    return null;
  }

  /// Vrai si le jour [dayIndex] peut etre regroupe avec le suivant.
  bool canMergeWithNext(int dayIndex) => mergeBlockedReason(dayIndex) == null;

  /// Regroupe le jour [dayIndex] avec le suivant (parite GR20).
  void mergeWithNext(int dayIndex) {
    if (!canMergeWithNext(dayIndex)) return;
    final days = List<PlannedDay>.of(state);
    final a = days[dayIndex];
    final b = days[dayIndex + 1];
    days[dayIndex] = a.copyWith(stages: [...a.stages, ...b.stages]);
    days.removeAt(dayIndex + 1);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  /// Vrai si le jour [dayIndex] peut etre separe.
  bool canSplit(int dayIndex) => splitBlockedReason(dayIndex) == null;

  /// L'etape [stage] est-elle une etape ENTIERE du sentier (tache 558) ?
  ///
  /// Faux pour une PORTION produite par [PlanningCalculator.splitStage] : une
  /// etape se coupe UNE fois ([PlanningCalculator.maxDaysPerStage]), pas
  /// indefiniment. La reponse se lit sur la donnee du sentier — les etapes
  /// sources que porte ce notifier — et non sur un marqueur qu'il faudrait
  /// maintenir a jour dans le modele.
  bool _isWholeStage(StageModel stage) => _stages.any(
        (source) =>
            source.stageNumber == stage.stageNumber &&
            source.name == stage.name,
      );

  /// Message explicatif si la separation est impossible (`null` si possible).
  ///
  /// Codes semantiques (libelles i18n a l'appelant, comme
  /// [mergeBlockedReason]) : `locked` (jour deja fait, R12), `single` (jour de
  /// repos ou jour vide -> rien a separer), `portion` (l'etape est deja coupee
  /// en deux, on ne la recoupe pas).
  ///
  /// TACHE 558 — UN JOUR A UNE SEULE ETAPE SE SEPARE DESORMAIS. Avant, ce cas
  /// rendait `single` : « Separer » etait mort sur la journee la plus dure du
  /// sentier — celle qui ne porte qu'une etape — c'est-a-dire precisement celle
  /// que l'application conseillait de couper (`advice.split` : « Decoupe la
  /// journee N en deux »). La campagne personas l'a mesure sur l'emulateur :
  /// depart a 9 jours, verdict « Decoupage trop serre », curseur pousse a fond,
  /// et le compteur ne bougeait pas d'un jour. Un conseil que l'application
  /// n'offre pas est pire que pas de conseil : le bouton fait maintenant ce que
  /// le conseil dit, en coupant l'etape en deux portions de meme energie.
  String? splitBlockedReason(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= state.length) return 'single';
    if (isDayLocked(dayIndex)) return 'locked';
    final day = state[dayIndex];
    if (day.isRestDay || day.stages.isEmpty) return 'single';
    if (day.stages.length > 1) return null;
    // Une seule etape : coupable si elle est ENTIERE, deja coupee sinon.
    return _isWholeStage(day.stages.single) ? null : 'portion';
  }

  /// Separe un jour : en N jours d'une etape s'il en regroupe plusieurs, en DEUX
  /// portions de meme energie s'il n'en porte qu'une (tache 558).
  ///
  /// R12 : refuse sur un jour deja fait (via [canSplit]).
  void splitDay(int dayIndex) {
    if (!canSplit(dayIndex)) return;
    final days = List<PlannedDay>.of(state);
    final toSplit = days[dayIndex];
    final List<PlannedDay> newDays;
    if (toSplit.stages.length > 1) {
      // Jour regroupe : on rend a chaque etape sa journee (parite GR20).
      newDays = toSplit.stages
          .map((s) => PlannedDay(dayNumber: 0, stages: [s]))
          .toList(growable: false);
    } else {
      // Jour a une seule etape ENTIERE : on la coupe en deux demi-journees.
      newDays = PlanningCalculator.splitStage(toSplit.stages.single)
          .map((s) => PlannedDay(dayNumber: 0, stages: [s]))
          .toList(growable: false);
    }
    days.removeAt(dayIndex);
    days.insertAll(dayIndex, newDays);
    _hasManualEdits = true;
    state = _renumber(days);
    _updateRestDayCache();
  }

  // --- Replanification (parite GR20) ---

  /// Replanifie en preservant les jours de repos manuels a leurs positions.
  ///
  /// R12 : en rando, la replanification ne porte QUE sur la partie a venir. Le
  /// prefixe fige (jours deja faits) est recopie tel quel et ses etapes sont
  /// retirees de la redistribution — sans cette garde, « Replanifier » aurait
  /// ete la porte derobee qui reecrit un passe deja marche.
  void regeneratePreservingRestDays() {
    final locked = lockedDayCount;
    final head = state.take(locked).toList(growable: false);

    // Etapes deja engagees dans le prefixe fige : elles ne repassent pas dans
    // le calcul (sinon elles seraient replanifiees dans le futur).
    final consumed = <int>{
      for (final day in head)
        for (final stage in day.stages) stage.stageNumber,
    };
    final remainingStages = _stages
        .where((s) => !consumed.contains(s.stageNumber))
        .toList(growable: false);

    // Jours de repos manuels a reinjecter : seulement ceux de la partie libre,
    // exprimes en index RELATIF a cette partie.
    final restIndices = <int>[];
    for (var i = locked; i < state.length; i++) {
      if (state[i].isRestDay) restIndices.add(i - locked);
    }

    final remainingDays = (_duration - locked) < 1 ? 1 : _duration - locked;
    var tail = _generate(remainingStages, remainingDays, _maxRestDays);
    var offset = 0;
    for (final restIndex in restIndices) {
      final insertAt = (restIndex + offset).clamp(0, tail.length);
      tail = List<PlannedDay>.of(tail)
        ..insert(insertAt,
            const PlannedDay(dayNumber: 0, stages: [], isRestDay: true));
      offset++;
    }

    _hasManualEdits = restIndices.isNotEmpty || locked > 0;
    state = _renumber([...head, ...tail]);
    _updateRestDayCache();
  }

  // --- Restauration / cache ---

  /// Reinjecte les jours de repos depuis le cache externe (appelee a la
  /// (re)creation du notifier). Parite GR20.
  ///
  /// IDEMPOTENTE (correctif tache 558). Elle INSERAIT les repos du cache
  /// PAR-DESSUS ceux que la repartition venait de poser : apres une seule
  /// edition manuelle, chaque mouvement du curseur AJOUTAIT une couche de
  /// repos, et le programme gonflait sans que personne ne l'ait demande — de
  /// quoi arriver a vingt jours en croyant en avoir choisi dix, exactement ce
  /// que Chris a vu. Le cache decrit desormais la DISPOSITION VOULUE des
  /// repos : on retire ceux de la repartition avant de reposer ceux du cache,
  /// donc rappeler cette methode deux fois donne le meme programme qu'une.
  void restoreRestDaysFromCache(List<int> cachedIndices) {
    var days = state.where((d) => !d.isRestDay).toList();
    var offset = 0;
    for (final restIndex in cachedIndices) {
      final insertAt = (restIndex + offset).clamp(0, days.length);
      days.insert(
          insertAt, const PlannedDay(dayNumber: 0, stages: [], isRestDay: true));
      offset++;
    }
    _hasManualEdits = cachedIndices.isNotEmpty;
    state = _renumber(days);
  }

  void _updateRestDayCache() {
    final indices = <int>[];
    for (var i = 0; i < state.length; i++) {
      if (state[i].isRestDay) indices.add(i);
    }
    _ref.read(manualRestDayCacheProvider.notifier).state = indices;
  }

  /// Renumerote les jours (1-indexed) apres toute mutation.
  static List<PlannedDay> _renumber(List<PlannedDay> days) =>
      List.generate(days.length, (i) => days[i].copyWith(dayNumber: i + 1));
}

/// Statistiques agregees du PROGRAMME courant (parite GR20 `planningStatsProvider`).
///
/// Refletent les editions manuelles (recalcul depuis l'etat des jours).
///
/// SENS DE MARCHE (R5, LOT L10) : les totaux D+/D- honorent desormais
/// [selectedDirectionProvider], comme le font deja les lignes JOUR PAR JOUR de
/// l'ecran Resume (`directionalDayStats`). Avant ce correctif, le meme ecran
/// affichait un D+ global issu des valeurs BRUTES du seed pendant que ses lignes
/// jour par jour permutaient montee et descente : incoherence interne, et
/// rupture de parite GR20 (`itinerary_provider` y construit les etapes
/// orientees AVANT de sommer, donc applique le sens au global ET au jour).
/// En sens INVERSE, la montee et la descente s'echangent (le D+ devient le D-
/// officiel) ; distance, duree et nombre d'etapes sont invariants au sens.
final planningStatsProvider =
    Provider.family<PlanningStats, String>((ref, trailId) {
  final days = ref.watch(plannedDaysProvider(trailId));

  // Sens de reference = 1er sens declare par le sentier (jamais devine). Sans
  // sens declare ou sans choix utilisateur, on reste dans le sens de reference.
  final directions = ref.watch(trailConfigProvider.select((c) => c.directions));
  final forward = directions.isNotEmpty ? directions.first : null;
  final selected = ref.watch(selectedDirectionProvider);
  final isForward = forward == null || selected == null || selected == forward;

  var totalDistance = 0.0;
  var totalGain = 0;
  var totalLoss = 0;
  var totalHours = 0.0;
  // ETAPES DISTINCTES, et non morceaux de journee (tache 558). Depuis que le
  // programme peut COUPER une etape en deux demi-journees, compter les entrees
  // annoncerait « 8 etapes » sur un sentier qui en compte 7 : le sentier n'a
  // pas change, c'est le decoupage qui a change.
  final stageNumbers = <int>{};
  for (final day in days) {
    if (day.isRestDay) continue;
    totalDistance += day.totalDistanceKm;
    totalGain += isForward ? day.totalElevationGainM : day.totalElevationLossM;
    totalLoss += isForward ? day.totalElevationLossM : day.totalElevationGainM;
    totalHours += day.estimatedHours;
    stageNumbers.addAll(day.stages.map((s) => s.stageNumber));
  }
  final stageCount = stageNumbers.length;
  final restDays = days.where((d) => d.isRestDay).length;
  final trekDays = days.where((d) => !d.isRestDay).length;

  return PlanningStats(
    totalDistance: totalDistance,
    totalElevationGain: totalGain,
    totalElevationLoss: totalLoss,
    totalHours: totalHours,
    trekDays: trekDays,
    restDays: restDays,
    stageCount: stageCount,
  );
});

/// Statistiques du programme (parite GR20 `PlanningStats`).
class PlanningStats {
  const PlanningStats({
    required this.totalDistance,
    required this.totalElevationGain,
    required this.totalElevationLoss,
    required this.totalHours,
    required this.trekDays,
    required this.restDays,
    required this.stageCount,
  });

  final double totalDistance;
  final int totalElevationGain;
  final int totalElevationLoss;
  final double totalHours;
  final int trekDays;
  final int restDays;
  /// Nombre d'etapes DISTINCTES portees par le programme (tache 558) — une
  /// etape coupee en deux demi-journees compte pour UNE.
  final int stageCount;

  int get totalDays => trekDays + restDays;

  /// Reste-t-il une journee a COUPER (tache 558) ?
  ///
  /// Faux quand chaque etape occupe deja le maximum de journees permis : a ce
  /// point, pousser le curseur n'allegera plus la pire journee, donc plus le
  /// verdict — et l'ecran doit le DIRE au lieu de laisser pousser un curseur
  /// qui ne sert plus a rien.
  bool get canSplitFurther =>
      stageCount > 0 &&
      trekDays < PlanningCalculator.maxWalkingDaysFor(stageCount);
}
