import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/geo/charnieres_du_trace.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/trek/data/background_cadence.dart';
import 'package:moteur_gr/features/trek/data/estime_de_fond.dart';
import 'package:moteur_gr/features/trek/data/measure_recorder.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';

/// LOT 671-04 — LE BANC DES REVEILS : UNE TRAVERSEE SIMULEE, SANS CAPTEUR.
///
/// C'est la VRAIE chaine de l'isolate de fond — le moteur des cadences
/// ([BackgroundCadence]), l'enregistreur du journal ([MeasureRecorder]),
/// l'estime sur le trace ([BackgroundEstimate]) et le canal du trace
/// ([encodeBackgroundTrace]) — branchee comme dans `_onServiceStart`, sur :
/// - une FAUSSE HORLOGE, dont les minuteurs partent a leur heure exacte ;
/// - un FAUX FOURNISSEUR DE POSITION qui rend, a l'heure du tir, la position
///   REELLEMENT atteinte par un marcheur a vitesse constante (interpolee ici,
///   sans le code teste) et compte chaque tir ;
/// - un FAUX FLUX DE PAS, un paquet toutes les 10 secondes, a 0,75 m le pas
///   (la longueur de depart du lot 671-02, que le code croit aussi).
/// Aucun capteur, aucun temps reel, aucune mise en sommeil.

/// Un minuteur de la fausse horloge.
class FauxMinuteur implements Timer {
  /// Un minuteur qui part a [echeance].
  FauxMinuteur(this.echeance, this.action);

  /// L'heure ou il part.
  final DateTime echeance;

  /// Ce qu'il fait.
  final void Function() action;

  /// Faux une fois parti ou annule.
  bool actif = true;

  @override
  void cancel() => actif = false;

  @override
  bool get isActive => actif;

  @override
  int get tick => 0;
}

/// Une horloge qu'on avance a la main, et ses minuteurs.
class FausseHorloge {
  /// L'heure courante.
  DateTime maintenant = DateTime(2026, 10, 7, 8);
  final _minuteurs = <FauxMinuteur>[];

  /// L'heure courante (la signature de `DateTime.now`).
  DateTime now() => maintenant;

  /// Arme un minuteur (la signature de `Timer.new`).
  Timer armer(Duration delai, void Function() action) {
    final m = FauxMinuteur(maintenant.add(delai), action);
    _minuteurs.add(m);
    return m;
  }

  /// Fait passer [duree], minuteur apres minuteur, a leur heure exacte.
  Future<void> avancer(Duration duree) async {
    final fin = maintenant.add(duree);
    while (true) {
      FauxMinuteur? prochain;
      for (final m in _minuteurs) {
        if (!m.actif || m.echeance.isAfter(fin)) continue;
        if (prochain == null || m.echeance.isBefore(prochain.echeance)) {
          prochain = m;
        }
      }
      if (prochain == null) break;
      prochain.actif = false;
      maintenant = prochain.echeance;
      prochain.action();
      await laisserPasser();
    }
    _minuteurs.removeWhere((m) => !m.actif);
    maintenant = fin;
    await laisserPasser();
  }
}

/// Laisse s'achever les traitements en attente, sans attente de duree.
Future<void> laisserPasser() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

/// Le point du trace a [d] m du depart, interpole ICI, sans le code teste.
({double lat, double lng}) pointAtteint(List<TrackPoint> trace, double d) {
  var i = 0;
  while (i < trace.length - 2 && trace[i + 1].distanceFromStart <= d) {
    i++;
  }
  final a = trace[i];
  final b = trace[i + 1];
  final l = b.distanceFromStart - a.distanceFromStart;
  final f = l <= 0 ? 0.0 : ((d - a.distanceFromStart) / l).clamp(0.0, 1.0);
  return (lat: a.lat + (b.lat - a.lat) * f, lng: a.lng + (b.lng - a.lng) * f);
}

/// Ce qu'une traversee complete a coute.
typedef Traversee = ({
  int tirs,
  int acquisitions,
  List<double> abscissesDesTirs,
  List<Duration> heuresDesTirs,
  List<String> lignes,
  List<FenetreDeCharniere> fenetres,
});

