// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChecklistItemModel _$ChecklistItemModelFromJson(Map<String, dynamic> json) =>
    _ChecklistItemModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      templateId: json['templateId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      isChecked: json['isChecked'] as bool? ?? false,
      weightGrams: (json['weightGrams'] as num?)?.toInt() ?? 0,
      customNote: json['customNote'] as String?,
    );

Map<String, dynamic> _$ChecklistItemModelToJson(_ChecklistItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'name': instance.name,
      'category': instance.category,
      'isChecked': instance.isChecked,
      'weightGrams': instance.weightGrams,
      'customNote': instance.customNote,
    };
