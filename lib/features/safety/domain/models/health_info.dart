/// LA FICHE D'URGENCE DU RANDONNEUR — LOCAL ONLY (E5.16, REFONDUE TACHE 630).
///
/// ===========================================================================
/// CE QUE CE FICHIER PORTAIT AVANT, ET POURQUOI C'ETAIT INSUFFISANT
/// ===========================================================================
///
/// Il portait CINQ champs : groupe sanguin, allergies, traitements, medecin,
/// assurance. Christophe l'a releve le 26/09 (entree #100661) puis re-releve le
/// 29/09 en testant l'application sur son telephone, verbatim : « Mais on avait
/// dit nom, prenom, info de contact, tu avais fait la liste !!! ».
///
/// LE DEFAUT EST GRAVE POUR UNE APPLICATION DE MONTAGNE : un secouriste qui
/// ouvrait cette fiche apprenait un groupe sanguin et des allergies, mais ne
/// savait NI QUI il soignait NI QUI prevenir. Les contacts a prevenir existaient
/// (`EmergencyContact`) comme fonction SEPAREE — et, mesure faite a la tache 630,
/// AUCUN ECRAN NE PERMETTAIT D'EN AJOUTER UN et le service les gardait en
/// MEMOIRE, donc ils n'auraient de toute facon pas survecu a un redemarrage.
///
/// ===========================================================================
/// LA SOURCE, QUI MANQUAIT — ET C'EST LE COEUR DE LA TACHE 630
/// ===========================================================================
///
/// La liste des cinq champs « a ete decidee, pas etablie » : aucune norme,
/// aucune reference citee nulle part. La reference retenue est LA FICHE
/// D'URGENCE DU TELEPHONE LUI-MEME, et le motif n'est pas esthetique :
/// l'application demande DEJA au randonneur d'y recopier la sienne (clef
/// `health.advice.phoneCard`). Si nos champs ne sont pas ceux du systeme, cette
/// recopie est IMPOSSIBLE.
///
/// CHAQUE CHAMP CI-DESSOUS PORTE SA SOURCE. Les deux documentations officielles
/// lues le 29/09 :
///  * APPLE — « Configuration de votre fiche medicale dans l'app Sante sur votre
///    iPhone », <https://support.apple.com/fr-fr/105072> : « La fiche medicale
///    donne aux premiers intervenants un acces a vos informations medicales
///    essentielles a partir de l'ecran verrouille ». Champs cites : allergies,
///    etat de sante (problemes medicaux), traitements, contacts d'urgence, don
///    d'organes. Et, pour le profil de sante :  « vous pouvez ajouter des
///    informations vous concernant, comme votre date de naissance et votre
///    groupe sanguin » (« Fill out your Health Details », guide iPhone :
///    « your name, date of birth, sex, blood type »).
///  * GOOGLE / ANDROID — « Get help during an emergency with your Android
///    phone », <https://support.google.com/android/answer/9319337> : application
///    Securite > « Your info » > « Medical information » — « To add info like
///    blood type, allergies, or medications, tap the item in the list you want to
///    update » — et « Emergency contacts > Add contact ».
///
/// CE QUE JE N'AI PAS PU SOURCER, ET JE LE DIS PLUTOT QUE DE L'INVENTER : ni
/// Apple ni Google ne documentent noir sur blanc, sur les pages ci-dessus, les
/// champs POIDS, TAILLE et LANGUE PRINCIPALE de la fiche medicale. Ils ne sont
/// donc PAS ajoutes ici. Le poids et la taille vivent de toute facon deja dans le
/// profil du randonneur (`ProfilRandonneurFichier`, tache 623), sous le meme
/// dossier protege.
///
/// ===========================================================================
/// L'ORDRE DES CHAMPS EST CELUI OU UN SECOURISTE LIT — ET IL EST SOURCE AUSSI
/// ===========================================================================
///
/// [1] IDENTITE D'ABORD. Un patient s'identifie avant qu'on agisse sur lui, et
///     les deux fiches systeme mettent le nom en tete. C'est aussi la premiere
///     ligne utile au telephone quand les secours passent le relais a l'hopital.
///
/// [2] QUI PREVENIR ENSUITE. Apple le dit mot pour mot de ce que voient les
///     premiers intervenants : « They can see information like allergies and
///     medical conditions as well as WHO TO CONTACT in case of an emergency »
///     (<https://support.apple.com/en-us/105072>).
///
/// [3] PUIS LE VITAL, DANS L'ORDRE DE L'ANAMNESE D'URGENCE. Le Resuscitation
///     Council UK, « The ABCDE Approach »
///     (<https://www.resus.org.uk/library/abcde-approach>), pose les principes de
///     l'evaluation d'un patient critique — « Use the Airway, Breathing,
///     Circulation, Disability, Exposure (ABCDE) approach », « Do a complete
///     initial assessment », « Take a full clinical history from the patient, any
///     relatives or friends, and other staff » et « Review the patient's notes
///     and charts [...] current medications ». L'anamnese associee suit le
///     mnemonique SAMPLE — Signes, ALLERGIES, MEDICAMENTS, ANTECEDENTS (Past
///     history), dernier repas, circonstances. D'ou l'ordre retenu :
///     ALLERGIES -> TRAITEMENTS -> ANTECEDENTS.
///     Le GROUPE SANGUIN vient APRES, et ce n'est pas une relegation : une
///     allergie tue au moment ou l'on administre un produit, sur le sentier ; le
///     groupe sanguin sert a la transfusion, donc a l'hopital, plus tard.
///
/// [4] ENFIN L'ADMINISTRATIF : medecin traitant, assurance, et les PHOTOS des
///     cartes. C'est ce qu'on recopie a l'accueil, pas ce qu'on lit sous la
///     pluie.
///
/// ===========================================================================
/// CE QUI NE BOUGE PAS D'UN MILLIMETRE
/// ===========================================================================
///
/// Christophe, en majuscules le 27/09 puis le 28/09 10:42 : « Les donnees
/// medicales RESTENT sur le tel ». Le nom et l'adresse sont des donnees
/// personnelles, leur finalite est le secours, et elles ne sortent PAS plus que
/// le reste : meme fichier, meme dossier exclu de la sauvegarde, meme
/// effacement. Les taches 612, 613, 615 et 617 ont ferme ces portes une par une ;
/// la tache 630 n'en ouvre AUCUNE nouvelle.
///
/// Freezed : immutable, copyWith, ==/hashCode, JSON generes.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import 'emergency_contact.dart';

