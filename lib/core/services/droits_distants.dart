/// LES DROITS TELS QUE LE SERVEUR LES ANNONCE, ET LA REGLE QUI TRANCHE (631).
///
/// DECISION D ARCHITECTURE DE CHRISTOPHE (29/09 13:43-13:44) : « je veux que
/// tout soit en base ... seul la copie sur le tel », « sauf les donnees
/// persos ». LE SERVEUR FAIT DONC FOI POUR LE COMPTE — solde d etapes,
/// abonnement, sentiers achetes — et la base du telephone n en est qu une
/// COPIE. Les donnees PERSONNELLES (fiche medicale, profil, contacts, journal,
/// progression, photos) ne montent pas et ne descendent pas : les lots 612,
/// 613, 615, 617, 623 et 630 les ont verrouillees sur l appareil, et ce fichier
/// ne connait AUCUN de ces champs.
///
/// CE FICHIER NE PARLE NI A FIRESTORE NI A FLUTTER. Il ne fait que deux choses,
/// et elles se verifient toutes les deux sans reseau ni telephone : LIRE ce que
/// le serveur annonce, et FUSIONNER avec ce que le telephone a. C est la partie
/// qu il faut pouvoir prouver, donc c est la partie qu on isole.
///
/// ============================================================================
/// LA REGLE DE RESOLUTION, ET POURQUOI ELLE N EST PAS « LE SERVEUR GAGNE »
/// ============================================================================
///
/// La proposition de depart etait : le serveur gagne sur les droits, SAUF une
/// depense faite hors ligne, qui doit remonter au lieu d etre ecrasee.
/// L intention est exacte. Le MOYEN propose — un horodatage par donnee — ne
/// tient pas pour le compte-etapes, et la mesure le montre :
///
///   1. LE TELEPHONE N A PAS D HORLOGE DE REFERENCE. C est le modele du lot
///      610, et il est verrouille par un test : [HorodatageServeur] a un
///      constructeur PRIVE, et la seule fonction qui transforme une horloge en
///      horodatage est INTERDITE a tout fichier de `lib/` — le garde du lot 610
///      (`test/comportement/horloge_du_telephone_610_test.dart`) BALAYE LE
///      TEXTE des sources et echoue sur la simple PRESENCE de son nom, meme en
///      commentaire, ce qui est pourquoi il n est pas ecrit ici. Une depense
///      hors ligne ne peut donc
///      pas se dater elle-meme avec quelque chose que le serveur accepterait de
///      comparer. Arbitrer le solde par horodatage reviendrait a comparer une
///      date de serveur a une date d appareil — exactement ce que le lot 610
///      interdit.
///
///   2. IL N EN A PAS BESOIN, PARCE QUE LES COMPTEURS SONT MONOTONES. Mesure
///      faite dans `wallet_store.dart` : `credit` n augmente QUE
///      `lifetimeEarnedSteps`, `debit` n augmente QUE `lifetimeSpentSteps`, et
///      le solde vaut toujours la difference des deux. Deux compteurs qui ne
///      font que MONTER se fusionnent exactement par leur maximum, sans aucune
///      horloge :
///
///          gagne   = max(gagne_serveur,   gagne_local)
///          depense = max(depense_serveur, depense_local)
///          solde   = gagne - depense
///
///      Ce que ca donne, cas par cas, et c est precisement ce qui etait
///      demande : un credit pose au serveur ARRIVE (le serveur seul fait monter
///      `gagne`) ; une depense faite hors ligne NE REVIENT PAS (le telephone
///      seul fait monter `depense`, et le maximum la garde) ; les deux a la
///      fois se combinent sans se detruire ; et la descente est IDEMPOTENTE —
///      la rejouer dix fois ne change rien, puisqu un maximum deja atteint reste
///      le meme.
///
///   3. LES DROITS DE SENTIER SONT DES LOQUETS. `owned` ne redevient jamais
///      faux et `acquiredStages` ne redescend jamais (non-repaiement des etapes
///      deja acquises, modele §2.5). On fusionne donc par OU et par maximum. Un
///      achat fait ailleurs ARRIVE ; un droit deja acquis ne peut pas
///      disparaitre sur une lecture en retard.
///
///   4. L ABONNEMENT EST LE SEUL QUI PEUT DESCENDRE, ET LUI SEUL EST ARBITRE
///      PAR L HORODATAGE. Une resiliation doit pouvoir RACCOURCIR l echeance :
///      un maximum la rendrait irrevocable, et « jamais a vie, toujours lie a un
///      etat actif » est la regle d or #99404 que le lot 594 a du restaurer. Or
///      le telephone n ecrit JAMAIS l abonnement de lui-meme : il ne fait que
///      transcrire ce que la caisse confirme. Le serveur est donc la seule
///      autorite, et l horodatage du lot 610 tranche : on applique SI ET
///      SEULEMENT SI l instant annonce par le serveur est strictement
///      posterieur au dernier applique.
///
/// EN UNE PHRASE : le serveur fait foi, mais on ne le laisse pas EFFACER ce
/// qu il ne peut pas savoir. Hors ligne, rien ne descend et la copie locale
/// vaut, comme aujourd hui.
library;

