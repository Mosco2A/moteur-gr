/// Les types de la monetisation : packs, niveaux d'acces, devis, issues
/// d'achat et de restauration, et les constantes du modele eco.
///
/// Bibliotheque de la monetisation (lot 645-06b), re-exportee par
/// `monetization_service.dart` : les appelants n'importent que cette racine.
library;

/// Un pack de recharge du compte-étapes : nombre d'étapes + prix EUR + SKU store.
class StepPack {
  const StepPack({
    required this.steps,
    required this.priceEur,
    required this.productId,
  });

  /// Nombre d'étapes créditées par le pack.
  final int steps;

  /// Prix du pack en euros (grille officielle).
  final double priceEur;

  /// ProductId store du pack (consommable, `wallet_iap_service.dart`).
  final String productId;

  @override
  String toString() => 'StepPack($steps étapes, $priceEur€, $productId)';
}

/// Niveau d'accès d'un trek (StepWays LOT 1 — remplace le booléen par-trek).
///
/// Quatre niveaux (`MODELE_ECO.md` du 08/09, §2, + sentier gratuit du 27/09) :
///   - [free]       : trek PAYANT ni possédé ni couvert par un abo → démo
///                    bridée + pub ;
///   - [freeTrail]  : SENTIER GRATUIT (prix nul) → entièrement jouable, ET avec
///                    pub — y compris pendant la marche — parce qu'il n'a rien
///                    payé ;
///   - [subscriber] : abo light actif → SANS PUB PARTOUT + cagnotte d'étapes,
///                    mais **ni les outils complets ni la réalisation** ;
///   - [owned]      : trek acheté → outils COMPLETS pour ce trek, réalisation,
///                    et sans pub sur ce trek.
///
/// POURQUOI UN QUATRIÈME NIVEAU (tâche 601), ET CE QU'IL RÉPARE. Cet enum
/// confondait deux axes que le modèle sépare : le DROIT DE JOUER et le SANS-PUB.
/// Tant que « jouable » et « sans pub » voulaient dire la même chose (`owned`),
/// un sentier de démonstration entièrement jouable ne pouvait exister qu'en
/// étant déclaré `owned` — ce que faisait le drapeau `isShowcaseTrail`, lui
/// offrant au passage le sans-pub PERMANENT réservé à l'achat, donc gratuitement
/// ce que l'abonnement fait payer. Le sentier gratuit est précisément le cas où
/// les deux axes divergent : jouable ET avec pub. Nommer ce niveau supprime
/// l'exemption plutôt que de la déplacer.
enum TrailAccess {
  /// Gratuit sur un sentier PAYANT : démo bridée + pub (trek non débloqué).
  free,

  /// SENTIER GRATUIT (prix nul) : entièrement jouable, avec pub hors mode trek.
  freeTrail,

  /// Abo light actif : sans-pub app-wide + cagnotte. RIEN de plus.
  subscriber,

  /// Possédé — achat confirmé.
  owned;

  /// Le trek est-il JOUABLE (outils complets, carte GPS, journal, réalisation) ?
  ///
  /// [owned] (on a payé) ou [freeTrail] (il n'y avait rien à payer). PAS
  /// l'abonné : **CORRIGE LA CONTRADICTION A2a (tâche 594)** — cette règle
  /// rendait jouable tout ce qui n'était pas [free], donc l'abonné, et un abonné
  /// light obtenait ainsi les outils complets ET la réalisation de TOUS les treks
  /// sans en acheter un seul. L'arbitrage du 08/09 dit exactement l'inverse, et
  /// il **prime sur #99405** : « l'abonné NE débloque PAS les outils complets ni
  /// la réalisation — pour les outils complets d'un trek, il faut l'acheter
  /// (comme le gratuit) ».
  bool get isPlayable =>
      this == TrailAccess.owned || this == TrailAccess.freeTrail;

