import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/town_guide.dart';
import '../providers/guide_providers.dart';
import 'town_guide_detail_screen.dart';

/// Liste des town guides d'un sentier (F8C-02, Phase 8 P8-C, offline R3).
///
/// Affiche les villes/villages d'etape disposant d'un guide pratique (modele
/// FarOut « town guides », A3-7). La consultation est 100 % OFFLINE : le contenu
/// vient du pack local (F8B-01), AUCUNE logique reseau ici. Le moteur reste
/// generique (#84627) : les guides sont parametres par [trailId], aucune
/// localite n'est hardcodee.
///
/// Un bandeau rappelle le role FACILITATEUR de l'app (#84100) : les liens
/// prestataires sont SORTANTS, aucune reservation ni paiement in-app.
///
/// a11y Semantics + Slang 5 langues (aucune chaine en dur). Riverpod 2.6.
class TownGuidesScreen extends ConsumerWidget {
  const TownGuidesScreen({super.key, required this.trailId});

  /// Sentier dont on liste les town guides (genericite #84627).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    // Catalogue OFFLINE : libelles de section localises via Slang (domaine pur
    // F8C-01). On ne garde que les guides porteurs de contenu consultable.
    final guides = townGuidesForContext(
      context,
      trailId,
    ).where((g) => g.hasContent).toList(growable: false);

    return Scaffold(
      appBar: AppBar(title: Text(t.guides.title)),
      body: guides.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  t.guides.empty,
                  key: const ValueKey('town-guides-empty'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              key: const ValueKey('town-guides-list'),
              children: [
                // En-tete : sous-titre + rappel FACILITATEUR (#84100).
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    AppTheme.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.guides.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      _FacilitatorNote(text: t.guides.facilitatorNote),
                    ],
                  ),
                ),
                // Une carte par localite porteuse d'un guide.
                for (final guide in guides)
                  _TownGuideTile(trailId: trailId, guide: guide),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
    );
  }
}

/// Bandeau « facilitateur » (anti reservation/paiement in-app, #84100).
class _FacilitatorNote extends StatelessWidget {
  const _FacilitatorNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Container(
        key: const ValueKey('guides-facilitator-note'),
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
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tuile d'une localite : ouvre le detail du town guide au tap.
class _TownGuideTile extends StatelessWidget {
  const _TownGuideTile({required this.trailId, required this.guide});

  final String trailId;
  final TownGuide guide;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final categoriesCount = guide.sections
        .where((s) => s.items.isNotEmpty)
        .length;

    return Semantics(
      container: true,
      button: true,
      label: t.guides.a11y.guideCard(lieu: guide.nomLieu),
      child: AppCard(
        key: ValueKey('town-guide-card-${guide.id}'),
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingXs,
        ),
        child: ListTile(
          leading: const Icon(Icons.location_city, color: AppTheme.vertFacile),
          title: Text(
            guide.nomLieu,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            t.guides.sectionsCount(n: categoriesCount),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisGranite,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  TownGuideDetailScreen(trailId: trailId, guideId: guide.id),
            ),
          ),
        ),
      ),
    );
  }
}
