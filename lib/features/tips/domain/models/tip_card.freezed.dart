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
 String get titleEs;/// POINTS du conseil -- francais. Contenu de reference d'une fiche au
/// calibre (5 points autonomes et chiffres). Vide -> repli sur [contentFr].
 List<String> get pointsFr;/// POINTS du conseil -- anglais.
 List<String> get pointsEn;/// POINTS du conseil -- allemand.
 List<String> get pointsDe;/// POINTS du conseil -- italien.
 List<String> get pointsIt;/// POINTS du conseil -- espagnol.
 List<String> get pointsEs;/// Contenu paragraphe -- francais (HISTORIQUE, repli si [pointsFr] est vide)
 String get contentFr;/// Contenu paragraphe -- anglais (HISTORIQUE)
 String get contentEn;/// Contenu paragraphe -- allemand (HISTORIQUE)
 String get contentDe;/// Contenu paragraphe -- italien (HISTORIQUE)
 String get contentIt;/// Contenu paragraphe -- espagnol (HISTORIQUE)
 String get contentEs;/// Perimetre du conseil -- String extensible (gr10, tmb, all, ...)
 String get scope;/// Saison de pertinence -- String extensible (summer, winter, spring, autumn, all, ...)
 String get season;/// Categorie du conseil -- String extensible (preparation, equipment, nutrition, safety, nature, recovery, ...)
 String get category;/// THEME de regroupement (StepWays LOT 5, sous-ensemble C) -- String
/// extensible : gear/safety/health/weather/refuge/... Les fiches sont
/// RANGEES PAR THEME (decision Chris #99615). Vide -> derive de [category]
/// via [TipTheme.fromCategory] (repli, jamais de fiche sans theme).
 String get theme;/// Lien FACEBOOK de la fiche (StepWays LOT 5, C) -- null = pas de bouton FB.
/// Renvoie vers la fiche/le post equivalent sur le compte de la marque.
/// AUCUNE url inventee : fournie par la donnee (JSON), jamais en dur.
 String? get urlFacebook;/// Lien INSTAGRAM de la fiche (StepWays LOT 5, C) -- null = pas de bouton IG.
 String? get urlInstagram;/// Tags libres pour filtrage supplementaire
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TipCard&&(identical(other.id, id) || other.id == id)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&const DeepCollectionEquality().equals(other.pointsFr, pointsFr)&&const DeepCollectionEquality().equals(other.pointsEn, pointsEn)&&const DeepCollectionEquality().equals(other.pointsDe, pointsDe)&&const DeepCollectionEquality().equals(other.pointsIt, pointsIt)&&const DeepCollectionEquality().equals(other.pointsEs, pointsEs)&&(identical(other.contentFr, contentFr) || other.contentFr == contentFr)&&(identical(other.contentEn, contentEn) || other.contentEn == contentEn)&&(identical(other.contentDe, contentDe) || other.contentDe == contentDe)&&(identical(other.contentIt, contentIt) || other.contentIt == contentIt)&&(identical(other.contentEs, contentEs) || other.contentEs == contentEs)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.season, season) || other.season == season)&&(identical(other.category, category) || other.category == category)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.urlFacebook, urlFacebook) || other.urlFacebook == urlFacebook)&&(identical(other.urlInstagram, urlInstagram) || other.urlInstagram == urlInstagram)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.minAltitudeM, minAltitudeM) || other.minAltitudeM == minAltitudeM)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,titleFr,titleEn,titleDe,titleIt,titleEs,const DeepCollectionEquality().hash(pointsFr),const DeepCollectionEquality().hash(pointsEn),const DeepCollectionEquality().hash(pointsDe),const DeepCollectionEquality().hash(pointsIt),const DeepCollectionEquality().hash(pointsEs),contentFr,contentEn,contentDe,contentIt,contentEs,scope,season,category,theme,urlFacebook,urlInstagram,const DeepCollectionEquality().hash(tags),minAltitudeM,imageAsset,priority]);

