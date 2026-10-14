/// L'ecart jusqu'au prochain ravitaillement — en nombre d'etapes ET en
/// kilometres — pour la nourriture comme pour l'eau, et l'etape qui declenche
/// l'alerte, celle dont le changement la rearme.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/models/poi.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/models/water_action.dart';
import '../../planning/planning_facade.dart' show trailShopsProvider;
import '../../trail/trail_facade.dart' show poisProvider, stagesProvider;
import 'track_position_provider.dart';

/// CE QUI MANQUE AU MARCHEUR : de l'eau, ou des vivres (tache 834).
///
/// Les deux trous ne se valent pas et ne portent donc pas le meme seuil ni le
/// meme texte. L'eau passe devant : on marche trois jours sur ses reserves de
/// nourriture, on ne marche pas deux jours sans boire.
enum SupplyGapKind {
  /// Plus d'epicerie avant plusieurs etapes.
  food,

  /// Plus de point d'eau avant plusieurs etapes.
  water,
}

/// Alerte « ravitaillement » calculee pour l'etape ou se trouve le randonneur
/// (correctif L6-1, etendue a l'eau et a la portee par la tache 834).
///
/// Porte ce que le bandeau de la carte doit dire, et rien de plus : l'etape qui
/// declenche l'alerte (c'est elle qui rearme la minuterie quand elle change),
/// le SUJET du manque, et la TAILLE du trou — en etapes et en kilometres.
class SupplyGapAlert {
  /// Une alerte pour une etape, un sujet, et une taille de trou.
  const SupplyGapAlert({
    required this.stageNumber,
    required this.gap,
    this.kind = SupplyGapKind.food,
    this.km,
    this.waterAction,
  });

  /// Etape courante detectee sur le trace au moment du declenchement.
  final int stageNumber;

  /// Nombre d'etapes a marcher avant le prochain point de ravitaillement.
  final int gap;

  /// Ce qui manque : des vivres, ou de l'eau.
  final SupplyGapKind kind;

  /// PORTEE DU TROU EN KILOMETRES, ou `null` quand on ne la connait pas.
  ///
  /// POURQUOI UN NOMBRE D'ETAPES NE SUFFIT PAS. Une etape de ce sentier mesure
  /// de 8,1 a 19,9 km : « avant 5 etapes » peut vouloir dire 40 km comme 90.
  /// « Dernier ravitaillement avant 5 etapes et 52,5 km » fait charger deux
  /// kilos de plus ; « attention ravitaillement » ne fait rien.
  ///
  /// NULLABLE PARCE QU'ON NE DEVINE PAS. Quand les distances d'etape ne sont
  /// pas chargees, ou qu'une etape du trou n'en declare pas, ce champ reste
  /// `null` et le bandeau retombe sur son ancien libelle — celui qui ne parle
  /// qu'en etapes. Un zero affiche serait un mensonge, et l'honnetete des
  /// donnees vaut aussi pour les alertes (#99460).
  final double? km;

  /// LE GESTE QUI ATTEND AU BOUT DU TROU, ou `null` hors alerte d'eau.
  ///
  /// POURQUOI L'ALERTE DOIT LE PORTER (tache 846). Un point filtrable COMPTE
  /// comme de l'eau — avec un filtre au sac, il se boit — mais le compter sans
  /// le dire serait mentir par omission : le marcheur qui lit « prochain point
  /// d'eau dans deux etapes » et arrive devant un ruisseau sans filtre a ete
  /// trompe par une alerte exacte. Elle dit donc les deux : la distance ET le
  /// geste.
  ///
  /// C'est le MEILLEUR geste de l'etape d'arrivee, celui des points qui
  /// donnent de l'eau ([WaterAction.meilleur]) : une etape qui porte une
  /// fontaine et un ruisseau s'annonce a la fontaine.
  final WaterAction? waterAction;

