import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';

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

  // StepWays L7 (A — dates localisees) : charge les donnees de locale `intl`
  // pour toute la suite, comme `main()` le fait en production
  // (`initializeDateFormatting`). Sans ca, un `DateFormat(pattern, 'de'|'fr'...)`
  // leverait `LocaleDataException` en test (seul en_US est charge par defaut).
  await initializeDateFormatting();

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

  // ==========================================================================
  // LE STOCKAGE DU TELEPHONE, SIMULE POUR TOUTE LA SUITE (tache 613)
  // ==========================================================================
  //
  // POURQUOI CECI EXISTE MAINTENANT, ET PAS AVANT. Jusqu'a la tache 613 la base
  // de l'application etait ouverte EN MEMOIRE — en production, ce qui etait le
  // defaut — et aucun test n'avait donc besoin d'un repertoire. La base vit
  // desormais dans un FICHIER, resolu par `path_provider`. Or dans `flutter
  // test` aucun greffon n'est enregistre : le canal de `path_provider` ne repond
  // pas, et TOUT test qui construit le graphe de providers sans surcharger
  // `databaseProvider` echouait sur `MissingPluginException`.
  //
  // LE CHOIX RETENU, ET IL N'EST PAS UN CONTOURNEMENT : on ne desactive pas la
  // persistance en test, ON SIMULE LE TELEPHONE. Chaque test recoit un
  // repertoire temporaire NEUF qui joue le stockage de l'appareil. Consequence
  // voulue : la suite exerce desormais LE CHEMIN DE PRODUCTION — une vraie base
  // sur un vrai fichier — au lieu d'une base substituee. C'est precisement parce
  // que personne n'exercait ce chemin que le defaut a survecu des mois.
  //
  // UN REPERTOIRE PAR TEST, ET C'EST LA PARTIE QUI COMPTE. Un repertoire partage
  // ferait fuir l'etat d'un test dans le suivant — la forme de defaut la plus
  // penible a diagnostiquer. Ici, chaque test part d'un telephone vierge.
  //
  // Un test qui veut piloter ces chemins lui-meme (par exemple pour ROUVRIR la
  // meme base apres fermeture) reinstalle son propre gestionnaire dans son
  // `setUp` : declare plus tard, il passe apres celui-ci et gagne.
  Directory? stockageDuTest;
  const canalChemins = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() {
    stockageDuTest = Directory.systemTemp.createTempSync('sw_stockage_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalChemins, (appel) async {
      final racine = stockageDuTest;
      if (racine == null) return null;
      switch (appel.method) {
        case 'getApplicationDocumentsDirectory':
          return _sousDossier(racine, 'documents');
        case 'getApplicationSupportDirectory':
          return _sousDossier(racine, 'support');
        case 'getApplicationCacheDirectory':
        case 'getTemporaryDirectory':
          return _sousDossier(racine, 'cache');
        case 'getLibraryDirectory':
          return _sousDossier(racine, 'library');
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(canalChemins, null);
    final racine = stockageDuTest;
    stockageDuTest = null;
    if (racine != null && racine.existsSync()) {
      try {
        racine.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows peut tenir le fichier de base quelques millisecondes apres sa
        // fermeture. Le bac est temporaire : un menage rate ne doit pas faire
        // echouer un test qui, lui, a fait ce qu'on lui demandait.
      }
    }
  });

  // Filet zone : les rejets de futures non-attendues (chemin emprunte par
  // google_fonts) sont avales s'ils correspondent au chargement de police.
  await runZonedGuarded(() async => testMain(), (
    Object error,
    StackTrace stack,
  ) {
    if (isGoogleFontsLoadError(error)) return;
    // Erreur non liee aux polices : on la propage (echec legitime).
    Zone.current.parent!.handleUncaughtError(error, stack);
  });
}

/// Cree (si besoin) et rend le chemin d'un sous-dossier du stockage simule.
///
/// `path_provider` rend sur un vrai telephone des dossiers qui EXISTENT deja :
/// on reproduit cette garantie, sinon le premier appelant a ecrire devrait la
/// recreer lui-meme et la difference se paierait en tests verts ici, rouges
/// la-bas.
String _sousDossier(Directory racine, String nom) {
  final dossier = Directory('${racine.path}/$nom');
  if (!dossier.existsSync()) dossier.createSync(recursive: true);
  return dossier.path;
}