part 'health_info.freezed.dart';
part 'health_info.g.dart';

/// Fiche d'urgence du randonneur — LOCAL ONLY.
///
/// Stockee exclusivement sur le telephone, dans un fichier sous le dossier
/// declare exclu de la sauvegarde systeme (`FicheMedicaleFichier`, tache 613).
/// Pas de Firestore, pas de cloud, pas de sauvegarde Google ou Apple.
///
/// L'ORDRE DE DECLARATION DES CHAMPS EST L'ORDRE DE LECTURE DU SECOURISTE (voir
/// l'en-tete du fichier). Il est repris tel quel par l'ecran et par la
/// notification d'ecran verrouille : une seule fiche, un seul ordre.
@freezed
abstract class HealthInfo with _$HealthInfo {
  const HealthInfo._();

  const factory HealthInfo({
    // ---------------------------------------------------------------- [1] QUI
    /// Nom et prenom du randonneur.
    ///
    /// SOURCE : Apple, « Fill out your Health Details » — « your name, date of
    /// birth, sex, blood type » ; Google, application Securite > « Your info ».
    /// C'EST LA PREMIERE LIGNE QUE LIT UN SECOURISTE : sans elle, la fiche parle
    /// d'un patient anonyme.
    @Default('') String fullName,

    /// Date de naissance, au format ISO `AAAA-MM-JJ` (stockage neutre).
    ///
    /// SOURCE : Apple, « vous pouvez ajouter des informations vous concernant,
    /// comme votre date de naissance et votre groupe sanguin »
    /// (<https://support.apple.com/fr-fr/105072>).
    ///
    /// POURQUOI L'ISO ET PAS `JJ/MM/AAAA` : l'application parle cinq langues, et
    /// `03/04` n'est pas la meme date des deux cotes de la Manche. Le stockage
    /// est neutre, l'affichage est localise.
    @Default('') String birthDate,

    /// Adresse du randonneur.
    ///
    /// SOURCE : fiche d'urgence systeme (champ « adresse » de la fiche du
    /// telephone). MESURE HONNETE : c'est le champ que je n'ai PAS pu citer mot
    /// pour mot sur une page officielle Apple ou Google — les pages listent
    /// « blood type, allergies, medications » a titre d'EXEMPLE et ne donnent
    /// jamais l'inventaire complet. Il est conserve parce que Christophe l'a
    /// nomme explicitement le 26/09 (« son nom prenom adresse ») et parce qu'un
    /// secouriste doit pouvoir dire d'ou vient la personne qu'il evacue.
    @Default('') String address,

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
    @Default(<EmergencyContact>[]) List<EmergencyContact> emergencyContacts,

    // -------------------------------------------------------------- [3] VITAL
    /// Allergies connues (texte libre, ex: 'Penicilline, arachides').
    ///
    /// SOURCE : Apple « Allergies » ; Google « allergies ». PREMIER DU BLOC
    /// VITAL au titre du A de SAMPLE : c'est ce qui tue au moment du soin.
    @Default('') String allergies,

    /// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
    ///
    /// SOURCE : Apple « Traitements » / « Medications » ; Google
    /// « medications ». M de SAMPLE.
    @Default('') String treatments,

    /// ANTECEDENTS ET PROBLEMES MEDICAUX (nouveau, tache 630).
    ///
    /// SOURCE : Apple, « Etat de sante » / « Medical conditions » — cite parmi
    /// ce que les premiers intervenants voient (« allergies and medical
    /// conditions »). P de SAMPLE (Past medical history).
    ///
    /// C'EST LE CHAMP QUI MANQUAIT LE PLUS APRES L'IDENTITE : un diabete, une
    /// epilepsie ou un traitement anticoagulant changent la conduite du
    /// secouriste, et aucun des cinq champs d'origine ne pouvait les porter.
    @Default('') String conditions,

    /// Groupe sanguin — LISTE FERMEE DE HUIT + « je ne sais pas ».
    ///
    /// SOURCE : Etablissement francais du sang pour les huit valeurs (voir
    /// `health_bounds.dart`) ; Apple et Google pour la presence du champ.
    /// PLUS DE SAISIE LIBRE (Christophe, 29/09) : un groupe sanguin mal saisi
    /// sur une fiche d'urgence est PIRE qu'un champ vide.
    @Default('') String bloodType,

    /// Don d'organes — liste fermee de trois valeurs (nouveau, tache 630).
    ///
    /// SOURCE : Apple, « Votre decision de faire don d'organes est accessible
    /// aux autres dans votre fiche medicale ».
    @Default('') String organDonor,

    // ------------------------------------------------------ [4] ADMINISTRATIF
    /// Contact du medecin traitant (nom + telephone).
    ///
    /// PAS DE SOURCE SYSTEME : ni Apple ni Google ne portent ce champ. CONSERVE
    /// QUAND MEME, et la raison est le terrain : le medecin traitant est celui
    /// qui peut confirmer un antecedent a 3 h du matin quand le patient ne parle
    /// plus. Il est en bas parce qu'on l'appelle apres, pas parce qu'il compte
    /// moins.
    @Default('') String doctorContact,

    /// Numero d'assurance / mutuelle / carte europeenne.
    ///
    /// PAS DE SOURCE SYSTEME non plus. CONSERVE MALGRE LA PHOTO DE LA CARTE, et
    /// c'est un choix mesure (tache 630) : un numero SE LIT A VOIX HAUTE au
    /// telephone, une image non. Les deux se completent, ils ne se remplacent
    /// pas.
    @Default('') String insuranceNumber,

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
    @Default('') String carteVitaleFichier,

    /// Nom du fichier de la photo de la carte de mutuelle, ou vide (tache 630).
    @Default('') String carteMutuelleFichier,
  }) = _HealthInfo;

