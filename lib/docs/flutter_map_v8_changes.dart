/// Documentation des breaking changes flutter_map v6 -> v8.
///
/// Ce fichier recense les modifications d'API a appliquer dans le moteur-gr
/// lors de la migration de flutter_map ^6.x vers ^8.2.0.
///
/// Reference: https://github.com/fleaflet/flutter_map/releases
library;

// -----------------------------------------------------------------------------
// 1. FlutterMap — nouveau parametre mapController
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   FlutterMap(
//     options: MapOptions(...),
//     mapController: _mapController,  // parametre nomme simple
//     children: [...]
//   )
//
// APRES (v8):
//   FlutterMap(
//     mapController: _mapController,  // toujours parametre nomme
//     options: MapOptions(...),       // options reste un parametre nomme
//     children: [...]
//   )
//
// Note: en v8, mapController est promu en parametre explicite du constructeur
// FlutterMap. L'ordre canonique est mapController, options, children.
// Le code existant dans trail_map_screen.dart utilise deja cette forme
// et n'a pas besoin de modification structurelle.

// -----------------------------------------------------------------------------
// 2. TileLayer.urlTemplate — desormais obligatoire (required)
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   TileLayer(
//     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',  // nullable
//   )
//
// APRES (v8):
//   TileLayer(
//     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',  // required
//   )
//
// Impact: le parametre urlTemplate etait nullable en v6, il est maintenant
// required. Si urlTemplate n'etait pas fourni, la compilation echouera.
// Dans notre code, urlTemplate est toujours fourni explicitement dans
// trail_map_screen.dart => pas de modification necessaire.

// -----------------------------------------------------------------------------
// 3. MarkerLayer.markers — ne peut plus etre null
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   MarkerLayer(markers: null)  // accepte
//   MarkerLayer()               // markers optionnel
//
// APRES (v8):
//   MarkerLayer(markers: [])    // doit etre une liste, jamais null
//
// Impact: toujours fournir une liste non-null a MarkerLayer.markers.
// Dans notre code, on passe toujours une liste construite via spread [...]
// => pas de modification necessaire.

// -----------------------------------------------------------------------------
// 4. MapController — dispose obligatoire dans StatefulWidget
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   Le dispose du MapController n'etait pas strictement necessaire.
//
// APRES (v8):
//   MapController implemente ChangeNotifier (ou similaire).
//   Il FAUT appeler _mapController.dispose() dans la methode dispose()
//   du State, sinon fuite memoire.
//
// Impact: dans trail_map_screen.dart, le dispose est deja fait :
//   @override
//   void dispose() {
//     _mapController.dispose();
//     super.dispose();
//   }
// => pas de modification necessaire.

// -----------------------------------------------------------------------------
// 5. MapOptions.onPositionChanged — signature modifiee
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   onPositionChanged: (MapPosition position, bool hasGesture) { ... }
//   position.zoom est nullable (double?)
//
// APRES (v8):
//   onPositionChanged: (MapCamera camera, bool hasGesture) { ... }
//   camera.zoom est un double non-nullable
//
// Impact: dans trail_map_screen.dart, le callback utilise position.zoom?.round()
// avec un fallback ?? _currentZoom. En v8, MapCamera.zoom n'est plus nullable,
// le ?. n'est plus necessaire mais reste fonctionnel (warning potentiel).
// A nettoyer en E0.3 lors de l'adaptation du code.

// -----------------------------------------------------------------------------
// 6. CameraFit.bounds — renomme depuis FitBounds
// -----------------------------------------------------------------------------
//
// AVANT (v6):
//   MapOptions(
//     bounds: LatLngBounds(...),
//     boundsOptions: FitBoundsOptions(padding: EdgeInsets.all(32)),
//   )
//
// APRES (v8):
//   MapOptions(
//     initialCameraFit: CameraFit.bounds(
//       bounds: bounds,
//       padding: EdgeInsets.all(32),
//     ),
//   )
//
// Impact: notre code utilise deja la syntaxe CameraFit.bounds => OK.

// -----------------------------------------------------------------------------
// Resume des actions pour le moteur-gr
// -----------------------------------------------------------------------------
//
// Fichiers impactes:
//   - pubspec.yaml: flutter_map ^6.1.0 -> ^8.2.0 (FAIT en E0.2)
//   - lib/features/map/presentation/trail_map_screen.dart: a adapter en E0.3
//     - onPositionChanged: retirer le ?. sur zoom (warning)
//   - lib/features/map/widgets/trail_polyline.dart: aucune modification
//
// Verification:
//   - flutter pub get (resolution des dependances)
//   - dart analyze (zero erreur / zero warning)
