import 'package:flutter/foundation.dart';

import 'error_handler.dart';

/// Signature d'un rapporteur de plantage (Crashlytics en production).
typedef RapporteurDePlantage = void Function(
  Object error,
  StackTrace? stack, {
  bool fatal,
});

/// LES FILETS D'ERREUR DE L'APPLICATION (596 C4).
///
/// LE CONSTAT : `FlutterError.onError`, `PlatformDispatcher.instance.onError`
/// et `runZonedGuarded` avaient ZERO occurrence dans `lib/`. Aucune erreur, de
/// quelque nature que ce soit, n'etait collectee. `AnalyticsService.recordError`
/// et `recordFatal` existaient — et n'etaient appeles de nulle part.
///
/// Autrement dit : meme si Firebase avait ete allume, il n'aurait rien recu. La
/// configuration manquante n'etait que le premier des deux verrous.
///
/// CE QUE POSE CETTE CLASSE :
///   * `FlutterError.onError` — les erreurs de l'arbre de widgets (rendu,
///     layout, assertions). Non fatales : l'appli continue.
///   * `PlatformDispatcher.instance.onError` — tout ce qui echappe a l'arbre
///     (futures non attendues, isolates). Fatales : c'est un crash.
///
/// DEUX GARANTIES, parce qu'un filet qui fait tomber l'appli est pire que pas
/// de filet :
///   1. sans rapporteur branche (mode local, aucun cloud), l'erreur est
///      seulement journalisee — rien ne plante ;
///   2. un rapporteur qui echoue lui-meme est avale : on ne plante jamais DANS
///      le gestionnaire de plantage.
abstract final class ErrorNets {
  static RapporteurDePlantage? _rapporteur;
  static bool _installes = false;
  static FlutterExceptionHandler? _precedentFlutterOnError;

  /// Vrai une fois [installer] appele.
  static bool get installes => _installes;

  /// Pose les deux filets. Idempotent.
  static void installer() {
    if (_installes) return;
    _precedentFlutterOnError = FlutterError.onError;

    FlutterError.onError = (FlutterErrorDetails details) {
      ErrorHandler.log(
        details.exception,
        stackTrace: details.stack,
        context: details.context?.toDescription() ?? 'rendu',
      );
      _rapporter(details.exception, details.stack, fatal: false);
      // On laisse le comportement d'origine s'exprimer (affichage en debug,
      // filtres de la suite de tests) : le filet OBSERVE, il ne confisque pas.
      (_precedentFlutterOnError ?? FlutterError.presentError)(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      ErrorHandler.log(error, stackTrace: stack, context: 'hors arbre');
      _rapporter(error, stack, fatal: true);
      // Traitee : l'appli ne meurt pas sur une future non attendue.
      return true;
    };

    _installes = true;
  }

  /// Branche le rapporteur reel (Crashlytics) une fois le cloud disponible.
  ///
  /// Appele APRES l'initialisation Firebase : tant que le cloud est absent, les
  /// erreurs restent dans les journaux locaux, ce qui est exactement ce que
  /// l'appli doit faire en mode local.
  static void brancherRapporteur(RapporteurDePlantage rapporteur) {
    _rapporteur = rapporteur;
  }

  /// Remet les filets a zero — reserve aux tests.
  @visibleForTesting
  static void retirerPourTest() {
    if (_installes) {
      FlutterError.onError = _precedentFlutterOnError;
      PlatformDispatcher.instance.onError = null;
    }
    _precedentFlutterOnError = null;
    _rapporteur = null;
    _installes = false;
  }

  static void _rapporter(Object error, StackTrace? stack, {required bool fatal}) {
    final rapporteur = _rapporteur;
    if (rapporteur == null) return;
    try {
      rapporteur(error, stack, fatal: fatal);
    } on Object catch (e) {
      // JAMAIS de plantage dans le gestionnaire de plantage.
      ErrorHandler.log(e, context: 'ErrorNets.rapporteur');
    }
  }
}
