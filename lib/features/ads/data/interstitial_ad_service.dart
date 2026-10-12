/// L'INTERSTITIEL : la mecanique seule, sans aucune regle (tache 838, D2).
///
/// POURQUOI UN SERVICE DE PLUS, ALORS QUE LE DEPOT EN PORTAIT DEJA UN. La
/// mecanique interstitielle existe aussi dans
/// `features/group/services/ad_service.dart`, ou elle sert la monetisation des
/// suiveurs. On ne l'appelle PAS d'ici, et ce n'est pas un doublon par
/// negligence : le plafond des croisements entre features est a ZERO
/// (`couches_respectees_645_test.dart`), `features/group` n'a PAS de facade, et
/// une feche `ads -> group` serait de toute facon a l'envers du sens metier —
/// la publicite ne descend pas du partage de position.
///
/// CE SERVICE-CI VIT DONC LA OU VIVENT LES AUTRES FORMATS, a cote de
/// [BannerAdPresenter] et de [RewardedAdService], et il est ecrit sur le MEME
/// patron qu'eux : chargement injectable, aucune exception propagee, aucune
/// attente infinie. Si un jour les deux mecaniques doivent se rejoindre, c'est
/// par une facade de `group` ou par un deplacement vers `ads` — pas par un
/// import qui traverse.
///
/// IL NE CONNAIT NI LA CADENCE, NI LA RANDO, NI LE SECOURS. Il sait charger et
/// montrer, et c'est tout. La regle est dans
/// [CadenceInterstitiel] (`domain/cadence_interstitiel.dart`), et le
/// raccordement dans `providers/interstitiel_providers.dart`. Un service qui
/// porterait sa propre regle serait une seconde source de verite.
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/ad_config.dart';
import '../../../core/error/error_handler.dart';

/// Service d'INTERSTITIEL — la mecanique pub, sans la decision.
///
/// [enabled] a `false` (mode test, SDK non initialise) court-circuite tout
/// chargement reel : [montrer] rend alors `false` sans effet de bord. C'est
/// exactement la couture de [RewardedAdService], et elle existe pour la meme
/// raison : qu'un test puisse COMPTER les affichages reellement partis plutot
/// que de regarder des pixels.
class InterstitialAdService {
  InterstitialAdService({
    bool enabled = true,
    String? adUnitId,
    Future<void> Function({
      required String adUnitId,
      required AdRequest request,
      required InterstitialAdLoadCallback adLoadCallback,
    })?
    chargerInterstitiel,
  }) : _enabled = enabled,
       _adUnitId = adUnitId ?? AdConfig.interstitialUnitId(),
       _charger = chargerInterstitiel ?? InterstitialAd.load;

  final bool _enabled;
  final String _adUnitId;
  final Future<void> Function({
    required String adUnitId,
    required AdRequest request,
    required InterstitialAdLoadCallback adLoadCallback,
  })
  _charger;

  InterstitialAd? _pub;

  /// Delai de garde du chargement : le SDK appelle normalement un callback, et
  /// ce plafond evite toute attente infinie s'il n'en vient aucun.
  static const Duration _delaiDeChargement = Duration(seconds: 15);

  /// Precharge un interstitiel (best-effort). Sans effet si [enabled] est faux.
  Future<void> precharger() async {
    if (!_enabled || _pub != null) return;
    final fini = Completer<void>();
    try {
      await _charger(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (pub) {
            _pub = pub;
            if (!fini.isCompleted) fini.complete();
          },
          onAdFailedToLoad: (erreur) {
            ErrorHandler.log(
              StateError('interstitiel non charge : ${erreur.message}'),
              context: 'InterstitialAdService.precharger',
            );
            if (!fini.isCompleted) fini.complete();
          },
        ),
      );
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'InterstitialAdService.precharger',
      );
      if (!fini.isCompleted) fini.complete();
    }
    await fini.future.timeout(_delaiDeChargement, onTimeout: () {});
  }

  /// MONTRE l'interstitiel. Rend `true` SI ET SEULEMENT SI il a ete affiche.
  ///
  /// ON REND CE QUI S'EST REELLEMENT PASSE, PAS CE QU'ON A DEMANDE. C'est la
  /// lecon de la tache 639 (`watchRewardedForNoAdsProvider`) : un service qui
  /// rend `true` sans avoir rien montre ferait avancer la cadence pour un
  /// interstitiel qui n'a jamais eu lieu, et le randonneur paierait une
  /// demi-heure de silence qu'il n'a pas eue.
  ///
  /// Charge a la volee si rien n'est precharge. Consomme l'instance apres
  /// affichage : un interstitiel ne se rejoue pas. Jamais d'exception propagee.
  Future<bool> montrer() async {
    if (!_enabled) return false;
    if (_pub == null) await precharger();
    final pub = _pub;
    if (pub == null) return false;
    _pub = null; // consommee

    final ferme = Completer<bool>();
    pub.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (pub) {
        pub.dispose();
        if (!ferme.isCompleted) ferme.complete(true);
      },
      onAdFailedToShowFullScreenContent: (pub, erreur) {
        ErrorHandler.log(
          StateError('interstitiel non affiche : ${erreur.message}'),
          context: 'InterstitialAdService.montrer',
        );
        pub.dispose();
        if (!ferme.isCompleted) ferme.complete(false);
      },
    );

    try {
      await pub.show();
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'InterstitialAdService.show',
      );
      if (!ferme.isCompleted) ferme.complete(false);
    }
    return ferme.future;
  }

  /// Libere l'interstitiel precharge eventuel.
  void dispose() {
    _pub?.dispose();
    _pub = null;
  }
}
