// D4C-03 — Implementation Firestore du ComplaintSink (plaintes art 20, design
// D4 CORDO #86166). Ecrit dans la collection moderation_complaints en
// rattachant l'UID HACHE du plaignant authentifie (complainantUidHash ==
// auth.uid), exige par les regles D4C-02 (anti-usurpation). Isole de
// [ComplaintService] (pur) pour garder ce dernier testable hors reseau.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'complaint_service.dart';

/// Nom de la collection des plaintes (cf. firestore.rules D4C-02).
const String kModerationComplaintsCollection = 'moderation_complaints';

/// Implementation [ComplaintSink] adossee a Cloud Firestore.
class FirestoreComplaintSink implements ComplaintSink {
  FirestoreComplaintSink({
    required String Function() currentUidHash,
    FirebaseFirestore? firestore,
  })  : _currentUidHash = currentUidHash,
        _firestore = firestore;

  /// Fournit l'UID hache de l'utilisateur authentifie (== auth.uid).
  final String Function() _currentUidHash;

  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get _db => _firestore ??= FirebaseFirestore.instance;

  @override
  Future<void> saveComplaint(ModerationComplaint complaint) async {
    final uidHash = _currentUidHash();
    if (uidHash.isEmpty) {
      // Pas d'utilisateur authentifie : la plainte serait refusee par les
      // regles (complainantUidHash == auth.uid). On remonte clairement plutot
      // que d'ecrire un doc voue a l'echec (zero catch silencieux).
      throw StateError(
        'Plainte impossible : aucun utilisateur authentifie (art 20).',
      );
    }
    final data = <String, dynamic>{
      'complainantUidHash': uidHash,
      ...complaint.toMap(),
    };
    await _db.collection(kModerationComplaintsCollection).add(data);
  }
}