  /// Faut-il afficher la pub pour ce niveau ? (source unique #99404)
  ///
  /// Pub en [free] ET en [freeTrail] : le sans-pub est la contrepartie d'avoir
  /// PAYÉ (§3, « trek acheté → sans pub sur ce trek »), pas d'être jouable. Un
  /// sentier gratuit n'a rien payé, il reste donc dans le niveau gratuit du §2,
  /// « AVEC pub ». [subscriber] et [owned] sont sans-pub — c'est ce que l'abo
  /// light donne, et c'est tout ce qu'il donne.
  ///
  /// TROIS EXCEPTIONS, ET PAS UNE DE PLUS. Décision de Christophe du **27/09
  /// 14:41**, verbatim : « TOUT PORTER LA PUB sauf si tu es abonné ou sur le
  /// trek que tu as acheté .. Pas la peine de mettre plus de règles » — les
  /// deux qu'il nomme, plus la récompense vidéo de 24 h déjà prévue au §3.
  /// AUCUNE condition de mode trek : ce getter rend `true` pour un sentier
  /// gratuit MÊME PENDANT LA MARCHE, et c'est voulu.
  ///
  /// CE COMMENTAIRE AFFIRMAIT L'INVERSE, ET IL L'ATTRIBUAIT À CHRISTOPHE. Il
  /// annonçait une règle « EN MODE TREK JAMAIS » qui « s'applique par-dessus »,
  /// alors qu'elle avait été retirée le jour même. C'est exactement le motif du
  /// drapeau `isShowcaseTrail` : un commentaire qui survit à la décision qui
  /// l'abroge et sert ensuite de justification. Il est corrigé ici, sur le getter
  /// lui-même, parce que c'est là qu'on vient le lire avant de « réparer ».
  bool get showAds => this == TrailAccess.free || this == TrailAccess.freeTrail;
}

/// Issue d'un versement de la CAGNOTTE de l'abonné (modèle éco §2, A5).
enum SubscriberAllowanceOutcome {
  /// Aucun abonnement actif : rien à verser.
  notSubscriber,

  /// Abonnement actif, mais le MONTANT de la cagnotte n'est pas décidé
  /// ([kSubscriberStepsAllowance] vaut `null`) → rien versé, décision attendue.
  pendingDecision,

  /// La cagnotte de la période courante a déjà été versée (anti double-crédit).
  alreadyGranted,

  /// Cagnotte versée au compte-étapes.
  granted,
}

/// Ce qu'une demande de restauration d'achats a réellement pu faire.
enum PurchaseRestoreStatus {
  /// Le store a été sollicité : les achats restaurés arriveront par la boucle
  /// de complétion (asynchrone).
  requested,

  /// L'achat in-app est indisponible sur cet appareil (ou kill-switch fermé) :
  /// aucune restauration possible, et on le DIT.
  storeUnavailable,
}

/// Résultat d'une restauration d'achats (ce qui a été sollicité, ce qui est
/// redescendu). Sert à ne JAMAIS laisser le bouton « Restaurer » muet.
class PurchaseRestoreOutcome {
  const PurchaseRestoreOutcome({required this.status, this.itemsRestored = 0});

  /// Ce que la demande a pu faire.
  final PurchaseRestoreStatus status;

  /// Nombre de droits redescendus de la sauvegarde (0 si aucune sauvegarde).
  final int itemsRestored;

  @override
  String toString() => 'PurchaseRestoreOutcome($status, $itemsRestored)';
}

/// MONTANT DE LA CAGNOTTE DE L'ABONNÉ — **DÉCIDÉ PAR CHRISTOPHE LE 27/09**.
///
/// Verbatim (27/09 12:26) : « Le prix on l'avait fixé à 2 euros mous = pub nul
/// part et 2 étapes cagnottes par mois ». Deux étapes par mois, versées tant que
/// l'abonnement est actif.
///
/// LA VALEUR A ATTENDU SA DÉCISION, ELLE NE L'A PAS INVENTÉE. La tâche 594 avait
/// implémenté le MÉCANISME complet ([MonetizationService.grantSubscriberAllowance])
/// et laissé cette constante à `null` = non décidé, parce qu'un chiffre inventé
/// dans un modèle économique est une faute et pas un défaut. Le prix avait été
/// fixé à l'oral et jamais consigné : il l'est maintenant, ici et dans
/// `MODELE_ECO.md`.
///
/// CE QUE CETTE CAGNOTTE N'EST PAS : un cadeau de bienvenue. C'est un versement
/// PÉRIODIQUE, borné par l'échéance de l'abonnement (une fois par période, cf.
/// [kSubscriberAllowanceGrantedAtPrefsKey]), qui s'arrête avec l'abonnement. Les
/// étapes déjà versées, elles, restent acquises À VIE — règle d'or #99404 :
/// crédits à vie, sans-pub lié à un état actif. Les deux ne se mélangent pas.
/// LE TYPE RESTE NULLABLE À DESSEIN : `null` = « pas décidé » est un MÉCANISME
/// ([SubscriberAllowanceOutcome.pendingDecision]), pas un reste de brouillon.
/// Il a servi une fois et resservira au prochain chiffre en attente ; le rendre
/// non-nullable parce qu'une valeur est enfin posée supprimerait la seule façon
/// qu'a ce code de dire « je ne sais pas encore » au lieu d'inventer.
// ignore: unnecessary_nullable_for_final_variable_declarations
const int? kSubscriberStepsAllowance = 2;

