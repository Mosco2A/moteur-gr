// D4C-03 — Service de plaintes / contestations DSA art 20 (design D4 CORDO
// #86166). Systeme INTERNE de traitement des plaintes : un utilisateur peut
// contester une decision de moderation le concernant. La plainte est
// enregistree (collection moderation_complaints, regles D4C-02) au statut
// 'ouverte' et sera examinee par un moderateur.
//
// Pur (sans dependance Firebase) pour rester testable : la persistance est
// abstraite par [ComplaintSink] (impl Firestore en prod, faux en test).
// ZERO catch silencieux : une plainte vide ou une erreur de persistance
// remonte a l'UI.

import 'moderation_service.dart';

/// Plainte / contestation d'une decision de moderation (art 20), immuable.
class ModerationComplaint {
  ModerationComplaint({
    required this.contentType,
    required this.contentRef,
    required this.expose,
    required this.createdAt,
    this.status = 'ouverte',
  });

  /// Type du contenu vise par la decision contestee.
  final ModeratedContentType contentType;

  /// Reference du contenu vise.
  final String contentRef;

  /// Expose des arguments du plaignant (art 20).
  final String expose;

  /// Horodatage de depot de la plainte.
  final DateTime createdAt;

  /// Statut de la plainte (ouverte / en_examen / tranchee).
  final String status;

  /// Serialise la plainte (sans l'UID du plaignant, ajoute par le sink qui
  /// connait l'utilisateur authentifie — anti-usurpation cote regles D4C-02).
  Map<String, dynamic> toMap() => <String, dynamic>{
        'contentType': contentType.collectionName,
        'contentRef': contentRef,
        'expose': expose,
        'createdAt': createdAt,
        'status': status,
      };
}

/// Exception levee quand une plainte est invalide (expose vide).
class InvalidComplaint implements Exception {
  const InvalidComplaint(this.message);

  /// Description du probleme.
  final String message;

  @override
  String toString() => 'InvalidComplaint: $message';
}

/// Contrat de persistance d'une plainte (abstrait le backend Firestore).
abstract class ComplaintSink {
  /// Persiste une plainte. L'implementation rattache l'UID hache du plaignant
  /// authentifie (complainantUidHash == auth.uid, exige par les regles D4C-02).
  Future<void> saveComplaint(ModerationComplaint complaint);
}

/// Service de plaintes art 20 (D4C-03).
class ComplaintService {
  ComplaintService({
    required ComplaintSink sink,
    DateTime Function()? now,
  })  : _sink = sink,
        _now = now ?? DateTime.now;

  final ComplaintSink _sink;
  final DateTime Function() _now;

  /// Depose une plainte (art 20). Valide l'expose (non vide), cree la plainte
  /// horodatee au statut 'ouverte' et la persiste.
  ///
  /// Leve [InvalidComplaint] si l'expose est vide (zero catch silencieux).
  Future<ModerationComplaint> fileComplaint({
    required ModeratedContentType contentType,
    required String contentRef,
    required String expose,
  }) async {
    final trimmed = expose.trim();
    if (trimmed.isEmpty) {
      throw const InvalidComplaint('expose vide (art 20)');
    }
    final complaint = ModerationComplaint(
      contentType: contentType,
      contentRef: contentRef.trim(),
      expose: trimmed,
      createdAt: _now(),
    );
    await _sink.saveComplaint(complaint);
    return complaint;
  }
}
