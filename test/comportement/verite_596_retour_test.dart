// LOT 596 (C1) — LE RETOUR UTILISATEUR EST MARQUE « ENVOYE » SANS JAMAIS PARTIR.
//
// LE FAUX SUCCES LE PLUS COUTEUX DE L'APPLI. Deux etages mentaient, chacun de
// son cote :
//
//   * `FeedbackNotifier._trySendPending()` appelait `_dao.markSent()` sur chaque
//     element en attente, avec en commentaire « Simulation d'envoi (pas de
//     backend Firebase) / En production, appeler l'API ici » ;
//   * `FeedbackService._sendToBackend()` attendait 10 millisecondes et rendait
//     `true`. Toujours.
//
// Et l'ecran remerciait. On croit ecouter ses clients avant de vendre, on
// n'entend rien — et la file locale se VIDE (`clearSent`), donc le message est
// perdu pour de bon.
//
// A NE PAS CONFONDRE AVEC LE LOT X : il a corrige le BOUTON (champ vide muet,
// booleen de retour jamais lu). Deux couches differentes : la sienne est bonne,
// celle-ci ne l'etait pas.
//
// LA REGLE : soit le retour part vraiment, soit l'appli dit honnetement qu'il
// est garde sur ce telephone. JAMAIS un merci pour un message qui ne partira
// pas.
//
// TESTS ECRITS ROUGES AVANT CORRECTION.
library;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/feedback_queue_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/features/feedback/data/feedback_service.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/parcours_reel.dart';

/// Textes francais attendus a l'ecran (l'appli reelle demarre en fr).
final _tr = AppLocale.fr.buildSync();

class FauxReseau extends ConnectivityMonitor {
  FauxReseau({this.statut = ConnectivityStatusValues.online})
      : super(connectivity: Connectivity());

  String statut;

  @override
  Future<ConnectivityStatus> checkStatus() async => statut;
}

/// Puits d'envoi espion : note ce qui lui est REELLEMENT remis.
class PuitsEspion implements FeedbackSink {
  PuitsEspion({this.accepte = true});

  bool accepte;
  final List<String> recus = <String>[];

  @override
  Future<void> envoyer(FeedbackQueueData feedback) async {
    if (!accepte) throw StateError('reception refusee');
    recus.add(feedback.content);
  }
}

