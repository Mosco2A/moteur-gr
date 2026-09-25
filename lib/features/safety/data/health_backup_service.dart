import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/services/secure_vault_service.dart';
import '../domain/models/health_info.dart';
import '../presentation/health_info_screen.dart'
    show healthInfoRepositoryProvider;
import 'health_info_repository.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Sauvegarde/restauration CHIFFRÉE de la fiche santé (StepWays L7, gap C).
///
/// La fiche santé (art. 9 RGPD : groupe sanguin, allergies, traitements…) est
/// LOCAL-ONLY (Drift) et ne doit JAMAIS transiter en clair. Au changement de
/// téléphone, l'utilisateur doit pouvoir la retrouver — donc un backup
/// CHIFFRÉ, zéro-knowledge.
///
/// PRINCIPE : la fiche est chiffrée par [SecureVaultService] (AES-GCM 256) en un
/// blob auto-descriptif. Deux modes de clé :
///  - **CODE de reconnexion** (cross-device, mode principal §C) : la clé est
///    dérivée du code (PBKDF2). Le même code sur un autre tél re-dérive la clé
///    et déchiffre le blob. C'est le seul mode qui SURVIT au changement de tél.
///  - **clé LOCALE keystore** (même appareil) : la clé vit dans le keystore OS
///    (`flutter_secure_storage`) ; utile pour un backup on-device, mais elle ne
///    suit pas sur un tél neuf (keystore vide) — donc réservée au même appareil.
///
/// Le blob chiffré peut être déposé tel quel dans le miroir cloud ANONYME (sous
/// le hash SHA-256, comme le profil L4) ou exporté vers le cloud OS : le serveur
/// ne voit que du chiffré. Cette classe ne fait PAS le transport réseau ; elle
/// produit/consomme le blob (le CloudSync/backend anonyme s'en charge, hors de
/// cette couche — même patron que `HikerProfileRepository`).
///
/// GARDE ART. 9 (tâche 562, K3) — DÉCISION PRODUIT, PAS TECHNIQUE. Ce service
/// produisait et déposait le blob SANS aucune vérification de consentement. Le
/// chiffrement zéro-knowledge et le caractère de SÉCURITÉ de la fiche (c'est
/// celle qu'on montre aux secours) plaidaient pour laisser passer. Tranché par
/// Skynet : on ne sauvegarde pas une donnée de santé sans accord, même
/// chiffrée, même pour le bien de la personne — l'accord se demande, il ne se
/// suppose pas. Chaque méthode vérifie donc ELLE-MÊME
/// [ConsentPurpose.healthData], fermée par défaut, et le randonneur lit ce
/// qu'il perd en refusant (`t.consent.healthBackupNote`, cinq langues, affiché
/// sur l'écran même où il refuse).
class HealthBackupService {
  HealthBackupService({
    required SecureVaultService vault,
    required HealthInfoRepository healthRepository,
    CloudSyncService? cloudSync,
    ConsentCheck? consentCheck,
  }) : _vault = vault,
       _health = healthRepository,
       _cloudSync = cloudSync,
       consentCheck = consentCheck ?? consentFromLocalStore;

  final SecureVaultService _vault;
  final HealthInfoRepository _health;

  /// Vérification de consentement utilisée par les gardes de ce service.
  /// JAMAIS nulle : à défaut d'injection, elle lit l'état RÉEL du stockage
  /// local ([consentFromLocalStore]), relu à CHAQUE appel — un consentement
  /// retiré produit donc un refus immédiat. Une garde qu'on désactive en
  /// oubliant un paramètre n'est pas une garde (tâche 561, J2).
  final ConsentCheck consentCheck;

  /// Transport du blob chiffré vers le miroir anonyme (optionnel : sans lui, on
  /// reste en mode blob « à déposer soi-même », p.ex. cloud OS). Ciphertext only.
  final CloudSyncService? _cloudSync;

  /// Marqueur de type de contenu dans le blob (robustesse au déchiffrement).
  static const String _kind = 'stepways.health.v1';

  /// Clé de document du backup santé dans le miroir anonyme.
  static const String cloudDocKey = 'health';

