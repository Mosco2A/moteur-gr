// L'AUTORITE DE TEMPS DU COLLECTEUR — tache 624.
//
// Execution : cd functions && node --test
//
// LE TEST QUI COMPTE EST LE DERNIER : il parcourt les sources du collecteur et
// REFUSE toute lecture d'horloge en dehors de horodatage.js. C'est le pendant, en
// JavaScript, du constructeur prive de HorodatageServeur cote Dart et de la garde
// structurelle de horloge_du_telephone_610_test.dart. Sans lui, la discipline ne
// serait qu'un commentaire, et un commentaire ne refuse rien.

import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { readdirSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  INSTANT_ORIGINE,
  InstantIllisible,
  ecartEnJours,
  enInstant,
  enMillisecondes,
  jourDecale,
  jourLocal,
  passageFixePourTest,
  plusAncien,
} from '../collecteur/horodatage.js';

const ICI = dirname(fileURLToPath(import.meta.url));
const DOSSIER_COLLECTEUR = join(ICI, '..', 'collecteur');

describe('le format des instants', () => {
  it('rend toujours ISO 8601 UTC avec millisecondes, longueur fixe', () => {
    assert.equal(enInstant(0), INSTANT_ORIGINE);
    assert.equal(enInstant(Date.parse('2026-09-28T09:32:00Z') + 123), '2026-09-28T09:32:00.123Z');
    assert.equal(enInstant(1790000000123), '2026-09-21T14:13:20.123Z');
    assert.equal(enInstant(1790000000123).length, 24);
    // Une milliseconde a zero reste ECRITE : c'est ce qui donne la longueur fixe,
    // donc la comparaison lexicographique.
    assert.equal(enInstant(Date.parse('2026-09-28T09:32:00Z')), '2026-09-28T09:32:00.000Z');
  });

  it('la comparaison LEXICOGRAPHIQUE est la comparaison chronologique', () => {
    // C'est la propriete qu'on exploite : elle permet de comparer des instants
    // sans les reparser, et elle tient parce que le format est zero-padde.
    const a = enInstant(1790000000000);
    const b = enInstant(1790000000001);
    assert.ok(a < b);
    assert.ok(enInstant(1000) < enInstant(999999999999));
  });

  it('refuse une chaine SANS FUSEAU plutot que de la deviner', () => {
    // #H3 : « une ecriture sans fuseau est lue en UTC, jamais en heure locale ».
    // Deviner serait pire que refuser : une lecture decalee est silencieuse.
    assert.throws(() => enMillisecondes('2026-09-28T09:32:00'), InstantIllisible);
    assert.throws(() => enMillisecondes('2026-09-28'), InstantIllisible);
    assert.throws(() => enMillisecondes(''), InstantIllisible);
    assert.throws(() => enMillisecondes(null), InstantIllisible);
  });

  it('relit ce qu il ecrit, et accepte un decalage explicite', () => {
    assert.equal(enMillisecondes('2026-09-28T09:32:00.000Z'), Date.parse('2026-09-28T09:32:00.000Z'));
    assert.equal(enMillisecondes('2026-09-28T11:32:00.000+02:00'), Date.parse('2026-09-28T09:32:00.000Z'));
  });
});

describe('la monotonie — le defaut qui ne se voit pas', () => {
  it('une horloge qui RECULE ne fait pas reculer l instant, et ca se DIT', () => {
    // #R16 : une publication portant un instant anterieur ou egal a la precedente
    // est INVISIBLE pour tous les telephones deja a jour, definitivement et sans
    // trace. On avance d une milliseconde, et on leve le drapeau.
    const borne = '2026-09-28T10:00:00.000Z';
    const p = passageFixePourTest(Date.parse('2026-09-28T09:00:00.000Z'), { borneAnterieure: borne });
    assert.equal(p.instant, '2026-09-28T10:00:00.001Z');
    assert.equal(p.horlogeCorrigee, true);
    assert.equal(p.horlogeBrute, '2026-09-28T09:00:00.000Z');
  });

  it('une horloge EGALE avance quand meme d une milliseconde', () => {
    // L egalite est le piege : la comparaison etant STRICTE, deux instants egaux
    // sont indiscernables et le second serait rate pour toujours (#R15).
    const borne = '2026-09-28T10:00:00.000Z';
    const p = passageFixePourTest(Date.parse(borne), { borneAnterieure: borne });
    assert.equal(p.instant, '2026-09-28T10:00:00.001Z');
    assert.equal(p.horlogeCorrigee, true);
  });

  it('une horloge en avance passe telle quelle, sans drapeau', () => {
    const p = passageFixePourTest(Date.parse('2026-09-28T11:00:00.000Z'), {
      borneAnterieure: '2026-09-28T10:00:00.000Z',
    });
    assert.equal(p.instant, '2026-09-28T11:00:00.000Z');
    assert.equal(p.horlogeCorrigee, false);
  });

  it('un passage est GELE : personne ne peut retoucher son instant apres coup', () => {
    const p = passageFixePourTest(1790000000000);
    assert.throws(() => { p.instant = 'autre chose'; }, TypeError);
  });
});

