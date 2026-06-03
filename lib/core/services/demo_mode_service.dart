// E5.18 — Service mode demo universel.
//
// Le mode demo s'applique a TOUT trek non achete, quel que soit
// le statut de l'utilisateur. Un premium qui a achete le GR20
// voit Mare a Mare en mode demo, et inversement.
//
// Limites du mode demo :
// - Carte visible, GPS desactive
// - Journal en lecture seule (read-only)
// - Bandeau "Mode demo" affiche en haut de l'ecran
//
// Source de verite : la liste des trailId achetes par l'utilisateur,
// stockee localement (SharedPreferences) et synchronisee depuis
// le backend d'achat.

import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion du mode demo universel.
///
/// Determine si un trek donne est en mode demo pour l'utilisateur
/// courant, en se basant sur la liste des achats (trailIds).
/// Un trek non achete = mode demo, quel que soit le statut premium.
class DemoModeService {
  DemoModeService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Instance SharedPreferences (injectee ou chargee au premier appel).
  SharedPreferences? _prefs;

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
  /// un premium qui a achete le GR20 voit Mare a Mare en demo.
  bool isDemoMode(String trailId) {
    final purchased = _prefs?.getStringList(_purchasedTrailsKey) ?? [];
    return !purchased.contains(trailId);
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
