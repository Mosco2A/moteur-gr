// LE REGISTRE DES DORMANTS (tache 580, point Y2).
//
// LE PROBLEME QU'IL REGLE. L'invariante V2 (LOT V) a trouve onze ecrans ecrits
// qu'aucune route n'ouvre. Onze ecrans ne sont pas onze oublis : la plupart
// appartiennent a des fonctions NON LIVREES (social, gamification,
// contribution, moderation) dont le serveur n'existe pas encore, et les cabler
// pour faire taire une garde livrerait des ecrans vides a des randonneurs.
// Mais les laisser faire rougir la garde a chaque passage la condamne : une
// garde durablement rouge finit ignoree, puis desactivee.
//
// LA REGLE, ET C'EST TOUT LE POINT :
//
//     UN ECRAN DECLARE DORMANT NE FAIT PLUS ROUGIR LA GARDE.
//     UN ECRAN OUBLIE CONTINUE DE LA FAIRE ROUGIR.
//
// La dette cesse d'etre MUETTE — elle est ecrite, datee, motivee, et chaque
// entree dit CE QUI LA REVEILLERA. La garde, elle, garde ses dents : ajouter un
// ecran sans route le fait toujours rougir, et une entree qui ne correspond
// plus a rien (ecran supprime, ou desormais cable) fait rougir AUSSI — sans
// quoi le registre pourrirait en silence et couvrirait des ecrans qui vont
// bien.
//
// CE N'EST PAS UNE LISTE D'EXCEPTIONS. Une exception se contente d'un nom ;
// une entree d'ici porte une RAISON et un REVEIL, et l'invariante verifie que
// les deux sont ecrits. Le cout d'endormir un ecran reste superieur a celui de
// lui donner sa porte.
library;

import 'package:flutter/foundation.dart';

/// Un ecran ECRIT, SANS ROUTE, ET ASSUME.
@immutable
class EcranDormant {
  const EcranDormant({required this.raison, required this.reveil});

  /// POURQUOI il n'est pas cable aujourd'hui — en clair, pas un code de ticket.
  final String raison;

  /// CE QUI LE REVEILLERA : la phase, le lot ou la decision qui lui donnera sa
  /// porte — ou qui le supprimera.
  final String reveil;
}

