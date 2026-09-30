import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_branding.dart';

/// LES 156 ICONES DE CHRISTOPHE (tache 632, zip du 29/09 14:50).
///
/// Grille 24 px, trait 2 px, extremites arrondies, `stroke="currentColor"` :
/// elles prennent la couleur qu'on leur donne, comme une icone Material.
///
/// Cette liste et le widget [StepIcon] viennent de son
/// `flutter/stepways_icons.dart`, RECOPIES a l'identique (un script les extrait
/// de son fichier : les retaper aurait fini par produire un chemin faux, et un
/// chemin faux ne leve rien — il fait un trou a l'ecran).
///
/// Le commentaire de chaque constante porte son code ICO ou MAT, comme chez lui.
///
/// AJOUTE dessous, et seulement dessous : les trois familles BICOLORES
/// ([RubriqueStepways], [IcoStepways], [MatStepways]) et le widget
/// [IconeStepways] qui les rend — parce que ces dessins-la existent en trois
/// traces et qu'il fallait un seul endroit qui decide lequel est employe.
abstract final class StepwaysIcons {
  static const info = 'assets/icons/info.svg'; // MAT-001 Information
  static const coche = 'assets/icons/coche.svg'; // MAT-002 Coche
  static const cocheCercle =
      'assets/icons/coche-cercle.svg'; // MAT-002 Coche contour
  static const cochePleine =
      'assets/icons/coche-pleine.svg'; // MAT-002 Coche pleine
  static const radio = 'assets/icons/radio.svg'; // MAT-005 Radio vide
  static const radioCoche =
      'assets/icons/radio-coche.svg'; // MAT-005 Radio choisi
  static const pastille =
      'assets/icons/pastille.svg'; // MAT-005 Pastille d'état
  static const chevronDroite =
      'assets/icons/chevron-droite.svg'; // MAT-003 Chevron droite
  static const chevronGauche =
      'assets/icons/chevron-gauche.svg'; // MAT-003 Chevron gauche
  static const flecheHaut =
      'assets/icons/fleche-haut.svg'; // MAT-004 Flèche haut
  static const flecheBas = 'assets/icons/fleche-bas.svg'; // MAT-004 Flèche bas
  static const flecheAvant =
      'assets/icons/fleche-avant.svg'; // MAT-004 Flèche avant
  static const flecheArriere =
      'assets/icons/fleche-arriere.svg'; // MAT-004 Flèche arrière
  static const deplier = 'assets/icons/deplier.svg'; // MAT-011 Déplier
  static const replier = 'assets/icons/replier.svg'; // MAT-011 Replier
  static const plus = 'assets/icons/plus.svg'; // MAT-007 Plus
  static const moins = 'assets/icons/moins.svg'; // MAT-007 Moins
  static const rafraichir = 'assets/icons/rafraichir.svg'; // MAT-006 Rafraîchir
  static const annuler =
      'assets/icons/annuler.svg'; // MAT-006 Annuler (défaire)
  static const corbeille = 'assets/icons/corbeille.svg'; // MAT-008 Corbeille
  static const crayon = 'assets/icons/crayon.svg'; // MAT-010 Crayon
  static const copier = 'assets/icons/copier.svg'; // MAT-014 Copier
  static const inverser = 'assets/icons/inverser.svg'; // MAT-015 Inverser
  static const poignee = 'assets/icons/poignee.svg'; // MAT-012 Poignée
  static const menu = 'assets/icons/menu.svg'; // MAT-013 Menu trois points
  static const croix = 'assets/icons/croix.svg'; // MAT-009 Croix / fermer
  static const refuser = 'assets/icons/refuser.svg'; // MAT-009 Refuser
  static const interdit =
      'assets/icons/interdit.svg'; // MAT-009 Bloqué / interdit
  static const compresser = 'assets/icons/compresser.svg'; // MAT-016 Compresser
  static const imageManquante =
      'assets/icons/image-manquante.svg'; // MAT-017 Image manquante
  static const eprouvette =
      'assets/icons/eprouvette.svg'; // MAT-018 Expérimental
  static const geste = 'assets/icons/geste.svg'; // MAT-019 Geste / toucher
  static const pouce = 'assets/icons/pouce.svg'; // MAT-019 Pouce / approuver
  static const oeil = 'assets/icons/oeil.svg'; // MAT-020 Afficher
  static const oeilBarre = 'assets/icons/oeil-barre.svg'; // MAT-020 Masquer
  static const palette = 'assets/icons/palette.svg'; // MAT-021 Thème / palette
  static const ville = 'assets/icons/ville.svg'; // MAT-022 Ville
  static const echelle = 'assets/icons/echelle.svg'; // MAT-023 Échelle
  static const catalogueSentiers =
      'assets/icons/catalogue-sentiers.svg'; // Catalogue sentiers
  static const monCompte = 'assets/icons/mon-compte.svg'; // Mon compte
  static const reglages = 'assets/icons/reglages.svg'; // Paramètres
  static const faisabilite = 'assets/icons/faisabilite.svg'; // Faisabilité
  static const itineraire = 'assets/icons/itineraire.svg'; // Itinéraires
  static const programme = 'assets/icons/programme.svg'; // Programme
  static const calendrier = 'assets/icons/calendrier.svg'; // Calendrier
  static const preparationPhysique =
      'assets/icons/preparation-physique.svg'; // Préparation physique
  static const ficheMedicale =
      'assets/icons/fiche-medicale.svg'; // Fiche médicale
  static const meteo = 'assets/icons/meteo.svg'; // Météo
  static const incendie = 'assets/icons/incendie.svg'; // Incendie
  static const ravitaillement =
      'assets/icons/ravitaillement.svg'; // Ravitaillement
  static const nuitees = 'assets/icons/nuitees.svg'; // Nuitées
  static const transport = 'assets/icons/transport.svg'; // Transport
  static const carte = 'assets/icons/carte.svg'; // Cartes
  static const sacADos = 'assets/icons/sac-a-dos.svg'; // Matériel & sac
  static const hebergement = 'assets/icons/hebergement.svg'; // Hébergement
  static const ficheConseil = 'assets/icons/fiche-conseil.svg'; // Fiche conseil
  static const journal = 'assets/icons/journal.svg'; // Journal
  static const diplome = 'assets/icons/diplome.svg'; // Diplôme
  static const boussole = 'assets/icons/boussole.svg'; // Boussole
  static const repere = 'assets/icons/repere.svg'; // Repère
  static const maPosition = 'assets/icons/ma-position.svg'; // Ma position
  static const boucle = 'assets/icons/boucle.svg'; // Boucle
  static const allerRetour = 'assets/icons/aller-retour.svg'; // Aller-retour
  static const calques = 'assets/icons/calques.svg'; // Calques
  static const horsLigne = 'assets/icons/hors-ligne.svg'; // Hors ligne
  static const panneau = 'assets/icons/panneau.svg'; // Panneau
  static const distance = 'assets/icons/distance.svg'; // Distance
  static const denivelePlus = 'assets/icons/denivele-plus.svg'; // Dénivelé +
  static const deniveleMoins = 'assets/icons/denivele-moins.svg'; // Dénivelé −
  static const altitude = 'assets/icons/altitude.svg'; // Altitude
  static const duree = 'assets/icons/duree.svg'; // Durée
  static const pas = 'assets/icons/pas.svg'; // Pas
  static const vitesse = 'assets/icons/vitesse.svg'; // Vitesse
  static const difficulte = 'assets/icons/difficulte.svg'; // Difficulté
  static const depart = 'assets/icons/depart.svg'; // Départ
  static const sommet = 'assets/icons/sommet.svg'; // Sommet
  static const refuge = 'assets/icons/refuge.svg'; // Refuge
  static const camping = 'assets/icons/camping.svg'; // Camping
  static const pointEau = 'assets/icons/point-eau.svg'; // Point d'eau
  static const parking = 'assets/icons/parking.svg'; // Parking
  static const pointDeVue = 'assets/icons/point-de-vue.svg'; // Point de vue
  static const lac = 'assets/icons/lac.svg'; // Lac
  static const foret = 'assets/icons/foret.svg'; // Forêt
  static const pont = 'assets/icons/pont.svg'; // Pont
  static const danger = 'assets/icons/danger.svg'; // Danger
  static const photo = 'assets/icons/photo.svg'; // Photo
  static const restauration = 'assets/icons/restauration.svg'; // Restauration
  static const secours = 'assets/icons/secours.svg'; // Secours
  static const soleil = 'assets/icons/soleil.svg'; // Soleil
  static const nuageux = 'assets/icons/nuageux.svg'; // Nuageux
  static const pluie = 'assets/icons/pluie.svg'; // Pluie
  static const orage = 'assets/icons/orage.svg'; // Orage
  static const neige = 'assets/icons/neige.svg'; // Neige
  static const vent = 'assets/icons/vent.svg'; // Vent
  static const brouillard = 'assets/icons/brouillard.svg'; // Brouillard
  static const temperature = 'assets/icons/temperature.svg'; // Température
  static const nuit = 'assets/icons/nuit.svg'; // Nuit
  static const chaussure = 'assets/icons/chaussure.svg'; // Chaussure
  static const batons = 'assets/icons/batons.svg'; // Bâtons
  static const gourde = 'assets/icons/gourde.svg'; // Gourde
  static const frontale = 'assets/icons/frontale.svg'; // Frontale
  static const enregistrer = 'assets/icons/enregistrer.svg'; // Enregistrer
  static const pause = 'assets/icons/pause.svg'; // Pause
  static const stop = 'assets/icons/stop.svg'; // Stop
  static const favori = 'assets/icons/favori.svg'; // Favori
  static const note = 'assets/icons/note.svg'; // Note
  static const partager = 'assets/icons/partager.svg'; // Partager
  static const recherche = 'assets/icons/recherche.svg'; // Recherche
  static const filtres = 'assets/icons/filtres.svg'; // Filtres
  static const profil = 'assets/icons/profil.svg'; // Profil
  static const batterie = 'assets/icons/batterie.svg'; // Batterie
  static const sansReseau = 'assets/icons/sans-reseau.svg'; // Sans réseau
  static const signaler = 'assets/icons/signaler.svg'; // Signaler
  static const cadenas = 'assets/icons/cadenas.svg'; // ICO-001 Cadenas fermé
  static const cadenasOuvert =
      'assets/icons/cadenas-ouvert.svg'; // ICO-001 Cadenas ouvert
  static const bouclier =
      'assets/icons/bouclier.svg'; // ICO-005 Confidentialité
  static const cle = 'assets/icons/cle.svg'; // ICO-015 Clé / code
  static const connexion = 'assets/icons/connexion.svg'; // ICO-027 Connexion
  static const deconnexion =
      'assets/icons/deconnexion.svg'; // ICO-027 Déconnexion
  static const effacerTelephone =
      'assets/icons/effacer-telephone.svg'; // ICO-026 Tout effacer
  static const langue = 'assets/icons/langue.svg'; // ICO-008 Langue
  static const aide = 'assets/icons/aide.svg'; // ICO-009 Aide
  static const loi = 'assets/icons/loi.svg'; // ICO-017 Loi
  static const cgu = 'assets/icons/cgu.svg'; // ICO-017 Conditions (CGU)
  static const panier = 'assets/icons/panier.svg'; // ICO-002 Panier
  static const portefeuille =
      'assets/icons/portefeuille.svg'; // ICO-007 Portefeuille
  static const prix = 'assets/icons/prix.svg'; // ICO-007 Prix
  static const boutique = 'assets/icons/boutique.svg'; // ICO-007 Boutique
  static const video = 'assets/icons/video.svg'; // ICO-016 Vidéo
  static const telecharger =
      'assets/icons/telecharger.svg'; // ICO-004 Téléchargement
  static const miseAJour =
      'assets/icons/mise-a-jour.svg'; // ICO-004 Mise à jour
  static const synchronise =
      'assets/icons/synchronise.svg'; // ICO-004 Synchronisé
  static const sablier = 'assets/icons/sablier.svg'; // ICO-020 En attente
  static const historique = 'assets/icons/historique.svg'; // ICO-019 Historique
  static const statistiques =
      'assets/icons/statistiques.svg'; // ICO-006 Statistiques
  static const questionnaire =
      'assets/icons/questionnaire.svg'; // ICO-021 Questionnaire
  static const pdf = 'assets/icons/pdf.svg'; // ICO-023 Document PDF
  static const telephone = 'assets/icons/telephone.svg'; // ICO-003 Appel
  static const courrier = 'assets/icons/courrier.svg'; // ICO-018 Courrier
  static const envoyer = 'assets/icons/envoyer.svg'; // ICO-018 Envoyer
  static const notifications =
      'assets/icons/notifications.svg'; // ICO-011 Notifications
  static const suiveurs = 'assets/icons/suiveurs.svg'; // ICO-013 Suiveurs
  static const lien = 'assets/icons/lien.svg'; // ICO-025 Lien
  static const lienRompu = 'assets/icons/lien-rompu.svg'; // ICO-025 Lien rompu
  static const gpsPerdu = 'assets/icons/gps-perdu.svg'; // ICO-014 GPS perdu
  static const train = 'assets/icons/train.svg'; // ICO-010 Train
  static const taxi = 'assets/icons/taxi.svg'; // ICO-010 Voiture / taxi
  static const bateau = 'assets/icons/bateau.svg'; // ICO-010 Bateau
  static const avion = 'assets/icons/avion.svg'; // ICO-010 Avion
  static const poids = 'assets/icons/poids.svg'; // ICO-012 Poids
  static const taille = 'assets/icons/taille.svg'; // ICO-012 Taille
  static const age = 'assets/icons/age.svg'; // ICO-012 Âge
  static const sexe = 'assets/icons/sexe.svg'; // ICO-012 Sexe
  static const animaux = 'assets/icons/animaux.svg'; // ICO-022 Chiens / animaux
  static const hygiene = 'assets/icons/hygiene.svg'; // ICO-024 Hygiène
  static const rechaud = 'assets/icons/rechaud.svg'; // ICO-024 Réchaud
}

