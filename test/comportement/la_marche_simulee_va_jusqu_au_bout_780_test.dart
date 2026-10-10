// LA GARDE DE LA TACHE 780 — LA MARCHE SIMULEE VA JUSQU'A L'ARRIVEE, ET LE
// PARCOURU NE SE FIGE PLUS.
//
// CE QUE CHRISTOPHE A VU, ET QUE CES GARDES EMPECHENT DE REVENIR (recette 778,
// emulator-5560, paquet e59f0012). A l'etape 3, Cozzano -> Guitera-les-Bains,
// le parcouru se FIGEAIT a 6,5 km sur 13,7 — 47 % — la barre passait au ROUGE,
// un badge « Hors trace » apparaissait, et un bandeau annoncait « Tu
// t'eloignes du sentier » avec une distance QUI GROSSISSAIT SANS FIN : 3 061
// puis 4 602, 6 966, 7 682, 8 324, 8 968 m. Quatre appuis de plus sur
// « Simuler l'etape suivante » n'avancaient plus rien. L'arrivee et ses
// felicitations etaient INATTEIGNABLES, le recapitulatif restait verrouille.
//
// LA CAUSE, MESUREE : la fenetre de recherche de [TrackProjector.project]
// compte des SEGMENTS, pas des metres. Sur le croquis de 53 points espaces de
// 1 079 m (avant la tache 761) ses 50 segments couvraient 54 km, c'est-a-dire
// TOUT le sentier : la fenetre ne bornait rien. Sur la trace relevee de 3 590
// points espaces de 19 m elle couvre 960 m. Le bouton d'etape deplace le
// marcheur de 9 a 20 km EN UN SEUL RELEVE : la position tombe hors fenetre, la
// recherche gloutonne se fait pieger par un minimum local, l'abscisse projetee
// se fige — et le bouton, qui calcule sa cible depuis cette abscisse figee,
// vise une borne DERRIERE le marcheur et ne fait plus rien. Un seul defaut,
// quatre symptomes.
//
// POURQUOI CES GARDES MANQUAIENT. Les gardes de la tache 747 eprouvent le
// marcheur et les jalons SEPAREMENT, et la projection n'y entre jamais : la
// panne ne nait que de leur RENCONTRE, et seulement sur une trace dense. La
// garde qui manquait est celle-ci : faire marcher le marcheur sur TOUTE LA
// LONGUEUR du sentier, par le chemin de la demonstration, et verifier qu'il
// reste sur la trace du premier metre au dernier.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/domain/jalons_des_etapes.dart';
import 'package:moteur_gr/features/map/domain/off_track_detector.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule.dart';

/// La VRAIE trace du sentier de demonstration, telle que l'application la lit.
List<TrackPoint> traceDeDemo() => GpxParser.parse(
  File('assets/data/mare_a_mare_centre/track.gpx').readAsStringSync(),
).allTrackPoints;

/// LA TRACE D'AVANT LA TACHE 761, gardee en temoin : 53 points espaces de
/// 1 079 m. C'est elle qui rendait la fenetre inoffensive.
List<TrackPoint> traceAvant761() => GpxParser.parse(
  File('test/fixtures/gpx/mare_a_mare_centre_avant_761.gpx').readAsStringSync(),
).allTrackPoints;

/// Les VRAIES etapes du sentier de demonstration.
List<StageModel> etapesDeDemo() {
  final brut =
      jsonDecode(
            File(
              'assets/data/mare_a_mare_centre/stages.json',
            ).readAsStringSync(),
          )
          as List<dynamic>;
  return [
    for (final e in brut.cast<Map<String, dynamic>>())
      StageModel(
        trailId: 'mare_a_mare_centre',
        stageNumber: e['stageNumber'] as int,
        name: e['nameFr'] as String? ?? 'Etape ${e['stageNumber']}',
        distanceKm: (e['distanceKm'] as num).toDouble(),
        elevationGainM: (e['elevationGainM'] as num).toInt(),
        elevationLossM: (e['elevationLossM'] as num).toInt(),
        startLat: (e['startLat'] as num).toDouble(),
        startLng: (e['startLng'] as num).toDouble(),
        endLat: (e['endLat'] as num).toDouble(),
        endLng: (e['endLng'] as num).toDouble(),
        departureName: e['departureName'] as String? ?? '',
        arrivalName: e['arrivalName'] as String? ?? '',
      ),
  ];
}

