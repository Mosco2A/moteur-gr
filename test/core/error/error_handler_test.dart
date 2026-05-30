import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/error/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('classify', () {
      test('classifie les erreurs reseau correctement', () {
        expect(
          ErrorHandler.classify(Exception('SocketException: connection refused')),
          equals(ErrorCategory.network),
        );
        expect(
          ErrorHandler.classify(Exception('timeout after 30 seconds')),
          equals(ErrorCategory.network),
        );
      });

      test('classifie les erreurs stockage correctement', () {
        expect(
          ErrorHandler.classify(Exception('sqlite error: table not found')),
          equals(ErrorCategory.storage),
        );
        expect(
          ErrorHandler.classify(Exception('database is locked')),
          equals(ErrorCategory.storage),
        );
      });

      test('classifie les erreurs auth correctement', () {
        expect(
          ErrorHandler.classify(Exception('unauthorized access')),
          equals(ErrorCategory.auth),
        );
        expect(
          ErrorHandler.classify(Exception('token expired')),
          equals(ErrorCategory.auth),
        );
      });

      test('classifie les erreurs de donnees correctement', () {
        expect(
          ErrorHandler.classify(const FormatException('invalid JSON')),
          equals(ErrorCategory.data),
        );
      });

      test('retourne unknown pour erreurs non classifiees', () {
        expect(
          ErrorHandler.classify(Exception('something unexpected')),
          equals(ErrorCategory.unknown),
        );
      });
    });

    group('toUserMessage', () {
      test('retourne une cle i18n selon la categorie', () {
        expect(
          ErrorHandler.toUserMessage(Exception('timeout')),
          equals('error.network'),
        );
        expect(
          ErrorHandler.toUserMessage(Exception('sqlite')),
          equals('error.storage'),
        );
        expect(
          ErrorHandler.toUserMessage(Exception('random')),
          equals('error.unknown'),
        );
      });
    });
  });
}
