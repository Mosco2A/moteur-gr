// LA BORNE — un seul enregistrement pour tout le catalogue. Logique PURE.
//
// ============================================================================
// CE QUE LA BORNE EST, ET POURQUOI ELLE N'EST PAS « LE MAXIMUM RECU »
// ============================================================================
// #K2 / #K4 de la conception 611. Une collecte ecrit sept enregistrements, un par
// un, entre 06:00:01 et 06:00:04. Un telephone interroge a 06:00:02 : il recoit
// les deux premiers. S'il retient LE MAXIMUM DE CE QU'IL A RECU, il retient
// 06:00:02 — et les cinq suivants, ecrits a 06:00:03 et 06:00:04, NE
// REDESCENDRONT JAMAIS, puisqu'il ne demandera plus que ce qui depasse son
// repere. La donnee est la, visible de tous, et ce telephone ne la verra plus.
// Aucune erreur, aucune trace, aucun moyen de s'en apercevoir.
//
// La borne ferme ce trou : elle vaut « AVANT CET INSTANT, PLUS RIEN NE SERA
// ECRIT », et elle ne bouge qu'a la FIN d'une collecte TERMINEE (#K3). Le
// telephone retient ca, relit gratuitement ce qu'il a deja (l'ecriture est
// idempotente) et ne saute rien. **Relire est gratuit, sauter est definitif.**
//
// ============================================================================
// POURQUOI UN SEUL DOCUMENT — ET C'EST UN ARGUMENT DE FACTURE, PAS DE STYLE
// ============================================================================
// #K6. Le chemin ordinaire est celui ou RIEN n'a change, et c'est celui qui est
// parcouru des dizaines de milliers de fois par jour. Avec un document unique il
// coute UNE lecture. Avec une question par famille il en couterait NEUF, pour
// neuf reponses vides. Firestore facture au document lu : 1 000 randonneurs x 6
// passages font 6 000 lectures contre 54 000, et le palier gratuit annonce est de
// 50 000 par jour. Le meme dispositif passe ou ne passe pas sous le palier
// gratuit selon ce seul choix de conception.
//
// ============================================================================
// LES DEUX PRODUCTEURS ECRIVENT LE MEME DOCUMENT, CHACUN SES LIGNES (#K9)
// ============================================================================
// Le collecteur ne touche que `meteo` et `risque_incendie` ; le publicateur ne
// touche que les familles du sentier. La fusion doit donc etre faite EN
// TRANSACTION sur le document relu, jamais par un ecrasement : `arreteA` est le
// MINIMUM de toutes les familles, il ne peut pas se calculer sans les lire.

import { enMillisecondes, plusAncien } from './horodatage.js';

/// L'identite du document. Un seul, pour tout le catalogue.
export const COLLECTION = 'catalogue_borne';
export const DOCUMENT = 'courant';

/// Les familles que le COLLECTEUR a le droit d'ecrire. La liste est CLOSE (#L1).
///
/// Elle n'est pas documentaire : `fusionner` refuse toute autre famille. Une
/// convention se viole en silence, une verification refuse. La garde vraie est
/// cote serveur (deux comptes de service, #L4) ; celle-ci attrape la faute avant
/// qu'elle ne parte sur le reseau, et elle la NOMME.
export const FAMILLES_DU_COLLECTEUR = Object.freeze(['meteo', 'risque_incendie']);

export class FamilleInterdite extends Error {
  constructor(famille) {
    super(`famille hors du perimetre du collecteur: ${famille}`);
    this.name = 'FamilleInterdite';
    this.famille = famille;
  }
}

