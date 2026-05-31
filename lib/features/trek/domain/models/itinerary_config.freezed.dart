// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItineraryConfig {
  /// Distance maximale par jour en km
  double get maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  double get maxHoursPerDay;

  /// Date de depart prevue
  DateTime get startDate;

  /// Niveau de difficulte (String extensible, ex: easy, moderate, hard)
  String get difficultyLevel;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ItineraryConfigCopyWith<ItineraryConfig> get copyWith =>
      _$ItineraryConfigCopyWithImpl<ItineraryConfig>(
          this as ItineraryConfig, _$identity);

  /// Serializes this ItineraryConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ItineraryConfig &&
            (identical(other.maxKmPerDay, maxKmPerDay) ||
                other.maxKmPerDay == maxKmPerDay) &&
            (identical(other.maxHoursPerDay, maxHoursPerDay) ||
                other.maxHoursPerDay == maxHoursPerDay) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, maxKmPerDay, maxHoursPerDay, startDate, difficultyLevel);

  @override
  String toString() {
    return 'ItineraryConfig(maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, startDate: $startDate, difficultyLevel: $difficultyLevel)';
  }
}

/// @nodoc
abstract mixin class $ItineraryConfigCopyWith<$Res> {
  factory $ItineraryConfigCopyWith(
          ItineraryConfig value, $Res Function(ItineraryConfig) _then) =
      _$ItineraryConfigCopyWithImpl;
  @useResult
  $Res call(
      {double maxKmPerDay,
      double maxHoursPerDay,
      DateTime startDate,
      String difficultyLevel});
}

/// @nodoc
class _$ItineraryConfigCopyWithImpl<$Res>
    implements $ItineraryConfigCopyWith<$Res> {
  _$ItineraryConfigCopyWithImpl(this._self, this._then);

  final ItineraryConfig _self;
  final $Res Function(ItineraryConfig) _then;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? startDate = null,
    Object? difficultyLevel = null,
  }) {
    return _then(_self.copyWith(
      maxKmPerDay: null == maxKmPerDay
          ? _self.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _self.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyLevel: null == difficultyLevel
          ? _self.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [ItineraryConfig].
extension ItineraryConfigPatterns on ItineraryConfig {
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
    TResult Function(_ItineraryConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig() when $default != null:
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
    TResult Function(_ItineraryConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig():
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
    TResult? Function(_ItineraryConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig() when $default != null:
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
    TResult Function(double maxKmPerDay, double maxHoursPerDay,
            DateTime startDate, String difficultyLevel)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig() when $default != null:
        return $default(_that.maxKmPerDay, _that.maxHoursPerDay,
            _that.startDate, _that.difficultyLevel);
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
    TResult Function(double maxKmPerDay, double maxHoursPerDay,
            DateTime startDate, String difficultyLevel)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig():
        return $default(_that.maxKmPerDay, _that.maxHoursPerDay,
            _that.startDate, _that.difficultyLevel);
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
    TResult? Function(double maxKmPerDay, double maxHoursPerDay,
            DateTime startDate, String difficultyLevel)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryConfig() when $default != null:
        return $default(_that.maxKmPerDay, _that.maxHoursPerDay,
            _that.startDate, _that.difficultyLevel);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ItineraryConfig extends ItineraryConfig {
  const _ItineraryConfig(
      {required this.maxKmPerDay,
      required this.maxHoursPerDay,
      required this.startDate,
      required this.difficultyLevel})
      : super._();
  factory _ItineraryConfig.fromJson(Map<String, dynamic> json) =>
      _$ItineraryConfigFromJson(json);

  /// Distance maximale par jour en km
  @override
  final double maxKmPerDay;

  /// Duree maximale de marche par jour en heures
  @override
  final double maxHoursPerDay;

  /// Date de depart prevue
  @override
  final DateTime startDate;

  /// Niveau de difficulte (String extensible, ex: easy, moderate, hard)
  @override
  final String difficultyLevel;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ItineraryConfigCopyWith<_ItineraryConfig> get copyWith =>
      __$ItineraryConfigCopyWithImpl<_ItineraryConfig>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ItineraryConfigToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ItineraryConfig &&
            (identical(other.maxKmPerDay, maxKmPerDay) ||
                other.maxKmPerDay == maxKmPerDay) &&
            (identical(other.maxHoursPerDay, maxHoursPerDay) ||
                other.maxHoursPerDay == maxHoursPerDay) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.difficultyLevel, difficultyLevel) ||
                other.difficultyLevel == difficultyLevel));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, maxKmPerDay, maxHoursPerDay, startDate, difficultyLevel);

  @override
  String toString() {
    return 'ItineraryConfig(maxKmPerDay: $maxKmPerDay, maxHoursPerDay: $maxHoursPerDay, startDate: $startDate, difficultyLevel: $difficultyLevel)';
  }
}

/// @nodoc
abstract mixin class _$ItineraryConfigCopyWith<$Res>
    implements $ItineraryConfigCopyWith<$Res> {
  factory _$ItineraryConfigCopyWith(
          _ItineraryConfig value, $Res Function(_ItineraryConfig) _then) =
      __$ItineraryConfigCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double maxKmPerDay,
      double maxHoursPerDay,
      DateTime startDate,
      String difficultyLevel});
}

/// @nodoc
class __$ItineraryConfigCopyWithImpl<$Res>
    implements _$ItineraryConfigCopyWith<$Res> {
  __$ItineraryConfigCopyWithImpl(this._self, this._then);

  final _ItineraryConfig _self;
  final $Res Function(_ItineraryConfig) _then;

  /// Create a copy of ItineraryConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? maxKmPerDay = null,
    Object? maxHoursPerDay = null,
    Object? startDate = null,
    Object? difficultyLevel = null,
  }) {
    return _then(_ItineraryConfig(
      maxKmPerDay: null == maxKmPerDay
          ? _self.maxKmPerDay
          : maxKmPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      maxHoursPerDay: null == maxHoursPerDay
          ? _self.maxHoursPerDay
          : maxHoursPerDay // ignore: cast_nullable_to_non_nullable
              as double,
      startDate: null == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      difficultyLevel: null == difficultyLevel
          ? _self.difficultyLevel
          : difficultyLevel // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
