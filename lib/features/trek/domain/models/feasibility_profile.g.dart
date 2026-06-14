// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feasibility_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FeasibilityProfile _$FeasibilityProfileFromJson(Map<String, dynamic> json) =>
    _FeasibilityProfile(
      fitnessLevel: json['fitnessLevel'] as String,
      experience: json['experience'] as String,
      maxKmPerDay: (json['maxKmPerDay'] as num).toDouble(),
      maxHoursPerDay: (json['maxHoursPerDay'] as num).toDouble(),
      groupMode: json['groupMode'] as bool? ?? false,
      groupProfiles: (json['groupProfiles'] as List<dynamic>?)
          ?.map((e) => FeasibilityProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$FeasibilityProfileToJson(_FeasibilityProfile instance) =>
    <String, dynamic>{
      'fitnessLevel': instance.fitnessLevel,
      'experience': instance.experience,
      'maxKmPerDay': instance.maxKmPerDay,
      'maxHoursPerDay': instance.maxHoursPerDay,
      'groupMode': instance.groupMode,
      'groupProfiles': instance.groupProfiles?.map((e) => e.toJson()).toList(),
    };
