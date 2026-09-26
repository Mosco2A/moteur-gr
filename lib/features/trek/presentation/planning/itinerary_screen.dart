import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/models/stage.dart';
import '../../../../core/models/stage_duration.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../hub/providers/cockpit_start_providers.dart';
import '../../domain/models/itinerary_day.dart';
import '../../providers/gps_providers.dart';
import '../../providers/itinerary_providers.dart';

/// Ecran ITINERAIRE (parite GR20).
///
/// Reproduit le role de l'ecran « Itineraire » de GR20 cote StepWays : le
/// DEROULE des etapes du sentier courant, jour par jour, avec les infos par
/// etape (distance, D+, D-, difficulte) et l'ACTION d'ouvrir le detail d'une
/// etape. Avant ce lot, la carte « Itineraire »
/// du HUB faisait `context.go('/map')` : la pile de navigation etait remplacee
/// (bascule d'onglet du shell) et le retour depuis la carte plantait
/// (`currentConfiguration.isNotEmpty`). Cet ecran est desormais une route
/// hors-shell atteinte par `context.push` -> retour propre vers le HUB.
///
/// Generique : alimente par [itineraryProvider] (etapes du sentier actif +
/// config), ZERO hardcode de localite. Hors systeme de peaux (AppCard, couleurs
/// semantiques d'AppTheme). Tout texte via Slang (t.itinerary.* / t.stage.*).
class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on affiche l'itineraire.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider.select((a) => a));

    // Q1 (§12.5) : ouvrir l'écran Itinéraire marque l'étape cœur « Itinéraire »
    // comme faite (persisté par sentier) — l'un des 3 signaux qui débloquent
    // « Démarrer le trek ». Idempotent ; planifié hors phase de build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(prepareCoreStepsProvider(trailId).notifier)
          .markSeen(PrepCoreStep.itinerary);
    });

    return Scaffold(
      // Ph5 (L6b) : AppHeader universel ([Retour]+[Accueil] contextuel). Ecran de
      // preparation (fiche pushee depuis le cockpit) -> pas de barre contextuelle
      // dediee (§4 ne prevoit pas d'actions specifiques ici).
      appBar: AppHeader(title: t.itinerary.title),
      body: itineraryAsync.when(
        loading: () => LoadingView(message: t.itinerary.loading),
        error: (error, _) => ErrorView(
          message: t.itinerary.error,
          onRetry: () => ref.invalidate(itineraryProvider),
        ),
        data: (days) {
          if (days.isEmpty) {
            return _EmptyItinerary();
          }
          return _ItineraryContent(days: days);
        },
      ),
    );
  }
}

/// Etat vide : aucune etape chargee pour le sentier.
class _EmptyItinerary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.route_outlined,
              size: 72,
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.itinerary.empty,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.itinerary.emptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu : controle du sens (si applicable) + en-tete de totaux + liste des
/// jours (deroule des etapes).
class _ItineraryContent extends ConsumerWidget {
  const _ItineraryContent({required this.days});

  final List<ItineraryDay> days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalKm = days.fold<double>(0, (s, d) => s + d.totalDistance);
    final totalGain = days.fold<int>(0, (s, d) => s + d.totalElevation);
    final stageCount = days.fold<int>(0, (s, d) => s + d.stageCount);
    // Un jour d'itineraire sans etape EST un jour de repos (projection de
    // [PlannedDay.isRestDay] par [itineraryProvider]) : c'est ce qui permet de
    // dire ce que le compteur de jours compte (tache 569, R2).
    final restDayCount = days.where((d) => d.stages.isEmpty).length;

    // Retour Chris #12b : le controle du SENS n'a de sens que si le sentier
    // propose au moins deux sens de parcours (`TrailConfig.directions`).
    final directions = ref.watch(
      trailConfigProvider.select((c) => c.directions),
    );
    final showDirection = directions.length >= 2;

    return Column(
      children: [
        _ItineraryStatsHeader(
          totalKm: totalKm,
          totalGain: totalGain,
          dayCount: days.length,
          restDayCount: restDayCount,
          stageCount: stageCount,
        ),
        if (showDirection) _DirectionControl(days: days),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
            itemCount: days.length,
            itemBuilder: (context, index) => _DayCard(day: days[index]),
          ),
        ),
      ],
    );
  }
}

