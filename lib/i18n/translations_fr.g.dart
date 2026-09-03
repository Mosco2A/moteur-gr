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
	late final Translations$branding$fr branding = Translations$branding$fr.internal(_root);
	late final Translations$hub$fr hub = Translations$hub$fr.internal(_root);
	late final Translations$map$fr map = Translations$map$fr.internal(_root);
	late final Translations$stage$fr stage = Translations$stage$fr.internal(_root);
	late final Translations$trail$fr trail = Translations$trail$fr.internal(_root);
	late final Translations$poi$fr poi = Translations$poi$fr.internal(_root);
	late final Translations$accommodation$fr accommodation = Translations$accommodation$fr.internal(_root);
	late final Translations$gps$fr gps = Translations$gps$fr.internal(_root);
	late final Translations$navAlert$fr navAlert = Translations$navAlert$fr.internal(_root);
	late final Translations$planning$fr planning = Translations$planning$fr.internal(_root);
	late final Translations$tracking$fr tracking = Translations$tracking$fr.internal(_root);
	late final Translations$checklist$fr checklist = Translations$checklist$fr.internal(_root);
	late final Translations$journal$fr journal = Translations$journal$fr.internal(_root);
	late final Translations$weather$fr weather = Translations$weather$fr.internal(_root);
	late final Translations$share$fr share = Translations$share$fr.internal(_root);
	late final Translations$diploma$fr diploma = Translations$diploma$fr.internal(_root);
	late final Translations$notifications$fr notifications = Translations$notifications$fr.internal(_root);
	late final Translations$settings$fr settings = Translations$settings$fr.internal(_root);
	late final Translations$appearance$fr appearance = Translations$appearance$fr.internal(_root);
	late final Translations$feedback$fr feedback = Translations$feedback$fr.internal(_root);
	late final Translations$auth$fr auth = Translations$auth$fr.internal(_root);
	late final Translations$feasibility$fr feasibility = Translations$feasibility$fr.internal(_root);
	late final Translations$tips$fr tips = Translations$tips$fr.internal(_root);
	late final Translations$goodies$fr goodies = Translations$goodies$fr.internal(_root);
	late final Translations$noData$fr noData = Translations$noData$fr.internal(_root);
	late final Translations$catalog$fr catalog = Translations$catalog$fr.internal(_root);
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
	late final Translations$social$fr social = Translations$social$fr.internal(_root);
	late final Translations$gamification$fr gamification = Translations$gamification$fr.internal(_root);
	late final Translations$shareVisibility$fr shareVisibility = Translations$shareVisibility$fr.internal(_root);
	late final Translations$waypoints$fr waypoints = Translations$waypoints$fr.internal(_root);
	late final Translations$packs$fr packs = Translations$packs$fr.internal(_root);
	late final Translations$guides$fr guides = Translations$guides$fr.internal(_root);
	late final Translations$health$fr health = Translations$health$fr.internal(_root);
	late final Translations$trailSelection$fr trailSelection = Translations$trailSelection$fr.internal(_root);
	late final Translations$consent$fr consent = Translations$consent$fr.internal(_root);
	late final Translations$moderation$fr moderation = Translations$moderation$fr.internal(_root);
	late final Translations$bootstrap$fr bootstrap = Translations$bootstrap$fr.internal(_root);
	late final Translations$recap$fr recap = Translations$recap$fr.internal(_root);
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

	/// fr: 'Accueil'
	String get accueil => 'Accueil';

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

	/// fr: 'Conseils randonnée'
	String get tips => 'Conseils randonnée';

	/// fr: 'Contacts urgence'
	String get emergency => 'Contacts urgence';

	/// fr: 'Catalogue des sentiers'
	String get catalog => 'Catalogue des sentiers';

	/// fr: 'Profil'
	String get profile => 'Profil';

	/// fr: 'Paramètres'
	String get settings => 'Paramètres';

	/// fr: 'Changer de sentier'
	String get trailSelection => 'Changer de sentier';
}

// Path: branding
class Translations$branding$fr {
	Translations$branding$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre compagnon de randonnée'
	String get tagline => 'Votre compagnon de randonnée';

	/// fr: 'Préparez, marchez, partagez'
	String get subline => 'Préparez, marchez, partagez';
}

// Path: hub
class Translations$hub$fr {
	Translations$hub$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Bonjour, $name !'
	String greeting({required Object name}) => 'Bonjour, ${name} !';

	/// fr: 'Randonneur'
	String get greetingFallback => 'Randonneur';

	/// fr: 'À propos de ce sentier'
	String get infoTooltip => 'À propos de ce sentier';

	/// fr: 'Mon profil'
	String get profileTooltip => 'Mon profil';

	/// fr: 'Ce sentier vous accompagne à chaque étape : préparez votre itinéraire, préparez votre sac, puis partez en navigation GPS. Chaque fonction est accessible depuis cet écran d'accueil.'
	String get infoSheetBody => 'Ce sentier vous accompagne à chaque étape : préparez votre itinéraire, préparez votre sac, puis partez en navigation GPS. Chaque fonction est accessible depuis cet écran d\'accueil.';

	late final Translations$hub$trekCard$fr trekCard = Translations$hub$trekCard$fr.internal(_root);
	late final Translations$hub$weather$fr weather = Translations$hub$weather$fr.internal(_root);

	/// fr: 'Démarrer la randonnée'
	String get startCta => 'Démarrer la randonnée';

	late final Translations$hub$sections$fr sections = Translations$hub$sections$fr.internal(_root);
	late final Translations$hub$cards$fr cards = Translations$hub$cards$fr.internal(_root);
	late final Translations$hub$fab$fr fab = Translations$hub$fab$fr.internal(_root);
}

// Path: map
class Translations$map$fr {
	Translations$map$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Carte du sentier'
	String get title => 'Carte du sentier';

	/// fr: 'Chargement du tracé...'
	String get loading => 'Chargement du tracé...';

	/// fr: 'Aucun tracé disponible'
	String get noTrack => 'Aucun tracé disponible';

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

	/// fr: 'Dénivelé'
	String get elevation => 'Dénivelé';

	/// fr: 'Dénivelé positif'
	String get elevationGain => 'Dénivelé positif';

	/// fr: 'Dénivelé négatif'
	String get elevationLoss => 'Dénivelé négatif';

	/// fr: 'Durée estimée'
	String get duration => 'Durée estimée';

	/// fr: 'Description'
	String get description => 'Description';

	/// fr: 'Coordonnées'
	String get coordinates => 'Coordonnées';

	/// fr: 'Points d'intérêt'
	String get pois => 'Points d\'intérêt';

	late final Translations$stage$difficulty$fr difficulty = Translations$stage$difficulty$fr.internal(_root);

	/// fr: '{distance} km restants'
	String get remaining => '{distance} km restants';

	/// fr: 'Vous etes arrive !'
	String get arrived => 'Vous etes arrive !';

	/// fr: 'Profil altimetrique'
	String get altitudeProfile => 'Profil altimetrique';

	/// fr: 'Statistiques'
	String get statistics => 'Statistiques';

	/// fr: 'Chargement...'
	String get loading => 'Chargement...';

	/// fr: 'Chargement des etapes...'
	String get loadingList => 'Chargement des etapes...';

	/// fr: 'D+'
	String get dPlus => 'D+';

	/// fr: 'D-'
	String get dMinus => 'D-';

	/// fr: 'Difficulte'
	String get difficultyLabel => 'Difficulte';
}

// Path: trail
class Translations$trail$fr {
	Translations$trail$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Étapes'
	String get stages => 'Étapes';

	/// fr: 'Distance totale'
	String get totalDistance => 'Distance totale';

	/// fr: 'Dénivelé total'
	String get totalElevation => 'Dénivelé total';
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

	/// fr: 'Filtrer les points d'intérêt'
	String get filter => 'Filtrer les points d\'intérêt';

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

// Path: navAlert
class Translations$navAlert$fr {
	Translations$navAlert$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Vous vous eloignez du sentier — $meters m. Verifiez votre position.'
	String offTrackBanner({required Object meters}) => 'Vous vous eloignez du sentier — ${meters} m. Verifiez votre position.';

	/// fr: 'Vous quittez le sentier'
	String get offTrackNotifTitle => 'Vous quittez le sentier';

	/// fr: 'Vous vous eloignez du sentier ($meters m). Verifiez votre position.'
	String offTrackNotifBody({required Object meters}) => 'Vous vous eloignez du sentier (${meters} m). Verifiez votre position.';
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

	/// fr: 'D+'
	String get dPlus => 'D+';

	/// fr: 'La progression sera sauvegardee.'
	String get stopSaveProgress => 'La progression sera sauvegardee.';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';

	/// fr: 'Stop'
	String get stopButton => 'Stop';
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

	/// fr: 'Journal de randonnée'
	String get title => 'Journal de randonnée';

	/// fr: 'Votre journal est vide'
	String get empty => 'Votre journal est vide';

	/// fr: 'Notez vos impressions et souvenirs de randonnée'
	String get emptySubtitle => 'Notez vos impressions et souvenirs de randonnée';

	/// fr: 'Nouvelle note'
	String get addNote => 'Nouvelle note';

	/// fr: 'Étape'
	String get stage => 'Étape';

	/// fr: 'Votre note'
	String get yourNote => 'Votre note';

	/// fr: 'Décrivez votre journée de randonnée...'
	String get placeholder => 'Décrivez votre journée de randonnée...';

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

	/// fr: 'Aujourd'hui'
	String get today => 'Aujourd\'hui';

	/// fr: 'Demain'
	String get tomorrow => 'Demain';

	/// fr: 'Après-demain'
	String get dayPlus2 => 'Après-demain';

	/// fr: 'Toutes les étapes'
	String get allStages => 'Toutes les étapes';

	/// fr: 'Aucune prévision disponible.'
	String get noForecast => 'Aucune prévision disponible.';

	/// fr: 'Étape $number'
	String stageLabel({required Object number}) => 'Étape ${number}';

	/// fr: 'Alertes orage'
	String get stormAlertsTitle => 'Alertes orage';

	/// fr: 'Alertes orage activées'
	String get stormAlertsToggleOn => 'Alertes orage activées';

	/// fr: 'Alertes orage désactivées'
	String get stormAlertsToggleOff => 'Alertes orage désactivées';

	/// fr: 'Mis à jour $date'
	String lastUpdate({required Object date}) => 'Mis à jour ${date}';

	/// fr: 'Comprendre la météo'
	String get guideTitle => 'Comprendre la météo';

	/// fr: 'Les prévisions couvrent 7 jours pour chaque étape. Surveillez les alertes orage et vent : en montagne, le temps change vite. En l'absence de réseau, les dernières données enregistrées sont affichées.'
	String get guideBody => 'Les prévisions couvrent 7 jours pour chaque étape. Surveillez les alertes orage et vent : en montagne, le temps change vite. En l\'absence de réseau, les dernières données enregistrées sont affichées.';

	late final Translations$weather$source$fr source = Translations$weather$source$fr.internal(_root);
	late final Translations$weather$recommendation$fr recommendation = Translations$weather$recommendation$fr.internal(_root);
	late final Translations$weather$alert$fr alert = Translations$weather$alert$fr.internal(_root);
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

	/// fr: 'Diplôme de randonnée'
	String get title => 'Diplôme de randonnée';

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

	/// fr: '{days} jours de randonnée'
	String get recapDuration => '{days} jours de randonnée';

	/// fr: 'Trace du parcours'
	String get recapMapTrace => 'Trace du parcours';

	/// fr: 'Trace non disponible'
	String get recapNoMap => 'Trace non disponible';

	/// fr: '{count} notes de journal'
	String get recapJournalEntries => '{count} notes de journal';

	/// fr: 'Telecharger le diplome PDF'
	String get downloadPdf => 'Telecharger le diplome PDF';

	/// fr: 'Diplome verrouille'
	String get lockedTitle => 'Diplome verrouille';

	/// fr: 'Terminez l integralite de votre parcours pour debloquer votre diplome de finisher.'
	String get lockedMessage => 'Terminez l integralite de votre parcours pour debloquer votre diplome de finisher.';

	/// fr: 'Parcours integral'
	String get labelIntegral => 'Parcours integral';

	/// fr: 'Parcours partiel'
	String get labelPartial => 'Parcours partiel';
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

	/// fr: 'Votre randonnée approche !'
	String get schedulerCountdownTitle => 'Votre randonnée approche !';

	/// fr: 'Depart dans 2 jours. Verifiez votre checklist et la meteo.'
	String get schedulerCountdownBody => 'Depart dans 2 jours. Verifiez votre checklist et la meteo.';

