/// Le profil d'un sentier, lu UNE FOIS dans sa trace — absent plutot
/// qu'invente.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_catalog.dart';
import '../../../core/geo/gpx_depuis_les_assets.dart';
import '../../../domain/profil_du_terrain.dart';
import 'fiche_de_sentier_provider.dart' show paquetDAssetsProvider;

/// LE PROFIL DU TERRAIN D'UN SENTIER DESIGNE (tache 858).
///
/// POURQUOI LA FICHE A BESOIN DE LA TRACE ENTIERE ET PLUS DE TROIS TOTAUX.
/// L'indice de terrain est une integrale sur le profil : deux journees de meme
/// distance et meme denivele n'ont pas le meme indice si l'une monte d'un trait
/// ce que l'autre monte en quatre fois. La fiche lit donc la trace du sentier —
/// celle qui est DEJA dans le binaire et qui produit deja le denivele
/// affiche — et en tire le profil une seule fois.
///
/// POURQUOI IL NE LIT AUCUN PROVIDER DU SENTIER ACTIF. Il prend son sentier en
/// PARAMETRE et resout sa configuration par le catalogue, qui est statique :
/// c'est la lecon mesuree des taches 796 et 841 (une famille par sentier qui
/// lit une source du sentier actif garde en vie l'element du sentier precedent,
/// lequel s'invalide en pleine phase de build). C'est aussi la forme de
/// `ficheDeSentierProvider`, dont il reprend le paquet d'assets surchargeable
/// pour les tests.
///
/// REPLI GRACIEUX ASSUME. Trace absente du binaire, GPX illisible, sentier
/// inconnu du catalogue : le profil vaut [ProfilDuTerrain.vide] et la fiche
/// ANNONCE la mesure manquante au lieu d'afficher un nombre construit sur
/// rien. Un enrichissement qui casse l'ecran quand il manque n'en est pas un.
final profilDuTerrainProvider = FutureProvider.family<ProfilDuTerrain, String>((
  ref,
  trailId,
) async {
  final chemin = TrailCatalog.byId(trailId)?.gpxAssetPath;
  if (chemin == null || chemin.isEmpty) return ProfilDuTerrain.vide;

  final paquet = ref.watch(paquetDAssetsProvider);
  final String contenu;
  try {
    contenu = await paquet.loadString(chemin);
  } catch (_) {
    // LA CLAUSE EST LARGE PARCE QUE LE PAQUET D'ASSETS LEVE UNE `Error`, PAS
    // UNE `Exception` : un asset introuvable leve un `FlutterError`, qu'un
    // `on Exception` laisserait passer jusqu'a l'ecran.
    return ProfilDuTerrain.vide;
  }

  try {
    final points = GpxDepuisLesAssets.parseFromString(contenu);
    if (points.length < 2) return ProfilDuTerrain.vide;
    return ProfilDuTerrain.depuisLaTrace(
      distancesM: points
          .map((point) => point.distanceFromStart)
          .toList(growable: false),
      altitudesM: points.map((point) => point.altitude).toList(growable: false),
    );
  } catch (_) {
    return ProfilDuTerrain.vide;
  }
});

/// Le profil charge, ou VIDE tant qu'il ne l'est pas — jamais d'attente
/// bloquante : la fiche s'affiche, puis s'enrichit de son indice.
final profilDuSentierProvider = Provider.family<ProfilDuTerrain, String>((
  ref,
  trailId,
) {
  return ref
      .watch(profilDuTerrainProvider(trailId))
      .maybeWhen(data: (profil) => profil, orElse: () => ProfilDuTerrain.vide);
});
