import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/notifications/providers/notification_scheduler.dart';

/// Test du scheduler de notifications E3.8b.
///
/// Valide que la date J-2 est correctement calculee
/// (2 jours avant la date de depart).
void main() {
  group('NotificationScheduler', () {
    test('computeCountdownDate retourne J-2 correct', () {
      // Depart le 15 juillet 2026
      final departureDate = DateTime(2026, 7, 15, 8, 0);

      final countdownDate = computeCountdownDate(departureDate);

      // J-2 = 13 juillet 2026
      expect(countdownDate.year, 2026);
      expect(countdownDate.month, 7);
      expect(countdownDate.day, 13);
      expect(countdownDate.hour, 8);
      expect(countdownDate.minute, 0);

      // Verifier que c est bien exactement 2 jours avant
      final diff = departureDate.difference(countdownDate);
      expect(diff.inDays, 2);
    });

    test('computeCountdownDate fonctionne au passage de mois', () {
      // Depart le 2 aout 2026
      final departureDate = DateTime(2026, 8, 2);

      final countdownDate = computeCountdownDate(departureDate);

      // J-2 = 31 juillet 2026
      expect(countdownDate.year, 2026);
      expect(countdownDate.month, 7);
      expect(countdownDate.day, 31);
    });

    test('NotificationSchedulerState a les bonnes valeurs par defaut', () {
      const state = NotificationSchedulerState();

      expect(state.departureDate, isNull);
      expect(state.trekDurationDays, 0);
      expect(state.countdownScheduled, false);
      expect(state.dailyRemindersCount, 0);
    });

    test('NotificationSchedulerState copyWith fonctionne correctement', () {
      const state = NotificationSchedulerState();
      final departure = DateTime(2026, 7, 15);

      final updated = state.copyWith(
        departureDate: departure,
        trekDurationDays: 5,
        countdownScheduled: true,
        dailyRemindersCount: 3,
      );

      expect(updated.departureDate, departure);
      expect(updated.trekDurationDays, 5);
      expect(updated.countdownScheduled, true);
      expect(updated.dailyRemindersCount, 3);
    });
  });
}
