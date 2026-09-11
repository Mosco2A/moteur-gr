import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../domain/models/tip_card.dart';
import '../domain/models/tip_theme.dart';
import '../providers/tip_cards_provider.dart';

/// Ecran FICHES CONSEILS — refonte StepWays LOT 5 (sous-ensemble C).
///
/// Les fiches sont RANGEES PAR THEMES (decision Chris #99615) : au lieu d'une
/// liste a plat, l'ecran presente des SECTIONS par theme (Materiel / Securite /
/// Sante / Meteo / Vie du refuge / ...). Chaque fiche depliee peut porter un ou
/// deux LIENS RESEAU (Facebook / Instagram) vers la fiche equivalente de la
/// marque — champ `url` de la donnee, JAMAIS invente. L'entrainement N'EST PLUS
/// une fiche conseil : c'est son propre ecran (sous-ensemble A).
///
/// Disponible en PREPA ET en RANDO (l'ecran est atteignable des deux phases du
/// cockpit). OFFLINE : le contenu des fiches est embarque (lisible sans reseau) ;
/// seuls les liens reseau requierent internet -> DEGRADATION PROPRE (bouton
/// present ; si l'ouverture echoue, message neutre, la fiche reste lisible).
///
/// Contenu i18n INLINE (5 langues, [TipCard.localizedTitle/Content]) ; libelles
/// d'interface via Slang. Look GR20 conserve ([AppCard], [ExpansionTile]).
class TipsScreen extends ConsumerWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final sections = ref.watch(tipCardsByThemeProvider);

    return Scaffold(
      appBar: AppHeader(title: t.tips.screenTitle),
      body: SafeArea(
        child: sections.isEmpty
            ? _EmptyThemed()
            : ListView(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                children: [
                  Text(t.tips.screenIntro, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppTheme.spacingBase),
                  for (final section in sections)
                    _ThemeSection(section: section),
                ],
              ),
      ),
    );
  }
}

/// Une SECTION par theme : titre de theme + fiches du theme.
class _ThemeSection extends StatelessWidget {
  const _ThemeSection({required this.section});

  final TipThemeSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelRaw = t['tips.themes.${section.theme}'];
    final label = labelRaw is String ? labelRaw : section.theme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de THEME (parite wireframe : « ══ MATERIEL ══ »).
        Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.spacingSm,
            bottom: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Icon(
                _themeIcon(TipTheme.iconFor(section.theme)),
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        for (final card in section.cards) _TipCardTile(card: card),
        const SizedBox(height: AppTheme.spacingSm),
      ],
    );
  }
}

/// Carte de fiche depliable (parite GR20) + boutons reseau (StepWays C).
class _TipCardTile extends StatelessWidget {
  const _TipCardTile({required this.card});

  final TipCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(card.localizedTitle, style: theme.textTheme.titleMedium),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          0,
          AppTheme.spacingBase,
          AppTheme.spacingBase,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              card.localizedContent,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          // Boutons reseau (uniquement si un lien est renseigne, spec C).
          if (card.hasSocialLinks) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _SocialLinks(card: card),
          ],
        ],
      ),
    );
  }
}

/// Boutons « Voir sur Facebook » / « Instagram » (champ url, StepWays C).
///
/// N'apparaissent QUE si le lien correspondant existe. Offline : l'ouverture
/// echoue proprement (message neutre) sans casser l'ecran (contrainte non
/// negociable). Aucune url en dur : tout vient de la donnee de la fiche.
class _SocialLinks extends StatelessWidget {
  const _SocialLinks({required this.card});

  final TipCard card;

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null && await canLaunchUrl(uri)) {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(t.tips.linkOffline)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fb = card.urlFacebook;
    final ig = card.urlInstagram;
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingSm,
      children: [
        if (fb != null && fb.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _open(context, fb),
            icon: const Icon(Icons.facebook, size: 18),
            label: Text(t.tips.viewOnFacebook),
          ),
        if (ig != null && ig.isNotEmpty)
          OutlinedButton.icon(
            onPressed: () => _open(context, ig),
            icon: const Icon(Icons.camera_alt_outlined, size: 18),
            label: Text(t.tips.viewOnInstagram),
          ),
      ],
    );
  }
}

/// Etat vide (aucune fiche pour ce sentier) — message neutre, jamais casse.
class _EmptyThemed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(120),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              t.tips.emptyThemed,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(170),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Resout le nom d'icone de theme (donnee) en [IconData] (couche UI).
IconData _themeIcon(String name) {
  switch (name) {
    case 'backpack':
      return Icons.backpack;
    case 'health_and_safety':
      return Icons.health_and_safety;
    case 'healing':
      return Icons.healing;
    case 'wb_sunny':
      return Icons.wb_sunny;
    case 'cabin':
      return Icons.cabin;
    case 'forest':
      return Icons.forest;
    default:
      return Icons.info_outline;
  }
}
