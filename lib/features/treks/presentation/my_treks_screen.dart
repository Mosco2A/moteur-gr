import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/routing/contextual_actions_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/contextual_action_bar.dart';
import '../../../shared/widgets/contextual_bottom_bar.dart';
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
///
/// ACCUEIL MAISON (StepWays LOT 3, Ph5 — SPEC §4) : c'est l'ACCUEIL « maison »
/// (aucune rando active). Il ne porte donc PAS d'`AppHeader` (§4 : « pas de
/// header, c'est l'accueil ») — juste son `AppBar` de titre. Sa BARRE
/// CONTEXTUELLE (mecanisme L3, [ContextualActionsMixin] + [ContextualBottomBar])
/// porte les deux entrees transverses de l'accueil : **Découvrir** (-> /catalog)
/// et **Mon compte** (-> /profile), conformement a §4. Les memes acces restent
/// aussi disponibles en bas du corps (bandeau [HubSection] avec sous-titres) —
/// la barre les rend atteignables a une main (thumb zone, §11.4) sans rien
/// retirer du contenu.
class MyTreksScreen extends ConsumerStatefulWidget {
  const MyTreksScreen({super.key});

  @override
  ConsumerState<MyTreksScreen> createState() => _MyTreksScreenState();
}

class _MyTreksScreenState extends ConsumerState<MyTreksScreen>
    with ContextualActionsMixin {
  /// Barre contextuelle de l'accueil maison (SPEC §4) : Découvrir / Mon compte.
  @override
  List<ContextualAction> buildContextualActions(BuildContext context) => [
        ContextualAction(
          icon: Icons.explore_outlined,
          label: t.myTreks.discoverTitle,
          onPressed: () => context.go('/catalog'),
        ),
        ContextualAction(
          icon: Icons.person_outline,
          label: t.myTreks.accountTitle,
          onPressed: () => context.push('/profile'),
        ),
        // Finitions V1 (point 1) : acces REGLAGES depuis l'accueil « maison ».
        // Le big-bang hub-and-push (L3) a retire l'onglet « Plus », seule porte
        // vers /settings -> langue/unites/theme/confidentialite etaient perdus
        // apres l'onboarding. On retablit l'acces ici (SPEC §4 : reglages dans
        // l'aire « Mon compte » de l'accueil). push -> retour propre.
        ContextualAction(
          icon: Icons.settings_outlined,
          label: t.nav.settings,
          onPressed: () => context.push('/settings'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final treksAsync = ref.watch(myTreksProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.myTreks.title)),
      // Barre contextuelle declarative (L3) : Découvrir / Mon compte (§4).
      bottomNavigationBar: const ContextualBottomBar(),
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
              // Finitions V1 (point 1) : carte REGLAGES dans le bandeau « Mon
              // compte » (SPEC §4). Rend langue/unites/theme/confidentialite
              // atteignables depuis l'accueil apres l'onboarding (l'onglet
              // « Plus », seule porte historique, a disparu au big-bang L3).
              QuickAccessCard(
                icon: Icons.settings_outlined,
                title: t.nav.settings,
                subtitle: t.myTreks.settingsSubtitle,
                onTap: () => context.push('/settings'),
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
