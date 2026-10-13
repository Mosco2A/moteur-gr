// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'track_point.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrackPoint {

/// Latitude en degres decimaux
 double get lat;/// Longitude en degres decimaux
 double get lng;/// Altitude en metres
 double get elevation;/// Horodatage du point (GPS ou enregistrement)
 DateTime? get timestamp;
/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrackPointCopyWith<TrackPoint> get copyWith => _$TrackPointCopyWithImpl<TrackPoint>(this as TrackPoint, _$identity);

  /// Serializes this TrackPoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrackPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.elevation, elevation) || other.elevation == elevation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,elevation,timestamp);

@override
String toString() {
  return 'TrackPoint(lat: $lat, lng: $lng, elevation: $elevation, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class $TrackPointCopyWith<$Res>  {
  factory $TrackPointCopyWith(TrackPoint value, $Res Function(TrackPoint) _then) = _$TrackPointCopyWithImpl;
@useResult
$Res call({
 double lat, double lng, double elevation, DateTime? timestamp
});




}
/// @nodoc
class _$TrackPointCopyWithImpl<$Res>
    implements $TrackPointCopyWith<$Res> {
  _$TrackPointCopyWithImpl(this._self, this._then);

  final TrackPoint _self;
  final $Res Function(TrackPoint) _then;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lat = null,Object? lng = null,Object? elevation = null,Object? timestamp = freezed,}) {
  return _then(_self.copyWith(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,elevation: null == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrackPoint].
extension TrackPointPatterns on TrackPoint {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrackPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrackPoint value)  $default,){
final _that = this;
switch (_that) {
case _TrackPoint():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrackPoint value)?  $default,){
final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double lat,  double lng,  double elevation,  DateTime? timestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.elevation,_that.timestamp);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double lat,  double lng,  double elevation,  DateTime? timestamp)  $default,) {final _that = this;
switch (_that) {
case _TrackPoint():
return $default(_that.lat,_that.lng,_that.elevation,_that.timestamp);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double lat,  double lng,  double elevation,  DateTime? timestamp)?  $default,) {final _that = this;
switch (_that) {
case _TrackPoint() when $default != null:
return $default(_that.lat,_that.lng,_that.elevation,_that.timestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrackPoint extends TrackPoint {
  const _TrackPoint({required this.lat, required this.lng, required this.elevation, this.timestamp}): super._();
  factory _TrackPoint.fromJson(Map<String, dynamic> json) => _$TrackPointFromJson(json);

/// Latitude en degres decimaux
@override final  double lat;
/// Longitude en degres decimaux
@override final  double lng;
/// Altitude en metres
@override final  double elevation;
/// Horodatage du point (GPS ou enregistrement)
@override final  DateTime? timestamp;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrackPointCopyWith<_TrackPoint> get copyWith => __$TrackPointCopyWithImpl<_TrackPoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrackPointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrackPoint&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.elevation, elevation) || other.elevation == elevation)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,lat,lng,elevation,timestamp);

@override
String toString() {
  return 'TrackPoint(lat: $lat, lng: $lng, elevation: $elevation, timestamp: $timestamp)';
}


}

/// @nodoc
abstract mixin class _$TrackPointCopyWith<$Res> implements $TrackPointCopyWith<$Res> {
  factory _$TrackPointCopyWith(_TrackPoint value, $Res Function(_TrackPoint) _then) = __$TrackPointCopyWithImpl;
@override @useResult
$Res call({
 double lat, double lng, double elevation, DateTime? timestamp
});




}
/// @nodoc
class __$TrackPointCopyWithImpl<$Res>
    implements _$TrackPointCopyWith<$Res> {
  __$TrackPointCopyWithImpl(this._self, this._then);

  final _TrackPoint _self;
  final $Res Function(_TrackPoint) _then;

/// Create a copy of TrackPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lat = null,Object? lng = null,Object? elevation = null,Object? timestamp = freezed,}) {
  return _then(_TrackPoint(
lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,elevation: null == elevation ? _self.elevation : elevation // ignore: cast_nullable_to_non_nullable
as double,timestamp: freezed == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
