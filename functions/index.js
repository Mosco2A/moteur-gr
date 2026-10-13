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
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

import { buildSegmentRanking, buildDefiRanking } from './ranking.js';
import { planModeration } from './moderation.js';
import { lireConfiguration, ConfigurationRefusee } from './collecteur/config.js';
import { Depot } from './collecteur/depot_firestore.js';
import { collecterLaMeteo, collecterLeRisqueIncendie, surveiller } from './collecteur/collecte.js';
import { sectionDeBattement, resumeDeFamille, ISSUE } from './collecteur/battement.js';
import { ouvrirPassage } from './collecteur/horodatage.js';

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

// ============================================================================
// LE COLLECTEUR SERVEUR (tache 624, conception 611)
// ============================================================================
//
// DECISION DE CHRISTOPHE DU 28/09, verbatim : « il y a un gros chantier qui est
// mise a jour des donnees sentiers, meteo, incendie. Je ne veux pas que se soit
// l appli qui fasse ca mais notre serveur qui mette a jour les donnees. »
//
// Ces trois planifications sont les PREMIERES `onSchedule` du depot. Elles
// occupent exactement l'allocation gratuite de Cloud Scheduler : trois taches par
// mois et par COMPTE DE FACTURATION (#S13) — pas par projet. Si un autre projet de
// Christophe en consomme deja, celles-ci sont facturees 0,10 $ par tache et par
// 31 jours : ce n'est pas un probleme, mais c'est une surprise, donc c'est dit.
//
// LE COLLECTEUR N'EST PAS DEPLOYE PAR CE LOT. Voir functions/collecteur/README
// pour la marche a suivre le jour ou Christophe le decide.
//
// Region europe-west1 : meme region que Firestore et le stockage. Une fonction
// dans une autre region paierait un aller-retour transatlantique a chaque
// ecriture, et les donnees d'un service europeen n'ont rien a faire ailleurs.
const REGION = 'europe-west1';

/// Ce que fait TOUT passage, meme quand sa configuration est refusee.
///
/// #H2 : le battement est ecrit a CHAQUE execution, succes ou echec. Un refus de
/// configuration qui ne battrait pas serait indiscernable d'un collecteur mort —
/// et c'est justement la panne que le battement existe pour rendre visible.
async function executerUnPassage(tache, action) {
  const depotSansConfig = new Depot(db);
  let configuration;
  try {
    configuration = lireConfiguration(process.env);
  } catch (e) {
    if (!(e instanceof ConfigurationRefusee)) throw e;
    logger.error(`collecteur/${tache}: configuration refusee`, { message: e.message, variable: e.variable });
    await depotSansConfig.battre(tache, sectionDeBattement({
      tache,
      passage: ouvrirPassage({ nom: tache }),
      familles: {
        configuration: resumeDeFamille({ issue: ISSUE.echec, detail: e.message }),
      },
      erreur: e.message,
    }));
    return;
  }

  const depot = new Depot(db, { aBlanc: configuration.aBlanc });
  try {
    const bilan = await action({ depot, configuration });
    logger.info(`collecteur/${tache}: passage termine`, {
      instant: bilan.passage?.instant,
      compte: bilan.compte ?? null,
      alertes: bilan.alertes?.length ?? null,
      ecrituresFaites: depot.ecrituresFaites,
      octetsEcrits: depot.octetsEcrits,
      aBlanc: configuration.aBlanc,
    });
  } catch (e) {
    // Un echec inattendu N'EFFACE RIEN et NE BOUCLE PAS : il bat, il journalise,
    // et le passage suivant reprendra. La donnee de la veille reste en place.
    logger.error(`collecteur/${tache}: echec du passage`, { message: e?.message ?? String(e) });
    await depot.battre(tache, sectionDeBattement({
      tache,
      passage: ouvrirPassage({ nom: tache }),
      familles: { passage: resumeDeFamille({ issue: ISSUE.echec, detail: e?.message ?? String(e) }) },
      erreur: e?.message ?? String(e),
    }));
  }
}

/// METEO — toutes les quatre heures (#W5).
///
/// Quatre heures, et la raison est double : c'est la cadence que Christophe a
/// fixee au telephone (« ensuite toutes les 4 heures par exemple »), donc
/// collecter plus souvent ne servirait personne ; et MET Norway annonce lui-meme
/// sa peremption (`Expires` mesure a +31 min), donc quatre heures reste tres
/// au-dessus de ce qu'il tolere. HORS SAISON, LA CADENCE EST LA MEME : le cout est
/// nul et une meteo absente coute plus cher qu'une collecte inutile.
export const collecteMeteo = onSchedule(
  { schedule: '0 */4 * * *', timeZone: 'Etc/UTC', region: REGION, timeoutSeconds: 300, memory: '256MiB' },
  async () => { await executerUnPassage('meteo', collecterLaMeteo); },
);

/// RISQUE INCENDIE — trois passages par jour (#I13, #I14).
///
/// 16:00 UTC : la Meteo des forets est posee a 14:50 UTC avec une regularite
///             d'horloge (mesure : 124 jours sur 124), la carte corse vers 15:45.
///             Un passage a 16:00 les prend toutes les deux le jour meme.
/// 19:00 UTC : le rattrapage d'un retard de publication — le mode de panne le plus
///             probable d'une source qui ne rate jamais un jour.
/// 06:00 UTC : celui-ci ne sert qu'a une chose, et c'est une correction que
///             j'apporte a #I14. La conception voulait qu'il RETIRE un bulletin
///             perime ; il n'a rien a retirer, parce que l'etat (connu / perime /
///             hors saison / inconnu) est DERIVE par le lecteur et non stocke
///             (voir documents.js, `etatDerive`). Son role reel est donc double :
///             prendre le bulletin du jour si le fichier de la veille l'annonce,
///             et permettre au surveillant d'alerter a 08:00 s'il manque (#H7).
export const collecteRisqueIncendie = onSchedule(
  { schedule: '0 6,16,19 * * *', timeZone: 'Etc/UTC', region: REGION, timeoutSeconds: 300, memory: '256MiB' },
  async () => { await executerUnPassage('incendie', collecterLeRisqueIncendie); },
);

/// LE SURVEILLANT — et il DOIT etre une autre tache (#H5).
///
/// Un collecteur mort ne peut pas signaler sa propre mort. C'est toute la raison
/// d'etre de cette troisieme planification : elle lit le battement des deux autres
/// et crie quand l'un d'eux s'est tu. Sans elle, l'arret du collecteur serait
/// silencieux — la donnee cesserait simplement de bouger, et rien ne distinguerait
/// « le monde n'a pas change » de « nous avons arrete de regarder » (#H1).
export const surveillantDuCollecteur = onSchedule(
  { schedule: '20 */3 * * *', timeZone: 'Etc/UTC', region: REGION, timeoutSeconds: 120, memory: '256MiB' },
  async () => { await executerUnPassage('surveillant', surveiller); },
);
