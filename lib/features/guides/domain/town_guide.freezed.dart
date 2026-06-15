// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'town_guide.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuideCoordinates {

/// Latitude en degres decimaux (WGS84).
 double get latitude;/// Longitude en degres decimaux (WGS84).
 double get longitude;
/// Create a copy of GuideCoordinates
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideCoordinatesCopyWith<GuideCoordinates> get copyWith => _$GuideCoordinatesCopyWithImpl<GuideCoordinates>(this as GuideCoordinates, _$identity);

  /// Serializes this GuideCoordinates to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideCoordinates&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude);

@override
String toString() {
  return 'GuideCoordinates(latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class $GuideCoordinatesCopyWith<$Res>  {
  factory $GuideCoordinatesCopyWith(GuideCoordinates value, $Res Function(GuideCoordinates) _then) = _$GuideCoordinatesCopyWithImpl;
@useResult
$Res call({
 double latitude, double longitude
});




}
/// @nodoc
class _$GuideCoordinatesCopyWithImpl<$Res>
    implements $GuideCoordinatesCopyWith<$Res> {
  _$GuideCoordinatesCopyWithImpl(this._self, this._then);

  final GuideCoordinates _self;
  final $Res Function(GuideCoordinates) _then;

/// Create a copy of GuideCoordinates
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? latitude = null,Object? longitude = null,}) {
  return _then(_self.copyWith(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideCoordinates].
extension GuideCoordinatesPatterns on GuideCoordinates {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideCoordinates value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideCoordinates() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideCoordinates value)  $default,){
final _that = this;
switch (_that) {
case _GuideCoordinates():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideCoordinates value)?  $default,){
final _that = this;
switch (_that) {
case _GuideCoordinates() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double latitude,  double longitude)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideCoordinates() when $default != null:
return $default(_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double latitude,  double longitude)  $default,) {final _that = this;
switch (_that) {
case _GuideCoordinates():
return $default(_that.latitude,_that.longitude);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double latitude,  double longitude)?  $default,) {final _that = this;
switch (_that) {
case _GuideCoordinates() when $default != null:
return $default(_that.latitude,_that.longitude);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuideCoordinates implements GuideCoordinates {
  const _GuideCoordinates({required this.latitude, required this.longitude});
  factory _GuideCoordinates.fromJson(Map<String, dynamic> json) => _$GuideCoordinatesFromJson(json);

/// Latitude en degres decimaux (WGS84).
@override final  double latitude;
/// Longitude en degres decimaux (WGS84).
@override final  double longitude;

/// Create a copy of GuideCoordinates
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideCoordinatesCopyWith<_GuideCoordinates> get copyWith => __$GuideCoordinatesCopyWithImpl<_GuideCoordinates>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuideCoordinatesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideCoordinates&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,latitude,longitude);

@override
String toString() {
  return 'GuideCoordinates(latitude: $latitude, longitude: $longitude)';
}


}

/// @nodoc
abstract mixin class _$GuideCoordinatesCopyWith<$Res> implements $GuideCoordinatesCopyWith<$Res> {
  factory _$GuideCoordinatesCopyWith(_GuideCoordinates value, $Res Function(_GuideCoordinates) _then) = __$GuideCoordinatesCopyWithImpl;
@override @useResult
$Res call({
 double latitude, double longitude
});




}
/// @nodoc
class __$GuideCoordinatesCopyWithImpl<$Res>
    implements _$GuideCoordinatesCopyWith<$Res> {
  __$GuideCoordinatesCopyWithImpl(this._self, this._then);

  final _GuideCoordinates _self;
  final $Res Function(_GuideCoordinates) _then;

/// Create a copy of GuideCoordinates
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? latitude = null,Object? longitude = null,}) {
  return _then(_GuideCoordinates(
latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$GuideItem {

/// Nom de l'item/prestataire (ex « Epicerie du village »).
 String get nom;/// Description courte (horaires, specificites, conseils pratiques).
 String get description;/// Lien deeplink SORTANT vers le site/app du prestataire (facilitateur,
/// #84100). Null = pas de lien (l'UI masque alors le bouton).
 String? get deeplinkUrl;/// Coordonnees de l'item si cartographiable (null sinon).
 GuideCoordinates? get coordonnees;
/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideItemCopyWith<GuideItem> get copyWith => _$GuideItemCopyWithImpl<GuideItem>(this as GuideItem, _$identity);

  /// Serializes this GuideItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideItem&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.description, description) || other.description == description)&&(identical(other.deeplinkUrl, deeplinkUrl) || other.deeplinkUrl == deeplinkUrl)&&(identical(other.coordonnees, coordonnees) || other.coordonnees == coordonnees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nom,description,deeplinkUrl,coordonnees);

@override
String toString() {
  return 'GuideItem(nom: $nom, description: $description, deeplinkUrl: $deeplinkUrl, coordonnees: $coordonnees)';
}


}

/// @nodoc
abstract mixin class $GuideItemCopyWith<$Res>  {
  factory $GuideItemCopyWith(GuideItem value, $Res Function(GuideItem) _then) = _$GuideItemCopyWithImpl;
@useResult
$Res call({
 String nom, String description, String? deeplinkUrl, GuideCoordinates? coordonnees
});


$GuideCoordinatesCopyWith<$Res>? get coordonnees;

}
/// @nodoc
class _$GuideItemCopyWithImpl<$Res>
    implements $GuideItemCopyWith<$Res> {
  _$GuideItemCopyWithImpl(this._self, this._then);

  final GuideItem _self;
  final $Res Function(GuideItem) _then;

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nom = null,Object? description = null,Object? deeplinkUrl = freezed,Object? coordonnees = freezed,}) {
  return _then(_self.copyWith(
nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,deeplinkUrl: freezed == deeplinkUrl ? _self.deeplinkUrl : deeplinkUrl // ignore: cast_nullable_to_non_nullable
as String?,coordonnees: freezed == coordonnees ? _self.coordonnees : coordonnees // ignore: cast_nullable_to_non_nullable
as GuideCoordinates?,
  ));
}
/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuideCoordinatesCopyWith<$Res>? get coordonnees {
    if (_self.coordonnees == null) {
    return null;
  }

  return $GuideCoordinatesCopyWith<$Res>(_self.coordonnees!, (value) {
    return _then(_self.copyWith(coordonnees: value));
  });
}
}


/// Adds pattern-matching-related methods to [GuideItem].
extension GuideItemPatterns on GuideItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideItem value)  $default,){
final _that = this;
switch (_that) {
case _GuideItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideItem value)?  $default,){
final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nom,  String description,  String? deeplinkUrl,  GuideCoordinates? coordonnees)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
return $default(_that.nom,_that.description,_that.deeplinkUrl,_that.coordonnees);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nom,  String description,  String? deeplinkUrl,  GuideCoordinates? coordonnees)  $default,) {final _that = this;
switch (_that) {
case _GuideItem():
return $default(_that.nom,_that.description,_that.deeplinkUrl,_that.coordonnees);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nom,  String description,  String? deeplinkUrl,  GuideCoordinates? coordonnees)?  $default,) {final _that = this;
switch (_that) {
case _GuideItem() when $default != null:
return $default(_that.nom,_that.description,_that.deeplinkUrl,_that.coordonnees);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuideItem extends GuideItem {
  const _GuideItem({required this.nom, required this.description, this.deeplinkUrl, this.coordonnees}): super._();
  factory _GuideItem.fromJson(Map<String, dynamic> json) => _$GuideItemFromJson(json);

/// Nom de l'item/prestataire (ex « Epicerie du village »).
@override final  String nom;
/// Description courte (horaires, specificites, conseils pratiques).
@override final  String description;
/// Lien deeplink SORTANT vers le site/app du prestataire (facilitateur,
/// #84100). Null = pas de lien (l'UI masque alors le bouton).
@override final  String? deeplinkUrl;
/// Coordonnees de l'item si cartographiable (null sinon).
@override final  GuideCoordinates? coordonnees;

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideItemCopyWith<_GuideItem> get copyWith => __$GuideItemCopyWithImpl<_GuideItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuideItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideItem&&(identical(other.nom, nom) || other.nom == nom)&&(identical(other.description, description) || other.description == description)&&(identical(other.deeplinkUrl, deeplinkUrl) || other.deeplinkUrl == deeplinkUrl)&&(identical(other.coordonnees, coordonnees) || other.coordonnees == coordonnees));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nom,description,deeplinkUrl,coordonnees);

@override
String toString() {
  return 'GuideItem(nom: $nom, description: $description, deeplinkUrl: $deeplinkUrl, coordonnees: $coordonnees)';
}


}

