// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JournalEntryModel _$JournalEntryModelFromJson(Map<String, dynamic> json) =>
    _JournalEntryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      trailId: json['trailId'] as String,
      stageNumber: (json['stageNumber'] as num).toInt(),
      text: json['text'] as String? ?? '',
      photoPath: json['photoPath'] as String?,
      photoSizeBytes: (json['photoSizeBytes'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$JournalEntryModelToJson(_JournalEntryModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'trailId': instance.trailId,
      'stageNumber': instance.stageNumber,
      'text': instance.text,
      'photoPath': instance.photoPath,
      'photoSizeBytes': instance.photoSizeBytes,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
