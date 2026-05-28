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

Stage _$StageFromJson(Map<String, dynamic> json) {
  return _Stage.fromJson(json);
}

/// @nodoc
mixin _$Stage {
  /// Identifiant unique de l'etape
  String get id => throw _privateConstructorUsedError;

  /// Nom en francais
  String get nameFr => throw _privateConstructorUsedError;

  /// Nom en anglais
  String get nameEn => throw _privateConstructorUsedError;

  /// Nom en allemand
  String get nameDe => throw _privateConstructorUsedError;

  /// Nom en italien
  String get nameIt => throw _privateConstructorUsedError;

  /// Nom en espagnol
  String get nameEs => throw _privateConstructorUsedError;

  /// Distance en kilometres
  double get distance => throw _privateConstructorUsedError;

  /// Denivele positif en metres
  int get elevationGain => throw _privateConstructorUsedError;

  /// Denivele negatif en metres
  int get elevationLoss => throw _privateConstructorUsedError;

  /// Duree estimee en minutes (serialise en int pour JSON)
  int get estimatedDurationMinutes => throw _privateConstructorUsedError;

  /// Difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  String get difficulty => throw _privateConstructorUsedError;

  /// Ordre d'affichage
  int get orderIndex => throw _privateConstructorUsedError;

  /// Latitude du point de depart
  double get startLat => throw _privateConstructorUsedError;

  /// Longitude du point de depart
  double get startLng => throw _privateConstructorUsedError;

  /// Latitude du point d'arrivee
  double get endLat => throw _privateConstructorUsedError;

  /// Longitude du point d'arrivee
  double get endLng => throw _privateConstructorUsedError;

  /// Description en francais
  String get descriptionFr => throw _privateConstructorUsedError;

  /// Description en anglais
  String get descriptionEn => throw _privateConstructorUsedError;

  /// Description en allemand
  String get descriptionDe => throw _privateConstructorUsedError;

  /// Description en italien
  String get descriptionIt => throw _privateConstructorUsedError;

  /// Description en espagnol
  String get descriptionEs => throw _privateConstructorUsedError;

  /// Serializes this Stage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StageCopyWith<Stage> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StageCopyWith<$Res> {
  factory $StageCopyWith(Stage value, $Res Function(Stage) then) =
      _$StageCopyWithImpl<$Res, Stage>;
  @useResult
  $Res call(
      {String id,
      String nameFr,
      String nameEn,
      String nameDe,
      String nameIt,
      String nameEs,
      double distance,
      int elevationGain,
      int elevationLoss,
      int estimatedDurationMinutes,
      String difficulty,
      int orderIndex,
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String descriptionFr,
      String descriptionEn,
      String descriptionDe,
      String descriptionIt,
      String descriptionEs});
}

/// @nodoc
class _$StageCopyWithImpl<$Res, $Val extends Stage>
    implements $StageCopyWith<$Res> {
  _$StageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameFr = null,
    Object? nameEn = null,
    Object? nameDe = null,
    Object? nameIt = null,
    Object? nameEs = null,
    Object? distance = null,
    Object? elevationGain = null,
    Object? elevationLoss = null,
    Object? estimatedDurationMinutes = null,
    Object? difficulty = null,
    Object? orderIndex = null,
    Object? startLat = null,
    Object? startLng = null,
    Object? endLat = null,
    Object? endLng = null,
    Object? descriptionFr = null,
    Object? descriptionEn = null,
    Object? descriptionDe = null,
    Object? descriptionIt = null,
    Object? descriptionEs = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nameFr: null == nameFr
          ? _value.nameFr
          : nameFr // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      nameDe: null == nameDe
          ? _value.nameDe
          : nameDe // ignore: cast_nullable_to_non_nullable
              as String,
      nameIt: null == nameIt
          ? _value.nameIt
          : nameIt // ignore: cast_nullable_to_non_nullable
              as String,
      nameEs: null == nameEs
          ? _value.nameEs
          : nameEs // ignore: cast_nullable_to_non_nullable
              as String,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedDurationMinutes: null == estimatedDurationMinutes
          ? _value.estimatedDurationMinutes
          : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
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
      descriptionFr: null == descriptionFr
          ? _value.descriptionFr
          : descriptionFr // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionEn: null == descriptionEn
          ? _value.descriptionEn
          : descriptionEn // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionDe: null == descriptionDe
          ? _value.descriptionDe
          : descriptionDe // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionIt: null == descriptionIt
          ? _value.descriptionIt
          : descriptionIt // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionEs: null == descriptionEs
          ? _value.descriptionEs
          : descriptionEs // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$StageImplCopyWith<$Res> implements $StageCopyWith<$Res> {
  factory _$$StageImplCopyWith(
          _$StageImpl value, $Res Function(_$StageImpl) then) =
      __$$StageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String nameFr,
      String nameEn,
      String nameDe,
      String nameIt,
      String nameEs,
      double distance,
      int elevationGain,
      int elevationLoss,
      int estimatedDurationMinutes,
      String difficulty,
      int orderIndex,
      double startLat,
      double startLng,
      double endLat,
      double endLng,
      String descriptionFr,
      String descriptionEn,
      String descriptionDe,
      String descriptionIt,
      String descriptionEs});
}

