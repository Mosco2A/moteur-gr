// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'follower_slot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FollowerSlot {

 String get id; String get sessionId; String get followerName; bool get isPaid; bool get adSupported;
/// Create a copy of FollowerSlot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FollowerSlotCopyWith<FollowerSlot> get copyWith => _$FollowerSlotCopyWithImpl<FollowerSlot>(this as FollowerSlot, _$identity);

  /// Serializes this FollowerSlot to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FollowerSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.followerName, followerName) || other.followerName == followerName)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.adSupported, adSupported) || other.adSupported == adSupported));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,followerName,isPaid,adSupported);

@override
String toString() {
  return 'FollowerSlot(id: $id, sessionId: $sessionId, followerName: $followerName, isPaid: $isPaid, adSupported: $adSupported)';
}


}

/// @nodoc
abstract mixin class $FollowerSlotCopyWith<$Res>  {
  factory $FollowerSlotCopyWith(FollowerSlot value, $Res Function(FollowerSlot) _then) = _$FollowerSlotCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String followerName, bool isPaid, bool adSupported
});




}
/// @nodoc
class _$FollowerSlotCopyWithImpl<$Res>
    implements $FollowerSlotCopyWith<$Res> {
  _$FollowerSlotCopyWithImpl(this._self, this._then);

  final FollowerSlot _self;
  final $Res Function(FollowerSlot) _then;

/// Create a copy of FollowerSlot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? followerName = null,Object? isPaid = null,Object? adSupported = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,followerName: null == followerName ? _self.followerName : followerName // ignore: cast_nullable_to_non_nullable
as String,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,adSupported: null == adSupported ? _self.adSupported : adSupported // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [FollowerSlot].
extension FollowerSlotPatterns on FollowerSlot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FollowerSlot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FollowerSlot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FollowerSlot value)  $default,){
final _that = this;
switch (_that) {
case _FollowerSlot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FollowerSlot value)?  $default,){
final _that = this;
switch (_that) {
case _FollowerSlot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String followerName,  bool isPaid,  bool adSupported)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FollowerSlot() when $default != null:
return $default(_that.id,_that.sessionId,_that.followerName,_that.isPaid,_that.adSupported);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String followerName,  bool isPaid,  bool adSupported)  $default,) {final _that = this;
switch (_that) {
case _FollowerSlot():
return $default(_that.id,_that.sessionId,_that.followerName,_that.isPaid,_that.adSupported);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String followerName,  bool isPaid,  bool adSupported)?  $default,) {final _that = this;
switch (_that) {
case _FollowerSlot() when $default != null:
return $default(_that.id,_that.sessionId,_that.followerName,_that.isPaid,_that.adSupported);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FollowerSlot implements FollowerSlot {
  const _FollowerSlot({required this.id, required this.sessionId, required this.followerName, this.isPaid = false, this.adSupported = false});
  factory _FollowerSlot.fromJson(Map<String, dynamic> json) => _$FollowerSlotFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String followerName;
@override@JsonKey() final  bool isPaid;
@override@JsonKey() final  bool adSupported;

/// Create a copy of FollowerSlot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FollowerSlotCopyWith<_FollowerSlot> get copyWith => __$FollowerSlotCopyWithImpl<_FollowerSlot>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FollowerSlotToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FollowerSlot&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.followerName, followerName) || other.followerName == followerName)&&(identical(other.isPaid, isPaid) || other.isPaid == isPaid)&&(identical(other.adSupported, adSupported) || other.adSupported == adSupported));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,followerName,isPaid,adSupported);

@override
String toString() {
  return 'FollowerSlot(id: $id, sessionId: $sessionId, followerName: $followerName, isPaid: $isPaid, adSupported: $adSupported)';
}


}

/// @nodoc
abstract mixin class _$FollowerSlotCopyWith<$Res> implements $FollowerSlotCopyWith<$Res> {
  factory _$FollowerSlotCopyWith(_FollowerSlot value, $Res Function(_FollowerSlot) _then) = __$FollowerSlotCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String followerName, bool isPaid, bool adSupported
});




}
/// @nodoc
class __$FollowerSlotCopyWithImpl<$Res>
    implements _$FollowerSlotCopyWith<$Res> {
  __$FollowerSlotCopyWithImpl(this._self, this._then);

  final _FollowerSlot _self;
  final $Res Function(_FollowerSlot) _then;

/// Create a copy of FollowerSlot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? followerName = null,Object? isPaid = null,Object? adSupported = null,}) {
  return _then(_FollowerSlot(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,followerName: null == followerName ? _self.followerName : followerName // ignore: cast_nullable_to_non_nullable
as String,isPaid: null == isPaid ? _self.isPaid : isPaid // ignore: cast_nullable_to_non_nullable
as bool,adSupported: null == adSupported ? _self.adSupported : adSupported // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