import "../data/revision_de_donnee.dart";

/// Chemin du document du solde, sous `users/{uid}`.
const String kCheminSolde = "wallet/current";

/// Chemin de la collection des droits de sentier, sous `users/{uid}`.
const String kEntitlementsPath = "entitlements";

/// Chemin du document d abonnement, sous `users/{uid}`.
///
/// NOUVEAU (631). Le miroir A5 portait deja le solde et les droits de sentier,
/// jamais l abonnement : il n existait donc AUCUN endroit ou un abonnement
/// pouvait vivre ailleurs que dans la memoire d un seul telephone.
const String kSubscriptionPath = "subscription/current";

/// LE SOLDE ANNONCE PAR LE SERVEUR.
///
/// Deux compteurs cumules, pas un solde. Le solde n est PAS lu du serveur : il
/// se RECALCULE (`gagne - depense`) apres fusion. Lire un solde tout fait
/// laisserait passer une valeur incoherente avec ses propres cumuls.
class SoldeDistant {
  const SoldeDistant({required this.cumulGagne, required this.cumulDepense});

  /// Total cumule d etapes GAGNEES. Ne descend jamais.
  final int cumulGagne;

  /// Total cumule d etapes DEPENSEES. Ne descend jamais.
  final int cumulDepense;

  /// Lit le document `users/{uid}/wallet/current`.
  ///
  /// Rend `null` si le document ne porte aucun des deux cumuls : un document
  /// vide ou mal forme ne doit pas se traduire par « zero gagne, zero
  /// depense », ce qui, fusionne, ne ferait rien — mais dirait faussement
  /// qu on a lu quelque chose.
  static SoldeDistant? lire(Map<String, Object?>? brut) {
    if (brut == null) return null;
    final gagne = _entier(brut["lifetime_earned"]);
    final depense = _entier(brut["lifetime_spent"]);
    if (gagne == null && depense == null) return null;
    return SoldeDistant(cumulGagne: gagne ?? 0, cumulDepense: depense ?? 0);
  }

  @override
  String toString() =>
      "SoldeDistant(gagne: $cumulGagne, depense: $cumulDepense)";
}

/// LE DROIT SUR UN SENTIER, ANNONCE PAR LE SERVEUR.
class DroitDeSentierDistant {
  const DroitDeSentierDistant({
    required this.trailId,
    required this.possede,
    required this.etapesAcquises,
    required this.complementConsomme,
  });

  /// Le sentier concerne.
  final String trailId;

  /// Possede = achete. Loquet : ne redevient jamais faux.
  final bool possede;

  /// Etapes deja acquises (base du non-repaiement). Ne redescend jamais.
  final int etapesAcquises;

  /// Complement magasin deja consomme. Ne redescend jamais.
  final int complementConsomme;

