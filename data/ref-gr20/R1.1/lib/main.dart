import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/constants/hive_boxes.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/feedback/data/tester_message_service.dart';
import 'core/data/remote_data_service.dart';
import 'features/trek/data/trek_service.dart';
import 'firebase_options.dart';

/// B62 ANR fix — main() fait le strict minimum avant runApp().
/// TOUT le reste (auth, Hive boxes, sync, geolocator) est differe
/// après le premier frame via postFrameCallback / FutureProvider.
/// B83: Flag RGPD Crashlytics — accessible dans le error handler de runZonedGuarded.
bool _crashReportingEnabled = false;

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // --- Les 2 seuls await obligatoires avant runApp ---
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await Hive.initFlutter();

    // B83: Crashlytics RGPD — activer seulement si consentement utilisateur
    final prefs = await SharedPreferences.getInstance();
    _crashReportingEnabled =
        prefs.getBool('crash_reporting_consent') ?? false;
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(_crashReportingEnabled);

    if (_crashReportingEnabled) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    // B62: orientation + date formatting + status bar APRES runApp
    // pour ne pas bloquer le premier frame.
    runApp(const ProviderScope(child: G20App()));
  }, (error, stack) {
    if (_crashReportingEnabled) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    }
  });
}

/// B62: Provider qui differe TOUTE l'initialisation lourde après le premier frame.
/// Ouverture des Hive boxes, date formatting, orientation, auth.
/// L'UI rend le splash immediatement, ce provider tourne en background.
final _postFrameInitProvider = FutureProvider<void>((ref) async {
  // Attendre le premier frame avant de commencer le travail lourd
  final completer = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    completer.complete();
  });
  await completer.future;

  // --- Phase 1 : config systeme rapide (pas de I/O réseau) ---
  unawaited(initializeDateFormatting('fr_FR', null));
  unawaited(SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]));
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF121212),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // --- Phase 2 : ouverture des Hive boxes (I/O locale, rapide) ---
  // B66: ouvrir app_settings AVANT les trek boxes pour que le cache
  // profileCompleted soit disponible des le premier redirect du router.
  try {
    if (!Hive.isBoxOpen(HiveBoxes.appSettings)) {
      await Hive.openBox(HiveBoxes.appSettings);
    }
  } catch (_) {
    // Pas critique — le provider tombera sur le fallback Firestore
  }

  final trekService = TrekService();
  await trekService.initialize();

  // B0: Initialiser le RemoteDataService (non bloquant, fallback const hardcodees)
  unawaited(RemoteDataService.instance.initialize());

  // --- Phase 3 : auth anonyme (réseau, peut etre lent) ---
  // Declenchee via autoAuthProvider dans G20App.build — rien a faire ici.
});

/// F7: Provider qui ecrit app_version + platform dans users/{uid} au lancement.
/// Fire-and-forget — ne bloque pas le main thread.
/// Declenche apres auth pour avoir le uid.
final _writeAppVersionProvider = FutureProvider<void>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return;

  // #267: Ne pas ecrire dans users/{uid} tant que le profil n'est pas complete.
  // Empeche la creation de documents fantomes par les sessions anonymes.
  try {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.collectionUsers)
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data()?['profileCompleted'] != true) return;
  } catch (_) {
    return;
  }

  final service = TesterMessageService();
  unawaited(service.writeAppVersion(uid: user.uid));
});

/// Widget racine de l'application GR20
class G20App extends ConsumerWidget {
  const G20App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // B62: Declencher l'init post-frame (Hive boxes, orientation, dates).
    // Le splash s'affiche immediatement, le travail lourd tourne en fond.
    ref.watch(_postFrameInitProvider);

    // B62: L'auth anonyme est declenchee APRES le premier frame
    // via autoAuthProvider. Le router affiche splash tant que l'auth
    // n'a pas resolu — pas de blocage du main thread.
    ref.watch(autoAuthProvider);

    // F7: Ecrire app_version dans Firestore apres auth (fire-and-forget)
    ref.watch(_writeAppVersionProvider);

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('fr', 'FR'),
    );
  }
}
