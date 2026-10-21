// LA DEMONSTRATION QUI JUSTIFIE TOUT LE LOT 861 — ET ELLE EST MESUREE SUR
// NOTRE PROPRE SENTIER, PAS SUR UN EXEMPLE CONSTRUIT.
//
// CE QU'ELLE MONTRE. Sur le GR20 entier marche en sept jours, decoupe a
// l'effort, LES JOURS 2 ET 7 ONT LE MEME EFFORT — 17,78 et 17,77 sur vingt,
// un centieme d'ecart — ET DES RAIDEURS DE 14,53 CONTRE 3,85. Dix points et
// demi d'ecart entre deux journees que n'importe quelle note unique aurait
// declarees identiques.
//
// CE QU'ELLES SONT VRAIMENT. Le jour 2 fait 13,3 km en montant 1 934 m, soit
// 145 m par kilometre : c'est un mur de bout en bout. Le jour 7 fait 39,9 km
// en montant 1 533 m, soit 38 m par kilometre : c'est une longue marche
// roulante. Elles coutent la meme energie et elles ne se ressemblent en rien.
// Un marcheur qui redoute les murs et un marcheur qui redoute les longues
// journees ne doivent PAS lire le meme nombre, et c'est exactement ce que la
// note unique leur imposait.
//
// POURQUOI CE TEST EXISTE PLUTOT QU'UN ARGUMENT. On a cherche pendant deux
// jours une formule unique qui separe ces deux journees. Le releve des
// methodes publiees du monde a montre que PERSONNE N'Y ARRIVE : MIDE quatre
// axes, FFRandonnee trois, Komoot deux, SAC et CAI cotent la technique
// separement de l'effort ; le seul chiffre unique qui internalise la
// concentration est l'IBP, et sa formule n'est pas publique. Ce fichier est la
// preuve chiffree qu'il ne fallait pas chercher, mais separer.
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
  group('861 — deux journees de meme effort ne se ressemblent pas', () {
    late List<JourneePesee> semaine;

    setUpAll(() {
      semaine = planDe('gr20', 7).journees;
    });

    test('LE PLAN A SEPT JOURS TIENT BIEN SEPT JOURNEES', () {
      expect(semaine, hasLength(7));
    });

    test('LES JOURS 2 ET 7 ONT LE MEME EFFORT — moins de cinq centiemes '
        'd ecart', () {
      final jour2 = semaine[1];
      final jour7 = semaine[6];
      expect(jour2.noteDEffort, closeTo(17.78, 0.05));
      expect(jour7.noteDEffort, closeTo(17.77, 0.05));
      expect(
        (jour2.noteDEffort - jour7.noteDEffort).abs(),
        lessThan(0.05),
        reason: 'une note unique les aurait declarees identiques',
      );
    });

    test('ET DIX POINTS DE RAIDEUR LES SEPARENT', () {
      final jour2 = semaine[1];
      final jour7 = semaine[6];
      expect(jour2.noteDeRaideur, closeTo(14.53, 0.05));
      expect(jour7.noteDeRaideur, closeTo(3.85, 0.05));
      expect(
        jour2.noteDeRaideur - jour7.noteDeRaideur,
        greaterThan(10.0),
        reason: 'C EST CA QU UNE NOTE UNIQUE NE POUVAIT PAS DIRE',
      );
    });

    test('LE CHIFFRE BRUT DIT LA MEME CHOSE EN METRES PAR KILOMETRE', () {
      // Le brut accompagne toujours la note : 145 m/km contre 38 m/km, soit
      // un mur contre une marche roulante.
      expect(semaine[1].metresParKmDeMontee, closeTo(145.3, 1.0));
      expect(semaine[6].metresParKmDeMontee, closeTo(38.5, 1.0));
    });

    test('LEUR GEOMETRIE EXPLIQUE L ECART : un mur de 13 km contre 40 km de '
        'marche roulante', () {
      final jour2 = semaine[1];
      final jour7 = semaine[6];
      expect(jour2.terrain.kmDeCarte, closeTo(13.31, 0.2));
      expect(jour2.terrain.deniveleM, closeTo(1934, 10));
      expect(jour7.terrain.kmDeCarte, closeTo(39.85, 0.2));
      expect(jour7.terrain.deniveleM, closeTo(1533, 10));
      // LE JOUR 7 EST TROIS FOIS PLUS LONG et monte MOINS : c'est bien la
      // meme energie repartie tout autrement.
      expect(
        jour7.terrain.kmDeCarte,
        greaterThan(jour2.terrain.kmDeCarte * 2.5),
      );
      expect(jour7.terrain.deniveleM, lessThan(jour2.terrain.deniveleM));
    });

    test('SUR LA SEMAINE ENTIERE, L AXE RAIDEUR PORTE SIX FOIS PLUS '
        'D ETENDUE QUE L AXE EFFORT', () {
      // LE VERDICT HONNETE DU LOT. L'axe effort reste TASSE — consequence
      // directe de garder le vingt sur la plus dure etape du monde — et c'est
      // precisement pourquoi un second axe etait necessaire plutot qu'une
      // correction du premier : une semaine lue sur le seul effort est une
      // semaine plate a l'ecran.
      final efforts = semaine.map((j) => j.noteDEffort).toList()..sort();
      final raideurs = semaine.map((j) => j.noteDeRaideur).toList()..sort();
      final etendueEffort = efforts.last - efforts.first;
      final etendueRaideur = raideurs.last - raideurs.first;
      expect(etendueEffort, closeTo(1.65, 0.1));
      expect(etendueRaideur, greaterThan(10.0));
      expect(etendueRaideur, greaterThan(etendueEffort * 6));
    });

    test('ET AUCUNE JOURNEE DE LA SEMAINE N EST ECRETEE', () {
      // La saturation que la jauge sur les rangs produisait a disparu : zero
      // journee a vingt pile sur l'axe effort.
      for (final journee in semaine) {
        expect(
          journee.estEcretee,
          isFalse,
          reason: 'journee ${journee.numero} est ecretee',
        );
        expect(journee.noteDEffort, lessThan(20.0));
      }
    });
  });
}
