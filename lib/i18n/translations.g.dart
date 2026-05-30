/// Generated file. Do not edit.
///
/// Original: assets/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 5
/// Strings: 875 (175 per locale)
///
/// Built on 2026-05-30 at 12:16 UTC

// coverage:ignore-file
// ignore_for_file: type=lint

import 'package:flutter/widgets.dart';
import 'package:slang/builder/model/node.dart';
import 'package:slang_flutter/slang_flutter.dart';
export 'package:slang_flutter/slang_flutter.dart';

const AppLocale _baseLocale = AppLocale.fr;

/// Supported locales, see extension methods below.
///
/// Usage:
/// - LocaleSettings.setLocale(AppLocale.fr) // set locale
/// - Locale locale = AppLocale.fr.flutterLocale // get flutter locale from enum
/// - if (LocaleSettings.currentLocale == AppLocale.fr) // locale check
enum AppLocale with BaseAppLocale<AppLocale, Translations> {
	fr(languageCode: 'fr', build: Translations.build),
	de(languageCode: 'de', build: _TranslationsDe.build),
	en(languageCode: 'en', build: _TranslationsEn.build),
	es(languageCode: 'es', build: _TranslationsEs.build),
	it(languageCode: 'it', build: _TranslationsIt.build);

	const AppLocale({required this.languageCode, this.scriptCode, this.countryCode, required this.build}); // ignore: unused_element

	@override final String languageCode;
	@override final String? scriptCode;
	@override final String? countryCode;
	@override final TranslationBuilder<AppLocale, Translations> build;

	/// Gets current instance managed by [LocaleSettings].
	Translations get translations => LocaleSettings.instance.translationMap[this]!;
}

/// Method A: Simple
///
/// No rebuild after locale change.
/// Translation happens during initialization of the widget (call of t).
/// Configurable via 'translate_var'.
///
/// Usage:
/// String a = t.someKey.anotherKey;
/// String b = t['someKey.anotherKey']; // Only for edge cases!
Translations get t => LocaleSettings.instance.currentTranslations;

/// Method B: Advanced
///
/// All widgets using this method will trigger a rebuild when locale changes.
/// Use this if you have e.g. a settings page where the user can select the locale during runtime.
///
/// Step 1:
/// wrap your App with
/// TranslationProvider(
/// 	child: MyApp()
/// );
///
/// Step 2:
/// final t = Translations.of(context); // Get t variable.
/// String a = t.someKey.anotherKey; // Use t variable.
/// String b = t['someKey.anotherKey']; // Only for edge cases!
class TranslationProvider extends BaseTranslationProvider<AppLocale, Translations> {
	TranslationProvider({required super.child}) : super(settings: LocaleSettings.instance);

	static InheritedLocaleData<AppLocale, Translations> of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context);
}

/// Method B shorthand via [BuildContext] extension method.
/// Configurable via 'translate_var'.
///
/// Usage (e.g. in a widget's build method):
/// context.t.someKey.anotherKey
extension BuildContextTranslationsExtension on BuildContext {
	Translations get t => TranslationProvider.of(this).translations;
}

/// Manages all translation instances and the current locale
class LocaleSettings extends BaseFlutterLocaleSettings<AppLocale, Translations> {
	LocaleSettings._() : super(utils: AppLocaleUtils.instance);

	static final instance = LocaleSettings._();

	// static aliases (checkout base methods for documentation)
	static AppLocale get currentLocale => instance.currentLocale;
	static Stream<AppLocale> getLocaleStream() => instance.getLocaleStream();
	static AppLocale setLocale(AppLocale locale, {bool? listenToDeviceLocale = false}) => instance.setLocale(locale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale setLocaleRaw(String rawLocale, {bool? listenToDeviceLocale = false}) => instance.setLocaleRaw(rawLocale, listenToDeviceLocale: listenToDeviceLocale);
	static AppLocale useDeviceLocale() => instance.useDeviceLocale();
	@Deprecated('Use [AppLocaleUtils.supportedLocales]') static List<Locale> get supportedLocales => instance.supportedLocales;
	@Deprecated('Use [AppLocaleUtils.supportedLocalesRaw]') static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
	static void setPluralResolver({String? language, AppLocale? locale, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver}) => instance.setPluralResolver(
		language: language,
		locale: locale,
		cardinalResolver: cardinalResolver,
		ordinalResolver: ordinalResolver,
	);
}

/// Provides utility functions without any side effects.
class AppLocaleUtils extends BaseAppLocaleUtils<AppLocale, Translations> {
	AppLocaleUtils._() : super(baseLocale: _baseLocale, locales: AppLocale.values);

	static final instance = AppLocaleUtils._();

	// static aliases (checkout base methods for documentation)
	static AppLocale parse(String rawLocale) => instance.parse(rawLocale);
	static AppLocale parseLocaleParts({required String languageCode, String? scriptCode, String? countryCode}) => instance.parseLocaleParts(languageCode: languageCode, scriptCode: scriptCode, countryCode: countryCode);
	static AppLocale findDeviceLocale() => instance.findDeviceLocale();
	static List<Locale> get supportedLocales => instance.supportedLocales;
	static List<String> get supportedLocalesRaw => instance.supportedLocalesRaw;
}

// translations

// Path: <root>
class Translations implements BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
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

	// Translations
	late final _TranslationsMapFr map = _TranslationsMapFr._(_root);
	late final _TranslationsStageFr stage = _TranslationsStageFr._(_root);
	late final _TranslationsTrailFr trail = _TranslationsTrailFr._(_root);
	late final _TranslationsPoiFr poi = _TranslationsPoiFr._(_root);
	late final _TranslationsGpsFr gps = _TranslationsGpsFr._(_root);
	late final _TranslationsPlanningFr planning = _TranslationsPlanningFr._(_root);
	late final _TranslationsTrackingFr tracking = _TranslationsTrackingFr._(_root);
	late final _TranslationsChecklistFr checklist = _TranslationsChecklistFr._(_root);
	late final _TranslationsJournalFr journal = _TranslationsJournalFr._(_root);
	late final _TranslationsWeatherFr weather = _TranslationsWeatherFr._(_root);
	late final _TranslationsShareFr share = _TranslationsShareFr._(_root);
	late final _TranslationsDiplomaFr diploma = _TranslationsDiplomaFr._(_root);
	late final _TranslationsNotificationsFr notifications = _TranslationsNotificationsFr._(_root);
	late final _TranslationsSettingsFr settings = _TranslationsSettingsFr._(_root);
	late final _TranslationsFeedbackFr feedback = _TranslationsFeedbackFr._(_root);
	late final _TranslationsAuthFr auth = _TranslationsAuthFr._(_root);
}

// Path: map
class _TranslationsMapFr {
	_TranslationsMapFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Carte du sentier';
	String get loading => 'Chargement du tracÃ©...';
	String get noTrack => 'Aucun tracÃ© disponible';
	String get viewMap => 'Voir la carte';
}

// Path: stage
class _TranslationsStageFr {
	_TranslationsStageFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get distance => 'Distance';
	String get elevation => 'DÃ©nivelÃ©';
	String get elevationGain => 'DÃ©nivelÃ© positif';
	String get elevationLoss => 'DÃ©nivelÃ© nÃ©gatif';
	String get duration => 'DurÃ©e estimÃ©e';
	String get description => 'Description';
	String get coordinates => 'CoordonnÃ©es';
	String get pois => 'Points d\'intÃ©rÃªt';
	late final _TranslationsStageDifficultyFr difficulty = _TranslationsStageDifficultyFr._(_root);
	String get remaining => '{distance} km restants';
	String get arrived => 'Vous etes arrive !';
}

// Path: trail
class _TranslationsTrailFr {
	_TranslationsTrailFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get stages => 'Ãtapes';
	String get totalDistance => 'Distance totale';
	String get totalElevation => 'DÃ©nivelÃ© total';
}

// Path: poi
class _TranslationsPoiFr {
	_TranslationsPoiFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get shelter => 'Refuge';
	String get water => 'Point d\'eau';
	String get viewpoint => 'Point de vue';
	String get campsite => 'Bivouac';
	String get restaurant => 'Restaurant';
	String get emergency => 'Urgence';
	String get danger => 'Danger';
	String get shop => 'Commerce';
	String get filter => 'Filtrer les points d\'intÃ©rÃªt';
	String get altitude => 'Altitude';
	String get hours => 'Horaires';
}

// Path: gps
class _TranslationsGpsFr {
	_TranslationsGpsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get permission => 'Autorisation GPS requise';
	String get denied => 'Acces a la localisation refuse';
	String get disabled => 'Service de localisation desactive';
	String get offTrack => 'Hors trace';
	String get centerOnMe => 'Centrer sur ma position';
}

// Path: planning
class _TranslationsPlanningFr {
	_TranslationsPlanningFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Planning';
	String get duration => 'Durée';
	String get days => 'jours';
	String get day => 'Jour';
	String get restDay => 'Jour de repos';
	String get totalDistance => 'Distance totale';
	String get totalElevation => 'Dénivelé total';
	String get estimatedTime => 'Durée estimée';
	String get stages => 'Étapes';
	String get plan => 'Planifier';
}

// Path: tracking
class _TranslationsTrackingFr {
	_TranslationsTrackingFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get start => 'Demarrer';
	String get pause => 'Pause';
	String get resume => 'Reprendre';
	String get stop => 'Arreter';
	String get distance => 'Distance';
	String get elevation => 'Denivele';
	String get speed => 'Vitesse';
	String get time => 'Temps';
	String get confirmStop => 'Arreter le tracking ?';
}

// Path: checklist
class _TranslationsChecklistFr {
	_TranslationsChecklistFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Checklist matériel';
	String get subtitle => 'Préparez votre sac à dos';
	String get progress => '{checked}/{total} préparés';
	String get complete => 'Checklist complète !';
	String get reset => 'Réinitialiser';
	String get resetConfirm => 'Réinitialiser la checklist ?';
	String get resetDescription => 'Tous les éléments seront décochés.';
	String get cancel => 'Annuler';
	String get confirm => 'Confirmer';
	late final _TranslationsChecklistCategoriesFr categories = _TranslationsChecklistCategoriesFr._(_root);
	late final _TranslationsChecklistItemsFr items = _TranslationsChecklistItemsFr._(_root);
	String get essential => 'Essentiel';
}

// Path: journal
class _TranslationsJournalFr {
	_TranslationsJournalFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Journal de trek';
	String get empty => 'Votre journal est vide';
	String get emptySubtitle => 'Notez vos impressions et souvenirs de trek';
	String get addNote => 'Nouvelle note';
	String get stage => 'Étape';
	String get yourNote => 'Votre note';
	String get placeholder => 'Décrivez votre journée de trek...';
	String get save => 'Enregistrer';
	String get cancel => 'Annuler';
	String get delete => 'Supprimer';
	String get photoLimit => 'Limite de 3 photos par jour atteinte';
	String get photoTooBig => 'Photo trop volumineuse (max 500 Ko)';
}

// Path: weather
class _TranslationsWeatherFr {
	_TranslationsWeatherFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Météo';
	String get loading => 'Chargement de la météo...';
	String get offline => 'Pas de connexion. Données météo indisponibles.';
	String get error => 'Impossible de charger la météo.';
	String get cached => 'Données en cache';
	String get alerts => 'alertes météo';
	String get refresh => 'Actualiser';
	String get temperature => 'Température';
	String get precipitation => 'Précipitations';
	String get wind => 'Vent';
	String get uv => 'Indice UV';
}

// Path: share
class _TranslationsShareFr {
	_TranslationsShareFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Partager';
	String get generating => 'Génération...';
	String get share => 'Partager';
	String get error => 'Erreur lors de la génération';
}

// Path: diploma
class _TranslationsDiplomaFr {
	_TranslationsDiplomaFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Diplôme de trek';
	String get yourName => 'Votre nom';
	String get namePlaceholder => 'Entrez votre nom...';
	String get generatePdf => 'Générer le PDF';
	String get certifies => 'Certifie que';
	String get completed => 'a parcouru le';
}

// Path: notifications
class _TranslationsNotificationsFr {
	_TranslationsNotificationsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get morningReminder => 'Rappel du matin';
	String get weatherAlerts => 'Alertes météo';
	String get countdown => 'Rappel J-2';
	String get countdownDesc => 'Notification 2 jours avant le départ';
}

// Path: settings
class _TranslationsSettingsFr {
	_TranslationsSettingsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Paramètres';
	String get language => 'Langue';
	String get units => 'Unités';
	String get distance => 'Distance';
	String get temperature => 'Température';
	String get theme => 'Thème';
	String get dark => 'Sombre';
	String get light => 'Clair';
	String get system => 'Système';
	String get cache => 'Cache';
	String get cacheEnabled => 'Cache activé';
	String get cacheDesc => 'Données disponibles hors ligne';
	String get cacheSize => 'Taille du cache';
	String get notifications => 'Notifications';
}

// Path: feedback
class _TranslationsFeedbackFr {
	_TranslationsFeedbackFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Feedback';
	String get type => 'Type de retour';
	String get bug => 'Bug / Problème';
	String get suggestion => 'Suggestion';
	String get question => 'Question';
	String get other => 'Autre';
	String get message => 'Votre message';
	String get messagePlaceholder => 'Décrivez votre retour...';
	String get satisfaction => 'Satisfaction';
	String get send => 'Envoyer';
	String get sending => 'Envoi...';
	String get thanks => 'Merci pour votre retour !';
	String get pending => 'en attente';
}

// Path: auth
class _TranslationsAuthFr {
	_TranslationsAuthFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get profile => 'Profil';
	String get anonymous => 'Randonneur anonyme';
	String get connectedVia => 'Connecté via';
	String get signInGoogle => 'Se connecter avec Google';
	String get signInGoogleDesc => 'Pour sauvegarder votre progression';
	String get signOut => 'Se déconnecter';
	String get signOutDesc => 'Revenir en mode anonyme';
	String get signOutConfirm => 'Se déconnecter ?';
	String get signOutMessage => 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.';
	String get deleteAccount => 'Supprimer mon compte';
	String get deleteAccountDesc => 'Toutes vos données seront effacées';
	String get deleteConfirm => 'Supprimer votre compte ?';
	String get deleteMessage => 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.';
	String get cancel => 'Annuler';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get easy => 'Facile';
	String get moderate => 'ModÃ©rÃ©';
	String get hard => 'Difficile';
	String get expert => 'Expert';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get equipment => 'Équipement';
	String get clothing => 'Vêtements';
	String get food => 'Alimentation';
	String get safety => 'Sécurité';
	String get documents => 'Documents';
	String get hygiene => 'Hygiène';
}

