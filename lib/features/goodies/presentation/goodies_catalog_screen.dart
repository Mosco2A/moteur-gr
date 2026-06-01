import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';

/// Ecran stub de la boutique goodies.
///
/// Affiche un placeholder "arrive bientot" tant que le module
/// n'est pas implemente. Protege par [FeatureFlags.isGoodiesEnabled].
/// Tous les textes via Slang (t.goodies.*) -- zero texte en dur.
class GoodiesCatalogScreen extends StatelessWidget {
  const GoodiesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goodiesT = t.goodies;

    return Scaffold(
      appBar: AppBar(title: Text(goodiesT.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withAlpha(120),
              ),
              const SizedBox(height: 16),
              Text(
                goodiesT.comingSoon,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
