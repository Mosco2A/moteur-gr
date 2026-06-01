import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../core/config/trail_config.dart';

/// Générateur de cartes de partage (1080x1080).
///
/// Crée une image carrée stylisée avec les statistiques du trek
/// et un branding dynamique basé sur la configuration du sentier.
/// Aucune référence en dur à un sentier — tout vient de [TrailConfig].
class ShareCardGenerator {
  /// Taille de la carte en pixels (1080x1080 pour Instagram/réseaux sociaux)
  static const int cardSize = 1080;

  /// Ratio de pixels pour la capture (qualité retina)
  static const double pixelRatio = 3.0;

  /// Génère les bytes PNG de la carte de partage
  /// depuis un RepaintBoundary capturé via [repaintKey].
  static Future<Uint8List?> generateCard({
    required GlobalKey repaintKey,
  }) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Extrait le branding dynamique depuis la config sentier.
  /// Aucune couleur ou logo en dur — tout vient de [TrailConfig].
  static ShareCardBranding brandingFromConfig(TrailConfig config) {
    return ShareCardBranding(
      primaryColor: Color(config.primaryColorValue),
      secondaryColor: Color(config.secondaryColorValue),
      trailName: config.displayName,
      region: config.region,
    );
  }
}

/// Branding dynamique extrait de [TrailConfig].
///
/// Permet de personnaliser l'apparence de la carte
/// sans référence en dur à un sentier spécifique.
class ShareCardBranding {
  const ShareCardBranding({
    required this.primaryColor,
    required this.secondaryColor,
    required this.trailName,
    required this.region,
    this.logoAssetPath,
  });

  /// Couleur primaire du gradient de fond
  final Color primaryColor;

  /// Couleur secondaire du gradient de fond
  final Color secondaryColor;

  /// Nom d'affichage du sentier (depuis TrailConfig.displayName)
  final String trailName;

  /// Région géographique du sentier
  final String region;

  /// Chemin optionnel vers le logo du sentier dans les assets
  final String? logoAssetPath;

  /// Génère les couleurs du gradient pour le fond de la carte
  List<Color> get gradientColors => [
        primaryColor,
        secondaryColor.withAlpha(200),
      ];
}

/// Données pour une carte de partage.
///
/// Contient les statistiques du trek à afficher
/// sur la carte de partage 1080x1080.
class ShareCardData {
  const ShareCardData({
    required this.trailName,
    required this.distanceKm,
    required this.elevationGain,
    required this.date,
    this.stageName,
    this.stageNumber,
    this.mapSnapshotBytes,
    this.customMessage,
  });

  /// Nom d'affichage du sentier
  final String trailName;

  /// Distance parcourue en kilomètres
  final double distanceKm;

  /// Dénivelé positif total en mètres
  final int elevationGain;

  /// Date du trek
  final DateTime date;

  /// Nom de l'étape (optionnel — pour partage d'une étape spécifique)
  final String? stageName;

  /// Numéro de l'étape (optionnel)
  final int? stageNumber;

  /// Bytes PNG d'une carte miniature (optionnel)
  final Uint8List? mapSnapshotBytes;

  /// Message personnalisé ajouté par l'utilisateur
  final String? customMessage;

  /// Indique si la carte concerne une étape spécifique
  bool get hasStageInfo => stageName != null && stageNumber != null;
}
