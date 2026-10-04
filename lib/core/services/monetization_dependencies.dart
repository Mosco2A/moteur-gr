/// Les collaborateurs injectes du service de monetisation, partages par ses
/// classes de responsabilite : stockages, store, reseau, horloge, demo.
///
/// Lot 645-06b : [MonetizationService] etait une classe de 965 lignes. Il est
/// desormais compose de classes collaboratrices (prix, droits, abonnement,
/// recompense, acces, achats) ; elles lisent toutes les MEMES dependances, que
/// cet objet porte une seule fois. En particulier les preferences sont
/// resolues une seule fois et partagees, exactement comme quand elles etaient
/// un champ du service.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../data/daos/no_ads_dao.dart';
import '../data/daos/trek_entitlements_dao.dart';
import '../network/connectivity_monitor.dart';
import 'wallet_iap_service.dart';
import 'wallet_store.dart';

/// Les dependances communes des collaborateurs de [MonetizationService].
class MonetizationDependencies {
  /// Construit les dependances ; [now] est l'horloge deja resolue.
  MonetizationDependencies({
    required this.wallet,
    required this.entitlementsDao,
    required this.noAdsDao,
    required this.iap,
    required this.connectivity,
    required this.now,
    SharedPreferences? prefs,
    bool Function()? enDemo,
    this.freeTrailIds,
    this.stagesOf,
  }) : _prefs = prefs,
       _enDemo = enDemo;

  /// Le compte-etapes (solde d'etapes rechargeable).
  final WalletStore wallet;

  /// Les droits par trek (`owned`, etapes acquises).
  final TrekEntitlementsDao entitlementsDao;

  /// Les sources sans-pub (abonnement, recompense).
  final NoAdsDao noAdsDao;

  /// L'achat in-app (packs, abonnement, restauration).
  final WalletIapService iap;

  /// L'etat du reseau (le complement store l'exige).
  final ConnectivityMonitor connectivity;

  /// Horloge injectable (reward 24 h testable via `Clock`).
  final DateTime Function() now;

  /// Sentiers GRATUITS (injectés en test, sinon dérivés du catalogue).
  final Set<String>? freeTrailIds;

  /// Nombre d'étapes d'un sentier — LE PRIX, résolu depuis le CATALOGUE.
  ///
  /// Injecté par [monetizationServiceProvider] sur le catalogue EFFECTIF
  /// (distant > dernier reçu > compilé) ; `null` en test ou hors Riverpod, où
  /// l'on retombe sur le catalogue COMPILÉ. Même forme d'injection que
  /// [freeTrailIds], et pour la même raison : le prix et la gratuité sont deux
  /// lectures de la même donnée, jamais deux décisions.
  final int Function(String trailId)? stagesOf;

  /// LA BARRIERE D'ECRITURE DE LA DEMO (tache 634, DEM-260929-1123).
  ///
  /// Rendue par une FONCTION et non par un booleen fige : la demo s'entre et se
  /// quitte pendant la vie du service, et le service n'est pas reconstruit pour
  /// autant. On interroge donc l'etat A L'INSTANT DE L'ECRITURE — meme
  /// raisonnement que `stagesOf`, qui lit le prix a l'instant de l'achat.
  ///
  /// `null` (defaut) = jamais en demo. C'est ce que lisent les tests qui ne
  /// connaissent pas ce mode, et le comportement d'origine est donc
  /// strictement inchange pour eux.
  final bool Function()? _enDemo;

  /// Vrai quand une demo volontaire est en cours : AUCUNE ecriture d'argent,
  /// de droit ou d'abonnement ne doit partir.
  bool get enDemo => _enDemo?.call() ?? false;

  SharedPreferences? _prefs;

  /// Les preferences, resolues au premier besoin puis gardees.
  Future<SharedPreferences> get preferences async =>
      _prefs ??= await SharedPreferences.getInstance();
}
