///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsFr = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.fr,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <fr>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$map$fr map = Translations$map$fr.internal(_root);
	late final Translations$stage$fr stage = Translations$stage$fr.internal(_root);
	late final Translations$trail$fr trail = Translations$trail$fr.internal(_root);
	late final Translations$poi$fr poi = Translations$poi$fr.internal(_root);
	late final Translations$gps$fr gps = Translations$gps$fr.internal(_root);
	late final Translations$planning$fr planning = Translations$planning$fr.internal(_root);
	late final Translations$tracking$fr tracking = Translations$tracking$fr.internal(_root);
	late final Translations$checklist$fr checklist = Translations$checklist$fr.internal(_root);
	late final Translations$journal$fr journal = Translations$journal$fr.internal(_root);
	late final Translations$weather$fr weather = Translations$weather$fr.internal(_root);
	late final Translations$share$fr share = Translations$share$fr.internal(_root);
	late final Translations$diploma$fr diploma = Translations$diploma$fr.internal(_root);
	late final Translations$notifications$fr notifications = Translations$notifications$fr.internal(_root);
	late final Translations$settings$fr settings = Translations$settings$fr.internal(_root);
	late final Translations$feedback$fr feedback = Translations$feedback$fr.internal(_root);
	late final Translations$auth$fr auth = Translations$auth$fr.internal(_root);
	late final Translations$feasibility$fr feasibility = Translations$feasibility$fr.internal(_root);
}

// Path: map
class Translations$map$fr {
	Translations$map$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Carte du sentier'
	String get title => 'Carte du sentier';

	/// fr: 'Chargement du tracÃ©...'
	String get loading => 'Chargement du tracÃ©...';

	/// fr: 'Aucun tracÃ© disponible'
	String get noTrack => 'Aucun tracÃ© disponible';

	/// fr: 'Voir la carte'
	String get viewMap => 'Voir la carte';
}

// Path: stage
class Translations$stage$fr {
	Translations$stage$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Distance'
	String get distance => 'Distance';

	/// fr: 'DÃ©nivelÃ©'
	String get elevation => 'DÃ©nivelÃ©';

	/// fr: 'DÃ©nivelÃ© positif'
	String get elevationGain => 'DÃ©nivelÃ© positif';

	/// fr: 'DÃ©nivelÃ© nÃ©gatif'
	String get elevationLoss => 'DÃ©nivelÃ© nÃ©gatif';

	/// fr: 'DurÃ©e estimÃ©e'
	String get duration => 'DurÃ©e estimÃ©e';

	/// fr: 'Description'
	String get description => 'Description';

	/// fr: 'CoordonnÃ©es'
	String get coordinates => 'CoordonnÃ©es';

	/// fr: 'Points d'intÃ©rÃªt'
	String get pois => 'Points d\'intÃ©rÃªt';

	late final Translations$stage$difficulty$fr difficulty = Translations$stage$difficulty$fr.internal(_root);

	/// fr: '{distance} km restants'
	String get remaining => '{distance} km restants';

	/// fr: 'Vous etes arrive !'
	String get arrived => 'Vous etes arrive !';
}

// Path: trail
class Translations$trail$fr {
	Translations$trail$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Ãtapes'
	String get stages => 'Ãtapes';

	/// fr: 'Distance totale'
	String get totalDistance => 'Distance totale';

	/// fr: 'DÃ©nivelÃ© total'
	String get totalElevation => 'DÃ©nivelÃ© total';
}

// Path: poi
class Translations$poi$fr {
	Translations$poi$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Refuge'
	String get shelter => 'Refuge';

	/// fr: 'Point d'eau'
	String get water => 'Point d\'eau';

	/// fr: 'Point de vue'
	String get viewpoint => 'Point de vue';

	/// fr: 'Bivouac'
	String get campsite => 'Bivouac';

	/// fr: 'Restaurant'
	String get restaurant => 'Restaurant';

	/// fr: 'Urgence'
	String get emergency => 'Urgence';

	/// fr: 'Danger'
	String get danger => 'Danger';

	/// fr: 'Commerce'
	String get shop => 'Commerce';

	/// fr: 'Filtrer les points d'intÃ©rÃªt'
	String get filter => 'Filtrer les points d\'intÃ©rÃªt';

	/// fr: 'Altitude'
	String get altitude => 'Altitude';

	/// fr: 'Horaires'
	String get hours => 'Horaires';
}

// Path: gps
class Translations$gps$fr {
	Translations$gps$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Autorisation GPS requise'
	String get permission => 'Autorisation GPS requise';

	/// fr: 'Acces a la localisation refuse'
	String get denied => 'Acces a la localisation refuse';

	/// fr: 'Service de localisation desactive'
	String get disabled => 'Service de localisation desactive';

	/// fr: 'Hors trace'
	String get offTrack => 'Hors trace';

	/// fr: 'Centrer sur ma position'
	String get centerOnMe => 'Centrer sur ma position';
}

