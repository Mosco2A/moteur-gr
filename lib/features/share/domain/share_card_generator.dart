import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Générateur de cartes de partage (1080x1080).
///
/// Crée une image carrée stylisée avec les données de trek
/// pour le partage sur les réseaux sociaux.
class ShareCardGenerator {
  /// Taille de la carte en pixels (1080x1080 pour Instagram)
  static const int cardSize = 1080;

  /// Génère les bytes PNG de la carte de partage
  static Future<Uint8List?> generateCard({
    required GlobalKey repaintKey,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// Données pour une carte de partage
class ShareCardData {
  const ShareCardData({
    required this.trailName,
    required this.stageName,
    required this.stageNumber,
    required this.distanceKm,
    required this.elevationGain,
    required this.date,
    this.customMessage,
  });

  final String trailName;
  final String stageName;
  final int stageNumber;
  final double distanceKm;
  final int elevationGain;
  final DateTime date;
  final String? customMessage;
}
