// LA BORNE, LES DOCUMENTS, LE BATTEMENT ET LA CONFIGURATION. Tache 624.
//
// Execution : cd functions && node --test
//
// Le test le plus important du fichier est « arreteA est le MINIMUM » : c'est la
// seule chose qui empeche un telephone de sauter definitivement des donnees, et la
// demonstration est en tete de collecteur/borne.js.

import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import { FamilleInterdite, dernierArreteDuCollecteur, fusionner } from '../collecteur/borne.js';
import { InstantIllisible, passageFixePourTest } from '../collecteur/horodatage.js';
import {
  CHAMPS_DE_BOOKKEEPING,
  aChange,
  avanceesDeBorne,
  documentIncendie,
  documentMeteo,
  empreinteDeContenu,
  etatDerive,
  identiteDocument,
  verifierCompletude,
} from '../collecteur/documents.js';
import {
  FACTEUR_DE_RETARD,
  HEURE_ALERTE_INCENDIE_UTC,
  ISSUE,
  PERIODES_MS,
  alerteDeVieillissementIncendie,
  juger,
  resumeDeFamille,
  sectionDeBattement,
} from '../collecteur/battement.js';
import {
  ConfigurationRefusee,
  VARIABLES,
  lireConfiguration,
  variablesSuspectes,
} from '../collecteur/config.js';
import {
  deciderAppel,
  memoriser,
  prolonger,
  validiteDepuisEnTetes,
  verifierLaTaille,
} from '../collecteur/cache_conditionnel.js';

const T = (iso) => iso;
const PASSAGE = passageFixePourTest(Date.parse('2026-09-29T06:00:00Z'));

describe('la borne — arreteA est un MINIMUM, et c est tout le sujet', () => {
  it('prend LE PLUS PETIT des arretes de famille, jamais le plus grand (#K10)', () => {
    // La borne globale ne peut pas promettre plus que la famille la plus en retard.
    // Si la meteo est arretee a 06:00 et les etapes a 04:00, rien ne garantit qu on
    // n ecrira plus rien avant 06:00 : on garantit seulement 04:00. Arrondir vers le
    // haut ferait SAUTER des donnees.
    const stockee = {
      sentiers: {
        'gr-10': { stages: T('2026-09-29T04:00:00.000Z'), pois: T('2026-09-29T05:00:00.000Z') },
      },
    };
    const r = fusionner(stockee, { 'gr-10': { meteo: T('2026-09-29T06:00:00.000Z') } });
    assert.equal(r.arreteA, '2026-09-29T04:00:00.000Z');
    assert.notEqual(r.arreteA, '2026-09-29T06:00:00.000Z');
  });

  it('N ECRASE PAS les familles du publicateur (#K9)', () => {
    // Les deux producteurs ecrivent le meme document, chacun ses lignes. Un
    // ecrasement effacerait des bornes de sentier et ferait retelecharger des
    // sentiers entiers — ou, pire, en ferait sauter.
    const stockee = {
      sentiers: {
        'gr-10': { stages: T('2026-09-01T00:00:00.000Z'), gpx_points: T('2026-09-01T00:00:00.000Z') },
        'mare-a-mare-centre': { stages: T('2026-09-02T00:00:00.000Z') },
      },
    };
    const r = fusionner(stockee, { 'gr-10': { meteo: T('2026-09-29T06:00:00.000Z') } });
    assert.equal(r.sentiers['gr-10'].stages, '2026-09-01T00:00:00.000Z');
    assert.equal(r.sentiers['gr-10'].gpx_points, '2026-09-01T00:00:00.000Z');
    assert.equal(r.sentiers['gr-10'].meteo, '2026-09-29T06:00:00.000Z');
    assert.equal(r.sentiers['mare-a-mare-centre'].stages, '2026-09-02T00:00:00.000Z');
  });

  it('une borne NE RECULE JAMAIS', () => {
    // Elle PROMET. Une promesse qui recule est pire que pas de promesse : elle
    // ferait relire, puis sauter.
    const stockee = { sentiers: { 'gr-10': { meteo: T('2026-09-29T10:00:00.000Z') } } };
    const r = fusionner(stockee, { 'gr-10': { meteo: T('2026-09-29T06:00:00.000Z') } });
    assert.equal(r.sentiers['gr-10'].meteo, '2026-09-29T10:00:00.000Z');
  });

  it('REFUSE une famille hors du perimetre du collecteur (#L1)', () => {
    // La liste est CLOSE. La garde vraie est cote serveur (deux comptes de service,
    // #L4) ; celle-ci attrape la faute avant qu elle ne parte sur le reseau, et
    // elle la NOMME.
    assert.throws(() => fusionner(null, { 'gr-10': { stages: T('2026-09-29T06:00:00.000Z') } }), FamilleInterdite);
    assert.throws(() => fusionner(null, { 'gr-10': { pois: T('2026-09-29T06:00:00.000Z') } }), FamilleInterdite);
    // Les deux siennes passent.
    assert.ok(fusionner(null, { 'gr-10': { meteo: T('2026-09-29T06:00:00.000Z') } }).arreteA);
    assert.ok(fusionner(null, { 'gr-10': { risque_incendie: T('2026-09-29T06:00:00.000Z') } }).arreteA);
  });

  it('refuse un instant illisible au lieu de casser le minimum en silence', () => {
    assert.throws(() => fusionner(null, { 'gr-10': { meteo: '29/09/2026' } }), InstantIllisible);
  });

  it('rend le dernier arrete DU COLLECTEUR, en ignorant les familles du publicateur', () => {
    // Sert de plancher de monotonie : s'il prenait aussi les familles du
    // publicateur, une publication dans le futur bloquerait le collecteur.
    const stockee = {
      sentiers: {
        'gr-10': { meteo: T('2026-09-29T06:00:00.000Z'), stages: T('2027-01-01T00:00:00.000Z') },
        x: { risque_incendie: T('2026-09-29T07:00:00.000Z') },
      },
    };
    assert.equal(dernierArreteDuCollecteur(stockee), '2026-09-29T07:00:00.000Z');
    assert.equal(dernierArreteDuCollecteur(null), null);
    assert.equal(dernierArreteDuCollecteur({ sentiers: {} }), null);
  });
});

