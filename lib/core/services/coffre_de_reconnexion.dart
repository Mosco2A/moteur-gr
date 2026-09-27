/// ETAT REEL DU COFFRE DE RECONNEXION — DECLARE A UN SEUL ENDROIT (596 C2).
///
/// LE DEFAUT CORRIGE : l'application promettait au randonneur que son code de
/// reconnexion « ouvre son coffre sur un autre telephone », et l'onboarding le
/// poussait a le noter. LE COFFRE N'A JAMAIS ETE ALIMENTE. Mesure, ligne a
/// ligne, dans le code de production :
///
///   * [ecrivainAttendu] — aucun appelant ;
///   * `HealthBackupService.backupToCloud` — aucun appelant ;
///   * [transportAttendu] — appele par le seul `backupToCloud`, lui-meme mort ;
///   * `VaultEnvelope.serialize()` — sa sortie n'est ecrite nulle part ;
///   * [ecranDeSaisieAttendu] — n'existe pas : rien ne permet de SAISIR un code.
///
/// Tout le chiffrement est pourtant complet et correct (AES-GCM-256, PBKDF2,
/// restauration reelle cote [AccountVaultService] et [RestoreService]). Ce qui
/// manque n'est pas la serrure, c'est le contenu du coffre — et le camion qui
/// l'y porte.
///
/// POURQUOI UNE CONSTANTE PLUTOT QU'UNE MESURE A L'EXECUTION : « le coffre
/// est-il alimente ? » n'est pas une question de disponibilite reseau, c'est
/// une question sur le CODE lui-meme. Une garde branchee sur la disponibilite
/// Firebase aurait remis la promesse en place le jour ou Chris configure le
/// cloud — alors que le coffre serait toujours vide. Le mensonge serait revenu
/// tout seul.
///
/// CETTE DECLARATION NE PEUT PAS MENTIR LONGTEMPS : une invariante
/// (`test/comportement/verite_596_coffre_test.dart`) balaye `lib/` et exige que
/// [alimente] et le nombre reel d'ecrivains disent la meme chose, dans les deux
/// sens. Brancher un ecrivain sans rallumer la promesse echoue ; rallumer la
/// promesse sans ecrivain echoue aussi.
///
/// PERIMETRE RGPD (LOTS J a O) — INTOUCHE. L'effacement prime sur toute
/// restauration et sa garde passe DEVANT celle du consentement article 9. On ne
/// contourne rien ici : on ne remplit pas le coffre, on cesse de promettre.
/// Le jour ou il sera rempli, la garde d'effacement restera en tete de chaque
/// chemin descendant — c'est deja le cas, et c'est teste.
abstract final class CoffreDeReconnexion {
  /// Vrai quand le coffre est REELLEMENT alimente par du code de production.
  ///
  /// Tant que c'est faux, l'application ne promet pas de rouvrir quoi que ce
  /// soit ailleurs et ne fabrique meme pas de code (un secret qui n'ouvre rien
  /// est un secret de trop — et il faudrait l'effacer avec les autres).
  static const bool alimente = false;

  /// Ce qui doit ecrire le contenu chiffre du coffre.
  static const String ecrivainAttendu =
      'AccountVaultService.exportWithCode (lib/features/auth/data/account_vault_service.dart)';

  /// Ce qui doit porter le contenu chiffre jusqu'au coffre distant.
  static const String transportAttendu =
      'CloudSyncService.pushEncryptedBackup (lib/core/services/cloud_sync_service.dart) '
      '— exige un projet Firebase configure ET une regle firestore pour '
      'users/{hash}/secure_backup/{docKey}, qui n\'existe pas encore';

  /// Ce qui doit permettre au randonneur de SAISIR son code sur le nouveau
  /// telephone. Sans cet ecran, meme un coffre rempli resterait inaccessible.
  static const String ecranDeSaisieAttendu =
      'un ecran de saisie du code de reconnexion — aucune route ni aucun champ '
      'de saisie n\'existe aujourd\'hui (seul /recovery-code, en lecture)';
}
