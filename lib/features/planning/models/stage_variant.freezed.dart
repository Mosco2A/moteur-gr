// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage_variant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StageVariant {

/// Identifiant unique de la variante.
 String get id;/// Identifiant de l'etape de base a laquelle se rattache la variante.
 String get etapeBaseId;/// Libelle court de la variante (ex. 'Officielle', 'Raccourci sud').
 String get label;/// Distance de la variante en kilometres.
 double get distanceKm;/// Denivele positif de la variante en metres.
 double get deniveleM;/// Niveau de difficulte de la variante.
 VariantDifficulty get difficulte;/// Reference de la trace GPX de la variante (asset / fichier).
 String get traceGpxRef;/// Vrai si c'est la variante officielle (par defaut) de l'etape.
 bool get isOfficielle;
/// Create a copy of StageVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StageVariantCopyWith<StageVariant> get copyWith => _$StageVariantCopyWithImpl<StageVariant>(this as StageVariant, _$identity);

  /// Serializes this StageVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StageVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.etapeBaseId, etapeBaseId) || other.etapeBaseId == etapeBaseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.deniveleM, deniveleM) || other.deniveleM == deniveleM)&&(identical(other.difficulte, difficulte) || other.difficulte == difficulte)&&(identical(other.traceGpxRef, traceGpxRef) || other.traceGpxRef == traceGpxRef)&&(identical(other.isOfficielle, isOfficielle) || other.isOfficielle == isOfficielle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,etapeBaseId,label,distanceKm,deniveleM,difficulte,traceGpxRef,isOfficielle);

@override
String toString() {
  return 'StageVariant(id: $id, etapeBaseId: $etapeBaseId, label: $label, distanceKm: $distanceKm, deniveleM: $deniveleM, difficulte: $difficulte, traceGpxRef: $traceGpxRef, isOfficielle: $isOfficielle)';
}


}

