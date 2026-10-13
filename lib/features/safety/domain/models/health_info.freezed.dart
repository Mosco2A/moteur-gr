// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthInfo {

// ---------------------------------------------------------------- [1] QUI
/// Nom et prenom du randonneur.
///
/// SOURCE : Apple, « Fill out your Health Details » — « your name, date of
/// birth, sex, blood type » ; Google, application Securite > « Your info ».
/// C'EST LA PREMIERE LIGNE QUE LIT UN SECOURISTE : sans elle, la fiche parle
/// d'un patient anonyme.
 String get fullName;/// Date de naissance, au format ISO `AAAA-MM-JJ` (stockage neutre).
///
/// SOURCE : Apple, « vous pouvez ajouter des informations vous concernant,
/// comme votre date de naissance et votre groupe sanguin »
/// (<https://support.apple.com/fr-fr/105072>).
///
/// POURQUOI L'ISO ET PAS `JJ/MM/AAAA` : l'application parle cinq langues, et
/// `03/04` n'est pas la meme date des deux cotes de la Manche. Le stockage
/// est neutre, l'affichage est localise.
 String get birthDate;/// Adresse du randonneur.
///
/// SOURCE : fiche d'urgence systeme (champ « adresse » de la fiche du
/// telephone). MESURE HONNETE : c'est le champ que je n'ai PAS pu citer mot
/// pour mot sur une page officielle Apple ou Google — les pages listent
/// « blood type, allergies, medications » a titre d'EXEMPLE et ne donnent
/// jamais l'inventaire complet. Il est conserve parce que Christophe l'a
/// nomme explicitement le 26/09 (« son nom prenom adresse ») et parce qu'un
/// secouriste doit pouvoir dire d'ou vient la personne qu'il evacue.
 String get address;// ------------------------------------------------------ [2] QUI PREVENIR
/// LES CONTACTS A PREVENIR — DANS LA FICHE, PLUS A COTE (tache 630).
///
/// SOURCE : Apple, « Emergency Contacts » / « Contacts d'urgence » ; Google,
/// « Emergency contacts > Add contact ». Et Apple, sur ce que voient les
/// premiers intervenants : « as well as who to contact in case of an
/// emergency ».
///
/// POURQUOI ILS ENTRENT ICI ET NE RESTENT PAS DANS LEUR SERVICE. Trois
/// mesures, pas une preference :
///  1. un persona les a trouves INTROUVABLES depuis l'accueil ;
///  2. AUCUN ecran ne permettait d'en ajouter un — `addContact` n'etait
///     appele par aucune ligne de `lib/` ;
///  3. `EmergencyContactsService` les gardait dans une liste EN MEMOIRE :
///     meme saisis, ils disparaissaient au redemarrage.
/// Les mettre dans la fiche les rend saisissables, persistants et proteges
/// par le meme dossier exclu — d'un seul geste.
///
/// NE CONTIENT QUE LES CONTACTS PERSONNELS. Le 112 et les secours regionaux
/// du sentier restent fabriques par `EmergencyContactsService` : ce ne sont
/// pas des donnees du randonneur, ce sont des constantes de l'application.
 List<EmergencyContact> get emergencyContacts;// -------------------------------------------------------------- [3] VITAL
/// Allergies connues (texte libre, ex: 'Penicilline, arachides').
///
/// SOURCE : Apple « Allergies » ; Google « allergies ». PREMIER DU BLOC
/// VITAL au titre du A de SAMPLE : c'est ce qui tue au moment du soin.
 String get allergies;/// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
///
/// SOURCE : Apple « Traitements » / « Medications » ; Google
/// « medications ». M de SAMPLE.
 String get treatments;/// ANTECEDENTS ET PROBLEMES MEDICAUX (nouveau, tache 630).
