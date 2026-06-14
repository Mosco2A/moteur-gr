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
	late final Translations$a11y$fr a11y = Translations$a11y$fr.internal(_root);
	late final Translations$nav$fr nav = Translations$nav$fr.internal(_root);
	late final Translations$map$fr map = Translations$map$fr.internal(_root);
	late final Translations$stage$fr stage = Translations$stage$fr.internal(_root);
	late final Translations$trail$fr trail = Translations$trail$fr.internal(_root);
	late final Translations$poi$fr poi = Translations$poi$fr.internal(_root);
	late final Translations$accommodation$fr accommodation = Translations$accommodation$fr.internal(_root);
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
	late final Translations$tips$fr tips = Translations$tips$fr.internal(_root);
	late final Translations$goodies$fr goodies = Translations$goodies$fr.internal(_root);
	late final Translations$noData$fr noData = Translations$noData$fr.internal(_root);
	late final Translations$updates$fr updates = Translations$updates$fr.internal(_root);
	late final Translations$follow$fr follow = Translations$follow$fr.internal(_root);
	late final Translations$cloud$fr cloud = Translations$cloud$fr.internal(_root);
	late final Translations$onboarding$fr onboarding = Translations$onboarding$fr.internal(_root);
	late final Translations$monetization$fr monetization = Translations$monetization$fr.internal(_root);
	late final Translations$signalement$fr signalement = Translations$signalement$fr.internal(_root);
	late final Translations$hebergement$fr hebergement = Translations$hebergement$fr.internal(_root);
	late final Translations$training$fr training = Translations$training$fr.internal(_root);
	late final Translations$eta$fr eta = Translations$eta$fr.internal(_root);
	late final Translations$leaderboard$fr leaderboard = Translations$leaderboard$fr.internal(_root);
}

// Path: a11y
class Translations$a11y$fr {
	Translations$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Retour'
	String get back => 'Retour';

	/// fr: 'Zoomer'
	String get zoomIn => 'Zoomer';

	/// fr: 'Dezoomer'
	String get zoomOut => 'Dezoomer';

	/// fr: 'Centrer sur ma position'
	String get centerOnMe => 'Centrer sur ma position';

	/// fr: 'Carte du sentier'
	String get mapRegion => 'Carte du sentier';

	/// fr: 'Votre position'
	String get userPosition => 'Votre position';

	/// fr: 'Etape $number'
	String stageMarker({required Object number}) => 'Etape ${number}';

	/// fr: 'Point d'interet : $name'
	String poiMarker({required Object name}) => 'Point d\'interet : ${name}';

	/// fr: '$count points groupes'
	String markerCluster({required Object count}) => '${count} points groupes';

	/// fr: 'Sentier $name'
	String trailCard({required Object name}) => 'Sentier ${name}';

	/// fr: 'Demarrer le suivi'
	String get startTracking => 'Demarrer le suivi';

	/// fr: 'Mettre le suivi en pause'
	String get pauseTracking => 'Mettre le suivi en pause';

	/// fr: 'Reprendre le suivi'
	String get resumeTracking => 'Reprendre le suivi';

	/// fr: 'Arreter le suivi'
	String get stopTracking => 'Arreter le suivi';
}

// Path: nav
class Translations$nav$fr {
	Translations$nav$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Carte'
	String get map => 'Carte';

	/// fr: 'Étapes'
	String get stages => 'Étapes';

	/// fr: 'Planning'
	String get planning => 'Planning';

	/// fr: 'Journal'
	String get journal => 'Journal';

	/// fr: 'Plus'
	String get more => 'Plus';

	/// fr: 'Checklist matériel'
	String get checklist => 'Checklist matériel';

	/// fr: 'Faisabilité'
	String get feasibility => 'Faisabilité';

	/// fr: 'Conseils trek'
	String get tips => 'Conseils trek';

	/// fr: 'Contacts urgence'
	String get emergency => 'Contacts urgence';

	/// fr: 'Catalogue des sentiers'
	String get catalog => 'Catalogue des sentiers';

	/// fr: 'Profil'
	String get profile => 'Profil';

	/// fr: 'Paramètres'
	String get settings => 'Paramètres';
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

// Path: accommodation
class Translations$accommodation$fr {
	Translations$accommodation$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$accommodation$types$fr types = Translations$accommodation$types$fr.internal(_root);
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

	/// fr: 'Risque incendie'
	String get fireRisk => 'Risque incendie';

	/// fr: 'Risque incendie eleve. Consultez les consignes de securite.'
	String get fireRiskDesc => 'Risque incendie eleve. Consultez les consignes de securite.';

	/// fr: 'Consignes incendie'
	String get fireSafetyTips => 'Consignes incendie';

	/// fr: 'alerte'
	String get alertCount => 'alerte';

	/// fr: 'alertes'
	String get alertCountPlural => 'alertes';
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

	/// fr: 'Erreur lors du partage'
	String get errorShare => 'Erreur lors du partage';

	/// fr: 'Aperçu'
	String get preview => 'Aperçu';

	/// fr: 'Choisir un template'
	String get chooseTemplate => 'Choisir un template';

	/// fr: 'Statistiques'
	String get templateStats => 'Statistiques';

	/// fr: 'Parcours'
	String get templateJourney => 'Parcours';

	/// fr: 'Étape'
	String get templateStage => 'Étape';
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

	/// fr: 'DIPLÔME'
	String get pdfTitle => 'DIPLÔME';

	/// fr: 'Certificat d'accomplissement'
	String get pdfSubtitle => 'Certificat d\'accomplissement';

	/// fr: '{count} étapes'
	String get pdfStages => '{count} étapes';

	/// fr: '{km} km parcourus'
	String get pdfDistance => '{km} km parcourus';

