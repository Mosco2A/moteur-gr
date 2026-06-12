// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'programme_entrainement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SeanceEntrainement {

/// Decalage en jours depuis le debut du programme (0 = jour 1).
 int get jourOffset;/// Type de seance (marche, cardio, renforcement).
 TypeSeance get type;/// Duree de la seance en minutes.
 int get dureeMin;/// Intensite de la seance.
 IntensiteSeance get intensite;/// Description / consigne de la seance.
 String get description;
/// Create a copy of SeanceEntrainement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeanceEntrainementCopyWith<SeanceEntrainement> get copyWith => _$SeanceEntrainementCopyWithImpl<SeanceEntrainement>(this as SeanceEntrainement, _$identity);

  /// Serializes this SeanceEntrainement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeanceEntrainement&&(identical(other.jourOffset, jourOffset) || other.jourOffset == jourOffset)&&(identical(other.type, type) || other.type == type)&&(identical(other.dureeMin, dureeMin) || other.dureeMin == dureeMin)&&(identical(other.intensite, intensite) || other.intensite == intensite)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jourOffset,type,dureeMin,intensite,description);

@override
String toString() {
  return 'SeanceEntrainement(jourOffset: $jourOffset, type: $type, dureeMin: $dureeMin, intensite: $intensite, description: $description)';
}


}