// Path: planning
class Translations$planning$fr {
	Translations$planning$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Planning'
	String get title => 'Planning';

	/// fr: 'Durée'
	String get duration => 'Durée';

	/// fr: 'jours'
	String get days => 'jours';

	/// fr: 'Jour'
	String get day => 'Jour';

	/// fr: 'Jour de repos'
	String get restDay => 'Jour de repos';

	/// fr: 'Distance totale'
	String get totalDistance => 'Distance totale';

	/// fr: 'Dénivelé total'
	String get totalElevation => 'Dénivelé total';

	/// fr: 'Durée estimée'
	String get estimatedTime => 'Durée estimée';

	/// fr: 'Étapes'
	String get stages => 'Étapes';

	/// fr: 'Planifier'
	String get plan => 'Planifier';
}

// Path: tracking
class Translations$tracking$fr {
	Translations$tracking$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Demarrer'
	String get start => 'Demarrer';

	/// fr: 'Pause'
	String get pause => 'Pause';

	/// fr: 'Reprendre'
	String get resume => 'Reprendre';

	/// fr: 'Arreter'
	String get stop => 'Arreter';

	/// fr: 'Distance'
	String get distance => 'Distance';

	/// fr: 'Denivele'
	String get elevation => 'Denivele';

	/// fr: 'Vitesse'
	String get speed => 'Vitesse';

	/// fr: 'Temps'
	String get time => 'Temps';

	/// fr: 'Arreter le tracking ?'
	String get confirmStop => 'Arreter le tracking ?';
}

// Path: checklist
class Translations$checklist$fr {
	Translations$checklist$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Checklist matériel'
	String get title => 'Checklist matériel';

	/// fr: 'Préparez votre sac à dos'
	String get subtitle => 'Préparez votre sac à dos';

	/// fr: '{checked}/{total} préparés'
	String get progress => '{checked}/{total} préparés';

	/// fr: 'Checklist complète !'
	String get complete => 'Checklist complète !';

	/// fr: 'Réinitialiser'
	String get reset => 'Réinitialiser';

	/// fr: 'Réinitialiser la checklist ?'
	String get resetConfirm => 'Réinitialiser la checklist ?';

	/// fr: 'Tous les éléments seront décochés.'
	String get resetDescription => 'Tous les éléments seront décochés.';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';

	/// fr: 'Confirmer'
	String get confirm => 'Confirmer';

	late final Translations$checklist$categories$fr categories = Translations$checklist$categories$fr.internal(_root);
	late final Translations$checklist$items$fr items = Translations$checklist$items$fr.internal(_root);

	/// fr: 'Essentiel'
	String get essential => 'Essentiel';
}

// Path: journal
class Translations$journal$fr {
	Translations$journal$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Journal de trek'
	String get title => 'Journal de trek';

	/// fr: 'Votre journal est vide'
	String get empty => 'Votre journal est vide';

	/// fr: 'Notez vos impressions et souvenirs de trek'
	String get emptySubtitle => 'Notez vos impressions et souvenirs de trek';

	/// fr: 'Nouvelle note'
	String get addNote => 'Nouvelle note';

	/// fr: 'Étape'
	String get stage => 'Étape';

	/// fr: 'Votre note'
	String get yourNote => 'Votre note';

	/// fr: 'Décrivez votre journée de trek...'
	String get placeholder => 'Décrivez votre journée de trek...';

	/// fr: 'Enregistrer'
	String get save => 'Enregistrer';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';

	/// fr: 'Supprimer'
	String get delete => 'Supprimer';

	/// fr: 'Limite de 3 photos par jour atteinte'
	String get photoLimit => 'Limite de 3 photos par jour atteinte';

	/// fr: 'Photo trop volumineuse (max 500 Ko)'
	String get photoTooBig => 'Photo trop volumineuse (max 500 Ko)';
}

// Path: weather
class Translations$weather$fr {
	Translations$weather$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Météo'
	String get title => 'Météo';

	/// fr: 'Chargement de la météo...'
	String get loading => 'Chargement de la météo...';

	/// fr: 'Pas de connexion. Données météo indisponibles.'
	String get offline => 'Pas de connexion. Données météo indisponibles.';

	/// fr: 'Impossible de charger la météo.'
	String get error => 'Impossible de charger la météo.';

	/// fr: 'Données en cache'
	String get cached => 'Données en cache';

	/// fr: 'alertes météo'
	String get alerts => 'alertes météo';

	/// fr: 'Actualiser'
	String get refresh => 'Actualiser';

	/// fr: 'Température'
	String get temperature => 'Température';

	/// fr: 'Précipitations'
	String get precipitation => 'Précipitations';

	/// fr: 'Vent'
	String get wind => 'Vent';

	/// fr: 'Indice UV'
	String get uv => 'Indice UV';
}

// Path: share
class Translations$share$fr {
	Translations$share$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Partager'
	String get title => 'Partager';

	/// fr: 'Génération...'
	String get generating => 'Génération...';