/// Une icone Stepways MONOCHROME, a la place d'un `Icon(Icons.x)`.
///
/// Se comporte comme une icone Material : elle prend la couleur de l'[IconTheme]
/// ambiant si aucune n'est donnee, donc elle suit le theme, l'etat d'un bouton,
/// la couleur d'un onglet selectionne. Les parametres portent les MEMES noms que
/// ceux d'`Icon` (`size`, `color`) : une substitution ne deplace rien d'autre.
///
/// POUR UNE TUILE, UTILISER [StepIcon.tuile] : c'est la porte d'entree de la
/// regle mono / duo decrite sur [iconeBicolorePour].
class StepIcon extends StatelessWidget {
  const StepIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : sujet = false;

  /// LE DESSIN EST LE SUJET DE CE QU'ON REGARDE (tache 639, bug 3).
  ///
  /// A employer pour l'icone d'une tuile principale, d'un en-tete de rubrique,
  /// d'une carte d'accueil : le dessin sort alors en BICOLORE des qu'il a un
  /// trace duo, exactement comme s'il avait ete appele par [IconeStepways]. Une
  /// couleur imposee retombe sur le monochrome, et un dessin sans trace duo
  /// (les icones du terrain) reste monochrome : la regle decide, pas l'ecran.
  const StepIcon.tuile(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  }) : sujet = true;

  final String asset;

  /// Vrai quand cet appel vient d'une TUILE (cf. [StepIcon.tuile]).
  final bool sujet;

  /// Laissee a null, la taille vient de l'[IconTheme] ambiant — comme pour une
  /// `Icon`. C'est ce qui fait qu'un `IconButton(iconSize: 18)` obtient bien
  /// 18 px : il ne passe pas de taille a son enfant, il pose un IconTheme.
  final double? size;

  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final t = size ?? theme.size ?? 24;
    // LA REGLE, APPLIQUEE ICI ET NULLE PART AILLEURS (tache 639).
    if (sujet && color == null) {
      final dessin = iconeBicolorePour(asset);
      if (dessin != null && dessin.duoParDefaut) {
        return IconeStepways(dessin, taille: t, semanticLabel: semanticLabel);
      }
    }
    final c = color ?? theme.color ?? AppBranding.vertSentier;
    return SvgPicture.asset(
      asset,
      width: t,
      height: t,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}

