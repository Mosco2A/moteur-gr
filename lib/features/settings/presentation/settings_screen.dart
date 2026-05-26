import 'package:flutter/material.dart';

/// Ecran des parametres de l'application.
///
/// Placeholder Phase 1 — sera enrichi en Phase 2
/// avec les preferences utilisateur (langue, theme, unites, etc.)
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Parametres')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              'Parametres',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Configuration en cours...',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
