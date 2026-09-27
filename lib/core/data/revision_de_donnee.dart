/// LA REVISION — UN SEUL NUMERO, PORTE PAR LA DONNEE ELLE-MEME.
///
/// DECISION DE CHRISTOPHE DU 27/09 20:43, verbatim : « On ne met qu une info de
/// version sur chaque donnee, l appli regarde juste quelles donnees ne sont pas
/// dans la derniere version et les telecharge ».
///
/// LE MODELE, EN TROIS PHRASES.
///  1. Chaque enregistrement telechargeable — une etape, un point d interet, un
///     hebergement, une trace, la fiche — porte [champRevision] : le numero de la
///     revision ou il a ete modifie pour la derniere fois.
///  2. Le sentier a une REVISION COURANTE (`TrailManifestEntry.dataVersion`), et
///     le telephone retient UNE seule valeur par sentier : la revision jusqu a
///     laquelle il est a jour (`trail_manifests.localVersion`).
///  3. L application demande TOUT CE QUI PORTE UN NUMERO PLUS RECENT QUE LE
///     SIEN. Une seule question, quelle que soit la taille du changement.
///
/// CE QUE CE MODELE SUPPRIME, ET C EST SA VERTU. Il n y a plus rien a INFERER :
/// pas de liste de tables changees, pas de comparaison par famille, pas de
/// version par table. `DeltaUpdateService._inferChangedTables(int from, int to)`
/// — qui rendait les sept tables en dur sans jamais lire ses deux parametres —
/// n a pas ete remplacee par quelque chose de plus fin : la question « qu est-ce
/// qui a bouge » ne se DEDUIT plus, elle se LIT dans la donnee.
///
/// UN SEUL CHEMIN DE CODE POUR LA PREMIERE COPIE ET POUR LA MISE A JOUR. Un
/// sentier jamais telecharge est a la revision ZERO : tout est plus recent que sa
/// revision, donc tout descend. Premier telechargement et mise a jour sont
/// litteralement le meme code — et c est le signe que le modele est le bon.
///
/// LES SUPPRESSIONS, QUE LE NUMERO CROISSANT NE PEUT PAS DIRE SEUL. Avec un
/// numero qui ne fait que monter, une donnee EFFACEE cote serveur ne redescend
/// jamais : un point d eau tari, un refuge ferme, un point d interet retire
/// resteraient A VIE sur le telephone du randonneur, et la correction de donnees
/// ne marcherait que dans un sens. D ou [champSupprime] : la donnee redescend
/// avec sa revision ET une marque qui dit « celle-la, retire-la ». C est un
/// MARQUEUR DE SUPPRESSION (pierre tombale), pas une absence — une absence ne se
/// transmet pas.
abstract final class RevisionDeDonnee {
  RevisionDeDonnee._();

  /// Nom du champ de revision dans les donnees publiees.
  static const String champRevision = 'rev';

  /// Nom du marqueur de suppression dans les donnees publiees.
  static const String champSupprime = 'supprime';

  /// Revision de la premiere ouverture : rien n est copie, tout est plus recent.
  static const int revisionInitiale = 0;

