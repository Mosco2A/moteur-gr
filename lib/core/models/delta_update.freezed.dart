// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delta_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeltaUpdate {

/// Identifiant du sentier concerne
 String get trailId;/// Version locale actuelle (point de depart du delta)
 int get fromVersion;/// Version cible apres application du delta
 int get toVersion;/// Liste des tables modifiees entre les deux versions
 List<String> get changedTables;/// Taille du delta en octets (pour affichage/estimation)
 int get downloadSize;
/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeltaUpdateCopyWith<DeltaUpdate> get copyWith => _$DeltaUpdateCopyWithImpl<DeltaUpdate>(this as DeltaUpdate, _$identity);

  /// Serializes this DeltaUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeltaUpdate&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.fromVersion, fromVersion) || other.fromVersion == fromVersion)&&(identical(other.toVersion, toVersion) || other.toVersion == toVersion)&&const DeepCollectionEquality().equals(other.changedTables, changedTables)&&(identical(other.downloadSize, downloadSize) || other.downloadSize == downloadSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,fromVersion,toVersion,const DeepCollectionEquality().hash(changedTables),downloadSize);

@override
String toString() {
  return 'DeltaUpdate(trailId: $trailId, fromVersion: $fromVersion, toVersion: $toVersion, changedTables: $changedTables, downloadSize: $downloadSize)';
}


}

/// @nodoc
abstract mixin class $DeltaUpdateCopyWith<$Res>  {
  factory $DeltaUpdateCopyWith(DeltaUpdate value, $Res Function(DeltaUpdate) _then) = _$DeltaUpdateCopyWithImpl;
@useResult
$Res call({
 String trailId, int fromVersion, int toVersion, List<String> changedTables, int downloadSize
});




}
/// @nodoc
class _$DeltaUpdateCopyWithImpl<$Res>
    implements $DeltaUpdateCopyWith<$Res> {
  _$DeltaUpdateCopyWithImpl(this._self, this._then);

  final DeltaUpdate _self;
  final $Res Function(DeltaUpdate) _then;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trailId = null,Object? fromVersion = null,Object? toVersion = null,Object? changedTables = null,Object? downloadSize = null,}) {
  return _then(_self.copyWith(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,fromVersion: null == fromVersion ? _self.fromVersion : fromVersion // ignore: cast_nullable_to_non_nullable
as int,toVersion: null == toVersion ? _self.toVersion : toVersion // ignore: cast_nullable_to_non_nullable
as int,changedTables: null == changedTables ? _self.changedTables : changedTables // ignore: cast_nullable_to_non_nullable
as List<String>,downloadSize: null == downloadSize ? _self.downloadSize : downloadSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DeltaUpdate].
extension DeltaUpdatePatterns on DeltaUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeltaUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeltaUpdate value)  $default,){
final _that = this;
switch (_that) {
case _DeltaUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeltaUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trailId,  int fromVersion,  int toVersion,  List<String> changedTables,  int downloadSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.changedTables,_that.downloadSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trailId,  int fromVersion,  int toVersion,  List<String> changedTables,  int downloadSize)  $default,) {final _that = this;
switch (_that) {
case _DeltaUpdate():
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.changedTables,_that.downloadSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trailId,  int fromVersion,  int toVersion,  List<String> changedTables,  int downloadSize)?  $default,) {final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.changedTables,_that.downloadSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeltaUpdate implements DeltaUpdate {
  const _DeltaUpdate({required this.trailId, required this.fromVersion, required this.toVersion, required final  List<String> changedTables, required this.downloadSize}): _changedTables = changedTables;
  factory _DeltaUpdate.fromJson(Map<String, dynamic> json) => _$DeltaUpdateFromJson(json);

/// Identifiant du sentier concerne
@override final  String trailId;
/// Version locale actuelle (point de depart du delta)
@override final  int fromVersion;
/// Version cible apres application du delta
@override final  int toVersion;
/// Liste des tables modifiees entre les deux versions
 final  List<String> _changedTables;
/// Liste des tables modifiees entre les deux versions
@override List<String> get changedTables {
  if (_changedTables is EqualUnmodifiableListView) return _changedTables;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changedTables);
}

/// Taille du delta en octets (pour affichage/estimation)
@override final  int downloadSize;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeltaUpdateCopyWith<_DeltaUpdate> get copyWith => __$DeltaUpdateCopyWithImpl<_DeltaUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeltaUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeltaUpdate&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.fromVersion, fromVersion) || other.fromVersion == fromVersion)&&(identical(other.toVersion, toVersion) || other.toVersion == toVersion)&&const DeepCollectionEquality().equals(other._changedTables, _changedTables)&&(identical(other.downloadSize, downloadSize) || other.downloadSize == downloadSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,fromVersion,toVersion,const DeepCollectionEquality().hash(_changedTables),downloadSize);

@override
String toString() {
  return 'DeltaUpdate(trailId: $trailId, fromVersion: $fromVersion, toVersion: $toVersion, changedTables: $changedTables, downloadSize: $downloadSize)';
}


}

/// @nodoc
abstract mixin class _$DeltaUpdateCopyWith<$Res> implements $DeltaUpdateCopyWith<$Res> {
  factory _$DeltaUpdateCopyWith(_DeltaUpdate value, $Res Function(_DeltaUpdate) _then) = __$DeltaUpdateCopyWithImpl;
@override @useResult
$Res call({
 String trailId, int fromVersion, int toVersion, List<String> changedTables, int downloadSize
});




}
/// @nodoc
class __$DeltaUpdateCopyWithImpl<$Res>
    implements _$DeltaUpdateCopyWith<$Res> {
  __$DeltaUpdateCopyWithImpl(this._self, this._then);

  final _DeltaUpdate _self;
  final $Res Function(_DeltaUpdate) _then;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trailId = null,Object? fromVersion = null,Object? toVersion = null,Object? changedTables = null,Object? downloadSize = null,}) {
  return _then(_DeltaUpdate(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,fromVersion: null == fromVersion ? _self.fromVersion : fromVersion // ignore: cast_nullable_to_non_nullable
as int,toVersion: null == toVersion ? _self.toVersion : toVersion // ignore: cast_nullable_to_non_nullable
as int,changedTables: null == changedTables ? _self._changedTables : changedTables // ignore: cast_nullable_to_non_nullable
as List<String>,downloadSize: null == downloadSize ? _self.downloadSize : downloadSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
