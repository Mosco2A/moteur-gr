import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Écran détail d'un sentier.
///
/// Affiche les informations principales du sentier
/// et propose un bouton pour accéder à la carte du tracé.
class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({super.key, required this.trailId});

  /// Identifiant du sentier à afficher
  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Sentier $trailId')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Detail du sentier',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: $trailId',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ElevatedButton.icon(
                onPressed: () => context.go('/trail/$trailId/map'),
                icon: const Icon(Icons.terrain),
                label: const Text('Voir la carte'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
