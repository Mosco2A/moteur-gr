// Tests de la logique PURE de classement (F7A-03) — k-anonymat, pseudonymat.
//
// Execution : cd functions && node --test
//
// Couvre (R1) :
//   - une tranche < K_MIN (5) participants n'est PAS publiee (entries vide) ;
//   - une tranche >= K_MIN est publiee, triee, par tranche ;
//   - AUCUN timestamp fin individuel dans la sortie ;
//   - libelles PSEUDONYMES, JAMAIS le mot "anonyme" ;
//   - meilleur effort par participant (k compte des PERSONNES distinctes).
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  K_MIN,
  buildSegmentRanking,
  buildDefiRanking,
  pseudonymLabel,
} from '../ranking.js';

function efforts(n, { tranche, base = 100, completedAt = true } = {}) {
  return Array.from({ length: n }, (_, i) => ({
    authorUidHash: `hash${String(i).padStart(4, '0')}abcdef`,
    durationSeconds: base + i,
    completedAt: completedAt ? `2026-06-14T10:0${i}:00Z` : undefined,
    ...(tranche ? { tranche } : {}),
  }));
}

describe('pseudonymLabel — pseudonyme, jamais anonyme', () => {
  it('derive un pseudonyme du hash, sans le mot anonyme', () => {
    const label = pseudonymLabel('deadbeefcafe1234');
    assert.equal(label, 'rndr-deadbeef');
    assert.ok(!label.toLowerCase().includes('anonyme'));
  });

  it('hash vide -> libelle de repli neutre', () => {
    assert.equal(pseudonymLabel(''), 'rndr-0000');
  });
});

describe('buildSegmentRanking — k-anonymat', () => {
  it('K_MIN vaut 5', () => {
    assert.equal(K_MIN, 5);
  });

  it('tranche < 5 participants : NON publiee (entries vide)', () => {
    const r = buildSegmentRanking('seg-1', efforts(4));
    assert.equal(r.tranches.length, 1);
    const t = r.tranches[0];
    assert.equal(t.published, false);
    assert.equal(t.participantCount, 4);
    assert.deepEqual(t.entries, []);
  });

  it('tranche >= 5 participants : publiee, triee par duree croissante', () => {
    const r = buildSegmentRanking('seg-1', efforts(6, { base: 200 }));
    const t = r.tranches[0];
    assert.equal(t.published, true);
    assert.equal(t.participantCount, 6);
    assert.equal(t.entries.length, 6);
    // Trie : rank 1 = duree mini.
    assert.equal(t.entries[0].rank, 1);
    assert.equal(t.entries[0].durationSeconds, 200);
    assert.equal(t.entries[5].durationSeconds, 205);
  });

  it('AUCUN timestamp fin individuel dans la sortie publiee (R1)', () => {
    const r = buildSegmentRanking('seg-1', efforts(6));
    const json = JSON.stringify(r);
    assert.ok(!json.includes('completedAt'));
    assert.ok(!json.includes('2026-06-14T10'));
    for (const entry of r.tranches[0].entries) {
      assert.deepEqual(
        Object.keys(entry).sort(),
        ['durationSeconds', 'pseudonym', 'rank'],
      );
    }
  });

  it('aucune entree ne contient le mot "anonyme" (R1)', () => {
    const r = buildSegmentRanking('seg-1', efforts(6));
    assert.ok(!JSON.stringify(r).toLowerCase().includes('anonyme'));
  });

  it('plusieurs tranches : chacune evaluee independamment', () => {
    const mix = [
      ...efforts(6, { tranche: 'sportif', base: 300 }),
      ...efforts(3, { tranche: 'decouverte', base: 400 }),
    ];
    const r = buildSegmentRanking('seg-2', mix);
    const byTranche = Object.fromEntries(r.tranches.map((t) => [t.tranche, t]));
    assert.equal(byTranche.sportif.published, true);
    assert.equal(byTranche.decouverte.published, false);
  });

  it('k compte des PERSONNES distinctes (meilleur effort par auteur)', () => {
    // 4 auteurs, l un avec 3 efforts -> 4 participants < 5 -> non publie.
    const repeated = [
      { authorUidHash: 'aaaa1111zzzz', durationSeconds: 100 },
      { authorUidHash: 'aaaa1111zzzz', durationSeconds: 90 },
      { authorUidHash: 'aaaa1111zzzz', durationSeconds: 95 },
      { authorUidHash: 'bbbb2222zzzz', durationSeconds: 110 },
      { authorUidHash: 'cccc3333zzzz', durationSeconds: 120 },
      { authorUidHash: 'dddd4444zzzz', durationSeconds: 130 },
    ];
    const r = buildSegmentRanking('seg-3', repeated);
    assert.equal(r.tranches[0].participantCount, 4);
    assert.equal(r.tranches[0].published, false);
  });
});

describe('buildDefiRanking — meme garanties', () => {
  it('tranche < 5 non publiee ; >= 5 publiee, triee par value decroissante', () => {
    const parts = Array.from({ length: 5 }, (_, i) => ({
      authorUidHash: `pid${i}xxxxxxxx`,
      value: 10 + i,
    }));
    const r = buildDefiRanking('defi-1', parts);
    const t = r.tranches[0];
    assert.equal(t.published, true);
    // value decroissante : rank 1 = value max (14).
    assert.equal(t.entries[0].value, 14);
    assert.ok(!JSON.stringify(r).toLowerCase().includes('anonyme'));
  });
});
