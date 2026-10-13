import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_points_dao.dart';
import 'package:moteur_gr/core/data/daos/trail_gpx_tracks_dao.dart';
import 'package:moteur_gr/features/trail/data/drift_trail_data_provider.dart';
import 'package:moteur_gr/features/trek/data/seed_data_loader.dart';

/// Config sentier pour le test du seed.
///
/// Le seed est desormais parametre par la config du sentier : l'id, le nom et
/// la racine des assets viennent de [TrailConfig]. On pointe [seedAssetsBase]
/// vers les donnees de seed embarquees ('assets/data/mare_a_mare_centre') que
/// ce test verifie. Geo neutre (Auvergne) ; seuls id/nom/assets sont
/// significatifs car ils pilotent les enregistrements POIs/track/points.
const _seedTrailConfig = TrailConfig(
  id: 'mare-a-mare-centre',
  name: 'Mare a Mare Centre',
  displayName: 'Mare a Mare Centre',
  tagline: 'Seed de test',
  totalStages: 7,
  totalDistanceKm: 0,
  totalElevationGain: 0,
  region: 'Auvergne',
  country: 'France',
  primaryColorValue: 0xFF8B4513,
  secondaryColorValue: 0xFFD2691E,
  gpxAssetPath: 'assets/data/mare_a_mare_centre/track.gpx',
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
);

/// Config identique mais AVEC le chemin des hebergements (R4) : le seed charge
/// alors les hebergements dans les tables riches lues par l'assistant Nuitees.
const _seedTrailConfigWithAccommodations = TrailConfig(
  id: 'mare-a-mare-centre',
  name: 'Mare a Mare Centre',
  displayName: 'Mare a Mare Centre',
  tagline: 'Seed de test',
  totalStages: 7,
  totalDistanceKm: 0,
  totalElevationGain: 0,
  region: 'Auvergne',
  country: 'France',
  primaryColorValue: 0xFF8B4513,
  secondaryColorValue: 0xFFD2691E,
  gpxAssetPath: 'assets/data/mare_a_mare_centre/track.gpx',
  seedAssetsBase: 'assets/data/mare_a_mare_centre',
  accommodationsAssetPath: 'assets/data/mare_a_mare_centre.json',
);

