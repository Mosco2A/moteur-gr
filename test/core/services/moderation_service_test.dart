// D4C-01 — Tests du ModerationService notice-and-action DSA art 16
// (design D4 CORDO #86166).
//
// Couvre :
//   - creation d'une notification VALIDE avec les mentions art 16 (motif,
//     reference contenu, contact notifiant, bonne foi), horodatee, statut
//     initial 'recue' ;
//   - REFUS (InvalidModerationReport) si une mention obligatoire manque :
//     motif vide, reference vide, contact invalide, bonne foi non declaree
//     (zero catch silencieux : l'erreur remonte) ;
//   - transitions de statut de la notification (recue -> en_traitement ->
//     traitee avec decision) ;
//   - transitions du moderationState du contenu cible apres decision
//     (moderation A POSTERIORI : keep -> visible, restrict -> flagged,
//     remove -> removed) appliquees sur la bonne collection ;
//   - serialisation art 16 (toMap) et stabilite des cles d'enum.
//
// Le backend est un faux [ModerationStore] en memoire : le service est pur
// (aucune dependance Firebase), donc testable hors reseau.

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/moderation_service.dart';

/// Faux store en memoire qui enregistre les appels pour assertion.
class _FakeModerationStore implements ModerationStore {
  final List<ModerationReport> saved = <ModerationReport>[];
  final List<ModerationReport> updated = <ModerationReport>[];
  final List<({ModeratedContentType type, String ref, ContentModerationState state})>
      applied = [];

  @override
  Future<void> saveReport(ModerationReport report) async {
    saved.add(report);
  }

  @override
  Future<void> updateReport(ModerationReport report) async {
    updated.add(report);
  }

  @override
  Future<void> applyContentState(
    ModeratedContentType contentType,
    String contentRef,
    ContentModerationState state,
  ) async {
    applied.add((type: contentType, ref: contentRef, state: state));
  }
}