	/// fr: 'Partager'
	String get share => 'Partager';

	/// fr: 'Erreur lors de la génération'
	String get error => 'Erreur lors de la génération';
}

// Path: diploma
class Translations$diploma$fr {
	Translations$diploma$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Diplôme de trek'
	String get title => 'Diplôme de trek';

	/// fr: 'Votre nom'
	String get yourName => 'Votre nom';

	/// fr: 'Entrez votre nom...'
	String get namePlaceholder => 'Entrez votre nom...';

	/// fr: 'Générer le PDF'
	String get generatePdf => 'Générer le PDF';

	/// fr: 'Certifie que'
	String get certifies => 'Certifie que';

	/// fr: 'a parcouru le'
	String get completed => 'a parcouru le';
}

// Path: notifications
class Translations$notifications$fr {
	Translations$notifications$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Rappel du matin'
	String get morningReminder => 'Rappel du matin';

	/// fr: 'Alertes météo'
	String get weatherAlerts => 'Alertes météo';

	/// fr: 'Rappel J-2'
	String get countdown => 'Rappel J-2';

	/// fr: 'Notification 2 jours avant le départ'
	String get countdownDesc => 'Notification 2 jours avant le départ';
}

// Path: settings
class Translations$settings$fr {
	Translations$settings$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Paramètres'
	String get title => 'Paramètres';

	/// fr: 'Langue'
	String get language => 'Langue';

	/// fr: 'Unités'
	String get units => 'Unités';

	/// fr: 'Distance'
	String get distance => 'Distance';

	/// fr: 'Température'
	String get temperature => 'Température';

	/// fr: 'Thème'
	String get theme => 'Thème';

	/// fr: 'Sombre'
	String get dark => 'Sombre';

	/// fr: 'Clair'
	String get light => 'Clair';

	/// fr: 'Système'
	String get system => 'Système';

	/// fr: 'Cache'
	String get cache => 'Cache';

	/// fr: 'Cache activé'
	String get cacheEnabled => 'Cache activé';

	/// fr: 'Données disponibles hors ligne'
	String get cacheDesc => 'Données disponibles hors ligne';

	/// fr: 'Taille du cache'
	String get cacheSize => 'Taille du cache';

	/// fr: 'Notifications'
	String get notifications => 'Notifications';
}

// Path: feedback
class Translations$feedback$fr {
	Translations$feedback$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Feedback'
	String get title => 'Feedback';

	/// fr: 'Type de retour'
	String get type => 'Type de retour';

	/// fr: 'Bug / Problème'
	String get bug => 'Bug / Problème';

	/// fr: 'Suggestion'
	String get suggestion => 'Suggestion';

	/// fr: 'Question'
	String get question => 'Question';

	/// fr: 'Autre'
	String get other => 'Autre';

	/// fr: 'Votre message'
	String get message => 'Votre message';

	/// fr: 'Décrivez votre retour...'
	String get messagePlaceholder => 'Décrivez votre retour...';

	/// fr: 'Satisfaction'
	String get satisfaction => 'Satisfaction';

	/// fr: 'Envoyer'
	String get send => 'Envoyer';

	/// fr: 'Envoi...'
	String get sending => 'Envoi...';

	/// fr: 'Merci pour votre retour !'
	String get thanks => 'Merci pour votre retour !';

	/// fr: 'en attente'
	String get pending => 'en attente';
}

// Path: auth
class Translations$auth$fr {
	Translations$auth$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Profil'
	String get profile => 'Profil';

	/// fr: 'Randonneur anonyme'
	String get anonymous => 'Randonneur anonyme';

	/// fr: 'Connecté via'
	String get connectedVia => 'Connecté via';

	/// fr: 'Se connecter avec Google'
	String get signInGoogle => 'Se connecter avec Google';

	/// fr: 'Pour sauvegarder votre progression'
	String get signInGoogleDesc => 'Pour sauvegarder votre progression';

	/// fr: 'Se déconnecter'
	String get signOut => 'Se déconnecter';

	/// fr: 'Revenir en mode anonyme'
	String get signOutDesc => 'Revenir en mode anonyme';

	/// fr: 'Se déconnecter ?'
	String get signOutConfirm => 'Se déconnecter ?';

	/// fr: 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.'
	String get signOutMessage => 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.';

	/// fr: 'Supprimer mon compte'
	String get deleteAccount => 'Supprimer mon compte';

	/// fr: 'Toutes vos données seront effacées'
	String get deleteAccountDesc => 'Toutes vos données seront effacées';

	/// fr: 'Supprimer votre compte ?'
	String get deleteConfirm => 'Supprimer votre compte ?';

	/// fr: 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.'
	String get deleteMessage => 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';
}

// Path: feasibility
class Translations$feasibility$fr {
	Translations$feasibility$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Faisabilité'
	String get title => 'Faisabilité';

	/// fr: 'Évaluez votre préparation'
	String get subtitle => 'Évaluez votre préparation';

