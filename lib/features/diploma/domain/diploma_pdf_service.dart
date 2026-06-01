import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Donnees necessaires a la generation du PDF diplome.
///
/// Structure decouplee du moteur -- aucune dependance vers
/// poi/, trek/, after/, planning/ ou feedback/.
/// Generique multi-sentier : le nom du sentier vient du parametre,
/// jamais en dur.
class DiplomaPdfData {
  const DiplomaPdfData({
    required this.hikerName,
    required this.trailName,
    required this.trailRegion,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    this.mapImageBytes,
  });

  /// Nom ou pseudo du randonneur (personnalisation)
  final String hikerName;

  /// Nom d affichage du sentier (generique, depuis TrailConfig)
  final String trailName;

  /// Region geographique du sentier
  final String trailRegion;

  /// Nombre total d etapes accomplies
  final int totalStages;

  /// Distance totale en kilometres
  final double totalDistanceKm;

  /// Denivele positif total en metres
  final int totalElevationGain;

  /// Date de debut du trek
  final DateTime startDate;

  /// Date de fin du trek
  final DateTime endDate;

  /// Duree totale en jours
  final int durationDays;

  /// Image PNG optionnelle du trace carte (bytes)
  final Uint8List? mapImageBytes;
}

/// Labels i18n injectes au service PDF.
///
/// Aucun texte en dur -- tout passe par Slang via cette structure.
/// Le caller resout les traductions et les injecte ici.
class DiplomaPdfLabels {
  const DiplomaPdfLabels({
    required this.title,
    required this.subtitle,
    required this.certifies,
    required this.completed,
    required this.stages,
    required this.distance,
    required this.elevation,
    required this.duration,
    required this.from,
    required this.to,
    required this.issuedOn,
  });

  /// Titre du diplome
  final String title;

  /// Sous-titre
  final String subtitle;

  /// Label certifie
  final String certifies;

  /// Label completion
  final String completed;

  /// Stats etapes -- deja formate
  final String stages;

  /// Stats distance -- deja formate
  final String distance;

  /// Stats denivele -- deja formate
  final String elevation;

  /// Stats duree -- deja formate
  final String duration;

  /// Label debut
  final String from;

  /// Label fin
  final String to;

  /// Label delivrance -- deja formate
  final String issuedOn;
}

/// Service de generation PDF pour le diplome de fin de trek.
///
/// Genere un document A4 paysage avec mise en page elegante :
/// titre, nom du randonneur, sentier, statistiques, dates,
/// et optionnellement une carte du trace.
///
/// Generique multi-sentier -- aucune reference en dur.
/// Personnalise avec le prenom/pseudo du randonneur.
/// Labels externalises via [DiplomaPdfLabels] (Slang).
class DiplomaPdfService {
  /// Genere les bytes du document PDF diplome.
  ///
  /// Retourne un [Uint8List] pret pour sauvegarde ou impression
  /// via le package printing.
  static Future<Uint8List> generatePdf({
    required DiplomaPdfData data,
    required DiplomaPdfLabels labels,
    String locale = 'fr',
  }) async {
    final pdf = pw.Document(
      title: labels.title,
      author: data.hikerName,
    );

    // Couleurs du diplome
    const headerColor = PdfColor.fromInt(0xFF1B5E20);
    const accentColor = PdfColor.fromInt(0xFF4CAF50);
    const textColor = PdfColor.fromInt(0xFF212121);
    const subtitleColor = PdfColor.fromInt(0xFF616161);

    // Formatage des dates selon la locale
    final dateFormat = DateFormat('d MMMM yyyy', locale);
    final startFormatted = dateFormat.format(data.startDate);
    final endFormatted = dateFormat.format(data.endDate);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: accentColor, width: 3),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(30),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _buildHeader(labels, headerColor, subtitleColor, accentColor),
                pw.SizedBox(height: 20),
                _buildHikerBlock(
                  data, labels, headerColor, textColor, subtitleColor,
                ),
                pw.SizedBox(height: 20),
                _buildStatsRow(labels, accentColor, textColor),
                pw.SizedBox(height: 16),
                if (data.mapImageBytes != null)
                  _buildMapImage(data.mapImageBytes!, accentColor),
                _buildFooter(
                  labels,
                  startFormatted,
                  endFormatted,
                  accentColor,
                  subtitleColor,
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// En-tete : titre + sous-titre + separateur
  static pw.Widget _buildHeader(
    DiplomaPdfLabels labels,
    PdfColor headerColor,
    PdfColor subtitleColor,
    PdfColor accentColor,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          labels.title,
          style: pw.TextStyle(
            fontSize: 42,
            fontWeight: pw.FontWeight.bold,
            color: headerColor,
            letterSpacing: 8,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          labels.subtitle,
          style: pw.TextStyle(
            fontSize: 14,
            color: subtitleColor,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Container(width: 200, height: 2, color: accentColor),
      ],
    );
  }

  /// Bloc central : certifie que [nom] a parcouru le [sentier]
  static pw.Widget _buildHikerBlock(
    DiplomaPdfData data,
    DiplomaPdfLabels labels,
    PdfColor headerColor,
    PdfColor textColor,
    PdfColor subtitleColor,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          labels.certifies,
          style: pw.TextStyle(fontSize: 16, color: subtitleColor),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          data.hikerName,
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: textColor,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: '${labels.completed} ',
                style: pw.TextStyle(fontSize: 16, color: subtitleColor),
              ),
              pw.TextSpan(
                text: data.trailName,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: headerColor,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          data.trailRegion,
          style: pw.TextStyle(
            fontSize: 14,
            color: subtitleColor,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }

  /// Ligne de statistiques (etapes, distance, denivele, duree)
  static pw.Widget _buildStatsRow(
    DiplomaPdfLabels labels,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatBlock(labels.stages, accentColor, textColor),
        _buildStatBlock(labels.distance, accentColor, textColor),
        _buildStatBlock(labels.elevation, accentColor, textColor),
        _buildStatBlock(labels.duration, accentColor, textColor),
      ],
    );
  }

  /// Bloc de statistique individuel
  static pw.Widget _buildStatBlock(
    String label,
    PdfColor accentColor,
    PdfColor textColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: accentColor, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontSize: 12, color: textColor),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Image optionnelle du trace carte
  static pw.Widget _buildMapImage(
    Uint8List mapBytes,
    PdfColor accentColor,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          height: 120,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: accentColor, width: 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Image(
              pw.MemoryImage(mapBytes),
              fit: pw.BoxFit.contain,
            ),
          ),
        ),
        pw.SizedBox(height: 16),
      ],
    );
  }

  /// Pied : dates + separateur + delivre le
  static pw.Widget _buildFooter(
    DiplomaPdfLabels labels,
    String startFormatted,
    String endFormatted,
    PdfColor accentColor,
    PdfColor subtitleColor,
  ) {
    return pw.Column(
      children: [
        pw.Text(
          '${labels.from} $startFormatted ${labels.to} $endFormatted',
          style: pw.TextStyle(fontSize: 13, color: subtitleColor),
        ),
        pw.SizedBox(height: 16),
        pw.Container(width: 200, height: 2, color: accentColor),
        pw.SizedBox(height: 12),
        pw.Text(
          labels.issuedOn,
          style: pw.TextStyle(
            fontSize: 12,
            color: subtitleColor,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
