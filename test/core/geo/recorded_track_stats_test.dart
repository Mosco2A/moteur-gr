import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';

import '../../comportement/banc_du_trace_671.dart';

/// LOT 671-06 — LES CHIFFRES SUR LE TRACE, ET LES LIMITES DE LA METHODE.
///
/// [computeTrackStatsOnTrace] mesure la tranche du sentier entre deux
/// releves reels ; ces tests chiffrent ce qu'elle fait de trois marches qui
/// ne vont pas simplement du depart vers la fin : l'aller-retour, le sentier
/// a l'envers, et la marche loin du trace.
void main() {
  final trace = fabricatedTrace();

  group('671-06 — limites de la methode, chiffrees', () {
    test('L ALLER-RETOUR : 750 m a l aller, 250 m au retour — 1 000 m dans '
        'les jambes, 500 m sur la tranche (defaut connu, remonte a '
        'Christophe, non corrige)', () {
      final out = walk(trace, everyM: 50, untilM: 750);
      final back = [
        for (final p in walk(trace, everyM: 50, untilM: 750).reversed.skip(1))
          if (p.recordedAt.difference(benchStart).inSeconds >= 450)
            p.copyWith(
              recordedAt: out.last.recordedAt.add(
                out.last.recordedAt.difference(p.recordedAt),
              ),
            ),
      ];
      final readings = [...out, ...back];

      final onTrace = computeTrackStatsOnTrace(
        readings: readings,
        trace: trace,
      );
      final onReadings = computeTrackStats(readings);
      debugPrint(
        'ALLER-RETOUR 671-06 : ${(onTrace.distanceKm * 1000).round()} m sur la '
        'tranche, ${(onReadings.distanceKm * 1000).round()} m sur les releves',
      );

      expect(onTrace.distanceKm, closeTo(0.5, 0.001));
      expect(onReadings.distanceKm, closeTo(1.0, 0.001));
    });

    test('LE SENTIER A L ENVERS : la montee faite compte en D+', () {
      final forward = walk(trace, everyM: batteryFirstSpacingM, untilM: 6400);
      final reverse = [
        for (final (i, p) in forward.reversed.indexed)
          p.copyWith(recordedAt: forward[i].recordedAt),
      ];

      final f = computeTrackStatsOnTrace(readings: forward, trace: trace);
      final r = computeTrackStatsOnTrace(readings: reverse, trace: trace);

      expect(r.distanceKm, closeTo(f.distanceKm, 1e-9));
      expect(r.elevationGainM, f.elevationLossM);
      expect(r.elevationLossM, f.elevationGainM);
    });

    test('LOIN DU TRACE, LES RELEVES : au-dela de kStatsMaxOffTraceMeters, la '
        'tranche ne decrit pas la marche', () {
      final far = [
        for (final p in walk(trace, everyM: batteryFirstSpacingM, untilM: 2000))
          p.copyWith(lng: p.lng + 0.05),
      ];

      final stats = computeTrackStatsOnTrace(readings: far, trace: trace);
      final readingsOnly = computeTrackStats(far);

      expect(stats.distanceKm, readingsOnly.distanceKm);
      expect(stats.elevationGainM, readingsOnly.elevationGainM);
      expect(stats.duration, readingsOnly.duration);
    });
  });
}
