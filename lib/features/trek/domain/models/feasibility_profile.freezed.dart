// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feasibility_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeasibilityProfile _$FeasibilityProfileFromJson(Map<String, dynamic> json) {
  return _FeasibilityProfile.fromJson(json);
}

/// @nodoc
mixin _$FeasibilityProfile {
  /// Niveau de forme physique — String libre, pas enum (#81752)
  /// Valeurs courantes : sedentary, average, fit, athletic
  String get fitnessLevel => throw _privateConstructorUsedError;

  /// Experience de randonnee — String libre, pas enum (#81752)
  /// Valeurs courantes : beginner, intermediate, experienced, expert
  String get experience => throw _privateConstructorUsedError;

  /// Distance maximale par jour en km
  double get maxKmPerDay => throw _privateConstructorUsedError;

  /// Duree maximale de marche par jour en heures
  double get maxHoursPerDay => throw _privateConstructorUsedError;

  /// True si evaluation en mode groupe
  bool get groupMode => throw _privateConstructorUsedError;

  /// Profils des membres du groupe (null si solo)
  List<FeasibilityProfile>? get groupProfiles =>
      throw _privateConstructorUsedError;

  /// Serializes this FeasibilityProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeasibilityProfileCopyWith<FeasibilityProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeasibilityProfileCopyWith<$Res> {
  factory $FeasibilityProfileCopyWith(
          FeasibilityProfile value, $Res Function(FeasibilityProfile) then) =
      _$FeasibilityProfileCopyWithImpl<$Res, FeasibilityProfile>;
  @useResult
  $Res call(
      {String fitnessLevel,
      String experience,
      double maxKmPerDay,
      double maxHoursPerDay,
      bool groupMode,
      List<FeasibilityProfile>? groupProfiles});
}

