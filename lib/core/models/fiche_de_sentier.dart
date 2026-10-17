/// La fiche d'un sentier — sa description et ses photos — lue dans un
/// MANIFESTE, jamais ecrite dans le code.
library;

import 'dart:convert';

/// LA FICHE EST UNE DONNEE DU SENTIER, COMME LA TRACE ET LES ETAPES.
///
/// POURQUOI CE FICHIER EXISTE (demande de Christophe du 17/10 09:22, verbatim :
/// « Il manque un truc entre le catalogue et le demarrage de la preparation ce
/// sont les infos sur le trek selectionne. Il faut avant que ca ouvre la
/// preparation que le client puisse voir une description du trek. Ou c'est, le
/// trace, la difficulte, des photos, tout ca »).
///
/// LA SEULE AUTRE FACON DE FAIRE AURAIT ETE DU TEXTE EN DUR, et elle se
/// condamne d'elle-meme : une description ecrite dans l'ecran decrit UN
/// sentier, donc le deuxieme arrive vide et le troisieme aussi. C'est la meme
/// lecon que `TrailConfig` a apprise pour les numeros de secours et que la
/// tache 839 a apprise pour les chiffres : ce qui varie d'un sentier a l'autre
/// est une ENTREE DE DONNEE, et le moteur reste generique (#84627).
///
/// LES CHAMPS SONT FIXES, ET C'EST UN CONTRAT A DEUX. Le fonds de photos est
/// constitue a part (tache 845) : les noms de champs ci-dessous sont donc le
/// format que le producteur remplit et que ce lecteur attend. Les changer d'un
/// cote sans l'autre casse la lecture — exactement comme `TrailChunks` pour le
/// monolithe de donnees.
///
/// FORMAT DU MANIFESTE (`assets/data/<sentier>/fiche.json`) :
///
/// ```json
/// {
///   "schema": 1,
///   "trailId": "gr20",
///   "description": {
///     "ou_c_est": "...",
///     "ce_qu_on_y_voit": "...",
///     "a_quoi_s_attendre": "..."
///   },
///   "photos": [
///     {
///       "fichier": "assets/data/gr20/photos/nom.jpg",
///       "adresse_d_origine": "https://...",
///       "auteur": "Prenom Nom",
///       "licence": "CC BY-SA 4.0",
///       "mention": "Prenom Nom — CC BY-SA 4.0",
///       "lat": 42.4652,
///       "lon": 8.90688,
///       "couverture": true
///     }
///   ]
/// }
/// ```
class FicheDeSentier {
  /// Construit une fiche deja TRIEE : [photos] ne contient que du
  /// publiable, [photosRefusees] porte le reste avec son motif.
  const FicheDeSentier({
    required this.trailId,
    required this.description,
    required this.photos,
    required this.photosRefusees,
  });

  /// Identifiant du sentier decrit. C'EST LA CLE, et c'est la meme que celle du
  /// catalogue : une fiche qui parle d'un autre sentier n'est pas une fiche
  /// pauvre, c'est une fiche fausse (cf. [lireFicheDeSentier]).
  final String trailId;

  /// Ce qu'il y a a lire. Jamais nul : un sentier sans texte porte une
  /// description VIDE, qui se declare telle ([DescriptionDeSentier.estVide]).
  final DescriptionDeSentier description;

  /// Les photos PUBLIABLES, dans l'ordre du manifeste.
  final List<PhotoDeSentier> photos;

  /// Les photos ECARTEES et POURQUOI — l'absence est NOMMEE, jamais
  /// silencieuse.
  ///
  /// Meme discipline que `TrailCatalog.fictifsEcartes` : une donnee qui
  /// disparait sans explication est indiagnosticable. Un test peut interroger
  /// ce champ, et le fait.
  final List<PhotoRefusee> photosRefusees;

  /// La photo de COUVERTURE : celle qui se montre sur la carte du catalogue.
  ///
  /// C'est la premiere photo publiable qui se declare couverture, et a defaut
  /// la premiere publiable tout court. Nulle quand il n'y a aucune photo
  /// publiable — l'appelant n'affiche alors AUCUN cadre (regle du trou, cf.
  /// l'en-tete de [PhotoDeSentier]).
  PhotoDeSentier? get couverture {
    for (final photo in photos) {
      if (photo.couverture) return photo;
    }
    return photos.isEmpty ? null : photos.first;
  }

