/// QUELLES LIGNES DU SAC MANQUENT EN BASE — une decision pure (tache 846).
///
/// LE PIEGE QUE CE LOT A TROUVE, ET IL ATTENDAIT DEPUIS LONGTEMPS. Le sac ne
/// posait ses lignes QUE sur une base vide (`dbItems.isEmpty`), et
/// `ChecklistDao.toggleItem` est un UPDATE SEC — il ne cree rien. Tout article
/// AJOUTE AU TEMPLATE apres coup n'avait donc aucune ligne chez un marcheur
/// ayant deja ouvert son sac : l'article s'affichait, sa coche basculait a
/// l'ecran... et n'arrivait JAMAIS en base. Au redemarrage, elle etait oubliee.
///
/// POURQUOI C'EST GRAVE POUR UN ARTICLE OBLIGATOIRE. Le filtre a eau de cette
/// tache est pose d'office et compte dans `requiredCount` : non coche, il
/// bloque « SAC OK ». Un marcheur l'aurait coche, valide, ferme — et retrouve
/// son sac refuse au lancement suivant, sans que rien ne l'explique.
///
/// POURQUOI UNE FONCTION A PART, ET PURE. Le notifier du sac depasse deja
/// largement les 500 lignes de la regle ECR-15 ; y ajouter ce raisonnement
/// l'aurait pousse au-dela de 800. Et surtout : « quelles lignes manquent »
/// est une question a laquelle on repond avec deux listes et rien d'autre —
/// ni base, ni providers, ni ecran. Elle se teste donc en une ligne.
library;

import 'package:drift/drift.dart' show Value;

import '../../../core/data/daos/checklist_dao.dart';
import '../../../core/data/database.dart'
    show ChecklistItem, ChecklistItemsCompanion;
import 'checklist_template.dart';

/// Les articles de [template] qui n'ont PAS de ligne dans [posees].
///
/// L'ORDRE DU TEMPLATE EST CONSERVE : les lignes se posent dans l'ordre GR20,
/// comme au premier remplissage.
///
/// CE N'EST PAS UNE RESURRECTION. Un article du template n'est pas supprimable
/// par le marcheur — `ChecklistDao.deleteCustomItem` ne touche que les articles
/// personnalises — donc une ligne absente est une ligne JAMAIS POSEE, et jamais
/// une ligne qu'il aurait retiree.
///
/// SUR UN SAC VIDE, RIEN NE CHANGE : toutes les lignes manquent, et la liste
/// rendue est le template entier. C'est exactement l'ancien premier
/// remplissage.
List<ChecklistTemplateItem> lignesManquantes(
  Iterable<ChecklistItem> posees,
  List<ChecklistTemplateItem> template,
) {
  final deja = posees.map((l) => l.itemId).toSet();
  return [
    for (final item in template)
      if (!deja.contains(item.id)) item,
  ];
}

/// Pose en base les lignes de [items] pour le sentier [trailId].
///
/// NON COCHEES, AU POIDS DU TEMPLATE. Le poids est la REFERENCE de l'article
/// (parite GR20) ; le marcheur l'ajuste ensuite article par article
/// (`setItemWeight`), et c'est sa valeur qui entre alors dans la jauge.
Future<void> poserLesLignes(
  ChecklistDao dao,
  String trailId,
  List<ChecklistTemplateItem> items,
) async {
  await dao.insertAll([
    for (final item in items)
      ChecklistItemsCompanion(
        trailId: Value(trailId),
        itemId: Value(item.id),
        category: Value(item.category),
        isChecked: const Value(false),
        weightGrams: Value(item.weightGrams),
        quantity: Value(item.quantity),
      ),
  ]);
}