/// @nodoc
abstract mixin class _$GuideItemCopyWith<$Res> implements $GuideItemCopyWith<$Res> {
  factory _$GuideItemCopyWith(_GuideItem value, $Res Function(_GuideItem) _then) = __$GuideItemCopyWithImpl;
@override @useResult
$Res call({
 String nom, String description, String? deeplinkUrl, GuideCoordinates? coordonnees
});


@override $GuideCoordinatesCopyWith<$Res>? get coordonnees;

}
/// @nodoc
class __$GuideItemCopyWithImpl<$Res>
    implements _$GuideItemCopyWith<$Res> {
  __$GuideItemCopyWithImpl(this._self, this._then);

  final _GuideItem _self;
  final $Res Function(_GuideItem) _then;

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nom = null,Object? description = null,Object? deeplinkUrl = freezed,Object? coordonnees = freezed,}) {
  return _then(_GuideItem(
nom: null == nom ? _self.nom : nom // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,deeplinkUrl: freezed == deeplinkUrl ? _self.deeplinkUrl : deeplinkUrl // ignore: cast_nullable_to_non_nullable
as String?,coordonnees: freezed == coordonnees ? _self.coordonnees : coordonnees // ignore: cast_nullable_to_non_nullable
as GuideCoordinates?,
  ));
}