  /// Vrai quand la fiche n'a RIEN a montrer : ni texte, ni photo publiable.
  bool get estVide => description.estVide && photos.isEmpty;
}

/// LA DESCRIPTION, EN TROIS QUESTIONS ET PAS UN BLOC DE PROSE.
///
/// Les trois questions sont celles de la demande du 17/10 : OU C'EST, CE QU'ON
/// Y VOIT, A QUOI S'ATTENDRE. Les separer plutot que de les fondre en un seul
/// champ a une consequence utile : une description a moitie ecrite affiche la
/// moitie qui existe, au lieu de tout retenir jusqu'a ce que tout soit pret.
class DescriptionDeSentier {
  /// Les trois parties, chacune vide par defaut : une description
  /// absente est un etat normal, pas un parametre oublie.
  const DescriptionDeSentier({
    this.ouCest = '',
    this.ceQuOnYVoit = '',
    this.aQuoiSAttendre = '',
  });

  /// Aucune description : l'ecran n'affiche alors AUCUNE section.
  static const DescriptionDeSentier vide = DescriptionDeSentier();

  /// OU C'EST : la region, les deux bouts du chemin, comment on y arrive.
  final String ouCest;

  /// CE QU'ON Y VOIT : les paysages, les sommets, ce qui fait venir.
  final String ceQuOnYVoit;

  /// A QUOI S'ATTENDRE : le terrain, les couchages, ce qui surprend.
  final String aQuoiSAttendre;

  /// Vrai quand les trois champs sont vides.
  bool get estVide =>
      ouCest.isEmpty && ceQuOnYVoit.isEmpty && aQuoiSAttendre.isEmpty;

  /// Lit la description d'un manifeste. Un bloc absent rend [vide].
  static DescriptionDeSentier depuisJson(Object? brut) {
    if (brut is! Map<String, dynamic>) return vide;
    return DescriptionDeSentier(
      ouCest: _texte(brut['ou_c_est']),
      ceQuOnYVoit: _texte(brut['ce_qu_on_y_voit']),
      aQuoiSAttendre: _texte(brut['a_quoi_s_attendre']),
    );
  }
}

/// UNE PHOTO DU PRODUIT, ET LES CINQ CHAMPS QUI LA RENDENT PUBLIABLE.
///
/// POURQUOI LA PROVENANCE EST OBLIGATOIRE, ET CE QUE LE DEPOT A MESURE AVANT DE
/// L'EXIGER (memoire #102112, 17/10). Le depot porte 271 photos qui servent aux
/// carrousels, et leur seul fichier de suivi enregistre le sujet — NI la
/// source, NI la licence. Christophe, interroge, a repondu « On les a trouve
/// sur internet en libre de droit ». « Libre de droit » recouvre quatre
/// realites tres differentes : domaine public, CC0, CC-BY qui EXIGE de citer
/// l'auteur, et CC-BY-NC qui INTERDIT l'usage commercial. Dans une application
/// PAYANTE, deux de ces quatre cas sont des infractions — et sans trace, on ne
/// peut pas prouver dans lequel on est, photo par photo.
///
/// D'OU LA REGLE PORTEE PAR CE FICHIER : une photo sans adresse d'origine, sans
/// auteur, sans licence ou sans mention a afficher N'ENTRE PAS DANS LE PRODUIT.
/// Ce n'est pas un avertissement, c'est un refus — la meme difference qu'entre
/// le commentaire « donnees fictives » et le drapeau `isFictional` de la tache
/// 793 : un commentaire n'est pas une garde.
///
/// LA MENTION EST VISIBLE A L'ECRAN, comme le credit de la carte. Une licence
/// CC-BY respectee dans un fichier JSON et nulle part ailleurs n'est pas
/// respectee : elle exige que le nom soit LU par celui qui regarde l'image.
class PhotoDeSentier {
  /// Les cinq champs de provenance sont OBLIGATOIRES a la construction ;
  /// vides, ils rendent la photo non publiable (cf. [motifDeRefus]).
  const PhotoDeSentier({
    required this.fichier,
    required this.adresseDOrigine,
    required this.auteur,
    required this.licence,
    required this.mention,
    this.lat,
    this.lon,
    this.couverture = false,
  });

