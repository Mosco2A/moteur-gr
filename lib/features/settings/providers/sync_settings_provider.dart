import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../../../core/models/sync_config.dart";
import "../../../core/services/cloud_sync_service.dart";

/// Cles SharedPreferences pour la config sync cloud.
class SyncSettingsKeys {
  static const String syncEnabled = "sync_cloud_enabled";
  static const String batchInterval = "sync_batch_interval_minutes";
  static const String syncOnRefuge = "sync_on_refuge_arrival";
  static const String syncOnReconnect = "sync_on_reconnect";
  static const String lastSyncTimestamp = "sync_last_timestamp";
  static const String lastSyncStatus = "sync_last_status";
}

/// Etat de la derniere synchronisation.
class SyncStatusInfo {
  const SyncStatusInfo({
    this.lastSyncTimestamp,
    this.lastStatus = CloudSyncStatus.idle,
    this.isEnabled = true,
  });

  final String? lastSyncTimestamp;
  final CloudSyncStatus lastStatus;
  final bool isEnabled;

  SyncStatusInfo copyWith({
    String? lastSyncTimestamp,
    CloudSyncStatus? lastStatus,
    bool? isEnabled,
  }) {
    return SyncStatusInfo(
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      lastStatus: lastStatus ?? this.lastStatus,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Notifier pour la configuration de sync cloud.
class SyncConfigNotifier extends Notifier<SyncConfig> {
  SharedPreferences? _prefs;

  @override
  SyncConfig build() {
    _load();
    return const SyncConfig();
  }

  /// Charge la configuration depuis SharedPreferences.
  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final interval = _prefs?.getInt(SyncSettingsKeys.batchInterval) ?? 60;
    final onRefuge = _prefs?.getBool(SyncSettingsKeys.syncOnRefuge) ?? true;
    final onReconnect = _prefs?.getBool(SyncSettingsKeys.syncOnReconnect) ?? true;
    final lastSync = _prefs?.getString(SyncSettingsKeys.lastSyncTimestamp);

    state = SyncConfig(
      batchIntervalMinutes: interval,
      syncOnRefugeArrival: onRefuge,
      syncOnReconnect: onReconnect,
      lastSyncTimestamp: lastSync,
    );
  }

  /// Met a jour l intervalle batch et persiste.
  void setBatchInterval(int minutes) {
    state = state.copyWith(batchIntervalMinutes: minutes);
    _prefs?.setInt(SyncSettingsKeys.batchInterval, minutes);
  }

  /// Active/desactive la sync a l arrivee refuge.
  void setSyncOnRefuge(bool enabled) {
    state = state.copyWith(syncOnRefugeArrival: enabled);
    _prefs?.setBool(SyncSettingsKeys.syncOnRefuge, enabled);
  }

  /// Active/desactive la sync au retour reseau.
  void setSyncOnReconnect(bool enabled) {
    state = state.copyWith(syncOnReconnect: enabled);
    _prefs?.setBool(SyncSettingsKeys.syncOnReconnect, enabled);
  }

  /// Met a jour le timestamp de derniere sync.
  void updateLastSync(String timestamp) {
    state = state.copyWith(lastSyncTimestamp: timestamp);
    _prefs?.setString(SyncSettingsKeys.lastSyncTimestamp, timestamp);
  }
}

/// Provider de la configuration sync cloud.
final syncConfigProvider =
    NotifierProvider<SyncConfigNotifier, SyncConfig>(SyncConfigNotifier.new);

/// Notifier pour le statut de synchronisation.
class SyncStatusNotifier extends Notifier<SyncStatusInfo> {
  SharedPreferences? _prefs;

  @override
  SyncStatusInfo build() {
    _load();
    return const SyncStatusInfo();
  }

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final timestamp = _prefs?.getString(SyncSettingsKeys.lastSyncTimestamp);
    final statusIndex = _prefs?.getInt(SyncSettingsKeys.lastSyncStatus) ?? 0;
    final enabled = _prefs?.getBool(SyncSettingsKeys.syncEnabled) ?? true;

    state = SyncStatusInfo(
      lastSyncTimestamp: timestamp,
      lastStatus: CloudSyncStatus.values[
          statusIndex.clamp(0, CloudSyncStatus.values.length - 1)],
      isEnabled: enabled,
    );
  }

  /// Met a jour le statut apres une sync.
  void updateStatus(CloudSyncStatus status, {String? timestamp}) {
    state = state.copyWith(
      lastStatus: status,
      lastSyncTimestamp: timestamp ?? state.lastSyncTimestamp,
    );
    _prefs?.setInt(SyncSettingsKeys.lastSyncStatus, status.index);
    if (timestamp != null) {
      _prefs?.setString(SyncSettingsKeys.lastSyncTimestamp, timestamp);
    }
  }

  /// Active/desactive la synchronisation cloud.
  void setEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    _prefs?.setBool(SyncSettingsKeys.syncEnabled, enabled);
  }
}

/// Provider du statut de synchronisation.
final syncStatusProvider =
    NotifierProvider<SyncStatusNotifier, SyncStatusInfo>(
        SyncStatusNotifier.new);

/// Provider pour activer/desactiver la sync cloud.
final toggleSyncProvider = Provider<void Function(bool)>((ref) {
  final notifier = ref.read(syncStatusProvider.notifier);
  return (bool enabled) => notifier.setEnabled(enabled);
});
