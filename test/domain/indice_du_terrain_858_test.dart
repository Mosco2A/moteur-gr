// GARDE — TACHE 858 : LA LOI DE L'INDICE DE TERRAIN, PROPRIETE PAR PROPRIETE.
//
// CE QUE CE FICHIER PROUVE, ET POURQUOI CHAQUE PREUVE EST DEMANDEE. L'indice
// de terrain melange deux choses de statut different : un socle MESURE (Minetti
// 2002, Table 2) et une majoration ASSUMEE (la continuite d'une montee, qu'
// aucune source ne chiffre). Un nombre dont on ne sait plus ce qui est mesure
// est un nombre qu'on finit par croire sur parole. Les tests ci-dessous
// verifient donc, dans l'ordre :
//
//   1. que le socle est bien la mesure et RIEN D'AUTRE — les treize pentes
//      mesurees sont rendues au centieme, et les trois pentes que le mandat
//      citait (5, 15, 25 %) sont annoncees pour ce qu'elles sont :
//      interpolees ;
//   2. que la part assumee S'ETEINT ENTIEREMENT a beta = 1, exigence explicite
//      de Christophe — l'indice redevient alors 100 % mesure ;
//   3. que la couture des montees fait ce qu'il a decide : deux montees
//      separees par moins d'un quart d'heure de terrain REPOSANT comptent pour
//      une, et la descente raide ne repose personne ;
//   4. que l'additivite est EXACTE aux frontieres de montee et SOUS-ADDITIVE a
//      l'interieur, avec le deficit en forme CLOSE — c'est la valeur d'une nuit
//      posee a mi-pente, et elle ne doit pas se corriger par accident.
library;

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/facteur_de_pente_minetti.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';

/// Un morceau de terrain de pente et de denivele donnes, pose a la suite du
/// precedent : de quoi fabriquer un sentier d'essai dont on connait la reponse.
SegmentDeProfil morceau({
  required double deniveleM,
  required double pente,
  double pkDebutM = 0.0,
}) => SegmentDeProfil(
  pkDebutM: pkDebutM,
  longueurM: deniveleM / pente,
  deniveleM: deniveleM,
);

/// Un sentier d'essai : les morceaux poses bout a bout, chacun au point
/// kilometrique ou le precedent s'arrete.
List<SegmentDeProfil> sentier(List<SegmentDeProfil> morceaux) {
  final out = <SegmentDeProfil>[];
  var pk = 0.0;
  for (final m in morceaux) {
    out.add(
      SegmentDeProfil(
        pkDebutM: pk,
        longueurM: m.longueurM,
        deniveleM: m.deniveleM,
      ),
    );
    pk += m.longueurM;
  }
  return out;
}

