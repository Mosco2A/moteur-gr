/// Les couleurs que les ecrans portaient en dur, nommees par leur usage et
/// rapatriees au theme (lot 645-11). Aucune valeur hexadecimale n'a change :
/// c'est un DEPLACEMENT, pas une harmonisation.
library;

import 'package:flutter/material.dart';

/// Couleurs SEMANTIQUES de StepWays : celles qui disent une chose (« eau »,
/// « danger », « sac trop lourd ») et qui ne varient donc PAS avec le sentier
/// actif ni avec la peau.
///
/// POURQUOI CE FICHIER EXISTE. Au 02/10/2026, quarante litteraux `Color(0x...)`
/// vivaient dans `lib/features/` et dans `lib/main.dart`, hors de tout theme.
/// Une couleur ecrite dans un ecran est une decision de design que le design
/// system ne voit pas : elle ne se relit pas, elle ne se corrige pas en un
/// endroit, et elle se recopie — `checklist_weight_banner.dart` portait DEUX
/// FOIS les deux memes valeurs, a 400 lignes d'intervalle. Les voici nommees,
/// a un seul endroit.
///
/// CE QUE CE FICHIER N'EST PAS. Ce n'est pas la palette du sentier : l'accent
/// primaire et secondaire restent injectes par `TrailConfig`, et les tokens de
/// forme (espacements, rayons, typo) restent dans [AppTheme]. Ce n'est pas non
/// plus une harmonisation : plusieurs constantes ci-dessous portent la MEME
/// valeur sous deux noms, parce que leurs deux usages sont distincts. Les
/// fusionner serait une evolution du design, pas un assainissement — les paires
/// concernees sont signalees en commentaire et attendent l'avis de Christophe.
class CouleursSemantiques {
  CouleursSemantiques._();

  // ---------------------------------------------------------------------------
  // ECRAN DE DEMARRAGE (lib/main.dart)
  // ---------------------------------------------------------------------------
  //
  // L'encre posee sur le fond du splash, derivee de la variante de marque
  // active (`AppBranding.splashSurFondSombre`, donc pilotee par
  // `tool/set_branding.py`) : le creme de la charte sur le vert sombre, ou le
  // vert sombre sur le creme.

  /// Creme de la charte, utilise comme ENCRE quand le splash est sombre.
  static const cremeSurSplashSombre = Color(0xFFF4F1E8);

  /// Vert sombre de la charte, utilise comme ENCRE quand le splash est clair.
  static const vertSombreSurSplashClair = Color(0xFF1F3D2B);

  // ---------------------------------------------------------------------------
  // PALETTE DES POINTS REMARQUABLES (POI ET WAYPOINTS COMMUNAUTAIRES)
  // ---------------------------------------------------------------------------
  //
  // UNE SEULE PALETTE POUR DEUX REGISTRES. `PoiTypeConfig` (points du sentier,
  // descendus de la base) et `WaypointTypeConfig` (reperes poses par les
  // marcheurs) sont documentes comme paralleles — « calque le pattern POI ».
  // Ils peignaient la meme nature de point de la meme teinte, chacun avec son
  // propre litteral. Une nature de point, une constante : c'est la meme
  // duplication de connaissance que les deux litteraux du bandeau de poids.

  /// Point d'eau (`water` cote POI, `eau` cote waypoint).
  static const pointEau = Color(0xFF1565C0);

  /// Commerce ou ravitaillement (`shop` cote POI, `ravitaillement` cote
  /// waypoint).
  static const pointRavitaillement = Color(0xFF2E7D32);

  /// Refuge ou abri (`refuge` et `shelter`, qui partagent deja leur style).
  static const pointRefuge = Color(0xFF5D4037);

  /// Hebergement marchand (`accommodation`).
  static const pointHebergement = Color(0xFF6A1B9A);

  /// Bivouac (`campsite` cote POI, `camp` cote waypoint).
  static const pointBivouac = Color(0xFF558B2F);

  /// Danger signale (`danger` des deux cotes).
  static const pointDanger = Color(0xFFC62828);

  /// Secours et urgence (`emergency`).
  ///
  /// Meme valeur que [pointDanger], usage distinct : un danger se contourne,
  /// une urgence s'appelle. NON fusionnee — a trancher par Christophe.
  static const pointUrgence = Color(0xFFC62828);

  /// Point de vue (`viewpoint`).
  static const pointPointDeVue = Color(0xFFE65100);

  /// Restauration (`restaurant`).
  ///
  /// Meme valeur que [pointPointDeVue] et [pointJonction], usages distincts.
  /// NON fusionnee — a trancher par Christophe.
  static const pointRestaurant = Color(0xFFE65100);

  /// Jonction d'itineraires (`jonction`, cote waypoint).
  ///
  /// Meme valeur que [pointPointDeVue] et [pointRestaurant], usages distincts.
  /// NON fusionnee — a trancher par Christophe.
  static const pointJonction = Color(0xFFE65100);

  /// Connectivite reseau (`connectivite`, cote waypoint).
  ///
  /// Meme valeur que [pointHebergement], usages distincts. NON fusionnee — a
  /// trancher par Christophe.
  static const pointConnectivite = Color(0xFF6A1B9A);

  /// Information (`info`).
  ///
  /// Meme valeur que `AppTheme.grisGranite` et que [pointInconnu]. NON
  /// fusionnee — a trancher par Christophe.
  static const pointInformation = Color(0xFF616161);

