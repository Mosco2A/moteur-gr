/// Les chiffres de la rando EN COURS, calcules SUR LE TRACE parcouru depuis
/// le lot 671-06, dates par la seule source reellement alimentee : les
/// releves persistes (TrekStats.addPoint n'a aucun appelant).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/geo/recorded_track_stats.dart';
import '../../../core/geo/track_segment_stats.dart';
import '../../map/map_facade.dart'
    show currentPositionProvider, statsTraceProvider, trackPositionProvider;
import '../data/source_des_releves.dart';
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
/// [computeTrackStatsOn], deja utilise par le journal (L4-3) et par le
/// recapitulatif d'aventure (L5-5, L5-6). Un deuxieme calcul finirait par
/// donner deux deniveles differents pour la meme journee.
///
/// LOT 671-06 — LA GEOMETRIE VIENT DU TRACE, LE TEMPS DES RELEVES. La
/// distance et le denivele se mesurent sur la tranche du sentier entre le
/// premier releve reel de la session, projete, et la POSITION COURANTE sur le
/// trace ; la duree reste l'ecart entre le premier et le dernier releve reel,
/// a la seconde pres la valeur d'avant (cf. [computeTrackStatsOnTrace]). LE
/// PERIMETRE NE CHANGE PAS : c'est toujours TOUTE la session, pas la journee.
///
/// RAFRAICHISSEMENT : le provider se recalcule quand la position projetee
/// change, c'est-a-dire au rythme des points GPS. DETTE ASSUMEE : chaque
/// rafraichissement relit les releves de la session (quelques centaines de
/// lignes SQLite en fin de journee, des milliers en profil carte) et projette
/// le premier sur tout le trace. Mesure avant optimisation : tant que la
/// barre reste fluide, un cumul incremental en memoire serait un SECOND
/// moteur de calcul, donc un risque de divergence pour un gain non mesure.
final liveTrekStatsProvider = FutureProvider<TrackSegmentStats>((ref) async {
  final session = ref.watch(
    trekSessionManagerProvider.select((s) => s.session),
  );
  final status = ref.watch(trekSessionManagerProvider.select((s) => s.status));
  final enCours =
      status == TrackingSessionStatus.recording ||
      status == TrackingSessionStatus.paused;
  if (!enCours || session == null) return const TrackSegmentStats();

  // Rythme le recalcul sur les points GPS (meme source que la barre d'etape),
  // et porte la borne de fin : l'abscisse courante sur le trace.
  final position = ref.watch(trackPositionProvider).value;
  final trace = ref.watch(statsTraceProvider.future);

  // LES SEULS RELEVES REELS (lot 671-03) : ils bornent et datent la tranche.
  // Un point estime ne date rien et ne borne rien ; la geometrie, elle, vient
  // du trace (lot 671-06).
  //
  // TACHE 742 — LA BASE EN VRAI, LA MEMOIRE EN DEMO, ET RIEN D'AUTRE NE CHANGE.
  // Cette lecture allait droit au DAO ; en demo la table reste vide (tache 634,
  // « rien en base »), donc `hasData` etait faux et la barre de la carte
  // affichait Parcouru « -- », Vit. moy. « -- », D+ « -- » quelle que soit la
  // distance marchee. [SourceDesReleves] choisit D'OU viennent les releves — la
  // base, ou la memoire du marcheur simule. LA SUITE EST IDENTIQUE : le meme
  // [computeTrackStatsOnTrace], le meme trace, la meme borne de fin. Meme
  // fonction de statistiques, entree differente.
  final readings = await ref
      .watch(sourceDesRelevesProvider)
      .parSession(session.id, read: TrackPointsRead.gpsOnly);
  return computeTrackStatsOnTrace(
    readings: readings,
    trace: await trace,
    currentDistanceM: position?.distanceFromStartM,
  );
});

/// Altitude courante en metres, `null` sans fix GPS exploitable (L6-2).
///
/// Vient de la position elle-meme et non de la trace : c'est l'altitude OU SE
/// TROUVE le randonneur maintenant, pas le point le plus haut de sa journee.
/// Les deux chiffres sont differents et le second ne repond pas a la question
/// « je suis a quelle altitude ». Un fix sans altitude renvoie exactement 0 :
/// ne rien montrer vaut mieux qu'un « 0 m » faux en pleine montagne.
///
/// LOT 671-03 : la POSITION COURANTE, releve ou point estime ; entre deux
/// releves des profils batterie, l'altitude est celle du trace sous le point
/// estime, plus fraiche que celle d'un releve vieux de trois minutes.
final currentAltitudeProvider = Provider<double?>((ref) {
  final position = ref.watch(currentPositionProvider).value;
  if (position == null) return null;
  final alt = position.altitude;
  if (alt == 0) return null;
  return alt;
});