  /// Chemin de l'image dans les assets de l'application.
  final String fichier;

  /// Adresse d'ou l'image vient — la page, pas le fichier quand les deux
  /// existent : c'est la page qui porte la licence.
  final String adresseDOrigine;

  /// Auteur, tel qu'il faut le citer.
  final String auteur;

  /// Licence, telle qu'elle est ecrite a la source. Voir
  /// [LicencesCommerciales] pour celles qui sont acceptees.
  final String licence;

  /// Mention A AFFICHER sous la photo. Ce n'est pas un commentaire : c'est le
  /// texte que le randonneur doit pouvoir lire.
  final String mention;

  /// Latitude du lieu photographie, SI LA SOURCE LA DONNE. Nulle sinon — on ne
  /// devine pas un lieu.
  final double? lat;

  /// Longitude du lieu photographie, si la source la donne.
  final double? lon;

  /// Vrai pour la photo proposee comme COUVERTURE (carte du catalogue).
  final bool couverture;

  /// Vrai quand la source donne les deux coordonnees.
  bool get aDesCoordonnees => lat != null && lon != null;

  /// POURQUOI CETTE PHOTO NE PEUT PAS ENTRER DANS LE PRODUIT, ou null quand
  /// rien ne s'y oppose.
  MotifDeRefus? get motifDeRefus {
    if (fichier.isEmpty) return MotifDeRefus.fichierManquant;
    if (adresseDOrigine.isEmpty) return MotifDeRefus.sourceManquante;
    if (auteur.isEmpty) return MotifDeRefus.auteurManquant;
    if (licence.isEmpty) return MotifDeRefus.licenceManquante;
    if (mention.isEmpty) return MotifDeRefus.mentionManquante;
    if (!LicencesCommerciales.autorise(licence)) {
      return MotifDeRefus.licenceNonCommerciale;
    }
    return null;
  }

  /// Vrai quand les cinq champs de provenance sont la et que la licence
  /// autorise l'usage commercial.
  bool get estPubliable => motifDeRefus == null;

  /// Lit une photo du manifeste. Les champs absents valent vide : c'est
  /// [motifDeRefus] qui tranche, pas une exception.
  static PhotoDeSentier depuisJson(Map<String, dynamic> brut) {
    return PhotoDeSentier(
      fichier: _texte(brut['fichier']),
      adresseDOrigine: _texte(brut['adresse_d_origine']),
      auteur: _texte(brut['auteur']),
      licence: _texte(brut['licence']),
      mention: _texte(brut['mention']),
      lat: _nombre(brut['lat']),
      lon: _nombre(brut['lon']),
      couverture: brut['couverture'] == true,
    );
  }
}

/// Une photo ECARTEE du produit, et la raison en clair.
class PhotoRefusee {
  /// Le fichier refuse et le motif du refus, toujours les deux.
  const PhotoRefusee({required this.fichier, required this.motif});

  /// Le fichier refuse, ou une chaine vide quand c'est lui qui manquait.
  final String fichier;

  /// Pourquoi il est refuse.
  final MotifDeRefus motif;
}

/// LES MOTIFS DE REFUS D'UNE PHOTO — un par champ obligatoire, plus la licence.
enum MotifDeRefus {
  /// Aucun chemin d'image.
  fichierManquant,

  /// Aucune adresse d'origine : la provenance n'est pas prouvable.
  sourceManquante,

  /// Aucun auteur : une licence CC-BY ne peut pas etre respectee.
  auteurManquant,

  /// Aucune licence : on ne sait pas ce qu'on a le droit de faire.
  licenceManquante,

  /// Aucune mention a afficher : rien a montrer sous la photo.
  mentionManquante,

  /// Licence qui n'autorise pas l'usage commercial, ou inconnue de la liste
  /// blanche — dans une application payante, les deux se refusent.
  licenceNonCommerciale,
}

