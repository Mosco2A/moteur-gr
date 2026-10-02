/// Limites appliquees a tout sentier non achete — carte visible, GPS coupe,
/// carnet en lecture seule — quel que soit le statut du compte.
library;

// E5.18 — Service mode demo universel.
//
// Le mode demo s'applique a TOUT trek non achete, quel que soit
// le statut de l'utilisateur. Un premium qui a achete un sentier
// voit les autres sentiers en mode demo, et inversement.
//
// Limites du mode demo :
// - Carte visible, GPS desactive
// - Journal en lecture seule (read-only)
// - Bandeau "Mode demo" affiche en haut de l'ecran
//
// AUCUNE EXEMPTION ICI, ET C'EST LE SUJET DE LA TACHE 601. Ce service portait
// une EXCEPTION VITRINE : un sentier marque `isShowcaseTrail` n'etait JAMAIS en
// mode demo, meme non achete. Ce drapeau avait ete invente pour corriger une
// divergence relevee par un audit de parite (#99433), puis attribue a Christophe
// dans un commentaire de code alors qu'AUCUNE decision ne le soutenait — et il a
// dit le 27/09 n'avoir jamais parle de sentier vitrine.
//
// LA DEMONSTRATION SE FAIT DESORMAIS SUR UN SENTIER GRATUIT DU CATALOGUE, dont le
// PRIX est nul. Il n'a besoin d'aucune exemption : il est jouable parce qu'il n'y
// a rien a payer. La difference n'est pas de forme — une exemption est un trou
// dans le modele, un sentier gratuit est une entree du modele. Ce service ne
// connait donc plus qu'une seule question : ce trek a-t-il ete debloque ?
//
// Source de verite : les droits de `MonetizationService` (via [demoResolver]),
// ou a defaut la liste legacy des trailId achetes en SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du mode demo universel.
///
/// Determine si un trek donne est en mode demo pour l'utilisateur
/// courant, en se basant sur la liste des achats (trailIds).
/// Un trek non achete = mode demo, quel que soit le statut premium.
class DemoModeService {
  DemoModeService({
    SharedPreferences? prefs,
    Future<bool> Function(String trailId)? demoResolver,
  }) : _prefs = prefs,
       _demoResolver = demoResolver;

  /// Instance SharedPreferences (injectee ou chargee au premier appel).
  SharedPreferences? _prefs;

  /// Delegue de reconciliation (StepWays LOT 1) : quand fourni, [isDemoModeAsync]
  /// derive l'etat demo de la SOURCE UNIQUE (`MonetizationService`, droits Drift)
  /// au lieu de la cle prefs legacy `purchased_trail_ids`. Cable par le provider ;
  /// null = comportement autonome historique (compat tests E5.18).
  final Future<bool> Function(String trailId)? _demoResolver;

  /// Cle SharedPreferences pour la liste des trailIds achetes.
  static const String _purchasedTrailsKey = 'purchased_trail_ids';

  /// Initialise le service (charge SharedPreferences si pas injecte).
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Retourne true si le trek [trailId] est en mode demo.
  ///
  /// Un trek est en mode demo s'il n'a PAS ete achete par
  /// l'utilisateur courant. Le statut premium n'entre pas en jeu :
  /// un premium voit tout sentier non achete en demo.
  ///
  /// AUCUNE EXEMPTION (tache 601) : la seule question est « ce trek est-il
  /// debloque ». Les sentiers GRATUITS ne passent pas par ici — ils sont
  /// resolus jouables par `MonetizationService.accessFor`, qui lit leur prix,
  /// et [isDemoModeAsync] delegue a cette source unique.
  bool isDemoMode(String trailId) {
    final purchased = _prefs?.getStringList(_purchasedTrailsKey) ?? [];
    return !purchased.contains(trailId);
  }

  /// Version RECONCILIEE (StepWays LOT 1) : delegue a la SOURCE UNIQUE quand un
  /// [_demoResolver] est cable (droits Drift de `MonetizationService`), sinon
  /// retombe sur [isDemoMode] (cle prefs legacy). Supprime le doublon d'achats :
  /// `DemoModeService` et `MonetizationService` renvoient le meme etat demo.
  ///
  /// Un SENTIER GRATUIT n'est jamais en mode demo — non par exemption posee ici,
  /// mais parce que la source unique le resout jouable (son prix est nul).
  Future<bool> isDemoModeAsync(String trailId) async {
    final resolver = _demoResolver;
    if (resolver != null) return resolver(trailId);
    return isDemoMode(trailId);
  }

  /// Enregistre un trail comme achete (sort du mode demo).
  ///
  /// Appele apres un achat valide confirme par le backend.
  Future<void> markAsPurchased(String trailId) async {
    await initialize();
    final purchased = _prefs?.getStringList(_purchasedTrailsKey) ?? [];
    if (!purchased.contains(trailId)) {
      purchased.add(trailId);
      await _prefs?.setStringList(_purchasedTrailsKey, purchased);
    }
  }

  /// Retourne la liste des trailIds achetes.
  List<String> getPurchasedTrails() {
    return _prefs?.getStringList(_purchasedTrailsKey) ?? [];
  }

  /// Verifie si le bandeau "Mode demo" doit etre affiche.
  ///
  /// Retourne true si le trek est en mode demo = bandeau visible.
  bool shouldShowDemoBanner(String trailId) {
    return isDemoMode(trailId);
  }

  /// Verifie si le GPS est autorise pour ce trek.
  ///
  /// En mode demo, le GPS est desactive (carte visible, pas de tracking).
  bool isGpsEnabled(String trailId) {
    return !isDemoMode(trailId);
  }

  /// Verifie si le journal est en mode lecture seule.
  ///
  /// En mode demo, le journal est consultable mais pas editable.
  bool isJournalReadOnly(String trailId) {
    return isDemoMode(trailId);
  }
}
