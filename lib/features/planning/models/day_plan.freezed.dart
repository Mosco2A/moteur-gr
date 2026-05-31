// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayPlan {

/// Numéro du jour (1-indexed)
 int get dayNumber;/// Liste des étapes prévues ce jour
 List<StageModel> get stages;/// Distance totale en km pour ce jour
 double get totalDistanceKm;/// Dénivelé positif total en mètres pour ce jour
 int get totalElevationGainM;/// Durée estimée en heures (distance/4 + D+/400)
 double get estimatedDurationHours;/// True si c'est un jour de repos (aucune étape)
 bool get isRestDay;
/// Create a copy of DayPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayPlanCopyWith<DayPlan> get copyWith => _$DayPlanCopyWithImpl<DayPlan>(this as DayPlan, _$identity);

  /// Serializes this DayPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayPlan&&(identical(other.dayNumber, dayNumber) || other.dayNumber == dayNumber)&&const DeepCollectionEquality().equals(other.stages, stages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGainM, totalElevationGainM) || other.totalElevationGainM == totalElevationGainM)&&(identical(other.estimatedDurationHours, estimatedDurationHours) || other.estimatedDurationHours == estimatedDurationHours)&&(identical(other.isRestDay, isRestDay) || other.isRestDay == isRestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayNumber,const DeepCollectionEquality().hash(stages),totalDistanceKm,totalElevationGainM,estimatedDurationHours,isRestDay);

@override
String toString() {
  return 'DayPlan(dayNumber: $dayNumber, stages: $stages, totalDistanceKm: $totalDistanceKm, totalElevationGainM: $totalElevationGainM, estimatedDurationHours: $estimatedDurationHours, isRestDay: $isRestDay)';
}


}

