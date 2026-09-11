// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'past_hike.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PastHike {

/// Cle DB (0 si pas encore inseree).
 int get id;/// Date de la rando (recence).
 DateTime get date;/// Nombre de jours.
 int get days;/// Temps moyen de marche PAR JOUR, en heures.
 double get avgWalkHoursPerDay;/// Denivele positif TOTAL, en metres.
 int get totalElevationGain;/// Distance TOTALE, en km.
 double get totalDistanceKm;
/// Create a copy of PastHike
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PastHikeCopyWith<PastHike> get copyWith => _$PastHikeCopyWithImpl<PastHike>(this as PastHike, _$identity);

  /// Serializes this PastHike to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PastHike&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.days, days) || other.days == days)&&(identical(other.avgWalkHoursPerDay, avgWalkHoursPerDay) || other.avgWalkHoursPerDay == avgWalkHoursPerDay)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,days,avgWalkHoursPerDay,totalElevationGain,totalDistanceKm);

@override
String toString() {
  return 'PastHike(id: $id, date: $date, days: $days, avgWalkHoursPerDay: $avgWalkHoursPerDay, totalElevationGain: $totalElevationGain, totalDistanceKm: $totalDistanceKm)';
}


}

/// @nodoc
abstract mixin class $PastHikeCopyWith<$Res>  {
  factory $PastHikeCopyWith(PastHike value, $Res Function(PastHike) _then) = _$PastHikeCopyWithImpl;
@useResult
$Res call({
 int id, DateTime date, int days, double avgWalkHoursPerDay, int totalElevationGain, double totalDistanceKm
});




}
/// @nodoc
class _$PastHikeCopyWithImpl<$Res>
    implements $PastHikeCopyWith<$Res> {
  _$PastHikeCopyWithImpl(this._self, this._then);

  final PastHike _self;
  final $Res Function(PastHike) _then;

/// Create a copy of PastHike
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? days = null,Object? avgWalkHoursPerDay = null,Object? totalElevationGain = null,Object? totalDistanceKm = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,avgWalkHoursPerDay: null == avgWalkHoursPerDay ? _self.avgWalkHoursPerDay : avgWalkHoursPerDay // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PastHike].
extension PastHikePatterns on PastHike {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PastHike value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PastHike() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PastHike value)  $default,){
final _that = this;
switch (_that) {
case _PastHike():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PastHike value)?  $default,){
final _that = this;
switch (_that) {
case _PastHike() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  DateTime date,  int days,  double avgWalkHoursPerDay,  int totalElevationGain,  double totalDistanceKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PastHike() when $default != null:
return $default(_that.id,_that.date,_that.days,_that.avgWalkHoursPerDay,_that.totalElevationGain,_that.totalDistanceKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  DateTime date,  int days,  double avgWalkHoursPerDay,  int totalElevationGain,  double totalDistanceKm)  $default,) {final _that = this;
switch (_that) {
case _PastHike():
return $default(_that.id,_that.date,_that.days,_that.avgWalkHoursPerDay,_that.totalElevationGain,_that.totalDistanceKm);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  DateTime date,  int days,  double avgWalkHoursPerDay,  int totalElevationGain,  double totalDistanceKm)?  $default,) {final _that = this;
switch (_that) {
case _PastHike() when $default != null:
return $default(_that.id,_that.date,_that.days,_that.avgWalkHoursPerDay,_that.totalElevationGain,_that.totalDistanceKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PastHike extends PastHike {
  const _PastHike({this.id = 0, required this.date, this.days = 1, this.avgWalkHoursPerDay = 0, this.totalElevationGain = 0, this.totalDistanceKm = 0}): super._();
  factory _PastHike.fromJson(Map<String, dynamic> json) => _$PastHikeFromJson(json);

/// Cle DB (0 si pas encore inseree).
@override@JsonKey() final  int id;
/// Date de la rando (recence).
@override final  DateTime date;
/// Nombre de jours.
@override@JsonKey() final  int days;
/// Temps moyen de marche PAR JOUR, en heures.
@override@JsonKey() final  double avgWalkHoursPerDay;
/// Denivele positif TOTAL, en metres.
@override@JsonKey() final  int totalElevationGain;
/// Distance TOTALE, en km.
@override@JsonKey() final  double totalDistanceKm;

/// Create a copy of PastHike
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PastHikeCopyWith<_PastHike> get copyWith => __$PastHikeCopyWithImpl<_PastHike>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PastHikeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PastHike&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.days, days) || other.days == days)&&(identical(other.avgWalkHoursPerDay, avgWalkHoursPerDay) || other.avgWalkHoursPerDay == avgWalkHoursPerDay)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,days,avgWalkHoursPerDay,totalElevationGain,totalDistanceKm);

@override
String toString() {
  return 'PastHike(id: $id, date: $date, days: $days, avgWalkHoursPerDay: $avgWalkHoursPerDay, totalElevationGain: $totalElevationGain, totalDistanceKm: $totalDistanceKm)';
}


}

/// @nodoc
abstract mixin class _$PastHikeCopyWith<$Res> implements $PastHikeCopyWith<$Res> {
  factory _$PastHikeCopyWith(_PastHike value, $Res Function(_PastHike) _then) = __$PastHikeCopyWithImpl;
@override @useResult
$Res call({
 int id, DateTime date, int days, double avgWalkHoursPerDay, int totalElevationGain, double totalDistanceKm
});




}
/// @nodoc
class __$PastHikeCopyWithImpl<$Res>
    implements _$PastHikeCopyWith<$Res> {
  __$PastHikeCopyWithImpl(this._self, this._then);

  final _PastHike _self;
  final $Res Function(_PastHike) _then;

/// Create a copy of PastHike
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? days = null,Object? avgWalkHoursPerDay = null,Object? totalElevationGain = null,Object? totalDistanceKm = null,}) {
  return _then(_PastHike(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as int,avgWalkHoursPerDay: null == avgWalkHoursPerDay ? _self.avgWalkHoursPerDay : avgWalkHoursPerDay // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
