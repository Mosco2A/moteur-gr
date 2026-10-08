/// TACHE 742 — LA DEMO MARCHE, EN SIMULATION, SUR LE SENTIER DE DEMO.
///
/// ORDRE DE CHRISTOPHE DU 08/10 20:19, verbatim : « Le mode demo doit
/// fonctionner et en mode simulation pour le sentier en mode demo !!! ».
///
/// CE QUI NE MARCHAIT PAS, MESURE (recette du build 12, tache 739) : en demo la
/// barre de la carte affichait Parcouru « -- », Vit. moy. « -- », Altitude
/// « -- », rien ne bougeait apres dix minutes de randonnee lancee, aucun point
/// n'apparaissait sur la carte, le journal du jour restait vide. Le GPS de fond
/// n'est pas arme en demo et la session ne s'ecrit nulle part — c'etait VOULU
/// (tache 638, bug 16) et ca l'est toujours. Ce qui manquait : la SOURCE.
///
/// CE QUE CES GARDES TIENNENT, ET DANS L'ORDRE DE LA FICHE :
///   1. UN SEUL MOTEUR — les chiffres de la simulation sont mesures par
///      [computeTrackStatsOnTrace], celui du lot 671-06, et par personne
///      d'autre. Le marcheur ne cumule rien.
///   2. AUCUN GPS, AUCUNE AUTORISATION — prouve sur la source et le robinet.
///   3. AUCUNE ECRITURE — la base reste vide apres une simulation entiere.
///   4. LA BARRE ET LE JOURNAL MESURENT LA SIMULATION, sans un releve en base.
///   5. LA TRACE EST CELLE DU SENTIER — le marcheur ne quitte jamais le trace.
///   6. LE TEMPS EST ACCELERE ET L'ECRAN LE DIT, dans les cinq langues.
///   7. PAUSE, REPRISE, ARRET — et aucune minuterie ne survit a la sortie.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/journal/providers/journal_day_providers.dart';
import 'package:moteur_gr/features/journal/providers/journal_providers.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule.dart';
import 'package:moteur_gr/features/trek/data/source_des_releves.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/mesure_des_sources_645.dart'
    show estLigneDeCommentaire, lignesDe;

/// LE CODE de [rel], SANS SES COMMENTAIRES.
///
/// Les gardes de ce fichier cherchent des motifs interdits — `Haversine`,
/// `insertPoint`, `Geolocator.` — dans le marcheur simule. Or sa documentation
/// EXPLIQUE justement qu'il ne fait rien de tout cela, et elle nomme donc ces
/// motifs. Sans ce filtre, la garde rougirait sur la phrase qui la justifie :
/// c'est le defaut que `estLigneDeCommentaire` existe pour eviter, et son
/// en-tete le dit mot pour mot.
String _codeDe(String rel) => [
  for (final ligne in lignesDe(rel))
    if (!estLigneDeCommentaire(ligne)) ligne,
].join('\n');

/// Metres par degre de latitude : la trace du test suit un meridien, donc
/// `distanceFromStart` y est EXACTE et la projection du moteur retombe au
/// metre pres sur la position du marcheur.
const double _metresParDegre = 111194.93;

/// LA TRACE DU TEST : 3 km plein nord, un point tous les 50 m, qui monte de
/// 1000 a 1300 m sur la premiere moitie et redescend a 1150 m sur la seconde.
///
/// Un vrai profil, parce que le denivele doit avoir quelque chose a mesurer :
/// une trace plate aurait rendu D+ = 0 et le test aurait passe sans rien dire.
final List<TrackPoint> _trace = <TrackPoint>[
  for (var i = 0; i <= 60; i++)
    TrackPoint(
      lat: 45.0 + (i * 50.0) / _metresParDegre,
      lng: 3.0,
      altitude: i <= 30 ? 1000.0 + i * 10.0 : 1300.0 - (i - 30) * 5.0,
      distanceFromStart: i * 50.0,
    ),
];

final DateTime _depart = DateTime.utc(2026, 10, 9, 8);

