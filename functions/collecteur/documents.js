// LES DOCUMENTS QUE LE COLLECTEUR DEPOSE — construction et comparaison. PUR.
//
// ============================================================================
// « LE COLLECTEUR N'ECRIT JAMAIS UNE DONNEE A MOITIE » — COMMENT C'EST TENU
// ============================================================================
// Contrainte n°3 du mandat : une etape a une meteo COMPLETE ou n'en a pas, et une
// lecture concurrente de l'application ne doit JAMAIS tomber sur un demi-bulletin.
//
// Ce n'est pas tenu par de la vigilance, c'est tenu par la FORME de la donnee :
// **tout le bulletin d'une etape tient dans UN SEUL document Firestore.** Une
// ecriture de document est atomique cote serveur : un lecteur voit l'ancien
// document en entier, ou le nouveau en entier. Il n'existe aucun instant ou il
// verrait trois jours sur cinq. Le decoupage inverse — un document par jour —
// aurait rendu le demi-bulletin possible, et aucune precaution de code ne
// l'aurait referme.
//
// Et avant d'ecrire, `verifierCompletude` refuse un bulletin incomplet : la forme
// garantit l'atomicite de l'ecriture, la verification garantit que ce qu'on ecrit
// vaut la peine d'etre lu. Les deux sont necessaires.
//
// ============================================================================
// LE VOCABULAIRE : `rev`, ET PAS `majLe`. C'EST UNE DIVERGENCE ASSUMEE.
// ============================================================================
// La conception 611 nomme `majLe` l'horodatage de synchronisation. Le depot, lui,
// a DEJA un nom pour ce fait exact : `rev`
// (`RevisionDeDonnee.champRevision`, lib/core/data/revision_de_donnee.dart), et
// c'est le champ que `SourceInterrogeable` interroge (`where('rev','>',R)`).
//
// Introduire `majLe` creerait DEUX noms pour un meme fait — precisement le piege
// que #M7 et #X12 de la spec 605 passent leur temps a denoncer (« deux autorites
// dont la plus silencieuse gagne »), et cela obligerait a ecrire un second chemin
// de requete cote application. On garde donc `rev`. Les noms qui n'existent pas
// encore dans le depot (`produiteLe`, `arreteA`) gardent ceux d'Athena.
//
// ============================================================================
// TROIS DATES ANNONCEES, DEUX DATES ECRITES — ET C'EST #H3 QUI LE DIT
// ============================================================================
// #W11 annonce `produiteLe`, `collecteeLe` et `majLe`. Dans cette mise en oeuvre,
// `collecteeLe` et `majLe` designeraient LE MEME INSTANT : il y a un seul instant
// par passage, et un document n'est reecrit que par un passage. `collecteeLe`
// serait donc un SECOND NOM pour `rev`.
// Ce qu'Athena voulait de `collecteeLe` — « a-t-on verifie recemment ? » — est
// deja porte par le BATTEMENT, et c'est sa propre regle #H3 : « la fraicheur est
// portee par la donnee, la VIVACITE par le battement ». Deux dates suffisent donc :
//   `produiteLe` = quand le MONDE a ete regarde (heure du modele, jour du bulletin)
//   `rev`        = quand NOUS avons ecrit (l'instant du passage)

import { enMillisecondes } from './horodatage.js';

export const COLLECTION_METEO = 'meteo_etape';
export const COLLECTION_INCENDIE = 'risque_incendie_etape';

/// Les familles telles qu'elles apparaissent dans la borne. Voir borne.js.
export const FAMILLE_METEO = 'meteo';
export const FAMILLE_INCENDIE = 'risque_incendie';

/// Champs exclus de la comparaison de contenu.
///
/// Meme doctrine, et pour la meme raison, que `champsDeBookkeeping` de
/// `tool/publication/revision_selective.dart` : comparer un champ que l'outil
/// ECRIT ferait dependre la decision de sa propre sortie, donc tout changerait
/// toujours, donc « seulement ce qui change » (#U2) deviendrait faux et chaque
/// passage repousserait 70 documents vers tous les telephones.
///
/// `produiteLe` N'EST PAS du bookkeeping : c'est ce que l'ecran affiche (#W11),
/// donc une nouvelle heure de modele est un vrai changement, meme a valeurs
/// egales — le randonneur apprend que la prevision a ete reconfirmee.
export const CHAMPS_DE_BOOKKEEPING = Object.freeze(['rev']);