	/// fr: '{meters} m de dénivelé positif'
	String get pdfElevation => '{meters} m de dénivelé positif';

	/// fr: 'en {days} jours'
	String get pdfDuration => 'en {days} jours';

	/// fr: 'Du'
	String get pdfFrom => 'Du';

	/// fr: 'au'
	String get pdfTo => 'au';

	/// fr: 'Délivré le {date}'
	String get pdfIssuedOn => 'Délivré le {date}';

	/// fr: 'Votre aventure'
	String get recapTitle => 'Votre aventure';

	/// fr: 'Photos du journal'
	String get recapJournalPhotos => 'Photos du journal';

	/// fr: 'Aucune photo dans le journal'
	String get recapNoPhotos => 'Aucune photo dans le journal';

	/// fr: 'Statistiques'
	String get recapStats => 'Statistiques';

	/// fr: '{count} etapes franchies'
	String get recapStages => '{count} etapes franchies';

	/// fr: '{km} km parcourus'
	String get recapDistance => '{km} km parcourus';

	/// fr: '{meters} m de denivele'
	String get recapElevation => '{meters} m de denivele';

	/// fr: '{days} jours de trek'
	String get recapDuration => '{days} jours de trek';

	/// fr: 'Trace du parcours'
	String get recapMapTrace => 'Trace du parcours';

	/// fr: 'Trace non disponible'
	String get recapNoMap => 'Trace non disponible';

	/// fr: '{count} notes de journal'
	String get recapJournalEntries => '{count} notes de journal';

	/// fr: 'Telecharger le diplome PDF'
	String get downloadPdf => 'Telecharger le diplome PDF';
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

	/// fr: 'Votre trek approche !'
	String get schedulerCountdownTitle => 'Votre trek approche !';

	/// fr: 'Depart dans 2 jours. Verifiez votre checklist et la meteo.'
	String get schedulerCountdownBody => 'Depart dans 2 jours. Verifiez votre checklist et la meteo.';

	/// fr: 'Bonne journee de trek !'
	String get schedulerDailyTitle => 'Bonne journee de trek !';

	/// fr: 'Consultez la meteo et preparez votre etape du jour.'
	String get schedulerDailyBody => 'Consultez la meteo et preparez votre etape du jour.';
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

	/// fr: 'Rappel du matin'
	String get morningReminder => 'Rappel du matin';

	/// fr: 'Alertes météo'
	String get weatherAlerts => 'Alertes météo';

	/// fr: 'Prévenu si conditions dangereuses'
	String get weatherAlertsDesc => 'Prévenu si conditions dangereuses';

	/// fr: 'Rappel J-2'
	String get countdownReminder => 'Rappel J-2';

	/// fr: 'Notification 2 jours avant le départ'
	String get countdownDesc => 'Notification 2 jours avant le départ';

	/// fr: 'Version'
	String get version => 'Version';

	/// fr: 'Version de l'application'
	String get versionLabel => 'Version de l\'application';
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

	/// fr: 'Compliment'
	String get compliment => 'Compliment';

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

	/// fr: 'Pseudonyme'
	String get pseudonym => 'Pseudonyme';

	/// fr: 'Votre nom de randonneur'
	String get pseudonymHint => 'Votre nom de randonneur';

	/// fr: 'Enregistrer'
	String get save => 'Enregistrer';

	/// fr: 'Changer l'avatar'
	String get changeAvatar => 'Changer l\'avatar';

	/// fr: 'Choisir un avatar'
	String get chooseAvatar => 'Choisir un avatar';

	/// fr: 'Erreur de chargement'
	String get errorLoading => 'Erreur de chargement';
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

	/// fr: 'Voir les recommandations'
	String get seeRecommendations => 'Voir les recommandations';

	/// fr: 'Votre profil'
	String get yourProfile => 'Votre profil';

	/// fr: 'Nos conseils'
	String get tipsTitle => 'Nos conseils';

	late final Translations$feasibility$recommendations$fr recommendations = Translations$feasibility$recommendations$fr.internal(_root);
}

// Path: tips
class Translations$tips$fr {
	Translations$tips$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Conseils trek'
	String get carouselTitle => 'Conseils trek';

	/// fr: 'Toutes'
	String get allCategories => 'Toutes';

	/// fr: 'Glissez pour voir plus'
	String get swipeHint => 'Glissez pour voir plus';

	/// fr: 'Détail du conseil'
	String get detailTitle => 'Détail du conseil';

	/// fr: 'Lire la suite'
	String get readMore => 'Lire la suite';

	/// fr: 'Aucun conseil disponible'
	String get noTips => 'Aucun conseil disponible';

	/// fr: 'Préparation'
	String get categoryPreparation => 'Préparation';

	/// fr: 'Équipement'
	String get categoryEquipment => 'Équipement';

	/// fr: 'Nutrition'
	String get categoryNutrition => 'Nutrition';

	/// fr: 'Sécurité'
	String get categorySafety => 'Sécurité';

	/// fr: 'Nature'
	String get categoryNature => 'Nature';

	/// fr: 'Récupération'
	String get categoryRecovery => 'Récupération';

	/// fr: 'Général'
	String get categoryGeneral => 'Général';

	/// fr: 'Priorité haute'
	String get priorityHigh => 'Priorité haute';

	/// fr: 'Sentier'
	String get scope => 'Sentier';

	/// fr: 'Saison'
	String get season => 'Saison';

	/// fr: 'Altitude min.'
	String get altitude => 'Altitude min.';
}

// Path: goodies
class Translations$goodies$fr {
	Translations$goodies$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Boutique Goodies'
	String get title => 'Boutique Goodies';

