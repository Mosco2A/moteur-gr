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
class TranslationsDe with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$map$de map = _Translations$map$de._(_root);
	@override late final _Translations$stage$de stage = _Translations$stage$de._(_root);
	@override late final _Translations$trail$de trail = _Translations$trail$de._(_root);
	@override late final _Translations$poi$de poi = _Translations$poi$de._(_root);
	@override late final _Translations$gps$de gps = _Translations$gps$de._(_root);
	@override late final _Translations$planning$de planning = _Translations$planning$de._(_root);
	@override late final _Translations$tracking$de tracking = _Translations$tracking$de._(_root);
	@override late final _Translations$checklist$de checklist = _Translations$checklist$de._(_root);
	@override late final _Translations$journal$de journal = _Translations$journal$de._(_root);
	@override late final _Translations$weather$de weather = _Translations$weather$de._(_root);
	@override late final _Translations$share$de share = _Translations$share$de._(_root);
	@override late final _Translations$diploma$de diploma = _Translations$diploma$de._(_root);
	@override late final _Translations$notifications$de notifications = _Translations$notifications$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$feedback$de feedback = _Translations$feedback$de._(_root);
	@override late final _Translations$auth$de auth = _Translations$auth$de._(_root);
	@override late final _Translations$feasibility$de feasibility = _Translations$feasibility$de._(_root);
	@override late final _Translations$tips$de tips = _Translations$tips$de._(_root);
	@override late final _Translations$goodies$de goodies = _Translations$goodies$de._(_root);
}

// Path: map
class _Translations$map$de implements Translations$map$en {
	_Translations$map$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderkarte';
	@override String get loading => 'Strecke wird geladen...';
	@override String get noTrack => 'Keine Strecke verfÃ¼gbar';
	@override String get viewMap => 'Karte anzeigen';
}

// Path: stage
class _Translations$stage$de implements Translations$stage$en {
	_Translations$stage$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Entfernung';
	@override String get elevation => 'HÃ¶henunterschied';
	@override String get elevationGain => 'HÃ¶henmeter aufwÃ¤rts';
	@override String get elevationLoss => 'HÃ¶henmeter abwÃ¤rts';
	@override String get duration => 'GeschÃ¤tzte Dauer';
	@override String get description => 'Beschreibung';
	@override String get coordinates => 'Koordinaten';
	@override String get pois => 'SehenswÃ¼rdigkeiten';
	@override late final _Translations$stage$difficulty$de difficulty = _Translations$stage$difficulty$de._(_root);
	@override String get remaining => '{distance} km verbleibend';
	@override String get arrived => 'Sie sind angekommen!';
}

// Path: trail
class _Translations$trail$de implements Translations$trail$en {
	_Translations$trail$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etappen';
	@override String get totalDistance => 'Gesamtstrecke';
	@override String get totalElevation => 'GesamthÃ¶henmeter';
}

