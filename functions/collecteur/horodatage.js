// L'AUTORITE DE TEMPS DU COLLECTEUR — le pendant serveur de HorodatageServeur
// (lot 610, cote application).
//
// POURQUOI CE FICHIER EXISTE, ET CE N'EST PAS UNE COMMODITE.
// Cote application, HorodatageServeur a un constructeur PRIVE : ecrire
// HorodatageServeur(DateTime.now()) est une ERREUR DE COMPILATION, pour qu'une
// horloge de telephone ne puisse JAMAIS servir de reference (#H1/#H2, §12.2 de
// la spec 605). Cote serveur la meme discipline doit tenir, et JavaScript n'a
// pas de constructeur prive. Elle est donc tenue par trois moyens CUMULES :
//
//   1. ce module est le SEUL du collecteur autorise a lire une horloge ;
//   2. il n'exporte aucun moyen de fabriquer un instant arbitraire : on ouvre
//      un PASSAGE, qui rend UN SEUL instant valable pour tout le passage ;
//   3. un test parcourt les sources de collecteur/ et REFUSE tout autre appel
//      d'horloge (`Date.now()`, `new Date()` sans argument).
//      Voir test/collecteur_horodatage.test.mjs.
//
// Une convention se viole en silence ; un test refuse.
//
// POURQUOI UN SEUL INSTANT POUR TOUT LE PASSAGE, et pas serverTimestamp() par
// enregistrement : la borne (#K3 de la conception 611) vaut « avant cet instant,
// plus rien ne sera ecrit ». Elle doit donc etre une valeur CONNUE avant
// l'ecriture, pour etre ecrite APRES elle. Le sentinel serverTimestamp() de
// Firestore ne se lit pas au moment de l'ecriture : il ne peut pas servir a
// calculer une borne. Un instant unique par passage donne en plus une propriete
// gratuite : tous les enregistrements d'un meme passage sont indiscernables en
// date, donc un telephone les prend tous ou aucun.

/// L'origine : le repere d'un telephone qui n'a jamais rien recu (#R5).
export const INSTANT_ORIGINE = '1970-01-01T00:00:00.000Z';

/// Le fuseau retenu quand la donnee du sentier n'en declare pas.
///
/// MET Norway rend des instants UTC et NE resout PAS le fuseau depuis les
/// coordonnees, contrairement au `timezone=auto` d'Open-Meteo que l'application
/// utilise aujourd'hui. Le fuseau est donc une DECISION du collecteur, et il est
/// ECRIT dans chaque bulletin (champ `fuseau`) : jamais implicite.
export const FUSEAU_DEFAUT = 'Europe/Paris';

const MOTIF_JOUR = /^(\d{4})-(\d{2})-(\d{2})$/;
const MOTIF_FUSEAU_EXPLICITE = /(Z|[+-]\d{2}:?\d{2})$/;

/// Erreur levee quand un instant ne peut pas etre lu.
export class InstantIllisible extends Error {
  constructor(valeur) {
    super(`instant illisible: ${JSON.stringify(valeur)}`);
    this.name = 'InstantIllisible';
  }
}

/// Rend un instant en ISO 8601 UTC AVEC MILLISECONDES (#H3, #R15).
///
/// `toISOString()` rend toujours exactement `YYYY-MM-DDTHH:mm:ss.sssZ` : 24
/// caracteres, longueur fixe, zero-paddes. Deux consequences qu'on exploite :
/// la comparaison LEXICOGRAPHIQUE de deux instants est la comparaison
/// chronologique, et le format ne depend d'aucune locale.
export function enInstant(millisecondes) {
  if (!Number.isFinite(millisecondes)) throw new InstantIllisible(millisecondes);
  return new Date(millisecondes).toISOString();
}

/// Relit un instant ecrit par `enInstant` (ou par le publicateur Dart).
///
/// Refuse une chaine sans fuseau : « une ecriture sans fuseau est lue en UTC,
/// jamais en heure locale » (#H3) — et plutot que de la deviner, on la refuse,
/// parce qu'une lecture silencieusement decalee est exactement le defaut que
/// tout ce modele cherche a fermer.
export function enMillisecondes(instant) {
  if (typeof instant !== 'string' || instant.length === 0) {
    throw new InstantIllisible(instant);
  }
  if (!MOTIF_FUSEAU_EXPLICITE.test(instant)) throw new InstantIllisible(instant);
  const ms = Date.parse(instant);
  if (!Number.isFinite(ms)) throw new InstantIllisible(instant);
  return ms;
}

