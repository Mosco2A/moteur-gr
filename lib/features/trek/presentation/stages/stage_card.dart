import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/stage.dart';

/// Carte Material 3 representant une etape de sentier.
///
/// Affiche le numero (CircleAvatar), le nom i18n selon la locale,
/// la distance en km, le denivele positif et la duree estimee.
/// [onTap] declenche la navigation vers le detail de l'etape.
class StageCard extends StatelessWidget {
  const StageCard({super.key, required this.stage, required this.onTap});

  /// Etape a afficher.
  final Stage stage;

  /// Callback au tap sur la carte.
  final VoidCallback onTap;

  /// Retourne le nom de l'etape selon la locale courante.
  ///
  /// Fallback : nameFr si la traduction est vide.
  String _localizedName(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'en':
        return stage.nameEn.isNotEmpty ? stage.nameEn : stage.nameFr;
      case 'de':
        return stage.nameDe.isNotEmpty ? stage.nameDe : stage.nameFr;
      case 'it':
        return stage.nameIt.isNotEmpty ? stage.nameIt : stage.nameFr;
      case 'es':
        return stage.nameEs.isNotEmpty ? stage.nameEs : stage.nameFr;
      default:
        return stage.nameFr;
    }
  }

  /// Formate la duree estimee en heures et minutes.
  ///
  /// Retourne une chaine vide si la duree est nulle.
  String _formattedDuration() {
    final duration = stage.estimatedDuration;
    if (duration.inSeconds == 0) return '';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, '0')}';
    }
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  /// Construit le sous-titre : distance + D+ + duree.
  String _subtitle() {
    final parts = <String>[
      '${stage.distance.toStringAsFixed(1)} km',
      'D+ ${stage.elevationGain} m',
    ];
    final duration = _formattedDuration();
    if (duration.isNotEmpty) {
      parts.add(duration);
    }
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // SW-SKIN-L3c : Card Material -> AppCard (grammaire unifiee). onTap porte
    // sur la carte (InkWell interne d'AppCard, borne au rayon) comme l'InkWell
    // d'origine ; padding zero pour garder la ListTile bord a bord.
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text('${stage.orderIndex}'),
        ),
        title: Text(_localizedName(context)),
        subtitle: Text(_subtitle()),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
