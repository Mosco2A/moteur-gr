// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'delta_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DeltaUpdate {

/// Identifiant du sentier concerne
 String get trailId;/// MON REPERE : jusqu a QUEL INSTANT ce telephone est a jour.
/// [HorodatageServeur.origine] = rien n est copie.
@HorodatageServeurJson() HorodatageServeur get fromVersion;/// L INSTANT DE PUBLICATION du sentier, tel que la liste distante l annonce.
@HorodatageServeurJson() HorodatageServeur get toVersion;/// Taille du fichier de donnees en octets (pour annoncer le cout au
/// randonneur qui paie son forfait).
 int get downloadSize;
/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeltaUpdateCopyWith<DeltaUpdate> get copyWith => _$DeltaUpdateCopyWithImpl<DeltaUpdate>(this as DeltaUpdate, _$identity);

  /// Serializes this DeltaUpdate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeltaUpdate&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.fromVersion, fromVersion) || other.fromVersion == fromVersion)&&(identical(other.toVersion, toVersion) || other.toVersion == toVersion)&&(identical(other.downloadSize, downloadSize) || other.downloadSize == downloadSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,fromVersion,toVersion,downloadSize);

@override
String toString() {
  return 'DeltaUpdate(trailId: $trailId, fromVersion: $fromVersion, toVersion: $toVersion, downloadSize: $downloadSize)';
}


}

/// @nodoc
abstract mixin class $DeltaUpdateCopyWith<$Res>  {
  factory $DeltaUpdateCopyWith(DeltaUpdate value, $Res Function(DeltaUpdate) _then) = _$DeltaUpdateCopyWithImpl;
@useResult
$Res call({
 String trailId,@HorodatageServeurJson() HorodatageServeur fromVersion,@HorodatageServeurJson() HorodatageServeur toVersion, int downloadSize
});




}
/// @nodoc
class _$DeltaUpdateCopyWithImpl<$Res>
    implements $DeltaUpdateCopyWith<$Res> {
  _$DeltaUpdateCopyWithImpl(this._self, this._then);

  final DeltaUpdate _self;
  final $Res Function(DeltaUpdate) _then;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trailId = null,Object? fromVersion = null,Object? toVersion = null,Object? downloadSize = null,}) {
  return _then(_self.copyWith(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,fromVersion: null == fromVersion ? _self.fromVersion : fromVersion // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,toVersion: null == toVersion ? _self.toVersion : toVersion // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,downloadSize: null == downloadSize ? _self.downloadSize : downloadSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DeltaUpdate].
extension DeltaUpdatePatterns on DeltaUpdate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeltaUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeltaUpdate value)  $default,){
final _that = this;
switch (_that) {
case _DeltaUpdate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeltaUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trailId, @HorodatageServeurJson()  HorodatageServeur fromVersion, @HorodatageServeurJson()  HorodatageServeur toVersion,  int downloadSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.downloadSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trailId, @HorodatageServeurJson()  HorodatageServeur fromVersion, @HorodatageServeurJson()  HorodatageServeur toVersion,  int downloadSize)  $default,) {final _that = this;
switch (_that) {
case _DeltaUpdate():
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.downloadSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trailId, @HorodatageServeurJson()  HorodatageServeur fromVersion, @HorodatageServeurJson()  HorodatageServeur toVersion,  int downloadSize)?  $default,) {final _that = this;
switch (_that) {
case _DeltaUpdate() when $default != null:
return $default(_that.trailId,_that.fromVersion,_that.toVersion,_that.downloadSize);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeltaUpdate extends DeltaUpdate {
  const _DeltaUpdate({required this.trailId, @HorodatageServeurJson() required this.fromVersion, @HorodatageServeurJson() required this.toVersion, required this.downloadSize}): super._();
  factory _DeltaUpdate.fromJson(Map<String, dynamic> json) => _$DeltaUpdateFromJson(json);

/// Identifiant du sentier concerne
@override final  String trailId;
/// MON REPERE : jusqu a QUEL INSTANT ce telephone est a jour.
/// [HorodatageServeur.origine] = rien n est copie.
@override@HorodatageServeurJson() final  HorodatageServeur fromVersion;
/// L INSTANT DE PUBLICATION du sentier, tel que la liste distante l annonce.
@override@HorodatageServeurJson() final  HorodatageServeur toVersion;
/// Taille du fichier de donnees en octets (pour annoncer le cout au
/// randonneur qui paie son forfait).
@override final  int downloadSize;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeltaUpdateCopyWith<_DeltaUpdate> get copyWith => __$DeltaUpdateCopyWithImpl<_DeltaUpdate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeltaUpdateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeltaUpdate&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.fromVersion, fromVersion) || other.fromVersion == fromVersion)&&(identical(other.toVersion, toVersion) || other.toVersion == toVersion)&&(identical(other.downloadSize, downloadSize) || other.downloadSize == downloadSize));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,fromVersion,toVersion,downloadSize);

