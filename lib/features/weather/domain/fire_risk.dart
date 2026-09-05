/// Modele de donnees RISQUE INCENDIE d'un sentier (parite GR20
/// `FireRiskScreen`, data-driven — regle « donnees en externe » de Christophe
/// #99460).
///
/// GR20 hardcode le contenu reglementaire par LOCALITE (Corse : « feux interdits
/// du 1er juin au 30 septembre », URL de la prefecture de Corse en dur dans
/// l'ecran). Cote StepWays, le moteur reste GENERIQUE multi-sentiers (#84627,
/// #99460) : la REGLEMENTATION incendie (periode d'interdiction, region, URL des
/// arretes, message) n'est PAS codee en dur dans le moteur mais fournie en
/// DONNEE, par sentier ([FireRiskCatalog]). Le backend (Phase 4) remplacera le
/// catalogue embarque par le contenu reel rapatrie dans le pack — meme principe
/// que [TrailTransport] / [TrailShops] / les town guides.
///
/// Le NIVEAU de risque (0-5) reste DERIVE de la meteo (parite GR20 : champ
/// `DayForecast.fireRiskLevel` produit par le provider meteo), via
/// [calculateFireRiskLevel] ci-dessous — pas une donnee editoriale.
///
/// Modele PUR (aucune dependance Flutter/Slang) : les libelles d'INTERFACE
/// (titres de section, niveaux « Faible/Modere/… », libelles de la legende) sont
/// resolus cote UI via Slang (5 langues) ; les DONNEES propres au sentier
/// (message reglementaire, periode, URL) restent dans la langue de la donnee.
library;

/// Reglementation incendie PROPRE AU SENTIER (parite GR20 : bloc « feux interdits
/// du … au … » + lien vers les arretes prefectoraux).
///
/// DATA-DRIVEN (#99460) : cote StepWays ce contenu n'est PAS code en dur dans le
/// moteur — il vient de la donnee du sentier. Tous les champs sont dans la langue
/// de la donnee (l'INTERFACE — titre « Reglementation », lien « Consulter les
/// arretes » — est traduite cote UI via Slang). Chaque champ est optionnel :
/// l'ecran masque proprement la ligne (ou toute la section) quand la donnee
/// manque, plutot que d'inventer une periode ou une URL.
class FireRegulation {
  const FireRegulation({
    this.regionLabel = '',
    this.periodStartMonth,
    this.periodEndMonth,
    this.message = '',
    this.decreeUrl,
  });

  /// Libelle de la region concernee par la reglementation (donnee du sentier,
  /// ex. « Corse »). Peut etre vide.
  final String regionLabel;

  /// Mois de DEBUT de la periode d'interdiction de feu (1 = janvier .. 12 =
  /// decembre), ou `null` si le sentier ne precise pas de periode.
  final int? periodStartMonth;

  /// Mois de FIN (inclus) de la periode d'interdiction de feu, ou `null`.
  final int? periodEndMonth;

  /// Message reglementaire complet PROPRE AU SENTIER (parite GR20 : « En Corse,
  /// les feux en plein air sont interdits du 1er juin au 30 septembre… »), en
  /// langue de la donnee. Vide => la section reglementation est masquee.
  final String message;

  /// Lien vers les arretes prefectoraux / la page officielle du sentier (ouvert
  /// via url_launcher, application externe). Null/vide => pas de lien affiche
  /// (parite GR20 : le lien n'apparait que si l'URL existe).
  final String? decreeUrl;

  /// Vrai s'il y a un message reglementaire affichable.
  bool get hasMessage => message.isNotEmpty;

  /// Vrai si un lien vers les arretes est disponible (bouton affiche).
  bool get hasDecreeUrl => decreeUrl != null && decreeUrl!.isNotEmpty;

  /// Vrai si au moins un contenu reglementaire est disponible (message OU lien).
  /// Sert a decider de l'affichage de la section (parite GR20 : masquee si vide).
  bool get hasContent => hasMessage || hasDecreeUrl;
}

/// Donnees RISQUE INCENDIE COMPLETES d'un sentier (parite GR20 `FireRiskScreen`).
///
/// Rattachees a un [trailId] (genericite #84627). Porte la [regulation]
/// reglementaire du sentier. Les NUMEROS d'urgence ne sont PAS ici : ils
/// proviennent de [TrailConfig.emergencyNumbers] (socle deja en place, secours
/// regionaux data-driven) completes par les numeros UNIVERSELS 18/112 geres par
/// le moteur — comme l'ecran Urgence. Le niveau de risque est DERIVE de la meteo
/// (cf. [calculateFireRiskLevel]), pas stocke ici.
class TrailFireRisk {
  const TrailFireRisk({
    required this.trailId,
    this.regulation = const FireRegulation(),
  });

  /// Identifiant du sentier.
  final String trailId;

  /// Reglementation incendie du sentier (periode, region, message, URL).
  final FireRegulation regulation;
}

/// Calcule le niveau de risque incendie (0-5) derive de la meteo du jour.
///
/// PARITE GR20 (`WeatherRepository._calculateFireRisk`, B81/B53v2) : meme
/// algorithme, memes seuils. Open-Meteo ne fournit pas l'humidite relative dans
/// le forecast daily ; on utilise la probabilite de pluie comme proxy indirect
/// d'humidite atmospherique (forte proba => air humide => risque attenue).
///
/// Facteurs :
///  * Temperature max (facteur principal : > 30 C = critique) ;
///  * Vent (amplifie la propagation) ;
///  * Precipitations recentes (sol humide => risque attenue) ;
///  * Probabilite de pluie (proxy humidite => risque attenue).
///
/// Le resultat est BORNE dans [0..5] (parite GR20 : GR20 clampe a 0-4 en
/// pratique ; StepWays garde la borne 5 « Extreme » de la legende accessible
/// quand tous les facteurs aggravants se cumulent — jamais au-dela).
///
/// [precipitationProbability] est nullable (Open-Meteo `precipitation_probability
/// _max` peut manquer sur d'anciens caches) : traite alors comme 0 (aucune
/// attenuation par l'humidite, parite comportement conservateur).
int calculateFireRiskLevel({
  required double temperatureMax,
  required double windSpeedKmh,
  required double precipitationMm,
  double? precipitationProbability,
}) {
  final proba = precipitationProbability ?? 0;

  // Pas de risque s'il pleut / a plu recemment (sol humide) — parite GR20.
  if (precipitationMm > 5) return 0;
  // Forte probabilite de pluie = atmosphere humide = risque faible — parite GR20.
  if (proba > 70) return 0;

  var risk = 0;

  // Temperature (facteur principal l'ete) — memes paliers que GR20.
  if (temperatureMax >= 35) {
    risk += 3;
  } else if (temperatureMax >= 30) {
    risk += 2;
  } else if (temperatureMax >= 25) {
    risk += 1;
  }

  // Vent (amplifie la propagation du feu) — memes paliers que GR20.
  if (windSpeedKmh >= 40) {
    risk += 2;
  } else if (windSpeedKmh >= 25) {
    risk += 1;
  }

  // Precipitation recente attenue le risque — parite GR20.
  if (precipitationMm > 2) {
    risk -= 1;
  }

  // Probabilite de pluie moderee attenue aussi (proxy humidite) — parite GR20.
  if (proba > 40) {
    risk -= 1;
  }

  return risk.clamp(0, 5);
}
