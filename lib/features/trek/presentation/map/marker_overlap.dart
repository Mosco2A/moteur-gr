import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// QUAND DEUX REPERES DE LA CARTE DESIGNENT LE MEME LIEU (tache 571).
///
/// Retour de Chris en testant l'appli, mot pour mot : « 14rando les numeros
/// d'etapes son caches par les refucge, il ne faut pas que les icones se
/// superposent ».
///
/// LE DEFAUT EST STRUCTUREL, PAS ACCIDENTEL. Une etape se TERMINE a un
/// hebergement et la suivante en REPART : le marqueur de numero d'etape et le
/// marqueur du refuge sont au MEME point geographique par construction. Sur les
/// donnees reelles du Mare a Mare Centre, le depart de l'etape 3 et le « Gite
/// d etape de Cozzano » sont a 0,0 m l'un de l'autre, au chiffre pres. Et le
/// couple etape / refuge n'est pas le seul : l'epicerie de Cozzano est a 37 m
/// du gite, les sources thermales de Guitera a 33 m du depart de l'etape 4, la
/// fontaine de Guitera a 41 m du gite voisin.
///
/// CE QUE CE MODULE FAIT, ET CE QU'IL SE REFUSE A FAIRE :
///  * il DECIDE, a un zoom donne, quels reperes sont indistinguables a l'ecran
///    et doivent donc n'en former qu'UN SEUL ;
///  * il ne DEPLACE jamais rien. Un decalage de quelques pixels ferait mentir
///    la position sur une carte, et se reformerait de toute facon a un autre
///    zoom. Le repere d'un groupe est pose sur la position EXACTE de son
///    ancre — une position reelle, jamais un centroide invente.
///
/// LE CRITERE EST GEOMETRIQUE ET IL TIENT A TOUS LES ZOOMS : on convertit
/// l'ecart en METRES entre deux points en ECART EN PIXELS au zoom courant, et
/// on fusionne quand les deux disques se touchent. Consequence directe : deux
/// points a 0 m restent fusionnes a n'importe quel zoom (aucun zoom ne peut
/// les separer, c'est le meme lieu), tandis que deux points a 37 m se separent
/// des que le zoom les rend distinguables.
///
/// POURQUOI PAS [MarkerClusterer] (marker_cluster.dart), QUI EXISTE DEJA :
/// quatre raisons, chacune suffisante.
///  1. Il ne s'active qu'AU-DELA de 50 marqueurs ; le probleme de Chris se
///     produit avec 7 etapes et 20 points d'interet.
///  2. Il travaille COUCHE PAR COUCHE ; ici il faut regrouper des reperes de
///     natures differentes, qui vivaient dans deux couches empilees.
///  3. Sa grille rate les couples a cheval sur une frontiere de cellule : deux
///     points a 1 m de distance mais de part et d'autre d'une bordure ne sont
///     PAS regroupes. Or notre cas est precisement celui des points confondus.
///  4. Il pose la bulle sur le CENTROIDE des membres, donc il deplace le
///     repere. Interdit ici.
/// Il reste en place pour ce qu'il sait faire : degrossir une carte a forte
/// densite. Ce module-ci repond a une autre question.
///
/// TOUT EST PUR ET SANS FLUTTER_MAP : la regle se teste sur des coordonnees
/// reelles du sentier, sans pomper un widget ni ouvrir une carte.

/// Largeur d'une tuile carto en pixels (OSM / slippy map standard).
const double _tileSizePx = 256.0;

/// Circonference equatoriale de la Terre, en metres (WGS 84).
const double _equatorialCircumferenceM = 40075016.686;

/// Metres parcourus par un degre de latitude (constant, contrairement a la
/// longitude). Sert au pre-filtre bon marche de [MarkerOverlap.groupByLocation].
const double _metersPerLatitudeDegree = 111320.0;

/// Un repere candidat a la pose sur la carte : une position, la place qu'il
/// prend a l'ecran, et la donnee metier qu'il porte.
@immutable
class MapMarkerCandidate<T> {
  const MapMarkerCandidate({
    required this.position,
    required this.diameterPx,
    required this.data,
  });

