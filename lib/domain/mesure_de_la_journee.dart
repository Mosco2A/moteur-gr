/// LA MESURE PROPRE D UNE JOURNEE DE MARCHE — celle qui ne vaut PAS la somme de
/// ses etapes entieres.
library;

/// LES QUATRE CHIFFRES D UNE JOURNEE, QUAND ELLE NE COUVRE PAS DES ETAPES
/// ENTIERES.
///
/// POURQUOI CE MODELE EXISTE, ET C EST LA REPARATION D UN DEFAUT LIVRE AUX
/// CLIENTS. Jusqu a la tache 855, la FICHE de vente et le PROGRAMME du client
/// ne posaient pas les memes journees :
///
///  - la FICHE posait les journees sur les TRENTE ET UNE NUITS relevees du GR20
///    (tache 838), donc EN COUPANT a l interieur des etapes
///    (`difficulte_calculee.dart`) ;
///  - le PROGRAMME ne coupait JAMAIS : en dessous du nombre d etapes il les
///    groupait, au-dela tout jour de plus etait du REPOS
///    (`PlanningCalculator.distribute`).
///
/// A SEIZE JOURS, LA FICHE ANNONCAIT DONC UNE PIRE JOURNEE DE 26,48 KM-EFFORT
/// QUAND LE PROGRAMME EN PRODUISAIT UNE DE 36,45 — neuf km-effort d ecart, et
/// du cote qui RASSURE A TORT, sur un sentier de haute montagne. Le mode
/// « facile » etait ANNONCE et PAS IMPLEMENTE.
///
/// CE QUE CHRISTOPHE A TRANCHE, 18/10 11:03, verbatim : « les etapes du GR
/// restent les etapes du GR. 16 c'et 16, si le gars fait la premiere en 2 fois
/// et bien c'est toujours 16 etape en 17 jours ». L ETAPE est donc la reference
/// FIXE du sentier et l unite de VENTE ; la JOURNEE est LIBRE et peut couvrir
/// une PARTIE d etape. Les deux comptes ne se touchent jamais : couper une
/// journee ne fabrique aucune dix-septieme etape.
///
/// CONSEQUENCE SUR LE MODELE : une journee ne peut plus deduire ses chiffres de
/// la somme de ses etapes, parce qu elle n en couvre peut-etre qu un morceau.
/// Elle porte donc SA PROPRE MESURE, et cette mesure vient des SEGMENTS mesures
/// entre deux nuits relevees — jamais d une proportion, jamais d une
/// interpolation. C est le reproche exact que Christophe avait fait au
/// decoupage du lot 558 (« le point de coupe n est pas un lieu releve ») et il
/// ne revient pas par ici : chaque borne de journee est un refuge, une
/// bergerie ou un bivouac qui existe dans OpenStreetMap.
class MesureDeLaJournee {
  /// Les quatre chiffres d une journee, deja sommes sur ses segments.
  const MesureDeLaJournee({
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
  });

  /// Longueur de la journee, en kilometres.
  final double km;

  /// Denivele POSITIF de la journee, en metres, detour vers le couchage
  /// compris.
  final int deniveleM;

  /// Denivele NEGATIF de la journee, en metres, compte positivement, detour
  /// compris.
  final int descenteM;

  /// Temps de marche de la journee, en minutes, detour compris.
  ///
  /// Par LE modele de temps operationnel du depot
  /// (`lib/core/models/stage_duration.dart`), celui qui annonce les horaires —
  /// et non par Naismith-Langmuir, qui mesure la difficulte et dont les seuils
  /// ne sont pas encore arbitres ([TempsNaismithLangmuir]).
  final int minutes;

  /// LA SOMME DE DEUX JOURNEES REUNIES — ce que fait « Regrouper ».
  ///
  /// Les quatre chiffres s additionnent. Le detour de la nuit intermediaire
  /// reste compte : le marcheur qui regroupe deux journees ne dort plus au
  /// milieu, mais ce lot ne pretend pas le savoir — le retirer demanderait de
  /// connaitre QUELLE nuit disparait, et une soustraction devinee serait pire
  /// que la legere surestimation qu elle corrige. C est une reserve NOMMEE,
  /// pas un oubli.
  MesureDeLaJournee plus(MesureDeLaJournee autre) => MesureDeLaJournee(
    km: km + autre.km,
    deniveleM: deniveleM + autre.deniveleM,
    descenteM: descenteM + autre.descenteM,
    minutes: minutes + autre.minutes,
  );

  /// VRAI quand les trois mesures tiennent debout (aucune negative).
  bool get estMesurable => km >= 0 && deniveleM >= 0 && descenteM >= 0;
}
