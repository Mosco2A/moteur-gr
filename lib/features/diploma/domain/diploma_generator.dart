import 'package:intl/intl.dart';

/// Générateur de diplôme PDF de fin de trek.
///
/// Crée un PDF A4 paysage avec le nom du randonneur,
/// le sentier complété, la date et les statistiques.
/// Utilise une mise en page élégante partageable.
class DiplomaGenerator {
  /// Génère les bytes du PDF diplôme
  ///
  /// Note: l'implémentation complète nécessite le package pdf.
  /// Cette version retourne les données structurées pour le PDF.
  static DiplomaData createDiploma({
    required String hikerName,
    required String trailName,
    required String trailRegion,
    required int totalStages,
    required double totalDistanceKm,
    required int totalElevationGain,
    required DateTime completionDate,
    required int durationDays,
  }) {
    return DiplomaData(
      hikerName: hikerName,
      trailName: trailName,
      trailRegion: trailRegion,
      totalStages: totalStages,
      totalDistanceKm: totalDistanceKm,
      totalElevationGain: totalElevationGain,
      completionDate: completionDate,
      durationDays: durationDays,
      formattedDate:
          DateFormat('d MMMM yyyy', 'fr_FR').format(completionDate),
    );
  }
}

/// Données structurées pour le diplôme
class DiplomaData {
  const DiplomaData({
    required this.hikerName,
    required this.trailName,
    required this.trailRegion,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
    required this.completionDate,
    required this.durationDays,
    required this.formattedDate,
  });

  final String hikerName;
  final String trailName;
  final String trailRegion;
  final int totalStages;
  final double totalDistanceKm;
  final int totalElevationGain;
  final DateTime completionDate;
  final int durationDays;
  final String formattedDate;

  /// Texte principal du diplôme
  String get mainText =>
      'Certifie que $hikerName a parcouru le $trailName '
      'en $durationDays jours, franchissant $totalStages étapes, '
      '${totalDistanceKm.toStringAsFixed(0)} kilomètres '
      'et ${totalElevationGain}m de dénivelé positif.';
}
