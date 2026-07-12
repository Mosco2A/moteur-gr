import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../i18n/translations.g.dart';

/// Coquille applicative de la navigation principale (E2.9b + HUB E07/AM-1).
///
/// Affiche les 5 onglets de la bottom navigation Material 3
/// (Accueil, Carte, Etapes, Journal, Plus) via un [NavigationBar]. Le HUB
/// d'accueil (E07) prend la position 1 ; le Planning trek a quitte la barre (il
/// descend dans le HUB via la carte « Programme »). Le contenu de chaque onglet
/// est rendu par le [StatefulNavigationShell] fourni par GoRouter
/// (StatefulShellRoute.indexedStack), ce qui preserve l'etat de chaque onglet
/// entre les bascules (IndexedStack natif).
///
/// Les libelles passent par Slang (t.nav.*) — zero texte en dur.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  /// Coquille de navigation a etat fournie par StatefulShellRoute.
  final StatefulNavigationShell navigationShell;

  /// Bascule vers l'onglet [index].
  ///
  /// `initialLocation: true` quand on retape l'onglet deja actif permet
  /// de revenir a la racine de la branche (comportement Material attendu).
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: tr.nav.accueil,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            selectedIcon: const Icon(Icons.map),
            label: tr.nav.map,
          ),
          NavigationDestination(
            icon: const Icon(Icons.terrain_outlined),
            selectedIcon: const Icon(Icons.terrain),
            label: tr.nav.stages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: tr.nav.journal,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: tr.nav.more,
          ),
        ],
      ),
    );
  }
}
