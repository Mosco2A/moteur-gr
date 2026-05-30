/// Generated file. Do not edit.
///
/// Original: assets/i18n
/// To regenerate, run: `dart run slang`
///
/// Locales: 1
/// Strings: 175
///
/// Built on 2026-05-30 at 11:48 UTC

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
	fr(languageCode: 'fr', build: Translations.build);

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
	String get title => 'Wanderkarte';
	String get loading => 'Strecke wird geladen...';
	String get noTrack => 'Keine Strecke verfÃ¼gbar';
	String get viewMap => 'Karte anzeigen';
}

// Path: stage
class _TranslationsStageFr {
	_TranslationsStageFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get distance => 'Entfernung';
	String get elevation => 'HÃ¶henunterschied';
	String get elevationGain => 'HÃ¶henmeter aufwÃ¤rts';
	String get elevationLoss => 'HÃ¶henmeter abwÃ¤rts';
	String get duration => 'GeschÃ¤tzte Dauer';
	String get description => 'Beschreibung';
	String get coordinates => 'Koordinaten';
	String get pois => 'SehenswÃ¼rdigkeiten';
	late final _TranslationsStageDifficultyFr difficulty = _TranslationsStageDifficultyFr._(_root);
	String get remaining => '{distance} km verbleibend';
	String get arrived => 'Sie sind angekommen!';
}

// Path: trail
class _TranslationsTrailFr {
	_TranslationsTrailFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get stages => 'Etappen';
	String get totalDistance => 'Gesamtstrecke';
	String get totalElevation => 'GesamthÃ¶henmeter';
}

// Path: poi
class _TranslationsPoiFr {
	_TranslationsPoiFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get shelter => 'SchutzhÃ¼tte';
	String get water => 'Wasserquelle';
	String get viewpoint => 'Aussichtspunkt';
	String get campsite => 'Biwakplatz';
	String get restaurant => 'Restaurant';
	String get emergency => 'Notfall';
	String get danger => 'Gefahr';
	String get shop => 'GeschÃ¤ft';
	String get filter => 'SehenswÃ¼rdigkeiten filtern';
	String get altitude => 'HÃ¶he';
	String get hours => 'Ãffnungszeiten';
}

// Path: gps
class _TranslationsGpsFr {
	_TranslationsGpsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get permission => 'GPS-Berechtigung erforderlich';
	String get denied => 'Standortzugriff verweigert';
	String get disabled => 'Standortdienst deaktiviert';
	String get offTrack => 'Abseits der Strecke';
	String get centerOnMe => 'Auf meine Position zentrieren';
}

// Path: planning
class _TranslationsPlanningFr {
	_TranslationsPlanningFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Planung';
	String get duration => 'Dauer';
	String get days => 'Tage';
	String get day => 'Tag';
	String get restDay => 'Ruhetag';
	String get totalDistance => 'Gesamtstrecke';
	String get totalElevation => 'Gesamthöhenmeter';
	String get estimatedTime => 'Geschätzte Dauer';
	String get stages => 'Etappen';
	String get plan => 'Planen';
}

// Path: tracking
class _TranslationsTrackingFr {
	_TranslationsTrackingFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get start => 'Starten';
	String get pause => 'Pause';
	String get resume => 'Fortsetzen';
	String get stop => 'Stoppen';
	String get distance => 'Entfernung';
	String get elevation => 'Hohenmeter';
	String get speed => 'Geschwindigkeit';
	String get time => 'Zeit';
	String get confirmStop => 'Tracking stoppen?';
}

// Path: checklist
class _TranslationsChecklistFr {
	_TranslationsChecklistFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Ausrüstungsliste';
	String get subtitle => 'Packen Sie Ihren Rucksack';
	String get progress => '{checked}/{total} gepackt';
	String get complete => 'Checkliste vollständig!';
	String get reset => 'Zurücksetzen';
	String get resetConfirm => 'Checkliste zurücksetzen?';
	String get resetDescription => 'Alle Elemente werden abgehakt.';
	String get cancel => 'Abbrechen';
	String get confirm => 'Bestätigen';
	late final _TranslationsChecklistCategoriesFr categories = _TranslationsChecklistCategoriesFr._(_root);
	late final _TranslationsChecklistItemsFr items = _TranslationsChecklistItemsFr._(_root);
	String get essential => 'Wesentlich';
}

// Path: journal
class _TranslationsJournalFr {
	_TranslationsJournalFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Wandertagebuch';
	String get empty => 'Ihr Tagebuch ist leer';
	String get emptySubtitle => 'Notieren Sie Ihre Eindrücke und Erinnerungen';
	String get addNote => 'Neue Notiz';
	String get stage => 'Etappe';
	String get yourNote => 'Ihre Notiz';
	String get placeholder => 'Beschreiben Sie Ihren Wandertag...';
	String get save => 'Speichern';
	String get cancel => 'Abbrechen';
	String get delete => 'Löschen';
	String get photoLimit => 'Limit von 3 Fotos pro Tag erreicht';
	String get photoTooBig => 'Foto zu groß (max 500 KB)';
}

// Path: weather
class _TranslationsWeatherFr {
	_TranslationsWeatherFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Wetter';
	String get loading => 'Wetter wird geladen...';
	String get offline => 'Keine Verbindung. Wetterdaten nicht verfügbar.';
	String get error => 'Wetter konnte nicht geladen werden.';
	String get cached => 'Zwischengespeicherte Daten';
	String get alerts => 'Wetterwarnungen';
	String get refresh => 'Aktualisieren';
	String get temperature => 'Temperatur';
	String get precipitation => 'Niederschlag';
	String get wind => 'Wind';
	String get uv => 'UV-Index';
}

