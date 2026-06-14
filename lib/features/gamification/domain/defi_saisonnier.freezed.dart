// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'defi_saisonnier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DefiSaisonnier {

/// Identifiant unique du defi.
 String get id;/// Titre localise (Slang).
 String get titre;/// Description localisee (Slang).
 String get description;/// Debut de la periode (UTC).
 DateTime get debut;/// Fin de la periode (UTC, incluse).
 DateTime get fin;/// Type d'objectif ('distance' / 'denivele' / 'segments', DefiObjectif).
 String get typeObjectif;/// Valeur cible a atteindre (unite selon typeObjectif).
 double get cible;
/// Create a copy of DefiSaisonnier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DefiSaisonnierCopyWith<DefiSaisonnier> get copyWith => _$DefiSaisonnierCopyWithImpl<DefiSaisonnier>(this as DefiSaisonnier, _$identity);

  /// Serializes this DefiSaisonnier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DefiSaisonnier&&(identical(other.id, id) || other.id == id)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.description, description) || other.description == description)&&(identical(other.debut, debut) || other.debut == debut)&&(identical(other.fin, fin) || other.fin == fin)&&(identical(other.typeObjectif, typeObjectif) || other.typeObjectif == typeObjectif)&&(identical(other.cible, cible) || other.cible == cible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titre,description,debut,fin,typeObjectif,cible);

@override
String toString() {
  return 'DefiSaisonnier(id: $id, titre: $titre, description: $description, debut: $debut, fin: $fin, typeObjectif: $typeObjectif, cible: $cible)';
}


}

/// @nodoc
abstract mixin class $DefiSaisonnierCopyWith<$Res>  {
  factory $DefiSaisonnierCopyWith(DefiSaisonnier value, $Res Function(DefiSaisonnier) _then) = _$DefiSaisonnierCopyWithImpl;
@useResult
$Res call({
 String id, String titre, String description, DateTime debut, DateTime fin, String typeObjectif, double cible
});




}
/// @nodoc
class _$DefiSaisonnierCopyWithImpl<$Res>
    implements $DefiSaisonnierCopyWith<$Res> {
  _$DefiSaisonnierCopyWithImpl(this._self, this._then);

  final DefiSaisonnier _self;
  final $Res Function(DefiSaisonnier) _then;

/// Create a copy of DefiSaisonnier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titre = null,Object? description = null,Object? debut = null,Object? fin = null,Object? typeObjectif = null,Object? cible = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,debut: null == debut ? _self.debut : debut // ignore: cast_nullable_to_non_nullable
as DateTime,fin: null == fin ? _self.fin : fin // ignore: cast_nullable_to_non_nullable
as DateTime,typeObjectif: null == typeObjectif ? _self.typeObjectif : typeObjectif // ignore: cast_nullable_to_non_nullable
as String,cible: null == cible ? _self.cible : cible // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DefiSaisonnier].
extension DefiSaisonnierPatterns on DefiSaisonnier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DefiSaisonnier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DefiSaisonnier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DefiSaisonnier value)  $default,){
final _that = this;
switch (_that) {
case _DefiSaisonnier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DefiSaisonnier value)?  $default,){
final _that = this;
switch (_that) {
case _DefiSaisonnier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titre,  String description,  DateTime debut,  DateTime fin,  String typeObjectif,  double cible)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DefiSaisonnier() when $default != null:
return $default(_that.id,_that.titre,_that.description,_that.debut,_that.fin,_that.typeObjectif,_that.cible);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titre,  String description,  DateTime debut,  DateTime fin,  String typeObjectif,  double cible)  $default,) {final _that = this;
switch (_that) {
case _DefiSaisonnier():
return $default(_that.id,_that.titre,_that.description,_that.debut,_that.fin,_that.typeObjectif,_that.cible);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titre,  String description,  DateTime debut,  DateTime fin,  String typeObjectif,  double cible)?  $default,) {final _that = this;
switch (_that) {
case _DefiSaisonnier() when $default != null:
return $default(_that.id,_that.titre,_that.description,_that.debut,_that.fin,_that.typeObjectif,_that.cible);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DefiSaisonnier extends DefiSaisonnier {
  const _DefiSaisonnier({required this.id, required this.titre, required this.description, required this.debut, required this.fin, required this.typeObjectif, required this.cible}): super._();
  factory _DefiSaisonnier.fromJson(Map<String, dynamic> json) => _$DefiSaisonnierFromJson(json);

/// Identifiant unique du defi.
@override final  String id;
/// Titre localise (Slang).
@override final  String titre;
/// Description localisee (Slang).
@override final  String description;
/// Debut de la periode (UTC).
@override final  DateTime debut;
/// Fin de la periode (UTC, incluse).
@override final  DateTime fin;
/// Type d'objectif ('distance' / 'denivele' / 'segments', DefiObjectif).
@override final  String typeObjectif;
/// Valeur cible a atteindre (unite selon typeObjectif).
@override final  double cible;

/// Create a copy of DefiSaisonnier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DefiSaisonnierCopyWith<_DefiSaisonnier> get copyWith => __$DefiSaisonnierCopyWithImpl<_DefiSaisonnier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DefiSaisonnierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DefiSaisonnier&&(identical(other.id, id) || other.id == id)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.description, description) || other.description == description)&&(identical(other.debut, debut) || other.debut == debut)&&(identical(other.fin, fin) || other.fin == fin)&&(identical(other.typeObjectif, typeObjectif) || other.typeObjectif == typeObjectif)&&(identical(other.cible, cible) || other.cible == cible));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titre,description,debut,fin,typeObjectif,cible);

@override
String toString() {
  return 'DefiSaisonnier(id: $id, titre: $titre, description: $description, debut: $debut, fin: $fin, typeObjectif: $typeObjectif, cible: $cible)';
}


}

/// @nodoc
abstract mixin class _$DefiSaisonnierCopyWith<$Res> implements $DefiSaisonnierCopyWith<$Res> {
  factory _$DefiSaisonnierCopyWith(_DefiSaisonnier value, $Res Function(_DefiSaisonnier) _then) = __$DefiSaisonnierCopyWithImpl;
@override @useResult
$Res call({
 String id, String titre, String description, DateTime debut, DateTime fin, String typeObjectif, double cible
});




}
/// @nodoc
class __$DefiSaisonnierCopyWithImpl<$Res>
    implements _$DefiSaisonnierCopyWith<$Res> {
  __$DefiSaisonnierCopyWithImpl(this._self, this._then);

  final _DefiSaisonnier _self;
  final $Res Function(_DefiSaisonnier) _then;

/// Create a copy of DefiSaisonnier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titre = null,Object? description = null,Object? debut = null,Object? fin = null,Object? typeObjectif = null,Object? cible = null,}) {
  return _then(_DefiSaisonnier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,debut: null == debut ? _self.debut : debut // ignore: cast_nullable_to_non_nullable
as DateTime,fin: null == fin ? _self.fin : fin // ignore: cast_nullable_to_non_nullable
as DateTime,typeObjectif: null == typeObjectif ? _self.typeObjectif : typeObjectif // ignore: cast_nullable_to_non_nullable
as String,cible: null == cible ? _self.cible : cible // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
