/// TACHE 744 — LA DEMO NE DEMANDE RIEN, ET ELLE REPREND.
///
/// SUITE IMMEDIATE DU LOT 742, SUR DEUX DEFAUTS MESURES A L'EXECUTION par la
/// recette de la tache 743 (emulateur, bundle release de la branche du lot
/// 742) — et non deux soupcons de relecture.
///
///   ROUGE 1 — UNE FENETRE SYSTEME DE POSITION S'OUVRAIT EN PLEIN MODE DEMO.
///   Le lot 742 avait bien branche la source simulee dans le robinet unique,
///   mais le CONSOMMATEUR en aval (`locationProvider`) exigeait encore une
///   permission dont une simulation n'a aucun besoin. Deux consequences, les
///   deux vues en demonstration : la fenetre mettait l'application en
///   arriere-plan et TUAIT la marche qu'elle interrompait ; et si
///   l'utilisateur refusait, la barre restait a « -- » pour toujours.
///
///   ROUGE 2 — LA MARCHE NE REPRENAIT JAMAIS. La pause en arriere-plan
///   existait ; la reprise n'existait nulle part, et aucun bouton
///   « Reprendre » n'existe dans l'interface. Tout passage en arriere-plan,
///   meme d'une seconde, arretait donc la demonstration DEFINITIVEMENT : il
///   fallait quitter la demo et tout recommencer.
///
/// CE QUE CES GARDES TIENNENT :
///   1. EN DEMO, AUCUNE AUTORISATION N'EST NI DEMANDEE NI CONSULTEE — et la
///      garde rougit si le fournisseur qui mesure le systeme est seulement
///      CONSTRUIT, parce que c'est sa construction qui ouvre la fenetre.
///   2. LE CHEMIN DE LA VRAIE RANDONNEE GARDE SON VERROU, intact.
///   3. AUCUN CHEMIN DE DEMO n'atteint une demande de permission : les trois
///      portes mesurees — le flux de positions de la carte, les pre-vols du
///      bouton de depart, le test de marche — sont fermees, et un QUATRIEME
///      appelant ferait rougir la garde au lieu de passer inapercu.
///   4. LA MARCHE REPREND au retour au premier plan, et SEULEMENT si elle
///      etait en cours : ni apres l'arrivee, ni apres un arret, ni apres la
///      sortie de demo, ni apres une pause voulue par le randonneur.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

import '../structurel/mesure_des_sources_645.dart'
    show estLigneDeCommentaire, lignesDe, sourcesLib;

/// LE CODE de [rel], SANS SES COMMENTAIRES.
///
/// Les gardes de ce fichier cherchent des motifs interdits — `Geolocator.`,
/// `gpsPermissionProvider` — dans des sources dont la DOCUMENTATION explique
/// justement pourquoi ils n'y sont pas, et qui les nomment donc. Sans ce
/// filtre, la garde rougirait sur la phrase qui la justifie.
String _codeDe(String rel) => [
  for (final ligne in lignesDe(rel))
    if (!estLigneDeCommentaire(ligne)) ligne,
].join('\n');

/// LA TRACE DU TEST : 1 km plein nord, un point tous les 50 m.
///
/// Elle sert a faire MARCHER le marcheur, pas a mesurer une randonnee : les
/// chiffres de la marche simulee sont tenus par les gardes du lot 742.
final List<TrackPoint> _trace = <TrackPoint>[
  for (var i = 0; i <= 20; i++)
    TrackPoint(
      lat: 45.0 + (i * 50.0) / 111194.93,
      lng: 3.0,
      altitude: 1000.0 + i * 5.0,
      distanceFromStart: i * 50.0,
    ),
];

final DateTime _depart = DateTime.utc(2026, 10, 9, 8);

/// UNE MINUTERIE QUE LE TEST FAIT AVANCER LUI-MEME : aucun test ne dort.
class _MinuterieFausse implements Timer {
  _MinuterieFausse(this._action);

  final void Function(Timer) _action;
  bool _active = true;
  int _tick = 0;

  /// Declenche [pas] battements, ou s'arrete des que la minuterie est coupee.
  void avancer(int pas) {
    for (var i = 0; i < pas && _active; i++) {
      _tick++;
      _action(this);
    }
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}

/// Garde la derniere minuterie creee, pour que le test la fasse avancer.
class _Horloge {
  _MinuterieFausse? derniere;

