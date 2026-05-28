// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feasibility_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeasibilityProfileImpl _$$FeasibilityProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$FeasibilityProfileImpl(
      fitnessLevel: json['fitnessLevel'] as String,
      experience: json['experience'] as String,
      maxKmPerDay: (json['maxKmPerDay'] as num).toDouble(),
      maxHoursPerDay: (json['maxHoursPerDay'] as num).toDouble(),
      groupMode: json['groupMode'] as bool? ?? false,
      groupProfiles: (json['groupProfiles'] as List<dynamic>?)
          ?.map((e) => FeasibilityProfile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$FeasibilityProfileImplToJson(
        _$FeasibilityProfileImpl instance) =>
    <String, dynamic>{
      'fitnessLevel': instance.fitnessLevel,
      'experience': instance.experience,
      'maxKmPerDay': instance.maxKmPerDay,
      'maxHoursPerDay': instance.maxHoursPerDay,
      'groupMode': instance.groupMode,
      'groupProfiles': instance.groupProfiles,
    };