/// LA REGLE MONO / DUO, ECRITE UNE FOIS (tache 639, bug 3 du test du 30/09).
///
/// CE QUE LE LOT 632 AVAIT REELLEMENT POSE, MESURE AVANT DE CHANGER QUOI QUE CE
/// SOIT. Les trois familles bicolores etaient bien branchees, mais le duo ne
/// s'obtenait qu'en NOMMANT la rubrique a l'appel
/// (`rubrique: RubriqueStepways.carte`). Un seul ecran le faisait — le cockpit,
/// 17 fois. Les 14 autres tuiles de l'application, « Mes treks » et
/// « Compte-etapes » compris, passaient le chemin A PLAT (`icon:
/// StepwaysIcons.catalogueSentiers`), et retombaient donc sur le monochrome
/// teinte. Rien n'etait casse : la regle dependait de la FORME de l'appel, donc
/// de la memoire de celui qui ecrivait l'ecran. Verbatim de Christophe (30/09
/// 10:09) : « les icones de Mes treks ne sont pas bicolores / Compte etapes et
/// pret a partir non plus ».
///
/// LA REGLE NE DEPEND PLUS DE LA FORME DE L'APPEL, MAIS DU ROLE DU DESSIN :
///
///   * SUJET — icone de rubrique, tuile principale, en-tete de section, carte
///     d'acces : BICOLORE. C'est le dessin qu'on regarde, il porte l'identite.
///     Voie d'appel : [IconeStepways], [StepIcon.tuile], ou `rubrique:`.
///   * SERVICE — icone d'action en ligne, chevron, coche, puce, icone dont la
///     COULEUR porte un etat (verrou, alerte, onglet actif) : MONOCHROME
///     teinte. Voie d'appel : [StepIcon] tout court.
///
/// DEUX GARDE-FOUS PORTES PAR LA REGLE ELLE-MEME, pas par les ecrans :
///   1. une couleur imposee retombe TOUJOURS sur le monochrome — un trace
///      bicolore fige ignorerait la couleur et rendrait l'etat illisible ;
///   2. un dessin qui n'a PAS de trace duo (les icones du terrain : meteo de
///      detail, points d'interet, navigation, materiel) reste monochrome, quel
///      que soit le role. La famille repond, l'ecran ne decide pas.
///
/// Les 38 icones de mecanique (MAT) restent monochromes meme en tuile, parce que
/// [AppBranding.mecaniqueEnDuo] est faux : un chevron orange sur chaque ligne
/// crierait partout. Un seul mot a changer pour que ca bascule.
IconeBicolore? iconeBicolorePour(String asset) =>
    _parNomDeFichier[_nomDeFichier(asset)];