// Path: checklist.items
class _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get backpack => 'Sac à dos';
	String get sleepingBag => 'Sac de couchage';
	String get sleepingPad => 'Matelas de sol';
	String get hikingPoles => 'Bâtons de marche';
	String get headlamp => 'Lampe frontale';
	String get waterBottle => 'Gourde';
	String get hikingBoots => 'Chaussures de randonnée';
	String get rainJacket => 'Veste imperméable';
	String get warmLayer => 'Couche chaude';
	String get hikingSocks => 'Chaussettes de randonnée';
	String get hat => 'Chapeau';
	String get gloves => 'Gants';
	String get trailSnacks => 'Encas de marche';
	String get energyBars => 'Barres énergétiques';
	String get waterPurification => 'Purification d\'eau';
	String get firstAidKit => 'Trousse de secours';
	String get whistle => 'Sifflet';
	String get emergencyBlanket => 'Couverture de survie';
	String get sunscreen => 'Crème solaire';
	String get idCard => 'Pièce d\'identité';
	String get insurance => 'Assurance';
	String get trailMap => 'Carte du sentier';
	String get toiletPaper => 'Papier toilette';
	String get handSanitizer => 'Gel hydroalcoolique';
	String get towel => 'Serviette';
}

// Path: <root>
class _TranslationsDe extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_TranslationsDe.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _TranslationsDe _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMapDe map = _TranslationsMapDe._(_root);
	@override late final _TranslationsStageDe stage = _TranslationsStageDe._(_root);
	@override late final _TranslationsTrailDe trail = _TranslationsTrailDe._(_root);
	@override late final _TranslationsPoiDe poi = _TranslationsPoiDe._(_root);
	@override late final _TranslationsGpsDe gps = _TranslationsGpsDe._(_root);
	@override late final _TranslationsPlanningDe planning = _TranslationsPlanningDe._(_root);
	@override late final _TranslationsTrackingDe tracking = _TranslationsTrackingDe._(_root);
	@override late final _TranslationsChecklistDe checklist = _TranslationsChecklistDe._(_root);
	@override late final _TranslationsJournalDe journal = _TranslationsJournalDe._(_root);
	@override late final _TranslationsWeatherDe weather = _TranslationsWeatherDe._(_root);
	@override late final _TranslationsShareDe share = _TranslationsShareDe._(_root);
	@override late final _TranslationsDiplomaDe diploma = _TranslationsDiplomaDe._(_root);
	@override late final _TranslationsNotificationsDe notifications = _TranslationsNotificationsDe._(_root);
	@override late final _TranslationsSettingsDe settings = _TranslationsSettingsDe._(_root);
	@override late final _TranslationsFeedbackDe feedback = _TranslationsFeedbackDe._(_root);
	@override late final _TranslationsAuthDe auth = _TranslationsAuthDe._(_root);
}

// Path: map
class _TranslationsMapDe extends _TranslationsMapFr {
	_TranslationsMapDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderkarte';
	@override String get loading => 'Strecke wird geladen...';
	@override String get noTrack => 'Keine Strecke verfÃ¼gbar';
	@override String get viewMap => 'Karte anzeigen';
}

// Path: stage
class _TranslationsStageDe extends _TranslationsStageFr {
	_TranslationsStageDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Entfernung';
	@override String get elevation => 'HÃ¶henunterschied';
	@override String get elevationGain => 'HÃ¶henmeter aufwÃ¤rts';
	@override String get elevationLoss => 'HÃ¶henmeter abwÃ¤rts';
	@override String get duration => 'GeschÃ¤tzte Dauer';
	@override String get description => 'Beschreibung';
	@override String get coordinates => 'Koordinaten';
	@override String get pois => 'SehenswÃ¼rdigkeiten';
	@override late final _TranslationsStageDifficultyDe difficulty = _TranslationsStageDifficultyDe._(_root);
	@override String get remaining => '{distance} km verbleibend';
	@override String get arrived => 'Sie sind angekommen!';
}

// Path: trail
class _TranslationsTrailDe extends _TranslationsTrailFr {
	_TranslationsTrailDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etappen';
	@override String get totalDistance => 'Gesamtstrecke';
	@override String get totalElevation => 'GesamthÃ¶henmeter';
}

// Path: poi
class _TranslationsPoiDe extends _TranslationsPoiFr {
	_TranslationsPoiDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'SchutzhÃ¼tte';
	@override String get water => 'Wasserquelle';
	@override String get viewpoint => 'Aussichtspunkt';
	@override String get campsite => 'Biwakplatz';
	@override String get restaurant => 'Restaurant';
	@override String get emergency => 'Notfall';
	@override String get danger => 'Gefahr';
	@override String get shop => 'GeschÃ¤ft';
	@override String get filter => 'SehenswÃ¼rdigkeiten filtern';
	@override String get altitude => 'HÃ¶he';
	@override String get hours => 'Ãffnungszeiten';
}

// Path: gps
class _TranslationsGpsDe extends _TranslationsGpsFr {
	_TranslationsGpsDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get permission => 'GPS-Berechtigung erforderlich';
	@override String get denied => 'Standortzugriff verweigert';
	@override String get disabled => 'Standortdienst deaktiviert';
	@override String get offTrack => 'Abseits der Strecke';
	@override String get centerOnMe => 'Auf meine Position zentrieren';
}

// Path: planning
class _TranslationsPlanningDe extends _TranslationsPlanningFr {
	_TranslationsPlanningDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planung';
	@override String get duration => 'Dauer';
	@override String get days => 'Tage';
	@override String get day => 'Tag';
	@override String get restDay => 'Ruhetag';
	@override String get totalDistance => 'Gesamtstrecke';
	@override String get totalElevation => 'Gesamthöhenmeter';
	@override String get estimatedTime => 'Geschätzte Dauer';
	@override String get stages => 'Etappen';
	@override String get plan => 'Planen';
}

// Path: tracking
class _TranslationsTrackingDe extends _TranslationsTrackingFr {
	_TranslationsTrackingDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get start => 'Starten';
	@override String get pause => 'Pause';
	@override String get resume => 'Fortsetzen';
	@override String get stop => 'Stoppen';
	@override String get distance => 'Entfernung';
	@override String get elevation => 'Hohenmeter';
	@override String get speed => 'Geschwindigkeit';
	@override String get time => 'Zeit';
	@override String get confirmStop => 'Tracking stoppen?';
}

// Path: checklist
class _TranslationsChecklistDe extends _TranslationsChecklistFr {
	_TranslationsChecklistDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ausrüstungsliste';
	@override String get subtitle => 'Packen Sie Ihren Rucksack';
	@override String get progress => '{checked}/{total} gepackt';
	@override String get complete => 'Checkliste vollständig!';
	@override String get reset => 'Zurücksetzen';
	@override String get resetConfirm => 'Checkliste zurücksetzen?';
	@override String get resetDescription => 'Alle Elemente werden abgehakt.';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'Bestätigen';
	@override late final _TranslationsChecklistCategoriesDe categories = _TranslationsChecklistCategoriesDe._(_root);
	@override late final _TranslationsChecklistItemsDe items = _TranslationsChecklistItemsDe._(_root);
	@override String get essential => 'Wesentlich';
}

// Path: journal
class _TranslationsJournalDe extends _TranslationsJournalFr {
	_TranslationsJournalDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wandertagebuch';
	@override String get empty => 'Ihr Tagebuch ist leer';
	@override String get emptySubtitle => 'Notieren Sie Ihre Eindrücke und Erinnerungen';
	@override String get addNote => 'Neue Notiz';
	@override String get stage => 'Etappe';
	@override String get yourNote => 'Ihre Notiz';
	@override String get placeholder => 'Beschreiben Sie Ihren Wandertag...';
	@override String get save => 'Speichern';
	@override String get cancel => 'Abbrechen';
	@override String get delete => 'Löschen';
	@override String get photoLimit => 'Limit von 3 Fotos pro Tag erreicht';
	@override String get photoTooBig => 'Foto zu groß (max 500 KB)';
}

// Path: weather
class _TranslationsWeatherDe extends _TranslationsWeatherFr {
	_TranslationsWeatherDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wetter';
	@override String get loading => 'Wetter wird geladen...';
	@override String get offline => 'Keine Verbindung. Wetterdaten nicht verfügbar.';
	@override String get error => 'Wetter konnte nicht geladen werden.';
	@override String get cached => 'Zwischengespeicherte Daten';
	@override String get alerts => 'Wetterwarnungen';
	@override String get refresh => 'Aktualisieren';
	@override String get temperature => 'Temperatur';
	@override String get precipitation => 'Niederschlag';
	@override String get wind => 'Wind';
	@override String get uv => 'UV-Index';
}

// Path: share
class _TranslationsShareDe extends _TranslationsShareFr {
	_TranslationsShareDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Teilen';
	@override String get generating => 'Wird generiert...';
	@override String get share => 'Teilen';
	@override String get error => 'Fehler bei der Erstellung';
}

// Path: diploma
class _TranslationsDiplomaDe extends _TranslationsDiplomaFr {
	_TranslationsDiplomaDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderdiplom';
	@override String get yourName => 'Ihr Name';
	@override String get namePlaceholder => 'Geben Sie Ihren Namen ein...';
	@override String get generatePdf => 'PDF erstellen';
	@override String get certifies => 'Bestätigt, dass';
	@override String get completed => 'den Weg abgeschlossen hat';
}

// Path: notifications
class _TranslationsNotificationsDe extends _TranslationsNotificationsFr {
	_TranslationsNotificationsDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Morgenerinnerung';
	@override String get weatherAlerts => 'Wetterwarnungen';
	@override String get countdown => 'Erinnerung 2 Tage vorher';
	@override String get countdownDesc => 'Benachrichtigung 2 Tage vor Abreise';
}

// Path: settings
class _TranslationsSettingsDe extends _TranslationsSettingsFr {
	_TranslationsSettingsDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Einstellungen';
	@override String get language => 'Sprache';
	@override String get units => 'Einheiten';
	@override String get distance => 'Entfernung';
	@override String get temperature => 'Temperatur';
	@override String get theme => 'Thema';
	@override String get dark => 'Dunkel';
	@override String get light => 'Hell';
	@override String get system => 'System';
	@override String get cache => 'Cache';
	@override String get cacheEnabled => 'Cache aktiviert';
	@override String get cacheDesc => 'Daten offline verfügbar';
	@override String get cacheSize => 'Cache-Größe';
	@override String get notifications => 'Benachrichtigungen';
}

// Path: feedback
class _TranslationsFeedbackDe extends _TranslationsFeedbackFr {
	_TranslationsFeedbackDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Feedbacktyp';
	@override String get bug => 'Fehler / Problem';
	@override String get suggestion => 'Vorschlag';
	@override String get question => 'Frage';
	@override String get other => 'Sonstiges';
	@override String get message => 'Ihre Nachricht';
	@override String get messagePlaceholder => 'Beschreiben Sie Ihr Feedback...';
	@override String get satisfaction => 'Zufriedenheit';
	@override String get send => 'Senden';
	@override String get sending => 'Wird gesendet...';
	@override String get thanks => 'Vielen Dank für Ihr Feedback!';
	@override String get pending => 'ausstehend';
}

// Path: auth
class _TranslationsAuthDe extends _TranslationsAuthFr {
	_TranslationsAuthDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profil';
	@override String get anonymous => 'Anonymer Wanderer';
	@override String get connectedVia => 'Verbunden über';
	@override String get signInGoogle => 'Mit Google anmelden';
	@override String get signInGoogleDesc => 'Um Ihren Fortschritt zu speichern';
	@override String get signOut => 'Abmelden';
	@override String get signOutDesc => 'Zurück zum anonymen Modus';
	@override String get signOutConfirm => 'Abmelden?';
	@override String get signOutMessage => 'Sie kehren zum anonymen Modus zurück. Ihre lokalen Daten bleiben erhalten.';
	@override String get deleteAccount => 'Mein Konto löschen';
	@override String get deleteAccountDesc => 'Alle Ihre Daten werden gelöscht';
	@override String get deleteConfirm => 'Konto löschen?';
	@override String get deleteMessage => 'Diese Aktion ist unwiderruflich. Alle Ihre Daten, Notizen und Fortschritte werden gelöscht.';
	@override String get cancel => 'Abbrechen';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyDe extends _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Leicht';
	@override String get moderate => 'Mittel';
	@override String get hard => 'Schwer';
	@override String get expert => 'Experte';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesDe extends _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Ausrüstung';
	@override String get clothing => 'Kleidung';
	@override String get food => 'Verpflegung';
	@override String get safety => 'Sicherheit';
	@override String get documents => 'Dokumente';
	@override String get hygiene => 'Hygiene';
}

// Path: checklist.items
class _TranslationsChecklistItemsDe extends _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsDe._(_TranslationsDe root) : this._root = root, super._(root);

	@override final _TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Rucksack';
	@override String get sleepingBag => 'Schlafsack';
	@override String get sleepingPad => 'Isomatte';
	@override String get hikingPoles => 'Wanderstöcke';
	@override String get headlamp => 'Stirnlampe';
	@override String get waterBottle => 'Trinkflasche';
	@override String get hikingBoots => 'Wanderschuhe';
	@override String get rainJacket => 'Regenjacke';
	@override String get warmLayer => 'Wärmeschicht';
	@override String get hikingSocks => 'Wandersocken';
	@override String get hat => 'Hut';
	@override String get gloves => 'Handschuhe';
	@override String get trailSnacks => 'Wandersnacks';
	@override String get energyBars => 'Energieriegel';
	@override String get waterPurification => 'Wasseraufbereitung';
	@override String get firstAidKit => 'Erste-Hilfe-Set';
	@override String get whistle => 'Pfeife';
	@override String get emergencyBlanket => 'Rettungsdecke';
	@override String get sunscreen => 'Sonnenschutz';
	@override String get idCard => 'Ausweis';
	@override String get insurance => 'Versicherung';
	@override String get trailMap => 'Wanderkarte';
	@override String get toiletPaper => 'Toilettenpapier';
	@override String get handSanitizer => 'Handdesinfektionsmittel';
	@override String get towel => 'Handtuch';
}

