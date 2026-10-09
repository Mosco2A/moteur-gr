/// Le cadrage d'ouverture de la carte, calcule AVANT la premiere image.
///
/// Bibliotheque de l'ecran `map_screen.dart` (tache 758).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Le centre et le zoom sur lesquels la carte doit S'OUVRIR.
typedef CadrageDOuverture = ({LatLng centre, double zoom});

/// Le cadrage d'ouverture pour [cible], avec [marge] de respiration, dans un
/// cadre de [taille].
///
/// POURQUOI LE CALCULER NOUS-MEMES (tache 758). `flutter_map` sait le faire —
/// c'est `CameraFit.fit` — mais il ne l'applique qu'une fois la carte batie,
/// dans un POST-FRAME, et seulement si la taille du cadre a CHANGE pendant
/// cette frame. D'ici la, la couche de tuiles a deja demande une pleine
/// fournee de tuiles au zoom par DEFAUT (13), pour une vue que personne ne
/// verra.
///
/// CE QUE CELA COUTAIT, MESURE SUR L'EMULATEUR LE 09/10 : 80 tuiles de zoom
/// 13 demandees en 72 millisecondes, puis les 90 vraies tuiles de zoom 12
/// mises en file DERRIERE elles sur le meme client HTTP, et 37 SECONDES sans
/// la moindre demande nouvelle. Le fond restait gris pres de cinq minutes.
///
/// On emprunte donc a `flutter_map` son propre calcul, sur une camera de meme
/// taille, et on lui rend le resultat comme camera de DEPART : il n'a plus
/// rien a corriger, et aucune tuile n'est demandee pour rien.
///
/// REPLI EXPLICITE, JAMAIS D'EXCEPTION. Taille pas encore connue, ou trace
/// reduite a un point — des bornes d'aire nulle donnent un zoom infini, que le
/// constructeur de [MapCamera] refuse : on garde le centre et un zoom
/// raisonnable, et `initialCameraFit` reprend la main. Une carte approximative
/// vaut mieux qu'un ecran en erreur.
CadrageDOuverture cadrageDOuverture(
  LatLngBounds cible,
  double marge,
  Size taille,
) {
  const zoomDeRepli = 13.0;
  if (taille.isEmpty || !taille.width.isFinite || !taille.height.isFinite) {
    return (centre: cible.center, zoom: zoomDeRepli);
  }
  try {
    final ajustee =
        CameraFit.bounds(bounds: cible, padding: EdgeInsets.all(marge)).fit(
          MapCamera(
            crs: const Epsg3857(),
            center: cible.center,
            zoom: zoomDeRepli,
            rotation: 0,
            nonRotatedSize: taille,
          ),
        );
    if (!ajustee.zoom.isFinite) {
      return (centre: cible.center, zoom: zoomDeRepli);
    }
    return (centre: ajustee.center, zoom: ajustee.zoom);
  } catch (_) {
    // Le cadrage est un confort, pas une fonction vitale : s'il echoue, la
    // carte s'ouvre quand meme, et `initialCameraFit` corrigera.
    return (centre: cible.center, zoom: zoomDeRepli);
  }
}
