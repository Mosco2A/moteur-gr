/// Logique de FIN DE TREK — generalisee, direction-aware, zero hardcode.
///
/// **Entierement parametree par le sentier / le parcours choisi** : aucune
/// dependance a un sentier particulier, aucune region en dur, ni constante de
/// nombre d'etapes en dur. Tout depend de la sequence d'etapes du parcours dans
/// le **sens de marche** et de la direction choisie.
///
/// Le moteur ne connait AUCUN code de direction en propre : les codes sont
/// fournis par le sentier (`TrailConfig.directions`, p. ex. `['NS','SN']` ou
/// `['EW','WE']`). Le sens n'a de signification que **relative** a l'ordre des
/// etapes du parcours — jamais une valeur devinee par le moteur.
///
/// Concepts exposes :
/// - etape de depart          -> [TrekPlan.startStageId]
/// - etape d'arrivee (fin)    -> [TrekPlan.finalStageId]
/// - etape suivante           -> [TrekPlan.nextStageId]
/// - test « est le depart »   -> [TrekPlan.isStartStage]
/// - test « est la fin »      -> [TrekPlan.isFinalStage]
/// - garde anti-felicitations prematurees + choix completer/avancer
///   -> [TrekPlan.resolveArrival]
/// - felicitations complet vs parcours partiel -> [TrekCongratulations].
library;

import 'models/stage.dart';

/// Plan de marche resolu d'un trek : la sequence d'etapes **dans l'ordre de
/// marche** + la direction choisie + le perimetre (parcours entier ou partiel).
///
/// Modelise le couple (direction, parcours) de facon generique. La « premiere »
/// etape (depart) et la « derniere » etape (fin reelle du trek) se deduisent
/// uniquement de l'ordre de [orderedStageIds] : premier / dernier element. Dans
/// un sens comme dans l'autre, aucune constante n'est necessaire
/// — c'est l'ordre du parcours qui porte le sens.
class TrekPlan {
  /// Construit un plan a partir de la sequence d'etapes **deja ordonnee dans le
  /// sens de marche** ([orderedStageIds], premier = depart, dernier = arrivee).
  ///
  /// [direction] est le code de sens choisi (⊂ `TrailConfig.directions`) ;
  /// il est conserve pour l'affichage/telemetrie et n'est jamais interprete
  /// par le moteur. [isFullTrail] indique si le parcours couvre le sentier
  /// entier (vs une portion : demi-parcours, section conseillee…).
  const TrekPlan({
    required this.orderedStageIds,
    required this.direction,
    required this.isFullTrail,
  });

  /// Sequence des identifiants d'etape **dans l'ordre de marche** (premier =
  /// depart du trek, dernier = arrivee finale). Peut etre un sous-ensemble du
  /// sentier (parcours partiel).
  final List<String> orderedStageIds;

  /// Code du sens de marche choisi (ex. 'NS'/'SN', 'EW'/'WE'). Opaque pour le
  /// moteur : fourni par le sentier, seul l'**ordre** porte la semantique.
  final String direction;

  /// True si le parcours couvre le sentier **entier**. False pour une portion
  /// (demi-parcours, section) — pilote les felicitations (complet vs partiel).
  final bool isFullTrail;

  /// Nombre d'etapes du parcours (jamais une constante en dur).
  int get stageCount => orderedStageIds.length;

  /// Identifiant de l'etape de DEPART du trek (la ou l'on demarre) : le premier
  /// element de la sequence de marche. Null si le parcours est vide.
  ///
  /// **Sans code de direction en dur** : c'est l'ordre du parcours qui decide
  /// (dans le sens de reference = premiere etape ; dans l'autre = la derniere).
  String? get startStageId =>
      orderedStageIds.isEmpty ? null : orderedStageIds.first;

  /// Identifiant de la DERNIERE etape (fin reelle du trek dans ce sens) : le
  /// dernier element de la sequence de marche. Null si le parcours est vide.
  String? get finalStageId =>
      orderedStageIds.isEmpty ? null : orderedStageIds.last;

  /// True si [stageId] est l'etape de DEPART du parcours.
  ///
  /// Garantit qu'aucune « fin de trek » ne se declenche au demarrage (garde
  /// anti-felicitations prematurees).
  bool isStartStage(String stageId) => stageId == startStageId;

  /// True si [stageId] est la DERNIERE etape (fin reelle du trek dans ce sens).
  bool isFinalStage(String stageId) => stageId == finalStageId;

  /// True si [stageId] appartient au parcours.
  bool contains(String stageId) => orderedStageIds.contains(stageId);