/// @nodoc
class __$$StageImplCopyWithImpl<$Res>
    extends _$StageCopyWithImpl<$Res, _$StageImpl>
    implements _$$StageImplCopyWith<$Res> {
  __$$StageImplCopyWithImpl(
      _$StageImpl _value, $Res Function(_$StageImpl) _then)
      : super(_value, _then);

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameFr = null,
    Object? nameEn = null,
    Object? nameDe = null,
    Object? nameIt = null,
    Object? nameEs = null,
    Object? distance = null,
    Object? elevationGain = null,
    Object? elevationLoss = null,
    Object? estimatedDurationMinutes = null,
    Object? difficulty = null,
    Object? orderIndex = null,
    Object? startLat = null,
    Object? startLng = null,
    Object? endLat = null,
    Object? endLng = null,
    Object? descriptionFr = null,
    Object? descriptionEn = null,
    Object? descriptionDe = null,
    Object? descriptionIt = null,
    Object? descriptionEs = null,
  }) {
    return _then(_$StageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      nameFr: null == nameFr
          ? _value.nameFr
          : nameFr // ignore: cast_nullable_to_non_nullable
              as String,
      nameEn: null == nameEn
          ? _value.nameEn
          : nameEn // ignore: cast_nullable_to_non_nullable
              as String,
      nameDe: null == nameDe
          ? _value.nameDe
          : nameDe // ignore: cast_nullable_to_non_nullable
              as String,
      nameIt: null == nameIt
          ? _value.nameIt
          : nameIt // ignore: cast_nullable_to_non_nullable
              as String,
      nameEs: null == nameEs
          ? _value.nameEs
          : nameEs // ignore: cast_nullable_to_non_nullable
              as String,
      distance: null == distance
          ? _value.distance
          : distance // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGain: null == elevationGain
          ? _value.elevationGain
          : elevationGain // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLoss: null == elevationLoss
          ? _value.elevationLoss
          : elevationLoss // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedDurationMinutes: null == estimatedDurationMinutes
          ? _value.estimatedDurationMinutes
          : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      difficulty: null == difficulty
          ? _value.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
      orderIndex: null == orderIndex
          ? _value.orderIndex
          : orderIndex // ignore: cast_nullable_to_non_nullable
              as int,
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
      descriptionFr: null == descriptionFr
          ? _value.descriptionFr
          : descriptionFr // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionEn: null == descriptionEn
          ? _value.descriptionEn
          : descriptionEn // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionDe: null == descriptionDe
          ? _value.descriptionDe
          : descriptionDe // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionIt: null == descriptionIt
          ? _value.descriptionIt
          : descriptionIt // ignore: cast_nullable_to_non_nullable
              as String,
      descriptionEs: null == descriptionEs
          ? _value.descriptionEs
          : descriptionEs // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$StageImpl extends _Stage {
  const _$StageImpl(
      {required this.id,
      required this.nameFr,
      required this.nameEn,
      this.nameDe = '',
      this.nameIt = '',
      this.nameEs = '',
      required this.distance,
      required this.elevationGain,
      required this.elevationLoss,
      required this.estimatedDurationMinutes,
      this.difficulty = 'moderate',
      required this.orderIndex,
      required this.startLat,
      required this.startLng,
      required this.endLat,
      required this.endLng,
      this.descriptionFr = '',
      this.descriptionEn = '',
      this.descriptionDe = '',
      this.descriptionIt = '',
      this.descriptionEs = ''})
      : super._();

  factory _$StageImpl.fromJson(Map<String, dynamic> json) =>
      _$$StageImplFromJson(json);

  /// Identifiant unique de l'etape
  @override
  final String id;

  /// Nom en francais
  @override
  final String nameFr;

  /// Nom en anglais
  @override
  final String nameEn;

  /// Nom en allemand
  @override
  @JsonKey()
  final String nameDe;

  /// Nom en italien
  @override
  @JsonKey()
  final String nameIt;

  /// Nom en espagnol
  @override
  @JsonKey()
  final String nameEs;

  /// Distance en kilometres
  @override
  final double distance;

  /// Denivele positif en metres
  @override
  final int elevationGain;

  /// Denivele negatif en metres
  @override
  final int elevationLoss;

  /// Duree estimee en minutes (serialise en int pour JSON)
  @override
  final int estimatedDurationMinutes;

  /// Difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  @override
  @JsonKey()
  final String difficulty;

  /// Ordre d'affichage
  @override
  final int orderIndex;

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

  /// Description en francais
  @override
  @JsonKey()
  final String descriptionFr;

  /// Description en anglais
  @override
  @JsonKey()
  final String descriptionEn;

  /// Description en allemand
  @override
  @JsonKey()
  final String descriptionDe;

  /// Description en italien
  @override
  @JsonKey()
  final String descriptionIt;

  /// Description en espagnol
  @override
  @JsonKey()
  final String descriptionEs;

  @override
  String toString() {
    return 'Stage(id: $id, nameFr: $nameFr, nameEn: $nameEn, nameDe: $nameDe, nameIt: $nameIt, nameEs: $nameEs, distance: $distance, elevationGain: $elevationGain, elevationLoss: $elevationLoss, estimatedDurationMinutes: $estimatedDurationMinutes, difficulty: $difficulty, orderIndex: $orderIndex, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, descriptionFr: $descriptionFr, descriptionEn: $descriptionEn, descriptionDe: $descriptionDe, descriptionIt: $descriptionIt, descriptionEs: $descriptionEs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameFr, nameFr) || other.nameFr == nameFr) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.nameDe, nameDe) || other.nameDe == nameDe) &&
            (identical(other.nameIt, nameIt) || other.nameIt == nameIt) &&
            (identical(other.nameEs, nameEs) || other.nameEs == nameEs) &&
            (identical(other.distance, distance) ||
                other.distance == distance) &&
            (identical(other.elevationGain, elevationGain) ||
                other.elevationGain == elevationGain) &&
            (identical(other.elevationLoss, elevationLoss) ||
                other.elevationLoss == elevationLoss) &&
            (identical(
                    other.estimatedDurationMinutes, estimatedDurationMinutes) ||
                other.estimatedDurationMinutes == estimatedDurationMinutes) &&
            (identical(other.difficulty, difficulty) ||
                other.difficulty == difficulty) &&
            (identical(other.orderIndex, orderIndex) ||
                other.orderIndex == orderIndex) &&
            (identical(other.startLat, startLat) ||
                other.startLat == startLat) &&
            (identical(other.startLng, startLng) ||
                other.startLng == startLng) &&
            (identical(other.endLat, endLat) || other.endLat == endLat) &&
            (identical(other.endLng, endLng) || other.endLng == endLng) &&
            (identical(other.descriptionFr, descriptionFr) ||
                other.descriptionFr == descriptionFr) &&
            (identical(other.descriptionEn, descriptionEn) ||
                other.descriptionEn == descriptionEn) &&
            (identical(other.descriptionDe, descriptionDe) ||
                other.descriptionDe == descriptionDe) &&
            (identical(other.descriptionIt, descriptionIt) ||
                other.descriptionIt == descriptionIt) &&
            (identical(other.descriptionEs, descriptionEs) ||
                other.descriptionEs == descriptionEs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        nameFr,
        nameEn,
        nameDe,
        nameIt,
        nameEs,
        distance,
        elevationGain,
        elevationLoss,
        estimatedDurationMinutes,
        difficulty,
        orderIndex,
        startLat,
        startLng,
        endLat,
        endLng,
        descriptionFr,
        descriptionEn,
        descriptionDe,
        descriptionIt,
        descriptionEs
      ]);

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StageImplCopyWith<_$StageImpl> get copyWith =>
      __$$StageImplCopyWithImpl<_$StageImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StageImplToJson(
      this,
    );
  }
}