/// L'identite d'un document : stable, lisible, et sans collision possible.
///
/// Le double souligne n'est pas cosmetique : un `trailId` peut contenir des
/// tirets (`mare-a-mare-centre`) et un `stageId` aussi. Un simple tiret rendrait
/// `a-b` + `c` indiscernable de `a` + `b-c`.
export function identiteDocument(trailId, stageId) {
  return `${trailId}__${stageId}`;
}

function canonique(valeur) {
  if (Array.isArray(valeur)) return valeur.map(canonique);
  if (valeur !== null && typeof valeur === 'object') {
    const out = {};
    for (const cle of Object.keys(valeur).sort()) {
      if (valeur[cle] === undefined) continue;
      out[cle] = canonique(valeur[cle]);
    }
    return out;
  }
  // Les nombres sont compares PAR LEUR VALEUR : 14 et 14.0 sont la meme
  // temperature (#G16). `JSON.stringify` s'en charge en JavaScript, mais on le
  // dit, parce que c'est un piege qui a deja coute au lot 607.
  return valeur;
}

/// Empreinte de contenu d'un document, hors bookkeeping.
export function empreinteDeContenu(document, champsExclus = CHAMPS_DE_BOOKKEEPING) {
  const utiles = {};
  for (const [cle, valeur] of Object.entries(document ?? {})) {
    if (champsExclus.includes(cle)) continue;
    utiles[cle] = valeur;
  }
  return JSON.stringify(canonique(utiles));
}

/// RIEN N'A CHANGE = RIEN N'EST ECRIT, ET `rev` NE BOUGE PAS (#G16).
///
/// Consequence directe et voulue : la borne de cette famille ne bouge pas non
/// plus, donc aucun telephone ne relit quoi que ce soit. Un passage qui ne trouve
/// rien de neuf coute ZERO octet de trafic descendant.
export function aChange(stocke, cible, champsExclus = CHAMPS_DE_BOOKKEEPING) {
  if (stocke === null || stocke === undefined) return true;
  return empreinteDeContenu(stocke, champsExclus) !== empreinteDeContenu(cible, champsExclus);
}

/// Les champs qu'un bulletin meteo DOIT porter pour chaque jour. Un jour qui en
/// manque un rend tout le bulletin incomplet : on ne depose pas un jour boiteux
/// au milieu de jours complets, parce que l'ecran l'afficherait comme les autres.
const CHAMPS_JOUR_OBLIGATOIRES = Object.freeze([
  'jour', 'temperatureMax', 'temperatureMin', 'precipitationMm',
  'windSpeedKmh', 'weatherCode',
]);

/// Verifie qu'un bulletin est complet AVANT de l'ecrire. Rend `null` si tout va
/// bien, la raison sinon.
export function verifierCompletude(bulletin, { joursMinimum }) {
  if (bulletin === null || typeof bulletin !== 'object') return 'bulletin-absent';
  if (!Array.isArray(bulletin.jours) || bulletin.jours.length < joursMinimum) {
    return `moins-de-${joursMinimum}-jours`;
  }
  const vus = new Set();
  for (const j of bulletin.jours) {
    if (j === null || typeof j !== 'object') return 'jour-non-objet';
    for (const champ of CHAMPS_JOUR_OBLIGATOIRES) {
      if (j[champ] === null || j[champ] === undefined) return `champ-manquant:${champ}`;
    }
    if (vus.has(j.jour)) return `jour-en-double:${j.jour}`;
    vus.add(j.jour);
  }
  // Les jours doivent etre CONSECUTIFS et croissants : un trou au milieu ferait
  // afficher « J+1, J+3 » comme si c'etait « J+1, J+2 ».
  const tries = [...vus].sort();
  for (let i = 1; i < tries.length; i += 1) {
    if (tries[i] <= tries[i - 1]) return 'jours-non-croissants';
  }
  if (bulletin.jours.map((j) => j.jour).join('|') !== tries.join('|')) {
    return 'jours-non-ordonnes';
  }
  return null;
}

