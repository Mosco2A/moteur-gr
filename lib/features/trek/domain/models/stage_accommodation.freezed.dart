// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage_accommodation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StageAccommodation {

/// Identifiant unique (UUID du JSON sentier)
 String get id;/// Reference vers l'etape (trail_stages.id)
 String get stageId;/// Numero de l'etape (depuis la jointure trail_stages)
 int get stageNumber;/// Nom en francais
 String get nameFr;/// Nom en anglais
 String get nameEn;/// Type d'hebergement
 AccommodationType get type;/// Latitude WGS84
 double get lat;/// Longitude WGS84
 double get lng;/// Telephone (nullable)
 String? get phone;/// Email (nullable)
 String? get email;/// Site web (nullable)
 String? get website;/// Capacite d'accueil (nullable)
 int? get capacity;/// Fourchette de prix (nullable, ex: '30-50EUR')
 String? get priceRange;/// URL de reservation (nullable)
 String? get bookingUrl;
/// Create a copy of StageAccommodation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageAccommodationCopyWith<StageAccommodation> get copyWith => _$StageAccommodationCopyWithImpl<StageAccommodation>(this as StageAccommodation, _$identity);

  /// Serializes this StageAccommodation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageAccommodation&&(identical(other.id, id) || other.id == id)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.nameFr, nameFr) || other.nameFr == nameFr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.type, type) || other.type == type)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.priceRange, priceRange) || other.priceRange == priceRange)&&(identical(other.bookingUrl, bookingUrl) || other.bookingUrl == bookingUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stageId,stageNumber,nameFr,nameEn,type,lat,lng,phone,email,website,capacity,priceRange,bookingUrl);

@override
String toString() {
  return 'StageAccommodation(id: $id, stageId: $stageId, stageNumber: $stageNumber, nameFr: $nameFr, nameEn: $nameEn, type: $type, lat: $lat, lng: $lng, phone: $phone, email: $email, website: $website, capacity: $capacity, priceRange: $priceRange, bookingUrl: $bookingUrl)';
}


}

