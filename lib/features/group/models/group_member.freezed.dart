// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupMember {
  String get uid;
  String? get displayName;
  double get lastLat;
  double get lastLng;
  String get lastUpdate;
  String? get currentStageId;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupMemberCopyWith<GroupMember> get copyWith =>
      _$GroupMemberCopyWithImpl<GroupMember>(this as GroupMember, _$identity);

  /// Serializes this GroupMember to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupMember &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.lastLat, lastLat) || other.lastLat == lastLat) &&
            (identical(other.lastLng, lastLng) || other.lastLng == lastLng) &&
            (identical(other.lastUpdate, lastUpdate) ||
                other.lastUpdate == lastUpdate) &&
            (identical(other.currentStageId, currentStageId) ||
                other.currentStageId == currentStageId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, displayName, lastLat,
      lastLng, lastUpdate, currentStageId);

  @override
  String toString() {
    return 'GroupMember(uid: $uid, displayName: $displayName, lastLat: $lastLat, lastLng: $lastLng, lastUpdate: $lastUpdate, currentStageId: $currentStageId)';
  }
}

/// @nodoc
abstract mixin class $GroupMemberCopyWith<$Res> {
  factory $GroupMemberCopyWith(
          GroupMember value, $Res Function(GroupMember) _then) =
      _$GroupMemberCopyWithImpl;
  @useResult
  $Res call(
      {String uid,
      String? displayName,
      double lastLat,
      double lastLng,
      String lastUpdate,
      String? currentStageId});
}

/// @nodoc
class _$GroupMemberCopyWithImpl<$Res> implements $GroupMemberCopyWith<$Res> {
  _$GroupMemberCopyWithImpl(this._self, this._then);

