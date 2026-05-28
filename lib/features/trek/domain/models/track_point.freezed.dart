// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrackPoint _$TrackPointFromJson(Map<String, dynamic> json) {
  return _TrackPoint.fromJson(json);
}

/// @nodoc
mixin _$TrackPoint {
  /// Latitude en degres decimaux
  double get lat => throw _privateConstructorUsedError;

  /// Longitude en degres decimaux
  double get lng => throw _privateConstructorUsedError;

  /// Altitude en metres
  double get elevation => throw _privateConstructorUsedError;

  /// Horodatage du point (nullable si import GPX sans temps)
  DateTime? get timestamp => throw _privateConstructorUsedError;

  /// Serializes this TrackPoint to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrackPointCopyWith<TrackPoint> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrackPointCopyWith<$Res> {
  factory $TrackPointCopyWith(
          TrackPoint value, $Res Function(TrackPoint) then) =
      _$TrackPointCopyWithImpl<$Res, TrackPoint>;
  @useResult
  $Res call({double lat, double lng, double elevation, DateTime? timestamp});
}

/// @nodoc
class _$TrackPointCopyWithImpl<$Res, $Val extends TrackPoint>
    implements $TrackPointCopyWith<$Res> {
  _$TrackPointCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? elevation = null,
    Object? timestamp = freezed,
  }) {
    return _then(_value.copyWith(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      elevation: null == elevation
          ? _value.elevation
          : elevation // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrackPointImplCopyWith<$Res>
    implements $TrackPointCopyWith<$Res> {
  factory _$$TrackPointImplCopyWith(
          _$TrackPointImpl value, $Res Function(_$TrackPointImpl) then) =
      __$$TrackPointImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double lat, double lng, double elevation, DateTime? timestamp});
}

/// @nodoc
class __$$TrackPointImplCopyWithImpl<$Res>
    extends _$TrackPointCopyWithImpl<$Res, _$TrackPointImpl>
    implements _$$TrackPointImplCopyWith<$Res> {
  __$$TrackPointImplCopyWithImpl(
      _$TrackPointImpl _value, $Res Function(_$TrackPointImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lat = null,
    Object? lng = null,
    Object? elevation = null,
    Object? timestamp = freezed,
  }) {
    return _then(_$TrackPointImpl(
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      elevation: null == elevation
          ? _value.elevation
          : elevation // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: freezed == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrackPointImpl implements _TrackPoint {
  const _$TrackPointImpl(
      {required this.lat,
      required this.lng,
      required this.elevation,
      this.timestamp});

  factory _$TrackPointImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrackPointImplFromJson(json);

  /// Latitude en degres decimaux
  @override
  final double lat;

  /// Longitude en degres decimaux
  @override
  final double lng;

  /// Altitude en metres
  @override
  final double elevation;

  /// Horodatage du point (nullable si import GPX sans temps)
  @override
  final DateTime? timestamp;

  @override
  String toString() {
    return 'TrackPoint(lat: $lat, lng: $lng, elevation: $elevation, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrackPointImpl &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.elevation, elevation) ||
                other.elevation == elevation) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, lat, lng, elevation, timestamp);

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrackPointImplCopyWith<_$TrackPointImpl> get copyWith =>
      __$$TrackPointImplCopyWithImpl<_$TrackPointImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrackPointImplToJson(
      this,
    );
  }
}

abstract class _TrackPoint implements TrackPoint {
  const factory _TrackPoint(
      {required final double lat,
      required final double lng,
      required final double elevation,
      final DateTime? timestamp}) = _$TrackPointImpl;

  factory _TrackPoint.fromJson(Map<String, dynamic> json) =
      _$TrackPointImpl.fromJson;

  /// Latitude en degres decimaux
  @override
  double get lat;

  /// Longitude en degres decimaux
  @override
  double get lng;

  /// Altitude en metres
  @override
  double get elevation;

  /// Horodatage du point (nullable si import GPX sans temps)
  @override
  DateTime? get timestamp;

  /// Create a copy of TrackPoint
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrackPointImplCopyWith<_$TrackPointImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
