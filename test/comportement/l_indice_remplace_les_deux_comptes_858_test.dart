// GARDE — TACHE 858 : IL NE RESTE QU'UN SEUL COMPTE DE DIFFICULTE, ET C'EST
// L'INDICE DE TERRAIN.
//
// CE QUE CETTE GARDE EMPECHE DE REVENIR. Trois comptes circulaient le
// 18/10/2026, et Christophe a tranche a 19:32 : on efface les deux anciens.
//
//   1. LE KILOMETRE-EFFORT (tache 852) — `km + D+/100 + 0,30 x D-/100`. Il
//      etait AFFICHE AUX CLIENTS, jusque dans le texte de vente des fiches, et
//      il etait faux : il cotait 26,5 la journee qui grimpe 1 454 m depuis
//      Calenzana et 21,4 la MEME journee marchee a l'envers, qui les descend.
//      Retire : code, donnee, outil de mesure, et citations dans les fiches.
//   2. LES POINTS DE LA TACHE 856 — ils valaient les minutes divisees par
//      13,64 dans chacune des six lignes de leur bareme, donc l'indice y etait
//      la duree deguisee. Ils n'avaient JAMAIS ete codes dans ce depot : leur
//      design vivait en base (#102238) et la verification est faite ici — la
//      chaine « 13,64 » n'existe nulle part dans le code.
//   3. L'INDICE DE TERRAIN (tache 857) — celui qui reste.
//
// ET LES BANDES DE NIVEAU PARTENT AVEC LE COMPTE QUI LES ALIMENTAIT. Les mots
// facile / moyen / difficile / tres difficile etaient produits par des seuils
// en kilometres-effort. Christophe tranchera les niveaux de l'indice plus tard
// (« On tranchera les niveaux apres », 18/10 19:32) : d'ici la l'indice sort en
// NOMBRE, et aucun seuil n'est invente.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

/// VRAI quand cette ligne est un commentaire : une garde qui lit les
/// commentaires s'eteint en PARLANT du symbole qu'elle surveille — defaut
/// connu du depot (`aucun_code_mort_645_test`, qui cherche hors commentaires
/// pour cette raison exacte). Ce fichier NOMME le kilometre-effort pour
/// expliquer pourquoi il est retire : il ne doit pas se declencher sur
/// lui-meme.
bool estUnCommentaire(String ligne) {
  final nue = ligne.trimLeft();
  return nue.startsWith('//') || nue.startsWith('*');
}

/// Le CODE d'un fichier : ses lignes, commentaires retires.
String codeDe(File fichier) => fichier
    .readAsLinesSync()
    .where((ligne) => !estUnCommentaire(ligne))
    .join(' ');

/// Les fichiers Dart de `lib/`, sans le code genere.
List<File> sourcesDeLib() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .where(
      (f) =>
          !f.path.endsWith('.g.dart') &&
          !f.path.endsWith('.freezed.dart') &&
          !f.path.contains('i18n'),
    )
    .toList(growable: false);

