/// Modele de donnees TRANSPORT d'un sentier (parite GR20 `TransportScreen`,
/// data-driven — regle « donnees en externe » de Christophe).
///
/// GR20 hardcode le contenu transport par LOCALITE (widgets `_CalenzanaArrivalTab`,
/// `_ConcaDepartureTab`...). Cote StepWays, le moteur reste GENERIQUE
/// multi-sentiers (#84627, #99460) : le contenu transport n'est PAS code en dur
/// mais fourni en DONNEE, par sentier et par ENDPOINT (point de depart / point
/// d'arrivee, dans les 2 sens). Le backend (Phase 4) remplacera le catalogue
/// embarque par le contenu reel rapatrie dans le pack.
///
/// Modele PUR (aucune dependance Flutter/Slang) : les libelles d'INTERFACE
/// (titres d'onglet, « Conseils pratiques », bouton site) sont resolus cote UI
/// via Slang (5 langues) ; les DONNEES propres au sentier (nom d'operateur,
/// horaires indicatifs, description) restent dans la langue de la donnee — meme
/// principe que le catalogue de town guides (F8C-01). Les icones et couleurs
/// semantiques sont designees par des CLES stables ([TransportModeKind]),
/// resolues en `IconData`/`Color` cote widget (le domaine ne connait pas
/// Material).
library;

/// Sens du transport pour un endpoint (parite GR20 `_TransportRole`).
///
/// - [arrival]   : comment REJOINDRE ce lieu (onglet « Aller »).
/// - [departure] : comment REPARTIR de ce lieu (onglet « Retour »).
enum TransportRole {
  /// Rejoindre le lieu (aller).
  arrival,

  /// Repartir du lieu (retour).
  departure,
}

/// Famille de mode de transport — CLE stable, resolue en icone/couleur cote UI.
///
/// Le widget mappe chaque valeur vers un `IconData` (parite GR20 :
/// `Icons.local_taxi`, `Icons.directions_bus`, `Icons.train`...). Une valeur
/// inconnue retombe sur [other] cote widget (aucun crash, le moteur reste
/// tolerant a un futur catalogue serveur).
enum TransportModeKind {
  /// Taxi (parite GR20 `Icons.local_taxi`).
  taxi,

  /// Bus / autocar (parite GR20 `Icons.directions_bus`).
  bus,

  /// Train (parite GR20 `Icons.train`).
  train,

  /// Navette / shuttle (parite GR20 `Icons.airport_shuttle`).
  shuttle,

  /// Ferry / bateau (parite GR20 `Icons.directions_boat`).
  ferry,

  /// Avion / vol (parite GR20 `Icons.flight`).
  plane,

  /// Location de voiture (parite GR20 `Icons.car_rental`).
  carRental,

  /// Autre mode (repli).
  other,
}

/// Une OPTION de transport concrete (parite GR20 `_TransportOptionCard`).
///
/// Porte exactement les memes champs que la carte GR20 : titre, description,
/// prix (badge), horaires indicatifs, contact cliquable (tel:) + son libelle, et
/// un lien web optionnel (ouvert via url_launcher). [mode] designe l'icone/teinte
/// (resolue cote UI). Aucun texte d'interface ici : ce sont des DONNEES du
/// sentier (langue de la donnee), pas des libelles traduits.
class TransportOption {
  const TransportOption({
    required this.mode,
    required this.title,
    required this.description,
    required this.contact,
    required this.contactLabel,
    this.price = '',
    this.schedule = '',
    this.url,
  });

  /// Famille de mode (icone/couleur resolues cote widget).
  final TransportModeKind mode;

  /// Titre de l'option (ex. « Bus Bastia -> Calvi »). Donnee du sentier.
  final String title;

  /// Description courte (trajet, duree, specificites). Donnee du sentier.
  final String description;

  /// Numero de telephone a appeler (tel:), format national/international.
  /// Vide = pas de contact tel (l'UI masque alors le bloc contact).
  final String contact;

  /// Libelle du contact (ex. « Les Beaux Voyages »). Donnee du sentier.
  final String contactLabel;

  /// Prix indicatif affiche en badge (ex. « 4 EUR », « Variable »). Peut etre
  /// vide (badge masque).
  final String price;

  /// Horaires indicatifs (multi-lignes possibles). Peut etre vide (bloc masque).
  final String schedule;

