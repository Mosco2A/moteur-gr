// TRADUCTION symbol_code MET Norway -> code WMO — logique PURE.
//
// POURQUOI CE FICHIER EXISTE. L'application ne connait qu'un vocabulaire :
// les codes WMO d'Open-Meteo (`DayForecast.weatherCode`, table
// `_wmoCodeDescriptions` de lib/features/weather/models/weather_forecast.dart).
// MET Norway parle un AUTRE vocabulaire : `symbol_code`, des noms comme
// 'partlycloudy_day' ou 'heavysleetshowersandthunder'. C'est le « travail reel »
// annonce en #W7 de la conception 611, et il tient ENTIEREMENT ici : l'appli ne
// voit jamais le fournisseur (#W8).
//
// LA CONTRAINTE QUI DECIDE DE LA TABLE, ET ELLE EST MESUREE.
// La table de libelles de l'application connait EXACTEMENT le sous-ensemble
// d'Open-Meteo : 0,1,2,3,45,48,51,53,55,56,57,61,63,65,66,67,71,73,75,77,80,81,
// 82,85,86,95,96,99. Tout autre code rend « Inconnu » a l'ecran
// (`_wmoCodeDescriptions[weatherCode] ?? 'Inconnu'`).
// Consequence : je NE PEUX PAS emettre 68/69 (« pluie et neige melees »), qui
// sont pourtant les codes WMO 4677 exacts de la neige fondue. Ils afficheraient
// « Inconnu ». La neige fondue est donc rangee avec la NEIGE, et c'est une
// approximation NOMMEE, pas un oubli : voir CODES_NEIGE_FONDUE.
//
// CE QUE JE REFUSE DE FAIRE, ET POURQUOI.
//   - Ranger la neige fondue en 66/67 (« pluie verglacante ») : la pluie
//     verglacante est un autre phenomene, plus dangereux. Annoncer un danger
//     qu'on n'a pas mesure est la meme faute qu'inventer une heure de modele
//     (#W12).
//   - Traduire « fort + orage » en 96/99 (« orage avec grele ») : MET Norway ne
//     dit RIEN de la grele. Tout orage devient donc 95. On perd l'intensite,
//     on n'invente pas la grele.

/// Les codes WMO que l'application sait NOMMER. Emettre autre chose afficherait
/// « Inconnu » : cette liste est donc un contrat, pas une documentation.
export const CODES_CONNUS_DE_LAPPLI = Object.freeze([
  0, 1, 2, 3, 45, 48, 51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 71, 73, 75, 77,
  80, 81, 82, 85, 86, 95, 96, 99,
]);

/// Ou va la neige fondue, faute de 68/69 dans la table de l'appli.
/// Le jour ou l'application apprend 68 et 69, ces trois valeurs changent et
/// RIEN D'AUTRE : c'est pour cela qu'elles sont nommees ici.
export const CODES_NEIGE_FONDUE = Object.freeze({ leger: 71, modere: 73, fort: 75 });

/// Table des bases de `symbol_code` (suffixes _day / _night / _polartwilight
/// retires) vers le code WMO.
///
/// Les doubles graphies `lightssleetshowersandthunder` et
/// `lightssnowshowersandthunder` (deux « s ») sont REELLES dans l'API de MET
/// Norway. Les deux orthographes sont acceptees : corriger la leur en silence
/// ferait tomber le symbole dans le defaut le jour ou ils la corrigent.
const TABLE = Object.freeze({
  clearsky: 0,
  fair: 1,
  partlycloudy: 2,
  cloudy: 3,
  fog: 45,

  lightrain: 61,
  rain: 63,
  heavyrain: 65,
  lightrainandthunder: 95,
  rainandthunder: 95,
  heavyrainandthunder: 95,

  lightrainshowers: 80,
  rainshowers: 81,
  heavyrainshowers: 82,
  lightrainshowersandthunder: 95,
  rainshowersandthunder: 95,
  heavyrainshowersandthunder: 95,

  lightsleet: CODES_NEIGE_FONDUE.leger,
  sleet: CODES_NEIGE_FONDUE.modere,
  heavysleet: CODES_NEIGE_FONDUE.fort,
  lightsleetandthunder: 95,
  sleetandthunder: 95,
  heavysleetandthunder: 95,

  lightsleetshowers: 85,
  sleetshowers: 85,
  heavysleetshowers: 86,
  lightssleetshowersandthunder: 95,
  lightsleetshowersandthunder: 95,
  sleetshowersandthunder: 95,
  heavysleetshowersandthunder: 95,

  lightsnow: 71,
  snow: 73,
  heavysnow: 75,
  lightsnowandthunder: 95,
  snowandthunder: 95,
  heavysnowandthunder: 95,

  lightsnowshowers: 85,
  snowshowers: 85,
  heavysnowshowers: 86,
  lightssnowshowersandthunder: 95,
  lightsnowshowersandthunder: 95,
  snowshowersandthunder: 95,
  heavysnowshowersandthunder: 95,
});

