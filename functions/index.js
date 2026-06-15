// Cloud Functions StepWays — calcul SERVEUR des classements (Phase 7 F7A-03).
//
// Deploiement :
//   cd functions && npm install
//   firebase deploy --only functions:classementSegment,functions:classementDefi
//
// Modele (R2) : le client ecrit un effort dans segment_efforts (cf.
// firestore.rules). Au declenchement, classementSegment RELIT tous les efforts
// du segment et RECALCULE le doc segment_rankings/{segmentId} via la logique
// PURE buildSegmentRanking (k-anonymat k>=5, libelles pseudonymes, sans
// timestamp fin — R1). Le client ne fabrique JAMAIS le classement.
//
// Rollback : retirer/redeployer la version anterieure de la function, ou
// supprimer la function (les rules continuent de proteger les collections).

import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';

import { buildSegmentRanking, buildDefiRanking } from './ranking.js';
import { planModeration } from './moderation.js';

initializeApp();
const db = getFirestore();

/// Recalcule le classement d'un segment a chaque ecriture d'un effort.
export const classementSegment = onDocumentWritten(
  'segment_efforts/{effortId}',
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    const segmentId = after?.segmentId ?? before?.segmentId;
    if (!segmentId) return;

    // Relit TOUS les efforts du segment (source de verite serveur, R2).
    const snap = await db
      .collection('segment_efforts')
      .where('segmentId', '==', segmentId)
      .get();

    const efforts = snap.docs.map((d) => {
      const data = d.data();
      return {
        authorUidHash: data.authorUidHash,
        durationSeconds: data.durationSeconds,
        tranche: data.tranche, // optionnel — tranche large declaree a la remontee
      };
    });

    const ranking = buildSegmentRanking(segmentId, efforts);
    // Le doc agrege publie ne contient PAS de timestamp fin par individu (R1).
    await db.collection('segment_rankings').doc(segmentId).set(ranking);
  },
);

/// Recalcule le classement d'un defi a chaque ecriture d'une participation.
export const classementDefi = onDocumentWritten(
  'defi_participations/{participationId}',
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    const defiId = after?.defiId ?? before?.defiId;
    if (!defiId) return;

    const snap = await db
      .collection('defi_participations')
      .where('defiId', '==', defiId)
      .get();

    const participations = snap.docs.map((d) => {
      const data = d.data();
      return {
        authorUidHash: data.authorUidHash,
        value: data.value,
        tranche: data.tranche,
      };
    });

    const ranking = buildDefiRanking(defiId, participations, {
      ascending: false,
    });
    await db.collection('defi_rankings').doc(defiId).set(ranking);
  },
);

/// Workflow de moderation hebergeur DSA (D4C-02, design #86166).
///
/// Declenche a chaque ecriture d'une notification reports_moderation. Quand un
/// moderateur STATUE (status -> 'traitee' avec une decision), la function :
///   1. relit l'auteur (authorUidHash) du contenu cible (pour l'art 17) ;
///   2. fait transiter le moderationState du contenu cible (A POSTERIORI :
///      keep->visible / restrict->flagged / remove->removed) ;
///   3. cree un enregistrement d'EXPOSE DES MOTIFS (art 17) dans
///      moderation_decisions, destine a l'auteur du contenu restreint.
/// La logique de decision est PURE (moderation.js, testee via node --test) ;
/// cette function ne fait que l'I/O Firestore (Admin SDK = bypass des rules).
///
/// Rollback : retirer/redeployer la version anterieure ; les rules continuent
/// de proteger reports_moderation / moderation_decisions independamment.
export const moderationWorkflow = onDocumentWritten(
  'reports_moderation/{reportId}',
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!after) return; // suppression -> rien a faire

    // Reference du rapport (pour tracer l'expose des motifs).
    const reportId = event.params?.reportId;
    const afterWithId = { ...after, reportId };

    // Pre-calcul defensif : pas de transition -> on ne lit meme pas le contenu.
    const preview = planModeration(before, afterWithId, {});
    if (!preview.process) return;

    // Relit l'auteur du contenu cible (UID hache) pour l'expose des motifs.
    let authorUidHash = null;
    const targetSnap = await db
      .collection(preview.contentCollection)
      .doc(preview.contentRef)
      .get();
    if (targetSnap.exists) {
      authorUidHash = targetSnap.data().authorUidHash ?? null;
    }

    const plan = planModeration(before, afterWithId, {
      authorUidHash,
      now: new Date(),
    });
    if (!plan.process) return;

    // 1. Transition du moderationState du contenu cible (a posteriori).
    await db
      .collection(plan.contentCollection)
      .doc(plan.contentRef)
      .set({ moderationState: plan.newModerationState }, { merge: true });

    // 2. Expose des motifs (art 17) destine a l'auteur du contenu restreint.
    await db.collection('moderation_decisions').add(plan.statement);
  },
);
