// LOT 596 (C4) — AUCUN RAPPORT DE PLANTAGE NE REMONTE, A 100 % DES DEMARRAGES.
//
// `Firebase.initializeApp()` n'etait JAMAIS execute : `firebaseProjectId` n'est
// renseigne dans AUCUNE configuration de sentier, et `FirebaseService.initialize`
// sort a la premiere ligne quand il est nul. Consequence mesuree : zero rapport
// de plantage, zero statistique, a chaque lancement. Chris publierait a l'aveugle
// — il ne saurait meme pas que l'appli plante chez ses utilisateurs.
//
// TROIS DEFAUTS INDEPENDANTS, chacun suffisant a lui seul :
//   1. la valeur de configuration n'a aucun point d'entree (ni --dart-define, ni
//      fichier, ni sentier) ;
//   2. AUCUN filet d'erreur n'est pose : `FlutterError.onError`,
//      `PlatformDispatcher.instance.onError`, `runZonedGuarded` — zero occurrence
//      dans lib/. Meme Firebase allume, rien ne serait rapporte ;
//   3. quatre acces Firestore n'ont aucune garde de disponibilite : ils
//      planteraient le jour ou Firebase s'allume, c'est-a-dire le jour du
//      correctif.
//
// ET LE GARDE-FOU : configuration absente = l'appli fonctionne NORMALEMENT et le
// DIT. Jamais un plantage au demarrage.
//
// TESTS ECRITS ROUGES AVANT CORRECTION.
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/firebase_config.dart';
import 'package:moteur_gr/core/error/error_nets.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/services/firestore_complaint_sink.dart';
import 'package:moteur_gr/core/services/firestore_moderation_store.dart';
import 'package:moteur_gr/core/services/complaint_service.dart';
import 'package:moteur_gr/core/services/moderation_service.dart';
import 'package:moteur_gr/core/firebase/cloud_indisponible.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/features/booking/data/booking_data_service.dart';

/// Puits de plantage espion : note l'etat de la collecte et ce qui remonte.
class _CrashEspion implements CrashSink {
  /// `null` = personne n'a touche l'interrupteur.
  bool? collecte;
  final List<bool> rapportes = <bool>[];

  @override
  Future<void> recordError(Object error, StackTrace? stack,
      {required bool fatal}) async {
    rapportes.add(fatal);
  }

