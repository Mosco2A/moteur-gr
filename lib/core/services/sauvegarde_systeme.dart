/// LA SAUVEGARDE DU TELEPHONE PAR SON PROPRE SYSTEME — DECLAREE A UN SEUL
/// ENDROIT (tache 612, decision de Christophe du 28/09 10:49 ; ELARGIE A TOUTES
/// LES FAMILLES DE DONNEES par sa regle generale du 28/09 14:31).
///
/// LA REGLE, VERBATIM : « on ne partage aucune donnee confiee sauf si le client
/// decoche volontairement ». Elle repondait a une question sur le poids et la
/// taille, et Christophe a repondu par une regle GENERALE. Elle vaut donc pour
/// TOUT ce que le randonneur confie : profil (age, taille, poids), randonnees
/// passees, progression, journal, photos, solde d'etapes, fiche medicale.
///
/// DEUX SUJETS QUI NE DOIVENT JAMAIS SE CONFONDRE, ni dans le code ni a
/// l'ecran :
///
///  1. NOS SERVEURS. Rien de ce que le randonneur confie n'y va, dans aucun cas,
///     case cochee ou non. Pour la fiche medicale c'est acquis par construction
///     depuis la tache 612 (`HealthBackupService` supprime, transport limite a
///     [DocumentsDuCoffreDistant.autorises]). CE FICHIER NE PARLE PAS DE CA.
///
///  2. LA SAUVEGARDE DU TELEPHONE PAR GOOGLE OU PAR APPLE. Elle ne nous
///     appartient pas, elle est activee par defaut sur les deux plateformes, et
///     c'est ELLE que la case pre-cochee de refus gouverne. C'est le sujet de ce
///     fichier.
///
/// Si l'ecran melangeait les deux, le randonneur croirait que NOUS recuperons
/// son journal quand il decoche. Nous ne l'avons jamais, dans aucun cas. La
/// tache 612 avait pose ce principe dans les seuls textes de la sante ; la tache
/// 617 l'etend a toutes les familles, parce qu'un randonneur qui lit « je refuse
/// la sauvegarde de mes donnees » sans cette phrase comprend l'inverse.
///
/// ---------------------------------------------------------------------------
/// LE RENVERSEMENT DE LA TACHE 617 : ON NE LISTE PLUS CE QUI NE PART PAS, ON
/// LISTE CE QUI PART — ET LA LISTE EST VIDE PAR DEFAUT
/// ---------------------------------------------------------------------------
///
/// Les taches 612 et 613 declaraient des EXCLUSIONS : une liste de ce qui ne
/// monte pas. Ce montage a un defaut de fond, et il s'est deja manifeste deux
/// fois dans ce depot : une liste d'exclusions doit etre TENUE A JOUR. Tout
/// stockage ajoute plus tard part par defaut, en silence, et personne ne le voit
/// — la tache 613 a mesure une exclusion qui portait sur un dossier VIDE
/// (`database`), et la tache 615 a trouve une fiche medicale qui montait dans
/// iCloud parce que le montage Android n'avait pas d'equivalent iPhone.
///
/// SOURCE VERIFIEE AVANT D'ETRE UTILISEE (documentation Android, « Back up user
/// data with Auto Backup », lue le 28/09), mot pour mot : « By default, Auto
/// Backup includes almost all app files. If you specify an `<include>` element,
/// the system no longer includes any files by default and backs up ONLY the
/// files specified. »
///
/// LE MONTAGE EST DONC INVERSE. Les deux fichiers de regles Android ne portent
/// plus une liste de ce qui reste dehors : ils portent UNE SEULE INCLUSION
/// ([inclusions]), le dossier [dossierSauvegardable]. Consequence directe :
/// TOUT LE RESTE EST DEHORS PAR DEFAUT — la base (progression, journal, trace,
/// solde, sentiers telecharges), les photos du journal, les preferences (profil,
/// age, taille, poids, randonnees passees), les paquets et les tuiles de carte,
/// la fiche medicale. Et un stockage ajoute demain est dehors LUI AUSSI, sans
/// que personne n'ait a y penser.
///
/// CE DOSSIER EST VIDE TANT QUE LE RANDONNEUR N'A PAS DECOCHE. La case pilote la
/// presence de COPIES dedans, pas le comportement du systeme — c'est le montage
/// de la tache 612, et il n'a pas change, il s'applique maintenant a toutes les
/// familles.
///
/// L'EXCLUSION DE `medical/` RESTE ECRITE ([exclusions]), ET CE N'EST PAS UNE
/// REDONDANCE PARESSEUSE. Avec une inclusion unique elle ne protege rien de plus
/// AUJOURD'HUI. Elle protege contre DEMAIN : le jour ou quelqu'un ajoute une
/// seconde inclusion un peu large (`root`, ou `file` tout entier), la donnee de
/// l'article 9 resterait dehors — et ce n'est pas une esperance, c'est ecrit :
/// « If your configuration file specifies both elements, then the backup
/// contains everything captured by the `<include>` elements minus the resources
/// named in the `<exclude>` elements. In other words, `<exclude>` takes
/// precedence. » C'est un second verrou, et il est le seul a porter la decision
/// du 28/09 10:42 (« NON ON NE TROUVERAIT RIEN !!! Les donnees medicales RESTENT
/// sur le tel !!! »).
///
/// ---------------------------------------------------------------------------
/// CE QUE J'AI MESURE LE 28/09, DOMAINE PAR DOMAINE — AU LIEU DE LE SUPPOSER
/// ---------------------------------------------------------------------------
///
/// La tache 613 a prouve qu'un domaine pouvait designer autre chose que ce qu'on
/// croyait. Les domaines Android ont donc ete releves sur le code, appel par
/// appel (`getApplicationDocumentsDirectory`, `getApplicationSupportDirectory`,
/// `SharedPreferences`), et confrontes a la definition de chacun dans la
/// documentation citee plus haut :
///
///  * `root` (« the directory on the file system where all private files
///    belonging to this app are stored ») — LE PLUS CHARGE, ET IL N'ETAIT PAS
///    DECLARE. `getApplicationDocumentsDirectory()` rend `app_flutter/` sous le
///    repertoire de donnees, donc domaine `root`. Y vivent : la base
///    `stepways.sqlite` (progression, journal, trace, solde, sentiers
///    telecharges), `journal_photos/` (les photos du randonneur), `packs/`,
///    `mbtiles/`, les exports GPX et les diplomes PDF.
///  * `file` (« directories returned by getFilesDir() ») —
///    `getApplicationSupportDirectory()` rend `files/`. Y vivent `medical/`
///    (fiche medicale, tache 613) et [dossierSauvegardable] (les copies).
///  * `sharedpref` (« the directory where SharedPreferences are stored ») — LE
///    PROFIL RANDONNEUR Y VIT : `hiker.profile` (age, taille, poids),
///    `hiker.pastHikes`, `hiker.walkTestResult`, plus le solde et les reglages.
///    `hiker_profile_repository.dart` le nommait lui-meme comme un trou ouvert
///    depuis la tache 613.
///  * `database` (« directories returned by getDatabasePath() ; databases
///    created with SQLiteOpenHelper are stored here ») — VIDE, et la mesure de
///    la tache 613 est CONFIRMEE : une application Flutter n'y ecrit jamais.
///  * `external` (« the directory returned by getExternalFilesDir() ») — aucun
///    appel dans `lib/`, donc rien.
///
/// AUCUN de ces domaines n'etait dehors avant ce lot, sauf `file/medical/`.
/// L'inclusion unique les met tous dehors d'un coup, y compris ceux qu'on
/// n'aurait pas pensé a lister.
///
/// [MESURE — CE QUI N'EST DE TOUTE FACON JAMAIS SAUVEGARDE] La meme page dit :
/// « Auto Backup excludes files in directories returned by getCacheDir(),
/// getCodeCacheDir(), and getNoBackupFilesDir() [...] always excluded even if
/// you try to include them. » Les tuiles en cache et `getTemporaryDirectory()`
/// (une seule utilisation, le partage de carte) sont donc hors sujet.
///
/// ---------------------------------------------------------------------------
/// LE TROU QUE JE NE PEUX PAS FERMER ICI, ET JE LE NOMME PLUTOT QUE DE LE TAIRE
/// ---------------------------------------------------------------------------
///
/// Voir [trouCrossPlatformTransfer] : une TROISIEME section de regles existe
/// depuis Android 16 QPR2, et son absence vaut autorisation.
///
/// ---------------------------------------------------------------------------
/// IPHONE — CE N'EST PAS LA MEME MECANIQUE, ET IL NE FAUT PAS L'UNIFORMISER
/// ---------------------------------------------------------------------------
///
/// Sur iOS l'exclusion n'est PAS declarative : elle se pose a l'execution,
/// fichier par fichier, avec `NSURLIsExcludedFromBackupKey`. Il n'y a aucun
/// equivalent de `dataExtractionRules` dans `Info.plist`, donc aucun equivalent
/// de l'inclusion unique : personne ne peut ecrire « ne sauvegarde rien sauf
/// ceci » a l'avance. La tache 615 a ouvert le canal natif pour la fiche
/// medicale ; la tache 617 le fait BALAYER TOUT LE STOCKAGE
/// (`GardeSauvegardeIos`), dossier par dossier et fichier par fichier, en
/// epargnant le seul [dossierSauvegardable].
///
/// Android par DECLARATION (les deux XML, fixes a la compilation, verifies par
/// invariante), iPhone par ATTRIBUT POSE A L'EXECUTION (verifie par invariante).
/// La case pre-cochee du randonneur, elle, dit la meme chose des deux cotes.
///
/// [LE SEUL STOCKAGE QUE L'IPHONE NE LAISSE PAS EXCLURE, MESURE ET NOMME]
/// Voir [trouUserDefaultsIos]. C'est le residu de ce lot, et il n'est pas
/// cosmetique : c'est la famille meme que Christophe a citee.
///
/// ---------------------------------------------------------------------------
/// LES INVARIANTES QUI TIENNENT TOUT CECI
/// ---------------------------------------------------------------------------
///
/// `test/comportement/fiche_medicale_locale_612_test.dart` lit le manifeste et
/// les deux fichiers de regles et exige qu'ils disent la MEME chose que ce
/// fichier pour les EXCLUSIONS, dans les deux sens.
///
/// `test/comportement/aucune_donnee_confiee_ne_sort_617_test.dart` fait le meme
/// travail pour les INCLUSIONS — et il fait plus : il exige qu'il y ait AU MOINS
/// une inclusion dans chaque section, parce qu'une section sans inclusion
/// sauvegarde tout. C'est le test qui donne son nom au lot.
///
/// `test/comportement/exclusion_icloud_615_test.dart` garde le mecanisme iPhone.
library;

