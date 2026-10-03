/// Un assistant nuit par nuit sur le PROGRAMME du sentier : un type
/// d'hebergement par nuit, pas une reservation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../domain/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';
import '../../../domain/stage_accommodation.dart';
import '../domain/models/nuitee_type.dart';
import '../providers/nuitee_selections_provider.dart';
import 'widgets/nuitee_card_parts.dart';
import '../../../core/branding/stepways_icons.dart';

/// Ecran NUITEES — assistant « Reserver vos nuits » (PARITE GR20
/// `RefugeAssistantScreen`).
///
/// Assistant par nuit : pour chaque nuit du PROGRAMME du sentier courant,
/// l'utilisateur choisit un TYPE de nuitee (refuge / gite / bivouac / autre) et
/// coche l'etat reserve / a reserver. Bandeau de progression en haut, recap en
/// bas. Les donnees d'hebergement (nom du lieu, telephone) proviennent des
/// donnees du sentier (module `booking` -> [StageAccommodation] via Drift),
/// avec fallback gracieux si le sentier n'a pas d'hebergement reference.
///
/// Ecarts de modele vs GR20 : le [PlannedDay] StepWays ne porte pas de
/// `nightCount` multiple ; chaque jour de marche = une nuit. StepWays n'a pas
/// non plus de compteur de progression « planning » (pas d'equivalent
/// `planningProgressProvider`) : le bandeau affiche la progression locale
/// (reserve / total) mais ne coche pas d'etape de preparation globale.
///
/// La NUIT N0 (veille du depart), qui figurait encore dans cette liste
/// d'ecarts, est RATTRAPEE par le correctif L7-2 (cf. [buildNuiteeSlots]).
///
/// Generique multi-sentiers : ZERO hardcode de localite ; hors systeme de peaux
/// (couleurs semantiques d'AppTheme + colorScheme). Tout libelle passe par Slang
/// (`t.nuitees.*`).
/// Une NUIT du programme : le jour concerne + le numero d'etape dont depend le
/// LIEU de couchage.
///
/// Pour un jour de MARCHE, c'est son etape d'arrivee. Pour un jour de REPOS,
/// c'est l'etape d'arrivee du dernier jour marche : on dort au meme endroit que
/// la veille (R5, LOT L10).
class NuiteeSlot {
  const NuiteeSlot({
    required this.day,
    required this.stageNumber,
    this.isEveOfDeparture = false,
  });

  final PlannedDay day;

  /// Etape dont on tire l'hebergement (0 si le programme commence par un repos,
  /// et 0 pour la nuit N0 : on ne dort encore au bout d'aucune etape).
  final int stageNumber;

  /// Nuit N0, la veille du depart (correctif L7-2). Elle n'appartient a aucun
  /// jour de marche : son [day] est un jour synthetique numerote 0.
  final bool isEveOfDeparture;
}

/// Numero de jour reserve a la nuit N0 (veille du depart, correctif L7-2).
///
/// Les jours du programme sont numerotes a partir de 1 : le 0 est donc libre
/// et sert de cle de reservation propre pour cette nuit, sans toucher au
/// modele [PlannedDay] ni au stockage des selections.
const int kEveOfDepartureDayNumber = 0;