  /// Verifie si au moins un champ est renseigne.
  ///
  /// IL PILOTE DEUX CHOSES, ET C'EST POUR CELA QU'IL DOIT ETRE COMPLET : la
  /// porte de demarrage du trek (`HealthPrepStep.filled`) et l'ECRITURE MEME du
  /// fichier — `FicheMedicaleFichier.ecrire` EFFACE la fiche quand `hasData` est
  /// faux, pour ne pas laisser de trace de passage. Un champ oublie ici serait
  /// donc un champ qui ne s'enregistre pas : la tache 630 en ajoute huit, ils y
  /// sont tous.
  bool get hasData =>
      fullName.isNotEmpty ||
      birthDate.isNotEmpty ||
      address.isNotEmpty ||
      emergencyContacts.isNotEmpty ||
      allergies.isNotEmpty ||
      treatments.isNotEmpty ||
      conditions.isNotEmpty ||
      bloodType.isNotEmpty ||
      organDonor.isNotEmpty ||
      doctorContact.isNotEmpty ||
      insuranceNumber.isNotEmpty ||
      carteVitaleFichier.isNotEmpty ||
      carteMutuelleFichier.isNotEmpty;

  /// Vrai si la fiche porte au moins une des deux photos de carte.
  bool get aUneCarte =>
      carteVitaleFichier.isNotEmpty || carteMutuelleFichier.isNotEmpty;

  /// Conversion depuis JSON (fichier local `medical/fiche.json`).
  ///
  /// LA MIGRATION DES FICHES DEJA SAISIES TIENT DANS CETTE LIGNE, ET ELLE EST
  /// TOTALE. Chaque champ ajoute par la tache 630 porte `@Default('')` : une
  /// fiche ecrite par une version precedente ne contient PAS ces clefs, et
  /// json_serializable prend alors le defaut. Les cinq champs d'origine gardent
  /// leur nom exact dans le JSON (`bloodType`, `allergies`, `treatments`,
  /// `doctorContact`, `insuranceNumber`) — AUCUN N'EST RENOMME, donc aucune
  /// valeur existante n'est perdue ni deplacee. C'est la raison pour laquelle il
  /// n'y a pas de code de migration : il n'y a rien a convertir, seulement des
  /// champs a ajouter. Verrouille par test (suite 630).
  factory HealthInfo.fromJson(Map<String, dynamic> json) =>
      _$HealthInfoFromJson(json);
}
