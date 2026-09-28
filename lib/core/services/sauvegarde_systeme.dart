/// LA SAUVEGARDE DU TELEPHONE PAR SON PROPRE SYSTEME — DECLAREE A UN SEUL
/// ENDROIT (tache 612, decision de Christophe du 28/09 10:49).
///
/// DEUX SUJETS QUI NE DOIVENT JAMAIS SE CONFONDRE, ni dans le code ni a
/// l'ecran :
///
///  1. NOS SERVEURS. La fiche medicale n'y va JAMAIS, dans aucun cas, case
///     cochee ou non. Decision du 28/09 10:42, verbatim et en majuscules dans
///     le message de Christophe : « NON ON NE TROUVERAIT RIEN !!! Les donnees
///     medicales RESTENT sur le tel !!! ». C'est acquis par construction :
///     `HealthBackupService` est supprime et le transport n'accepte que
///     [DocumentsDuCoffreDistant.autorises]. CE FICHIER NE PARLE PAS DE CA.
///
///  2. LA SAUVEGARDE DU TELEPHONE PAR GOOGLE OU PAR APPLE. Elle ne nous
///     appartient pas, elle est activee par defaut sur les deux plateformes, et
///     c'est ELLE que la case pre-cochee de refus gouverne. C'est le sujet de ce
///     fichier.
///
/// Si l'ecran melangeait les deux, le randonneur croirait que NOUS recuperons sa
/// fiche quand il decoche. Nous ne l'avons jamais, dans aucun cas.
///
/// ---------------------------------------------------------------------------
/// LA CONTRAINTE TECHNIQUE QUI DICTE LE MONTAGE, ET ELLE EST MESUREE
/// ---------------------------------------------------------------------------
///
/// L'exclusion d'un emplacement de la sauvegarde systeme N'EST PAS UN REGLAGE
/// PAR UTILISATEUR. Sur Android c'est une propriete DECLAREE DE L'APPLICATION,
/// fixee a la compilation (`android:dataExtractionRules` pour Android 12 et
/// au-dela, `android:fullBackupContent` en dessous). On ne peut pas l'allumer ou
/// l'eteindre selon une case cochee.
///
/// LE MONTAGE RETENU, ET C'EST LE SEUL QUI RESPECTE SON INTENTION ET LA
/// MECANIQUE DES PLATEFORMES : la fiche medicale vit dans un emplacement
/// DECLARE EXCLU ([dossierExclu]), donc elle ne part jamais, quoi qu'il arrive.
/// Si le randonneur DECOCHE la case, donc accepte la sauvegarde, l'application
/// ecrit une COPIE de la fiche dans un emplacement INCLUS dans la sauvegarde
/// ([dossierSauvegardable]). Le defaut ne fait rien partir ; decocher fait
/// apparaitre une copie sauvegardable. LA CASE PILOTE LA PRESENCE D'UNE COPIE,
/// PAS LE COMPORTEMENT DU SYSTEME.
///
/// ---------------------------------------------------------------------------
/// CE QUE J'AI MESURE LE 28/09 ET QUI NUANCE LA PREMISSE
/// ---------------------------------------------------------------------------
///
/// [MESURE 1 — ANDROID] Le depot ne declarait AUCUNE exclusion : ni
/// `allowBackup`, ni `dataExtractionRules`, ni `fullBackupContent`. Le defaut
/// d'Android est `allowBackup="true"`, donc tout le repertoire de donnees de
/// l'application montait chez Google. Les deux fichiers de regles existent
/// desormais ([reglesAndroid12EtPlus], [reglesAndroidAvant12]) et le manifeste
/// les reference.
///
/// [MESURE 2 — LA BASE EST DEVENUE DURABLE, ET CETTE MESURE A CHANGE DE SIGNE
/// (tache 613)] La 612 avait mesure que la base etait ouverte EN MEMOIRE : la
/// fiche medicale ne montait pas chez Google, non parce qu'on la protegeait mais
/// parce qu'elle ne persistait pas. Protection par accident, dont la 612 avait
/// ecrit qu'elle « tombera le jour ou la base deviendra durable ». Ce jour est
/// arrive : la base vit dans un fichier depuis la tache 613. La protection n'est
/// plus un accident — la fiche medicale a son PROPRE fichier sous [dossierExclu]
/// (`FicheMedicaleFichier`), et plus une seule ligne de production n'ecrit de
/// donnee medicale dans la base.
///
/// [MESURE 3 — L'EXCLUSION DU DOMAINE `database` EST RETIREE, POUR DEUX RAISONS
/// QUI SE CUMULENT (tache 613)]
///
///  a. ELLE COUTAIT CE QUE LA 612 AVAIT ANNONCE. Son motif etait que la table
///     `health_info` partageait le fichier de la progression et du journal. Ce
///     motif a disparu : la fiche a son propre fichier. Le garder aurait fait
///     perdre la progression et le carnet au changement de telephone, alors que
///     le modele economique promet qu'un trek realise garde A VIE sa trace et son
///     carnet. Une promesse a vie ne survit pas a un changement d'appareil si le
///     fichier qui la porte est exclu de la sauvegarde.
///
///  b. ELLE NE PROTEGEAIT DE TOUTE FACON PAS CE QU'ON CROYAIT, ET C'EST MESURE.
///     Le domaine `database` des regles Android designe
///     `/data/data/<paquet>/databases/`, la ou Android range les bases ouvertes
///     par son propre `SQLiteOpenHelper`. Une application Flutter n'y ecrit
///     jamais : la base de StepWays vit sous le repertoire de documents
///     (`app_flutter/`), donc dans le domaine `root`. L'exclusion portait sur un
///     dossier vide. Elle aurait donne une fausse tranquillite le jour ou la
///     base est devenue durable — exactement le jour ou on en avait besoin.
///
/// CE QUI EXCLUT REELLEMENT LA DONNEE MEDICALE est donc la premiere ligne, et
/// elle seule : le dossier [dossierExclu] sous le stockage applicatif
/// (`files/medical/` sur Android, domaine `file`).
///
/// [MESURE 4 — IPHONE, ET CE N'EST PAS LA MEME MECANIQUE] Sur iOS l'exclusion
/// de la sauvegarde iCloud n'est PAS declarative : elle se pose a l'execution,
/// fichier par fichier, avec `NSURLIsExcludedFromBackupKey` sur l'URL. Il n'y a
/// aucun equivalent de `dataExtractionRules` dans `Info.plist`. Ce que ce
/// fichier declare pour iOS est donc une EXIGENCE nommee
/// ([exigenceIosExclusion]), pas un fait acquis — sur le meme patron que
/// [CoffreDeReconnexion] : on declare l'etat reel et on nomme ce qui manque,
/// plutot que de laisser croire que c'est fait. CET ECART EST DEVENU REEL AVEC LA
/// TACHE 613 : un fichier medical durable existe desormais sous [dossierExclu],
/// donc sur iPhone il monte aujourd'hui dans iCloud. C'est LE point ouvert de ce
/// lot, il demande un canal de methode natif, et il est nomme ici pour ne pas
/// etre perdu.
///
/// ---------------------------------------------------------------------------
/// UNE INVARIANTE TIENT TOUT CECI
/// ---------------------------------------------------------------------------
///
/// `test/comportement/fiche_medicale_locale_612_test.dart` lit le manifeste et
/// les deux fichiers de regles et exige qu'ils disent la MEME chose que ce
/// fichier, dans les deux sens. Retirer une exclusion du XML sans la retirer
/// ici echoue ; l'inverse aussi.
library;

