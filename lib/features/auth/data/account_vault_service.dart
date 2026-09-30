import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/cloud_sync_service.dart';
import '../../../core/services/secure_vault_service.dart';
import '../../../core/services/wallet_store.dart';
import '../providers/auth_provider.dart';
import '../domain/auth_service.dart';

/// Sauvegarde/restauration CHIFFRÉE du PROFIL + SOLDE WALLET (StepWays — coffre
/// de reconnexion, décision Chris #99784).
///
/// Le coffre de reconnexion contient DEUX blocs, chacun chiffré ZÉRO-KNOWLEDGE
/// avec la clé dérivée du CODE de reconnexion ([SecureVaultService]) :
///  - le **profil** (pseudonyme + avatar — zéro PII : ni email ni photo) ;
///  - le **solde wallet** (compte-étapes : le code EST la clé du solde, #99784).
///
/// IL EN CONTENAIT TROIS, ET LE TROISIÈME EST PARTI LE 28/09 (tâche 612). Cet
/// en-tête annonçait « la fiche santé (déjà branchée en L7 :
/// `HealthBackupService`) ». Décision de Christophe, verbatim et en majuscules
/// dans son message : « NON ON NE TROUVERAIT RIEN !!! Les donnees medicales
/// RESTENT sur le tel !!! ». La fiche médicale N'ENTRE PLUS dans ce coffre, et
/// elle ne peut plus y entrer : `HealthBackupService` n'existe plus, et le
/// transport n'accepte que [DocumentsDuCoffreDistant.autorises], où elle ne
/// figure pas.
///
/// CE QUI RESTE VRAI, ET QU'IL NE FAUT PAS CONFONDRE. Le pseudonyme, l'avatar et
/// le solde d'étapes ne sont PAS des données de santé : ce coffre-ci n'est pas
/// concerné par la décision du 28/09, et le randonneur qui retrouve son solde
/// avec son code ne retrouve pas sa fiche médicale — celle-là se ressaisit, et
/// l'écran de la fiche le dit au moment où il la remplit.
///
/// CE QUE CE SERVICE FAIT : il produit/consomme un blob chiffré auto-descriptif
/// (le transport réseau vers le miroir anonyme est HORS de cette couche). Chris
/// peut demander d'EXCLURE le solde du transfert ([includeWallet] = false) ;
/// par défaut il est inclus (« tout revient avec le même code », #99784).
///
/// RESTAURATION : re-dérive la clé depuis le code (+ sel du blob) et réécrit le
/// profil (pseudonyme/avatar) et le solde en local. Lève [VaultDecryptException]
/// si le code est faux (aucune écriture partielle).
class AccountVaultService {
  AccountVaultService({
    required SecureVaultService vault,
    required AuthService auth,
    required WalletStore wallet,
  }) : _vault = vault,
       _auth = auth,
       _wallet = wallet;

  final SecureVaultService _vault;
  final AuthService _auth;
  final WalletStore _wallet;

  /// Marqueur de type de contenu (robustesse au déchiffrement).
  static const String _kind = 'stepways.account.v1';

  /// Clé de document du backup compte dans le miroir anonyme.
  ///
  /// ELLE N'EST PLUS ÉCRITE ICI (tâche 612) : elle vient de la liste fermée
  /// [DocumentsDuCoffreDistant], le seul endroit qui décide ce que le coffre
  /// distant peut porter. Deux listes finiraient par diverger, et c'est la
  /// divergence qui rouvre une porte.
  static const String cloudDocKey = DocumentsDuCoffreDistant.compte;

  /// Chiffre le profil (+ solde wallet si [includeWallet]) avec une clé dérivée
  /// du [code]. Retourne le blob chiffré à déposer (miroir cloud anonyme / cloud
  /// OS), ou `null` s'il n'y a rien à sauvegarder (pas d'utilisateur).
  Future<String?> exportWithCode(
    String code, {
    bool includeWallet = true,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final payload = <String, dynamic>{
      'kind': _kind,
      'profile': <String, dynamic>{
        'displayName': user.displayName,
        'avatarIndex': user.avatarIndex,
        'authMethod': user.authMethod,
      },
    };
    if (includeWallet) {
      // Assure l'hydratation depuis la source durable avant de lire le solde.
      if (!_wallet.isLoaded) await _wallet.load();
      final s = _wallet.snapshot;
      payload['wallet'] = <String, dynamic>{
        'balanceSteps': s.balanceSteps,
        'lifetimeEarnedSteps': s.lifetimeEarnedSteps,
        'lifetimeSpentSteps': s.lifetimeSpentSteps,
      };
    }

    final salt = _vault.newSalt();
    final key = await _vault.deriveKeyFromCode(code, salt);
    return _vault.encryptJson(payload, key: key, salt: salt);
  }

  /// Déchiffre un [blob] avec le [code] et RESTAURE le profil (+ solde si
  /// présent) en local. Lève [VaultDecryptException] si le code est faux/altéré.
  Future<void> restoreWithCode(String code, String blob) async {
    final salt = _vault.saltOf(blob);
    if (salt == null) {
      throw const VaultDecryptException('sel absent du blob');
    }
    final key = await _vault.deriveKeyFromCode(code, salt);
    final data = await _vault.decryptJson(blob, key: key);
    if (data['kind'] != _kind) {
      throw const VaultDecryptException('contenu de backup inattendu');
    }

    // --- Profil (pseudonyme + avatar ; zéro PII) ---
    final profile = data['profile'];
    if (profile is Map) {
      final name = profile['displayName'];
      if (name is String && name.isNotEmpty) {
        await _auth.updateDisplayName(name);
      }
      final avatar = profile['avatarIndex'];
      if (avatar is int) {
        await _auth.updateAvatarIndex(avatar);
      }
    }

    // --- Solde wallet (si inclus dans le blob) ---
    final wallet = data['wallet'];
    if (wallet is Map) {
      final balance = (wallet['balanceSteps'] as num?)?.toInt() ?? 0;
      final earned = (wallet['lifetimeEarnedSteps'] as num?)?.toInt() ?? 0;
      final spent = (wallet['lifetimeSpentSteps'] as num?)?.toInt() ?? 0;
      await _wallet.restoreSnapshot(
        WalletSnapshot(
          balanceSteps: balance,
          lifetimeEarnedSteps: earned,
          lifetimeSpentSteps: spent,
        ),
      );
    }
  }
}

/// Provider Riverpod du service de coffre compte (profil + wallet).
final accountVaultServiceProvider = Provider<AccountVaultService>((ref) {
  return AccountVaultService(
    vault: ref.watch(secureVaultServiceProvider),
    auth: ref.watch(authServiceProvider),
    wallet: ref.watch(walletStoreProvider),
  );
});
