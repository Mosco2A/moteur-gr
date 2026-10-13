/// La boutique n'est PAS implementee, et cet ecran ne promet plus rien : une
/// promesse que le code ne tient pas est un defaut.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/screen_entry.dart';
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
class GoodiesCatalogScreen extends ConsumerWidget {
  const GoodiesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LA MIETTE D ENTREE D ECRAN (lot 645-09). Cet ecran n a pas
    // d etat : le service deduplique, donc une miette part par
    // ENTREE et non par reconstruction. Rien n est attendu ici.
    observeScreenEntry(ref, ScreenBreadcrumb.goodiesCatalog);
    return Scaffold(
      appBar: AppBar(title: Text(t.goodies.title)),
      body: const SizedBox.shrink(),
    );
  }
}
