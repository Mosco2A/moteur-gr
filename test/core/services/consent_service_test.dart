// D4A-01 — Tests du service de consentement granulaire RGPD (design #86166).
//
// VRAIS tests : SharedPreferences mocke via setMockInitialValues, service
// reellement instancie. Couvre :
//   - etat initial : aucune finalite consentie (acte positif requis)
//   - grant / revoke PAR FINALITE (independance des finalites)
//   - donnee SANTE (art 9) isolee : jamais accordee par une autre finalite
//   - horodatage des decisions
//   - versionnement : un accord sous une politique anterieure est caduc
//     (re-demande), un accord sous la version courante reste valide
//   - flux [changes] : emission a chaque decision

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/services/consent_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConsentService — D4A-01', () {
    test('etat initial : AUCUNE finalite consentie (acte positif requis)',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      // Aucune finalite n'est accordee par defaut (opt-in reel).
      for (final purpose in ConsentPurpose.values) {
        expect(service.hasConsent(purpose), isFalse,
            reason: 'Defaut = non accorde pour $purpose');
        expect(service.needsPrompt(purpose), isTrue,
            reason: 'Jamais decide => re-demande pour $purpose');
        expect(service.stateOf(purpose).decidedAt, isNull);
      }
    });

    test('grant / revoke par finalite (independance des finalites)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      // Accord d'UNE seule finalite.
      await service.grant(ConsentPurpose.locationNavigation);
      expect(service.hasConsent(ConsentPurpose.locationNavigation), isTrue);

      // Les AUTRES finalites restent non accordees (pas de groupage).
      expect(service.hasConsent(ConsentPurpose.socialSharing), isFalse);
      expect(service.hasConsent(ConsentPurpose.publicReporting), isFalse);
      expect(service.hasConsent(ConsentPurpose.healthData), isFalse);

      // Retrait de la finalite accordee.
      await service.revoke(ConsentPurpose.locationNavigation);
      expect(service.hasConsent(ConsentPurpose.locationNavigation), isFalse);
      // Un refus explicite sous la version courante n'est PAS re-demande.
      expect(service.needsPrompt(ConsentPurpose.locationNavigation), isFalse);
      expect(service.stateOf(ConsentPurpose.locationNavigation).decidedAt,
          isNotNull);
    });

    test('donnee SANTE (art 9) isolee : jamais accordee via une autre finalite',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      // healthData est marquee renforcee (art 9), les autres non.
      expect(ConsentPurpose.healthData.isReinforced, isTrue);
      expect(ConsentPurpose.locationNavigation.isReinforced, isFalse);
      expect(ConsentPurpose.socialSharing.isReinforced, isFalse);
      expect(ConsentPurpose.publicReporting.isReinforced, isFalse);

      // On accorde TOUTES les autres finalites.
      await service.grant(ConsentPurpose.locationNavigation);
      await service.grant(ConsentPurpose.socialSharing);
      await service.grant(ConsentPurpose.publicReporting);

      // La SANTE reste non accordee : consentement separe et explicite requis.
      expect(service.hasConsent(ConsentPurpose.healthData), isFalse);
      expect(service.needsPrompt(ConsentPurpose.healthData), isTrue);

      // Accord explicite et separe de la sante.
      await service.grant(ConsentPurpose.healthData);
      expect(service.hasConsent(ConsentPurpose.healthData), isTrue);

      // Retirer la sante n'affecte pas les autres finalites.
      await service.revoke(ConsentPurpose.healthData);
      expect(service.hasConsent(ConsentPurpose.healthData), isFalse);
      expect(service.hasConsent(ConsentPurpose.locationNavigation), isTrue);
    });

    test('chaque decision est horodatee et versionnee', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      final before = DateTime.now();
      await service.grant(ConsentPurpose.socialSharing);
      final after = DateTime.now();

      final state = service.stateOf(ConsentPurpose.socialSharing);
      expect(state.granted, isTrue);
      expect(state.policyVersion, ConsentService.currentPolicyVersion);
      expect(state.decidedAt, isNotNull);
      // Horodatage dans la fenetre [before, after].
      expect(
        state.decidedAt!.isBefore(before.subtract(const Duration(seconds: 1))),
        isFalse,
      );
      expect(
        state.decidedAt!.isAfter(after.add(const Duration(seconds: 1))),
        isFalse,
      );
    });

    test(
        'versionnement : un accord sous une politique anterieure est caduc '
        '(re-demande)', () async {
      // L'utilisateur a accorde sous la politique v1...
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefsV1 = await SharedPreferences.getInstance();
      final serviceV1 = ConsentService(prefs: prefsV1, policyVersion: 1);
      addTearDown(serviceV1.dispose);
      await serviceV1.grant(ConsentPurpose.locationNavigation);
      expect(serviceV1.hasConsent(ConsentPurpose.locationNavigation), isTrue);

      // ...puis la politique evolue en v2 : l'accord v1 devient caduc.
      final serviceV2 = ConsentService(prefs: prefsV1, policyVersion: 2);
      addTearDown(serviceV2.dispose);
      expect(serviceV2.hasConsent(ConsentPurpose.locationNavigation), isFalse,
          reason: 'Accord sous v1 invalide sous v2');
      expect(serviceV2.needsPrompt(ConsentPurpose.locationNavigation), isTrue,
          reason: 'La nouvelle politique exige une re-demande');

      // Re-accord sous v2 : valide a nouveau.
      await serviceV2.grant(ConsentPurpose.locationNavigation);
      expect(serviceV2.hasConsent(ConsentPurpose.locationNavigation), isTrue);
      expect(serviceV2.needsPrompt(ConsentPurpose.locationNavigation), isFalse);
    });

    test('le flux [changes] emet a chaque decision', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      final emitted = <ConsentPurpose>[];
      final sub = service.changes.listen(emitted.add);
      addTearDown(sub.cancel);

      await service.grant(ConsentPurpose.locationNavigation);
      await service.revoke(ConsentPurpose.locationNavigation);
      await service.grant(ConsentPurpose.healthData);

      // Laisse le broadcast stream delivrer les evenements.
      await Future<void>.delayed(Duration.zero);

      expect(emitted, <ConsentPurpose>[
        ConsentPurpose.locationNavigation,
        ConsentPurpose.locationNavigation,
        ConsentPurpose.healthData,
      ]);
    });

    test('allStates() retourne l\'etat de TOUTES les finalites', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final service = ConsentService(prefs: prefs);
      addTearDown(service.dispose);

      await service.grant(ConsentPurpose.socialSharing);
      final states = service.allStates();

      expect(states.keys.toSet(), ConsentPurpose.values.toSet());
      expect(states[ConsentPurpose.socialSharing]!.granted, isTrue);
      expect(states[ConsentPurpose.healthData]!.granted, isFalse);
    });

    test('stateOf leve si le service n\'est pas initialise', () async {
      // Pas de prefs injectees et pas d'initialize() => erreur explicite,
      // pas de catch silencieux.
      final service = ConsentService();
      addTearDown(service.dispose);
      expect(
        () => service.stateOf(ConsentPurpose.locationNavigation),
        throwsA(isA<StateError>()),
      );
    });
  });
}
