// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrailManifest {

/// Version du schema du manifeste (2 depuis la tache 605)
 int get schemaVersion;/// Liste des sentiers declares dans le manifeste
 List<TrailManifestEntry> get trails;
/// Create a copy of TrailManifest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrailManifestCopyWith<TrailManifest> get copyWith => _$TrailManifestCopyWithImpl<TrailManifest>(this as TrailManifest, _$identity);

  /// Serializes this TrailManifest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrailManifest&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other.trails, trails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(trails));

@override
String toString() {
  return 'TrailManifest(schemaVersion: $schemaVersion, trails: $trails)';
}


}

/// @nodoc
abstract mixin class $TrailManifestCopyWith<$Res>  {
  factory $TrailManifestCopyWith(TrailManifest value, $Res Function(TrailManifest) _then) = _$TrailManifestCopyWithImpl;
@useResult
$Res call({
 int schemaVersion, List<TrailManifestEntry> trails
});




}
/// @nodoc
class _$TrailManifestCopyWithImpl<$Res>
    implements $TrailManifestCopyWith<$Res> {
  _$TrailManifestCopyWithImpl(this._self, this._then);

  final TrailManifest _self;
  final $Res Function(TrailManifest) _then;

/// Create a copy of TrailManifest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? schemaVersion = null,Object? trails = null,}) {
  return _then(_self.copyWith(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,trails: null == trails ? _self.trails : trails // ignore: cast_nullable_to_non_nullable
as List<TrailManifestEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [TrailManifest].
extension TrailManifestPatterns on TrailManifest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrailManifest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrailManifest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrailManifest value)  $default,){
final _that = this;
switch (_that) {
case _TrailManifest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrailManifest value)?  $default,){
final _that = this;
switch (_that) {
case _TrailManifest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int schemaVersion,  List<TrailManifestEntry> trails)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrailManifest() when $default != null:
return $default(_that.schemaVersion,_that.trails);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int schemaVersion,  List<TrailManifestEntry> trails)  $default,) {final _that = this;
switch (_that) {
case _TrailManifest():
return $default(_that.schemaVersion,_that.trails);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int schemaVersion,  List<TrailManifestEntry> trails)?  $default,) {final _that = this;
switch (_that) {
case _TrailManifest() when $default != null:
return $default(_that.schemaVersion,_that.trails);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrailManifest implements TrailManifest {
  const _TrailManifest({required this.schemaVersion, required final  List<TrailManifestEntry> trails}): _trails = trails;
  factory _TrailManifest.fromJson(Map<String, dynamic> json) => _$TrailManifestFromJson(json);

/// Version du schema du manifeste (2 depuis la tache 605)
@override final  int schemaVersion;
/// Liste des sentiers declares dans le manifeste
 final  List<TrailManifestEntry> _trails;
/// Liste des sentiers declares dans le manifeste
@override List<TrailManifestEntry> get trails {
  if (_trails is EqualUnmodifiableListView) return _trails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trails);
}


/// Create a copy of TrailManifest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrailManifestCopyWith<_TrailManifest> get copyWith => __$TrailManifestCopyWithImpl<_TrailManifest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrailManifestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrailManifest&&(identical(other.schemaVersion, schemaVersion) || other.schemaVersion == schemaVersion)&&const DeepCollectionEquality().equals(other._trails, _trails));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,schemaVersion,const DeepCollectionEquality().hash(_trails));

@override
String toString() {
  return 'TrailManifest(schemaVersion: $schemaVersion, trails: $trails)';
}


}

/// @nodoc
abstract mixin class _$TrailManifestCopyWith<$Res> implements $TrailManifestCopyWith<$Res> {
  factory _$TrailManifestCopyWith(_TrailManifest value, $Res Function(_TrailManifest) _then) = __$TrailManifestCopyWithImpl;
@override @useResult
$Res call({
 int schemaVersion, List<TrailManifestEntry> trails
});




}
/// @nodoc
class __$TrailManifestCopyWithImpl<$Res>
    implements _$TrailManifestCopyWith<$Res> {
  __$TrailManifestCopyWithImpl(this._self, this._then);

  final _TrailManifest _self;
  final $Res Function(_TrailManifest) _then;

/// Create a copy of TrailManifest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? schemaVersion = null,Object? trails = null,}) {
  return _then(_TrailManifest(
schemaVersion: null == schemaVersion ? _self.schemaVersion : schemaVersion // ignore: cast_nullable_to_non_nullable
as int,trails: null == trails ? _self._trails : trails // ignore: cast_nullable_to_non_nullable
as List<TrailManifestEntry>,
  ));
}


}


