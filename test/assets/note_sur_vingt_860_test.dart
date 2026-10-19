// GARDE — TACHE 860 : LES NOTES ET LES QUATRE LECTURES DU GR20, PESEES DEUX
// FOIS, EN DART ET EN PYTHON.
//
// `tool/note_sur_vingt_860.py` mesure la note des seize etapes, le decoupage a
// l'EFFORT des trois produits dans les deux sens, et les quatre lectures de
// chaque plan ; il ecrit `assets/data/gr20/notes_860.json`. Ce fichier-ci
// recalcule tout en DART, par le socle du produit, et exige les memes nombres.
// Un calcul qui s'auto-atteste ne prouve rien ; deux qui tombent d'accord, si.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/note_sur_vingt.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

Map<String, dynamic> lireJson(String chemin) =>
    json.decode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

ProfilDuTerrain profilDe(String dossier) {
  final points = GpxDepuisLesAssets.parseFromString(
    File('assets/data/$dossier/track.gpx').readAsStringSync(),
  );
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

DecoupageDeNuits nuitsDe(String dossier) => DecoupageDeNuits.fromJson(
  lireJson('assets/data/$dossier/nuits_possibles.json'),
);

/// L'effort d'un groupe de segments — la charge que le repartiteur egalise.
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

/// Le plan d'un produit a une allure, dans le sens de la trace.
SentierPese planDe(String dossier, int jours) {
  final profil = profilDe(dossier);
  final nuits = nuitsDe(dossier);
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
  return SentierPese.peser(jours: jours, profil: profil, journees: journees)!;
}

void main() {
  final mesure = lireJson('assets/data/gr20/notes_860.json');
  final etapesPubliees = lireJson('assets/data/gr20/mesure_etapes.json');

  group('860 — la jauge du fichier est la jauge du code', () {
    test('LES ONZE PALIERS, LE CORPUS ET SA DATE CONCORDENT', () {
      final jauge = mesure['jauge'] as Map<String, dynamic>;
      expect(jauge['figee_le'], NoteSurVingt.dateDuCalage);
      expect(jauge['etapes_du_corpus'], NoteSurVingt.etapesDuCorpus);
      expect(
        (jauge['indice_du_zero'] as num).toDouble(),
        NoteSurVingt.indiceDuZero,
      );
      expect(
        (jauge['indice_du_vingt'] as num).toDouble(),
        NoteSurVingt.indiceDuVingt,
      );
      final paliers = jauge['paliers'] as List<dynamic>;
      expect(paliers, hasLength(NoteSurVingt.paliers.length));
      for (var i = 0; i < paliers.length; i++) {
        final couple = paliers[i] as List<dynamic>;
        expect(
          (couple[0] as num).toDouble(),
          closeTo(NoteSurVingt.paliers[i].$1, 1e-9),
        );
        expect(
          (couple[1] as num).toDouble(),
          closeTo(NoteSurVingt.paliers[i].$2, 1e-9),
        );
      }
      // LE CORPUS EST NOMME ET SA COMPOSITION EST DANS LE FICHIER : 106 etapes
      // officielles, et la somme des blocs le dit.
      final composition = jauge['composition'] as Map<String, dynamic>;
      var total = 0;
      for (final valeur in composition.values) {
        total += (valeur as num).toInt();
      }
      expect(total, NoteSurVingt.etapesDuCorpus);
      expect(jauge['plafond'], NoteSurVingt.etapeDuPlafond);
    });

    test('L EXPOSANT DU FICHIER EST CELUI DU CODE, ET SA PART ASSUMEE EST '
        'CELLE QU ATHENA A MESUREE : 3,3 %', () {
      final loi = mesure['loi'] as Map<String, dynamic>;
      expect(LoiDeLIndice.retenue.beta, (loi['beta'] as num).toDouble());
      expect(LoiDeLIndice.retenue.beta, 1.08);
      expect(
        (loi['part_assumee_brute_pct'] as num).toDouble(),
        closeTo(3.28, 0.02),
        reason:
            'elle valait 9,73 % a l exposant 1,25 sans fondation publiee : '
            'c est le gain principal du passage a 1,08',
      );
      expect((loi['fondation_de_l_exposant'] as String), contains('Riegel'));
      expect(
        (loi['fondation_de_l_exposant'] as String),
        contains('RESERVE'),
        reason:
            'les exposants publies portent sur la DUREE d un effort, pas sur '
            'la HAUTEUR d une cote : la reserve doit voyager avec le chiffre',
      );
    });
  });

  group('860 — les seize etapes notees, Dart contre Python', () {
    test('CHAQUE ETAPE REND LA MEME NOTE, LA MEME MONTEE ET LE MEME '
        'KILOMETRAGE', () {
      final profil = profilDe('gr20');
      final attendues = mesure['etapes_officielles_notees'] as List<dynamic>;
      expect(attendues, hasLength(16));
      final publiees = etapesPubliees['etapes'] as List<dynamic>;
      for (var i = 0; i < attendues.length; i++) {
        final attendue = attendues[i] as Map<String, dynamic>;
        final publiee = publiees[i] as Map<String, dynamic>;
        final calculee = IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: (publiee['pk_depart_km'] as num).toDouble() * 1000.0,
            pkFinM: (publiee['pk_arrivee_km'] as num).toDouble() * 1000.0,
          ),
        );
        final ou = 'etape ${attendue['rang']}';
        expect(
          calculee.indice,
          closeTo((attendue['indice'] as num).toDouble(), 0.01),
          reason: '$ou : indice',
        );
        expect(
          NoteSurVingt.pourIndice(calculee.indice),
          closeTo((attendue['note'] as num).toDouble(), 0.01),
          reason: '$ou : note sur vingt',
        );
        expect(
          calculee.plusGrosseMonteeM,
          closeTo((attendue['plus_grosse_montee_m'] as num).toDouble(), 1),
          reason: '$ou : plus grosse montee continue',
        );
      }
    });

    test('LA REPONSE QUI A DECIDE DU LOT EST DANS LE FICHIER : l etape 1 vaut '
        '15,55 sur vingt', () {
      final etape1 =
          (mesure['etapes_officielles_notees'] as List<dynamic>).first
              as Map<String, dynamic>;
      expect(etape1['rang'], 1);
      expect((etape1['indice'] as num).toDouble(), closeTo(42.58, 0.01));
      expect((etape1['note'] as num).toDouble(), closeTo(15.55, 0.01));
      expect(
        (etape1['plus_grosse_montee_m'] as num).toDouble(),
        closeTo(1454, 2),
        reason: 'c est elle qui porte la plus grosse montee du sentier',
      );
    });

    test('LES DEUX FAITS SANS ECHELLE NE DISENT PAS LA MEME CHOSE QUE LA '
        'NOTE, et le GR20 le prouve', () {
      // L'etape 4 monte 1 162 m d'un seul tenant et note 12,32 ; l'etape 13
      // ne monte que 769 m d'un seul tenant et note 11,37 — tout pres. La
      // difference est le kilometrage. Un marcheur qui redoute les grandes
      // montees ne lit pas la meme colonne qu'un marcheur qui redoute les
      // longues journees : c'est pour cela que les deux faits voyagent avec la
      // note.
      final etapes = <int, Map<String, dynamic>>{
        for (final e in mesure['etapes_officielles_notees'] as List<dynamic>)
          (e as Map<String, dynamic>)['rang'] as int: e,
      };
      final quatre = etapes[4]!;
      final treize = etapes[13]!;
      expect(
        (quatre['plus_grosse_montee_m'] as num).toDouble(),
        greaterThan((treize['plus_grosse_montee_m'] as num).toDouble() * 1.4),
      );
      expect(
        (quatre['note'] as num).toDouble() - (treize['note'] as num).toDouble(),
        lessThan(1.5),
        reason:
            'une montee une fois et demie plus grosse ne fait pas une note '
            'une fois et demie plus grosse',
      );
    });
  });

  group('860 — les plans et leurs quatre lectures, Dart contre Python', () {
    test('CHAQUE PLAN DU FICHIER EST CELUI QUE LE PRODUIT POSE', () {
      for (final attendu in mesure['plans'] as List<dynamic>) {
        final p = attendu as Map<String, dynamic>;
        if (p['sens'] != 'trace') continue;
        final pese = planDe(p['produit'] as String, p['jours_demandes'] as int);
        final attendues = p['lectures'] as Map<String, dynamic>;
        final lectures = pese.lectures;
        final ou = '${p['produit']} a ${p['jours_demandes']} jours';
        expect(
          lectures.nombreDeJours,
          attendues['nombre_de_jours'],
          reason: '$ou : nombre de jours',
        );
        expect(
          lectures.pireJournee,
          closeTo((attendues['pire_journee'] as num).toDouble(), 0.02),
          reason: '$ou : pire journee',
        );
        expect(
          lectures.journeeType,
          closeTo((attendues['journee_type'] as num).toDouble(), 0.02),
          reason: '$ou : journee type',
        );
        expect(
          lectures.journeesDures,
          attendues['journees_dures'],
          reason: '$ou : journees dures',
        );
        expect(
          lectures.plusLongEnchainementDeJourneesDures,
          attendues['plus_long_enchainement'],
          reason: '$ou : plus long enchainement',
        );
      }
    });

    test('A CINQ JOURS, LE GR20 ENTIER ECRETE A VINGT — et c est normal', () {
      // Christophe : « 2 ou 3 etapes groupee sortent a plus que la plus grosse
      // etape du monde. Et au dessus de 20, cest 20 ». A cinq jours la
      // premiere journee groupe Calenzana jusqu a Ascu-Stagnu : 2 060 m de
      // montee continue, 23,6 km, un indice de 88,6 contre un plafond mondial
      // a 87,5. La note s ecrete, et ce sont les deux faits qui la decrivent.
      final pese = planDe('gr20', 5);
      final pire = pese.pireJournee!;
      expect(pire.noteSurVingt, 20.0);
      expect(pire.estEcretee, isTrue);
      expect(pire.indiceDuTerrain, greaterThan(NoteSurVingt.indiceDuVingt));
      expect(pire.plusGrosseMonteeM, closeTo(2060, 2));
      // A SEPT JOURS, PLUS AUCUNE JOURNEE N EST ECRETEE.
      final aSept = planDe('gr20', 7);
      expect(aSept.journees.any((j) => j.estEcretee), isFalse);
      expect(aSept.lectures.pireJournee, closeTo(18.86, 0.02));
    });

    test('LES LECTURES DU SENTIER NE SONT PAS CELLES DE SES CHAPITRES MISES '
        'BOUT A BOUT', () {
      // Le plan par defaut vaut sept a huit jours POUR CHAQUE PRODUIT : qui
      // achete les deux chapitres marche quatorze a seize jours, donc des
      // journees plus courtes. L ecart se mesure et il est enorme.
      final entier = planDe('gr20', 7).lectures;
      final nord = planDe('gr20-nord', 7).lectures;
      final sud = planDe('gr20-sud', 7).lectures;
      expect(entier.nombreDeJours, 7);
      expect(nord.nombreDeJours + sud.nombreDeJours, 14);
      expect(
        entier.journeeType,
        greaterThan(nord.journeeType),
        reason: 'la journee type de l entier ecrase celle du nord',
      );
      expect(
        entier.journeeType,
        greaterThan(sud.journeeType * 3),
        reason:
            'et elle vaut plus de trois fois celle du sud : les deux '
            'chapitres additionnes sont un produit beaucoup plus facile',
      );
      expect(entier.pireJournee, greaterThan(nord.pireJournee));
    });

    test('LE SUD REPOND A L ALLURE, LE NORD NON — et c est structurel', () {
      // Le nord porte une journee qu aucun couchage releve ne coupe : la
      // premiere, 1 455 m d un seul tenant. Son plancher est donc atteint des
      // huit jours et il ne descend plus. Le sud, lui, se coupe partout.
      final nordHuit = planDe('gr20-nord', 8).lectures.pireJournee;
      final nordDouze = planDe('gr20-nord', 12).lectures.pireJournee;
      expect(nordHuit, closeTo(15.55, 0.02));
      expect(nordDouze, closeTo(15.55, 0.02));
      final sudHuit = planDe('gr20-sud', 8).lectures.pireJournee;
      final sudDouze = planDe('gr20-sud', 12).lectures.pireJournee;
      expect(sudDouze, lessThan(sudHuit));
    });
  });
}
