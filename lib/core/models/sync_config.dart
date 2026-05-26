import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_config.freezed.dart';
part 'sync_config.g.dart';

/// Configuration de la synchronisation cloud des donnees utilisateur.
///
/// Definit les parametres de sync : intervalle batch, triggers
/// automatiques (arrivee refuge, retour reseau), et retries.
/// Persiste via SharedPreferences.
@freezed
class SyncConfig with _$SyncConfig {
  const factory SyncConfig({
    /// Intervalle en minutes entre deux syncs batch (defaut 60)
    @Default(60) int batchIntervalMinutes,

    /// Sync automatique a l arrivee dans un refuge
    @Default(true) bool syncOnRefugeArrival,

    /// Sync automatique au retour de la connectivite
    @Default(true) bool syncOnReconnect,

    /// Nombre max de tentatives en cas d echec
    @Default(3) int maxRetries,

    /// Timestamp ISO 8601 de la derniere sync reussie (nullable)
    String? lastSyncTimestamp,
  }) = _SyncConfig;

  /// Deserialisation depuis JSON
  factory SyncConfig.fromJson(Map<String, dynamic> json) =>
      _$SyncConfigFromJson(json);
}
