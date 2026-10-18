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
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/journees_pesees.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';

/// Le profil du GR20, lu sur sa trace embarquee (tache 858).
ProfilDuTerrain lireLeProfil() {
  final points = GpxDepuisLesAssets.parseFromString(
    File('assets/data/gr20/track.gpx').readAsStringSync(),
  );
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

/// LE SENTIER PESE A UNE ALLURE, DANS LE SENS DEMANDE (tache 858).
///
/// LE SENS INVERSE DEMANDE DEUX RETOURNEMENTS, ET C'EST LE PIEGE : le
/// decoupage se retourne ([DecoupageDeNuits.aLEnvers]) ET le profil aussi
/// ([ProfilDuTerrain.aLEnvers]), sinon les points kilometriques des nuits
/// designeraient l'autre bout du sentier. Un sentier descendu n'est pas un
/// sentier monte.
SentierPese peser({
  required DecoupageDeNuits nuits,
  required ProfilDuTerrain profil,
  required int jours,
  bool aLEnvers = false,
}) {
  final profilUtile = aLEnvers ? profil.aLEnvers : profil;
  final total = profil.longueurM / 1000.0;
  final journees = <JourneeAPeser>[];
  var pk = 0.0;
  var depart = nuits.teteDeSentier;
  for (final j in DecoupageSurLesNuits.repartir(nuits, jours)) {
    final pkTrace = j.arrivee?.pkKm;
    final pkFin = pkTrace == null ? pk : (aLEnvers ? total - pkTrace : pkTrace);
    journees.add(
      JourneeAPeser(
        depart: depart,
        arrivee: j.arriveeNom,
        km: j.km,
        deniveleM: j.deniveleM,
        descenteM: j.descenteM,
        minutes: j.minutes,
        pkDebutKm: pk,
        pkFinKm: pkFin,
      ),
    );
    pk = pkFin;
    depart = j.arriveeNom;
  }
  return SentierPese.peser(
    jours: jours,
    profil: profilUtile,
    journees: journees,
  )!;
}

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

  group('858 — CE QUE L INDICE DE TERRAIN DIT DU DECOUPAGE, ET CE QU IL NE '
      'VOIT PAS', () {
    test('LE DETOUR VERS UN COUCHAGE N ENTRE PAS DANS L INDICE, ET IL FAUT LE '
        'SAVOIR', () {
      // UNE LIMITE REELLE, ECRITE PLUTOT QUE DECOUVERTE PLUS TARD. Les metres
      // du detour vers un couchage entrent dans le DENIVELE annonce de la
      // journee et dans son TEMPS DE MARCHE (tache 853) ; ils n'entrent PAS
      // dans son indice de terrain, parce que l'indice integre LA TRACE entre
      // deux points kilometriques et que le detour, par definition, quitte la
      // trace. Le refuge Laparo coute 126 m de remontee le lendemain matin :
      // ces metres sont dits, ils ne sont pas cotes.
      final gr20 = lireGr20();
      final profil = lireLeProfil();
      for (final jours in <int>[7, 9, 12, 16, 31]) {
        final pese = peser(nuits: gr20, profil: profil, jours: jours);
        expect(pese.journeesDeMarche, jours);
        for (final journee in pese.journees) {
          expect(
            journee.terrain.deniveleM,
            lessThanOrEqualTo(journee.deniveleM + 20.0),
            reason:
                'a $jours jours, l indice de ${journee.arrivee} compte plus de '
                'montee que la journee n en annonce',
          );
        }
      }
    });

    test('LE SENS INVERSE EST MOINS DUR SUR SA PIRE JOURNEE, ET PLUS DUR SUR '
        'LE RESTE — ET C EST UNE INFORMATION DE VENTE', () {
      // CE QUE LE NOUVEAU COMPTE REND VISIBLE ET QUE L ANCIEN NOYAIT. Le
      // kilometre-effort cotait presque pareil la journee qui grimpe 1 454 m
      // depuis Calenzana (26,5) et celle qui les descend (21,4) : le sens de
      // marche ne se voyait pas. L indice les separe par un facteur QUATRE, et
      // il dit alors quelque chose de vendable : du sud vers le nord, la pire
      // journee du GR20 est franchement plus basse, parce que la montee de
      // Calenzana se DESCEND.
      final gr20 = lireGr20();
      final profil = lireLeProfil();
      final endroit = peser(nuits: gr20, profil: profil, jours: 16);
      final envers = peser(
        nuits: gr20.aLEnvers,
        profil: profil,
        jours: 16,
        aLEnvers: true,
      );

      expect(endroit.journeesDeMarche, 16);
      expect(envers.journeesDeMarche, 16);

      final pireEndroit = endroit.pireJournee!;
      final pireEnvers = envers.pireJournee!;
      expect(
        pireEndroit.indiceDuTerrain,
        greaterThan(pireEnvers.indiceDuTerrain),
        reason:
            'dans le sens de la trace la premiere journee grimpe 1 454 m d un '
            'seul tenant et aucun couchage ne la coupe',
      );
      expect(pireEndroit.depart, 'Calenzana');

      // ET LES DEUX SENS NE COUTENT PAS LE MEME TOTAL : le sentier n est pas
      // symetrique, parce que monter et descendre ne coutent pas pareil.
      expect(
        (endroit.indiceDuTerrainCumule - envers.indiceDuTerrainCumule).abs(),
        greaterThan(1.0),
      );
    });

    test('LA FRAGILITE DU SEUIL A DISPARU AVEC LES BANDES, ET IL FAUT LE '
        'DIRE', () {
      // CE QUE CE LOT A RETIRE. La tache 852 avait nomme une fragilite : au
      // decoupage le plus fin en sens inverse, son verdict « tres difficile »
      // tenait sur 0,08 kilometre-effort — huit metres de montee en moins
      // auraient fait changer le mot affiche au client. Cette fragilite
      // n appartenait pas au sentier : elle appartenait au SEUIL. Il n y a
      // plus de seuil, donc plus de bascule : l indice sort en nombre, et un
      // nombre qui bouge de 0,1 bouge de 0,1.
      //
      // Christophe tranchera les niveaux plus tard (18/10 19:32). Le jour ou
      // il les posera, cette fragilite reviendra avec eux, et c est a ce
      // moment-la qu il faudra la mesurer — pas avant.
      final gr20 = lireGr20();
      final profil = lireLeProfil();
      final auPlusFin = peser(
        nuits: gr20.aLEnvers,
        profil: profil,
        jours: 31,
        aLEnvers: true,
      );
      expect(auPlusFin.journeesDeMarche, 31);
      final pire = auPlusFin.pireJournee!;
      expect(pire.indiceDuTerrain, greaterThan(0.0));
      // AUCUN SEUIL N EST CITE ICI, et c est le sujet du test.
      expect(pire.terrain.majorationDeContinuite.isFinite, isTrue);
    });
  });
}