  /// Position geographique REELLE du repere. Jamais retouchee.
  final LatLng position;

  /// Diametre du repere a l'ecran, en pixels.
  ///
  /// L'appelant y met la taille du PLUS GRAND repere qu'il est susceptible de
  /// dessiner (un repere fusionne est plus gros qu'un repere seul) : la
  /// garantie de non-recouvrement tient alors quel que soit le rendu choisi.
  final double diameterPx;

  /// Donnee metier associee (etape, point d'interet...).
  final T data;
}

/// Un groupe de reperes qui designent le meme lieu au zoom considere.
///
/// [members] contient au moins un element et commence TOUJOURS par [anchor].
@immutable
class MapMarkerGroup<T> {
  const MapMarkerGroup({required this.anchor, required this.members});

  /// Le repere qui donne sa position au groupe.
  ///
  /// C'est le premier membre dans l'ordre de priorite fourni par l'appelant —
  /// pour la carte du sentier : l'etape avant les points d'interet, parce que
  /// le numero d'etape est le repere de parcours le plus utile.
  final MapMarkerCandidate<T> anchor;

  /// Tous les membres du groupe, [anchor] en tete.
  final List<MapMarkerCandidate<T>> members;

  /// Position a laquelle le repere du groupe est pose : celle de l'ancre,
  /// donc une position REELLE. Aucun centroide, aucun decalage.
  LatLng get position => anchor.position;

  /// Nombre de reperes reunis.
  int get count => members.length;

  /// Vrai quand plusieurs reperes ont ete reunis en un seul.
  bool get isMerged => members.length > 1;
}

/// La regle de recouvrement et de regroupement des reperes de la carte.
abstract final class MarkerOverlap {
  /// Calculateur de distance geodesique (haversine), partage.
  static const Distance _geo = Distance();

  /// METRES COUVERTS PAR UN PIXEL D'ECRAN, a [zoom] et a la latitude
  /// [latitudeDeg].
  ///
  /// Formule slippy map standard : une tuile de 256 px couvre
  /// `circonference * cos(latitude) / 2^zoom` metres. La latitude compte —
  /// a 42° de latitude (Corse), un pixel couvre 26 % de metres en moins qu'a
  /// l'equateur, et ignorer ce facteur ferait fusionner trop tard.
  static double metersPerPixel(double zoom, double latitudeDeg) {
    final z = zoom.clamp(0.0, 24.0);
    final latitudeFactor = math.cos(latitudeDeg * math.pi / 180.0).abs();
    return _equatorialCircumferenceM *
        latitudeFactor /
        (_tileSizePx * math.pow(2, z));
  }

  /// ECART ENTRE DEUX POSITIONS, EN PIXELS D'ECRAN, au zoom donne.
  ///
  /// La distance geographique est mesuree en metres (haversine) puis convertie
  /// a l'echelle du zoom. C'est ce nombre — et lui seul — qui dit si deux
  /// reperes se marchent dessus.
  static double screenGapPx(LatLng a, LatLng b, double zoom) {
    final meters = _geo.distance(a, b);
    if (meters == 0) return 0;
    final midLatitude = (a.latitude + b.latitude) / 2.0;
    final scale = metersPerPixel(zoom, midLatitude);
    if (scale <= 0) return double.infinity;
    return meters / scale;
  }

  /// Vrai quand les deux reperes se recouvrent a l'ecran, a [zoom].
  ///
  /// Les deux reperes sont des disques : ils se touchent des que l'ecart entre
  /// leurs centres descend sous la SOMME DE LEURS RAYONS.
  static bool overlapAtZoom<T>(
    MapMarkerCandidate<T> a,
    MapMarkerCandidate<T> b,
    double zoom,
  ) {
    return screenGapPx(a.position, b.position, zoom) <
        minimumGapPx(a.diameterPx, b.diameterPx);
  }

  /// Ecart minimal, en pixels, pour que deux disques de ces diametres ne se
  /// recouvrent pas : la somme de leurs rayons.
  static double minimumGapPx(double diameterA, double diameterB) =>
      (diameterA + diameterB) / 2.0;

