/// Le seul endroit du depot qui ecrit un SENS DE PARCOURS a l'ecran.
library;

import '../../i18n/translations.g.dart';

/// Ecrit le sens de parcours [code] en clair : « Nord-Sud », « Sud-Nord ».
///
/// CE QUE CETTE FONCTION FERME (tache 835). Le Resume du plan affichait
/// « Direction NS » : la valeur BRUTE. `TrekPlan.direction` est une simple
/// `String` que le moteur traite comme opaque ('NS' / 'SN'), et
/// `plan_summary_screen.dart` la posait telle quelle dans un `Text`. Le
/// randonneur lisait donc un code machine a la place d'une phrase.
///
/// LE LIBELLE N'A PAS ETE INVENTE ICI : il existait deja, traduit dans les cinq
/// langues (`import.directionNS` / `import.directionSN`), et l'ecran d'import de
/// trace l'employait correctement — deux fois, avec le MEME ternaire recopie.
/// Ce lot en fait une fonction plutot qu'une troisieme copie.
///
/// POURQUOI LES CLEFS VIVENT DANS LE NAMESPACE `import`. Elles y sont nees avec
/// l'ecran d'import. Les deplacer casserait les cinq fichiers de langue pour un
/// gain cosmetique ; on les REUTILISE, et c'est ce commentaire qui dit pourquoi
/// un ecran de resume va chercher un texte chez `import`.
///
/// TOUT CODE INCONNU EST TRAITE COMME 'SN', parce que le depot n'en declare que
/// deux (`TrailConfig.directions` vaut `['NS', 'SN']`) et qu'un sens inconnu ne
/// doit surtout pas faire reapparaitre un code brut a l'ecran.
String libelleDeDirection(String code, Translations t) =>
    code == 'NS' ? t.import.directionNS : t.import.directionSN;
