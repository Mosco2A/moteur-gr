/// LES TROIS ETATS D UN SENTIER, ET LES DEUX GESTES QUI LES RELIENT.
///
/// PRECISION DE CHRISTOPHE DU 27/09 20:41, verbatim : « Ca ajoute seulement au
/// catalogue, il faut faire un telecharger le sentier pour le mettre sur le
/// telephone, on peut aussi le supprimer sauf si on l a achete ».
///
/// La liste distante AJOUTE AU CATALOGUE, et rien de plus. Telecharger est un
/// geste SEPARE, supprimer aussi. C est pourquoi ces etats sont NOMMES ici et non
/// deduits a la volee dans un widget : trois etats redecouverts chacun de leur
/// cote finissent par diverger.
enum TrailState {
  /// ETAT 1 — AU CATALOGUE, PAS SUR LE TELEPHONE.
  ///
  /// La liste distante a fait apparaitre le sentier : on voit sa fiche, son nom,
  /// son prix, ses chiffres — de quoi decider. Ses donnees completes ne sont PAS
  /// la. C est l etat par defaut de tout sentier neuf publie.
  auCatalogue,

  /// ETAT 2 — TELECHARGE SUR LE TELEPHONE.
  ///
  /// Le geste « telecharger » a copie l integralite des donnees en local, de
  /// facon atomique. Le sentier est utilisable sans reseau.
  telecharge,

  /// ETAT 3 — ACHETE.
  ///
  /// Le droit de REALISER est acquis (`MonetizationService.canRealizeTrail`, lot
  /// 594), et le sentier N EST PLUS SUPPRIMABLE. Le sens est net : un randonneur
  /// ne doit pas pouvoir effacer, la veille du depart, ce qu il a paye, et se
  /// retrouver sans donnees sur un sentier sans reseau.
  achete,
}

/// Pourquoi la suppression est refusee, ou `null` si elle est permise.
///
/// UN BOUTON INDISPONIBLE DOIT DIRE POURQUOI. C est la consigne explicite de
/// Christophe : pas de bouton grise sans explication. Cette cause est donc une
/// VALEUR portee par le domaine, que l ecran traduit — et non une condition
/// booleenne enfouie dans un `onPressed: null`.
enum RefusDeSuppression {
  /// Achete : interdiction absolue. Regle de Christophe, telle quelle.
  sentierAchete,

  /// Rien a supprimer : le sentier n est pas sur le telephone.
  pasSurLeTelephone,
}

/// L etat d un sentier, et ce que le randonneur peut en faire.
///
/// TELECHARGER N EST PAS ACHETER, ET LES DEUX VERROUS RESTENT SEPARES. Un sentier
/// peut etre telecharge sans etre achete : le niveau gratuit du modele economique
/// (§2) consulte et PREPARE, et le sentier de demonstration est gratuit et
/// entierement jouable. Le telechargement pose les DONNEES ; l achat donne le
/// droit de REALISER. Aucun des deux ne doit dependre de l autre, et c est
/// pourquoi [copieComplete] et [achete] sont deux entrees independantes et non
/// une echelle a trois barreaux.
///
/// CONSEQUENCE ASSUMEE : un sentier ACHETE mais PAS ENCORE TELECHARGE existe. Son
/// etat est [TrailState.achete] — c est le fait le plus important a montrer —
/// et [peutTelecharger] reste vrai. La suppression, elle, est deja interdite :
/// l interdiction porte sur le DROIT, pas sur la presence des fichiers.
class TrailAvailability {
  const TrailAvailability({
    required this.trailId,
    required this.copieComplete,
    required this.achete,
  });

  final String trailId;

  /// Vrai quand les donnees du sentier sont INTEGRALEMENT sur le telephone.
  ///
  /// OU CET ETAT VIT DANS LE SCHEMA LOCAL, ET IL EXISTAIT DEJA : c est
  /// `trail_manifests.localVersion`, non nul et au niveau de la revision publiee
  /// (`dataVersion`). Le defaut n etait donc pas l absence de l etat mais le fait
  /// que PERSONNE NE L ECRIVAIT apres un telechargement reussi — d ou un sentier
  /// eternellement « a telecharger » et une recopie a chaque ouverture.
  final bool copieComplete;

  /// Vrai quand le droit de realiser est acquis (achat confirme, ou prix nul).
  final bool achete;

  /// L etat a montrer, quand il faut n en montrer qu un.
  TrailState get etat {
    if (achete) return TrailState.achete;
    if (copieComplete) return TrailState.telecharge;
    return TrailState.auCatalogue;
  }

  /// Le geste « telecharger » est-il offert ?
  ///
  /// Oui tant que les donnees ne sont pas la — achete ou pas.
  bool get peutTelecharger => !copieComplete;

  /// Pourquoi « supprimer » est refuse, ou `null` s il est permis.
  RefusDeSuppression? get refusDeSuppression {
    if (achete) return RefusDeSuppression.sentierAchete;
    if (!copieComplete) return RefusDeSuppression.pasSurLeTelephone;
    return null;
  }

  /// Le geste « supprimer » est-il offert ?
  bool get peutSupprimer => refusDeSuppression == null;
}
