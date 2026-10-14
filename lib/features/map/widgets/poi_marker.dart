/// La pastille d'un point sur la carte : couleur et icone viennent du registre
/// des types, jamais du code de la carte.
library;

import 'package:flutter/material.dart';

import '../../../shared/poi/poi_type_config.dart';
import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/water_action.dart';
import '../../../core/theme/couleurs_semantiques.dart';

/// Widget marqueur personnalise pour un point d'interet sur la carte.
///
/// Affiche un cercle colore avec une icone blanche au centre.
/// Chaque type de POI a sa propre couleur et icone via PoiTypeConfig.
class PoiMarker extends StatelessWidget {
  const PoiMarker({
    super.key,
    required this.type,
    this.size = 36,
    this.waterAction,
  });

  /// Type du POI (String extensible)
  final String type;

  /// Taille totale du marqueur en pixels
  final double size;

  /// LE GESTE A FAIRE, sur un point d'eau (tache 846).
  ///
  /// Facultatif, et ignore hors point d'eau : c'est [PoiTypeConfig] qui
  /// tranche. Absent, un point d'eau garde le dessin de la fontaine.
  final WaterAction? waterAction;

  /// Retourne l'icone associee au type de POI, et au geste s'il est connu.
  static String iconFor(String type, {WaterAction? waterAction}) {
    return PoiTypeConfig.getStyle(type, waterAction: waterAction).icon;
  }

  /// Retourne la couleur associee au type de POI, et au geste s'il est connu.
  static Color colorFor(String type, {WaterAction? waterAction}) {
    return PoiTypeConfig.getStyle(type, waterAction: waterAction).color;
  }

  @override
  Widget build(BuildContext context) {
    final style = PoiTypeConfig.getStyle(type, waterAction: waterAction);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: style.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(
            color: CouleursSemantiques.ombrePorteeDuMarqueur,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: StepIcon(style.icon, color: Colors.white, size: size * 0.5),
    );
  }
}
