/// Un point d'interet immutable, dont le TYPE est un String extensible : c'est
/// PoiTypeConfig qui lui donne son icone et sa couleur.
library;

import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/database.dart';
import 'water_action.dart';

part 'poi.freezed.dart';
part 'poi.g.dart';

/// Modele immutable representant un point d'interet.
///
/// Le type est un String extensible (ex: 'water', 'refuge', 'danger').
/// Utiliser PoiTypeConfig.getStyle(type) pour obtenir icone/couleur.
/// Convertible depuis/vers la table Drift Pois et depuis JSON.
@freezed
abstract class PoiModel with _$PoiModel {
  const PoiModel._();

  const factory PoiModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du sentier parent
    required String trailId,

    /// Numero de l'etape associee
    required int stageNumber,

    /// Nom du POI
    required String name,

    /// Description
    @Default('') String description,

    /// Type de POI (String extensible, ex: water, refuge, danger)
    required String type,

    /// Latitude
    required double lat,

    /// Longitude
    required double lng,

    /// Altitude en metres
    @Default(0) int altitudeM,

    /// Horaires d'ouverture (nullable)
    String? openingHours,

    /// LE GESTE A FAIRE AVANT DE BOIRE, TEL QUE LA DONNEE LE DECLARE.
    ///
    /// `null` QUAND LA DONNEE N'EN DIT RIEN, et c'est le point entier de ce
    /// champ : il ne porte que du releve. Le geste a montrer au marcheur se lit
    /// sur [waterAction], qui applique le repli de prudence ; et
    /// [waterActionIsPrecaution] dit lequel des deux on vient de lire.
    ///
    /// N'a de sens que sur un point d'eau (les types de `PoiTypeConfig`
    /// `waterTypes`).
    ///
    /// AUCUNE ANNOTATION ICI, ET C'EST VOLONTAIRE. La donnee du sentier ecrit
    /// ce geste sous la cle `waterAction`, en `snake_case`
    /// ([WaterAction.versDonnee]), et c'est le SEMEUR qui la lit — lui seul,
    /// explicitement, via [WaterAction.depuisDonnee]. [PoiModel.fromJson]
    /// n'est PAS le chemin de la donnee embarquee : lui coller un `@JsonKey`
    /// pour faire coincider les deux orthographes n'aurait servi personne, et
    /// une annotation sur un parametre de fabrique freezed n'est de toute
    /// facon pas a sa place.
    WaterAction? declaredWaterAction,
  }) = _PoiModel;

  /// LE GESTE A FAIRE AVANT DE BOIRE ICI.
  ///
  /// Le releve quand la donnee l'a dit, sinon FILTRER par prudence
  /// ([WaterAction.parPrudence]). C'est ce getter que lisent l'alerte d'eau,
  /// le sac et la carte : le repli n'est ecrit qu'une fois, et nulle part
  /// ailleurs.
  ///
  /// N'a de sens que sur un point d'eau : sur un refuge, il rendrait
  /// « filtrer » sans que personne le lui demande, et les trois lecteurs
  /// filtrent d'abord sur le type.
  WaterAction get waterAction => declaredWaterAction ?? WaterAction.parPrudence;

  /// Vrai quand [waterAction] est une PRECAUTION et non un releve.
  ///
  /// La fiche du point l'ecrit noir sur blanc : un marcheur a le droit de
  /// savoir qu'on lui demande de filtrer parce qu'on ne sait pas, et non parce
  /// qu'on a mesure.
  bool get waterActionIsPrecaution => declaredWaterAction == null;

  /// Construit depuis une ligne Drift (table Poi)
  factory PoiModel.fromDb(Poi row) {
    return PoiModel(
      id: row.id,
      trailId: row.trailId,
      stageNumber: row.stageNumber,
      name: row.name,
      description: row.description,
      type: row.type,
      lat: row.lat,
      lng: row.lng,
      altitudeM: row.altitudeM,
      openingHours: row.openingHours,
      declaredWaterAction: WaterAction.depuisDonnee(row.waterAction),
    );
  }

  /// Convertit vers un companion Drift pour insertion
  PoisCompanion toCompanion() {
    return PoisCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      name: Value(name),
      description: Value(description),
      type: Value(type),
      lat: Value(lat),
      lng: Value(lng),
      altitudeM: Value(altitudeM),
      openingHours: Value(openingHours),
      waterAction: Value(declaredWaterAction?.versDonnee),
    );
  }

  /// Deserialisation depuis JSON
  factory PoiModel.fromJson(Map<String, dynamic> json) =>
      _$PoiModelFromJson(json);
}
