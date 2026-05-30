import 'package:logger/logger.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 2),
);

/// Classification des erreurs applicatives.
enum ErrorCategory {
  /// Erreur reseau (timeout, pas de connexion, HTTP 5xx)
  network,

  /// Erreur de stockage local (base SQLite, fichiers)
  storage,

  /// Erreur d'authentification (token expire, acces refuse)
  auth,

  /// Erreur de donnees (format invalide, parsing echoue)
  data,

  /// Erreur inconnue / non classifiee
  unknown,
}

/// Gestionnaire central des erreurs du Moteur GR.
///
/// Responsabilites:
/// - Logger les erreurs de facon structuree (ZERO print)
/// - Classifier les erreurs par categorie
/// - Convertir en message utilisateur i18n-ready
class ErrorHandler {
  ErrorHandler._();

  /// Log une erreur avec sa stack trace et son contexte.
  ///
  /// [error] — l'erreur attrapee
  /// [stackTrace] — la stack trace associee
  /// [context] — contexte metier (ex: "chargement etape 3")
  static void log(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final category = classify(error);
    final prefix = context != null ? '[$context] ' : '';
    _log.e(
      '${prefix}Erreur ($category): $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Classifie une erreur dans une categorie.
  ///
  /// Utilise le type de l'exception pour determiner la categorie.
  /// Les erreurs reseau, stockage et auth sont detectees automatiquement.
  static ErrorCategory classify(Object error) {
    final errorString = error.toString().toLowerCase();

    // Erreurs reseau
    if (error is FormatException && errorString.contains('http')) {
      return ErrorCategory.network;
    }
    if (errorString.contains('socketexception') ||
        errorString.contains('timeout') ||
        errorString.contains('connection refused') ||
        errorString.contains('no internet') ||
        errorString.contains('network')) {
      return ErrorCategory.network;
    }

    // Erreurs stockage
    if (errorString.contains('sqlite') ||
        errorString.contains('database') ||
        errorString.contains('drift') ||
        errorString.contains('filesystem')) {
      return ErrorCategory.storage;
    }

    // Erreurs auth
    if (errorString.contains('auth') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('token')) {
      return ErrorCategory.auth;
    }

    // Erreurs donnees
    if (error is FormatException ||
        errorString.contains('parse') ||
        errorString.contains('format') ||
        errorString.contains('invalid')) {
      return ErrorCategory.data;
    }

    return ErrorCategory.unknown;
  }

  /// Convertit une erreur en message utilisateur lisible.
  ///
  /// Retourne une cle i18n-ready basee sur la categorie de l'erreur.
  /// Le message est generique et ne contient aucun detail technique.
  static String toUserMessage(Object error) {
    final category = classify(error);
    switch (category) {
      case ErrorCategory.network:
        return 'error.network';
      case ErrorCategory.storage:
        return 'error.storage';
      case ErrorCategory.auth:
        return 'error.auth';
      case ErrorCategory.data:
        return 'error.data';
      case ErrorCategory.unknown:
        return 'error.unknown';
    }
  }
}
