// LES GARDES DE LA TACHE 747 — L'ETAPE NE SAUTE PLUS, ET LES CHIFFRES SE
// RECONCILIENT.
//
// CE QUE CHRISTOPHE A VU LE 09/10 AU MATIN, ET QUE CES GARDES EMPECHENT DE
// REVENIR :
//
//   * « Le changement d'etapes ne fonctionne pas, c'est alleatoire le
//     changement » (08:55). Mesure avant correctif, rejouee sur la vraie trace
//     du sentier de demonstration : a l'abscisse 63,0 km — celle de sa capture
//     — l'ancien detecteur geographique repondait l'etape 5
//     « Zicavo - Cuttoli-Corticchiato », le nom AFFICHE sur son telephone,
//     alors que le marcheur etait sur l'etape 7 « Bastelica - Porticcio ». Sa
//     suite de reponses le long du sentier RECULAIT : 6 puis 5 puis 7.
//   * Une barre qui affichait EN MEME TEMPS Total 84,0 km, Parcouru 63,0 km et
//     « 9,9 km restants ». 84 moins 63 font 21, pas 9,9 : les trois nombres ne
//     pouvaient pas etre vrais ensemble. Chacun l'etait pourtant, sur SON
//     total — la trace GPX (72,892 km) pour deux d'entre eux, la fiche du
//     sentier (84,0 km) pour le troisieme.
//   * « la fleche orange ... ne fonctionne pas » et « simuler ne fonctionne pas
//     du tout » (08:46 et 08:48).
//   * « A la fin il manque les felicitations » (08:59).
//   * « il faut rester sur la fin pas revenir au debut dans l'affichage de la
//     carte » (09:00).
//
// LA GARDE LA PLUS IMPORTANTE DE CE FICHIER est celle de la MONOTONIE : elle
// parcourt la vraie trace metre par metre et exige que le numero d'etape ne
// decroisse JAMAIS. C'est l'enonce exact du defaut de Christophe, et aucun
// detecteur par distance a vol d'oiseau ne peut la passer.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/domain/jalons_des_etapes.dart';
import 'package:moteur_gr/features/map/providers/perimetre_de_la_barre_provider.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule.dart';
import 'package:moteur_gr/features/trek/data/placement_sur_la_trace.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// La VRAIE trace du sentier de demonstration, telle que l'application la lit.
List<TrackPoint> traceDeDemo() => GpxParser.parse(
  File('assets/data/mare_a_mare_centre/track.gpx').readAsStringSync(),
).allTrackPoints;

/// Les VRAIES etapes du sentier de demonstration, avec leurs bornes.
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

/// Une trace droite de [longueurM] metres, un point tous les [pasM].
List<TrackPoint> traceDroite({double longueurM = 10000, double pasM = 100}) => [
  for (var d = 0.0; d <= longueurM; d += pasM)
    TrackPoint(
      // 1 degre de latitude vaut environ 111 320 m : la trace est droite vers
      // le nord, et ses abscisses sont posees a la main de toute facon.
      lat: 42.0 + d / 111320.0,
      lng: 9.0,
      altitude: 100,
      distanceFromStart: d,
    ),
];

/// Une etape dont les bornes tombent sur la trace droite de [traceDroite].
StageModel etapeDroite(int numero, double debutM, double finM) => StageModel(
  trailId: 'droit',
  stageNumber: numero,
  name: 'Etape $numero',
  distanceKm: (finM - debutM) / 1000,
  elevationGainM: 100,
  elevationLossM: 80,
  startLat: 42.0 + debutM / 111320.0,
  startLng: 9.0,
  endLat: 42.0 + finM / 111320.0,
  endLng: 9.0,
  departureName: 'D$numero',
  arrivalName: 'A$numero',
);

