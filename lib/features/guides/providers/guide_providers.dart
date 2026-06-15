import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../i18n/translations.g.dart';
import '../domain/town_guide.dart';
import '../domain/town_guide_catalog.dart';

/// Ouvre un lien deeplink SORTANT (facilitateur prestataire, #84100).
///
/// Abstraction injectable (surchargeable en test) du lancement d'URL : permet
/// de mocker le deeplink dans les tests widget sans dependre du plugin natif
/// url_launcher. FACILITATEUR uniquement — ouvre le site/app du prestataire,
/// AUCUNE reservation ni paiement in-app (decision Chris #84100).
abstract class GuideDeeplinkLauncher {
  /// Tente d'ouvrir [url] dans une application externe.
  ///
  /// Retourne true si l'ouverture a ete declenchee, false si l'appareil ne
  /// peut pas ouvrir ce lien (l'UI affiche alors un repli, ZERO catch
  /// silencieux).
  Future<bool> open(String url);
}

/// Implementation reelle basee sur url_launcher (mode application externe).
class UrlLauncherDeeplink implements GuideDeeplinkLauncher {
  const UrlLauncherDeeplink();

  @override
  Future<bool> open(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Provider du lanceur de deeplink des town guides (surchargeable en test).
final guideDeeplinkLauncherProvider = Provider<GuideDeeplinkLauncher>(
  (ref) => const UrlLauncherDeeplink(),
);

/// Resout les libelles localises (titre + contenu) d'une section de guide.
///
/// Lit les chaines Slang (5 langues) a partir du [BuildContext] : le domaine
/// reste pur (F8C-01), l'UI fournit la traduction. Toute categorie connue de
/// [GuideCategory] a son libelle ; une categorie inconnue retombe sur le
/// fallback (services), comme cote modele.
GuideSectionLabels guideSectionLabels(BuildContext context, String categorie) {
  final g = Translations.of(context).guides;
  switch (GuideCategory.fromString(categorie)) {
    case GuideCategory.ravitaillement:
      return GuideSectionLabels(
        titre: g.categories.ravitaillement,
        contenu: g.intro.ravitaillement,
      );
    case GuideCategory.hebergement:
      return GuideSectionLabels(
        titre: g.categories.hebergement,
        contenu: g.intro.hebergement,
      );
    case GuideCategory.transport:
      return GuideSectionLabels(
        titre: g.categories.transport,
        contenu: g.intro.transport,
      );
    case GuideCategory.eau:
      return GuideSectionLabels(
        titre: g.categories.eau,
        contenu: g.intro.eau,
      );
    case GuideCategory.sante:
      return GuideSectionLabels(
        titre: g.categories.sante,
        contenu: g.intro.sante,
      );
    case GuideCategory.services:
    default:
      return GuideSectionLabels(
        titre: g.categories.services,
        contenu: g.intro.services,
      );
  }
}

/// Liste des town guides du sentier [trailId], libelles localises (Slang).
///
/// Lit le catalogue PUR (F8C-01) en injectant la resolution i18n. Donnees
/// fictives en P2-P3 (#84627) ; consultation 100 % OFFLINE (R3), AUCUNE logique
/// reseau (le contenu vient du pack local).
List<TownGuide> townGuidesForContext(BuildContext context, String trailId) {
  return TownGuideCatalog.guidesFor(
    trailId,
    sectionLabelResolver: (categorie) =>
        guideSectionLabels(context, categorie),
  );
}

/// Retourne le town guide [guideId] du sentier [trailId], libelles localises.
TownGuide? townGuideByIdForContext(
  BuildContext context,
  String trailId,
  String guideId,
) {
  return TownGuideCatalog.guideById(
    trailId,
    guideId,
    sectionLabelResolver: (categorie) =>
        guideSectionLabels(context, categorie),
  );
}
