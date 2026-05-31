// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DownloadProgress _$DownloadProgressFromJson(Map<String, dynamic> json) =>
    _DownloadProgress(
      trailId: json['trailId'] as String,
      status: json['status'] as String,
      bytesDownloaded: (json['bytesDownloaded'] as num).toInt(),
      totalBytes: (json['totalBytes'] as num).toInt(),
      currentStep: json['currentStep'] as String,
      error: json['error'] as String?,
    );

Map<String, dynamic> _$DownloadProgressToJson(_DownloadProgress instance) =>
    <String, dynamic>{
      'trailId': instance.trailId,
      'status': instance.status,
      'bytesDownloaded': instance.bytesDownloaded,
      'totalBytes': instance.totalBytes,
      'currentStep': instance.currentStep,
      'error': instance.error,
    };
