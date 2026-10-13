// LES GARDES DE LA TACHE 808, CHANTIER « UN PETIT MESSAGE » (item 3).
//
// RETOUR DE CHRISTOPHE DU 10/10, EN MODE DEMO, mot pour mot : « un petit
// message quand tu finis une etape ca serait bien ».
//
// CE QUE CES GARDES TIENNENT, ET POURQUOI CHACUNE :
//
//   * ARRIVER N EST PAS FRANCHIR. Le message ne doit pas se declencher parce
//     qu on ouvre la carte au milieu d une etape : sans memoire du numero
//     precedent, la premiere lecture serait un faux franchissement, et c est
//     le piege classique d un detecteur de front.
//   * LE MESSAGE NOMME CE QU ON VIENT DE FINIR. Le bandeau, lui, bascule deja
//     sur l etape SUIVANTE : si le message nommait la meme, il n apprendrait
//     rien et laisserait disparaitre le nom qu on vient de meriter.
//   * IL PART SEUL. Christophe a demande un petit message, pas un bandeau de
//     plus a fermer. Aucun geste dans ces tests : seulement du temps.
//   * IL NE S EMPILE PAS. A x60 deux bornes peuvent tomber coup sur coup ; le
//     second message remplace le premier et repart pour une duree entiere.
//   * SA DUREE TIENT DANS L ETAPE LA PLUS COURTE, et c est la garde que
//     Christophe a explicitement demandee (« ATTENTION AU TEMPS ACCELERE »).
//     Elle est calculee sur les VRAIES longueurs du sentier de demonstration,
//     lues dans l asset : si une etape minuscule apparait un jour, elle tombe.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule.dart';
import 'package:moteur_gr/features/trek/presentation/map/felicitations_d_etape.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  /// Une trace droite de 20 km, deux etapes de 10 km.
  final trace = [
    for (var d = 0.0; d <= 20000; d += 500)
      TrackPoint(
        lat: 42.0 + d / 111320.0,
        lng: 9.0,
        altitude: 100 + (d / 1000) * 10,
        distanceFromStart: d,
      ),
  ];
  // TROIS ETAPES, ET IL EN FAUT TROIS : avec deux, on ne peut franchir
  // qu'une seule borne, et la garde du REARMEMENT n'aurait rien a mesurer.
  // Bornes a 5 km et a 10 km.
  final etapes = [
    _etape(1, 0, 5000, trace),
    _etape(2, 5000, 10000, trace),
    _etape(3, 10000, 20000, trace),
  ];

  Position fix(double abscisseM) {
    final point = trace.firstWhere(
      (p) => p.distanceFromStart >= abscisseM,
      orElse: () => trace.last,
    );
    return Position(
      latitude: point.lat,
      longitude: point.lng,
      timestamp: DateTime.utc(2026, 6, 15, 9),
      accuracy: 5,
      altitude: point.altitude,
      altitudeAccuracy: 5,
      heading: 0,
      headingAccuracy: 0,
      speed: 1.2,
      speedAccuracy: 0.5,
    );
  }

  /// Le banc : la banniere seule, nourrie par un robinet de positions que le
  /// test ouvre a la main. C est ce qui permet de FRANCHIR une borne pendant
  /// le test, et pas seulement de se poser d un cote ou de l autre.
  Widget banc(Stream<Position> positions) => ProviderScope(
    overrides: [
      trailConfigProvider.overrideWithValue(testTrailConfig),
      gpxTrackProvider(
        testTrailConfig.id,
      ).overrideWith((ref) => Future.value(trace)),
      gpxTrackProvider('default').overrideWith((ref) => Future.value(trace)),
      stagesProvider(
        testTrailConfig.id,
      ).overrideWith((ref) => Future.value(etapes)),
      stagesProvider('default').overrideWith((ref) => Future.value(etapes)),
      locationProvider.overrideWith((ref) => positions),
      gpsPermissionProvider.overrideWith(
        (ref) => Future.value(GpsPermissionStateValues.granted),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: Align(child: FelicitationsDEtape())),
    ),
  );

  /// Pose une position et laisse la chaine de projection se propager.
  Future<void> poser(
    WidgetTester tester,
    StreamController<Position> robinet,
    double abscisseM,
  ) async {
    robinet.add(fix(abscisseM));
    // TROIS BATTEMENTS, ET CHACUN SERT : le premier livre l evenement du flux
    // et recalcule la projection, le second laisse la rappel-apres-image
    // poser l etat, le troisieme le dessine.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
  }

  group('LA FIN D UNE ETAPE SE DIT (tache 808)', () {
    testWidgets('ARRIVER SUR LA CARTE N EST PAS FRANCHIR UNE BORNE : aucun '
        'message a l ouverture, meme en pleine etape 2', (tester) async {
      final robinet = StreamController<Position>();
      addTearDown(robinet.close);
      await tester.pumpWidget(banc(robinet.stream));
      await tester.pump();
      await poser(tester, robinet, 15000);

      expect(
        find.text(t.map.etapeFinie),
        findsNothing,
        reason: 'la premiere etape vue est une lecture, pas un franchissement',
      );
    });

    testWidgets('FRANCHIR LA BORNE NOMME L ETAPE ACHEVEE, pas celle qui '
        'commence', (tester) async {
      final robinet = StreamController<Position>();
      addTearDown(robinet.close);
      await tester.pumpWidget(banc(robinet.stream));
      await tester.pump();
      await poser(tester, robinet, 9000);
      await poser(tester, robinet, 11000);

      expect(find.text(t.map.etapeFinie), findsOneWidget);
      expect(
        find.text('Etape 2'),
        findsOneWidget,
        reason: 'on felicite ce qui est fini, pas ce qui commence',
      );
      expect(find.text('Etape 3'), findsNothing);
    });

    testWidgets('LE MESSAGE S EFFACE SEUL, sans qu on touche a rien', (
      tester,
    ) async {
      final robinet = StreamController<Position>();
      addTearDown(robinet.close);
      await tester.pumpWidget(banc(robinet.stream));
      await tester.pump();
      await poser(tester, robinet, 9000);
      await poser(tester, robinet, 11000);
      expect(find.text(t.map.etapeFinie), findsOneWidget);

      // Juste avant l echeance, il est encore la...
      await tester.pump(FelicitationsDEtape.duree - const Duration(seconds: 1));
      expect(find.text(t.map.etapeFinie), findsOneWidget);
      // ... et apres, il est parti de lui-meme.
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(t.map.etapeFinie), findsNothing);
    });

    testWidgets('UN SECOND FRANCHISSEMENT REARME LE MESSAGE au lieu de le '
        'laisser mourir a l heure du premier', (tester) async {
      final robinet = StreamController<Position>();
      addTearDown(robinet.close);
      await tester.pumpWidget(banc(robinet.stream));
      await tester.pump();
      await poser(tester, robinet, 4000);
      await poser(tester, robinet, 6000);
      expect(find.text('Etape 1'), findsOneWidget);

      // On laisse courir presque toute la premiere minuterie, puis on franchit
      // de nouveau : le message doit repartir pour une duree ENTIERE.
      await tester.pump(FelicitationsDEtape.duree - const Duration(seconds: 1));
      await poser(tester, robinet, 11000);
      expect(find.text('Etape 2'), findsOneWidget);
      expect(find.text('Etape 1'), findsNothing);

      await tester.pump(FelicitationsDEtape.duree - const Duration(seconds: 1));
      expect(
        find.text(t.map.etapeFinie),
        findsOneWidget,
        reason: 'la minuterie du second message est la sienne, pas un reste',
      );
      await tester.pump(const Duration(seconds: 2));
      expect(find.text(t.map.etapeFinie), findsNothing);
    });
  });

  group('LE MESSAGE TIENT DANS LE TEMPS ACCELERE DE LA DEMO', () {
    test('sa duree reste sous 5 pct de l etape la plus courte du sentier de '
        'demonstration', () {
      // LES VRAIES LONGUEURS, lues dans l asset et non recopiees ici : si une
      // etape minuscule apparait un jour, cette garde tombe avant Christophe.
      final brut = File(
        'assets/data/mare_a_mare_centre/stages.json',
      ).readAsStringSync();
      final lignes = (jsonDecode(brut) as List).cast<Map<String, dynamic>>();
      final plusCourteKm = lignes
          .map((l) => (l['distanceKm'] as num).toDouble())
          .reduce((a, b) => a < b ? a : b);

      // La vitesse APPARENTE a l ecran en demonstration : l allure simulee
      // multipliee par le facteur de temps. Aucune constante recopiee.
      const metresParSecondeEcran =
          MarcheurSimule.kVitesseSimuleeKmh /
          3.6 *
          MarcheurSimule.kFacteurTemps;
      final secondesDeLEtape = plusCourteKm * 1000 / metresParSecondeEcran;

      expect(
        FelicitationsDEtape.duree.inSeconds / secondesDeLEtape,
        lessThan(0.05),
        reason:
            'l etape la plus courte dure ${secondesDeLEtape.round()} s a '
            'l ecran ; un message de '
            '${FelicitationsDEtape.duree.inSeconds} s doit y rester une '
            'ponctuation, jamais un bandeau permanent',
      );
    });
  });
}

StageModel _etape(int numero, double debutM, double finM, List<TrackPoint> t) {
  final depart = t.firstWhere(
    (p) => p.distanceFromStart >= debutM,
    orElse: () => t.first,
  );
  final arrivee = t.firstWhere(
    (p) => p.distanceFromStart >= finM,
    orElse: () => t.last,
  );
  return StageModel(
    trailId: testTrailConfig.id,
    stageNumber: numero,
    name: 'Etape $numero',
    distanceKm: (finM - debutM) / 1000,
    elevationGainM: 100,
    elevationLossM: 80,
    startLat: depart.lat,
    startLng: depart.lng,
    endLat: arrivee.lat,
    endLng: arrivee.lng,
    departureName: 'D$numero',
    arrivalName: 'A$numero',
  );
}
