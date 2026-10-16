// LE CHAPITRE EST L UNITE DE VENTE (tache 841).
//
// QUATRE REGLES DE CHRISTOPHE, ET CE FICHIER NE SERT QU A LES TENIR.
//
//  1. 15/10 17:45, verbatim : « on achete le sentier seulement si il n y a pas
//     de chapitres. Sinon par exemple pour le GR20 on peut acheter chapitre 1,
//     chapitre 2, chapitre 1 and 2 ». Donc : le GR20 entier n est plus un
//     produit, et ses deux moities en sont deux.
//
//  2. 15/10 17:58, verbatim : « vizzavona pardon, c'est la que ca se decoupe et
//     seulement la ». Donc : neuf etapes au nord, sept au sud.
//
//  3. 16/10 10:09, verbatim : « OUI IL REPAYE ! ». Donc : refaire un chapitre
//     plus tard est un AUTRE achat, au prix plein.
//
//  4. 27/09, decision #100698 : la propriete d un sentier achete n a aucune
//     echeance. Donc : le CONTENU n est JAMAIS reverrouille, meme quand un
//     nouveau periple se paie. Les regles 3 et 4 ne se contredisent pas — elles
//     portent sur deux objets, le periple et le contenu.
//
// ET LA CINQUIEME, QUI VIENT DU LOT 839 ET QU IL FALLAIT VERIFIER : « IL N Y A
// PAS DE PUB DU TOUT EN MODE TREKK VU QU ON A PAYE » (13/10). La loi etait
// posee sur le SENTIER soldé ; avec des chapitres, le cas ordinaire devient
// « un chapitre paye, l autre pas ». Ce fichier mesure que la loi porte bien
// sur le chapitre ACHETE, et qu elle ne deborde ni sur l autre chapitre ni sur
// le sentier mere.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_nord_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_sud_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nord = gr20NordTrailConfig;
const _sud = gr20SudTrailConfig;

