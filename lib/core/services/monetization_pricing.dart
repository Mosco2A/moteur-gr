/// Le prix des sentiers et des packs : palier d'etape, grille des packs,
/// gratuite, prix lu au catalogue.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « catalogue et prix ». Les constantes de la grille sont re-exportees par
/// `monetization_service.dart` ; la classe ne l'est pas.
library;

import '../config/trail_catalog.dart';
import 'monetization_dependencies.dart';
import 'monetization_models.dart';
import 'wallet_iap_service.dart';

/// Prix d'un PALIER d'étape (1 étape), en euros (StepWays LOT 1, modèle éco).
///
/// Remplace l'ancien `kPricePerStageEur` (1,0). Le prix « catalogue » d'un trek
/// = nombre d'étapes × [kStepTierEur] ; il sert d'ancrage d'affichage. L'achat
/// réel passe par le compte-étapes (`buyTrail`) : wallet d'abord, complément
/// store via un PACK (grille [kStepPacks]).
const double kStepTierEur = 0.99;

/// Étapes créditées et prix EUR de chaque PACK de recharge (grille officielle).
///
/// Les packs sont vendus par le store (consommables StepWays,
/// `wallet_iap_service.dart`). Le complément d'un achat passe par le PLUS PETIT
/// pack couvrant le manque (reco spec §3.1) : évite les SKU unitaires
/// ingérables. Trié par nombre d'étapes croissant (contrat pour `packSteps`).
///
/// L'INVARIANT COMMERCIAL DE CETTE GRILLE EST LA PENTE DÉGRESSIVE : 0,91 puis
/// 0,87 puis 0,80 puis 0,70 l'étape, chaque palier STRICTEMENT moins cher à
/// l'étape que le précédent. Un palier qui casse la pente rend le pack du
/// dessous plus avantageux que celui du dessus, et le randonneur qui prend le
/// gros paie l'étape plus cher que celui qui prend le petit. La garde
/// `la_pente_des_paliers_reste_degressive_813` le refuse par la machine, parce
/// que c'est un chiffre qu'on ajuste sous pression commerciale.
///
/// LE PALIER DE SEIZE EST ENTRÉ LE 11/10/2026 (tâche 813, validé par
/// Christophe à 13:32), SEUL AJOUT, les trois autres inchangés. Le trou de la
/// grille était entre onze et vingt-cinq, exactement là où tombe le meilleur
/// client : deux tronçons de cinq à six jours, donc deux semaines de congés, et
/// le GR20 intégral qui fait seize étapes tout rond.
///
/// POURQUOI 13,99 ET PAS AUTRE CHOSE, et c'est la pente qui l'impose : à 14,99
/// l'étape reviendrait à 0,94, donc PLUS CHER que le pack de onze, et la pente
/// se casserait ; à 12,99 elle tomberait à 0,81 et mangerait le pack de
/// vingt-cinq.
///
/// AUCUN PALIER SOUS ONZE, ET CE N'EST PAS UN OUBLI : le petit acheteur, celui
/// du sentier corse à sept étapes, est servi par le COMPLÉMENT EXACT au tarif
/// unité ([kStepTierEur]). Un palier de plus coûte des démarches dans les DEUX
/// boutiques — on n'en ajoute qu'un.
const List<StepPack> kStepPacks = <StepPack>[
  StepPack(steps: 11, priceEur: 9.99, productId: kWalletCredits11),
  StepPack(steps: 16, priceEur: 13.99, productId: kWalletCredits16),
  StepPack(steps: 25, priceEur: 19.99, productId: kWalletCredits25),
  StepPack(steps: 50, priceEur: 34.99, productId: kWalletCredits50),
];

/// Catalogue et prix : la gratuite d'un sentier, son prix en etapes et en
/// euros, la grille des packs.
class TrailPricing {
  /// Le prix lit les sentiers gratuits et le nombre d'etapes dans [_deps].
  TrailPricing(this._deps);

  final MonetizationDependencies _deps;

  // --- Sentiers GRATUITS (prix nul, tâche 601) ------------------------------

  /// Ensemble effectif des sentiers gratuits (injection > catalogue).
  Set<String> get _gratuits => _deps.freeTrailIds ?? TrailCatalog.freeIds;

  /// Vrai si [trailId] est un sentier GRATUIT — son prix est nul.
  ///
  /// Dérive du PRIX porté par la donnée du catalogue, jamais d'un id de localité
  /// en dur ni d'un drapeau d'exemption (tâche 601).
  bool isFreeTrail(String trailId) => _gratuits.contains(trailId);

  // --- LE PRIX D'UN SENTIER, ET PERSONNE D'AUTRE NE LE DÉCIDE (avenant 614) --