/// @nodoc
abstract mixin class $StageAccommodationCopyWith<$Res>  {
  factory $StageAccommodationCopyWith(StageAccommodation value, $Res Function(StageAccommodation) _then) = _$StageAccommodationCopyWithImpl;
@useResult
$Res call({
 String id, String stageId, int stageNumber, String nameFr, String nameEn, AccommodationType type, double lat, double lng, String? phone, String? email, String? website, int? capacity, String? priceRange, String? bookingUrl
});




}
/// @nodoc
class _$StageAccommodationCopyWithImpl<$Res>
    implements $StageAccommodationCopyWith<$Res> {
  _$StageAccommodationCopyWithImpl(this._self, this._then);

  final StageAccommodation _self;
  final $Res Function(StageAccommodation) _then;

/// Create a copy of StageAccommodation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stageId = null,Object? stageNumber = null,Object? nameFr = null,Object? nameEn = null,Object? type = null,Object? lat = null,Object? lng = null,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? capacity = freezed,Object? priceRange = freezed,Object? bookingUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,nameFr: null == nameFr ? _self.nameFr : nameFr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccommodationType,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,priceRange: freezed == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as String?,bookingUrl: freezed == bookingUrl ? _self.bookingUrl : bookingUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StageAccommodation].
extension StageAccommodationPatterns on StageAccommodation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageAccommodation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageAccommodation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageAccommodation value)  $default,){
final _that = this;
switch (_that) {
case _StageAccommodation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageAccommodation value)?  $default,){
final _that = this;
switch (_that) {
case _StageAccommodation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String stageId,  int stageNumber,  String nameFr,  String nameEn,  AccommodationType type,  double lat,  double lng,  String? phone,  String? email,  String? website,  int? capacity,  String? priceRange,  String? bookingUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageAccommodation() when $default != null:
return $default(_that.id,_that.stageId,_that.stageNumber,_that.nameFr,_that.nameEn,_that.type,_that.lat,_that.lng,_that.phone,_that.email,_that.website,_that.capacity,_that.priceRange,_that.bookingUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String stageId,  int stageNumber,  String nameFr,  String nameEn,  AccommodationType type,  double lat,  double lng,  String? phone,  String? email,  String? website,  int? capacity,  String? priceRange,  String? bookingUrl)  $default,) {final _that = this;
switch (_that) {
case _StageAccommodation():
return $default(_that.id,_that.stageId,_that.stageNumber,_that.nameFr,_that.nameEn,_that.type,_that.lat,_that.lng,_that.phone,_that.email,_that.website,_that.capacity,_that.priceRange,_that.bookingUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String stageId,  int stageNumber,  String nameFr,  String nameEn,  AccommodationType type,  double lat,  double lng,  String? phone,  String? email,  String? website,  int? capacity,  String? priceRange,  String? bookingUrl)?  $default,) {final _that = this;
switch (_that) {
case _StageAccommodation() when $default != null:
return $default(_that.id,_that.stageId,_that.stageNumber,_that.nameFr,_that.nameEn,_that.type,_that.lat,_that.lng,_that.phone,_that.email,_that.website,_that.capacity,_that.priceRange,_that.bookingUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageAccommodation extends StageAccommodation {
  const _StageAccommodation({required this.id, required this.stageId, required this.stageNumber, required this.nameFr, this.nameEn = '', required this.type, required this.lat, required this.lng, this.phone, this.email, this.website, this.capacity, this.priceRange, this.bookingUrl}): super._();
  factory _StageAccommodation.fromJson(Map<String, dynamic> json) => _$StageAccommodationFromJson(json);

/// Identifiant unique (UUID du JSON sentier)
@override final  String id;
/// Reference vers l'etape (trail_stages.id)
@override final  String stageId;
/// Numero de l'etape (depuis la jointure trail_stages)
@override final  int stageNumber;
/// Nom en francais
@override final  String nameFr;
/// Nom en anglais
@override@JsonKey() final  String nameEn;
/// Type d'hebergement
@override final  AccommodationType type;
/// Latitude WGS84
@override final  double lat;
/// Longitude WGS84
@override final  double lng;
/// Telephone (nullable)
@override final  String? phone;
/// Email (nullable)
@override final  String? email;
/// Site web (nullable)
@override final  String? website;
/// Capacite d'accueil (nullable)
@override final  int? capacity;
/// Fourchette de prix (nullable, ex: '30-50EUR')
@override final  String? priceRange;
/// URL de reservation (nullable)
@override final  String? bookingUrl;

/// Create a copy of StageAccommodation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageAccommodationCopyWith<_StageAccommodation> get copyWith => __$StageAccommodationCopyWithImpl<_StageAccommodation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageAccommodationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageAccommodation&&(identical(other.id, id) || other.id == id)&&(identical(other.stageId, stageId) || other.stageId == stageId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.nameFr, nameFr) || other.nameFr == nameFr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.type, type) || other.type == type)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.website, website) || other.website == website)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.priceRange, priceRange) || other.priceRange == priceRange)&&(identical(other.bookingUrl, bookingUrl) || other.bookingUrl == bookingUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stageId,stageNumber,nameFr,nameEn,type,lat,lng,phone,email,website,capacity,priceRange,bookingUrl);

@override
String toString() {
  return 'StageAccommodation(id: $id, stageId: $stageId, stageNumber: $stageNumber, nameFr: $nameFr, nameEn: $nameEn, type: $type, lat: $lat, lng: $lng, phone: $phone, email: $email, website: $website, capacity: $capacity, priceRange: $priceRange, bookingUrl: $bookingUrl)';
}


}

/// @nodoc
abstract mixin class _$StageAccommodationCopyWith<$Res> implements $StageAccommodationCopyWith<$Res> {
  factory _$StageAccommodationCopyWith(_StageAccommodation value, $Res Function(_StageAccommodation) _then) = __$StageAccommodationCopyWithImpl;
@override @useResult
$Res call({
 String id, String stageId, int stageNumber, String nameFr, String nameEn, AccommodationType type, double lat, double lng, String? phone, String? email, String? website, int? capacity, String? priceRange, String? bookingUrl
});




}
/// @nodoc
class __$StageAccommodationCopyWithImpl<$Res>
    implements _$StageAccommodationCopyWith<$Res> {
  __$StageAccommodationCopyWithImpl(this._self, this._then);

  final _StageAccommodation _self;
  final $Res Function(_StageAccommodation) _then;

/// Create a copy of StageAccommodation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stageId = null,Object? stageNumber = null,Object? nameFr = null,Object? nameEn = null,Object? type = null,Object? lat = null,Object? lng = null,Object? phone = freezed,Object? email = freezed,Object? website = freezed,Object? capacity = freezed,Object? priceRange = freezed,Object? bookingUrl = freezed,}) {
  return _then(_StageAccommodation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,stageId: null == stageId ? _self.stageId : stageId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,nameFr: null == nameFr ? _self.nameFr : nameFr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AccommodationType,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,website: freezed == website ? _self.website : website // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,priceRange: freezed == priceRange ? _self.priceRange : priceRange // ignore: cast_nullable_to_non_nullable
as String?,bookingUrl: freezed == bookingUrl ? _self.bookingUrl : bookingUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
