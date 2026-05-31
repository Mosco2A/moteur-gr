// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'itinerary_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ItineraryDay {
  /// Numero du jour (1-indexed)
  int get dayNumber;

  /// Liste des etapes prevues ce jour
  List<StageModel> get stages;

  /// Distance totale en km pour ce jour
  double get totalDistance;

  /// Denivele positif total en metres pour ce jour
  int get totalElevation;

  /// Duree estimee en heures
  double get estimatedHours;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ItineraryDayCopyWith<ItineraryDay> get copyWith =>
      _$ItineraryDayCopyWithImpl<ItineraryDay>(
          this as ItineraryDay, _$identity);

  /// Serializes this ItineraryDay to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ItineraryDay &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            const DeepCollectionEquality().equals(other.stages, stages) &&
            (identical(other.totalDistance, totalDistance) ||
                other.totalDistance == totalDistance) &&
            (identical(other.totalElevation, totalElevation) ||
                other.totalElevation == totalElevation) &&
            (identical(other.estimatedHours, estimatedHours) ||
                other.estimatedHours == estimatedHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayNumber,
      const DeepCollectionEquality().hash(stages),
      totalDistance,
      totalElevation,
      estimatedHours);

  @override
  String toString() {
    return 'ItineraryDay(dayNumber: $dayNumber, stages: $stages, totalDistance: $totalDistance, totalElevation: $totalElevation, estimatedHours: $estimatedHours)';
  }
}

/// @nodoc
abstract mixin class $ItineraryDayCopyWith<$Res> {
  factory $ItineraryDayCopyWith(
          ItineraryDay value, $Res Function(ItineraryDay) _then) =
      _$ItineraryDayCopyWithImpl;
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistance,
      int totalElevation,
      double estimatedHours});
}

/// @nodoc
class _$ItineraryDayCopyWithImpl<$Res> implements $ItineraryDayCopyWith<$Res> {
  _$ItineraryDayCopyWithImpl(this._self, this._then);

  final ItineraryDay _self;
  final $Res Function(ItineraryDay) _then;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistance = null,
    Object? totalElevation = null,
    Object? estimatedHours = null,
  }) {
    return _then(_self.copyWith(
      dayNumber: null == dayNumber
          ? _self.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      stages: null == stages
          ? _self.stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageModel>,
      totalDistance: null == totalDistance
          ? _self.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevation: null == totalElevation
          ? _self.totalElevation
          : totalElevation // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedHours: null == estimatedHours
          ? _self.estimatedHours
          : estimatedHours // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [ItineraryDay].
extension ItineraryDayPatterns on ItineraryDay {
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
    TResult Function(_ItineraryDay value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay() when $default != null:
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
    TResult Function(_ItineraryDay value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay():
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
    TResult? Function(_ItineraryDay value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay() when $default != null:
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
    TResult Function(int dayNumber, List<StageModel> stages,
            double totalDistance, int totalElevation, double estimatedHours)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay() when $default != null:
        return $default(_that.dayNumber, _that.stages, _that.totalDistance,
            _that.totalElevation, _that.estimatedHours);
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
    TResult Function(int dayNumber, List<StageModel> stages,
            double totalDistance, int totalElevation, double estimatedHours)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay():
        return $default(_that.dayNumber, _that.stages, _that.totalDistance,
            _that.totalElevation, _that.estimatedHours);
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
    TResult? Function(int dayNumber, List<StageModel> stages,
            double totalDistance, int totalElevation, double estimatedHours)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ItineraryDay() when $default != null:
        return $default(_that.dayNumber, _that.stages, _that.totalDistance,
            _that.totalElevation, _that.estimatedHours);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ItineraryDay extends ItineraryDay {
  const _ItineraryDay(
      {required this.dayNumber,
      required final List<StageModel> stages,
      required this.totalDistance,
      required this.totalElevation,
      required this.estimatedHours})
      : _stages = stages,
        super._();
  factory _ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);

  /// Numero du jour (1-indexed)
  @override
  final int dayNumber;

  /// Liste des etapes prevues ce jour
  final List<StageModel> _stages;

  /// Liste des etapes prevues ce jour
  @override
  List<StageModel> get stages {
    if (_stages is EqualUnmodifiableListView) return _stages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stages);
  }

  /// Distance totale en km pour ce jour
  @override
  final double totalDistance;

  /// Denivele positif total en metres pour ce jour
  @override
  final int totalElevation;

  /// Duree estimee en heures
  @override
  final double estimatedHours;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ItineraryDayCopyWith<_ItineraryDay> get copyWith =>
      __$ItineraryDayCopyWithImpl<_ItineraryDay>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ItineraryDayToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ItineraryDay &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            const DeepCollectionEquality().equals(other._stages, _stages) &&
            (identical(other.totalDistance, totalDistance) ||
                other.totalDistance == totalDistance) &&
            (identical(other.totalElevation, totalElevation) ||
                other.totalElevation == totalElevation) &&
            (identical(other.estimatedHours, estimatedHours) ||
                other.estimatedHours == estimatedHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayNumber,
      const DeepCollectionEquality().hash(_stages),
      totalDistance,
      totalElevation,
      estimatedHours);

  @override
  String toString() {
    return 'ItineraryDay(dayNumber: $dayNumber, stages: $stages, totalDistance: $totalDistance, totalElevation: $totalElevation, estimatedHours: $estimatedHours)';
  }
}

/// @nodoc
abstract mixin class _$ItineraryDayCopyWith<$Res>
    implements $ItineraryDayCopyWith<$Res> {
  factory _$ItineraryDayCopyWith(
          _ItineraryDay value, $Res Function(_ItineraryDay) _then) =
      __$ItineraryDayCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int dayNumber,
      List<StageModel> stages,
      double totalDistance,
      int totalElevation,
      double estimatedHours});
}

/// @nodoc
class __$ItineraryDayCopyWithImpl<$Res>
    implements _$ItineraryDayCopyWith<$Res> {
  __$ItineraryDayCopyWithImpl(this._self, this._then);

  final _ItineraryDay _self;
  final $Res Function(_ItineraryDay) _then;

  /// Create a copy of ItineraryDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayNumber = null,
    Object? stages = null,
    Object? totalDistance = null,
    Object? totalElevation = null,
    Object? estimatedHours = null,
  }) {
    return _then(_ItineraryDay(
      dayNumber: null == dayNumber
          ? _self.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      stages: null == stages
          ? _self._stages
          : stages // ignore: cast_nullable_to_non_nullable
              as List<StageModel>,
      totalDistance: null == totalDistance
          ? _self.totalDistance
          : totalDistance // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevation: null == totalElevation
          ? _self.totalElevation
          : totalElevation // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedHours: null == estimatedHours
          ? _self.estimatedHours
          : estimatedHours // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
