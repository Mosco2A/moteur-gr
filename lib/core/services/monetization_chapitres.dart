/// LE CHAPITRE, UNITE DE VENTE : le devis sur plusieurs chapitres, leur achat
/// d'un seul geste, et l'ouverture d'un nouveau periple.
///
/// Collaborateur de [MonetizationService] (tache 841) : la responsabilite
/// « vente par chapitres ». Non re-exporte.
///
/// POURQUOI UN FICHIER A PART, ET PAS TROIS METHODES DE PLUS DANS
/// [TrailPurchases]. Deux raisons, et la seconde est la vraie.
///
/// LA PREMIERE EST MESUREE : avec ces trois gestes dedans,
/// `monetization_purchases.dart` passait de 319 a 580 lignes et franchissait le
/// plafond de cinq cents que la garde ECR-15 du lot 645 surveille — la garde a
/// rougi, et elle avait raison de rougir.
///
/// LA SECONDE EST QUE CE SONT DEUX RESPONSABILITES. [TrailPurchases] vend UN
/// sentier : devis, debit, complement store, rollback. Ce fichier-ci vend une
/// COMBINAISON de produits et une MARCHE DE PLUS sur un produit deja acquis —
/// deux notions nees de la decision de Christophe du 15/10 (« on peut acheter
/// chapitre 1, chapitre 2, chapitre 1 and 2 ») et de celle du 16/10 (« OUI IL
/// REPAYE ! »). C'est le decoupage que le lot 645-06b a deja applique au reste
/// du service : une classe, une responsabilite, un fichier.
///
/// ET IL NE REFAIT AUCUNE ARITHMETIQUE D'ACHAT. Chaque chapitre est achete par
/// [TrailPurchases.buyTrail], chaque devis par
/// [TrailPurchases.quoteTrail] ou [TrailPurchases.devisAuPrixPlein] : le debit,
/// le complement et le rollback restent ecrits UNE fois. L'inventaire 593 a
/// mesure ce que coutent trois chemins d'achat ; on n'en ouvre pas un
/// quatrieme.
library;

import 'package:logger/logger.dart';

import 'monetization_dependencies.dart';
import 'monetization_entitlements.dart';
import 'monetization_models.dart';
import 'monetization_pricing.dart';
import 'monetization_purchases.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// La vente par chapitres : un, l'autre, les deux, ou une marche de plus.
class VenteParChapitres {
  /// La vente par chapitres s'appuie sur les achats ordinaires de [_achats].
  VenteParChapitres(
    this._deps,
    this._pricing,
    this._entitlements,
    this._achats,
  );

  final MonetizationDependencies _deps;
  final TrailPricing _pricing;
  final TrekEntitlementLedger _entitlements;
  final TrailPurchases _achats;

  /// DEVIS SUR PLUSIEURS CHAPITRES — le prix est la SOMME DES ÉTAPES.
  ///
  /// Règle de Christophe du 15/10 17:45, verbatim : « on achete le sentier
  /// seulement si il n y a pas de chapitres. Sinon par exemple pour le GR20 on
  /// peut acheter chapitre 1, chapitre 2, chapitre 1 and 2 ». Ce devis est la
  /// troisième de ces trois possibilités, et c'est la seule qui demandait
  /// quelque chose de neuf : prendre un chapitre seul, c'est [quoteTrail].
  ///
  /// IL N'Y A AUCUN LOT À CONSTRUIRE EN BOUTIQUE, et ce devis est la preuve de
  /// pourquoi. Le prix est en ÉTAPES, prélevées sur la cagnotte : deux
  /// chapitres coûtent la somme de leurs étapes, point. Il n'y a donc aucune
  /// référence store à déclarer pour « le nord et le sud ensemble », rien à
  /// faire valider chez Google ni chez Apple, et aucune combinaison à prévoir —
  /// trois chapitres en feraient sept, dix en feraient mille. La seule grille
  /// qui existe reste celle des paliers de RECHARGE (`kStepPacks`), et elle ne
  /// bouge pas.
  ///
  /// N'ENGAGE RIEN (lecture seule). Les doublons sont écartés en gardant le
  /// premier rang de chacun : demander deux fois le même chapitre ne le fait
  /// pas payer deux fois.
  Future<DevisDeChapitres> devisDesChapitres(List<String> trailIds) async {
    final vus = <String>{};
    final devis = <TrailQuote>[];
    for (final id in trailIds) {
      if (!vus.add(id)) continue;
      devis.add(await _achats.quoteTrail(id));
    }
    final besoin = devis.fold(0, (s, d) => s + d.stepsNeeded);
    final cagnotte = _deps.wallet.balanceSteps;
    final surLaCagnotte = besoin < cagnotte ? besoin : cagnotte;
    final complement = besoin - surLaCagnotte;
    return DevisDeChapitres(
      devis: devis,
      stepsNeeded: besoin,
      stepsFromWallet: surLaCagnotte,
      complementSteps: complement,
      complementPack: complement > 0
          ? _pricing.smallestPackCovering(complement)
          : null,
    );
  }

