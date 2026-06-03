import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/tester_message_model.dart';

/// F7: Service de lecture des messages testeurs depuis Firestore.
///
/// Collection `messages_testeurs` — lecture seule depuis l'app.
/// DEC-048: includeMetadataChanges + filtre isFromCache.
class TesterMessageService {
  TesterMessageService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Stream des messages actifs, filtres par cible (all, plateforme, uid).
  ///
  /// Filtre cote client apres reception des messages actifs:
  /// - actif == true
  /// - cible match: all, plateforme courante (android/ios), ou uid specifique
  /// - Si type update avec version_min: compare avec version installee
  Stream<List<TesterMessage>> watchActiveMessages({
    required String uid,
    required String appVersion,
  }) {
    final platform = Platform.isAndroid ? 'android' : 'ios';

    // DEC-048: includeMetadataChanges + filtre isFromCache
    return _firestore
        .collection(AppConstants.collectionTesterMessages)
        .where('actif', isEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .where((snapshot) => !snapshot.metadata.isFromCache)
        .map((snapshot) {
      final messages = <TesterMessage>[];

      for (final doc in snapshot.docs) {
        final message = TesterMessage.fromFirestore(doc);

        // Filtre par cible
        if (!_matchesCible(message, uid, platform)) continue;

        // Filtre version: si type update avec version_min,
        // ne garder que si version installee < version_min
        if (message.type == TesterMessageType.update &&
            message.versionMin != null &&
            message.versionMin!.isNotEmpty) {
          if (!isVersionBelow(appVersion, message.versionMin!)) continue;
        }

        messages.add(message);
      }

      // Trier par date decroissante (plus recent en premier)
      messages.sort((a, b) => b.date.compareTo(a.date));
      return messages;
    });
  }

  /// Verifie si un message correspond a la cible courante.
  bool _matchesCible(TesterMessage message, String uid, String platform) {
    switch (message.cible) {
      case TesterMessageTarget.all:
        return true;
      case TesterMessageTarget.android:
        return platform == 'android';
      case TesterMessageTarget.ios:
        return platform == 'ios';
      case TesterMessageTarget.uid:
        return message.cibleUid == uid;
    }
  }

  /// Ecrit la version de l'app et la plateforme dans users/{uid}.
  ///
  /// Utilise set avec merge pour ne pas ecraser les autres champs.
  /// Appele au lancement de l'app (fire-and-forget).
  Future<void> writeAppVersion({required String uid}) async {
    try {
      // #267: Ne pas ecrire dans users/{uid} tant que le profil n'est pas complete.
      // Empeche la creation de documents fantomes par les sessions anonymes.
      final userDoc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .get();
      if (!userDoc.exists || userDoc.data()?['profileCompleted'] != true) {
        return;
      }

      final info = await PackageInfo.fromPlatform();
      final version = '${info.version}+${info.buildNumber}';
      final platform = Platform.isAndroid ? 'android' : 'ios';

      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .set({
        'app_version': version,
        'platform': platform,
        'last_seen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Silencieux — pas critique, best effort
    }
  }
}