  /// GARDE ART. 9 — à appeler EN PREMIER dans chaque méthode, avant toute
  /// lecture de la fiche, toute dérivation de clé et tout accès réseau.
  ///
  /// Lève [HealthConsentMissingException] : un refus de consentement ne doit
  /// JAMAIS se confondre avec « aucune fiche à sauvegarder » (`null`) ni avec
  /// « cloud indisponible » (`false`). Ces deux retours existent déjà et sont
  /// des no-op légitimes ; un refus, lui, doit être visible de l'appelant pour
  /// qu'il puisse dire au randonneur ce qu'il perd.
  Future<void> _requireHealthConsent(String operation) async {
    if (await consentCheck(ConsentPurpose.healthData)) return;
    _log.w('[HealthBackup] Consentement santé absent -> $operation REFUSÉ');
    throw const HealthConsentMissingException();
  }

  // --- Backup cross-device via le CODE de reconnexion (mode principal) -----

  /// Chiffre la fiche santé courante avec une clé dérivée du [code].
  ///
  /// Retourne le blob chiffré (à déposer dans le miroir cloud anonyme / cloud
  /// OS), ou `null` s'il n'y a aucune fiche à sauvegarder. Un sel aléatoire est
  /// embarqué dans le blob pour permettre la re-dérivation sur un autre tél.
  ///
  /// GARDE ART. 9 : sans consentement `healthData` EFFECTIF, lève
  /// [HealthConsentMissingException] sans même lire la fiche.
  Future<String?> exportWithCode(String code) async {
    await _requireHealthConsent('export par code');
    final info = await _health.get();
    if (!info.hasData) {
      _log.d('[HealthBackup] Aucune fiche à sauvegarder');
      return null;
    }
    final salt = _vault.newSalt();
    final key = await _vault.deriveKeyFromCode(code, salt);
    final payload = _wrap(info);
    return _vault.encryptJson(payload, key: key, salt: salt);
  }

  /// Déchiffre un [blob] avec le [code] et RESTAURE la fiche en local.
  ///
  /// Le sel est lu dans le blob (zéro-knowledge : rien de nominatif). Lève
  /// [VaultDecryptException] si le code est faux ou le blob altéré (aucune
  /// écriture locale dans ce cas). Retourne la fiche restaurée.
  ///
  /// GARDE ART. 9 : la restauration ÉCRIT de la donnée de santé sur l'appareil.
  /// C'est un traitement de la même finalité que le backup — même consentement,
  /// même symétrie que `CloudSyncService.syncHikerProfile` /
  /// `RestoreService.restoreHikerProfile` (tâche 561, J2).
  Future<HealthInfo> restoreWithCode(String code, String blob) async {
    await _requireHealthConsent('restauration par code');
    final salt = _vault.saltOf(blob);
    if (salt == null) {
      throw const VaultDecryptException('sel absent du blob');
    }
    final key = await _vault.deriveKeyFromCode(code, salt);
    final data = await _vault.decryptJson(blob, key: key);
    final info = _unwrap(data);
    await _health.save(info);
    _log.d('[HealthBackup] Fiche santé restaurée (code)');
    return info;
  }

  // --- Backup vers le miroir cloud ANONYME (bout-en-bout, via code) --------

  /// Chiffre la fiche avec le [code] et DÉPOSE le blob dans le miroir anonyme
  /// sous `users/{anonymousUserId}/secure_backup/health`.
  ///
  /// [anonymousUserId] = hash SHA-256 (`anonymous_id_service`), jamais un
  /// identifiant en clair. Le serveur ne reçoit que du chiffré. GRACEFUL NO-OP
  /// si pas de fiche, ou transport cloud absent/indisponible (retourne false).
  ///
  /// GARDE ART. 9 EN PREMIER : un refus de consentement n'est PAS un no-op, il
  /// lève. Sans cela il se confondrait avec « cloud absent » et deviendrait
  /// indébuggable — exactement le piège nommé au LOT J.
  Future<bool> backupToCloud(String anonymousUserId, String code) async {
    await _requireHealthConsent('dépôt du backup santé dans le miroir');
    final cloud = _cloudSync;
    if (cloud == null) return false;
    final blob = await exportWithCode(code);
    if (blob == null) return false;
    final res = await cloud.pushEncryptedBackup(
      anonymousUserId,
      cloudDocKey,
      blob,
    );
    return res.status == CloudSyncStatusValues.success;
  }

