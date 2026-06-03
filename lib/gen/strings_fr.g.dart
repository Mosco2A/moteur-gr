///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsFr with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsFr({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
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
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsFr _root = this; // ignore: unused_field

	@override 
	TranslationsFr $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsFr(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$map$fr map = _Translations$map$fr._(_root);
	@override late final _Translations$stage$fr stage = _Translations$stage$fr._(_root);
	@override late final _Translations$trail$fr trail = _Translations$trail$fr._(_root);
	@override late final _Translations$poi$fr poi = _Translations$poi$fr._(_root);
	@override late final _Translations$gps$fr gps = _Translations$gps$fr._(_root);
	@override late final _Translations$planning$fr planning = _Translations$planning$fr._(_root);
	@override late final _Translations$tracking$fr tracking = _Translations$tracking$fr._(_root);
	@override late final _Translations$checklist$fr checklist = _Translations$checklist$fr._(_root);
	@override late final _Translations$journal$fr journal = _Translations$journal$fr._(_root);
	@override late final _Translations$weather$fr weather = _Translations$weather$fr._(_root);
	@override late final _Translations$share$fr share = _Translations$share$fr._(_root);
	@override late final _Translations$diploma$fr diploma = _Translations$diploma$fr._(_root);
	@override late final _Translations$notifications$fr notifications = _Translations$notifications$fr._(_root);
	@override late final _Translations$settings$fr settings = _Translations$settings$fr._(_root);
	@override late final _Translations$feedback$fr feedback = _Translations$feedback$fr._(_root);
	@override late final _Translations$auth$fr auth = _Translations$auth$fr._(_root);
	@override late final _Translations$feasibility$fr feasibility = _Translations$feasibility$fr._(_root);
	@override late final _Translations$tips$fr tips = _Translations$tips$fr._(_root);
	@override late final _Translations$goodies$fr goodies = _Translations$goodies$fr._(_root);
}

// Path: map
class _Translations$map$fr implements Translations$map$en {
	_Translations$map$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Carte du sentier';
	@override String get loading => 'Chargement du tracÃ©...';
	@override String get noTrack => 'Aucun tracÃ© disponible';
	@override String get viewMap => 'Voir la carte';
}

// Path: stage
class _Translations$stage$fr implements Translations$stage$en {
	_Translations$stage$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distance';
	@override String get elevation => 'DÃ©nivelÃ©';
	@override String get elevationGain => 'DÃ©nivelÃ© positif';
	@override String get elevationLoss => 'DÃ©nivelÃ© nÃ©gatif';
	@override String get duration => 'DurÃ©e estimÃ©e';
	@override String get description => 'Description';
	@override String get coordinates => 'CoordonnÃ©es';
	@override String get pois => 'Points d\'intÃ©rÃªt';
	@override late final _Translations$stage$difficulty$fr difficulty = _Translations$stage$difficulty$fr._(_root);
	@override String get remaining => '{distance} km restants';
	@override String get arrived => 'Vous etes arrive !';
}

// Path: trail
class _Translations$trail$fr implements Translations$trail$en {
	_Translations$trail$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Ãtapes';
	@override String get totalDistance => 'Distance totale';
	@override String get totalElevation => 'DÃ©nivelÃ© total';
}

// Path: poi
class _Translations$poi$fr implements Translations$poi$en {
	_Translations$poi$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Refuge';
	@override String get water => 'Point d\'eau';
	@override String get viewpoint => 'Point de vue';
	@override String get campsite => 'Bivouac';
	@override String get restaurant => 'Restaurant';
	@override String get emergency => 'Urgence';
	@override String get danger => 'Danger';
	@override String get shop => 'Commerce';
	@override String get filter => 'Filtrer les points d\'intÃ©rÃªt';
	@override String get altitude => 'Altitude';
	@override String get hours => 'Horaires';
}

// Path: gps
class _Translations$gps$fr implements Translations$gps$en {
	_Translations$gps$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get permission => 'Autorisation GPS requise';
	@override String get denied => 'Acces a la localisation refuse';
	@override String get disabled => 'Service de localisation desactive';
	@override String get offTrack => 'Hors trace';
	@override String get centerOnMe => 'Centrer sur ma position';
}

