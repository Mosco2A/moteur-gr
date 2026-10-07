/// Rabat une position GPS sur le segment de trace le plus proche, en ne
/// cherchant que dans une fenetre de 50 segments autour du dernier ; et, depuis
/// le lot 671-03, fait AVANCER un point le long du trace d'un nombre de metres
/// donne, sans GPS : c'est le recalage sur le trace.
///
/// DE LA GEOMETRIE ET RIEN D'AUTRE. Ce fichier n'importe ni Flutter, ni
/// greffon, ni feature : il est lu par l'isolate de l'interface ET par celui de
/// fond, et une garde structurelle le verifie.
library;

import 'dart:math';

import 'geo_utils.dart';
import 'trace_point.dart';

/// Résultat de la projection d'un point GPS sur le tracé.
///
/// Contient la position projetée, la distance au tracé,
/// l'index du segment, et les distances cumulées.
typedef TrackProjection = ({
  double projectedLat,
  double projectedLng,
  double distanceToTrackM,
  int trackIndexPosition,
  double distanceFromStartM,
  double distanceRemainingM,
});

/// Un point SUR le trace (lot 671-03) : ses coordonnees, son altitude, le
/// segment qui le porte et sa distance depuis le depart du trace.
///
/// C'est ce que rend l'avance, et ce dont elle repart : un point estime est
/// par construction sur le trace, il n'a pas de distance au trace.
typedef TrackAbscissa = ({
  double lat,
  double lng,
  double altitude,
  int segmentIndex,
  double distanceFromStartM,
});

/// Le sens de la marche le long du trace : vers la fin (distances
/// croissantes) ou vers le depart (distances decroissantes).
enum WalkDirection {
  /// Du depart vers la fin du trace.
  increasing,

  /// De la fin vers le depart du trace.
  decreasing,
}

/// LA ZONE MORTE DU SENS DE LA MARCHE : deux releves dont les distances sur le
/// trace different de moins de 20 m ne changent pas le sens.
///
/// POURQUOI. A l'arret, deux releves successifs tombent a quelques metres l'un
/// de l'autre, dans un ordre quelconque : le bruit du recepteur. Sans zone
/// morte, ce bruit retournerait le sens au hasard, et les premiers pas de la
/// reprise feraient reculer le point. 20 m, c'est deux fois l'erreur courante
/// d'un releve en montagne, et quinze secondes de marche : un vrai demi-tour
/// la franchit des le releve suivant.
const double kWalkDirectionDeadBandMeters = 20.0;

/// Projette un point GPS utilisateur sur le segment de tracé le plus proche.
///
/// Optimisation : recherche dans une fenêtre de 50 segments autour
/// de la dernière projection connue pour éviter un scan complet.
class TrackProjector {
  TrackProjector._();

  /// Taille de la fenêtre de recherche autour du dernier index connu.
  static const int _searchWindow = 50;

  /// Projette [userLat, userLng] sur le tracé [trackPoints].
  ///
  /// [lastKnownIndex] — index du segment de la dernière projection.
  /// Si null, on scanne tout le tracé (premier appel).
  ///
  /// Retourne un [TrackProjection] avec toutes les infos nécessaires.
  /// Lève une [ArgumentError] si le tracé a moins de 2 points.
  static TrackProjection project({
    required double userLat,
    required double userLng,
    required List<TrackPoint> trackPoints,
    int? lastKnownIndex,
  }) {
    _requireTrack(trackPoints);

    // Déterminer la fenêtre de recherche
    final totalSegments = trackPoints.length - 1;
    int startIdx;
    int endIdx;

    if (lastKnownIndex == null) {
      // Premier appel : scanner tout le tracé
      startIdx = 0;
      endIdx = totalSegments;
    } else {
      // Recherche dans une fenêtre autour du dernier index
      startIdx = max(0, lastKnownIndex - _searchWindow);
      endIdx = min(totalSegments, lastKnownIndex + _searchWindow);
    }

    // Trouver le segment le plus proche
    double bestDistance = double.infinity;
    int bestIndex = startIdx;
    double bestLat = trackPoints[startIdx].lat;
    double bestLng = trackPoints[startIdx].lng;

    for (int i = startIdx; i < endIdx; i++) {
      final a = trackPoints[i];
      final b = trackPoints[i + 1];

      final proj = GeoUtils.projectPointOnSegment(
        userLat,
        userLng,
        a.lat,
        a.lng,
        b.lat,
        b.lng,
      );

      if (proj.distanceToSegment < bestDistance) {
        bestDistance = proj.distanceToSegment;
        bestIndex = i;
        bestLat = proj.projectedLat;
        bestLng = proj.projectedLng;
      }
    }

    // Calculer la distance depuis le début du tracé
    // = distance cumulée jusqu'au segment + distance du point A au projeté
    final segmentStart = trackPoints[bestIndex];
    final distAlongSegment = GeoUtils.haversineDistance(
      segmentStart.lat,
      segmentStart.lng,
      bestLat,
      bestLng,
    );
    final distanceFromStart = segmentStart.distanceFromStart + distAlongSegment;

    // Distance totale du tracé = distanceFromStart du dernier point
    final totalDistance = trackPoints.last.distanceFromStart;
    final distanceRemaining = max(0.0, totalDistance - distanceFromStart);

    return (
      projectedLat: bestLat,
      projectedLng: bestLng,
      distanceToTrackM: bestDistance,
      trackIndexPosition: bestIndex,
      distanceFromStartM: distanceFromStart,
      distanceRemainingM: distanceRemaining,
    );
  }

