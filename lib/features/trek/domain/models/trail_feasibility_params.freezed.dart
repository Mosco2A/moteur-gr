// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail_feasibility_params.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrailFeasibilityParams _$TrailFeasibilityParamsFromJson(
    Map<String, dynamic> json) {
  return _TrailFeasibilityParams.fromJson(json);
}

/// @nodoc
mixin _$TrailFeasibilityParams {
  /// Facteur d'ajustement altitude (1.0 = neutre, >1 = plus difficile)
  double get altitudeFactor => throw _privateConstructorUsedError;

  /// Facteur d'ajustement technicite (1.0 = neutre)
  double get technicalFactor => throw _privateConstructorUsedError;

  /// Facteur d'ajustement chaleur (1.0 = neutre)
  double get heatFactor => throw _privateConstructorUsedError;

  /// Facteur d'ajustement neige (1.0 = neutre)
  double get snowFactor => throw _privateConstructorUsedError;

  /// Conditions supplementaires personnalisees
  List<String> get customConditions => throw _privateConstructorUsedError;

  /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
  Map<String, String> get recommendationTemplates =>
      throw _privateConstructorUsedError;

  /// Serializes this TrailFeasibilityParams to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrailFeasibilityParamsCopyWith<TrailFeasibilityParams> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrailFeasibilityParamsCopyWith<$Res> {
  factory $TrailFeasibilityParamsCopyWith(TrailFeasibilityParams value,
          $Res Function(TrailFeasibilityParams) then) =
      _$TrailFeasibilityParamsCopyWithImpl<$Res, TrailFeasibilityParams>;
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
class _$TrailFeasibilityParamsCopyWithImpl<$Res,
        $Val extends TrailFeasibilityParams>
    implements $TrailFeasibilityParamsCopyWith<$Res> {
  _$TrailFeasibilityParamsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
    return _then(_value.copyWith(
      altitudeFactor: null == altitudeFactor
          ? _value.altitudeFactor
          : altitudeFactor // ignore: cast_nullable_to_non_nullable
              as double,
      technicalFactor: null == technicalFactor
          ? _value.technicalFactor
          : technicalFactor // ignore: cast_nullable_to_non_nullable
              as double,
      heatFactor: null == heatFactor
          ? _value.heatFactor
          : heatFactor // ignore: cast_nullable_to_non_nullable
              as double,
      snowFactor: null == snowFactor
          ? _value.snowFactor
          : snowFactor // ignore: cast_nullable_to_non_nullable
              as double,
      customConditions: null == customConditions
          ? _value.customConditions
          : customConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      recommendationTemplates: null == recommendationTemplates
          ? _value.recommendationTemplates
          : recommendationTemplates // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrailFeasibilityParamsImplCopyWith<$Res>
    implements $TrailFeasibilityParamsCopyWith<$Res> {
  factory _$$TrailFeasibilityParamsImplCopyWith(
          _$TrailFeasibilityParamsImpl value,
          $Res Function(_$TrailFeasibilityParamsImpl) then) =
      __$$TrailFeasibilityParamsImplCopyWithImpl<$Res>;
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
class __$$TrailFeasibilityParamsImplCopyWithImpl<$Res>
    extends _$TrailFeasibilityParamsCopyWithImpl<$Res,
        _$TrailFeasibilityParamsImpl>
    implements _$$TrailFeasibilityParamsImplCopyWith<$Res> {
  __$$TrailFeasibilityParamsImplCopyWithImpl(
      _$TrailFeasibilityParamsImpl _value,
      $Res Function(_$TrailFeasibilityParamsImpl) _then)
      : super(_value, _then);

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
    return _then(_$TrailFeasibilityParamsImpl(
      altitudeFactor: null == altitudeFactor
          ? _value.altitudeFactor
          : altitudeFactor // ignore: cast_nullable_to_non_nullable
              as double,
      technicalFactor: null == technicalFactor
          ? _value.technicalFactor
          : technicalFactor // ignore: cast_nullable_to_non_nullable
              as double,
      heatFactor: null == heatFactor
          ? _value.heatFactor
          : heatFactor // ignore: cast_nullable_to_non_nullable
              as double,
      snowFactor: null == snowFactor
          ? _value.snowFactor
          : snowFactor // ignore: cast_nullable_to_non_nullable
              as double,
      customConditions: null == customConditions
          ? _value._customConditions
          : customConditions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      recommendationTemplates: null == recommendationTemplates
          ? _value._recommendationTemplates
          : recommendationTemplates // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrailFeasibilityParamsImpl extends _TrailFeasibilityParams {
  const _$TrailFeasibilityParamsImpl(
      {required this.altitudeFactor,
      required this.technicalFactor,
      required this.heatFactor,
      required this.snowFactor,
      final List<String> customConditions = const [],
      final Map<String, String> recommendationTemplates = const {}})
      : _customConditions = customConditions,
        _recommendationTemplates = recommendationTemplates,
        super._();

  factory _$TrailFeasibilityParamsImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrailFeasibilityParamsImplFromJson(json);

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

  @override
  String toString() {
    return 'TrailFeasibilityParams(altitudeFactor: $altitudeFactor, technicalFactor: $technicalFactor, heatFactor: $heatFactor, snowFactor: $snowFactor, customConditions: $customConditions, recommendationTemplates: $recommendationTemplates)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrailFeasibilityParamsImpl &&
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

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrailFeasibilityParamsImplCopyWith<_$TrailFeasibilityParamsImpl>
      get copyWith => __$$TrailFeasibilityParamsImplCopyWithImpl<
          _$TrailFeasibilityParamsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrailFeasibilityParamsImplToJson(
      this,
    );
  }
}

abstract class _TrailFeasibilityParams extends TrailFeasibilityParams {
  const factory _TrailFeasibilityParams(
          {required final double altitudeFactor,
          required final double technicalFactor,
          required final double heatFactor,
          required final double snowFactor,
          final List<String> customConditions,
          final Map<String, String> recommendationTemplates}) =
      _$TrailFeasibilityParamsImpl;
  const _TrailFeasibilityParams._() : super._();

  factory _TrailFeasibilityParams.fromJson(Map<String, dynamic> json) =
      _$TrailFeasibilityParamsImpl.fromJson;

  /// Facteur d'ajustement altitude (1.0 = neutre, >1 = plus difficile)
  @override
  double get altitudeFactor;

  /// Facteur d'ajustement technicite (1.0 = neutre)
  @override
  double get technicalFactor;

  /// Facteur d'ajustement chaleur (1.0 = neutre)
  @override
  double get heatFactor;

  /// Facteur d'ajustement neige (1.0 = neutre)
  @override
  double get snowFactor;

  /// Conditions supplementaires personnalisees
  @override
  List<String> get customConditions;

  /// Templates de recommandation par cle (ex: "heat" -> "Prevoyez 3L d'eau/jour")
  @override
  Map<String, String> get recommendationTemplates;

  /// Create a copy of TrailFeasibilityParams
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrailFeasibilityParamsImplCopyWith<_$TrailFeasibilityParamsImpl>
      get copyWith => throw _privateConstructorUsedError;
}