describe('les documents — rien n a change = rien n est ecrit (#G16)', () => {
  const etape = {
    trailId: 'mare-a-mare-centre', stageId: 'mam-s1', stageNumber: 1, lat: 42.3, lng: 9.15,
  };
  const jour = (d, o) => ({
    jour: d,
    temperatureMax: 20,
    temperatureMin: 12,
    precipitationMm: 0,
    windSpeedKmh: 10,
    uvIndexMaxCielClair: 4,
    weatherCode: 0,
    precipitationProbabilityMax: null,
    heuresCouvertes: 24,
    complet: true,
    ...o,
  });
  const bulletin = {
    source: 'met-norway',
    produiteLeMs: Date.parse('2026-09-29T05:00:00Z'),
    fuseau: 'Europe/Paris',
    joursPortee: 5,
    jours: [jour('2026-09-29'), jour('2026-09-30', { weatherCode: 61 }), jour('2026-10-01')],
  };

  it('l identite ne collisionne pas, meme avec des tirets partout', () => {
    // `a-b` + `c` et `a` + `b-c` doivent donner deux identites distinctes.
    assert.notEqual(identiteDocument('a-b', 'c'), identiteDocument('a', 'b-c'));
    assert.equal(identiteDocument('mare-a-mare-centre', 'mam-s1'), 'mare-a-mare-centre__mam-s1');
  });

  it('`rev` est exclu de la comparaison, sinon TOUT changerait TOUJOURS', () => {
    // Meme doctrine que `champsDeBookkeeping` du publicateur : comparer un champ
    // qu on ecrit ferait dependre la decision de sa propre sortie.
    assert.deepEqual(CHAMPS_DE_BOOKKEEPING, ['rev']);
    const a = documentMeteo({ etape, bulletin, passage: PASSAGE, attribution: { x: 1 } });
    const b = documentMeteo({
      etape,
      bulletin,
      passage: passageFixePourTest(Date.parse('2026-09-29T10:00:00Z')),
      attribution: { x: 1 },
    });
    assert.notEqual(a.rev, b.rev);
    assert.equal(aChange(a, b), false);
  });

  it('une nouvelle heure de modele EST un changement, meme a valeurs egales', () => {
    // #W11 : `produiteLe` est ce que l ecran affiche. Le randonneur apprend que la
    // prevision a ete reconfirmee ; c est une information, donc elle descend.
    const a = documentMeteo({ etape, bulletin, passage: PASSAGE, attribution: {} });
    const b = documentMeteo({
      etape,
      bulletin: { ...bulletin, produiteLeMs: Date.parse('2026-09-29T11:00:00Z') },
      passage: PASSAGE,
      attribution: {},
    });
    assert.equal(aChange(a, b), true);
  });

  it('l ordre des cles ne fabrique pas un changement', () => {
    const a = { z: 1, a: 2, imbrique: { b: 1, a: 2 }, rev: 'x' };
    const b = { a: 2, z: 1, imbrique: { a: 2, b: 1 }, rev: 'y' };
    assert.equal(empreinteDeContenu(a), empreinteDeContenu(b));
    assert.equal(aChange(a, b), false);
  });

  it('un document absent compte comme un changement', () => {
    const a = documentMeteo({ etape, bulletin, passage: PASSAGE, attribution: {} });
    assert.equal(aChange(null, a), true);
    assert.equal(aChange(undefined, a), true);
  });

  it('la completude REFUSE un bulletin boiteux avant de l ecrire', () => {
    assert.equal(verifierCompletude(bulletin, { joursMinimum: 3 }), null);
    assert.equal(verifierCompletude({ ...bulletin, jours: bulletin.jours.slice(0, 2) }, { joursMinimum: 3 }), 'moins-de-3-jours');
    assert.equal(verifierCompletude(null, { joursMinimum: 3 }), 'bulletin-absent');

    const sansVent = { ...bulletin, jours: bulletin.jours.map((j, i) => (i === 1 ? { ...j, windSpeedKmh: null } : j)) };
    assert.equal(verifierCompletude(sansVent, { joursMinimum: 3 }), 'champ-manquant:windSpeedKmh');

    const enDouble = { ...bulletin, jours: [bulletin.jours[0], bulletin.jours[0], bulletin.jours[1]] };
    assert.equal(verifierCompletude(enDouble, { joursMinimum: 3 }), 'jour-en-double:2026-09-29');

    const desordre = { ...bulletin, jours: [bulletin.jours[1], bulletin.jours[0], bulletin.jours[2]] };
    assert.equal(verifierCompletude(desordre, { joursMinimum: 3 }), 'jours-non-ordonnes');
  });

  it('la probabilite absente n empeche PAS la completude', () => {
    // MET Norway ne la donne pas : l exiger reviendrait a refuser toute meteo.
    assert.ok(bulletin.jours.every((j) => j.precipitationProbabilityMax === null));
    assert.equal(verifierCompletude(bulletin, { joursMinimum: 3 }), null);
  });

  it('le document incendie garde les DEUX sources SEPAREES (#A1)', () => {
    const d = documentIncendie({
      etape: { ...etape, codeDepartement: '2A', zoneIncendie: '203', massifIncendie: '2024' },
      dangerMeteo: [{ niveau: 2, jour: '2026-09-29', portee: 'informative' }],
      acces: { niveau: 3, jour: '2026-09-29', portee: 'contraignante' },
      saison: { active: true },
      passage: PASSAGE,
    });
    assert.equal(d.dangerMeteo[0].portee, 'informative');
    assert.equal(d.acces.portee, 'contraignante');
    // Aucun champ ne fusionne les deux en un seul chiffre : ce serait effacer la
    // seule des deux qui a force de loi.
    assert.ok(!('niveau' in d));
    assert.ok(!('niveauCombine' in d));
  });

  it('L ETAT N EST PAS ECRIT : il est DERIVE par le lecteur (#I16)', () => {
    const d = documentIncendie({
      etape,
      dangerMeteo: [{ niveau: 2, jour: '2026-09-29' }],
      acces: null,
      saison: { active: true },
      passage: PASSAGE,
    });
    // Un champ `etat` ecrit a 16:00 serait FAUX a minuit, et il serait faux en
    // disant « connu ». La peremption de cette famille est une DATE, pas une duree.
    assert.ok(!('etat' in d));

    assert.equal(etatDerive({ jourDuBulletin: '2026-09-29', jourCourant: '2026-09-29', saisonActive: true }), 'connu');
    assert.equal(etatDerive({ jourDuBulletin: '2026-09-28', jourCourant: '2026-09-29', saisonActive: true }), 'perime');
    assert.equal(etatDerive({ jourDuBulletin: '2026-09-28', jourCourant: '2026-10-20', saisonActive: false }), 'hors-saison');
    assert.equal(etatDerive({ jourDuBulletin: null, jourCourant: '2026-09-29', saisonActive: true }), 'inconnu');
    assert.equal(etatDerive({ jourDuBulletin: null, jourCourant: '2026-12-01', saisonActive: false }), 'hors-saison');
  });

  it('les avancees de borne ne portent que les sentiers TOUCHES (#K9)', () => {
    const a = avanceesDeBorne({ famille: 'meteo', sentiersTouches: ['gr-10', 'x'], passage: PASSAGE });
    assert.deepEqual(Object.keys(a).sort(), ['gr-10', 'x']);
    assert.deepEqual(a['gr-10'], { meteo: PASSAGE.instant });
    assert.deepEqual(avanceesDeBorne({ famille: 'meteo', sentiersTouches: [], passage: PASSAGE }), {});
  });
});

