// Tests des regles de securite Firestore — StepWays (P0-2 audit #327).
//
// Execution OBLIGATOIRE via l emulateur (depuis la racine du repo) :
//   firebase emulators:exec --only firestore --project demo-stepways \
//     "npm --prefix firestore-tests test"
//
// Matrice couverte :
//   trails           : lecture publique OK, ecriture refusee (sauf admin
//                      sous-collections), ecriture document racine refusee.
//   users            : owner only (lecture/ecriture, sous-collections).
//   follow_sessions  : trekker ecrit OK / etranger KO / anonyme KO ;
//                      lecture positions par suiveur anonyme OK si session
//                      valide, KO si expiree, resolution impossible si
//                      shareCode faux ; trekkerUserId jamais expose au
//                      suiveur ; followers owner-only ; payloads bornes.
//   reste            : deny explicite (ex. collection groups).
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';

import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  limit,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const TREKKER = 'trekker-uid-001';
const STRANGER = 'stranger-uid-666';
const SESSION = 'session-test-0001';
const CODE = 'ABC234';

const HOUR_MS = 3600 * 1000;
const in48h = () => Timestamp.fromMillis(Date.now() + 48 * HOUR_MS);
const oneHourAgo = () => Timestamp.fromMillis(Date.now() - HOUR_MS);

/// Payload exact d une session privee telle qu ecrite par FollowService.
function sessionPayload(overrides = {}) {
  return {
    id: SESSION,
    trekkerUserId: TREKKER,
    shareCode: CODE,
    createdAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 48 * HOUR_MS).toISOString(),
    isActive: true,
    expiresAtTs: in48h(),
    ...overrides,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-stepways',
    firestore: {
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

const trekkerDb = () => testEnv.authenticatedContext(TREKKER).firestore();
const strangerDb = () => testEnv.authenticatedContext(STRANGER).firestore();
const adminDb = () =>
  testEnv.authenticatedContext('admin-uid', { admin: true }).firestore();
const moderatorDb = () =>
  testEnv.authenticatedContext('mod-uid', { moderator: true }).firestore();
const anonDb = () => testEnv.unauthenticatedContext().firestore();

/// Seed direct (regles desactivees) d une session + miroir + 1 position.
async function seedSession({ isActive = true, expired = false } = {}) {
  const ts = expired ? oneHourAgo() : in48h();
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(
      doc(db, 'follow_sessions', SESSION),
      sessionPayload({ isActive, expiresAtTs: ts }),
    );
    await setDoc(doc(db, 'follow_sessions_public', SESSION), {
      shareCode: CODE,
      isActive,
      expiresAtTs: ts,
    });
    await setDoc(doc(db, 'follow_sessions', SESSION, 'positions', 'pos-1'), {
      lat: 45.0,
      lng: 6.0,
      timestamp: Timestamp.now(),
    });
  });
}

describe('trails — lecture publique, ecriture verrouillee', () => {
  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'trails', 'sentier-bleu'), { name: 'Sentier Bleu' });
      await setDoc(doc(db, 'trails', 'sentier-bleu', 'stages', 'stage-1'), {
        name: 'Etape 1',
      });
    });
  });

  it('lecture anonyme du document sentier OK', async () => {
    await assertSucceeds(getDoc(doc(anonDb(), 'trails', 'sentier-bleu')));
  });

  it('lecture anonyme d une sous-collection OK', async () => {
    await assertSucceeds(
      getDoc(doc(anonDb(), 'trails', 'sentier-bleu', 'stages', 'stage-1')),
    );
  });

  it('ecriture du document racine refusee meme authentifie', async () => {
    await assertFails(
      setDoc(doc(trekkerDb(), 'trails', 'sentier-pirate'), { name: 'x' }),
    );
  });

  it('ecriture sous-collection refusee pour un utilisateur normal', async () => {
    await assertFails(
      setDoc(doc(trekkerDb(), 'trails', 'sentier-bleu', 'stages', 'stage-2'), {
        name: 'intrusion',
      }),
    );
  });

  it('ecriture sous-collection autorisee avec claim admin', async () => {
    await assertSucceeds(
      setDoc(doc(adminDb(), 'trails', 'sentier-bleu', 'stages', 'stage-2'), {
        name: 'Etape 2',
      }),
    );
  });
});

