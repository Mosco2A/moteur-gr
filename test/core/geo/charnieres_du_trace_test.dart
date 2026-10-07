import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/charnieres_du_trace.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';

import '../../comportement/traces_fabriquees_671.dart';

/// LOT 671-04 — LA FONCTION PURE DES CHARNIERES, CAS PAR CAS (fiche E7 (1)).
///
/// Une charniere est un point ou le cap change de plus de 50 degres sur 40 m
/// de part et d'autre, MESURES SUR L'ABSCISSE. Chaque cas limite de la fiche
/// E2 a son test, sur un trace fabrique au metre, sans aucune donnee reelle.
void main() {
  /// Un virage de [degres] a gauche au sommet (500, 0), apres 500 m vers
  /// l'est, puis 500 m apres le virage ; un point tous les 10 m.
  List<TrackPoint> virageDe(double degres) {
    final apres = auCap(500, 0, 90 - degres, 500);
    return traceDesSommets([(0, 0), (500, 0), apres]);
  }

  /// 500 m vers l'est, puis le lacet, puis 500 m dans l'axe de sa derniere
  /// branche : le lacet est au milieu du trace.
  List<TrackPoint> traceAuLacet() {
    final epingles = lacet(500, 0);
    final (x, y) = epingles.last;
    return traceDesSommets([
      (0, 0),
      (500, 0),
      ...epingles,
      auCap(x, y, 300, 500),
    ]);
  }

  group('la definition geometrique', () {
    test('un virage de 60 degres sur 40 m EST une charniere, une seule, au '
        'sommet', () {
      final c = charnieresDuTrace(virageDe(60));
      expect(c, hasLength(1));
      expect(c.single.abscisseM, closeTo(500, 1));
      expect(c.single.virageDegres!.abs(), closeTo(60, 1));
      expect(c.single.enrichie, isFalse);
    });

    test('un virage de 40 degres n en est PAS une', () {
      expect(charnieresDuTrace(virageDe(40)), isEmpty);
    });

    test('un virage de 60 degres ETALE SUR 400 m n en est PAS une : les 40 m '
        'se mesurent bien en abscisse, pas en nombre de points', () {
      // Un arc : 40 cordes de 10 m, chacune tourne de 1,5 degre.
      final sommets = <(double, double)>[(0, 0), (500, 0)];
      var cap = 90.0;
      for (var k = 0; k < 40; k++) {
        cap -= 1.5;
        final (x, y) = sommets.last;
        sommets.add(auCap(x, y, cap, 10));
      }
      final (x, y) = sommets.last;
      sommets.add(auCap(x, y, cap, 500));
      expect(charnieresDuTrace(traceDesSommets(sommets)), isEmpty);
    });

    test('le meme virage de 60 degres donne la meme charniere, que le trace '
        'ait un point tous les 2 m ou tous les 25 m', () {
      final apres = auCap(500, 0, 30, 500);
      for (final pas in [2.0, 25.0]) {
        final c = charnieresDuTrace(
          traceDesSommets([(0, 0), (500, 0), apres], pas: pas),
        );
        expect(c, hasLength(1), reason: 'pas de $pas m');
        expect(c.single.abscisseM, closeTo(500, 1), reason: 'pas de $pas m');
      }
    });
  });

  group('LE FRANCHISSEMENT DU NORD — sans lui la fonction est fausse', () {
    test('un cap qui passe de 350 a 40 degres est un virage de 50 degres, '
        'PAS de 310', () {
      expect(ecartDeCaps(350, 40), closeTo(50, 1e-9));
      expect(ecartDeCaps(40, 350), closeTo(-50, 1e-9));
      expect(ecartDeCaps(10, 190), closeTo(180, 1e-9));
    });

    test('un virage de 10 degres qui franchit le nord (355 -> 5) n est PAS '
        'une charniere, et un de 60 degres (340 -> 40) en est une', () {
      final pli = auCap(0, 0, 355, 400);
      final douce = traceDesSommets([
        (0, 0),
        pli,
        auCap(pli.$1, pli.$2, 5, 400),
      ]);
      expect(charnieresDuTrace(douce), isEmpty);
      final sommet = auCap(0, 0, 340, 400);
      final franche = traceDesSommets([
        (0, 0),
        sommet,
        auCap(sommet.$1, sommet.$2, 40, 400),
      ]);
      final c = charnieresDuTrace(franche);
      expect(c, hasLength(1));
      expect(c.single.virageDegres, closeTo(60, 1));
    });
  });

  group('les cinq cas limites', () {
    test('un trace de moins de 2 points est REFUSE, comme project', () {
      expect(() => charnieresDuTrace(const []), throwsArgumentError);
      expect(
        () => charnieresDuTrace(traceDesPoints([(0, 0)])),
        throwsArgumentError,
      );
    });

    test('un trace de moins de 80 m : liste vide, sans erreur', () {
      final court = traceDesSommets([(0, 0), (35, 0), (35, 35)]);
      expect(court.last.distanceFromStart, lessThan(80));
      expect(charnieresDuTrace(court), isEmpty);
    });

    test('les 40 premiers et les 40 derniers metres ne portent aucune '
        'charniere', () {
      // Equerres a 30 m du depart et a 30 m de l'arrivee : hors d'atteinte.
      final t = traceDesSommets([(0, 0), (30, 0), (30, 300), (0, 300)]);
      expect(charnieresDuTrace(t), isEmpty);
    });

    test('un doublon AU MILIEU d une ligne droite et un doublon JUSTE AVANT '
        'une charniere : enjambes, sans division ni boucle', () {
      final plan = <(double, double)>[
        for (var x = 0.0; x <= 500; x += 10) (x, 0),
      ];
      final sommet = plan.length - 1;
      final apres = <(double, double)>[
        for (var k = 1; k <= 50; k++) auCap(500, 0, 30, k * 10.0),
      ];
      final avecDoublons = [
        ...plan.sublist(0, 25),
        plan[24], // doublon au milieu de la ligne droite
        ...plan.sublist(25, sommet),
        plan[sommet - 1], // doublon juste avant la charniere
        plan[sommet],
        ...apres,
      ];
      final c = charnieresDuTrace(traceDesPoints(avecDoublons));
      expect(c, hasLength(1));
      expect(c.single.abscisseM, closeTo(500, 1));
      expect(c.single.virageDegres!.isFinite, isTrue);
    });

    test('un trace qui se replie sur lui-meme : deux passages, deux '
        'charnieres a deux abscisses differentes', () {
      // Aller 400 m vers l'est, equerre, 100 m au nord, demi-tour par une
      // seconde equerre, puis retour sur la MEME portion.
      final t = traceDesSommets([
        (0, 0),
        (400, 0),
        (400, 100),
        (400, 0),
        (0, 0),
      ]);
      final c = charnieresDuTrace(t);
      final enEquerre = c.where((x) => (x.lat - c.first.lat).abs() < 1e-7);
      expect(enEquerre.length, 2, reason: 'le sommet (400, 0) passe deux fois');
      expect(enEquerre.first.abscisseM, closeTo(400, 1));
      expect(enEquerre.last.abscisseM, closeTo(600, 1));
    });

    test('deux epingles collees d un lacet sont DEUX charnieres', () {
      final t = traceAuLacet();
      final c = charnieresDuTrace(t);
      final epingles = c.where((x) => x.virageDegres!.abs() > 100).toList();
      expect(epingles, hasLength(5));
      for (var k = 1; k < epingles.length; k++) {
        expect(
          epingles[k].abscisseM - epingles[k - 1].abscisseM,
          closeTo(80, 1),
        );
      }
    });
  });

  group('l enrichissement par la donnee, facultatif par construction', () {
    test('ZERO donnee enrichie : la fonction rend sa liste, c est le cas par '
        'defaut puisque aucun sentier ne declare de jonction', () {
      final c = charnieresDuTrace(virageDe(60));
      expect(c.where((x) => x.enrichie), isEmpty);
      expect(c, hasLength(1));
    });

    test('une jonction deja projetee s ajoute, triee par abscisse', () {
      final c = charnieresDuTrace(
        virageDe(60),
        enrichies: const [
          Charniere.enrichie(abscisseM: 120, lat: 42.0, lng: 9.0),
        ],
      );
      expect(c.map((x) => x.enrichie), [true, false]);
      expect(c.first.virageDegres, isNull);
    });
  });

  group('les fenetres, en abscisse, et leur fusion', () {
    /// Les metres de trace sous fenetre.
    double metresSous(List<FenetreDeCharniere> fenetres) =>
        fenetres.fold(0, (somme, f) => somme + f.largeurM);

    TrackAbscissa a(double m) =>
        (lat: 0, lng: 0, altitude: 0, segmentIndex: 0, distanceFromStartM: m);

    test('une charniere isolee ouvre 150 m avant et ferme 150 m apres', () {
      final t = virageDe(60);
      final f = fenetresDesCharnieres(
        charnieresDuTrace(t),
        longueurM: t.last.distanceFromStart,
      );
      expect(f, hasLength(1));
      expect(f.single.debutM, closeTo(350, 1));
      expect(f.single.finM, closeTo(650, 1));
      expect(fenetreOu(f, a(349)), isNull);
      expect(fenetreOu(f, a(351)), same(f.single));
      expect(fenetreOu(f, a(649)), same(f.single));
      expect(fenetreOu(f, a(651)), isNull);
    });

    test('LE LACET : cinq epingles a 80 m font UNE fenetre de 620 m, pas '
        'cinq', () {
      final t = traceAuLacet();
      final c = charnieresDuTrace(t);
      final f = fenetresDesCharnieres(c, longueurM: t.last.distanceFromStart);
      expect(c.length, greaterThanOrEqualTo(5));
      final duLacet = f.where((x) => x.charnieres.length >= 5).toList();
      expect(duLacet, hasLength(1));
      // 4 x 80 m entre la premiere et la derniere epingle, + 150 + 150.
      expect(duLacet.single.largeurM, closeTo(620, 2));
      // Sans la fusion, cinq fenetres de 300 m auraient compte 1 500 m.
      expect(metresSous(duLacet), lessThan(5 * 300));
    });

    test('une fenetre est bornee aux extremites du trace', () {
      final f = fenetresDesCharnieres(const [
        Charniere.enrichie(abscisseM: 60, lat: 0, lng: 0),
        Charniere.enrichie(abscisseM: 960, lat: 0, lng: 0),
      ], longueurM: 1000);
      expect(f.first.debutM, 0);
      expect(f.last.finM, 1000);
    });
  });
}