@override
String toString() {
  return 'TipCard(id: $id, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, pointsFr: $pointsFr, pointsEn: $pointsEn, pointsDe: $pointsDe, pointsIt: $pointsIt, pointsEs: $pointsEs, contentFr: $contentFr, contentEn: $contentEn, contentDe: $contentDe, contentIt: $contentIt, contentEs: $contentEs, scope: $scope, season: $season, category: $category, theme: $theme, urlFacebook: $urlFacebook, urlInstagram: $urlInstagram, tags: $tags, minAltitudeM: $minAltitudeM, imageAsset: $imageAsset, priority: $priority)';
}


}

/// @nodoc
abstract mixin class $TipCardCopyWith<$Res>  {
  factory $TipCardCopyWith(TipCard value, $Res Function(TipCard) _then) = _$TipCardCopyWithImpl;
@useResult
$Res call({
 String id, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, List<String> pointsFr, List<String> pointsEn, List<String> pointsDe, List<String> pointsIt, List<String> pointsEs, String contentFr, String contentEn, String contentDe, String contentIt, String contentEs, String scope, String season, String category, String theme, String? urlFacebook, String? urlInstagram, List<String> tags, int? minAltitudeM, String? imageAsset, int priority
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? pointsFr = null,Object? pointsEn = null,Object? pointsDe = null,Object? pointsIt = null,Object? pointsEs = null,Object? contentFr = null,Object? contentEn = null,Object? contentDe = null,Object? contentIt = null,Object? contentEs = null,Object? scope = null,Object? season = null,Object? category = null,Object? theme = null,Object? urlFacebook = freezed,Object? urlInstagram = freezed,Object? tags = null,Object? minAltitudeM = freezed,Object? imageAsset = freezed,Object? priority = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,pointsFr: null == pointsFr ? _self.pointsFr : pointsFr // ignore: cast_nullable_to_non_nullable
as List<String>,pointsEn: null == pointsEn ? _self.pointsEn : pointsEn // ignore: cast_nullable_to_non_nullable
as List<String>,pointsDe: null == pointsDe ? _self.pointsDe : pointsDe // ignore: cast_nullable_to_non_nullable
as List<String>,pointsIt: null == pointsIt ? _self.pointsIt : pointsIt // ignore: cast_nullable_to_non_nullable
as List<String>,pointsEs: null == pointsEs ? _self.pointsEs : pointsEs // ignore: cast_nullable_to_non_nullable
as List<String>,contentFr: null == contentFr ? _self.contentFr : contentFr // ignore: cast_nullable_to_non_nullable
as String,contentEn: null == contentEn ? _self.contentEn : contentEn // ignore: cast_nullable_to_non_nullable
as String,contentDe: null == contentDe ? _self.contentDe : contentDe // ignore: cast_nullable_to_non_nullable
as String,contentIt: null == contentIt ? _self.contentIt : contentIt // ignore: cast_nullable_to_non_nullable
as String,contentEs: null == contentEs ? _self.contentEs : contentEs // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,urlFacebook: freezed == urlFacebook ? _self.urlFacebook : urlFacebook // ignore: cast_nullable_to_non_nullable
as String?,urlInstagram: freezed == urlInstagram ? _self.urlInstagram : urlInstagram // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  List<String> pointsFr,  List<String> pointsEn,  List<String> pointsDe,  List<String> pointsIt,  List<String> pointsEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  String theme,  String? urlFacebook,  String? urlInstagram,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TipCard() when $default != null:
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.pointsFr,_that.pointsEn,_that.pointsDe,_that.pointsIt,_that.pointsEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.theme,_that.urlFacebook,_that.urlInstagram,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  List<String> pointsFr,  List<String> pointsEn,  List<String> pointsDe,  List<String> pointsIt,  List<String> pointsEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  String theme,  String? urlFacebook,  String? urlInstagram,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)  $default,) {final _that = this;
switch (_that) {
case _TipCard():
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.pointsFr,_that.pointsEn,_that.pointsDe,_that.pointsIt,_that.pointsEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.theme,_that.urlFacebook,_that.urlInstagram,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titleFr,  String titleEn,  String titleDe,  String titleIt,  String titleEs,  List<String> pointsFr,  List<String> pointsEn,  List<String> pointsDe,  List<String> pointsIt,  List<String> pointsEs,  String contentFr,  String contentEn,  String contentDe,  String contentIt,  String contentEs,  String scope,  String season,  String category,  String theme,  String? urlFacebook,  String? urlInstagram,  List<String> tags,  int? minAltitudeM,  String? imageAsset,  int priority)?  $default,) {final _that = this;
switch (_that) {
case _TipCard() when $default != null:
return $default(_that.id,_that.titleFr,_that.titleEn,_that.titleDe,_that.titleIt,_that.titleEs,_that.pointsFr,_that.pointsEn,_that.pointsDe,_that.pointsIt,_that.pointsEs,_that.contentFr,_that.contentEn,_that.contentDe,_that.contentIt,_that.contentEs,_that.scope,_that.season,_that.category,_that.theme,_that.urlFacebook,_that.urlInstagram,_that.tags,_that.minAltitudeM,_that.imageAsset,_that.priority);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TipCard extends TipCard {
  const _TipCard({required this.id, required this.titleFr, this.titleEn = '', this.titleDe = '', this.titleIt = '', this.titleEs = '', final  List<String> pointsFr = const <String>[], final  List<String> pointsEn = const <String>[], final  List<String> pointsDe = const <String>[], final  List<String> pointsIt = const <String>[], final  List<String> pointsEs = const <String>[], this.contentFr = '', this.contentEn = '', this.contentDe = '', this.contentIt = '', this.contentEs = '', this.scope = 'all', this.season = 'all', this.category = 'general', this.theme = '', this.urlFacebook, this.urlInstagram, final  List<String> tags = const [], this.minAltitudeM, this.imageAsset, this.priority = 0}): _pointsFr = pointsFr,_pointsEn = pointsEn,_pointsDe = pointsDe,_pointsIt = pointsIt,_pointsEs = pointsEs,_tags = tags,super._();
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
/// POINTS du conseil -- francais. Contenu de reference d'une fiche au
/// calibre (5 points autonomes et chiffres). Vide -> repli sur [contentFr].
 final  List<String> _pointsFr;
/// POINTS du conseil -- francais. Contenu de reference d'une fiche au
/// calibre (5 points autonomes et chiffres). Vide -> repli sur [contentFr].
@override@JsonKey() List<String> get pointsFr {
  if (_pointsFr is EqualUnmodifiableListView) return _pointsFr;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsFr);
}

/// POINTS du conseil -- anglais.
 final  List<String> _pointsEn;
/// POINTS du conseil -- anglais.
@override@JsonKey() List<String> get pointsEn {
  if (_pointsEn is EqualUnmodifiableListView) return _pointsEn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsEn);
}

/// POINTS du conseil -- allemand.
 final  List<String> _pointsDe;
/// POINTS du conseil -- allemand.
@override@JsonKey() List<String> get pointsDe {
  if (_pointsDe is EqualUnmodifiableListView) return _pointsDe;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsDe);
}

/// POINTS du conseil -- italien.
 final  List<String> _pointsIt;
/// POINTS du conseil -- italien.
@override@JsonKey() List<String> get pointsIt {
  if (_pointsIt is EqualUnmodifiableListView) return _pointsIt;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsIt);
}

