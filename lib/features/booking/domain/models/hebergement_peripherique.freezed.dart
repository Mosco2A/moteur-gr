// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hebergement_peripherique.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HebergementPeripherique {

/// Identifiant unique de l'hébergement.
 String get id;/// Nom commercial de l'hébergement.
 String get nom;/// Type d'hébergement.
 HebergementType get type;/// Latitude de l'hébergement (hors-trace).
 double get latitude;/// Longitude de l'hébergement (hors-trace).
 double get longitude;/// Distance aller-retour estimée (km) depuis le point d'étape de référence.
 double get distanceAllerRetourKm;/// Lien profond (URL) vers le site/app du prestataire pour réserver.
/// Le facilitateur ouvre ce lien : pas de réservation in-app (#84100).
 String get deeplinkUrl;
/// Create a copy of HebergementPeripherique
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HebergementPeripheriqueCopyWith<HebergementPeripherique> get copyWith => _$HebergementPeripheriqueCopyWithImpl<HebergementPeripherique>(this as HebergementPeripherique, _$identity);

  /// Serializes this HebergementPeripherique to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HebergementPeripherique&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceAllerRetourKm, distanceAllerRetourKm) || other.distanceAllerRetourKm == distanceAllerRetourKm)&&(identical(other.deeplinkUrl, deeplinkUrl) || other.deeplinkUrl == deeplinkUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,type,latitude,longitude,distanceAllerRetourKm,deeplinkUrl);

@override
String toString() {
  return 'HebergementPeripherique(id: $id, nom: $nom, type: $type, latitude: $latitude, longitude: $longitude, distanceAllerRetourKm: $distanceAllerRetourKm, deeplinkUrl: $deeplinkUrl)';
}


}

