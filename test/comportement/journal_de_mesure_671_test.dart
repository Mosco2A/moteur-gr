// LOT 671-01 — LE BUILD DE MESURE BATTERIE : TROIS CADENCES ET UN JOURNAL.
//
// CE QUE CE FICHIER PROUVE, dans l'ordre de la fiche (E7) :
//
//  1. LE FORMAT. Chaque ligne ecrite a ce lot a neuf champs dans l'ordre,
//     avec un tiret aux champs sans objet ; la ligne de compteurs a ses neuf
//     valeurs nommees, les deux ajouts du lot a la fin.
//  2. LE VOCABULAIRE. Une liste fermee : tout autre mot est refuse.
//  3. LES CADENCES. Carte en flux, batterie d'abord et batterie basse en tir.
//  4. LE TIR UNIQUE. Aucune souscription vivante entre deux tirs ; un tir
//     expire est journalise puis rien avant la periode suivante ; la sonde de
//     vie ne rouvre jamais de flux.
//  5. LE CHANGEMENT DE PROFIL, sans redemarrage, avec sa ligne reprise.
//  6. L'ECRITURE. Deux isolates, quatre cents lignes entieres ; une erreur
//     d'ecriture est comptee et n'arrete pas le suivi.
//  7. LES DEUX AJOUTS DE PLATEFORME.
//  8. LES PAS BRUTS, sans aucun effet sur les positions ni les statistiques.
// 10. LA GARDE : ni reseau ni Firebase dans les deux fichiers neufs.
// 11. LES DEUX VALEURS AJOUTEES A LA LIGNE DE COMPTEURS.
//
// (9, l'ecran, vit dans `mesure_batterie_screen_test.dart`, meme dossier.)
//
// FAUSSE HORLOGE, FAUX GPS. Aucun cas ne depend du vrai capteur ni du vrai
// temps : les minuteurs sont ceux de [_Horloge], qu'on avance a la main. Seuls
// le banc d'ecriture et le journal touchent le disque, dans un dossier
// temporaire.
library;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/tracking/domain/tracking_engine.dart';
import 'package:moteur_gr/features/trek/data/background_cadence.dart';
import 'package:moteur_gr/features/trek/data/gps_settings_mapping.dart';
import 'package:moteur_gr/features/trek/data/measure_recorder.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';

// ---------------------------------------------------------------------------
// Les faux : horloge, GPS, podometre
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
  DateTime maintenant = DateTime(2026, 10, 6, 9);
  final _minuteurs = <_FauxMinuteur>[];

  DateTime now() => maintenant;

  Timer armer(Duration delai, void Function() action) {
    final m = _FauxMinuteur(maintenant.add(delai), action);
    _minuteurs.add(m);
    return m;
  }

  /// Fait passer [duree], minuteur apres minuteur, a leur heure exacte.
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

