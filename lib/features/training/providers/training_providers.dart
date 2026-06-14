import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../notifications/providers/notification_provider.dart';
import '../domain/programme_generator.dart';
import '../models/programme_entrainement.dart';

/// Clé SharedPreferences des séances marquées comme faites (local-only).
const _prefsDoneKey = 'training_done_offsets';

/// État du programme d'entraînement (F6E-02).
///
/// Le programme est GÉNÉRÉ localement (F6E-01) et l'ensemble des séances
/// terminées est persisté UNIQUEMENT en local (SharedPreferences). AUCUNE
/// donnée de santé/perso n'est envoyée à un serveur (minimisation RGPD).
class TrainingState {
  const TrainingState({
    required this.programme,
    this.doneOffsets = const {},
  });

  /// Programme généré (séances ordonnées par jourOffset).
  final ProgrammeEntrainement programme;

  /// jourOffset des séances marquées comme faites.
  final Set<int> doneOffsets;

  /// Une séance (identifiée par son jourOffset) est-elle faite ?
  bool isDone(int jourOffset) => doneOffsets.contains(jourOffset);

  /// Nombre de séances terminées.
  int get doneCount => doneOffsets.length;

  TrainingState copyWith({
    ProgrammeEntrainement? programme,
    Set<int>? doneOffsets,
  }) {
    return TrainingState(
      programme: programme ?? this.programme,
      doneOffsets: doneOffsets ?? this.doneOffsets,
    );
  }
}

/// Paramètres de génération du programme (durée + niveau).
class TrainingParams {
  const TrainingParams({
    this.dureeSemaines = 6,
    this.niveau = NiveauEntrainement.debutant,
  });

  final int dureeSemaines;
  final NiveauEntrainement niveau;
}

/// Paramètres courants du programme (modifiable par l'UI).
final trainingParamsProvider =
    StateProvider<TrainingParams>((ref) => const TrainingParams());

/// Notifier du programme d'entraînement (F6E-02), persistance locale.
class TrainingNotifier extends Notifier<TrainingState> {
  @override
  TrainingState build() {
    final params = ref.watch(trainingParamsProvider);
    final programme = ProgrammeGenerator.generer(
      dureeSemaines: params.dureeSemaines,
      niveau: params.niveau,
    );
    // Charge l'état local (séances faites) de façon asynchrone.
    _loadDone();
    return TrainingState(programme: programme);
  }

  Future<void> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsDoneKey) ?? const [];
    final offsets = raw.map(int.tryParse).whereType<int>().toSet();
    state = state.copyWith(doneOffsets: offsets);
  }

  /// Bascule l'état « faite » d'une séance (persisté localement).
  Future<void> toggleDone(int jourOffset) async {
    final updated = Set<int>.from(state.doneOffsets);
    if (!updated.add(jourOffset)) {
      updated.remove(jourOffset);
    }
    state = state.copyWith(doneOffsets: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsDoneKey,
      updated.map((e) => e.toString()).toList(),
    );
  }

  /// Planifie des rappels LOCAUX pour les séances à venir (F6E-02).
  ///
  /// À partir de [startDate], chaque séance non terminée est planifiée à son
  /// `jourOffset` (à [hour]h). Notifications 100 % locales (pas de push).
  /// Retourne le nombre de rappels planifiés.
  Future<int> scheduleReminders({
    required DateTime startDate,
    int hour = 18,
    String Function(SeanceEntrainement seance)? titleBuilder,
    String Function(SeanceEntrainement seance)? bodyBuilder,
  }) async {
    final service = ref.read(notificationServiceProvider);
    var scheduled = 0;
    final seances = state.programme.seances;
    for (var i = 0; i < seances.length; i++) {
      final seance = seances[i];
      if (state.isDone(seance.jourOffset)) continue;
      final day = DateTime(startDate.year, startDate.month, startDate.day)
          .add(Duration(days: seance.jourOffset));
      final when = DateTime(day.year, day.month, day.day, hour);
      if (when.isBefore(DateTime.now())) continue;
      await service.scheduleTrainingReminder(
        dateTime: when,
        title: titleBuilder?.call(seance) ?? 'Séance d\'entraînement',
        body: bodyBuilder?.call(seance) ?? seance.description,
        sessionIndex: i,
      );
      scheduled++;
    }
    return scheduled;
  }
}

/// Provider du programme d'entraînement (F6E-02).
final trainingProvider =
    NotifierProvider<TrainingNotifier, TrainingState>(TrainingNotifier.new);
