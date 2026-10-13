/// Les deux ENTREES du moteur de chiffres : les points enregistres tels quels,
/// et la tranche de trace bornee et datee par les releves reels (lot 671-06).
/// Un seul calcul derriere les deux : [computeTrackStatsOn].
library;

import '../data/database.dart';
import 'trace_point.dart';
import 'track_projection.dart';
import 'track_segment_stats.dart';
import 'track_slice.dart';

/// AU-DELA DE CETTE DISTANCE AU TRACE, LE TRACE NE DECRIT PAS LA MARCHE : un
/// releve de borne qui en est plus loin n'est ni sur une variante, ni au
/// parking du depart, il est ailleurs — un autre sentier, une marche d'essai a
/// la maison. Les chiffres reviennent alors aux releves, comme avant le lot
/// 671-06, plutot que de mesurer une tranche de sentier ou personne n'a
/// marche.
///
/// 500 m : six fois le seuil de sortie du hors-trace (80 m), pour qu'un
/// depart du village ou un detour vers un refuge restent mesures sur le
/// sentier ; vingt fois l'erreur courante d'un releve en montagne. Valeur de
/// jugement, non mesuree sur le terrain : elle est nommee pour cela.
const double kStatsMaxOffTraceMeters = 500.0;

/// Les chiffres d'une suite de POINTS ENREGISTRES, leur geometrie telle
/// quelle : la surcharge d'adaptation de [computeTrackStatsOn].
///
/// ELLE CONVERTIT, ELLE NE CALCULE RIEN. Le resultat est celui d'avant le lot
/// 671-06 au metre et a la seconde : meme boucle, memes points, et la duree
/// est l'ecart entre le premier et le dernier point, comme la fonction la
/// calculait elle-meme. C'est le repli de [computeTrackStatsOnTrace] quand le
/// sentier n'a pas de trace.
TrackSegmentStats computeTrackStats(List<SessionTrackPoint> points) =>
    computeTrackStatsOn(
      _geometryOfReadings(points),
      duration: _durationOfReadings(points),
    );

/// Les chiffres d'un perimetre de marche (une session, une journee) calcules
/// SUR LE TRACE (lot 671-06) : la geometrie vient de la tranche du sentier
/// parcourue, le temps vient des releves reels.
///
/// POURQUOI. Avec un releve toutes les 3 minutes, deux releves sont espaces
/// de 200 m a 4 km/h : la corde qui les relie efface les bosses et coupe les
/// lacets, et le denivele du jour s'effondre. Le trace, lui, porte l'altitude
/// de chacun de ses points.
///
/// [readings] : les SEULS RELEVES REELS du perimetre, dans l'ordre
/// d'enregistrement — une lecture `TrackPointsRead.gpsOnly`. Ils donnent :
/// - LA BORNE DE DEPART : le premier releve, projete sur le trace ;
/// - LA BORNE DE FIN : [currentDistanceM] quand l'appelant connait la
///   position courante sur le trace (la carte), sinon le dernier releve,
///   projete ;
/// - LA DUREE : l'ecart entre le premier et le dernier releve, exactement
///   la valeur d'avant le lot. UNE TRANCHE DE SENTIER N'A PAS DE DUREE : la
///   prendre au trace donnerait zero et la vitesse disparaitrait ;
/// - LE NOMBRE DE POINTS : celui des releves, donc [TrackSegmentStats.hasData]
///   inchange — un seul releve ne fait toujours ni vitesse ni chiffre affiche.
///
/// LES BORNES LUES EN BASE SONT DES RELEVES REELS, PAS DES POINTS ESTIMES.
/// Un point estime est par construction SUR le trace, son abscisse est
/// exacte, mais elle a pu deriver de quelques metres depuis le dernier
/// releve ; le releve reel projete est la meilleure borne disponible. Seule la
/// carte passe une borne de fin plus fraiche, la position courante, qu'elle
/// affiche deja. Et un point estime n'entre JAMAIS dans la duree : il est date
/// par l'isolate qui l'a calcule, pas par le recepteur.
///
/// LE SENS DE LA MARCHE. Un randonneur qui marche le sentier a l'envers a une
/// borne de fin AVANT sa borne de depart : la tranche est decoupee dans le
/// sens du trace puis RETOURNEE, pour que la montee qu'il a faite compte en
/// denivele positif.
///
/// LIMITE CONNUE, INHERENTE A LA METHODE ET NON CORRIGEE ICI : un aller-retour
/// sur la meme portion n'est compte qu'une fois — la tranche va de la borne de
/// depart a la borne de fin, quel que soit le chemin entre les deux.
///
/// SANS TRACE ([trace] nul ou de moins de deux points), ou quand le premier ou
/// le dernier releve est a plus de [kStatsMaxOffTraceMeters] du trace : les
/// releves, comme avant le lot ([computeTrackStats]) — un chiffre sous-estime
/// vaut mieux qu'un chiffre mesure sur un sentier ou l'on n'est pas.
TrackSegmentStats computeTrackStatsOnTrace({
  required List<SessionTrackPoint> readings,
  required List<TrackPoint>? trace,
  double? currentDistanceM,
}) {
  if (readings.isEmpty) return const TrackSegmentStats();
  if (trace == null || trace.length < 2) return computeTrackStats(readings);
  final first = _projectionOf(readings.first, trace);
  final last = _projectionOf(readings.last, trace);
  if (first.distanceToTrackM > kStatsMaxOffTraceMeters ||
      last.distanceToTrackM > kStatsMaxOffTraceMeters) {
    return computeTrackStats(readings);
  }
  final startM = first.distanceFromStartM;
  final endM = currentDistanceM ?? last.distanceFromStartM;
  final slice = startM <= endM
      ? TrackSlice.between(trackPoints: trace, fromM: startM, toM: endM)
      : TrackSlice.between(
          trackPoints: trace,
          fromM: endM,
          toM: startM,
        ).reversed.toList();
  final stats = computeTrackStatsOn(
    _geometryOfTrace(slice),
    duration: _durationOfReadings(readings),
  );
  return TrackSegmentStats(
    distanceKm: stats.distanceKm,
    elevationGainM: stats.elevationGainM,
    elevationLossM: stats.elevationLossM,
    duration: stats.duration,
    maxAltitudeM: stats.maxAltitudeM,
    pointCount: readings.length,
  );
}

