import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:moteur_gr/features/ads/data/ads_consent_service.dart';

/// Fake ConsentInformation (UMP) : simule l'etat de consentement SANS reseau.
class _FakeConsentInformation implements ConsentInformation {
  _FakeConsentInformation({
    required this.canRequest,
    this.updateFails = false,
    this.privacyRequired = false,
  });

  bool canRequest;
  final bool updateFails;
  final bool privacyRequired;
  int updateCalls = 0;

  @override
  void requestConsentInfoUpdate(
    ConsentRequestParameters params,
    OnConsentInfoUpdateSuccessListener successListener,
    OnConsentInfoUpdateFailureListener failureListener,
  ) {
    updateCalls++;
    if (updateFails) {
      failureListener(FormError(errorCode: 1, message: 'update KO'));
    } else {
      successListener();
    }
  }

  @override
  Future<bool> canRequestAds() async => canRequest;

  @override
  Future<bool> isConsentFormAvailable() async => false;

  @override
  Future<ConsentStatus> getConsentStatus() async =>
      canRequest ? ConsentStatus.obtained : ConsentStatus.required;

  @override
  Future<void> reset() async {}

  @override
  Future<PrivacyOptionsRequirementStatus>
  getPrivacyOptionsRequirementStatus() async => privacyRequired
      ? PrivacyOptionsRequirementStatus.required
      : PrivacyOptionsRequirementStatus.notRequired;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AdsConsentService — UMP/CMP + init AdMob (A6)', () {
    test(
      'consentement obtenu -> SDK initialise + canRequestAds vrai',
      () async {
        var initCalled = false;
        final svc = AdsConsentService(
          consentInformation: _FakeConsentInformation(canRequest: true),
          loadAndShowIfRequired: (cb) async => cb(null),
          initializeAds: () async {
            initCalled = true;
            return InitializationStatus(const {});
          },
          updateRequestConfiguration: (_) async {},
        );

        final canRequest = await svc.ensureConsentAndInit();

        expect(canRequest, isTrue);
        expect(initCalled, isTrue);
        expect(svc.adsInitialized, isTrue);
      },
    );

    test('consentement NON obtenu -> SDK NON initialise, pas de pub', () async {
      var initCalled = false;
      final svc = AdsConsentService(
        consentInformation: _FakeConsentInformation(canRequest: false),
        loadAndShowIfRequired: (cb) async => cb(null),
        initializeAds: () async {
          initCalled = true;
          return InitializationStatus(const {});
        },
        updateRequestConfiguration: (_) async {},
      );

      final canRequest = await svc.ensureConsentAndInit();

      expect(canRequest, isFalse);
      expect(initCalled, isFalse, reason: 'aucune pub tant que non consenti');
      expect(svc.adsInitialized, isFalse);
    });

    test(
      'echec UMP non bloquant : ne crashe pas, pas d\'init si non autorise',
      () async {
        final svc = AdsConsentService(
          consentInformation: _FakeConsentInformation(
            canRequest: false,
            updateFails: true,
          ),
          loadAndShowIfRequired: (cb) async => cb(null),
          initializeAds: () async => InitializationStatus(const {}),
          updateRequestConfiguration: (_) async {},
        );

        // Ne doit PAS lever (best-effort).
        final canRequest = await svc.ensureConsentAndInit();
        expect(canRequest, isFalse);
      },
    );

    test('isPrivacyOptionsRequired reflète l\'etat UMP', () async {
      final svc = AdsConsentService(
        consentInformation: _FakeConsentInformation(
          canRequest: true,
          privacyRequired: true,
        ),
        loadAndShowIfRequired: (cb) async => cb(null),
        initializeAds: () async => InitializationStatus(const {}),
        updateRequestConfiguration: (_) async {},
      );
      expect(await svc.isPrivacyOptionsRequired(), isTrue);
    });
  });
}
