import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/ad_config.dart';
import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/services/consent_service.dart';
import '../../../core/services/monetization_service.dart';
import '../../consent/providers/consent_ui_providers.dart';
import '../data/ads_consent_service.dart';
import '../data/banner_ad_presenter.dart';
import '../data/rewarded_ad_service.dart';

/// Provider du service de consentement pub (UMP/CMP) + init AdMob (A6).
///
/// Instance unique app-wide. Surchargeable en test (fake sans réseau/SDK).
final adsConsentServiceProvider = Provider<AdsConsentService>(
  (ref) => AdsConsentService(),
);

/// Boot pub : résout le consentement UMP puis initialise le SDK si autorisé.
///
/// À `watch` au démarrage (après le bootstrap métier). Retourne `true` si les
/// pubs peuvent être demandées ([AdsConsentService.canRequestAds]). Best-effort
/// : un échec ne bloque pas l'app (aucune pub, jamais de crash).
final adsReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(adsConsentServiceProvider).ensureConsentAndInit();
});

/// Provider du service de pub RÉCOMPENSÉE (rewarded).
///
/// Activé uniquement une fois le SDK initialisé ET le consentement obtenu
/// ([adsReadyProvider]). Sinon `enabled=false` (aucun chargement réel).
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  final ready = ref.watch(adsReadyProvider).value ?? false;
  final svc = RewardedAdService(enabled: ready);
  ref.onDispose(svc.dispose);
  return svc;
});

/// Les mouvements du DROIT d'un trek (un achat confirmé pose `owned`).
///
/// Même signal que celui qui empêche le bandeau démo de rester périmé
/// (`isDemoModeProvider`) : sans lui, acheter un trek pendant que la bannière
/// est à l'écran ne l'éteignait qu'au changement d'écran.
final _trekDroitChangeProvider =
    StreamProvider.autoDispose.family<TrekEntitlement?, String>((ref, trailId) {
  return ref.watch(monetizationServiceProvider).watchEntitlement(trailId);
});

/// Les mouvements de l'état sans-pub APP-WIDE (abonnement, récompense 24 h).
///
/// Une récompense vidéo créditée doit éteindre la bannière DANS LA SECONDE,
/// pas au prochain démarrage : c'est la contrepartie que le randonneur vient
/// littéralement de regarder.
final _sansPubChangeProvider =
    StreamProvider.autoDispose<List<NoAdsStateData>>((ref) {
  return ref.watch(databaseProvider).noAdsDao.watchAll();
});

/// Faut-il AFFICHER une bannière pour ce trek ? (source unique #99404 + UMP)
///
/// `true` seulement si : (1) le trek N'EST PAS sans-pub
/// ([MonetizationService.isNoAdsActive] — owned/abo/reward 24 h/vitrine) ET
/// (2) le consentement pub autorise les requêtes ([adsReadyProvider]). AUCUNE
/// règle sans-pub recalculée ici : on lit la source unique. En prépa gratuite
/// sans consentement pub, aucune bannière (conforme A6).
///
/// TACHE 595 — LA DECISION EST DESORMAIS VIVANTE, ET C'EST LA REGLE D'OR QUI
/// L'EXIGE. Cette décision était prise UNE FOIS et mise en cache pour la durée
/// du processus. Tant qu'elle n'affichait rien, personne ne pouvait le voir ;
/// du jour où elle commande une vraie bannière, elle produit deux défauts
/// opposés et tous deux graves :
///   * un randonneur qui ACHETE le trek (ou regarde une vidéo récompensée)
///     continuait de voir la publicité qu'il venait de supprimer ;
///   * une récompense de 24 h ÉCHUE continuait de valoir sans-pub — soit
///     exactement le « sans-pub à vie » que la règle d'or interdit.
/// On observe donc les deux sources qui peuvent basculer en direct (le droit
/// du trek, l'état sans-pub), et le provider est `autoDispose` : la décision
/// est re-prise à chaque montage d'un emplacement.
///
/// CE QUI RESTE BORNE, ET C'EST ASSUME : une échéance qui PASSE n'émet aucun
/// événement — aucune base ne prévient qu'une date est arrivée. Une récompense
/// qui expire pendant qu'un écran reste ouvert n'est donc vue qu'au montage
/// suivant. On ne pose pas de minuterie pour cela : réveiller l'application
/// toutes les minutes pour rallumer une publicité serait un mauvais échange.
final shouldShowBannerProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, trailId) async {
  // SE BRANCHER SUR LES SIGNAUX VIVANTS AVANT TOUT `await`. Un `ref.watch`
  // pose APRES une suspension n'enregistre pas fiablement sa dependance : la
  // decision resterait figee, et c'est precisement ce qu'on repare ici.
  ref.watch(_trekDroitChangeProvider(trailId));
  ref.watch(_sansPubChangeProvider);
  final adsReady = await ref.watch(adsReadyProvider.future);
  if (!adsReady) return false;
  final monetization = await ref.watch(monetizationReadyProvider.future);
  final noAds = await monetization.isNoAdsActive(trailId);
  return !noAds;
});