/// L'ORDRE DE GRAVITE, et il n'est PAS l'ordre des numeros WMO.
///
/// Le code journalier d'Open-Meteo est « le temps le plus significatif de la
/// journee » : le PIRE, pas la moyenne. Pour garder la meme semantique, il faut
/// pouvoir comparer deux codes — et 45 (brouillard) est numeriquement inferieur
/// a 61 (pluie) alors que 71 (neige) lui est superieur sans que les numeros
/// disent quoi que ce soit d'utile.
///
/// L'ordre retenu est celui d'un RANDONNEUR EN MONTAGNE, et c'est un jugement
/// que j'assume plutot que de le cacher dans un `Math.max` sur des numeros :
/// un ciel voile est moins grave qu'un brouillard, un brouillard moins grave
/// qu'une pluie, la neige plus grave qu'une pluie de meme intensite, le verglas
/// au-dessus, l'orage au sommet.
const GRAVITE = Object.freeze({
  0: 0, 1: 1, 2: 2, 3: 3,
  45: 10, 48: 11,
  51: 20, 53: 21, 55: 22,
  61: 30, 63: 31, 65: 32,
  80: 33, 81: 34, 82: 35,
  71: 40, 73: 41, 75: 42, 77: 43,
  85: 44, 86: 45,
  56: 50, 57: 51, 66: 52, 67: 53,
  95: 60, 96: 61, 99: 62,
});

/// Retire le suffixe de luminosite d'un `symbol_code`.
///
/// MET Norway suffixe certains symboles (`clearsky_day`) et pas d'autres
/// (`cloudy`, `heavyrain`) — mesure du 28/09/2026 sur une reponse reelle. Les
/// deux formes doivent donc marcher.
export function baseDuSymbole(symbolCode) {
  if (typeof symbolCode !== 'string' || symbolCode.length === 0) return null;
  const base = symbolCode.trim().toLowerCase();
  for (const suffixe of ['_day', '_night', '_polartwilight']) {
    if (base.endsWith(suffixe)) return base.slice(0, -suffixe.length);
  }
  return base;
}

/// Traduit un `symbol_code` MET Norway en code WMO.
///
/// Rend `null` sur un symbole inconnu, JAMAIS une valeur par defaut. Un symbole
/// que MET Norway ajouterait demain deviendrait sinon silencieusement « ciel
/// degage », ce qui est exactement le « defaut vert » refuse en #I21 : un
/// mensonge confortable. Un `null` remonte comme un refus compte dans le
/// battement (#A5).
export function codeWmoDepuisSymbole(symbolCode) {
  const base = baseDuSymbole(symbolCode);
  if (base === null) return null;
  const code = TABLE[base];
  return code === undefined ? null : code;
}

/// Le pire de deux codes WMO au sens de GRAVITE (#A2 : une donnee de securite
/// s'arrondit vers le haut, jamais la moyenne).
export function pireCodeWmo(a, b) {
  if (a === null || a === undefined) return b ?? null;
  if (b === null || b === undefined) return a;
  const ga = GRAVITE[a];
  const gb = GRAVITE[b];
  if (ga === undefined) return b;
  if (gb === undefined) return a;
  return gb > ga ? b : a;
}

/// Le rang de gravite d'un code (pour les tests et le journal).
export function graviteDe(codeWmo) {
  const g = GRAVITE[codeWmo];
  return g === undefined ? null : g;
}

/// Tous les symboles connus — sert au test qui verifie qu'AUCUNE valeur de la
/// table ne sort du vocabulaire de l'application.
export function symbolesConnus() {
  return Object.keys(TABLE);
}

/// Tous les codes emis par la table — meme usage.
export function codesEmis() {
  return [...new Set(Object.values(TABLE))].sort((a, b) => a - b);
}