/// @nodoc
abstract mixin class $SeanceEntrainementCopyWith<$Res>  {
  factory $SeanceEntrainementCopyWith(SeanceEntrainement value, $Res Function(SeanceEntrainement) _then) = _$SeanceEntrainementCopyWithImpl;
@useResult
$Res call({
 int jourOffset, TypeSeance type, int dureeMin, IntensiteSeance intensite, String description
});




}
/// @nodoc
class _$SeanceEntrainementCopyWithImpl<$Res>
    implements $SeanceEntrainementCopyWith<$Res> {
  _$SeanceEntrainementCopyWithImpl(this._self, this._then);

  final SeanceEntrainement _self;
  final $Res Function(SeanceEntrainement) _then;

/// Create a copy of SeanceEntrainement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jourOffset = null,Object? type = null,Object? dureeMin = null,Object? intensite = null,Object? description = null,}) {
  return _then(_self.copyWith(
jourOffset: null == jourOffset ? _self.jourOffset : jourOffset // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeSeance,dureeMin: null == dureeMin ? _self.dureeMin : dureeMin // ignore: cast_nullable_to_non_nullable
as int,intensite: null == intensite ? _self.intensite : intensite // ignore: cast_nullable_to_non_nullable
as IntensiteSeance,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SeanceEntrainement].
extension SeanceEntrainementPatterns on SeanceEntrainement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeanceEntrainement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeanceEntrainement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeanceEntrainement value)  $default,){
final _that = this;
switch (_that) {
case _SeanceEntrainement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeanceEntrainement value)?  $default,){
final _that = this;
switch (_that) {
case _SeanceEntrainement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int jourOffset,  TypeSeance type,  int dureeMin,  IntensiteSeance intensite,  String description)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeanceEntrainement() when $default != null:
return $default(_that.jourOffset,_that.type,_that.dureeMin,_that.intensite,_that.description);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int jourOffset,  TypeSeance type,  int dureeMin,  IntensiteSeance intensite,  String description)  $default,) {final _that = this;
switch (_that) {
case _SeanceEntrainement():
return $default(_that.jourOffset,_that.type,_that.dureeMin,_that.intensite,_that.description);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int jourOffset,  TypeSeance type,  int dureeMin,  IntensiteSeance intensite,  String description)?  $default,) {final _that = this;
switch (_that) {
case _SeanceEntrainement() when $default != null:
return $default(_that.jourOffset,_that.type,_that.dureeMin,_that.intensite,_that.description);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeanceEntrainement extends SeanceEntrainement {
  const _SeanceEntrainement({required this.jourOffset, required this.type, required this.dureeMin, required this.intensite, required this.description}): super._();
  factory _SeanceEntrainement.fromJson(Map<String, dynamic> json) => _$SeanceEntrainementFromJson(json);

/// Decalage en jours depuis le debut du programme (0 = jour 1).
@override final  int jourOffset;
/// Type de seance (marche, cardio, renforcement).
@override final  TypeSeance type;
/// Duree de la seance en minutes.
@override final  int dureeMin;
/// Intensite de la seance.
@override final  IntensiteSeance intensite;
/// Description / consigne de la seance.
@override final  String description;

/// Create a copy of SeanceEntrainement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeanceEntrainementCopyWith<_SeanceEntrainement> get copyWith => __$SeanceEntrainementCopyWithImpl<_SeanceEntrainement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeanceEntrainementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeanceEntrainement&&(identical(other.jourOffset, jourOffset) || other.jourOffset == jourOffset)&&(identical(other.type, type) || other.type == type)&&(identical(other.dureeMin, dureeMin) || other.dureeMin == dureeMin)&&(identical(other.intensite, intensite) || other.intensite == intensite)&&(identical(other.description, description) || other.description == description));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jourOffset,type,dureeMin,intensite,description);

@override
String toString() {
  return 'SeanceEntrainement(jourOffset: $jourOffset, type: $type, dureeMin: $dureeMin, intensite: $intensite, description: $description)';
}


}

/// @nodoc
abstract mixin class _$SeanceEntrainementCopyWith<$Res> implements $SeanceEntrainementCopyWith<$Res> {
  factory _$SeanceEntrainementCopyWith(_SeanceEntrainement value, $Res Function(_SeanceEntrainement) _then) = __$SeanceEntrainementCopyWithImpl;
@override @useResult
$Res call({
 int jourOffset, TypeSeance type, int dureeMin, IntensiteSeance intensite, String description
});




}
/// @nodoc
class __$SeanceEntrainementCopyWithImpl<$Res>
    implements _$SeanceEntrainementCopyWith<$Res> {
  __$SeanceEntrainementCopyWithImpl(this._self, this._then);

  final _SeanceEntrainement _self;
  final $Res Function(_SeanceEntrainement) _then;

/// Create a copy of SeanceEntrainement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jourOffset = null,Object? type = null,Object? dureeMin = null,Object? intensite = null,Object? description = null,}) {
  return _then(_SeanceEntrainement(
jourOffset: null == jourOffset ? _self.jourOffset : jourOffset // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TypeSeance,dureeMin: null == dureeMin ? _self.dureeMin : dureeMin // ignore: cast_nullable_to_non_nullable
as int,intensite: null == intensite ? _self.intensite : intensite // ignore: cast_nullable_to_non_nullable
as IntensiteSeance,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProgrammeEntrainement {

/// Identifiant du programme.
 String get id;/// Duree totale du programme en semaines.
 int get dureeSemaines;/// Seances planifiees, ordonnees par jourOffset croissant.
 List<SeanceEntrainement> get seances;
/// Create a copy of ProgrammeEntrainement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgrammeEntrainementCopyWith<ProgrammeEntrainement> get copyWith => _$ProgrammeEntrainementCopyWithImpl<ProgrammeEntrainement>(this as ProgrammeEntrainement, _$identity);

  /// Serializes this ProgrammeEntrainement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgrammeEntrainement&&(identical(other.id, id) || other.id == id)&&(identical(other.dureeSemaines, dureeSemaines) || other.dureeSemaines == dureeSemaines)&&const DeepCollectionEquality().equals(other.seances, seances));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dureeSemaines,const DeepCollectionEquality().hash(seances));

@override
String toString() {
  return 'ProgrammeEntrainement(id: $id, dureeSemaines: $dureeSemaines, seances: $seances)';
}


}

/// @nodoc
abstract mixin class $ProgrammeEntrainementCopyWith<$Res>  {
  factory $ProgrammeEntrainementCopyWith(ProgrammeEntrainement value, $Res Function(ProgrammeEntrainement) _then) = _$ProgrammeEntrainementCopyWithImpl;
@useResult
$Res call({
 String id, int dureeSemaines, List<SeanceEntrainement> seances
});




}
/// @nodoc
class _$ProgrammeEntrainementCopyWithImpl<$Res>
    implements $ProgrammeEntrainementCopyWith<$Res> {
  _$ProgrammeEntrainementCopyWithImpl(this._self, this._then);

  final ProgrammeEntrainement _self;
  final $Res Function(ProgrammeEntrainement) _then;

/// Create a copy of ProgrammeEntrainement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dureeSemaines = null,Object? seances = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dureeSemaines: null == dureeSemaines ? _self.dureeSemaines : dureeSemaines // ignore: cast_nullable_to_non_nullable
as int,seances: null == seances ? _self.seances : seances // ignore: cast_nullable_to_non_nullable
as List<SeanceEntrainement>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgrammeEntrainement].
extension ProgrammeEntrainementPatterns on ProgrammeEntrainement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgrammeEntrainement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgrammeEntrainement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgrammeEntrainement value)  $default,){
final _that = this;
switch (_that) {
case _ProgrammeEntrainement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgrammeEntrainement value)?  $default,){
final _that = this;
switch (_that) {
case _ProgrammeEntrainement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int dureeSemaines,  List<SeanceEntrainement> seances)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgrammeEntrainement() when $default != null:
return $default(_that.id,_that.dureeSemaines,_that.seances);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int dureeSemaines,  List<SeanceEntrainement> seances)  $default,) {final _that = this;
switch (_that) {
case _ProgrammeEntrainement():
return $default(_that.id,_that.dureeSemaines,_that.seances);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int dureeSemaines,  List<SeanceEntrainement> seances)?  $default,) {final _that = this;
switch (_that) {
case _ProgrammeEntrainement() when $default != null:
return $default(_that.id,_that.dureeSemaines,_that.seances);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgrammeEntrainement extends ProgrammeEntrainement {
  const _ProgrammeEntrainement({required this.id, required this.dureeSemaines, required final  List<SeanceEntrainement> seances}): _seances = seances,super._();
  factory _ProgrammeEntrainement.fromJson(Map<String, dynamic> json) => _$ProgrammeEntrainementFromJson(json);

/// Identifiant du programme.
@override final  String id;
/// Duree totale du programme en semaines.
@override final  int dureeSemaines;
/// Seances planifiees, ordonnees par jourOffset croissant.
 final  List<SeanceEntrainement> _seances;
/// Seances planifiees, ordonnees par jourOffset croissant.
@override List<SeanceEntrainement> get seances {
  if (_seances is EqualUnmodifiableListView) return _seances;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seances);
}


/// Create a copy of ProgrammeEntrainement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgrammeEntrainementCopyWith<_ProgrammeEntrainement> get copyWith => __$ProgrammeEntrainementCopyWithImpl<_ProgrammeEntrainement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgrammeEntrainementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgrammeEntrainement&&(identical(other.id, id) || other.id == id)&&(identical(other.dureeSemaines, dureeSemaines) || other.dureeSemaines == dureeSemaines)&&const DeepCollectionEquality().equals(other._seances, _seances));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dureeSemaines,const DeepCollectionEquality().hash(_seances));

@override
String toString() {
  return 'ProgrammeEntrainement(id: $id, dureeSemaines: $dureeSemaines, seances: $seances)';
}


}

/// @nodoc
abstract mixin class _$ProgrammeEntrainementCopyWith<$Res> implements $ProgrammeEntrainementCopyWith<$Res> {
  factory _$ProgrammeEntrainementCopyWith(_ProgrammeEntrainement value, $Res Function(_ProgrammeEntrainement) _then) = __$ProgrammeEntrainementCopyWithImpl;
@override @useResult
$Res call({
 String id, int dureeSemaines, List<SeanceEntrainement> seances
});




}
/// @nodoc
class __$ProgrammeEntrainementCopyWithImpl<$Res>
    implements _$ProgrammeEntrainementCopyWith<$Res> {
  __$ProgrammeEntrainementCopyWithImpl(this._self, this._then);

  final _ProgrammeEntrainement _self;
  final $Res Function(_ProgrammeEntrainement) _then;

/// Create a copy of ProgrammeEntrainement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dureeSemaines = null,Object? seances = null,}) {
  return _then(_ProgrammeEntrainement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dureeSemaines: null == dureeSemaines ? _self.dureeSemaines : dureeSemaines // ignore: cast_nullable_to_non_nullable
as int,seances: null == seances ? _self._seances : seances // ignore: cast_nullable_to_non_nullable
as List<SeanceEntrainement>,
  ));
}


}

// dart format on
