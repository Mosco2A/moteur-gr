// UN PASSAGE COMPLET, DE BOUT EN BOUT. Tache 624.
//
// Execution : cd functions && node --test
//
// ============================================================================
// POURQUOI CE FICHIER EXISTE, ET C'EST LE MANDAT DE CHRISTOPHE DU 21/09
// ============================================================================
// « donne moi la version SEULEMENT quand elle est testee par les persona
// (passant / no passant et multi reponses (cas metiers)) et qu elle fonctionne ».
//
// Un chemin nominal qui marche ne suffit pas. Ce fichier exerce donc le passage
// ENTIER — reseau compris, mais avec un faux reseau et un faux depot — sur les cas
// qui comptent vraiment :
//   PASSANT      : sept etapes, une collecte, sept bulletins, une borne qui avance.
//   NON PASSANT  : la source est en panne -> RIEN n'est ecrit, la donnee de la
//                  veille reste, la borne NE bouge PAS, et le battement le DIT.
//   NON PASSANT  : la source rend un demi-bulletin -> refus, rien d'ecrit.
//   NON PASSANT  : la source rend une valeur folle -> refus COMPTE.
//   CAS METIER   : cinq etapes sur sept repondent -> on ecrit cinq (#T2).
//   CAS METIER   : rien n'a change -> ZERO ecriture, ZERO octet descendant.
//   CAS METIER   : le cache dit « encore valable » -> AUCUN appel reseau du tout.
//
// Le depot est un double en memoire : `collecte.js` recoit son depot en parametre,
// donc le passage entier est exercable sans Firestore et sans firebase-admin.

