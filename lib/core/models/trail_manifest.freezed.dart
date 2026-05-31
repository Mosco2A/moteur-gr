// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'trail_manifest.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrailManifest {
  /// Version du schema du manifeste
  int get schemaVersion;

  /// Liste des sentiers declares dans le manifeste
  List<TrailManifestEntry> get trails;

  /// Create a copy of TrailManifest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrailManifestCopyWith<TrailManifest> get copyWith =>
      _$TrailManifestCopyWithImpl<TrailManifest>(
          this as TrailManifest, _$identity);

  /// Serializes this TrailManifest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrailManifest &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            const DeepCollectionEquality().equals(other.trails, trails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, schemaVersion, const DeepCollectionEquality().hash(trails));

  @override
  String toString() {
    return 'TrailManifest(schemaVersion: $schemaVersion, trails: $trails)';
  }
}

/// @nodoc
abstract mixin class $TrailManifestCopyWith<$Res> {
  factory $TrailManifestCopyWith(
          TrailManifest value, $Res Function(TrailManifest) _then) =
      _$TrailManifestCopyWithImpl;
  @useResult
  $Res call({int schemaVersion, List<TrailManifestEntry> trails});
}

/// @nodoc
class _$TrailManifestCopyWithImpl<$Res>
    implements $TrailManifestCopyWith<$Res> {
  _$TrailManifestCopyWithImpl(this._self, this._then);

  final TrailManifest _self;
  final $Res Function(TrailManifest) _then;

  /// Create a copy of TrailManifest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? schemaVersion = null,
    Object? trails = null,
  }) {
    return _then(_self.copyWith(
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      trails: null == trails
          ? _self.trails
          : trails // ignore: cast_nullable_to_non_nullable
              as List<TrailManifestEntry>,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrailManifest].
extension TrailManifestPatterns on TrailManifest {
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
    TResult Function(_TrailManifest value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailManifest() when $default != null:
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
    TResult Function(_TrailManifest value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifest():
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
    TResult? Function(_TrailManifest value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifest() when $default != null:
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
    TResult Function(int schemaVersion, List<TrailManifestEntry> trails)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailManifest() when $default != null:
        return $default(_that.schemaVersion, _that.trails);
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
    TResult Function(int schemaVersion, List<TrailManifestEntry> trails)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifest():
        return $default(_that.schemaVersion, _that.trails);
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
    TResult? Function(int schemaVersion, List<TrailManifestEntry> trails)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifest() when $default != null:
        return $default(_that.schemaVersion, _that.trails);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TrailManifest implements TrailManifest {
  const _TrailManifest(
      {required this.schemaVersion,
      required final List<TrailManifestEntry> trails})
      : _trails = trails;
  factory _TrailManifest.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestFromJson(json);

  /// Version du schema du manifeste
  @override
  final int schemaVersion;

  /// Liste des sentiers declares dans le manifeste
  final List<TrailManifestEntry> _trails;

  /// Liste des sentiers declares dans le manifeste
  @override
  List<TrailManifestEntry> get trails {
    if (_trails is EqualUnmodifiableListView) return _trails;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_trails);
  }

  /// Create a copy of TrailManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrailManifestCopyWith<_TrailManifest> get copyWith =>
      __$TrailManifestCopyWithImpl<_TrailManifest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TrailManifestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrailManifest &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            const DeepCollectionEquality().equals(other._trails, _trails));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, schemaVersion, const DeepCollectionEquality().hash(_trails));

  @override
  String toString() {
    return 'TrailManifest(schemaVersion: $schemaVersion, trails: $trails)';
  }
}

/// @nodoc
abstract mixin class _$TrailManifestCopyWith<$Res>
    implements $TrailManifestCopyWith<$Res> {
  factory _$TrailManifestCopyWith(
          _TrailManifest value, $Res Function(_TrailManifest) _then) =
      __$TrailManifestCopyWithImpl;
  @override
  @useResult
  $Res call({int schemaVersion, List<TrailManifestEntry> trails});
}

/// @nodoc
class __$TrailManifestCopyWithImpl<$Res>
    implements _$TrailManifestCopyWith<$Res> {
  __$TrailManifestCopyWithImpl(this._self, this._then);

  final _TrailManifest _self;
  final $Res Function(_TrailManifest) _then;

  /// Create a copy of TrailManifest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? schemaVersion = null,
    Object? trails = null,
  }) {
    return _then(_TrailManifest(
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      trails: null == trails
          ? _self._trails
          : trails // ignore: cast_nullable_to_non_nullable
              as List<TrailManifestEntry>,
    ));
  }
}

/// @nodoc
mixin _$TrailManifestEntry {
  /// Identifiant unique du sentier (ex: 'gr20', 'mare_a_mare')
  String get trailId;

  /// Version des donnees (incremente a chaque publication serveur)
  int get dataVersion;

  /// Hash SHA-256 du fichier de donnees
  String get hash;

  /// Chemin relatif du fichier de donnees sur le serveur
  String get filePath;

  /// Taille du fichier en octets
  int get fileSize;

  /// Statut du sentier ('active', 'draft', 'archived')
  String get status;

  /// Date de derniere mise a jour (ISO 8601)
  String get lastUpdated;

  /// Create a copy of TrailManifestEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrailManifestEntryCopyWith<TrailManifestEntry> get copyWith =>
      _$TrailManifestEntryCopyWithImpl<TrailManifestEntry>(
          this as TrailManifestEntry, _$identity);

  /// Serializes this TrailManifestEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrailManifestEntry &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.dataVersion, dataVersion) ||
                other.dataVersion == dataVersion) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, trailId, dataVersion, hash,
      filePath, fileSize, status, lastUpdated);

  @override
  String toString() {
    return 'TrailManifestEntry(trailId: $trailId, dataVersion: $dataVersion, hash: $hash, filePath: $filePath, fileSize: $fileSize, status: $status, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class $TrailManifestEntryCopyWith<$Res> {
  factory $TrailManifestEntryCopyWith(
          TrailManifestEntry value, $Res Function(TrailManifestEntry) _then) =
      _$TrailManifestEntryCopyWithImpl;
  @useResult
  $Res call(
      {String trailId,
      int dataVersion,
      String hash,
      String filePath,
      int fileSize,
      String status,
      String lastUpdated});
}