  @override
  bool operator ==(Object other) =>
      other is SupplyGapAlert &&
      other.stageNumber == stageNumber &&
      other.gap == gap &&
      other.kind == kind &&
      other.km == km &&
      other.waterAction == waterAction;

  @override
  int get hashCode => Object.hash(stageNumber, gap, kind, km, waterAction);
}

/// LES TYPES DE POI QUI COMPTENT COMME UN POINT D'EAU.
///
/// Un seul aujourd'hui, et c'est le type que la donnee du sentier emploie pour
/// ses fontaines et ses sources (`assets/data/<sentier>/pois.json`). Declare en
/// ensemble nomme plutot qu'en litteral disperse : le jour ou un sentier
/// distingue l'eau potable de l'eau de baignade, c'est ICI que la liste
/// s'allonge, en un seul endroit.
///
/// LA LIMITE QUE CETTE LISTE PORTAIT EST LEVEE DEPUIS LA TACHE 846 : le type
/// `water` ne disait pas la potabilite, et une source thermale sulfureuse
/// comptait donc comme de l'eau. Ce n'est plus le type qui decide, c'est le
/// GESTE a faire ([PoiModel.waterAction]) — le type ne dit plus que « il y a
/// de l'eau ici », ce qui est tout ce qu'on lui demande.
const _waterPoiTypes = <String>{'water'};

/// LE GESTE A FAIRE, ETAPE PAR ETAPE — et une etape sans eau UTILISABLE n'y
/// figure pas du tout.
///
/// DEUX DECISIONS DE LA TACHE 846 TIENNENT DANS CETTE FONCTION.
///
/// UN POINT « NE PAS BOIRE » NE COMPTE JAMAIS, MEME AVEC UN FILTRE AU SAC.
/// [WaterAction.meilleur] les ecarte avant de choisir : une etape qui ne porte
/// que de l'eau thermale sort de la carte des etapes servies, et l'alerte
/// compte le trou par-dessus elle. C'est le cas que la donnee d'hier ratait.
///
/// UNE ETAPE S'ANNONCE A SON MEILLEUR POINT. L'etape 3 du Mare a Mare Centre
/// porte la source thermale de Guitera (qui ne se boit pas) et la Funtana di
/// Croce (muette, donc a filtrer par precaution) : ce qui attend le marcheur
/// la-bas, c'est « a filtrer », pas « rien » et pas « buvable ».
Map<int, WaterAction> _gestesParEtape(List<PoiModel>? pois) {
  if (pois == null) return const <int, WaterAction>{};
  final parEtape = <int, List<WaterAction>>{};
  for (final p in pois) {
    if (!_waterPoiTypes.contains(p.type)) continue;
    (parEtape[p.stageNumber] ??= <WaterAction>[]).add(p.waterAction);
  }
  return <int, WaterAction>{
    for (final etape in parEtape.entries)
      if (WaterAction.meilleur(etape.value) case final geste?) etape.key: geste,
  };
}

/// Kilometres a marcher depuis [from] (exclue) jusqu'a [to] (incluse).
///
/// Rend `null` des qu'une etape du trou ne declare pas sa distance : mieux vaut
/// taire la portee que l'arrondir a un chiffre faux.
double? _kmBetween(List<StageModel>? stages, int from, int to) {
  if (stages == null || stages.isEmpty || to <= from) return null;
  final byNumber = <int, double>{
    for (final s in stages) s.stageNumber: s.distanceKm,
  };
  var total = 0.0;
  for (var n = from + 1; n <= to; n++) {
    final d = byNumber[n];
    if (d == null) return null;
    total += d;
  }
  return total;
}

