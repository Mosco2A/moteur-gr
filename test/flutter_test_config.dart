import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Configuration globale de la suite de tests (auto-chargee par `flutter test`).
///
/// SW-SKIN-L1 : depuis le cablage de `google_fonts` dans le theme, toute
/// construction de theme declenche `GoogleFonts.*` qui tente de charger la
/// police. En environnement de test (headless, hors-ligne, polices non
/// bundlees) ce chargement echoue et google_fonts *rethrow* dans une future
/// non-attendue -> l'erreur remonterait dans le zone de chaque test et le
/// ferait echouer, alors que le `TextStyle` renvoye est correct (bonne famille,
/// fallback systeme). Ce comportement reflete la garantie offline-first du
/// produit : aucune dependance reseau au rendu.
///
/// On :
///  1. desactive le fetch HTTP runtime (pattern officiel google_fonts en test) ;
///  2. filtre l'erreur benigne de chargement de police (FlutterError + zone),
///     toute AUTRE erreur restant fatale.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  bool isGoogleFontsLoadError(Object error) {
    final msg = error.toString();
    return msg.contains('unable to load font') ||
        msg.contains('allowRuntimeFetching is false') ||
        msg.contains('Failed to load font');
  }

  // Filet FlutterError : les erreurs de chargement google_fonts qui remontent
  // via le pipeline Flutter sont ignorees ; le reste garde le handler d'origine.
  final FlutterExceptionHandler? previousOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (isGoogleFontsLoadError(details.exception)) return;
    (previousOnError ?? FlutterError.presentError)(details);
  };

  // Filet PlatformDispatcher : rejets de futures non-attendues remontant a
  // l'isolate racine (cas des `test()` purs) -> avale l'erreur police, propage
  // le reste. Retourne true pour marquer l'erreur police comme geree.
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    return isGoogleFontsLoadError(error);
  };

  // Filet zone : les rejets de futures non-attendues (chemin emprunte par
  // google_fonts) sont avales s'ils correspondent au chargement de police.
  await runZonedGuarded(
    () async => testMain(),
    (Object error, StackTrace stack) {
      if (isGoogleFontsLoadError(error)) return;
      // Erreur non liee aux polices : on la propage (echec legitime).
      Zone.current.parent!.handleUncaughtError(error, stack);
    },
  );
}
