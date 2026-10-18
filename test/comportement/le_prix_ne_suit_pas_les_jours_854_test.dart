// GARDE — TACHE 854 : LE PRIX SUIT LES SEGMENTS DU SENTIER, JAMAIS LES
// JOURNEES DU MARCHEUR.
//
// LA PAROLE QU'ELLE PROTEGE. Christophe, 18/10 09:49, verbatim : « on s'en
// tape on paye a l'etape, il pourrait y passer 3 mois si ca lui fait plaisir »
// puis « Le nombre de jour sur les sentier est indicatif. Le randonneur peux
// tuner au jour pret avec ses pause a lui, il fait ce qu'il veut. Nous on
// propose un mode facile/ moyen/ difficile et tres difficile ... mais ca ne
// change rien au prix. Il y a seulement 2 troncon » (memoire #102213).
//
// LE RISQUE EXACT, ET POURQUOI IL MERITE UNE GARDE PLUTOT QU'UNE RELECTURE.
// Le repartiteur (`RepartitionEquilibree`) rend un nombre de JOURNEES qui
// depend de ce que le marcheur demande : sept, seize, trente et une. Le
// compte-etapes, lui, se debite en ETAPES. Les deux sont des entiers, ils se
// ressemblent, et il suffirait qu'un seul appelant passe le nombre de journees
// la ou le service attend le nombre d'etapes pour que choisir dix-neuf jours
// coute plus cher que sept — et la parole ci-dessus serait fausse DANS
// l'application, sans que rien ne rougisse. C'est exactement le motif de
// l'avenant 614 (`stagesOfTrail`) : un nombre que l'appelant declare au lieu
// de le lire.
//
// CE QUE LA MESURE DE LA TACHE 854 A TROUVE, ET IL FAUT LE DIRE : LE CODE EST
// DEJA JUSTE. `TrailPurchases.buyTrail` et
// `VenteParChapitres.ouvrirUnNouveauPeriple` sont les SEULS appelants de
// `markOwned`, et tous deux lisent `_pricing.stagesOfTrail(trailId)` ; aucune
// signature de la chaine d'achat ne porte un nombre de jours. AUCUNE LIGNE DE
// PRODUCTION N'A DONC ETE TOUCHEE PAR CE LOT. Ce fichier ne repare rien : il
// FIGE ce qui est juste, pour que ca le reste.
library;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:moteur_gr/domain/repartition_equilibree.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TOUJOURS EN LIGNE, ET SANS INTERRUPTEUR POUR L'INVERSER.
///
/// Les autres faux moniteurs du depot portent un parametre `online` ; celui-ci
/// n'en a pas, parce qu'aucun test de ce fichier ne mesure le hors-ligne. Un
/// parametre que personne ne donne est du code mort que `flutter analyze`
/// signale a juste titre (`unused_element_parameter`) : le complement store
/// hors-ligne est deja garde ailleurs (`achat_et_video_614_test`), et ce
/// fichier-ci ne parle que du PRIX.
class _ToujoursEnLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;

  const idNord = 'gr20-nord';
  const idSud = 'gr20-sud';
  const idMere = 'gr20';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FeatureFlags.clearOverrides();
    db = AppDatabase(NativeDatabase.memory());
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
  });

  tearDown(() async {
    FeatureFlags.clearOverrides();
    await db.close();
  });

  // LE SERVICE EST MONTE SUR LE VRAI CATALOGUE, SANS `stagesOf` INJECTE.
  // C'est la condition pour que ce fichier garde LES VRAIS PRODUITS : avec un
  // catalogue de test, il garderait un chiffre que personne ne vend.
  Future<MonetizationService> service({int etapesEnCagnotte = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final svc = MonetizationService(
      walletStore: wallet,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _ToujoursEnLigne(),
      prefs: prefs,
    );
    await svc.load();
    if (etapesEnCagnotte > 0) await wallet.credit(etapesEnCagnotte);
    return svc;
  }

  // =========================================================================
  // 1 — LE PRIX D'UN TRONCON EST CELUI DU CATALOGUE, ET IL Y EN A DEUX
  // =========================================================================

  group('le prix des deux troncons', () {
    test('le nord coute 9 etapes, le sud 7, et la somme fait les 16 '
        'du modele du 01/09', () async {
      final svc = await service();

      expect(
        svc.stagesOfTrail(idNord),
        9,
        reason: 'le chapitre nord porte neuf etapes au catalogue',
      );
      expect(
        svc.stagesOfTrail(idSud),
        7,
        reason: 'le chapitre sud porte sept etapes au catalogue',
      );
      expect(
        svc.stagesOfTrail(idNord) + svc.stagesOfTrail(idSud),
        16,
        reason:
            'le modele de monetisation du 01/09 (#99305) dit « GR20 '
            '16 etapes egale 16 EUR ». Les deux troncons doivent donc '
            'sommer a seize : si cette somme derive, le sentier coute '
            'autre chose que ce qui a ete decide.',
      );
    });

    test('IL Y A TROIS PRODUITS SUR LE GR20 : TOUT, LE NORD, LE SUD', () async {
      final vendables = TrailCatalog.all
          .where((c) => c.id == idNord || c.id == idSud || c.id == idMere)
          .map((c) => c.id)
          .toList();

      expect(
        vendables,
        unorderedEquals(<String>[idMere, idNord, idSud]),
        reason:
            'Christophe, 18/10 11:19, verbatim : « Tu achetes TOUT le GR, ou '
            'par troncon (2) c\'est tout ce que tu as a proposer ». CE CAS '
            'EXIGEAIT DEUX PRODUITS quelques heures plus tot, sur sa phrase '
            '« Il y a seulement 2 troncon » — qui comptait les TRONCONS, pas '
            'les produits. Il en a nomme trois depuis.',
      );
    });

    test('vendre TOUT ne vend pas deux fois la meme chose', () async {
      // LE SOUPCON QUI AVAIT MOTIVE LE RETRAIT, ET LA RAISON POUR LAQUELLE IL
      // NE TIENT PAS : un troisieme produit serait un doublon « vendu une
      // seconde fois ». Il n en est pas un, parce que LE PRIX EST LE MEME des
      // deux cotes — seize etapes pour tout, neuf plus sept pour les moities.
      // Le client choisit une FORME d achat, pas un supplement.
      final svc = await service(etapesEnCagnotte: 99);
      expect(svc.stagesOfTrail(idMere), 16);
      expect(svc.stagesOfTrail(idNord) + svc.stagesOfTrail(idSud), 16);
    });

    test('le sentier mere SE VEND en bloc, a seize etapes', () async {
      final svc = await service(etapesEnCagnotte: 99);
      final issue = await svc.buyTrail(idMere);

      expect(
        issue.status,
        PurchaseStatusResult.owned,
        reason:
            'decision du 18/10 11:19 : le sentier entier est un produit. Ce '
            'cas attendait un REFUS (regle du 15/10), qui est annulee.',
      );
      expect(issue.stepsFromWallet, 16);
      expect(wallet.balanceSteps, 83, reason: '99 - 16');
    });
  });

  // =========================================================================
  // 2 — LE COEUR : LE NOMBRE DE JOURNEES NE TOUCHE PAS LE PRIX
  // =========================================================================

  group('le nombre de journees ne touche pas le prix', () {
    // LES ALLURES SONT CELLES DU REPARTITEUR, PAS UNE LISTE CHOISIE ICI. On
    // fabrique de vraies journees pour chaque allure et on verifie que le
    // devis ne bouge pas d'une etape. C'est la seule facon que ce test
    // mesure la parole de Christophe (« trois mois si ca lui fait plaisir »)
    // et non une liste de nombres que j'aurais ecrite.
    test(
      'de 5 a 31 journees, le devis du nord vaut toujours 9 etapes',
      () async {
        final svc = await service();
        final charges = List<double>.generate(31, (i) => 60.0 + i);

        final devisParAllure = <int, int>{};
        for (var jours = 5; jours <= 31; jours++) {
          final journees = RepartitionEquilibree.coupes(charges, jours);
          expect(
            journees.length,
            jours,
            reason:
                'le repartiteur doit rendre exactement le nombre de journees '
                'demande (tache 846) : sans cela, ce test ne mesurerait pas '
                'les allures qu il croit mesurer',
          );

          final devis = await svc.quoteTrail(idNord);
          devisParAllure[jours] = devis.totalStages;
        }

        expect(
          devisParAllure.values.toSet(),
          <int>{9},
          reason:
              'VINGT-SEPT ALLURES, UN SEUL PRIX. « on paye a l etape, il '
              'pourrait y passer 3 mois si ca lui fait plaisir » : si cet '
              'ensemble contenait deux valeurs, choisir plus de jours '
              'couterait plus cher et la parole serait fausse dans '
              'l application.',
        );
      },
    );

    test(
      'acheter le nord debite 9 etapes, quelle que soit l allure prevue',
      () async {
        // L'ACHAT REEL, PAS SEULEMENT LE DEVIS. Un devis juste suivi d'un
        // debit faux serait le pire des deux mondes.
        final svc = await service(etapesEnCagnotte: 9);
        final issue = await svc.buyTrail(idNord);

        expect(issue.isOwned, isTrue);
        expect(
          issue.stepsFromWallet,
          9,
          reason: 'le debit vaut le prix du catalogue, pas un nombre de jours',
        );
        expect(
          wallet.balanceSteps,
          0,
          reason: 'neuf etapes acquises, neuf etapes debitees',
        );
      },
    );

    test(
      'les deux troncons ensemble valent 16 etapes, une seule fois',
      () async {
        final svc = await service(etapesEnCagnotte: 16);
        final devis = await svc.devisDesChapitres([idNord, idSud]);

        expect(
          devis.stepsNeeded,
          16,
          reason: 'la somme des deux chapitres, et rien de plus',
        );

        final issues = await svc.acheterLesChapitres([idNord, idSud]);
        expect(issues.every((i) => i.isOwned), isTrue);
        expect(
          wallet.balanceSteps,
          0,
          reason:
              'seize etapes pour le sentier entier, quel que soit le nombre de '
              'jours que le marcheur y passera',
        );
      },
    );

    test('redemander le meme chapitre deux fois ne le fait pas payer deux '
        'fois', () async {
      final svc = await service(etapesEnCagnotte: 16);
      final devis = await svc.devisDesChapitres([idNord, idNord, idNord]);

      expect(
        devis.stepsNeeded,
        9,
        reason:
            'les doublons sont ecartes ; sans cela une liste de journees '
            'repetant un chapitre le facturerait autant de fois',
      );
    });
  });

  // =========================================================================
  // 3 — LE DROIT DE REALISER EST UN OUI/NON, PAS UN COMPTEUR DE JOURS
  // =========================================================================

  group('realiser ne se paie pas au jour', () {
    test('un troncon achete reste realisable, rien ne se redebite', () async {
      final svc = await service(etapesEnCagnotte: 9);
      await svc.buyTrail(idNord);

      expect(await svc.canRealizeTrail(idNord), isTrue);
      final soldeApresAchat = wallet.balanceSteps;

      // On interroge le droit autant de fois qu'il y a de journees a la plus
      // longue allure. Si realiser se payait au jour, le solde tomberait.
      for (var jour = 0; jour < 31; jour++) {
        expect(await svc.canRealizeTrail(idNord), isTrue);
      }

      expect(
        wallet.balanceSteps,
        soldeApresAchat,
        reason:
            'LE DROIT DE REALISER EST UN BOOLEEN PORTE PAR `owned`, pas un '
            'credit qui se consomme journee par journee. Un marcheur qui '
            'etale son GR20 sur trois mois ne doit pas voir sa cagnotte '
            'fondre : « il pourrait y passer 3 mois si ca lui fait plaisir ».',
      );
    });
  });

  // =========================================================================
  // 4 — SEIZE ETAPES EN DIX-SEPT JOURNEES : LE CAS QUE CHRISTOPHE A NOMME
  // =========================================================================
  //
  // VERBATIM, 18/10 11:03 : « Mais les etapes du GR restent les etapes du GR.
  // 16 c'et 16, si le gars fait la premiere en 2 fois et bien c'est toujours
  // 16 etape en 17 jours ».
  //
  // COUPER UNE JOURNEE A L'INTERIEUR D'UNE ETAPE EST AUTORISE — c'est meme ce
  // qu'on cherche pour le mode facile. Ce qui ne doit JAMAIS bouger, c'est le
  // COMPTE D'ETAPES et donc le PRIX. Dix-sept journees ou sept, c'est seize
  // etapes et seize euros.

  group('seize etapes en dix-sept journees', () {
    test('couper la premiere etape en deux ne fait pas dix-sept etapes', () {
      // LE COMPTE D'ETAPES EST UNE PROPRIETE DU SENTIER, PAS DU PROGRAMME.
      // On fabrique dix-sept journees a partir des trente et un segments
      // entre nuits — donc en coupant a l'interieur d'etapes — et on verifie
      // que le nombre d'ETAPES VENDUES ne s'en apercoit pas.
      final charges = List<double>.generate(31, (i) => 60.0 + i);
      final dixSept = RepartitionEquilibree.coupes(charges, 17);

      expect(
        dixSept.length,
        17,
        reason: 'dix-sept journees, obtenues en coupant dans les etapes',
      );
      expect(
        TrailCatalog.byId(idNord)!.totalStages +
            TrailCatalog.byId(idSud)!.totalStages,
        16,
        reason:
            'SEIZE ETAPES, ET ELLES NE BOUGENT PAS. Le compte d etapes vit '
            'dans la donnee du catalogue ; le nombre de journees vit dans le '
            'programme du marcheur. Les deux ne se touchent jamais.',
      );
    });

    test(
      'le droit ENREGISTRE porte le compte d ETAPES, pas de journees',
      () async {
        // C'EST LA LIGNE QUI COMPTE VRAIMENT : ce qui est ecrit en base apres
        // l'achat. Si un nombre de journees s'y glissait, la reprise et le
        // repaiement se feraient sur un mauvais compte.
        final svc = await service(etapesEnCagnotte: 16);
        await svc.acheterLesChapitres([idNord, idSud]);

        expect(
          await svc.acquiredStagesFor(idNord),
          9,
          reason: 'neuf ETAPES acquises au nord, jamais un nombre de jours',
        );
        expect(
          await svc.acquiredStagesFor(idSud),
          7,
          reason: 'sept ETAPES acquises au sud',
        );
        expect(
          await svc.acquiredStagesFor(idNord) +
              await svc.acquiredStagesFor(idSud),
          16,
          reason:
              'SEIZE ETAPES ACQUISES, quel que soit le nombre de journees que '
              'le marcheur se donnera pour les faire',
        );
      },
    );

    test('un second periple repaie SEIZE etapes, pas dix-sept', () async {
      // « OUI IL REPAYE ! » (16/10). Ce qu'il repaie est le prix du
      // chapitre en ETAPES, et il ne doit pas dependre de l'allure de la
      // premiere marche.
      final svc = await service(etapesEnCagnotte: 18);
      await svc.buyTrail(idNord);
      expect(wallet.balanceSteps, 9);

      final second = await svc.ouvrirUnNouveauPeriple(idNord);
      expect(second.isOwned, isTrue);
      expect(second.peripleNumero, 2);
      expect(
        wallet.balanceSteps,
        0,
        reason:
            'neuf etapes la premiere fois, NEUF la seconde : le prix plein du '
            'chapitre, jamais un compte de journees',
      );
    });
  });
}