/// Emplacements et regles de la sauvegarde systeme (Google / Apple).
abstract final class SauvegardeSysteme {
  /// Sous-dossier du stockage applicatif ou vit la fiche medicale, EXPLICITEMENT
  /// exclu en plus de l'etre par defaut (voir [exclusions]).
  ///
  /// Resolu sous `getApplicationSupportDirectory()`, ce qui donne
  /// `files/medical/` sur Android (domaine `file`) et
  /// `Library/Application Support/medical/` sur iPhone.
  static const String dossierExclu = 'medical';

  /// LE SEUL SOUS-DOSSIER INCLUS DANS LA SAUVEGARDE SYSTEME — et il est VIDE
  /// tant que le randonneur n'a pas decoche la case.
  ///
  /// C'est le pivot du montage : ce n'est plus « tout sauf une liste », c'est
  /// « rien sauf ce dossier » (voir [inclusions] et l'en-tete du fichier).
  static const String dossierSauvegardable = 'sauvegarde_systeme';

  /// Nom du fichier de la copie sauvegardable de la fiche medicale.
  static const String fichierCopieFiche = 'fiche_medicale.json';

  /// Nom du fichier de la copie sauvegardable de LA BASE (progression, journal,
  /// trace, treks realises, solde, sentiers telecharges).
  ///
  /// POURQUOI LA BASE A UNE COPIE ET PAS SEULEMENT LA FICHE MEDICALE. Sans elle,
  /// decocher la case n'aurait servi a rien pour les familles qui font tout le
  /// prix du geste : le randonneur decoche precisement pour ne pas perdre sa
  /// progression et son carnet. Une case qui ne change rien serait decorative,
  /// et le texte qui l'accompagne serait faux.
  static const String fichierCopieBase = 'stepways.sqlite';

