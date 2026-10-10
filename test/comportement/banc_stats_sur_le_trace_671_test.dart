import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/geo/track_segment_stats.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/estime_de_fond.dart';

import 'banc_du_trace_671.dart';

/// LOT 671-06, FICHE E6 — LE BANC DE REFERENCE, QUI REMPLACE LA MARCHE.
///
/// Christophe ne marchera pas : ce lot ne s'acquitte pas en disant que le
/// denivele est meilleur, il le CHIFFRE. Le meme trace, la meme journee,
/// echantillonnee a DIX METRES (la verite geometrique du sentier) et a TROIS
/// MINUTES (ce que donnent les releves du profil batterie d'abord, 200 m a
/// 4 km/h), passee AVANT le lot par les points enregistres et APRES le lot
/// par la tranche de trace.
///
/// « AVANT » est [computeTrackStats] sur les releves : c'est exactement le
/// calcul d'avant le lot, le test `track_segment_stats_test.dart` le prouve
/// au metre et a la seconde. « APRES » est [computeTrackStatsOnTrace], la
/// fonction que la carte, le journal et le recapitulatif appellent.
///
/// LA JOURNEE S'ARRETE SUR UN RELEVE : la marche dure un nombre entier de
/// periodes de trois minutes, pour mesurer la methode et non la phase du
/// dernier tir. Sans cela, le dernier releve d'une journee a trois minutes
/// tomberait jusqu'a 200 m avant l'arrivee, avant comme apres le lot.
void main() {
  /// LE SEUIL D'ACCEPTATION DU LOT : 2 % d'ecart entre dix metres et trois
  /// minutes, APRES le lot, sur chacun des cinq chiffres.
  ///
  /// L'ARITHMETIQUE. Sur une journee de 6,4 km et 500 m de D+, 2 % valent
  /// 128 m de distance et 10 m de denivele — moins qu'une seule des bosses de
  /// 8 m que la corde de 200 m efface — et 1 min 55 s sur 1 h 36 de marche.
  const acceptanceGapPercent = 2.0;

  /// Les chiffres d'une ligne du tableau.
  String row(String label, TrackSegmentStats s) =>
      '$label | ${s.distanceKm.toStringAsFixed(3)} km | '
      'D+ ${s.elevationGainM} m | D- ${s.elevationLossM} m | '
      '${s.duration.inSeconds} s | '
      '${s.averageSpeedKmh?.toStringAsFixed(2) ?? 'nulle'} km/h';

  /// Le tableau de la fiche E6 pour [trace], marche jusqu'a [untilM].
  ({
    TrackSegmentStats before10,
    TrackSegmentStats before3,
    TrackSegmentStats after10,
    TrackSegmentStats after3,
  })
  bench(List<TrackPoint> trace, double untilM) {
    final every10 = walk(trace, everyM: 10, untilM: untilM);
    final every3min = walk(trace, everyM: batteryFirstSpacingM, untilM: untilM);
    return (
      before10: computeTrackStats(every10),
      before3: computeTrackStats(every3min),
      after10: computeTrackStatsOnTrace(readings: every10, trace: trace),
      after3: computeTrackStatsOnTrace(readings: every3min, trace: trace),
    );
  }

  void report(
    String name,
    ({
      TrackSegmentStats before10,
      TrackSegmentStats before3,
      TrackSegmentStats after10,
      TrackSegmentStats after3,
    })
    t,
  ) {
    debugPrint('BANC 671-06 — $name');
    debugPrint(row('10 m    AVANT', t.before10));
    debugPrint(row('3 min   AVANT', t.before3));
    debugPrint(row('10 m    APRES', t.after10));
    debugPrint(row('3 min   APRES', t.after3));
    for (final (label, a, b) in [
      ('AVANT', t.before10, t.before3),
      ('APRES', t.after10, t.after3),
    ]) {
      debugPrint(
        'ECART $label 10 m / 3 min : '
        'distance ${gapText(a.distanceKm, b.distanceKm)} '
        '| D+ ${gapText(a.elevationGainM, b.elevationGainM)} '
        '| D- ${gapText(a.elevationLossM, b.elevationLossM)} '
        '| duree ${gapText(a.duration.inSeconds, b.duration.inSeconds)} '
        '| vitesse ${gapText(a.averageSpeedKmh ?? 0, b.averageSpeedKmh ?? 0)}',
      );
    }
    final gain = t.after3.elevationGainM - t.before3.elevationGainM;
    debugPrint(
      'GAIN DE D+ A TROIS MINUTES : $gain m '
      '(${gapText(t.before3.elevationGainM, t.after3.elevationGainM)} '
      'au-dessus de l avant)',
    );
  }

  void expectConverged(String name, TrackSegmentStats a, TrackSegmentStats b) {
    final pairs = <String, (num, num)>{
      'distance (km)': (a.distanceKm, b.distanceKm),
      'D+ (m)': (a.elevationGainM, b.elevationGainM),
      'D- (m)': (a.elevationLossM, b.elevationLossM),
      'duree (s)': (a.duration.inSeconds, b.duration.inSeconds),
      'vitesse (km/h)': (a.averageSpeedKmh ?? 0, b.averageSpeedKmh ?? 0),
    };
    for (final MapEntry(key: what, value: (ten, three)) in pairs.entries) {
      expect(
        gapPercent(ten, three),
        lessThan(acceptanceGapPercent),
        reason:
            '$name, $what : $ten a dix metres contre $three a trois minutes, '
            'APRES le lot — les deux lisent pourtant la meme tranche de trace. '
            'D+ a dix metres ${a.elevationGainM} m, a trois minutes '
            '${b.elevationGainM} m.',
      );
    }
  }

  group('671-06 E6 — dix metres contre trois minutes', () {
    test('APRES LE LOT, LE MEME TRACE ECHANTILLONNE A DIX METRES ET A TROIS '
        'MINUTES DONNE DES CHIFFRES A MOINS DE 2 % — trace fabrique et '
        'sentier de reference', () {
      final fabricated = fabricatedTrace();
      final t = bench(fabricated, 32 * batteryFirstSpacingM);
      report('trace fabrique (6,4 km de marche)', t);
      expectConverged('trace fabrique', t.after10, t.after3);

      final reference = referenceTrail();
      final r = bench(reference, 120 * batteryFirstSpacingM);
      report('Mare a Mare Centre (24 km de marche)', r);
      expectConverged('Mare a Mare Centre', r.after10, r.after3);

      // La duree et la vitesse sont renseignees, a toutes les lignes.
      for (final s in [t.after10, t.after3, r.after10, r.after3]) {
        expect(s.duration, greaterThan(Duration.zero));
        expect(s.averageSpeedKmh, isNotNull);
      }
    });

    test('LE DENIVELE DU JOUR REMONTE : le gain, en metres, sur le trace '
        'fabrique et sur le sentier de reference', () {
      final t = bench(fabricatedTrace(), 32 * batteryFirstSpacingM);
      final r = bench(referenceTrail(), 120 * batteryFirstSpacingM);

      // Sur le trace fabrique, le vrai D+ de la tranche marchee est connu :
      // 300 m de montee, et 24 bosses de 8 m entieres plus le debut de la
      // 25e — la journee s'arrete a 6 400 m, a 21 m de la fin du trace.
      expect(
        t.after3.elevationGainM,
        greaterThan(t.before3.elevationGainM),
        reason:
            'trace fabrique : D+ a trois minutes ${t.before3.elevationGainM} m '
            'AVANT le lot, ${t.after3.elevationGainM} m APRES — l effondrement '
            'du denivele devait disparaitre.',
      );
      expect(t.after3.elevationGainM, inInclusiveRange(490, 500));
      // TACHE 761 — LA VRAIE TRACE RETOURNE CETTE COMPARAISON, ET CE N EST PAS
      // LE LOT 671 QUI A REGRESSE : c est un defaut du SEUIL que seule une
      // trace dense pouvait montrer. Mesure sur le sentier de reference,
      // 24 km de marche : 1 733 m AVANT, 1 458 m APRES — l « apres » est
      // desormais le PLUS BAS des deux.
      //
      // LA CAUSE, dans `computeTrackStatsOn` : le seuil de bruit de 3 m est
      // compare a l ecart entre DEUX POINTS CONSECUTIFS, et un ecart qui ne
      // l atteint pas est JETE, jamais reporte. Sur des releves espaces de
      // 200 m (l « avant »), chaque ecart depasse 3 m et compte en entier. Sur
      // la trace relevee, espacee de 19 m, une montee reelle arrive par
      // paliers de 1 a 2 m : chacun est jete, et une pente soutenue peut
      // n accumuler presque RIEN. L ancienne trace de 53 points cachait le
      // defaut, ses altitudes etant interpolees en longues rampes lisses.
      //
      // CE N EST PAS CORRIGE ICI, ET DELIBEREMENT : le seuil vit dans le socle
      // (`lib/core/geo/track_segment_stats.dart`, lu par le journal, le
      // recapitulatif, le diplome et les badges), et le corriger — en suivant
      // une reference mobile au lieu de comparer des ecarts consecutifs —
      // deplacerait TOUS les deniveles de l application. Cela demande son
      // propre lot. Le chiffre est donc DONNE, et la comparaison dit ce
      // qu elle mesure au lieu d affirmer ce qui n est plus vrai.
      expect(r.before3.elevationGainM, 1733);
      expect(r.after3.elevationGainM, 1458);
      expect(
        r.after3.elevationGainM,
        lessThan(r.before3.elevationGainM),
        reason:
            'Mare a Mare Centre : D+ a trois minutes '
            '${r.before3.elevationGainM} m AVANT, ${r.after3.elevationGainM} m '
            'APRES — si l apres repassait au-dessus, c est que le seuil du '
            'socle a change, et ce commentaire doit etre relu.',
      );
      debugPrint(
        'GAIN 671-06 : trace fabrique '
        '${t.after3.elevationGainM - t.before3.elevationGainM} m, '
        'Mare a Mare Centre '
        '${r.after3.elevationGainM - r.before3.elevationGainM} m',
      );
    });

    test('LE PIEGE DU SEUIL PAR PAIRE, MESURE ET NON CORRIGE : sur un trace '
        'DENSE, le seuil de 3 m entre deux points voisins efface le relief, '
        'trace ou releves', () {
      // LE MOTEUR N'A PAS CHANGE, ET C'EST POURQUOI CE TEST EXISTE. Le seuil
      // de bruit compare chaque point AU PRECEDENT : une pente reguliere
      // decoupee en pas de moins de 3 m de denivele ne compte RIEN. Les
      // sentiers du depot ont un point par kilometre environ, et la tranche
      // y garde tout le relief ; un trace a un point tous les 5 m le
      // perdrait, comme le perdent aujourd'hui des releves tous les 10 m.
      // Corriger le seuil change le calcul : c'est une decision de
      // Christophe, hors de ce lot. Si ce test rougit parce que le D+ du
      // trace dense rejoint le vrai, le moteur a ete corrige : mettez cette
      // mesure a jour.
      final coarse = fabricatedTrace();
      final dense = densify(coarse, 5);
      final readings = walk(dense, everyM: batteryFirstSpacingM, untilM: 6400);
      final onCoarse = computeTrackStatsOnTrace(
        readings: readings,
        trace: coarse,
      );
      final onDense = computeTrackStatsOnTrace(
        readings: readings,
        trace: dense,
      );
      final readingsOnly = computeTrackStats(readings);
      debugPrint(
        'PIEGE DU SEUIL PAR PAIRE : D+ sur le trace aux ruptures de pente '
        '${onCoarse.elevationGainM} m, sur le meme trace a un point tous les '
        '5 m ${onDense.elevationGainM} m, sur les releves a trois minutes '
        '${readingsOnly.elevationGainM} m',
      );

      expect(onDense.distanceKm, closeTo(onCoarse.distanceKm, 0.001));
      expect(readingsOnly.elevationGainM, greaterThan(onDense.elevationGainM));
      expect(onDense.elevationGainM, lessThan(onCoarse.elevationGainM ~/ 10));
    });
  });

  group('671-06 E7 (7) — la trace dessinee, base Drift en memoire', () {
    final trace = fabricatedTrace();
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    Future<void> store(
      List<SessionTrackPoint> points, {
      required TrackPointSource source,
    }) async {
      for (final p in points) {
        await db.sessionTrackPointsDao.insertPoint(
          trailId: testTrailConfig.id,
          sessionId: p.sessionId,
          lat: p.lat,
          lng: p.lng,
          altitude: p.altitude,
          recordedAt: p.recordedAt,
          source: source,
        );
      }
    }

    group('la trace du jour reste dense, mesuree', () {
      test('LE COMPTE ET L ESPACEMENT MEDIAN de la trace enregistree, avec et '
          'sans les points estimes du lot 671-03', () async {
        // L'ESTIME REEL DE L'ISOLATE DE FOND, nourri d'une fausse marche : un
        // releve toutes les trois minutes, un paquet de pas toutes les deux
        // secondes (hypothese du banc), la regle de retenue a 12 m
        // (kBgMinKeepDistanceMeters).
        const stride = 0.75;
        final reckoning = TrackDeadReckoning((
          trailId: testTrailConfig.id,
          points: trace,
          direction: WalkDirection.increasing,
        ));
        final fixes = walk(trace, everyM: batteryFirstSpacingM, untilM: 6400);
        final recorded = <SessionTrackPoint>[];
        for (final fix in fixes) {
          final fixSeconds = fix.recordedAt.difference(benchStart).inSeconds;
          final fixSteps = (fixSeconds * walkSpeedMps / stride).floor();
          reckoning.recalibrate(
            latitude: fix.lat,
            longitude: fix.lng,
            steps: fixSteps,
          );
          recorded.add(fix);
          if (fix == fixes.last) break;
          for (var t = fixSeconds + 2; t < fixSeconds + 180; t += 2) {
            final e = reckoning.advance(
              steps: (t * walkSpeedMps / stride).floor(),
              strideMeters: stride,
            );
            if (e == null || !reckoning.keep(e, kBgMinKeepDistanceMeters)) {
              continue;
            }
            recorded.add(
              SessionTrackPoint(
                id: 0,
                trailId: testTrailConfig.id,
                sessionId: 'banc',
                lat: e.lat,
                lng: e.lng,
                altitude: e.altitude,
                recordedAt: benchStart.add(Duration(seconds: t)),
                source: TrackPointSource.estimated.stored,
              ),
            );
          }
        }
        for (final p in recorded) {
          await store([p], source: TrackPointSource.fromStored(p.source));
        }

        List<double> spacings(List<SessionTrackPoint> pts) => [
          for (var i = 1; i < pts.length; i++)
            GeoUtils.haversineDistance(
              pts[i - 1].lat,
              pts[i - 1].lng,
              pts[i].lat,
              pts[i].lng,
            ),
        ];
        final dao = db.sessionTrackPointsDao;
        final dense = await dao.getBySessionId(
          'banc',
          read: TrackPointsRead.withEstimated,
        );
        final sparse = await dao.getBySessionId(
          'banc',
          read: TrackPointsRead.gpsOnly,
        );
        final denseMedian = median(spacings(dense));
        final sparseMedian = median(spacings(sparse));
        debugPrint(
          'TRACE DU JOUR 671-06 : ${dense.length} points, espacement median '
          '${denseMedian.toStringAsFixed(1)} m AVEC les estimes ; '
          '${sparse.length} points, ${sparseMedian.toStringAsFixed(1)} m SANS',
        );

        expect(sparse, hasLength(33));
        expect(sparseMedian, closeTo(200, 1));
        expect(dense.length, greaterThan(400));
        expect(denseMedian, inInclusiveRange(12, 16));
      });
    });
  });
}