/// Une minuterie qui ne se declenche jamais : la garde pilote les battements.
class _MinuterieMuette implements Timer {
  @override
  void cancel() {}
  @override
  bool get isActive => true;
  @override
  int get tick => 0;
}

/// LE BANC : un marcheur simule et LA PROJECTION DE PRODUCTION branchee
/// dessus, telle que `track_position_provider.dart` la fait — fenetree, avec
/// l'index de la projection precedente reporte d'un releve au suivant.
class _Banc {
  _Banc(this.trace) {
    marcheur = MarcheurSimule(
      minuterie: (_, action) {
        _battement = action;
        return _MinuterieMuette();
      },
      surveillerLeCycleDeVie: false,
    );
  }

  final List<TrackPoint> trace;
  late final MarcheurSimule marcheur;
  late void Function(Timer) _battement;

  int? _dernierIndex;

  /// L'abscisse PROJETEE : c'est le « parcouru » que la barre affiche
  /// (`stageDistanceCoveredProvider`).
  double parcouruProjete = 0;

  /// L'ecart au trace que lit le detecteur hors-trace.
  double ecartAuTrace = 0;

  /// Le pire ecart au trace depuis le depart.
  double ecartMax = 0;

  /// LE PIRE RETARD DE L'ABSCISSE PROJETEE SUR CELLE DU MARCHEUR. C'est le
  /// chiffre du defaut : a 41,308 km il atteignait des kilometres et ne
  /// redescendait plus.
  double retardMax = 0;

  bool demarrer() {
    final parti = marcheur.demarrer(
      trace: trace,
      trailId: 'mare_a_mare_centre',
    );
    _projeter();
    return parti;
  }

  void _projeter() {
    final p = marcheur.dernierePosition;
    if (p == null) return;
    final proj = TrackProjector.project(
      userLat: p.latitude,
      userLng: p.longitude,
      trackPoints: trace,
      lastKnownIndex: _dernierIndex,
    );
    _dernierIndex = proj.trackIndexPosition;
    parcouruProjete = proj.distanceFromStartM;
    ecartAuTrace = proj.distanceToTrackM;
    if (ecartAuTrace > ecartMax) ecartMax = ecartAuTrace;
    final retard = (marcheur.distanceSimuleeM - parcouruProjete).abs();
    if (retard > retardMax) retardMax = retard;
  }

  /// [combien] battements de la minuterie, projection a chaque releve.
  void battre(int combien) {
    for (var i = 0; i < combien; i++) {
      _battement(_MinuterieMuette());
      _projeter();
    }
  }

  /// UN APPUI SUR « SIMULER L'ETAPE SUIVANTE », par le chemin EXACT de la
  /// production (`TrekController.simulerLEtapeSuivante`, lignes 548-554) : la
  /// cible est la prochaine fin d'etape lue depuis L'ABSCISSE PROJETEE, et
  /// c'est [MarcheurSimule.allerA] qui deplace la source.
  bool appuyerSurSimulerLEtapeSuivante(List<JalonDEtape> jalons) {
    final cible = prochaineFinDEtape(jalons, parcouruProjete);
    if (cible == null) return false;
    final bouge = marcheur.allerA(cible);
    _projeter();
    return bouge;
  }
}