// Path: poi
class _Translations$poi$de implements Translations$poi$en {
	_Translations$poi$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$gps$de implements Translations$gps$en {
	_Translations$gps$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get permission => 'GPS-Berechtigung erforderlich';
	@override String get denied => 'Standortzugriff verweigert';
	@override String get disabled => 'Standortdienst deaktiviert';
	@override String get offTrack => 'Abseits der Strecke';
	@override String get centerOnMe => 'Auf meine Position zentrieren';
}

// Path: planning
class _Translations$planning$de implements Translations$planning$en {
	_Translations$planning$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$tracking$de implements Translations$tracking$en {
	_Translations$tracking$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$checklist$de implements Translations$checklist$en {
	_Translations$checklist$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
	@override late final _Translations$checklist$categories$de categories = _Translations$checklist$categories$de._(_root);
	@override late final _Translations$checklist$items$de items = _Translations$checklist$items$de._(_root);
	@override String get essential => 'Wesentlich';
}

// Path: journal
class _Translations$journal$de implements Translations$journal$en {
	_Translations$journal$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
class _Translations$weather$de implements Translations$weather$en {
	_Translations$weather$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
	@override String get fireRisk => 'Brandgefahr';
	@override String get fireRiskDesc => 'Hohe Brandgefahr. Sicherheitshinweise beachten.';
	@override String get fireSafetyTips => 'Brandschutzhinweise';
	@override String get alertCount => 'Warnung';
	@override String get alertCountPlural => 'Warnungen';
}

// Path: share
class _Translations$share$de implements Translations$share$en {
	_Translations$share$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Teilen';
	@override String get generating => 'Wird generiert...';
	@override String get share => 'Teilen';
	@override String get error => 'Fehler bei der Erstellung';
	@override String get errorShare => 'Fehler beim Teilen';
	@override String get preview => 'Vorschau';
	@override String get chooseTemplate => 'Vorlage wählen';
	@override String get templateStats => 'Statistiken';
	@override String get templateJourney => 'Strecke';
	@override String get templateStage => 'Etappe';
}

// Path: diploma
class _Translations$diploma$de implements Translations$diploma$en {
	_Translations$diploma$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderdiplom';
	@override String get yourName => 'Ihr Name';
	@override String get namePlaceholder => 'Geben Sie Ihren Namen ein...';
	@override String get generatePdf => 'PDF erstellen';
	@override String get certifies => 'Bestätigt, dass';
	@override String get completed => 'den Weg abgeschlossen hat';
	@override String get pdfTitle => 'DIPLOM';
	@override String get pdfSubtitle => 'Leistungszertifikat';
	@override String get pdfStages => '{count} Etappen';
	@override String get pdfDistance => '{km} km zurückgelegt';
	@override String get pdfElevation => '{meters} m Höhenunterschied';
	@override String get pdfDuration => 'in {days} Tagen';
	@override String get pdfFrom => 'Vom';
	@override String get pdfTo => 'bis';
	@override String get pdfIssuedOn => 'Ausgestellt am {date}';
	@override String get recapTitle => 'Ihr Abenteuer';
	@override String get recapJournalPhotos => 'Tagebuchfotos';
	@override String get recapNoPhotos => 'Keine Fotos im Tagebuch';
	@override String get recapStats => 'Statistiken';
	@override String get recapStages => '{count} Etappen absolviert';
	@override String get recapDistance => '{km} km zurueckgelegt';
	@override String get recapElevation => '{meters} m Hoehenunterschied';
	@override String get recapDuration => '{days} Tage Wanderung';
	@override String get recapMapTrace => 'Routenverlauf';
	@override String get recapNoMap => 'Verlauf nicht verfuegbar';
	@override String get recapJournalEntries => '{count} Tagebucheintraege';
	@override String get downloadPdf => 'Diplom-PDF herunterladen';
}

// Path: notifications
class _Translations$notifications$de implements Translations$notifications$en {
	_Translations$notifications$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Morgenerinnerung';
	@override String get weatherAlerts => 'Wetterwarnungen';
	@override String get countdown => 'Erinnerung 2 Tage vorher';
	@override String get countdownDesc => 'Benachrichtigung 2 Tage vor Abreise';
	@override String get schedulerCountdownTitle => 'Ihr Trek steht bevor!';
	@override String get schedulerCountdownBody => 'Abreise in 2 Tagen. Pruefen Sie Ihre Checkliste und das Wetter.';
	@override String get schedulerDailyTitle => 'Guten Trek-Tag!';
	@override String get schedulerDailyBody => 'Pruefen Sie das Wetter und bereiten Sie Ihre heutige Etappe vor.';
}

// Path: settings
class _Translations$settings$de implements Translations$settings$en {
	_Translations$settings$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
	@override String get morningReminder => 'Morgenerinnerung';
	@override String get weatherAlerts => 'Wetteralarme';
	@override String get weatherAlertsDesc => 'Benachrichtigung bei gefährlichen Bedingungen';
	@override String get countdownReminder => 'T-2 Erinnerung';
	@override String get countdownDesc => 'Benachrichtigung 2 Tage vor der Abreise';
	@override String get version => 'Version';
	@override String get versionLabel => 'App-Version';
}

// Path: feedback
class _Translations$feedback$de implements Translations$feedback$en {
	_Translations$feedback$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Feedbacktyp';
	@override String get bug => 'Fehler / Problem';
	@override String get suggestion => 'Vorschlag';
	@override String get compliment => 'Kompliment';
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
class _Translations$auth$de implements Translations$auth$en {
	_Translations$auth$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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
	@override String get pseudonym => 'Pseudonym';
	@override String get pseudonymHint => 'Ihr Wandername';
	@override String get save => 'Speichern';
	@override String get changeAvatar => 'Avatar ändern';
	@override String get chooseAvatar => 'Avatar wählen';
	@override String get errorLoading => 'Ladefehler';
}

// Path: feasibility
class _Translations$feasibility$de implements Translations$feasibility$en {
	_Translations$feasibility$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feasibility';
	@override String get subtitle => 'Assess your preparation';
	@override String get previous => 'Previous';
	@override String get restart => 'Start over';
	@override String get resultTitle => 'Your result';
	@override String get weakPointsTitle => 'Areas to improve';
	@override String get strongPointsTitle => 'Strong points';
	@override String get progress => '{current}/{total}';
	@override late final _Translations$feasibility$levels$de levels = _Translations$feasibility$levels$de._(_root);
	@override late final _Translations$feasibility$categories$de categories = _Translations$feasibility$categories$de._(_root);
	@override late final _Translations$feasibility$questions$de questions = _Translations$feasibility$questions$de._(_root);
	@override late final _Translations$feasibility$answers$de answers = _Translations$feasibility$answers$de._(_root);
	@override String get seeRecommendations => 'Empfehlungen anzeigen';
	@override String get yourProfile => 'Ihr Profil';
	@override String get tipsTitle => 'Unsere Tipps';
	@override late final _Translations$feasibility$recommendations$de recommendations = _Translations$feasibility$recommendations$de._(_root);
}

// Path: tips
class _Translations$tips$de implements Translations$tips$en {
	_Translations$tips$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Trek-Tipps';
	@override String get allCategories => 'Alle';
	@override String get swipeHint => 'Wischen fuer mehr';
	@override String get detailTitle => 'Tipp-Detail';
	@override String get readMore => 'Mehr lesen';
	@override String get noTips => 'Keine Tipps verfuegbar';
	@override String get categoryPreparation => 'Vorbereitung';
	@override String get categoryEquipment => 'Ausruestung';
	@override String get categoryNutrition => 'Ernaehrung';
	@override String get categorySafety => 'Sicherheit';
	@override String get categoryNature => 'Natur';
	@override String get categoryRecovery => 'Erholung';
	@override String get categoryGeneral => 'Allgemein';
	@override String get priorityHigh => 'Hohe Prioritaet';
	@override String get scope => 'Wanderweg';
	@override String get season => 'Saison';
	@override String get altitude => 'Min. Hoehe';
}

// Path: goodies
class _Translations$goodies$de implements Translations$goodies$en {
	_Translations$goodies$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Goodies-Shop';
	@override String get comingSoon => 'Dieses Modul kommt bald. Bleiben Sie dran!';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$de implements Translations$stage$difficulty$en {
	_Translations$stage$difficulty$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Leicht';
	@override String get moderate => 'Mittel';
	@override String get hard => 'Schwer';
	@override String get expert => 'Experte';
}

// Path: checklist.categories
class _Translations$checklist$categories$de implements Translations$checklist$categories$en {
	_Translations$checklist$categories$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Ausrüstung';
	@override String get clothing => 'Kleidung';
	@override String get food => 'Verpflegung';
	@override String get safety => 'Sicherheit';
	@override String get documents => 'Dokumente';
	@override String get hygiene => 'Hygiene';
}

// Path: checklist.items
class _Translations$checklist$items$de implements Translations$checklist$items$en {
	_Translations$checklist$items$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

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

// Path: feasibility.levels
class _Translations$feasibility$levels$de implements Translations$feasibility$levels$en {
	_Translations$feasibility$levels$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Not recommended';
	@override String get caution => 'Preparation needed';
	@override String get good => 'Feasible';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$de implements Translations$feasibility$categories$en {
	_Translations$feasibility$categories$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fitness => 'Physical fitness';
	@override String get experience => 'Experience';
	@override String get gear => 'Equipment';
	@override String get weather => 'Weather';
	@override String get duration => 'Duration';
	@override String get companion => 'Companions';
	@override String get health => 'Health';
	@override String get motivation => 'Motivation';
}

// Path: feasibility.questions
class _Translations$feasibility$questions$de implements Translations$feasibility$questions$en {
	_Translations$feasibility$questions$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fitnessQuestion => 'What is your physical fitness level?';
	@override String get experienceQuestion => 'What is your hiking experience?';
	@override String get gearQuestion => 'What is the state of your equipment?';
	@override String get weatherQuestion => 'Have you checked weather conditions?';
	@override String get durationQuestion => 'How many days do you plan?';
	@override String get companionQuestion => 'Are you hiking with others?';
	@override String get healthQuestion => 'Do you have any health concerns?';
	@override String get motivationQuestion => 'What is your motivation level?';
}

// Path: feasibility.answers
class _Translations$feasibility$answers$de implements Translations$feasibility$answers$en {
	_Translations$feasibility$answers$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get fitnessA => 'Sedentary, no training';
	@override String get fitnessB => 'Occasional physical activity';
	@override String get fitnessC => 'Regular exercise (2-3x/week)';
	@override String get fitnessD => 'Seasoned athlete, specifically trained';
	@override String get experienceA => 'No hiking experience';
	@override String get experienceB => 'A few day hikes';
	@override String get experienceC => 'Multi-day hikes completed';
	@override String get experienceD => 'Experienced trekker, long trails done';
	@override String get gearA => 'Incomplete or unsuitable gear';
	@override String get gearB => 'Basic gear, some items missing';
	@override String get gearC => 'Complete gear, good condition';
	@override String get gearD => 'Technical gear, tested and proven';
	@override String get weatherA => 'Not checked, no idea';
	@override String get weatherB => 'Briefly checked, uncertain conditions';
	@override String get weatherC => 'Checked, fair conditions expected';
	@override String get weatherD => 'Thoroughly checked, favorable window';
	@override String get durationA => 'No idea of the duration';
	@override String get durationB => 'Underestimated or too ambitious';
	@override String get durationC => 'Realistic plan with margins';
	@override String get durationD => 'Detailed plan, rest days included';
	@override String get companionA => 'Solo, no solo experience';
	@override String get companionB => 'Solo, but experienced';
	@override String get companionC => 'In a group, mixed levels';
	@override String get companionD => 'In a group, all experienced';
	@override String get healthA => 'Untreated health issues';
	@override String get healthB => 'Minor issues, under control';
	@override String get healthC => 'Generally good health';
	@override String get healthD => 'Excellent health, recent checkup';
	@override String get motivationA => 'Low motivation, hesitant';
	@override String get motivationB => 'Motivated but anxious';
	@override String get motivationC => 'Motivated and determined';
	@override String get motivationD => 'Absolute passion, long-time dream';
}

// Path: feasibility.recommendations
class _Translations$feasibility$recommendations$de implements Translations$feasibility$recommendations$en {
	_Translations$feasibility$recommendations$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$de danger = _Translations$feasibility$recommendations$danger$de._(_root);
	@override late final _Translations$feasibility$recommendations$caution$de caution = _Translations$feasibility$recommendations$caution$de._(_root);
	@override late final _Translations$feasibility$recommendations$good$de good = _Translations$feasibility$recommendations$good$de._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$de excellent = _Translations$feasibility$recommendations$excellent$de._(_root);
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$de implements Translations$feasibility$recommendations$danger$en {
	_Translations$feasibility$recommendations$danger$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unzureichende Vorbereitung';
	@override String get summary => 'Ihr Profil zeigt erhebliche Lücken. Wir raten vom Start ab.';
	@override late final _Translations$feasibility$recommendations$danger$tips$de tips = _Translations$feasibility$recommendations$danger$tips$de._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$de implements Translations$feasibility$recommendations$caution$en {
	_Translations$feasibility$recommendations$caution$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vorbereitung verstärken';
	@override String get summary => 'Sie haben Grundlagen, aber einige Bereiche brauchen Aufmerksamkeit.';
	@override late final _Translations$feasibility$recommendations$caution$tips$de tips = _Translations$feasibility$recommendations$caution$tips$de._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$de implements Translations$feasibility$recommendations$good$en {
	_Translations$feasibility$recommendations$good$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gute Vorbereitung';
	@override String get summary => 'Ihr Profil ist solide. Einige Anpassungen und Sie sind bereit.';
	@override late final _Translations$feasibility$recommendations$good$tips$de tips = _Translations$feasibility$recommendations$good$tips$de._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$de implements Translations$feasibility$recommendations$excellent$en {
	_Translations$feasibility$recommendations$excellent$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Optimale Vorbereitung';
	@override String get summary => 'Sie sind perfekt vorbereitet. Genießen Sie die Wanderung!';
	@override late final _Translations$feasibility$recommendations$excellent$tips$de tips = _Translations$feasibility$recommendations$excellent$tips$de._(_root);
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$de implements Translations$feasibility$recommendations$danger$tips$en {
	_Translations$feasibility$recommendations$danger$tips$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Beginnen Sie mit kurzen Wanderungen';
	@override String get tip2 => 'Konsultieren Sie einen Arzt vor längerer Anstrengung';
	@override String get tip3 => 'Investieren Sie in geeignete Ausrüstung';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$de implements Translations$feasibility$recommendations$caution$tips$en {
	_Translations$feasibility$recommendations$caution$tips$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Verstärken Sie Ihr Training 6 bis 8 Wochen vorher';
	@override String get tip2 => 'Überprüfen und ergänzen Sie Ihre Ausrüstung';
	@override String get tip3 => 'Planen Sie Etappen, die Ihrem Niveau entsprechen';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$de implements Translations$feasibility$recommendations$good$tips$en {
	_Translations$feasibility$recommendations$good$tips$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Halten Sie Ihr Trainingstempo aufrecht';
	@override String get tip2 => 'Planen Sie Puffer in Ihrem Zeitplan ein';
	@override String get tip3 => 'Überprüfen Sie regelmäßig das Wetter';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$de implements Translations$feasibility$recommendations$excellent$tips$en {
	_Translations$feasibility$recommendations$excellent$tips$de._(this._root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Hören Sie auf Ihren Körper';
	@override String get tip2 => 'Teilen Sie Ihre Erfahrung mit anderen Wanderern';
	@override String get tip3 => 'Dokumentieren Sie Ihr Abenteuer im Tagebuch';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'map.title' => 'Wanderkarte',
			'map.loading' => 'Strecke wird geladen...',
			'map.noTrack' => 'Keine Strecke verfÃ¼gbar',
			'map.viewMap' => 'Karte anzeigen',
			'stage.distance' => 'Entfernung',
			'stage.elevation' => 'HÃ¶henunterschied',
			'stage.elevationGain' => 'HÃ¶henmeter aufwÃ¤rts',
			'stage.elevationLoss' => 'HÃ¶henmeter abwÃ¤rts',
			'stage.duration' => 'GeschÃ¤tzte Dauer',
			'stage.description' => 'Beschreibung',
			'stage.coordinates' => 'Koordinaten',
			'stage.pois' => 'SehenswÃ¼rdigkeiten',
			'stage.difficulty.easy' => 'Leicht',
			'stage.difficulty.moderate' => 'Mittel',
			'stage.difficulty.hard' => 'Schwer',
			'stage.difficulty.expert' => 'Experte',
			'stage.remaining' => '{distance} km verbleibend',
			'stage.arrived' => 'Sie sind angekommen!',
			'trail.stages' => 'Etappen',
			'trail.totalDistance' => 'Gesamtstrecke',
			'trail.totalElevation' => 'GesamthÃ¶henmeter',
			'poi.shelter' => 'SchutzhÃ¼tte',
			'poi.water' => 'Wasserquelle',
			'poi.viewpoint' => 'Aussichtspunkt',
			'poi.campsite' => 'Biwakplatz',
			'poi.restaurant' => 'Restaurant',
			'poi.emergency' => 'Notfall',
			'poi.danger' => 'Gefahr',
			'poi.shop' => 'GeschÃ¤ft',
			'poi.filter' => 'SehenswÃ¼rdigkeiten filtern',
			'poi.altitude' => 'HÃ¶he',
			'poi.hours' => 'Ãffnungszeiten',
			'gps.permission' => 'GPS-Berechtigung erforderlich',
			'gps.denied' => 'Standortzugriff verweigert',
			'gps.disabled' => 'Standortdienst deaktiviert',
			'gps.offTrack' => 'Abseits der Strecke',
			'gps.centerOnMe' => 'Auf meine Position zentrieren',
			'planning.title' => 'Planung',
			'planning.duration' => 'Dauer',
			'planning.days' => 'Tage',
			'planning.day' => 'Tag',
			'planning.restDay' => 'Ruhetag',
			'planning.totalDistance' => 'Gesamtstrecke',
			'planning.totalElevation' => 'Gesamthöhenmeter',
			'planning.estimatedTime' => 'Geschätzte Dauer',
			'planning.stages' => 'Etappen',
			'planning.plan' => 'Planen',
			'tracking.start' => 'Starten',
			'tracking.pause' => 'Pause',
			'tracking.resume' => 'Fortsetzen',
			'tracking.stop' => 'Stoppen',
			'tracking.distance' => 'Entfernung',
			'tracking.elevation' => 'Hohenmeter',
			'tracking.speed' => 'Geschwindigkeit',
			'tracking.time' => 'Zeit',
			'tracking.confirmStop' => 'Tracking stoppen?',
			'checklist.title' => 'Ausrüstungsliste',
			'checklist.subtitle' => 'Packen Sie Ihren Rucksack',
			'checklist.progress' => '{checked}/{total} gepackt',
			'checklist.complete' => 'Checkliste vollständig!',
			'checklist.reset' => 'Zurücksetzen',
			'checklist.resetConfirm' => 'Checkliste zurücksetzen?',
			'checklist.resetDescription' => 'Alle Elemente werden abgehakt.',
			'checklist.cancel' => 'Abbrechen',
			'checklist.confirm' => 'Bestätigen',
			'checklist.categories.equipment' => 'Ausrüstung',
			'checklist.categories.clothing' => 'Kleidung',
			'checklist.categories.food' => 'Verpflegung',
			'checklist.categories.safety' => 'Sicherheit',
			'checklist.categories.documents' => 'Dokumente',
			'checklist.categories.hygiene' => 'Hygiene',
			'checklist.items.backpack' => 'Rucksack',
			'checklist.items.sleepingBag' => 'Schlafsack',
			'checklist.items.sleepingPad' => 'Isomatte',
			'checklist.items.hikingPoles' => 'Wanderstöcke',
			'checklist.items.headlamp' => 'Stirnlampe',
			'checklist.items.waterBottle' => 'Trinkflasche',
			'checklist.items.hikingBoots' => 'Wanderschuhe',
			'checklist.items.rainJacket' => 'Regenjacke',
			'checklist.items.warmLayer' => 'Wärmeschicht',
			'checklist.items.hikingSocks' => 'Wandersocken',
			'checklist.items.hat' => 'Hut',
			'checklist.items.gloves' => 'Handschuhe',
			'checklist.items.trailSnacks' => 'Wandersnacks',
			'checklist.items.energyBars' => 'Energieriegel',
			'checklist.items.waterPurification' => 'Wasseraufbereitung',
			'checklist.items.firstAidKit' => 'Erste-Hilfe-Set',
			'checklist.items.whistle' => 'Pfeife',
			'checklist.items.emergencyBlanket' => 'Rettungsdecke',
			'checklist.items.sunscreen' => 'Sonnenschutz',
			'checklist.items.idCard' => 'Ausweis',
			'checklist.items.insurance' => 'Versicherung',
			'checklist.items.trailMap' => 'Wanderkarte',
			'checklist.items.toiletPaper' => 'Toilettenpapier',
			'checklist.items.handSanitizer' => 'Handdesinfektionsmittel',
			'checklist.items.towel' => 'Handtuch',
			'checklist.essential' => 'Wesentlich',
			'journal.title' => 'Wandertagebuch',
			'journal.empty' => 'Ihr Tagebuch ist leer',
			'journal.emptySubtitle' => 'Notieren Sie Ihre Eindrücke und Erinnerungen',
			'journal.addNote' => 'Neue Notiz',
			'journal.stage' => 'Etappe',
			'journal.yourNote' => 'Ihre Notiz',
			'journal.placeholder' => 'Beschreiben Sie Ihren Wandertag...',
			'journal.save' => 'Speichern',
			'journal.cancel' => 'Abbrechen',
			'journal.delete' => 'Löschen',
			'journal.photoLimit' => 'Limit von 3 Fotos pro Tag erreicht',
			'journal.photoTooBig' => 'Foto zu groß (max 500 KB)',
			'weather.title' => 'Wetter',
			'weather.loading' => 'Wetter wird geladen...',
			'weather.offline' => 'Keine Verbindung. Wetterdaten nicht verfügbar.',
			'weather.error' => 'Wetter konnte nicht geladen werden.',
			'weather.cached' => 'Zwischengespeicherte Daten',
			'weather.alerts' => 'Wetterwarnungen',
			'weather.refresh' => 'Aktualisieren',
			'weather.temperature' => 'Temperatur',
			'weather.precipitation' => 'Niederschlag',
			'weather.wind' => 'Wind',
			'weather.uv' => 'UV-Index',
			'weather.fireRisk' => 'Brandgefahr',
			'weather.fireRiskDesc' => 'Hohe Brandgefahr. Sicherheitshinweise beachten.',
			'weather.fireSafetyTips' => 'Brandschutzhinweise',
			'weather.alertCount' => 'Warnung',
			'weather.alertCountPlural' => 'Warnungen',
			'share.title' => 'Teilen',
			'share.generating' => 'Wird generiert...',
			'share.share' => 'Teilen',
			'share.error' => 'Fehler bei der Erstellung',
			'share.errorShare' => 'Fehler beim Teilen',
			'share.preview' => 'Vorschau',
			'share.chooseTemplate' => 'Vorlage wählen',
			'share.templateStats' => 'Statistiken',
			'share.templateJourney' => 'Strecke',
			'share.templateStage' => 'Etappe',
			'diploma.title' => 'Wanderdiplom',
			'diploma.yourName' => 'Ihr Name',
			'diploma.namePlaceholder' => 'Geben Sie Ihren Namen ein...',
			'diploma.generatePdf' => 'PDF erstellen',
			'diploma.certifies' => 'Bestätigt, dass',
			'diploma.completed' => 'den Weg abgeschlossen hat',
			'diploma.pdfTitle' => 'DIPLOM',
			'diploma.pdfSubtitle' => 'Leistungszertifikat',
			'diploma.pdfStages' => '{count} Etappen',
			'diploma.pdfDistance' => '{km} km zurückgelegt',
			'diploma.pdfElevation' => '{meters} m Höhenunterschied',
			'diploma.pdfDuration' => 'in {days} Tagen',
			'diploma.pdfFrom' => 'Vom',
			'diploma.pdfTo' => 'bis',
			'diploma.pdfIssuedOn' => 'Ausgestellt am {date}',
			'diploma.recapTitle' => 'Ihr Abenteuer',
			'diploma.recapJournalPhotos' => 'Tagebuchfotos',
			'diploma.recapNoPhotos' => 'Keine Fotos im Tagebuch',
			'diploma.recapStats' => 'Statistiken',
			'diploma.recapStages' => '{count} Etappen absolviert',
			'diploma.recapDistance' => '{km} km zurueckgelegt',
			'diploma.recapElevation' => '{meters} m Hoehenunterschied',
			'diploma.recapDuration' => '{days} Tage Wanderung',
			'diploma.recapMapTrace' => 'Routenverlauf',
			'diploma.recapNoMap' => 'Verlauf nicht verfuegbar',
			'diploma.recapJournalEntries' => '{count} Tagebucheintraege',
			'diploma.downloadPdf' => 'Diplom-PDF herunterladen',
			'notifications.morningReminder' => 'Morgenerinnerung',
			'notifications.weatherAlerts' => 'Wetterwarnungen',
			'notifications.countdown' => 'Erinnerung 2 Tage vorher',
			'notifications.countdownDesc' => 'Benachrichtigung 2 Tage vor Abreise',
			'notifications.schedulerCountdownTitle' => 'Ihr Trek steht bevor!',
			'notifications.schedulerCountdownBody' => 'Abreise in 2 Tagen. Pruefen Sie Ihre Checkliste und das Wetter.',
			'notifications.schedulerDailyTitle' => 'Guten Trek-Tag!',
			'notifications.schedulerDailyBody' => 'Pruefen Sie das Wetter und bereiten Sie Ihre heutige Etappe vor.',
			'settings.title' => 'Einstellungen',
			'settings.language' => 'Sprache',
			'settings.units' => 'Einheiten',
			'settings.distance' => 'Entfernung',
			'settings.temperature' => 'Temperatur',
			'settings.theme' => 'Thema',
			'settings.dark' => 'Dunkel',
			'settings.light' => 'Hell',
			'settings.system' => 'System',
			'settings.cache' => 'Cache',
			'settings.cacheEnabled' => 'Cache aktiviert',
			'settings.cacheDesc' => 'Daten offline verfügbar',
			'settings.cacheSize' => 'Cache-Größe',
			'settings.notifications' => 'Benachrichtigungen',
			'settings.morningReminder' => 'Morgenerinnerung',
			'settings.weatherAlerts' => 'Wetteralarme',
			'settings.weatherAlertsDesc' => 'Benachrichtigung bei gefährlichen Bedingungen',
			'settings.countdownReminder' => 'T-2 Erinnerung',
			'settings.countdownDesc' => 'Benachrichtigung 2 Tage vor der Abreise',
			'settings.version' => 'Version',
			'settings.versionLabel' => 'App-Version',
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Feedbacktyp',
			'feedback.bug' => 'Fehler / Problem',
			'feedback.suggestion' => 'Vorschlag',
			'feedback.compliment' => 'Kompliment',
			'feedback.question' => 'Frage',
			'feedback.other' => 'Sonstiges',
			'feedback.message' => 'Ihre Nachricht',
			'feedback.messagePlaceholder' => 'Beschreiben Sie Ihr Feedback...',
			'feedback.satisfaction' => 'Zufriedenheit',
			'feedback.send' => 'Senden',
			'feedback.sending' => 'Wird gesendet...',
			'feedback.thanks' => 'Vielen Dank für Ihr Feedback!',
			'feedback.pending' => 'ausstehend',
			'auth.profile' => 'Profil',
			'auth.anonymous' => 'Anonymer Wanderer',
			'auth.connectedVia' => 'Verbunden über',
			'auth.signInGoogle' => 'Mit Google anmelden',
			'auth.signInGoogleDesc' => 'Um Ihren Fortschritt zu speichern',
			'auth.signOut' => 'Abmelden',
			'auth.signOutDesc' => 'Zurück zum anonymen Modus',
			'auth.signOutConfirm' => 'Abmelden?',
			'auth.signOutMessage' => 'Sie kehren zum anonymen Modus zurück. Ihre lokalen Daten bleiben erhalten.',
			'auth.deleteAccount' => 'Mein Konto löschen',
			'auth.deleteAccountDesc' => 'Alle Ihre Daten werden gelöscht',
			'auth.deleteConfirm' => 'Konto löschen?',
			'auth.deleteMessage' => 'Diese Aktion ist unwiderruflich. Alle Ihre Daten, Notizen und Fortschritte werden gelöscht.',
			'auth.cancel' => 'Abbrechen',
			'auth.pseudonym' => 'Pseudonym',
			'auth.pseudonymHint' => 'Ihr Wandername',
			'auth.save' => 'Speichern',
			'auth.changeAvatar' => 'Avatar ändern',
			'auth.chooseAvatar' => 'Avatar wählen',
			'auth.errorLoading' => 'Ladefehler',
			'feasibility.title' => 'Feasibility',
			'feasibility.subtitle' => 'Assess your preparation',
			'feasibility.previous' => 'Previous',
			'feasibility.restart' => 'Start over',
			'feasibility.resultTitle' => 'Your result',
			'feasibility.weakPointsTitle' => 'Areas to improve',
			'feasibility.strongPointsTitle' => 'Strong points',
			'feasibility.progress' => '{current}/{total}',
			'feasibility.levels.danger' => 'Not recommended',
			'feasibility.levels.caution' => 'Preparation needed',
			'feasibility.levels.good' => 'Feasible',
			'feasibility.levels.excellent' => 'Excellent',
			'feasibility.categories.fitness' => 'Physical fitness',
			'feasibility.categories.experience' => 'Experience',
			'feasibility.categories.gear' => 'Equipment',
			'feasibility.categories.weather' => 'Weather',
			'feasibility.categories.duration' => 'Duration',
			'feasibility.categories.companion' => 'Companions',
			'feasibility.categories.health' => 'Health',
			'feasibility.categories.motivation' => 'Motivation',
			'feasibility.questions.fitnessQuestion' => 'What is your physical fitness level?',
			'feasibility.questions.experienceQuestion' => 'What is your hiking experience?',
			'feasibility.questions.gearQuestion' => 'What is the state of your equipment?',
			'feasibility.questions.weatherQuestion' => 'Have you checked weather conditions?',
			'feasibility.questions.durationQuestion' => 'How many days do you plan?',
			'feasibility.questions.companionQuestion' => 'Are you hiking with others?',
			'feasibility.questions.healthQuestion' => 'Do you have any health concerns?',
			'feasibility.questions.motivationQuestion' => 'What is your motivation level?',
			'feasibility.answers.fitnessA' => 'Sedentary, no training',
			'feasibility.answers.fitnessB' => 'Occasional physical activity',
			'feasibility.answers.fitnessC' => 'Regular exercise (2-3x/week)',
			'feasibility.answers.fitnessD' => 'Seasoned athlete, specifically trained',
			'feasibility.answers.experienceA' => 'No hiking experience',
			'feasibility.answers.experienceB' => 'A few day hikes',
			'feasibility.answers.experienceC' => 'Multi-day hikes completed',
			'feasibility.answers.experienceD' => 'Experienced trekker, long trails done',
			'feasibility.answers.gearA' => 'Incomplete or unsuitable gear',
			'feasibility.answers.gearB' => 'Basic gear, some items missing',
			'feasibility.answers.gearC' => 'Complete gear, good condition',
			'feasibility.answers.gearD' => 'Technical gear, tested and proven',
			'feasibility.answers.weatherA' => 'Not checked, no idea',
			'feasibility.answers.weatherB' => 'Briefly checked, uncertain conditions',
			'feasibility.answers.weatherC' => 'Checked, fair conditions expected',
			'feasibility.answers.weatherD' => 'Thoroughly checked, favorable window',
			'feasibility.answers.durationA' => 'No idea of the duration',
			'feasibility.answers.durationB' => 'Underestimated or too ambitious',
			'feasibility.answers.durationC' => 'Realistic plan with margins',
			'feasibility.answers.durationD' => 'Detailed plan, rest days included',
			'feasibility.answers.companionA' => 'Solo, no solo experience',
			'feasibility.answers.companionB' => 'Solo, but experienced',
			'feasibility.answers.companionC' => 'In a group, mixed levels',
			'feasibility.answers.companionD' => 'In a group, all experienced',
			'feasibility.answers.healthA' => 'Untreated health issues',
			'feasibility.answers.healthB' => 'Minor issues, under control',
			'feasibility.answers.healthC' => 'Generally good health',
			'feasibility.answers.healthD' => 'Excellent health, recent checkup',
			'feasibility.answers.motivationA' => 'Low motivation, hesitant',
			'feasibility.answers.motivationB' => 'Motivated but anxious',
			'feasibility.answers.motivationC' => 'Motivated and determined',
			'feasibility.answers.motivationD' => 'Absolute passion, long-time dream',
			'feasibility.seeRecommendations' => 'Empfehlungen anzeigen',
			'feasibility.yourProfile' => 'Ihr Profil',
			'feasibility.tipsTitle' => 'Unsere Tipps',
			'feasibility.recommendations.danger.title' => 'Unzureichende Vorbereitung',
			'feasibility.recommendations.danger.summary' => 'Ihr Profil zeigt erhebliche Lücken. Wir raten vom Start ab.',
			'feasibility.recommendations.danger.tips.tip1' => 'Beginnen Sie mit kurzen Wanderungen',
			'feasibility.recommendations.danger.tips.tip2' => 'Konsultieren Sie einen Arzt vor längerer Anstrengung',
			'feasibility.recommendations.danger.tips.tip3' => 'Investieren Sie in geeignete Ausrüstung',
			'feasibility.recommendations.caution.title' => 'Vorbereitung verstärken',
			'feasibility.recommendations.caution.summary' => 'Sie haben Grundlagen, aber einige Bereiche brauchen Aufmerksamkeit.',
			'feasibility.recommendations.caution.tips.tip1' => 'Verstärken Sie Ihr Training 6 bis 8 Wochen vorher',
			'feasibility.recommendations.caution.tips.tip2' => 'Überprüfen und ergänzen Sie Ihre Ausrüstung',
			'feasibility.recommendations.caution.tips.tip3' => 'Planen Sie Etappen, die Ihrem Niveau entsprechen',
			'feasibility.recommendations.good.title' => 'Gute Vorbereitung',
			'feasibility.recommendations.good.summary' => 'Ihr Profil ist solide. Einige Anpassungen und Sie sind bereit.',
			'feasibility.recommendations.good.tips.tip1' => 'Halten Sie Ihr Trainingstempo aufrecht',
			'feasibility.recommendations.good.tips.tip2' => 'Planen Sie Puffer in Ihrem Zeitplan ein',
			'feasibility.recommendations.good.tips.tip3' => 'Überprüfen Sie regelmäßig das Wetter',
			'feasibility.recommendations.excellent.title' => 'Optimale Vorbereitung',
			'feasibility.recommendations.excellent.summary' => 'Sie sind perfekt vorbereitet. Genießen Sie die Wanderung!',
			'feasibility.recommendations.excellent.tips.tip1' => 'Hören Sie auf Ihren Körper',
			'feasibility.recommendations.excellent.tips.tip2' => 'Teilen Sie Ihre Erfahrung mit anderen Wanderern',
			'feasibility.recommendations.excellent.tips.tip3' => 'Dokumentieren Sie Ihr Abenteuer im Tagebuch',
			'tips.carouselTitle' => 'Trek-Tipps',
			'tips.allCategories' => 'Alle',
			'tips.swipeHint' => 'Wischen fuer mehr',
			'tips.detailTitle' => 'Tipp-Detail',
			'tips.readMore' => 'Mehr lesen',
			'tips.noTips' => 'Keine Tipps verfuegbar',
			'tips.categoryPreparation' => 'Vorbereitung',
			'tips.categoryEquipment' => 'Ausruestung',
			'tips.categoryNutrition' => 'Ernaehrung',
			'tips.categorySafety' => 'Sicherheit',
			'tips.categoryNature' => 'Natur',
			'tips.categoryRecovery' => 'Erholung',
			'tips.categoryGeneral' => 'Allgemein',
			'tips.priorityHigh' => 'Hohe Prioritaet',
			'tips.scope' => 'Wanderweg',
			'tips.season' => 'Saison',
			'tips.altitude' => 'Min. Hoehe',
			'goodies.title' => 'Goodies-Shop',
			'goodies.comingSoon' => 'Dieses Modul kommt bald. Bleiben Sie dran!',
			_ => null,
		};
	}
}