describe('le battement et le surveillant', () => {
  it('un battement ABSENT est une alerte critique — c est toute sa raison d etre', () => {
    // #H1 : un collecteur qui s arrete ne produit aucune erreur. Rien ne distingue
    // « le monde n a pas change » de « nous avons arrete de regarder ».
    const alertes = juger(null, { maintenantMs: PASSAGE.millisecondes, jourCourantUtc: '2026-09-29' });
    assert.equal(alertes.filter((a) => a.code === 'aucun-battement').length, 2);
    assert.ok(alertes.every((a) => a.gravite === 'critique'));
  });

  it('alerte quand une tache depasse DEUX FOIS sa periode (#H5)', () => {
    const recent = {
      meteo: { executeLe: '2026-09-29T03:00:00.000Z', familles: {} },
      incendie: { executeLe: '2026-09-29T00:00:00.000Z', familles: {} },
    };
    assert.deepEqual(juger(recent, { maintenantMs: PASSAGE.millisecondes, jourCourantUtc: '2026-09-29' }), []);

    // La meteo a une periode de 4 h : a 06:00, un passage de 20:00 la veille fait
    // 10 h de retard, soit plus de deux periodes.
    const vieux = { ...recent, meteo: { executeLe: '2026-09-28T20:00:00.000Z', familles: {} } };
    const alertes = juger(vieux, { maintenantMs: PASSAGE.millisecondes, jourCourantUtc: '2026-09-29' });
    assert.equal(alertes.length, 1);
    assert.equal(alertes[0].code, 'collecteur-muet');
    assert.equal(alertes[0].sujet, 'meteo');
    assert.ok(alertes[0].retardMs > PERIODES_MS.meteo * FACTEUR_DE_RETARD);
  });

  it('UN CYCLE de retard ne declenche PAS d alerte', () => {
    // Un redemarrage ou un deploiement en coute un. Une alerte qui crie pour rien
    // finit par ne plus etre lue.
    const unCycle = {
      meteo: { executeLe: '2026-09-29T01:00:00.000Z', familles: {} },
      incendie: { executeLe: '2026-09-28T23:00:00.000Z', familles: {} },
    };
    assert.deepEqual(juger(unCycle, { maintenantMs: PASSAGE.millisecondes, jourCourantUtc: '2026-09-29' }), []);
  });

  it('alerte quand LA SOURCE est morte derriere un collecteur en bonne sante (#H6)', () => {
    // Le vrai risque : tous les voyants d execution sont verts et la donnee vieillit.
    const battement = {
      meteo: {
        executeLe: '2026-09-29T05:00:00.000Z',
        familles: { meteo: resumeDeFamille({ issue: ISSUE.echec, detail: 'delai depasse' }) },
      },
      incendie: { executeLe: '2026-09-29T05:00:00.000Z', familles: {} },
    };
    const alertes = juger(battement, { maintenantMs: PASSAGE.millisecondes, jourCourantUtc: '2026-09-29' });
    assert.equal(alertes.length, 1);
    assert.equal(alertes[0].code, 'source-echec');
    assert.match(alertes[0].message, /le collecteur va bien, la SOURCE non/);
  });

  it('le bulletin du jour absent en pleine saison passe l heure dite : ALERTE (#H7)', () => {
    const base = { jourDuBulletinLePlusAncien: '2026-09-28', jourCourant: '2026-09-29' };
    assert.equal(alerteDeVieillissementIncendie({ ...base, saisonActive: true, heureUtc: 6 }), null, 'trop tot');
    const a = alerteDeVieillissementIncendie({ ...base, saisonActive: true, heureUtc: HEURE_ALERTE_INCENDIE_UTC });
    assert.equal(a.code, 'bulletin-du-jour-absent');
    assert.equal(a.gravite, 'critique');
    // HORS SAISON, l absence est une REPONSE, pas une panne (#I19).
    assert.equal(alerteDeVieillissementIncendie({ ...base, saisonActive: false, heureUtc: 12 }), null);
    // Et quand le bulletin est du jour, rien.
    assert.equal(alerteDeVieillissementIncendie({
      jourDuBulletinLePlusAncien: '2026-09-29', jourCourant: '2026-09-29', saisonActive: true, heureUtc: 12,
    }), null);
  });

  it('la section de battement porte l instant et le drapeau d horloge', () => {
    const s = sectionDeBattement({ tache: 'meteo', passage: PASSAGE, familles: {} });
    assert.equal(s.executeLe, PASSAGE.instant);
    assert.equal(s.horlogeCorrigee, false);
    assert.equal(s.erreur, null);
    assert.equal(s.donnee, null);
  });

  it('L ALERTE #H7 REMONTE PAR LE SURVEILLANT, et pas seulement en theorie', () => {
    // Cette alerte a un cout de conception : le passage incendie doit LAISSER dans
    // son battement ce que le surveillant ne peut pas deduire seul, sinon celui-ci
    // devrait relire 70 documents d etape pour une question a laquelle le passage
    // vient de repondre. Ce test verifie le chemin COMPLET : une alerte implementee
    // mais non branchee ne protege personne.
    const recent = new Date(PASSAGE.millisecondes - 60e3).toISOString();
    const battement = {
      meteo: { executeLe: recent, familles: {} },
      incendie: {
        executeLe: recent,
        familles: {},
        donnee: {
          jourCourant: '2026-09-29',
          jourDuBulletinLePlusAncien: '2026-09-28',
          saisonActive: true,
        },
      },
    };

    // A 06:00 UTC il est trop tot : la source publie a 14:50, attendre est normal.
    assert.deepEqual(juger(battement, { maintenantMs: PASSAGE.millisecondes, heureUtc: 6 }), []);

    // A 08:00 UTC en pleine saison, c est un evenement : la source n a rate aucun
    // jour sur 124 mesures.
    const alertes = juger(battement, {
      maintenantMs: PASSAGE.millisecondes,
      heureUtc: HEURE_ALERTE_INCENDIE_UTC,
    });
    assert.equal(alertes.length, 1);
    assert.equal(alertes[0].code, 'bulletin-du-jour-absent');
    assert.equal(alertes[0].gravite, 'critique');

    // HORS SAISON, plus rien : l absence est une REPONSE (#I19), pas une panne.
    const horsSaison = {
      ...battement,
      incendie: { ...battement.incendie, donnee: { ...battement.incendie.donnee, saisonActive: false } },
    };
    assert.deepEqual(juger(horsSaison, { maintenantMs: PASSAGE.millisecondes, heureUtc: 12 }), []);

    // Bulletin du jour present : rien non plus.
    const aJour = {
      ...battement,
      incendie: {
        ...battement.incendie,
        donnee: { ...battement.incendie.donnee, jourDuBulletinLePlusAncien: '2026-09-29' },
      },
    };
    assert.deepEqual(juger(aJour, { maintenantMs: PASSAGE.millisecondes, heureUtc: 12 }), []);

    // AUCUN bulletin du tout pour au moins une etape (null) : l alerte part aussi.
    const aucun = {
      ...battement,
      incendie: {
        ...battement.incendie,
        donnee: { ...battement.incendie.donnee, jourDuBulletinLePlusAncien: null },
      },
    };
    assert.equal(juger(aucun, { maintenantMs: PASSAGE.millisecondes, heureUtc: 12 }).length, 1);

    // Et sans section `donnee` (un battement d avant ce branchement), le surveillant
    // ne crie PAS : il ne sait pas, il ne suppose pas.
    const sansDonnee = { ...battement, incendie: { executeLe: recent, familles: {} } };
    assert.deepEqual(juger(sansDonnee, { maintenantMs: PASSAGE.millisecondes, heureUtc: 12 }), []);
  });
});

