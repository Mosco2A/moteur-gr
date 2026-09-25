import '../../../core/models/stage.dart';
import '../../../core/models/stage_duration.dart';
import '../../feasibility/domain/feasibility_formula.dart';
import '../models/day_plan.dart';

/// Calculateur de planning : répartit N étapes sur D jours.
///
/// Algorithme greedy qui équilibre la charge entre les jours
/// en se basant sur un score de difficulté par étape
/// (distance + dénivelé positif / 100).
///
/// TACHE 558 — LE CURSEUR DOIT POUVOIR ALLEGER LE VERDICT.
///
/// CE QUI N'ALLAIT PAS, mot pour mot (Chris, 25/09) : « si je passe a 20 jours
/// en mettant des jours de repos ca reste rouge ». Ce n'etait pas un bug de
/// calcul, c'etait une impasse mathematique. Depuis GO-61, le verdict du
/// circuit vaut C1 = LA PIRE JOURNEE ET ELLE SEULE. Or au-dela de N jours pour
/// N etapes, [distribute] ne savait qu'AJOUTER DU REPOS : les memes etapes
/// restaient seules sur leur journee, donc la pire journee ne bougeait pas d'un
/// gramme, donc le rouge ne pouvait pas partir. Pousser le curseur ne servait a
/// rien, et rien ne le disait.
///
/// CE QUI CHANGE : au-dela du repos CONSEILLE, un jour de plus ne devient plus
/// un jour de repos mais un DECOUPAGE — la journee la plus lourde est coupee en
/// deux demi-journees, en commencant par la PIRE, puisque c'est elle et elle
/// seule qui fixe le verdict. Le randonneur pousse le curseur, la pire journee
/// s'allege, la couleur bouge : la boucle est enfin fermee.
///
/// LA COUPE SE FAIT A MI-ENERGIE, PAS A MI-DISTANCE. L'unite du moteur est
/// l'energie (1 km de plat = 42 m de D+, [FeasibilityScale.v2]) : couper a
/// mi-distance laisserait une moitie deux fois plus dure que l'autre des que le
/// denivele est mal reparti, et la pire journee — celle qui fixe le verdict —
/// ne baisserait pas de moitie. Les deux portions portent donc chacune la
/// moitie de la distance ET la moitie du D+, ce qui vaut, par linearite de
/// l'energie, exactement la moitie de l'energie de l'etape.
///
/// CE QUE CE MODELE NE PRETEND PAS : dire OU s'arreter. Les chiffres d'une
/// portion sont une estimation d'effort ; le point de passage est une
/// interpolation sur le segment depart -> arrivee, PAS un lieu releve ni un
/// hebergement verifie. Couper une etape suppose qu'on puisse s'arreter a
/// mi-parcours — l'ecran le DIT, il ne le laisse pas deviner (cf.
/// `t.programme.duration.splitNote`). Poser la coupe sur un hebergement reel du
/// trace demanderait une donnee que le socle sentier ne porte pas encore.
class PlanningCalculator {
  const PlanningCalculator._();

  /// Nombre MAXIMAL de journees qu'une etape peut occuper (tache 558).
  ///
  /// Deux : une etape se coupe en deux demi-journees, jamais davantage. Au-dela
  /// on ne decrirait plus une journee de marche mais des fragments d'itineraire
  /// sans point d'arret plausible — et la moitie d'une etape est deja la plus
  /// petite unite que la donnee du sentier permette d'estimer honnetement.
  static const int maxDaysPerStage = 2;

  /// Marque d'une demi-journee dans le nom affiche (tache 558).
  ///
  /// Volontairement un SIGNE et non un mot — meme regle que le tiret d'attente
  /// de la carte : il ne demande aucune traduction et se lit dans les cinq
  /// langues. `Sermano -> Corte (1/2)` puis `(2/2)`.
  static String splitSuffix(int part, int count) => ' ($part/$count)';

  /// Nombre maximal de JOURS DE MARCHE atteignable pour [stageCount] etapes.
  static int maxWalkingDaysFor(int stageCount) =>
      stageCount <= 0 ? 0 : stageCount * maxDaysPerStage;

  /// Calcule le score de difficulté d'une étape (répartition greedy).
  ///
  /// Formule historique : distanceKm + elevationGainM / 100. Elle sert au
  /// REGROUPEMENT d'étapes, dont elle équilibre les paquets ; elle n'est PAS
  /// l'unité du verdict. Pour choisir quelle journée couper, c'est
  /// [stageEnergyKm] qui fait foi.
  static double stageScore(StageModel stage) {
    return stage.distanceKm + stage.elevationGainM / 100.0;
  }