///
/// SOURCE : Apple, « Etat de sante » / « Medical conditions » — cite parmi
/// ce que les premiers intervenants voient (« allergies and medical
/// conditions »). P de SAMPLE (Past medical history).
///
/// C'EST LE CHAMP QUI MANQUAIT LE PLUS APRES L'IDENTITE : un diabete, une
/// epilepsie ou un traitement anticoagulant changent la conduite du
/// secouriste, et aucun des cinq champs d'origine ne pouvait les porter.
 String get conditions;/// Groupe sanguin — LISTE FERMEE DE HUIT + « je ne sais pas ».
///
/// SOURCE : Etablissement francais du sang pour les huit valeurs (voir
/// `health_bounds.dart`) ; Apple et Google pour la presence du champ.
/// PLUS DE SAISIE LIBRE (Christophe, 29/09) : un groupe sanguin mal saisi
/// sur une fiche d'urgence est PIRE qu'un champ vide.
 String get bloodType;/// Don d'organes — liste fermee de trois valeurs (nouveau, tache 630).
///
/// SOURCE : Apple, « Votre decision de faire don d'organes est accessible
/// aux autres dans votre fiche medicale ».
 String get organDonor;// ------------------------------------------------------ [4] ADMINISTRATIF
/// Contact du medecin traitant (nom + telephone).
///
/// PAS DE SOURCE SYSTEME : ni Apple ni Google ne portent ce champ. CONSERVE
/// QUAND MEME, et la raison est le terrain : le medecin traitant est celui
/// qui peut confirmer un antecedent a 3 h du matin quand le patient ne parle
/// plus. Il est en bas parce qu'on l'appelle apres, pas parce qu'il compte
/// moins.
 String get doctorContact;/// Numero d'assurance / mutuelle / carte europeenne.
///
/// PAS DE SOURCE SYSTEME non plus. CONSERVE MALGRE LA PHOTO DE LA CARTE, et
/// c'est un choix mesure (tache 630) : un numero SE LIT A VOIX HAUTE au
/// telephone, une image non. Les deux se completent, ils ne se remplacent
/// pas.
 String get insuranceNumber;/// NOM DU FICHIER DE LA PHOTO DE LA CARTE VITALE, ou vide (tache 630).
///
/// Demande de Christophe le 29/09 11:37, verbatim : « Telecharger la carte
/// verte et la carte de mutuelle, tout reste sur le tel » puis « photo des
/// 2 ».
///
/// LE MODELE NE PORTE QUE LE NOM DU FICHIER, JAMAIS L'IMAGE. L'image vit a
/// cote de `fiche.json`, dans le MEME dossier protege, et passe donc par la
/// MEME porte : meme exclusion de sauvegarde Android (declaree), meme
/// attribut iCloud pose a l'execution, meme effacement. Aucune seconde porte
/// n'est ouverte — c'etait la condition posee avec la demande.
///
/// POURQUOI PAS L'IMAGE EN BASE64 DANS LE JSON : la fiche est relue a chaque
/// ouverture de l'ecran et a chaque rafraichissement de la notification de
/// secours. Y encastrer deux images multiplierait par mille le cout d'une
/// lecture qui doit rester instantanee sur un telephone froid.
 String get carteVitaleFichier;/// Nom du fichier de la photo de la carte de mutuelle, ou vide (tache 630).
 String get carteMutuelleFichier;
/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthInfoCopyWith<HealthInfo> get copyWith => _$HealthInfoCopyWithImpl<HealthInfo>(this as HealthInfo, _$identity);

  /// Serializes this HealthInfo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthInfo&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other.emergencyContacts, emergencyContacts)&&(identical(other.allergies, allergies) || other.allergies == allergies)&&(identical(other.treatments, treatments) || other.treatments == treatments)&&(identical(other.conditions, conditions) || other.conditions == conditions)&&(identical(other.bloodType, bloodType) || other.bloodType == bloodType)&&(identical(other.organDonor, organDonor) || other.organDonor == organDonor)&&(identical(other.doctorContact, doctorContact) || other.doctorContact == doctorContact)&&(identical(other.insuranceNumber, insuranceNumber) || other.insuranceNumber == insuranceNumber)&&(identical(other.carteVitaleFichier, carteVitaleFichier) || other.carteVitaleFichier == carteVitaleFichier)&&(identical(other.carteMutuelleFichier, carteMutuelleFichier) || other.carteMutuelleFichier == carteMutuelleFichier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,birthDate,address,const DeepCollectionEquality().hash(emergencyContacts),allergies,treatments,conditions,bloodType,organDonor,doctorContact,insuranceNumber,carteVitaleFichier,carteMutuelleFichier);

