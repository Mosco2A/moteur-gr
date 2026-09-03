// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checklist_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChecklistItemModel {

/// Cle primaire DB (0 si pas encore insere)
 int get id;/// Identifiant du template source (ex: 'backpack')
 String get templateId;/// Nom de l'item (cle i18n pour resolution via Slang)
 String get name;/// Categorie (ex: 'equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene')
 String get category;/// Item coche ou non par l'utilisateur
 bool get isChecked;/// Poids unitaire en grammes (parite GR20 « Materiel & Sac »). 0 = non pese.
 int get weightGrams;/// Note personnelle optionnelle de l'utilisateur
 String? get customNote;
/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChecklistItemModelCopyWith<ChecklistItemModel> get copyWith => _$ChecklistItemModelCopyWithImpl<ChecklistItemModel>(this as ChecklistItemModel, _$identity);

  /// Serializes this ChecklistItemModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChecklistItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.weightGrams, weightGrams) || other.weightGrams == weightGrams)&&(identical(other.customNote, customNote) || other.customNote == customNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,templateId,name,category,isChecked,weightGrams,customNote);

@override
String toString() {
  return 'ChecklistItemModel(id: $id, templateId: $templateId, name: $name, category: $category, isChecked: $isChecked, weightGrams: $weightGrams, customNote: $customNote)';
}


}

/// @nodoc
abstract mixin class $ChecklistItemModelCopyWith<$Res>  {
  factory $ChecklistItemModelCopyWith(ChecklistItemModel value, $Res Function(ChecklistItemModel) _then) = _$ChecklistItemModelCopyWithImpl;
@useResult
$Res call({
 int id, String templateId, String name, String category, bool isChecked, int weightGrams, String? customNote
});




}
/// @nodoc
class _$ChecklistItemModelCopyWithImpl<$Res>
    implements $ChecklistItemModelCopyWith<$Res> {
  _$ChecklistItemModelCopyWithImpl(this._self, this._then);

  final ChecklistItemModel _self;
  final $Res Function(ChecklistItemModel) _then;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? templateId = null,Object? name = null,Object? category = null,Object? isChecked = null,Object? weightGrams = null,Object? customNote = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,weightGrams: null == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int,customNote: freezed == customNote ? _self.customNote : customNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChecklistItemModel].
extension ChecklistItemModelPatterns on ChecklistItemModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChecklistItemModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChecklistItemModel value)  $default,){
final _that = this;
switch (_that) {
case _ChecklistItemModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChecklistItemModel value)?  $default,){
final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String templateId,  String name,  String category,  bool isChecked,  int weightGrams,  String? customNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
return $default(_that.id,_that.templateId,_that.name,_that.category,_that.isChecked,_that.weightGrams,_that.customNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String templateId,  String name,  String category,  bool isChecked,  int weightGrams,  String? customNote)  $default,) {final _that = this;
switch (_that) {
case _ChecklistItemModel():
return $default(_that.id,_that.templateId,_that.name,_that.category,_that.isChecked,_that.weightGrams,_that.customNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String templateId,  String name,  String category,  bool isChecked,  int weightGrams,  String? customNote)?  $default,) {final _that = this;
switch (_that) {
case _ChecklistItemModel() when $default != null:
return $default(_that.id,_that.templateId,_that.name,_that.category,_that.isChecked,_that.weightGrams,_that.customNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ChecklistItemModel extends ChecklistItemModel {
  const _ChecklistItemModel({this.id = 0, required this.templateId, required this.name, required this.category, this.isChecked = false, this.weightGrams = 0, this.customNote}): super._();
  factory _ChecklistItemModel.fromJson(Map<String, dynamic> json) => _$ChecklistItemModelFromJson(json);

/// Cle primaire DB (0 si pas encore insere)
@override@JsonKey() final  int id;
/// Identifiant du template source (ex: 'backpack')
@override final  String templateId;
/// Nom de l'item (cle i18n pour resolution via Slang)
@override final  String name;
/// Categorie (ex: 'equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene')
@override final  String category;
/// Item coche ou non par l'utilisateur
@override@JsonKey() final  bool isChecked;
/// Poids unitaire en grammes (parite GR20 « Materiel & Sac »). 0 = non pese.
@override@JsonKey() final  int weightGrams;
/// Note personnelle optionnelle de l'utilisateur
@override final  String? customNote;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChecklistItemModelCopyWith<_ChecklistItemModel> get copyWith => __$ChecklistItemModelCopyWithImpl<_ChecklistItemModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChecklistItemModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChecklistItemModel&&(identical(other.id, id) || other.id == id)&&(identical(other.templateId, templateId) || other.templateId == templateId)&&(identical(other.name, name) || other.name == name)&&(identical(other.category, category) || other.category == category)&&(identical(other.isChecked, isChecked) || other.isChecked == isChecked)&&(identical(other.weightGrams, weightGrams) || other.weightGrams == weightGrams)&&(identical(other.customNote, customNote) || other.customNote == customNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,templateId,name,category,isChecked,weightGrams,customNote);

@override
String toString() {
  return 'ChecklistItemModel(id: $id, templateId: $templateId, name: $name, category: $category, isChecked: $isChecked, weightGrams: $weightGrams, customNote: $customNote)';
}


}

/// @nodoc
abstract mixin class _$ChecklistItemModelCopyWith<$Res> implements $ChecklistItemModelCopyWith<$Res> {
  factory _$ChecklistItemModelCopyWith(_ChecklistItemModel value, $Res Function(_ChecklistItemModel) _then) = __$ChecklistItemModelCopyWithImpl;
@override @useResult
$Res call({
 int id, String templateId, String name, String category, bool isChecked, int weightGrams, String? customNote
});




}
/// @nodoc
class __$ChecklistItemModelCopyWithImpl<$Res>
    implements _$ChecklistItemModelCopyWith<$Res> {
  __$ChecklistItemModelCopyWithImpl(this._self, this._then);

  final _ChecklistItemModel _self;
  final $Res Function(_ChecklistItemModel) _then;

/// Create a copy of ChecklistItemModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? templateId = null,Object? name = null,Object? category = null,Object? isChecked = null,Object? weightGrams = null,Object? customNote = freezed,}) {
  return _then(_ChecklistItemModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,templateId: null == templateId ? _self.templateId : templateId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,isChecked: null == isChecked ? _self.isChecked : isChecked // ignore: cast_nullable_to_non_nullable
as bool,weightGrams: null == weightGrams ? _self.weightGrams : weightGrams // ignore: cast_nullable_to_non_nullable
as int,customNote: freezed == customNote ? _self.customNote : customNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
