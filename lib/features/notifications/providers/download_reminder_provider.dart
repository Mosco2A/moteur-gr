import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Cle de prefix pour les dates de depart en SharedPreferences.
const _departureDatePrefix = 'departure_date_';

/// Cle de prefix pour le statut des rappels.
const _reminderScheduledPrefix = 'reminder_scheduled_';

/// Etat d'un rappel de date de depart pour un sentier.
class DepartureReminderState {
  const DepartureReminderState({
    this.departureDate,
    this.isReminderScheduled = false,
  });

  /// Date de depart choisie par l'utilisateur
  final DateTime? departureDate;

  /// Indique si un rappel est planifie pour ce sentier
  final bool isReminderScheduled;

  DepartureReminderState copyWith({
    DateTime? departureDate,
    bool? isReminderScheduled,
  }) {
    return DepartureReminderState(
      departureDate: departureDate ?? this.departureDate,
      isReminderScheduled: isReminderScheduled ?? this.isReminderScheduled,
    );
  }
}

/// Notifier pour la gestion des dates de depart et rappels.
///
/// Sauvegarde les dates en SharedPreferences pour persistance
/// entre les sessions. Gere aussi le flag de rappel planifie.
class DownloadReminderNotifier extends StateNotifier<DepartureReminderState> {
  DownloadReminderNotifier(this._trailId)
      : super(const DepartureReminderState()) {
    _loadFromPrefs();
  }

  final String _trailId;

  /// Charge la date de depart et le statut du rappel depuis SharedPreferences.
  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final dateStr = prefs.getString('$_departureDatePrefix$_trailId');
    final scheduled =
        prefs.getBool('$_reminderScheduledPrefix$_trailId') ?? false;

    DateTime? date;
    if (dateStr != null) {
      date = DateTime.tryParse(dateStr);
    }

    state = DepartureReminderState(
      departureDate: date,
      isReminderScheduled: scheduled,
    );

    _log.d(
      '[DownloadReminderNotifier] Charge pour $_trailId : '
      'date=$date, scheduled=$scheduled',
    );
  }

  /// Definit la date de depart pour le sentier.
  Future<void> setDepartureDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_departureDatePrefix$_trailId',
      date.toIso8601String(),
    );

    state = state.copyWith(departureDate: date);

    _log.d(
      '[DownloadReminderNotifier] Date de depart definie pour $_trailId : $date',
    );
  }

  /// Recupere la date de depart sauvegardee.
  DateTime? getDepartureDate() => state.departureDate;

  /// Indique si un rappel est planifie.
  bool isReminderScheduled() => state.isReminderScheduled;

  /// Marque le rappel comme planifie.
  Future<void> markReminderScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_reminderScheduledPrefix$_trailId', true);
    state = state.copyWith(isReminderScheduled: true);
  }

  /// Annule le marquage du rappel.
  Future<void> clearReminderScheduled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_reminderScheduledPrefix$_trailId', false);
    state = state.copyWith(isReminderScheduled: false);
  }
}

/// Provider par sentier pour la gestion des rappels de depart.
///
/// Usage : ref.watch(downloadReminderProvider('gr20'))
final downloadReminderProvider = StateNotifierProvider.family<
    DownloadReminderNotifier, DepartureReminderState, String>(
  (ref, trailId) => DownloadReminderNotifier(trailId),
);
