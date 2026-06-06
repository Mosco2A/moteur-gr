// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthInfo {

/// Groupe sanguin (ex: 'A+', 'O-', 'AB+').
 String get bloodType;/// Allergies connues (texte libre, ex: 'Penicilline, arachides').
 String get allergies;/// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
 String get treatments;/// Contact du medecin traitant (nom + telephone).
 String get doctorContact;/// Numero d'assurance / mutuelle / carte europeenne.
 String get insuranceNumber;
/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthInfoCopyWith<HealthInfo> get copyWith => _$HealthInfoCopyWithImpl<HealthInfo>(this as HealthInfo, _$identity);

  /// Serializes this HealthInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthInfo&&(identical(other.bloodType, bloodType) || other.bloodType == bloodType)&&(identical(other.allergies, allergies) || other.allergies == allergies)&&(identical(other.treatments, treatments) || other.treatments == treatments)&&(identical(other.doctorContact, doctorContact) || other.doctorContact == doctorContact)&&(identical(other.insuranceNumber, insuranceNumber) || other.insuranceNumber == insuranceNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bloodType,allergies,treatments,doctorContact,insuranceNumber);

@override
String toString() {
  return 'HealthInfo(bloodType: $bloodType, allergies: $allergies, treatments: $treatments, doctorContact: $doctorContact, insuranceNumber: $insuranceNumber)';
}


}

/// @nodoc
abstract mixin class $HealthInfoCopyWith<$Res>  {
  factory $HealthInfoCopyWith(HealthInfo value, $Res Function(HealthInfo) _then) = _$HealthInfoCopyWithImpl;
@useResult
$Res call({
 String bloodType, String allergies, String treatments, String doctorContact, String insuranceNumber
});




}
/// @nodoc
class _$HealthInfoCopyWithImpl<$Res>
    implements $HealthInfoCopyWith<$Res> {
  _$HealthInfoCopyWithImpl(this._self, this._then);

  final HealthInfo _self;
  final $Res Function(HealthInfo) _then;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bloodType = null,Object? allergies = null,Object? treatments = null,Object? doctorContact = null,Object? insuranceNumber = null,}) {
  return _then(_self.copyWith(
bloodType: null == bloodType ? _self.bloodType : bloodType // ignore: cast_nullable_to_non_nullable
as String,allergies: null == allergies ? _self.allergies : allergies // ignore: cast_nullable_to_non_nullable
as String,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as String,doctorContact: null == doctorContact ? _self.doctorContact : doctorContact // ignore: cast_nullable_to_non_nullable
as String,insuranceNumber: null == insuranceNumber ? _self.insuranceNumber : insuranceNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthInfo].
extension HealthInfoPatterns on HealthInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthInfo value)  $default,){
final _that = this;
switch (_that) {
case _HealthInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthInfo value)?  $default,){
final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String bloodType,  String allergies,  String treatments,  String doctorContact,  String insuranceNumber)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
return $default(_that.bloodType,_that.allergies,_that.treatments,_that.doctorContact,_that.insuranceNumber);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String bloodType,  String allergies,  String treatments,  String doctorContact,  String insuranceNumber)  $default,) {final _that = this;
switch (_that) {
case _HealthInfo():
return $default(_that.bloodType,_that.allergies,_that.treatments,_that.doctorContact,_that.insuranceNumber);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String bloodType,  String allergies,  String treatments,  String doctorContact,  String insuranceNumber)?  $default,) {final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
return $default(_that.bloodType,_that.allergies,_that.treatments,_that.doctorContact,_that.insuranceNumber);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthInfo extends HealthInfo {
  const _HealthInfo({this.bloodType = '', this.allergies = '', this.treatments = '', this.doctorContact = '', this.insuranceNumber = ''}): super._();
  factory _HealthInfo.fromJson(Map<String, dynamic> json) => _$HealthInfoFromJson(json);

/// Groupe sanguin (ex: 'A+', 'O-', 'AB+').
@override@JsonKey() final  String bloodType;
/// Allergies connues (texte libre, ex: 'Penicilline, arachides').
@override@JsonKey() final  String allergies;
/// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
@override@JsonKey() final  String treatments;
/// Contact du medecin traitant (nom + telephone).
@override@JsonKey() final  String doctorContact;
/// Numero d'assurance / mutuelle / carte europeenne.
@override@JsonKey() final  String insuranceNumber;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthInfoCopyWith<_HealthInfo> get copyWith => __$HealthInfoCopyWithImpl<_HealthInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthInfo&&(identical(other.bloodType, bloodType) || other.bloodType == bloodType)&&(identical(other.allergies, allergies) || other.allergies == allergies)&&(identical(other.treatments, treatments) || other.treatments == treatments)&&(identical(other.doctorContact, doctorContact) || other.doctorContact == doctorContact)&&(identical(other.insuranceNumber, insuranceNumber) || other.insuranceNumber == insuranceNumber));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,bloodType,allergies,treatments,doctorContact,insuranceNumber);

@override
String toString() {
  return 'HealthInfo(bloodType: $bloodType, allergies: $allergies, treatments: $treatments, doctorContact: $doctorContact, insuranceNumber: $insuranceNumber)';
}


}

/// @nodoc
abstract mixin class _$HealthInfoCopyWith<$Res> implements $HealthInfoCopyWith<$Res> {
  factory _$HealthInfoCopyWith(_HealthInfo value, $Res Function(_HealthInfo) _then) = __$HealthInfoCopyWithImpl;
@override @useResult
$Res call({
 String bloodType, String allergies, String treatments, String doctorContact, String insuranceNumber
});




}
/// @nodoc
class __$HealthInfoCopyWithImpl<$Res>
    implements _$HealthInfoCopyWith<$Res> {
  __$HealthInfoCopyWithImpl(this._self, this._then);

  final _HealthInfo _self;
  final $Res Function(_HealthInfo) _then;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bloodType = null,Object? allergies = null,Object? treatments = null,Object? doctorContact = null,Object? insuranceNumber = null,}) {
  return _then(_HealthInfo(
bloodType: null == bloodType ? _self.bloodType : bloodType // ignore: cast_nullable_to_non_nullable
as String,allergies: null == allergies ? _self.allergies : allergies // ignore: cast_nullable_to_non_nullable
as String,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as String,doctorContact: null == doctorContact ? _self.doctorContact : doctorContact // ignore: cast_nullable_to_non_nullable
as String,insuranceNumber: null == insuranceNumber ? _self.insuranceNumber : insuranceNumber // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
