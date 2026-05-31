// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trek_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrekSession {

/// Identifiant unique (UUID)
 String get id;/// Identifiant du sentier parcouru
 String get trailId;/// Date/heure de debut
 DateTime get startedAt;/// Date/heure de fin (null si en cours)
 DateTime? get finishedAt;/// Statut — String extensible (active, paused, completed, abandoned, ...)
 String get status;
/// Create a copy of TrekSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrekSessionCopyWith<TrekSession> get copyWith => _$TrekSessionCopyWithImpl<TrekSession>(this as TrekSession, _$identity);

  /// Serializes this TrekSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrekSession&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,startedAt,finishedAt,status);

@override
String toString() {
  return 'TrekSession(id: $id, trailId: $trailId, startedAt: $startedAt, finishedAt: $finishedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class $TrekSessionCopyWith<$Res>  {
  factory $TrekSessionCopyWith(TrekSession value, $Res Function(TrekSession) _then) = _$TrekSessionCopyWithImpl;
@useResult
$Res call({
 String id, String trailId, DateTime startedAt, DateTime? finishedAt, String status
});




}
/// @nodoc
class _$TrekSessionCopyWithImpl<$Res>
    implements $TrekSessionCopyWith<$Res> {
  _$TrekSessionCopyWithImpl(this._self, this._then);

  final TrekSession _self;
  final $Res Function(TrekSession) _then;

/// Create a copy of TrekSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trailId = null,Object? startedAt = null,Object? finishedAt = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TrekSession].
extension TrekSessionPatterns on TrekSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrekSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrekSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrekSession value)  $default,){
final _that = this;
switch (_that) {
case _TrekSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrekSession value)?  $default,){
final _that = this;
switch (_that) {
case _TrekSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String trailId,  DateTime startedAt,  DateTime? finishedAt,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrekSession() when $default != null:
return $default(_that.id,_that.trailId,_that.startedAt,_that.finishedAt,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String trailId,  DateTime startedAt,  DateTime? finishedAt,  String status)  $default,) {final _that = this;
switch (_that) {
case _TrekSession():
return $default(_that.id,_that.trailId,_that.startedAt,_that.finishedAt,_that.status);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String trailId,  DateTime startedAt,  DateTime? finishedAt,  String status)?  $default,) {final _that = this;
switch (_that) {
case _TrekSession() when $default != null:
return $default(_that.id,_that.trailId,_that.startedAt,_that.finishedAt,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrekSession extends TrekSession {
  const _TrekSession({required this.id, required this.trailId, required this.startedAt, this.finishedAt, this.status = "active"}): super._();
  factory _TrekSession.fromJson(Map<String, dynamic> json) => _$TrekSessionFromJson(json);

/// Identifiant unique (UUID)
@override final  String id;
/// Identifiant du sentier parcouru
@override final  String trailId;
/// Date/heure de debut
@override final  DateTime startedAt;
/// Date/heure de fin (null si en cours)
@override final  DateTime? finishedAt;
/// Statut — String extensible (active, paused, completed, abandoned, ...)
@override@JsonKey() final  String status;

/// Create a copy of TrekSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrekSessionCopyWith<_TrekSession> get copyWith => __$TrekSessionCopyWithImpl<_TrekSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrekSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrekSession&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.finishedAt, finishedAt) || other.finishedAt == finishedAt)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,startedAt,finishedAt,status);

@override
String toString() {
  return 'TrekSession(id: $id, trailId: $trailId, startedAt: $startedAt, finishedAt: $finishedAt, status: $status)';
}


}

/// @nodoc
abstract mixin class _$TrekSessionCopyWith<$Res> implements $TrekSessionCopyWith<$Res> {
  factory _$TrekSessionCopyWith(_TrekSession value, $Res Function(_TrekSession) _then) = __$TrekSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String trailId, DateTime startedAt, DateTime? finishedAt, String status
});




}
/// @nodoc
class __$TrekSessionCopyWithImpl<$Res>
    implements _$TrekSessionCopyWith<$Res> {
  __$TrekSessionCopyWithImpl(this._self, this._then);

  final _TrekSession _self;
  final $Res Function(_TrekSession) _then;

/// Create a copy of TrekSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trailId = null,Object? startedAt = null,Object? finishedAt = freezed,Object? status = null,}) {
  return _then(_TrekSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,finishedAt: freezed == finishedAt ? _self.finishedAt : finishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