/// POINTS du conseil -- espagnol.
 final  List<String> _pointsEs;
/// POINTS du conseil -- espagnol.
@override@JsonKey() List<String> get pointsEs {
  if (_pointsEs is EqualUnmodifiableListView) return _pointsEs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pointsEs);
}

/// Contenu paragraphe -- francais (HISTORIQUE, repli si [pointsFr] est vide)
@override@JsonKey() final  String contentFr;
/// Contenu paragraphe -- anglais (HISTORIQUE)
@override@JsonKey() final  String contentEn;
/// Contenu paragraphe -- allemand (HISTORIQUE)
@override@JsonKey() final  String contentDe;
/// Contenu paragraphe -- italien (HISTORIQUE)
@override@JsonKey() final  String contentIt;
/// Contenu paragraphe -- espagnol (HISTORIQUE)
@override@JsonKey() final  String contentEs;
/// Perimetre du conseil -- String extensible (gr10, tmb, all, ...)
@override@JsonKey() final  String scope;
/// Saison de pertinence -- String extensible (summer, winter, spring, autumn, all, ...)
@override@JsonKey() final  String season;
/// Categorie du conseil -- String extensible (preparation, equipment, nutrition, safety, nature, recovery, ...)
@override@JsonKey() final  String category;
/// THEME de regroupement (StepWays LOT 5, sous-ensemble C) -- String
/// extensible : gear/safety/health/weather/refuge/... Les fiches sont
/// RANGEES PAR THEME (decision Chris #99615). Vide -> derive de [category]
/// via [TipTheme.fromCategory] (repli, jamais de fiche sans theme).
@override@JsonKey() final  String theme;
/// Lien FACEBOOK de la fiche (StepWays LOT 5, C) -- null = pas de bouton FB.
/// Renvoie vers la fiche/le post equivalent sur le compte de la marque.
/// AUCUNE url inventee : fournie par la donnee (JSON), jamais en dur.
@override final  String? urlFacebook;
/// Lien INSTAGRAM de la fiche (StepWays LOT 5, C) -- null = pas de bouton IG.
@override final  String? urlInstagram;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TipCard&&(identical(other.id, id) || other.id == id)&&(identical(other.titleFr, titleFr) || other.titleFr == titleFr)&&(identical(other.titleEn, titleEn) || other.titleEn == titleEn)&&(identical(other.titleDe, titleDe) || other.titleDe == titleDe)&&(identical(other.titleIt, titleIt) || other.titleIt == titleIt)&&(identical(other.titleEs, titleEs) || other.titleEs == titleEs)&&const DeepCollectionEquality().equals(other._pointsFr, _pointsFr)&&const DeepCollectionEquality().equals(other._pointsEn, _pointsEn)&&const DeepCollectionEquality().equals(other._pointsDe, _pointsDe)&&const DeepCollectionEquality().equals(other._pointsIt, _pointsIt)&&const DeepCollectionEquality().equals(other._pointsEs, _pointsEs)&&(identical(other.contentFr, contentFr) || other.contentFr == contentFr)&&(identical(other.contentEn, contentEn) || other.contentEn == contentEn)&&(identical(other.contentDe, contentDe) || other.contentDe == contentDe)&&(identical(other.contentIt, contentIt) || other.contentIt == contentIt)&&(identical(other.contentEs, contentEs) || other.contentEs == contentEs)&&(identical(other.scope, scope) || other.scope == scope)&&(identical(other.season, season) || other.season == season)&&(identical(other.category, category) || other.category == category)&&(identical(other.theme, theme) || other.theme == theme)&&(identical(other.urlFacebook, urlFacebook) || other.urlFacebook == urlFacebook)&&(identical(other.urlInstagram, urlInstagram) || other.urlInstagram == urlInstagram)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.minAltitudeM, minAltitudeM) || other.minAltitudeM == minAltitudeM)&&(identical(other.imageAsset, imageAsset) || other.imageAsset == imageAsset)&&(identical(other.priority, priority) || other.priority == priority));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,titleFr,titleEn,titleDe,titleIt,titleEs,const DeepCollectionEquality().hash(_pointsFr),const DeepCollectionEquality().hash(_pointsEn),const DeepCollectionEquality().hash(_pointsDe),const DeepCollectionEquality().hash(_pointsIt),const DeepCollectionEquality().hash(_pointsEs),contentFr,contentEn,contentDe,contentIt,contentEs,scope,season,category,theme,urlFacebook,urlInstagram,const DeepCollectionEquality().hash(_tags),minAltitudeM,imageAsset,priority]);

