import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'firebase_analytics_sink.dart';

/// Noms d'evenements analytics (zero-PII).
abstract final class AnalyticsEvents {
  static const String trailDownloaded = 'trail_downloaded';
  static const String trekStarted = 'trek_started';
  static const String trekCompleted = 'trek_completed';
  static const String shareCard = 'share_card';
  static const String diplomaGenerated = 'diploma_generated';
}

/// Puits analytics abstrait — decouple de Firebase pour la testabilite.
abstract interface class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object?> params);
  Future<void> logScreenView(String screenName);
  Future<void> setCollectionEnabled(bool enabled);
}

/// Puits crash abstrait — decouple de Crashlytics pour la testabilite.
abstract interface class CrashSink {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  });
  Future<void> setCollectionEnabled(bool enabled);
}

/// Puits analytics inerte (Firebase indisponible / mode degrade).
class NoOpAnalyticsSink implements AnalyticsSink {
  const NoOpAnalyticsSink();
  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {}
  @override
  Future<void> logScreenView(String screenName) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Puits crash inerte (Firebase indisponible / mode degrade).
class NoOpCrashSink implements CrashSink {
  const NoOpCrashSink();
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Service analytics ANONYME (E5.4).
///
/// Garanties :
/// - **Zero-PII strict** : aucun nom/email/uid/GPS en clair n'est jamais
///   transmis. Les identifiants (trailId, ...) sont hashes en SHA-256
///   ([anonymize]). L'API typee ne permet pas de passer de PII. Pas de
///   fingerprinting : les mesures (distance, duree) sont arrondies grossierement.
/// - **Mode degrade** : si Firebase est indisponible, le service est inerte
///   (no-op, zero crash) — voir [AnalyticsService.disabled] et le provider.
/// - **Opt-in** : la collecte est DESACTIVEE par defaut. Aucun evenement n'est
///   emis tant que [setConsent] n'a pas accorde le consentement.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsSink analytics,
    required CrashSink crash,
    bool operational = true,
  })  : _analytics = analytics,
        _crash = crash,
        _operational = operational;

  /// Service inerte (Firebase indisponible) — toutes les operations no-op.
  factory AnalyticsService.disabled() => AnalyticsService(
        analytics: const NoOpAnalyticsSink(),
        crash: const NoOpCrashSink(),
        operational: false,
      );

  final AnalyticsSink _analytics;
  final CrashSink _crash;
  final bool _operational;

  /// Consentement (opt-in). Faux par defaut : aucune collecte avant accord.
  bool _consentGranted = false;

  /// Vrai si un backend reel est cable (Firebase disponible).
  bool get isOperational => _operational;

  /// Vrai si le consentement a ete accorde.
  bool get isConsentGranted => _consentGranted;

  /// Anonymise un identifiant en SHA-256 (hex) — jamais de valeur en clair.
  static String anonymize(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  /// Accorde/retire le consentement. Bascule la collecte Analytics ET
  /// Crashlytics. Opt-in : tant que [granted] est faux, rien n'est emis.
  Future<void> setConsent({required bool granted}) async {
    _consentGranted = granted;
    await _analytics.setCollectionEnabled(granted);
    await _crash.setCollectionEnabled(granted);
  }

  /// Ecran consulte (nom logique d'ecran, jamais d'identifiant utilisateur).
  Future<void> logScreenView(String screenName) async {
    if (!_consentGranted) return;
    await _analytics.logScreenView(screenName);
  }

  Future<void> logTrailDownloaded({required String trailId}) =>
      _log(AnalyticsEvents.trailDownloaded, {'trail': anonymize(trailId)});

  Future<void> logTrekStarted({required String trailId}) =>
      _log(AnalyticsEvents.trekStarted, {'trail': anonymize(trailId)});

  Future<void> logTrekCompleted({
    required String trailId,
    required double distanceKm,
    required Duration duration,
  }) =>
      _log(AnalyticsEvents.trekCompleted, {
        'trail': anonymize(trailId),
        // Valeurs grossieres (anti-fingerprinting) : km et minutes entieres.
        'distance_km': distanceKm.round(),
        'duration_min': duration.inMinutes,
      });

  Future<void> logShareCard({required String template}) =>
      _log(AnalyticsEvents.shareCard, {'template': template});

  Future<void> logDiplomaGenerated({required String trailId}) =>
      _log(AnalyticsEvents.diplomaGenerated, {'trail': anonymize(trailId)});

  /// Erreur non fatale (capturee/geree).
  Future<void> recordError(Object error, StackTrace? stack) async {
    if (!_consentGranted) return;
    await _crash.recordError(error, stack, fatal: false);
  }

  /// Erreur fatale (crash).
  Future<void> recordFatal(Object error, StackTrace? stack) async {
    if (!_consentGranted) return;
    await _crash.recordError(error, stack, fatal: true);
  }

  Future<void> _log(String name, Map<String, Object?> params) async {
    if (!_consentGranted) return;
    await _analytics.logEvent(name, params);
  }
}

/// Provider du service analytics, gate sur la disponibilite Firebase.
///
/// Firebase indisponible -> service inerte (no-op, zero crash).
/// Firebase disponible -> backend reel, collecte DESACTIVEE par defaut
/// (opt-in : appeler [AnalyticsService.setConsent] apres consentement).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final available = ref.watch(isFirebaseAvailableProvider);
  if (!available) {
    return AnalyticsService.disabled();
  }
  final service = AnalyticsService(
    analytics: FirebaseAnalyticsSink(),
    crash: FirebaseCrashSink(),
  );
  // Opt-in strict : collecte coupee tant que le consentement n'est pas donne.
  unawaited(service.setConsent(granted: false));
  return service;
});
