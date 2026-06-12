// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'variante_etape.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VarianteEtape {

/// Identifiant unique de la variante.
 String get id;/// Identifiant de l'etape de base a laquelle se rattache la variante.
 String get etapeBaseId;/// Libelle court de la variante (ex. 'Officielle', 'Raccourci sud').
 String get label;/// Distance de la variante en kilometres.
 double get distanceKm;/// Denivele positif de la variante en metres.
 double get deniveleM;/// Niveau de difficulte de la variante.
 VarianteDifficulte get difficulte;/// Reference de la trace GPX de la variante (asset / fichier).
 String get traceGpxRef;/// Vrai si c'est la variante officielle (par defaut) de l'etape.
 bool get isOfficielle;
/// Create a copy of VarianteEtape
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VarianteEtapeCopyWith<VarianteEtape> get copyWith => _$VarianteEtapeCopyWithImpl<VarianteEtape>(this as VarianteEtape, _$identity);

  /// Serializes this VarianteEtape to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VarianteEtape&&(identical(other.id, id) || other.id == id)&&(identical(other.etapeBaseId, etapeBaseId) || other.etapeBaseId == etapeBaseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.deniveleM, deniveleM) || other.deniveleM == deniveleM)&&(identical(other.difficulte, difficulte) || other.difficulte == difficulte)&&(identical(other.traceGpxRef, traceGpxRef) || other.traceGpxRef == traceGpxRef)&&(identical(other.isOfficielle, isOfficielle) || other.isOfficielle == isOfficielle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,etapeBaseId,label,distanceKm,deniveleM,difficulte,traceGpxRef,isOfficielle);

@override
String toString() {
  return 'VarianteEtape(id: $id, etapeBaseId: $etapeBaseId, label: $label, distanceKm: $distanceKm, deniveleM: $deniveleM, difficulte: $difficulte, traceGpxRef: $traceGpxRef, isOfficielle: $isOfficielle)';
}


}

/// @nodoc
abstract mixin class $VarianteEtapeCopyWith<$Res>  {
  factory $VarianteEtapeCopyWith(VarianteEtape value, $Res Function(VarianteEtape) _then) = _$VarianteEtapeCopyWithImpl;
@useResult
$Res call({
 String id, String etapeBaseId, String label, double distanceKm, double deniveleM, VarianteDifficulte difficulte, String traceGpxRef, bool isOfficielle
});




}
/// @nodoc
class _$VarianteEtapeCopyWithImpl<$Res>
    implements $VarianteEtapeCopyWith<$Res> {
  _$VarianteEtapeCopyWithImpl(this._self, this._then);

  final VarianteEtape _self;
  final $Res Function(VarianteEtape) _then;

/// Create a copy of VarianteEtape
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? etapeBaseId = null,Object? label = null,Object? distanceKm = null,Object? deniveleM = null,Object? difficulte = null,Object? traceGpxRef = null,Object? isOfficielle = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etapeBaseId: null == etapeBaseId ? _self.etapeBaseId : etapeBaseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,deniveleM: null == deniveleM ? _self.deniveleM : deniveleM // ignore: cast_nullable_to_non_nullable
as double,difficulte: null == difficulte ? _self.difficulte : difficulte // ignore: cast_nullable_to_non_nullable
as VarianteDifficulte,traceGpxRef: null == traceGpxRef ? _self.traceGpxRef : traceGpxRef // ignore: cast_nullable_to_non_nullable
as String,isOfficielle: null == isOfficielle ? _self.isOfficielle : isOfficielle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [VarianteEtape].
extension VarianteEtapePatterns on VarianteEtape {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VarianteEtape value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VarianteEtape() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VarianteEtape value)  $default,){
final _that = this;
switch (_that) {
case _VarianteEtape():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VarianteEtape value)?  $default,){
final _that = this;
switch (_that) {
case _VarianteEtape() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VarianteDifficulte difficulte,  String traceGpxRef,  bool isOfficielle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VarianteEtape() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VarianteDifficulte difficulte,  String traceGpxRef,  bool isOfficielle)  $default,) {final _that = this;
switch (_that) {
case _VarianteEtape():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String etapeBaseId,  String label,  double distanceKm,  double deniveleM,  VarianteDifficulte difficulte,  String traceGpxRef,  bool isOfficielle)?  $default,) {final _that = this;
switch (_that) {
case _VarianteEtape() when $default != null:
return $default(_that.id,_that.etapeBaseId,_that.label,_that.distanceKm,_that.deniveleM,_that.difficulte,_that.traceGpxRef,_that.isOfficielle);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VarianteEtape extends VarianteEtape {
  const _VarianteEtape({required this.id, required this.etapeBaseId, required this.label, required this.distanceKm, required this.deniveleM, required this.difficulte, required this.traceGpxRef, this.isOfficielle = false}): super._();
  factory _VarianteEtape.fromJson(Map<String, dynamic> json) => _$VarianteEtapeFromJson(json);

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
@override final  VarianteDifficulte difficulte;
/// Reference de la trace GPX de la variante (asset / fichier).
@override final  String traceGpxRef;
/// Vrai si c'est la variante officielle (par defaut) de l'etape.
@override@JsonKey() final  bool isOfficielle;

/// Create a copy of VarianteEtape
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VarianteEtapeCopyWith<_VarianteEtape> get copyWith => __$VarianteEtapeCopyWithImpl<_VarianteEtape>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VarianteEtapeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VarianteEtape&&(identical(other.id, id) || other.id == id)&&(identical(other.etapeBaseId, etapeBaseId) || other.etapeBaseId == etapeBaseId)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.deniveleM, deniveleM) || other.deniveleM == deniveleM)&&(identical(other.difficulte, difficulte) || other.difficulte == difficulte)&&(identical(other.traceGpxRef, traceGpxRef) || other.traceGpxRef == traceGpxRef)&&(identical(other.isOfficielle, isOfficielle) || other.isOfficielle == isOfficielle));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,etapeBaseId,label,distanceKm,deniveleM,difficulte,traceGpxRef,isOfficielle);

