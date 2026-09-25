import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/consent_service.dart';
import 'package:moteur_gr/features/consent/providers/consent_ui_providers.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// CONSENTEMENT ARTICLE 9 ET VOCABULAIRE PROSCRIT — tache 560, defauts N1 et N2
/// de la campagne personas 559 (rapport #100474).
///
/// N1, LE DEFAUT QUE 2604 TESTS UNITAIRES N'ONT PAS VU. Gerard remplit
/// 72 ans / 172 cm / 88 kg, LAISSE LE CONSENTEMENT MORPHOLOGIE REFUSE, touche
/// « Enregistrer » : l'ecran se ferme comme un enregistrement reussi, et apres
/// redemarrage les trois valeurs sont relues a l'ecran. Le code annoncait
/// pourtant l'intention inverse en commentaire — « si la morpho est renseignee,
/// exiger le consentement healthData. Sinon, on n'enregistre pas » — puis
/// appelait `revoke()` et enchainait sur `save(profile)` SANS CONDITION. Il
/// revoquait le consentement et enregistrait quand meme la donnee de sante que
/// ce consentement protege.
///
/// CE FICHIER EST LA PREUVE QUI MANQUAIT. Il ne verifie pas que le code DIT la
/// bonne chose : il verifie ce que l'appareil GARDE apres le geste. Retablir
/// l'ancien enchainement (revoke puis save inconditionnel) rend rouge le
/// premier test de ce fichier.
///
/// N2, LE VOCABULAIRE. La fiche affichait « IMC 29.7 » puis « Surpoids »
/// PENDANT la saisie, donc avant tout consentement. Deux fautes en une : un
/// calcul de sante montre avant l'accord, et un vocabulaire interdit a l'ecran
/// (« on est pas medecin et on insulte pas les clients », Chris, 25/09). Les
/// tests du bas verrouillent les deux etages : la table de traduction ne porte
/// plus ces libelles, et l'ecran ne les affiche dans aucune des cinq langues.
void main() {
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
    LocaleSettings.setLocaleRaw('fr');
  });

  HikerProfileRepository depot() =>
      HikerProfileRepository(db: db, prefs: prefs);

  /// Service de consentement lisant le MEME stockage que l'application sous
  /// test (SharedPreferences mockees) : ce qu'il voit est ce qui est ecrit.
  Future<ConsentService> consentement() async {
    final service = ConsentService();
    await service.initialize();
    return service;
  }

  /// L'ecran est atteint par un push depuis /home (comme en prod) : le
  /// `Navigator.pop()` de la sauvegarde a bien une page ou revenir, donc
  /// « l'ecran est quitte » se constate vraiment.
  Widget wrap() {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider.overrideWithValue(depot()),
      ],
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/home/profile',
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const Scaffold(body: SizedBox()),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (_, __) => const HikerProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> ouvrir(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
  }

  final tp = t.hikerProfile;

  /// La saisie de Gerard, mot pour mot celle de la campagne.
  Future<void> saisirGerard(WidgetTester tester) async {
    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldAge), '72');
    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldHeight), '172');
    await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldWeight), '88');
    await tester.pumpAndSettle();
  }

  Future<void> basculerConsentement(WidgetTester tester) async {
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
  }

  group('N1 — le refus du consentement article 9 est APPLIQUE', () {
    testWidgets(
        'consentement refuse : rien n est enregistre, l ecran reste ouvert, '
        'le refus est dit', (tester) async {
      await ouvrir(tester);
      await saisirGerard(tester);
      // La bascule de consentement n'est PAS touchee : elle reste a « refuse »,
      // exactement comme dans la campagne.

      await tester.tap(find.text(tp.save));
      await tester.pumpAndSettle();

      // 1. RIEN N'EST SUR L'APPAREIL. C'est l'assertion qui etait fausse : la
      //    campagne relisait 72 / 172 / 88 apres redemarrage.
      final persiste = await depot().getProfile();
      expect(persiste.age, 0, reason: 'l age a ete enregistre malgre le refus');
      expect(persiste.heightCm, 0,
          reason: 'la taille a ete enregistree malgre le refus');
      expect(persiste.weightKg, 0,
          reason: 'le poids a ete enregistre malgre le refus');

      // 2. L'ecran ne se ferme PAS comme un succes.
      expect(find.text(tp.fieldAge), findsOneWidget);
      expect(find.text(tp.saved), findsNothing);

      // 3. Le refus est DIT, la ou l'on vient d'appuyer.
      expect(find.byKey(const ValueKey('hiker-profile-consent-error')),
          findsOneWidget);
      expect(find.text(tp.errorConsentRequired), findsOneWidget);

      // 4. Et le refus est trace cote consentement.
      final consent = await consentement();
      expect(consent.hasConsent(ConsentPurpose.healthData), isFalse);
    });

    testWidgets('la saisie n est pas perdue : un tap sur la bascule, un second '
        'sur Enregistrer, et la fiche part', (tester) async {
      await ouvrir(tester);
      await saisirGerard(tester);
      await tester.tap(find.text(tp.save));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('hiker-profile-consent-error')),
          findsOneWidget);

      await basculerConsentement(tester);
      // Le message disparait des que l'autorisation est donnee : il dirait le
      // contraire de ce que la bascule montre.
      expect(find.byKey(const ValueKey('hiker-profile-consent-error')),
          findsNothing);

      await tester.tap(find.text(tp.save));
      await tester.pumpAndSettle();

      final persiste = await depot().getProfile();
      expect(persiste.age, 72);
      expect(persiste.heightCm, 172);
      expect(persiste.weightKg, 88);
      final consent = await consentement();
      expect(consent.hasConsent(ConsentPurpose.healthData), isTrue);
    });

    testWidgets('UNE REVOCATION EFFACE : la morpho deja enregistree ne survit '
        'pas au retrait du consentement', (tester) async {
      // Etat de depart : fiche complete enregistree AVEC consentement.
      await depot().saveProfile(const HikerProfile(
        age: 72,
        heightCm: 172,
        weightKg: 88,
        sex: HikerSex.male,
        countryIso: 'FR',
      ));
      final consent = await consentement();
      await consent.grant(ConsentPurpose.healthData);

      await ouvrir(tester);
      // L'ecran relit l'accord : la bascule est sur « autorise ».
      expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
          isTrue);

      // Le randonneur retire son accord, puis enregistre.
      await basculerConsentement(tester);
      await tester.tap(find.text(tp.save));
      await tester.pumpAndSettle();

      // Cesser d'ecrire n'aurait pas suffi : les trois valeurs seraient restees
      // sur l'appareil. Elles sont EFFACEES.
      final persiste = await depot().getProfile();
      expect(persiste.age, 0);
      expect(persiste.heightCm, 0);
      expect(persiste.weightKg, 0);
      // Le perimetre efface est celui que l'application DECLARE (age, taille,
      // poids) : ce qui ne releve pas de l'article 9 n'est pas emporte.
      expect(persiste.sex, HikerSex.male);
      expect(persiste.countryIso, 'FR');
      // Et la fiche est redevenue « vide » pour la faisabilite : aucun 0/0/0
      // ne remonte au moteur.
      expect(persiste.isEmpty, isTrue);

      final apres = await consentement();
      expect(apres.hasConsent(ConsentPurpose.healthData), isFalse);
    });

    test('MEME REGLE DEPUIS LES REGLAGES : retirer l autorisation sante y '
        'efface aussi la morphologie', () async {
      await depot().saveProfile(const HikerProfile(
        age: 68,
        heightCm: 170,
        weightKg: 92,
        countryIso: 'IT',
      ));
      final consent = await consentement();
      await consent.grant(ConsentPurpose.healthData);

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider.overrideWithValue(depot()),
      ]);
      addTearDown(container.dispose);

      await container
          .read(consentControllerProvider)
          .revoke(ConsentPurpose.healthData);

      final persiste = await depot().getProfile();
      expect(persiste.age, 0);
      expect(persiste.heightCm, 0);
      expect(persiste.weightKg, 0);
      expect(persiste.countryIso, 'IT');
      expect((await consentement()).hasConsent(ConsentPurpose.healthData),
          isFalse);
    });

    test('une autre finalite retiree ne touche PAS a la morphologie', () async {
      await depot().saveProfile(const HikerProfile(
        age: 40,
        heightCm: 175,
        weightKg: 70,
      ));
      final consent = await consentement();
      await consent.grant(ConsentPurpose.healthData);
      await consent.grant(ConsentPurpose.socialSharing);

      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        hikerProfileRepositoryProvider.overrideWithValue(depot()),
      ]);
      addTearDown(container.dispose);

      await container
          .read(consentControllerProvider)
          .revoke(ConsentPurpose.socialSharing);

      final persiste = await depot().getProfile();
      expect(persiste.age, 40);
      expect(persiste.heightCm, 175);
      expect(persiste.weightKg, 70);
    });
  });

  group('N2 — aucun jugement sur le corps, dans aucune langue', () {
    /// Ce que la fiche d'info ne doit plus jamais nommer, langue par langue.
    /// Liste ECRITE, comme celle du garde-fou de l'alerte descente : une forme
    /// est interdite parce qu'elle figure ici, pas parce qu'un algorithme la
    /// trouve suspecte.
    const interdits = <String, List<String>>{
      'fr': ['imc', 'maigreur', 'corpulence', 'surpoids', 'obésit'],
      'en': ['bmi', 'underweight', 'normal weight', 'overweight', 'obes'],
      'de': ['bmi', 'untergewicht', 'normalgewicht', 'übergewicht', 'adiposit'],
      'es': ['imc', 'bajo peso', 'peso normal', 'sobrepeso', 'obesidad'],
      'it': ['imc', 'sottopeso', 'normopeso', 'sovrappeso', 'obesit'],
    };

    /// Tous les textes de la section `hikerProfile` d'une langue, a plat.
    List<String> textesFiche(String langue) {
      final racine = jsonDecode(
        File('assets/i18n/$langue.i18n.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final out = <String>[];
      void visiter(Object? noeud) {
        if (noeud is Map) {
          noeud.forEach((_, v) => visiter(v));
        } else if (noeud is List) {
          for (final v in noeud) {
            visiter(v);
          }
        } else if (noeud is String) {
          out.add(noeud);
        }
      }

      visiter(racine['hikerProfile']);
      return out;
    }

    test('la table de traduction ne porte plus l IMC ni ses categories', () {
      for (final entree in interdits.entries) {
        final textes = textesFiche(entree.key);
        expect(textes, isNotEmpty,
            reason: '${entree.key} : section hikerProfile introuvable');
        for (final mot in entree.value) {
          for (final texte in textes) {
            expect(texte.toLowerCase(), isNot(contains(mot)),
                reason: '${entree.key} : la fiche d info dit « $mot » '
                    '(« $texte »)');
          }
        }
      }
    });

    test('les cles bmiLabel / bmiCategories n existent plus nulle part', () {
      for (final locale in AppLocale.values) {
        final tr = locale.buildSync();
        expect(tr['hikerProfile.bmiLabel'], isNull,
            reason: '${locale.languageCode} : bmiLabel est revenu');
        for (final cle in const [
          'underweight',
          'normal',
          'overweight',
          'obese',
        ]) {
          expect(tr['hikerProfile.bmiCategories.$cle'], isNull,
              reason: '${locale.languageCode} : bmiCategories.$cle est revenu');
        }
      }
    });

    testWidgets('l ecran n affiche aucun IMC ni categorie, taille et poids '
        'saisis, dans les cinq langues', (tester) async {
      for (final locale in AppLocale.values) {
        LocaleSettings.setLocaleRaw(locale.languageCode);
        await ouvrir(tester);
        // IMC 29.7 : exactement la saisie de la capture S9 de la campagne.
        await tester.enterText(
            find.widgetWithText(TextFormField, t.hikerProfile.fieldHeight),
            '172');
        await tester.enterText(
            find.widgetWithText(TextFormField, t.hikerProfile.fieldWeight),
            '88');
        await tester.pumpAndSettle();

        final affiches = tester
            .widgetList<Text>(find.byType(Text))
            .map((w) => (w.data ?? '').toLowerCase())
            .toList();
        for (final mot in interdits[locale.languageCode]!) {
          for (final texte in affiches) {
            expect(texte, isNot(contains(mot)),
                reason: '${locale.languageCode} : l ecran affiche « $mot » '
                    '(« $texte »)');
          }
        }
        // Et aucun nombre d IMC non plus : 88 / 1,72^2 = 29.7.
        for (final texte in affiches) {
          expect(texte, isNot(contains('29.7')),
              reason: '${locale.languageCode} : l IMC calcule est affiche');
          expect(texte, isNot(contains('29,7')),
              reason: '${locale.languageCode} : l IMC calcule est affiche');
        }
      }
    });
  });
}
