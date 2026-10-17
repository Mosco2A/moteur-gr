// GARDE — TACHE 852 : LA REMESURE DU GR20 SUR L'EFFORT COMPLET, DANS LES DEUX
// SENS, SUR LES DEUX CHAPITRES, ET AVEC LA VARIANTE BONIFATU.
//
// POURQUOI CE FICHIER EXISTE. La 852 change la regle de classement : l'effort
// d'une journee se calcule sur ses TROIS mesures, et le verdict d'un troncon
// part de sa pire journee puis peut monter d'un cran. Changer une regle sans
// remesurer ce qu'elle classe, c'est poser un mot neuf sur un chiffre ancien.
// Christophe a nomme lui-meme ce qu'il fallait remesurer : les quatre allures
// dans les deux sens, les deux chapitres, et la variante Bonifatu.
//
// DEUX CALCULS INDEPENDANTS, ET ILS DOIVENT CONCORDER. `tool/
// effort_des_journees_852.py` mesure les memes scenarios en Python et ecrit
// `assets/data/gr20/effort_852.json`. Ce fichier-ci les recalcule en DART, par
// le socle du produit (`SeuilsDeDifficulte`, `DifficulteDuSentier`,
// `RepartitionEquilibree`), et exige le MEME verdict scenario par scenario. Un
// calcul qui s'auto-atteste ne prouve rien ; deux qui tombent d'accord, si.
//
// LE SENS INVERSE NE PASSE PAS PAR `DecoupageSurLesNuits`, ET C'EST VOLONTAIRE.
// La tache 849 a trouve un defaut la : en sens inverse la derniere journee
// disparait en silence, parce qu'elle arrive a Calenzana qui n'est pas une nuit
// relevee. Ce lot-ci ne le corrige pas ; on groupe donc les segments
// directement avec le repartiteur du depot, ce qui mesure L'ECHELLE sans
// mesurer le defaut. Celui-ci reste ouvert, et il est nomme ici pour qu'il ne
// se perde pas.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/repartition_equilibree.dart';

/// Un segment entre deux nuits, reduit a ce que la mesure demande.
class Segment {
  const Segment({
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.pkDepartKm,
    required this.pkArriveeKm,
  });

  final String depart;
  final String arrivee;
  final double km;
  final int deniveleM;
  final int descenteM;
  final double pkDepartKm;
  final double pkArriveeKm;

  /// Le temps de marche du modele UNIQUE du depot — la charge du repartiteur.
  ///
  /// Il est RECALCULE et non relu, parce que le sens inverse n'a pas de temps
  /// stocke : echanger montee et descente change la duree, et c'est exactement
  /// ce qui deplace les coupes.
  double get minutes =>
      km / kWalkingKmPerHour * 60.0 +
      deniveleM * kWalkingAscentSecondsPerMetre / 60.0 +
      descenteM * kWalkingDescentSecondsPerMetre / 60.0;

  /// Le meme bout de chemin marche dans l'autre sens.
  Segment get aLEnvers => Segment(
    depart: arrivee,
    arrivee: depart,
    km: km,
    deniveleM: descenteM,
    descenteM: deniveleM,
    pkDepartKm: pkArriveeKm,
    pkArriveeKm: pkDepartKm,
  );
}