/// LES LICENCES QUI AUTORISENT L'USAGE COMMERCIAL — UNE LISTE BLANCHE.
///
/// POURQUOI UNE LISTE BLANCHE ET PAS UNE LISTE NOIRE, ET C'EST TOUT LE SUJET.
/// Une liste noire (« refuser ce qui contient NC ») laisse passer tout ce
/// qu'elle n'a pas prevu : une licence maison, un sigle mal orthographie, un
/// champ rempli « libre de droit » — c'est-a-dire precisement la phrase qui a
/// declenche cette regle. Une liste blanche refuse par defaut : l'inconnu
/// n'entre pas. C'est le sens du refus du 17/10 — sans trace, pas dans le
/// produit payant.
///
/// CE QUI EST DEDANS, ET RIEN D'AUTRE : le domaine public, CC0, et les CC-BY /
/// CC-BY-SA toutes versions. Tout ce qui porte NC (non commercial) est refuse
/// par construction, puisqu'il n'est pas dans la liste.
abstract final class LicencesCommerciales {
  LicencesCommerciales._();

  /// Les mentions de domaine public acceptees, une fois normalisees.
  static const Set<String> _domainePublic = <String>{
    'CC0',
    'CC01.0',
    'DOMAINEPUBLIC',
    'PUBLICDOMAIN',
    'PD',
  };

  /// `CC BY 4.0`, `CC-BY-SA-3.0`, `CC BY SA 2.5`... et rien d'autre.
  static final RegExp _creativeCommonsBy = RegExp(r'^CCBY(SA)?[0-9.]*$');

  /// Vrai si [licence] autorise l'usage commercial.
  ///
  /// La comparaison se fait sur une forme NORMALISEE (majuscules, sans espaces
  /// ni tirets ni soulignes) : « CC BY-SA 4.0 », « cc_by_sa_4.0 » et
  /// « CCBYSA4.0 » sont la meme licence, et une difference de ponctuation ne
  /// doit pas faire refuser une photo legitime.
  static bool autorise(String licence) {
    final normalisee = normaliser(licence);
    if (normalisee.isEmpty) return false;
    if (_domainePublic.contains(normalisee)) return true;
    return _creativeCommonsBy.hasMatch(normalisee);
  }

  /// La forme comparable d'un libelle de licence.
  static String normaliser(String licence) => licence
      .toUpperCase()
      .replaceAll(RegExp(r'[\s_\-]'), '')
      .replaceAll('LICENSE', '')
      .replaceAll('LICENCE', '');
}

/// Lit un manifeste de fiche de sentier.
///
/// [contenu] est le texte du fichier JSON, [trailId] le sentier attendu.
/// Retourne null quand le manifeste est illisible, vide, ou qu'il parle d'un
/// AUTRE sentier : une fiche absente est un etat normal (l'ecran n'affiche
/// alors pas la section), une fiche qui se trompe de sentier est une faute qui
/// ne doit pas s'afficher.
FicheDeSentier? lireFicheDeSentier(String contenu, String trailId) {
  final Object? brut;
  try {
    brut = jsonDecode(contenu);
  } on FormatException {
    return null;
  }
  if (brut is! Map<String, dynamic>) return null;

  final declare = _texte(brut['trailId']);
  if (declare.isNotEmpty && declare != trailId) return null;

  final publiables = <PhotoDeSentier>[];
  final refusees = <PhotoRefusee>[];
  final brutPhotos = brut['photos'];
  if (brutPhotos is List) {
    for (final entree in brutPhotos) {
      if (entree is! Map<String, dynamic>) continue;
      final photo = PhotoDeSentier.depuisJson(entree);
      final motif = photo.motifDeRefus;
      if (motif == null) {
        publiables.add(photo);
      } else {
        refusees.add(PhotoRefusee(fichier: photo.fichier, motif: motif));
      }
    }
  }

  return FicheDeSentier(
    trailId: trailId,
    description: DescriptionDeSentier.depuisJson(brut['description']),
    photos: List<PhotoDeSentier>.unmodifiable(publiables),
    photosRefusees: List<PhotoRefusee>.unmodifiable(refusees),
  );
}

/// Un texte du manifeste, toujours rendu : une valeur absente ou d'un autre
/// type vaut la chaine vide, jamais « null » affiche a l'ecran.
String _texte(Object? valeur) => valeur is String ? valeur.trim() : '';

/// Un nombre du manifeste, ou null quand la source ne le donne pas.
double? _nombre(Object? valeur) => valeur is num ? valeur.toDouble() : null;
