/// LES CHARNIERES DU TRACE (lot 671-04) : les endroits ou le randonneur se
/// trompe de chemin, CALCULES sur la geometrie du trace, et les FENETRES ou
/// le GPS se recale plus souvent autour d'elles.
///
/// DE LA GEOMETRIE ET RIEN D'AUTRE. Ce fichier n'importe ni Flutter, ni
/// greffon, ni feature : il est lu par l'isolate de l'interface (qui calcule
/// la liste une fois, au chargement du sentier) ET par celui de fond (qui y
/// compare l'abscisse du randonneur), et une garde structurelle le verifie.
///
/// TOUT SE MESURE EN DISTANCE SUR LE TRACE, JAMAIS A VOL D'OISEAU. Sur un
/// lacet, deux points du sentier peuvent etre a trente metres l'un de l'autre
/// a vol d'oiseau et a huit cents metres l'un de l'autre sur le chemin : une
/// fenetre mesuree a vol d'oiseau tirerait sur le mauvais brin. C'est pour
/// cela que ce lot vient apres le lot 671-03, qui a pose l'abscisse
/// ([TrackProjector.locate]).
library;

import 'geo_utils.dart';
import 'trace_point.dart';
import 'track_projection.dart';

/// LE SEUIL DE CAP : un point est une charniere si le cap du sentier y change
/// de PLUS de 50 degres (strictement) sur [kVoisinageDeCapMetres] de part et
/// d'autre. Un virage de 40 degres se suit sans y penser ; un virage de 60
/// degres est celui ou l'on rate l'embranchement.
const double kSeuilDeCapDegres = 50.0;

/// LE VOISINAGE DU CAP : 40 metres de part et d'autre du point, mesures EN
/// DISTANCE SUR LE TRACE (abscisse), jamais en nombre de points.
///
/// POURQUOI EN METRES ET PAS EN POINTS. Un trace est echantillonne de facon
/// irreguliere : quarante metres valent deux points en montagne et quinze
/// points en ville. Compter des points donnerait une charniere differente
/// selon le sentier pour un meme virage ; compter des metres, non.
const double kVoisinageDeCapMetres = 40.0;

/// La fenetre s'ouvre 150 metres AVANT une charniere, sur le trace.
const double kFenetreAvantMetres = 150.0;

/// La fenetre se ferme 150 metres APRES une charniere, sur le trace.
const double kFenetreApresMetres = 150.0;

/// LA PERIODE DES TIRS DANS UNE FENETRE : un tir immediat a l'entree, puis un
/// toutes les 30 secondes jusqu'a la sortie.
///
/// L'ARITHMETIQUE DU COUT, A 4 km/h ET 3 MINUTES DE CADENCE. Le randonneur
/// avance de 200 m en 3 minutes, et une fenetre isolee de 300 m se traverse en
/// 4 min 30 : NEUF tirs a 30 s (le tir d'entree compris), contre UN ET DEMI que
/// la cadence periodique aurait donnes. La fenetre multiplie le cout par six
/// pendant qu'elle dure. Et comme l'intervalle periodique (200 m) est plus
/// court que la fenetre (300 m), le releve periodique tombe presque toujours
/// DEDANS : les tirs de fenetre le REMPLACENT, ils ne s'y ajoutent pas.
const Duration kPeriodeDansLaFenetre = Duration(seconds: 30);

/// En deca de cette longueur, une corde n'a pas de cap : deux points
/// dupliques du GPX, ou un trace degenere.
const double _cordeSansCapMetres = 0.01;

/// La difference de deux caps ([depuis] puis [vers], en degres), RAMENEE dans
/// l'intervalle ]-180, 180] : positive a droite, negative a gauche.
///
/// C'EST L'ERREUR CLASSIQUE, ET ELLE REND LA FONCTION FAUSSE EXACTEMENT LA OU
/// ELLE DOIT ETRE JUSTE : sans cette normalisation, passer de 350 a 40 degres
/// vaudrait 310 degres au lieu de 50, et un virage de dix degres qui franchit
/// le nord deviendrait une epingle.
double ecartDeCaps(double depuis, double vers) {
  final brut = (vers - depuis) % 360.0;
  return brut > 180.0 ? brut - 360.0 : brut;
}

/// Un endroit du trace ou l'on se trompe de chemin.
class Charniere {
  /// Une charniere CALCULEE, de virage [virageDegres].
  const Charniere({
    required this.abscisseM,
    required this.lat,
    required this.lng,
    required this.virageDegres,
  }) : enrichie = false;