  /// ACHÈTE PLUSIEURS CHAPITRES D'UN SEUL GESTE, ou aucun.
  ///
  /// LE TOUT OU RIEN EST LA SEULE CHOSE DE NEUF ICI, et c'est elle qui justifie
  /// la méthode. Chaque chapitre reste un achat ORDINAIRE ([buyTrail]) : même
  /// algorithme, même débit, même rollback, aucun chemin de vente parallèle —
  /// l'inventaire 593 a montré ce que coûtent trois chemins d'achat. Ce que
  /// cette méthode ajoute, c'est le refus AVANT TOUT DÉBIT quand la cagnotte ne
  /// couvre pas le lot entier.
  ///
  /// POURQUOI CE REFUS COMPTE. Sans lui, un randonneur qui demande le nord ET
  /// le sud avec de quoi payer un seul des deux verrait le premier débité et le
  /// second échouer sur un complément store — il se retrouverait à moitié servi
  /// sans l'avoir choisi, et sans savoir lequel il a. Avec lui, il reçoit un
  /// devis qui dit le manque et le plus petit pack qui le couvre, et sa
  /// cagnotte n'a pas bougé.
  ///
  /// CE QU'ELLE NE FAIT PAS : ouvrir un second périple sur un chapitre déjà
  /// possédé. Un chapitre déjà acquis dans la liste ressort en
  /// [PurchaseStatusResult.alreadyOwned] et ne coûte rien — repayer est un
  /// geste explicite ([ouvrirUnNouveauPeriple]), jamais un effet de bord d'un
  /// achat groupé.
  Future<List<PurchaseOutcome>> acheterLesChapitres(
    List<String> trailIds,
  ) async {
    final devis = await devisDesChapitres(trailIds);
    if (!devis.couvertParLaCagnotte) {
      _log.w(
        '[Monetization] lot ${devis.trailIds.join('+')} : la cagnotte ne '
        'couvre pas les ${devis.stepsNeeded} étapes du lot '
        '(${devis.complementSteps} manquantes) -> RIEN débité, rien acheté',
      );
      return [
        for (final d in devis.devis)
          PurchaseOutcome(
            status: PurchaseStatusResult.offlineComplementRequired,
            trailId: d.trailId,
            complementSteps: devis.complementSteps,
            complementPack: devis.complementPack,
          ),
      ];
    }
    final issues = <PurchaseOutcome>[];
    for (final id in devis.trailIds) {
      issues.add(await _achats.buyTrail(id));
    }
    return issues;
  }

  // --- LE PÉRIPLE : REFAIRE UN CHAPITRE EST UN AUTRE ACHAT ------------------