void main() {
  group('858 — le socle est la mesure de Minetti, et rien de plus', () {
    test('LES TREIZE PENTES MESUREES SONT RENDUES EXACTEMENT', () {
      const pentes = FacteurDePenteMinetti.pentesMesurees;
      const couts = FacteurDePenteMinetti.coutsMesuresJParKgParM;
      expect(pentes, hasLength(13));
      expect(couts, hasLength(13));
      for (var i = 0; i < pentes.length; i++) {
        expect(
          FacteurDePenteMinetti.coutJParKgParM(pentes[i]),
          closeTo(couts[i], 1e-9),
          reason:
              'la courbe doit PASSER par la mesure de ${pentes[i]}, pas '
              'passer a cote',
        );
        expect(FacteurDePenteMinetti.mesuree(pentes[i]), isTrue);
      }
    });

    test('L UNITE EST LE KILOMETRE DE PLAT : 1,000 point par km a plat', () {
      expect(
        FacteurDePenteMinetti.coutDuPlatJParKgParM,
        1.64,
        reason: 'Table 2 : le plat coute 1,64 J/kg/m',
      );
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.0),
        closeTo(1.0, 1e-12),
      );
    });

    test('LA DESCENTE DOUCE COUTE LA MOITIE DU PLAT, et c est la mesure qui '
        'le dit', () {
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(-0.10),
        closeTo(0.494, 0.001),
        reason: '0,81 J/kg/m mesure a -10 % contre 1,64 a plat',
      );
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.10),
        closeTo(2.854, 0.001),
      );
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.45),
        closeTo(10.567, 0.001),
      );
    });

    test('LES TROIS PENTES DU MANDAT — 5, 15 ET 25 % — SONT INTERPOLEES, ET '
        'LE CODE LE DIT', () {
      for (final pente in <double>[0.05, 0.15, 0.25]) {
        expect(
          FacteurDePenteMinetti.mesuree(pente),
          isFalse,
          reason:
              'Minetti n a PAS mesure ${pente * 100} % : l annoncer mesure '
              'serait un mensonge de plus dans une chaine de mesures',
        );
      }
      // Les valeurs interpolees, pour que leur derive se voie.
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.05),
        closeTo(1.782, 0.001),
      );
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.15),
        closeTo(3.880, 0.001),
      );
      expect(
        FacteurDePenteMinetti.pointsParKmDeTrajet(0.25),
        closeTo(5.925, 0.001),
      );
    });

    test('LA COURBE EST MONOTONE ENTRE DEUX MESURES : aucune descente moins '
        'chere que la moins chere mesuree', () {
      var minimum = double.infinity;
      for (var p = -0.45; p <= 0.0; p += 0.005) {
        minimum = math.min(minimum, FacteurDePenteMinetti.coutJParKgParM(p));
      }
      expect(
        minimum,
        greaterThanOrEqualTo(0.81 - 1e-9),
        reason:
            'une spline ordinaire creuserait sous 0,81 J/kg/m autour de '
            '-10 % : Fritsch-Carlson l interdit',
      );
    });

    test('LE SEUIL DU TERRAIN REPOSANT EST LU SUR LA COURBE : -24,3 %', () {
      // Resolu ici, pas recopie : si la courbe bouge, ce test rougit.
      var bas = -0.30;
      var haut = -0.20;
      for (var i = 0; i < 200; i++) {
        final milieu = (bas + haut) / 2;
        if (FacteurDePenteMinetti.coutJParKgParM(milieu) >
            FacteurDePenteMinetti.coutDuPlatJParKgParM) {
          bas = milieu;
        } else {
          haut = milieu;
        }
      }
      expect(
        (bas + haut) / 2,
        closeTo(FacteurDePenteMinetti.penteOuLaDescenteCouteLePlat, 0.0005),
      );
    });

    test('CE QUI REPOSE ET CE QUI NE REPOSE PAS : le plat et la descente '
        'douce reposent, la raide non, la montee jamais', () {
      expect(FacteurDePenteMinetti.terrainReposant(0.0), isTrue);
      expect(FacteurDePenteMinetti.terrainReposant(-0.10), isTrue);
      expect(FacteurDePenteMinetti.terrainReposant(-0.20), isTrue);
      expect(
        FacteurDePenteMinetti.terrainReposant(-0.30),
        isFalse,
        reason: 'a -30 % la descente coute 1,33 km de plat : elle fatigue',
      );
      expect(
        FacteurDePenteMinetti.terrainReposant(0.01),
        isFalse,
        reason: 'une montee, meme d un pour cent, coute plus que le plat',
      );
    });
  });

  group('858 — la part assumee est reglable, et elle S ETEINT a beta = 1', () {
    test('A BETA = 1 LA MAJORATION EST IDENTIQUEMENT NULLE, quelle que soit '
        'la montee', () {
      for (final denivele in <double>[50, 200, 550, 1000, 2060, 5000]) {
        expect(
          LoiDeLIndice.entierementMesuree.facteurDeContinuite(denivele),
          closeTo(0.0, 1e-12),
          reason: 'beta = 1 doit annuler la majoration, pas la reduire',
        );
      }
    });

    test('A BETA = 1 L INDICE EST EXACTEMENT SON SOCLE MESURE — sur un '
        'sentier d essai qui enchaine montee, plat et descente', () {
      final terrain = sentier([
        morceau(deniveleM: 1200, pente: 0.22),
        morceau(deniveleM: -40, pente: -0.02),
        morceau(deniveleM: -900, pente: -0.28),
        morceau(deniveleM: 300, pente: 0.12),
      ]);
      final mesure = IndiceDuTerrain.calculer(
        terrain: terrain,
        loi: LoiDeLIndice.entierementMesuree,
      );
      expect(mesure.majorationDeContinuite, closeTo(0.0, 1e-12));
      expect(mesure.indice, closeTo(mesure.socleMesure, 1e-12));
      expect(mesure.partAssumee, closeTo(0.0, 1e-12));
      // Et le socle ne depend PAS de beta : c'est la mesure.
      final retenue = IndiceDuTerrain.calculer(terrain: terrain);
      expect(retenue.socleMesure, closeTo(mesure.socleMesure, 1e-12));
      expect(
        retenue.majorationDeContinuite,
        isNot(closeTo(0.0, 0.01)),
        reason: 'la loi retenue, elle, majore : sinon ce test ne prouve rien',
      );
    });

    test('LA DECISION DE CHRISTOPHE EST TENUE : une montee de 1 000 m vaut '
        '2,38 fois une montee de 500 m a pente egale', () {
      final cinqCents = IndiceDuTerrain.calculer(
        terrain: sentier([morceau(deniveleM: 500, pente: 0.20)]),
      );
      final mille = IndiceDuTerrain.calculer(
        terrain: sentier([morceau(deniveleM: 1000, pente: 0.20)]),
      );
      expect(cinqCents.monteesContinues, 1);
      expect(mille.monteesContinues, 1);
      expect(
        mille.indice / cinqCents.indice,
        closeTo(2.38, 0.01),
        reason:
            'decision du 18/10 19:34 : « franchement plus que le double », '
            'et 1,25 rend 2,38',
      );
      // Le socle seul, lui, est exactement proportionnel : c'est la mesure de
      // Minetti qui le dit, et c'est pour cela que la majoration est assumee.
      expect(mille.socleMesure / cinqCents.socleMesure, closeTo(2.0, 1e-9));
    });

    test('LA PART ASSUMEE SE CHIFFRE, et elle reste minoritaire sur une '
        'grosse journee', () {
      final journee = IndiceDuTerrain.calculer(
        terrain: sentier([
          morceau(deniveleM: 1454, pente: 0.19),
          morceau(deniveleM: -194, pente: -0.15),
        ]),
      );
      expect(journee.partAssumee, lessThan(0.35));
      expect(journee.majorationDeContinuite, greaterThan(0.0));
    });
  });

  group('858 — la couture des montees : un quart d heure de terrain '
      'REPOSANT', () {
    test('LE CAS DE CHRISTOPHE, MOT POUR MOT : 500 m de plat entre deux '
        'montees de 700 m font UNE montee de 1 400 m', () {
      final deuxFoisSeptCents = IndiceDuTerrain.calculer(
        terrain: sentier([
          morceau(deniveleM: 700, pente: 0.20),
          const SegmentDeProfil(pkDebutM: 0, longueurM: 500, deniveleM: 0),
          morceau(deniveleM: 700, pente: 0.20),
        ]),
      );
      expect(
        deuxFoisSeptCents.monteesContinues,
        1,
        reason:
            '500 m de plat font 7,5 minutes, donc moins d un quart d heure : '
            'la montee continue (question du 18/10 15:33, reponse du 19:36)',
      );
      expect(deuxFoisSeptCents.plusGrosseMonteeM, closeTo(1400, 1e-9));
    });

    test('UN REPIT PLUS LONG QU UN QUART D HEURE COUPE LA MONTEE EN DEUX', () {
      final avecUnVraiRepit = IndiceDuTerrain.calculer(
        terrain: sentier([
          morceau(deniveleM: 700, pente: 0.20),
          const SegmentDeProfil(pkDebutM: 0, longueurM: 2000, deniveleM: 0),
          morceau(deniveleM: 700, pente: 0.20),
        ]),
      );
      expect(
        avecUnVraiRepit.monteesContinues,
        2,
        reason: '2 km de plat font trente minutes : la montee s arrete',
      );
      expect(avecUnVraiRepit.plusGrosseMonteeM, closeTo(700, 1e-9));
    });

    test('LA DESCENTE RAIDE NE REPOSE PERSONNE, LA DOUCE SI — meme longueur, '
        'verdict oppose', () {
      final apresUneDescenteRaide = IndiceDuTerrain.calculer(
        terrain: sentier([
          morceau(deniveleM: 700, pente: 0.20),
          morceau(deniveleM: -300, pente: -0.30),
          morceau(deniveleM: 700, pente: 0.20),
        ]),
      );
      final apresUneDescenteDouce = IndiceDuTerrain.calculer(
        terrain: sentier([
          morceau(deniveleM: 700, pente: 0.20),
          morceau(deniveleM: -100, pente: -0.10),
          morceau(deniveleM: 700, pente: 0.20),
        ]),
      );
      expect(
        apresUneDescenteRaide.monteesContinues,
        1,
        reason:
            'un kilometre a -30 % coute PLUS qu un kilometre de plat : il ne '
            'donne aucun repit, et la montee continue',
      );
      expect(
        apresUneDescenteDouce.monteesContinues,
        2,
        reason:
            'un kilometre a -10 % coute la moitie du plat : il repose, et il '
            'dure plus d un quart d heure',
      );
    });

    test('L HORLOGE DU REPIT NE SERT QU A CA, et elle se lit : un kilometre '
        'de plat vaut quinze minutes', () {
      const loi = LoiDeLIndice.retenue;
      const unKmDePlat = SegmentDeProfil(
        pkDebutM: 0,
        longueurM: 1000,
        deniveleM: 0,
      );
      expect(loi.minutesDeRepit(unKmDePlat), closeTo(15.0, 1e-9));
      expect(loi.repitQuiCoupeUneMonteeMinutes, 15.0);
      // Et la descente repose MOINS vite que le plat, a longueur egale.
      const unKmEnDescente = SegmentDeProfil(
        pkDebutM: 0,
        longueurM: 1000,
        deniveleM: -150,
      );
      expect(
        loi.minutesDeRepit(unKmEnDescente),
        greaterThan(loi.minutesDeRepit(unKmDePlat)),
      );
    });

    test('UNE MONTEE D UN SEUL TENANT RESTE UNE SEULE MONTEE, quel que soit '
        'le nombre de morceaux qui la decrivent', () {
      final enUnMorceau = IndiceDuTerrain.calculer(
        terrain: sentier([morceau(deniveleM: 1000, pente: 0.20)]),
      );
      final enDixMorceaux = IndiceDuTerrain.calculer(
        terrain: sentier([
          for (var i = 0; i < 10; i++) morceau(deniveleM: 100, pente: 0.20),
        ]),
      );
      expect(enDixMorceaux.monteesContinues, 1);
      expect(enDixMorceaux.indice, closeTo(enUnMorceau.indice, 1e-9));
    });
  });

  group('858 — l additivite : exacte aux frontieres, sous-additive dedans', () {
    test('LE SOCLE MESURE EST EXACTEMENT ADDITIF, OU QU ON COUPE', () {
      final terrain = sentier([
        morceau(deniveleM: 900, pente: 0.18),
        morceau(deniveleM: -600, pente: -0.22),
        morceau(deniveleM: 400, pente: 0.10),
      ]);
      final profil = ProfilDuTerrain(terrain);
      final tout = IndiceDuTerrain.calculer(terrain: terrain);
      for (var k = 1; k < 40; k++) {
        final coupe = profil.longueurM * k / 40.0;
        final avant = IndiceDuTerrain.calculer(
          terrain: profil.tranche(pkDebutM: 0, pkFinM: coupe),
        );
        final apres = IndiceDuTerrain.calculer(
          terrain: profil.tranche(pkDebutM: coupe, pkFinM: profil.longueurM),
        );
        expect(
          avant.socleMesure + apres.socleMesure,
          closeTo(tout.socleMesure, 1e-9),
          reason: 'le socle est une integrale : il ne connait pas les coupures',
        );
      }
    });

    test('A LA FRONTIERE D UNE MONTEE, L INDICE COMPLET EST EXACTEMENT '
        'ADDITIF — ecart nul', () {
      final premiere = sentier([morceau(deniveleM: 800, pente: 0.20)]);
      final suite = sentier([
        const SegmentDeProfil(pkDebutM: 0, longueurM: 2500, deniveleM: 0),
        morceau(deniveleM: 600, pente: 0.15),
      ]);
      final terrain = sentier([...premiere, ...suite]);
      final tout = IndiceDuTerrain.calculer(terrain: terrain);
      final morceau1 = IndiceDuTerrain.calculer(terrain: premiere);
      final morceau2 = IndiceDuTerrain.calculer(terrain: suite);
      expect(tout.monteesContinues, 2);
      expect(
        morceau1.indice + morceau2.indice,
        closeTo(tout.indice, 1e-9),
        reason:
            'couper la ou une montee finit ne change RIEN : c est ce qui rend '
            'un decoupage chiffrable journee par journee',
      );
    });

    test('A L INTERIEUR D UNE MONTEE, LE DEFICIT EST CELUI DE LA FORME '
        'CLOSE : 1 - 2^(1-beta), soit 15,9 %', () {
      final montee = sentier([morceau(deniveleM: 1000, pente: 0.20)]);
      final profil = ProfilDuTerrain(montee);
      final dUnTrait = IndiceDuTerrain.calculer(terrain: montee);
      final moitie = profil.longueurM / 2;
      final premiereMoitie = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: 0, pkFinM: moitie),
      );
      final secondeMoitie = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: moitie, pkFinM: profil.longueurM),
      );
      final enDeux = premiereMoitie.indice + secondeMoitie.indice;
      final deficit = (dUnTrait.indice - enDeux) / dUnTrait.indice;
      final attendu = 1 - math.pow(2, 1 - LoiDeLIndice.retenue.beta).toDouble();
      expect(deficit, closeTo(attendu, 1e-9));
      expect(
        deficit,
        closeTo(0.159, 0.001),
        reason:
            'dormir au milieu d une montee rend le chemin REELLEMENT plus '
            'facile : ce deficit est l information, pas un defaut',
      );
    });

    test('UN TERRAIN VIDE N A PAS D INDICE, et il ne vaut pas zero par '
        'hasard', () {
      expect(ProfilDuTerrain.vide.estVide, isTrue);
      expect(ProfilDuTerrain.vide.longueurM, 0.0);
      final rien = IndiceDuTerrain.calculer(
        terrain: ProfilDuTerrain.vide.tranche(pkDebutM: 0, pkFinM: 100),
      );
      expect(rien.indice, IndiceDuTerrain.aucun.indice);
      expect(rien.monteesContinues, 0);
    });

    test('UN MORCEAU REDUIT GARDE SA PENTE, et c est ce qui rend la coupure '
        'honnete', () {
      const entier = SegmentDeProfil(
        pkDebutM: 0,
        longueurM: 1000,
        deniveleM: 200,
      );
      final moitie = entier.fraction(depuisM: 0, part: 0.5);
      expect(moitie.pente, closeTo(entier.pente, 1e-12));
      expect(moitie.longueurM, closeTo(500, 1e-12));
      expect(moitie.deniveleM, closeTo(100, 1e-12));
      expect(entier.longueurDeTrajetM, greaterThan(entier.longueurM));
      expect(entier.monte, isTrue);
      expect(entier.pkFinM, 1000.0);
    });
  });
}
