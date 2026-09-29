// L'ECRITURE DANS FIRESTORE — la seule couche du collecteur qui touche la base.
//
// ============================================================================
// LE REGISTRE : POURQUOI UN PASSAGE COUTE DEUX LECTURES ET PAS SOIXANTE-DIX
// ============================================================================
// Pour savoir si un bulletin a change, il faut le comparer a ce qui est stocke.
// Relire les 70 documents d'etape a chaque passage couterait 420 lectures par
// jour, POUR NE RIEN APPRENDRE la plupart du temps.
//
// Le registre resout cela : un document par famille qui porte, pour chaque point,
// a la fois les VALIDATEURS HTTP (etag, last-modified, validite — l'obligation de
// cache de MET Norway) et l'EMPREINTE DE CONTENU du dernier document ecrit. Une
// lecture suffit donc a savoir quoi appeler et quoi reecrire.
//
// C'est le meme raisonnement que #K6 pour la borne, applique au cout d'ecriture
// au lieu du cout de lecture. Cout mesure d'un passage meteo complet sur 70
// etapes : 2 lectures (registre + borne), et au plus 73 ecritures.
//
// ============================================================================
// LE COLLECTEUR NE SUPPRIME JAMAIS (#T3)
// ============================================================================
// Il n'existe AUCUN appel `delete` dans ce fichier, et ce n'est pas un oubli : une
// source qui tombe ressemble, du point de vue du code, a une source qui dit « il
// n'y a plus rien ». Retirer ce droit au collecteur ferme la confusion par
// construction. Le marqueur de suppression est un outil du PUBLICATEUR.

import { FieldValue, Timestamp } from 'firebase-admin/firestore';

import * as borne from './borne.js';
import * as battement from './battement.js';
import * as enrolement from './enrolement.js';

export const COLLECTION_REGISTRE = 'collecteur_registre';

/// Convertit les instants d'un document pur en types NATIFS de Firestore.
///
/// #H1 : « l'horodatage est pose par le serveur, de preference par l'horodatage
/// NATIF de sa base ». Un `Timestamp` se compare et s'indexe exactement ; une
/// chaine ISO se comparerait lexicographiquement, ce qui marche mais impose que
/// personne n'ecrive jamais un format different.
///
/// COTE APPLICATION, la lecture est deja prevue : `HorodatageServeur
/// .annonceParLeServeur` accepte un entier de millisecondes, donc
/// `annonceParLeServeur(ts.millisecondesEpoch)` — rien a changer dans le type.
function enTypesFirestore(document) {
  const out = { ...document };
  if (typeof out.rev === 'string') {
    out.rev = Timestamp.fromMillis(Date.parse(out.rev));
  }
  if (Number.isFinite(out.produiteLeMs)) {
    out.produiteLe = Timestamp.fromMillis(out.produiteLeMs);
    delete out.produiteLeMs;
  }
  return out;
}

export class Depot {
  constructor(db, { aBlanc = false } = {}) {
    this.db = db;
    this.aBlanc = aBlanc;
    this.ecrituresEvitees = 0;
    this.ecrituresFaites = 0;
    this.octetsEcrits = 0;
  }

  /// Lit la liste enrolee. UNE lecture.
  async lireEnrolement() {
    const snap = await this.db.collection(enrolement.COLLECTION).doc(enrolement.DOCUMENT).get();
    return enrolement.validerEnrolement(snap.exists ? snap.data() : null);
  }

  /// Lit le registre d'une famille. UNE lecture.
  async lireRegistre(famille) {
    const snap = await this.db.collection(COLLECTION_REGISTRE).doc(famille).get();
    const data = snap.exists ? snap.data() : {};
    return {
      points: (data.points ?? {}),
      empreintes: (data.empreintes ?? {}),
    };
  }

  async ecrireRegistre(famille, registre) {
    if (this.aBlanc) return;
    await this.db.collection(COLLECTION_REGISTRE).doc(famille).set(
      { points: registre.points, empreintes: registre.empreintes, majLe: FieldValue.serverTimestamp() },
      { merge: false },
    );
    this.ecrituresFaites += 1;
  }

  /// Lit la borne. UNE lecture. Sert aussi de plancher de monotonie d'horloge.
  async lireBorne() {
    const snap = await this.db.collection(borne.COLLECTION).doc(borne.DOCUMENT).get();
    if (!snap.exists) return null;
    const data = snap.data();
    // La borne stockee porte des Timestamp ; on la ramene en instants ISO pour que
    // toute la logique de fusion reste PURE et testable sans Firestore.
    const sentiers = {};
    for (const [trailId, familles] of Object.entries(data.sentiers ?? {})) {
      sentiers[trailId] = {};
      for (const [famille, valeur] of Object.entries(familles ?? {})) {
        sentiers[trailId][famille] = valeur instanceof Timestamp
          ? valeur.toDate().toISOString()
          : String(valeur);
      }
    }
    return { sentiers };
  }

