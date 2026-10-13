/// Rabat une position GPS sur le segment de trace le plus proche — en cherchant
/// d'abord dans une fenetre de 50 segments autour du dernier, et sur le trace
/// ENTIER des que cette fenetre a perdu la position (tache 780) ; et, depuis
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
/// Optimisation : recherche dans une fenêtre de 50 segments autour de la
/// dernière projection connue pour éviter un scan complet — et repli sur le
/// tracé entier quand la fenêtre ne peut pas répondre, parce qu'UNE
/// OPTIMISATION NE CHANGE PAS LA RÉPONSE (cf. [_parLaFenetre], tâche 780).
class TrackProjector {
  TrackProjector._();

  /// Taille de la fenêtre de recherche autour du dernier index connu.
  ///
  /// ELLE COMPTE DES SEGMENTS, PAS DES METRES : sa portee geographique depend
  /// donc de la densite du trace, et c'est ce qui a reveille le defaut de la
  /// tache 780 quand la trace du sentier de demonstration est passee de 53 a
  /// 3 590 points. Le repli de [_parLaFenetre] rend ce reglage inoffensif —
  /// il ne change plus que le COUT de la recherche, jamais son resultat.
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

    final totalSegments = trackPoints.length - 1;

    final best = lastKnownIndex == null
        ? _plusProcheEntre(userLat, userLng, trackPoints, 0, totalSegments)
        : _parLaFenetre(userLat, userLng, trackPoints, lastKnownIndex);

    final bestDistance = best.distance;
    final bestIndex = best.index;
    final bestLat = best.lat;
    final bestLng = best.lng;

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

  /// Le segment le plus proche vu PAR LA FENETRE, et le repli sur le trace
  /// ENTIER quand la fenetre ne peut pas repondre (tache 780).
  ///
  /// CE QUI NE MARCHAIT PAS, MESURE SUR LA VRAIE TRACE. [_searchWindow] compte
  /// des SEGMENTS, pas des metres : sa portee depend donc de la DENSITE du
  /// trace, et la tache 761 l'a changee d'un ordre de grandeur. Sur le croquis
  /// de 53 points espaces de 1 079 m, 50 segments couvraient 54 km — tout le
  /// sentier : la fenetre ne bornait RIEN et [project] rendait toujours le
  /// minimum global. Sur la trace relevee de 3 590 points espaces de 19 m,
  /// elle couvre 960 m. La meme constante, le meme code, une autre reponse.
  ///
  /// POURQUOI CELA CASSE LA DEMONSTRATION. Le bouton « Simuler l'etape
  /// suivante » deplace le marcheur de 9 a 20 km EN UN SEUL RELEVE : la
  /// position suivante tombe tres loin de la fenetre. La recherche fenetree
  /// est une descente gloutonne — elle ne voit que 960 m de sentier — et elle
  /// se fait PIEGER PAR UN MINIMUM LOCAL : a l'abscisse 41,308 km du Mare a
  /// Mare, le segment le plus proche DANS la fenetre est celui du milieu, pas
  /// celui du bord, donc l'index ne bouge plus JAMAIS. L'abscisse projetee —
  /// qui est le « parcouru » affiche — se FIGE, l'ecart au trace CROIT a
  /// chaque pas du marcheur, et le bouton, qui calcule sa cible depuis cette
  /// abscisse figee, vise une borne DERRIERE le marcheur et ne fait plus rien.
  ///
  /// LA REGLE POSEE ICI : UNE OPTIMISATION NE CHANGE PAS LA REPONSE. La
  /// fenetre n'est crue que si la position est VRAIMENT dans son voisinage, et
  /// le critere ne demande aucun seuil a regler : la fenetre couvre une
  /// certaine longueur de sentier ([porteeM], lue sur les distances cumulees
  /// du trace). Si le plus proche segment qu'elle trouve est PLUS LOIN que
  /// cette longueur, la position n'est pas dans son voisinage et le vrai
  /// minimum peut etre n'importe ou : on rescanne le trace entier. Le critere
  /// se regle donc tout seul sur la densite — sur le croquis de 53 points la
  /// portee valait 54 km et ce repli ne se declenchait jamais, ce qui est
  /// exactement le comportement d'avant.
  ///
  /// CE QUE CELA COUTE : rien en marche normale. Le marcheur est SUR le trace,
  /// l'ecart trouve vaut quelques metres contre 960 de portee, et la fenetre
  /// repond. Le trace entier n'est rescanne que quand la fenetre a deja perdu
  /// la position — c'est-a-dire au moment ou elle rendait un chiffre FAUX.
  static ({double distance, int index, double lat, double lng}) _parLaFenetre(
    double userLat,
    double userLng,
    List<TrackPoint> trackPoints,
    int lastKnownIndex,
  ) {
    final totalSegments = trackPoints.length - 1;
    final startIdx = max(0, lastKnownIndex - _searchWindow);
    final endIdx = min(totalSegments, lastKnownIndex + _searchWindow);
    final best = _plusProcheEntre(
      userLat,
      userLng,
      trackPoints,
      startIdx,
      endIdx,
    );
    final porteeM =
        trackPoints[endIdx].distanceFromStart -
        trackPoints[startIdx].distanceFromStart;
    if (best.distance <= porteeM) return best;
    return _plusProcheEntre(userLat, userLng, trackPoints, 0, totalSegments);
  }

  /// Le segment le plus proche de la position parmi ceux de [startIdx] inclus
  /// a [endIdx] exclu. La geometrie est celle de [GeoUtils], pas une autre.
  static ({double distance, int index, double lat, double lng})
  _plusProcheEntre(
    double userLat,
    double userLng,
    List<TrackPoint> trackPoints,
    int startIdx,
    int endIdx,
  ) {
    var bestDistance = double.infinity;
    var bestIndex = startIdx;
    var bestLat = trackPoints[startIdx].lat;
    var bestLng = trackPoints[startIdx].lng;

    for (var i = startIdx; i < endIdx; i++) {
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
    return (
      distance: bestDistance,
      index: bestIndex,
      lat: bestLat,
      lng: bestLng,
    );
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
