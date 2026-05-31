// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncConfig _$SyncConfigFromJson(Map<String, dynamic> json) => _SyncConfig(
  batchIntervalMinutes: (json['batchIntervalMinutes'] as num?)?.toInt() ?? 60,
  syncOnRefugeArrival: json['syncOnRefugeArrival'] as bool? ?? true,
  syncOnReconnect: json['syncOnReconnect'] as bool? ?? true,
  maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
  lastSyncTimestamp: json['lastSyncTimestamp'] as String?,
);

Map<String, dynamic> _$SyncConfigToJson(_SyncConfig instance) =>
    <String, dynamic>{
      'batchIntervalMinutes': instance.batchIntervalMinutes,
      'syncOnRefugeArrival': instance.syncOnRefugeArrival,
      'syncOnReconnect': instance.syncOnReconnect,
      'maxRetries': instance.maxRetries,
      'lastSyncTimestamp': instance.lastSyncTimestamp,
    };
