import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/feedback_queue_dao.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../data/feedback_service.dart';
import '../data/firestore_feedback_sink.dart';

/// Provider du DAO feedback
final feedbackQueueDaoProvider = Provider<FeedbackQueueDao>((ref) {
  return FeedbackQueueDao(ref.watch(databaseProvider));
});

/// Destinataire des retours — `null` tant que le cloud n'est pas configure.
///
/// 596 C1 : c'est LA piece qui manquait. Tant qu'elle vaut `null`, l'appli sait
/// qu'elle ne peut pas envoyer, et elle le DIT a l'utilisateur au lieu de le
/// remercier pour un message qui ne partira pas.
final feedbackSinkProvider = Provider<FeedbackSink?>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  if (!firebase.isAvailable) return null;
  return FirestoreFeedbackSink(firebaseService: firebase);
});

/// Service de feedback reel — UN SEUL chemin d'envoi pour toute l'appli.
///
/// Le notifier faisait sa propre « simulation d'envoi » dans son coin pendant
/// que [FeedbackService] existait sans etre branche nulle part. Deux etages qui
/// mentaient separement ; il n'y en a plus qu'un, et il dit la verite.
final feedbackServiceProvider = Provider<FeedbackService>((ref) {
  return FeedbackService(
    dao: ref.watch(feedbackQueueDaoProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
    sink: ref.watch(feedbackSinkProvider),
  );
});

/// Types de feedback disponibles.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef FeedbackType = String;

/// Valeurs connues pour FeedbackType avec fallback generique.
abstract class FeedbackTypeValues {
  static const String bug = 'bug';
  static const String suggestion = 'suggestion';
  static const String question = 'question';
  static const String compliment = 'compliment';
  static const String other = 'other';
  static const String fallback = other;
  static const List<String> values = [bug, suggestion, compliment, question, other];

  static const Map<String, String> labels = {
    bug: 'Bug / Probleme',
    suggestion: 'Suggestion',
    compliment: 'Compliment',
    question: 'Question',
    other: 'Autre',
  };

  static String labelFor(String type) => labels[type] ?? type;
  static FeedbackType fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Etat du formulaire de feedback
class FeedbackState {
  const FeedbackState({
    this.pendingCount = 0,
    this.isSubmitting = false,
    this.derniereIssue,
    this.envoiPossible = false,
  });

  final int pendingCount;
  final bool isSubmitting;

  /// CE QUI EST REELLEMENT ARRIVE au dernier retour soumis (596 C1).
  ///
  /// Remplace `lastSubmitSuccess`, un booleen qui valait vrai des que
  /// l'ECRITURE LOCALE avait reussi — et sur lequel l'ecran affichait
  /// « Merci pour votre retour ! » pour un message qui ne partait nulle part.
  final FeedbackIssue? derniereIssue;

  /// Vrai si un destinataire est branche. Faux => l'appli doit annoncer
  /// qu'elle garde les retours sur le telephone.
  final bool envoiPossible;

  FeedbackState copyWith({
    int? pendingCount,
    bool? isSubmitting,
    FeedbackIssue? derniereIssue,
    bool? envoiPossible,
  }) {
    return FeedbackState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      derniereIssue: derniereIssue,
      envoiPossible: envoiPossible ?? this.envoiPossible,
    );
  }
}

/// Notifier des retours utilisateur — PLUS AUCUNE SIMULATION D'ENVOI (596 C1).
///
/// CE QUI ETAIT LA :
/// ```dart
/// Future<void> _trySendPending() async {
///   for (final feedback in await _dao.getPending()) {
///     // Simulation d'envoi (pas de backend Firebase)
///     // En production, appeler l'API ici
///     await _dao.markSent(feedback.id);
///   }
/// }
/// ```
/// Chaque retour etait declare envoye sans qu'aucun octet ne quitte le
/// telephone, et l'ecran remerciait. Le notifier refaisait par ailleurs, en
/// pire, le travail de [FeedbackService] — qui existait et n'etait branche
/// nulle part. Il n'y a plus qu'UN chemin d'envoi, et il dit la verite.
class FeedbackNotifier extends Notifier<FeedbackState> {
  late FeedbackService _service;
  late String _trailId;

  @override
  FeedbackState build() {
    _service = ref.watch(feedbackServiceProvider);
    _trailId = ref.read(trailIdProvider);
    // L'etat du reseau reconstruit le notifier : un retour garde hors ligne
    // repart tout seul au retour de la connexion.
    ref.watch(connectivityProvider.select(
        (asyncVal) => asyncVal.value ?? ConnectivityStatusValues.offline));
    _loadPendingCount();
    return FeedbackState(envoiPossible: _service.envoiPossible);
  }

  Future<void> _loadPendingCount() async {
    final count = await _service.pendingCount();
    if (!ref.mounted) return;
    state = state.copyWith(pendingCount: count);
  }

  /// Soumet un retour et rend CE QUI LUI EST REELLEMENT ARRIVE.
  Future<FeedbackIssue> submitFeedback({
    required FeedbackType type,
    required String content,
    int? rating,
  }) async {
    state = state.copyWith(isSubmitting: true);

    final issue = await _service.submit(
      trailId: _trailId,
      category: type,
      content: content,
      rating: rating,
    );

    if (!ref.mounted) return issue;
    await _loadPendingCount();
    if (!ref.mounted) return issue;
    state = state.copyWith(isSubmitting: false, derniereIssue: issue);
    return issue;
  }

  /// Force le renvoi des retours encore sur le telephone.
  ///
  /// Rend le nombre de retours REELLEMENT partis (zero quand aucun
  /// destinataire n'est branche).
  Future<int> retrySendPending() async {
    final envoyes = await _service.flush();
    if (!ref.mounted) return envoyes;
    await _loadPendingCount();
    return envoyes;
  }
}

/// Provider du feedback pour le sentier actif
final feedbackProvider =
    NotifierProvider<FeedbackNotifier, FeedbackState>(FeedbackNotifier.new);
