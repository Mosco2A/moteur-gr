// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follow_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowSession {

 String get id; String get trekkerUserId; String get shareCode; String get createdAt; String get expiresAt; bool get isActive;
/// Create a copy of FollowSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowSessionCopyWith<FollowSession> get copyWith => _$FollowSessionCopyWithImpl<FollowSession>(this as FollowSession, _$identity);

  /// Serializes this FollowSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowSession&&(identical(other.id, id) || other.id == id)&&(identical(other.trekkerUserId, trekkerUserId) || other.trekkerUserId == trekkerUserId)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trekkerUserId,shareCode,createdAt,expiresAt,isActive);

@override
String toString() {
  return 'FollowSession(id: $id, trekkerUserId: $trekkerUserId, shareCode: $shareCode, createdAt: $createdAt, expiresAt: $expiresAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $FollowSessionCopyWith<$Res>  {
  factory $FollowSessionCopyWith(FollowSession value, $Res Function(FollowSession) _then) = _$FollowSessionCopyWithImpl;
@useResult
$Res call({
 String id, String trekkerUserId, String shareCode, String createdAt, String expiresAt, bool isActive
});




}
/// @nodoc
class _$FollowSessionCopyWithImpl<$Res>
    implements $FollowSessionCopyWith<$Res> {
  _$FollowSessionCopyWithImpl(this._self, this._then);

  final FollowSession _self;
  final $Res Function(FollowSession) _then;

/// Create a copy of FollowSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trekkerUserId = null,Object? shareCode = null,Object? createdAt = null,Object? expiresAt = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trekkerUserId: null == trekkerUserId ? _self.trekkerUserId : trekkerUserId // ignore: cast_nullable_to_non_nullable
as String,shareCode: null == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowSession].
extension FollowSessionPatterns on FollowSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowSession value)  $default,){
final _that = this;
switch (_that) {
case _FollowSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowSession value)?  $default,){
final _that = this;
switch (_that) {
case _FollowSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String trekkerUserId,  String shareCode,  String createdAt,  String expiresAt,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowSession() when $default != null:
return $default(_that.id,_that.trekkerUserId,_that.shareCode,_that.createdAt,_that.expiresAt,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String trekkerUserId,  String shareCode,  String createdAt,  String expiresAt,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _FollowSession():
return $default(_that.id,_that.trekkerUserId,_that.shareCode,_that.createdAt,_that.expiresAt,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String trekkerUserId,  String shareCode,  String createdAt,  String expiresAt,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _FollowSession() when $default != null:
return $default(_that.id,_that.trekkerUserId,_that.shareCode,_that.createdAt,_that.expiresAt,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowSession implements FollowSession {
  const _FollowSession({required this.id, required this.trekkerUserId, required this.shareCode, required this.createdAt, required this.expiresAt, this.isActive = true});
  factory _FollowSession.fromJson(Map<String, dynamic> json) => _$FollowSessionFromJson(json);

@override final  String id;
@override final  String trekkerUserId;
@override final  String shareCode;
@override final  String createdAt;
@override final  String expiresAt;
@override@JsonKey() final  bool isActive;

/// Create a copy of FollowSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowSessionCopyWith<_FollowSession> get copyWith => __$FollowSessionCopyWithImpl<_FollowSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowSession&&(identical(other.id, id) || other.id == id)&&(identical(other.trekkerUserId, trekkerUserId) || other.trekkerUserId == trekkerUserId)&&(identical(other.shareCode, shareCode) || other.shareCode == shareCode)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trekkerUserId,shareCode,createdAt,expiresAt,isActive);

@override
String toString() {
  return 'FollowSession(id: $id, trekkerUserId: $trekkerUserId, shareCode: $shareCode, createdAt: $createdAt, expiresAt: $expiresAt, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$FollowSessionCopyWith<$Res> implements $FollowSessionCopyWith<$Res> {
  factory _$FollowSessionCopyWith(_FollowSession value, $Res Function(_FollowSession) _then) = __$FollowSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String trekkerUserId, String shareCode, String createdAt, String expiresAt, bool isActive
});




}
/// @nodoc
class __$FollowSessionCopyWithImpl<$Res>
    implements _$FollowSessionCopyWith<$Res> {
  __$FollowSessionCopyWithImpl(this._self, this._then);

  final _FollowSession _self;
  final $Res Function(_FollowSession) _then;

/// Create a copy of FollowSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trekkerUserId = null,Object? shareCode = null,Object? createdAt = null,Object? expiresAt = null,Object? isActive = null,}) {
  return _then(_FollowSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trekkerUserId: null == trekkerUserId ? _self.trekkerUserId : trekkerUserId // ignore: cast_nullable_to_non_nullable
as String,shareCode: null == shareCode ? _self.shareCode : shareCode // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
