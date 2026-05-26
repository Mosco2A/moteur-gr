import 'package:flutter/material.dart';

/// Ecran detail d'un sentier.
///
/// Placeholder Phase 1 — sera enrichi en Phase 2
/// avec les etapes, carte, et progression.
class TrailDetailScreen extends StatelessWidget {
  const TrailDetailScreen({super.key, required this.trailId});

  /// Identifiant du sentier a afficher
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
          ],
        ),
      ),
    );
  }
}
