import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/mare_a_mare_centre_trail_config.dart';
import 'core/config/trail_config.dart';
import 'core/firebase/firebase_service.dart';
import 'core/engine/trail_engine.dart';
import 'core/providers/app_bootstrap_provider.dart';
import 'core/providers/database_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/skin_provider.dart';
import 'features/ads/providers/ads_providers.dart';
import 'features/onboarding/providers/onboarding_providers.dart';
import 'features/safety/presentation/health_info_screen.dart';
import 'features/treks/presentation/widgets/orphan_session_reprise.dart';
import 'i18n/translations.g.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // E5.1b — lit le flag d'onboarding AVANT le premier rendu pour que le guard
  // du routeur (synchrone) redirige vers /onboarding au tout premier lancement.
  final prefs = await SharedPreferences.getInstance();
  hasCompletedOnboarding = prefs.getBool(kOnboardingCompletedKey) ?? false;

  // Initialisation Firebase conditionnelle :
  // si firebaseProjectId est null, le moteur reste en mode local.
  // PARITE GR20 — LOT 1 (#99423) : la demo demarre sur Mare a Mare Centre
  // (sentier reel de StepWays), en tete du catalogue. Le moteur reste
  // generique : c'est une DONNEE (TrailConfig), aucune localite hardcodee ici.
  final firebaseService = await FirebaseService.initialize(
    firebaseProjectId: mareAMareCentreTrailConfig.firebaseProjectId,
  );

  runApp(
    MoteurGrApp(
      config: mareAMareCentreTrailConfig,
      firebaseService: firebaseService,
    ),
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
      child: TranslationProvider(child: _MoteurGrMaterialApp(config: config)),
    );
  }
}

/// MaterialApp pilote par la peau active (SW-SKIN-L7).
///
/// `ConsumerWidget` (donc SOUS le `ProviderScope`) : lit
/// [effectiveSkinProvider] pour construire le theme avec la peau reellement
/// appliquee (choix utilisateur persiste + fallback Grand Air->Sentier Vivant).
/// Changer de peau => ce widget se reconstruit => `buildLightTheme`/
/// `buildDarkTheme` regeneres avec la nouvelle peau => prise d'effet immediate.
class _MoteurGrMaterialApp extends ConsumerWidget {
  const _MoteurGrMaterialApp({required this.config});

  final TrailConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SW-SKIN-L7 : la peau active vient desormais du provider (au lieu du
    // sentierVivant cable en dur en L2). effectiveSkin applique deja le
    // fallback d'eligibilite (Grand Air -> Sentier Vivant si non eligible).
    final skin = ref.watch(effectiveSkinProvider);

    return MaterialApp.router(
      title: config.displayName,
      debugShowCheckedModeBanner: false,
      // Theme clair ET sombre injectes depuis TrailConfig (E5.5b).
      // L'app reste sombre par defaut (design trek), mais le pendant
      // clair existe et est cable -> bascule de theme sans casse.
      theme: AppTheme.buildLightTheme(
        primaryColor: Color(config.primaryColorValue),
        secondaryColor: Color(config.secondaryColorValue),
        skin: skin,
      ),
      darkTheme: AppTheme.buildDarkTheme(
        primaryColor: Color(config.primaryColorValue),
        secondaryColor: Color(config.secondaryColorValue),
        skin: skin,
      ),
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
      // PARITE GR20 — LOT 1 (#99423 §4.1) : porte d'amorce. Le `builder` de
      // MaterialApp.router enveloppe TOUT ecran route -> le seed du sentier
      // actif (appBootstrapProvider) est declenche et ATTENDU avant le premier
      // rendu des ecrans data. Sans cette garde, seedIfNeeded() n'etait appele
      // nulle part : carte/etapes/POI vides et meteo « introuvable ».
      builder: (context, child) => _BootstrapGate(child: child),
    );
  }
}

/// Porte d'amorce des donnees (PARITE GR20, LOT 1 ; StepWays LOT 2, Phase 5 —
/// REACTIVE au changement de sentier).
///
/// `ConsumerWidget` (sous le `ProviderScope`) : observe [appBootstrapProvider],
/// qui force le seed du sentier actif (DB in-memory volatile -> re-seed a chaque
/// lancement). Tant que le seed n'est pas resolu, affiche un ecran de chargement
/// (i18n Slang) ; en cas d'echec, un ecran d'erreur discret. Une fois resolu, le
/// [child] route (« Mes treks » puis le cockpit) s'affiche avec ses donnees deja
/// en base.
///
/// LOT 2 (§4, SEUL RISQUE TECHNIQUE identifie) : changer de sentier depuis
/// « Mes treks » ecrit [selectedTrailIdProvider] -> [trailConfigProvider] change
/// -> [appBootstrapProvider] (qui watch la config) RE-SEEDE la base pour le
/// nouveau sentier. On observe explicitement l'id du sentier actif ici (barriere
/// de re-seed lisible) et on affiche le loader PENDANT tout rechargement — y
/// compris un refresh « en place » (Riverpod garde alors l'ancienne valeur avec
/// `isLoading` vrai) : sans ca, l'app afficherait 1 frame l'ancien sentier
/// (carte/etapes de l'ancien trek) avant le re-seed. On regarde donc
/// `isLoading`/`isReloading` en plus du `hasValue` pour couvrir ce cas.
class _BootstrapGate extends ConsumerWidget {
  const _BootstrapGate({required this.child});

  /// Arbre route fourni par GoRouter (peut etre null tres tot dans le cycle de
  /// vie de MaterialApp.router — on affiche alors le loader).
  final Widget? child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Barriere de re-seed : le changement de sentier actif doit rejouer l'amorce
    // (le provider d'amorce watch deja la config ; cette lecture rend la
    // dependance explicite et documente l'invalidation au niveau de la garde).
    ref.watch(trailConfigProvider.select((c) => c.id));

    // StepWays L6/A6 : amorce PUB NON bloquante — resout le consentement UMP/CMP
    // puis initialise le SDK AdMob en tache de fond. On `watch` sans gater le
    // rendu dessus (best-effort) : l'app demarre meme si la pub echoue, et
    // aucune banniere ne s'affiche tant que le consentement n'est pas obtenu.
    ref.watch(adsReadyProvider);

    final bootstrap = ref.watch(appBootstrapProvider);
    final t = Translations.of(context);

    Widget loader() => _BootstrapScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            t.bootstrap.loading,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );

    // Rechargement en cours (premier seed OU re-seed apres changement de
    // sentier) : montrer le loader meme si une valeur precedente subsiste, pour
    // ne jamais laisser voir l'ancien sentier pendant le re-seed.
    if (bootstrap.isLoading) return loader();

    return bootstrap.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      // Amorce resolue : on rend l'arbre route, SOUS la garde de reprise
      // orpheline (StepWays LOT 2, C4 §3). `pendingSessionProvider` a deja ete
      // awaite par `appBootstrapProvider` (donc immediatement disponible ici) ;
      // s'il a detecte une rando laissee par un arret brutal, on propose
      // Reprendre / Abandonner une seule fois au premier rendu.
      data: (_) =>
          OrphanSessionReprise(child: child ?? const SizedBox.shrink()),
      loading: loader,
      error: (error, _) => _BootstrapScaffold(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            '$error',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}

/// Echafaudage commun (loader / erreur) de la porte d'amorce : centre le
/// contenu sur la couleur de fond du theme actif, pour une transition sans
/// clignotement vers l'ecran route.
class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(child: child),
    );
  }
}
