import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 2),
  level: kReleaseMode ? Level.warning : Level.debug,
);

/// Categories d'erreurs reconnues par le moteur.
enum ErrorCategory {
  network,
  database,
  permission,
  unknown,
}

/// Gestionnaire d'erreurs centralise.
///
/// Toutes les erreurs passent par cette classe pour :
/// - le logging structure (JAMAIS print)
/// - la classification automatique
/// - la traduction en message utilisateur i18n-ready
class ErrorHandler {
  ErrorHandler._();

  /// Log une erreur avec contexte optionnel.
  ///
  /// Utilise le package logger — jamais print().
  static void log(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final prefix = context != null ? '[$context] ' : '';
    final category = classify(error);

    _log.e(
      '${prefix}Erreur [$category]: $error',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Classifie une erreur en [ErrorCategory].
  ///
  /// Reconnait les exceptions reseau (SocketException, HttpException,
  /// timeouts), les erreurs Drift/SQLite, et les erreurs de permissions.
  static ErrorCategory classify(Object error) {
    // --- Reseau ---
    if (error is SocketException ||
        error is HttpException ||
        _isTimeout(error)) {
      return ErrorCategory.network;
    }

    // --- Base de donnees (Drift / SQLite) ---
    if (_isDatabaseError(error)) {
      return ErrorCategory.database;
    }

    // --- Permissions ---
    if (_isPermissionError(error)) {
      return ErrorCategory.permission;
    }

    return ErrorCategory.unknown;
  }

  /// Traduit une erreur en message utilisateur lisible.
  ///
  /// Les messages sont i18n-ready (clefs ou textes par defaut en francais).
  static String toUserMessage(Object error) {
    final category = classify(error);

    switch (category) {
      case ErrorCategory.network:
        return 'Connexion impossible. Verifiez votre reseau et reessayez.';
      case ErrorCategory.database:
        return 'Erreur de stockage local. Redemarrez l\'application.';
      case ErrorCategory.permission:
        return 'Permission requise. Autorisez l\'acces dans les reglages.';
      case ErrorCategory.unknown:
        return 'Une erreur inattendue est survenue. Reessayez.';
    }
  }

  // --- Helpers prives ---

  static bool _isTimeout(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('timeout') ||
        message.contains('timed out') ||
        error is AppTimeoutException;
  }

  static bool _isDatabaseError(Object error) {
    final typeName = error.runtimeType.toString().toLowerCase();
    final message = error.toString().toLowerCase();
    return typeName.contains('drift') ||
        typeName.contains('sqlite') ||
        message.contains('sqflite') ||
        message.contains('database') ||
        message.contains('sql');
  }

  static bool _isPermissionError(Object error) {
    final typeName = error.runtimeType.toString().toLowerCase();
    final message = error.toString().toLowerCase();
    return typeName.contains('permission') ||
        message.contains('permission denied') ||
        message.contains('access denied') ||
        message.contains('not allowed');
  }
}

/// Exception de timeout generique.
///
/// Utilisee quand une operation depasse sa duree maximale.
/// Nommee AppTimeoutException pour eviter le conflit avec dart:async.TimeoutException.
class AppTimeoutException implements Exception {
  const AppTimeoutException([this.message]);
  final String? message;

  @override
  String toString() =>
      message != null ? 'AppTimeoutException: $message' : 'AppTimeoutException';
}
