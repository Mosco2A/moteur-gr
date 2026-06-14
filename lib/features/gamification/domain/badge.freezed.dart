// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'badge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Badge {

/// Identifiant unique du badge (== code par defaut).
 String get id;/// Code de regle/i18n du badge (BadgeCode).
 String get code;/// Titre localise (Slang).
 String get titre;/// Description localisee (Slang).
 String get description;/// Palier ('debutant' / 'expert', BadgeTier).
 String get tier;/// Reference d'icone (asset/glyph) du badge.
 String get iconRef;/// Date d'obtention (null = badge verrouille, pas encore obtenu).
 DateTime? get obtainedAt;
/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BadgeCopyWith<Badge> get copyWith => _$BadgeCopyWithImpl<Badge>(this as Badge, _$identity);

  /// Serializes this Badge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Badge&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.description, description) || other.description == description)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.obtainedAt, obtainedAt) || other.obtainedAt == obtainedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,titre,description,tier,iconRef,obtainedAt);

@override
String toString() {
  return 'Badge(id: $id, code: $code, titre: $titre, description: $description, tier: $tier, iconRef: $iconRef, obtainedAt: $obtainedAt)';
}


}

/// @nodoc
abstract mixin class $BadgeCopyWith<$Res>  {
  factory $BadgeCopyWith(Badge value, $Res Function(Badge) _then) = _$BadgeCopyWithImpl;
@useResult
$Res call({
 String id, String code, String titre, String description, String tier, String iconRef, DateTime? obtainedAt
});




}
/// @nodoc
class _$BadgeCopyWithImpl<$Res>
    implements $BadgeCopyWith<$Res> {
  _$BadgeCopyWithImpl(this._self, this._then);

  final Badge _self;
  final $Res Function(Badge) _then;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? titre = null,Object? description = null,Object? tier = null,Object? iconRef = null,Object? obtainedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,obtainedAt: freezed == obtainedAt ? _self.obtainedAt : obtainedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Badge].
extension BadgePatterns on Badge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Badge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Badge() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Badge value)  $default,){
final _that = this;
switch (_that) {
case _Badge():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Badge value)?  $default,){
final _that = this;
switch (_that) {
case _Badge() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String code,  String titre,  String description,  String tier,  String iconRef,  DateTime? obtainedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Badge() when $default != null:
return $default(_that.id,_that.code,_that.titre,_that.description,_that.tier,_that.iconRef,_that.obtainedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String code,  String titre,  String description,  String tier,  String iconRef,  DateTime? obtainedAt)  $default,) {final _that = this;
switch (_that) {
case _Badge():
return $default(_that.id,_that.code,_that.titre,_that.description,_that.tier,_that.iconRef,_that.obtainedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String code,  String titre,  String description,  String tier,  String iconRef,  DateTime? obtainedAt)?  $default,) {final _that = this;
switch (_that) {
case _Badge() when $default != null:
return $default(_that.id,_that.code,_that.titre,_that.description,_that.tier,_that.iconRef,_that.obtainedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Badge extends Badge {
  const _Badge({required this.id, required this.code, required this.titre, required this.description, required this.tier, required this.iconRef, this.obtainedAt}): super._();
  factory _Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);

/// Identifiant unique du badge (== code par defaut).
@override final  String id;
/// Code de regle/i18n du badge (BadgeCode).
@override final  String code;
/// Titre localise (Slang).
@override final  String titre;
/// Description localisee (Slang).
@override final  String description;
/// Palier ('debutant' / 'expert', BadgeTier).
@override final  String tier;
/// Reference d'icone (asset/glyph) du badge.
@override final  String iconRef;
/// Date d'obtention (null = badge verrouille, pas encore obtenu).
@override final  DateTime? obtainedAt;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BadgeCopyWith<_Badge> get copyWith => __$BadgeCopyWithImpl<_Badge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BadgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Badge&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.description, description) || other.description == description)&&(identical(other.tier, tier) || other.tier == tier)&&(identical(other.iconRef, iconRef) || other.iconRef == iconRef)&&(identical(other.obtainedAt, obtainedAt) || other.obtainedAt == obtainedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,titre,description,tier,iconRef,obtainedAt);

@override
String toString() {
  return 'Badge(id: $id, code: $code, titre: $titre, description: $description, tier: $tier, iconRef: $iconRef, obtainedAt: $obtainedAt)';
}


}

/// @nodoc
abstract mixin class _$BadgeCopyWith<$Res> implements $BadgeCopyWith<$Res> {
  factory _$BadgeCopyWith(_Badge value, $Res Function(_Badge) _then) = __$BadgeCopyWithImpl;
@override @useResult
$Res call({
 String id, String code, String titre, String description, String tier, String iconRef, DateTime? obtainedAt
});




}
/// @nodoc
class __$BadgeCopyWithImpl<$Res>
    implements _$BadgeCopyWith<$Res> {
  __$BadgeCopyWithImpl(this._self, this._then);

  final _Badge _self;
  final $Res Function(_Badge) _then;

/// Create a copy of Badge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? titre = null,Object? description = null,Object? tier = null,Object? iconRef = null,Object? obtainedAt = freezed,}) {
  return _then(_Badge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,tier: null == tier ? _self.tier : tier // ignore: cast_nullable_to_non_nullable
as String,iconRef: null == iconRef ? _self.iconRef : iconRef // ignore: cast_nullable_to_non_nullable
as String,obtainedAt: freezed == obtainedAt ? _self.obtainedAt : obtainedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
