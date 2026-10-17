import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

/// LE SENS DE MARCHE ET LE PLANCHER DU GR20, MESURES (tache 849).
///
/// POURQUOI CE FICHIER EXISTE. La tache 848 a etabli que la pire journee du
/// GR20 ne descend jamais sous 1 455 m de montee, parce que le premier segment
/// — Calenzana vers le refuge de l\'Ortu di u Piobbu, 11,349 km et 1 455 m —
/// ne porte aucune nuit a son interieur et ne peut donc pas etre coupe. Ce
/// raisonnement valait POUR UN SEUL SENS DE MARCHE, celui de la trace
/// (Calenzana vers Conca), et SOUS RESERVE qu\'aucune nuit n\'existe dans ce
/// premier segment. La tache 849 a leve les deux reserves et les deux
/// repondent dans le meme sens.
///
/// CE QUE L\'INVERSION EST, EXACTEMENT, ET POURQUOI ELLE EST LEGITIME. Chaque
/// segment porte son denivele positif ET son denivele negatif, mesures
/// separement sur la trace (tache 839). Marcher le segment a l\'envers echange
/// les deux : la suite d\'altitudes est la meme, lue dans l\'autre sens, donc
/// chaque montee devient une descente de la meme hauteur. Le filtre de
/// denivele de la 838 est symetrique (fenetre centree, et les DEUX bouts
/// ancres sur l\'altitude reelle), donc l\'echange est exact et non approche.
/// Le temps de marche, lui, est RECALCULE et non echange : le modele unique du
/// depot ne paie pas la descente au meme prix que la montee (9 s par metre
/// monte contre 1,667 s par metre descendu), donc un segment ne dure pas le
/// meme temps dans les deux sens.
///
/// CE QUI NE S\'INVERSE PAS, ET C\'EST UN PIEGE EVITE. Le detour vers un
/// couchage ne change pas de sens quand le sentier en change : on quitte la
/// trace pour aller dormir le soir et on y remonte le matin, dans les deux sens
/// de marche. [NuitPossible.minutesAller] et [NuitPossible.minutesRetour]
/// restent donc tels quels — les echanger aurait fabrique une asymetrie qui
/// n\'existe pas.
void main() {
  DecoupageDeNuits lire(String chemin) {
    final file = File(chemin);
    expect(file.existsSync(), isTrue, reason: '$chemin absent');
    return DecoupageDeNuits.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  /// Le temps de marche d\'un segment, par LE modele du depot.
  int minutesDuSegment(double km, int dplus, int dmoins) =>
      (walkingSeconds(
                distanceMetres: km * 1000.0,
                ascentMetres: dplus.toDouble(),
                descentMetres: dmoins.toDouble(),
              ) /
              60.0)
          .round();

  /// Le meme sentier, marche a l\'envers.
  ///
  /// L\'ordre des segments s\'inverse, chaque segment echange son depart et son
  /// arrivee ainsi que ses deux deniveles, et son temps de marche est
  /// RECALCULE.
  /// La tete de sentier devient Conca ; Calenzana, qui etait la tete de sentier
  /// et n\'est donc pas dans la liste des nuits, devient l\'ARRIVEE du dernier
  /// jour et doit y entrer — sans quoi le decoupage laisse tomber ce jour-la,
  /// ce qu\'un cas ci-dessous mesure nommement.
  DecoupageDeNuits aLEnvers(DecoupageDeNuits avant) {
    final segments = <SegmentEntreNuits>[];
    for (var i = avant.segments.length - 1; i >= 0; i--) {
      final s = avant.segments[i];
      segments.add(
        SegmentEntreNuits(
          rang: segments.length + 1,
          depart: s.arrivee,
          arrivee: s.depart,
          km: s.km,
          deniveleM: s.descenteM,
          descenteM: s.deniveleM,
          minutes: minutesDuSegment(s.km, s.descenteM, s.deniveleM),
        ),
      );
    }
    final nuits = <NuitPossible>[
      ...avant.nuits.reversed,
      NuitPossible(
        nom: avant.teteDeSentier,
        osm: const <String>[],
        pkKm: 0,
        altitudeM: 0,
        lat: 0,
        lon: 0,
        minutesAller: 0,
        minutesRetour: 0,
        lits: null,
        finDEtape: null,
      ),
    ];
    return DecoupageDeNuits(
      trailId: avant.trailId,
      teteDeSentier: avant.segments.last.arrivee,
      nuits: nuits,
      segments: segments,
    );
  }

  ({int dplus, int numero, int journees}) pireJournee(
    DecoupageDeNuits decoupage,
    int jours,
  ) {
    final journees = DecoupageSurLesNuits.repartir(decoupage, jours);
    var pire = -1;
    var numero = -1;
    for (final j in journees) {
      if (j.deniveleM > pire) {
        pire = j.deniveleM;
        numero = j.numero;
      }
    }
    return (dplus: pire, numero: numero, journees: journees.length);
  }

  const cheminNuits = 'assets/data/gr20/nuits_possibles.json';
  const cheminInsertion = 'assets/data/gr20/nuits_avec_insertion_849.json';

  group('Le sens de marche du GR20, mesure (tache 849)', () {
    test('les 31 segments se relisent, et leur temps colle au modele', () {
      final nuits = lire(cheminNuits);
      expect(nuits.segments.length, 31);
      expect(nuits.nuits.length, 31);
      expect(nuits.teteDeSentier, 'Calenzana');
      for (final s in nuits.segments) {
        expect(
          minutesDuSegment(s.km, s.deniveleM, s.descenteM),
          s.minutes,
          reason:
              'le temps du segment ${s.rang} ne vient pas du modele du depot',
        );
      }
    });

    test('LE PREMIER SEGMENT EST LE PLANCHER DU SENS DE LA TRACE, et il tombe '
        'a l\'envers', () {
      final nuits = lire(cheminNuits);
      final premier = nuits.segments.first;
      expect(premier.depart, 'Calenzana');
      expect(premier.deniveleM, 1455);
      expect(premier.descenteM, 194);

      // Le MEME segment, marche a l\'envers : la montee devient la descente.
      final envers = aLEnvers(nuits);
      final dernier = envers.segments.last;
      expect(dernier.arrivee, 'Calenzana');
      expect(dernier.deniveleM, 194, reason: 'a l\'envers, on DESCEND ici');
      expect(dernier.descenteM, 1455);

      // Et le segment le plus montant du sens inverse est ailleurs : c\'est
      // Conca vers i Paliri, la derniere etape du sentier marchee a l\'envers.
      final pireSegmentEnvers = envers.segments
          .map((s) => s.deniveleM)
          .reduce((a, b) => a > b ? a : b);
      expect(pireSegmentEnvers, 1097);
      expect(envers.segments.first.depart, 'Conca');
    });

    test('LE DECOUPAGE PERD LE DERNIER JOUR EN SENS INVERSE quand Calenzana '
        'n\'est pas une nuit', () {
      // C\'est un DEFAUT MESURE, pas une curiosite : le decoupage cherche la
      // nuit d\'arrivee de chaque journee par son nom et laisse tomber la
      // journee quand il ne la trouve pas. En sens inverse la derniere
      // journee arrive a Calenzana, qui est la TETE DE SENTIER et n\'est donc
      // pas dans la liste des nuits : la journee disparait EN SILENCE, et le
      // client qui demande seize jours en recoit quinze.
      final nuits = lire(cheminNuits);
      final sansCalenzana = DecoupageDeNuits(
        trailId: nuits.trailId,
        teteDeSentier: nuits.segments.last.arrivee,
        nuits: nuits.nuits.reversed.toList(growable: false),
        segments: aLEnvers(nuits).segments,
      );
      expect(
        DecoupageSurLesNuits.repartir(sansCalenzana, 16).length,
        15,
        reason:
            'seize journees demandees, quinze rendues : la derniere arrive '
            'a Calenzana et le decoupage ne la reconnait pas',
      );
      // Avec Calenzana declaree comme arrivee, le compte est tenu.
      expect(DecoupageSurLesNuits.repartir(aLEnvers(nuits), 16).length, 16);
    });

    test('LES QUATRE ALLURES DE CHRISTOPHE, DANS LES DEUX SENS', () {
      final nuits = lire(cheminNuits);
      final envers = aLEnvers(nuits);

      // Les chiffres du sens de la trace sont ceux de la tache 848 : ils sont
      // repris ici pour que la COMPARAISON soit figee, pas seulement calculee.
      const attenduTrace = <int, int>{7: 2088, 9: 2088, 12: 1455, 16: 1455};
      const attenduEnvers = <int, int>{7: 2102, 9: 2026, 12: 1499, 16: 1148};

      for (final jours in <int>[7, 9, 12, 16]) {
        final trace = pireJournee(nuits, jours);
        final retour = pireJournee(envers, jours);
        expect(trace.journees, jours, reason: 'compte tenu dans le sens trace');
        expect(retour.journees, jours, reason: 'compte tenu a l\'envers');
        expect(
          trace.dplus,
          attenduTrace[jours],
          reason: 'pire journee a $jours jours, sens de la trace',
        );
        expect(
          retour.dplus,
          attenduEnvers[jours],
          reason: 'pire journee a $jours jours, sens inverse',
        );
        // LE RESULTAT QUI DECIDE DE LA FICHE : le VERDICT est le meme dans les
        // deux sens, a chacune des quatre allures, meme quand le chiffre bouge.
        expect(
          SeuilsDeDifficulte.pourDenivele(retour.dplus),
          SeuilsDeDifficulte.pourDenivele(trace.dplus),
          reason: 'a $jours jours, le sens change le chiffre mais pas le mot',
        );
      }
    });

    test('A DOUZE JOURS A L\'ENVERS, IL MANQUE UN METRE POUR ETRE EXPERT', () {
      // 1 499 m contre un seuil d\'expert a 1 500 m. Ce n\'est pas une
      // anecdote : ca dit que le verdict « tres difficile » de cette allure ne
      // tient qu\'a un metre, et qu\'une re-mesure de la trace peut le faire
      // basculer. Mieux vaut l\'avoir ecrit que le decouvrir en production.
      final envers = aLEnvers(lire(cheminNuits));
      final douze = pireJournee(envers, 12);
      expect(douze.dplus, 1499);
      expect(SeuilsDeDifficulte.deniveleExpertM - douze.dplus, 1);
      expect(
        SeuilsDeDifficulte.pourDenivele(douze.dplus),
        NiveauDeDifficulte.tresDifficile,
      );
    });

    test('LE PLANCHER DE CHAQUE SENS, cherche sur toutes les allures', () {
      final nuits = lire(cheminNuits);
      final envers = aLEnvers(nuits);
      var plancherTrace = 1 << 30;
      var plancherEnvers = 1 << 30;
      for (var jours = 1; jours <= 31; jours++) {
        final t = pireJournee(nuits, jours).dplus;
        final e = pireJournee(envers, jours).dplus;
        if (t < plancherTrace) plancherTrace = t;
        if (e < plancherEnvers) plancherEnvers = e;
      }
      expect(
        plancherTrace,
        1455,
        reason: 'le plancher du sens de la trace est le premier segment',
      );
      expect(
        plancherEnvers,
        1097,
        reason: 'a l\'envers, le plancher est Conca vers i Paliri',
      );
      // LE POINT QUI DECIDE DE LA PHRASE DE LA FICHE : les deux planchers
      // tombent dans la MEME bande de l\'echelle de Christophe.
      expect(
        SeuilsDeDifficulte.pourDenivele(plancherTrace),
        NiveauDeDifficulte.tresDifficile,
      );
      expect(
        SeuilsDeDifficulte.pourDenivele(plancherEnvers),
        NiveauDeDifficulte.tresDifficile,
      );
    });

    test(
      'LA NUIT TROUVEE DANS LE PREMIER SEGMENT NE CHANGE PAS LE VERDICT',
      () {
        // La tache 849 a cherche dans un couloir de 8 km, sans aucun seuil de
        // minutes, et a trouve l\'Auberge de la Foret de Bonifatu : un hotel
        // DECLARE par OpenStreetMap, qui quitte la trace au PK 8,748 km. Elle
        // coupe donc le segment reellement. Et elle ne suffit pas.
        final avec = lire(cheminInsertion);
        expect(avec.segments.length, 32);
        expect(avec.segments.first.arrivee, 'Auberge de la Forêt');
        expect(avec.segments.first.deniveleM, 1277);
        expect(avec.segments[1].deniveleM, 178);

        var plancher = 1 << 30;
        for (var jours = 1; jours <= 32; jours++) {
          final p = pireJournee(avec, jours).dplus;
          if (p < plancher) plancher = p;
        }
        expect(
          plancher,
          1277,
          reason:
              'inserer Bonifatu fait passer le plancher de 1 455 m a 1 277 m, '
              'soit 178 m : pas une bande',
        );
        expect(
          SeuilsDeDifficulte.pourDenivele(plancher),
          NiveauDeDifficulte.tresDifficile,
          reason: 'toujours tres difficile, donc la fiche ne change pas de mot',
        );
        // Aux trois allures serrees, elle ne change meme pas le chiffre : ce
        // sont d\'autres journees qui portent le verdict.
        for (final jours in <int>[7, 9, 12]) {
          expect(
            pireJournee(avec, jours).dplus,
            pireJournee(lire(cheminNuits), jours).dplus,
            reason: 'a $jours jours, Bonifatu ne change rien',
          );
        }
      },
    );

    test(
      'LE DETOUR VERS UNE NUIT N\'ENTRE PAS DANS LE DENIVELE DE LA JOURNEE',
      () {
        // ECART CONNU ET NOMME, et il devient important avec Bonifatu. Une
        // journee somme le denivele de ses SEGMENTS ; le detour vers le
        // couchage n\'est compte que dans ses MINUTES. Pour les quinze nuits de
        // la 838 (detours de 0 a 28 minutes) l\'ecart est negligeable. Pour
        // Bonifatu, ou l\'on descend 973 m le soir et ou on les REMONTE le
        // matin, il ne l\'est plus : le verdict se lit sur un denivele qui
        // ignore 973 m de montee reelle.
        final avec = lire(cheminInsertion);
        final nuit = avec.nuits.firstWhere(
          (n) => n.nom == 'Auberge de la Forêt',
        );
        expect(nuit.minutesAller, 126);
        expect(nuit.minutesRetour, 240);
        expect(nuit.minutesDeDetour, 366);

        final journees = DecoupageSurLesNuits.repartir(avec, 32);
        final premiere = journees.first;
        expect(premiere.arrivee.nom, 'Auberge de la Forêt');
        // Le denivele de la journee est celui du segment SEUL...
        expect(premiere.deniveleM, 1277);
        // ...alors que ses minutes, elles, PAIENT le detour.
        expect(
          premiere.minutes,
          avec.segments.first.minutes + nuit.minutesAller,
        );
        // Le jour suivant repart en REMONTANT, et ces minutes sont comptees.
        expect(
          journees[1].minutes,
          avec.segments[1].minutes + nuit.minutesRetour,
          reason: 'la remontee du matin est dans les minutes...',
        );
        expect(
          journees[1].deniveleM,
          178,
          reason: '...mais ses 973 m de montee ne sont PAS dans le denivele',
        );
      },
    );

    test('MEME LA VARIANTE PAR BONIFATU RESTE TRES DIFFICILE', () {
      // La partie UN cherchait le plus court chemin DEPUIS LA TRACE : elle
      // traitait donc Bonifatu comme un detour et descendait 973 m depuis le
      // PK 8,748 km. Les topoguides decrivent autre chose — on va a Bonifatu
      // DIRECTEMENT depuis Calenzana par le Tra Mare e Monti, puis on remonte
      // par le chemin de Melaghja. C\'est une VARIANTE, pas un detour, et elle
      // a ete mesuree comme telle (tool/variante_bonifatu_849.py). C\'est la
      // lecture la PLUS FAVORABLE au sentier, et elle ne suffit toujours pas.
      final fichier = File('assets/data/gr20/variante_bonifatu_849.json');
      expect(fichier.existsSync(), isTrue);
      final v = jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
      final pire = (v['pire_journee_de_la_variante_dplus_m'] as num).toInt();
      expect(pire, 1056);
      expect(
        SeuilsDeDifficulte.pourDenivele(pire),
        NiveauDeDifficulte.tresDifficile,
        reason:
            'la variante la plus favorable rend 1 056 m : 56 m seulement '
            'au-dessus du plafond de « difficile », mais au-dessus',
      );

      // LE CONTROLE QUI VALIDE TOUTE LA CHAINE DE MESURE : le meme reseau
      // pieton, parcouru de Calenzana a l\'Ortu di u Piobbu, rend 1 458 m de
      // montee quand la trace mesuree en 839 en rend 1 455. Trois metres
      // d\'ecart sur 1 455 : le releve OpenStreetMap et la trace disent la
      // meme montagne.
      final controle = (v['troncons'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((t) => (t['nom'] as String).contains('controle'));
      expect((controle['dplus_m'] as num).toInt(), 1458);
      expect(((controle['dplus_m'] as num).toInt() - 1455).abs(), 3);
    });

    test(
      'AUCUNE ALLURE, DANS AUCUN SENS, AVEC OU SANS LA NUIT TROUVEE, NE REND '
      'LE GR20 DIFFICILE OU PLUS FACILE',
      () {
        // C\'est la phrase de tete de la fiche, reduite a un cas de test :
        // « c\'est difficile, et ni le nombre de jours ni le sens n\'y changent
        // rien ». Si ce cas rougit, la phrase doit etre reecrite AVANT d\'etre
        // affichee.
        final nuits = lire(cheminNuits);
        final avec = lire(cheminInsertion);
        final scenarios = <String, DecoupageDeNuits>{
          'sens de la trace': nuits,
          'sens inverse': aLEnvers(nuits),
          'avec Bonifatu': avec,
          'avec Bonifatu, a l\'envers': aLEnvers(avec),
        };
        for (final entree in scenarios.entries) {
          for (var jours = 1; jours <= 32; jours++) {
            final niveau = SeuilsDeDifficulte.pourDenivele(
              pireJournee(entree.value, jours).dplus,
            );
            expect(
              niveau.rang,
              greaterThanOrEqualTo(NiveauDeDifficulte.tresDifficile.rang),
              reason:
                  'a $jours jours en ${entree.key}, le GR20 serait '
                  '${niveau.libelle} : la phrase de la fiche ne tiendrait plus',
            );
          }
        }
      },
    );
  });
}
