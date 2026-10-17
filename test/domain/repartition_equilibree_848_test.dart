// GARDE — TACHE 848 : LE COMPTE DEMANDE EST RENDU, ET AUCUNE JOURNEE N'EST
// VIDE.
//
// LE DEFAUT QUE CES CAS EMPECHENT DE REVENIR. Les deux repartiteurs du depot
// coupaient « des que la charge accumulee atteint la cible ». Une unite entiere
// fait souvent DEPASSER cette cible : les premieres journees prennent plus que
// leur part, les dernieres n'atteignent plus la leur, et la coupe s'arrete
// avant le compte. Sur le GR20, sept jours demandes rendaient six journees.
// Depuis que le nombre de jours est un CHOIX DU CLIENT (Christophe, 17/10 :
// « le client le fait dans le nombre de jours qu'il veut »), rendre autre chose
// que le compte demande, c'est corriger son choix en silence.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/repartition_equilibree.dart';

/// Les charges d'un decoupage, deduites des index de debut de groupe.
List<double> chargesParGroupe(List<double> charges, List<int> debuts) => [
  for (var g = 0; g < debuts.length; g++)
    charges
        .sublist(
          debuts[g],
          g + 1 < debuts.length ? debuts[g + 1] : charges.length,
        )
        .fold<double>(0, (s, c) => s + c),
];

void main() {
  group('848 — le compte', () {
    test('LE CAS EXACT QUI CASSAIT L ANCIEN CALCUL', () {
      // Une charge enorme en tete, puis des miettes. Ancien calcul : il coupait
      // apres la premiere unite (100 >= 104/3), puis le cumul des miettes
      // n'atteignait plus jamais la cible — DEUX groupes au lieu de trois.
      final charges = <double>[100, 1, 1, 1, 1];
      final debuts = RepartitionEquilibree.coupes(charges, 3);
      expect(debuts.length, 3);
      expect(debuts.first, 0);
      expect(chargesParGroupe(charges, debuts).length, 3);
    });

    test('LE COMPTE EST RENDU POUR TOUT k <= n, SUR CENT CHARGES', () {
      // Des charges volontairement tres inegales : c'est le cas defavorable.
      final charges = <double>[
        for (var i = 0; i < 100; i++) (i % 7 == 0) ? 500.0 : 3.0,
      ];
      for (var k = 1; k <= charges.length; k++) {
        final debuts = RepartitionEquilibree.coupes(charges, k);
        expect(debuts.length, k, reason: 'k=$k');
        expect(debuts.first, 0, reason: 'k=$k');
        for (var i = 1; i < debuts.length; i++) {
          expect(
            debuts[i],
            greaterThan(debuts[i - 1]),
            reason: 'k=$k : aucun groupe vide, les debuts croissent',
          );
        }
        expect(debuts.last, lessThan(charges.length));
      }
    });

    test('plus de groupes que d unites : une unite par groupe', () {
      final debuts = RepartitionEquilibree.coupes(<double>[1, 2, 3], 10);
      expect(debuts, <int>[0, 1, 2]);
    });

    test('les cas limites ne levent pas et ne devinent rien', () {
      expect(RepartitionEquilibree.coupes(<double>[], 3), isEmpty);
      expect(RepartitionEquilibree.coupes(<double>[1, 2], 0), isEmpty);
      expect(RepartitionEquilibree.coupes(<double>[1, 2], -4), isEmpty);
    });

    test('une charge negative est ramenee a zero, pas propagee', () {
      final debuts = RepartitionEquilibree.coupes(<double>[-50, 10, 10], 2);
      expect(debuts.length, 2);
    });
  });

  group('848 — l equilibre, en deux temps', () {
    test(
      'TEMPS 1 : la journee la plus chargee est la plus legere possible',
      () {
        // Quatre unites egales en deux journees : le seul optimum est 10 / 10.
        final charges = <double>[5, 5, 5, 5];
        final debuts = RepartitionEquilibree.coupes(charges, 2);
        expect(debuts, <int>[0, 2]);
        expect(chargesParGroupe(charges, debuts), <double>[10, 10]);
      },
    );

    test('TEMPS 1 : il trouve la coupe que la gloutonne manquait', () {
      // Charges 9, 1, 1, 9 en deux journees. La gloutonne viserait 10 et
      // couperait apres la premiere unite : 9 et 11, maximum 11. Le minimum
      // vrai est 10 (9+1 puis 1+9).
      final charges = <double>[9, 1, 1, 9];
      final debuts = RepartitionEquilibree.coupes(charges, 2);
      expect(chargesParGroupe(charges, debuts), <double>[10, 10]);
    });

    test('TEMPS 2 : AUCUNE JOURNEE DEGENEREE A MAXIMUM EGAL', () {
      // LE CAS QUI JUSTIFIE LE SECOND TEMPS. Charges 10, 10, 10, 0, 0, 0 en
      // trois journees : le maximum minimal vaut 10, et DE NOMBREUSES coupes
      // l'atteignent — dont [10][10][10+0+0+0] et [10][10+0][10+0+0]. Mais
      // aussi, si l'on ne regarde que le maximum, rien n'interdit une journee
      // a ZERO. Le second temps choisit les journees les plus egales, donc
      // aucune a zero.
      final charges = <double>[10, 10, 10, 0, 0, 0];
      final debuts = RepartitionEquilibree.coupes(charges, 3);
      final parGroupe = chargesParGroupe(charges, debuts);
      expect(parGroupe.length, 3);
      expect(parGroupe.reduce((a, b) => a > b ? a : b), 10);
      for (final charge in parGroupe) {
        expect(charge, greaterThan(0), reason: 'aucune journee a zero');
      }
    });

    test('LA SOMME EST CONSERVEE : aucune charge ne se perd en route', () {
      final charges = <double>[12, 3, 48, 7, 7, 25, 1, 30];
      for (var k = 1; k <= charges.length; k++) {
        final total = chargesParGroupe(
          charges,
          RepartitionEquilibree.coupes(charges, k),
        ).fold<double>(0, (s, c) => s + c);
        expect(total, closeTo(133, 1e-9), reason: 'k=$k');
      }
    });

    test('L\'ORDRE EST GARDE : les groupes sont contigus et croissants', () {
      final debuts = RepartitionEquilibree.coupes(<double>[
        4,
        4,
        4,
        4,
        4,
        4,
        4,
        4,
      ], 4);
      expect(debuts, <int>[0, 2, 4, 6]);
    });
  });
}
