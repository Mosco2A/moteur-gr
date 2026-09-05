import 'fire_risk.dart';

/// Catalogue de donnees RISQUE INCENDIE par sentier (parite GR20 `FireRiskScreen`,
/// data-driven — regle « donnees en externe » de Christophe #99460).
///
/// Equivalent structurel du bloc reglementaire GR20 hardcode par localite (Corse
/// en dur dans l'ecran), mais cote StepWays le contenu est une DONNEE parametree
/// par sentier (genericite #84627) : AUCUNE localite n'est codee en dur DANS LE
/// MOTEUR. Ce catalogue embarque joue le role du contenu offline rapatrie dans le
/// pack (comme [TransportCatalog] / [ShopCatalog]) ; le backend (Phase 4) le
/// remplacera par le contenu reel.
///
/// Fonctions PURES (aucune dependance Flutter/Slang). Le contenu par sentier est
/// dans la langue de la donnee (ici FR pour le sentier corse) ; l'INTERFACE de
/// l'ecran (titres, niveaux, boutons) est traduite cote UI via Slang.
///
/// HONNETETE DES DONNEES (regle Chris #99460) : on ne renseigne que ce qui est
/// verifiable. La periode d'interdiction de feu en Corse et la page officielle
/// des feux de foret de la prefecture de Corse sont des faits publics ; ils sont
/// places ICI (donnee du sentier), pas dans le moteur. Un sentier sans donnee
/// reglementaire renvoie une [FireRegulation] vide -> l'ecran masque la section.
abstract final class FireRiskCatalog {
  /// Retourne les donnees risque incendie du sentier [trailId], ou `null` si le
  /// sentier n'en fournit pas (l'ecran masque alors la section reglementation ;
  /// le reste — niveaux derives de la meteo, numeros universels — reste actif).
  ///
  /// Le moteur reste generique : le mapping id -> donnees est une simple table de
  /// DONNEES embarquees, jamais une localite codee dans la logique du moteur.
  static TrailFireRisk? forTrail(String trailId) {
    switch (trailId) {
      case 'mare-a-mare-centre':
        return _mareAMareCentre;
      default:
        return null;
    }
  }

  // ==========================================================================
  // Mare a Mare Centre (Corse) — sentier VITRINE de demonstration (#99423).
  //
  // Reglementation incendie CORSE (faits publics verifies, places en DONNEE du
  // sentier — sources : services de l'Etat en Corse-du-Sud / Haute-Corse) :
  //   * L'emploi du feu en plein air est strictement reglemente en Corse. En
  //     Corse-du-Sud, l'arrete prefectoral 2025 interdit l'emploi du feu du
  //     15 juin au 30 septembre (souvent prolonge par arrete jusqu'a l'automne).
  //     La Haute-Corse prend des arretes equivalents. Les dates exactes varient
  //     chaque annee selon l'arrete en vigueur.
  //   * L'acces a certains massifs forestiers peut etre restreint en cas de
  //     risque eleve (carte de risque interdepartementale mise a jour chaque
  //     jour a 18h).
  //   * Lien officiel data-driven : carte du risque incendie Corse
  //     (risque-prevention-incendie.fr/corse), la ressource la plus utile pour
  //     un randonneur (etat du jour + acces aux massifs). Le sentier traversant
  //     les DEUX departements corses, on renvoie a la carte interdepartementale
  //     plutot qu'a une seule prefecture.
  //
  // Le message reste PRUDENT (« indicativement », « selon l'arrete en vigueur »)
  // et renvoie au lien officiel — honnetete #99460 : on n'affirme pas une date
  // figee comme une certitude legale annuelle (l'arrete est reconduit/prolonge
  // chaque annee avec des dates qui bougent).
  // ==========================================================================
  static const TrailFireRisk _mareAMareCentre = TrailFireRisk(
    trailId: 'mare-a-mare-centre',
    regulation: FireRegulation(
      regionLabel: 'Corse',
      periodStartMonth: 6,
      periodEndMonth: 9,
      message:
          'En Corse, l\'emploi du feu en plein air est strictement reglemente. '
          'En periode estivale a risque (indicativement du 15 juin au 30 '
          'septembre, selon l\'arrete prefectoral en vigueur, souvent prolonge '
          'jusqu\'a l\'automne), les feux et l\'ecobuage sont interdits, et '
          'l\'acces a certains massifs peut etre restreint en cas de risque '
          'eleve. Consultez la carte de risque et l\'arrete en vigueur avant de '
          'partir.',
      decreeUrl: 'https://www.risque-prevention-incendie.fr/corse',
    ),
  );
}
