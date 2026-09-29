// MESURER CE QUE COUTE UN PASSAGE COMPLET, CONTRE LES SOURCES REELLES.
//
//   node collecteur/outils/mesurer_un_passage.mjs
//
// ============================================================================
// CET OUTIL N'ECRIT RIEN NULLE PART. C'est un depot EN MEMOIRE : il appelle les
// vraies sources, fait le vrai travail, et compte. Aucune connexion a Firebase,
// aucun deploiement, aucun octet ecrit ailleurs que dans la memoire du processus.
// ============================================================================
//
// POURQUOI UN OUTIL PLUTOT QU'UN CHIFFRE DANS UN DOCUMENT. Les chiffres de cout
// vieillissent : MET Norway peut changer la taille de ses reponses, la Meteo des
// forets peut grossir en fin de saison, et le nombre d'etapes augmentera avec le
// catalogue. Un tableau dans un bilan serait vrai un jour. Cet outil est
// re-executable, donc il reste vrai.
//
// Il porte son propre User-Agent de mesure, nomme et joignable, comme l'exigent
// les conditions de MET Norway — y compris pour une simple mesure.

import { collecterLaMeteo, collecterLeRisqueIncendie } from '../collecte.js';
import { validerEnrolement } from '../enrolement.js';
import { fusionner } from '../borne.js';
import { COLLECTION_METEO, COLLECTION_INCENDIE, FAMILLE_METEO } from '../documents.js';

const CONFIGURATION = {
  userAgent: process.env.STEPWAYS_COLLECTEUR_USER_AGENT
    ?? 'StepWays-mesure/0.1 (https://only1cent.com; christophe.mosconi@only1cent.com)',
  fournisseurMeteo: 'met-norway',
  joursPortee: 5,
  fuseauDefaut: 'Europe/Paris',
  corseActif: process.env.STEPWAYS_COLLECTEUR_CORSE_ACTIF === '1',
  aBlanc: false,
};

/// Les sept etapes du Mare a Mare Centre, cote corse. Les coordonnees servent a
/// mesurer un volume, pas a publier un sentier.
const ETAPES = [
  ['mam-s1', 42.27, 9.54, '2B'],
  ['mam-s2', 42.23, 9.43, '2B'],
  ['mam-s3', 42.18, 9.33, '2B'],
  ['mam-s4', 42.21, 9.21, '2B'],
  ['mam-s5', 42.25, 9.09, '2A'],
  ['mam-s6', 42.30, 8.98, '2A'],
  ['mam-s7', 42.34, 8.87, '2A'],
].map(([stageId, lat, lng, codeDepartement], i) => ({
  trailId: 'mare-a-mare-centre',
  stageId,
  stageNumber: i + 1,
  lat,
  lng,
  codeDepartement,
  zoneIncendie: null,
  massifIncendie: null,
}));

class DepotEnMemoire {
  constructor(etapes) {
    this.source = { etapes };
    this.registres = new Map();
    this.borne = null;
    this.collections = new Map();
    this.battements = {};
    this.ecrituresFaites = 0;
    this.octetsEcrits = 0;
  }

  async lireEnrolement() { return validerEnrolement(this.source); }
  async lireRegistre(f) { return this.registres.get(f) ?? { points: {}, empreintes: {} }; }
  async ecrireRegistre(f, r) { this.registres.set(f, r); this.ecrituresFaites += 1; }
  async lireBorne() { return this.borne; }

  async deposer(collection, aEcrire) {
    if (!this.collections.has(collection)) this.collections.set(collection, new Map());
    for (const { identite, document } of aEcrire) {
      this.collections.get(collection).set(identite, document);
      this.octetsEcrits += Buffer.byteLength(JSON.stringify(document), 'utf8');
    }
    this.ecrituresFaites += aEcrire.length;
    return aEcrire.length;
  }

  async avancerLaBorne(a) {
    this.borne = fusionner(this.borne, a);
    this.ecrituresFaites += 1;
    return this.borne;
  }

  async battre(t, s) { this.battements[t] = s; this.ecrituresFaites += 1; }
  async lireBattement() { return this.battements; }
  async deposerAlertes() { this.ecrituresFaites += 1; }
}

// Compte les octets REELLEMENT recus sur le reseau, corps compresse compris.
let appelsReseau = 0;
let octetsRecus = 0;
const fetchVrai = globalThis.fetch;
globalThis.fetch = async (url, options) => {
  appelsReseau += 1;
  const reponse = await fetchVrai(url, options);
  const copie = Buffer.from(await reponse.clone().arrayBuffer());
  octetsRecus += copie.length;
  return reponse;
};

const titre = (t) => console.log(`\n========== ${t} ==========`);
const ligne = (etiquette, valeur) => console.log(`${etiquette.padEnd(28)}: ${valeur}`);

const depot = new DepotEnMemoire(ETAPES);

