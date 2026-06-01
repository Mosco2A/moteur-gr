// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personalization_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PersonalizationData {

/// Identifiant unique des donnees de personnalisation
 String get id;/// Identifiant de la commande associee
 String get orderId;/// Nom personnalise (ex: prenom du trekkeur)
 String? get customName;/// Date de trek personnalisee (ex: 'Juin 2026')
 String? get trekDate;/// Nom de l'etape commemoree (ex: 'Vizzavona')
 String? get stageName;/// Texte libre supplementaire
 String? get freeText;/// Chemin vers une image personnalisee uploadee par l'utilisateur
 String? get customImagePath;
/// Create a copy of PersonalizationData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalizationDataCopyWith<PersonalizationData> get copyWith => _$PersonalizationDataCopyWithImpl<PersonalizationData>(this as PersonalizationData, _$identity);

  /// Serializes this PersonalizationData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalizationData&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.customName, customName) || other.customName == customName)&&(identical(other.trekDate, trekDate) || other.trekDate == trekDate)&&(identical(other.stageName, stageName) || other.stageName == stageName)&&(identical(other.freeText, freeText) || other.freeText == freeText)&&(identical(other.customImagePath, customImagePath) || other.customImagePath == customImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,customName,trekDate,stageName,freeText,customImagePath);

@override
String toString() {
  return 'PersonalizationData(id: $id, orderId: $orderId, customName: $customName, trekDate: $trekDate, stageName: $stageName, freeText: $freeText, customImagePath: $customImagePath)';
}


}

/// @nodoc
abstract mixin class $PersonalizationDataCopyWith<$Res>  {
  factory $PersonalizationDataCopyWith(PersonalizationData value, $Res Function(PersonalizationData) _then) = _$PersonalizationDataCopyWithImpl;
@useResult
$Res call({
 String id, String orderId, String? customName, String? trekDate, String? stageName, String? freeText, String? customImagePath
});




}
/// @nodoc
class _$PersonalizationDataCopyWithImpl<$Res>
    implements $PersonalizationDataCopyWith<$Res> {
  _$PersonalizationDataCopyWithImpl(this._self, this._then);

  final PersonalizationData _self;
  final $Res Function(PersonalizationData) _then;

/// Create a copy of PersonalizationData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? customName = freezed,Object? trekDate = freezed,Object? stageName = freezed,Object? freeText = freezed,Object? customImagePath = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,trekDate: freezed == trekDate ? _self.trekDate : trekDate // ignore: cast_nullable_to_non_nullable
as String?,stageName: freezed == stageName ? _self.stageName : stageName // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,customImagePath: freezed == customImagePath ? _self.customImagePath : customImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalizationData].
extension PersonalizationDataPatterns on PersonalizationData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalizationData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalizationData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalizationData value)  $default,){
final _that = this;
switch (_that) {
case _PersonalizationData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalizationData value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalizationData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String orderId,  String? customName,  String? trekDate,  String? stageName,  String? freeText,  String? customImagePath)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalizationData() when $default != null:
return $default(_that.id,_that.orderId,_that.customName,_that.trekDate,_that.stageName,_that.freeText,_that.customImagePath);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String orderId,  String? customName,  String? trekDate,  String? stageName,  String? freeText,  String? customImagePath)  $default,) {final _that = this;
switch (_that) {
case _PersonalizationData():
return $default(_that.id,_that.orderId,_that.customName,_that.trekDate,_that.stageName,_that.freeText,_that.customImagePath);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String orderId,  String? customName,  String? trekDate,  String? stageName,  String? freeText,  String? customImagePath)?  $default,) {final _that = this;
switch (_that) {
case _PersonalizationData() when $default != null:
return $default(_that.id,_that.orderId,_that.customName,_that.trekDate,_that.stageName,_that.freeText,_that.customImagePath);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalizationData extends PersonalizationData {
  const _PersonalizationData({required this.id, required this.orderId, this.customName, this.trekDate, this.stageName, this.freeText, this.customImagePath}): super._();
  factory _PersonalizationData.fromJson(Map<String, dynamic> json) => _$PersonalizationDataFromJson(json);

/// Identifiant unique des donnees de personnalisation
@override final  String id;
/// Identifiant de la commande associee
@override final  String orderId;
/// Nom personnalise (ex: prenom du trekkeur)
@override final  String? customName;
/// Date de trek personnalisee (ex: 'Juin 2026')
@override final  String? trekDate;
/// Nom de l'etape commemoree (ex: 'Vizzavona')
@override final  String? stageName;
/// Texte libre supplementaire
@override final  String? freeText;
/// Chemin vers une image personnalisee uploadee par l'utilisateur
@override final  String? customImagePath;

/// Create a copy of PersonalizationData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalizationDataCopyWith<_PersonalizationData> get copyWith => __$PersonalizationDataCopyWithImpl<_PersonalizationData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalizationDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalizationData&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.customName, customName) || other.customName == customName)&&(identical(other.trekDate, trekDate) || other.trekDate == trekDate)&&(identical(other.stageName, stageName) || other.stageName == stageName)&&(identical(other.freeText, freeText) || other.freeText == freeText)&&(identical(other.customImagePath, customImagePath) || other.customImagePath == customImagePath));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,orderId,customName,trekDate,stageName,freeText,customImagePath);

@override
String toString() {
  return 'PersonalizationData(id: $id, orderId: $orderId, customName: $customName, trekDate: $trekDate, stageName: $stageName, freeText: $freeText, customImagePath: $customImagePath)';
}


}

/// @nodoc
abstract mixin class _$PersonalizationDataCopyWith<$Res> implements $PersonalizationDataCopyWith<$Res> {
  factory _$PersonalizationDataCopyWith(_PersonalizationData value, $Res Function(_PersonalizationData) _then) = __$PersonalizationDataCopyWithImpl;
@override @useResult
$Res call({
 String id, String orderId, String? customName, String? trekDate, String? stageName, String? freeText, String? customImagePath
});




}
/// @nodoc
class __$PersonalizationDataCopyWithImpl<$Res>
    implements _$PersonalizationDataCopyWith<$Res> {
  __$PersonalizationDataCopyWithImpl(this._self, this._then);

  final _PersonalizationData _self;
  final $Res Function(_PersonalizationData) _then;

/// Create a copy of PersonalizationData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? customName = freezed,Object? trekDate = freezed,Object? stageName = freezed,Object? freeText = freezed,Object? customImagePath = freezed,}) {
  return _then(_PersonalizationData(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,trekDate: freezed == trekDate ? _self.trekDate : trekDate // ignore: cast_nullable_to_non_nullable
as String?,stageName: freezed == stageName ? _self.stageName : stageName // ignore: cast_nullable_to_non_nullable
as String?,freeText: freezed == freeText ? _self.freeText : freeText // ignore: cast_nullable_to_non_nullable
as String?,customImagePath: freezed == customImagePath ? _self.customImagePath : customImagePath // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