/// OUVRE UN PASSAGE : la SEULE porte par laquelle une horloge devient un
/// horodatage dans tout le collecteur.
///
/// `borneAnterieure` est la borne du passage precedent, relue depuis la base.
/// Si l'horloge du serveur a RECULE (correction NTP, changement de machine),
/// l'instant du passage avance d'UNE milliseconde au-dessus d'elle et le
/// passage le DIT (`horlogeCorrigee`) — meme doctrine que l'outil de
/// publication (#R16). Un instant anterieur ou egal au precedent serait
/// INVISIBLE pour tous les telephones deja a jour, definitivement et sans
/// trace : c'est le seul defaut de ce modele qui ne se voit pas.
export function ouvrirPassage({ borneAnterieure = null, nom = 'passage' } = {}) {
  // La seule lecture d'horloge de tout le collecteur. Elle est ici, une fois.
  const horloge = Date.now();
  return _passage(horloge, borneAnterieure, nom);
}

/// Ouvre un passage a un instant IMPOSE — reserve aux tests.
///
/// Il n'existe pas de chemin de production vers cette fonction : rien du
/// collecteur ne l'appelle, et le test de discipline le verifie. Elle existe
/// pour que les modules purs soient testables sans horloge, ce qui est la
/// condition pour qu'ils n'en lisent JAMAIS.
export function passageFixePourTest(millisecondes, { borneAnterieure = null, nom = 'test' } = {}) {
  return _passage(millisecondes, borneAnterieure, nom);
}

function _passage(horloge, borneAnterieure, nom) {
  let millisecondes = horloge;
  let horlogeCorrigee = false;
  if (borneAnterieure !== null && borneAnterieure !== undefined) {
    const precedent = enMillisecondes(borneAnterieure);
    if (millisecondes <= precedent) {
      millisecondes = precedent + 1;
      horlogeCorrigee = true;
    }
  }
  return Object.freeze({
    nom,
    instant: enInstant(millisecondes),
    millisecondes,
    horlogeCorrigee,
    horlogeBrute: enInstant(horloge),
  });
}

/// Le plus ancien de deux instants (`null` = pas de contrainte).
export function plusAncien(a, b) {
  if (!a) return b;
  if (!b) return a;
  return enMillisecondes(a) <= enMillisecondes(b) ? a : b;
}

const _formatteursDeJour = new Map();

function formatteurDeJour(fuseau) {
  let f = _formatteursDeJour.get(fuseau);
  if (f === undefined) {
    // Node 20 embarque l'ICU complet : les fuseaux IANA sont disponibles sans
    // dependance. Un fuseau inconnu leve ici, au lieu de decaler en silence.
    // `fr-CA` rend YYYY-MM-DD, seule locale courante a le faire nativement.
    f = new Intl.DateTimeFormat('fr-CA', {
      timeZone: fuseau,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
    });
    _formatteursDeJour.set(fuseau, f);
  }
  return f;
}

/// Le JOUR CIVIL (`YYYY-MM-DD`) dans lequel tombe un instant, pour un fuseau.
///
/// POURQUOI LE JOUR LOCAL ET PAS LE JOUR UTC. Un randonneur corse lit « demain »
/// en heure locale. Decouper les journees en UTC rangerait 22h-00h locales dans
/// la veille : la prevision du soir serait attribuee au mauvais jour, et l'erreur
/// serait invisible parce qu'elle ne se voit que sur deux heures par jour.
export function jourLocal(millisecondes, fuseau = FUSEAU_DEFAUT) {
  return formatteurDeJour(fuseau).format(new Date(millisecondes));
}

function jourEnMsMidiUtc(jour) {
  const m = typeof jour === 'string' ? jour.match(MOTIF_JOUR) : null;
  if (!m) throw new InstantIllisible(jour);
  return Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]), 12, 0, 0);
}

/// Le jour civil `YYYY-MM-DD` decale de `n` jours (n peut etre negatif).
///
/// L'arithmetique se fait a MIDI UTC : ajouter 24 h a minuit tomberait a cote un
/// jour de changement d'heure, et cette erreur-la n'arrive que deux fois par an —
/// donc elle passe tous les tests ecrits un autre jour.
export function jourDecale(jour, n) {
  return new Date(jourEnMsMidiUtc(jour) + n * 86400000).toISOString().slice(0, 10);
}

/// Nombre de jours civils entiers de `depuis` a `jusqu`.
export function ecartEnJours(depuis, jusqu) {
  return Math.round((jourEnMsMidiUtc(jusqu) - jourEnMsMidiUtc(depuis)) / 86400000);
}
