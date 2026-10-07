// LOT 671-02 — LE SOCLE PODOMETRE : LA LONGUEUR DE PAS ET LE FLUX DE PAS.
//
// CE QUE CE FICHIER PROUVE, dans l'ordre de la fiche (E7) :
//
//  1. LE GARDE-FOU, EN PREMIER : le telepherique et la remontee mecanique
//     sont rejetes et n'entrent pas dans la moyenne ; 0,39 m et 1,11 m sont
//     rejetes, 0,40 m et 1,10 m acceptes (bornes INCLUSES) ; zero pas est
//     rejete sans division ; 10 m est rejete comme trop court.
//  2. LA MOYENNE GLISSANTE sur cinq intervalles acceptes.
//  3. LA VALEUR DE DEPART ET LA PERSISTANCE au point de calibration.
//  4. LE COMPTEUR QUI RECULE (redemarrage du telephone) : le total ne
//     diminue jamais.
//  5. LE PAQUET : un bond de 400 pas est compte tel quel.
//  6. L'ABSENCE ET L'ERREUR : le compte vaut nul, le champ 5 un tiret, et le
//     suivi continue.
//  7. LA REPRISE apres une fermeture de l'application.
//  9. LE TEMOIN DE NON-REGRESSION : avec et sans pas, rien de visible ne
//     change.
// 10. LA GARDE : ni reseau ni Firebase, et ni Flutter ni greffon dans les deux
//     classes pures.
//
// (8, l'autorisation, vit dans `permission_activite_physique_671_test.dart`.)
//
// AUCUN CAPTEUR REEL, AUCUN VRAI TEMPS : faux flux de pas par la fabrique du
// constructeur de SensorFusionService, fausse horloge, faux GPS, fausses
// preferences partagees.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/core/services/sensor_fusion_service.dart';
import 'package:moteur_gr/features/tracking/domain/tracking_engine.dart';
import 'package:moteur_gr/features/trek/data/background_cadence.dart';
import 'package:moteur_gr/features/trek/data/calibration_du_pas.dart';
import 'package:moteur_gr/features/trek/data/measure_recorder.dart';
import 'package:moteur_gr/features/trek/data/podometre_preferences.dart';
import 'package:moteur_gr/features/trek/domain/accumulateur_de_pas.dart';
import 'package:moteur_gr/features/trek/domain/longueur_de_pas.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Les faux : horloge, GPS, enregistreur
// ---------------------------------------------------------------------------

class _FauxMinuteur implements Timer {
  _FauxMinuteur(this.echeance, this.action);

  final DateTime echeance;
  final void Function() action;
  bool actif = true;

  @override
  void cancel() => actif = false;

  @override
  bool get isActive => actif;

  @override
  int get tick => 0;
}

/// Une horloge qu'on avance a la main, et ses minuteurs.
class _Horloge {
  DateTime maintenant = DateTime(2026, 10, 7, 9);
  final _minuteurs = <_FauxMinuteur>[];

  DateTime now() => maintenant;

  Timer armer(Duration delai, void Function() action) {
    final m = _FauxMinuteur(maintenant.add(delai), action);
    _minuteurs.add(m);
    return m;
  }

  Future<void> avancer(Duration duree) async {
    final fin = maintenant.add(duree);
    while (true) {
      final dus =
          _minuteurs.where((m) => m.actif && !m.echeance.isAfter(fin)).toList()
            ..sort((a, b) => a.echeance.compareTo(b.echeance));
      if (dus.isEmpty) break;
      final m = dus.first..actif = false;
      maintenant = m.echeance;
      m.action();
      await _laisserPasser();
    }
    maintenant = fin;
    await _laisserPasser();
  }
}

Future<void> _laisserPasser() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Position _position(double lat) => Position(
  latitude: lat,
  longitude: 9,
  altitude: 1000 + lat,
  accuracy: 4,
  altitudeAccuracy: 3,
  heading: 0,
  headingAccuracy: 0,
  speed: 1,
  speedAccuracy: 0,
  timestamp: DateTime(2026, 10, 7, 9),
);

