import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ecran liste des sentiers disponibles.
///
/// Placeholder Phase 1 — sera enrichi en Phase 2
/// avec la vraie liste depuis la DB.
class TrailListScreen extends StatelessWidget {
  const TrailListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushNamed('settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.terrain, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Liste des sentiers',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Chargement en cours...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
