/// L'entree du moteur de chiffres par les points enregistres tels quels (lot
/// 671-06) : un seul calcul derriere elle, [computeTrackStatsOn].
library;

import '../data/database.dart';
import 'track_segment_stats.dart';

/// Les chiffres d'une suite de POINTS ENREGISTRES, leur geometrie telle
/// quelle : la surcharge d'adaptation de [computeTrackStatsOn].
///
/// ELLE CONVERTIT, ELLE NE CALCULE RIEN. Le resultat est celui d'avant le lot
/// 671-06 au metre et a la seconde : meme boucle, memes points, et la duree
/// est l'ecart entre le premier et le dernier point, comme la fonction la
/// calculait elle-meme.
TrackSegmentStats computeTrackStats(List<SessionTrackPoint> points) =>
    computeTrackStatsOn(
      _geometryOfReadings(points),
      duration: _durationOfReadings(points),
    );

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