import assert from 'node:assert/strict';
import { beforeEach, afterEach, describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { gzipSync } from 'node:zlib';

import { collecterLaMeteo, collecterLeRisqueIncendie, surveiller } from '../collecteur/collecte.js';
import { COLLECTION_METEO, COLLECTION_INCENDIE, FAMILLE_METEO, FAMILLE_INCENDIE } from '../collecteur/documents.js';
import { validerEnrolement } from '../collecteur/enrolement.js';
import { fusionner } from '../collecteur/borne.js';

const ICI = dirname(fileURLToPath(import.meta.url));
const REPONSE_REELLE = JSON.parse(readFileSync(join(ICI, 'fixtures', 'met_norway_reel.json'), 'utf8'));
const CSV_REEL = readFileSync(join(ICI, 'fixtures', 'meteo_des_forets_reel.csv'), 'utf8');

const CONFIGURATION = Object.freeze({
  userAgent: 'StepWays/1.0 (https://stepways.app; contact@only1cent.com)',
  fournisseurMeteo: 'met-norway',
  joursPortee: 5,
  fuseauDefaut: 'Europe/Paris',
  corseActif: false,
  aBlanc: false,
});

function etapesDuMareAMare() {
  return Array.from({ length: 7 }, (_, i) => ({
    trailId: 'mare-a-mare-centre',
    stageId: `mam-s${i + 1}`,
    stageNumber: i + 1,
    lat: 42.3 + i * 0.05,
    lng: 9.15 + i * 0.05,
    codeDepartement: i < 4 ? '2A' : '2B',
    zoneIncendie: '203',
    massifIncendie: '2024',
  }));
}

/// Un depot en memoire : meme surface que `Depot`, zero Firestore.
class FauxDepot {
  constructor({ etapes }) {
    this.etapesEnrolees = { etapes };
    this.registres = new Map();
    this.borne = null;
    this.collections = new Map();
    this.battements = {};
    this.ecrituresFaites = 0;
    this.octetsEcrits = 0;
    this.appelsAvancerLaBorne = 0;
  }

  async lireEnrolement() { return validerEnrolement(this.etapesEnrolees); }

  async lireRegistre(famille) {
    return this.registres.get(famille) ?? { points: {}, empreintes: {} };
  }

  async ecrireRegistre(famille, registre) {
    this.registres.set(famille, registre);
    this.ecrituresFaites += 1;
  }

  async lireBorne() { return this.borne; }

  async deposer(collection, aEcrire) {
    if (!this.collections.has(collection)) this.collections.set(collection, new Map());
    const c = this.collections.get(collection);
    for (const { identite, document } of aEcrire) {
      c.set(identite, document);
      this.octetsEcrits += Buffer.byteLength(JSON.stringify(document), 'utf8');
    }
    this.ecrituresFaites += aEcrire.length;
    return aEcrire.length;
  }

  async avancerLaBorne(avancees) {
    this.appelsAvancerLaBorne += 1;
    this.borne = fusionner(this.borne, avancees);
    this.ecrituresFaites += 1;
    return this.borne;
  }

  async battre(tache, section) {
    this.battements[tache] = section;
    this.ecrituresFaites += 1;
  }

  async lireBattement() { return this.battements; }

  async deposerAlertes(alertes, passage) {
    this.battements.surveillant = { executeLe: passage.instant, alertes, nombre: alertes.length };
    this.ecrituresFaites += 1;
  }

  docsDe(collection) { return this.collections.get(collection) ?? new Map(); }
}

/// Un faux reseau. `reponses` est une fonction (url, options) -> Response.
let fetchOriginal;
function poserLeReseau(reponses) {
  globalThis.fetch = async (url, options) => reponses(String(url), options);
}
function reponseJson(objet, enTetes = {}) {
  return new Response(JSON.stringify(objet), {
    status: 200,
    headers: { 'Content-Type': 'application/json', ...enTetes },
  });
}

/// L'heure du modele du fixture est fixe ; on decale la reponse pour qu'elle reste
/// vraisemblable a l'instant du passage, qui est l'horloge reelle.
function reponseMeteoFraiche(surcharge = {}) {
  const copie = JSON.parse(JSON.stringify(REPONSE_REELLE));
  const decalage = Date.now() - Date.parse('2026-09-28T21:36:20Z');
  copie.properties.meta.updated_at = new Date(Date.parse(copie.properties.meta.updated_at) + decalage).toISOString();
  for (const p of copie.properties.timeseries) {
    p.time = new Date(Date.parse(p.time) + decalage).toISOString();
  }
  Object.assign(copie, surcharge);
  return copie;
}

beforeEach(() => { fetchOriginal = globalThis.fetch; });
afterEach(() => { globalThis.fetch = fetchOriginal; });

describe('METEO — le chemin PASSANT', () => {
  it('sept etapes, sept bulletins, une borne qui avance APRES les donnees', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    let appels = 0;
    poserLeReseau((url) => {
      assert.match(url, /api\.met\.no/);
      appels += 1;
      return reponseJson(reponseMeteoFraiche(), { Expires: new Date(Date.now() + 31 * 60e3).toUTCString() });
    });

    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(appels, 7, 'un appel par etape : MET Norway ne groupe pas les points');
    assert.equal(bilan.compte.ecrits, 7);
    assert.equal(depot.docsDe(COLLECTION_METEO).size, 7);
    // La borne a avance, et pour le bon sentier / la bonne famille.
    assert.equal(depot.appelsAvancerLaBorne, 1);
    assert.ok(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO]);
    assert.equal(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO], bilan.passage.instant);
    // Le battement dit qu on a collecte.
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].issue, 'collecte');
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].echecs, 0);
  });

  it('chaque document porte les DEUX dates et son attribution CC BY', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare().slice(0, 1) });
    poserLeReseau(() => reponseJson(reponseMeteoFraiche()));
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    const d = depot.docsDe(COLLECTION_METEO).get('mare-a-mare-centre__mam-s1');
    assert.ok(d.produiteLeMs > 0, 'l heure du MODELE, ce que l ecran affiche');
    assert.ok(typeof d.rev === 'string', 'l instant du passage, ce qui sert la synchronisation');
    assert.ok(!('collecteeLe' in d), 'un troisieme nom pour rev serait une seconde autorite');
    // CC BY 4.0 impose de crediter, de lier la licence ET d indiquer les
    // modifications — et nous en faisons une : l agregation journaliere.
    assert.match(d.attribution.fournisseur, /MET Norway/);
    assert.equal(d.attribution.licence, 'CC BY 4.0');
    assert.match(d.attribution.modifications, /agregation/);
    assert.equal(d.fuseau, 'Europe/Paris');
    assert.ok(d.jours.length >= 3 && d.jours.length <= 5);
  });
});

