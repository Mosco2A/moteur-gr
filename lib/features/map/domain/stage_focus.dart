import '../../../core/geo/track_point.dart';
import '../../../core/models/stage.dart';

/// OU LA CARTE DOIT S'OUVRIR (tache 558).
///
/// Retour de Chris, mot pour mot : « Je veux etre a la premiere etape et voir
/// le sentier !!! ». La carte s'ouvrait cadree sur le sentier ENTIER : a cette
/// echelle, le trace est un fil de quelques pixels et on n'est nulle part en
/// particulier. Elle s'ouvre desormais sur UNE etape — celle qu'on marche si la
/// base en connait une, la premiere sinon — avec son troncon de trace en entier
/// dans le cadre.
///
/// Ces fonctions sont PURES et vivent hors de l'ecran pour etre testables sans
/// carte ni GPS : elles ne decident que du « quoi cadrer », jamais du « comment
/// zoomer », qui reste l'affaire de la carte.

/// L'ETAPE SUR LAQUELLE CADRER.
///
/// [currentStageNumber] vient de la progression persistee (colonne
/// `currentStage`). Quand il designe une etape connue, c'est elle. Sinon — pas
/// de progression, trek termine, numero hors du sentier — c'est la PREMIERE
/// etape, qui est le point de depart connu du programme. `null` seulement quand
/// le sentier n'a aucune etape chargee : on ne cadre alors sur rien plutot que
/// sur un lieu devine.
StageModel? mapFocusStage(List<StageModel>? stages, int? currentStageNumber) {
  if (stages == null || stages.isEmpty) return null;
  if (currentStageNumber != null) {
    for (final stage in stages) {
      if (stage.stageNumber == currentStageNumber) return stage;
    }
  }
  // Premiere etape = plus petit numero, et non « premiere de la liste » : la
  // source peut rendre les lignes dans l'ordre de la base.
  var first = stages.first;
  for (final stage in stages) {
    if (stage.stageNumber < first.stageNumber) first = stage;
  }
  return first;
}

/// Index du point de trace le plus proche d'une coordonnee.
///
/// Distance EUCLIDIENNE sur les degres, volontairement : on ne cherche pas une
/// distance en metres, on cherche le point le plus proche, et l'ordre des
/// candidats est le meme a l'echelle d'un sentier. Pas de trigonometrie pour un
/// resultat identique.
int nearestTrackPointIndex(List<TrackPoint> points, double lat, double lng) {
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < points.length; i++) {
    final dLat = points[i].lat - lat;
    final dLng = points[i].lng - lng;
    final distance = dLat * dLat + dLng * dLng;
    if (distance < bestDistance) {
      bestDistance = distance;
      best = i;
    }
  }
  return best;
}

/// LE TRONCON DE TRACE D'UNE ETAPE : du point le plus proche de son depart au
/// point le plus proche de son arrivee, bornes comprises.
///
/// Rend une liste VIDE quand il n'y a rien d'exploitable (trace absente, ou
/// depart et arrivee qui tombent sur le meme point de trace). L'appelant cadre
/// alors sur ce qu'il a — le sentier entier — plutot que sur un segment qui
/// n'existe pas. On ne fabrique jamais un cadrage sur une donnee manquante.
List<TrackPoint> stageTrackSegment(List<TrackPoint> points, StageModel stage) {
  if (points.length < 2) return const [];
  var from = nearestTrackPointIndex(points, stage.startLat, stage.startLng);
  var to = nearestTrackPointIndex(points, stage.endLat, stage.endLng);
  if (from > to) {
    final swap = from;
    from = to;
    to = swap;
  }
  if (to - from < 1) return const [];
  return points.sublist(from, to + 1);
}
