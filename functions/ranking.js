// Logique PURE de classement de segment / defi — StepWays Phase 7 (F7A-03).
//
// REGLES NON NEGOCIABLES (design D2 #86160, verdicts Themis) :
//   (R1) PSEUDONYME, PAS ANONYME + k-anonymat (k>=5) + PAS de timestamp fin
//        exploitable. Une tranche avec moins de K_MIN participants n'est PAS
//        publiee individuellement : elle est masquee (compte seul).
//   (R2) Calcul COTE SERVEUR : ce module tourne dans la Cloud Function, jamais
//        sur le client. Le client ne fait qu'un APERCU (F7A-02).
//
// Ce fichier ne depend PAS de firebase-admin (testable en isolation via
// `node --test`). index.js l'appelle avec les efforts lus depuis Firestore.

/// Seuil de k-anonymat : une tranche doit compter au moins K_MIN participants
/// distincts pour que son classement detaille soit publie.
export const K_MIN = 5;

/// Tronque un UID hache en libelle PSEUDONYME court et stable.
///
/// JAMAIS "anonyme" : on derive un pseudonyme deterministe a partir du hash
/// (8 premiers caracteres). Aucune donnee personnelle directe n'est exposee
/// (le hash est deja irreversible cote client, #85383).
export function pseudonymLabel(authorUidHash) {
  if (typeof authorUidHash !== 'string' || authorUidHash.length === 0) {
    return 'rndr-0000';
  }
  return `rndr-${authorUidHash.slice(0, 8)}`;
}

/// Regroupe les efforts par tranche.
///
/// `effort.tranche` est une etiquette de tranche LARGE deja decidee a la
/// remontee (ex: niveau "decouverte"/"sportif", tranche d'age large), ou
/// 'all' si aucune segmentation n'est declaree. On NE cree PAS de tranche a
/// partir d'un timestamp ni d'une perf (eviterait le k-anonymat).
function groupByTranche(efforts) {
  const groups = new Map();
  for (const e of efforts) {
    const tranche = e.tranche || 'all';
    if (!groups.has(tranche)) groups.set(tranche, []);
    groups.get(tranche).push(e);
  }
  return groups;
}

/// Garde le MEILLEUR effort (duree minimale) par participant (UID hache), pour
/// que le k-anonymat compte des PERSONNES distinctes, pas des tentatives.
function bestEffortPerAuthor(efforts) {
  const best = new Map();
  for (const e of efforts) {
    const key = e.authorUidHash;
    if (typeof key !== 'string') continue;
    const cur = best.get(key);
    if (cur === undefined || e.durationSeconds < cur.durationSeconds) {
      best.set(key, e);
    }
  }
  return [...best.values()];
}

/// Construit le document de classement d'un segment AGREGE PAR TRANCHE avec
/// k-anonymat. Entree : liste d'efforts bruts
///   { authorUidHash, durationSeconds, tranche? } (PAS de completedAt fin
///   exploitable dans la SORTIE).
///
/// Sortie (forme du doc Firestore segment_rankings/{segmentId}) :
///   {
///     segmentId,
///     tranches: [
///       {
///         tranche,                 // etiquette de tranche large
///         participantCount,        // nb de participants distincts
///         published: bool,         // false si participantCount < K_MIN
///         entries: [               // present SEULEMENT si published
///           { rank, pseudonym, durationSeconds }  // PAS de timestamp fin
///         ]
///       }, ...
///     ]
///   }
///
/// Garanties (R1) :
///   - aucune entree publiee si la tranche a < K_MIN participants ;
///   - aucun timestamp fin individuel dans la sortie ;
///   - libelles PSEUDONYMES (jamais "anonyme").
export function buildSegmentRanking(segmentId, efforts) {
  const out = { segmentId, tranches: [] };
  const groups = groupByTranche(Array.isArray(efforts) ? efforts : []);

  for (const [tranche, rawEfforts] of groups) {
    const distinct = bestEffortPerAuthor(rawEfforts);
    const participantCount = distinct.length;

    if (participantCount < K_MIN) {
      // k-anonymat : tranche trop petite -> non publiee (compte seul, sans
      // aucune entree individuelle ni pseudonyme).
      out.tranches.push({
        tranche,
        participantCount,
        published: false,
        entries: [],
      });
      continue;
    }

    const sorted = distinct
      .slice()
      .sort((a, b) => a.durationSeconds - b.durationSeconds);
    const entries = sorted.map((e, i) => ({
      rank: i + 1,
      pseudonym: pseudonymLabel(e.authorUidHash),
      durationSeconds: e.durationSeconds,
      // NOTE: volontairement AUCUN champ de date/heure (R1, CNIL A4-4).
    }));

    out.tranches.push({
      tranche,
      participantCount,
      published: true,
      entries,
    });
  }

  return out;
}

/// Variante defi (F7C-02) : meme structure, cle defiId. Le "score" peut etre
/// une duree, une distance ou un denivele cumule selon le type d'objectif ;
/// ici on classe par `value` DECROISSANT (plus haut = meilleur) par defaut.
export function buildDefiRanking(defiId, participations, { ascending = false } = {}) {
  const out = { defiId, tranches: [] };
  const groups = groupByTranche(Array.isArray(participations) ? participations : []);

  for (const [tranche, rawParts] of groups) {
    // Meilleure participation par auteur.
    const best = new Map();
    for (const p of rawParts) {
      const key = p.authorUidHash;
      if (typeof key !== 'string') continue;
      const cur = best.get(key);
      const better = cur === undefined
        || (ascending ? p.value < cur.value : p.value > cur.value);
      if (better) best.set(key, p);
    }
    const distinct = [...best.values()];
    const participantCount = distinct.length;

    if (participantCount < K_MIN) {
      out.tranches.push({ tranche, participantCount, published: false, entries: [] });
      continue;
    }

    const sorted = distinct
      .slice()
      .sort((a, b) => (ascending ? a.value - b.value : b.value - a.value));
    const entries = sorted.map((p, i) => ({
      rank: i + 1,
      pseudonym: pseudonymLabel(p.authorUidHash),
      value: p.value,
    }));
    out.tranches.push({ tranche, participantCount, published: true, entries });
  }

  return out;
}
