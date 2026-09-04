import 'package:flutter/material.dart';

import '../../../../i18n/translations.g.dart';

/// Type de nuitee choisi par nuit (PARITE GR20 `NuiteeType`).
///
/// 4 choix simples, clone strict de l'ecran GR20 « Reserver vos nuits » :
/// refuge / gite / bivouac / autre hebergement. Chaque type a une icone et un
/// libelle i18n dedie (5 langues via Slang). Generique multi-sentiers : aucune
/// donnee de localite, seul le libelle du TYPE est traduit.
enum NuiteeType { refuge, gite, bivouac, autreHebergement }

/// Libelles i18n + icones des types de nuitee (parite GR20).
extension NuiteeTypeUi on NuiteeType {
  /// Libelle traduit du type (Slang, 5 langues).
  String get label {
    final n = t.nuitees.types;
    switch (this) {
      case NuiteeType.refuge:
        return n.refuge;
      case NuiteeType.gite:
        return n.gite;
      case NuiteeType.bivouac:
        return n.bivouac;
      case NuiteeType.autreHebergement:
        return n.autreHebergement;
    }
  }

  /// Icone du type (parite GR20 : cabin / house / terrain / other_houses).
  IconData get icon {
    switch (this) {
      case NuiteeType.refuge:
        return Icons.cabin;
      case NuiteeType.gite:
        return Icons.house;
      case NuiteeType.bivouac:
        return Icons.terrain;
      case NuiteeType.autreHebergement:
        return Icons.other_houses;
    }
  }

  /// Cle de persistance stable (nom de l'enum). Sert en DB.
  String get storageKey => name;

  /// Reconstruit un [NuiteeType] depuis sa cle de persistance.
  /// Repli sur [NuiteeType.refuge] pour une valeur inconnue (tolerance).
  static NuiteeType fromStorage(String? key) {
    return NuiteeType.values.firstWhere(
      (t) => t.name == key,
      orElse: () => NuiteeType.refuge,
    );
  }
}