/// Construit la liste des NUITS a reserver a partir du programme.
///
/// R5 (LOT L10) — PARITE GR20 : les jours de REPOS comptent, eux aussi, pour
/// une nuit. L'ancien filtre `!isRestDay` en faisait disparaitre une : sur un
/// programme de 7 jours dont 1 repos, seules 6 nuits etaient proposees et le
/// randonneur se retrouvait sans toit une nuit. GR20 ne supprime pas la nuit,
/// il met le jour precedent a `nightCount` 2 ; faute de `nightCount` sur
/// [PlannedDay], StepWays lui donne sa propre ligne, rattachee au lieu
/// d'arrivee du dernier jour marche.
///
/// L7-2 — LA NUIT N0, VEILLE DU DEPART, EST COMPTEE ELLE AUSSI.
///
/// On n'arrive pas au depart d'un sentier le matin de la premiere etape : on
/// arrive la veille et on dort sur place. L'assistant de reference ouvre donc
/// sa liste par cette nuit-la ; StepWays l'omettait, et son propre en-tete
/// documentait l'oubli. Resultat concret : une nuit a reserver invisible dans
/// l'assistant, exactement le meme defaut que la nuit de repos rattrapee en
/// R5 — a ceci pres que celle-ci tombe la veille du grand jour.
///
/// Elle ne se rattache a AUCUNE etape ([stageNumber] = 0) : on dort au point
/// de DEPART de la premiere etape, pas a son arrivee. Proposer l'hebergement
/// de l'arrivee serait proposer le mauvais village — la carte affiche donc son
/// libelle generique et laisse le randonneur choisir son type de nuitee.
///
/// Fonction PURE (testable sans widget).
List<NuiteeSlot> buildNuiteeSlots(List<PlannedDay> days) {
  final slots = <NuiteeSlot>[];
  if (days.isEmpty) return slots;

  // Nuit N0 : jour synthetique numerote 0, en tete de liste.
  slots.add(
    const NuiteeSlot(
      day: PlannedDay(dayNumber: kEveOfDepartureDayNumber, stages: []),
      stageNumber: 0,
      isEveOfDeparture: true,
    ),
  );

  // Dernier lieu d'arrivee connu : un repos herite du jour marche precedent.
  var lastStageNumber = 0;
  for (final day in days) {
    if (!day.isRestDay && day.stages.isNotEmpty) {
      lastStageNumber = day.stages.last.stageNumber;
    }
    slots.add(NuiteeSlot(day: day, stageNumber: lastStageNumber));
  }
  return slots;
}

class NuiteesScreen extends ConsumerWidget {
  const NuiteesScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on planifie les nuitees.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(plannedDaysProvider(trailId));
    final selections = ref.watch(nuiteeSelectionsProvider);

    // R5 (retour Chris, LOT L10) — LA NUIT DU JOUR DE REPOS EST COMPTEE.
    // Le filtre `!d.isRestDay` faisait DISPARAITRE une nuit reelle : un jour de
    // repos, on dort quand meme, au meme endroit que la veille. Un programme de
    // 7 jours dont 1 repos ne proposait que 6 nuits a reserver -> le randonneur
    // se retrouvait sans toit une nuit sur son planning. PARITE GR20 : GR20 ne
    // supprime pas la nuit, il met le jour PRECEDENT a `nightCount` 2 (deux
    // nuits au meme endroit) — la nuit est donc bien comptabilisee.
    // StepWays n'a pas de `nightCount` sur [PlannedDay] : on materialise la
    // nuit du repos par sa PROPRE ligne, rattachee au lieu d'arrivee du dernier
    // jour marche ([buildNuiteeSlots]), ce qui donne le meme total de nuits que
    // GR20 sans toucher au modele.
    final nuitees = buildNuiteeSlots(days);
    final nuiteesDays = nuitees.map((n) => n.day).toList();
    final totalNuitees = nuitees.length;
    final bookedCount = nuitees
        .where((n) => selections.isBooked(n.day.dayNumber))
        .length;
    final progress = totalNuitees > 0 ? bookedCount / totalNuitees : 0.0;

