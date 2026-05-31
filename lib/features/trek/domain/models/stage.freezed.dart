// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Stage {

/// Identifiant unique de l'etape
 String get id;/// Nom — francais
 String get nameFr;/// Nom — anglais
 String get nameEn;/// Nom — allemand
 String get nameDe;/// Nom — italien
 String get nameIt;/// Nom — espagnol
 String get nameEs;/// Distance en kilometres
 double get distance;/// Denivele positif en metres
 int get elevationGain;/// Denivele negatif en metres
 int get elevationLoss;/// Duree estimee en secondes (serialisable)
 int get estimatedDurationSeconds;/// Difficulte — String extensible (easy, moderate, hard, extreme, ...)
 String get difficulty;/// Ordre d'affichage (1-indexed)
 int get orderIndex;/// Latitude du point de depart
 double get startLat;/// Longitude du point de depart
 double get startLng;/// Latitude du point d'arrivee
 double get endLat;/// Longitude du point d'arrivee
 double get endLng;/// Description — francais
 String get descriptionFr;/// Description — anglais
 String get descriptionEn;/// Description — allemand
 String get descriptionDe;/// Description — italien
 String get descriptionIt;/// Description — espagnol
 String get descriptionEs;
/// Create a copy of Stage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageCopyWith<Stage> get copyWith => _$StageCopyWithImpl<Stage>(this as Stage, _$identity);

  /// Serializes this Stage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Stage&&(identical(other.id, id) || other.id == id)&&(identical(other.nameFr, nameFr) || other.nameFr == nameFr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameDe, nameDe) || other.nameDe == nameDe)&&(identical(other.nameIt, nameIt) || other.nameIt == nameIt)&&(identical(other.nameEs, nameEs) || other.nameEs == nameEs)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.elevationGain, elevationGain) || other.elevationGain == elevationGain)&&(identical(other.elevationLoss, elevationLoss) || other.elevationLoss == elevationLoss)&&(identical(other.estimatedDurationSeconds, estimatedDurationSeconds) || other.estimatedDurationSeconds == estimatedDurationSeconds)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.startLat, startLat) || other.startLat == startLat)&&(identical(other.startLng, startLng) || other.startLng == startLng)&&(identical(other.endLat, endLat) || other.endLat == endLat)&&(identical(other.endLng, endLng) || other.endLng == endLng)&&(identical(other.descriptionFr, descriptionFr) || other.descriptionFr == descriptionFr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.descriptionDe, descriptionDe) || other.descriptionDe == descriptionDe)&&(identical(other.descriptionIt, descriptionIt) || other.descriptionIt == descriptionIt)&&(identical(other.descriptionEs, descriptionEs) || other.descriptionEs == descriptionEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameFr,nameEn,nameDe,nameIt,nameEs,distance,elevationGain,elevationLoss,estimatedDurationSeconds,difficulty,orderIndex,startLat,startLng,endLat,endLng,descriptionFr,descriptionEn,descriptionDe,descriptionIt,descriptionEs]);

@override
String toString() {
  return 'Stage(id: $id, nameFr: $nameFr, nameEn: $nameEn, nameDe: $nameDe, nameIt: $nameIt, nameEs: $nameEs, distance: $distance, elevationGain: $elevationGain, elevationLoss: $elevationLoss, estimatedDurationSeconds: $estimatedDurationSeconds, difficulty: $difficulty, orderIndex: $orderIndex, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, descriptionFr: $descriptionFr, descriptionEn: $descriptionEn, descriptionDe: $descriptionDe, descriptionIt: $descriptionIt, descriptionEs: $descriptionEs)';
}


}