  /// ENERGIE d'une etape, dans l'unite du VERDICT ([FeasibilityScale.v2] :
  /// 1 km de plat = 42 m de D+).
  ///
  /// C'est cette grandeur, et aucune autre, qui ordonne les journees quand il
  /// faut decider laquelle couper : le verdict du circuit vaut la PIRE journee
  /// et elle seule (GO-61), donc couper une journee choisie sur une autre
  /// echelle reviendrait a couper la mauvaise et a ne rien changer au verdict.
  static double stageEnergyKm(StageModel stage) =>
      FeasibilityScale.v2.energyOf(
        distanceKm: stage.distanceKm,
        elevationGainM: stage.elevationGainM,
      );

  /// Coupe une etape en [maxDaysPerStage] portions de MEME ENERGIE.
  ///
  /// Chaque portion porte sa fraction de distance, de D+, de D− et de duree —
  /// donc, par linearite de l'energie, exactement sa fraction d'energie. Les
  /// entiers sont repartis sans perte : la derniere portion prend le reste, de
  /// sorte que la somme des portions redonne EXACTEMENT l'etape d'origine
  /// (aucun metre de denivele ne disparait dans un arrondi).
  ///
  /// Le numero d'etape est CONSERVE sur les deux portions : ce sont deux
  /// moments de la meme etape, et tout ce qui identifie une etape ailleurs dans
  /// l'application (journal, carte, verrou « deja marchee ») continue de la
  /// retrouver. Le point de passage est interpole sur le segment depart ->
  /// arrivee : c'est un repere, pas un lieu releve.
  static List<StageModel> splitStage(StageModel stage, {int parts = 2}) {
    if (parts < 2) return [stage];
    final result = <StageModel>[];
    var distanceLeft = stage.distanceKm;
    var gainLeft = stage.elevationGainM;
    var lossLeft = stage.elevationLossM;
    final providedMinutes = stage.estimatedDurationMinutes;
    var minutesLeft = providedMinutes;
    var fromLat = stage.startLat;
    var fromLng = stage.startLng;

    for (var i = 0; i < parts; i++) {
      final remaining = parts - i;
      final last = remaining == 1;
      final distance = last ? distanceLeft : stage.distanceKm / parts;
      final gain = last ? gainLeft : (stage.elevationGainM / parts).floor();
      final loss = last ? lossLeft : (stage.elevationLossM / parts).floor();
      final int? minutes = providedMinutes == null
          ? null
          : (last ? minutesLeft : (providedMinutes / parts).floor());

      // Fin de la part : le milieu interpole du segment, sauf la derniere qui
      // s'acheve sur l'arrivee REELLE de l'etape.
      final ratio = (i + 1) / parts;
      final toLat = last
          ? stage.endLat
          : stage.startLat + (stage.endLat - stage.startLat) * ratio;
      final toLng = last
          ? stage.endLng
          : stage.startLng + (stage.endLng - stage.startLng) * ratio;

      result.add(stage.copyWith(
        name: '${stage.name}${splitSuffix(i + 1, parts)}',
        distanceKm: distance,
        elevationGainM: gain,
        elevationLossM: loss,
        estimatedDurationMinutes: minutes,
        startLat: fromLat,
        startLng: fromLng,
        endLat: toLat,
        endLng: toLng,
        // Les noms de depart / arrivee du sentier ne valent QUE pour l'etape
        // entiere : un point de coupe n'a pas de nom, et en inventer un serait
        // affirmer un lieu qui n'existe pas.
        departureName: i == 0 ? stage.departureName : null,
        arrivalName: last ? stage.arrivalName : null,
      ));

      distanceLeft -= distance;
      gainLeft -= gain;
      lossLeft -= loss;
      if (minutesLeft != null && minutes != null) minutesLeft -= minutes;
      fromLat = toLat;
      fromLng = toLng;
    }
    return result;
  }

  /// Calcule la durée estimée en heures pour une étape.
  ///
  /// Source unique [stageDurationMinutes] : privilégie la durée RICHE du sentier
  /// ([StageModel.estimatedDurationMinutes]) quand elle est fournie, sinon
  /// applique la règle de marche Naismith (distance / 4 km/h + D+ / 400 m/h).
  static double estimatedHours(StageModel stage) =>
      stageDurationMinutes(stage) / 60.0;

