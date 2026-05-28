import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/extensions/async_value_extensions.dart';
import 'package:moteur_gr/core/ui/error_view.dart';
import 'package:moteur_gr/core/ui/loading_view.dart';

void main() {
  group('AsyncValueUI.whenOrError', () {
    Widget wrapInApp(Widget child) {
      return MaterialApp(home: Scaffold(body: child));
    }

    testWidgets('affiche LoadingView quand loading', (tester) async {
      const asyncValue = AsyncValue<String>.loading();

      await tester.pumpWidget(
        wrapInApp(
          asyncValue.whenOrError(
            data: (value) => Text(value),
            loadingMessage: 'Chargement...',
          ),
        ),
      );

      expect(find.byType(LoadingView), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement...'), findsOneWidget);
    });

    testWidgets('affiche ErrorView quand error', (tester) async {
      final asyncValue = AsyncValue<String>.error(
        const SocketException('no network'),
        StackTrace.current,
      );

      var retried = false;

      await tester.pumpWidget(
        wrapInApp(
          asyncValue.whenOrError(
            data: (value) => Text(value),
            onRetry: () => retried = true,
          ),
        ),
      );

      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Reessayer'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('Reessayer'));
      expect(retried, isTrue);
    });

    testWidgets('affiche data quand data', (tester) async {
      const asyncValue = AsyncValue<String>.data('Hello GR20');

      await tester.pumpWidget(
        wrapInApp(
          asyncValue.whenOrError(
            data: (value) => Text(value),
          ),
        ),
      );

      expect(find.text('Hello GR20'), findsOneWidget);
      expect(find.byType(LoadingView), findsNothing);
      expect(find.byType(ErrorView), findsNothing);
    });
  });

  group('guardAsync', () {
    test('retourne le resultat en cas de succes', () async {
      final result = await guardAsync(
        () async => 42,
        context: 'test',
      );
      expect(result, equals(42));
    });

    test('retourne null en cas d erreur', () async {
      final result = await guardAsync<int>(
        () async => throw Exception('boom'),
        context: 'test',
      );
      expect(result, isNull);
    });

    test('ne propage pas l exception', () async {
      // Verifie que l'erreur est capturee et ne remonte pas
      await expectLater(
        guardAsync<int>(
          () async => throw Exception('boom'),
          context: 'test',
        ),
        completes,
      );
    });
  });
}
