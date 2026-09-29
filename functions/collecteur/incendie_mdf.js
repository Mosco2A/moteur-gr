// METEO DES FORETS (Meteo-France) — lecture du bulletin de danger. Logique PURE.
//
// Source : meteofrance.s3.sbg.io.cloud.ovh.net/data/BULLETIN/MDF/mdf_2026.csv.gz
// Licence Ouverte 2.0 (Etalab), usage commercial autorise, mention « Meteo-France »
// obligatoire (#S02 du corpus #100736). Sans cle, sans compte.
//
// ============================================================================
// CE QUE J'AI MESURE MOI-MEME LE 28/09/2026 A 21:33 UTC, ET QUI CORRIGE LA
// CONCEPTION 611 SUR UN POINT QUI AURAIT FAIT AFFICHER LE MAUVAIS JOUR.
// ============================================================================
//
// La colonne `date` N'EST PAS UNE DATE DE VALIDITE : c'est un INSTANT DE
// PRODUCTION complet, `2026-09-28T14:50:06Z`. Et `niveau_j1` / `niveau_j2` sont
// les niveaux de J+1 et J+2 *relatifs a ce jour de production*.
//
// CONSEQUENCE QUI CHANGE L'IMPLEMENTATION : **le fichier ne contient PAS le
// niveau d'aujourd'hui dans la ligne d'aujourd'hui.** Le niveau du jour J est
// porte par la ligne produite la VEILLE (J-1), champ `niveau_j1`. Les §3.2.3 et
// #I17 de la conception 611 supposent l'inverse (« le bulletin stocke porte la
// date du jour ») : appliquees a la lettre, elles auraient affiche la prevision
// de DEMAIN comme etant celle d'AUJOURD'HUI, en pleine saison des feux.
//
// COMMENT JE L'AI ETABLI, plutot que suppose. Le fichier est CUMULATIF (toute la
// saison y est). Si `niveau_j1` de la ligne du jour D vise D+1, alors
// `ligne(D).niveau_j2` et `ligne(D+1).niveau_j1` visent le MEME jour D+2 et
// doivent concorder plus souvent que deux jours differents. Mesure sur les
// 11 808 paires disponibles :
//     ligne(D).niveau_j2 == ligne(D+1).niveau_j1  ->  87,9 %
//     ligne(D).niveau_j1 == ligne(D+1).niveau_j1  ->  75,7 %
// Douze points d'ecart : le recouvrement est reel, l'hypothese est etablie.
//
// AUTRES MESURES DU MEME PASSAGE :
//   - 47 374 octets gzip, HTTP 200, `ETag` et `Last-Modified` presents
//     -> la requete conditionnelle fonctionne, un passage sans nouveaute coute
//        un 304 et zero octet ;
//   - 11 904 lignes = 96 departements x 124 jours de production, EXACTEMENT :
//     zero jour manquant depuis le 28/05. La regularite est celle d'une horloge ;
//   - encodage UTF-8 (verifie par decodage strict) ;
//   - production a 14:50 UTC ;
//   - 2A et 2B presents.

import { jourDecale, ecartEnJours } from './horodatage.js';

/// Les quatre niveaux et leurs libelles OFFICIELS (#S03). On affiche le niveau
/// publie ; on ne le recalcule jamais — Meteo-France publie le niveau, pas le
/// seuil (#R2 de la conception).
export const LIBELLES = Object.freeze({
  1: 'Danger faible',
  2: 'Danger modere',
  3: 'Danger eleve',
  4: 'Danger tres eleve',
});

/// Ce que Meteo-France dit d'elle-meme, et qui fixe la hierarchie des deux
/// sources (#I7) : la Meteo des forets INFORME, elle n'interdit pas. Les
/// prefectures restent souveraines. Ce texte accompagne la donnee pour que
/// l'ecran ne puisse pas la presenter comme une interdiction.
export const PORTEE = 'informative';

export const SOURCE = 'meteo-france-meteo-des-forets';
export const ATTRIBUTION = 'Meteo-France';
export const LICENCE = 'Licence Ouverte 2.0 (Etalab)';

/// Au-dela de ce retard du dernier jour de production, la saison est declaree
/// TERMINEE. Deux jours : la source n'a rate aucun jour sur 124, donc deux jours
/// de silence ne sont pas un alea. C'est ce qui permet de distinguer
/// « hors saison » (#I19) de « en panne » (#I20) — et cette distinction compte,
/// parce qu'un message de panne affiche tout l'hiver apprend au randonneur a
/// ignorer les messages.
export const JOURS_AVANT_HORS_SAISON = 2;

export const REFUS = Object.freeze({
  colonnes: 'colonnes-inattendues',
  vide: 'fichier-vide',
  niveauHorsDomaine: 'niveau-hors-domaine',
  dateIllisible: 'date-de-production-illisible',
});

/// Decoupe une ligne CSV `a;b;c`. Le fichier mesure ne contient ni guillemets
/// ni separateur echappe : un decoupage simple suffit, et un jour ou ce ne serait
/// plus vrai le controle de colonnes ci-dessous le dirait.
function champs(ligne) {
  return ligne.split(';').map((c) => c.trim());
}