/// PRIX DE L'ABONNEMENT, EN EUROS PAR MOIS — **DÉCIDÉ PAR CHRISTOPHE LE 27/09**.
///
/// Verbatim (27/09 12:26) : « Le prix on l'avait fixé à 2 euros mous = pub nul
/// part et 2 étapes cagnottes par mois ».
///
/// CE QU'IL ACHÈTE, ET CE QU'IL N'ACHÈTE PAS. Sans publicité PARTOUT tant qu'il
/// est actif, plus [kSubscriberStepsAllowance] étapes par mois. Il ne débloque NI
/// les outils complets NI la réalisation d'un trek : pour cela il faut acheter le
/// trek (arbitrage du 08/09, qui prime sur #99405 et reste entier).
///
/// UN PRIX QUI VIT À L'ORAL EST UN PRIX QU'ON AFFICHE FAUX LE JOUR OÙ ON
/// L'AFFICHE. Il est déclaré ici, en un seul point, et l'écran d'abonnement le
/// lit — il annonçait jusqu'ici ce que l'abo donne et ce qu'il ne donne pas, sans
/// jamais dire ce qu'il coûte.
///
/// La PÉRIODE facturée est le mois. Ne pas la confondre avec
/// [kSubscriptionNoAdsWindow] (31 jours), qui n'est pas une durée commerciale
/// mais le temps pendant lequel l'appareil accepte de croire un reçu sans
/// nouvelle preuve.
const double kSubscriptionPriceEur = 2.0;

/// Clé prefs : début de la période de cagnotte déjà versée (ISO-8601).
const kSubscriberAllowanceGrantedAtPrefsKey =
    'monetization.subscriberAllowanceGrantedAt';

/// Nombre de PHASES du plan d'entraînement réellement jouables en démo bridée.
///
/// Modèle éco §2 : en gratuit, « SAC À DOS + PRÉPA PHYSIQUE jouables *pour de
/// faux* (version bridée) ». Les phases au-delà restent VISIBLES et GRISÉES,
/// jamais cachées. Point de réglage unique du bridage de la prépa physique.
const int kDemoTrainingPhasesPlayable = 1;

/// Nombre de CATÉGORIES du sac réellement jouables en démo bridée.
///
/// Même règle que [kDemoTrainingPhasesPlayable], côté sac à dos : les autres
/// catégories restent visibles, grisées et verrouillées. Avant la tâche 594 le
/// sac n'avait AUCUN bridage — il était intégralement gratuit et complet,
/// contraire à la décision qui exige l'achat du trek (inventaire 593 §M7c).
const int kDemoChecklistCategoriesPlayable = 2;

/// Issue d'un achat de trek via [MonetizationService.buyTrail] (spec §2.5).
///
/// Décrit précisément CE QUI S'EST PASSÉ (pour l'UI et les tests) : succès ou
/// motif d'échec, part payée par le wallet, complément store requis/consommé.
class PurchaseOutcome {
  const PurchaseOutcome({
    required this.status,
    required this.trailId,
    this.stepsFromWallet = 0,
    this.complementSteps = 0,
    this.complementPack,
  });

  /// Résultat global de la tentative.
  final PurchaseStatusResult status;

  /// Trek concerné.
  final String trailId;

  /// Nombre d'étapes débitées du compte-étapes (wallet) pour cet achat.
  final int stepsFromWallet;

  /// Nombre d'étapes du complément couvert par le store (0 si wallet suffisant).
  final int complementSteps;

  /// Pack store utilisé pour le complément (null si aucun complément).
  final StepPack? complementPack;

  /// Vrai si le trek est possédé à l'issue (achat abouti).
  bool get isOwned => status == PurchaseStatusResult.owned;

  @override
  String toString() =>
      'PurchaseOutcome($status, $trailId, '
      'wallet=$stepsFromWallet, complément=$complementSteps)';
}

/// Statut détaillé d'une tentative d'achat.
enum PurchaseStatusResult {
  /// Le trek est désormais possédé (achat confirmé).
  owned,

  /// Déjà possédé avant l'appel (idempotent, rien débité).
  alreadyOwned,

  /// Complément store requis mais l'appareil est hors-ligne → wallet rollback.
  offlineComplementRequired,

  /// Complément store nécessaire mais échoué/annulé/non initié → wallet rollback.
  complementFailed,