void main() {
  group(
    'LES JALONS : une PARTITION de la trace, sans trou ni chevauchement',
    () {
      test('les tranches s additionnent EXACTEMENT a la longueur de la trace — '
          'c est ce qui rend la somme des etapes egale au sentier entier', () {
        final trace = traceDeDemo();
        final jalons = jalonsDesEtapes(trace, etapesDeDemo());

        final somme = jalons.fold<double>(0, (t, j) => t + j.longueurM);
        expect(jalons, hasLength(7));
        expect(somme, closeTo(trace.last.distanceFromStart, 0.001));
      });

      test('la fin d une etape est le debut de la suivante : aucun metre de '
          'sentier n appartient a deux etapes, ni a aucune', () {
        final jalons = jalonsDesEtapes(traceDeDemo(), etapesDeDemo());
        for (var i = 1; i < jalons.length; i++) {
          expect(
            jalons[i].debutM,
            equals(jalons[i - 1].finM),
            reason:
                'trou ou chevauchement entre les etapes '
                '${jalons[i - 1].numero} et ${jalons[i].numero}',
          );
        }
      });

      test('le sentier commence a zero et finit au bout de la trace', () {
        final trace = traceDeDemo();
        final jalons = jalonsDesEtapes(trace, etapesDeDemo());
        expect(jalons.first.debutM, 0);
        expect(jalons.last.finM, closeTo(trace.last.distanceFromStart, 0.001));
      });

      test('les etapes sont prises dans l ORDRE DU SENTIER, pas dans celui de '
          'la base', () {
        final trace = traceDroite();
        // Volontairement a l envers : la base peut rendre les lignes ainsi.
        final jalons = jalonsDesEtapes(trace, [
          etapeDroite(3, 6000, 10000),
          etapeDroite(1, 0, 3000),
          etapeDroite(2, 3000, 6000),
        ]);
        expect(jalons.map((j) => j.numero), [1, 2, 3]);
        expect(jalons[1].debutM, closeTo(3000, 1));
      });

      test('une borne qui RECULE est relachee sur la precedente : l ordre des '
          'etapes survit a une trace grossiere', () {
        final trace = traceDroite();
        final jalons = jalonsDesEtapes(trace, [
          etapeDroite(1, 0, 5000),
          // Le depart de l etape 2 tombe AVANT celui de l etape 1 : la tranche
          // devient vide, mais rien ne recule.
          etapeDroite(2, 5000, 5000),
          etapeDroite(3, 2000, 10000),
        ]);
        for (var i = 1; i < jalons.length; i++) {
          expect(jalons[i].debutM, greaterThanOrEqualTo(jalons[i - 1].debutM));
          expect(jalons[i].longueurM, greaterThanOrEqualTo(0));
        }
      });

      test(
        'rien d exploitable (trace trop courte, aucune etape) rend une liste '
        'vide plutot qu un decoupage invente',
        () {
          expect(jalonsDesEtapes(const [], etapesDeDemo()), isEmpty);
          expect(jalonsDesEtapes(traceDeDemo(), const []), isEmpty);
        },
      );
    },
  );

  group('L ETAPE SOUS LES PIEDS : elle ne recule JAMAIS', () {
    test('LA GARDE DU RETOUR DE CHRISTOPHE — le long de TOUTE la vraie trace, '
        'metre par metre, le numero d etape ne decroit jamais', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      final longueur = trace.last.distanceFromStart;

      var precedent = 0;
      var changements = 0;
      for (var d = 0.0; d <= longueur; d += 50) {
        final numero = jalonALAbscisse(jalons, d)!.numero;
        expect(
          numero,
          greaterThanOrEqualTo(precedent),
          reason: 'l etape a RECULE de $precedent a $numero a ${d ~/ 1000} km',
        );
        if (numero != precedent) changements++;
        precedent = numero;
      }
      // Sept etapes : sept prises de valeur, et pas une de plus. L ancien
      // detecteur en produisait bien davantage, en avant comme en arriere.
      expect(changements, 7);
    });

    test(
      'A 63,0 KM — L ABSCISSE DE LA CAPTURE DE CHRISTOPHE — c est l etape 7 '
      '« Bastelica », et non l etape 5 « Zicavo » que la barre affichait',
      () {
        final etapes = etapesDeDemo();
        final jalons = jalonsDesEtapes(traceDeDemo(), etapes);
        final jalon = jalonALAbscisse(jalons, 63000)!;

        expect(jalon.numero, 7);
        final nom = etapes.firstWhere((e) => e.stageNumber == 7).name;
        expect(nom, contains('Bastelica'));
      },
    );

    test('AU BOUT EXACT de la trace, c est la DERNIERE etape : le marcheur ne '
        'sort pas du sentier a l instant ou il le termine', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      expect(jalonALAbscisse(jalons, trace.last.distanceFromStart)!.numero, 7);
    });

    test('avant le depart, c est la PREMIERE etape — on n est pas « nulle '
        'part », on n est pas parti', () {
      final jalons = jalonsDesEtapes(traceDeDemo(), etapesDeDemo());
      expect(jalonALAbscisse(jalons, -500)!.numero, 1);
      expect(jalonALAbscisse(jalons, 0)!.numero, 1);
    });

    test('sans jalons, personne ne devine une etape', () {
      expect(jalonALAbscisse(const [], 1000), isNull);
    });
  });

  group('LES CHIFFRES D UN PERIMETRE : parcouru plus restant FONT le total', () {
    test('DANS LE PERIMETRE DE L ETAPE, sur la vraie trace, a chaque '
        'kilometre : la somme retombe sur le total et le pourcentage est leur '
        'rapport', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());

      for (var d = 0.0; d <= trace.last.distanceFromStart; d += 1000) {
        final jalon = jalonALAbscisse(jalons, d)!;
        final c = ChiffresDuPerimetre.surLaTranche(
          debutM: jalon.debutM,
          finM: jalon.finM,
          abscisseM: d,
        );
        expect(
          c.parcouruM + c.restantM,
          closeTo(c.totalM, 0.000001),
          reason: 'etape ${jalon.numero} a ${d ~/ 1000} km',
        );
        if (c.totalM > 0) {
          expect(c.ratio, closeTo(c.parcouruM / c.totalM, 0.000001));
        }
      }
    });

    test(
      'DANS LE PERIMETRE DU SENTIER, a chaque kilometre : meme invariant, '
      'et le total est la LONGUEUR DE LA TRACE — jamais celle de la fiche',
      () {
        final trace = traceDeDemo();
        final longueur = trace.last.distanceFromStart;

        for (var d = 0.0; d <= longueur; d += 1000) {
          final c = ChiffresDuPerimetre(totalM: longueur, parcouruM: d);
          expect(c.parcouruM + c.restantM, closeTo(c.totalM, 0.000001));
          expect(c.totalKm, closeTo(72.892, 0.01));
        }
      },
    );

    test('LE DEFAUT DE LA CAPTURE NE PEUT PLUS SE PRODUIRE : a 63,0 km les '
        'cinq chiffres du perimetre sentier sont coherents entre eux', () {
      final trace = traceDeDemo();
      final c = ChiffresDuPerimetre(
        totalM: trace.last.distanceFromStart,
        parcouruM: 63000,
      );
      // Ce que Christophe a vu : Total 84,0 / Parcouru 63,0 / restants 9,9.
      // Ce que la barre dit maintenant : 72,9 / 63,0 / 9,9 — et 63 + 9,9 font
      // bien 72,9.
      expect(c.totalKm, closeTo(72.892, 0.01));
      expect(c.parcouruKm, closeTo(63.0, 0.01));
      expect(c.restantKm, closeTo(9.892, 0.01));
      expect(c.parcouruKm + c.restantKm, closeTo(c.totalKm, 0.000001));
      expect((c.ratio * 100).round(), 86);
    });

    test('une position aberrante ne produit ni parcouru negatif ni plus de '
        '100 %', () {
      final avant = ChiffresDuPerimetre.surLaTranche(
        debutM: 1000,
        finM: 2000,
        abscisseM: 500,
      );
      expect(avant.parcouruM, 0);
      expect(avant.restantM, 1000);
      expect(avant.ratio, 0);

      final apres = ChiffresDuPerimetre.surLaTranche(
        debutM: 1000,
        finM: 2000,
        abscisseM: 9000,
      );
      expect(apres.parcouruM, 1000);
      expect(apres.restantM, 0);
      expect(apres.ratio, 1);
    });

    test('un perimetre vide ne montre aucun rapport plutot qu une division '
        'par zero', () {
      final c = ChiffresDuPerimetre(totalM: 0, parcouruM: 0);
      expect(c.ratio, 0);
      expect(c.restantM, 0);
    });
  });

  group('LA PROCHAINE FIN D ETAPE : la cible du bouton de simulation', () {
    test('c est la premiere borne DEVANT le marcheur', () {
      final jalons = jalonsDesEtapes(traceDeDemo(), etapesDeDemo());
      final cible = prochaineFinDEtape(jalons, 0)!;
      expect(cible, closeTo(jalons.first.finM, 0.001));
      expect(
        prochaineFinDEtape(jalons, cible)!,
        closeTo(jalons[1].finM, 0.001),
      );
    });

    test('elle ENJAMBE une tranche vide : le bouton ne devient jamais un geste '
        'mort', () {
      final jalons = [
        const JalonDEtape(numero: 1, debutM: 0, finM: 5000),
        // Tranche vide, exactement la ou se trouve le marcheur.
        const JalonDEtape(numero: 2, debutM: 5000, finM: 5000),
        const JalonDEtape(numero: 3, debutM: 5000, finM: 9000),
      ];
      expect(prochaineFinDEtape(jalons, 5000), 9000);
    });

    test('au bout du sentier il n y a plus rien a franchir : c est l ARRIVEE '
        'qu il reste a simuler', () {
      final trace = traceDeDemo();
      final jalons = jalonsDesEtapes(trace, etapesDeDemo());
      expect(prochaineFinDEtape(jalons, trace.last.distanceFromStart), isNull);
    });
  });

  group('LE SAUT DU MARCHEUR SIMULE : le bouton deplace LA SOURCE', () {
    test(
      'il avance jusqu a la borne demandee et fabrique un releve de plus',
      () {
        final marcheur = MarcheurSimule(
          minuterie: (_, __) => _MinuterieMuette(),
          surveillerLeCycleDeVie: false,
        );
        addTearDown(marcheur.fermer);
        expect(
          marcheur.demarrer(trace: traceDroite(), trailId: 'droit'),
          isTrue,
        );
        final relevesAuDepart = marcheur.releves.length;

        expect(marcheur.allerA(4000), isTrue);

        expect(marcheur.distanceSimuleeM, closeTo(4000, 0.001));
        expect(marcheur.releves.length, relevesAuDepart + 1);
      },
    );

    test(
      'IL NE RECULE JAMAIS : une cible derriere le marcheur est ignoree',
      () {
        final marcheur = MarcheurSimule(
          minuterie: (_, __) => _MinuterieMuette(),
          surveillerLeCycleDeVie: false,
        );
        addTearDown(marcheur.fermer);
        marcheur.demarrer(trace: traceDroite(), trailId: 'droit');
        marcheur.allerA(4000);

        expect(marcheur.allerA(1000), isFalse);
        expect(marcheur.distanceSimuleeM, closeTo(4000, 0.001));
      },
    );

    test('L HORLOGE DE LA MARCHE AVANCE AVEC LA DISTANCE : l allure que les '
        'releves racontent reste celle d un randonneur, pas 240 km/h', () {
      final marcheur = MarcheurSimule(
        minuterie: (_, __) => _MinuterieMuette(),
        surveillerLeCycleDeVie: false,
      );
      addTearDown(marcheur.fermer);
      marcheur.demarrer(
        trace: traceDroite(),
        trailId: 'droit',
        depart: DateTime(2026, 10, 9, 8),
      );
      marcheur.allerA(8000);

      final premier = marcheur.releves.first.recordedAt;
      final dernier = marcheur.releves.last.recordedAt;
      final heures = dernier.difference(premier).inSeconds / 3600;
      // 8 km a 4 km/h : deux heures de marche racontee.
      expect(heures, closeTo(2.0, 0.01));
      expect(8.0 / heures, closeTo(MarcheurSimule.kVitesseSimuleeKmh, 0.05));
    });

    test('au bout de la trace, le saut declare l ARRIVEE comme le dernier pas '
        'l aurait fait', () {
      final marcheur = MarcheurSimule(
        minuterie: (_, __) => _MinuterieMuette(),
        surveillerLeCycleDeVie: false,
      );
      addTearDown(marcheur.fermer);
      marcheur.demarrer(trace: traceDroite(), trailId: 'droit');

      expect(marcheur.allerA(999999), isTrue);
      expect(marcheur.distanceSimuleeM, closeTo(10000, 0.001));
      expect(marcheur.etat, EtatDuMarcheur.arrive);
    });

    test('un marcheur arrete ne saute pas', () {
      final marcheur = MarcheurSimule(
        minuterie: (_, __) => _MinuterieMuette(),
        surveillerLeCycleDeVie: false,
      );
      addTearDown(marcheur.fermer);
      expect(marcheur.allerA(1000), isFalse);
    });

    test('le temps d une distance est l inverse exact du pas regulier', () {
      expect(MarcheurSimule.tempsDeMarcheDe(0), Duration.zero);
      expect(MarcheurSimule.tempsDeMarcheDe(-10), Duration.zero);
      // Une vitesse nulle ne fabrique pas une duree infinie.
      expect(tempsDeMarchePour(1000, 0), Duration.zero);
      // Le pas regulier et son inverse doivent se retrouver.
      final aller = MarcheurSimule.tempsDeMarcheDe(MarcheurSimule.pasEnMetres);
      expect(
        aller.inMilliseconds,
        closeTo(MarcheurSimule.pasDeTempsSimule.inMilliseconds, 2),
      );
    });
  });

  group(
    'LA BASCULE DE PERIMETRE : etape par defaut, retour au bout de 20 s',
    () {
      ProviderContainer conteneur() {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        return c;
      }

      test(
        'A L OUVERTURE, C EST L ETAPE — la decision de Christophe du 09/10',
        () {
          final c = conteneur();
          expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.etape);
        },
      );

      test('un appui bascule vers le SENTIER ENTIER', () {
        final c = conteneur();
        c.read(perimetreDeLaBarreProvider.notifier).basculer();
        expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.sentier);
      });

      test('un second appui revient a l etape TOUT DE SUITE : on n attend pas '
          'vingt secondes devant le mauvais perimetre', () {
        final c = conteneur();
        final n = c.read(perimetreDeLaBarreProvider.notifier);
        n.basculer();
        n.basculer();
        expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.etape);
      });

      testWidgets('AU BOUT DE VINGT SECONDES la vue sentier revient seule a '
          'l etape', (tester) async {
        final c = conteneur();
        c.read(perimetreDeLaBarreProvider.notifier).basculer();
        expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.sentier);

        await tester.pump(const Duration(seconds: 19));
        expect(
          c.read(perimetreDeLaBarreProvider),
          PerimetreDeLaBarre.sentier,
          reason: 'elle ne doit pas revenir avant la fin du compte',
        );
        await tester.pump(const Duration(seconds: 2));
        expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.etape);
      });

      testWidgets(
        'TOUCHER L ECRAN REMET LE COMPTE A ZERO : la vue ne se derobe '
        'pas sous les doigts de qui s en sert',
        (tester) async {
          final c = conteneur();
          final n = c.read(perimetreDeLaBarreProvider.notifier);
          n.basculer();

          await tester.pump(const Duration(seconds: 15));
          n.toucheEcran();
          await tester.pump(const Duration(seconds: 15));
          expect(
            c.read(perimetreDeLaBarreProvider),
            PerimetreDeLaBarre.sentier,
            reason:
                'trente secondes ont passe, mais le compte a reparti a 15 s',
          );

          await tester.pump(const Duration(seconds: 6));
          expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.etape);
        },
      );

      testWidgets(
        'toucher l ecran sur la vue ETAPE ne declenche rien : il n y a '
        'aucun retour en attente',
        (tester) async {
          final c = conteneur();
          c.read(perimetreDeLaBarreProvider.notifier).toucheEcran();
          await tester.pump(const Duration(seconds: 25));
          expect(c.read(perimetreDeLaBarreProvider), PerimetreDeLaBarre.etape);
        },
      );
    },
  );

  group('LA BARRE LE DIT AVEC UN MOT, pas seulement avec une couleur', () {
    Widget barre({
      required String perimetre,
      bool vueSentier = false,
      VoidCallback? onBasculer,
    }) => MaterialApp(
      home: Scaffold(
        body: StageProgressBar(
          stageName: 'Bastelica - Porticcio',
          distanceRemainingKm: 9.9,
          progressRatio: 0.86,
          isOffTrack: false,
          totalDistanceKm: 72.9,
          distanceCoveredKm: 63.0,
          perimetreLabel: perimetre,
          vueSentier: vueSentier,
          onBasculer: onBasculer,
        ),
      ),
    );

    testWidgets('LE MOT DU PERIMETRE EST AFFICHE — la couleur seule ne suffit '
        'pas a qui distingue mal les couleurs', (tester) async {
      await tester.pumpWidget(barre(perimetre: 'Sentier entier'));
      expect(find.text('Sentier entier'), findsOneWidget);
    });

    testWidgets('un appui sur la barre appelle la bascule : le geste n est pas '
        'mort', (tester) async {
      var appuis = 0;
      await tester.pumpWidget(
        barre(perimetre: 'Etape', onBasculer: () => appuis++),
      );
      await tester.tap(find.text('Bastelica - Porticcio'));
      await tester.pump();
      expect(appuis, 1);
    });

    testWidgets('les deux perimetres ne se peignent pas de la meme couleur', (
      tester,
    ) async {
      Color couleurDuPourcentage() =>
          tester.widget<Text>(find.text('86%')).style!.color!;

      await tester.pumpWidget(barre(perimetre: 'Etape'));
      final couleurEtape = couleurDuPourcentage();

      await tester.pumpWidget(
        barre(perimetre: 'Sentier entier', vueSentier: true),
      );
      expect(couleurDuPourcentage(), isNot(couleurEtape));
    });
  });
}

/// Une minuterie qui ne se declenche jamais : les tests pilotent le marcheur
/// a la main, aucun pas automatique ne doit brouiller la mesure du saut.
class _MinuterieMuette implements Timer {
  @override
  void cancel() {}

  @override
  int get tick => 0;

  @override
  bool get isActive => true;
}