/// @nodoc
mixin _$TrailManifestEntry {

/// Identifiant unique du sentier (ex: 'gr10', 'tmb').
///
/// C EST LA CLE, et elle est la meme des deux cotes : un sentier present
/// dans le catalogue compile ET dans le manifeste distant n est pas deux
/// sentiers, c est le meme.
 String get trailId;/// LA REVISION COURANTE DU SENTIER — le numero de la derniere revision
/// publiee.
///
/// C est la moitie de l unique question que l application pose : « je suis a
/// la revision R (`trail_manifests.localVersion`), tu es a la revision
/// [dataVersion] ; donne-moi tout ce qui porte un numero superieur a R ».
/// L autre moitie est portee par chaque enregistrement
/// (`RevisionDeDonnee.champRevision`).
///
/// A la premiere ouverture la revision locale vaut zero : tout est plus
/// recent, donc tout descend. Premiere copie et mise a jour sont le MEME
/// chemin de code.
 int get dataVersion;/// Hash SHA-256 du fichier de donnees COMPLET du sentier.
 String get hash;/// Chemin du fichier de donnees du sentier.
///
/// LE TRANSPORT, ET SA LIMITE MESUREE. Le moteur telecharge ce fichier puis
/// ne pose QUE les enregistrements dont la revision depasse la sienne : la
/// correction d une altitude ecrit UNE etape, pas sept tables. En revanche le
/// TRANSFERT reste global tant que les donnees vivent dans un fichier a plat.
/// Sur une base interrogeable (Firestore), la meme question devient une
/// requete `rev > R` et le transfert devient lui aussi unitaire, sans changer
/// une ligne de la logique ci-dessous. C est la seule difference entre les
/// deux transports, et elle est en octets, pas en comportement.
 String get filePath;/// Taille du fichier de donnees complet, en octets.
 int get fileSize;/// Statut du sentier ('active', 'draft', 'archived')
 String get status;/// Date de derniere mise a jour (ISO 8601)
 String get lastUpdated;/// FICHE D AFFICHAGE DU SENTIER — LA PIECE QUI MANQUAIT AU MOTEUR.
///
/// CE QUI ETAIT CASSE, ET C EST LE MUR N1 (tache 605). Le manifeste ne
/// portait QUE du versionnement : identifiant, version, hash, taille,
/// statut, date. Aucun NOM, aucune REGION, aucune STATISTIQUE. Or l ecran
/// catalogue affiche une carte par sentier avec son nom, sa region, sa
/// distance, son denivele et son nombre d etapes — toutes choses que le
/// manifeste ne disait pas. CONSEQUENCE MECANIQUE : un sentier connu du
/// SEUL distant etait strictement INAFFICHABLE, quoi qu on branche. Le
/// chainage n etait donc pas le seul manque ; le manifeste lui-meme etait
/// incapable de decrire un sentier.
///
/// Elle est OPTIONNELLE, et les deux cas ont un sens precis :
///
///  * PRESENTE — le sentier est entierement decrit a distance. Il apparait
///    au catalogue SANS republication au magasin : c est le critere de
///    reussite du lot, verbatim de Christophe du 27/09 19:57 (« faire lire
///    les donnees automatiquement a l appli pour que ca affiche les
///    nouveaux sentiers totalement decrits en base »).
///
///  * ABSENTE — l entree ne fait que VERSIONNER un sentier que le binaire
///    connait deja (catalogue compile). Si le binaire ne le connait pas non
///    plus, l entree n est pas affichable et elle est ecartee avec un
///    journal qui le DIT (cf. `sentier_distant.dart`) — jamais une carte
///    vide au catalogue.
 TrailManifestFiche? get fiche;
/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrailManifestEntryCopyWith<TrailManifestEntry> get copyWith => _$TrailManifestEntryCopyWithImpl<TrailManifestEntry>(this as TrailManifestEntry, _$identity);

  /// Serializes this TrailManifestEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrailManifestEntry&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.dataVersion, dataVersion) || other.dataVersion == dataVersion)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.fiche, fiche) || other.fiche == fiche));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,dataVersion,hash,filePath,fileSize,status,lastUpdated,fiche);

@override
String toString() {
  return 'TrailManifestEntry(trailId: $trailId, dataVersion: $dataVersion, hash: $hash, filePath: $filePath, fileSize: $fileSize, status: $status, lastUpdated: $lastUpdated, fiche: $fiche)';
}


}

