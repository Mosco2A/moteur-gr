// LE BATTEMENT ET LE SURVEILLANT — logique PURE.
//
// ============================================================================
// LE PROBLEME, ET IL EST SPECIFIQUE (#H1)
// ============================================================================
// Un collecteur qui s'arrete NE PRODUIT AUCUNE ERREUR. La donnee cesse simplement
// de bouger. Et rien, absolument rien, ne distingue « le monde n'a pas change »
// de « nous avons arrete de regarder ». C'est le seul mode de panne totalement
// silencieux du dispositif.
//
// Le battement est donc ecrit a CHAQUE execution, succes ou echec, meme quand
// rien d'autre n'est ecrit — et c'est tout son interet : **c'est le seul
// enregistrement dont l'ABSENCE est une information.**
//
// ============================================================================
// DEUX SIGNAUX, DEUX LECTEURS (#H3)
// ============================================================================
//   - la FRAICHEUR est portee par la donnee (`produiteLe`, le jour du bulletin) ;
//   - la VIVACITE est portee par le battement.
// Le battement ne dit pas que ca a marche : il dit que quelqu'un a essaye.
//
// ============================================================================
// LE BATTEMENT N'EST JAMAIS LU PAR L'APPLICATION (#H4)
// ============================================================================
// Si le telephone le lisait, un battement vert rassurerait sur une donnee
// perimee. Un collecteur peut tourner parfaitement et ne collecter que des
// echecs. Cette regle n'est PAS une consigne : les regles Firestore de ce lot
// REFUSENT la lecture de cette collection aux clients. Une convention se viole en
// silence ; une regle refuse.

/// Le document est unique et REECRIT (#H2). Chaque tache ne fusionne que sa
/// propre section : trois planifications, trois sections, aucune ne s'ecrase.
export const COLLECTION = 'collecteur_battement';
export const DOCUMENT = 'courant';

/// Les issues possibles d'une famille dans un passage.
export const ISSUE = Object.freeze({
  collecte: 'collecte',
  inchange: 'inchange',
  refuse: 'refuse',
  echec: 'echec',
  eteint: 'eteint',
});

/// Le surveillant alerte quand la derniere execution depasse DEUX FOIS la periode
/// de la tache (#H5). Deux fois, et pas une : un retard d'un cycle arrive pour de
/// bonnes raisons (redemarrage, deploiement) et une alerte qui crie pour rien
/// finit par ne plus etre lue.
export const FACTEUR_DE_RETARD = 2;

/// Les periodes des taches, en millisecondes. Elles sont ICI parce que le
/// surveillant en a besoin pour juger, et parce qu'un seuil code deux fois derive.
export const PERIODES_MS = Object.freeze({
  meteo: 4 * 3600e3,
  incendie: 8 * 3600e3,
});

/// En pleine saison, si le bulletin du jour n'est pas la a cette heure UTC, c'est
/// une ALERTE, pas une attente (#H7). La source n'a rate aucun jour sur 124 : un
/// jour manque est donc un evenement, pas du bruit. Le seuil est plus serre que
/// les autres parce que le randonneur se leve.
export const HEURE_ALERTE_INCENDIE_UTC = 8;

/// Construit la section de battement d'une tache.
///
/// `donnee` porte ce que le SURVEILLANT ne peut pas deduire seul — typiquement le
/// jour du bulletin le plus ancien (#H7). Il voyage ICI plutot que d'etre relu :
/// faire relire 70 documents d'etape au surveillant, pour une question a laquelle le
/// passage vient de repondre, serait 70 lectures pour rien.
export function sectionDeBattement({
  tache, passage, familles, donnee = null, dureeMs = null, erreur = null,
}) {
  return {
    tache,
    executeLe: passage.instant,
    horlogeCorrigee: passage.horlogeCorrigee,
    dureeMs,
    // `familles` = { meteo: { issue, ecrits, inchanges, refuses, echecs, detail } }
    familles: familles ?? {},
    donnee,
    erreur: erreur === null ? null : String(erreur),
  };
}

/// Resume d'une famille pour le battement — compte, jamais liste.
///
/// On compte les refus (#A5) : une source qui rend soudain des valeurs hors
/// domaine se voit dans les chiffres avant de se voir dans l'ecran du randonneur.
export function resumeDeFamille({
  issue,
  ecrits = 0,
  inchanges = 0,
  refuses = 0,
  echecs = 0,
  appels = 0,
  octets = 0,
  detail = null,
}) {
  return { issue, ecrits, inchanges, refuses, echecs, appels, octets, detail };
}