/// Create a copy of GuideItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuideCoordinatesCopyWith<$Res>? get coordonnees {
    if (_self.coordonnees == null) {
    return null;
  }

  return $GuideCoordinatesCopyWith<$Res>(_self.coordonnees!, (value) {
    return _then(_self.copyWith(coordonnees: value));
  });
}
}


/// @nodoc
mixin _$GuideSection {

/// Categorie de la section ([GuideCategory]).
 String get categorie;/// Titre localise de la section (ex « Ravitaillement »).
 String get titre;/// Contenu introductif localise (paragraphe d'en-tete, peut etre vide).
 String get contenu;/// Items de la section (prestataires/points pratiques).
 List<GuideItem> get items;
/// Create a copy of GuideSection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuideSectionCopyWith<GuideSection> get copyWith => _$GuideSectionCopyWithImpl<GuideSection>(this as GuideSection, _$identity);

  /// Serializes this GuideSection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuideSection&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.contenu, contenu) || other.contenu == contenu)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categorie,titre,contenu,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'GuideSection(categorie: $categorie, titre: $titre, contenu: $contenu, items: $items)';
}


}

/// @nodoc
abstract mixin class $GuideSectionCopyWith<$Res>  {
  factory $GuideSectionCopyWith(GuideSection value, $Res Function(GuideSection) _then) = _$GuideSectionCopyWithImpl;
@useResult
$Res call({
 String categorie, String titre, String contenu, List<GuideItem> items
});




}
/// @nodoc
class _$GuideSectionCopyWithImpl<$Res>
    implements $GuideSectionCopyWith<$Res> {
  _$GuideSectionCopyWithImpl(this._self, this._then);

  final GuideSection _self;
  final $Res Function(GuideSection) _then;

/// Create a copy of GuideSection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categorie = null,Object? titre = null,Object? contenu = null,Object? items = null,}) {
  return _then(_self.copyWith(
categorie: null == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,contenu: null == contenu ? _self.contenu : contenu // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [GuideSection].
extension GuideSectionPatterns on GuideSection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuideSection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuideSection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuideSection value)  $default,){
final _that = this;
switch (_that) {
case _GuideSection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuideSection value)?  $default,){
final _that = this;
switch (_that) {
case _GuideSection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String categorie,  String titre,  String contenu,  List<GuideItem> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuideSection() when $default != null:
return $default(_that.categorie,_that.titre,_that.contenu,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String categorie,  String titre,  String contenu,  List<GuideItem> items)  $default,) {final _that = this;
switch (_that) {
case _GuideSection():
return $default(_that.categorie,_that.titre,_that.contenu,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String categorie,  String titre,  String contenu,  List<GuideItem> items)?  $default,) {final _that = this;
switch (_that) {
case _GuideSection() when $default != null:
return $default(_that.categorie,_that.titre,_that.contenu,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuideSection extends GuideSection {
  const _GuideSection({required this.categorie, required this.titre, this.contenu = '', final  List<GuideItem> items = const <GuideItem>[]}): _items = items,super._();
  factory _GuideSection.fromJson(Map<String, dynamic> json) => _$GuideSectionFromJson(json);

/// Categorie de la section ([GuideCategory]).
@override final  String categorie;
/// Titre localise de la section (ex « Ravitaillement »).
@override final  String titre;
/// Contenu introductif localise (paragraphe d'en-tete, peut etre vide).
@override@JsonKey() final  String contenu;
/// Items de la section (prestataires/points pratiques).
 final  List<GuideItem> _items;
/// Items de la section (prestataires/points pratiques).
@override@JsonKey() List<GuideItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of GuideSection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuideSectionCopyWith<_GuideSection> get copyWith => __$GuideSectionCopyWithImpl<_GuideSection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuideSectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuideSection&&(identical(other.categorie, categorie) || other.categorie == categorie)&&(identical(other.titre, titre) || other.titre == titre)&&(identical(other.contenu, contenu) || other.contenu == contenu)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,categorie,titre,contenu,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'GuideSection(categorie: $categorie, titre: $titre, contenu: $contenu, items: $items)';
}


}

/// @nodoc
abstract mixin class _$GuideSectionCopyWith<$Res> implements $GuideSectionCopyWith<$Res> {
  factory _$GuideSectionCopyWith(_GuideSection value, $Res Function(_GuideSection) _then) = __$GuideSectionCopyWithImpl;
@override @useResult
$Res call({
 String categorie, String titre, String contenu, List<GuideItem> items
});




}
/// @nodoc
class __$GuideSectionCopyWithImpl<$Res>
    implements _$GuideSectionCopyWith<$Res> {
  __$GuideSectionCopyWithImpl(this._self, this._then);

  final _GuideSection _self;
  final $Res Function(_GuideSection) _then;

/// Create a copy of GuideSection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categorie = null,Object? titre = null,Object? contenu = null,Object? items = null,}) {
  return _then(_GuideSection(
categorie: null == categorie ? _self.categorie : categorie // ignore: cast_nullable_to_non_nullable
as String,titre: null == titre ? _self.titre : titre // ignore: cast_nullable_to_non_nullable
as String,contenu: null == contenu ? _self.contenu : contenu // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<GuideItem>,
  ));
}


}


/// @nodoc
mixin _$TownGuide {

/// Identifiant unique du guide (ex 'mam_corte').
 String get id;/// Identifiant du sentier auquel ce guide appartient (genericite #84627).
 String get trailId;/// Nom du lieu (ville/village d'etape, ex « Corte »).
 String get nomLieu;/// Latitude de la localite en degres decimaux (WGS84).
 double get latitude;/// Longitude de la localite en degres decimaux (WGS84).
 double get longitude;/// Sections thematiques du guide (ravitaillement, hebergement, etc.).
 List<GuideSection> get sections;
/// Create a copy of TownGuide
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TownGuideCopyWith<TownGuide> get copyWith => _$TownGuideCopyWithImpl<TownGuide>(this as TownGuide, _$identity);

  /// Serializes this TownGuide to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TownGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.nomLieu, nomLieu) || other.nomLieu == nomLieu)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other.sections, sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,nomLieu,latitude,longitude,const DeepCollectionEquality().hash(sections));

@override
String toString() {
  return 'TownGuide(id: $id, trailId: $trailId, nomLieu: $nomLieu, latitude: $latitude, longitude: $longitude, sections: $sections)';
}


}

/// @nodoc
abstract mixin class $TownGuideCopyWith<$Res>  {
  factory $TownGuideCopyWith(TownGuide value, $Res Function(TownGuide) _then) = _$TownGuideCopyWithImpl;
@useResult
$Res call({
 String id, String trailId, String nomLieu, double latitude, double longitude, List<GuideSection> sections
});




}
/// @nodoc
class _$TownGuideCopyWithImpl<$Res>
    implements $TownGuideCopyWith<$Res> {
  _$TownGuideCopyWithImpl(this._self, this._then);

  final TownGuide _self;
  final $Res Function(TownGuide) _then;

/// Create a copy of TownGuide
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trailId = null,Object? nomLieu = null,Object? latitude = null,Object? longitude = null,Object? sections = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,nomLieu: null == nomLieu ? _self.nomLieu : nomLieu // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,sections: null == sections ? _self.sections : sections // ignore: cast_nullable_to_non_nullable
as List<GuideSection>,
  ));
}

}


/// Adds pattern-matching-related methods to [TownGuide].
extension TownGuidePatterns on TownGuide {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TownGuide value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TownGuide() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TownGuide value)  $default,){
final _that = this;
switch (_that) {
case _TownGuide():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TownGuide value)?  $default,){
final _that = this;
switch (_that) {
case _TownGuide() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String trailId,  String nomLieu,  double latitude,  double longitude,  List<GuideSection> sections)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TownGuide() when $default != null:
return $default(_that.id,_that.trailId,_that.nomLieu,_that.latitude,_that.longitude,_that.sections);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String trailId,  String nomLieu,  double latitude,  double longitude,  List<GuideSection> sections)  $default,) {final _that = this;
switch (_that) {
case _TownGuide():
return $default(_that.id,_that.trailId,_that.nomLieu,_that.latitude,_that.longitude,_that.sections);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String trailId,  String nomLieu,  double latitude,  double longitude,  List<GuideSection> sections)?  $default,) {final _that = this;
switch (_that) {
case _TownGuide() when $default != null:
return $default(_that.id,_that.trailId,_that.nomLieu,_that.latitude,_that.longitude,_that.sections);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TownGuide extends TownGuide {
  const _TownGuide({required this.id, required this.trailId, required this.nomLieu, required this.latitude, required this.longitude, final  List<GuideSection> sections = const <GuideSection>[]}): _sections = sections,super._();
  factory _TownGuide.fromJson(Map<String, dynamic> json) => _$TownGuideFromJson(json);

/// Identifiant unique du guide (ex 'mam_corte').
@override final  String id;
/// Identifiant du sentier auquel ce guide appartient (genericite #84627).
@override final  String trailId;
/// Nom du lieu (ville/village d'etape, ex « Corte »).
@override final  String nomLieu;
/// Latitude de la localite en degres decimaux (WGS84).
@override final  double latitude;
/// Longitude de la localite en degres decimaux (WGS84).
@override final  double longitude;
/// Sections thematiques du guide (ravitaillement, hebergement, etc.).
 final  List<GuideSection> _sections;
/// Sections thematiques du guide (ravitaillement, hebergement, etc.).
@override@JsonKey() List<GuideSection> get sections {
  if (_sections is EqualUnmodifiableListView) return _sections;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sections);
}


/// Create a copy of TownGuide
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TownGuideCopyWith<_TownGuide> get copyWith => __$TownGuideCopyWithImpl<_TownGuide>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TownGuideToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TownGuide&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.nomLieu, nomLieu) || other.nomLieu == nomLieu)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&const DeepCollectionEquality().equals(other._sections, _sections));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,nomLieu,latitude,longitude,const DeepCollectionEquality().hash(_sections));

