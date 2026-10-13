/// Branchement Firestore des contestations, qui rattache l'UID hache du
/// plaignant exige par les regles anti-usurpation.
library;

// D4C-03 — Implementation Firestore du ComplaintSink (plaintes art 20, design
// D4 CORDO #86166). Ecrit dans la collection moderation_complaints en
// rattachant l'UID HACHE du plaignant authentifie (complainantUidHash ==
// auth.uid), exige par les regles D4C-02 (anti-usurpation). Isole de
// [ComplaintService] (pur) pour garder ce dernier testable hors reseau.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/cloud_indisponible.dart';
import '../firebase/firebase_service.dart';
import 'complaint_service.dart';

/// Nom de la collection des plaintes (cf. firestore.rules D4C-02).
const String kModerationComplaintsCollection = 'moderation_complaints';

/// Implementation [ComplaintSink] adossee a Cloud Firestore.
class FirestoreComplaintSink implements ComplaintSink {
  FirestoreComplaintSink({
    required String Function() currentUidHash,
    required FirebaseService firebaseService,
    FirebaseFirestore? firestore,
  }) : _currentUidHash = currentUidHash,
       _firebaseService = firebaseService,
       _firestore = firestore;

  /// Fournit l'UID hache de l'utilisateur authentifie (== auth.uid).
  final String Function() _currentUidHash;

  /// 596 C4 — GARDE DE DISPONIBILITE. Ce puits touchait `FirebaseFirestore
  /// .instance` sans jamais verifier que Firebase etait la. Il ne plantait que
  /// parce que le cloud etait eteint partout ; il serait devenu un plantage
  /// reel le jour de l'allumage.
  final FirebaseService _firebaseService;

  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init pour les tests).
  FirebaseFirestore get _db {
    if (!_firebaseService.isAvailable) {
      throw const CloudIndisponibleException('depot d une plainte (art. 20)');
    }
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<void> saveComplaint(ModerationComplaint complaint) async {
    // On lit `_db` EN PREMIER : refuser avant de calculer quoi que ce soit.
    final db = _db;
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
    await db.collection(kModerationComplaintsCollection).add(data);
  }
}