/// LE RELIEF D'UNE TRANCHE DE SENTIER, bornee en ABSCISSE (tache 762).
///
/// POURQUOI ELLE EXISTE. Christophe a tranche le 09/10 16:29, mot pour mot :
/// « En sentier entier l altitude pure n a plus lieue d etre et le denivele +
/// et - doit etre le total depuis le debut et en mode sentier celui de l etape,
/// a revoir ». Le denivele de la barre venait — et vient toujours — de
/// [computeTrackStatsOnTrace], dont le perimetre est TOUTE la session : c'est
/// la bonne reponse pour la vue sentier, et c'est la mauvaise pour la vue
/// etape, qui annonce par ailleurs un total et un parcouru d'etape.
///
/// CE N'EST PAS UN SECOND MOTEUR DE DENIVELE, et c'est la seule raison pour
/// laquelle cette fonction est acceptable. Le lot 671-06 a pose la regle : un
/// deuxieme calcul finirait par donner deux deniveles differents pour la meme
/// journee. Ici il n'y a AUCUN calcul nouveau — le decoupage est celui de
/// [TrackSlice.between], la boucle est celle de [computeTrackStatsOn], le seuil
/// de bruit d'altimetre est le meme. Seules les BORNES changent : deux
/// abscisses au lieu de deux releves projetes. Meme moteur, autre tranche.
///
/// ELLE NE REND QUE DU RELIEF. [TrackSegmentStats.duration] vaut zero et
/// [TrackSegmentStats.averageSpeedKmh] est donc nulle : une tranche de sentier
/// n'a pas d'horodatage (`trace_point.dart`), et la vitesse moyenne de la barre
/// reste celle de la SESSION dans les deux perimetres — Christophe a qualifie
/// le denivele d'« etape », pas la vitesse.
///
/// Tranche vide, inversee, ou trace de moins de deux points : des chiffres
/// nuls, jamais une exception. Le marcheur juste entre dans une etape n'a
/// encore monte ni descendu quoi que ce soit, et c'est la verite.
TrackSegmentStats reliefDeLaTranche({
  required List<TrackPoint>? trace,
  required double debutM,
  required double finM,
}) {
  if (trace == null || trace.length < 2 || finM <= debutM) {
    return const TrackSegmentStats();
  }
  final slice = TrackSlice.between(
    trackPoints: trace,
    fromM: debutM,
    toM: finM,
  );
  return computeTrackStatsOn(_geometryOfTrace(slice), duration: Duration.zero);
}

/// LA SOURCE DE TEMPS, UNE SEULE : l'ecart entre le premier et le dernier
/// releve reel, nul sous deux releves.
Duration _durationOfReadings(List<SessionTrackPoint> readings) =>
    readings.length < 2
    ? Duration.zero
    : readings.last.recordedAt.difference(readings.first.recordedAt);

/// LA CONVERSION des points enregistres vers la geometrie du calcul.
List<StatsPoint> _geometryOfReadings(List<SessionTrackPoint> points) => [
  for (final p in points) (lat: p.lat, lng: p.lng, altitude: p.altitude),
];

/// LA CONVERSION des points du trace vers la geometrie du calcul.
List<StatsPoint> _geometryOfTrace(List<TrackPoint> points) => [
  for (final p in points) (lat: p.lat, lng: p.lng, altitude: p.altitude),
];

/// La projection d'un releve sur le trace, cherchee sur TOUT le trace : sans
/// index connu, [TrackProjector.project] ne se limite a aucune fenetre.
TrackProjection _projectionOf(SessionTrackPoint reading, List<TrackPoint> t) =>
    TrackProjector.project(
      userLat: reading.lat,
      userLng: reading.lng,
      trackPoints: t,
    );
