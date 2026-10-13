/// L'ECART et rien d'autre : « je suis a telle revision, le sentier est publie
/// a telle autre ». Ce qui descend se lit ensuite a la source.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/revision_de_donnee.dart';
import 'niveau_de_telechargement.dart';

part 'delta_update.freezed.dart';
part 'delta_update.g.dart';

/// CE QU IL Y A A PRENDRE POUR UN SENTIER — UNE SEULE QUESTION, UN SEUL ECART.
///
/// MODELE DE REVISION (decision de Christophe du 27/09 20:43, verbatim : « On ne
/// met qu une info de version sur chaque donnee, l appli regarde juste quelles
/// donnees ne sont pas dans la derniere version et les telecharge »). Cet objet
/// ne porte donc QUE l ecart : « je suis a la revision [fromVersion], le sentier
/// est publie a la revision [toVersion] ». Ce qui descendra effectivement se LIT
/// dans les donnees, au moment de les appliquer — cf. `RevisionDeDonnee`.
///
/// CE QUI A DISPARU DE CE MODELE, ET POURQUOI C EST LE POINT DU LOT. Il portait
/// un champ `changedTables`, rempli par `DeltaUpdateService._inferChangedTables(int
/// from, int to)` — une fonction qui retournait les SEPT tables EN DUR sans jamais
/// lire ses deux parametres. Le « delta » etait un rechargement integral deguise,
/// les journaux annoncaient invariablement « 7 tables a MAJ, 0 ignorees », et
/// aucun appelant ne pouvait s en apercevoir : le mensonge etait dans le NOM, pas
/// dans le comportement. La liste n a pas ete rendue plus intelligente, elle a ete
/// SUPPRIMEE : une prevision de ce qui a change n a pas de raison d exister quand
/// la donnee porte elle-meme son numero. Ce qui a REELLEMENT ete touche est
/// desormais un RESULTAT ([ResultatSynchronisation]), pas une prophetie.
@freezed
abstract class DeltaUpdate with _$DeltaUpdate {
  // Freezed exige ce constructeur prive des lors que la classe porte un getter.
  const DeltaUpdate._();

  const factory DeltaUpdate({
    /// Identifiant du sentier concerne
    required String trailId,

    /// MON REPERE : jusqu a QUEL INSTANT ce telephone est a jour.
    /// [HorodatageServeur.origine] = rien n est copie.
    @HorodatageServeurJson() required HorodatageServeur fromVersion,

    /// L INSTANT DE PUBLICATION du sentier, tel que la liste distante l annonce.
    @HorodatageServeurJson() required HorodatageServeur toVersion,

    /// Taille du fichier de donnees en octets (pour annoncer le cout au
    /// randonneur qui paie son forfait).
    required int downloadSize,
  }) = _DeltaUpdate;

  /// Deserialisation depuis JSON
  factory DeltaUpdate.fromJson(Map<String, dynamic> json) =>
      _$DeltaUpdateFromJson(json);

  /// Vrai a la PREMIERE copie : rien n est encore sur le telephone.
  ///
  /// Ce n est pas un autre chemin de code, seulement un fait a afficher. A
  /// l origine, « tout est plus recent que mon repere » et tout descend :
  /// premiere copie et mise a jour sont litteralement le meme code.
  bool get premiereCopie => fromVersion <= HorodatageServeur.origine;
}

/// CE QUI A REELLEMENT ETE FAIT — mesure, pas prevision.
///
/// C est le remplacant honnete de l ancien `changedTables` : il est rempli APRES
/// lecture des donnees, donc il ne peut pas mentir. Un journal qui dit « 1 etape
/// ecrite » quand une altitude a ete corrigee est verifiable ; « 7 tables a MAJ »
/// ne l etait pas.
@freezed
abstract class ResultatSynchronisation with _$ResultatSynchronisation {
  // Idem : un getter sur une classe freezed impose le constructeur prive.
  const ResultatSynchronisation._();

  const factory ResultatSynchronisation({
    /// Familles de donnees effectivement touchees (`stages`, `pois`...).
    required List<String> famillesTouchees,

    /// Nombre d enregistrements ecrits ou mis a jour.
    required int ecrits,

    /// Nombre d enregistrements RETIRES du telephone sur marqueur de suppression.
    required int supprimes,

    /// L INSTANT atteint apres application : le nouveau repere du telephone.
    @HorodatageServeurJson() required HorodatageServeur revisionAtteinte,

    /// JUSQU OU LE SENTIER EST DESCENDU apres cette passe (tache 616).
    ///
    /// `null` uniquement quand rien n a jamais ete copie et que la passe n a rien
    /// copie non plus (niveau « regarder » sur un sentier neuf).
    NiveauDeTelechargement? niveauAtteint,

    /// ENREGISTREMENTS QUI ONT REELLEMENT TRAVERSE LE RESEAU.
    ///
    /// LES QUATRE COMPTEURS CI-DESSOUS REMONTENT DE LA SOURCE JUSQU ICI, ET C EST
    /// LA DEMANDE DE MESURE DE LA TACHE 616. Ils etaient deja comptes par
    /// `MorceauxAPrendre` mais s arretaient dans un journal : aucun appelant, aucun
    /// test ne pouvait les affirmer. Or la seule facon de prouver qu un niveau ne
    /// descend pas plus que son perimetre est de COMPTER — c est ainsi que la tache
    /// 606 a prouve qu un enregistrement transitait au lieu de dix.
    @Default(0) int transferes,

    /// Enregistrements retenus : plus recents que le repere ET dans le niveau.
    @Default(0) int retenus,

    /// Enregistrements descendus puis ECARTES parce que hors du niveau demande.
    ///
    /// Non nul sur une source de fichier des qu on prepare un sentier dont la trace
    /// est publiee : les octets ont traverse le reseau, on ne les ecrit pas. Nul sur
    /// une source interrogeable, qui ne les demande pas. Le chiffre reste visible
    /// meme quand il est genant — c est lui qui dit ou l economie est reelle.
    @Default(0) int ecartesHorsNiveau,

    /// Octets recus, quand la source peut les compter (0 = inconnu).
    @Default(0) int octetsRecus,
  }) = _ResultatSynchronisation;

  /// Deserialisation depuis JSON
  factory ResultatSynchronisation.fromJson(Map<String, dynamic> json) =>
      _$ResultatSynchronisationFromJson(json);

  /// Vrai si rien n a bouge (tout etait deja a jour).
  bool get rienAFaire => ecrits == 0 && supprimes == 0;

  /// PART INUTILE DU TRANSFERT : ce qui est descendu pour rien.
  ///
  /// Comprend [ecartesHorsNiveau] — un enregistrement hors niveau est descendu
  /// pour rien au meme titre qu un enregistrement deja a jour.
  int get transferesEnTrop => transferes - retenus;

  /// Vrai si AUCUN octet n a ete demande au reseau.
  ///
  /// C est l affirmation exacte du niveau « regarder » : pas « peu de donnees »,
  /// RIEN. Elle est verifiable, donc elle est verifiee.
  bool get aucunTransport => transferes == 0 && octetsRecus == 0;
}
