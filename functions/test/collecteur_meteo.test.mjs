// LA METEO : traduction du symbole et agregation horaire -> journalier. Tache 624.
//
// Execution : cd functions && node --test
//
// Le fixture `met_norway_reel.json` est une REPONSE REELLE de
// api.met.no/weatherapi/locationforecast/2.0/complete, relevee le 28/09/2026 a
// 21:36 UTC pour lat 42.30 lon 9.15 (Corse). Les champs d'instant inutiles au
// collecteur ont ete retires, rien n'a ete invente. Tester contre une reponse
// reelle attrape ce qu'un double ne montre jamais : ici, le CHEVAUCHEMENT des
// fenetres de six heures avec les fenetres horaires.

import assert from 'node:assert/strict';
import { describe, it } from 'node:test';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  CODES_CONNUS_DE_LAPPLI,
  CODES_NEIGE_FONDUE,
  baseDuSymbole,
  codeWmoDepuisSymbole,
  codesEmis,
  graviteDe,
  pireCodeWmo,
  symbolesConnus,
} from '../collecteur/wmo.js';

import {
  BORNES,
  HEURES_MINIMUM_PAR_JOUR,
  JOURS_MINIMUM,
  JOURS_PORTEE_DEFAUT,
  PROBABILITE_ABSENTE,
  REFUS,
  UNITES_EXIGEES,
  agregerMetNorway,
} from '../collecteur/meteo_agregat.js';

const ICI = dirname(fileURLToPath(import.meta.url));
const REEL = JSON.parse(readFileSync(join(ICI, 'fixtures', 'met_norway_reel.json'), 'utf8'));
/// L'instant de la mesure : le premier point du fixture. Le passage est ainsi
/// deterministe, sans horloge.
const MAINTENANT = Date.parse('2026-09-28T21:36:20Z');

function copieProfonde(o) { return JSON.parse(JSON.stringify(o)); }

describe('wmo — le vocabulaire de l application est un CONTRAT', () => {
  it('AUCUN code emis ne sort du vocabulaire que l appli sait nommer', () => {
    // La table `_wmoCodeDescriptions` de weather_forecast.dart rend « Inconnu »
    // pour tout code absent. Emettre 68/69 (« pluie et neige melees », les codes
    // WMO exacts de la neige fondue) afficherait donc « Inconnu » au randonneur.
    // C'est la contrainte qui a decide de toute la table.
    for (const code of codesEmis()) {
      assert.ok(
        CODES_CONNUS_DE_LAPPLI.includes(code),
        `le code ${code} n est pas dans la table de libelles de l application`,
      );
    }
  });

  it('la neige fondue est rangee avec la NEIGE, jamais avec la pluie verglacante', () => {
    // Choix NOMME : 66/67 (« pluie verglacante ») decrit un autre phenomene, plus
    // dangereux. Annoncer un danger qu'on n'a pas mesure est la meme faute
    // qu'inventer une heure de modele.
    assert.equal(codeWmoDepuisSymbole('lightsleet'), CODES_NEIGE_FONDUE.leger);
    assert.equal(codeWmoDepuisSymbole('sleet'), CODES_NEIGE_FONDUE.modere);
    assert.equal(codeWmoDepuisSymbole('heavysleet'), CODES_NEIGE_FONDUE.fort);
    for (const symbole of ['lightsleet', 'sleet', 'heavysleet']) {
      assert.ok(![66, 67].includes(codeWmoDepuisSymbole(symbole)));
    }
  });

  it('tout orage devient 95 : on ne fabrique PAS de grele', () => {
    // 96 et 99 disent « orage avec grele ». MET Norway ne dit rien de la grele :
    // on perd l intensite, on n invente pas le phenomene.
    for (const symbole of symbolesConnus().filter((s) => s.includes('thunder'))) {
      assert.equal(codeWmoDepuisSymbole(symbole), 95, symbole);
    }
    assert.ok(!codesEmis().includes(96));
    assert.ok(!codesEmis().includes(99));
  });

  it('accepte les DEUX orthographes de MET Norway, y compris leur double s', () => {
    // `lightssleetshowersandthunder` et `lightssnowshowersandthunder` sont REELS
    // dans leur API. Corriger leur faute en silence ferait tomber le symbole dans
    // le defaut le jour ou ils la corrigent.
    assert.equal(codeWmoDepuisSymbole('lightssleetshowersandthunder'), 95);
    assert.equal(codeWmoDepuisSymbole('lightsleetshowersandthunder'), 95);
    assert.equal(codeWmoDepuisSymbole('lightssnowshowersandthunder'), 95);
    assert.equal(codeWmoDepuisSymbole('lightsnowshowersandthunder'), 95);
  });

  it('retire les suffixes de luminosite, et accepte leur absence', () => {
    assert.equal(baseDuSymbole('clearsky_day'), 'clearsky');
    assert.equal(baseDuSymbole('partlycloudy_night'), 'partlycloudy');
    assert.equal(baseDuSymbole('fair_polartwilight'), 'fair');
    assert.equal(baseDuSymbole('cloudy'), 'cloudy');
    assert.equal(codeWmoDepuisSymbole('clearsky_day'), 0);
    assert.equal(codeWmoDepuisSymbole('cloudy'), 3);
  });

  it('un symbole INCONNU rend null, jamais « ciel degage »', () => {
    // #I21 : « pas de defaut vert : un defaut vert est un mensonge confortable ».
    // Un symbole que MET Norway ajouterait demain deviendrait sinon silencieusement
    // beau temps.
    assert.equal(codeWmoDepuisSymbole('supercellule_de_mars'), null);
    assert.equal(codeWmoDepuisSymbole(''), null);
    assert.equal(codeWmoDepuisSymbole(null), null);
    assert.equal(codeWmoDepuisSymbole(42), null);
  });

  it('le PIRE temps de la journee, jamais la moyenne (#A2)', () => {
    assert.equal(pireCodeWmo(0, 95), 95);
    assert.equal(pireCodeWmo(95, 0), 95);
    // Et l ordre n est PAS celui des numeros : 45 (brouillard) est numeriquement
    // inferieur a 3 (couvert) est superieur... bref, il fallait une table.
    assert.equal(pireCodeWmo(3, 45), 45);
    assert.equal(pireCodeWmo(65, 71), 71, 'la neige passe devant la pluie forte en montagne');
    assert.equal(pireCodeWmo(75, 67), 67, 'le verglas passe devant la neige forte');
    assert.equal(pireCodeWmo(null, 61), 61);
    assert.equal(pireCodeWmo(61, null), 61);
    assert.ok(graviteDe(95) > graviteDe(67));
  });
});

