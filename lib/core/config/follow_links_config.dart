import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuration des liens de partage du suivi trekkeur (E4.11).
///
/// Les 3 canaux de suivi (#81753) pointent chacun vers une base
/// d URL distincte. Les valeurs par defaut sont celles du moteur ;
/// chaque application produit les surcharge via
/// [followLinksConfigProvider] (aucune marque en dur dans les services).
class FollowLinksConfig {
  const FollowLinksConfig({
    this.appLinkBase = 'moteurgr://follow',
    this.webLinkBase = 'https://moteur-gr.web.app/follow',
    this.companionLinkBase = 'https://moteur-gr.web.app/companion',
  });

  /// Base du deeplink vers l application principale (canal app gratuit).
  final String appLinkBase;

  /// Base de l URL de la page web de suivi (canal web, pass payant).
  final String webLinkBase;

  /// Base du lien vers l application complementaire de suivi (payante).
  final String companionLinkBase;

  /// URL du deeplink app pour un shareCode donne.
  String appLink(String shareCode) => '$appLinkBase/$shareCode';

  /// URL de la page web de suivi pour un shareCode donne.
  String webLink(String shareCode) => '$webLinkBase/$shareCode';

  /// URL de l application complementaire pour un shareCode donne.
  String companionLink(String shareCode) => '$companionLinkBase/$shareCode';
}

/// Provider de la configuration des liens de suivi.
///
/// Override par l application hote pour injecter son scheme
/// et son domaine (le moteur reste generique).
final followLinksConfigProvider = Provider<FollowLinksConfig>((ref) {
  return const FollowLinksConfig();
});