	/// fr: 'Précédent'
	String get previous => 'Précédent';

	/// fr: 'Recommencer'
	String get restart => 'Recommencer';

	/// fr: 'Votre résultat'
	String get resultTitle => 'Votre résultat';

	/// fr: 'Points à améliorer'
	String get weakPointsTitle => 'Points à améliorer';

	/// fr: 'Points forts'
	String get strongPointsTitle => 'Points forts';

	/// fr: '{current}/{total}'
	String get progress => '{current}/{total}';

	late final Translations$feasibility$levels$fr levels = Translations$feasibility$levels$fr.internal(_root);
	late final Translations$feasibility$categories$fr categories = Translations$feasibility$categories$fr.internal(_root);
	late final Translations$feasibility$questions$fr questions = Translations$feasibility$questions$fr.internal(_root);
	late final Translations$feasibility$answers$fr answers = Translations$feasibility$answers$fr.internal(_root);
}

// Path: stage.difficulty
class Translations$stage$difficulty$fr {
	Translations$stage$difficulty$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Facile'
	String get easy => 'Facile';

	/// fr: 'ModÃ©rÃ©'
	String get moderate => 'ModÃ©rÃ©';

	/// fr: 'Difficile'
	String get hard => 'Difficile';

	/// fr: 'Expert'
	String get expert => 'Expert';
}

// Path: checklist.categories
class Translations$checklist$categories$fr {
	Translations$checklist$categories$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Équipement'
	String get equipment => 'Équipement';

	/// fr: 'Vêtements'
	String get clothing => 'Vêtements';

	/// fr: 'Alimentation'
	String get food => 'Alimentation';

	/// fr: 'Sécurité'
	String get safety => 'Sécurité';

	/// fr: 'Documents'
	String get documents => 'Documents';

	/// fr: 'Hygiène'
	String get hygiene => 'Hygiène';
}

// Path: checklist.items
class Translations$checklist$items$fr {
	Translations$checklist$items$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Sac à dos'
	String get backpack => 'Sac à dos';

	/// fr: 'Sac de couchage'
	String get sleepingBag => 'Sac de couchage';

	/// fr: 'Matelas de sol'
	String get sleepingPad => 'Matelas de sol';

	/// fr: 'Bâtons de marche'
	String get hikingPoles => 'Bâtons de marche';

	/// fr: 'Lampe frontale'
	String get headlamp => 'Lampe frontale';

	/// fr: 'Gourde'
	String get waterBottle => 'Gourde';

	/// fr: 'Chaussures de randonnée'
	String get hikingBoots => 'Chaussures de randonnée';

	/// fr: 'Veste imperméable'
	String get rainJacket => 'Veste imperméable';

	/// fr: 'Couche chaude'
	String get warmLayer => 'Couche chaude';

	/// fr: 'Chaussettes de randonnée'
	String get hikingSocks => 'Chaussettes de randonnée';

	/// fr: 'Chapeau'
	String get hat => 'Chapeau';

	/// fr: 'Gants'
	String get gloves => 'Gants';

	/// fr: 'Encas de marche'
	String get trailSnacks => 'Encas de marche';

	/// fr: 'Barres énergétiques'
	String get energyBars => 'Barres énergétiques';

	/// fr: 'Purification d'eau'
	String get waterPurification => 'Purification d\'eau';

	/// fr: 'Trousse de secours'
	String get firstAidKit => 'Trousse de secours';

	/// fr: 'Sifflet'
	String get whistle => 'Sifflet';

	/// fr: 'Couverture de survie'
	String get emergencyBlanket => 'Couverture de survie';

	/// fr: 'Crème solaire'
	String get sunscreen => 'Crème solaire';

	/// fr: 'Pièce d'identité'
	String get idCard => 'Pièce d\'identité';

	/// fr: 'Assurance'
	String get insurance => 'Assurance';

	/// fr: 'Carte du sentier'
	String get trailMap => 'Carte du sentier';

	/// fr: 'Papier toilette'
	String get toiletPaper => 'Papier toilette';

	/// fr: 'Gel hydroalcoolique'
	String get handSanitizer => 'Gel hydroalcoolique';

	/// fr: 'Serviette'
	String get towel => 'Serviette';
}

// Path: feasibility.levels
class Translations$feasibility$levels$fr {
	Translations$feasibility$levels$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Déconseillé'
	String get danger => 'Déconseillé';

	/// fr: 'Préparation nécessaire'
	String get caution => 'Préparation nécessaire';

	/// fr: 'Faisable'
	String get good => 'Faisable';

	/// fr: 'Excellent'
	String get excellent => 'Excellent';
}

// Path: feasibility.categories
class Translations$feasibility$categories$fr {
	Translations$feasibility$categories$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Condition physique'
	String get fitness => 'Condition physique';

	/// fr: 'Expérience'
	String get experience => 'Expérience';

	/// fr: 'Équipement'
	String get gear => 'Équipement';

	/// fr: 'Météo'
	String get weather => 'Météo';

