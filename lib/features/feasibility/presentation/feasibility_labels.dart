/// Les libelles, couleurs, icones et formats du verdict de faisabilite,
/// partages par les widgets de l'ecran.
///
/// Bibliotheque de l'ecran `trek_feasibility_screen.dart` (lot 645-06b) :
/// ces aides etaient privees a une bibliotheque scindee en `part` ; plusieurs
/// fichiers de la feature les lisent, elles sont donc publiques ici, et la
/// facade de la feature ne les re-exporte pas.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../domain/feasibility_formula.dart';
import '../../../core/branding/stepways_icons.dart';

// --- Helpers de resolution enum -> i18n / couleur / icone -------------------

/// Formatte un km-energie : entier si rond, sinon une decimale.
String formatEnergyKm(double value) {
  if (!value.isFinite) return '—';
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toStringAsFixed(1);
}

/// Formatte un SCORE (sans unite) a deux decimales : a une seule, 1,04 et 1,10
/// s'afficheraient tous deux « 1,1 » alors qu'ils tombent de part et d'autre du
/// seuil rouge.
String formatTwoDecimals(double value) {
  if (!value.isFinite) return '—';
  return value.toStringAsFixed(2);
}

/// Libelle traduit d'un verdict tricolore.
String verdictLabel(FeasibilityVerdict verdict) {
  final v = t.feasibility.formula.verdicts;
  switch (verdict) {
    case FeasibilityVerdict.green:
      return v.green;
    case FeasibilityVerdict.orange:
      return v.orange;
    case FeasibilityVerdict.red:
      return v.red;
  }
}

/// Libelle traduit d'un niveau de randonneur.
String hikerLevelLabel(HikerLevel level) {
  final l = t.feasibility.formula.levels;
  switch (level) {
    case HikerLevel.beginner:
      return l.beginner;
    case HikerLevel.intermediate:
      return l.intermediate;
    case HikerLevel.confirmed:
      return l.confirmed;
    case HikerLevel.expert:
      return l.expert;
  }
}

/// Libelle traduit d'un facteur limitant.
String limitingFactorLabel(LimitingFactor factor) {
  final lf = t.feasibility.formula.limitingFactors;
  switch (factor) {
    case LimitingFactor.distance:
      return lf.distance;
    case LimitingFactor.elevation:
      return lf.elevation;
    case LimitingFactor.altitude:
      return lf.altitude;
    case LimitingFactor.heat:
      return lf.heat;
    case LimitingFactor.chaining:
      return lf.chaining;
    case LimitingFactor.none:
      return lf.none;
  }
}

/// Couleur du theme associee a un verdict tricolore.
Color verdictColor(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.red:
      return AppTheme.emergencyRed;
    case FeasibilityVerdict.orange:
      return AppTheme.orangeDifficile;
    case FeasibilityVerdict.green:
      return AppTheme.vertFacile;
  }
}

/// Icone StepWays associee a un verdict tricolore.
String verdictIcon(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.red:
      return StepwaysIcons.refuser;
    case FeasibilityVerdict.orange:
      return StepwaysIcons.danger;
    case FeasibilityVerdict.green:
      return StepwaysIcons.cochePleine;
  }
}