  @override
  Future<void> setCollectionEnabled(bool enabled) async => collecte = enabled;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LOT 596 C4 — la configuration a un point d entree, et aucune cle '
      'n est dans le depot', () {
    test('sans injection au build, l appli se sait SANS configuration Firebase',
        () {
      // Le depot ne porte AUCUNE valeur : c'est la regle. La configuration
      // arrive par --dart-define au moment du build.
      expect(FirebaseConfig.isConfigured, isFalse,
          reason: 'aucune valeur Firebase ne doit etre ecrite dans le depot');
      expect(FirebaseConfig.projectId, isNull);
    });

    test('le nom de la variable de build est publie et stable', () {
      // Chris (ou la CI) doit pouvoir la passer sans deviner son nom.
      expect(FirebaseConfig.variableDeBuild, 'STEPWAYS_FIREBASE_PROJECT_ID');
    });

    test('AUCUNE cle Firebase en clair dans lib/ — balayage du code source',
        () {
      final fautifs = <String>[];
      final racine = Directory('lib');
      for (final f in racine
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final texte = f.readAsStringSync();
        // Prefixe des cles d'API Google, et forme d'un appId Firebase.
        if (texte.contains('AIza') ||
            RegExp(r'1:\d{6,}:(android|ios|web):').hasMatch(texte)) {
          fautifs.add(f.path);
        }
      }
      expect(fautifs, isEmpty,
          reason: 'une cle Firebase en clair dans le depot : ${fautifs.join(", ")}');
    });
  });

  group('LOT 596 C4 — sans configuration, l appli demarre et le DIT', () {
    test('initialize sans projet : indisponible, AUCUNE exception, et la '
        'raison est nommee', () async {
      final service = await FirebaseService.initialize(firebaseProjectId: null);
      expect(service.isAvailable, isFalse);
      expect(service.raisonIndisponible, FirebaseIndisponible.configurationAbsente,
          reason: 'l appli doit savoir POURQUOI elle est en mode local, sinon '
              'personne ne peut diagnostiquer les zero rapports de plantage');
    });

    test('initialize avec un projet mais sans options natives : indisponible '
        'pour ECHEC, pas pour absence de configuration', () async {
      final service = await FirebaseService.initialize(
        firebaseProjectId: 'un-projet-quelconque',
        timeout: const Duration(milliseconds: 200),
      );
      expect(service.isAvailable, isFalse);
      expect(service.raisonIndisponible, FirebaseIndisponible.echecInitialisation,
          reason: 'confondre « pas configure » et « configuration cassee » '
              'rend le probleme introuvable');
    });

    test('un service disponible n a aucune raison d indisponibilite', () {
      expect(FirebaseService.testOnly(isAvailable: true).raisonIndisponible,
          isNull);
    });
  });

  group('LOT 596 C4 — les filets d erreur existent et attrapent', () {
    tearDown(ErrorNets.retirerPourTest);

    test('installer() pose les DEUX filets', () {
      ErrorNets.installer();
      expect(PlatformDispatcher.instance.onError, isNotNull,
          reason: 'aucun filet sur les erreurs hors arbre de widgets : elles '
              'disparaissent sans laisser de trace');
      expect(ErrorNets.installes, isTrue);
    });

    test('une erreur de rendu part au rapporteur', () {
      final recues = <Object>[];
      ErrorNets.installer();
      ErrorNets.brancherRapporteur(
          (error, stack, {bool fatal = false}) => recues.add(error));

      FlutterError.onError!(FlutterErrorDetails(
        exception: StateError('ecran casse'),
        stack: StackTrace.current,
      ));

      expect(recues, hasLength(1),
          reason: 'une erreur de rendu ne remonte a personne');
    });

    test('une erreur hors arbre part au rapporteur, marquee FATALE', () {
      Object? recue;
      var fatalVu = false;
      ErrorNets.installer();
      ErrorNets.brancherRapporteur((error, stack, {bool fatal = false}) {
        recue = error;
        fatalVu = fatal;
      });

      final traitee = PlatformDispatcher.instance.onError!(
          StateError('plantage hors arbre'), StackTrace.current);

      expect(traitee, isTrue);
      expect(recue, isA<StateError>());
      expect(fatalVu, isTrue,
          reason: 'un plantage non rattrape est un crash : il doit etre '
              'rapporte comme fatal');
    });

    test('SANS rapporteur branche (mode local), rien ne plante', () {
      ErrorNets.installer();
      expect(
        () => FlutterError.onError!(FlutterErrorDetails(
          exception: StateError('sans rapporteur'),
          stack: StackTrace.current,
        )),
        returnsNormally,
        reason: 'le filet lui-meme ne doit jamais faire tomber l appli',
      );
    });

    test('un rapporteur qui echoue ne fait pas tomber l appli', () {
      ErrorNets.installer();
      ErrorNets.brancherRapporteur((error, stack, {bool fatal = false}) {
        throw StateError('le rapporteur est casse');
      });
      expect(
        () => PlatformDispatcher.instance.onError!(
            StateError('boum'), StackTrace.current),
        returnsNormally,
      );
    });
  });

  group('LOT 596 C4 — le troisieme verrou : le consentement ANALYTICS '
      'eteignait les rapports de plantage', () {
    test('couper la mesure d usage NE COUPE PAS la remontee des plantages',
        () async {
      final crash = _CrashEspion();
      final service =
          AnalyticsService(analytics: const NoOpAnalyticsSink(), crash: crash);

      // C'est exactement ce que fait `analyticsServiceProvider` des sa
      // construction (opt-in strict).
      await service.setConsent(granted: false);

      expect(crash.collecte, isNot(false),
          reason: 'le premier lecteur du provider coupait Crashlytics pour '
              'toute la session : meme Firebase allume et les filets poses, '
              'chaque rapport partait a la poubelle');
    });

    test('la remontee des plantages a son PROPRE interrupteur', () async {
      final crash = _CrashEspion();
      final service =
          AnalyticsService(analytics: const NoOpAnalyticsSink(), crash: crash);
      await service.setCrashCollection(enabled: true);
      expect(crash.collecte, isTrue);
    });

    test('un plantage est rapporte MEME sans consentement de mesure d usage',
        () async {
      final crash = _CrashEspion();
      final service =
          AnalyticsService(analytics: const NoOpAnalyticsSink(), crash: crash);
      await service.setConsent(granted: false);

      await service.recordFatal(StateError('boum'), StackTrace.current);

      expect(crash.rapportes, hasLength(1),
          reason: 'recordError/recordFatal etaient gardes par le consentement '
              'analytics, toujours faux : ils ne rapportaient JAMAIS rien');
      expect(crash.rapportes.single, isTrue, reason: 'fatal');
    });

    test('service inerte (Firebase absent) : rien n est rapporte', () async {
      final service = AnalyticsService.disabled();
      await service.recordError(StateError('boum'), StackTrace.current);
      expect(service.isOperational, isFalse);
    });
  });

  group('LOT 596 C4 — les quatre acces Firestore sans garde', () {
    final indisponible = FirebaseService.testOnly(isAvailable: false);

    test('la plainte art. 20 est REFUSEE proprement, sans toucher Firestore',
        () async {
      final sink = FirestoreComplaintSink(
        currentUidHash: () => 'abc123',
        firebaseService: indisponible,
      );
      await expectLater(
        sink.saveComplaint(ModerationComplaint(
          contentType: ModeratedContentType.trailReport,
          contentRef: 'c1',
          expose: 'je conteste cette decision',
          createdAt: DateTime(2026, 1, 1),
        )),
        throwsA(isA<CloudIndisponibleException>()),
      );
    });

    test('le signalement de contenu est REFUSE proprement', () async {
      final store = FirestoreModerationStore(firebaseService: indisponible);
      await expectLater(
        store.saveReport(ModerationReport(
          id: 'm1',
          contentType: ModeratedContentType.trailReport,
          contentRef: 'c1',
          motif: 'contenu trompeur',
          notifierContact: 'randonneur@exemple.fr',
          bonneFoi: true,
          createdAt: DateTime(2026, 1, 1),
        )),
        throwsA(isA<CloudIndisponibleException>()),
      );
    });

    test('le service de reservation se CONSTRUIT sans Firebase (il explosait '
        'avant meme d etre utilise)', () {
      expect(() => BookingDataService(firebaseService: indisponible),
          returnsNormally,
          reason: 'l acces Firestore etait dans la liste d initialisation du '
              'constructeur : impossible a rattraper par l appelant');
    });
  });
}
