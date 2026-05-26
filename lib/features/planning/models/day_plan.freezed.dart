// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

DayPlan _$DayPlanFromJson(Map<String, dynamic> json) {
  return _DayPlan.fromJson(json);
}

/// @nodoc
mixin _$DayPlan {
  /// Numéro du jour (1-indexed)
  int get dayNumber => throw _privateConstructorUsedError;

  /// Liste des étapes prévues ce jour
  List<StageModel> get stages => throw _privateConstructorUsedError;

  /// Distance totale en km pour ce jour
  double get totalDistanceKm => throw _privateConstructorUsedError;

  /// Dénivelé positif total en mètres pour ce jour
  int get totalElevationGainM => throw _privateConstructorUsedError;

  /// Durée estimée en heures (distance/4 + D+/400)
  double get estimatedDurationHours => throw _privateConstructorUsedError;

  /// True si c'est un jour de repos (aucune étape)
  bool get isRestDay => throw _privateConstructorUsedError;

  /// Serializes this DayPlan to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DayPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DayPlanCopyWith<DayPlan> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DayPlanCopyWith<$Res> {
  factory $DayPlanCopyWith(DayPlan value, $Res Function(DayPlan) then) =
      _$DayPlanCopyWithImpl<$Res, DayPlan>;
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistanceKm,
      int totalElevationGainM,
      double estimatedDurationHours,
      bool isRestDay});
}

/// @nodoc
class _$DayPlanCopyWithImpl<$Res, $Val extends DayPlan>
    implements $DayPlanCopyWith<$Res> {
  _$DayPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DayPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistanceKm = null,
    Object? totalElevationGainM = null,
    Object? estimatedDurationHours = null,
    Object? isRestDay = null,
  }) {
    return _then(_value.copyWith(
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      stages: null == stages
          ? _value.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageModel>,
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGainM: null == totalElevationGainM
          ? _value.totalElevationGainM
          : totalElevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedDurationHours: null == estimatedDurationHours
          ? _value.estimatedDurationHours
          : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
              as double,
      isRestDay: null == isRestDay
          ? _value.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DayPlanImplCopyWith<$Res> implements $DayPlanCopyWith<$Res> {
  factory _$$DayPlanImplCopyWith(
          _$DayPlanImpl value, $Res Function(_$DayPlanImpl) then) =
      __$$DayPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistanceKm,
      int totalElevationGainM,
      double estimatedDurationHours,
      bool isRestDay});
}

/// @nodoc
class __$$DayPlanImplCopyWithImpl<$Res>
    extends _$DayPlanCopyWithImpl<$Res, _$DayPlanImpl>
    implements _$$DayPlanImplCopyWith<$Res> {
  __$$DayPlanImplCopyWithImpl(
      _$DayPlanImpl _value, $Res Function(_$DayPlanImpl) _then)
      : super(_value, _then);

  /// Create a copy of DayPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistanceKm = null,
    Object? totalElevationGainM = null,
    Object? estimatedDurationHours = null,
    Object? isRestDay = null,
  }) {
    return _then(_$DayPlanImpl(
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      stages: null == stages
          ? _value._stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageModel>,
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGainM: null == totalElevationGainM
          ? _value.totalElevationGainM
          : totalElevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedDurationHours: null == estimatedDurationHours
          ? _value.estimatedDurationHours
          : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
              as double,
      isRestDay: null == isRestDay
          ? _value.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DayPlanImpl extends _DayPlan {
  const _$DayPlanImpl(
      {required this.dayNumber,
      required final List<StageModel> stages,
      required this.totalDistanceKm,
      required this.totalElevationGainM,
      required this.estimatedDurationHours,
      required this.isRestDay})
      : _stages = stages,
        super._();

  factory _$DayPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$DayPlanImplFromJson(json);

  /// Numéro du jour (1-indexed)
  @override
  final int dayNumber;

  /// Liste des étapes prévues ce jour
  final List<StageModel> _stages;

  /// Liste des étapes prévues ce jour
  @override
  List<StageModel> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  /// Distance totale en km pour ce jour
  @override
  final double totalDistanceKm;

  /// Dénivelé positif total en mètres pour ce jour
  @override
  final int totalElevationGainM;

  /// Durée estimée en heures (distance/4 + D+/400)
  @override
  final double estimatedDurationHours;

  /// True si c'est un jour de repos (aucune étape)
  @override
  final bool isRestDay;

  @override
  String toString() {
    return 'DayPlan(dayNumber: $dayNumber, stages: $stages, totalDistanceKm: $totalDistanceKm, totalElevationGainM: $totalElevationGainM, estimatedDurationHours: $estimatedDurationHours, isRestDay: $isRestDay)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DayPlanImpl &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            const DeepCollectionEquality().equals(other._stages, _stages) &&
            (identical(other.totalDistanceKm, totalDistanceKm) ||
                other.totalDistanceKm == totalDistanceKm) &&
            (identical(other.totalElevationGainM, totalElevationGainM) ||
                other.totalElevationGainM == totalElevationGainM) &&
            (identical(other.estimatedDurationHours, estimatedDurationHours) ||
                other.estimatedDurationHours == estimatedDurationHours) &&
            (identical(other.isRestDay, isRestDay) ||
                other.isRestDay == isRestDay));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayNumber,
      const DeepCollectionEquality().hash(_stages),
      totalDistanceKm,
      totalElevationGainM,
      estimatedDurationHours,
      isRestDay);

  /// Create a copy of DayPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DayPlanImplCopyWith<_$DayPlanImpl> get copyWith =>
      __$$DayPlanImplCopyWithImpl<_$DayPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DayPlanImplToJson(
      this,
    );
  }
}

abstract class _DayPlan extends DayPlan {
  const factory _DayPlan(
      {required final int dayNumber,
      required final List<StageModel> stages,
      required final double totalDistanceKm,
      required final int totalElevationGainM,
      required final double estimatedDurationHours,
      required final bool isRestDay}) = _$DayPlanImpl;
  const _DayPlan._() : super._();

  factory _DayPlan.fromJson(Map<String, dynamic> json) = _$DayPlanImpl.fromJson;

  /// Numéro du jour (1-indexed)
  @override
  int get dayNumber;

  /// Liste des étapes prévues ce jour
  @override
  List<StageModel> get stages;

  /// Distance totale en km pour ce jour
  @override
  double get totalDistanceKm;

  /// Dénivelé positif total en mètres pour ce jour
  @override
  int get totalElevationGainM;

  /// Durée estimée en heures (distance/4 + D+/400)
  @override
  double get estimatedDurationHours;

  /// True si c'est un jour de repos (aucune étape)
  @override
  bool get isRestDay;

  /// Create a copy of DayPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DayPlanImplCopyWith<_$DayPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