describe('agregation — contre une reponse MET Norway REELLE', () => {
  it('lit l heure du MODELE, et c est ce que l ecran affichera', () => {
    // #W2/#W11 : `meta.updated_at` est la seule date qui dise quand le monde a ete
    // regarde. C'est la SEULE raison pour laquelle MET Norway a ete retenu contre
    // Open-Meteo, qui ne la donne pas.
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    assert.ok(r.ok, JSON.stringify(r));
    assert.equal(r.bulletin.produiteLeMs, Date.parse('2026-09-28T19:17:44Z'));
    assert.equal(r.bulletin.source, 'met-norway');
  });

  it('rend au plus cinq jours, consecutifs et croissants', () => {
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    assert.ok(r.bulletin.jours.length >= JOURS_MINIMUM);
    assert.ok(r.bulletin.jours.length <= JOURS_PORTEE_DEFAUT);
    const jours = r.bulletin.jours.map((j) => j.jour);
    assert.deepEqual(jours, [...jours].sort());
    assert.equal(new Set(jours).size, jours.length);
  });

  it('LE VENT EST CONVERTI EN KM/H — sans quoi l alerte vent ne partirait jamais', () => {
    // MET Norway rend des m/s (`meta.units.wind_speed = 'm/s'`), l application
    // compare a `windSpeedKmh >= 60`. Sans le facteur 3,6, une tempete a 20 m/s
    // (72 km/h) serait lue comme 20 km/h et n alerterait personne.
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    const ventMaxBrut = Math.max(
      ...REEL.properties.timeseries.map((p) => p.data.instant.details.wind_speed ?? 0),
    );
    const ventMaxRendu = Math.max(...r.bulletin.jours.map((j) => j.windSpeedKmh));
    assert.ok(ventMaxRendu > ventMaxBrut * 3, 'le vent rendu doit etre en km/h, pas en m/s');
    assert.ok(ventMaxRendu <= ventMaxBrut * 3.6 + 0.2);
  });

  it('NE COMPTE PAS LA PLUIE DEUX FOIS — le piege principal de cette source', () => {
    // 84 points portent un `next_6_hours` qui CHEVAUCHE les 63 `next_1_hours`.
    // Additionner les deux doublerait la pluie, et rien ne le signalerait :
    // l ecran afficherait simplement deux fois trop d eau.
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    const totalRendu = r.bulletin.jours.reduce((s, j) => s + j.precipitationMm, 0);

    // Somme NAIVE : tout `next_1_hours` plus tout `next_6_hours`. C'est ce qu'un
    // code sans curseur produirait.
    let naive = 0;
    for (const p of REEL.properties.timeseries) {
      naive += p.data.next_1_hours?.details?.precipitation_amount ?? 0;
      naive += p.data.next_6_hours?.details?.precipitation_amount ?? 0;
    }
    assert.ok(naive > 0, 'le fixture doit contenir de la pluie pour que ce test prouve quelque chose');
    assert.ok(
      totalRendu < naive,
      `agregat ${totalRendu} mm doit etre INFERIEUR a la somme naive ${naive} mm`,
    );
  });

  it('chaque jour retenu porte au moins six heures de couverture', () => {
    // Le jour courant est tronque par construction : a 23:36 locale il ne reste
    // qu une heure. En tirer un « maximum du jour » serait une assertion FAUSSE.
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    for (const j of r.bulletin.jours) {
      assert.ok(j.heuresCouvertes >= HEURES_MINIMUM_PAR_JOUR, `${j.jour} -> ${j.heuresCouvertes} h`);
      assert.equal(typeof j.complet, 'boolean');
    }
    // Le 28/09 local n'a qu une heure de prevision a partir de 21:00 UTC : il ne
    // doit PAS etre rendu.
    assert.ok(!r.bulletin.jours.some((j) => j.jour === '2026-09-28'));
  });

  it('la probabilite de precipitation est ABSENTE, explicitement', () => {
    // MET Norway ne fournit pas `probability_of_precipitation` (mesure : aucune
    // occurrence dans la reponse). L inventer serait annoncer une garantie qu on
    // n a pas. C est une PERTE FONCTIONNELLE par rapport a Open-Meteo, nommee.
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    for (const j of r.bulletin.jours) {
      assert.equal(j.precipitationProbabilityMax, PROBABILITE_ABSENTE);
      assert.equal(j.precipitationProbabilityMax, null);
    }
  });

  it('l UV est nomme CIEL CLAIR, parce que c est ce que la source donne', () => {
    const r = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    for (const j of r.bulletin.jours) {
      assert.ok('uvIndexMaxCielClair' in j);
      assert.ok(!('uvIndex' in j), 'ne pas laisser croire a un UV reel sous nuages');
    }
  });

  it('le FUSEAU est ecrit dans le bulletin, jamais implicite', () => {
    // MET Norway ne resout pas le fuseau depuis les coordonnees, contrairement au
    // `timezone=auto` d Open-Meteo. C est donc une decision du collecteur, et une
    // decision se trace.
    const paris = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    const utc = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Etc/UTC' });
    assert.equal(paris.bulletin.fuseau, 'Europe/Paris');
    assert.equal(utc.bulletin.fuseau, 'Etc/UTC');
  });

  it('LE FUSEAU DEPLACE REELLEMENT LA PLUIE D UN JOUR A L AUTRE', () => {
    // Prouve par une serie CONSTRUITE plutot qu'en esperant que la reponse reelle
    // expose le cas : la pluie est posee a 22:00 UTC, c'est-a-dire minuit a Paris.
    // En UTC elle tombe le 29 ; a Paris elle tombe le 30. Un decoupage UTC
    // attribuerait donc l'averse a la mauvaise journee, et l'erreur ne porterait
    // que sur deux heures — donc elle passerait tous les tests ecrits a midi.
    const serie = [];
    const depart = Date.parse('2026-09-29T06:00:00Z');
    for (let h = 0; h < 72; h += 1) {
      const t = depart + h * 3600e3;
      const pluie = new Date(t).toISOString() === '2026-09-29T22:00:00.000Z' ? 9 : 0;
      serie.push({
        time: new Date(t).toISOString(),
        data: {
          instant: { details: { air_temperature: 15, wind_speed: 2, ultraviolet_index_clear_sky: 1 } },
          next_1_hours: { summary: { symbol_code: 'clearsky_day' }, details: { precipitation_amount: pluie } },
        },
      });
    }
    const reponse = {
      properties: {
        meta: { updated_at: '2026-09-29T05:00:00Z', units: { ...UNITES_EXIGEES } },
        timeseries: serie,
      },
    };
    const maintenant = Date.parse('2026-09-29T06:00:00Z');

    const utc = agregerMetNorway(reponse, { maintenantMs: maintenant, fuseau: 'Etc/UTC' });
    const paris = agregerMetNorway(reponse, { maintenantMs: maintenant, fuseau: 'Europe/Paris' });
    assert.ok(utc.ok && paris.ok, JSON.stringify({ utc, paris }));

    const jourPluieUtc = utc.bulletin.jours.find((j) => j.precipitationMm > 0).jour;
    const jourPluieParis = paris.bulletin.jours.find((j) => j.precipitationMm > 0).jour;
    assert.equal(jourPluieUtc, '2026-09-29');
    assert.equal(jourPluieParis, '2026-09-30');
  });

  it('honore la portee demandee, entre trois et cinq jours', () => {
    const trois = agregerMetNorway(REEL, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris', joursPortee: 3 });
    assert.equal(trois.bulletin.jours.length, 3);
    assert.equal(trois.bulletin.joursPortee, 3);
  });
});

describe('les refus — une valeur illisible ne devient pas une valeur acceptee (#A5)', () => {
  it('REFUSE une derive d unite, au lieu de rendre des chiffres faux', () => {
    // C est le refus le plus important du fichier. Si MET Norway passait un jour le
    // vent en km/h, un collecteur qui multiplie par 3,6 rendrait 216 km/h pour
    // 60 km/h — et rien ne casserait. La derive d unite est silencieuse.
    const abime = copieProfonde(REEL);
    abime.properties.meta.units.wind_speed = 'km/h';
    const r = agregerMetNorway(abime, { maintenantMs: MAINTENANT });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS.unites);
    assert.match(r.detail, /wind_speed/);
  });

  it('exige toutes les unites qu il utilise', () => {
    for (const champ of Object.keys(UNITES_EXIGEES)) {
      const abime = copieProfonde(REEL);
      delete abime.properties.meta.units[champ];
      const r = agregerMetNorway(abime, { maintenantMs: MAINTENANT });
      assert.equal(r.ok, false, champ);
      assert.equal(r.raison, REFUS.unites);
    }
  });

  it('refuse une heure de modele DANS LE FUTUR ou trop vieille', () => {
    const futur = copieProfonde(REEL);
    futur.properties.meta.updated_at = '2027-01-01T00:00:00Z';
    assert.equal(agregerMetNorway(futur, { maintenantMs: MAINTENANT }).raison, REFUS.modeleInvraisemblable);

    const vieux = copieProfonde(REEL);
    vieux.properties.meta.updated_at = '2026-09-01T00:00:00Z';
    assert.equal(agregerMetNorway(vieux, { maintenantMs: MAINTENANT }).raison, REFUS.modeleInvraisemblable);

    const illisible = copieProfonde(REEL);
    illisible.properties.meta.updated_at = 'hier matin';
    assert.equal(agregerMetNorway(illisible, { maintenantMs: MAINTENANT }).raison, REFUS.modeleIllisible);
  });

  it('refuse une temperature hors du domaine du vivant', () => {
    const abime = copieProfonde(REEL);
    abime.properties.timeseries[10].data.instant.details.air_temperature = 80;
    const r = agregerMetNorway(abime, { maintenantMs: MAINTENANT });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS.valeurHorsDomaine);
    assert.ok(BORNES.temperatureMax < 80);
  });

  it('refuse un symbole inconnu plutot que de deviner le temps', () => {
    const abime = copieProfonde(REEL);
    abime.properties.timeseries[5].data.next_1_hours.summary.symbol_code = 'pluie_de_grenouilles';
    const r = agregerMetNorway(abime, { maintenantMs: MAINTENANT });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS.symboleInconnu);
  });

  it('refuse TOUT LE BULLETIN quand il reste moins de trois jours', () => {
    // « Une etape a une meteo COMPLETE ou n en a pas. » Deux jours exploitables ne
    // font pas un demi-bulletin qu on deposerait quand meme.
    const court = copieProfonde(REEL);
    court.properties.timeseries = court.properties.timeseries.slice(0, 20);
    const r = agregerMetNorway(court, { maintenantMs: MAINTENANT, fuseau: 'Europe/Paris' });
    assert.equal(r.ok, false);
    assert.equal(r.raison, REFUS.troisPeuDeJours);
  });

  it('refuse une charpente inattendue sans lever vers l appelant', () => {
    // Un refus est une ISSUE NORMALE, comptee dans le battement : il ne doit pas
    // faire tomber le passage des soixante-neuf autres etapes (#T2).
    for (const cas of [null, {}, { properties: {} }, { properties: { meta: { units: {} } } }]) {
      const r = agregerMetNorway(cas, { maintenantMs: MAINTENANT });
      assert.equal(r.ok, false);
      assert.ok(typeof r.raison === 'string');
    }
  });
});
