import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/error/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('classify', () {
      test('SocketException -> network', () {
        final error = const SocketException('Connection refused');
        expect(ErrorHandler.classify(error), ErrorCategory.network);
      });

      test('HttpException -> network', () {
        final error = const HttpException('404 Not Found');
        expect(ErrorHandler.classify(error), ErrorCategory.network);
      });

      test('AppTimeoutException -> network', () {
        final error = const AppTimeoutException('Request timed out');
        expect(ErrorHandler.classify(error), ErrorCategory.network);
      });

      test('erreur contenant "timeout" -> network', () {
        final error = Exception('Connection timed out after 30s');
        expect(ErrorHandler.classify(error), ErrorCategory.network);
      });

      test('erreur contenant "database" -> database', () {
        final error = Exception('database is locked');
        expect(ErrorHandler.classify(error), ErrorCategory.database);
      });

      test('erreur contenant "sql" -> database', () {
        final error = Exception('SQL syntax error near SELECT');
        expect(ErrorHandler.classify(error), ErrorCategory.database);
      });

      test('erreur contenant "permission denied" -> permission', () {
        final error = Exception('permission denied for location');
        expect(ErrorHandler.classify(error), ErrorCategory.permission);
      });

      test('erreur contenant "access denied" -> permission', () {
        final error = Exception('access denied to storage');
        expect(ErrorHandler.classify(error), ErrorCategory.permission);
      });

      test('erreur inconnue -> unknown', () {
        final error = Exception('quelque chose de bizarre');
        expect(ErrorHandler.classify(error), ErrorCategory.unknown);
      });

      test('FormatException -> unknown', () {
        final error = const FormatException('bad format');
        expect(ErrorHandler.classify(error), ErrorCategory.unknown);
      });
    });

    group('toUserMessage', () {
      test('network -> message connexion', () {
        final error = const SocketException('fail');
        final message = ErrorHandler.toUserMessage(error);
        expect(message, contains('Connexion impossible'));
        expect(message, contains('reseau'));
      });

      test('database -> message stockage', () {
        final error = Exception('database is locked');
        final message = ErrorHandler.toUserMessage(error);
        expect(message, contains('stockage local'));
      });

      test('permission -> message autorisation', () {
        final error = Exception('permission denied');
        final message = ErrorHandler.toUserMessage(error);
        expect(message, contains('Permission requise'));
      });

      test('unknown -> message generique', () {
        final error = Exception('wtf');
        final message = ErrorHandler.toUserMessage(error);
        expect(message, contains('inattendue'));
      });
    });

    group('log', () {
      test('log ne lance pas d exception', () {
        // Verifie que log() ne propage pas d'erreur
        expect(
          () => ErrorHandler.log(
            Exception('test error'),
            context: 'TestContext',
          ),
          returnsNormally,
        );
      });

      test('log avec stackTrace ne lance pas d exception', () {
        expect(
          () => ErrorHandler.log(
            Exception('test error'),
            stackTrace: StackTrace.current,
            context: 'TestContext',
          ),
          returnsNormally,
        );
      });
    });
  });
}