describe('users — owner only', () => {
  it('le proprietaire lit et ecrit son document', async () => {
    const db = trekkerDb();
    await assertSucceeds(setDoc(doc(db, 'users', TREKKER), { locale: 'fr' }));
    await assertSucceeds(getDoc(doc(db, 'users', TREKKER)));
  });

  it('le proprietaire ecrit dans ses sous-collections', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'users', TREKKER, 'journal', 'entry-1'), {
        note: 'belle etape',
      }),
    );
  });

  it('un autre utilisateur ne lit ni n ecrit', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', TREKKER), { locale: 'fr' });
    });
    await assertFails(getDoc(doc(strangerDb(), 'users', TREKKER)));
    await assertFails(
      setDoc(doc(strangerDb(), 'users', TREKKER), { locale: 'hack' }),
    );
  });

  it('un anonyme ne lit pas', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users', TREKKER), { locale: 'fr' });
    });
    await assertFails(getDoc(doc(anonDb(), 'users', TREKKER)));
  });
});

describe('follow_sessions — creation', () => {
  it('le trekker cree SA session (payload FollowService exact) OK', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
  });

  it('un etranger ne cree pas une session au nom du trekker', async () => {
    await assertFails(
      setDoc(doc(strangerDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
  });

  it('un anonyme ne cree rien', async () => {
    await assertFails(
      setDoc(doc(anonDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
  });

  it('TTL superieur a 48h (+tolerance) refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION),
        sessionPayload({
          expiresAtTs: Timestamp.fromMillis(Date.now() + 72 * HOUR_MS),
        }),
      ),
    );
  });

  it('session deja expiree a la creation refusee', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION),
        sessionPayload({ expiresAtTs: oneHourAgo() }),
      ),
    );
  });

  it('champ hors schema refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION),
        sessionPayload({ champPirate: true }),
      ),
    );
  });

  it('shareCode de mauvaise taille refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION),
        sessionPayload({ shareCode: 'TROPLONG99' }),
      ),
    );
  });
});

describe('follow_sessions — lecture et mise a jour', () => {
  beforeEach(() => seedSession());

  it('le proprietaire lit sa session', async () => {
    await assertSucceeds(getDoc(doc(trekkerDb(), 'follow_sessions', SESSION)));
  });

  it('un etranger ne lit pas la session (trekkerUserId protege)', async () => {
    await assertFails(getDoc(doc(strangerDb(), 'follow_sessions', SESSION)));
  });

  it('un anonyme ne lit pas la session (trekkerUserId protege)', async () => {
    await assertFails(getDoc(doc(anonDb(), 'follow_sessions', SESSION)));
  });

  it('le proprietaire cloture sa session (isActive=false)', async () => {
    await assertSucceeds(
      updateDoc(doc(trekkerDb(), 'follow_sessions', SESSION), {
        isActive: false,
      }),
    );
  });

  it('le proprietaire ne change ni shareCode ni TTL', async () => {
    await assertFails(
      updateDoc(doc(trekkerDb(), 'follow_sessions', SESSION), {
        shareCode: 'ZZZ999',
      }),
    );
    await assertFails(
      updateDoc(doc(trekkerDb(), 'follow_sessions', SESSION), {
        expiresAtTs: Timestamp.fromMillis(Date.now() + 400 * HOUR_MS),
      }),
    );
  });

  it('un etranger ne met pas a jour la session', async () => {
    await assertFails(
      updateDoc(doc(strangerDb(), 'follow_sessions', SESSION), {
        isActive: false,
      }),
    );
  });
});