/// @nodoc
class _$TrailManifestEntryCopyWithImpl<$Res>
    implements $TrailManifestEntryCopyWith<$Res> {
  _$TrailManifestEntryCopyWithImpl(this._self, this._then);

  final TrailManifestEntry _self;
  final $Res Function(TrailManifestEntry) _then;

  /// Create a copy of TrailManifestEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? trailId = null,
    Object? dataVersion = null,
    Object? hash = null,
    Object? filePath = null,
    Object? fileSize = null,
    Object? status = null,
    Object? lastUpdated = null,
  }) {
    return _then(_self.copyWith(
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      dataVersion: null == dataVersion
          ? _self.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as int,
      hash: null == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrailManifestEntry].
extension TrailManifestEntryPatterns on TrailManifestEntry {
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
    TResult Function(_TrailManifestEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry() when $default != null:
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
    TResult Function(_TrailManifestEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry():
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
    TResult? Function(_TrailManifestEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry() when $default != null:
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
    TResult Function(String trailId, int dataVersion, String hash,
            String filePath, int fileSize, String status, String lastUpdated)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry() when $default != null:
        return $default(_that.trailId, _that.dataVersion, _that.hash,
            _that.filePath, _that.fileSize, _that.status, _that.lastUpdated);
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
    TResult Function(String trailId, int dataVersion, String hash,
            String filePath, int fileSize, String status, String lastUpdated)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry():
        return $default(_that.trailId, _that.dataVersion, _that.hash,
            _that.filePath, _that.fileSize, _that.status, _that.lastUpdated);
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
    TResult? Function(String trailId, int dataVersion, String hash,
            String filePath, int fileSize, String status, String lastUpdated)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrailManifestEntry() when $default != null:
        return $default(_that.trailId, _that.dataVersion, _that.hash,
            _that.filePath, _that.fileSize, _that.status, _that.lastUpdated);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TrailManifestEntry implements TrailManifestEntry {
  const _TrailManifestEntry(
      {required this.trailId,
      required this.dataVersion,
      required this.hash,
      required this.filePath,
      required this.fileSize,
      required this.status,
      required this.lastUpdated});
  factory _TrailManifestEntry.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestEntryFromJson(json);

  /// Identifiant unique du sentier (ex: 'gr20', 'mare_a_mare')
  @override
  final String trailId;

  /// Version des donnees (incremente a chaque publication serveur)
  @override
  final int dataVersion;

  /// Hash SHA-256 du fichier de donnees
  @override
  final String hash;

  /// Chemin relatif du fichier de donnees sur le serveur
  @override
  final String filePath;

  /// Taille du fichier en octets
  @override
  final int fileSize;

  /// Statut du sentier ('active', 'draft', 'archived')
  @override
  final String status;

  /// Date de derniere mise a jour (ISO 8601)
  @override
  final String lastUpdated;

  /// Create a copy of TrailManifestEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrailManifestEntryCopyWith<_TrailManifestEntry> get copyWith =>
      __$TrailManifestEntryCopyWithImpl<_TrailManifestEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TrailManifestEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrailManifestEntry &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.dataVersion, dataVersion) ||
                other.dataVersion == dataVersion) &&
            (identical(other.hash, hash) || other.hash == hash) &&
            (identical(other.filePath, filePath) ||
                other.filePath == filePath) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, trailId, dataVersion, hash,
      filePath, fileSize, status, lastUpdated);

  @override
  String toString() {
    return 'TrailManifestEntry(trailId: $trailId, dataVersion: $dataVersion, hash: $hash, filePath: $filePath, fileSize: $fileSize, status: $status, lastUpdated: $lastUpdated)';
  }
}

/// @nodoc
abstract mixin class _$TrailManifestEntryCopyWith<$Res>
    implements $TrailManifestEntryCopyWith<$Res> {
  factory _$TrailManifestEntryCopyWith(
          _TrailManifestEntry value, $Res Function(_TrailManifestEntry) _then) =
      __$TrailManifestEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String trailId,
      int dataVersion,
      String hash,
      String filePath,
      int fileSize,
      String status,
      String lastUpdated});
}

/// @nodoc
class __$TrailManifestEntryCopyWithImpl<$Res>
    implements _$TrailManifestEntryCopyWith<$Res> {
  __$TrailManifestEntryCopyWithImpl(this._self, this._then);

  final _TrailManifestEntry _self;
  final $Res Function(_TrailManifestEntry) _then;

  /// Create a copy of TrailManifestEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? trailId = null,
    Object? dataVersion = null,
    Object? hash = null,
    Object? filePath = null,
    Object? fileSize = null,
    Object? status = null,
    Object? lastUpdated = null,
  }) {
    return _then(_TrailManifestEntry(
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      dataVersion: null == dataVersion
          ? _self.dataVersion
          : dataVersion // ignore: cast_nullable_to_non_nullable
              as int,
      hash: null == hash
          ? _self.hash
          : hash // ignore: cast_nullable_to_non_nullable
              as String,
      filePath: null == filePath
          ? _self.filePath
          : filePath // ignore: cast_nullable_to_non_nullable
              as String,
      fileSize: null == fileSize
          ? _self.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      lastUpdated: null == lastUpdated
          ? _self.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
