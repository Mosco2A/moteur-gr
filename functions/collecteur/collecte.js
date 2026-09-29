// L'ORCHESTRATION DES PASSAGES — I/O mince au-dessus des modules PURS.
//
// ============================================================================
// « LE COLLECTEUR NE DOIT NI BOUCLER NI EFFACER LA DONNEE DE LA VEILLE »
// ============================================================================
// C'est la question que le mandat demande de traiter explicitement. Reponse, et
// elle est structurelle :
//
// IL N'EFFACE PAS : il n'existe aucun `delete` dans depot_firestore.js, et une
// collecte qui echoue N'ECRIT RIEN (#T1) — pas un vide, pas un `null`, pas un
// enregistrement « indisponible ». La derniere donnee connue reste en place AVEC
// SON `rev` INCHANGE, donc elle ne redescend meme pas vers les telephones : un
// echec ne produit AUCUN octet de trafic. Et comme l'etat (connu / perime / hors
// saison / inconnu) est DERIVE par le lecteur et non stocke, une meteo de la
// veille s'affiche datee, et un bulletin d'incendie de la veille disparait tout
// seul — sans que le serveur ait eu besoin d'ecrire quoi que ce soit.
//
// IL NE BOUCLE PAS : **la cadence EST la politique de reprise.** Un echec de
// source ne declenche au plus qu'UNE seule seconde tentative, et seulement sur une
// panne de transport (reseau, 5xx). Un 4xx n'est pas reessaye du tout : ce n'est
// pas un alea, c'est un defaut, et le reessayer par lassitude finirait par le
// normaliser (meme doctrine que #E2). Le rattrapage reel est le passage suivant —
// c'est precisement pour cela que l'incendie a un passage a 19:00 en plus de
// celui de 16:00 (#I13). Une meteo vieille de quatre heures vaut mieux qu'une
// boucle qui epuise un quota.
//
// ============================================================================
// LE DEBIT : 20 REQUETES PAR SECONDE EST UN PLAFOND DE LICENCE (#S09)
// ============================================================================
// « maximum 20 requetes par seconde PAR APPLICATION (total, pas par client) ».
// On s'en tient tres loin : au plus QUATRE appels en vol, et un espacement
// minimal entre deux departs. 70 etapes prennent alors quelques secondes, ce qui
// tient largement dans le creneau d'une fonction planifiee.

import { ouvrirPassage, jourLocal, jourDecale, FUSEAU_DEFAUT } from './horodatage.js';
import * as cache from './cache_conditionnel.js';
import * as docs from './documents.js';
import * as mdf from './incendie_mdf.js';
import * as corse from './incendie_corse.js';
import * as bat from './battement.js';
import { dernierArreteDuCollecteur } from './borne.js';
import { sentiersDe } from './enrolement.js';
import { agregerMetNorway, JOURS_MINIMUM } from './meteo_agregat.js';
import { prevoirMetNorway, lireMeteoDesForetsDistante, lireCarteCorseDistante } from './sources_http.js';

/// Appels simultanes au plus. Quatre, pour rester a un ordre de grandeur sous le
/// plafond de licence meme si la latence s'ecroule.
export const APPELS_SIMULTANES = 4;

/// Espacement minimal entre deux departs d'appel, en millisecondes. Avec quatre
/// en vol et 100 ms d'espacement, le debit est plafonne a 10 requetes par
/// seconde : la MOITIE de ce que MET Norway autorise.
export const ESPACEMENT_MS = 100;

/// Une seule seconde tentative, et seulement sur panne de transport.
export const TENTATIVES_MAXIMUM = 2;

/// L'attribution due a MET Norway : CC BY 4.0 impose de crediter, de lier la
/// licence et D'INDIQUER LES MODIFICATIONS — et nous en faisons une, l'agregation
/// journaliere (#W3, #W7). Elle voyage AVEC la donnee, pour que l'ecran ne puisse
/// pas l'afficher sans elle.
export const ATTRIBUTION_MET_NORWAY = Object.freeze({
  fournisseur: 'MET Norway (Norwegian Meteorological Institute)',
  licence: 'CC BY 4.0',
  lienLicence: 'https://creativecommons.org/licenses/by/4.0/',
  modifications: 'agregation horaire vers journalier et traduction du symbole vers le code WMO',
});

