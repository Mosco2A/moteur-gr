// AGREGATION DE L'HORAIRE MET NORWAY VERS LE JOURNALIER — logique PURE.
//
// C'est le « travail reel » annonce en #W7 de la conception 611. MET Norway rend
// de l'HORAIRE ; l'application attend du JOURNALIER pret a l'emploi, exactement
// aux sept variables qu'Open-Meteo lui servait
// (lib/features/weather/data/weather_api_service.dart:38-42). La conversion vit
// ICI, une fois, pour tout le monde : l'appli ne voit plus le fournisseur (#W8).
//
// CE QUE J'AI MESURE LE 28/09/2026 SUR UNE REPONSE REELLE (lat 42.30 lon 9.15,
// endpoint `locationforecast/2.0/complete`), et qui decide de cet algorithme :
//   - 90 points, de maintenant a +9,1 jours ;
//   - les 63 premiers pas sont HORAIRES, les 26 suivants sont de SIX HEURES ;
//   - 84 points portent AUSSI un `next_6_hours` qui CHEVAUCHE les fenetres
//     horaires : additionner les deux COMPTERAIT LA PLUIE DEUX FOIS. C'est le
//     piege principal de cette agregation et il ne se voit pas a l'oeil ;
//   - `wind_speed` est en METRES PAR SECONDE (`meta.units.wind_speed = 'm/s'`)
//     alors que l'application attend des KM/H (`windSpeedKmh`, et le seuil
//     `windSpeedKmh >= 60` de `DayForecast.isAlertCondition`). Sans conversion,
//     l'alerte vent ne se declencherait JAMAIS ;
//   - `probability_of_precipitation` est ABSENT de la reponse : MET Norway ne le
//     donne pas. `precipitationProbabilityMax` reste donc `null`, EXPLICITEMENT
//     (voir PROBABILITE_ABSENTE) ;
//   - `ultraviolet_index_clear_sky` est un UV CIEL CLAIR : une borne HAUTE, pas
//     l'UV sous les nuages. Le nom du champ de sortie le dit.
//
// LES UNITES SONT VERIFIEES A CHAQUE PASSAGE, PAS SUPPOSEES. Une derive
// d'unite chez le fournisseur est silencieuse et dangereuse : elle ne casse
// rien, elle rend des chiffres faux. #A5 s'applique — valeur hors domaine,
// refus, rien n'est ecrit.

import { jourLocal, FUSEAU_DEFAUT } from './horodatage.js';
import { codeWmoDepuisSymbole, pireCodeWmo } from './wmo.js';

/// Portee retenue : 5 jours (#W6). Christophe a tranche « 3 ou 5 jours » ; le
/// depot demandait 10 (`forecastHorizonDays`) en argumentant lui-meme sur NOAA
/// (5 jours justes ~90 % du temps, 10 jours une fois sur deux) : c'est le code
/// qui demandait trop.
export const JOURS_PORTEE_DEFAUT = 5;

/// Sous ce nombre de jours retenus, le bulletin de l'etape est REFUSE en entier.
/// « Une etape a une meteo complete ou n'en a pas » — jamais un demi-bulletin.
export const JOURS_MINIMUM = 3;

/// Un jour couvert par moins d'heures que ceci n'est PAS emis.
///
/// POURQUOI ON JETTE PLUTOT QUE DE MARQUER. Le jour courant est tronque par
/// construction : a 22 h locale il ne reste qu'une heure de prevision. En tirer
/// un « maximum du jour » serait une ASSERTION FAUSSE sur la journee, affichee
/// comme un maximum. Six heures est la granularite grossiere de la source :
/// en dessous, on ne sait pas, et on le dit en n'ecrivant rien.
export const HEURES_MINIMUM_PAR_JOUR = 6;

/// A partir de ce nombre d'heures couvertes, le jour est declare `complet`.
export const HEURES_POUR_COMPLET = 20;

/// Les unites EXIGEES dans `properties.meta.units`. Une divergence est un refus.
export const UNITES_EXIGEES = Object.freeze({
  air_temperature: 'celsius',
  air_temperature_max: 'celsius',
  air_temperature_min: 'celsius',
  precipitation_amount: 'mm',
  wind_speed: 'm/s',
});

/// Bornes de vraisemblance (#A5 : « une temperature de 80 °C » -> refus).
export const BORNES = Object.freeze({
  temperatureMin: -80,
  temperatureMax: 60,
  precipitationMaxMm: 500,
  ventMaxKmh: 400,
  uvMax: 20,
});

