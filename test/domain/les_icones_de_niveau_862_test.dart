// TACHE 862 — UNE ICONE NE PEUT PAS CONTREDIRE SA NOTE.
//
// CE QUE CE FICHIER PROUVE, ET C'EST LA PREMIERE DES TROIS EXIGENCES DU LOT :
// que les icones et les notes lisent LES MEMES CONSTANTES. Quatre etats de
// couleur, ce sont quatre bandes, donc quatre frontieres — et Christophe avait
// tue les bandes le 20/10 au matin PARCE QUE leurs frontieres etaient
// arbitraires. Elles ne le sont plus : ce sont les quatre bandes publiees de
// l'IMBA pour la raideur et les quatre seuils publies du bareme francais pour
// l'effort, deja figes par le lot 861 pour les notes.
//
// LA PREUVE TIENT EN UNE PHRASE : les frontieres des icones tombent sur les
// notes 5, 10, 15 et 20 pile pour la raideur, et 4, 8, 12 et 16 pile pour
// l'effort. Le nombre d'icones est donc une FONCTION DE LA NOTE, et si une
// frontiere bouge un jour, les deux bougent ensemble.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/niveau_des_icones.dart';
import 'package:moteur_gr/domain/note_d_effort.dart';
import 'package:moteur_gr/domain/note_de_raideur.dart';