/// Un faux recepteur GPS en tir unique.
class _FauxGps {
  _FauxGps(this.horloge);

  final _Horloge horloge;
  final tirs = <Completer<Position>>[];

  Stream<Position> ouvrir({required LocationSettings locationSettings}) =>
      const Stream<Position>.empty();

  Future<Position> tirer(LocationSettings reglages) {
    final c = Completer<Position>();
    tirs.add(c);
    return c.future;
  }

  Future<void> repondre(double lat, Duration delai) async {
    await horloge.avancer(delai);
    tirs.last.complete(_position(lat));
    await _laisserPasser();
  }
}

/// Un enregistreur de journal sur un dossier temporaire, et ses lectures.
class _Enregistreur {
  _Enregistreur(
    this.dossier, {
    Stream<int> Function()? pas,
    Future<bool> Function()? autorises,
    PodometerStore? canal,
    String session = 'session-1',
  }) {
    journal = MeasureJournal(directory: () async => Directory(dossier));
    enregistreur = MeasureRecorder(
      journal: journal,
      readBattery: () async => 80,
      stepCounts: pas,
      stepsAllowed: autorises,
      podometer: canal,
      sessionId: () => session,
      schedule: horloge.armer,
      now: horloge.now,
    );
  }

  final String dossier;
  final horloge = _Horloge();
  late final MeasureJournal journal;
  late final MeasureRecorder enregistreur;

  Future<List<String>> lignes() async {
    await _laisserPasser();
    await journal.idle;
    final f = File('$dossier/$kMeasureJournalFileName');
    return f.existsSync() ? f.readAsLinesSync() : const <String>[];
  }

  /// Les valeurs nommees de la derniere ligne de compteurs.
  Future<Map<String, String>> compteurs() async {
    await enregistreur.writeCounters();
    final ligne = (await lignes()).last;
    return {
      for (final v in ligne.split(';').skip(3))
        v.substring(0, v.indexOf('=')): v.substring(v.indexOf('=') + 1),
    };
  }

  /// Le champ 5 (pas) du dernier releve.
  Future<String> champPasDuDernierReleve() async {
    final releves = [
      for (final l in await lignes())
        if (l.split(';')[2] == 'releve') l.split(';'),
    ];
    return releves.last[4];
  }
}

/// Le faux flux de pas passe par la COUTURE EXISTANTE : la fabrique du
/// constructeur de [SensorFusionService]. Aucun point d'injection neuf.
Stream<int> Function() _parLeService(Stream<int> flux) =>
    () => SensorFusionService(stepCountStream: () => flux).stepCountStream();