  /// Chemin du fichier de regles Android 12 et au-dela
  /// (`android:dataExtractionRules`), relatif a la racine du depot.
  static const String reglesAndroid12EtPlus =
      'android/app/src/main/res/xml/regles_sauvegarde_donnees.xml';

  /// Chemin du fichier de regles Android 11 et en dessous
  /// (`android:fullBackupContent`), relatif a la racine du depot.
  static const String reglesAndroidAvant12 =
      'android/app/src/main/res/xml/regles_sauvegarde_complete.xml';

  /// Manifeste Android qui doit referencer les deux fichiers ci-dessus.
  static const String manifesteAndroid =
      'android/app/src/main/AndroidManifest.xml';

  /// LES SECTIONS DE REGLES D'ANDROID 12 ET AU-DELA QUI DOIVENT TOUTES PORTER
  /// [inclusions].
  ///
  /// `cloud-backup` gouverne la montee chez Google, `device-transfer` la copie
  /// directe d'un telephone a l'autre. Les regles sont SCOPEES PAR SECTION
  /// (documentation Android : « Each section of the configuration contains rules
  /// that apply only to that type of transfer ») : une inclusion posee dans la
  /// premiere ne protege RIEN dans la seconde. Une donnee qui refuse le nuage
  /// mais passe par le cable n'a pas quitte le telephone : elle a quitte CE
  /// telephone-la, ce que la decision interdit exactement.
  static const List<String> sectionsAndroid12EtPlus = [
    'cloud-backup',
    'device-transfer',
  ];

