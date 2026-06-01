// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goodie_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GoodieOrder {

/// Identifiant unique de la commande
 String get id;/// Identifiant du produit commande
 String get productId;/// Identifiant du sentier associe (ex: 'gr20')
 String get trailId;/// Quantite commandee
 int get quantity;/// Prix total en centimes
 int get totalPrice;/// Statut de la commande -- String extensible (pending, confirmed, shipped, delivered, cancelled, ...)
 String get status;/// Date de creation de la commande
 DateTime get createdAt;/// Date de derniere mise a jour (null si jamais modifiee)
 DateTime? get updatedAt;
/// Create a copy of GoodieOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoodieOrderCopyWith<GoodieOrder> get copyWith => _$GoodieOrderCopyWithImpl<GoodieOrder>(this as GoodieOrder, _$identity);

  /// Serializes this GoodieOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GoodieOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productId,trailId,quantity,totalPrice,status,createdAt,updatedAt);

@override
String toString() {
  return 'GoodieOrder(id: $id, productId: $productId, trailId: $trailId, quantity: $quantity, totalPrice: $totalPrice, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GoodieOrderCopyWith<$Res>  {
  factory $GoodieOrderCopyWith(GoodieOrder value, $Res Function(GoodieOrder) _then) = _$GoodieOrderCopyWithImpl;
@useResult
$Res call({
 String id, String productId, String trailId, int quantity, int totalPrice, String status, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$GoodieOrderCopyWithImpl<$Res>
    implements $GoodieOrderCopyWith<$Res> {
  _$GoodieOrderCopyWithImpl(this._self, this._then);

  final GoodieOrder _self;
  final $Res Function(GoodieOrder) _then;

/// Create a copy of GoodieOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? trailId = null,Object? quantity = null,Object? totalPrice = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [GoodieOrder].
extension GoodieOrderPatterns on GoodieOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GoodieOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GoodieOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GoodieOrder value)  $default,){
final _that = this;
switch (_that) {
case _GoodieOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GoodieOrder value)?  $default,){
final _that = this;
switch (_that) {
case _GoodieOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String productId,  String trailId,  int quantity,  int totalPrice,  String status,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GoodieOrder() when $default != null:
return $default(_that.id,_that.productId,_that.trailId,_that.quantity,_that.totalPrice,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String productId,  String trailId,  int quantity,  int totalPrice,  String status,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GoodieOrder():
return $default(_that.id,_that.productId,_that.trailId,_that.quantity,_that.totalPrice,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String productId,  String trailId,  int quantity,  int totalPrice,  String status,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GoodieOrder() when $default != null:
return $default(_that.id,_that.productId,_that.trailId,_that.quantity,_that.totalPrice,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GoodieOrder extends GoodieOrder {
  const _GoodieOrder({required this.id, required this.productId, required this.trailId, this.quantity = 1, required this.totalPrice, this.status = 'pending', required this.createdAt, this.updatedAt}): super._();
  factory _GoodieOrder.fromJson(Map<String, dynamic> json) => _$GoodieOrderFromJson(json);

/// Identifiant unique de la commande
@override final  String id;
/// Identifiant du produit commande
@override final  String productId;
/// Identifiant du sentier associe (ex: 'gr20')
@override final  String trailId;
/// Quantite commandee
@override@JsonKey() final  int quantity;
/// Prix total en centimes
@override final  int totalPrice;
/// Statut de la commande -- String extensible (pending, confirmed, shipped, delivered, cancelled, ...)
@override@JsonKey() final  String status;
/// Date de creation de la commande
@override final  DateTime createdAt;
/// Date de derniere mise a jour (null si jamais modifiee)
@override final  DateTime? updatedAt;

/// Create a copy of GoodieOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoodieOrderCopyWith<_GoodieOrder> get copyWith => __$GoodieOrderCopyWithImpl<_GoodieOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoodieOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GoodieOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.totalPrice, totalPrice) || other.totalPrice == totalPrice)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productId,trailId,quantity,totalPrice,status,createdAt,updatedAt);

@override
String toString() {
  return 'GoodieOrder(id: $id, productId: $productId, trailId: $trailId, quantity: $quantity, totalPrice: $totalPrice, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GoodieOrderCopyWith<$Res> implements $GoodieOrderCopyWith<$Res> {
  factory _$GoodieOrderCopyWith(_GoodieOrder value, $Res Function(_GoodieOrder) _then) = __$GoodieOrderCopyWithImpl;
@override @useResult
$Res call({
 String id, String productId, String trailId, int quantity, int totalPrice, String status, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$GoodieOrderCopyWithImpl<$Res>
    implements _$GoodieOrderCopyWith<$Res> {
  __$GoodieOrderCopyWithImpl(this._self, this._then);

  final _GoodieOrder _self;
  final $Res Function(_GoodieOrder) _then;

/// Create a copy of GoodieOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? trailId = null,Object? quantity = null,Object? totalPrice = null,Object? status = null,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_GoodieOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,totalPrice: null == totalPrice ? _self.totalPrice : totalPrice // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