// Path: <root>
class _TranslationsEn extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_TranslationsEn.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _TranslationsEn _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMapEn map = _TranslationsMapEn._(_root);
	@override late final _TranslationsStageEn stage = _TranslationsStageEn._(_root);
	@override late final _TranslationsTrailEn trail = _TranslationsTrailEn._(_root);
	@override late final _TranslationsPoiEn poi = _TranslationsPoiEn._(_root);
	@override late final _TranslationsGpsEn gps = _TranslationsGpsEn._(_root);
	@override late final _TranslationsPlanningEn planning = _TranslationsPlanningEn._(_root);
	@override late final _TranslationsTrackingEn tracking = _TranslationsTrackingEn._(_root);
	@override late final _TranslationsChecklistEn checklist = _TranslationsChecklistEn._(_root);
	@override late final _TranslationsJournalEn journal = _TranslationsJournalEn._(_root);
	@override late final _TranslationsWeatherEn weather = _TranslationsWeatherEn._(_root);
	@override late final _TranslationsShareEn share = _TranslationsShareEn._(_root);
	@override late final _TranslationsDiplomaEn diploma = _TranslationsDiplomaEn._(_root);
	@override late final _TranslationsNotificationsEn notifications = _TranslationsNotificationsEn._(_root);
	@override late final _TranslationsSettingsEn settings = _TranslationsSettingsEn._(_root);
	@override late final _TranslationsFeedbackEn feedback = _TranslationsFeedbackEn._(_root);
	@override late final _TranslationsAuthEn auth = _TranslationsAuthEn._(_root);
}

// Path: map
class _TranslationsMapEn extends _TranslationsMapFr {
	_TranslationsMapEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trail map';
	@override String get loading => 'Loading track...';
	@override String get noTrack => 'No track available';
	@override String get viewMap => 'View map';
}

// Path: stage
class _TranslationsStageEn extends _TranslationsStageFr {
	_TranslationsStageEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distance';
	@override String get elevation => 'Elevation';
	@override String get elevationGain => 'Elevation gain';
	@override String get elevationLoss => 'Elevation loss';
	@override String get duration => 'Estimated duration';
	@override String get description => 'Description';
	@override String get coordinates => 'Coordinates';
	@override String get pois => 'Points of interest';
	@override late final _TranslationsStageDifficultyEn difficulty = _TranslationsStageDifficultyEn._(_root);
	@override String get remaining => '{distance} km remaining';
	@override String get arrived => 'You have arrived!';
}

// Path: trail
class _TranslationsTrailEn extends _TranslationsTrailFr {
	_TranslationsTrailEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Stages';
	@override String get totalDistance => 'Total distance';
	@override String get totalElevation => 'Total elevation';
}

// Path: poi
class _TranslationsPoiEn extends _TranslationsPoiFr {
	_TranslationsPoiEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Shelter';
	@override String get water => 'Water source';
	@override String get viewpoint => 'Viewpoint';
	@override String get campsite => 'Campsite';
	@override String get restaurant => 'Restaurant';
	@override String get emergency => 'Emergency';
	@override String get danger => 'Danger';
	@override String get shop => 'Shop';
	@override String get filter => 'Filter points of interest';
	@override String get altitude => 'Altitude';
	@override String get hours => 'Opening hours';
}

// Path: gps
class _TranslationsGpsEn extends _TranslationsGpsFr {
	_TranslationsGpsEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get permission => 'GPS permission required';
	@override String get denied => 'Location access denied';
	@override String get disabled => 'Location service disabled';
	@override String get offTrack => 'Off track';
	@override String get centerOnMe => 'Center on my position';
}

// Path: planning
class _TranslationsPlanningEn extends _TranslationsPlanningFr {
	_TranslationsPlanningEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planning';
	@override String get duration => 'Duration';
	@override String get days => 'days';
	@override String get day => 'Day';
	@override String get restDay => 'Rest day';
	@override String get totalDistance => 'Total distance';
	@override String get totalElevation => 'Total elevation';
	@override String get estimatedTime => 'Estimated time';
	@override String get stages => 'Stages';
	@override String get plan => 'Plan';
}

// Path: tracking
class _TranslationsTrackingEn extends _TranslationsTrackingFr {
	_TranslationsTrackingEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get start => 'Start';
	@override String get pause => 'Pause';
	@override String get resume => 'Resume';
	@override String get stop => 'Stop';
	@override String get distance => 'Distance';
	@override String get elevation => 'Elevation';
	@override String get speed => 'Speed';
	@override String get time => 'Time';
	@override String get confirmStop => 'Stop tracking?';
}

// Path: checklist
class _TranslationsChecklistEn extends _TranslationsChecklistFr {
	_TranslationsChecklistEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gear checklist';
	@override String get subtitle => 'Pack your backpack';
	@override String get progress => '{checked}/{total} packed';
	@override String get complete => 'Checklist complete!';
	@override String get reset => 'Reset';
	@override String get resetConfirm => 'Reset checklist?';
	@override String get resetDescription => 'All items will be unchecked.';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'Confirm';
	@override late final _TranslationsChecklistCategoriesEn categories = _TranslationsChecklistCategoriesEn._(_root);
	@override late final _TranslationsChecklistItemsEn items = _TranslationsChecklistItemsEn._(_root);
	@override String get essential => 'Essential';
}

// Path: journal
class _TranslationsJournalEn extends _TranslationsJournalFr {
	_TranslationsJournalEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trek journal';
	@override String get empty => 'Your journal is empty';
	@override String get emptySubtitle => 'Write down your trek impressions and memories';
	@override String get addNote => 'New note';
	@override String get stage => 'Stage';
	@override String get yourNote => 'Your note';
	@override String get placeholder => 'Describe your hiking day...';
	@override String get save => 'Save';
	@override String get cancel => 'Cancel';
	@override String get delete => 'Delete';
	@override String get photoLimit => '3 photos per day limit reached';
	@override String get photoTooBig => 'Photo too large (max 500 KB)';
}

// Path: weather
class _TranslationsWeatherEn extends _TranslationsWeatherFr {
	_TranslationsWeatherEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weather';
	@override String get loading => 'Loading weather...';
	@override String get offline => 'No connection. Weather data unavailable.';
	@override String get error => 'Unable to load weather.';
	@override String get cached => 'Cached data';
	@override String get alerts => 'weather alerts';
	@override String get refresh => 'Refresh';
	@override String get temperature => 'Temperature';
	@override String get precipitation => 'Precipitation';
	@override String get wind => 'Wind';
	@override String get uv => 'UV index';
}

// Path: share
class _TranslationsShareEn extends _TranslationsShareFr {
	_TranslationsShareEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Share';
	@override String get generating => 'Generating...';
	@override String get share => 'Share';
	@override String get error => 'Error during generation';
}

// Path: diploma
class _TranslationsDiplomaEn extends _TranslationsDiplomaFr {
	_TranslationsDiplomaEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trek diploma';
	@override String get yourName => 'Your name';
	@override String get namePlaceholder => 'Enter your name...';
	@override String get generatePdf => 'Generate PDF';
	@override String get certifies => 'Certifies that';
	@override String get completed => 'completed the';
}

// Path: notifications
class _TranslationsNotificationsEn extends _TranslationsNotificationsFr {
	_TranslationsNotificationsEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Morning reminder';
	@override String get weatherAlerts => 'Weather alerts';
	@override String get countdown => 'D-2 reminder';
	@override String get countdownDesc => 'Notification 2 days before departure';
}

// Path: settings
class _TranslationsSettingsEn extends _TranslationsSettingsFr {
	_TranslationsSettingsEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Settings';
	@override String get language => 'Language';
	@override String get units => 'Units';
	@override String get distance => 'Distance';
	@override String get temperature => 'Temperature';
	@override String get theme => 'Theme';
	@override String get dark => 'Dark';
	@override String get light => 'Light';
	@override String get system => 'System';
	@override String get cache => 'Cache';
	@override String get cacheEnabled => 'Cache enabled';
	@override String get cacheDesc => 'Data available offline';
	@override String get cacheSize => 'Cache size';
	@override String get notifications => 'Notifications';
}

// Path: feedback
class _TranslationsFeedbackEn extends _TranslationsFeedbackFr {
	_TranslationsFeedbackEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Feedback type';
	@override String get bug => 'Bug / Problem';
	@override String get suggestion => 'Suggestion';
	@override String get question => 'Question';
	@override String get other => 'Other';
	@override String get message => 'Your message';
	@override String get messagePlaceholder => 'Describe your feedback...';
	@override String get satisfaction => 'Satisfaction';
	@override String get send => 'Send';
	@override String get sending => 'Sending...';
	@override String get thanks => 'Thank you for your feedback!';
	@override String get pending => 'pending';
}

// Path: auth
class _TranslationsAuthEn extends _TranslationsAuthFr {
	_TranslationsAuthEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profile';
	@override String get anonymous => 'Anonymous hiker';
	@override String get connectedVia => 'Connected via';
	@override String get signInGoogle => 'Sign in with Google';
	@override String get signInGoogleDesc => 'To save your progress';
	@override String get signOut => 'Sign out';
	@override String get signOutDesc => 'Return to anonymous mode';
	@override String get signOutConfirm => 'Sign out?';
	@override String get signOutMessage => 'You will return to anonymous mode. Your local data is preserved.';
	@override String get deleteAccount => 'Delete my account';
	@override String get deleteAccountDesc => 'All your data will be erased';
	@override String get deleteConfirm => 'Delete your account?';
	@override String get deleteMessage => 'This action is irreversible. All your data, notes and progress will be erased.';
	@override String get cancel => 'Cancel';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyEn extends _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Easy';
	@override String get moderate => 'Moderate';
	@override String get hard => 'Hard';
	@override String get expert => 'Expert';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesEn extends _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Equipment';
	@override String get clothing => 'Clothing';
	@override String get food => 'Food';
	@override String get safety => 'Safety';
	@override String get documents => 'Documents';
	@override String get hygiene => 'Hygiene';
}

// Path: checklist.items
class _TranslationsChecklistItemsEn extends _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsEn._(_TranslationsEn root) : this._root = root, super._(root);

	@override final _TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Backpack';
	@override String get sleepingBag => 'Sleeping bag';
	@override String get sleepingPad => 'Sleeping pad';
	@override String get hikingPoles => 'Hiking poles';
	@override String get headlamp => 'Headlamp';
	@override String get waterBottle => 'Water bottle';
	@override String get hikingBoots => 'Hiking boots';
	@override String get rainJacket => 'Rain jacket';
	@override String get warmLayer => 'Warm layer';
	@override String get hikingSocks => 'Hiking socks';
	@override String get hat => 'Hat';
	@override String get gloves => 'Gloves';
	@override String get trailSnacks => 'Trail snacks';
	@override String get energyBars => 'Energy bars';
	@override String get waterPurification => 'Water purification';
	@override String get firstAidKit => 'First aid kit';
	@override String get whistle => 'Whistle';
	@override String get emergencyBlanket => 'Emergency blanket';
	@override String get sunscreen => 'Sunscreen';
	@override String get idCard => 'ID card';
	@override String get insurance => 'Insurance';
	@override String get trailMap => 'Trail map';
	@override String get toiletPaper => 'Toilet paper';
	@override String get handSanitizer => 'Hand sanitizer';
	@override String get towel => 'Towel';
}

// Path: <root>
class _TranslationsEs extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_TranslationsEs.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _TranslationsEs _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMapEs map = _TranslationsMapEs._(_root);
	@override late final _TranslationsStageEs stage = _TranslationsStageEs._(_root);
	@override late final _TranslationsTrailEs trail = _TranslationsTrailEs._(_root);
	@override late final _TranslationsPoiEs poi = _TranslationsPoiEs._(_root);
	@override late final _TranslationsGpsEs gps = _TranslationsGpsEs._(_root);
	@override late final _TranslationsPlanningEs planning = _TranslationsPlanningEs._(_root);
	@override late final _TranslationsTrackingEs tracking = _TranslationsTrackingEs._(_root);
	@override late final _TranslationsChecklistEs checklist = _TranslationsChecklistEs._(_root);
	@override late final _TranslationsJournalEs journal = _TranslationsJournalEs._(_root);
	@override late final _TranslationsWeatherEs weather = _TranslationsWeatherEs._(_root);
	@override late final _TranslationsShareEs share = _TranslationsShareEs._(_root);
	@override late final _TranslationsDiplomaEs diploma = _TranslationsDiplomaEs._(_root);
	@override late final _TranslationsNotificationsEs notifications = _TranslationsNotificationsEs._(_root);
	@override late final _TranslationsSettingsEs settings = _TranslationsSettingsEs._(_root);
	@override late final _TranslationsFeedbackEs feedback = _TranslationsFeedbackEs._(_root);
	@override late final _TranslationsAuthEs auth = _TranslationsAuthEs._(_root);
}

// Path: map
class _TranslationsMapEs extends _TranslationsMapFr {
	_TranslationsMapEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mapa del sendero';
	@override String get loading => 'Cargando el recorrido...';
	@override String get noTrack => 'NingÃºn recorrido disponible';
	@override String get viewMap => 'Ver el mapa';
}

// Path: stage
class _TranslationsStageEs extends _TranslationsStageFr {
	_TranslationsStageEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distancia';
	@override String get elevation => 'Desnivel';
	@override String get elevationGain => 'Desnivel positivo';
	@override String get elevationLoss => 'Desnivel negativo';
	@override String get duration => 'DuraciÃ³n estimada';
	@override String get description => 'DescripciÃ³n';
	@override String get coordinates => 'Coordenadas';
	@override String get pois => 'Puntos de interÃ©s';
	@override late final _TranslationsStageDifficultyEs difficulty = _TranslationsStageDifficultyEs._(_root);
	@override String get remaining => '{distance} km restantes';
	@override String get arrived => 'Has llegado!';
}

// Path: trail
class _TranslationsTrailEs extends _TranslationsTrailFr {
	_TranslationsTrailEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etapas';
	@override String get totalDistance => 'Distancia total';
	@override String get totalElevation => 'Desnivel total';
}

// Path: poi
class _TranslationsPoiEs extends _TranslationsPoiFr {
	_TranslationsPoiEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Refugio';
	@override String get water => 'Fuente de agua';
	@override String get viewpoint => 'Mirador';
	@override String get campsite => 'Vivac';
	@override String get restaurant => 'Restaurante';
	@override String get emergency => 'Emergencia';
	@override String get danger => 'Peligro';
	@override String get shop => 'Tienda';
	@override String get filter => 'Filtrar puntos de interÃ©s';
	@override String get altitude => 'Altitud';
	@override String get hours => 'Horarios';
}

// Path: gps
class _TranslationsGpsEs extends _TranslationsGpsFr {
	_TranslationsGpsEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get permission => 'Permiso GPS requerido';
	@override String get denied => 'Acceso a la ubicacion denegado';
	@override String get disabled => 'Servicio de ubicacion desactivado';
	@override String get offTrack => 'Fuera del sendero';
	@override String get centerOnMe => 'Centrar en mi posicion';
}

