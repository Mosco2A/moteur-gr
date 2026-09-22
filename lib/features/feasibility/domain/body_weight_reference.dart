/// LE DISPOSITIF POIDS — UNE REFERENCE, DEUX SORTIES (§4 de la spec finale
/// `data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md`, arbitrages Chris
/// du 22/09/2026).
///
/// OU EST LE POIDS DANS L'APPLICATION, ET OU IL N'EST PAS.
/// Le moteur de faisabilite ne porte AUCUN terme de masse (#1-b, #3-d) : le
/// cout d'une etape vaut pente x distance x masse, la capacite journaliere est
/// deduite d'une performance geometrique passee du MEME corps, la masse se
/// simplifie exactement. Le poids vit donc ici, et seulement ici : le SAC
/// CONSEILLE et l'ALERTE DESCENTE. Cette separation satisfait exactement #S7
/// (Tucker 2024 : le cout de la marche par kilogramme n'est correle ni a la
/// masse grasse ni a l'IMC) et #S14 (Zwolinski 2025 : aucune relation entre
/// categorie d'IMC et blessure en randonnee, p = 0,708), qui interdisent tous
/// deux de faire porter un VERDICT par l'IMC.
///
/// CE QUE CE FICHIER CORRIGE. La regle des 20 % etait appliquee au POIDS REEL :
/// un randonneur de 120 kg se voyait conseiller un sac de 24 kg, c'est-a-dire
/// qu'on lui conseillait de porter d'autant plus qu'il portait deja plus. La
/// regle publiee des 20 % (#S13-a, REI) est CONSERVEE TELLE QUELLE ; seul le
/// DENOMINATEUR change, et il devient une reference de taille.
///
/// LE GARDE-FOU DE REDACTION EST NON NEGOCIABLE (#7).
/// L'IMC sert ici de REGLE GRADUEE pour convertir une taille en kilos. JAMAIS
/// de predicteur de risque, jamais de diagnostic. Vocabulaire proscrit a
/// l'ecran : surpoids, obesite, exces, IMC, corpulence, nanisme, pathologie.
/// L'alerte descente parle de masse TRANSPORTEE et de charge mecanique au
/// genou ; elle ne doit pas glisser vers « tu risques de te blesser ».
library;

import 'dart:math' as math;

/// Pourquoi la reference de taille n'a pas pu etre calculee (#5-h).
enum WeightReferenceFallback {
  /// Taille absente : rien a calculer.
  missingHeight,

  /// Taille adulte sous [BodyWeightReference.minHeightCmForReference] : AUCUNE
  /// reference adulte publiee n'existe pour les morphologies disproportionnees
  /// (trou declare #M14). On ne bloque personne, ON DIT QU'ON NE SAIT PAS
  /// CALCULER : le plafond retombe sur le poids reel et l'ecran l'annonce.
  heightBelowReferenceDomain,
}

/// Reference de charge et sorties du dispositif poids.
class BodyWeightReference {
  const BodyWeightReference._();

  /// Reference unique : IMC 25, neutre en age et en sexe (#1-g).
  ///
  /// Declaree comme REGLE GRADUEE, jamais comme diagnostic : elle sert a
  /// convertir une taille en kilos, rien d'autre.
  static const double referenceBmi = 25.0;

  /// Part de la reference conseillee pour le sac (#4-d, #S13-a REI).
  ///
  /// REGLE PUBLIEE CONSERVEE TELLE QUELLE. On garde une regle publiee au lieu
  /// d'inventer un seuil ; seul le denominateur a change.
  static const double backpackShare = 0.20;

  /// Part minimale de reference du bandeau « refuge » (parite GR20), alignee sur
  /// LE MEME denominateur que [backpackShare] (#7-f) : sans quoi la meme page se
  /// contredirait.
  static const double refugeBackpackShare = 0.15;

  /// Taille adulte minimale (cm) sous laquelle AUCUNE reference n'est calculee.
  ///
  /// 147 cm est un seuil clinique usuel, applique ici comme BORNE DE CALCUL et
  /// jamais comme etiquette : le message ne mentionne aucune pathologie et ne
  /// pose aucun diagnostic (#5-i). Il dit ce que l'application ne sait pas
  /// faire, pas ce que la personne est.
  ///
  /// FONDEMENT DU TROU (#5-f, #M14) : en morphologie disproportionnee l'IMC
  /// standard est reconnu invalide (tronc de taille normale, membres courts) ;
  /// des courbes specifiques existent pour les ENFANTS (Hoover-Fong 2008,
  /// courbes 2007 qui s'arretent a 16 ans) et Schulze 2013 plaide explicitement
  /// pour des seuils specifiques — QUI N'EXISTENT PAS POUR L'ADULTE.
  static const int minHeightCmForReference = 147;

  /// Masse de REFERENCE (kg) = 25 × taille_m² (#4-a).
  ///
  /// `null` quand la taille manque ou tombe sous [minHeightCmForReference] :
  /// a 1,30 m la formule rendrait 42,25 kg et un sac conseille de 8,5 kg, a
  /// 60 cm 1,8 kg — un chiffre faux presente avec l'autorite d'un calcul (#5-e).
  static double? referenceMassKg(int heightCm) {
    if (heightCm < minHeightCmForReference) return null;
    final meters = heightCm / 100.0;
    return referenceBmi * meters * meters;
  }

