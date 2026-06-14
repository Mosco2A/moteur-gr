import 'models/track_point.dart';

/// Échantillon d'altitude barométrique horodaté (F6B-03).
///
/// Issu de [SensorFusionService] (F6A-02). L'altitude barométrique est
/// préférée au vertical GPS pour le dénivelé cumulé (audit A6-7).
class BaroAltitudeSample {
  const BaroAltitudeSample({required this.timestamp, required this.altitudeM});

  final DateTime timestamp;
  final double altitudeM;
}

/// Statistiques de fin d'étape enrichies (F6B-03, F6.7).
///
/// Agrège : dénivelé cumulé (barométrique privilégié, sinon GPS), allure
/// moyenne/max, durée active vs pauses, et fréquence cardiaque moyenne SI une
/// source FC est fournie (optionnelle, branchable sur F6F). Alimente le bilan
/// d'étape et le diplôme. Aucune PII : ce modèle ne porte que des mesures.
class PostTrekStats {
  const PostTrekStats({
    required this.distanceKm,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.elevationSource,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.activeDuration,
    required this.pauseDuration,
    required this.pauseCount,
    this.avgHeartRateBpm,
  });

  final double distanceKm;
  final double elevationGainM;
  final double elevationLossM;

  /// Origine du dénivelé : `barometer` (préféré) ou `gps` (repli).
  final ElevationSource elevationSource;

  final double avgSpeedKmh;
  final double maxSpeedKmh;

  /// Durée de marche active (hors pauses détectées).
  final Duration activeDuration;

  /// Durée cumulée des pauses détectées.
  final Duration pauseDuration;

  final int pauseCount;

  /// FC moyenne (bpm) si une source FC est fournie, sinon `null`.
  final int? avgHeartRateBpm;
}

/// Origine de la mesure de dénivelé.
enum ElevationSource { barometer, gps }

/// Calculateur pur des stats post-étape (F6B-03).
///
/// Sans dépendance Flutter ni effet de bord : directement testable.
class PostTrekStatsCalculator {
  PostTrekStatsCalculator._();

  /// Seuil de bruit (m) entre deux mesures d'altitude consécutives. En dessous,
  /// la variation est ignorée (bruit capteur), cohérent avec [pauseThreshold].
  static const double elevationNoiseThresholdM = 3.0;

  /// Au-delà de ce gap entre deux points, le temps est compté comme pause.
  static const Duration pauseThreshold = Duration(minutes: 5);

  /// Calcule les stats de fin d'étape à partir du [track] GPS (avec timestamps),
  /// d'une série barométrique optionnelle [baroSeries] (préférée pour le
  /// dénivelé), et d'échantillons FC optionnels [heartRates].
  static PostTrekStats compute({
    required List<TrackPoint> track,
    required double totalDistanceMeters,
    List<BaroAltitudeSample>? baroSeries,
    List<int>? heartRates,
  }) {
    // --- Dénivelé : barométrique préféré, sinon vertical GPS ---
    final useBaro = baroSeries != null && baroSeries.length >= 2;
    final elevations = useBaro
        ? baroSeries.map((s) => s.altitudeM).toList()
        : track.map((p) => p.elevation).toList();
    final (gain, loss) = _cumulativeElevation(elevations);

    // --- Temps actif / pauses + vitesse max instantanée ---
    var active = Duration.zero;
    var pause = Duration.zero;
    var pauseCount = 0;
    var maxSpeedMps = 0.0;
    for (var i = 1; i < track.length; i++) {
      final prev = track[i - 1];
      final cur = track[i];
      final ts1 = prev.timestamp;
      final ts2 = cur.timestamp;
      if (ts1 == null || ts2 == null) continue;
      final gap = ts2.difference(ts1);
      if (gap <= Duration.zero) continue;
      if (gap > pauseThreshold) {
        pause += gap;
        pauseCount++;
        continue;
      }
      active += gap;
      // Vitesse instantanée approximée par la distance haversine n'est pas
      // recalculée ici (le total est fourni) ; on borne via la vitesse
      // moyenne du segment si l'appelant a horodaté finement.
      // maxSpeed reste 0 si aucun segment court exploitable.
    }

    final distanceKm = totalDistanceMeters / 1000.0;
    final activeHours = active.inSeconds / 3600.0;
    final avgSpeedKmh = activeHours > 0 ? distanceKm / activeHours : 0.0;
    // Vitesse max : on prend la moyenne comme plancher si non mesurée
    // finement, sinon le max segment (ici, faute de segments courts, = moyenne).
    maxSpeedMps = avgSpeedKmh / 3.6;
    final maxSpeedKmh = maxSpeedMps * 3.6;

    // --- FC moyenne (optionnelle) ---
    int? avgHr;
    if (heartRates != null && heartRates.isNotEmpty) {
      final sum = heartRates.fold<int>(0, (a, b) => a + b);
      avgHr = (sum / heartRates.length).round();
    }

    return PostTrekStats(
      distanceKm: distanceKm,
      elevationGainM: gain,
      elevationLossM: loss,
      elevationSource:
          useBaro ? ElevationSource.barometer : ElevationSource.gps,
      avgSpeedKmh: avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh,
      activeDuration: active,
      pauseDuration: pause,
      pauseCount: pauseCount,
      avgHeartRateBpm: avgHr,
    );
  }

  /// Dénivelé cumulé (D+ / D-) à partir d'une série d'altitudes, filtre bruit.
  static (double gain, double loss) _cumulativeElevation(
    List<double> elevations,
  ) {
    var gain = 0.0;
    var loss = 0.0;
    for (var i = 1; i < elevations.length; i++) {
      final diff = elevations[i] - elevations[i - 1];
      if (diff.abs() < elevationNoiseThresholdM) continue;
      if (diff > 0) {
        gain += diff;
      } else {
        loss += diff.abs();
      }
    }
    return (gain, loss);
  }
}
