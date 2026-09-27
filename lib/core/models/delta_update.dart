import 'package:freezed_annotation/freezed_annotation.dart';

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

    /// MA revision : jusqu ou ce telephone est a jour. `0` = rien n est copie.
    required int fromVersion,

    /// La revision COURANTE du sentier, telle que la liste distante la publie.
    required int toVersion,

    /// Taille du fichier de donnees en octets (pour annoncer le cout au
    /// randonneur qui paie son forfait).
    required int downloadSize,
  }) = _DeltaUpdate;

  /// Deserialisation depuis JSON
  factory DeltaUpdate.fromJson(Map<String, dynamic> json) =>
      _$DeltaUpdateFromJson(json);

  /// Vrai a la PREMIERE copie : rien n est encore sur le telephone.
  ///
  /// Ce n est pas un autre chemin de code, seulement un fait a afficher. A la
  /// revision zero, « tout est plus recent que ma revision » et tout descend :
  /// premiere copie et mise a jour sont litteralement le meme code.
  bool get premiereCopie => fromVersion <= 0;
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

    /// Revision atteinte apres application.
    required int revisionAtteinte,
  }) = _ResultatSynchronisation;

  /// Deserialisation depuis JSON
  factory ResultatSynchronisation.fromJson(Map<String, dynamic> json) =>
      _$ResultatSynchronisationFromJson(json);

  /// Vrai si rien n a bouge (tout etait deja a jour).
  bool get rienAFaire => ecrits == 0 && supprimes == 0;
}