  /// REGROUPE LES REPERES QUI DESIGNENT LE MEME LIEU A [zoom].
  ///
  /// ALGORITHME — regroupement AUTOUR D'UNE ANCRE, et le choix est deliberé :
  ///  * on parcourt [candidates] dans l'ordre de priorite recu ;
  ///  * le premier repere encore libre devient l'ANCRE d'un groupe ;
  ///  * tout repere encore libre qui recouvre CETTE ANCRE rejoint le groupe ;
  ///  * on recommence avec le premier repere restant.
  ///
  /// DEUX PROPRIETES EN DECOULENT, et ce sont elles qui reglent le probleme.
  ///  1. AUCUN COUPLE DE REPERES RENDUS NE SE RECOUVRE. Quand une ancre est
  ///     choisie, tout ce qui la recouvre est absorbe ; une ancre suivante ne
  ///     peut donc jamais recouvrir une ancre deja posee. C'est la garantie
  ///     verifiable a tous les zooms.
  ///  2. LE REPERE NE MENT PAS. Chaque membre est, par construction, a moins
  ///     d'un rayon de l'ancre : le repere pose couvre donc a l'ecran la
  ///     position reelle de chacun de ses membres.
  ///
  /// CE QU'ON N'A PAS FAIT, ET POURQUOI : le regroupement par chaine (A avec
  /// B, B avec C, donc A avec C) reunirait des points que l'ancre ne couvre
  /// pas. A Guitera, la chaine depart d'etape -> sources -> gite -> fontaine
  /// mettrait la fontaine a 82 m de l'ancre, soit 46 px a fort zoom : le
  /// repere mentirait sur sa position. Le regroupement autour d'une ancre
  /// l'interdit.
  ///
  /// Cout : O(n * k) en pratique grace au pre-filtre en latitude (une
  /// soustraction) qui ecarte la quasi-totalite des couples avant le calcul
  /// geodesique.
  static List<MapMarkerGroup<T>> groupByLocation<T>(
    List<MapMarkerCandidate<T>> candidates, {
    required double zoom,
  }) {
    final groups = <MapMarkerGroup<T>>[];
    final taken = List<bool>.filled(candidates.length, false);

    for (var i = 0; i < candidates.length; i++) {
      if (taken[i]) continue;
      final anchor = candidates[i];
      taken[i] = true;
      final members = <MapMarkerCandidate<T>>[anchor];

      // Ecart maximal, en metres, susceptible de produire un recouvrement
      // avec cette ancre. Sert de pre-filtre : au-dela, aucun calcul.
      final anchorScale = metersPerPixel(zoom, anchor.position.latitude);

      for (var j = i + 1; j < candidates.length; j++) {
        if (taken[j]) continue;
        final other = candidates[j];
        final maxGapM =
            minimumGapPx(anchor.diameterPx, other.diameterPx) * anchorScale;
        final latGapM =
            (anchor.position.latitude - other.position.latitude).abs() *
                _metersPerLatitudeDegree;
        if (latGapM > maxGapM) continue;
        if (overlapAtZoom(anchor, other, zoom)) {
          taken[j] = true;
          members.add(other);
        }
      }

      groups.add(MapMarkerGroup<T>(anchor: anchor, members: members));
    }

    return groups;
  }

  /// LE ZOOM A RETENIR QUAND ON NE CONNAIT QUE LA BANDE DE ZOOM ENTIERE.
  ///
  /// La carte ne notifie le zoom qu'ARRONDI a l'entier (cf. `map_screen`, qui
  /// s'en sert aussi pour la simplification de trace). La camera reelle est
  /// donc quelque part dans `[z - 0.5 ; z + 0.5[`. On evalue le regroupement
  /// au PLUS PETIT zoom de la bande : c'est le cote prudent — au plus petit
  /// zoom les points sont le plus serres, donc on fusionne un peu plus tot
  /// plutot que de laisser deux icones se marcher dessus a 16,4 en attendant
  /// l'arrondi a 17.
  static double lowestZoomOfBand(int roundedZoom) => roundedZoom - 0.5;
}
