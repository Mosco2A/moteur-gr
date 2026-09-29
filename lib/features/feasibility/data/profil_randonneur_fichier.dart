/// LE PROFIL DU RANDONNEUR QUITTE LES PREFERENCES POUR LE STOCKAGE PROTEGE DE LA
/// FICHE MEDICALE (tache 623, GO-73).
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT N'ETAIT PAS UNE SUPPOSITION : IL ETAIT DEJA CHIFFRE DANS LE DEPOT
/// ---------------------------------------------------------------------------
///
/// `SauvegardeSysteme.trouUserDefaultsIos`, ecrit par la tache 617, le nommait
/// mot pour mot : « sur iPhone, NSUserDefaults (SharedPreferences) ne peut PAS
/// etre exclu de la sauvegarde iCloud : ce n'est pas un fichier de l'application
/// mais un domaine de preferences du systeme. Le profil randonneur (age, taille,
/// poids, randonnees passees, test de marche) [...] monte donc dans iCloud sur
/// iPhone. [...] A FERMER en sortant ces cles vers un fichier, comme la tache
/// 613 l'a fait pour la fiche medicale. »
///
/// Et la regle de Christophe ne laisse aucune marge — il l'a ecrite en
/// majuscules le 27/09 : « Les donnees medicales RESTENT sur le tel », en
/// incluant EXPLICITEMENT le poids et la taille. L'application le lui dit
/// elle-meme, dans ses cinq langues (`hikerProfile.consentBody`) : « Age, taille
/// et poids sont des donnees de sante ».
///
/// TROIS LOTS AVAIENT PROTEGE LA FICHE MEDICALE ET LAISSE LE PROFIL DEHORS : le
/// 613 lui a donne son propre fichier, le 615 l'a sorti d'iCloud, le 612 lui a
/// coupe ses chemins de sortie. Ce lot met le profil au MEME endroit, avec la
/// MEME garde. Pas une seconde.
///
/// ---------------------------------------------------------------------------
/// POURQUOI LE MEME DOSSIER, ET PAS UN DOSSIER « PROFIL »
/// ---------------------------------------------------------------------------
///
/// [SauvegardeSysteme.dossierExclu] (`medical/`) est le SEUL dossier que les deux
/// fichiers de regles Android nomment explicitement en exclusion, et c'est le
/// second verrou voulu par la tache 617 : « le jour ou quelqu'un ajoute une
/// inclusion un peu large, la donnee de l'article 9 resterait dehors ». Un
/// dossier neuf n'aurait eu que la protection par defaut, donc UN verrou au lieu
/// de deux, et il aurait fallu se souvenir de l'ajouter aux deux XML.
///
/// Le profil releve du meme article 9 que la fiche medicale — c'est ce que
/// l'application declare au randonneur. Il va donc dans le meme dossier, et il
/// herite des deux verrous sans qu'aucune declaration ne soit a tenir a jour.
///
/// ---------------------------------------------------------------------------
/// UN SEUL FICHIER POUR LES QUATRE FAMILLES, ET CE N'EST PAS DE LA PARESSE
/// ---------------------------------------------------------------------------
///
/// Profil, randonnees passees, test de marche et note heritee vivaient dans
/// QUATRE cles de preferences. Ils vivent maintenant dans UN document. La raison
/// est la mesure de la tache 615 : l'exclusion iCloud est un attribut DU FICHIER,
/// reposee a chaque ecriture, en trois points. Quatre fichiers auraient voulu
/// dire quatre chemins d'ecriture, douze poses, et quatre occasions d'en oublier
/// une — sachant qu'une pose oubliee ne casse AUCUN test de comportement et ne se
/// voit que dans une sauvegarde iCloud, six mois plus tard.
///
/// Et [ecrire] est ATOMIQUE : un seul document veut dire qu'une interruption ne
/// peut pas laisser le profil d'aujourd'hui avec les randonnees d'hier.
///
/// ---------------------------------------------------------------------------
/// LE PIEGE DU LOT 615, QUI S'APPLIQUE MOT POUR MOT ICI
/// ---------------------------------------------------------------------------
///
/// L'ecriture atomique ecrit un `.tmp` puis le RENOMME par-dessus le document.
/// Apres le renommage, le fichier en place est l'ancien `.tmp`, QUI N'A JAMAIS
/// PORTE L'ATTRIBUT. Une exclusion posee une seule fois, a la creation, serait
/// donc perdue des la premiere correction du poids. L'exclusion est REPOSEE EN
/// TROIS POINTS a chaque ecriture — le dossier apres sa creation, le `.tmp` AVANT
/// le renommage, le fichier final APRES — exactement comme `FicheMedicaleFichier`,
/// et pour les memes deux raisons qui se couvrent l'une l'autre.
///
/// ENTREES-SORTIES SYNCHRONES, et c'est la mesure de la tache 612 : ecrites en
/// asynchrone, elles ne se terminent JAMAIS dans un test de widgets, ou `pump`
/// avance des minuteurs simules sans faire tourner la boucle d'evenements reelle.
/// Le document pese quelques centaines d'octets.
///
/// ---------------------------------------------------------------------------
/// UN DOCUMENT VIDE N'EST PAS ECRIT : IL EFFACE LE FICHIER
/// ---------------------------------------------------------------------------
///
/// Regle heritee du lot 566 (LOT O) et tenue par la tache 613 pour la fiche
/// medicale. Apres un refus de consentement, `eraseMorphology` ecrivait un profil
/// a zero, horodate, a l'endroit exact ou l'ecran venait de promettre « Sans
/// votre accord, rien n'est enregistre ». Un fichier de champs vides est une
/// TRACE DE PASSAGE. S'il ne reste rien, le fichier part.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/services/exclusion_sauvegarde_icloud.dart';
import '../../../core/services/sauvegarde_systeme.dart';
import '../domain/hiker_profile.dart';
import '../domain/past_hike.dart';
import '../domain/walk_test_result.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// TOUT CE QUE LE RANDONNEUR A CONFIE SUR SA PERSONNE, EN UN SEUL DOCUMENT.
///
/// Les quatre familles voyagent ensemble parce qu'elles sont ecrites ensemble
/// (voir l'en-tete du fichier). [estVide] decide si le fichier doit exister.
class ContenuProfilRandonneur {
  const ContenuProfilRandonneur({
    this.profil,
    this.randosPassees = const [],
    this.testDeMarche,
    this.noteExperienceHeritee,
  });