/// @nodoc
abstract mixin class $DayPlanCopyWith<$Res>  {
  factory $DayPlanCopyWith(DayPlan value, $Res Function(DayPlan) _then) = _$DayPlanCopyWithImpl;
@useResult
$Res call({
 int dayNumber, List<StageModel> stages, double totalDistanceKm, int totalElevationGainM, double estimatedDurationHours, bool isRestDay
});




}
/// @nodoc
class _$DayPlanCopyWithImpl<$Res>
    implements $DayPlanCopyWith<$Res> {
  _$DayPlanCopyWithImpl(this._self, this._then);

  final DayPlan _self;
  final $Res Function(DayPlan) _then;

/// Create a copy of DayPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? dayNumber = null,Object? stages = null,Object? totalDistanceKm = null,Object? totalElevationGainM = null,Object? estimatedDurationHours = null,Object? isRestDay = null,}) {
  return _then(_self.copyWith(
dayNumber: null == dayNumber ? _self.dayNumber : dayNumber // ignore: cast_nullable_to_non_nullable
as int,stages: null == stages ? _self.stages : stages // ignore: cast_nullable_to_non_nullable
as List<StageModel>,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGainM: null == totalElevationGainM ? _self.totalElevationGainM : totalElevationGainM // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationHours: null == estimatedDurationHours ? _self.estimatedDurationHours : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
as double,isRestDay: null == isRestDay ? _self.isRestDay : isRestDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DayPlan].
extension DayPlanPatterns on DayPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayPlan value)  $default,){
final _that = this;
switch (_that) {
case _DayPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayPlan value)?  $default,){
final _that = this;
switch (_that) {
case _DayPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int dayNumber,  List<StageModel> stages,  double totalDistanceKm,  int totalElevationGainM,  double estimatedDurationHours,  bool isRestDay)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayPlan() when $default != null:
return $default(_that.dayNumber,_that.stages,_that.totalDistanceKm,_that.totalElevationGainM,_that.estimatedDurationHours,_that.isRestDay);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int dayNumber,  List<StageModel> stages,  double totalDistanceKm,  int totalElevationGainM,  double estimatedDurationHours,  bool isRestDay)  $default,) {final _that = this;
switch (_that) {
case _DayPlan():
return $default(_that.dayNumber,_that.stages,_that.totalDistanceKm,_that.totalElevationGainM,_that.estimatedDurationHours,_that.isRestDay);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int dayNumber,  List<StageModel> stages,  double totalDistanceKm,  int totalElevationGainM,  double estimatedDurationHours,  bool isRestDay)?  $default,) {final _that = this;
switch (_that) {
case _DayPlan() when $default != null:
return $default(_that.dayNumber,_that.stages,_that.totalDistanceKm,_that.totalElevationGainM,_that.estimatedDurationHours,_that.isRestDay);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayPlan extends DayPlan {
  const _DayPlan({required this.dayNumber, required final  List<StageModel> stages, required this.totalDistanceKm, required this.totalElevationGainM, required this.estimatedDurationHours, required this.isRestDay}): _stages = stages,super._();
  factory _DayPlan.fromJson(Map<String, dynamic> json) => _$DayPlanFromJson(json);

/// Numéro du jour (1-indexed)
@override final  int dayNumber;
/// Liste des étapes prévues ce jour
 final  List<StageModel> _stages;
/// Liste des étapes prévues ce jour
@override List<StageModel> get stages {
  if (_stages is EqualUnmodifiableListView) return _stages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stages);
}

/// Distance totale en km pour ce jour
@override final  double totalDistanceKm;
/// Dénivelé positif total en mètres pour ce jour
@override final  int totalElevationGainM;
/// Durée estimée en heures (distance/4 + D+/400)
@override final  double estimatedDurationHours;
/// True si c'est un jour de repos (aucune étape)
@override final  bool isRestDay;

/// Create a copy of DayPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayPlanCopyWith<_DayPlan> get copyWith => __$DayPlanCopyWithImpl<_DayPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayPlan&&(identical(other.dayNumber, dayNumber) || other.dayNumber == dayNumber)&&const DeepCollectionEquality().equals(other._stages, _stages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGainM, totalElevationGainM) || other.totalElevationGainM == totalElevationGainM)&&(identical(other.estimatedDurationHours, estimatedDurationHours) || other.estimatedDurationHours == estimatedDurationHours)&&(identical(other.isRestDay, isRestDay) || other.isRestDay == isRestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,dayNumber,const DeepCollectionEquality().hash(_stages),totalDistanceKm,totalElevationGainM,estimatedDurationHours,isRestDay);

@override
String toString() {
  return 'DayPlan(dayNumber: $dayNumber, stages: $stages, totalDistanceKm: $totalDistanceKm, totalElevationGainM: $totalElevationGainM, estimatedDurationHours: $estimatedDurationHours, isRestDay: $isRestDay)';
}


}

/// @nodoc
abstract mixin class _$DayPlanCopyWith<$Res> implements $DayPlanCopyWith<$Res> {
  factory _$DayPlanCopyWith(_DayPlan value, $Res Function(_DayPlan) _then) = __$DayPlanCopyWithImpl;
@override @useResult
$Res call({
 int dayNumber, List<StageModel> stages, double totalDistanceKm, int totalElevationGainM, double estimatedDurationHours, bool isRestDay
});




}
/// @nodoc
class __$DayPlanCopyWithImpl<$Res>
    implements _$DayPlanCopyWith<$Res> {
  __$DayPlanCopyWithImpl(this._self, this._then);

  final _DayPlan _self;
  final $Res Function(_DayPlan) _then;

/// Create a copy of DayPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? dayNumber = null,Object? stages = null,Object? totalDistanceKm = null,Object? totalElevationGainM = null,Object? estimatedDurationHours = null,Object? isRestDay = null,}) {
  return _then(_DayPlan(
dayNumber: null == dayNumber ? _self.dayNumber : dayNumber // ignore: cast_nullable_to_non_nullable
as int,stages: null == stages ? _self._stages : stages // ignore: cast_nullable_to_non_nullable
as List<StageModel>,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGainM: null == totalElevationGainM ? _self.totalElevationGainM : totalElevationGainM // ignore: cast_nullable_to_non_nullable
as int,estimatedDurationHours: null == estimatedDurationHours ? _self.estimatedDurationHours : estimatedDurationHours // ignore: cast_nullable_to_non_nullable
as double,isRestDay: null == isRestDay ? _self.isRestDay : isRestDay // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
