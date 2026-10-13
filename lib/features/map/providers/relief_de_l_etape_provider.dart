/// LE DENIVELE DE L'ETAPE EN COURS — celui de la tranche deja marchee, et de
/// rien d'autre (tache 762).
///
/// DECISION DE CHRISTOPHE DU 09/10 16:29, mot pour mot : « En sentier entier
/// l altitude pure n a plus lieue d etre et le denivele + et - doit etre le
/// total depuis le debut et en mode sentier celui de l etape, a revoir ».
///
/// CE QUI ETAIT FAUX, ET LA TACHE 747 LE DISAIT DEJA TOUT HAUT. La barre
/// annonce un Total d'etape et un Parcouru d'etape, et posait a cote le
/// denivele de TOUTE LA SESSION — l'en-tete de `barre_d_etape.dart` l'ecrivait
/// noir sur blanc : « LE DENIVELE, LA VITESSE MOYENNE ET L'ALTITUDE NE SUIVENT
/// PAS LE PERIMETRE, ET C'EST DIT PLUTOT QUE CACHE ». C'etait une dette
/// assumee, pas un oubli ; Christophe l'a tranchee.
///
/// POURQUOI LA REPONSE N'EST PAS UN SECOND MOTEUR DE DENIVELE. Le lot 671-06 a
/// pose la regle qui interdit d'en ecrire un deuxieme : deux moteurs finissent
/// par donner deux deniveles differents pour la meme journee. Ce provider n'en
/// ecrit aucun — il appelle [reliefDeLaTranche], qui est le decoupage de
/// `TrackSlice.between` suivi de la boucle de `computeTrackStatsOn`, les deux
/// deja en service. MEME MOTEUR, AUTRES BORNES : deux abscisses au lieu de deux
/// releves projetes.
///
/// LE PERIMETRE EST « CE QUI EST DEJA MONTE DANS CETTE ETAPE », du debut de
/// l'etape a l'abscisse du marcheur — et non le relief total de l'etape. C'est
/// la symetrie exacte de la vue sentier, ou le D+ est ce qui est monte depuis
/// le depart : les deux colonnes de la barre disent une quantite ACCOMPLIE,
/// jamais un programme. Le marcheur qui vient d'entrer dans une etape voit donc
/// zero, ce qui est la verite.
///
/// CE QU'IL COUTE, ET IL EST DIT. La tranche change a chaque releve — deux fois
/// par seconde en demonstration — donc le decoupage est refait a chaque fois.
/// Sur la trace de demonstration (53 points) c'est gratuit ; sur un vrai
/// sentier de plusieurs dizaines de milliers de points, c'est un parcours
/// lineaire par releve. C'est l'ordre de grandeur que la mesure de la session
/// paie DEJA a chaque releve (une relecture SQLite et une projection sur toute
/// la trace, « DETTE ASSUMEE » de son en-tete) : ce provider n'ajoute donc pas
/// une classe de cout nouvelle. Mesurer avant d'optimiser reste la regle.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/recorded_track_stats.dart';
import '../../../core/geo/track_segment_stats.dart';
import '../domain/jalons_des_etapes.dart';
import 'gpx_track_provider.dart';
import 'track_position_provider.dart';

/// LE RELIEF DEJA MARCHE DANS L'ETAPE EN COURS.
///
/// `null` quand il n'y a rien a mesurer : pas de position sur la trace, pas
/// d'etapes chargees, ou trace indisponible. Un `null` fait afficher un tiret
/// par la barre — jamais un zero qui aurait l'air d'une mesure (regle du
/// correctif L5-6).
final reliefDeLEtapeProvider = Provider<TrackSegmentStats?>((ref) {
  final trailId = ref.watch(trailIdProvider);
  final abscisseM = ref.watch(trackPositionProvider).value?.distanceFromStartM;
  if (abscisseM == null) return null;

  final jalons = ref.watch(jalonsDesEtapesProvider(trailId));
  final jalon = jalonALAbscisse(jalons, abscisseM);
  if (jalon == null) return null;

  final trace = ref.watch(statsTraceProvider).value;
  if (trace == null) return null;

  return reliefDeLaTranche(trace: trace, debutM: jalon.debutM, finM: abscisseM);
});
