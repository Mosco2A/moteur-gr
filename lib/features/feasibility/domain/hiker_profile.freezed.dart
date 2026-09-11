// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'hiker_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HikerProfile {

/// Age en annees (0 = non renseigne).
 int get age;/// Taille en centimetres (0 = non renseignee).
 int get heightCm;/// Poids en kilogrammes (0 = non renseigne).
 double get weightKg;/// Sexe declare (null = non renseigne / optionnel). Voir [HikerSex].
 String? get sex;/// Code pays ISO 3166-1 alpha-2 (ex. 'FR'). Vide = non renseigne.
 String get countryIso;/// Horodatage de la derniere mise a jour (null si jamais saisi).
 DateTime? get updatedAt;
/// Create a copy of HikerProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HikerProfileCopyWith<HikerProfile> get copyWith => _$HikerProfileCopyWithImpl<HikerProfile>(this as HikerProfile, _$identity);

  /// Serializes this HikerProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HikerProfile&&(identical(other.age, age) || other.age == age)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.countryIso, countryIso) || other.countryIso == countryIso)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,age,heightCm,weightKg,sex,countryIso,updatedAt);

@override
String toString() {
  return 'HikerProfile(age: $age, heightCm: $heightCm, weightKg: $weightKg, sex: $sex, countryIso: $countryIso, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $HikerProfileCopyWith<$Res>  {
  factory $HikerProfileCopyWith(HikerProfile value, $Res Function(HikerProfile) _then) = _$HikerProfileCopyWithImpl;
@useResult
$Res call({
 int age, int heightCm, double weightKg, String? sex, String countryIso, DateTime? updatedAt
});




}
/// @nodoc
class _$HikerProfileCopyWithImpl<$Res>
    implements $HikerProfileCopyWith<$Res> {
  _$HikerProfileCopyWithImpl(this._self, this._then);

  final HikerProfile _self;
  final $Res Function(HikerProfile) _then;

/// Create a copy of HikerProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? age = null,Object? heightCm = null,Object? weightKg = null,Object? sex = freezed,Object? countryIso = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
age: null == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int,heightCm: null == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,countryIso: null == countryIso ? _self.countryIso : countryIso // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [HikerProfile].
extension HikerProfilePatterns on HikerProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HikerProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HikerProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HikerProfile value)  $default,){
final _that = this;
switch (_that) {
case _HikerProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HikerProfile value)?  $default,){
final _that = this;
switch (_that) {
case _HikerProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int age,  int heightCm,  double weightKg,  String? sex,  String countryIso,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HikerProfile() when $default != null:
return $default(_that.age,_that.heightCm,_that.weightKg,_that.sex,_that.countryIso,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int age,  int heightCm,  double weightKg,  String? sex,  String countryIso,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _HikerProfile():
return $default(_that.age,_that.heightCm,_that.weightKg,_that.sex,_that.countryIso,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int age,  int heightCm,  double weightKg,  String? sex,  String countryIso,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _HikerProfile() when $default != null:
return $default(_that.age,_that.heightCm,_that.weightKg,_that.sex,_that.countryIso,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HikerProfile extends HikerProfile {
  const _HikerProfile({this.age = 0, this.heightCm = 0, this.weightKg = 0, this.sex, this.countryIso = '', this.updatedAt}): super._();
  factory _HikerProfile.fromJson(Map<String, dynamic> json) => _$HikerProfileFromJson(json);

/// Age en annees (0 = non renseigne).
@override@JsonKey() final  int age;
/// Taille en centimetres (0 = non renseignee).
@override@JsonKey() final  int heightCm;
/// Poids en kilogrammes (0 = non renseigne).
@override@JsonKey() final  double weightKg;
/// Sexe declare (null = non renseigne / optionnel). Voir [HikerSex].
@override final  String? sex;
/// Code pays ISO 3166-1 alpha-2 (ex. 'FR'). Vide = non renseigne.
@override@JsonKey() final  String countryIso;
/// Horodatage de la derniere mise a jour (null si jamais saisi).
@override final  DateTime? updatedAt;

/// Create a copy of HikerProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HikerProfileCopyWith<_HikerProfile> get copyWith => __$HikerProfileCopyWithImpl<_HikerProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HikerProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HikerProfile&&(identical(other.age, age) || other.age == age)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.sex, sex) || other.sex == sex)&&(identical(other.countryIso, countryIso) || other.countryIso == countryIso)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,age,heightCm,weightKg,sex,countryIso,updatedAt);

@override
String toString() {
  return 'HikerProfile(age: $age, heightCm: $heightCm, weightKg: $weightKg, sex: $sex, countryIso: $countryIso, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$HikerProfileCopyWith<$Res> implements $HikerProfileCopyWith<$Res> {
  factory _$HikerProfileCopyWith(_HikerProfile value, $Res Function(_HikerProfile) _then) = __$HikerProfileCopyWithImpl;
@override @useResult
$Res call({
 int age, int heightCm, double weightKg, String? sex, String countryIso, DateTime? updatedAt
});




}
/// @nodoc
class __$HikerProfileCopyWithImpl<$Res>
    implements _$HikerProfileCopyWith<$Res> {
  __$HikerProfileCopyWithImpl(this._self, this._then);

  final _HikerProfile _self;
  final $Res Function(_HikerProfile) _then;

/// Create a copy of HikerProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? age = null,Object? heightCm = null,Object? weightKg = null,Object? sex = freezed,Object? countryIso = null,Object? updatedAt = freezed,}) {
  return _then(_HikerProfile(
age: null == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int,heightCm: null == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,sex: freezed == sex ? _self.sex : sex // ignore: cast_nullable_to_non_nullable
as String?,countryIso: null == countryIso ? _self.countryIso : countryIso // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
