// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goodie_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoodieProduct {

/// Identifiant unique du produit
 String get id;/// Nom du produit (cle i18n pour resolution via Slang)
 String get name;/// Description du produit (cle i18n pour resolution via Slang)
 String get description;/// Type de produit -- String extensible (tshirt, mug, patch, sticker, poster, ...)
 String get type;/// Prix en centimes (ex: 1990 = 19.90 EUR)
 int get price;/// Chemin vers l'image du produit (asset ou URL)
 String? get image;/// Indique si le produit est personnalisable (nom, date, etape, etc.)
 bool get personalizable;/// Indique si le produit est specifique a un sentier
 bool get trailSpecific;
/// Create a copy of GoodieProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoodieProductCopyWith<GoodieProduct> get copyWith => _$GoodieProductCopyWithImpl<GoodieProduct>(this as GoodieProduct, _$identity);

  /// Serializes this GoodieProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoodieProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.price, price) || other.price == price)&&(identical(other.image, image) || other.image == image)&&(identical(other.personalizable, personalizable) || other.personalizable == personalizable)&&(identical(other.trailSpecific, trailSpecific) || other.trailSpecific == trailSpecific));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,type,price,image,personalizable,trailSpecific);

@override
String toString() {
  return 'GoodieProduct(id: $id, name: $name, description: $description, type: $type, price: $price, image: $image, personalizable: $personalizable, trailSpecific: $trailSpecific)';
}


}

/// @nodoc
abstract mixin class $GoodieProductCopyWith<$Res>  {
  factory $GoodieProductCopyWith(GoodieProduct value, $Res Function(GoodieProduct) _then) = _$GoodieProductCopyWithImpl;
@useResult
$Res call({
 String id, String name, String description, String type, int price, String? image, bool personalizable, bool trailSpecific
});




}
/// @nodoc
class _$GoodieProductCopyWithImpl<$Res>
    implements $GoodieProductCopyWith<$Res> {
  _$GoodieProductCopyWithImpl(this._self, this._then);

  final GoodieProduct _self;
  final $Res Function(GoodieProduct) _then;

/// Create a copy of GoodieProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = null,Object? type = null,Object? price = null,Object? image = freezed,Object? personalizable = null,Object? trailSpecific = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,personalizable: null == personalizable ? _self.personalizable : personalizable // ignore: cast_nullable_to_non_nullable
as bool,trailSpecific: null == trailSpecific ? _self.trailSpecific : trailSpecific // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GoodieProduct].
extension GoodieProductPatterns on GoodieProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoodieProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoodieProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoodieProduct value)  $default,){
final _that = this;
switch (_that) {
case _GoodieProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoodieProduct value)?  $default,){
final _that = this;
switch (_that) {
case _GoodieProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String type,  int price,  String? image,  bool personalizable,  bool trailSpecific)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoodieProduct() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.type,_that.price,_that.image,_that.personalizable,_that.trailSpecific);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String description,  String type,  int price,  String? image,  bool personalizable,  bool trailSpecific)  $default,) {final _that = this;
switch (_that) {
case _GoodieProduct():
return $default(_that.id,_that.name,_that.description,_that.type,_that.price,_that.image,_that.personalizable,_that.trailSpecific);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String description,  String type,  int price,  String? image,  bool personalizable,  bool trailSpecific)?  $default,) {final _that = this;
switch (_that) {
case _GoodieProduct() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.type,_that.price,_that.image,_that.personalizable,_that.trailSpecific);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoodieProduct extends GoodieProduct {
  const _GoodieProduct({required this.id, required this.name, this.description = '', required this.type, required this.price, this.image, this.personalizable = false, this.trailSpecific = false}): super._();
  factory _GoodieProduct.fromJson(Map<String, dynamic> json) => _$GoodieProductFromJson(json);

/// Identifiant unique du produit
@override final  String id;
/// Nom du produit (cle i18n pour resolution via Slang)
@override final  String name;
/// Description du produit (cle i18n pour resolution via Slang)
@override@JsonKey() final  String description;
/// Type de produit -- String extensible (tshirt, mug, patch, sticker, poster, ...)
@override final  String type;
/// Prix en centimes (ex: 1990 = 19.90 EUR)
@override final  int price;
/// Chemin vers l'image du produit (asset ou URL)
@override final  String? image;
/// Indique si le produit est personnalisable (nom, date, etape, etc.)
@override@JsonKey() final  bool personalizable;
/// Indique si le produit est specifique a un sentier
@override@JsonKey() final  bool trailSpecific;

/// Create a copy of GoodieProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoodieProductCopyWith<_GoodieProduct> get copyWith => __$GoodieProductCopyWithImpl<_GoodieProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoodieProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoodieProduct&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.price, price) || other.price == price)&&(identical(other.image, image) || other.image == image)&&(identical(other.personalizable, personalizable) || other.personalizable == personalizable)&&(identical(other.trailSpecific, trailSpecific) || other.trailSpecific == trailSpecific));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,type,price,image,personalizable,trailSpecific);

@override
String toString() {
  return 'GoodieProduct(id: $id, name: $name, description: $description, type: $type, price: $price, image: $image, personalizable: $personalizable, trailSpecific: $trailSpecific)';
}


}

/// @nodoc
abstract mixin class _$GoodieProductCopyWith<$Res> implements $GoodieProductCopyWith<$Res> {
  factory _$GoodieProductCopyWith(_GoodieProduct value, $Res Function(_GoodieProduct) _then) = __$GoodieProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String description, String type, int price, String? image, bool personalizable, bool trailSpecific
});




}
/// @nodoc
class __$GoodieProductCopyWithImpl<$Res>
    implements _$GoodieProductCopyWith<$Res> {
  __$GoodieProductCopyWithImpl(this._self, this._then);

  final _GoodieProduct _self;
  final $Res Function(_GoodieProduct) _then;

/// Create a copy of GoodieProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = null,Object? type = null,Object? price = null,Object? image = freezed,Object? personalizable = null,Object? trailSpecific = null,}) {
  return _then(_GoodieProduct(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as int,image: freezed == image ? _self.image : image // ignore: cast_nullable_to_non_nullable
as String?,personalizable: null == personalizable ? _self.personalizable : personalizable // ignore: cast_nullable_to_non_nullable
as bool,trailSpecific: null == trailSpecific ? _self.trailSpecific : trailSpecific // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
