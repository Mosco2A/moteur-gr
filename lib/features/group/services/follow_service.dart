/// Ce qu'on remet au marcheur quand il partage : le lien ET le verdict dans le
/// MEME objet, jamais l'un sans l'autre.
library;

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
import 'verificateur_cible_suivi.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const _codeLength = 6;

/// Nombre de suiveurs gratuits par session (#81759).
/// Au-dela, le suiveur voit de la publicite ou doit payer.
const kMaxFreeFollowers = 2;

/// CE QU'ON REMET AU RANDONNEUR QUAND IL PARTAGE — LE LIEN ET LE VERDICT
/// ENSEMBLE, JAMAIS L'UN SANS L'AUTRE (tache 623).
///
/// POURQUOI LES DEUX SONT DANS LE MEME OBJET. Le defaut mesure par Skynet le
/// 28/09 n'etait pas une mauvaise adresse : c'etait qu'un lien pouvait circuler
/// SANS que personne n'ait verifie qu'il menait quelque part. Separer le lien de
/// son verdict permettrait a un appelant de prendre le premier et d'ignorer le
/// second — c'est-a-dire de reproduire le defaut exactement. Ici, obtenir le lien
/// oblige a tenir le verdict dans la main.
class PartageSuivi {
  const PartageSuivi({required this.lien, required this.verdict});

  /// Le lien a remettre aux proches, ou `null` quand il ne pourrait pas servir
  /// (canal absent, cible qui repond non, reseau absent).
  final ShareLink? lien;

  /// Ce que la cible a repondu, et pourquoi.
  final VerdictCibleSuivi verdict;

  /// Vrai quand il y a un lien ET que la cible a repondu oui. C'est la SEULE
  /// condition dans laquelle on peut dire au randonneur que ses proches pourront
  /// le suivre.
  bool get partageable => lien != null && verdict.joignable;