/// Controle du SENS de la rando (retour Chris #12b) : affiche Depart -> Arrivee
/// (noms des extremites dans le sens courant) et un bouton « Inverser le sens ».
///
/// N'INVENTE aucune donnee : le sens est porte par [selectedDirectionProvider]
/// (deja utilise par tout le pipeline direction-aware — plan de marche, GPS,
/// arrivee) et les sens possibles par `TrailConfig.directions`. Inverser bascule
/// la valeur entre le sens de reference (1er code) et l'autre ; l'itineraire se
/// recalcule tout seul ([itineraryProvider] watch ce provider) et l'ordre des
/// etapes s'inverse. Les noms d'extremites sont lus sur l'itineraire courant
/// (1re etape du 1er jour = depart ; derniere etape du dernier jour = arrivee).
class _DirectionControl extends ConsumerWidget {
  const _DirectionControl({required this.days});

  final List<ItineraryDay> days;

  /// Nom de l'etape de DEPART dans le sens courant (1re etape du 1er jour porteur
  /// d'etape), ou null si indisponible.
  String? get _startName {
    for (final d in days) {
      if (d.stages.isNotEmpty) return d.stages.first.name;
    }
    return null;
  }

  /// Nom de l'etape d'ARRIVEE dans le sens courant (derniere etape du dernier
  /// jour porteur d'etape), ou null si indisponible.
  String? get _endName {
    for (final d in days.reversed) {
      if (d.stages.isNotEmpty) return d.stages.last.name;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final directions = ref.watch(
      trailConfigProvider.select((c) => c.directions),
    );
    final forward = directions.isNotEmpty ? directions.first : null;
    final selected = ref.watch(selectedDirectionProvider) ?? forward;

    final start = _startName;
    final end = _endName;

    return AppCard(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingSm,
        AppTheme.spacingBase,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, size: 18, color: scheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                t.itinerary.direction.title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Depart -> Arrivee (noms des extremites dans le sens courant).
          if (start != null && end != null)
            Row(
              children: [
                Expanded(
                  child: _Endpoint(
                    label: t.itinerary.direction.from,
                    place: start,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                  ),
                  child: Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: scheme.onSurface.withAlpha(140),
                  ),
                ),
                Expanded(
                  child: _Endpoint(
                    label: t.itinerary.direction.to,
                    place: end,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppTheme.spacingSm),
          // Bouton « Inverser le sens » : bascule entre le sens de reference et
          // l'autre code declare par le sentier.
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: forward == null
                  ? null
                  : () {
                      // Sens cible = l'AUTRE code que le sens courant. On prend
                      // le 1er code different du sens selectionne (robuste meme
                      // si > 2 sens : bascule vers le suivant declare).
                      final current = selected ?? forward;
                      final next = directions.firstWhere(
                        (d) => d != current,
                        orElse: () => forward,
                      );
                      ref.read(selectedDirectionProvider.notifier).state = next;
                    },
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: Text(t.itinerary.direction.reverse),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une extremite (Depart / Arrivee) : petit label + nom du lieu.
class _Endpoint extends StatelessWidget {
  const _Endpoint({
    required this.label,
    required this.place,
    this.alignEnd = false,
  });

  final String label;
  final String place;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(140),
          ),
        ),
        Text(
          place,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// En-tete de statistiques globales (parite GR20 _StatsHeader).
///
/// TACHE 569 (R2) — LE COMPTEUR DE JOURS DIT CE QU'IL COMPTE.
///
/// LE RETOUR DE CHRIS, MOT POUR MOT : « faisabilite dit 11 et itineraire propose
/// 9 ». Les deux chiffres etaient JUSTES et ne parlaient pas de la meme chose :
/// la Faisabilite conseillait 11 jours AU TOTAL, cet en-tete affichait les 9
/// jours du programme courant sous un libelle « Jour » qui ne disait ni marche,
/// ni repos, ni total. Deux nombres sans unite, c'est une contradiction pour
/// celui qui lit.
///
/// Ce compteur compte des TOTAUX — un jour de repos est une journee de
/// l'itineraire — et il le dit, avec le detail marche / repos juste en dessous.
class _ItineraryStatsHeader extends StatelessWidget {
  const _ItineraryStatsHeader({
    required this.totalKm,
    required this.totalGain,
    required this.dayCount,
    required this.restDayCount,
    required this.stageCount,
  });

  final double totalKm;
  final int totalGain;

  /// Jours TOTAUX de l'itineraire (marche + repos).
  final int dayCount;

  /// Jours de REPOS parmi eux.
  final int restDayCount;

  final int stageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      color: theme.colorScheme.primary.withAlpha(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(
                label: t.itinerary.totalDistance,
                value: '${totalKm.toStringAsFixed(0)} km',
              ),
              _Stat(label: t.itinerary.totalElevation, value: '$totalGain m'),
              _Stat(label: t.itinerary.daysTotal, value: '$dayCount'),
              _Stat(label: t.itinerary.stages, value: '$stageCount'),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.itinerary.daysBreakdown(
              walk: dayCount - restDayCount,
              rest: restDayCount,
            ),
            key: const ValueKey('itinerary-days-breakdown'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Carte d'un jour : en-tete (Jour N, nb etapes, distance) + etapes du jour.
///
/// Parite GR20 : les etapes du jour sont deroulees avec leurs infos et une
/// action (tap -> detail de l'etape). Un jour sans etape (repos) est signale.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingXs,
      ),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: day.dayNumber == 1,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text('${day.dayNumber}'),
        ),
        title: Text('${t.itinerary.day} ${day.dayNumber}'),
        subtitle: Text(
          day.stageCount == 0
              ? t.itinerary.restDay
              // PLURIEL PORTE PAR SLANG, PLUS PAR UN replaceAll (tache 560, N4).
              // La cle etait « {count} etapes » et le nombre y etait substitue a
              // la main : un jour a une seule etape affichait « 1 etapes ». La
              // cle est desormais un pluriel Slang, donc chaque langue applique
              // SA regle CLDR (en francais `one` couvre 0 et 1, en anglais 1
              // seul) — un accord de plus a maintenir aurait ete un accord de
              // plus a oublier.
              : '${t.itinerary.stageCount(n: day.stageCount)}'
                    '  -  ${day.totalDistance.toStringAsFixed(1)} km'
                    '  -  D+ ${day.totalElevation} m',
        ),
        children: day.stages
            .map((stage) => _StageTile(stage: stage))
            .toList(growable: false),
      ),
    );
  }
}

/// Tuile d'une etape : infos par etape (distance, D+, D-) + chip difficulte.
/// Action (parite GR20) : tap sur la tuile -> detail de l'etape (/stages/:num).
class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage});