void main() {
  group('862 — les frontieres des icones SONT les seuils publies', () {
    test('LA RAIDEUR : les quatre frontieres sont les quatre bandes IMBA', () {
      expect(NoteDeRaideur.frontieresDesIcones, <double>[
        NoteDeRaideur.vertM,
        NoteDeRaideur.bleuM,
        NoteDeRaideur.noirM,
        NoteDeRaideur.doubleNoirM,
      ]);
      expect(NoteDeRaideur.frontieresDesIcones, hasLength(4));
    });

    test('L EFFORT : les quatre frontieres sont les quatre seuils du '
        'bareme francais', () {
      expect(NoteDEffort.frontieresDesIcones, <double>[
        NoteDEffort.indiceDe6km200m,
        NoteDEffort.indiceDe12km450m,
        NoteDEffort.indiceDe18km750m,
        NoteDEffort.indiceDuDernierSeuilPublie,
      ]);
      expect(NoteDEffort.frontieresDesIcones, hasLength(4));
    });

    test('LES FRONTIERES SONT STRICTEMENT CROISSANTES sur les deux axes', () {
      for (final frontieres in <List<double>>[
        NoteDeRaideur.frontieresDesIcones,
        NoteDEffort.frontieresDesIcones,
      ]) {
        for (var i = 1; i < frontieres.length; i++) {
          expect(frontieres[i], greaterThan(frontieres[i - 1]));
        }
      }
    });
  });

  group('862 — UNE ICONE NE PEUT PAS CONTREDIRE SA NOTE', () {
    test(
      'LA RAIDEUR CHANGE DE NIVEAU EXACTEMENT AUX NOTES 5, 10, 15 ET 20',
      () {
        // C'EST LE TEST QUI TIENT LE LOT. Si ces quatre nombres ne sont pas
        // ronds, l'icone et la note ne parlent plus de la meme echelle.
        const attendu = <double>[5.0, 10.0, 15.0, 20.0];
        for (var i = 0; i < 4; i++) {
          final frontiere = NoteDeRaideur.frontieresDesIcones[i];
          expect(
            NoteDeRaideur.pourMetresParKm(frontiere),
            closeTo(attendu[i], 1e-9),
            reason:
                'la frontiere ${i + 1} doit tomber sur la note ${attendu[i]}',
          );
        }
      },
    );

    test('L EFFORT CHANGE DE NIVEAU EXACTEMENT AUX NOTES 4, 8, 12 ET 16', () {
      const attendu = <double>[4.0, 8.0, 12.0, 16.0];
      for (var i = 0; i < 4; i++) {
        final frontiere = NoteDEffort.frontieresDesIcones[i];
        expect(
          NoteDEffort.pourIndice(frontiere),
          closeTo(attendu[i], 1e-9),
          reason: 'la frontiere ${i + 1} doit tomber sur la note ${attendu[i]}',
        );
      }
    });

    test('LE NOMBRE D ICONES DE RAIDEUR EST UNE FONCTION DE LA NOTE, '
        'balayage dense', () {
      // On balaie tout le domaine et on exige que le niveau soit EXACTEMENT
      // celui que la note impose. Aucune valeur ne peut faire divorcer les
      // deux.
      for (var parKm = 0.0; parKm <= 320.0; parKm += 0.25) {
        final note = NoteDeRaideur.pourMetresParKm(parKm);
        final attendu = note >= 20
            ? 4
            : note >= 15
            ? 3
            : note >= 10
            ? 2
            : note >= 5
            ? 1
            : 0;
        expect(
          NoteDeRaideur.niveauDIcone(parKm).nombreDIcones,
          attendu,
          reason: 'a $parKm m/km, note $note',
        );
      }
    });

    test('LE NOMBRE D ICONES D EFFORT EST UNE FONCTION DE LA NOTE, '
        'balayage dense', () {
      for (var indice = 0.0; indice <= 120.0; indice += 0.25) {
        final note = NoteDEffort.pourIndice(indice);
        final brut = note >= 16
            ? 4
            : note >= 12
            ? 3
            : note >= 8
            ? 2
            : note >= 4
            ? 1
            : 0;
        // LE PLANCHER D UNE ICONE EST LA SEULE DIFFERENCE, et il est mesure :
        // aucune des 108 etapes officielles ne tombe sous la note 4.
        expect(
          NoteDEffort.niveauDIcone(indice).nombreDIcones,
          brut < 1 ? 1 : brut,
          reason: 'a l indice $indice, note $note',
        );
      }
    });

    test('UNE NOTE PLUS HAUTE NE DONNE JAMAIS MOINS D ICONES', () {
      var precedent = -1;
      for (var parKm = 0.0; parKm <= 320.0; parKm += 0.5) {
        final n = NoteDeRaideur.niveauDIcone(parKm).nombreDIcones;
        expect(n, greaterThanOrEqualTo(precedent), reason: 'a $parKm m/km');
        precedent = n;
      }
      precedent = -1;
      for (var indice = 0.0; indice <= 120.0; indice += 0.5) {
        final n = NoteDEffort.niveauDIcone(indice).nombreDIcones;
        expect(
          n,
          greaterThanOrEqualTo(precedent),
          reason: 'a l indice $indice',
        );
        precedent = n;
      }
    });
  });

  group('862 — ce que chaque axe fait de sa bande basse', () {
    test('LA MONTAGNE DISPARAIT SOUS LA PREMIERE BANDE PUBLIEE', () {
      // Christophe, 21/10 08:14 : « pas d icone montagne du tout en dessous
      // de 50 metres ». L IMBA ne gradue rien en dessous, et une etape
      // VRAIMENT plate existe — sept des seize du GR20 en sont.
      expect(NoteDeRaideur.niveauDIcone(0).nombreDIcones, 0);
      expect(NoteDeRaideur.niveauDIcone(49.9).nombreDIcones, 0);
      expect(NoteDeRaideur.niveauDIcone(NoteDeRaideur.vertM).nombreDIcones, 1);
      expect(NoteDeRaideur.niveauDIcone(0), NiveauDIcone.aucun);
    });

    test('LA CHAUSSURE RESTE TOUJOURS PRESENTE, AU MOINS UNE', () {
      // MESURE, PAS CHOIX : aucune des 108 etapes officielles ne tombe sous
      // la premiere frontiere, parce qu une etape publiee EST une journee de
      // marche. Une rangee d effort vide serait donc TOUJOURS lue comme une
      // donnee manquante, jamais comme « aucun effort ».
      expect(NoteDEffort.niveauDIcone(0).nombreDIcones, 1);
      expect(NoteDEffort.niveauDIcone(1).nombreDIcones, 1);
      expect(
        NoteDEffort.niveauDIcone(NoteDEffort.indiceDe6km200m).nombreDIcones,
        1,
      );
      expect(
        NoteDEffort.niveauDIcone(NoteDEffort.indiceDe12km450m).nombreDIcones,
        2,
      );
      for (var indice = 0.0; indice <= 120.0; indice += 0.5) {
        expect(
          NoteDEffort.niveauDIcone(indice),
          isNot(NiveauDIcone.aucun),
          reason: 'l effort ne disparait jamais, a l indice $indice',
        );
      }
    });

    test('LE QUATRIEME NIVEAU DE RAIDEUR EST AUSSI CELUI OU LA NOTE '
        'S ECRETE', () {
      expect(NoteDeRaideur.niveauDIcone(250).nombreDIcones, 4);
      expect(NoteDeRaideur.estEcretee(250), isTrue);
      expect(NoteDeRaideur.pourMetresParKm(250), 20.0);
    });
  });

  group('862 — les libelles parlent sans aucun mot de niveau', () {
    test('AUCUN LIBELLE NE PORTE UN MOT DE NIVEAU', () {
      // Christophe tranchera les niveaux apres : le libelle decrit la BANDE
      // PUBLIEE, factuellement, parce que c'est elle qui est sourcee.
      final libelles = <String>[
        for (final v in <double>[0, 49, 60, 120, 180, 250])
          NoteDeRaideur.libelleDuNiveau(v),
        for (final v in <double>[0, 5, 12, 25, 35, 50, 90])
          NoteDEffort.libelleDuNiveau(v),
      ];
      expect(libelles, hasLength(13));
      for (final libelle in libelles) {
        expect(libelle, isNotEmpty);
        for (final interdit in <String>[
          'facile',
          'Facile',
          'moyen',
          'Moyen',
          'modere',
          'difficile',
          'Difficile',
          'extreme',
        ]) {
          expect(
            libelle.contains(interdit),
            isFalse,
            reason: '« $libelle » porte le mot $interdit',
          );
        }
      }
    });

    test('CHAQUE NIVEAU A SON PROPRE LIBELLE : la voix distingue ce que la '
        'couleur distingue', () {
      final raideur = <String>{
        for (final v in <double>[0, 60, 120, 180, 250])
          NoteDeRaideur.libelleDuNiveau(v),
      };
      expect(raideur, hasLength(5), reason: 'cinq bandes, cinq phrases');
      final effort = <String>{
        for (final v in <double>[5, 25, 35, 50]) NoteDEffort.libelleDuNiveau(v),
      };
      expect(effort, hasLength(4), reason: 'quatre etats visibles');
    });

    test(
      'LES LIBELLES CITENT LES CHIFFRES PUBLIES, pas des approximations',
      () {
        expect(NoteDeRaideur.libelleDuNiveau(0), contains('50'));
        expect(NoteDeRaideur.libelleDuNiveau(120), contains('100'));
        expect(NoteDeRaideur.libelleDuNiveau(120), contains('150'));
        expect(NoteDeRaideur.libelleDuNiveau(250), contains('200'));
        expect(NoteDEffort.libelleDuNiveau(50), contains('25 km'));
        expect(NoteDEffort.libelleDuNiveau(50), contains('1 000 m'));
      },
    );
  });

  group('862 — la largeur reservee est celle du maximum', () {
    test('QUATRE, ET C EST LE PLUS GRAND NIVEAU', () {
      expect(NiveauDIcone.maximum, 4);
      expect(NiveauDIcone.quatre.nombreDIcones, NiveauDIcone.maximum);
      for (final niveau in NiveauDIcone.values) {
        expect(niveau.nombreDIcones, lessThanOrEqualTo(NiveauDIcone.maximum));
      }
    });

    test('LE NIVEAU SE RELIT DEPUIS SON NOMBRE', () {
      for (final niveau in NiveauDIcone.values) {
        expect(NiveauDIcone.pourNombre(niveau.nombreDIcones), niveau);
      }
      expect(NiveauDIcone.pourNombre(-3), NiveauDIcone.aucun);
      expect(NiveauDIcone.pourNombre(99), NiveauDIcone.quatre);
    });
  });
}
