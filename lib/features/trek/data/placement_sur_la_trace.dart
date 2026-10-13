/// LE PLACEMENT D'UN MARCHEUR SUR UNE TRACE CONNUE : le point situe a une
/// distance donnee du depart, interpole entre les deux points qui l'encadrent.
///
/// SORTI DE `marcheur_simule.dart` PAR SA PROPRE GARDE DE TAILLE (tache 744).
/// Ce fichier-la etait a 490 lignes pour un plafond de 500 (ECR-15,
/// `taille_et_rangement_645_test.dart`), et le message de la garde dit quoi
/// faire mot pour mot : « DECOUPEZ AVANT D AJOUTER ». Ajouter la reprise de
/// marche sans decouper aurait fait rougir la garde — et on n'assouplit pas
/// une garde pour se faire de la place. Cette fonction est le morceau le plus
/// facile a sortir : elle est PURE (une trace et une distance entrent, un
/// point sort), elle ne touche a aucun etat du marcheur, et elle se lit seule.
///
/// ELLE NE MESURE RIEN, ELLE PLACE. La distance cumulee est LUE sur la trace
/// (`distanceFromStart`), jamais recalculee : aucun cumul de distance, de
/// denivele ni de vitesse n'est ecrit ici. La garde du lot 742 qui interdit un
/// deuxieme moteur de calcul dans le marcheur a ete ETENDUE A CE FICHIER
/// (tache 744) : sortir du code d'un fichier garde ne doit pas le sortir de sa
/// garde. Les chiffres de l'ecran restent mesures par
/// `computeTrackStatsOnTrace` (lot 671-06).
library;

import '../../../core/geo/trace_point.dart';

/// LE POINT DE [trace] A [metres] DU DEPART, interpole entre ses deux points
/// encadrants.
///
/// La distance cumulee est LUE sur la trace (`distanceFromStart`), jamais
/// recalculee. L'interpolation est lineaire en latitude, longitude et
/// altitude : sur un segment de trace (quelques dizaines de metres) l'ecart
/// avec un trace de grand cercle est inferieur au millimetre, tres loin
/// devant la precision d'un GPS. Elle sert a FLUIDIFIER un deplacement, pas
/// a mesurer une distance.
///
/// Une trace vide rend le point d'origine : le marcheur refuse de partir sans
/// trace exploitable ([MarcheurSimule.demarrer]), donc ce cas ne se produit
/// pas en marche — il evite seulement un plantage a qui appellerait a vide.
TrackPoint pointSurLaTrace(List<TrackPoint> trace, double metres) {
  if (trace.isEmpty) {
    return const TrackPoint(lat: 0, lng: 0, altitude: 0, distanceFromStart: 0);
  }
  if (metres <= trace.first.distanceFromStart) return trace.first;
  if (metres >= trace.last.distanceFromStart) return trace.last;

  // Recherche dichotomique : la trace du Mare a Mare porte des milliers de
  // points et ce placement a lieu deux fois par seconde.
  var bas = 0;
  var haut = trace.length - 1;
  while (haut - bas > 1) {
    final milieu = (bas + haut) ~/ 2;
    if (trace[milieu].distanceFromStart <= metres) {
      bas = milieu;
    } else {
      haut = milieu;
    }
  }
  final a = trace[bas];
  final b = trace[haut];
  final longueur = b.distanceFromStart - a.distanceFromStart;
  final f = longueur <= 0
      ? 0.0
      : ((metres - a.distanceFromStart) / longueur).clamp(0.0, 1.0);
  return TrackPoint(
    lat: a.lat + (b.lat - a.lat) * f,
    lng: a.lng + (b.lng - a.lng) * f,
    altitude: a.altitude + (b.altitude - a.altitude) * f,
    distanceFromStart: metres,
  );
}

/// LE TEMPS DE MARCHE QU'IL FAUT POUR COUVRIR [metres] a [vitesseKmh]
/// (tache 747).
///
/// SORTI DU MARCHEUR PAR SA GARDE DE TAILLE, comme [pointSurLaTrace] l'avait
/// ete a la tache 744 — et il est a sa place ici : c'est du PLACEMENT, pas une
/// mesure. Aucun chiffre affiche n'en sort.
///
/// A QUOI IL SERT. Le saut d'etape de la demonstration (`MarcheurSimule.allerA`)
/// deplace le marcheur de plusieurs kilometres d'un coup. Si l'horloge de la
/// marche ne suivait pas, le moteur de statistiques — qui divise la distance
/// par l'ecart des horodatages — annoncerait une vitesse moyenne absurde. On
/// avance donc l'horloge du temps qu'il aurait fallu pour marcher la distance.
///
/// Une distance nulle ou negative ne coute aucun temps, et une vitesse nulle ou
/// negative non plus : on ne fabrique pas une duree infinie.
Duration tempsDeMarchePour(double metres, double vitesseKmh) {
  if (metres <= 0 || vitesseKmh <= 0) return Duration.zero;
  final secondes = metres / (vitesseKmh / 3.6);
  return Duration(milliseconds: (secondes * 1000).round());
}