/// LA PUBLICITE A-T-ELLE LE DROIT D'ETRE PERSONNALISEE ? (tache 595, B4)
///
/// LE DEFAUT REPARE : le consentement publicitaire vivait A COTE du dispositif
/// de consentement de l'appli. L'appli a pourtant un dispositif complet —
/// granulaire par finalite, horodate, versionne, avec refus global (LOT Y) et
/// effacement de l'article 9 (LOT J/K/N) — et la publicite n'en faisait pas
/// partie. Elle en fait partie maintenant : [ConsentPurpose.advertising] est
/// une finalite comme les autres, avec sa bascule sur le MEME ecran, emportee
/// par le MEME « Tout refuser ».
///
/// CE QUE CE CONSENTEMENT GOUVERNE, ET CE QU'IL NE GOUVERNE PAS. Il gouverne
/// le CIBLAGE, pas l'affichage. Le modele economique dit « gratuit = avec
/// pub » : ce n'est pas une question de consentement, c'est la contrepartie du
/// niveau gratuit, et un interrupteur qui supprimerait la publicite ferait du
/// niveau payant un cadeau. Ce que le randonneur choisit ici, c'est si ses
/// donnees de ciblage quittent l'appareil — exactement la question que pose le
/// CMP, posee au meme endroit que toutes les autres.
///
/// FERME PAR DEFAUT (opt-in, doctrine [ConsentService]) : sans decision, la
/// demande part non personnalisee. Le droit de DEMANDER une publicite reste,
/// lui, gouverne par le CMP ([adsReadyProvider]) — deux verrous distincts,
/// jamais confondus.
final adPersonalizationAllowedProvider = FutureProvider<bool>((ref) async {
  final service = await ref.watch(consentServiceReadyProvider.future);
  // Suivre le FLUX des decisions : un retrait depuis les Reglages doit
  // s'appliquer a la banniere suivante, pas au prochain demarrage.
  await ref.watch(consentStatesProvider.future);
  return service.hasConsent(ConsentPurpose.advertising);
});

/// Faut-il proposer le point d'entree « Options de confidentialite » du CMP ?
///
/// LE DEFAUT REPARE : [AdsConsentService.isPrivacyOptionsRequired] et
/// [AdsConsentService.showPrivacyOptionsForm] etaient ecrits ET testes, et
/// AUCUN geste de l'application ne les appelait. Un ecran que personne ne peut
/// ouvrir n'existe pas — c'est exactement ce que traque l'invariante « toute
/// route a une porte » (tache 573). Leur porte est desormais un bouton de
/// l'ecran de consentement, qui a deja la sienne (Reglages). AUCUNE ROUTE
/// NOUVELLE : le formulaire CMP est une vue NATIVE, pas un ecran Flutter —
/// l'invariante reste verte, et on n'ajoute pas un orphelin de plus.
final adsPrivacyOptionsRequiredProvider = FutureProvider<bool>((ref) async {
  return ref.watch(adsConsentServiceProvider).isPrivacyOptionsRequired();
});

