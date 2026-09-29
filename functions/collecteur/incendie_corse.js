// CARTE DU RISQUE PAR MASSIF EN CORSE — lecture du flux. Logique PURE.
//
// Source : risque-prevention-incendie.fr/static/20/import_data/YYYYMMDD.json
// Autorite : services de l'Etat en Corse, DRAAF Corse.
//
// ============================================================================
// CE FLUX EST ECRIT, TESTE, ET **DESACTIVE PAR DEFAUT**. LA RAISON EST JURIDIQUE.
// ============================================================================
//
// #I8 / #R1 de la conception 611 : **la licence de ce flux n'est PAS etablie.**
// Aucune page de mentions legales (deux URL testees, 404). Le site est public et
// produit par l'Etat, ce qui rend la Licence Ouverte PLAUSIBLE — mais plausible
// n'est pas etabli, et StepWays est payant. On demarre donc sur la Meteo des
// forets seule, dont la licence est sans ambiguite, et ce module ne s'allume
// qu'apres reponse de `srfb.draaf-corse@agriculture.gouv.fr`.
//
// Le code existe quand meme, pour une raison pratique : le jour ou le courriel
// revient, il n'y a rien a ecrire, seulement une variable d'environnement a
// poser (`STEPWAYS_COLLECTEUR_CORSE_ACTIF`). Et il est teste, donc il ne
// pourrira pas en attendant.
//
// ============================================================================
// CE QUE J'AI MESURE LE 28/09/2026 A 21:34 UTC
// ============================================================================
//   - `20260929.json` : HTTP 200, 982 octets, `Last-Modified` = 28/09 15:45:04 UTC.
//     `20260928.json` : HTTP 200, 982 octets, `Last-Modified` = 27/09 15:45:03 UTC.
//     -> LE FICHIER PORTE LE JOUR QU'IL DECRIT, et il est pose LA VEILLE vers
//        15:45 UTC. Un seul jour a la fois. Demander le jour J+1 apres 15:45 UTC
//        marche ; avant, il repond 404 (mesure d'Athena le matin du 28).
//   - `ETag` et `Last-Modified` presents MAIS `Cache-Control: no-cache, no-store,
//     must-revalidate` : le serveur refuse qu'on garde sa reponse. On respecte
//     l'entete (aucune reponse conservee) tout en gardant les VALIDATEURS, ce qui
//     reste licite et suffit a eviter de retelecharger l'identique.
//   - 11 massifs et 17 zones meteo dans le fichier du jour.
//   - PIEGE MESURE, absent de la conception : **les identifiants de massif et de
//     zone se CHEVAUCHENT numeriquement.** 211, 213, 214, 215 et 207 sont
//     presents dans `massifs` ET dans `zm`, et ne designent pas la meme chose.
//     Ce sont deux espaces de noms distincts. Les confondre donnerait un niveau
//     faux sans qu'aucune erreur ne se produise — c'est exactement le genre de
//     defaut que ce dossier passe son temps a fermer. Les deux sont donc lus,
//     stockes et nommes SEPAREMENT, jamais dans un meme dictionnaire.

export const SOURCE = 'risque-prevention-incendie-corse';
export const ATTRIBUTION = 'Services de l Etat en Corse / DRAAF Corse';

/// LA licence n'est pas etablie. Ce n'est pas un champ decoratif : il descend
/// jusqu'a la donnee pour qu'on ne puisse pas oublier pourquoi elle est eteinte.
export const LICENCE = 'NON ETABLIE — voir #I8 / #R1, courriel DRAAF Corse a envoyer';

/// Cette source porte une INTERDICTION, la Meteo des forets non (#I6, #I7).
/// C'est la seule des deux qui a force de loi, et c'est pour cela qu'on ne les
/// fusionne pas en un seul chiffre.
export const PORTEE = 'contraignante';

/// L'ECHELLE N'EST PAS ETABLIE, et je ne l'invente pas.
///
/// La carte publique affiche quatre etats nommes (« Prudence », « Limitez votre
/// presence, quittez avant 11 h », « Dangereux, ne vous y engagez pas »,
/// « Acces interdit »). Le flux, lui, rend des ENTIERS, et rien ne dit
/// publiquement quel entier vaut quel etat. Les seules valeurs observees sont 1
/// et 2, sur des journees de fin septembre.
///
/// Mettre une table de libelles ici serait une supposition presentee comme un
/// fait, sur une donnee de securite qui porte une INTERDICTION. On transmet donc
/// le niveau brut avec `echelleEtablie: false`, et l'ecran renvoie a la carte
/// officielle — « le lien est la sortie de secours : il mene a l'autorite, qui
/// sait » (#I20). C'est une reserve a fermer avec le meme courriel que la licence.
export const ECHELLE_ETABLIE = false;