/// Le nom nu d'un fichier d'icone : sans dossier, sans extension. C'est la SEULE
/// chose que les quatre traces d'un meme dessin ont en commun — `carte.svg`,
/// `rubriques-duo/carte.svg`, `rubriques-duo-mono/carte.svg` et
/// `rubriques-duo-clair/carte.svg` donnent tous « carte ». La resolution par nom
/// evite d'ecrire quatre tables qui divergeraient.
String _nomDeFichier(String asset) {
  final barre = asset.lastIndexOf('/');
  final nom = barre < 0 ? asset : asset.substring(barre + 1);
  return nom.endsWith('.svg') ? nom.substring(0, nom.length - 4) : nom;
}

/// Table nom de fichier -> famille. Les rubriques sont posees EN DERNIER : si un
/// jour un nom existait dans deux familles, c'est la rubrique qui gagnerait (un
/// dessin de rubrique est toujours un sujet). Au 30/09 les 101 noms des trois
/// familles sont distincts — un test le verrouille.
final Map<String, IconeBicolore> _parNomDeFichier = <String, IconeBicolore>{
  for (final i in MatStepways.values) i.fichier: i,
  for (final i in IcoStepways.values) i.fichier: i,
  for (final i in RubriqueStepways.values) i.fichier: i,
};