@override
String toString() {
  return 'VarianteEtape(id: $id, etapeBaseId: $etapeBaseId, label: $label, distanceKm: $distanceKm, deniveleM: $deniveleM, difficulte: $difficulte, traceGpxRef: $traceGpxRef, isOfficielle: $isOfficielle)';
}


}

/// @nodoc
abstract mixin class _$VarianteEtapeCopyWith<$Res> implements $VarianteEtapeCopyWith<$Res> {
  factory _$VarianteEtapeCopyWith(_VarianteEtape value, $Res Function(_VarianteEtape) _then) = __$VarianteEtapeCopyWithImpl;
@override @useResult
$Res call({
 String id, String etapeBaseId, String label, double distanceKm, double deniveleM, VarianteDifficulte difficulte, String traceGpxRef, bool isOfficielle
});




}
/// @nodoc
class __$VarianteEtapeCopyWithImpl<$Res>
    implements _$VarianteEtapeCopyWith<$Res> {
  __$VarianteEtapeCopyWithImpl(this._self, this._then);

  final _VarianteEtape _self;
  final $Res Function(_VarianteEtape) _then;

/// Create a copy of VarianteEtape
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? etapeBaseId = null,Object? label = null,Object? distanceKm = null,Object? deniveleM = null,Object? difficulte = null,Object? traceGpxRef = null,Object? isOfficielle = null,}) {
  return _then(_VarianteEtape(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,etapeBaseId: null == etapeBaseId ? _self.etapeBaseId : etapeBaseId // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,deniveleM: null == deniveleM ? _self.deniveleM : deniveleM // ignore: cast_nullable_to_non_nullable
as double,difficulte: null == difficulte ? _self.difficulte : difficulte // ignore: cast_nullable_to_non_nullable
as VarianteDifficulte,traceGpxRef: null == traceGpxRef ? _self.traceGpxRef : traceGpxRef // ignore: cast_nullable_to_non_nullable
as String,isOfficielle: null == isOfficielle ? _self.isOfficielle : isOfficielle // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$VarianteSelection {

/// Variante choisie par etape de base (etapeBaseId -> varianteId).
 Map<String, String> get selectionParEtape;
/// Create a copy of VarianteSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VarianteSelectionCopyWith<VarianteSelection> get copyWith => _$VarianteSelectionCopyWithImpl<VarianteSelection>(this as VarianteSelection, _$identity);

  /// Serializes this VarianteSelection to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VarianteSelection&&const DeepCollectionEquality().equals(other.selectionParEtape, selectionParEtape));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selectionParEtape));

@override
String toString() {
  return 'VarianteSelection(selectionParEtape: $selectionParEtape)';
}


}

/// @nodoc
abstract mixin class $VarianteSelectionCopyWith<$Res>  {
  factory $VarianteSelectionCopyWith(VarianteSelection value, $Res Function(VarianteSelection) _then) = _$VarianteSelectionCopyWithImpl;
@useResult
$Res call({
 Map<String, String> selectionParEtape
});




}
/// @nodoc
class _$VarianteSelectionCopyWithImpl<$Res>
    implements $VarianteSelectionCopyWith<$Res> {
  _$VarianteSelectionCopyWithImpl(this._self, this._then);

  final VarianteSelection _self;
  final $Res Function(VarianteSelection) _then;

/// Create a copy of VarianteSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selectionParEtape = null,}) {
  return _then(_self.copyWith(
selectionParEtape: null == selectionParEtape ? _self.selectionParEtape : selectionParEtape // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [VarianteSelection].
extension VarianteSelectionPatterns on VarianteSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VarianteSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VarianteSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VarianteSelection value)  $default,){
final _that = this;
switch (_that) {
case _VarianteSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VarianteSelection value)?  $default,){
final _that = this;
switch (_that) {
case _VarianteSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, String> selectionParEtape)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VarianteSelection() when $default != null:
return $default(_that.selectionParEtape);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, String> selectionParEtape)  $default,) {final _that = this;
switch (_that) {
case _VarianteSelection():
return $default(_that.selectionParEtape);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, String> selectionParEtape)?  $default,) {final _that = this;
switch (_that) {
case _VarianteSelection() when $default != null:
return $default(_that.selectionParEtape);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VarianteSelection extends VarianteSelection {
  const _VarianteSelection({final  Map<String, String> selectionParEtape = const <String, String>{}}): _selectionParEtape = selectionParEtape,super._();
  factory _VarianteSelection.fromJson(Map<String, dynamic> json) => _$VarianteSelectionFromJson(json);

/// Variante choisie par etape de base (etapeBaseId -> varianteId).
 final  Map<String, String> _selectionParEtape;
/// Variante choisie par etape de base (etapeBaseId -> varianteId).
@override@JsonKey() Map<String, String> get selectionParEtape {
  if (_selectionParEtape is EqualUnmodifiableMapView) return _selectionParEtape;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_selectionParEtape);
}


/// Create a copy of VarianteSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VarianteSelectionCopyWith<_VarianteSelection> get copyWith => __$VarianteSelectionCopyWithImpl<_VarianteSelection>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VarianteSelectionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VarianteSelection&&const DeepCollectionEquality().equals(other._selectionParEtape, _selectionParEtape));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selectionParEtape));

@override
String toString() {
  return 'VarianteSelection(selectionParEtape: $selectionParEtape)';
}


}

/// @nodoc
abstract mixin class _$VarianteSelectionCopyWith<$Res> implements $VarianteSelectionCopyWith<$Res> {
  factory _$VarianteSelectionCopyWith(_VarianteSelection value, $Res Function(_VarianteSelection) _then) = __$VarianteSelectionCopyWithImpl;
@override @useResult
$Res call({
 Map<String, String> selectionParEtape
});




}
/// @nodoc
class __$VarianteSelectionCopyWithImpl<$Res>
    implements _$VarianteSelectionCopyWith<$Res> {
  __$VarianteSelectionCopyWithImpl(this._self, this._then);

  final _VarianteSelection _self;
  final $Res Function(_VarianteSelection) _then;

/// Create a copy of VarianteSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selectionParEtape = null,}) {
  return _then(_VarianteSelection(
selectionParEtape: null == selectionParEtape ? _self._selectionParEtape : selectionParEtape // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
