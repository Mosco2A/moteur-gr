// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Trail {

/// Identifiant unique (ex: 'mare_a_mare', 'tmb')
 String get id;/// Nom technique court (ex: 'Mare a Mare')
 String get name;/// Nom d'affichage dans l'app
 String get displayName;/// Accroche sous le nom
 String get tagline;/// Nombre total d'etapes
 int get totalStages;/// Distance totale en km
 double get totalDistanceKm;/// Denivele positif total en metres
 int get totalElevationGain;/// Region geographique
 String get region;/// Pays
 String get country;
/// Create a copy of Trail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrailCopyWith<Trail> get copyWith => _$TrailCopyWithImpl<Trail>(this as Trail, _$identity);

  /// Serializes this Trail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Trail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.totalStages, totalStages) || other.totalStages == totalStages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayName,tagline,totalStages,totalDistanceKm,totalElevationGain,region,country);

@override
String toString() {
  return 'Trail(id: $id, name: $name, displayName: $displayName, tagline: $tagline, totalStages: $totalStages, totalDistanceKm: $totalDistanceKm, totalElevationGain: $totalElevationGain, region: $region, country: $country)';
}


}

/// @nodoc
abstract mixin class $TrailCopyWith<$Res>  {
  factory $TrailCopyWith(Trail value, $Res Function(Trail) _then) = _$TrailCopyWithImpl;
@useResult
$Res call({
 String id, String name, String displayName, String tagline, int totalStages, double totalDistanceKm, int totalElevationGain, String region, String country
});




}
/// @nodoc
class _$TrailCopyWithImpl<$Res>
    implements $TrailCopyWith<$Res> {
  _$TrailCopyWithImpl(this._self, this._then);

  final Trail _self;
  final $Res Function(Trail) _then;

/// Create a copy of Trail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? tagline = null,Object? totalStages = null,Object? totalDistanceKm = null,Object? totalElevationGain = null,Object? region = null,Object? country = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,totalStages: null == totalStages ? _self.totalStages : totalStages // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Trail].
extension TrailPatterns on Trail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Trail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Trail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Trail value)  $default,){
final _that = this;
switch (_that) {
case _Trail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Trail value)?  $default,){
final _that = this;
switch (_that) {
case _Trail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String displayName,  String tagline,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  String region,  String country)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Trail() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.tagline,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.region,_that.country);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String displayName,  String tagline,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  String region,  String country)  $default,) {final _that = this;
switch (_that) {
case _Trail():
return $default(_that.id,_that.name,_that.displayName,_that.tagline,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.region,_that.country);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String displayName,  String tagline,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  String region,  String country)?  $default,) {final _that = this;
switch (_that) {
case _Trail() when $default != null:
return $default(_that.id,_that.name,_that.displayName,_that.tagline,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.region,_that.country);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Trail implements Trail {
  const _Trail({required this.id, required this.name, required this.displayName, this.tagline = '', required this.totalStages, required this.totalDistanceKm, required this.totalElevationGain, required this.region, required this.country});
  factory _Trail.fromJson(Map<String, dynamic> json) => _$TrailFromJson(json);

/// Identifiant unique (ex: 'mare_a_mare', 'tmb')
@override final  String id;
/// Nom technique court (ex: 'Mare a Mare')
@override final  String name;
/// Nom d'affichage dans l'app
@override final  String displayName;
/// Accroche sous le nom
@override@JsonKey() final  String tagline;
/// Nombre total d'etapes
@override final  int totalStages;
/// Distance totale en km
@override final  double totalDistanceKm;
/// Denivele positif total en metres
@override final  int totalElevationGain;
/// Region geographique
@override final  String region;
/// Pays
@override final  String country;

/// Create a copy of Trail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrailCopyWith<_Trail> get copyWith => __$TrailCopyWithImpl<_Trail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Trail&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.totalStages, totalStages) || other.totalStages == totalStages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,displayName,tagline,totalStages,totalDistanceKm,totalElevationGain,region,country);

@override
String toString() {
  return 'Trail(id: $id, name: $name, displayName: $displayName, tagline: $tagline, totalStages: $totalStages, totalDistanceKm: $totalDistanceKm, totalElevationGain: $totalElevationGain, region: $region, country: $country)';
}


}

/// @nodoc
abstract mixin class _$TrailCopyWith<$Res> implements $TrailCopyWith<$Res> {
  factory _$TrailCopyWith(_Trail value, $Res Function(_Trail) _then) = __$TrailCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String displayName, String tagline, int totalStages, double totalDistanceKm, int totalElevationGain, String region, String country
});




}
/// @nodoc
class __$TrailCopyWithImpl<$Res>
    implements _$TrailCopyWith<$Res> {
  __$TrailCopyWithImpl(this._self, this._then);

  final _Trail _self;
  final $Res Function(_Trail) _then;

/// Create a copy of Trail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? displayName = null,Object? tagline = null,Object? totalStages = null,Object? totalDistanceKm = null,Object? totalElevationGain = null,Object? region = null,Object? country = null,}) {
  return _then(_Trail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,totalStages: null == totalStages ? _self.totalStages : totalStages // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
