import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

import '../error/error_handler.dart';
import '../ui/error_view.dart';
import '../ui/loading_view.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kReleaseMode ? Level.off : Level.debug,
);

/// Extensions sur [AsyncValue] pour simplifier le pattern loading/error/data.
extension AsyncValueUI<T> on AsyncValue<T> {
  /// Variante de [when] qui gere automatiquement les erreurs
  /// via [ErrorHandler] et affiche [ErrorView] + [LoadingView].
  ///
  /// Seul le cas `data` doit etre fourni par l'appelant.
  /// Les cas loading et error sont geres avec les widgets standards.
  ///
  /// ```dart
  /// asyncValue.whenOrError(
  ///   data: (value) => Text(value.toString()),
  ///   onRetry: () => ref.invalidate(myProvider),
  /// );
  /// ```
  Widget whenOrError({
    required Widget Function(T data) data,
    VoidCallback? onRetry,
    String? loadingMessage,
  }) {
    return when(
      loading: () => LoadingView(message: loadingMessage),
      error: (error, stackTrace) {
        ErrorHandler.log(error, stackTrace: stackTrace, context: 'AsyncValue');
        return ErrorView(error: error, onRetry: onRetry);
      },
      data: data,
    );
  }
}

/// Guard async pour les operations Riverpod.
///
/// Encapsule un appel async avec error handling centralise.
/// Retourne le resultat ou null en cas d'erreur (loguee automatiquement).
///
/// ```dart
/// final result = await guardAsync(
///   () => api.fetchStages(),
///   context: 'StagesProvider',
/// );
/// ```
Future<T?> guardAsync<T>(
  Future<T> Function() action, {
  String? context,
}) async {
  try {
    return await action();
  } catch (error, stackTrace) {
    ErrorHandler.log(error, stackTrace: stackTrace, context: context);
    _log.d('[guardAsync] Erreur capturee${context != null ? ' dans $context' : ''}');
    return null;
  }
}
