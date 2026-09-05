import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider (filtre de type) : Riverpod 3.x le fournit via legacy.dart
// (meme convention que les autres StateProvider du projet, ex. stage_providers).
import 'package:flutter_riverpod/legacy.dart';

import '../domain/shop_catalog.dart';
import '../domain/shop_info.dart';

/// Filtre de TYPE de commerce (parite GR20 `shopTypeFilterProvider`).
///
/// `null` = « Tous » (aucun filtre). Selectionner un [ShopKind] restreint la
/// liste a ce type ; re-taper la meme puce revient a « Tous » (parite GR20 :
/// toggle). StateProvider (etat UI simple, pas de persistance).
final shopTypeFilterProvider = StateProvider<ShopKind?>((ref) => null);

/// Donnees RAVITAILLEMENT du sentier [trailId] (catalogue embarque, offline).
///
/// Simple lecture du [ShopCatalog] (data-driven, genericite #84627). Retourne
/// `null` si le sentier ne fournit pas de donnees ravitaillement -> l'ecran
/// affiche un fallback informatif propre (pas de crash). Family par `trailId`
/// (coherent avec [stagesProvider] et le scope multi-sentiers, isolation par
/// sentier). Le backend (Phase 4) remplacera la source du catalogue.
final trailShopsProvider =
    Provider.family<TrailShops?, String>((ref, trailId) {
  return ShopCatalog.forTrail(trailId);
});