  final StageModel stage;

  String _difficultyLabel() {
    switch (stage.difficulty) {
      case 'easy':
        return t.stage.difficulty.easy;
      case 'moderate':
        return t.stage.difficulty.moderate;
      case 'hard':
        return t.stage.difficulty.hard;
      case 'extreme':
        return t.stage.difficulty.extreme;
      default:
        return stage.difficulty;
    }
  }

  Color _difficultyColor() {
    switch (stage.difficulty) {
      case 'easy':
        return AppTheme.vertFacile;
      case 'moderate':
        return AppTheme.jauneModere;
      case 'hard':
        return AppTheme.orangeDifficile;
      case 'extreme':
        return AppTheme.rougeExtreme;
      default:
        return AppTheme.grisGranite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = _difficultyColor();

    return InkWell(
      onTap: () => context.push('/stages/${stage.stageNumber}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          AppTheme.spacingSm,
          AppTheme.spacingBase,
          AppTheme.spacingSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastille numero d'etape teintee par difficulte.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: diffColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: diffColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stage.stageNumber}',
                style: theme.textTheme.labelLarge?.copyWith(color: diffColor),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  // Infos par etape (parite GR20 : distance, D+, D-).
                  Wrap(
                    spacing: AppTheme.spacingMd,
                    runSpacing: AppTheme.spacingXs,
                    children: [
                      _MiniStat(
                        icon: Icons.straighten,
                        label: '${stage.distanceKm.toStringAsFixed(1)} km',
                      ),
                      _MiniStat(
                        icon: Icons.arrow_upward,
                        label: '${stage.elevationGainM} m',
                        color: AppTheme.rougeExtreme,
                      ),
                      _MiniStat(
                        icon: Icons.arrow_downward,
                        label: '${stage.elevationLossM} m',
                        color: theme.colorScheme.primary,
                      ),
                      // Duree par etape (parite GR20) — leve le residuel « pas
                      // de duree » sur Itineraire. Valeur issue du socle
                      // « donnees externes » ([stageDurationMinutes]) : donnee
                      // du sentier si fournie, sinon estimation Naismith. Un
                      // sentier sans la donnee reste affiche (repli propre).
                      _MiniStat(
                        icon: Icons.schedule,
                        label: formatDurationMinutes(
                          stageDurationMinutes(stage),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      // Chip difficulte (semantique).
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusChip,
                          ),
                          border: Border.all(color: diffColor),
                        ),
                        child: Text(
                          _difficultyLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: diffColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Action (parite GR20) : ouvrir le detail de l'etape.
                      // Affordance de navigation vers le detail.
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.onSurface.withAlpha(120),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini statistique (icone + valeur) pour les infos d'une etape.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface.withAlpha(160);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 3),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
      ],
    );
  }
}