/// Tolerance sur `meta.updated_at` : une heure de modele dans le futur de plus
/// de 2 h, ou plus vieille que 24 h, est refusee (#A5, « une date dans le
/// futur »). 2 h couvre un decalage d'horloge plausible sans laisser passer une
/// annee 2027.
export const TOLERANCE_MODELE = Object.freeze({ futurMs: 2 * 3600e3, passeMs: 24 * 3600e3 });

/// MET Norway ne fournit PAS de probabilite de precipitation (mesure du
/// 28/09/2026 : aucun `probability_of_precipitation` dans la reponse
/// `complete`). Le champ que l'application attend reste donc `null`.
/// L'INVENTER serait la faute nommee en #W12 : annoncer une garantie qu'on n'a
/// pas. C'est une PERTE FONCTIONNELLE reelle par rapport a Open-Meteo, et elle
/// est nommee ici plutot que comblee.
export const PROBABILITE_ABSENTE = null;

/// Raisons de refus, nommees pour que le battement les compte (#H2).
export const REFUS = Object.freeze({
  charpente: 'charpente-inattendue',
  unites: 'unites-divergentes',
  modeleIllisible: 'heure-de-modele-illisible',
  modeleInvraisemblable: 'heure-de-modele-invraisemblable',
  aucunPoint: 'aucun-point-horaire',
  troisPeuDeJours: 'trop-peu-de-jours-exploitables',
  valeurHorsDomaine: 'valeur-hors-domaine',
  symboleInconnu: 'symbole-inconnu',
});

class BulletinRefuse extends Error {
  constructor(raison, detail) {
    super(`${raison}${detail ? `: ${detail}` : ''}`);
    this.name = 'BulletinRefuse';
    this.raison = raison;
    this.detail = detail ?? null;
  }
}

function nombreOuNull(v) {
  return typeof v === 'number' && Number.isFinite(v) ? v : null;
}

function verifierLesUnites(units) {
  if (units === null || typeof units !== 'object') {
    throw new BulletinRefuse(REFUS.charpente, 'properties.meta.units absent');
  }
  for (const [champ, attendue] of Object.entries(UNITES_EXIGEES)) {
    const lue = units[champ];
    if (lue !== attendue) {
      throw new BulletinRefuse(REFUS.unites, `${champ} = ${JSON.stringify(lue)} au lieu de ${attendue}`);
    }
  }
}

/// Parcourt la serie et retient des FENETRES DE PRECIPITATION QUI NE SE
/// CHEVAUCHENT PAS.
///
/// A chaque instant on prend la fenetre la plus fine disponible (`next_1_hours`,
/// sinon `next_6_hours`), puis on avance le curseur jusqu'a sa fin : tout point
/// situe avant ce curseur est deja couvert et ne compte plus. Sans ce curseur,
/// les 84 `next_6_hours` mesures s'ajouteraient aux 63 `next_1_hours` et la
/// pluie serait comptee jusqu'a deux fois.
function fenetresSansChevauchement(serie) {
  const fenetres = [];
  let curseur = -Infinity;
  for (const point of serie) {
    const t = point.ms;
    if (t < curseur) continue;
    const n1 = point.brut?.data?.next_1_hours;
    const n6 = point.brut?.data?.next_6_hours;
    let choisie = null;
    if (n1 && nombreOuNull(n1.details?.precipitation_amount) !== null) {
      choisie = { heures: 1, bloc: n1 };
    } else if (n6 && nombreOuNull(n6.details?.precipitation_amount) !== null) {
      choisie = { heures: 6, bloc: n6 };
    }
    if (choisie === null) continue;
    fenetres.push({
      ms: t,
      heures: choisie.heures,
      precipitation: nombreOuNull(choisie.bloc.details.precipitation_amount) ?? 0,
      temperatureMax: nombreOuNull(choisie.bloc.details?.air_temperature_max),
      temperatureMin: nombreOuNull(choisie.bloc.details?.air_temperature_min),
      symbole: choisie.bloc.summary?.symbol_code ?? null,
    });
    curseur = t + choisie.heures * 3600e3;
  }
  return fenetres;
}

function jourVide(jour) {
  return {
    jour,
    temperatureMax: null,
    temperatureMin: null,
    precipitationMm: 0,
    windSpeedKmh: null,
    uvIndexMax: null,
    weatherCode: null,
    precipitationProbabilityMax: PROBABILITE_ABSENTE,
    heuresCouvertes: 0,
  };
}

