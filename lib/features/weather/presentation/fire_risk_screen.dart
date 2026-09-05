import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/connectivity_monitor.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/fire_risk.dart';
import '../providers/current_stage_provider.dart';
import '../providers/fire_risk_providers.dart';
import '../providers/weather_providers.dart';

/// Ecran RISQUE INCENDIE (parite GR20 `FireRiskScreen`, data-driven — regle
/// « donnees en externe » de Christophe #99460).
///
/// Clone strict de l'ecran GR20 (7 sections) :
///   1. AppBar « Risque incendie » + bouton refresh ;
///   2. bandeau MAJ (source + fraicheur des donnees, horodatage, rafraichir) ;
///   3. bandeau source FWI (indice Fire Weather Index, Open-Meteo / Meteo-France) ;
///   4. section Reglementation (fond orange) — DATA-DRIVEN par sentier
///      ([trailFireRegulationProvider]) : periode, region, message, URL viennent
///      de la config du sentier ; masquee proprement si absente ;
///   5. legende des 5 niveaux (Faible -> Extreme, couleurs semantiques AppTheme) ;
///   6. risque par etape : etapes a risque (niveau >= 1) triees decroissant,
///      badge « E{n} », nom, badge « Niv. X », detail par jour ;
///   7. numeros utiles tappables (tel:) — DATA-DRIVEN : 18/112 universels +
///      secours regionaux de [TrailConfig.emergencyNumbers].
///
/// Le NIVEAU de risque est DERIVE de la meteo (parite GR20) : le socle meteo
/// StepWays ([stageWeatherProvider], coords dynamiques + cache/API) est reutilise
/// et le niveau 0-5 calcule par [calculateFireRiskLevel] (algorithme GR20), agrege
/// par etape via [trailFireRiskProvider]. Le moteur reste GENERIQUE multi-sentiers
/// (#84627), zero hardcode de localite ni de « GR20/Corse ». Fallback gracieux :
/// pas de donnees meteo -> ecran informatif propre (pas de crash) ; reglementation
/// absente -> section masquee. Hors peau : couleurs semantiques d'AppTheme. Tout
/// libelle d'INTERFACE passe par Slang (`t.fireRisk.*`, 5 langues) ; a11y
/// (`Semantics`) sur numeros tappables et lien prefecture.
class FireRiskScreen extends ConsumerWidget {
  const FireRiskScreen({super.key, required this.trailId});

