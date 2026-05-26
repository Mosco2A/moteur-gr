// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StageModel _$StageModelFromJson(Map<String, dynamic> json) {
  return _StageModel.fromJson(json);
}

/// @nodoc
mixin _$StageModel {
  /// Cle primaire DB (0 si pas encore insere)
  int get id => throw _privateConstructorUsedError;

  /// Identifiant du sentier parent
  String get trailId => throw _privateConstructorUsedError;

  /// Numero de l'etape (1-indexed)
  int get stageNumber => throw _privateConstructorUsedError;

  /// Nom de l'etape
  String get name => throw _privateConstructorUsedError;

  /// Distance en km
  double get distanceKm => throw _privateConstructorUsedError;

  /// Denivele positif en metres
  int get elevationGainM => throw _privateConstructorUsedError;

  /// Denivele negatif en metres
  int get elevationLossM => throw _privateConstructorUsedError;

  /// Description textuelle
  String get description => throw _privateConstructorUsedError;

  /// Latitude du point de depart
  double get startLat => throw _privateConstructorUsedError;

  /// Longitude du point de depart
  double get startLng => throw _privateConstructorUsedError;

  /// Latitude du point d'arrivee
  double get endLat => throw _privateConstructorUsedError;

  /// Longitude du point d'arrivee
  double get endLng => throw _privateConstructorUsedError;

  /// Difficulte (easy, moderate, hard, extreme)
  String get difficulty => throw _privateConstructorUsedError;

  /// Serializes this StageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageModelCopyWith<StageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageModelCopyWith<$Res> {
  factory $StageModelCopyWith(
          StageModel value, $Res Function(StageModel) then) =
      _$StageModelCopyWithImpl<$Res, StageModel>;
  @useResult
  $Res call(
      {int id,
      String trailId,
      int stageNumber,
      String name,
      double distanceKm,
      int elevationGainM,
      int elevationLossM,
      String description,
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String difficulty});
}

/// @nodoc
class _$StageModelCopyWithImpl<$Res, $Val extends StageModel>
    implements $StageModelCopyWith<$Res> {
  _$StageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? stageNumber = null,
    Object? name = null,
    Object? distanceKm = null,
    Object? elevationGainM = null,
    Object? elevationLossM = null,
    Object? description = null,
    Object? startLat = null,
    Object? startLng = null,
    Object? endLat = null,
    Object? endLng = null,
    Object? difficulty = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      trailId: null == trailId
          ? _value.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      stageNumber: null == stageNumber
          ? _value.stageNumber
          : stageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      distanceKm: null == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGainM: null == elevationGainM
          ? _value.elevationGainM
          : elevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLossM: null == elevationLossM
          ? _value.elevationLossM
          : elevationLossM // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      startLat: null == startLat
          ? _value.startLat
          : startLat // ignore: cast_nullable_to_non_nullable
              as double,
      startLng: null == startLng
          ? _value.startLng
          : startLng // ignore: cast_nullable_to_non_nullable
              as double,
      endLat: null == endLat
          ? _value.endLat
          : endLat // ignore: cast_nullable_to_non_nullable
              as double,
      endLng: null == endLng
          ? _value.endLng
          : endLng // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageModelImplCopyWith<$Res>
    implements $StageModelCopyWith<$Res> {
  factory _$$StageModelImplCopyWith(
          _$StageModelImpl value, $Res Function(_$StageModelImpl) then) =
      __$$StageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String trailId,
      int stageNumber,
      String name,
      double distanceKm,
      int elevationGainM,
      int elevationLossM,
      String description,
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String difficulty});
}