/// Lit le CSV et rend un bulletin par (jour cible, departement).
///
/// Rend `{ ok, parDepartement, saison, produiteLe... }` ou `{ ok: false, raison }`.
export function lireMeteoDesForets(texte, { jourCourant }) {
  if (typeof texte !== 'string' || texte.length === 0) {
    return { ok: false, raison: REFUS.vide };
  }
  const lignes = texte.split(/\r?\n/).filter((l) => l.length > 0);
  if (lignes.length < 2) return { ok: false, raison: REFUS.vide };

  const entete = champs(lignes[0]);
  const attendu = ['date', 'num_dep', 'niveau_j1', 'niveau_j2', 'nom_dep'];
  if (entete.length !== attendu.length || attendu.some((c, i) => entete[i] !== c)) {
    return { ok: false, raison: REFUS.colonnes, detail: entete.join(';') };
  }

  // Cle : `${jourCible}|${departement}` -> { niveau, jourDeProduction, produiteLe }
  // Une meme cible peut etre annoncee deux fois (j2 de la veille, j1 du jour) :
  // LA PRODUCTION LA PLUS RECENTE GAGNE. C'est #A4 — la source gagne toujours,
  // et entre deux versions de la source, la plus fraiche.
  const brut = new Map();
  let dernierJourDeProduction = null;
  let premierJourDeProduction = null;
  let derniereProduction = null;

  for (let i = 1; i < lignes.length; i += 1) {
    const c = champs(lignes[i]);
    if (c.length !== 5) continue;
    const [dateBrute, dep, j1, j2] = c;
    const msProduction = Date.parse(dateBrute);
    if (!Number.isFinite(msProduction)) continue;
    const jourDeProduction = new Date(msProduction).toISOString().slice(0, 10);

    if (dernierJourDeProduction === null || jourDeProduction > dernierJourDeProduction) {
      dernierJourDeProduction = jourDeProduction;
      derniereProduction = dateBrute;
    }
    if (premierJourDeProduction === null || jourDeProduction < premierJourDeProduction) {
      premierJourDeProduction = jourDeProduction;
    }

    // LE DECALAGE MESURE : j1 vise le LENDEMAIN du jour de production, j2 le
    // surlendemain. C'est la correction du §3.2.3 de la conception 611.
    for (const [decalage, niveauBrut] of [[1, j1], [2, j2]]) {
      if (niveauBrut === '' || niveauBrut === undefined) continue;
      const niveau = Number(niveauBrut);
      if (!Number.isInteger(niveau)) continue;
      if (niveau < 1 || niveau > 4) {
        return { ok: false, raison: REFUS.niveauHorsDomaine, detail: `${dep} -> ${niveauBrut}` };
      }
      const jourCible = jourDecale(jourDeProduction, decalage);
      const cle = `${jourCible}|${dep}`;
      const dejaLa = brut.get(cle);
      if (dejaLa === undefined || jourDeProduction > dejaLa.jourDeProduction) {
        brut.set(cle, { niveau, jourDeProduction, produiteLe: dateBrute, departement: dep, jour: jourCible });
      }
    }
  }

  if (dernierJourDeProduction === null) {
    return { ok: false, raison: REFUS.dateIllisible };
  }

  // La saison est declaree depuis LE FICHIER lui-meme, pas depuis un calendrier
  // code en dur : c'est la source qui sait quand elle publie (#R7 — je ne peux
  // pas dire aujourd'hui ce que le fichier fait en octobre, donc je le lui
  // demande a chaque passage au lieu de le supposer).
  const retard = ecartEnJours(dernierJourDeProduction, jourCourant);
  const saison = Object.freeze({
    active: retard <= JOURS_AVANT_HORS_SAISON,
    premierJourPublie: premierJourDeProduction,
    dernierJourPublie: dernierJourDeProduction,
    retardEnJours: retard,
  });

  const parDepartement = new Map();
  for (const entree of brut.values()) {
    let m = parDepartement.get(entree.departement);
    if (m === undefined) {
      m = new Map();
      parDepartement.set(entree.departement, m);
    }
    m.set(entree.jour, entree);
  }

  return {
    ok: true,
    parDepartement,
    saison,
    derniereProduction,
    departements: [...parDepartement.keys()].sort(),
  };
}

/// Extrait le bulletin d'UN departement pour UN jour, pret a etre depose.
///
/// Rend `null` quand la source ne dit rien pour ce couple : #T1 — le collecteur
/// n'ecrit PAS un vide. La donnee precedente reste en place avec sa date, et
/// c'est le LECTEUR qui conclut « perime » en comparant le jour du bulletin au
/// jour courant (#I16 : la peremption de cette famille n'est pas une duree, c'est
/// une date). Ecrire un etat « perime » cote serveur serait une erreur : l'etat
/// se perime, lui aussi, douze heures plus tard.
export function bulletinPourDepartement(lecture, departement, jour) {
  const parJour = lecture.parDepartement.get(departement);
  if (parJour === undefined) return null;
  const e = parJour.get(jour);
  if (e === undefined) return null;
  return Object.freeze({
    niveau: e.niveau,
    libelle: LIBELLES[e.niveau],
    jour: e.jour,
    produiteLe: e.produiteLe,
    jourDeProduction: e.jourDeProduction,
    source: SOURCE,
    attribution: ATTRIBUTION,
    licence: LICENCE,
    portee: PORTEE,
  });
}

/// Les jours a deposer pour un departement, du jour courant vers l'avant.
///
/// Le fichier donne au mieux J+2 depuis la derniere production, donc trois jours
/// au maximum (hier->aujourd'hui, aujourd'hui->J+1, aujourd'hui->J+2). On ne
/// remplit jamais un trou par interpolation.
export function joursPourDepartement(lecture, departement, jourCourant, nombre = 3) {
  const out = [];
  for (let i = 0; i < nombre; i += 1) {
    const b = bulletinPourDepartement(lecture, departement, jourDecale(jourCourant, i));
    if (b !== null) out.push(b);
  }
  return out;
}