/// UNE MINUTERIE QUE LE TEST FAIT AVANCER LUI-MEME.
///
/// Aucun test de ce fichier n'attend une vraie demi-seconde : le marcheur
/// recoit cette fabrique et le test appelle [avancer]. Un test qui dort est
/// un test qui devient intermittent.
class _MinuterieFausse implements Timer {
  _MinuterieFausse(this._action);

  final void Function(Timer) _action;
  bool _active = true;
  int _tick = 0;

  /// Declenche [pas] battements, ou s'arrete des que la minuterie est coupee.
  void avancer(int pas) {
    for (var i = 0; i < pas && _active; i++) {
      _tick++;
      _action(this);
    }
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}

/// Garde la derniere minuterie creee, pour que le test la fasse avancer.
class _Horloge {
  _MinuterieFausse? derniere;

  /// La fabrique passee au marcheur. Le type est nomme ICI pour que
  /// [FabriqueDeMinuterie] ait un appelant hors de son fichier.
  FabriqueDeMinuterie get fabrique =>
      (Duration periode, void Function(Timer) action) {
        final minuterie = _MinuterieFausse(action);
        derniere = minuterie;
        return minuterie;
      };
}

/// Un marcheur de test : minuterie pilotee, horloge figee, et SANS observateur
/// de cycle de vie (il exige un binding Flutter que les tests purs n'ont pas).
({MarcheurSimule marcheur, _Horloge horloge}) _marcheur({
  bool cycleDeVie = false,
}) {
  final horloge = _Horloge();
  final marcheur = MarcheurSimule(
    minuterie: horloge.fabrique,
    maintenant: () => _depart,
    surveillerLeCycleDeVie: cycleDeVie,
  );
  addTearDown(marcheur.fermer);
  return (marcheur: marcheur, horloge: horloge);
}

/// Fait marcher [pas] battements sur la trace du test.
({MarcheurSimule marcheur, _Horloge horloge}) _marcheDe(int pas) {
  final m = _marcheur();
  expect(
    m.marcheur.demarrer(
      trace: _trace,
      trailId: testTrailConfig.id,
      sessionId: 'sim-1',
    ),
    isTrue,
  );
  m.horloge.derniere!.avancer(pas);
  return m;
}

TrekSession _session(String id) => TrekSession(
  id: id,
  trailId: testTrailConfig.id,
  startedAt: _depart,
  status: 'active',
);

/// Un notifier de session FIGE : ces gardes mesurent la SOURCE des chiffres,
/// pas la machine de session (deja tenue par les gardes 638 et 649).
class _SessionFigee extends TrekSessionManagerNotifier {
  _SessionFigee(this._etat);

  final TrackingSessionState _etat;

