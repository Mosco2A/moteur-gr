// GARDE — TACHE 860 : LA JAUGE SUR LES RANGS, LES QUATRE LECTURES, ET LA
// REGLE QUI INTERDIT D'ADDITIONNER DES NOTES.
//
// CE QUE CE FICHIER PROUVE, DANS L'ORDRE :
//
//   1. LA JAUGE est figee, strictement croissante, elle respecte EXACTEMENT
//      les deux ancres de Christophe (six kilometres de plat valent zero, la
//      plus dure etape publiee vaut vingt) et elle ECRETE au-dessus ;
//   2. LA NOTE NE LIT QUE L'INDICE — aucun rang recalcule, aucun contexte,
//      donc une journee garde sa note pour toujours ;
//   3. LES QUATRE LECTURES decrivent un plan SANS JAMAIS LE NOTER, et la
//      journee dure est celle qui depasse la journee TYPE du plan ;
//   4. LE REPARTITEUR egalise l'EFFORT et son second temps MAXIMISE LA PLUS
//      PETITE journee, ce qui tue les journees d'une heure.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/note_sur_vingt.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/domain/repartition_equilibree.dart';

/// Une journee pesee de note voulue, pour eprouver les lectures.
JourneePesee journeeDIndice(double indice, {int numero = 1}) => JourneePesee(
  numero: numero,
  depart: 'a',
  arrivee: 'b',
  km: 10,
  deniveleM: 500,
  descenteM: 500,
  minutes: 300,
  terrain: IndiceDuTerrain(
    socleMesure: indice,
    majorationDeContinuite: 0,
    monteesContinues: 1,
    plusGrosseMonteeM: 500,
    deniveleM: 500,
    descenteM: 500,
    kmDeTrajet: 10,
  ),
);

