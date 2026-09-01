import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/town_guide.dart';
import '../providers/guide_providers.dart';

/// Detail d'un town guide : sections pratiques + liens facilitateur (F8C-02).
///
/// Consultation 100 % OFFLINE (R3) d'une localite d'etape : sections
/// ravitaillement / hebergement / transport / services / eau / sante, chacune
/// listant ses items (prestataires/points pratiques). Le contenu provient du
/// pack local (F8C-01), AUCUNE logique reseau.
///
/// Chaque item porteur d'un lien expose un bouton « voir le site » qui OUVRE le
/// site/app du prestataire via url_launcher — FACILITATEUR uniquement, AUCUNE
/// reservation ni paiement in-app (decision Chris #84100). Le lancement passe
/// par [guideDeeplinkLauncherProvider] (surchargeable en test) ; un echec est
/// signale a l'utilisateur (ZERO catch silencieux).
///
/// a11y Semantics + Slang 5 langues (aucune chaine en dur). Riverpod 2.6.
class TownGuideDetailScreen extends ConsumerWidget {
  const TownGuideDetailScreen({
    super.key,
    required this.trailId,
    required this.guideId,
    this.guide,
  });

  /// Sentier auquel le guide est rattache (genericite #84627).
  final String trailId;

  /// Identifiant du town guide a afficher.
  final String guideId;

  /// Guide deja resolu (optionnel) : evite une relecture du catalogue quand
  /// l'appelant le detient deja. Si null, le guide est resolu depuis le
  /// catalogue OFFLINE par [trailId]/[guideId].
  final TownGuide? guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final guide =
        this.guide ?? townGuideByIdForContext(context, trailId, guideId);

    // Guide introuvable (purge du pack, id obsolete) : repli explicite offline.
    if (guide == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.guides.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Text(
              t.guides.empty,
              key: const ValueKey('town-guide-detail-empty'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // On n'affiche que les sections porteuses d'items consultables.
    final sections = guide.sections
        .where((s) => s.items.isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(guide.nomLieu)),
      body: ListView(
        key: ValueKey('town-guide-detail-${guide.id}'),
        padding: const EdgeInsets.only(bottom: AppTheme.spacingLg),
        children: [
          // Rappel FACILITATEUR (#84100) en tete du detail.
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
            ),
            child: Semantics(
              label: t.guides.facilitatorNote,
              child: Container(
                key: const ValueKey('guide-detail-facilitator-note'),
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: AppTheme.vertFacile.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 18,
                      color: AppTheme.vertFacile,
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        t.guides.facilitatorNote,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (sections.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Text(
                t.guides.noItems,
                key: const ValueKey('town-guide-detail-no-items'),
                textAlign: TextAlign.center,
              ),
            )
          else
            for (final section in sections) _GuideSectionCard(section: section),
        ],
      ),
    );
  }
}

/// Carte d'une section thematique (titre + intro + items).
class _GuideSectionCard extends StatelessWidget {
  const _GuideSectionCard({required this.section});

  final GuideSection section;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      key: ValueKey('guide-section-${section.normalizedCategorie}'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section (Semantics « header » pour lecteurs d'ecran).
          Semantics(
            header: true,
            label: t.guides.a11y.section(titre: section.titre),
            child: Text(
              section.titre,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (section.contenu.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              section.contenu,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingSm),
          for (final item in section.items) _GuideItemTile(item: item),
        ],
      ),
    );
  }
}

/// Tuile d'un item : nom, description et — si lien — bouton facilitateur.
class _GuideItemTile extends ConsumerWidget {
  const _GuideItemTile({required this.item});

  final GuideItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.nom,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              item.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisGranite,
              ),
            ),
            // Bouton FACILITATEUR : OUVRE le site du prestataire (lien SORTANT),
            // AUCUNE resa ni paiement in-app (#84100). Masque si pas de lien.
            if (item.hasDeeplink) ...[
              const SizedBox(height: AppTheme.spacingXs),
              Semantics(
                button: true,
                label: t.guides.a11y.openSiteButton(nom: item.nom),
                child: AppButton(
                  key: ValueKey('guide-deeplink-${item.nom}'),
                  variant: AppButtonVariant.outline,
                  isFullWidth: false,
                  icon: Icons.open_in_new,
                  label: t.guides.openSite,
                  onPressed: () => _openSite(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Ouvre le lien SORTANT du prestataire (facilitateur, #84100).
  ///
  /// Delegue au [GuideDeeplinkLauncher] (surchargeable en test). En cas d'echec
  /// (appareil sans navigateur, lien invalide), affiche un message — ZERO catch
  /// silencieux. AUCUNE logique de reservation/paiement n'est declenchee ici.
  Future<void> _openSite(BuildContext context, WidgetRef ref) async {
    final url = item.deeplinkUrl;
    if (url == null || url.isEmpty) return;
    final launcher = ref.read(guideDeeplinkLauncherProvider);
    final messenger = ScaffoldMessenger.of(context);
    final t = Translations.of(context);
    final ok = await launcher.open(url);
    if (ok) return;
    messenger.showSnackBar(SnackBar(content: Text(t.guides.cannotOpen)));
  }
}
