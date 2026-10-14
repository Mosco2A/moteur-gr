/// LE GESTE A FAIRE AVANT DE BOIRE — et non un drapeau de potabilite.
///
/// DECISION DE CHRISTOPHE, 14/10 : « Potabilite ca veut dire filtration ».
/// Ce qui sert au marcheur n'est pas une etiquette abstraite (« potable » /
/// « non potable ») mais ce qu'il doit FAIRE, bouteille en main, devant l'eau :
/// boire, filtrer, traiter, ou s'abstenir. Un booleen aurait range la source
/// non captee du cote du « non potable », avec l'eau thermale sulfureuse — et
/// perdu l'information qui compte : la premiere se boit avec un filtre, la
/// seconde ne se boit pas du tout.
///
/// ---------------------------------------------------------------------------
/// CE QUE LA DONNEE SAIT DIRE, ET CE QU'ELLE TAIT
/// ---------------------------------------------------------------------------
///
/// Les POI de sentier portent leur provenance OpenStreetMap dans leur champ
/// `source`. OSM distingue `amenity=drinking_water` (une eau a boire) de
/// `amenity=fountain` (une fontaine, qui peut etre ornementale), et c'est le
/// qualificatif `drinking_water=yes` qui AFFIRME la potabilite d'une fontaine.
/// Sur le Mare a Mare Centre, deux fontaines le portent et une ne le porte
/// pas : l'absence est donc une information, pas un oubli de saisie.
///
/// LA REGLE QUI EN DECOULE N'A QU'UN SENS. Quand la donnee ne dit rien, le
/// point est a FILTRER ([WaterAction.parPrudence]). Jamais l'inverse :
/// annoncer « buvable » une eau dont on ne sait rien se paye en secours,
/// annoncer « a filtrer » une fontaine potable se paye en soixante-cinq
/// grammes au sac.
///
/// ET CE REPLI SE DIT. `PoiModel.waterActionIsPrecaution` distingue le geste
/// RELEVE du geste pris par PRUDENCE, et la fiche du point l'ecrit : le
/// marcheur sait s'il lit une mesure ou une precaution.
library;

/// Le geste a faire devant un point d'eau.
///
/// L'ORDRE DES VALEURS EST L'ORDRE DE L'EXIGENCE, du plus simple au plus
/// severe : il sert a choisir le MEILLEUR geste quand une etape porte
/// plusieurs points d'eau (voir [meilleur]). Ne pas le reordonner.
enum WaterAction {
  /// BOIRE TEL QUEL — fontaine, source captee. Rien a faire.
  ///
  /// Ce que la donnee doit porter pour le meriter : un qualificatif qui
  /// AFFIRME la potabilite — `amenity=drinking_water`, ou `drinking_water=yes`
  /// pose sur une fontaine.
  drinkAsIs,

  /// FILTRER — ruisseau, source non captee.
  ///
  /// C'est aussi LE GESTE PAR DEFAUT quand la donnee ne dit rien
  /// ([parPrudence]).
  filter,

  /// TRAITER ou FAIRE BOUILLIR — eau dont un filtre ne repond pas.
  ///
  /// Un filtre de poche retient les particules et les micro-organismes ; il ne
  /// retient ni le chimique ni le virus. Ce geste-la n'est donc PAS un filtre,
  /// et c'est pour cela qu'il porte son propre cas plutot que de se ranger
  /// avec [filter].
  treatOrBoil,

  /// NE PAS BOIRE — eau thermale, eau stagnante, abreuvoir.
  ///
  /// NE COMPTE JAMAIS COMME DE L'EAU, meme avec un filtre au sac
  /// ([donneDeLEau] rend `false`). Un filtre ne desulfure pas une source
  /// thermale.
  doNotDrink;

  /// LE GESTE RETENU QUAND LA DONNEE NE DIT RIEN : filtrer.
  ///
  /// POURQUOI UNE CONSTANTE ET PAS UN `??` RECOPIE. Le repli de prudence est
  /// une decision produit, pas un detail d'implementation : il se lit a UN
  /// endroit, et le jour ou il change il change partout. Les trois lecteurs du
  /// geste — l'alerte d'eau, le sac, la carte — passent tous par
  /// `PoiModel.waterAction`, qui passe par ici.
  static const WaterAction parPrudence = WaterAction.filter;

  /// Vrai si ce geste laisse de l'eau BUVABLE au bout.
  ///
  /// Trois cas sur quatre : avec le bon geste, l'eau est utilisable. Seul
  /// [doNotDrink] ne donne rien.
  bool get donneDeLEau => this != WaterAction.doNotDrink;

  /// Vrai si ce geste EXIGE un filtre au sac.
  ///
  /// [filter] seul. [treatOrBoil] demande autre chose (pastilles, rechaud) et
  /// n'impose donc pas de filtre ; aucune donnee de sentier ne porte ce cas a
  /// ce jour, et aucun article ne lui est associe.
  bool get exigeUnFiltre => this == WaterAction.filter;

  /// La valeur ecrite dans la donnee du sentier et dans la base.
  ///
  /// `snake_case`, et jamais `index` : un entier aurait fait dependre la base
  /// de l'ordre de declaration, qu'on vient justement de se donner le droit de
  /// relire comme une echelle d'exigence.
  String get versDonnee => switch (this) {
    WaterAction.drinkAsIs => 'drink_as_is',
    WaterAction.filter => 'filter',
    WaterAction.treatOrBoil => 'treat_or_boil',
    WaterAction.doNotDrink => 'do_not_drink',
  };

  /// Le geste DECLARE par une donnee, ou `null` quand elle n'en dit rien.
  ///
  /// RIEN N'EST DEVINE ICI, ET SURTOUT PAS A PARTIR D'UN TEXTE. Une valeur
  /// inconnue rend `null` — donc le repli de prudence — plutot que de choisir
  /// au hasard parmi les quatre. Le geste se declare, il ne se deduit ni d'un
  /// nom de fontaine ni d'une description.
  static WaterAction? depuisDonnee(Object? brut) {
    if (brut is! String) return null;
    for (final geste in WaterAction.values) {
      if (geste.versDonnee == brut) return geste;
    }
    return null;
  }

  /// LE MEILLEUR GESTE PARMI [gestes], ou `null` si aucun ne donne d'eau.
  ///
  /// A QUOI CA SERT : une etape peut porter plusieurs points d'eau. L'etape 3
  /// du Mare a Mare Centre en porte deux — la source thermale de Guitera, qui
  /// ne se boit pas, et la Funtana di Croce, qui se filtre. Ce que le marcheur
  /// aura a faire en arrivant la, c'est le geste le MOINS exigeant de ceux qui
  /// donnent de l'eau : filtrer.
  ///
  /// Les gestes qui ne donnent rien sont ecartes d'abord. Quand il ne reste
  /// rien, l'etape ne porte pas d'eau utilisable, et c'est `null` qui le dit.
  static WaterAction? meilleur(Iterable<WaterAction> gestes) {
    WaterAction? retenu;
    for (final geste in gestes) {
      if (!geste.donneDeLEau) continue;
      if (retenu == null || geste.index < retenu.index) retenu = geste;
    }
    return retenu;
  }
}
