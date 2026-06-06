// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'journal_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JournalEntryModel {

/// Cle primaire DB (0 si pas encore insere)
 int get id;/// Identifiant du sentier parent (ex: 'gr10')
 String get trailId;/// Numero de l'etape associee (1-indexed)
 int get stageNumber;/// Contenu textuel de la note
 String get text;/// Chemin local de la photo (null si note sans photo)
 String? get photoPath;/// Taille de la photo en octets (null si pas de photo)
 int? get photoSizeBytes;/// Date de creation de l'entree
 DateTime get createdAt;/// Date de derniere modification (null si jamais modifiee)
 DateTime? get updatedAt;
/// Create a copy of JournalEntryModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JournalEntryModelCopyWith<JournalEntryModel> get copyWith => _$JournalEntryModelCopyWithImpl<JournalEntryModel>(this as JournalEntryModel, _$identity);

  /// Serializes this JournalEntryModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JournalEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.text, text) || other.text == text)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.photoSizeBytes, photoSizeBytes) || other.photoSizeBytes == photoSizeBytes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,stageNumber,text,photoPath,photoSizeBytes,createdAt,updatedAt);

@override
String toString() {
  return 'JournalEntryModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, text: $text, photoPath: $photoPath, photoSizeBytes: $photoSizeBytes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $JournalEntryModelCopyWith<$Res>  {
  factory $JournalEntryModelCopyWith(JournalEntryModel value, $Res Function(JournalEntryModel) _then) = _$JournalEntryModelCopyWithImpl;
@useResult
$Res call({
 int id, String trailId, int stageNumber, String text, String? photoPath, int? photoSizeBytes, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$JournalEntryModelCopyWithImpl<$Res>
    implements $JournalEntryModelCopyWith<$Res> {
  _$JournalEntryModelCopyWithImpl(this._self, this._then);

  final JournalEntryModel _self;
  final $Res Function(JournalEntryModel) _then;

/// Create a copy of JournalEntryModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? trailId = null,Object? stageNumber = null,Object? text = null,Object? photoPath = freezed,Object? photoSizeBytes = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,photoSizeBytes: freezed == photoSizeBytes ? _self.photoSizeBytes : photoSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JournalEntryModel].
extension JournalEntryModelPatterns on JournalEntryModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JournalEntryModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JournalEntryModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JournalEntryModel value)  $default,){
final _that = this;
switch (_that) {
case _JournalEntryModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JournalEntryModel value)?  $default,){
final _that = this;
switch (_that) {
case _JournalEntryModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String trailId,  int stageNumber,  String text,  String? photoPath,  int? photoSizeBytes,  DateTime createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JournalEntryModel() when $default != null:
return $default(_that.id,_that.trailId,_that.stageNumber,_that.text,_that.photoPath,_that.photoSizeBytes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String trailId,  int stageNumber,  String text,  String? photoPath,  int? photoSizeBytes,  DateTime createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _JournalEntryModel():
return $default(_that.id,_that.trailId,_that.stageNumber,_that.text,_that.photoPath,_that.photoSizeBytes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String trailId,  int stageNumber,  String text,  String? photoPath,  int? photoSizeBytes,  DateTime createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _JournalEntryModel() when $default != null:
return $default(_that.id,_that.trailId,_that.stageNumber,_that.text,_that.photoPath,_that.photoSizeBytes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JournalEntryModel extends JournalEntryModel {
  const _JournalEntryModel({this.id = 0, required this.trailId, required this.stageNumber, this.text = '', this.photoPath, this.photoSizeBytes, required this.createdAt, this.updatedAt}): super._();
  factory _JournalEntryModel.fromJson(Map<String, dynamic> json) => _$JournalEntryModelFromJson(json);

/// Cle primaire DB (0 si pas encore insere)
@override@JsonKey() final  int id;
/// Identifiant du sentier parent (ex: 'gr10')
@override final  String trailId;
/// Numero de l'etape associee (1-indexed)
@override final  int stageNumber;
/// Contenu textuel de la note
@override@JsonKey() final  String text;
/// Chemin local de la photo (null si note sans photo)
@override final  String? photoPath;
/// Taille de la photo en octets (null si pas de photo)
@override final  int? photoSizeBytes;
/// Date de creation de l'entree
@override final  DateTime createdAt;
/// Date de derniere modification (null si jamais modifiee)
@override final  DateTime? updatedAt;

/// Create a copy of JournalEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JournalEntryModelCopyWith<_JournalEntryModel> get copyWith => __$JournalEntryModelCopyWithImpl<_JournalEntryModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JournalEntryModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JournalEntryModel&&(identical(other.id, id) || other.id == id)&&(identical(other.trailId, trailId) || other.trailId == trailId)&&(identical(other.stageNumber, stageNumber) || other.stageNumber == stageNumber)&&(identical(other.text, text) || other.text == text)&&(identical(other.photoPath, photoPath) || other.photoPath == photoPath)&&(identical(other.photoSizeBytes, photoSizeBytes) || other.photoSizeBytes == photoSizeBytes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,trailId,stageNumber,text,photoPath,photoSizeBytes,createdAt,updatedAt);

@override
String toString() {
  return 'JournalEntryModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, text: $text, photoPath: $photoPath, photoSizeBytes: $photoSizeBytes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$JournalEntryModelCopyWith<$Res> implements $JournalEntryModelCopyWith<$Res> {
  factory _$JournalEntryModelCopyWith(_JournalEntryModel value, $Res Function(_JournalEntryModel) _then) = __$JournalEntryModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String trailId, int stageNumber, String text, String? photoPath, int? photoSizeBytes, DateTime createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$JournalEntryModelCopyWithImpl<$Res>
    implements _$JournalEntryModelCopyWith<$Res> {
  __$JournalEntryModelCopyWithImpl(this._self, this._then);

  final _JournalEntryModel _self;
  final $Res Function(_JournalEntryModel) _then;

/// Create a copy of JournalEntryModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? trailId = null,Object? stageNumber = null,Object? text = null,Object? photoPath = freezed,Object? photoSizeBytes = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_JournalEntryModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,trailId: null == trailId ? _self.trailId : trailId // ignore: cast_nullable_to_non_nullable
as String,stageNumber: null == stageNumber ? _self.stageNumber : stageNumber // ignore: cast_nullable_to_non_nullable
as int,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,photoPath: freezed == photoPath ? _self.photoPath : photoPath // ignore: cast_nullable_to_non_nullable
as String?,photoSizeBytes: freezed == photoSizeBytes ? _self.photoSizeBytes : photoSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