/// LE SURVEILLANT. Rend la liste des alertes, ou une liste vide.
///
/// Il DOIT etre une autre tache que le collecteur (#H5) : un collecteur mort ne
/// peut pas signaler sa propre mort. Il occupe la troisieme place gratuite du
/// planificateur.
///
/// `battement` = le document relu, avec la section `donnee` que chaque passage y a
/// laissee (#H7) — c'est ce qui permet de juger LA DONNEE sans la relire.
export function juger(battement, { maintenantMs, heureUtc = null }) {
  const alertes = [];

  for (const [tache, periodeMs] of Object.entries(PERIODES_MS)) {
    const section = battement?.[tache];
    if (section === null || section === undefined) {
      // PAS DE BATTEMENT DU TOUT : c'est le cas que tout ce fichier existe pour
      // attraper. Une donnee qui ne bouge pas et un collecteur qui n'a jamais
      // tourne sont indiscernables autrement.
      alertes.push({
        gravite: 'critique',
        sujet: tache,
        code: 'aucun-battement',
        message: `aucun battement pour la tache ${tache} : le collecteur n a peut-etre jamais tourne`,
      });
      continue;
    }
    const ms = typeof section.executeLe === 'string' ? Date.parse(section.executeLe) : NaN;
    if (!Number.isFinite(ms)) {
      alertes.push({
        gravite: 'critique',
        sujet: tache,
        code: 'battement-illisible',
        message: `battement de ${tache} illisible: ${section.executeLe}`,
      });
      continue;
    }
    const retardMs = maintenantMs - ms;
    if (retardMs > periodeMs * FACTEUR_DE_RETARD) {
      alertes.push({
        gravite: 'critique',
        sujet: tache,
        code: 'collecteur-muet',
        message: `derniere execution de ${tache} il y a ${Math.round(retardMs / 60000)} min, `
          + `soit plus de ${FACTEUR_DE_RETARD} fois sa periode`,
        retardMs,
      });
    }
  }

  // #H6 — L'ALERTE QUI EST LE VRAI RISQUE : le collecteur tourne, et la source
  // est morte. Tous les voyants d'execution sont verts et la donnee vieillit.
  // Invisible autrement.
  for (const [tache, section] of Object.entries(battement ?? {})) {
    if (section === null || typeof section !== 'object') continue;
    for (const [famille, resume] of Object.entries(section.familles ?? {})) {
      if (resume === null || typeof resume !== 'object') continue;
      if (resume.issue === ISSUE.echec || resume.issue === ISSUE.refuse) {
        alertes.push({
          gravite: 'majeure',
          sujet: `${tache}/${famille}`,
          code: `source-${resume.issue}`,
          message: `la famille ${famille} est en ${resume.issue} au dernier passage`
            + `${resume.detail ? ` (${resume.detail})` : ''} — le collecteur va bien, la SOURCE non`,
        });
      }
    }
  }

  // #H7 — LE SEUIL PLUS SERRE DE L'INCENDIE, en saison seulement.
  //
  // C'est l'alerte qui regarde LA DONNEE et pas L'EXECUTION. Elle est la derniere
  // parce qu'elle est la plus specifique, et elle n'existe que parce que le passage
  // incendie a laisse dans son battement ce que le surveillant ne peut pas deduire
  // seul (section `donnee`). La lire ici ne coute aucune lecture supplementaire.
  const donnee = battement?.incendie?.donnee;
  if (donnee !== null && donnee !== undefined && heureUtc !== null) {
    const vieillissement = alerteDeVieillissementIncendie({
      jourDuBulletinLePlusAncien: donnee.jourDuBulletinLePlusAncien ?? null,
      jourCourant: donnee.jourCourant ?? null,
      saisonActive: donnee.saisonActive === true,
      heureUtc,
    });
    if (vieillissement !== null) alertes.push(vieillissement);
  }

  return alertes;
}

/// #H6, moitie « donnee » : une donnee dont le bulletin n'est plus du jour alors
/// que la saison est active, et qu'il est passe l'heure ou elle devrait etre la.
///
/// C'est le seul controle qui regarde la DONNEE et pas l'EXECUTION, et c'est
/// celui qui attrape une source morte derriere un collecteur en bonne sante.
export function alerteDeVieillissementIncendie({
  jourDuBulletinLePlusAncien,
  jourCourant,
  saisonActive,
  heureUtc,
}) {
  if (!saisonActive) return null; // hors saison, l'absence est une reponse (#I19)
  if (jourDuBulletinLePlusAncien === jourCourant) return null;
  if (heureUtc < HEURE_ALERTE_INCENDIE_UTC) return null; // pas encore l'heure (#H7)
  return {
    gravite: 'critique',
    sujet: 'risque_incendie',
    code: 'bulletin-du-jour-absent',
    message: `il est ${heureUtc}h UTC, la saison est active, et le bulletin le plus ancien porte `
      + `${jourDuBulletinLePlusAncien} au lieu de ${jourCourant} — la source a rate un jour, `
      + 'ce qui ne s est jamais produit sur 124 jours mesures',
  };
}
