import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:moteur_gr/features/ads/data/ads_consent_service.dart';

/// NON-REGRESSION — LOT FIX-2, finding M2 (MAJEUR).
///
/// LE FINDING TEL QUE RAPPORTE : « la `TimeoutException` remonte comme ERREUR
/// ASYNCHRONE NON GEREE via Riverpod et fait ECHOUER le run S2 ».
///
/// CE QUE LA VERIFICATION A MONTRE (mesure, pas supposition) :
///  1. la `TimeoutException` EST capturee par `ensureConsentAndInit` — le pave
///     rouge du log S2 est le RENDU de cette capture (message + `error:` +
///     `stackTrace:` du logger), pas une erreur qui s'echappe ;
///  2. le run S2 a echoue sur tout autre chose : « A SemanticsHandle was active
///     at the end of the test » (harnais `integration_test/`, poignee de
///     semantique jamais liberee) ;
///  3. `Future.timeout` ne signale PAS les erreurs tardives du `Future` source :
///     il les ABANDONNE en silence. Une panne reelle d'AdMob survenant apres
///     l'echeance ne laissait donc AUCUNE trace.
///
/// CE QUI A ETE CORRIGE, ET QUE CES TESTS VERROUILLENT :
///  - le CONTRAT d'amorce : quelle que soit la date d'arrivee de l'echec (avant
///    l'echeance, apres, ou jamais), `ensureConsentAndInit` ne leve rien, ne
///    laisse RIEN fuir vers le gestionnaire de zone, et rend toujours `false`
///    (pas de pub, jamais de boot casse) ;
///  - l'init native est desormais gardee pour son propre compte, donc un echec
///    tardif est trace au lieu d'etre perdu ;
///  - le depassement de budget, comportement VOULU hors-ligne, n'est plus
///    journalise comme une erreur reseau avec pile d'appel (c'est ce pave qui a
///    ete lu comme un plantage au demarrage).
///
/// Le budget de boot est injecte court pour ne pas faire durer le test six
/// secondes ; c'est la MEME mecanique qu'en production, seule l'echeance change.
class _FakeConsentInformation implements ConsentInformation {
  const _FakeConsentInformation();

  /// Consentement resolu : l'amorce va jusqu'a l'init AdMob, la ou le finding
  /// se joue.
  static const bool canRequest = true;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    successListener();
  }

  @override
  Future<bool> canRequestAds() async => canRequest;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<ConsentStatus> getConsentStatus() async => ConsentStatus.obtained;

  @override
  Future<void> reset() async {}

  @override
  Future<PrivacyOptionsRequirementStatus>
      getPrivacyOptionsRequirementStatus() async =>
          PrivacyOptionsRequirementStatus.notRequired;
}

/// Lance [action] dans une zone gardee et rend les erreurs qui s'en echappent.
///
/// C'est l'observatoire du defaut : une erreur asynchrone non geree n'est
/// visible NULLE PART ailleurs (ni valeur de retour, ni exception levee) — elle
/// ne se manifeste que par un appel au gestionnaire de zone, exactement ce que
/// Riverpod remontait au boot.
Future<List<Object>> erreursEchappees(
  Future<void> Function() action, {
  required Duration laisserRetomber,
}) async {
  final echappees = <Object>[];
  final termine = Completer<void>();

  runZonedGuarded(
    () async {
      await action();
      if (!termine.isCompleted) termine.complete();
    },
    (error, _) => echappees.add(error),
  );

  await termine.future;
  // On laisse volontairement du temps APRES le retour de l'amorce : c'est
  // precisement la fenetre ou l'echec tardif arrivait et partait en erreur non
  // geree.
  await Future<void>.delayed(laisserRetomber);
  return echappees;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const budget = Duration(milliseconds: 40);
  const apresEcheance = Duration(milliseconds: 120);

  group('M2 — amorce pub : aucune erreur asynchrone non geree au boot', () {
    test(
      'init AdMob qui echoue APRES l echeance -> rien ne fuit vers la zone',
      () async {
        var resultat = true;

        final echappees = await erreursEchappees(
          () async {
            final svc = AdsConsentService(
              consentInformation: const _FakeConsentInformation(),
              loadAndShowIfRequired: (cb) async => cb(null),
              // Reseau lent : l'init native met plus longtemps que le budget
              // de boot, PUIS echoue. C'est le cas exact du finding.
              initializeAds: () => Future<InitializationStatus>.delayed(
                apresEcheance,
                () => throw StateError('AdMob KO (reseau lent)'),
              ),
              updateRequestConfiguration: (_) async {},
              bootTimeout: budget,
            );
            resultat = await svc.ensureConsentAndInit();
          },
          laisserRetomber: apresEcheance * 2,
        );

        expect(
          echappees,
          isEmpty,
          reason: 'l echec tardif de l amorce pub ne doit JAMAIS remonter '
              'comme erreur asynchrone non geree (finding M2)',
        );
        expect(resultat, isFalse, reason: 'pas de pub, mais pas de crash');
      },
    );

    test(
      'init AdMob qui PEND indefiniment -> l amorce rend false sans fuite',
      () async {
        var resultat = true;

        final echappees = await erreursEchappees(
          () async {
            final svc = AdsConsentService(
              consentInformation: const _FakeConsentInformation(),
              loadAndShowIfRequired: (cb) async => cb(null),
              // Hors-ligne : l'API native ne rappelle jamais.
              initializeAds: () => Completer<InitializationStatus>().future,
              updateRequestConfiguration: (_) async {},
              bootTimeout: budget,
            );
            resultat = await svc.ensureConsentAndInit();
          },
          laisserRetomber: apresEcheance,
        );

        expect(echappees, isEmpty);
        expect(resultat, isFalse);
      },
    );

    test(
      'echec AVANT l echeance -> capture aussi, et toujours false',
      () async {
        var resultat = true;

        final echappees = await erreursEchappees(
          () async {
            final svc = AdsConsentService(
              consentInformation: const _FakeConsentInformation(),
              loadAndShowIfRequired: (cb) async => cb(null),
              initializeAds: () async =>
                  throw StateError('AdMob KO (immediat)'),
              updateRequestConfiguration: (_) async {},
              bootTimeout: budget,
            );
            resultat = await svc.ensureConsentAndInit();
          },
          laisserRetomber: apresEcheance,
        );

        expect(echappees, isEmpty);
        expect(resultat, isFalse);
      },
    );

    test(
      'chemin nominal preserve : consentement obtenu -> SDK initialise',
      () async {
        var initAppele = false;
        final svc = AdsConsentService(
          consentInformation: const _FakeConsentInformation(),
          loadAndShowIfRequired: (cb) async => cb(null),
          initializeAds: () async {
            initAppele = true;
            return InitializationStatus(const {});
          },
          updateRequestConfiguration: (_) async {},
          bootTimeout: budget,
        );

        expect(await svc.ensureConsentAndInit(), isTrue);
        expect(initAppele, isTrue);
        expect(svc.adsInitialized, isTrue);
      },
    );
  });
}