void main() {
  late _FakeModerationStore store;
  final DateTime fixedNow = DateTime.utc(2026, 6, 15, 16, 30);

  ModerationService buildService() => ModerationService(
        store: store,
        idGenerator: () => 'report-fixed-id',
        now: () => fixedNow,
      );

  setUp(() {
    store = _FakeModerationStore();
  });

  group('reportContent — notice-and-action art 16', () {
    test('cree une notification valide horodatee au statut recue', () async {
      final service = buildService();

      final report = await service.reportContent(
        contentType: ModeratedContentType.waypoint,
        contentRef: 'wp-123',
        motif: 'Contenu manifestement illicite',
        notifierContact: 'temoin@example.com',
        bonneFoi: true,
      );

      expect(report.id, 'report-fixed-id');
      expect(report.contentType, ModeratedContentType.waypoint);
      expect(report.contentRef, 'wp-123');
      expect(report.motif, 'Contenu manifestement illicite');
      expect(report.notifierContact, 'temoin@example.com');
      expect(report.bonneFoi, isTrue);
      expect(report.createdAt, fixedNow);
      expect(report.status, ModerationStatus.recue);
      expect(report.decision, isNull);

      // Persistee une seule fois.
      expect(store.saved, hasLength(1));
      expect(store.saved.single.id, 'report-fixed-id');
    });

    test('diffuse la notification creee sur le flux reports', () async {
      final service = buildService();
      final emissions = <ModerationReport>[];
      final sub = service.reports.listen(emissions.add);

      await service.reportContent(
        contentType: ModeratedContentType.activity,
        contentRef: 'act-1',
        motif: 'spam',
        notifierContact: 'a@b.fr',
        bonneFoi: true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(emissions, hasLength(1));
      expect(emissions.single.contentRef, 'act-1');
      await sub.cancel();
      service.dispose();
    });

    test('trim les champs et conserve la valeur nettoyee', () async {
      final service = buildService();

      final report = await service.reportContent(
        contentType: ModeratedContentType.trailReport,
        contentRef: '  tr-9  ',
        motif: '  motif important  ',
        notifierContact: '  user@mail.com  ',
        bonneFoi: true,
      );

      expect(report.contentRef, 'tr-9');
      expect(report.motif, 'motif important');
      expect(report.notifierContact, 'user@mail.com');
    });

    test('REFUSE un motif vide (art 16) — erreur remontee', () async {
      final service = buildService();

      expect(
        () => service.reportContent(
          contentType: ModeratedContentType.waypoint,
          contentRef: 'wp-1',
          motif: '   ',
          notifierContact: 'a@b.fr',
          bonneFoi: true,
        ),
        throwsA(isA<InvalidModerationReport>()),
      );
      expect(store.saved, isEmpty);
    });

    test('REFUSE une reference de contenu vide (art 16)', () async {
      final service = buildService();

      expect(
        () => service.reportContent(
          contentType: ModeratedContentType.waypoint,
          contentRef: '  ',
          motif: 'motif',
          notifierContact: 'a@b.fr',
          bonneFoi: true,
        ),
        throwsA(isA<InvalidModerationReport>()),
      );
      expect(store.saved, isEmpty);
    });

    test('REFUSE un contact notifiant invalide (art 16)', () async {
      final service = buildService();

      for (final bad in <String>['', 'pasdemail', '@nope', 'a@', 'a@b.']) {
        expect(
          () => service.reportContent(
            contentType: ModeratedContentType.waypoint,
            contentRef: 'wp-1',
            motif: 'motif',
            notifierContact: bad,
            bonneFoi: true,
          ),
          throwsA(isA<InvalidModerationReport>()),
          reason: 'contact "$bad" doit etre refuse',
        );
      }
      expect(store.saved, isEmpty);
    });

    test('REFUSE si la bonne foi n\'est pas declaree (art 16)', () async {
      final service = buildService();

      expect(
        () => service.reportContent(
          contentType: ModeratedContentType.waypoint,
          contentRef: 'wp-1',
          motif: 'motif',
          notifierContact: 'a@b.fr',
          bonneFoi: false,
        ),
        throwsA(isA<InvalidModerationReport>()),
      );
      expect(store.saved, isEmpty);
    });
  });

  group('transitions de statut de la notification', () {
    test('markInProgress passe la notification a en_traitement', () async {
      final service = buildService();
      final report = await service.reportContent(
        contentType: ModeratedContentType.waypointComment,
        contentRef: 'cmt-1',
        motif: 'injure',
        notifierContact: 'a@b.fr',
        bonneFoi: true,
      );

      final inProgress = await service.markInProgress(report);

      expect(inProgress.status, ModerationStatus.enTraitement);
      expect(store.updated, hasLength(1));
      expect(store.updated.single.status, ModerationStatus.enTraitement);
      // Immutabilite : l'original n'est pas mute.
      expect(report.status, ModerationStatus.recue);
    });
  });

  group('decide — moderation A POSTERIORI (art 16/17)', () {
    Future<ModerationReport> seedReport(
      ModerationService service, {
      ModeratedContentType type = ModeratedContentType.waypoint,
      String ref = 'wp-1',
    }) =>
        service.reportContent(
          contentType: type,
          contentRef: ref,
          motif: 'motif',
          notifierContact: 'a@b.fr',
          bonneFoi: true,
        );

    test('remove -> contenu cible passe removed sur la bonne collection',
        () async {
      final service = buildService();
      final report = await seedReport(service,
          type: ModeratedContentType.waypoint, ref: 'wp-42');

      final decided = await service.decide(report, ModerationDecision.remove);

      expect(decided.status, ModerationStatus.traitee);
      expect(decided.decision, ModerationDecision.remove);
      expect(store.applied, hasLength(1));
      expect(store.applied.single.type, ModeratedContentType.waypoint);
      expect(store.applied.single.ref, 'wp-42');
      expect(store.applied.single.state, ContentModerationState.removed);
    });

    test('restrict -> contenu cible passe flagged', () async {
      final service = buildService();
      final report = await seedReport(service);

      final decided = await service.decide(report, ModerationDecision.restrict);

      expect(decided.decision, ModerationDecision.restrict);
      expect(store.applied.single.state, ContentModerationState.flagged);
    });

    test('keep -> contenu cible (re)devient visible', () async {
      final service = buildService();
      final report = await seedReport(service);

      final decided = await service.decide(report, ModerationDecision.keep);

      expect(decided.decision, ModerationDecision.keep);
      expect(store.applied.single.state, ContentModerationState.visible);
    });

    test('la decision met aussi a jour la notification (statut traitee)',
        () async {
      final service = buildService();
      final report = await seedReport(service);

      await service.decide(report, ModerationDecision.remove);

      expect(store.updated, hasLength(1));
      expect(store.updated.single.status, ModerationStatus.traitee);
      expect(store.updated.single.decision, ModerationDecision.remove);
    });
  });

  group('serialisation et enums', () {
    test('toMap porte les mentions art 16 + statut', () async {
      final report = ModerationReport(
        id: 'r1',
        contentType: ModeratedContentType.activity,
        contentRef: 'act-9',
        motif: 'haine',
        notifierContact: 'x@y.fr',
        bonneFoi: true,
        createdAt: fixedNow,
      );

      final map = report.toMap();
      expect(map['contentType'], 'activity');
      expect(map['contentRef'], 'act-9');
      expect(map['motif'], 'haine');
      expect(map['notifierContact'], 'x@y.fr');
      expect(map['bonneFoi'], true);
      expect(map['status'], 'recue');
      expect(map['createdAt'], fixedNow);
      // Pas de decision tant que non traitee.
      expect(map.containsKey('decision'), isFalse);
    });

    test('toMap inclut la decision une fois traitee', () {
      final report = ModerationReport(
        id: 'r1',
        contentType: ModeratedContentType.waypoint,
        contentRef: 'wp-1',
        motif: 'm',
        notifierContact: 'x@y.fr',
        bonneFoi: true,
        createdAt: fixedNow,
        status: ModerationStatus.traitee,
        decision: ModerationDecision.remove,
      );

      expect(report.toMap()['decision'], 'remove');
      expect(report.toMap()['status'], 'traitee');
    });

    test('ModeratedContentType mappe la bonne collection', () {
      expect(ModeratedContentType.trailReport.collectionName, 'trail_reports');
      expect(ModeratedContentType.activity.collectionName, 'activities');
      expect(ModeratedContentType.waypoint.collectionName, 'waypoints');
      expect(ModeratedContentType.waypointComment.collectionName,
          'waypoint_comments');
    });

    test('ModeratedContentType.fromStorageKey reversible, leve si inconnu', () {
      for (final t in ModeratedContentType.values) {
        expect(ModeratedContentType.fromStorageKey(t.storageKey), t);
      }
      expect(
        () => ModeratedContentType.fromStorageKey('inconnu'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ContentModerationState wire reversible, leve si inconnu', () {
      for (final s in ContentModerationState.values) {
        expect(ContentModerationState.fromWire(s.wireValue), s);
      }
      expect(
        () => ContentModerationState.fromWire('zombie'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ModerationDecision porte l\'etat resultant attendu', () {
      expect(ModerationDecision.keep.resultingState,
          ContentModerationState.visible);
      expect(ModerationDecision.restrict.resultingState,
          ContentModerationState.flagged);
      expect(ModerationDecision.remove.resultingState,
          ContentModerationState.removed);
    });
  });
}
