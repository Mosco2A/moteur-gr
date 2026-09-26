// LE REGISTRE DES ROUTES DORMANTES (tache 582, LOT Z).
//
// CE N'EST PAS LE REGISTRE DES DORMANTS. Celui-la (tache 580, Y2) parle
// d'ECRANS SANS ROUTE : du code qu'aucun chemin ne declare. Celui-ci parle de
// ROUTES SANS PORTE : un chemin bel et bien declare au routeur, un ecran qui
// se peint, un deep-link qui marche — et AUCUN GESTE de l'application qui y
// mene. Les deux dettes sont voisines et differentes : la premiere est du code
// que le routeur ignore, la seconde une porte que l'interface a condamnee.
//
// POURQUOI IL FALLAIT L'ECRIRE. L'invariante V1 (tache 573, LOT V) a trouve
// treize routes sans porte. Elle offrait deux issues : cabler, ou inscrire la
// route dans ses `exceptionsDocumentees`. Or la mesure du 26/09 montre que la
// plupart de ces treize ne sont NI des oublis NI des exceptions « par
// conception » : ce sont des DECISIONS DE CHRIS (masquer les guides des villes,
// parquer le groupe, geler l'import GPX) ou des DOUBLONS PAUVRES herites des
// premieres phases, dont personne n'a encore tranche le sort. Les entasser
// dans une liste d'exceptions aurait menti sur leur nature et dilue le peu
// qu'une exception veut dire.
//
// LA REGLE, LA MEME QUE POUR LES ECRANS :
//
//     UNE ROUTE DECLAREE DORMANTE NE FAIT PLUS ROUGIR LA GARDE.
//     UNE ROUTE OUBLIEE CONTINUE DE LA FAIRE ROUGIR.
//
// Et la garde garde ses dents dans LES DEUX SENS : declarer une route qui n'est
// plus declaree au routeur fait rougir (le registre pourrirait), et declarer
// une route QUI A RETROUVE SA PORTE fait rougir aussi (on couvrirait une route
// qui va bien, et la prochaine vraie regression passerait pour normale).
//
// CE QUE CHAQUE ENTREE DOIT PORTER : une RAISON en clair — pas un numero de
// ticket — et un REVEIL : la decision, la phase ou le lot qui lui rendra sa
// porte, ou qui la supprimera. Endormir une route doit rester plus couteux que
// lui donner son bouton.
library;

import 'package:flutter/foundation.dart';

/// Une route DECLAREE, SANS PORTE, ET ASSUMEE.
@immutable
class RouteDormante {
  const RouteDormante({required this.raison, required this.reveil});

  /// POURQUOI aucun geste de l'application n'y mene aujourd'hui.
  final String raison;

  /// CE QUI LA REVEILLERA : la decision, la phase ou le lot qui lui rendra sa
  /// porte — ou qui la supprimera.
  final String reveil;
}