  /// Lit un document `users/{uid}/entitlements/{trailId}`.
  static DroitDeSentierDistant? lire(
    String trailId,
    Map<String, Object?>? brut,
  ) {
    if (brut == null) return null;
    final possede = brut["owned"];
    final acquises = _entier(brut["acquired_steps"]);
    final complement = _entier(brut["consumed_complement_steps"]);
    if (possede is! bool && acquises == null && complement == null) return null;
    return DroitDeSentierDistant(
      trailId: trailId,
      possede: possede is bool ? possede : false,
      etapesAcquises: acquises ?? 0,
      complementConsomme: complement ?? 0,
    );
  }

  @override
  String toString() =>
      "DroitDeSentierDistant($trailId, possede: $possede, "
      "acquises: $etapesAcquises)";
}

/// L ABONNEMENT SANS-PUB, ANNONCE PAR LE SERVEUR.
///
/// LE SEUL DES TROIS QUI PORTE UN HORODATAGE, parce que le seul qui peut
/// DESCENDRE (voir l en-tete du fichier).
class AbonnementDistant {
  const AbonnementDistant({
    required this.actif,
    required this.echeance,
    required this.horodatage,
  });

  /// Vrai si le serveur declare l abonnement en cours.
  final bool actif;

  /// Jusqu a quand. `null` quand [actif] est faux.
  ///
  /// UNE ECHEANCE EST OBLIGATOIRE QUAND L ABONNEMENT EST ACTIF (regle d or
  /// #99404, restauree par le lot 594) : un abonnement sans echeance est un
  /// « a vie » deguise. [lire] REFUSE un document actif sans echeance.
  final DateTime? echeance;

  /// L instant SERVEUR de cette annonce. C est lui qui tranche contre la copie
  /// locale.
  final HorodatageServeur horodatage;

  /// Lit le document `users/{uid}/subscription/current`.
  ///
  /// Rend `null` — donc « on n applique rien » — dans trois cas, et chacun est
  /// un refus DELIBERE plutot qu un repli :
  ///  * pas d horodatage lisible : sans instant de serveur, on ne peut pas
  ///    savoir si cette annonce est plus recente que ce qu on a deja ;
  ///  * `active: true` sans `expires_at` : ce serait le « a vie » interdit ;
  ///  * `expires_at` illisible.
  static AbonnementDistant? lire(Map<String, Object?>? brut) {
    if (brut == null) return null;
    final horodatage = HorodatageServeur.annonceParLeServeur(
      brut["updated_at"],
    );
    if (horodatage == null) return null;

    final actif = brut["active"] == true;
    if (!actif) {
      return AbonnementDistant(
        actif: false,
        echeance: null,
        horodatage: horodatage,
      );
    }

    final echeance = HorodatageServeur.annonceParLeServeur(brut["expires_at"]);
    if (echeance == null) return null;
    return AbonnementDistant(
      actif: true,
      echeance: echeance.date,
      horodatage: horodatage,
    );
  }

  @override
  String toString() => "AbonnementDistant(actif: $actif, echeance: $echeance)";
}

/// TOUT CE QUE LE SERVEUR ANNONCE EN UNE PASSE.
class DroitsDistants {
  const DroitsDistants({this.solde, this.trails = const [], this.subscription});

  /// Le solde, ou `null` si le serveur n en annonce pas.
  final SoldeDistant? solde;

  /// Les droits de sentier annonces (un par document).
  final List<DroitDeSentierDistant> trails;

  /// L abonnement, ou `null` si le serveur n en annonce pas.
  final AbonnementDistant? subscription;

  /// Vrai si le serveur n a rien annonce du tout.
  bool get estVide => solde == null && trails.isEmpty && subscription == null;

  @override
  String toString() =>
      "DroitsDistants(solde: $solde, "
      "sentiers: ${trails.length}, abonnement: $subscription)";
}

/// LE SOLDE APRES FUSION — deux cumuls et le solde qui en decoule.
class SoldeFusionne {
  const SoldeFusionne({required this.cumulGagne, required this.cumulDepense});

  final int cumulGagne;
  final int cumulDepense;