@override
String toString() {
  return 'DeltaUpdate(trailId: $trailId, fromVersion: $fromVersion, toVersion: $toVersion, downloadSize: $downloadSize)';
}


}

/// @nodoc
abstract mixin class _$DeltaUpdateCopyWith<$Res> implements $DeltaUpdateCopyWith<$Res> {
  factory _$DeltaUpdateCopyWith(_DeltaUpdate value, $Res Function(_DeltaUpdate) _then) = __$DeltaUpdateCopyWithImpl;
@override @useResult
$Res call({
 String trailId,@HorodatageServeurJson() HorodatageServeur fromVersion,@HorodatageServeurJson() HorodatageServeur toVersion, int downloadSize
});




}
/// @nodoc
class __$DeltaUpdateCopyWithImpl<$Res>
    implements _$DeltaUpdateCopyWith<$Res> {
  __$DeltaUpdateCopyWithImpl(this._self, this._then);

  final _DeltaUpdate _self;
  final $Res Function(_DeltaUpdate) _then;

/// Create a copy of DeltaUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trailId = null,Object? fromVersion = null,Object? toVersion = null,Object? downloadSize = null,}) {
  return _then(_DeltaUpdate(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,fromVersion: null == fromVersion ? _self.fromVersion : fromVersion // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,toVersion: null == toVersion ? _self.toVersion : toVersion // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,downloadSize: null == downloadSize ? _self.downloadSize : downloadSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ResultatSynchronisation {

/// Familles de donnees effectivement touchees (`stages`, `pois`...).
 List<String> get famillesTouchees;/// Nombre d enregistrements ecrits ou mis a jour.
 int get ecrits;/// Nombre d enregistrements RETIRES du telephone sur marqueur de suppression.
 int get supprimes;/// L INSTANT atteint apres application : le nouveau repere du telephone.
@HorodatageServeurJson() HorodatageServeur get revisionAtteinte;/// JUSQU OU LE SENTIER EST DESCENDU apres cette passe (tache 616).
///
/// `null` uniquement quand rien n a jamais ete copie et que la passe n a rien
/// copie non plus (niveau « regarder » sur un sentier neuf).
 NiveauDeTelechargement? get niveauAtteint;/// ENREGISTREMENTS QUI ONT REELLEMENT TRAVERSE LE RESEAU.
///
/// LES QUATRE COMPTEURS CI-DESSOUS REMONTENT DE LA SOURCE JUSQU ICI, ET C EST
/// LA DEMANDE DE MESURE DE LA TACHE 616. Ils etaient deja comptes par
/// `MorceauxAPrendre` mais s arretaient dans un journal : aucun appelant, aucun
/// test ne pouvait les affirmer. Or la seule facon de prouver qu un niveau ne
/// descend pas plus que son perimetre est de COMPTER — c est ainsi que la tache
/// 606 a prouve qu un enregistrement transitait au lieu de dix.
 int get transferes;/// Enregistrements retenus : plus recents que le repere ET dans le niveau.
 int get retenus;/// Enregistrements descendus puis ECARTES parce que hors du niveau demande.
///
/// Non nul sur une source de fichier des qu on prepare un sentier dont la trace
/// est publiee : les octets ont traverse le reseau, on ne les ecrit pas. Nul sur
/// une source interrogeable, qui ne les demande pas. Le chiffre reste visible
/// meme quand il est genant — c est lui qui dit ou l economie est reelle.
 int get ecartesHorsNiveau;/// Octets recus, quand la source peut les compter (0 = inconnu).
 int get octetsRecus;
/// Create a copy of ResultatSynchronisation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResultatSynchronisationCopyWith<ResultatSynchronisation> get copyWith => _$ResultatSynchronisationCopyWithImpl<ResultatSynchronisation>(this as ResultatSynchronisation, _$identity);

  /// Serializes this ResultatSynchronisation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResultatSynchronisation&&const DeepCollectionEquality().equals(other.famillesTouchees, famillesTouchees)&&(identical(other.ecrits, ecrits) || other.ecrits == ecrits)&&(identical(other.supprimes, supprimes) || other.supprimes == supprimes)&&(identical(other.revisionAtteinte, revisionAtteinte) || other.revisionAtteinte == revisionAtteinte)&&(identical(other.niveauAtteint, niveauAtteint) || other.niveauAtteint == niveauAtteint)&&(identical(other.transferes, transferes) || other.transferes == transferes)&&(identical(other.retenus, retenus) || other.retenus == retenus)&&(identical(other.ecartesHorsNiveau, ecartesHorsNiveau) || other.ecartesHorsNiveau == ecartesHorsNiveau)&&(identical(other.octetsRecus, octetsRecus) || other.octetsRecus == octetsRecus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(famillesTouchees),ecrits,supprimes,revisionAtteinte,niveauAtteint,transferes,retenus,ecartesHorsNiveau,octetsRecus);

@override
String toString() {
  return 'ResultatSynchronisation(famillesTouchees: $famillesTouchees, ecrits: $ecrits, supprimes: $supprimes, revisionAtteinte: $revisionAtteinte, niveauAtteint: $niveauAtteint, transferes: $transferes, retenus: $retenus, ecartesHorsNiveau: $ecartesHorsNiveau, octetsRecus: $octetsRecus)';
}


}

/// @nodoc
abstract mixin class $ResultatSynchronisationCopyWith<$Res>  {
  factory $ResultatSynchronisationCopyWith(ResultatSynchronisation value, $Res Function(ResultatSynchronisation) _then) = _$ResultatSynchronisationCopyWithImpl;
@useResult
$Res call({
 List<String> famillesTouchees, int ecrits, int supprimes,@HorodatageServeurJson() HorodatageServeur revisionAtteinte, NiveauDeTelechargement? niveauAtteint, int transferes, int retenus, int ecartesHorsNiveau, int octetsRecus
});




}
/// @nodoc
class _$ResultatSynchronisationCopyWithImpl<$Res>
    implements $ResultatSynchronisationCopyWith<$Res> {
  _$ResultatSynchronisationCopyWithImpl(this._self, this._then);

  final ResultatSynchronisation _self;
  final $Res Function(ResultatSynchronisation) _then;

/// Create a copy of ResultatSynchronisation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? famillesTouchees = null,Object? ecrits = null,Object? supprimes = null,Object? revisionAtteinte = null,Object? niveauAtteint = freezed,Object? transferes = null,Object? retenus = null,Object? ecartesHorsNiveau = null,Object? octetsRecus = null,}) {
  return _then(_self.copyWith(
famillesTouchees: null == famillesTouchees ? _self.famillesTouchees : famillesTouchees // ignore: cast_nullable_to_non_nullable
as List<String>,ecrits: null == ecrits ? _self.ecrits : ecrits // ignore: cast_nullable_to_non_nullable
as int,supprimes: null == supprimes ? _self.supprimes : supprimes // ignore: cast_nullable_to_non_nullable
as int,revisionAtteinte: null == revisionAtteinte ? _self.revisionAtteinte : revisionAtteinte // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,niveauAtteint: freezed == niveauAtteint ? _self.niveauAtteint : niveauAtteint // ignore: cast_nullable_to_non_nullable
as NiveauDeTelechargement?,transferes: null == transferes ? _self.transferes : transferes // ignore: cast_nullable_to_non_nullable
as int,retenus: null == retenus ? _self.retenus : retenus // ignore: cast_nullable_to_non_nullable
as int,ecartesHorsNiveau: null == ecartesHorsNiveau ? _self.ecartesHorsNiveau : ecartesHorsNiveau // ignore: cast_nullable_to_non_nullable
as int,octetsRecus: null == octetsRecus ? _self.octetsRecus : octetsRecus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ResultatSynchronisation].
extension ResultatSynchronisationPatterns on ResultatSynchronisation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResultatSynchronisation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResultatSynchronisation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResultatSynchronisation value)  $default,){
final _that = this;
switch (_that) {
case _ResultatSynchronisation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResultatSynchronisation value)?  $default,){
final _that = this;
switch (_that) {
case _ResultatSynchronisation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> famillesTouchees,  int ecrits,  int supprimes, @HorodatageServeurJson()  HorodatageServeur revisionAtteinte,  NiveauDeTelechargement? niveauAtteint,  int transferes,  int retenus,  int ecartesHorsNiveau,  int octetsRecus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResultatSynchronisation() when $default != null:
return $default(_that.famillesTouchees,_that.ecrits,_that.supprimes,_that.revisionAtteinte,_that.niveauAtteint,_that.transferes,_that.retenus,_that.ecartesHorsNiveau,_that.octetsRecus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> famillesTouchees,  int ecrits,  int supprimes, @HorodatageServeurJson()  HorodatageServeur revisionAtteinte,  NiveauDeTelechargement? niveauAtteint,  int transferes,  int retenus,  int ecartesHorsNiveau,  int octetsRecus)  $default,) {final _that = this;
switch (_that) {
case _ResultatSynchronisation():
return $default(_that.famillesTouchees,_that.ecrits,_that.supprimes,_that.revisionAtteinte,_that.niveauAtteint,_that.transferes,_that.retenus,_that.ecartesHorsNiveau,_that.octetsRecus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> famillesTouchees,  int ecrits,  int supprimes, @HorodatageServeurJson()  HorodatageServeur revisionAtteinte,  NiveauDeTelechargement? niveauAtteint,  int transferes,  int retenus,  int ecartesHorsNiveau,  int octetsRecus)?  $default,) {final _that = this;
switch (_that) {
case _ResultatSynchronisation() when $default != null:
return $default(_that.famillesTouchees,_that.ecrits,_that.supprimes,_that.revisionAtteinte,_that.niveauAtteint,_that.transferes,_that.retenus,_that.ecartesHorsNiveau,_that.octetsRecus);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResultatSynchronisation extends ResultatSynchronisation {
  const _ResultatSynchronisation({required final  List<String> famillesTouchees, required this.ecrits, required this.supprimes, @HorodatageServeurJson() required this.revisionAtteinte, this.niveauAtteint, this.transferes = 0, this.retenus = 0, this.ecartesHorsNiveau = 0, this.octetsRecus = 0}): _famillesTouchees = famillesTouchees,super._();
  factory _ResultatSynchronisation.fromJson(Map<String, dynamic> json) => _$ResultatSynchronisationFromJson(json);

/// Familles de donnees effectivement touchees (`stages`, `pois`...).
 final  List<String> _famillesTouchees;
/// Familles de donnees effectivement touchees (`stages`, `pois`...).
@override List<String> get famillesTouchees {
  if (_famillesTouchees is EqualUnmodifiableListView) return _famillesTouchees;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_famillesTouchees);
}

/// Nombre d enregistrements ecrits ou mis a jour.
@override final  int ecrits;
/// Nombre d enregistrements RETIRES du telephone sur marqueur de suppression.
@override final  int supprimes;
/// L INSTANT atteint apres application : le nouveau repere du telephone.
@override@HorodatageServeurJson() final  HorodatageServeur revisionAtteinte;
/// JUSQU OU LE SENTIER EST DESCENDU apres cette passe (tache 616).
///
/// `null` uniquement quand rien n a jamais ete copie et que la passe n a rien
/// copie non plus (niveau « regarder » sur un sentier neuf).
@override final  NiveauDeTelechargement? niveauAtteint;
/// ENREGISTREMENTS QUI ONT REELLEMENT TRAVERSE LE RESEAU.
///
/// LES QUATRE COMPTEURS CI-DESSOUS REMONTENT DE LA SOURCE JUSQU ICI, ET C EST
/// LA DEMANDE DE MESURE DE LA TACHE 616. Ils etaient deja comptes par
/// `MorceauxAPrendre` mais s arretaient dans un journal : aucun appelant, aucun
/// test ne pouvait les affirmer. Or la seule facon de prouver qu un niveau ne
/// descend pas plus que son perimetre est de COMPTER — c est ainsi que la tache
/// 606 a prouve qu un enregistrement transitait au lieu de dix.
@override@JsonKey() final  int transferes;
/// Enregistrements retenus : plus recents que le repere ET dans le niveau.
@override@JsonKey() final  int retenus;
/// Enregistrements descendus puis ECARTES parce que hors du niveau demande.
///
/// Non nul sur une source de fichier des qu on prepare un sentier dont la trace
/// est publiee : les octets ont traverse le reseau, on ne les ecrit pas. Nul sur
/// une source interrogeable, qui ne les demande pas. Le chiffre reste visible
/// meme quand il est genant — c est lui qui dit ou l economie est reelle.
@override@JsonKey() final  int ecartesHorsNiveau;
/// Octets recus, quand la source peut les compter (0 = inconnu).
@override@JsonKey() final  int octetsRecus;

/// Create a copy of ResultatSynchronisation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResultatSynchronisationCopyWith<_ResultatSynchronisation> get copyWith => __$ResultatSynchronisationCopyWithImpl<_ResultatSynchronisation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResultatSynchronisationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResultatSynchronisation&&const DeepCollectionEquality().equals(other._famillesTouchees, _famillesTouchees)&&(identical(other.ecrits, ecrits) || other.ecrits == ecrits)&&(identical(other.supprimes, supprimes) || other.supprimes == supprimes)&&(identical(other.revisionAtteinte, revisionAtteinte) || other.revisionAtteinte == revisionAtteinte)&&(identical(other.niveauAtteint, niveauAtteint) || other.niveauAtteint == niveauAtteint)&&(identical(other.transferes, transferes) || other.transferes == transferes)&&(identical(other.retenus, retenus) || other.retenus == retenus)&&(identical(other.ecartesHorsNiveau, ecartesHorsNiveau) || other.ecartesHorsNiveau == ecartesHorsNiveau)&&(identical(other.octetsRecus, octetsRecus) || other.octetsRecus == octetsRecus));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_famillesTouchees),ecrits,supprimes,revisionAtteinte,niveauAtteint,transferes,retenus,ecartesHorsNiveau,octetsRecus);

@override
String toString() {
  return 'ResultatSynchronisation(famillesTouchees: $famillesTouchees, ecrits: $ecrits, supprimes: $supprimes, revisionAtteinte: $revisionAtteinte, niveauAtteint: $niveauAtteint, transferes: $transferes, retenus: $retenus, ecartesHorsNiveau: $ecartesHorsNiveau, octetsRecus: $octetsRecus)';
}


}

/// @nodoc
abstract mixin class _$ResultatSynchronisationCopyWith<$Res> implements $ResultatSynchronisationCopyWith<$Res> {
  factory _$ResultatSynchronisationCopyWith(_ResultatSynchronisation value, $Res Function(_ResultatSynchronisation) _then) = __$ResultatSynchronisationCopyWithImpl;
@override @useResult
$Res call({
 List<String> famillesTouchees, int ecrits, int supprimes,@HorodatageServeurJson() HorodatageServeur revisionAtteinte, NiveauDeTelechargement? niveauAtteint, int transferes, int retenus, int ecartesHorsNiveau, int octetsRecus
});




}
/// @nodoc
class __$ResultatSynchronisationCopyWithImpl<$Res>
    implements _$ResultatSynchronisationCopyWith<$Res> {
  __$ResultatSynchronisationCopyWithImpl(this._self, this._then);

  final _ResultatSynchronisation _self;
  final $Res Function(_ResultatSynchronisation) _then;

/// Create a copy of ResultatSynchronisation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? famillesTouchees = null,Object? ecrits = null,Object? supprimes = null,Object? revisionAtteinte = null,Object? niveauAtteint = freezed,Object? transferes = null,Object? retenus = null,Object? ecartesHorsNiveau = null,Object? octetsRecus = null,}) {
  return _then(_ResultatSynchronisation(
famillesTouchees: null == famillesTouchees ? _self._famillesTouchees : famillesTouchees // ignore: cast_nullable_to_non_nullable
as List<String>,ecrits: null == ecrits ? _self.ecrits : ecrits // ignore: cast_nullable_to_non_nullable
as int,supprimes: null == supprimes ? _self.supprimes : supprimes // ignore: cast_nullable_to_non_nullable
as int,revisionAtteinte: null == revisionAtteinte ? _self.revisionAtteinte : revisionAtteinte // ignore: cast_nullable_to_non_nullable
as HorodatageServeur,niveauAtteint: freezed == niveauAtteint ? _self.niveauAtteint : niveauAtteint // ignore: cast_nullable_to_non_nullable
as NiveauDeTelechargement?,transferes: null == transferes ? _self.transferes : transferes // ignore: cast_nullable_to_non_nullable
as int,retenus: null == retenus ? _self.retenus : retenus // ignore: cast_nullable_to_non_nullable
as int,ecartesHorsNiveau: null == ecartesHorsNiveau ? _self.ecartesHorsNiveau : ecartesHorsNiveau // ignore: cast_nullable_to_non_nullable
as int,octetsRecus: null == octetsRecus ? _self.octetsRecus : octetsRecus // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