// Path: planning
class _TranslationsPlanningEs extends _TranslationsPlanningFr {
	_TranslationsPlanningEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planificación';
	@override String get duration => 'Duración';
	@override String get days => 'días';
	@override String get day => 'Día';
	@override String get restDay => 'Día de descanso';
	@override String get totalDistance => 'Distancia total';
	@override String get totalElevation => 'Desnivel total';
	@override String get estimatedTime => 'Duración estimada';
	@override String get stages => 'Etapas';
	@override String get plan => 'Planificar';
}

// Path: tracking
class _TranslationsTrackingEs extends _TranslationsTrackingFr {
	_TranslationsTrackingEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get start => 'Iniciar';
	@override String get pause => 'Pausa';
	@override String get resume => 'Reanudar';
	@override String get stop => 'Detener';
	@override String get distance => 'Distancia';
	@override String get elevation => 'Desnivel';
	@override String get speed => 'Velocidad';
	@override String get time => 'Tiempo';
	@override String get confirmStop => 'Detener el seguimiento?';
}

// Path: checklist
class _TranslationsChecklistEs extends _TranslationsChecklistFr {
	_TranslationsChecklistEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lista de equipo';
	@override String get subtitle => 'Prepara tu mochila';
	@override String get progress => '{checked}/{total} preparados';
	@override String get complete => 'Lista completa!';
	@override String get reset => 'Reiniciar';
	@override String get resetConfirm => 'Reiniciar la lista?';
	@override String get resetDescription => 'Todos los elementos serán desmarcados.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override late final _TranslationsChecklistCategoriesEs categories = _TranslationsChecklistCategoriesEs._(_root);
	@override late final _TranslationsChecklistItemsEs items = _TranslationsChecklistItemsEs._(_root);
	@override String get essential => 'Esencial';
}

// Path: journal
class _TranslationsJournalEs extends _TranslationsJournalFr {
	_TranslationsJournalEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diario de trekking';
	@override String get empty => 'Tu diario está vacío';
	@override String get emptySubtitle => 'Anota tus impresiones y recuerdos de trekking';
	@override String get addNote => 'Nueva nota';
	@override String get stage => 'Etapa';
	@override String get yourNote => 'Tu nota';
	@override String get placeholder => 'Describe tu día de senderismo...';
	@override String get save => 'Guardar';
	@override String get cancel => 'Cancelar';
	@override String get delete => 'Eliminar';
	@override String get photoLimit => 'Límite de 3 fotos por día alcanzado';
	@override String get photoTooBig => 'Foto demasiado grande (máx 500 KB)';
}

// Path: weather
class _TranslationsWeatherEs extends _TranslationsWeatherFr {
	_TranslationsWeatherEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meteorología';
	@override String get loading => 'Cargando meteorología...';
	@override String get offline => 'Sin conexión. Datos meteorológicos no disponibles.';
	@override String get error => 'No se pudo cargar la meteorología.';
	@override String get cached => 'Datos en caché';
	@override String get alerts => 'alertas meteorológicas';
	@override String get refresh => 'Actualizar';
	@override String get temperature => 'Temperatura';
	@override String get precipitation => 'Precipitación';
	@override String get wind => 'Viento';
	@override String get uv => 'Índice UV';
}

// Path: share
class _TranslationsShareEs extends _TranslationsShareFr {
	_TranslationsShareEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Compartir';
	@override String get generating => 'Generando...';
	@override String get share => 'Compartir';
	@override String get error => 'Error durante la generación';
}

// Path: diploma
class _TranslationsDiplomaEs extends _TranslationsDiplomaFr {
	_TranslationsDiplomaEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diploma de trekking';
	@override String get yourName => 'Tu nombre';
	@override String get namePlaceholder => 'Introduce tu nombre...';
	@override String get generatePdf => 'Generar PDF';
	@override String get certifies => 'Certifica que';
	@override String get completed => 'ha recorrido el';
}

// Path: notifications
class _TranslationsNotificationsEs extends _TranslationsNotificationsFr {
	_TranslationsNotificationsEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Recordatorio matutino';
	@override String get weatherAlerts => 'Alertas meteorológicas';
	@override String get countdown => 'Recordatorio D-2';
	@override String get countdownDesc => 'Notificación 2 días antes de la salida';
}

// Path: settings
class _TranslationsSettingsEs extends _TranslationsSettingsFr {
	_TranslationsSettingsEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ajustes';
	@override String get language => 'Idioma';
	@override String get units => 'Unidades';
	@override String get distance => 'Distancia';
	@override String get temperature => 'Temperatura';
	@override String get theme => 'Tema';
	@override String get dark => 'Oscuro';
	@override String get light => 'Claro';
	@override String get system => 'Sistema';
	@override String get cache => 'Caché';
	@override String get cacheEnabled => 'Caché activada';
	@override String get cacheDesc => 'Datos disponibles sin conexión';
	@override String get cacheSize => 'Tamaño de caché';
	@override String get notifications => 'Notificaciones';
}

// Path: feedback
class _TranslationsFeedbackEs extends _TranslationsFeedbackFr {
	_TranslationsFeedbackEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Comentarios';
	@override String get type => 'Tipo de comentario';
	@override String get bug => 'Error / Problema';
	@override String get suggestion => 'Sugerencia';
	@override String get question => 'Pregunta';
	@override String get other => 'Otro';
	@override String get message => 'Tu mensaje';
	@override String get messagePlaceholder => 'Describe tu comentario...';
	@override String get satisfaction => 'Satisfacción';
	@override String get send => 'Enviar';
	@override String get sending => 'Enviando...';
	@override String get thanks => '¡Gracias por tu comentario!';
	@override String get pending => 'pendiente';
}

// Path: auth
class _TranslationsAuthEs extends _TranslationsAuthFr {
	_TranslationsAuthEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Perfil';
	@override String get anonymous => 'Senderista anónimo';
	@override String get connectedVia => 'Conectado vía';
	@override String get signInGoogle => 'Iniciar sesión con Google';
	@override String get signInGoogleDesc => 'Para guardar tu progreso';
	@override String get signOut => 'Cerrar sesión';
	@override String get signOutDesc => 'Volver al modo anónimo';
	@override String get signOutConfirm => '¿Cerrar sesión?';
	@override String get signOutMessage => 'Volverás al modo anónimo. Tus datos locales se conservan.';
	@override String get deleteAccount => 'Eliminar mi cuenta';
	@override String get deleteAccountDesc => 'Todos tus datos serán borrados';
	@override String get deleteConfirm => '¿Eliminar tu cuenta?';
	@override String get deleteMessage => 'Esta acción es irreversible. Todos tus datos, notas y progreso serán eliminados.';
	@override String get cancel => 'Cancelar';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyEs extends _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get easy => 'FÃ¡cil';
	@override String get moderate => 'Moderado';
	@override String get hard => 'DifÃ­cil';
	@override String get expert => 'Experto';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesEs extends _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Equipo';
	@override String get clothing => 'Ropa';
	@override String get food => 'Alimentación';
	@override String get safety => 'Seguridad';
	@override String get documents => 'Documentos';
	@override String get hygiene => 'Higiene';
}

// Path: checklist.items
class _TranslationsChecklistItemsEs extends _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsEs._(_TranslationsEs root) : this._root = root, super._(root);

	@override final _TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Mochila';
	@override String get sleepingBag => 'Saco de dormir';
	@override String get sleepingPad => 'Esterilla';
	@override String get hikingPoles => 'Bastones de senderismo';
	@override String get headlamp => 'Linterna frontal';
	@override String get waterBottle => 'Botella de agua';
	@override String get hikingBoots => 'Botas de senderismo';
	@override String get rainJacket => 'Chaqueta impermeable';
	@override String get warmLayer => 'Capa de abrigo';
	@override String get hikingSocks => 'Calcetines de senderismo';
	@override String get hat => 'Sombrero';
	@override String get gloves => 'Guantes';
	@override String get trailSnacks => 'Snacks de sendero';
	@override String get energyBars => 'Barritas energéticas';
	@override String get waterPurification => 'Purificación de agua';
	@override String get firstAidKit => 'Botiquín';
	@override String get whistle => 'Silbato';
	@override String get emergencyBlanket => 'Manta de emergencia';
	@override String get sunscreen => 'Protector solar';
	@override String get idCard => 'Documento de identidad';
	@override String get insurance => 'Seguro';
	@override String get trailMap => 'Mapa del sendero';
	@override String get toiletPaper => 'Papel higiénico';
	@override String get handSanitizer => 'Gel desinfectante';
	@override String get towel => 'Toalla';
}