titre('PASSAGE METEO 1 — cache vide');
let debut = Date.now();
let bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
ligne('duree (ms)', Date.now() - debut);
ligne('appels sortants', bilan.compte.appels);
ligne('octets recus', bilan.compte.octets);
ligne('documents ecrits', bilan.compte.ecrits);
ligne('refuses / echecs', `${bilan.compte.refuses} / ${bilan.compte.echecs}`);
ligne('octets ecrits (donnees)', depot.octetsEcrits);
ligne('operations d ecriture', depot.ecrituresFaites);
const exemple = depot.collections.get(COLLECTION_METEO)?.get('mare-a-mare-centre__mam-s1');
if (exemple !== undefined) {
  ligne('octets d un document', Buffer.byteLength(JSON.stringify(exemple), 'utf8'));
  ligne('jours rendus', `${exemple.jours.length} — ${exemple.jours.map((j) => j.jour).join(' ')}`);
  ligne('produiteLe (heure modele)', new Date(exemple.produiteLeMs).toISOString());
  ligne('exemple de jour', JSON.stringify(exemple.jours[0]));
}

titre('PASSAGE METEO 2 — immediat : Expires doit TOUT bloquer (licence MET Norway)');
let octetsAvant = depot.octetsEcrits;
let ecrituresAvant = depot.ecrituresFaites;
debut = Date.now();
bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
ligne('duree (ms)', Date.now() - debut);
ligne('appels sortants', `${bilan.compte.appels}  (0 attendu)`);
ligne('evites par le cache', bilan.compte.evitesParCache);
ligne('documents ecrits', bilan.compte.ecrits);
ligne('octets ecrits (delta)', depot.octetsEcrits - octetsAvant);
ligne('operations (delta)', depot.ecrituresFaites - ecrituresAvant);

titre('PASSAGE METEO 3 — cache force perime : revalidation conditionnelle');
for (const e of Object.values(depot.registres.get(FAMILLE_METEO).points)) e.valableJusquAMs = 0;
octetsAvant = depot.octetsEcrits;
ecrituresAvant = depot.ecrituresFaites;
debut = Date.now();
bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
ligne('duree (ms)', Date.now() - debut);
ligne('appels sortants', bilan.compte.appels);
ligne('octets recus', bilan.compte.octets);
ligne('documents ecrits', bilan.compte.ecrits);
ligne('inchanges', bilan.compte.inchanges);
ligne('octets ecrits (delta)', depot.octetsEcrits - octetsAvant);
ligne('operations (delta)', depot.ecrituresFaites - ecrituresAvant);

titre('PASSAGE INCENDIE — un seul appel national pour 96 departements');
const depotIncendie = new DepotEnMemoire(ETAPES);
debut = Date.now();
const bilanIncendie = await collecterLeRisqueIncendie({ depot: depotIncendie, configuration: CONFIGURATION });
ligne('duree (ms)', Date.now() - debut);
ligne('appels sortants', bilanIncendie.compte.appels);
ligne('octets recus', bilanIncendie.compte.octets);
ligne('documents ecrits', bilanIncendie.compte.ecrits);
ligne('refuses / echecs', `${bilanIncendie.compte.refuses} / ${bilanIncendie.compte.echecs}`);
ligne('octets ecrits (donnees)', depotIncendie.octetsEcrits);
ligne('operations d ecriture', depotIncendie.ecrituresFaites);
ligne('jour courant', bilanIncendie.jourCourant);
ligne('saison (lue du fichier)', JSON.stringify(bilanIncendie.saison));
const exempleIncendie = depotIncendie.collections.get(COLLECTION_INCENDIE)?.get('mare-a-mare-centre__mam-s1');
if (exempleIncendie !== undefined) {
  ligne('octets d un document', Buffer.byteLength(JSON.stringify(exempleIncendie), 'utf8'));
  ligne('dangerMeteo', JSON.stringify(exempleIncendie.dangerMeteo));
  ligne('acces (carte corse)', JSON.stringify(exempleIncendie.acces));
}

titre('TOTAUX RESEAU DE CETTE MESURE');
ligne('appels sortants reels', appelsReseau);
ligne('octets recus totaux', octetsRecus);

titre('EXTRAPOLATION — 10 sentiers de 7 etapes, soit 70 etapes');
const parEtape = exemple === undefined ? 0 : Buffer.byteLength(JSON.stringify(exemple), 'utf8');
const octetsMeteoParPassage = parEtape * 70;
ligne('meteo : appels / jour', `${70 * 6} (70 etapes x 6 passages)`);
ligne('meteo : ecritures / jour', `${70 * 6 + 6 * 2} (documents + registre + borne)`);
ligne('meteo : octets ecrits / jour', `${octetsMeteoParPassage * 6} (~${Math.round(octetsMeteoParPassage * 6 / 1024)} Kio)`);
ligne('meteo : lectures / jour', '12 (2 par passage : registre + borne)');
ligne('incendie : appels / jour', '3 (un fichier national, 3 passages)');
ligne('incendie : ecritures / jour', '~70 a 76 (seulement ce qui change)');
ligne('palier gratuit Firestore', '50 000 lectures, 20 000 ecritures par jour');
