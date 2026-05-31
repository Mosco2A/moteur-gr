// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncConfig {

/// Intervalle en minutes entre deux syncs batch (defaut 60)
 int get batchIntervalMinutes;/// Sync automatique a l arrivee dans un refuge
 bool get syncOnRefugeArrival;/// Sync automatique au retour de la connectivite
 bool get syncOnReconnect;/// Nombre max de tentatives en cas d echec
 int get maxRetries;/// Timestamp ISO 8601 de la derniere sync reussie (nullable)
 String? get lastSyncTimestamp;
/// Create a copy of SyncConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncConfigCopyWith<SyncConfig> get copyWith => _$SyncConfigCopyWithImpl<SyncConfig>(this as SyncConfig, _$identity);

  /// Serializes this SyncConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncConfig&&(identical(other.batchIntervalMinutes, batchIntervalMinutes) || other.batchIntervalMinutes == batchIntervalMinutes)&&(identical(other.syncOnRefugeArrival, syncOnRefugeArrival) || other.syncOnRefugeArrival == syncOnRefugeArrival)&&(identical(other.syncOnReconnect, syncOnReconnect) || other.syncOnReconnect == syncOnReconnect)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.lastSyncTimestamp, lastSyncTimestamp) || other.lastSyncTimestamp == lastSyncTimestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,batchIntervalMinutes,syncOnRefugeArrival,syncOnReconnect,maxRetries,lastSyncTimestamp);

@override
String toString() {
  return 'SyncConfig(batchIntervalMinutes: $batchIntervalMinutes, syncOnRefugeArrival: $syncOnRefugeArrival, syncOnReconnect: $syncOnReconnect, maxRetries: $maxRetries, lastSyncTimestamp: $lastSyncTimestamp)';
}


}