/// Le profil et les nuits du GR20, tels qu'embarques.
ProfilDuTerrain profilDuGr20() {
  final points = GpxDepuisLesAssets.parseFromString(
    File('assets/data/gr20/track.gpx').readAsStringSync(),
  );
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

DecoupageDeNuits nuitsDuGr20() => DecoupageDeNuits.fromJson(
  jsonDecode(File('assets/data/gr20/nuits_possibles.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// L'EFFORT D'UN GROUPE DE SEGMENTS — la charge que le repartiteur egalise
/// depuis la tache 860 (« Oui a l'effort pas au temps »).
double Function(int, int) effortDuGroupe(
  DecoupageDeNuits nuits,
  ProfilDuTerrain profil,
) {
  final pkParNom = <String, double>{
    for (final nuit in nuits.nuits) nuit.nom: nuit.pkKm,
  };
  double pkDeFin(int segment) =>
      pkParNom[nuits.segments[segment].arrivee] ?? 0.0;
  return (debut, fin) {
    final pkDebut = debut == 0 ? 0.0 : pkDeFin(debut - 1);
    final pkFin = pkDeFin(fin - 1);
    if (pkFin <= pkDebut) return 0.0;
    return IndiceDuTerrain.calculer(
      terrain: profil.tranche(
        pkDebutM: pkDebut * 1000.0,
        pkFinM: pkFin * 1000.0,
      ),
    ).indice;
  };
}

/// Les journees d'une allure, avec leurs bornes — comme la fiche les pose.
List<JourneeAPeser> journeesDe(
  DecoupageDeNuits nuits,
  ProfilDuTerrain profil,
  int jours,
) {
  final journees = <JourneeAPeser>[];
  var pk = 0.0;
  var depart = nuits.teteDeSentier;
  for (final j in DecoupageSurLesNuits.repartir(
    nuits,
    jours,
    effortDuGroupe: effortDuGroupe(nuits, profil),
  )) {
    final pkFin = j.arrivee?.pkKm ?? pk;
    journees.add(
      JourneeAPeser(
        depart: depart,
        arrivee: j.arriveeNom,
        km: j.km,
        deniveleM: j.deniveleM,
        descenteM: j.descenteM,
        minutes: j.minutes,
        pkDebutKm: pk,
        pkFinKm: pkFin,
      ),
    );
    pk = pkFin;
    depart = j.arriveeNom;
  }
  return journees;
}

void main() {
  group('858 — les deux anciens comptes ont disparu du code', () {
    test('AUCUN FICHIER DE lib/ NE PORTE PLUS LE KILOMETRE-EFFORT NI SON '
        'ECHELLE', () {
      final interdits = <String>[
        'kmEffort',
        'km-effort',
        'SeuilsDeDifficulte',
        'NiveauDeDifficulte',
        'DifficulteDuSentier',
        'effortDeLaJournee',
        'metresDeMonteeParKmEffort',
      ];
      final fautes = <String>[];
      for (final fichier in sourcesDeLib()) {
        final texte = codeDe(fichier);
        for (final interdit in interdits) {
          if (texte.contains(interdit)) {
            fautes.add('${fichier.path} : $interdit');
          }
        }
      }
      expect(
        fautes,
        isEmpty,
        reason:
            'le compte de la tache 852 doit rester retire — il etait faux et '
            'il etait affiche aux clients :\n${fautes.join('\n')}',
      );
    });

    test('LE COMPTE DE LA TACHE 856 N A JAMAIS EXISTE ICI, ET N Y ENTRE PAS : '
        'aucun facteur 13,64 entre un indice et des minutes', () {
      // SON DEFAUT, CHIFFRE : ses points valaient les minutes divisees par
      // 13,64 dans chacune des six lignes de son bareme (ecart-type 0,02
      // minute). Un indice qui est la duree a un facteur pres n'est pas un
      // indice.
      final fautes = <String>[];
      for (final fichier in sourcesDeLib()) {
        final texte = codeDe(fichier);
        if (texte.contains('13.64') || texte.contains('13,64')) {
          fautes.add(fichier.path);
        }
      }
      expect(fautes, isEmpty, reason: fautes.join('\n'));
    });

    test('L INDICE N EST PAS LA DUREE, ET LE GR20 LE PROUVE : deux journees '
        'de meme duree n ont pas le meme indice', () {
      // LA PREUVE SE LIT SUR LE SENTIER REEL. Si l'indice etait la duree a un
      // facteur pres, le rapport indice/heure serait constant. Il va de 2,2 a
      // 8,0 sur les journees du GR20 : un rapport de pres de QUATRE.
      final profil = profilDuGr20();
      final nuits = nuitsDuGr20();
      final pese = SentierPese.peser(
        jours: 16,
        profil: profil,
        journees: journeesDe(nuits, profil, 16),
      )!;
      final parHeure = pese.journees
          .where((j) => j.minutes > 0)
          .map((j) => j.indiceDuTerrain / (j.minutes / 60.0))
          .toList(growable: false);
      final minimum = parHeure.reduce((a, b) => a < b ? a : b);
      final maximum = parHeure.reduce((a, b) => a > b ? a : b);
      expect(
        maximum / minimum,
        greaterThan(1.9),
        reason:
            'indice par heure de $minimum a $maximum : s il etait constant, '
            'l indice serait la duree deguisee. Le rapport mesure vaut 1,97 a '
            'l exposant 1,08 contre 2,4 a 1,25 : une courbe moins raide '
            'rapproche l indice de la duree, et c est le prix de la '
            'fondation publiee',
      );
    });
  });

  group('858 — ce que l indice garde de l ancien socle', () {
    test('LE REPARTITEUR REND TOUJOURS LE NOMBRE DE JOURS DEMANDE, DE 7 A '
        '31', () {
      // LA GARDE DE LA TACHE 848, REPRISE TELLE QUELLE : le repartiteur
      // rendait six journees pour sept jours demandes (mesure #102125). Le
      // compte est compte, pas suppose — et il reste juste meme quand l indice
      // ne peut pas etre calcule.
      final nuits = nuitsDuGr20();
      final profil = profilDuGr20();
      for (var jours = 7; jours <= 31; jours++) {
        final pese = SentierPese.peser(
          jours: jours,
          profil: profil,
          journees: journeesDe(nuits, profil, jours),
        )!;
        expect(
          pese.journeesDeMarche,
          jours,
          reason: 'a $jours jours demandes, le decoupage en pose autant',
        );
        expect(pese.joursChoisis, jours);
        expect(pese.mesuresManquantes, isEmpty);
      }
    });

    test('LA PIRE JOURNEE EST CHOISIE PAR L INDICE, ET A DENIVELE EGAL CE '
        'N EST PAS LA PLUS LONGUE', () {
      // CE QUE LE NOUVEAU COMPTE CHANGE AU CLASSEMENT. Deux journees de MEME
      // LONGUEUR (8 km) montent exactement le MEME denivele (1 000 m) et ont
      // la meme part de plat (3 km). La premiere monte D'UN SEUL TENANT ; la
      // seconde monte en QUATRE fois, avec 1 100 m de plat entre chaque bosse —
      // assez de repit pour couper la montee. Tout est egal sauf la STRUCTURE,
      // et c'est la premiere qui est la plus dure. Le kilometre-effort, qui ne
      // lisait que les totaux, les cotait IDENTIQUES.
      final profil = ProfilDuTerrain(<SegmentDeProfil>[
        const SegmentDeProfil(pkDebutM: 0, longueurM: 5000, deniveleM: 1000),
        const SegmentDeProfil(pkDebutM: 5000, longueurM: 3300, deniveleM: 0),
        for (var i = 0; i < 4; i++) ...<SegmentDeProfil>[
          SegmentDeProfil(
            pkDebutM: 8300 + i * 2350,
            longueurM: 1250,
            deniveleM: 250,
          ),
          SegmentDeProfil(
            pkDebutM: 9550 + i * 2350,
            longueurM: 1100,
            deniveleM: 0,
          ),
        ],
      ]);
      final pese = SentierPese.peser(
        jours: 2,
        profil: profil,
        journees: <JourneeAPeser>[
          const JourneeAPeser(
            depart: 'depart',
            arrivee: 'la montee d un trait',
            km: 8.3,
            deniveleM: 1000,
            descenteM: 0,
            minutes: 345,
            pkDebutKm: 0,
            pkFinKm: 8.3,
          ),
          const JourneeAPeser(
            depart: 'la montee d un trait',
            arrivee: 'les quatre bosses',
            km: 8.3,
            deniveleM: 1000,
            descenteM: 0,
            minutes: 345,
            pkDebutKm: 8.3,
            pkFinKm: 16.6,
          ),
        ],
      )!;
      expect(pese.journees, hasLength(2));
      final dUnTrait = pese.journees.first;
      final enQuatre = pese.journees.last;
      expect(dUnTrait.terrain.monteesContinues, 1);
      expect(dUnTrait.terrain.plusGrosseMonteeM, closeTo(1000, 1));
      expect(enQuatre.terrain.monteesContinues, 4);
      expect(enQuatre.terrain.plusGrosseMonteeM, closeTo(250, 1));
      expect(
        enQuatre.terrain.deniveleM,
        closeTo(dUnTrait.terrain.deniveleM, 1),
        reason: 'les deux journees montent le meme denivele',
      );
      expect(
        enQuatre.km,
        closeTo(dUnTrait.km, 0.01),
        reason: 'et les deux journees font la meme longueur',
      );
      expect(
        pese.pireJournee!.arrivee,
        'la montee d un trait',
        reason:
            'a longueur egale et denivele egal, c est la premiere qui est la '
            'plus dure : mille metres d un seul tenant ne se marchent pas '
            'comme quatre fois deux cent cinquante',
      );
    });

    test('SANS BORNES SUR LA TRACE, L INDICE EST ANNONCE MANQUANT ET LE '
        'COMPTE RESTE JUSTE', () {
      final pese = SentierPese.peser(
        jours: 3,
        profil: profilDuGr20(),
        journees: <JourneeAPeser>[
          for (var i = 0; i < 3; i++)
            const JourneeAPeser(
              depart: '',
              arrivee: '',
              km: 10,
              deniveleM: 500,
              descenteM: 500,
              minutes: 300,
              pkDebutKm: 0,
              pkFinKm: 0,
            ),
        ],
      )!;
      expect(pese.journeesDeMarche, 3);
      expect(pese.journees, isEmpty);
      expect(pese.pireJournee, isNull);
      expect(
        pese.mesuresManquantes,
        contains('les points kilometriques des journees'),
      );
    });

    test('UN SENTIER QU ON NE MARCHE PAS N A PAS D INDICE', () {
      expect(
        SentierPese.peser(
          jours: 0,
          profil: profilDuGr20(),
          journees: const <JourneeAPeser>[],
        ),
        isNull,
      );
    });
  });
}
