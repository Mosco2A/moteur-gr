import 'town_guide.dart';

/// Libelles localises d'une section de guide (titre + contenu), resolus par l'UI.
///
/// Le domaine reste PUR et testable (aucune dependance Slang/Flutter) : l'UI
/// (F8C-02) passe la resolution i18n a la construction du guide — meme principe
/// que [PackLabels] (F8B-01) et le catalogue de badges (F7C-01).
class GuideSectionLabels {
  const GuideSectionLabels({required this.titre, required this.contenu});

  /// Titre localise de la section (ex « Ravitaillement »).
  final String titre;

  /// Contenu introductif localise (peut etre vide).
  final String contenu;
}

/// Resout les libelles d'une section a partir de sa categorie ([GuideCategory]).
typedef GuideSectionLabelResolver =
    GuideSectionLabels Function(String categorie);

/// Catalogue de town guides (F8C-01, Phase 8 P8-C, offline R3).
///
/// Fournit des town guides FICTIFS en P2-P3 (#84627) destines a etre consultes
/// 100 % OFFLINE (contenu descendu avec les donnees du sentier, AVANT le
/// depart). Fonctions PURES (aucune dependance Flutter/Slang) : l'UI fournit le
/// [GuideSectionLabelResolver] pour les titres de section localises (5 langues).
///
/// Le moteur reste GENERIQUE (#84627) : les guides sont parametres par [trailId]
/// et leurs items (noms de prestataires fictifs) sont des DONNEES, jamais du
/// code en dur. Le backend (Phase 4) remplacera ce catalogue par le contenu reel
/// rapatrie dans le pack.
///
/// AUCUN ITEM NE PORTE DE LIEN PROFOND, ET C'EST VOLONTAIRE (lot 645-08, voie V2
/// arbitree par Christophe le 02/10/2026). Trois items en portaient un vers
/// `example.org` : le domaine reserve aux exemples (RFC 2606). Un randonneur qui
/// appuyait sur « Voir le site » partait donc nulle part, sans qu'aucune
/// exception soit levee. La valeur inventee est RETIREE plutot que remplacee par
/// une chaine creuse : `deeplinkUrl` est nul, [GuideItem.hasDeeplink] est faux,
/// et `TownGuideDetailScreen` ne construit PAS le bouton — pas de tiret, pas de
/// « non renseigne », pas d'espace reserve. Quand le backend fournira de vrais
/// liens, ils reviendront par la donnee, et le bouton avec eux.
abstract final class TownGuideCatalog {
  /// Construit la liste des town guides fictifs d'un sentier (P2-P3, #84627).
  ///
  /// [sectionLabelResolver] fournit les titres/contenus localises (Slang cote
  /// UI). Les noms de lieux et d'items restent des donnees fictives neutres
  /// (aucune localite reelle, le moteur reste generique).
  static List<TownGuide> guidesFor(
    String trailId, {
    required GuideSectionLabelResolver sectionLabelResolver,
  }) {
    GuideSection section(String categorie, List<GuideItem> items) {
      final labels = sectionLabelResolver(categorie);
      return GuideSection(
        categorie: categorie,
        titre: labels.titre,
        contenu: labels.contenu,
        items: items,
      );
    }

    // Deux localites fictives d'etape (donnees neutres, #84627).
    return <TownGuide>[
      TownGuide(
        id: '${trailId}_etape_centre',
        trailId: trailId,
        nomLieu: 'Village d\'etape',
        latitude: 42.0,
        longitude: 9.0,
        sections: [
          section(GuideCategory.ravitaillement, const [
            GuideItem(
              nom: 'Epicerie du village',
              description: 'Produits de base, ouverte le matin.',
            ),
            GuideItem(
              nom: 'Boulangerie',
              description: 'Pain et viennoiseries, ferme le lundi.',
            ),
          ]),
          section(GuideCategory.hebergement, const [
            GuideItem(
              nom: 'Gite d\'etape',
              description: 'Dortoirs et chambres, reservation conseillee.',
            ),
          ]),
          section(GuideCategory.transport, const [
            GuideItem(
              nom: 'Navette vallee',
              description: 'Liaison quotidienne, horaires variables.',
            ),
          ]),
          section(GuideCategory.eau, const [
            GuideItem(
              nom: 'Fontaine de la place',
              description: 'Eau potable toute l\'annee.',
              coordonnees: GuideCoordinates(latitude: 42.001, longitude: 9.001),
            ),
          ]),
          section(GuideCategory.services, const [
            GuideItem(
              nom: 'Bureau de poste',
              description: 'Retrait especes, ouvert en semaine.',
            ),
          ]),
          section(GuideCategory.sante, const [
            GuideItem(
              nom: 'Pharmacie',
              description: 'Premiers soins, ferme le dimanche.',
            ),
          ]),
        ],
      ),
      TownGuide(
        id: '${trailId}_etape_porte',
        trailId: trailId,
        nomLieu: 'Bourg de depart',
        latitude: 42.3,
        longitude: 9.2,
        sections: [
          section(GuideCategory.ravitaillement, const [
            GuideItem(
              nom: 'Supermarche',
              description: 'Ravitaillement complet avant le depart.',
            ),
          ]),
          section(GuideCategory.transport, const [
            GuideItem(
              nom: 'Gare routiere',
              description: 'Bus vers les principales villes.',
              coordonnees: GuideCoordinates(latitude: 42.301, longitude: 9.201),
            ),
          ]),
        ],
      ),
    ];
  }

  /// Retourne le town guide d'identifiant [guideId] pour [trailId], ou null.
  static TownGuide? guideById(
    String trailId,
    String guideId, {
    required GuideSectionLabelResolver sectionLabelResolver,
  }) {
    for (final guide in guidesFor(
      trailId,
      sectionLabelResolver: sectionLabelResolver,
    )) {
      if (guide.id == guideId) return guide;
    }
    return null;
  }
}