/// @nodoc
abstract mixin class $StageCopyWith<$Res>  {
  factory $StageCopyWith(Stage value, $Res Function(Stage) _then) = _$StageCopyWithImpl;
@useResult
$Res call({
 String id, String nameFr, String nameEn, String nameDe, String nameIt, String nameEs, double distance, int elevationGain, int elevationLoss, int estimatedDurationSeconds, String difficulty, int orderIndex, double startLat, double startLng, double endLat, double endLng, String descriptionFr, String descriptionEn, String descriptionDe, String descriptionIt, String descriptionEs
});




}
/// @nodoc
class _$StageCopyWithImpl<$Res>
    implements $StageCopyWith<$Res> {
  _$StageCopyWithImpl(this._self, this._then);

  final Stage _self;
  final $Res Function(Stage) _then;

/// Create a copy of Stage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nameFr = null,Object? nameEn = null,Object? nameDe = null,Object? nameIt = null,Object? nameEs = null,Object? distance = null,Object? elevationGain = null,Object? elevationLoss = null,Object? estimatedDurationSeconds = null,Object? difficulty = null,Object? orderIndex = null,Object? startLat = null,Object? startLng = null,Object? endLat = null,Object? endLng = null,Object? descriptionFr = null,Object? descriptionEn = null,Object? descriptionDe = null,Object? descriptionIt = null,Object? descriptionEs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameFr: null == nameFr ? _self.nameFr : nameFr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameDe: null == nameDe ? _self.nameDe : nameDe // ignore: cast_nullable_to_non_nullable
as String,nameIt: null == nameIt ? _self.nameIt : nameIt // ignore: cast_nullable_to_non_nullable
as String,nameEs: null == nameEs ? _self.nameEs : nameEs // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,elevationGain: null == elevationGain ? _self.elevationGain : elevationGain // ignore: cast_nullable_to_non_nullable
as int,elevationLoss: null == elevationLoss ? _self.elevationLoss : elevationLoss // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,startLat: null == startLat ? _self.startLat : startLat // ignore: cast_nullable_to_non_nullable
as double,startLng: null == startLng ? _self.startLng : startLng // ignore: cast_nullable_to_non_nullable
as double,endLat: null == endLat ? _self.endLat : endLat // ignore: cast_nullable_to_non_nullable
as double,endLng: null == endLng ? _self.endLng : endLng // ignore: cast_nullable_to_non_nullable
as double,descriptionFr: null == descriptionFr ? _self.descriptionFr : descriptionFr // ignore: cast_nullable_to_non_nullable
as String,descriptionEn: null == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String,descriptionDe: null == descriptionDe ? _self.descriptionDe : descriptionDe // ignore: cast_nullable_to_non_nullable
as String,descriptionIt: null == descriptionIt ? _self.descriptionIt : descriptionIt // ignore: cast_nullable_to_non_nullable
as String,descriptionEs: null == descriptionEs ? _self.descriptionEs : descriptionEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Stage].
extension StagePatterns on Stage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Stage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Stage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Stage value)  $default,){
final _that = this;
switch (_that) {
case _Stage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Stage value)?  $default,){
final _that = this;
switch (_that) {
case _Stage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nameFr,  String nameEn,  String nameDe,  String nameIt,  String nameEs,  double distance,  int elevationGain,  int elevationLoss,  int estimatedDurationSeconds,  String difficulty,  int orderIndex,  double startLat,  double startLng,  double endLat,  double endLng,  String descriptionFr,  String descriptionEn,  String descriptionDe,  String descriptionIt,  String descriptionEs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Stage() when $default != null:
return $default(_that.id,_that.nameFr,_that.nameEn,_that.nameDe,_that.nameIt,_that.nameEs,_that.distance,_that.elevationGain,_that.elevationLoss,_that.estimatedDurationSeconds,_that.difficulty,_that.orderIndex,_that.startLat,_that.startLng,_that.endLat,_that.endLng,_that.descriptionFr,_that.descriptionEn,_that.descriptionDe,_that.descriptionIt,_that.descriptionEs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nameFr,  String nameEn,  String nameDe,  String nameIt,  String nameEs,  double distance,  int elevationGain,  int elevationLoss,  int estimatedDurationSeconds,  String difficulty,  int orderIndex,  double startLat,  double startLng,  double endLat,  double endLng,  String descriptionFr,  String descriptionEn,  String descriptionDe,  String descriptionIt,  String descriptionEs)  $default,) {final _that = this;
switch (_that) {
case _Stage():
return $default(_that.id,_that.nameFr,_that.nameEn,_that.nameDe,_that.nameIt,_that.nameEs,_that.distance,_that.elevationGain,_that.elevationLoss,_that.estimatedDurationSeconds,_that.difficulty,_that.orderIndex,_that.startLat,_that.startLng,_that.endLat,_that.endLng,_that.descriptionFr,_that.descriptionEn,_that.descriptionDe,_that.descriptionIt,_that.descriptionEs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nameFr,  String nameEn,  String nameDe,  String nameIt,  String nameEs,  double distance,  int elevationGain,  int elevationLoss,  int estimatedDurationSeconds,  String difficulty,  int orderIndex,  double startLat,  double startLng,  double endLat,  double endLng,  String descriptionFr,  String descriptionEn,  String descriptionDe,  String descriptionIt,  String descriptionEs)?  $default,) {final _that = this;
switch (_that) {
case _Stage() when $default != null:
return $default(_that.id,_that.nameFr,_that.nameEn,_that.nameDe,_that.nameIt,_that.nameEs,_that.distance,_that.elevationGain,_that.elevationLoss,_that.estimatedDurationSeconds,_that.difficulty,_that.orderIndex,_that.startLat,_that.startLng,_that.endLat,_that.endLng,_that.descriptionFr,_that.descriptionEn,_that.descriptionDe,_that.descriptionIt,_that.descriptionEs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Stage extends Stage {
  const _Stage({required this.id, required this.nameFr, this.nameEn = '', this.nameDe = '', this.nameIt = '', this.nameEs = '', required this.distance, required this.elevationGain, required this.elevationLoss, this.estimatedDurationSeconds = 0, this.difficulty = 'moderate', required this.orderIndex, required this.startLat, required this.startLng, required this.endLat, required this.endLng, this.descriptionFr = '', this.descriptionEn = '', this.descriptionDe = '', this.descriptionIt = '', this.descriptionEs = ''}): super._();
  factory _Stage.fromJson(Map<String, dynamic> json) => _$StageFromJson(json);

/// Identifiant unique de l'etape
@override final  String id;
/// Nom — francais
@override final  String nameFr;
/// Nom — anglais
@override@JsonKey() final  String nameEn;
/// Nom — allemand
@override@JsonKey() final  String nameDe;
/// Nom — italien
@override@JsonKey() final  String nameIt;
/// Nom — espagnol
@override@JsonKey() final  String nameEs;
/// Distance en kilometres
@override final  double distance;
/// Denivele positif en metres
@override final  int elevationGain;
/// Denivele negatif en metres
@override final  int elevationLoss;
/// Duree estimee en secondes (serialisable)
@override@JsonKey() final  int estimatedDurationSeconds;
/// Difficulte — String extensible (easy, moderate, hard, extreme, ...)
@override@JsonKey() final  String difficulty;
/// Ordre d'affichage (1-indexed)
@override final  int orderIndex;
/// Latitude du point de depart
@override final  double startLat;
/// Longitude du point de depart
@override final  double startLng;
/// Latitude du point d'arrivee
@override final  double endLat;
/// Longitude du point d'arrivee
@override final  double endLng;
/// Description — francais
@override@JsonKey() final  String descriptionFr;
/// Description — anglais
@override@JsonKey() final  String descriptionEn;
/// Description — allemand
@override@JsonKey() final  String descriptionDe;
/// Description — italien
@override@JsonKey() final  String descriptionIt;
/// Description — espagnol
@override@JsonKey() final  String descriptionEs;

/// Create a copy of Stage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageCopyWith<_Stage> get copyWith => __$StageCopyWithImpl<_Stage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Stage&&(identical(other.id, id) || other.id == id)&&(identical(other.nameFr, nameFr) || other.nameFr == nameFr)&&(identical(other.nameEn, nameEn) || other.nameEn == nameEn)&&(identical(other.nameDe, nameDe) || other.nameDe == nameDe)&&(identical(other.nameIt, nameIt) || other.nameIt == nameIt)&&(identical(other.nameEs, nameEs) || other.nameEs == nameEs)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.elevationGain, elevationGain) || other.elevationGain == elevationGain)&&(identical(other.elevationLoss, elevationLoss) || other.elevationLoss == elevationLoss)&&(identical(other.estimatedDurationSeconds, estimatedDurationSeconds) || other.estimatedDurationSeconds == estimatedDurationSeconds)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.orderIndex, orderIndex) || other.orderIndex == orderIndex)&&(identical(other.startLat, startLat) || other.startLat == startLat)&&(identical(other.startLng, startLng) || other.startLng == startLng)&&(identical(other.endLat, endLat) || other.endLat == endLat)&&(identical(other.endLng, endLng) || other.endLng == endLng)&&(identical(other.descriptionFr, descriptionFr) || other.descriptionFr == descriptionFr)&&(identical(other.descriptionEn, descriptionEn) || other.descriptionEn == descriptionEn)&&(identical(other.descriptionDe, descriptionDe) || other.descriptionDe == descriptionDe)&&(identical(other.descriptionIt, descriptionIt) || other.descriptionIt == descriptionIt)&&(identical(other.descriptionEs, descriptionEs) || other.descriptionEs == descriptionEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,nameFr,nameEn,nameDe,nameIt,nameEs,distance,elevationGain,elevationLoss,estimatedDurationSeconds,difficulty,orderIndex,startLat,startLng,endLat,endLng,descriptionFr,descriptionEn,descriptionDe,descriptionIt,descriptionEs]);

@override
String toString() {
  return 'Stage(id: $id, nameFr: $nameFr, nameEn: $nameEn, nameDe: $nameDe, nameIt: $nameIt, nameEs: $nameEs, distance: $distance, elevationGain: $elevationGain, elevationLoss: $elevationLoss, estimatedDurationSeconds: $estimatedDurationSeconds, difficulty: $difficulty, orderIndex: $orderIndex, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, descriptionFr: $descriptionFr, descriptionEn: $descriptionEn, descriptionDe: $descriptionDe, descriptionIt: $descriptionIt, descriptionEs: $descriptionEs)';
}


}

/// @nodoc
abstract mixin class _$StageCopyWith<$Res> implements $StageCopyWith<$Res> {
  factory _$StageCopyWith(_Stage value, $Res Function(_Stage) _then) = __$StageCopyWithImpl;
@override @useResult
$Res call({
 String id, String nameFr, String nameEn, String nameDe, String nameIt, String nameEs, double distance, int elevationGain, int elevationLoss, int estimatedDurationSeconds, String difficulty, int orderIndex, double startLat, double startLng, double endLat, double endLng, String descriptionFr, String descriptionEn, String descriptionDe, String descriptionIt, String descriptionEs
});




}
/// @nodoc
class __$StageCopyWithImpl<$Res>
    implements _$StageCopyWith<$Res> {
  __$StageCopyWithImpl(this._self, this._then);

  final _Stage _self;
  final $Res Function(_Stage) _then;

/// Create a copy of Stage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nameFr = null,Object? nameEn = null,Object? nameDe = null,Object? nameIt = null,Object? nameEs = null,Object? distance = null,Object? elevationGain = null,Object? elevationLoss = null,Object? estimatedDurationSeconds = null,Object? difficulty = null,Object? orderIndex = null,Object? startLat = null,Object? startLng = null,Object? endLat = null,Object? endLng = null,Object? descriptionFr = null,Object? descriptionEn = null,Object? descriptionDe = null,Object? descriptionIt = null,Object? descriptionEs = null,}) {
  return _then(_Stage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nameFr: null == nameFr ? _self.nameFr : nameFr // ignore: cast_nullable_to_non_nullable
as String,nameEn: null == nameEn ? _self.nameEn : nameEn // ignore: cast_nullable_to_non_nullable
as String,nameDe: null == nameDe ? _self.nameDe : nameDe // ignore: cast_nullable_to_non_nullable
as String,nameIt: null == nameIt ? _self.nameIt : nameIt // ignore: cast_nullable_to_non_nullable
as String,nameEs: null == nameEs ? _self.nameEs : nameEs // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as double,elevationGain: null == elevationGain ? _self.elevationGain : elevationGain // ignore: cast_nullable_to_non_nullable
as int,elevationLoss: null == elevationLoss ? _self.elevationLoss : elevationLoss // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationSeconds: null == estimatedDurationSeconds ? _self.estimatedDurationSeconds : estimatedDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as String,orderIndex: null == orderIndex ? _self.orderIndex : orderIndex // ignore: cast_nullable_to_non_nullable
as int,startLat: null == startLat ? _self.startLat : startLat // ignore: cast_nullable_to_non_nullable
as double,startLng: null == startLng ? _self.startLng : startLng // ignore: cast_nullable_to_non_nullable
as double,endLat: null == endLat ? _self.endLat : endLat // ignore: cast_nullable_to_non_nullable
as double,endLng: null == endLng ? _self.endLng : endLng // ignore: cast_nullable_to_non_nullable
as double,descriptionFr: null == descriptionFr ? _self.descriptionFr : descriptionFr // ignore: cast_nullable_to_non_nullable
as String,descriptionEn: null == descriptionEn ? _self.descriptionEn : descriptionEn // ignore: cast_nullable_to_non_nullable
as String,descriptionDe: null == descriptionDe ? _self.descriptionDe : descriptionDe // ignore: cast_nullable_to_non_nullable
as String,descriptionIt: null == descriptionIt ? _self.descriptionIt : descriptionIt // ignore: cast_nullable_to_non_nullable
as String,descriptionEs: null == descriptionEs ? _self.descriptionEs : descriptionEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