/// Laisse s'achever les traitements en attente (aucune attente de duree).
Future<void> _laisserPasser([MeasureJournal? journal]) async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  if (journal != null) {
    await journal.idle;
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

Position _position(double lat, {double lon = 9, double precision = 4}) =>
    Position(
      latitude: lat,
      longitude: lon,
      altitude: 1000 + lat,
      accuracy: precision,
      altitudeAccuracy: 3,
      heading: 0,
      headingAccuracy: 0,
      speed: 1,
      speedAccuracy: 0,
      timestamp: DateTime(2026, 10, 6, 9),
    );

/// Un faux recepteur GPS qui compte ce qu'on lui demande.
class _FauxGps {
  _FauxGps(this.horloge);

  final _Horloge horloge;
  int fluxOuverts = 0;
  int souscriptionsVivantes = 0;
  final reglagesFlux = <LocationSettings>[];
  final reglagesTirs = <LocationSettings>[];
  final tirs = <Completer<Position>>[];
  StreamController<Position>? flux;

  Stream<Position> ouvrir({required LocationSettings locationSettings}) {
    fluxOuverts++;
    reglagesFlux.add(locationSettings);
    final c = StreamController<Position>(
      onListen: () => souscriptionsVivantes++,
      onCancel: () => souscriptionsVivantes--,
    );
    flux = c;
    return c.stream;
  }

  Future<Position> tirer(LocationSettings reglages) {
    reglagesTirs.add(reglages);
    final c = Completer<Position>();
    tirs.add(c);
    return c.future;
  }

  /// Rend la position du dernier tir apres [delai] de fausse horloge.
  Future<void> repondre(double lat, Duration delai) async {
    await horloge.avancer(delai);
    tirs.last.complete(_position(lat));
    await _laisserPasser();
  }
}

/// Un banc complet : horloge, GPS, journal sur disque, enregistreur, cadence.
class _Banc {
  _Banc(
    this.dossier, {
    Stream<int> Function()? pas,
    Future<bool> Function()? pasAutorises,
    int? batterie = 80,
    MeasureJournal? journal,
  }) {
    gps = _FauxGps(horloge);
    this.journal =
        journal ?? MeasureJournal(directory: () async => Directory(dossier));
    enregistreur = MeasureRecorder(
      journal: this.journal,
      readBattery: () async => batterieLue,
      stepCounts: pas,
      stepsAllowed: pasAutorises,
      schedule: horloge.armer,
      now: horloge.now,
    );
    batterieLue = batterie;
    cadence = BackgroundCadence(
      openStream: gps.ouvrir,
      takeShot: gps.tirer,
      distanceFilter: () => 12,
      onPosition: (position, {required via, required force}) async {
        recues.add((position, via));
        return true;
      },
      keepAliveDue: () => pointDeSecoursDu,
      onHeartbeat: () => battements++,
      observer: enregistreur,
      schedule: horloge.armer,
      now: horloge.now,
    );
  }

  final String dossier;
  final horloge = _Horloge();
  late final _FauxGps gps;
  late final MeasureJournal journal;
  late final MeasureRecorder enregistreur;
  late final BackgroundCadence cadence;
  int? batterieLue;
  bool pointDeSecoursDu = false;
  int battements = 0;
  final recues = <(Position, String)>[];

  Future<List<String>> lignes() async {
    await _laisserPasser(journal);
    final f = File('$dossier/$kMeasureJournalFileName');
    return f.existsSync() ? f.readAsLinesSync() : const <String>[];
  }

  Future<List<List<String>>> evenements(String mot) async => [
    for (final l in await lignes())
      if (l.split(';')[2] == mot) l.split(';'),
  ];
}

/// Les champs d'une ligne de compteurs, par nom.
Map<String, String> _compteurs(String ligne) => {
  for (final v in ligne.split(';').skip(3))
    v.substring(0, v.indexOf('=')): v.substring(v.indexOf('=') + 1),
};

void main() {
  late Directory bac;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('journal_de_mesure_671_');
  });

  tearDown(() {
    if (bac.existsSync()) bac.deleteSync(recursive: true);
  });

  final heure = DateTime(2026, 10, 6, 14, 5, 9);

  group('671-01 (1) — le format des lignes', () {
    test('chaque evenement ecrit a ce lot a neuf champs dans l ordre exact, '
        'un tiret a chaque champ sans objet', () {
      for (final evenement in [
        MeasureEvent.demarrage,
        MeasureEvent.reprise,
        MeasureEvent.arret,
        MeasureEvent.ecranOn,
        MeasureEvent.ecranOff,
        MeasureEvent.palierBatterie,
      ]) {
        final champs = MeasureLine.event(
          at: heure,
          profile: PositionProfile.batteryFirst,
          event: evenement,
          batteryPercent: 76,
        ).split(';');
        expect(champs, hasLength(kMeasureEventFieldCount));
        expect(champs, [
          '2026-10-06T14:05:09',
          'batterieDabord',
          evenement.word,
          '76',
          '-',
          '-',
          '-',
          '-',
          '-',
        ]);
      }
    });

    test('une ligne releve porte la position a six decimales, la precision, '
        'le champ 8 (un tiret a ce lot) et le temps du premier point', () {
      final champs = MeasureLine.event(
        at: heure,
        profile: PositionProfile.map,
        event: MeasureEvent.releve,
        batteryPercent: 81,
        steps: 42,
        latitude: 42.1234567,
        longitude: 9.7654321,
        accuracyMeters: 4.25,
        timeToFix: const Duration(milliseconds: 3460),
      ).split(';');
      expect(champs, [
        '2026-10-06T14:05:09',
        'carte',
        'releve',
        '81',
        '42',
        '42.123457,9.765432',
        '4.3',
        '-',
        '3.5',
      ]);
    });

    test('un tir expire donne un releve sans position ni precision, et le '
        'delai maximum au champ 9', () {
      final champs = MeasureLine.event(
        at: heure,
        profile: PositionProfile.batteryFirst,
        event: MeasureEvent.releve,
        batteryPercent: 70,
        timeToFix: kSingleShotMaxDelay,
      ).split(';');
      expect(champs, hasLength(9));
      expect(champs.sublist(5), ['-', '-', '-', '15.0']);
    });

    test('la ligne de compteurs a ses neuf valeurs nommees dans l ordre fixe, '
        'redemarrages et attente d acquisition a la fin', () {
      final ligne = MeasureLine.counters(
        at: heure,
        profile: PositionProfile.lowBattery,
        batteryPercent: 64,
        acquisitions: 3,
        steps: null,
        distanceMeters: null,
        restarts: 4,
        acquisitionWait: const Duration(milliseconds: 26500),
      );
      expect(
        ligne,
        '2026-10-06T14:05:09;batterieBasse;compteurs;batterie=64;'
        'acquisitions=3;pas=-;distance_m=-;redemarrages=4;'
        'attente_acquisition_s=26.5',
      );
    });
  });

  group('671-01 (2) — le vocabulaire est une liste fermee', () {
    test('les onze mots de la fiche, et pas un de plus', () {
      expect(MeasureEvent.values.map((e) => e.word), [
        'demarrage',
        'releve',
        'estime',
        'arret',
        'reprise',
        'charniere',
        'sos',
        'hors-trace',
        'ecran-on',
        'ecran-off',
        'palier-batterie',
      ]);
      for (final e in MeasureEvent.values) {
        expect(MeasureEvent.fromWord(e.word), e);
      }
    });

    test('un evenement hors de la liste est refuse', () {
      for (final intrus in [
        'derive',
        'compteurs',
        'Releve',
        '',
        'hors trace',
      ]) {
        expect(
          () => MeasureEvent.fromWord(intrus),
          throwsArgumentError,
          reason: '« $intrus » n est pas un evenement du journal',
        );
      }
    });
  });

  group('671-01 (3) — les trois cadences, une seule definition', () {
    test('carte : flux continu, precision haute, filtre de 10 m (celui du '
        'robinet unique du lot 671-00)', () {
      final c = GpsCadence.of(PositionProfile.map);
      expect(c.mode, GpsCaptureMode.stream);
      expect(c.precision, GpsPrecision.high);
      expect(c.distanceFilterMeters, 10);
      expect(c.period, isNull);
      expect(locationAccuracyOf(c.precision), LocationAccuracy.high);
    });

    test('batterie d abord : tir unique, precision haute, 15 s au plus, un '
        'tir toutes les 3 minutes', () {
      final c = GpsCadence.of(PositionProfile.batteryFirst);
      expect(c.mode, GpsCaptureMode.singleShot);
      expect(c.precision, GpsPrecision.high);
      expect(c.maxDelay, const Duration(seconds: 15));
      expect(c.period, const Duration(minutes: 3));
    });

    test('batterie basse : tir unique, 15 s au plus, un tir toutes les 15 '
        'minutes', () {
      final c = GpsCadence.of(PositionProfile.lowBattery);
      expect(c.mode, GpsCaptureMode.singleShot);
      expect(c.maxDelay, const Duration(seconds: 15));
      expect(c.period, const Duration(minutes: 15));
    });

    test('un profil inconnu ou absent des preferences vaut carte', () {
      for (final range in [null, '', 'turbo', 'batterieDabord']) {
        expect(
          GpsCadence.of(PositionProfile.fromStored(range)),
          same(GpsCadence.map),
          reason: 'valeur rangee : $range',
        );
      }
    });

    test('la sonde de vie et le battement suivent la cadence : 20 s et 30 s '
        'en flux, periode + delai + marge en tir', () {
      expect(GpsCadence.map.watchdogPeriod, const Duration(seconds: 20));
      expect(GpsCadence.map.heartbeatPeriod, const Duration(seconds: 30));
      expect(
        GpsCadence.batteryFirst.normalSilence,
        const Duration(minutes: 3, seconds: 15) + kSingleShotSilenceMargin,
      );
      expect(
        GpsCadence.lowBattery.watchdogPeriod,
        const Duration(minutes: 15, seconds: 15) + kSingleShotSilenceMargin,
      );
    });
  });

  group('671-01 (4) — le tir unique relache le recepteur', () {
    test('entre deux tirs il n existe AUCUNE souscription vivante', () async {
      final b = _Banc(bac.path);
      await b.cadence.start(PositionProfile.batteryFirst);
      await _laisserPasser();
      expect(b.gps.tirs, hasLength(1), reason: 'un tir des le demarrage');

      for (var tir = 1; tir <= 3; tir++) {
        await b.gps.repondre(42 + tir / 1000, const Duration(seconds: 6));
        // Entre deux tirs : ni flux ouvert, ni souscription vivante.
        expect(b.gps.fluxOuverts, 0, reason: 'un flux a ete ouvert en tir');
        expect(b.gps.souscriptionsVivantes, 0);
        expect(b.cadence.engine.hasLiveSubscription, isFalse);
        await b.horloge.avancer(const Duration(minutes: 3, seconds: -6));
        expect(b.gps.tirs, hasLength(tir + 1));
      }
      expect(b.gps.reglagesTirs.first.accuracy, LocationAccuracy.high);
      expect(b.gps.reglagesTirs.first.timeLimit, kSingleShotMaxDelay);
      await b.cadence.stop();
    });

    test('le controleur de l interface relache aussi le recepteur entre deux '
        'tirs, et ses abonnes recoivent chaque tir', () async {
      final horloge = _Horloge();
      final gps = _FauxGps(horloge);
      final controleur = PositionController(
        positionStream: gps.ouvrir,
        currentPosition: ({required locationSettings}) =>
            gps.tirer(locationSettings),
        schedule: horloge.armer,
        now: horloge.now,
      );
      await controleur.setProfile(PositionProfile.batteryFirst);
      final recues = <double>[];
      final abonne = controleur.positions.listen((p) => recues.add(p.latitude));
      await _laisserPasser();

      await gps.repondre(43.1, const Duration(seconds: 2));
      expect(gps.fluxOuverts, 0);
      expect(controleur.hasLiveSubscription, isFalse);
      await horloge.avancer(const Duration(minutes: 3));
      await gps.repondre(43.2, const Duration(seconds: 2));
      expect(recues, [43.1, 43.2]);
      expect(gps.souscriptionsVivantes, 0);
      await abonne.cancel();
    });

    test('un tir sans reponse au bout de 15 s ecrit un releve sans position '
        'avec 15 au champ 9, puis rien avant la periode suivante', () async {
      final b = _Banc(bac.path);
      await b.cadence.start(PositionProfile.batteryFirst);
      await b.horloge.avancer(const Duration(seconds: 15));

      final releves = await b.evenements('releve');
      expect(releves, hasLength(1));
      expect(releves.single.sublist(5), ['-', '-', '-', '15.0']);

      // Ni rafale, ni nouvel essai : le tir suivant vient a 3 min pile.
      await b.horloge.avancer(const Duration(minutes: 2, seconds: 44));
      expect(b.gps.tirs, hasLength(1));
      await b.horloge.avancer(const Duration(seconds: 1));
      expect(b.gps.tirs, hasLength(2));

      // Une reponse tardive au tir expire n'est pas journalisee.
      b.gps.tirs.first.complete(_position(44));
      expect(await b.evenements('releve'), hasLength(1));
      expect(b.recues, isEmpty);
      await b.cadence.stop();
    });

    test('la sonde de vie ne relance JAMAIS de flux en tir unique, meme '
        'quand le point de secours serait du', () async {
      final b = _Banc(bac.path)..pointDeSecoursDu = true;
      await b.cadence.start(PositionProfile.batteryFirst);
      await b.horloge.avancer(const Duration(hours: 1));

      expect(b.gps.fluxOuverts, 0);
      expect(b.gps.souscriptionsVivantes, 0);
      // Un tir toutes les 3 min pendant une heure, et pas un de plus : pas de
      // point de secours en tir unique.
      expect(b.gps.tirs, hasLength(21));
      await b.cadence.stop();
    });

    test('si le rythme se perd, la sonde de vie le relance par un TIR, '
        'jamais par un flux', () async {
      final b = _Banc(bac.path);
      await b.cadence.start(PositionProfile.batteryFirst);
      await b.gps.repondre(42, const Duration(seconds: 3));
      // Le minuteur des tirs est perdu (le systeme l'a tue).
      for (final m in b.horloge._minuteurs) {
        if (m.echeance == DateTime(2026, 10, 6, 9, 3)) m.cancel();
      }
      await b.horloge.avancer(const Duration(minutes: 8));
      expect(b.gps.fluxOuverts, 0);
      expect(b.gps.tirs.length, greaterThanOrEqualTo(2));
      await b.cadence.stop();
    });
  });

  group('671-01 (5) — changer de profil en cours de route', () {
    test('de la carte au tir : le flux est annule proprement, une ligne '
        'reprise porte le NOUVEAU profil, et rien ne redemarre', () async {
      final b = _Banc(bac.path);
      await b.cadence.start(PositionProfile.map);
      await _laisserPasser();
      expect(b.gps.fluxOuverts, 1);
      expect(b.gps.souscriptionsVivantes, 1);

      await b.cadence.switchProfile(PositionProfile.batteryFirst);
      await _laisserPasser();
      expect(b.gps.souscriptionsVivantes, 0, reason: 'le flux vit encore');
      expect(b.gps.tirs, hasLength(1));
      expect(b.cadence.isRunning, isTrue);

      final reprises = await b.evenements('reprise');
      expect(reprises, hasLength(1));
      expect(reprises.single[1], 'batterieDabord');
      expect(await b.evenements('demarrage'), hasLength(1));
      await b.cadence.stop();
    });

    test('du tir a la carte : le tir en vol est abandonne et un seul flux '
        's ouvre', () async {
      final b = _Banc(bac.path);
      await b.cadence.start(PositionProfile.lowBattery);
      await b.cadence.switchProfile(PositionProfile.map);
      b.gps.tirs.single.complete(_position(42));
      await _laisserPasser();
      expect(b.recues, isEmpty, reason: 'le tir abandonne a ete transmis');
      expect(b.gps.fluxOuverts, 1);
      expect((await b.evenements('reprise')).single[1], 'carte');
      await b.cadence.stop();
    });

    test('le controleur de l interface change de cadence sans couper ses '
        'abonnes', () async {
      final horloge = _Horloge();
      final gps = _FauxGps(horloge);
      final controleur = PositionController(
        positionStream: gps.ouvrir,
        currentPosition: ({required locationSettings}) =>
            gps.tirer(locationSettings),
        schedule: horloge.armer,
        now: horloge.now,
      );
      var fini = false;
      final abonne = controleur.positions.listen(
        (_) {},
        onDone: () => fini = true,
      );
      await _laisserPasser();
      expect(gps.souscriptionsVivantes, 1);
      await controleur.setProfile(PositionProfile.batteryFirst);
      await _laisserPasser();
      expect(gps.souscriptionsVivantes, 0);
      expect(gps.tirs, hasLength(1));
      expect(fini, isFalse);
      await abonne.cancel();
    });
  });

  group('671-01 (6) — l ecriture du journal', () {
    test('deux isolates ajoutent deux cents lignes chacun en meme temps : le '
        'fichier contient quatre cents lignes entieres', () async {
      final dossier = bac.path;
      await Future.wait([
        Isolate.run(() => _ecrireDeuxCents(dossier, 'A')),
        Isolate.run(() => _ecrireDeuxCents(dossier, 'B')),
      ]);
      final lignes = File(
        '$dossier/$kMeasureJournalFileName',
      ).readAsLinesSync();
      final entieres = RegExp(r'^[AB];\d{3};x{60}$');
      expect(lignes, hasLength(400), reason: 'lignes perdues ou en trop');
      expect(
        lignes.where(entieres.hasMatch),
        hasLength(400),
        reason: 'lignes melangees ou coupees',
      );
      for (final ecrivain in ['A', 'B']) {
        expect(lignes.where((l) => l.startsWith('$ecrivain;')), hasLength(200));
      }
    });

    test('une erreur d ecriture ne fait jamais echouer le suivi : elle est '
        'avalee et comptee', () async {
      // Un dossier ou rien ne s'ecrit, quel que soit l'utilisateur : son
      // chemin passe par un FICHIER. Un dossier en lecture seule ne suffirait
      // pas sous un compte administrateur, qui ignore ce droit.
      final bloque = File('${bac.path}/pas_un_dossier')..writeAsStringSync('');
      final journal = MeasureJournal(
        directory: () async => Directory('${bloque.path}/journal'),
      );
      final b = _Banc(bac.path, journal: journal);
      await b.cadence.start(PositionProfile.batteryFirst);
      await b.gps.repondre(42.5, const Duration(seconds: 2));
      await _laisserPasser(journal);

      expect(b.recues, hasLength(1), reason: 'le suivi n a plus recu le point');
      expect(b.cadence.isRunning, isTrue);
      expect(journal.failedWrites, greaterThanOrEqualTo(2));
      await expectLater(journal.append('encore'), completes);
      await b.cadence.stop();
    });
  });

  group('671-01 (7) — les deux ajouts de plateforme', () {
    test('le manifeste Android declare ACTIVITY_RECOGNITION', () {
      final manifeste = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        RegExp(
          r'<uses-permission\s+android:name="android\.permission\.'
          r'ACTIVITY_RECOGNITION"\s*/>',
        ).hasMatch(manifeste),
        isTrue,
        reason:
            'sans la permission ACTIVITY_RECOGNITION, le flux de pas ne peut '
            'pas demarrer sur Android 10 et au-dela : le journal de mesure '
            'perdrait ses pas',
      );
    });

    test(
      'l Info.plist iOS porte NSMotionUsageDescription, avec une phrase',
      () {
        final plist = File('ios/Runner/Info.plist').readAsStringSync();
        final m = RegExp(
          r'<key>NSMotionUsageDescription</key>\s*<string>([^<]+)</string>',
        ).firstMatch(plist);
        expect(
          m,
          isNotNull,
          reason: 'sans NSMotionUsageDescription, iOS refuse le podometre',
        );
        expect(m!.group(1)!.trim(), isNotEmpty);
      },
    );
  });

  group('671-01 (8) — les pas bruts ne servent qu au journal', () {
    test('avec et sans flux de pas, les positions et les statistiques du '
        'suivi sont strictement identiques', () async {
      Future<(List<String>, TrackingEngine)> marche(
        String sousDossier, {
        required bool avecPas,
      }) async {
        final dossier = Directory('${bac.path}/$sousDossier')..createSync();
        final pas = StreamController<int>();
        final b = _Banc(
          dossier.path,
          pas: avecPas ? () => pas.stream : null,
          pasAutorises: () async => avecPas,
        );
        final moteur = TrackingEngine();
        await b.cadence.start(PositionProfile.batteryFirst);
        for (var i = 0; i < 4; i++) {
          if (avecPas) pas.add(5000 + i * 300);
          await b.gps.repondre(42 + i / 500, const Duration(seconds: 5));
          await b.horloge.avancer(const Duration(minutes: 2, seconds: 55));
        }
        for (final (p, _) in b.recues) {
          moteur.addPosition(
            p.latitude,
            p.longitude,
            p.altitude,
            timestamp: DateTime(2026, 10, 6, 9),
          );
        }
        await b.cadence.stop();
        unawaited(pas.close());
        return (
          [
            for (final (p, via) in b.recues)
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
      expect(statsAvec.pointCount, statsSans.pointCount);
    });

    test('avec autorisation, le champ pas compte depuis le demarrage du '
        'suivi, pas depuis celui du telephone', () async {
      final pas = StreamController<int>();
      final b = _Banc(
        bac.path,
        pas: () => pas.stream,
        pasAutorises: () async => true,
      );
      await b.cadence.start(PositionProfile.batteryFirst);
      pas
        ..add(12000)
        ..add(12042);
      await b.gps.repondre(42, const Duration(seconds: 4));
      expect((await b.evenements('releve')).single[4], '42');
      await b.enregistreur.writeCounters();
      expect(_compteurs((await b.lignes()).last)['pas'], '42');
      await b.cadence.stop();
      unawaited(pas.close());
    });

    test('sans autorisation, le flux de pas ne demarre pas et le champ pas '
        'vaut un tiret, rien d autre ne change', () async {
      var ouvertures = 0;
      final b = _Banc(
        bac.path,
        pas: () {
          ouvertures++;
          return const Stream<int>.empty();
        },
        pasAutorises: () async => false,
      );
      await b.cadence.start(PositionProfile.batteryFirst);
      await b.gps.repondre(42, const Duration(seconds: 4));
      await b.enregistreur.writeCounters();
      expect(ouvertures, 0);
      expect((await b.evenements('demarrage')).single[4], '-');
      expect((await b.evenements('releve')).single[4], '-');
      expect(_compteurs((await b.lignes()).last)['pas'], '-');
      expect(b.recues, hasLength(1));
      await b.cadence.stop();
    });
  });

  group('671-01 (10) — ni reseau ni Firebase dans les fichiers neufs', () {
    const fichiersNeufs = [
      'lib/core/services/journal_de_mesure.dart',
      'lib/features/settings/presentation/mesure_batterie_screen.dart',
    ];
    final importsInterdits = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]*(?:firebase|firestore|'''
      r'''cloud_|package:http|package:dio|connectivity|url_launcher|'''
      r'''web_socket|/network/|google_mobile_ads)[^'"]*)['"]''',
      multiLine: true,
    );

    List<String> fautifs(String source) => [
      for (final m in importsInterdits.allMatches(source)) m.group(1)!,
    ];

    test('les deux fichiers neufs n importent ni reseau ni Firebase', () {
      for (final chemin in fichiersNeufs) {
        final interdits = fautifs(File(chemin).readAsStringSync());
        expect(
          interdits,
          isEmpty,
          reason: '$chemin importe un acces reseau ou Firebase : $interdits',
        );
      }
    });

    test('LA GARDE VOIT VRAIMENT : un import interdit est reconnu', () {
      expect(
        fautifs(
          "import 'package:firebase_core/firebase_core.dart';\n"
          "import 'package:http/http.dart' as http;\n"
          "import '../../core/network/api.dart';\n"
          "import 'dart:io';\n",
        ),
        hasLength(3),
      );
    });
  });

  group('671-01 (11) — redemarrages et attente d acquisition', () {
    test(
      'trois tirs en batterie d abord : redemarrages=3, et l attente est '
      'la somme des trois temps du premier point, tir expire compris',
      () async {
        final b = _Banc(bac.path);
        await b.cadence.start(PositionProfile.batteryFirst);
        await b.gps.repondre(42.1, const Duration(seconds: 4));
        await b.horloge.avancer(const Duration(minutes: 2, seconds: 56));
        await b.gps.repondre(42.2, const Duration(milliseconds: 7500));
        await b.horloge.avancer(
          const Duration(minutes: 2, seconds: 52, milliseconds: 500),
        );
        // Troisieme tir : pas de reponse, il expire a 15 s.
        await b.horloge.avancer(const Duration(seconds: 15));
        await b.enregistreur.writeCounters();

        final compteurs = _compteurs((await b.lignes()).last);
        expect(compteurs['redemarrages'], '3');
        expect(compteurs['acquisitions'], '2');
        expect(compteurs['attente_acquisition_s'], '26.5');
        final temps = [for (final r in await b.evenements('releve')) r[8]];
        expect(temps, ['4.0', '7.5', '15.0']);
        await b.cadence.stop();
      },
    );

    test(
      'en carte, un seul flux ouvert sur la fenetre : redemarrages=1, et '
      'le temps du premier point n est porte que par le premier releve',
      () async {
        final b = _Banc(bac.path);
        await b.cadence.start(PositionProfile.map);
        await b.horloge.avancer(const Duration(seconds: 2));
        for (var i = 0; i < 3; i++) {
          b.gps.flux!.add(_position(42 + i / 1000));
          await _laisserPasser();
          await b.horloge.avancer(const Duration(seconds: 7));
        }
        await b.horloge.avancer(const Duration(minutes: 10));

        final compteurs = [
          for (final l in await b.lignes())
            if (l.split(';')[2] == kMeasureCountersWord) _compteurs(l),
        ];
        expect(compteurs, isNotEmpty, reason: 'aucune ligne de compteurs');
        expect(compteurs.first['redemarrages'], '1');
        expect(compteurs.first['acquisitions'], '3');
        expect(compteurs.first['attente_acquisition_s'], '2.0');
        expect(
          [for (final r in await b.evenements('releve')) r[8]],
          ['2.0', '-', '-'],
        );
        expect(b.gps.fluxOuverts, 1);
        await b.cadence.stop();
      },
    );

    test('un palier de batterie tombe a chaque baisse de cinq points, lu a '
        'chaque releve', () async {
      final b = _Banc(bac.path, batterie: 80);
      await b.cadence.start(PositionProfile.batteryFirst);
      b.batterieLue = 77;
      await b.gps.repondre(42, const Duration(seconds: 3));
      expect(await b.evenements('palier-batterie'), isEmpty);
      b.batterieLue = 75;
      await b.horloge.avancer(const Duration(minutes: 3));
      await b.gps.repondre(42.1, const Duration(seconds: 3));
      final paliers = await b.evenements('palier-batterie');
      expect(paliers, hasLength(1));
      expect(paliers.single[3], '75');
      await b.cadence.stop();
      expect(await b.evenements('arret'), hasLength(1));
    });
  });

  group('671-01 — ecran-on et ecran-off', () {
    test('le cycle de vie donne ecran-on au retour, ecran-off au depart, et '
        'rien pour les etats de passage', () async {
      final journal = MeasureJournal(directory: () async => bac);
      final r = ScreenStateRecorder(
        journal: journal,
        readProfile: () async => PositionProfile.lowBattery,
        readBattery: () async => 55,
        now: () => heure,
      );
      for (final etat in AppLifecycleState.values) {
        await r.record(etat);
      }
      final lignes = File(
        '${bac.path}/$kMeasureJournalFileName',
      ).readAsLinesSync();
      expect(lignes, [
        '2026-10-06T14:05:09;batterieBasse;ecran-on;55;-;-;-;-;-',
        '2026-10-06T14:05:09;batterieBasse;ecran-off;55;-;-;-;-;-',
      ]);
    });
  });
}

/// Un ecrivain du banc de concurrence : deux cents lignes, une par ajout.
Future<void> _ecrireDeuxCents(String dossier, String ecrivain) async {
  final journal = MeasureJournal(directory: () async => Directory(dossier));
  for (var i = 0; i < 200; i++) {
    await journal.append(
      '$ecrivain;${i.toString().padLeft(3, '0')};${'x' * 60}',
    );
  }
  if (journal.failedWrites > 0) {
    throw StateError('$ecrivain : ${journal.failedWrites} lignes perdues');
  }
}
