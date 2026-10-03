import 'trail_manifest.dart';

/// CE QUI DESCEND SUR LE TELEPHONE, ET JUSQU OU.
///
/// DEMANDE DE CHRISTOPHE DU 28/09 11:27, verbatim : « Attention de ne pas
/// telecharger les donnees inutiles quand on prepare avec pub et quand on prepare
/// en ayant achete le sentier ».
///
/// AVANT CE LOT C ETAIT TOUT OU RIEN : le geste « telecharger » appelait
/// `DeltaUpdateService.synchroniser`, qui posait les SEPT familles de
/// [MorceauxDeSentier], trace et points de trace compris, pour n importe quel
/// usage. Un randonneur qui regardait simplement si un sentier lui plaisait payait
/// le meme transport, le meme espace disque et la meme latence d affichage qu un
/// randonneur qui part le lendemain.
///
/// POURQUOI CE N EST PAS UN DETAIL, ET LES DEUX CHIFFRES SONT MESURES, PAS
/// SUPPOSES. Le chiffrage de la tache 608 a etabli que les tuiles de carte pesent
/// 260 Mo en z10-16 pour un sentier. Et la mesure de la tache 615 : lire une trace
/// de 10 000 points prend 18,6 ms sur le fil d affichage, 49,9 ms a 20 000 points.
/// Le volumineux coute donc trois fois — le forfait du randonneur, la place sur son
/// telephone, et la fluidite de son ecran.
///
/// LA NUANCE QUI COMPTE, ET ELLE EST CONTRE-INTUITIVE : « PREPARER AVEC LA
/// PUBLICITE » ET « PREPARER APRES AVOIR ACHETE » DEMANDENT EXACTEMENT LES MEMES
/// DONNEES. Ce qui change entre ces deux cas est la publicite (niveau gratuit) et
/// le DROIT de realiser (`MonetizationService.canRealizeTrail`) — pas le volume. Il
/// n existe donc PAS de niveau « preparer gratuitement » distinct d un niveau
/// « preparer en ayant paye » : ce serait un quatrieme barreau qui ne transporterait
/// rien de plus. La vraie frontiere de volume est entre [preparer] et [realiser].
///
/// LES TROIS NIVEAUX DECOULENT DES TROIS ETATS DU 27/09 20:41 (`TrailState`),
/// ils ne les doublent pas : l etat dit CE QUE LE RANDONNEUR A FAIT (vu au
/// catalogue, telecharge, achete), le niveau dit CE QUI EST DESCENDU. Un sentier
/// achete mais seulement prepare est un cas normal et attendu.
enum NiveauDeTelechargement {
  /// NIVEAU 1 — REGARDER : RIEN NE DESCEND. Zero enregistrement, zero octet.
  ///
  /// La fiche d affichage (nom, region, distance, denivele, nombre d etapes,
  /// prix) est DEJA portee par la liste distante elle-meme
  /// (`TrailManifestEntry.fiche`, tache 605) et conservee en base pour survivre au
  /// hors-ligne (`trail_manifests.ficheJson`). Il n y a donc litteralement rien a
  /// telecharger pour decider si un sentier plait : la carte du catalogue
  /// s affiche entierement avec ce que la lecture de la liste a deja rapporte.
  ///
  /// CE NIVEAU N EST PAS UNE FORMALITE — C EST LUI QUI REPOND A CHRISTOPHE. Le
  /// demander doit produire un bilan a zero sans ouvrir la moindre connexion vers
  /// le fichier de donnees, et c est verifie par un test qui COMPTE.
  regarder,

  /// NIVEAU 2 — PREPARER : DE QUOI CALCULER LA FAISABILITE ET REMPLIR LE SAC.
  ///
  /// Les etapes et leurs deniveles (faisabilite, programme), les hebergements
  /// (reservations, etapes du sac), les points d interet (eau, ravitaillement) et
  /// la fiche du sentier avec ses itineraires. PAS LE VOLUMINEUX : ni la trace ni
  /// ses points.
  ///
  /// POURQUOI LA TRACE N EST PAS ICI, ALORS QU ON POURRAIT LA DESSINER. Parce que
  /// preparer se fait sur les CHIFFRES des etapes, pas sur la geometrie : distance,
  /// denivele positif, denivele negatif et duree sont des colonnes de `stages`. La
  /// trace ne sert qu a marcher — la suivre sur le terrain, se situer, mesurer
  /// l ecart. C est le seul usage qui la justifie, et c est [realiser].
  preparer,

  /// NIVEAU 3 — REALISER : TOUT.
  ///
  /// Les sept familles, trace complete et points de trace compris, plus les cartes
  /// hors ligne. C est le niveau du randonneur qui part : sur le GR20 il n y a pas
  /// de reseau, et ce qui manque a ce moment-la manque definitivement.
  ///
  /// LES CARTES DESCENDENT ICI, ET NULLE PART AILLEURS (tache 622). Le paragraphe
  /// qui occupait cette place disait le contraire, et il avait raison de le dire :
  /// « le telechargement existe (`MBTilesManager.downloadMbtiles`) mais AUCUN CODE
  /// DE PRODUCTION NE L APPELLE, et la liste distante ne porte AUCUN champ donnant
  /// l adresse du fichier de tuiles ». Les deux moities du trou sont fermees — la
  /// liste distante declare desormais ses tuiles (`TrailManifestEntry.tilesPath`,
  /// `tilesSize`, `tilesHash`) et un seul chemin les fait descendre
  /// ([MapDownloader]), depuis le geste qui demande CE niveau.
  ///
  /// CE NIVEAU NE SUFFIT PAS A LUI SEUL, et c est la seule nuance : il dit que les
  /// cartes SONT de ce niveau, il ne dit pas que le randonneur y a droit. Realiser
  /// est lie a avoir PAYE (modele economique §2), sauf le sentier gratuit dont le
  /// prix est nul (§2 bis) — ce droit se lit une seule fois, dans
  /// `MonetizationService.canRealizeTrail`, et [MapDownloader] le consulte
  /// AVANT d ouvrir la moindre connexion.
  realiser;