	/// fr: 'Ce module arrive bientot. Restez connecte !'
	String get comingSoon => 'Ce module arrive bientot. Restez connecte !';
}

// Path: noData
class Translations$noData$fr {
	Translations$noData$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Aucun sentier téléchargé'
	String get title => 'Aucun sentier téléchargé';

	/// fr: 'Téléchargez un sentier pour commencer'
	String get subtitle => 'Téléchargez un sentier pour commencer';

	/// fr: 'Les données seront disponibles hors ligne pour votre randonnée.'
	String get offlineHint => 'Les données seront disponibles hors ligne pour votre randonnée.';

	/// fr: 'Parcourir les sentiers'
	String get browseCta => 'Parcourir les sentiers';
}

// Path: updates
class Translations$updates$fr {
	Translations$updates$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mise à jour prête'
	String get readyTitle => 'Mise à jour prête';

	/// fr: 'Un sentier a été mis à jour.'
	String get readyBodyOne => 'Un sentier a été mis à jour.';

	/// fr: '$count sentiers ont été mis à jour.'
	String readyBodyMany({required Object count}) => '${count} sentiers ont été mis à jour.';
}

// Path: follow
class Translations$follow$fr {
	Translations$follow$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Suivi en direct'
	String get title => 'Suivi en direct';

	/// fr: 'Connexion…'
	String get connecting => 'Connexion…';

	/// fr: 'En direct'
	String get live => 'En direct';

	/// fr: 'Hors ligne'
	String get offline => 'Hors ligne';

	/// fr: 'Lien invalide'
	String get invalidLink => 'Lien invalide';

	/// fr: 'Ce lien de suivi n'existe pas ou a expiré.'
	String get invalidLinkHint => 'Ce lien de suivi n\'existe pas ou a expiré.';
}

// Path: cloud
class Translations$cloud$fr {
	Translations$cloud$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mode local'
	String get localModeTitle => 'Mode local';

	/// fr: 'Cette installation n'est pas reliée à un service cloud : suivi en temps réel, sauvegarde en ligne et compte sont désactivés. Vos données restent sur l'appareil.'
	String get localModeBody => 'Cette installation n\'est pas reliée à un service cloud : suivi en temps réel, sauvegarde en ligne et compte sont désactivés. Vos données restent sur l\'appareil.';

	/// fr: 'Cloud'
	String get statusSection => 'Cloud';

	/// fr: 'Services en ligne actifs'
	String get statusActive => 'Services en ligne actifs';

	/// fr: 'Sauvegarde et suivi en temps réel disponibles.'
	String get statusActiveDesc => 'Sauvegarde et suivi en temps réel disponibles.';

	/// fr: 'Mode local (sans cloud)'
	String get statusLocal => 'Mode local (sans cloud)';

	/// fr: 'Aucune donnée n'est envoyée en ligne. Configuration cloud absente.'
	String get statusLocalDesc => 'Aucune donnée n\'est envoyée en ligne. Configuration cloud absente.';
}

// Path: onboarding
class Translations$onboarding$fr {
	Translations$onboarding$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Passer'
	String get skip => 'Passer';

	/// fr: 'Suivant'
	String get next => 'Suivant';

	/// fr: 'Commencer'
	String get getStarted => 'Commencer';

	/// fr: 'Bienvenue sur $appName'
	String welcomeTitle({required Object appName}) => 'Bienvenue sur ${appName}';

	/// fr: 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de trek.'
	String get welcomeSubtitle => 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de trek.';

	/// fr: 'Choisissez votre langue'
	String get languageTitle => 'Choisissez votre langue';

	/// fr: 'Vous pourrez la modifier à tout moment dans les paramètres.'
	String get languageSubtitle => 'Vous pourrez la modifier à tout moment dans les paramètres.';

	/// fr: 'Téléchargez votre premier sentier'
	String get downloadTitle => 'Téléchargez votre premier sentier';

	/// fr: 'Parcourez le catalogue et téléchargez un sentier pour l'utiliser entièrement hors ligne.'
	String get downloadSubtitle => 'Parcourez le catalogue et téléchargez un sentier pour l\'utiliser entièrement hors ligne.';

	/// fr: 'Parcourir le catalogue'
	String get browseCatalog => 'Parcourir le catalogue';
}

// Path: monetization
class Translations$monetization$fr {
	Translations$monetization$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mode démo — touchez pour débloquer'
	String get demoBanner => 'Mode démo — touchez pour débloquer';

	/// fr: 'Débloquez ce trek'
	String get paywallTitle => 'Débloquez ce trek';

	/// fr: 'Le mode gratuit permet de préparer votre trek avec publicité. Le premium débloque tout, sans pub.'
	String get paywallBody => 'Le mode gratuit permet de préparer votre trek avec publicité. Le premium débloque tout, sans pub.';

	/// fr: 'Carte hors ligne + GPS + suivi en direct'
	String get featureMap => 'Carte hors ligne + GPS + suivi en direct';

	/// fr: 'Journal de bord complet'
	String get featureJournal => 'Journal de bord complet';

	/// fr: 'Diplôme de fin de trek'
	String get featureDiploma => 'Diplôme de fin de trek';

	/// fr: '2 suiveurs gratuits'
	String get featureFollowers => '2 suiveurs gratuits';

	/// fr: 'Zéro publicité'
	String get featureNoAds => 'Zéro publicité';

	/// fr: 'Débloquer ce trek'
	String get buyCta => 'Débloquer ce trek';

	/// fr: 'Débloquer ce trek — $price €'
	String buyCtaWithPrice({required Object price}) => 'Débloquer ce trek — ${price} €';
}

// Path: signalement
class Translations$signalement$fr {
	Translations$signalement$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Signaler'
	String get title => 'Signaler';

