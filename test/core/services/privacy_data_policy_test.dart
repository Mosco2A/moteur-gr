// D4B-01 — Tests de la politique de minimisation (design D4 CORDO #86166).
//
// VRAIS tests sur la fonction pure [PrivacyDataPolicy.aggregateTrace] :
//   - le resultat ne contient QUE des stats agregees (distance, duree,
//     denivele, nb de points), JAMAIS la serie fine de points / coordonnees
//   - distance, denivele et duree calcules correctement
//   - cas limites : trace vide, trace a un seul point, points sans horodatage
//   - le JSON transmissible n'expose aucune coordonnee ni horodatage individuel
//
// Objectif conformite : prouver qu'aucun point GPS fin ne peut fuir vers le
// serveur via la donnee minimisee (CNIL A4-2, minimisation art 5.1.c RGPD).

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/services/privacy_data_policy.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';

void main() {
  group('PrivacyDataPolicy.aggregateTrace — D4B-01', () {
    // Trace fine d'exemple : 3 points horodates avec altitude variable.
    final trace = <TrackPoint>[
      TrackPoint(
        lat: 42.0000,
        lng: 9.0000,
        elevation: 1000,
        timestamp: DateTime.utc(2026, 6, 15, 10, 0, 0),
      ),
      TrackPoint(
        lat: 42.0010,
        lng: 9.0000,
        elevation: 1050, // +50 m (montee)
        timestamp: DateTime.utc(2026, 6, 15, 10, 5, 0),
      ),
      TrackPoint(
        lat: 42.0010,
        lng: 9.0010,
        elevation: 1020, // -30 m (descente)
        timestamp: DateTime.utc(2026, 6, 15, 10, 12, 0),
      ),
    ];

    test('ne conserve QUE le resultat agrege, PAS la serie fine de points', () {
      final result = PrivacyDataPolicy.aggregateTrace(trace);

      // Le resultat expose des statistiques, et le nombre de points source
      // (information statistique), mais aucune liste de points exploitable.
      expect(result.sourcePointCount, 3);
      expect(result.distanceMeters, greaterThan(0));

      // GARDE-FOU MINIMISATION : le type agrege n'a AUCUN champ "points",
      // "coordinates" ou "timestamps". On le verifie via le JSON serialise
      // (la seule forme qui partirait au serveur) : aucune coordonnee, aucun
      // horodatage individuel ne doit y figurer.
      final json = result.toJson();
      expect(json.keys, containsAll(<String>[
        'distanceMeters',
        'durationSeconds',
        'elevationGainMeters',
        'elevationLossMeters',
        'sourcePointCount',
      ]));
      // Aucune cle ne doit exposer de donnee fine.
      for (final forbidden in <String>[
        'points',
        'coordinates',
        'lat',
        'lng',
        'latitude',
        'longitude',
        'timestamps',
        'trace',
      ]) {
        expect(json.containsKey(forbidden), isFalse,
            reason: 'Le resultat minimise ne doit PAS exposer "$forbidden"');
      }

      // Et la valeur serialisee, recherchee en texte, ne contient aucune des
      // coordonnees fines d'origine (preuve d'absence de la serie).
      final serialized = json.toString();
      expect(serialized.contains('42.001'), isFalse,
          reason: 'Aucune latitude fine ne doit subsister');
      expect(serialized.contains('9.001'), isFalse,
          reason: 'Aucune longitude fine ne doit subsister');
    });

    test('calcule la duree entre premier et dernier point horodate', () {
      final result = PrivacyDataPolicy.aggregateTrace(trace);
      // 10:00 -> 10:12 = 12 minutes.
      expect(result.duration, const Duration(minutes: 12));
    });

    test('calcule le denivele positif et negatif separement', () {
      final result = PrivacyDataPolicy.aggregateTrace(trace);
      // Montee 1000->1050 = +50 ; descente 1050->1020 = -30.
      expect(result.elevationGainMeters, closeTo(50, 0.001));
      expect(result.elevationLossMeters, closeTo(30, 0.001));
    });

    test('distance haversine plausible (centaines de metres ici)', () {
      final result = PrivacyDataPolicy.aggregateTrace(trace);
      // ~111 m / 0.001 deg de latitude -> total dans une plage realiste.
      expect(result.distanceMeters, inInclusiveRange(150, 350));
    });

    test('trace vide -> resultat a zero, zero point source', () {
      final result = PrivacyDataPolicy.aggregateTrace(const <TrackPoint>[]);
      expect(result.sourcePointCount, 0);
      expect(result.distanceMeters, 0);
      expect(result.duration, Duration.zero);
      expect(result.elevationGainMeters, 0);
      expect(result.elevationLossMeters, 0);
    });

    test('trace a un seul point -> aucune distance ni duree', () {
      final single = <TrackPoint>[
        const TrackPoint(lat: 42, lng: 9, elevation: 1000),
      ];
      final result = PrivacyDataPolicy.aggregateTrace(single);
      expect(result.sourcePointCount, 1);
      expect(result.distanceMeters, 0);
      expect(result.duration, Duration.zero);
    });

    test('points sans horodatage -> duree zero (pas de valeur aberrante)', () {
      final noTime = <TrackPoint>[
        const TrackPoint(lat: 42.0, lng: 9.0, elevation: 1000),
        const TrackPoint(lat: 42.001, lng: 9.0, elevation: 1010),
      ];
      final result = PrivacyDataPolicy.aggregateTrace(noTime);
      expect(result.duration, Duration.zero);
      // La distance et le denivele restent calcules (independants du temps).
      expect(result.distanceMeters, greaterThan(0));
      expect(result.elevationGainMeters, closeTo(10, 0.001));
    });

    test('fonction PURE : deux appels donnent un resultat identique', () {
      final a = PrivacyDataPolicy.aggregateTrace(trace);
      final b = PrivacyDataPolicy.aggregateTrace(trace);
      expect(a.distanceMeters, b.distanceMeters);
      expect(a.duration, b.duration);
      expect(a.elevationGainMeters, b.elevationGainMeters);
      expect(a.sourcePointCount, b.sourcePointCount);
    });

    test('AggregatedTrace.empty est neutre', () {
      const e = AggregatedTrace.empty;
      expect(e.distanceMeters, 0);
      expect(e.duration, Duration.zero);
      expect(e.sourcePointCount, 0);
    });
  });
}