/// Un dessin qui existe en TROIS traces : bicolore, bicolore clair, monochrome.
///
/// Christophe livre trois familles comme ca — les 20 rubriques de
/// l'application, les 43 icones ICO du metier, et les 38 icones MAT de la
/// mecanique d'interface — dans des dossiers differents mais avec exactement la
/// meme regle. Cette interface leur donne un rendu commun ([IconeStepways])
/// plutot que trois widgets jumeaux qui divergeraient.
abstract interface class IconeBicolore {
  /// Trace monochrome : prend la couleur qu'on lui donne. Indispensable des que
  /// la couleur doit varier (onglet actif, element desactive).
  String get mono;

  /// Trace bicolore, couleurs FIGEES dans le fichier. A poser sans filtre.
  String get duo;

  /// Meme dessin, le vert remplace par le creme, pour les fonds sombres.
  /// Genere par `tool/set_branding.py`, jamais edite.
  String get duoClair;

  /// Vrai si cette famille s'affiche en bicolore par defaut. C'est la famille
  /// qui repond, pas l'appelant : voir [AppBranding.iconesEnDuo] et
  /// [AppBranding.mecaniqueEnDuo].
  bool get duoParDefaut;
}

/// LES 20 RUBRIQUES DE L'APPLICATION.
enum RubriqueStepways implements IconeBicolore {
  catalogueSentiers('catalogue-sentiers'),
  monCompte('mon-compte'),
  reglages('reglages'),
  faisabilite('faisabilite'),
  itineraire('itineraire'),
  programme('programme'),
  calendrier('calendrier'),
  preparationPhysique('preparation-physique'),
  ficheMedicale('fiche-medicale'),
  meteo('meteo'),
  incendie('incendie'),
  ravitaillement('ravitaillement'),
  nuitees('nuitees'),
  transport('transport'),
  carte('carte'),
  sacADos('sac-a-dos'),
  hebergement('hebergement'),
  ficheConseil('fiche-conseil'),
  journal('journal'),
  diplome('diplome');

