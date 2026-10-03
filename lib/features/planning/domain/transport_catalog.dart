import 'transport_info.dart';

/// Catalogue de donnees TRANSPORT par sentier (parite GR20 `TransportScreen`,
/// data-driven — regle « donnees en externe » de Christophe).
///
/// Equivalent structurel du GR20 `_build*Tab` hardcode par localite, mais cote
/// StepWays le contenu est une DONNEE parametree par sentier (genericite
/// #84627) : AUCUNE localite n'est codee en dur DANS LE MOTEUR. Ce catalogue
/// embarque joue le role du contenu offline rapatrie dans le pack (comme le
/// [TownGuideCatalog]) ; le backend (Phase 4) le remplacera par le contenu reel.
///
/// Fonctions PURES (aucune dependance Flutter/Slang). Le contenu par sentier est
/// dans la langue de la donnee (ici FR pour le sentier corse) ; l'INTERFACE de
/// l'ecran (onglets, conseils, boutons) est traduite cote UI via Slang.
///
/// HONNETETE DES DONNEES (regle Chris #99460) : on n'invente jamais un horaire
/// ni un tarif. Les liens web et telephones sont ceux des operateurs/offices
/// connus quand ils existent ; sinon champ vide (l'UI masque).
///
/// UN TARIF OU UN HORAIRE QU'ON N'A PAS N'EST PLUS ECRIT DU TOUT (lot 645-08,
/// voie V2 arbitree par Christophe le 02/10/2026). La regle etait « on met une
/// entree explicite a completer plutot qu'un horaire faux ». Elle evitait le
/// mensonge et gardait le bruit : VINGT-SEPT fois, le randonneur lisait un
/// marqueur d'editeur a la place d'une information — dix badges de prix
/// « a completer » en vert, huit blocs d'horaires qui se terminaient par
/// « (a completer) », et neuf libelles de contact qui portaient l'aveu dans
/// leur nom. Desormais [TransportOption.price] et [TransportOption.schedule]
/// portent une valeur, ou sont absents : leur defaut est la chaine vide, et
/// `transport_screen.dart` ne construit ni le badge ni le bloc sombre des
/// horaires dans ce cas (`if (option.price.isNotEmpty)`,
/// `if (option.schedule.isNotEmpty)`). Rien ne les remplace — pas de tiret,
/// pas de « non renseigne », pas d'espace reserve.
///
/// LES LIBELLES DE CONTACT, EUX, RESTENT — SANS L'AVEU. `contactLabel` nomme
/// l'operateur (« Taxi », « Autocars du golfe », « Port d'Ajaccio ») et n'est
/// affiche que lorsqu'il y a un numero ou un site a cote de lui
/// (`if (option.hasContact || option.hasUrl)`). Le « (a completer) » qu'ils
/// portaient parlait du NUMERO manquant, deja masque : il ne restait qu'a le
/// retirer du nom.
///
/// CE QUE CELA A COUTE. Quatre horaires portaient aussi un fait saisonnier que
/// le champ ne sait pas exprimer seul (« frequence renforcee en saison »,
/// « service saisonnier »). Il tombe avec le marqueur, faute d'une rubrique
/// « saisonnalite » distincte de l'horaire. Les horaires REELS du catalogue
/// (« Sur reservation », « Selon compagnies maritimes », « Variable ») sont
/// intacts : ils disent quelque chose.
abstract final class TransportCatalog {
  /// Retourne les donnees transport du sentier [trailId], ou `null` si le sentier
  /// n'en fournit pas (l'ecran affiche alors un fallback informatif propre).
  ///
  /// Le moteur reste generique : le mapping id -> donnees est une simple table de
  /// DONNEES embarquees, jamais une localite codee dans la logique du moteur.
  static TrailTransport? forTrail(String trailId) {
    switch (trailId) {
      case 'mare-a-mare-centre':
        return _mareAMareCentre;
      default:
        return null;
    }
  }