describe('follow_sessions/positions — ecriture trekker, lecture anonyme bornee', () => {
  it('le trekker publie une position (session valide)', async () => {
    await seedSession();
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION, 'positions', 'p2'), {
        lat: 45.1,
        lng: 6.1,
        timestamp: serverTimestamp(),
      }),
    );
  });

  it('le trekker publie un batch GroupSync (stageId/batchedAt/syncMode)', async () => {
    await seedSession();
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION, 'positions', 'p3'), {
        lat: 45.2,
        lng: 6.2,
        stageId: null,
        timestamp: serverTimestamp(),
        batchedAt: new Date().toISOString(),
        syncMode: 'hourly',
      }),
    );
  });

  it('un etranger authentifie n ecrit pas de position', async () => {
    await seedSession();
    await assertFails(
      setDoc(doc(strangerDb(), 'follow_sessions', SESSION, 'positions', 'p2'), {
        lat: 0,
        lng: 0,
        timestamp: serverTimestamp(),
      }),
    );
  });

  it('un anonyme n ecrit pas de position', async () => {
    await seedSession();
    await assertFails(
      setDoc(doc(anonDb(), 'follow_sessions', SESSION, 'positions', 'p2'), {
        lat: 0,
        lng: 0,
        timestamp: serverTimestamp(),
      }),
    );
  });

  it('le trekker n ecrit plus apres expiration de la session', async () => {
    await seedSession({ expired: true });
    await assertFails(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION, 'positions', 'p2'), {
        lat: 45.1,
        lng: 6.1,
        timestamp: serverTimestamp(),
      }),
    );
  });

  it('suiveur ANONYME : lecture positions OK si session valide', async () => {
    await seedSession();
    await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions', SESSION, 'positions'),
          orderBy('timestamp', 'desc'),
          limit(1),
        ),
      ),
    );
  });

  it('suiveur ANONYME : lecture positions KO si session EXPIREE', async () => {
    await seedSession({ expired: true });
    await assertFails(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions', SESSION, 'positions'),
          orderBy('timestamp', 'desc'),
          limit(1),
        ),
      ),
    );
  });

  it('suiveur ANONYME : lecture positions KO si session INACTIVE', async () => {
    await seedSession({ isActive: false });
    await assertFails(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions', SESSION, 'positions'),
          orderBy('timestamp', 'desc'),
          limit(1),
        ),
      ),
    );
  });

  it('une position publiee est immuable (update/delete refuses)', async () => {
    await seedSession();
    await assertFails(
      updateDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION, 'positions', 'pos-1'),
        { lat: 0 },
      ),
    );
    await assertFails(
      deleteDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION, 'positions', 'pos-1'),
      ),
    );
  });
});

describe('follow_sessions/followers — owner only au strict besoin', () => {
  beforeEach(() => seedSession());

  it('le proprietaire compte (list) et cree un slot borne', async () => {
    const db = trekkerDb();
    await assertSucceeds(
      getDocs(collection(db, 'follow_sessions', SESSION, 'followers')),
    );
    await assertSucceeds(
      setDoc(doc(db, 'follow_sessions', SESSION, 'followers', 'slot-1'), {
        id: 'slot-1',
        sessionId: SESSION,
        followerName: 'Marie',
        isPaid: false,
        adSupported: false,
      }),
    );
  });

  it('slot avec sessionId incoherent refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'follow_sessions', SESSION, 'followers', 'slot-1'),
        {
          id: 'slot-1',
          sessionId: 'autre-session',
          followerName: 'Marie',
          isPaid: false,
          adSupported: false,
        },
      ),
    );
  });

  it('etranger et anonyme ne touchent pas aux followers', async () => {
    await assertFails(
      getDocs(collection(strangerDb(), 'follow_sessions', SESSION, 'followers')),
    );
    await assertFails(
      setDoc(doc(anonDb(), 'follow_sessions', SESSION, 'followers', 'x'), {
        id: 'x',
        sessionId: SESSION,
        followerName: 'pirate',
        isPaid: false,
        adSupported: false,
      }),
    );
  });
});

