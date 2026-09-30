import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider (filtre de type) : Riverpod 3.x le fournit via legacy.dart
// (meme convention que les autres StateProvider du projet, ex. stage_providers).
import 'package:flutter_riverpod/legacy.dart';

import '../domain/shop_catalog.dart';
import '../domain/shop_info.dart';
import 'lieux_en_base_provider.dart';

/// Filtre de TYPE de commerce (parite GR20 `shopTypeFilterProvider`).
///
/// `null` = « Tous » (aucun filtre). Selectionner un [ShopKind] restreint la
/// liste a ce type ; re-taper la meme puce revient a « Tous » (parite GR20 :
/// toggle). StateProvider (etat UI simple, pas de persistance).
final shopTypeFilterProvider = StateProvider<ShopKind?>((ref) => null);

/// Donnees RAVITAILLEMENT du sentier [trailId] — LA BASE D'ABORD (tache 641).
///
/// CE QUI ETAIT CASSE, ET C'EST LE BUG 13 PUIS LE BUG 17. Ce provider ne lisait
/// que [ShopCatalog], une constante Dart derriere un `switch (trailId)`. Tout
/// sentier autre que `mare-a-mare-centre` obtenait `null`, et `ShopScreen` rend
/// alors un `SizedBox.shrink()` : un ECRAN BLANC sous le titre « Ravitaillement »,
/// sans le moindre message. C'est ce que Christophe a vu, d'abord en demo — dont
/// l'identifiant de sentier est different — puis en reel.
///
/// LA BASE GAGNE MAINTENANT, ET C'EST LA REGLE DE CHRISTOPHE DU 29/09 : « tout en
/// base, seule la copie sur le tel ; JE NE VEUX PAS QUE CE SOIT EN DUR MAIS DANS
/// LA BASE ». Les commerces sont publies dans `trails/{id}/pois` avec un type
/// prefixe `shop_`, descendus par la synchronisation, et lus ici.
///
/// LE CATALOGUE COMPILE RESTE EN DERNIER RECOURS, pas par prudence mais par
/// honnetete : tant qu'un sentier n'est pas publie en base, son ancien contenu
/// vaut mieux qu'un ecran vide. Il disparaitra quand tous les sentiers seront
/// publies.
final trailShopsProvider =
    Provider.family<TrailShops?, String>((ref, trailId) {
  return ref.watch(ravitaillementEnBaseProvider(trailId)) ??
      ShopCatalog.forTrail(trailId);
});
