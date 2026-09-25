import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';

/// Ecran de la boutique goodies — MODULE NON IMPLEMENTE.
///
/// IL N'ANNONCE PLUS RIEN (retour Chris 25/09, tache 552). Mot pour mot : « Tu
/// les as, tu les a pas, si tu ne les a pas tu ne met rien ». L'ecran portait
/// « Ce module arrive bientot. Restez connecte ! » : une promesse que le code ne
/// tient pas. Elle est SUPPRIMEE, pas reformulee — l'absence de boutique ne
/// modifie aucun resultat affiche ailleurs, donc elle ne se commente pas.
/// L'ecran reste protege par `FeatureFlags.isGoodiesEnabled` (faux par defaut,
/// la route redirige vers `/trails`) : personne ne l'atteint aujourd'hui.
/// Tous les textes via Slang (t.goodies.*) -- zero texte en dur.
class GoodiesCatalogScreen extends StatelessWidget {
  const GoodiesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.goodies.title)),
      body: const SizedBox.shrink(),
    );
  }
}