void main() {
  // Necessaire pour rootBundle.loadString (chargement des assets de seed).
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SeedDataLoader', () {
    test('seedIfNeeded charge les donnees et set le flag', () async {
      // --- Setup : DB in-memory + SharedPreferences mock ---
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());

      final loader = SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: _seedTrailConfig,
      );

      // --- Act : premier seed ---
      final result = await loader.seedIfNeeded();

      // --- Assert : seed effectue ---
      expect(result, isTrue);

      // Stages inseres (7 etapes Mare a Mare Centre)
      final stagesDao = StagesDao(db);
      final stages = await stagesDao.getByTrailId('mare-a-mare-centre');
      expect(stages.length, 7);
      expect(stages.first.name, contains('Ghisonaccia'));
      expect(stages.last.name, contains('Porticcio'));

      // POIs inseres (20 POIs)
      final poisDao = PoisDao(db);
      final pois = await poisDao.getByTrailId('mare-a-mare-centre');
      expect(pois.length, 20);

      // GPX track insere
      final tracksDao = TrailGpxTracksDao(db);
      final track = await tracksDao.getById('mare-a-mare-centre');
      expect(track, isNotNull);
      expect(track!.name, 'Mare a Mare Centre');

      // GPX points inseres : le semeur pose la trace ENTIERE (lot 606)
      final pointsDao = TrailGpxPointsDao(db);
      final points = await pointsDao.getByTrackId('mare-a-mare-centre');
      expect(points.length, greaterThan(0));
      // TACHE 761 — LA TRACE FAIT 3 590 POINTS, ET LE SEMEUR DOIT LES POSER
      // TOUS. Le plafond de 63 datait de la trace de 53 points : il mesurait un
      // croquis. Le semeur ne simplifie plus depuis le lot 606 (la
      // simplification vit au rendu, par niveau de zoom), donc l egalite
      // STRICTE avec le compte du GPX dit plus qu un plafond : si un point se
      // perd en route, ce test le nomme — c est exactement le defaut que le lot
      // 606 avait trouve, 48 points poses pour 53 lus.
      expect(points.length, 3590);

      // TACHE 613 — PLUS AUCUN DRAPEAU EN PREFERENCES. La marque du seed est la
      // PRESENCE DES ETAPES EN BASE, et rien d'autre : une preference et une base
      // ne disparaissent pas ensemble, donc un drapeau peut mentir dans les deux
      // sens (base vide apres restauration de preferences ; base pleine apres un
      // effacement de compte, qui purge les preferences mais CONSERVE les tables
      // de reference du sentier — un re-seed y dupliquerait tout).
      expect(
        prefs.getBool(SeedDataLoader.kDataSeededPrefsKey),
        isNull,
        reason: 'l ancienne cle globale n est plus posee, seulement nettoyee',
      );

      // --- Act : deuxieme appel (idempotent) ---
      final result2 = await loader.seedIfNeeded();
      expect(result2, isFalse);

      // Donnees inchangees
      final stages2 = await stagesDao.getByTrailId('mare-a-mare-centre');
      expect(stages2.length, 7);

      await db.close();
    });

    test(
      'le seed charge la duree riche par etape (parite GR20 socle donnees)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());

        final loader = SeedDataLoader(
          db: db,
          prefs: prefs,
          trailConfig: _seedTrailConfig,
        );
        await loader.seedIfNeeded();

        final stagesDao = StagesDao(db);
        final stages = await stagesDao.getByTrailId('mare-a-mare-centre');

        // Toutes les etapes Mare a Mare portent une duree (donnee du sentier).
        expect(
          stages.every((s) => s.estimatedDurationMinutes != null),
          isTrue,
          reason: 'estimatedDurationMinutes alimente depuis stages.json',
        );
        // Valeur exacte de l etape 1, Ghisonaccia — Catastaghju : 457 min.
        // TACHE 761 — 457 et non 350 : l etape ne fait plus 15,0 km estimes
        // mais 19,9 km mesures sur la trace relevee, pour 1 058 m de D+. La
        // duree reste la meme regle de marche (19,9 / 4 + 1 058 / 400 heures,
        // soit 7 h 37), appliquee a des chiffres qui, eux, sont mesures.
        final s1 = stages.firstWhere((s) => s.stageNumber == 1);
        expect(s1.estimatedDurationMinutes, 457);

        await db.close();
      },
    );

    test(
      'le seed charge les noms depart/arrivee par etape (parite GR20)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final db = AppDatabase(NativeDatabase.memory());

        final loader = SeedDataLoader(
          db: db,
          prefs: prefs,
          trailConfig: _seedTrailConfig,
        );
        await loader.seedIfNeeded();

        final stagesDao = StagesDao(db);
        final stages = await stagesDao.getByTrailId('mare-a-mare-centre');

        // Toutes les etapes portent des noms depart/arrivee (donnee du sentier).
        expect(
          stages.every(
            (s) =>
                (s.departureName?.isNotEmpty ?? false) &&
                (s.arrivalName?.isNotEmpty ?? false),
          ),
          isTrue,
          reason: 'departureName/arrivalName alimentes depuis stages.json',
        );
        // Valeurs exactes de l etape 1 (Ghisonaccia — Catastaghju).
        final s1 = stages.firstWhere((s) => s.stageNumber == 1);
        expect(s1.departureName, 'Ghisonaccia');
        expect(s1.arrivalName, 'Catastaghju');

        await db.close();
      },
    );
  });

  // --- R4 : hebergements charges et lisibles par getAccommodations ---
  // Retour Chris R4 : l'assistant Nuitees n'affichait pas les noms
  // d'hebergement. Cause : le seed « dossier » ne peuplait PAS les tables
  // riches lues par `getAccommodations`. Avec `accommodationsAssetPath`, le
  // seed charge le fichier monolithique -> les noms reels remontent.
  group('SeedDataLoader — hebergements (R4)', () {
    test('sans accommodationsAssetPath : aucun hebergement (comportement '
        'inchange)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: _seedTrailConfig,
      ).seedIfNeeded();

      final data = DriftTrailDataProvider(
        db: db,
        trailConfig: _seedTrailConfig,
      );
      final accommodations = await data.getAccommodations('mare-a-mare-centre');
      expect(
        accommodations,
        isEmpty,
        reason: 'sans chemin hebergements, la table riche reste vide',
      );
    });

    test('avec accommodationsAssetPath : getAccommodations renvoie les noms '
        'reels par etape', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await SeedDataLoader(
        db: db,
        prefs: prefs,
        trailConfig: _seedTrailConfigWithAccommodations,
      ).seedIfNeeded();

      final data = DriftTrailDataProvider(
        db: db,
        trailConfig: _seedTrailConfigWithAccommodations,
      );

      // Total : 11 hebergements reels sur les 7 etapes (seed monolithique).
      final all = await data.getAccommodations('mare-a-mare-centre');
      expect(
        all.length,
        11,
        reason: '11 hebergements reels dans mare_a_mare_centre.json',
      );
      expect(
        all.every((a) => a.nameFr.isNotEmpty),
        isTrue,
        reason: 'tous les hebergements portent un nom reel (nameFr)',
      );

      // Etape 1 : au moins un hebergement nomme (le cas du 1er retour Chris).
      final stage1 = await data.getAccommodations(
        'mare-a-mare-centre',
        stageNumber: 1,
      );
      expect(
        stage1,
        isNotEmpty,
        reason: 'l etape 1 a des hebergements (mam-ew-s1)',
      );
      expect(
        stage1.any((a) => a.nameFr.contains('Serra di Fiumorbu')),
        isTrue,
        reason: 'nom reel attendu (ex. « Gite d etape de Serra di Fiumorbu »)',
      );
    });
  });
}