abstract class _Stage extends Stage {
  const factory _Stage(
      {required final String id,
      required final String nameFr,
      required final String nameEn,
      final String nameDe,
      final String nameIt,
      final String nameEs,
      required final double distance,
      required final int elevationGain,
      required final int elevationLoss,
      required final int estimatedDurationMinutes,
      final String difficulty,
      required final int orderIndex,
      required final double startLat,
      required final double startLng,
      required final double endLat,
      required final double endLng,
      final String descriptionFr,
      final String descriptionEn,
      final String descriptionDe,
      final String descriptionIt,
      final String descriptionEs}) = _$StageImpl;
  const _Stage._() : super._();

  factory _Stage.fromJson(Map<String, dynamic> json) = _$StageImpl.fromJson;

  /// Identifiant unique de l'etape
  @override
  String get id;

  /// Nom en francais
  @override
  String get nameFr;

  /// Nom en anglais
  @override
  String get nameEn;

  /// Nom en allemand
  @override
  String get nameDe;

  /// Nom en italien
  @override
  String get nameIt;

  /// Nom en espagnol
  @override
  String get nameEs;

  /// Distance en kilometres
  @override
  double get distance;

  /// Denivele positif en metres
  @override
  int get elevationGain;

  /// Denivele negatif en metres
  @override
  int get elevationLoss;

  /// Duree estimee en minutes (serialise en int pour JSON)
  @override
  int get estimatedDurationMinutes;

  /// Difficulte — String libre, pas enum (#81752)
  /// Valeurs courantes : easy, moderate, hard, extreme
  @override
  String get difficulty;

  /// Ordre d'affichage
  @override
  int get orderIndex;

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

  /// Description en francais
  @override
  String get descriptionFr;

  /// Description en anglais
  @override
  String get descriptionEn;

  /// Description en allemand
  @override
  String get descriptionDe;

  /// Description en italien
  @override
  String get descriptionIt;

  /// Description en espagnol
  @override
  String get descriptionEs;

  /// Create a copy of Stage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StageImplCopyWith<_$StageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
