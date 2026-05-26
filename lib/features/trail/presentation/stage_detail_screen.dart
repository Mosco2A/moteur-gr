import 'package:flutter/material.dart';

/// Ecran detail d'une etape.
///
/// Placeholder Phase 1 — sera enrichi en Phase 2
/// avec le profil altimetrique, les POI, et la carte.
class StageDetailScreen extends StatelessWidget {
  const StageDetailScreen({
    super.key,
    required this.trailId,
    required this.stageNumber,
  });

  /// Identifiant du sentier parent
  final String trailId;

  /// Numero de l'etape a afficher
  final int stageNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Etape $stageNumber')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hiking, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Etape $stageNumber',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Sentier: $trailId',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