// Path: <root>
class _TranslationsIt extends Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	_TranslationsIt.build({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super.build(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	@override late final _TranslationsIt _root = this; // ignore: unused_field

	// Translations
	@override late final _TranslationsMapIt map = _TranslationsMapIt._(_root);
	@override late final _TranslationsStageIt stage = _TranslationsStageIt._(_root);
	@override late final _TranslationsTrailIt trail = _TranslationsTrailIt._(_root);
	@override late final _TranslationsPoiIt poi = _TranslationsPoiIt._(_root);
	@override late final _TranslationsGpsIt gps = _TranslationsGpsIt._(_root);
	@override late final _TranslationsPlanningIt planning = _TranslationsPlanningIt._(_root);
	@override late final _TranslationsTrackingIt tracking = _TranslationsTrackingIt._(_root);
	@override late final _TranslationsChecklistIt checklist = _TranslationsChecklistIt._(_root);
	@override late final _TranslationsJournalIt journal = _TranslationsJournalIt._(_root);
	@override late final _TranslationsWeatherIt weather = _TranslationsWeatherIt._(_root);
	@override late final _TranslationsShareIt share = _TranslationsShareIt._(_root);
	@override late final _TranslationsDiplomaIt diploma = _TranslationsDiplomaIt._(_root);
	@override late final _TranslationsNotificationsIt notifications = _TranslationsNotificationsIt._(_root);
	@override late final _TranslationsSettingsIt settings = _TranslationsSettingsIt._(_root);
	@override late final _TranslationsFeedbackIt feedback = _TranslationsFeedbackIt._(_root);
	@override late final _TranslationsAuthIt auth = _TranslationsAuthIt._(_root);
}

// Path: map
class _TranslationsMapIt extends _TranslationsMapFr {
	_TranslationsMapIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mappa del sentiero';
	@override String get loading => 'Caricamento del tracciato...';
	@override String get noTrack => 'Nessun tracciato disponibile';
	@override String get viewMap => 'Vedi la mappa';
}

// Path: stage
class _TranslationsStageIt extends _TranslationsStageFr {
	_TranslationsStageIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distanza';
	@override String get elevation => 'Dislivello';
	@override String get elevationGain => 'Dislivello positivo';
	@override String get elevationLoss => 'Dislivello negativo';
	@override String get duration => 'Durata stimata';
	@override String get description => 'Descrizione';
	@override String get coordinates => 'Coordinate';
	@override String get pois => 'Punti di interesse';
	@override late final _TranslationsStageDifficultyIt difficulty = _TranslationsStageDifficultyIt._(_root);
	@override String get remaining => '{distance} km rimanenti';
	@override String get arrived => 'Sei arrivato!';
}

// Path: trail
class _TranslationsTrailIt extends _TranslationsTrailFr {
	_TranslationsTrailIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Tappe';
	@override String get totalDistance => 'Distanza totale';
	@override String get totalElevation => 'Dislivello totale';
}

// Path: poi
class _TranslationsPoiIt extends _TranslationsPoiFr {
	_TranslationsPoiIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Rifugio';
	@override String get water => 'Fonte d\'acqua';
	@override String get viewpoint => 'Punto panoramico';
	@override String get campsite => 'Bivacco';
	@override String get restaurant => 'Ristorante';
	@override String get emergency => 'Emergenza';
	@override String get danger => 'Pericolo';
	@override String get shop => 'Negozio';
	@override String get filter => 'Filtra i punti di interesse';
	@override String get altitude => 'Altitudine';
	@override String get hours => 'Orari';
}

// Path: gps
class _TranslationsGpsIt extends _TranslationsGpsFr {
	_TranslationsGpsIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get permission => 'Autorizzazione GPS richiesta';
	@override String get denied => 'Accesso alla posizione negato';
	@override String get disabled => 'Servizio di localizzazione disattivato';
	@override String get offTrack => 'Fuori tracciato';
	@override String get centerOnMe => 'Centra sulla mia posizione';
}

// Path: planning
class _TranslationsPlanningIt extends _TranslationsPlanningFr {
	_TranslationsPlanningIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pianificazione';
	@override String get duration => 'Durata';
	@override String get days => 'giorni';
	@override String get day => 'Giorno';
	@override String get restDay => 'Giorno di riposo';
	@override String get totalDistance => 'Distanza totale';
	@override String get totalElevation => 'Dislivello totale';
	@override String get estimatedTime => 'Durata stimata';
	@override String get stages => 'Tappe';
	@override String get plan => 'Pianificare';
}

// Path: tracking
class _TranslationsTrackingIt extends _TranslationsTrackingFr {
	_TranslationsTrackingIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get start => 'Avvia';
	@override String get pause => 'Pausa';
	@override String get resume => 'Riprendi';
	@override String get stop => 'Ferma';
	@override String get distance => 'Distanza';
	@override String get elevation => 'Dislivello';
	@override String get speed => 'Velocita';
	@override String get time => 'Tempo';
	@override String get confirmStop => 'Fermare il tracciamento?';
}

// Path: checklist
class _TranslationsChecklistIt extends _TranslationsChecklistFr {
	_TranslationsChecklistIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lista equipaggiamento';
	@override String get subtitle => 'Prepara lo zaino';
	@override String get progress => '{checked}/{total} preparati';
	@override String get complete => 'Lista completa!';
	@override String get reset => 'Reimposta';
	@override String get resetConfirm => 'Reimpostare la lista?';
	@override String get resetDescription => 'Tutti gli elementi saranno deselezionati.';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'Conferma';
	@override late final _TranslationsChecklistCategoriesIt categories = _TranslationsChecklistCategoriesIt._(_root);
	@override late final _TranslationsChecklistItemsIt items = _TranslationsChecklistItemsIt._(_root);
	@override String get essential => 'Essenziale';
}

// Path: journal
class _TranslationsJournalIt extends _TranslationsJournalFr {
	_TranslationsJournalIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diario di trekking';
	@override String get empty => 'Il tuo diario è vuoto';
	@override String get emptySubtitle => 'Annota le tue impressioni e ricordi di trekking';
	@override String get addNote => 'Nuova nota';
	@override String get stage => 'Tappa';
	@override String get yourNote => 'La tua nota';
	@override String get placeholder => 'Descrivi la tua giornata di trekking...';
	@override String get save => 'Salva';
	@override String get cancel => 'Annulla';
	@override String get delete => 'Elimina';
	@override String get photoLimit => 'Limite di 3 foto al giorno raggiunto';
	@override String get photoTooBig => 'Foto troppo grande (max 500 KB)';
}

// Path: weather
class _TranslationsWeatherIt extends _TranslationsWeatherFr {
	_TranslationsWeatherIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meteo';
	@override String get loading => 'Caricamento meteo...';
	@override String get offline => 'Nessuna connessione. Dati meteo non disponibili.';
	@override String get error => 'Impossibile caricare il meteo.';
	@override String get cached => 'Dati nella cache';
	@override String get alerts => 'allerte meteo';
	@override String get refresh => 'Aggiorna';
	@override String get temperature => 'Temperatura';
	@override String get precipitation => 'Precipitazioni';
	@override String get wind => 'Vento';
	@override String get uv => 'Indice UV';
}

// Path: share
class _TranslationsShareIt extends _TranslationsShareFr {
	_TranslationsShareIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Condividi';
	@override String get generating => 'Generazione...';
	@override String get share => 'Condividi';
	@override String get error => 'Errore durante la generazione';
}

// Path: diploma
class _TranslationsDiplomaIt extends _TranslationsDiplomaFr {
	_TranslationsDiplomaIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diploma di trekking';
	@override String get yourName => 'Il tuo nome';
	@override String get namePlaceholder => 'Inserisci il tuo nome...';
	@override String get generatePdf => 'Genera PDF';
	@override String get certifies => 'Certifica che';
	@override String get completed => 'ha percorso il';
}

// Path: notifications
class _TranslationsNotificationsIt extends _TranslationsNotificationsFr {
	_TranslationsNotificationsIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Promemoria mattutino';
	@override String get weatherAlerts => 'Allerte meteo';
	@override String get countdown => 'Promemoria G-2';
	@override String get countdownDesc => 'Notifica 2 giorni prima della partenza';
}

// Path: settings
class _TranslationsSettingsIt extends _TranslationsSettingsFr {
	_TranslationsSettingsIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Impostazioni';
	@override String get language => 'Lingua';
	@override String get units => 'Unità';
	@override String get distance => 'Distanza';
	@override String get temperature => 'Temperatura';
	@override String get theme => 'Tema';
	@override String get dark => 'Scuro';
	@override String get light => 'Chiaro';
	@override String get system => 'Sistema';
	@override String get cache => 'Cache';
	@override String get cacheEnabled => 'Cache attivata';
	@override String get cacheDesc => 'Dati disponibili offline';
	@override String get cacheSize => 'Dimensione cache';
	@override String get notifications => 'Notifiche';
}

// Path: feedback
class _TranslationsFeedbackIt extends _TranslationsFeedbackFr {
	_TranslationsFeedbackIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Tipo di feedback';
	@override String get bug => 'Bug / Problema';
	@override String get suggestion => 'Suggerimento';
	@override String get question => 'Domanda';
	@override String get other => 'Altro';
	@override String get message => 'Il tuo messaggio';
	@override String get messagePlaceholder => 'Descrivi il tuo feedback...';
	@override String get satisfaction => 'Soddisfazione';
	@override String get send => 'Invia';
	@override String get sending => 'Invio...';
	@override String get thanks => 'Grazie per il tuo feedback!';
	@override String get pending => 'in attesa';
}

// Path: auth
class _TranslationsAuthIt extends _TranslationsAuthFr {
	_TranslationsAuthIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profilo';
	@override String get anonymous => 'Escursionista anonimo';
	@override String get connectedVia => 'Connesso tramite';
	@override String get signInGoogle => 'Accedi con Google';
	@override String get signInGoogleDesc => 'Per salvare i tuoi progressi';
	@override String get signOut => 'Esci';
	@override String get signOutDesc => 'Torna alla modalità anonima';
	@override String get signOutConfirm => 'Disconnettersi?';
	@override String get signOutMessage => 'Tornerai alla modalità anonima. I tuoi dati locali saranno conservati.';
	@override String get deleteAccount => 'Elimina il mio account';
	@override String get deleteAccountDesc => 'Tutti i tuoi dati saranno cancellati';
	@override String get deleteConfirm => 'Eliminare il tuo account?';
	@override String get deleteMessage => 'Questa azione è irreversibile. Tutti i tuoi dati, note e progressi saranno cancellati.';
	@override String get cancel => 'Annulla';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyIt extends _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Facile';
	@override String get moderate => 'Moderato';
	@override String get hard => 'Difficile';
	@override String get expert => 'Esperto';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesIt extends _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Equipaggiamento';
	@override String get clothing => 'Abbigliamento';
	@override String get food => 'Alimentazione';
	@override String get safety => 'Sicurezza';
	@override String get documents => 'Documenti';
	@override String get hygiene => 'Igiene';
}

// Path: checklist.items
class _TranslationsChecklistItemsIt extends _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsIt._(_TranslationsIt root) : this._root = root, super._(root);

	@override final _TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Zaino';
	@override String get sleepingBag => 'Sacco a pelo';
	@override String get sleepingPad => 'Materassino';
	@override String get hikingPoles => 'Bastoncini da trekking';
	@override String get headlamp => 'Lampada frontale';
	@override String get waterBottle => 'Borraccia';
	@override String get hikingBoots => 'Scarpe da trekking';
	@override String get rainJacket => 'Giacca impermeabile';
	@override String get warmLayer => 'Strato caldo';
	@override String get hikingSocks => 'Calzini da trekking';
	@override String get hat => 'Cappello';
	@override String get gloves => 'Guanti';
	@override String get trailSnacks => 'Snack da sentiero';
	@override String get energyBars => 'Barrette energetiche';
	@override String get waterPurification => 'Purificazione dell\'acqua';
	@override String get firstAidKit => 'Kit di primo soccorso';
	@override String get whistle => 'Fischietto';
	@override String get emergencyBlanket => 'Coperta di emergenza';
	@override String get sunscreen => 'Protezione solare';
	@override String get idCard => 'Carta d\'identità';
	@override String get insurance => 'Assicurazione';
	@override String get trailMap => 'Mappa del sentiero';
	@override String get toiletPaper => 'Carta igienica';
	@override String get handSanitizer => 'Disinfettante mani';
	@override String get towel => 'Asciugamano';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'map.title': return 'Carte du sentier';
			case 'map.loading': return 'Chargement du tracÃ©...';
			case 'map.noTrack': return 'Aucun tracÃ© disponible';
			case 'map.viewMap': return 'Voir la carte';
			case 'stage.distance': return 'Distance';
			case 'stage.elevation': return 'DÃ©nivelÃ©';
			case 'stage.elevationGain': return 'DÃ©nivelÃ© positif';
			case 'stage.elevationLoss': return 'DÃ©nivelÃ© nÃ©gatif';
			case 'stage.duration': return 'DurÃ©e estimÃ©e';
			case 'stage.description': return 'Description';
			case 'stage.coordinates': return 'CoordonnÃ©es';
			case 'stage.pois': return 'Points d\'intÃ©rÃªt';
			case 'stage.difficulty.easy': return 'Facile';
			case 'stage.difficulty.moderate': return 'ModÃ©rÃ©';
			case 'stage.difficulty.hard': return 'Difficile';
			case 'stage.difficulty.expert': return 'Expert';
			case 'stage.remaining': return '{distance} km restants';
			case 'stage.arrived': return 'Vous etes arrive !';
			case 'trail.stages': return 'Ãtapes';
			case 'trail.totalDistance': return 'Distance totale';
			case 'trail.totalElevation': return 'DÃ©nivelÃ© total';
			case 'poi.shelter': return 'Refuge';
			case 'poi.water': return 'Point d\'eau';
			case 'poi.viewpoint': return 'Point de vue';
			case 'poi.campsite': return 'Bivouac';
			case 'poi.restaurant': return 'Restaurant';
			case 'poi.emergency': return 'Urgence';
			case 'poi.danger': return 'Danger';
			case 'poi.shop': return 'Commerce';
			case 'poi.filter': return 'Filtrer les points d\'intÃ©rÃªt';
			case 'poi.altitude': return 'Altitude';
			case 'poi.hours': return 'Horaires';
			case 'gps.permission': return 'Autorisation GPS requise';
			case 'gps.denied': return 'Acces a la localisation refuse';
			case 'gps.disabled': return 'Service de localisation desactive';
			case 'gps.offTrack': return 'Hors trace';
			case 'gps.centerOnMe': return 'Centrer sur ma position';
			case 'planning.title': return 'Planning';
			case 'planning.duration': return 'Durée';
			case 'planning.days': return 'jours';
			case 'planning.day': return 'Jour';
			case 'planning.restDay': return 'Jour de repos';
			case 'planning.totalDistance': return 'Distance totale';
			case 'planning.totalElevation': return 'Dénivelé total';
			case 'planning.estimatedTime': return 'Durée estimée';
			case 'planning.stages': return 'Étapes';
			case 'planning.plan': return 'Planifier';
			case 'tracking.start': return 'Demarrer';
			case 'tracking.pause': return 'Pause';
			case 'tracking.resume': return 'Reprendre';
			case 'tracking.stop': return 'Arreter';
			case 'tracking.distance': return 'Distance';
			case 'tracking.elevation': return 'Denivele';
			case 'tracking.speed': return 'Vitesse';
			case 'tracking.time': return 'Temps';
			case 'tracking.confirmStop': return 'Arreter le tracking ?';
			case 'checklist.title': return 'Checklist matériel';
			case 'checklist.subtitle': return 'Préparez votre sac à dos';
			case 'checklist.progress': return '{checked}/{total} préparés';
			case 'checklist.complete': return 'Checklist complète !';
			case 'checklist.reset': return 'Réinitialiser';
			case 'checklist.resetConfirm': return 'Réinitialiser la checklist ?';
			case 'checklist.resetDescription': return 'Tous les éléments seront décochés.';
			case 'checklist.cancel': return 'Annuler';
			case 'checklist.confirm': return 'Confirmer';
			case 'checklist.categories.equipment': return 'Équipement';
			case 'checklist.categories.clothing': return 'Vêtements';
			case 'checklist.categories.food': return 'Alimentation';
			case 'checklist.categories.safety': return 'Sécurité';
			case 'checklist.categories.documents': return 'Documents';
			case 'checklist.categories.hygiene': return 'Hygiène';
			case 'checklist.items.backpack': return 'Sac à dos';
			case 'checklist.items.sleepingBag': return 'Sac de couchage';
			case 'checklist.items.sleepingPad': return 'Matelas de sol';
			case 'checklist.items.hikingPoles': return 'Bâtons de marche';
			case 'checklist.items.headlamp': return 'Lampe frontale';
			case 'checklist.items.waterBottle': return 'Gourde';
			case 'checklist.items.hikingBoots': return 'Chaussures de randonnée';
			case 'checklist.items.rainJacket': return 'Veste imperméable';
			case 'checklist.items.warmLayer': return 'Couche chaude';
			case 'checklist.items.hikingSocks': return 'Chaussettes de randonnée';
			case 'checklist.items.hat': return 'Chapeau';
			case 'checklist.items.gloves': return 'Gants';
			case 'checklist.items.trailSnacks': return 'Encas de marche';
			case 'checklist.items.energyBars': return 'Barres énergétiques';
			case 'checklist.items.waterPurification': return 'Purification d\'eau';
			case 'checklist.items.firstAidKit': return 'Trousse de secours';
			case 'checklist.items.whistle': return 'Sifflet';
			case 'checklist.items.emergencyBlanket': return 'Couverture de survie';
			case 'checklist.items.sunscreen': return 'Crème solaire';
			case 'checklist.items.idCard': return 'Pièce d\'identité';
			case 'checklist.items.insurance': return 'Assurance';
			case 'checklist.items.trailMap': return 'Carte du sentier';
			case 'checklist.items.toiletPaper': return 'Papier toilette';
			case 'checklist.items.handSanitizer': return 'Gel hydroalcoolique';
			case 'checklist.items.towel': return 'Serviette';
			case 'checklist.essential': return 'Essentiel';
			case 'journal.title': return 'Journal de trek';
			case 'journal.empty': return 'Votre journal est vide';
			case 'journal.emptySubtitle': return 'Notez vos impressions et souvenirs de trek';
			case 'journal.addNote': return 'Nouvelle note';
			case 'journal.stage': return 'Étape';
			case 'journal.yourNote': return 'Votre note';
			case 'journal.placeholder': return 'Décrivez votre journée de trek...';
			case 'journal.save': return 'Enregistrer';
			case 'journal.cancel': return 'Annuler';
			case 'journal.delete': return 'Supprimer';
			case 'journal.photoLimit': return 'Limite de 3 photos par jour atteinte';
			case 'journal.photoTooBig': return 'Photo trop volumineuse (max 500 Ko)';
			case 'weather.title': return 'Météo';
			case 'weather.loading': return 'Chargement de la météo...';
			case 'weather.offline': return 'Pas de connexion. Données météo indisponibles.';
			case 'weather.error': return 'Impossible de charger la météo.';
			case 'weather.cached': return 'Données en cache';
			case 'weather.alerts': return 'alertes météo';
			case 'weather.refresh': return 'Actualiser';
			case 'weather.temperature': return 'Température';
			case 'weather.precipitation': return 'Précipitations';
			case 'weather.wind': return 'Vent';
			case 'weather.uv': return 'Indice UV';
			case 'share.title': return 'Partager';
			case 'share.generating': return 'Génération...';
			case 'share.share': return 'Partager';
			case 'share.error': return 'Erreur lors de la génération';
			case 'diploma.title': return 'Diplôme de trek';
			case 'diploma.yourName': return 'Votre nom';
			case 'diploma.namePlaceholder': return 'Entrez votre nom...';
			case 'diploma.generatePdf': return 'Générer le PDF';
			case 'diploma.certifies': return 'Certifie que';
			case 'diploma.completed': return 'a parcouru le';
			case 'notifications.morningReminder': return 'Rappel du matin';
			case 'notifications.weatherAlerts': return 'Alertes météo';
			case 'notifications.countdown': return 'Rappel J-2';
			case 'notifications.countdownDesc': return 'Notification 2 jours avant le départ';
			case 'settings.title': return 'Paramètres';
			case 'settings.language': return 'Langue';
			case 'settings.units': return 'Unités';
			case 'settings.distance': return 'Distance';
			case 'settings.temperature': return 'Température';
			case 'settings.theme': return 'Thème';
			case 'settings.dark': return 'Sombre';
			case 'settings.light': return 'Clair';
			case 'settings.system': return 'Système';
			case 'settings.cache': return 'Cache';
			case 'settings.cacheEnabled': return 'Cache activé';
			case 'settings.cacheDesc': return 'Données disponibles hors ligne';
			case 'settings.cacheSize': return 'Taille du cache';
			case 'settings.notifications': return 'Notifications';
			case 'feedback.title': return 'Feedback';
			case 'feedback.type': return 'Type de retour';
			case 'feedback.bug': return 'Bug / Problème';
			case 'feedback.suggestion': return 'Suggestion';
			case 'feedback.question': return 'Question';
			case 'feedback.other': return 'Autre';
			case 'feedback.message': return 'Votre message';
			case 'feedback.messagePlaceholder': return 'Décrivez votre retour...';
			case 'feedback.satisfaction': return 'Satisfaction';
			case 'feedback.send': return 'Envoyer';
			case 'feedback.sending': return 'Envoi...';
			case 'feedback.thanks': return 'Merci pour votre retour !';
			case 'feedback.pending': return 'en attente';
			case 'auth.profile': return 'Profil';
			case 'auth.anonymous': return 'Randonneur anonyme';
			case 'auth.connectedVia': return 'Connecté via';
			case 'auth.signInGoogle': return 'Se connecter avec Google';
			case 'auth.signInGoogleDesc': return 'Pour sauvegarder votre progression';
			case 'auth.signOut': return 'Se déconnecter';
			case 'auth.signOutDesc': return 'Revenir en mode anonyme';
			case 'auth.signOutConfirm': return 'Se déconnecter ?';
			case 'auth.signOutMessage': return 'Vous reviendrez en mode anonyme. Vos données locales sont conservées.';
			case 'auth.deleteAccount': return 'Supprimer mon compte';
			case 'auth.deleteAccountDesc': return 'Toutes vos données seront effacées';
			case 'auth.deleteConfirm': return 'Supprimer votre compte ?';
			case 'auth.deleteMessage': return 'Cette action est irréversible. Toutes vos données, notes et progression seront effacées.';
			case 'auth.cancel': return 'Annuler';
			default: return null;
		}
	}
}