	/// fr: 'Durée'
	String get duration => 'Durée';

	/// fr: 'Accompagnement'
	String get companion => 'Accompagnement';

	/// fr: 'Santé'
	String get health => 'Santé';

	/// fr: 'Motivation'
	String get motivation => 'Motivation';
}

// Path: feasibility.questions
class Translations$feasibility$questions$fr {
	Translations$feasibility$questions$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Quel est votre niveau de condition physique ?'
	String get fitnessQuestion => 'Quel est votre niveau de condition physique ?';

	/// fr: 'Quelle est votre expérience en randonnée ?'
	String get experienceQuestion => 'Quelle est votre expérience en randonnée ?';

	/// fr: 'Quel est l’état de votre équipement ?'
	String get gearQuestion => 'Quel est l’état de votre équipement ?';

	/// fr: 'Avez-vous vérifié les conditions météo ?'
	String get weatherQuestion => 'Avez-vous vérifié les conditions météo ?';

	/// fr: 'Combien de jours prévoyez-vous ?'
	String get durationQuestion => 'Combien de jours prévoyez-vous ?';

	/// fr: 'Êtes-vous accompagné(e) ?'
	String get companionQuestion => 'Êtes-vous accompagné(e) ?';

	/// fr: 'Avez-vous des problèmes de santé ?'
	String get healthQuestion => 'Avez-vous des problèmes de santé ?';

	/// fr: 'Quel est votre niveau de motivation ?'
	String get motivationQuestion => 'Quel est votre niveau de motivation ?';
}

// Path: feasibility.answers
class Translations$feasibility$answers$fr {
	Translations$feasibility$answers$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Sédentaire, aucun entraînement'
	String get fitnessA => 'Sédentaire, aucun entraînement';

	/// fr: 'Activité physique occasionnelle'
	String get fitnessB => 'Activité physique occasionnelle';

	/// fr: 'Sport régulier (2-3x/semaine)'
	String get fitnessC => 'Sport régulier (2-3x/semaine)';

	/// fr: 'Sportif aguerri, entraîné spécifiquement'
	String get fitnessD => 'Sportif aguerri, entraîné spécifiquement';

	/// fr: 'Aucune expérience de randonnée'
	String get experienceA => 'Aucune expérience de randonnée';

	/// fr: 'Quelques randonnées à la journée'
	String get experienceB => 'Quelques randonnées à la journée';

	/// fr: 'Randonnées multi-jours déjà réalisées'
	String get experienceC => 'Randonnées multi-jours déjà réalisées';

	/// fr: 'Trekkeur expérimenté, GR déjà réalisés'
	String get experienceD => 'Trekkeur expérimenté, GR déjà réalisés';

	/// fr: 'Équipement incomplet ou inadapté'
	String get gearA => 'Équipement incomplet ou inadapté';

	/// fr: 'Équipement basique, quelques manques'
	String get gearB => 'Équipement basique, quelques manques';

	/// fr: 'Équipement complet, bon état'
	String get gearC => 'Équipement complet, bon état';

	/// fr: 'Équipement technique, rodé et testé'
	String get gearD => 'Équipement technique, rodé et testé';

	/// fr: 'Pas vérifié, aucune idée'
	String get weatherA => 'Pas vérifié, aucune idée';

	/// fr: 'Consulté vaguement, conditions incertaines'
	String get weatherB => 'Consulté vaguement, conditions incertaines';

	/// fr: 'Vérifié, conditions correctes prévues'
	String get weatherC => 'Vérifié, conditions correctes prévues';

	/// fr: 'Vérifié en détail, créneau favorable'
	String get weatherD => 'Vérifié en détail, créneau favorable';

	/// fr: 'Aucune idée de la durée'
	String get durationA => 'Aucune idée de la durée';

	/// fr: 'Durée sous-estimée ou trop ambitieuse'
	String get durationB => 'Durée sous-estimée ou trop ambitieuse';

	/// fr: 'Planning réaliste avec marges'
	String get durationC => 'Planning réaliste avec marges';

	/// fr: 'Planning détaillé, jours de repos prévus'
	String get durationD => 'Planning détaillé, jours de repos prévus';

	/// fr: 'Seul(e), sans expérience solo'
	String get companionA => 'Seul(e), sans expérience solo';

	/// fr: 'Seul(e), mais expérimenté(e)'
	String get companionB => 'Seul(e), mais expérimenté(e)';

	/// fr: 'En groupe, niveaux mixtes'
	String get companionC => 'En groupe, niveaux mixtes';

	/// fr: 'En groupe, tous expérimentés'
	String get companionD => 'En groupe, tous expérimentés';

	/// fr: 'Problèmes de santé non traités'
	String get healthA => 'Problèmes de santé non traités';

	/// fr: 'Problèmes mineurs, sous contrôle'
	String get healthB => 'Problèmes mineurs, sous contrôle';

	/// fr: 'Bonne santé générale'
	String get healthC => 'Bonne santé générale';