  /// Pourquoi la reference manque, `null` si elle a bien ete calculee.
  static WeightReferenceFallback? fallbackFor(int heightCm) {
    if (heightCm <= 0) return WeightReferenceFallback.missingHeight;
    if (heightCm < minHeightCmForReference) {
      return WeightReferenceFallback.heightBelowReferenceDomain;
    }
    return null;
  }

  /// BASE DE CHARGE : `min(poids_reel ; masse_de_reference)` (#4-b).
  ///
  /// C'est le denominateur UNIQUE de tout ce qui parle de charge dans
  /// l'application — sac conseille, plafond, pourcentage affiche, bandeau
  /// refuge. Une seule definition, pas deux concurrentes (#4-e) : c'est le
  /// defaut qui avait produit deux moteurs de verdict (ecart G1-1, audit
  /// #100189), on ne le refait pas sur le poids.
  ///
  /// Sans reference calculable, la base retombe sur le POIDS REEL — le
  /// comportement actuel — et l'ecran dit que le plafond est calcule sur le
  /// poids reel et non sur une reference de taille (#5-h).
  static double loadBaseKg({required int heightCm, required double bodyWeightKg}) {
    final weight = bodyWeightKg.isFinite && bodyWeightKg > 0 ? bodyWeightKg : 0.0;
    final reference = referenceMassKg(heightCm);
    if (reference == null) return weight;
    return math.min(weight, reference);
  }

  /// SORTIE 1 — sac conseille (kg) : `0,20 × base de charge` (#4-b).
  ///
  /// Demonstration a 1,78 m (reference 79,2 kg) : 120 kg -> 24,0 puis 15,8 kg ;
  /// 70 kg -> 14,0 puis 14,0, STRICTEMENT INCHANGE (#4-h). Le `min()` sature
  /// proprement : a 1,78 m le plafond reste 15,8 kg de 80 a 200 kg (#5-c).
  static double recommendedBackpackKg({
    required int heightCm,
    required double bodyWeightKg,
  }) =>
      backpackShare * loadBaseKg(heightCm: heightCm, bodyWeightKg: bodyWeightKg);

  /// Plancher « refuge » du bandeau de recommandation, meme denominateur (#7-f).
  static double refugeBackpackKg({
    required int heightCm,
    required double bodyWeightKg,
  }) =>
      refugeBackpackShare *
      loadBaseKg(heightCm: heightCm, bodyWeightKg: bodyWeightKg);

  /// Pourcentage du sac RAPPORTE A LA BASE DE CHARGE (0..), 0 si base nulle.
  ///
  /// Le libelle qui l'accompagne doit dire DE QUOI il est le pourcentage
  /// (#7-e) : changer le denominateur sans changer le libelle ferait mentir
  /// l'ecran.
  static double backpackRatio({
    required int heightCm,
    required double bodyWeightKg,
    required double backpackKg,
  }) {
    final base = loadBaseKg(heightCm: heightCm, bodyWeightKg: bodyWeightKg);
    if (base <= 0 || !backpackKg.isFinite) return 0;
    return backpackKg / base;
  }

  /// SORTIE 2 — charge EXCEDENTAIRE (kg) de l'alerte descente (#4-c) :
  /// `max(0 ; poids_reel − masse_de_reference) + poids_du_sac`.
  ///
  /// `null` quand aucune reference n'est calculable : sans reference il n'y a
  /// pas d'exces a nommer, et on n'en invente pas (#5-h).
  static double? excessLoadKg({
    required int heightCm,
    required double bodyWeightKg,
    required double backpackKg,
  }) {
    final reference = referenceMassKg(heightCm);
    if (reference == null) return null;
    if (!bodyWeightKg.isFinite || !backpackKg.isFinite) return null;
    return math.max(0.0, bodyWeightKg - reference) + math.max(0.0, backpackKg);
  }

  /// Vrai si l'alerte descente a quelque chose a dire : une charge excedentaire
  /// strictement positive.
  ///
  /// AUCUN SEUIL BINAIRE DE DENIVELE NEGATIF (#4-l). La grandeur est sourcee —
  /// le travail excentrique est proportionnel a masse × D−, et les forces du
  /// genou s'expriment en multiples du poids (#S23-a Kutzner 2010 : 261 % a
  /// plat, 346 % en descente ; #S23-b Kuster 1995 : moment de flexion +117 %,
  /// puissance +490 % a 11°) — MAIS AUCUN SEUIL DE D− DANGEREUX N'EST PUBLIE
  /// (#M11).
  ///
  /// Le declencheur par pente moyenne a ete INVALIDE par la mesure : sur
  /// l'etape 7 du Mare a Mare, 1 115 m de descente sur 17,7 km, la pente moyenne
  /// vaut 3,6° — sous le seuil publie de Langmuir (12°), il ne declencherait pas
  /// sur l'etape meme qui justifie l'alerte. La moyenne dilue la descente.
  /// Le dispositif CLASSE donc les etapes par D− decroissant et enonce la charge
  /// une fois, sans seuil a inventer.
  static bool hasDescentAlert({
    required int heightCm,
    required double bodyWeightKg,
    required double backpackKg,
  }) {
    final excess = excessLoadKg(
      heightCm: heightCm,
      bodyWeightKg: bodyWeightKg,
      backpackKg: backpackKg,
    );
    return excess != null && excess > 0;
  }
}