  /// Répartit les [stages] sur [days] jours de manière équilibrée.
  ///
  /// - Si jours < étapes : distribution greedy qui minimise l'écart
  ///   de score entre les jours.
  /// - Si jours >= étapes : une étape par jour, les jours restants
  ///   deviennent des jours de repos.
  /// - Les étapes conservent leur ordre séquentiel (pas de mélange).
  ///
  /// [maxRestDays] — TACHE 558, LE JOUR EN TROP DEVIENT UN DECOUPAGE.
  ///
  /// `null` (defaut) : comportement d'origine, TOUT jour au-dela du nombre
  /// d'etapes devient un jour de repos. C'est ce que lisent les appelants qui
  /// ne raisonnent qu'en repartition brute, et les tests qui la verrouillent.
  ///
  /// Une valeur : le surplus de jours alimente d'ABORD le repos, dans la limite
  /// de [maxRestDays] — c'est le repos CONSEILLE par le moteur (GO-61), et le
  /// programme par defaut est donc INCHANGE — puis, au-dela, il COUPE les
  /// journees les plus lourdes en deux, en commencant par la pire. Le nombre de
  /// jours de marche est plafonne a [maxWalkingDaysFor] ; ce qui depasse
  /// redevient du repos, faute de quoi le curseur aurait une plage morte.
  static List<DayPlan> distribute(
    List<StageModel> stages,
    int days, {
    int? maxRestDays,
  }) {
    if (stages.isEmpty || days <= 0) return [];

    if (days < stages.length) {
      return _distributeGreedy(stages, days);
    }

    // Combien de jours de MARCHE, combien de jours de REPOS.
    final surplus = days - stages.length;
    int restDays;
    List<List<StageModel>> walkingDays;
    if (maxRestDays == null) {
      // Comportement d'origine : tout le surplus part en repos.
      restDays = surplus;
      walkingDays = [
        for (final stage in stages) [stage],
      ];
    } else {
      final cappedRest = surplus < maxRestDays ? surplus : maxRestDays;
      final maxWalking = maxWalkingDaysFor(stages.length);
      var targetWalking = days - (cappedRest < 0 ? 0 : cappedRest);
      if (targetWalking > maxWalking) targetWalking = maxWalking;
      restDays = days - targetWalking;
      walkingDays = _splitHeaviestFirst(stages, targetWalking);
    }

    return _assemble(walkingDays, restDays);
  }

  /// Construit les journees de MARCHE en coupant les plus lourdes d'abord.
  ///
  /// Depart : une etape par journee. Tant qu'il manque des journees, on coupe
  /// la journee de plus grosse [stageEnergyKm] parmi celles qui portent encore
  /// une etape ENTIERE — la PIRE d'abord, puisque c'est elle qui fixe le
  /// verdict (GO-61). Une etape deja coupee ne se recoupe pas
  /// ([maxDaysPerStage]).
  static List<List<StageModel>> _splitHeaviestFirst(
    List<StageModel> stages,
    int targetWalkingDays,
  ) {
    final days = <List<StageModel>>[
      for (final stage in stages) [stage],
    ];
    // Journees encore coupables : celles qui portent une etape entiere.
    final splittable = <int>{for (var i = 0; i < days.length; i++) i};

    while (days.length < targetWalkingDays && splittable.isNotEmpty) {
      int? worst;
      double worstScore = double.negativeInfinity;
      for (final i in splittable) {
        final score = stageEnergyKm(days[i].single);
        if (score > worstScore) {
          worstScore = score;
          worst = i;
        }
      }
      if (worst == null) break;

      final parts = splitStage(days[worst].single);
      days.removeAt(worst);
      days.insertAll(worst, [
        for (final part in parts) [part],
      ]);

      // Les index ont glisse de (parts-1) a partir du point de coupe, et les
      // parts nouvellement creees ne sont plus coupables.
      final shift = parts.length - 1;
      final updated = <int>{};
      for (final i in splittable) {
        if (i == worst) continue;
        updated.add(i > worst ? i + shift : i);
      }
      splittable
        ..clear()
        ..addAll(updated);
    }
    return days;
  }