void main() {
  late Directory bac;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    bac = Directory.systemTemp.createTempSync('longueur_de_pas_671_');
  });

  tearDown(() {
    if (bac.existsSync()) bac.deleteSync(recursive: true);
  });

  group('671-02 (1) — le garde-fou, en premier', () {
    test('le telepherique et la remontee mecanique sont REJETES et '
        'n entrent pas dans la moyenne', () {
      final depart = StrideCalibration([0.70]);
      // Le telepherique : cinq kilometres pour trente pas, 166 m par pas.
      final telepherique = depart.offer(distanceMeters: 5000, steps: 30);
      // Le telesiege lent : 600 m pour 300 pas pietines, 2,00 m par pas.
      final telesiege = telepherique.calibration.offer(
        distanceMeters: 600,
        steps: 300,
      );
      final retenue = telesiege.calibration.meters;
      expect(
        retenue,
        closeTo(0.70, 1e-9),
        reason:
            'longueur de pas retenue : ${retenue.toStringAsFixed(2)} m. '
            'Une remontee mecanique est entree dans la moyenne et '
            'l empoisonne pour le reste de la journee.',
      );
      expect(telepherique.outcome.rejection, StrideRejection.outOfBounds);
      expect(telepherique.outcome.intervalMeters, closeTo(166.67, 0.01));
      expect(telesiege.outcome.rejection, StrideRejection.outOfBounds);
      expect(telesiege.calibration.accepted, [0.70]);
    });

    test('0,39 m et 1,11 m sont rejetes ; 0,40 m et 1,10 m sont acceptes : '
        'les deux bornes sont INCLUSES', () {
      StrideOutcome juge(double distance) =>
          StrideOutcome.judge(distanceMeters: distance, steps: 200);
      expect(juge(78).rejection, StrideRejection.outOfBounds, reason: '0,39');
      expect(juge(222).rejection, StrideRejection.outOfBounds, reason: '1,11');
      expect(juge(80).accepted, isTrue, reason: '0,40 m, borne basse');
      expect(juge(220).accepted, isTrue, reason: '1,10 m, borne haute');
      expect(kStrideMinMeters, 0.40);
      expect(kStrideMaxMeters, 1.10);
    });

    test('zero pas est rejete SANS division : c est l arret, pas une '
        'mesure', () {
      final arret = StrideCalibration().offer(distanceMeters: 300, steps: 0);
      expect(arret.outcome.rejection, StrideRejection.noSteps);
      expect(arret.outcome.intervalMeters, isNull);
      expect(arret.calibration.isCalibrated, isFalse);
      final recul = StrideOutcome.judge(distanceMeters: 300, steps: -12);
      expect(recul.rejection, StrideRejection.noSteps);
    });

    test('un intervalle de 10 m est rejete comme trop court : un pas d '
        'erreur y pese 7,5 %', () {
      final court = StrideCalibration().offer(distanceMeters: 10, steps: 13);
      expect(court.outcome.rejection, StrideRejection.tooShort);
      expect(court.calibration.isCalibrated, isFalse);
      expect(kStrideMinIntervalMeters, 50);
      expect(
        StrideOutcome.judge(distanceMeters: 50, steps: 67).accepted,
        isTrue,
        reason: '50 m, le minimum, est accepte',
      );
    });
  });

  group('671-02 (2) — la moyenne glissante', () {
    StrideCalibration nourrir(List<double> longueurs) {
      var c = StrideCalibration();
      for (final l in longueurs) {
        c = c.offer(distanceMeters: l * 100, steps: 100).calibration;
      }
      return c;
    }

    test('cinq intervalles acceptes donnent exactement leur moyenne', () {
      final c = nourrir([0.70, 0.72, 0.74, 0.76, 0.78]);
      expect(c.meters, closeTo(0.74, 1e-9));
      expect(kStrideWindowSize, 5);
    });

    test('le sixieme fait sortir le premier', () {
      final c = nourrir([0.70, 0.72, 0.74, 0.76, 0.78, 0.80]);
      expect(c.accepted.first, closeTo(0.72, 1e-9));
      expect(c.accepted, hasLength(5));
      expect(c.meters, closeTo(0.76, 1e-9));
    });

    test('un intervalle REJETE ne deplace pas la fenetre', () {
      final c = nourrir([0.70, 0.72, 0.74, 0.76, 0.78]);
      final apres = c.offer(distanceMeters: 5000, steps: 30).calibration;
      expect(apres.accepted, c.accepted);
      expect(apres.meters, closeTo(0.74, 1e-9));
    });
  });

  group('671-02 (3) — la valeur de depart et la persistance', () {
    test('sans aucun intervalle accepte, la longueur vaut la constante de '
        'depart, 0,75 m', () {
      expect(StrideCalibration().meters, kStrideDefaultMeters);
      expect(kStrideDefaultMeters, 0.75);
      expect(StrideCalibration().isCalibrated, isFalse);
    });

    test('apres un intervalle accepte, la longueur est ECRITE au point de '
        'calibration, et un nouveau depart la RELIT', () async {
      SharedPreferences.setMockInitialValues({
        kPrefsStepsReadiness: 'possible',
        kPrefsStepsTotal: 1000,
      });
      final canal = PodometerStore();
      final calibration = StrideCalibrationFeed(canal);
      await calibration.observe(120);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(kPrefsStepsTotal, 1400);
      final sort = await calibration.observe(400);

      expect(sort?.accepted, isTrue);
      expect(prefs.getStringList(kPrefsStrideWindow), ['0.7000']);

      // Un nouveau trek, une nouvelle interface : la calibration est relue.
      final relue = await PodometerStore().readStride();
      expect(relue.meters, closeTo(0.70, 1e-9));
      expect(relue.isCalibrated, isTrue);
    });

    test('une valeur illisible, absente ou hors du garde-fou retombe sur la '
        'constante de depart, sans jamais lever', () async {
      for (final valeur in <Object?>[
        null,
        <String>['abc', ''],
        <String>['3.50', '0.05'],
        'pas une liste',
        42,
      ]) {
        SharedPreferences.setMockInitialValues({
          if (valeur != null) kPrefsStrideWindow: valeur,
        });
        final lue = await PodometerStore().readStride();
        expect(lue.meters, kStrideDefaultMeters, reason: 'valeur $valeur');
      }
      expect(
        StrideCalibration.fromStored(['0.66', 'n/a', '9']).accepted,
        [0.66],
        reason: 'seules les valeurs valables sont gardees',
      );
    });
  });

  group('671-02 (4) — le compteur qui recule', () {
    test('monte, REDESCEND (redemarrage du telephone), remonte : le total est '
        'monotone croissant et vaut la somme des deux montees', () {
      final pas = StepAccumulator();
      final totaux = <int>[];
      for (final brut in [1000, 1100, 1300, 50, 120, 250]) {
        pas.add(brut);
        totaux.add(pas.total!);
      }
      for (var i = 1; i < totaux.length; i++) {
        expect(
          totaux[i],
          greaterThanOrEqualTo(totaux[i - 1]),
          reason:
              'le compte de pas a DIMINUE de ${totaux[i - 1]} a '
              '${totaux[i]} apres un redemarrage du telephone : une distance '
              'negative. Totaux successifs : $totaux',
        );
      }
      expect(totaux.last, 300 + 200);
    });

    test('au journal, le champ 5 ne recule pas apres un redemarrage du '
        'telephone', () async {
      final flux = StreamController<int>();
      final b = _Enregistreur(
        bac.path,
        pas: _parLeService(flux.stream),
        autorises: () async => true,
      );
      await b.enregistreur.started(PositionProfile.batteryFirst);
      final champs = <String>[];
      for (final brut in [8000, 8300, 40, 240]) {
        flux.add(brut);
        await _laisserPasser();
        await b.enregistreur.received(_position(42), Duration.zero);
        champs.add(await b.champPasDuDernierReleve());
      }
      expect(champs, ['0', '300', '300', '500']);
      await b.enregistreur.stopped();
      await flux.close();
    });
  });

  group('671-02 (5) — le paquet', () {
    test('un bond de 400 pas d un coup est compte tel quel, sans filtrage ni '
        'lissage', () {
      final pas = StepAccumulator()
        ..add(5000)
        ..add(5400);
      expect(pas.total, 400);
    });
  });

  group('671-02 (6) — l absence et l erreur', () {
    test('flux absent : le compte vaut NUL et le champ 5 un tiret', () async {
      final silencieux = StreamController<int>();
      final b = _Enregistreur(
        bac.path,
        pas: _parLeService(silencieux.stream),
        autorises: () async => true,
      );
      await b.enregistreur.started(PositionProfile.batteryFirst);
      await b.enregistreur.received(_position(42), Duration.zero);
      expect(b.enregistreur.steps, isNull);
      expect(await b.champPasDuDernierReleve(), '-');
      expect((await b.compteurs())['pas'], '-');
      await b.enregistreur.stopped();
      await silencieux.close();
    });

    test('flux qui jette : l erreur est journalisee, le suivi CONTINUE, le '
        'compte vaut nul, rien ne plante', () async {
      final flux = StreamController<int>();
      final b = _Enregistreur(
        bac.path,
        pas: _parLeService(flux.stream),
        autorises: () async => true,
        canal: PodometerStore(),
      );
      await b.enregistreur.started(PositionProfile.batteryFirst);
      flux.add(3000);
      await _laisserPasser();
      flux.addError(StateError('capteur perdu'));
      await _laisserPasser();
      await b.enregistreur.received(_position(42.001), Duration.zero);

      expect(b.enregistreur.steps, isNull);
      expect(await b.champPasDuDernierReleve(), '-');
      final compteurs = await b.compteurs();
      expect(compteurs['pas'], '-');
      expect(compteurs['podometre'], 'flux_en_erreur');
      expect(
        await PodometerStore().readReadiness(),
        EstimateReadiness.streamError,
      );
      await b.enregistreur.stopped();
      final mots = [for (final l in await b.lignes()) l.split(';')[2]];
      expect(mots, containsAllInOrder(['demarrage', 'releve', 'arret']));
      await flux.close();
    });

    test('un telephone sans compteur de pas est dit indisponible, pas en '
        'panne', () {
      expect(
        EstimateReadiness.forError(
          Exception('StepCount not available on this device'),
        ),
        EstimateReadiness.podometerUnavailable,
      );
      expect(
        EstimateReadiness.forError(StateError('capteur perdu')),
        EstimateReadiness.streamError,
      );
    });

    test('sans autorisation, le podometre est dit refuse au journal', () async {
      final b = _Enregistreur(
        bac.path,
        pas: () => const Stream<int>.empty(),
        autorises: () async => false,
      );
      await b.enregistreur.started(PositionProfile.batteryFirst);
      final compteurs = await b.compteurs();
      expect(compteurs['pas'], '-');
      expect(compteurs['podometre'], 'autorisation_refusee');
      await b.enregistreur.stopped();
    });
  });

  group('671-02 (7) — la persistance a travers une reprise', () {
    test('un trek qui reprend apres une fermeture de l application repart du '
        'total persiste, pas de zero', () async {
      final avant = StreamController<int>();
      final premier = _Enregistreur(
        bac.path,
        pas: _parLeService(avant.stream),
        autorises: () async => true,
        canal: PodometerStore(),
      );
      await premier.enregistreur.started(PositionProfile.batteryFirst);
      avant
        ..add(1000)
        ..add(1400);
      await _laisserPasser();
      await premier.enregistreur.received(_position(42), Duration.zero);
      await avant.close();

      // L'application est fermee puis rouverte : un enregistreur neuf.
      final apres = StreamController<int>();
      final second = _Enregistreur(
        bac.path,
        pas: _parLeService(apres.stream),
        autorises: () async => true,
        canal: PodometerStore(),
      );
      await second.enregistreur.started(PositionProfile.batteryFirst);
      expect(second.enregistreur.steps, 400);
      apres.add(1500);
      await _laisserPasser();
      expect(
        second.enregistreur.steps,
        500,
        reason: 'les pas faits application fermee sont comptes',
      );
      await second.enregistreur.stopped();
      await apres.close();
    });

    test('un trek NEUF ne reprend pas le total du precedent', () async {
      SharedPreferences.setMockInitialValues({
        kPrefsStepsSessionId: 'ancienne',
        kPrefsStepsTotal: 9000,
        kPrefsStepsLastRaw: 30000,
      });
      final b = _Enregistreur(
        bac.path,
        pas: () => const Stream<int>.empty(),
        autorises: () async => true,
        canal: PodometerStore(),
        session: 'nouvelle',
      );
      await b.enregistreur.started(PositionProfile.batteryFirst);
      expect(b.enregistreur.steps, isNull);
      await b.enregistreur.stopped();
    });
  });

  group('671-02 (9) — ce lot ne change rien de visible', () {
    test(
      'avec et sans flux de pas simule, les positions recues, la distance '
      'du trek et les statistiques du jour sont STRICTEMENT IDENTIQUES',
      () async {
        Future<(List<String>, TrackingEngine)> marche(
          String sousDossier, {
          required bool avecPas,
        }) async {
          SharedPreferences.setMockInitialValues({
            kPrefsStrideWindow: ['0.70', '0.72'],
          });
          final dossier = Directory('${bac.path}/$sousDossier')..createSync();
          final flux = StreamController<int>();
          final b = _Enregistreur(
            dossier.path,
            pas: avecPas ? _parLeService(flux.stream) : null,
            autorises: () async => avecPas,
            canal: PodometerStore(),
          );
          final gps = _FauxGps(b.horloge);
          final recues = <(Position, String)>[];
          final cadence = BackgroundCadence(
            openStream: gps.ouvrir,
            takeShot: gps.tirer,
            distanceFilter: () => 12,
            onPosition: (position, {required via, required force}) async {
              recues.add((position, via));
              return true;
            },
            keepAliveDue: () => false,
            onHeartbeat: () {},
            observer: b.enregistreur,
            schedule: b.horloge.armer,
            now: b.horloge.now,
          );
          final moteur = TrackingEngine();
          await cadence.start(PositionProfile.batteryFirst);
          for (var i = 0; i < 4; i++) {
            if (avecPas) {
              flux
                ..add(5000 + i * 300)
                ..add(i == 2 ? 10 : 5100 + i * 300);
            }
            await gps.repondre(42 + i / 500, const Duration(seconds: 5));
            await b.horloge.avancer(const Duration(minutes: 2, seconds: 55));
          }
          await b.horloge.avancer(const Duration(minutes: 10));
          for (final (p, _) in recues) {
            moteur.addPosition(
              p.latitude,
              p.longitude,
              p.altitude,
              timestamp: DateTime(2026, 10, 7, 9),
            );
          }
          await cadence.stop();
          unawaited(flux.close());
          return (
            [
              for (final (p, via) in recues)
                '${p.latitude},${p.longitude},${p.altitude},$via',
            ],
            moteur,
          );
        }

        final (avec, statsAvec) = await marche('avec', avecPas: true);
        final (sans, statsSans) = await marche('sans', avecPas: false);
        expect(avec, sans);
        expect(avec, hasLength(4));
        expect(statsAvec.distanceMeters, statsSans.distanceMeters);
        expect(statsAvec.elevationGainM, statsSans.elevationGainM);
        expect(statsAvec.elevationLossM, statsSans.elevationLossM);
        expect(statsAvec.pointCount, statsSans.pointCount);
      },
    );
  });

  group('671-02 — la dispersion, sur une journee simulee', () {
    test('plat, montee raide, descente, plat, descente : sur un terrain '
        'regulier la dispersion reste sous 7 %, elle ne depasse 15 % qu a '
        'une bascule de terrain franche, le temps que la fenetre suive', () {
      final journee = _journeeSimulee();
      var c = StrideCalibration();
      final dispersions = <double>[];
      for (final intervalle in journee) {
        c = c
            .offer(distanceMeters: intervalle.metres, steps: intervalle.pas)
            .calibration;
        dispersions.add(c.spreadPercent ?? 0);
      }
      // Les cinq troncons font 20, 15, 10, 20 et 10 intervalles de 3 min ;
      // une fenetre est « reguliere » quand ses cinq intervalles sont du meme
      // troncon.
      double pire(int de, int a) =>
          dispersions.sublist(de, a).reduce((x, y) => x > y ? x : y);
      final reguliers = {
        'plat': pire(5, 20),
        'montee raide': pire(25, 35),
        'descente': pire(40, 45),
        'plat du soir': pire(50, 65),
        'derniere descente': pire(70, 75),
      };
      for (final MapEntry(:key, :value) in reguliers.entries) {
        expect(value, lessThan(7), reason: '$key : $value %');
      }
      // Bascule franche, plat (0,74 m) vers montee raide (0,58 m).
      expect(pire(20, 25), closeTo(28.4, 0.1));
      // Bascule douce, plat (0,74 m) vers descente (0,68 m) : sous 15 %.
      expect(pire(65, 70), closeTo(12.8, 0.1));
      expect(reguliers['plat'], closeTo(6.5, 0.1));
      expect(c.meters, closeTo(0.68, 0.01));
    });
  });

  group('671-02 (10) — la garde des fichiers neufs', () {
    const fichiersNeufs = [
      'lib/features/trek/domain/longueur_de_pas.dart',
      'lib/features/trek/domain/accumulateur_de_pas.dart',
      'lib/features/trek/data/podometre_preferences.dart',
      'lib/features/trek/data/podometre_permission_service.dart',
      'lib/features/trek/data/calibration_du_pas.dart',
      'lib/features/trek/providers/podometre_providers.dart',
      'lib/features/trek/presentation/podometre_autorisation.dart',
    ];
    const classesPures = [
      'lib/features/trek/domain/longueur_de_pas.dart',
      'lib/features/trek/domain/accumulateur_de_pas.dart',
    ];
    final reseauOuFirebase = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]*(?:firebase|firestore|'''
      r'''cloud_|package:http|package:dio|connectivity|url_launcher|'''
      r'''web_socket|/network/|google_mobile_ads)[^'"]*)['"]''',
      multiLine: true,
    );
    // Une classe pure n'importe que le langage : ni Flutter, ni greffon,
    // ni `dart:ui`, ni `dart:io`.
    final horsDuLangage = RegExp(
      r'''^\s*(?:import|export)\s+['"]((?:package:|dart:ui|dart:io|'''
      r'''\.\.?/)[^'"]*)['"]''',
      multiLine: true,
    );

    List<String> fautifs(RegExp motif, String source) => [
      for (final m in motif.allMatches(source)) m.group(1)!,
    ];

    test('les fichiers neufs n importent ni reseau ni Firebase', () {
      for (final chemin in fichiersNeufs) {
        final interdits = fautifs(
          reseauOuFirebase,
          File(chemin).readAsStringSync(),
        );
        expect(
          interdits,
          isEmpty,
          reason: '$chemin importe un acces reseau ou Firebase : $interdits',
        );
      }
    });

    test('les deux classes pures n importent ni Flutter ni greffon', () {
      for (final chemin in classesPures) {
        final interdits = fautifs(
          horsDuLangage,
          File(chemin).readAsStringSync(),
        );
        expect(
          interdits,
          isEmpty,
          reason: '$chemin n est plus pure : elle importe $interdits',
        );
      }
    });

    test('LA GARDE VOIT VRAIMENT : un import interdit est reconnu', () {
      expect(
        fautifs(
          reseauOuFirebase,
          "import 'package:firebase_core/firebase_core.dart';\n"
          "import 'package:http/http.dart' as http;\n"
          "import 'dart:math';\n",
        ),
        hasLength(2),
      );
      expect(
        fautifs(
          horsDuLangage,
          "import 'package:flutter/widgets.dart';\n"
          "import 'package:pedometer/pedometer.dart';\n"
          "import 'dart:ui';\n"
          "import '../data/podometre_preferences.dart';\n"
          "import 'dart:math' as math;\n",
        ),
        hasLength(4),
      );
    });
  });
}