    return Scaffold(
      // Ph5 (L6b) : AppHeader universel + action (i) conservee (parite ecran).
      appBar: AppHeader(
        title: t.nuitees.title,
        actions: [
          IconButton(
            icon: const StepIcon(StepwaysIcons.info),
            tooltip: t.nuitees.guideTooltip,
            onPressed: () => _showInfoSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: nuiteesDays.isEmpty
            ? _EmptyState(trailId: trailId)
            : Column(
                children: [
                  _CompactInfoBar(
                    bookedCount: bookedCount,
                    totalNuitees: totalNuitees,
                    progress: progress,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingBase,
                        vertical: AppTheme.spacingSm,
                      ),
                      itemCount: nuitees.length,
                      itemBuilder: (context, index) {
                        final slot = nuitees[index];
                        final day = slot.day;
                        return _NuiteeCard(
                          trailId: trailId,
                          day: day,
                          stageNumber: slot.stageNumber,
                          isEveOfDeparture: slot.isEveOfDeparture,
                          isBooked: selections.isBooked(day.dayNumber),
                          nuiteeType: selections.typeFor(day.dayNumber),
                          onToggle: () => ref
                              .read(nuiteeSelectionsProvider.notifier)
                              .toggleBooking(day.dayNumber),
                          onNuiteeTypeChanged: (type) => ref
                              .read(nuiteeSelectionsProvider.notifier)
                              .setNuiteeType(day.dayNumber, type),
                        );
                      },
                    ),
                  ),
                  _CompactSummary(
                    days: nuiteesDays,
                    selections: selections,
                    bookedCount: bookedCount,
                    totalNuitees: totalNuitees,
                  ),
                ],
              ),
      ),
    );
  }

  /// Guide des types de nuitees (parite GR20 `_showInfoSheet`) : fiche par type
  /// avec icone + description, en bottom-sheet.
  void _showInfoSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Row(
              children: [
                StepIcon(StepwaysIcons.info, color: scheme.primary, size: 24),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  t.nuitees.guide.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingBase),
            _infoItem(theme, NuiteeType.refuge, t.nuitees.guide.refuge),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(theme, NuiteeType.gite, t.nuitees.guide.gite),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(theme, NuiteeType.bivouac, t.nuitees.guide.bivouac),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(
              theme,
              NuiteeType.autreHebergement,
              t.nuitees.guide.autre,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Center(
              child: AppButton(
                variant: AppButtonVariant.text,
                label: t.nuitees.guide.close,
                labelFontSize: 16,
                isFullWidth: false,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(ThemeData theme, NuiteeType type, String description) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: StepIcon(type.icon, size: 22, color: scheme.primary),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bandeau compact en haut : rappel + progression (parite GR20
/// `_CompactInfoBar`).
class _CompactInfoBar extends StatelessWidget {
  const _CompactInfoBar({
    required this.bookedCount,
    required this.totalNuitees,
    required this.progress,
  });

  final int bookedCount;
  final int totalNuitees;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = bookedCount == totalNuitees && totalNuitees > 0;
    final barColor = isDone ? AppTheme.vertFacile : AppTheme.orangeDifficile;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      color: barColor.withAlpha(20),
      child: Column(
        children: [
          Row(
            children: [
              StepIcon(
                StepwaysIcons.info,
                size: 20,
                color: theme.colorScheme.primary.withAlpha(180),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.nuitees.infoBar,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  '$bookedCount / $totalNuitees',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.grisGranite.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une nuit (parite GR20 `_RefugeCard`).
///
/// Affiche le nom reel de l'hebergement (donnees du sentier) selon le type
/// choisi, un selecteur de type (refuge / gite / bivouac / autre), l'etat
/// reserve (case), et une action Appeler quand un telephone est disponible.
/// Consomme les hebergements de l'etape via [nuiteeStageAccommodationsProvider]
/// (fallback gracieux : libelle generique si aucun hebergement reference).
class _NuiteeCard extends ConsumerWidget {
  const _NuiteeCard({
    required this.trailId,
    required this.day,
    required this.stageNumber,
    required this.isBooked,
    required this.nuiteeType,
    required this.onToggle,
    required this.onNuiteeTypeChanged,
    this.isEveOfDeparture = false,
  });

  final String trailId;
  final PlannedDay day;

  /// Nuit N0, la veille du depart (correctif L7-2) : badge et libelle propres.
  final bool isEveOfDeparture;

  /// Etape dont on tire l'hebergement du lieu de nuit. Fournie par
  /// [buildNuiteeSlots] : pour un jour de REPOS c'est l'etape d'arrivee du
  /// dernier jour marche (on dort au meme endroit que la veille), un jour de
  /// repos n'ayant par construction aucune etape a lui.
  final int stageNumber;

  final bool isBooked;
  final NuiteeType nuiteeType;
  final VoidCallback onToggle;
  final void Function(NuiteeType) onNuiteeTypeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accommodationsAsync = ref.watch(
      nuiteeStageAccommodationsProvider((
        trailId: trailId,
        stageNumber: stageNumber,
      )),
    );
    final accommodations = accommodationsAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <StageAccommodation>[],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      color: isBooked ? scheme.primary.withAlpha(20) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: isBooked
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      // GRISE EN DEMO (tache 638, bug 14) : reserver une nuit ecrit en base
      // (`NuiteeSelectionsDao`) sous l'identifiant du sentier REEL. La fiche de
      // la nuitee reste LISIBLE (c'est ce que la demo doit montrer) ; seul le
      // geste qui reserve est grise.
      child: GriseEnDemo(
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: NuiteeCardContents(
              day: day,
              accommodations: accommodations,
              nuiteeType: nuiteeType,
              isBooked: isBooked,
              isEveOfDeparture: isEveOfDeparture,
              onNuiteeTypeChanged: onNuiteeTypeChanged,
            ),
          ),
        ),
      ),
    );
  }
}

/// Recap compact en bas (parite GR20 `_CompactSummary`) : bouton de
/// confirmation si tout est reserve, sinon chips des nuits restantes.
class _CompactSummary extends StatelessWidget {
  const _CompactSummary({
    required this.days,
    required this.selections,
    required this.bookedCount,
    required this.totalNuitees,
  });

  final List<PlannedDay> days;
  final NuiteeSelectionsState selections;
  final int bookedCount;
  final int totalNuitees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bookedCount == totalNuitees && totalNuitees > 0) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: AppButton(
          icon: StepwaysIcons.cochePleine,
          iconSize: 18,
          label: t.nuitees.summary.allBooked,
          onPressed: () => context.pop(),
        ),
      );
    }

    if (days.isEmpty) return const SizedBox.shrink();

    final missingDays = days
        .where((d) => !selections.isBooked(d.dayNumber))
        .toList();
    final bookedDays = days
        .where((d) => selections.isBooked(d.dayNumber))
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.orangeDifficile.withAlpha(12),
        border: Border(
          top: BorderSide(color: AppTheme.grisGranite.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const StepIcon(
                StepwaysIcons.danger,
                size: 16,
                color: AppTheme.orangeDifficile,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                t.nuitees.summary.remaining.replaceAll(
                  '{count}',
                  missingDays.length.toString(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.orangeDifficile,
                  fontSize: 14,
                ),
              ),
              if (bookedDays.isNotEmpty) ...[
                const Spacer(),
                StepIcon(
                  StepwaysIcons.cochePleine,
                  size: 14,
                  color: AppTheme.vertFacile.withAlpha(180),
                ),
                const SizedBox(width: 4),
                Text(
                  t.nuitees.summary.done.replaceAll(
                    '{count}',
                    bookedDays.length.toString(),
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: AppTheme.vertFacile,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: missingDays.map((day) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.orangeDifficile.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(
                    color: AppTheme.orangeDifficile.withAlpha(60),
                  ),
                ),
                child: Text(
                  // L7-2 : la nuit de la veille porte son badge, pas un « J0 ».
                  day.dayNumber == kEveOfDepartureDayNumber
                      ? t.nuitees.card.eveBadge
                      : t.nuitees.card.dayLabel.replaceAll(
                          '{n}',
                          day.dayNumber.toString(),
                        ),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.orangeDifficile,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Etat vide — aucune nuit (programme non configure). Fallback gracieux :
/// invite a configurer l'itineraire (parite GR20 `_buildEmptyState`).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StepIcon(
              StepwaysIcons.nuitees,
              size: 80,
              color: AppTheme.grisGranite.withAlpha(80),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.nuitees.empty.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisGranite,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.nuitees.empty.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisGranite.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            AppButton(
              icon: StepwaysIcons.itineraire,
              iconSize: 18,
              label: t.nuitees.empty.action,
              onPressed: () => context.push('/trail/$trailId/itinerary'),
            ),
          ],
        ),
      ),
    );
  }
}