/// Construit le document meteo d'une etape, pret a etre depose.
export function documentMeteo({ etape, bulletin, passage, attribution }) {
  return {
    trailId: etape.trailId,
    stageId: etape.stageId,
    stageNumber: etape.stageNumber ?? null,
    lat: etape.lat,
    lng: etape.lng,
    fuseau: bulletin.fuseau,
    source: bulletin.source,
    // L'heure du MODELE : « la date en haut du bulletin est celle de
    // fabrication » (Christophe, 28/09). C'est la seule qui dise quand le monde a
    // ete regarde, et la seule raison pour laquelle MET Norway a ete retenu.
    produiteLeMs: bulletin.produiteLeMs,
    joursPortee: bulletin.joursPortee,
    jours: bulletin.jours,
    attribution,
    rev: passage.instant,
  };
}

/// Construit le document de risque incendie d'une etape.
///
/// #A1 — ON N'ARBITRE PAS ENTRE DEUX SOURCES DE SECURITE, ON LES NOMME. Les deux
/// blocs restent SEPARES, chacun attribue a son autorite, parce qu'ils repondent
/// a deux questions differentes : `dangerMeteo` dit « quel est le danger
/// meteorologique » (Meteo-France, INFORMATIF) et `acces` dit « ai-je le droit
/// d'entrer » (Etat en Corse, CONTRAIGNANT). Les fondre en un chiffre effacerait
/// la seule des deux qui a force de loi (#I7).
export function documentIncendie({ etape, dangerMeteo, acces, saison, passage }) {
  return {
    trailId: etape.trailId,
    stageId: etape.stageId,
    stageNumber: etape.stageNumber ?? null,
    codeDepartement: etape.codeDepartement ?? null,
    zoneIncendie: etape.zoneIncendie ?? null,
    massifIncendie: etape.massifIncendie ?? null,
    // Les jours a venir, du plus proche au plus lointain. `null` quand la source
    // ne dit rien : le collecteur n'ecrit PAS un vide (#T1), mais un bloc absent
    // dans un document present est une INFORMATION (« je n'ai pas cette source »),
    // pas un vide.
    dangerMeteo: dangerMeteo ?? null,
    acces: acces ?? null,
    // La saison vient du FICHIER, pas d'un calendrier code en dur. C'est ce qui
    // permet a l'ecran de distinguer « hors saison » (#I19, une REPONSE) de
    // « inconnu » (#I20, une panne) — et cette distinction compte : un message de
    // panne affiche tout l'hiver apprend au randonneur a ignorer les messages.
    saison: saison ?? null,
    rev: passage.instant,
  };
}

/// L'ETAT (connu / perime / hors saison / inconnu) N'EST PAS ECRIT. Volontairement.
///
/// #I16 : « un niveau de danger incendie ne se reporte JAMAIS d'un jour sur
/// l'autre. Un bulletin vaut pour UN JOUR NOMME. Passe ce jour, il n'est pas un
/// peu vieux, il est FAUX. La peremption de cette famille n'est pas une duree,
/// c'est une DATE. »
///
/// Un champ `etat` ecrit a 16:00 serait donc FAUX a minuit — et il serait faux en
/// disant « connu ». La seule maniere d'etre juste est que l'etat soit DERIVE par
/// le lecteur, en comparant `dangerMeteo.jour` au jour courant. Cette fonction
/// est la definition de reference de cette derivation ; elle est exportee pour
/// etre testee et pour que le lot qui branchera l'ecran ait la meme, et non une
/// seconde qui deriverait.
export function etatDerive({ jourDuBulletin, jourCourant, saisonActive }) {
  if (jourDuBulletin === null || jourDuBulletin === undefined) {
    return saisonActive === false ? 'hors-saison' : 'inconnu';
  }
  if (jourDuBulletin === jourCourant) return 'connu';
  if (saisonActive === false) return 'hors-saison';
  return 'perime';
}

/// Les avancees de borne d'un passage, a fusionner par borne.fusionner.
///
/// LA BORNE NE BOUGE QU'A LA FIN D'UNE COLLECTE TERMINEE (#K3), et seulement pour
/// les sentiers REELLEMENT touches. Un passage meteo ne fait donc relire aucune
/// donnee de sentier : la borne des familles du sentier n'a pas bouge (#K9).
export function avanceesDeBorne({ famille, sentiersTouches, passage }) {
  const avancees = {};
  for (const trailId of sentiersTouches) {
    avancees[trailId] = { [famille]: passage.instant };
  }
  return avancees;
}

/// Verifie qu'un instant est lisible — sert de garde-fou aux tests de bout en bout.
export function verifierInstant(instant) {
  enMillisecondes(instant);
  return instant;
}
