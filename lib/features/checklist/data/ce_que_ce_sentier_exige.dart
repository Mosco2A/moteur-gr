/// CE QUE *CE* SENTIER EXIGE AU SAC — en plus des 84 articles de la parite.
///
/// LA PROMESSE DU PRODUIT, ET C'EST ELLE QUI JUSTIFIE CE FICHIER. Le marcheur
/// ne doit pas avoir a se demander si ce sentier-la demande un filtre : c'est
/// l'application qui sait ce que le sentier demande, et qui le pose dans le sac
/// avec son poids. Elle ne le SUGGERE pas — une suggestion se lit, s'ignore, et
/// se decouvre devant le ruisseau.
///
/// POURQUOI PAS DANS `defaultChecklistTemplate`. Les 84 articles sont la parite
/// GR20 : ils valent pour tous les sentiers. Un filtre a eau ne vaut que pour
/// les sentiers qui portent de l'eau a filtrer — l'imposer partout ferait
/// porter soixante-cinq grammes a qui marche de fontaine en fontaine, et
/// viderait de son sens le mot « obligatoire ».
///
/// COMMENT CA SE BRANCHE SUR LE MECANISME EXISTANT, SANS REGLE A COTE. Le sac
/// n'a qu'UNE facon de decider ce qu'il impose : `ChecklistTemplateItem`
/// `requirement == ChecklistRequirement.required`. C'est de la que viennent le
/// badge rouge « Obligatoire », le compte `requiredCount`, le garde-fou qui
/// empeche de decocher, et le refus de « SAC OK » tant qu'il en manque un. Ce
/// fichier ne duplique aucun de ces quatre comportements : il ajoute un article
/// `required` a la liste que le sac lisait deja, et les quatre suivent.
library;

import '../../../core/models/poi.dart';
import '../../../shared/poi/poi_type_config.dart';
import 'checklist_template.dart';

/// LE FILTRE A EAU, article impose par un sentier qui porte de l'eau a filtrer.
///
/// LE POIDS : 65 g, poids de reference d'un filtre de poche a fibres creuses,
/// a sec. Comme les 84 autres, c'est une REFERENCE et non une mesure du sac du
/// marcheur : il reste modifiable article par article (`setItemWeight`), et
/// c'est ce poids-la qui entre dans la jauge tant qu'il ne l'a pas corrige.
///
/// LA CATEGORIE `foodWater` : celle de l'eau et des vivres, ou vivent deja les
/// pastilles de purification. Un filtre se range avec ce qui sert a boire, pas
/// avec le materiel de bivouac.
const ChecklistTemplateItem filtreAEau = ChecklistTemplateItem(
  id: 'waterFilter',
  category: 'foodWater',
  nameKey: 'waterFilter',
  weightGrams: 65,
  requirement: ChecklistRequirement.required,
  isEssential: true,
);

/// Les articles que [pois] rend OBLIGATOIRES sur ce sentier.
///
/// UN SEUL POINT SUFFIT, et c'est voulu. Un sentier qui porte UN ruisseau a
/// filtrer est un sentier ou l'on boit filtre : il n'y a pas de seuil a
/// franchir, parce qu'il n'existe pas de demi-filtre. Le marcheur le porte ou
/// il ne le porte pas.
///
/// CE QUI NE DECLENCHE RIEN. Une eau qui ne se boit pas (le geste
/// `doNotDrink`) n'exige pas de filtre : un filtre ne desulfure pas une source
/// thermale, et faire porter du materiel inutile est aussi une faute. Une eau
/// a traiter ou a faire bouillir n'en exige pas non plus — c'est un autre
/// geste, auquel aucun article n'est associe a ce jour, et le brief ne demande
/// que le filtre.
///
/// LE CAS DE LA DONNEE MUETTE EST DEJA TRANCHE EN AMONT, et pas ici : un point
/// d'eau dont la donnee ne dit rien est rendu « a filtrer » par
/// [PoiModel.waterAction]. Il pose donc le filtre au sac, par la meme prudence
/// qui le fait ecrire sur la carte. La regle ne vit qu'a un endroit.
List<ChecklistTemplateItem> articlesExigesParLeSentier(List<PoiModel> pois) {
  for (final poi in pois) {
    if (!PoiTypeConfig.waterTypes.contains(poi.type)) continue;
    if (poi.waterAction.exigeUnFiltre) return const [filtreAEau];
  }
  return const [];
}
