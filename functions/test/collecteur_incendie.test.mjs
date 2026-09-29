// LE RISQUE INCENDIE — lecture des deux sources. Tache 624.
//
// Execution : cd functions && node --test
//
// Le fixture `meteo_des_forets_reel.csv` est un EXTRAIT REEL du fichier de
// Meteo-France (mdf_2026.csv.gz), telecharge le 28/09/2026 a 21:33 UTC : six jours
// de production, trois departements (07, 2A, 2B). Rien n'a ete invente, rien n'a
// ete reformate.
//
// LE TEST CENTRAL DE CE FICHIER est « le niveau du jour vient de la ligne de la
// VEILLE » : c'est la correction que ma mesure apporte a la conception 611, et
// s'en tromper afficherait la prevision de demain comme etant celle d'aujourd'hui,
// en pleine saison des feux.

import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  JOURS_AVANT_HORS_SAISON,
  LIBELLES,
  PORTEE as PORTEE_MDF,
  REFUS as REFUS_MDF,
  bulletinPourDepartement,
  joursPourDepartement,
  lireMeteoDesForets,
} from '../collecteur/incendie_mdf.js';

import {
  ECHELLE_ETABLIE,
  LICENCE as LICENCE_CORSE,
  PORTEE as PORTEE_CORSE,
  REFUS as REFUS_CORSE,
  accesPourEtape,
  lireCarteCorse,
  nomDeFichierPour,
} from '../collecteur/incendie_corse.js';

const ICI = dirname(fileURLToPath(import.meta.url));
const CSV = readFileSync(join(ICI, 'fixtures', 'meteo_des_forets_reel.csv'), 'utf8');

/// Le dernier jour de production du fixture est le 28/09 ; on se place donc « le
/// 29 », jour pour lequel ce fichier porte un niveau (via `niveau_j1` du 28).
const JOUR_COURANT = '2026-09-29';

describe('Meteo des forets — la semantique des colonnes, MESUREE', () => {
  it('LE NIVEAU DU JOUR VIENT DE LA LIGNE DE LA VEILLE, champ niveau_j1', () => {
    // La colonne `date` est un INSTANT DE PRODUCTION (`2026-09-28T14:50:06Z`), pas
    // une date de validite. `niveau_j1` vise donc le LENDEMAIN de la production.
    // Verifie statistiquement sur les 11 808 paires du fichier complet :
    //   ligne(D).niveau_j2 == ligne(D+1).niveau_j1 -> 87,9 %  (meme jour cible)
    //   ligne(D).niveau_j1 == ligne(D+1).niveau_j1 -> 75,7 %  (jours decales)
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    assert.ok(lu.ok, JSON.stringify(lu));

    const bulletin = bulletinPourDepartement(lu, '2A', JOUR_COURANT);
    assert.ok(bulletin !== null, 'le 29 doit etre couvert par la production du 28');
    // La production qui porte ce niveau est bien celle de la VEILLE.
    assert.equal(bulletin.jourDeProduction, '2026-09-28');
    assert.equal(bulletin.jour, '2026-09-29');
    assert.ok(bulletin.produiteLe.startsWith('2026-09-28T14:50'));
  });

  it('le fichier ne dit RIEN du jour de sa propre production', () => {
    // Consequence directe : demander le niveau du 28 doit puiser dans la
    // production du 27, pas dans celle du 28.
    const lu = lireMeteoDesForets(CSV, { jourCourant: '2026-09-28' });
    const b = bulletinPourDepartement(lu, '2A', '2026-09-28');
    assert.ok(b !== null);
    assert.equal(b.jourDeProduction, '2026-09-27');
  });

  it('entre deux annonces du meme jour, la production la PLUS RECENTE gagne (#A4)', () => {
    // Le 30/09 est annonce deux fois : par `niveau_j2` du 28 et — s il existait —
    // par `niveau_j1` du 29. Dans ce fixture la derniere production est le 28, donc
    // le 30 vient de son `niveau_j2`.
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    const b = bulletinPourDepartement(lu, '2A', '2026-09-30');
    assert.ok(b !== null);
    assert.equal(b.jourDeProduction, '2026-09-28');
  });

  it('porte un libelle OFFICIEL, et se declare INFORMATIF (#I7)', () => {
    // Meteo-France ecrit elle-meme que la Meteo des forets N EST PAS une
    // interdiction : les prefectures restent souveraines. Ecrit dans la donnee, il
    // n y a plus d arbitrage a faire a l ecran.
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    const b = bulletinPourDepartement(lu, '2B', JOUR_COURANT);
    assert.equal(b.libelle, LIBELLES[b.niveau]);
    assert.equal(b.portee, PORTEE_MDF);
    assert.equal(b.portee, 'informative');
    assert.equal(b.attribution, 'Meteo-France');
    assert.match(b.licence, /Licence Ouverte/);
  });

  it('rend jusqu a trois jours, dans l ordre, sans jamais combler un trou', () => {
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    const jours = joursPourDepartement(lu, '2A', JOUR_COURANT);
    assert.ok(jours.length >= 2 && jours.length <= 3);
    const etiquettes = jours.map((j) => j.jour);
    assert.deepEqual(etiquettes, [...etiquettes].sort());
    // Aucun jour au-dela de J+2 de la derniere production : on n extrapole pas.
    assert.ok(etiquettes.every((j) => j <= '2026-09-30'));
  });

  it('un departement absent rend null, PAS un niveau par defaut', () => {
    // #I21 : « pas de niveau modere par defaut : un defaut vert est un mensonge
    // confortable ».
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    assert.equal(bulletinPourDepartement(lu, '75', JOUR_COURANT), null);
    assert.equal(bulletinPourDepartement(lu, '2A', '2030-01-01'), null);
    assert.deepEqual(joursPourDepartement(lu, '75', JOUR_COURANT), []);
  });
});