	/// fr: 'Que voulez-vous signaler ?'
	String get chooseType => 'Que voulez-vous signaler ?';

	late final Translations$signalement$types$fr types = Translations$signalement$types$fr.internal(_root);

	/// fr: 'Enregistré. Visible par les autres randonneurs après synchronisation réseau.'
	String get latencyBanner => 'Enregistré. Visible par les autres randonneurs après synchronisation réseau.';

	/// fr: 'Confirmer le signalement'
	String get confirm => 'Confirmer le signalement';

	/// fr: 'Position GPS indisponible pour le moment. Réessayez sous le ciel ouvert.'
	String get noLocation => 'Position GPS indisponible pour le moment. Réessayez sous le ciel ouvert.';

	/// fr: 'Signalement enregistré'
	String get savedTitle => 'Signalement enregistré';

	/// fr: 'Il sera partagé dès le retour du réseau.'
	String get savedPendingSync => 'Il sera partagé dès le retour du réseau.';

	/// fr: '$n en attente de synchronisation'
	String pendingCount({required Object n}) => '${n} en attente de synchronisation';

	/// fr: 'Fermer'
	String get close => 'Fermer';
}

// Path: hebergement
class Translations$hebergement$fr {
	Translations$hebergement$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Hébergements à proximité'
	String get title => 'Hébergements à proximité';

	/// fr: 'StepWays vous oriente vers les hébergeurs. La réservation se fait sur leur site : aucun paiement dans l'application.'
	String get facilitatorNote => 'StepWays vous oriente vers les hébergeurs. La réservation se fait sur leur site : aucun paiement dans l\'application.';

	/// fr: 'Détour aller-retour : $km km'
	String detourAR({required Object km}) => 'Détour aller-retour : ${km} km';

	/// fr: 'Voir le site'
	String get openSite => 'Voir le site';

	/// fr: 'Impossible d'ouvrir ce lien sur cet appareil.'
	String get cannotOpen => 'Impossible d\'ouvrir ce lien sur cet appareil.';

	/// fr: 'Aucun hébergement répertorié à proximité pour le moment.'
	String get empty => 'Aucun hébergement répertorié à proximité pour le moment.';

	late final Translations$hebergement$types$fr types = Translations$hebergement$types$fr.internal(_root);
}

// Path: training
class Translations$training$fr {
	Translations$training$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation physique'
	String get title => 'Préparation physique';

	/// fr: 'Votre programme est calculé et conservé sur votre téléphone. Les rappels sont des notifications locales, sans suivi.'
	String get localNotice => 'Votre programme est calculé et conservé sur votre téléphone. Les rappels sont des notifications locales, sans suivi.';

	/// fr: 'Séance d'entraînement aujourd'hui'
	String get reminderTitle => 'Séance d\'entraînement aujourd\'hui';

	/// fr: 'Programmer les rappels'
	String get scheduleReminders => 'Programmer les rappels';

	/// fr: '$n rappel(s) programmé(s)'
	String remindersScheduled({required Object n}) => '${n} rappel(s) programmé(s)';

	/// fr: 'Semaine $n'
	String week({required Object n}) => 'Semaine ${n}';

	/// fr: '$n min'
	String minutes({required Object n}) => '${n} min';

	/// fr: '$done/$total séances faites'
	String progress({required Object done, required Object total}) => '${done}/${total} séances faites';

	late final Translations$training$types$fr types = Translations$training$types$fr.internal(_root);
	late final Translations$training$intensity$fr intensity = Translations$training$intensity$fr.internal(_root);
}

// Path: eta
class Translations$eta$fr {
	Translations$eta$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Temps estimé'
	String get title => 'Temps estimé';

	/// fr: 'Prochain point'
	String get toNextWaypoint => 'Prochain point';

	/// fr: 'Fin d'étape'
	String get toStageEnd => 'Fin d\'étape';

	/// fr: 'Estimation fiable'
	String get confidenceHigh => 'Estimation fiable';

	/// fr: 'Approximatif (GPS faible)'
	String get confidenceLow => 'Approximatif (GPS faible)';

	/// fr: '$h h $m min'
	String durationHm({required Object h, required Object m}) => '${h} h ${m} min';

	/// fr: '$m min'
	String durationM({required Object m}) => '${m} min';
}

// Path: leaderboard
class Translations$leaderboard$fr {
	Translations$leaderboard$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Roi de l'étape'
	String get title => 'Roi de l\'étape';

	/// fr: 'Classement indisponible pour le moment.'
	String get unavailable => 'Classement indisponible pour le moment.';

	/// fr: 'Aucun classement pour ce segment. Sois le premier à le parcourir !'
	String get empty => 'Aucun classement pour ce segment. Sois le premier à le parcourir !';

	/// fr: 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n'est affichée.'
	String get pseudonymNotice => 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n\'est affichée.';

	/// fr: 'Tranche : $tranche'
	String trancheLabel({required Object tranche}) => 'Tranche : ${tranche}';

	/// fr: 'Pas assez de participants pour publier ce classement.'
	String get notEnoughParticipants => 'Pas assez de participants pour publier ce classement.';

	/// fr: 'Rang $rank, $pseudonym, temps $time'
	String entrySemantics({required Object rank, required Object pseudonym, required Object time}) => 'Rang ${rank}, ${pseudonym}, temps ${time}';
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

// Path: accommodation.types
class Translations$accommodation$types$fr {
	Translations$accommodation$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Refuge'
	String get refuge => 'Refuge';

	/// fr: 'Bergerie'
	String get bergerie => 'Bergerie';

	/// fr: 'Gîte'
	String get gite => 'Gîte';

	/// fr: 'Hôtel'
	String get hotel => 'Hôtel';

