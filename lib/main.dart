import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/trail_config.dart';
import 'core/config/test_trail_config.dart';
import 'core/engine/trail_engine.dart';
import 'core/firebase/firebase_service.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/providers/onboarding_providers.dart';
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
        trailConfigProvider.overrideWithValue(config),
        firebaseServiceProvider.overrideWithValue(firebaseService),
      ],
      // TranslationProvider (Slang) : requis pour Translations.of(context),
      // utilise notamment par l'ecran d'onboarding (E5.1a).
      child: TranslationProvider(
        child: MaterialApp.router(
          title: config.displayName,
          debugShowCheckedModeBanner: false,
          // Theme clair ET sombre injectes depuis TrailConfig (E5.5b).
          // L'app reste sombre par defaut (design trek), mais le pendant
          // clair existe et est cable -> bascule de theme sans casse.
          theme: AppTheme.buildLightTheme(
            primaryColor: Color(config.primaryColorValue),
            secondaryColor: Color(config.secondaryColorValue),
          ),
          darkTheme: AppTheme.buildDarkTheme(
            primaryColor: Color(config.primaryColorValue),
            secondaryColor: Color(config.secondaryColorValue),
          ),
          themeMode: ThemeMode.dark,
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