  /// Aucune donnee confiee.
  static const ContenuProfilRandonneur vide = ContenuProfilRandonneur();

  /// La fiche d'info (age, taille, poids, sexe declare, pays), ou `null` si
  /// aucune fiche n'a jamais ete saisie.
  final HikerProfile? profil;

  /// Les randonnees passees declarees (plafonnees par l'appelant).
  final List<PastHike> randosPassees;

  /// Le dernier resultat du test de marche 6 minutes, ou `null`.
  final WalkTestResult? testDeMarche;

  /// LA NOTE DE DIFFICULTES, HERITEE ET JAMAIS REECRITE (tache 570, S2).
  ///
  /// Plus rien ne l'ecrit : le champ, son provider et son ecriture ont ete
  /// retires parce que la donnee etait collectee et lue par personne. Mais des
  /// telephones la portent DEJA, en clair, dans les preferences qui montent dans
  /// iCloud. La migration la TRANSPORTE au lieu de la jeter — la consigne de ce
  /// lot est que la migration ne perde rien — et l'effacement de l'article 17
  /// continue de l'emporter.
  final String? noteExperienceHeritee;

  /// Vrai quand il n'y a rien a ecrire : le fichier ne doit alors pas exister.
  bool get estVide =>
      (profil == null || profil!.isEmpty && !_aDuNonMorphologique(profil!)) &&
      randosPassees.isEmpty &&
      testDeMarche == null &&
      (noteExperienceHeritee == null || noteExperienceHeritee!.isEmpty);

  /// Le sexe declare et le pays ne relevent pas de l'article 9 : une fiche
  /// reduite a ces deux champs n'est pas « rien », et le lot 560 (N1) a decide
  /// qu'elle survivait a un refus de consentement.
  static bool _aDuNonMorphologique(HikerProfile p) =>
      (p.sex?.isNotEmpty ?? false) || p.countryIso.isNotEmpty;