/// @nodoc
abstract mixin class $SyncConfigCopyWith<$Res>  {
  factory $SyncConfigCopyWith(SyncConfig value, $Res Function(SyncConfig) _then) = _$SyncConfigCopyWithImpl;
@useResult
$Res call({
 int batchIntervalMinutes, bool syncOnRefugeArrival, bool syncOnReconnect, int maxRetries, String? lastSyncTimestamp
});




}
/// @nodoc
class _$SyncConfigCopyWithImpl<$Res>
    implements $SyncConfigCopyWith<$Res> {
  _$SyncConfigCopyWithImpl(this._self, this._then);

  final SyncConfig _self;
  final $Res Function(SyncConfig) _then;

/// Create a copy of SyncConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? batchIntervalMinutes = null,Object? syncOnRefugeArrival = null,Object? syncOnReconnect = null,Object? maxRetries = null,Object? lastSyncTimestamp = freezed,}) {
  return _then(_self.copyWith(
batchIntervalMinutes: null == batchIntervalMinutes ? _self.batchIntervalMinutes : batchIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,syncOnRefugeArrival: null == syncOnRefugeArrival ? _self.syncOnRefugeArrival : syncOnRefugeArrival // ignore: cast_nullable_to_non_nullable
as bool,syncOnReconnect: null == syncOnReconnect ? _self.syncOnReconnect : syncOnReconnect // ignore: cast_nullable_to_non_nullable
as bool,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,lastSyncTimestamp: freezed == lastSyncTimestamp ? _self.lastSyncTimestamp : lastSyncTimestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncConfig].
extension SyncConfigPatterns on SyncConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncConfig value)  $default,){
final _that = this;
switch (_that) {
case _SyncConfig():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncConfig value)?  $default,){
final _that = this;
switch (_that) {
case _SyncConfig() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int batchIntervalMinutes,  bool syncOnRefugeArrival,  bool syncOnReconnect,  int maxRetries,  String? lastSyncTimestamp)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncConfig() when $default != null:
return $default(_that.batchIntervalMinutes,_that.syncOnRefugeArrival,_that.syncOnReconnect,_that.maxRetries,_that.lastSyncTimestamp);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int batchIntervalMinutes,  bool syncOnRefugeArrival,  bool syncOnReconnect,  int maxRetries,  String? lastSyncTimestamp)  $default,) {final _that = this;
switch (_that) {
case _SyncConfig():
return $default(_that.batchIntervalMinutes,_that.syncOnRefugeArrival,_that.syncOnReconnect,_that.maxRetries,_that.lastSyncTimestamp);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int batchIntervalMinutes,  bool syncOnRefugeArrival,  bool syncOnReconnect,  int maxRetries,  String? lastSyncTimestamp)?  $default,) {final _that = this;
switch (_that) {
case _SyncConfig() when $default != null:
return $default(_that.batchIntervalMinutes,_that.syncOnRefugeArrival,_that.syncOnReconnect,_that.maxRetries,_that.lastSyncTimestamp);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncConfig implements SyncConfig {
  const _SyncConfig({this.batchIntervalMinutes = 60, this.syncOnRefugeArrival = true, this.syncOnReconnect = true, this.maxRetries = 3, this.lastSyncTimestamp});
  factory _SyncConfig.fromJson(Map<String, dynamic> json) => _$SyncConfigFromJson(json);

/// Intervalle en minutes entre deux syncs batch (defaut 60)
@override@JsonKey() final  int batchIntervalMinutes;
/// Sync automatique a l arrivee dans un refuge
@override@JsonKey() final  bool syncOnRefugeArrival;
/// Sync automatique au retour de la connectivite
@override@JsonKey() final  bool syncOnReconnect;
/// Nombre max de tentatives en cas d echec
@override@JsonKey() final  int maxRetries;
/// Timestamp ISO 8601 de la derniere sync reussie (nullable)
@override final  String? lastSyncTimestamp;

/// Create a copy of SyncConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncConfigCopyWith<_SyncConfig> get copyWith => __$SyncConfigCopyWithImpl<_SyncConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncConfig&&(identical(other.batchIntervalMinutes, batchIntervalMinutes) || other.batchIntervalMinutes == batchIntervalMinutes)&&(identical(other.syncOnRefugeArrival, syncOnRefugeArrival) || other.syncOnRefugeArrival == syncOnRefugeArrival)&&(identical(other.syncOnReconnect, syncOnReconnect) || other.syncOnReconnect == syncOnReconnect)&&(identical(other.maxRetries, maxRetries) || other.maxRetries == maxRetries)&&(identical(other.lastSyncTimestamp, lastSyncTimestamp) || other.lastSyncTimestamp == lastSyncTimestamp));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,batchIntervalMinutes,syncOnRefugeArrival,syncOnReconnect,maxRetries,lastSyncTimestamp);

@override
String toString() {
  return 'SyncConfig(batchIntervalMinutes: $batchIntervalMinutes, syncOnRefugeArrival: $syncOnRefugeArrival, syncOnReconnect: $syncOnReconnect, maxRetries: $maxRetries, lastSyncTimestamp: $lastSyncTimestamp)';
}


}

/// @nodoc
abstract mixin class _$SyncConfigCopyWith<$Res> implements $SyncConfigCopyWith<$Res> {
  factory _$SyncConfigCopyWith(_SyncConfig value, $Res Function(_SyncConfig) _then) = __$SyncConfigCopyWithImpl;
@override @useResult
$Res call({
 int batchIntervalMinutes, bool syncOnRefugeArrival, bool syncOnReconnect, int maxRetries, String? lastSyncTimestamp
});




}
/// @nodoc
class __$SyncConfigCopyWithImpl<$Res>
    implements _$SyncConfigCopyWith<$Res> {
  __$SyncConfigCopyWithImpl(this._self, this._then);

  final _SyncConfig _self;
  final $Res Function(_SyncConfig) _then;

/// Create a copy of SyncConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? batchIntervalMinutes = null,Object? syncOnRefugeArrival = null,Object? syncOnReconnect = null,Object? maxRetries = null,Object? lastSyncTimestamp = freezed,}) {
  return _then(_SyncConfig(
batchIntervalMinutes: null == batchIntervalMinutes ? _self.batchIntervalMinutes : batchIntervalMinutes // ignore: cast_nullable_to_non_nullable
as int,syncOnRefugeArrival: null == syncOnRefugeArrival ? _self.syncOnRefugeArrival : syncOnRefugeArrival // ignore: cast_nullable_to_non_nullable
as bool,syncOnReconnect: null == syncOnReconnect ? _self.syncOnReconnect : syncOnReconnect // ignore: cast_nullable_to_non_nullable
as bool,maxRetries: null == maxRetries ? _self.maxRetries : maxRetries // ignore: cast_nullable_to_non_nullable
as int,lastSyncTimestamp: freezed == lastSyncTimestamp ? _self.lastSyncTimestamp : lastSyncTimestamp // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
