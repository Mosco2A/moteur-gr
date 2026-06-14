// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pack_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PackManifest {

/// Identifiant du pack decrit par ce manifeste ([SentierPack.id]).
 String get packId;/// References des fichiers cartes mbtiles (offline).
 List<String> get mbtilesRefs;/// References des traces GPX (offline).
 List<String> get gpxRefs;/// References des jeux de POI (offline).
 List<String> get poiRefs;/// References des town guides (P8-C, offline).
 List<String> get townGuideRefs;/// Reference du snapshot des waypoints communautaires (P8-A, offline).
///
/// Instantane fige a la publication du pack ; les contributions ulterieures
/// arrivent ensuite par la sync differee du [WaypointService] (F8A-02).
 String get waypointsSnapshotRef;/// Taille totale du pack en megaoctets (affichee dans le store, F8B-03).
 int get tailleMo;/// Checksum d'integrite attendu du pack (verifie par F8B-02).
///
/// Optionnel : null tant que le catalogue serveur ne fournit pas de
/// checksum (avant Phase 4, #84627). Quand present, le service refuse un
/// pack dont le checksum calcule differe (ZERO catch silencieux).
 String? get checksum;
/// Create a copy of PackManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackManifestCopyWith<PackManifest> get copyWith => _$PackManifestCopyWithImpl<PackManifest>(this as PackManifest, _$identity);

  /// Serializes this PackManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackManifest&&(identical(other.packId, packId) || other.packId == packId)&&const DeepCollectionEquality().equals(other.mbtilesRefs, mbtilesRefs)&&const DeepCollectionEquality().equals(other.gpxRefs, gpxRefs)&&const DeepCollectionEquality().equals(other.poiRefs, poiRefs)&&const DeepCollectionEquality().equals(other.townGuideRefs, townGuideRefs)&&(identical(other.waypointsSnapshotRef, waypointsSnapshotRef) || other.waypointsSnapshotRef == waypointsSnapshotRef)&&(identical(other.tailleMo, tailleMo) || other.tailleMo == tailleMo)&&(identical(other.checksum, checksum) || other.checksum == checksum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packId,const DeepCollectionEquality().hash(mbtilesRefs),const DeepCollectionEquality().hash(gpxRefs),const DeepCollectionEquality().hash(poiRefs),const DeepCollectionEquality().hash(townGuideRefs),waypointsSnapshotRef,tailleMo,checksum);

@override
String toString() {
  return 'PackManifest(packId: $packId, mbtilesRefs: $mbtilesRefs, gpxRefs: $gpxRefs, poiRefs: $poiRefs, townGuideRefs: $townGuideRefs, waypointsSnapshotRef: $waypointsSnapshotRef, tailleMo: $tailleMo, checksum: $checksum)';
}


}