  final GroupMember _self;
  final $Res Function(GroupMember) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = freezed,
    Object? lastLat = null,
    Object? lastLng = null,
    Object? lastUpdate = null,
    Object? currentStageId = freezed,
  }) {
    return _then(_self.copyWith(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLat: null == lastLat
          ? _self.lastLat
          : lastLat // ignore: cast_nullable_to_non_nullable
              as double,
      lastLng: null == lastLng
          ? _self.lastLng
          : lastLng // ignore: cast_nullable_to_non_nullable
              as double,
      lastUpdate: null == lastUpdate
          ? _self.lastUpdate
          : lastUpdate // ignore: cast_nullable_to_non_nullable
              as String,
      currentStageId: freezed == currentStageId
          ? _self.currentStageId
          : currentStageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [GroupMember].
extension GroupMemberPatterns on GroupMember {
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
    TResult Function(_GroupMember value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
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
    TResult Function(_GroupMember value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember():
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
    TResult? Function(_GroupMember value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
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
    TResult Function(String uid, String? displayName, double lastLat,
            double lastLng, String lastUpdate, String? currentStageId)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
        return $default(_that.uid, _that.displayName, _that.lastLat,
            _that.lastLng, _that.lastUpdate, _that.currentStageId);
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
    TResult Function(String uid, String? displayName, double lastLat,
            double lastLng, String lastUpdate, String? currentStageId)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember():
        return $default(_that.uid, _that.displayName, _that.lastLat,
            _that.lastLng, _that.lastUpdate, _that.currentStageId);
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
    TResult? Function(String uid, String? displayName, double lastLat,
            double lastLng, String lastUpdate, String? currentStageId)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupMember() when $default != null:
        return $default(_that.uid, _that.displayName, _that.lastLat,
            _that.lastLng, _that.lastUpdate, _that.currentStageId);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GroupMember implements GroupMember {
  const _GroupMember(
      {required this.uid,
      this.displayName,
      required this.lastLat,
      required this.lastLng,
      required this.lastUpdate,
      this.currentStageId});
  factory _GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);

  @override
  final String uid;
  @override
  final String? displayName;
  @override
  final double lastLat;
  @override
  final double lastLng;
  @override
  final String lastUpdate;
  @override
  final String? currentStageId;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupMemberCopyWith<_GroupMember> get copyWith =>
      __$GroupMemberCopyWithImpl<_GroupMember>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupMemberToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupMember &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.lastLat, lastLat) || other.lastLat == lastLat) &&
            (identical(other.lastLng, lastLng) || other.lastLng == lastLng) &&
            (identical(other.lastUpdate, lastUpdate) ||
                other.lastUpdate == lastUpdate) &&
            (identical(other.currentStageId, currentStageId) ||
                other.currentStageId == currentStageId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, uid, displayName, lastLat,
      lastLng, lastUpdate, currentStageId);

  @override
  String toString() {
    return 'GroupMember(uid: $uid, displayName: $displayName, lastLat: $lastLat, lastLng: $lastLng, lastUpdate: $lastUpdate, currentStageId: $currentStageId)';
  }
}

/// @nodoc
abstract mixin class _$GroupMemberCopyWith<$Res>
    implements $GroupMemberCopyWith<$Res> {
  factory _$GroupMemberCopyWith(
          _GroupMember value, $Res Function(_GroupMember) _then) =
      __$GroupMemberCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String uid,
      String? displayName,
      double lastLat,
      double lastLng,
      String lastUpdate,
      String? currentStageId});
}

/// @nodoc
class __$GroupMemberCopyWithImpl<$Res> implements _$GroupMemberCopyWith<$Res> {
  __$GroupMemberCopyWithImpl(this._self, this._then);

  final _GroupMember _self;
  final $Res Function(_GroupMember) _then;

  /// Create a copy of GroupMember
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? uid = null,
    Object? displayName = freezed,
    Object? lastLat = null,
    Object? lastLng = null,
    Object? lastUpdate = null,
    Object? currentStageId = freezed,
  }) {
    return _then(_GroupMember(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastLat: null == lastLat
          ? _self.lastLat
          : lastLat // ignore: cast_nullable_to_non_nullable
              as double,
      lastLng: null == lastLng
          ? _self.lastLng
          : lastLng // ignore: cast_nullable_to_non_nullable
              as double,
      lastUpdate: null == lastUpdate
          ? _self.lastUpdate
          : lastUpdate // ignore: cast_nullable_to_non_nullable
              as String,
      currentStageId: freezed == currentStageId
          ? _self.currentStageId
          : currentStageId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
mixin _$GroupInfo {
  String get groupCode;
  String get trailId;
  String get createdBy;
  List<GroupMember> get members;
  int get maxFreeWatchers;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $GroupInfoCopyWith<GroupInfo> get copyWith =>
      _$GroupInfoCopyWithImpl<GroupInfo>(this as GroupInfo, _$identity);

  /// Serializes this GroupInfo to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is GroupInfo &&
            (identical(other.groupCode, groupCode) ||
                other.groupCode == groupCode) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other.members, members) &&
            (identical(other.maxFreeWatchers, maxFreeWatchers) ||
                other.maxFreeWatchers == maxFreeWatchers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupCode, trailId, createdBy,
      const DeepCollectionEquality().hash(members), maxFreeWatchers);

  @override
  String toString() {
    return 'GroupInfo(groupCode: $groupCode, trailId: $trailId, createdBy: $createdBy, members: $members, maxFreeWatchers: $maxFreeWatchers)';
  }
}

/// @nodoc
abstract mixin class $GroupInfoCopyWith<$Res> {
  factory $GroupInfoCopyWith(GroupInfo value, $Res Function(GroupInfo) _then) =
      _$GroupInfoCopyWithImpl;
  @useResult
  $Res call(
      {String groupCode,
      String trailId,
      String createdBy,
      List<GroupMember> members,
      int maxFreeWatchers});
}

/// @nodoc
class _$GroupInfoCopyWithImpl<$Res> implements $GroupInfoCopyWith<$Res> {
  _$GroupInfoCopyWithImpl(this._self, this._then);

  final GroupInfo _self;
  final $Res Function(GroupInfo) _then;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupCode = null,
    Object? trailId = null,
    Object? createdBy = null,
    Object? members = null,
    Object? maxFreeWatchers = null,
  }) {
    return _then(_self.copyWith(
      groupCode: null == groupCode
          ? _self.groupCode
          : groupCode // ignore: cast_nullable_to_non_nullable
              as String,
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _self.members
          : members // ignore: cast_nullable_to_non_nullable
              as List<GroupMember>,
      maxFreeWatchers: null == maxFreeWatchers
          ? _self.maxFreeWatchers
          : maxFreeWatchers // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [GroupInfo].
extension GroupInfoPatterns on GroupInfo {
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
    TResult Function(_GroupInfo value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
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
    TResult Function(_GroupInfo value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo():
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
    TResult? Function(_GroupInfo value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
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
    TResult Function(String groupCode, String trailId, String createdBy,
            List<GroupMember> members, int maxFreeWatchers)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
        return $default(_that.groupCode, _that.trailId, _that.createdBy,
            _that.members, _that.maxFreeWatchers);
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
    TResult Function(String groupCode, String trailId, String createdBy,
            List<GroupMember> members, int maxFreeWatchers)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo():
        return $default(_that.groupCode, _that.trailId, _that.createdBy,
            _that.members, _that.maxFreeWatchers);
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
    TResult? Function(String groupCode, String trailId, String createdBy,
            List<GroupMember> members, int maxFreeWatchers)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _GroupInfo() when $default != null:
        return $default(_that.groupCode, _that.trailId, _that.createdBy,
            _that.members, _that.maxFreeWatchers);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _GroupInfo implements GroupInfo {
  const _GroupInfo(
      {required this.groupCode,
      required this.trailId,
      required this.createdBy,
      required final List<GroupMember> members,
      this.maxFreeWatchers = 2})
      : _members = members;
  factory _GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);

  @override
  final String groupCode;
  @override
  final String trailId;
  @override
  final String createdBy;
  final List<GroupMember> _members;
  @override
  List<GroupMember> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  @JsonKey()
  final int maxFreeWatchers;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$GroupInfoCopyWith<_GroupInfo> get copyWith =>
      __$GroupInfoCopyWithImpl<_GroupInfo>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$GroupInfoToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _GroupInfo &&
            (identical(other.groupCode, groupCode) ||
                other.groupCode == groupCode) &&
            (identical(other.trailId, trailId) || other.trailId == trailId) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.maxFreeWatchers, maxFreeWatchers) ||
                other.maxFreeWatchers == maxFreeWatchers));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupCode, trailId, createdBy,
      const DeepCollectionEquality().hash(_members), maxFreeWatchers);

  @override
  String toString() {
    return 'GroupInfo(groupCode: $groupCode, trailId: $trailId, createdBy: $createdBy, members: $members, maxFreeWatchers: $maxFreeWatchers)';
  }
}

/// @nodoc
abstract mixin class _$GroupInfoCopyWith<$Res>
    implements $GroupInfoCopyWith<$Res> {
  factory _$GroupInfoCopyWith(
          _GroupInfo value, $Res Function(_GroupInfo) _then) =
      __$GroupInfoCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String groupCode,
      String trailId,
      String createdBy,
      List<GroupMember> members,
      int maxFreeWatchers});
}

/// @nodoc
class __$GroupInfoCopyWithImpl<$Res> implements _$GroupInfoCopyWith<$Res> {
  __$GroupInfoCopyWithImpl(this._self, this._then);

  final _GroupInfo _self;
  final $Res Function(_GroupInfo) _then;

  /// Create a copy of GroupInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groupCode = null,
    Object? trailId = null,
    Object? createdBy = null,
    Object? members = null,
    Object? maxFreeWatchers = null,
  }) {
    return _then(_GroupInfo(
      groupCode: null == groupCode
          ? _self.groupCode
          : groupCode // ignore: cast_nullable_to_non_nullable
              as String,
      trailId: null == trailId
          ? _self.trailId
          : trailId // ignore: cast_nullable_to_non_nullable
              as String,
      createdBy: null == createdBy
          ? _self.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String,
      members: null == members
          ? _self._members
          : members // ignore: cast_nullable_to_non_nullable
              as List<GroupMember>,
      maxFreeWatchers: null == maxFreeWatchers
          ? _self.maxFreeWatchers
          : maxFreeWatchers // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