	/// fr: 'Camping'
	String get camping => 'Camping';

	/// fr: 'Bivouac'
	String get bivouac => 'Bivouac';
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

// Path: feasibility.recommendations
class Translations$feasibility$recommendations$fr {
	Translations$feasibility$recommendations$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$feasibility$recommendations$danger$fr danger = Translations$feasibility$recommendations$danger$fr.internal(_root);
	late final Translations$feasibility$recommendations$caution$fr caution = Translations$feasibility$recommendations$caution$fr.internal(_root);
	late final Translations$feasibility$recommendations$good$fr good = Translations$feasibility$recommendations$good$fr.internal(_root);
	late final Translations$feasibility$recommendations$excellent$fr excellent = Translations$feasibility$recommendations$excellent$fr.internal(_root);
}

// Path: signalement.types
class Translations$signalement$types$fr {
	Translations$signalement$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Obstacle sur le sentier'
	String get obstacle => 'Obstacle sur le sentier';

	/// fr: 'Point d'eau à sec'
	String get eauASec => 'Point d\'eau à sec';

	/// fr: 'Danger'
	String get danger => 'Danger';
}

// Path: hebergement.types
class Translations$hebergement$types$fr {
	Translations$hebergement$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Refuge'
	String get refuge => 'Refuge';

	/// fr: 'Gîte'
	String get gite => 'Gîte';

	/// fr: 'Hôtel'
	String get hotel => 'Hôtel';

	/// fr: 'Camping'
	String get camping => 'Camping';

	/// fr: 'Chambre d'hôte'
	String get chambreHote => 'Chambre d\'hôte';
}

// Path: training.types
class Translations$training$types$fr {
	Translations$training$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Marche'
	String get marche => 'Marche';

	/// fr: 'Cardio'
	String get cardio => 'Cardio';

	/// fr: 'Renforcement'
	String get renforcement => 'Renforcement';
}

// Path: training.intensity
class Translations$training$intensity$fr {
	Translations$training$intensity$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Faible'
	String get faible => 'Faible';

	/// fr: 'Modérée'
	String get moderee => 'Modérée';

	/// fr: 'Élevée'
	String get elevee => 'Élevée';
}

// Path: feasibility.recommendations.danger
class Translations$feasibility$recommendations$danger$fr {
	Translations$feasibility$recommendations$danger$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation insuffisante'
	String get title => 'Préparation insuffisante';

	/// fr: 'Votre profil indique des lacunes importantes. Nous vous déconseillons de partir en l’état.'
	String get summary => 'Votre profil indique des lacunes importantes. Nous vous déconseillons de partir en l’état.';

	late final Translations$feasibility$recommendations$danger$tips$fr tips = Translations$feasibility$recommendations$danger$tips$fr.internal(_root);
}

// Path: feasibility.recommendations.caution
class Translations$feasibility$recommendations$caution$fr {
	Translations$feasibility$recommendations$caution$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation à renforcer'
	String get title => 'Préparation à renforcer';

	/// fr: 'Vous avez des bases, mais certains points méritent une attention particulière.'
	String get summary => 'Vous avez des bases, mais certains points méritent une attention particulière.';

	late final Translations$feasibility$recommendations$caution$tips$fr tips = Translations$feasibility$recommendations$caution$tips$fr.internal(_root);
}

// Path: feasibility.recommendations.good
class Translations$feasibility$recommendations$good$fr {
	Translations$feasibility$recommendations$good$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Bonne préparation'
	String get title => 'Bonne préparation';

	/// fr: 'Votre profil est solide. Quelques ajustements et vous serez prêt(e).'
	String get summary => 'Votre profil est solide. Quelques ajustements et vous serez prêt(e).';

	late final Translations$feasibility$recommendations$good$tips$fr tips = Translations$feasibility$recommendations$good$tips$fr.internal(_root);
}

// Path: feasibility.recommendations.excellent
class Translations$feasibility$recommendations$excellent$fr {
	Translations$feasibility$recommendations$excellent$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation optimale'
	String get title => 'Préparation optimale';

	/// fr: 'Vous êtes parfaitement préparé(e). Profitez du trek !'
	String get summary => 'Vous êtes parfaitement préparé(e). Profitez du trek !';

	late final Translations$feasibility$recommendations$excellent$tips$fr tips = Translations$feasibility$recommendations$excellent$tips$fr.internal(_root);
}

// Path: feasibility.recommendations.danger.tips
class Translations$feasibility$recommendations$danger$tips$fr {
	Translations$feasibility$recommendations$danger$tips$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Commencez par des randonnées courtes pour évaluer votre condition'
	String get tip1 => 'Commencez par des randonnées courtes pour évaluer votre condition';

	/// fr: 'Consultez un professionnel de santé avant un effort prolongé'
	String get tip2 => 'Consultez un professionnel de santé avant un effort prolongé';

	/// fr: 'Investissez dans un équipement adapté et testez-le'
	String get tip3 => 'Investissez dans un équipement adapté et testez-le';
}

// Path: feasibility.recommendations.caution.tips
class Translations$feasibility$recommendations$caution$tips$fr {
	Translations$feasibility$recommendations$caution$tips$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Renforcez votre entraînement physique 6 à 8 semaines avant'
	String get tip1 => 'Renforcez votre entraînement physique 6 à 8 semaines avant';

	/// fr: 'Vérifiez et complétez votre équipement'
	String get tip2 => 'Vérifiez et complétez votre équipement';

	/// fr: 'Planifiez des étapes adaptées à votre niveau'
	String get tip3 => 'Planifiez des étapes adaptées à votre niveau';
}

// Path: feasibility.recommendations.good.tips
class Translations$feasibility$recommendations$good$tips$fr {
	Translations$feasibility$recommendations$good$tips$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Maintenez votre rythme d’entraînement'
	String get tip1 => 'Maintenez votre rythme d’entraînement';

