/// LE RACCORD ENTRE UN ECRAN ET LE SERVICE D'OBSERVABILITE (lot 645-09).
///
/// C'est le SEUL geste qu'un ecran apprend. Aucun ecran n'appelle
/// `FirebaseCrashlytics.instance` : il nomme l'ecran ou il entre, et tout le
/// reste — les trois cles, la miette, le plafond, l'inertie, et depuis le
/// 645-09b la PILE DE NAVIGATION — est l'affaire de ce socle.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'analytics_service.dart';
import 'screen_breadcrumb.dart';

// LE CATALOGUE EST REEXPORTE ICI pour qu'un ecran n'ait qu'UN import a
// porter : le geste et les noms d'ecran arrivent ensemble.
export 'screen_breadcrumb.dart';

/// Le journal local de secours de ce raccord.
final _log = Logger(printer: SimplePrinter(colors: false));

/// CE QU'UN ECRAN A DECLARE A SA DERNIERE ENTREE, range SUR SON ELEMENT.
///
/// C'est la memoire qui permet de REPOSER la bonne miette quand un ecran
/// redevient visible sans repasser par son point d'entree (voir
/// [ScreenEntryObserver]). Un `Expando` et non une table : la cle est
/// l'element de l'ecran, tenue FAIBLEMENT — un ecran demonte emporte son
/// entree, rien ne s'accumule.
final _entryOf = Expando<_Entry>('entree d ecran (645-09b)');

/// Une entree d'ecran : le nom, et ce que l'ecran sait du sentier et de
/// l'etape.
final class _Entry {
  const _Entry(this.screen, this.trail, this.stage);
  final ScreenBreadcrumb screen;
  final String? trail;
  final String? stage;
}

/// POSE LA MIETTE D'ENTREE D'ECRAN, ET NE COUTE JAMAIS L'ECRAN.
///
/// A APPELER A L'ENTREE DE L'ECRAN : dans `initState` quand l'ecran a un etat,
/// en premiere instruction de `build` quand il n'en a pas. Le service
/// deduplique (voir [AnalyticsService.enterScreen]), si bien que les deux
/// emplacements donnent la MEME chose : une miette par entree d'ecran, pas une
/// par reconstruction.
///
/// SEUL L'ECRAN VISIBLE PARLE (lot 645-09b). `Navigator` reconstruit les
/// ecrans restes vivants SOUS celui du dessus, et la deduplication du service
/// ne retient que la DERNIERE empreinte : avant ce lot, les ecrans instrumentes
/// dans `build` reposaient donc leur miette a chaque empilement, a tour de
/// role, et la cle `screen` designait un ecran cache (QA d'Artemis, 04/10/2026,
/// 12 fois sur 12). L'entree n'est donc transmise que si la route de l'ecran
/// est la route COURANTE — voir [_isVisible]. Les deux autres cles suivent :
/// un ecran cache ne pose ni `trail` ni `stage`.
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
    final screenContext = ref.context;
    final entry = _Entry(screen, trail, stage);
    // MEMORISEE AVANT LE FILTRE : un ecran cache dont l'etape change sous
    // la pile doit reposer la NOUVELLE etape quand il redevient visible.
    _entryOf[screenContext] = entry;
    if (!_isVisible(screenContext)) return;
    _send(ref.read(analyticsServiceProvider), entry);
  } on Object catch (e) {
    _log.w('[observabilite] entree d ecran non observee (${screen.name}) : $e');
  }
}

/// L'ECRAN EST-IL CELUI QUE LE RANDONNEUR REGARDE ?
///
/// UN ECRAN SANS ETAT (`ConsumerWidget`) n'a pas d'`initState` : son appel
/// vient forcement de `build` (ou d'un geste), ou consulter la route est
/// permis. [ModalRoute.isCurrentOf] y repond, et ABONNE l'ecran au seul
/// aspect « courant » de sa route : quand on depile ce qui le couvrait, il
/// est reconstruit, rappelle ce raccord, et repose sa miette. Sans route
/// (un ecran monte hors de tout `Navigator`), il est visible par definition.
///
/// UN ECRAN A ETAT pose sa miette dans `initState` (la garde OBS-01 l'exige),
/// qui ne tourne qu'UNE fois par montage : il ne participe donc pas au defaut,
/// et `Flutter` interdit d'y lire une route. Son montage EST son entree. Son
/// RETOUR au premier plan, que `initState` ne voit pas, est l'affaire de
/// [ScreenEntryObserver].
bool _isVisible(BuildContext screenContext) {
  if (screenContext.widget is! ConsumerWidget) return true;
  return ModalRoute.isCurrentOf(screenContext) ?? true;
}

/// Transmet [entry] au service, sans rien attendre ni laisser remonter.
void _send(AnalyticsService service, _Entry entry) {
  unawaited(
    service
        .enterScreen(entry.screen, trail: entry.trail, stage: entry.stage)
        .catchError((Object e) {
          _log.w(
            '[observabilite] miette d ecran rejetee '
            '(${entry.screen.name}) : $e',
          );
        }),
  );
}

/// L'OBSERVATEUR DE PILE : REPOSE LA MIETTE DE L'ECRAN QUI REDEVIENT VISIBLE
/// (lot 645-09b). Il est branche UNE fois, sur le routeur de l'application.
///
/// POURQUOI IL EXISTE EN PLUS DU FILTRE DE [observeScreenEntry]. Le filtre
/// fait taire les ecrans caches, et un ecran SANS etat qui revient au premier
/// plan reparle de lui-meme (il est reconstruit). Un ecran A ETAT, non : sa
/// miette vit dans `initState`, qui ne retourne pas quand on depile. Sans cet
/// observateur, « Reglages » puis retour au cockpit laissait `screen` sur
/// `settings` — un ecran qui n'existe plus.
///
/// IL NE CONNAIT AUCUN NOM D'ECRAN, et c'est voulu : il ne fait que REPOSER ce
/// que l'ecran a declare lui-meme a son entree. Pas de seconde table des 63
/// noms, donc pas de seconde source de verite a tenir a jour.
class ScreenEntryObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _repostAfterFrame(previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _repostAfterFrame(previousRoute);
}

/// Repose l'entree de l'ecran porte par [route], si elle est REDEVENUE la
/// route courante.
///
/// APRES LA FRAME, ET C'EST UNE CONTRAINTE : `Navigator` previent ses
/// observateurs pendant qu'il reconstruit la pile, et l'arbre ne se parcourt
/// pas en pleine construction. La frame passee, la route est re-verifiee :
/// un depilement suivi d'un empilement dans la meme frame ne repose rien.
void _repostAfterFrame(Route<dynamic>? route) {
  if (route is! ModalRoute) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    try {
      final root = route.subtreeContext;
      if (!route.isCurrent || root == null || !root.mounted) return;
      final screenContext = _instrumentedScreen(root);
      if (screenContext == null) return;
      _send(
        ProviderScope.containerOf(
          screenContext,
          listen: false,
        ).read(analyticsServiceProvider),
        _entryOf[screenContext]!,
      );
    } on Object catch (e) {
      _log.w('[observabilite] retour d ecran non observe : $e');
    }
  });
}

/// Le premier element instrumente sous [root] : l'ecran de la route.
Element? _instrumentedScreen(BuildContext root) {
  Element? found;
  void visit(Element e) {
    if (found != null) return;
    if (_entryOf[e] != null) {
      found = e;
      return;
    }
    e.visitChildElements(visit);
  }

  root.visitChildElements(visit);
  return found;
}