	/// fr: 'Excellent état de santé, bilan récent'
	String get healthD => 'Excellent état de santé, bilan récent';

	/// fr: 'Peu motivé(e), hésitant(e)'
	String get motivationA => 'Peu motivé(e), hésitant(e)';

	/// fr: 'Motivé(e) mais anxieux(se)'
	String get motivationB => 'Motivé(e) mais anxieux(se)';

	/// fr: 'Motivé(e) et déterminé(e)'
	String get motivationC => 'Motivé(e) et déterminé(e)';

	/// fr: 'Passion absolue, rêve de longue date'
	String get motivationD => 'Passion absolue, rêve de longue date';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'map.title' => 'Carte du sentier',
			'map.loading' => 'Chargement du tracÃ©...',
			'map.noTrack' => 'Aucun tracÃ© disponible',
			'map.viewMap' => 'Voir la carte',
			'stage.distance' => 'Distance',
			'stage.elevation' => 'DÃ©nivelÃ©',
			'stage.elevationGain' => 'DÃ©nivelÃ© positif',
			'stage.elevationLoss' => 'DÃ©nivelÃ© nÃ©gatif',
			'stage.duration' => 'DurÃ©e estimÃ©e',
			'stage.description' => 'Description',
			'stage.coordinates' => 'CoordonnÃ©es',
			'stage.pois' => 'Points d\'intÃ©rÃªt',
			'stage.difficulty.easy' => 'Facile',
			'stage.difficulty.moderate' => 'ModÃ©rÃ©',
			'stage.difficulty.hard' => 'Difficile',
			'stage.difficulty.expert' => 'Expert',
			'stage.remaining' => '{distance} km restants',
			'stage.arrived' => 'Vous etes arrive !',
			'trail.stages' => 'Ãtapes',
			'trail.totalDistance' => 'Distance totale',
			'trail.totalElevation' => 'DÃ©nivelÃ© total',
			'poi.shelter' => 'Refuge',
			'poi.water' => 'Point d\'eau',
			'poi.viewpoint' => 'Point de vue',
			'poi.campsite' => 'Bivouac',
			'poi.restaurant' => 'Restaurant',
			'poi.emergency' => 'Urgence',
			'poi.danger' => 'Danger',
			'poi.shop' => 'Commerce',
			'poi.filter' => 'Filtrer les points d\'intÃ©rÃªt',
			'poi.altitude' => 'Altitude',
			'poi.hours' => 'Horaires',
			'gps.permission' => 'Autorisation GPS requise',
			'gps.denied' => 'Acces a la localisation refuse',
			'gps.disabled' => 'Service de localisation desactive',
			'gps.offTrack' => 'Hors trace',
			'gps.centerOnMe' => 'Centrer sur ma position',
			'planning.title' => 'Planning',
			'planning.duration' => 'Durée',
			'planning.days' => 'jours',
			'planning.day' => 'Jour',
			'planning.restDay' => 'Jour de repos',
			'planning.totalDistance' => 'Distance totale',
			'planning.totalElevation' => 'Dénivelé total',
			'planning.estimatedTime' => 'Durée estimée',
			'planning.stages' => 'Étapes',
			'planning.plan' => 'Planifier',
			'tracking.start' => 'Demarrer',
			'tracking.pause' => 'Pause',
			'tracking.resume' => 'Reprendre',
			'tracking.stop' => 'Arreter',
			'tracking.distance' => 'Distance',
			'tracking.elevation' => 'Denivele',
			'tracking.speed' => 'Vitesse',
			'tracking.time' => 'Temps',
			'tracking.confirmStop' => 'Arreter le tracking ?',
			'checklist.title' => 'Checklist matériel',
			'checklist.subtitle' => 'Préparez votre sac à dos',
			'checklist.progress' => '{checked}/{total} préparés',
			'checklist.complete' => 'Checklist complète !',
			'checklist.reset' => 'Réinitialiser',
			'checklist.resetConfirm' => 'Réinitialiser la checklist ?',
			'checklist.resetDescription' => 'Tous les éléments seront décochés.',
			'checklist.cancel' => 'Annuler',
			'checklist.confirm' => 'Confirmer',
			'checklist.categories.equipment' => 'Équipement',
			'checklist.categories.clothing' => 'Vêtements',
			'checklist.categories.food' => 'Alimentation',
			'checklist.categories.safety' => 'Sécurité',
			'checklist.categories.documents' => 'Documents',
			'checklist.categories.hygiene' => 'Hygiène',
			'checklist.items.backpack' => 'Sac à dos',
			'checklist.items.sleepingBag' => 'Sac de couchage',
			'checklist.items.sleepingPad' => 'Matelas de sol',
			'checklist.items.hikingPoles' => 'Bâtons de marche',
			'checklist.items.headlamp' => 'Lampe frontale',
			'checklist.items.waterBottle' => 'Gourde',
			'checklist.items.hikingBoots' => 'Chaussures de randonnée',
			'checklist.items.rainJacket' => 'Veste imperméable',
			'checklist.items.warmLayer' => 'Couche chaude',
			'checklist.items.hikingSocks' => 'Chaussettes de randonnée',
			'checklist.items.hat' => 'Chapeau',
			'checklist.items.gloves' => 'Gants',
			'checklist.items.trailSnacks' => 'Encas de marche',
			'checklist.items.energyBars' => 'Barres énergétiques',
			'checklist.items.waterPurification' => 'Purification d\'eau',
			'checklist.items.firstAidKit' => 'Trousse de secours',
			'checklist.items.whistle' => 'Sifflet',
			'checklist.items.emergencyBlanket' => 'Couverture de survie',
			'checklist.items.sunscreen' => 'Crème solaire',
			'checklist.items.idCard' => 'Pièce d\'identité',
			'checklist.items.insurance' => 'Assurance',
			'checklist.items.trailMap' => 'Carte du sentier',
			'checklist.items.toiletPaper' => 'Papier toilette',
			'checklist.items.handSanitizer' => 'Gel hydroalcoolique',
			'checklist.items.towel' => 'Serviette',
			'checklist.essential' => 'Essentiel',
			'journal.title' => 'Journal de trek',
			'journal.empty' => 'Votre journal est vide',
			'journal.emptySubtitle' => 'Notez vos impressions et souvenirs de trek',
			'journal.addNote' => 'Nouvelle note',
			'journal.stage' => 'Étape',
			'journal.yourNote' => 'Votre note',
			'journal.placeholder' => 'Décrivez votre journée de trek...',
			'journal.save' => 'Enregistrer',
			'journal.cancel' => 'Annuler',
			'journal.delete' => 'Supprimer',
			'journal.photoLimit' => 'Limite de 3 photos par jour atteinte',
			'journal.photoTooBig' => 'Photo trop volumineuse (max 500 Ko)',
			'weather.title' => 'Météo',
			'weather.loading' => 'Chargement de la météo...',
			'weather.offline' => 'Pas de connexion. Données météo indisponibles.',
			'weather.error' => 'Impossible de charger la météo.',
			'weather.cached' => 'Données en cache',
			'weather.alerts' => 'alertes météo',
			'weather.refresh' => 'Actualiser',
			'weather.temperature' => 'Température',
			'weather.precipitation' => 'Précipitations',
			'weather.wind' => 'Vent',
			'weather.uv' => 'Indice UV',
			'share.title' => 'Partager',
			'share.generating' => 'Génération...',
			'share.share' => 'Partager',
			'share.error' => 'Erreur lors de la génération',
			'diploma.title' => 'Diplôme de trek',
			'diploma.yourName' => 'Votre nom',
			'diploma.namePlaceholder' => 'Entrez votre nom...',
			'diploma.generatePdf' => 'Générer le PDF',
			'diploma.certifies' => 'Certifie que',
			'diploma.completed' => 'a parcouru le',
			'notifications.morningReminder' => 'Rappel du matin',
			'notifications.weatherAlerts' => 'Alertes météo',
			'notifications.countdown' => 'Rappel J-2',
			'notifications.countdownDesc' => 'Notification 2 jours avant le départ',
			'settings.title' => 'Paramètres',
			'settings.language' => 'Langue',
			'settings.units' => 'Unités',
			'settings.distance' => 'Distance',
			'settings.temperature' => 'Température',
			'settings.theme' => 'Thème',
			'settings.dark' => 'Sombre',
			'settings.light' => 'Clair',
			'settings.system' => 'Système',
			'settings.cache' => 'Cache',
			'settings.cacheEnabled' => 'Cache activé',
			'settings.cacheDesc' => 'Données disponibles hors ligne',
			'settings.cacheSize' => 'Taille du cache',
			'settings.notifications' => 'Notifications',
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Type de retour',
			'feedback.bug' => 'Bug / Problème',
			'feedback.suggestion' => 'Suggestion',
			'feedback.question' => 'Question',
			'feedback.other' => 'Autre',
			'feedback.message' => 'Votre message',
			'feedback.messagePlaceholder' => 'Décrivez votre retour...',
			'feedback.satisfaction' => 'Satisfaction',
			'feedback.send' => 'Envoyer',
			'feedback.sending' => 'Envoi...',
			'feedback.thanks' => 'Merci pour votre retour !',
			'feedback.pending' => 'en attente',
			'auth.profile' => 'Profil',
			'auth.anonymous' => 'Randonneur anonyme',
			'auth.connectedVia' => 'Connecté via',
			'auth.signInGoogle' => 'Se connecter avec Google',
			'auth.signInGoogleDesc' => 'Pour sauvegarder votre progression',
			'auth.signOut' => 'Se déconnecter',
			'auth.signOutDesc' => 'Revenir en mode anonyme',
			'auth.signOutConfirm' => 'Se déconnecter ?',
			'auth.signOutMessage' => 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.',
			'auth.deleteAccount' => 'Supprimer mon compte',
			'auth.deleteAccountDesc' => 'Toutes vos données seront effacées',
			'auth.deleteConfirm' => 'Supprimer votre compte ?',
			'auth.deleteMessage' => 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.',
			'auth.cancel' => 'Annuler',
			'feasibility.title' => 'Faisabilité',
			'feasibility.subtitle' => 'Évaluez votre préparation',
			'feasibility.previous' => 'Précédent',
			'feasibility.restart' => 'Recommencer',
			'feasibility.resultTitle' => 'Votre résultat',
			'feasibility.weakPointsTitle' => 'Points à améliorer',
			'feasibility.strongPointsTitle' => 'Points forts',
			'feasibility.progress' => '{current}/{total}',
			'feasibility.levels.danger' => 'Déconseillé',
			'feasibility.levels.caution' => 'Préparation nécessaire',
			'feasibility.levels.good' => 'Faisable',
			'feasibility.levels.excellent' => 'Excellent',
			'feasibility.categories.fitness' => 'Condition physique',
			'feasibility.categories.experience' => 'Expérience',
			'feasibility.categories.gear' => 'Équipement',
			'feasibility.categories.weather' => 'Météo',
			'feasibility.categories.duration' => 'Durée',
			'feasibility.categories.companion' => 'Accompagnement',
			'feasibility.categories.health' => 'Santé',
			'feasibility.categories.motivation' => 'Motivation',
			'feasibility.questions.fitnessQuestion' => 'Quel est votre niveau de condition physique ?',
			'feasibility.questions.experienceQuestion' => 'Quelle est votre expérience en randonnée ?',
			'feasibility.questions.gearQuestion' => 'Quel est l’état de votre équipement ?',
			'feasibility.questions.weatherQuestion' => 'Avez-vous vérifié les conditions météo ?',
			'feasibility.questions.durationQuestion' => 'Combien de jours prévoyez-vous ?',
			'feasibility.questions.companionQuestion' => 'Êtes-vous accompagné(e) ?',
			'feasibility.questions.healthQuestion' => 'Avez-vous des problèmes de santé ?',
			'feasibility.questions.motivationQuestion' => 'Quel est votre niveau de motivation ?',
			'feasibility.answers.fitnessA' => 'Sédentaire, aucun entraînement',
			'feasibility.answers.fitnessB' => 'Activité physique occasionnelle',
			'feasibility.answers.fitnessC' => 'Sport régulier (2-3x/semaine)',
			'feasibility.answers.fitnessD' => 'Sportif aguerri, entraîné spécifiquement',
			'feasibility.answers.experienceA' => 'Aucune expérience de randonnée',
			'feasibility.answers.experienceB' => 'Quelques randonnées à la journée',
			'feasibility.answers.experienceC' => 'Randonnées multi-jours déjà réalisées',
			'feasibility.answers.experienceD' => 'Trekkeur expérimenté, GR déjà réalisés',
			'feasibility.answers.gearA' => 'Équipement incomplet ou inadapté',
			'feasibility.answers.gearB' => 'Équipement basique, quelques manques',
			'feasibility.answers.gearC' => 'Équipement complet, bon état',
			'feasibility.answers.gearD' => 'Équipement technique, rodé et testé',
			'feasibility.answers.weatherA' => 'Pas vérifié, aucune idée',
			'feasibility.answers.weatherB' => 'Consulté vaguement, conditions incertaines',
			'feasibility.answers.weatherC' => 'Vérifié, conditions correctes prévues',
			'feasibility.answers.weatherD' => 'Vérifié en détail, créneau favorable',
			'feasibility.answers.durationA' => 'Aucune idée de la durée',
			'feasibility.answers.durationB' => 'Durée sous-estimée ou trop ambitieuse',
			'feasibility.answers.durationC' => 'Planning réaliste avec marges',
			'feasibility.answers.durationD' => 'Planning détaillé, jours de repos prévus',
			'feasibility.answers.companionA' => 'Seul(e), sans expérience solo',
			'feasibility.answers.companionB' => 'Seul(e), mais expérimenté(e)',
			'feasibility.answers.companionC' => 'En groupe, niveaux mixtes',
			'feasibility.answers.companionD' => 'En groupe, tous expérimentés',
			'feasibility.answers.healthA' => 'Problèmes de santé non traités',
			'feasibility.answers.healthB' => 'Problèmes mineurs, sous contrôle',
			'feasibility.answers.healthC' => 'Bonne santé générale',
			'feasibility.answers.healthD' => 'Excellent état de santé, bilan récent',
			'feasibility.answers.motivationA' => 'Peu motivé(e), hésitant(e)',
			'feasibility.answers.motivationB' => 'Motivé(e) mais anxieux(se)',
			'feasibility.answers.motivationC' => 'Motivé(e) et déterminé(e)',
			'feasibility.answers.motivationD' => 'Passion absolue, rêve de longue date',
			_ => null,
		};
	}
}
