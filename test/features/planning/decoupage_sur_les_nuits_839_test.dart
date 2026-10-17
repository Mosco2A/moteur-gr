import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';

/// LE CURSEUR DE DUREE PEUT FINIR UNE JOURNEE SUR UN LIEU QUI EXISTE
/// (tache 839).
///
/// CE QUE CES CAS PROUVENT, ET LE REPROCHE AUQUEL ILS REPONDENT. Le lot 558
/// avait ajoute un decoupage d'etape que Christophe a refuse le 29/09, verbatim :
/// « Decouper les etapes en deux est une mauvaise idee... il n'y a pas de
/// refuge et surtout JE N'AI JAMAIS DEMANDE CA ». La tache 634 l'a retire.
/// Le grief portait sur le POINT DE COUPE : une interpolation lineaire entre
/// le depart et l'arrivee de l'etape, donc un endroit ou il n'y a peut-etre
/// ni refuge, ni eau, ni abri.
///
/// Ces cas verifient que la coupe n'est plus calculee : chaque journee se
/// termine sur une [NuitPossible] relevee dans OpenStreetMap, avec son
/// identifiant, son temps de marche aller et retour mesure, et ses lits quand
/// OpenStreetMap les connait.
void main() {
  DecoupageDeNuits lireGr20() {
    final file = File('assets/data/gr20/nuits_possibles.json');
    expect(file.existsSync(), isTrue);
    return DecoupageDeNuits.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  group('DecoupageSurLesNuits — toute journee finit sur un lieu releve', () {
    test('AUTANT DE JOURNEES QUE DEMANDE, de 1 a 31', () {
      final gr20 = lireGr20();
      for (var jours = 1; jours <= gr20.journeesMaximales; jours++) {
        final programme = DecoupageSurLesNuits.repartir(gr20, jours);
        expect(
          programme.length,
          jours,
          reason: 'le curseur a demande $jours journees',
        );
        // Aucune journee vide, et l'ordre de marche est preserve.
        var rangPrecedent = 0;
        for (final j in programme) {
          expect(j.segmentCount, greaterThan(0));
          expect(j.km, greaterThan(0));
          for (final s in j.segments) {
            expect(s.rang, greaterThan(rangPrecedent));
            rangPrecedent = s.rang;
          }
        }
        // Toutes les journees reunies couvrent la trace entiere.
        final km = programme.fold<double>(0, (s, j) => s + j.km);
        expect(km, closeTo(183.585, 0.01));
      }
    });

    test(
      'CHAQUE ARRIVEE EST UN LIEU D OPENSTREETMAP, jamais un point calcule',
      () {
        final gr20 = lireGr20();
        final connues = {for (final n in gr20.nuits) n.nom};
        for (final jours in [7, 10, 12, 16, 20, 25, 31]) {
          for (final j in DecoupageSurLesNuits.repartir(gr20, jours)) {
            // TACHE 853 — LE NOM EST TOUJOURS LA, LA NUIT PAS TOUJOURS. Dans
            // le sens de la trace, toutes les arrivees SONT des nuits relevees
            // et ce cas l'exige encore. Ce qui a change, c'est que la journee
            // n'est plus JETEE quand ce n'est pas le cas : elle porte alors son
            // nom de lieu et une nuit nulle (voir le cas de la tete de
            // sentier).
            expect(connues, contains(j.arriveeNom));
            expect(j.arrivee, isNotNull, reason: 'sens de la trace');
            expect(
              j.arrivee!.osm,
              isNotEmpty,
              reason:
                  '${j.arriveeNom} : une arrivee sans identifiant '
                  'OpenStreetMap serait un point invente',
            );
          }
        }
      },
    );

    test('AU-DELA DE SEIZE JOURNEES, ce sont de VRAIES coupures de jour', () {
      final gr20 = lireGr20();
      // A seize journees, l'allure federale : les arrivees sont les seize fins
      // d'etape et rien d'autre.
      final seize = DecoupageSurLesNuits.repartir(gr20, 16);
      expect(seize.length, 16);
      // A vingt-cinq journees, le programme DOIT s'arreter ailleurs qu'aux fins
      // d'etape — sinon le curseur n'aurait toujours que du repos a offrir.
      final vingtCinq = DecoupageSurLesNuits.repartir(gr20, 25);
      final horsEtape = vingtCinq
          .where((j) => !(j.arrivee?.estFinDEtape ?? false))
          .length;
      expect(
        horsEtape,
        greaterThanOrEqualTo(25 - 16),
        reason:
            'vingt-cinq journees sur seize etapes exigent au moins neuf '
            'arrets hors fin d etape, et ils doivent etre releves',
      );
    });

    test('LE DETOUR VERS LE COUCHAGE EST COMPTE, aller et retour', () {
      final gr20 = lireGr20();
      final programme = DecoupageSurLesNuits.repartir(gr20, 31);
      for (final j in programme) {
        final marche = j.segments.fold<int>(0, (s, x) => s + x.minutes);
        // La journee dure au moins le temps de ses segments : le detour ne peut
        // qu'ajouter du temps, jamais en retirer.
        expect(j.minutes, greaterThanOrEqualTo(marche));
      }
      // Et au moins une journee paie reellement un detour : taire les
      // vingt-deux minutes de La Halte du Prince ferait passer sa journee pour
      // plus courte qu'elle n'est.
      expect(programme.any((j) => j.minutes > _marcheSeule(j)), isTrue);
    });

    test('la journee la plus longue retrecit, PUIS BUTE SUR SON PLANCHER', () {
      final gr20 = lireGr20();
      int pireJournee(int jours) => DecoupageSurLesNuits.repartir(
        gr20,
        jours,
      ).fold<int>(0, (m, j) => j.minutes > m ? j.minutes : m);

      // C'est tout l'interet du decoupage pour le randonneur : le verdict vaut
      // la PIRE journee (GO-61), et le repos n'y change rien. Une coupure
      // relevee, elle, l'allege vraiment — jusqu'a un point.
      expect(pireJournee(16), lessThan(pireJournee(7)));

      // CE CAS ATTENDAIT `pireJournee(31) < pireJournee(16)`, ET IL A CESSE
      // D'ETRE VRAI PARCE QUE LE CALCUL S'EST AMELIORE (tache 848).
      //
      // L'ancien decoupage equilibrait mal : a seize journees il en laissait
      // une plus longue que necessaire, si bien que passer a trente et une
      // l'allegeait encore. Depuis que la repartition est OPTIMALE
      // (`RepartitionEquilibree`), seize journees atteignent DEJA le plancher,
      // et aucun nombre de jours ne peut descendre en dessous.
      //
      // LE PLANCHER N'EST PAS UN REGLAGE : c'est le plus long segment
      // INDIVISIBLE du sentier. Sur le GR20, c'est Calenzana vers l'Ortu di u
      // Piobbu — 394 minutes de marche, et aucune nuit relevee a l'interieur.
      // On ne peut pas alleger une journee qu'on ne peut pas couper, et c'est
      // exactement ce que Christophe disait le 29/09 : « couper une journer
      // c est dormir ou? ».
      final plancher = gr20.segments
          .map((s) => s.minutes)
          .reduce((a, b) => a > b ? a : b);
      expect(plancher, 394);
      expect(pireJournee(16), plancher);
      expect(pireJournee(31), plancher);
      for (var jours = 1; jours <= 31; jours++) {
        expect(
          pireJournee(jours),
          greaterThanOrEqualTo(plancher),
          reason: 'a $jours jours : le plancher ne se franchit pas',
        );
      }
    });

    test('un sentier sans releve ne change pas de comportement', () {
      expect(
        DecoupageSurLesNuits.repartir(DecoupageDeNuits.aucun, 10),
        isEmpty,
      );
      expect(DecoupageDeNuits.aucun.vide, isTrue);
      expect(DecoupageDeNuits.aucun.journeesMaximales, 0);
      // Une demande absurde ne fabrique rien.
      expect(DecoupageSurLesNuits.repartir(lireGr20(), 0), isEmpty);
      expect(DecoupageSurLesNuits.repartir(lireGr20(), -3), isEmpty);
      // Au-dela du decoupage le plus fin possible, on ne COUPE PAS PLUS : on
      // rend le plus fin. Inventer un arret de plus serait exactement la faute
      // du lot 558.
      expect(DecoupageSurLesNuits.repartir(lireGr20(), 99).length, 31);
    });
  });

  group('DurationBounds — le curseur atteint ce que les nuits permettent', () {
    test('sans releve, les bornes ne bougent pas d un pouce', () {
      final avant = DurationBounds.fromStageCount(16, recommendedRestDays: 2);
      final avec = DurationBounds.fromStageCount(
        16,
        recommendedRestDays: 2,
        walkingDaysFromNights: 0,
      );
      expect(avec.min, avant.min);
      expect(avec.max, avant.max);
      expect(avec.naturalMax, avant.naturalMax);
    });

    test('avec les trente et une nuits du GR20, la borne haute suit', () {
      final sans = DurationBounds.fromStageCount(16);
      final avec = DurationBounds.fromStageCount(16, walkingDaysFromNights: 31);
      expect(avec.max, greaterThan(sans.max));
      expect(avec.max, 31 + avec.restAllowance);
      // LA DUREE PAR DEFAUT NE BOUGE PAS : les nuits elargissent ce que le
      // randonneur PEUT choisir, elles ne changent pas ce qu'on lui propose.
      expect(avec.naturalMax, sans.naturalMax);
      expect(avec.min, sans.min);
    });
  });
}

/// Minutes de marche des seuls segments d'une journee (detour exclu).
int _marcheSeule(JourneeSurLesNuits j) =>
    j.segments.fold<int>(0, (s, x) => s + x.minutes);
