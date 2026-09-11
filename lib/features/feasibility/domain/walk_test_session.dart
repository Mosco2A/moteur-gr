import '../../../core/geo/geo_utils.dart';

/// Duree officielle du test de marche 6 minutes.
const Duration kWalkTestDuration = Duration(minutes: 6);

/// Compte a rebours avant le depart (le temps de se positionner).
const Duration kWalkTestCountdown = Duration(seconds: 3);

/// Accumulateur PUR de distance du test 6 minutes (zero dependance Flutter /
/// GPS / Timer) — directement testable (StepWays LOT 4, Ph2).
///
/// On additionne la distance haversine entre positions successives (memes
/// coordonnees que `TrackPoint`). Les positions au-dela de 6:00 sont IGNOREES
/// (le test s'arrete a la duree officielle, arret auto). Un filtre anti-bruit
/// leger ecarte les micro-sauts GPS (< 1 m) et les sauts aberrants.
class WalkTestSession {
  WalkTestSession();

  double _distanceMeters = 0;
  double? _lastLat;
  double? _lastLng;

  /// Saut minimal pris en compte (m) — filtre le jitter GPS a l'arret.
  static const double _minStepMeters = 1.0;

  /// Saut maximal plausible entre deux points (m) — ecarte les aberrations
  /// (teleportation GPS). A ~6 km/h, 2 s => ~3.3 m ; on tolere large (50 m).
  static const double _maxStepMeters = 50.0;

  /// Distance cumulee retenue, en metres.
  double get distanceMeters => _distanceMeters;

  /// Integre une position horodatee par rapport au debut du test.
  ///
  /// [elapsed] = temps ecoule depuis le demarrage. Si [elapsed] depasse la
  /// duree officielle, la position est ignoree (arret auto a 6:00).
  /// Retourne true si le point a ete comptabilise.
  bool addPosition({
    required double lat,
    required double lng,
    required Duration elapsed,
  }) {
    if (elapsed > kWalkTestDuration) return false;
    final prevLat = _lastLat;
    final prevLng = _lastLng;
    _lastLat = lat;
    _lastLng = lng;
    if (prevLat == null || prevLng == null) return false; // 1er point = origine
    final step = GeoUtils.haversineDistance(prevLat, prevLng, lat, lng);
    if (step < _minStepMeters || step > _maxStepMeters) return false;
    _distanceMeters += step;
    return true;
  }

  /// Remet l'accumulateur a zero (nouveau test).
  void reset() {
    _distanceMeters = 0;
    _lastLat = null;
    _lastLng = null;
  }
}
