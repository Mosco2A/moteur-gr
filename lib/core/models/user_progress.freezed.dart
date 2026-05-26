// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$UserProgressModel {
  /// Cle primaire DB (0 si pas encore insere)
  int get id => throw _privateConstructorUsedError;

  /// Identifiant du sentier
  String get trailId => throw _privateConstructorUsedError;

  /// Etape courante (1-indexed)
  int get currentStage => throw _privateConstructorUsedError;

  /// Distance totale parcourue en km
  double get totalDistanceWalkedKm => throw _privateConstructorUsedError;

  /// Denivele positif total cumule en metres
  int get totalElevationGainedM => throw _privateConstructorUsedError;

  /// Sentier complete ou non
  bool get isCompleted => throw _privateConstructorUsedError;

  /// Date de debut du sentier
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Date de fin du sentier
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProgressModelCopyWith<UserProgressModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProgressModelCopyWith<$Res> {
  factory $UserProgressModelCopyWith(
          UserProgressModel value, $Res Function(UserProgressModel) then) =
      _$UserProgressModelCopyWithImpl<$Res, UserProgressModel>;
  @useResult
  $Res call(
      {int id,
      String trailId,
      int currentStage,
      double totalDistanceWalkedKm,
      int totalElevationGainedM,
      bool isCompleted,
      DateTime? startedAt,
      DateTime? completedAt});
}

/// @nodoc
class _$UserProgressModelCopyWithImpl<$Res, $Val extends UserProgressModel>
    implements $UserProgressModelCopyWith<$Res> {
  _$UserProgressModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? currentStage = null,
    Object? totalDistanceWalkedKm = null,
    Object? totalElevationGainedM = null,
    Object? isCompleted = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
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
      currentStage: null == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as int,
      totalDistanceWalkedKm: null == totalDistanceWalkedKm
          ? _value.totalDistanceWalkedKm
          : totalDistanceWalkedKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGainedM: null == totalElevationGainedM
          ? _value.totalElevationGainedM
          : totalElevationGainedM // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UserProgressModelImplCopyWith<$Res>
    implements $UserProgressModelCopyWith<$Res> {
  factory _$$UserProgressModelImplCopyWith(_$UserProgressModelImpl value,
          $Res Function(_$UserProgressModelImpl) then) =
      __$$UserProgressModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String trailId,
      int currentStage,
      double totalDistanceWalkedKm,
      int totalElevationGainedM,
      bool isCompleted,
      DateTime? startedAt,
      DateTime? completedAt});
}

/// @nodoc
class __$$UserProgressModelImplCopyWithImpl<$Res>
    extends _$UserProgressModelCopyWithImpl<$Res, _$UserProgressModelImpl>
    implements _$$UserProgressModelImplCopyWith<$Res> {
  __$$UserProgressModelImplCopyWithImpl(_$UserProgressModelImpl _value,
      $Res Function(_$UserProgressModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? currentStage = null,
    Object? totalDistanceWalkedKm = null,
    Object? totalElevationGainedM = null,
    Object? isCompleted = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(_$UserProgressModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      trailId: null == trailId
          ? _value.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      currentStage: null == currentStage
          ? _value.currentStage
          : currentStage // ignore: cast_nullable_to_non_nullable
              as int,
      totalDistanceWalkedKm: null == totalDistanceWalkedKm
          ? _value.totalDistanceWalkedKm
          : totalDistanceWalkedKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGainedM: null == totalElevationGainedM
          ? _value.totalElevationGainedM
          : totalElevationGainedM // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc

class _$UserProgressModelImpl extends _UserProgressModel {
  const _$UserProgressModelImpl(
      {this.id = 0,
      required this.trailId,
      this.currentStage = 1,
      this.totalDistanceWalkedKm = 0.0,
      this.totalElevationGainedM = 0,
      this.isCompleted = false,
      this.startedAt,
      this.completedAt})
      : super._();

  /// Cle primaire DB (0 si pas encore insere)
  @override
  @JsonKey()
  final int id;

  /// Identifiant du sentier
  @override
  final String trailId;

  /// Etape courante (1-indexed)
  @override
  @JsonKey()
  final int currentStage;

  /// Distance totale parcourue en km
  @override
  @JsonKey()
  final double totalDistanceWalkedKm;

  /// Denivele positif total cumule en metres
  @override
  @JsonKey()
  final int totalElevationGainedM;

  /// Sentier complete ou non
  @override
  @JsonKey()
  final bool isCompleted;

  /// Date de debut du sentier
  @override
  final DateTime? startedAt;

  /// Date de fin du sentier
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'UserProgressModel(id: $id, trailId: $trailId, currentStage: $currentStage, totalDistanceWalkedKm: $totalDistanceWalkedKm, totalElevationGainedM: $totalElevationGainedM, isCompleted: $isCompleted, startedAt: $startedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProgressModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.currentStage, currentStage) ||
                other.currentStage == currentStage) &&
            (identical(other.totalDistanceWalkedKm, totalDistanceWalkedKm) ||
                other.totalDistanceWalkedKm == totalDistanceWalkedKm) &&
            (identical(other.totalElevationGainedM, totalElevationGainedM) ||
                other.totalElevationGainedM == totalElevationGainedM) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      trailId,
      currentStage,
      totalDistanceWalkedKm,
      totalElevationGainedM,
      isCompleted,
      startedAt,
      completedAt);

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProgressModelImplCopyWith<_$UserProgressModelImpl> get copyWith =>
      __$$UserProgressModelImplCopyWithImpl<_$UserProgressModelImpl>(
          this, _$identity);
}

abstract class _UserProgressModel extends UserProgressModel {
  const factory _UserProgressModel(
      {final int id,
      required final String trailId,
      final int currentStage,
      final double totalDistanceWalkedKm,
      final int totalElevationGainedM,
      final bool isCompleted,
      final DateTime? startedAt,
      final DateTime? completedAt}) = _$UserProgressModelImpl;
  const _UserProgressModel._() : super._();

  /// Cle primaire DB (0 si pas encore insere)
  @override
  int get id;

  /// Identifiant du sentier
  @override
  String get trailId;

  /// Etape courante (1-indexed)
  @override
  int get currentStage;

  /// Distance totale parcourue en km
  @override
  double get totalDistanceWalkedKm;

  /// Denivele positif total cumule en metres
  @override
  int get totalElevationGainedM;

  /// Sentier complete ou non
  @override
  bool get isCompleted;

  /// Date de debut du sentier
  @override
  DateTime? get startedAt;

  /// Date de fin du sentier
  @override
  DateTime? get completedAt;

  /// Create a copy of UserProgressModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProgressModelImplCopyWith<_$UserProgressModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
