import '../../../core/geo/geo_utils.dart';
// Simplificateur Douglas-Peucker cote trek (opere sur le `TrackPoint` trek,
// lat/lng/elevation). Alias pour lever l'homonymie avec core/geo/douglas_peucker.
import '../../trek/data/track_simplifier.dart' as trek_simplifier;
import '../../trek/domain/models/track_point.dart';

/// Resultat du calcul d'effort IBP depuis un trace GPX.
class IbpResult {
  const IbpResult({
    required this.score,
    required this.distanceKm,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.effortLevel,
  });

  /// Score d'effort brut (echelle ~0 facile -> 180+ tres difficile).
  final double score;

  /// Distance totale du trace, en km.
  final double distanceKm;

  /// Denivele positif cumule, en metres.
  final double elevationGainM;

  /// Denivele negatif cumule, en metres.
  final double elevationLossM;

  /// Niveau d'effort FFRandonnee 1-5 derive du [score] (barème externalise).
  final int effortLevel;
}

/// Calculateur d'EFFORT (indice type IBP) depuis un trace GPX — fonction PURE
/// (zero dependance Flutter), StepWays LOT 4 Ph4.
///
/// L'indice IBP (distance + denivele + pentes) est PROPRIETAIRE et son barème
/// exact n'est pas public (BP `BP_faisabilite_entrainement.md`, §C
/// « barème IBP non public a caler nous-memes »). On implemente ici une
/// APPROXIMATION transparente, slope-aware, batie sur les seules entrees
/// connues :
///   effort = somme sur chaque segment de
///            (montee_m * poidsMontee(pente)) + (descente_m * poidsDescente)
///            + (distance_plat_km * poidsPlat)
/// puis normalisee sur une echelle 0..180+ (facile -> tres difficile), cohente
/// avec l'ordre de grandeur public de l'IBP Index (0-25 facile, 180+ difficile).
///
/// Reutilise l'infra existante : `TrackSimplifier` (Douglas-Peucker sur le
/// `TrackPoint` trek) pour lisser le bruit d'altitude avant l'integration des
/// pentes, et `GeoUtils.haversineDistance` pour les distances. Le mapping
/// score -> niveau 1-5 est EXTERNALISE (barème JSON, cf. `IbpBareme`).
class IbpCalculator {
  const IbpCalculator._();

  /// Epsilon de simplification (DEGRES, ~11 m) avant integration des pentes :
  /// lisse le jitter d'altitude GPS sans effacer le relief reel. Aligne sur
  /// `DouglasPeucker.defaultEpsilon` du simplificateur trek.
  static const double simplifyEpsilonDegrees = 0.0001;

  /// Equivalence effort de reference : 100 m de D+ ~ 1 km de plat (BP §A).
  /// -> 1 m de D+ vaut `_flatPerElevation` km de plat en base.
  static const double _kmPer100mGain = 1.0;

  /// Poids de la descente (l'effort de descente est moindre que la montee mais
  /// non nul — sollicitation excentrique, BP §B). ~0.30 de la montee.
  static const double _descentWeight = 0.30;

  /// Facteur d'echelle final -> ordre de grandeur IBP (0-180+).
  static const double _scale = 10.0;

  /// Calcule l'effort IBP a partir d'un trace [TrackPoint] (trek).
  ///
  /// [bareme] : barème externalise score->niveau (defaut = [IbpBareme.standard]).
  /// Trace vide/1 point -> effort nul (niveau 1).
  static IbpResult compute(
    List<TrackPoint> trace, {
    IbpBareme bareme = IbpBareme.standard,
  }) {
    if (trace.length < 2) {
      return IbpResult(
        score: 0,
        distanceKm: 0,
        elevationGainM: 0,
        elevationLossM: 0,
        effortLevel: bareme.levelFor(0),
      );
    }

    // Lisse le bruit d'altitude avant d'integrer les pentes.
    final pts =
        trek_simplifier.DouglasPeucker.simplify(trace, simplifyEpsilonDegrees);
    final ref = pts.length >= 2 ? pts : trace;

    double distanceM = 0;
    double gain = 0;
    double loss = 0;
    double effort = 0;

    for (var i = 1; i < ref.length; i++) {
      final a = ref[i - 1];
      final b = ref[i];
      final segDist =
          GeoUtils.haversineDistance(a.lat, a.lng, b.lat, b.lng);
      final dAlt = b.elevation - a.elevation;
      distanceM += segDist;

      // Plat : effort proportionnel a la distance (km).
      effort += (segDist / 1000.0);

      if (dAlt > 0) {
        gain += dAlt;
        // Montee : effort majore par la RAIDEUR (pente = D+/distance).
        final grade = segDist > 0 ? dAlt / segDist : 0.0; // 0..1
        final steepnessBoost = 1.0 + (grade * 10).clamp(0.0, 4.0);
        effort += (dAlt / 100.0) * _kmPer100mGain * steepnessBoost;
      } else if (dAlt < 0) {
        final drop = -dAlt;
        loss += drop;
        effort += (drop / 100.0) * _kmPer100mGain * _descentWeight;
      }
    }

    final score = effort * _scale;
    return IbpResult(
      score: score,
      distanceKm: distanceM / 1000.0,
      elevationGainM: gain,
      elevationLossM: loss,
      effortLevel: bareme.levelFor(score),
    );
  }
}

/// Barème EXTERNALISE de conversion score IBP -> niveau d'effort FFRando 1-5
/// (spec §5 : « barème IBP->niveau externalise JSON »).
///
/// Les seuils sont des bornes SUPERIEURES croissantes : un score <= thresholds[i]
/// donne le niveau i+1. Au-dela du dernier seuil -> niveau 5. Chargeable depuis
/// un JASON par sentier ([IbpBareme.fromJson]) ; un defaut [standard] est fourni.
class IbpBareme {
  const IbpBareme(this.thresholds);

  /// 4 bornes superieures (score) separant les niveaux 1..5.
  /// Exemple standard : [25, 50, 90, 130] -> 1 tres facile ... 5 tres difficile.
  final List<double> thresholds;

  /// Barème par defaut (ordre de grandeur IBP public : 0-25 facile, 180+ dur).
  static const IbpBareme standard = IbpBareme([25, 50, 90, 130]);

  /// Reconstruit un barème depuis un JSON (`{"thresholds":[25,50,90,130]}`).
  factory IbpBareme.fromJson(Map<String, dynamic> json) {
    final raw = json['thresholds'];
    if (raw is List && raw.length == 4) {
      return IbpBareme(raw.map((e) => (e as num).toDouble()).toList());
    }
    return standard;
  }

  Map<String, dynamic> toJson() => {'thresholds': thresholds};

  /// Niveau d'effort 1-5 pour un [score].
  int levelFor(double score) {
    for (var i = 0; i < thresholds.length; i++) {
      if (score <= thresholds[i]) return i + 1;
    }
    return thresholds.length + 1; // 5
  }
}