	/// fr: 'Bonne journee de randonnée !'
	String get schedulerDailyTitle => 'Bonne journee de randonnée !';

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

	/// fr: 'Alerte hors-trace'
	String get offTrackAlerts => 'Alerte hors-trace';

	/// fr: 'Notification + vibration si vous quittez le sentier'
	String get offTrackAlertsDesc => 'Notification + vibration si vous quittez le sentier';

	/// fr: 'Version'
	String get version => 'Version';

	/// fr: 'Version de l'application'
	String get versionLabel => 'Version de l\'application';
}

// Path: appearance
class Translations$appearance$fr {
	Translations$appearance$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Apparence'
	String get title => 'Apparence';

	/// fr: 'Choisissez l’habillage de l’application'
	String get subtitle => 'Choisissez l’habillage de l’application';

	/// fr: 'Sentier Vivant'
	String get skinSentierVivant => 'Sentier Vivant';

	/// fr: 'Moderne et coloré, la couleur du sentier en vedette'
	String get skinSentierVivantDesc => 'Moderne et coloré, la couleur du sentier en vedette';

	/// fr: 'Topographique'
	String get skinTopographique => 'Topographique';

	/// fr: 'Style carte d’état-major, données en avant'
	String get skinTopographiqueDesc => 'Style carte d’état-major, données en avant';

	/// fr: 'Grand Air'
	String get skinGrandAir => 'Grand Air';

	/// fr: 'Photos plein écran, ambiance carnet d’aventure'
	String get skinGrandAirDesc => 'Photos plein écran, ambiance carnet d’aventure';

	/// fr: 'Indisponible sur ce sentier'
	String get unavailableOnTrail => 'Indisponible sur ce sentier';

	/// fr: 'Changer de peau'
	String get changeSkin => 'Changer de peau';

	/// fr: 'Sélectionné'
	String get selected => 'Sélectionné';
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

	/// fr: 'Randonneur sans compte'
	String get anonymous => 'Randonneur sans compte';

	/// fr: 'Connecté via'
	String get connectedVia => 'Connecté via';

	/// fr: 'Se connecter avec Google'
	String get signInGoogle => 'Se connecter avec Google';

	/// fr: 'Pour sauvegarder votre progression'
	String get signInGoogleDesc => 'Pour sauvegarder votre progression';

	/// fr: 'Se déconnecter'
	String get signOut => 'Se déconnecter';

	/// fr: 'Revenir au mode sans compte'
	String get signOutDesc => 'Revenir au mode sans compte';

	/// fr: 'Se déconnecter ?'
	String get signOutConfirm => 'Se déconnecter ?';

	/// fr: 'Vous reviendrez au mode sans compte. Vos données locales sont conservées.'
	String get signOutMessage => 'Vous reviendrez au mode sans compte. Vos données locales sont conservées.';

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

	/// fr: 'Conseils randonnée'
	String get carouselTitle => 'Conseils randonnée';

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

// Path: catalog
class Translations$catalog$fr {
	Translations$catalog$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Catalogue des sentiers'
	String get title => 'Catalogue des sentiers';

	/// fr: 'Entrer'
	String get enter => 'Entrer';

	/// fr: 'Téléchargez ce sentier pour l'explorer.'
	String get mustDownload => 'Téléchargez ce sentier pour l\'explorer.';

	/// fr: 'Aucun sentier disponible'
	String get emptyTitle => 'Aucun sentier disponible';

	/// fr: 'Aucun sentier n'est encore proposé au catalogue.'
	String get emptySubtitle => 'Aucun sentier n\'est encore proposé au catalogue.';

	late final Translations$catalog$a11y$fr a11y = Translations$catalog$a11y$fr.internal(_root);
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

	/// fr: 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de randonnée.'
	String get welcomeSubtitle => 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de randonnée.';

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

	/// fr: 'Débloquez cette randonnée'
	String get paywallTitle => 'Débloquez cette randonnée';

	/// fr: 'Le mode gratuit permet de préparer votre randonnée avec publicité. Le premium débloque tout, sans pub.'
	String get paywallBody => 'Le mode gratuit permet de préparer votre randonnée avec publicité. Le premium débloque tout, sans pub.';

	/// fr: 'Carte hors ligne + GPS + suivi en direct'
	String get featureMap => 'Carte hors ligne + GPS + suivi en direct';

	/// fr: 'Journal de bord complet'
	String get featureJournal => 'Journal de bord complet';

	/// fr: 'Diplôme de fin de randonnée'
	String get featureDiploma => 'Diplôme de fin de randonnée';

	/// fr: '2 suiveurs gratuits'
	String get featureFollowers => '2 suiveurs gratuits';

	/// fr: 'Zéro publicité'
	String get featureNoAds => 'Zéro publicité';

	/// fr: 'Débloquer cette randonnée'
	String get buyCta => 'Débloquer cette randonnée';

	/// fr: 'Débloquer cette randonnée — $price €'
	String buyCtaWithPrice({required Object price}) => 'Débloquer cette randonnée — ${price} €';
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

// Path: social
class Translations$social$fr {
	Translations$social$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Fil d'activité'
	String get feedTitle => 'Fil d\'activité';

	/// fr: 'Aucune activité pour le moment.'
	String get empty => 'Aucune activité pour le moment.';

	/// fr: 'Encourager'
	String get kudos => 'Encourager';

	/// fr: '$n encouragement(s)'
	String kudosCount({required Object n}) => '${n} encouragement(s)';

	/// fr: 'Signaler'
	String get report => 'Signaler';

	/// fr: 'Signaler cette publication'
	String get reportTitle => 'Signaler cette publication';

	/// fr: 'Motif du signalement'
	String get reportReasonLabel => 'Motif du signalement';

	/// fr: 'Spam ou publicité'
	String get reasonSpam => 'Spam ou publicité';

	/// fr: 'Contenu abusif ou haineux'
	String get reasonAbuse => 'Contenu abusif ou haineux';

	/// fr: 'Autre'
	String get reasonOther => 'Autre';

	/// fr: 'Envoyer le signalement'
	String get reportSend => 'Envoyer le signalement';

	/// fr: 'Signalement envoyé. Il sera examiné par notre équipe.'
	String get reportSent => 'Signalement envoyé. Il sera examiné par notre équipe.';

	/// fr: 'En attente de synchronisation'
	String get syncPending => 'En attente de synchronisation';

	/// fr: 'Synchronisé'
	String get synced => 'Synchronisé';

	/// fr: 'a réalisé un segment'
	String get activitySegment => 'a réalisé un segment';

	/// fr: 'a obtenu un badge'
	String get activityBadge => 'a obtenu un badge';

	/// fr: 'a progressé dans un défi'
	String get activityDefi => 'a progressé dans un défi';
}

// Path: gamification
class Translations$gamification$fr {
	Translations$gamification$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mes badges'
	String get galleryTitle => 'Mes badges';

	/// fr: 'Obtenu'
	String get obtained => 'Obtenu';

	/// fr: 'Verrouillé'
	String get locked => 'Verrouillé';

	/// fr: 'Débutant'
	String get tierDebutant => 'Débutant';

	/// fr: 'Expert'
	String get tierExpert => 'Expert';

	late final Translations$gamification$badge$fr badge = Translations$gamification$badge$fr.internal(_root);
	late final Translations$gamification$defi$fr defi = Translations$gamification$defi$fr.internal(_root);
}

// Path: shareVisibility
class Translations$shareVisibility$fr {
	Translations$shareVisibility$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Partage et visibilité'
	String get title => 'Partage et visibilité';

	/// fr: 'Par défaut, rien n'est partagé. Active ci-dessous, finalité par finalité, ce que tu veux rendre visible.'
	String get intro => 'Par défaut, rien n\'est partagé. Active ci-dessous, finalité par finalité, ce que tu veux rendre visible.';

	/// fr: 'Gérer mon consentement (confidentialité)'
	String get consentLink => 'Gérer mon consentement (confidentialité)';

	/// fr: 'Partager mes résultats d'étape'
	String get stageResults => 'Partager mes résultats d\'étape';

	/// fr: 'Une carte pseudonyme (sans données personnelles directes).'
	String get stageResultsDesc => 'Une carte pseudonyme (sans données personnelles directes).';

	/// fr: 'Apparaître dans les classements'
	String get leaderboard => 'Apparaître dans les classements';

	/// fr: 'Classement par tranche, avec un pseudonyme.'
	String get leaderboardDesc => 'Classement par tranche, avec un pseudonyme.';

	/// fr: 'Publier au fil d'activité'
	String get activityFeed => 'Publier au fil d\'activité';

	/// fr: 'Tes activités apparaissent dans le fil, sous pseudonyme.'
	String get activityFeedDesc => 'Tes activités apparaissent dans le fil, sous pseudonyme.';

	/// fr: 'Partager cette étape'
	String get shareTitle => 'Partager cette étape';

	/// fr: 'Partager'
	String get shareButton => 'Partager';

	/// fr: 'Le partage est désactivé. Active-le dans Partage et visibilité.'
	String get privateNotice => 'Le partage est désactivé. Active-le dans Partage et visibilité.';

	/// fr: 'Carte prête à partager.'
	String get shared => 'Carte prête à partager.';
}

// Path: waypoints
class Translations$waypoints$fr {
	Translations$waypoints$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$waypoints$types$fr types = Translations$waypoints$types$fr.internal(_root);
	late final Translations$waypoints$filters$fr filters = Translations$waypoints$filters$fr.internal(_root);
	late final Translations$waypoints$detail$fr detail = Translations$waypoints$detail$fr.internal(_root);
	late final Translations$waypoints$freshness$fr freshness = Translations$waypoints$freshness$fr.internal(_root);
	late final Translations$waypoints$contribution$fr contribution = Translations$waypoints$contribution$fr.internal(_root);
}

// Path: packs
class Translations$packs$fr {
	Translations$packs$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Packs sentier'
	String get title => 'Packs sentier';

	/// fr: 'Téléchargez un pack pour randonner 100% hors-ligne.'
	String get subtitle => 'Téléchargez un pack pour randonner 100% hors-ligne.';

	/// fr: 'À la carte : achetez seulement le pack qu'il vous faut, pas d'abonnement.'
	String get alaCarteNote => 'À la carte : achetez seulement le pack qu\'il vous faut, pas d\'abonnement.';

	/// fr: '$mo Mo'
	String size({required Object mo}) => '${mo} Mo';

	late final Translations$packs$states$fr states = Translations$packs$states$fr.internal(_root);
	late final Translations$packs$actions$fr actions = Translations$packs$actions$fr.internal(_root);
	late final Translations$packs$progress$fr progress = Translations$packs$progress$fr.internal(_root);
	late final Translations$packs$delete$fr delete = Translations$packs$delete$fr.internal(_root);

	/// fr: 'Aucun pack disponible pour ce sentier.'
	String get empty => 'Aucun pack disponible pour ce sentier.';

	late final Translations$packs$a11y$fr a11y = Translations$packs$a11y$fr.internal(_root);
	late final Translations$packs$types$fr types = Translations$packs$types$fr.internal(_root);
}

// Path: guides
class Translations$guides$fr {
	Translations$guides$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Guides des villes'
	String get title => 'Guides des villes';

	/// fr: 'Infos pratiques des villes et villages, consultables hors-ligne.'
	String get subtitle => 'Infos pratiques des villes et villages, consultables hors-ligne.';

	/// fr: '$n rubriques pratiques'
	String sectionsCount({required Object n}) => '${n} rubriques pratiques';

	/// fr: 'Aucun guide disponible pour ce sentier.'
	String get empty => 'Aucun guide disponible pour ce sentier.';

	/// fr: 'Aucune information dans cette section pour le moment.'
	String get noItems => 'Aucune information dans cette section pour le moment.';

	/// fr: 'StepWays vous oriente vers les prestataires. Réservation et paiement se font sur leur site : rien dans l'application.'
	String get facilitatorNote => 'StepWays vous oriente vers les prestataires. Réservation et paiement se font sur leur site : rien dans l\'application.';

	/// fr: 'Voir le site'
	String get openSite => 'Voir le site';

	/// fr: 'Impossible d'ouvrir ce lien sur cet appareil.'
	String get cannotOpen => 'Impossible d\'ouvrir ce lien sur cet appareil.';

	late final Translations$guides$categories$fr categories = Translations$guides$categories$fr.internal(_root);
	late final Translations$guides$intro$fr intro = Translations$guides$intro$fr.internal(_root);
	late final Translations$guides$a11y$fr a11y = Translations$guides$a11y$fr.internal(_root);
}

// Path: health
class Translations$health$fr {
	Translations$health$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Informations santé'
	String get title => 'Informations santé';

