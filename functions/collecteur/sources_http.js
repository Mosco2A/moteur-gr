// LES APPELS SORTANTS — la seule couche du collecteur qui touche le reseau.
//
// Node 20 apporte `fetch` et `DecompressionStream` nativement : aucune dependance
// ajoutee au paquet `functions`. C'est voulu — chaque dependance d'une fonction
// planifiee allonge le demarrage a froid, et un collecteur ne fait que trois
// choses (demander, decompresser, lire).
//
// TOUT APPEL PORTE LE USER-AGENT DE LA CONFIGURATION. Il n'existe pas de chemin
// vers le reseau qui n'en porte pas : `appeler` est la seule fonction qui appelle
// `fetch`, et elle exige `userAgent` en parametre. MET Norway l'impose (#S09) ;
// la Meteo des forets ne l'impose pas, mais s'identifier est la moindre des
// politesses envers un service public qu'on exploite commercialement.

import { gunzipSync } from 'node:zlib';

export const URL_METEO_DES_FORETS =
  'https://meteofrance.s3.sbg.io.cloud.ovh.net/data/BULLETIN/MDF/mdf_2026.csv.gz';

export const BASE_MET_NORWAY =
  'https://api.met.no/weatherapi/locationforecast/2.0/complete';

export const BASE_CARTE_CORSE =
  'https://www.risque-prevention-incendie.fr/static/20/import_data';

export const BASE_OPEN_METEO = 'https://api.open-meteo.com/v1/forecast';

/// Delai maximum d'un appel. L'application se donne 10 s ; le serveur peut etre
/// plus patient, mais pas au point qu'un passage planifie depasse son creneau.
export const DELAI_MS = 20000;

/// MET Norway DEMANDE de tronquer les coordonnees a quatre decimales, parce que
/// c'est ce qui rend son cache efficace : deux appels a 0,00001 degre d'ecart
/// sont, pour lui, deux entrees de cache distinctes pour la meme prevision.
/// Respecter cela fait partie du « cache data locally » de leurs conditions.
export const DECIMALES_COORDONNEES = 4;

export function tronquer(coordonnee) {
  const f = 10 ** DECIMALES_COORDONNEES;
  return Math.round(coordonnee * f) / f;
}

export function urlMetNorway(lat, lng) {
  return `${BASE_MET_NORWAY}?lat=${tronquer(lat)}&lon=${tronquer(lng)}`;
}

export function urlCarteCorse(nomDeFichier) {
  return `${BASE_CARTE_CORSE}/${nomDeFichier}`;
}

/// Un appel HTTP, avec identification et en-tetes conditionnels.
///
/// Rend `{ statut, enTetes, corps, octets }`. `corps` est `null` sur un 304 :
/// c'est l'interet du conditionnel, le serveur ne renvoie rien.
///
/// On demande `gzip` explicitement : MET Norway sert 4,9 Ko compresses la ou la
/// reponse brute pese 62 Ko (mesure du 28/09). Douze fois moins d'octets pour un
/// en-tete.
export async function appeler(url, { userAgent, enTetes = {}, delaiMs = DELAI_MS } = {}) {
  if (typeof userAgent !== 'string' || userAgent.length === 0) {
    // Garde-fou : il ne doit exister AUCUN chemin vers le reseau sans identite.
    throw new Error('appel sans User-Agent : refuse (conditions api.met.no, #S09)');
  }
  const arret = AbortSignal.timeout(delaiMs);
  const reponse = await fetch(url, {
    method: 'GET',
    signal: arret,
    headers: {
      'User-Agent': userAgent,
      'Accept-Encoding': 'gzip',
      ...enTetes,
    },
  });

  const lus = {};
  for (const [nom, valeur] of reponse.headers.entries()) lus[nom.toLowerCase()] = valeur;

  if (reponse.status === 304) {
    return { statut: 304, enTetes: lus, corps: null, octets: 0 };
  }

  const tampon = Buffer.from(await reponse.arrayBuffer());
  return { statut: reponse.status, enTetes: lus, corps: tampon, octets: tampon.length };
}

/// Decompresse un corps `.gz` et le rend en texte.
///
/// Le fichier de la Meteo des forets est en UTF-8 — verifie par decodage strict
/// le 28/09/2026, malgre les accents qui trompent l'oeil dans un terminal
/// Windows. On ne devine donc pas l'encodage.
export function texteDepuisGzip(tampon) {
  return gunzipSync(tampon).toString('utf8');
}

/// Appelle MET Norway pour un point et rend la reponse decodee.
///
/// `fetch` decompresse deja le `gzip` pose par `Accept-Encoding` : le corps qui
/// arrive ici est du JSON en clair. `octets` reste la taille RECUE sur le reseau,
/// c'est-a-dire ce qu'on veut mesurer.
export async function prevoirMetNorway({ lat, lng, userAgent, enTetes }) {
  const url = urlMetNorway(lat, lng);
  const r = await appeler(url, { userAgent, enTetes });
  if (r.statut === 304) return { statut: 304, enTetes: r.enTetes, octets: 0, url };
  if (r.statut !== 200) {
    return { statut: r.statut, enTetes: r.enTetes, octets: r.octets, url, corps: null };
  }
  return {
    statut: 200,
    enTetes: r.enTetes,
    octets: r.octets,
    url,
    corps: JSON.parse(r.corps.toString('utf8')),
  };
}

/// Appelle la Meteo des forets et rend le CSV en texte.
export async function lireMeteoDesForetsDistante({ userAgent, enTetes }) {
  const r = await appeler(URL_METEO_DES_FORETS, { userAgent, enTetes });
  if (r.statut === 304) return { statut: 304, enTetes: r.enTetes, octets: 0, url: URL_METEO_DES_FORETS };
  if (r.statut !== 200) {
    return { statut: r.statut, enTetes: r.enTetes, octets: r.octets, url: URL_METEO_DES_FORETS, texte: null };
  }
  return {
    statut: 200,
    enTetes: r.enTetes,
    octets: r.octets,
    url: URL_METEO_DES_FORETS,
    texte: texteDepuisGzip(r.corps),
  };
}

/// Appelle la carte corse pour un jour donne.
///
/// Un 404 n'est PAS une panne : le fichier d'un jour n'est pose que la veille vers
/// 15:45 UTC (mesure). Demander J+1 le matin rend 404, et c'est une reponse
/// normale. L'appelant le distingue d'un echec.
export async function lireCarteCorseDistante({ nomDeFichier, userAgent, enTetes }) {
  const url = urlCarteCorse(nomDeFichier);
  const r = await appeler(url, { userAgent, enTetes });
  if (r.statut === 304) return { statut: 304, enTetes: r.enTetes, octets: 0, url };
  if (r.statut === 404) return { statut: 404, enTetes: r.enTetes, octets: r.octets, url, corps: null };
  if (r.statut !== 200) {
    return { statut: r.statut, enTetes: r.enTetes, octets: r.octets, url, corps: null };
  }
  return {
    statut: 200,
    enTetes: r.enTetes,
    octets: r.octets,
    url,
    corps: JSON.parse(r.corps.toString('utf8')),
  };
}
