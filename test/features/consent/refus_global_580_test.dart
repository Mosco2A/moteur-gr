// LE REFUS GLOBAL DES CONSENTEMENTS — tache 580, point Y1.
//
// CE QUI MANQUAIT, ET CE N'ETAIT PAS UNE COMMODITE. L'ecran `/consent` — le
// SEUL ecran de consentement qu'un utilisateur puisse ouvrir — offrait quatre
// bascules et rien d'autre. Accorder tenait en un geste par finalite ; refuser
// en bloc n'existait nulle part. Le libelle `consent.declineAll` (« Tout
// refuser ») etait pourtant ecrit dans les cinq langues depuis le LOT 4, et il
// vivait sur `ConsentOnboardingScreen`, un ecran sans route que personne ne
// peut atteindre (invariante V2, LOT V). Un mot traduit cinq fois pour un
// bouton que personne ne voit.
//
// POURQUOI C'EST UNE FAUTE RGPD ET PAS UN CONFORT. Le retrait doit etre aussi
// simple que l'octroi (art. 7-3) — l'ecran le PROMET d'ailleurs en toutes
// lettres dans son intro (« Vous pouvez retirer un consentement a tout moment »).
// Et le LOT I (tache 560) a deja fait appliquer le principe a l'article 9 : un
// refus n'est pas un affichage, il EFFACE ce que le consentement protegeait.
//
// CE QUE CE FICHIER PROUVE, EN DEUX ETAGES :
//   (1) le geste EXISTE la ou l'utilisateur arrive — sur la route `/consent`,
//       montee avec le VRAI routeur, dans les cinq langues ;
//   (2) le geste EFFACE — apres un refus global, les quatre finalites portent
//       une decision NEGATIVE horodatee, et la morphologie (donnee art. 9) a
//       disparu du stockage, relue par un depot NEUF.
//
// Retirer le bouton rend (1) rouge ; le brancher sur un simple `service.revoke`
// sans effacement rend (2) rouge.
library;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/consent/presentation/consent_settings_screen.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../structurel/parcours_reel.dart';

void main() {
  group('Y1-a — le refus global est OFFERT sur l ecran atteignable', () {
    for (final langue in AppLocale.values) {
      testWidgets('/consent offre « tout refuser » en ${langue.languageCode}',
          (tester) async {
        LocaleSettings.setLocale(langue);
        addTearDown(() => LocaleSettings.setLocaleRaw('fr'));

        await monterAppliReelle(tester, depart: '/consent');
        final arrivee = cheminAffiche();
        final attendu = t.consent.declineAll;
        final gestes = gestesDisponibles(tester).map((g) => g.libelle).toList();
        await demonterAppli(tester);
        erreursDeRendu(tester);

        expect(arrivee, '/consent',
            reason: 'la route du consentement doit rester atteignable');
        expect(
          gestes.any((l) => l.toLowerCase().contains(attendu.toLowerCase())),
          isTrue,
          reason: 'AUCUN MOYEN DE TOUT REFUSER sur le seul ecran de '
              'consentement atteignable. Le libelle « $attendu » existe dans '
              'les cinq langues et ne vit que sur un ecran sans route. Le RGPD '
              'veut qu un refus soit aussi simple qu un accord.\n'
              '  gestes offerts : ${gestes.join(' / ')}',
        );
      });
    }
  });

  group('Y1-b — un refus global EFFACE ce qu il doit effacer', () {
    late AppDatabase db;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
      LocaleSettings.setLocaleRaw('fr');
    });

    tearDown(() async {
      await db.close();
    });

    HikerProfileRepository depot() => HikerProfileRepository(db: db, prefs: prefs);

    testWidgets(
        'apres « tout refuser » : les quatre finalites sont refusees ET la '
        'morphologie a disparu du stockage', (tester) async {
      // ETAT DE DEPART : tout accorde, et une morphologie enregistree — la
      // donnee de sante (art. 9) que le consentement healthData protege.
      final service = ConsentService();
      await service.initialize();
      for (final purpose in ConsentPurpose.values) {
        await service.grant(purpose);
      }
      await depot().saveProfile(
        HikerProfile.empty.copyWith(age: 72, heightCm: 172, weightKg: 88),
      );
      expect((await depot().load()).age, 72, reason: 'mise en place cassee');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hikerProfileRepositoryProvider.overrideWithValue(depot()),
          ],
          child: TranslationProvider(
            // `AppHeader` interroge le routeur : l'ecran se monte dans un
            // GoRouter minimal, comme en production.
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/consent',
                routes: [
                  GoRoute(
                    path: '/consent',
                    builder: (_, __) => const ConsentSettingsScreen(),
                  ),
                  GoRoute(
                    path: '/my-treks',
                    builder: (_, __) => const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // LE GESTE COMPLET : le bouton de l'ecran, puis la confirmation qui dit
      // ce qu'il emporte. Refuser reste le chemin le plus court de l'ecran —
      // deux gestes contre quatre bascules.
      await tester.tap(find.text(t.consent.declineAll));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: 'le refus global doit dire ce qu il efface AVANT d effacer');
      expect(find.text(t.consent.declineAllNote), findsOneWidget,
          reason: 'la confirmation doit nommer ce que le refus emporte');
      await tester.tap(find.byKey(const ValueKey('consent-decline-all-confirm')));
      await tester.pumpAndSettle();

      // (1) LES QUATRE FINALITES PORTENT UNE DECISION NEGATIVE HORODATEE. Un
      // refus est une decision, pas un silence : l application ne doit plus
      // redemander, et le journal doit pouvoir dire quand il a ete pose.
      final relu = ConsentService();
      await relu.initialize();
      for (final purpose in ConsentPurpose.values) {
        final etat = relu.stateOf(purpose);
        expect(etat.granted, isFalse,
            reason: '$purpose reste accorde apres un refus global');
        expect(etat.decidedAt, isNotNull,
            reason: '$purpose n a pas ete DECIDE : un refus global doit poser '
                'une decision, sinon l application redemande comme si rien '
                'n avait ete dit');
        expect(relu.needsPrompt(purpose), isFalse,
            reason: '$purpose serait redemande : le refus n a pas ete entendu');
      }

      // (2) ET LA DONNEE PROTEGEE S EN VA. Relue par un depot NEUF, donc
      // depuis le stockage et jamais depuis un cache d ecran.
      final profil = await depot().load();
      expect(
        [profil.age, profil.heightCm, profil.weightKg],
        [0, 0, 0],
        reason: 'LA MORPHOLOGIE A SURVECU AU REFUS GLOBAL. Un refus qui laisse '
            'la donnee sur l appareil est un affichage, pas un refus — c est '
            'exactement le defaut N1 corrige par le LOT I sur la fiche '
            'randonneur.',
      );
    });
  });
}