  /// Le point du trace situe a [distanceFromStartM] du depart (lot 671-03).
  ///
  /// RECHERCHE DICHOTOMIQUE SUR LES DISTANCES CUMULEES, PAS DE FENETRE. Chaque
  /// point du trace porte deja sa distance depuis le depart
  /// ([TrackPoint.distanceFromStart]) : on ne cherche pas le segment le PLUS
  /// PROCHE d'une position, comme [project], on cherche le segment qui CONTIENT
  /// une abscisse. La fenetre de 50 segments de [project] n'a donc rien a
  /// faire ici ; la recopier par mimetisme ferait rater une avance longue.
  ///
  /// Une abscisse hors du trace est BORNEE a ses extremites : le point ne
  /// sort jamais du trace. Un segment de longueur nulle (deux points
  /// dupliques dans le GPX, cela existe) est enjambe sans division. Leve une
  /// [ArgumentError] si le trace a moins de 2 points, comme [project].
  static TrackAbscissa locate({
    required List<TrackPoint> trackPoints,
    required double distanceFromStartM,
  }) {
    _requireTrack(trackPoints);
    final total = trackPoints.last.distanceFromStart;
    final target = distanceFromStartM.clamp(0.0, total).toDouble();
    final i = _segmentContaining(trackPoints, target);
    final a = trackPoints[i];
    final b = trackPoints[i + 1];
    final length = b.distanceFromStart - a.distanceFromStart;
    // Segment de longueur nulle (doublon du GPX) : le point est A, sans
    // division. Seul le dernier segment peut etre retenu ainsi, la recherche
    // prenant toujours le DERNIER segment qui commence avant l'abscisse.
    final t = length > 0 ? (target - a.distanceFromStart) / length : 0.0;
    return (
      lat: a.lat + (b.lat - a.lat) * t,
      lng: a.lng + (b.lng - a.lng) * t,
      altitude: a.altitude + (b.altitude - a.altitude) * t,
      segmentIndex: i,
      distanceFromStartM: target,
    );
  }

  /// Avance de [meters] le long du trace depuis [from], dans le sens
  /// [direction] (lot 671-03).
  ///
  /// LES CINQ CAS LIMITES, UN PAR UN :
  /// - au-dela d'une extremite : BORNE a l'extremite, index du dernier (ou du
  ///   premier) segment — le point ne sort jamais du trace ;
  /// - avance NEGATIVE : REFUSEE par une [ArgumentError]. Un nombre de pas ne
  ///   peut pas etre negatif, et la borner a zero masquerait un compteur faux
  ///   en arret silencieux ; on leve, comme [project] leve sur un trace trop
  ///   court, pour que l'appelant fautif se voie ;
  /// - avance NULLE : [from] rendu tel quel, sans recalcul ni changement
  ///   d'index — c'est l'arret, il doit etre gratuit ;
  /// - trace de moins de 2 points : REFUSE ([ArgumentError]), comme [project] ;
  /// - segment de longueur nulle : enjambe sans division (voir [locate]).
  static TrackAbscissa advance({
    required List<TrackPoint> trackPoints,
    required TrackAbscissa from,
    required double meters,
    WalkDirection direction = WalkDirection.increasing,
  }) {
    _requireTrack(trackPoints);
    if (meters.isNaN || meters < 0) {
      throw ArgumentError.value(
        meters,
        'meters',
        'une avance sur le trace ne peut pas etre negative',
      );
    }
    if (meters == 0) return from;
    final signed = direction == WalkDirection.increasing ? meters : -meters;
    return locate(
      trackPoints: trackPoints,
      distanceFromStartM: from.distanceFromStartM + signed,
    );
  }

  /// LE SENS DE LA MARCHE, SANS AUCUN CAPTEUR DE CAP (lot 671-03).
  ///
  /// Sur un trace connu, la direction est portee par le trace : une fois
  /// qu'on sait de combien on a avance, on sait ou l'on est. Seul le SENS
  /// reste a trancher, et ce sont les deux derniers releves reels projetes
  /// qui le donnent, par le signe de la difference de leurs distances sur le
  /// trace. Sans releve precedent ([previousM] nul), ou sous
  /// [kWalkDirectionDeadBandMeters] d'ecart, le sens reste [fallback] : celui
  /// de la marche en cours tel que le trek le connait, a defaut croissant.
  static WalkDirection directionOf({
    required double? previousM,
    required double latestM,
    required WalkDirection fallback,
  }) {
    if (previousM == null) return fallback;
    final delta = latestM - previousM;
    if (delta.abs() < kWalkDirectionDeadBandMeters) return fallback;
    return delta > 0 ? WalkDirection.increasing : WalkDirection.decreasing;
  }

  static void _requireTrack(List<TrackPoint> trackPoints) {
    if (trackPoints.length < 2) {
      throw ArgumentError(
        'Le tracé doit contenir au moins 2 points '
        '(reçu: ${trackPoints.length}).',
      );
    }
  }

  /// L'index du DERNIER segment dont le point de depart est avant [target],
  /// entre 0 et le nombre de segments moins un.
  static int _segmentContaining(List<TrackPoint> trackPoints, double target) {
    var low = 0;
    var high = trackPoints.length - 2;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (trackPoints[mid].distanceFromStart <= target) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}
