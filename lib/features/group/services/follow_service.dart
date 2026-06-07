import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/follow_links_config.dart';
import '../../../core/firebase/firebase_service.dart';
import '../models/follow_session.dart';
import '../models/follower_slot.dart';
import '../models/share_link.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const _codeLength = 6;

/// Nombre de suiveurs gratuits par session (#81759).
/// Au-dela, le suiveur voit de la publicite ou doit payer.
const kMaxFreeFollowers = 2;

/// Service de partage de position en temps reel (E4.11).
///
/// Permet au randonneur de creer une session de suivi,
/// ajouter des suiveurs (2 gratuits, au-dela pub #81759),
/// publier sa position vers Firestore et generer des liens
/// de partage sur les 3 canaux (#81753).
///
/// E4.11 — Dependances: E4.10 (modeles suivi), E4.1b (Auth),
/// E4.2a (Firestore).
class FollowService {
  FollowService({
    required this.firebaseService,
    this.linksConfig = const FollowLinksConfig(),
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  final FirebaseService firebaseService;

  /// Bases d URL des liens de partage (injectees, jamais en dur).
  final FollowLinksConfig linksConfig;

  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;

  static const _uuid = Uuid();

  /// Indique si un suiveur supplementaire reste gratuit.
  ///
  /// Les [kMaxFreeFollowers] premiers slots sont gratuits (#81759) ;
  /// au-dela, le suiveur passe par la pub ou un pass payant.
  bool canAddFreeFollower(int currentCount) => currentCount < kMaxFreeFollowers;

  /// Cree une session de suivi avec un shareCode unique de 6 caracteres.
  ///
  /// Ecrit le document maitre follow_sessions/{id} (prive, owner-only)
  /// puis le miroir public minimal follow_sessions_public/{id} qui ne
  /// porte QUE shareCode/isActive/expiresAtTs — jamais trekkerUserId
  /// (P0-1 audit #327). Les regles Firestore ne sachant pas parser les
  /// dates ISO-8601 du modele, l expiration TTL 48h est doublee d un
  /// champ Timestamp natif expiresAtTs sur les deux documents.
  ///
  /// Retourne la [FollowSession] creee ou null si Firebase indisponible.
  Future<FollowSession?> createSession({required String trekkerUserId}) async {
    if (!firebaseService.isAvailable) return null;

    final sessionId = _uuid.v4();
    final shareCode = _generateShareCode();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 48));

    final session = FollowSession(
      id: sessionId,
      trekkerUserId: trekkerUserId,
      shareCode: shareCode,
      createdAt: now.toIso8601String(),
      expiresAt: expiresAt.toIso8601String(),
      isActive: true,
    );

    try {
      await firestore.collection('follow_sessions').doc(sessionId).set({
        ...session.toJson(),
        'expiresAtTs': Timestamp.fromDate(expiresAt),
      });
    } catch (e) {
      _log.e('[FollowService] Erreur createSession: $e');
      return null;
    }

    try {
      await firestore
          .collection('follow_sessions_public')
          .doc(sessionId)
          .set({
        'shareCode': shareCode,
        'isActive': true,
        'expiresAtTs': Timestamp.fromDate(expiresAt),
      });
    } catch (e) {
      // Sans miroir public, le suiveur ne peut pas resoudre le shareCode :
      // rollback best-effort du document maitre pour ne pas laisser une
      // session orpheline.
      _log.e('[FollowService] Erreur miroir public: $e');
      try {
        await firestore.collection('follow_sessions').doc(sessionId).delete();
      } catch (_) {}
      return null;
    }

    _log.i('[FollowService] Session creee: $shareCode');
    return session;
  }

  /// Ajoute un suiveur a la session. Max [kMaxFreeFollowers] gratuits.
  ///
  /// Retourne le [FollowerSlot] cree, ou null si la limite gratuite
  /// est atteinte (sans pub ni paiement) ou si Firebase est indisponible.
  Future<FollowerSlot?> addFollower({
    required String sessionId,
    required String name,
  }) async {
    if (!firebaseService.isAvailable) return null;

    try {
      // Compter les suiveurs existants
      final snapshot = await firestore
          .collection('follow_sessions')
          .doc(sessionId)
          .collection('followers')
          .get();

      final currentCount = snapshot.docs.length;

      if (!canAddFreeFollower(currentCount)) {
        _log.w('[FollowService] Limite $kMaxFreeFollowers suiveurs gratuits '
            'atteinte pour session $sessionId');
        return null;
      }

      final slotId = _uuid.v4();
      final slot = FollowerSlot(
        id: slotId,
        sessionId: sessionId,
        followerName: name,
        isPaid: false,
        adSupported: false,
      );

      await firestore
          .collection('follow_sessions')
          .doc(sessionId)
          .collection('followers')
          .doc(slotId)
          .set(slot.toJson());

      _log.i('[FollowService] Suiveur ajoute: $name '
          '(${currentCount + 1}/$kMaxFreeFollowers)');
      return slot;
    } catch (e) {
      _log.e('[FollowService] Erreur addFollower: $e');
      return null;
    }
  }

  /// Publie la position du randonneur vers Firestore.
  ///
  /// Ecrit dans follow_sessions/{sessionId}/positions.
  Future<bool> publishPosition({
    required String sessionId,
    required double lat,
    required double lng,
  }) async {
    if (!firebaseService.isAvailable) return false;

    try {
      await firestore
          .collection('follow_sessions')
          .doc(sessionId)
          .collection('positions')
          .add({
        'lat': lat,
        'lng': lng,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _log.e('[FollowService] Erreur publishPosition: $e');
      return false;
    }
  }

  /// Genere un lien de partage sur l un des 3 canaux (#81753).
  ///
  /// [type] : ShareLinkTypeValues.app (deeplink), .web (page web),
  /// .companionApp (application complementaire). Valeur inconnue ->
  /// fallback web. Les bases d URL viennent de [linksConfig].
  ShareLink generateShareLink({
    required String sessionId,
    required String shareCode,
    ShareLinkType type = ShareLinkTypeValues.web,
  }) {
    final resolvedType = ShareLinkTypeValues.fromString(type);
    final String url;

    switch (resolvedType) {
      case ShareLinkTypeValues.app:
        url = linksConfig.appLink(shareCode);
      case ShareLinkTypeValues.companionApp:
        url = linksConfig.companionLink(shareCode);
      default:
        url = linksConfig.webLink(shareCode);
    }

    return ShareLink(
      id: _uuid.v4(),
      sessionId: sessionId,
      type: resolvedType,
      url: url,
      activatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Genere les liens de partage des 3 canaux d un coup (#81753).
  List<ShareLink> generateAllShareLinks({
    required String sessionId,
    required String shareCode,
  }) {
    return [
      for (final type in ShareLinkTypeValues.values)
        generateShareLink(
          sessionId: sessionId,
          shareCode: shareCode,
          type: type,
        ),
    ];
  }

  /// Genere un shareCode unique de 6 caracteres alphanumeriques.
  ///
  /// Utilise un jeu de caracteres sans ambiguite (pas de O/0, I/1).
  String _generateShareCode() {
    final random = Random.secure();
    return List.generate(
      _codeLength,
      (_) => _codeChars[random.nextInt(_codeChars.length)],
    ).join();
  }
}

/// Provider Riverpod pour le [FollowService].
final followServiceProvider = Provider<FollowService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final links = ref.watch(followLinksConfigProvider);
  return FollowService(firebaseService: firebase, linksConfig: links);
});
