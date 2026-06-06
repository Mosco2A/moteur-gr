// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthInfo _$HealthInfoFromJson(Map<String, dynamic> json) => _HealthInfo(
  bloodType: json['bloodType'] as String? ?? '',
  allergies: json['allergies'] as String? ?? '',
  treatments: json['treatments'] as String? ?? '',
  doctorContact: json['doctorContact'] as String? ?? '',
  insuranceNumber: json['insuranceNumber'] as String? ?? '',
);

Map<String, dynamic> _$HealthInfoToJson(_HealthInfo instance) =>
    <String, dynamic>{
      'bloodType': instance.bloodType,
      'allergies': instance.allergies,
      'treatments': instance.treatments,
      'doctorContact': instance.doctorContact,
      'insuranceNumber': instance.insuranceNumber,
    };
