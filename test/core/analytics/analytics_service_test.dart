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
    test('aucun evenement tant que le consentement n\'est pas accorde', () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      // Pas de consentement : tout est inerte.
      await service.logScreenView('map');
      await service.logTrekStarted(trailId: 'sentier-bleu');
      await service.recordError(StateError('x'), null);

      expect(a.events, isEmpty);
      expect(a.screens, isEmpty);
      expect(c.errors, isEmpty);
    });

    test('setConsent bascule la collecte Analytics ET Crashlytics', () async {
      final a = _RecAnalytics();
      final c = _RecCrash();
      final service = AnalyticsService(analytics: a, crash: c);

      await service.setConsent(granted: true);
      expect(service.isConsentGranted, isTrue);
      expect(a.collectionEnabled, isTrue);
      expect(c.collectionEnabled, isTrue);

      await service.setConsent(granted: false);
      expect(a.collectionEnabled, isFalse);
      expect(c.collectionEnabled, isFalse);
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