  /// LE SOLDE SE DEDUIT, IL NE SE TRANSPORTE PAS.
  ///
  /// Plancher a zero : si un serveur mal renseigne annoncait moins de gagne que
  /// de depense, on n inscrit pas un solde negatif dans la base — `debit` le
  /// refuse de toute facon, et un solde negatif bloquerait tout achat futur
  /// sans rien dire.
  int get solde {
    final calcule = cumulGagne - cumulDepense;
    return calcule < 0 ? 0 : calcule;
  }

  @override
  String toString() =>
      "SoldeFusionne(gagne: $cumulGagne, depense: $cumulDepense, "
      "solde: $solde)";
}

/// FUSION DU SOLDE — maximum de chaque compteur monotone, sans horloge.
///
/// Voir l en-tete du fichier pour la demonstration. En resume : le serveur seul
/// fait monter le gagne, le telephone seul fait monter la depense, et le
/// maximum garde les deux.
SoldeFusionne fusionnerSolde({
  required int gagneLocal,
  required int depenseLocal,
  required SoldeDistant distant,
}) {
  return SoldeFusionne(
    cumulGagne: distant.cumulGagne > gagneLocal
        ? distant.cumulGagne
        : gagneLocal,
    cumulDepense: distant.cumulDepense > depenseLocal
        ? distant.cumulDepense
        : depenseLocal,
  );
}

/// LE DROIT DE SENTIER APRES FUSION.
class DroitDeSentierFusionne {
  const DroitDeSentierFusionne({
    required this.trailId,
    required this.possede,
    required this.etapesAcquises,
    required this.complementConsomme,
  });

  final String trailId;
  final bool possede;
  final int etapesAcquises;
  final int complementConsomme;

  @override
  String toString() =>
      "DroitDeSentierFusionne($trailId, possede: $possede, "
      "acquises: $etapesAcquises)";
}

/// FUSION D UN DROIT DE SENTIER — loquets : OU pour la possession, maximum
/// pour les compteurs.
///
/// [possedeLocal] et les deux compteurs valent zero/faux quand le telephone ne
/// connait pas encore ce sentier : la fusion se reduit alors a « prendre ce que
/// le serveur annonce », ce qui est exactement le cas de la premiere descente.
DroitDeSentierFusionne mergeTrailEntitlement({
  required bool possedeLocal,
  required int etapesAcquisesLocal,
  required int complementConsommeLocal,
  required DroitDeSentierDistant distant,
}) {
  return DroitDeSentierFusionne(
    trailId: distant.trailId,
    possede: possedeLocal || distant.possede,
    etapesAcquises: distant.etapesAcquises > etapesAcquisesLocal
        ? distant.etapesAcquises
        : etapesAcquisesLocal,
    complementConsomme: distant.complementConsomme > complementConsommeLocal
        ? distant.complementConsomme
        : complementConsommeLocal,
  );
}

/// L abonnement annonce doit-il etre applique ?
///
/// SEULEMENT si le serveur parle d un instant STRICTEMENT posterieur a celui
/// deja applique. Strictement : deux annonces du meme instant sont
/// indiscernables, et rejouer la seconde ne pourrait qu ecraser une decision
/// plus fraiche prise dans le meme milliseconde.
///
/// [horodatageApplique] vaut [HorodatageServeur.origine] quand rien n a encore
/// ete applique — et tout instant publie lui est posterieur, donc la premiere
/// annonce descend toujours.
bool abonnementAApplique({
  required HorodatageServeur horodatageApplique,
  required AbonnementDistant distant,
}) {
  return distant.horodatage > horodatageApplique;
}

/// Lit un entier quelle que soit la forme sous laquelle Firestore le rend
/// (`int`, `num`, ou une chaine posee a la main dans la console).
///
/// Une valeur negative est REFUSEE : un cumul ne descend jamais, une valeur
/// negative est donc forcement une erreur de saisie, et l accepter la
/// propagerait dans la base du telephone.
int? _entier(Object? brut) {
  if (brut == null) return null;
  if (brut is int) return brut < 0 ? null : brut;
  if (brut is num) {
    final valeur = brut.round();
    return valeur < 0 ? null : valeur;
  }
  if (brut is String) {
    final valeur = int.tryParse(brut.trim());
    if (valeur == null || valeur < 0) return null;
    return valeur;
  }
  return null;
}