// Path: planning
class _Translations$planning$fr implements Translations$planning$en {
	_Translations$planning$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planning';
	@override String get duration => 'Durée';
	@override String get days => 'jours';
	@override String get day => 'Jour';
	@override String get restDay => 'Jour de repos';
	@override String get totalDistance => 'Distance totale';
	@override String get totalElevation => 'Dénivelé total';
	@override String get estimatedTime => 'Durée estimée';
	@override String get stages => 'Étapes';
	@override String get plan => 'Planifier';
}

// Path: tracking
class _Translations$tracking$fr implements Translations$tracking$en {
	_Translations$tracking$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get start => 'Demarrer';
	@override String get pause => 'Pause';
	@override String get resume => 'Reprendre';
	@override String get stop => 'Arreter';
	@override String get distance => 'Distance';
	@override String get elevation => 'Denivele';
	@override String get speed => 'Vitesse';
	@override String get time => 'Temps';
	@override String get confirmStop => 'Arreter le tracking ?';
}

// Path: checklist
class _Translations$checklist$fr implements Translations$checklist$en {
	_Translations$checklist$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Checklist matériel';
	@override String get subtitle => 'Préparez votre sac à dos';
	@override String get progress => '{checked}/{total} préparés';
	@override String get complete => 'Checklist complète !';
	@override String get reset => 'Réinitialiser';
	@override String get resetConfirm => 'Réinitialiser la checklist ?';
	@override String get resetDescription => 'Tous les éléments seront décochés.';
	@override String get cancel => 'Annuler';
	@override String get confirm => 'Confirmer';
	@override late final _Translations$checklist$categories$fr categories = _Translations$checklist$categories$fr._(_root);
	@override late final _Translations$checklist$items$fr items = _Translations$checklist$items$fr._(_root);
	@override String get essential => 'Essentiel';
}

// Path: journal
class _Translations$journal$fr implements Translations$journal$en {
	_Translations$journal$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Journal de trek';
	@override String get empty => 'Votre journal est vide';
	@override String get emptySubtitle => 'Notez vos impressions et souvenirs de trek';
	@override String get addNote => 'Nouvelle note';
	@override String get stage => 'Étape';
	@override String get yourNote => 'Votre note';
	@override String get placeholder => 'Décrivez votre journée de trek...';
	@override String get save => 'Enregistrer';
	@override String get cancel => 'Annuler';
	@override String get delete => 'Supprimer';
	@override String get photoLimit => 'Limite de 3 photos par jour atteinte';
	@override String get photoTooBig => 'Photo trop volumineuse (max 500 Ko)';
}

// Path: weather
class _Translations$weather$fr implements Translations$weather$en {
	_Translations$weather$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Météo';
	@override String get loading => 'Chargement de la météo...';
	@override String get offline => 'Pas de connexion. Données météo indisponibles.';
	@override String get error => 'Impossible de charger la météo.';
	@override String get cached => 'Données en cache';
	@override String get alerts => 'alertes météo';
	@override String get refresh => 'Actualiser';
	@override String get temperature => 'Température';
	@override String get precipitation => 'Précipitations';
	@override String get wind => 'Vent';
	@override String get uv => 'Indice UV';
	@override String get fireRisk => 'Risque incendie';
	@override String get fireRiskDesc => 'Risque incendie eleve. Consultez les consignes de securite.';
	@override String get fireSafetyTips => 'Consignes incendie';
	@override String get alertCount => 'alerte';
	@override String get alertCountPlural => 'alertes';
}

// Path: share
class _Translations$share$fr implements Translations$share$en {
	_Translations$share$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Partager';
	@override String get generating => 'Génération...';
	@override String get share => 'Partager';
	@override String get error => 'Erreur lors de la génération';
	@override String get errorShare => 'Erreur lors du partage';
	@override String get preview => 'Aperçu';
	@override String get chooseTemplate => 'Choisir un template';
	@override String get templateStats => 'Statistiques';
	@override String get templateJourney => 'Parcours';
	@override String get templateStage => 'Étape';
}

