/// L'acces aux sessions de suivi public : la seule porte du groupe vers
/// Firestore, derriere le garde `isAvailable` (lot 645-05, cas K2).
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_service.dart';

/// UNE POSITION DU RANDONNEUR SUIVI, QUI NE DOIT RIEN A FIRESTORE.
///
/// L'ecran de suivi web manipulait des `QuerySnapshot` et des `Timestamp` :
/// c'est ce qui l'obligeait a importer `cloud_firestore` depuis la couche
/// presentation (unique infraction ECR-25 du depot). Ce type-ci est du Dart
/// nu : l'ecran le lit sans savoir d'ou il vient, et le jour ou la source
/// change, l'ecran ne bouge pas.
class PositionSuivie {
  const PositionSuivie({required this.lat, required this.lng, this.horodatage});

  /// Latitude en degres decimaux.
  final double lat;

  /// Longitude en degres decimaux.
  final double lng;

  /// Horodatage de la position, quand la source en porte un.
  final DateTime? horodatage;
}

/// LE DEPOT DU SUIVI PUBLIC, ET LE GARDE EST ICI, PAS DANS L'ECRAN.
///
/// POURQUOI LE GARDE DESCEND AVEC L'ACCES. `isAvailable` protege un appel
/// Firestore ; le laisser dans l'ecran alors que l'appel descend d'une couche,
/// c'est separer la question de sa reponse — et le prochain appelant, lui,
/// n'aura aucune raison de se souvenir du garde. Les deux lectures ci-dessous
/// le portent donc chacune : sans Firebase, elles rendent la main comme si la
/// session n'existait pas, ce qui est exactement ce que l'ecran affichait deja.
class SuiviPublicDepot {
  SuiviPublicDepot({required FirebaseService firebase, FirebaseFirestore? base})
    : _firebase = firebase,
      _base = base;

  final FirebaseService _firebase;
  final FirebaseFirestore? _base;

  FirebaseFirestore get _firestore => _base ?? FirebaseFirestore.instance;

  /// L'identifiant de session derriere [codeDePartage], ou `null`.
  ///
  /// `null` couvre les quatre cas que l'ecran traite de la meme facon — lien
  /// invalide : Firebase indisponible, aucune session active pour ce code,
  /// session expiree (TTL 48 h), ou erreur de lecture.
  ///
  /// La resolution passe par le MIROIR PUBLIC MINIMAL
  /// (`follow_sessions_public` ne porte jamais `trekkerUserId` — P0-1 #327) ;
  /// le document maitre `follow_sessions` reste owner-only.
  Future<String?> resoudreSession(String codeDePartage) async {
    if (!_firebase.isAvailable) return null;
    final snapshot = await _firestore
        .collection('follow_sessions_public')
        .where('shareCode', isEqualTo: codeDePartage)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    // Session expiree (TTL 48 h) : les regles refuseront de toute facon la
    // lecture des positions — autant le dire tout de suite plutot que
    // d'afficher une carte vide.
    final expiration = doc.data()['expiresAtTs'];
    if (expiration is Timestamp &&
        !expiration.toDate().isAfter(DateTime.now())) {
      return null;
    }
    return doc.id;
  }

  /// Les positions de [sessionId], la plus recente d'abord, au fil de l'eau.
  ///
  /// Les instantanes vides et les documents sans latitude ou sans longitude ne
  /// sont pas emis : l'ecran n'a rien a en faire, et c'est ce qu'il faisait
  /// deja en rendant la main sans rien changer.
  Stream<PositionSuivie> positions(String sessionId) {
    if (!_firebase.isAvailable) return const Stream<PositionSuivie>.empty();
    return _firestore
        .collection('follow_sessions')
        .doc(sessionId)
        .collection('positions')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .expand(_positionsDe);
  }

  Iterable<PositionSuivie> _positionsDe(QuerySnapshot<Object?> snapshot) {
    if (snapshot.docs.isEmpty) return const <PositionSuivie>[];
    final donnees = snapshot.docs.first.data() as Map<String, dynamic>;
    final lat = (donnees['lat'] as num?)?.toDouble();
    final lng = (donnees['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return const <PositionSuivie>[];
    final horodatage = donnees['timestamp'];
    return <PositionSuivie>[
      PositionSuivie(
        lat: lat,
        lng: lng,
        horodatage: horodatage is Timestamp ? horodatage.toDate() : null,
      ),
    ];
  }
}

/// Le depot du suivi public, pose sur le `FirebaseService` de l'application.
final suiviPublicDepotProvider = Provider<SuiviPublicDepot>(
  (ref) => SuiviPublicDepot(firebase: ref.watch(firebaseServiceProvider)),
);