  @override
  TrackingSessionState build() => _etat;
}

/// Un journal SANS AUCUNE ENTREE : c'est le cas de la demo, qui n'ecrit pas une
/// ligne de carnet.
class _JournalVide extends JournalScreenNotifier {
  @override
  JournalScreenState build() => const JournalScreenState();
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  ProviderContainer conteneur({
    required MarcheurSimule marcheur,
    required bool enDemo,
    TrekSession? session,
  }) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(
          testTrailConfig.id,
        ).overrideWith((ref) async => _trace),
        enDemoProvider.overrideWithValue(enDemo),
        marcheurSimuleProvider.overrideWithValue(marcheur),
        journalScreenProvider.overrideWith(_JournalVide.new),
        trekSessionManagerProvider.overrideWith(
          () => _SessionFigee(
            TrackingSessionState(
              status: session == null
                  ? TrackingSessionStatus.idle
                  : TrackingSessionStatus.recording,
              session: session,
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // =========================================================================
  // 5. LA TRACE EST CELLE DU SENTIER, PAS UNE INVENTION
  // =========================================================================
  group('742 — le marcheur avance sur la trace du sentier, et nulle part '
      'ailleurs', () {
    test('il refuse de marcher sans trace exploitable', () {
      final m = _marcheur();
      expect(
        m.marcheur.demarrer(trace: const [], trailId: 'x'),
        isFalse,
        reason:
            'Sans deux points il n y a pas de chemin : mieux vaut refuser que '
            'simuler une marche sur place.',
      );
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);
    });

    test('le premier releve part du DEBUT de la trace, sans attendre un '
        'battement', () {
      final m = _marcheur();
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      // UN SEUL releve, deja pose : le moteur en demande DEUX pour avoir une
      // duree mesurable, autant ne pas perdre la premiere demi-seconde.
      expect(m.marcheur.releves, hasLength(1));
      expect(m.marcheur.releves.first.lat, closeTo(_trace.first.lat, 1e-9));
      expect(m.marcheur.distanceSimuleeM, 0);
      expect(m.marcheur.etat, EtatDuMarcheur.enMarche);
    });

    test('chaque battement avance du pas annonce, et le releve reste SUR la '
        'trace', () {
      final m = _marcheDe(9);
      // 10 releves : celui du depart + 9 battements.
      expect(m.marcheur.releves, hasLength(10));
      expect(
        m.marcheur.distanceSimuleeM,
        closeTo(9 * MarcheurSimule.pasEnMetres, 1e-6),
      );
      // La trace suit le meridien 3° E : un releve qui s'en ecarte ne serait
      // plus sur le sentier, et la projection du moteur le refuserait.
      for (final releve in m.marcheur.releves) {
        expect(releve.lng, closeTo(3.0, 1e-9));
        final attendu =
            45.0 +
            (releve.id - 1) * MarcheurSimule.pasEnMetres / _metresParDegre;
        expect(releve.lat, closeTo(attendu, 1e-7));
      }
    });

    test('entre deux points de la trace, la position est INTERPOLEE', () {
      final m = _marcheDe(1);
      // Un pas vaut 33,33 m : le marcheur est entre le point 0 (0 m, 1000 m
      // d'altitude) et le point 1 (50 m, 1010 m), aux deux tiers du segment.
      final releve = m.marcheur.releves.last;
      expect(releve.altitude, closeTo(1000.0 + 10.0 * (100 / 150), 0.01));
      expect(
        releve.lat,
        closeTo(45.0 + MarcheurSimule.pasEnMetres / _metresParDegre, 1e-9),
      );
    });

    test('au bout de la trace il ARRIVE, et cesse d avancer', () {
      final m = _marcheur();
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      // 3000 m a 33,33 m par battement : 90 battements. On en demande large.
      m.horloge.derniere!.avancer(200);
      expect(m.marcheur.etat, EtatDuMarcheur.arrive);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(m.marcheur.distanceSimuleeM, closeTo(3000.0, 1e-6));
      expect(
        m.marcheur.releves.last.lat,
        closeTo(_trace.last.lat, 1e-9),
        reason: 'Le dernier releve est pose EXACTEMENT sur l arrivee.',
      );
    });
  });

  // =========================================================================
  // 1 + 6. UN SEUL MOTEUR, ET LE TEMPS DE LA MARCHE DANS LES RELEVES
  // =========================================================================
  group('742 — le temps est accelere, et le moteur EXISTANT mesure une allure '
      'de randonneur', () {
    test('une seconde reelle vaut une minute de marche', () {
      expect(MarcheurSimule.kFacteurTemps, 60);
      expect(MarcheurSimule.kPeriodeReelle, const Duration(milliseconds: 500));
      expect(MarcheurSimule.pasDeTempsSimule, const Duration(seconds: 30));
      expect(MarcheurSimule.pasEnMetres, closeTo(33.333, 0.001));
    });

    test('les releves portent l HORLOGE DE LA MARCHE, pas celle de la '
        'demonstration', () {
      final m = _marcheDe(4);
      final releves = m.marcheur.releves;
      expect(releves.first.recordedAt, _depart);
      // Quatre battements = quatre demi-secondes a l'ecran, DEUX MINUTES de
      // marche dans les releves.
      expect(releves.last.recordedAt, _depart.add(const Duration(minutes: 2)));
    });

    test('LA GARDE CENTRALE : computeTrackStatsOnTrace mesure ~4 km/h sur les '
        'releves simules', () {
      final m = _marcheDe(60);
      final chiffres = computeTrackStatsOnTrace(
        readings: m.marcheur.releves,
        trace: _trace,
        currentDistanceM: m.marcheur.distanceSimuleeM,
      );

      expect(
        chiffres.hasData,
        isTrue,
        reason: 'Sans deux releves, la barre garde ses tirets.',
      );
      // SI LES RELEVES PORTAIENT L'HEURE REELLE, la vitesse mesuree serait de
      // 240 km/h — au-dela du plafond de marche du moteur (15 km/h), qui rend
      // alors `null`. Ce test echouerait donc des deux facons : chiffre absent,
      // ou chiffre absurde. C'est la preuve que l'horloge simulee est la bonne.
      expect(chiffres.averageSpeedKmh, isNotNull);
      expect(
        chiffres.averageSpeedKmh!,
        closeTo(MarcheurSimule.kVitesseSimuleeKmh, 0.05),
        reason:
            'La vitesse affichee est MESUREE par le moteur sur les releves ; '
            'elle doit retomber sur l allure simulee.',
      );
      expect(
        chiffres.distanceKm,
        closeTo(60 * MarcheurSimule.pasEnMetres / 1000, 0.02),
      );
      expect(
        chiffres.elevationGainM,
        greaterThan(0),
        reason: 'La trace monte : le denivele mesure doit le voir.',
      );
    });

    test('le marcheur ne cumule RIEN : aucun calcul de distance, de denivele '
        'ni de vitesse dans son code', () {
      final source = _codeDe('lib/features/trek/data/marcheur_simule.dart');
      for (final interdit in [
        'haversine',
        'Haversine',
        'elevationNoiseThreshold',
        'elevationGain',
        'distanceKm',
        'averageSpeed',
      ]) {
        expect(
          source.contains(interdit),
          isFalse,
          reason:
              'LE MARCHEUR FABRIQUE DES RELEVES, IL NE MESURE RIEN. '
              '« $interdit » dans ce fichier, c est un SECOND moteur qui '
              'commence — '
              'et deux moteurs donnent deux deniveles pour la meme journee '
              '(c est tout le sujet du lot 671-06).',
        );
      }
    });
  });

  // =========================================================================
  // 2. AUCUN GPS, AUCUNE AUTORISATION
  // =========================================================================
  group('742 — la simulation n arme aucun GPS et ne demande aucune '
      'autorisation', () {
    test('le marcheur ne connait ni Geolocator, ni permission, ni position '
        'reelle', () {
      final source = _codeDe('lib/features/trek/data/marcheur_simule.dart');
      for (final interdit in [
        'Geolocator.',
        'getPositionStream',
        'getCurrentPosition',
        'Permission',
        'requestPermission',
        'checkPermission',
      ]) {
        expect(
          source.contains(interdit),
          isFalse,
          reason:
              'C EST LA RAISON D ETRE DU MODE DEMO : on ne demande pas sa '
              'position a quelqu un qui ne bouge pas. « $interdit » ici, et '
              'une '
              'demonstration ferait surgir un ecran systeme.',
        );
      }
    });

    test('en demo, le robinet unique est alimente par le marcheur — et le '
        'profil GPS n est NI lu NI ecrit', () {
      final source = _codeDe('lib/features/trek/data/gps_service.dart');
      final enDemo = source.substring(
        source.indexOf('if (ref.watch(enDemoProvider))'),
        source.indexOf('return PositionController(\n    writeProfile:'),
      );
      expect(
        enDemo.contains('marcheur.positions'),
        isTrue,
        reason: 'La source des positions, en demo, est le marcheur simule.',
      );
      for (final interdit in [
        'bgWritePositionProfile',
        'bgReadStoredPositionProfile',
      ]) {
        expect(
          enDemo.contains(interdit),
          isFalse,
          reason:
              'Armer le canal du profil ecrirait une PREFERENCE pour l isolate '
              'de fond — une trace durable, que la demo s interdit.',
        );
      }
    });

    test('le marcheur ne tire aucune position tant qu on ne l a pas fait '
        'partir', () {
      final m = _marcheur();
      expect(m.marcheur.dernierePosition, isNull);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(m.marcheur.releves, isEmpty);
    });
  });

  // =========================================================================
  // 3. AUCUNE ECRITURE EN BASE
  // =========================================================================
  group('742 — la simulation n ecrit rien, nulle part', () {
    test('le marcheur ne sait pas ecrire : ni DAO, ni base, ni preference', () {
      final source = _codeDe('lib/features/trek/data/marcheur_simule.dart');
      for (final interdit in [
        'insertPoint',
        'upsertSession',
        'databaseProvider',
        'SharedPreferences',
        'into(',
        'update(',
      ]) {
        expect(
          source.contains(interdit),
          isFalse,
          reason:
              '« rien en base » est une decision de Christophe (tache 634). '
              '« $interdit » dans le marcheur, et la demo laisserait une '
              'trace.',
        );
      }
    });

    test('une marche entiere ne laisse AUCUN releve et AUCUNE session en '
        'base', () async {
      final m = _marcheur();
      m.marcheur.demarrer(
        trace: _trace,
        trailId: testTrailConfig.id,
        sessionId: 'sim-1',
      );
      m.horloge.derniere!.avancer(200);
      expect(m.marcheur.releves, hasLength(greaterThan(80)));

      // LA MEMOIRE EST PLEINE, LA BASE EST VIDE : c'est exactement la promesse.
      expect(
        await db.sessionTrackPointsDao.getByTrailId(
          testTrailConfig.id,
          read: TrackPointsRead.withEstimated,
        ),
        isEmpty,
      );
      expect(await db.trekSessionsDao.ongoingRows(), isEmpty);
    });
  });

  // =========================================================================
  // 4. LA BARRE DE LA CARTE ET LE JOURNAL DU JOUR MESURENT LA SIMULATION
  // =========================================================================
  group('742 — la barre de la carte mesure la simulation, sans un releve en '
      'base', () {
    test('la source des releves bascule sur la MEMOIRE en demo, et sur la '
        'base hors demo', () async {
      final m = _marcheDe(30);

      final enDemo = conteneur(marcheur: m.marcheur, enDemo: true);
      expect(enDemo.read(sourceDesRelevesProvider).enMemoire, isTrue);
      expect(
        await enDemo
            .read(sourceDesRelevesProvider)
            .parSession('sim-1', read: TrackPointsRead.gpsOnly),
        hasLength(31),
      );

      final horsDemo = conteneur(marcheur: m.marcheur, enDemo: false);
      expect(horsDemo.read(sourceDesRelevesProvider).enMemoire, isFalse);
      expect(
        await horsDemo
            .read(sourceDesRelevesProvider)
            .parSession('sim-1', read: TrackPointsRead.gpsOnly),
        isEmpty,
        reason:
            'Hors demo la lecture passe au DAO, mot pour mot — et la base '
            'de ce '
            'test est vide.',
      );
    });

    test('liveTrekStats rend des chiffres MESURABLES en demo', () async {
      final m = _marcheDe(60);
      final container = conteneur(
        marcheur: m.marcheur,
        enDemo: true,
        session: _session('sim-1'),
      );

      final chiffres = await container.read(liveTrekStatsProvider.future);
      expect(
        chiffres.hasData,
        isTrue,
        reason:
            'C EST LE DEFAUT DU BUILD 12 : sans releves, `hasData` etait faux '
            'et la barre affichait Parcouru « -- », Vit. moy. « -- ».',
      );
      expect(chiffres.distanceKm, greaterThan(1.0));
      expect(chiffres.averageSpeedKmh, isNotNull);
      expect(
        chiffres.averageSpeedKmh!,
        closeTo(MarcheurSimule.kVitesseSimuleeKmh, 0.6),
      );
      expect(chiffres.elevationGainM, greaterThan(0));
    });

    test('le cumul en memoire ne lit que les releves du bon sentier', () async {
      final m = _marcheDe(20);
      final container = conteneur(marcheur: m.marcheur, enDemo: true);
      final source = container.read(sourceDesRelevesProvider);

      expect(
        await source.parSentier(
          testTrailConfig.id,
          read: TrackPointsRead.gpsOnly,
        ),
        hasLength(21),
      );
      expect(
        await source.parSentier(
          'un-autre-sentier',
          read: TrackPointsRead.gpsOnly,
        ),
        isEmpty,
      );
    });
  });

  group('742 — le journal du jour montre la journee marchee, meme sans une '
      'seule note', () {
    test('la journee marchee EXISTE dans le carnet', () {
      final m = _marcheDe(30);
      final container = conteneur(marcheur: m.marcheur, enDemo: true);

      final jours = container.read(journalDaysProvider);
      expect(
        jours,
        contains(DateTime(_depart.year, _depart.month, _depart.day)),
        reason:
            'LE DEUXIEME VERROU DU BUILD 12 : les journees du carnet venaient '
            'des ENTREES, et une demo n en ecrit aucune. Sans journee, aucune '
            'journee selectionnee, donc ni trace du jour ni chiffres du jour — '
            'avant meme de chercher un releve.',
      );
      expect(container.read(journalSelectedDayProvider), isNotNull);
    });

    test('et ses chiffres sont mesures par computeDayStats', () async {
      final m = _marcheDe(60);
      final container = conteneur(marcheur: m.marcheur, enDemo: true);

      final trace = await container.read(journalDayTraceProvider.future);
      expect(trace, hasLength(61));

      final chiffres = await container.read(journalDayStatsProvider.future);
      expect(chiffres.hasData, isTrue);
      expect(chiffres.distanceKm, greaterThan(1.0));
      expect(chiffres.averageSpeedKmh, isNotNull);
    });

    test('hors demo, le carnet ne gagne aucune journee', () {
      final m = _marcheDe(30);
      final container = conteneur(marcheur: m.marcheur, enDemo: false);
      expect(
        container.read(journalDaysProvider),
        isEmpty,
        reason:
            'La memoire du marcheur ne doit JAMAIS se melanger a un vrai '
            'carnet : hors demo, elle n est pas lue.',
      );
    });
  });

  // =========================================================================
  // 7. PAUSE, REPRISE, ARRET — ET RIEN NE SURVIT A LA SORTIE
  // =========================================================================
  group('742 — elle se met en pause, elle reprend, elle s arrete', () {
    test('la pause coupe la minuterie et GARDE les releves', () {
      final m = _marcheDe(10);
      final avant = m.marcheur.releves.length;

      m.marcheur.pause();
      expect(m.marcheur.etat, EtatDuMarcheur.enPause);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(m.marcheur.releves, hasLength(avant));

      // La minuterie d'avant est coupee : meme sollicitee, elle n avance plus.
      m.horloge.derniere!.avancer(5);
      expect(m.marcheur.releves, hasLength(avant));
    });

    test('la reprise repart ou la marche s etait arretee, et LE TEMPS DE PAUSE '
        'NE COMPTE PAS', () {
      final m = _marcheDe(10);
      final distanceAvant = m.marcheur.distanceSimuleeM;
      final heureAvant = m.marcheur.releves.last.recordedAt;

      m.marcheur.pause();
      m.marcheur.reprendre();
      expect(m.marcheur.etat, EtatDuMarcheur.enMarche);
      m.horloge.derniere!.avancer(1);

      expect(
        m.marcheur.distanceSimuleeM,
        closeTo(distanceAvant + MarcheurSimule.pasEnMetres, 1e-6),
      );
      expect(
        m.marcheur.releves.last.recordedAt,
        heureAvant.add(MarcheurSimule.pasDeTempsSimule),
        reason:
            'Une pause de dix minutes pendant la demonstration ne doit pas '
            'faire chuter la vitesse moyenne mesuree.',
      );
    });

    test('terminer garde les releves — le journal du jour reste lisible apres '
        'l arrivee', () {
      final m = _marcheDe(10);
      final avant = m.marcheur.releves.length;
      m.marcheur.terminer();
      expect(m.marcheur.etat, EtatDuMarcheur.arrive);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(m.marcheur.releves, hasLength(avant));
    });

    test('arreter JETTE TOUT, et aucune minuterie ne survit', () {
      final m = _marcheDe(10);
      m.marcheur.arreter();
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(m.marcheur.releves, isEmpty);
      expect(m.marcheur.dernierePosition, isNull);
      expect(m.marcheur.distanceSimuleeM, 0);
    });

    test('arreter deux fois ne casse rien — quitter la demo sans etre parti '
        'est le cas le PLUS courant', () {
      final m = _marcheur();
      m.marcheur.arreter();
      m.marcheur.arreter();
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);
    });

    test('QUITTER LA DEMO arrete la simulation : `arreterSimulationDemo` '
        'appelle bien le marcheur', () async {
      final m = _marcheDe(10);
      expect(m.marcheur.releves, isNotEmpty);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          enDemoProvider.overrideWithValue(true),
          marcheurSimuleProvider.overrideWithValue(m.marcheur),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(trekSessionManagerProvider.notifier)
          .arreterSimulationDemo();

      expect(m.marcheur.minuterieActive, isFalse);
      expect(
        m.marcheur.releves,
        isEmpty,
        reason:
            'La sortie de demo promet qu il ne reste RIEN : pas une minuterie, '
            'pas un releve.',
      );
    });

    test('l etat du marcheur est PUBLIE, sinon la mention de l ecran resterait '
        'figee', () async {
      final m = _marcheur();
      final vus = <EtatDuMarcheur>[];
      final abonnement = m.marcheur.etats.listen(vus.add);
      addTearDown(abonnement.cancel);

      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.marcheur.pause();
      m.marcheur.reprendre();
      m.marcheur.arreter();
      await Future<void>.delayed(Duration.zero);

      expect(vus, [
        EtatDuMarcheur.enMarche,
        EtatDuMarcheur.enPause,
        EtatDuMarcheur.enMarche,
        EtatDuMarcheur.arrete,
      ]);
    });
  });

  group('742 — l application en arriere-plan met la marche en pause', () {
    testWidgets('elle ne continue pas d avancer ecran eteint', (tester) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      expect(m.marcheur.etat, EtatDuMarcheur.enMarche);

      // Le cycle de vie de l'application, tel que Flutter le livre.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      expect(
        m.marcheur.etat,
        EtatDuMarcheur.enPause,
        reason:
            'Une demonstration que personne ne regarde ne doit pas faire '
            'tourner une minuterie — et la demo ne fait rien vivre en fond.',
      );
      expect(m.marcheur.minuterieActive, isFalse);
    });
  });

  // =========================================================================
  // 6. L ECRAN LE DIT, DANS LES CINQ LANGUES
  // =========================================================================
  group('742 — l ecran annonce la marche simulee, dans les cinq langues', () {
    test('la mention existe partout, et porte le facteur', () {
      for (final langue in AppLocale.values) {
        final mention = langue.buildSync().demo.marcheSimulee(
          facteur: MarcheurSimule.kFacteurTemps,
        );
        expect(mention.trim(), isNotEmpty, reason: langue.languageCode);
        expect(
          mention.contains('60'),
          isTrue,
          reason:
              'LE FACTEUR EST ANNONCE EN CLAIR (${langue.languageCode}) : une '
              'mention qui dirait seulement « simulation » laisserait croire a '
              'une marche de six heures.',
        );
      }
      expect(AppLocale.values, hasLength(5));
    });

    test('le francais est ecrit en francais correct, avec ses accents', () {
      final fr = AppLocale.fr.buildSync().demo.marcheSimulee(facteur: 60);
      expect(fr, 'Marche simulée — temps accéléré ×60');
    });
  });
}
