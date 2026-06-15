// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pack_download_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PackDownloadProgress {

/// Identifiant du pack en cours de telechargement.
 String get packId;/// Statut courant ([PackDownloadStatus]).
 String get status;/// Nombre de fichiers deja recuperes et stockes.
 int get filesDone;/// Nombre total de fichiers a recuperer (= [PackManifest.allRefs].length).
 int get filesTotal;/// Numero de tentative courante (1..maxAttempts) pour le fichier en cours.
 int get attempt;/// Message d'erreur en cas d'echec (null si tout va bien).
 String? get error;
/// Create a copy of PackDownloadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackDownloadProgressCopyWith<PackDownloadProgress> get copyWith => _$PackDownloadProgressCopyWithImpl<PackDownloadProgress>(this as PackDownloadProgress, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackDownloadProgress&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.status, status) || other.status == status)&&(identical(other.filesDone, filesDone) || other.filesDone == filesDone)&&(identical(other.filesTotal, filesTotal) || other.filesTotal == filesTotal)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,packId,status,filesDone,filesTotal,attempt,error);

@override
String toString() {
  return 'PackDownloadProgress(packId: $packId, status: $status, filesDone: $filesDone, filesTotal: $filesTotal, attempt: $attempt, error: $error)';
}


}

/// @nodoc
abstract mixin class $PackDownloadProgressCopyWith<$Res>  {
  factory $PackDownloadProgressCopyWith(PackDownloadProgress value, $Res Function(PackDownloadProgress) _then) = _$PackDownloadProgressCopyWithImpl;
@useResult
$Res call({
 String packId, String status, int filesDone, int filesTotal, int attempt, String? error
});




}
/// @nodoc
class _$PackDownloadProgressCopyWithImpl<$Res>
    implements $PackDownloadProgressCopyWith<$Res> {
  _$PackDownloadProgressCopyWithImpl(this._self, this._then);

  final PackDownloadProgress _self;
  final $Res Function(PackDownloadProgress) _then;

/// Create a copy of PackDownloadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? packId = null,Object? status = null,Object? filesDone = null,Object? filesTotal = null,Object? attempt = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,filesDone: null == filesDone ? _self.filesDone : filesDone // ignore: cast_nullable_to_non_nullable
as int,filesTotal: null == filesTotal ? _self.filesTotal : filesTotal // ignore: cast_nullable_to_non_nullable
as int,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PackDownloadProgress].
extension PackDownloadProgressPatterns on PackDownloadProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackDownloadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackDownloadProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackDownloadProgress value)  $default,){
final _that = this;
switch (_that) {
case _PackDownloadProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackDownloadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _PackDownloadProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String packId,  String status,  int filesDone,  int filesTotal,  int attempt,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackDownloadProgress() when $default != null:
return $default(_that.packId,_that.status,_that.filesDone,_that.filesTotal,_that.attempt,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String packId,  String status,  int filesDone,  int filesTotal,  int attempt,  String? error)  $default,) {final _that = this;
switch (_that) {
case _PackDownloadProgress():
return $default(_that.packId,_that.status,_that.filesDone,_that.filesTotal,_that.attempt,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String packId,  String status,  int filesDone,  int filesTotal,  int attempt,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _PackDownloadProgress() when $default != null:
return $default(_that.packId,_that.status,_that.filesDone,_that.filesTotal,_that.attempt,_that.error);case _:
  return null;

}
}

}

/// @nodoc


class _PackDownloadProgress extends PackDownloadProgress {
  const _PackDownloadProgress({required this.packId, required this.status, required this.filesDone, required this.filesTotal, this.attempt = 1, this.error}): super._();
  

/// Identifiant du pack en cours de telechargement.
@override final  String packId;
/// Statut courant ([PackDownloadStatus]).
@override final  String status;
/// Nombre de fichiers deja recuperes et stockes.
@override final  int filesDone;
/// Nombre total de fichiers a recuperer (= [PackManifest.allRefs].length).
@override final  int filesTotal;
/// Numero de tentative courante (1..maxAttempts) pour le fichier en cours.
@override@JsonKey() final  int attempt;
/// Message d'erreur en cas d'echec (null si tout va bien).
@override final  String? error;

/// Create a copy of PackDownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackDownloadProgressCopyWith<_PackDownloadProgress> get copyWith => __$PackDownloadProgressCopyWithImpl<_PackDownloadProgress>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackDownloadProgress&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.status, status) || other.status == status)&&(identical(other.filesDone, filesDone) || other.filesDone == filesDone)&&(identical(other.filesTotal, filesTotal) || other.filesTotal == filesTotal)&&(identical(other.attempt, attempt) || other.attempt == attempt)&&(identical(other.error, error) || other.error == error));
}


@override
int get hashCode => Object.hash(runtimeType,packId,status,filesDone,filesTotal,attempt,error);

@override
String toString() {
  return 'PackDownloadProgress(packId: $packId, status: $status, filesDone: $filesDone, filesTotal: $filesTotal, attempt: $attempt, error: $error)';
}


}

/// @nodoc
abstract mixin class _$PackDownloadProgressCopyWith<$Res> implements $PackDownloadProgressCopyWith<$Res> {
  factory _$PackDownloadProgressCopyWith(_PackDownloadProgress value, $Res Function(_PackDownloadProgress) _then) = __$PackDownloadProgressCopyWithImpl;
@override @useResult
$Res call({
 String packId, String status, int filesDone, int filesTotal, int attempt, String? error
});




}
/// @nodoc
class __$PackDownloadProgressCopyWithImpl<$Res>
    implements _$PackDownloadProgressCopyWith<$Res> {
  __$PackDownloadProgressCopyWithImpl(this._self, this._then);

  final _PackDownloadProgress _self;
  final $Res Function(_PackDownloadProgress) _then;

/// Create a copy of PackDownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? packId = null,Object? status = null,Object? filesDone = null,Object? filesTotal = null,Object? attempt = null,Object? error = freezed,}) {
  return _then(_PackDownloadProgress(
packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,filesDone: null == filesDone ? _self.filesDone : filesDone // ignore: cast_nullable_to_non_nullable
as int,filesTotal: null == filesTotal ? _self.filesTotal : filesTotal // ignore: cast_nullable_to_non_nullable
as int,attempt: null == attempt ? _self.attempt : attempt // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