describe('Meteo des forets — la saison vient du FICHIER, pas d un calendrier', () => {
  it('declare la saison ACTIVE quand la derniere production est recente', () => {
    const lu = lireMeteoDesForets(CSV, { jourCourant: JOUR_COURANT });
    assert.equal(lu.saison.active, true);
    assert.equal(lu.saison.dernierJourPublie, '2026-09-28');
    assert.equal(lu.saison.retardEnJours, 1);
  });

  it('declare la saison TERMINEE quand la source s est tue — et c est une REPONSE', () => {
    // #I19 : « hors saison n est pas une absence, c est une reponse, et il faut la
    // distinguer d une panne — sinon on apprend au randonneur a ignorer le
    // message ». C est la source qui le dit, pas un mois code en dur : #R7 note
    // qu on ne sait pas encore ce que ce fichier fait en octobre, donc on le lui
    // demande a chaque passage.
    const lu = lireMeteoDesForets(CSV, { jourCourant: '2026-10-20' });
    assert.equal(lu.saison.active, false);
    assert.ok(lu.saison.retardEnJours > JOURS_AVANT_HORS_SAISON);
  });

  it('deux jours de silence ne suffisent pas a declarer la fin de saison', () => {
    // La source n a rate aucun jour sur 124 : un jour de silence est un alea, deux
    // restent tolerables, au-dela c est la saison.
    assert.equal(lireMeteoDesForets(CSV, { jourCourant: '2026-09-30' }).saison.active, true);
    assert.equal(lireMeteoDesForets(CSV, { jourCourant: '2026-10-05' }).saison.active, false);
  });
});

describe('Meteo des forets — les refus', () => {
  it('refuse des colonnes inattendues plutot que de lire de travers', () => {
    const r = lireMeteoDesForets('a;b;c\n1;2;3\n', { jourCourant: JOUR_COURANT });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS_MDF.colonnes);
  });

  it('refuse un niveau hors de l echelle 1..4 (#A5)', () => {
    const abime = CSV.replace(';2;2;Corse-du-Sud', ';7;2;Corse-du-Sud');
    const r = lireMeteoDesForets(abime, { jourCourant: JOUR_COURANT });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS_MDF.niveauHorsDomaine);
  });

  it('refuse un fichier vide', () => {
    assert.equal(lireMeteoDesForets('', { jourCourant: JOUR_COURANT }).raison, REFUS_MDF.vide);
    assert.equal(lireMeteoDesForets('date;num_dep;niveau_j1;niveau_j2;nom_dep\n', { jourCourant: JOUR_COURANT }).raison, REFUS_MDF.vide);
  });
});