	/// fr: 'Ces données restent sur votre téléphone. Elles ne sont jamais envoyées sur internet.'
	String get privacyBanner => 'Ces données restent sur votre téléphone. Elles ne sont jamais envoyées sur internet.';

	late final Translations$health$field$fr field = Translations$health$field$fr.internal(_root);
	late final Translations$health$hint$fr hint = Translations$health$hint$fr.internal(_root);

	/// fr: 'Sauvegarder'
	String get save => 'Sauvegarder';

	/// fr: 'Sauvegarde…'
	String get saving => 'Sauvegarde…';

	/// fr: 'Informations sauvegardées'
	String get saved => 'Informations sauvegardées';

	/// fr: 'En cas d'urgence, montrez cet écran aux secours.'
	String get emergencyHint => 'En cas d\'urgence, montrez cet écran aux secours.';

	/// fr: 'Mes infos santé'
	String get entryTitle => 'Mes infos santé';

	/// fr: 'À montrer aux secours (restées sur le téléphone)'
	String get entrySubtitle => 'À montrer aux secours (restées sur le téléphone)';

	late final Translations$health$a11y$fr a11y = Translations$health$a11y$fr.internal(_root);
}

// Path: trailSelection
class Translations$trailSelection$fr {
	Translations$trailSelection$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Changer de sentier'
	String get title => 'Changer de sentier';

	/// fr: 'Choisis le sentier a explorer. Tout l app (carte, etapes, points d interet, packs, guides) suit ta selection.'
	String get subtitle => 'Choisis le sentier a explorer. Tout l app (carte, etapes, points d interet, packs, guides) suit ta selection.';

	/// fr: 'Sentier actif'
	String get current => 'Sentier actif';

	/// fr: 'Choisir ce sentier'
	String get select => 'Choisir ce sentier';

	/// fr: 'Sentier selectionne'
	String get selected => 'Sentier selectionne';

	/// fr: '$stages etapes - $km km'
	String stagesDistance({required Object stages, required Object km}) => '${stages} etapes - ${km} km';

	late final Translations$trailSelection$a11y$fr a11y = Translations$trailSelection$a11y$fr.internal(_root);
}

// Path: consent
class Translations$consent$fr {
	Translations$consent$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Votre vie privée, votre choix'
	String get onboardingTitle => 'Votre vie privée, votre choix';

	/// fr: 'Rien n'est activé par défaut. Choisissez, finalité par finalité, ce que vous autorisez. Vous pourrez tout modifier à tout moment dans les réglages.'
	String get onboardingIntro => 'Rien n\'est activé par défaut. Choisissez, finalité par finalité, ce que vous autorisez. Vous pourrez tout modifier à tout moment dans les réglages.';

	/// fr: 'Confidentialité et consentement'
	String get settingsTitle => 'Confidentialité et consentement';

	/// fr: 'Gérez ici chaque autorisation. Vous pouvez retirer un consentement à tout moment, sans conséquence sur le reste.'
	String get settingsIntro => 'Gérez ici chaque autorisation. Vous pouvez retirer un consentement à tout moment, sans conséquence sur le reste.';

	/// fr: 'Confidentialité et consentement'
	String get settingsEntry => 'Confidentialité et consentement';

	/// fr: 'Gérer mes autorisations (géolocalisation, partage, santé)'
	String get settingsEntryDesc => 'Gérer mes autorisations (géolocalisation, partage, santé)';

	late final Translations$consent$purposes$fr purposes = Translations$consent$purposes$fr.internal(_root);

	/// fr: 'Donnée sensible'
	String get healthBadge => 'Donnée sensible';

	/// fr: 'La fréquence cardiaque est une donnée de santé (article 9 RGPD). Ce consentement est demandé séparément et n'est jamais regroupé avec les autres. Vos données de santé ne sont pas envoyées sur nos serveurs.'
	String get healthWarning => 'La fréquence cardiaque est une donnée de santé (article 9 RGPD). Ce consentement est demandé séparément et n\'est jamais regroupé avec les autres. Vos données de santé ne sont pas envoyées sur nos serveurs.';

	/// fr: 'Autorisé'
	String get granted => 'Autorisé';

	/// fr: 'Non autorisé'
	String get denied => 'Non autorisé';

	/// fr: 'Autoriser'
	String get grant => 'Autoriser';

	/// fr: 'Retirer'
	String get revoke => 'Retirer';

	/// fr: 'Choix du $date'
	String decidedOn({required Object date}) => 'Choix du ${date}';

	/// fr: 'En attente de votre choix'
	String get notDecided => 'En attente de votre choix';

	/// fr: 'Valider mes choix'
	String get acceptSelected => 'Valider mes choix';

	/// fr: 'Tout refuser'
	String get declineAll => 'Tout refuser';

	/// fr: 'Continuer'
	String get continueLabel => 'Continuer';

	/// fr: 'Lire la politique de confidentialité'
	String get privacyPolicyLink => 'Lire la politique de confidentialité';

	/// fr: 'Notre politique a évolué : merci de revoir vos choix.'
	String get reviewNeeded => 'Notre politique a évolué : merci de revoir vos choix.';

	late final Translations$consent$a11y$fr a11y = Translations$consent$a11y$fr.internal(_root);
}

// Path: moderation
class Translations$moderation$fr {
	Translations$moderation$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Signaler ce contenu'
	String get reportTitle => 'Signaler ce contenu';

	/// fr: 'Aidez-nous à garder la communauté saine. Indiquez pourquoi ce contenu vous semble illicite. Votre signalement sera examiné par un modérateur.'
	String get reportIntro => 'Aidez-nous à garder la communauté saine. Indiquez pourquoi ce contenu vous semble illicite. Votre signalement sera examiné par un modérateur.';

	/// fr: 'Motif du signalement'
	String get reasonLabel => 'Motif du signalement';

	late final Translations$moderation$reasons$fr reasons = Translations$moderation$reasons$fr.internal(_root);

	/// fr: 'Précisez (facultatif)'
	String get detailsLabel => 'Précisez (facultatif)';

	/// fr: 'Ajoutez un commentaire pour aider le modérateur.'
	String get detailsHint => 'Ajoutez un commentaire pour aider le modérateur.';

	/// fr: 'Votre adresse e-mail'
	String get contactLabel => 'Votre adresse e-mail';

	/// fr: 'Pour vous tenir informé du traitement (article 16).'
	String get contactHint => 'Pour vous tenir informé du traitement (article 16).';

	/// fr: 'Je déclare de bonne foi que ces informations sont exactes.'
	String get goodFaithLabel => 'Je déclare de bonne foi que ces informations sont exactes.';

	/// fr: 'Envoyer le signalement'
	String get submit => 'Envoyer le signalement';

	/// fr: 'Envoi en cours…'
	String get submitting => 'Envoi en cours…';

	/// fr: 'Signalement envoyé. Merci, un modérateur va l'examiner.'
	String get sent => 'Signalement envoyé. Merci, un modérateur va l\'examiner.';

	/// fr: 'Veuillez compléter le motif, votre e-mail et la déclaration de bonne foi.'
	String get errorRequired => 'Veuillez compléter le motif, votre e-mail et la déclaration de bonne foi.';

	/// fr: 'Le signalement n'a pas pu être envoyé. Réessayez.'
	String get errorGeneric => 'Le signalement n\'a pas pu être envoyé. Réessayez.';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';

	/// fr: 'Pourquoi ce contenu a-t-il été restreint ?'
	String get reasonsTitle => 'Pourquoi ce contenu a-t-il été restreint ?';

	/// fr: 'Conformément à l'article 17, voici la raison de la décision de modération concernant votre contenu.'
	String get reasonsIntro => 'Conformément à l\'article 17, voici la raison de la décision de modération concernant votre contenu.';

	/// fr: 'Décision'
	String get decisionLabel => 'Décision';

	late final Translations$moderation$decisions$fr decisions = Translations$moderation$decisions$fr.internal(_root);

	/// fr: 'Aucune restriction n'a été appliquée à vos contenus.'
	String get noStatement => 'Aucune restriction n\'a été appliquée à vos contenus.';

	/// fr: 'Contester cette décision'
	String get complaintAction => 'Contester cette décision';

	/// fr: 'Contester une décision'
	String get complaintTitle => 'Contester une décision';

	/// fr: 'Vous pouvez contester une décision de modération. Expliquez pourquoi vous estimez la décision injustifiée (article 20).'
	String get complaintIntro => 'Vous pouvez contester une décision de modération. Expliquez pourquoi vous estimez la décision injustifiée (article 20).';

	/// fr: 'Votre contestation'
	String get complaintExposeLabel => 'Votre contestation';

	/// fr: 'Décrivez les raisons de votre contestation.'
	String get complaintExposeHint => 'Décrivez les raisons de votre contestation.';

	/// fr: 'Envoyer la contestation'
	String get complaintSubmit => 'Envoyer la contestation';

	/// fr: 'Contestation enregistrée. Elle sera examinée.'
	String get complaintSent => 'Contestation enregistrée. Elle sera examinée.';

	/// fr: 'Veuillez expliquer votre contestation.'
	String get complaintEmpty => 'Veuillez expliquer votre contestation.';

	late final Translations$moderation$a11y$fr a11y = Translations$moderation$a11y$fr.internal(_root);
}

// Path: bootstrap
class Translations$bootstrap$fr {
	Translations$bootstrap$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparation de votre randonnée…'
	String get loading => 'Préparation de votre randonnée…';
}

// Path: recap
class Translations$recap$fr {
	Translations$recap$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mon aventure'
	String get title => 'Mon aventure';

	/// fr: 'Disponible a la fin du trek'
	String get lockedTitle => 'Disponible a la fin du trek';

	/// fr: 'Terminez ou abandonnez votre parcours pour retrouver le recapitulatif de votre aventure.'
	String get lockedMessage => 'Terminez ou abandonnez votre parcours pour retrouver le recapitulatif de votre aventure.';

	/// fr: 'Felicitations !'
	String get finisherTitle => 'Felicitations !';

	/// fr: 'Vous avez termine votre parcours'
	String get finisherSubtitle => 'Vous avez termine votre parcours';

	/// fr: 'Votre parcours partiel'
	String get partialTitle => 'Votre parcours partiel';

	/// fr: 'Votre aventure reste enregistree'
	String get partialSubtitle => 'Votre aventure reste enregistree';

	/// fr: 'Statistiques'
	String get statsSection => 'Statistiques';

	/// fr: 'Votre trace'
	String get traceSection => 'Votre trace';

	/// fr: 'Aucune trace GPS disponible'
	String get noTrace => 'Aucune trace GPS disponible';

	/// fr: '{done} / {total} etapes parcourues'
	String get stages => '{done} / {total} etapes parcourues';

	/// fr: '{km} km parcourus'
	String get distance => '{km} km parcourus';

	/// fr: '{meters} m de denivele positif'
	String get elevation => '{meters} m de denivele positif';

	/// fr: '{days} jours'
	String get duration => '{days} jours';

	/// fr: 'Du {start} au {end}'
	String get dates => 'Du {start} au {end}';

	/// fr: 'Voir mon diplome'
	String get viewDiploma => 'Voir mon diplome';

	/// fr: 'Aucune donnee de parcours a afficher pour le moment.'
	String get noData => 'Aucune donnee de parcours a afficher pour le moment.';
}

// Path: hub.trekCard
class Translations$hub$trekCard$fr {
	Translations$hub$trekCard$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Randonnée en cours'
	String get activeTitle => 'Randonnée en cours';

	/// fr: 'Distance parcourue'
	String get distanceCovered => 'Distance parcourue';

	/// fr: 'Dénivelé du jour'
	String get elevationGain => 'Dénivelé du jour';

	/// fr: 'Temps de marche'
	String get duration => 'Temps de marche';

	/// fr: '$percent % du sentier'
	String progressLabel({required Object percent}) => '${percent} % du sentier';

	/// fr: 'Reprendre la navigation'
	String get resume => 'Reprendre la navigation';

	/// fr: 'Prêt à partir ?'
	String get noTrekTitle => 'Prêt à partir ?';

	/// fr: 'Planifiez votre itinéraire, puis lancez votre randonnée quand vous êtes prêt.'
	String get noTrekBody => 'Planifiez votre itinéraire, puis lancez votre randonnée quand vous êtes prêt.';

	/// fr: 'Planifier ma randonnée'
	String get plan => 'Planifier ma randonnée';
}

// Path: hub.weather
class Translations$hub$weather$fr {
	Translations$hub$weather$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Météo du jour'
	String get title => 'Météo du jour';

	/// fr: 'La météo de votre étape arrive bientôt.'
	String get stub => 'La météo de votre étape arrive bientôt.';