  /// Une charniere venue d'une DONNEE (une jonction declaree), deja projetee
  /// sur le trace : elle n'a pas de virage mesure.
  const Charniere.enrichie({
    required this.abscisseM,
    required this.lat,
    required this.lng,
  }) : virageDegres = null,
       enrichie = true;

  /// Distance depuis le depart du trace, en metres.
  final double abscisseM;

  /// Latitude du point du trace.
  final double lat;

  /// Longitude du point du trace.
  final double lng;

  /// Le changement de cap mesure, en degres (signe : droite positive) ; nul
  /// pour une charniere enrichie.
  final double? virageDegres;

  /// Vrai si la charniere vient d'une donnee et non de la geometrie.
  final bool enrichie;
}

/// Un INTERVALLE D'ABSCISSES ou le GPS se recale toutes les
/// [kPeriodeDansLaFenetre], et les charnieres qui l'ont ouvert.
class FenetreDeCharniere {
  /// Une fenetre de [debutM] a [finM].
  const FenetreDeCharniere({
    required this.debutM,
    required this.finM,
    required this.charnieres,
  });

  /// Abscisse d'entree, en metres.
  final double debutM;

  /// Abscisse de sortie, en metres.
  final double finM;

  /// Les charnieres de la fenetre : plusieurs quand des fenetres se
  /// recouvraient et ont ete fusionnees.
  final List<Charniere> charnieres;

  /// La largeur de la fenetre, en metres de trace.
  double get largeurM => finM - debutM;
}

/// LES CHARNIERES CALCULEES DE [trace], plus les [enrichies] (deja projetees),
/// triees par abscisse.
///
/// LA DEFINITION, GEOMETRIQUE. Pour chaque point du trace, on prend le point
/// du trace situe [kVoisinageDeCapMetres] EN AMONT sur l'abscisse et celui
/// situe autant EN AVAL ([TrackProjector.locate]) ; on compare le cap de la
/// corde amont -> point au cap de la corde point -> aval. Au-dela de
/// [kSeuilDeCapDegres], le point est candidat.
///
/// UN VIRAGE, UNE CHARNIERE. Sur un trace dense, les points voisins d'un
/// virage le voient aussi, en plus doux : parmi les candidats a moins de
/// [kVoisinageDeCapMetres] les uns des autres, seul garde le plus fort virage
/// (a egalite, le premier). Deux epingles d'un lacet separees de plus de
/// 40 m restent DEUX charnieres : leurs fenetres fusionnent ailleurs
/// ([fenetresDesCharnieres]), on ne filtre pas ici ce qui se regle la-bas.
///
/// LES CAS LIMITES, UN PAR UN :
/// - moins de 2 points : REFUSE ([ArgumentError]), comme
///   [TrackProjector.project] ;
/// - trace plus court que deux voisinages (80 m) : liste VIDE, sans erreur —
///   la mesure ne tient pas ;
/// - les 40 premiers et les 40 derniers metres ne portent AUCUNE charniere :
///   ils n'ont pas de voisinage amont, ou pas d'aval ;
/// - deux points DUPLIQUES (segment de longueur nulle) : le doublon est
///   enjambe, et une corde sans longueur n'a pas de cap — aucune division ;
/// - un trace qui se replie sur lui-meme (aller-retour) : les deux passages
///   sont a des abscisses differentes, donc deux endroits differents.
///
/// En O(n) sur le trace (chaque point fait deux recherches dichotomiques) :
/// calcule UNE fois au chargement du sentier, jamais a chaque position.
List<Charniere> charnieresDuTrace(
  List<TrackPoint> trace, {
  List<Charniere> enrichies = const [],
}) {
  if (trace.length < 2) {
    throw ArgumentError(
      'Le tracé doit contenir au moins 2 points (reçu: ${trace.length}).',
    );
  }
  final longueur = trace.last.distanceFromStart;
  final candidats = <Charniere>[];
  if (longueur >= 2 * kVoisinageDeCapMetres) {
    for (var i = 0; i < trace.length; i++) {
      final p = trace[i];
      final d = p.distanceFromStart;
      if (d < kVoisinageDeCapMetres || d > longueur - kVoisinageDeCapMetres) {
        continue;
      }
      // Un doublon du GPX est le meme endroit que son predecesseur.
      if (i > 0 && trace[i - 1].distanceFromStart == d) continue;
      final virage = _virageAu(trace, p);
      if (virage != null && virage.abs() > kSeuilDeCapDegres) {
        candidats.add(
          Charniere(abscisseM: d, lat: p.lat, lng: p.lng, virageDegres: virage),
        );
      }
    }
  }
  return [..._unParVirage(candidats), ...enrichies]
    ..sort((a, b) => a.abscisseM.compareTo(b.abscisseM));
}

