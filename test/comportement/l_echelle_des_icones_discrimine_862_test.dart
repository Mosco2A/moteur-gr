// TEST DE L'ECHELLE — TACHE 862. CE N'EST PAS UN CONTROLE DE RENDU.
//
// Christophe, 21/10/2026 08:14 : « si l icone sort rouge partout c est que
// l echelle est mauvaise ». Il a retourne l'enonce et il a raison : une
// echelle qui donne la meme valeur a tout ne porte AUCUNE information, par
// definition. Le releve des couleurs est donc un TEST DE L'ECHELLE, et un axe
// qui sort uniforme a ECHOUE.
//
// LE CRITERE, EXPLICITE : sur les seize etapes du GR20 et sur les journees des
// trois produits a leur allure par defaut, chaque axe doit produire PLUSIEURS
// niveaux differents. Un seul niveau occupe = echec.
//
// ET IL Y A UN CAS OU L'UNIFORMITE SERAIT UNE VERITE ET PAS UN DEFAUT, et il
// fallait le chiffrer avant de conclure : le bareme francais place son dernier
// seuil publie a 25 km et 1 000 m de montee, et une journee GROUPEE du GR20
// depasse deja ca largement — les huit journees du sentier entier sont a un
// indice de 41 a 60 quand le seuil est a 41,86. LE GR20 COMMENCE DONC LA OU
// L'ECHELLE GENERALISTE S'ARRETE. La reparation n'est PAS de deplacer les
// seuils publies — ce serait perdre la seule chose sourcee qu'on ait — c'est
// de le dire, et de verifier que l'axe RAIDEUR porte la discrimination quand
// l'axe effort se tasse. C'est exactement ce que ce fichier mesure.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/niveau_des_icones.dart';
import 'package:moteur_gr/domain/note_d_effort.dart';
import 'package:moteur_gr/domain/note_de_raideur.dart';
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

List<JourneePesee> journeesDe(String dossier, int jours) {
  final profil = profilDe(dossier);
  final nuits = nuitsDe(dossier);
  final aPeser = <JourneeAPeser>[];
  var pk = 0.0;
  var depart = nuits.teteDeSentier;
  for (final j in DecoupageSurLesNuits.repartir(
    nuits,
    jours,
    effortDuGroupe: effortDuGroupe(nuits, profil),
  )) {
    final pkFin = j.arrivee?.pkKm ?? pk;
    aPeser.add(
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
  return SentierPese.peser(
    jours: jours,
    profil: profil,
    journees: aPeser,
  )!.journees;
}

/// Les seize etapes officielles, mesurees dans un sens ou dans l'autre.
List<IndiceDuTerrain> seizeEtapes({required bool aLEnvers}) {
  final profil = aLEnvers ? profilDe('gr20').aLEnvers : profilDe('gr20');
  final longueurKm = profil.longueurM / 1000.0;
  final publiees =
      lireJson('assets/data/gr20/mesure_etapes.json')['etapes']
          as List<dynamic>;
  return <IndiceDuTerrain>[
    for (final brute in publiees)
      () {
        final e = brute as Map<String, dynamic>;
        final depart = (e['pk_depart_km'] as num).toDouble();
        final arrivee = (e['pk_arrivee_km'] as num).toDouble();
        final debut = aLEnvers ? longueurKm - arrivee : depart;
        final fin = aLEnvers ? longueurKm - depart : arrivee;
        return IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: debut * 1000.0,
            pkFinM: fin * 1000.0,
          ),
        );
      }(),
  ];
}

/// Combien de niveaux DIFFERENTS un axe occupe sur une serie de mesures.
int niveauxOccupes(List<NiveauDIcone> niveaux) => niveaux.toSet().length;

List<NiveauDIcone> niveauxDEffort(List<IndiceDuTerrain> mesures) =>
    <NiveauDIcone>[for (final m in mesures) NoteDEffort.niveauDIcone(m.indice)];

List<NiveauDIcone> niveauxDeRaideur(List<IndiceDuTerrain> mesures) =>
    <NiveauDIcone>[
      for (final m in mesures)
        NoteDeRaideur.niveauDIcone(
          NoteDeRaideur.metresParKm(deniveleM: m.deniveleM, km: m.kmDeCarte),
        ),
    ];