	/// fr: 'Météo indisponible pour le moment.'
	String get unavailable => 'Météo indisponible pour le moment.';

	/// fr: 'Alerte orage'
	String get alertStorm => 'Alerte orage';

	/// fr: '$min° / $max°'
	String tempRange({required Object min, required Object max}) => '${min}° / ${max}°';
}

// Path: hub.sections
class Translations$hub$sections$fr {
	Translations$hub$sections$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Préparer'
	String get prepare => 'Préparer';

	/// fr: 'Randonner'
	String get hike => 'Randonner';

	/// fr: 'Informations'
	String get info => 'Informations';

	/// fr: 'Après la randonnée'
	String get after => 'Après la randonnée';
}

// Path: hub.cards
class Translations$hub$cards$fr {
	Translations$hub$cards$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Faisabilité'
	String get feasibility => 'Faisabilité';

	/// fr: 'Évaluez votre niveau'
	String get feasibilitySub => 'Évaluez votre niveau';

	/// fr: 'Itinéraire'
	String get itinerary => 'Itinéraire';

	/// fr: 'Le tracé du sentier'
	String get itinerarySub => 'Le tracé du sentier';

	/// fr: 'Programme'
	String get programme => 'Programme';

	/// fr: 'Répartissez vos étapes'
	String get programmeSub => 'Répartissez vos étapes';

	/// fr: 'Matériel & sac'
	String get checklist => 'Matériel & sac';

	/// fr: 'Préparez votre sac à dos'
	String get checklistSub => 'Préparez votre sac à dos';

	/// fr: 'Préparation physique'
	String get training => 'Préparation physique';

	/// fr: 'Votre programme d'entraînement'
	String get trainingSub => 'Votre programme d\'entraînement';

	/// fr: 'Découvrir des sentiers'
	String get offline => 'Découvrir des sentiers';

	/// fr: 'Parcourez le catalogue'
	String get offlineSub => 'Parcourez le catalogue';

	/// fr: 'Mon groupe'
	String get group => 'Mon groupe';

	/// fr: 'Suivi de vos compagnons'
	String get groupSub => 'Suivi de vos compagnons';

	/// fr: 'Navigation'
	String get navigation => 'Navigation';

	/// fr: 'Carte et suivi GPS'
	String get navigationSub => 'Carte et suivi GPS';

	/// fr: 'Journal'
	String get journal => 'Journal';

	/// fr: 'Vos notes et souvenirs'
	String get journalSub => 'Vos notes et souvenirs';

	/// fr: 'Hébergements'
	String get accommodations => 'Hébergements';

	/// fr: 'Où dormir à proximité'
	String get accommodationsSub => 'Où dormir à proximité';

	/// fr: 'Fiches conseils'
	String get tips => 'Fiches conseils';

	/// fr: 'Nos conseils de randonnée'
	String get tipsSub => 'Nos conseils de randonnée';

	/// fr: 'Guides des villes'
	String get townGuides => 'Guides des villes';

	/// fr: 'Infos pratiques des étapes'
	String get townGuidesSub => 'Infos pratiques des étapes';

	/// fr: 'Récapitulatif'
	String get recap => 'Récapitulatif';

	/// fr: 'Votre aventure en résumé'
	String get recapSub => 'Votre aventure en résumé';

	/// fr: 'Diplôme'
	String get diploma => 'Diplôme';

	/// fr: 'Votre certificat de fin'
	String get diplomaSub => 'Votre certificat de fin';
}

// Path: hub.fab
class Translations$hub$fab$fr {
	Translations$hub$fab$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Donner mon avis'
	String get feedback => 'Donner mon avis';

	/// fr: 'SOS'
	String get sos => 'SOS';
}

// Path: stage.difficulty
class Translations$stage$difficulty$fr {
	Translations$stage$difficulty$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Facile'
	String get easy => 'Facile';

	/// fr: 'Modéré'
	String get moderate => 'Modéré';

	/// fr: 'Difficile'
	String get hard => 'Difficile';

	/// fr: 'Expert'
	String get expert => 'Expert';

	/// fr: 'Extreme'
	String get extreme => 'Extreme';
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

// Path: weather.source
class Translations$weather$source$fr {
	Translations$weather$source$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Données en direct'
	String get api => 'Données en direct';

	/// fr: 'Données enregistrées'
	String get cache => 'Données enregistrées';

	/// fr: 'Hors ligne'
	String get offline => 'Hors ligne';

	/// fr: 'Données de démonstration'
	String get demo => 'Données de démonstration';
}

// Path: weather.recommendation
class Translations$weather$recommendation$fr {
	Translations$weather$recommendation$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Conditions favorables'
	String get ok => 'Conditions favorables';

	/// fr: 'Vigilance recommandée'
	String get watch => 'Vigilance recommandée';

	/// fr: 'Conditions défavorables'
	String get danger => 'Conditions défavorables';
}

// Path: weather.alert
class Translations$weather$alert$fr {
	Translations$weather$alert$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$weather$alert$storm$fr storm = Translations$weather$alert$storm$fr.internal(_root);
	late final Translations$weather$alert$wind$fr wind = Translations$weather$alert$wind$fr.internal(_root);
	late final Translations$weather$alert$rain$fr rain = Translations$weather$alert$rain$fr.internal(_root);
	late final Translations$weather$alert$snow$fr snow = Translations$weather$alert$snow$fr.internal(_root);
	late final Translations$weather$alert$uv$fr uv = Translations$weather$alert$uv$fr.internal(_root);
	late final Translations$weather$alert$fire$fr fire = Translations$weather$alert$fire$fr.internal(_root);
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

	/// fr: 'Randonneur expérimenté, GR déjà réalisés'
	String get experienceD => 'Randonneur expérimenté, GR déjà réalisés';

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

// Path: catalog.a11y
class Translations$catalog$a11y$fr {
	Translations$catalog$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Entrer dans le sentier $nom'
	String enterButton({required Object nom}) => 'Entrer dans le sentier ${nom}';
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

// Path: gamification.badge
class Translations$gamification$badge$fr {
	Translations$gamification$badge$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$gamification$badge$firstStage$fr firstStage = Translations$gamification$badge$firstStage$fr.internal(_root);
	late final Translations$gamification$badge$firstTrek$fr firstTrek = Translations$gamification$badge$firstTrek$fr.internal(_root);
	late final Translations$gamification$badge$firstSegment$fr firstSegment = Translations$gamification$badge$firstSegment$fr.internal(_root);
	late final Translations$gamification$badge$elevation5000$fr elevation5000 = Translations$gamification$badge$elevation5000$fr.internal(_root);
	late final Translations$gamification$badge$tenStages$fr tenStages = Translations$gamification$badge$tenStages$fr.internal(_root);
	late final Translations$gamification$badge$challenger$fr challenger = Translations$gamification$badge$challenger$fr.internal(_root);
}

// Path: gamification.defi
class Translations$gamification$defi$fr {
	Translations$gamification$defi$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Défis'
	String get screenTitle => 'Défis';

	/// fr: 'En cours'
	String get inProgress => 'En cours';

	/// fr: 'Progression : $current / $target'
	String progressLabel({required Object current, required Object target}) => 'Progression : ${current} / ${target}';

	/// fr: 'Classement du défi'
	String get rankingTitle => 'Classement du défi';

	/// fr: 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n'est affichée.'
	String get pseudonymNotice => 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n\'est affichée.';

	/// fr: 'Pas assez de participants pour publier ce classement.'
	String get notEnoughParticipants => 'Pas assez de participants pour publier ce classement.';

	/// fr: 'Aucun défi en cours pour le moment.'
	String get noDefi => 'Aucun défi en cours pour le moment.';
}

// Path: waypoints.types
class Translations$waypoints$types$fr {
	Translations$waypoints$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Eau'
	String get eau => 'Eau';

	/// fr: 'Ravitaillement'
	String get ravitaillement => 'Ravitaillement';

	/// fr: 'Danger'
	String get danger => 'Danger';

	/// fr: 'Bivouac'
	String get camp => 'Bivouac';

	/// fr: 'Connectivité'
	String get connectivite => 'Connectivité';

	/// fr: 'Jonction'
	String get jonction => 'Jonction';
}

// Path: waypoints.filters
class Translations$waypoints$filters$fr {
	Translations$waypoints$filters$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Filtrer les waypoints'
	String get title => 'Filtrer les waypoints';

	/// fr: 'Tout afficher'
	String get showAll => 'Tout afficher';

	/// fr: 'Tout masquer'
	String get hideAll => 'Tout masquer';

	/// fr: 'Condition récente uniquement'
	String get recentConditionOnly => 'Condition récente uniquement';
}

// Path: waypoints.detail
class Translations$waypoints$detail$fr {
	Translations$waypoints$detail$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Conditions terrain'
	String get conditionsTitle => 'Conditions terrain';

	/// fr: 'Aucune condition signalée pour le moment.'
	String get noComments => 'Aucune condition signalée pour le moment.';

	/// fr: 'Conditions indisponibles.'
	String get commentsError => 'Conditions indisponibles.';

	/// fr: 'Signaler'
	String get report => 'Signaler';

	/// fr: 'Signalement enregistré. Il sera examiné après synchronisation.'
	String get reportAck => 'Signalement enregistré. Il sera examiné après synchronisation.';

	/// fr: 'En attente de synchronisation'
	String get pendingSync => 'En attente de synchronisation';
}

// Path: waypoints.freshness
class Translations$waypoints$freshness$fr {
	Translations$waypoints$freshness$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'mis à jour à l’instant'
	String get justNow => 'mis à jour à l’instant';

	/// fr: 'mis à jour il y a $n min'
	String minutes({required Object n}) => 'mis à jour il y a ${n} min';

	/// fr: 'mis à jour il y a $n h'
	String hours({required Object n}) => 'mis à jour il y a ${n} h';

	/// fr: 'mis à jour il y a $n j'
	String days({required Object n}) => 'mis à jour il y a ${n} j';
}

// Path: waypoints.contribution
class Translations$waypoints$contribution$fr {
	Translations$waypoints$contribution$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Ajouter un point'
	String get titleWaypoint => 'Ajouter un point';

	/// fr: 'Signaler une condition'
	String get titleComment => 'Signaler une condition';

	/// fr: 'Type de point'
	String get chooseType => 'Type de point';

	/// fr: 'Titre du point'
	String get titleField => 'Titre du point';

	/// fr: 'Décrivez la condition observée'
	String get conditionPrompt => 'Décrivez la condition observée';

	/// fr: 'Votre observation'
	String get commentField => 'Votre observation';

	/// fr: 'État (optionnel)'
	String get conditionField => 'État (optionnel)';

	/// fr: 'ex : eau à sec, eau coule bien, passage glissant'
	String get conditionHelper => 'ex : eau à sec, eau coule bien, passage glissant';

	/// fr: 'Sera publié à la prochaine synchronisation réseau.'
	String get latencyBanner => 'Sera publié à la prochaine synchronisation réseau.';

	/// fr: 'Enregistrer'
	String get submit => 'Enregistrer';

	/// fr: 'Contribution enregistrée'
	String get savedTitle => 'Contribution enregistrée';

	/// fr: 'Elle sera publiée dès le retour du réseau.'
	String get savedPendingSync => 'Elle sera publiée dès le retour du réseau.';

	/// fr: '$n en attente de synchronisation'
	String pendingCount({required Object n}) => '${n} en attente de synchronisation';

	/// fr: 'Fermer'
	String get close => 'Fermer';

	/// fr: 'Indiquez un titre pour le point.'
	String get emptyTitle => 'Indiquez un titre pour le point.';

	/// fr: 'Saisissez votre observation.'
	String get emptyComment => 'Saisissez votre observation.';

	/// fr: 'Position GPS indisponible. Réessayez sous le ciel ouvert.'
	String get noLocation => 'Position GPS indisponible. Réessayez sous le ciel ouvert.';

	/// fr: 'Enregistrement impossible pour le moment.'
	String get error => 'Enregistrement impossible pour le moment.';
}

// Path: packs.states
class Translations$packs$states$fr {
	Translations$packs$states$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Non téléchargé'
	String get notDownloaded => 'Non téléchargé';

	/// fr: 'Téléchargé'
	String get downloaded => 'Téléchargé';

	/// fr: 'Mise à jour disponible'
	String get updateAvailable => 'Mise à jour disponible';
}

// Path: packs.actions
class Translations$packs$actions$fr {
	Translations$packs$actions$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Télécharger'
	String get download => 'Télécharger';

	/// fr: 'Mettre à jour'
	String get update => 'Mettre à jour';

	/// fr: 'Supprimer'
	String get delete => 'Supprimer';

	/// fr: 'Réessayer'
	String get retry => 'Réessayer';