function dormir(ms) {
  return new Promise((resoudre) => { setTimeout(resoudre, ms); });
}

/// Parcourt une liste avec une concurrence bornee et un espacement minimal.
async function parcourirAvecDebitBorne(elements, action) {
  const resultats = new Array(elements.length);
  let prochain = 0;
  const travailleur = async () => {
    for (;;) {
      const i = prochain;
      prochain += 1;
      if (i >= elements.length) return;
      if (i > 0) await dormir(ESPACEMENT_MS);
      resultats[i] = await action(elements[i], i);
    }
  };
  const equipe = [];
  for (let n = 0; n < Math.min(APPELS_SIMULTANES, elements.length); n += 1) {
    equipe.push(travailleur());
  }
  await Promise.all(equipe);
  return resultats;
}

/// Un appel avec au plus une seconde tentative, sur panne de TRANSPORT seulement.
async function appelerAvecUneSecondeChance(action) {
  let dernierEchec = null;
  for (let tentative = 1; tentative <= TENTATIVES_MAXIMUM; tentative += 1) {
    try {
      const r = await action();
      // Un 5xx est une panne de transport : on retente. Un 4xx est un defaut : on
      // ne retente pas — ce serait normaliser une erreur.
      if (r.statut >= 500 && tentative < TENTATIVES_MAXIMUM) {
        dernierEchec = `statut ${r.statut}`;
        continue;
      }
      return { ok: true, reponse: r, tentatives: tentative };
    } catch (e) {
      dernierEchec = e?.message ?? String(e);
      if (tentative >= TENTATIVES_MAXIMUM) break;
    }
  }
  return { ok: false, detail: dernierEchec, tentatives: TENTATIVES_MAXIMUM };
}

// ============================================================================
// PASSAGE METEO
// ============================================================================

