// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trek_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TrekSession _$TrekSessionFromJson(Map<String, dynamic> json) {
  return _TrekSession.fromJson(json);
}

/// @nodoc
mixin _$TrekSession {
  /// Identifiant unique (UUID)
  String get id => throw _privateConstructorUsedError;

  /// Identifiant du sentier parcouru
  String get trailId => throw _privateConstructorUsedError;

  /// Date/heure de debut
  DateTime get startedAt => throw _privateConstructorUsedError;

  /// Date/heure de fin (null si en cours)
  DateTime? get finishedAt => throw _privateConstructorUsedError;

  /// Statut — String extensible (active, paused, completed, abandoned, ...)
  String get status => throw _privateConstructorUsedError;

  /// Serializes this TrekSession to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TrekSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TrekSessionCopyWith<TrekSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TrekSessionCopyWith<$Res> {
  factory $TrekSessionCopyWith(
          TrekSession value, $Res Function(TrekSession) then) =
      _$TrekSessionCopyWithImpl<$Res, TrekSession>;
  @useResult
  $Res call(
      {String id,
      String trailId,
      DateTime startedAt,
      DateTime? finishedAt,
      String status});
}

/// @nodoc
class _$TrekSessionCopyWithImpl<$Res, $Val extends TrekSession>
    implements $TrekSessionCopyWith<$Res> {
  _$TrekSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TrekSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? startedAt = null,
    Object? finishedAt = freezed,
    Object? status = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      trailId: null == trailId
          ? _value.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TrekSessionImplCopyWith<$Res>
    implements $TrekSessionCopyWith<$Res> {
  factory _$$TrekSessionImplCopyWith(
          _$TrekSessionImpl value, $Res Function(_$TrekSessionImpl) then) =
      __$$TrekSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String trailId,
      DateTime startedAt,
      DateTime? finishedAt,
      String status});
}

/// @nodoc
class __$$TrekSessionImplCopyWithImpl<$Res>
    extends _$TrekSessionCopyWithImpl<$Res, _$TrekSessionImpl>
    implements _$$TrekSessionImplCopyWith<$Res> {
  __$$TrekSessionImplCopyWithImpl(
      _$TrekSessionImpl _value, $Res Function(_$TrekSessionImpl) _then)
      : super(_value, _then);

  /// Create a copy of TrekSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? trailId = null,
    Object? startedAt = null,
    Object? finishedAt = freezed,
    Object? status = null,
  }) {
    return _then(_$TrekSessionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      trailId: null == trailId
          ? _value.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      startedAt: null == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      finishedAt: freezed == finishedAt
          ? _value.finishedAt
          : finishedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TrekSessionImpl extends _TrekSession {
  const _$TrekSessionImpl(
      {required this.id,
      required this.trailId,
      required this.startedAt,
      this.finishedAt,
      this.status = "active"})
      : super._();

  factory _$TrekSessionImpl.fromJson(Map<String, dynamic> json) =>
      _$$TrekSessionImplFromJson(json);

  /// Identifiant unique (UUID)
  @override
  final String id;

  /// Identifiant du sentier parcouru
  @override
  final String trailId;

  /// Date/heure de debut
  @override
  final DateTime startedAt;

  /// Date/heure de fin (null si en cours)
  @override
  final DateTime? finishedAt;

  /// Statut — String extensible (active, paused, completed, abandoned, ...)
  @override
  @JsonKey()
  final String status;

  @override
  String toString() {
    return 'TrekSession(id: $id, trailId: $trailId, startedAt: $startedAt, finishedAt: $finishedAt, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TrekSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.finishedAt, finishedAt) ||
                other.finishedAt == finishedAt) &&
            (identical(other.status, status) || other.status == status));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, trailId, startedAt, finishedAt, status);

  /// Create a copy of TrekSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TrekSessionImplCopyWith<_$TrekSessionImpl> get copyWith =>
      __$$TrekSessionImplCopyWithImpl<_$TrekSessionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TrekSessionImplToJson(
      this,
    );
  }
}

abstract class _TrekSession extends TrekSession {
  const factory _TrekSession(
      {required final String id,
      required final String trailId,
      required final DateTime startedAt,
      final DateTime? finishedAt,
      final String status}) = _$TrekSessionImpl;
  const _TrekSession._() : super._();

  factory _TrekSession.fromJson(Map<String, dynamic> json) =
      _$TrekSessionImpl.fromJson;

  /// Identifiant unique (UUID)
  @override
  String get id;

  /// Identifiant du sentier parcouru
  @override
  String get trailId;

  /// Date/heure de debut
  @override
  DateTime get startedAt;

  /// Date/heure de fin (null si en cours)
  @override
  DateTime? get finishedAt;

  /// Statut — String extensible (active, paused, completed, abandoned, ...)
  @override
  String get status;

  /// Create a copy of TrekSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TrekSessionImplCopyWith<_$TrekSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