/// @nodoc
abstract mixin class $TrailManifestEntryCopyWith<$Res>  {
  factory $TrailManifestEntryCopyWith(TrailManifestEntry value, $Res Function(TrailManifestEntry) _then) = _$TrailManifestEntryCopyWithImpl;
@useResult
$Res call({
 String trailId, int dataVersion, String hash, String filePath, int fileSize, String status, String lastUpdated, TrailManifestFiche? fiche
});


$TrailManifestFicheCopyWith<$Res>? get fiche;

}
/// @nodoc
class _$TrailManifestEntryCopyWithImpl<$Res>
    implements $TrailManifestEntryCopyWith<$Res> {
  _$TrailManifestEntryCopyWithImpl(this._self, this._then);

  final TrailManifestEntry _self;
  final $Res Function(TrailManifestEntry) _then;

/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trailId = null,Object? dataVersion = null,Object? hash = null,Object? filePath = null,Object? fileSize = null,Object? status = null,Object? lastUpdated = null,Object? fiche = freezed,}) {
  return _then(_self.copyWith(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,dataVersion: null == dataVersion ? _self.dataVersion : dataVersion // ignore: cast_nullable_to_non_nullable
as int,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String,fiche: freezed == fiche ? _self.fiche : fiche // ignore: cast_nullable_to_non_nullable
as TrailManifestFiche?,
  ));
}
/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrailManifestFicheCopyWith<$Res>? get fiche {
    if (_self.fiche == null) {
    return null;
  }

  return $TrailManifestFicheCopyWith<$Res>(_self.fiche!, (value) {
    return _then(_self.copyWith(fiche: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrailManifestEntry].
extension TrailManifestEntryPatterns on TrailManifestEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrailManifestEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrailManifestEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrailManifestEntry value)  $default,){
final _that = this;
switch (_that) {
case _TrailManifestEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrailManifestEntry value)?  $default,){
final _that = this;
switch (_that) {
case _TrailManifestEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trailId,  int dataVersion,  String hash,  String filePath,  int fileSize,  String status,  String lastUpdated,  TrailManifestFiche? fiche)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrailManifestEntry() when $default != null:
return $default(_that.trailId,_that.dataVersion,_that.hash,_that.filePath,_that.fileSize,_that.status,_that.lastUpdated,_that.fiche);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trailId,  int dataVersion,  String hash,  String filePath,  int fileSize,  String status,  String lastUpdated,  TrailManifestFiche? fiche)  $default,) {final _that = this;
switch (_that) {
case _TrailManifestEntry():
return $default(_that.trailId,_that.dataVersion,_that.hash,_that.filePath,_that.fileSize,_that.status,_that.lastUpdated,_that.fiche);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trailId,  int dataVersion,  String hash,  String filePath,  int fileSize,  String status,  String lastUpdated,  TrailManifestFiche? fiche)?  $default,) {final _that = this;
switch (_that) {
case _TrailManifestEntry() when $default != null:
return $default(_that.trailId,_that.dataVersion,_that.hash,_that.filePath,_that.fileSize,_that.status,_that.lastUpdated,_that.fiche);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrailManifestEntry implements TrailManifestEntry {
  const _TrailManifestEntry({required this.trailId, required this.dataVersion, required this.hash, required this.filePath, required this.fileSize, required this.status, required this.lastUpdated, this.fiche});
  factory _TrailManifestEntry.fromJson(Map<String, dynamic> json) => _$TrailManifestEntryFromJson(json);

/// Identifiant unique du sentier (ex: 'gr10', 'tmb').
///
/// C EST LA CLE, et elle est la meme des deux cotes : un sentier present
/// dans le catalogue compile ET dans le manifeste distant n est pas deux
/// sentiers, c est le meme.
@override final  String trailId;
/// LA REVISION COURANTE DU SENTIER — le numero de la derniere revision
/// publiee.
///
/// C est la moitie de l unique question que l application pose : « je suis a
/// la revision R (`trail_manifests.localVersion`), tu es a la revision
/// [dataVersion] ; donne-moi tout ce qui porte un numero superieur a R ».
/// L autre moitie est portee par chaque enregistrement
/// (`RevisionDeDonnee.champRevision`).
///
/// A la premiere ouverture la revision locale vaut zero : tout est plus
/// recent, donc tout descend. Premiere copie et mise a jour sont le MEME
/// chemin de code.
@override final  int dataVersion;
/// Hash SHA-256 du fichier de donnees COMPLET du sentier.
@override final  String hash;
/// Chemin du fichier de donnees du sentier.
///
/// LE TRANSPORT, ET SA LIMITE MESUREE. Le moteur telecharge ce fichier puis
/// ne pose QUE les enregistrements dont la revision depasse la sienne : la
/// correction d une altitude ecrit UNE etape, pas sept tables. En revanche le
/// TRANSFERT reste global tant que les donnees vivent dans un fichier a plat.
/// Sur une base interrogeable (Firestore), la meme question devient une
/// requete `rev > R` et le transfert devient lui aussi unitaire, sans changer
/// une ligne de la logique ci-dessous. C est la seule difference entre les
/// deux transports, et elle est en octets, pas en comportement.
@override final  String filePath;
/// Taille du fichier de donnees complet, en octets.
@override final  int fileSize;
/// Statut du sentier ('active', 'draft', 'archived')
@override final  String status;
/// Date de derniere mise a jour (ISO 8601)
@override final  String lastUpdated;
/// FICHE D AFFICHAGE DU SENTIER — LA PIECE QUI MANQUAIT AU MOTEUR.
///
/// CE QUI ETAIT CASSE, ET C EST LE MUR N1 (tache 605). Le manifeste ne
/// portait QUE du versionnement : identifiant, version, hash, taille,
/// statut, date. Aucun NOM, aucune REGION, aucune STATISTIQUE. Or l ecran
/// catalogue affiche une carte par sentier avec son nom, sa region, sa
/// distance, son denivele et son nombre d etapes — toutes choses que le
/// manifeste ne disait pas. CONSEQUENCE MECANIQUE : un sentier connu du
/// SEUL distant etait strictement INAFFICHABLE, quoi qu on branche. Le
/// chainage n etait donc pas le seul manque ; le manifeste lui-meme etait
/// incapable de decrire un sentier.
///
/// Elle est OPTIONNELLE, et les deux cas ont un sens precis :
///
///  * PRESENTE — le sentier est entierement decrit a distance. Il apparait
///    au catalogue SANS republication au magasin : c est le critere de
///    reussite du lot, verbatim de Christophe du 27/09 19:57 (« faire lire
///    les donnees automatiquement a l appli pour que ca affiche les
///    nouveaux sentiers totalement decrits en base »).
///
///  * ABSENTE — l entree ne fait que VERSIONNER un sentier que le binaire
///    connait deja (catalogue compile). Si le binaire ne le connait pas non
///    plus, l entree n est pas affichable et elle est ecartee avec un
///    journal qui le DIT (cf. `sentier_distant.dart`) — jamais une carte
///    vide au catalogue.
@override final  TrailManifestFiche? fiche;

/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrailManifestEntryCopyWith<_TrailManifestEntry> get copyWith => __$TrailManifestEntryCopyWithImpl<_TrailManifestEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrailManifestEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrailManifestEntry&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.dataVersion, dataVersion) || other.dataVersion == dataVersion)&&(identical(other.hash, hash) || other.hash == hash)&&(identical(other.filePath, filePath) || other.filePath == filePath)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastUpdated, lastUpdated) || other.lastUpdated == lastUpdated)&&(identical(other.fiche, fiche) || other.fiche == fiche));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,dataVersion,hash,filePath,fileSize,status,lastUpdated,fiche);

