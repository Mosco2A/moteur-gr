import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/track_segment_stats.dart';
import '../../../core/providers/database_provider.dart';
import '../../map/providers/location_provider.dart';
import '../../map/providers/track_position_provider.dart';
import 'tracking_providers.dart';

/// Chiffres MESURES de la randonnee EN COURS (correctif L6-2).
///
/// POURQUOI PAS [trekStatsProvider] : la classe `TrekStats` sait tout
/// calculer, mais personne ne l'alimente — `TrekStats.addPoint` n'a AUCUN
/// appelant dans l'application (le constat etait deja ecrit noir sur blanc
/// dans `hub_trek_card.dart`, d'ou le « 0.0 km » vu en QA). Brancher la barre
/// de la carte dessus aurait affiche trois zeros bien alignes. La seule source
/// reellement alimentee pendant un trek est la TRACE PERSISTEE : le service de
/// fond ecrit chaque point dans `session_track_points`, avec sa session depuis
/// le socle L3-1.
///
/// AUCUN MOTEUR DE STATS N'EST RECRIT ICI : le calcul est celui de
/// [computeTrackStats], deja utilise par le journal (L4-3) et par le
/// recapitulatif d'aventure (L5-5, L5-6). Un deuxieme calcul finirait par
/// donner deux deniveles differents pour la meme journee.
///
/// RAFRAICHISSEMENT : le provider se recalcule quand la position projetee
/// change, c'est-a-dire au rythme des points GPS. DETTE ASSUMEE : chaque
/// rafraichissement relit les points de la session (quelques milliers de
/// lignes SQLite en fin de journee). Mesure avant optimisation : tant que la
/// barre reste fluide, un cumul incremental en memoire serait un SECOND
/// moteur de calcul, donc un risque de divergence pour un gain non mesure.
final liveTrekStatsProvider = FutureProvider<TrackSegmentStats>((ref) async {
  final session = ref.watch(
    trekSessionManagerProvider.select((s) => s.session),
  );
  final status = ref.watch(
    trekSessionManagerProvider.select((s) => s.status),
  );
  final enCours = status == TrackingSessionStatus.recording ||
      status == TrackingSessionStatus.paused;
  if (!enCours || session == null) return const TrackSegmentStats();

  // Rythme le recalcul sur les points GPS (meme source que la barre d'etape).
  ref.watch(trackPositionProvider);

  final db = ref.watch(databaseProvider);
  final points = await db.sessionTrackPointsDao.getBySessionId(session.id);
  return computeTrackStats(points);
});

/// Altitude courante en metres, `null` sans fix GPS exploitable (L6-2).
///
/// Vient de la position elle-meme et non de la trace : c'est l'altitude OU SE
/// TROUVE le randonneur maintenant, pas le point le plus haut de sa journee.
/// Les deux chiffres sont differents et le second ne repond pas a la question
/// « je suis a quelle altitude ». Un fix sans altitude renvoie exactement 0 :
/// ne rien montrer vaut mieux qu'un « 0 m » faux en pleine montagne.
final currentAltitudeProvider = Provider<double?>((ref) {
  final position = ref.watch(locationProvider).value;
  if (position == null) return null;
  final alt = position.altitude;
  if (alt == 0) return null;
  return alt;
});