/// Une journee de marche simulee, intervalle par intervalle (3 min chacun) :
/// 1 h de plat, 45 min de montee raide, 30 min de descente, 1 h de plat,
/// 30 min de descente. Le comptage des pas porte 1 % d'erreur, la distance
/// sur le trace 8 m (projection d'un point GPS sur le trace, aux deux bouts).
/// Generateur deterministe : le test rejoue toujours la meme journee.
List<({double metres, int pas})> _journeeSimulee() {
  var graine = 67102;
  double alea() {
    graine = (graine * 1103515245 + 12345) & 0x7fffffff;
    return graine / 0x7fffffff * 2 - 1;
  }

  const troncons = [
    (intervalles: 20, foulee: 0.74, cadence: 110),
    (intervalles: 15, foulee: 0.58, cadence: 96),
    (intervalles: 10, foulee: 0.68, cadence: 104),
    (intervalles: 20, foulee: 0.74, cadence: 110),
    (intervalles: 10, foulee: 0.68, cadence: 104),
  ];
  return [
    for (final t in troncons)
      for (var i = 0; i < t.intervalles; i++)
        () {
          final vraisPas = t.cadence * 3;
          return (
            metres: vraisPas * t.foulee + 8 * alea(),
            pas: (vraisPas * (1 + 0.01 * alea())).round(),
          );
        }(),
  ];
}
