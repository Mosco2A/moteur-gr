import '../data/database.dart';
import '../../features/trek/domain/trek_stats.dart';
import 'geo_utils.dart';

/// Chiffres MESURES sur une suite de points GPS.
///
/// Socle partage par le journal (resume du jour, lot L4-3) et par le
/// recapitulatif d'aventure (detail jour par jour et vitesse, lot L5-5 et
/// L5-6). Un seul calcul : deux implantations finiraient par donner deux
/// chiffres differents pour la meme journee.
class TrackSegmentStats {
  const TrackSegmentStats({
    this.distanceKm = 0,
    this.elevationGainM = 0,
    this.elevationLossM = 0,
    this.duration = Duration.zero,
    this.maxAltitudeM,
    this.pointCount = 0,
  });

  /// Distance MESUREE au GPS (et non une somme d'etapes nominale).
  final double distanceKm;
  final int elevationGainM;
  final int elevationLossM;

  /// Ecart entre le premier et le dernier point du segment.
  final Duration duration;

  /// Point le plus haut, `null` sans trace.
  final double? maxAltitudeM;

  /// Nombre de points GPS derriere ces chiffres (0 = rien a afficher).
  final int pointCount;

  bool get hasData => pointCount > 1;

  /// Vitesse moyenne en km/h, `null` quand elle n'aurait AUCUN SENS.
  ///
  /// PIEGE DU LOT L5-6, evite ici par construction : la distance de
  /// [AdventureStats] est une somme NOMINALE des etapes completees, pas une
  /// distance mesuree. La diviser par un temps reel ne donne pas une vitesse
  /// de marche, elle donne un chiffre faux qui aura l'air vrai. Cette
  /// vitesse-ci ne se calcule QUE sur une distance et une duree issues des
  /// MEMES points GPS — et reste nulle si la duree est nulle ou absurde.
  double? get averageSpeedKmh {
    if (!hasData) return null;
    final hours = duration.inMilliseconds / 3600000.0;
    if (hours <= 0) return null;
    final speed = distanceKm / hours;
    // Au-dela, ce n'est plus de la marche : un saut de position GPS, un
    // transfert en vehicule. Mieux vaut ne rien montrer qu'un chiffre absurde.
    if (speed <= 0 || speed > 15) return null;
    return speed;
  }

  /// Somme de deux segments (pour un cumul).
  TrackSegmentStats plus(TrackSegmentStats other) => TrackSegmentStats(
        distanceKm: distanceKm + other.distanceKm,
        elevationGainM: elevationGainM + other.elevationGainM,
        elevationLossM: elevationLossM + other.elevationLossM,
        duration: duration + other.duration,
        maxAltitudeM: switch ((maxAltitudeM, other.maxAltitudeM)) {
          (null, final b) => b,
          (final a, null) => a,
          (final a?, final b?) => a > b ? a : b,
        },
        pointCount: pointCount + other.pointCount,
      );
}

/// Calcule les chiffres d'une suite de points GPS.
///
/// Reutilise [GeoUtils.haversineDistance] et le SEUIL DE BRUIT de
/// [TrekStats] (3 m) : sans ce seuil, le tremblement de l'altimetre fabrique
/// plusieurs centaines de metres de denivele sur une journee plate. Aucun
/// moteur de stats n'est reconstruit ici.
TrackSegmentStats computeTrackStats(List<SessionTrackPoint> points) {
  if (points.length < 2) {
    return TrackSegmentStats(
      pointCount: points.length,
      maxAltitudeM: points.isEmpty ? null : points.first.altitude,
    );
  }
  var meters = 0.0;
  var gain = 0.0;
  var loss = 0.0;
  var maxAlt = points.first.altitude;
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final cur = points[i];
    meters += GeoUtils.haversineDistance(prev.lat, prev.lng, cur.lat, cur.lng);
    final d = cur.altitude - prev.altitude;
    if (d.abs() >= TrekStats.elevationNoiseThresholdM) {
      if (d > 0) {
        gain += d;
      } else {
        loss += -d;
      }
    }
    if (cur.altitude > maxAlt) maxAlt = cur.altitude;
  }
  return TrackSegmentStats(
    distanceKm: meters / 1000.0,
    elevationGainM: gain.round(),
    elevationLossM: loss.round(),
    duration: points.last.recordedAt.difference(points.first.recordedAt),
    maxAltitudeM: maxAlt,
    pointCount: points.length,
  );
}
