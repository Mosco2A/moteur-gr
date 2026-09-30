import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../core/data/daos/feedback_queue_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/network/connectivity_monitor.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Categories de feedback disponibles.
///
/// bug, suggestion, compliment — extensible via String.
abstract class FeedbackCategory {
  static const String bug = 'bug';
  static const String suggestion = 'suggestion';
  static const String compliment = 'compliment';
  static const String fallback = suggestion;
  static const List<String> values = [bug, suggestion, compliment];

  /// Valide une categorie ; retourne fallback si inconnue.
  static String fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Statuts possibles d'un feedback dans la file Drift.
abstract class FeedbackStatus {
  static const String pending = 'pending';
  static const String sent = 'sent';
  static const String failed = 'failed';
}

/// CE QUI EST REELLEMENT ARRIVE AU RETOUR DE L'UTILISATEUR (596 C1).
///
/// L'appli ne savait dire que « oui » : `submitFeedback` rendait un booleen qui
/// valait vrai des que l'ECRITURE LOCALE avait reussi, et l'ecran affichait
/// « Merci pour votre retour ! » — pour un message qui ne partait nulle part.
enum FeedbackIssue {
  /// Remis au destinataire, pour de vrai.
  envoye,

  /// Ecrit sur ce telephone, pas encore parti : hors ligne, envoi indisponible
  /// ou refuse. Le message est conserve, jamais efface.
  gardeLocalement,

  /// Meme l'enregistrement local a echoue : rien n'a ete garde.
  echec,
}

/// DESTINATAIRE REEL D'UN RETOUR UTILISATEUR (596 C1).
///
/// Ce que l'appli n'avait pas. `_sendToBackend` attendait 10 ms et rendait
/// `true` ; le retour etait alors marque « envoye » puis EFFACE de la file par
/// `clearSent()`. Tout ce que les utilisateurs ont pu ecrire est parti a la
/// poubelle en croyant etre lu.
///
/// Tant qu'aucune implementation n'est branchee (`sink == null`), le service
/// GARDE et le dit. C'est l'etat de l'appli aujourd'hui.
abstract interface class FeedbackSink {
  /// Remet un retour au destinataire. Doit LEVER si la remise echoue —
  /// un puits qui avale les erreurs recree exactement le defaut corrige ici.
  Future<void> envoyer(FeedbackQueueData feedback);
}

/// Service offline-first de feedback.
///
/// Stocke les feedbacks dans la file Drift (FeedbackQueueDao)
/// et tente l'envoi quand la connexion est disponible ET qu'un destinataire
/// est branche. Aucun feedback n'est perdu : tout passe par la queue locale,
/// et rien n'est efface avant d'avoir ete reellement remis.
class FeedbackService {
  FeedbackService({
    required FeedbackQueueDao dao,
    required ConnectivityMonitor connectivityMonitor,
    FeedbackSink? sink,
  }) : _dao = dao,
       _connectivityMonitor = connectivityMonitor,
       _sink = sink;

  final FeedbackQueueDao _dao;
  final ConnectivityMonitor _connectivityMonitor;

  /// Destinataire reel, ou `null` quand l'envoi n'est pas ouvert.
  final FeedbackSink? _sink;

  /// Vrai si un destinataire est branche : l'appli peut alors PROMETTRE un
  /// envoi. Sinon elle doit dire qu'elle garde.
  bool get envoiPossible => _sink != null;

  /// Soumet un feedback — stocke localement, puis tente l'envoi si possible.
  ///
  /// Retourne ce qui est REELLEMENT arrive au message.
  Future<FeedbackIssue> submit({
    required String trailId,
    required String category,
    required String content,
    int? rating,
  }) async {
    final validCategory = FeedbackCategory.fromString(category);

    final int id;
    try {
      id = await _dao.addFeedback(
        FeedbackQueueCompanion(
          trailId: Value(trailId),
          feedbackType: Value(validCategory),
          content: Value(content),
          rating: Value(rating),
          createdAt: Value(DateTime.now()),
        ),
      );
    } on Object catch (e, st) {
      _log.e(
        '[FeedbackService] Enregistrement local impossible',
        error: e,
        stackTrace: st,
      );
      return FeedbackIssue.echec;
    }

    _log.d('[FeedbackService] Feedback #$id stocke (categorie=$validCategory)');

    final envoyes = await _flushIfOnline();
    return envoyes > 0 ? FeedbackIssue.envoye : FeedbackIssue.gardeLocalement;
  }

  /// Nombre de feedbacks en attente d'envoi (pending ET failed : tant qu'ils
  /// ne sont pas partis, ils attendent).
  Future<int> pendingCount() async => (await _aEnvoyer()).length;

  /// Recupere les feedbacks en attente.
  Future<List<FeedbackQueueData>> pendingFeedbacks() => _dao.getPending();

  /// Force le flush de la file d'attente (appel manuel ou reconnexion).
  Future<int> flush() async {
    if (_sink == null) {
      _log.d(
        '[FeedbackService] Flush annule — aucun destinataire branche : '
        'les retours restent sur ce telephone',
      );
      return 0;
    }
    final status = await _connectivityMonitor.checkStatus();
    if (status != ConnectivityStatusValues.online) {
      _log.d('[FeedbackService] Flush annule — hors ligne');
      return 0;
    }
    return _sendPending();
  }

  /// Tente l'envoi si la connexion est en ligne. Ne leve jamais.
  Future<int> _flushIfOnline() async {
    try {
      return await flush();
    } on Object catch (e) {
      // Pas de propagation — le feedback est deja en base, donc conserve.
      _log.d('[FeedbackService] Erreur flush auto: $e');
      return 0;
    }
  }

  /// Tout ce qui n'est pas encore parti : `pending` ET `failed`.
  ///
  /// Un retour passe « echoue » restait bloque a vie — seuls les `pending`
  /// etaient repris. Une panne reseau d'une minute condamnait le message.
  Future<List<FeedbackQueueData>> _aEnvoyer() async {
    final pending = await _dao.getPending();
    final failed = await _dao.getFailed();
    return [...pending, ...failed];
  }

  /// Envoie les feedbacks restants un par un. Marque sent ou failed.
  ///
  /// `markSent` n'est appele QU'APRES une remise reussie au destinataire, et
  /// `clearSent` n'efface donc que des messages reellement partis.
  Future<int> _sendPending() async {
    final sink = _sink;
    if (sink == null) return 0;

    var sentCount = 0;
    for (final feedback in await _aEnvoyer()) {
      try {
        await sink.envoyer(feedback);
        await _dao.markSent(feedback.id);
        sentCount++;
        _log.d('[FeedbackService] Feedback #${feedback.id} envoye');
      } on Object catch (e) {
        await _dao.markFailed(feedback.id);
        _log.d('[FeedbackService] Erreur envoi #${feedback.id}: $e');
      }
    }

    // Nettoyage des feedbacks REELLEMENT envoyes.
    if (sentCount > 0) {
      await _dao.clearSent();
      _log.d(
        '[FeedbackService] $sentCount feedback(s) envoye(s) et nettoye(s)',
      );
    }

    return sentCount;
  }
}
