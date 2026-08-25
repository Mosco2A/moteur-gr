import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/trail_config.dart';
import 'core/config/test_trail_config.dart';
import 'core/firebase/firebase_service.dart';
import 'core/providers/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_skin.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/onboarding_providers.dart';
import 'features/safety/presentation/health_info_screen.dart';
import 'i18n/translations.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // E5.1b — lit le flag d'onboarding AVANT le premier rendu pour que le guard
  // du routeur (synchrone) redirige vers /onboarding au tout premier lancement.
  final prefs = await SharedPreferences.getInstance();
  hasCompletedOnboarding = prefs.getBool(kOnboardingCompletedKey) ?? false;

  // Initialisation Firebase conditionnelle :
  // si firebaseProjectId est null, le moteur reste en mode local
  final firebaseService = await FirebaseService.initialize(
    firebaseProjectId: testTrailConfig.firebaseProjectId,
  );

  runApp(
    MoteurGrApp(config: testTrailConfig, firebaseService: firebaseService),
  );
}

/// Application racine du Moteur GR.
///
/// Wrappee dans ProviderScope pour Riverpod,
/// utilise GoRouter pour la navigation.
class MoteurGrApp extends StatelessWidget {
  const MoteurGrApp({
    super.key,
    required this.config,
    required this.firebaseService,
  });

  final TrailConfig config;
  final FirebaseService firebaseService;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        // NOTE (cablage nav, design #88246) : on NE surcharge PLUS
        // trailConfigProvider. L'override figeait le sentier actif sur
        // testTrailConfig et court-circuitait selectedTrailIdProvider : la
        // selection au catalogue n'avait alors aucun effet. Sans override,
        // trailConfigProvider derive de selectedTrailIdProvider
        // (cf. trail_engine.dart) et toute l'app suit le sentier choisi.
        // Seul firebaseServiceProvider reste surcharge (service initialise
        // au demarrage, hors graphe Riverpod pur).
        firebaseServiceProvider.overrideWithValue(firebaseService),
        // E57 (LOT D/D1) : cablage explicite du DAO sante sur la base Drift
        // unique (databaseProvider). Le provider auto-derive deja de
        // databaseProvider ; l'override rend le point d'injection explicite au
        // niveau racine (spec E57 RF-8). Donnees LOCAL ONLY (art. 9), jamais le
        // cloud. NB : databaseProvider est en memoire (etat app-wide inchange,
        // hors perimetre D1) -> persistance = duree de session, comme les
        // autres features Drift aujourd'hui.
        healthInfoDaoProvider.overrideWith(
          (ref) => ref.watch(databaseProvider).healthInfoDao,
        ),
      ],
      // Migration Riverpod 3 (INC-1) : NEUTRALISATION du retry automatique.
      // Riverpod 3 re-essaie par defaut tout provider Future/Stream qui leve
      // (back-off exponentiel). Tant que le comportement n'a pas ete arbitre
      // provider par provider (prevu en INC-4), on desactive ce retry au niveau
      // racine pour garantir ZERO effet de bord comportemental vs Riverpod 2
      // (pas de re-tentative en boucle sur une garde d'auth ou une erreur
      // metier volontaire). Retourner null = aucune nouvelle tentative.
      retry: (_, __) => null,
      // TranslationProvider (Slang) : requis pour Translations.of(context),
      // utilise notamment par l'ecran d'onboarding (E5.1a).
      child: TranslationProvider(
        child: MaterialApp.router(
          title: config.displayName,
          debugShowCheckedModeBanner: false,
          // Theme clair ET sombre injectes depuis TrailConfig (E5.5b).
          // L'app reste sombre par defaut (design trek), mais le pendant
          // clair existe et est cable -> bascule de theme sans casse.
          //
          // SW-SKIN-L2 : peau active cablee en dur sur Sentier Vivant (defaut).
          // La selection utilisateur (Reglages + carte) + persistance arrive en
          // L7 (skinProvider) ; ici le porteur technique est en place, neutre.
          theme: AppTheme.buildLightTheme(
            primaryColor: Color(config.primaryColorValue),
            secondaryColor: Color(config.secondaryColorValue),
            skin: AppSkin.sentierVivant,
          ),
          darkTheme: AppTheme.buildDarkTheme(
            primaryColor: Color(config.primaryColorValue),
            secondaryColor: Color(config.secondaryColorValue),
            skin: AppSkin.sentierVivant,
          ),
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