@override
String toString() {
  return 'TipCard(id: $id, titleFr: $titleFr, titleEn: $titleEn, titleDe: $titleDe, titleIt: $titleIt, titleEs: $titleEs, pointsFr: $pointsFr, pointsEn: $pointsEn, pointsDe: $pointsDe, pointsIt: $pointsIt, pointsEs: $pointsEs, contentFr: $contentFr, contentEn: $contentEn, contentDe: $contentDe, contentIt: $contentIt, contentEs: $contentEs, scope: $scope, season: $season, category: $category, theme: $theme, urlFacebook: $urlFacebook, urlInstagram: $urlInstagram, tags: $tags, minAltitudeM: $minAltitudeM, imageAsset: $imageAsset, priority: $priority)';
}


}

/// @nodoc
abstract mixin class _$TipCardCopyWith<$Res> implements $TipCardCopyWith<$Res> {
  factory _$TipCardCopyWith(_TipCard value, $Res Function(_TipCard) _then) = __$TipCardCopyWithImpl;
@override @useResult
$Res call({
 String id, String titleFr, String titleEn, String titleDe, String titleIt, String titleEs, List<String> pointsFr, List<String> pointsEn, List<String> pointsDe, List<String> pointsIt, List<String> pointsEs, String contentFr, String contentEn, String contentDe, String contentIt, String contentEs, String scope, String season, String category, String theme, String? urlFacebook, String? urlInstagram, List<String> tags, int? minAltitudeM, String? imageAsset, int priority
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titleFr = null,Object? titleEn = null,Object? titleDe = null,Object? titleIt = null,Object? titleEs = null,Object? pointsFr = null,Object? pointsEn = null,Object? pointsDe = null,Object? pointsIt = null,Object? pointsEs = null,Object? contentFr = null,Object? contentEn = null,Object? contentDe = null,Object? contentIt = null,Object? contentEs = null,Object? scope = null,Object? season = null,Object? category = null,Object? theme = null,Object? urlFacebook = freezed,Object? urlInstagram = freezed,Object? tags = null,Object? minAltitudeM = freezed,Object? imageAsset = freezed,Object? priority = null,}) {
  return _then(_TipCard(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titleFr: null == titleFr ? _self.titleFr : titleFr // ignore: cast_nullable_to_non_nullable
as String,titleEn: null == titleEn ? _self.titleEn : titleEn // ignore: cast_nullable_to_non_nullable
as String,titleDe: null == titleDe ? _self.titleDe : titleDe // ignore: cast_nullable_to_non_nullable
as String,titleIt: null == titleIt ? _self.titleIt : titleIt // ignore: cast_nullable_to_non_nullable
as String,titleEs: null == titleEs ? _self.titleEs : titleEs // ignore: cast_nullable_to_non_nullable
as String,pointsFr: null == pointsFr ? _self._pointsFr : pointsFr // ignore: cast_nullable_to_non_nullable
as List<String>,pointsEn: null == pointsEn ? _self._pointsEn : pointsEn // ignore: cast_nullable_to_non_nullable
as List<String>,pointsDe: null == pointsDe ? _self._pointsDe : pointsDe // ignore: cast_nullable_to_non_nullable
as List<String>,pointsIt: null == pointsIt ? _self._pointsIt : pointsIt // ignore: cast_nullable_to_non_nullable
as List<String>,pointsEs: null == pointsEs ? _self._pointsEs : pointsEs // ignore: cast_nullable_to_non_nullable
as List<String>,contentFr: null == contentFr ? _self.contentFr : contentFr // ignore: cast_nullable_to_non_nullable
as String,contentEn: null == contentEn ? _self.contentEn : contentEn // ignore: cast_nullable_to_non_nullable
as String,contentDe: null == contentDe ? _self.contentDe : contentDe // ignore: cast_nullable_to_non_nullable
as String,contentIt: null == contentIt ? _self.contentIt : contentIt // ignore: cast_nullable_to_non_nullable
as String,contentEs: null == contentEs ? _self.contentEs : contentEs // ignore: cast_nullable_to_non_nullable
as String,scope: null == scope ? _self.scope : scope // ignore: cast_nullable_to_non_nullable
as String,season: null == season ? _self.season : season // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,theme: null == theme ? _self.theme : theme // ignore: cast_nullable_to_non_nullable
as String,urlFacebook: freezed == urlFacebook ? _self.urlFacebook : urlFacebook // ignore: cast_nullable_to_non_nullable
as String?,urlInstagram: freezed == urlInstagram ? _self.urlInstagram : urlInstagram // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,minAltitudeM: freezed == minAltitudeM ? _self.minAltitudeM : minAltitudeM // ignore: cast_nullable_to_non_nullable
as int?,imageAsset: freezed == imageAsset ? _self.imageAsset : imageAsset // ignore: cast_nullable_to_non_nullable
as String?,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
