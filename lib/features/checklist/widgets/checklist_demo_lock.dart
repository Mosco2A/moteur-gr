import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/paywall_sheet.dart';

/// LE BRIDAGE DU SAC EN DEMO (tache 594, A2c) — deux pieces, une regle.
///
/// Le modele eco du 08/09, §2, decrit le gratuit comme une « demo BRIDEE des
/// outils — SAC A DOS + PREPA PHYSIQUE jouables *pour de faux* (version
/// bridee), toutes les autres categories GRISEES (visibles, verrouillees,
/// jamais cachees) ».
///
/// LE SAC N'AVAIT AUCUN BRIDAGE. Recherche `isDemo|PurchaseGate|paywall|demo`
/// dans tout `lib/features/checklist/` : zero occurrence de monetisation
/// (inventaire 593 §M7c). Il s'ouvrait entier, gratuit et complet — exactement
/// l'inverse de la decision. Les trois `Icons.lock` de l'ecran ne sont PAS un
/// paywall : ils designent les articles OBLIGATOIRES, et ils restent ce
/// qu'ils sont.
///
/// CE QUI EST POSE ICI : un bandeau qui dit que c'est un essai, et une
/// categorie grisee qui dit ce qu'elle contient sans le servir, avec le chemin
/// d'achat. Jamais une categorie CACHEE : on doit voir ce qu'on n'a pas.

/// Bandeau d'essai en tete du sac : dit le bridage avant qu'on le decouvre.
class ChecklistDemoBanner extends StatelessWidget {
  const ChecklistDemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('checklist-demo-banner'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      color: theme.colorScheme.secondary.withAlpha(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.science_outlined,
                  size: 20, color: theme.colorScheme.secondary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.checklist.demoBridledTitle,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.checklist.demoBridledBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}

/// Categorie GRISEE : visible, verrouillee, jamais cachee.
///
/// On lit le NOM de la categorie (on sait ce qu'on n'a pas) ; on n'a pas ses
/// articles. Le geste mene au paywall, jamais dans le vide (regle du LOT X).
class ChecklistLockedCategory extends StatelessWidget {
  const ChecklistLockedCategory({
    super.key,
    required this.categoryKey,
    required this.categoryName,
    required this.trailId,
    required this.totalStages,
  });

  /// Cle technique de la categorie (sert a la cle de widget, donc aux tests).
  final String categoryKey;

  /// Nom affiche de la categorie (traduit).
  final String categoryName;

  /// Sentier a debloquer.
  final String trailId;

  /// Nombre d'etapes du sentier (prix affiche par le paywall).
  final int totalStages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grise = theme.colorScheme.onSurface.withAlpha(110);
    return AppCard(
      key: ValueKey('checklist-locked-$categoryKey'),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => showPaywallSheet(
          context,
          trailId: trailId,
          totalStages: totalStages,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(
            children: [
              Icon(Icons.lock_outline, size: 20, color: grise),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: theme.textTheme.titleSmall?.copyWith(color: grise),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.checklist.demoLockedCategory,
                      style: theme.textTheme.labelSmall?.copyWith(color: grise),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: grise),
            ],
          ),
        ),
      ),
    );
  }
}
