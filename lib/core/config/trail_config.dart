/// Numero de secours regional d'un sentier.
///
/// Fourni par la configuration du sentier (jamais hardcode dans
/// le moteur). Exemple : secours montagne local de la region.
/// Le 112 (urgences europeennes) est universel et gere par le
/// moteur — ne pas le dupliquer ici.
class TrailEmergencyNumber {
  const TrailEmergencyNumber({required this.name, required this.phone});

  /// Nom affiche du service de secours (ex: 'Secours montagne').
  final String name;

  /// Numero de telephone (format national ou international).
  final String phone;
}

/// Configuration d'un sentier — coeur du Moteur GR.
///
/// Chaque sentier fournit sa propre instance de TrailConfig.
/// Le moteur s'adapte automatiquement : couleurs, étapes,
/// points d'intérêt, secours régionaux, etc.
class TrailConfig {
  const TrailConfig({
    required this.id,
    required this.name,
    required this.displayName,
    required this.tagline,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
    required this.region,
    required this.country,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    required this.gpxAssetPath,
    this.directions = const ['NS', 'SN'],
    this.availableDurations = const [7, 9, 12, 14, 16],
    this.defaultDuration = 14,
    this.offlineFirst = true,
    this.hasPremium = false,
    this.isFictional = false,
    this.parentTrailId,
    this.chapterIds = const [],
    this.priceStages,
    this.firebaseProjectId,
    this.emergencyNumbers = const [],
    this.seedAssetsBase,
    this.accommodationsAssetPath,
    this.tipAssetPaths = const [],
    this.possibleNightsAssetPath,
    this.ficheAssetPath,
    this.maxAltitudeM,
    this.privacyPolicyUrl,
  });

  /// Identifiant unique du sentier (ex: 'gr10', 'tmb')
  final String id;

  /// Nom technique court (ex: 'GR10')
  final String name;

  /// Nom d'affichage de l'app (ex: 'Volcans Trail')
  final String displayName;

  /// Accroche sous le nom (ex: 'Votre compagnon de trek')
  final String tagline;

  /// Nombre total d'étapes
  final int totalStages;

  /// Distance totale en kilomètres
  final double totalDistanceKm;

  /// Dénivelé positif total en mètres
  final int totalElevationGain;

  /// Région géographique (ex: 'Auvergne', 'Pyrénées')
  final String region;

  /// Pays (ex: 'France', 'Suisse')
  final String country;

  /// Couleur primaire du thème (valeur int du Color)
  final int primaryColorValue;

  /// Couleur secondaire du thème (valeur int du Color)
  final int secondaryColorValue;

  /// Chemin vers le fichier GPX dans les assets
  final String gpxAssetPath;

  /// Directions de parcours possibles (ex: ['NS', 'SN'])
  final List<String> directions;

  /// Durées proposées pour le planning (en jours)
  final List<int> availableDurations;

  /// Durée par défaut suggérée (en jours)
  final int defaultDuration;

  /// Mode offline-first obligatoire (true pour les sentiers sans réseau)
  final bool offlineFirst;

  /// Active les fonctionnalités premium
  final bool hasPremium;

  /// Vrai quand ce sentier est INVENTÉ : un décor de test, pas un chemin.
  ///
  /// POURQUOI CE CHAMP EXISTE, ET CE QU'IL A COÛTÉ DE NE PAS L'AVOIR (tâche
  /// 793). `test_trail_config.dart` disait de lui-même, dès sa deuxième ligne,
  /// « aucune correspondance avec un lieu réel », et plus bas « données 100%
  /// fictives ». Il le disait en PROSE — donc à personne. Pendant ce temps il
  /// figurait au catalogue sous le nom crédible de « Sentier des Volcans », en
  /// Auvergne, 72 km et 2 420 m de D+, et il était ACHETABLE à 4,95 € (cinq
  /// étapes au palier 0,99 €). Un randonneur qui l'achetait croyait pouvoir le
  /// marcher. Décision de Christophe du 10/10, en deux mots : « tu dégage ».
  ///
  /// UN COMMENTAIRE N'EST PAS UNE GARDE. La seule trace machine de cette
  /// fiction était une liste d'exemption écrite à la main dans un test
  /// (`kSentiersSansCheminReel`), c'est-à-dire un endroit qui DISPENSAIT le
  /// sentier d'avoir une vraie trace au lieu de l'empêcher d'être vendu. Ce
  /// champ déplace l'aveu de la prose vers la DONNÉE : la configuration déclare
  /// elle-même sa nature, et [TrailCatalog] peut la refuser.
  ///
  /// C'EST UNE PROPRIÉTÉ, PAS UN IDENTIFIANT, et c'est tout l'intérêt. Une
  /// garde écrite sur `id == 'test-trail'` protégerait de ce sentier-ci et
  /// d'aucun autre : le prochain décor de test ajouté au registre repasserait
  /// par le même trou. Celle-ci tient sur la nature déclarée, donc sur tous.
  ///
  /// SORTIR DU CATALOGUE N'EST PAS SORTIR DU DÉPÔT. Un sentier fictif reste un
  /// outil légitime — 66 fichiers de test s'en servent de décor. Ce drapeau ne
  /// le supprime pas : il l'empêche d'arriver chez le randonneur.
  final bool isFictional;

