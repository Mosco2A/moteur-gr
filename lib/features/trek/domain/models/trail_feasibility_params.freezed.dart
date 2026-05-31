// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail_feasibility_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrailFeasibilityParams {
  /// Facteur d'ajustement altitude (1.0 = neutre, >1 = plus difficile)
  double get altitudeFactor;

  /// Facteur d'ajustement technicite (1.0 = neutre)
  double get technicalFactor;

  /// Facteur d'ajustement chaleur (1.0 = neutre)
  double get heatFactor;

  /// Facteur d'ajustement neige (1.0 = neutre)
  double get snowFactor;

  /// Conditions supplementaires personnalisees
  List<String> get customConditions;

  /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
  Map<String, String> get recommendationTemplates;

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrailFeasibilityParamsCopyWith<TrailFeasibilityParams> get copyWith =>
      _$TrailFeasibilityParamsCopyWithImpl<TrailFeasibilityParams>(
          this as TrailFeasibilityParams, _$identity);

  /// Serializes this TrailFeasibilityParams to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrailFeasibilityParams &&
            (identical(other.altitudeFactor, altitudeFactor) ||
                other.altitudeFactor == altitudeFactor) &&
            (identical(other.technicalFactor, technicalFactor) ||
                other.technicalFactor == technicalFactor) &&
            (identical(other.heatFactor, heatFactor) ||
                other.heatFactor == heatFactor) &&
            (identical(other.snowFactor, snowFactor) ||
                other.snowFactor == snowFactor) &&
            const DeepCollectionEquality()
                .equals(other.customConditions, customConditions) &&
            const DeepCollectionEquality().equals(
                other.recommendationTemplates, recommendationTemplates));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      altitudeFactor,
      technicalFactor,
      heatFactor,
      snowFactor,
      const DeepCollectionEquality().hash(customConditions),
      const DeepCollectionEquality().hash(recommendationTemplates));

  @override
  String toString() {
    return 'TrailFeasibilityParams(altitudeFactor: $altitudeFactor, technicalFactor: $technicalFactor, heatFactor: $heatFactor, snowFactor: $snowFactor, customConditions: $customConditions, recommendationTemplates: $recommendationTemplates)';
  }
}

/// @nodoc
abstract mixin class $TrailFeasibilityParamsCopyWith<$Res> {
  factory $TrailFeasibilityParamsCopyWith(TrailFeasibilityParams value,
          $Res Function(TrailFeasibilityParams) _then) =
      _$TrailFeasibilityParamsCopyWithImpl;
  @useResult
  $Res call(
      {double altitudeFactor,
      double technicalFactor,
      double heatFactor,
      double snowFactor,
      List<String> customConditions,
      Map<String, String> recommendationTemplates});
}