	/// fr: 'Acheter ce pack'
	String get buy => 'Acheter ce pack';

	/// fr: 'Acheter ce pack — $price'
	String buyWithPrice({required Object price}) => 'Acheter ce pack — ${price}';
}

// Path: packs.progress
class Translations$packs$progress$fr {
	Translations$packs$progress$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Téléchargement… $done/$total'
	String downloading({required Object done, required Object total}) => 'Téléchargement… ${done}/${total}';

	/// fr: 'Vérification de l'intégrité…'
	String get verifying => 'Vérification de l\'intégrité…';

	/// fr: 'Pack prêt hors-ligne'
	String get completed => 'Pack prêt hors-ligne';

	/// fr: 'Échec du téléchargement'
	String get error => 'Échec du téléchargement';
}

// Path: packs.delete
class Translations$packs$delete$fr {
	Translations$packs$delete$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Supprimer ce pack ?'
	String get confirmTitle => 'Supprimer ce pack ?';

	/// fr: 'Le pack sera retiré de l'appareil pour libérer de l'espace. Vous pourrez le retélécharger.'
	String get confirmBody => 'Le pack sera retiré de l\'appareil pour libérer de l\'espace. Vous pourrez le retélécharger.';

	/// fr: 'Annuler'
	String get cancel => 'Annuler';

	/// fr: 'Supprimer'
	String get confirm => 'Supprimer';

	/// fr: 'Espace libéré.'
	String get freed => 'Espace libéré.';
}

// Path: packs.a11y
class Translations$packs$a11y$fr {
	Translations$packs$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Pack $nom, $state'
	String packCard({required Object nom, required Object state}) => 'Pack ${nom}, ${state}';

	/// fr: 'Télécharger le pack $nom'
	String downloadButton({required Object nom}) => 'Télécharger le pack ${nom}';

	/// fr: 'Supprimer le pack $nom'
	String deleteButton({required Object nom}) => 'Supprimer le pack ${nom}';
}

// Path: packs.types
class Translations$packs$types$fr {
	Translations$packs$types$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$packs$types$nord$fr nord = Translations$packs$types$nord$fr.internal(_root);
	late final Translations$packs$types$sud$fr sud = Translations$packs$types$sud$fr.internal(_root);
	late final Translations$packs$types$complet$fr complet = Translations$packs$types$complet$fr.internal(_root);
	late final Translations$packs$types$mam$fr mam = Translations$packs$types$mam$fr.internal(_root);
}

// Path: guides.categories
class Translations$guides$categories$fr {
	Translations$guides$categories$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Ravitaillement'
	String get ravitaillement => 'Ravitaillement';

	/// fr: 'Hébergement'
	String get hebergement => 'Hébergement';

	/// fr: 'Transport'
	String get transport => 'Transport';

	/// fr: 'Services'
	String get services => 'Services';

	/// fr: 'Eau'
	String get eau => 'Eau';

	/// fr: 'Santé'
	String get sante => 'Santé';
}

// Path: guides.intro
class Translations$guides$intro$fr {
	Translations$guides$intro$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Où faire le plein de provisions.'
	String get ravitaillement => 'Où faire le plein de provisions.';

	/// fr: 'Où dormir à l'étape.'
	String get hebergement => 'Où dormir à l\'étape.';

	/// fr: 'Bus, navettes et liaisons.'
	String get transport => 'Bus, navettes et liaisons.';

	/// fr: 'Poste, banque, laverie et autres services.'
	String get services => 'Poste, banque, laverie et autres services.';

	/// fr: 'Points d'eau potable.'
	String get eau => 'Points d\'eau potable.';

	/// fr: 'Pharmacie et soins de proximité.'
	String get sante => 'Pharmacie et soins de proximité.';
}

// Path: guides.a11y
class Translations$guides$a11y$fr {
	Translations$guides$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Guide de $lieu'
	String guideCard({required Object lieu}) => 'Guide de ${lieu}';

	/// fr: 'Section $titre'
	String section({required Object titre}) => 'Section ${titre}';

	/// fr: 'Ouvrir le site de $nom'
	String openSiteButton({required Object nom}) => 'Ouvrir le site de ${nom}';
}

// Path: health.field
class Translations$health$field$fr {
	Translations$health$field$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Groupe sanguin'
	String get bloodType => 'Groupe sanguin';

	/// fr: 'Allergies'
	String get allergies => 'Allergies';

	/// fr: 'Traitements en cours'
	String get treatments => 'Traitements en cours';

	/// fr: 'Médecin traitant'
	String get doctor => 'Médecin traitant';

	/// fr: 'N° assurance / mutuelle'
	String get insurance => 'N° assurance / mutuelle';
}

// Path: health.hint
class Translations$health$hint$fr {
	Translations$health$hint$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Ex : A+, O-, AB+'
	String get bloodType => 'Ex : A+, O-, AB+';

	/// fr: 'Ex : pénicilline, arachides'
	String get allergies => 'Ex : pénicilline, arachides';

	/// fr: 'Ex : Lévothyrox 50 mg/j'
	String get treatments => 'Ex : Lévothyrox 50 mg/j';

	/// fr: 'Ex : Dr Dupont 04 95 xx xx xx'
	String get doctor => 'Ex : Dr Dupont 04 95 xx xx xx';

	/// fr: 'Ex : carte européenne'
	String get insurance => 'Ex : carte européenne';
}

// Path: health.a11y
class Translations$health$a11y$fr {
	Translations$health$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Formulaire d'informations de santé'
	String get form => 'Formulaire d\'informations de santé';

	/// fr: 'Enregistrer les informations de santé'
	String get saveButton => 'Enregistrer les informations de santé';
}

// Path: trailSelection.a11y
class Translations$trailSelection$a11y$fr {
	Translations$trailSelection$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Sentier $nom, $region'
	String trailCard({required Object nom, required Object region}) => 'Sentier ${nom}, ${region}';

	/// fr: 'Sentier actuellement actif'
	String get currentBadge => 'Sentier actuellement actif';

	/// fr: 'Activer le sentier $nom'
	String selectButton({required Object nom}) => 'Activer le sentier ${nom}';
}

// Path: consent.purposes
class Translations$consent$purposes$fr {
	Translations$consent$purposes$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Navigation personnelle'
	String get locationNavigation => 'Navigation personnelle';

	/// fr: 'Utiliser votre position pour la carte et le suivi de votre étape. Reste sur votre appareil.'
	String get locationNavigationDesc => 'Utiliser votre position pour la carte et le suivi de votre étape. Reste sur votre appareil.';

	/// fr: 'Partage social'
	String get socialSharing => 'Partage social';

	/// fr: 'Apparaître dans les classements et le fil communautaire, sous pseudonyme.'
	String get socialSharingDesc => 'Apparaître dans les classements et le fil communautaire, sous pseudonyme.';

	/// fr: 'Signalement public'
	String get publicReporting => 'Signalement public';

	/// fr: 'Publier des signalements (eau, danger, conditions) visibles par les autres randonneurs.'
	String get publicReportingDesc => 'Publier des signalements (eau, danger, conditions) visibles par les autres randonneurs.';

	/// fr: 'Données de santé'
	String get healthData => 'Données de santé';

	/// fr: 'Lire votre fréquence cardiaque (ceinture ou appli santé) pour enrichir votre suivi d'effort.'
	String get healthDataDesc => 'Lire votre fréquence cardiaque (ceinture ou appli santé) pour enrichir votre suivi d\'effort.';
}

// Path: consent.a11y
class Translations$consent$a11y$fr {
	Translations$consent$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: '$purpose, actuellement $state'
	String purposeToggle({required Object purpose, required Object state}) => '${purpose}, actuellement ${state}';

	/// fr: 'Section données de santé, consentement renforcé'
	String get healthSection => 'Section données de santé, consentement renforcé';

	/// fr: 'Ouvrir la politique de confidentialité'
	String get policyButton => 'Ouvrir la politique de confidentialité';
}

// Path: moderation.reasons
class Translations$moderation$reasons$fr {
	Translations$moderation$reasons$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Contenu illégal'
	String get illegal => 'Contenu illégal';

	/// fr: 'Harcèlement ou haine'
	String get harassment => 'Harcèlement ou haine';

	/// fr: 'Spam ou publicité'
	String get spam => 'Spam ou publicité';

	/// fr: 'Information dangereuse ou trompeuse'
	String get dangerous => 'Information dangereuse ou trompeuse';

	/// fr: 'Autre'
	String get other => 'Autre';
}

// Path: moderation.decisions
class Translations$moderation$decisions$fr {
	Translations$moderation$decisions$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Contenu maintenu'
	String get keep => 'Contenu maintenu';

	/// fr: 'Contenu restreint'
	String get restrict => 'Contenu restreint';

	/// fr: 'Contenu retiré'
	String get remove => 'Contenu retiré';
}

// Path: moderation.a11y
class Translations$moderation$a11y$fr {
	Translations$moderation$a11y$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Formulaire de signalement de contenu'
	String get reportForm => 'Formulaire de signalement de contenu';

	/// fr: 'Sélecteur de motif de signalement'
	String get reasonSelector => 'Sélecteur de motif de signalement';

	/// fr: 'Déclaration de bonne foi, $state'
	String goodFaithToggle({required Object state}) => 'Déclaration de bonne foi, ${state}';

	/// fr: 'Envoyer le signalement'
	String get submitReport => 'Envoyer le signalement';

	/// fr: 'Exposé des motifs de la décision de modération'
	String get statementCard => 'Exposé des motifs de la décision de modération';

	/// fr: 'Formulaire de contestation d'une décision'
	String get complaintForm => 'Formulaire de contestation d\'une décision';
}

// Path: weather.alert.storm
class Translations$weather$alert$storm$fr {
	Translations$weather$alert$storm$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Orage prévu'
	String get title => 'Orage prévu';

	/// fr: '$condition. Évitez les crêtes et les zones exposées.'
	String desc({required Object condition}) => '${condition}. Évitez les crêtes et les zones exposées.';
}

// Path: weather.alert.wind
class Translations$weather$alert$wind$fr {
	Translations$weather$alert$wind$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Vent fort'
	String get title => 'Vent fort';

	/// fr: 'Rafales jusqu'à $value km/h. Prudence sur les passages exposés.'
	String desc({required Object value}) => 'Rafales jusqu\'à ${value} km/h. Prudence sur les passages exposés.';
}

// Path: weather.alert.rain
class Translations$weather$alert$rain$fr {
	Translations$weather$alert$rain$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Fortes précipitations'
	String get title => 'Fortes précipitations';

	/// fr: '$value mm prévus. Risque de sentiers glissants et de torrents.'
	String desc({required Object value}) => '${value} mm prévus. Risque de sentiers glissants et de torrents.';
}

// Path: weather.alert.snow
class Translations$weather$alert$snow$fr {
	Translations$weather$alert$snow$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Neige prévue'
	String get title => 'Neige prévue';

	/// fr: '$condition. Équipement adapté nécessaire.'
	String desc({required Object condition}) => '${condition}. Équipement adapté nécessaire.';
}

// Path: weather.alert.uv
class Translations$weather$alert$uv$fr {
	Translations$weather$alert$uv$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'UV très élevé'
	String get title => 'UV très élevé';

	/// fr: 'Indice UV $value. Protection solaire maximale recommandée.'
	String desc({required Object value}) => 'Indice UV ${value}. Protection solaire maximale recommandée.';
}

// Path: weather.alert.fire
class Translations$weather$alert$fire$fr {
	Translations$weather$alert$fire$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Risque incendie'
	String get title => 'Risque incendie';

	/// fr: '$value°C prévus. Risque incendie élevé.'
	String desc({required Object value}) => '${value}°C prévus. Risque incendie élevé.';
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

	/// fr: 'Vous êtes parfaitement préparé(e). Profitez de la randonnée !'
	String get summary => 'Vous êtes parfaitement préparé(e). Profitez de la randonnée !';

	late final Translations$feasibility$recommendations$excellent$tips$fr tips = Translations$feasibility$recommendations$excellent$tips$fr.internal(_root);
}

// Path: gamification.badge.firstStage
class Translations$gamification$badge$firstStage$fr {
	Translations$gamification$badge$firstStage$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Première étape'
	String get titre => 'Première étape';

	/// fr: 'Tu as terminé ta première étape.'
	String get description => 'Tu as terminé ta première étape.';
}

// Path: gamification.badge.firstTrek
class Translations$gamification$badge$firstTrek$fr {
	Translations$gamification$badge$firstTrek$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Première randonnée'
	String get titre => 'Première randonnée';

