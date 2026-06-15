// D4C-03 — Providers de l'UI de moderation hebergeur DSA (design D4 CORDO
// #86166). Pont entre le [ModerationService] (D4C-01) et les widgets de
// signalement / expose des motifs / plaintes, SANS logique serveur dans l'UI
// (les widgets delèguent ici, qui delègue au service / aux fonctions).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/services/complaint_service.dart';
import '../../../core/services/firestore_complaint_sink.dart';
import '../../../core/services/moderation_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Motifs de signalement proposes a l'utilisateur (art 16).
///
/// Liste fermee pour guider le notifiant ; le detail libre complete le motif.
/// L'ordre est stable (utilise comme cle de selection dans l'UI).
enum ReportReason {
  /// Contenu illegal (au sens du droit applicable).
  illegal,

  /// Harcelement ou incitation a la haine.
  harassment,

  /// Spam ou publicite non sollicitee.
  spam,

  /// Information dangereuse ou trompeuse (securite en montagne).
  dangerous,

  /// Autre motif (precise dans le detail libre).
  other;

  /// Cle stable (le `name` de l'enum), utilisee pour les ValueKey de l'UI.
  String get storageKey => name;
}

/// Controleur imperatif de signalement pour l'UI (D4C-03).
///
/// Encapsule l'appel a [ModerationService.reportContent] : compose le motif
/// (libelle du [ReportReason] + detail libre), valide via le service (art 16)
/// et remonte le resultat / l'erreur a l'UI. Aucune ecriture Firestore ici :
/// tout passe par le service (D4C-01) puis le store (D4C-02).
class ModerationReportController {
  ModerationReportController(this._ref);

  final Ref _ref;

  /// Envoie un signalement (art 16) pour [contentRef] de type [contentType].
  ///
  /// [reasonLabel] est le libelle localise du motif choisi (compose cote UI
  /// pour rester independant de la langue) ; [details] est le commentaire
  /// libre facultatif ; [contact] est l'e-mail du notifiant ; [goodFaith] doit
  /// etre vrai (declaration art 16). Retourne la notification creee, ou
  /// propage [InvalidModerationReport] si une mention obligatoire manque.
  Future<ModerationReport> submit({
    required ModeratedContentType contentType,
    required String contentRef,
    required String reasonLabel,
    required String details,
    required String contact,
    required bool goodFaith,
  }) {
    final service = _ref.read(moderationServiceProvider);
    final trimmedDetails = details.trim();
    final motif = trimmedDetails.isEmpty
        ? reasonLabel
        : '$reasonLabel — $trimmedDetails';
    return service.reportContent(
      contentType: contentType,
      contentRef: contentRef,
      motif: motif,
      notifierContact: contact,
      bonneFoi: goodFaith,
    );
  }
}

/// Provider du [ModerationReportController].
final moderationReportControllerProvider =
    Provider<ModerationReportController>(ModerationReportController.new);

/// Provider du sink Firestore des plaintes (D4C-03).
///
/// Rattache l'UID hache du plaignant authentifie (via [authServiceProvider]),
/// exige par les regles D4C-02. Overridable en test par un faux [ComplaintSink].
final complaintSinkProvider = Provider<ComplaintSink>((ref) {
  final auth = ref.watch(authServiceProvider);
  return FirestoreComplaintSink(
    currentUidHash: () => auth.currentUser?.uid ?? '',
  );
});

/// Provider du service de plaintes art 20 (D4C-03).
final complaintServiceProvider = Provider<ComplaintService>(
  (ref) => ComplaintService(sink: ref.watch(complaintSinkProvider)),
);

/// Controleur imperatif de plainte pour l'UI (D4C-03).
///
/// Encapsule [ComplaintService.fileComplaint] : depose une contestation (art
/// 20) et propage le resultat / l'erreur a l'ecran. Aucune ecriture Firestore
/// directe dans le widget.
class ModerationComplaintController {
  ModerationComplaintController(this._ref);

  final Ref _ref;

  /// Depose une plainte (art 20) contestant la decision sur [contentRef].
  Future<ModerationComplaint> submit({
    required ModeratedContentType contentType,
    required String contentRef,
    required String expose,
  }) {
    return _ref.read(complaintServiceProvider).fileComplaint(
          contentType: contentType,
          contentRef: contentRef,
          expose: expose,
        );
  }
}

/// Provider du [ModerationComplaintController].
final moderationComplaintControllerProvider =
    Provider<ModerationComplaintController>(
  ModerationComplaintController.new,
);
