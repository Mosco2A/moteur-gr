import '../../../i18n/translations.g.dart';
import 'badge.dart';

/// Construit le CATALOGUE de badges avec libelles LOCALISES (F7C-01).
///
/// Les titres/descriptions viennent de Slang (t.gamification.badge.<code>) — 5
/// langues, AUCUN texte en dur cote moteur. Les badges sont retournes
/// VERROUILLES (obtainedAt == null) ; c'est [BadgeEngine.evaluateBadges] qui
/// decide de l'obtention a partir des stats locales.
class BadgeCatalog {
  const BadgeCatalog._();

  /// Catalogue complet, localise via [t] (Translations courant).
  static List<Badge> build(Translations t) {
    final g = t.gamification.badge;
    return [
      Badge(
        id: BadgeCode.firstStage,
        code: BadgeCode.firstStage,
        titre: g.firstStage.titre,
        description: g.firstStage.description,
        tier: BadgeTier.debutant,
        iconRef: 'flag',
      ),
      Badge(
        id: BadgeCode.firstTrek,
        code: BadgeCode.firstTrek,
        titre: g.firstTrek.titre,
        description: g.firstTrek.description,
        tier: BadgeTier.debutant,
        iconRef: 'hiking',
      ),
      Badge(
        id: BadgeCode.firstSegment,
        code: BadgeCode.firstSegment,
        titre: g.firstSegment.titre,
        description: g.firstSegment.description,
        tier: BadgeTier.debutant,
        iconRef: 'timeline',
      ),
      Badge(
        id: BadgeCode.elevation5000,
        code: BadgeCode.elevation5000,
        titre: g.elevation5000.titre,
        description: g.elevation5000.description,
        tier: BadgeTier.expert,
        iconRef: 'terrain',
      ),
      Badge(
        id: BadgeCode.tenStages,
        code: BadgeCode.tenStages,
        titre: g.tenStages.titre,
        description: g.tenStages.description,
        tier: BadgeTier.expert,
        iconRef: 'military_tech',
      ),
      Badge(
        id: BadgeCode.challenger,
        code: BadgeCode.challenger,
        titre: g.challenger.titre,
        description: g.challenger.description,
        tier: BadgeTier.expert,
        iconRef: 'emoji_events',
      ),
    ];
  }
}