describe('follow_sessions_public — miroir minimal sans trekkerUserId', () => {
  it('resolution anonyme par shareCode valide OK, et AUCUN trekkerUserId expose', async () => {
    await seedSession();
    const snap = await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions_public'),
          where('shareCode', '==', CODE),
          where('isActive', '==', true),
          limit(1),
        ),
      ),
    );
    assert.equal(snap.docs.length, 1);
    assert.equal(snap.docs[0].id, SESSION);
    const data = snap.docs[0].data();
    assert.ok(!('trekkerUserId' in data), 'trekkerUserId ne doit JAMAIS etre expose');
    assert.deepEqual(
      Object.keys(data).sort(),
      ['expiresAtTs', 'isActive', 'shareCode'],
      'le miroir public ne porte que le champ public minimal',
    );
  });

  it('shareCode faux : resolution impossible (0 resultat)', async () => {
    await seedSession();
    const snap = await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions_public'),
          where('shareCode', '==', 'FAUX42'),
          where('isActive', '==', true),
          limit(1),
        ),
      ),
    );
    assert.equal(snap.docs.length, 0);
  });

  it('session inactive : invisible a la resolution + get direct refuse', async () => {
    await seedSession({ isActive: false });
    const snap = await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions_public'),
          where('shareCode', '==', CODE),
          where('isActive', '==', true),
          limit(1),
        ),
      ),
    );
    assert.equal(snap.docs.length, 0);
    await assertFails(getDoc(doc(anonDb(), 'follow_sessions_public', SESSION)));
  });

  it('le proprietaire cree le miroir minimal de SA session', async () => {
    // La session privee doit exister d abord (flux FollowService reel).
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions_public', SESSION), {
        shareCode: CODE,
        isActive: true,
        expiresAtTs: in48h(),
      }),
    );
  });

  it('un etranger ne cree pas le miroir d une session qui n est pas la sienne', async () => {
    await seedSession();
    await assertFails(
      setDoc(doc(strangerDb(), 'follow_sessions_public', SESSION), {
        shareCode: CODE,
        isActive: true,
        expiresAtTs: in48h(),
      }),
    );
  });

  it('miroir portant trekkerUserId refuse (champ public minimal impose)', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
    await assertFails(
      setDoc(doc(trekkerDb(), 'follow_sessions_public', SESSION), {
        shareCode: CODE,
        isActive: true,
        expiresAtTs: in48h(),
        trekkerUserId: TREKKER,
      }),
    );
  });

  it('miroir avec shareCode incoherent avec la session privee refuse', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'follow_sessions', SESSION), sessionPayload()),
    );
    await assertFails(
      setDoc(doc(trekkerDb(), 'follow_sessions_public', SESSION), {
        shareCode: 'AUTRE1',
        isActive: true,
        expiresAtTs: in48h(),
      }),
    );
  });

  it('le proprietaire cloture le miroir (isActive seulement)', async () => {
    await seedSession();
    await assertSucceeds(
      updateDoc(doc(trekkerDb(), 'follow_sessions_public', SESSION), {
        isActive: false,
      }),
    );
    await assertFails(
      updateDoc(doc(trekkerDb(), 'follow_sessions_public', SESSION), {
        shareCode: 'ZZZ999',
      }),
    );
  });
});

describe('parcours complet suiveur anonyme (sans seed admin)', () => {
  it('creation trekker -> resolution shareCode -> lecture position', async () => {
    const db = trekkerDb();
    await assertSucceeds(
      setDoc(doc(db, 'follow_sessions', SESSION), sessionPayload()),
    );
    await assertSucceeds(
      setDoc(doc(db, 'follow_sessions_public', SESSION), {
        shareCode: CODE,
        isActive: true,
        expiresAtTs: in48h(),
      }),
    );
    await assertSucceeds(
      setDoc(doc(db, 'follow_sessions', SESSION, 'positions', 'p1'), {
        lat: 45.0,
        lng: 6.0,
        timestamp: serverTimestamp(),
      }),
    );

    // Cote suiveur anonyme (flux FollowWebScreen).
    const resolution = await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions_public'),
          where('shareCode', '==', CODE),
          where('isActive', '==', true),
          limit(1),
        ),
      ),
    );
    assert.equal(resolution.docs.length, 1);
    const sessionId = resolution.docs[0].id;
    const positions = await assertSucceeds(
      getDocs(
        query(
          collection(anonDb(), 'follow_sessions', sessionId, 'positions'),
          orderBy('timestamp', 'desc'),
          limit(1),
        ),
      ),
    );
    assert.equal(positions.docs.length, 1);
    assert.equal(positions.docs[0].data().lat, 45.0);
  });
});