  const RubriqueStepways(this.fichier);

  /// Nom de fichier commun aux trois traces (sans dossier ni extension).
  final String fichier;

  @override
  String get mono => 'assets/icons/rubriques-duo-mono/$fichier.svg';

  @override
  String get duo => 'assets/icons/rubriques-duo/$fichier.svg';

  @override
  String get duoClair => 'assets/icons/rubriques-duo-clair/$fichier.svg';

  @override
  bool get duoParDefaut => AppBranding.iconesEnDuo;
}

/// LES 43 ICONES DU METIER, ICO-001 A ICO-027.
///
/// Le cadenas, le telephone, le portefeuille, la langue, les notifications, les
/// modes de transport, les mesures du randonneur... Leur trace MONOCHROME est le
/// fichier a plat de [StepwaysIcons] — le meme dessin, pas une seconde version.
enum IcoStepways implements IconeBicolore {
  /// ICO-012 Âge
  age('age'),

  /// ICO-009 Aide
  aide('aide'),

  /// ICO-022 Chiens / animaux
  animaux('animaux'),

  /// ICO-010 Avion
  avion('avion'),

  /// ICO-010 Bateau
  bateau('bateau'),

  /// ICO-005 Confidentialité
  bouclier('bouclier'),

  /// ICO-007 Boutique
  boutique('boutique'),

  /// ICO-001 Cadenas ouvert
  cadenasOuvert('cadenas-ouvert'),

  /// ICO-001 Cadenas fermé
  cadenas('cadenas'),

  /// ICO-017 Conditions (CGU)
  cgu('cgu'),

