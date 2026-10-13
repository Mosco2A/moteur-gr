// LE CACHE EXIGE PAR MET NORWAY — logique PURE de decision.
//
// ============================================================================
// CE N'EST PAS UNE OPTIMISATION. C'EST UNE OBLIGATION DE LICENCE.
// ============================================================================
// api.met.no/doc/TermsOfService, releve au corpus #100736 (#S09) :
//   - « All requests must include an identifying User Agent-string (UA) with the
//     application/domain name » ET un moyen de contact ;
//   - « Cache data locally and use the If-Modified-Since request header to avoid
//     repeatedly downloading the same data » ;
//   - respecter les en-tetes `Expires` ;
//   - 20 requetes par seconde PAR APPLICATION, au total.
// Ne pas le faire fait BANNIR. C'est contractuel, pas discretionnaire.
//
// Mesure du 28/09/2026 21:36 UTC sur `locationforecast/2.0/complete` :
// `Expires` = `Date` + 31 minutes, `Last-Modified` present. Une cadence de 4 h
// reste tres au-dessus de ce que la source tolere — donc le respect d'`Expires`
// ne nous coute normalement AUCUN appel evite... sauf le jour ou quelqu'un
// baissera la cadence. C'est justement le jour ou ce garde-fou sert.
//
// ============================================================================
// POURQUOI LE CACHE EST DANS LA BASE, ET PAS EN MEMOIRE
// ============================================================================
// Une fonction planifiee ne garantit AUCUNE continuite de processus entre deux
// reveils : chaque passage peut etre un demarrage a froid. Un cache en memoire
// serait donc systematiquement vide, et l'obligation de MET Norway ne serait
// tenue que sur le papier. Le cache vit dans Firestore.
//
// ET IL TIENT DANS UN SEUL DOCUMENT PAR FAMILLE, pas un par point.
// 70 etapes x (1 lecture + 1 ecriture) par passage feraient 840 operations par
// jour pour du pur bookkeeping. Un document unique portant un dictionnaire de
// validateurs fait 1 lecture + 1 ecriture par passage. Meme raisonnement que
// #K6 pour la borne, meme ordre de grandeur d'economie.

/// Au-dela de cette taille, le document de cache est REFUSE plutot qu'ecrit.
/// La limite Firestore est de 1 MiB par document ; on s'arrete bien avant, et on
/// le dit, au lieu de decouvrir la limite un jour de croissance.
export const OCTETS_MAXIMUM_DOCUMENT = 700 * 1024;

/// Duree de vie retenue quand la source ne dit rien (ni `Expires`, ni
/// `Cache-Control: max-age`). Zero : sans indication, on ne s'autorise aucune
/// retenue et on repose la question conditionnelle au passage suivant. Supposer
/// une duree que la source n'annonce pas serait decider a sa place.
export const TTL_PAR_DEFAUT_MS = 0;

/// Lit `Expires` / `Cache-Control: max-age` d'une reponse et rend l'instant
/// jusqu'auquel la reponse reste valable.
///
/// `no-store` / `no-cache` (ce que rend le flux corse, mesure) fait rendre
/// `maintenantMs` : on ne CONSERVE pas la reponse, mais on garde les
/// validateurs, ce qui reste conforme et evite de retelecharger l'identique.
export function validiteDepuisEnTetes(enTetes, { maintenantMs }) {
  const lire = (nom) => {
    if (enTetes === null || typeof enTetes !== 'object') return null;
    const v = enTetes[nom] ?? enTetes[nom.toLowerCase()];
    return typeof v === 'string' ? v : null;
  };

  const controle = (lire('cache-control') ?? '').toLowerCase();
  if (controle.includes('no-store') || controle.includes('no-cache')) {
    return { jusquAMs: maintenantMs, origine: 'no-store' };
  }

  const maxAge = controle.match(/max-age\s*=\s*(\d+)/);
  if (maxAge !== null) {
    return { jusquAMs: maintenantMs + Number(maxAge[1]) * 1000, origine: 'max-age' };
  }

  const expires = lire('expires');
  if (expires !== null) {
    const ms = Date.parse(expires);
    // Un `Expires` dans le passe vaut « deja perime » : on ne le refuse pas, on
    // le lit pour ce qu'il dit.
    if (Number.isFinite(ms)) return { jusquAMs: ms, origine: 'expires' };
  }

  return { jusquAMs: maintenantMs + TTL_PAR_DEFAUT_MS, origine: 'defaut' };
}

/// DECIDE s'il faut appeler, et avec quels en-tetes conditionnels.
///
/// Trois issues :
///   - `appeler: false` + `raison: 'encore-valable'` : `Expires` n'est pas
///     atteint. C'EST L'OBLIGATION DE LICENCE. Aucun octet ne part.
///   - `appeler: true` avec `If-None-Match` / `If-Modified-Since` : on a des
///     validateurs, un 304 coutera zero octet de corps.
///   - `appeler: true` sans en-tete : premier appel pour cette adresse.
export function deciderAppel(entree, { maintenantMs }) {
  if (entree && Number.isFinite(entree.valableJusquAMs) && entree.valableJusquAMs > maintenantMs) {
    return {
      appeler: false,
      raison: 'encore-valable',
      valableJusquAMs: entree.valableJusquAMs,
      enTetes: {},
    };
  }

  const enTetes = {};
  if (entree && typeof entree.etag === 'string' && entree.etag.length > 0) {
    enTetes['If-None-Match'] = entree.etag;
  }
  if (entree && typeof entree.lastModified === 'string' && entree.lastModified.length > 0) {
    enTetes['If-Modified-Since'] = entree.lastModified;
  }

  return {
    appeler: true,
    raison: Object.keys(enTetes).length > 0 ? 'revalidation' : 'premier-appel',
    enTetes,
  };
}

/// Construit l'entree de cache a garder apres une reponse 200.
///
/// On ne garde QUE les validateurs et la validite : jamais le corps. Le corps
/// mesure pres de 5 Ko gzip par etape et son interet est nul — ce qu'on veut
/// reutiliser, c'est l'AGREGAT, qui est deja depose dans la collection meteo.
export function memoriser({ etag, lastModified, enTetes, maintenantMs }) {
  const validite = validiteDepuisEnTetes(enTetes, { maintenantMs });
  return {
    etag: typeof etag === 'string' && etag.length > 0 ? etag : null,
    lastModified: typeof lastModified === 'string' && lastModified.length > 0 ? lastModified : null,
    valableJusquAMs: validite.jusquAMs,
    origineDeLaValidite: validite.origine,
    obtenuLeMs: maintenantMs,
  };
}

/// Rafraichit la validite apres un 304 sans toucher aux validateurs.
export function prolonger(entree, { enTetes, maintenantMs }) {
  const validite = validiteDepuisEnTetes(enTetes, { maintenantMs });
  return {
    ...(entree ?? {}),
    valableJusquAMs: validite.jusquAMs,
    origineDeLaValidite: validite.origine,
    revalideLeMs: maintenantMs,
  };
}

/// Mesure la taille du document de cache et refuse au-dela du seuil.
export function verifierLaTaille(document) {
  const octets = Buffer.byteLength(JSON.stringify(document ?? {}), 'utf8');
  return { octets, acceptable: octets <= OCTETS_MAXIMUM_DOCUMENT };
}
