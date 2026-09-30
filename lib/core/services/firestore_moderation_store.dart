// D4C-01 — Implementation Firestore du ModerationStore (design D4 CORDO
// #86166). Branche le mecanisme notice-and-action (art 16) sur Firestore :
//   - ecrit les notifications dans la collection `reports_moderation` (regles
//     et workflow moderateur en D4C-02) ;
//   - applique la transition de moderationState au contenu cible
//     (trail_reports / activities / waypoints / waypoint_comments).
//
// Isole de [ModerationService] (qui reste pur, sans dependance Firebase, donc
// testable hors reseau) sur le meme principe que la logique de classement
// (ranking.js cote Cloud Functions). En prod, l'ecriture du moderationState du
// contenu cible est normalement portee par la Cloud Function moderateur
// (D4C-02, privileges moderateur) ; cote client, [applyContentState] sert au
// chemin direct moderateur authentifie (les regles refusent un non-moderateur).

import 'package:cloud_firestore/cloud_firestore.dart';

import '../firebase/cloud_indisponible.dart';
import '../firebase/firebase_service.dart';
import 'moderation_service.dart';

/// Nom de la collection des notifications de moderation (cf. firestore.rules
/// D4C-02 : create par tout utilisateur authentifie, read/update moderateur).
const String kReportsModerationCollection = 'reports_moderation';

/// Implementation [ModerationStore] adossee a Cloud Firestore.
class FirestoreModerationStore implements ModerationStore {
  FirestoreModerationStore({
    required FirebaseService firebaseService,
    FirebaseFirestore? firestore,
  }) : _firebaseService = firebaseService,
       _firestore = firestore;

  /// 596 C4 — GARDE DE DISPONIBILITE. Les trois ecritures de ce magasin
  /// (`saveReport`, `updateReport`, `applyContentState`) dereferencaient
  /// `FirebaseFirestore.instance` sans aucune verification : c'est le chemin
  /// « Signaler » d'un contenu, construit inconditionnellement par les
  /// providers. Il ne plantait que parce que Firebase etait eteint partout.
  final FirebaseService _firebaseService;

  FirebaseFirestore? _firestore;

  /// Accesseur Firestore (lazy init, comme [CloudSyncService], pour les tests).
  FirebaseFirestore get _db {
    if (!_firebaseService.isAvailable) {
      throw const CloudIndisponibleException('moderation d un contenu');
    }
    return _firestore ??= FirebaseFirestore.instance;
  }

  @override
  Future<void> saveReport(ModerationReport report) async {
    // Le doc id est celui du rapport (genere par le service / Firestore).
    await _db
        .collection(kReportsModerationCollection)
        .doc(report.id)
        .set(report.toMap());
  }

  @override
  Future<void> updateReport(ModerationReport report) async {
    final data = <String, dynamic>{
      'status': report.status.wireValue,
      if (report.decision != null) 'decision': report.decision!.name,
    };
    await _db
        .collection(kReportsModerationCollection)
        .doc(report.id)
        .update(data);
  }

  @override
  Future<void> applyContentState(
    ModeratedContentType contentType,
    String contentRef,
    ContentModerationState state,
  ) async {
    // Transition A POSTERIORI du moderationState du contenu cible. Les regles
    // (D4C-02) garantissent que SEUL un moderateur peut muter ce champ, et que
    // seul moderationState bouge (contenu utilisateur immuable).
    await _db.collection(contentType.collectionName).doc(contentRef).update(
      <String, dynamic>{'moderationState': state.wireValue},
    );
  }
}