describe('plusAncien — la borne racine est un MINIMUM (#K10)', () => {
  it('rend le plus ancien, et traite null comme absence de contrainte', () => {
    assert.equal(plusAncien('2026-09-28T10:00:00.000Z', '2026-09-28T09:00:00.000Z'), '2026-09-28T09:00:00.000Z');
    assert.equal(plusAncien(null, '2026-09-28T09:00:00.000Z'), '2026-09-28T09:00:00.000Z');
    assert.equal(plusAncien('2026-09-28T09:00:00.000Z', null), '2026-09-28T09:00:00.000Z');
    assert.equal(plusAncien(null, null), null);
  });
});

describe('les journees locales', () => {
  it('decoupe les journees en HEURE LOCALE, pas en UTC', () => {
    // 22:30 UTC le 28 septembre = 00:30 le 29 a Paris (UTC+2 en ete). Un decoupage
    // UTC rangerait cette prevision dans la veille, et l erreur ne se verrait que
    // sur deux heures par jour — donc jamais, jusqu au jour ou elle compte.
    const ms = Date.parse('2026-09-28T22:30:00Z');
    assert.equal(jourLocal(ms, 'Europe/Paris'), '2026-09-29');
    assert.equal(jourLocal(ms, 'Etc/UTC'), '2026-09-28');
  });

  it('l arithmetique des jours survit au changement d heure', () => {
    // Le dernier dimanche d octobre 2026 : la France repasse en UTC+1. Une
    // arithmetique a minuit + 24 h tomberait a cote, et seulement ce jour-la.
    assert.equal(jourDecale('2026-10-24', 1), '2026-10-25');
    assert.equal(jourDecale('2026-10-25', 1), '2026-10-26');
    assert.equal(jourDecale('2026-03-28', 1), '2026-03-29');
    assert.equal(jourDecale('2026-01-01', -1), '2025-12-31');
    assert.equal(jourDecale('2026-02-28', 1), '2026-03-01');
    assert.equal(ecartEnJours('2026-09-27', '2026-09-29'), 2);
    assert.equal(ecartEnJours('2026-10-24', '2026-10-27'), 3);
  });

  it('refuse un jour mal forme', () => {
    assert.throws(() => jourDecale('28/09/2026', 1), InstantIllisible);
    assert.throws(() => ecartEnJours('2026-9-1', '2026-09-02'), InstantIllisible);
  });
});

describe('LA GARDE : une seule horloge dans tout le collecteur', () => {
  it('aucun module du collecteur sauf horodatage.js ne lit l horloge', () => {
    // Cette garde est la RAISON pour laquelle la discipline tient. Cote Dart, le
    // constructeur prive de HorodatageServeur transforme la faute en erreur de
    // compilation ; JavaScript n'offre pas cela, donc c'est ce test qui refuse.
    //
    // Ce qui est interdit : `Date.now()` et `new Date()` SANS ARGUMENT — les deux
    // seules facons de lire l heure courante. `new Date(ms)` est une conversion
    // deterministe, pas une lecture d horloge : elle reste permise.
    const fautes = [];
    for (const fichier of readdirSync(DOSSIER_COLLECTEUR).filter((f) => f.endsWith('.js'))) {
      if (fichier === 'horodatage.js') continue;
      const source = readFileSync(join(DOSSIER_COLLECTEUR, fichier), 'utf8');
      const lignes = source.split(/\r?\n/);
      lignes.forEach((ligne, i) => {
        const nue = ligne.replace(/\/\/.*$/, '');
        if (/\bDate\.now\s*\(/.test(nue)) fautes.push(`${fichier}:${i + 1} Date.now()`);
        if (/\bnew\s+Date\s*\(\s*\)/.test(nue)) fautes.push(`${fichier}:${i + 1} new Date()`);
      });
    }
    assert.deepEqual(fautes, [], `lecture d horloge hors horodatage.js:\n${fautes.join('\n')}`);
  });

  it('horodatage.js contient EXACTEMENT une lecture d horloge', () => {
    // Une seule porte. Deux portes, c'est deja deux disciplines.
    const source = readFileSync(join(DOSSIER_COLLECTEUR, 'horodatage.js'), 'utf8');
    const sansCommentaires = source.split(/\r?\n/)
      .map((l) => l.replace(/\/\/.*$/, ''))
      .join('\n');
    const occurrences = sansCommentaires.match(/\bDate\.now\s*\(/g) ?? [];
    assert.equal(occurrences.length, 1);
    assert.equal((sansCommentaires.match(/\bnew\s+Date\s*\(\s*\)/g) ?? []).length, 0);
  });

  it('passageFixePourTest n est appele par AUCUN module du collecteur', () => {
    // Elle existe pour les tests. S'il existait un chemin de production vers elle,
    // l instant du passage deviendrait un parametre, donc une decision, donc une
    // faute possible.
    const fautes = [];
    for (const fichier of readdirSync(DOSSIER_COLLECTEUR).filter((f) => f.endsWith('.js'))) {
      if (fichier === 'horodatage.js') continue;
      const source = readFileSync(join(DOSSIER_COLLECTEUR, fichier), 'utf8');
      if (source.includes('passageFixePourTest')) fautes.push(fichier);
    }
    assert.deepEqual(fautes, []);
  });
});
