// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StageModel {
  /// Cle primaire DB (0 si pas encore insere)
  int get id;

  /// Identifiant du sentier parent
  String get trailId;

  /// Numero de l'etape (1-indexed)
  int get stageNumber;

  /// Nom de l'etape
  String get name;

  /// Distance en km
  double get distanceKm;

  /// Denivele positif en metres
  int get elevationGainM;

  /// Denivele negatif en metres
  int get elevationLossM;

  /// Description textuelle
  String get description;

  /// Latitude du point de depart
  double get startLat;

  /// Longitude du point de depart
  double get startLng;

  /// Latitude du point d'arrivee
  double get endLat;

  /// Longitude du point d'arrivee
  double get endLng;

  /// Difficulte (easy, moderate, hard, extreme)
  String get difficulty;

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StageModelCopyWith<StageModel> get copyWith =>
      _$StageModelCopyWithImpl<StageModel>(this as StageModel, _$identity);

  /// Serializes this StageModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StageModel &&
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

  @override
  String toString() {
    return 'StageModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, distanceKm: $distanceKm, elevationGainM: $elevationGainM, elevationLossM: $elevationLossM, description: $description, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, difficulty: $difficulty)';
  }
}

/// @nodoc
abstract mixin class $StageModelCopyWith<$Res> {
  factory $StageModelCopyWith(
          StageModel value, $Res Function(StageModel) _then) =
      _$StageModelCopyWithImpl;
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
class _$StageModelCopyWithImpl<$Res> implements $StageModelCopyWith<$Res> {
  _$StageModelCopyWithImpl(this._self, this._then);

  final StageModel _self;
  final $Res Function(StageModel) _then;

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
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      stageNumber: null == stageNumber
          ? _self.stageNumber
          : stageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      distanceKm: null == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGainM: null == elevationGainM
          ? _self.elevationGainM
          : elevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLossM: null == elevationLossM
          ? _self.elevationLossM
          : elevationLossM // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      startLat: null == startLat
          ? _self.startLat
          : startLat // ignore: cast_nullable_to_non_nullable
              as double,
      startLng: null == startLng
          ? _self.startLng
          : startLng // ignore: cast_nullable_to_non_nullable
              as double,
      endLat: null == endLat
          ? _self.endLat
          : endLat // ignore: cast_nullable_to_non_nullable
              as double,
      endLng: null == endLng
          ? _self.endLng
          : endLng // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _self.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [StageModel].
extension StageModelPatterns on StageModel {
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
    TResult Function(_StageModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StageModel() when $default != null:
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
    TResult Function(_StageModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StageModel():
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
    TResult? Function(_StageModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StageModel() when $default != null:
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
            int id,
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
            String difficulty)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _StageModel() when $default != null:
        return $default(
            _that.id,
            _that.trailId,
            _that.stageNumber,
            _that.name,
            _that.distanceKm,
            _that.elevationGainM,
            _that.elevationLossM,
            _that.description,
            _that.startLat,
            _that.startLng,
            _that.endLat,
            _that.endLng,
            _that.difficulty);
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
            int id,
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
            String difficulty)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StageModel():
        return $default(
            _that.id,
            _that.trailId,
            _that.stageNumber,
            _that.name,
            _that.distanceKm,
            _that.elevationGainM,
            _that.elevationLossM,
            _that.description,
            _that.startLat,
            _that.startLng,
            _that.endLat,
            _that.endLng,
            _that.difficulty);
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
            int id,
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
            String difficulty)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _StageModel() when $default != null:
        return $default(
            _that.id,
            _that.trailId,
            _that.stageNumber,
            _that.name,
            _that.distanceKm,
            _that.elevationGainM,
            _that.elevationLossM,
            _that.description,
            _that.startLat,
            _that.startLng,
            _that.endLat,
            _that.endLng,
            _that.difficulty);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _StageModel extends StageModel {
  const _StageModel(
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
  factory _StageModel.fromJson(Map<String, dynamic> json) =>
      _$StageModelFromJson(json);

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

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StageModelCopyWith<_StageModel> get copyWith =>
      __$StageModelCopyWithImpl<_StageModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$StageModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StageModel &&
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

  @override
  String toString() {
    return 'StageModel(id: $id, trailId: $trailId, stageNumber: $stageNumber, name: $name, distanceKm: $distanceKm, elevationGainM: $elevationGainM, elevationLossM: $elevationLossM, description: $description, startLat: $startLat, startLng: $startLng, endLat: $endLat, endLng: $endLng, difficulty: $difficulty)';
  }
}

/// @nodoc
abstract mixin class _$StageModelCopyWith<$Res>
    implements $StageModelCopyWith<$Res> {
  factory _$StageModelCopyWith(
          _StageModel value, $Res Function(_StageModel) _then) =
      __$StageModelCopyWithImpl;
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
class __$StageModelCopyWithImpl<$Res> implements _$StageModelCopyWith<$Res> {
  __$StageModelCopyWithImpl(this._self, this._then);

  final _StageModel _self;
  final $Res Function(_StageModel) _then;

  /// Create a copy of StageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
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
    return _then(_StageModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      stageNumber: null == stageNumber
          ? _self.stageNumber
          : stageNumber // ignore: cast_nullable_to_non_nullable
              as int,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      distanceKm: null == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      elevationGainM: null == elevationGainM
          ? _self.elevationGainM
          : elevationGainM // ignore: cast_nullable_to_non_nullable
              as int,
      elevationLossM: null == elevationLossM
          ? _self.elevationLossM
          : elevationLossM // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      startLat: null == startLat
          ? _self.startLat
          : startLat // ignore: cast_nullable_to_non_nullable
              as double,
      startLng: null == startLng
          ? _self.startLng
          : startLng // ignore: cast_nullable_to_non_nullable
              as double,
      endLat: null == endLat
          ? _self.endLat
          : endLat // ignore: cast_nullable_to_non_nullable
              as double,
      endLng: null == endLng
          ? _self.endLng
          : endLng // ignore: cast_nullable_to_non_nullable
              as double,
      difficulty: null == difficulty
          ? _self.difficulty
          : difficulty // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
