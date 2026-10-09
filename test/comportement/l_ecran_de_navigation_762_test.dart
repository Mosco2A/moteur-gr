// LES GARDES DE LA TACHE 762 — L'ARRIVEE, LA BARRE, LA BASCULE ET LE SOS.
//
// CE QUE LA RECETTE 753 A MESURE, ET QUE CES GARDES EMPECHENT DE REVENIR :
//
//   * « apres usage de la fleche d'etape, les felicitations perdent trois de
//     leurs quatre chiffres » — Parcouru restait, D+, D- et Vit. moy.
//     disparaissaient ;
//   * « a la fermeture le bandeau RETOMBE SUR L'ETAPE 1 avec 11,8 km restants
//     et 0 pour cent », soit un recul de l'etape 7 vers l'etape 1 ;
//   * « dans les DEUX cas la carte ne reste pas sur le point d'arrivee, le
//     marcheur finit dans le coin bas-gauche a moitie cache ».
//
// ET LES TROIS DECISIONS DE CHRISTOPHE DU 09/10 :
//
//   * 16:27 « Le bouton etape/ sentier entier est inverse. Quand on est etape
//     le bouton doit etre sentier entier et inversement pour l autre » ;
//   * 16:29 « En sentier entier l altitude pure n a plus lieue d etre et le
//     denivele + et - doit etre le total depuis le debut et en mode sentier
//     celui de l etape » — puis 16:32, le nombre d'etapes faites sur le total
//     a la place de l'altitude ;
//   * 16:26 « SOS en haut tres bien. A droite si droitier, a gauche si
//     gauche ».
//
// LA GARDE LA PLUS IMPORTANTE DE CE FICHIER est celle du RECUL D'ETAPE : une
// session finalisee n'est pas une session jamais partie, et la barre ne doit
// plus les confondre. C'est l'enonce exact de ce que Christophe a vu.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/recorded_track_stats.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_segment_stats.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/map/domain/jalons_des_etapes.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/features/safety/presentation/sos_button.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/barre_d_etape.dart';
import 'package:moteur_gr/features/trek/presentation/map/cadrage_de_l_arrivee.dart';
import 'package:moteur_gr/features/trek/presentation/map/felicitations_de_la_demo.dart';
import 'package:moteur_gr/features/trek/presentation/map/sos_du_cote_de_la_main.dart';
import 'package:moteur_gr/features/trek/providers/derniers_chiffres_mesures.dart';
import 'package:moteur_gr/features/trek/providers/live_trek_stats_provider.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import 'les_chiffres_de_la_demo_762_appuis.dart';

