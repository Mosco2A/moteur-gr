import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:moteur_gr/core/models/delta_update.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/map_downloader.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/trail/providers/catalog_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// TACHE 622 — LES CARTES HORS LIGNE N AVAIENT AUCUN CHEMIN DE TELECHARGEMENT.
///
/// LE CONSTAT, VERIFIE AVANT D ECRIRE UNE LIGNE DE CODE.
/// `MBTilesManager.downloadMbtiles` existait et n avait AUCUN appelant de
/// production. Un randonneur qui preparait son sentier puis montait SANS RESEAU
/// n avait donc pas ses cartes — c est-a-dire le coeur du produit : StepWays sert a
/// marcher la ou il n y a pas de reseau.
///
/// ET LE MANIFESTE N AURAIT RIEN EU A DESCENDRE DE TOUTE FACON : `TrailManifestEntry`
/// ne portait ni adresse, ni taille, ni empreinte de tuiles. Les deux moities du trou
/// sont fermees par ce lot.
///
/// CE FICHIER COMPTE, IL NE DECRIT PAS — c est la regle posee par la tache 616 et
/// elle vaut ici plus qu ailleurs : la demande de Christophe du 27/09 est un VOLUME
/// (« Attention de ne pas telecharger les donnees inutile quand on prepare »). Un
/// niveau qui descendrait des tuiles hors de son perimetre doit donc etre un test
/// ROUGE, et la preuve est le nombre de REQUETES sur le fichier de tuiles — zero
/// requete, pas « zero d apres le journal ».
///
/// LES TROIS NIVEAUX, TRANCHES PAR CHRISTOPHE :
///   REGARDER : 0 octet. Aucune carte.
///   PREPARER : le strict necessaire, et PAS les grosses tuiles.
///   REALISER : tout, cartes comprises, parce qu on part marcher.
/// Le modele lie « realiser » a « avoir paye » (MODELE_ECO §2), sauf le sentier
/// gratuit dont le prix est nul (§2 bis).
void main() {
  late Directory tempDir;
  late AppDatabase db;
  late TrailManifestsDao manifestes;
  late List<String> requetes;

  /// La carte de reference : 4 096 octets, et son empreinte REELLE.
  late Uint8List tuiles;
  late String empreinteDesTuiles;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('cartes_622_');
    PathProviderPlatform.instance = _FauxDossiers(tempDir);
    db = AppDatabase(NativeDatabase.memory());
    manifestes = TrailManifestsDao(db);
    requetes = [];
    tuiles = Uint8List.fromList(
      List<int>.generate(4096, (i) => (i * 11 + 3) % 256),
    );
    empreinteDesTuiles = sha256.convert(tuiles).toString();
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// LE SERVEUR DE TUILES — ET SON COMPTEUR DE REQUETES.
  ///
  /// Chaque appel est trace : c est ce qui permet d AFFIRMER qu un niveau qui ne
  /// porte pas les cartes n ouvre aucune connexion, au lieu de le supposer.
  http.Client serveurDeTuiles() => MockClient((requete) async {
    requetes.add(requete.url.toString());
    return http.Response.bytes(tuiles, HttpStatus.ok);
  });

  /// Pose une ligne de liste locale pour `mare-a-mare`, avec ou sans tuiles.
  Future<void> publier({
    String? tilesPath = 'mare_a_mare/tuiles_v1.mbtiles',
    int? tilesSize = 4096,
    String? tilesHash,
  }) async {
    final service = ManifestService(
      dao: manifestes,
      connectivityMonitor: _Reseau(TypesDeLien.wifi),
    );
    await service.saveLocalManifest(
      TrailManifestEntry(
        trailId: 'mare-a-mare',
        dataVersion: HorodatageServeur.annonceParLeServeur(1700000000000)!,
        hash: 'd' * 64,
        filePath: 'mare_a_mare/v1.json',
        fileSize: 2048,
        status: 'active',
        lastUpdated: '2026-09-28T00:00:00Z',
        tilesPath: tilesPath,
        tilesSize: tilesSize,
        tilesHash: tilesHash ?? empreinteDesTuiles,
      ),
    );
  }

  MBTilesManager maps() => MBTilesManager(httpClient: serveurDeTuiles());

  MapDownloader descente({
    required bool droitDeRealiser,
    TypeDeLien lien = TypesDeLien.wifi,
    MBTilesManager? avecCartes,
  }) => MapDownloader(
    maps: avecCartes ?? maps(),
    dao: manifestes,
    monetization: _Droits(droitDeRealiser),
    connectivityMonitor: _Reseau(lien),
  );

  // =========================================================================
  // 1. LES TROIS NIVEAUX : LE VOLUME EST COMPTE EN REQUETES
  // =========================================================================
  group('622 — LES TROIS NIVEAUX : ce qui descend est COMPTE', () {
    test(
      'REGARDER ne descend AUCUNE carte, et n ouvre AUCUNE connexion',
      () async {
        await publier();

        final bilan = await descente(
          droitDeRealiser: true,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.regarder);

        expect(bilan.refus, RefusDeDescente.niveauInsuffisant);
        expect(requetes, isEmpty);
        expect(bilan.map, isNull);
      },
    );

    test(
      'PREPARER ne descend AUCUNE carte — la demande de Christophe du 27/09, '
      'et elle vaut AUSSI quand le sentier est ACHETE',
      () async {
        await publier();

        // Les deux cas de preparation : sans droit, puis avec. MEME resultat.
        for (final achete in [false, true]) {
          requetes.clear();
          final bilan = await descente(
            droitDeRealiser: achete,
          ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.preparer);

          expect(
            bilan.refus,
            RefusDeDescente.niveauInsuffisant,
            reason: 'achete=$achete : preparer ne porte pas les tuiles',
          );
          expect(requetes, isEmpty, reason: 'achete=$achete : zero octet');
        }
      },
    );

    test('REALISER descend la carte, la verifie, et la pose sous son nom '
        'definitif', () async {
      await publier();
      final gestionnaire = maps();

      final bilan = await descente(
        droitDeRealiser: true,
        avecCartes: gestionnaire,
      ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

      expect(bilan.posee, isTrue);
      expect(requetes, hasLength(1));
      expect(await gestionnaire.hasMbtiles('mare-a-mare'), isTrue);
      expect(bilan.map!.octetsSurLeTelephone, 4096);
    });

    test('carriesMaps est le SEUL juge, et il ne dit oui qu a realiser', () {
      expect(NiveauDeTelechargement.regarder.carriesMaps, isFalse);
      expect(NiveauDeTelechargement.preparer.carriesMaps, isFalse);
      expect(NiveauDeTelechargement.realiser.carriesMaps, isTrue);
    });
  });

  // =========================================================================
  // 2. LE DROIT DE REALISER — ET LE SENTIER GRATUIT
  // =========================================================================
  group('622 — REALISER est lie a AVOIR PAYE, sauf prix nul', () {
    test('sans le droit de realiser, AUCUNE connexion ne s ouvre', () async {
      await publier();

      final bilan = await descente(
        droitDeRealiser: false,
      ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

      expect(bilan.refus, RefusDeDescente.droitDeRealiserManquant);
      expect(requetes, isEmpty);
    });

    test(
      'le sentier GRATUIT recoit ses cartes : son prix est nul, donc le droit '
      'de realiser est acquis — c est la meme source, pas une exception',
      () async {
        await publier();
        // `canRealizeTrail` rend vrai pour un sentier ACHETE **et** pour un sentier
        // gratuit (`accessFor.isPlayable`). La descente ne connait donc qu un seul
        // fait, et n a aucune regle propre a ajouter.
        final bilan = await descente(
          droitDeRealiser: true,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        expect(bilan.posee, isTrue);
      },
    );

    test(
      'le refus du droit est rendu AVANT toute question de reseau',
      () async {
        await publier();

        final bilan = await descente(
          droitDeRealiser: false,
          lien: TypesDeLien.mobile,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        // Pas « confirme ton forfait » sur une carte qu on n a pas le droit de
        // prendre : la question serait posee pour rien.
        expect(bilan.refus, RefusDeDescente.droitDeRealiserManquant);
      },
    );
  });

  // =========================================================================
  // 3. LE POIDS, LE FORFAIT, ET LA CONFIRMATION HORS WIFI
  // =========================================================================
  group('622 — le poids est annonce AVANT le premier octet', () {
    test(
      'hors wifi, la descente DEMANDE confirmation et ne transfere rien',
      () async {
        await publier();

        final bilan = await descente(
          droitDeRealiser: true,
          lien: TypesDeLien.mobile,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        expect(bilan.refus, RefusDeDescente.confirmationHorsWifiRequise);
        expect(requetes, isEmpty);
        // ET LE POIDS EST DEJA CONNU : c est ce que l ecran affiche pour poser la
        // question.
        expect(bilan.decision.octetsTotal, 4096);
        expect(bilan.decision.octetsAPrendre, 4096);
      },
    );

    test('hors wifi AVEC confirmation, la carte descend', () async {
      await publier();

      final bilan =
          await descente(
            droitDeRealiser: true,
            lien: TypesDeLien.mobile,
          ).descendre(
            'mare-a-mare',
            niveau: NiveauDeTelechargement.realiser,
            confirmeHorsWifi: true,
          );

      expect(bilan.posee, isTrue);
      expect(requetes, hasLength(1));
    });

    test(
      'un lien NON IDENTIFIE est traite comme payant — « hors wifi » se prend '
      'au mot',
      () async {
        await publier();

        final bilan = await descente(
          droitDeRealiser: true,
          lien: TypesDeLien.autre,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        expect(bilan.refus, RefusDeDescente.confirmationHorsWifiRequise);
        expect(requetes, isEmpty);
      },
    );

    test('la confirmation du forfait ne leve AUCUNE autre garde', () async {
      await publier();

      // Ni le niveau...
      var bilan =
          await descente(
            droitDeRealiser: true,
            lien: TypesDeLien.mobile,
          ).descendre(
            'mare-a-mare',
            niveau: NiveauDeTelechargement.preparer,
            confirmeHorsWifi: true,
          );
      expect(bilan.refus, RefusDeDescente.niveauInsuffisant);

      // ...ni le droit de realiser.
      bilan = await descente(droitDeRealiser: false, lien: TypesDeLien.mobile)
          .descendre(
            'mare-a-mare',
            niveau: NiveauDeTelechargement.realiser,
            confirmeHorsWifi: true,
          );
      expect(bilan.refus, RefusDeDescente.droitDeRealiserManquant);
      expect(requetes, isEmpty);
    });

    test(
      'LE POIDS REEL D UN SENTIER COMPLET, MESURE : 260 Mo (chiffrage 608) '
      'sont annonces comme 260,0 Mo, et pas un octet ne bouge avant le oui',
      () async {
        // 260 Mo en z10-16 pour un sentier, mesure par la tache 608.
        const deuxCentSoixanteMo = 260 * 1000 * 1000;
        await publier(tilesSize: deuxCentSoixanteMo);

        final decision = await descente(
          droitDeRealiser: true,
          lien: TypesDeLien.mobile,
        ).examiner('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        expect(decision.refus, RefusDeDescente.confirmationHorsWifiRequise);
        expect(decision.megaoctetsAPrendre, 260.0);
        expect(requetes, isEmpty, reason: 'examiner ne transporte rien');
      },
    );
  });

  // =========================================================================
  // 4. CE QUE LE MOTEUR FAIT QUAND IL N Y A RIEN A DESCENDRE
  // =========================================================================
  group('622 — les refus sont NOMMES, jamais muets', () {
    test('un sentier sans carte publiee est REFUSE avec sa cause, pas tente a '
        'l aveugle', () async {
      await publier(tilesPath: null, tilesSize: null);

      final bilan = await descente(
        droitDeRealiser: true,
      ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

      expect(bilan.refus, RefusDeDescente.aucuneCartePubliee);
      expect(requetes, isEmpty);
    });

    test('un descripteur INCOMPLET est ignore a l enregistrement : les trois '
        'champs vont ensemble', () async {
      // Une adresse sans taille : on ne pourrait pas annoncer le poids, et
      // `octetsAttendus` serait invente.
      await publier(tilesSize: null);

      final ligne = await manifestes.getByTrailId('mare-a-mare');
      expect(ligne!.tilesPath, isNull);
      expect(ligne.tilesHash, isNull);

      final bilan = await descente(
        droitDeRealiser: true,
      ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);
      expect(bilan.refus, RefusDeDescente.aucuneCartePubliee);
    });

    test(
      'un sentier inconnu de la liste locale est REFUSE, pas devine',
      () async {
        final bilan = await descente(
          droitDeRealiser: true,
        ).descendre('jamais-publie', niveau: NiveauDeTelechargement.realiser);

        expect(bilan.refus, RefusDeDescente.sentierInconnu);
        expect(requetes, isEmpty);
      },
    );

    test(
      'hors ligne, la descente est refusee sans tenter le transport',
      () async {
        await publier();

        final bilan = await descente(
          droitDeRealiser: true,
          lien: TypesDeLien.aucun,
        ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

        expect(bilan.refus, RefusDeDescente.horsLigne);
        expect(requetes, isEmpty);
      },
    );

    test('une carte deja posee ne se retelecharge pas', () async {
      await publier();
      final gestionnaire = maps();
      final service = descente(droitDeRealiser: true, avecCartes: gestionnaire);

      expect(
        (await service.descendre(
          'mare-a-mare',
          niveau: NiveauDeTelechargement.realiser,
        )).posee,
        isTrue,
      );
      expect(requetes, hasLength(1));

      final second = await service.descendre(
        'mare-a-mare',
        niveau: NiveauDeTelechargement.realiser,
      );
      expect(second.refus, RefusDeDescente.dejaLa);
      expect(requetes, hasLength(1), reason: 'aucune seconde requete');
    });

    test('une empreinte qui ne correspond pas ne pose AUCUNE carte', () async {
      await publier(tilesHash: 'f' * 64);
      final gestionnaire = maps();

      final bilan = await descente(
        droitDeRealiser: true,
        avecCartes: gestionnaire,
      ).descendre('mare-a-mare', niveau: NiveauDeTelechargement.realiser);

      expect(bilan.posee, isFalse);
      expect(bilan.echec, MapFailure.empreinteInvalide);
      expect(await gestionnaire.hasMbtiles('mare-a-mare'), isFalse);
    });
  });

  // =========================================================================
  // 5. LE GESTE COMPLET : LE CHEMIN EST REELLEMENT BRANCHE
  // =========================================================================
  group('622 — le geste « telecharger » emporte les cartes au bon niveau', () {
    ProviderContainer conteneur({
      required bool droitDeRealiser,
      required MBTilesManager gestionnaire,
      TypeDeLien lien = TypesDeLien.wifi,
    }) {
      final reseau = _Reseau(lien);
      return ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          connectivityMonitorProvider.overrideWithValue(reseau),
          mbtilesManagerProvider.overrideWithValue(gestionnaire),
          monetizationServiceProvider.overrideWithValue(
            _Droits(droitDeRealiser),
          ),
          // La liste distante est injoignable : le catalogue retombe sur le local,
          // ce qui suffit — ce groupe teste le GESTE, pas la lecture du catalogue.
          manifestServiceProvider.overrideWithValue(
            ManifestService(
              dao: manifestes,
              connectivityMonitor: reseau,
              httpClient: MockClient((_) async => http.Response('non', 404)),
            ),
          ),
          deltaUpdateServiceProvider.overrideWith((_) => _CopieQuiReussit()),
        ],
      );
    }

    test(
      'downloadTrail(realiser) pose les donnees ET la carte hors ligne',
      () async {
        await publier();
        final gestionnaire = maps();
        final c = conteneur(droitDeRealiser: true, gestionnaire: gestionnaire);
        addTearDown(c.dispose);
        await c.read(catalogStateProvider.future);

        await c
            .read(catalogStateProvider.notifier)
            .downloadTrail(
              'mare-a-mare',
              niveau: NiveauDeTelechargement.realiser,
            );

        expect(await gestionnaire.hasMbtiles('mare-a-mare'), isTrue);
        expect(requetes, hasLength(1));
        final etat = c.read(controleurDesCartesProvider('mare-a-mare'));
        expect(etat.bilan!.posee, isTrue);
        expect(etat.enCours, isFalse);
      },
    );

    test('downloadTrail(preparer) ne demande AUCUNE tuile', () async {
      await publier();
      final gestionnaire = maps();
      final c = conteneur(droitDeRealiser: true, gestionnaire: gestionnaire);
      addTearDown(c.dispose);
      await c.read(catalogStateProvider.future);

      await c
          .read(catalogStateProvider.notifier)
          .downloadTrail(
            'mare-a-mare',
            niveau: NiveauDeTelechargement.preparer,
          );

      expect(requetes, isEmpty);
      expect(await gestionnaire.hasMbtiles('mare-a-mare'), isFalse);
    });

    test('hors wifi, le geste ne fait PAS payer le randonneur par defaut : le '
        'sentier est telecharge, la carte attend son oui', () async {
      await publier();
      final gestionnaire = maps();
      final c = conteneur(
        droitDeRealiser: true,
        gestionnaire: gestionnaire,
        lien: TypesDeLien.mobile,
      );
      addTearDown(c.dispose);
      await c.read(catalogStateProvider.future);

      await c
          .read(catalogStateProvider.notifier)
          .downloadTrail(
            'mare-a-mare',
            niveau: NiveauDeTelechargement.realiser,
          );

      expect(requetes, isEmpty);
      final etat = c.read(controleurDesCartesProvider('mare-a-mare'));
      expect(etat.bilan!.refus, RefusDeDescente.confirmationHorsWifiRequise);
      // LE SENTIER RESTE TELECHARGE : l absence de carte n annule pas la copie des
      // donnees. Retirer au randonneur ce qu il a deja parce que le fond de carte
      // attend son accord serait le pire des deux mondes.
      final entree = c
          .read(catalogStateProvider)
          .value!
          .entries
          .firstWhere((e) => e.trailId == 'mare-a-mare');
      expect(entree.localStatus, TrailLocalStatusValues.downloaded);
    });

    test('le controleur fabrique un jeton NEUF a chaque depart : une descente '
        'annulee ne condamne pas la suivante', () async {
      await publier();
      final gestionnaire = maps();
      final c = conteneur(droitDeRealiser: true, gestionnaire: gestionnaire);
      addTearDown(c.dispose);

      final controleur = c.read(
        controleurDesCartesProvider('mare-a-mare').notifier,
      );
      controleur.cancel(); // aucun effet : rien ne tourne

      final bilan = await controleur.start(
        niveau: NiveauDeTelechargement.realiser,
      );
      expect(bilan.posee, isTrue);
    });
  });

  // =========================================================================
  // 6. L INVARIANTE : UN SEUL CHEMIN DE DESCENTE
  // =========================================================================
  group('622 — INVARIANTE : la descente des cartes a UN SEUL appelant', () {
    List<File> sourcesDeProduction() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList();

    test('AUCUN code de production n appelle le transport des tuiles en dehors de '
        'MapDownloader — c est la faute que la tache 606 a du corriger', () {
      // Les seules apparitions legitimes : la definition du transport lui-meme, et
      // l unique orchestrateur qui le pilote.
      const tolerees = [
        'lib/core/map/mbtiles_manager.dart',
        'lib/core/services/map_downloader.dart',
      ];

      final coupables = <String>[];
      for (final fichier in sourcesDeProduction()) {
        final chemin = fichier.path.replaceAll(r'\', '/');
        if (tolerees.any(chemin.endsWith)) continue;
        final source = fichier.readAsStringSync();
        // `.descendre(` precede d un appel au gestionnaire de cartes : on cherche
        // l usage du transport, pas le mot.
        if (source.contains('maps.descendre(') ||
            source.contains('mbtilesManager.descendre(') ||
            source.contains('Manager.descendre(')) {
          coupables.add(chemin);
        }
      }

      expect(
        coupables,
        isEmpty,
        reason:
            'Un second chemin de descente des cartes est apparu : '
            '${coupables.join(", ")}. Le lot 606 a du defaire exactement cela '
            '(un geste « telecharger » qui empruntait un second chemin ignorant '
            'tout le modele). Passe par MapDownloader.',
      );
    });

    test('la CADENCE ne descend jamais de tuiles : l ordonnanceur ne connait pas '
        'la descente des cartes', () {
      // 260 Mo arrivant tout seuls toutes les quatre heures est precisement ce que
      // l ordonnanceur se documente d interdire (tache 616). La garde est
      // structurelle : il n a aucun lien vers ce service.
      //
      // LE NOM DE FICHIER SURVEILLE EST CELUI D AUJOURD HUI (tache 665). Il
      // s appelait `descente_des_cartes.dart` jusqu au lot 645-07, qui l a
      // renomme `map_downloader.dart`. La chaine surveillee, elle, n avait pas
      // suivi : elle cherchait un nom qui n existait plus NULLE PART, donc elle
      // ne trouvait plus jamais rien et passait au vert quoi qu il arrive. Une
      // garde qui ne peut plus rougir ne garde rien — c est exactement le defaut
      // trouve au lot 645-06. Les deux lignes surveillent desormais les deux
      // portes d entree reelles : l IMPORT (le nom de fichier) et L USAGE (le
      // nom de classe).
      final ordonnanceur = File(
        'lib/core/services/ordonnanceur_de_synchronisation.dart',
      ).readAsStringSync();
      expect(ordonnanceur.contains('map_downloader'), isFalse);
      expect(ordonnanceur.contains('MapDownloader'), isFalse);

      final telechargeur = File(
        'lib/core/services/update_downloader.dart',
      ).readAsStringSync();
      expect(telechargeur.contains('MapDownloader'), isFalse);
      expect(telechargeur.contains('mbtiles'), isFalse);
    });
  });
}

/// Dossier de documents pilote, pour que les cartes vivent dans un temporaire.
class _FauxDossiers extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FauxDossiers(this.dossier);
  final Directory dossier;

  @override
  Future<String?> getApplicationDocumentsPath() async => dossier.path;
}

/// Le reseau, pilote : son TYPE de lien est ce qui decide de la confirmation.
class _Reseau extends ConnectivityMonitor {
  _Reseau(this.lien);
  final TypeDeLien lien;

  @override
  Future<TypeDeLien> typeDeLien() async => lien;

  @override
  Future<ConnectivityStatus> checkStatus() async => lien == TypesDeLien.aucun
      ? ConnectivityStatusValues.offline
      : ConnectivityStatusValues.online;
}

/// LE DROIT DE REALISER, PILOTE — et c est la SEULE chose qu on simule ici.
///
/// `canRealizeTrail` est la source unique du verrou (tache 594) : elle rend vrai
/// pour un trek achete ET pour un sentier gratuit. Les deux cas du modele passent
/// donc par ce seul booleen, ce qui est exactement le point du §2 bis — un prix nul
/// est une entree du modele, pas une exemption a coder ailleurs.
class _Droits extends Fake implements MonetizationService {
  _Droits(this.autorise);
  final bool autorise;

  @override
  Future<bool> canRealizeTrail(String trailId) async => autorise;
}

/// Une copie de donnees qui reussit, pour isoler le geste des cartes.
class _CopieQuiReussit extends Fake implements DeltaUpdateService {
  @override
  Future<ResultatSynchronisation> synchroniser(
    String trailId,
    String urlDonnees, {
    required HorodatageServeur revisionCible,
    required String? empreinteAttendue,
    required NiveauDeTelechargement niveau,
    HorodatageServeur? revisionLocaleConnue,
  }) async => ResultatSynchronisation(
    famillesTouchees: const ['trail_meta'],
    ecrits: 1,
    supprimes: 0,
    revisionAtteinte: revisionCible,
    niveauAtteint: niveau,
  );
}
