// GARDE — TACHE 853 : LE REPARTITEUR NE PERD PLUS DE JOURNEE, ET LE DETOUR
// COMPTE AUSSI EN METRES.
//
// DEUX DEFAUTS TROUVES PAR LA 849, NOMMES PAR LA 852 DANS SES COMMENTAIRES, ET
// LAISSES OUVERTS PAR LES DEUX. Ils sont repares ici, et chacun a son groupe.
//
// (1) EN SENS INVERSE, UNE JOURNEE DISPARAISSAIT EN SILENCE. La derniere
//     journee du sens inverse arrive a Calenzana, la tete de sentier, qui
//     n'est PAS une nuit relevee — on y dort avant de partir, pas pendant. Le
//     repartiteur ne la retrouvait pas dans sa table des nuits et faisait
//     `continue` : seize journees demandees, quinze rendues, sans un mot. La
//     garantie etait pourtant ECRITE deux lignes plus haut dans le meme
//     fichier (« AUTANT de journees que demande »).
//
// (2) LE DETOUR VERS UN COUCHAGE COMPTAIT EN MINUTES ET PAS EN METRES. La
//     tache 838 avait mesure le detour dans les deux sens, separement, parce
//     qu'il n'est pas symetrique : on DESCEND au refuge Laparo (10 min, 5 m de
//     montee) et on en REMONTE (28 min, 126 m de montee). Les minutes
//     entraient dans la journee depuis la 838 ; les metres n'entraient dans
//     rien. Le commentaire du champ des minutes disait deja pourquoi c'est
//     inacceptable — « les taire ferait passer une journee pour plus courte
//     qu'elle n'est » — et le raisonnement vaut mot pour mot pour les metres.
//
// CE QUE CE FICHIER NE PRETEND PAS. Les 126 m du refuge Laparo sont le PLUS
// GROS detour des trente et une nuits retenues. Le mandat de ce lot parlait de
// « 973 m » : ce chiffre n'est le detour d'aucune nuit du jeu. Il appartient a
// la Bergerie de Pulella (974 m de remontee, 206 minutes), ECARTEE du jeu des
// nuits precisement parce que son detour depasse le seuil — et un cas plus
// bas le fige pour que cette distinction ne se reperde pas.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