extension on _TranslationsDe {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'map.title': return 'Wanderkarte';
			case 'map.loading': return 'Strecke wird geladen...';
			case 'map.noTrack': return 'Keine Strecke verfÃ¼gbar';
			case 'map.viewMap': return 'Karte anzeigen';
			case 'stage.distance': return 'Entfernung';
			case 'stage.elevation': return 'HÃ¶henunterschied';
			case 'stage.elevationGain': return 'HÃ¶henmeter aufwÃ¤rts';
			case 'stage.elevationLoss': return 'HÃ¶henmeter abwÃ¤rts';
			case 'stage.duration': return 'GeschÃ¤tzte Dauer';
			case 'stage.description': return 'Beschreibung';
			case 'stage.coordinates': return 'Koordinaten';
			case 'stage.pois': return 'SehenswÃ¼rdigkeiten';
			case 'stage.difficulty.easy': return 'Leicht';
			case 'stage.difficulty.moderate': return 'Mittel';
			case 'stage.difficulty.hard': return 'Schwer';
			case 'stage.difficulty.expert': return 'Experte';
			case 'stage.remaining': return '{distance} km verbleibend';
			case 'stage.arrived': return 'Sie sind angekommen!';
			case 'trail.stages': return 'Etappen';
			case 'trail.totalDistance': return 'Gesamtstrecke';
			case 'trail.totalElevation': return 'GesamthÃ¶henmeter';
			case 'poi.shelter': return 'SchutzhÃ¼tte';
			case 'poi.water': return 'Wasserquelle';
			case 'poi.viewpoint': return 'Aussichtspunkt';
			case 'poi.campsite': return 'Biwakplatz';
			case 'poi.restaurant': return 'Restaurant';
			case 'poi.emergency': return 'Notfall';
			case 'poi.danger': return 'Gefahr';
			case 'poi.shop': return 'GeschÃ¤ft';
			case 'poi.filter': return 'SehenswÃ¼rdigkeiten filtern';
			case 'poi.altitude': return 'HÃ¶he';
			case 'poi.hours': return 'Ãffnungszeiten';
			case 'gps.permission': return 'GPS-Berechtigung erforderlich';
			case 'gps.denied': return 'Standortzugriff verweigert';
			case 'gps.disabled': return 'Standortdienst deaktiviert';
			case 'gps.offTrack': return 'Abseits der Strecke';
			case 'gps.centerOnMe': return 'Auf meine Position zentrieren';
			case 'planning.title': return 'Planung';
			case 'planning.duration': return 'Dauer';
			case 'planning.days': return 'Tage';
			case 'planning.day': return 'Tag';
			case 'planning.restDay': return 'Ruhetag';
			case 'planning.totalDistance': return 'Gesamtstrecke';
			case 'planning.totalElevation': return 'Gesamthöhenmeter';
			case 'planning.estimatedTime': return 'Geschätzte Dauer';
			case 'planning.stages': return 'Etappen';
			case 'planning.plan': return 'Planen';
			case 'tracking.start': return 'Starten';
			case 'tracking.pause': return 'Pause';
			case 'tracking.resume': return 'Fortsetzen';
			case 'tracking.stop': return 'Stoppen';
			case 'tracking.distance': return 'Entfernung';
			case 'tracking.elevation': return 'Hohenmeter';
			case 'tracking.speed': return 'Geschwindigkeit';
			case 'tracking.time': return 'Zeit';
			case 'tracking.confirmStop': return 'Tracking stoppen?';
			case 'checklist.title': return 'Ausrüstungsliste';
			case 'checklist.subtitle': return 'Packen Sie Ihren Rucksack';
			case 'checklist.progress': return '{checked}/{total} gepackt';
			case 'checklist.complete': return 'Checkliste vollständig!';
			case 'checklist.reset': return 'Zurücksetzen';
			case 'checklist.resetConfirm': return 'Checkliste zurücksetzen?';
			case 'checklist.resetDescription': return 'Alle Elemente werden abgehakt.';
			case 'checklist.cancel': return 'Abbrechen';
			case 'checklist.confirm': return 'Bestätigen';
			case 'checklist.categories.equipment': return 'Ausrüstung';
			case 'checklist.categories.clothing': return 'Kleidung';
			case 'checklist.categories.food': return 'Verpflegung';
			case 'checklist.categories.safety': return 'Sicherheit';
			case 'checklist.categories.documents': return 'Dokumente';
			case 'checklist.categories.hygiene': return 'Hygiene';
			case 'checklist.items.backpack': return 'Rucksack';
			case 'checklist.items.sleepingBag': return 'Schlafsack';
			case 'checklist.items.sleepingPad': return 'Isomatte';
			case 'checklist.items.hikingPoles': return 'Wanderstöcke';
			case 'checklist.items.headlamp': return 'Stirnlampe';
			case 'checklist.items.waterBottle': return 'Trinkflasche';
			case 'checklist.items.hikingBoots': return 'Wanderschuhe';
			case 'checklist.items.rainJacket': return 'Regenjacke';
			case 'checklist.items.warmLayer': return 'Wärmeschicht';
			case 'checklist.items.hikingSocks': return 'Wandersocken';
			case 'checklist.items.hat': return 'Hut';
			case 'checklist.items.gloves': return 'Handschuhe';
			case 'checklist.items.trailSnacks': return 'Wandersnacks';
			case 'checklist.items.energyBars': return 'Energieriegel';
			case 'checklist.items.waterPurification': return 'Wasseraufbereitung';
			case 'checklist.items.firstAidKit': return 'Erste-Hilfe-Set';
			case 'checklist.items.whistle': return 'Pfeife';
			case 'checklist.items.emergencyBlanket': return 'Rettungsdecke';
			case 'checklist.items.sunscreen': return 'Sonnenschutz';
			case 'checklist.items.idCard': return 'Ausweis';
			case 'checklist.items.insurance': return 'Versicherung';
			case 'checklist.items.trailMap': return 'Wanderkarte';
			case 'checklist.items.toiletPaper': return 'Toilettenpapier';
			case 'checklist.items.handSanitizer': return 'Handdesinfektionsmittel';
			case 'checklist.items.towel': return 'Handtuch';
			case 'checklist.essential': return 'Wesentlich';
			case 'journal.title': return 'Wandertagebuch';
			case 'journal.empty': return 'Ihr Tagebuch ist leer';
			case 'journal.emptySubtitle': return 'Notieren Sie Ihre Eindrücke und Erinnerungen';
			case 'journal.addNote': return 'Neue Notiz';
			case 'journal.stage': return 'Etappe';
			case 'journal.yourNote': return 'Ihre Notiz';
			case 'journal.placeholder': return 'Beschreiben Sie Ihren Wandertag...';
			case 'journal.save': return 'Speichern';
			case 'journal.cancel': return 'Abbrechen';
			case 'journal.delete': return 'Löschen';
			case 'journal.photoLimit': return 'Limit von 3 Fotos pro Tag erreicht';
			case 'journal.photoTooBig': return 'Foto zu groß (max 500 KB)';
			case 'weather.title': return 'Wetter';
			case 'weather.loading': return 'Wetter wird geladen...';
			case 'weather.offline': return 'Keine Verbindung. Wetterdaten nicht verfügbar.';
			case 'weather.error': return 'Wetter konnte nicht geladen werden.';
			case 'weather.cached': return 'Zwischengespeicherte Daten';
			case 'weather.alerts': return 'Wetterwarnungen';
			case 'weather.refresh': return 'Aktualisieren';
			case 'weather.temperature': return 'Temperatur';
			case 'weather.precipitation': return 'Niederschlag';
			case 'weather.wind': return 'Wind';
			case 'weather.uv': return 'UV-Index';
			case 'share.title': return 'Teilen';
			case 'share.generating': return 'Wird generiert...';
			case 'share.share': return 'Teilen';
			case 'share.error': return 'Fehler bei der Erstellung';
			case 'diploma.title': return 'Wanderdiplom';
			case 'diploma.yourName': return 'Ihr Name';
			case 'diploma.namePlaceholder': return 'Geben Sie Ihren Namen ein...';
			case 'diploma.generatePdf': return 'PDF erstellen';
			case 'diploma.certifies': return 'Bestätigt, dass';
			case 'diploma.completed': return 'den Weg abgeschlossen hat';
			case 'notifications.morningReminder': return 'Morgenerinnerung';
			case 'notifications.weatherAlerts': return 'Wetterwarnungen';
			case 'notifications.countdown': return 'Erinnerung 2 Tage vorher';
			case 'notifications.countdownDesc': return 'Benachrichtigung 2 Tage vor Abreise';
			case 'settings.title': return 'Einstellungen';
			case 'settings.language': return 'Sprache';
			case 'settings.units': return 'Einheiten';
			case 'settings.distance': return 'Entfernung';
			case 'settings.temperature': return 'Temperatur';
			case 'settings.theme': return 'Thema';
			case 'settings.dark': return 'Dunkel';
			case 'settings.light': return 'Hell';
			case 'settings.system': return 'System';
			case 'settings.cache': return 'Cache';
			case 'settings.cacheEnabled': return 'Cache aktiviert';
			case 'settings.cacheDesc': return 'Daten offline verfügbar';
			case 'settings.cacheSize': return 'Cache-Größe';
			case 'settings.notifications': return 'Benachrichtigungen';
			case 'feedback.title': return 'Feedback';
			case 'feedback.type': return 'Feedbacktyp';
			case 'feedback.bug': return 'Fehler / Problem';
			case 'feedback.suggestion': return 'Vorschlag';
			case 'feedback.question': return 'Frage';
			case 'feedback.other': return 'Sonstiges';
			case 'feedback.message': return 'Ihre Nachricht';
			case 'feedback.messagePlaceholder': return 'Beschreiben Sie Ihr Feedback...';
			case 'feedback.satisfaction': return 'Zufriedenheit';
			case 'feedback.send': return 'Senden';
			case 'feedback.sending': return 'Wird gesendet...';
			case 'feedback.thanks': return 'Vielen Dank für Ihr Feedback!';
			case 'feedback.pending': return 'ausstehend';
			case 'auth.profile': return 'Profil';
			case 'auth.anonymous': return 'Anonymer Wanderer';
			case 'auth.connectedVia': return 'Verbunden über';
			case 'auth.signInGoogle': return 'Mit Google anmelden';
			case 'auth.signInGoogleDesc': return 'Um Ihren Fortschritt zu speichern';
			case 'auth.signOut': return 'Abmelden';
			case 'auth.signOutDesc': return 'Zurück zum anonymen Modus';
			case 'auth.signOutConfirm': return 'Abmelden?';
			case 'auth.signOutMessage': return 'Sie kehren zum anonymen Modus zurück. Ihre lokalen Daten bleiben erhalten.';
			case 'auth.deleteAccount': return 'Mein Konto löschen';
			case 'auth.deleteAccountDesc': return 'Alle Ihre Daten werden gelöscht';
			case 'auth.deleteConfirm': return 'Konto löschen?';
			case 'auth.deleteMessage': return 'Diese Aktion ist unwiderruflich. Alle Ihre Daten, Notizen und Fortschritte werden gelöscht.';
			case 'auth.cancel': return 'Abbrechen';
			default: return null;
		}
	}
}