List<Segment> lireLesSegments() {
  final brut =
      jsonDecode(
            File('assets/data/gr20/nuits_possibles.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  return [
    for (final s
        in (brut['entre_les_nuits'] as List<dynamic>)
            .cast<Map<String, dynamic>>())
      Segment(
        depart: s['depart'] as String,
        arrivee: s['arrivee'] as String,
        km: (s['km'] as num).toDouble(),
        deniveleM: (s['dplus_m'] as num).round(),
        descenteM: (s['dmoins_m'] as num).round(),
        pkDepartKm: (s['pk_depart_km'] as num).toDouble(),
        pkArriveeKm: (s['pk_arrivee_km'] as num).toDouble(),
      ),
  ];
}

Map<String, dynamic> lireLaMesure() =>
    jsonDecode(File('assets/data/gr20/effort_852.json').readAsStringSync())
        as Map<String, dynamic>;

List<Segment> aLEnvers(List<Segment> segments) => [
  for (final segment in segments.reversed) segment.aLEnvers,
];

/// Les segments d'un chapitre, decoupes a la coupe declaree dans la donnee.
List<Segment> segmentsDuChapitre(List<Segment> segments, String nom) {
  final brut =
      jsonDecode(File('assets/data/gr20/chapitres.json').readAsStringSync())
          as Map<String, dynamic>;
  final chapitre = (brut['chapitres'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .firstWhere((c) => c['nom'] == nom);
  final debut = (chapitre['pkDepartDansLeSentierMere'] as num).toDouble();
  final fin = (chapitre['pkArriveeDansLeSentierMere'] as num).toDouble();
  return segments
      .where((s) => s.pkDepartKm >= debut - 0.01 && s.pkArriveeKm <= fin + 0.01)
      .toList(growable: false);
}

/// Le verdict d'un troncon a l'allure demandee, PAR LE SOCLE DU PRODUIT.
DifficulteDuSentier troncon(List<Segment> segments, int jours) {
  final cible = jours > segments.length ? segments.length : jours;
  final debuts = RepartitionEquilibree.coupes(
    segments.map((s) => s.minutes).toList(growable: false),
    cible,
  );
  final mesurees = <JourneeMesuree>[];
  for (var i = 0; i < debuts.length; i++) {
    final fin = i + 1 < debuts.length ? debuts[i + 1] : segments.length;
    final tranche = segments.sublist(debuts[i], fin);
    mesurees.add(
      JourneeMesuree(
        km: tranche.fold<double>(0, (s, x) => s + x.km),
        deniveleM: tranche.fold<int>(0, (s, x) => s + x.deniveleM),
        descenteM: tranche.fold<int>(0, (s, x) => s + x.descenteM),
      ),
    );
  }
  return DifficulteDuSentier.calculer(jours: jours, journees: mesurees)!;
}

/// Le GR20 dont le premier segment est remplace par la variante Bonifatu.
///
/// LES DEUX TRONCONS DE LA VARIANTE VIENNENT DE LA MESURE OSM DE LA TACHE 849,
/// relue dans `effort_852.json` : ils ne sont pas recalculables depuis les
/// donnees embarquees, puisqu'ils empruntent le Tra Mare e Monti et le chemin
/// de Melaghja, qui ne sont pas la trace du GR20.
List<Segment> avecLaVariante(List<Segment> segments) {
  final par =
      (lireLaMesure()['variante_bonifatu'] as Map<String, dynamic>)['par']
          as List<dynamic>;
  var pk = 0.0;
  final deux = <Segment>[];
  for (final brut in par.cast<Map<String, dynamic>>()) {
    final km = (brut['km'] as num).toDouble();
    deux.add(
      Segment(
        depart: brut['depart'] as String,
        arrivee: brut['arrivee'] as String,
        km: km,
        deniveleM: (brut['dplus_m'] as num).round(),
        descenteM: (brut['dmoins_m'] as num).round(),
        pkDepartKm: pk,
        pkArriveeKm: pk + km,
      ),
    );
    pk += km;
  }
  return [...deux, ...segments.sublist(1)];
}

void main() {
  group('852 — les deux calculs concordent, scenario par scenario', () {
    test('LE SENTIER ENTIER, DE 7 A 31 JOURS, DANS LES DEUX SENS', () {
      final segments = lireLesSegments();
      final mesure = lireLaMesure()['sentier_entier'] as Map<String, dynamic>;
      for (final sens in <String>['sens trace', 'sens inverse']) {
        final liste = sens == 'sens trace' ? segments : aLEnvers(segments);
        final table = mesure[sens] as Map<String, dynamic>;
        for (var jours = 7; jours <= 31; jours++) {
          final attendu = table['$jours'] as Map<String, dynamic>;
          final obtenu = troncon(liste, jours);
          expect(
            obtenu.verdict!.libelle.toLowerCase(),
            attendu['verdict'],
            reason: '$sens, $jours jours',
          );
          expect(
            obtenu.plancher!.libelle.toLowerCase(),
            attendu['plancher'],
            reason: '$sens, $jours jours, plancher',
          );
          expect(
            obtenu.plusLongueSuiteEnBandesHautes,
            attendu['plus_longue_suite'],
            reason: '$sens, $jours jours, suite',
          );
          expect(
            obtenu.journeesEnBandesHautes,
            attendu['journees_en_bandes_hautes'],
            reason: '$sens, $jours jours, compte',
          );
          expect(
            obtenu.pireJournee!.kmEffort,
            closeTo(
              ((attendu['pire_journee'] as Map<String, dynamic>)['km_effort']
                      as num)
                  .toDouble(),
              0.01,
            ),
            reason: '$sens, $jours jours, pire journee',
          );
        }
      }
    });

    test('LES DEUX CHAPITRES, A TOUTES LEURS ALLURES', () {
      final segments = lireLesSegments();
      final mesure = lireLaMesure()['chapitres'] as Map<String, dynamic>;
      for (final nom in <String>['GR20 Nord', 'GR20 Sud']) {
        final liste = segmentsDuChapitre(segments, nom);
        final chapitre = mesure[nom] as Map<String, dynamic>;
        expect(liste.length, chapitre['segments'], reason: '$nom, segments');
        final allures = chapitre['allures'] as Map<String, dynamic>;
        for (final entree in allures.entries) {
          final jours = int.parse(entree.key);
          final attendu = entree.value as Map<String, dynamic>;
          final obtenu = troncon(liste, jours);
          expect(
            obtenu.verdict!.libelle.toLowerCase(),
            attendu['verdict'],
            reason: '$nom, $jours jours',
          );
          expect(
            obtenu.plusLongueSuiteEnBandesHautes,
            attendu['plus_longue_suite'],
            reason: '$nom, $jours jours, suite',
          );
        }
      }
    });

    test('LE SENTIER AVEC LA VARIANTE BONIFATU, DE 7 A 32 JOURS', () {
      final segments = avecLaVariante(lireLesSegments());
      final table =
          (lireLaMesure()['variante_bonifatu']
                  as Map<String, dynamic>)['sentier_entier_avec_la_variante']
              as Map<String, dynamic>;
      for (final entree in table.entries) {
        final jours = int.parse(entree.key);
        final attendu = entree.value as Map<String, dynamic>;
        expect(
          troncon(segments, jours).verdict!.libelle.toLowerCase(),
          attendu['verdict'],
          reason: 'avec la variante, $jours jours',
        );
      }
    });
  });

  group('852 — ce que la remesure REPOND, en clair', () {
    test('NI L ALLURE NI LE SENS NE FONT DESCENDRE LE GR20', () {
      // C'EST LA PROMESSE DE LA FICHE, ET ELLE TIENT SUR L'EFFORT COMPLET. Elle
      // avait ete etablie par la 849 sur le seul denivele positif ; la 852 la
      // refait sur les trois mesures, et le resultat est le meme — a toutes les
      // allures de 7 a 31 jours, dans les deux sens, le GR20 est TRES
      // DIFFICILE.
      final segments = lireLesSegments();
      for (final liste in <List<Segment>>[segments, aLEnvers(segments)]) {
        for (var jours = 7; jours <= 31; jours++) {
          expect(
            troncon(liste, jours).verdict,
            NiveauDeDifficulte.tresDifficile,
            reason: '$jours jours',
          );
        }
      }
    });

    test('LE PLANCHER DU SENS TRACE EST LA PREMIERE JOURNEE', () {
      // Des seize jours, la journee la plus dure du sens trace EST la
      // premiere :
      // 11,349 km, 1 455 m de montee, 194 m de descente, 26,48 km-effort — et
      // elle le reste jusqu'a trente et un jours, parce qu'aucune nuit relevee
      // ne la coupe. C'est la phrase de tete de fiche, verifiee apres recalcul.
      final segments = lireLesSegments();
      for (var jours = 16; jours <= 31; jours++) {
        final pire = troncon(segments, jours).pireJournee!;
        expect(pire.numero, 1, reason: '$jours jours');
        expect(pire.deniveleM, 1455, reason: '$jours jours');
        expect(pire.kmEffort, closeTo(26.48, 0.01), reason: '$jours jours');
      }
      // EN DESSOUS DE SEIZE JOURS, CE N'EST PLUS ELLE — et il faut le dire,
      // parce que la phrase de la 849 l'affirmait des douze jours. Le
      // regroupement fabrique des journees plus lourdes qu'elle.
      for (var jours = 7; jours <= 15; jours++) {
        expect(
          troncon(segments, jours).pireJournee!.numero,
          isNot(1),
          reason: '$jours jours : la pire journee n est plus la premiere',
        );
      }
    });

    test('LE SENS INVERSE TIENT, DE PEU AU DECOUPAGE LE PLUS FIN', () {
      // A TRENTE ET UN JOURS EN SENS INVERSE, le verdict tres difficile tient
      // sur 0,08 km-effort : la pire journee est Conca vers i Paliri, soit
      // 13,209 km,
      // 1 097 m de montee et 300 m de descente, soit 25,08 km-effort contre un
      // seuil a 25,0. C'EST LA FRAGILITE DU LOT, et elle est ecrite ici plutot
      // qu'arrondie : si une mesure de trace bougeait de huit metres de montee,
      // ce verdict changerait de bande.
      final inverse = aLEnvers(lireLesSegments());
      // A TRENTE ET UN JOURS, UNE JOURNEE = UN SEGMENT : la journee qui decide
      // est donc nommable dans la donnee elle-meme, sans que le socle porte un
      // champ de nom dont aucun ecran n'a besoin.
      final segmentLePlusDur = inverse.reduce(
        (a, b) =>
            SeuilsDeDifficulte.effortDeLaJournee(
                  km: a.km,
                  deniveleM: a.deniveleM,
                  descenteM: a.descenteM,
                ) >=
                SeuilsDeDifficulte.effortDeLaJournee(
                  km: b.km,
                  deniveleM: b.deniveleM,
                  descenteM: b.descenteM,
                )
            ? a
            : b,
      );
      expect(segmentLePlusDur.depart, 'Conca');
      expect(segmentLePlusDur.arrivee, 'Refuge d\'i Paliri');
      expect(segmentLePlusDur.deniveleM, 1097);
      expect(segmentLePlusDur.descenteM, 300);

      final pire = troncon(inverse, 31).pireJournee!;
      expect(pire.deniveleM, 1097);
      expect(pire.kmEffort, closeTo(25.08, 0.01));
      expect(
        pire.kmEffort - SeuilsDeDifficulte.effortTresDifficileKm,
        lessThan(0.1),
        reason: 'la marge est inferieure a un dixieme de km-effort',
      );
      expect(troncon(inverse, 31).verdict, NiveauDeDifficulte.tresDifficile);
    });

    test('LA VARIANTE BONIFATU CHANGE DE BANDE, ET NE SUFFIT PAS', () {
      // LA QUESTION DE CHRISTOPHE : sur le seul D+ la variante ratait la bande
      // du dessous de 56 m (1 056 contre 1 000), mais elle coupe aussi la
      // distance en deux. SUR L'EFFORT COMPLET ELLE CHANGE DE BANDE : les deux
      // journees de la variante valent 19,21 et 18,63 km-effort, donc
      // DIFFICILE, la ou le segment qu'elle remplace vaut 26,48, donc TRES
      // DIFFICILE.
      final remplace = lireLesSegments().first;
      expect(
        SeuilsDeDifficulte.pourUneJournee(
          km: remplace.km,
          deniveleM: remplace.deniveleM,
          descenteM: remplace.descenteM,
        ),
        NiveauDeDifficulte.tresDifficile,
      );
      final variante = avecLaVariante(lireLesSegments()).take(2).toList();
      expect(variante.first.km, closeTo(11.738, 0.001));
      expect(variante.first.deniveleM, 632);
      expect(variante.last.km, closeTo(7.952, 0.001));
      expect(variante.last.deniveleM, 1056);
      for (final journee in variante) {
        final niveau = SeuilsDeDifficulte.pourUneJournee(
          km: journee.km,
          deniveleM: journee.deniveleM,
          descenteM: journee.descenteM,
        );
        expect(
          niveau,
          NiveauDeDifficulte.difficile,
          reason: '${journee.depart} vers ${journee.arrivee}',
        );
      }

      // ET POURTANT LE SENTIER RESTE TRES DIFFICILE JUSQU A DIX-HUIT JOURS :
      // retirer la pire journee ne suffit pas, les suivantes depassent encore
      // 25 km-effort. IL DEVIENT DIFFICILE A DIX-NEUF JOURS. C'est le prix du
      // mode facile, et c'est un prix en JOURS, pas en variante.
      final segments = avecLaVariante(lireLesSegments());
      for (var jours = 7; jours <= 18; jours++) {
        expect(
          troncon(segments, jours).verdict,
          NiveauDeDifficulte.tresDifficile,
          reason: 'avec la variante, $jours jours',
        );
      }
      expect(troncon(segments, 19).verdict, NiveauDeDifficulte.difficile);
      expect(troncon(segments, 32).verdict, NiveauDeDifficulte.difficile);
    });

    test('L ACCUMULATION SE JOUE SUR LE CHAPITRE SUD, ET ELLE LE DEPLACE', () {
      // L'ACCUMULATION NE DEPLACE QU'UNE FRONTIERE — difficile vers tres
      // difficile — et sur ce sentier elle se joue a deux endroits : le
      // chapitre SUD a sept jours, et le sentier entier AVEC la variante
      // Bonifatu a dix-sept et dix-huit jours. Le cas du sud est une vraie
      // information de vente : marche en SEPT jours il est TRES DIFFICILE —
      // sept journees des bandes hautes d'affilee — et il redevient DIFFICILE
      // des huit jours, ou la plus longue suite tombe a trois.
      final sud = segmentsDuChapitre(lireLesSegments(), 'GR20 Sud');
      final sept = troncon(sud, 7);
      expect(sept.plancher, NiveauDeDifficulte.difficile);
      expect(sept.plusLongueSuiteEnBandesHautes, 7);
      expect(sept.verdictMonteParLAccumulation, isTrue);
      expect(sept.verdict, NiveauDeDifficulte.tresDifficile);

      final huit = troncon(sud, 8);
      expect(huit.plancher, NiveauDeDifficulte.difficile);
      expect(huit.plusLongueSuiteEnBandesHautes, 3);
      expect(huit.verdictMonteParLAccumulation, isFalse);
      expect(huit.verdict, NiveauDeDifficulte.difficile);

      // LE NORD, LUI, PLAFONNE A TOUTES SES ALLURES : son plancher est deja la
      // bande du haut, l'accumulation n'a aucun cran ou monter.
      final nord = segmentsDuChapitre(lireLesSegments(), 'GR20 Nord');
      for (var jours = 5; jours <= nord.length; jours++) {
        final mesure = troncon(nord, jours);
        expect(mesure.plancher, NiveauDeDifficulte.tresDifficile);
        expect(mesure.verdictMonteParLAccumulation, isFalse);
        expect(mesure.verdict, NiveauDeDifficulte.tresDifficile);
      }
    });

    test('LE SEUIL DE LA SUITE EST ENCADRE PAR LA MESURE, DE 4 A 7', () {
      // C'EST LA JUSTIFICATION PAR LA MESURE, ET ELLE SE CALCULE ICI. Sur tous
      // les troncons mesures, seuls ceux dont le plancher est SOUS « tres
      // difficile » peuvent monter. On releve leurs suites, et on verifie que
      // tout seuil de 4 a 7 rend les memes verdicts — donc que le choix de 4
      // n'achete aucun verdict, et que 3 ou 8 en changeraient un.
      final segments = lireLesSegments();
      final troncons = <DifficulteDuSentier>[
        for (var jours = 7; jours <= 31; jours++) troncon(segments, jours),
        for (var jours = 7; jours <= 31; jours++)
          troncon(aLEnvers(segments), jours),
        for (final nom in <String>['GR20 Nord', 'GR20 Sud']) ...[
          for (
            var jours = 5;
            jours <= segmentsDuChapitre(segments, nom).length;
            jours++
          )
            troncon(segmentsDuChapitre(segments, nom), jours),
        ],
        for (var jours = 7; jours <= 32; jours++)
          troncon(avecLaVariante(segments), jours),
      ];
      final suitesQuiComptent = troncons
          .where((t) => t.plancher != NiveauDeDifficulte.tresDifficile)
          .map((t) => t.plusLongueSuiteEnBandesHautes)
          .toSet();
      // CE QUE LA MESURE RELEVE : des suites de 1, 2, 3, 7 et 8 — et AUCUNE de
      // 4, 5 ou 6.
      expect(suitesQuiComptent, <int>{1, 2, 3, 7, 8});
      // CONSEQUENCE 1 — TOUT SEUIL DE 4 A 7 REND LES MEMES VERDICTS, puisque
      // aucune suite ne tombe entre 4 et 6 : deplacer le seuil dans cet
      // intervalle ne fait changer aucun troncon de bande.
      expect(
        suitesQuiComptent.intersection(<int>{4, 5, 6}),
        isEmpty,
        reason: 'le seuil n achete aucun verdict dans [4 ; 7]',
      );
      // CONSEQUENCE 2 — 3 ET 8 CHANGERAIENT UN VERDICT, donc l'intervalle est
      // vraiment borne par la mesure et non par un gout : un seuil a 3 ferait
      // monter les troncons dont la suite vaut 3, un seuil a 8 cesserait de
      // faire monter ceux dont la suite vaut 7.
      expect(suitesQuiComptent, contains(3));
      expect(suitesQuiComptent, contains(7));
      // ET LE SEUIL RETENU EST LE BAS DE L'INTERVALLE, qui est aussi la
      // majorite de la fenetre que ce produit emploie deja.
      expect(SeuilsDeDifficulte.suiteQuiMonteLeVerdict, 4);
    });
  });
}
