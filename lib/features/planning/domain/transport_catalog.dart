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
/// HONNETETE DES DONNEES (regle Chris #99460) : quand une info precise n'est pas
/// disponible (horaire exact, tarif), on met une entree explicite « a completer »
/// plutot qu'un horaire faux. Les liens web et telephones sont ceux des
/// operateurs/offices connus quand ils existent ; sinon champ vide (l'UI masque).
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
                price: 'a completer',
                schedule: 'Horaires saisonniers a verifier aupres du '
                    'transporteur (a completer)',
                contact: '',
                contactLabel: 'Autocars de la plaine orientale',
              ),
              TransportOption(
                mode: TransportModeKind.taxi,
                title: 'Taxi depuis Bastia',
                description: 'Trajet direct sur reservation. Duree ~1h15.',
                price: 'a completer',
                schedule: 'Sur reservation',
                contact: '',
                contactLabel: 'Taxi (a completer)',
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
                price: 'a completer',
                schedule: 'Horaires saisonniers a verifier (a completer)',
                contact: '',
                contactLabel: 'Autocars (a completer)',
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
                price: 'a completer',
                schedule: 'Frequence renforcee en saison (a completer)',
                contact: '',
                contactLabel: 'Autocars du golfe (a completer)',
              ),
              TransportOption(
                mode: TransportModeKind.ferry,
                title: 'Navette maritime Porticcio -> Ajaccio',
                description:
                    'Liaison saisonniere par bateau a travers le golfe. '
                    'Alternative panoramique a la route. Duree ~20 min.',
                price: 'a completer',
                schedule: 'Service saisonnier (a completer)',
                contact: '',
                contactLabel: 'Navette maritime du golfe (a completer)',
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
                price: 'a completer',
                schedule: 'Sur reservation',
                contact: '',
                contactLabel: 'Taxi (a completer)',
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
                contactLabel: 'Port d\'Ajaccio (a completer)',
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
                price: 'a completer',
                schedule: 'Horaires saisonniers a verifier (a completer)',
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
                price: 'a completer',
                schedule: 'Horaires saisonniers a verifier (a completer)',
                contact: '',
                contactLabel: 'Autocars (a completer)',
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
                price: 'a completer',
                schedule: 'Frequence renforcee en saison (a completer)',
                contact: '',
                contactLabel: 'Autocars du golfe (a completer)',
              ),
              TransportOption(
                mode: TransportModeKind.ferry,
                title: 'Navette maritime Ajaccio -> Porticcio',
                description:
                    'Liaison saisonniere par bateau a travers le golfe '
                    '(~20 min).',
                price: 'a completer',
                schedule: 'Service saisonnier (a completer)',
                contact: '',
                contactLabel: 'Navette maritime du golfe (a completer)',
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