  /// Le sentier dont CELUI-CI est un CHAPITRE — `null` s'il n'en est pas un.
  ///
  /// UN CHAPITRE EST UN SENTIER COMPLET, PAS UN MORCEAU (règle CH-11 du design
  /// #101920) : son nom, sa trace, ses étapes, ses lieux, son prix. Il est donc
  /// une [TrailConfig] comme les autres, avec son identifiant, son dossier de
  /// données et son entrée au catalogue. Ce champ ne le rend pas dépendant de
  /// son sentier mère : il sert à le RANGER, et c'est tout ce qu'il fait.
  ///
  /// CE QUE LE SENTIER MÈRE DEVIENT, ET C'EST UNE DÉCISION DE CHRISTOPHE DU
  /// 15/10 17:45, verbatim : « on achete le sentier seulement si il n y a pas
  /// de chapitres. Sinon par exemple pour le GR20 on peut acheter chapitre 1,
  /// chapitre 2, chapitre 1 and 2 ». Un sentier qui a des chapitres n'est PLUS
  /// un produit : il est une numérotation de référence. Voir [chapterIds].
  final String? parentTrailId;

  /// Les CHAPITRES de ce sentier — vide quand il n'en a pas.
  ///
  /// DÉCLARER UN CHAPITRE RETIRE LE SENTIER DE LA VENTE, et c'est le fond de la
  /// règle de Christophe du 15/10 : on achète le sentier SEULEMENT s'il n'a pas
  /// de chapitres. Dès que cette liste n'est pas vide, [estVendable] est faux,
  /// [TrailCatalog.all] ne montre plus ce sentier, et [TrailPurchases.buyTrail]
  /// le refuse nommément — trois verrous pour une seule règle, parce qu'un
  /// sentier vendu en bloc alors qu'il a des chapitres vendrait deux fois les
  /// mêmes étapes.
  ///
  /// IL RESTE RÉSOLVABLE PAR SON IDENTIFIANT, ET C'EST LA DIFFÉRENCE AVEC
  /// [isFictional]. Un sentier fictif est un MENSONGE : il devient introuvable.
  /// Un sentier mère est une VÉRITÉ qui n'est pas un produit : ses données, sa
  /// trace et sa numérotation de référence restent lisibles — c'est ce qui
  /// permet aux chapitres d'en être découpés et à la numérotation de ne jamais
  /// bouger (règle CH-10).
  final List<String> chapterIds;

  /// Vrai si ce sentier est un CHAPITRE d'un autre.
  bool get estChapitre => parentTrailId != null;

  /// Vrai si ce sentier A des chapitres — donc s'il ne se vend plus en bloc.
  bool get aDesChapitres => chapterIds.isNotEmpty;

  /// Vrai si ce sentier peut être ACHETÉ tel quel — ET C'EST DÉSORMAIS VRAI DE
  /// TOUS, SENTIERS MÈRES COMPRIS.
  ///
  /// CE QUE CE GETTER DISAIT, ET PENDANT TROIS JOURS SEULEMENT. La tâche 841 le
  /// rendait FAUX pour un sentier à chapitres : « ce sont ses chapitres qui se
  /// vendent, et le randonneur qui veut tout le sentier les prend tous ».
  ///
  /// CE QUI L'ANNULE, décision de Christophe du 18/10 11:19, verbatim : « Tu
  /// achetes TOUT le GR, ou par troncon (2) c'est tout ce que tu as à
  /// proposer ». LE SENTIER ENTIER EST UN PRODUIT, au même titre que chacun de
  /// ses deux tronçons : trois produits, pas deux.
  ///
  /// POURQUOI CE GETTER RESTE PLUTÔT QUE DE DISPARAÎTRE. Il porte une QUESTION
  /// qui a un sens — « ce sentier est-il à vendre ? » — et la réponse est
  /// aujourd'hui « oui » pour tout ce qui existe. Un sentier FICTIF, lui, n'est
  /// pas à vendre, mais il est écarté bien plus haut : il est introuvable
  /// ([TrailCatalog.byId] ne le résout pas), donc la question ne lui est jamais
  /// posée. Garder le getter laisse un seul endroit à changer le jour où une
  /// offre aura de nouveau des sentiers non vendables ; le supprimer obligerait
  /// à retrouver tous ses appelants.
  bool get estVendable => true;