/// LA VITESSE DE MARCHE DU BANC : 4 km/h, soit 200 m par intervalle de 3 min.
const double vitesseDuBanc = 4000 / 3600;

/// Fait traverser [trace] de bout en bout, en profil batterie d'abord, avec
/// les [charnieres] passees a l'isolate de fond par le canal du trace (aucune
/// : la seule cadence de 3 minutes).
Future<Traversee> traverser(
  List<TrackPoint> trace, {
  required List<Charniere> charnieres,
}) async {
  final dossier = await Directory.systemTemp.createTemp('reveils_671_');
  final journal = MeasureJournal(directory: () async => dossier);
  final horloge = FausseHorloge();
  final depart = horloge.maintenant;
  final longueur = trace.last.distanceFromStart;
  const pas = 0.75;
  const pasAuDepart = 10000;
  double parcouru() =>
      (horloge.maintenant.difference(depart).inMilliseconds /
              1000 *
              vitesseDuBanc)
          .clamp(0.0, longueur);
  int pasA(double d) => pasAuDepart + (d / pas + 1e-9).floor();

  final abscisses = <double>[];
  final heures = <Duration>[];
  // Le podometre livre aussi un paquet AU MOMENT du tir : sans cela, le
  // releve serait recale sur le compte de pas du paquet precedent, en retard
  // de 10 s (11 m), et le banc mesurerait son propre decalage.
  late final StreamController<int> flux;
  flux = StreamController<int>(
    sync: true,
    onListen: () => flux.add(pasA(parcouru())),
  );
  final brut = encodeBackgroundTrace((
    trailId: 'banc',
    points: trace,
    direction: WalkDirection.increasing,
  ), charnieres: charnieres);
  late final BackgroundCadence cadence;
  final estime = BackgroundEstimate(
    readTrace: () async => brut,
    trailId: () => 'banc',
    keepDistanceMeters: () => 12,
    requestFix: () => cadence.engine.rearm(),
    onWindow: (periode) => periode == null
        ? cadence.engine.relax()
        : cadence.engine.accelerate(periode),
  );
  final enregistreur = MeasureRecorder(
    journal: journal,
    readBattery: () async => 80,
    stepCounts: () => flux.stream,
    stepsAllowed: () async => true,
    sessionId: () => 'banc',
    estimate: estime,
    schedule: horloge.armer,
    now: horloge.now,
  );
  cadence = BackgroundCadence(
    openStream: ({required locationSettings}) =>
        throw StateError('aucun flux en profil batterie d abord'),
    takeShot: (_) {
      final d = parcouru();
      flux.add(pasA(d));
      abscisses.add(d);
      heures.add(horloge.maintenant.difference(depart));
      final p = pointAtteint(trace, d);
      return Future.value(
        Position(
          latitude: p.lat,
          longitude: p.lng,
          timestamp: horloge.maintenant,
          accuracy: 4,
          altitude: 0,
          altitudeAccuracy: 3,
          heading: 0,
          headingAccuracy: 0,
          speed: vitesseDuBanc,
          speedAccuracy: 0.5,
        ),
      );
    },
    distanceFilter: () => 12,
    onPosition: (_, {required via, required force}) async => true,
    keepAliveDue: () => false,
    onHeartbeat: () {},
    observer: enregistreur,
    schedule: horloge.armer,
    now: horloge.now,
  );

  await cadence.start(PositionProfile.batteryFirst);
  await laisserPasser();
  while (parcouru() < longueur) {
    await horloge.avancer(const Duration(seconds: 10));
    flux.add(pasA(parcouru()));
    await laisserPasser();
  }
  await cadence.stop();
  await flux.close();
  await journal.idle;
  final lignes = (await (await journal.file()).readAsLines())
      .where((l) => l.isNotEmpty)
      .toList();
  await dossier.delete(recursive: true);
  return (
    tirs: abscisses.length,
    acquisitions: enregistreur.acquisitions,
    abscissesDesTirs: abscisses,
    heuresDesTirs: heures,
    lignes: lignes,
    fenetres: estime.windows,
  );
}
