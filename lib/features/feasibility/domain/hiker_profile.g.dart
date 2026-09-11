// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hiker_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HikerProfile _$HikerProfileFromJson(Map<String, dynamic> json) =>
    _HikerProfile(
      age: (json['age'] as num?)?.toInt() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      sex: json['sex'] as String?,
      countryIso: json['countryIso'] as String? ?? '',
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$HikerProfileToJson(_HikerProfile instance) =>
    <String, dynamic>{
      'age': instance.age,
      'heightCm': instance.heightCm,
      'weightKg': instance.weightKg,
      'sex': instance.sex,
      'countryIso': instance.countryIso,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
