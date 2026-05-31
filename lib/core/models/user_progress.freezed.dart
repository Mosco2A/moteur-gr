// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserProgressModel {

/// Cle primaire DB (0 si pas encore insere)
 int get id;/// Identifiant du sentier
 String get trailId;/// Etape courante (1-indexed)
 int get currentStage;/// Distance totale parcourue en km
 double get totalDistanceWalkedKm;/// Denivele positif total cumule en metres
 int get totalElevationGainedM;/// Temps total de marche en minutes
 int get totalTimeMinutes;/// Sentier complete ou non
 bool get isCompleted;/// Date de debut du sentier
 DateTime? get startedAt;/// Date de fin du sentier
 DateTime? get completedAt;
/// Create a copy of UserProgressModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserProgressModelCopyWith<UserProgressModel> get copyWith => _$UserProgressModelCopyWithImpl<UserProgressModel>(this as UserProgressModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserProgressModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&(identical(other.totalDistanceWalkedKm, totalDistanceWalkedKm) || other.totalDistanceWalkedKm == totalDistanceWalkedKm)&&(identical(other.totalElevationGainedM, totalElevationGainedM) || other.totalElevationGainedM == totalElevationGainedM)&&(identical(other.totalTimeMinutes, totalTimeMinutes) || other.totalTimeMinutes == totalTimeMinutes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,trailId,currentStage,totalDistanceWalkedKm,totalElevationGainedM,totalTimeMinutes,isCompleted,startedAt,completedAt);

