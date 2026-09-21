import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/map/test_inert_tile_provider.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/paywall_sheet.dart';
import '../data/photo_service.dart';
import '../domain/models/journal_entry.dart';
import '../providers/journal_day_providers.dart';
import '../providers/journal_providers.dart';

/// Ecran principal du journal de trek (E3.1c).
///
/// Affiche toutes les notes et photos du randonneur,
/// groupees par jour (date decroissante).
/// Utilise select() partout -- zero ref.watch brut dans build.
/// Tout texte via Slang (t.journal.*).
///
/// PAYANT (correctif L7-3) : le journal fait partie du pack du sentier. Le
/// verrou passe par la SOURCE UNIQUE d'acces, [isDemoModeProvider] — la meme
/// que l'entrainement, la seule qui soit reellement branchee en production.
///
/// DEUX PIEGES EVITES ICI, et ils valent d'etre ecrits :
///  1. NE PAS COPIER LA REFERENCE. Son `PremiumGate` pose sur le journal ne
///     bloque rien : la route ne lui passe pas de contexte, le defaut est pris,
///     et la resolution d'acces rend systematiquement l'acces complet. Le
///     recopier aurait produit un paywall DECORATIF.
///  2. NE PAS S'APPUYER SUR `hasJournal`. Le drapeau existe dans
///     [TrailFeatures], mais toute cette structure (et `featuresForTrail`) n'est
///     appelee NULLE PART dans l'application : c'est un cul-de-sac. S'y brancher
///     aurait verrouille sur une valeur que personne ne calcule.
///
/// FAIL-CLOSED : tant que l'acces est indetermine (chargement) ou en erreur,
/// l'ecran ne montre PAS le contenu. Un journal qui s'ouvre une demi-seconde
/// avant de se verrouiller, c'est un verrou qui ne verrouille pas.
///
/// HORS-LIGNE : [isDemoModeProvider] derive des droits Drift LOCAUX, sans aucun
/// appel reseau — un payeur n'est jamais bloque faute de reseau.
class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Acces REACTIF (L7-3) : il se reevalue des qu'un achat pose le droit.
    final accesAsync = ref.watch(isDemoModeProvider(trailId));
    return accesAsync.when(
      loading: () => const _JournalShell(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _JournalShell(
        child: _LockedJournalView(trailId: trailId),
      ),
      data: (isDemo) => isDemo
          ? _JournalShell(child: _LockedJournalView(trailId: trailId))
          : _UnlockedJournal(trailId: trailId),
    );
  }
}

/// Coque commune des etats non deverrouilles : meme en-tete que le journal
/// ouvert, aucun bouton d'ajout (on n'ecrit pas dans un journal verrouille).
class _JournalShell extends StatelessWidget {
  const _JournalShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeader(title: t.journal.title),
      body: SafeArea(child: child),
    );
  }
}