  /// PRIX INTROUVABLE : le sentier n'est pas au catalogue, donc invendable.
  ///
  /// LE SECOND VERROU DE L'AVENANT 614, et il ne fait pas doublon avec le
  /// premier. Retirer `totalStages` de [MonetizationService.buyTrail] empêche un
  /// APPELANT d'annoncer un prix nul ; il n'empêche pas le CATALOGUE de ne rien
  /// savoir d'un identifiant. Un sentier absent du catalogue rend 0 étape, et 0
  /// étape traverserait l'algorithme sans débit jusqu'à poser `owned` — le
  /// sentier serait OFFERT. On refuse donc explicitement, et on le NOMME.
  ///
  /// UN SENTIER GRATUIT N'ARRIVE JAMAIS ICI, et c'est toute la différence. Sa
  /// gratuité est lue au catalogue ([MonetizationService.isFreeTrail]) et
  /// traitée AVANT ce refus, par [alreadyOwned] : il reste jouable sans débit,
  /// conformément à la décision de Christophe du 27/09 sur le sentier démo.
  /// « Prix nul parce que le catalogue le dit » et « prix nul parce qu'on ne
  /// sait pas » sont deux choses, et ce statut n'existe que pour la seconde.
  unknownPrice,

  /// REFUSE PARCE QU'ON EST EN DEMO (tache 634, DEM-260929-1123).
  ///
  /// Christophe, le 29/09 : « ON EST EN MODE DEMO » = rien ne compte, « pas
  /// d etapes gagnees, pas de diplome, pas de droits, rien en base ». Une
  /// demonstration qui deduirait des etapes du compte, ou qui poserait un droit
  /// acquis, ne serait plus une demonstration.
  ///
  /// CE STATUT EXISTE POUR ETRE LU. Le refus n'est pas silencieux : l'ecran le
  /// recoit et peut le dire, la ou un `false` muet aurait ressemble a une
  /// panne.
  refuseEnDemo,
}

/// Devis d'achat/reprise d'un trek (spec §2.4/§2.5).
class TrailQuote {
  const TrailQuote({
    required this.trailId,
    required this.totalStages,
    required this.acquiredStages,
    required this.stepsNeeded,
    required this.stepsFromWallet,
    required this.complementSteps,
    this.complementPack,
  });

  /// Trek concerné.
  final String trailId;

  /// Nombre total d'étapes du trek.
  final int totalStages;

  /// Étapes déjà acquises (base = ne pas repayer).
  final int acquiredStages;

  /// Étapes restant à acquérir (`totalStages - acquiredStages`, ≥ 0).
  final int stepsNeeded;

  /// Part du besoin couverte par le wallet (`min(wallet, stepsNeeded)`).
  final int stepsFromWallet;

  /// Complément store (`stepsNeeded - stepsFromWallet`, ≥ 0).
  final int complementSteps;

  /// Plus petit pack couvrant le complément (null si complément = 0).
  final StepPack? complementPack;

  /// Prix EUR à régler au store pour le complément (0 si wallet suffisant).
  double get complementPriceEur => complementPack?.priceEur ?? 0.0;

  @override
  String toString() =>
      'TrailQuote($trailId, besoin=$stepsNeeded, '
      'wallet=$stepsFromWallet, complément=$complementSteps)';
}

/// Features disponibles selon le mode (gratuit ou premium).
///
/// En mode gratuit : préparation avec pub + démo limitée.
/// En mode premium (jouable) : carte GPS tracking journal diplôme
/// goodies + 2 suiveurs gratuits, SANS pub.
class TrailFeatures {
  const TrailFeatures({
    required this.hasAds,
    required this.isDemo,
    required this.hasGpsTracking,
    required this.hasJournal,
    required this.hasDiploma,
    required this.hasGoodies,
    required this.freeFollowerSlots,
    required this.hasPreparation,
  });

  /// Publicités affichées
  final bool hasAds;

  /// Mode démonstration (fonctionnalités limitées)
  final bool isDemo;

  /// Carte GPS + suivi en direct
  final bool hasGpsTracking;

  /// Journal de bord
  final bool hasJournal;

  /// Diplôme de fin de trek
  final bool hasDiploma;

  /// Boutique goodies
  final bool hasGoodies;

  /// Nombre de suiveurs gratuits (0 en gratuit, 2 en premium)
  final int freeFollowerSlots;

  /// Accès à la préparation du trek
  final bool hasPreparation;

  /// Copie en changeant l'affichage de la pub (l'abonné light garde la démo
  /// bridée mais n'a PAS de pub — modèle éco §2 + règle d'or #99404).
  TrailFeatures withAds(bool showAds) {
    if (showAds == hasAds) return this;
    return TrailFeatures(
      hasAds: showAds,
      isDemo: isDemo,
      hasGpsTracking: hasGpsTracking,
      hasJournal: hasJournal,
      hasDiploma: hasDiploma,
      hasGoodies: hasGoodies,
      freeFollowerSlots: freeFollowerSlots,
      hasPreparation: hasPreparation,
    );
  }
}
