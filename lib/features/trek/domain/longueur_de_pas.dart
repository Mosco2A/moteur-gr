/// LA LONGUEUR DE PAS (lot 671-02) : une classe pure, sans Flutter ni greffon,
/// qui transforme des intervalles « distance sur le trace / pas comptes » en
/// une longueur de pas, et qui refuse ceux qui mentent.
///
/// ELLE NE LIT NI HORLOGE, NI CAPTEUR, NI PREFERENCE : tout lui est donne.
/// C'est ce qui la rend testable sans binding, et ce qui permettra au lot
/// 671-03 de mesurer une derive avec une longueur de pas choisie a volonte.
///
/// ELLE NE FAIT AVANCER AUCUN POINT. Elle dit combien mesure un pas ; le lot
/// 671-03 s'en servira pour estimer la position entre deux points GPS.
library;

import 'dart:math' as math;

/// LE GARDE-FOU BAS : toute longueur calculee sous 0,40 m est rejetee (borne
/// INCLUSE : 0,40 m est accepte, 0,39 m rejete).
///
/// CE QU'IL PROTEGE, AVEC [kStrideMaxMeters] : la remontee mecanique, le bus,
/// le telepherique, ou le compteur de pas et la distance parcourue sur le
/// trace racontent deux histoires differentes. Cinq kilometres pour trente
/// pas donneraient une longueur de pas de 166 metres, et une seule acceptation
/// de ce genre empoisonnerait la moyenne pour le reste de la journee. A
/// l'inverse, pietiner au refuge ajoute des pas sans distance et ferait
/// tomber la longueur sous ce qu'un randonneur fait en montee raide.
const double kStrideMinMeters = 0.40;

/// LE GARDE-FOU HAUT : toute longueur calculee au-dessus de 1,10 m est
/// rejetee (borne INCLUSE : 1,10 m est accepte, 1,11 m rejete). Voir
/// [kStrideMinMeters] pour ce que les deux bornes protegent.
const double kStrideMaxMeters = 1.10;

/// LA DISTANCE MINIMALE D'UN INTERVALLE, sur le trace : 50 m.
///
/// En dessous, le rapport distance / pas est trop bruite. L'arithmetique : a
/// 0,75 m par pas, 50 m valent environ 67 pas, donc UN pas d'erreur de
/// comptage pese 1,5 % ; a 10 m il en pese 7,5 %, c'est-a-dire la totalite
/// de l'erreur publiee de l'etat de l'art (1 a 7 %).
const double kStrideMinIntervalMeters = 50;

/// LA FENETRE GLISSANTE : la longueur retenue est la moyenne des 5 derniers
/// intervalles ACCEPTES.
///
/// Pourquoi 5 : a une acquisition GPS toutes les 3 minutes (profil batterie
/// d'abord), cinq intervalles valent un quart d'heure de marche. Assez pour
/// lisser le bruit du comptage, pas assez pour effacer un vrai changement de
/// terrain : une montee raide raccourcit le pas, et la longueur doit suivre
/// en un quart d'heure, pas en une journee.
const int kStrideWindowSize = 5;

/// LA VALEUR DE DEPART : 0,75 m.
///
/// CETTE VALEUR N'EST PAS MESUREE SUR CHRISTOPHE. Aucune marche de deux
/// heures n'a eu lieu (decision du 06/10 : rien n'est teste sur un telephone
/// reel). C'est une valeur de depart generique, celle d'un adulte qui marche
/// sur sentier, et elle est remplacee par la calibration des le premier
/// intervalle accepte de la premiere randonnee ; la calibration est gardee
/// d'une randonnee a l'autre (cle `bg_stride_window_m`).
///
/// CE QUE DIT LA LITTERATURE, pour ancrer l'ordre de grandeur : les erreurs
/// de longueur de pas publiees vont de 1 a 7 %, l'erreur de distance moyenne
/// mesuree vaut 2,6 % plus ou moins 1,3 %, et 3 % valent 30 m par kilometre,
/// exactement le seuil de derive que le lot 671-03 devra tenir.
const double kStrideDefaultMeters = 0.75;

/// Pourquoi un intervalle est rejete.
enum StrideRejection {
  /// Zero pas (ou moins) : c'est l'arret, pas une mesure. Rejete sans
  /// division.
  noSteps,

  /// Moins de [kStrideMinIntervalMeters] sur le trace : trop bruite.
  tooShort,

  /// Longueur hors de [kStrideMinMeters]..[kStrideMaxMeters] : remontee
  /// mecanique, vehicule, ou pietinement.
  outOfBounds,
}

/// Le sort d'un intervalle : accepte, ou rejete avec sa raison nommee.
final class StrideOutcome {
  const StrideOutcome._(this.rejection, this.intervalMeters);

  /// Nul si l'intervalle est accepte.
  final StrideRejection? rejection;

  /// La longueur de pas de CET intervalle ; nulle quand elle n'a pas ete
  /// calculee (zero pas ou intervalle trop court).
  final double? intervalMeters;

