/// LE NIVEAU D'UN AXE, EXPRIME EN NOMBRE D'ICONES — zero a quatre.
library;

/// LE NIVEAU QU'UNE RANGEE D'ICONES AFFICHE (tache 862).
///
/// POURQUOI UN NOMBRE D'ICONES ET PAS UNE ICONE QUI CHANGE DE COULEUR.
/// Christophe, 21/10/2026 08:16 : « rien, 1 vert, 2 orange, 3 rouge, 4 noirs
/// [...] rien en dessous de 50 m ». Le COMPTAGE porte l'information EN PLUS de
/// la couleur, et c'est ce qui rend la rangee lisible pour une personne qui ne
/// distingue pas le vert du rouge — environ 8 % des hommes et 0,5 % des femmes
/// (deficience rouge-vert). Elle COMPTE au lieu de distinguer une teinte.
///
/// C'EST L'EXIGENCE WCAG 1.4.1 « Use of Color », de niveau A, donc le niveau
/// le plus exigeant a satisfaire et pas un bonus : la couleur ne doit jamais
/// etre le SEUL moyen visuel de transmettre une information. Le nombre
/// d'icones la satisfait sans rien ajouter a l'ecran, et c'est plus elegant
/// qu'une difference de forme.
///
/// LES QUATRE FRONTIERES NE SONT PAS ICI, ET C'EST VOLONTAIRE. Ce type ne dit
/// QUE le rendu. Les frontieres vivent dans les deux lois qui les ont deja
/// publiees — `NoteDeRaideur` pour les bandes de l'IMBA, `NoteDEffort` pour
/// les seuils du bareme francais — et chaque loi calcule elle-meme le niveau
/// de son axe. UNE SEULE SOURCE DE VERITE : si une frontiere bouge un jour, la
/// note et l'icone bougent ensemble parce qu'elles lisent la meme constante.
enum NiveauDIcone {
  /// Rien a signaler : sous la premiere frontiere publiee de l'axe.
  ///
  /// L'ABSENCE EST UN ETAT, PAS UN TROU. Le metier lui-meme ne gradue rien a
  /// ce niveau : l'IMBA ne commence a classer qu'a partir de 50 m de montee
  /// par kilometre. Afficher un glyphe pour dire qu'il n'y a rien a dire est
  /// du bruit — la PRESENCE de la montagne veut alors dire quelque chose par
  /// elle-meme.
  ///
  /// CE N'EST JAMAIS « ON NE SAIT PAS ». Une mesure absente ne produit aucune
  /// rangee d'icones du tout : elle est NOMMEE en texte, en amont, par
  /// `SentierPese.mesuresManquantes`. Les deux cas ne se rencontrent jamais au
  /// meme endroit de l'ecran.
  aucun(0),

  /// Au-dessus de la premiere frontiere publiee.
  une(1),

  /// Au-dessus de la deuxieme.
  deux(2),

  /// Au-dessus de la troisieme.
  trois(3),

  /// Au-dessus de la quatrieme et derniere frontiere publiee.
  ///
  /// Sur l'axe raideur, c'est aussi l'etat ou la note s'ecrete : la bande la
  /// plus raide que l'IMBA publie est le plafond de l'axe.
  quatre(4);

  const NiveauDIcone(this.nombreDIcones);

  /// COMBIEN D'ICONES CETTE RANGEE PORTE. C'est le niveau lui-meme.
  final int nombreDIcones;

  /// LE NOMBRE MAXIMUM D'ICONES, donc la largeur a reserver dans une liste.
  ///
  /// Une colonne dont la largeur change d'une ligne a l'autre se parcourt mal :
  /// le regard perd le bord sur lequel il s'aligne. La pratique est de
  /// RESERVER la place du maximum et d'y poser les icones presentes, plutot
  /// que de laisser la rangee se recentrer a chaque ligne.
  static const int maximum = 4;

  /// LE NIVEAU CORRESPONDANT A UN NOMBRE D'ICONES, pour relire un releve.
  static NiveauDIcone pourNombre(int nombre) =>
      NiveauDIcone.values[nombre.clamp(0, maximum)];
}