describe('METEO — les chemins NON PASSANTS', () => {
  it('SOURCE EN PANNE : rien n est ecrit, la donnee de la veille reste, la borne NE bouge PAS', async () => {
    // C est la question que le mandat demande de traiter explicitement. #T1 : « une
    // collecte qui echoue n ecrit RIEN. Pas une donnee vide, pas un null, pas un
    // enregistrement indisponible. Rien. »
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    // Un passage precedent a reussi : il y a donc une donnee « de la veille ».
    poserLeReseau(() => reponseJson(reponseMeteoFraiche()));
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    const borneAvant = depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO];
    const documentsAvant = new Map(depot.docsDe(COLLECTION_METEO));
    assert.equal(documentsAvant.size, 7);

    // Maintenant la source tombe. Le cache doit etre perime pour qu on rappelle.
    for (const entree of Object.values(depot.registres.get(FAMILLE_METEO).points)) {
      entree.valableJusquAMs = 0;
    }
    let appels = 0;
    poserLeReseau(() => { appels += 1; throw new TypeError('fetch failed'); });

    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(bilan.compte.ecrits, 0, 'aucune ecriture');
    assert.equal(bilan.compte.echecs, 7);
    // LA DONNEE DE LA VEILLE EST INTACTE, `rev` COMPRIS : elle ne redescend meme
    // pas vers les telephones. Un echec ne produit AUCUN octet de trafic.
    assert.equal(depot.docsDe(COLLECTION_METEO).size, 7);
    for (const [identite, avant] of documentsAvant) {
      assert.deepEqual(depot.docsDe(COLLECTION_METEO).get(identite), avant);
    }
    // LA BORNE N A PAS BOUGE : rien de neuf a annoncer.
    assert.equal(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO], borneAvant);
    // ET LE BATTEMENT LE DIT : c est le seul enregistrement dont l absence
    // informerait, et ici c est sa presence qui informe.
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].issue, 'echec');
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].echecs, 7);
  });

  it('NE BOUCLE PAS : au plus deux tentatives par etape, et AUCUNE sur un 4xx', async () => {
    // « le collecteur ne doit NI boucler NI effacer ». La cadence EST la politique
    // de reprise. Un 4xx n est pas un alea, c est un defaut : le reessayer par
    // lassitude finirait par le normaliser.
    const depot = new FauxDepot({ etapes: etapesDuMareAMare().slice(0, 1) });
    let appels5xx = 0;
    poserLeReseau(() => { appels5xx += 1; return new Response('boom', { status: 503 }); });
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(appels5xx, 2, 'un 5xx vaut une seconde chance, pas une boucle');

    const depot2 = new FauxDepot({ etapes: etapesDuMareAMare().slice(0, 1) });
    let appels4xx = 0;
    poserLeReseau(() => { appels4xx += 1; return new Response('non', { status: 403 }); });
    await collecterLaMeteo({ depot: depot2, configuration: CONFIGURATION });
    assert.equal(appels4xx, 1, 'un 4xx ne se reessaie PAS');
  });

  it('DEMI-BULLETIN : une source tronquee est REFUSEE, rien n est ecrit', async () => {
    // « Une etape a une meteo COMPLETE ou n en a pas. Une lecture concurrente de
    // l appli ne doit jamais tomber sur un demi-bulletin. »
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    poserLeReseau(() => {
      const tronquee = reponseMeteoFraiche();
      tronquee.properties.timeseries = tronquee.properties.timeseries.slice(0, 12);
      return reponseJson(tronquee);
    });
    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(bilan.compte.ecrits, 0);
    assert.equal(bilan.compte.refuses, 7);
    assert.equal(depot.docsDe(COLLECTION_METEO).size, 0);
    assert.equal(depot.appelsAvancerLaBorne, 0);
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].refuses, 7);
  });

  it('VALEUR FOLLE : refus COMPTE dans le battement (#A5)', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare().slice(0, 2) });
    poserLeReseau(() => {
      const folle = reponseMeteoFraiche();
      folle.properties.timeseries[3].data.instant.details.air_temperature = 120;
      return reponseJson(folle);
    });
    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(bilan.compte.refuses, 2);
    assert.equal(bilan.compte.ecrits, 0);
  });

  it('CINQ ETAPES SUR SEPT REPONDENT : on ecrit CINQ (#T2)', async () => {
    // « Sept etapes attendues, cinq recues : on ecrit cinq. Les deux autres gardent
    // leur donnee precedente. » Refuser tout le passage pour deux etapes priverait
    // de meteo les cinq qui vont bien.
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    let n = 0;
    poserLeReseau(() => {
      n += 1;
      if (n > 5) throw new TypeError('fetch failed');
      return reponseJson(reponseMeteoFraiche());
    });
    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(bilan.compte.ecrits, 5);
    assert.equal(bilan.compte.echecs, 2);
    assert.equal(depot.docsDe(COLLECTION_METEO).size, 5);
    // La borne avance quand meme : cinq bulletins neufs sont une vraie nouvelle.
    assert.ok(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO]);
  });

  it('ENROLEMENT VIDE OU ILLISIBLE : le battement bat quand meme', async () => {
    // Un refus muet serait indiscernable d un collecteur mort.
    const depot = new FauxDepot({ etapes: null });
    depot.etapesEnrolees = { pasDEtapes: true };
    let appels = 0;
    poserLeReseau(() => { appels += 1; return reponseJson({}); });
    const bilan = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(appels, 0, 'aucun appel reseau sans liste enrolee');
    assert.equal(bilan.alerte, 'enrolement-illisible');
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].issue, 'echec');
  });
});

