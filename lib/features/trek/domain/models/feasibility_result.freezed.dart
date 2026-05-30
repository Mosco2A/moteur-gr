// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feasibility_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FeasibilityResult _$FeasibilityResultFromJson(Map<String, dynamic> json) {
  return _FeasibilityResult.fromJson(json);
}

/// @nodoc
mixin _$FeasibilityResult {
  /// Score de faisabilite (0-100, 100 = tres faisable)
  double get score => throw _privateConstructorUsedError;

  /// Nombre de jours recommandes pour le parcours
  int get recommendedDays => throw _privateConstructorUsedError;

  /// Liste d'avertissements (ex: denivele trop important, meteo)
  List<String> get warnings => throw _privateConstructorUsedError;

  /// True si l'evaluation porte sur un groupe
  bool get isGroupAssessment => throw _privateConstructorUsedError;

  /// Index du profil le plus faible dans le groupe (null si solo)
  int? get worstProfileIndex => throw _privateConstructorUsedError;

  /// Serializes this FeasibilityResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeasibilityResultCopyWith<FeasibilityResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeasibilityResultCopyWith<$Res> {
  factory $FeasibilityResultCopyWith(
          FeasibilityResult value, $Res Function(FeasibilityResult) then) =
      _$FeasibilityResultCopyWithImpl<$Res, FeasibilityResult>;
  @useResult
  $Res call(
      {double score,
      int recommendedDays,
      List<String> warnings,
      bool isGroupAssessment,
      int? worstProfileIndex});
}

/// @nodoc
class _$FeasibilityResultCopyWithImpl<$Res, $Val extends FeasibilityResult>
    implements $FeasibilityResultCopyWith<$Res> {
  _$FeasibilityResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedDays: null == recommendedDays
          ? _value.recommendedDays
          : recommendedDays // ignore: cast_nullable_to_non_nullable
              as int,
      warnings: null == warnings
          ? _value.warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isGroupAssessment: null == isGroupAssessment
          ? _value.isGroupAssessment
          : isGroupAssessment // ignore: cast_nullable_to_non_nullable
              as bool,
      worstProfileIndex: freezed == worstProfileIndex
          ? _value.worstProfileIndex
          : worstProfileIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FeasibilityResultImplCopyWith<$Res>
    implements $FeasibilityResultCopyWith<$Res> {
  factory _$$FeasibilityResultImplCopyWith(_$FeasibilityResultImpl value,
          $Res Function(_$FeasibilityResultImpl) then) =
      __$$FeasibilityResultImplCopyWithImpl<$Res>;
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
class __$$FeasibilityResultImplCopyWithImpl<$Res>
    extends _$FeasibilityResultCopyWithImpl<$Res, _$FeasibilityResultImpl>
    implements _$$FeasibilityResultImplCopyWith<$Res> {
  __$$FeasibilityResultImplCopyWithImpl(_$FeasibilityResultImpl _value,
      $Res Function(_$FeasibilityResultImpl) _then)
      : super(_value, _then);

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
    return _then(_$FeasibilityResultImpl(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedDays: null == recommendedDays
          ? _value.recommendedDays
          : recommendedDays // ignore: cast_nullable_to_non_nullable
              as int,
      warnings: null == warnings
          ? _value._warnings
          : warnings // ignore: cast_nullable_to_non_nullable
              as List<String>,
      isGroupAssessment: null == isGroupAssessment
          ? _value.isGroupAssessment
          : isGroupAssessment // ignore: cast_nullable_to_non_nullable
              as bool,
      worstProfileIndex: freezed == worstProfileIndex
          ? _value.worstProfileIndex
          : worstProfileIndex // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FeasibilityResultImpl extends _FeasibilityResult {
  const _$FeasibilityResultImpl(
      {required this.score,
      required this.recommendedDays,
      required final List<String> warnings,
      this.isGroupAssessment = false,
      this.worstProfileIndex})
      : _warnings = warnings,
        super._();

  factory _$FeasibilityResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeasibilityResultImplFromJson(json);

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

  @override
  String toString() {
    return 'FeasibilityResult(score: $score, recommendedDays: $recommendedDays, warnings: $warnings, isGroupAssessment: $isGroupAssessment, worstProfileIndex: $worstProfileIndex)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeasibilityResultImpl &&
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

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeasibilityResultImplCopyWith<_$FeasibilityResultImpl> get copyWith =>
      __$$FeasibilityResultImplCopyWithImpl<_$FeasibilityResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeasibilityResultImplToJson(
      this,
    );
  }
}

abstract class _FeasibilityResult extends FeasibilityResult {
  const factory _FeasibilityResult(
      {required final double score,
      required final int recommendedDays,
      required final List<String> warnings,
      final bool isGroupAssessment,
      final int? worstProfileIndex}) = _$FeasibilityResultImpl;
  const _FeasibilityResult._() : super._();

  factory _FeasibilityResult.fromJson(Map<String, dynamic> json) =
      _$FeasibilityResultImpl.fromJson;

  /// Score de faisabilite (0-100, 100 = tres faisable)
  @override
  double get score;

  /// Nombre de jours recommandes pour le parcours
  @override
  int get recommendedDays;

  /// Liste d'avertissements (ex: denivele trop important, meteo)
  @override
  List<String> get warnings;

  /// True si l'evaluation porte sur un groupe
  @override
  bool get isGroupAssessment;

  /// Index du profil le plus faible dans le groupe (null si solo)
  @override
  int? get worstProfileIndex;

  /// Create a copy of FeasibilityResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeasibilityResultImplCopyWith<_$FeasibilityResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
