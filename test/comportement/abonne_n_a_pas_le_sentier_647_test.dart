// L ABONNEMENT NE DONNE AUCUN DROIT SUR UN SENTIER (integration 647, regle
// #100945).
//
// LA REGLE, DE CHRISTOPHE, MOT POUR MOT (30/09 16:21 puis 16:24) :
//   « L ABONNEMENT C EST SEULEMENT POUR NE PAS VOIR LA PUB. POUR VOIR LES CARTES
//     ET FAIRE LE TREK IL FAUT ACHETER LE SENTIER. »
//   « DONC PAS BESOIN D ETRE ABONNE, JUSTE AVOIR ACHETE LE SENTIER ! abonne ne
//     change rien d autre visuellement que la pub et la cagnotte ! »
//
// CE QUE CELA VEUT DIRE, EXACTEMENT : un abonne qui n a rien achete voit la MEME
// application qu un non-abonne, a deux exceptions pres et pas une de plus — la
// publicite (retiree) et la cagnotte. Ni un bouton, ni un acces, ni un ecran, ni
// un badge ne doit changer parce qu on est abonne.
//
// POURQUOI CE FICHIER EXISTE ALORS QUE LE CODE EST DEJA JUSTE. Il l est — c est
// mesure ici, et c est la reponse. Mais trois lots du build 8 touchent justement
// a cette zone (639 pose les trois etats de la publicite, 631 fait descendre les
// droits depuis la base, 638 refait la demo), et le glissement « abonne = acces »
// est le genre de raccourci qu on ajoute sans y penser, une ligne a la fois. La
// regle etant desormais explicite, elle se verifie toute seule.
//
// LES DEUX MOITIES DE LA PREUVE :
//   1. LE COMPORTEMENT — abonnement actif, sentier payant NON achete : pas de
//      droit de realiser, et la carte hors ligne est REFUSEE, par le vrai service
//      de descente branche sur le vrai service de monetisation.
//   2. LA STRUCTURE — dans tout `lib/`, l etat d abonnement n est lu QUE par la
//      decision publicitaire et par la cagnotte. Tout nouveau lecteur ailleurs
//      fait echouer ce test, et c est le but.
library;