  /// ICO-015 Clé / code
  cle('cle'),

  /// ICO-027 Connexion
  connexion('connexion'),

  /// ICO-018 Courrier
  courrier('courrier'),

  /// ICO-027 Déconnexion
  deconnexion('deconnexion'),

  /// ICO-026 Tout effacer
  effacerTelephone('effacer-telephone'),

  /// ICO-018 Envoyer
  envoyer('envoyer'),

  /// ICO-014 GPS perdu
  gpsPerdu('gps-perdu'),

  /// ICO-019 Historique
  historique('historique'),

  /// ICO-024 Hygiène
  hygiene('hygiene'),

  /// ICO-008 Langue
  langue('langue'),

  /// ICO-025 Lien rompu
  lienRompu('lien-rompu'),

  /// ICO-025 Lien
  lien('lien'),

  /// ICO-017 Loi
  loi('loi'),

  /// ICO-004 Mise à jour
  miseAJour('mise-a-jour'),

  /// ICO-011 Notifications
  notifications('notifications'),

  /// ICO-002 Panier
  panier('panier'),

  /// ICO-023 Document PDF
  pdf('pdf'),

  /// ICO-012 Poids
  poids('poids'),

  /// ICO-007 Portefeuille
  portefeuille('portefeuille'),

  /// ICO-007 Prix
  prix('prix'),

  /// ICO-021 Questionnaire
  questionnaire('questionnaire'),

  /// ICO-024 Réchaud
  rechaud('rechaud'),

  /// ICO-020 En attente
  sablier('sablier'),

  /// ICO-012 Sexe
  sexe('sexe'),

  /// ICO-006 Statistiques
  statistiques('statistiques'),

  /// ICO-013 Suiveurs
  suiveurs('suiveurs'),

  /// ICO-004 Synchronisé
  synchronise('synchronise'),

  /// ICO-012 Taille
  taille('taille'),

  /// ICO-010 Voiture / taxi
  taxi('taxi'),

  /// ICO-004 Téléchargement
  telecharger('telecharger'),

  /// ICO-003 Appel
  telephone('telephone'),

  /// ICO-010 Train
  train('train'),

  /// ICO-016 Vidéo
  video('video');

  const IcoStepways(this.fichier);

  /// Nom de fichier commun aux trois traces (sans dossier ni extension).
  final String fichier;

  @override
  String get mono => 'assets/icons/$fichier.svg';

  @override
  String get duo => 'assets/icons/ico-duo/$fichier.svg';

  @override
  String get duoClair => 'assets/icons/ico-duo-clair/$fichier.svg';

  @override
  bool get duoParDefaut => AppBranding.iconesEnDuo;
}

/// LES 38 ICONES DE LA MECANIQUE D'INTERFACE, MAT-001 A MAT-023.
///
/// Chevrons, fleches, coches, plus, moins, croix, crayon, corbeille... Elles ne
/// sont jamais LE SUJET : elles accompagnent une ligne de liste, un bouton, un
/// champ. D'ou [AppBranding.mecaniqueEnDuo] a faux — un chevron orange sur
/// chaque ligne crierait partout.
enum MatStepways implements IconeBicolore {
  /// MAT-006 Annuler (défaire)
  annuler('annuler'),

  /// MAT-003 Chevron droite
  chevronDroite('chevron-droite'),

  /// MAT-003 Chevron gauche
  chevronGauche('chevron-gauche'),

  /// MAT-002 Coche contour
  cocheCercle('coche-cercle'),

  /// MAT-002 Coche pleine
  cochePleine('coche-pleine'),

  /// MAT-002 Coche
  coche('coche'),

  /// MAT-016 Compresser
  compresser('compresser'),

  /// MAT-014 Copier
  copier('copier'),

  /// MAT-008 Corbeille
  corbeille('corbeille'),

  /// MAT-010 Crayon
  crayon('crayon'),

  /// MAT-009 Croix / fermer
  croix('croix'),

  /// MAT-011 Déplier
  deplier('deplier'),

