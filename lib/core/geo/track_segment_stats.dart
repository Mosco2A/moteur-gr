/// Un SEUL calcul de chiffres sur une suite de points, partage par le carnet et
/// le recapitulatif : deux implantations finiraient par divergeur.
library;

import 'geo_utils.dart';

/// LE MINIMUM GEOMETRIQUE dont le calcul a besoin (lot 671-06) : un point,
/// son altitude, et rien d'autre — ni horodatage, ni origine, ni base.
///
/// TROIS GRANDEURS, PAS QUATRE, ET LA QUATRIEME EST PASSEE A PART. Le calcul
/// lisait aussi `recordedAt`, pour la duree. Or la tranche de trace que le lot
/// 671-06 lui donne n'a PAS d'horodatage (`trace_point.dart` le dit en
/// en-tete) : une duree tiree de la geometrie vaudrait zero, et la vitesse
/// disparaitrait. La duree est donc un parametre OBLIGATOIRE de
/// [computeTrackStatsOn] — on ne peut pas l'oublier, on doit dire d'ou elle
/// vient. Un enregistrement et non une classe : aucune generation de code,
/// sur le modele de `TrackAbscissa` (`track_projection.dart`).
typedef StatsPoint = ({double lat, double lng, double altitude});

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

  /// Distance MESUREE (et non une somme d'etapes nominale) : sur la tranche
  /// de trace parcourue depuis le lot 671-06, sur les releves sans trace.
  final double distanceKm;
  final int elevationGainM;
  final int elevationLossM;

  /// Ecart entre le premier et le dernier RELEVE REEL du segment.
  ///
  /// Fournie par l'appelant depuis le lot 671-06 (voir [computeTrackStatsOn]) :
  /// une tranche de trace n'a pas d'horodatage, le temps vient des releves.
  final Duration duration;

  /// Point le plus haut, `null` sans trace.
  final double? maxAltitudeM;

  /// Nombre de points GPS derriere ces chiffres (0 = rien a afficher).
  ///
  /// Sur une tranche de trace (lot 671-06), c'est le nombre de RELEVES REELS
  /// qui la bornent et la datent : [hasData] dit donc, comme avant, s'il y a
  /// eu au moins deux releves.
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

/// Calcule les chiffres d'une suite de points, en [duration].
///
/// Sous deux points, le resultat est degrade comme avant le lot 671-06 :
/// aucune distance, aucun denivele, une duree nulle.
///
/// Reutilise [GeoUtils.haversineDistance] et
/// [GeoUtils.elevationNoiseThresholdM] (3 m) : sans ce seuil, le tremblement de
/// l'altimetre fabrique plusieurs centaines de metres de denivele sur une
/// journee plate. Aucun moteur de stats n'est reconstruit ici.
///
/// LE SEUIL EST LU DANS LE SOCLE, PLUS DANS `TrekStats` (ARB-645-05-c). Ce
/// fichier est du socle : il ne peut pas connaitre le metier, et il n'avait
/// besoin que d'un nombre — la valeur est la meme, a un seul endroit.
///
/// LOT 671-06 : LA SIGNATURE A CHANGE, PAS LE CALCUL. La fonction prend la
/// GEOMETRIE ([StatsPoint]) d'un cote et la DUREE ([duration]) de l'autre ;
/// la boucle ci-dessous est celle d'avant, au caractere pres. Ce fichier
/// n'importe plus la base : l'adaptation des points enregistres
/// (`computeTrackStats`) et la tranche de trace (`computeTrackStatsOnTrace`)
/// vivent dans `recorded_track_stats.dart`, et passent toutes deux par ici.
TrackSegmentStats computeTrackStatsOn(
  List<StatsPoint> points, {
  required Duration duration,
}) {
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
    if (d.abs() >= GeoUtils.elevationNoiseThresholdM) {
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
    duration: duration,
    maxAltitudeM: maxAlt,
    pointCount: points.length,
  );
}
