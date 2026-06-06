// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tip_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TipCard {

/// Identifiant unique de la fiche conseil
 String get id;/// Titre -- francais
 String get titleFr;/// Titre -- anglais
 String get titleEn;/// Titre -- allemand
 String get titleDe;/// Titre -- italien
 String get titleIt;/// Titre -- espagnol
 String get titleEs;/// Contenu -- francais
 String get contentFr;/// Contenu -- anglais
 String get contentEn;/// Contenu -- allemand
 String get contentDe;/// Contenu -- italien
 String get contentIt;/// Contenu -- espagnol
 String get contentEs;/// Perimetre du conseil -- String extensible (gr10, tmb, all, ...)
 String get scope;/// Saison de pertinence -- String extensible (summer, winter, spring, autumn, all, ...)
 String get season;/// Categorie du conseil -- String extensible (preparation, equipment, nutrition, safety, nature, recovery, ...)
 String get category;/// Tags libres pour filtrage supplementaire
 List<String> get tags;/// Altitude minimale de pertinence en metres (null = pas de filtre altitude)
 int? get minAltitudeM;/// Chemin vers l asset image associe (null = pas d image)
 String? get imageAsset;/// Priorite d affichage (plus le nombre est eleve, plus le conseil est prioritaire)
 int get priority;
/// Create a copy of TipCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TipCardCopyWith<TipCard> get copyWith => _$TipCardCopyWithImpl<TipCard>(this as TipCard, _$identity);

  /// Serializes this TipCard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TipCard&&(identical(other.id, id) || other.id == id)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&(identical(other.contentFr, contentFr) || other.contentFr == contentFr)&&(identical(other.contentEn, contentEn) || other.contentEn == contentEn)&&(identical(other.contentDe, contentDe) || other.contentDe == contentDe)&&(identical(other.contentIt, contentIt) || other.contentIt == contentIt)&&(identical(other.contentEs, contentEs) || other.contentEs == contentEs)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.season, season) || other.season == season)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.minAltitudeM, minAltitudeM) || other.minAltitudeM == minAltitudeM)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleFr,titleEn,titleDe,titleIt,titleEs,contentFr,contentEn,contentDe,contentIt,contentEs,scope,season,category,const DeepCollectionEquality().hash(tags),minAltitudeM,imageAsset,priority);