@override
String toString() {
  return 'UserProgressModel(id: $id, trailId: $trailId, currentStage: $currentStage, totalDistanceWalkedKm: $totalDistanceWalkedKm, totalElevationGainedM: $totalElevationGainedM, totalTimeMinutes: $totalTimeMinutes, isCompleted: $isCompleted, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class $UserProgressModelCopyWith<$Res>  {
  factory $UserProgressModelCopyWith(UserProgressModel value, $Res Function(UserProgressModel) _then) = _$UserProgressModelCopyWithImpl;
@useResult
$Res call({
 int id, String trailId, int currentStage, double totalDistanceWalkedKm, int totalElevationGainedM, int totalTimeMinutes, bool isCompleted, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class _$UserProgressModelCopyWithImpl<$Res>
    implements $UserProgressModelCopyWith<$Res> {
  _$UserProgressModelCopyWithImpl(this._self, this._then);

  final UserProgressModel _self;
  final $Res Function(UserProgressModel) _then;

/// Create a copy of UserProgressModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trailId = null,Object? currentStage = null,Object? totalDistanceWalkedKm = null,Object? totalElevationGainedM = null,Object? totalTimeMinutes = null,Object? isCompleted = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,currentStage: null == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as int,totalDistanceWalkedKm: null == totalDistanceWalkedKm ? _self.totalDistanceWalkedKm : totalDistanceWalkedKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGainedM: null == totalElevationGainedM ? _self.totalElevationGainedM : totalElevationGainedM // ignore: cast_nullable_to_non_nullable
as int,totalTimeMinutes: null == totalTimeMinutes ? _self.totalTimeMinutes : totalTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [UserProgressModel].
extension UserProgressModelPatterns on UserProgressModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserProgressModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserProgressModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserProgressModel value)  $default,){
final _that = this;
switch (_that) {
case _UserProgressModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserProgressModel value)?  $default,){
final _that = this;
switch (_that) {
case _UserProgressModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String trailId,  int currentStage,  double totalDistanceWalkedKm,  int totalElevationGainedM,  int totalTimeMinutes,  bool isCompleted,  DateTime? startedAt,  DateTime? completedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserProgressModel() when $default != null:
return $default(_that.id,_that.trailId,_that.currentStage,_that.totalDistanceWalkedKm,_that.totalElevationGainedM,_that.totalTimeMinutes,_that.isCompleted,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String trailId,  int currentStage,  double totalDistanceWalkedKm,  int totalElevationGainedM,  int totalTimeMinutes,  bool isCompleted,  DateTime? startedAt,  DateTime? completedAt)  $default,) {final _that = this;
switch (_that) {
case _UserProgressModel():
return $default(_that.id,_that.trailId,_that.currentStage,_that.totalDistanceWalkedKm,_that.totalElevationGainedM,_that.totalTimeMinutes,_that.isCompleted,_that.startedAt,_that.completedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String trailId,  int currentStage,  double totalDistanceWalkedKm,  int totalElevationGainedM,  int totalTimeMinutes,  bool isCompleted,  DateTime? startedAt,  DateTime? completedAt)?  $default,) {final _that = this;
switch (_that) {
case _UserProgressModel() when $default != null:
return $default(_that.id,_that.trailId,_that.currentStage,_that.totalDistanceWalkedKm,_that.totalElevationGainedM,_that.totalTimeMinutes,_that.isCompleted,_that.startedAt,_that.completedAt);case _:
  return null;

}
}

}

/// @nodoc


class _UserProgressModel extends UserProgressModel {
  const _UserProgressModel({this.id = 0, required this.trailId, this.currentStage = 1, this.totalDistanceWalkedKm = 0.0, this.totalElevationGainedM = 0, this.totalTimeMinutes = 0, this.isCompleted = false, this.startedAt, this.completedAt}): super._();
  

/// Cle primaire DB (0 si pas encore insere)
@override@JsonKey() final  int id;
/// Identifiant du sentier
@override final  String trailId;
/// Etape courante (1-indexed)
@override@JsonKey() final  int currentStage;
/// Distance totale parcourue en km
@override@JsonKey() final  double totalDistanceWalkedKm;
/// Denivele positif total cumule en metres
@override@JsonKey() final  int totalElevationGainedM;
/// Temps total de marche en minutes
@override@JsonKey() final  int totalTimeMinutes;
/// Sentier complete ou non
@override@JsonKey() final  bool isCompleted;
/// Date de debut du sentier
@override final  DateTime? startedAt;
/// Date de fin du sentier
@override final  DateTime? completedAt;

/// Create a copy of UserProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserProgressModelCopyWith<_UserProgressModel> get copyWith => __$UserProgressModelCopyWithImpl<_UserProgressModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserProgressModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.currentStage, currentStage) || other.currentStage == currentStage)&&(identical(other.totalDistanceWalkedKm, totalDistanceWalkedKm) || other.totalDistanceWalkedKm == totalDistanceWalkedKm)&&(identical(other.totalElevationGainedM, totalElevationGainedM) || other.totalElevationGainedM == totalElevationGainedM)&&(identical(other.totalTimeMinutes, totalTimeMinutes) || other.totalTimeMinutes == totalTimeMinutes)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,trailId,currentStage,totalDistanceWalkedKm,totalElevationGainedM,totalTimeMinutes,isCompleted,startedAt,completedAt);

@override
String toString() {
  return 'UserProgressModel(id: $id, trailId: $trailId, currentStage: $currentStage, totalDistanceWalkedKm: $totalDistanceWalkedKm, totalElevationGainedM: $totalElevationGainedM, totalTimeMinutes: $totalTimeMinutes, isCompleted: $isCompleted, startedAt: $startedAt, completedAt: $completedAt)';
}


}

/// @nodoc
abstract mixin class _$UserProgressModelCopyWith<$Res> implements $UserProgressModelCopyWith<$Res> {
  factory _$UserProgressModelCopyWith(_UserProgressModel value, $Res Function(_UserProgressModel) _then) = __$UserProgressModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String trailId, int currentStage, double totalDistanceWalkedKm, int totalElevationGainedM, int totalTimeMinutes, bool isCompleted, DateTime? startedAt, DateTime? completedAt
});




}
/// @nodoc
class __$UserProgressModelCopyWithImpl<$Res>
    implements _$UserProgressModelCopyWith<$Res> {
  __$UserProgressModelCopyWithImpl(this._self, this._then);

  final _UserProgressModel _self;
  final $Res Function(_UserProgressModel) _then;

/// Create a copy of UserProgressModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trailId = null,Object? currentStage = null,Object? totalDistanceWalkedKm = null,Object? totalElevationGainedM = null,Object? totalTimeMinutes = null,Object? isCompleted = null,Object? startedAt = freezed,Object? completedAt = freezed,}) {
  return _then(_UserProgressModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,currentStage: null == currentStage ? _self.currentStage : currentStage // ignore: cast_nullable_to_non_nullable
as int,totalDistanceWalkedKm: null == totalDistanceWalkedKm ? _self.totalDistanceWalkedKm : totalDistanceWalkedKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGainedM: null == totalElevationGainedM ? _self.totalElevationGainedM : totalElevationGainedM // ignore: cast_nullable_to_non_nullable
as int,totalTimeMinutes: null == totalTimeMinutes ? _self.totalTimeMinutes : totalTimeMinutes // ignore: cast_nullable_to_non_nullable
as int,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