  /// COMBIEN DE REVISIONS DE MARQUEURS LE SERVEUR GARDE — ET DONC JUSQU OU UN
  /// TELEPHONE EN RETARD PEUT ENCORE RATTRAPER PAR MORCEAUX.
  ///
  /// LE PROBLEME QUE CE NOMBRE TRANCHE (#X5, ouvert depuis le lot 606). Les
  /// marqueurs de suppression s accumulent dans le fichier publie, indefiniment :
  /// #R9 disait « garder le marqueur jusqu a ce que tous les telephones aient
  /// depasse sa revision », condition INOBSERVABLE puisque l application ne
  /// rapporte sa revision a personne. La retention est donc FIXE — dix
  /// revisions — plutot qu un flux de telemetrie qui poserait une question RGPD
  /// pour un simple menage de fichier.
  ///
  /// LES DEUX COTES LISENT CE MEME NOMBRE, ET CE N EST PAS UNE COMMODITE : C EST
  /// CE QUI REND LA REGLE VRAIE. L outil de publication garde les marqueurs dont
  /// la revision depasse `revisionCourante - fenetreDeRetention`
  /// ([marqueurAConserver]) ; l application exige une copie complete des que son
  /// retard depasse la MEME fenetre ([exigeUneCopieComplete]).
  ///
  /// DEMONSTRATION. Un telephone a la revision L face a un serveur a la revision
  /// N a besoin de TOUS les marqueurs de revision comprise dans `]L, N]`. Le
  /// serveur conserve ceux de revision `> N - fenetre`. Les deux ensembles
  /// coincident si et seulement si `N - L <= fenetre`. Au-dela, des suppressions
  /// ont ete purgees sans avoir jamais ete transmises : une mise a jour par
  /// morceaux laisserait DEFINITIVEMENT sur le telephone un point d eau tari ou
  /// un refuge ferme. D ou la copie complete, qui est la seule reponse correcte.
  ///
  /// Deux constantes independantes auraient donne un decalage silencieux, et du
  /// mauvais cote : l application se croirait a jour.
  static const int fenetreDeRetention = 10;

  /// Vrai si le retard du telephone depasse la fenetre de retention serveur.
  ///
  /// Dans ce cas la mise a jour par morceaux n est plus « moins efficace », elle
  /// est INSUFFISANTE. La seule reponse correcte est de reprendre le sentier
  /// depuis la revision zero en effacant d abord ce qui est en base — c est ce
  /// que fait `DeltaUpdateService.synchroniser`.
  ///
  /// Un telephone qui n a RIEN (revision zero) ne releve pas de ce cas : il
  /// prend deja tout, par le chemin normal.
  static bool exigeUneCopieComplete({
    required int revisionLocale,
    required int revisionCible,
  }) {
    if (revisionLocale <= revisionInitiale) return false;
    return revisionCible - revisionLocale > fenetreDeRetention;
  }

  /// Vrai si un marqueur de revision [rev] doit encore etre publie quand le
  /// sentier atteint [revisionCourante].
  ///
  /// C est la moitie SERVEUR de la meme regle, et elle vit ici pour que l outil
  /// de publication et l application ne puissent pas diverger.
  static bool marqueurAConserver({
    required int rev,
    required int revisionCourante,
  }) {
    return rev > revisionCourante - fenetreDeRetention;
  }

  /// Revision portee par [donnee], ou [defaut] si elle n en declare pas.
  ///
  /// UNE DONNEE SANS REVISION EST TRAITEE COMME APPARTENANT A LA REVISION
  /// COURANTE DU SENTIER, et ce choix est deliberе : les fichiers de donnees
  /// deja deposes (et les quatre sentiers embarques) n ont pas de champ `rev`.
  /// Les ignorer rendrait un sentier existant intelligible mais non copiable ;
  /// les traiter comme « toujours a jour » les rendrait incorrigibles. Les
  /// rattacher a la revision courante donne le comportement attendu : a la
  /// premiere copie tout descend, et une republication qui incremente la revision
  /// du sentier fait redescendre ce qui n a pas de numero propre.
  static int revisionDe(Map<String, dynamic> donnee, {required int defaut}) {
    final brut = donnee[champRevision];
    if (brut is int) return brut;
    if (brut is num) return brut.toInt();
    return defaut;
  }

  /// Vrai si [donnee] est un marqueur de suppression.
  static bool estSupprimee(Map<String, dynamic> donnee) =>
      donnee[champSupprime] == true;

  /// Vrai si [donnee] doit descendre sur le telephone.
  ///
  /// C est LA question, et il n y en a pas d autre : « ta revision est-elle plus
  /// recente que la mienne ? ».
  static bool aPrendre(
    Map<String, dynamic> donnee, {
    required int revisionLocale,
    required int revisionDuSentier,
  }) {
    return revisionDe(donnee, defaut: revisionDuSentier) > revisionLocale;
  }
}
