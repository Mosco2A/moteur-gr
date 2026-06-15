// Tests de la logique PURE du workflow de moderation (D4C-02) — DSA art 16/17.
//
// Execution : cd functions && node --test
//
// Couvre :
//   - resultingState : keep->visible, restrict->flagged, remove->removed,
//     decision inconnue -> null (no-op defensif) ;
//   - shouldProcess : ne declenche QUE sur la transition vers 'traitee' avec
//     une decision exploitable (idempotence, pas de boucle, pas de doublon) ;
//   - buildStatementOfReasons : expose des motifs (art 17) bien forme,
//     destine a l'auteur (authorUidHash), reprend motif + decision ;
//   - planModeration : plan complet (transition moderationState + expose),
//     inerte hors collection moderee connue (defense en profondeur).
import assert from 'node:assert/strict';
import { describe, it } from 'node:test';

import {
  MODERATED_COLLECTIONS,
  resultingState,
  shouldProcess,
  buildStatementOfReasons,
  planModeration,
} from '../moderation.js';

const treatedReport = (overrides = {}) => ({
  contentType: 'waypoints',
  contentRef: 'wp-1',
  motif: 'Contenu illicite',
  notifierContact: 'temoin@example.com',
  bonneFoi: true,
  createdAt: 'ts',
  status: 'traitee',
  decision: 'remove',
  ...overrides,
});

describe('resultingState — transition a posteriori (art 16)', () => {
  it('keep -> visible', () => assert.equal(resultingState('keep'), 'visible'));
  it('restrict -> flagged', () =>
    assert.equal(resultingState('restrict'), 'flagged'));
  it('remove -> removed', () =>
    assert.equal(resultingState('remove'), 'removed'));
  it('decision inconnue -> null (no-op)', () => {
    assert.equal(resultingState('zombie'), null);
    assert.equal(resultingState(undefined), null);
  });
});

describe('shouldProcess — idempotence sur la transition vers traitee', () => {
  it('declenche quand la notification passe a traitee avec decision', () => {
    const before = { status: 'en_traitement' };
    assert.equal(shouldProcess(before, treatedReport()), true);
  });

  it('declenche aussi si le doc nait deja traite (before indefini)', () => {
    assert.equal(shouldProcess(undefined, treatedReport()), true);
  });

  it('NE declenche PAS si statut pas encore traitee', () => {
    const after = treatedReport({ status: 'recue' });
    assert.equal(shouldProcess({ status: 'recue' }, after), false);
  });

  it('NE declenche PAS si deja traitee avant (anti-doublon/boucle)', () => {
    const before = { status: 'traitee', decision: 'remove' };
    assert.equal(shouldProcess(before, treatedReport()), false);
  });

  it('NE declenche PAS si decision absente/inconnue', () => {
    assert.equal(
      shouldProcess({ status: 'en_traitement' }, treatedReport({ decision: undefined })),
      false,
    );
  });

  it('NE declenche PAS sur suppression (after indefini)', () => {
    assert.equal(shouldProcess({ status: 'recue' }, undefined), false);
  });
});

describe('buildStatementOfReasons — expose des motifs (art 17)', () => {
  it('forme un doc destine a l auteur, reprenant motif + decision', () => {
    const stmt = buildStatementOfReasons(
      treatedReport({ reportId: 'rep-9' }),
      'author-hash-abc',
      'now-ts',
    );
    assert.equal(stmt.authorUidHash, 'author-hash-abc');
    assert.equal(stmt.contentType, 'waypoints');
    assert.equal(stmt.contentRef, 'wp-1');
    assert.equal(stmt.decision, 'remove');
    assert.equal(stmt.resultingState, 'removed');
    assert.equal(stmt.motif, 'Contenu illicite');
    assert.equal(stmt.reportId, 'rep-9');
    assert.equal(stmt.createdAt, 'now-ts');
  });

  it('tolere un auteur inconnu (authorUidHash null)', () => {
    const stmt = buildStatementOfReasons(treatedReport(), null, 'now');
    assert.equal(stmt.authorUidHash, null);
  });
});

describe('planModeration — plan complet du workflow', () => {
  it('produit la transition + l expose pour une notification traitee', () => {
    const plan = planModeration({ status: 'en_traitement' }, treatedReport(), {
      authorUidHash: 'author-x',
      now: 'now',
    });
    assert.equal(plan.process, true);
    assert.equal(plan.contentCollection, 'waypoints');
    assert.equal(plan.contentRef, 'wp-1');
    assert.equal(plan.newModerationState, 'removed');
    assert.equal(plan.statement.authorUidHash, 'author-x');
    assert.equal(plan.statement.resultingState, 'removed');
  });

  it('restrict -> flagged dans le plan', () => {
    const plan = planModeration(
      { status: 'en_traitement' },
      treatedReport({ decision: 'restrict' }),
      {},
    );
    assert.equal(plan.newModerationState, 'flagged');
  });

  it('plan inerte si pas de transition vers traitee', () => {
    const plan = planModeration(
      { status: 'recue' },
      treatedReport({ status: 'recue' }),
      {},
    );
    assert.deepEqual(plan, { process: false });
  });

  it('plan inerte si collection cible inconnue (defense en profondeur)', () => {
    const plan = planModeration(
      { status: 'en_traitement' },
      treatedReport({ contentType: 'collection_pirate' }),
      {},
    );
    assert.deepEqual(plan, { process: false });
  });

  it('toutes les collections moderees connues sont planifiables', () => {
    for (const col of MODERATED_COLLECTIONS) {
      const plan = planModeration(
        { status: 'en_traitement' },
        treatedReport({ contentType: col }),
        { authorUidHash: 'a' },
      );
      assert.equal(plan.process, true, `collection ${col} doit etre planifiable`);
      assert.equal(plan.contentCollection, col);
    }
  });
});
