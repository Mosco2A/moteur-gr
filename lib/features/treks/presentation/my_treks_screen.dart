import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_selection.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/routing/contextual_actions_provider.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/contextual_action_bar.dart';
import '../../../shared/widgets/contextual_bottom_bar.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../hub/presentation/widgets/hub_section.dart';
import '../../hub/presentation/widgets/quick_access_card.dart';
import '../domain/trek_lifecycle_state.dart';
import '../domain/trek_summary.dart';
import '../providers/my_treks_provider.dart';
import 'widgets/trek_summary_card.dart';
import '../../../core/branding/stepways_icons.dart';

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
    // Q2 (tache 568) — `push` ET NON `go`. Le `go` REMPLACAIT la pile : une
    // fois au catalogue il n'y avait plus d'historique, et le retour (bouton
    // comme geste systeme Android) retombait sur l'accueil contextuel, donc
    // sur le COCKPIT d'un sentier non choisi — le defaut de Chris du 26/09.
    // En empilant, le retour DEPILE naturellement vers « Mes treks ».
    ContextualAction(
      icon: StepwaysIcons.catalogueSentiers,
      label: t.myTreks.discoverTitle,
      onPressed: () => context.push('/catalog'),
    ),
    ContextualAction(
      icon: StepwaysIcons.monCompte,
      label: t.myTreks.accountTitle,
      onPressed: () => context.push('/profile'),
    ),
    // Finitions V1 (point 1) : acces REGLAGES depuis l'accueil « maison ».
    // Le big-bang hub-and-push (L3) a retire l'onglet « Plus », seule porte
    // vers /settings -> langue/unites/theme/confidentialite etaient perdus
    // apres l'onboarding. On retablit l'acces ici (SPEC §4 : reglages dans
    // l'aire « Mon compte » de l'accueil). push -> retour propre.
    ContextualAction(
      icon: StepwaysIcons.reglages,
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
        // ETAT VIDE : LE CAS NORMAL DU PREMIER LANCEMENT (tache 638).
        //
        // CE COMMENTAIRE DISAIT LE CONTRAIRE, ET IL AVAIT CESSE D ETRE VRAI. Il
        // annoncait un « cas theorique — la vitrine en fournit au moins un ».
        // La vitrine a disparu avec le lot 601, et le dernier sentier gratuit du
        // catalogue avec la tache 638 : un randonneur qui n a rien achete n a
        // donc AUCUN trek, et c est VOULU. Scenario d acceptation de Christophe
        // du 29/09 14:17, verbatim : « la prochaine fois que j ouvre
        // l application je n ai droit a rien ».
        //
        // UN ACCUEIL VIDE QUI EXPLIQUE N EST PAS UNE PANNE. L ecran dit qu il n y
        // a pas encore de sentier et renvoie vers le catalogue — ou vers la demo,
        // qui est en tete du catalogue. Le texte SUIT le reglage « cacher le mode
        // demo » : promettre une demo en tete de liste a qui l a masquee serait
        // un mensonge, exactement celui que le dialogue de sortie evite deja.
        //
        // Reutilise le widget maison [EmptyState] (meme grammaire que le
        // catalogue vide) ; le bandeau « Decouvrir / Mon compte » en bas de liste
        // reste present, et le bouton d ici est la porte saillante.
        if (isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXl),
            child: EmptyState(
              icon: StepwaysIcons.catalogueSentiers,
              title: t.myTreks.emptyTitle,
              subtitle: ref.watch(boutonDemoCacheProvider)
                  ? t.myTreks.emptyCatalogueSeul
                  : t.myTreks.emptyCatalogueOuDemo,
              action: AppButton(
                key: const ValueKey('my-treks-empty-discover'),
                icon: StepwaysIcons.catalogueSentiers,
                iconSize: 18,
                label: t.myTreks.discoverTitle,
                isFullWidth: false,
                // Q2 (tache 568) : `push`, pour que le retour depile vers ici.
                onPressed: () => context.push('/catalog'),
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
            icon: StepwaysIcons.catalogueSentiers,
            cards: [
              QuickAccessCard(
                icon: StepwaysIcons.catalogueSentiers,
                title: t.myTreks.discoverTitle,
                subtitle: t.myTreks.discoverSubtitle,
                // Q2 (tache 568) : `push`, pour que le retour depile vers ici.
                onTap: () => context.push('/catalog'),
              ),
              QuickAccessCard(
                icon: StepwaysIcons.monCompte,
                title: t.myTreks.accountTitle,
                subtitle: t.myTreks.accountSubtitle,
                onTap: () => context.push('/profile'),
              ),
              // Finitions V1 (point 1) : carte REGLAGES dans le bandeau « Mon
              // compte » (SPEC §4). Rend langue/unites/theme/confidentialite
              // atteignables depuis l'accueil apres l'onboarding (l'onglet
              // « Plus », seule porte historique, a disparu au big-bang L3).
              QuickAccessCard(
                icon: StepwaysIcons.reglages,
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
    // Bascule resolue AVANT la navigation (cf. [choisirSentier]).
    choisirSentier(ref, id);
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
