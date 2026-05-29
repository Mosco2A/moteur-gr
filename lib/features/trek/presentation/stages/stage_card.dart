import 'package:flutter/material.dart';

import '../../domain/models/stage.dart';

/// Carte Material 3 affichant le resume d'une etape de trek.
///
/// Affiche le numero d'ordre, le nom i18n (selon la locale du contexte),
/// la distance en km, le denivele positif en metres et la duree estimee.
/// Un tap sur la carte declenche [onTap].
class StageCard extends StatelessWidget {
  const StageCard({
    super.key,
    required this.stage,
    required this.onTap,
  });

  /// Modele de l'etape a afficher
  final Stage stage;

  /// Callback au tap (navigation vers detail)
  final VoidCallback onTap;

  /// Retourne le nom de l'etape selon la locale courante.
  ///
  /// Fallback : nameEn si la langue demandee n'a pas de traduction,
  /// puis nameFr en dernier recours.
  String _localizedName(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (lang) {
      case 'fr':
        return stage.nameFr;
      case 'de':
        return stage.nameDe.isNotEmpty ? stage.nameDe : stage.nameEn;
      case 'it':
        return stage.nameIt.isNotEmpty ? stage.nameIt : stage.nameEn;
      case 'es':
        return stage.nameEs.isNotEmpty ? stage.nameEs : stage.nameEn;
      case 'en':
      default:
        return stage.nameEn.isNotEmpty ? stage.nameEn : stage.nameFr;
    }
  }

  /// Formate la duree en heures et minutes (ex: "5h30").
  static String formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            child: Text('${stage.orderIndex}'),
          ),
          title: Text(_localizedName(context)),
          subtitle: Text(
            '${stage.distance.toStringAsFixed(1)} km'
            '  \u2022  '
            '${stage.elevationGain} m D+'
            '  \u2022  '
            '${formatDuration(stage.estimatedDurationMinutes)}',
          ),
        ),
      ),
    );
  }
}
