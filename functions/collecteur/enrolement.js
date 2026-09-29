// LA LISTE DES ETAPES A COLLECTER — validation PURE.
//
// ============================================================================
// POURQUOI UNE LISTE, ET PAS UNE LECTURE DES DONNEES PUBLIEES
// ============================================================================
// #L3 dit que le collecteur lit la liste des etapes et leurs coordonnees « depuis
// les donnees publiees, en lecture seule ». Litteralement, cela voudrait dire
// telecharger `data/manifest.json` PUIS le fichier de donnees de chaque sentier —
// or ce fichier porte `gpx_points`, donc des milliers d'enregistrements, donc
// plusieurs megaoctets, et il faudrait le faire SIX FOIS PAR JOUR pour en extraire
// sept coordonnees qui ne changent jamais.
//
// La conception dit d'ailleurs elle-meme comment l'eviter : #I10 — « le
// rattachement est calcule UNE FOIS, a la publication, pas a chaque collecte.
// Raison : un calcul refait six fois par jour pour un resultat qui ne change
// jamais est une depense et une source de panne. » Et #X13 numerote l'etape qui
// pose cette liste : « ENROLER. C'est l'etape qu'on oublie, et c'est pour cela
// qu'elle est numerotee. »
//
// La liste est donc un DOCUMENT UNIQUE, ecrit par l'enrolement (hors de ce lot,
// il appartient au mecanisme d'ajout d'un sentier) et lu par le collecteur en UNE
// lecture par passage.
//
// ============================================================================
// LE COLLECTEUR NE CORRIGE JAMAIS CETTE LISTE (#L3)
// ============================================================================
// Meme quand une coordonnee est visiblement fausse. Il la SIGNALE dans son
// battement et passe l'etape. Corriger une donnee editoriale sans humain est
// exactement ce que Christophe a refuse.

export const COLLECTION = 'collecteur_enrolement';
export const DOCUMENT = 'courant';

export const REFUS = Object.freeze({
  charpente: 'charpente-inattendue',
  champManquant: 'champ-obligatoire-manquant',
  coordonneeHorsDuMonde: 'coordonnee-hors-du-monde',
  identiteDupliquee: 'identite-dupliquee',
});

const CHAMPS_OBLIGATOIRES = Object.freeze(['trailId', 'stageId', 'lat', 'lng']);

/// Valide la liste enrolee et separe le bon grain de l'ivraie.
///
/// Une etape refusee NE FAIT PAS tomber les autres : c'est #T2 — « une collecte
/// qui reussit mais rapporte moins que prevu n'ecrit que ce qu'elle a ». Sept
/// etapes attendues, cinq valides : on collecte cinq, et les deux autres sont
/// NOMMEES dans le battement. Refuser tout le passage pour une coordonnee fausse
/// priverait de meteo six etapes qui vont bien.
export function validerEnrolement(brut) {
  if (brut === null || typeof brut !== 'object') {
    return { ok: false, raison: REFUS.charpente, detail: 'document absent' };
  }
  const liste = brut.etapes;
  if (!Array.isArray(liste)) {
    return { ok: false, raison: REFUS.charpente, detail: 'etapes n est pas une liste' };
  }

  const retenues = [];
  const ecartees = [];
  const vues = new Set();

  for (const e of liste) {
    if (e === null || typeof e !== 'object') {
      ecartees.push({ etape: null, raison: REFUS.charpente });
      continue;
    }
    const manquant = CHAMPS_OBLIGATOIRES.find((c) => e[c] === null || e[c] === undefined);
    if (manquant !== undefined) {
      ecartees.push({ etape: `${e.trailId ?? '?'}/${e.stageId ?? '?'}`, raison: `${REFUS.champManquant}:${manquant}` });
      continue;
    }
    const lat = Number(e.lat);
    const lng = Number(e.lng);
    // #G11 : « une latitude et une longitude inversees mettent le randonneur dans
    // la mer ». On ne peut pas detecter l'inversion, on peut refuser l'impossible.
    if (!Number.isFinite(lat) || !Number.isFinite(lng)
        || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      ecartees.push({ etape: `${e.trailId}/${e.stageId}`, raison: REFUS.coordonneeHorsDuMonde });
      continue;
    }
    const identite = `${e.trailId}__${e.stageId}`;
    if (vues.has(identite)) {
      // #G12 : deux enregistrements de meme identite -> le second ecraserait le
      // premier EN SILENCE. On refuse le doublon plutot que de choisir.
      ecartees.push({ etape: identite, raison: REFUS.identiteDupliquee });
      continue;
    }
    vues.add(identite);

    retenues.push(Object.freeze({
      trailId: String(e.trailId),
      stageId: String(e.stageId),
      stageNumber: Number.isInteger(e.stageNumber) ? e.stageNumber : null,
      lat,
      lng,
      // Le fuseau est PORTE PAR L'ETAPE quand on le connait, sinon le defaut de la
      // configuration. Jamais devine depuis les coordonnees : resoudre un fuseau
      // geographiquement demande une base de donnees de fuseaux, et se tromper
      // decalerait les journees d'un cran sans rien dire.
      fuseau: typeof e.fuseau === 'string' && e.fuseau.length > 0 ? e.fuseau : null,
      // Calcules a la publication (#I10), jamais a la collecte.
      codeDepartement: typeof e.codeDepartement === 'string' ? e.codeDepartement : null,
      zoneIncendie: e.zoneIncendie === null || e.zoneIncendie === undefined ? null : String(e.zoneIncendie),
      massifIncendie: e.massifIncendie === null || e.massifIncendie === undefined ? null : String(e.massifIncendie),
    }));
  }

  return { ok: true, etapes: retenues, ecartees };
}

/// Les sentiers distincts d'une liste d'etapes — sert aux avancees de borne.
export function sentiersDe(etapes) {
  return [...new Set(etapes.map((e) => e.trailId))].sort();
}
