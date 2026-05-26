// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Trail _$TrailFromJson(Map<String, dynamic> json) {
  return _Trail.fromJson(json);
}

/// @nodoc
mixin _$Trail {
  /// Identifiant unique (ex: 'mare_a_mare', 'tmb')
  String get id => throw _privateConstructorUsedError;

  /// Nom technique court (ex: 'Mare a Mare')
  String get name => throw _privateConstructorUsedError;

  /// Nom d'affichage dans l'app
  String get displayName => throw _privateConstructorUsedError;

  /// Accroche sous le nom
  String get tagline => throw _privateConstructorUsedError;

  /// Nombre total d'etapes
  int get totalStages => throw _privateConstructorUsedError;

  /// Distance totale en km
  double get totalDistanceKm => throw _privateConstructorUsedError;

  /// Denivele positif total en metres
  int get totalElevationGain => throw _privateConstructorUsedError;

  /// Region geographique
  String get region => throw _privateConstructorUsedError;

  /// Pays
  String get country => throw _privateConstructorUsedError;

  /// Serializes this Trail to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrailCopyWith<Trail> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrailCopyWith<$Res> {
  factory $TrailCopyWith(Trail value, $Res Function(Trail) then) =
      _$TrailCopyWithImpl<$Res, Trail>;
  @useResult
  $Res call(
      {String id,
      String name,
      String displayName,
      String tagline,
      int totalStages,
      double totalDistanceKm,
      int totalElevationGain,
      String region,
      String country});
}

/// @nodoc
class _$TrailCopyWithImpl<$Res, $Val extends Trail>
    implements $TrailCopyWith<$Res> {
  _$TrailCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? tagline = null,
    Object? totalStages = null,
    Object? totalDistanceKm = null,
    Object? totalElevationGain = null,
    Object? region = null,
    Object? country = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
      totalStages: null == totalStages
          ? _value.totalStages
          : totalStages // ignore: cast_nullable_to_non_nullable
              as int,
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGain: null == totalElevationGain
          ? _value.totalElevationGain
          : totalElevationGain // ignore: cast_nullable_to_non_nullable
              as int,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrailImplCopyWith<$Res> implements $TrailCopyWith<$Res> {
  factory _$$TrailImplCopyWith(
          _$TrailImpl value, $Res Function(_$TrailImpl) then) =
      __$$TrailImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String displayName,
      String tagline,
      int totalStages,
      double totalDistanceKm,
      int totalElevationGain,
      String region,
      String country});
}

/// @nodoc
class __$$TrailImplCopyWithImpl<$Res>
    extends _$TrailCopyWithImpl<$Res, _$TrailImpl>
    implements _$$TrailImplCopyWith<$Res> {
  __$$TrailImplCopyWithImpl(
      _$TrailImpl _value, $Res Function(_$TrailImpl) _then)
      : super(_value, _then);

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? displayName = null,
    Object? tagline = null,
    Object? totalStages = null,
    Object? totalDistanceKm = null,
    Object? totalElevationGain = null,
    Object? region = null,
    Object? country = null,
  }) {
    return _then(_$TrailImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
      totalStages: null == totalStages
          ? _value.totalStages
          : totalStages // ignore: cast_nullable_to_non_nullable
              as int,
      totalDistanceKm: null == totalDistanceKm
          ? _value.totalDistanceKm
          : totalDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      totalElevationGain: null == totalElevationGain
          ? _value.totalElevationGain
          : totalElevationGain // ignore: cast_nullable_to_non_nullable
              as int,
      region: null == region
          ? _value.region
          : region // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _value.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrailImpl implements _Trail {
  const _$TrailImpl(
      {required this.id,
      required this.name,
      required this.displayName,
      this.tagline = '',
      required this.totalStages,
      required this.totalDistanceKm,
      required this.totalElevationGain,
      required this.region,
      required this.country});

  factory _$TrailImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrailImplFromJson(json);

  /// Identifiant unique (ex: 'mare_a_mare', 'tmb')
  @override
  final String id;

  /// Nom technique court (ex: 'Mare a Mare')
  @override
  final String name;

  /// Nom d'affichage dans l'app
  @override
  final String displayName;

  /// Accroche sous le nom
  @override
  @JsonKey()
  final String tagline;

  /// Nombre total d'etapes
  @override
  final int totalStages;

  /// Distance totale en km
  @override
  final double totalDistanceKm;

  /// Denivele positif total en metres
  @override
  final int totalElevationGain;

  /// Region geographique
  @override
  final String region;

  /// Pays
  @override
  final String country;

  @override
  String toString() {
    return 'Trail(id: $id, name: $name, displayName: $displayName, tagline: $tagline, totalStages: $totalStages, totalDistanceKm: $totalDistanceKm, totalElevationGain: $totalElevationGain, region: $region, country: $country)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrailImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.tagline, tagline) || other.tagline == tagline) &&
            (identical(other.totalStages, totalStages) ||
                other.totalStages == totalStages) &&
            (identical(other.totalDistanceKm, totalDistanceKm) ||
                other.totalDistanceKm == totalDistanceKm) &&
            (identical(other.totalElevationGain, totalElevationGain) ||
                other.totalElevationGain == totalElevationGain) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.country, country) || other.country == country));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, displayName, tagline,
      totalStages, totalDistanceKm, totalElevationGain, region, country);

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrailImplCopyWith<_$TrailImpl> get copyWith =>
      __$$TrailImplCopyWithImpl<_$TrailImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrailImplToJson(
      this,
    );
  }
}

abstract class _Trail implements Trail {
  const factory _Trail(
      {required final String id,
      required final String name,
      required final String displayName,
      final String tagline,
      required final int totalStages,
      required final double totalDistanceKm,
      required final int totalElevationGain,
      required final String region,
      required final String country}) = _$TrailImpl;

  factory _Trail.fromJson(Map<String, dynamic> json) = _$TrailImpl.fromJson;

  /// Identifiant unique (ex: 'mare_a_mare', 'tmb')
  @override
  String get id;

  /// Nom technique court (ex: 'Mare a Mare')
  @override
  String get name;

  /// Nom d'affichage dans l'app
  @override
  String get displayName;

  /// Accroche sous le nom
  @override
  String get tagline;

  /// Nombre total d'etapes
  @override
  int get totalStages;

  /// Distance totale en km
  @override
  double get totalDistanceKm;

  /// Denivele positif total en metres
  @override
  int get totalElevationGain;

  /// Region geographique
  @override
  String get region;

  /// Pays
  @override
  String get country;

  /// Create a copy of Trail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrailImplCopyWith<_$TrailImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