void main() {
  group('862 — LE TEST DE L ECHELLE SUR LES SEIZE ETAPES DU GR20', () {
    test('SENS DE LA TRACE : LES DEUX AXES DISCRIMINENT, quatre niveaux '
        'chacun', () {
      final mesures = seizeEtapes(aLEnvers: false);
      expect(mesures, hasLength(16));
      final effort = niveauxDEffort(mesures);
      final raideur = niveauxDeRaideur(mesures);
      // LE CRITERE : plusieurs niveaux, sinon l'axe a echoue.
      expect(
        niveauxOccupes(effort),
        greaterThan(1),
        reason: 'L AXE EFFORT SATURE sur les seize etapes : echec d echelle',
      );
      expect(
        niveauxOccupes(raideur),
        greaterThan(1),
        reason: 'L AXE RAIDEUR SATURE sur les seize etapes : echec d echelle',
      );
      // ET LE RELEVE EXACT EST FIGE ICI, parce que c'est lui qu'on montre.
      expect(niveauxOccupes(effort), 4);
      expect(niveauxOccupes(raideur), 4);
      expect(_compter(effort), <int>[0, 4, 6, 5, 1]);
      expect(_compter(raideur), <int>[7, 5, 3, 1, 0]);
    });

    test('SENS INVERSE : LES DEUX AXES DISCRIMINENT ENCORE', () {
      final mesures = seizeEtapes(aLEnvers: true);
      expect(mesures, hasLength(16));
      final effort = niveauxDEffort(mesures);
      final raideur = niveauxDeRaideur(mesures);
      expect(
        niveauxOccupes(effort),
        greaterThan(1),
        reason: 'L AXE EFFORT SATURE a l envers : echec d echelle',
      );
      expect(
        niveauxOccupes(raideur),
        greaterThan(1),
        reason: 'L AXE RAIDEUR SATURE a l envers : echec d echelle',
      );
      expect(niveauxOccupes(effort), 4);
      expect(niveauxOccupes(raideur), 3);
      expect(_compter(effort), <int>[0, 5, 6, 4, 1]);
      expect(_compter(raideur), <int>[4, 8, 4, 0, 0]);
    });

    test('LA MONTAGNE DISPARAIT SUR LES ETAPES VRAIMENT PLATES, et c est une '
        'information vraie', () {
      // Sept des seize etapes sont sous la premiere bande publiee de l'IMBA.
      // L'absence de montagne y dit « ca ne monte pas pour la distance », et
      // ce n'est pas un trou : une mesure absente ne produit aucune rangee du
      // tout, elle est nommee en texte par `SentierPese.mesuresManquantes`.
      final raideur = niveauxDeRaideur(seizeEtapes(aLEnvers: false));
      expect(
        raideur.where((n) => n == NiveauDIcone.aucun).length,
        7,
        reason: 'sept etapes sous 50 m de montee par kilometre',
      );
    });

    test('LA CHAUSSURE NE DISPARAIT JAMAIS, dans aucun sens', () {
      for (final aLEnvers in <bool>[false, true]) {
        for (final niveau in niveauxDEffort(seizeEtapes(aLEnvers: aLEnvers))) {
          expect(niveau, isNot(NiveauDIcone.aucun));
        }
      }
    });
  });

  group('862 — LE TEST DE L ECHELLE SUR LES TROIS PRODUITS', () {
    // Les allures PAR DEFAUT, celles que le client voit en ouvrant la fiche :
    // huit jours sur le sentier entier, sept sur chaque chapitre.
    const produits = <String, int>{'gr20': 8, 'gr20-nord': 7, 'gr20-sud': 7};

    test('AUCUN AXE NE SATURE SUR AUCUN DES TROIS PRODUITS', () {
      for (final entree in produits.entries) {
        final journees = journeesDe(entree.key, entree.value);
        expect(journees, isNotEmpty, reason: entree.key);
        final effort = <NiveauDIcone>[
          for (final j in journees) NoteDEffort.niveauDIcone(j.indiceDuTerrain),
        ];
        final raideur = <NiveauDIcone>[
          for (final j in journees)
            NoteDeRaideur.niveauDIcone(j.metresParKmDeMontee),
        ];
        expect(
          niveauxOccupes(effort),
          greaterThan(1),
          reason:
              'L AXE EFFORT SATURE sur ${entree.key} a ${entree.value} jours : '
              'echec d echelle',
        );
        expect(
          niveauxOccupes(raideur),
          greaterThan(1),
          reason:
              'L AXE RAIDEUR SATURE sur ${entree.key} a ${entree.value} '
              'jours : echec d echelle',
        );
      }
    });

    test('LE GR20 ENTIER COMMENCE LA OU L ECHELLE GENERALISTE S ARRETE, et '
        'c est la RAIDEUR qui porte alors la discrimination', () {
      // LE CAS OU L UNIFORMITE SERAIT UNE VERITE, chiffre. Sur le sentier
      // entier a huit jours, SEPT des huit journees depassent le dernier
      // seuil publie du bareme francais (25 km et 1 000 m de montee) : l'axe
      // effort n'a plus que deux niveaux pour les decrire. C'est un fait sur
      // le GR20, pas un defaut de l'echelle — et c'est precisement pour cela
      // que le second axe existe.
      final journees = journeesDe('gr20', 8);
      expect(journees, hasLength(8));
      final auDela = journees
          .where(
            (j) => j.indiceDuTerrain > NoteDEffort.indiceDuDernierSeuilPublie,
          )
          .length;
      expect(auDela, 7, reason: 'sept journees au-dela du dernier seuil');

      final effort = <NiveauDIcone>[
        for (final j in journees) NoteDEffort.niveauDIcone(j.indiceDuTerrain),
      ];
      final raideur = <NiveauDIcone>[
        for (final j in journees)
          NoteDeRaideur.niveauDIcone(j.metresParKmDeMontee),
      ];
      expect(niveauxOccupes(effort), 2, reason: 'l effort se tasse');
      expect(
        niveauxOccupes(raideur),
        greaterThan(niveauxOccupes(effort)),
        reason:
            'LA RAIDEUR DOIT PORTER PLUS DE NIVEAUX QUE L EFFORT ICI, '
            'sinon le second axe ne sert a rien la ou on en a le plus besoin',
      );
      expect(niveauxOccupes(raideur), 3);
    });

    test('ET LES SEUILS PUBLIES NE SONT PAS DEPLACES POUR ARRANGER LE '
        'RESULTAT', () {
      // La tentation serait de remonter le dernier seuil pour que le GR20
      // retrouve de la place. Ce serait perdre la seule chose sourcee qu'on
      // ait. Ce test fige les quatre frontieres sur leurs valeurs publiees.
      expect(NoteDEffort.frontieresDesIcones, <double>[
        8.69,
        18.80,
        30.16,
        41.86,
      ]);
      expect(NoteDeRaideur.frontieresDesIcones, <double>[
        50.0,
        100.0,
        150.0,
        200.0,
      ]);
    });
  });
}

/// Combien de mesures tombent dans chacun des cinq niveaux, dans l'ordre.
List<int> _compter(List<NiveauDIcone> niveaux) => <int>[
  for (final niveau in NiveauDIcone.values)
    niveaux.where((n) => n == niveau).length,
];