// Path: diploma
class _Translations$diploma$fr implements Translations$diploma$en {
	_Translations$diploma$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diplôme de trek';
	@override String get yourName => 'Votre nom';
	@override String get namePlaceholder => 'Entrez votre nom...';
	@override String get generatePdf => 'Générer le PDF';
	@override String get certifies => 'Certifie que';
	@override String get completed => 'a parcouru le';
	@override String get pdfTitle => 'DIPLÔME';
	@override String get pdfSubtitle => 'Certificat d\'accomplissement';
	@override String get pdfStages => '{count} étapes';
	@override String get pdfDistance => '{km} km parcourus';
	@override String get pdfElevation => '{meters} m de dénivelé positif';
	@override String get pdfDuration => 'en {days} jours';
	@override String get pdfFrom => 'Du';
	@override String get pdfTo => 'au';
	@override String get pdfIssuedOn => 'Délivré le {date}';
	@override String get recapTitle => 'Votre aventure';
	@override String get recapJournalPhotos => 'Photos du journal';
	@override String get recapNoPhotos => 'Aucune photo dans le journal';
	@override String get recapStats => 'Statistiques';
	@override String get recapStages => '{count} etapes franchies';
	@override String get recapDistance => '{km} km parcourus';
	@override String get recapElevation => '{meters} m de denivele';
	@override String get recapDuration => '{days} jours de trek';
	@override String get recapMapTrace => 'Trace du parcours';
	@override String get recapNoMap => 'Trace non disponible';
	@override String get recapJournalEntries => '{count} notes de journal';
	@override String get downloadPdf => 'Telecharger le diplome PDF';
}

// Path: notifications
class _Translations$notifications$fr implements Translations$notifications$en {
	_Translations$notifications$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Rappel du matin';
	@override String get weatherAlerts => 'Alertes météo';
	@override String get countdown => 'Rappel J-2';
	@override String get countdownDesc => 'Notification 2 jours avant le départ';
	@override String get schedulerCountdownTitle => 'Votre trek approche !';
	@override String get schedulerCountdownBody => 'Depart dans 2 jours. Verifiez votre checklist et la meteo.';
	@override String get schedulerDailyTitle => 'Bonne journee de trek !';
	@override String get schedulerDailyBody => 'Consultez la meteo et preparez votre etape du jour.';
	@override String get downloadReminderTitle => 'Pensez a telecharger votre sentier !';
	@override String get downloadReminderBody => 'Depart dans 2 jours. Telechargez votre sentier pour le mode offline.';
}

// Path: settings
class _Translations$settings$fr implements Translations$settings$en {
	_Translations$settings$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Paramètres';
	@override String get language => 'Langue';
	@override String get units => 'Unités';
	@override String get distance => 'Distance';
	@override String get temperature => 'Température';
	@override String get theme => 'Thème';
	@override String get dark => 'Sombre';
	@override String get light => 'Clair';
	@override String get system => 'Système';
	@override String get cache => 'Cache';
	@override String get cacheEnabled => 'Cache activé';
	@override String get cacheDesc => 'Données disponibles hors ligne';
	@override String get cacheSize => 'Taille du cache';
	@override String get notifications => 'Notifications';
	@override String get morningReminder => 'Rappel du matin';
	@override String get weatherAlerts => 'Alertes météo';
	@override String get weatherAlertsDesc => 'Prévenu si conditions dangereuses';
	@override String get countdownReminder => 'Rappel J-2';
	@override String get countdownDesc => 'Notification 2 jours avant le départ';
	@override String get version => 'Version';
	@override String get versionLabel => 'Version de l\'application';
}

// Path: feedback
class _Translations$feedback$fr implements Translations$feedback$en {
	_Translations$feedback$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Type de retour';
	@override String get bug => 'Bug / Problème';
	@override String get suggestion => 'Suggestion';
	@override String get compliment => 'Compliment';
	@override String get question => 'Question';
	@override String get other => 'Autre';
	@override String get message => 'Votre message';
	@override String get messagePlaceholder => 'Décrivez votre retour...';
	@override String get satisfaction => 'Satisfaction';
	@override String get send => 'Envoyer';
	@override String get sending => 'Envoi...';
	@override String get thanks => 'Merci pour votre retour !';
	@override String get pending => 'en attente';
}

