import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/services/cloud_sync_service.dart';
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
class HealthBackupService {
  HealthBackupService({
    required SecureVaultService vault,
    required HealthInfoRepository healthRepository,
    CloudSyncService? cloudSync,
  }) : _vault = vault,
       _health = healthRepository,
       _cloudSync = cloudSync;

  final SecureVaultService _vault;
  final HealthInfoRepository _health;

  /// Transport du blob chiffré vers le miroir anonyme (optionnel : sans lui, on
  /// reste en mode blob « à déposer soi-même », p.ex. cloud OS). Ciphertext only.
  final CloudSyncService? _cloudSync;

  /// Marqueur de type de contenu dans le blob (robustesse au déchiffrement).
  static const String _kind = 'stepways.health.v1';

  /// Clé de document du backup santé dans le miroir anonyme.
  static const String cloudDocKey = 'health';

  // --- Backup cross-device via le CODE de reconnexion (mode principal) -----

  /// Chiffre la fiche santé courante avec une clé dérivée du [code].
  ///
  /// Retourne le blob chiffré (à déposer dans le miroir cloud anonyme / cloud
  /// OS), ou `null` s'il n'y a aucune fiche à sauvegarder. Un sel aléatoire est
  /// embarqué dans le blob pour permettre la re-dérivation sur un autre tél.
  Future<String?> exportWithCode(String code) async {
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
  Future<HealthInfo> restoreWithCode(String code, String blob) async {
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
  Future<bool> backupToCloud(String anonymousUserId, String code) async {
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
    final cloud = _cloudSync;
    if (cloud == null) return null;
    final blob = await cloud.pullEncryptedBackup(anonymousUserId, cloudDocKey);
    if (blob == null) return null;
    return restoreWithCode(code, blob);
  }

  // --- Backup on-device via la clé LOCALE keystore -------------------------

  /// Chiffre la fiche santé avec la clé LOCALE (keystore OS). Même appareil
  /// uniquement (la clé ne suit pas sur un tél neuf). `null` si pas de fiche.
  Future<String?> exportWithLocalKey() async {
    final info = await _health.get();
    if (!info.hasData) return null;
    final key = await _vault.getOrCreateLocalDataKey();
    return _vault.encryptJson(_wrap(info), key: key);
  }

  /// Déchiffre un [blob] avec la clé LOCALE et restaure la fiche. Lève
  /// [VaultDecryptException] si la clé locale a changé/été effacée.
  Future<HealthInfo> restoreWithLocalKey(String blob) async {
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

/// Provider Riverpod du service de backup chiffré de la fiche santé.
final healthBackupServiceProvider = Provider<HealthBackupService>((ref) {
  return HealthBackupService(
    vault: ref.watch(secureVaultServiceProvider),
    healthRepository: ref.watch(healthInfoRepositoryProvider),
    cloudSync: ref.watch(cloudSyncServiceProvider),
  );
});