  /// CE QUI EST SAUVEGARDE, ET RIEN D'AUTRE — source unique de verite.
  ///
  /// Chaque entree est un couple `domaine` / `chemin`. Les deux fichiers de
  /// regles Android doivent porter EXACTEMENT ces inclusions, dans CHAQUE
  /// section, et l'invariante du lot 617 le verifie dans les deux sens.
  ///
  /// UNE SEULE ENTREE, ET C'EST TOUT LE LOT : le dossier des copies que le
  /// randonneur a explicitement acceptees. Tout le reste est dehors par defaut,
  /// sans avoir a etre nomme (voir l'en-tete : une inclusion desactive le defaut
  /// d'Android).
  static const List<({String domaine, String chemin})> inclusions = [
    (domaine: 'file', chemin: '$dossierSauvegardable/'),
  ];

  /// CE QUI EST EXPLICITEMENT EXCLU, EN PLUS DE L'ETRE PAR DEFAUT.
  ///
  /// Second verrou, pas protection principale : avec [inclusions] tout est deja
  /// dehors. Cette liste tient le jour ou quelqu'un ajoute une inclusion trop
  /// large — voir l'en-tete du fichier.
  static const List<({String domaine, String chemin})> exclusions = [
    // La fiche medicale, dans son dossier dedie (tache 613 : elle y a son propre
    // fichier). C'est la seule donnee pour laquelle Christophe a tranche deux
    // fois, et en majuscules.
    (domaine: 'file', chemin: '$dossierExclu/'),
  ];

  /// L'EXIGENCE IPHONE — NOMMEE PAR LE LOT 612, TENUE PAR LE LOT 615, ELARGIE
  /// PAR LE LOT 617.
  ///
  /// C'est le CONTRAT que `ExclusionSauvegardeIcloud` et `GardeSauvegardeIos`
  /// doivent honorer, et c'est le texte que l'invariante du lot 612 continue de
  /// lire. « A chaque ecriture » vient du lot 615 : l'ecriture de la fiche est
  /// ATOMIQUE, elle REMPLACE le fichier, et un fichier remplace ne porte plus
  /// l'attribut de celui qu'il remplace.
  static const String exigenceIosExclusion =
      'poser NSURLIsExcludedFromBackupKey = true sur le dossier "$dossierExclu" '
      'de Library/Application Support ET sur le fichier de la fiche, A CHAQUE '
      'creation OU remplacement, via un canal de methode natif — iOS n\'offre '
      'AUCUN equivalent declaratif de android:dataExtractionRules dans '
      'Info.plist, et une ecriture atomique fait perdre l\'attribut. TACHE 617 : '
      'la meme pose est etendue a TOUT le stockage confie (base, photos, '
      'paquets, tuiles), en epargnant le seul dossier '
      '"$dossierSauvegardable"';

