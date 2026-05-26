import '../../../core/geo/geo_utils.dart';
import '../../../core/geo/track_point.dart';

/// Moteur de calcul pour le tracking de randonnee.
///
/// Classe pure Dart (pas de dependance Flutter).
/// Accumule les points GPS, calcule distance cumulee,
/// denivele D+/D-, duree et vitesse moyenne.
class TrackingEngine {
  final List<TrackPoint> _points = [];
  double _distanceMeters = 0.0;
  double _elevationGainM = 0.0;
  double _elevationLossM = 0.0;
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  bool _isPaused = false;

  /// Distance totale parcourue en metres
  double get distanceMeters => _distanceMeters;

  /// Denivele positif cumule en metres
  double get elevationGainM => _elevationGainM;

  /// Denivele negatif cumule en metres
  double get elevationLossM => _elevationLossM;

  /// Duree totale en secondes (hors pauses)
  int get durationSeconds {
    if (_startTime == null) return 0;
    final now = _isPaused ? _pauseTime! : DateTime.now();
    final elapsed = now.difference(_startTime!) - _pausedDuration;
    return elapsed.inSeconds.clamp(0, 999999);
  }

  /// Vitesse moyenne en km/h (0 si pas assez de donnees)
  double get averageSpeedKmh {
    if (durationSeconds < 1) return 0.0;
    return (distanceMeters / 1000) / (durationSeconds / 3600);
  }

  /// Tracking en pause ou non
  bool get isPaused => _isPaused;

  /// Nombre de points enregistres
  int get pointCount => _points.length;

  /// Liste des points (copie non modifiable)
  List<TrackPoint> get points => List.unmodifiable(_points);

  /// Ajoute une position GPS et met a jour les calculs.
  ///
  /// Ignore les positions recues pendant une pause.
  /// Le [timestamp] est optionnel (pour les tests).
  void addPosition(
    double lat,
    double lng,
    double altitude, {
    DateTime? timestamp,
  }) {
    if (_isPaused) return;

    final now = timestamp ?? DateTime.now();
    _startTime ??= now;

    if (_points.isNotEmpty) {
      final last = _points.last;

      final segmentDist = GeoUtils.haversineDistance(
        last.lat,
        last.lng,
        lat,
        lng,
      );
      _distanceMeters += segmentDist;

      final altDiff = altitude - last.altitude;
      if (altDiff > 0) {
        _elevationGainM += altDiff;
      } else {
        _elevationLossM += altDiff.abs();
      }
    }

    _points.add(TrackPoint(
      lat: lat,
      lng: lng,
      altitude: altitude,
      distanceFromStart: _distanceMeters,
    ));
  }

  /// Met le tracking en pause.
  void pause() {
    if (_isPaused || _startTime == null) return;
    _isPaused = true;
    _pauseTime = DateTime.now();
  }

  /// Reprend le tracking apres une pause.
  void resume() {
    if (!_isPaused || _pauseTime == null) return;
    _pausedDuration += DateTime.now().difference(_pauseTime!);
    _isPaused = false;
    _pauseTime = null;
  }

  /// Remet le moteur a zero pour un nouveau tracking.
  void reset() {
    _points.clear();
    _distanceMeters = 0.0;
    _elevationGainM = 0.0;
    _elevationLossM = 0.0;
    _startTime = null;
    _pauseTime = null;
    _pausedDuration = Duration.zero;
    _isPaused = false;
  }
}
