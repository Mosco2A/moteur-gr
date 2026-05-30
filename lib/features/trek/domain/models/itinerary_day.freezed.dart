// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItineraryDay _$ItineraryDayFromJson(Map<String, dynamic> json) {
  return _ItineraryDay.fromJson(json);
}

/// @nodoc
mixin _$ItineraryDay {
  /// Numero du jour (1-indexed)
  int get dayNumber => throw _privateConstructorUsedError;

  /// Liste des etapes prevues ce jour
  List<StageModel> get stages => throw _privateConstructorUsedError;

  /// Distance totale en km pour ce jour
  double get totalDistance => throw _privateConstructorUsedError;

  /// Denivele positif total en metres pour ce jour
  int get totalElevation => throw _privateConstructorUsedError;

  /// Duree estimee en heures
  double get estimatedHours => throw _privateConstructorUsedError;

  /// Serializes this ItineraryDay to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryDayCopyWith<ItineraryDay> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryDayCopyWith<$Res> {
  factory $ItineraryDayCopyWith(
          ItineraryDay value, $Res Function(ItineraryDay) then) =
      _$ItineraryDayCopyWithImpl<$Res, ItineraryDay>;
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistance,
      int totalElevation,
      double estimatedHours});
}

/// @nodoc
class _$ItineraryDayCopyWithImpl<$Res, $Val extends ItineraryDay>
    implements $ItineraryDayCopyWith<$Res> {
  _$ItineraryDayCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistance = null,
    Object? totalElevation = null,
    Object? estimatedHours = null,
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
      totalDistance: null == totalDistance
          ? _value.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevation: null == totalElevation
          ? _value.totalElevation
          : totalElevation // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedHours: null == estimatedHours
          ? _value.estimatedHours
          : estimatedHours // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryDayImplCopyWith<$Res>
    implements $ItineraryDayCopyWith<$Res> {
  factory _$$ItineraryDayImplCopyWith(
          _$ItineraryDayImpl value, $Res Function(_$ItineraryDayImpl) then) =
      __$$ItineraryDayImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistance,
      int totalElevation,
      double estimatedHours});
}

/// @nodoc
class __$$ItineraryDayImplCopyWithImpl<$Res>
    extends _$ItineraryDayCopyWithImpl<$Res, _$ItineraryDayImpl>
    implements _$$ItineraryDayImplCopyWith<$Res> {
  __$$ItineraryDayImplCopyWithImpl(
      _$ItineraryDayImpl _value, $Res Function(_$ItineraryDayImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistance = null,
    Object? totalElevation = null,
    Object? estimatedHours = null,
  }) {
    return _then(_$ItineraryDayImpl(
      dayNumber: null == dayNumber
          ? _value.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      stages: null == stages
          ? _value._stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageModel>,
      totalDistance: null == totalDistance
          ? _value.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevation: null == totalElevation
          ? _value.totalElevation
          : totalElevation // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedHours: null == estimatedHours
          ? _value.estimatedHours
          : estimatedHours // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryDayImpl extends _ItineraryDay {
  const _$ItineraryDayImpl(
      {required this.dayNumber,
      required final List<StageModel> stages,
      required this.totalDistance,
      required this.totalElevation,
      required this.estimatedHours})
      : _stages = stages,
        super._();

  factory _$ItineraryDayImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryDayImplFromJson(json);

  /// Numero du jour (1-indexed)
  @override
  final int dayNumber;

  /// Liste des etapes prevues ce jour
  final List<StageModel> _stages;

  /// Liste des etapes prevues ce jour
  @override
  List<StageModel> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  /// Distance totale en km pour ce jour
  @override
  final double totalDistance;

  /// Denivele positif total en metres pour ce jour
  @override
  final int totalElevation;

  /// Duree estimee en heures
  @override
  final double estimatedHours;

  @override
  String toString() {
    return 'ItineraryDay(dayNumber: $dayNumber, stages: $stages, totalDistance: $totalDistance, totalElevation: $totalElevation, estimatedHours: $estimatedHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryDayImpl &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            const DeepCollectionEquality().equals(other._stages, _stages) &&
            (identical(other.totalDistance, totalDistance) ||
                other.totalDistance == totalDistance) &&
            (identical(other.totalElevation, totalElevation) ||
                other.totalElevation == totalElevation) &&
            (identical(other.estimatedHours, estimatedHours) ||
                other.estimatedHours == estimatedHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayNumber,
      const DeepCollectionEquality().hash(_stages),
      totalDistance,
      totalElevation,
      estimatedHours);

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryDayImplCopyWith<_$ItineraryDayImpl> get copyWith =>
      __$$ItineraryDayImplCopyWithImpl<_$ItineraryDayImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryDayImplToJson(
      this,
    );
  }
}

abstract class _ItineraryDay extends ItineraryDay {
  const factory _ItineraryDay(
      {required final int dayNumber,
      required final List<StageModel> stages,
      required final double totalDistance,
      required final int totalElevation,
      required final double estimatedHours}) = _$ItineraryDayImpl;
  const _ItineraryDay._() : super._();

  factory _ItineraryDay.fromJson(Map<String, dynamic> json) =
      _$ItineraryDayImpl.fromJson;

  /// Numero du jour (1-indexed)
  @override
  int get dayNumber;

  /// Liste des etapes prevues ce jour
  @override
  List<StageModel> get stages;

  /// Distance totale en km pour ce jour
  @override
  double get totalDistance;

  /// Denivele positif total en metres pour ce jour
  @override
  int get totalElevation;

  /// Duree estimee en heures
  @override
  double get estimatedHours;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryDayImplCopyWith<_$ItineraryDayImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
