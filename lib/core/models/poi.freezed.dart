// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'poi.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PoiModel _$PoiModelFromJson(Map<String, dynamic> json) {
  return _PoiModel.fromJson(json);
}

/// @nodoc
mixin _$PoiModel {
  /// Cle primaire DB (0 si pas encore insere)
  int get id => throw _privateConstructorUsedError;

  /// Identifiant du sentier parent
  String get trailId => throw _privateConstructorUsedError;

  /// Numero de l'etape associee
  int get stageNumber => throw _privateConstructorUsedError;

  /// Nom du POI
  String get name => throw _privateConstructorUsedError;

  /// Description
  String get description => throw _privateConstructorUsedError;

  /// Type de POI (String extensible, ex: water, refuge, danger)
  String get type => throw _privateConstructorUsedError;

  /// Latitude
  double get lat => throw _privateConstructorUsedError;

  /// Longitude
  double get lng => throw _privateConstructorUsedError;

  /// Altitude en metres
  int get altitudeM => throw _privateConstructorUsedError;

  /// Horaires d'ouverture (nullable)
  String? get openingHours => throw _privateConstructorUsedError;

  /// Serializes this PoiModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PoiModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PoiModelCopyWith<PoiModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PoiModelCopyWith<$Res> {
  factory $PoiModelCopyWith(PoiModel value, $Res Function(PoiModel) then) =
      _$PoiModelCopyWithImpl<$Res, PoiModel>;
  @useResult
  $Res call(
      {int id,
      String trailId,
      int stageNumber,
      String name,
      String description,
      String type,
      double lat,
      double lng,
      int altitudeM,
      String? openingHours});
}

/// @nodoc
class _$PoiModelCopyWithImpl<$Res, $Val extends PoiModel>
    implements $PoiModelCopyWith<$Res> {
  _$PoiModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PoiModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? stageNumber = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? lat = null,
    Object? lng = null,
    Object? altitudeM = null,
    Object? openingHours = freezed,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      altitudeM: null == altitudeM
          ? _value.altitudeM
          : altitudeM // ignore: cast_nullable_to_non_nullable
              as int,
      openingHours: freezed == openingHours
          ? _value.openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PoiModelImplCopyWith<$Res>
    implements $PoiModelCopyWith<$Res> {
  factory _$$PoiModelImplCopyWith(
          _$PoiModelImpl value, $Res Function(_$PoiModelImpl) then) =
      __$$PoiModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String trailId,
      int stageNumber,
      String name,
      String description,
      String type,
      double lat,
      double lng,
      int altitudeM,
      String? openingHours});
}

/// @nodoc
class __$$PoiModelImplCopyWithImpl<$Res>
    extends _$PoiModelCopyWithImpl<$Res, _$PoiModelImpl>
    implements _$$PoiModelImplCopyWith<$Res> {
  __$$PoiModelImplCopyWithImpl(
      _$PoiModelImpl _value, $Res Function(_$PoiModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PoiModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? stageNumber = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? lat = null,
    Object? lng = null,
    Object? altitudeM = null,
    Object? openingHours = freezed,
  }) {
    return _then(_$PoiModelImpl(
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      lat: null == lat
          ? _value.lat
          : lat // ignore: cast_nullable_to_non_nullable
              as double,
      lng: null == lng
          ? _value.lng
          : lng // ignore: cast_nullable_to_non_nullable
              as double,
      altitudeM: null == altitudeM
          ? _value.altitudeM
          : altitudeM // ignore: cast_nullable_to_non_nullable
              as int,
      openingHours: freezed == openingHours
          ? _value.openingHours
          : openingHours // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PoiModelImpl extends _PoiModel {
  const _$PoiModelImpl(
      {this.id = 0,
      required this.trailId,
      required this.stageNumber,
      required this.name,
      this.description = '',
      required this.type,
      required this.lat,
      required this.lng,
      this.altitudeM = 0,
      this.openingHours})
      : super._();

  factory _$PoiModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PoiModelImplFromJson(json);

  /// Cle primaire DB (0 si pas encore insere)
  @override
  @JsonKey()
  final int id;

  /// Identifiant du sentier parent
  @override
  final String trailId;

  /// Numero de l'etape associee
  @override
  final int stageNumber;

  /// Nom du POI
  @override
  final String name;

  /// Description
  @override
  @JsonKey()
  final String description;

  /// Type de POI (String extensible, ex: water, refuge, danger)
  @override
  final String type;

  /// Latitude
  @override
  final double lat;

  /// Longitude
  @override
  final double lng;

  /// Altitude en metres
  @override
  @JsonKey()
  final int altitudeM;

  /// Horaires d'ouverture (nullable)
  @override
  final String? openingHours;

  @override
  String toString() {
    return 'PoiModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, description: $description, type: $type, lat: $lat, lng: $lng, altitudeM: $altitudeM, openingHours: $openingHours)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PoiModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.stageNumber, stageNumber) ||
                other.stageNumber == stageNumber) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.lat, lat) || other.lat == lat) &&
            (identical(other.lng, lng) || other.lng == lng) &&
            (identical(other.altitudeM, altitudeM) ||
                other.altitudeM == altitudeM) &&
            (identical(other.openingHours, openingHours) ||
                other.openingHours == openingHours));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, trailId, stageNumber, name,
      description, type, lat, lng, altitudeM, openingHours);

  /// Create a copy of PoiModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PoiModelImplCopyWith<_$PoiModelImpl> get copyWith =>
      __$$PoiModelImplCopyWithImpl<_$PoiModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PoiModelImplToJson(
      this,
    );
  }
}

abstract class _PoiModel extends PoiModel {
  const factory _PoiModel(
      {final int id,
      required final String trailId,
      required final int stageNumber,
      required final String name,
      final String description,
      required final String type,
      required final double lat,
      required final double lng,
      final int altitudeM,
      final String? openingHours}) = _$PoiModelImpl;
  const _PoiModel._() : super._();

  factory _PoiModel.fromJson(Map<String, dynamic> json) =
      _$PoiModelImpl.fromJson;

  /// Cle primaire DB (0 si pas encore insere)
  @override
  int get id;

  /// Identifiant du sentier parent
  @override
  String get trailId;

  /// Numero de l'etape associee
  @override
  int get stageNumber;

  /// Nom du POI
  @override
  String get name;

  /// Description
  @override
  String get description;

  /// Type de POI (String extensible, ex: water, refuge, danger)
  @override
  String get type;

  /// Latitude
  @override
  double get lat;

  /// Longitude
  @override
  double get lng;

  /// Altitude en metres
  @override
  int get altitudeM;

  /// Horaires d'ouverture (nullable)
  @override
  String? get openingHours;

  /// Create a copy of PoiModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PoiModelImplCopyWith<_$PoiModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