/// @nodoc
abstract mixin class $PackManifestCopyWith<$Res>  {
  factory $PackManifestCopyWith(PackManifest value, $Res Function(PackManifest) _then) = _$PackManifestCopyWithImpl;
@useResult
$Res call({
 String packId, List<String> mbtilesRefs, List<String> gpxRefs, List<String> poiRefs, List<String> townGuideRefs, String waypointsSnapshotRef, int tailleMo, String? checksum
});




}
/// @nodoc
class _$PackManifestCopyWithImpl<$Res>
    implements $PackManifestCopyWith<$Res> {
  _$PackManifestCopyWithImpl(this._self, this._then);

  final PackManifest _self;
  final $Res Function(PackManifest) _then;

/// Create a copy of PackManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packId = null,Object? mbtilesRefs = null,Object? gpxRefs = null,Object? poiRefs = null,Object? townGuideRefs = null,Object? waypointsSnapshotRef = null,Object? tailleMo = null,Object? checksum = freezed,}) {
  return _then(_self.copyWith(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,mbtilesRefs: null == mbtilesRefs ? _self.mbtilesRefs : mbtilesRefs // ignore: cast_nullable_to_non_nullable
as List<String>,gpxRefs: null == gpxRefs ? _self.gpxRefs : gpxRefs // ignore: cast_nullable_to_non_nullable
as List<String>,poiRefs: null == poiRefs ? _self.poiRefs : poiRefs // ignore: cast_nullable_to_non_nullable
as List<String>,townGuideRefs: null == townGuideRefs ? _self.townGuideRefs : townGuideRefs // ignore: cast_nullable_to_non_nullable
as List<String>,waypointsSnapshotRef: null == waypointsSnapshotRef ? _self.waypointsSnapshotRef : waypointsSnapshotRef // ignore: cast_nullable_to_non_nullable
as String,tailleMo: null == tailleMo ? _self.tailleMo : tailleMo // ignore: cast_nullable_to_non_nullable
as int,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PackManifest].
extension PackManifestPatterns on PackManifest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackManifest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackManifest value)  $default,){
final _that = this;
switch (_that) {
case _PackManifest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackManifest value)?  $default,){
final _that = this;
switch (_that) {
case _PackManifest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String packId,  List<String> mbtilesRefs,  List<String> gpxRefs,  List<String> poiRefs,  List<String> townGuideRefs,  String waypointsSnapshotRef,  int tailleMo,  String? checksum)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackManifest() when $default != null:
return $default(_that.packId,_that.mbtilesRefs,_that.gpxRefs,_that.poiRefs,_that.townGuideRefs,_that.waypointsSnapshotRef,_that.tailleMo,_that.checksum);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String packId,  List<String> mbtilesRefs,  List<String> gpxRefs,  List<String> poiRefs,  List<String> townGuideRefs,  String waypointsSnapshotRef,  int tailleMo,  String? checksum)  $default,) {final _that = this;
switch (_that) {
case _PackManifest():
return $default(_that.packId,_that.mbtilesRefs,_that.gpxRefs,_that.poiRefs,_that.townGuideRefs,_that.waypointsSnapshotRef,_that.tailleMo,_that.checksum);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String packId,  List<String> mbtilesRefs,  List<String> gpxRefs,  List<String> poiRefs,  List<String> townGuideRefs,  String waypointsSnapshotRef,  int tailleMo,  String? checksum)?  $default,) {final _that = this;
switch (_that) {
case _PackManifest() when $default != null:
return $default(_that.packId,_that.mbtilesRefs,_that.gpxRefs,_that.poiRefs,_that.townGuideRefs,_that.waypointsSnapshotRef,_that.tailleMo,_that.checksum);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PackManifest extends PackManifest {
  const _PackManifest({required this.packId, final  List<String> mbtilesRefs = const <String>[], final  List<String> gpxRefs = const <String>[], final  List<String> poiRefs = const <String>[], final  List<String> townGuideRefs = const <String>[], required this.waypointsSnapshotRef, required this.tailleMo, this.checksum}): _mbtilesRefs = mbtilesRefs,_gpxRefs = gpxRefs,_poiRefs = poiRefs,_townGuideRefs = townGuideRefs,super._();
  factory _PackManifest.fromJson(Map<String, dynamic> json) => _$PackManifestFromJson(json);

/// Identifiant du pack decrit par ce manifeste ([SentierPack.id]).
@override final  String packId;
/// References des fichiers cartes mbtiles (offline).
 final  List<String> _mbtilesRefs;
/// References des fichiers cartes mbtiles (offline).
@override@JsonKey() List<String> get mbtilesRefs {
  if (_mbtilesRefs is EqualUnmodifiableListView) return _mbtilesRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_mbtilesRefs);
}

/// References des traces GPX (offline).
 final  List<String> _gpxRefs;
/// References des traces GPX (offline).
@override@JsonKey() List<String> get gpxRefs {
  if (_gpxRefs is EqualUnmodifiableListView) return _gpxRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_gpxRefs);
}

/// References des jeux de POI (offline).
 final  List<String> _poiRefs;
/// References des jeux de POI (offline).
@override@JsonKey() List<String> get poiRefs {
  if (_poiRefs is EqualUnmodifiableListView) return _poiRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_poiRefs);
}

/// References des town guides (P8-C, offline).
 final  List<String> _townGuideRefs;
/// References des town guides (P8-C, offline).
@override@JsonKey() List<String> get townGuideRefs {
  if (_townGuideRefs is EqualUnmodifiableListView) return _townGuideRefs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_townGuideRefs);
}

