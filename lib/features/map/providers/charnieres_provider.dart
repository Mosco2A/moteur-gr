/// LES CHARNIERES DU SENTIER ACTIF (lot 671-04), calculees UNE FOIS avec le
/// trace et gardees avec lui : les endroits ou l'on se trompe de chemin, la
/// ou le GPS se recale plus souvent.
///
/// CE QUI EST CALCULE, ET CE QUI VIENT D'UNE DONNEE. Les charnieres sont
/// d'abord GEOMETRIQUES ([charnieresDuTrace], socle). Elles sont ENRICHIES par
/// les reperes de type `jonction` du sentier (table `waypoint`) : ils portent
/// deja des coordonnees, un type dans une liste fermee, un style et un
/// libelle, et la donnee communautaire en produira naturellement. Les points
/// d'interet (`Poi.type`, chaine extensible) restent un chemin OUVERT mais non
/// cable. AUJOURD'HUI AUCUN SENTIER NE DECLARE DE JONCTION : le cas courant
/// est ZERO donnee enrichie, et tout marche sans elle.
///
/// DEUX COLONNES `source`, DEUX SENS. Celle des reperes dit `officiel` ou
/// `communaute` ; celle des points de trace (lot 671-03) dit `gps` ou
/// `estime`. Ce fichier ne lit ni l'une ni l'autre : une jonction compte
/// quelle que soit sa provenance.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/geo/charnieres_du_trace.dart';
import '../../../core/geo/trace_point.dart';
import '../../../core/geo/track_projection.dart';
import '../../../core/providers/database_provider.dart';
import '../../community/community_facade.dart' show WaypointType;
import '../domain/off_track_detector.dart';
import 'gpx_track_provider.dart';

/// LES CHARNIERES DU SENTIER [trailId], derivees de [gpxTrackProvider] et des
/// jonctions declarees, triees par abscisse.
///
/// LE CALCUL SE FAIT AU CHARGEMENT DU SENTIER, PAS A CHAQUE POSITION. Mesure
/// du lot 671-04 sur le sentier de reference du depot (53 points, 72,9 km) :
/// quelques millisecondes, une fois. Une base illisible n'empeche rien : les
/// charnieres calculees restent, sans enrichissement.
final charnieresDuSentierProvider =
    FutureProvider.family<List<Charniere>, String>((ref, trailId) async {
      final trace = await ref.watch(gpxTrackProvider(trailId).future);
      if (trace.length < 2) return const [];
      var jonctions = const <({double lat, double lng})>[];
      try {
        final reperes = await ref
            .watch(databaseProvider)
            .waypointsDao
            .waypointsForTrail(trailId);
        jonctions = [
          for (final r in reperes)
            if (r.type == WaypointType.jonction)
              (lat: r.latitude, lng: r.longitude),
        ];
      } on Object catch (e, st) {
        ErrorHandler.log(e, stackTrace: st, context: 'charnieresDuSentier');
      }
      return charnieresDuTrace(
        trace,
        enrichies: projeterLesJonctions(trace, jonctions),
      );
    });

/// LES JONCTIONS PROJETEES SUR [trace], en charnieres enrichies.
///
/// LE PIEGE DE LA FENETRE DE 50 SEGMENTS. [TrackProjector.project] ne cherche
/// le segment le plus proche que dans 50 segments autour du DERNIER projete :
/// projeter une liste de reperes epars en lui passant chaque fois l'index du
/// precedent ferait glisser cette fenetre et RATER un repere eloigne. Chaque
/// jonction est donc projetee SEULE, sans index connu, c'est-a-dire sur TOUT
/// le trace (une passe par jonction ; elles se comptent sur les doigts).
///
/// LE GARDE-FOU : une jonction a plus de [kOffTrackExitThresholdMeters] du
/// trace est IGNOREE — une jonction a trois cents metres du sentier ne
/// concerne pas ce sentier. C'est le seuil de sortie du hors-trace : une seule
/// verite pour une seule question.
List<Charniere> projeterLesJonctions(
  List<TrackPoint> trace,
  List<({double lat, double lng})> jonctions,
) => [
  for (final j in jonctions)
    if (TrackProjector.project(
          userLat: j.lat,
          userLng: j.lng,
          trackPoints: trace,
        )
        case final p when p.distanceToTrackM <= kOffTrackExitThresholdMeters)
      Charniere.enrichie(
        abscisseM: p.distanceFromStartM,
        lat: p.projectedLat,
        lng: p.projectedLng,
      ),
];