@override
String toString() {
  return 'TrailManifestEntry(trailId: $trailId, dataVersion: $dataVersion, hash: $hash, filePath: $filePath, fileSize: $fileSize, status: $status, lastUpdated: $lastUpdated, fiche: $fiche)';
}


}

/// @nodoc
abstract mixin class _$TrailManifestEntryCopyWith<$Res> implements $TrailManifestEntryCopyWith<$Res> {
  factory _$TrailManifestEntryCopyWith(_TrailManifestEntry value, $Res Function(_TrailManifestEntry) _then) = __$TrailManifestEntryCopyWithImpl;
@override @useResult
$Res call({
 String trailId, int dataVersion, String hash, String filePath, int fileSize, String status, String lastUpdated, TrailManifestFiche? fiche
});


@override $TrailManifestFicheCopyWith<$Res>? get fiche;

}
/// @nodoc
class __$TrailManifestEntryCopyWithImpl<$Res>
    implements _$TrailManifestEntryCopyWith<$Res> {
  __$TrailManifestEntryCopyWithImpl(this._self, this._then);

  final _TrailManifestEntry _self;
  final $Res Function(_TrailManifestEntry) _then;

/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trailId = null,Object? dataVersion = null,Object? hash = null,Object? filePath = null,Object? fileSize = null,Object? status = null,Object? lastUpdated = null,Object? fiche = freezed,}) {
  return _then(_TrailManifestEntry(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,dataVersion: null == dataVersion ? _self.dataVersion : dataVersion // ignore: cast_nullable_to_non_nullable
as int,hash: null == hash ? _self.hash : hash // ignore: cast_nullable_to_non_nullable
as String,filePath: null == filePath ? _self.filePath : filePath // ignore: cast_nullable_to_non_nullable
as String,fileSize: null == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,lastUpdated: null == lastUpdated ? _self.lastUpdated : lastUpdated // ignore: cast_nullable_to_non_nullable
as String,fiche: freezed == fiche ? _self.fiche : fiche // ignore: cast_nullable_to_non_nullable
as TrailManifestFiche?,
  ));
}

/// Create a copy of TrailManifestEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrailManifestFicheCopyWith<$Res>? get fiche {
    if (_self.fiche == null) {
    return null;
  }

  return $TrailManifestFicheCopyWith<$Res>(_self.fiche!, (value) {
    return _then(_self.copyWith(fiche: value));
  });
}
}