/// Agrege une reponse `locationforecast/2.0/complete` en bulletin journalier.
///
/// Rend `{ ok: true, bulletin }` ou `{ ok: false, raison, detail }`. On ne leve
/// pas vers l'appelant : un refus est une ISSUE NORMALE, comptee dans le
/// battement, qui laisse la donnee de la veille en place (#T1).
export function agregerMetNorway(reponse, {
  maintenantMs,
  fuseau = FUSEAU_DEFAUT,
  joursPortee = JOURS_PORTEE_DEFAUT,
} = {}) {
  try {
    return { ok: true, bulletin: _agreger(reponse, { maintenantMs, fuseau, joursPortee }) };
  } catch (e) {
    if (e instanceof BulletinRefuse) return { ok: false, raison: e.raison, detail: e.detail };
    throw e;
  }
}

function _agreger(reponse, { maintenantMs, fuseau, joursPortee }) {
  const proprietes = reponse?.properties;
  if (proprietes === null || typeof proprietes !== 'object') {
    throw new BulletinRefuse(REFUS.charpente, 'properties absent');
  }
  verifierLesUnites(proprietes.meta?.units);

  // `meta.updated_at` est l'HEURE DU MODELE (#W11, `produiteLe`) : la seule qui
  // dise quand le monde a ete regarde. C'est ce que l'ecran affiche, et c'est la
  // seule raison pour laquelle MET Norway a ete retenu (#W2).
  const brutModele = proprietes.meta?.updated_at;
  const modeleMs = typeof brutModele === 'string' ? Date.parse(brutModele) : NaN;
  if (!Number.isFinite(modeleMs)) {
    throw new BulletinRefuse(REFUS.modeleIllisible, String(brutModele));
  }
  if (modeleMs > maintenantMs + TOLERANCE_MODELE.futurMs
      || modeleMs < maintenantMs - TOLERANCE_MODELE.passeMs) {
    throw new BulletinRefuse(REFUS.modeleInvraisemblable, brutModele);
  }

  const brute = Array.isArray(proprietes.timeseries) ? proprietes.timeseries : null;
  if (brute === null || brute.length === 0) throw new BulletinRefuse(REFUS.aucunPoint);

  const serie = [];
  for (const point of brute) {
    const ms = typeof point?.time === 'string' ? Date.parse(point.time) : NaN;
    if (!Number.isFinite(ms)) continue;
    serie.push({ ms, brut: point });
  }
  if (serie.length === 0) throw new BulletinRefuse(REFUS.aucunPoint);
  serie.sort((a, b) => a.ms - b.ms);

  const parJour = new Map();
  const obtenir = (ms) => {
    const jour = jourLocal(ms, fuseau);
    let j = parJour.get(jour);
    if (j === undefined) {
      j = jourVide(jour);
      parJour.set(jour, j);
    }
    return j;
  };

  // (a) Les RELEVES INSTANTANES : temperature, vent, UV. Independants des
  //     fenetres de precipitation, donc parcourus separement et tous retenus.
  for (const point of serie) {
    const details = point.brut?.data?.instant?.details;
    if (details === null || typeof details !== 'object') continue;
    const j = obtenir(point.ms);

    const t = nombreOuNull(details.air_temperature);
    if (t !== null) {
      if (t < BORNES.temperatureMin || t > BORNES.temperatureMax) {
        throw new BulletinRefuse(REFUS.valeurHorsDomaine, `air_temperature=${t}`);
      }
      j.temperatureMax = j.temperatureMax === null ? t : Math.max(j.temperatureMax, t);
      j.temperatureMin = j.temperatureMin === null ? t : Math.min(j.temperatureMin, t);
    }

    const ventMs = nombreOuNull(details.wind_speed);
    if (ventMs !== null) {
      // m/s -> km/h. L'unite a ete VERIFIEE plus haut ; sans cette ligne le
      // seuil d'alerte vent de l'application ne se declencherait jamais.
      const ventKmh = ventMs * 3.6;
      if (ventKmh < 0 || ventKmh > BORNES.ventMaxKmh) {
        throw new BulletinRefuse(REFUS.valeurHorsDomaine, `wind_speed=${ventMs} m/s`);
      }
      j.windSpeedKmh = j.windSpeedKmh === null ? ventKmh : Math.max(j.windSpeedKmh, ventKmh);
    }

    const uv = nombreOuNull(details.ultraviolet_index_clear_sky);
    if (uv !== null) {
      if (uv < 0 || uv > BORNES.uvMax) {
        throw new BulletinRefuse(REFUS.valeurHorsDomaine, `uv=${uv}`);
      }
      j.uvIndexMax = j.uvIndexMax === null ? uv : Math.max(j.uvIndexMax, uv);
    }
  }

  // (b) Les FENETRES : precipitation, extremes de fenetre, symbole du temps.
  //     Une fenetre de six heures peut chevaucher deux jours locaux ; elle est
  //     attribuee ENTIEREMENT au jour de son DEBUT. Repartir la pluie au prorata
  //     inventerait une donnee que la source ne donne pas ; l'erreur possible
  //     est bornee a six heures, et seulement aux jours ou la source est deja
  //     grossiere (au-dela de +2,6 jours).
  for (const f of fenetresSansChevauchement(serie)) {
    const j = obtenir(f.ms);
    if (f.precipitation < 0) {
      throw new BulletinRefuse(REFUS.valeurHorsDomaine, `precipitation=${f.precipitation}`);
    }
    j.precipitationMm += f.precipitation;
    j.heuresCouvertes += f.heures;

    // Les extremes de fenetre couvrent TOUT l'intervalle, pas seulement les
    // instants echantillonnes : sur les jours a pas de six heures ils rattrapent
    // les pointes que les releves instantanes manquent.
    for (const t of [f.temperatureMax, f.temperatureMin]) {
      if (t === null) continue;
      if (t < BORNES.temperatureMin || t > BORNES.temperatureMax) {
        throw new BulletinRefuse(REFUS.valeurHorsDomaine, `air_temperature_max/min=${t}`);
      }
      j.temperatureMax = j.temperatureMax === null ? t : Math.max(j.temperatureMax, t);
      j.temperatureMin = j.temperatureMin === null ? t : Math.min(j.temperatureMin, t);
    }

    if (f.symbole !== null) {
      const code = codeWmoDepuisSymbole(f.symbole);
      if (code === null) throw new BulletinRefuse(REFUS.symboleInconnu, f.symbole);
      // Le PIRE temps de la journee, jamais la moyenne (#A2), et c'est aussi la
      // semantique du code journalier d'Open-Meteo que l'appli connait deja.
      j.weatherCode = pireCodeWmo(j.weatherCode, code);
    }
  }

  const jourCourant = jourLocal(maintenantMs, fuseau);
  const retenus = [...parJour.values()]
    .filter((j) => j.jour >= jourCourant)
    .sort((a, b) => (a.jour < b.jour ? -1 : 1))
    .filter((j) => j.heuresCouvertes >= HEURES_MINIMUM_PAR_JOUR
      && j.temperatureMax !== null
      && j.temperatureMin !== null
      && j.weatherCode !== null)
    .slice(0, joursPortee);

  if (retenus.length < JOURS_MINIMUM) {
    throw new BulletinRefuse(
      REFUS.troisPeuDeJours,
      `${retenus.length} jour(s) exploitable(s) sur ${parJour.size}`,
    );
  }

  for (const j of retenus) {
    if (j.precipitationMm > BORNES.precipitationMaxMm) {
      throw new BulletinRefuse(REFUS.valeurHorsDomaine, `precipitation=${j.precipitationMm} mm le ${j.jour}`);
    }
  }

  return {
    source: 'met-norway',
    produiteLeMs: modeleMs,
    fuseau,
    joursPortee,
    jours: retenus.map((j) => ({
      jour: j.jour,
      temperatureMax: arrondir(j.temperatureMax, 1),
      temperatureMin: arrondir(j.temperatureMin, 1),
      precipitationMm: arrondir(j.precipitationMm, 1),
      windSpeedKmh: arrondir(j.windSpeedKmh, 1),
      // Le nom dit CIEL CLAIR : c'est une borne haute, pas l'UV sous nuages.
      uvIndexMaxCielClair: arrondir(j.uvIndexMax, 1),
      weatherCode: j.weatherCode,
      precipitationProbabilityMax: PROBABILITE_ABSENTE,
      heuresCouvertes: j.heuresCouvertes,
      complet: j.heuresCouvertes >= HEURES_POUR_COMPLET,
    })),
  };
}

function arrondir(v, decimales) {
  if (v === null || v === undefined) return null;
  const f = 10 ** decimales;
  return Math.round(v * f) / f;
}