/// @nodoc
class __$$StageModelImplCopyWithImpl<$Res>
    extends _$StageModelCopyWithImpl<$Res, _$StageModelImpl>
    implements _$$StageModelImplCopyWith<$Res> {
  __$$StageModelImplCopyWithImpl(
      _$StageModelImpl _value, $Res Function(_$StageModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? stageNumber = null,
    Object? name = null,
    Object? distanceKm = null,
    Object? elevationGainM = null,
    Object? elevationLossM = null,
    Object? description = null,
    Object? startLat = null,
    Object? startLng = null,
    Object? endLat = null,
    Object? endLng = null,
    Object? difficulty = null,
  }) {
    return _then(_$StageModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      trailId: null == trailId
          ? _value.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      stageNumber: null == stageNumber
          ? _value.stageNumber
          : stageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      distanceKm: null == distanceKm
          ? _value.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGainM: null == elevationGainM
          ? _value.elevationGainM
          : elevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLossM: null == elevationLossM
          ? _value.elevationLossM
          : elevationLossM // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      startLat: null == startLat
          ? _value.startLat
          : startLat // ignore: cast_nullable_to_non_nullable
              as double,
      startLng: null == startLng
          ? _value.startLng
          : startLng // ignore: cast_nullable_to_non_nullable
              as double,
      endLat: null == endLat
          ? _value.endLat
          : endLat // ignore: cast_nullable_to_non_nullable
              as double,
      endLng: null == endLng
          ? _value.endLng
          : endLng // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageModelImpl extends _StageModel {
  const _$StageModelImpl(
      {this.id = 0,
      required this.trailId,
      required this.stageNumber,
      required this.name,
      required this.distanceKm,
      required this.elevationGainM,
      required this.elevationLossM,
      this.description = '',
      required this.startLat,
      required this.startLng,
      required this.endLat,
      required this.endLng,
      this.difficulty = 'moderate'})
      : super._();

  factory _$StageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageModelImplFromJson(json);

  /// Cle primaire DB (0 si pas encore insere)
  @override
  @JsonKey()
  final int id;

  /// Identifiant du sentier parent
  @override
  final String trailId;

  /// Numero de l'etape (1-indexed)
  @override
  final int stageNumber;

  /// Nom de l'etape
  @override
  final String name;

  /// Distance en km
  @override
  final double distanceKm;

  /// Denivele positif en metres
  @override
  final int elevationGainM;

  /// Denivele negatif en metres
  @override
  final int elevationLossM;

  /// Description textuelle
  @override
  @JsonKey()
  final String description;

  /// Latitude du point de depart
  @override
  final double startLat;

  /// Longitude du point de depart
  @override
  final double startLng;

  /// Latitude du point d'arrivee
  @override
  final double endLat;

  /// Longitude du point d'arrivee
  @override
  final double endLng;

  /// Difficulte (easy, moderate, hard, extreme)
  @override
  @JsonKey()
  final String difficulty;

  @override
  String toString() {
    return 'StageModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, distanceKm: $distanceKm, elevationGainM: $elevationGainM, elevationLossM: $elevationLossM, description: $description, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.stageNumber, stageNumber) ||
                other.stageNumber == stageNumber) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.elevationGainM, elevationGainM) ||
                other.elevationGainM == elevationGainM) &&
            (identical(other.elevationLossM, elevationLossM) ||
                other.elevationLossM == elevationLossM) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.startLat, startLat) ||
                other.startLat == startLat) &&
            (identical(other.startLng, startLng) ||
                other.startLng == startLng) &&
            (identical(other.endLat, endLat) || other.endLat == endLat) &&
            (identical(other.endLng, endLng) || other.endLng == endLng) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      trailId,
      stageNumber,
      name,
      distanceKm,
      elevationGainM,
      elevationLossM,
      description,
      startLat,
      startLng,
      endLat,
      endLng,
      difficulty);

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageModelImplCopyWith<_$StageModelImpl> get copyWith =>
      __$$StageModelImplCopyWithImpl<_$StageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageModelImplToJson(
      this,
    );
  }
}

abstract class _StageModel extends StageModel {
  const factory _StageModel(
      {final int id,
      required final String trailId,
      required final int stageNumber,
      required final String name,
      required final double distanceKm,
      required final int elevationGainM,
      required final int elevationLossM,
      final String description,
      required final double startLat,
      required final double startLng,
      required final double endLat,
      required final double endLng,
      final String difficulty}) = _$StageModelImpl;
  const _StageModel._() : super._();

  factory _StageModel.fromJson(Map<String, dynamic> json) =
      _$StageModelImpl.fromJson;

  /// Cle primaire DB (0 si pas encore insere)
  @override
  int get id;

  /// Identifiant du sentier parent
  @override
  String get trailId;

  /// Numero de l'etape (1-indexed)
  @override
  int get stageNumber;

  /// Nom de l'etape
  @override
  String get name;

  /// Distance en km
  @override
  double get distanceKm;

  /// Denivele positif en metres
  @override
  int get elevationGainM;

  /// Denivele negatif en metres
  @override
  int get elevationLossM;

  /// Description textuelle
  @override
  String get description;

  /// Latitude du point de depart
  @override
  double get startLat;

  /// Longitude du point de depart
  @override
  double get startLng;

  /// Latitude du point d'arrivee
  @override
  double get endLat;

  /// Longitude du point d'arrivee
  @override
  double get endLng;

  /// Difficulte (easy, moderate, hard, extreme)
  @override
  String get difficulty;

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageModelImplCopyWith<_$StageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
