import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Calcul de contraste WCAG 2.x (E5.3a — audit accessibilite).
///
/// Implemente la luminance relative et le ratio de contraste de la
/// recommandation WCAG, plus les seuils de conformite :
/// - texte normal  : AA >= 4.5:1 ([meetsAA]) ;
/// - grand texte    : AA >= 3.0:1 ([meetsAALargeText]) ;
/// - elements non textuels (UI, icones porteuses de sens) : >= 3.0:1
///   ([meetsNonText], WCAG 1.4.11).
///
/// Sert d'outil d'audit (tests) et peut etre utilise a l'execution pour
/// choisir une couleur de texte lisible sur un fond donne.
abstract final class WcagContrast {
  /// Luminance relative WCAG d'une couleur (0.0 = noir, 1.0 = blanc).
  static double relativeLuminance(Color color) {
    final argb = color.toARGB32();
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;

    double linear(int channel) {
      final c = channel / 255.0;
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b);
  }

  /// Ratio de contraste entre deux couleurs (de 1.0 a 21.0).
  ///
  /// Symetrique : l'ordre des arguments n'a pas d'importance.
  static double ratio(Color a, Color b) {
    final la = relativeLuminance(a);
    final lb = relativeLuminance(b);
    final lighter = math.max(la, lb);
    final darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Conformite AA pour du texte normal (>= 4.5:1).
  static bool meetsAA(Color foreground, Color background) =>
      ratio(foreground, background) >= 4.5;

  /// Conformite AA pour du grand texte (>= 3.0:1).
  static bool meetsAALargeText(Color foreground, Color background) =>
      ratio(foreground, background) >= 3.0;

  /// Conformite des elements non textuels / UI (>= 3.0:1, WCAG 1.4.11).
  static bool meetsNonText(Color foreground, Color background) =>
      ratio(foreground, background) >= 3.0;
}