  /// Vrai si l'intervalle entre dans la moyenne.
  bool get accepted => rejection == null;

  /// Juge un intervalle de [distanceMeters] sur le trace pour [steps] pas.
  static StrideOutcome judge({
    required double distanceMeters,
    required int steps,
  }) {
    if (steps <= 0) return const StrideOutcome._(StrideRejection.noSteps, null);
    if (!(distanceMeters >= kStrideMinIntervalMeters)) {
      return const StrideOutcome._(StrideRejection.tooShort, null);
    }
    final meters = distanceMeters / steps;
    final inBounds = meters >= kStrideMinMeters && meters <= kStrideMaxMeters;
    return StrideOutcome._(
      inBounds ? null : StrideRejection.outOfBounds,
      meters,
    );
  }
}

/// L'etat de la calibration : les [kStrideWindowSize] dernieres longueurs
/// acceptees, la plus recente en dernier. Immuable.
final class StrideCalibration {
  /// Une calibration portant [accepted] (seules les dernieres sont gardees).
  StrideCalibration([Iterable<double> accepted = const <double>[]])
    : accepted = List<double>.unmodifiable(_lastWindow(accepted.toList()));

  /// Les longueurs acceptees retenues, la plus recente en dernier.
  final List<double> accepted;

  /// Vrai des qu'au moins un intervalle a ete accepte.
  bool get isCalibrated => accepted.isNotEmpty;

  /// LA LONGUEUR RETENUE : la moyenne de la fenetre, ou la valeur de depart.
  double get meters => isCalibrated
      ? accepted.reduce((a, b) => a + b) / accepted.length
      : kStrideDefaultMeters;

  /// LA DISPERSION, en pour cent : l'ecart entre la plus grande et la plus
  /// petite longueur de la fenetre, rapporte a leur moyenne. Nulle sous deux
  /// longueurs. Au-dela de 15 %, une seule longueur de pas ne suffit plus et
  /// la question d'un modele dependant de la cadence de marche se pose.
  double? get spreadPercent {
    if (accepted.length < 2) return null;
    final low = accepted.reduce(math.min);
    final high = accepted.reduce(math.max);
    return (high - low) / meters * 100;
  }

  /// Offre un intervalle : rend la calibration suivante et le sort de
  /// l'intervalle. Un intervalle rejete ne deplace pas la fenetre.
  ({StrideCalibration calibration, StrideOutcome outcome}) offer({
    required double distanceMeters,
    required int steps,
  }) {
    final outcome = StrideOutcome.judge(
      distanceMeters: distanceMeters,
      steps: steps,
    );
    if (!outcome.accepted) return (calibration: this, outcome: outcome);
    return (
      calibration: StrideCalibration([...accepted, outcome.intervalMeters!]),
      outcome: outcome,
    );
  }

  /// LECTURE TOLERANTE, sur le motif de `PositionProfile.fromStored` : une
  /// valeur absente, illisible ou hors du garde-fou est ignoree ; sans valeur
  /// valable, la longueur retombe sur [kStrideDefaultMeters]. Ne leve jamais.
  static StrideCalibration fromStored(List<String>? stored) {
    final valid = <double>[
      for (final raw in stored ?? const <String>[])
        if (double.tryParse(raw) case final v?)
          if (v >= kStrideMinMeters && v <= kStrideMaxMeters) v,
    ];
    return StrideCalibration(valid);
  }

  /// La forme stockee : une longueur par entree, en metres, quatre decimales.
  List<String> toStored() => [for (final v in accepted) v.toStringAsFixed(4)];

  static List<double> _lastWindow(List<double> values) =>
      values.length <= kStrideWindowSize
      ? values
      : values.sublist(values.length - kStrideWindowSize);
}

/// Decoupe la marche en intervalles et les offre a la calibration.
///
/// Il recoit, a chaque position projetee sur le trace, la distance depuis le
/// depart et le total de pas consolide du meme instant. Un intervalle trop
/// court garde son point de depart pour grandir jusqu'a
/// [kStrideMinIntervalMeters] ; tout autre sort repart du point courant.
class StrideCalibrator {
  /// Part de [calibration], relue au demarrage du trek.
  StrideCalibrator(this.calibration);

  /// La calibration courante.
  StrideCalibration calibration;

  ({double distance, int steps})? _anchor;

  /// Observe un point : rend le sort de l'intervalle ferme par ce point, ou
  /// nul s'il n'en ferme aucun (premier point, ou pas inconnus).
  StrideOutcome? observe({
    required double distanceFromStartMeters,
    required int? steps,
  }) {
    if (steps == null) {
      _anchor = null;
      return null;
    }
    final here = (distance: distanceFromStartMeters, steps: steps);
    final anchor = _anchor;
    if (anchor == null) {
      _anchor = here;
      return null;
    }
    final result = calibration.offer(
      distanceMeters: here.distance - anchor.distance,
      steps: here.steps - anchor.steps,
    );
    calibration = result.calibration;
    if (result.outcome.rejection != StrideRejection.tooShort) _anchor = here;
    return result.outcome;
  }
}
