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
// EXCEPTION VITRINE (PARITE GR20, LOT 2, #99433) : un sentier marque VITRINE
// (TrailConfig.isShowcaseTrail, cf. TrailCatalog.showcaseIds) est traite comme
// DEBLOQUE meme sans achat -> GPS + journal + navigation jouables, sans bandeau
// demo. C'est la parite avec le mode demo « tout debloque » de GR20. Le
// debridage est pilote par ce FLAG de donnees, jamais par un id de localite en
// dur. GARDE-FOU : seule la vitrine est debridee ; le modele a la carte reste
// intact sur tous les autres sentiers (decision Christophe).
//
// Source de verite : la liste des trailId achetes par l'utilisateur,
// stockee localement (SharedPreferences) et synchronisee depuis
// le backend d'achat.

import 'package:shared_preferences/shared_preferences.dart';

import '../config/trail_catalog.dart';

/// Service de gestion du mode demo universel.
///
/// Determine si un trek donne est en mode demo pour l'utilisateur
/// courant, en se basant sur la liste des achats (trailIds).
/// Un trek non achete = mode demo, quel que soit le statut premium.
///
/// EXCEPTION : un sentier VITRINE ([showcaseTrailIds], derive du flag de
/// donnees [TrailConfig.isShowcaseTrail]) n'est JAMAIS en mode demo, meme non
/// achete (parite GR20, LOT 2). Injection [showcaseTrailIds] overridable en
/// test ; par defaut = [TrailCatalog.showcaseIds] (aucun hardcode de localite).
class DemoModeService {
  DemoModeService({
    SharedPreferences? prefs,
    Set<String>? showcaseTrailIds,
    Future<bool> Function(String trailId)? demoResolver,
  })  : _prefs = prefs,
        _showcaseTrailIds = showcaseTrailIds,
        _demoResolver = demoResolver;

  /// Instance SharedPreferences (injectee ou chargee au premier appel).
  SharedPreferences? _prefs;

  /// Sentiers vitrine debloques sans achat (injecte ou derive du catalogue).
  final Set<String>? _showcaseTrailIds;

  /// Delegue de reconciliation (StepWays LOT 1) : quand fourni, [isDemoModeAsync]
  /// derive l'etat demo de la SOURCE UNIQUE (`MonetizationService`, droits Drift)
  /// au lieu de la cle prefs legacy `purchased_trail_ids`. Cable par le provider ;
  /// null = comportement autonome historique (compat tests E5.18).
  final Future<bool> Function(String trailId)? _demoResolver;

  /// Ensemble effectif des sentiers vitrine (injection > catalogue).
  Set<String> get _showcase => _showcaseTrailIds ?? TrailCatalog.showcaseIds;

  /// Cle SharedPreferences pour la liste des trailIds achetes.
  static const String _purchasedTrailsKey = 'purchased_trail_ids';

  /// Vrai si [trailId] est un sentier VITRINE (débloqué jouable sans achat).
  bool isShowcaseTrail(String trailId) => _showcase.contains(trailId);

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
  /// EXCEPTION VITRINE (parite GR20, LOT 2) : un sentier vitrine
  /// ([isShowcaseTrail]) n'est JAMAIS en mode demo, meme non achete ->
  /// GPS + journal jouables (les autres sentiers restent bridés).
  bool isDemoMode(String trailId) {
    if (isShowcaseTrail(trailId)) return false;
    final purchased = _prefs?.getStringList(_purchasedTrailsKey) ?? [];
    return !purchased.contains(trailId);
  }

  /// Version RECONCILIEE (StepWays LOT 1) : delegue a la SOURCE UNIQUE quand un
  /// [_demoResolver] est cable (droits Drift de `MonetizationService`), sinon
  /// retombe sur [isDemoMode] (cle prefs legacy). Supprime le doublon d'achats :
  /// `DemoModeService` et `MonetizationService` renvoient le meme etat demo.
  ///
  /// La vitrine reste TOUJOURS jouable (jamais en demo), quel que soit le mode.
  Future<bool> isDemoModeAsync(String trailId) async {
    if (isShowcaseTrail(trailId)) return false;
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