  /// GO-85 inc2 (porte du finisher, port GR20 #97501 chantier B) — le parcours
  /// a-t-il ete REELLEMENT parcouru en entier ?
  ///
  /// True si et seulement si CHAQUE etape du parcours (dans le sens de marche)
  /// figure dans [completed] (les etapes reellement completees, cf.
  /// `TrekSession.completedStages`). Direction-aware et sans nombre en dur :
  /// c'est l'ensemble des etapes du plan qui fait foi, quel que soit le sens.
  ///
  /// Critere BLOQUANT du finisher : atteindre la derniere etape ne suffit pas
  /// si les etapes intermediaires n'ont pas ete marchees (demi-tour, arrivee
  /// opportuniste). Un parcours vide renvoie false (rien a feliciter).
  bool isFullyWalked(Set<String> completed) {
    if (orderedStageIds.isEmpty) return false;
    for (final id in orderedStageIds) {
      if (!completed.contains(id)) return false;
    }
    return true;
  }

  /// Etape SUIVANTE dans le sens de marche apres [stageId], ou null si [stageId]
  /// est la derniere (ou absent du parcours).
  ///
  /// « Suivant » = element suivant dans la sequence de marche, quelle que soit
  /// la direction (pas d'increment/decrement de numero code en dur).
  String? nextStageId(String stageId) {
    final index = orderedStageIds.indexOf(stageId);
    if (index < 0 || index >= orderedStageIds.length - 1) return null;
    return orderedStageIds[index + 1];
  }

  /// Resout l'arrivee a la fin de l'etape [stageId] : que doit-il se passer ?
  ///
  /// 1. Etape hors parcours -> ignorer.
  /// 2. **Faux positif au point de DEPART (#98856, port GR20 07d7ce8)** : si le
  ///    caller signale [isFalsePositiveAtDeparture] (on est encore au refuge de
  ///    depart de l'etape de depart — decision de POSITION, prise la ou la
  ///    position est disponible : [ArrivalDetectionService]), on ignore. On NE
  ///    bloque PLUS l'etape de depart par simple IDENTITE : l'ancien garde
  ///    `if (isStartStage) ignore` ecartait aussi l'arrivee REELLE a la fin de
  ///    l'etape de depart (verrou oeuf-poule : trek bloque a la 1re etape). Une
  ///    arrivee genuine a la fin de l'etape de depart avance donc normalement.
  /// 3. Ambiguite depart == fin (parcours mono-etape) -> ignorer : arriver a
  ///    l'unique etape ne peut pas etre distingue du depart sans position, on
  ///    laisse l'arret manuel (comportement historique preserve).
  /// 4. Si [stageId] est la **vraie derniere etape** -> completer le trek.
  /// 5. Sinon -> avancer a l'etape suivante.
  ///
  /// [isFalsePositiveAtDeparture] : fourni par le caller qui dispose de la
  /// position (distToStart <= rayon de depart). Defaut false : sans info de
  /// position, une arrivee de fin d'etape est prise au mot (l'etape de depart
  /// n'est plus un cas special par identite).
  TrekArrivalOutcome resolveArrival(
    String stageId, {
    bool isFalsePositiveAtDeparture = false,
  }) {
    if (!contains(stageId)) {
      return const TrekArrivalOutcome.ignored();
    }
    // #98856 — Neutralise UNIQUEMENT un faux positif de detection au point de
    // depart, signale par le caller (position). Remplace l'ancien blocage par
    // identite qui creait le verrou oeuf-poule.
    if (isFalsePositiveAtDeparture) {
      return const TrekArrivalOutcome.ignored();
    }
    // Parcours mono-etape : depart == fin. Sans position pour trancher, on
    // conserve le comportement historique (ignore, arret manuel).
    if (isStartStage(stageId) && isFinalStage(stageId)) {
      return const TrekArrivalOutcome.ignored();
    }
    if (isFinalStage(stageId)) {
      return const TrekArrivalOutcome.complete();
    }
    final next = nextStageId(stageId);
    if (next == null) {
      // Filet : pas de suivant sans etre la derniere -> ne rien casser.
      return const TrekArrivalOutcome.ignored();
    }
    return TrekArrivalOutcome.advance(next);
  }

