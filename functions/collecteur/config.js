// LA CONFIGURATION DU COLLECTEUR — lue dans l'ENVIRONNEMENT, jamais dans le
// depot. Logique PURE (elle recoit l'environnement, elle ne le lit pas).
//
// ============================================================================
// AUCUNE VALEUR D'IDENTIFICATION DANS LE DEPOT, JAMAIS
// ============================================================================
// C'est la regle absolue que `lib/core/config/firebase_config.dart` pose pour
// l'application, et elle vaut ici mot pour mot. Le collecteur lit ses acces dans
// son environnement.
//
// BONNE NOUVELLE MESUREE : **aucune des deux sources n'a de cle.** La Meteo des
// forets est un fichier public (mesure : HTTP 200 sans cle, sans compte) et MET
// Norway n'en demande pas non plus. Il n'y a donc AUCUN secret a gerer pour la
// collecte — ce qui referme d'avance la question « ou range-t-on la cle ».
//
// ============================================================================
// CE QUI EST OBLIGATOIRE, ET POURQUOI C'EST UN REFUS ET PAS UN DEFAUT
// ============================================================================
// MET Norway EXIGE un User-Agent nommant l'application ET un moyen de contact
// (#S09). Appeler sans cela viole leurs conditions et fait BANNIR l'application
// entiere — pas un telephone, l'application. Il n'existe donc pas de valeur par
// defaut raisonnable : un UA generique serait une violation deguisee en repli.
//
// Le collecteur REFUSE DE PARTIR sans lui. C'est la meme doctrine que la
// fermeture par defaut de l'empreinte au lot 607 : mieux vaut ne rien faire que
// faire une chose interdite. Et le refus est ECRIT DANS LE BATTEMENT, donc le
// surveillant le voit — un refus muet serait pire que l'appel interdit.

export const VARIABLES = Object.freeze({
  /// OBLIGATOIRE. Exemple : `StepWays/1.0 (https://stepways.app; contact@exemple.org)`
  userAgent: 'STEPWAYS_COLLECTEUR_USER_AGENT',
  /// `met-norway` (defaut) ou `open-meteo` (repli, #A3). UN SEUL a la fois.
  fournisseurMeteo: 'STEPWAYS_COLLECTEUR_FOURNISSEUR_METEO',
  /// Portee en jours, bornee a [3..5] (#W6).
  joursPortee: 'STEPWAYS_COLLECTEUR_JOURS_PORTEE',
  /// Fuseau retenu quand la donnee du sentier n'en declare pas.
  fuseauDefaut: 'STEPWAYS_COLLECTEUR_FUSEAU_DEFAUT',
  /// `1` pour allumer la carte corse par massif. ETEINT PAR DEFAUT : sa licence
  /// n'est pas etablie (#I8). Ce n'est pas un reglage de confort.
  corseActif: 'STEPWAYS_COLLECTEUR_CORSE_ACTIF',
  /// Mode a blanc : tout est calcule, RIEN n'est ecrit. Sert a mesurer un passage
  /// complet sans toucher la base.
  aBlanc: 'STEPWAYS_COLLECTEUR_A_BLANC',
});

export const FOURNISSEURS = Object.freeze(['met-norway', 'open-meteo']);

export class ConfigurationRefusee extends Error {
  constructor(message, variable) {
    super(message);
    this.name = 'ConfigurationRefusee';
    this.variable = variable ?? null;
  }
}

/// MET Norway veut « the application/domain name » ET un moyen de contact. On
/// verifie donc qu'il y a de quoi nous joindre : une adresse de courriel ou une
/// URL. Un UA sans contact ne satisfait pas la condition et serait une violation
/// qui passe les tests.
const MOTIF_CONTACT = /(@[\w.-]+\.\w{2,}|https?:\/\/[\w.-]+)/;

/// Longueur minimale d'un UA credible. Un `UA: x` passerait le motif de contact
/// mais ne nommerait rien.
export const LONGUEUR_MINIMALE_UA = 12;

export function lireConfiguration(environnement = {}) {
  const brutUa = environnement[VARIABLES.userAgent];
  if (typeof brutUa !== 'string' || brutUa.trim().length < LONGUEUR_MINIMALE_UA) {
    throw new ConfigurationRefusee(
      `${VARIABLES.userAgent} est obligatoire : MET Norway exige un User-Agent nommant `
      + 'l application. Sans lui le collecteur ne part pas — un appel anonyme fait bannir '
      + 'l application entiere (conditions api.met.no).',
      VARIABLES.userAgent,
    );
  }
  const userAgent = brutUa.trim();
  if (!MOTIF_CONTACT.test(userAgent)) {
    throw new ConfigurationRefusee(
      `${VARIABLES.userAgent} doit porter un MOYEN DE CONTACT (courriel ou URL) : `
      + 'MET Norway l exige explicitement, pas seulement un nom.',
      VARIABLES.userAgent,
    );
  }

  const fournisseurMeteo = (environnement[VARIABLES.fournisseurMeteo] ?? 'met-norway').trim();
  if (!FOURNISSEURS.includes(fournisseurMeteo)) {
    throw new ConfigurationRefusee(
      `${VARIABLES.fournisseurMeteo} = ${fournisseurMeteo} inconnu (attendu: ${FOURNISSEURS.join(', ')})`,
      VARIABLES.fournisseurMeteo,
    );
  }

  let joursPortee = Number(environnement[VARIABLES.joursPortee] ?? 5);
  if (!Number.isInteger(joursPortee)) joursPortee = 5;
  // Borne DURE sur la decision de Christophe (« 3 ou 5 jours »). Une valeur hors
  // bornes est ramenee dedans plutot que refusee : ce reglage-la n'a aucune
  // consequence de securite, et bloquer une collecte pour un chiffre de confort
  // serait disproportionne. Mais le ramene est DIT dans le retour.
  const jourPorteeBornee = Math.min(5, Math.max(3, joursPortee));

  return Object.freeze({
    userAgent,
    fournisseurMeteo,
    joursPortee: jourPorteeBornee,
    joursPorteeRamenee: jourPorteeBornee !== joursPortee,
    fuseauDefaut: (environnement[VARIABLES.fuseauDefaut] ?? 'Europe/Paris').trim(),
    // ETEINT sauf demande EXPLICITE. La licence n'est pas etablie (#I8).
    corseActif: environnement[VARIABLES.corseActif] === '1',
    aBlanc: environnement[VARIABLES.aBlanc] === '1',
  });
}

/// Vrai si l'environnement contient quelque chose qui ressemble a une cle.
///
/// Sert au test de discipline : aucune des deux sources n'a de cle, donc une
/// variable de cle dans l'environnement du collecteur signale une derive — soit
/// quelqu'un a change de source sans le dire, soit un secret traine la ou il n'a
/// rien a faire.
export function variablesSuspectes(environnement = {}) {
  const suspects = [];
  for (const nom of Object.keys(environnement)) {
    if (!nom.startsWith('STEPWAYS_COLLECTEUR_')) continue;
    if (Object.values(VARIABLES).includes(nom)) continue;
    if (/(KEY|TOKEN|SECRET|PASSWORD|MDP|APIKEY)/i.test(nom)) suspects.push(nom);
  }
  return suspects;
}
