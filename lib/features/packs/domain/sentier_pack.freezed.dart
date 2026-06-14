// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sentier_pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SentierPack {

/// Identifiant unique du pack (ex: 'mam_nord', 'mam_complet').
 String get id;/// Nom localise du pack (Slang) — ex « Mare a Mare Nord ».
 String get nom;/// Identifiant du sentier auquel ce pack appartient (genericite #84627).
 String get trailId;/// Type de pack ('nord' / 'sud' / 'complet' / 'mam', [PackType]).
 String get type;/// Description localisee du pack (Slang).
 String get description;
/// Create a copy of SentierPack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SentierPackCopyWith<SentierPack> get copyWith => _$SentierPackCopyWithImpl<SentierPack>(this as SentierPack, _$identity);

  /// Serializes this SentierPack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SentierPack&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,trailId,type,description);

@override
String toString() {
  return 'SentierPack(id: $id, nom: $nom, trailId: $trailId, type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class $SentierPackCopyWith<$Res>  {
  factory $SentierPackCopyWith(SentierPack value, $Res Function(SentierPack) _then) = _$SentierPackCopyWithImpl;
@useResult
$Res call({
 String id, String nom, String trailId, String type, String description
});




}
/// @nodoc
class _$SentierPackCopyWithImpl<$Res>
    implements $SentierPackCopyWith<$Res> {
  _$SentierPackCopyWithImpl(this._self, this._then);

  final SentierPack _self;
  final $Res Function(SentierPack) _then;

/// Create a copy of SentierPack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? trailId = null,Object? type = null,Object? description = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SentierPack].
extension SentierPackPatterns on SentierPack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SentierPack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SentierPack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SentierPack value)  $default,){
final _that = this;
switch (_that) {
case _SentierPack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SentierPack value)?  $default,){
final _that = this;
switch (_that) {
case _SentierPack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  String trailId,  String type,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SentierPack() when $default != null:
return $default(_that.id,_that.nom,_that.trailId,_that.type,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  String trailId,  String type,  String description)  $default,) {final _that = this;
switch (_that) {
case _SentierPack():
return $default(_that.id,_that.nom,_that.trailId,_that.type,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  String trailId,  String type,  String description)?  $default,) {final _that = this;
switch (_that) {
case _SentierPack() when $default != null:
return $default(_that.id,_that.nom,_that.trailId,_that.type,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SentierPack extends SentierPack {
  const _SentierPack({required this.id, required this.nom, required this.trailId, required this.type, required this.description}): super._();
  factory _SentierPack.fromJson(Map<String, dynamic> json) => _$SentierPackFromJson(json);

/// Identifiant unique du pack (ex: 'mam_nord', 'mam_complet').
@override final  String id;
/// Nom localise du pack (Slang) — ex « Mare a Mare Nord ».
@override final  String nom;
/// Identifiant du sentier auquel ce pack appartient (genericite #84627).
@override final  String trailId;
/// Type de pack ('nord' / 'sud' / 'complet' / 'mam', [PackType]).
@override final  String type;
/// Description localisee du pack (Slang).
@override final  String description;

/// Create a copy of SentierPack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SentierPackCopyWith<_SentierPack> get copyWith => __$SentierPackCopyWithImpl<_SentierPack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SentierPackToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SentierPack&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.type, type) || other.type == type)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,trailId,type,description);

@override
String toString() {
  return 'SentierPack(id: $id, nom: $nom, trailId: $trailId, type: $type, description: $description)';
}


}

/// @nodoc
abstract mixin class _$SentierPackCopyWith<$Res> implements $SentierPackCopyWith<$Res> {
  factory _$SentierPackCopyWith(_SentierPack value, $Res Function(_SentierPack) _then) = __$SentierPackCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, String trailId, String type, String description
});




}
/// @nodoc
class __$SentierPackCopyWithImpl<$Res>
    implements _$SentierPackCopyWith<$Res> {
  __$SentierPackCopyWithImpl(this._self, this._then);

  final _SentierPack _self;
  final $Res Function(_SentierPack) _then;

/// Create a copy of SentierPack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? trailId = null,Object? type = null,Object? description = null,}) {
  return _then(_SentierPack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
