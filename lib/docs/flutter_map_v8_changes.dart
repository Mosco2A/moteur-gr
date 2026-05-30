// ignore_for_file: unused_element

/// Documentation des breaking changes flutter_map v6 -> v8.
///
/// 4 breaking changes identifies et documentes pour la migration
/// du Moteur GR depuis flutter_map ^6.1.0 vers ^8.2.0.
///
/// Reference: https://docs.fleaflet.dev/migration
library flutter_map_v8_changes;

// ---------------------------------------------------------------------------
// BREAKING CHANGE 1 : MapOptions.center/zoom -> initialCenter/initialZoom
// ---------------------------------------------------------------------------
//
// AVANT (flutter_map 6.x):
//
//   FlutterMap(
//     options: MapOptions(
//       center: LatLng(42.0, 9.0),
//       zoom: 10.0,
//     ),
//   );
//
// APRES (flutter_map 8.x):
//
//   FlutterMap(
//     options: MapOptions(
//       initialCenter: LatLng(42.0, 9.0),
//       initialZoom: 10.0,
//     ),
//   );
//
// NOTES:
//   - `center` renomme en `initialCenter`.
//   - `zoom` renomme en `initialZoom`.
//   - S'applique aussi a `rotation` -> `initialRotation`.
//   - Le Moteur GR utilise `initialCameraFit` (bounds) qui reste inchange.

// ---------------------------------------------------------------------------
// BREAKING CHANGE 2 : onPositionChanged callback signature
// ---------------------------------------------------------------------------
//
// AVANT (flutter_map 6.x):
//
//   MapOptions(
//     onPositionChanged: (MapPosition position, bool hasGesture) {
//       final zoom = position.zoom;
//       final center = position.center;
//     },
//   );
//
// APRES (flutter_map 8.x):
//
//   MapOptions(
//     onPositionChanged: (MapCamera camera, bool hasGesture) {
//       final zoom = camera.zoom;        // double (plus nullable)
//       final center = camera.center;    // LatLng (plus nullable)
//     },
//   );
//
// NOTES:
//   - `MapPosition` remplace par `MapCamera`.
//   - `position.zoom` etait `double?`, `camera.zoom` est `double`.
//   - Plus besoin de `position.zoom ?? defaultZoom`.
//   - Impact Moteur GR: trail_map_screen.dart, suppression du `?` et du `??`.

// ---------------------------------------------------------------------------
// BREAKING CHANGE 3 : TileLayer.urlTemplate parametres nommes
// ---------------------------------------------------------------------------
//
// AVANT (flutter_map 6.x):
//
//   TileLayer(
//     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//     userAgentPackageName: 'com.moteur-gr.app',
//   );
//
// APRES (flutter_map 8.x):
//
//   TileLayer(
//     urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
//     userAgentPackageName: 'com.moteur-gr.app',
//   );
//
// NOTES:
//   - L'API TileLayer reste compatible pour notre usage.
//   - Le parametre `tileProvider` accepte toujours NetworkTileProvider.
//   - `subdomains` est deprecie en faveur de `{s}` dans l'URL template.
//   - Le Moteur GR n'utilise pas `subdomains` donc pas d'impact.

// ---------------------------------------------------------------------------
// BREAKING CHANGE 4 : Polyline strokeCap / strokeJoin
// ---------------------------------------------------------------------------
//
// AVANT (flutter_map 6.x):
//
//   Polyline(
//     points: points,
//     color: Colors.blue,
//     strokeWidth: 4.0,
//     strokeCap: StrokeCap.round,
//     strokeJoin: StrokeJoin.round,
//   );
//
// APRES (flutter_map 8.x):
//
//   Polyline(
//     points: points,
//     color: Colors.blue,
//     strokeWidth: 4.0,
//     // strokeCap et strokeJoin sont par defaut round en v8
//     // Ils peuvent etre passes mais la valeur par defaut a change
//   );
//
// NOTES:
//   - Les valeurs par defaut de strokeCap/strokeJoin sont desormais
//     `StrokeCap.round` et `StrokeJoin.round` en v8 (etaient .butt/.miter).
//   - Le Moteur GR les specifie explicitement, donc pas de changement
//     de comportement visuel.
//   - La classe Polyline est dans le meme package, pas de renommage.