  /// Nombre d'étapes du sentier [trailId] — SOURCE UNIQUE DU PRIX.
  ///
  /// LE TROU QUE CETTE MÉTHODE FERME. `buyTrail` prenait `totalStages` en
  /// paramètre REQUIS : c'était l'APPELANT qui annonçait le prix. Un appelant
  /// qui passait zéro sur un sentier payant traversait tout l'algorithme sans
  /// rien débiter — `need = 0`, `fromWallet = 0`, `complément = 0` — et
  /// atteignait la pose de `owned`. Autrement dit : il existait un chemin par
  /// lequel un sentier PAYANT devenait GRATUIT, et il suffisait de se tromper
  /// d'argument. C'est exactement le motif `isShowcaseTrail` du lot 601 sous un
  /// autre nom : une exemption qui n'est écrite nulle part dans le modèle.
  ///
  /// LA CORRECTION EST DE RETIRER LE CHOIX, PAS DE LE SURVEILLER. Le prix d'un
  /// sentier est une propriété de la DONNÉE du catalogue, comme sa gratuité
  /// ([isFreeTrail]) et comme tout le reste du modèle éco §2 bis. Le service la
  /// lit ; plus aucun appelant ne la déclare, donc plus aucun appelant ne peut
  /// se tromper. Les six écrans qui passaient chacun leur montant n'ont plus
  /// rien à passer.
  ///
  /// Rend 0 pour un sentier INCONNU du catalogue — et 0 n'est pas gratuit :
  /// `buyTrail` refuse alors la vente par [PurchaseStatusResult.unknownPrice]
  /// plutôt que d'offrir le sentier.
  int stagesOfTrail(String trailId) =>
      _deps.stagesOf?.call(trailId) ??
      TrailCatalog.byId(trailId)?.totalStages ??
      0;

  // `eurPriceForTrail` A ÉTÉ RETIRÉE (tâche 806), ET C'EST LE FOND DU LOT.
  //
  // Elle rendait le prix d'un SENTIER en euros, et elle était le « point
  // d'entrée unique du prix affiché » : la vitrine, le catalogue et le cockpit
  // l'appelaient tous les trois. C'est elle qui mettait « Acheter — 6.93 € »
  // sur la carte du Mare a Mare Centre.
  //
  // POURQUOI CE MONTANT EST FAUX PAR CONSTRUCTION, et pas seulement mal écrit.
  // Il vaut `nombre d'étapes × kStepTierEur`, donc il suppose que le randonneur
  // achète ses étapes À L'UNITÉ — le tarif le plus DÉFAVORABLE de la grille.
  // Or le prix d'une étape en euros n'existe pas dans l'absolu : il dépend de
  // la façon dont CHAQUE randonneur a rempli sa cagnotte. À l'unité, 0,99 € ;
  // par pack, 0,91 puis 0,80 puis 0,70 selon la taille ; par cagnotage de
  // l'abonnement, autre chose encore. Un prix en euros affiché sur un sentier
  // décrit donc l'ACHETEUR et non le sentier — et il annonce à tout le monde
  // le tarif de celui qui paie le plus cher.
  //
  // CE QUI RESTE, ET QUI EST LE VRAI PRIX : [stagesOfTrail]. Le Mare a Mare
  // Centre coûte SEPT ÉTAPES, ce nombre est une propriété de la donnée du
  // catalogue, et il ne bouge jamais. [eurPriceForSteps] reste lui aussi, mais
  // pour le COMPTOIR : il chiffre le complément exact au tarif unité, au moment
  // où l'on paie vraiment avec de l'argent.

  // --- Grille de prix -------------------------------------------------------

  /// Prix « catalogue » d'un trek EN ÉTAPES = son nombre d'étapes.
  ///
  /// Remplace `priceForTrail` (qui rendait des euros). Le prix en étapes est
  /// l'unité du compte-étapes ; l'affichage EUR passe par [eurPriceForSteps].
  int stepPriceForTrail({required int totalStages}) => totalStages;

  /// Prix EUR d'un nombre d'étapes au tarif palier ([kStepTierEur]).
  double eurPriceForSteps(int steps) => steps * kStepTierEur;

  /// Nombre d'étapes créditées par un [pack] (raccourci).
  int packSteps(StepPack pack) => pack.steps;

  /// Prix EUR d'un [pack] (raccourci sur la grille).
  double packPriceEur(StepPack pack) => pack.priceEur;

  /// Le plus petit pack couvrant [steps] étapes (reco complément §3.1).
  ///
  /// Retourne le pack de plus petit `steps >= steps demandé` ; si aucun ne
  /// couvre (demande > plus gros pack), retourne le plus gros pack.
  StepPack smallestPackCovering(int steps) {
    for (final pack in kStepPacks) {
      if (pack.steps >= steps) return pack;
    }
    return kStepPacks.last;
  }
}