import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/descente_des_cartes.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/core/services/wallet_iap_service.dart';
import 'package:moteur_gr/core/services/wallet_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Reseau extends ConnectivityMonitor {
  _Reseau(this.lien);

  final TypeDeLien lien;

  @override
  Future<ConnectivityStatus> checkStatus() async => lien == TypesDeLien.aucun
      ? ConnectivityStatusValues.offline
      : ConnectivityStatusValues.online;

  @override
  Future<TypeDeLien> typeDeLien() async => lien;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late WalletStore wallet;
  late TrailManifestsDao manifestes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
    wallet = WalletStore(db: db, prefs: await SharedPreferences.getInstance());
    addTearDown(wallet.dispose);
  });

  tearDown(() async => db.close());

  /// LE VRAI SERVICE, pas un faux : c est lui qu on met en cause.
  Future<MonetizationService> monetisation() async {
    final prefs = await SharedPreferences.getInstance();
    final iap = WalletIapService(
      walletStore: wallet,
      noAdsDao: db.noAdsDao,
      testMode: true,
    );
    addTearDown(iap.stopListening);
    final service = MonetizationService(
      walletStore: wallet,
      entitlementsDao: db.trekEntitlementsDao,
      noAdsDao: db.noAdsDao,
      iapService: iap,
      connectivityMonitor: _Reseau(TypesDeLien.wifi),
      prefs: prefs,
      // AUCUN SENTIER GRATUIT, comme au catalogue depuis le lot 638.
      freeTrailIds: const {},
      stagesOf: (id) => id == 'mare-a-mare-centre' ? 7 : 0,
    );
    await service.load();
    return service;
  }

  /// Une carte hors ligne PUBLIEE pour ce sentier : sans elle, le refus viendrait
  /// de l absence de carte et ne prouverait rien sur les droits.
  Future<void> publierUneCarte() async {
    await ManifestService(
      dao: manifestes,
      connectivityMonitor: _Reseau(TypesDeLien.wifi),
    ).saveLocalManifest(
      TrailManifestEntry(
        trailId: 'mare-a-mare-centre',
        dataVersion: HorodatageServeur.annonceParLeServeur(1700000000000)!,
        hash: 'e' * 64,
        filePath: 'mare_a_mare_centre/v1.json',
        fileSize: 2048,
        status: 'active',
        lastUpdated: '2026-09-30T00:00:00Z',
        tilesPath: 'mare_a_mare_centre/tuiles_v1.mbtiles',
        tilesSize: 26955776,
        tilesHash: 'a' * 64,
      ),
    );
  }

  group('647 — l abonnement ne donne AUCUN droit sur un sentier', () {
    test(
      'abonne + sentier NON achete : le droit de realiser n est pas acquis',
      () async {
        final service = await monetisation();
        await service.onSubscriptionValidated();

        expect(
          await service.isSubscriberActive(),
          isTrue,
          reason:
              'l abonnement doit bien etre actif, sinon le test ne prouve rien',
        );
        expect(
          await service.accessFor('mare-a-mare-centre'),
          TrailAccess.subscriber,
        );
        expect(
          await service.canRealizeTrail('mare-a-mare-centre'),
          isFalse,
          reason:
              'pour faire le trek il faut ACHETER le sentier — l abonnement ne '
              'remplace pas l achat',
        );
      },
    );

    test('abonne + sentier NON achete : la carte hors ligne est REFUSEE, et le '
        'refus nomme le droit manquant', () async {
      final service = await monetisation();
      await service.onSubscriptionValidated();
      await publierUneCarte();

      final descente = DescenteDesCartes(
        cartes: MBTilesManager(),
        dao: manifestes,
        monetization: service,
        connectivityMonitor: _Reseau(TypesDeLien.wifi),
      );

      final decision = await descente.examiner(
        'mare-a-mare-centre',
        niveau: NiveauDeTelechargement.realiser,
      );

      expect(
        decision.refus,
        RefusDeDescente.droitDeRealiserManquant,
        reason:
            'la carte est publiee et le reseau est la : ce qui manque est le '
            'droit, et l abonnement ne le donne pas',
      );
    });

    test(
      'ACHETER le sentier, lui, ouvre la carte — c est la contre-epreuve',
      () async {
        final service = await monetisation();
        await publierUneCarte();
        await db.trekEntitlementsDao.upsert(
          TrekEntitlementsCompanion.insert(
            trailId: 'mare-a-mare-centre',
            owned: const Value(true),
            acquiredStages: const Value(7),
            totalStages: const Value(7),
            updatedAt: DateTime(2026, 9, 30),
          ),
        );

        expect(await service.canRealizeTrail('mare-a-mare-centre'), isTrue);

        final decision =
            await DescenteDesCartes(
              cartes: MBTilesManager(),
              dao: manifestes,
              monetization: service,
              connectivityMonitor: _Reseau(TypesDeLien.wifi),
            ).examiner(
              'mare-a-mare-centre',
              niveau: NiveauDeTelechargement.realiser,
            );

        expect(
          decision.refus,
          isNot(RefusDeDescente.droitDeRealiserManquant),
          reason: 'le sentier achete, le droit est acquis',
        );
      },
    );

    test('l abonnement ne change QUE la publicite et la cagnotte', () async {
      final service = await monetisation();

      // AVANT : non abonne, rien d achete.
      final avantAcces = await service.accessFor('mare-a-mare-centre');
      final avantRealiser = await service.canRealizeTrail('mare-a-mare-centre');
      final avantDemo = await service.isDemoMode('mare-a-mare-centre');
      final avantOutils = await service.featuresForTrail('mare-a-mare-centre');
      final avantPub = await service.isNoAdsActive('mare-a-mare-centre');

      await service.onSubscriptionValidated();

      // APRES : abonne, toujours rien d achete.
      expect(
        await service.canRealizeTrail('mare-a-mare-centre'),
        avantRealiser,
        reason: 'la realisation ne bouge pas',
      );
      expect(
        await service.isDemoMode('mare-a-mare-centre'),
        avantDemo,
        reason: 'le mur payant est le meme',
      );
      final apresOutils = await service.featuresForTrail('mare-a-mare-centre');
      expect(apresOutils.hasGpsTracking, avantOutils.hasGpsTracking);
      expect(apresOutils.hasJournal, avantOutils.hasJournal);
      expect(apresOutils.hasDiploma, avantOutils.hasDiploma);
      expect(apresOutils.hasPreparation, avantOutils.hasPreparation);

      // LES DEUX SEULES CHOSES QUI CHANGENT.
      expect(
        await service.isNoAdsActive('mare-a-mare-centre'),
        isTrue,
        reason: 'la publicite disparait — c est la premiere exception',
      );
      expect(avantPub, isFalse);
      expect(
        apresOutils.hasAds,
        isFalse,
        reason: 'et elle disparait aussi dans la liste des fonctions',
      );
      expect(
        avantAcces,
        TrailAccess.free,
        reason: 'avant l abonnement, le niveau gratuit sur un sentier payant',
      );
    });
  });

  // =========================================================================
  // LA GARDE STRUCTURELLE : PERSONNE D AUTRE NE LIT L ABONNEMENT
  // =========================================================================

  group('647 — l abonnement n est lu QUE par la pub et par la cagnotte', () {
    /// LES SEULS FICHIERS DE `lib/` AUTORISES A LIRE L ETAT D ABONNEMENT.
    ///
    /// Le service de monetisation, parce qu il le DEFINIT ; la decision
    /// publicitaire et la regie, parce que le sans-pub est la premiere exception ;
    /// le magasin de sans-pub, parce qu il en est le stockage. La cagnotte vit
    /// DANS le service de monetisation, elle n a donc pas de fichier a elle.
    ///
    /// LOT 645-06, VAGUE 2 : `monetization_service.dart` a ete scinde en
    /// `part` du meme dossier. La liste nomme donc les trois morceaux de LA
    /// MEME bibliotheque, qui est toujours le seul service autorise. Aucune
    /// attente n a bouge : c est la liste des FICHIERS qui suit le decoupage.
    const autorises = {
      'lib/core/services/monetization_service.dart',
      'lib/core/services/monetization_service_modeles.dart',
      'lib/core/services/monetization_service_service.dart',
      'lib/core/services/monetization_service_fournisseurs.dart',
      'lib/core/data/daos/no_ads_dao.dart',
      'lib/features/ads/domain/etat_publicite.dart',
      'lib/features/group/services/ad_service.dart',
    };

    test('aucun autre fichier de lib/ ne lit isSubscriberActive', () {
      final coupables = <String>[];
      final marqueur = RegExp(r'isSubscriberActive|TrailAccess\.subscriber');

      for (final entite in Directory('lib').listSync(recursive: true)) {
        if (entite is! File || !entite.path.endsWith('.dart')) continue;
        final chemin = entite.path.replaceAll(r'\', '/');
        // Les fichiers GENERES ne sont pas des decisions.
        if (chemin.endsWith('.g.dart') || chemin.endsWith('.freezed.dart')) {
          continue;
        }
        if (autorises.contains(chemin)) continue;
        if (marqueur.hasMatch(entite.readAsStringSync())) coupables.add(chemin);
      }

      expect(
        coupables,
        isEmpty,
        reason:
            'l abonnement ne change QUE la publicite et la cagnotte (regle de '
            'Christophe du 30/09). Un nouveau lecteur ici, c est un acces, un '
            'bouton ou un ecran qui se met a dependre de l abonnement — et la '
            'regle dit que rien d autre ne doit en dependre. Si l ajout est '
            'volontaire, il se discute AVANT d elargir cette liste.',
      );
    });
  });
}