/// @nodoc
mixin _$TrailManifestFiche {

/// Nom technique court (ex: 'GR10').
 String get name;/// Nom d affichage, celui que le randonneur lit (ex: 'Mare a Mare Centre').
 String get displayName;/// Accroche sous le nom.
 String get tagline;/// Region geographique (ex: 'Corse', 'Pyrenees').
 String get region;/// Pays.
 String get country;/// Nombre total d etapes.
 int get totalStages;/// Distance totale en kilometres.
 double get totalDistanceKm;/// Denivele positif total en metres.
 int get totalElevationGain;/// Couleur primaire du theme (valeur int d un Color). Null = defaut moteur.
 int? get primaryColorValue;/// Couleur secondaire du theme. Null = defaut moteur.
 int? get secondaryColorValue;/// PRIX du sentier EN ETAPES. Null = non declare (cf. `sentier_distant.dart`).
///
/// `0` declare un SENTIER GRATUIT, et c est une decision de modele
/// economique prise a distance : Christophe peut ouvrir un sentier gratuit
/// sans republier l application. La regle de publicite en decoule sans
/// exception nouvelle (#99404 : rien de paye => niveau gratuit).
 int? get priceStages;/// Directions de parcours possibles (ex: ['NS', 'SN']). Null = defaut.
 List<String>? get directions;/// Durees proposees pour le planning, en jours. Null = defaut.
 List<int>? get availableDurations;/// Duree par defaut suggeree, en jours. Null = defaut.
 int? get defaultDuration;/// Numeros de secours REGIONAUX du sentier. Le 112 est universel et gere
/// par le moteur : ne pas le mettre ici.
 List<FicheNumeroSecours>? get emergencyNumbers;/// URL de la politique de confidentialite du sentier.
 String? get privacyPolicyUrl;
/// Create a copy of TrailManifestFiche
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrailManifestFicheCopyWith<TrailManifestFiche> get copyWith => _$TrailManifestFicheCopyWithImpl<TrailManifestFiche>(this as TrailManifestFiche, _$identity);

  /// Serializes this TrailManifestFiche to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrailManifestFiche&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.totalStages, totalStages) || other.totalStages == totalStages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.primaryColorValue, primaryColorValue) || other.primaryColorValue == primaryColorValue)&&(identical(other.secondaryColorValue, secondaryColorValue) || other.secondaryColorValue == secondaryColorValue)&&(identical(other.priceStages, priceStages) || other.priceStages == priceStages)&&const DeepCollectionEquality().equals(other.directions, directions)&&const DeepCollectionEquality().equals(other.availableDurations, availableDurations)&&(identical(other.defaultDuration, defaultDuration) || other.defaultDuration == defaultDuration)&&const DeepCollectionEquality().equals(other.emergencyNumbers, emergencyNumbers)&&(identical(other.privacyPolicyUrl, privacyPolicyUrl) || other.privacyPolicyUrl == privacyPolicyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,displayName,tagline,region,country,totalStages,totalDistanceKm,totalElevationGain,primaryColorValue,secondaryColorValue,priceStages,const DeepCollectionEquality().hash(directions),const DeepCollectionEquality().hash(availableDurations),defaultDuration,const DeepCollectionEquality().hash(emergencyNumbers),privacyPolicyUrl);

@override
String toString() {
  return 'TrailManifestFiche(name: $name, displayName: $displayName, tagline: $tagline, region: $region, country: $country, totalStages: $totalStages, totalDistanceKm: $totalDistanceKm, totalElevationGain: $totalElevationGain, primaryColorValue: $primaryColorValue, secondaryColorValue: $secondaryColorValue, priceStages: $priceStages, directions: $directions, availableDurations: $availableDurations, defaultDuration: $defaultDuration, emergencyNumbers: $emergencyNumbers, privacyPolicyUrl: $privacyPolicyUrl)';
}


}

