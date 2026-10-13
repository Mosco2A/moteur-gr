import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/safety/data/health_info_file.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// LA FICHE A CHANGE, DONC L APPLICATION REPOSE LA QUESTION (DEM 30/09 12:33).
///
/// DECISION DE CHRISTOPHE, verbatim : « en cas de modification des donnees, on
/// redemande le consentement ».
///
/// CE QUE CES TESTS PROUVENT, A L ECRAN et pas seulement dans le service :
///
///   1. OUVRIR LA FICHE NE DEMANDE RIEN. « Jamais au simple affichage » : un
///      randonneur qui relit son groupe sanguin ne doit pas se voir reposer une
///      question a laquelle il a deja repondu. C est le test qui garde le lot
///      d etre insupportable a l usage.
///
///   2. ENREGISTRER LA FICHE POSE LA QUESTION, une fois, et APRES la
///      confirmation d enregistrement. L ordre n est pas cosmetique : placee
///      avant, la question laissait le bouton « Enregistrer » tourner sous le
///      dialogue — defaut deja paye par la tache 612 sur cet ecran, et rattrape
///      ici par deux tests devenus rouges (`pumpAndSettle timed out`).
///
///   3. LA REPONSE EST ENREGISTREE AVEC SON DECLENCHEUR, et elle ferme la
///      boucle : on ne repose pas la question a l enregistrement suivant si rien
///      n a change entre-temps.
void main() {
  late AppDatabase db;
  late Directory bacFiche;
  late HealthInfoFile fiche;
  late ConsentService consentement;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    bacFiche = Directory.systemTemp.createTempSync('fiche638_redemande');
    fiche = HealthInfoFile(dossierApplicatif: () async => bacFiche);
    SharedPreferences.setMockInitialValues(<String, Object>{});
    consentement = ConsentService();
    await consentement.initialize();
  });

  tearDown(() async {
    consentement.dispose();
    await db.close();
    if (bacFiche.existsSync()) bacFiche.deleteSync(recursive: true);
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        healthInfoFileProvider.overrideWithValue(fiche),
        // MEME INSTANCE QUE CELLE QUE LE TEST INTERROGE : sans cette surcharge,
        // l ecran ecrirait dans un service et le test lirait dans un autre. Les
        // deux liraient le meme magasin de preferences, mais l etat en memoire
        // (et le flux des decisions) differerait — on mesurerait alors le
        // stockage, pas le comportement de l ecran.
        consentServiceProvider.overrideWithValue(consentement),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/health',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'health',
                    builder: (_, __) => const HealthInfoScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // INTEGRATION 647 — CE TEST TAPAIT DANS UN CHAMP QUI N EXISTE PLUS.
  //
  // Le lot 635 a ete ecrit contre l ecran d AVANT la tache 630 : le groupe
  // sanguin y etait une saisie libre, et ce test y ecrivait « A+ ». La tache 630
  // l a remplace par une LISTE FERMEE (`_ChampGroupeSanguin`) — la cle
  // `health-blood-type-field` existe toujours, mais elle ne porte plus de champ
  // de texte, donc `enterText` ne trouvait aucun `EditableText` et levait
  // « Bad state: No element ».
  //
  // CE QUE CE TEST VEUT VRAIMENT, c est qu une MODIFICATION de la fiche suivie
  // d un enregistrement pose la question du consentement. N importe quel champ
  // reellement modifie le prouve. On prend les antecedents medicaux, qui est
  // l exemple meme que le lot 635 donne dans sa propre documentation (« le
  // randonneur qui ajoute aujourd hui un traitement ou une allergie n a jamais
  // consenti POUR CELA ») — et qui est reste un champ de texte libre.
  Future<void> remplirEtEnregistrer(WidgetTester tester) async {
    await tester.enterText(
      find.byKey(const ValueKey('health-conditions-field')),
      'Asthme',
    );
    await tester.pumpAndSettle();
    final save = find.text(t.health.save);
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  void grandEcran(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('638 — la re-demande se declenche sur une MODIFICATION', () {
    testWidgets('ouvrir la fiche ne demande RIEN', (tester) async {
      grandEcran(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(
        find.text(t.consent.purposes.healthData),
        findsNothing,
        reason:
            'un affichage n est pas une modification : reposer la question '
            'a chaque ouverture rendrait l application insupportable',
      );
      expect(
        consentement.revisionDesDonnees(ConsentPurpose.healthData),
        0,
        reason: 'lire la fiche ne fait pas monter la revision des donnees',
      );
    });

    testWidgets('enregistrer la fiche POSE la question', (tester) async {
      grandEcran(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      await remplirEtEnregistrer(tester);

      expect(
        find.text(t.consent.purposes.healthData),
        findsOneWidget,
        reason:
            'c est la demande de Christophe : la fiche a change, on '
            'redemande',
      );
      // Les deux reponses sont aussi accessibles l une que l autre (RGPD
      // art. 7-3 : le retrait doit etre aussi simple que l octroi).
      expect(find.text(t.consent.grant), findsOneWidget);
      expect(find.text(t.consent.revoke), findsOneWidget);
      expect(
        consentement.revisionDesDonnees(ConsentPurpose.healthData),
        1,
        reason: 'la modification a ete notee une fois',
      );
    });

    testWidgets('repondre « Autoriser » enregistre la decision et son '
        'declencheur', (tester) async {
      grandEcran(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await remplirEtEnregistrer(tester);

      await tester.tap(find.text(t.consent.grant));
      await tester.pumpAndSettle();

      final etat = consentement.stateOf(ConsentPurpose.healthData);
      expect(etat.granted, isTrue);
      expect(etat.decidedAt, isNotNull, reason: 'la decision est horodatee');
      expect(
        etat.declencheur,
        ConsentTrigger.modificationDesDonnees,
        reason:
            'le registre en base doit pouvoir distinguer une '
            're-confirmation apres modification d un premier accord',
      );
      expect(
        consentement.needsPrompt(ConsentPurpose.healthData),
        isFalse,
        reason: 'UNE FOIS par modification : la reponse ferme la boucle',
      );
    });

    testWidgets('repondre « Retirer » enregistre AUSSI une decision — un refus '
        'n est pas un silence', (tester) async {
      grandEcran(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await remplirEtEnregistrer(tester);

      await tester.tap(find.text(t.consent.revoke));
      await tester.pumpAndSettle();

      final etat = consentement.stateOf(ConsentPurpose.healthData);
      expect(etat.granted, isFalse);
      expect(etat.decidedAt, isNotNull);
      expect(etat.declencheur, ConsentTrigger.modificationDesDonnees);
      expect(consentement.needsPrompt(ConsentPurpose.healthData), isFalse);
    });

    testWidgets('LA FICHE EST ENREGISTREE quoi qu il arrive a la question', (
      tester,
    ) async {
      // CE QUI COMPTE POUR UN SECOURISTE, C EST LA FICHE. La question de
      // consentement est posee APRES l enregistrement, jamais avant : elle ne
      // peut donc pas empecher un antecedent medical d atteindre le disque.
      // (Integration 647 : le champ verifie suit celui que le helper remplit,
      // voir la note sur `remplirEtEnregistrer`.)
      grandEcran(tester);
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();
      await remplirEtEnregistrer(tester);

      final enregistree = await fiche.lire();
      expect(enregistree.conditions, 'Asthme');
      expect(
        find.text(t.health.saved),
        findsOneWidget,
        reason:
            'la confirmation d enregistrement ne depend de rien d autre '
            'que de l enregistrement',
      );
    });
  });
}
