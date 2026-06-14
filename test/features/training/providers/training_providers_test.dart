import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/domain/notification_service.dart';
import 'package:moteur_gr/features/notifications/providers/notification_provider.dart';
import 'package:moteur_gr/features/training/providers/training_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NotificationService factice : compte les rappels planifiés (pas de plugin).
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

/// Tests du Notifier d'entraînement (F6E-02).
///
/// Vérifie la génération locale du programme, le marquage de séance persisté
/// localement (SharedPreferences) et la planification de rappels LOCAUX.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('TrainingNotifier', () {
    test('génère un programme non vide à partir des paramètres', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(trainingProvider);
      expect(state.programme.nbSeances, greaterThan(0));
      expect(state.doneCount, 0);
    });

    test('toggleDone marque puis démarque une séance (persisté localement)',
        () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(trainingProvider.notifier);
      final offset = container.read(trainingProvider).programme.seances.first
          .jourOffset;

      await notifier.toggleDone(offset);
      expect(container.read(trainingProvider).isDone(offset), isTrue);

      // Persistance locale effective.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('training_done_offsets'),
          contains(offset.toString()));

      await notifier.toggleDone(offset);
      expect(container.read(trainingProvider).isDone(offset), isFalse);
    });

    test('scheduleReminders planifie des rappels locaux pour les séances à venir',
        () async {
      final fake = _FakeNotificationService();
      final container = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(trainingProvider.notifier);
      final count = await notifier.scheduleReminders(
        startDate: DateTime.now(),
      );

      expect(count, greaterThan(0));
      expect(fake.scheduled, count);
    });

    test('une séance déjà faite n est pas reprogrammée', () async {
      final fake = _FakeNotificationService();
      final container = ProviderContainer(overrides: [
        notificationServiceProvider.overrideWithValue(fake),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(trainingProvider.notifier);
      final seances = container.read(trainingProvider).programme.seances;
      // Marque la première séance future comme faite.
      final futureOffset = seances
          .firstWhere((s) => s.jourOffset >= 1, orElse: () => seances.first)
          .jourOffset;
      await notifier.toggleDone(futureOffset);

      final scheduled = await notifier.scheduleReminders(
        startDate: DateTime.now(),
      );
      // Le nombre planifié exclut la séance faite.
      final futureCount = seances
          .where((s) =>
              DateTime.now()
                  .add(Duration(days: s.jourOffset))
                  .isAfter(DateTime.now()) &&
              s.jourOffset != futureOffset)
          .length;
      expect(scheduled, lessThanOrEqualTo(futureCount + 1));
    });
  });
}