/// @nodoc
abstract mixin class $StageVariantCopyWith<$Res>  {
  factory $StageVariantCopyWith(StageVariant value, $Res Function(StageVariant) _then) = _$StageVariantCopyWithImpl;
@useResult
$Res call({
 String id, String etapeBaseId, String label, double distanceKm, double deniveleM, VariantDifficulty difficulte, String traceGpxRef, bool isOfficielle
});




}
/// @nodoc
class _$StageVariantCopyWithImpl<$Res>
    implements $StageVariantCopyWith<$Res> {
  _$StageVariantCopyWithImpl(this._self, this._then);

  final StageVariant _self;
  final $Res Function(StageVariant) _then;

/// Create a copy of StageVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? etapeBaseId = null,Object? label = null,Object? distanceKm = null,Object? deniveleM = null,Object? difficulte = null,Object? traceGpxRef = null,Object? isOfficielle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etapeBaseId: null == etapeBaseId ? _self.etapeBaseId : etapeBaseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,deniveleM: null == deniveleM ? _self.deniveleM : deniveleM // ignore: cast_nullable_to_non_nullable
as double,difficulte: null == difficulte ? _self.difficulte : difficulte // ignore: cast_nullable_to_non_nullable
as VariantDifficulty,traceGpxRef: null == traceGpxRef ? _self.traceGpxRef : traceGpxRef // ignore: cast_nullable_to_non_nullable
as String,isOfficielle: null == isOfficielle ? _self.isOfficielle : isOfficielle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [StageVariant].
extension StageVariantPatterns on StageVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StageVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StageVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StageVariant value)  $default,){
final _that = this;
switch (_that) {
case _StageVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StageVariant value)?  $default,){
final _that = this;
switch (_that) {
case _StageVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VariantDifficulty difficulte,  String traceGpxRef,  bool isOfficielle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StageVariant() when $default != null:
return $default(_that.id,_that.etapeBaseId,_that.label,_that.distanceKm,_that.deniveleM,_that.difficulte,_that.traceGpxRef,_that.isOfficielle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VariantDifficulty difficulte,  String traceGpxRef,  bool isOfficielle)  $default,) {final _that = this;
switch (_that) {
case _StageVariant():
return $default(_that.id,_that.etapeBaseId,_that.label,_that.distanceKm,_that.deniveleM,_that.difficulte,_that.traceGpxRef,_that.isOfficielle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VariantDifficulty difficulte,  String traceGpxRef,  bool isOfficielle)?  $default,) {final _that = this;
switch (_that) {
case _StageVariant() when $default != null:
return $default(_that.id,_that.etapeBaseId,_that.label,_that.distanceKm,_that.deniveleM,_that.difficulte,_that.traceGpxRef,_that.isOfficielle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StageVariant extends StageVariant {
  const _StageVariant({required this.id, required this.etapeBaseId, required this.label, required this.distanceKm, required this.deniveleM, required this.difficulte, required this.traceGpxRef, this.isOfficielle = false}): super._();
  factory _StageVariant.fromJson(Map<String, dynamic> json) => _$StageVariantFromJson(json);

/// Identifiant unique de la variante.
@override final  String id;
/// Identifiant de l'etape de base a laquelle se rattache la variante.
@override final  String etapeBaseId;
/// Libelle court de la variante (ex. 'Officielle', 'Raccourci sud').
@override final  String label;
/// Distance de la variante en kilometres.
@override final  double distanceKm;
/// Denivele positif de la variante en metres.
@override final  double deniveleM;
/// Niveau de difficulte de la variante.
@override final  VariantDifficulty difficulte;
/// Reference de la trace GPX de la variante (asset / fichier).
@override final  String traceGpxRef;
/// Vrai si c'est la variante officielle (par defaut) de l'etape.
@override@JsonKey() final  bool isOfficielle;

/// Create a copy of StageVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StageVariantCopyWith<_StageVariant> get copyWith => __$StageVariantCopyWithImpl<_StageVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StageVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StageVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.etapeBaseId, etapeBaseId) || other.etapeBaseId == etapeBaseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.deniveleM, deniveleM) || other.deniveleM == deniveleM)&&(identical(other.difficulte, difficulte) || other.difficulte == difficulte)&&(identical(other.traceGpxRef, traceGpxRef) || other.traceGpxRef == traceGpxRef)&&(identical(other.isOfficielle, isOfficielle) || other.isOfficielle == isOfficielle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,etapeBaseId,label,distanceKm,deniveleM,difficulte,traceGpxRef,isOfficielle);

@override
String toString() {
  return 'StageVariant(id: $id, etapeBaseId: $etapeBaseId, label: $label, distanceKm: $distanceKm, deniveleM: $deniveleM, difficulte: $difficulte, traceGpxRef: $traceGpxRef, isOfficielle: $isOfficielle)';
}


}

/// @nodoc
abstract mixin class _$StageVariantCopyWith<$Res> implements $StageVariantCopyWith<$Res> {
  factory _$StageVariantCopyWith(_StageVariant value, $Res Function(_StageVariant) _then) = __$StageVariantCopyWithImpl;
@override @useResult
$Res call({
 String id, String etapeBaseId, String label, double distanceKm, double deniveleM, VariantDifficulty difficulte, String traceGpxRef, bool isOfficielle
});




}
/// @nodoc
class __$StageVariantCopyWithImpl<$Res>
    implements _$StageVariantCopyWith<$Res> {
  __$StageVariantCopyWithImpl(this._self, this._then);

  final _StageVariant _self;
  final $Res Function(_StageVariant) _then;

/// Create a copy of StageVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? etapeBaseId = null,Object? label = null,Object? distanceKm = null,Object? deniveleM = null,Object? difficulte = null,Object? traceGpxRef = null,Object? isOfficielle = null,}) {
  return _then(_StageVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etapeBaseId: null == etapeBaseId ? _self.etapeBaseId : etapeBaseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,deniveleM: null == deniveleM ? _self.deniveleM : deniveleM // ignore: cast_nullable_to_non_nullable
as double,difficulte: null == difficulte ? _self.difficulte : difficulte // ignore: cast_nullable_to_non_nullable
as VariantDifficulty,traceGpxRef: null == traceGpxRef ? _self.traceGpxRef : traceGpxRef // ignore: cast_nullable_to_non_nullable
as String,isOfficielle: null == isOfficielle ? _self.isOfficielle : isOfficielle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$VariantSelection {

/// Variante choisie par etape de base (etapeBaseId -> varianteId).
@JsonKey(name: 'selectionParEtape') Map<String, String> get selectionByStage;
/// Create a copy of VariantSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantSelectionCopyWith<VariantSelection> get copyWith => _$VariantSelectionCopyWithImpl<VariantSelection>(this as VariantSelection, _$identity);

  /// Serializes this VariantSelection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantSelection&&const DeepCollectionEquality().equals(other.selectionByStage, selectionByStage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectionByStage));

@override
String toString() {
  return 'VariantSelection(selectionByStage: $selectionByStage)';
}


}

/// @nodoc
abstract mixin class $VariantSelectionCopyWith<$Res>  {
  factory $VariantSelectionCopyWith(VariantSelection value, $Res Function(VariantSelection) _then) = _$VariantSelectionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'selectionParEtape') Map<String, String> selectionByStage
});




}
/// @nodoc
class _$VariantSelectionCopyWithImpl<$Res>
    implements $VariantSelectionCopyWith<$Res> {
  _$VariantSelectionCopyWithImpl(this._self, this._then);

  final VariantSelection _self;
  final $Res Function(VariantSelection) _then;

/// Create a copy of VariantSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectionByStage = null,}) {
  return _then(_self.copyWith(
selectionByStage: null == selectionByStage ? _self.selectionByStage : selectionByStage // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VariantSelection].
extension VariantSelectionPatterns on VariantSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VariantSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VariantSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VariantSelection value)  $default,){
final _that = this;
switch (_that) {
case _VariantSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VariantSelection value)?  $default,){
final _that = this;
switch (_that) {
case _VariantSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'selectionParEtape')  Map<String, String> selectionByStage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VariantSelection() when $default != null:
return $default(_that.selectionByStage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'selectionParEtape')  Map<String, String> selectionByStage)  $default,) {final _that = this;
switch (_that) {
case _VariantSelection():
return $default(_that.selectionByStage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'selectionParEtape')  Map<String, String> selectionByStage)?  $default,) {final _that = this;
switch (_that) {
case _VariantSelection() when $default != null:
return $default(_that.selectionByStage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VariantSelection extends VariantSelection {
  const _VariantSelection({@JsonKey(name: 'selectionParEtape') final  Map<String, String> selectionByStage = const <String, String>{}}): _selectionByStage = selectionByStage,super._();
  factory _VariantSelection.fromJson(Map<String, dynamic> json) => _$VariantSelectionFromJson(json);

/// Variante choisie par etape de base (etapeBaseId -> varianteId).
 final  Map<String, String> _selectionByStage;
/// Variante choisie par etape de base (etapeBaseId -> varianteId).
@override@JsonKey(name: 'selectionParEtape') Map<String, String> get selectionByStage {
  if (_selectionByStage is EqualUnmodifiableMapView) return _selectionByStage;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectionByStage);
}


/// Create a copy of VariantSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VariantSelectionCopyWith<_VariantSelection> get copyWith => __$VariantSelectionCopyWithImpl<_VariantSelection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VariantSelectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VariantSelection&&const DeepCollectionEquality().equals(other._selectionByStage, _selectionByStage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectionByStage));

@override
String toString() {
  return 'VariantSelection(selectionByStage: $selectionByStage)';
}


}

/// @nodoc
abstract mixin class _$VariantSelectionCopyWith<$Res> implements $VariantSelectionCopyWith<$Res> {
  factory _$VariantSelectionCopyWith(_VariantSelection value, $Res Function(_VariantSelection) _then) = __$VariantSelectionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'selectionParEtape') Map<String, String> selectionByStage
});




}
/// @nodoc
class __$VariantSelectionCopyWithImpl<$Res>
    implements _$VariantSelectionCopyWith<$Res> {
  __$VariantSelectionCopyWithImpl(this._self, this._then);

  final _VariantSelection _self;
  final $Res Function(_VariantSelection) _then;

/// Create a copy of VariantSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectionByStage = null,}) {
  return _then(_VariantSelection(
selectionByStage: null == selectionByStage ? _self._selectionByStage : selectionByStage // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