describe('METEO — les cas metiers qui coutent de l argent', () => {
  it('RIEN N A CHANGE : zero ecriture de donnee, et la borne ne bouge pas (#G16)', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    const figee = reponseMeteoFraiche();
    poserLeReseau(() => reponseJson(figee));

    const premier = await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(premier.compte.ecrits, 7);
    const borneApresPremier = depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO];

    // Second passage : meme reponse, cache perime pour forcer les appels.
    for (const entree of Object.values(depot.registres.get(FAMILLE_METEO).points)) {
      entree.valableJusquAMs = 0;
    }
    const second = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(second.compte.ecrits, 0, 'aucun document reecrit');
    assert.equal(second.compte.inchanges, 7);
    // Incrementer pour rien ferait relire la liste a tous les telephones pour
    // n avoir rien a prendre.
    assert.equal(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_METEO], borneApresPremier);
    assert.equal(depot.battements.meteo.familles[FAMILLE_METEO].issue, 'inchange');
  });

  it('CACHE ENCORE VALABLE : AUCUN appel reseau — c est l obligation de licence', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    poserLeReseau(() => reponseJson(reponseMeteoFraiche(), {
      Expires: new Date(Date.now() + 31 * 60e3).toUTCString(),
    }));
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    let appels = 0;
    poserLeReseau(() => { appels += 1; return reponseJson(reponseMeteoFraiche()); });
    const second = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(appels, 0, 'MET Norway EXIGE qu on respecte Expires : zero appel');
    assert.equal(second.compte.evitesParCache, 7);
    assert.equal(second.compte.ecrits, 0);
  });

  it('UN 304 n ecrit aucune donnee et prolonge seulement la validite', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare().slice(0, 3) });
    poserLeReseau(() => reponseJson(reponseMeteoFraiche(), { ETag: '"v1"' }));
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    for (const entree of Object.values(depot.registres.get(FAMILLE_METEO).points)) {
      entree.valableJusquAMs = 0;
    }

    const enTetesRecus = [];
    poserLeReseau((url, options) => {
      enTetesRecus.push(options.headers);
      return new Response(null, { status: 304, headers: { 'Cache-Control': 'max-age=600' } });
    });
    const second = await collecterLaMeteo({ depot, configuration: CONFIGURATION });

    assert.equal(second.compte.ecrits, 0);
    assert.equal(second.compte.inchanges, 3);
    // La requete conditionnelle est bien partie, avec le validateur.
    assert.equal(enTetesRecus[0]['If-None-Match'], '"v1"');
    // Et le User-Agent est la, sur TOUS les appels : sans lui, bannissement.
    for (const e of enTetesRecus) assert.equal(e['User-Agent'], CONFIGURATION.userAgent);
  });

  it('TOUT APPEL porte le User-Agent, et les coordonnees sont tronquees a 4 decimales', async () => {
    // MET Norway DEMANDE la troncature : c est ce qui rend son cache efficace, et
    // cela fait partie du « cache data locally » de ses conditions.
    const depot = new FauxDepot({
      etapes: [{ trailId: 't', stageId: 's', lat: 42.3000123456, lng: 9.1500987654, codeDepartement: '2A' }],
    });
    const urls = [];
    poserLeReseau((url) => { urls.push(url); return reponseJson(reponseMeteoFraiche()); });
    await collecterLaMeteo({ depot, configuration: CONFIGURATION });
    assert.equal(urls.length, 1);
    assert.match(urls[0], /lat=42\.3&lon=9\.1501/);
  });
});

