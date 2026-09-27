import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:logger/logger.dart';

import '../../../core/error/error_handler.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// CE QU'ON DEMANDE A LA REGIE — et rien de plus (tache 595, B1/B4).
///
/// Deux champs, deux decisions prises ailleurs et jamais recalculees ici :
///   * [unitId] : l'emplacement publicitaire, resolu par `AdConfig` (test par
///     defaut, production injectee au build) ;
///   * [personalized] : ce que la demande a le droit d'emporter, resolu par le
///     dispositif de consentement de l'appli ([ConsentPurpose.advertising]).
///
/// POURQUOI UN OBJET PLUTOT QUE DEUX ARGUMENTS. Parce qu'un test doit pouvoir
/// dire « voici EXACTEMENT ce qui est parti a la regie ». Compter des appels
/// ne suffit pas : l'affirmation utile de la tache 595 est « le refus de la
/// publicite personnalisee change CE QUI PART DE L'APPAREIL », et cela se
/// verifie sur le contenu de la demande, pas sur son existence.
@immutable
class BannerAdRequest {
  const BannerAdRequest({required this.unitId, required this.personalized});

  /// Emplacement publicitaire (ad-unit) vise.
  final String unitId;

  /// Vrai si la publicite a le droit d'etre PERSONNALISEE.
  ///
  /// Faux = `AdRequest(nonPersonalizedAds: true)` : la publicite est toujours
  /// affichee (le modele gratuit-avec-pub tient), mais aucune donnee de
  /// ciblage ne quitte l'appareil.
  final bool personalized;

  @override
  bool operator ==(Object other) =>
      other is BannerAdRequest &&
      other.unitId == unitId &&
      other.personalized == personalized;

  @override
  int get hashCode => Object.hash(unitId, personalized);

  @override
  String toString() =>
      'BannerAdRequest($unitId, personnalisee: $personalized)';
}

/// UNE BANNIERE REELLEMENT CHARGEE, prete a etre posee dans l'arbre.
///
/// [dispose] n'est pas une politesse : une `BannerAd` non liberee continue de
/// vivre cote natif — elle se rafraichit, elle consomme, elle compte des
/// impressions. C'est le point qui fait la difference entre « le trek achete
/// n'affiche plus de pub » et « le trek achete EST sans pub ».
@immutable
class LoadedBanner {
  const LoadedBanner({
    required this.view,
    required this.height,
    required this.dispose,
  });

  /// Le widget a poser (un `AdWidget` en production).
  final Widget view;

  /// Hauteur en pixels logiques que l'emplacement doit reserver.
  final double height;

  /// Libere la publicite cote natif. Appele par Riverpod a la destruction.
  final Future<void> Function() dispose;
}

/// CE QU'IL FAUT SAVOIR FAIRE POUR AFFICHER UNE BANNIERE.
///
/// POURQUOI CETTE COUTURE EXISTE. `AdWidget` refuse d'etre monte tant que la
/// publicite n'est pas chargee, et `BannerAd.load()` passe par un canal natif
/// absent d'un test Flutter. Sans cette frontiere, la regle d'or #99404 ne
/// serait verifiable que par une lecture de code — or c'est precisement la
/// regle qui, si elle casse, fait payer deux fois un randonneur qui a paye.
/// Avec elle, un test COMPTE les demandes parties a la regie : « sans pub »
/// veut dire qu'on ne CHARGE pas, pas qu'on charge et qu'on cache.
abstract interface class BannerAdPresenter {
  /// Charge une banniere pour [request].
  ///
  /// Retourne `null` si rien n'est disponible (reseau, remplissage vide, SDK
  /// absent). NE LEVE JAMAIS : une publicite indisponible n'est pas une panne
  /// de l'application, c'est le cas normal hors ligne.
  Future<LoadedBanner?> load(BannerAdRequest request);
}

/// La regie REELLE (google_mobile_ads).
///
/// BORNEE (parite avec l'amorce du consentement, `AdsConsentService`) : l'API
/// AdMob est a callbacks et peut, hors ligne, ne JAMAIS rappeler — ni succes,
/// ni echec. Un `Completer` non borne resterait pendant pour la duree de vie
/// de l'ecran. On abandonne donc au-dela de [_budget] : aucune banniere,
/// jamais de crash, jamais de fuite.
class GoogleBannerAdPresenter implements BannerAdPresenter {
  GoogleBannerAdPresenter({Duration budget = budgetParDefaut})
      : _budget = budget;

  /// Delai maximum accorde au chargement d'une banniere.
  static const Duration budgetParDefaut = Duration(seconds: 8);

  /// Delai reellement applique (injectable : un test ne doit pas durer 8 s).
  final Duration _budget;

  @override
  Future<LoadedBanner?> load(BannerAdRequest request) async {
    try {
      return await _charger(request).timeout(_budget);
    } on TimeoutException {
      // CAS NORMAL ET PREVU, PAS UNE PANNE : hors ligne ou en reseau lent, une
      // banniere qui n'arrive pas est le comportement attendu. On le dit en
      // une ligne d'information, sans pile d'appel — un pave rouge a chaque
      // demarrage lent serait indiscernable d'un plantage.
      _log.i(
        '[BannerAd] Aucune banniere : budget de chargement '
        '(${_budget.inSeconds} s) depasse. Cas attendu hors ligne.',
      );
      return null;
    } on Object catch (e, st) {
      // Tout le reste est reellement inattendu (SDK absent en test, canal
      // natif indisponible) : trace, jamais propage. Une publicite ne casse
      // pas un ecran.
      ErrorHandler.log(e, stackTrace: st, context: 'GoogleBannerAdPresenter');
      return null;
    }
  }

  Future<LoadedBanner?> _charger(BannerAdRequest request) async {
    final taille = await _tailleAdaptative();
    final resultat = Completer<LoadedBanner?>();
    late final BannerAd banniere;
    banniere = BannerAd(
      adUnitId: request.unitId,
      size: taille,
      // LE CONSENTEMENT DE L'APPLI ARRIVE JUSQU'ICI. C'est le seul endroit ou
      // le choix du randonneur devient un fait technique : sans accord, la
      // demande part `nonPersonalizedAds` et aucun signal de ciblage ne quitte
      // l'appareil. La publicite reste affichee — le modele gratuit-avec-pub
      // n'est pas une question de consentement, le CIBLAGE si.
      request: AdRequest(nonPersonalizedAds: !request.personalized),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (resultat.isCompleted) return;
          resultat.complete(
            LoadedBanner(
              view: AdWidget(ad: ad as BannerAd),
              height: taille.height.toDouble(),
              dispose: ad.dispose,
            ),
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _log.i('[BannerAd] Pas de banniere (${error.code}) : ${error.message}');
          if (!resultat.isCompleted) resultat.complete(null);
        },
      ),
    );
    await banniere.load();
    return resultat.future;
  }

  /// Taille ANCREE ADAPTATIVE a la largeur de l'ecran (reco Google), avec
  /// retour a la banniere standard 320x50 si la plateforme ne repond pas.
  Future<AdSize> _tailleAdaptative() async {
    try {
      final vue = WidgetsBinding.instance.platformDispatcher.views.first;
      final largeur = (vue.physicalSize.width / vue.devicePixelRatio).round();
      final adaptative =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        largeur,
      );
      return adaptative ?? AdSize.banner;
    } on Object {
      return AdSize.banner;
    }
  }
}
