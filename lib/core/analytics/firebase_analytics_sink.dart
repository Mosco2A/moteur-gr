/// Le puits Firebase, instancie SEULEMENT quand Firebase est la : il isole
/// l'import, pour que le service tourne sans lui.
library;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'analytics_service.dart';

/// Puits analytics adosse a Firebase Analytics (E5.4).
///
/// N'est instancie QUE lorsque Firebase est disponible (voir
/// [analyticsServiceProvider]). Isole l'import firebase_analytics du service,
/// qui reste ainsi testable sans dependance native.
class FirebaseAnalyticsSink implements AnalyticsSink {
  FirebaseAnalyticsSink({FirebaseAnalytics? analytics})
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent(String name, Map<String, Object?> params) {
    // Firebase n'accepte que des valeurs String/num, non nulles.
    final clean = <String, Object>{
      for (final entry in params.entries)
        if (entry.value != null) entry.key: entry.value!,
    };
    return _analytics.logEvent(name: name, parameters: clean);
  }

  @override
  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _analytics.setAnalyticsCollectionEnabled(enabled);
}

/// Puits crash adosse a Firebase Crashlytics (E5.4) — fatals + non-fatals.
class FirebaseCrashSink implements CrashSink {
  FirebaseCrashSink({FirebaseCrashlytics? crashlytics})
    : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) => _crashlytics.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  /// TACHE 637 — LES MIETTES DE PISTE. Ni `log` ni `setCustomKey` n'emettent
  /// quoi que ce soit par eux-memes : Crashlytics les garde en local et ne les
  /// joint qu'au prochain rapport, s'il y en a un. Aucun trafic, aucune donnee
  /// envoyee pour une session qui se passe bien.
  @override
  Future<void> log(String message) => _crashlytics.log(message);

  @override
  Future<void> setCustomKey(String key, String value) =>
      _crashlytics.setCustomKey(key, value);
}
