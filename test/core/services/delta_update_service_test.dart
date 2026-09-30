import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart' hide TrailManifest;
import 'package:moteur_gr/core/data/daos/trail_manifests_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_meta_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_itineraries_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_stages_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_accommodations_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/delta_update_service.dart';
import 'package:moteur_gr/core/services/manifest_service.dart';
import 'package:moteur_gr/core/models/niveau_de_telechargement.dart';

import '../../fixtures/horodatage_de_serveur.dart';

/// LA REVISION N DEVIENT L INSTANT « REFERENCE + N JOURS » (tache 610).
HorodatageServeur ins(int n) => aJPlus(n);

class FakeConnectivityMonitor extends ConnectivityMonitor {
  ConnectivityStatus _status = ConnectivityStatusValues.online;
  void setStatus(ConnectivityStatus s) => _status = s;
  @override
  Future<ConnectivityStatus> checkStatus() async => _status;
}

void main() {
  late AppDatabase db;
  late TrailManifestsDao dao;
  late DeltaUpdateService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TrailManifestsDao(db);
    final conn = FakeConnectivityMonitor();
    svc = DeltaUpdateService(
      db: db,
      manifestService: ManifestService(dao: dao, connectivityMonitor: conn),
      trailManifestsDao: dao,
      trailMetaDao: TrailMetaDao(db),
      trailItinerariesDao: TrailItinerariesDao(db),
      trailStagesDao: TrailStagesDao(db),
      trailAccommodationsDao: TrailAccommodationsDao(db),
      trailPoisDao: TrailPoisDao(db),
      trailGpxTracksDao: TrailGpxTracksDao(db),
      trailGpxPointsDao: TrailGpxPointsDao(db),
    );
  });
  tearDown(() async {
    await db.close();
  });

  TrailManifest mk({int v = 3}) => TrailManifest(
    schemaVersion: 1,
    trails: [
      TrailManifestEntry(
        trailId: 'sentier-volcans',
        dataVersion: ins(v),
        hash: 'h',
        filePath: 'p',
        fileSize: 524288,
        status: 'active',
        lastUpdated: '2026-05-26T12:00:00Z',
      ),
    ],
  );

  group('checkForUpdates', () {
    test('null si absent', () async {
      expect(
        await svc.checkForUpdates(
          'sentier-volcans',
          remoteManifest: const TrailManifest(schemaVersion: 1, trails: []),
        ),
        isNull,
      );
    });
    test('null si a jour', () async {
      await dao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('sentier-volcans'),
          dataVersion: Value(ins(3)),
          hash: const Value('h'),
          filePath: const Value('p'),
          fileSize: const Value(100),
          status: const Value('active'),
          lastUpdated: const Value('2026-01-01'),
          localVersion: Value(ins(3)),
        ),
      );
      expect(
        await svc.checkForUpdates('sentier-volcans', remoteManifest: mk(v: 3)),
        isNull,
      );
    });
    test('DeltaUpdate si MAJ dispo', () async {
      await dao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('sentier-volcans'),
          dataVersion: Value(ins(1)),
          hash: const Value('h'),
          filePath: const Value('p'),
          fileSize: const Value(100),
          status: const Value('active'),
          lastUpdated: const Value('2026-01-01'),
          localVersion: Value(ins(1)),
        ),
      );
      final r = await svc.checkForUpdates(
        'sentier-volcans',
        remoteManifest: mk(v: 3),
      );
      expect(r, isNotNull);
      expect(r!.fromVersion, ins(1));
      expect(r.toVersion, ins(3));
    });
    test('DeltaUpdate si jamais telecharge', () async {
      final r = await svc.checkForUpdates(
        'sentier-volcans',
        remoteManifest: mk(v: 2),
      );
      expect(r, isNotNull);
      expect(r!.fromVersion, HorodatageServeur.origine);
    });
  });

  group('appliquerRevisions', () {
    // LA LIGNE DE LISTE LOCALE EST POSEE, ET CE N EST PAS UN CONFORT DE TEST.
    // Depuis la tache 610, `inscrireRevision` LEVE quand l `UPDATE` ne touche
    // aucune ligne (#X10) : un repere qu on croit pose et qui ne l est pas est un
    // faux succes, et le mot de Christophe est « le dernier timestamp de MAJ
    // COMPLET ». Dans la vraie chaine cette ligne existe toujours — la lecture du
    // catalogue l ecrit — donc l ajouter ici rapproche le test de la realite au
    // lieu de l en eloigner. Le cas « pas de ligne » a desormais son propre test
    // (test/comportement/horloge_du_telephone_610_test.dart).
    setUp(() async {
      await dao.insertOrReplace(
        TrailManifestsCompanion(
          trailId: const Value('sentier-volcans'),
          dataVersion: Value(ins(1)),
          hash: const Value('h'),
          filePath: const Value('p'),
          fileSize: const Value(100),
          status: const Value('active'),
          lastUpdated: const Value('2026-01-01'),
        ),
      );
    });

    test('applique stages', () async {
      await svc.appliquerRevisions(
        'sentier-volcans',
        revisionLocale: HorodatageServeur.origine,
        niveau: NiveauDeTelechargement.realiser,
        revisionCible: ins(1),
        {
          'stages': [
            {
              'id': 's1',
              'itinerary_id': 'i1',
              'stage_number': 1,
              'name_fr': 'Cal',
              'name_en': 'C',
              'name_de': 'C',
              'name_it': 'C',
              'name_es': 'C',
              'start_lat': 45.5,
              'start_lng': 2.9,
              'end_lat': 45.4,
              'end_lng': 3.0,
              'distance_km': 12.0,
              'elevation_gain': 1500,
              'elevation_loss': 200,
              'duration_minutes': 420,
              'difficulty': 'difficile',
            },
          ],
        },
      );
      final stages = await TrailStagesDao(db).getByItineraryId('i1');
      expect(stages.length, 1);
      expect(stages.first.nameFr, 'Cal');
    });
    // CE TEST S APPELAIT « respecte changedTables » ET IL BORNAIT LA POSE PAR
    // `famillesLimitees: ['stages']` (tache 616). Le parametre a disparu : le
    // NIVEAU est desormais la seule borne, et il n a que trois valeurs emboitees
    // au lieu d une liste libre qui autorisait n importe quelle combinaison — y
    // compris des points de trace sans leur trace. Le sujet du test ne change
    // pas — « la pose n ecrit que ce que la borne autorise » — il est simplement
    // exprime avec la borne reelle, et sur la frontiere qui compte : le
    // volumineux.
    test(
      'le niveau borne la pose : PREPARER n ecrit pas le volumineux',
      () async {
        final bilan = await svc.appliquerRevisions(
          'sentier-volcans',
          revisionLocale: HorodatageServeur.origine,
          niveau: NiveauDeTelechargement.preparer,
          revisionCible: ins(1),
          {
            'stages': [
              {
                'id': 's1',
                'itinerary_id': 'i1',
                'stage_number': 1,
                'name_fr': 'A',
                'name_en': 'A',
                'name_de': 'A',
                'name_it': 'A',
                'name_es': 'A',
                'start_lat': 45.5,
                'start_lng': 2.9,
                'end_lat': 45.6,
                'end_lng': 3.0,
                'distance_km': 10.0,
                'elevation_gain': 500,
                'elevation_loss': 200,
                'duration_minutes': 300,
                'difficulty': 'moyen',
              },
            ],
            'pois': [
              {
                'id': 'p1',
                'stage_id': 's1',
                'name_fr': 'S',
                'name_en': 'S',
                'name_de': 'Q',
                'name_it': 'S',
                'name_es': 'F',
                'type': 'water',
                'lat': 45.55,
                'lng': 2.95,
              },
            ],
            'gpx_tracks': [
              {'id': 't1', 'itinerary_id': 'i1', 'name': 'trace'},
            ],
            'gpx_points': [
              for (var i = 0; i < 5; i++)
                {
                  'track_id': 't1',
                  'lat': 45.5,
                  'lng': 2.9,
                  'elevation': 1200.0,
                  'sequence_index': i,
                },
            ],
          },
        );

        // CE QUI EST ECRIT : de quoi calculer la faisabilite et remplir le sac.
        expect((await TrailStagesDao(db).getByItineraryId('i1')).length, 1);
        expect(await TrailPoisDao(db).getByStageId('s1'), hasLength(1));

        // CE QUI N EST PAS ECRIT, ET C EST LA DEMANDE DE CHRISTOPHE DU 28/09 11:27.
        // Les cinq points de trace etaient DANS les donnees posees : ils sont
        // refuses par le niveau, pas absents de la source.
        expect(await TrailGpxTracksDao(db).getAll(), isEmpty);
        expect(await TrailGpxPointsDao(db).getAll(), isEmpty);

        // ET LE BILAN LE COMPTE, au lieu de le laisser deviner.
        expect(bilan.ecrits, 2, reason: '1 etape + 1 point d interet');
        expect(bilan.famillesTouchees, ['stages', 'pois']);
        expect(bilan.niveauAtteint, NiveauDeTelechargement.preparer);
      },
    );
  });
}