/// @nodoc
abstract mixin class $TrailManifestFicheCopyWith<$Res>  {
  factory $TrailManifestFicheCopyWith(TrailManifestFiche value, $Res Function(TrailManifestFiche) _then) = _$TrailManifestFicheCopyWithImpl;
@useResult
$Res call({
 String name, String displayName, String tagline, String region, String country, int totalStages, double totalDistanceKm, int totalElevationGain, int? primaryColorValue, int? secondaryColorValue, int? priceStages, List<String>? directions, List<int>? availableDurations, int? defaultDuration, List<FicheNumeroSecours>? emergencyNumbers, String? privacyPolicyUrl
});




}
/// @nodoc
class _$TrailManifestFicheCopyWithImpl<$Res>
    implements $TrailManifestFicheCopyWith<$Res> {
  _$TrailManifestFicheCopyWithImpl(this._self, this._then);

  final TrailManifestFiche _self;
  final $Res Function(TrailManifestFiche) _then;

/// Create a copy of TrailManifestFiche
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? displayName = null,Object? tagline = null,Object? region = null,Object? country = null,Object? totalStages = null,Object? totalDistanceKm = null,Object? totalElevationGain = null,Object? primaryColorValue = freezed,Object? secondaryColorValue = freezed,Object? priceStages = freezed,Object? directions = freezed,Object? availableDurations = freezed,Object? defaultDuration = freezed,Object? emergencyNumbers = freezed,Object? privacyPolicyUrl = freezed,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,totalStages: null == totalStages ? _self.totalStages : totalStages // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,primaryColorValue: freezed == primaryColorValue ? _self.primaryColorValue : primaryColorValue // ignore: cast_nullable_to_non_nullable
as int?,secondaryColorValue: freezed == secondaryColorValue ? _self.secondaryColorValue : secondaryColorValue // ignore: cast_nullable_to_non_nullable
as int?,priceStages: freezed == priceStages ? _self.priceStages : priceStages // ignore: cast_nullable_to_non_nullable
as int?,directions: freezed == directions ? _self.directions : directions // ignore: cast_nullable_to_non_nullable
as List<String>?,availableDurations: freezed == availableDurations ? _self.availableDurations : availableDurations // ignore: cast_nullable_to_non_nullable
as List<int>?,defaultDuration: freezed == defaultDuration ? _self.defaultDuration : defaultDuration // ignore: cast_nullable_to_non_nullable
as int?,emergencyNumbers: freezed == emergencyNumbers ? _self.emergencyNumbers : emergencyNumbers // ignore: cast_nullable_to_non_nullable
as List<FicheNumeroSecours>?,privacyPolicyUrl: freezed == privacyPolicyUrl ? _self.privacyPolicyUrl : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrailManifestFiche].
extension TrailManifestFichePatterns on TrailManifestFiche {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrailManifestFiche value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrailManifestFiche() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrailManifestFiche value)  $default,){
final _that = this;
switch (_that) {
case _TrailManifestFiche():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrailManifestFiche value)?  $default,){
final _that = this;
switch (_that) {
case _TrailManifestFiche() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String displayName,  String tagline,  String region,  String country,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  int? primaryColorValue,  int? secondaryColorValue,  int? priceStages,  List<String>? directions,  List<int>? availableDurations,  int? defaultDuration,  List<FicheNumeroSecours>? emergencyNumbers,  String? privacyPolicyUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrailManifestFiche() when $default != null:
return $default(_that.name,_that.displayName,_that.tagline,_that.region,_that.country,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.primaryColorValue,_that.secondaryColorValue,_that.priceStages,_that.directions,_that.availableDurations,_that.defaultDuration,_that.emergencyNumbers,_that.privacyPolicyUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String displayName,  String tagline,  String region,  String country,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  int? primaryColorValue,  int? secondaryColorValue,  int? priceStages,  List<String>? directions,  List<int>? availableDurations,  int? defaultDuration,  List<FicheNumeroSecours>? emergencyNumbers,  String? privacyPolicyUrl)  $default,) {final _that = this;
switch (_that) {
case _TrailManifestFiche():
return $default(_that.name,_that.displayName,_that.tagline,_that.region,_that.country,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.primaryColorValue,_that.secondaryColorValue,_that.priceStages,_that.directions,_that.availableDurations,_that.defaultDuration,_that.emergencyNumbers,_that.privacyPolicyUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String displayName,  String tagline,  String region,  String country,  int totalStages,  double totalDistanceKm,  int totalElevationGain,  int? primaryColorValue,  int? secondaryColorValue,  int? priceStages,  List<String>? directions,  List<int>? availableDurations,  int? defaultDuration,  List<FicheNumeroSecours>? emergencyNumbers,  String? privacyPolicyUrl)?  $default,) {final _that = this;
switch (_that) {
case _TrailManifestFiche() when $default != null:
return $default(_that.name,_that.displayName,_that.tagline,_that.region,_that.country,_that.totalStages,_that.totalDistanceKm,_that.totalElevationGain,_that.primaryColorValue,_that.secondaryColorValue,_that.priceStages,_that.directions,_that.availableDurations,_that.defaultDuration,_that.emergencyNumbers,_that.privacyPolicyUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrailManifestFiche implements TrailManifestFiche {
  const _TrailManifestFiche({required this.name, required this.displayName, required this.tagline, required this.region, required this.country, required this.totalStages, required this.totalDistanceKm, required this.totalElevationGain, this.primaryColorValue, this.secondaryColorValue, this.priceStages, final  List<String>? directions, final  List<int>? availableDurations, this.defaultDuration, final  List<FicheNumeroSecours>? emergencyNumbers, this.privacyPolicyUrl}): _directions = directions,_availableDurations = availableDurations,_emergencyNumbers = emergencyNumbers;
  factory _TrailManifestFiche.fromJson(Map<String, dynamic> json) => _$TrailManifestFicheFromJson(json);

/// Nom technique court (ex: 'GR10').
@override final  String name;
/// Nom d affichage, celui que le randonneur lit (ex: 'Mare a Mare Centre').
@override final  String displayName;
/// Accroche sous le nom.
@override final  String tagline;
/// Region geographique (ex: 'Corse', 'Pyrenees').
@override final  String region;
/// Pays.
@override final  String country;
/// Nombre total d etapes.
@override final  int totalStages;
/// Distance totale en kilometres.
@override final  double totalDistanceKm;
/// Denivele positif total en metres.
@override final  int totalElevationGain;
/// Couleur primaire du theme (valeur int d un Color). Null = defaut moteur.
@override final  int? primaryColorValue;
/// Couleur secondaire du theme. Null = defaut moteur.
@override final  int? secondaryColorValue;
/// PRIX du sentier EN ETAPES. Null = non declare (cf. `sentier_distant.dart`).
///
/// `0` declare un SENTIER GRATUIT, et c est une decision de modele
/// economique prise a distance : Christophe peut ouvrir un sentier gratuit
/// sans republier l application. La regle de publicite en decoule sans
/// exception nouvelle (#99404 : rien de paye => niveau gratuit).
@override final  int? priceStages;
/// Directions de parcours possibles (ex: ['NS', 'SN']). Null = defaut.
 final  List<String>? _directions;
/// Directions de parcours possibles (ex: ['NS', 'SN']). Null = defaut.
@override List<String>? get directions {
  final value = _directions;
  if (value == null) return null;
  if (_directions is EqualUnmodifiableListView) return _directions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Durees proposees pour le planning, en jours. Null = defaut.
 final  List<int>? _availableDurations;
/// Durees proposees pour le planning, en jours. Null = defaut.
@override List<int>? get availableDurations {
  final value = _availableDurations;
  if (value == null) return null;
  if (_availableDurations is EqualUnmodifiableListView) return _availableDurations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Duree par defaut suggeree, en jours. Null = defaut.
@override final  int? defaultDuration;
/// Numeros de secours REGIONAUX du sentier. Le 112 est universel et gere
/// par le moteur : ne pas le mettre ici.
 final  List<FicheNumeroSecours>? _emergencyNumbers;
/// Numeros de secours REGIONAUX du sentier. Le 112 est universel et gere
/// par le moteur : ne pas le mettre ici.
@override List<FicheNumeroSecours>? get emergencyNumbers {
  final value = _emergencyNumbers;
  if (value == null) return null;
  if (_emergencyNumbers is EqualUnmodifiableListView) return _emergencyNumbers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// URL de la politique de confidentialite du sentier.
@override final  String? privacyPolicyUrl;

/// Create a copy of TrailManifestFiche
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrailManifestFicheCopyWith<_TrailManifestFiche> get copyWith => __$TrailManifestFicheCopyWithImpl<_TrailManifestFiche>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrailManifestFicheToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrailManifestFiche&&(identical(other.name, name) || other.name == name)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.tagline, tagline) || other.tagline == tagline)&&(identical(other.region, region) || other.region == region)&&(identical(other.country, country) || other.country == country)&&(identical(other.totalStages, totalStages) || other.totalStages == totalStages)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalElevationGain, totalElevationGain) || other.totalElevationGain == totalElevationGain)&&(identical(other.primaryColorValue, primaryColorValue) || other.primaryColorValue == primaryColorValue)&&(identical(other.secondaryColorValue, secondaryColorValue) || other.secondaryColorValue == secondaryColorValue)&&(identical(other.priceStages, priceStages) || other.priceStages == priceStages)&&const DeepCollectionEquality().equals(other._directions, _directions)&&const DeepCollectionEquality().equals(other._availableDurations, _availableDurations)&&(identical(other.defaultDuration, defaultDuration) || other.defaultDuration == defaultDuration)&&const DeepCollectionEquality().equals(other._emergencyNumbers, _emergencyNumbers)&&(identical(other.privacyPolicyUrl, privacyPolicyUrl) || other.privacyPolicyUrl == privacyPolicyUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,displayName,tagline,region,country,totalStages,totalDistanceKm,totalElevationGain,primaryColorValue,secondaryColorValue,priceStages,const DeepCollectionEquality().hash(_directions),const DeepCollectionEquality().hash(_availableDurations),defaultDuration,const DeepCollectionEquality().hash(_emergencyNumbers),privacyPolicyUrl);

@override
String toString() {
  return 'TrailManifestFiche(name: $name, displayName: $displayName, tagline: $tagline, region: $region, country: $country, totalStages: $totalStages, totalDistanceKm: $totalDistanceKm, totalElevationGain: $totalElevationGain, primaryColorValue: $primaryColorValue, secondaryColorValue: $secondaryColorValue, priceStages: $priceStages, directions: $directions, availableDurations: $availableDurations, defaultDuration: $defaultDuration, emergencyNumbers: $emergencyNumbers, privacyPolicyUrl: $privacyPolicyUrl)';
}


}

/// @nodoc
abstract mixin class _$TrailManifestFicheCopyWith<$Res> implements $TrailManifestFicheCopyWith<$Res> {
  factory _$TrailManifestFicheCopyWith(_TrailManifestFiche value, $Res Function(_TrailManifestFiche) _then) = __$TrailManifestFicheCopyWithImpl;
@override @useResult
$Res call({
 String name, String displayName, String tagline, String region, String country, int totalStages, double totalDistanceKm, int totalElevationGain, int? primaryColorValue, int? secondaryColorValue, int? priceStages, List<String>? directions, List<int>? availableDurations, int? defaultDuration, List<FicheNumeroSecours>? emergencyNumbers, String? privacyPolicyUrl
});




}
/// @nodoc
class __$TrailManifestFicheCopyWithImpl<$Res>
    implements _$TrailManifestFicheCopyWith<$Res> {
  __$TrailManifestFicheCopyWithImpl(this._self, this._then);

  final _TrailManifestFiche _self;
  final $Res Function(_TrailManifestFiche) _then;

/// Create a copy of TrailManifestFiche
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? displayName = null,Object? tagline = null,Object? region = null,Object? country = null,Object? totalStages = null,Object? totalDistanceKm = null,Object? totalElevationGain = null,Object? primaryColorValue = freezed,Object? secondaryColorValue = freezed,Object? priceStages = freezed,Object? directions = freezed,Object? availableDurations = freezed,Object? defaultDuration = freezed,Object? emergencyNumbers = freezed,Object? privacyPolicyUrl = freezed,}) {
  return _then(_TrailManifestFiche(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,tagline: null == tagline ? _self.tagline : tagline // ignore: cast_nullable_to_non_nullable
as String,region: null == region ? _self.region : region // ignore: cast_nullable_to_non_nullable
as String,country: null == country ? _self.country : country // ignore: cast_nullable_to_non_nullable
as String,totalStages: null == totalStages ? _self.totalStages : totalStages // ignore: cast_nullable_to_non_nullable
as int,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalElevationGain: null == totalElevationGain ? _self.totalElevationGain : totalElevationGain // ignore: cast_nullable_to_non_nullable
as int,primaryColorValue: freezed == primaryColorValue ? _self.primaryColorValue : primaryColorValue // ignore: cast_nullable_to_non_nullable
as int?,secondaryColorValue: freezed == secondaryColorValue ? _self.secondaryColorValue : secondaryColorValue // ignore: cast_nullable_to_non_nullable
as int?,priceStages: freezed == priceStages ? _self.priceStages : priceStages // ignore: cast_nullable_to_non_nullable
as int?,directions: freezed == directions ? _self._directions : directions // ignore: cast_nullable_to_non_nullable
as List<String>?,availableDurations: freezed == availableDurations ? _self._availableDurations : availableDurations // ignore: cast_nullable_to_non_nullable
as List<int>?,defaultDuration: freezed == defaultDuration ? _self.defaultDuration : defaultDuration // ignore: cast_nullable_to_non_nullable
as int?,emergencyNumbers: freezed == emergencyNumbers ? _self._emergencyNumbers : emergencyNumbers // ignore: cast_nullable_to_non_nullable
as List<FicheNumeroSecours>?,privacyPolicyUrl: freezed == privacyPolicyUrl ? _self.privacyPolicyUrl : privacyPolicyUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$FicheNumeroSecours {

/// Nom affiche du service de secours.
 String get name;/// Numero de telephone.
 String get phone;
/// Create a copy of FicheNumeroSecours
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FicheNumeroSecoursCopyWith<FicheNumeroSecours> get copyWith => _$FicheNumeroSecoursCopyWithImpl<FicheNumeroSecours>(this as FicheNumeroSecours, _$identity);

  /// Serializes this FicheNumeroSecours to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FicheNumeroSecours&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone);

@override
String toString() {
  return 'FicheNumeroSecours(name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $FicheNumeroSecoursCopyWith<$Res>  {
  factory $FicheNumeroSecoursCopyWith(FicheNumeroSecours value, $Res Function(FicheNumeroSecours) _then) = _$FicheNumeroSecoursCopyWithImpl;
@useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class _$FicheNumeroSecoursCopyWithImpl<$Res>
    implements $FicheNumeroSecoursCopyWith<$Res> {
  _$FicheNumeroSecoursCopyWithImpl(this._self, this._then);

  final FicheNumeroSecours _self;
  final $Res Function(FicheNumeroSecours) _then;

/// Create a copy of FicheNumeroSecours
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? phone = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FicheNumeroSecours].
extension FicheNumeroSecoursPatterns on FicheNumeroSecours {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FicheNumeroSecours value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FicheNumeroSecours() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FicheNumeroSecours value)  $default,){
final _that = this;
switch (_that) {
case _FicheNumeroSecours():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FicheNumeroSecours value)?  $default,){
final _that = this;
switch (_that) {
case _FicheNumeroSecours() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FicheNumeroSecours() when $default != null:
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String phone)  $default,) {final _that = this;
switch (_that) {
case _FicheNumeroSecours():
return $default(_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String phone)?  $default,) {final _that = this;
switch (_that) {
case _FicheNumeroSecours() when $default != null:
return $default(_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FicheNumeroSecours implements FicheNumeroSecours {
  const _FicheNumeroSecours({required this.name, required this.phone});
  factory _FicheNumeroSecours.fromJson(Map<String, dynamic> json) => _$FicheNumeroSecoursFromJson(json);

/// Nom affiche du service de secours.
@override final  String name;
/// Numero de telephone.
@override final  String phone;

/// Create a copy of FicheNumeroSecours
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FicheNumeroSecoursCopyWith<_FicheNumeroSecours> get copyWith => __$FicheNumeroSecoursCopyWithImpl<_FicheNumeroSecours>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FicheNumeroSecoursToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FicheNumeroSecours&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,phone);

@override
String toString() {
  return 'FicheNumeroSecours(name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$FicheNumeroSecoursCopyWith<$Res> implements $FicheNumeroSecoursCopyWith<$Res> {
  factory _$FicheNumeroSecoursCopyWith(_FicheNumeroSecours value, $Res Function(_FicheNumeroSecours) _then) = __$FicheNumeroSecoursCopyWithImpl;
@override @useResult
$Res call({
 String name, String phone
});




}
/// @nodoc
class __$FicheNumeroSecoursCopyWithImpl<$Res>
    implements _$FicheNumeroSecoursCopyWith<$Res> {
  __$FicheNumeroSecoursCopyWithImpl(this._self, this._then);

  final _FicheNumeroSecours _self;
  final $Res Function(_FicheNumeroSecours) _then;

/// Create a copy of FicheNumeroSecours
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? phone = null,}) {
  return _then(_FicheNumeroSecours(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