void main() {
  // -------------------------------------------------------------------------
  // CHANTIER 1 — L'ARRIVEE
  // -------------------------------------------------------------------------

  group('LES CHIFFRES DE LA MARCHE SURVIVENT A SON DERNIER PAS', () {
    /// Les chiffres qu'une marche a mesures, reconnaissables a leur D+.
    const mesures = TrackSegmentStats(
      distanceKm: 63.0,
      elevationGainM: 2480,
      elevationLossM: 2310,
      duration: Duration(hours: 15, minutes: 45),
      pointCount: 94,
    );

    /// Un conteneur ou le statut de session est PILOTABLE, et ou
    /// `liveTrekStatsProvider` se comporte comme EN VRAI : il ne rend des
    /// chiffres que pour LA session qui les a marches, et du VIDE partout
    /// ailleurs. Le vrai provider sort sur `session == null` et lit les releves
    /// PAR SESSION : une autre session, ce sont d'autres releves, donc d'autres
    /// chiffres — et aucun tant que son premier releve n'est pas arrive.
    ({ProviderContainer conteneur, StatutPilote pilote}) banc() {
      final pilote = StatutPilote(
        TrackingSessionState(
          status: TrackingSessionStatus.recording,
          session: sessionMarchee(),
        ),
      );
      final conteneur = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(() => pilote),
          liveTrekStatsProvider.overrideWith((ref) async {
            final etat = ref.watch(trekSessionManagerProvider);
            final active =
                etat.status == TrackingSessionStatus.recording ||
                etat.status == TrackingSessionStatus.paused;
            final laBonne = etat.session?.id == idDeLaMarche;
            return active && laBonne ? mesures : const TrackSegmentStats();
          }),
        ],
      );
      addTearDown(conteneur.dispose);
      return (conteneur: conteneur, pilote: pilote);
    }

    test('PENDANT la marche, ce sont les chiffres en vol', () async {
      final b = banc();
      await b.conteneur.read(liveTrekStatsProvider.future);
      expect(
        b.conteneur.read(chiffresDeLaMarcheProvider)?.elevationGainM,
        2480,
      );
    });

    test(
      'APRES la fin de la marche, les chiffres sont ENCORE LA — le defaut '
      'de la recette 753 etait qu ils disparaissaient a cet instant precis',
      () async {
        final b = banc();
        // On abonne la memoire, comme le fait l ecran qui l affiche.
        b.conteneur.listen(chiffresDeLaMarcheProvider, (_, _) {});
        await b.conteneur.read(liveTrekStatsProvider.future);
        expect(b.conteneur.read(chiffresDeLaMarcheProvider), isNotNull);

        // L arrivee ouvre la porte du finisher : `stop()` finalise et pose un
        // etat `stopped` SANS session. C est ce que `_finalize` fait en vrai.
        b.pilote.poser(
          const TrackingSessionState(status: TrackingSessionStatus.stopped),
        );
        await b.conteneur.read(liveTrekStatsProvider.future);

        final apres = b.conteneur.read(chiffresDeLaMarcheProvider);
        expect(apres, isNotNull, reason: 'les quatre chiffres, pas un seul');
        expect(apres!.elevationGainM, 2480);
        expect(apres.elevationLossM, 2310);
        expect(apres.averageSpeedKmh, isNotNull);
      },
    );

    test('LA SORTIE DE DEMO OUBLIE TOUT : le retour a `idle` efface la '
        'memoire, parce que la demo promet qu il ne reste rien', () async {
      final b = banc();
      b.conteneur.listen(chiffresDeLaMarcheProvider, (_, _) {});
      await b.conteneur.read(liveTrekStatsProvider.future);
      expect(b.conteneur.read(chiffresDeLaMarcheProvider), isNotNull);

      b.pilote.poser(const TrackingSessionState());
      await b.conteneur.read(liveTrekStatsProvider.future);
      expect(b.conteneur.read(chiffresDeLaMarcheProvider), isNull);
    });

    test('LES CHIFFRES D UNE AUTRE MARCHE SONT REFUSES : une nouvelle '
        'randonnee ne demarre pas avec le denivele de la veille', () async {
      final b = banc();
      b.conteneur.listen(chiffresDeLaMarcheProvider, (_, _) {});
      await b.conteneur.read(liveTrekStatsProvider.future);
      expect(b.conteneur.read(chiffresDeLaMarcheProvider), isNotNull);

      // Une AUTRE session devient active, et son premier releve n est pas
      // encore arrive : la memoire ne doit pas parler pour elle.
      b.pilote.poser(
        TrackingSessionState(
          status: TrackingSessionStatus.recording,
          session: sessionMarchee(id: 'une-autre-session'),
        ),
      );
      await b.conteneur.read(liveTrekStatsProvider.future);

      expect(
        b.conteneur.read(chiffresDeLaMarcheProvider),
        isNull,
        reason: 'des tirets, et non le denivele de la marche precedente',
      );
    });
  });

  group('LES FELICITATIONS PORTENT LES QUATRE CHIFFRES, PAS UN SEUL', () {
    /// Les felicitations seules, a l'arrivee d'une demonstration, avec ou sans
    /// chiffres mesures disponibles.
    Widget banc({required TrackSegmentStats? chiffres}) => ProviderScope(
      overrides: [
        enDemoProvider.overrideWithValue(true),
        etatDuMarcheurSimuleProvider.overrideWithValue(EtatDuMarcheur.arrive),
        stageDistanceCoveredProvider.overrideWithValue(63000),
        chiffresDeLaMarcheProvider.overrideWithValue(chiffres),
      ],
      child: const MaterialApp(
        home: Scaffold(body: Stack(children: [FelicitationsDeLaDemo()])),
      ),
    );

    testWidgets('LES QUATRE CHIFFRES : Parcouru, D+, D- et Vit. moy. — c est '
        'le releve exact de la recette 753, qui n en voyait plus qu un', (
      tester,
    ) async {
      await tester.pumpWidget(
        banc(
          chiffres: const TrackSegmentStats(
            distanceKm: 63.0,
            elevationGainM: 2480,
            elevationLossM: 2310,
            duration: Duration(hours: 15, minutes: 45),
            pointCount: 94,
          ),
        ),
      );
      await tester.pump();

      // LES LIBELLES SONT CHERCHES PAR LEUR CONTENU : cette surcouche les
      // rend suivis d'une espace (`'$label '`), pour les coller a leur valeur
      // sur la meme ligne.
      expect(find.textContaining(t.tracking.covered), findsOneWidget);
      expect(find.text('63.0 km'), findsOneWidget);
      expect(find.textContaining(t.tracking.dPlus), findsOneWidget);
      expect(find.text('2480 m'), findsOneWidget);
      expect(find.textContaining(t.tracking.dMinus), findsOneWidget);
      expect(find.text('2310 m'), findsOneWidget);
      expect(find.textContaining(t.tracking.avgSpeed), findsOneWidget);
    });

    testWidgets('SANS MESURE, le parcouru reste et les trois autres se '
        'taisent : jamais un zero qui aurait l air mesure', (tester) async {
      await tester.pumpWidget(banc(chiffres: null));
      await tester.pump();

      expect(find.textContaining(t.tracking.covered), findsOneWidget);
      expect(find.textContaining(t.tracking.dPlus), findsNothing);
      expect(find.textContaining(t.tracking.dMinus), findsNothing);
      expect(find.textContaining(t.tracking.avgSpeed), findsNothing);
    });
  });

  group('LA BARRE NE RECULE PLUS SUR L ETAPE 1 A L ARRIVEE', () {
    /// Une trace droite de 20 km, deux etapes de 10 km.
    final trace = [
      for (var d = 0.0; d <= 20000; d += 500)
        TrackPoint(
          lat: 42.0 + d / 111320.0,
          lng: 9.0,
          altitude: 100 + (d / 1000) * 10,
          distanceFromStart: d,
        ),
    ];
    final etapes = [_etape(1, 0, 10000, trace), _etape(2, 10000, 20000, trace)];

    /// La barre seule, avec un fix GPS pose a [abscisseM] sur la trace et un
    /// statut de session donne.
    Widget banc(TrackingSessionStatus statut, double abscisseM) {
      final point = trace.firstWhere(
        (p) => p.distanceFromStart >= abscisseM,
        orElse: () => trace.last,
      );
      return ProviderScope(
        overrides: [
          trailConfigProvider.overrideWithValue(testTrailConfig),
          gpxTrackProvider(
            testTrailConfig.id,
          ).overrideWith((ref) => Future.value(trace)),
          gpxTrackProvider(
            'default',
          ).overrideWith((ref) => Future.value(trace)),
          stagesProvider(
            testTrailConfig.id,
          ).overrideWith((ref) => Future.value(etapes)),
          stagesProvider('default').overrideWith((ref) => Future.value(etapes)),
          locationProvider.overrideWith(
            (ref) => Stream.value(
              Position(
                latitude: point.lat,
                longitude: point.lng,
                timestamp: DateTime.utc(2026, 6, 15, 9),
                accuracy: 5,
                altitude: point.altitude,
                altitudeAccuracy: 5,
                heading: 0,
                headingAccuracy: 0,
                speed: 1.2,
                speedAccuracy: 0.5,
              ),
            ),
          ),
          gpsPermissionProvider.overrideWith(
            (ref) => Future.value(GpsPermissionStateValues.granted),
          ),
          trekSessionManagerProvider.overrideWith(
            () => StatutPilote(
              TrackingSessionState(
                status: statut,
                session: statut == TrackingSessionStatus.recording
                    ? sessionMarchee(id: 'sess-762-bar')
                    : null,
              ),
            ),
          ),
          liveTrekStatsProvider.overrideWith(
            (ref) async => const TrackSegmentStats(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Align(child: ActiveStageBar())),
        ),
      );
    }

    testWidgets('A L ARRIVEE, la barre nomme la DERNIERE etape — pas la '
        'premiere', (tester) async {
      await tester.pumpWidget(banc(TrackingSessionStatus.stopped, 19999));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Etape 2'), findsOneWidget);
      expect(
        find.text('Etape 1'),
        findsNothing,
        reason:
            'c est le recul mesure a la recette 753 : etape 7 redevenue '
            'etape 1 a la fermeture des felicitations',
      );
    });

    testWidgets('A L ARRIVEE, le restant est celui de la FIN, pas les 10 km '
        'de la premiere etape', (tester) async {
      await tester.pumpWidget(banc(TrackingSessionStatus.stopped, 19999));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Le restant de l etape 2 a l arrivee est nul (a l arrondi), et le
      // pourcentage vaut 100 — jamais « 11,8 km restants et 0 pour cent ».
      expect(find.text('100%'), findsOneWidget);
      expect(find.text('0%'), findsNothing);
    });

    testWidgets('AVANT TOUTE MARCHE, rien ne change : la barre du PROGRAMME '
        'reste celle du lot D', (tester) async {
      await tester.pumpWidget(banc(TrackingSessionStatus.idle, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StageProgressBar), findsOneWidget);
      expect(find.text('Etape 1'), findsOneWidget);
      expect(find.text(StageProgressBar.pendingValueLabel), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // CHANTIER 5 (et 1c) — LE CADRE DE L'ARRIVEE
  // -------------------------------------------------------------------------

  group('LE CADRE DE L ARRIVEE met le point d arrivee AU CENTRE', () {
    test('l arrivee est le centre du cadre, et non son bord', () {
      const arrivee = LatLng(42.5, 9.1);
      final cadre = cadreDeLArrivee(arrivee);

      // LA TOLERANCE EST LE METRE, et elle est nommee : le centre d'un
      // [LatLngBounds] est un milieu GEODESIQUE, pas une moyenne de
      // coordonnees. L'ecart au point d'arrivee se compte en centimetres a
      // cette latitude — invisible a l'ecran, et c'est la seule chose qui
      // compte ici.
      const unMetreEnDegres = 1 / 111320.0;
      expect(cadre.center.latitude, closeTo(arrivee.latitude, unMetreEnDegres));
      expect(
        cadre.center.longitude,
        closeTo(arrivee.longitude, unMetreEnDegres),
      );
    });

    test('le cadre mesure environ deux fois le rayon, dans les deux axes — '
        'un cadre aplati loin de l equateur serait un cadre faux', () {
      const arrivee = LatLng(42.5, 9.1);
      final cadre = cadreDeLArrivee(arrivee);
      const distance = Distance();

      final hauteurM = distance.as(
        LengthUnit.Meter,
        LatLng(cadre.south, arrivee.longitude),
        LatLng(cadre.north, arrivee.longitude),
      );
      final largeurM = distance.as(
        LengthUnit.Meter,
        LatLng(arrivee.latitude, cadre.west),
        LatLng(arrivee.latitude, cadre.east),
      );

      expect(hauteurM, closeTo(2 * rayonDArriveeM, 50));
      expect(largeurM, closeTo(2 * rayonDArriveeM, 50));
    });
  });

  // -------------------------------------------------------------------------
  // CHANTIER 3 — LE CONTENU DE LA BARRE, PERIMETRE PAR PERIMETRE
  // -------------------------------------------------------------------------

  group('LES ETAPES FAITES SE COMPTENT SUR L ABSCISSE', () {
    final trace = [
      for (var d = 0.0; d <= 30000; d += 1000)
        TrackPoint(
          lat: 42.0 + d / 111320.0,
          lng: 9.0,
          altitude: 100,
          distanceFromStart: d,
        ),
    ];
    final jalons = jalonsDesEtapes(trace, [
      _etape(1, 0, 10000, trace),
      _etape(2, 10000, 20000, trace),
      _etape(3, 20000, 30000, trace),
    ]);

    test('au depart, AUCUNE etape faite', () {
      expect(etapesFaites(jalons, 0), 0);
    });

    test('une etape compte quand SA BORNE DE FIN est franchie, pas avant', () {
      expect(etapesFaites(jalons, 9999), 0);
      expect(etapesFaites(jalons, 10000), 1);
      expect(etapesFaites(jalons, 19999), 1);
      expect(etapesFaites(jalons, 20000), 2);
    });

    test('AU BOUT DE LA TRACE, le compte vaut le total : les chiffres se '
        'reconcilient aussi sur ce compteur', () {
      expect(etapesFaites(jalons, trace.last.distanceFromStart), jalons.length);
    });

    test('IL NE RECULE JAMAIS tant que l abscisse avance', () {
      var precedent = 0;
      for (var d = 0.0; d <= 30000; d += 250) {
        final faites = etapesFaites(jalons, d);
        expect(faites, greaterThanOrEqualTo(precedent));
        precedent = faites;
      }
    });
  });

  group('LE RELIEF D UNE TRANCHE : meme moteur, autres bornes', () {
    /// Une trace qui monte de 1000 m sur 10 km, puis redescend de 500 m.
    final trace = [
      for (var i = 0; i <= 10; i++)
        TrackPoint(
          lat: 42.0 + (i * 1000) / 111320.0,
          lng: 9.0,
          altitude: 100 + i * 100,
          distanceFromStart: i * 1000.0,
        ),
      for (var i = 1; i <= 5; i++)
        TrackPoint(
          lat: 42.0 + ((10 + i) * 1000) / 111320.0,
          lng: 9.0,
          altitude: 1100 - i * 100,
          distanceFromStart: (10 + i) * 1000.0,
        ),
    ];

    test('la tranche de montee ne porte QUE de la montee', () {
      final relief = reliefDeLaTranche(trace: trace, debutM: 0, finM: 10000);
      expect(relief.elevationGainM, 1000);
      expect(relief.elevationLossM, 0);
    });

    test('la tranche de descente ne porte QUE de la descente', () {
      final relief = reliefDeLaTranche(
        trace: trace,
        debutM: 10000,
        finM: 15000,
      );
      expect(relief.elevationGainM, 0);
      expect(relief.elevationLossM, 500);
    });

    test('UNE TRANCHE VIDE NE MENT PAS : le marcheur qui vient d entrer dans '
        'une etape n a encore rien monte', () {
      final relief = reliefDeLaTranche(trace: trace, debutM: 5000, finM: 5000);
      expect(relief.elevationGainM, 0);
      expect(relief.elevationLossM, 0);
    });

    test('sans trace exploitable, des zeros plutot qu une exception', () {
      expect(
        reliefDeLaTranche(trace: null, debutM: 0, finM: 1000).elevationGainM,
        0,
      );
      expect(
        reliefDeLaTranche(
          trace: const [],
          debutM: 0,
          finM: 1000,
        ).elevationGainM,
        0,
      );
    });

    test('LA TRANCHE ENTIERE DONNE LE MEME RELIEF QUE LE MOTEUR DE SESSION — '
        'c est la preuve qu il n y a pas deux moteurs', () {
      final tout = reliefDeLaTranche(
        trace: trace,
        debutM: 0,
        finM: trace.last.distanceFromStart,
      );
      expect(tout.elevationGainM, 1000);
      expect(tout.elevationLossM, 500);
    });
  });

  group('LES CHIFFRES SE RECONCILIENT DANS LES DEUX PERIMETRES', () {
    final trace = [
      for (var d = 0.0; d <= 30000; d += 1000)
        TrackPoint(
          lat: 42.0 + d / 111320.0,
          lng: 9.0,
          altitude: 100,
          distanceFromStart: d,
        ),
    ];
    final jalons = jalonsDesEtapes(trace, [
      _etape(1, 0, 10000, trace),
      _etape(2, 10000, 20000, trace),
      _etape(3, 20000, 30000, trace),
    ]);

    test('parcouru plus restant font le total, et le pourcentage est leur '
        'rapport — a chaque abscisse, dans les DEUX perimetres', () {
      for (var abscisse = 0.0; abscisse <= 30000; abscisse += 500) {
        final sentier = ChiffresDuPerimetre(
          totalM: trace.last.distanceFromStart,
          parcouruM: abscisse,
        );
        expect(
          sentier.parcouruM + sentier.restantM,
          closeTo(sentier.totalM, 1e-6),
          reason: 'perimetre SENTIER a $abscisse m',
        );
        expect(
          sentier.ratio,
          closeTo(sentier.parcouruM / sentier.totalM, 1e-9),
        );

        final jalon = jalonALAbscisse(jalons, abscisse)!;
        final etape = ChiffresDuPerimetre.surLaTranche(
          debutM: jalon.debutM,
          finM: jalon.finM,
          abscisseM: abscisse,
        );
        expect(
          etape.parcouruM + etape.restantM,
          closeTo(etape.totalM, 1e-6),
          reason: 'perimetre ETAPE a $abscisse m',
        );
        expect(etape.ratio, closeTo(etape.parcouruM / etape.totalM, 1e-9));
      }
    });
  });

  // -------------------------------------------------------------------------
  // CHANTIERS 2 ET 3 — LA BASCULE ET LES SIX CASES
  // -------------------------------------------------------------------------

  group('LE BOUTON DIT OU IL MENE, LA PASTILLE DIT OU L ON EST', () {
    Widget barre({
      required bool vueSentier,
      VoidCallback? onBasculer,
      int? etapesFaites,
      int? etapesTotal,
      double? altitudeM,
    }) => MaterialApp(
      home: Scaffold(
        body: StageProgressBar(
          stageName: 'Bastelica - Porticcio',
          distanceRemainingKm: 9.9,
          progressRatio: 0.86,
          isOffTrack: false,
          totalDistanceKm: 72.9,
          distanceCoveredKm: 63.0,
          elevationGainM: 2480,
          elevationLossM: 2310,
          avgSpeedKmh: 4.0,
          altitudeM: altitudeM,
          etapesFaites: etapesFaites,
          etapesTotal: etapesTotal,
          perimetreLabel: vueSentier
              ? t.map.perimetreSentier
              : t.map.perimetreEtape,
          basculeLabel: vueSentier
              ? t.map.basculerVersEtape
              : t.map.basculerVersSentier,
          vueSentier: vueSentier,
          onBasculer: onBasculer ?? () {},
        ),
      ),
    );

    testWidgets('EN VUE ETAPE : la pastille dit « Étape », le bouton dit '
        '« Voir le sentier entier »', (tester) async {
      await tester.pumpWidget(barre(vueSentier: false, altitudeM: 1480));

      expect(find.text(t.map.perimetreEtape), findsOneWidget);
      expect(find.text(t.map.basculerVersSentier), findsOneWidget);
      expect(
        find.text(t.map.basculerVersEtape),
        findsNothing,
        reason:
            'le bouton annoncerait l endroit ou l on est deja — c est '
            'l inversion que Christophe a relevee a 16:27',
      );
    });

    testWidgets('EN VUE SENTIER ENTIER : la pastille dit « Sentier entier », '
        'le bouton dit « Voir l etape »', (tester) async {
      await tester.pumpWidget(
        barre(vueSentier: true, etapesFaites: 3, etapesTotal: 7),
      );

      expect(find.text(t.map.perimetreSentier), findsOneWidget);
      expect(find.text(t.map.basculerVersEtape), findsOneWidget);
      expect(find.text(t.map.basculerVersSentier), findsNothing);
    });

    testWidgets('UN APPUI SUR LE BOUTON BASCULE UNE FOIS, pas deux : le '
        'bouton consomme le geste avant la barre', (tester) async {
      var appuis = 0;
      await tester.pumpWidget(
        barre(vueSentier: false, altitudeM: 1480, onBasculer: () => appuis++),
      );
      await tester.tap(find.text(t.map.basculerVersSentier));
      await tester.pump();
      expect(appuis, 1);
    });

    testWidgets('LA BARRE RESTE TACTILE DANS SON ENSEMBLE — le raccourci de '
        'la tache 747 n est pas perdu', (tester) async {
      var appuis = 0;
      await tester.pumpWidget(
        barre(vueSentier: false, altitudeM: 1480, onBasculer: () => appuis++),
      );
      await tester.tap(find.text('Bastelica - Porticcio'));
      await tester.pump();
      expect(appuis, 1);
    });

    testWidgets('SANS BASCULE, AUCUN BOUTON : un bouton qui ne mene nulle '
        'part est un geste mort', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StageProgressBar(
              stageName: 'Etape de depart',
              distanceRemainingKm: 11.8,
              progressRatio: 0,
              isOffTrack: false,
              totalDistanceKm: 72.9,
              perimetreLabel: t.map.perimetreEtape,
              basculeLabel: t.map.basculerVersSentier,
              showPendingValues: true,
            ),
          ),
        ),
      );
      expect(find.text(t.map.basculerVersSentier), findsNothing);
    });

    testWidgets('EN VUE SENTIER, LES ETAPES FAITES REMPLACENT L ALTITUDE '
        '(decision du 09/10 16:32, forme « 3 / 7 »)', (tester) async {
      await tester.pumpWidget(
        barre(vueSentier: true, etapesFaites: 3, etapesTotal: 7),
      );

      expect(find.text('3 / 7'), findsOneWidget);
      expect(find.text(t.tracking.stagesDone), findsOneWidget);
      expect(
        find.text(t.tracking.altitude),
        findsNothing,
        reason: '« l altitude pure n a plus lieue d etre » (16:29)',
      );
    });

    testWidgets('EN VUE ETAPE, L ALTITUDE DU MOMENT RESTE — elle repond a '
        '« je suis a quelle altitude »', (tester) async {
      await tester.pumpWidget(barre(vueSentier: false, altitudeM: 1480));

      expect(find.text(t.tracking.altitude), findsOneWidget);
      expect(find.text('1480 m'), findsOneWidget);
      expect(find.text(t.tracking.stagesDone), findsNothing);
    });

    testWidgets('LES SIX CASES SONT TOUJOURS LA, dans les deux perimetres', (
      tester,
    ) async {
      for (final vueSentier in [false, true]) {
        await tester.pumpWidget(
          barre(
            vueSentier: vueSentier,
            altitudeM: vueSentier ? null : 1480,
            etapesFaites: vueSentier ? 3 : null,
            etapesTotal: vueSentier ? 7 : null,
          ),
        );
        expect(find.text(t.tracking.total), findsOneWidget);
        expect(find.text(t.tracking.covered), findsOneWidget);
        expect(find.text(t.tracking.avgSpeed), findsOneWidget);
        expect(find.text(t.tracking.dPlus), findsOneWidget);
        expect(find.text(t.tracking.dMinus), findsOneWidget);
      }
    });
  });

  // -------------------------------------------------------------------------
  // CHANTIER 4 — LE SOS SUIT LA MAIN
  // -------------------------------------------------------------------------

  group('LE SOS EST DU COTE DE LA MAIN DOMINANTE', () {
    Widget banc(DominantHand? main) => ProviderScope(
      overrides: [
        if (main != null)
          settingsProvider.overrideWith(() => ReglagesFixes(main)),
      ],
      child: const MaterialApp(home: Scaffold(body: SosDuCoteDeLaMain())),
    );

    MainAxisAlignment alignement(WidgetTester tester) => tester
        .widget<Row>(
          find.descendant(
            of: find.byType(SosDuCoteDeLaMain),
            matching: find.byType(Row).first,
          ),
        )
        .mainAxisAlignment;

    testWidgets('DROITIER PAR DEFAUT : sans reglage lu, le SOS va a DROITE', (
      tester,
    ) async {
      await tester.pumpWidget(banc(null));
      await tester.pump();
      expect(alignement(tester), MainAxisAlignment.end);
    });

    testWidgets('DROITIER : a droite', (tester) async {
      await tester.pumpWidget(banc(DominantHandValues.right));
      await tester.pump();
      expect(alignement(tester), MainAxisAlignment.end);
    });

    testWidgets('GAUCHER : a gauche — le reglage tient enfin sa promesse, '
        '« Place le SOS et les commandes clés du côté de votre main »', (
      tester,
    ) async {
      await tester.pumpWidget(banc(DominantHandValues.left));
      await tester.pump();
      expect(alignement(tester), MainAxisAlignment.start);
    });

    testWidgets('LE BOUTON LUI-MEME EST LE MEME DES DEUX COTES : un seul '
        'widget, deux positions', (tester) async {
      for (final main in [DominantHandValues.right, DominantHandValues.left]) {
        await tester.pumpWidget(banc(main));
        await tester.pump();
        expect(find.byType(SosButton), findsOneWidget);
      }
    });

    testWidgets('IL NE DEPEND D AUCUNE POSITION GPS : il se rend sans fix, '
        'et c est le premier refus de garde de la tache 747', (tester) async {
      await tester.pumpWidget(banc(DominantHandValues.right));
      await tester.pump();
      expect(find.byType(SosDuCoteDeLaMain), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

/// Une etape dont les bornes tombent sur [trace].
StageModel _etape(int numero, double debutM, double finM, List<TrackPoint> t) {
  final depart = t.firstWhere(
    (p) => p.distanceFromStart >= debutM,
    orElse: () => t.first,
  );
  final arrivee = t.firstWhere(
    (p) => p.distanceFromStart >= finM,
    orElse: () => t.last,
  );
  return StageModel(
    trailId: testTrailConfig.id,
    stageNumber: numero,
    name: 'Etape $numero',
    distanceKm: (finM - debutM) / 1000,
    elevationGainM: 100,
    elevationLossM: 80,
    startLat: depart.lat,
    startLng: depart.lng,
    endLat: arrivee.lat,
    endLng: arrivee.lng,
    departureName: 'D$numero',
    arrivalName: 'A$numero',
  );
}
