/// Grille du compte-etapes : prix d'un palier, packs de recharge, et achat qui
/// prend d'abord au solde avant de passer au store.
library;

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/feature_flags.dart';
import '../config/trail_catalog.dart';
import '../config/trail_selection.dart';
import '../data/daos/no_ads_dao.dart';
import '../data/daos/trek_entitlements_dao.dart';
import '../config/ad_config.dart';
import '../data/database.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'wallet_iap_service.dart';
import 'wallet_store.dart';
import 'session_demo.dart';

part 'monetization_service_modeles.dart';
part 'monetization_service_service.dart';
part 'monetization_service_fournisseurs.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Prix d'un PALIER d'étape (1 étape), en euros (StepWays LOT 1, modèle éco).
///
/// Remplace l'ancien `kPricePerStageEur` (1,0). Le prix « catalogue » d'un trek
/// = nombre d'étapes × [kStepTierEur] ; il sert d'ancrage d'affichage. L'achat
/// réel passe par le compte-étapes ([buyTrail]) : wallet d'abord, complément
/// store via un PACK (grille [kStepPacks]).
const double kStepTierEur = 0.99;

/// Étapes créditées et prix EUR de chaque PACK de recharge (grille officielle).
///
/// Les packs sont vendus par le store (consommables StepWays,
/// `wallet_iap_service.dart`). Le complément d'un achat passe par le PLUS PETIT
/// pack couvrant le manque (reco spec §3.1) : évite les SKU unitaires
/// ingérables. Trié par nombre d'étapes croissant (contrat pour [packSteps]).
const List<StepPack> kStepPacks = <StepPack>[
  StepPack(steps: 11, priceEur: 9.99, productId: kWalletCredits11),
  StepPack(steps: 25, priceEur: 19.99, productId: kWalletCredits25),
  StepPack(steps: 50, priceEur: 34.99, productId: kWalletCredits50),
];

/// Clé SharedPreferences legacy #1 : treks achetés (booléen par trek).
///
/// Écrite par l'ANCIEN `MonetizationService` (`purchaseTrail` stub). Migrée en
/// runtime vers `TrekEntitlements.owned=true` par [migrateLegacyPurchases].
const kPurchasedTrailsPrefsKey = 'monetization.purchasedTrails';

/// Clé SharedPreferences legacy #2 : treks achetés vus par `DemoModeService`.
///
/// 2ᵉ source d'achat historique (doublon). Migrée elle aussi vers
/// `TrekEntitlements.owned=true` (idempotent).
const kDemoModePurchasedTrailsPrefsKey = 'purchased_trail_ids';
