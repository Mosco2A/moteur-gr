/// LE RACCORDEMENT DE L'INTERSTITIEL : l'horloge d'utilisation, la memoire du
/// dernier affichage, et le geste qui ouvre — ou refuse (tache 838, D2).
///
/// LA REGLE N'EST PAS ICI, elle est dans `domain/cadence_interstitiel.dart` et
/// elle ne connait rien du monde. Ce fichier apporte les FAITS a cette
/// decision : combien de temps l'application a ete utilisee, quand le dernier
/// interstitiel est tombe, si une rando est en cours, si le randonneur a paye
/// le silence, et si le consentement autorise a demander quoi que ce soit.
///
/// AUCUNE REGLE SANS-PUB N'EST RECALCULEE : on lit la source unique (#99404),
/// `MonetizationService.isNoAdsActive`, exactement comme la banniere. Et la
/// question « une rando est-elle en cours ? » est posee au MEME provider que
/// la banniere, [enModeTrekProvider] — il n'y a pas deux definitions de la
/// marche dans ce depot.
library;

import 'dart:async';

import 'package:flutter/widgets.dart'
    show AppLifecycleListener, AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monetization_providers.dart';
import '../data/interstitial_ad_service.dart';
import '../domain/cadence_interstitiel.dart';
import 'ads_providers.dart';

/// L'HORLOGE D'UTILISATION — elle ne tourne QUE devant les yeux du randonneur.
///
/// POURQUOI UNE HORLOGE A PART, ET PAS `DateTime.now()`. Christophe a dit
/// « demi-heures [...] d utilisation », pas « demi-heures ». La difference est
/// entiere : une application ouverte trois minutes le matin et trois minutes le
/// soir montrerait un interstitiel a chaque ouverture si l'on comptait le temps
/// de la montre, alors que le randonneur ne l'a utilisee que six minutes. Cette
/// horloge s'arrete quand l'application part en arriere-plan et reprend quand
/// elle revient.
///
/// ELLE NE PERSISTE RIEN, ET C'EST ASSUME. Fermer l'application remet le
/// compteur a zero, donc le premier interstitiel d'une session tombe apres une
/// demi-heure d'usage de CETTE session. C'est le choix le plus favorable au
/// randonneur, et il evite d'ecrire une preference de plus pour une publicite.
class HorlogeDUtilisation {
  /// [maintenant] est injectable : un test decide de l'heure qu'il est.
  HorlogeDUtilisation({DateTime Function()? maintenant})
    : _maintenant = maintenant ?? DateTime.now {
    _depuis = _maintenant();
  }

  final DateTime Function() _maintenant;

  /// Le temps deja accumule, hors tranche en cours.
  Duration _accumule = Duration.zero;

  /// Le debut de la tranche en cours, ou `null` en arriere-plan.
  DateTime? _depuis;

  /// Le temps d'utilisation total, tranche en cours comprise.
  Duration get utilisation {
    final debut = _depuis;
    if (debut == null) return _accumule;
    return _accumule + _maintenant().difference(debut);
  }

  /// L'application revient devant les yeux : l'horloge repart.
  void reprendre() => _depuis ??= _maintenant();

  /// L'application part en arriere-plan : on encaisse la tranche, puis on
  /// s'arrete.
  void suspendre() {
    final debut = _depuis;
    if (debut == null) return;
    _accumule += _maintenant().difference(debut);
    _depuis = null;
  }

  /// Suit le cycle de vie de l'application.
  void suivreLeCycleDeVie(AppLifecycleState etat) {
    if (etat == AppLifecycleState.resumed) {
      reprendre();
    } else {
      suspendre();
    }
  }
}

/// L'horloge d'utilisation de l'application — une seule, armee au cycle de vie.
final horlogeDUtilisationProvider = Provider<HorlogeDUtilisation>((ref) {
  final horloge = HorlogeDUtilisation();
  // LE CYCLE DE VIE EST ARME ICI, ET IL EST RENDU EN SE FERMANT. Sans ce
  // `onDispose`, un conteneur detruit laisserait un auditeur de cycle de vie
  // derriere lui — et le cadre de test refuse ce genre de survivant.
  final cycle = AppLifecycleListener(onStateChange: horloge.suivreLeCycleDeVie);
  ref.onDispose(cycle.dispose);
  return horloge;
});