// Path: share
class _TranslationsShareFr {
	_TranslationsShareFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Teilen';
	String get generating => 'Wird generiert...';
	String get share => 'Teilen';
	String get error => 'Fehler bei der Erstellung';
}

// Path: diploma
class _TranslationsDiplomaFr {
	_TranslationsDiplomaFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Wanderdiplom';
	String get yourName => 'Ihr Name';
	String get namePlaceholder => 'Geben Sie Ihren Namen ein...';
	String get generatePdf => 'PDF erstellen';
	String get certifies => 'Bestätigt, dass';
	String get completed => 'den Weg abgeschlossen hat';
}

// Path: notifications
class _TranslationsNotificationsFr {
	_TranslationsNotificationsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get morningReminder => 'Morgenerinnerung';
	String get weatherAlerts => 'Wetterwarnungen';
	String get countdown => 'Erinnerung 2 Tage vorher';
	String get countdownDesc => 'Benachrichtigung 2 Tage vor Abreise';
}

// Path: settings
class _TranslationsSettingsFr {
	_TranslationsSettingsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Einstellungen';
	String get language => 'Sprache';
	String get units => 'Einheiten';
	String get distance => 'Entfernung';
	String get temperature => 'Temperatur';
	String get theme => 'Thema';
	String get dark => 'Dunkel';
	String get light => 'Hell';
	String get system => 'System';
	String get cache => 'Cache';
	String get cacheEnabled => 'Cache aktiviert';
	String get cacheDesc => 'Daten offline verfügbar';
	String get cacheSize => 'Cache-Größe';
	String get notifications => 'Benachrichtigungen';
}

// Path: feedback
class _TranslationsFeedbackFr {
	_TranslationsFeedbackFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get title => 'Feedback';
	String get type => 'Feedbacktyp';
	String get bug => 'Fehler / Problem';
	String get suggestion => 'Vorschlag';
	String get question => 'Frage';
	String get other => 'Sonstiges';
	String get message => 'Ihre Nachricht';
	String get messagePlaceholder => 'Beschreiben Sie Ihr Feedback...';
	String get satisfaction => 'Zufriedenheit';
	String get send => 'Senden';
	String get sending => 'Wird gesendet...';
	String get thanks => 'Vielen Dank für Ihr Feedback!';
	String get pending => 'ausstehend';
}

// Path: auth
class _TranslationsAuthFr {
	_TranslationsAuthFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get profile => 'Profil';
	String get anonymous => 'Anonymer Wanderer';
	String get connectedVia => 'Verbunden über';
	String get signInGoogle => 'Mit Google anmelden';
	String get signInGoogleDesc => 'Um Ihren Fortschritt zu speichern';
	String get signOut => 'Abmelden';
	String get signOutDesc => 'Zurück zum anonymen Modus';
	String get signOutConfirm => 'Abmelden?';
	String get signOutMessage => 'Sie kehren zum anonymen Modus zurück. Ihre lokalen Daten bleiben erhalten.';
	String get deleteAccount => 'Mein Konto löschen';
	String get deleteAccountDesc => 'Alle Ihre Daten werden gelöscht';
	String get deleteConfirm => 'Konto löschen?';
	String get deleteMessage => 'Diese Aktion ist unwiderruflich. Alle Ihre Daten, Notizen und Fortschritte werden gelöscht.';
	String get cancel => 'Abbrechen';
}

// Path: stage.difficulty
class _TranslationsStageDifficultyFr {
	_TranslationsStageDifficultyFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get easy => 'Leicht';
	String get moderate => 'Mittel';
	String get hard => 'Schwer';
	String get expert => 'Experte';
}

// Path: checklist.categories
class _TranslationsChecklistCategoriesFr {
	_TranslationsChecklistCategoriesFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get equipment => 'Ausrüstung';
	String get clothing => 'Kleidung';
	String get food => 'Verpflegung';
	String get safety => 'Sicherheit';
	String get documents => 'Dokumente';
	String get hygiene => 'Hygiene';
}

// Path: checklist.items
class _TranslationsChecklistItemsFr {
	_TranslationsChecklistItemsFr._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	String get backpack => 'Rucksack';
	String get sleepingBag => 'Schlafsack';
	String get sleepingPad => 'Isomatte';
	String get hikingPoles => 'Wanderstöcke';
	String get headlamp => 'Stirnlampe';
	String get waterBottle => 'Trinkflasche';
	String get hikingBoots => 'Wanderschuhe';
	String get rainJacket => 'Regenjacke';
	String get warmLayer => 'Wärmeschicht';
	String get hikingSocks => 'Wandersocken';
	String get hat => 'Hut';
	String get gloves => 'Handschuhe';
	String get trailSnacks => 'Wandersnacks';
	String get energyBars => 'Energieriegel';
	String get waterPurification => 'Wasseraufbereitung';
	String get firstAidKit => 'Erste-Hilfe-Set';
	String get whistle => 'Pfeife';
	String get emergencyBlanket => 'Rettungsdecke';
	String get sunscreen => 'Sonnenschutz';
	String get idCard => 'Ausweis';
	String get insurance => 'Versicherung';
	String get trailMap => 'Wanderkarte';
	String get toiletPaper => 'Toilettenpapier';
	String get handSanitizer => 'Handdesinfektionsmittel';
	String get towel => 'Handtuch';
}

/// Flat map(s) containing all translations.
/// Only for edge cases! For simple maps, use the map function of this library.

extension on Translations {
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
