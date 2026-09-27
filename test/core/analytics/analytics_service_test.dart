import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';

/// Puits analytics enregistreur (capture les appels).
class _RecAnalytics implements AnalyticsSink {
  final List<({String name, Map<String, Object?> params})> events = [];
  final List<String> screens = [];
  bool? collectionEnabled;

  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {
    events.add((name: name, params: params));
  }

  @override
  Future<void> logScreenView(String screenName) async {
    screens.add(screenName);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }
}

/// Puits crash enregistreur.
class _RecCrash implements CrashSink {
  final List<({Object error, bool fatal})> errors = [];
  bool? collectionEnabled;

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {required bool fatal}) async {
    errors.add((error: error, fatal: fatal));
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async {
    collectionEnabled = enabled;
  }
}

/// Verifie qu'un jeu de parametres ne contient AUCUNE PII.
void _assertNoPii(Map<String, Object?> params, {required String rawTrailId}) {
  const piiKeys = {
    'name', 'nom', 'email', 'mail', 'uid', 'user', 'userid', 'user_id',
    'lat', 'lng', 'latitude', 'longitude', 'gps', 'coord', 'position', 'phone',
  };
  final emailRe = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
  final coordRe = RegExp(r'-?\d{1,3}\.\d{3,}'); // ex: 42.123456

  params.forEach((key, value) {
    expect(piiKeys.contains(key.toLowerCase()), isFalse,
        reason: 'cle PII interdite: $key');
    final s = value.toString();
    expect(s, isNot(equals(rawTrailId)),
        reason: 'identifiant en clair dans "$key"');
    expect(emailRe.hasMatch(s), isFalse, reason: 'email dans "$key": $s');
    expect(coordRe.hasMatch(s), isFalse, reason: 'coordonnee GPS dans "$key": $s');
  });
}