  /// OUVRE UN NOUVEAU PÉRIPLE sur [trailId] — une nouvelle marche, repayée.
  ///
  /// DÉCISION DE CHRISTOPHE DU 16/10 10:09, VERBATIM : « OUI IL REPAYE ! ».
  /// Elle tranche le point T1 du design #101920 et confirme ce qu'il disait
  /// déjà le 11/10 : « il est marche une fois, le refaire c est un autre achat
  /// et il faudra le stocker comme un nouveau périple ».
  ///
  /// LE CONTENU N'EST JAMAIS REVERROUILLÉ, ET C'EST L'AUTRE MOITIÉ DE SA
  /// PENSÉE. Décision du 27/09 (#100698) : la propriété d'un sentier acheté n'a
  /// aucune échéance. Les deux paroles tiennent ensemble parce qu'elles portent
  /// sur deux objets différents — le CONTENU (trace, étapes, lieux, cartes hors
  /// ligne) est acquis à vie et `owned` ne redescend pas ; le PÉRIPLE (une
  /// marche datée, son carnet, son programme) se recrée et se paie. On ne
  /// revend pas le sentier, on vend une marche de plus.
  ///
  /// LE PRIX EST LE PRIX PLEIN, SANS REMISE DE FIDÉLITÉ. `useAcquired: false` :
  /// c'est la lecture littérale de « il repaye », et c'est le seul endroit du
  /// service qui n'escompte pas les étapes déjà acquises. Avec l'escompte, le
  /// besoin tomberait à ZÉRO sur un chapitre soldé — un second périple serait
  /// gratuit, c'est-à-dire exactement l'option 1 que Christophe a écartée.
  ///
  /// ELLE EXIGE QUE LE CONTENU SOIT DÉJÀ ACQUIS. Un chapitre jamais acheté
  /// n'ouvre pas de « second » périple : il s'achète ([buyTrail]), et ce
  /// premier achat ouvre le périple nº 1. Appelée sur un chapitre non possédé,
  /// cette méthode délègue donc à [buyTrail] plutôt que d'inventer un état.
  ///
  /// CE QUE L'ACHAT D'UN PÉRIPLE N'ÉCRIT PAS, ET C'EST VÉRIFIABLE :
  /// rien du carnet. Ni journal, ni sac, ni nuitées, ni session — ce chemin
  /// n'écrit QUE la ligne de droits. Le carnet de la marche précédente reste
  /// donc intact. CE QUI MANQUE ENCORE POUR TENIR TOUTE LA PROMESSE, et il faut
  /// le dire plutôt que de le laisser croire : journal, sac et nuitées sont
  /// rangés par identifiant de SENTIER, pas par périple. Deux marches du MÊME
  /// chapitre écriraient donc dans le même carnet. Partitionner le carnet par
  /// périple est l'ordre 6 du design #101920 et n'est PAS fait ici ; ce
  /// compteur est l'ancrage dont cet ordre 6 avait besoin.
  Future<PurchaseOutcome> ouvrirUnNouveauPeriple(String trailId) async {
    if (_deps.enDemo) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.refuseEnDemo,
        trailId: trailId,
      );
    }
    if (_pricing.aDesChapitres(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.sentierAChapitres,
        trailId: trailId,
      );
    }
    // Contenu pas encore acquis : c'est un PREMIER achat, pas un second
    // périple. Le geste ordinaire s'en charge, et il ouvre le périple nº 1.
    if (!await _entitlements.ownsTrail(trailId)) {
      return _achats.buyTrail(trailId);
    }

    // UN SENTIER GRATUIT N'OUVRE PAS DE PÉRIPLE PAYANT. Son prix est nul : il
    // n'y a rien à débiter, et lui facturer une seconde marche serait inventer
    // un prix que le catalogue ne dit pas.
    if (_pricing.isFreeTrail(trailId)) {
      return PurchaseOutcome(
        status: PurchaseStatusResult.alreadyOwned,
        trailId: trailId,
        peripleNumero: await _entitlements.periplesAchetes(trailId),
      );
    }

    final prix = _pricing.stagesOfTrail(trailId);
    if (prix <= 0) {
      _log.w(
        '[Monetization] $trailId : prix introuvable au catalogue -> nouveau '
        'périple REFUSE (rien debite, aucun droit touche)',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.unknownPrice,
        trailId: trailId,
      );
    }

    // LE PRIX PLEIN : aucun escompte sur les étapes déjà acquises.
    final devis = await _achats.devisAuPrixPlein(trailId);
    if (devis.complementSteps > 0) {
      // LA CAGNOTTE NE SUFFIT PAS : ON NE DÉBITE RIEN, ET ON NE TOUCHE À AUCUN
      // DROIT. Le contenu reste acquis, le périple en cours reste le dernier,
      // et le randonneur reçoit le manque et le pack qui le couvre.
      _log.w(
        '[Monetization] $trailId : nouveau périple à $prix étapes, '
        '${devis.complementSteps} manquantes -> rien débité',
      );
      return PurchaseOutcome(
        status: PurchaseStatusResult.offlineComplementRequired,
        trailId: trailId,
        complementSteps: devis.complementSteps,
        complementPack: devis.complementPack,
      );
    }

    await _deps.wallet.debit(devis.stepsFromWallet);
    final numero = await _entitlements.periplesAchetes(trailId) + 1;
    await _entitlements.markOwned(
      trailId,
      totalStages: prix,
      acquiredStages: prix,
      consumedComplementSteps: 0,
      source: 'wallet',
      peripleNumero: numero,
    );
    _log.i(
      '[Monetization] $trailId : périple nº $numero ouvert '
      '($prix étapes débitées, contenu inchangé et toujours acquis)',
    );
    return PurchaseOutcome(
      status: PurchaseStatusResult.owned,
      trailId: trailId,
      stepsFromWallet: devis.stepsFromWallet,
      peripleNumero: numero,
    );
  }
}