/// LES ECRANS SANS ROUTE PAR CONCEPTION, ET LA RAISON DE CHACUN.
///
/// Mesure du 26/09/2026 (tache 580) sur `claude/integration/578-lot-w` : onze
/// ecrans de `lib/features/**/presentation/` n'ont ni route au routeur ni
/// citation ailleurs dans `lib/`.
const registreDesDormants = <String, EcranDormant>{
  // --- Phase 7 : social, gamification, classements (serveur non livre) -----
  //
  // Ces cinq ecrans lisent tous un document CALCULE COTE SERVEUR (classements
  // par tranche, fil d'activite, defis) ou publient sous pseudonyme. Sans le
  // backend, ils s'ouvriraient vides ou sur un cache inexistant : leur donner
  // une porte aujourd'hui serait promettre une fonction absente — exactement le
  // defaut que le LOT Q (tache 568) a corrige a l'envers.
  'LeaderboardScreen': EcranDormant(
    raison: 'Classement « Roi de l etape » par tranche (F7A-04) : il REND un '
        'document calcule cote serveur (F7A-03) et lu depuis le cache local. '
        'Aucun serveur ne le calcule encore, le cache est donc toujours vide.',
    reveil: 'Phase 7 (social), quand le calcul serveur des classements F7A-03 '
        'est livre.',
  ),
  'DefiScreen': EcranDormant(
    raison: 'Defi saisonnier (F7C-03) : la progression personnelle se calcule '
        'en local, mais le CLASSEMENT du defi vient du serveur (F7C-02), avec '
        'son seuil de k-anonymat. Sans defi publie, l ecran n a aucun defi a '
        'montrer.',
    reveil: 'Phase 7 (gamification), avec la publication des defis saisonniers.',
  ),
  'BadgeGalleryScreen': EcranDormant(
    raison: 'Galerie de badges (F7C-03) : le moteur de badges evalue bien en '
        'local, mais la gamification n est pas ouverte au randonneur et aucun '
        'ecran livre ne mene aux badges.',
    reveil: 'Phase 7 (gamification), avec l ouverture des badges.',
  ),
  'ActivityFeedScreen': EcranDormant(
    raison: 'Fil d activite communautaire (F7B-04) : il liste des activites '
        'PUBLIEES par d autres randonneurs, lues du cache local. Personne ne '
        'publie encore, et son bouton « Signaler » suppose le workflow de '
        'moderation DSA (D4C), lui aussi a venir.',
    reveil: 'Phase 7 (social), avec la publication communautaire et le '
        'workflow de moderation D4C.',
  ),
  'VisibilitySettingsScreen': EcranDormant(
    raison: 'Reglages de visibilite sociale (F7D-02) : il regle, finalite par '
        'finalite, ce qui apparait dans le fil et les classements. Tant que ni '
        'le fil ni les classements n existent, il reglerait le partage de rien.',
    reveil: 'Phase 7 (social), en meme temps que le fil et les classements '
        'qu il gouverne.',
  ),
  'StageShareScreen': EcranDormant(
    raison: 'Partage d une carte de resultat d etape (F7D-02) : il est OPT-IN '
        'et depend du reglage de visibilite, lui-meme dormant. Sans ce reglage '
        'atteignable, l ecran ne saurait afficher que son message « partage non '
        'active ».',
    reveil: 'Phase 7 (social), apres VisibilitySettingsScreen.',
  ),

  // --- Partage d une carte trek : supplante par le partage deja livre ------
  'ShareCardScreen': EcranDormant(
    raison: 'Previsualisation d une carte trek 1080x1080 avec choix de '
        'gabarit. Le partage LIVRE part d ailleurs : le recap « Mon aventure » '
        'envoie un texte et la trace GPX, le diplome un PDF, le journal ses '
        'photos — aucun ne passe par une previsualisation de carte, et '
        '`ShareCardGenerator` n a que cet ecran pour appelant. Il attend une '
        'decision : le brancher sur le recap, ou partir avec son generateur.',
    reveil: 'Decision produit sur le partage visuel (image contre texte). A '
        'supprimer si la reponse est « texte ».',
  ),

  // --- Contribution communautaire et moderation (DSA) ----------------------
  'WaypointContributionScreen': EcranDormant(
    raison: 'Formulaire de contribution communautaire hors-ligne (F8A-05) : il '
        'enregistre en local « sera publie a la prochaine synchronisation ». '
        'Aucune synchronisation n existe, la promesse du bandeau ne serait donc '
        'jamais tenue.',
    reveil: 'Phase de contribution communautaire (F8A), quand la publication '
        'des waypoints est livree.',
  ),
  'StatementOfReasonsScreen': EcranDormant(
    raison: 'Expose des motifs d une decision de moderation, DSA art. 17 '
        '(D4C-03). Il AFFICHE un enregistrement cree par le workflow de '
        'moderation D4C-02, qui n existe pas encore : il n y a aucune decision '
        'a exposer, et rien a contester.',
    reveil: 'Livraison du workflow de moderation D4C-02 — obligation legale des '
        'la premiere publication communautaire, donc au plus tard avec la '
        'Phase 7.',
  ),

  // --- Consentement au premier lancement -----------------------------------
  'ConsentOnboardingScreen': EcranDormant(
    raison: 'Ecran de consentement du PREMIER LANCEMENT (D4A-02) : le parcours '
        'd accueil ne demande pas encore le consentement, donc rien ne '
        'l ouvre. Le seul geste qu il portait et que l ecran atteignable n a '
        'jamais eu — « Tout refuser » — a ete cable sur /consent (tache 580, '
        'Y1) : plus aucun libelle traduit ne dort ici.',
    reveil: 'Quand le parcours de premier lancement integrera la demande de '
        'consentement (le provider `consentPromptNeededProvider` est deja la '
        'pour decider de l afficher).',
  ),

  // --- Reglage des plafonds d itineraire (heritage GR20) -------------------
  //
  // LE DOUZIEME, ET IL N'A ETE VU QUE LE 26/09 : ses seules citations dans
  // `lib/` etaient des COMMENTAIRES de parite GR20, et le balayage de
  // l'invariante lisait les commentaires. Il a fallu apprendre a la garde
  // qu'un commentaire n'est pas une porte (tache 580, Y2) pour qu'il apparaisse.
  'ItineraryConfigScreen': EcranDormant(
    raison: 'Reglage des plafonds de l itineraire — distance max par jour, '
        'duree max par jour, date de depart — herite de GR20. Il est le SEUL '
        'ecrivain de `itineraryConfigProvider`, qui reste donc fige sur ses '
        'valeurs par defaut. Le randonneur faconne aujourd hui son parcours '
        'autrement : le curseur de duree de la faisabilite (LOT R) et le '
        'Programme / « Adapter l itineraire » (regrouper, separer, jour de '
        'repos).',
    reveil: 'Decision produit : rouvrir des plafonds km / heures au randonneur, '
        'ou supprimer l ecran — et le provider que plus personne n ecrirait.',
  ),

  // --- Fiche hebergement d etape -------------------------------------------
  'RefugeDetailScreen': EcranDormant(
    raison: 'Fiche hebergement d etape (TREK-06) : capacite, tarifs, contact, '
        'boutons appeler / ecrire / site. Jamais cablee, et ses titres sont '
        'ECRITS EN DUR EN FRANCAIS — elle n a donc jamais ete prete a partir '
        'en cinq langues. Le detail d un lieu passe desormais par la feuille du '
        'repere fusionne de la carte (LOT T, tache 571) et par '
        '/accommodations-nearby ; ce qu elle porte EN PLUS — capacite, tarifs, '
        'contact — n a aujourd hui aucune porte.',
    reveil: 'Decision produit : porter capacite / tarifs / contact dans la '
        'feuille du repere fusionne et supprimer cet ecran, ou le traduire et '
        'lui donner une route.',
  ),
};
