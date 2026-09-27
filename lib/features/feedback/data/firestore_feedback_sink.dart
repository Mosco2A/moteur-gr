// 596 C1 — DESTINATAIRE REEL DES RETOURS UTILISATEUR, adosse a Cloud Firestore.
//
// Meme patron que [FirestoreComplaintSink] (D4C-03) : l'acces Firestore est
// isole du service, qui reste testable hors reseau, et il porte sa GARDE DE
// DISPONIBILITE (596 C4) au lieu de dereferencer `FirebaseFirestore.instance`
// a l'aveugle.
//
// CE PUITS N'EST CONSTRUIT QUE SI LE CLOUD EST LA. Sans lui, le service de
// feedback garde les messages sur le telephone ET LE DIT — il ne fait jamais
// semblant de les avoir envoyes.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/data/database.dart';
import '../../../core/firebase/cloud_indisponible.dart';
import '../../../core/firebase/firebase_service.dart';
import 'feedback_service.dart';

/// Nom de la collection des retours utilisateur.
const String kFeedbackCollection = 'user_feedback';

/// Implementation [FeedbackSink] adossee a Cloud Firestore.
class FirestoreFeedbackSink implements FeedbackSink {
  FirestoreFeedbackSink({
    required FirebaseService firebaseService,
    FirebaseFirestore? firestore,
  })  : _firebaseService = firebaseService,
        _firestore = firestore;

  final FirebaseService _firebaseService;
  FirebaseFirestore? _firestore;

  FirebaseFirestore get _db {
    if (!_firebaseService.isAvailable) {
      throw const CloudIndisponibleException('envoi d un retour utilisateur');
    }
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<void> envoyer(FeedbackQueueData feedback) async {
    // LEVE si la remise echoue : c'est le contrat de [FeedbackSink]. Un puits
    // qui avale ses erreurs recree exactement le faux succes corrige ici.
    await _db.collection(kFeedbackCollection).add(<String, dynamic>{
      'trailId': feedback.trailId,
      'type': feedback.feedbackType,
      'content': feedback.content,
      if (feedback.rating != null) 'rating': feedback.rating,
      'createdAt': feedback.createdAt.toIso8601String(),
      'receivedAt': FieldValue.serverTimestamp(),
    });
  }
}
