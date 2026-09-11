// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingPlan {

/// Identifiant du sentier cible (`mare-a-mare-centre`, ...) ou `default`.
 String get trailId;/// Duree totale du plan en semaines (CHAMP DE DONNEES, reglable 6/8/12).
 int get durationWeeks;/// Phases progressives (Fondation / Denivele / Endurance), ordonnees.
 List<TrainingPhase> get phases;/// Objectif chiffre a atteindre avant le depart (encart orange).
 TrainingObjective? get objective;
/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingPlanCopyWith<TrainingPlan> get copyWith => _$TrainingPlanCopyWithImpl<TrainingPlan>(this as TrainingPlan, _$identity);

  /// Serializes this TrainingPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingPlan&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&const DeepCollectionEquality().equals(other.phases, phases)&&(identical(other.objective, objective) || other.objective == objective));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,durationWeeks,const DeepCollectionEquality().hash(phases),objective);

@override
String toString() {
  return 'TrainingPlan(trailId: $trailId, durationWeeks: $durationWeeks, phases: $phases, objective: $objective)';
}


}

/// @nodoc
abstract mixin class $TrainingPlanCopyWith<$Res>  {
  factory $TrainingPlanCopyWith(TrainingPlan value, $Res Function(TrainingPlan) _then) = _$TrainingPlanCopyWithImpl;
@useResult
$Res call({
 String trailId, int durationWeeks, List<TrainingPhase> phases, TrainingObjective? objective
});


$TrainingObjectiveCopyWith<$Res>? get objective;

}
/// @nodoc
class _$TrainingPlanCopyWithImpl<$Res>
    implements $TrainingPlanCopyWith<$Res> {
  _$TrainingPlanCopyWithImpl(this._self, this._then);

  final TrainingPlan _self;
  final $Res Function(TrainingPlan) _then;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trailId = null,Object? durationWeeks = null,Object? phases = null,Object? objective = freezed,}) {
  return _then(_self.copyWith(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: null == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int,phases: null == phases ? _self.phases : phases // ignore: cast_nullable_to_non_nullable
as List<TrainingPhase>,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as TrainingObjective?,
  ));
}
/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingObjectiveCopyWith<$Res>? get objective {
    if (_self.objective == null) {
    return null;
  }

  return $TrainingObjectiveCopyWith<$Res>(_self.objective!, (value) {
    return _then(_self.copyWith(objective: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrainingPlan].
extension TrainingPlanPatterns on TrainingPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingPlan value)  $default,){
final _that = this;
switch (_that) {
case _TrainingPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingPlan value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trailId,  int durationWeeks,  List<TrainingPhase> phases,  TrainingObjective? objective)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
return $default(_that.trailId,_that.durationWeeks,_that.phases,_that.objective);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trailId,  int durationWeeks,  List<TrainingPhase> phases,  TrainingObjective? objective)  $default,) {final _that = this;
switch (_that) {
case _TrainingPlan():
return $default(_that.trailId,_that.durationWeeks,_that.phases,_that.objective);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trailId,  int durationWeeks,  List<TrainingPhase> phases,  TrainingObjective? objective)?  $default,) {final _that = this;
switch (_that) {
case _TrainingPlan() when $default != null:
return $default(_that.trailId,_that.durationWeeks,_that.phases,_that.objective);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingPlan extends TrainingPlan {
  const _TrainingPlan({required this.trailId, this.durationWeeks = 8, final  List<TrainingPhase> phases = const <TrainingPhase>[], this.objective}): _phases = phases,super._();
  factory _TrainingPlan.fromJson(Map<String, dynamic> json) => _$TrainingPlanFromJson(json);

/// Identifiant du sentier cible (`mare-a-mare-centre`, ...) ou `default`.
@override final  String trailId;
/// Duree totale du plan en semaines (CHAMP DE DONNEES, reglable 6/8/12).
@override@JsonKey() final  int durationWeeks;
/// Phases progressives (Fondation / Denivele / Endurance), ordonnees.
 final  List<TrainingPhase> _phases;
/// Phases progressives (Fondation / Denivele / Endurance), ordonnees.
@override@JsonKey() List<TrainingPhase> get phases {
  if (_phases is EqualUnmodifiableListView) return _phases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_phases);
}

/// Objectif chiffre a atteindre avant le depart (encart orange).
@override final  TrainingObjective? objective;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingPlanCopyWith<_TrainingPlan> get copyWith => __$TrainingPlanCopyWithImpl<_TrainingPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingPlan&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.durationWeeks, durationWeeks) || other.durationWeeks == durationWeeks)&&const DeepCollectionEquality().equals(other._phases, _phases)&&(identical(other.objective, objective) || other.objective == objective));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,durationWeeks,const DeepCollectionEquality().hash(_phases),objective);