	/// fr: 'Tu as bouclé ta première randonnée complète.'
	String get description => 'Tu as bouclé ta première randonnée complète.';
}

// Path: gamification.badge.firstSegment
class Translations$gamification$badge$firstSegment$fr {
	Translations$gamification$badge$firstSegment$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Premier segment'
	String get titre => 'Premier segment';

	/// fr: 'Tu as parcouru ton premier segment.'
	String get description => 'Tu as parcouru ton premier segment.';
}

// Path: gamification.badge.elevation5000
class Translations$gamification$badge$elevation5000$fr {
	Translations$gamification$badge$elevation5000$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: '5000 m de dénivelé'
	String get titre => '5000 m de dénivelé';

	/// fr: 'Tu as cumulé 5000 m de dénivelé positif.'
	String get description => 'Tu as cumulé 5000 m de dénivelé positif.';
}

// Path: gamification.badge.tenStages
class Translations$gamification$badge$tenStages$fr {
	Translations$gamification$badge$tenStages$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: '10 étapes'
	String get titre => '10 étapes';

	/// fr: 'Tu as terminé 10 étapes.'
	String get description => 'Tu as terminé 10 étapes.';
}

// Path: gamification.badge.challenger
class Translations$gamification$badge$challenger$fr {
	Translations$gamification$badge$challenger$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Challenger'
	String get titre => 'Challenger';

	/// fr: 'Tu as réussi ton premier défi saisonnier.'
	String get description => 'Tu as réussi ton premier défi saisonnier.';
}

// Path: packs.types.nord
class Translations$packs$types$nord$fr {
	Translations$packs$types$nord$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mare a Mare Nord'
	String get nom => 'Mare a Mare Nord';

	/// fr: 'La moitié nord du sentier, hors-ligne.'
	String get description => 'La moitié nord du sentier, hors-ligne.';
}

// Path: packs.types.sud
class Translations$packs$types$sud$fr {
	Translations$packs$types$sud$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mare a Mare Sud'
	String get nom => 'Mare a Mare Sud';

	/// fr: 'La moitié sud du sentier, hors-ligne.'
	String get description => 'La moitié sud du sentier, hors-ligne.';
}

// Path: packs.types.complet
class Translations$packs$types$complet$fr {
	Translations$packs$types$complet$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mare a Mare Complet'
	String get nom => 'Mare a Mare Complet';

	/// fr: 'Tout le sentier, hors-ligne.'
	String get description => 'Tout le sentier, hors-ligne.';
}

// Path: packs.types.mam
class Translations$packs$types$mam$fr {
	Translations$packs$types$mam$fr.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// fr: 'Mare a Mare'
	String get nom => 'Mare a Mare';

