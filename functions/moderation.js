// Logique PURE du workflow de moderation hebergeur DSA — StepWays (D4C-02,
// design D4 CORDO #86166).
//
// REGLES (audit A4 #86124, validees Themis #86142) :
//   - art 16 : la notification (reports_moderation) porte motif, reference du
//     contenu, contact du notifiant, bonne foi ; elle est traitee A POSTERIORI
//     par un moderateur (statut hebergeur, pas editeur).
//   - art 17 : quand le moderateur STATUE (status -> 'traitee' avec une
//     decision keep/restrict/remove), on (1) fait transiter le moderationState
//     du contenu cible et (2) cree un ENREGISTREMENT D'EXPOSE DES MOTIFS
//     destine a l'auteur du contenu restreint.
//
// Ce fichier ne depend PAS de firebase-admin (testable en isolation via
// `node --test`). index.js l'appelle avec les donnees lues depuis Firestore.

/// Collections de contenu modere autorisees (coherent avec firestore.rules et
/// le modele Phase 8 : champ texte moderationState 'visible'/'flagged'/'removed').
export const MODERATED_COLLECTIONS = [
  'trail_reports',
  'activities',
  'waypoints',
  'waypoint_comments',
];

/// Etat de moderation resultant d'une decision (moderation A POSTERIORI).
///   keep -> visible, restrict -> flagged, remove -> removed.
export function resultingState(decision) {
  switch (decision) {
    case 'keep':
      return 'visible';
    case 'restrict':
      return 'flagged';
    case 'remove':
      return 'removed';
    default:
      return null; // decision inconnue -> aucune transition (no-op defensif)
  }
}

/// Vrai si une transition de notification doit declencher le workflow.
///
/// On agit UNIQUEMENT quand la notification VIENT d'etre traitee (passage a
/// 'traitee' avec une decision exploitable), pas a chaque ecriture. `before`
/// peut etre indefini (creation) : dans ce cas on ne declenche que si le doc
/// nait deja traite (cas rare mais gere). Evite les boucles et les doublons
/// d'expose des motifs.
export function shouldProcess(before, after) {
  if (!after) return false; // suppression -> rien
  if (after.status !== 'traitee') return false; // pas encore tranchee
  if (resultingState(after.decision) === null) return false; // decision absente/inconnue
  // Idempotence : ne traite QUE la transition vers 'traitee'.
  if (before && before.status === 'traitee') return false;
  return true;
}

/// Construit l'enregistrement d'EXPOSE DES MOTIFS (art 17) a destination de
/// l'auteur du contenu restreint. `authorUidHash` est l'UID HACHE de l'auteur
/// du contenu cible (resolu cote index.js en relisant le doc du contenu) :
/// aucune PII directe. Le document est destine a la collection
/// moderation_decisions (lecture par l'auteur, cf. firestore.rules D4C-02).
///
/// Entree : la notification traitee (report) + l'UID hache de l'auteur du
/// contenu. Sortie : la forme du doc moderation_decisions.
export function buildStatementOfReasons(report, authorUidHash, now) {
  return {
    authorUidHash: authorUidHash ?? null,
    contentType: report.contentType,
    contentRef: report.contentRef,
    decision: report.decision,
    resultingState: resultingState(report.decision),
    // L'expose reprend le motif de la notification (art 17 : raison de la
    // restriction communiquee a l'auteur).
    motif: report.motif ?? '',
    reportId: report.reportId ?? null,
    createdAt: now ?? null,
  };
}

/// Plan d'action complet du workflow pour une notification traitee.
///
/// Sortie (consommee par index.js qui execute les ecritures Firestore) :
///   {
///     process: bool,                 // faut-il agir ?
///     contentCollection,             // collection du contenu cible
///     contentRef,                    // doc id du contenu cible
///     newModerationState,            // 'visible'|'flagged'|'removed'
///     statement: { ... } | null      // doc expose des motifs (art 17)
///   }
///
/// `authorUidHash` est lu par index.js sur le contenu cible AVANT d'appeler
/// ce planificateur (le planificateur reste pur). Si la collection cible n'est
/// pas une collection moderee connue, le plan est inerte (defense en
/// profondeur, jamais d'ecriture hors perimetre).
export function planModeration(before, after, { authorUidHash, now } = {}) {
  if (!shouldProcess(before, after)) {
    return { process: false };
  }
  if (!MODERATED_COLLECTIONS.includes(after.contentType)) {
    return { process: false };
  }
  return {
    process: true,
    contentCollection: after.contentType,
    contentRef: after.contentRef,
    newModerationState: resultingState(after.decision),
    statement: buildStatementOfReasons(after, authorUidHash, now),
  };
}
