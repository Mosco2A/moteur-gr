/// La fiche d'un sentier, lue une fois dans ses assets — absente plutot
/// qu'inventee.
library;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/trail_catalog.dart';
import '../../../core/models/fiche_de_sentier.dart';

/// Le paquet d'assets ou la fiche est lue.
///
/// Surchargeable POUR LES TESTS, et c'est la seule raison de son existence :
/// un test de widget n'a pas les assets de l'application sous la main, et il ne
/// doit pas avoir a en fabriquer pour verifier qu'une fiche s'affiche.
final paquetDAssetsProvider = Provider<AssetBundle>((ref) => rootBundle);

/// LA FICHE D'UN SENTIER, OU `null` — ET `null` EST UN ETAT NORMAL.
///
/// POURQUOI CE PROVIDER NE LEVE JAMAIS. Un sentier sans fiche, un manifeste
/// absent du binaire, un JSON mal forme : dans les trois cas la fiche vaut
/// `null` et l'ecran n'affiche simplement AUCUNE section. C'est la quatrieme
/// demande de la tache 846 — « l'application se comporte proprement quand un
/// sentier n'a ni photo ni description : pas de trou, pas de point
/// d'interrogation, pas de cadre vide ». Un `AsyncValue.error` aurait produit
/// exactement le contraire : un bandeau rouge sur la fiche d'un sentier dont
/// tout le reste va bien.
///
/// POURQUOI IL NE LIT AUCUN PROVIDER GLOBAL, ET CE N'EST PAS UN DETAIL. Il
/// prend son sentier en PARAMETRE et resout sa configuration par le catalogue
/// (statique), sans jamais consulter le sentier ACTIF. C'est la lecon mesuree
/// par les taches 796 et 841 : une famille de providers par sentier qui lit une
/// source du sentier actif garde en vie l'element du sentier precedent, lequel
/// s'invalide en pleine phase de build. Ici, l'element `gr20` ne depend que de
/// `gr20`.
final ficheDeSentierProvider = FutureProvider.family<FicheDeSentier?, String>((
  ref,
  trailId,
) async {
  final chemin = TrailCatalog.byId(trailId)?.ficheAssetPath;
  if (chemin == null || chemin.isEmpty) return null;

  final paquet = ref.watch(paquetDAssetsProvider);
  final String contenu;
  try {
    contenu = await paquet.loadString(chemin);
  } catch (_) {
    // MANIFESTE ABSENT DU BINAIRE : le sentier n'a pas de fiche, point. Ce
    // n'est pas une panne a montrer au randonneur.
    //
    // LA CLAUSE EST LARGE PARCE QUE LE PAQUET D'ASSETS LEVE UNE `Error`, PAS
    // UNE `Exception` : pour un asset introuvable, Flutter leve un
    // `FlutterError` (« Unable to load asset »), qui descend d'`Error` et
    // qu'un `on Exception` laisserait donc passer jusqu'a l'ecran. Mesure
    // faite : c'est ce qui se produit pour un sentier declarant une fiche que
    // le binaire ne porte pas.
    return null;
  }

  final fiche = lireFicheDeSentier(contenu, trailId);
  if (fiche == null || fiche.estVide) return null;
  return fiche;
});