export async function collecterLaMeteo({ depot, configuration }) {
  const debutSection = { appels: 0, octets: 0, ecrits: 0, inchanges: 0, refuses: 0, echecs: 0, evitesParCache: 0 };
  const compte = { ...debutSection };

  const listeEnrolee = await depot.lireEnrolement();
  const registre = await depot.lireRegistre(docs.FAMILLE_METEO);
  const borneLue = await depot.lireBorne();

  // L'instant du passage : la SEULE lecture d'horloge, plancher de monotonie pris
  // sur la borne relue (#R16 — une horloge serveur peut reculer).
  const passage = ouvrirPassage({
    borneAnterieure: dernierArreteDuCollecteur(borneLue),
    nom: 'meteo',
  });

  if (!listeEnrolee.ok) {
    await depot.battre('meteo', bat.sectionDeBattement({
      tache: 'meteo',
      passage,
      familles: {
        [docs.FAMILLE_METEO]: bat.resumeDeFamille({
          issue: bat.ISSUE.echec,
          detail: `enrolement illisible: ${listeEnrolee.raison}`,
        }),
      },
    }));
    return { passage, compte, alerte: 'enrolement-illisible' };
  }

  const etapes = listeEnrolee.etapes;
  const aEcrire = [];
  const nouveauxPoints = { ...registre.points };
  const nouvellesEmpreintes = { ...registre.empreintes };
  const sentiersTouches = new Set();

  await parcourirAvecDebitBorne(etapes, async (etape) => {
    const identite = docs.identiteDocument(etape.trailId, etape.stageId);
    const entree = registre.points[identite] ?? null;

    // LE CACHE, ET C'EST UNE OBLIGATION DE LICENCE, PAS UNE OPTIMISATION.
    const decision = cache.deciderAppel(entree, { maintenantMs: passage.millisecondes });
    if (!decision.appeler) {
      compte.evitesParCache += 1;
      compte.inchanges += 1;
      return;
    }

    const essai = await appelerAvecUneSecondeChance(() => prevoirMetNorway({
      lat: etape.lat,
      lng: etape.lng,
      userAgent: configuration.userAgent,
      enTetes: decision.enTetes,
    }));
    compte.appels += essai.tentatives;

    if (!essai.ok) {
      // #T1 : rien n'est ecrit. La donnee de la veille reste, avec son `rev`.
      compte.echecs += 1;
      return;
    }
    const reponse = essai.reponse;
    compte.octets += reponse.octets ?? 0;

    if (reponse.statut === 304) {
      // Rien de neuf : on prolonge la validite et on n'ecrit AUCUNE donnee.
      nouveauxPoints[identite] = cache.prolonger(entree, {
        enTetes: reponse.enTetes,
        maintenantMs: passage.millisecondes,
      });
      compte.inchanges += 1;
      return;
    }
    if (reponse.statut !== 200 || reponse.corps === null) {
      compte.echecs += 1;
      return;
    }

    const agregat = agregerMetNorway(reponse.corps, {
      maintenantMs: passage.millisecondes,
      fuseau: etape.fuseau ?? configuration.fuseauDefaut ?? FUSEAU_DEFAUT,
      joursPortee: configuration.joursPortee,
    });
    if (!agregat.ok) {
      // #A5 : valeur hors domaine ou charpente inattendue -> REFUS, rien n'est
      // ecrit, et le refus est COMPTE dans le battement.
      compte.refuses += 1;
      return;
    }

    const document = docs.documentMeteo({
      etape,
      bulletin: agregat.bulletin,
      passage,
      attribution: ATTRIBUTION_MET_NORWAY,
    });

    // « Une etape a une meteo COMPLETE ou n'en a pas. »
    const incomplet = docs.verifierCompletude(agregat.bulletin, { joursMinimum: JOURS_MINIMUM });
    if (incomplet !== null) {
      compte.refuses += 1;
      return;
    }

    nouveauxPoints[identite] = cache.memoriser({
      etag: reponse.enTetes.etag,
      lastModified: reponse.enTetes['last-modified'],
      enTetes: reponse.enTetes,
      maintenantMs: passage.millisecondes,
    });

    // RIEN N'A CHANGE = RIEN N'EST ECRIT, ET `rev` NE BOUGE PAS (#G16).
    const empreinte = docs.empreinteDeContenu(document);
    if (registre.empreintes[identite] === empreinte) {
      compte.inchanges += 1;
      return;
    }
    nouvellesEmpreintes[identite] = empreinte;
    aEcrire.push({ identite, document });
    sentiersTouches.add(etape.trailId);
  });

  compte.ecrits = await depot.deposer(docs.COLLECTION_METEO, aEcrire);

  const taille = cache.verifierLaTaille({ points: nouveauxPoints, empreintes: nouvellesEmpreintes });
  if (taille.acceptable) {
    await depot.ecrireRegistre(docs.FAMILLE_METEO, { points: nouveauxPoints, empreintes: nouvellesEmpreintes });
  }

  // LA BORNE APRES LES DONNEES, JAMAIS AVANT (#K3).
  if (sentiersTouches.size > 0) {
    await depot.avancerLaBorne(docs.avanceesDeBorne({
      famille: docs.FAMILLE_METEO,
      sentiersTouches: [...sentiersTouches],
      passage,
    }));
  }

  await depot.battre('meteo', bat.sectionDeBattement({
    tache: 'meteo',
    passage,
    familles: {
      [docs.FAMILLE_METEO]: bat.resumeDeFamille({
        issue: compte.echecs > 0 && compte.ecrits === 0 ? bat.ISSUE.echec
          : (aEcrire.length === 0 ? bat.ISSUE.inchange : bat.ISSUE.collecte),
        ecrits: compte.ecrits,
        inchanges: compte.inchanges,
        refuses: compte.refuses,
        echecs: compte.echecs,
        appels: compte.appels,
        octets: compte.octets,
        detail: taille.acceptable ? null : `registre trop gros (${taille.octets} o), non ecrit`,
      }),
    },
  }));

  return { passage, compte, etapes: etapes.length, ecartees: listeEnrolee.ecartees };
}

// ============================================================================
// PASSAGE RISQUE INCENDIE
// ============================================================================

