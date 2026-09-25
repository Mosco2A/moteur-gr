import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:moteur_gr/core/config/ad_config.dart';
import 'package:moteur_gr/features/ads/data/ads_consent_service.dart';

/// LE FORMULAIRE DE CONSENTEMENT PUBLICITAIRE GOOGLE (UMP) — tache 560, defaut
/// N3 de la campagne personas 559 (rapport #100474).
///
/// CE QUI A ETE MESURE PAR LA CAMPAGNE : le formulaire recouvre l'appli en
/// pleine session — par-dessus les Reglages, le cockpit, le Programme et la
/// carte de navigation, en moins d'une minute. Il n'est PAS dans l'arbre
/// Flutter (vue native) : aucun test Flutter ne peut le VOIR.
///
/// D'OU VIENT CE FICHIER. Puisqu'on ne peut pas le voir, on compte les fois ou
/// il est DEMANDE, et on verifie QUAND il l'est. C'est la seule preuve
/// atteignable depuis un test, et elle suffit : un formulaire qui n'est jamais
/// demande ne peut rien recouvrir.
///
/// CE QUE LE CODE ETABLIT, ET QUI N'EST DONC PAS SUPPOSE ICI :
///  - `adsReadyProvider` est un `FutureProvider` legacy, donc
///    `isAutoDispose = false` sous Riverpod 3.3.2 (verifie dans la source du
///    paquet), et il est observe par une garde d'amorce qui ne se demonte
///    jamais : la sequence UMP tourne UNE FOIS PAR PROCESSUS, il n'y a pas de
///    boucle. Les quatre apparitions de la campagne viennent de ONZE
///    lancements — un formulaire jamais repondu reste « requis » et revient au
///    lancement suivant.
///  - le retard, lui, est structurel : la sequence est bornee par un budget
///    d'amorce, et `Future.timeout` rend la main SANS annuler l'appel natif
///    (l'API UMP n'offre aucune annulation). Le formulaire s'affichait donc
///    quand il pouvait, c'est-a-dire une fois le randonneur deja au travail.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Marges LARGES a dessein : ces tests comparent un budget d'amorce a un delai
  // UMP, et une machine chargee ne doit pas faire basculer le verdict. Un
  // facteur dix separe chaque paire (20 ms contre 200 ms, 200 ms contre 2 s) :
  // il faudrait plus d'une seconde de retard d'ordonnancement pour tromper le
  // test, et le comportement mesure resterait le meme en production ou seule
  // l'echeance change (6 s).
  const budgetCourt = Duration(milliseconds: 20);
  const budgetLarge = Duration(seconds: 2);
  const umpLent = Duration(milliseconds: 200);

  AdsConsentService service({
    required bool consentFormEnabled,
    Duration bootTimeout = budgetLarge,
    Duration delaiUmp = Duration.zero,
    required List<int> formulairesDemandes,
  }) {
    return AdsConsentService(
      consentInformation: _FakeConsentInformation(delai: delaiUmp),
      loadAndShowIfRequired: (cb) async {
        formulairesDemandes.add(1);
        cb(null);
      },
      initializeAds: () async => InitializationStatus(const {}),
      updateRequestConfiguration: (_) async {},
      bootTimeout: bootTimeout,
      consentFormEnabled: consentFormEnabled,
    );
  }

  group('N3 — le formulaire de consentement pub ne recouvre plus l appli', () {
    test('LE CONSTAT DE DEPART : ce depot ne porte aucun identifiant de '
        'production', () {
      // C'est la premisse de tout le reste, et elle est verifiable : les
      // ad-units de production sont injectes au build de release par
      // `--dart-define`. Un build de test — l APK de Chris, les onze runs de la
      // campagne — n'en porte aucun, et posait pourtant une vraie question RGPD.
      expect(AdConfig.hasProductionUnits, isFalse);
    });

    test('build sans identifiants de production : AUCUN formulaire demande', () async {
      final demandes = <int>[];
      final svc = service(consentFormEnabled: false, formulairesDemandes: demandes);

      final autorise = await svc.ensureConsentAndInit();

      expect(demandes, isEmpty,
          reason: 'un build de test ne demande pas un consentement '
              'publicitaire pour une regie qui n est pas branchee');
      expect(svc.consentFormRequests, 0);
      expect(svc.consentFormDeferred, isTrue);
      // Et le reste de la chaine n'est pas casse : le consentement deja
      // enregistre (ici « obtenu ») decide toujours des pubs.
      expect(autorise, isTrue);
      expect(svc.adsInitialized, isTrue);
    });

    test('build de production : le formulaire est demande UNE SEULE FOIS, '
        'meme sur deux appels', () async {
      final demandes = <int>[];
      final svc = service(consentFormEnabled: true, formulairesDemandes: demandes);

      // Deux appels — c'est le cas d'une re-souscription au provider d'amorce.
      final premier = svc.ensureConsentAndInit();
      final second = svc.ensureConsentAndInit();
      await Future.wait([premier, second]);
      await svc.ensureConsentAndInit();

      expect(svc.consentFormRequests, 1,
          reason: 'trois appels, un seul formulaire : la sequence est memorisee');
      expect(demandes.length, 1);
      expect(svc.consentFormDeferred, isFalse);
    });

    test('UMP qui repond APRES le budget d amorce : le formulaire est REPORTE, '
        'pas affiche par-dessus l ecran en cours', () async {
      final demandes = <int>[];
      final svc = service(
        consentFormEnabled: true,
        bootTimeout: budgetCourt,
        delaiUmp: umpLent,
        formulairesDemandes: demandes,
      );

      // L'amorce rend la main sur depassement de budget (comportement voulu)...
      expect(await svc.ensureConsentAndInit(), isFalse);
      // ...et on laisse volontairement retomber l'appel natif : c'est
      // EXACTEMENT la fenetre ou le formulaire s'affichait sur les Reglages, le
      // cockpit ou la carte.
      await Future<void>.delayed(umpLent * 3);

      expect(demandes, isEmpty,
          reason: 'le formulaire tombe hors de la fenetre d amorce : il doit '
              'etre reporte au prochain demarrage, pas pose sur un ecran de '
              'travail');
      expect(svc.consentFormRequests, 0);
      expect(svc.consentFormDeferred, isTrue);
    });

    test('MEME UMP LENT, BUDGET LARGE : le formulaire est bien demande — c est '
        'la FENETRE qui decide, pas le hasard', () async {
      final demandes = <int>[];
      final svc = service(
        consentFormEnabled: true,
        bootTimeout: budgetLarge,
        delaiUmp: umpLent,
        formulairesDemandes: demandes,
      );

      expect(await svc.ensureConsentAndInit(), isTrue);
      expect(svc.consentFormRequests, 1);
      expect(svc.consentFormDeferred, isFalse);
    });
  });
}

/// Fake UMP : repond « consentement obtenu » apres [delai], sans reseau.
class _FakeConsentInformation implements ConsentInformation {
  _FakeConsentInformation({this.delai = Duration.zero});

  final Duration delai;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    if (delai == Duration.zero) {
      successListener();
    } else {
      Future<void>.delayed(delai, successListener);
    }
  }

  @override
  Future<bool> canRequestAds() async => true;

  @override
  Future<bool> isConsentFormAvailable() async => true;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

  @override
  Future<void> reset() async {}

  @override
  Future<PrivacyOptionsRequirementStatus>
      getPrivacyOptionsRequirementStatus() async =>
          PrivacyOptionsRequirementStatus.notRequired;
}