describe('RISQUE INCENDIE — de bout en bout', () => {
  /// La source reelle est un `.csv.gz`. On la GZIPPE donc vraiment, pour exercer la
  /// chaine entiere : transport -> decompression -> lecture UTF-8 -> semantique des
  /// colonnes. Un double qui rendrait du texte clair sauterait la decompression,
  /// c est-a-dire l endroit exact ou un mauvais encodage se verrait.
  function reponseCsvGzip(enTetes = {}) {
    return new Response(gzipSync(Buffer.from(CSV_REEL, 'utf8')), {
      status: 200,
      headers: { ETag: '"mdf1"', 'Last-Modified': 'Mon, 28 Sep 2026 15:15:30 GMT', ...enTetes },
    });
  }

  it('PASSANT : ecrit un document par etape, avec le niveau du JOUR', async () => {
    // Le fixture s arrete au 28/09 ; le niveau du jour vient donc de la ligne de la
    // VEILLE, et on se place « le 29 » pour que la chaine ait quelque chose a dire.
    // (Le passage lit l horloge reelle : ce test ne verifie donc pas la date, il
    // verifie que la chaine ecrit bien ce que la source donne, ou n ecrit RIEN quand
    // la source ne couvre plus le jour courant — les deux sont corrects.)
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    let appels = 0;
    poserLeReseau((url) => {
      assert.match(url, /meteofrance/);
      appels += 1;
      return reponseCsvGzip();
    });

    const bilan = await collecterLeRisqueIncendie({ depot, configuration: CONFIGURATION });

    assert.equal(appels, 1, 'UN seul appel pour les 96 departements : le fichier est national');
    assert.equal(bilan.compte.echecs, 0, 'la source a repondu');
    assert.equal(bilan.compte.refuses, 0, 'le fichier a ete lu sans refus');
    assert.ok(bilan.saison !== null, 'la saison est lue depuis le FICHIER');

    // Le passage LAISSE au surveillant ce qu il ne peut pas deduire seul (#H7),
    // sinon celui-ci devrait relire 70 documents pour savoir si le bulletin du jour
    // est arrive.
    const donnee = depot.battements.incendie.donnee;
    assert.ok(donnee !== null && donnee !== undefined, 'la section donnee du battement');
    assert.equal(donnee.jourCourant, bilan.jourCourant);
    assert.equal(donnee.saisonActive, true);
    assert.ok('jourDuBulletinLePlusAncien' in donnee);
    assert.equal(bilan.saison.dernierJourPublie, '2026-09-28');

    // Le fixture couvre jusqu au 30/09. Selon le jour ou ce test tourne, il y a des
    // bulletins ou il n y en a pas — et les deux comportements sont justes.
    const docs = depot.docsDe(COLLECTION_INCENDIE);
    if (bilan.compte.ecrits > 0) {
      assert.equal(docs.size, 7, 'une etape, un document');
      const d = docs.get('mare-a-mare-centre__mam-s1');
      assert.equal(d.codeDepartement, '2A');
      assert.ok(Array.isArray(d.dangerMeteo) && d.dangerMeteo.length > 0);
      assert.equal(d.dangerMeteo[0].portee, 'informative', 'Meteo-France INFORME, n interdit pas');
      assert.equal(d.dangerMeteo[0].attribution, 'Meteo-France');
      assert.equal(d.acces, null, 'la carte corse est eteinte');
      assert.ok(!('etat' in d), 'l etat est DERIVE par le lecteur, jamais stocke');
      assert.ok(typeof d.rev === 'string');
      assert.ok(depot.borne.sentiers['mare-a-mare-centre'][FAMILLE_INCENDIE]);
    } else {
      // Hors de la fenetre du fixture : le collecteur n ecrit PAS un vide (#T1).
      assert.equal(docs.size, 0);
      assert.equal(depot.appelsAvancerLaBorne, 0);
    }
  });

  it('UN SEUL APPEL sert les deux departements du sentier', async () => {
    // Le fichier est national : 96 departements en 47 Ko gzip. Interroger par
    // departement serait 96 fois plus d appels pour la meme donnee.
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    let appels = 0;
    poserLeReseau(() => { appels += 1; return reponseCsvGzip(); });
    await collecterLeRisqueIncendie({ depot, configuration: CONFIGURATION });
    const deps = new Set(etapesDuMareAMare().map((e) => e.codeDepartement));
    assert.equal(deps.size, 2);
    assert.equal(appels, 1);
  });

  it('la carte corse est ETEINTE : aucun appel, et le battement le NOMME', async () => {
    // Un silence se lirait comme « tout va bien », et c est ce que #I21 interdit.
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    const urls = [];
    poserLeReseau((url) => {
      urls.push(url);
      // Le vrai transport gunzip le corps ; ce test n exerce que l aiguillage.
      return new Response('', { status: 503 });
    });
    await collecterLeRisqueIncendie({ depot, configuration: CONFIGURATION });
    assert.ok(urls.every((u) => !u.includes('risque-prevention-incendie')));
    const section = depot.battements.incendie.familles.acces_corse;
    assert.equal(section.issue, 'eteint');
    assert.match(section.detail, /licence non etablie/);
  });

  it('SOURCE EN PANNE : rien n est ecrit et la borne ne bouge pas', async () => {
    const depot = new FauxDepot({ etapes: etapesDuMareAMare() });
    poserLeReseau(() => { throw new TypeError('fetch failed'); });
    const bilan = await collecterLeRisqueIncendie({ depot, configuration: CONFIGURATION });
    assert.equal(bilan.compte.ecrits, 0);
    assert.equal(depot.docsDe(COLLECTION_INCENDIE).size, 0);
    assert.equal(depot.appelsAvancerLaBorne, 0);
    assert.equal(depot.battements.incendie.familles[FAMILLE_INCENDIE].issue, 'echec');
  });

  it('un passage ecrit TOUJOURS son battement, meme sans rien collecter', async () => {
    const depot = new FauxDepot({ etapes: [] });
    poserLeReseau(() => new Response('', { status: 500 }));
    await collecterLeRisqueIncendie({ depot, configuration: CONFIGURATION });
    assert.ok(depot.battements.incendie);
    assert.ok(depot.battements.incendie.executeLe);
  });
});

describe('LE SURVEILLANT — un collecteur mort ne signale pas sa mort', () => {
  it('crie quand aucun battement n existe', async () => {
    const depot = new FauxDepot({ etapes: [] });
    const bilan = await surveiller({ depot, configuration: CONFIGURATION });
    assert.ok(bilan.alertes.length >= 2);
    assert.ok(bilan.alertes.some((a) => a.code === 'aucun-battement'));
    assert.equal(depot.battements.surveillant.nombre, bilan.alertes.length);
  });

  it('se tait quand les deux taches ont battu recemment', async () => {
    const depot = new FauxDepot({ etapes: [] });
    const maintenant = new Date().toISOString();
    depot.battements = {
      meteo: { executeLe: maintenant, familles: {} },
      incendie: { executeLe: maintenant, familles: {} },
    };
    const bilan = await surveiller({ depot, configuration: CONFIGURATION });
    assert.deepEqual(bilan.alertes, []);
  });
});
