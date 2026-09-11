// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TrainingPlan _$TrainingPlanFromJson(Map<String, dynamic> json) =>
    _TrainingPlan(
      trailId: json['trailId'] as String,
      durationWeeks: (json['durationWeeks'] as num?)?.toInt() ?? 8,
      phases:
          (json['phases'] as List<dynamic>?)
              ?.map((e) => TrainingPhase.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TrainingPhase>[],
      objective: json['objective'] == null
          ? null
          : TrainingObjective.fromJson(
              json['objective'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$TrainingPlanToJson(_TrainingPlan instance) =>
    <String, dynamic>{
      'trailId': instance.trailId,
      'durationWeeks': instance.durationWeeks,
      'phases': instance.phases.map((e) => e.toJson()).toList(),
      'objective': instance.objective?.toJson(),
    };

_TrainingPhase _$TrainingPhaseFromJson(Map<String, dynamic> json) =>
    _TrainingPhase(
      id: json['id'] as String,
      weekStart: (json['weekStart'] as num).toInt(),
      weekEnd: (json['weekEnd'] as num).toInt(),
      icon: json['icon'] as String? ?? 'directions_walk',
      titleFr: json['titleFr'] as String,
      titleEn: json['titleEn'] as String? ?? '',
      titleDe: json['titleDe'] as String? ?? '',
      titleIt: json['titleIt'] as String? ?? '',
      titleEs: json['titleEs'] as String? ?? '',
      subtitleFr: json['subtitleFr'] as String? ?? '',
      subtitleEn: json['subtitleEn'] as String? ?? '',
      subtitleDe: json['subtitleDe'] as String? ?? '',
      subtitleIt: json['subtitleIt'] as String? ?? '',
      subtitleEs: json['subtitleEs'] as String? ?? '',
      sessions:
          (json['sessions'] as List<dynamic>?)
              ?.map((e) => TrainingSession.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TrainingSession>[],
    );

Map<String, dynamic> _$TrainingPhaseToJson(_TrainingPhase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'weekStart': instance.weekStart,
      'weekEnd': instance.weekEnd,
      'icon': instance.icon,
      'titleFr': instance.titleFr,
      'titleEn': instance.titleEn,
      'titleDe': instance.titleDe,
      'titleIt': instance.titleIt,
      'titleEs': instance.titleEs,
      'subtitleFr': instance.subtitleFr,
      'subtitleEn': instance.subtitleEn,
      'subtitleDe': instance.subtitleDe,
      'subtitleIt': instance.subtitleIt,
      'subtitleEs': instance.subtitleEs,
      'sessions': instance.sessions.map((e) => e.toJson()).toList(),
    };

_TrainingSession _$TrainingSessionFromJson(Map<String, dynamic> json) =>
    _TrainingSession(
      id: json['id'] as String,
      labelFr: json['labelFr'] as String,
      labelEn: json['labelEn'] as String? ?? '',
      labelDe: json['labelDe'] as String? ?? '',
      labelIt: json['labelIt'] as String? ?? '',
      labelEs: json['labelEs'] as String? ?? '',
    );

Map<String, dynamic> _$TrainingSessionToJson(_TrainingSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelFr': instance.labelFr,
      'labelEn': instance.labelEn,
      'labelDe': instance.labelDe,
      'labelIt': instance.labelIt,
      'labelEs': instance.labelEs,
    };

_TrainingObjective _$TrainingObjectiveFromJson(Map<String, dynamic> json) =>
    _TrainingObjective(
      labelFr: json['labelFr'] as String,
      labelEn: json['labelEn'] as String? ?? '',
      labelDe: json['labelDe'] as String? ?? '',
      labelIt: json['labelIt'] as String? ?? '',
      labelEs: json['labelEs'] as String? ?? '',
    );

Map<String, dynamic> _$TrainingObjectiveToJson(_TrainingObjective instance) =>
    <String, dynamic>{
      'labelFr': instance.labelFr,
      'labelEn': instance.labelEn,
      'labelDe': instance.labelDe,
      'labelIt': instance.labelIt,
      'labelEs': instance.labelEs,
    };