void main() {
  late AppDatabase db;
  late FeedbackQueueDao dao;
  late FauxReseau reseau;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = FeedbackQueueDao(db);
    reseau = FauxReseau();
  });

  tearDown(() async => db.close());

  group('LOT 596 C1 — sans destinataire, rien n est declare envoye', () {
    test('SANS PUITS D ENVOI, le retour RESTE en attente (il etait marque '
        'envoye, puis efface)', () async {
      final service = FeedbackService(
        dao: dao,
        connectivityMonitor: reseau,
        sink: null, // aucun backend : c'est l'etat reel de l'appli aujourd'hui
      );

      final resultat = await service.submit(
        trailId: 'mare-a-mare-centre',
        category: FeedbackCategory.bug,
        content: 'La carte se fige au col',
      );

      expect(resultat, FeedbackIssue.gardeLocalement,
          reason: 'sans destinataire, le service doit DIRE qu il garde, pas '
              'pretendre qu il a envoye');
      final enAttente = await dao.getPending();
      expect(enAttente, hasLength(1),
          reason: 'le retour a ete marque envoye sans destinataire — et la '
              'file a ete videe : le message de l utilisateur est PERDU');
      expect(enAttente.single.content, 'La carte se fige au col');
    });

    test('le comptage des retours en attente ne ment pas non plus', () async {
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: null);
      await service.submit(
          trailId: 't', category: FeedbackCategory.bug, content: 'un');
      await service.submit(
          trailId: 't', category: FeedbackCategory.suggestion, content: 'deux');
      expect(await service.pendingCount(), 2,
          reason: 'l ecran affichait zero en attente alors que rien n etait '
              'parti');
    });

    test('flush sans puits n envoie rien et ne vide rien', () async {
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: null);
      await service.submit(
          trailId: 't', category: FeedbackCategory.bug, content: 'garde-moi');
      expect(await service.flush(), 0);
      expect(await dao.getPending(), hasLength(1));
    });
  });

  group('LOT 596 C1 — avec un vrai destinataire, le retour part vraiment', () {
    test('le contenu est REMIS au puits, puis seulement marque envoye',
        () async {
      final puits = PuitsEspion();
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: puits);

      final resultat = await service.submit(
        trailId: 'mare-a-mare-centre',
        category: FeedbackCategory.compliment,
        content: 'Le decoupage des etapes est parfait',
      );

      expect(resultat, FeedbackIssue.envoye);
      expect(puits.recus, ['Le decoupage des etapes est parfait'],
          reason: 'le retour doit REELLEMENT etre remis au destinataire');
      expect(await dao.getPending(), isEmpty);
    });

    test('un envoi qui ECHOUE laisse le retour recuperable, jamais efface',
        () async {
      final puits = PuitsEspion(accepte: false);
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: puits);

      final resultat = await service.submit(
          trailId: 't', category: FeedbackCategory.bug, content: 'un bug');

      expect(resultat, FeedbackIssue.gardeLocalement);
      final tout = await dao.getByTrailId('t');
      expect(tout, hasLength(1),
          reason: 'un envoi rate ne doit jamais faire disparaitre le message');
    });

    test('un retour echoue REPART au flush suivant quand le reseau revient',
        () async {
      final puits = PuitsEspion(accepte: false);
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: puits);
      await service.submit(
          trailId: 't', category: FeedbackCategory.bug, content: 'a renvoyer');

      puits.accepte = true;
      expect(await service.flush(), 1,
          reason: 'un retour marque « echoue » restait bloque pour toujours : '
              'seuls les « pending » etaient repris');
      expect(puits.recus, ['a renvoyer']);
    });

    test('hors ligne, on garde — et on le dit', () async {
      reseau.statut = ConnectivityStatusValues.offline;
      final puits = PuitsEspion();
      final service =
          FeedbackService(dao: dao, connectivityMonitor: reseau, sink: puits);

      final resultat = await service.submit(
          trailId: 't', category: FeedbackCategory.bug, content: 'au refuge');

      expect(resultat, FeedbackIssue.gardeLocalement);
      expect(puits.recus, isEmpty);
      expect(await dao.getPending(), hasLength(1));
    });
  });

  group('LOT 596 C1 — CE QUE L ECRAN DIT AU RANDONNEUR', () {
    testWidgets(
        '/trail/:id/feedback — l ecran annonce AVANT d ecrire que le retour '
        'reste sur le telephone', (tester) async {
      // L'APPLICATION REELLE, par sa vraie route (socle du LOT V). Sans
      // configuration cloud, aucun destinataire n'est branche : l'ecran doit le
      // dire d'entree, pas apres avoir remercie.
      await monterAppliReelle(tester,
          depart: '/trail/mare-a-mare-centre/feedback');

      final textes = textesVisibles(tester);
      expect(textes, contains(_tr.feedback.keptLocallyNotice),
          reason: 'l utilisateur doit savoir AVANT d ecrire que son message ne '
              'partira pas encore');
      expect(textes, isNot(contains(_tr.feedback.thanks)),
          reason: 'aucun merci ne doit s afficher avant meme un envoi');

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });

    testWidgets(
        '/trail/:id/feedback — apres envoi sans destinataire, l ecran dit '
        '« garde ici » et JAMAIS merci', (tester) async {
      await monterAppliReelle(tester,
          depart: '/trail/mare-a-mare-centre/feedback');

      await tester.enterText(
          find.byType(TextField).first, 'La carte se fige au col');
      await stabiliser(tester, coups: 4);

      final bouton = find.widgetWithText(ElevatedButton, _tr.feedback.send);
      expect(bouton, findsWidgets, reason: 'le bouton d envoi doit etre la');
      await tester.tap(bouton.first, warnIfMissed: false);
      await stabiliser(tester, coups: 12);

      final textes = textesVisibles(tester);
      expect(textes, contains(_tr.feedback.keptLocally),
          reason: 'le retour est garde sur le telephone : l ecran doit le dire');
      expect(textes, isNot(contains(_tr.feedback.thanks)),
          reason: 'C EST LE DEFAUT CORRIGE : l ecran remerciait pour un '
              'message que personne n allait jamais lire');
      expect(textes, isNot(contains(_tr.feedback.sentThanks)),
          reason: 'le merci d envoi est reserve a un message reellement parti');

      await demonterAppli(tester);
      erreursDeRendu(tester);
    });
  });
}