  /// Ce que la cible a repondu, en un mot (raccourci de lecture).
  DisponibiliteCibleSuivi get disponibilite => verdict.disponibilite;
}

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
    VerificateurCibleSuivi? verificateurCible,
  }) : _firestore = firestore,
       verificateurCible = verificateurCible ?? VerificateurCibleSuivi();

  final FirebaseService firebaseService;

  /// Bases d URL des liens de partage (injectees, jamais en dur).
  final FollowLinksConfig linksConfig;

  /// LA MESURE DE LA CIBLE, AU MOMENT DU PARTAGE (tache 623).
  ///
  /// Construit par defaut, mais il ne touche NI le reseau NI un greffon tant
  /// qu'un canal n'a pas d'adresse — et le depot n'en porte aucune. Dans
  /// `flutter test`, aucune mesure n'est donc emise par defaut, et un test de ce
  /// lot le prouve.
  final VerificateurCibleSuivi verificateurCible;

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
      await firestore.collection('follow_sessions_public').doc(sessionId).set({
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
        _log.w(
          '[FollowService] Limite $kMaxFreeFollowers suiveurs gratuits '
          'atteinte pour session $sessionId',
        );
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

      _log.i(
        '[FollowService] Suiveur ajoute: $name '
        '(${currentCount + 1}/$kMaxFreeFollowers)',
      );
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
  ///
  /// REND `null` QUAND LE CANAL N'A PAS D'ADRESSE DANS CE BUILD (tache 623), et
  /// c'est le premier des deux verrous contre le lien mort en silence. Avant ce
  /// lot, cette methode rendait TOUJOURS une chaine d'allure parfaite —
  /// `https://<projet-inexistant>/follow/AB3C7D` — et c'est exactement ce qui a
  /// permis au defaut de vivre : l'interface n'avait aucun moyen de savoir que
  /// le lien qu'elle affichait ne menait nulle part. Un appelant doit desormais
  /// traiter le `null`, et il ne peut plus afficher un lien fabrique a partir de
  /// rien. Voir `FollowLinksConfig` pour la mesure du 28/09.
  ///
  /// ELLE NE MESURE PAS LA CIBLE : elle ne fait pas d'appel reseau et ne peut
  /// donc pas savoir si l'adresse REPOND. C'est [preparerPartage] qu'il faut
  /// appeler pour remettre un lien au randonneur.
  ShareLink? generateShareLink({
    required String sessionId,
    required String shareCode,
    ShareLinkType type = ShareLinkTypeValues.web,
  }) {
    final resolvedType = ShareLinkTypeValues.fromString(type);
    final url = linksConfig.lien(canalDe(resolvedType), shareCode);
    if (url == null) {
      _log.w(
        '[FollowService] Canal $resolvedType sans adresse dans ce build : '
        'aucun lien produit (variables ${FollowLinksConfig.variableAppBase} / '
        '${FollowLinksConfig.variableWebBase} / '
        '${FollowLinksConfig.variableCompagnonBase})',
      );
      return null;
    }

    return ShareLink(
      id: _uuid.v4(),
      sessionId: sessionId,
      type: resolvedType,
      url: url,
      activatedAt: DateTime.now().toIso8601String(),
    );
  }

  /// Genere les liens de partage des canaux CONFIGURES (#81753).
  ///
  /// La liste ne contient plus systematiquement trois entrees : un canal sans
  /// adresse dans ce build n'y figure pas du tout. Un canal absent est plus
  /// honnete qu'un canal present avec un lien mort — et dans le depot, ou aucune
  /// adresse n'est ecrite, cette liste est VIDE. C'est voulu : c'est l'etat reel.
  List<ShareLink> generateAllShareLinks({
    required String sessionId,
    required String shareCode,
  }) {
    final liens = <ShareLink>[];
    for (final type in ShareLinkTypeValues.values) {
      final lien = generateShareLink(
        sessionId: sessionId,
        shareCode: shareCode,
        type: type,
      );
      if (lien != null) liens.add(lien);
    }
    return liens;
  }

  /// PREPARE UN PARTAGE : LE LIEN, ET CE QUE LA CIBLE A REPONDU (tache 623).
  ///
  /// C'EST LA METHODE QU'UNE INTERFACE DE PARTAGE DOIT APPELER, et pas
  /// [generateShareLink] seule. La raison est le defaut mesure par Skynet le
  /// 28/09 : l'adresse du canal web rendait 404, le randonneur partageait sa
  /// position, personne ne pouvait le suivre, ET RIEN NE LE LUI DISAIT. Il ne
  /// l'apprenait pas plus tard : il ne l'apprenait jamais.
  ///
  /// LE LIEN N'EST REMIS QUE S'IL PEUT SERVIR. Trois verdicts ne rendent AUCUN
  /// lien, et chacun pour une raison differente qui doit etre dite au randonneur
  /// dans des mots differents :
  ///
  ///  * `nonConfiguree` — ce canal n'existe pas dans cette version. Ce n'est pas
  ///    une panne.
  ///  * `injoignable` — la cible a repondu non. C'est l'etat mesure le 28/09.
  ///  * `reseauIndisponible` — nous n'avons pas pu demander. Et rendre le lien
  ///    quand meme n'aurait aucun sens ici, pour une raison MESUREE dans ce
  ///    fichier et non par principe : [createSession] rend `null` et
  ///    [publishPosition] rend `false` quand Firebase est indisponible. Un
  ///    randonneur hors reseau n'a donc PAS de session a partager — il n'y a
  ///    aucun `shareCode` a mettre dans un lien.
  ///
  /// `nonVerifiable` rend le lien AVEC son verdict : un lien profond n'est pas
  /// interrogeable en HTTP, et l'appelant doit savoir que rien n'a ete verifie
  /// plutot que de lire un succes qu'on n'a pas mesure.
  Future<PartageSuivi> preparerPartage({
    required String sessionId,
    required String shareCode,
    ShareLinkType type = ShareLinkTypeValues.web,
  }) async {
    final resolvedType = ShareLinkTypeValues.fromString(type);
    final canal = canalDe(resolvedType);
    final url = linksConfig.lien(canal, shareCode);

    final verdict = await verificateurCible.verifier(canal: canal, url: url);

    final lien = switch (verdict.disponibilite) {
      DisponibiliteCibleSuivi.joignable ||
      DisponibiliteCibleSuivi.nonVerifiable => generateShareLink(
        sessionId: sessionId,
        shareCode: shareCode,
        type: resolvedType,
      ),
      _ => null,
    };

    return PartageSuivi(lien: lien, verdict: verdict);
  }

  /// Le canal de suivi correspondant a un type de lien de partage.
  ///
  /// `ShareLinkType` est une chaine extensible (#81752) ; `CanalSuivi` est un
  /// enum, parce qu'un VERDICT doit porter sur un canal dont la configuration a
  /// ete verifiee. La traduction est faite ici, a un seul endroit.
  static CanalSuivi canalDe(ShareLinkType type) =>
      switch (ShareLinkTypeValues.fromString(type)) {
        ShareLinkTypeValues.app => CanalSuivi.app,
        ShareLinkTypeValues.companionApp => CanalSuivi.compagnon,
        _ => CanalSuivi.web,
      };

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