void main() {
  group('LA MARCHE SIMULEE VA JUSQU AU BOUT DU SENTIER', () {
    test('LA GARDE QUI MANQUAIT — LES SEPT ETAPES PAR LE BOUTON, DU PREMIER '
        'METRE AU DERNIER : chaque appui avance, le parcouru suit le marcheur, '
        'et l arrivee est atteinte', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      final banc = _Banc(trace);
      expect(banc.demarrer(), isTrue);

      // Le randonneur marche un peu avant d'appuyer, comme Christophe.
      banc.battre(20);

      final franchies = <double>[];
      for (var appui = 1; appui <= jalons.length; appui++) {
        expect(
          banc.appuyerSurSimulerLEtapeSuivante(jalons),
          isTrue,
          reason:
              'APPUI $appui MORT. Le bouton calcule sa cible depuis '
              'l abscisse PROJETEE : si la projection a pris du retard sur le '
              'marcheur, la cible tombe DERRIERE lui et allerA la refuse. '
              'Retard mesure : ${banc.retardMax.toStringAsFixed(0)} m, '
              'parcouru projete ${banc.parcouruProjete.toStringAsFixed(0)} m, '
              'marcheur ${banc.marcheur.distanceSimuleeM.toStringAsFixed(0)} m',
        );
        franchies.add(banc.marcheur.distanceSimuleeM);
        // La minuterie continue de battre entre deux appuis.
        banc.battre(6);
      }

      // LES SEPT BORNES, DANS L'ORDRE DU SENTIER.
      expect(franchies, hasLength(7));
      for (var i = 0; i < jalons.length; i++) {
        expect(franchies[i], closeTo(jalons[i].finM, 1));
      }

      // L'ARRIVEE : le bout de la trace, et plus rien a franchir.
      expect(banc.marcheur.etat, EtatDuMarcheur.arrive);
      expect(
        banc.marcheur.distanceSimuleeM,
        closeTo(trace.last.distanceFromStart, 1),
      );
      expect(prochaineFinDEtape(jalons, banc.parcouruProjete), isNull);
    });

    test('IL RESTE SUR LA TRACE DU DEBUT A LA FIN : aucun badge '
        '« Hors trace », aucun bandeau d eloignement, sur les sept etapes', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      final banc = _Banc(trace);
      banc.demarrer();
      banc.battre(20);
      for (var appui = 1; appui <= jalons.length; appui++) {
        banc.appuyerSurSimulerLEtapeSuivante(jalons);
        banc.battre(6);
      }

      // Le marcheur simule est POSE sur la trace : son ecart est geometrique,
      // pas statistique. Le seuil de sortie du hors-trace est ce qui allume le
      // badge et le bandeau — il ne doit jamais etre approche.
      expect(
        banc.ecartMax,
        lessThan(kOffTrackExitThresholdMeters),
        reason:
            'ECART AU TRACE DE ${banc.ecartMax.toStringAsFixed(0)} m : '
            'c est le bandeau « Tu t eloignes du sentier » de Christophe.',
      );
      expect(banc.ecartMax, lessThan(2));

      // ET LE PARCOURU NE SE FIGE PAS : l abscisse projetee est celle que la
      // barre affiche. Un retard, c est un parcouru faux.
      expect(
        banc.retardMax,
        lessThan(2),
        reason:
            'LE PARCOURU A PRIS ${banc.retardMax.toStringAsFixed(0)} m DE '
            'RETARD sur le marcheur : c est le « 6,5 km sur 13,7 » fige.',
      );
    });

    test('LA MARCHE CONTINUE, PAS A PAS, SUR LES 87 KM : le parcouru suit le '
        'marcheur a chaque releve et le sentier se termine', () {
      final trace = traceDeDemo();
      final banc = _Banc(trace);
      banc.demarrer();
      var tours = 0;
      // Le marcheur avance de 33,3 m par battement : la traversee complete
      // demande environ 2 620 battements. La borne est large et NOMMEE : elle
      // n est la que pour qu une marche qui n arrive jamais echoue au lieu de
      // tourner sans fin.
      while (banc.marcheur.etat == EtatDuMarcheur.enMarche && tours < 20000) {
        banc.battre(1);
        tours++;
      }
      expect(banc.marcheur.etat, EtatDuMarcheur.arrive);
      expect(
        banc.marcheur.distanceSimuleeM,
        closeTo(trace.last.distanceFromStart, 1),
      );
      expect(banc.ecartMax, lessThan(2));
      expect(banc.retardMax, lessThan(2));
    });
  });

  group('LA FENETRE DE RECHERCHE NE CHANGE PAS LA REPONSE', () {
    test('APRES UN SAUT D ETAPE, la projection fenetree rend EXACTEMENT ce que '
        'rend le trace entier — c est le defaut, a l abscisse ou il se '
        'produisait', () {
      final trace = traceDeDemo();
      // L'abscisse du piege, mesuree : le marcheur saute a la fin de l etape 3
      // (48,525 km) alors que l index de la projection est reste au debut de
      // l etape, et la fenetre se figeait a 41,308 km.
      final depart = TrackProjector.locate(
        trackPoints: trace,
        distanceFromStartM: 34846,
      );
      final apresLeSaut = TrackProjector.locate(
        trackPoints: trace,
        distanceFromStartM: 48525,
      );
      final verite = TrackProjector.project(
        userLat: apresLeSaut.lat,
        userLng: apresLeSaut.lng,
        trackPoints: trace,
      );
      final fenetree = TrackProjector.project(
        userLat: apresLeSaut.lat,
        userLng: apresLeSaut.lng,
        trackPoints: trace,
        lastKnownIndex: depart.segmentIndex,
      );
      expect(
        fenetree.distanceFromStartM,
        closeTo(verite.distanceFromStartM, 1),
        reason:
            'LA FENETRE REND UNE AUTRE ABSCISSE QUE LE TRACE ENTIER : '
            '${fenetree.distanceFromStartM.toStringAsFixed(0)} m au lieu de '
            '${verite.distanceFromStartM.toStringAsFixed(0)} m. Une '
            'optimisation qui change la reponse est un defaut.',
      );
      expect(fenetree.distanceToTrackM, closeTo(verite.distanceToTrackM, 1));
      expect(fenetree.distanceToTrackM, lessThan(1));
    });

    test('LE LONG DE TOUT LE SENTIER, un saut d etape depuis n importe quelle '
        'borne retombe sur la bonne abscisse', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      for (final jalon in jalons) {
        final avant = TrackProjector.locate(
          trackPoints: trace,
          distanceFromStartM: jalon.debutM,
        );
        final apres = TrackProjector.locate(
          trackPoints: trace,
          distanceFromStartM: jalon.finM,
        );
        final fenetree = TrackProjector.project(
          userLat: apres.lat,
          userLng: apres.lng,
          trackPoints: trace,
          lastKnownIndex: avant.segmentIndex,
        );
        expect(
          fenetree.distanceFromStartM,
          closeTo(jalon.finM, 1),
          reason:
              'ETAPE ${jalon.numero} : le saut de '
              '${(jalon.debutM / 1000).toStringAsFixed(1)} km a '
              '${(jalon.finM / 1000).toStringAsFixed(1)} km rend '
              '${(fenetree.distanceFromStartM / 1000).toStringAsFixed(3)} km',
        );
      }
    });

    test('LE TEMOIN DE LA REGRESSION — la fenetre compte des SEGMENTS, donc sa '
        'portee a fondu quand la trace est devenue dense', () {
      final avant = traceAvant761();
      final maintenant = traceDeDemo();
      double porteeM(List<TrackPoint> t) {
        // La portee de 50 segments de part et d'autre, au milieu de la trace.
        final milieu = t.length ~/ 2;
        final bas = (milieu - 50).clamp(0, t.length - 1);
        final haut = (milieu + 50).clamp(0, t.length - 1);
        return t[haut].distanceFromStart - t[bas].distanceFromStart;
      }

      // AVANT : 53 points, la fenetre couvrait plus que le sentier entier.
      expect(avant.length, 53);
      expect(porteeM(avant), greaterThan(avant.last.distanceFromStart * 0.9));
      // MAINTENANT : 3 590 points, elle couvre environ 2 km de part et d autre.
      expect(maintenant.length, 3590);
      expect(porteeM(maintenant), lessThan(5000));
      // C est ce rapport — plus de vingt fois — qui a reveille le defaut.
      expect(
        porteeM(avant) / porteeM(maintenant),
        greaterThan(20),
        reason:
            'Si ce rapport retombe a 1, la fenetre ne depend plus de la '
            'densite et ce temoin n a plus de sens.',
      );
    });
  });
}