/// @nodoc
class _$TrailFeasibilityParamsCopyWithImpl<$Res>
    implements $TrailFeasibilityParamsCopyWith<$Res> {
  _$TrailFeasibilityParamsCopyWithImpl(this._self, this._then);

  final TrailFeasibilityParams _self;
  final $Res Function(TrailFeasibilityParams) _then;

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? altitudeFactor = null,
    Object? technicalFactor = null,
    Object? heatFactor = null,
    Object? snowFactor = null,
    Object? customConditions = null,
    Object? recommendationTemplates = null,
  }) {
    return _then(_self.copyWith(
      altitudeFactor: null == altitudeFactor
          ? _self.altitudeFactor
          : altitudeFactor // ignore: cast_nullable_to_non_nullable
              as double,
      technicalFactor: null == technicalFactor
          ? _self.technicalFactor
          : technicalFactor // ignore: cast_nullable_to_non_nullable
              as double,
      heatFactor: null == heatFactor
          ? _self.heatFactor
          : heatFactor // ignore: cast_nullable_to_non_nullable
              as double,
      snowFactor: null == snowFactor
          ? _self.snowFactor
          : snowFactor // ignore: cast_nullable_to_non_nullable
              as double,
      customConditions: null == customConditions
          ? _self.customConditions
          : customConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      recommendationTemplates: null == recommendationTemplates
          ? _self.recommendationTemplates
          : recommendationTemplates // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrailFeasibilityParams].
extension TrailFeasibilityParamsPatterns on TrailFeasibilityParams {
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
    TResult Function(_TrailFeasibilityParams value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams() when $default != null:
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
    TResult Function(_TrailFeasibilityParams value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams():
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
    TResult? Function(_TrailFeasibilityParams value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams() when $default != null:
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
            double altitudeFactor,
            double technicalFactor,
            double heatFactor,
            double snowFactor,
            List<String> customConditions,
            Map<String, String> recommendationTemplates)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams() when $default != null:
        return $default(
            _that.altitudeFactor,
            _that.technicalFactor,
            _that.heatFactor,
            _that.snowFactor,
            _that.customConditions,
            _that.recommendationTemplates);
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
            double altitudeFactor,
            double technicalFactor,
            double heatFactor,
            double snowFactor,
            List<String> customConditions,
            Map<String, String> recommendationTemplates)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams():
        return $default(
            _that.altitudeFactor,
            _that.technicalFactor,
            _that.heatFactor,
            _that.snowFactor,
            _that.customConditions,
            _that.recommendationTemplates);
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
            double altitudeFactor,
            double technicalFactor,
            double heatFactor,
            double snowFactor,
            List<String> customConditions,
            Map<String, String> recommendationTemplates)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailFeasibilityParams() when $default != null:
        return $default(
            _that.altitudeFactor,
            _that.technicalFactor,
            _that.heatFactor,
            _that.snowFactor,
            _that.customConditions,
            _that.recommendationTemplates);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TrailFeasibilityParams extends TrailFeasibilityParams {
  const _TrailFeasibilityParams(
      {required this.altitudeFactor,
      required this.technicalFactor,
      required this.heatFactor,
      required this.snowFactor,
      final List<String> customConditions = const [],
      final Map<String, String> recommendationTemplates = const {}})
      : _customConditions = customConditions,
        _recommendationTemplates = recommendationTemplates,
        super._();
  factory _TrailFeasibilityParams.fromJson(Map<String, dynamic> json) =>
      _$TrailFeasibilityParamsFromJson(json);

  /// Facteur d'ajustement altitude (1.0 = neutre, >1 = plus difficile)
  @override
  final double altitudeFactor;

  /// Facteur d'ajustement technicite (1.0 = neutre)
  @override
  final double technicalFactor;

  /// Facteur d'ajustement chaleur (1.0 = neutre)
  @override
  final double heatFactor;

  /// Facteur d'ajustement neige (1.0 = neutre)
  @override
  final double snowFactor;

  /// Conditions supplementaires personnalisees
  final List<String> _customConditions;

  /// Conditions supplementaires personnalisees
  @override
  @JsonKey()
  List<String> get customConditions {
    if (_customConditions is EqualUnmodifiableListView)
      return _customConditions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customConditions);
  }

  /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
  final Map<String, String> _recommendationTemplates;

  /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
  @override
  @JsonKey()
  Map<String, String> get recommendationTemplates {
    if (_recommendationTemplates is EqualUnmodifiableMapView)
      return _recommendationTemplates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_recommendationTemplates);
  }

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrailFeasibilityParamsCopyWith<_TrailFeasibilityParams> get copyWith =>
      __$TrailFeasibilityParamsCopyWithImpl<_TrailFeasibilityParams>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TrailFeasibilityParamsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrailFeasibilityParams &&
            (identical(other.altitudeFactor, altitudeFactor) ||
                other.altitudeFactor == altitudeFactor) &&
            (identical(other.technicalFactor, technicalFactor) ||
                other.technicalFactor == technicalFactor) &&
            (identical(other.heatFactor, heatFactor) ||
                other.heatFactor == heatFactor) &&
            (identical(other.snowFactor, snowFactor) ||
                other.snowFactor == snowFactor) &&
            const DeepCollectionEquality()
                .equals(other._customConditions, _customConditions) &&
            const DeepCollectionEquality().equals(
                other._recommendationTemplates, _recommendationTemplates));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      altitudeFactor,
      technicalFactor,
      heatFactor,
      snowFactor,
      const DeepCollectionEquality().hash(_customConditions),
      const DeepCollectionEquality().hash(_recommendationTemplates));

  @override
  String toString() {
    return 'TrailFeasibilityParams(altitudeFactor: $altitudeFactor, technicalFactor: $technicalFactor, heatFactor: $heatFactor, snowFactor: $snowFactor, customConditions: $customConditions, recommendationTemplates: $recommendationTemplates)';
  }
}

/// @nodoc
abstract mixin class _$TrailFeasibilityParamsCopyWith<$Res>
    implements $TrailFeasibilityParamsCopyWith<$Res> {
  factory _$TrailFeasibilityParamsCopyWith(_TrailFeasibilityParams value,
          $Res Function(_TrailFeasibilityParams) _then) =
      __$TrailFeasibilityParamsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double altitudeFactor,
      double technicalFactor,
      double heatFactor,
      double snowFactor,
      List<String> customConditions,
      Map<String, String> recommendationTemplates});
}

/// @nodoc
class __$TrailFeasibilityParamsCopyWithImpl<$Res>
    implements _$TrailFeasibilityParamsCopyWith<$Res> {
  __$TrailFeasibilityParamsCopyWithImpl(this._self, this._then);

  final _TrailFeasibilityParams _self;
  final $Res Function(_TrailFeasibilityParams) _then;

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? altitudeFactor = null,
    Object? technicalFactor = null,
    Object? heatFactor = null,
    Object? snowFactor = null,
    Object? customConditions = null,
    Object? recommendationTemplates = null,
  }) {
    return _then(_TrailFeasibilityParams(
      altitudeFactor: null == altitudeFactor
          ? _self.altitudeFactor
          : altitudeFactor // ignore: cast_nullable_to_non_nullable
              as double,
      technicalFactor: null == technicalFactor
          ? _self.technicalFactor
          : technicalFactor // ignore: cast_nullable_to_non_nullable
              as double,
      heatFactor: null == heatFactor
          ? _self.heatFactor
          : heatFactor // ignore: cast_nullable_to_non_nullable
              as double,
      snowFactor: null == snowFactor
          ? _self.snowFactor
          : snowFactor // ignore: cast_nullable_to_non_nullable
              as double,
      customConditions: null == customConditions
          ? _self._customConditions
          : customConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      recommendationTemplates: null == recommendationTemplates
          ? _self._recommendationTemplates
          : recommendationTemplates // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

// dart format on