/// La REGIE qui sait charger une banniere (surchargeable en test).
///
/// Instance unique app-wide. La couture existe pour que la regle d'or #99404
/// soit verifiee par un test qui COMPTE les demandes reellement parties, et
/// pas seulement ce qui est peint (cf. [BannerAdPresenter]).
final bannerAdPresenterProvider = Provider<BannerAdPresenter>(
  (ref) => GoogleBannerAdPresenter(),
);

/// LE CONTEXTE « HORS TREK » de la banniere (tache 595, B2).
///
/// Certains ecrans n'ont AUCUN trek en contexte — le catalogue, par exemple, ou
/// l'on choisit justement le sien. La regle d'or y garde pourtant ses deux
/// volets APP-WIDE : « abonne actif = sans pub PARTOUT » et « recompense video
/// = 24 h sans pub ». Seul le volet par trek (« trek achete = sans pub sur CE
/// trek ») n'a rien a dire.
///
/// C'est exactement ce que produit la source unique appelee avec cet
/// identifiant vide : aucun trek ne peut etre possede ni vitrine sous ce nom,
/// donc `isNoAdsActive` se reduit a `abonne || recompense`. On le NOMME plutot
/// que de laisser trainer une chaine vide : une convention implicite est une
/// convention qu'on casse.
const String adContextHorsTrek = '';

/// LA BANNIERE D'UN TREK : chargee UNIQUEMENT si elle a le droit d'exister.
///
/// CE QUI MANQUAIT (mesure tache 595) : la decision d'afficher existait et
/// etait testee ([shouldShowBannerProvider]) ; la chose qui s'affiche,
/// jamais — zero `BannerAd`, zero `AdWidget` dans tout `lib/`. Un
/// interrupteur sans ampoule.
///
/// POURQUOI LE CHARGEMENT VIT DANS UN PROVIDER ET PAS DANS L'ETAT DU WIDGET.
/// Parce que la regle d'or #99404 est liee a un ETAT ACTIF qui peut changer
/// PENDANT que la banniere est a l'ecran : le randonneur achete le trek,
/// regarde une video recompensee, son abonnement expire. Riverpod recalcule
/// alors la dependance et, par [Ref.onDispose], LIBERE la publicite deja
/// chargee — une `BannerAd` non liberee continue de vivre cote natif, de se
/// rafraichir et de compter des impressions. « Sans pub » doit etre un fait,
/// pas un masquage.
///
/// AUCUNE REGLE SANS-PUB N'EST RECALCULEE ICI : on lit la source unique
/// ([MonetizationService.isNoAdsActive]) via [shouldShowBannerProvider]. Les
/// 24 h de la recompense sont deja comptees en base avec leur echeance — on
/// s'y branche, on ne les refait pas.
final bannerAdProvider =
    FutureProvider.autoDispose.family<LoadedBanner?, String>((
  ref,
  trailId,
) async {
  final autorisee = await ref.watch(shouldShowBannerProvider(trailId).future);
  if (!autorisee) return null;

  final personnalisee =
      await ref.watch(adPersonalizationAllowedProvider.future);
  final banniere = await ref.watch(bannerAdPresenterProvider).load(
        BannerAdRequest(
          unitId: AdConfig.bannerUnitId(),
          personalized: personnalisee,
        ),
      );
  if (banniere != null) ref.onDispose(banniere.dispose);
  return banniere;
});

/// Demande une pub rewarded et, si récompensée, crédite le sans-pub 24 h via la
/// SOURCE UNIQUE [MonetizationService.grantRewardNoAds].
///
/// Retourne `true` si le sans-pub 24 h a été crédité (récompense obtenue).
/// Encapsule la mécanique pub + le crédit métier pour l'UI (un seul appel).
final watchRewardedForNoAdsProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final rewarded = ref.watch(rewardedAdServiceProvider);
  final outcome = await rewarded.showRewarded();
  if (outcome == RewardedOutcome.earned) {
    final monetization = await ref.read(monetizationReadyProvider.future);
    await monetization.grantRewardNoAds();
    return true;
  }
  return false;
});