void main() {
  final hashRe = RegExp(r'^[0-9a-f]{64}$');

  group('AnalyticsService — mode degrade (Firebase indisponible)', () {
    test('provider => service inerte, aucun crash', () async {
      final container = ProviderContainer(overrides: [
        firebaseServiceProvider
            .overrideWithValue(FirebaseService.testOnly(isAvailable: false)),
      ]);
      addTearDown(container.dispose);

      final service = container.read(analyticsServiceProvider);
      expect(service.isOperational, isFalse);

      // Toutes les operations sont no-op (zero crash), meme avec consentement.
      await service.setConsent(granted: true);
      await service.logScreenView('map');
      await service.logTrailDownloaded(trailId: 'sentier-bleu');
      await service.logTrekStarted(trailId: 'sentier-bleu');
      await service.recordError(StateError('x'), StackTrace.current);
      await service.recordFatal(StateError('y'), StackTrace.current);
      // Aucun throw => succes.
    });
  });

  group('AnalyticsService — opt-in (consentement)', () {
    // TACHE 596 (C4) — CES DEUX TESTS CONSACRAIENT LE TROISIEME VERROU.
    //
    // Ils EXIGEAIENT que le consentement de MESURE D'USAGE commande aussi la
    // remontee des plantages. Comme `analyticsServiceProvider` appelle
    // `setConsent(granted: false)` des sa construction (opt-in strict), le
    // premier ecran qui lisait le service coupait Crashlytics pour toute la
    // session : meme Firebase allume et les filets d'erreur poses, aucun
    // rapport ne serait jamais parti. C'etait le verrou le plus vicieux des
    // trois, parce qu'il annulait silencieusement la correction des deux
    // autres — et un test vert le tenait en place.
    //
    // Mesurer l'usage d'un randonneur et savoir que l'appli a plante chez lui
    // sont deux questions differentes, pour deux finalites differentes. Les
    // deux interrupteurs sont desormais separes, dans les deux sens.

    test('aucun EVENEMENT D USAGE tant que le consentement n\'est pas accorde',
        () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      // Pas de consentement : la mesure d'usage est inerte.
      await service.logScreenView('map');
      await service.logTrekStarted(trailId: 'sentier-bleu');

      expect(a.events, isEmpty);
      expect(a.screens, isEmpty);
    });

    test('un PLANTAGE remonte meme sans consentement de mesure d usage',
        () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      await service.recordError(StateError('x'), null);

      expect(c.errors, hasLength(1),
          reason: 'une panne n est pas une mesure d usage : elle ne doit pas '
              'etre retenue par le consentement analytics, sinon zero rapport '
              'de plantage, pour toujours');
      expect(a.events, isEmpty, reason: 'et rien n a fuite cote usage');
    });

    test('setConsent ne bascule QUE la collecte Analytics', () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      await service.setConsent(granted: true);
      expect(service.isConsentGranted, isTrue);
      expect(a.collectionEnabled, isTrue);
      expect(c.collectionEnabled, isNull,
          reason: 'setConsent ne doit plus toucher l interrupteur des '
              'plantages, dans un sens comme dans l autre');

      await service.setConsent(granted: false);
      expect(a.collectionEnabled, isFalse);
      expect(c.collectionEnabled, isNull);
    });

    test('la remontee des plantages a son PROPRE interrupteur', () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      await service.setCrashCollection(enabled: true);
      expect(c.collectionEnabled, isTrue);
      expect(a.collectionEnabled, isNull,
          reason: 'et reciproquement : allumer les plantages n allume pas la '
              'mesure d usage');
    });
  });

  group('AnalyticsService — evenements (Firebase disponible + consentement)', () {
    late _RecAnalytics a;
    late _RecCrash c;
    late AnalyticsService service;

    setUp(() async {
      a = _RecAnalytics();
      c = _RecCrash();
      service = AnalyticsService(analytics: a, crash: c);
      await service.setConsent(granted: true);
    });

    test('trek_started loggue avec trailId hashe (jamais en clair)', () async {
      await service.logTrekStarted(trailId: 'sentier-bleu');

      expect(a.events, hasLength(1));
      final ev = a.events.single;
      expect(ev.name, equals(AnalyticsEvents.trekStarted));
      final expected =
          sha256.convert(utf8.encode('sentier-bleu')).toString();
      expect(ev.params['trail'], equals(expected));
      expect(ev.params['trail'], matches(hashRe));
      expect(ev.params['trail'], isNot(equals('sentier-bleu')));
    });

    test('les 5 evenements sont emis et 100% zero-PII', () async {
      await service.logTrailDownloaded(trailId: 'sentier-bleu');
      await service.logTrekStarted(trailId: 'sentier-bleu');
      await service.logTrekCompleted(
        trailId: 'sentier-bleu',
        distanceKm: 42.7,
        duration: const Duration(hours: 6, minutes: 30),
      );
      await service.logShareCard(template: 'stats');
      await service.logDiplomaGenerated(trailId: 'sentier-bleu');

      final names = a.events.map((e) => e.name).toList();
      expect(names, [
        AnalyticsEvents.trailDownloaded,
        AnalyticsEvents.trekStarted,
        AnalyticsEvents.trekCompleted,
        AnalyticsEvents.shareCard,
        AnalyticsEvents.diplomaGenerated,
      ]);

      for (final ev in a.events) {
        _assertNoPii(ev.params, rawTrailId: 'sentier-bleu');
      }

      // Mesures grossieres (anti-fingerprinting) : entiers arrondis.
      final completed = a.events
          .firstWhere((e) => e.name == AnalyticsEvents.trekCompleted);
      expect(completed.params['distance_km'], equals(43));
      expect(completed.params['duration_min'], equals(390));
    });

    test('logScreenView n\'emet pas d\'identifiant', () async {
      await service.logScreenView('catalog');
      expect(a.screens, equals(['catalog']));
    });

    test('trek_stats (F6B-03) emis arrondi et zero-PII', () async {
      await service.logTrekStats(
        trailId: 'sentier-bleu',
        distanceKm: 12.6,
        elevationGainM: 845.4,
        activeDuration: const Duration(hours: 3, minutes: 12),
        pauseCount: 2,
        avgHeartRateBpm: 134,
      );

      expect(a.events, hasLength(1));
      final ev = a.events.single;
      expect(ev.name, equals(AnalyticsEvents.trekStats));
      // Mesures arrondies (anti-fingerprinting).
      expect(ev.params['distance_km'], equals(13));
      expect(ev.params['elevation_gain_m'], equals(845));
      expect(ev.params['active_min'], equals(192));
      expect(ev.params['pauses'], equals(2));
      // FC en palier de 10 bpm.
      expect(ev.params['hr_bucket'], equals(130));
      _assertNoPii(ev.params, rawTrailId: 'sentier-bleu');
    });

    test('trek_stats omet la FC si non fournie', () async {
      await service.logTrekStats(
        trailId: 'sentier-bleu',
        distanceKm: 5.0,
        elevationGainM: 100,
        activeDuration: const Duration(hours: 1),
        pauseCount: 0,
      );
      expect(a.events.single.params.containsKey('hr_bucket'), isFalse);
    });

    test('Crashlytics : non-fatal et fatal enregistres avec le bon flag',
        () async {
      await service.recordError(StateError('non-fatal'), StackTrace.current);
      await service.recordFatal(StateError('fatal'), StackTrace.current);

      expect(c.errors, hasLength(2));
      expect(c.errors[0].fatal, isFalse);
      expect(c.errors[1].fatal, isTrue);
    });
  });

  group('AnalyticsService.anonymize', () {
    test('SHA-256 deterministe, 64 hex, different de l\'entree', () {
      final h1 = AnalyticsService.anonymize('sentier-bleu');
      final h2 = AnalyticsService.anonymize('sentier-bleu');
      expect(h1, equals(h2));
      expect(h1, matches(hashRe));
      expect(h1, isNot(equals('sentier-bleu')));
      expect(AnalyticsService.anonymize('autre'), isNot(equals(h1)));
    });
  });
}
