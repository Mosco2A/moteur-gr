/// LE CATALOGUE FERME DES ECRANS OBSERVES (lot 645-09).
///
/// Il n'y a ici AUCUNE logique : rien que les 63 noms d'ecran que
/// l'application sait poser en valeur de cle Crashlytics. Le catalogue vit a
/// part de [AnalyticsService] pour une raison de mesure, pas de gout : son
/// service portait deja 377 lignes, et 63 constantes de plus l'envoyaient
/// au-dela du plafond de 500 lignes que l'audit 644 compte sous ECR-15.
library;

/// UN ECRAN OBSERVE, en type FERME et instances CONSTANTES.
///
/// MEME PHILOSOPHIE QUE [AnalyticsStep] (tache 637), ET POUR LA MEME RAISON :
/// la methode d'entree d'ecran n'accepte que ce type, donc le nom d'ecran qui
/// part dans un rapport de plantage ne peut JAMAIS etre une valeur venue du
/// randonneur. Ce n'est pas une consigne a respecter, c'est le compilateur qui
/// la tient.
///
/// POURQUOI UN CATALOGUE PLUTOT QU'UNE CHAINE LIBRE. Une chaine libre a deux
/// defauts qui coutent cher et tard : deux ecrans peuvent porter le meme nom
/// sans que rien ne le dise, et un nom peut se perdre dans un renommage de
/// fichier — le lot 645-07 en a renomme 28 d'un coup. Ici, un ecran qui
/// disparait casse la compilation du catalogue, et la garde de test compte les
/// entrees.
final class ScreenBreadcrumb {
  const ScreenBreadcrumb._(this.name);

  /// Le nom logique de l'ecran : la valeur de la cle `screen` et le corps de
  /// la miette `screen:<nom>`.
  ///
  /// Court par obligation, pas par style : Crashlytics plafonne ses journaux a
  /// 64 ko par session, et une session traverse jusqu'a 63 ecrans.
  final String name;

  /// La fiche d'un hebergement d'etape.
  static const accommodationDetail = ScreenBreadcrumb._('accommodation_detail');

  /// Le fil des activites de la communaute.
  static const activityFeed = ScreenBreadcrumb._('activity_feed');

  /// Le recapitulatif d'une aventure terminee.
  static const adventureRecap = ScreenBreadcrumb._('adventure_recap');

  /// La galerie des badges obtenus.
  static const badgeGallery = ScreenBreadcrumb._('badge_gallery');

  /// La reservation d'un hebergement.
  static const booking = ScreenBreadcrumb._('booking');

  /// Le calendrier de preparation du depart.
  static const calendar = ScreenBreadcrumb._('calendar');

  /// La liste du materiel a emporter.
  static const checklist = ScreenBreadcrumb._('checklist');

  /// Le depot d'une reclamation de moderation.
  static const complaint = ScreenBreadcrumb._('complaint');

  /// La demande de consentement a la premiere ouverture.
  static const consentOnboarding = ScreenBreadcrumb._('consent_onboarding');

  /// Le reglage des consentements deja donnes.
  static const consentSettings = ScreenBreadcrumb._('consent_settings');

  /// Un defi propose au randonneur.
  static const defi = ScreenBreadcrumb._('defi');

  /// Le diplome de fin de parcours.
  static const diploma = ScreenBreadcrumb._('diploma');

  /// Les secours et les numeros d'urgence.
  static const emergency = ScreenBreadcrumb._('emergency');

  /// L'envoi d'un retour d'experience.
  static const feedback = ScreenBreadcrumb._('feedback');

  /// Le risque d'incendie sur le massif.
  static const fireRisk = ScreenBreadcrumb._('fire_risk');

  /// Le suivi d'un groupe depuis le web.
  static const followWeb = ScreenBreadcrumb._('follow_web');

  /// La boutique d'objets de la marque.
  static const goodiesCatalog = ScreenBreadcrumb._('goodies_catalog');

  /// L'import d'une trace GPX.
  static const gpxImport = ScreenBreadcrumb._('gpx_import');

  /// Le groupe de marche.
  static const group = ScreenBreadcrumb._('group');

  /// La fiche medicale du randonneur.
  static const healthInfo = ScreenBreadcrumb._('health_info');

  /// Les hebergements autour d'une etape.
  static const hebergementsPeripheriques = ScreenBreadcrumb._(
    'hebergements_peripheriques',
  );

  /// Le profil physique du randonneur.
  static const hikerProfile = ScreenBreadcrumb._('hiker_profile');

  /// Le hub d'accueil, porte de toutes les fonctions.
  static const hub = ScreenBreadcrumb._('hub');

  /// L'itineraire calcule, etape par etape.
  static const itinerary = ScreenBreadcrumb._('itinerary');

  /// Le reglage de l'itineraire avant calcul.
  static const itineraryConfig = ScreenBreadcrumb._('itinerary_config');

  /// Le journal de bord du parcours.
  static const journal = ScreenBreadcrumb._('journal');

  /// Le classement des marcheurs.
  static const leaderboard = ScreenBreadcrumb._('leaderboard');

  /// La carte de marche, ecran de terrain.
  static const map = ScreenBreadcrumb._('map');

  /// Les parcours du randonneur.
  static const myTreks = ScreenBreadcrumb._('my_treks');

  /// Le mur affiche quand aucun sentier n'est sur le telephone.
  static const noData = ScreenBreadcrumb._('no_data');