  // ==========================================================================
  // Mare a Mare Centre (Corse) — sentier VITRINE de demonstration (#99423).
  //
  // Endpoints reels (assets/data/mare_a_mare_centre/stages.json) :
  //   depart  = Ghisonaccia (plaine orientale, cote est)
  //   arrivee = Porticcio   (golfe d'Ajaccio, cote ouest)
  // Le sentier etant bi-directionnel (directions ['NS','SN']), on fournit les
  // 4 combinaisons (chaque endpoint en « rejoindre » ET en « repartir »).
  // ==========================================================================
  static const TrailTransport _mareAMareCentre = TrailTransport(
    trailId: 'mare-a-mare-centre',
    endpoints: [
      // --- Ghisonaccia : REJOINDRE (aller, depart du sentier sens N->S) ------
      EndpointTransport(
        endpointName: 'Ghisonaccia',
        role: TransportRole.arrival,
        intro:
            'Ghisonaccia est le point de depart du Mare a Mare Centre, sur la '
            'plaine orientale. La ville est desservie depuis Bastia et Ajaccio '
            'par la route territoriale T10 (ex-N198).',
        sections: [
          TransportSection(
            title: 'Depuis Bastia (port / aeroport de Poretta)',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Bastia -> Ghisonaccia',
                description:
                    'Ligne de la plaine orientale (cote est), via Aleria. '
                    'Trajet indicatif ~1h30.',
                contact: '',
                contactLabel: 'Autocars de la plaine orientale',
              ),
              TransportOption(
                mode: TransportModeKind.taxi,
                title: 'Taxi depuis Bastia',
                description: 'Trajet direct sur reservation. Duree ~1h15.',
                schedule: 'Sur reservation',
                contact: '',
                contactLabel: 'Taxi',
              ),
            ],
          ),
          TransportSection(
            title: 'Depuis Ajaccio',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Ajaccio -> Ghisonaccia',
                description:
                    'Liaison transversale via le col de Vizzavona puis la '
                    'plaine orientale. Correspondance possible. Trajet ~2h30.',
                contact: '',
                contactLabel: 'Autocars',
              ),
            ],
          ),
          TransportSection(
            title: 'Office de tourisme',
            mode: TransportModeKind.other,
            options: [
              TransportOption(
                mode: TransportModeKind.other,
                title: 'Office de tourisme de l\'Oriente (Ghisonaccia)',
                description:
                    'Informations horaires de bus, navettes locales et depart '
                    'du sentier.',
                price: '',
                schedule: '',
                contact: '+33495561200',
                contactLabel: 'Office de tourisme Costa Verde / Oriente',
                url: 'https://www.oriente-corsica.com',
              ),
            ],
          ),
        ],
        advices: [
          'Faites votre dernier ravitaillement a Ghisonaccia (commerces et '
              'supermarches en centre-ville).',
          'Verifiez les horaires de bus la veille : les liaisons sont '
              'reduites hors saison estivale.',
          'Le depart du sentier se situe au-dessus de la plaine : prevoyez le '
              'transfert local jusqu\'au debut de l\'itineraire.',
        ],
      ),

      // --- Porticcio : REPARTIR (retour, arrivee du sentier sens N->S) -------
      EndpointTransport(
        endpointName: 'Porticcio',
        role: TransportRole.departure,
        intro:
            'Porticcio est l\'arrivee du Mare a Mare Centre, sur le golfe '
            'd\'Ajaccio. La station est reliee a Ajaccio (et son aeroport '
            'Napoleon-Bonaparte) par la route et, en saison, par navette '
            'maritime.',
        sections: [
          TransportSection(
            title: 'Vers Ajaccio (centre-ville)',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Porticcio -> Ajaccio',
                description:
                    'Ligne du golfe (rive sud) vers la gare routiere '
                    'd\'Ajaccio. Trajet ~40 min selon trafic.',
                contact: '',
                contactLabel: 'Autocars du golfe',
              ),
              TransportOption(
                mode: TransportModeKind.ferry,
                title: 'Navette maritime Porticcio -> Ajaccio',
                description:
                    'Liaison saisonniere par bateau a travers le golfe. '
                    'Alternative panoramique a la route. Duree ~20 min.',
                contact: '',
                contactLabel: 'Navette maritime du golfe',
              ),
            ],
          ),
          TransportSection(
            title: 'Vers l\'aeroport d\'Ajaccio Napoleon-Bonaparte',
            mode: TransportModeKind.plane,
            options: [
              TransportOption(
                mode: TransportModeKind.taxi,
                title: 'Taxi Porticcio -> Aeroport d\'Ajaccio',
                description:
                    'Aeroport Napoleon-Bonaparte (Campo dell\'Oro). Trajet '
                    'direct ~25 min.',
                schedule: 'Sur reservation',
                contact: '',
                contactLabel: 'Taxi',
              ),
              TransportOption(
                mode: TransportModeKind.plane,
                title: 'Aeroport d\'Ajaccio Napoleon-Bonaparte',
                description:
                    'Vols vers le continent (Paris, Marseille, Nice, Lyon...) '
                    'selon compagnies et saison.',
                price: 'Variable',
                schedule: 'Selon compagnies',
                contact: '+33495234545',
                contactLabel: 'Aeroport d\'Ajaccio',
                url: 'https://www.2a.cci.corsica/aeroport-ajaccio',
              ),
            ],
          ),
          TransportSection(
            title: 'Vers le port d\'Ajaccio (ferries continent)',
            mode: TransportModeKind.ferry,
            options: [
              TransportOption(
                mode: TransportModeKind.ferry,
                title: 'Ferry depuis Ajaccio',
                description:
                    'Traversees vers Marseille, Toulon et Nice depuis le port '
                    'de commerce d\'Ajaccio (rejoindre Ajaccio d\'abord).',
                price: 'Variable',
                schedule: 'Selon compagnies maritimes',
                contact: '',
                contactLabel: 'Port d\'Ajaccio',
              ),
            ],
          ),
        ],
        advices: [
          'Celebrez votre arrivee sur la plage de Porticcio, face au golfe '
              'd\'Ajaccio !',
          'Ajaccio dispose de tous les commerces et services pour le retour.',
          'En saison, la navette maritime est une belle alternative a la route '
              'pour rejoindre Ajaccio.',
          'Reservez tot vols et ferries en haute saison (juillet-aout).',
        ],
      ),

      // --- Ghisonaccia : REPARTIR (retour, arrivee du sentier sens S->N) -----
      EndpointTransport(
        endpointName: 'Ghisonaccia',
        role: TransportRole.departure,
        intro:
            'Vous terminez le Mare a Mare Centre a Ghisonaccia, sur la plaine '
            'orientale. Rejoignez Bastia ou Ajaccio par la route territoriale.',
        sections: [
          TransportSection(
            title: 'Vers Bastia (port / aeroport de Poretta)',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Ghisonaccia -> Bastia',
                description:
                    'Ligne de la plaine orientale via Aleria. Trajet ~1h30.',
                contact: '',
                contactLabel: 'Autocars de la plaine orientale',
              ),
            ],
          ),
          TransportSection(
            title: 'Vers Ajaccio',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Ghisonaccia -> Ajaccio',
                description:
                    'Liaison transversale via Vizzavona. Correspondance '
                    'possible. Trajet ~2h30.',
                contact: '',
                contactLabel: 'Autocars',
              ),
            ],
          ),
        ],
        advices: [
          'Verifiez les horaires de bus la veille au depart, surtout hors '
              'saison.',
          'Ghisonaccia dispose de commerces pour patienter avant votre '
              'liaison retour.',
        ],
      ),

      // --- Porticcio : REJOINDRE (aller, depart du sentier sens S->N) --------
      EndpointTransport(
        endpointName: 'Porticcio',
        role: TransportRole.arrival,
        intro:
            'Porticcio, sur le golfe d\'Ajaccio, est votre point de depart pour '
            'le Mare a Mare Centre en sens ouest -> est. La station est reliee '
            'a Ajaccio et a son aeroport.',
        sections: [
          TransportSection(
            title: 'Depuis l\'aeroport / le centre d\'Ajaccio',
            mode: TransportModeKind.bus,
            options: [
              TransportOption(
                mode: TransportModeKind.bus,
                title: 'Autocar Ajaccio -> Porticcio',
                description:
                    'Ligne du golfe (rive sud) depuis la gare routiere '
                    'd\'Ajaccio. Trajet ~40 min.',
                contact: '',
                contactLabel: 'Autocars du golfe',
              ),
              TransportOption(
                mode: TransportModeKind.ferry,
                title: 'Navette maritime Ajaccio -> Porticcio',
                description:
                    'Liaison saisonniere par bateau a travers le golfe '
                    '(~20 min).',
                contact: '',
                contactLabel: 'Navette maritime du golfe',
              ),
            ],
          ),
        ],
        advices: [
          'Faites votre ravitaillement a Porticcio ou Ajaccio avant le depart.',
          'La navette maritime depuis Ajaccio est une arrivee agreable a '
              'Porticcio en saison.',
        ],
      ),
    ],
  );
}