/// @nodoc
class _$FeasibilityProfileCopyWithImpl<$Res, $Val extends FeasibilityProfile>
    implements $FeasibilityProfileCopyWith<$Res> {
  _$FeasibilityProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fitnessLevel = null,
    Object? experience = null,
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? groupMode = null,
    Object? groupProfiles = freezed,
  }) {
    return _then(_value.copyWith(
      fitnessLevel: null == fitnessLevel
          ? _value.fitnessLevel
          : fitnessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      experience: null == experience
          ? _value.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as String,
      maxKmPerDay: null == maxKmPerDay
          ? _value.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _value.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      groupMode: null == groupMode
          ? _value.groupMode
          : groupMode // ignore: cast_nullable_to_non_nullable
              as bool,
      groupProfiles: freezed == groupProfiles
          ? _value.groupProfiles
          : groupProfiles // ignore: cast_nullable_to_non_nullable
              as List<FeasibilityProfile>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeasibilityProfileImplCopyWith<$Res>
    implements $FeasibilityProfileCopyWith<$Res> {
  factory _$$FeasibilityProfileImplCopyWith(_$FeasibilityProfileImpl value,
          $Res Function(_$FeasibilityProfileImpl) then) =
      __$$FeasibilityProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String fitnessLevel,
      String experience,
      double maxKmPerDay,
      double maxHoursPerDay,
      bool groupMode,
      List<FeasibilityProfile>? groupProfiles});
}

/// @nodoc
class __$$FeasibilityProfileImplCopyWithImpl<$Res>
    extends _$FeasibilityProfileCopyWithImpl<$Res, _$FeasibilityProfileImpl>
    implements _$$FeasibilityProfileImplCopyWith<$Res> {
  __$$FeasibilityProfileImplCopyWithImpl(_$FeasibilityProfileImpl _value,
      $Res Function(_$FeasibilityProfileImpl) _then)
      : super(_value, _then);

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fitnessLevel = null,
    Object? experience = null,
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? groupMode = null,
    Object? groupProfiles = freezed,
  }) {
    return _then(_$FeasibilityProfileImpl(
      fitnessLevel: null == fitnessLevel
          ? _value.fitnessLevel
          : fitnessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      experience: null == experience
          ? _value.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as String,
      maxKmPerDay: null == maxKmPerDay
          ? _value.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _value.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      groupMode: null == groupMode
          ? _value.groupMode
          : groupMode // ignore: cast_nullable_to_non_nullable
              as bool,
      groupProfiles: freezed == groupProfiles
          ? _value._groupProfiles
          : groupProfiles // ignore: cast_nullable_to_non_nullable
              as List<FeasibilityProfile>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeasibilityProfileImpl extends _FeasibilityProfile {
  const _$FeasibilityProfileImpl(
      {required this.fitnessLevel,
      required this.experience,
      required this.maxKmPerDay,
      required this.maxHoursPerDay,
      this.groupMode = false,
      final List<FeasibilityProfile>? groupProfiles})
      : _groupProfiles = groupProfiles,
        super._();

  factory _$FeasibilityProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeasibilityProfileImplFromJson(json);

  /// Niveau de forme physique — String libre, pas enum (#81752)
  /// Valeurs courantes : sedentary, average, fit, athletic
  @override
  final String fitnessLevel;

  /// Experience de randonnee — String libre, pas enum (#81752)
  /// Valeurs courantes : beginner, intermediate, experienced, expert
  @override
  final String experience;

  /// Distance maximale par jour en km
  @override
  final double maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  final double maxHoursPerDay;

  /// True si evaluation en mode groupe
  @override
  @JsonKey()
  final bool groupMode;

  /// Profils des membres du groupe (null si solo)
  final List<FeasibilityProfile>? _groupProfiles;

  /// Profils des membres du groupe (null si solo)
  @override
  List<FeasibilityProfile>? get groupProfiles {
    final value = _groupProfiles;
    if (value == null) return null;
    if (_groupProfiles is EqualUnmodifiableListView) return _groupProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'FeasibilityProfile(fitnessLevel: $fitnessLevel, experience: $experience, maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, groupMode: $groupMode, groupProfiles: $groupProfiles)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeasibilityProfileImpl &&
            (identical(other.fitnessLevel, fitnessLevel) ||
                other.fitnessLevel == fitnessLevel) &&
            (identical(other.experience, experience) ||
                other.experience == experience) &&
            (identical(other.maxKmPerDay, maxKmPerDay) ||
                other.maxKmPerDay == maxKmPerDay) &&
            (identical(other.maxHoursPerDay, maxHoursPerDay) ||
                other.maxHoursPerDay == maxHoursPerDay) &&
            (identical(other.groupMode, groupMode) ||
                other.groupMode == groupMode) &&
            const DeepCollectionEquality()
                .equals(other._groupProfiles, _groupProfiles));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      fitnessLevel,
      experience,
      maxKmPerDay,
      maxHoursPerDay,
      groupMode,
      const DeepCollectionEquality().hash(_groupProfiles));

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeasibilityProfileImplCopyWith<_$FeasibilityProfileImpl> get copyWith =>
      __$$FeasibilityProfileImplCopyWithImpl<_$FeasibilityProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeasibilityProfileImplToJson(
      this,
    );
  }
}

abstract class _FeasibilityProfile extends FeasibilityProfile {
  const factory _FeasibilityProfile(
          {required final String fitnessLevel,
          required final String experience,
          required final double maxKmPerDay,
          required final double maxHoursPerDay,
          final bool groupMode,
          final List<FeasibilityProfile>? groupProfiles}) =
      _$FeasibilityProfileImpl;
  const _FeasibilityProfile._() : super._();

  factory _FeasibilityProfile.fromJson(Map<String, dynamic> json) =
      _$FeasibilityProfileImpl.fromJson;

  /// Niveau de forme physique — String libre, pas enum (#81752)
  /// Valeurs courantes : sedentary, average, fit, athletic
  @override
  String get fitnessLevel;

  /// Experience de randonnee — String libre, pas enum (#81752)
  /// Valeurs courantes : beginner, intermediate, experienced, expert
  @override
  String get experience;

  /// Distance maximale par jour en km
  @override
  double get maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  double get maxHoursPerDay;

  /// True si evaluation en mode groupe
  @override
  bool get groupMode;

  /// Profils des membres du groupe (null si solo)
  @override
  List<FeasibilityProfile>? get groupProfiles;

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeasibilityProfileImplCopyWith<_$FeasibilityProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