/// @nodoc
abstract mixin class $HebergementPeripheriqueCopyWith<$Res>  {
  factory $HebergementPeripheriqueCopyWith(HebergementPeripherique value, $Res Function(HebergementPeripherique) _then) = _$HebergementPeripheriqueCopyWithImpl;
@useResult
$Res call({
 String id, String nom, HebergementType type, double latitude, double longitude, double distanceAllerRetourKm, String deeplinkUrl
});




}
/// @nodoc
class _$HebergementPeripheriqueCopyWithImpl<$Res>
    implements $HebergementPeripheriqueCopyWith<$Res> {
  _$HebergementPeripheriqueCopyWithImpl(this._self, this._then);

  final HebergementPeripherique _self;
  final $Res Function(HebergementPeripherique) _then;

/// Create a copy of HebergementPeripherique
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nom = null,Object? type = null,Object? latitude = null,Object? longitude = null,Object? distanceAllerRetourKm = null,Object? deeplinkUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HebergementType,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceAllerRetourKm: null == distanceAllerRetourKm ? _self.distanceAllerRetourKm : distanceAllerRetourKm // ignore: cast_nullable_to_non_nullable
as double,deeplinkUrl: null == deeplinkUrl ? _self.deeplinkUrl : deeplinkUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HebergementPeripherique].
extension HebergementPeripheriquePatterns on HebergementPeripherique {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HebergementPeripherique value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HebergementPeripherique() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HebergementPeripherique value)  $default,){
final _that = this;
switch (_that) {
case _HebergementPeripherique():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HebergementPeripherique value)?  $default,){
final _that = this;
switch (_that) {
case _HebergementPeripherique() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nom,  HebergementType type,  double latitude,  double longitude,  double distanceAllerRetourKm,  String deeplinkUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HebergementPeripherique() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.latitude,_that.longitude,_that.distanceAllerRetourKm,_that.deeplinkUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nom,  HebergementType type,  double latitude,  double longitude,  double distanceAllerRetourKm,  String deeplinkUrl)  $default,) {final _that = this;
switch (_that) {
case _HebergementPeripherique():
return $default(_that.id,_that.nom,_that.type,_that.latitude,_that.longitude,_that.distanceAllerRetourKm,_that.deeplinkUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nom,  HebergementType type,  double latitude,  double longitude,  double distanceAllerRetourKm,  String deeplinkUrl)?  $default,) {final _that = this;
switch (_that) {
case _HebergementPeripherique() when $default != null:
return $default(_that.id,_that.nom,_that.type,_that.latitude,_that.longitude,_that.distanceAllerRetourKm,_that.deeplinkUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HebergementPeripherique extends HebergementPeripherique {
  const _HebergementPeripherique({required this.id, required this.nom, required this.type, required this.latitude, required this.longitude, required this.distanceAllerRetourKm, required this.deeplinkUrl}): super._();
  factory _HebergementPeripherique.fromJson(Map<String, dynamic> json) => _$HebergementPeripheriqueFromJson(json);

/// Identifiant unique de l'hébergement.
@override final  String id;
/// Nom commercial de l'hébergement.
@override final  String nom;
/// Type d'hébergement.
@override final  HebergementType type;
/// Latitude de l'hébergement (hors-trace).
@override final  double latitude;
/// Longitude de l'hébergement (hors-trace).
@override final  double longitude;
/// Distance aller-retour estimée (km) depuis le point d'étape de référence.
@override final  double distanceAllerRetourKm;
/// Lien profond (URL) vers le site/app du prestataire pour réserver.
/// Le facilitateur ouvre ce lien : pas de réservation in-app (#84100).
@override final  String deeplinkUrl;

/// Create a copy of HebergementPeripherique
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HebergementPeripheriqueCopyWith<_HebergementPeripherique> get copyWith => __$HebergementPeripheriqueCopyWithImpl<_HebergementPeripherique>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HebergementPeripheriqueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HebergementPeripherique&&(identical(other.id, id) || other.id == id)&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.type, type) || other.type == type)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.distanceAllerRetourKm, distanceAllerRetourKm) || other.distanceAllerRetourKm == distanceAllerRetourKm)&&(identical(other.deeplinkUrl, deeplinkUrl) || other.deeplinkUrl == deeplinkUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nom,type,latitude,longitude,distanceAllerRetourKm,deeplinkUrl);

@override
String toString() {
  return 'HebergementPeripherique(id: $id, nom: $nom, type: $type, latitude: $latitude, longitude: $longitude, distanceAllerRetourKm: $distanceAllerRetourKm, deeplinkUrl: $deeplinkUrl)';
}


}

/// @nodoc
abstract mixin class _$HebergementPeripheriqueCopyWith<$Res> implements $HebergementPeripheriqueCopyWith<$Res> {
  factory _$HebergementPeripheriqueCopyWith(_HebergementPeripherique value, $Res Function(_HebergementPeripherique) _then) = __$HebergementPeripheriqueCopyWithImpl;
@override @useResult
$Res call({
 String id, String nom, HebergementType type, double latitude, double longitude, double distanceAllerRetourKm, String deeplinkUrl
});




}
/// @nodoc
class __$HebergementPeripheriqueCopyWithImpl<$Res>
    implements _$HebergementPeripheriqueCopyWith<$Res> {
  __$HebergementPeripheriqueCopyWithImpl(this._self, this._then);

  final _HebergementPeripherique _self;
  final $Res Function(_HebergementPeripherique) _then;

/// Create a copy of HebergementPeripherique
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nom = null,Object? type = null,Object? latitude = null,Object? longitude = null,Object? distanceAllerRetourKm = null,Object? deeplinkUrl = null,}) {
  return _then(_HebergementPeripherique(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as HebergementType,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,distanceAllerRetourKm: null == distanceAllerRetourKm ? _self.distanceAllerRetourKm : distanceAllerRetourKm // ignore: cast_nullable_to_non_nullable
as double,deeplinkUrl: null == deeplinkUrl ? _self.deeplinkUrl : deeplinkUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