@override
String toString() {
  return 'HealthInfo(fullName: $fullName, birthDate: $birthDate, address: $address, emergencyContacts: $emergencyContacts, allergies: $allergies, treatments: $treatments, conditions: $conditions, bloodType: $bloodType, organDonor: $organDonor, doctorContact: $doctorContact, insuranceNumber: $insuranceNumber, carteVitaleFichier: $carteVitaleFichier, carteMutuelleFichier: $carteMutuelleFichier)';
}


}

/// @nodoc
abstract mixin class $HealthInfoCopyWith<$Res>  {
  factory $HealthInfoCopyWith(HealthInfo value, $Res Function(HealthInfo) _then) = _$HealthInfoCopyWithImpl;
@useResult
$Res call({
 String fullName, String birthDate, String address, List<EmergencyContact> emergencyContacts, String allergies, String treatments, String conditions, String bloodType, String organDonor, String doctorContact, String insuranceNumber, String carteVitaleFichier, String carteMutuelleFichier
});




}
/// @nodoc
class _$HealthInfoCopyWithImpl<$Res>
    implements $HealthInfoCopyWith<$Res> {
  _$HealthInfoCopyWithImpl(this._self, this._then);

  final HealthInfo _self;
  final $Res Function(HealthInfo) _then;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fullName = null,Object? birthDate = null,Object? address = null,Object? emergencyContacts = null,Object? allergies = null,Object? treatments = null,Object? conditions = null,Object? bloodType = null,Object? organDonor = null,Object? doctorContact = null,Object? insuranceNumber = null,Object? carteVitaleFichier = null,Object? carteMutuelleFichier = null,}) {
  return _then(_self.copyWith(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,emergencyContacts: null == emergencyContacts ? _self.emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,allergies: null == allergies ? _self.allergies : allergies // ignore: cast_nullable_to_non_nullable
as String,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as String,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as String,bloodType: null == bloodType ? _self.bloodType : bloodType // ignore: cast_nullable_to_non_nullable
as String,organDonor: null == organDonor ? _self.organDonor : organDonor // ignore: cast_nullable_to_non_nullable
as String,doctorContact: null == doctorContact ? _self.doctorContact : doctorContact // ignore: cast_nullable_to_non_nullable
as String,insuranceNumber: null == insuranceNumber ? _self.insuranceNumber : insuranceNumber // ignore: cast_nullable_to_non_nullable
as String,carteVitaleFichier: null == carteVitaleFichier ? _self.carteVitaleFichier : carteVitaleFichier // ignore: cast_nullable_to_non_nullable
as String,carteMutuelleFichier: null == carteMutuelleFichier ? _self.carteMutuelleFichier : carteMutuelleFichier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthInfo].
extension HealthInfoPatterns on HealthInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthInfo value)  $default,){
final _that = this;
switch (_that) {
case _HealthInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthInfo value)?  $default,){
final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fullName,  String birthDate,  String address,  List<EmergencyContact> emergencyContacts,  String allergies,  String treatments,  String conditions,  String bloodType,  String organDonor,  String doctorContact,  String insuranceNumber,  String carteVitaleFichier,  String carteMutuelleFichier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
return $default(_that.fullName,_that.birthDate,_that.address,_that.emergencyContacts,_that.allergies,_that.treatments,_that.conditions,_that.bloodType,_that.organDonor,_that.doctorContact,_that.insuranceNumber,_that.carteVitaleFichier,_that.carteMutuelleFichier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fullName,  String birthDate,  String address,  List<EmergencyContact> emergencyContacts,  String allergies,  String treatments,  String conditions,  String bloodType,  String organDonor,  String doctorContact,  String insuranceNumber,  String carteVitaleFichier,  String carteMutuelleFichier)  $default,) {final _that = this;
switch (_that) {
case _HealthInfo():
return $default(_that.fullName,_that.birthDate,_that.address,_that.emergencyContacts,_that.allergies,_that.treatments,_that.conditions,_that.bloodType,_that.organDonor,_that.doctorContact,_that.insuranceNumber,_that.carteVitaleFichier,_that.carteMutuelleFichier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fullName,  String birthDate,  String address,  List<EmergencyContact> emergencyContacts,  String allergies,  String treatments,  String conditions,  String bloodType,  String organDonor,  String doctorContact,  String insuranceNumber,  String carteVitaleFichier,  String carteMutuelleFichier)?  $default,) {final _that = this;
switch (_that) {
case _HealthInfo() when $default != null:
return $default(_that.fullName,_that.birthDate,_that.address,_that.emergencyContacts,_that.allergies,_that.treatments,_that.conditions,_that.bloodType,_that.organDonor,_that.doctorContact,_that.insuranceNumber,_that.carteVitaleFichier,_that.carteMutuelleFichier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HealthInfo extends HealthInfo {
  const _HealthInfo({this.fullName = '', this.birthDate = '', this.address = '', final  List<EmergencyContact> emergencyContacts = const <EmergencyContact>[], this.allergies = '', this.treatments = '', this.conditions = '', this.bloodType = '', this.organDonor = '', this.doctorContact = '', this.insuranceNumber = '', this.carteVitaleFichier = '', this.carteMutuelleFichier = ''}): _emergencyContacts = emergencyContacts,super._();
  factory _HealthInfo.fromJson(Map<String, dynamic> json) => _$HealthInfoFromJson(json);

// ---------------------------------------------------------------- [1] QUI
/// Nom et prenom du randonneur.
///
/// SOURCE : Apple, « Fill out your Health Details » — « your name, date of
/// birth, sex, blood type » ; Google, application Securite > « Your info ».
/// C'EST LA PREMIERE LIGNE QUE LIT UN SECOURISTE : sans elle, la fiche parle
/// d'un patient anonyme.
@override@JsonKey() final  String fullName;
/// Date de naissance, au format ISO `AAAA-MM-JJ` (stockage neutre).
///
/// SOURCE : Apple, « vous pouvez ajouter des informations vous concernant,
/// comme votre date de naissance et votre groupe sanguin »
/// (<https://support.apple.com/fr-fr/105072>).
///
/// POURQUOI L'ISO ET PAS `JJ/MM/AAAA` : l'application parle cinq langues, et
/// `03/04` n'est pas la meme date des deux cotes de la Manche. Le stockage
/// est neutre, l'affichage est localise.
@override@JsonKey() final  String birthDate;
/// Adresse du randonneur.
///
/// SOURCE : fiche d'urgence systeme (champ « adresse » de la fiche du
/// telephone). MESURE HONNETE : c'est le champ que je n'ai PAS pu citer mot
/// pour mot sur une page officielle Apple ou Google — les pages listent
/// « blood type, allergies, medications » a titre d'EXEMPLE et ne donnent
/// jamais l'inventaire complet. Il est conserve parce que Christophe l'a
/// nomme explicitement le 26/09 (« son nom prenom adresse ») et parce qu'un
/// secouriste doit pouvoir dire d'ou vient la personne qu'il evacue.
@override@JsonKey() final  String address;
// ------------------------------------------------------ [2] QUI PREVENIR
/// LES CONTACTS A PREVENIR — DANS LA FICHE, PLUS A COTE (tache 630).
///
/// SOURCE : Apple, « Emergency Contacts » / « Contacts d'urgence » ; Google,
/// « Emergency contacts > Add contact ». Et Apple, sur ce que voient les
/// premiers intervenants : « as well as who to contact in case of an
/// emergency ».
///
/// POURQUOI ILS ENTRENT ICI ET NE RESTENT PAS DANS LEUR SERVICE. Trois
/// mesures, pas une preference :
///  1. un persona les a trouves INTROUVABLES depuis l'accueil ;
///  2. AUCUN ecran ne permettait d'en ajouter un — `addContact` n'etait
///     appele par aucune ligne de `lib/` ;
///  3. `EmergencyContactsService` les gardait dans une liste EN MEMOIRE :
///     meme saisis, ils disparaissaient au redemarrage.
/// Les mettre dans la fiche les rend saisissables, persistants et proteges
/// par le meme dossier exclu — d'un seul geste.
///
/// NE CONTIENT QUE LES CONTACTS PERSONNELS. Le 112 et les secours regionaux
/// du sentier restent fabriques par `EmergencyContactsService` : ce ne sont
/// pas des donnees du randonneur, ce sont des constantes de l'application.
 final  List<EmergencyContact> _emergencyContacts;
// ------------------------------------------------------ [2] QUI PREVENIR
/// LES CONTACTS A PREVENIR — DANS LA FICHE, PLUS A COTE (tache 630).
///
/// SOURCE : Apple, « Emergency Contacts » / « Contacts d'urgence » ; Google,
/// « Emergency contacts > Add contact ». Et Apple, sur ce que voient les
/// premiers intervenants : « as well as who to contact in case of an
/// emergency ».
///
/// POURQUOI ILS ENTRENT ICI ET NE RESTENT PAS DANS LEUR SERVICE. Trois
/// mesures, pas une preference :
///  1. un persona les a trouves INTROUVABLES depuis l'accueil ;
///  2. AUCUN ecran ne permettait d'en ajouter un — `addContact` n'etait
///     appele par aucune ligne de `lib/` ;
///  3. `EmergencyContactsService` les gardait dans une liste EN MEMOIRE :
///     meme saisis, ils disparaissaient au redemarrage.
/// Les mettre dans la fiche les rend saisissables, persistants et proteges
/// par le meme dossier exclu — d'un seul geste.
///
/// NE CONTIENT QUE LES CONTACTS PERSONNELS. Le 112 et les secours regionaux
/// du sentier restent fabriques par `EmergencyContactsService` : ce ne sont
/// pas des donnees du randonneur, ce sont des constantes de l'application.
@override@JsonKey() List<EmergencyContact> get emergencyContacts {
  if (_emergencyContacts is EqualUnmodifiableListView) return _emergencyContacts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emergencyContacts);
}

// -------------------------------------------------------------- [3] VITAL
/// Allergies connues (texte libre, ex: 'Penicilline, arachides').
///
/// SOURCE : Apple « Allergies » ; Google « allergies ». PREMIER DU BLOC
/// VITAL au titre du A de SAMPLE : c'est ce qui tue au moment du soin.
@override@JsonKey() final  String allergies;
/// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
///
/// SOURCE : Apple « Traitements » / « Medications » ; Google
/// « medications ». M de SAMPLE.
@override@JsonKey() final  String treatments;
/// ANTECEDENTS ET PROBLEMES MEDICAUX (nouveau, tache 630).
///
/// SOURCE : Apple, « Etat de sante » / « Medical conditions » — cite parmi
/// ce que les premiers intervenants voient (« allergies and medical
/// conditions »). P de SAMPLE (Past medical history).
///
/// C'EST LE CHAMP QUI MANQUAIT LE PLUS APRES L'IDENTITE : un diabete, une
/// epilepsie ou un traitement anticoagulant changent la conduite du
/// secouriste, et aucun des cinq champs d'origine ne pouvait les porter.
@override@JsonKey() final  String conditions;
/// Groupe sanguin — LISTE FERMEE DE HUIT + « je ne sais pas ».
///
/// SOURCE : Etablissement francais du sang pour les huit valeurs (voir
/// `health_bounds.dart`) ; Apple et Google pour la presence du champ.
/// PLUS DE SAISIE LIBRE (Christophe, 29/09) : un groupe sanguin mal saisi
/// sur une fiche d'urgence est PIRE qu'un champ vide.
@override@JsonKey() final  String bloodType;
/// Don d'organes — liste fermee de trois valeurs (nouveau, tache 630).
///
/// SOURCE : Apple, « Votre decision de faire don d'organes est accessible
/// aux autres dans votre fiche medicale ».
@override@JsonKey() final  String organDonor;
// ------------------------------------------------------ [4] ADMINISTRATIF
/// Contact du medecin traitant (nom + telephone).
///
/// PAS DE SOURCE SYSTEME : ni Apple ni Google ne portent ce champ. CONSERVE
/// QUAND MEME, et la raison est le terrain : le medecin traitant est celui
/// qui peut confirmer un antecedent a 3 h du matin quand le patient ne parle
/// plus. Il est en bas parce qu'on l'appelle apres, pas parce qu'il compte
/// moins.
@override@JsonKey() final  String doctorContact;
/// Numero d'assurance / mutuelle / carte europeenne.
///
/// PAS DE SOURCE SYSTEME non plus. CONSERVE MALGRE LA PHOTO DE LA CARTE, et
/// c'est un choix mesure (tache 630) : un numero SE LIT A VOIX HAUTE au
/// telephone, une image non. Les deux se completent, ils ne se remplacent
/// pas.
@override@JsonKey() final  String insuranceNumber;
/// NOM DU FICHIER DE LA PHOTO DE LA CARTE VITALE, ou vide (tache 630).
///
/// Demande de Christophe le 29/09 11:37, verbatim : « Telecharger la carte
/// verte et la carte de mutuelle, tout reste sur le tel » puis « photo des
/// 2 ».
///
/// LE MODELE NE PORTE QUE LE NOM DU FICHIER, JAMAIS L'IMAGE. L'image vit a
/// cote de `fiche.json`, dans le MEME dossier protege, et passe donc par la
/// MEME porte : meme exclusion de sauvegarde Android (declaree), meme
/// attribut iCloud pose a l'execution, meme effacement. Aucune seconde porte
/// n'est ouverte — c'etait la condition posee avec la demande.
///
/// POURQUOI PAS L'IMAGE EN BASE64 DANS LE JSON : la fiche est relue a chaque
/// ouverture de l'ecran et a chaque rafraichissement de la notification de
/// secours. Y encastrer deux images multiplierait par mille le cout d'une
/// lecture qui doit rester instantanee sur un telephone froid.
@override@JsonKey() final  String carteVitaleFichier;
/// Nom du fichier de la photo de la carte de mutuelle, ou vide (tache 630).
@override@JsonKey() final  String carteMutuelleFichier;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthInfoCopyWith<_HealthInfo> get copyWith => __$HealthInfoCopyWithImpl<_HealthInfo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HealthInfoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthInfo&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.birthDate, birthDate) || other.birthDate == birthDate)&&(identical(other.address, address) || other.address == address)&&const DeepCollectionEquality().equals(other._emergencyContacts, _emergencyContacts)&&(identical(other.allergies, allergies) || other.allergies == allergies)&&(identical(other.treatments, treatments) || other.treatments == treatments)&&(identical(other.conditions, conditions) || other.conditions == conditions)&&(identical(other.bloodType, bloodType) || other.bloodType == bloodType)&&(identical(other.organDonor, organDonor) || other.organDonor == organDonor)&&(identical(other.doctorContact, doctorContact) || other.doctorContact == doctorContact)&&(identical(other.insuranceNumber, insuranceNumber) || other.insuranceNumber == insuranceNumber)&&(identical(other.carteVitaleFichier, carteVitaleFichier) || other.carteVitaleFichier == carteVitaleFichier)&&(identical(other.carteMutuelleFichier, carteMutuelleFichier) || other.carteMutuelleFichier == carteMutuelleFichier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fullName,birthDate,address,const DeepCollectionEquality().hash(_emergencyContacts),allergies,treatments,conditions,bloodType,organDonor,doctorContact,insuranceNumber,carteVitaleFichier,carteMutuelleFichier);

@override
String toString() {
  return 'HealthInfo(fullName: $fullName, birthDate: $birthDate, address: $address, emergencyContacts: $emergencyContacts, allergies: $allergies, treatments: $treatments, conditions: $conditions, bloodType: $bloodType, organDonor: $organDonor, doctorContact: $doctorContact, insuranceNumber: $insuranceNumber, carteVitaleFichier: $carteVitaleFichier, carteMutuelleFichier: $carteMutuelleFichier)';
}


}

/// @nodoc
abstract mixin class _$HealthInfoCopyWith<$Res> implements $HealthInfoCopyWith<$Res> {
  factory _$HealthInfoCopyWith(_HealthInfo value, $Res Function(_HealthInfo) _then) = __$HealthInfoCopyWithImpl;
@override @useResult
$Res call({
 String fullName, String birthDate, String address, List<EmergencyContact> emergencyContacts, String allergies, String treatments, String conditions, String bloodType, String organDonor, String doctorContact, String insuranceNumber, String carteVitaleFichier, String carteMutuelleFichier
});




}
/// @nodoc
class __$HealthInfoCopyWithImpl<$Res>
    implements _$HealthInfoCopyWith<$Res> {
  __$HealthInfoCopyWithImpl(this._self, this._then);

  final _HealthInfo _self;
  final $Res Function(_HealthInfo) _then;

/// Create a copy of HealthInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fullName = null,Object? birthDate = null,Object? address = null,Object? emergencyContacts = null,Object? allergies = null,Object? treatments = null,Object? conditions = null,Object? bloodType = null,Object? organDonor = null,Object? doctorContact = null,Object? insuranceNumber = null,Object? carteVitaleFichier = null,Object? carteMutuelleFichier = null,}) {
  return _then(_HealthInfo(
fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,birthDate: null == birthDate ? _self.birthDate : birthDate // ignore: cast_nullable_to_non_nullable
as String,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,emergencyContacts: null == emergencyContacts ? _self._emergencyContacts : emergencyContacts // ignore: cast_nullable_to_non_nullable
as List<EmergencyContact>,allergies: null == allergies ? _self.allergies : allergies // ignore: cast_nullable_to_non_nullable
as String,treatments: null == treatments ? _self.treatments : treatments // ignore: cast_nullable_to_non_nullable
as String,conditions: null == conditions ? _self.conditions : conditions // ignore: cast_nullable_to_non_nullable
as String,bloodType: null == bloodType ? _self.bloodType : bloodType // ignore: cast_nullable_to_non_nullable
as String,organDonor: null == organDonor ? _self.organDonor : organDonor // ignore: cast_nullable_to_non_nullable
as String,doctorContact: null == doctorContact ? _self.doctorContact : doctorContact // ignore: cast_nullable_to_non_nullable
as String,insuranceNumber: null == insuranceNumber ? _self.insuranceNumber : insuranceNumber // ignore: cast_nullable_to_non_nullable
as String,carteVitaleFichier: null == carteVitaleFichier ? _self.carteVitaleFichier : carteVitaleFichier // ignore: cast_nullable_to_non_nullable
as String,carteMutuelleFichier: null == carteMutuelleFichier ? _self.carteMutuelleFichier : carteMutuelleFichier // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