  /// Depose les documents d'etape qui ont REELLEMENT change.
  ///
  /// Un lot Firestore (`batch`) est atomique : les documents d'un meme passage
  /// apparaissent ensemble. Ce n'est PAS ce qui garantit l'absence de
  /// demi-bulletin — c'est la forme du document qui la garantit (un bulletin =
  /// un document, voir documents.js) — mais cela evite qu'un telephone
  /// interrogeant au milieu d'un passage voie trois etapes sur sept.
  ///
  /// Firestore limite un lot a 500 operations : on decoupe, et chaque tranche
  /// reste atomique. Une tranche perdue laisse les autres en place, ce qui est
  /// exactement #T2 (on ecrit ce qu'on a).
  async deposer(collection, aEcrire) {
    if (aEcrire.length === 0) return 0;
    if (this.aBlanc) {
      this.ecrituresEvitees += aEcrire.length;
      for (const { document } of aEcrire) {
        this.octetsEcrits += Buffer.byteLength(JSON.stringify(document), 'utf8');
      }
      return 0;
    }
    const TAILLE = 400;
    let faites = 0;
    for (let i = 0; i < aEcrire.length; i += TAILLE) {
      const tranche = aEcrire.slice(i, i + TAILLE);
      const lot = this.db.batch();
      for (const { identite, document } of tranche) {
        lot.set(this.db.collection(collection).doc(identite), enTypesFirestore(document));
        this.octetsEcrits += Buffer.byteLength(JSON.stringify(document), 'utf8');
      }
      await lot.commit();
      faites += tranche.length;
    }
    this.ecrituresFaites += faites;
    return faites;
  }

  /// Avance la borne EN TRANSACTION.
  ///
  /// #K9 : les deux producteurs ecrivent le meme document, chacun ses lignes. Un
  /// ecrasement effacerait les familles du publicateur ; et `arreteA` etant le
  /// MINIMUM de toutes les familles (#K10), il ne peut pas se calculer sans les
  /// avoir relues. Une transaction est donc necessaire, pas prudente.
  ///
  /// ET ELLE EST ECRITE APRES LES DONNEES, JAMAIS AVANT. La borne promet « avant
  /// cet instant, plus rien ne sera ecrit » : la publier avant d'avoir ecrit
  /// ouvrirait exactement la fenetre que #K4 decrit.
  async avancerLaBorne(avancees) {
    if (this.aBlanc) return null;
    const reference = this.db.collection(borne.COLLECTION).doc(borne.DOCUMENT);
    const resultat = await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(reference);
      const stockee = snap.exists ? snap.data() : null;
      const lue = { sentiers: {} };
      for (const [trailId, familles] of Object.entries(stockee?.sentiers ?? {})) {
        lue.sentiers[trailId] = {};
        for (const [famille, valeur] of Object.entries(familles ?? {})) {
          lue.sentiers[trailId][famille] = valeur instanceof Timestamp
            ? valeur.toDate().toISOString()
            : String(valeur);
        }
      }
      const fusionnee = borne.fusionner(lue, avancees);

      const sentiers = {};
      for (const [trailId, familles] of Object.entries(fusionnee.sentiers)) {
        sentiers[trailId] = {};
        for (const [famille, instant] of Object.entries(familles)) {
          sentiers[trailId][famille] = Timestamp.fromMillis(Date.parse(instant));
        }
      }
      tx.set(reference, {
        arreteA: fusionnee.arreteA === null ? null : Timestamp.fromMillis(Date.parse(fusionnee.arreteA)),
        sentiers,
        // Le contrat de lecture, ECRIT DANS LA DONNEE : sans lui, un futur lot
        // prendrait `arreteA` pour un repere de rattrapage et relirait tout.
        contratDeLecture: borne.NOTE_POUR_LE_LECTEUR,
      }, { merge: false });
      return fusionnee;
    });
    this.ecrituresFaites += 1;
    return resultat;
  }

  /// Ecrit le battement. TOUJOURS, succes ou echec (#H2).
  ///
  /// Chaque tache ne fusionne QUE sa propre section : trois planifications, trois
  /// sections, aucune n'ecrase les autres.
  async battre(tache, section) {
    if (this.aBlanc) return;
    await this.db.collection(battement.COLLECTION).doc(battement.DOCUMENT).set(
      { [tache]: section },
      { merge: true },
    );
    this.ecrituresFaites += 1;
  }

  async lireBattement() {
    const snap = await this.db.collection(battement.COLLECTION).doc(battement.DOCUMENT).get();
    return snap.exists ? snap.data() : null;
  }

  /// Le surveillant depose ses alertes a cote du battement, dans sa propre section.
  async deposerAlertes(alertes, passage) {
    if (this.aBlanc) return;
    await this.db.collection(battement.COLLECTION).doc(battement.DOCUMENT).set(
      { surveillant: { executeLe: passage.instant, alertes, nombre: alertes.length } },
      { merge: true },
    );
    this.ecrituresFaites += 1;
  }
}