  /// Construit le plan de marche a partir des etapes du sentier et du parcours.
  ///
  /// [allStages] = toutes les etapes du sentier (ordre quelconque). [direction]
  /// = sens choisi. [forwardDirectionCode] = code de sens qui correspond a
  /// l'ordre **croissant** de `orderIndex` (l'ordre « officiel » du JSON, p. ex.
  /// `'NS'` ou `'EW'`) — fourni par le sentier, jamais devine. Marcher dans
  /// l'autre sens inverse simplement la sequence.
  ///
  /// [stageIds] restreint le parcours a un sous-ensemble (parcours partiel :
  /// demi-parcours, section). Null/vide = sentier entier. [isFullTrail] est
  /// deduit (parcours == toutes les etapes) sauf si force via [forceFull].
  factory TrekPlan.fromStages(
    List<Stage> allStages, {
    required String direction,
    required String forwardDirectionCode,
    List<String>? stageIds,
    bool? forceFull,
  }) {
    // Ordre officiel (croissant par orderIndex) — source unique de l'ordre.
    final ordered = [...allStages]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Restreindre au parcours si un sous-ensemble est fourni.
    final Set<String>? subset =
        (stageIds == null || stageIds.isEmpty) ? null : stageIds.toSet();
    final scoped = subset == null
        ? ordered
        : ordered.where((s) => subset.contains(s.id)).toList();

    var ids = scoped.map((s) => s.id).toList();

    // Sens de marche : si la direction choisie n'est pas le sens croissant de
    // reference, on parcourt les etapes a rebours (sans code en dur).
    if (direction != forwardDirectionCode) {
      ids = ids.reversed.toList();
    }

    final full = forceFull ?? (subset == null && ids.length == ordered.length);

    return TrekPlan(
      orderedStageIds: ids,
      direction: direction,
      isFullTrail: full,
    );
  }
}

/// Type d'action a effectuer suite a une arrivee de fin d'etape.
enum TrekArrivalAction {
  /// Ne rien faire (faux positif au depart, etape hors parcours, ou sans suite).
  ignore,

  /// Avancer a l'etape suivante ([TrekArrivalOutcome.nextStageId] non nul).
  advance,

  /// Terminer le trek (vraie derniere etape atteinte).
  complete,
}

/// Resultat de [TrekPlan.resolveArrival] : l'action + l'eventuelle etape suivante.
class TrekArrivalOutcome {
  const TrekArrivalOutcome._(this.action, this.nextStageId);

  /// Ne rien faire.
  const TrekArrivalOutcome.ignored()
      : this._(TrekArrivalAction.ignore, null);

  /// Avancer vers [next].
  const TrekArrivalOutcome.advance(String next)
      : this._(TrekArrivalAction.advance, next);

  /// Terminer le trek.
  const TrekArrivalOutcome.complete()
      : this._(TrekArrivalAction.complete, null);

  /// Action a effectuer.
  final TrekArrivalAction action;

  /// Etape suivante (uniquement si [action] == advance), sinon null.
  final String? nextStageId;

  /// Raccourci : le trek est-il termine ?
  bool get isComplete => action == TrekArrivalAction.complete;

  /// Raccourci : faut-il avancer d'etape ?
  bool get isAdvance => action == TrekArrivalAction.advance;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrekArrivalOutcome &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          nextStageId == other.nextStageId;

  @override
  int get hashCode => Object.hash(action, nextStageId);

  @override
  String toString() =>
      'TrekArrivalOutcome(action: $action, nextStageId: $nextStageId)';
}

/// Felicitations de fin de trek — adaptees parcours **entier** vs **partiel**.
///
/// Au lieu de booleens codes pour un sentier particulier, on expose un [kind]
/// (complet / partiel) derivable de n'importe quel [TrekPlan] via
/// [TrekCongratulations.forPlan]. Le libelle final (traductions, nom du
/// parcours partiel) reste a la charge de l'UI (i18n) — ici, aucune chaine en
/// dur.
class TrekCongratulations {
  const TrekCongratulations({
    required this.kind,
    this.partialLabel,
  });

  /// Complet (sentier entier) ou partiel (demi-parcours, section).
  final TrekCompletionKind kind;

  /// Libelle optionnel du parcours partiel (ex. « Nord »/« Sud »), pour l'UI.
  /// Null pour un parcours entier. Fourni par le parcours, jamais en dur.
  final String? partialLabel;

  /// True si le sentier entier est termine.
  bool get isFull => kind == TrekCompletionKind.full;

  /// True si un parcours partiel est termine (portion : demi-parcours, section).
  bool get isPartial => kind == TrekCompletionKind.partial;

  /// Deduit les felicitations depuis le plan de marche (+ libelle partiel).
  factory TrekCongratulations.forPlan(
    TrekPlan plan, {
    String? partialLabel,
  }) {
    return TrekCongratulations(
      kind: plan.isFullTrail
          ? TrekCompletionKind.full
          : TrekCompletionKind.partial,
      partialLabel: plan.isFullTrail ? null : partialLabel,
    );
  }
}

/// Nature de la completion d'un trek.
enum TrekCompletionKind {
  /// Sentier entier termine.
  full,

  /// Parcours partiel termine (demi-parcours, section conseillee…).
  partial,
}