  /// LE TROU ANDROID QUE CE LOT NE PEUT PAS FERMER, ET POURQUOI — pas un oubli.
  ///
  /// Documentation Android, mot pour mot : « If there are no rules for a
  /// particular backup mode, such as if the `<device-transfer>` section is
  /// missing, that mode is fully enabled for all content except for no-backup
  /// and cache directories. » Et : « Starting from Android 16 QPR2 (API level
  /// 36.1) you can configure Auto Backup for data transfers to and from
  /// non-Android devices [...] add the `<cross-platform-transfer>` element ».
  ///
  /// CONSEQUENCE MESUREE : sur un telephone Android 16 QPR2 ou plus recent, le
  /// transfert vers un appareil NON-Android emporte TOUT, y compris la fiche
  /// medicale, parce que nous ne declarons pas cette section. Ce trou existait
  /// deja apres les taches 612 et 615 ; il est nomme ici pour la premiere fois.
  ///
  /// POURQUOI JE NE LA DECLARE PAS MAINTENANT. La section exige un element
  /// `<platform-specific-params bundleId="..." teamId="..."
  /// contentVersion="..."/>`, dont les trois attributs sont requis. `bundleId`
  /// est dans le depot (`com.only1cent.stepways`), mais `teamId` est l'IDENTIFIANT
  /// D'EQUIPE APPLE et il n'apparait NULLE PART dans le projet Xcode
  /// (`DEVELOPMENT_TEAM` est absent du pbxproj). L'inventer ferait une
  /// declaration decorative qui ne protege rien — exactement le defaut que la
  /// tache 615 a refuse pour `Info.plist`, et exactement l'exclusion sur dossier
  /// vide que la tache 613 a trouvee. Il faut ce chiffre, il faut une
  /// verification sur un telephone Android 16 QPR2, et cela ne se fait pas ici.
  static const String trouCrossPlatformTransfer =
      'la section <cross-platform-transfer> (Android 16 QPR2, API 36.1) n\'est '
      'PAS declaree : son absence vaut autorisation complete vers un appareil '
      'non-Android. Elle exige platform-specific-params teamId, l\'identifiant '
      'd\'equipe Apple, absent du depot. A FERMER des que Christophe le fournit.';

  /// LE SEUL STOCKAGE QUE L'IPHONE NE LAISSE PAS EXCLURE, MESURE ET NOMME.
  ///
  /// `NSUserDefaults` (ce que `SharedPreferences` utilise sur iOS) n'est pas un
  /// fichier que l'application possede : c'est un domaine de preferences gere
  /// par le systeme, ecrit dans `Library/Preferences/<bundle>.plist`.
  /// `NSURLIsExcludedFromBackupKey` s'applique a une URL de fichier ou de
  /// dossier ; les valeurs de `NSUserDefaults` ne peuvent pas en etre exclues,
  /// ni globalement ni cle par cle. La tache 615 l'avait deja mesure en marge ;
  /// ce lot le confirme sur source externe et en tire la consequence.
  ///
  /// CE QUI RESTE DONC DANS iCLOUD SUR IPHONE, AUJOURD'HUI, MALGRE CE LOT :
  /// `hiker.profile` (age, taille, poids), `hiker.pastHikes`,
  /// `hiker.walkTestResult`, le solde d'etapes et les reglages. Sur ANDROID ces
  /// memes cles sont dehors depuis ce lot (domaine `sharedpref`, non inclus).
  ///
  /// LA SEULE FACON DE LE FERMER est de faire SORTIR ces cles de
  /// `SharedPreferences` vers un fichier, comme la tache 613 a fait sortir la
  /// fiche medicale de la base. Ce n'est pas fait ici : 28 fichiers de tests
  /// ecrivent ces cles directement, et renverser la persistance du profil dans
  /// le lot qui renverse celle de la sauvegarde ferait deux renversements a la
  /// fois. Point OUVERT, chiffre, pas oubli.
  static const String trouUserDefaultsIos =
      'sur iPhone, NSUserDefaults (SharedPreferences) ne peut PAS etre exclu de '
      'la sauvegarde iCloud : ce n\'est pas un fichier de l\'application mais un '
      'domaine de preferences du systeme. Le profil randonneur (age, taille, '
      'poids, randonnees passees, test de marche), le solde et les reglages y '
      'vivent encore et montent donc dans iCloud sur iPhone. Sur Android ils '
      'sont dehors (domaine sharedpref non inclus). A FERMER en sortant ces cles '
      'vers un fichier, comme la tache 613 l\'a fait pour la fiche medicale.';
}