  /// PRIX du sentier, EN ÉTAPES. `null` = le prix vaut [totalStages].
  ///
  /// L'unité du modèle économique est l'ÉTAPE (`MODELE_ECO.md` §1) : un trek de
  /// N étapes coûte N étapes, calées sur le palier store à 0,99 €. Ce champ
  /// EXISTE pour qu'un sentier puisse dire un prix DIFFÉRENT de son nombre
  /// d'étapes — et le seul cas qui compte aujourd'hui est le prix ZÉRO : un
  /// SENTIER GRATUIT ([isFreeTrail]).
  ///
  /// POURQUOI UN PRIX ET PAS UN DRAPEAU « DÉMO », ET C'EST TOUT LE SUJET DE LA
  /// TÂCHE 601. Ce champ remplace un booléen `isShowcaseTrail` qui disait « ce
  /// sentier ÉCHAPPE au mode démo ». Une exemption est un TROU dans le modèle :
  /// elle n'a pas de prix, elle ne se déduit de rien, et elle emporte tout ce
  /// qui s'accroche à `owned` — y compris le sans-pub permanent réservé à
  /// l'achat, que le sentier de démonstration recevait ainsi gratuitement. Un
  /// PRIX, lui, est une ENTRÉE du modèle : de lui se déduisent l'accès (rien à
  /// payer, donc jouable) et la publicité (rien de payé, donc niveau gratuit
  /// du §2). Le drapeau avait par ailleurs été attribué à Christophe dans un
  /// commentaire de code sans qu'aucune décision ne le soutienne, et il a dit
  /// le 27/09 n'avoir jamais parlé de sentier vitrine.
  ///
  /// Un sentier gratuit n'est donc PAS un sentier payant débridé : c'est un
  /// sentier de plus au catalogue, dont le prix est nul.
  final int? priceStages;

  /// Prix EFFECTIF du sentier en étapes (défaut : une étape par étape).
  int get priceInStages => priceStages ?? totalStages;

  /// Vrai si ce sentier est GRATUIT — son prix est nul.
  ///
  /// Gratuit par NATURE, pas par exemption : il n'y a rien à payer, donc rien
  /// à débloquer.
  ///
  /// COROLLAIRE ASSUMÉ CÔTÉ PUBLICITÉ, ET IL VAUT AUSSI PENDANT LA MARCHE.
  /// N'ayant rien payé, un sentier gratuit relève du niveau gratuit du §2 du
  /// modèle éco : il porte la pub. Décision de Christophe du **27/09 14:41**,
  /// verbatim : « TOUT PORTER LA PUB sauf si tu es abonné ou sur le trek que tu
  /// as acheté .. Pas la peine de mettre plus de règles ». Les seules
  /// exceptions sont donc l'abonnement actif, le trek ACHETÉ, et la récompense
  /// vidéo de 24 h déjà prévue au §3 (#99404).
  ///
  /// IL N'Y A PLUS DE RÈGLE « EN MODE TREK JAMAIS », et ce commentaire disait
  /// le contraire jusqu'à la relecture de ce lot. Une garde de ce nom a vécu la
  /// matinée du 27/09 et Christophe l'a retirée le même jour, en connaissance de
  /// cause : le sentier gratuit est le SEUL endroit où l'on marche sans avoir
  /// payé, donc le seul où la bannière peut apparaître en marchant. Ne pas la
  /// remettre — ce serait ajouter la règle qui vient d'être enlevée.
  bool get isFreeTrail => priceInStages == 0;

  /// ID du projet Firebase (null = pas de backend Firebase)
  final String? firebaseProjectId;

  /// Numeros de secours regionaux du sentier (ex: secours montagne
  /// local). Affiches apres le 112 universel dans l'ecran urgence.
  /// Vide par defaut : seul le 112 est propose.
  final List<TrailEmergencyNumber> emergencyNumbers;

  /// Racine des assets de donnees du sentier pour le seed initial
  /// (ex: 'assets/data/mon_sentier'). Null = pas de seed embarque.
  final String? seedAssetsBase;