  /// Les nuitees retenues pour un parcours.
  static const nuitees = ScreenBreadcrumb._('nuitees');

  /// Les cartes disponibles hors ligne.
  static const offlineMaps = ScreenBreadcrumb._('offline_maps');

  /// La toute premiere ouverture de l'application.
  static const onboarding = ScreenBreadcrumb._('onboarding');

  /// Les randonnees deja faites, saisies par le randonneur.
  static const pastHikes = ScreenBreadcrumb._('past_hikes');

  /// La synthese du plan de marche.
  static const planSummary = ScreenBreadcrumb._('plan_summary');

  /// Le compte et son profil.
  static const profile = ScreenBreadcrumb._('profile');

  /// Le code de recuperation du compte.
  static const recoveryCode = ScreenBreadcrumb._('recovery_code');

  /// Les reglages de l'application.
  static const settings = ScreenBreadcrumb._('settings');

  /// La carte souvenir a partager.
  static const shareCard = ScreenBreadcrumb._('share_card');

  /// Les commerces d'une etape.
  static const shop = ScreenBreadcrumb._('shop');

  /// Le signalement d'un contenu ou d'un danger.
  static const signalement = ScreenBreadcrumb._('signalement');

  /// La liste des etapes du parcours en cours.
  static const stageList = ScreenBreadcrumb._('stage_list');

  /// Le partage d'une etape terminee.
  static const stageShare = ScreenBreadcrumb._('stage_share');

  /// L'expose des motifs d'une decision de moderation.
  static const statementOfReasons = ScreenBreadcrumb._('statement_of_reasons');

  /// L'abonnement a l'application.
  static const subscription = ScreenBreadcrumb._('subscription');

  /// Les conseils de preparation et de terrain.
  static const tips = ScreenBreadcrumb._('tips');

  /// La fiche d'un guide de ville-etape.
  static const townGuideDetail = ScreenBreadcrumb._('town_guide_detail');

  /// Les guides des villes-etapes.
  static const townGuides = ScreenBreadcrumb._('town_guides');

  /// Le catalogue des sentiers telechargeables.
  static const trailCatalog = ScreenBreadcrumb._('trail_catalog');

  /// La fiche d'un sentier du catalogue.
  static const trailDetail = ScreenBreadcrumb._('trail_detail');

  /// La preparation d'un sentier choisi.
  static const trailPlanning = ScreenBreadcrumb._('trail_planning');

  /// Le choix du sentier a marcher.
  static const trailSelection = ScreenBreadcrumb._('trail_selection');

  /// La fiche d'une etape vue depuis le catalogue.
  static const trailStageDetail = ScreenBreadcrumb._('trail_stage_detail');

  /// Le plan d'entrainement avant le depart.
  static const training = ScreenBreadcrumb._('training');

  /// Les transports pour rejoindre le depart.
  static const transport = ScreenBreadcrumb._('transport');

  /// Le reglage du decoupage des etapes.
  static const trekAdjust = ScreenBreadcrumb._('trek_adjust');

  /// La faisabilite du parcours pour ce randonneur.
  static const trekFeasibility = ScreenBreadcrumb._('trek_feasibility');

  /// La fiche d'une etape pendant le parcours.
  static const trekStageDetail = ScreenBreadcrumb._('trek_stage_detail');

  /// Le reglage de ce que les autres voient.
  static const visibilitySettings = ScreenBreadcrumb._('visibility_settings');

  /// Le test de marche qui mesure la forme.
  static const walkTest = ScreenBreadcrumb._('walk_test');

  /// La recharge du compte-etapes.
  static const walletRecharge = ScreenBreadcrumb._('wallet_recharge');

  /// La contribution d'un point d'interet.
  static const waypointContribution = ScreenBreadcrumb._(
    'waypoint_contribution',
  );

  /// La meteo de l'etape.
  static const weather = ScreenBreadcrumb._('weather');

  /// TOUS LES ECRANS OBSERVES, pour les gardes de test.
  ///
  /// C'est cette liste que la garde de plafond parcourt pour verifier qu'elle
  /// mesure bien les 63 ecrans du depot et pas un sous-ensemble oublie. Une
  /// constante ajoutee ci-dessus et absente d'ici fait rougir la garde.
  static const all = <ScreenBreadcrumb>[
    accommodationDetail,
    activityFeed,
    adventureRecap,
    badgeGallery,
    booking,
    calendar,
    checklist,
    complaint,
    consentOnboarding,
    consentSettings,
    defi,
    diploma,
    emergency,
    feedback,
    fireRisk,
    followWeb,
    goodiesCatalog,
    gpxImport,
    group,
    healthInfo,
    hebergementsPeripheriques,
    hikerProfile,
    hub,
    itinerary,
    itineraryConfig,
    journal,
    leaderboard,
    map,
    myTreks,
    noData,
    nuitees,
    offlineMaps,
    onboarding,
    pastHikes,
    planSummary,
    profile,
    recoveryCode,
    settings,
    shareCard,
    shop,
    signalement,
    stageList,
    stageShare,
    statementOfReasons,
    subscription,
    tips,
    townGuideDetail,
    townGuides,
    trailCatalog,
    trailDetail,
    trailPlanning,
    trailSelection,
    trailStageDetail,
    training,
    transport,
    trekAdjust,
    trekFeasibility,
    trekStageDetail,
    visibilitySettings,
    walkTest,
    walletRecharge,
    waypointContribution,
    weather,
  ];

  @override
  String toString() => 'ScreenBreadcrumb($name)';
}
