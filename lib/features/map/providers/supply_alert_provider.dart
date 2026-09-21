import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../planning/providers/shop_providers.dart';
import 'track_position_provider.dart';

/// Alerte « ravitaillement » calculee pour l'etape ou se trouve le randonneur
/// (correctif L6-1).
///
/// Porte les deux seules informations dont le bandeau de la carte a besoin :
/// l'etape qui declenche l'alerte (c'est elle qui rearme la minuterie quand
/// elle change) et l'ecart, en nombre d'etapes, jusqu'au prochain commerce.
class SupplyGapAlert {
  const SupplyGapAlert({required this.stageNumber, required this.gap});

  /// Etape courante detectee sur le trace au moment du declenchement.
  final int stageNumber;

  /// Nombre d'etapes a marcher avant le prochain point de ravitaillement.
  final int gap;

  @override
  bool operator ==(Object other) =>
      other is SupplyGapAlert &&
      other.stageNumber == stageNumber &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(stageNumber, gap);
}

/// Alerte de ravitaillement a montrer sur la carte, `null` quand il n'y a
/// rien a signaler (correctif L6-1).
///
/// BRANCHEMENT, PAS CONSTRUCTION : toute la logique metier existait deja et
/// n'etait cablee que sur l'ecran « Ravitaillement ».
///  - [TrailShops.gapAfter] / [TrailShops.isGapAlert] calculent l'ecart et le
///    comparent au seuil du sentier (defaut 2) ;
///  - [trailShopsProvider] fournit le catalogue embarque du sentier ;
///  - [trackPositionProvider] fournit deja l'etape courante projetee sur le
///    trace, c'est la meme source que la barre d'etape de la carte.
///
/// REGLE DE DECLENCHEMENT, alignee sur la reference : RIEN tant que l'ecart
/// ne DEPASSE pas le seuil du sentier. Un ecart de une ou deux etapes est la
/// normale d'un sentier desservi, alerter dessus rendrait l'alerte invisible
/// le jour ou elle compte. Le seuil vit dans la donnee du sentier
/// ([TrailShops.gapThreshold]) : un sentier isole peut l'abaisser.
///
/// Rien non plus hors trace detectee (`stageNumber <= 0`) ni sur un sentier
/// sans donnee de ravitaillement : l'alerte ne s'invente pas.
final supplyGapAlertProvider = Provider<SupplyGapAlert?>((ref) {
  final trailId = ref.watch(trailIdProvider);
  final shops = ref.watch(trailShopsProvider(trailId));
  if (shops == null || !shops.hasShops) return null;

  final stageNumber = ref.watch(
    trackPositionProvider.select(
      (async) => async.value?.stageDetection.stageNumber ?? 0,
    ),
  );
  if (stageNumber <= 0) return null;
  if (!shops.isGapAlert(stageNumber)) return null;

  return SupplyGapAlert(
    stageNumber: stageNumber,
    gap: shops.gapAfter(stageNumber),
  );
});
