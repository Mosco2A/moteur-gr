// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'walk_test_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalkTestResult {

/// Distance parcourue en 6 minutes, en metres.
 double get distanceMeters;/// Niveau objectif deduit (voir `WalkTestLevel`).
 String get level;/// Date de realisation du test.
 DateTime get takenAt;
/// Create a copy of WalkTestResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalkTestResultCopyWith<WalkTestResult> get copyWith => _$WalkTestResultCopyWithImpl<WalkTestResult>(this as WalkTestResult, _$identity);

  /// Serializes this WalkTestResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalkTestResult&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.level, level) || other.level == level)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceMeters,level,takenAt);

@override
String toString() {
  return 'WalkTestResult(distanceMeters: $distanceMeters, level: $level, takenAt: $takenAt)';
}


}

/// @nodoc
abstract mixin class $WalkTestResultCopyWith<$Res>  {
  factory $WalkTestResultCopyWith(WalkTestResult value, $Res Function(WalkTestResult) _then) = _$WalkTestResultCopyWithImpl;
@useResult
$Res call({
 double distanceMeters, String level, DateTime takenAt
});




}
/// @nodoc
class _$WalkTestResultCopyWithImpl<$Res>
    implements $WalkTestResultCopyWith<$Res> {
  _$WalkTestResultCopyWithImpl(this._self, this._then);

  final WalkTestResult _self;
  final $Res Function(WalkTestResult) _then;

/// Create a copy of WalkTestResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? distanceMeters = null,Object? level = null,Object? takenAt = null,}) {
  return _then(_self.copyWith(
distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WalkTestResult].
extension WalkTestResultPatterns on WalkTestResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalkTestResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalkTestResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalkTestResult value)  $default,){
final _that = this;
switch (_that) {
case _WalkTestResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalkTestResult value)?  $default,){
final _that = this;
switch (_that) {
case _WalkTestResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double distanceMeters,  String level,  DateTime takenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalkTestResult() when $default != null:
return $default(_that.distanceMeters,_that.level,_that.takenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double distanceMeters,  String level,  DateTime takenAt)  $default,) {final _that = this;
switch (_that) {
case _WalkTestResult():
return $default(_that.distanceMeters,_that.level,_that.takenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double distanceMeters,  String level,  DateTime takenAt)?  $default,) {final _that = this;
switch (_that) {
case _WalkTestResult() when $default != null:
return $default(_that.distanceMeters,_that.level,_that.takenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalkTestResult extends WalkTestResult {
  const _WalkTestResult({required this.distanceMeters, required this.level, required this.takenAt}): super._();
  factory _WalkTestResult.fromJson(Map<String, dynamic> json) => _$WalkTestResultFromJson(json);

/// Distance parcourue en 6 minutes, en metres.
@override final  double distanceMeters;
/// Niveau objectif deduit (voir `WalkTestLevel`).
@override final  String level;
/// Date de realisation du test.
@override final  DateTime takenAt;

/// Create a copy of WalkTestResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalkTestResultCopyWith<_WalkTestResult> get copyWith => __$WalkTestResultCopyWithImpl<_WalkTestResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalkTestResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalkTestResult&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.level, level) || other.level == level)&&(identical(other.takenAt, takenAt) || other.takenAt == takenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,distanceMeters,level,takenAt);

@override
String toString() {
  return 'WalkTestResult(distanceMeters: $distanceMeters, level: $level, takenAt: $takenAt)';
}


}

/// @nodoc
abstract mixin class _$WalkTestResultCopyWith<$Res> implements $WalkTestResultCopyWith<$Res> {
  factory _$WalkTestResultCopyWith(_WalkTestResult value, $Res Function(_WalkTestResult) _then) = __$WalkTestResultCopyWithImpl;
@override @useResult
$Res call({
 double distanceMeters, String level, DateTime takenAt
});




}
/// @nodoc
class __$WalkTestResultCopyWithImpl<$Res>
    implements _$WalkTestResultCopyWith<$Res> {
  __$WalkTestResultCopyWithImpl(this._self, this._then);

  final _WalkTestResult _self;
  final $Res Function(_WalkTestResult) _then;

/// Create a copy of WalkTestResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? distanceMeters = null,Object? level = null,Object? takenAt = null,}) {
  return _then(_WalkTestResult(
distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as double,level: null == level ? _self.level : level // ignore: cast_nullable_to_non_nullable
as String,takenAt: null == takenAt ? _self.takenAt : takenAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