/// Vue VERROUILLEE (L7-3) : on dit ce que le journal apporte et on propose de
/// le debloquer. Aucune entree du journal n'est lue ni affichee ici.
class _LockedJournalView extends ConsumerWidget {
  const _LockedJournalView({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trail = ref.watch(trailConfigProvider);
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock, color: theme.colorScheme.primary, size: 22),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      t.journal.lockedTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(t.journal.lockedBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: AppTheme.spacingBase),
              AppButton(
                icon: Icons.lock_open,
                label: t.journal.lockedUnlock,
                onPressed: () => showPaywallSheet(
                  context,
                  trailId: trailId,
                  totalStages: trail.totalStages,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Journal DEVERROUILLE : le contenu d'origine, inchange.
class _UnlockedJournal extends ConsumerWidget {
  const _UnlockedJournal({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() pour ne reconstruire que sur changement de isLoading
    final isLoading = ref.watch(
      journalScreenProvider.select((s) => s.isLoading),
    );
    // select() pour ne reconstruire que sur changement du nombre d entrees
    final entryCount = ref.watch(
      journalScreenProvider.select((s) => s.entries.length),
    );

    // R10 (LOT L10) : nombre d'etapes REEL du sentier courant — remplace le
    // `16` en dur (compte du GR20) du selecteur d'etape. Cf.
    // [journalStageCountProvider].
    final stageCount = ref.watch(journalStageCountProvider(trailId));

    final theme = Theme.of(context);
    final journalT = t.journal;

    return Scaffold(
      // Ph5 (L6a) : AppHeader universel ([Retour]+[Accueil] contextuel). Le
      // badge du nombre d'entrees est passe en `actions` (rendu avant Accueil).
      // Ecran cœur -> pas de barre contextuelle (§4).
      appBar: AppHeader(
        title: journalT.title,
        actions: [
          if (entryCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingBase),
              child: Center(
                child: Text(
                  entryCount.toString(),
                  style: theme.textTheme.labelLarge,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : entryCount == 0
          ? _EmptyJournalView(journalT: journalT)
          : const _JournalDayView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context, ref, stageCount),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, WidgetRef ref, int stageCount) {
    final journalT = t.journal;
    // Capture AVANT tout await : le dialogue se referme avant la fin de la
    // sauvegarde, son `context` ne doit donc pas servir a afficher l'erreur.
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => _AddNoteDialogSlang(
        journalT: journalT,
        stageCount: stageCount,
        onSave: (stageNumber, content, photoPath) async {
          final notifier = ref.read(journalScreenProvider.notifier);
          if (photoPath == null) {
            await notifier.addNote(stageNumber: stageNumber, content: content);
            return;
          }
          // R10 (LOT L10) : entree AVEC photo. L'erreur eventuelle (quota du
          // jour, photo trop lourde, disque) est REMONTEE a l'utilisateur —
          // jamais avalee en silence.
          final error = await notifier.addPhotoNote(
            stageNumber: stageNumber,
            content: content,
            sourcePath: photoPath,
          );
          if (error == null) return;
          messenger.showSnackBar(
            SnackBar(content: Text(_photoErrorLabel(journalT, error))),
          );
        },
      ),
    );
  }

  /// Libelle Slang correspondant a un echec d'ajout de photo.
  static String _photoErrorLabel(
    Translations$journal$fr journalT,
    PhotoError error,
  ) {
    switch (error) {
      case PhotoError.dailyLimitReached:
        return journalT.photoLimit;
      case PhotoError.tooLarge:
        return journalT.photoTooBig;
      case PhotoError.fileNotFound:
      case PhotoError.ioError:
        return journalT.photoError;
    }
  }
}

/// Vue etat vide -- aucune note dans le journal.
class _EmptyJournalView extends StatelessWidget {
  const _EmptyJournalView({required this.journalT});

  final Translations$journal$fr journalT;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: AppTheme.spacingLg),
          Text(journalT.empty, style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppTheme.spacingSm),
          Text(journalT.emptySubtitle, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Vue d'UNE journee de journal : navigateur de jour + entrees du jour.
///
/// CORRECTIF L4-1 — changement structurel du journal. L'ecran deroulait
/// auparavant toutes les journees dans une seule liste : il n'avait AUCUNE
/// notion de jour selectionne. Sans elle, ni la trace du jour (L4-2) ni le
/// resume chiffre du jour (L4-3) n'ont de sens. Le journal se lit desormais
/// une journee a la fois, comme un carnet qu'on feuillette.
class _JournalDayView extends ConsumerWidget {
  const _JournalDayView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(journalDaysProvider);
    final index = ref.watch(journalSelectedDayIndexProvider);
    final entries = ref.watch(journalEntriesOfDayProvider);
    final journalT = t.journal;

    if (days.isEmpty) return _EmptyJournalView(journalT: journalT);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DayNavigator(days: days, index: index, journalT: journalT),
        const Divider(height: 1),
        // Une SEULE liste defilante pour la journee : la carte et les notes
        // defilent ensemble. Deux zones de defilement imbriquees sur un
        // ecran de telephone rendent le geste illisible.
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              const _DayTraceCard(),
              const _DaySummaryCard(),
              const SizedBox(height: AppTheme.spacingBase),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: Text(
                    journalT.dayEmpty,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...entries.map((e) => _JournalEntryTile(entry: e)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hauteur de la carte du trace du jour, en points (valeur de parite).
const double _dayTraceMapHeight = 200;

/// Trace GPS de la journee affichee (CORRECTIF L4-2).
///
/// Ne devient visible que si la journee porte VRAIMENT des points : une
/// carte vide au-dessus des notes ferait croire a une panne. Depend du
/// socle L3-1 — avant lui, la trace d'une journee passee n'existait plus
/// en base, elle etait effacee au demarrage de la randonnee suivante.
class _DayTraceCard extends ConsumerWidget {
  const _DayTraceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journalT = t.journal;
    final traceAsync = ref.watch(journalDayTraceProvider);

    return traceAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (points) {
        if (points.length < 2) return const SizedBox.shrink();
        final latLngs =
            points.map((p) => LatLng(p.lat, p.lng)).toList(growable: false);
        return AppCard(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.route_outlined,
                      size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    journalT.dayTrace,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                child: SizedBox(
                  height: _dayTraceMapHeight,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCameraFit: CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(latLngs),
                        padding: const EdgeInsets.all(24),
                      ),
                      // Vignette de lecture, pas un ecran de navigation :
                      // aucun geste, pour ne pas voler le defilement de la
                      // liste des notes sous le doigt.
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.moteur-gr.app',
                        // En test, fournisseur inerte : aucune requete
                        // reseau. En production, `null` -> fournisseur par
                        // defaut, comportement inchange.
                        tileProvider: inertTileProviderOrNull(),
                      ),
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: latLngs,
                            strokeWidth: 3,
                            color: theme.colorScheme.primary,
                          ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          _traceDot(latLngs.first, theme.colorScheme.primary),
                          _traceDot(latLngs.last, theme.colorScheme.tertiary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Pastille de depart / d'arrivee du trace.
  static Marker _traceDot(LatLng at, Color color) => Marker(
        point: at,
        width: 16,
        height: 16,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      );
}

/// Resume chiffre de la journee affichee + cumul depuis le depart
/// (CORRECTIF L4-3).
///
/// Les chiffres sont MESURES sur la trace GPS du jour, jamais deduits d'une
/// somme d'etapes nominale : une etape entamee et non finie, un aller-retour
/// a la source, un detour par un refuge, rien de tout cela n'apparait dans
/// un total theorique. Sans trace, la carte disparait au lieu d'afficher
/// des zeros qui auraient l'air vrais.
class _DaySummaryCard extends ConsumerWidget {
  const _DaySummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final journalT = t.journal;
    final dayAsync = ref.watch(journalDayStatsProvider);
    final cumulativeAsync = ref.watch(journalCumulativeStatsProvider);

    return dayAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (day) {
        if (!day.hasData) return const SizedBox.shrink();
        final cumulative = cumulativeAsync.value;
        return Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingBase),
          child: AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.insights_outlined,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      journalT.daySummary,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                _StatsRow(stats: day, journalT: journalT),
                if (cumulative != null && cumulative.hasData) ...[
                  const Divider(height: AppTheme.spacingLg),
                  Text(
                    journalT.sinceStart,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  _StatsRow(stats: cumulative, journalT: journalT),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Une ligne de quatre chiffres : distance, D+, D-, duree.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.journalT});

  final JournalDayStats stats;
  final Translations$journal$fr journalT;

  @override
  Widget build(BuildContext context) {
    final h = stats.duration.inHours;
    final m = stats.duration.inMinutes.remainder(60);
    // [Wrap] et non [Row] : en allemand et en espagnol, quatre libelles
    // cote a cote debordent la largeur d'un telephone.
    return Wrap(
      spacing: AppTheme.spacingLg,
      runSpacing: AppTheme.spacingSm,
      children: [
        _StatTile(
          label: journalT.distance,
          value: '${stats.distanceKm.toStringAsFixed(1)} km',
        ),
        _StatTile(
          label: journalT.elevationGain,
          value: '${stats.elevationGainM} m',
        ),
        _StatTile(
          label: journalT.elevationLoss,
          value: '${stats.elevationLossM} m',
        ),
        _StatTile(
          label: journalT.duration,
          value: h > 0 ? '$h h $m' : '$m min',
        ),
      ],
    );
  }
}

/// Un chiffre et son libelle.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: theme.textTheme.titleMedium),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withAlpha(150),
          ),
        ),
      ],
    );
  }
}

/// Navigateur de journee : jour precedent, date en clair, jour suivant.
///
/// Les fleches sont DESACTIVEES aux extremites plutot que masquees : un
/// bouton qui disparait deplace la date sous le doigt du randonneur.
class _DayNavigator extends ConsumerWidget {
  const _DayNavigator({
    required this.days,
    required this.index,
    required this.journalT,
  });

  final List<DateTime> days;
  final int index;
  final Translations$journal$fr journalT;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // StepWays L7 (A) : date localisee sur la langue de l'app (au lieu de
    // 'fr_FR' fige). `initializeDateFormatting` (main) charge les 5 locales.
    final dateFormat = DateFormat(
      'EEEE d MMMM yyyy',
      LocaleSettings.currentLocale.languageCode,
    );
    final notifier = ref.read(journalSelectedDayRawProvider.notifier);
    final hasPrevious = index > 0;
    final hasNext = index < days.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: journalT.dayNavPrevious,
            onPressed: hasPrevious ? () => notifier.select(days[index - 1]) : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  dateFormat.format(days[index]),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    journalT.dayOfTrek(day: index + 1),
                    journalT.dayCounter(
                      index: index + 1,
                      total: days.length,
                    ),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: journalT.dayNavNext,
            onPressed: hasNext ? () => notifier.select(days[index + 1]) : null,
          ),
        ],
      ),
    );
  }
}

/// Hauteur de la miniature photo d'une entree de journal, en points.
/// Valeur de PARITE GR20 (`trek_journal_screen.dart`).
const double _entryPhotoHeight = 120;

/// Texte partage pour une entree de journal (CORRECTIF L4-4).
///
/// Fonction PURE, donc testable sans toucher a la feuille de partage du
/// systeme : date lisible, etape, puis la note. Une entree photo sans
/// texte donne un en-tete seul — jamais une chaine vide, qui ferait
/// apparaitre un partage muet.
String journalShareText(JournalEntryModel entry, Translations$journal$fr journalT) {
  final dateFormat = DateFormat(
    'EEEE d MMMM yyyy',
    LocaleSettings.currentLocale.languageCode,
  );
  final header = [
    dateFormat.format(entry.createdAt),
    [journalT.stage, entry.stageNumber.toString()].join(' '),
  ].join(' — ');
  if (entry.text.trim().isEmpty) return header;
  return [header, entry.text.trim()].join('\n\n');
}

/// Ouvre la feuille de partage du systeme pour une entree de journal.
///
/// La photo part AVEC le texte quand elle existe vraiment sur le disque :
/// une entree dont le fichier a disparu se partage en texte seul plutot
/// que d'echouer. share_plus est deja en production ailleurs dans l'app
/// (carte de partage, resume de plan) — aucune dependance ajoutee.
Future<void> _shareEntry(
  JournalEntryModel entry,
  Translations$journal$fr journalT,
  ScaffoldMessengerState messenger,
) async {
  final text = journalShareText(entry, journalT);
  try {
    final path = entry.photoPath;
    if (path != null && File(path).existsSync()) {
      await Share.shareXFiles(
        [XFile(path)],
        text: text,
        subject: journalT.shareSubject,
      );
      return;
    }
    await Share.share(text, subject: journalT.shareSubject);
  } catch (_) {
    messenger.showSnackBar(SnackBar(content: Text(journalT.shareError)));
  }
}

/// Tuile d une entree de journal (note ou photo).
///
/// Affiche l heure, l etape, le contenu, et la photo si presente.
/// Actions : supprimer via le menu contextuel.
class _JournalEntryTile extends ConsumerWidget {
  const _JournalEntryTile({required this.entry});

  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm');
    final journalT = t.journal;
    final stageLabel = [journalT.stage, entry.stageNumber.toString()].join(' ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.terrain, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingXs),
              Text(
                stageLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                timeFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    ref
                        .read(journalScreenProvider.notifier)
                        .deleteEntry(entry.id);
                    return;
                  }
                  if (value == 'share') {
                    // CORRECTIF L4-4 : le messenger est capture AVANT tout
                    // await — la feuille de partage ferme le menu, son
                    // `context` ne peut plus servir a afficher l'erreur.
                    _shareEntry(
                      entry,
                      journalT,
                      ScaffoldMessenger.of(context),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text(journalT.share),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(journalT.delete),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // ORDRE : le TEXTE d'abord, la PHOTO en dernier — parite GR20
          // (`trek_journal_screen.dart` : le texte de l'entree est rendu juste
          // sous l'en-tete, la miniature ferme la carte). L'ordre inverse
          // (photo puis texte) rejetait la note tout en bas de la carte, collee
          // au bord sous une image trop haute : illisible (QA Skynet, L10).
          if (entry.text.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(entry.text, style: theme.textTheme.bodyMedium),
          ],
          // MINIATURE PHOTO — parite GR20 stricte : 120 px de haut (et non
          // 200, qui mangeait la carte et coupait brutalement l'image), le
          // cadrage etant porte par un [SizedBox] et non par l'`Image` (sinon
          // l'image impose sa propre hauteur avant le clip). `cacheWidth`
          // limite la memoire : une photo d'appareil est decodee en version
          // reduite, pas en pleine resolution, pour une bande de 120 px.
          if (entry.photoPath != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              child: SizedBox(
                height: _entryPhotoHeight,
                width: double.infinity,
                child: Image.file(
                  File(entry.photoPath!),
                  fit: BoxFit.cover,
                  cacheWidth: 480,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 32),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialogue d ajout de note avec textes Slang.
///
/// R10 (LOT L10) : le dialogue sait desormais porter une PHOTO (appareil photo
/// ou galerie, parite GR20) et son selecteur d'etape suit le nombre REEL
/// d'etapes du sentier ([stageCount]) au lieu d'un 16 en dur.
class _AddNoteDialogSlang extends StatefulWidget {
  const _AddNoteDialogSlang({
    required this.journalT,
    required this.stageCount,
    required this.onSave,
  });

  final Translations$journal$fr journalT;

  /// Nombre d'etapes proposees dans le selecteur (>= 1).
  final int stageCount;

  /// [photoPath] : fichier source choisi, `null` pour une note sans photo.
  final void Function(int stageNumber, String content, String? photoPath)
      onSave;

  @override
  State<_AddNoteDialogSlang> createState() => _AddNoteDialogSlangState();
}

/// Cote (en points) de la vignette d'apercu de la photo dans le dialogue.
/// Valeur FINIE volontairement (cf. commentaire de l'apercu).
const double _photoPreviewSize = 96;

class _AddNoteDialogSlangState extends State<_AddNoteDialogSlang> {
  final _contentController = TextEditingController();
  int _stageNumber = 1;

  /// Fichier choisi par l'utilisateur, pas encore compresse ni copie en local
  /// (c'est `PhotoService` qui le fera a l'enregistrement).
  String? _photoPath;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// Demande la SOURCE (appareil photo / galerie), parite GR20
  /// (`_showPhotoSourceDialog`), puis ouvre le selecteur correspondant.
  Future<void> _choosePhotoSource() async {
    final journalT = widget.journalT;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Text(
                journalT.photoSource,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(journalT.camera),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(journalT.gallery),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    // Pre-redimensionnement a la prise : evite de trimballer un original de
    // plusieurs Mo jusqu'a la compression (limite finale 500 Ko cote
    // PhotoService, qui reste la seule autorite sur la taille stockee).
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;
    setState(() => _photoPath = picked.path);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final journalT = widget.journalT;

    return AlertDialog(
      title: Text(journalT.addNote),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(journalT.stage, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            // R10 (LOT L10) : le selecteur suit le sentier COURANT. Le `16` en
            // dur (compte du GR20) laissait choisir des etapes inexistantes sur
            // un sentier a 7, 12 ou 5 etapes.
            DropdownButtonFormField<int>(
              initialValue: _stageNumber,
              items: List.generate(widget.stageCount, (i) => i + 1)
                  .map(
                    (n) => DropdownMenuItem(
                      value: n,
                      child: Text([journalT.stage, n.toString()].join(' ')),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _stageNumber = value);
                }
              },
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(journalT.yourNote, style: theme.textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(hintText: journalT.placeholder),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            // R10 (LOT L10) — AJOUT DE PHOTO (parite GR20). Sans ce bloc, une
            // entree ne pouvait porter que du texte, et la galerie du Diplome
            // (qui filtre les entrees avec photo) restait toujours vide.
            if (_photoPath == null)
              OutlinedButton.icon(
                onPressed: _choosePhotoSource,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(journalT.addPhoto),
              )
            else
              // APERCU EN VIGNETTE DE TAILLE FIXE — ET SURTOUT PAS de largeur
              // `double.infinity` ici : `AlertDialog` enveloppe sa colonne dans
              // un `IntrinsicWidth`, et une largeur infinie remontee par la
              // passe d'intrinseques fait degenerer la mesure — le dialogue se
              // dessine alors COMPLETEMENT VIDE (titre compris), sans la
              // moindre exception Dart. Constate sur emulateur au LOT L10.
              // Toutes les dimensions de ce bloc restent donc FINIES.
              // [Wrap] et non [Row] : selon la langue, « Retirer la photo » et
              // la vignette peuvent depasser la largeur du dialogue (constate :
              // debordement de 5,9 px en francais). Le Wrap fait passer le
              // bouton a la ligne au lieu de deborder — zero bandeau jaune et
              // noir, quelle que soit la traduction ou la taille de police.
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppTheme.spacingMd,
                runSpacing: AppTheme.spacingSm,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    child: Image.file(
                      File(_photoPath!),
                      width: _photoPreviewSize,
                      height: _photoPreviewSize,
                      fit: BoxFit.cover,
                      // Decode a la taille d'affichage : une photo d'appareil
                      // fait plusieurs milliers de pixels de cote, inutile de
                      // la monter en memoire en pleine resolution pour une
                      // vignette.
                      cacheWidth: (_photoPreviewSize * 3).round(),
                      errorBuilder: (_, __, ___) => Container(
                        width: _photoPreviewSize,
                        height: _photoPreviewSize,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _photoPath = null),
                    icon: const Icon(Icons.close),
                    label: Text(journalT.removePhoto),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(journalT.cancel),
        ),
        AppButton(
          label: journalT.save,
          isFullWidth: false,
          onPressed: () {
            final content = _contentController.text.trim();
            // Une PHOTO SEULE est une entree valide (parite GR20) : on
            // n'exige plus du texte des lors qu'une photo est jointe.
            if (content.isEmpty && _photoPath == null) return;
            widget.onSave(_stageNumber, content, _photoPath);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