@override
String toString() {
  return 'TownGuide(id: $id, trailId: $trailId, nomLieu: $nomLieu, latitude: $latitude, longitude: $longitude, sections: $sections)';
}


}

/// @nodoc
abstract mixin class _$TownGuideCopyWith<$Res> implements $TownGuideCopyWith<$Res> {
  factory _$TownGuideCopyWith(_TownGuide value, $Res Function(_TownGuide) _then) = __$TownGuideCopyWithImpl;
@override @useResult
$Res call({
 String id, String trailId, String nomLieu, double latitude, double longitude, List<GuideSection> sections
});




}
/// @nodoc
class __$TownGuideCopyWithImpl<$Res>
    implements _$TownGuideCopyWith<$Res> {
  __$TownGuideCopyWithImpl(this._self, this._then);

  final _TownGuide _self;
  final $Res Function(_TownGuide) _then;

/// Create a copy of TownGuide
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trailId = null,Object? nomLieu = null,Object? latitude = null,Object? longitude = null,Object? sections = null,}) {
  return _then(_TownGuide(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,nomLieu: null == nomLieu ? _self.nomLieu : nomLieu // ignore: cast_nullable_to_non_nullable
as String,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,sections: null == sections ? _self._sections : sections // ignore: cast_nullable_to_non_nullable
as List<GuideSection>,
  ));
}


}

// dart format on
