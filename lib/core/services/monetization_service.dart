import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../config/trail_catalog.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Prix premium par etape, en euros (#81774 : 1 EUR par etape).
const kPricePerStageEur = 1.0;

/// Cle SharedPreferences des treks achetes.
const kPurchasedTrailsPrefsKey = 'monetization.purchasedTrails';

/// Features disponibles selon le mode (gratuit ou premium).
///
/// En mode gratuit : preparation avec pub + demo limitee.
/// En mode premium (post-achat) : carte GPS tracking journal diplome
/// goodies + 2 suiveurs gratuits, SANS pub.
class TrailFeatures {
  const TrailFeatures({
    required this.hasAds,
    required this.isDemo,
    required this.hasGpsTracking,
    required this.hasJournal,
    required this.hasDiploma,
    required this.hasGoodies,
    required this.freeFollowerSlots,
    required this.hasPreparation,
  });

  /// Publicites affichees
  final bool hasAds;

  /// Mode demonstration (fonctionnalites limitees)
  final bool isDemo;

  /// Carte GPS + suivi en direct
  final bool hasGpsTracking;

  /// Journal de bord
  final bool hasJournal;

  /// Diplome de fin de trek
  final bool hasDiploma;

  /// Boutique goodies
  final bool hasGoodies;

  /// Nombre de suiveurs gratuits (0 en gratuit, 2 en premium)
  final int freeFollowerSlots;

  /// Acces a la preparation du trek
  final bool hasPreparation;
}

/// Service de monetisation freemium a la carte (E4.17).
///
/// Modele (#81774) : chaque trek est un achat separe.
/// - Gratuit : preparation (faisabilite, fiches, checklist,
///   calendrier) AVEC PUB + mode demo partout.
/// - Premium (post-achat par trek) : carte GPS tracking journal
///   diplome goodies + 2 suiveurs gratuits SANS PUB.
/// Pas d abonnement. Prix = nombre d etapes x [kPricePerStageEur].
///
/// isDemoMode est PAR TREK, pas par user : un trek achete ne
/// debloque que CE sentier (#81805 V7).
///
/// STUBS/SANDBOX uniquement : purchaseTrail enregistre l achat en
/// local (SharedPreferences) sans appel au store. Le branchement
/// IAP reel (in_app_purchase) se fera derriere cette interface.
/// L etat premium est reflete dans FeatureFlags (premium:trailId)
/// pour les gardes de routes synchrones.
class MonetizationService {
  MonetizationService({SharedPreferences? prefs, Set<String>? showcaseTrailIds})
      : _prefs = prefs,
        _showcaseTrailIds = showcaseTrailIds;

  SharedPreferences? _prefs;

  /// Sentiers VITRINE debloques sans achat (injecte ou derive du catalogue).
  ///
  /// PARITE GR20, LOT 2 (#99433) : un sentier vitrine est traite comme premium
  /// (jouable) meme sans achat. Derive du flag de donnees
  /// [TrailConfig.isShowcaseTrail] via [TrailCatalog.showcaseIds] — aucun id de
  /// localite en dur. Overridable en test.
  final Set<String>? _showcaseTrailIds;

  Set<String> get _showcase => _showcaseTrailIds ?? TrailCatalog.showcaseIds;

  /// Vrai si [trailId] est un sentier VITRINE (débloqué jouable sans achat).
  bool isShowcaseTrail(String trailId) => _showcase.contains(trailId);

  /// Cache interne des achats par trailId.
  final Set<String> _purchases = {};

  bool _loaded = false;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Charge les achats persistes (a appeler au demarrage).
  Future<void> loadPurchases() async {
    final prefs = await _preferences;
    final stored = prefs.getStringList(kPurchasedTrailsPrefsKey) ?? const [];
    _purchases
      ..clear()
      ..addAll(stored);
    for (final trailId in _purchases) {
      FeatureFlags.setOverride('premium', trailId, enabled: true);
    }
    _loaded = true;
    _log.d('[Monetization] ${_purchases.length} trek(s) premium charges');
  }

  /// Verifie si un trek a ete achete.
  ///
  /// Retourne true si le trek [trailId] a ete achete par l'utilisateur.
  /// Chaque trek est independant (#81805 V7).
  bool isTrailPurchased(String trailId) {
    return _purchases.contains(trailId);
  }

  /// Indique si l etat persiste a ete charge.
  bool get isLoaded => _loaded;

  /// Prix premium d un trek en euros (#81774 : 1 EUR par etape).
  double priceForTrail({required int totalStages}) {
    return totalStages * kPricePerStageEur;
  }

  /// Enregistre l'achat d'un trek (STUB — aucun paiement reel).
  ///
  /// En production, cette methode sera appelee apres verification
  /// de l achat via in_app_purchase/purchaseStream (E4.14). Ici :
  /// enregistrement local persiste + propagation FeatureFlags.
  Future<bool> purchaseTrail(String trailId) async {
    _purchases.add(trailId);
    FeatureFlags.setOverride('premium', trailId, enabled: true);
    final prefs = await _preferences;
    await prefs.setStringList(
      kPurchasedTrailsPrefsKey,
      _purchases.toList()..sort(),
    );
    _log.i('[Monetization] Trek $trailId debloque (premium)');
    return true;
  }

  /// Features du mode gratuit : preparation avec pub + demo.
  ///
  /// Le randonneur peut preparer son trek (etapes, meteo, checklist)
  /// mais avec publicites et en mode demonstration.
  TrailFeatures getTrialFeatures() {
    return const TrailFeatures(
      hasAds: true,
      isDemo: true,
      hasGpsTracking: false,
      hasJournal: false,
      hasDiploma: false,
      hasGoodies: false,
      freeFollowerSlots: 0,
      hasPreparation: true,
    );
  }

  /// Features du mode premium (post-achat) : tout, sans pub.
  ///
  /// Carte GPS tracking, journal, diplome, goodies,
  /// 2 suiveurs gratuits, pas de publicite.
  TrailFeatures getPremiumFeatures() {
    return const TrailFeatures(
      hasAds: false,
      isDemo: false,
      hasGpsTracking: true,
      hasJournal: true,
      hasDiploma: true,
      hasGoodies: true,
      freeFollowerSlots: 2,
      hasPreparation: true,
    );
  }

  /// Retourne les features applicables pour un trek donne.
  ///
  /// Si le trek est achete OU VITRINE -> premium (jouable). Sinon -> gratuit
  /// (demo + pub). Decision PAR TREK, pas par user (#81805 V7).
  ///
  /// PARITE GR20, LOT 2 (#99433) : la vitrine ([isShowcaseTrail]) obtient les
  /// features premium sans achat (GPS/journal/diplome), comme la demo « tout
  /// debloque » de GR20 ; les autres sentiers non achetes restent en gratuit.
  TrailFeatures getFeaturesForTrail(String trailId) {
    if (isTrailPurchased(trailId) || isShowcaseTrail(trailId)) {
      return getPremiumFeatures();
    }
    return getTrialFeatures();
  }

  /// Indique si un trek est en mode demo.
  ///
  /// Retourne true si ce trek n'a PAS ete achete,
  /// QUEL QUE SOIT le statut global de l'utilisateur (#81805 V7).
  ///
  /// EXCEPTION VITRINE (parite GR20, LOT 2) : un sentier vitrine
  /// ([isShowcaseTrail]) n'est jamais en mode demo (jouable sans achat).
  bool isDemoMode(String trailId) {
    if (isShowcaseTrail(trailId)) return false;
    return !isTrailPurchased(trailId);
  }

  /// Reinitialise les achats (tests uniquement).
  void clearPurchases() {
    for (final trailId in _purchases) {
      FeatureFlags.setOverride('premium', trailId, enabled: false);
    }
    _purchases.clear();
  }
}

/// Provider Riverpod pour le service de monetisation.
final monetizationServiceProvider = Provider<MonetizationService>((ref) {
  return MonetizationService();
});