  /// MAT-023 Échelle
  echelle('echelle'),

  /// MAT-018 Expérimental
  eprouvette('eprouvette'),

  /// MAT-004 Flèche arrière
  flecheArriere('fleche-arriere'),

  /// MAT-004 Flèche avant
  flecheAvant('fleche-avant'),

  /// MAT-004 Flèche bas
  flecheBas('fleche-bas'),

  /// MAT-004 Flèche haut
  flecheHaut('fleche-haut'),

  /// MAT-019 Geste / toucher
  geste('geste'),

  /// MAT-017 Image manquante
  imageManquante('image-manquante'),

  /// MAT-001 Information
  info('info'),

  /// MAT-009 Bloqué / interdit
  interdit('interdit'),

  /// MAT-015 Inverser
  inverser('inverser'),

  /// MAT-013 Menu trois points
  menu('menu'),

  /// MAT-007 Moins
  moins('moins'),

  /// MAT-020 Masquer
  oeilBarre('oeil-barre'),

  /// MAT-020 Afficher
  oeil('oeil'),

  /// MAT-021 Thème / palette
  palette('palette'),

  /// MAT-005 Pastille d'état
  pastille('pastille'),

  /// MAT-007 Plus
  plus('plus'),

  /// MAT-012 Poignée
  poignee('poignee'),

  /// MAT-019 Pouce / approuver
  pouce('pouce'),

  /// MAT-005 Radio choisi
  radioCoche('radio-coche'),

  /// MAT-005 Radio vide
  radio('radio'),

  /// MAT-006 Rafraîchir
  rafraichir('rafraichir'),

  /// MAT-009 Refuser
  refuser('refuser'),

  /// MAT-011 Replier
  replier('replier'),

  /// MAT-022 Ville
  ville('ville');

  const MatStepways(this.fichier);

  /// Nom de fichier commun aux trois traces (sans dossier ni extension).
  final String fichier;

  @override
  String get mono => 'assets/icons/$fichier.svg';

  @override
  String get duo => 'assets/icons/mat-duo/$fichier.svg';

  @override
  String get duoClair => 'assets/icons/mat-duo-clair/$fichier.svg';

  @override
  bool get duoParDefaut => AppBranding.mecaniqueEnDuo;
}

/// UNE ICONE BICOLORE — LE SEUL ENDROIT QUI CHOISIT ENTRE DUO ET MONOCHROME.
///
/// Le choix vit dans [AppBranding] : deux constantes, pas cent decisions
/// eparpillees. La famille dit laquelle la concerne ([IconeBicolore.duoParDefaut]).
///
/// DEUX CAS FORCENT LE MONOCHROME, et ils ne sont pas negociables :
///   - [couleur] donnee : l'appelant veut une couleur precise (onglet actif,
///     element desactive, icone sur un aplat colore). Un trace bicolore fige
///     ignorerait cette couleur et rendrait l'etat illisible.
///   - fond sombre : le vert #1F3D2B y disparaitrait — d'ou le trace
///     [IconeBicolore.duoClair], choisi ici et nulle part ailleurs.
class IconeStepways extends StatelessWidget {
  const IconeStepways(
    this.icone, {
    super.key,
    this.taille = 24,
    this.couleur,
    this.surFondSombre,
    this.semanticLabel,
  });

  final IconeBicolore icone;
  final double taille;

  /// Force le trace monochrome et cette couleur.
  final Color? couleur;

  /// Vrai si l'icone est posee sur un fond sombre. Laisse a null, la luminosite
  /// du theme ambiant decide.
  final bool? surFondSombre;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (!icone.duoParDefaut || couleur != null) {
      return StepIcon(
        icone.mono,
        size: taille,
        color: couleur,
        semanticLabel: semanticLabel,
      );
    }

    final sombre =
        surFondSombre ?? Theme.brightnessOf(context) == Brightness.dark;
    return SvgPicture.asset(
      sombre ? icone.duoClair : icone.duo,
      width: taille,
      height: taille,
      semanticsLabel: semanticLabel,
    );
  }
}