/// Reference du snapshot des waypoints communautaires (P8-A, offline).
///
/// Instantane fige a la publication du pack ; les contributions ulterieures
/// arrivent ensuite par la sync differee du [WaypointService] (F8A-02).
@override final  String waypointsSnapshotRef;
/// Taille totale du pack en megaoctets (affichee dans le store, F8B-03).
@override final  int tailleMo;
/// Checksum d'integrite attendu du pack (verifie par F8B-02).
///
/// Optionnel : null tant que le catalogue serveur ne fournit pas de
/// checksum (avant Phase 4, #84627). Quand present, le service refuse un
/// pack dont le checksum calcule differe (ZERO catch silencieux).
@override final  String? checksum;

/// Create a copy of PackManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackManifestCopyWith<_PackManifest> get copyWith => __$PackManifestCopyWithImpl<_PackManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackManifest&&(identical(other.packId, packId) || other.packId == packId)&&const DeepCollectionEquality().equals(other._mbtilesRefs, _mbtilesRefs)&&const DeepCollectionEquality().equals(other._gpxRefs, _gpxRefs)&&const DeepCollectionEquality().equals(other._poiRefs, _poiRefs)&&const DeepCollectionEquality().equals(other._townGuideRefs, _townGuideRefs)&&(identical(other.waypointsSnapshotRef, waypointsSnapshotRef) || other.waypointsSnapshotRef == waypointsSnapshotRef)&&(identical(other.tailleMo, tailleMo) || other.tailleMo == tailleMo)&&(identical(other.checksum, checksum) || other.checksum == checksum));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,packId,const DeepCollectionEquality().hash(_mbtilesRefs),const DeepCollectionEquality().hash(_gpxRefs),const DeepCollectionEquality().hash(_poiRefs),const DeepCollectionEquality().hash(_townGuideRefs),waypointsSnapshotRef,tailleMo,checksum);

@override
String toString() {
  return 'PackManifest(packId: $packId, mbtilesRefs: $mbtilesRefs, gpxRefs: $gpxRefs, poiRefs: $poiRefs, townGuideRefs: $townGuideRefs, waypointsSnapshotRef: $waypointsSnapshotRef, tailleMo: $tailleMo, checksum: $checksum)';
}


}

/// @nodoc
abstract mixin class _$PackManifestCopyWith<$Res> implements $PackManifestCopyWith<$Res> {
  factory _$PackManifestCopyWith(_PackManifest value, $Res Function(_PackManifest) _then) = __$PackManifestCopyWithImpl;
@override @useResult
$Res call({
 String packId, List<String> mbtilesRefs, List<String> gpxRefs, List<String> poiRefs, List<String> townGuideRefs, String waypointsSnapshotRef, int tailleMo, String? checksum
});




}
/// @nodoc
class __$PackManifestCopyWithImpl<$Res>
    implements _$PackManifestCopyWith<$Res> {
  __$PackManifestCopyWithImpl(this._self, this._then);

  final _PackManifest _self;
  final $Res Function(_PackManifest) _then;

/// Create a copy of PackManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packId = null,Object? mbtilesRefs = null,Object? gpxRefs = null,Object? poiRefs = null,Object? townGuideRefs = null,Object? waypointsSnapshotRef = null,Object? tailleMo = null,Object? checksum = freezed,}) {
  return _then(_PackManifest(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,mbtilesRefs: null == mbtilesRefs ? _self._mbtilesRefs : mbtilesRefs // ignore: cast_nullable_to_non_nullable
as List<String>,gpxRefs: null == gpxRefs ? _self._gpxRefs : gpxRefs // ignore: cast_nullable_to_non_nullable
as List<String>,poiRefs: null == poiRefs ? _self._poiRefs : poiRefs // ignore: cast_nullable_to_non_nullable
as List<String>,townGuideRefs: null == townGuideRefs ? _self._townGuideRefs : townGuideRefs // ignore: cast_nullable_to_non_nullable
as List<String>,waypointsSnapshotRef: null == waypointsSnapshotRef ? _self.waypointsSnapshotRef : waypointsSnapshotRef // ignore: cast_nullable_to_non_nullable
as String,tailleMo: null == tailleMo ? _self.tailleMo : tailleMo // ignore: cast_nullable_to_non_nullable
as int,checksum: freezed == checksum ? _self.checksum : checksum // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