  ContenuProfilRandonneur copyWith({
    HikerProfile? profil,
    bool effacerProfil = false,
    List<PastHike>? randosPassees,
    WalkTestResult? testDeMarche,
    bool effacerTestDeMarche = false,
    String? noteExperienceHeritee,
    bool effacerNote = false,
  }) {
    return ContenuProfilRandonneur(
      profil: effacerProfil ? null : (profil ?? this.profil),
      randosPassees: randosPassees ?? this.randosPassees,
      testDeMarche:
          effacerTestDeMarche ? null : (testDeMarche ?? this.testDeMarche),
      noteExperienceHeritee: effacerNote
          ? null
          : (noteExperienceHeritee ?? this.noteExperienceHeritee),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (profil != null) ProfilRandonneurFichier.clefProfil: profil!.toJson(),
        if (randosPassees.isNotEmpty)
          ProfilRandonneurFichier.clefRandosPassees:
              randosPassees.map((h) => h.toJson()).toList(),
        if (testDeMarche != null)
          ProfilRandonneurFichier.clefTestDeMarche: testDeMarche!.toJson(),
        if (noteExperienceHeritee != null && noteExperienceHeritee!.isNotEmpty)
          ProfilRandonneurFichier.clefNoteExperience: noteExperienceHeritee,
      };

  /// Relecture TOLERANTE : une section illisible ne fait pas perdre les autres.
  ///
  /// Ce n'est pas de la complaisance. Un document corrompu par une coupure de
  /// courant ne doit pas effacer les randonnees passees du randonneur parce que
  /// son poids etait devenu illisible, et il ne doit surtout pas empecher l'ecran
  /// de s'ouvrir — meme discipline que `FicheMedicaleFichier.lire`.
  factory ContenuProfilRandonneur.fromJson(Map<String, dynamic> json) {
    HikerProfile? profil;
    try {
      final brut = json[ProfilRandonneurFichier.clefProfil];
      if (brut is Map<String, dynamic>) profil = HikerProfile.fromJson(brut);
    } catch (e) {
      _log.e('[ProfilRandonneur] Section profil illisible ($e)');
    }

    final randos = <PastHike>[];
    try {
      final brut = json[ProfilRandonneurFichier.clefRandosPassees];
      if (brut is List) {
        for (final e in brut) {
          if (e is Map<String, dynamic>) randos.add(PastHike.fromJson(e));
        }
      }
    } catch (e) {
      _log.e('[ProfilRandonneur] Section randonnees illisible ($e)');
    }

    WalkTestResult? test;
    try {
      final brut = json[ProfilRandonneurFichier.clefTestDeMarche];
      if (brut is Map<String, dynamic>) test = WalkTestResult.fromJson(brut);
    } catch (e) {
      _log.e('[ProfilRandonneur] Section test de marche illisible ($e)');
    }

    final note = json[ProfilRandonneurFichier.clefNoteExperience];

    return ContenuProfilRandonneur(
      profil: profil,
      randosPassees: randos,
      testDeMarche: test,
      noteExperienceHeritee: note is String && note.isNotEmpty ? note : null,
    );
  }
}

/// LE STOCKAGE DURABLE DU PROFIL : UN FICHIER, DANS LE DOSSIER DECLARE EXCLU DE
/// LA SAUVEGARDE DU TELEPHONE — LE MEME QUE LA FICHE MEDICALE.
///
/// Voir l'en-tete du fichier pour le raisonnement entier.
class ProfilRandonneurFichier {
  ProfilRandonneurFichier({
    Future<Directory> Function()? dossierApplicatif,
    ExclusionSauvegardeIcloud? exclusionIcloud,
  })  : _dossierApplicatif =
            dossierApplicatif ?? getApplicationSupportDirectory,
        _exclusion = exclusionIcloud ?? ExclusionSauvegardeIcloud();

  /// Resolution du stockage applicatif. Sur Android
  /// `getApplicationSupportDirectory()` donne `files/`, donc le domaine `file`
  /// des regles de sauvegarde. Sur iPhone il rend `Library/Application Support/`,
  /// QUE LA SAUVEGARDE iCLOUD EMPORTE PAR DEFAUT — d'ou [_exclusion]. Les tests
  /// le pointent sur un repertoire temporaire (`flutter_test_config.dart` le fait
  /// pour toute la suite depuis la tache 613).
  final Future<Directory> Function() _dossierApplicatif;

  /// L'EXCLUSION iCLOUD DU LOT 615, REUTILISEE TELLE QUELLE. Sur Android elle
  /// rend `sansObjet` sans toucher au canal natif : la protection y est declaree
  /// dans les deux XML.
  final ExclusionSauvegardeIcloud _exclusion;

  /// Nom du document.
  static const String nomFichier = 'profil_randonneur.json';

  /// Suffixe du fichier temporaire de l'ecriture atomique. Nomme ici parce que
  /// TROIS choses portent sur lui : l'ecriture le cree, [effacer] doit l'emporter
  /// et [garantirExclusion] doit le couvrir.
  static const String suffixeTemporaire = '.tmp';

  /// Clef de la fiche d'info dans le document.
  static const String clefProfil = 'profil';

  /// Clef des randonnees passees dans le document.
  static const String clefRandosPassees = 'randosPassees';

  /// Clef du dernier test de marche dans le document.
  static const String clefTestDeMarche = 'testDeMarche';

  /// Clef de la note de difficultes heritee (jamais reecrite, tache 570).
  static const String clefNoteExperience = 'noteExperienceHeritee';

  /// Le document : `<stockage applicatif>/medical/profil_randonneur.json`.
  Future<File> fichier() async {
    final base = await _dossierApplicatif();
    return File(
      '${base.path}/${SauvegardeSysteme.dossierExclu}/$nomFichier',
    );
  }

