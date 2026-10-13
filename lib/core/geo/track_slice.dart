/// La TRANCHE d'un trace entre deux abscisses, bornes interpolees comprises :
/// ce que le randonneur a parcouru, decrit par le sentier et non par ses
/// releves (lot 671-06).
///
/// DE LA GEOMETRIE ET RIEN D'AUTRE, comme `track_projection.dart` dont elle
/// reutilise l'interpolation : ni Flutter, ni greffon, ni feature, ni base. Une
/// garde structurelle le verifie.
library;

import 'trace_point.dart';
import 'track_projection.dart';

/// Decoupe un trace de reference entre deux distances depuis son depart.
class TrackSlice {
  TrackSlice._();

  /// Les points de [trackPoints] entre [fromM] et [toM], dans l'ordre du
  /// trace : le point INTERPOLE a [fromM], les points du trace strictement
  /// entre les deux, le point INTERPOLE a [toM].
  ///
  /// LES BORNES INTERPOLEES NE SONT PAS UN RAFFINEMENT : sans elles, la
  /// tranche s'arrondirait au point du trace le plus proche, a plusieurs
  /// centaines de metres pres sur un trace grossierement echantillonne (les
  /// points du Mare a Mare Centre sont espaces d'un kilometre). Elles viennent
  /// de [TrackProjector.locate], la fonction d'avance du lot 671-03 :
  /// recherche dichotomique sur les distances cumulees, puis interpolation —
  /// rien n'est recalcule ici.
  ///
  /// LES CAS LIMITES, UN PAR UN :
  /// - [toM] AVANT [fromM] : REFUSE par une [ArgumentError], comme
  ///   [TrackProjector.project] refuse un trace trop court. Une tranche a
  ///   l'envers rendrait des deniveles intervertis ; c'est a l'appelant de
  ///   dire dans quel sens il l'a parcourue ;
  /// - bornes EGALES : tranche de longueur nulle, ses deux bornes confondues,
  ///   aucune erreur ;
  /// - bornes hors du trace : BORNEES a ses extremites, comme l'avance ;
  /// - trace de moins de 2 points : REFUSE ([ArgumentError]) ;
  /// - points DUPLIQUES dans le trace (cela existe dans les GPX) : gardes tels
  ///   quels, segment de longueur nulle, sans aucune division.
  static List<TrackPoint> between({
    required List<TrackPoint> trackPoints,
    required double fromM,
    required double toM,
  }) {
    if (fromM.isNaN || toM.isNaN || toM < fromM) {
      throw ArgumentError(
        'Une tranche de trace va du depart vers la fin '
        '(recu: de $fromM m a $toM m).',
      );
    }
    final start = TrackProjector.locate(
      trackPoints: trackPoints,
      distanceFromStartM: fromM,
    );
    final end = TrackProjector.locate(
      trackPoints: trackPoints,
      distanceFromStartM: toM,
    );
    return [
      _pointAt(start),
      for (var i = start.segmentIndex + 1; i <= end.segmentIndex; i++)
        if (trackPoints[i].distanceFromStart > start.distanceFromStartM &&
            trackPoints[i].distanceFromStart < end.distanceFromStartM)
          trackPoints[i],
      _pointAt(end),
    ];
  }

  static TrackPoint _pointAt(TrackAbscissa a) => TrackPoint(
    lat: a.lat,
    lng: a.lng,
    altitude: a.altitude,
    distanceFromStart: a.distanceFromStartM,
  );
}
