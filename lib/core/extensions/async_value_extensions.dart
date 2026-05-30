import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../error/error_handler.dart';
import '../ui/error_view.dart';
import '../ui/loading_view.dart';

/// Extensions sur AsyncValue pour simplifier le pattern loading/error/data.
///
/// Fournit des methodes utilitaires pour gerer les 3 etats
/// d'un AsyncValue de facon homogene dans toute l'app.
extension AsyncValueUI<T> on AsyncValue<T> {
  /// Construit un widget selon l'etat de l'AsyncValue.
  ///
  /// Affiche automatiquement:
  /// - [LoadingView] pendant le chargement
  /// - [ErrorView] avec retry en cas d'erreur
  /// - Le widget [data] quand les donnees sont disponibles
  ///
  /// [onRetry] est appele quand l'utilisateur appuie sur "Reessayer".
  /// [loadingMessage] est le texte affiche pendant le chargement.
  Widget whenOrError({
    required Widget Function(T data) data,
    VoidCallback? onRetry,
    String? loadingMessage,
  }) {
    return when(
      loading: () => LoadingView(message: loadingMessage),
      error: (error, stack) {
        ErrorHandler.log(error, stackTrace: stack);
        return ErrorView(
          message: ErrorHandler.toUserMessage(error),
          onRetry: onRetry,
        );
      },
      data: data,
    );
  }
}

/// Extension pour executer une operation async avec gestion d'erreur.
///
/// Wraps une operation Future dans un try/catch avec logging automatique.
extension GuardAsync on Object {
  /// Execute [action] avec gestion d'erreur centralisee.
  ///
  /// En cas d'erreur:
  /// - Log l'erreur via [ErrorHandler]
  /// - Retourne [fallback] si fourni
  /// - Relance l'erreur sinon
  ///
  /// [context] est le contexte metier pour le logging.
  static Future<T> guardAsync<T>({
    required Future<T> Function() action,
    required String context,
    T? fallback,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      ErrorHandler.log(error, stackTrace: stackTrace, context: context);
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    }
  }
}
