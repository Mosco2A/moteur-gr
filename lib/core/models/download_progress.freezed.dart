// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'download_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DownloadProgress {

/// Identifiant du sentier en cours de telechargement
 String get trailId;/// Statut courant du telechargement
 DownloadStatus get status;/// Nombre d'octets telecharges
 int get bytesDownloaded;/// Taille totale en octets (0 si inconnue)
 int get totalBytes;/// Etape courante du pipeline ('downloading', 'trail_meta', 'stages', etc.)
 String get currentStep;/// Message d'erreur en cas de probleme (nullable)
 String? get error;
/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadProgressCopyWith<DownloadProgress> get copyWith => _$DownloadProgressCopyWithImpl<DownloadProgress>(this as DownloadProgress, _$identity);

  /// Serializes this DownloadProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadProgress&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.status, status) || other.status == status)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,status,bytesDownloaded,totalBytes,currentStep,error);

@override
String toString() {
  return 'DownloadProgress(trailId: $trailId, status: $status, bytesDownloaded: $bytesDownloaded, totalBytes: $totalBytes, currentStep: $currentStep, error: $error)';
}


}

/// @nodoc
abstract mixin class $DownloadProgressCopyWith<$Res>  {
  factory $DownloadProgressCopyWith(DownloadProgress value, $Res Function(DownloadProgress) _then) = _$DownloadProgressCopyWithImpl;
@useResult
$Res call({
 String trailId, DownloadStatus status, int bytesDownloaded, int totalBytes, String currentStep, String? error
});




}
/// @nodoc
class _$DownloadProgressCopyWithImpl<$Res>
    implements $DownloadProgressCopyWith<$Res> {
  _$DownloadProgressCopyWithImpl(this._self, this._then);

  final DownloadProgress _self;
  final $Res Function(DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? trailId = null,Object? status = null,Object? bytesDownloaded = null,Object? totalBytes = null,Object? currentStep = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadProgress].
extension DownloadProgressPatterns on DownloadProgress {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadProgress value)  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadProgress value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String trailId,  DownloadStatus status,  int bytesDownloaded,  int totalBytes,  String currentStep,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.trailId,_that.status,_that.bytesDownloaded,_that.totalBytes,_that.currentStep,_that.error);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String trailId,  DownloadStatus status,  int bytesDownloaded,  int totalBytes,  String currentStep,  String? error)  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress():
return $default(_that.trailId,_that.status,_that.bytesDownloaded,_that.totalBytes,_that.currentStep,_that.error);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String trailId,  DownloadStatus status,  int bytesDownloaded,  int totalBytes,  String currentStep,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _DownloadProgress() when $default != null:
return $default(_that.trailId,_that.status,_that.bytesDownloaded,_that.totalBytes,_that.currentStep,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DownloadProgress implements DownloadProgress {
  const _DownloadProgress({required this.trailId, required this.status, required this.bytesDownloaded, required this.totalBytes, required this.currentStep, this.error});
  factory _DownloadProgress.fromJson(Map<String, dynamic> json) => _$DownloadProgressFromJson(json);

/// Identifiant du sentier en cours de telechargement
@override final  String trailId;
/// Statut courant du telechargement
@override final  DownloadStatus status;
/// Nombre d'octets telecharges
@override final  int bytesDownloaded;
/// Taille totale en octets (0 si inconnue)
@override final  int totalBytes;
/// Etape courante du pipeline ('downloading', 'trail_meta', 'stages', etc.)
@override final  String currentStep;
/// Message d'erreur en cas de probleme (nullable)
@override final  String? error;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadProgressCopyWith<_DownloadProgress> get copyWith => __$DownloadProgressCopyWithImpl<_DownloadProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DownloadProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadProgress&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.status, status) || other.status == status)&&(identical(other.bytesDownloaded, bytesDownloaded) || other.bytesDownloaded == bytesDownloaded)&&(identical(other.totalBytes, totalBytes) || other.totalBytes == totalBytes)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,trailId,status,bytesDownloaded,totalBytes,currentStep,error);

@override
String toString() {
  return 'DownloadProgress(trailId: $trailId, status: $status, bytesDownloaded: $bytesDownloaded, totalBytes: $totalBytes, currentStep: $currentStep, error: $error)';
}


}

/// @nodoc
abstract mixin class _$DownloadProgressCopyWith<$Res> implements $DownloadProgressCopyWith<$Res> {
  factory _$DownloadProgressCopyWith(_DownloadProgress value, $Res Function(_DownloadProgress) _then) = __$DownloadProgressCopyWithImpl;
@override @useResult
$Res call({
 String trailId, DownloadStatus status, int bytesDownloaded, int totalBytes, String currentStep, String? error
});




}
/// @nodoc
class __$DownloadProgressCopyWithImpl<$Res>
    implements _$DownloadProgressCopyWith<$Res> {
  __$DownloadProgressCopyWithImpl(this._self, this._then);

  final _DownloadProgress _self;
  final $Res Function(_DownloadProgress) _then;

/// Create a copy of DownloadProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? trailId = null,Object? status = null,Object? bytesDownloaded = null,Object? totalBytes = null,Object? currentStep = null,Object? error = freezed,}) {
  return _then(_DownloadProgress(
trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DownloadStatus,bytesDownloaded: null == bytesDownloaded ? _self.bytesDownloaded : bytesDownloaded // ignore: cast_nullable_to_non_nullable
as int,totalBytes: null == totalBytes ? _self.totalBytes : totalBytes // ignore: cast_nullable_to_non_nullable
as int,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as String,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