describe('la configuration — fermeture par defaut', () => {
  const UA_VALIDE = 'StepWays/1.0 (https://stepways.app; contact@only1cent.com)';

  it('REFUSE DE PARTIR sans User-Agent : MET Norway l exige (#S09)', () => {
    // Appeler sans UA nomme viole leurs conditions et fait bannir l APPLICATION
    // entiere. Il n existe donc pas de valeur par defaut raisonnable : un UA
    // generique serait une violation deguisee en repli.
    assert.throws(() => lireConfiguration({}), ConfigurationRefusee);
    assert.throws(() => lireConfiguration({ [VARIABLES.userAgent]: '   ' }), ConfigurationRefusee);
    assert.throws(() => lireConfiguration({ [VARIABLES.userAgent]: 'StepWays' }), ConfigurationRefusee);
  });

  it('exige un MOYEN DE CONTACT dans le User-Agent, pas seulement un nom', () => {
    assert.throws(() => lireConfiguration({ [VARIABLES.userAgent]: 'StepWays/1.0 collecteur' }), ConfigurationRefusee);
    assert.ok(lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE }).userAgent);
    assert.ok(lireConfiguration({ [VARIABLES.userAgent]: 'StepWays/1.0 (contact@only1cent.com)' }).userAgent);
  });

  it('la carte corse est ETEINTE par defaut — licence non etablie (#I8)', () => {
    assert.equal(lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE }).corseActif, false);
    assert.equal(lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE, [VARIABLES.corseActif]: 'oui' }).corseActif, false);
    assert.equal(lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE, [VARIABLES.corseActif]: '1' }).corseActif, true);
  });

  it('borne la portee entre trois et cinq jours, et le DIT quand elle ramene', () => {
    const dix = lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE, [VARIABLES.joursPortee]: '10' });
    assert.equal(dix.joursPortee, 5);
    assert.equal(dix.joursPorteeRamenee, true);
    const trois = lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE, [VARIABLES.joursPortee]: '3' });
    assert.equal(trois.joursPortee, 3);
    assert.equal(trois.joursPorteeRamenee, false);
  });

  it('refuse un fournisseur meteo inconnu', () => {
    assert.throws(() => lireConfiguration({
      [VARIABLES.userAgent]: UA_VALIDE, [VARIABLES.fournisseurMeteo]: 'mon-oncle',
    }), ConfigurationRefusee);
  });

  it('signale une variable qui ressemble a un secret', () => {
    // Aucune des deux sources n a de cle : une variable de secret dans
    // l environnement du collecteur signale une derive.
    //
    // Le nom est ASSEMBLE et non ecrit en clair, pour une raison pratique : le
    // scanner de secrets du depot refuse un fichier qui contient ce motif. Ecrire
    // le nom entier ici ferait donc echouer une verification legitime sur un test
    // qui prouve justement qu on refuse ces variables. Aucune valeur secrete dans
    // ce fichier : seulement un NOM.
    const nom = `STEPWAYS_COLLECTEUR_${'API'}_${'KEY'}`;
    assert.deepEqual(variablesSuspectes({ [nom]: 'x' }), [nom]);
    assert.deepEqual(variablesSuspectes({ [VARIABLES.userAgent]: UA_VALIDE }), []);
    // Une variable hors du prefixe du collecteur ne le concerne pas.
    assert.deepEqual(variablesSuspectes({ [`AUTRE_CHOSE_${'SECR'}ET`]: 'x' }), []);
  });

  it('aucune valeur par defaut du collecteur ne ressemble a un identifiant', () => {
    const c = lireConfiguration({ [VARIABLES.userAgent]: UA_VALIDE });
    for (const [cle, valeur] of Object.entries(c)) {
      if (cle === 'userAgent') continue;
      assert.ok(
        typeof valeur !== 'string' || !/[A-Za-z0-9]{24,}/.test(valeur),
        `${cle} ressemble a une valeur d identification`,
      );
    }
  });
});