  /// Fichier JSON MONOLITHIQUE (schema `trail_meta`/`itineraries`/`stages`/
  /// `accommodations`/`pois`) charge au seed dans les tables relationnelles
  /// riches (`trail_stages`/`trail_accommodations`...) via [TrailSeeder].
  ///
  /// R4 (retour Chris) : l'assistant Nuitees lit les hebergements par
  /// `getAccommodations` (jointure itineraires -> etapes -> hebergements sur
  /// ces tables riches). Le seed « dossier » ([seedAssetsBase]) ne peuple QUE
  /// les tables simples (etapes/POI) — les hebergements n'etaient donc jamais
  /// charges (noms manquants). Ce chemin optionnel branche le seed des
  /// hebergements. Null = pas d'hebergements embarques (fallback gracieux).
  final String? accommodationsAssetPath;

  /// Fichiers JSON de fiches conseils a charger au seed.
  final List<String> tipAssetPaths;

  /// Fichier JSON des NUITS POSSIBLES du sentier (tache 839).
  ///
  /// Les endroits ou une journee peut se terminer — fins d'etape ET couchages
  /// releves qui n'en sont pas — avec, pour chacun, son identifiant
  /// OpenStreetMap, son temps de marche aller ET retour depuis la trace, et ses
  /// lits quand ils sont connus ; plus les segments MESURES entre nuits
  /// consecutives (cf. [DecoupageDeNuits]).
  ///
  /// Null = le sentier n'offre aucune nuit au decoupage, et le curseur de duree
  /// se comporte exactement comme avant. Aucun sentier n'est penalise de ne pas
  /// avoir ce releve : c'est un enrichissement, pas un prerequis.
  final String? possibleNightsAssetPath;

  /// MANIFESTE DE LA FICHE DU SENTIER : sa description et ses photos.
  ///
  /// POURQUOI LA DESCRIPTION EST UN CHEMIN D'ASSET ET PAS TROIS CHAINES ICI.
  /// Trois champs de texte dans cette classe auraient marche, et ils auraient
  /// coute la meme chose que les chiffres saisis a la main de la tache 839 :
  /// une description est de la MATIERE EDITORIALE, elle se relit, se corrige,
  /// se traduit et grossit — elle n'a pas la meme vie qu'un identifiant ou
  /// qu'une couleur de theme. Le depot a deja tranche ce genre de question pour
  /// les etapes, les hebergements et les nuits possibles : la matiere va dans
  /// un fichier de donnees, la configuration en porte le CHEMIN.
  ///
  /// Null = le sentier n'a pas de fiche. Ce n'est PAS une panne : la fiche
  /// n'affiche alors ni section description, ni bande de photos, et la carte du
  /// catalogue reste celle d'avant (cf. `FicheDeSentier`). Un sentier sans
  /// photo ne doit pas montrer un cadre vide.
  final String? ficheAssetPath;

  /// Altitude MAXIMALE de la trace, en metres — MESUREE, jamais annoncee.
  ///
  /// POURQUOI ELLE EST ICI ALORS QUE LA DIFFICULTE SE CALCULE. C'est une
  /// MESURE, pas un verdict : elle entre dans le calcul de la difficulte
  /// (`DifficulteDuSentier`) au meme titre que le denivele des journees, et
  /// elle se lit sur la trace comme [totalDistanceKm] et [totalElevationGain]
  /// s'y lisent deja. Un test de garde relit le GPX et refuse toute divergence
  /// (`test/assets/altitude_max_mesuree_846_test.dart`) : un chiffre change a
  /// la main ici fait rougir la gate.
  ///
  /// POURQUOI ELLE NE SE CALCULE PAS A L'EXECUTION. La trace du GR20 porte
  /// 9 128 points ; la lire et la parcourir pour afficher un seul nombre sur
  /// une fiche serait payer un chargement de trace a chaque ouverture d'ecran.
  /// La mesure est faite une fois, hors ligne, et verifiee par un test.
  ///
  /// Null = la trace ne porte pas d'altitude. Le critere d'altitude DISPARAIT
  /// alors du calcul et la fiche DIT qu'il manque — elle ne devine pas.
  final int? maxAltitudeM;

  /// URL de la politique de confidentialite du produit/sentier.
  ///
  /// Parametrique (jamais codee en dur dans le moteur) : fournie par la
  /// configuration du sentier. Requise pour les fiches store (Google Play /
  /// App Store) et publiee en base par l'outil du lot 641. Null = non
  /// renseignee.
  ///
  /// LES SENTIERS DE LA MAISON PASSENT PAR [StepwaysLegal] (tache 642), et
  /// c'est la seule valeur qu'il faut employer ici : les quatre
  /// configurations portaient auparavant quatre adresses en `example.org`,
  /// c'est-a-dire quatre pages qui ne repondaient pas. Un test de garde
  /// (`test/comportement/urls_legales_642_test.dart`) interdit leur retour.
  /// Un sentier TIERS peut fournir la sienne — c'est a ca que sert le
  /// parametre — a condition qu'elle reponde.
  final String? privacyPolicyUrl;
}