/// Fusionne les lignes d'un passage dans la borne relue, et recalcule `arreteA`.
///
/// `avancees` = `{ '<trailId>': { '<famille>': '<instant ISO>' } }`.
///
/// `arreteA` est LE PLUS PETIT des arretes de famille, jamais le plus grand
/// (#K10) : la borne globale ne peut pas promettre plus que la famille la plus en
/// retard. Si la meteo est arretee a 06:00 et les etapes a 04:00, rien ne
/// garantit qu'on n'ecrira plus rien avant 06:00 — on garantit seulement 04:00.
/// Arrondir vers le haut ICI ferait sauter des donnees, exactement comme #K4.
export function fusionner(borneStockee, avancees) {
  const sentiers = {};
  const source = borneStockee?.sentiers;
  if (source !== null && typeof source === 'object') {
    for (const [trailId, familles] of Object.entries(source)) {
      if (familles === null || typeof familles !== 'object') continue;
      sentiers[trailId] = { ...familles };
    }
  }

  for (const [trailId, familles] of Object.entries(avancees ?? {})) {
    for (const [famille, instant] of Object.entries(familles ?? {})) {
      if (!FAMILLES_DU_COLLECTEUR.includes(famille)) throw new FamilleInterdite(famille);
      // Lit l'instant pour le VALIDER : une borne illisible casserait le calcul
      // du minimum sans rien dire.
      enMillisecondes(instant);
      if (sentiers[trailId] === undefined) sentiers[trailId] = {};
      const precedent = sentiers[trailId][famille];
      // Une borne ne RECULE jamais : elle promet, et une promesse qui recule est
      // pire que pas de promesse.
      if (precedent === undefined || enMillisecondes(instant) > enMillisecondes(precedent)) {
        sentiers[trailId][famille] = instant;
      }
    }
  }

  let arreteA = null;
  for (const familles of Object.values(sentiers)) {
    for (const instant of Object.values(familles)) {
      arreteA = plusAncien(arreteA, instant);
    }
  }

  return { arreteA, sentiers };
}

/// Ce que le collecteur a le droit de lire dans la borne pour savoir ou il en
/// etait : le plus recent de SES arretes, toutes familles et tous sentiers.
///
/// Sert de `borneAnterieure` a `ouvrirPassage` : c'est ce qui garantit la
/// monotonie stricte des instants meme si l'horloge du serveur recule (#R16).
export function dernierArreteDuCollecteur(borneStockee) {
  let dernier = null;
  const source = borneStockee?.sentiers;
  if (source === null || typeof source !== 'object') return null;
  for (const familles of Object.values(source)) {
    if (familles === null || typeof familles !== 'object') continue;
    for (const [famille, instant] of Object.entries(familles)) {
      if (!FAMILLES_DU_COLLECTEUR.includes(famille)) continue;
      if (typeof instant !== 'string') continue;
      if (dernier === null || enMillisecondes(instant) > enMillisecondes(dernier)) dernier = instant;
    }
  }
  return dernier;
}

/// CE QUE LA BORNE NE FERME PAS, ET QUE JE SIGNALE SANS Y TOUCHER.
///
/// `arreteA` etant le minimum, il reste EPINGLE a la famille la plus ancienne.
/// Un sentier publie une fois et jamais retouche garde ses `stages` a leur date
/// d'origine : `arreteA` ne depassera donc jamais cette date, meme si la meteo
/// avance toutes les quatre heures.
///
/// Consequence : un telephone qui prendrait `arreteA` comme repere UNIQUE
/// relirait, a chaque passage, tout ce qui a ete ecrit depuis ce minimum. C'est
/// juste (rien n'est saute) mais c'est cher.
///
/// Le remede n'est pas ici : il est cote lecteur, et il est deja prevu par la
/// forme du document. `sentiers[trailId][famille]` porte une date PAR FAMILLE
/// (#K5) precisement pour qu'un telephone garde un repere par famille et
/// n'interroge que celles qui ont bouge (#K7). La tache 610 a livre UN repere par
/// sentier (`trail_manifests.localVersion`) : avec un seul repere par sentier, la
/// relecture decrite ci-dessus aura lieu. C'est un cout, pas un defaut de
/// justesse, et il appartient au lot qui branchera la lecture.
export const NOTE_POUR_LE_LECTEUR = Object.freeze({
  contrat: 'arreteA est un MINIMUM : raccourci « rien n a change », pas un repere de rattrapage',
  repereRecommande: 'un repere par (sentier, famille), lu dans sentiers[trailId][famille]',
});