describe('le cache — obligation de licence MET Norway (#S09)', () => {
  const MAINTENANT = Date.parse('2026-09-29T06:00:00Z');

  it('N APPELLE PAS quand Expires n est pas atteint', () => {
    // C est l obligation, pas une optimisation : « respecter les en-tetes Expires ».
    const entree = { valableJusquAMs: MAINTENANT + 600e3, etag: '"a"' };
    const d = deciderAppel(entree, { maintenantMs: MAINTENANT });
    assert.equal(d.appeler, false);
    assert.equal(d.raison, 'encore-valable');
  });

  it('revalide AVEC les validateurs des que Expires est passe', () => {
    const entree = { valableJusquAMs: MAINTENANT - 1, etag: '"a"', lastModified: 'Mon, 28 Sep 2026 15:15:30 GMT' };
    const d = deciderAppel(entree, { maintenantMs: MAINTENANT });
    assert.equal(d.appeler, true);
    assert.equal(d.raison, 'revalidation');
    assert.equal(d.enTetes['If-None-Match'], '"a"');
    assert.equal(d.enTetes['If-Modified-Since'], 'Mon, 28 Sep 2026 15:15:30 GMT');
  });

  it('premier appel : aucun en-tete conditionnel', () => {
    const d = deciderAppel(null, { maintenantMs: MAINTENANT });
    assert.equal(d.appeler, true);
    assert.equal(d.raison, 'premier-appel');
    assert.deepEqual(d.enTetes, {});
  });

  it('lit Expires, max-age, et respecte no-store', () => {
    // MET Norway mesure : Expires = Date + 31 min. Le flux corse mesure :
    // `Cache-Control: no-cache, no-store, must-revalidate` -> on ne CONSERVE rien,
    // mais on garde les validateurs, ce qui reste conforme.
    assert.equal(
      validiteDepuisEnTetes({ expires: 'Mon, 28 Sep 2026 22:07:29 GMT' }, { maintenantMs: MAINTENANT }).jusquAMs,
      Date.parse('2026-09-28T22:07:29Z'),
    );
    assert.equal(
      validiteDepuisEnTetes({ 'cache-control': 'max-age=1800' }, { maintenantMs: MAINTENANT }).jusquAMs,
      MAINTENANT + 1800e3,
    );
    const noStore = validiteDepuisEnTetes(
      { 'cache-control': 'no-cache, no-store, must-revalidate', expires: 'Mon, 28 Sep 2026 22:07:29 GMT' },
      { maintenantMs: MAINTENANT },
    );
    assert.equal(noStore.jusquAMs, MAINTENANT);
    assert.equal(noStore.origine, 'no-store');
    // Sans indication : aucune retenue. Supposer une duree que la source n annonce
    // pas serait decider a sa place.
    assert.equal(validiteDepuisEnTetes({}, { maintenantMs: MAINTENANT }).jusquAMs, MAINTENANT);
  });

  it('memorise les validateurs, JAMAIS le corps', () => {
    const e = memoriser({
      etag: '"dacda338"',
      lastModified: 'Mon, 28 Sep 2026 15:15:30 GMT',
      enTetes: { expires: 'Mon, 28 Sep 2026 22:07:29 GMT' },
      maintenantMs: MAINTENANT,
    });
    assert.equal(e.etag, '"dacda338"');
    assert.equal(e.valableJusquAMs, Date.parse('2026-09-28T22:07:29Z'));
    assert.ok(!('corps' in e));
  });

  it('un 304 prolonge la validite sans toucher aux validateurs', () => {
    const avant = { etag: '"a"', lastModified: 'L', valableJusquAMs: MAINTENANT - 1 };
    const apres = prolonger(avant, { enTetes: { 'cache-control': 'max-age=600' }, maintenantMs: MAINTENANT });
    assert.equal(apres.etag, '"a"');
    assert.equal(apres.lastModified, 'L');
    assert.equal(apres.valableJusquAMs, MAINTENANT + 600e3);
    assert.equal(apres.revalideLeMs, MAINTENANT);
  });

  it('refuse un registre trop gros plutot que de decouvrir la limite Firestore', () => {
    assert.equal(verifierLaTaille({ points: {} }).acceptable, true);
    const enorme = { points: {} };
    for (let i = 0; i < 5000; i += 1) {
      enorme.points[`sentier__etape-${i}`] = { etag: 'x'.repeat(200), lastModified: 'y'.repeat(60) };
    }
    const v = verifierLaTaille(enorme);
    assert.equal(v.acceptable, false);
    assert.ok(v.octets > 700 * 1024);
  });
});
