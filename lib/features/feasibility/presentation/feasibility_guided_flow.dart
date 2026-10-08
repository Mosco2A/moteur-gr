/// Le parcours guide de la faisabilite : ses etapes, ce qui manque
/// encore, et la carte d une etape.
///
/// Bibliotheque de l'ecran `trek_feasibility_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../../i18n/translations.g.dart';
import '../providers/trek_feasibility_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// PARCOURS GUIDE d'entree (parite GR20) : fiche -> test 6 min -> randos,
/// barre de progression, puis bouton « Valider / Voir mon resultat ».
///
/// D1 (#100293) : ce bouton ne mene au verdict QUE si les criteres
/// obligatoires sont tous fournis. Sinon il est DESACTIVE et un encart nomme
/// ce qui manque — l'ecran ne rend aucun verdict et ne laisse pas croire
/// qu'il pourrait en rendre un. Chaque etape ouvre l'ecran de saisie existant
/// et se coche au retour. Le test 6 min alimente le calcul (R2b).
class FeasibilityGuidedFlow extends ConsumerWidget {
  const FeasibilityGuidedFlow({
    super.key,
    required this.criteria,
    required this.onOpenStep,
    required this.onValidate,
  });

  /// Completude des criteres qui conditionnent le verdict.
  final FeasibilityCriteria criteria;

  /// Ouvre un ecran de saisie (route) puis rafraichit l'evaluation au retour.
  final Future<void> Function(String route) onOpenStep;

  /// Voir le resultat — `null` tant que les criteres ne sont pas complets
  /// (bouton desactive : aucune porte vers un verdict pose sur du vide).
  final VoidCallback? onValidate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;

    // Progression : les 3 etapes du parcours (le test reste optionnel mais
    // compte dans la barre pour encourager a le faire).
    final doneCount = criteria.doneCount;
    final progress = doneCount / 3.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de progression (parite GR20 questionnaire).
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            f.flow.progress(done: doneCount, total: 3),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(160),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Intro du parcours guide.
          Text(f.flow.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingSm),
          Text(f.flow.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),

          // CE QUI MANQUE ENCORE (D1) : tant qu'un critere obligatoire n'est
          // pas la, on ne rend pas de verdict — on dit lequel manque.
          if (!criteria.isComplete) ...[
            _MissingCriteriaNotice(criteria: criteria),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Etape 1 : fiche morpho (age/taille/poids).
          _FlowStepCard(
            step: 1,
            icon: StepwaysIcons.myAccount,
            title: f.flow.stepProfile,
            subtitle: f.flow.stepProfileSub,
            done: criteria.profileComplete,
            onTap: () => onOpenStep('/trail/$trailId/hiker-profile'),
          ),
          // Etape 2 : test 6 minutes (optionnel mais alimente le calcul).
          //
          // GRISEE EN DEMO (tache 744), pour DEUX raisons qui vont dans le
          // meme sens. D'abord la regle de la tache 638 (bug 14) : le test de
          // marche SAISIT une donnee de personne et l'ecrit dans le profil,
          // et les trois raccourcis de `feasibility_tiles.dart` — fiche, test
          // de marche, randonnees passees — sont grises pour exactement cette
          // raison. Ce deuxieme chemin vers le MEME ecran avait ete oublie.
          // Ensuite la demo : le test de marche DEMANDE la permission de
          // position (`walk_test_provider`, `gps.requestPermission()`) avant
          // de mesurer. En demo, cette fenetre systeme surgirait sur la
          // demonstration et, en passant l'application en arriere-plan,
          // mettrait la marche simulee en pause. Grisee, elle DIT pourquoi.
          //
          // Elle ne bloque rien : le test est `optional`, et les criteres
          // obligatoires sont `profileComplete && hasPastHike`.
          GriseEnDemo(
            child: _FlowStepCard(
              step: 2,
              icon: StepwaysIcons.pas,
              title: f.flow.stepWalkTest,
              subtitle: f.flow.stepWalkTestSub,
              done: criteria.hasWalkTest,
              optional: true,
              onTap: () => onOpenStep('/trail/$trailId/walk-test'),
            ),
          ),
          // Etape 3 : 5 dernieres randos.
          _FlowStepCard(
            step: 3,
            icon: StepwaysIcons.historique,
            title: f.flow.stepPastHikes,
            subtitle: f.flow.stepPastHikesSub,
            done: criteria.hasPastHike,
            onTap: () => onOpenStep('/trail/$trailId/past-hikes'),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // « Valider / Voir mon resultat » — actif SEULEMENT au complet (D1).
          AppButton(
            minHeight: 52,
            icon: StepwaysIcons.cocheCercle,
            label: f.flow.validate,
            onPressed: onValidate,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            criteria.isComplete ? f.flow.hintReady : f.flow.hintBlocked,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(150),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Encart « il manque encore ceci » (D1, mandat #100293).
///
/// Remplace le verdict tant qu'un critere OBLIGATOIRE manque. GR20 se
/// contentait de ne rien faire quand le questionnaire etait incomplet ; ici on
/// nomme ce qui bloque, et on rappelle que le test 6 min, lui, reste optionnel
/// — sans quoi le randonneur ne saurait pas pourquoi il n'obtient rien.
class _MissingCriteriaNotice extends StatelessWidget {
  const _MissingCriteriaNotice({required this.criteria});

  final FeasibilityCriteria criteria;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = t.feasibility.flow;
    const color = AppTheme.orangeDifficile;

    final missing = <String>[
      if (!criteria.profileComplete) f.missingProfile,
      if (!criteria.hasPastHike) f.missingPastHikes,
    ];

    return AppCard(
      backgroundColor: color.withAlpha(20),
      borderColor: color.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIcon(StepwaysIcons.sablier, size: 20, color: color),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  f.missingTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(f.missingIntro, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppTheme.spacingSm),
          for (final item in missing)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepIcon(StepwaysIcons.radio, size: 14, color: color),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(item, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ),
            ),
          if (!criteria.hasWalkTest) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              f.missingWalkTestNote,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Carte d'une etape du flux guide (numero, icone, titre, etat coche).
class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.done,
    required this.onTap,
    this.optional = false,
  });
  final int step;
  final String icon;
  final String title;
  final String subtitle;
  final bool done;
  final bool optional;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = done ? AppTheme.vertFacile : colors.primary;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      onTap: onTap,
      child: Row(
        children: [
          // Pastille numero -> coche verte quand l'etape est remplie.
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withAlpha(30),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withAlpha(120)),
            ),
            child: done
                ? StepIcon(StepwaysIcons.coche, color: accent, size: 20)
                : Text(
                    '$step',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StepIcon(icon, size: 18, color: colors.onSurface),
                    const SizedBox(width: AppTheme.spacingXs),
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (optional) ...[
                      const SizedBox(width: AppTheme.spacingXs),
                      Text(
                        t.feasibility.flow.optionalTag,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurface.withAlpha(140),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          const StepIcon(StepwaysIcons.chevronDroite),
        ],
      ),
    );
  }
}