/// Niveau maximum plausible. Au-dela : refus (#A5).
export const NIVEAU_MAXIMUM = 4;

export const REFUS = Object.freeze({
  charpente: 'charpente-inattendue',
  niveauHorsDomaine: 'niveau-hors-domaine',
  vide: 'aucun-massif-ni-zone',
});

/// Le nom du fichier a demander pour un jour donne (`YYYY-MM-DD` -> `YYYYMMDD`).
export function nomDeFichierPour(jour) {
  return `${jour.slice(0, 4)}${jour.slice(5, 7)}${jour.slice(8, 10)}.json`;
}

function entierOuNull(v) {
  if (typeof v === 'number' && Number.isInteger(v)) return v;
  if (typeof v === 'string' && /^\d+$/.test(v)) return Number(v);
  return null;
}

/// Lit le flux d'un jour. `jour` est le jour que le fichier DECRIT (c'est son nom).
export function lireCarteCorse(objet, { jour }) {
  if (objet === null || typeof objet !== 'object') {
    return { ok: false, raison: REFUS.charpente, detail: 'racine non objet' };
  }

  // DEUX espaces de noms SEPARES — voir le piege mesure en tete de fichier.
  const massifs = new Map();
  const zones = new Map();

  const brutMassifs = objet.massifs;
  if (brutMassifs !== undefined) {
    if (brutMassifs === null || typeof brutMassifs !== 'object') {
      return { ok: false, raison: REFUS.charpente, detail: 'massifs non objet' };
    }
    for (const [id, valeur] of Object.entries(brutMassifs)) {
      if (!Array.isArray(valeur) || valeur.length < 1) {
        return { ok: false, raison: REFUS.charpente, detail: `massif ${id}` };
      }
      const niveau = entierOuNull(valeur[0]);
      const procedure = entierOuNull(valeur[1]);
      if (niveau === null || niveau < 0 || niveau > NIVEAU_MAXIMUM) {
        return { ok: false, raison: REFUS.niveauHorsDomaine, detail: `massif ${id} -> ${valeur[0]}` };
      }
      massifs.set(String(id), { niveau, procedure });
    }
  }

  const brutZones = objet.zm;
  if (brutZones !== undefined) {
    if (brutZones === null || typeof brutZones !== 'object') {
      return { ok: false, raison: REFUS.charpente, detail: 'zm non objet' };
    }
    for (const [id, valeur] of Object.entries(brutZones)) {
      const niveau = entierOuNull(valeur);
      if (niveau === null || niveau < 0 || niveau > NIVEAU_MAXIMUM) {
        return { ok: false, raison: REFUS.niveauHorsDomaine, detail: `zone ${id} -> ${valeur}` };
      }
      zones.set(String(id), { niveau });
    }
  }

  if (massifs.size === 0 && zones.size === 0) {
    return { ok: false, raison: REFUS.vide };
  }

  return { ok: true, jour, massifs, zones };
}

/// L'acces pour une etape, d'apres son massif et/ou sa zone.
///
/// #I12 : une donnee de securite s'arrondit VERS LE HAUT. Quand une etape est
/// rattachee a la fois a un massif et a une zone, on retient le MAXIMUM des deux
/// niveaux, jamais la moyenne et jamais « celui du massif parce qu'il est plus
/// fin ». Le raffinement « maximum des zones TRAVERSEES » (et non de la seule
/// zone d'arrivee) demande la geometrie de la trace : il n'est pas ici, il est
/// nomme en #R10 comme non mesure.
export function accesPourEtape(lecture, { massifIncendie = null, zoneIncendie = null } = {}) {
  const m = massifIncendie === null ? undefined : lecture.massifs.get(String(massifIncendie));
  const z = zoneIncendie === null ? undefined : lecture.zones.get(String(zoneIncendie));
  if (m === undefined && z === undefined) return null;

  const niveaux = [];
  if (m !== undefined) niveaux.push(m.niveau);
  if (z !== undefined) niveaux.push(z.niveau);

  return Object.freeze({
    niveau: Math.max(...niveaux),
    niveauMassif: m === undefined ? null : m.niveau,
    procedureMassif: m === undefined ? null : m.procedure,
    niveauZone: z === undefined ? null : z.niveau,
    massifIncendie: m === undefined ? null : String(massifIncendie),
    zoneIncendie: z === undefined ? null : String(zoneIncendie),
    jour: lecture.jour,
    source: SOURCE,
    attribution: ATTRIBUTION,
    licence: LICENCE,
    portee: PORTEE,
    // Le niveau est transmis BRUT : aucun libelle n'est etabli (voir
    // ECHELLE_ETABLIE). L'ecran doit renvoyer a la carte officielle.
    echelleEtablie: ECHELLE_ETABLIE,
    libelle: null,
  });
}
