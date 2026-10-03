/// LE RACCORD ENTRE UN ECRAN ET LE SERVICE D'OBSERVABILITE (lot 645-09).
///
/// C'est le SEUL geste qu'un ecran apprend. Aucun ecran n'appelle
/// `FirebaseCrashlytics.instance` : il nomme l'ecran ou il entre, et tout le
/// reste — les trois cles, la miette, le plafond, l'inertie — est l'affaire du
/// service.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'analytics_service.dart';
import 'screen_breadcrumb.dart';

// LE CATALOGUE EST REEXPORTE ICI pour qu'un ecran n'ait qu'UN import a
// porter : le geste et les noms d'ecran arrivent ensemble.
export 'screen_breadcrumb.dart';

/// Le journal local de secours de ce raccord.
final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// POSE LA MIETTE D'ENTREE D'ECRAN, ET NE COUTE JAMAIS L'ECRAN.
///
/// A APPELER A L'ENTREE DE L'ECRAN : dans `initState` quand l'ecran a un etat,
/// en premiere instruction de `build` quand il n'en a pas. Le service
/// deduplique (voir [AnalyticsService.enterScreen]), si bien que les deux
/// emplacements donnent la MEME chose : une miette par entree d'ecran, pas une
/// par reconstruction.
///
/// TROIS GARDES, ET CHACUNE REPOND A UNE PANNE REELLE. L'instrumentation doit
/// etre inerte quand Firebase est indisponible — ce qui est le cas 100 pct du
/// temps aujourd'hui — et un ecran ne doit JAMAIS ralentir, bloquer ni echouer
/// parce qu'une miette n'a pas pu partir :
///
///   1. RIEN N'EST ATTENDU. Aucun `await` : la fonction rend la main tout de
///      suite, donc ni `initState` ni `build` n'attendent un canal natif. Le
///      lot 637 a montre ce que coute un journal sur le chemin d'un ecran.
///   2. LA LECTURE DU PROVIDER EST GARDEE. `ref.read` peut lever — un
///      provider surcharge en test, un conteneur deja detruit. Une exception
///      ici coutait l'ecran entier.
///   3. LE REJET ASYNCHRONE EST RATTRAPE. Le service avale deja ses propres
///      pannes, mais un puits qui rendrait une future rejetee ferait remonter
///      l'erreur dans la zone de l'application, loin d'ici et sans contexte.
///
/// LE SERVICE QUI SERT A SAVOIR QUE L'APPLICATION CASSE NE DOIT PAS POUVOIR LA
/// CASSER : c'est la lecon du volet 2 de la tache 637, et ces trois gardes en
/// sont la forme pour les ecrans.
void observeScreenEntry(
  WidgetRef ref,
  ScreenBreadcrumb screen, {
  String? trail,
  String? stage,
}) {
  try {
    unawaited(
      ref
          .read(analyticsServiceProvider)
          .enterScreen(screen, trail: trail, stage: stage)
          .catchError((Object e) {
            _log.w(
              '[observabilite] miette d ecran rejetee '
              '(${screen.name}) : $e',
            );
          }),
    );
  } on Object catch (e) {
    _log.w('[observabilite] entree d ecran non observee (${screen.name}) : $e');
  }
}