	/// fr: 'Le sentier Mare a Mare, hors-ligne.'
	String get description => 'Le sentier Mare a Mare, hors-ligne.';
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
			'nav.accueil' => 'Accueil',
			'nav.map' => 'Carte',
			'nav.stages' => 'Étapes',
			'nav.planning' => 'Planning',
			'nav.journal' => 'Journal',
			'nav.more' => 'Plus',
			'nav.checklist' => 'Checklist matériel',
			'nav.feasibility' => 'Faisabilité',
			'nav.tips' => 'Conseils randonnée',
			'nav.emergency' => 'Contacts urgence',
			'nav.catalog' => 'Catalogue des sentiers',
			'nav.profile' => 'Profil',
			'nav.settings' => 'Paramètres',
			'nav.trailSelection' => 'Changer de sentier',
			'branding.tagline' => 'Votre compagnon de randonnée',
			'branding.subline' => 'Préparez, marchez, partagez',
			'hub.greeting' => ({required Object name}) => 'Bonjour, ${name} !',
			'hub.greetingFallback' => 'Randonneur',
			'hub.infoTooltip' => 'À propos de ce sentier',
			'hub.profileTooltip' => 'Mon profil',
			'hub.infoSheetBody' => 'Ce sentier vous accompagne à chaque étape : préparez votre itinéraire, préparez votre sac, puis partez en navigation GPS. Chaque fonction est accessible depuis cet écran d\'accueil.',
			'hub.trekCard.activeTitle' => 'Randonnée en cours',
			'hub.trekCard.distanceCovered' => 'Distance parcourue',
			'hub.trekCard.elevationGain' => 'Dénivelé du jour',
			'hub.trekCard.duration' => 'Temps de marche',
			'hub.trekCard.progressLabel' => ({required Object percent}) => '${percent} % du sentier',
			'hub.trekCard.resume' => 'Reprendre la navigation',
			'hub.trekCard.noTrekTitle' => 'Prêt à partir ?',
			'hub.trekCard.noTrekBody' => 'Planifiez votre itinéraire, puis lancez votre randonnée quand vous êtes prêt.',
			'hub.trekCard.plan' => 'Planifier ma randonnée',
			'hub.weather.title' => 'Météo du jour',
			'hub.weather.stub' => 'La météo de votre étape arrive bientôt.',
			'hub.weather.unavailable' => 'Météo indisponible pour le moment.',
			'hub.weather.alertStorm' => 'Alerte orage',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Démarrer la randonnée',
			'hub.sections.prepare' => 'Préparer',
			'hub.sections.hike' => 'Randonner',
			'hub.sections.info' => 'Informations',
			'hub.sections.after' => 'Après la randonnée',
			'hub.cards.feasibility' => 'Faisabilité',
			'hub.cards.feasibilitySub' => 'Évaluez votre niveau',
			'hub.cards.itinerary' => 'Itinéraire',
			'hub.cards.itinerarySub' => 'Le tracé du sentier',
			'hub.cards.programme' => 'Programme',
			'hub.cards.programmeSub' => 'Répartissez vos étapes',
			'hub.cards.checklist' => 'Matériel & sac',
			'hub.cards.checklistSub' => 'Préparez votre sac à dos',
			'hub.cards.training' => 'Préparation physique',
			'hub.cards.trainingSub' => 'Votre programme d\'entraînement',
			'hub.cards.offline' => 'Découvrir des sentiers',
			'hub.cards.offlineSub' => 'Parcourez le catalogue',
			'hub.cards.group' => 'Mon groupe',
			'hub.cards.groupSub' => 'Suivi de vos compagnons',
			'hub.cards.navigation' => 'Navigation',
			'hub.cards.navigationSub' => 'Carte et suivi GPS',
			'hub.cards.journal' => 'Journal',
			'hub.cards.journalSub' => 'Vos notes et souvenirs',
			'hub.cards.accommodations' => 'Hébergements',
			'hub.cards.accommodationsSub' => 'Où dormir à proximité',
			'hub.cards.tips' => 'Fiches conseils',
			'hub.cards.tipsSub' => 'Nos conseils de randonnée',
			'hub.cards.townGuides' => 'Guides des villes',
			'hub.cards.townGuidesSub' => 'Infos pratiques des étapes',
			'hub.cards.recap' => 'Récapitulatif',
			'hub.cards.recapSub' => 'Votre aventure en résumé',
			'hub.cards.diploma' => 'Diplôme',
			'hub.cards.diplomaSub' => 'Votre certificat de fin',
			'hub.fab.feedback' => 'Donner mon avis',
			'hub.fab.sos' => 'SOS',
			'map.title' => 'Carte du sentier',
			'map.loading' => 'Chargement du tracé...',
			'map.noTrack' => 'Aucun tracé disponible',
			'map.viewMap' => 'Voir la carte',
			'stage.distance' => 'Distance',
			'stage.elevation' => 'Dénivelé',
			'stage.elevationGain' => 'Dénivelé positif',
			'stage.elevationLoss' => 'Dénivelé négatif',
			'stage.duration' => 'Durée estimée',
			'stage.description' => 'Description',
			'stage.coordinates' => 'Coordonnées',
			'stage.pois' => 'Points d\'intérêt',
			'stage.difficulty.easy' => 'Facile',
			'stage.difficulty.moderate' => 'Modéré',
			'stage.difficulty.hard' => 'Difficile',
			'stage.difficulty.expert' => 'Expert',
			'stage.difficulty.extreme' => 'Extreme',
			'stage.remaining' => '{distance} km restants',
			'stage.arrived' => 'Vous etes arrive !',
			'stage.altitudeProfile' => 'Profil altimetrique',
			'stage.statistics' => 'Statistiques',
			'stage.loading' => 'Chargement...',
			'stage.loadingList' => 'Chargement des etapes...',
			'stage.dPlus' => 'D+',
			'stage.dMinus' => 'D-',
			'stage.difficultyLabel' => 'Difficulte',
			'trail.stages' => 'Étapes',
			'trail.totalDistance' => 'Distance totale',
			'trail.totalElevation' => 'Dénivelé total',
			'poi.shelter' => 'Refuge',
			'poi.water' => 'Point d\'eau',
			'poi.viewpoint' => 'Point de vue',
			'poi.campsite' => 'Bivouac',
			'poi.restaurant' => 'Restaurant',
			'poi.emergency' => 'Urgence',
			'poi.danger' => 'Danger',
			'poi.shop' => 'Commerce',
			'poi.filter' => 'Filtrer les points d\'intérêt',
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
			'navAlert.offTrackBanner' => ({required Object meters}) => 'Vous vous eloignez du sentier — ${meters} m. Verifiez votre position.',
			'navAlert.offTrackNotifTitle' => 'Vous quittez le sentier',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'Vous vous eloignez du sentier (${meters} m). Verifiez votre position.',
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
			'tracking.dPlus' => 'D+',
			'tracking.stopSaveProgress' => 'La progression sera sauvegardee.',
			'tracking.cancel' => 'Annuler',
			'tracking.stopButton' => 'Stop',
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
			'journal.title' => 'Journal de randonnée',
			'journal.empty' => 'Votre journal est vide',
			'journal.emptySubtitle' => 'Notez vos impressions et souvenirs de randonnée',
			'journal.addNote' => 'Nouvelle note',
			'journal.stage' => 'Étape',
			'journal.yourNote' => 'Votre note',
			'journal.placeholder' => 'Décrivez votre journée de randonnée...',
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
			'weather.today' => 'Aujourd\'hui',
			'weather.tomorrow' => 'Demain',
			'weather.dayPlus2' => 'Après-demain',
			'weather.allStages' => 'Toutes les étapes',
			'weather.noForecast' => 'Aucune prévision disponible.',
			'weather.stageLabel' => ({required Object number}) => 'Étape ${number}',
			'weather.stormAlertsTitle' => 'Alertes orage',
			'weather.stormAlertsToggleOn' => 'Alertes orage activées',
			'weather.stormAlertsToggleOff' => 'Alertes orage désactivées',
			'weather.lastUpdate' => ({required Object date}) => 'Mis à jour ${date}',
			'weather.guideTitle' => 'Comprendre la météo',
			'weather.guideBody' => 'Les prévisions couvrent 7 jours pour chaque étape. Surveillez les alertes orage et vent : en montagne, le temps change vite. En l\'absence de réseau, les dernières données enregistrées sont affichées.',
			'weather.source.api' => 'Données en direct',
			'weather.source.cache' => 'Données enregistrées',
			'weather.source.offline' => 'Hors ligne',
			'weather.source.demo' => 'Données de démonstration',
			'weather.recommendation.ok' => 'Conditions favorables',
			'weather.recommendation.watch' => 'Vigilance recommandée',
			'weather.recommendation.danger' => 'Conditions défavorables',
			'weather.alert.storm.title' => 'Orage prévu',
			'weather.alert.storm.desc' => ({required Object condition}) => '${condition}. Évitez les crêtes et les zones exposées.',
			'weather.alert.wind.title' => 'Vent fort',
			'weather.alert.wind.desc' => ({required Object value}) => 'Rafales jusqu\'à ${value} km/h. Prudence sur les passages exposés.',
			'weather.alert.rain.title' => 'Fortes précipitations',
			'weather.alert.rain.desc' => ({required Object value}) => '${value} mm prévus. Risque de sentiers glissants et de torrents.',
			'weather.alert.snow.title' => 'Neige prévue',
			'weather.alert.snow.desc' => ({required Object condition}) => '${condition}. Équipement adapté nécessaire.',
			'weather.alert.uv.title' => 'UV très élevé',
			'weather.alert.uv.desc' => ({required Object value}) => 'Indice UV ${value}. Protection solaire maximale recommandée.',
			'weather.alert.fire.title' => 'Risque incendie',
			'weather.alert.fire.desc' => ({required Object value}) => '${value}°C prévus. Risque incendie élevé.',
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
			'diploma.title' => 'Diplôme de randonnée',
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
			'diploma.recapDuration' => '{days} jours de randonnée',
			'diploma.recapMapTrace' => 'Trace du parcours',
			'diploma.recapNoMap' => 'Trace non disponible',
			'diploma.recapJournalEntries' => '{count} notes de journal',
			'diploma.downloadPdf' => 'Telecharger le diplome PDF',
			'diploma.lockedTitle' => 'Diplome verrouille',
			'diploma.lockedMessage' => 'Terminez l integralite de votre parcours pour debloquer votre diplome de finisher.',
			'diploma.labelIntegral' => 'Parcours integral',
			'diploma.labelPartial' => 'Parcours partiel',
			'notifications.morningReminder' => 'Rappel du matin',
			'notifications.weatherAlerts' => 'Alertes météo',
			'notifications.countdown' => 'Rappel J-2',
			'notifications.countdownDesc' => 'Notification 2 jours avant le départ',
			'notifications.schedulerCountdownTitle' => 'Votre randonnée approche !',
			'notifications.schedulerCountdownBody' => 'Depart dans 2 jours. Verifiez votre checklist et la meteo.',
			'notifications.schedulerDailyTitle' => 'Bonne journee de randonnée !',
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
			'settings.offTrackAlerts' => 'Alerte hors-trace',
			'settings.offTrackAlertsDesc' => 'Notification + vibration si vous quittez le sentier',
			'settings.version' => 'Version',
			'settings.versionLabel' => 'Version de l\'application',
			'appearance.title' => 'Apparence',
			'appearance.subtitle' => 'Choisissez l’habillage de l’application',
			'appearance.skinSentierVivant' => 'Sentier Vivant',
			'appearance.skinSentierVivantDesc' => 'Moderne et coloré, la couleur du sentier en vedette',
			'appearance.skinTopographique' => 'Topographique',
			'appearance.skinTopographiqueDesc' => 'Style carte d’état-major, données en avant',
			'appearance.skinGrandAir' => 'Grand Air',
			'appearance.skinGrandAirDesc' => 'Photos plein écran, ambiance carnet d’aventure',
			'appearance.unavailableOnTrail' => 'Indisponible sur ce sentier',
			'appearance.changeSkin' => 'Changer de peau',
			'appearance.selected' => 'Sélectionné',
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
			'auth.anonymous' => 'Randonneur sans compte',
			'auth.connectedVia' => 'Connecté via',
			'auth.signInGoogle' => 'Se connecter avec Google',
			'auth.signInGoogleDesc' => 'Pour sauvegarder votre progression',
			'auth.signOut' => 'Se déconnecter',
			'auth.signOutDesc' => 'Revenir au mode sans compte',
			'auth.signOutConfirm' => 'Se déconnecter ?',
			'auth.signOutMessage' => 'Vous reviendrez au mode sans compte. Vos données locales sont conservées.',
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
			'feasibility.answers.experienceD' => 'Randonneur expérimenté, GR déjà réalisés',
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
			'feasibility.recommendations.excellent.summary' => 'Vous êtes parfaitement préparé(e). Profitez de la randonnée !',
			'feasibility.recommendations.excellent.tips.tip1' => 'Restez à l’écoute de votre corps',
			'feasibility.recommendations.excellent.tips.tip2' => 'Partagez votre expérience avec les randonneurs',
			'feasibility.recommendations.excellent.tips.tip3' => 'Documentez votre aventure dans le journal',
			'tips.carouselTitle' => 'Conseils randonnée',
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
			'catalog.title' => 'Catalogue des sentiers',
			'catalog.enter' => 'Entrer',
			'catalog.mustDownload' => 'Téléchargez ce sentier pour l\'explorer.',
			'catalog.emptyTitle' => 'Aucun sentier disponible',
			'catalog.emptySubtitle' => 'Aucun sentier n\'est encore proposé au catalogue.',
			'catalog.a11y.enterButton' => ({required Object nom}) => 'Entrer dans le sentier ${nom}',
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
			'onboarding.welcomeSubtitle' => 'Votre compagnon de randonnée hors ligne : carte, navigation GPS, planning et journal de randonnée.',
			'onboarding.languageTitle' => 'Choisissez votre langue',
			_ => null,
		} ?? switch (path) {
			'onboarding.languageSubtitle' => 'Vous pourrez la modifier à tout moment dans les paramètres.',
			'onboarding.downloadTitle' => 'Téléchargez votre premier sentier',
			'onboarding.downloadSubtitle' => 'Parcourez le catalogue et téléchargez un sentier pour l\'utiliser entièrement hors ligne.',
			'onboarding.browseCatalog' => 'Parcourir le catalogue',
			'monetization.demoBanner' => 'Mode démo — touchez pour débloquer',
			'monetization.paywallTitle' => 'Débloquez cette randonnée',
			'monetization.paywallBody' => 'Le mode gratuit permet de préparer votre randonnée avec publicité. Le premium débloque tout, sans pub.',
			'monetization.featureMap' => 'Carte hors ligne + GPS + suivi en direct',
			'monetization.featureJournal' => 'Journal de bord complet',
			'monetization.featureDiploma' => 'Diplôme de fin de randonnée',
			'monetization.featureFollowers' => '2 suiveurs gratuits',
			'monetization.featureNoAds' => 'Zéro publicité',
			'monetization.buyCta' => 'Débloquer cette randonnée',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Débloquer cette randonnée — ${price} €',
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
			'social.feedTitle' => 'Fil d\'activité',
			'social.empty' => 'Aucune activité pour le moment.',
			'social.kudos' => 'Encourager',
			'social.kudosCount' => ({required Object n}) => '${n} encouragement(s)',
			'social.report' => 'Signaler',
			'social.reportTitle' => 'Signaler cette publication',
			'social.reportReasonLabel' => 'Motif du signalement',
			'social.reasonSpam' => 'Spam ou publicité',
			'social.reasonAbuse' => 'Contenu abusif ou haineux',
			'social.reasonOther' => 'Autre',
			'social.reportSend' => 'Envoyer le signalement',
			'social.reportSent' => 'Signalement envoyé. Il sera examiné par notre équipe.',
			'social.syncPending' => 'En attente de synchronisation',
			'social.synced' => 'Synchronisé',
			'social.activitySegment' => 'a réalisé un segment',
			'social.activityBadge' => 'a obtenu un badge',
			'social.activityDefi' => 'a progressé dans un défi',
			'gamification.galleryTitle' => 'Mes badges',
			'gamification.obtained' => 'Obtenu',
			'gamification.locked' => 'Verrouillé',
			'gamification.tierDebutant' => 'Débutant',
			'gamification.tierExpert' => 'Expert',
			'gamification.badge.firstStage.titre' => 'Première étape',
			'gamification.badge.firstStage.description' => 'Tu as terminé ta première étape.',
			'gamification.badge.firstTrek.titre' => 'Première randonnée',
			'gamification.badge.firstTrek.description' => 'Tu as bouclé ta première randonnée complète.',
			'gamification.badge.firstSegment.titre' => 'Premier segment',
			'gamification.badge.firstSegment.description' => 'Tu as parcouru ton premier segment.',
			'gamification.badge.elevation5000.titre' => '5000 m de dénivelé',
			'gamification.badge.elevation5000.description' => 'Tu as cumulé 5000 m de dénivelé positif.',
			'gamification.badge.tenStages.titre' => '10 étapes',
			'gamification.badge.tenStages.description' => 'Tu as terminé 10 étapes.',
			'gamification.badge.challenger.titre' => 'Challenger',
			'gamification.badge.challenger.description' => 'Tu as réussi ton premier défi saisonnier.',
			'gamification.defi.screenTitle' => 'Défis',
			'gamification.defi.inProgress' => 'En cours',
			'gamification.defi.progressLabel' => ({required Object current, required Object target}) => 'Progression : ${current} / ${target}',
			'gamification.defi.rankingTitle' => 'Classement du défi',
			'gamification.defi.pseudonymNotice' => 'Classement par tranche, avec des pseudonymes. Aucune donnée personnelle directe n\'est affichée.',
			'gamification.defi.notEnoughParticipants' => 'Pas assez de participants pour publier ce classement.',
			'gamification.defi.noDefi' => 'Aucun défi en cours pour le moment.',
			'shareVisibility.title' => 'Partage et visibilité',
			'shareVisibility.intro' => 'Par défaut, rien n\'est partagé. Active ci-dessous, finalité par finalité, ce que tu veux rendre visible.',
			'shareVisibility.consentLink' => 'Gérer mon consentement (confidentialité)',
			'shareVisibility.stageResults' => 'Partager mes résultats d\'étape',
			'shareVisibility.stageResultsDesc' => 'Une carte pseudonyme (sans données personnelles directes).',
			'shareVisibility.leaderboard' => 'Apparaître dans les classements',
			'shareVisibility.leaderboardDesc' => 'Classement par tranche, avec un pseudonyme.',
			'shareVisibility.activityFeed' => 'Publier au fil d\'activité',
			'shareVisibility.activityFeedDesc' => 'Tes activités apparaissent dans le fil, sous pseudonyme.',
			'shareVisibility.shareTitle' => 'Partager cette étape',
			'shareVisibility.shareButton' => 'Partager',
			'shareVisibility.privateNotice' => 'Le partage est désactivé. Active-le dans Partage et visibilité.',
			'shareVisibility.shared' => 'Carte prête à partager.',
			'waypoints.types.eau' => 'Eau',
			'waypoints.types.ravitaillement' => 'Ravitaillement',
			'waypoints.types.danger' => 'Danger',
			'waypoints.types.camp' => 'Bivouac',
			'waypoints.types.connectivite' => 'Connectivité',
			'waypoints.types.jonction' => 'Jonction',
			'waypoints.filters.title' => 'Filtrer les waypoints',
			'waypoints.filters.showAll' => 'Tout afficher',
			'waypoints.filters.hideAll' => 'Tout masquer',
			'waypoints.filters.recentConditionOnly' => 'Condition récente uniquement',
			'waypoints.detail.conditionsTitle' => 'Conditions terrain',
			'waypoints.detail.noComments' => 'Aucune condition signalée pour le moment.',
			'waypoints.detail.commentsError' => 'Conditions indisponibles.',
			'waypoints.detail.report' => 'Signaler',
			'waypoints.detail.reportAck' => 'Signalement enregistré. Il sera examiné après synchronisation.',
			'waypoints.detail.pendingSync' => 'En attente de synchronisation',
			'waypoints.freshness.justNow' => 'mis à jour à l’instant',
			'waypoints.freshness.minutes' => ({required Object n}) => 'mis à jour il y a ${n} min',
			'waypoints.freshness.hours' => ({required Object n}) => 'mis à jour il y a ${n} h',
			'waypoints.freshness.days' => ({required Object n}) => 'mis à jour il y a ${n} j',
			'waypoints.contribution.titleWaypoint' => 'Ajouter un point',
			'waypoints.contribution.titleComment' => 'Signaler une condition',
			'waypoints.contribution.chooseType' => 'Type de point',
			'waypoints.contribution.titleField' => 'Titre du point',
			'waypoints.contribution.conditionPrompt' => 'Décrivez la condition observée',
			'waypoints.contribution.commentField' => 'Votre observation',
			'waypoints.contribution.conditionField' => 'État (optionnel)',
			'waypoints.contribution.conditionHelper' => 'ex : eau à sec, eau coule bien, passage glissant',
			'waypoints.contribution.latencyBanner' => 'Sera publié à la prochaine synchronisation réseau.',
			'waypoints.contribution.submit' => 'Enregistrer',
			'waypoints.contribution.savedTitle' => 'Contribution enregistrée',
			'waypoints.contribution.savedPendingSync' => 'Elle sera publiée dès le retour du réseau.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} en attente de synchronisation',
			'waypoints.contribution.close' => 'Fermer',
			'waypoints.contribution.emptyTitle' => 'Indiquez un titre pour le point.',
			'waypoints.contribution.emptyComment' => 'Saisissez votre observation.',
			'waypoints.contribution.noLocation' => 'Position GPS indisponible. Réessayez sous le ciel ouvert.',
			'waypoints.contribution.error' => 'Enregistrement impossible pour le moment.',
			'packs.title' => 'Packs sentier',
			'packs.subtitle' => 'Téléchargez un pack pour randonner 100% hors-ligne.',
			'packs.alaCarteNote' => 'À la carte : achetez seulement le pack qu\'il vous faut, pas d\'abonnement.',
			'packs.size' => ({required Object mo}) => '${mo} Mo',
			'packs.states.notDownloaded' => 'Non téléchargé',
			'packs.states.downloaded' => 'Téléchargé',
			'packs.states.updateAvailable' => 'Mise à jour disponible',
			'packs.actions.download' => 'Télécharger',
			'packs.actions.update' => 'Mettre à jour',
			'packs.actions.delete' => 'Supprimer',
			'packs.actions.retry' => 'Réessayer',
			'packs.actions.buy' => 'Acheter ce pack',
			'packs.actions.buyWithPrice' => ({required Object price}) => 'Acheter ce pack — ${price}',
			'packs.progress.downloading' => ({required Object done, required Object total}) => 'Téléchargement… ${done}/${total}',
			'packs.progress.verifying' => 'Vérification de l\'intégrité…',
			'packs.progress.completed' => 'Pack prêt hors-ligne',
			'packs.progress.error' => 'Échec du téléchargement',
			'packs.delete.confirmTitle' => 'Supprimer ce pack ?',
			'packs.delete.confirmBody' => 'Le pack sera retiré de l\'appareil pour libérer de l\'espace. Vous pourrez le retélécharger.',
			'packs.delete.cancel' => 'Annuler',
			'packs.delete.confirm' => 'Supprimer',
			'packs.delete.freed' => 'Espace libéré.',
			'packs.empty' => 'Aucun pack disponible pour ce sentier.',
			'packs.a11y.packCard' => ({required Object nom, required Object state}) => 'Pack ${nom}, ${state}',
			'packs.a11y.downloadButton' => ({required Object nom}) => 'Télécharger le pack ${nom}',
			'packs.a11y.deleteButton' => ({required Object nom}) => 'Supprimer le pack ${nom}',
			'packs.types.nord.nom' => 'Mare a Mare Nord',
			'packs.types.nord.description' => 'La moitié nord du sentier, hors-ligne.',
			'packs.types.sud.nom' => 'Mare a Mare Sud',
			'packs.types.sud.description' => 'La moitié sud du sentier, hors-ligne.',
			'packs.types.complet.nom' => 'Mare a Mare Complet',
			'packs.types.complet.description' => 'Tout le sentier, hors-ligne.',
			'packs.types.mam.nom' => 'Mare a Mare',
			'packs.types.mam.description' => 'Le sentier Mare a Mare, hors-ligne.',
			'guides.title' => 'Guides des villes',
			'guides.subtitle' => 'Infos pratiques des villes et villages, consultables hors-ligne.',
			'guides.sectionsCount' => ({required Object n}) => '${n} rubriques pratiques',
			'guides.empty' => 'Aucun guide disponible pour ce sentier.',
			'guides.noItems' => 'Aucune information dans cette section pour le moment.',
			'guides.facilitatorNote' => 'StepWays vous oriente vers les prestataires. Réservation et paiement se font sur leur site : rien dans l\'application.',
			'guides.openSite' => 'Voir le site',
			'guides.cannotOpen' => 'Impossible d\'ouvrir ce lien sur cet appareil.',
			'guides.categories.ravitaillement' => 'Ravitaillement',
			'guides.categories.hebergement' => 'Hébergement',
			'guides.categories.transport' => 'Transport',
			'guides.categories.services' => 'Services',
			'guides.categories.eau' => 'Eau',
			'guides.categories.sante' => 'Santé',
			'guides.intro.ravitaillement' => 'Où faire le plein de provisions.',
			'guides.intro.hebergement' => 'Où dormir à l\'étape.',
			'guides.intro.transport' => 'Bus, navettes et liaisons.',
			'guides.intro.services' => 'Poste, banque, laverie et autres services.',
			'guides.intro.eau' => 'Points d\'eau potable.',
			'guides.intro.sante' => 'Pharmacie et soins de proximité.',
			'guides.a11y.guideCard' => ({required Object lieu}) => 'Guide de ${lieu}',
			'guides.a11y.section' => ({required Object titre}) => 'Section ${titre}',
			'guides.a11y.openSiteButton' => ({required Object nom}) => 'Ouvrir le site de ${nom}',
			'health.title' => 'Informations santé',
			'health.privacyBanner' => 'Ces données restent sur votre téléphone. Elles ne sont jamais envoyées sur internet.',
			'health.field.bloodType' => 'Groupe sanguin',
			'health.field.allergies' => 'Allergies',
			'health.field.treatments' => 'Traitements en cours',
			'health.field.doctor' => 'Médecin traitant',
			'health.field.insurance' => 'N° assurance / mutuelle',
			'health.hint.bloodType' => 'Ex : A+, O-, AB+',
			'health.hint.allergies' => 'Ex : pénicilline, arachides',
			'health.hint.treatments' => 'Ex : Lévothyrox 50 mg/j',
			'health.hint.doctor' => 'Ex : Dr Dupont 04 95 xx xx xx',
			'health.hint.insurance' => 'Ex : carte européenne',
			'health.save' => 'Sauvegarder',
			'health.saving' => 'Sauvegarde…',
			'health.saved' => 'Informations sauvegardées',
			'health.emergencyHint' => 'En cas d\'urgence, montrez cet écran aux secours.',
			'health.entryTitle' => 'Mes infos santé',
			'health.entrySubtitle' => 'À montrer aux secours (restées sur le téléphone)',
			'health.a11y.form' => 'Formulaire d\'informations de santé',
			'health.a11y.saveButton' => 'Enregistrer les informations de santé',
			'trailSelection.title' => 'Changer de sentier',
			'trailSelection.subtitle' => 'Choisis le sentier a explorer. Tout l app (carte, etapes, points d interet, packs, guides) suit ta selection.',
			'trailSelection.current' => 'Sentier actif',
			'trailSelection.select' => 'Choisir ce sentier',
			'trailSelection.selected' => 'Sentier selectionne',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} etapes - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Sentier ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Sentier actuellement actif',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Activer le sentier ${nom}',
			'consent.onboardingTitle' => 'Votre vie privée, votre choix',
			'consent.onboardingIntro' => 'Rien n\'est activé par défaut. Choisissez, finalité par finalité, ce que vous autorisez. Vous pourrez tout modifier à tout moment dans les réglages.',
			'consent.settingsTitle' => 'Confidentialité et consentement',
			'consent.settingsIntro' => 'Gérez ici chaque autorisation. Vous pouvez retirer un consentement à tout moment, sans conséquence sur le reste.',
			'consent.settingsEntry' => 'Confidentialité et consentement',
			'consent.settingsEntryDesc' => 'Gérer mes autorisations (géolocalisation, partage, santé)',
			'consent.purposes.locationNavigation' => 'Navigation personnelle',
			'consent.purposes.locationNavigationDesc' => 'Utiliser votre position pour la carte et le suivi de votre étape. Reste sur votre appareil.',
			'consent.purposes.socialSharing' => 'Partage social',
			'consent.purposes.socialSharingDesc' => 'Apparaître dans les classements et le fil communautaire, sous pseudonyme.',
			'consent.purposes.publicReporting' => 'Signalement public',
			'consent.purposes.publicReportingDesc' => 'Publier des signalements (eau, danger, conditions) visibles par les autres randonneurs.',
			'consent.purposes.healthData' => 'Données de santé',
			'consent.purposes.healthDataDesc' => 'Lire votre fréquence cardiaque (ceinture ou appli santé) pour enrichir votre suivi d\'effort.',
			'consent.healthBadge' => 'Donnée sensible',
			'consent.healthWarning' => 'La fréquence cardiaque est une donnée de santé (article 9 RGPD). Ce consentement est demandé séparément et n\'est jamais regroupé avec les autres. Vos données de santé ne sont pas envoyées sur nos serveurs.',
			'consent.granted' => 'Autorisé',
			'consent.denied' => 'Non autorisé',
			'consent.grant' => 'Autoriser',
			'consent.revoke' => 'Retirer',
			'consent.decidedOn' => ({required Object date}) => 'Choix du ${date}',
			'consent.notDecided' => 'En attente de votre choix',
			'consent.acceptSelected' => 'Valider mes choix',
			'consent.declineAll' => 'Tout refuser',
			'consent.continueLabel' => 'Continuer',
			'consent.privacyPolicyLink' => 'Lire la politique de confidentialité',
			'consent.reviewNeeded' => 'Notre politique a évolué : merci de revoir vos choix.',
			'consent.a11y.purposeToggle' => ({required Object purpose, required Object state}) => '${purpose}, actuellement ${state}',
			'consent.a11y.healthSection' => 'Section données de santé, consentement renforcé',
			'consent.a11y.policyButton' => 'Ouvrir la politique de confidentialité',
			'moderation.reportTitle' => 'Signaler ce contenu',
			'moderation.reportIntro' => 'Aidez-nous à garder la communauté saine. Indiquez pourquoi ce contenu vous semble illicite. Votre signalement sera examiné par un modérateur.',
			'moderation.reasonLabel' => 'Motif du signalement',
			'moderation.reasons.illegal' => 'Contenu illégal',
			'moderation.reasons.harassment' => 'Harcèlement ou haine',
			'moderation.reasons.spam' => 'Spam ou publicité',
			'moderation.reasons.dangerous' => 'Information dangereuse ou trompeuse',
			'moderation.reasons.other' => 'Autre',
			'moderation.detailsLabel' => 'Précisez (facultatif)',
			'moderation.detailsHint' => 'Ajoutez un commentaire pour aider le modérateur.',
			'moderation.contactLabel' => 'Votre adresse e-mail',
			'moderation.contactHint' => 'Pour vous tenir informé du traitement (article 16).',
			'moderation.goodFaithLabel' => 'Je déclare de bonne foi que ces informations sont exactes.',
			'moderation.submit' => 'Envoyer le signalement',
			'moderation.submitting' => 'Envoi en cours…',
			'moderation.sent' => 'Signalement envoyé. Merci, un modérateur va l\'examiner.',
			'moderation.errorRequired' => 'Veuillez compléter le motif, votre e-mail et la déclaration de bonne foi.',
			'moderation.errorGeneric' => 'Le signalement n\'a pas pu être envoyé. Réessayez.',
			'moderation.cancel' => 'Annuler',
			'moderation.reasonsTitle' => 'Pourquoi ce contenu a-t-il été restreint ?',
			'moderation.reasonsIntro' => 'Conformément à l\'article 17, voici la raison de la décision de modération concernant votre contenu.',
			'moderation.decisionLabel' => 'Décision',
			'moderation.decisions.keep' => 'Contenu maintenu',
			'moderation.decisions.restrict' => 'Contenu restreint',
			'moderation.decisions.remove' => 'Contenu retiré',
			'moderation.noStatement' => 'Aucune restriction n\'a été appliquée à vos contenus.',
			'moderation.complaintAction' => 'Contester cette décision',
			'moderation.complaintTitle' => 'Contester une décision',
			'moderation.complaintIntro' => 'Vous pouvez contester une décision de modération. Expliquez pourquoi vous estimez la décision injustifiée (article 20).',
			'moderation.complaintExposeLabel' => 'Votre contestation',
			'moderation.complaintExposeHint' => 'Décrivez les raisons de votre contestation.',
			'moderation.complaintSubmit' => 'Envoyer la contestation',
			'moderation.complaintSent' => 'Contestation enregistrée. Elle sera examinée.',
			'moderation.complaintEmpty' => 'Veuillez expliquer votre contestation.',
			'moderation.a11y.reportForm' => 'Formulaire de signalement de contenu',
			'moderation.a11y.reasonSelector' => 'Sélecteur de motif de signalement',
			'moderation.a11y.goodFaithToggle' => ({required Object state}) => 'Déclaration de bonne foi, ${state}',
			'moderation.a11y.submitReport' => 'Envoyer le signalement',
			'moderation.a11y.statementCard' => 'Exposé des motifs de la décision de modération',
			'moderation.a11y.complaintForm' => 'Formulaire de contestation d\'une décision',
			'bootstrap.loading' => 'Préparation de votre randonnée…',
			'recap.title' => 'Mon aventure',
			'recap.lockedTitle' => 'Disponible a la fin du trek',
			'recap.lockedMessage' => 'Terminez ou abandonnez votre parcours pour retrouver le recapitulatif de votre aventure.',
			'recap.finisherTitle' => 'Felicitations !',
			'recap.finisherSubtitle' => 'Vous avez termine votre parcours',
			'recap.partialTitle' => 'Votre parcours partiel',
			'recap.partialSubtitle' => 'Votre aventure reste enregistree',
			'recap.statsSection' => 'Statistiques',
			'recap.traceSection' => 'Votre trace',
			'recap.noTrace' => 'Aucune trace GPS disponible',
			'recap.stages' => '{done} / {total} etapes parcourues',
			'recap.distance' => '{km} km parcourus',
			'recap.elevation' => '{meters} m de denivele positif',
			'recap.duration' => '{days} jours',
			'recap.dates' => 'Du {start} au {end}',
			'recap.viewDiploma' => 'Voir mon diplome',
			'recap.noData' => 'Aucune donnee de parcours a afficher pour le moment.',
			_ => null,
		};
	}
}
