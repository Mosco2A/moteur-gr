/// L'acces a un trek : son niveau (possede, gratuit, abonne, gratuit bride),
/// le verrou de realisation, la regle sans-pub et les fonctions jouables.
///
/// Collaborateur de [MonetizationService] (lot 645-06b) : la responsabilite
/// « acces ». Il ne lit aucune table lui-meme : il COMBINE les quatre faits
/// que les autres collaborateurs etablissent (possession, gratuite,
/// abonnement, recompense), recus en parametres nommes. Non re-exporte.
library;

import '../config/ad_config.dart';
import 'monetization_models.dart';

/// La politique d'acces d'un trek, source unique du niveau et du sans-pub.
class TrailAccessPolicy {
  /// La politique combine les quatre predicats qu'on lui donne.
  TrailAccessPolicy({
    required this.ownsTrail,
    required this.isFreeTrail,
    required this.isSubscriberActive,
    required this.isRewardNoAdsActive,
  });

  /// Vrai si le trek est POSSEDE (achat confirme store).
  final Future<bool> Function(String trailId) ownsTrail;

  /// Vrai si le trek est un sentier GRATUIT (prix nul au catalogue).
  final bool Function(String trailId) isFreeTrail;

  /// Vrai si un abonnement sans-pub est ACTIF.
  final Future<bool> Function() isSubscriberActive;

  /// Vrai si une recompense sans-pub de 24 h est ACTIVE.
  final Future<bool> Function() isRewardNoAdsActive;

  /// Niveau d'accès effectif du trek (spec §2.4) :
  /// owned > freeTrail > subscriber > free.
  ///
  /// Priorité : possédé → [TrailAccess.owned] ; sinon sentier GRATUIT →
  /// [TrailAccess.freeTrail] ; sinon abo actif → [TrailAccess.subscriber] ;
  /// sinon [TrailAccess.free] (démo bridée + pub).
  ///
  /// POURQUOI LE SENTIER GRATUIT PASSE AVANT L'ABONNÉ : le niveau doit rester
  /// JOUABLE pour un abonné qui marche la démo. Son sans-pub, lui, ne dépend pas
  /// de ce niveau — [isNoAdsActive] interroge l'abonnement séparément, parce que
  /// « jouable » et « sans pub » sont deux axes distincts (tâche 601).
  ///
  /// ET POURQUOI `owned` PASSE AVANT LE GRATUIT : si un sentier gratuit devenait
  /// payant un jour, un randonneur qui l'a réellement acheté garde son droit.
  Future<TrailAccess> accessFor(String trailId) async {
    if (await ownsTrail(trailId)) return TrailAccess.owned;
    if (isFreeTrail(trailId)) return TrailAccess.freeTrail;
    if (await isSubscriberActive()) return TrailAccess.subscriber;
    return TrailAccess.free;
  }

  /// LE DROIT DE **RÉALISER** LE TREK [trailId] (tâche 594, A1).
  ///
  /// SOURCE UNIQUE du verrou de réalisation. Vrai pour un trek ACHETÉ, et pour
  /// un SENTIER GRATUIT — dont il n'y avait rien à acheter : `accessFor.isPlayable`.
  ///
  /// CE QUI MANQUAIT. Le modèle éco réserve la réalisation au trek acheté
  /// (§2, « Trek acheté : outils COMPLETS … + réalisation »). Le code ne la
  /// verrouillait nulle part : « Démarrer la randonnée » n'avait qu'une
  /// condition de PRÉPARATION (itinéraire + date + programme), et le
  /// démarrage de session n'interrogeait NI ce service NI les droits d'achat.
  /// N'importe qui démarrait, enregistrait et terminait le parcours entier
  /// sans payer — la contradiction la plus coûteuse de l'inventaire 593 (§M2),
  /// et la seule atteignable en trois gestes depuis l'accueil.
  ///
  /// L'ABONNÉ N'EST PAS CONCERNÉ : l'abo light ne débloque pas la réalisation
  /// (arbitrage du 08/09, qui prime sur #99405). Il faut acheter le trek.
  ///
  /// HORS-LIGNE : dérive des droits Drift LOCAUX, aucun appel réseau — un
  /// payeur n'est jamais bloqué faute de réseau sur le sentier.
  Future<bool> canRealizeTrail(String trailId) async {
    return (await accessFor(trailId)).isPlayable;
  }

