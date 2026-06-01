// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personalization_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PersonalizationData _$PersonalizationDataFromJson(Map<String, dynamic> json) =>
    _PersonalizationData(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      customName: json['customName'] as String?,
      trekDate: json['trekDate'] as String?,
      stageName: json['stageName'] as String?,
      freeText: json['freeText'] as String?,
      customImagePath: json['customImagePath'] as String?,
    );

Map<String, dynamic> _$PersonalizationDataToJson(
  _PersonalizationData instance,
) => <String, dynamic>{
  'id': instance.id,
  'orderId': instance.orderId,
  'customName': instance.customName,
  'trekDate': instance.trekDate,
  'stageName': instance.stageName,
  'freeText': instance.freeText,
  'customImagePath': instance.customImagePath,
};
