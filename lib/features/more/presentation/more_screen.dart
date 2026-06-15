import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Ecran "Plus" — onglet hub de la bottom navigation (E2.9b).
///
/// Regroupe les fonctions secondaires non promues en onglet principal :
/// checklist, faisabilite, conseils, urgence, catalogue, profil, parametres.
/// Chaque entree pousse l'ecran cible au-dessus de la branche courante
/// (context.push) afin de preserver la pile de l'onglet "Plus".
///
/// Tous les libelles passent par Slang (zero texte en dur).
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = Translations.of(context);
    // L'identifiant du sentier actif provient de la configuration injectee.
    final trailId = ref.watch(
      trailConfigProvider.select((c) => c.id),
    );

    final entries = <_MoreEntry>[
      _MoreEntry(
        icon: Icons.checklist_rtl,
        label: tr.nav.checklist,
        onTap: () => context.push('/trail/$trailId/checklist'),
      ),
      _MoreEntry(
        icon: Icons.fitness_center,
        label: tr.nav.feasibility,
        onTap: () => context.push('/trail/$trailId/feasibility'),
      ),
      _MoreEntry(
        icon: Icons.lightbulb_outline,
        label: tr.nav.tips,
        onTap: () => context.push('/trail/$trailId/tips'),
      ),
      _MoreEntry(
        icon: Icons.emergency_outlined,
        label: tr.nav.emergency,
        onTap: () => context.push('/emergency'),
      ),
      _MoreEntry(
        icon: Icons.download_outlined,
        label: tr.nav.catalog,
        onTap: () => context.push('/catalog'),
      ),
      // F8D-02 : bascule de sentier (le moteur reste generique, #84627).
      _MoreEntry(
        icon: Icons.swap_horiz,
        label: tr.nav.trailSelection,
        onTap: () => context.push('/trail-selection'),
      ),
      _MoreEntry(
        icon: Icons.person_outline,
        label: tr.nav.profile,
        onTap: () => context.push('/profile'),
      ),
      _MoreEntry(
        icon: Icons.settings_outlined,
        label: tr.nav.settings,
        onTap: () => context.push('/settings'),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(tr.nav.more)),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final entry = entries[index];
          return ListTile(
            leading: Icon(entry.icon, color: theme.colorScheme.primary),
            title: Text(entry.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: entry.onTap,
          );
        },
      ),
    );
  }
}

/// Entree du menu "Plus" : une icone, un libelle, une action de navigation.
class _MoreEntry {
  const _MoreEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
