import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/analytics/firebase_analytics_sink.dart';
import 'core/branding/app_branding.dart';
import 'core/config/firebase_config.dart';
import 'core/config/mare_a_mare_centre_trail_config.dart';
import 'core/config/trail_config.dart';
import 'core/error/error_nets.dart';
import 'core/firebase/firebase_service.dart';
import 'core/engine/trail_engine.dart';
import 'core/providers/app_bootstrap_provider.dart';
import 'core/routing/app_router.dart';
import 'core/routing/home_location_provider.dart';
import 'core/services/descente_des_droits.dart';
import 'core/services/ordonnanceur_de_synchronisation.dart';
import 'core/services/sync_scheduler.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/skin_provider.dart';
import 'features/ads/providers/ads_providers.dart';
import 'features/onboarding/providers/onboarding_providers.dart';
import 'features/settings/data/settings_service.dart';
import 'features/settings/providers/settings_provider.dart';
import 'features/safety/presentation/porte_consentement_sauvegarde.dart';
import 'features/treks/presentation/widgets/orphan_session_reprise.dart';
import 'i18n/translations.g.dart';
import 'shared/widgets/app_logo.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // LES FILETS D'ERREUR, POSES AVANT TOUT LE RESTE (596 C4).
  //
  // `FlutterError.onError`, `PlatformDispatcher.instance.onError` et
  // `runZonedGuarded` avaient ZERO occurrence dans tout `lib/` : AUCUNE erreur
  // de l'application n'etait collectee, nulle part. Firebase allume n'y aurait
  // rien change — il n'y avait personne pour lui donner quoi que ce soit.
  //
  // Poses des la premiere ligne utile : une erreur survenue pendant l'amorce
  // (lecture des prefs, dates, amorce du sentier) doit etre attrapee elle
  // aussi. Sans rapporteur branche, elles partent dans les journaux locaux —
  // ce qui est exactement le comportement attendu en mode local.
  ErrorNets.installer();

  // OFFLINE-FIRST (fix cycle 3) : interdit tout fetch HTTP de police au runtime.
  // La typographie (Montserrat) est desormais EMBARQUEE comme famille Flutter
  // native (pubspec `fonts:` + assets/fonts/, parite GR20) et resolue en local.
  // Ce garde-fou garantit qu'aucun code (present ou futur) ne rappellera le
  // reseau pour une police -> boot fiable en mode avion (cas Ines, payeuse
  // offline, qui etait bloquee par l'echec de fetch de google_fonts au boot).
  GoogleFonts.config.allowRuntimeFetching = false;

  // E5.1b — lit le flag d'onboarding AVANT le premier rendu pour que le guard
  // du routeur (synchrone) redirige vers /onboarding au tout premier lancement.
  final prefs = await SharedPreferences.getInstance();
  hasCompletedOnboarding = prefs.getBool(kOnboardingCompletedKey) ?? false;

  // StepWays L7 (A — persistance de la langue) : RESTAURATION du choix de langue
  // AVANT le premier rendu. Slang n'est PAS persistant par defaut.
  // - 1er lancement (aucun choix sauve) : AUTO-DETECTION silencieuse de la
  //   locale du telephone (useDeviceLocale) ; si elle n'est pas dans les 5
  //   langues, Slang retombe sur la base (fr). Aucun ecran de choix impose
  //   (recommandation i18n.md : detection auto + modifiable dans les reglages).
  // - Lancements suivants : on rejoue le choix persiste (settings_language).
  // Tout est EMBARQUE (assets/i18n) -> fonctionne 100% hors-ligne, mode avion.
  final savedLanguage = prefs.getString(SettingsKeys.language);
  if (savedLanguage != null && savedLanguage.isNotEmpty) {
    LocaleSettings.setLocaleRawSync(savedLanguage);
  } else {
    LocaleSettings.useDeviceLocaleSync();
  }

  // StepWays L7 (A — dates/pluriels localises) : charge les donnees de locale
  // `intl` pour les 5 langues. Sans cet appel, `DateFormat(pattern, locale)`
  // levait `LocaleDataException` hors en_US (d'ou les repli defensifs des ecrans
  // calendrier/meteo/resume). Desormais les dates s'ecrivent « a la mode » de
  // chaque pays (lundi 7 juil. / Monday 7 Jul / Montag, 7. Juli...).
  await initializeDateFormatting();

  // Initialisation Firebase conditionnelle :
  // si firebaseProjectId est null, le moteur reste en mode local.
  // PARITE GR20 — LOT 1 (#99423) : la demo demarre sur Mare a Mare Centre
  // (sentier reel de StepWays), en tete du catalogue. Le moteur reste
  // generique : c'est une DONNEE (TrailConfig), aucune localite hardcodee ici.
  //
  // 596 C4 — L'IDENTIFIANT DE PROJET A ENFIN UN POINT D'ENTREE. Il n'etait
  // renseigne dans AUCUNE configuration de sentier, et aucun moyen n'existait
  // de le renseigner : `Firebase.initializeApp()` n'etait donc jamais execute,
  // a 100 % des demarrages. Il est desormais injecte au build
  // (`--dart-define=STEPWAYS_FIREBASE_PROJECT_ID=...`, cf. [FirebaseConfig]),
  // jamais ecrit dans le depot. Absent => mode local, dit dans les journaux,
  // et l'application demarre normalement.
  final firebaseService = await FirebaseService.initialize(
    firebaseProjectId: FirebaseConfig.resoudre(
      depuisLeSentier: mareAMareCentreTrailConfig.firebaseProjectId,
    ),
  );

  // Le rapporteur de plantage n'est branche QUE si le cloud a vraiment demarre.
  // C'est le second verrou du meme defaut : la configuration presente ne suffit
  // pas, encore faut-il que quelqu'un transmette les erreurs.
  if (firebaseService.isAvailable) {
    final crash = FirebaseCrashSink();
    ErrorNets.brancherRapporteur(
      (error, stack, {bool fatal = false}) =>
          unawaited(crash.recordError(error, stack, fatal: fatal)),
    );
  }

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
        // TACHE 613 — L'OVERRIDE DU DAO SANTE A ETE RETIRE, PAS OUBLIE. Il
        // cablait la fiche medicale (E57 LOT D/D1) sur la base Drift commune.
        // Cette base est desormais DURABLE et doit remonter dans la sauvegarde
        // du telephone pour que la progression et le journal survivent au
        // changement d'appareil ; un fichier de base ne s'excluant pas table par
        // table, la fiche a recu son PROPRE fichier sous le dossier declare
        // exclu (`FicheMedicaleFichier`, cable par
        // `ficheMedicaleFichierProvider`). Plus rien de medical ne passe par
        // `databaseProvider` : il n'y a donc plus rien a cabler ici.
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

    // StepWays L7 (A) : la MaterialApp suit la langue choisie. On observe le
    // champ `language` des reglages : changer de langue reconstruit la
    // MaterialApp avec la nouvelle `locale`, ce qui localise AUSSI les widgets
    // Material natifs (DatePicker, tooltips...) et les formats de date `intl`.
    // Le contenu Slang (t.*) bascule via TranslationProvider ; ici on aligne la
    // locale Flutter/intl sur la locale Slang courante (source de verite unique).
    final language = ref.watch(settingsProvider.select((s) => s.language));
    final locale = AppLocaleUtils.parse(language).flutterLocale;

    return MaterialApp.router(
      title: config.displayName,
      debugShowCheckedModeBanner: false,
      // StepWays L7 (A) : localisation Flutter native (5 langues embarquees).
      locale: locale,
      supportedLocales: AppLocaleUtils.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        // NOMS DE PAYS LOCALISES (retour Chris #2, tache 553). Le selecteur de
        // pays de la fiche randonneur affiche « France », « Deutschland »,
        // « Italia »... dans la langue de l'application : ces noms viennent de ce
        // delegue (package `country_picker`, 246 pays x 35 langues embarquees,
        // zero reseau). SANS LUI, `CountryLocalizations.of(context)` rend `null`
        // et toute la liste retombe en anglais — c'est la seule ligne qui fait la
        // difference entre un selecteur localise et un selecteur anglais.
        // Il couvre nos cinq langues (de, en, es, fr, it), verifie code par code.
        CountryLocalizations.delegate,
      ],
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
      // LE MODE SOMBRE / CLAIR SUIT ENFIN LE REGLAGE (tache 558).
      //
      // Retour de Chris, mot pour mot : « sombrer clair ca ne fonctionne pas ».
      // Cette ligne valait `ThemeMode.dark` EN DUR. Tout le reste du chemin
      // existait pourtant en entier : les trois choix dans les Reglages, la
      // persistance du choix, le theme clair construit et passe juste au-dessus.
      // Le randonneur choisissait « Clair », le choix etait enregistre, survivait
      // au redemarrage — et l'ecran restait sombre. Un seul fil manquait.
      //
      // `select` sur le seul champ `themeMode` : changer de langue ou d'unite ne
      // reconstruit pas la MaterialApp pour autant. `system` suit le telephone,
      // et le defaut du produit reste sombre.
      themeMode: AppThemeModeValues.toThemeMode(
        ref.watch(settingsProvider.select((s) => s.themeMode)),
      ),
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
/// qui seede le sentier actif SI SES DONNEES NE SONT PAS DEJA EN BASE. Depuis la
/// tache 613 la base est durable : le seed force a chaque lancement a ete retire,
/// il aurait duplique etapes, POI et trace a chaque ouverture. Tant que le seed
/// n'est pas resolu, affiche un ecran de chargement
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

    // ACCUEIL CONTEXTUEL TENU A JOUR AU NIVEAU DE L'APPLICATION (tache 548).
    //
    // La destination d'accueil (maison / terrain) est un etat GLOBAL : elle
    // depend de la rando active, pas de l'ecran affiche. Elle etait pourtant
    // (re)decouverte par chaque `AppHeader`, au moment ou il se montait.
    // Riverpod 3 met en PAUSE les abonnements d'un ecran qui n'est plus a
    // l'avant-plan : entre la fin d'une rando (qui invalide
    // `activeTrekIdProvider`) et le montage de l'en-tete de l'ecran suivant,
    // le selecteur n'avait plus aucun auditeur actif — l'ordonnanceur le
    // laissait donc « a recalculer » au lieu de le rafraichir. Le premier
    // `AppHeader` a se monter declenchait ce recalcul EN PLEINE PHASE DE BUILD,
    // le selecteur se re-invalidait et reclamait un rafraichissement du
    // `ProviderScope` : un `setState()` pendant le build, refuse par Flutter
    // (assertion relevee par la campagne 547 sur `AppHeader.build`).
    //
    // Cette garde ne se demonte jamais et n'est jamais mise en pause (elle est
    // au-dessus du `Navigator`) : l'accueil contextuel garde ici un auditeur
    // actif en permanence, donc il est rafraichi par l'ordonnanceur AVANT la
    // phase de build, jamais pendant. Aucun effet visuel : la garde rend le
    // meme arbre route.
    ref.watch(homeLocationProvider);

    // StepWays L6/A6 : amorce PUB NON bloquante — resout le consentement UMP/CMP
    // puis initialise le SDK AdMob en tache de fond. On `watch` sans gater le
    // rendu dessus (best-effort) : l'app demarre meme si la pub echoue, et
    // aucune banniere ne s'affiche tant que le consentement n'est pas obtenu.
    ref.watch(adsReadyProvider);

    // LA CADENCE DE SYNCHRONISATION EST ARMEE ICI (tache 616), ET RIEN NE L ARMAIT.
    //
    // Demande de Christophe du 28/09 09:32 : « quand l appli recupere du reseau (et
    // ensuite toutes les 4 heures par exemple) elle vient verifier toutes les
    // donnees superieures a sa date de MAJ ». La mecanique existait depuis la tache
    // E4.11c (`UpdateDownloader.scheduleBackgroundDownload`) mais AUCUN code de
    // production ne l'appelait : un sentier ne se mettait a jour que si le
    // randonneur rouvrait le catalogue et appuyait lui-meme.
    //
    // POURQUOI ICI ET PAS DANS UN ECRAN. Cette garde vit au-dessus du `Navigator`
    // et ne se demonte jamais ; Riverpod 3 met en PAUSE les abonnements d'un ecran
    // qui n'est plus a l'avant-plan, donc une cadence branchee depuis le catalogue
    // s'arreterait des qu'on en sort. C'est le meme raisonnement que pour
    // [homeLocationProvider] ci-dessus.
    //
    // NON BLOQUANT : l'ordonnanceur arme une horloge et une ecoute de
    // connectivite, il ne declenche aucune passe au demarrage et ne retarde donc
    // pas le premier ecran.
    ref.watch(ordonnanceurDemarreProvider);

    // L ECOUTE EN DIRECT DES DROITS (tache 631), ARMEE AU MEME ENDROIT ET POUR
    // LA MEME RAISON. Le scenario d acceptation de Christophe est : on ecrit ses
    // droits depuis le PC et il les voit arriver dans l application OUVERTE,
    // sans la fermer. La cadence de l ordonnanceur (quatre heures) est le repli
    // pour le reste du temps ; ceci est le direct. Cette garde ne se demonte
    // jamais et n est jamais mise en pause : l ecoute vit aussi longtemps que
    // l application.
    ref.watch(descenteEnDirectProvider);

    // LA MONTEE EN BASE, ARMEE ICI ET NULLE PART AILLEURS (tache 635).
    //
    // Demande de Christophe du 29/09 : « je veux voir toutes les donnees en
    // base qui se mettent a jour quand je rentre des infos dans l appli ». La
    // mecanique de montee existait depuis le LOT A5 et DEUX ordonnanceurs
    // etaient censes la reveiller — aucun des deux n avait le moindre appelant
    // dans `lib/`. Le telephone n ecrivait donc RIEN : ni fiche technique, ni
    // progression, ni sac, ni randos passees, d ou le constat « donnees dans la
    // base ni utilisateur ni sentier ».
    //
    // MEME RAISON D ETRE ICI que la cadence et l ecoute des droits juste
    // au-dessus : cette garde vit au-dessus du `Navigator` et ne se demonte
    // jamais. Une montee branchee depuis un ecran s arreterait des qu on
    // naviguerait ailleurs, c est-a-dire au moment meme ou le randonneur valide
    // une etape et change d ecran.
    //
    // NON BLOQUANT : elle attend l identite en tache de fond et n empeche pas le
    // premier rendu.
    ref.watch(monteeEnBaseDemarreeProvider);

    final bootstrap = ref.watch(appBootstrapProvider);
    final t = Translations.of(context);

    // LE PREMIER ECRAN FLUTTER PROLONGE LE SPLASH NATIF (tache 632).
    //
    // L'ecran de demarrage natif (flutter_native_splash, variante Foret) montre
    // le logo sur le vert #1F3D2B, puis s'efface des que Flutter dessine sa
    // premiere image — qui etait jusqu'ici un fond de theme CLAIR avec un
    // tourniquet nu. Le randonneur voyait donc un flash blanc au lancement, et
    // l'application ne disait son nom nulle part.
    //
    // Ce loader reprend la couleur ET le logo du splash natif : la passation ne
    // se voit plus. C'est l'equivalent du `main_snippet.dart` livre par
    // Christophe (`FlutterNativeSplash.preserve`), en mieux : la continuite
    // couvre AUSSI le re-seed apres un changement de sentier, pas seulement
    // l'amorce initiale — et sans garder la main sur le splash natif, donc sans
    // risque de figer le demarrage si l'amorce echoue.
    Widget loader() => _BootstrapScaffold(
      fond: AppBranding.couleurFondSplash,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo.horizontal(
            hauteur: 52,
            surFondSombre: AppBranding.splashSurFondSombre,
          ),
          const SizedBox(height: 40),
          const CircularProgressIndicator(color: _encreSurSplash),
          const SizedBox(height: 24),
          Text(
            t.bootstrap.loading,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: _encreSurSplash),
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
      //
      // ET SOUS LA PORTE DU CONSENTEMENT DE SAUVEGARDE (tache 617). La question
      // « je refuse la sauvegarde de mes donnees par le systeme du telephone »
      // etait posee a la seule connexion Google depuis la tache 612, dont le
      // bilan nommait le trou : le randonneur anonyme ne la voyait jamais. Elle
      // est posee ICI, une fois, a tout le monde. La PROTECTION, elle, s'applique
      // deja (refus par defaut) : poser la question n'est pas proteger, et c'est
      // ce qui autorise a la poser apres le premier rendu plutot qu'a bloquer le
      // demarrage.
      //
      // ORDRE DES DEUX PORTES : la reprise orpheline est la plus interieure, donc
      // son dialogue s'ouvre en second et se retrouve AU-DESSUS. C'est voulu :
      // reprendre une rando interrompue est un geste urgent, le consentement de
      // sauvegarde ne l'est pas, et il sera repose au lancement suivant s'il est
      // ignore.
      data: (_) => PorteConsentementSauvegarde(
        child: OrphanSessionReprise(child: child ?? const SizedBox.shrink()),
      ),
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

/// Encre posee sur le fond de l'ecran de demarrage : le creme de la charte sur
/// le vert sombre (variante Foret), le vert sombre sur le creme (variante
/// Aube). Derive de la variante active, donc suit `tool/set_branding.py`.
const Color _encreSurSplash = AppBranding.splashSurFondSombre
    ? Color(0xFFF4F1E8)
    : Color(0xFF1F3D2B);

/// Echafaudage commun (loader / erreur) de la porte d'amorce : centre le
/// contenu pour une transition sans clignotement vers l'ecran route.
///
/// [fond] laisse a null = couleur de fond du theme actif. C'est ce que garde la
/// branche ERREUR : le message y est ecrit a l'encre du theme, et le forcer sur
/// le vert du splash le rendrait illisible. Le loader, lui, passe la couleur du
/// splash pour prolonger l'ecran de demarrage natif (tache 632).
class _BootstrapScaffold extends StatelessWidget {
  const _BootstrapScaffold({required this.child, this.fond});

  final Widget child;
  final Color? fond;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: fond ?? Theme.of(context).scaffoldBackgroundColor,
      body: Center(child: child),
    );
  }
}
