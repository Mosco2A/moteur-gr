// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feasibility_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FeasibilityResult {
  /// Score de faisabilite (0-100, 100 = tres faisable)
  double get score;

  /// Nombre de jours recommandes pour le parcours
  int get recommendedDays;

  /// Liste d'avertissements (ex: denivele trop important, meteo)
  List<String> get warnings;

  /// True si l'evaluation porte sur un groupe
  bool get isGroupAssessment;

  /// Index du profil le plus faible dans le groupe (null si solo)
  int? get worstProfileIndex;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FeasibilityResultCopyWith<FeasibilityResult> get copyWith =>
      _$FeasibilityResultCopyWithImpl<FeasibilityResult>(
          this as FeasibilityResult, _$identity);

  /// Serializes this FeasibilityResult to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FeasibilityResult &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.recommendedDays, recommendedDays) ||
                other.recommendedDays == recommendedDays) &&
            const DeepCollectionEquality().equals(other.warnings, warnings) &&
            (identical(other.isGroupAssessment, isGroupAssessment) ||
                other.isGroupAssessment == isGroupAssessment) &&
            (identical(other.worstProfileIndex, worstProfileIndex) ||
                other.worstProfileIndex == worstProfileIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      score,
      recommendedDays,
      const DeepCollectionEquality().hash(warnings),
      isGroupAssessment,
      worstProfileIndex);

  @override
  String toString() {
    return 'FeasibilityResult(score: $score, recommendedDays: $recommendedDays, warnings: $warnings, isGroupAssessment: $isGroupAssessment, worstProfileIndex: $worstProfileIndex)';
  }
}

/// @nodoc
abstract mixin class $FeasibilityResultCopyWith<$Res> {
  factory $FeasibilityResultCopyWith(
          FeasibilityResult value, $Res Function(FeasibilityResult) _then) =
      _$FeasibilityResultCopyWithImpl;
  @useResult
  $Res call(
      {double score,
      int recommendedDays,
      List<String> warnings,
      bool isGroupAssessment,
      int? worstProfileIndex});
}