describe('trail_reports — signalement offline-first + moderation DSA (F6C-04)', () => {
  const REPORT = 'report-test-0001';

  function reportPayload(overrides = {}) {
    return {
      type: 'obstacle',
      latitude: 45.0,
      longitude: 6.0,
      authorUidHash: 'hash-abc-123',
      createdAt: serverTimestamp(),
      moderationState: 'visible',
      ...overrides,
    };
  }

  /// Seed direct (regles desactivees) d un signalement avec un etat donne.
  async function seedReport({ moderationState = 'visible' } = {}) {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'trail_reports', REPORT), {
        type: 'danger',
        latitude: 45.0,
        longitude: 6.0,
        authorUidHash: 'hash-seed',
        createdAt: Timestamp.now(),
        moderationState,
      });
    });
  }

  it('utilisateur authentifie cree un signalement valide', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'trail_reports', REPORT), reportPayload()),
    );
  });

  it('un anonyme ne cree pas de signalement', async () => {
    await assertFails(
      setDoc(doc(anonDb(), 'trail_reports', REPORT), reportPayload()),
    );
  });

  it('type hors liste refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'trail_reports', REPORT),
        reportPayload({ type: 'blague' }),
      ),
    );
  });

  it('moderationState initial != visible refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'trail_reports', REPORT),
        reportPayload({ moderationState: 'removed' }),
      ),
    );
  });

  it('champ hors schema refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'trail_reports', REPORT),
        reportPayload({ champPirate: true }),
      ),
    );
  });

  it('lecture publique des signalements visible', async () => {
    await seedReport({ moderationState: 'visible' });
    await assertSucceeds(getDoc(doc(anonDb(), 'trail_reports', REPORT)));
  });

  it('signalement removed invisible en lecture', async () => {
    await seedReport({ moderationState: 'removed' });
    await assertFails(getDoc(doc(anonDb(), 'trail_reports', REPORT)));
  });

  it('auteur ne peut PAS re-editer le contenu (immutabilite)', async () => {
    await seedReport();
    await assertFails(
      updateDoc(doc(trekkerDb(), 'trail_reports', REPORT), {
        latitude: 0.0,
      }),
    );
  });

  it('non-moderateur ne change pas moderationState', async () => {
    await seedReport();
    await assertFails(
      updateDoc(doc(trekkerDb(), 'trail_reports', REPORT), {
        moderationState: 'removed',
      }),
    );
  });

  it('moderateur masque un signalement (moderationState=removed)', async () => {
    await seedReport();
    await assertSucceeds(
      updateDoc(doc(moderatorDb(), 'trail_reports', REPORT), {
        moderationState: 'removed',
      }),
    );
  });

  it('moderateur ne peut PAS editer le contenu (seul moderationState)', async () => {
    await seedReport();
    await assertFails(
      updateDoc(doc(moderatorDb(), 'trail_reports', REPORT), {
        moderationState: 'flagged',
        latitude: 0.0,
      }),
    );
  });

  it('moderateur supprime un signalement', async () => {
    await seedReport();
    await assertSucceeds(
      deleteDoc(doc(moderatorDb(), 'trail_reports', REPORT)),
    );
  });

  it('utilisateur normal ne supprime pas un signalement', async () => {
    await seedReport();
    await assertFails(deleteDoc(doc(trekkerDb(), 'trail_reports', REPORT)));
  });
});