/// Les trente et une nuits relevees du GR20, telles qu'embarquees.
DecoupageDeNuits lireGr20() => DecoupageDeNuits.fromJson(
  jsonDecode(File('assets/data/gr20/nuits_possibles.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// Le releve brut des couchages — la SOURCE du denivele de detour.
Map<String, dynamic> lireLesCouchages() =>
    jsonDecode(
          File('assets/data/gr20/couchages_hors_etape.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

/// Le temps des seuls segments, detour exclu.
int marcheSeule(JourneeSurLesNuits j) =>
    j.segments.fold<int>(0, (s, x) => s + x.minutes);

/// Le denivele des seuls segments, detour exclu.
int monteeDesSegments(JourneeSurLesNuits j) =>
    j.segments.fold<int>(0, (s, x) => s + x.deniveleM);

void main() {
  group('853 — LE SENS INVERSE EXISTE, ET IL RETOURNE LES DENIVELES', () {
    test('UN SEGMENT A L ENVERS ECHANGE MONTEE ET DESCENTE', () {
      // Le dernier segment du GR20 : de i Paliri vers Conca, on descend. Pris
      // a l'envers c'est la premiere journee du sens inverse, et elle MONTE.
      final gr20 = lireGr20();
      final dernier = gr20.segments.last;
      expect(dernier.arrivee, 'Conca');

      final aLEnvers = dernier.aLEnvers(rang: 1);
      expect(aLEnvers.depart, dernier.arrivee);
      expect(aLEnvers.arrivee, dernier.depart);
      expect(aLEnvers.deniveleM, dernier.descenteM);
      expect(aLEnvers.descenteM, dernier.deniveleM);
      // La longueur ne bouge pas : le meme chemin fait la meme longueur.
      expect(aLEnvers.km, dernier.km);
    });

    test('ET LE TEMPS EST RECALCULE, PARCE QU IL CHANGE', () {
      // MONTER NE COUTE PAS LE MEME TEMPS QUE DESCENDRE : 400 m de montee a
      // l'heure contre 1,67 s par metre de descente. Recopier les minutes du
      // sens de la trace ferait equilibrer les journees du sens inverse sur un
      // temps qui n'est pas le leur, et les coupures tomberaient a cote.
      final gr20 = lireGr20();
      final dernier = gr20.segments.last;
      final aLEnvers = dernier.aLEnvers(rang: 1);

      expect(
        aLEnvers.minutes,
        estimatedStageDurationMinutes(
          distanceKm: dernier.km,
          elevationGainM: dernier.descenteM,
          elevationLossM: dernier.deniveleM,
        ),
      );
      // Ce segment monte beaucoup plus a l'envers : il doit durer PLUS
      // longtemps.
      expect(dernier.descenteM, greaterThan(dernier.deniveleM));
      expect(aLEnvers.minutes, greaterThan(dernier.minutes));
    });

    test('LE SENTIER A L ENVERS PART DE L AUTRE BOUT', () {
      final gr20 = lireGr20();
      expect(gr20.teteDeSentier, 'Calenzana');

      final envers = gr20.aLEnvers;
      expect(envers.teteDeSentier, 'Conca');
      expect(envers.segments.length, gr20.segments.length);
      expect(envers.segments.first.depart, 'Conca');
      expect(envers.segments.last.arrivee, 'Calenzana');
      // Les rangs sont redonnes dans le nouvel ordre, sans trou.
      for (var i = 0; i < envers.segments.length; i++) {
        expect(envers.segments[i].rang, i + 1);
      }
      // La trace entiere est conservee, au metre pres.
      final kmEndroit = gr20.segments.fold<double>(0, (s, x) => s + x.km);
      final kmEnvers = envers.segments.fold<double>(0, (s, x) => s + x.km);
      expect(kmEnvers, closeTo(kmEndroit, 0.001));
      // Et la montee totale du retour est la descente totale de l'aller.
      final monteeEnvers = envers.segments.fold<int>(
        0,
        (s, x) => s + x.deniveleM,
      );
      final descenteEndroit = gr20.segments.fold<int>(
        0,
        (s, x) => s + x.descenteM,
      );
      expect(monteeEnvers, descenteEndroit);
    });
  });

  group('853 — LE DEFAUT : QUINZE JOURNEES POUR SEIZE DEMANDEES', () {
    test('EN SENS INVERSE, LE COMPTE EST TENU DE 1 A 31', () {
      // LE CAS QUI AURAIT ROUGI AVANT CE LOT, et le coeur du correctif. La
      // derniere journee revient a Calenzana, qui n'est pas une nuit relevee :
      // elle etait jetee en silence, et le compte tombait d'une unite.
      final envers = lireGr20().aLEnvers;
      for (var jours = 1; jours <= envers.journeesMaximales; jours++) {
        final programme = DecoupageSurLesNuits.repartir(envers, jours);
        expect(
          programme.length,
          jours,
          reason: '$jours journees demandees en sens inverse',
        );
        for (final j in programme) {
          expect(j.segmentCount, greaterThan(0));
          expect(j.km, greaterThan(0));
        }
      }
    });

    test('LA DERNIERE JOURNEE DU RETOUR ARRIVE A CALENZANA, ET ELLE EST '
        'LA', () {
      final envers = lireGr20().aLEnvers;
      final seize = DecoupageSurLesNuits.repartir(envers, 16);
      expect(seize.length, 16);

      final derniere = seize.last;
      // LE NOM EST TOUJOURS CONNU : il vient du segment, pas de la table des
      // nuits. Rien n'est invente.
      expect(derniere.arriveeNom, 'Calenzana');
      // ET LA NUIT EST NULLE, ce qui est exact : la tete de sentier n'est pas
      // une nuit relevee. Nulle veut dire « aucun detour a compter », pas
      // « lieu inconnu ».
      expect(derniere.arrivee, isNull);
      expect(derniere.deniveleDuDetourM, 0);
      expect(derniere.descenteDuDetourM, 0);
    });

    test('LE SENS DE LA TRACE N A PAS BOUGE : TOUTES SES ARRIVEES SONT DES '
        'NUITS', () {
      // LA NON-REGRESSION. Le correctif ne doit pas transformer le sens de la
      // trace en sentier a arrivees nulles : la, chaque journee finit bien sur
      // une nuit relevee, et c'est la 839 qui l'exigeait.
      final gr20 = lireGr20();
      for (final jours in <int>[7, 16, 31]) {
        for (final j in DecoupageSurLesNuits.repartir(gr20, jours)) {
          expect(j.arrivee, isNotNull, reason: 'a $jours jours');
          expect(j.arrivee!.nom, j.arriveeNom);
        }
      }
    });
  });

  group('853 — LE DETOUR COMPTE EN METRES, COMME IL COMPTAIT EN MINUTES', () {
    test('LA MONTEE DU DETOUR S AJOUTE A CELLE DES SEGMENTS', () {
      final programme = DecoupageSurLesNuits.repartir(lireGr20(), 31);
      for (final j in programme) {
        // Le detour ne peut QU AJOUTER : jamais retirer de la montee.
        expect(j.deniveleM, greaterThanOrEqualTo(monteeDesSegments(j)));
        expect(
          j.deniveleM - monteeDesSegments(j),
          j.deniveleDuDetourM,
          reason: 'journee ${j.numero} : le detour expose EST celui compte',
        );
      }
      // ET AU MOINS UNE JOURNEE EN PAIE VRAIMENT : sinon ce correctif
      // n'ajouterait rien et ce fichier le dirait.
      expect(programme.any((j) => j.deniveleDuDetourM > 0), isTrue);
    });

    test('LE REFUGE LAPARO EST LE PLUS GROS DETOUR DU JEU : 126 M A '
        'REMONTER', () {
      // CE CHIFFRE EST LE VRAI VISAGE DU DEFAUT. 126 m, c'est 1,26 km-effort
      // qui manquaient a une journee — assez pour la faire changer de bande
      // quand elle joue autour d'un seuil.
      final gr20 = lireGr20();
      final laparo = gr20.nuits.firstWhere((n) => n.nom == 'Refuge Laparo');
      expect(laparo.minutesAller, 10);
      expect(laparo.minutesRetour, 28);
      expect(laparo.deniveleAllerM, 5);
      expect(laparo.descenteAllerM, 126);
      expect(laparo.deniveleRetourM, 126);
      expect(laparo.descenteRetourM, 5);

      // C'est le maximum des trente et une nuits, aller et retour confondus.
      final pire = gr20.nuits
          .map((n) => n.deniveleAllerM + n.deniveleRetourM)
          .reduce((a, b) => a > b ? a : b);
      expect(pire, laparo.deniveleAllerM + laparo.deniveleRetourM);
      expect(pire, 131);
    });

    test('LES 973 M NE SONT PAS UN DETOUR DU JEU, ET VOICI D OU ILS '
        'VIENNENT', () {
      // LE MANDAT DE CE LOT PARLAIT DES « 973 M DE BONIFATU ». La mesure dit
      // deux choses, et toutes deux comptent.
      //
      // (a) BONIFATU N'EST PAS UN DETOUR : c'est une VARIANTE d'itineraire
      //     mesuree par la tache 849 (Calenzana -> Auberge de la Foret ->
      //     Ortu di u Piobbu), donc deux segments de trace, deja comptes comme
      //     tels. Aucun couchage du releve ne porte ce nom.
      // (b) LE CHIFFRE VOISIN QUI EXISTE EST 974 M, et c'est la remontee de la
      //     Bergerie de Pulella — ECARTEE du jeu des nuits parce que son
      //     detour depasse le seuil (206 minutes de remontee). Aucune journee
      //     ne la porte, donc aucune journee ne porte ses 974 m.
      final releve = lireLesCouchages();
      final couchages = (releve['couchages'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      expect(
        couchages.where((c) => (c['nom'] as String? ?? '').contains('onifat')),
        isEmpty,
        reason: 'Bonifatu n est pas un couchage : c est une variante',
      );

      final pulella = couchages.firstWhere(
        (c) => (c['nom'] as String? ?? '').contains('Pulella'),
      );
      expect(pulella['dplus_retour_m'], 974);
      expect(pulella['sous_le_seuil'], isFalse);

      // ET ELLE N'EST PAS UNE NUIT DU JEU : le seuil l'a ecartee.
      final gr20 = lireGr20();
      expect(gr20.nuits.where((n) => n.nom.contains('Pulella')), isEmpty);
    });

    test('UNE FIN D ETAPE N A AUCUN DETOUR, NI EN TEMPS NI EN METRES', () {
      // LA COHERENCE QUI EST LE VRAI CRITERE ICI. Le modele du depot place la
      // nuit d'une fin d'etape AU point de la trace : son detour vaut zero
      // minute depuis la tache 838, donc il doit valoir zero metre. Le
      // batiment voisin est parfois a une vingtaine de metres de montee ;
      // deplacer la nuit sur le batiment serait changer la definition d'une fin
      // d'etape, donc un autre lot — pas un effet de bord de celui-ci.
      final gr20 = lireGr20();
      final finsDEtape = gr20.nuits.where((n) => n.estFinDEtape).toList();
      expect(finsDEtape.length, 16);
      for (final n in finsDEtape) {
        expect(n.minutesDeDetour, 0, reason: n.nom);
        expect(n.deniveleAllerM, 0, reason: n.nom);
        expect(n.descenteAllerM, 0, reason: n.nom);
        expect(n.deniveleRetourM, 0, reason: n.nom);
        expect(n.descenteRetourM, 0, reason: n.nom);
        expect(n.surLaTrace, isTrue, reason: n.nom);
      }
    });

    test('LE TEMPS DU DETOUR EST TOUJOURS COMPTE, LUI AUSSI', () {
      // NON-REGRESSION DE LA 839 : le correctif des metres ne doit pas avoir
      // deplace les minutes.
      final programme = DecoupageSurLesNuits.repartir(lireGr20(), 31);
      for (final j in programme) {
        expect(j.minutes, greaterThanOrEqualTo(marcheSeule(j)));
      }
      expect(programme.any((j) => j.minutes > marcheSeule(j)), isTrue);
    });
  });

  group('853 — CE QUE LE CORRECTIF CHANGE AUX VERDICTS : RIEN, ET C EST '
      'MESURE', () {
    test('LE DETOUR NE FAIT CHANGER DE BANDE AUCUNE ALLURE', () {
      // LE RESULTAT LE PLUS UTILE DE CE CORRECTIF EST UN RESULTAT NEGATIF, ET
      // IL DOIT ETRE ECRIT PLUTOT QUE SUPPOSE. Les metres du detour entrent
      // desormais dans le denivele des journees, et AUCUN verdict ne bouge —
      // de sept a trente et un jours, dans les deux sens.
      //
      // LA RAISON N'EST PAS QUE LE DETOUR SERAIT NEGLIGEABLE : elle est que la
      // journee la PLUS DURE finit presque toujours sur une FIN D'ETAPE, dont
      // le detour vaut zero. Les nuits a detour (refuge Laparo et ses 126 m en
      // tete) tombent sur des journees plus legeres. Le correctif rend donc
      // les journees moyennes plus justes sans deplacer le plancher — et si un
      // jour une nuit a detour devient la pire journee d'une allure, ce cas
      // rougira et il faudra le relire.
      final gr20 = lireGr20();
      for (final jeu in <DecoupageDeNuits>[gr20, gr20.aLEnvers]) {
        for (final jours in <int>[7, 9, 12, 16, 31]) {
          final journees = DecoupageSurLesNuits.repartir(jeu, jours);
          expect(journees.length, jours);

          NiveauDeDifficulte verdict(bool avecLeDetour) =>
              DifficulteDuSentier.calculer(
                jours: jours,
                journees: journees
                    .map(
                      (j) => JourneeMesuree(
                        km: j.km,
                        deniveleM: avecLeDetour
                            ? j.deniveleM
                            : j.deniveleM - j.deniveleDuDetourM,
                        descenteM: avecLeDetour
                            ? j.descenteM
                            : j.descenteM - j.descenteDuDetourM,
                      ),
                    )
                    .toList(growable: false),
              )!.verdict!;

          expect(
            verdict(true),
            verdict(false),
            reason: 'a $jours jours, le detour ne change pas la bande',
          );
        }
      }
    });

    test('LE SENS INVERSE EST PLUS DUR A SEIZE JOURS, ET CA SE COMPTE', () {
      // CE QUE LE CORRECTIF DU COMPTE REND ENFIN MESURABLE. Avant lui, le sens
      // inverse perdait une journee et toute mesure sur lui etait fausse d'une
      // unite. Maintenant on peut comparer les deux sens a allure egale, et la
      // comparaison dit quelque chose de vendable :
      //
      //   seize jours dans le sens de la trace : 3 moyennes, 12 difficiles,
      //                                          1 tres difficile
      //   seize jours en sens inverse          : 1 moyenne, 12 difficiles,
      //                                          3 tres difficiles
      //
      // Le mot du verdict est le meme — tres difficile — mais le sens inverse
      // porte TROIS journees de la bande du haut au lieu d'une.
      final gr20 = lireGr20();

      Map<NiveauDeDifficulte, int> repartition(DecoupageDeNuits jeu) =>
          DifficulteDuSentier.calculer(
            jours: 16,
            journees: DecoupageSurLesNuits.repartir(jeu, 16)
                .map(
                  (j) => JourneeMesuree(
                    km: j.km,
                    deniveleM: j.deniveleM,
                    descenteM: j.descenteM,
                  ),
                )
                .toList(growable: false),
          )!.repartition;

      final endroit = repartition(gr20);
      final envers = repartition(gr20.aLEnvers);

      expect(endroit[NiveauDeDifficulte.tresDifficile], 1);
      expect(endroit[NiveauDeDifficulte.difficile], 12);
      expect(endroit[NiveauDeDifficulte.moyen], 3);

      expect(envers[NiveauDeDifficulte.tresDifficile], 3);
      expect(envers[NiveauDeDifficulte.difficile], 12);
      expect(envers[NiveauDeDifficulte.moyen], 1);

      // Les deux sens comptent seize journees : c'est tout l'objet du lot.
      expect(endroit.values.reduce((a, b) => a + b), 16);
      expect(envers.values.reduce((a, b) => a + b), 16);
    });

    test('LA FRAGILITE DU SEUIL TIENT TOUJOURS, ET LE DETOUR NE LA SAUVE '
        'PAS', () {
      // LA 852 AVAIT NOMME CETTE FRAGILITE : au decoupage le plus fin en sens
      // inverse, le verdict « tres difficile » tient sur 0,08 km-effort. On
      // pouvait esperer que les metres du detour l'eloignent du seuil ; ils ne
      // le font pas, parce que la journee en cause (Conca vers i Paliri) finit
      // sur une fin d'etape, donc sans detour. La fragilite reste, et elle
      // reste DITE.
      final envers = lireGr20().aLEnvers;
      final journees = DecoupageSurLesNuits.repartir(envers, 31);
      final difficulte = DifficulteDuSentier.calculer(
        jours: 31,
        journees: journees
            .map(
              (j) => JourneeMesuree(
                km: j.km,
                deniveleM: j.deniveleM,
                descenteM: j.descenteM,
              ),
            )
            .toList(growable: false),
      )!;
      final pire = difficulte.pireJournee!;
      expect(pire.kmEffort, closeTo(25.079, 0.005));
      expect(
        pire.kmEffort - SeuilsDeDifficulte.effortTresDifficileKm,
        lessThan(0.1),
        reason: 'huit metres de montee en moins changeraient ce verdict',
      );
      expect(difficulte.verdict, NiveauDeDifficulte.tresDifficile);
    });
  });
}
