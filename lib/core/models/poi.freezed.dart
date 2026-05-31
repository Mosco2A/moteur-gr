// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PoiModel {

/// Cle primaire DB (0 si pas encore insere)
 int get id;/// Identifiant du sentier parent
 String get trailId;/// Numero de l'etape associee
 int get stageNumber;/// Nom du POI
 String get name;/// Description
 String get description;/// Type de POI (String extensible, ex: water, refuge, danger)
 String get type;/// Latitude
 double get lat;/// Longitude
 double get lng;/// Altitude en metres
 int get altitudeM;/// Horaires d'ouverture (nullable)
 String? get openingHours;
/// Create a copy of PoiModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoiModelCopyWith<PoiModel> get copyWith => _$PoiModelCopyWithImpl<PoiModel>(this as PoiModel, _$identity);

  /// Serializes this PoiModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.altitudeM, altitudeM) || other.altitudeM == altitudeM)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,stageNumber,name,description,type,lat,lng,altitudeM,openingHours);

@override
String toString() {
  return 'PoiModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, description: $description, type: $type, lat: $lat, lng: $lng, altitudeM: $altitudeM, openingHours: $openingHours)';
}


}

/// @nodoc
abstract mixin class $PoiModelCopyWith<$Res>  {
  factory $PoiModelCopyWith(PoiModel value, $Res Function(PoiModel) _then) = _$PoiModelCopyWithImpl;
@useResult
$Res call({
 int id, String trailId, int stageNumber, String name, String description, String type, double lat, double lng, int altitudeM, String? openingHours
});




}
/// @nodoc
class _$PoiModelCopyWithImpl<$Res>
    implements $PoiModelCopyWith<$Res> {
  _$PoiModelCopyWithImpl(this._self, this._then);

  final PoiModel _self;
  final $Res Function(PoiModel) _then;

/// Create a copy of PoiModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trailId = null,Object? stageNumber = null,Object? name = null,Object? description = null,Object? type = null,Object? lat = null,Object? lng = null,Object? altitudeM = null,Object? openingHours = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,altitudeM: null == altitudeM ? _self.altitudeM : altitudeM // ignore: cast_nullable_to_non_nullable
as int,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PoiModel].
extension PoiModelPatterns on PoiModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoiModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoiModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoiModel value)  $default,){
final _that = this;
switch (_that) {
case _PoiModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoiModel value)?  $default,){
final _that = this;
switch (_that) {
case _PoiModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String trailId,  int stageNumber,  String name,  String description,  String type,  double lat,  double lng,  int altitudeM,  String? openingHours)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoiModel() when $default != null:
return $default(_that.id,_that.trailId,_that.stageNumber,_that.name,_that.description,_that.type,_that.lat,_that.lng,_that.altitudeM,_that.openingHours);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String trailId,  int stageNumber,  String name,  String description,  String type,  double lat,  double lng,  int altitudeM,  String? openingHours)  $default,) {final _that = this;
switch (_that) {
case _PoiModel():
return $default(_that.id,_that.trailId,_that.stageNumber,_that.name,_that.description,_that.type,_that.lat,_that.lng,_that.altitudeM,_that.openingHours);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String trailId,  int stageNumber,  String name,  String description,  String type,  double lat,  double lng,  int altitudeM,  String? openingHours)?  $default,) {final _that = this;
switch (_that) {
case _PoiModel() when $default != null:
return $default(_that.id,_that.trailId,_that.stageNumber,_that.name,_that.description,_that.type,_that.lat,_that.lng,_that.altitudeM,_that.openingHours);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PoiModel extends PoiModel {
  const _PoiModel({this.id = 0, required this.trailId, required this.stageNumber, required this.name, this.description = '', required this.type, required this.lat, required this.lng, this.altitudeM = 0, this.openingHours}): super._();
  factory _PoiModel.fromJson(Map<String, dynamic> json) => _$PoiModelFromJson(json);

/// Cle primaire DB (0 si pas encore insere)
@override@JsonKey() final  int id;
/// Identifiant du sentier parent
@override final  String trailId;
/// Numero de l'etape associee
@override final  int stageNumber;
/// Nom du POI
@override final  String name;
/// Description
@override@JsonKey() final  String description;
/// Type de POI (String extensible, ex: water, refuge, danger)
@override final  String type;
/// Latitude
@override final  double lat;
/// Longitude
@override final  double lng;
/// Altitude en metres
@override@JsonKey() final  int altitudeM;
/// Horaires d'ouverture (nullable)
@override final  String? openingHours;

/// Create a copy of PoiModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoiModelCopyWith<_PoiModel> get copyWith => __$PoiModelCopyWithImpl<_PoiModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoiModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoiModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.type, type) || other.type == type)&&(identical(other.lat, lat) || other.lat == lat)&&(identical(other.lng, lng) || other.lng == lng)&&(identical(other.altitudeM, altitudeM) || other.altitudeM == altitudeM)&&(identical(other.openingHours, openingHours) || other.openingHours == openingHours));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,stageNumber,name,description,type,lat,lng,altitudeM,openingHours);

@override
String toString() {
  return 'PoiModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, description: $description, type: $type, lat: $lat, lng: $lng, altitudeM: $altitudeM, openingHours: $openingHours)';
}


}

/// @nodoc
abstract mixin class _$PoiModelCopyWith<$Res> implements $PoiModelCopyWith<$Res> {
  factory _$PoiModelCopyWith(_PoiModel value, $Res Function(_PoiModel) _then) = __$PoiModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String trailId, int stageNumber, String name, String description, String type, double lat, double lng, int altitudeM, String? openingHours
});




}
/// @nodoc
class __$PoiModelCopyWithImpl<$Res>
    implements _$PoiModelCopyWith<$Res> {
  __$PoiModelCopyWithImpl(this._self, this._then);

  final _PoiModel _self;
  final $Res Function(_PoiModel) _then;

/// Create a copy of PoiModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trailId = null,Object? stageNumber = null,Object? name = null,Object? description = null,Object? type = null,Object? lat = null,Object? lng = null,Object? altitudeM = null,Object? openingHours = freezed,}) {
  return _then(_PoiModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,lat: null == lat ? _self.lat : lat // ignore: cast_nullable_to_non_nullable
as double,lng: null == lng ? _self.lng : lng // ignore: cast_nullable_to_non_nullable
as double,altitudeM: null == altitudeM ? _self.altitudeM : altitudeM // ignore: cast_nullable_to_non_nullable
as int,openingHours: freezed == openingHours ? _self.openingHours : openingHours // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
