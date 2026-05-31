// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feasibility_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeasibilityProfile {
  /// Niveau de forme physique (String extensible, ex: beginner, intermediate, advanced)
  String get fitnessLevel;

  /// Experience de randonnee (String extensible, ex: novice, experienced, expert)
  String get experience;

  /// Distance maximale par jour en km
  double get maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  double get maxHoursPerDay;

  /// True si evaluation de groupe (utilise le pire profil)
  bool get groupMode;

  /// Profils des membres du groupe (null si pas en mode groupe)
  List<FeasibilityProfile>? get groupProfiles;

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FeasibilityProfileCopyWith<FeasibilityProfile> get copyWith =>
      _$FeasibilityProfileCopyWithImpl<FeasibilityProfile>(
          this as FeasibilityProfile, _$identity);

  /// Serializes this FeasibilityProfile to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FeasibilityProfile &&
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
                .equals(other.groupProfiles, groupProfiles));
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
      const DeepCollectionEquality().hash(groupProfiles));

  @override
  String toString() {
    return 'FeasibilityProfile(fitnessLevel: $fitnessLevel, experience: $experience, maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, groupMode: $groupMode, groupProfiles: $groupProfiles)';
  }
}

/// @nodoc
abstract mixin class $FeasibilityProfileCopyWith<$Res> {
  factory $FeasibilityProfileCopyWith(
          FeasibilityProfile value, $Res Function(FeasibilityProfile) _then) =
      _$FeasibilityProfileCopyWithImpl;
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
class _$FeasibilityProfileCopyWithImpl<$Res>
    implements $FeasibilityProfileCopyWith<$Res> {
  _$FeasibilityProfileCopyWithImpl(this._self, this._then);

  final FeasibilityProfile _self;
  final $Res Function(FeasibilityProfile) _then;

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
    return _then(_self.copyWith(
      fitnessLevel: null == fitnessLevel
          ? _self.fitnessLevel
          : fitnessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      experience: null == experience
          ? _self.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as String,
      maxKmPerDay: null == maxKmPerDay
          ? _self.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _self.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      groupMode: null == groupMode
          ? _self.groupMode
          : groupMode // ignore: cast_nullable_to_non_nullable
              as bool,
      groupProfiles: freezed == groupProfiles
          ? _self.groupProfiles
          : groupProfiles // ignore: cast_nullable_to_non_nullable
              as List<FeasibilityProfile>?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FeasibilityProfile].
extension FeasibilityProfilePatterns on FeasibilityProfile {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FeasibilityProfile value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FeasibilityProfile value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FeasibilityProfile value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String fitnessLevel,
            String experience,
            double maxKmPerDay,
            double maxHoursPerDay,
            bool groupMode,
            List<FeasibilityProfile>? groupProfiles)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile() when $default != null:
        return $default(_that.fitnessLevel, _that.experience, _that.maxKmPerDay,
            _that.maxHoursPerDay, _that.groupMode, _that.groupProfiles);
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String fitnessLevel,
            String experience,
            double maxKmPerDay,
            double maxHoursPerDay,
            bool groupMode,
            List<FeasibilityProfile>? groupProfiles)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile():
        return $default(_that.fitnessLevel, _that.experience, _that.maxKmPerDay,
            _that.maxHoursPerDay, _that.groupMode, _that.groupProfiles);
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String fitnessLevel,
            String experience,
            double maxKmPerDay,
            double maxHoursPerDay,
            bool groupMode,
            List<FeasibilityProfile>? groupProfiles)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityProfile() when $default != null:
        return $default(_that.fitnessLevel, _that.experience, _that.maxKmPerDay,
            _that.maxHoursPerDay, _that.groupMode, _that.groupProfiles);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FeasibilityProfile extends FeasibilityProfile {
  const _FeasibilityProfile(
      {required this.fitnessLevel,
      required this.experience,
      required this.maxKmPerDay,
      required this.maxHoursPerDay,
      this.groupMode = false,
      final List<FeasibilityProfile>? groupProfiles})
      : _groupProfiles = groupProfiles,
        super._();
  factory _FeasibilityProfile.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityProfileFromJson(json);

  /// Niveau de forme physique (String extensible, ex: beginner, intermediate, advanced)
  @override
  final String fitnessLevel;

  /// Experience de randonnee (String extensible, ex: novice, experienced, expert)
  @override
  final String experience;

  /// Distance maximale par jour en km
  @override
  final double maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  final double maxHoursPerDay;

  /// True si evaluation de groupe (utilise le pire profil)
  @override
  @JsonKey()
  final bool groupMode;

  /// Profils des membres du groupe (null si pas en mode groupe)
  final List<FeasibilityProfile>? _groupProfiles;

  /// Profils des membres du groupe (null si pas en mode groupe)
  @override
  List<FeasibilityProfile>? get groupProfiles {
    final value = _groupProfiles;
    if (value == null) return null;
    if (_groupProfiles is EqualUnmodifiableListView) return _groupProfiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FeasibilityProfileCopyWith<_FeasibilityProfile> get copyWith =>
      __$FeasibilityProfileCopyWithImpl<_FeasibilityProfile>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FeasibilityProfileToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FeasibilityProfile &&
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

  @override
  String toString() {
    return 'FeasibilityProfile(fitnessLevel: $fitnessLevel, experience: $experience, maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, groupMode: $groupMode, groupProfiles: $groupProfiles)';
  }
}

/// @nodoc
abstract mixin class _$FeasibilityProfileCopyWith<$Res>
    implements $FeasibilityProfileCopyWith<$Res> {
  factory _$FeasibilityProfileCopyWith(
          _FeasibilityProfile value, $Res Function(_FeasibilityProfile) _then) =
      __$FeasibilityProfileCopyWithImpl;
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
class __$FeasibilityProfileCopyWithImpl<$Res>
    implements _$FeasibilityProfileCopyWith<$Res> {
  __$FeasibilityProfileCopyWithImpl(this._self, this._then);

  final _FeasibilityProfile _self;
  final $Res Function(_FeasibilityProfile) _then;

  /// Create a copy of FeasibilityProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? fitnessLevel = null,
    Object? experience = null,
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? groupMode = null,
    Object? groupProfiles = freezed,
  }) {
    return _then(_FeasibilityProfile(
      fitnessLevel: null == fitnessLevel
          ? _self.fitnessLevel
          : fitnessLevel // ignore: cast_nullable_to_non_nullable
              as String,
      experience: null == experience
          ? _self.experience
          : experience // ignore: cast_nullable_to_non_nullable
              as String,
      maxKmPerDay: null == maxKmPerDay
          ? _self.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _self.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      groupMode: null == groupMode
          ? _self.groupMode
          : groupMode // ignore: cast_nullable_to_non_nullable
              as bool,
      groupProfiles: freezed == groupProfiles
          ? _self._groupProfiles
          : groupProfiles // ignore: cast_nullable_to_non_nullable
              as List<FeasibilityProfile>?,
    ));
  }
}

// dart format on
