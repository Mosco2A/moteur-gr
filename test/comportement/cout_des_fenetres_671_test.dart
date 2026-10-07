import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/charnieres_du_trace.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

import 'banc_des_reveils_671.dart';
import 'traces_fabriquees_671.dart';

/// LOT 671-04 — LE COUT DES FENETRES, CHIFFRE PAR SIMULATION. C'EST LE CHIFFRE
/// D'ACCEPTATION DU LOT : IL REMPLACE LA MARCHE QUE PERSONNE NE FERA.
///
/// LE BANC. Deux traces, une traversee complete chacun, a 4 km/h, en profil
/// batterie d'abord, sur la VRAIE chaine de l'isolate de fond et une fausse
/// horloge ([traverser]) : une fois AVEC les charnieres passees par le canal,
/// une fois SANS (la seule cadence de 3 minutes). On compte les TIRS, c'est a
/// dire les reveils du recepteur ; le journal les compte aussi
/// (`acquisitions`).
///
/// CE QUE CE BANC N'AFFIRME PAS : AUCUN POURCENTAGE DE BATTERIE. Un banc de
/// test ne consomme pas de recepteur GPS. Il chiffre le MECANISME — le nombre
/// de reveils — et rien d'autre.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// LE TRACE FABRIQUE, sa geometrie au metre : 2 000 m droits vers l'est
  /// (deux points dupliques dedans), un lacet de cinq epingles a 80 m (des
  /// virages de 120 degres), 1 000 m dans l'axe de la derniere branche, un
  /// virage isole de 70 degres, 1 500 m.
  List<TrackPoint> traceFabrique() {
    final epingles = lacet(2000, 0);
    final (x, y) = epingles.last;
    final pli = auCap(x, y, 300, 1000);
    final plan = decouper([
      (0, 0),
      (2000, 0),
      ...epingles,
      pli,
      auCap(pli.$1, pli.$2, 10, 1500),
    ]);
    return traceDesPoints([
      ...plan.sublist(0, 50),
      plan[49],
      ...plan.sublist(50, 120),
      plan[119],
      ...plan.sublist(120),
    ]);
  }

  /// Une ligne du tableau de la fiche E5, imprimee et rendue.
  Future<Map<String, Object>> ligneDuTableau(
    String nom,
    List<TrackPoint> trace,
  ) async {
    final chrono = Stopwatch()..start();
    final charnieres = charnieresDuTrace(trace);
    chrono.stop();
    final longueur = trace.last.distanceFromStart;
    final fenetres = fenetresDesCharnieres(charnieres, longueurM: longueur);
    final sous = fenetres.fold<double>(0, (s, f) => s + f.largeurM);
    final avec = await traverser(trace, charnieres: charnieres);
    final sans = await traverser(trace, charnieres: const []);
    // LE RECOUVREMENT : les tirs periodiques (sans fenetre) qui tombent
    // DANS une fenetre, et que les tirs de fenetre remplacent.
    final remplaces = sans.abscissesDesTirs
        .where((d) => fenetres.any((f) => d >= f.debutM && d <= f.finM))
        .length;
    final ligne = <String, Object>{
      'trace': nom,
      'points': trace.length,
      'longueur_m': longueur.round(),
      'charnieres': charnieres.length,
      'fenetres_avant_fusion': charnieres.length,
      'fenetres_apres_fusion': fenetres.length,
      'metres_sous_fenetre': sous.round(),
      'pct_sous_fenetre': (100 * sous / longueur).toStringAsFixed(2),
      'tirs_avec_fenetres': avec.tirs,
      'tirs_sans_fenetres': sans.tirs,
      'rapport': (avec.tirs / sans.tirs).toStringAsFixed(2),
      'tirs_periodiques_remplaces': remplaces,
      'acquisitions_avec': avec.acquisitions,
      'lignes_charniere': avec.lignes
          .where((l) => l.split(';')[2] == 'charniere')
          .length,
      'calcul_charnieres_us': chrono.elapsedMicroseconds,
    };
    // ignore: avoid_print
    print('COUT E5 $ligne');
    expect(avec.acquisitions, avec.tirs);
    expect(sans.acquisitions, sans.tirs);
    return ligne;
  }

  test('LE TRACE FABRIQUE : six charnieres, deux fenetres apres fusion, et '
      'le cout d une traversee complete', () async {
    final trace = traceFabrique();
    final doublons = [
      for (var i = 1; i < trace.length; i++)
        if (trace[i].distanceFromStart == trace[i - 1].distanceFromStart) i,
    ];
    expect(doublons, hasLength(2));
    // La longueur connue au metre : 2 000 + 6 x 80 + 1 000 + 1 500 m dans
    // le plan local, 0,1 % de moins en Haversine.
    expect(trace.last.distanceFromStart, closeTo(4980, 6));
    final l = await ligneDuTableau('fabrique', trace);
    expect(l['charnieres'], 6);
    expect(l['fenetres_apres_fusion'], 2);
    // 620 m pour le lacet, 300 m pour le virage isole.
    expect(l['metres_sous_fenetre'] as int, closeTo(920, 2));
    // 4 980 m a 4 km/h = 74 min 42 s : 25 tirs a 3 minutes.
    expect(l['tirs_sans_fenetres'], 25);
    // 920 m sous fenetre, soit 828 s, a 30 s : une trentaine de tirs de
    // fenetre, moins les tirs periodiques qu'ils remplacent.
    expect(l['tirs_avec_fenetres'] as int, inInclusiveRange(45, 55));
    expect(l['lignes_charniere'], 2);
  });

  test('LE SENTIER DE REFERENCE DU DEPOT (Mare a Mare Centre) : le chiffre '
      'sur un vrai sentier', () async {
    final trace = GpxParser.parse(
      File('assets/data/mare_a_mare_centre/track.gpx').readAsStringSync(),
    ).allTrackPoints;
    final l = await ligneDuTableau('Mare a Mare Centre', trace);
    expect(l['points'], 53);
    expect(l['charnieres'], 2);
    expect(l['fenetres_apres_fusion'], 2);
    expect(double.parse(l['pct_sous_fenetre']! as String), lessThan(10));
    // 72,9 km a 4 km/h : 18 h 13, 365 tirs a 3 minutes.
    expect(l['tirs_sans_fenetres'], 365);
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('l arithmetique de la fiche : 300 m a 4 km/h se traversent en '
      '4 min 30, neuf tirs a 30 s contre un et demi a 3 minutes', () {
    const secondes =
        (kFenetreAvantMetres + kFenetreApresMetres) / vitesseDuBanc;
    final traversee = Duration(milliseconds: (secondes * 1000).round());
    expect(traversee, const Duration(minutes: 4, seconds: 30));
    expect(traversee.inSeconds / kPeriodeDansLaFenetre.inSeconds, 9);
    expect(traversee.inSeconds / kBatteryFirstShotPeriod.inSeconds, 1.5);
  });
}