  /// Lien web optionnel (site de l'operateur), ouvert en application externe.
  /// Null/vide = pas de bouton site (parite GR20 : `url` optionnel).
  final String? url;

  /// Vrai si un contact telephonique est disponible.
  bool get hasContact => contact.isNotEmpty;

  /// Vrai si un lien web est disponible (bouton « site » affiche).
  bool get hasUrl => url != null && url!.isNotEmpty;
}

/// Une SECTION thematique d'options (parite GR20 `SectionHeader` + cartes).
///
/// Regroupe les options d'un meme theme (ex. « Depuis l'aeroport de Calvi »,
/// « Vers Porto-Vecchio »). [title] est une DONNEE du sentier (langue de la
/// donnee) — pas un libelle d'interface (les sections varient par lieu, elles ne
/// peuvent pas etre des cles i18n fixes). [mode] fournit une icone d'en-tete de
/// section (resolue cote widget).
class TransportSection {
  const TransportSection({
    required this.title,
    required this.options,
    this.mode = TransportModeKind.other,
  });

  /// Titre de la section (donnee du sentier).
  final String title;

  /// Mode dominant de la section (icone d'en-tete, resolue cote widget).
  final TransportModeKind mode;

  /// Options de la section (au moins une en general ; peut etre vide -> masquee).
  final List<TransportOption> options;
}

/// Infos transport d'UN endpoint dans UN sens (parite GR20 : un onglet complet,
/// ex. `_CalenzanaArrivalTab`).
///
/// [endpointName] est le nom du lieu (point de depart ou d'arrivee du sentier),
/// resolu depuis les DONNEES du sentier (etapes : `departureName`/`arrivalName`,
/// direction-aware). [role] indique s'il s'agit de REJOINDRE (aller) ou de
/// REPARTIR (retour). [intro] est le paragraphe d'introduction (donnee du
/// sentier). [sections] portent les options. [advices] = conseils pratiques
/// (donnees du sentier), affiches dans la carte « Conseils » commune.
class EndpointTransport {
  const EndpointTransport({
    required this.endpointName,
    required this.role,
    this.intro = '',
    this.sections = const <TransportSection>[],
    this.advices = const <String>[],
  });

  /// Nom du lieu (endpoint) concerne.
  final String endpointName;

  /// Sens (rejoindre / repartir).
  final TransportRole role;

  /// Paragraphe d'introduction (donnee du sentier, peut etre vide).
  final String intro;

  /// Sections d'options de transport.
  final List<TransportSection> sections;

  /// Conseils pratiques (donnees du sentier, liste possiblement vide).
  final List<String> advices;

  /// Vrai s'il y a du contenu affichable (au moins une section avec options).
  bool get hasContent => sections.any((s) => s.options.isNotEmpty);
}

/// Donnees transport COMPLETES d'un sentier (parite GR20 `TransportScreen`).
///
/// Rattachees a un [trailId] (genericite #84627). Fournit, pour chaque lieu
/// (endpoint) et chaque sens, ses infos transport. L'ecran resout les 2 endpoints
/// courants (depart/arrivee, direction-aware) via les DONNEES du sentier, puis
/// demande a ce modele l'[EndpointTransport] correspondant. Le contenu est
/// consultable 100 % OFFLINE (embarque, comme les town guides).
class TrailTransport {
  const TrailTransport({
    required this.trailId,
    this.endpoints = const <EndpointTransport>[],
  });

  /// Identifiant du sentier.
  final String trailId;

  /// Infos transport par (endpoint, sens).
  final List<EndpointTransport> endpoints;

  /// Retourne les infos transport pour le lieu [endpointName] dans le sens
  /// [role], ou null si le sentier ne fournit pas cette donnee (fallback UI).
  ///
  /// La comparaison de nom est insensible a la casse et aux espaces de bord,
  /// pour resister a de menues divergences entre `departureName`/`arrivalName`
  /// des etapes et les cles du catalogue transport.
  EndpointTransport? forEndpoint(String endpointName, TransportRole role) {
    final needle = endpointName.trim().toLowerCase();
    for (final e in endpoints) {
      if (e.role == role && e.endpointName.trim().toLowerCase() == needle) {
        return e;
      }
    }
    return null;
  }
}