  /// VRAI SI CE NIVEAU FAIT DESCENDRE LES CARTES HORS LIGNE (tache 622).
  ///
  /// UN SEUL ENDROIT DECIDE, ET C EST CELUI-CI. La question « faut-il les tuiles ? »
  /// se posait a zero endroit avant ce lot (personne n appelait le telechargement) ;
  /// elle pourrait maintenant se reposer dans le service de descente, dans l ecran
  /// du catalogue et dans la cadence, avec trois reponses qui finiraient par
  /// diverger — c est mot pour mot la lecon des trois copies de l ordre d insertion
  /// que la tache 605 a du reduire a une, et celle des deux mecanismes de limitation
  /// que la tache 616 a du reduire a un.
  ///
  /// POURQUOI [preparer] REPOND NON, ALORS QU ON POURRAIT DEJA AFFICHER UNE CARTE.
  /// Demande de Christophe du 27/09, verbatim : « Attention de ne pas telecharger
  /// les donnees inutile quand on prepare avec pub et quand on prepare en ayant
  /// achete le sentier ». Preparer se fait sur les CHIFFRES des etapes ; la carte
  /// affichee pendant la preparation est celle du reseau, qui est la par definition
  /// — on prepare chez soi. Les 260 Mo mesures par la tache 608 ne servent qu a
  /// marcher la ou il n y a pas de reseau, et c est [realiser].
  ///
  /// LES DEUX CAS DE PREPARATION REPONDENT PAREIL, ET C EST VOLONTAIRE : qu il ait
  /// paye ou non, un randonneur qui PREPARE ne recoit aucune tuile. L achat ne
  /// change pas le volume, il change le DROIT de realiser — la nuance est deja
  /// ecrite en tete de cette enumeration, et ce getter ne l ouvre pas.
  bool get porteLesCartes => this == NiveauDeTelechargement.realiser;

  /// LES FAMILLES DE DONNEES QUE CE NIVEAU FAIT DESCENDRE, DANS L ORDRE DES CLES
  /// ETRANGERES.
  ///
  /// L ordre est celui de [MorceauxDeSentier.tous] et il n est pas decoratif : un
  /// hebergement rattache a une etape qui n existe pas encore echoue. Les listes
  /// ci-dessous sont donc DERIVEES de cet ordre, jamais reecrites a la main.
  List<String> get familles => switch (this) {
    NiveauDeTelechargement.regarder => const <String>[],
    NiveauDeTelechargement.preparer => _famillesPreparer,
    NiveauDeTelechargement.realiser => MorceauxDeSentier.tous,
  };

  /// LE VOLUMINEUX, NOMME UNE SEULE FOIS.
  ///
  /// C est exactement ce qui separe [preparer] de [realiser]. Une seule definition,
  /// parce que trois listes redecouvertes chacune de leur cote finissent par
  /// diverger — c est la lecon des trois copies de l ordre d insertion que la tache
  /// 605 a du reduire a une.
  static const List<String> volumineux = <String>[
    MorceauxDeSentier.traces,
    MorceauxDeSentier.pointsDeTrace,
  ];

  static final List<String> _famillesPreparer = MorceauxDeSentier.tous
      .where((f) => !volumineux.contains(f))
      .toList(growable: false);

  /// Vrai si ce niveau fait descendre [famille].
  bool porte(String famille) => familles.contains(famille);

  /// Vrai si ce niveau descend AU MOINS tout ce que descend [autre].
  ///
  /// LES TROIS NIVEAUX SONT EMBOITES, et c est ce qui rend la question « faut-il
  /// completer ? » decidable : regarder ⊂ preparer ⊂ realiser. Sans emboitement,
  /// passer d un niveau a l autre demanderait de calculer une difference de
  /// familles dans les deux sens.
  bool couvre(NiveauDeTelechargement autre) => index >= autre.index;

  /// Nom stable pour la persistance. JAMAIS [Enum.name] directement en base.
  ///
  /// Une valeur ecrite dans `trail_manifests.niveauLocal` doit survivre a un
  /// renommage de la constante Dart : un refactoring d editeur ne doit pas rendre
  /// illisibles les reperes deja poses sur les telephones.
  String get code => switch (this) {
    NiveauDeTelechargement.regarder => 'regarder',
    NiveauDeTelechargement.preparer => 'preparer',
    NiveauDeTelechargement.realiser => 'realiser',
  };

  /// Relit un niveau persiste. Valeur absente ou inconnue = [regarder].
  ///
  /// LE REPLI EST LE NIVEAU LE PLUS BAS, ET C EST DELIBERE. Une valeur illisible
  /// signifie « je ne sais pas ce qui est descendu » ; repondre [realiser] ferait
  /// croire le telephone complet sur des donnees peut-etre absentes, et la
  /// synchronisation periodique n irait jamais les chercher. Repondre [regarder]
  /// fait au pire recopier, jamais rater.
  static NiveauDeTelechargement? depuisLeCode(String? code) => switch (code) {
    'regarder' => NiveauDeTelechargement.regarder,
    'preparer' => NiveauDeTelechargement.preparer,
    'realiser' => NiveauDeTelechargement.realiser,
    _ => null,
  };
}