// Path: auth
class _Translations$auth$fr implements Translations$auth$en {
	_Translations$auth$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profil';
	@override String get anonymous => 'Randonneur anonyme';
	@override String get connectedVia => 'Connecté via';
	@override String get signInGoogle => 'Se connecter avec Google';
	@override String get signInGoogleDesc => 'Pour sauvegarder votre progression';
	@override String get signOut => 'Se déconnecter';
	@override String get signOutDesc => 'Revenir en mode anonyme';
	@override String get signOutConfirm => 'Se déconnecter ?';
	@override String get signOutMessage => 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.';
	@override String get deleteAccount => 'Supprimer mon compte';
	@override String get deleteAccountDesc => 'Toutes vos données seront effacées';
	@override String get deleteConfirm => 'Supprimer votre compte ?';
	@override String get deleteMessage => 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.';
	@override String get cancel => 'Annuler';
	@override String get pseudonym => 'Pseudonyme';
	@override String get pseudonymHint => 'Votre nom de randonneur';
	@override String get save => 'Enregistrer';
	@override String get changeAvatar => 'Changer l\'avatar';
	@override String get chooseAvatar => 'Choisir un avatar';
	@override String get errorLoading => 'Erreur de chargement';
}

// Path: feasibility
class _Translations$feasibility$fr implements Translations$feasibility$en {
	_Translations$feasibility$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Faisabilité';
	@override String get subtitle => 'Évaluez votre préparation';
	@override String get previous => 'Précédent';
	@override String get restart => 'Recommencer';
	@override String get resultTitle => 'Votre résultat';
	@override String get weakPointsTitle => 'Points à améliorer';
	@override String get strongPointsTitle => 'Points forts';
	@override String get progress => '{current}/{total}';
	@override late final _Translations$feasibility$levels$fr levels = _Translations$feasibility$levels$fr._(_root);
	@override late final _Translations$feasibility$categories$fr categories = _Translations$feasibility$categories$fr._(_root);
	@override late final _Translations$feasibility$questions$fr questions = _Translations$feasibility$questions$fr._(_root);
	@override late final _Translations$feasibility$answers$fr answers = _Translations$feasibility$answers$fr._(_root);
	@override String get seeRecommendations => 'Voir les recommandations';
	@override String get yourProfile => 'Votre profil';
	@override String get tipsTitle => 'Nos conseils';
	@override late final _Translations$feasibility$recommendations$fr recommendations = _Translations$feasibility$recommendations$fr._(_root);
}

// Path: tips
class _Translations$tips$fr implements Translations$tips$en {
	_Translations$tips$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Conseils trek';
	@override String get allCategories => 'Toutes';
	@override String get swipeHint => 'Glissez pour voir plus';
	@override String get detailTitle => 'Détail du conseil';
	@override String get readMore => 'Lire la suite';
	@override String get noTips => 'Aucun conseil disponible';
	@override String get categoryPreparation => 'Préparation';
	@override String get categoryEquipment => 'Équipement';
	@override String get categoryNutrition => 'Nutrition';
	@override String get categorySafety => 'Sécurité';
	@override String get categoryNature => 'Nature';
	@override String get categoryRecovery => 'Récupération';
	@override String get categoryGeneral => 'Général';
	@override String get priorityHigh => 'Priorité haute';
	@override String get scope => 'Sentier';
	@override String get season => 'Saison';
	@override String get altitude => 'Altitude min.';
}

