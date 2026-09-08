import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../hub/presentation/widgets/hub_section.dart';
import '../../hub/presentation/widgets/quick_access_card.dart';
import '../domain/trek_lifecycle_state.dart';
import '../domain/trek_summary.dart';
import '../providers/my_treks_provider.dart';
import 'widgets/trek_summary_card.dart';

/// Ecran d'accueil « Mes treks » (StepWays LOT 2, Phase 4 / §2).
///
/// Nouvelle entree de l'onglet Accueil (option A) : liste les treks POSSEDES de
/// l'utilisateur ([myTreksProvider]) repartis en sections — **En cours** (0/1,
/// invariant C4) · **Préparés** (prepared + juste possedes) · **Terminés** —
/// puis un bandeau « Découvrir / Mon compte » (reutilise [HubSection], comme le
/// HUB). Selectionner un trek ecrit [selectedTrailIdProvider] et bascule vers le
/// cockpit `/home` (geste eprouve du catalogue) : tout le contexte du sentier
/// suit alors la selection ([trailConfigProvider] en derive).
///
/// Zero texte en dur (Slang `myTreks.*` / `nav.*`), zero localite hardcodee — le
/// contenu vient integralement du provider. Etats loading/erreur/vide geres.
class MyTreksScreen extends ConsumerWidget {
  const MyTreksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final treksAsync = ref.watch(myTreksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.myTreks.title)),
      body: treksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              '$error',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        data: (treks) => _MyTreksBody(treks: treks),
      ),
    );
  }
}

/// Corps de l'ecran une fois les treks charges : sections d'etat + bandeau.
class _MyTreksBody extends ConsumerWidget {
  const _MyTreksBody({required this.treks});

  final List<TrekSummary> treks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    // Repartition par etat (le provider a deja trie la liste globale ; on
    // conserve l'ordre relatif de chaque groupe). « owned » (juste possede,
    // rien fait) rejoint « Préparés » a l'affichage : ce sont les treks pas
    // encore engages mais pas termines.
    final inProgress = <TrekSummary>[];
    final prepared = <TrekSummary>[];
    final completed = <TrekSummary>[];
    for (final s in treks) {
      switch (s.state) {
        case TrekLifecycleState.inProgress:
          inProgress.add(s);
        case TrekLifecycleState.prepared:
        case TrekLifecycleState.owned:
          prepared.add(s);
        case TrekLifecycleState.completed:
          completed.add(s);
      }
    }

    final isEmpty = treks.isEmpty;

    return ListView(
      key: const ValueKey('my-treks-list'),
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
      children: [
        // Etat vide : aucun trek possede (cas theorique — la vitrine en fournit
        // au moins un — mais l'ecran ne doit jamais paraitre casse).
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              t.myTreks.empty,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.grisGranite,
                  ),
            ),
          ),

        _TrekSection(
          title: t.myTreks.sectionInProgress,
          summaries: inProgress,
          onSelect: (id) => _selectTrek(ref, context, id),
        ),
        _TrekSection(
          title: t.myTreks.sectionPrepared,
          summaries: prepared,
          onSelect: (id) => _selectTrek(ref, context, id),
        ),
        _TrekSection(
          title: t.myTreks.sectionCompleted,
          summaries: completed,
          onSelect: (id) => _selectTrek(ref, context, id),
        ),

        // Bandeau « Découvrir / Mon compte » : reutilise HubSection (grille 2
        // cartes) — meme grammaire visuelle que le HUB.
        const SizedBox(height: AppTheme.spacingLg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: HubSection(
            title: t.nav.myTreks,
            icon: Icons.explore_outlined,
            cards: [
              QuickAccessCard(
                icon: Icons.explore_outlined,
                title: t.myTreks.discoverTitle,
                subtitle: t.myTreks.discoverSubtitle,
                onTap: () => context.go('/catalog'),
              ),
              QuickAccessCard(
                icon: Icons.person_outline,
                title: t.myTreks.accountTitle,
                subtitle: t.myTreks.accountSubtitle,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }

  /// Selectionne le trek [id] : ecrit la selection puis bascule vers le cockpit
  /// (`/home`). Geste eprouve du catalogue — toute l'app suit le sentier choisi.
  void _selectTrek(WidgetRef ref, BuildContext context, String id) {
    ref.read(selectedTrailIdProvider.notifier).state = id;
    context.go('/home');
  }
}

/// Une section d'etat (titre + liste de [TrekSummaryCard]). Masquee si vide
/// pour ne pas afficher un en-tete orphelin.
class _TrekSection extends StatelessWidget {
  const _TrekSection({
    required this.title,
    required this.summaries,
    required this.onSelect,
  });

  final String title;
  final List<TrekSummary> summaries;
  final void Function(String trailId) onSelect;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingXs,
          ),
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        for (final summary in summaries)
          TrekSummaryCard(
            summary: summary,
            onTap: () => onSelect(summary.trailId),
          ),
      ],
    );
  }
}
