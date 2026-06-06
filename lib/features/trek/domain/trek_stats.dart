import 'dart:math';

import '../../../core/geo/geo_utils.dart';
import 'models/track_point.dart';

/// Statistiques temps reel d'un trek en cours.
///
/// Classe pure Dart (pas de dependance Flutter).
/// Accumule les TrackPoints et calcule en continu :
/// - Distance parcourue (haversine)
/// - Denivele D+ / D- (filtre bruit < 3m)
/// - Altitude min / max
/// - Vitesse moyenne et instantanee
/// - Duree ecoulee (hors pauses > 5 min)
/// - ETA basee sur distance restante + vitesse moyenne
class TrekStats {
  TrekStats({required double totalDistanceKm})
      : _totalDistanceKm = totalDistanceKm;

  /// Seuil minimum de denivele entre 2 points consecutifs (metres).
  /// En dessous, le denivele est considere comme bruit GPS.
  static const double elevationNoiseThresholdM = 3.0;

  /// Seuil de pause automatique (secondes).
  /// Si > 5 min entre 2 points, le temps n'est pas compte.
  static const int pauseThresholdSeconds = 300;

  final double _totalDistanceKm;
  final List<TrackPoint> _points = [];

  double _distanceMeters = 0.0;
  double _elevationGainM = 0.0;
  double _elevationLossM = 0.0;
  double _altitudeMinM = double.infinity;
  double _altitudeMaxM = double.negativeInfinity;

  /// Duree active cumulee (hors pauses detectees).
  Duration _activeDuration = Duration.zero;

  /// Vitesse instantanee entre les 2 derniers points (m/s).
  double _currentSpeedMs = 0.0;

  /// Nombre de pauses detectees.
  int _pauseCount = 0;

  // --- Getters publics ---

  /// Distance parcourue en kilometres.
  double get distanceKm => _distanceMeters / 1000.0;

  /// Denivele positif cumule en metres (filtre bruit).
  double get elevationGain => _elevationGainM;

  /// Denivele negatif cumule en metres (filtre bruit).
  double get elevationLoss => _elevationLossM;

  /// Altitude minimale rencontree en metres.
  double get altitudeMin =>
      _altitudeMinM == double.infinity ? 0.0 : _altitudeMinM;

  /// Altitude maximale rencontree en metres.
  double get altitudeMax =>
      _altitudeMaxM == double.negativeInfinity ? 0.0 : _altitudeMaxM;

  /// Vitesse moyenne en km/h (sur la duree active uniquement).
  double get avgSpeedKmh {
    final seconds = _activeDuration.inSeconds;
    if (seconds < 1) return 0.0;
    return (_distanceMeters / 1000.0) / (seconds / 3600.0);
  }

  /// Vitesse instantanee en km/h (entre les 2 derniers points).
  double get currentSpeedKmh => _currentSpeedMs * 3.6;

  /// Duree ecoulee active (hors pauses detectees).
  Duration get elapsedDuration => _activeDuration;

  /// ETA estimee (temps restant) basee sur distance restante + vitesse moyenne.
  ///
  /// - Retourne [Duration.zero] si la distance totale est atteinte ou depassee
  ///   (arrivee), independamment de la vitesse moyenne instantanee.
  /// - Retourne null si la distance restante ne peut pas etre estimee
  ///   (vitesse moyenne nulle, donc aucune progression temporelle exploitable).
  Duration? get eta {
    final remainingKm = _totalDistanceKm - distanceKm;
    // Distance totale atteinte ou depassee -> arrivee, ETA = 0.
    if (remainingKm <= 0) return Duration.zero;
    // Pas de vitesse moyenne exploitable -> ETA indeterminable.
    if (avgSpeedKmh <= 0) return null;
    final hoursRemaining = remainingKm / avgSpeedKmh;
    return Duration(seconds: (hoursRemaining * 3600).round());
  }

  /// Nombre de points accumules.
  int get pointCount => _points.length;

  /// Nombre de pauses detectees (gaps > 5 min).
  int get pauseCount => _pauseCount;

  /// Ajoute un point GPS et met a jour toutes les statistiques.
  ///
  /// Le [point] doit avoir un [timestamp] non null pour que
  /// la detection de pause et le calcul de vitesse fonctionnent.
  void addPoint(TrackPoint point) {
    // Mise a jour altitude min/max
    _altitudeMinM = min(_altitudeMinM, point.elevation);
    _altitudeMaxM = max(_altitudeMaxM, point.elevation);

    if (_points.isNotEmpty) {
      final prev = _points.last;

      // --- Distance (haversine) ---
      final segmentDist = GeoUtils.haversineDistance(
        prev.lat,
        prev.lng,
        point.lat,
        point.lng,
      );
      _distanceMeters += segmentDist;

      // --- Denivele (filtre bruit < 3m) ---
      final altDiff = point.elevation - prev.elevation;
      if (altDiff.abs() >= elevationNoiseThresholdM) {
        if (altDiff > 0) {
          _elevationGainM += altDiff;
        } else {
          _elevationLossM += altDiff.abs();
        }
      }

      // --- Temps et vitesses ---
      if (point.timestamp != null && prev.timestamp != null) {
        final gap = point.timestamp!.difference(prev.timestamp!);
        final gapSeconds = gap.inSeconds;

        if (gapSeconds > pauseThresholdSeconds) {
          // Pause detectee : ne pas compter dans le temps actif
          _pauseCount++;
          _currentSpeedMs = 0.0;
        } else if (gapSeconds > 0) {
          _activeDuration += gap;
          _currentSpeedMs = segmentDist / gapSeconds;
        }
      }
    }

    _points.add(point);
  }

  /// Remet toutes les stats a zero.
  void reset() {
    _points.clear();
    _distanceMeters = 0.0;
    _elevationGainM = 0.0;
    _elevationLossM = 0.0;
    _altitudeMinM = double.infinity;
    _altitudeMaxM = double.negativeInfinity;
    _activeDuration = Duration.zero;
    _currentSpeedMs = 0.0;
    _pauseCount = 0;
  }
}