@override
String toString() {
  return 'TrainingPlan(trailId: $trailId, durationWeeks: $durationWeeks, phases: $phases, objective: $objective)';
}


}

/// @nodoc
abstract mixin class _$TrainingPlanCopyWith<$Res> implements $TrainingPlanCopyWith<$Res> {
  factory _$TrainingPlanCopyWith(_TrainingPlan value, $Res Function(_TrainingPlan) _then) = __$TrainingPlanCopyWithImpl;
@override @useResult
$Res call({
 String trailId, int durationWeeks, List<TrainingPhase> phases, TrainingObjective? objective
});


@override $TrainingObjectiveCopyWith<$Res>? get objective;

}
/// @nodoc
class __$TrainingPlanCopyWithImpl<$Res>
    implements _$TrainingPlanCopyWith<$Res> {
  __$TrainingPlanCopyWithImpl(this._self, this._then);

  final _TrainingPlan _self;
  final $Res Function(_TrainingPlan) _then;

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trailId = null,Object? durationWeeks = null,Object? phases = null,Object? objective = freezed,}) {
  return _then(_TrainingPlan(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,durationWeeks: null == durationWeeks ? _self.durationWeeks : durationWeeks // ignore: cast_nullable_to_non_nullable
as int,phases: null == phases ? _self._phases : phases // ignore: cast_nullable_to_non_nullable
as List<TrainingPhase>,objective: freezed == objective ? _self.objective : objective // ignore: cast_nullable_to_non_nullable
as TrainingObjective?,
  ));
}

/// Create a copy of TrainingPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingObjectiveCopyWith<$Res>? get objective {
    if (_self.objective == null) {
    return null;
  }

  return $TrainingObjectiveCopyWith<$Res>(_self.objective!, (value) {
    return _then(_self.copyWith(objective: value));
  });
}
}