/// Alerte de ravitaillement a montrer sur la carte, `null` quand il n'y a
/// rien a signaler (correctif L6-1, tache 834).
///
/// CE QU'ELLE LIT :
///  - [trailShopsProvider] fournit le catalogue embarque du sentier, et avec
///    lui les DEUX seuils (nourriture et eau) ;
///  - [poisProvider] fournit les points d'eau du sentier, ceux-la memes qui
///    s'affichent sur la carte ;
///  - [stagesProvider] fournit les distances d'etape, d'ou la portee en
///    kilometres ;
///  - [trackPositionProvider] fournit l'etape courante projetee sur le trace,
///    c'est la meme source que la barre d'etape de la carte.
///
/// CE QUE LA TACHE 834 A CORRIGE, ET C'ETAIT UN SILENCE, PAS UN BRUIT.
/// L'alerte comparait l'ecart jusqu'a la prochaine ETAPE PORTANT UNE ENTREE de
/// catalogue. Sur le Mare a Mare Centre, les sept etapes en portent une — les
/// villages du milieu ont un bar, et les villages sans commerce portent une
/// entree qui le CONSTATE — donc l'ecart valait 1 partout et l'alerte ne s'est
/// jamais declenchee, pas une fois, sur le seul trou qui compte : cinq etapes
/// et 52,5 km sans une epicerie entre Cozzano et Porticcio. Elle lit desormais
/// [TrailShops.resupplyStages], qui ne retient que les entrees declarant
/// [Shop.providesResupply].
///
/// REGLE DE DECLENCHEMENT : RIEN tant que l'ecart ne DEPASSE pas le seuil du
/// sentier. Un ecart de une ou deux etapes est la normale d'un sentier
/// desservi ; alerter dessus rendrait l'alerte invisible le jour ou elle
/// compte. Les seuils vivent dans la donnee ([TrailShops.gapThreshold] pour les
/// vivres, [TrailShops.waterGapThreshold] pour l'eau, plus severe).
///
/// L'EAU PASSE DEVANT, ET UNE SEULE ALERTE A LA FOIS. Les deux trous peuvent
/// s'ouvrir sur la meme etape (c'est le cas de l'etape 4 de ce sentier). Le
/// bandeau s'affiche au-dessus d'une carte en cours de marche, ou la place est
/// comptee et ou le bouton SOS ne doit rien recouvrir : on empile donc les
/// sujets dans le TEMPS, pas dans l'espace. L'eau gagne parce que c'est elle
/// qui envoie les secours — et le trou de vivres, lui, a deja parle aux etapes
/// precedentes, ou l'eau ne manquait pas.
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

  // Les distances d'etape, pour dire la portee du trou. Absentes, l'alerte
  // parle encore — en etapes seulement.
  final stages = ref.watch(
    stagesProvider(trailId).select((async) => async.value),
  );

  // L'EAU D'ABORD.
  final gestesParEtape = _gestesParEtape(
    ref.watch(poisProvider(trailId).select((async) => async.value)),
  );
  final waterStages = gestesParEtape.keys;
  if (shops.isWaterGapAlert(stageNumber, waterStages)) {
    final gap = shops.waterGapAfter(stageNumber, waterStages);
    return SupplyGapAlert(
      stageNumber: stageNumber,
      gap: gap,
      kind: SupplyGapKind.water,
      km: _kmBetween(stages, stageNumber, stageNumber + gap),
      // LE GESTE QUI ATTEND AU BOUT DU TROU. L'ecart vaut `gap` etapes, donc
      // l'eau retrouvee est a l'etape `stageNumber + gap` : c'est la MEME
      // etape que celle qui a ferme le calcul de l'ecart, relue dans la meme
      // carte, et non une seconde recherche qui pourrait en designer une autre.
      waterAction: gestesParEtape[stageNumber + gap],
    );
  }

  // PUIS LES VIVRES.
  if (shops.isResupplyGapAlert(stageNumber)) {
    final gap = shops.resupplyGapAfter(stageNumber);
    return SupplyGapAlert(
      stageNumber: stageNumber,
      gap: gap,
      km: _kmBetween(stages, stageNumber, stageNumber + gap),
    );
  }

  return null;
});