  /// Identifiant du sentier courant (risque + reglementation + secours par
  /// sentier).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(trailFireRiskProvider(trailId));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.fireRisk.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t.a11y.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: t.fireRisk.refresh,
            onPressed: () => _refreshAll(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(context, ref, silent: true),
        child: _buildBody(context, ref, theme, t, state),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations t,
    FireRiskState state,
  ) {
    // Chargement initial : aucune etape resolue encore.
    if (state.isLoading && state.stages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Fallback gracieux : aucune prevision meteo exploitable (offline + pas de
    // cache) -> ecran informatif propre (parite « ecran informatif », pas de
    // crash). La section reglementation/numeros n'a pas de sens sans le contexte
    // risque ; on montre un etat vide scrollable (pull-to-refresh reste actif).
    if (!state.hasAnyForecast && !state.isLoading) {
      return _FireRiskEmptyState(trailId: trailId);
    }

    final stagesAtRisk = state.stagesAtRisk;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2. Bandeau MAJ (source + fraicheur).
          _UpdateBanner(trailId: trailId),
          const SizedBox(height: AppTheme.spacingLg),

          // 3. Bandeau source FWI (transparence).
          _FwiSourceBanner(theme: theme, t: t),
          const SizedBox(height: AppTheme.spacingMd),

          // 4. Section Reglementation (data-driven, masquee si absente).
          _RegulationSection(trailId: trailId),

          // 5. Legende des niveaux.
          SectionHeader(
            title: t.fireRisk.levelsTitle,
            icon: Icons.local_fire_department,
            iconColor: AppTheme.rougeUrgence,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _Legend(theme: theme, t: t),
          const SizedBox(height: AppTheme.spacingLg),

          // 6. Risque par etape.
          SectionHeader(
            title: t.fireRisk.stagesTitle,
            icon: Icons.map_outlined,
            iconColor: AppTheme.orangeDifficile,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          if (stagesAtRisk.isEmpty)
            _NoRiskCard(theme: theme, t: t)
          else
            ...stagesAtRisk.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                  child: _StageFireCard(stage: s, theme: theme, t: t),
                )),
          const SizedBox(height: AppTheme.spacingLg),

          // 7. Numeros utiles (data-driven).
          SectionHeader(
            title: t.fireRisk.numbersTitle,
            icon: Icons.phone,
            iconColor: theme.colorScheme.secondary,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _EmergencyNumbers(trailId: trailId, theme: theme, t: t),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  /// Rafraichit la meteo de TOUTES les etapes du sentier (parite GR20
  /// `forceRefresh`). Le socle StepWays est par etape : on relance le refresh de
  /// chaque etape resolue. [silent] : pas de SnackBar (pull-to-refresh).
  Future<void> _refreshAll(
    BuildContext context,
    WidgetRef ref, {
    bool silent = false,
  }) async {
    final t = Translations.of(context);
    final stages = ref.read(trailFireRiskProvider(trailId)).stages;
    try {
      await Future.wait([
        for (final s in stages)
          ref
              .read(stageWeatherProvider(WeatherStageParams(
                trailId: trailId,
                stageNumber: s.stageNumber,
              )).notifier)
              .refresh(),
      ]);
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.fireRisk.refreshed)),
        );
      }
    } catch (_) {
      if (!silent && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.fireRisk.refreshError)),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// 2. Bandeau MAJ — fraicheur/source des donnees (parite GR20 « Derniere MAJ »).
// ---------------------------------------------------------------------------

/// Bandeau de fraicheur des donnees (parite GR20 : 4 cas — live / cache recent /
/// cache ancien / jamais). StepWays derive la fraicheur de la date de la
/// prevision de l'etape de reference + de l'etat cache/connectivite du socle.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    // Etape de reference (1 par defaut) : porte la date de prevision servant
    // d'horodatage global (parite GR20 : MAJ globale du lot meteo).
    final refStage = ref.watch(referenceStageNumberProvider);
    final params = WeatherStageParams(trailId: trailId, stageNumber: refStage);
    final weather = ref.watch(stageWeatherProvider(params));
    final online = ref.watch(connectivityProvider).value ==
        ConnectivityStatusValues.online;

    final firstDay = weather.forecast?.days.isNotEmpty == true
        ? weather.forecast!.days.first
        : null;

    final String label;
    final Color color;
    if (firstDay == null) {
      // Aucune donnee horodatee -> jamais mis a jour (cas fallback GR20).
      color = AppTheme.rougeUrgence;
      label = t.fireRisk.update.never;
    } else if (!weather.isFromCache && online) {
      // Donnees live (API).
      color = AppTheme.vertFacile;
      label = t.fireRisk.update.liveAt(date: _formatDate(firstDay.date));
    } else {
      // Cache : recent (< 3h) ou ancien (parite GR20 : seuil 3h).
      final diff = DateTime.now().difference(firstDay.date);
      if (diff.inHours < 3) {
        color = AppTheme.jauneModere;
        label = t.fireRisk.update
            .cacheRecent(duration: _formatDuration(diff, t));
      } else {
        color = AppTheme.orangeDifficile;
        label = t.fireRisk.update.cacheOld(date: _formatDate(firstDay.date));
      }
    }

    return AppCard(
      child: Row(
        children: [
          Icon(Icons.update, size: 16, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
          TextButton.icon(
            onPressed: () => ref
                .read(stageWeatherProvider(params).notifier)
                .refresh(),
            icon: const Icon(Icons.refresh, size: 14),
            label: Text(t.fireRisk.refresh,
                style: const TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Bandeau source FWI (parite GR20 : transparence sur l'indice).
// ---------------------------------------------------------------------------

class _FwiSourceBanner extends StatelessWidget {
  const _FwiSourceBanner({required this.theme, required this.t});

  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final accent = theme.colorScheme.secondary;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: accent.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: accent.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: accent),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.fireRisk.fwiSource,
              style: theme.textTheme.bodySmall?.copyWith(
                color: accent,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Section Reglementation (data-driven, masquee si absente).
// ---------------------------------------------------------------------------

class _RegulationSection extends ConsumerWidget {
  const _RegulationSection({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final regulation = ref.watch(trailFireRegulationProvider(trailId));

    // Data-driven : pas de reglementation pour ce sentier -> section masquee
    // proprement (parite GR20 : masquee si vide), aucun littoral Corse en dur.
    if (regulation == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: AppTheme.orangeDifficile.withAlpha(15),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.orangeDifficile.withAlpha(60)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gavel,
                      size: 18, color: AppTheme.orangeDifficile),
                  const SizedBox(width: AppTheme.spacingSm),
                  Text(
                    t.fireRisk.regulation.title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.orangeDifficile,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              if (regulation.hasMessage) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  regulation.message,
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                ),
              ],
              if (regulation.hasDecreeUrl) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Semantics(
                  button: true,
                  label: t.fireRisk.a11y.decree,
                  child: InkWell(
                    onTap: () => _openUrl(regulation.decreeUrl!),
                    child: Row(
                      children: [
                        Icon(Icons.open_in_new,
                            size: 14, color: theme.colorScheme.secondary),
                        const SizedBox(width: AppTheme.spacingXs),
                        Flexible(
                          child: Text(
                            t.fireRisk.regulation.decreeLink,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              decoration: TextDecoration.underline,
                              decorationColor: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Legende des niveaux (parite GR20 : 5 badges couleur).
// ---------------------------------------------------------------------------

class _Legend extends StatelessWidget {
  const _Legend({required this.theme, required this.t});

  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _row(1, t.fireRisk.level.low),
          _row(2, t.fireRisk.level.moderate),
          _row(3, t.fireRisk.level.high),
          _row(4, t.fireRisk.level.veryHigh),
          _row(5, t.fireRisk.level.extreme),
        ],
      ),
    );
  }

  Widget _row(int level, String label) {
    final color = fireRiskColor(level);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color),
            ),
            child: Center(
              child: Text(
                '$level',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Icon(Icons.local_fire_department, size: 16, color: color),
          const SizedBox(width: AppTheme.spacingSm),
          Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. Risque par etape (parite GR20 `_buildStageFireCard`).
// ---------------------------------------------------------------------------

/// Carte « aucun risque » (parite GR20 : check_circle vert).
class _NoRiskCard extends StatelessWidget {
  const _NoRiskCard({required this.theme, required this.t});

  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: Column(
          children: [
            Icon(Icons.check_circle,
                size: 40, color: AppTheme.vertFacile.withAlpha(180)),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.fireRisk.noRisk,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.vertFacile),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte d'une etape a risque (parite GR20 : badge etape + nom + badge niveau +
/// detail par jour).
class _StageFireCard extends StatelessWidget {
  const _StageFireCard({
    required this.stage,
    required this.theme,
    required this.t,
  });

  final StageFireRisk stage;
  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context) {
    final maxLevel = stage.maxLevel;
    final color = fireRiskColor(maxLevel);

    return AppCard(
      borderColor: color.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge « E{n} ».
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.vertFacile.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  t.fireRisk.stageBadge(number: stage.stageNumber),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: AppTheme.vertFacile, fontSize: 12),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  stage.stageName,
                  style: theme.textTheme.titleLarge?.copyWith(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Badge « Niv. X » (niveau max).
              Semantics(
                label: t.fireRisk.a11y.levelBadge(level: maxLevel),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    border: Border.all(color: color),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_fire_department, size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        t.fireRisk.levelBadge(level: maxLevel),
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Detail par jour (parite GR20 : rangee de jours).
          Row(
            children: stage.days.map((d) {
              final dColor = fireRiskColor(d.level);
              return Expanded(
                child: Column(
                  children: [
                    Text(_dayLabel(d.dayIndex, t),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Icon(Icons.local_fire_department, size: 20, color: dColor),
                    Text(
                      t.fireRisk.dayLevel(level: d.level),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: dColor, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Numeros utiles (parite GR20 : liste tappable tel:).
// ---------------------------------------------------------------------------

class _EmergencyNumbers extends ConsumerWidget {
  const _EmergencyNumbers({
    required this.trailId,
    required this.theme,
    required this.t,
  });

  final String trailId;
  final ThemeData theme;
  final Translations t;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numbers = ref.watch(fireEmergencyNumbersProvider(trailId));

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < numbers.length; i++) ...[
            if (i > 0) const Divider(height: AppTheme.spacingMd),
            _row(context, numbers[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, FireEmergencyNumber n) {
    // Libelle : cle i18n pour les numeros universels (18/112), donnee du sentier
    // pour les secours regionaux (langue de la donnee).
    final label = n.isUniversal ? _universalLabel(n.labelKey!, t) : n.labelData!;
    // Couleur : rouge urgence pour les universels, orange pour les regionaux
    // (parite esprit GR20 : hierarchie visuelle 18/112 vs local).
    final color =
        n.isUniversal ? AppTheme.rougeUrgence : AppTheme.orangeDifficile;

    return Semantics(
      button: true,
      label: t.fireRisk.a11y.call(label: label, number: n.phone),
      child: InkWell(
        onTap: () => _call(n.phone),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          child: Row(
            children: [
              Icon(Icons.phone, size: 18, color: color),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(n.phone,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: color)),
                  ],
                ),
              ),
              Icon(Icons.call, size: 20, color: color),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _call(String phone) async {
    try {
      final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
      await launchUrl(uri);
    } catch (_) {
      // Silencieux (parite GR20 : echec d'appel non bloquant).
    }
  }
}

// ---------------------------------------------------------------------------
// Fallback : aucune donnee meteo (parite GR20 : ecran informatif propre).
// ---------------------------------------------------------------------------

class _FireRiskEmptyState extends StatelessWidget {
  const _FireRiskEmptyState({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    // Scrollable pour que le pull-to-refresh reste actif meme sans contenu.
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXl),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.local_fire_department,
            size: 72, color: AppTheme.grisGranite.withAlpha(80)),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          t.fireRisk.empty.title,
          style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.grisGranite),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          t.fireRisk.empty.message,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.grisGranite.withAlpha(180)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers partages
// ---------------------------------------------------------------------------

/// Couleur semantique d'un niveau de risque 0-5 (parite GR20 `_fireColor`).
///
/// Hors peau : tokens semantiques stables d'AppTheme (mappes sur la palette
/// StepWays). Niveau 5 « Extreme » = rouge sombre (parite GR20 `0xFF8B0000`).
Color fireRiskColor(int level) {
  switch (level) {
    case 1:
      return AppTheme.vertFacile;
    case 2:
      return AppTheme.jauneModere;
    case 3:
      return AppTheme.orangeDifficile;
    case 4:
      return AppTheme.rougeUrgence;
    case >= 5:
      return const Color(0xFF8B0000);
    default:
      return AppTheme.grisGranite;
  }
}

/// Libelle d'un jour (parite GR20 : Aujourd'hui / Demain / J+n), resolu via Slang.
String _dayLabel(int index, Translations t) {
  if (index == 0) return t.fireRisk.day.today;
  if (index == 1) return t.fireRisk.day.tomorrow;
  return t.fireRisk.day.plus(n: index);
}

/// Libelle d'un numero universel (18/112) resolu via Slang depuis sa cle stable.
String _universalLabel(String key, Translations t) {
  switch (key) {
    case FireEmergencyLabelKeys.firefighters:
      return t.fireRisk.number.firefighters;
    case FireEmergencyLabelKeys.europeanEmergency:
      return t.fireRisk.number.europeanEmergency;
    default:
      return key;
  }
}

/// Formate une date en JJ/MM/AAAA HH:MM (parite GR20 `_formatDate`).
String _formatDate(DateTime dt) {
  return '${dt.day.toString().padLeft(2, '0')}/'
      '${dt.month.toString().padLeft(2, '0')}/'
      '${dt.year} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

/// Formate une duree en texte lisible via Slang (parite GR20 `_formatDuration`).
String _formatDuration(Duration diff, Translations t) {
  if (diff.inMinutes < 1) return t.fireRisk.duration.seconds;
  if (diff.inMinutes < 60) return t.fireRisk.duration.minutes(n: diff.inMinutes);
  if (diff.inHours < 24) return t.fireRisk.duration.hours(n: diff.inHours);
  return t.fireRisk.duration.days(n: diff.inDays);
}

/// Ouvre une URL en application externe (parite GR20 : lien prefecture).
Future<void> _openUrl(String urlStr) async {
  final uri = Uri.parse(urlStr);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
