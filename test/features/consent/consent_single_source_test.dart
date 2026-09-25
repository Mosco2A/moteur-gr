// TACHE 564 (LOT M, M2) — LE CONSENTEMENT SANTE N'A QU'UN SEUL VISAGE.
//
// CE QUE LA CAMPAGNE A MESURE (verdict #100501). Sur l'ecran Confidentialite, la
// bascule « Donnees de sante » se lit FALSE alors que la morphologie vient
// d'etre accordee et enregistree depuis la fiche randonneur (age relu « 72 »
// apres redemarrage). Le tap de la campagne l'a donc ACCORDEE au lieu de la
// retirer — lecture avant/apres : false puis true. La verification « la
// revocation efface ce qui etait deja la » n'a jamais pu etre jouee.
//
// LA VERITE, ET ELLE EST RASSURANTE SUR LE STOCKAGE. Il n'y a PAS deux
// consentements : les deux ecrans passent par le meme [ConsentService], la meme
// instance (`consentServiceProvider`, un `Provider` donc un singleton de scope),
// et la meme cle SharedPreferences (`consent_healthData`). La conception est
// saine ; c'est la LECTURE qui divergeait.
//
// LA CAUSE EXACTE. L'ecran Confidentialite lit `consentStatesProvider`, un
// `FutureProvider` mis en cache. Seul [ConsentController] l'invalidait. Or la
// fiche randonneur n'appelle pas le controleur : elle appelle
// `ConsentService.grant/revoke` DIRECTEMENT (`hiker_profile_screen.dart`). Le
// disque etait donc a jour et l'ecran resservait son instantane d'avant. La
// bascule affichait « non accorde » sur une donnee accordee — et comme un
// interrupteur envoie l'INVERSE de ce qu'il affiche, le seul geste possible
// depuis cet ecran etait d'ACCORDER. La revocation etait litteralement hors
// d'atteinte, et avec elle l'effacement qu'elle declenche.
//
// LA REPARATION, ET POURQUOI PAS UNE INVALIDATION DE PLUS. On pouvait faire
// passer la fiche par le controleur : un appelant de plus, discipline, et le
// prochain ecran qui ecrira en direct re-creera le meme ecart. Le service
// DIFFUSE deja chaque decision sur son flux `changes` — et personne ne
// l'ecoutait. C'est desormais ce flux qui rafraichit l'etat affiche : d'ou que
// vienne la decision, tous les ecrans la lisent. Une source, un chemin de
// rafraichissement.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/consent/providers/consent_ui_providers.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await db.close();
  });

  ProviderContainer chauffer() {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Abonne l'ecran Confidentialite, comme un `ref.watch` le ferait : sans
  /// auditeur, un provider ne se rafraichit pas — et le test ne mesurerait
  /// alors que sa propre lecture.
  Future<void> ouvrirEcranConfidentialite(ProviderContainer container) async {
    final sub = container.listen(consentStatesProvider, (_, __) {});
    addTearDown(sub.close);
    await container.read(consentStatesProvider.future);
  }

  bool luSurEcranConfidentialite(ProviderContainer container) =>
      container
          .read(consentStatesProvider)
          .value?[ConsentPurpose.healthData]
          ?.granted ??
      false;

  group('M2 — une seule source, lue pareil des deux cotes', () {
    test('accorder depuis la FICHE se lit sur l ecran Confidentialite',
        () async {
      final container = chauffer();
      await ouvrirEcranConfidentialite(container);
      expect(luSurEcranConfidentialite(container), isFalse,
          reason: 'etat de depart : aucune decision prise');

      // Le chemin REEL de la fiche randonneur : elle ecrit sur le service,
      // directement, sans passer par le controleur de l'ecran Confidentialite.
      final service = await container.read(consentServiceReadyProvider.future);
      await service.grant(ConsentPurpose.healthData);
      await pumpEventQueue();

      expect(luSurEcranConfidentialite(container), isTrue,
          reason: 'l ecran Confidentialite affichait « non accorde » sur une '
              'donnee accordee — c est ce qui rendait la revocation impossible');
    });

    test('retirer depuis la FICHE se lit aussi sur l ecran Confidentialite',
        () async {
      final container = chauffer();
      final service = await container.read(consentServiceReadyProvider.future);
      await service.grant(ConsentPurpose.healthData);
      await ouvrirEcranConfidentialite(container);
      expect(luSurEcranConfidentialite(container), isTrue);

      await service.revoke(ConsentPurpose.healthData);
      await pumpEventQueue();

      expect(luSurEcranConfidentialite(container), isFalse);
    });

    test('accorder depuis l ecran Confidentialite se lit depuis la FICHE',
        () async {
      final container = chauffer();
      await ouvrirEcranConfidentialite(container);

      await container
          .read(consentControllerProvider)
          .set(ConsentPurpose.healthData, granted: true);
      await pumpEventQueue();

      // La fiche randonneur relit le service a chaque ouverture (`_load`).
      final service = container.read(consentServiceProvider);
      await service.initialize();
      expect(service.hasConsent(ConsentPurpose.healthData), isTrue);
      expect(luSurEcranConfidentialite(container), isTrue);
    });
  });

  group('M2 — la revocation depuis les Reglages efface, et on peut enfin le '
      'jouer', () {
    test('retirer l autorisation sante depuis les Reglages efface la morphologie',
        () async {
      final container = chauffer();
      final repo = container.read(hikerProfileRepositoryProvider);

      // Morphologie accordee et enregistree DEPUIS LA FICHE, comme la campagne.
      final service = await container.read(consentServiceReadyProvider.future);
      await service.grant(ConsentPurpose.healthData);
      await repo.saveProfile(const HikerProfile(
        age: 72,
        heightCm: 172,
        weightKg: 88,
        sex: 'male',
        countryIso: 'FR',
      ));
      await ouvrirEcranConfidentialite(container);

      // L'ecran doit maintenant montrer « accorde » — sans quoi le geste qui
      // suit accorderait au lieu de retirer (defaut mesure par la campagne).
      expect(luSurEcranConfidentialite(container), isTrue,
          reason: 'on ne peut pas retirer ce qui s affiche comme non accorde');

      // LE GESTE : la bascule est deja a vrai, on la met a faux.
      await container
          .read(consentControllerProvider)
          .set(ConsentPurpose.healthData, granted: false);
      await pumpEventQueue();

      expect(luSurEcranConfidentialite(container), isFalse);
      final reste = await repo.getProfile();
      expect(reste.age, 0, reason: 'une revocation efface ce qui etait deja la');
      expect(reste.heightCm, 0);
      expect(reste.weightKg, 0);
      expect(await repo.getWalkTestResult(), isNull);
      // Ce qui ne releve pas de l'article 9 survit (sexe declare, pays).
      expect(reste.countryIso, 'FR');
    });
  });
}