  /// Récupère le blob chiffré depuis le miroir anonyme et RESTAURE la fiche en
  /// local avec le [code]. Retourne la fiche restaurée, ou `null` si aucun
  /// backup cloud. Lève [VaultDecryptException] si le code est faux.
  Future<HealthInfo?> restoreFromCloud(
    String anonymousUserId,
    String code,
  ) async {
    await _requireHealthConsent('restauration depuis le miroir');
    final cloud = _cloudSync;
    if (cloud == null) return null;
    final blob = await cloud.pullEncryptedBackup(anonymousUserId, cloudDocKey);
    if (blob == null) return null;
    return restoreWithCode(code, blob);
  }

  // --- Backup on-device via la clé LOCALE keystore -------------------------

  /// Chiffre la fiche santé avec la clé LOCALE (keystore OS). Même appareil
  /// uniquement (la clé ne suit pas sur un tél neuf). `null` si pas de fiche.
  ///
  /// GARDE ART. 9 aussi sur ce chemin, bien qu'il soit « on-device » : le blob
  /// produit ici est PORTABLE par construction et l'en-tête de cette classe
  /// prévoit explicitement de l'exporter vers le cloud de l'OS. Un blob de
  /// donnée de santé ne se fabrique donc pas sans accord.
  Future<String?> exportWithLocalKey() async {
    await _requireHealthConsent('export par clé locale');
    final info = await _health.get();
    if (!info.hasData) return null;
    final key = await _vault.getOrCreateLocalDataKey();
    return _vault.encryptJson(_wrap(info), key: key);
  }

  /// Déchiffre un [blob] avec la clé LOCALE et restaure la fiche. Lève
  /// [VaultDecryptException] si la clé locale a changé/été effacée.
  ///
  /// GARDE ART. 9 : même raison que [restoreWithCode] — restaurer, c'est écrire
  /// de la donnée de santé sur l'appareil.
  Future<HealthInfo> restoreWithLocalKey(String blob) async {
    await _requireHealthConsent('restauration par clé locale');
    final key = await _vault.getOrCreateLocalDataKey();
    final info = _unwrap(await _vault.decryptJson(blob, key: key));
    await _health.save(info);
    return info;
  }

  // --- (dé)sérialisation du contenu ----------------------------------------

  Map<String, dynamic> _wrap(HealthInfo info) => {
    'kind': _kind,
    'health': info.toJson(),
  };

  HealthInfo _unwrap(Map<String, dynamic> data) {
    if (data['kind'] != _kind || data['health'] is! Map) {
      throw const VaultDecryptException('contenu de backup inattendu');
    }
    return HealthInfo.fromJson(
      Map<String, dynamic>.from(data['health'] as Map),
    );
  }
}

/// REFUS de consentement santé sur une opération de backup/restauration de la
/// fiche (art. 9 RGPD, tâche 562 K3).
///
/// Porte une RAISON nommée, volontairement identique à celle du miroir de profil
/// ([kSyncErrorHealthConsentMissing]) : les deux refus ont la même cause et se
/// diagnostiquent avec le même mot. Ce n'est pas une panne — c'est une décision.
class HealthConsentMissingException implements Exception {
  const HealthConsentMissingException();

  /// Raison nommée, à journaliser ou à mapper vers un message d'écran.
  String get reason => kSyncErrorHealthConsentMissing;

  @override
  String toString() => 'HealthConsentMissingException: $reason';
}

/// Provider Riverpod du service de backup chiffré de la fiche santé.
final healthBackupServiceProvider = Provider<HealthBackupService>((ref) {
  return HealthBackupService(
    vault: ref.watch(secureVaultServiceProvider),
    healthRepository: ref.watch(healthInfoRepositoryProvider),
    cloudSync: ref.watch(cloudSyncServiceProvider),
  );
});
