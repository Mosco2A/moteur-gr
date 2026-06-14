import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:moteur_gr/features/notifications/providers/notification_provider.dart';
import 'package:moteur_gr/features/training/presentation/training_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService factice (aucun plugin réel en test).
class _FakeNotificationService implements NotificationService {
  int scheduled = 0;

  @override
  Future<int> scheduleTrainingReminder({
    required DateTime dateTime,
    required String title,
    required String body,
    int sessionIndex = 0,
  }) async {
    scheduled++;
    return sessionIndex;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Tests widget de l'écran d'entraînement (F6E-02).
///
/// Vérifie : l'affichage du plan (semaines + séances), le bandeau « local »,
/// le marquage d'une séance, et la planification de rappels LOCAUX au tap.
void main() {
  late _FakeNotificationService fake;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fake = _FakeNotificationService();
  });

  Widget wrap() => ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(fake),
        ],
        child: TranslationProvider(
          child: const MaterialApp(home: TrainingScreen()),
        ),
      );

  group('TrainingScreen', () {
    testWidgets('affiche le titre et le bandeau local', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.training.title), findsWidgets);
      expect(find.text(t.training.localNotice), findsOneWidget);
    });

    testWidgets('affiche au moins une semaine et des séances', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.training.week(n: 1)), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('marque une séance via la checkbox', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final firstCheckbox = find.byType(CheckboxListTile).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      // Au moins une checkbox est désormais cochée.
      final checked = tester
          .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
          .where((c) => c.value == true);
      expect(checked, isNotEmpty);
    });

    testWidgets('le bouton programme des rappels locaux', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.training.scheduleReminders));
      await tester.pump(); // SnackBar

      expect(fake.scheduled, greaterThan(0));
    });
  });
}
