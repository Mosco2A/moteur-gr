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
  }) =>
      _crashlytics.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);
}