/// Emplacements et regles de la sauvegarde systeme (Google / Apple).
abstract final class SauvegardeSysteme {
  /// Sous-dossier du stockage applicatif DECLARE EXCLU de la sauvegarde
  /// systeme. La fiche medicale y vit REELLEMENT depuis la tache 613
  /// (`FicheMedicaleFichier`, fichier `fiche.json`) : elle ne part donc jamais.
  ///
  /// Resolu sous `getApplicationSupportDirectory()`, ce qui donne
  /// `files/medical/` sur Android (domaine `file` des regles de sauvegarde) et
  /// `Library/Application Support/medical/` sur iPhone.
  static const String dossierExclu = 'medical';

  /// Sous-dossier du stockage applicatif INCLUS dans la sauvegarde systeme.
  /// La COPIE de la fiche y est ecrite UNIQUEMENT si le randonneur decoche la
  /// case de refus.
  static const String dossierSauvegardable = 'sauvegarde_systeme';

  /// Nom du fichier de la copie sauvegardable de la fiche medicale.
  static const String fichierCopieFiche = 'fiche_medicale.json';

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

  /// CE QUI EST EXCLU, ET RIEN D'AUTRE — source unique de verite.
  ///
  /// Chaque entree est un couple `domaine` / `chemin`. Un chemin vide signifie
  /// « le domaine tout entier ». Les deux fichiers de regles Android doivent
  /// porter EXACTEMENT ces exclusions, dans les deux sens (l'invariante le
  /// verifie).
  /// UNE SEULE ENTREE, ET C'EST UN CHOIX DE LA TACHE 613 : tout ce qui est exclu
  /// est medical, et tout ce qui est medical est ici. L'exclusion du domaine
  /// `database` a ete RETIREE (mesure 3) — elle faisait perdre la progression et
  /// le carnet au changement de telephone, et elle designeait un dossier ou une
  /// application Flutter n'ecrit jamais.
  static const List<({String domaine, String chemin})> exclusions = [
    // La fiche medicale, dans son dossier dedie. Elle y vit VRAIMENT depuis la
    // tache 613 (`FicheMedicaleFichier`) : cette ligne n'est plus posee d'avance.
    (domaine: 'file', chemin: 'medical/'),
  ];

  /// L'EXIGENCE IPHONE, NOMMEE POUR ETRE ACTIONNABLE (mesure 4).
  ///
  /// Ce n'est pas un fait acquis : c'est ce qu'il faudra appeler le jour ou un
  /// fichier medical durable apparaitra sous [dossierExclu].
  static const String exigenceIosExclusion =
      'poser NSURLIsExcludedFromBackupKey = true sur le dossier "$dossierExclu" '
      'de Library/Application Support, a sa creation, via un canal de methode '
      'natif — iOS n\'offre AUCUN equivalent declaratif de '
      'android:dataExtractionRules dans Info.plist';
}
