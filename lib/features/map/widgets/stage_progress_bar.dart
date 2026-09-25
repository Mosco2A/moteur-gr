import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Barre de progression d'étape affichée en bas de la carte.
///
/// Affiche le nom de l'étape courante, la distance restante,
/// le pourcentage de progression, et un indicateur "hors tracé"
/// si l'utilisateur est à plus de 100m du sentier.
///
/// CORRECTIF L6-2 — LIGNE DE CHIFFRES MESURÉS. La barre ne portait que quatre
/// informations là où la navigation de référence en affiche six sur deux
/// lignes. Les valeurs ajoutées (total, parcouru, dénivelé, vitesse moyenne,
/// altitude) sont OPTIONNELLES et chacune disparaît quand elle vaut `null` :
/// une valeur absente ne s'affiche pas à zéro. C'est la même règle que le
/// correctif L5-6 — une vitesse moyenne mesurée, ou rien.
///
/// Cette seconde ligne est purement informative : elle est enveloppée dans un
/// [IgnorePointer] pour ne jamais voler un geste à la carte.
///
/// LOT D (tâche 554) — JAMAIS D'ÉCRAN NU. Retour de Chris, mot pour mot :
/// « 14 navigation ne ressemble en rien a GR20 !!!!! ». La cause n'était pas un
/// manque de fonctions : c'est que, sans randonnée démarrée, TOUTES les valeurs
/// valent `null`, les six disparaissent d'un coup et il ne reste qu'une carte
/// nue — là où la navigation de référence montre TOUJOURS ses six cases, avec
/// un tiret quand la valeur n'est pas encore connue (`'--'` pour l'altitude
/// sans fix GPS).
///
/// D'où [showPendingValues] : quand il est vrai, une valeur absente s'affiche
/// en attente ([pendingValueLabel]) au lieu de disparaître. La règle du
/// correctif L5-6 est INTACTE — on n'affiche jamais un zéro qui aurait l'air
/// mesuré ; un tiret dit « pas encore », ce qui est la vérité. Le défaut reste
/// `false` : en randonnée réelle, la barre garde son comportement d'origine.
class StageProgressBar extends StatelessWidget {
  const StageProgressBar({
    super.key,
    required this.stageName,
    required this.distanceRemainingKm,
    required this.progressRatio,
    required this.isOffTrack,
    this.totalDistanceKm,
    this.distanceCoveredKm,
    this.elevationGainM,
    this.elevationLossM,
    this.avgSpeedKmh,
    this.altitudeM,
    this.showPendingValues = false,
    this.footer,
  });

  /// Marque d'une valeur qui n'est pas encore mesurable (parite GR20 : `'--'`).
  ///
  /// Volontairement un SIGNE et non un mot : il ne demande aucune traduction et
  /// se lit dans les cinq langues.
  static const String pendingValueLabel = '--';

  /// Nom de l'étape courante
  final String stageName;

  /// Distance restante en kilomètres
  final double distanceRemainingKm;

  /// Pourcentage de progression (0.0 à 1.0)
  final double progressRatio;

  /// Indicateur hors tracé (distance > 100m)
  final bool isOffTrack;

  /// Distance totale du sentier en kilomètres (L6-2). `null` = masquée.
  final double? totalDistanceKm;

  /// Distance déjà parcourue en kilomètres (L6-2). `null` = masquée.
  final double? distanceCoveredKm;

  /// Dénivelé positif cumulé, mesuré sur la trace (L6-2). `null` = masqué.
  final int? elevationGainM;

  /// Dénivelé négatif cumulé, mesuré sur la trace (L6-2). `null` = masqué.
  final int? elevationLossM;

  /// Vitesse moyenne mesurée en km/h (L6-2). `null` = masquée, jamais zéro.
  final double? avgSpeedKmh;

  /// Altitude courante en mètres (L6-2). `null` = masquée.
  final double? altitudeM;

  /// Affiche les valeurs absentes en attente au lieu de les masquer (LOT D).
  ///
  /// Employé par l'état AVANT randonnée de la carte : les chiffres connus du
  /// programme sont réels, les chiffres qui demandent le GPS portent un tiret.
  final bool showPendingValues;