	/// fr: 'Prévoyez des marges dans votre planning'
	String get tip2 => 'Prévoyez des marges dans votre planning';

	/// fr: 'Consultez la météo régulièrement'
	String get tip3 => 'Consultez la météo régulièrement';
}

// Path: feasibility.recommendations.excellent.tips
class Translations$feasibility$recommendations$excellent$tips$fr {
	Translations$feasibility$recommendations$excellent$tips$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Restez à l’écoute de votre corps'
	String get tip1 => 'Restez à l’écoute de votre corps';

	/// fr: 'Partagez votre expérience avec les randonneurs'
	String get tip2 => 'Partagez votre expérience avec les randonneurs';

	/// fr: 'Documentez votre aventure dans le journal'
	String get tip3 => 'Documentez votre aventure dans le journal';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'a11y.back' => 'Retour',
			'a11y.zoomIn' => 'Zoomer',
			'a11y.zoomOut' => 'Dezoomer',
			'a11y.centerOnMe' => 'Centrer sur ma position',
			'a11y.mapRegion' => 'Carte du sentier',
			'a11y.userPosition' => 'Votre position',
			'a11y.stageMarker' => ({required Object number}) => 'Etape ${number}',
			'a11y.poiMarker' => ({required Object name}) => 'Point d\'interet : ${name}',
			'a11y.markerCluster' => ({required Object count}) => '${count} points groupes',
			'a11y.trailCard' => ({required Object name}) => 'Sentier ${name}',
			'a11y.startTracking' => 'Demarrer le suivi',
			'a11y.pauseTracking' => 'Mettre le suivi en pause',
			'a11y.resumeTracking' => 'Reprendre le suivi',
			'a11y.stopTracking' => 'Arreter le suivi',
			'nav.map' => 'Carte',
			'nav.stages' => 'Étapes',
			'nav.planning' => 'Planning',
			'nav.journal' => 'Journal',
			'nav.more' => 'Plus',
			'nav.checklist' => 'Checklist matériel',
			'nav.feasibility' => 'Faisabilité',
			'nav.tips' => 'Conseils trek',
			'nav.emergency' => 'Contacts urgence',
			'nav.catalog' => 'Catalogue des sentiers',
			'nav.profile' => 'Profil',
			'nav.settings' => 'Paramètres',
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
			'accommodation.types.refuge' => 'Refuge',
			'accommodation.types.bergerie' => 'Bergerie',
			'accommodation.types.gite' => 'Gîte',
			'accommodation.types.hotel' => 'Hôtel',
			'accommodation.types.camping' => 'Camping',
			'accommodation.types.bivouac' => 'Bivouac',
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
			'weather.fireRisk' => 'Risque incendie',
			'weather.fireRiskDesc' => 'Risque incendie eleve. Consultez les consignes de securite.',
			'weather.fireSafetyTips' => 'Consignes incendie',
			'weather.alertCount' => 'alerte',
			'weather.alertCountPlural' => 'alertes',
			'share.title' => 'Partager',
			'share.generating' => 'Génération...',
			'share.share' => 'Partager',
			'share.error' => 'Erreur lors de la génération',
			'share.errorShare' => 'Erreur lors du partage',
			'share.preview' => 'Aperçu',
			'share.chooseTemplate' => 'Choisir un template',
			'share.templateStats' => 'Statistiques',
			'share.templateJourney' => 'Parcours',
			'share.templateStage' => 'Étape',
			'diploma.title' => 'Diplôme de trek',
			'diploma.yourName' => 'Votre nom',
			'diploma.namePlaceholder' => 'Entrez votre nom...',
			'diploma.generatePdf' => 'Générer le PDF',
			'diploma.certifies' => 'Certifie que',
			'diploma.completed' => 'a parcouru le',
			'diploma.pdfTitle' => 'DIPLÔME',
			'diploma.pdfSubtitle' => 'Certificat d\'accomplissement',
			'diploma.pdfStages' => '{count} étapes',
			'diploma.pdfDistance' => '{km} km parcourus',
			'diploma.pdfElevation' => '{meters} m de dénivelé positif',
			'diploma.pdfDuration' => 'en {days} jours',
			'diploma.pdfFrom' => 'Du',
			'diploma.pdfTo' => 'au',
			'diploma.pdfIssuedOn' => 'Délivré le {date}',
			'diploma.recapTitle' => 'Votre aventure',
			'diploma.recapJournalPhotos' => 'Photos du journal',
			'diploma.recapNoPhotos' => 'Aucune photo dans le journal',
			'diploma.recapStats' => 'Statistiques',
			'diploma.recapStages' => '{count} etapes franchies',
			'diploma.recapDistance' => '{km} km parcourus',
			'diploma.recapElevation' => '{meters} m de denivele',
			'diploma.recapDuration' => '{days} jours de trek',
			'diploma.recapMapTrace' => 'Trace du parcours',
			'diploma.recapNoMap' => 'Trace non disponible',
			'diploma.recapJournalEntries' => '{count} notes de journal',
			'diploma.downloadPdf' => 'Telecharger le diplome PDF',
			'notifications.morningReminder' => 'Rappel du matin',
			'notifications.weatherAlerts' => 'Alertes météo',
			'notifications.countdown' => 'Rappel J-2',
			'notifications.countdownDesc' => 'Notification 2 jours avant le départ',
			'notifications.schedulerCountdownTitle' => 'Votre trek approche !',
			'notifications.schedulerCountdownBody' => 'Depart dans 2 jours. Verifiez votre checklist et la meteo.',
			'notifications.schedulerDailyTitle' => 'Bonne journee de trek !',
			'notifications.schedulerDailyBody' => 'Consultez la meteo et preparez votre etape du jour.',
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
			'settings.morningReminder' => 'Rappel du matin',
			'settings.weatherAlerts' => 'Alertes météo',
			'settings.weatherAlertsDesc' => 'Prévenu si conditions dangereuses',
			'settings.countdownReminder' => 'Rappel J-2',
			'settings.countdownDesc' => 'Notification 2 jours avant le départ',
			'settings.version' => 'Version',
			'settings.versionLabel' => 'Version de l\'application',
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Type de retour',
			'feedback.bug' => 'Bug / Problème',
			'feedback.suggestion' => 'Suggestion',
			'feedback.compliment' => 'Compliment',
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
			'auth.pseudonym' => 'Pseudonyme',
			'auth.pseudonymHint' => 'Votre nom de randonneur',
			'auth.save' => 'Enregistrer',
			'auth.changeAvatar' => 'Changer l\'avatar',
			'auth.chooseAvatar' => 'Choisir un avatar',
			'auth.errorLoading' => 'Erreur de chargement',
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
			'feasibility.seeRecommendations' => 'Voir les recommandations',
			'feasibility.yourProfile' => 'Votre profil',
			'feasibility.tipsTitle' => 'Nos conseils',
			'feasibility.recommendations.danger.title' => 'Préparation insuffisante',
			'feasibility.recommendations.danger.summary' => 'Votre profil indique des lacunes importantes. Nous vous déconseillons de partir en l’état.',
			'feasibility.recommendations.danger.tips.tip1' => 'Commencez par des randonnées courtes pour évaluer votre condition',
			'feasibility.recommendations.danger.tips.tip2' => 'Consultez un professionnel de santé avant un effort prolongé',
			'feasibility.recommendations.danger.tips.tip3' => 'Investissez dans un équipement adapté et testez-le',
			'feasibility.recommendations.caution.title' => 'Préparation à renforcer',
			'feasibility.recommendations.caution.summary' => 'Vous avez des bases, mais certains points méritent une attention particulière.',
			'feasibility.recommendations.caution.tips.tip1' => 'Renforcez votre entraînement physique 6 à 8 semaines avant',
			'feasibility.recommendations.caution.tips.tip2' => 'Vérifiez et complétez votre équipement',
			'feasibility.recommendations.caution.tips.tip3' => 'Planifiez des étapes adaptées à votre niveau',
			'feasibility.recommendations.good.title' => 'Bonne préparation',
			'feasibility.recommendations.good.summary' => 'Votre profil est solide. Quelques ajustements et vous serez prêt(e).',
			'feasibility.recommendations.good.tips.tip1' => 'Maintenez votre rythme d’entraînement',
			'feasibility.recommendations.good.tips.tip2' => 'Prévoyez des marges dans votre planning',
			'feasibility.recommendations.good.tips.tip3' => 'Consultez la météo régulièrement',
			'feasibility.recommendations.excellent.title' => 'Préparation optimale',
			'feasibility.recommendations.excellent.summary' => 'Vous êtes parfaitement préparé(e). Profitez du trek !',
			'feasibility.recommendations.excellent.tips.tip1' => 'Restez à l’écoute de votre corps',
			'feasibility.recommendations.excellent.tips.tip2' => 'Partagez votre expérience avec les randonneurs',
			'feasibility.recommendations.excellent.tips.tip3' => 'Documentez votre aventure dans le journal',
			'tips.carouselTitle' => 'Conseils trek',
			'tips.allCategories' => 'Toutes',
			'tips.swipeHint' => 'Glissez pour voir plus',
			'tips.detailTitle' => 'Détail du conseil',
			'tips.readMore' => 'Lire la suite',
			'tips.noTips' => 'Aucun conseil disponible',
			'tips.categoryPreparation' => 'Préparation',
			'tips.categoryEquipment' => 'Équipement',
			'tips.categoryNutrition' => 'Nutrition',
			'tips.categorySafety' => 'Sécurité',
			'tips.categoryNature' => 'Nature',
			'tips.categoryRecovery' => 'Récupération',
			'tips.categoryGeneral' => 'Général',
			'tips.priorityHigh' => 'Priorité haute',
			'tips.scope' => 'Sentier',
			'tips.season' => 'Saison',
			'tips.altitude' => 'Altitude min.',
			'goodies.title' => 'Boutique Goodies',
			'goodies.comingSoon' => 'Ce module arrive bientot. Restez connecte !',
			'noData.title' => 'Aucun sentier téléchargé',
			'noData.subtitle' => 'Téléchargez un sentier pour commencer',
			'noData.offlineHint' => 'Les données seront disponibles hors ligne pour votre randonnée.',
			'noData.browseCta' => 'Parcourir les sentiers',
			'updates.readyTitle' => 'Mise à jour prête',
			'updates.readyBodyOne' => 'Un sentier a été mis à jour.',
			'updates.readyBodyMany' => ({required Object count}) => '${count} sentiers ont été mis à jour.',
			'follow.title' => 'Suivi en direct',
			'follow.connecting' => 'Connexion…',
			'follow.live' => 'En direct',
			'follow.offline' => 'Hors ligne',
			'follow.invalidLink' => 'Lien invalide',
			'follow.invalidLinkHint' => 'Ce lien de suivi n\'existe pas ou a expiré.',
			'cloud.localModeTitle' => 'Mode local',
			'cloud.localModeBody' => 'Cette installation n\'est pas reliée à un service cloud : suivi en temps réel, sauvegarde en ligne et compte sont désactivés. Vos données restent sur l\'appareil.',
			'cloud.statusSection' => 'Cloud',
			'cloud.statusActive' => 'Services en ligne actifs',
			'cloud.statusActiveDesc' => 'Sauvegarde et suivi en temps réel disponibles.',
			'cloud.statusLocal' => 'Mode local (sans cloud)',
			'cloud.statusLocalDesc' => 'Aucune donnée n\'est envoyée en ligne. Configuration cloud absente.',
			'onboarding.skip' => 'Passer',
			'onboarding.next' => 'Suivant',
			'onboarding.getStarted' => 'Commencer',
			'onboarding.welcomeTitle' => ({required Object appName}) => 'Bienvenue sur ${appName}',
			'onboarding.welcomeSubtitle' => 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de trek.',
			'onboarding.languageTitle' => 'Choisissez votre langue',
			'onboarding.languageSubtitle' => 'Vous pourrez la modifier à tout moment dans les paramètres.',
			'onboarding.downloadTitle' => 'Téléchargez votre premier sentier',
			'onboarding.downloadSubtitle' => 'Parcourez le catalogue et téléchargez un sentier pour l\'utiliser entièrement hors ligne.',
			'onboarding.browseCatalog' => 'Parcourir le catalogue',
			'monetization.demoBanner' => 'Mode démo — touchez pour débloquer',
			'monetization.paywallTitle' => 'Débloquez ce trek',
			'monetization.paywallBody' => 'Le mode gratuit permet de préparer votre trek avec publicité. Le premium débloque tout, sans pub.',
			'monetization.featureMap' => 'Carte hors ligne + GPS + suivi en direct',
			'monetization.featureJournal' => 'Journal de bord complet',
			'monetization.featureDiploma' => 'Diplôme de fin de trek',
			'monetization.featureFollowers' => '2 suiveurs gratuits',
			'monetization.featureNoAds' => 'Zéro publicité',
			'monetization.buyCta' => 'Débloquer ce trek',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Débloquer ce trek — ${price} €',
			'signalement.title' => 'Signaler',
			'signalement.chooseType' => 'Que voulez-vous signaler ?',
			'signalement.types.obstacle' => 'Obstacle sur le sentier',
			'signalement.types.eauASec' => 'Point d\'eau à sec',
			'signalement.types.danger' => 'Danger',
			'signalement.latencyBanner' => 'Enregistré. Visible par les autres randonneurs après synchronisation réseau.',
			'signalement.confirm' => 'Confirmer le signalement',
			'signalement.noLocation' => 'Position GPS indisponible pour le moment. Réessayez sous le ciel ouvert.',
			'signalement.savedTitle' => 'Signalement enregistré',
			'signalement.savedPendingSync' => 'Il sera partagé dès le retour du réseau.',
			'signalement.pendingCount' => ({required Object n}) => '${n} en attente de synchronisation',
			'signalement.close' => 'Fermer',
			'hebergement.title' => 'Hébergements à proximité',
			'hebergement.facilitatorNote' => 'StepWays vous oriente vers les hébergeurs. La réservation se fait sur leur site : aucun paiement dans l\'application.',
			'hebergement.detourAR' => ({required Object km}) => 'Détour aller-retour : ${km} km',
			'hebergement.openSite' => 'Voir le site',
			'hebergement.cannotOpen' => 'Impossible d\'ouvrir ce lien sur cet appareil.',
			'hebergement.empty' => 'Aucun hébergement répertorié à proximité pour le moment.',
			'hebergement.types.refuge' => 'Refuge',
			'hebergement.types.gite' => 'Gîte',
			'hebergement.types.hotel' => 'Hôtel',
			'hebergement.types.camping' => 'Camping',
			'hebergement.types.chambreHote' => 'Chambre d\'hôte',
			'training.title' => 'Préparation physique',
			'training.localNotice' => 'Votre programme est calculé et conservé sur votre téléphone. Les rappels sont des notifications locales, sans suivi.',
			'training.reminderTitle' => 'Séance d\'entraînement aujourd\'hui',
			'training.scheduleReminders' => 'Programmer les rappels',
			'training.remindersScheduled' => ({required Object n}) => '${n} rappel(s) programmé(s)',
			'training.week' => ({required Object n}) => 'Semaine ${n}',
			'training.minutes' => ({required Object n}) => '${n} min',
			'training.progress' => ({required Object done, required Object total}) => '${done}/${total} séances faites',
			'training.types.marche' => 'Marche',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Renforcement',
			'training.intensity.faible' => 'Faible',
			'training.intensity.moderee' => 'Modérée',
			'training.intensity.elevee' => 'Élevée',
			'eta.title' => 'Temps estimé',
			'eta.toNextWaypoint' => 'Prochain point',
			'eta.toStageEnd' => 'Fin d\'étape',
			'eta.confidenceHigh' => 'Estimation fiable',
			'eta.confidenceLow' => 'Approximatif (GPS faible)',
			'eta.durationHm' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'eta.durationM' => ({required Object m}) => '${m} min',
			'leaderboard.title' => 'Roi de l\'étape',
			'leaderboard.unavailable' => 'Classement indisponible pour le moment.',
			'leaderboard.empty' => 'Aucun classement pour ce segment. Sois le premier à le parcourir !',
			'leaderboard.pseudonymNotice' => 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n\'est affichée.',
			'leaderboard.trancheLabel' => ({required Object tranche}) => 'Tranche : ${tranche}',
			'leaderboard.notEnoughParticipants' => 'Pas assez de participants pour publier ce classement.',
			'leaderboard.entrySemantics' => ({required Object rank, required Object pseudonym, required Object time}) => 'Rang ${rank}, ${pseudonym}, temps ${time}',
			_ => null,
		};
	}
}