/// Le virage au point [p] du trace, nul si une corde n'a pas de cap.
double? _virageAu(List<TrackPoint> trace, TrackPoint p) {
  final amont = TrackProjector.locate(
    trackPoints: trace,
    distanceFromStartM: p.distanceFromStart - kVoisinageDeCapMetres,
  );
  final aval = TrackProjector.locate(
    trackPoints: trace,
    distanceFromStartM: p.distanceFromStart + kVoisinageDeCapMetres,
  );
  if (GeoUtils.haversineDistance(amont.lat, amont.lng, p.lat, p.lng) <
          _cordeSansCapMetres ||
      GeoUtils.haversineDistance(p.lat, p.lng, aval.lat, aval.lng) <
          _cordeSansCapMetres) {
    return null;
  }
  return ecartDeCaps(
    GeoUtils.bearing(amont.lat, amont.lng, p.lat, p.lng),
    GeoUtils.bearing(p.lat, p.lng, aval.lat, aval.lng),
  );
}

/// Garde, parmi des candidats tries par abscisse, ceux dont aucun voisin a
/// moins de [kVoisinageDeCapMetres] ne tourne plus fort (a egalite, le
/// premier).
List<Charniere> _unParVirage(List<Charniere> candidats) => [
  for (var i = 0; i < candidats.length; i++)
    if (_estLePlusFort(candidats, i)) candidats[i],
];

bool _estLePlusFort(List<Charniere> candidats, int i) {
  final c = candidats[i];
  final force = c.virageDegres!.abs();
  for (var j = i - 1; j >= 0; j--) {
    final v = candidats[j];
    if (c.abscisseM - v.abscisseM >= kVoisinageDeCapMetres) break;
    if (v.virageDegres!.abs() >= force) return false;
  }
  for (var j = i + 1; j < candidats.length; j++) {
    final v = candidats[j];
    if (v.abscisseM - c.abscisseM >= kVoisinageDeCapMetres) break;
    if (v.virageDegres!.abs() > force) return false;
  }
  return true;
}

/// LES FENETRES DES [charnieres] (triees par abscisse) sur un trace de
/// [longueurM] metres : [kFenetreAvantMetres] avant, [kFenetreApresMetres]
/// apres, bornees au trace, et FUSIONNEES quand elles se recouvrent ou se
/// touchent.
///
/// LA FUSION EST LA REPONSE AU LACET. Cinq epingles separees de 80 m donnent
/// cinq fenetres de 300 m qui se recouvrent : elles n'en font qu'UNE, de
/// 4 x 80 + 300 = 620 m, et non cinq qui se repetent. Sans elle, on tirerait
/// cinq fois plus souvent la ou les fenetres sont deja les plus bavardes.
List<FenetreDeCharniere> fenetresDesCharnieres(
  List<Charniere> charnieres, {
  required double longueurM,
}) {
  final fenetres = <FenetreDeCharniere>[];
  for (final c in charnieres) {
    final debut = (c.abscisseM - kFenetreAvantMetres).clamp(0.0, longueurM);
    final fin = (c.abscisseM + kFenetreApresMetres).clamp(0.0, longueurM);
    final derniere = fenetres.isEmpty ? null : fenetres.last;
    if (derniere != null && debut <= derniere.finM) {
      fenetres.last = FenetreDeCharniere(
        debutM: derniere.debutM,
        finM: fin > derniere.finM ? fin : derniere.finM,
        charnieres: [...derniere.charnieres, c],
      );
    } else {
      fenetres.add(
        FenetreDeCharniere(debutM: debut, finM: fin, charnieres: [c]),
      );
    }
  }
  return fenetres;
}

/// LA FENETRE OU SE TROUVE [point], nulle hors de toute fenetre.
///
/// UNE COMPARAISON DE DEUX NOMBRES, ET RIEN D'AUTRE : l'abscisse du point
/// contre les bornes de chaque fenetre. Pas de distance geodesique, pas de
/// geometrie a chaque position. Les coordonnees du point ne servent pas, et
/// c'est voulu : a vol d'oiseau, le brin voisin d'un lacet serait « dans » la
/// fenetre.
FenetreDeCharniere? fenetreOu(
  List<FenetreDeCharniere> fenetres,
  TrackAbscissa point,
) {
  final x = point.distanceFromStartM;
  for (final f in fenetres) {
    if (x < f.debutM) return null;
    if (x <= f.finM) return f;
  }
  return null;
}