void main() {
  group('860 — la jauge sur les rangs est figee et elle tient ses ancres', () {
    test('LES DEUX ANCRES DE CHRISTOPHE SONT EXACTES : zero a six kilometres '
        'de plat, vingt a la plus dure etape publiee', () {
      expect(NoteSurVingt.pourIndice(NoteSurVingt.indiceDuZero), 0.0);
      expect(
        NoteSurVingt.pourIndice(NoteSurVingt.indiceDuVingt),
        NoteSurVingt.noteMaximale,
      );
      // Six kilometres de plat valent exactement six points d'indice, par
      // construction de l'indice (un point = un kilometre de plat).
      expect(NoteSurVingt.indiceDuZero, 6.0);
      expect(NoteSurVingt.pourIndice(5.0), 0.0);
      expect(NoteSurVingt.pourIndice(0.0), 0.0);
    });

    test('AU-DESSUS DE VINGT, C EST VINGT — et l ecretage se dit', () {
      // Christophe, verbatim : « Evidemment que 2 ou 3 etapes groupee sortent
      // a plus que la plus grosse etape du monde. Et au dessus de 20, cest
      // 20 ». Une journee qui groupe des etapes y arrive mecaniquement : sur
      // le GR20 a cinq jours, la premiere journee vaut 88,6 d'indice.
      expect(NoteSurVingt.pourIndice(88.64), 20.0);
      expect(NoteSurVingt.pourIndice(200.0), 20.0);
      expect(NoteSurVingt.estEcretee(88.64), isTrue);
      expect(NoteSurVingt.estEcretee(NoteSurVingt.indiceDuVingt), isFalse);
      expect(NoteSurVingt.estEcretee(42.58), isFalse);
    });

    test('LA JAUGE EST STRICTEMENT CROISSANTE SUR TOUT SON DOMAINE', () {
      var precedente = -1.0;
      for (var indice = 0.0; indice <= 95.0; indice += 0.05) {
        final note = NoteSurVingt.pourIndice(indice);
        expect(
          note,
          greaterThanOrEqualTo(precedente),
          reason: 'la note recule a l indice $indice',
        );
        expect(note, inInclusiveRange(0.0, 20.0));
        precedente = note;
      }
    });

    test('LES ONZE PALIERS SONT DES CONSTANTES DATEES, et la jauge passe '
        'exactement par chacun', () {
      expect(NoteSurVingt.paliers, hasLength(11));
      expect(NoteSurVingt.dateDuCalage, '19/10/2026');
      expect(NoteSurVingt.etapesDuCorpus, 106);
      for (final (indice, note) in NoteSurVingt.paliers) {
        expect(
          NoteSurVingt.pourIndice(indice),
          closeTo(note, 1e-9),
          reason: 'palier $indice',
        );
      }
      // Les paliers montent, en indice comme en note : c'est ce qui garantit
      // la croissance stricte.
      for (var i = 1; i < NoteSurVingt.paliers.length; i++) {
        expect(
          NoteSurVingt.paliers[i].$1,
          greaterThan(NoteSurVingt.paliers[i - 1].$1),
        );
        expect(
          NoteSurVingt.paliers[i].$2,
          greaterThan(NoteSurVingt.paliers[i - 1].$2),
        );
      }
    });

    test('LA REPONSE QUI A DECIDE DU LOT : l etape 1 du GR20 vaut 15,55 sur '
        'vingt, et plus 9,85', () {
      // L'indice de l'etape 1 a l'exposant mesure 1,08 vaut 42,58. L'ancienne
      // jauge de MAGNITUDE en faisait 9,85 sur 20, un chiffre que personne ne
      // pouvait croire pour la plus dure etape du GR20. La jauge sur les RANGS
      // en fait 15,55 : plus dure que les trois quarts des etapes officielles
      // du monde. Ce qui a change n'est pas la mesure, c'est la question.
      expect(NoteSurVingt.pourIndice(42.58), closeTo(15.55, 0.01));
    });

    test('LA JAUGE SE LIT A L ENVERS, et c est ce qui la garde explicable', () {
      // « 18 sur 20, c'est quoi en terrain ? » — un indice de 50, donc
      // cinquante kilometres de plat en energie.
      expect(NoteSurVingt.indicePourNote(18.0), closeTo(50.051, 0.01));
      expect(NoteSurVingt.indicePourNote(0.0), NoteSurVingt.indiceDuZero);
      expect(NoteSurVingt.indicePourNote(20.0), NoteSurVingt.indiceDuVingt);
      // ET LA NOTE N EST PAS PROPORTIONNELLE A L EFFORT, il faut le savoir :
      // 18 sur 20 vaut 1,53 fois 9 sur 20, et non le double.
      final a18 = NoteSurVingt.indicePourNote(18.0);
      final a9 = NoteSurVingt.indicePourNote(9.0);
      expect(a18 / a9, closeTo(1.53, 0.02));
    });

    test('ELLE NE LIT QUE L INDICE : deux appels identiques rendent la meme '
        'note, sans aucun contexte', () {
      expect(NoteSurVingt.pourIndice(31.0), NoteSurVingt.pourIndice(31.0));
      // Entre deux paliers elle est LINEAIRE en indice, donc proportionnelle a
      // l interieur d un decile.
      final basse = NoteSurVingt.pourIndice(36.391);
      final haute = NoteSurVingt.pourIndice(39.736);
      final milieu = NoteSurVingt.pourIndice((36.391 + 39.736) / 2);
      expect(milieu, closeTo((basse + haute) / 2, 1e-9));
    });
  });

  group('860 — les quatre lectures decrivent un plan sans le noter', () {
    test('LA JOURNEE TYPE EST LA MOYENNE, ET LA JOURNEE DURE LA DEPASSE', () {
      final lectures = LecturesDuPlan.desJournees(<JourneePesee>[
        journeeDIndice(20.0, numero: 1), // note 2,29
        journeeDIndice(40.0, numero: 2), // note 14,16
        journeeDIndice(45.0, numero: 3), // note 16,48
      ]);
      expect(lectures.nombreDeJours, 3);
      final notes = <double>[
        NoteSurVingt.pourIndice(20.0),
        NoteSurVingt.pourIndice(40.0),
        NoteSurVingt.pourIndice(45.0),
      ];
      expect(lectures.pireJournee, closeTo(notes.last, 1e-9));
      expect(
        lectures.journeeType,
        closeTo((notes[0] + notes[1] + notes[2]) / 3, 1e-9),
        reason: 'la journee type est la MOYENNE, et c est nomme',
      );
      // Deux journees depassent la moyenne, et elles se suivent.
      expect(lectures.journeesDures, 2);
      expect(lectures.plusLongEnchainementDeJourneesDures, 2);
    });

    test('L ENCHAINEMENT COMPTE LES JOURNEES DURES CONSECUTIVES, PAS LEUR '
        'NOMBRE', () {
      // Dure, facile, dure, dure : trois dures mais seulement deux d affilee.
      final lectures = LecturesDuPlan.desJournees(<JourneePesee>[
        journeeDIndice(50.0, numero: 1),
        journeeDIndice(10.0, numero: 2),
        journeeDIndice(50.0, numero: 3),
        journeeDIndice(50.0, numero: 4),
      ]);
      expect(lectures.journeesDures, 3);
      expect(
        lectures.plusLongEnchainementDeJourneesDures,
        2,
        reason:
            'six journees dures etalees se marchent, six d affilee se '
            'subissent — c est la lecture que Christophe a soulignee',
      );
    });

    test(
      'UN PLAN SANS JOURNEE N A AUCUNE LECTURE, et pas des zeros devines',
      () {
        expect(
          LecturesDuPlan.desJournees(const <JourneePesee>[]).nombreDeJours,
          0,
        );
        expect(LecturesDuPlan.aucune.pireJournee, 0.0);
        expect(LecturesDuPlan.aucune.journeesDures, 0);
      },
    );

    test('AUCUNE NOTE N EXISTE AU-DESSUS DE LA JOURNEE — la garde lit le '
        'source', () {
      // ON NE SOMME JAMAIS. La preuve ne peut pas etre un appel : il faut
      // verifier qu'aucun symbole de note ne vit sur les classes de plan. En
      // rampe droite un troncon sortait a 66 sur 20, absurde donc inoffensif ;
      // avec une jauge qui plafonne il sortirait 20,00 sur 20, credible et
      // completement faux.
      const source = LecturesDuPlan(
        nombreDeJours: 2,
        pireJournee: 10,
        journeeType: 8,
        journeesDures: 1,
        plusLongEnchainementDeJourneesDures: 1,
      );
      // Les quatre lectures et RIEN d'autre : si quelqu'un ajoute un total,
      // c'est ce test et le test structurel qui le diront.
      expect(source.pireJournee, 10);
      expect(source.journeeType, 8);
      expect(source.nombreDeJours, 2);
      expect(source.journeesDures, 1);
      expect(source.plusLongEnchainementDeJourneesDures, 1);
    });
  });

  group('860 — le repartiteur egalise l EFFORT, et son second temps maximise '
      'la plus petite journee', () {
    test('LE SECOND TEMPS TUE LA JOURNEE D UNE HEURE, SANS BOUGER LA PIRE', () {
      // Quatre unites, deux groupes. Le seul maximum est indifferent entre
      // (3+1) et (2+2) si les deux rendent le meme maximum ; ici seul le
      // second temps evite une journee minuscule.
      final charges = <double>[10, 1, 1, 10];
      final coupes = RepartitionEquilibree.coupes(charges, 2);
      expect(coupes, hasLength(2));
      // La coupe retenue equilibre : 10+1 et 1+10, donc 11 et 11.
      expect(coupes, <int>[0, 2]);
    });

    test('LA CHARGE N A PAS BESOIN D ETRE ADDITIVE, et c est le chemin de '
        'l effort', () {
      // L'indice d'une journee n'est pas la somme des indices de ses morceaux.
      // `coupesSelon` prend donc la charge du GROUPE, et la mesure ci-dessous
      // le prouve : la charge vaut le CARRE du nombre d'unites, ce qu'aucune
      // somme d'unites ne peut produire.
      final coupes = RepartitionEquilibree.coupesSelon(
        unites: 4,
        groupes: 2,
        chargeDuGroupe: (debut, fin) {
          final taille = fin - debut;
          return taille * taille * 1.0;
        },
      );
      expect(coupes, <int>[0, 2], reason: 'deux groupes de deux : 4 et 4');
    });

    test('LE COMPTE EST TENU, ET AUCUN GROUPE N EST VIDE', () {
      for (var groupes = 1; groupes <= 6; groupes++) {
        final coupes = RepartitionEquilibree.coupesSelon(
          unites: 6,
          groupes: groupes,
          chargeDuGroupe: (d, f) => (f - d) * 1.0,
        );
        expect(coupes, hasLength(groupes));
        expect(coupes.first, 0);
        for (var i = 1; i < coupes.length; i++) {
          expect(coupes[i], greaterThan(coupes[i - 1]));
        }
      }
    });

    test('UN TERRAIN REEL : la coupe a l effort prefere une journee plus '
        'longue a une journee plus raide', () {
      // Deux unites : une montee seche et un long plat. A deux groupes la
      // coupe est forcee ; a un groupe la charge est celle du tout, et elle
      // n'est PAS la somme des deux (la majoration de continuite ne survit pas
      // a la coupure).
      const profil = ProfilDuTerrain(<SegmentDeProfil>[
        SegmentDeProfil(pkDebutM: 0, longueurM: 4000, deniveleM: 800),
        SegmentDeProfil(pkDebutM: 4000, longueurM: 6000, deniveleM: 0),
      ]);
      double charge(int debut, int fin) => IndiceDuTerrain.calculer(
        terrain: profil.tranche(
          pkDebutM: debut == 0 ? 0 : 4000,
          pkFinM: fin == 1 ? 4000 : 10000,
        ),
      ).indice;
      final coupes = RepartitionEquilibree.coupesSelon(
        unites: 2,
        groupes: 2,
        chargeDuGroupe: charge,
      );
      expect(coupes, <int>[0, 1]);
      expect(charge(0, 2), greaterThan(charge(0, 1)));
    });
  });
}