  /// Lit le document. Rend un contenu VIDE si rien n'a jamais ete ecrit, et
  /// aussi si le document est illisible — un profil corrompu ne doit pas
  /// empecher l'ecran de faisabilite de s'ouvrir.
  Future<ContenuProfilRandonneur> lire() async {
    try {
      final f = await fichier();
      if (!f.existsSync()) return ContenuProfilRandonneur.vide;
      final brut = f.readAsStringSync();
      if (brut.trim().isEmpty) return ContenuProfilRandonneur.vide;
      return ContenuProfilRandonneur.fromJson(
        jsonDecode(brut) as Map<String, dynamic>,
      );
    } catch (e) {
      _log.e('[ProfilRandonneur] Lecture impossible ($e) -> repute vide');
      return ContenuProfilRandonneur.vide;
    }
  }

  /// Ecrit le document, en remplacant le precedent. Un contenu VIDE n'est pas
  /// ecrit : il EFFACE le fichier (voir l'en-tete — une trace de passage la ou le
  /// randonneur a demande qu'il n'y en ait plus).
  ///
  /// L'ORDRE DES QUATRE GESTES N'EST PAS INTERCHANGEABLE, et c'est la mesure du
  /// lot 615 :
  ///
  ///  1. le dossier est cree PUIS exclu — un dossier absent ne porte pas
  ///     d'attribut ;
  ///  2. le `.tmp` est ecrit PUIS exclu, AVANT le renommage — sinon la donnee
  ///     existe sur le disque, en clair, sans attribut, pendant toute l'ecriture ;
  ///  3. le renommage ;
  ///  4. le document final est exclu APRES le renommage — c'est CE geste qui
  ///     ferme le piege de l'ecriture atomique, et il ne suppose pas que
  ///     l'attribut ait suivi le fichier a travers le `rename`.
  Future<void> ecrire(ContenuProfilRandonneur contenu) async {
    if (contenu.estVide) {
      await effacer();
      return;
    }
    final f = await fichier();
    f.parent.createSync(recursive: true);
    await _exclusion.exclure(f.parent.path);

    final temporaire = File('${f.path}$suffixeTemporaire');
    temporaire.writeAsStringSync(jsonEncode(contenu.toJson()), flush: true);
    await _exclusion.exclure(temporaire.path);

    temporaire.renameSync(f.path);
    await _exclusion.exclure(f.path);
  }

  /// REPOSE L'EXCLUSION SUR CE QUI EST DEJA SUR LE DISQUE, SANS RIEN ECRIRE.
  ///
  /// POURQUOI ELLE EXISTE, ET CE N'EST PAS UNE CEINTURE DE PLUS. [ecrire] protege
  /// ce qu'ELLE ecrit. Mais on remplit son profil UNE fois, avant de partir : le
  /// randonneur qui a saisi son poids avec une version anterieure et met a jour
  /// ne reecrira peut-etre plus jamais. C'est l'amorce de l'application, et elle
  /// seule, qui repasse derriere lui.
  ///
  /// ELLE NE CREE RIEN : poser l'attribut sur un dossier absent le ferait
  /// apparaitre chez un randonneur qui n'a jamais rien saisi — une trace de
  /// passage, et le lot 612 a decide qu'on n'en laissait pas.
  Future<void> garantirExclusion() async {
    try {
      final f = await fichier();
      final dossier = f.parent;
      if (!dossier.existsSync()) return;
      await _exclusion.exclure(dossier.path);
      if (f.existsSync()) await _exclusion.exclure(f.path);
      final temporaire = File('${f.path}$suffixeTemporaire');
      if (temporaire.existsSync()) await _exclusion.exclure(temporaire.path);
    } catch (e) {
      // ELLE NE LEVE JAMAIS : elle est attendue par l'amorce de l'application.
      // Un attribut de sauvegarde ne doit pas empecher un randonneur de demarrer.
      _log.e('[ProfilRandonneur] Exclusion iCloud impossible ($e)');
    }
  }

  /// Supprime le document du disque. Idempotent, et il emporte AUSSI le fichier
  /// temporaire : une ecriture interrompue juste avant un effacement laisserait
  /// sinon l'age, la taille et le poids dans le `.tmp`, hors de portee du droit
  /// a l'effacement.
  Future<void> effacer() async {
    try {
      final f = await fichier();
      if (f.existsSync()) f.deleteSync();
      final temporaire = File('${f.path}$suffixeTemporaire');
      if (temporaire.existsSync()) temporaire.deleteSync();
    } catch (e) {
      _log.e('[ProfilRandonneur] Suppression impossible ($e)');
      rethrow;
    }
  }
}
