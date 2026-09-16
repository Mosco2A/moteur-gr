import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Fournisseur de tuiles INERTE, reserve aux tests d'integration.
///
/// POURQUOI (fiabilite des tests personas, cycle 3) : l'ecran carte affiche un
/// fond OSM via un [TileLayer] dont le fournisseur par defaut
/// ([NetworkTileProvider]) va chercher chaque tuile sur `tile.openstreetmap.org`.
/// Sur l'emulateur de test OFFLINE, chaque requete leve une `SocketException`
/// et le `RetryClient` interne re-essaie EN BOUCLE -> l'ordonnanceur de frames
/// ne se calme JAMAIS -> `flutter_test` part en timeout (S1) ou echoue au
/// teardown sur `!_expectingFrame` avec « Multiple exceptions » (S4).
///
/// [InertTileProvider] court-circuite tout reseau : `getImage` renvoie
/// SYNCHRONEMENT une image 1x1 entierement transparente
/// ([TileProvider.transparentImage]) — aucune requete HTTP, aucun retry, aucun
/// future pendant. La carte reste fonctionnelle (position, trace local, POIs,
/// interactions) ; seul le fond raster est vide, ce qui est sans importance
/// pour la validation QA.
///
/// PORTEE STRICTEMENT TEST : ce fournisseur n'est instancie que lorsque
/// [kInertMapTiles] est vrai — c.-a-d. sous un binding de test Flutter (detecte
/// au runtime, voir [_isRunningUnderFlutterTest]) ou via l'override de
/// compilation optionnel [_kForceInertMapTiles]. En production, [kInertMapTiles]
/// est FAUX, donc [inertTileProviderOrNull] renvoie `null` et les [TileLayer]
/// conservent leur fournisseur reseau habituel — ZERO changement en prod.
class InertTileProvider extends TileProvider {
  /// Cree un fournisseur inerte. Aucune ressource reseau n'est allouee.
  InertTileProvider();

  /// Image transparente 1x1 reutilisee pour toutes les tuiles (jamais visible).
  ///
  /// Reutilise l'octet-buffer fourni par flutter_map pour eviter toute
  /// allocation superflue.
  static final MemoryImage _transparentTile =
      MemoryImage(TileProvider.transparentImage);

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    // Retour synchrone : aucune I/O, aucun retry, aucun future pendant.
    return _transparentTile;
  }
}

/// Override de COMPILATION forcant les tuiles inertes (echappatoire optionnel).
///
/// Peut etre pose via `--dart-define=STEPWAYS_INERT_TILES=true` si l'on veut
/// forcer le mode inerte independamment de la detection de binding. ABSENT en
/// production -> `bool.fromEnvironment` vaut `false` : aucun effet hors demande
/// explicite. La detection automatique ci-dessous ([_isRunningUnderFlutterTest])
/// suffit deja pour les tests personas, sans aucun flag a passer.
const bool _kForceInertMapTiles =
    bool.fromEnvironment('STEPWAYS_INERT_TILES');

/// Vrai si le code s'execute SOUS un binding de test Flutter
/// (`flutter test` / `integration_test`), faux en production.
///
/// COMMENT : en test, `WidgetsBinding.instance` est un
/// `TestWidgetsFlutterBinding` (l'`integration_test` utilise plus precisement
/// un `LiveTestWidgetsFlutterBinding`). En production, c'est un
/// `WidgetsFlutterBinding` — JAMAIS un binding de test. On detecte donc le
/// contexte de test par le NOM de type runtime du binding, SANS importer le
/// paquet `flutter_test` dans le code de production (aucune dependance de test
/// tiree dans le bundle applicatif). Best-effort : si le binding n'est pas
/// encore initialise, on repond `false` (comportement prod par defaut).
bool _isRunningUnderFlutterTest() {
  try {
    final binding = SchedulerBinding.instance;
    final typeName = binding.runtimeType.toString();
    // Couvre IntegrationTestWidgetsFlutterBinding, LiveTestWidgetsFlutterBinding
    // et AutomatedTestWidgetsFlutterBinding — tous des bindings de test.
    return typeName.contains('TestWidgetsFlutterBinding');
  } catch (_) {
    return false;
  }
}

/// Vrai si le fond de carte doit etre INERTE (tuiles transparentes).
///
/// Actif automatiquement sous un binding de test, ou si l'override de
/// compilation [_kForceInertMapTiles] est pose. FAUX en production.
bool get kInertMapTiles =>
    _kForceInertMapTiles || _isRunningUnderFlutterTest();

/// Renvoie un [InertTileProvider] SI et seulement si [kInertMapTiles] est vrai
/// (contexte de test), sinon `null`.
///
/// A brancher sur le parametre `tileProvider:` des [TileLayer] OSM. Quand la
/// valeur est `null` (prod/defaut), [TileLayer] retombe sur son fournisseur par
/// defaut ([NetworkTileProvider]) — le comportement de production est preserve
/// a l'identique (cf. `TileLayer(... tileProvider: tileProvider ?? NetworkTileProvider())`).
TileProvider? inertTileProviderOrNull() =>
    kInertMapTiles ? InertTileProvider() : null;