extension on _TranslationsEn {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'map.title': return 'Trail map';
			case 'map.loading': return 'Loading track...';
			case 'map.noTrack': return 'No track available';
			case 'map.viewMap': return 'View map';
			case 'stage.distance': return 'Distance';
			case 'stage.elevation': return 'Elevation';
			case 'stage.elevationGain': return 'Elevation gain';
			case 'stage.elevationLoss': return 'Elevation loss';
			case 'stage.duration': return 'Estimated duration';
			case 'stage.description': return 'Description';
			case 'stage.coordinates': return 'Coordinates';
			case 'stage.pois': return 'Points of interest';
			case 'stage.difficulty.easy': return 'Easy';
			case 'stage.difficulty.moderate': return 'Moderate';
			case 'stage.difficulty.hard': return 'Hard';
			case 'stage.difficulty.expert': return 'Expert';
			case 'stage.remaining': return '{distance} km remaining';
			case 'stage.arrived': return 'You have arrived!';
			case 'trail.stages': return 'Stages';
			case 'trail.totalDistance': return 'Total distance';
			case 'trail.totalElevation': return 'Total elevation';
			case 'poi.shelter': return 'Shelter';
			case 'poi.water': return 'Water source';
			case 'poi.viewpoint': return 'Viewpoint';
			case 'poi.campsite': return 'Campsite';
			case 'poi.restaurant': return 'Restaurant';
			case 'poi.emergency': return 'Emergency';
			case 'poi.danger': return 'Danger';
			case 'poi.shop': return 'Shop';
			case 'poi.filter': return 'Filter points of interest';
			case 'poi.altitude': return 'Altitude';
			case 'poi.hours': return 'Opening hours';
			case 'gps.permission': return 'GPS permission required';
			case 'gps.denied': return 'Location access denied';
			case 'gps.disabled': return 'Location service disabled';
			case 'gps.offTrack': return 'Off track';
			case 'gps.centerOnMe': return 'Center on my position';
			case 'planning.title': return 'Planning';
			case 'planning.duration': return 'Duration';
			case 'planning.days': return 'days';
			case 'planning.day': return 'Day';
			case 'planning.restDay': return 'Rest day';
			case 'planning.totalDistance': return 'Total distance';
			case 'planning.totalElevation': return 'Total elevation';
			case 'planning.estimatedTime': return 'Estimated time';
			case 'planning.stages': return 'Stages';
			case 'planning.plan': return 'Plan';
			case 'tracking.start': return 'Start';
			case 'tracking.pause': return 'Pause';
			case 'tracking.resume': return 'Resume';
			case 'tracking.stop': return 'Stop';
			case 'tracking.distance': return 'Distance';
			case 'tracking.elevation': return 'Elevation';
			case 'tracking.speed': return 'Speed';
			case 'tracking.time': return 'Time';
			case 'tracking.confirmStop': return 'Stop tracking?';
			case 'checklist.title': return 'Gear checklist';
			case 'checklist.subtitle': return 'Pack your backpack';
			case 'checklist.progress': return '{checked}/{total} packed';
			case 'checklist.complete': return 'Checklist complete!';
			case 'checklist.reset': return 'Reset';
			case 'checklist.resetConfirm': return 'Reset checklist?';
			case 'checklist.resetDescription': return 'All items will be unchecked.';
			case 'checklist.cancel': return 'Cancel';
			case 'checklist.confirm': return 'Confirm';
			case 'checklist.categories.equipment': return 'Equipment';
			case 'checklist.categories.clothing': return 'Clothing';
			case 'checklist.categories.food': return 'Food';
			case 'checklist.categories.safety': return 'Safety';
			case 'checklist.categories.documents': return 'Documents';
			case 'checklist.categories.hygiene': return 'Hygiene';
			case 'checklist.items.backpack': return 'Backpack';
			case 'checklist.items.sleepingBag': return 'Sleeping bag';
			case 'checklist.items.sleepingPad': return 'Sleeping pad';
			case 'checklist.items.hikingPoles': return 'Hiking poles';
			case 'checklist.items.headlamp': return 'Headlamp';
			case 'checklist.items.waterBottle': return 'Water bottle';
			case 'checklist.items.hikingBoots': return 'Hiking boots';
			case 'checklist.items.rainJacket': return 'Rain jacket';
			case 'checklist.items.warmLayer': return 'Warm layer';
			case 'checklist.items.hikingSocks': return 'Hiking socks';
			case 'checklist.items.hat': return 'Hat';
			case 'checklist.items.gloves': return 'Gloves';
			case 'checklist.items.trailSnacks': return 'Trail snacks';
			case 'checklist.items.energyBars': return 'Energy bars';
			case 'checklist.items.waterPurification': return 'Water purification';
			case 'checklist.items.firstAidKit': return 'First aid kit';
			case 'checklist.items.whistle': return 'Whistle';
			case 'checklist.items.emergencyBlanket': return 'Emergency blanket';
			case 'checklist.items.sunscreen': return 'Sunscreen';
			case 'checklist.items.idCard': return 'ID card';
			case 'checklist.items.insurance': return 'Insurance';
			case 'checklist.items.trailMap': return 'Trail map';
			case 'checklist.items.toiletPaper': return 'Toilet paper';
			case 'checklist.items.handSanitizer': return 'Hand sanitizer';
			case 'checklist.items.towel': return 'Towel';
			case 'checklist.essential': return 'Essential';
			case 'journal.title': return 'Trek journal';
			case 'journal.empty': return 'Your journal is empty';
			case 'journal.emptySubtitle': return 'Write down your trek impressions and memories';
			case 'journal.addNote': return 'New note';
			case 'journal.stage': return 'Stage';
			case 'journal.yourNote': return 'Your note';
			case 'journal.placeholder': return 'Describe your hiking day...';
			case 'journal.save': return 'Save';
			case 'journal.cancel': return 'Cancel';
			case 'journal.delete': return 'Delete';
			case 'journal.photoLimit': return '3 photos per day limit reached';
			case 'journal.photoTooBig': return 'Photo too large (max 500 KB)';
			case 'weather.title': return 'Weather';
			case 'weather.loading': return 'Loading weather...';
			case 'weather.offline': return 'No connection. Weather data unavailable.';
			case 'weather.error': return 'Unable to load weather.';
			case 'weather.cached': return 'Cached data';
			case 'weather.alerts': return 'weather alerts';
			case 'weather.refresh': return 'Refresh';
			case 'weather.temperature': return 'Temperature';
			case 'weather.precipitation': return 'Precipitation';
			case 'weather.wind': return 'Wind';
			case 'weather.uv': return 'UV index';
			case 'share.title': return 'Share';
			case 'share.generating': return 'Generating...';
			case 'share.share': return 'Share';
			case 'share.error': return 'Error during generation';
			case 'diploma.title': return 'Trek diploma';
			case 'diploma.yourName': return 'Your name';
			case 'diploma.namePlaceholder': return 'Enter your name...';
			case 'diploma.generatePdf': return 'Generate PDF';
			case 'diploma.certifies': return 'Certifies that';
			case 'diploma.completed': return 'completed the';
			case 'notifications.morningReminder': return 'Morning reminder';
			case 'notifications.weatherAlerts': return 'Weather alerts';
			case 'notifications.countdown': return 'D-2 reminder';
			case 'notifications.countdownDesc': return 'Notification 2 days before departure';
			case 'settings.title': return 'Settings';
			case 'settings.language': return 'Language';
			case 'settings.units': return 'Units';
			case 'settings.distance': return 'Distance';
			case 'settings.temperature': return 'Temperature';
			case 'settings.theme': return 'Theme';
			case 'settings.dark': return 'Dark';
			case 'settings.light': return 'Light';
			case 'settings.system': return 'System';
			case 'settings.cache': return 'Cache';
			case 'settings.cacheEnabled': return 'Cache enabled';
			case 'settings.cacheDesc': return 'Data available offline';
			case 'settings.cacheSize': return 'Cache size';
			case 'settings.notifications': return 'Notifications';
			case 'feedback.title': return 'Feedback';
			case 'feedback.type': return 'Feedback type';
			case 'feedback.bug': return 'Bug / Problem';
			case 'feedback.suggestion': return 'Suggestion';
			case 'feedback.question': return 'Question';
			case 'feedback.other': return 'Other';
			case 'feedback.message': return 'Your message';
			case 'feedback.messagePlaceholder': return 'Describe your feedback...';
			case 'feedback.satisfaction': return 'Satisfaction';
			case 'feedback.send': return 'Send';
			case 'feedback.sending': return 'Sending...';
			case 'feedback.thanks': return 'Thank you for your feedback!';
			case 'feedback.pending': return 'pending';
			case 'auth.profile': return 'Profile';
			case 'auth.anonymous': return 'Anonymous hiker';
			case 'auth.connectedVia': return 'Connected via';
			case 'auth.signInGoogle': return 'Sign in with Google';
			case 'auth.signInGoogleDesc': return 'To save your progress';
			case 'auth.signOut': return 'Sign out';
			case 'auth.signOutDesc': return 'Return to anonymous mode';
			case 'auth.signOutConfirm': return 'Sign out?';
			case 'auth.signOutMessage': return 'You will return to anonymous mode. Your local data is preserved.';
			case 'auth.deleteAccount': return 'Delete my account';
			case 'auth.deleteAccountDesc': return 'All your data will be erased';
			case 'auth.deleteConfirm': return 'Delete your account?';
			case 'auth.deleteMessage': return 'This action is irreversible. All your data, notes and progress will be erased.';
			case 'auth.cancel': return 'Cancel';
			default: return null;
		}
	}
}

extension on _TranslationsEs {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'map.title': return 'Mapa del sendero';
			case 'map.loading': return 'Cargando el recorrido...';
			case 'map.noTrack': return 'NingÃºn recorrido disponible';
			case 'map.viewMap': return 'Ver el mapa';
			case 'stage.distance': return 'Distancia';
			case 'stage.elevation': return 'Desnivel';
			case 'stage.elevationGain': return 'Desnivel positivo';
			case 'stage.elevationLoss': return 'Desnivel negativo';
			case 'stage.duration': return 'DuraciÃ³n estimada';
			case 'stage.description': return 'DescripciÃ³n';
			case 'stage.coordinates': return 'Coordenadas';
			case 'stage.pois': return 'Puntos de interÃ©s';
			case 'stage.difficulty.easy': return 'FÃ¡cil';
			case 'stage.difficulty.moderate': return 'Moderado';
			case 'stage.difficulty.hard': return 'DifÃ­cil';
			case 'stage.difficulty.expert': return 'Experto';
			case 'stage.remaining': return '{distance} km restantes';
			case 'stage.arrived': return 'Has llegado!';
			case 'trail.stages': return 'Etapas';
			case 'trail.totalDistance': return 'Distancia total';
			case 'trail.totalElevation': return 'Desnivel total';
			case 'poi.shelter': return 'Refugio';
			case 'poi.water': return 'Fuente de agua';
			case 'poi.viewpoint': return 'Mirador';
			case 'poi.campsite': return 'Vivac';
			case 'poi.restaurant': return 'Restaurante';
			case 'poi.emergency': return 'Emergencia';
			case 'poi.danger': return 'Peligro';
			case 'poi.shop': return 'Tienda';
			case 'poi.filter': return 'Filtrar puntos de interÃ©s';
			case 'poi.altitude': return 'Altitud';
			case 'poi.hours': return 'Horarios';
			case 'gps.permission': return 'Permiso GPS requerido';
			case 'gps.denied': return 'Acceso a la ubicacion denegado';
			case 'gps.disabled': return 'Servicio de ubicacion desactivado';
			case 'gps.offTrack': return 'Fuera del sendero';
			case 'gps.centerOnMe': return 'Centrar en mi posicion';
			case 'planning.title': return 'Planificación';
			case 'planning.duration': return 'Duración';
			case 'planning.days': return 'días';
			case 'planning.day': return 'Día';
			case 'planning.restDay': return 'Día de descanso';
			case 'planning.totalDistance': return 'Distancia total';
			case 'planning.totalElevation': return 'Desnivel total';
			case 'planning.estimatedTime': return 'Duración estimada';
			case 'planning.stages': return 'Etapas';
			case 'planning.plan': return 'Planificar';
			case 'tracking.start': return 'Iniciar';
			case 'tracking.pause': return 'Pausa';
			case 'tracking.resume': return 'Reanudar';
			case 'tracking.stop': return 'Detener';
			case 'tracking.distance': return 'Distancia';
			case 'tracking.elevation': return 'Desnivel';
			case 'tracking.speed': return 'Velocidad';
			case 'tracking.time': return 'Tiempo';
			case 'tracking.confirmStop': return 'Detener el seguimiento?';
			case 'checklist.title': return 'Lista de equipo';
			case 'checklist.subtitle': return 'Prepara tu mochila';
			case 'checklist.progress': return '{checked}/{total} preparados';
			case 'checklist.complete': return 'Lista completa!';
			case 'checklist.reset': return 'Reiniciar';
			case 'checklist.resetConfirm': return 'Reiniciar la lista?';
			case 'checklist.resetDescription': return 'Todos los elementos serán desmarcados.';
			case 'checklist.cancel': return 'Cancelar';
			case 'checklist.confirm': return 'Confirmar';
			case 'checklist.categories.equipment': return 'Equipo';
			case 'checklist.categories.clothing': return 'Ropa';
			case 'checklist.categories.food': return 'Alimentación';
			case 'checklist.categories.safety': return 'Seguridad';
			case 'checklist.categories.documents': return 'Documentos';
			case 'checklist.categories.hygiene': return 'Higiene';
			case 'checklist.items.backpack': return 'Mochila';
			case 'checklist.items.sleepingBag': return 'Saco de dormir';
			case 'checklist.items.sleepingPad': return 'Esterilla';
			case 'checklist.items.hikingPoles': return 'Bastones de senderismo';
			case 'checklist.items.headlamp': return 'Linterna frontal';
			case 'checklist.items.waterBottle': return 'Botella de agua';
			case 'checklist.items.hikingBoots': return 'Botas de senderismo';
			case 'checklist.items.rainJacket': return 'Chaqueta impermeable';
			case 'checklist.items.warmLayer': return 'Capa de abrigo';
			case 'checklist.items.hikingSocks': return 'Calcetines de senderismo';
			case 'checklist.items.hat': return 'Sombrero';
			case 'checklist.items.gloves': return 'Guantes';
			case 'checklist.items.trailSnacks': return 'Snacks de sendero';
			case 'checklist.items.energyBars': return 'Barritas energéticas';
			case 'checklist.items.waterPurification': return 'Purificación de agua';
			case 'checklist.items.firstAidKit': return 'Botiquín';
			case 'checklist.items.whistle': return 'Silbato';
			case 'checklist.items.emergencyBlanket': return 'Manta de emergencia';
			case 'checklist.items.sunscreen': return 'Protector solar';
			case 'checklist.items.idCard': return 'Documento de identidad';
			case 'checklist.items.insurance': return 'Seguro';
			case 'checklist.items.trailMap': return 'Mapa del sendero';
			case 'checklist.items.toiletPaper': return 'Papel higiénico';
			case 'checklist.items.handSanitizer': return 'Gel desinfectante';
			case 'checklist.items.towel': return 'Toalla';
			case 'checklist.essential': return 'Esencial';
			case 'journal.title': return 'Diario de trekking';
			case 'journal.empty': return 'Tu diario está vacío';
			case 'journal.emptySubtitle': return 'Anota tus impresiones y recuerdos de trekking';
			case 'journal.addNote': return 'Nueva nota';
			case 'journal.stage': return 'Etapa';
			case 'journal.yourNote': return 'Tu nota';
			case 'journal.placeholder': return 'Describe tu día de senderismo...';
			case 'journal.save': return 'Guardar';
			case 'journal.cancel': return 'Cancelar';
			case 'journal.delete': return 'Eliminar';
			case 'journal.photoLimit': return 'Límite de 3 fotos por día alcanzado';
			case 'journal.photoTooBig': return 'Foto demasiado grande (máx 500 KB)';
			case 'weather.title': return 'Meteorología';
			case 'weather.loading': return 'Cargando meteorología...';
			case 'weather.offline': return 'Sin conexión. Datos meteorológicos no disponibles.';
			case 'weather.error': return 'No se pudo cargar la meteorología.';
			case 'weather.cached': return 'Datos en caché';
			case 'weather.alerts': return 'alertas meteorológicas';
			case 'weather.refresh': return 'Actualizar';
			case 'weather.temperature': return 'Temperatura';
			case 'weather.precipitation': return 'Precipitación';
			case 'weather.wind': return 'Viento';
			case 'weather.uv': return 'Índice UV';
			case 'share.title': return 'Compartir';
			case 'share.generating': return 'Generando...';
			case 'share.share': return 'Compartir';
			case 'share.error': return 'Error durante la generación';
			case 'diploma.title': return 'Diploma de trekking';
			case 'diploma.yourName': return 'Tu nombre';
			case 'diploma.namePlaceholder': return 'Introduce tu nombre...';
			case 'diploma.generatePdf': return 'Generar PDF';
			case 'diploma.certifies': return 'Certifica que';
			case 'diploma.completed': return 'ha recorrido el';
			case 'notifications.morningReminder': return 'Recordatorio matutino';
			case 'notifications.weatherAlerts': return 'Alertas meteorológicas';
			case 'notifications.countdown': return 'Recordatorio D-2';
			case 'notifications.countdownDesc': return 'Notificación 2 días antes de la salida';
			case 'settings.title': return 'Ajustes';
			case 'settings.language': return 'Idioma';
			case 'settings.units': return 'Unidades';
			case 'settings.distance': return 'Distancia';
			case 'settings.temperature': return 'Temperatura';
			case 'settings.theme': return 'Tema';
			case 'settings.dark': return 'Oscuro';
			case 'settings.light': return 'Claro';
			case 'settings.system': return 'Sistema';
			case 'settings.cache': return 'Caché';
			case 'settings.cacheEnabled': return 'Caché activada';
			case 'settings.cacheDesc': return 'Datos disponibles sin conexión';
			case 'settings.cacheSize': return 'Tamaño de caché';
			case 'settings.notifications': return 'Notificaciones';
			case 'feedback.title': return 'Comentarios';
			case 'feedback.type': return 'Tipo de comentario';
			case 'feedback.bug': return 'Error / Problema';
			case 'feedback.suggestion': return 'Sugerencia';
			case 'feedback.question': return 'Pregunta';
			case 'feedback.other': return 'Otro';
			case 'feedback.message': return 'Tu mensaje';
			case 'feedback.messagePlaceholder': return 'Describe tu comentario...';
			case 'feedback.satisfaction': return 'Satisfacción';
			case 'feedback.send': return 'Enviar';
			case 'feedback.sending': return 'Enviando...';
			case 'feedback.thanks': return '¡Gracias por tu comentario!';
			case 'feedback.pending': return 'pendiente';
			case 'auth.profile': return 'Perfil';
			case 'auth.anonymous': return 'Senderista anónimo';
			case 'auth.connectedVia': return 'Conectado vía';
			case 'auth.signInGoogle': return 'Iniciar sesión con Google';
			case 'auth.signInGoogleDesc': return 'Para guardar tu progreso';
			case 'auth.signOut': return 'Cerrar sesión';
			case 'auth.signOutDesc': return 'Volver al modo anónimo';
			case 'auth.signOutConfirm': return '¿Cerrar sesión?';
			case 'auth.signOutMessage': return 'Volverás al modo anónimo. Tus datos locales se conservan.';
			case 'auth.deleteAccount': return 'Eliminar mi cuenta';
			case 'auth.deleteAccountDesc': return 'Todos tus datos serán borrados';
			case 'auth.deleteConfirm': return '¿Eliminar tu cuenta?';
			case 'auth.deleteMessage': return 'Esta acción es irreversible. Todos tus datos, notas y progreso serán eliminados.';
			case 'auth.cancel': return 'Cancelar';
			default: return null;
		}
	}
}