  /// SOURCE UNIQUE de la règle sans-pub (#99404) :
  /// `ownsTrail(trailId) || isSubscriberActive || isRewardNoAdsActive`.
  ///
  /// LE SANS-PUB EST LA CONTREPARTIE D'AVOIR PAYÉ, jamais d'être jouable
  /// (modèle éco §3 : « trek acheté → sans pub sur ce trek »). Un SENTIER
  /// GRATUIT ([TrailAccess.freeTrail]) est entièrement jouable et n'a rien
  /// payé : il relève du niveau gratuit du §2, « AVEC pub ». C'est ce que
  /// `accessFor` produit, et la nuance n'est pas décorative — le drapeau
  /// vitrine, lui, résolvait le sentier de démonstration en `owned` et lui
  /// offrait donc le sans-pub PERMANENT réservé à l'achat : il donnait
  /// gratuitement ce que l'abonnement fait payer (tâche 601).
  ///
  /// CE QUI RESTE VRAI APRÈS UNE ANNULATION D'ABONNEMENT (règle de Chris,
  /// 27/09 12:27 : « quand il arrête l'abonnement il revoit la pub partout sauf
  /// sur les sentiers achetés ») : la première condition ne porte AUCUNE
  /// échéance — la propriété d'un sentier est permanente. Arrêter l'abonnement
  /// éteint la deuxième et laisse la première intacte.
  ///
  /// Aucune UI ne recalcule cette règle ; `AdService.shouldShowAd(isPaid: …)`
  /// se branche dessus (branchement app-wide = ST7, hors périmètre ST4).
  Future<bool> isNoAdsActive(String trailId) async {
    // MODE PUBS DE TEST : SEUL L'ABONNEMENT ETEINT LA PUBLICITE
    // (tache 639, DEM-260930-1224).
    //
    // La demande de Christophe : « Et j aimerais voir les pubs sur la version de
    // test », et la règle posée avec Skynet : « bannière et vidéo de test
    // visibles sur tout sentier tant qu'on n'est pas abonné ». Sans cette
    // dérogation, un testeur qui possède le sentier qu'il teste ne voit JAMAIS de
    // publicité — l'exception « acheté » suffit à tout éteindre, et c'est
    // exactement ce qui s'est passé quand le sentier gratuit a disparu du
    // catalogue.
    //
    // L'ABONNEMENT RESTE RESPECTE, ET C'EST VOULU : c'est le seul des trois états
    // qui se PAIE en argent tous les mois. Le priver de ce qu'il paie, même sur un
    // build de test, serait la mauvaise dérogation — et c'est aussi ce qui permet
    // de VERIFIER que l'abonnement éteint bien la publicité.
    //
    // ELLE NE PEUT PAS ATTEINDRE LA PRODUCTION : [AdConfig.testAdsForced] rend
    // `false` dès qu'un ad-unit de production est injecté, quel que soit le
    // `--dart-define`. Un build de release porte ses vrais identifiants.
    if (AdConfig.testAdsForced) return isSubscriberActive();

    // ACHETÉ : permanent, sans échéance (le « sauf » de la règle de Chris).
    if (await accessFor(trailId) == TrailAccess.owned) return true;
    if (await isSubscriberActive()) return true;
    if (await isRewardNoAdsActive()) return true;
    return false;
  }

  // --- Features (rétro-compat) ----------------------------------------------

  /// Features du mode gratuit : préparation avec pub + démo.
  TrailFeatures getTrialFeatures() {
    return const TrailFeatures(
      hasAds: true,
      isDemo: true,
      hasGpsTracking: false,
      hasJournal: false,
      hasDiploma: false,
      hasGoodies: false,
      freeFollowerSlots: 0,
      hasPreparation: true,
    );
  }

  /// Features du mode premium (jouable) : tout, sans pub.
  TrailFeatures getPremiumFeatures() {
    return const TrailFeatures(
      hasAds: false,
      isDemo: false,
      hasGpsTracking: true,
      hasJournal: true,
      hasDiploma: true,
      hasGoodies: true,
      freeFollowerSlots: 2,
      hasPreparation: true,
    );
  }

  /// Features applicables pour un trek : premium si JOUABLE (trek acheté ou
  /// vitrine), sinon démo bridée. Décision dérivée d'[accessFor].
  ///
  /// LA PUB EST DÉCIDÉE À PART (règle d'or #99404) : l'abonné light reste en
  /// démo bridée — il n'a pas acheté le trek — mais il n'a PAS de pub. Les deux
  /// axes viennent de la même source ([TrailAccess.isPlayable] et
  /// [TrailAccess.showAds]), ils ne sont simplement plus confondus.
  Future<TrailFeatures> featuresForTrail(String trailId) async {
    final access = await accessFor(trailId);
    final base = access.isPlayable ? getPremiumFeatures() : getTrialFeatures();
    return base.withAds(access.showAds);
  }

  /// Vrai si le trek est en mode démo (non jouable).
  ///
  /// Un trek est en démo s'il n'est ni possédé, ni couvert par un abo, ni
  /// vitrine (parité GR20). Async car dérive des droits Drift.
  Future<bool> isDemoMode(String trailId) async {
    final access = await accessFor(trailId);
    return !access.isPlayable;
  }
}