export async function collecterLeRisqueIncendie({ depot, configuration }) {
  const compte = { appels: 0, octets: 0, ecrits: 0, inchanges: 0, refuses: 0, echecs: 0 };

  const listeEnrolee = await depot.lireEnrolement();
  const registre = await depot.lireRegistre(docs.FAMILLE_INCENDIE);
  const borneLue = await depot.lireBorne();
  const passage = ouvrirPassage({
    borneAnterieure: dernierArreteDuCollecteur(borneLue),
    nom: 'incendie',
  });

  if (!listeEnrolee.ok) {
    await depot.battre('incendie', bat.sectionDeBattement({
      tache: 'incendie',
      passage,
      familles: {
        [docs.FAMILLE_INCENDIE]: bat.resumeDeFamille({
          issue: bat.ISSUE.echec,
          detail: `enrolement illisible: ${listeEnrolee.raison}`,
        }),
      },
    }));
    return { passage, compte, alerte: 'enrolement-illisible' };
  }

  const etapes = listeEnrolee.etapes;
  const jourCourant = jourLocal(passage.millisecondes, configuration.fuseauDefaut ?? FUSEAU_DEFAUT);
  const nouveauxPoints = { ...registre.points };
  const nouvellesEmpreintes = { ...registre.empreintes };

  // ---- Source 1 : la Meteo des forets. Licenciee sans ambiguite. UN appel.
  let lecture = null;
  const entreeMdf = registre.points.mdf ?? null;
  const decisionMdf = cache.deciderAppel(entreeMdf, { maintenantMs: passage.millisecondes });
  if (decisionMdf.appeler) {
    const essai = await appelerAvecUneSecondeChance(() => lireMeteoDesForetsDistante({
      userAgent: configuration.userAgent,
      enTetes: decisionMdf.enTetes,
    }));
    compte.appels += essai.tentatives;
    if (!essai.ok) {
      compte.echecs += 1;
    } else {
      compte.octets += essai.reponse.octets ?? 0;
      if (essai.reponse.statut === 304) {
        // Le fichier n'a pas bouge. On ne peut donc RIEN apprendre de neuf, et on
        // n'ecrit rien : zero octet descendant (#T1).
        nouveauxPoints.mdf = cache.prolonger(entreeMdf, {
          enTetes: essai.reponse.enTetes,
          maintenantMs: passage.millisecondes,
        });
        compte.inchanges += 1;
      } else if (essai.reponse.statut === 200 && essai.reponse.texte !== null) {
        const lu = mdf.lireMeteoDesForets(essai.reponse.texte, { jourCourant });
        if (!lu.ok) {
          compte.refuses += 1;
        } else {
          lecture = lu;
          nouveauxPoints.mdf = cache.memoriser({
            etag: essai.reponse.enTetes.etag,
            lastModified: essai.reponse.enTetes['last-modified'],
            enTetes: essai.reponse.enTetes,
            maintenantMs: passage.millisecondes,
          });
        }
      } else {
        compte.echecs += 1;
      }
    }
  } else {
    compte.inchanges += 1;
  }

  // ---- Source 2 : la carte corse. ETEINTE par defaut — licence non etablie (#I8).
  let lectureCorse = null;
  if (configuration.corseActif) {
    // Le fichier porte le jour qu'il DECRIT et il est pose la veille vers 15:45
    // UTC : on demande d'abord demain, et on retombe sur aujourd'hui si demain
    // n'est pas encore pose (404 = reponse normale, pas panne).
    for (const jour of [jourDecale(jourCourant, 1), jourCourant]) {
      const nom = corse.nomDeFichierPour(jour);
      const essai = await appelerAvecUneSecondeChance(() => lireCarteCorseDistante({
        nomDeFichier: nom,
        userAgent: configuration.userAgent,
        enTetes: {},
      }));
      compte.appels += essai.tentatives;
      if (!essai.ok) { compte.echecs += 1; continue; }
      compte.octets += essai.reponse.octets ?? 0;
      if (essai.reponse.statut === 404) continue;
      if (essai.reponse.statut !== 200 || essai.reponse.corps === null) { compte.echecs += 1; continue; }
      const lu = corse.lireCarteCorse(essai.reponse.corps, { jour });
      if (!lu.ok) { compte.refuses += 1; continue; }
      lectureCorse = lu;
      break;
    }
  }

  const aEcrire = [];
  const sentiersTouches = new Set();

  if (lecture !== null || lectureCorse !== null) {
    for (const etape of etapes) {
      const identite = docs.identiteDocument(etape.trailId, etape.stageId);

      // #I1 informe (departement), #I2 contraint (massif/zone). On NE FUSIONNE
      // PAS : deux blocs, deux autorites (#A1).
      const dangerMeteo = (lecture !== null && etape.codeDepartement !== null)
        ? mdf.joursPourDepartement(lecture, etape.codeDepartement, jourCourant)
        : null;
      const acces = lectureCorse === null ? null : corse.accesPourEtape(lectureCorse, {
        massifIncendie: etape.massifIncendie,
        zoneIncendie: etape.zoneIncendie,
      });

      if ((dangerMeteo === null || dangerMeteo.length === 0) && acces === null) {
        // Rien a dire pour cette etape : on n'ecrit PAS un vide (#T1). Ce qui etait
        // la reste la, et le lecteur en derivera « perime » ou « inconnu ».
        continue;
      }

      const document = docs.documentIncendie({
        etape,
        dangerMeteo: dangerMeteo !== null && dangerMeteo.length > 0 ? dangerMeteo : null,
        acces,
        saison: lecture === null ? null : lecture.saison,
        passage,
      });

      const empreinte = docs.empreinteDeContenu(document);
      if (registre.empreintes[identite] === empreinte) {
        compte.inchanges += 1;
        continue;
      }
      nouvellesEmpreintes[identite] = empreinte;
      aEcrire.push({ identite, document });
      sentiersTouches.add(etape.trailId);
    }
  }

  compte.ecrits = await depot.deposer(docs.COLLECTION_INCENDIE, aEcrire);

  const taille = cache.verifierLaTaille({ points: nouveauxPoints, empreintes: nouvellesEmpreintes });
  if (taille.acceptable) {
    await depot.ecrireRegistre(docs.FAMILLE_INCENDIE, { points: nouveauxPoints, empreintes: nouvellesEmpreintes });
  }

  if (sentiersTouches.size > 0) {
    await depot.avancerLaBorne(docs.avanceesDeBorne({
      famille: docs.FAMILLE_INCENDIE,
      sentiersTouches: [...sentiersTouches],
      passage,
    }));
  }

  await depot.battre('incendie', bat.sectionDeBattement({
    tache: 'incendie',
    passage,
    familles: {
      [docs.FAMILLE_INCENDIE]: bat.resumeDeFamille({
        issue: compte.echecs > 0 && compte.ecrits === 0 ? bat.ISSUE.echec
          : (aEcrire.length === 0 ? bat.ISSUE.inchange : bat.ISSUE.collecte),
        ecrits: compte.ecrits,
        inchanges: compte.inchanges,
        refuses: compte.refuses,
        echecs: compte.echecs,
        appels: compte.appels,
        octets: compte.octets,
        detail: lecture === null ? 'meteo des forets non relue a ce passage' : null,
      }),
      // La carte corse est nommee MEME ETEINTE : un silence se lirait comme
      // « tout va bien », et c'est exactement ce que #I21 interdit.
      acces_corse: bat.resumeDeFamille({
        issue: configuration.corseActif
          ? (lectureCorse === null ? bat.ISSUE.echec : bat.ISSUE.collecte)
          : bat.ISSUE.eteint,
        detail: configuration.corseActif ? null : 'licence non etablie (#I8) — courriel DRAAF Corse',
      }),
    },
  }));

  return {
    passage,
    compte,
    etapes: etapes.length,
    saison: lecture?.saison ?? null,
    jourCourant,
  };
}

// ============================================================================
// LE SURVEILLANT — une tache SEPAREE (#H5)
// ============================================================================

export async function surveiller({ depot, configuration }) {
  const borneLue = await depot.lireBorne();
  const passage = ouvrirPassage({
    borneAnterieure: dernierArreteDuCollecteur(borneLue),
    nom: 'surveillant',
  });
  const battement = await depot.lireBattement();
  const jourCourantUtc = new Date(passage.millisecondes).toISOString().slice(0, 10);

  const alertes = bat.juger(battement, {
    maintenantMs: passage.millisecondes,
    jourCourantUtc,
    saisonIncendieActive: null,
  });

  await depot.deposerAlertes(alertes, passage);
  return { passage, alertes };
}