@override
String toString() {
  return 'TipCard(id: $id, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, contentFr: $contentFr, contentEn: $contentEn, contentDe: $contentDe, contentIt: $contentIt, contentEs: $contentEs, scope: $scope, season: $season, category: $category, tags: $tags, minAltitudeM: $minAltitudeM, imageAsset: $imageAsset, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $TipCardCopyWith<$Res>  {
  factory $TipCardCopyWith(TipCard value, $Res Function(TipCard) _then) = _$TipCardCopyWithImpl;
@useResult
$Res call({
 String id, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, String contentFr, String contentEn, String contentDe, String contentIt, String contentEs, String scope, String season, String category, List<String> tags, int? minAltitudeM, String? imageAsset, int priority
});




}
/// @nodoc
class _$TipCardCopyWithImpl<$Res>
    implements $TipCardCopyWith<$Res> {
  _$TipCardCopyWithImpl(this._self, this._then);

  final TipCard _self;
  final $Res Function(TipCard) _then;

/// Create a copy of TipCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? contentFr = null,Object? contentEn = null,Object? contentDe = null,Object? contentIt = null,Object? contentEs = null,Object? scope = null,Object? season = null,Object? category = null,Object? tags = null,Object? minAltitudeM = freezed,Object? imageAsset = freezed,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,contentFr: null == contentFr ? _self.contentFr : contentFr // ignore: cast_nullable_to_non_nullable
as String,contentEn: null == contentEn ? _self.contentEn : contentEn // ignore: cast_nullable_to_non_nullable
as String,contentDe: null == contentDe ? _self.contentDe : contentDe // ignore: cast_nullable_to_non_nullable
as String,contentIt: null == contentIt ? _self.contentIt : contentIt // ignore: cast_nullable_to_non_nullable
as String,contentEs: null == contentEs ? _self.contentEs : contentEs // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,minAltitudeM: freezed == minAltitudeM ? _self.minAltitudeM : minAltitudeM // ignore: cast_nullable_to_non_nullable
as int?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TipCard].
extension TipCardPatterns on TipCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TipCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TipCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TipCard value)  $default,){
final _that = this;
switch (_that) {
case _TipCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TipCard value)?  $default,){
final _that = this;
switch (_that) {
case _TipCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TipCard() when $default != null:
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)  $default,) {final _that = this;
switch (_that) {
case _TipCard():
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _TipCard() when $default != null:
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TipCard extends TipCard {
  const _TipCard({required this.id, required this.titleFr, this.titleEn = '', this.titleDe = '', this.titleIt = '', this.titleEs = '', required this.contentFr, this.contentEn = '', this.contentDe = '', this.contentIt = '', this.contentEs = '', this.scope = 'all', this.season = 'all', this.category = 'general', final  List<String> tags = const [], this.minAltitudeM, this.imageAsset, this.priority = 0}): _tags = tags,super._();
  factory _TipCard.fromJson(Map<String, dynamic> json) => _$TipCardFromJson(json);

/// Identifiant unique de la fiche conseil
@override final  String id;
/// Titre -- francais
@override final  String titleFr;
/// Titre -- anglais
@override@JsonKey() final  String titleEn;
/// Titre -- allemand
@override@JsonKey() final  String titleDe;
/// Titre -- italien
@override@JsonKey() final  String titleIt;
/// Titre -- espagnol
@override@JsonKey() final  String titleEs;
/// Contenu -- francais
@override final  String contentFr;
/// Contenu -- anglais
@override@JsonKey() final  String contentEn;
/// Contenu -- allemand
@override@JsonKey() final  String contentDe;
/// Contenu -- italien
@override@JsonKey() final  String contentIt;
/// Contenu -- espagnol
@override@JsonKey() final  String contentEs;
/// Perimetre du conseil -- String extensible (gr10, tmb, all, ...)
@override@JsonKey() final  String scope;
/// Saison de pertinence -- String extensible (summer, winter, spring, autumn, all, ...)
@override@JsonKey() final  String season;
/// Categorie du conseil -- String extensible (preparation, equipment, nutrition, safety, nature, recovery, ...)
@override@JsonKey() final  String category;
/// Tags libres pour filtrage supplementaire
 final  List<String> _tags;
/// Tags libres pour filtrage supplementaire
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Altitude minimale de pertinence en metres (null = pas de filtre altitude)
@override final  int? minAltitudeM;
/// Chemin vers l asset image associe (null = pas d image)
@override final  String? imageAsset;
/// Priorite d affichage (plus le nombre est eleve, plus le conseil est prioritaire)
@override@JsonKey() final  int priority;

/// Create a copy of TipCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TipCardCopyWith<_TipCard> get copyWith => __$TipCardCopyWithImpl<_TipCard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TipCardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TipCard&&(identical(other.id, id) || other.id == id)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&(identical(other.contentFr, contentFr) || other.contentFr == contentFr)&&(identical(other.contentEn, contentEn) || other.contentEn == contentEn)&&(identical(other.contentDe, contentDe) || other.contentDe == contentDe)&&(identical(other.contentIt, contentIt) || other.contentIt == contentIt)&&(identical(other.contentEs, contentEs) || other.contentEs == contentEs)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.season, season) || other.season == season)&&(identical(other.category, category) || other.category == category)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.minAltitudeM, minAltitudeM) || other.minAltitudeM == minAltitudeM)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titleFr,titleEn,titleDe,titleIt,titleEs,contentFr,contentEn,contentDe,contentIt,contentEs,scope,season,category,const DeepCollectionEquality().hash(_tags),minAltitudeM,imageAsset,priority);

@override
String toString() {
  return 'TipCard(id: $id, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, contentFr: $contentFr, contentEn: $contentEn, contentDe: $contentDe, contentIt: $contentIt, contentEs: $contentEs, scope: $scope, season: $season, category: $category, tags: $tags, minAltitudeM: $minAltitudeM, imageAsset: $imageAsset, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$TipCardCopyWith<$Res> implements $TipCardCopyWith<$Res> {
  factory _$TipCardCopyWith(_TipCard value, $Res Function(_TipCard) _then) = __$TipCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, String contentFr, String contentEn, String contentDe, String contentIt, String contentEs, String scope, String season, String category, List<String> tags, int? minAltitudeM, String? imageAsset, int priority
});




}
/// @nodoc
class __$TipCardCopyWithImpl<$Res>
    implements _$TipCardCopyWith<$Res> {
  __$TipCardCopyWithImpl(this._self, this._then);

  final _TipCard _self;
  final $Res Function(_TipCard) _then;

/// Create a copy of TipCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? contentFr = null,Object? contentEn = null,Object? contentDe = null,Object? contentIt = null,Object? contentEs = null,Object? scope = null,Object? season = null,Object? category = null,Object? tags = null,Object? minAltitudeM = freezed,Object? imageAsset = freezed,Object? priority = null,}) {
  return _then(_TipCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,contentFr: null == contentFr ? _self.contentFr : contentFr // ignore: cast_nullable_to_non_nullable
as String,contentEn: null == contentEn ? _self.contentEn : contentEn // ignore: cast_nullable_to_non_nullable
as String,contentDe: null == contentDe ? _self.contentDe : contentDe // ignore: cast_nullable_to_non_nullable
as String,contentIt: null == contentIt ? _self.contentIt : contentIt // ignore: cast_nullable_to_non_nullable
as String,contentEs: null == contentEs ? _self.contentEs : contentEs // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,minAltitudeM: freezed == minAltitudeM ? _self.minAltitudeM : minAltitudeM // ignore: cast_nullable_to_non_nullable
as int?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
