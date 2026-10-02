/// Ouvrir une page legale PUBLIEE : le bouton existait depuis un lot, il
/// n'etait cable sur rien.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// OUVRIR UNE PAGE LEGALE PUBLIEE (tache 642).
///
/// LE DEFAUT MESURE. L'ecran de consentement portait depuis le lot D4D-01 un
/// bouton « Politique de confidentialite » cable sur `onOpenPrivacyPolicy`, un
/// rappel injecte pour la testabilite. La seule route qui ouvre cet ecran
/// (`/consent`, `app_router.dart`) construisait `const ConsentSettingsScreen()`
/// — sans rappel. `onPressed: null` : le bouton etait GRISE et n'ouvrait rien.
/// Un randonneur ne pouvait donc pas lire la politique depuis l'application,
/// alors que le RGPD (art. 13) demande qu'elle soit accessible, et que le
/// formulaire de consentement la cite.
///
/// Meme classe de defaut que le formulaire de confidentialite publicitaire du
/// lot 595 : ecrit, traduit dans les cinq langues, teste — et appele par aucun
/// geste.
///
/// Abstraction injectable, sur le modele de `GuideDeeplinkLauncher` (#84100) :
/// les tests widget surchargent le provider, aucun canal natif n'est touche.
abstract class LegalPageLauncher {
  /// Tente d'ouvrir [url] dans le navigateur de l'appareil.
  ///
  /// Retourne true si l'ouverture a ete declenchee, false si l'appareil ne
  /// sait pas ouvrir ce lien — l'appelant decide alors quoi montrer. ZERO
  /// catch silencieux : un echec se voit.
  Future<bool> open(String url);
}

/// Implementation reelle : `url_launcher` en application externe.
class UrlLauncherLegalPage implements LegalPageLauncher {
  const UrlLauncherLegalPage();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    // `canLaunchUrl` et `launchUrl` LEVENT quand le canal natif est absent
    // (tests, plateforme sans navigateur) : le provider est surcharge en test,
    // et en production un lien qui ne s'ouvre pas ne doit pas faire tomber
    // l'ecran de consentement.
    try {
      if (!await canLaunchUrl(uri)) return false;
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

/// Provider du lanceur de pages legales (surchargeable en test).
final legalPageLauncherProvider = Provider<LegalPageLauncher>(
  (ref) => const UrlLauncherLegalPage(),
);