  /// Ligne d'explication optionnelle sous les chiffres (LOT D).
  ///
  /// Sert à dire ce qui démarrera avec la randonnée, plutôt que de laisser
  /// deviner pourquoi trois cases portent un tiret.
  final Widget? footer;

  /// Vrai dès qu'au moins une valeur de la seconde ligne est disponible.
  bool get _hasMeasuredLine =>
      showPendingValues ||
      totalDistanceKm != null ||
      distanceCoveredKm != null ||
      elevationGainM != null ||
      elevationLossM != null ||
      avgSpeedKmh != null ||
      altitudeM != null;

  /// Libellé d'un chiffre : sa valeur si elle existe, sinon le tiret d'attente.
  String _valueOrPending(String? formatted) =>
      formatted ?? pendingValueLabel;

  /// Vrai si la case doit être rendue : valeur connue, ou mode « en attente ».
  bool _shows(Object? value) => value != null || showPendingValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (progressRatio * 100).round();
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ligne titre + indicateur hors tracé
          Row(
            children: [
              Expanded(
                child: Text(
                  stageName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isOffTrack)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.rougeUrgence.withAlpha(30),
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusChip,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: AppTheme.rougeUrgence,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.map.offTrackChip,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.rougeUrgence,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppTheme.grisClair,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOffTrack ? AppTheme.rougeUrgence : primaryColor,
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // Ligne distance + pourcentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.map.stageRemaining(
                  km: distanceRemainingKm.toStringAsFixed(1),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
              Text(
                '$progressPercent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Seconde ligne : chiffres MESURÉS (L6-2). Informative uniquement.
          if (_hasMeasuredLine) ...[
            const SizedBox(height: AppTheme.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacingSm),
            IgnorePointer(
              child: Wrap(
                spacing: AppTheme.spacingBase,
                runSpacing: AppTheme.spacingXs,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  if (_shows(totalDistanceKm))
                    _MeasuredStat(
                      icon: Icons.straighten,
                      label: t.tracking.total,
                      value: _valueOrPending(
                        totalDistanceKm == null
                            ? null
                            : '${totalDistanceKm!.toStringAsFixed(1)} km',
                      ),
                    ),
                  if (_shows(distanceCoveredKm))
                    _MeasuredStat(
                      icon: Icons.directions_walk,
                      label: t.tracking.covered,
                      value: _valueOrPending(
                        distanceCoveredKm == null
                            ? null
                            : '${distanceCoveredKm!.toStringAsFixed(1)} km',
                      ),
                    ),
                  if (_shows(elevationGainM))
                    _MeasuredStat(
                      icon: Icons.trending_up,
                      label: t.tracking.dPlus,
                      value: _valueOrPending(
                        elevationGainM == null ? null : '$elevationGainM m',
                      ),
                    ),
                  if (_shows(elevationLossM))
                    _MeasuredStat(
                      icon: Icons.trending_down,
                      label: t.tracking.dMinus,
                      value: _valueOrPending(
                        elevationLossM == null ? null : '$elevationLossM m',
                      ),
                    ),
                  if (_shows(avgSpeedKmh))
                    _MeasuredStat(
                      icon: Icons.speed,
                      label: t.tracking.avgSpeed,
                      value: _valueOrPending(
                        avgSpeedKmh == null
                            ? null
                            : '${avgSpeedKmh!.toStringAsFixed(1)} km/h',
                      ),
                    ),
                  if (_shows(altitudeM))
                    _MeasuredStat(
                      icon: Icons.terrain,
                      label: t.tracking.altitude,
                      value: _valueOrPending(
                        altitudeM == null ? null : '${altitudeM!.round()} m',
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Ligne d'explication (LOT D) : ce qui démarrera avec la randonnée.
          // Hors [IgnorePointer] — elle peut porter un bouton d'action.
          if (footer != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            footer!,
          ],
        ],
      ),
    );
  }
}

/// Une valeur mesurée de la seconde ligne : icône, chiffre, libellé (L6-2).
class _MeasuredStat extends StatelessWidget {
  const _MeasuredStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.grisTexteSecondaire),
          const SizedBox(width: 4),
          Text(
            value,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}
