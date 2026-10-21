// TACHE 861 — LES DEUX JAUGES, ET CE QUI LES FONDE.
//
// CE QUE CE FICHIER PROUVE, ET C'EST TOUT CE QUI COMPTE DANS CE LOT : que les
// reperes des deux axes sont des SEUILS PUBLIES et pas des nombres choisis par
// nous. Pour l'effort, les quatre premiers paliers rendent exactement 4, 8, 12
// et 16 sur les frontieres du bareme francais. Pour la raideur, le diviseur
// dix fait tomber les quatre bandes de l'IMBA exactement sur 5, 10, 15 et 20.
// Si l'un de ces nombres bouge, l'axe n'est plus source et le lot s'effondre.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/note_d_effort.dart';
import 'package:moteur_gr/domain/note_de_raideur.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';

void main() {
  group('861 — l axe effort est cale sur des seuils publies', () {
    test(
      'LES QUATRE SEUILS DU BAREME FRANCAIS RENDENT 4, 8, 12 ET 16 PILE',
      () {
        // Ce ne sont pas nos chiffres : ce sont les frontieres du bareme
        // francais commun de randonnee, relevees le 20/10/2026.
        expect(
          NoteDEffort.pourIndice(NoteDEffort.indiceDe6km200m),
          closeTo(4, 1e-9),
        );
        expect(
          NoteDEffort.pourIndice(NoteDEffort.indiceDe12km450m),
          closeTo(8, 1e-9),
        );
        expect(
          NoteDEffort.pourIndice(NoteDEffort.indiceDe18km750m),
          closeTo(12, 1e-9),
        );
        expect(
          NoteDEffort.pourIndice(NoteDEffort.indiceDuDernierSeuilPublie),
          closeTo(16, 1e-9),
        );
        expect(
          NoteDEffort.pourIndice(NoteDEffort.indiceDuVingt),
          closeTo(20, 1e-9),
        );
      },
    );

    test('ALLTRAILS RECOUPE LE BAREME FRANCAIS A CINQ POUR CENT PRES', () {
      // LA VALIDATION QUI N'ETAIT PAS CHERCHEE, et c'est la plus solide que
      // l'indice ait recue : deux methodes, deux pays, la meme frontiere.
      // AllTrails la place a 11 km et 450 m, le bareme francais a 12 km et
      // 450 m, et nos indices tombent a 17,80 contre 18,80.
      final ecart =
          (NoteDEffort.indiceDe12km450m -
                  NoteDEffort.indiceDeLaFrontiereAllTrails)
              .abs() /
          NoteDEffort.indiceDe12km450m;
      expect(ecart, lessThan(0.06));
      expect(
        NoteDEffort.pourIndice(NoteDEffort.indiceDeLaFrontiereAllTrails),
        closeTo(7.60, 0.05),
      );
    });

    test('LE DERNIER PALIER EST LE SEUL QUI DEPENDE DE NOUS, et il ne pese '
        'QUE VINGT POUR CENT DE L ECHELLE', () {
      // C'est le gain reel du lot sur la 860 : l'ancre de Christophe
      // gouvernait CENT pour cent de l'echelle quand les paliers etaient les
      // deciles d'un corpus a nous. Elle n'en gouverne plus que le dernier
      // cinquieme.
      expect(
        NoteDEffort.pourIndice(NoteDEffort.indiceDuDernierSeuilPublie),
        closeTo(16, 1e-9),
      );
      const partQuiDependDeNous = (20.0 - 16.0) / 20.0;
      expect(partQuiDependDeNous, closeTo(0.20, 1e-9));
    });

    test('LE RAPPORT DU PALIER LE PLUS RAIDE AU PLUS PLAT VAUT 5,3 et non '
        '19,5', () {
      // LE PROBLEME DE RESOLUTION EN BAS EST REGLE, et il se mesure. La jauge
      // sur les deciles depensait 0,16 point de note par kilometre de plat en
      // bas contre 3,1 fois plus en haut ; celle-ci depense 0,46 en bas.
      final pentes = <double>[];
      for (var i = 1; i < NoteDEffort.paliers.length; i++) {
        final (basIndice, basNote) = NoteDEffort.paliers[i - 1];
        final (hautIndice, hautNote) = NoteDEffort.paliers[i];
        pentes.add((hautNote - basNote) / (hautIndice - basIndice));
      }
      expect(pentes.first, closeTo(0.4603, 0.0005));
      expect(pentes.last, closeTo(0.0877, 0.0005));
      final rapport =
          pentes.reduce((a, b) => a > b ? a : b) /
          pentes.reduce((a, b) => a < b ? a : b);
      expect(rapport, closeTo(5.25, 0.1));
      // ET LES QUATRE PREMIERS PALIERS SONT PRESQUE EGAUX : c'est ce qui rend
      // la note lisible sur toute la plage utile.
      for (var i = 0; i < 4; i++) {
        expect(pentes[i], closeTo(0.39, 0.08), reason: 'palier $i');
      }
    });

    test('LA JAUGE EST STRICTEMENT CROISSANTE, ET SON INVERSE LA RETOURNE', () {
      var precedente = -1.0;
      for (var indice = 0.0; indice <= 90.0; indice += 0.25) {
        final note = NoteDEffort.pourIndice(indice);
        expect(note, greaterThanOrEqualTo(precedente), reason: 'a $indice');
        expect(note, inInclusiveRange(0.0, 20.0));
        precedente = note;
      }
      for (var note = 0.5; note < 20.0; note += 0.5) {
        final indice = NoteDEffort.indicePourNote(note);
        expect(NoteDEffort.pourIndice(indice), closeTo(note, 1e-6));
      }
    });

    test('AU-DESSUS DE VINGT C EST VINGT, ET L ECRETAGE SE DIT', () {
      expect(NoteDEffort.pourIndice(500), 20.0);
      expect(NoteDEffort.pourIndice(-5), 0.0);
      expect(NoteDEffort.estEcretee(NoteDEffort.indiceDuVingt), isFalse);
      expect(NoteDEffort.estEcretee(NoteDEffort.indiceDuVingt + 0.01), isTrue);
    });
  });

  group('861 — l axe raideur est cale sur les bandes publiees de l IMBA', () {
    test('LES QUATRE BANDES DE L IMBA RENDENT 5, 10, 15 ET 20 PILE — donc le '
        'diviseur dix n est PAS choisi', () {
      // C'EST LE TEST QUI FONDE L AXE. Si ces quatre nombres ne sont pas
      // ronds, le diviseur dix devient un reglage a nous et l'axe perd sa
      // source. Bandes : vert 5 %, bleu 10 %, noir 15 %, double noir 20 %.
      expect(NoteDeRaideur.pourMetresParKm(NoteDeRaideur.vertM), 5.0);
      expect(NoteDeRaideur.pourMetresParKm(NoteDeRaideur.bleuM), 10.0);
      expect(NoteDeRaideur.pourMetresParKm(NoteDeRaideur.noirM), 15.0);
      expect(NoteDeRaideur.pourMetresParKm(NoteDeRaideur.doubleNoirM), 20.0);
    });

    test('LE KILOMETRAGE EST CELUI DE LA CARTE, et la mesure dit pourquoi', () {
      // UNE PENTE MOYENNE EST UNE DENIVELEE SUR UNE DISTANCE HORIZONTALE.
      // Mesuree sur la longueur inclinee, une VRAIE pente de 20 % — la
      // frontiere double noir — sortirait a 19,61 sur 20 au lieu de 20,00, et
      // les quatre bandes publiees ne tomberaient plus sur des notes rondes.
      // La convention horizontale est donc la seule qui rende vrai l'argument
      // fondant le diviseur dix.
      for (final pente in <double>[0.05, 0.10, 0.15, 0.20]) {
        const horizontalM = 1000.0;
        final monteeM = pente * horizontalM;
        final inclineeM = _hypot(horizontalM, monteeM);
        final surLaCarte = NoteDeRaideur.pourJournee(
          deniveleM: monteeM,
          km: horizontalM / 1000.0,
        );
        final surLInclinee = NoteDeRaideur.pourJournee(
          deniveleM: monteeM,
          km: inclineeM / 1000.0,
        );
        expect(
          surLaCarte,
          closeTo(pente * 100, 1e-9),
          reason: 'la carte rend la pente en pourcents a pente $pente',
        );
        expect(
          surLInclinee,
          lessThan(surLaCarte),
          reason: 'l inclinee sous-estime toujours la pente',
        );
      }
      // ET L ERREUR GRANDIT AVEC LA PENTE, ce qui est le pire comportement
      // possible pour un axe de raideur : elle se trompe le plus la ou l on
      // mesure justement la raideur.
      final erreurA5 =
          5.0 -
          NoteDeRaideur.pourJournee(deniveleM: 50, km: _hypot(1000, 50) / 1000);
      final erreurA20 =
          20.0 -
          NoteDeRaideur.pourJournee(
            deniveleM: 200,
            km: _hypot(1000, 200) / 1000,
          );
      expect(erreurA20, greaterThan(erreurA5 * 5));
    });

    test('AU-DESSUS DE LA BANDE LA PLUS RAIDE, C EST VINGT', () {
      expect(NoteDeRaideur.pourMetresParKm(251.5), 20.0);
      expect(NoteDeRaideur.estEcretee(NoteDeRaideur.doubleNoirM), isFalse);
      expect(NoteDeRaideur.estEcretee(251.5), isTrue);
      expect(NoteDeRaideur.pourMetresParKm(0), 0.0);
      expect(NoteDeRaideur.pourJournee(deniveleM: 500, km: 0), 0.0);
    });

    test('LE CHIFFRE BRUT EST LA GRANDEUR, PAS LA NOTE', () {
      // Le brut s'affiche a cote de la note parce qu'une note sur vingt
      // suggere une precision au dixieme que la pente moyenne n'a pas.
      expect(
        NoteDeRaideur.metresParKm(deniveleM: 1454, km: 11.35),
        closeTo(128.1, 0.1),
      );
      expect(NoteDeRaideur.metresParKm(deniveleM: 100, km: 0), 0.0);
    });
  });

  group('861 — les deux axes disent des choses differentes', () {
    test('LE MUR DE 300 METRES EN UN KILOMETRE : BAS EN EFFORT, AU PLAFOND EN '
        'RAIDEUR', () {
      // AUCUN AXE UNIQUE NE POUVAIT DIRE CA, quelle que soit sa formule : ce
      // mur ne coute presque rien — un kilometre — et c'est un mur.
      const mur = ProfilDuTerrain(<SegmentDeProfil>[
        SegmentDeProfil(pkDebutM: 0, longueurM: 1000, deniveleM: 300),
      ]);
      final terrain = IndiceDuTerrain.calculer(terrain: mur.segments);
      expect(NoteDEffort.pourIndice(terrain.indice), closeTo(3.15, 0.05));
      expect(
        NoteDeRaideur.pourJournee(
          deniveleM: terrain.deniveleM,
          km: terrain.kmDeCarte,
        ),
        20.0,
      );
    });

    test('DEUX JOURNEES DE MEME EFFORT PEUVENT AVOIR DIX POINTS DE RAIDEUR '
        'D ECART', () {
      // LA PREUVE EN GEOMETRIE PURE, avant toute trace reelle : quatre
      // kilometres a 150 m/km et quinze kilometres a 15 m/km. On les construit
      // pour qu'elles coutent a peu pres la meme energie, et elles sortent a
      // 15 sur 20 contre 1,5 sur 20 de raideur.
      final courteEtRaide = NoteDeRaideur.pourJournee(deniveleM: 600, km: 4);
      final longueEtPlate = NoteDeRaideur.pourJournee(deniveleM: 225, km: 15);
      expect(courteEtRaide, closeTo(15.0, 1e-9));
      expect(longueEtPlate, closeTo(1.5, 1e-9));
      expect(courteEtRaide - longueEtPlate, greaterThan(10));
    });
  });
}

/// L'hypotenuse : la longueur INCLINEE d'un morceau de pente.
double _hypot(double a, double b) => sqrt(a * a + b * b);