describe('carte corse — deux espaces de noms qui se ressemblent', () => {
  /// Extrait REEL du flux du 28/09/2026 (982 octets a l origine). Les
  /// identifiants 207, 211, 213, 214 et 215 sont presents dans LES DEUX
  /// dictionnaires du fichier reel, et ne designent pas la meme chose.
  const FLUX = {
    massifs: { 211: [2, 0], 213: [2, 0], 214: [1, 0], 207: [1, 0], 2024: [2, 0] },
    zm: { 201: 1, 203: 2, 207: 2, 211: 2, 213: 2, 214: 3 },
  };

  it('ne confond JAMAIS un massif et une zone qui portent le meme numero', () => {
    // Le piege est mesure : massif 214 vaut 1, zone 214 vaut 3. Un dictionnaire
    // unique rendrait un niveau faux SANS qu aucune erreur ne se produise — et
    // c est une donnee de securite.
    const lu = lireCarteCorse(FLUX, { jour: '2026-09-29' });
    assert.ok(lu.ok);
    assert.equal(lu.massifs.get('214').niveau, 1);
    assert.equal(lu.zones.get('214').niveau, 3);
    assert.equal(lu.massifs.size, 5);
    assert.equal(lu.zones.size, 6);
  });

  it('prend le MAXIMUM du massif et de la zone (#I12)', () => {
    // « Une donnee de securite s arrondit VERS LE HAUT. » Jamais la moyenne, jamais
    // « le massif parce qu il est plus fin ».
    const lu = lireCarteCorse(FLUX, { jour: '2026-09-29' });
    const a = accesPourEtape(lu, { massifIncendie: '214', zoneIncendie: '214' });
    assert.equal(a.niveau, 3);
    assert.equal(a.niveauMassif, 1);
    assert.equal(a.niveauZone, 3);
  });

  it('fonctionne avec un seul des deux rattachements', () => {
    const lu = lireCarteCorse(FLUX, { jour: '2026-09-29' });
    assert.equal(accesPourEtape(lu, { massifIncendie: '2024' }).niveau, 2);
    assert.equal(accesPourEtape(lu, { zoneIncendie: '201' }).niveau, 1);
    assert.equal(accesPourEtape(lu, {}), null);
    assert.equal(accesPourEtape(lu, { massifIncendie: '9999' }), null);
  });

  it('se declare CONTRAIGNANTE, licence NON ETABLIE, echelle NON ETABLIE', () => {
    // Les trois voyagent avec la donnee. La licence n est pas etablie (#I8) et
    // l echelle numerique n est documentee nulle part : mettre une table de
    // libelles ici serait une supposition presentee comme un fait, sur une donnee
    // qui porte une INTERDICTION.
    const lu = lireCarteCorse(FLUX, { jour: '2026-09-29' });
    const a = accesPourEtape(lu, { zoneIncendie: '203' });
    assert.equal(a.portee, PORTEE_CORSE);
    assert.equal(a.portee, 'contraignante');
    assert.equal(a.licence, LICENCE_CORSE);
    assert.match(a.licence, /NON ETABLIE/);
    assert.equal(a.echelleEtablie, ECHELLE_ETABLIE);
    assert.equal(a.echelleEtablie, false);
    assert.equal(a.libelle, null);
  });

  it('nomme le fichier du jour qu il DECRIT', () => {
    // Mesure : `20260929.json` est pose le 28/09 a 15:45 UTC. Le nom porte le jour
    // decrit, pas le jour de pose.
    assert.equal(nomDeFichierPour('2026-09-29'), '20260929.json');
    assert.equal(nomDeFichierPour('2026-01-05'), '20260105.json');
  });

  it('refuse une charpente ou un niveau inattendus', () => {
    assert.equal(lireCarteCorse(null, { jour: 'x' }).raison, REFUS_CORSE.charpente);
    assert.equal(lireCarteCorse({ massifs: 3 }, { jour: 'x' }).raison, REFUS_CORSE.charpente);
    assert.equal(lireCarteCorse({ massifs: { 1: 'x' } }, { jour: 'x' }).raison, REFUS_CORSE.charpente);
    assert.equal(lireCarteCorse({ zm: { 1: 9 } }, { jour: 'x' }).raison, REFUS_CORSE.niveauHorsDomaine);
    assert.equal(lireCarteCorse({ massifs: {}, zm: {} }, { jour: 'x' }).raison, REFUS_CORSE.vide);
  });
});