extension on _TranslationsIt {
	dynamic _flatMapFunction(String path) {
		switch (path) {
			case 'map.title': return 'Mappa del sentiero';
			case 'map.loading': return 'Caricamento del tracciato...';
			case 'map.noTrack': return 'Nessun tracciato disponibile';
			case 'map.viewMap': return 'Vedi la mappa';
			case 'stage.distance': return 'Distanza';
			case 'stage.elevation': return 'Dislivello';
			case 'stage.elevationGain': return 'Dislivello positivo';
			case 'stage.elevationLoss': return 'Dislivello negativo';
			case 'stage.duration': return 'Durata stimata';
			case 'stage.description': return 'Descrizione';
			case 'stage.coordinates': return 'Coordinate';
			case 'stage.pois': return 'Punti di interesse';
			case 'stage.difficulty.easy': return 'Facile';
			case 'stage.difficulty.moderate': return 'Moderato';
			case 'stage.difficulty.hard': return 'Difficile';
			case 'stage.difficulty.expert': return 'Esperto';
			case 'stage.remaining': return '{distance} km rimanenti';
			case 'stage.arrived': return 'Sei arrivato!';
			case 'trail.stages': return 'Tappe';
			case 'trail.totalDistance': return 'Distanza totale';
			case 'trail.totalElevation': return 'Dislivello totale';
			case 'poi.shelter': return 'Rifugio';
			case 'poi.water': return 'Fonte d\'acqua';
			case 'poi.viewpoint': return 'Punto panoramico';
			case 'poi.campsite': return 'Bivacco';
			case 'poi.restaurant': return 'Ristorante';
			case 'poi.emergency': return 'Emergenza';
			case 'poi.danger': return 'Pericolo';
			case 'poi.shop': return 'Negozio';
			case 'poi.filter': return 'Filtra i punti di interesse';
			case 'poi.altitude': return 'Altitudine';
			case 'poi.hours': return 'Orari';
			case 'gps.permission': return 'Autorizzazione GPS richiesta';
			case 'gps.denied': return 'Accesso alla posizione negato';
			case 'gps.disabled': return 'Servizio di localizzazione disattivato';
			case 'gps.offTrack': return 'Fuori tracciato';
			case 'gps.centerOnMe': return 'Centra sulla mia posizione';
			case 'planning.title': return 'Pianificazione';
			case 'planning.duration': return 'Durata';
			case 'planning.days': return 'giorni';
			case 'planning.day': return 'Giorno';
			case 'planning.restDay': return 'Giorno di riposo';
			case 'planning.totalDistance': return 'Distanza totale';
			case 'planning.totalElevation': return 'Dislivello totale';
			case 'planning.estimatedTime': return 'Durata stimata';
			case 'planning.stages': return 'Tappe';
			case 'planning.plan': return 'Pianificare';
			case 'tracking.start': return 'Avvia';
			case 'tracking.pause': return 'Pausa';
			case 'tracking.resume': return 'Riprendi';
			case 'tracking.stop': return 'Ferma';
			case 'tracking.distance': return 'Distanza';
			case 'tracking.elevation': return 'Dislivello';
			case 'tracking.speed': return 'Velocita';
			case 'tracking.time': return 'Tempo';
			case 'tracking.confirmStop': return 'Fermare il tracciamento?';
			case 'checklist.title': return 'Lista equipaggiamento';
			case 'checklist.subtitle': return 'Prepara lo zaino';
			case 'checklist.progress': return '{checked}/{total} preparati';
			case 'checklist.complete': return 'Lista completa!';
			case 'checklist.reset': return 'Reimposta';
			case 'checklist.resetConfirm': return 'Reimpostare la lista?';
			case 'checklist.resetDescription': return 'Tutti gli elementi saranno deselezionati.';
			case 'checklist.cancel': return 'Annulla';
			case 'checklist.confirm': return 'Conferma';
			case 'checklist.categories.equipment': return 'Equipaggiamento';
			case 'checklist.categories.clothing': return 'Abbigliamento';
			case 'checklist.categories.food': return 'Alimentazione';
			case 'checklist.categories.safety': return 'Sicurezza';
			case 'checklist.categories.documents': return 'Documenti';
			case 'checklist.categories.hygiene': return 'Igiene';
			case 'checklist.items.backpack': return 'Zaino';
			case 'checklist.items.sleepingBag': return 'Sacco a pelo';
			case 'checklist.items.sleepingPad': return 'Materassino';
			case 'checklist.items.hikingPoles': return 'Bastoncini da trekking';
			case 'checklist.items.headlamp': return 'Lampada frontale';
			case 'checklist.items.waterBottle': return 'Borraccia';
			case 'checklist.items.hikingBoots': return 'Scarpe da trekking';
			case 'checklist.items.rainJacket': return 'Giacca impermeabile';
			case 'checklist.items.warmLayer': return 'Strato caldo';
			case 'checklist.items.hikingSocks': return 'Calzini da trekking';
			case 'checklist.items.hat': return 'Cappello';
			case 'checklist.items.gloves': return 'Guanti';
			case 'checklist.items.trailSnacks': return 'Snack da sentiero';
			case 'checklist.items.energyBars': return 'Barrette energetiche';
			case 'checklist.items.waterPurification': return 'Purificazione dell\'acqua';
			case 'checklist.items.firstAidKit': return 'Kit di primo soccorso';
			case 'checklist.items.whistle': return 'Fischietto';
			case 'checklist.items.emergencyBlanket': return 'Coperta di emergenza';
			case 'checklist.items.sunscreen': return 'Protezione solare';
			case 'checklist.items.idCard': return 'Carta d\'identità';
			case 'checklist.items.insurance': return 'Assicurazione';
			case 'checklist.items.trailMap': return 'Mappa del sentiero';
			case 'checklist.items.toiletPaper': return 'Carta igienica';
			case 'checklist.items.handSanitizer': return 'Disinfettante mani';
			case 'checklist.items.towel': return 'Asciugamano';
			case 'checklist.essential': return 'Essenziale';
			case 'journal.title': return 'Diario di trekking';
			case 'journal.empty': return 'Il tuo diario è vuoto';
			case 'journal.emptySubtitle': return 'Annota le tue impressioni e ricordi di trekking';
			case 'journal.addNote': return 'Nuova nota';
			case 'journal.stage': return 'Tappa';
			case 'journal.yourNote': return 'La tua nota';
			case 'journal.placeholder': return 'Descrivi la tua giornata di trekking...';
			case 'journal.save': return 'Salva';
			case 'journal.cancel': return 'Annulla';
			case 'journal.delete': return 'Elimina';
			case 'journal.photoLimit': return 'Limite di 3 foto al giorno raggiunto';
			case 'journal.photoTooBig': return 'Foto troppo grande (max 500 KB)';
			case 'weather.title': return 'Meteo';
			case 'weather.loading': return 'Caricamento meteo...';
			case 'weather.offline': return 'Nessuna connessione. Dati meteo non disponibili.';
			case 'weather.error': return 'Impossibile caricare il meteo.';
			case 'weather.cached': return 'Dati nella cache';
			case 'weather.alerts': return 'allerte meteo';
			case 'weather.refresh': return 'Aggiorna';
			case 'weather.temperature': return 'Temperatura';
			case 'weather.precipitation': return 'Precipitazioni';
			case 'weather.wind': return 'Vento';
			case 'weather.uv': return 'Indice UV';
			case 'share.title': return 'Condividi';
			case 'share.generating': return 'Generazione...';
			case 'share.share': return 'Condividi';
			case 'share.error': return 'Errore durante la generazione';
			case 'diploma.title': return 'Diploma di trekking';
			case 'diploma.yourName': return 'Il tuo nome';
			case 'diploma.namePlaceholder': return 'Inserisci il tuo nome...';
			case 'diploma.generatePdf': return 'Genera PDF';
			case 'diploma.certifies': return 'Certifica che';
			case 'diploma.completed': return 'ha percorso il';
			case 'notifications.morningReminder': return 'Promemoria mattutino';
			case 'notifications.weatherAlerts': return 'Allerte meteo';
			case 'notifications.countdown': return 'Promemoria G-2';
			case 'notifications.countdownDesc': return 'Notifica 2 giorni prima della partenza';
			case 'settings.title': return 'Impostazioni';
			case 'settings.language': return 'Lingua';
			case 'settings.units': return 'Unità';
			case 'settings.distance': return 'Distanza';
			case 'settings.temperature': return 'Temperatura';
			case 'settings.theme': return 'Tema';
			case 'settings.dark': return 'Scuro';
			case 'settings.light': return 'Chiaro';
			case 'settings.system': return 'Sistema';
			case 'settings.cache': return 'Cache';
			case 'settings.cacheEnabled': return 'Cache attivata';
			case 'settings.cacheDesc': return 'Dati disponibili offline';
			case 'settings.cacheSize': return 'Dimensione cache';
			case 'settings.notifications': return 'Notifiche';
			case 'feedback.title': return 'Feedback';
			case 'feedback.type': return 'Tipo di feedback';
			case 'feedback.bug': return 'Bug / Problema';
			case 'feedback.suggestion': return 'Suggerimento';
			case 'feedback.question': return 'Domanda';
			case 'feedback.other': return 'Altro';
			case 'feedback.message': return 'Il tuo messaggio';
			case 'feedback.messagePlaceholder': return 'Descrivi il tuo feedback...';
			case 'feedback.satisfaction': return 'Soddisfazione';
			case 'feedback.send': return 'Invia';
			case 'feedback.sending': return 'Invio...';
			case 'feedback.thanks': return 'Grazie per il tuo feedback!';
			case 'feedback.pending': return 'in attesa';
			case 'auth.profile': return 'Profilo';
			case 'auth.anonymous': return 'Escursionista anonimo';
			case 'auth.connectedVia': return 'Connesso tramite';
			case 'auth.signInGoogle': return 'Accedi con Google';
			case 'auth.signInGoogleDesc': return 'Per salvare i tuoi progressi';
			case 'auth.signOut': return 'Esci';
			case 'auth.signOutDesc': return 'Torna alla modalità anonima';
			case 'auth.signOutConfirm': return 'Disconnettersi?';
			case 'auth.signOutMessage': return 'Tornerai alla modalità anonima. I tuoi dati locali saranno conservati.';
			case 'auth.deleteAccount': return 'Elimina il mio account';
			case 'auth.deleteAccountDesc': return 'Tutti i tuoi dati saranno cancellati';
			case 'auth.deleteConfirm': return 'Eliminare il tuo account?';
			case 'auth.deleteMessage': return 'Questa azione è irreversibile. Tutti i tuoi dati, note e progressi saranno cancellati.';
			case 'auth.cancel': return 'Annulla';
			default: return null;
		}
	}
}
