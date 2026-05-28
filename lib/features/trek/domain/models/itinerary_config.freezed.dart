// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ItineraryConfig _$ItineraryConfigFromJson(Map<String, dynamic> json) {
  return _ItineraryConfig.fromJson(json);
}

/// @nodoc
mixin _$ItineraryConfig {
  /// Distance maximale par jour en km
  double get maxKmPerDay => throw _privateConstructorUsedError;

  /// Duree maximale de marche par jour en heures
  double get maxHoursPerDay => throw _privateConstructorUsedError;

  /// Date de depart du trek
  DateTime get startDate => throw _privateConstructorUsedError;

  /// Niveau de difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  String get difficultyLevel => throw _privateConstructorUsedError;

  /// Serializes this ItineraryConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ItineraryConfigCopyWith<ItineraryConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ItineraryConfigCopyWith<$Res> {
  factory $ItineraryConfigCopyWith(
          ItineraryConfig value, $Res Function(ItineraryConfig) then) =
      _$ItineraryConfigCopyWithImpl<$Res, ItineraryConfig>;
  @useResult
  $Res call(
      {double maxKmPerDay,
      double maxHoursPerDay,
      DateTime startDate,
      String difficultyLevel});
}

/// @nodoc
class _$ItineraryConfigCopyWithImpl<$Res, $Val extends ItineraryConfig>
    implements $ItineraryConfigCopyWith<$Res> {
  _$ItineraryConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? startDate = null,
    Object? difficultyLevel = null,
  }) {
    return _then(_value.copyWith(
      maxKmPerDay: null == maxKmPerDay
          ? _value.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _value.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyLevel: null == difficultyLevel
          ? _value.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ItineraryConfigImplCopyWith<$Res>
    implements $ItineraryConfigCopyWith<$Res> {
  factory _$$ItineraryConfigImplCopyWith(_$ItineraryConfigImpl value,
          $Res Function(_$ItineraryConfigImpl) then) =
      __$$ItineraryConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double maxKmPerDay,
      double maxHoursPerDay,
      DateTime startDate,
      String difficultyLevel});
}

/// @nodoc
class __$$ItineraryConfigImplCopyWithImpl<$Res>
    extends _$ItineraryConfigCopyWithImpl<$Res, _$ItineraryConfigImpl>
    implements _$$ItineraryConfigImplCopyWith<$Res> {
  __$$ItineraryConfigImplCopyWithImpl(
      _$ItineraryConfigImpl _value, $Res Function(_$ItineraryConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? startDate = null,
    Object? difficultyLevel = null,
  }) {
    return _then(_$ItineraryConfigImpl(
      maxKmPerDay: null == maxKmPerDay
          ? _value.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _value.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _value.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyLevel: null == difficultyLevel
          ? _value.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ItineraryConfigImpl extends _ItineraryConfig {
  const _$ItineraryConfigImpl(
      {required this.maxKmPerDay,
      required this.maxHoursPerDay,
      required this.startDate,
      this.difficultyLevel = 'moderate'})
      : super._();

  factory _$ItineraryConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItineraryConfigImplFromJson(json);

  /// Distance maximale par jour en km
  @override
  final double maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  final double maxHoursPerDay;

  /// Date de depart du trek
  @override
  final DateTime startDate;

  /// Niveau de difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  @override
  @JsonKey()
  final String difficultyLevel;

  @override
  String toString() {
    return 'ItineraryConfig(maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, startDate: $startDate, difficultyLevel: $difficultyLevel)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItineraryConfigImpl &&
            (identical(other.maxKmPerDay, maxKmPerDay) ||
                other.maxKmPerDay == maxKmPerDay) &&
            (identical(other.maxHoursPerDay, maxHoursPerDay) ||
                other.maxHoursPerDay == maxHoursPerDay) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, maxKmPerDay, maxHoursPerDay, startDate, difficultyLevel);

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItineraryConfigImplCopyWith<_$ItineraryConfigImpl> get copyWith =>
      __$$ItineraryConfigImplCopyWithImpl<_$ItineraryConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ItineraryConfigImplToJson(
      this,
    );
  }
}

abstract class _ItineraryConfig extends ItineraryConfig {
  const factory _ItineraryConfig(
      {required final double maxKmPerDay,
      required final double maxHoursPerDay,
      required final DateTime startDate,
      final String difficultyLevel}) = _$ItineraryConfigImpl;
  const _ItineraryConfig._() : super._();

  factory _ItineraryConfig.fromJson(Map<String, dynamic> json) =
      _$ItineraryConfigImpl.fromJson;

  /// Distance maximale par jour en km
  @override
  double get maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  double get maxHoursPerDay;

  /// Date de depart du trek
  @override
  DateTime get startDate;

  /// Niveau de difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  @override
  String get difficultyLevel;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItineraryConfigImplCopyWith<_$ItineraryConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