  /// Type de point inconnu : le repli generique des DEUX registres, pour qu'une
  /// valeur serveur inattendue s'affiche en gris au lieu de faire tomber
  /// l'ecran.
  ///
  /// Meme valeur que `AppTheme.grisGranite`. NON fusionnee — a trancher par
  /// Christophe.
  static const pointInconnu = Color(0xFF616161);

  // ---------------------------------------------------------------------------
  // CARTE : AMAS, POSITION DU MARCHEUR, OMBRES
  // ---------------------------------------------------------------------------

  /// Pastille d'un amas de marqueurs (`ClusteredMarkerLayer`), quand le zoom
  /// est trop large pour les afficher un par un.
  ///
  /// Meme valeur que [bleuDeLaPositionDuMarcheur], usages distincts : un amas
  /// est une donnee du sentier, la position est celle du telephone. NON
  /// fusionnee — a trancher par Christophe.
  static const bleuDeLAmasDeMarqueurs = Color(0xFF1976D2);

  /// Point bleu pulsant de la position du marcheur (`UserPositionMarker`).
  static const bleuDeLaPositionDuMarcheur = Color(0xFF1976D2);

  /// Remplissage du cercle de precision GPS autour de la position : le meme
  /// bleu, pose a ~19 % d'opacite pour laisser voir la carte dessous.
  static const voileDePrecisionGps = Color(0x301976D2);

  /// Bord du cercle de precision GPS : le meme bleu, a ~38 %, pour que le
  /// rayon se lise sans masquer le fond.
  static const bordDuVoileDePrecisionGps = Color(0x601976D2);

  /// Ombre portee sous un marqueur de carte (amas et POI) : noir a 25 %, ce qui
  /// decolle la pastille du fond quelle que soit la tuile dessous.
  static const ombrePorteeDuMarqueur = Color(0x40000000);

  // ---------------------------------------------------------------------------
  // DEUX CRANS DE GRAVITE QU'AppTheme N'AVAIT PAS (parite GR20)
  // ---------------------------------------------------------------------------
  //
  // L'echelle de denivele d'[AppTheme] va du vert au rouge en quatre crans. Le
  // bandeau de poids du sac en demande CINQ, et le risque d'incendie aussi :
  // il leur manquait un cran EN DESSOUS du vert facile, et un cran AU-DELA du
  // rouge d'urgence. Ces deux valeurs viennent de GR20.

  /// Jaune-vert du sac LEGER mais plus ultra-leger : ratio entre 12 % et 15 %
  /// du poids de corps, le cran entre `AppTheme.vertFacile` et
  /// `AppTheme.orangeDifficile`.
  ///
  /// Une seule constante pour les DEUX endroits du bandeau de poids (le conseil
  /// et la jauge) qui portaient chacun son litteral.
  static const jauneVertSacLeger = Color(0xFF9ACD32);

  /// Rouge sombre du sac DANGEREUX : au-dela de 25 % du poids de corps, le cran
  /// au-dela de `AppTheme.rougeUrgence`.
  ///
  /// Une seule constante pour les DEUX endroits du bandeau de poids.
  static const rougeSombreSacDangereux = Color(0xFF8B0000);

  /// Rouge sombre du risque d'incendie EXTREME (niveau 5).
  ///
  /// Meme valeur que [rougeSombreSacDangereux], usages distincts : l'un parle
  /// du sac, l'autre de la foret. NON fusionnee — a trancher par Christophe.
  static const rougeSombreRisqueFeuExtreme = Color(0xFF8B0000);

  // ---------------------------------------------------------------------------
  // CATEGORIES DE CONSEILS (fiches conseil)
  // ---------------------------------------------------------------------------
  //
  // Une teinte par categorie, pour que la puce et la carte d'une meme fiche se
  // repondent. Les categories inconnues retombent sur l'accent du sentier.

  /// Categorie « preparation ».
  static const conseilPreparation = Color(0xFF42A5F5);

  /// Categorie « equipement ».
  static const conseilEquipement = Color(0xFFFF7043);

  /// Categorie « nutrition ».
  ///
  /// Meme valeur que `AppTheme.vertFacile`, usages distincts : l'un classe une
  /// fiche, l'autre note un denivele. NON fusionnee — a trancher par
  /// Christophe.
  static const conseilNutrition = Color(0xFF66BB6A);

  /// Categorie « securite ».
  static const conseilSecurite = Color(0xFFEF5350);

  /// Categorie « nature ».
  static const conseilNature = Color(0xFF26A69A);

  /// Categorie « recuperation ».
  static const conseilRecuperation = Color(0xFFAB47BC);

  // ---------------------------------------------------------------------------
  // DIVERS
  // ---------------------------------------------------------------------------

  /// Fond du bloc d'horaires indicatifs de l'ecran transport : un gris tres
  /// sombre, volontairement plus sombre que la surface du theme, pour que
  /// l'horaire se lise comme une citation et non comme une donnee de l'app
  /// (parite GR20).
  static const fondSombreDesHorairesIndicatifs = Color(0xFF2C2C2C);

  /// Difficulte « expert » du badge de sentier : le cran au-dela de
  /// `AppTheme.rougeExtreme`, en violet, pour qu'il ne se lise pas comme « plus
  /// rouge » mais comme autre chose.
  static const violetDifficulteExpert = Color(0xFF7B1FA2);
}