describe('segment_efforts — effort immuable + UID auteur (F7A-03)', () => {
  const EFFORT = 'effort-test-0001';

  function effortPayload(overrides = {}) {
    return {
      segmentId: 'seg-1',
      authorUidHash: TREKKER,
      durationSeconds: 600,
      completedAt: serverTimestamp(),
      ...overrides,
    };
  }

  it('auteur authentifie cree son effort (authorUidHash == uid)', async () => {
    await assertSucceeds(
      setDoc(doc(trekkerDb(), 'segment_efforts', EFFORT), effortPayload()),
    );
  });

  it('un anonyme ne cree pas d effort', async () => {
    await assertFails(
      setDoc(doc(anonDb(), 'segment_efforts', EFFORT), effortPayload()),
    );
  });

  it('usurpation d UID refusee (authorUidHash != uid)', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'segment_efforts', EFFORT),
        effortPayload({ authorUidHash: STRANGER }),
      ),
    );
  });

  it('durationSeconds <= 0 refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'segment_efforts', EFFORT),
        effortPayload({ durationSeconds: 0 }),
      ),
    );
  });

  it('champ hors schema refuse', async () => {
    await assertFails(
      setDoc(
        doc(trekkerDb(), 'segment_efforts', EFFORT),
        effortPayload({ champPirate: true }),
      ),
    );
  });

  it('effort immuable : update et delete refuses meme par l auteur', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'segment_efforts', EFFORT), {
        segmentId: 'seg-1',
        authorUidHash: TREKKER,
        durationSeconds: 600,
        completedAt: Timestamp.now(),
      });
    });
    await assertFails(
      updateDoc(doc(trekkerDb(), 'segment_efforts', EFFORT), {
        durationSeconds: 1,
      }),
    );
    await assertFails(
      deleteDoc(doc(trekkerDb(), 'segment_efforts', EFFORT)),
    );
  });

  it('un effort n est PAS lisible par un autre utilisateur (lecture auteur only)', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'segment_efforts', EFFORT), {
        segmentId: 'seg-1',
        authorUidHash: TREKKER,
        durationSeconds: 600,
        completedAt: Timestamp.now(),
      });
    });
    await assertSucceeds(getDoc(doc(trekkerDb(), 'segment_efforts', EFFORT)));
    await assertFails(getDoc(doc(strangerDb(), 'segment_efforts', EFFORT)));
  });
});

describe('segment_rankings — lecture publique, ecriture backend only (F7A-03)', () => {
  const SEG = 'seg-1';

  async function seedRanking() {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'segment_rankings', SEG), {
        segmentId: SEG,
        tranches: [
          { tranche: 'all', participantCount: 6, published: true, entries: [] },
        ],
      });
    });
  }

  it('lecture publique du classement agrege (cache offline)', async () => {
    await seedRanking();
    await assertSucceeds(getDoc(doc(anonDb(), 'segment_rankings', SEG)));
  });

  it('un client normal ne fabrique PAS un classement (R2)', async () => {
    await assertFails(
      setDoc(doc(trekkerDb(), 'segment_rankings', SEG), {
        segmentId: SEG,
        tranches: [],
      }),
    );
  });

  it('le backend (claim admin) ecrit le classement', async () => {
    await assertSucceeds(
      setDoc(doc(adminDb(), 'segment_rankings', SEG), {
        segmentId: SEG,
        tranches: [],
      }),
    );
  });
});

describe('tout le reste — deny', () => {
  it('collection sans regles (groups) refusee meme authentifie', async () => {
    await assertFails(
      setDoc(doc(trekkerDb(), 'groups', 'code-1'), { groupCode: 'code-1' }),
    );
    await assertFails(getDoc(doc(trekkerDb(), 'groups', 'code-1')));
  });

  it('collection inconnue refusee en anonyme', async () => {
    await assertFails(getDoc(doc(anonDb(), 'collection_pirate', 'doc-1')));
  });
});