/// LE TEMPS D'UTILISATION AU DERNIER INTERSTITIEL — la memoire de la cadence.
///
/// `Duration.zero` au lancement : le premier interstitiel tombe donc apres une
/// demi-heure d'utilisation, et pas sur le premier ecran ouvert.
class DernierInterstitielNotifier extends Notifier<Duration> {
  @override
  Duration build() => Duration.zero;

  /// Note qu'un interstitiel VIENT D'ETRE MONTRE, a [utilisation].
  ///
  /// APPELE SEULEMENT APRES UN AFFICHAGE REEL. Avancer la cadence sur une
  /// simple TENTATIVE ferait payer au randonneur une demi-heure de silence
  /// qu'il n'a pas eue — c'est la faute que la tache 639 a mesuree sur la video
  /// recompensee, qui annoncait « merci » sans avoir rien accorde.
  void montreA(Duration utilisation) => state = utilisation;
}

/// Le temps d'utilisation au dernier interstitiel affiche.
final dernierInterstitielProvider =
    NotifierProvider<DernierInterstitielNotifier, Duration>(
      DernierInterstitielNotifier.new,
    );

/// LA REGIE QUI SAIT MONTRER UN INTERSTITIEL (surchargeable en test).
///
/// Activee uniquement une fois le SDK initialise ET le consentement obtenu
/// ([adsReadyProvider]) — meme couture que [rewardedAdServiceProvider]. La
/// decision de MONTRER, elle, n'est pas ici : voir [Interstitiel].
final interstitialAdServiceProvider = Provider<InterstitialAdService>((ref) {
  final pret = ref.watch(adsReadyProvider).value ?? false;
  final service = InterstitialAdService(enabled: pret);
  ref.onDispose(service.dispose);
  return service;
});

/// LE GESTE : ouvrir un interstitiel SI l'heure est venue, et jamais autrement.
///
/// IL EST APPELE A L'ARRIVEE SUR UN ECRAN, et c'est le seul moment acceptable
/// pour un format qui prend tout l'ecran : le randonneur vient de changer de
/// contexte, il n'est pas en train de lire ni de saisir quelque chose.
class Interstitiel {
  /// [ref] donne acces aux faits que la cadence demande.
  Interstitiel(Ref ref) : _ref = ref;

  final Ref _ref;

  /// RASSEMBLE LES FAITS, PUIS LAISSE LA DECISION TRANCHER.
  ///
  /// Rend `true` si un interstitiel a ETE MONTRE. Jamais d'exception : une
  /// publicite ne doit pas pouvoir casser une navigation.
  Future<bool> siLHeureEstVenue(String chemin) async {
    try {
      // LA RANDO ET LE SECOURS SONT DEMANDES AVANT TOUT LE RESTE, et c'est une
      // economie autant qu'une regle : sur ces deux refus, on ne lit ni la
      // base de monetisation ni le consentement.
      final enRando = _ref.read(enModeTrekProvider);
      if (enRando || kCheminsSansInterstitiel.contains(chemin)) return false;

      final pubAutorisee = await _ref.read(adsReadyProvider.future);
      // LE CONTEXTE EST « HORS TREK », ET C'EST LE BON POUR CE FORMAT. Un
      // interstitiel n'appartient a aucun sentier : la question qu'il pose est
      // app-wide, donc `isNoAdsActive` se reduit a « abonne ou recompense »
      // (cf. [adContextHorsTrek]).
      final monetisation = await _ref.read(monetizationReadyProvider.future);
      final sansPub = await monetisation.isNoAdsActive(adContextHorsTrek);

      final horloge = _ref.read(horlogeDUtilisationProvider);
      final moment = MomentDInterstitiel(
        utilisation: horloge.utilisation,
        utilisationAuDernier: _ref.read(dernierInterstitielProvider),
        enRando: enRando,
        chemin: chemin,
        sansPub: sansPub,
        pubAutorisee: pubAutorisee,
      );
      if (!moment.autorise) return false;

      // ON NE NOTE LA CADENCE QUE SI L'INTERSTITIEL A REELLEMENT ETE MONTRE.
      final montre = await _ref.read(interstitialAdServiceProvider).montrer();
      if (!montre) return false;
      _ref
          .read(dernierInterstitielProvider.notifier)
          .montreA(horloge.utilisation);
      return true;
    } on Object {
      // UNE PUBLICITE NE CASSE PAS UNE NAVIGATION. Le format le plus intrusif
      // du catalogue est aussi celui dont l'echec doit etre le plus discret.
      return false;
    }
  }
}

/// Le porteur du geste d'interstitiel.
final interstitielProvider = Provider<Interstitiel>(Interstitiel.new);