class _EnLigne extends ConnectivityMonitor {
  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore cagnotte;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    db = AppDatabase(NativeDatabase.memory());
    cagnotte = WalletStore(
      db: db,
      prefs: await SharedPreferences.getInstance(),
    );
    addTearDown(cagnotte.dispose);
  });

  tearDown(() async => db.close());

  Future<MonetizationService> service({int etapes = 0}) async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: cagnotte,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final monetisation = MonetizationService(
      walletStore: cagnotte,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _EnLigne(),
      prefs: prefs,
    );
    await monetisation.load();
    if (etapes > 0) await cagnotte.credit(etapes);
    return monetisation;
  }

  group('CE QUI EST ACHETABLE, ET A QUEL PRIX EN ETAPES', () {
    test(
      'les deux chapitres sont au catalogue, le sentier entier n y est plus',
      () {
        // LA REGLE DE CHRISTOPHE DU 15/10, LUE DANS LE CATALOGUE.
        expect(TrailCatalog.ids, contains('gr20-nord'));
        expect(TrailCatalog.ids, contains('gr20-sud'));
        expect(
          TrailCatalog.ids,
          isNot(contains('gr20')),
          reason:
              'un sentier qui a des chapitres n est plus un produit : ce sont '
              'ses chapitres qui se vendent',
        );
        // MAIS IL EXISTE TOUJOURS, et c est la difference avec un sentier
        // fictif : sa numerotation de reference ne doit jamais bouger (CH-10).
        expect(TrailCatalog.byId('gr20'), isNotNull);
        expect(TrailCatalog.contains('gr20'), isTrue);
        expect(TrailCatalog.sentiersMeres.map((c) => c.id), ['gr20']);
        expect(TrailCatalog.chapitresDe('gr20').map((c) => c.id), [
          'gr20-nord',
          'gr20-sud',
        ]);
        // ET L APPLICATION DEMARRE TOUJOURS AU MEME ENDROIT.
        expect(TrailCatalog.defaultTrail.id, 'mare-a-mare-centre');
      },
    );

    test(
      'LE PRIX D UN CHAPITRE EST SON NOMBRE D ETAPES : neuf et sept',
      () async {
        final monetisation = await service();
        expect(monetisation.stagesOfTrail('gr20-nord'), 9);
        expect(monetisation.stagesOfTrail('gr20-sud'), 7);
        // AUCUN MODELE DE VENTE NOUVEAU : le prix se deduit des etapes, comme
        // pour tout sentier (`priceStages` nul).
        expect(_nord.priceInStages, _nord.totalStages);
        expect(_sud.priceInStages, _sud.totalStages);
        expect(_nord.isFreeTrail, isFalse);
        expect(_sud.isFreeTrail, isFalse);
        // LES DEUX CHAPITRES COUTENT EXACTEMENT LE SENTIER ENTIER.
        expect(
          _nord.totalStages + _sud.totalStages,
          gr20TrailConfig.totalStages,
          reason:
              'decouper ne doit ni majorer ni brader : neuf plus sept font les '
              'seize etapes du sentier entier',
        );
      },
    );

    test('un chapitre s achete seul, et il se paie sur la cagnotte', () async {
      final monetisation = await service(etapes: 9);
      final issue = await monetisation.buyTrail('gr20-nord');
      expect(issue.status, PurchaseStatusResult.owned);
      expect(issue.stepsFromWallet, 9);
      expect(cagnotte.balanceSteps, 0);
      expect(await monetisation.ownsTrail('gr20-nord'), isTrue);
      // ET ACHETER LE NORD NE DONNE PAS LE SUD.
      expect(await monetisation.ownsTrail('gr20-sud'), isFalse);
    });

    test(
      'LES DEUX D UN COUP : le prix est la SOMME, et aucun lot n est construit',
      () async {
        final monetisation = await service(etapes: 16);
        final devis = await monetisation.devisDesChapitres([
          'gr20-nord',
          'gr20-sud',
        ]);
        // LE PRIX EST LA SOMME DES ETAPES, ET RIEN D AUTRE.
        expect(devis.totalStages, 16);
        expect(devis.stepsNeeded, 16);
        expect(devis.stepsFromWallet, 16);
        expect(devis.complementSteps, 0);
        // AUCUN PACK N EST ENGAGE : la cagnotte couvre, donc rien ne part au
        // magasin. C est tout l interet du prix en etapes.
        expect(devis.complementPack, isNull);
        expect(devis.couvertParLaCagnotte, isTrue);
        expect(devis.devis.map((d) => d.trailId), ['gr20-nord', 'gr20-sud']);

        final issues = await monetisation.acheterLesChapitres([
          'gr20-nord',
          'gr20-sud',
        ]);
        expect(issues.map((i) => i.status), [
          PurchaseStatusResult.owned,
          PurchaseStatusResult.owned,
        ]);
        expect(cagnotte.balanceSteps, 0);
        expect(await monetisation.ownsTrail('gr20-nord'), isTrue);
        expect(await monetisation.ownsTrail('gr20-sud'), isTrue);
      },
    );

    test(
      'demander deux fois le meme chapitre ne le fait pas payer deux fois',
      () async {
        final monetisation = await service(etapes: 16);
        final devis = await monetisation.devisDesChapitres([
          'gr20-nord',
          'gr20-nord',
        ]);
        expect(devis.devis.length, 1);
        expect(devis.stepsNeeded, 9);
      },
    );

    test('LE TOUT OU RIEN : la cagnotte ne couvre pas le lot, donc RIEN '
        'n est debite', () async {
      // Neuf etapes en cagnotte, un lot qui en coute seize.
      final monetisation = await service(etapes: 9);
      final devis = await monetisation.devisDesChapitres([
        'gr20-nord',
        'gr20-sud',
      ]);
      expect(devis.stepsNeeded, 16);
      expect(devis.stepsFromWallet, 9);
      expect(devis.complementSteps, 7);
      expect(devis.complementPack, isNotNull);
      expect(devis.couvertParLaCagnotte, isFalse);

      final issues = await monetisation.acheterLesChapitres([
        'gr20-nord',
        'gr20-sud',
      ]);
      // LE DEFAUT QUE CE CAS EMPECHE : debiter le nord puis echouer sur le
      // sud, laissant le randonneur a moitie servi sans l avoir choisi.
      expect(
        issues.every(
          (i) => i.status == PurchaseStatusResult.offlineComplementRequired,
        ),
        isTrue,
      );
      expect(cagnotte.balanceSteps, 9, reason: 'la cagnotte n a pas bouge');
      expect(await monetisation.ownsTrail('gr20-nord'), isFalse);
      expect(await monetisation.ownsTrail('gr20-sud'), isFalse);
    });
  });

  group('UN SENTIER A CHAPITRES NE SE VEND PLUS EN BLOC', () {
    test(
      'l achat du sentier mere est REFUSE, et il est refuse NOMMEMENT',
      () async {
        final monetisation = await service(etapes: 50);
        expect(monetisation.aDesChapitres('gr20'), isTrue);
        expect(monetisation.aDesChapitres('gr20-nord'), isFalse);
        expect(monetisation.aDesChapitres('mare-a-mare-centre'), isFalse);

        final issue = await monetisation.buyTrail('gr20');
        expect(issue.status, PurchaseStatusResult.sentierAChapitres);
        // RIEN DEBITE, AUCUN DROIT POSE.
        expect(cagnotte.balanceSteps, 50);
        expect(await monetisation.ownsTrail('gr20'), isFalse);
        // ET LE REFUS N EST PAS « PRIX INTROUVABLE » : le sentier mere a un
        // prix parfaitement connu, il n est simplement pas a vendre.
        expect(monetisation.stagesOfTrail('gr20'), 16);
        expect(issue.status, isNot(PurchaseStatusResult.unknownPrice));
      },
    );

    test(
      'le refus tient MEME sur un droit acquis d avant les chapitres',
      () async {
        // Le cas reel : un randonneur avait achete le GR20 entier avant la
        // tache 841. Son droit reste (la propriete n a pas d echeance) mais le
        // produit n existe plus — ni rachat, ni nouveau periple.
        final monetisation = await service(etapes: 50);
        await db.trekEntitlementsDao.upsert(
          TrekEntitlementsCompanion.insert(
            trailId: 'gr20',
            owned: const Value(true),
            acquiredStages: const Value(16),
            totalStages: const Value(16),
            updatedAt: DateTime.utc(2026, 10, 1),
          ),
        );
        expect(await monetisation.ownsTrail('gr20'), isTrue);

        expect(
          (await monetisation.buyTrail('gr20')).status,
          PurchaseStatusResult.sentierAChapitres,
        );
        expect(
          (await monetisation.ouvrirUnNouveauPeriple('gr20')).status,
          PurchaseStatusResult.sentierAChapitres,
        );
        // SON DROIT N EST PAS TOUCHE : rien n est reverrouille.
        expect(await monetisation.ownsTrail('gr20'), isTrue);
        expect(cagnotte.balanceSteps, 50);
      },
    );

    test('un sentier SANS chapitre se vend toujours entier', () async {
      // L autre moitie de la regle, et elle compte autant : « on achete le
      // sentier seulement si il n y a pas de chapitres ».
      final monetisation = await service(etapes: 7);
      final issue = await monetisation.buyTrail('mare-a-mare-centre');
      expect(issue.status, PurchaseStatusResult.owned);
      expect(issue.stepsFromWallet, 7);
    });
  });

  group('REFAIRE UN CHAPITRE : UN NOUVEAU PERIPLE, ET UN NOUVEL ACHAT', () {
    test(
      'UN ACHAT EGALE UN PERIPLE : le premier achat ouvre le periple numero un',
      () async {
        final monetisation = await service(etapes: 9);
        final issue = await monetisation.buyTrail('gr20-nord');
        expect(issue.peripleNumero, 1);
        expect(await monetisation.periplesAchetes('gr20-nord'), 1);
      },
    );

    test('« OUI IL REPAYE » : le second periple coute le PRIX PLEIN', () async {
      final monetisation = await service(etapes: 18);
      await monetisation.buyTrail('gr20-nord');
      expect(cagnotte.balanceSteps, 9);

      final second = await monetisation.ouvrirUnNouveauPeriple('gr20-nord');
      expect(second.status, PurchaseStatusResult.owned);
      expect(second.peripleNumero, 2);
      // NEUF ETAPES DE PLUS, SANS AUCUNE REMISE DE FIDELITE. Si le devis
      // escomptait les etapes deja acquises, le besoin tomberait a zero et le
      // second periple serait GRATUIT — l option que Christophe a ecartee.
      expect(second.stepsFromWallet, 9);
      expect(cagnotte.balanceSteps, 0);
      expect(await monetisation.periplesAchetes('gr20-nord'), 2);
    });

    test(
      'LE CONTENU N EST JAMAIS REVERROUILLE, ni avant ni apres le second achat',
      () async {
        final monetisation = await service(etapes: 9);
        await monetisation.buyTrail('gr20-nord');
        expect(await monetisation.ownsTrail('gr20-nord'), isTrue);

        // Cagnotte vide : le second periple ne peut pas se payer.
        expect(cagnotte.balanceSteps, 0);
        final refus = await monetisation.ouvrirUnNouveauPeriple('gr20-nord');
        expect(refus.status, PurchaseStatusResult.offlineComplementRequired);
        expect(refus.complementSteps, 9);
        // ET C EST LE POINT : un periple refuse ne retire RIEN. Le contenu
        // reste acquis, le periple precedent reste le dernier.
        expect(await monetisation.ownsTrail('gr20-nord'), isTrue);
        expect(await monetisation.canRealizeTrail('gr20-nord'), isTrue);
        expect(await monetisation.periplesAchetes('gr20-nord'), 1);
      },
    );

    test(
      'LE CARNET DE LA MARCHE PRECEDENTE RESTE INTACT : l achat n y ecrit rien',
      () async {
        final monetisation = await service(etapes: 18);
        await monetisation.buyTrail('gr20-nord');

        // Le carnet de la premiere marche.
        await db.journalDao.insertEntry(
          JournalEntriesCompanion.insert(
            trailId: 'gr20-nord',
            stageNumber: 3,
            content: const Value('Premiere marche : orage au Monte Cinto.'),
            createdAt: DateTime.utc(2026, 7, 14),
          ),
        );
        final avant = await db.journalDao.getByTrailId('gr20-nord');
        expect(avant.length, 1);

        // Le second achat.
        final second = await monetisation.ouvrirUnNouveauPeriple('gr20-nord');
        expect(second.peripleNumero, 2);

        // LE CARNET N A PAS BOUGE D UNE LIGNE. L achat d un periple n ecrit
        // QUE la ligne de droits : ni journal, ni sac, ni nuitees, ni session.
        final apres = await db.journalDao.getByTrailId('gr20-nord');
        expect(apres.length, 1);
        expect(apres.first.content, avant.first.content);
        expect(apres.first.stageNumber, 3);
      },
    );

    test('le double appui sur Acheter NE paie PAS un second periple', () async {
      // LE FILET, ET IL EST IMPORTANT : repayer est un geste EXPLICITE, pas
      // la consequence d un second appui. Le lot 796 a mesure ce que coute
      // un double appui sur un bouton de preparation ; sur un bouton
      // d achat, ce serait neuf etapes.
      final monetisation = await service(etapes: 18);
      await monetisation.buyTrail('gr20-nord');
      final deuxieme = await monetisation.buyTrail('gr20-nord');
      expect(deuxieme.status, PurchaseStatusResult.alreadyOwned);
      expect(deuxieme.peripleNumero, 1);
      expect(cagnotte.balanceSteps, 9, reason: 'rien de plus debite');
      expect(await monetisation.periplesAchetes('gr20-nord'), 1);
    });

    test('un chapitre JAMAIS achete n ouvre pas un second periple : c est '
        'un premier achat', () async {
      final monetisation = await service(etapes: 7);
      final issue = await monetisation.ouvrirUnNouveauPeriple('gr20-sud');
      expect(issue.status, PurchaseStatusResult.owned);
      expect(issue.peripleNumero, 1);
      expect(issue.stepsFromWallet, 7);
    });
  });

  group('ZERO PUBLICITE SUR LE CHAPITRE ACHETE (loi du 13/10, lot 839)', () {
    test('acheter UN chapitre eteint la publicite SUR CE CHAPITRE, et sur '
        'lui seul', () async {
      final monetisation = await service(etapes: 9);
      // Avant l achat : les deux chapitres portent la publicite.
      expect(await monetisation.isNoAdsActive('gr20-nord'), isFalse);
      expect(await monetisation.isNoAdsActive('gr20-sud'), isFalse);

      await monetisation.buyTrail('gr20-nord');

      // LE POINT QUE LE CHAPITRE RENDAIT URGENT (design #101920, 4.6) : la
      // loi « zero pub quand c est paye » portait sur le sentier SOLDE. Avec
      // des chapitres, « un paye, l autre pas » devient le cas ORDINAIRE.
      // Elle porte bien sur le chapitre ACHETE.
      expect(await monetisation.isNoAdsActive('gr20-nord'), isTrue);
      expect(
        await monetisation.isNoAdsActive('gr20-sud'),
        isFalse,
        reason:
            'le chapitre non achete n a rien paye : il reste au niveau '
            'gratuit du modele eco',
      );
      // ET ELLE NE DEBORDE PAS SUR LE SENTIER MERE, qui n est pas un produit.
      expect(await monetisation.isNoAdsActive('gr20'), isFalse);
      // LE NIVEAU D ACCES SUIT LE MEME DECOUPAGE.
      expect(await monetisation.accessFor('gr20-nord'), TrailAccess.owned);
      expect(await monetisation.accessFor('gr20-sud'), TrailAccess.free);
      expect(await monetisation.canRealizeTrail('gr20-nord'), isTrue);
      expect(await monetisation.canRealizeTrail('gr20-sud'), isFalse);
    });

    test(
      'le sans-pub d un chapitre SURVIT a l ouverture d un nouveau periple',
      () async {
        final monetisation = await service(etapes: 18);
        await monetisation.buyTrail('gr20-nord');
        expect(await monetisation.isNoAdsActive('gr20-nord'), isTrue);
        await monetisation.ouvrirUnNouveauPeriple('gr20-nord');
        // IL A PAYE DEUX FOIS : il serait absurde qu une seconde marche
        // ramene la publicite.
        expect(await monetisation.isNoAdsActive('gr20-nord'), isTrue);
      },
    );

    test(
      'acheter les DEUX chapitres eteint la publicite sur les deux',
      () async {
        final monetisation = await service(etapes: 16);
        await monetisation.acheterLesChapitres(['gr20-nord', 'gr20-sud']);
        expect(await monetisation.isNoAdsActive('gr20-nord'), isTrue);
        expect(await monetisation.isNoAdsActive('gr20-sud'), isTrue);
      },
    );
  });
}