  /// Assemble les journees de marche et [restDays] jours de repos repartis.
  static List<DayPlan> _assemble(
    List<List<StageModel>> walkingDays,
    int restDays,
  ) {
    final result = <DayPlan>[];
    final safeRest = restDays < 0 ? 0 : restDays;
    final restPositions = _computeRestPositions(walkingDays.length, safeRest);

    DayPlan restDay(int dayNumber) => DayPlan(
          dayNumber: dayNumber,
          stages: const [],
          totalDistanceKm: 0,
          totalElevationGainM: 0,
          estimatedDurationHours: 0,
          isRestDay: true,
        );

    var dayNumber = 1;
    for (var i = 0; i < walkingDays.length; i++) {
      for (var r = 0; r < restPositions[i]; r++) {
        result.add(restDay(dayNumber));
        dayNumber++;
      }

      final group = walkingDays[i];
      result.add(DayPlan(
        dayNumber: dayNumber,
        stages: group,
        totalDistanceKm:
            group.fold<double>(0, (sum, s) => sum + s.distanceKm),
        totalElevationGainM:
            group.fold<int>(0, (sum, s) => sum + s.elevationGainM),
        estimatedDurationHours:
            group.fold<double>(0, (sum, s) => sum + estimatedHours(s)),
        isRestDay: false,
      ));
      dayNumber++;
    }

    final total = walkingDays.length + safeRest;
    while (result.length < total) {
      result.add(restDay(dayNumber));
      dayNumber++;
    }

    return result;
  }

  /// Calcule combien de jours de repos placer avant chaque étape.
  static List<int> _computeRestPositions(
    int stageCount,
    int restDays,
  ) {
    final positions = List.filled(stageCount, 0);
    if (restDays <= 0) return positions;

    final interval = stageCount / (restDays + 1);
    for (var r = 0; r < restDays; r++) {
      final pos =
          ((r + 1) * interval).round().clamp(0, stageCount - 1);
      positions[pos]++;
    }

    return positions;
  }

  /// Distribution greedy quand il y a plus d'étapes que de jours.
  ///
  /// Approche DP simplifiée : calcule les points de coupure optimaux
  /// pour répartir les étapes séquentiellement en [days] groupes,
  /// minimisant l'écart de score maximum entre groupes.
  static List<DayPlan> _distributeGreedy(
    List<StageModel> stages,
    int days,
  ) {
    final n = stages.length;
    final scores =
        stages.map((s) => stageScore(s)).toList();

    // Calculer les sommes de préfixes pour accès O(1)
    final prefix = List.filled(n + 1, 0.0);
    for (var i = 0; i < n; i++) {
      prefix[i + 1] = prefix[i] + scores[i];
    }
    final totalScore = prefix[n];
    final targetPerDay = totalScore / days;

    // Trouver les points de coupure greedy en visant la cible
    final cutPoints = <int>[]; // indices de début de chaque groupe
    cutPoints.add(0);

    var accumulated = 0.0;
    for (var i = 0; i < n && cutPoints.length < days; i++) {
      accumulated += scores[i];
      final remainingCuts = days - cutPoints.length;
      final remainingStages = n - i - 1;

      // Si le score accumulé dépasse la cible et qu'il reste
      // assez d'étapes pour les jours restants
      if (accumulated >= targetPerDay &&
          remainingStages >= remainingCuts) {
        cutPoints.add(i + 1);
        accumulated = 0;
      }
    }

    // Construire les groupes à partir des points de coupure
    final groups = <List<StageModel>>[];
    for (var g = 0; g < cutPoints.length; g++) {
      final start = cutPoints[g];
      final end =
          g + 1 < cutPoints.length ? cutPoints[g + 1] : n;
      groups.add(stages.sublist(start, end));
    }

    // Construire les DayPlan
    return groups.asMap().entries.map((entry) {
      final stageList = entry.value;
      final totalDist = stageList.fold<double>(
        0,
        (sum, s) => sum + s.distanceKm,
      );
      final totalGain = stageList.fold<int>(
        0,
        (sum, s) => sum + s.elevationGainM,
      );
      final totalHours = stageList.fold<double>(
        0,
        (sum, s) => sum + estimatedHours(s),
      );

      return DayPlan(
        dayNumber: entry.key + 1,
        stages: stageList,
        totalDistanceKm: totalDist,
        totalElevationGainM: totalGain,
        estimatedDurationHours: totalHours,
        isRestDay: false,
      );
    }).toList();
  }
}