/// @nodoc
mixin _$TrainingPhase {

/// Identifiant stable de la phase (`foundation`, `elevation`, `endurance`).
 String get id;/// Premiere semaine de la phase (1-based, pour « Semaines X-Y »).
 int get weekStart;/// Derniere semaine de la phase (1-based).
 int get weekEnd;/// Nom de l'icone Material (resolu cote UI, jamais d'IconData en donnee).
 String get icon;/// Intitule de la phase — francais (base).
 String get titleFr; String get titleEn; String get titleDe; String get titleIt; String get titleEs;/// Accroche courte de la phase — francais (base).
 String get subtitleFr; String get subtitleEn; String get subtitleDe; String get subtitleIt; String get subtitleEs;/// Seances cochables de la phase.
 List<TrainingSession> get sessions;
/// Create a copy of TrainingPhase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingPhaseCopyWith<TrainingPhase> get copyWith => _$TrainingPhaseCopyWithImpl<TrainingPhase>(this as TrainingPhase, _$identity);

  /// Serializes this TrainingPhase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingPhase&&(identical(other.id, id) || other.id == id)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&(identical(other.subtitleFr, subtitleFr) || other.subtitleFr == subtitleFr)&&(identical(other.subtitleEn, subtitleEn) || other.subtitleEn == subtitleEn)&&(identical(other.subtitleDe, subtitleDe) || other.subtitleDe == subtitleDe)&&(identical(other.subtitleIt, subtitleIt) || other.subtitleIt == subtitleIt)&&(identical(other.subtitleEs, subtitleEs) || other.subtitleEs == subtitleEs)&&const DeepCollectionEquality().equals(other.sessions, sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekStart,weekEnd,icon,titleFr,titleEn,titleDe,titleIt,titleEs,subtitleFr,subtitleEn,subtitleDe,subtitleIt,subtitleEs,const DeepCollectionEquality().hash(sessions));

@override
String toString() {
  return 'TrainingPhase(id: $id, weekStart: $weekStart, weekEnd: $weekEnd, icon: $icon, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, subtitleFr: $subtitleFr, subtitleEn: $subtitleEn, subtitleDe: $subtitleDe, subtitleIt: $subtitleIt, subtitleEs: $subtitleEs, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $TrainingPhaseCopyWith<$Res>  {
  factory $TrainingPhaseCopyWith(TrainingPhase value, $Res Function(TrainingPhase) _then) = _$TrainingPhaseCopyWithImpl;
@useResult
$Res call({
 String id, int weekStart, int weekEnd, String icon, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, String subtitleFr, String subtitleEn, String subtitleDe, String subtitleIt, String subtitleEs, List<TrainingSession> sessions
});




}
/// @nodoc
class _$TrainingPhaseCopyWithImpl<$Res>
    implements $TrainingPhaseCopyWith<$Res> {
  _$TrainingPhaseCopyWithImpl(this._self, this._then);

  final TrainingPhase _self;
  final $Res Function(TrainingPhase) _then;

/// Create a copy of TrainingPhase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? weekStart = null,Object? weekEnd = null,Object? icon = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? subtitleFr = null,Object? subtitleEn = null,Object? subtitleDe = null,Object? subtitleIt = null,Object? subtitleEs = null,Object? sessions = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,subtitleFr: null == subtitleFr ? _self.subtitleFr : subtitleFr // ignore: cast_nullable_to_non_nullable
as String,subtitleEn: null == subtitleEn ? _self.subtitleEn : subtitleEn // ignore: cast_nullable_to_non_nullable
as String,subtitleDe: null == subtitleDe ? _self.subtitleDe : subtitleDe // ignore: cast_nullable_to_non_nullable
as String,subtitleIt: null == subtitleIt ? _self.subtitleIt : subtitleIt // ignore: cast_nullable_to_non_nullable
as String,subtitleEs: null == subtitleEs ? _self.subtitleEs : subtitleEs // ignore: cast_nullable_to_non_nullable
as String,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<TrainingSession>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingPhase].
extension TrainingPhasePatterns on TrainingPhase {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingPhase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingPhase() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingPhase value)  $default,){
final _that = this;
switch (_that) {
case _TrainingPhase():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingPhase value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingPhase() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int weekStart,  int weekEnd,  String icon,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String subtitleFr,  String subtitleEn,  String subtitleDe,  String subtitleIt,  String subtitleEs,  List<TrainingSession> sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingPhase() when $default != null:
return $default(_that.id,_that.weekStart,_that.weekEnd,_that.icon,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.subtitleFr,_that.subtitleEn,_that.subtitleDe,_that.subtitleIt,_that.subtitleEs,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int weekStart,  int weekEnd,  String icon,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String subtitleFr,  String subtitleEn,  String subtitleDe,  String subtitleIt,  String subtitleEs,  List<TrainingSession> sessions)  $default,) {final _that = this;
switch (_that) {
case _TrainingPhase():
return $default(_that.id,_that.weekStart,_that.weekEnd,_that.icon,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.subtitleFr,_that.subtitleEn,_that.subtitleDe,_that.subtitleIt,_that.subtitleEs,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int weekStart,  int weekEnd,  String icon,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String subtitleFr,  String subtitleEn,  String subtitleDe,  String subtitleIt,  String subtitleEs,  List<TrainingSession> sessions)?  $default,) {final _that = this;
switch (_that) {
case _TrainingPhase() when $default != null:
return $default(_that.id,_that.weekStart,_that.weekEnd,_that.icon,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.subtitleFr,_that.subtitleEn,_that.subtitleDe,_that.subtitleIt,_that.subtitleEs,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingPhase extends TrainingPhase {
  const _TrainingPhase({required this.id, required this.weekStart, required this.weekEnd, this.icon = 'directions_walk', required this.titleFr, this.titleEn = '', this.titleDe = '', this.titleIt = '', this.titleEs = '', this.subtitleFr = '', this.subtitleEn = '', this.subtitleDe = '', this.subtitleIt = '', this.subtitleEs = '', final  List<TrainingSession> sessions = const <TrainingSession>[]}): _sessions = sessions,super._();
  factory _TrainingPhase.fromJson(Map<String, dynamic> json) => _$TrainingPhaseFromJson(json);

/// Identifiant stable de la phase (`foundation`, `elevation`, `endurance`).
@override final  String id;
/// Premiere semaine de la phase (1-based, pour « Semaines X-Y »).
@override final  int weekStart;
/// Derniere semaine de la phase (1-based).
@override final  int weekEnd;
/// Nom de l'icone Material (resolu cote UI, jamais d'IconData en donnee).
@override@JsonKey() final  String icon;
/// Intitule de la phase — francais (base).
@override final  String titleFr;
@override@JsonKey() final  String titleEn;
@override@JsonKey() final  String titleDe;
@override@JsonKey() final  String titleIt;
@override@JsonKey() final  String titleEs;
/// Accroche courte de la phase — francais (base).
@override@JsonKey() final  String subtitleFr;
@override@JsonKey() final  String subtitleEn;
@override@JsonKey() final  String subtitleDe;
@override@JsonKey() final  String subtitleIt;
@override@JsonKey() final  String subtitleEs;
/// Seances cochables de la phase.
 final  List<TrainingSession> _sessions;
/// Seances cochables de la phase.
@override@JsonKey() List<TrainingSession> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}


/// Create a copy of TrainingPhase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingPhaseCopyWith<_TrainingPhase> get copyWith => __$TrainingPhaseCopyWithImpl<_TrainingPhase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingPhaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingPhase&&(identical(other.id, id) || other.id == id)&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&(identical(other.weekEnd, weekEnd) || other.weekEnd == weekEnd)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&(identical(other.subtitleFr, subtitleFr) || other.subtitleFr == subtitleFr)&&(identical(other.subtitleEn, subtitleEn) || other.subtitleEn == subtitleEn)&&(identical(other.subtitleDe, subtitleDe) || other.subtitleDe == subtitleDe)&&(identical(other.subtitleIt, subtitleIt) || other.subtitleIt == subtitleIt)&&(identical(other.subtitleEs, subtitleEs) || other.subtitleEs == subtitleEs)&&const DeepCollectionEquality().equals(other._sessions, _sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,weekStart,weekEnd,icon,titleFr,titleEn,titleDe,titleIt,titleEs,subtitleFr,subtitleEn,subtitleDe,subtitleIt,subtitleEs,const DeepCollectionEquality().hash(_sessions));

@override
String toString() {
  return 'TrainingPhase(id: $id, weekStart: $weekStart, weekEnd: $weekEnd, icon: $icon, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, subtitleFr: $subtitleFr, subtitleEn: $subtitleEn, subtitleDe: $subtitleDe, subtitleIt: $subtitleIt, subtitleEs: $subtitleEs, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$TrainingPhaseCopyWith<$Res> implements $TrainingPhaseCopyWith<$Res> {
  factory _$TrainingPhaseCopyWith(_TrainingPhase value, $Res Function(_TrainingPhase) _then) = __$TrainingPhaseCopyWithImpl;
@override @useResult
$Res call({
 String id, int weekStart, int weekEnd, String icon, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, String subtitleFr, String subtitleEn, String subtitleDe, String subtitleIt, String subtitleEs, List<TrainingSession> sessions
});




}
/// @nodoc
class __$TrainingPhaseCopyWithImpl<$Res>
    implements _$TrainingPhaseCopyWith<$Res> {
  __$TrainingPhaseCopyWithImpl(this._self, this._then);

  final _TrainingPhase _self;
  final $Res Function(_TrainingPhase) _then;

/// Create a copy of TrainingPhase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? weekStart = null,Object? weekEnd = null,Object? icon = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? subtitleFr = null,Object? subtitleEn = null,Object? subtitleDe = null,Object? subtitleIt = null,Object? subtitleEs = null,Object? sessions = null,}) {
  return _then(_TrainingPhase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,weekStart: null == weekStart ? _self.weekStart : weekStart // ignore: cast_nullable_to_non_nullable
as int,weekEnd: null == weekEnd ? _self.weekEnd : weekEnd // ignore: cast_nullable_to_non_nullable
as int,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,subtitleFr: null == subtitleFr ? _self.subtitleFr : subtitleFr // ignore: cast_nullable_to_non_nullable
as String,subtitleEn: null == subtitleEn ? _self.subtitleEn : subtitleEn // ignore: cast_nullable_to_non_nullable
as String,subtitleDe: null == subtitleDe ? _self.subtitleDe : subtitleDe // ignore: cast_nullable_to_non_nullable
as String,subtitleIt: null == subtitleIt ? _self.subtitleIt : subtitleIt // ignore: cast_nullable_to_non_nullable
as String,subtitleEs: null == subtitleEs ? _self.subtitleEs : subtitleEs // ignore: cast_nullable_to_non_nullable
as String,sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<TrainingSession>,
  ));
}


}


/// @nodoc
mixin _$TrainingSession {

/// Identifiant STABLE de la seance (cle de persistance du coche).
 String get id;/// Libelle de la seance — francais (base).
 String get labelFr; String get labelEn; String get labelDe; String get labelIt; String get labelEs;
/// Create a copy of TrainingSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingSessionCopyWith<TrainingSession> get copyWith => _$TrainingSessionCopyWithImpl<TrainingSession>(this as TrainingSession, _$identity);

  /// Serializes this TrainingSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingSession&&(identical(other.id, id) || other.id == id)&&(identical(other.labelFr, labelFr) || other.labelFr == labelFr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.labelDe, labelDe) || other.labelDe == labelDe)&&(identical(other.labelIt, labelIt) || other.labelIt == labelIt)&&(identical(other.labelEs, labelEs) || other.labelEs == labelEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,labelFr,labelEn,labelDe,labelIt,labelEs);

@override
String toString() {
  return 'TrainingSession(id: $id, labelFr: $labelFr, labelEn: $labelEn, labelDe: $labelDe, labelIt: $labelIt, labelEs: $labelEs)';
}


}

/// @nodoc
abstract mixin class $TrainingSessionCopyWith<$Res>  {
  factory $TrainingSessionCopyWith(TrainingSession value, $Res Function(TrainingSession) _then) = _$TrainingSessionCopyWithImpl;
@useResult
$Res call({
 String id, String labelFr, String labelEn, String labelDe, String labelIt, String labelEs
});




}
/// @nodoc
class _$TrainingSessionCopyWithImpl<$Res>
    implements $TrainingSessionCopyWith<$Res> {
  _$TrainingSessionCopyWithImpl(this._self, this._then);

  final TrainingSession _self;
  final $Res Function(TrainingSession) _then;

/// Create a copy of TrainingSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? labelFr = null,Object? labelEn = null,Object? labelDe = null,Object? labelIt = null,Object? labelEs = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,labelFr: null == labelFr ? _self.labelFr : labelFr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,labelDe: null == labelDe ? _self.labelDe : labelDe // ignore: cast_nullable_to_non_nullable
as String,labelIt: null == labelIt ? _self.labelIt : labelIt // ignore: cast_nullable_to_non_nullable
as String,labelEs: null == labelEs ? _self.labelEs : labelEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingSession].
extension TrainingSessionPatterns on TrainingSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingSession value)  $default,){
final _that = this;
switch (_that) {
case _TrainingSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingSession value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingSession() when $default != null:
return $default(_that.id,_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)  $default,) {final _that = this;
switch (_that) {
case _TrainingSession():
return $default(_that.id,_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)?  $default,) {final _that = this;
switch (_that) {
case _TrainingSession() when $default != null:
return $default(_that.id,_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingSession extends TrainingSession {
  const _TrainingSession({required this.id, required this.labelFr, this.labelEn = '', this.labelDe = '', this.labelIt = '', this.labelEs = ''}): super._();
  factory _TrainingSession.fromJson(Map<String, dynamic> json) => _$TrainingSessionFromJson(json);

/// Identifiant STABLE de la seance (cle de persistance du coche).
@override final  String id;
/// Libelle de la seance — francais (base).
@override final  String labelFr;
@override@JsonKey() final  String labelEn;
@override@JsonKey() final  String labelDe;
@override@JsonKey() final  String labelIt;
@override@JsonKey() final  String labelEs;

/// Create a copy of TrainingSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingSessionCopyWith<_TrainingSession> get copyWith => __$TrainingSessionCopyWithImpl<_TrainingSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingSession&&(identical(other.id, id) || other.id == id)&&(identical(other.labelFr, labelFr) || other.labelFr == labelFr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.labelDe, labelDe) || other.labelDe == labelDe)&&(identical(other.labelIt, labelIt) || other.labelIt == labelIt)&&(identical(other.labelEs, labelEs) || other.labelEs == labelEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,labelFr,labelEn,labelDe,labelIt,labelEs);

@override
String toString() {
  return 'TrainingSession(id: $id, labelFr: $labelFr, labelEn: $labelEn, labelDe: $labelDe, labelIt: $labelIt, labelEs: $labelEs)';
}


}

/// @nodoc
abstract mixin class _$TrainingSessionCopyWith<$Res> implements $TrainingSessionCopyWith<$Res> {
  factory _$TrainingSessionCopyWith(_TrainingSession value, $Res Function(_TrainingSession) _then) = __$TrainingSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, String labelFr, String labelEn, String labelDe, String labelIt, String labelEs
});




}
/// @nodoc
class __$TrainingSessionCopyWithImpl<$Res>
    implements _$TrainingSessionCopyWith<$Res> {
  __$TrainingSessionCopyWithImpl(this._self, this._then);

  final _TrainingSession _self;
  final $Res Function(_TrainingSession) _then;

/// Create a copy of TrainingSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? labelFr = null,Object? labelEn = null,Object? labelDe = null,Object? labelIt = null,Object? labelEs = null,}) {
  return _then(_TrainingSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,labelFr: null == labelFr ? _self.labelFr : labelFr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,labelDe: null == labelDe ? _self.labelDe : labelDe // ignore: cast_nullable_to_non_nullable
as String,labelIt: null == labelIt ? _self.labelIt : labelIt // ignore: cast_nullable_to_non_nullable
as String,labelEs: null == labelEs ? _self.labelEs : labelEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TrainingObjective {

/// Enonce de l'objectif — francais (base).
 String get labelFr; String get labelEn; String get labelDe; String get labelIt; String get labelEs;
/// Create a copy of TrainingObjective
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingObjectiveCopyWith<TrainingObjective> get copyWith => _$TrainingObjectiveCopyWithImpl<TrainingObjective>(this as TrainingObjective, _$identity);

  /// Serializes this TrainingObjective to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingObjective&&(identical(other.labelFr, labelFr) || other.labelFr == labelFr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.labelDe, labelDe) || other.labelDe == labelDe)&&(identical(other.labelIt, labelIt) || other.labelIt == labelIt)&&(identical(other.labelEs, labelEs) || other.labelEs == labelEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,labelFr,labelEn,labelDe,labelIt,labelEs);

@override
String toString() {
  return 'TrainingObjective(labelFr: $labelFr, labelEn: $labelEn, labelDe: $labelDe, labelIt: $labelIt, labelEs: $labelEs)';
}


}

/// @nodoc
abstract mixin class $TrainingObjectiveCopyWith<$Res>  {
  factory $TrainingObjectiveCopyWith(TrainingObjective value, $Res Function(TrainingObjective) _then) = _$TrainingObjectiveCopyWithImpl;
@useResult
$Res call({
 String labelFr, String labelEn, String labelDe, String labelIt, String labelEs
});




}
/// @nodoc
class _$TrainingObjectiveCopyWithImpl<$Res>
    implements $TrainingObjectiveCopyWith<$Res> {
  _$TrainingObjectiveCopyWithImpl(this._self, this._then);

  final TrainingObjective _self;
  final $Res Function(TrainingObjective) _then;

/// Create a copy of TrainingObjective
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? labelFr = null,Object? labelEn = null,Object? labelDe = null,Object? labelIt = null,Object? labelEs = null,}) {
  return _then(_self.copyWith(
labelFr: null == labelFr ? _self.labelFr : labelFr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,labelDe: null == labelDe ? _self.labelDe : labelDe // ignore: cast_nullable_to_non_nullable
as String,labelIt: null == labelIt ? _self.labelIt : labelIt // ignore: cast_nullable_to_non_nullable
as String,labelEs: null == labelEs ? _self.labelEs : labelEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingObjective].
extension TrainingObjectivePatterns on TrainingObjective {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingObjective value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingObjective() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingObjective value)  $default,){
final _that = this;
switch (_that) {
case _TrainingObjective():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingObjective value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingObjective() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingObjective() when $default != null:
return $default(_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)  $default,) {final _that = this;
switch (_that) {
case _TrainingObjective():
return $default(_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String labelFr,  String labelEn,  String labelDe,  String labelIt,  String labelEs)?  $default,) {final _that = this;
switch (_that) {
case _TrainingObjective() when $default != null:
return $default(_that.labelFr,_that.labelEn,_that.labelDe,_that.labelIt,_that.labelEs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingObjective extends TrainingObjective {
  const _TrainingObjective({required this.labelFr, this.labelEn = '', this.labelDe = '', this.labelIt = '', this.labelEs = ''}): super._();
  factory _TrainingObjective.fromJson(Map<String, dynamic> json) => _$TrainingObjectiveFromJson(json);

/// Enonce de l'objectif — francais (base).
@override final  String labelFr;
@override@JsonKey() final  String labelEn;
@override@JsonKey() final  String labelDe;
@override@JsonKey() final  String labelIt;
@override@JsonKey() final  String labelEs;

/// Create a copy of TrainingObjective
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingObjectiveCopyWith<_TrainingObjective> get copyWith => __$TrainingObjectiveCopyWithImpl<_TrainingObjective>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingObjectiveToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingObjective&&(identical(other.labelFr, labelFr) || other.labelFr == labelFr)&&(identical(other.labelEn, labelEn) || other.labelEn == labelEn)&&(identical(other.labelDe, labelDe) || other.labelDe == labelDe)&&(identical(other.labelIt, labelIt) || other.labelIt == labelIt)&&(identical(other.labelEs, labelEs) || other.labelEs == labelEs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,labelFr,labelEn,labelDe,labelIt,labelEs);

@override
String toString() {
  return 'TrainingObjective(labelFr: $labelFr, labelEn: $labelEn, labelDe: $labelDe, labelIt: $labelIt, labelEs: $labelEs)';
}


}

/// @nodoc
abstract mixin class _$TrainingObjectiveCopyWith<$Res> implements $TrainingObjectiveCopyWith<$Res> {
  factory _$TrainingObjectiveCopyWith(_TrainingObjective value, $Res Function(_TrainingObjective) _then) = __$TrainingObjectiveCopyWithImpl;
@override @useResult
$Res call({
 String labelFr, String labelEn, String labelDe, String labelIt, String labelEs
});




}
/// @nodoc
class __$TrainingObjectiveCopyWithImpl<$Res>
    implements _$TrainingObjectiveCopyWith<$Res> {
  __$TrainingObjectiveCopyWithImpl(this._self, this._then);

  final _TrainingObjective _self;
  final $Res Function(_TrainingObjective) _then;

/// Create a copy of TrainingObjective
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? labelFr = null,Object? labelEn = null,Object? labelDe = null,Object? labelIt = null,Object? labelEs = null,}) {
  return _then(_TrainingObjective(
labelFr: null == labelFr ? _self.labelFr : labelFr // ignore: cast_nullable_to_non_nullable
as String,labelEn: null == labelEn ? _self.labelEn : labelEn // ignore: cast_nullable_to_non_nullable
as String,labelDe: null == labelDe ? _self.labelDe : labelDe // ignore: cast_nullable_to_non_nullable
as String,labelIt: null == labelIt ? _self.labelIt : labelIt // ignore: cast_nullable_to_non_nullable
as String,labelEs: null == labelEs ? _self.labelEs : labelEs // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