  /// La fabrique passee au marcheur.
  FabriqueDeMinuterie get fabrique =>
      (Duration periode, void Function(Timer) action) {
        final minuterie = _MinuterieFausse(action);
        derniere = minuterie;
        return minuterie;
      };
}

/// Un marcheur de test : minuterie pilotee, horloge figee.
///
/// [cycleDeVie] arme le VRAI observateur de cycle de vie de Flutter — celui
/// que la garde du rouge 2 pilote par le binding de test.
({MarcheurSimule marcheur, _Horloge horloge}) _marcheur({
  bool cycleDeVie = false,
}) {
  final horloge = _Horloge();
  final marcheur = MarcheurSimule(
    minuterie: horloge.fabrique,
    maintenant: () => _depart,
    surveillerLeCycleDeVie: cycleDeVie,
  );
  addTearDown(marcheur.fermer);
  return (marcheur: marcheur, horloge: horloge);
}

/// Laisse passer les microtaches : un flux ne livre pas dans la foulee.
Future<void> _laisserPasser() => Future<void>.delayed(Duration.zero);

/// L'APPLICATION PART EN ARRIERE-PLAN, PAR LE CHEMIN QUE FLUTTER LIVRE.
///
/// Les quatre etats sont joues DANS L'ORDRE REEL (`resumed` -> `inactive` ->
/// `hidden` -> `paused`) parce que [AppLifecycleListener] REFUSE les
/// transitions impossibles : il affirme qu'on n'arrive sur `resumed` que
/// depuis `inactive` ou `detached` (son `didChangeAppLifecycleState`). Un test
/// qui sauterait d'un etat a l'autre ne prouverait rien du telephone.
Future<void> _allerEnArrierePlan(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  await tester.pump();
}

/// L'APPLICATION REVIENT AU PREMIER PLAN, par le chemin inverse et legal.
Future<void> _revenirAuPremierPlan(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pump();
}

/// LES DEUX FICHIERS QUI DECLARENT les pre-vols d'autorisation.
///
/// Ils les declarent, ils ne les declenchent pas : un appelant, c'est
/// quelqu'un d'autre. La garde verifie que ces deux-la sont bien les
/// declarants, sinon cette liste pourrait cacher un appelant.
const Set<String> _declarantsDesPrevols = {
  'lib/shared/widgets/background_tracking_rationale_dialog.dart',
  'lib/features/trek/presentation/podometre_autorisation.dart',
};

/// LES SEULS ENDROITS QUI DECLENCHENT un pre-vol d'autorisation.
const Set<String> _appelantsDesPrevols = {
  'lib/features/hub/presentation/widgets/hub_start_trek_button.dart',
  'lib/features/trek/presentation/map/overlay/tracking_overlay.dart',
};

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  /// Le conteneur de la carte, avec un ESPION sur la permission.
  ///
  /// [permissionLue] est pose a vrai si le fournisseur qui MESURE le systeme
  /// est construit. C'est la mesure qui compte : le construire, c'est appeler
  /// Geolocator, donc faire surgir la fenetre systeme.
  ({ProviderContainer conteneur, List<bool> permissionLue}) carte({
    required MarcheurSimule marcheur,
    required bool enDemo,
    String permission = GpsPermissionStateValues.granted,
  }) {
    final permissionLue = <bool>[];
    final conteneur = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        enDemoProvider.overrideWithValue(enDemo),
        marcheurSimuleProvider.overrideWithValue(marcheur),
        // PAS d'override du robinet : on veut le VRAI, pour qu'il choisisse
        // lui-meme sa source selon le mode — c'est le chemin de production.
        gpsPermissionProvider.overrideWith((ref) async {
          permissionLue.add(true);
          return permission;
        }),
      ],
    );
    addTearDown(conteneur.dispose);
    return (conteneur: conteneur, permissionLue: permissionLue);
  }

  // =========================================================================
  // ROUGE 1 — EN DEMO, AUCUNE AUTORISATION N'EST DEMANDEE NI CONSULTEE
  // =========================================================================
  group('744 — en demo, la carte prend les positions simulees sans jamais '
      'consulter la permission', () {
    test('LA GARDE CENTRALE : les positions arrivent, et le fournisseur de '
        'permission n est MEME PAS CONSTRUIT', () async {
      final m = _marcheur();
      final c = carte(marcheur: m.marcheur, enDemo: true);

      final vues = <double>[];
      c.conteneur.listen(locationProvider, (_, v) {
        if (v.hasValue) vues.add(v.value!.latitude);
      });
      await _laisserPasser();

      // La marche part APRES l'abonnement : le flux du marcheur est diffuse,
      // ce qui est emis avant que quelqu'un ecoute n'est livre a personne.
      expect(
        m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id),
        isTrue,
      );
      m.horloge.derniere!.avancer(3);
      await _laisserPasser();

      expect(
        vues,
        isNotEmpty,
        reason:
            'EN DEMO LA CARTE DOIT RECEVOIR LES POSITIONS SIMULEES. Sans '
            'elles, le marqueur ne bouge pas et la barre garde ses « -- » : '
            'c est le defaut mesure a la recette du lot 742.',
      );
      expect(
        c.permissionLue,
        isEmpty,
        reason:
            'LE FOURNISSEUR DE PERMISSION A ETE CONSTRUIT EN DEMO. Le '
            'construire, c est appeler Geolocator.requestPermission() : une '
            'fenetre systeme surgit sur la demonstration et, en passant '
            'l application en arriere-plan, elle met la marche en pause. En '
            'demo, on ne LIT pas ce provider — ne pas le lire est la seule '
            'facon de garantir qu il ne s execute pas.',
      );
    });

    test('meme avec une permission REFUSEE, la demo marche', () async {
      final m = _marcheur();
      final c = carte(
        marcheur: m.marcheur,
        enDemo: true,
        permission: GpsPermissionStateValues.denied,
      );

      final vues = <double>[];
      final erreurs = <Object>[];
      c.conteneur.listen(locationProvider, (_, v) {
        if (v.hasValue) vues.add(v.value!.latitude);
        if (v.hasError) erreurs.add(v.error!);
      });
      await _laisserPasser();

      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(2);
      await _laisserPasser();

      expect(
        erreurs,
        isEmpty,
        reason:
            'UN REFUS NE DOIT PLUS RIEN CASSER EN DEMO : avant la tache 744, '
            'le flux rendait une erreur et la barre restait a « -- » POUR '
            'TOUJOURS — la demonstration etait perdue sur un refus.',
      );
      expect(vues, isNotEmpty);
      expect(c.permissionLue, isEmpty);
    });

    test('HORS DEMO, LE VERROU TIENT : un refus refuse toujours', () async {
      final m = _marcheur();
      final c = carte(
        marcheur: m.marcheur,
        enDemo: false,
        permission: GpsPermissionStateValues.denied,
      );

      final erreurs = <Object>[];
      c.conteneur.listen(locationProvider, (_, v) {
        if (v.hasError) erreurs.add(v.error!);
      });
      await c.conteneur.read(gpsPermissionProvider.future);
      await _laisserPasser();

      expect(
        erreurs,
        isNotEmpty,
        reason:
            'LE CHEMIN DE LA VRAIE RANDONNEE N EST PAS TOUCHE. Sans '
            'permission, il n y a pas de position reelle : le dire est le '
            'travail de ce verrou, et la tache 744 ne le desarme QUE sur le '
            'chemin de demo.',
      );
      expect(
        c.permissionLue,
        isNotEmpty,
        reason: 'Hors demo, la permission est mesuree, comme avant.',
      );
    });

    test('la branche de demo est AVANT toute lecture de la permission', () {
      final source = _codeDe(
        'lib/features/map/providers/location_provider.dart',
      );
      final demo = source.indexOf('if (ref.watch(enDemoProvider))');
      final lecture = source.indexOf('ref.watch(gpsPermissionProvider)');

      expect(demo, greaterThan(-1), reason: 'la branche de demo a disparu');
      expect(lecture, greaterThan(-1), reason: 'le verrou reel a disparu');
      expect(
        demo,
        lessThan(lecture),
        reason:
            'L ORDRE EST LE CORRECTIF. Lire la permission AVANT de regarder '
            'le mode, c est la construire — donc ouvrir la fenetre systeme — '
            'meme si la branche de demo l ignore ensuite.',
      );
    });

    test('la branche de demo ne nomme ni Geolocator ni la permission', () {
      final source = _codeDe(
        'lib/features/map/providers/location_provider.dart',
      );
      final debut = source.indexOf('if (ref.watch(enDemoProvider))');
      final branche = source.substring(
        debut,
        source.indexOf('ref.watch(gpsPermissionProvider)'),
      );

      for (final interdit in [
        'Geolocator',
        'gpsPermissionProvider',
        'requestPermission',
        'checkPermission',
      ]) {
        expect(
          branche.contains(interdit),
          isFalse,
          reason:
              '« $interdit » sur le chemin de demo. La demo n a pas de '
              'recepteur a allumer : elle n a donc rien a autoriser.',
        );
      }
    });

    test('UN SEUL ENDROIT de lib/ lit le fournisseur de permission', () {
      final lecteurs = [
        for (final f in sourcesLib())
          if (_codeDe(f).contains('gpsPermissionProvider')) f,
      ];

      expect(
        lecteurs,
        ['lib/features/map/providers/location_provider.dart'],
        reason:
            'UN DEUXIEME LECTEUR, ET LA FENETRE SYSTEME REVIENT PAR LA '
            'FENETRE. Ce provider MESURE le systeme et ouvre sa demande des '
            'qu il est construit : tant qu il n a qu un lecteur, il suffit de '
            'regarder ce lecteur-la pour savoir si une demo peut declencher '
            'une demande. Un nouveau lecteur doit porter sa propre branche de '
            'demo, et cette garde doit le nommer.',
      );
    });

    test('les pre-vols d autorisation sont TOUS fermes en demo', () {
      final appelants = [
        for (final f in sourcesLib())
          if (!_declarantsDesPrevols.contains(f) &&
              (_codeDe(f).contains('ensureBackgroundTrackingExplained(') ||
                  _codeDe(f).contains('ensureStepCountingExplained(')))
            f,
      ];

      expect(
        appelants.toSet(),
        _appelantsDesPrevols,
        reason:
            'UN APPELANT DE PRE-VOL EST APPARU OU A DISPARU. Ces fonctions '
            'ouvrent la demande systeme de position de fond et celle de '
            'l activite physique : tout appelant doit etre ferme en demo.',
      );

      for (final f in appelants) {
        expect(
          _codeDe(f).contains('!ref.read(enDemoProvider)'),
          isTrue,
          reason:
              '$f DECLENCHE UN PRE-VOL D AUTORISATION SANS GARDE DE DEMO. Le '
              'bouton du cockpit le fait depuis la tache 638 ; celui de la '
              'carte ne le faisait pas, et c est la deuxieme porte par '
              'laquelle une fenetre systeme entrait en demonstration '
              '(tache 744).',
        );
      }
    });

    test('le placement sorti du marcheur reste sous la MEME garde : il ne '
        'cumule rien, et il ne connait pas le GPS', () {
      // SORTIR DU CODE D'UN FICHIER GARDE NE DOIT PAS LE SORTIR DE SA GARDE.
      // Le placement sur la trace a quitte `marcheur_simule.dart` a la tache
      // 744 pour tenir le plafond de 500 lignes (ECR-15) ; les deux gardes du
      // lot 742 qui le couvraient — aucun second moteur de calcul, aucun GPS —
      // le suivent ici. Sans ce cas, le decoupage aurait ete une porte de
      // sortie silencieuse.
      const chemin = 'lib/features/trek/data/placement_sur_la_trace.dart';
      final source = _codeDe(chemin);

      for (final interdit in [
        'haversine',
        'Haversine',
        'elevationNoiseThreshold',
        'elevationGain',
        'distanceKm',
        'averageSpeed',
      ]) {
        expect(
          source.contains(interdit),
          isFalse,
          reason:
              'LE PLACEMENT PLACE, IL NE MESURE RIEN. « $interdit » ici, '
              'c est un SECOND moteur qui commence — et deux moteurs donnent '
              'deux deniveles pour la meme journee (lot 671-06).',
        );
      }

      for (final interdit in [
        'Geolocator',
        'Permission',
        'SessionTrackPoint',
        'dao',
      ]) {
        expect(
          source.contains(interdit),
          isFalse,
          reason:
              '« $interdit » dans le placement. Il recoit une trace et une '
              'distance, il rend un point : ni recepteur, ni autorisation, ni '
              'base de donnees.',
        );
      }
    });

    test('les declarants des pre-vols declarent bien, et n appellent pas', () {
      for (final f in _declarantsDesPrevols) {
        final code = _codeDe(f);
        expect(
          code.contains('Future<void> ensureBackgroundTrackingExplained(') ||
              code.contains('Future<void> ensureStepCountingExplained('),
          isTrue,
          reason:
              '$f N EST PLUS UN DECLARANT. Cette liste sert a EXCLURE les '
              'declarations du comptage des appelants ; si elle contient '
              'autre chose, elle cache un appelant au lieu de l exempter.',
        );
      }
    });

    test('le test de marche, qui demande la position, est grise en demo', () {
      // CHAQUE SITE, PAS CHAQUE FICHIER. Mesurer « le fichier contient-il
      // GriseEnDemo ? » ne prouve rien ici : `feasibility_tiles.dart` porte
      // DEUX chemins vers le test de marche, et le premier etait deja grise
      // depuis la tache 638 — un fichier « conforme » pouvait donc cacher un
      // second chemin nu. On remonte donc depuis CHAQUE navigation.
      const fenetre = 12;
      final sites = <String>[];

      for (final f in sourcesLib()) {
        final lignes = lignesDe(f);
        for (var i = 0; i < lignes.length; i++) {
          if (estLigneDeCommentaire(lignes[i])) continue;
          if (!lignes[i].contains("/walk-test'")) continue;
          sites.add('$f:${i + 1}');

          final debut = i - fenetre < 0 ? 0 : i - fenetre;
          final amont = lignes
              .sublist(debut, i)
              .where((l) => !estLigneDeCommentaire(l))
              .join('\n');

          expect(
            amont.contains('GriseEnDemo('),
            isTrue,
            reason:
                '$f:${i + 1} MENE AU TEST DE MARCHE SANS LE GRISER EN DEMO. '
                'Le test de marche DEMANDE la permission de position avant '
                'de mesurer (`walk_test_provider`, `gps.requestPermission()`) '
                ': atteignable en demo, il fait surgir une fenetre systeme '
                'qui met la marche simulee en pause. Et il ECRIT une donnee '
                'de personne, ce que la regle de la tache 638 (bug 14) grise '
                'deja — le raccourci des tuiles etait grise, les DEUX autres '
                'chemins vers le MEME ecran ne l etaient pas (tache 744).',
          );
        }
      }

      expect(
        sites,
        hasLength(3),
        reason:
            'TROIS CHEMINS MENENT AU TEST DE MARCHE, mesures le 08/10 : le '
            'raccourci des tuiles, l etape 2 du parcours guide et la carte de '
            'la vue de depannage. Un quatrieme doit etre grise lui aussi, et '
            'un chemin qui disparait doit sortir de ce compte sciemment.\n'
            '  ${sites.join('\n  ')}',
      );
    });
  });

  // =========================================================================
  // ROUGE 2 — LA MARCHE REPREND, ET SEULEMENT SI ELLE ETAIT EN COURS
  // =========================================================================
  group('744 — le retour au premier plan relance la marche, et lui seule', () {
    testWidgets('elle REPREND quand l application revient', (tester) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(2);
      expect(m.marcheur.etat, EtatDuMarcheur.enMarche);

      await _allerEnArrierePlan(tester);
      expect(m.marcheur.etat, EtatDuMarcheur.enPause);
      expect(m.marcheur.minuterieActive, isFalse);

      await _revenirAuPremierPlan(tester);

      expect(
        m.marcheur.etat,
        EtatDuMarcheur.enMarche,
        reason:
            'LA MARCHE NE REPRENAIT JAMAIS (mesure a la recette de la tache '
            '743). Un passage en arriere-plan d une seconde arretait la '
            'demonstration pour de bon, et aucun bouton « Reprendre » '
            'n existe dans l interface : il fallait quitter la demo et tout '
            'recommencer.',
      );
      expect(
        m.marcheur.minuterieActive,
        isTrue,
        reason: 'reprendre sans minuterie, c est un etat qui mentirait',
      );
    });

    testWidgets('et elle reprend LA MEME marche, la ou elle en etait', (
      tester,
    ) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(4);
      final relevesAvant = m.marcheur.releves.length;
      final distanceAvant = m.marcheur.distanceSimuleeM;

      await _allerEnArrierePlan(tester);
      await _revenirAuPremierPlan(tester);
      m.horloge.derniere!.avancer(3);

      expect(
        m.marcheur.releves.length,
        greaterThan(relevesAvant),
        reason: 'apres la reprise, les releves doivent reprendre leur cours',
      );
      expect(
        m.marcheur.distanceSimuleeM,
        greaterThan(distanceAvant),
        reason:
            'LA REPRISE N EST PAS UN REDEPART : la marche continue d ou elle '
            's etait interrompue, elle ne revient pas au depart.',
      );
    });

    testWidgets('elle NE REPREND PAS apres l arrivee', (tester) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      // Assez de battements pour atteindre le bout de la trace.
      m.horloge.derniere!.avancer(200);
      expect(m.marcheur.etat, EtatDuMarcheur.arrive);

      await _allerEnArrierePlan(tester);
      await _revenirAuPremierPlan(tester);

      expect(
        m.marcheur.etat,
        EtatDuMarcheur.arrive,
        reason:
            'ARRIVE, C EST FINI. Le randonneur regarde sa journee : relancer '
            'la marche lui ferait repartir tout seul.',
      );
      expect(m.marcheur.minuterieActive, isFalse);
    });

    testWidgets('elle NE REPREND PAS apres un arret', (tester) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(2);
      m.marcheur.arreter();
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);

      await _allerEnArrierePlan(tester);
      await _revenirAuPremierPlan(tester);

      expect(m.marcheur.etat, EtatDuMarcheur.arrete);
      expect(m.marcheur.minuterieActive, isFalse);
      expect(
        m.marcheur.releves,
        isEmpty,
        reason:
            'Un arret a tout jete : une reprise fabriquerait des releves que '
            'personne n a demandes.',
      );
    });

    testWidgets('elle NE REPREND PAS apres la sortie de demo', (tester) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(2);

      final c = carte(marcheur: m.marcheur, enDemo: true);
      await c.conteneur
          .read(trekSessionManagerProvider.notifier)
          .arreterSimulationDemo();
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);

      await _allerEnArrierePlan(tester);
      await _revenirAuPremierPlan(tester);

      expect(
        m.marcheur.minuterieActive,
        isFalse,
        reason:
            'LA SORTIE DE DEMO PROMET QU IL NE RESTE RIEN. Une minuterie qui '
            'repartirait au retour au premier plan serait une simulation qui '
            'survit a la demo : exactement ce que le lot 742 interdit.',
      );
      expect(m.marcheur.etat, EtatDuMarcheur.arrete);
    });

    testWidgets('elle NE REPREND PAS une pause VOULUE par le randonneur', (
      tester,
    ) async {
      final m = _marcheur(cycleDeVie: true);
      m.marcheur.demarrer(trace: _trace, trailId: testTrailConfig.id);
      m.horloge.derniere!.avancer(2);
      // La pause du suivi, celle que `tracking_providers` repercute quand le
      // randonneur met SA randonnee en pause.
      m.marcheur.pause();
      expect(m.marcheur.etat, EtatDuMarcheur.enPause);

      await _allerEnArrierePlan(tester);
      await _revenirAuPremierPlan(tester);

      expect(
        m.marcheur.etat,
        EtatDuMarcheur.enPause,
        reason:
            'LA REPRISE REPARE UNE INTERRUPTION, ELLE NE DEFAIT PAS UN CHOIX. '
            'La marche n etait pas « en cours » quand l ecran s est eteint : '
            'le randonneur l avait mise en pause. Un retour au premier plan '
            'qui la relancerait lui reprendrait sa decision — et c est pour '
            'cela que la reprise regarde la CAUSE de la pause, et pas '
            'seulement l etat.',
      );
      expect(m.marcheur.minuterieActive, isFalse);
    });
  });
}