/// @nodoc
class _$FeasibilityResultCopyWithImpl<$Res>
    implements $FeasibilityResultCopyWith<$Res> {
  _$FeasibilityResultCopyWithImpl(this._self, this._then);

  final FeasibilityResult _self;
  final $Res Function(FeasibilityResult) _then;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? recommendedDays = null,
    Object? warnings = null,
    Object? isGroupAssessment = null,
    Object? worstProfileIndex = freezed,
  }) {
    return _then(_self.copyWith(
      score: null == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedDays: null == recommendedDays
          ? _self.recommendedDays
          : recommendedDays // ignore: cast_nullable_to_non_nullable
              as int,
      warnings: null == warnings
          ? _self.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isGroupAssessment: null == isGroupAssessment
          ? _self.isGroupAssessment
          : isGroupAssessment // ignore: cast_nullable_to_non_nullable
              as bool,
      worstProfileIndex: freezed == worstProfileIndex
          ? _self.worstProfileIndex
          : worstProfileIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FeasibilityResult].
extension FeasibilityResultPatterns on FeasibilityResult {
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
    TResult Function(_FeasibilityResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult() when $default != null:
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
    TResult Function(_FeasibilityResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult():
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
    TResult? Function(_FeasibilityResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult() when $default != null:
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
    TResult Function(double score, int recommendedDays, List<String> warnings,
            bool isGroupAssessment, int? worstProfileIndex)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult() when $default != null:
        return $default(_that.score, _that.recommendedDays, _that.warnings,
            _that.isGroupAssessment, _that.worstProfileIndex);
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
    TResult Function(double score, int recommendedDays, List<String> warnings,
            bool isGroupAssessment, int? worstProfileIndex)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult():
        return $default(_that.score, _that.recommendedDays, _that.warnings,
            _that.isGroupAssessment, _that.worstProfileIndex);
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
    TResult? Function(double score, int recommendedDays, List<String> warnings,
            bool isGroupAssessment, int? worstProfileIndex)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FeasibilityResult() when $default != null:
        return $default(_that.score, _that.recommendedDays, _that.warnings,
            _that.isGroupAssessment, _that.worstProfileIndex);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FeasibilityResult extends FeasibilityResult {
  const _FeasibilityResult(
      {required this.score,
      required this.recommendedDays,
      required final List<String> warnings,
      this.isGroupAssessment = false,
      this.worstProfileIndex})
      : _warnings = warnings,
        super._();
  factory _FeasibilityResult.fromJson(Map<String, dynamic> json) =>
      _$FeasibilityResultFromJson(json);

  /// Score de faisabilite (0-100, 100 = tres faisable)
  @override
  final double score;

  /// Nombre de jours recommandes pour le parcours
  @override
  final int recommendedDays;

  /// Liste d'avertissements (ex: denivele trop important, meteo)
  final List<String> _warnings;

  /// Liste d'avertissements (ex: denivele trop important, meteo)
  @override
  List<String> get warnings {
    if (_warnings is EqualUnmodifiableListView) return _warnings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_warnings);
  }

  /// True si l'evaluation porte sur un groupe
  @override
  @JsonKey()
  final bool isGroupAssessment;

  /// Index du profil le plus faible dans le groupe (null si solo)
  @override
  final int? worstProfileIndex;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FeasibilityResultCopyWith<_FeasibilityResult> get copyWith =>
      __$FeasibilityResultCopyWithImpl<_FeasibilityResult>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FeasibilityResultToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FeasibilityResult &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.recommendedDays, recommendedDays) ||
                other.recommendedDays == recommendedDays) &&
            const DeepCollectionEquality().equals(other._warnings, _warnings) &&
            (identical(other.isGroupAssessment, isGroupAssessment) ||
                other.isGroupAssessment == isGroupAssessment) &&
            (identical(other.worstProfileIndex, worstProfileIndex) ||
                other.worstProfileIndex == worstProfileIndex));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      score,
      recommendedDays,
      const DeepCollectionEquality().hash(_warnings),
      isGroupAssessment,
      worstProfileIndex);

  @override
  String toString() {
    return 'FeasibilityResult(score: $score, recommendedDays: $recommendedDays, warnings: $warnings, isGroupAssessment: $isGroupAssessment, worstProfileIndex: $worstProfileIndex)';
  }
}

/// @nodoc
abstract mixin class _$FeasibilityResultCopyWith<$Res>
    implements $FeasibilityResultCopyWith<$Res> {
  factory _$FeasibilityResultCopyWith(
          _FeasibilityResult value, $Res Function(_FeasibilityResult) _then) =
      __$FeasibilityResultCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double score,
      int recommendedDays,
      List<String> warnings,
      bool isGroupAssessment,
      int? worstProfileIndex});
}

/// @nodoc
class __$FeasibilityResultCopyWithImpl<$Res>
    implements _$FeasibilityResultCopyWith<$Res> {
  __$FeasibilityResultCopyWithImpl(this._self, this._then);

  final _FeasibilityResult _self;
  final $Res Function(_FeasibilityResult) _then;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? score = null,
    Object? recommendedDays = null,
    Object? warnings = null,
    Object? isGroupAssessment = null,
    Object? worstProfileIndex = freezed,
  }) {
    return _then(_FeasibilityResult(
      score: null == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedDays: null == recommendedDays
          ? _self.recommendedDays
          : recommendedDays // ignore: cast_nullable_to_non_nullable
              as int,
      warnings: null == warnings
          ? _self._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isGroupAssessment: null == isGroupAssessment
          ? _self.isGroupAssessment
          : isGroupAssessment // ignore: cast_nullable_to_non_nullable
              as bool,
      worstProfileIndex: freezed == worstProfileIndex
          ? _self.worstProfileIndex
          : worstProfileIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