// Path: goodies
class _Translations$goodies$fr implements Translations$goodies$en {
	_Translations$goodies$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Boutique Goodies';
	@override String get comingSoon => 'Ce module arrive bientot. Restez connecte !';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$fr implements Translations$stage$difficulty$en {
	_Translations$stage$difficulty$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Facile';
	@override String get moderate => 'ModÃ©rÃ©';
	@override String get hard => 'Difficile';
	@override String get expert => 'Expert';
}

// Path: checklist.categories
class _Translations$checklist$categories$fr implements Translations$checklist$categories$en {
	_Translations$checklist$categories$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Équipement';
	@override String get clothing => 'Vêtements';
	@override String get food => 'Alimentation';
	@override String get safety => 'Sécurité';
	@override String get documents => 'Documents';
	@override String get hygiene => 'Hygiène';
}

// Path: checklist.items
class _Translations$checklist$items$fr implements Translations$checklist$items$en {
	_Translations$checklist$items$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Sac à dos';
	@override String get sleepingBag => 'Sac de couchage';
	@override String get sleepingPad => 'Matelas de sol';
	@override String get hikingPoles => 'Bâtons de marche';
	@override String get headlamp => 'Lampe frontale';
	@override String get waterBottle => 'Gourde';
	@override String get hikingBoots => 'Chaussures de randonnée';
	@override String get rainJacket => 'Veste imperméable';
	@override String get warmLayer => 'Couche chaude';
	@override String get hikingSocks => 'Chaussettes de randonnée';
	@override String get hat => 'Chapeau';
	@override String get gloves => 'Gants';
	@override String get trailSnacks => 'Encas de marche';
	@override String get energyBars => 'Barres énergétiques';
	@override String get waterPurification => 'Purification d\'eau';
	@override String get firstAidKit => 'Trousse de secours';
	@override String get whistle => 'Sifflet';
	@override String get emergencyBlanket => 'Couverture de survie';
	@override String get sunscreen => 'Crème solaire';
	@override String get idCard => 'Pièce d\'identité';
	@override String get insurance => 'Assurance';
	@override String get trailMap => 'Carte du sentier';
	@override String get toiletPaper => 'Papier toilette';
	@override String get handSanitizer => 'Gel hydroalcoolique';
	@override String get towel => 'Serviette';
}

// Path: feasibility.levels
class _Translations$feasibility$levels$fr implements Translations$feasibility$levels$en {
	_Translations$feasibility$levels$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Déconseillé';
	@override String get caution => 'Préparation nécessaire';
	@override String get good => 'Faisable';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$fr implements Translations$feasibility$categories$en {
	_Translations$feasibility$categories$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fitness => 'Condition physique';
	@override String get experience => 'Expérience';
	@override String get gear => 'Équipement';
	@override String get weather => 'Météo';
	@override String get duration => 'Durée';
	@override String get companion => 'Accompagnement';
	@override String get health => 'Santé';
	@override String get motivation => 'Motivation';
}

// Path: feasibility.questions
class _Translations$feasibility$questions$fr implements Translations$feasibility$questions$en {
	_Translations$feasibility$questions$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fitnessQuestion => 'Quel est votre niveau de condition physique ?';
	@override String get experienceQuestion => 'Quelle est votre expérience en randonnée ?';
	@override String get gearQuestion => 'Quel est l’état de votre équipement ?';
	@override String get weatherQuestion => 'Avez-vous vérifié les conditions météo ?';
	@override String get durationQuestion => 'Combien de jours prévoyez-vous ?';
	@override String get companionQuestion => 'Êtes-vous accompagné(e) ?';
	@override String get healthQuestion => 'Avez-vous des problèmes de santé ?';
	@override String get motivationQuestion => 'Quel est votre niveau de motivation ?';
}

// Path: feasibility.answers
class _Translations$feasibility$answers$fr implements Translations$feasibility$answers$en {
	_Translations$feasibility$answers$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get fitnessA => 'Sédentaire, aucun entraînement';
	@override String get fitnessB => 'Activité physique occasionnelle';
	@override String get fitnessC => 'Sport régulier (2-3x/semaine)';
	@override String get fitnessD => 'Sportif aguerri, entraîné spécifiquement';
	@override String get experienceA => 'Aucune expérience de randonnée';
	@override String get experienceB => 'Quelques randonnées à la journée';
	@override String get experienceC => 'Randonnées multi-jours déjà réalisées';
	@override String get experienceD => 'Trekkeur expérimenté, GR déjà réalisés';
	@override String get gearA => 'Équipement incomplet ou inadapté';
	@override String get gearB => 'Équipement basique, quelques manques';
	@override String get gearC => 'Équipement complet, bon état';
	@override String get gearD => 'Équipement technique, rodé et testé';
	@override String get weatherA => 'Pas vérifié, aucune idée';
	@override String get weatherB => 'Consulté vaguement, conditions incertaines';
	@override String get weatherC => 'Vérifié, conditions correctes prévues';
	@override String get weatherD => 'Vérifié en détail, créneau favorable';
	@override String get durationA => 'Aucune idée de la durée';
	@override String get durationB => 'Durée sous-estimée ou trop ambitieuse';
	@override String get durationC => 'Planning réaliste avec marges';
	@override String get durationD => 'Planning détaillé, jours de repos prévus';
	@override String get companionA => 'Seul(e), sans expérience solo';
	@override String get companionB => 'Seul(e), mais expérimenté(e)';
	@override String get companionC => 'En groupe, niveaux mixtes';
	@override String get companionD => 'En groupe, tous expérimentés';
	@override String get healthA => 'Problèmes de santé non traités';
	@override String get healthB => 'Problèmes mineurs, sous contrôle';
	@override String get healthC => 'Bonne santé générale';
	@override String get healthD => 'Excellent état de santé, bilan récent';
	@override String get motivationA => 'Peu motivé(e), hésitant(e)';
	@override String get motivationB => 'Motivé(e) mais anxieux(se)';
	@override String get motivationC => 'Motivé(e) et déterminé(e)';
	@override String get motivationD => 'Passion absolue, rêve de longue date';
}

// Path: feasibility.recommendations
class _Translations$feasibility$recommendations$fr implements Translations$feasibility$recommendations$en {
	_Translations$feasibility$recommendations$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$fr danger = _Translations$feasibility$recommendations$danger$fr._(_root);
	@override late final _Translations$feasibility$recommendations$caution$fr caution = _Translations$feasibility$recommendations$caution$fr._(_root);
	@override late final _Translations$feasibility$recommendations$good$fr good = _Translations$feasibility$recommendations$good$fr._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$fr excellent = _Translations$feasibility$recommendations$excellent$fr._(_root);
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$fr implements Translations$feasibility$recommendations$danger$en {
	_Translations$feasibility$recommendations$danger$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Préparation insuffisante';
	@override String get summary => 'Votre profil indique des lacunes importantes. Nous vous déconseillons de partir en l’état.';
	@override late final _Translations$feasibility$recommendations$danger$tips$fr tips = _Translations$feasibility$recommendations$danger$tips$fr._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$fr implements Translations$feasibility$recommendations$caution$en {
	_Translations$feasibility$recommendations$caution$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Préparation à renforcer';
	@override String get summary => 'Vous avez des bases, mais certains points méritent une attention particulière.';
	@override late final _Translations$feasibility$recommendations$caution$tips$fr tips = _Translations$feasibility$recommendations$caution$tips$fr._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$fr implements Translations$feasibility$recommendations$good$en {
	_Translations$feasibility$recommendations$good$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bonne préparation';
	@override String get summary => 'Votre profil est solide. Quelques ajustements et vous serez prêt(e).';
	@override late final _Translations$feasibility$recommendations$good$tips$fr tips = _Translations$feasibility$recommendations$good$tips$fr._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$fr implements Translations$feasibility$recommendations$excellent$en {
	_Translations$feasibility$recommendations$excellent$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get title => 'Préparation optimale';
	@override String get summary => 'Vous êtes parfaitement préparé(e). Profitez du trek !';
	@override late final _Translations$feasibility$recommendations$excellent$tips$fr tips = _Translations$feasibility$recommendations$excellent$tips$fr._(_root);
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$fr implements Translations$feasibility$recommendations$danger$tips$en {
	_Translations$feasibility$recommendations$danger$tips$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Commencez par des randonnées courtes pour évaluer votre condition';
	@override String get tip2 => 'Consultez un professionnel de santé avant un effort prolongé';
	@override String get tip3 => 'Investissez dans un équipement adapté et testez-le';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$fr implements Translations$feasibility$recommendations$caution$tips$en {
	_Translations$feasibility$recommendations$caution$tips$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Renforcez votre entraînement physique 6 à 8 semaines avant';
	@override String get tip2 => 'Vérifiez et complétez votre équipement';
	@override String get tip3 => 'Planifiez des étapes adaptées à votre niveau';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$fr implements Translations$feasibility$recommendations$good$tips$en {
	_Translations$feasibility$recommendations$good$tips$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Maintenez votre rythme d’entraînement';
	@override String get tip2 => 'Prévoyez des marges dans votre planning';
	@override String get tip3 => 'Consultez la météo régulièrement';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$fr implements Translations$feasibility$recommendations$excellent$tips$en {
	_Translations$feasibility$recommendations$excellent$tips$fr._(this._root);

	final TranslationsFr _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Restez à l’écoute de votre corps';
	@override String get tip2 => 'Partagez votre expérience avec les randonneurs';
	@override String get tip3 => 'Documentez votre aventure dans le journal';
}

/// The flat map containing all translations for locale <fr>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsFr {
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
			'notifications.downloadReminderTitle' => 'Pensez a telecharger votre sentier !',
			'notifications.downloadReminderBody' => 'Depart dans 2 jours. Telechargez votre sentier pour le mode offline.',
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
			_ => null,
		};
	}
}
