import 'package:freezed_annotation/freezed_annotation.dart';

part 'share_link.freezed.dart';
part 'share_link.g.dart';

/// Type de lien de partage.
/// Utilise String pour extensibilite (#81752) — valeurs inconnues
/// gerees par fallback, comme AuthMethod et CloudSyncStatus.
typedef ShareLinkType = String;

/// Valeurs connues pour ShareLinkType avec fallback generique.
///
/// Les 3 canaux de suivi (#81753) :
/// - [app] : deeplink vers l application principale (gratuit, 2 suiveurs
///   sans pub puis pub) ;
/// - [web] : URL vers la page web de suivi (pass payant) ;
/// - [companionApp] : application complementaire de suivi payante.
abstract class ShareLinkTypeValues {
  static const String app = 'app';
  static const String web = 'web';
  static const String companionApp = 'companion_app';
  static const String fallback = web;
  static const List<String> values = [app, web, companionApp];

  static ShareLinkType fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Lien de partage pour une session de suivi (E4.10).
///
/// Genere pour inviter les proches a suivre le randonneur.
/// Peut etre un deeplink app, une URL web ou un lien vers
/// l application complementaire de suivi.
@freezed
abstract class ShareLink with _$ShareLink {
  const factory ShareLink({
    required String id,
    required String sessionId,
    required ShareLinkType type,
    required String url,
    String? activatedAt,
  }) = _ShareLink;

  factory ShareLink.fromJson(Map<String, dynamic> json) =>
      _$ShareLinkFromJson(json);
}