/// LES ROUTES SANS PORTE PAR DECISION, ET LA RAISON DE CHACUNE.
///
/// Mesure du 26/09/2026 (tache 582) sur la reunion des lots X et Y : treize
/// routes declarees n'avaient aucun geste entrant dans `lib/`. `/signalement`
/// n'etait pas de cette famille — il n'avait jamais eu de porte du tout, et il
/// en a recu une (LOT Z). Les douze autres sont ici.
const registreDesRoutesDormantes = <String, RouteDormante>{
  // --- Decisions explicites de Chris -------------------------------------
  //
  // Ces quatre routes ONT EU une porte, et Chris l'a fait retirer. Les
  // recabler pour faire taire une garde reviendrait a defaire sa decision.
  '/trail/:id/guides': RouteDormante(
    raison: 'Guides des villes (F8C-02) : la carte du cockpit a ete MASQUEE sur '
        'decision de Chris (retour 13, tache 553) — mot pour mot « guide des '
        'villes, on en a pas assez parle voire pas du tout tu cache pour l '
        'instant ». La fonction avait ete cablee en E33/E34 sans avoir jamais '
        'ete discutee. Ecrans, routes et contenu restent INTACTS : seule la '
        'porte est retiree, le temps d en parler.',
    reveil: 'Conversation produit avec Chris sur les guides des villes : '
        'remettre la carte au cockpit, ou retirer la fonction.',
  ),
  '/trail/:id/guides/:guideId': RouteDormante(
    raison: 'Fiche d une localite du sentier. Elle N EST PAS orpheline dans '
        'l usage : la liste la pousse par `Navigator.of(context).push` d un '
        'MaterialPageRoute, geste que cette garde ne lit pas puisqu il ne passe '
        'pas par le routeur. Elle est donc inatteignable pour la MEME et SEULE '
        'raison que sa liste : la porte du cockpit est masquee au-dessus d elle.',
    reveil: 'Avec sa liste `/trail/:id/guides` — les deux se reveillent ou '
        'partent ensemble.',
  ),
  '/group/:id': RouteDormante(
    raison: 'Suivi de groupe en direct (E23/E33) : RETIRE du perimetre V1 sur '
        'decision de Chris (#99615-2, StepWays L8). La carte « Mon groupe » du '
        'HUB a ete supprimee ; le code Firestore sous-jacent etait mort ou en '
        'demo cote GR20. Chris a dit « pour l instant » : la route et '
        '`GroupScreen` sont PARQUES intacts, pas supprimes, pour que le groupe '
        'puisse revenir.',
    reveil: 'Decision de Chris de rouvrir le groupe — et un serveur de suivi '
        'temps reel qui existe vraiment. Ne PAS recabler d entree sans elle.',
  ),
  '/trail/:id/import-gpx': RouteDormante(
    raison: 'Import d une trace GPX : ROUTE ORPHELINE ASSUMEE depuis StepWays '
        'L8 (decision de Chris #99615-1, option A du mandat retraits). '
        'C etait un ajout unilateral jamais discute, gele comme idee future '
        '(« ajouter son propre sentier par une trace »). La carte « Import GPX » '
        'du HUB a ete supprimee ; le code est parke, pas detruit, et la route '
        'est conservee pour qu un futur deep-link reste valide.',
    reveil: 'Decision de Chris de rouvrir l idee d apporter sa propre trace.',
  ),

  // --- Doublons pauvres des premieres phases -----------------------------
  //
  // Ces cinq routes ne sont pas des fonctions en attente : ce sont de VIEILLES
  // VERSIONS d une fonction que le randonneur atteint DEJA ailleurs, par un
  // ecran plus riche. Aucune ne merite une porte ; chacune attend qu on
  // tranche entre supprimer la route ou supprimer aussi l ecran, ce qui est
  // une decision produit et pas un geste de lot.
  '/trail/:id': RouteDormante(
    raison: 'Fiche sentier de la phase 1 (`TrailDetailScreen`) : un en-tete et '
        'la liste des etapes. Le randonneur arrive aujourd hui sur le COCKPIT '
        '(`/home`), qui porte la meme information et tout le reste ; le detail '
        'des etapes vit dans le Programme (`/trail/:id/itinerary`). La route a '
        'survecu a la refonte hub-and-push, l ecran n a plus de lecteur.',
    reveil: 'Decision produit : supprimer la route ET `TrailDetailScreen`, ou '
        'la garder comme cible de deep-link documentee.',
  ),
  '/stages': RouteDormante(
    raison: 'Liste nue des etapes (`StageListScreen`, phase 2). Elle est le '
        'PARENT du detail `/stages/:id`, qui lui est bien atteint — les etapes '
        'se poussent depuis le Programme et le resume. La liste elle-meme est '
        'un doublon pauvre du Programme (`/trail/:id/itinerary`), qui ajoute '
        'les jours, le decoupage et les verdicts.',
    reveil: 'Decision produit : supprimer la liste et ne garder que le detail, '
        'ou assumer `/stages` comme simple prefixe sans ecran.',
  ),
  '/trail/:id/stage/:num': RouteDormante(
    raison: 'Detail d etape de la phase 1 (`TrailStageDetailScreen`). Le detail '
        'REELLEMENT ouvert par l application est `/stages/:id` '
        '(`TrekStageDetailScreen`), pousse depuis le Programme, le resume et '
        'l itineraire. Deux ecrans pour une meme question, un seul a une porte.',
    reveil: 'Decision produit : supprimer le jumeau de la phase 1, apres avoir '
        'verifie que le detail vivant ne lui doit rien.',
  ),
  '/trail/:id/journal': RouteDormante(
    raison: 'Journal de bord — MEME ECRAN, au meme parametre, que la route '
        'racine `/journal` (`JournalScreen(trailId:)`). C est la route racine '
        'que l application pousse, depuis le cockpit en rando et depuis le '
        'recap une fois le trek termine. Cette seconde adresse ne mene a rien '
        'de plus : c est un doublon de CHEMIN, pas de code.',
    reveil: 'Nettoyage du routeur : supprimer la route jumelle une fois '
        'verifie qu aucun lien profond publie ne la vise.',
  ),
  '/trail/:id/map': RouteDormante(
    raison: 'Carte du sentier par son chemin de la phase 1. Elle construit '
        'DESORMAIS le meme `MapScreen` que la route vivante `/map` (migration '
        'L6-4 terminee, l ancien ecran de transition `TrailMapScreen` a '
        'disparu) : les deux chemins menent au meme ecran. Or ses deux SEULS '
        'gestes entrants vivent sur `TrailDetailScreen` et '
        '`TrailStageDetailScreen`, les deux ecrans de la phase 1 endormis '
        'ci-dessus — la carte est donc atteignable uniquement depuis des ecrans '
        'que personne n atteint. Le randonneur ouvre la carte par le cockpit, '
        'qui pousse `/map`.',
    reveil: 'Avec les deux ecrans de la phase 1 : ce chemin disparait quand ils '
        'disparaissent, puisqu il n existe que pour eux.',
  ),
  '/trail-selection': RouteDormante(
    raison: 'Bascule de sentier actif (F8D-02). Le randonneur change de sentier '
        'par le CATALOGUE (`/catalog`), qui est une porte d entree de '
        'l application et fait le meme travail avec les visuels et les '
        'descriptions. Cet ecran est la version nue du meme geste.',
    reveil: 'Decision produit : supprimer l ecran au profit du catalogue, ou '
        'lui trouver un role distinct (bascule rapide sans quitter le cockpit).',
  ),

  // --- Fonction ecrite, place de sa porte jamais tranchee ----------------
  '/trail/:id/feedback': RouteDormante(
    raison: 'Formulaire d avis dans l application (type, message, note). '
        'L ecran fonctionne — le LOT X (tache 579) a justement repare son '
        'bouton d envoi, qui etait muet quand le message etait vide. Mais '
        'aucune place ne lui a jamais ete donnee dans l interface : ni les '
        'reglages, ni le cockpit, ni le recap ne l ouvrent.',
    reveil: 'Decision produit sur la place de l avis : les Reglages sont le '
        'candidat naturel. Le tester avec des randonneurs avant de le poser.',
  ),

  // --- Derriere un drapeau de fonctionnalite -----------------------------
  //
  // CES DEUX-LA SONT DIFFERENTES DE TOUTES LES AUTRES, et c est pourquoi elles
  // ne sont pas dans les `exceptionsDocumentees` de l invariante : leur porte
  // ne manque pas par decision ni par oubli, elle manque PAR ETAT. Le drapeau
  // est ferme, donc la route se redirige vers le catalogue avant meme de
  // construire son ecran. Poser une carte qui renvoie ailleurs serait le
  // defaut que le LOT Q a corrige.
  '/goodies': RouteDormante(
    raison: 'Boutique de goodies, gardee par `FeatureFlags.isGoodiesEnabled` : '
        'drapeau ferme, la route redirige vers le catalogue. Une porte visible '
        'vers un ecran qui renvoie ailleurs ment au randonneur.',
    reveil: 'Ouverture du drapeau goodies pour un sentier — la porte se pose '
        'alors AVEC le drapeau, et conditionnee par lui.',
  ),
  '/booking': RouteDormante(
    raison: 'Reservation (E5.13), gardee par `FeatureFlags.isBookingEnabled` et '
        'encore a l etat d ebauche : drapeau ferme, la route redirige vers le '
        'catalogue. Rien a montrer, donc rien a ouvrir.',
    reveil: 'Livraison de la reservation reelle et ouverture de son drapeau.',
  ),
};
