///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsDe extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsDe({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.de,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <de>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsDe _root = this; // ignore: unused_field

	@override 
	TranslationsDe $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsDe(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$a11y$de a11y = _Translations$a11y$de._(_root);
	@override late final _Translations$nav$de nav = _Translations$nav$de._(_root);
	@override late final _Translations$branding$de branding = _Translations$branding$de._(_root);
	@override late final _Translations$hub$de hub = _Translations$hub$de._(_root);
	@override late final _Translations$map$de map = _Translations$map$de._(_root);
	@override late final _Translations$stage$de stage = _Translations$stage$de._(_root);
	@override late final _Translations$trail$de trail = _Translations$trail$de._(_root);
	@override late final _Translations$poi$de poi = _Translations$poi$de._(_root);
	@override late final _Translations$accommodation$de accommodation = _Translations$accommodation$de._(_root);
	@override late final _Translations$gps$de gps = _Translations$gps$de._(_root);
	@override late final _Translations$navAlert$de navAlert = _Translations$navAlert$de._(_root);
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
	@override late final _Translations$noData$de noData = _Translations$noData$de._(_root);
	@override late final _Translations$catalog$de catalog = _Translations$catalog$de._(_root);
	@override late final _Translations$updates$de updates = _Translations$updates$de._(_root);
	@override late final _Translations$follow$de follow = _Translations$follow$de._(_root);
	@override late final _Translations$cloud$de cloud = _Translations$cloud$de._(_root);
	@override late final _Translations$onboarding$de onboarding = _Translations$onboarding$de._(_root);
	@override late final _Translations$monetization$de monetization = _Translations$monetization$de._(_root);
	@override late final _Translations$signalement$de signalement = _Translations$signalement$de._(_root);
	@override late final _Translations$hebergement$de hebergement = _Translations$hebergement$de._(_root);
	@override late final _Translations$training$de training = _Translations$training$de._(_root);
	@override late final _Translations$eta$de eta = _Translations$eta$de._(_root);
	@override late final _Translations$leaderboard$de leaderboard = _Translations$leaderboard$de._(_root);
	@override late final _Translations$social$de social = _Translations$social$de._(_root);
	@override late final _Translations$gamification$de gamification = _Translations$gamification$de._(_root);
	@override late final _Translations$shareVisibility$de shareVisibility = _Translations$shareVisibility$de._(_root);
	@override late final _Translations$waypoints$de waypoints = _Translations$waypoints$de._(_root);
	@override late final _Translations$packs$de packs = _Translations$packs$de._(_root);
	@override late final _Translations$guides$de guides = _Translations$guides$de._(_root);
	@override late final _Translations$trailSelection$de trailSelection = _Translations$trailSelection$de._(_root);
	@override late final _Translations$consent$de consent = _Translations$consent$de._(_root);
	@override late final _Translations$moderation$de moderation = _Translations$moderation$de._(_root);
}

// Path: a11y
class _Translations$a11y$de extends Translations$a11y$fr {
	_Translations$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get back => 'Zuruck';
	@override String get zoomIn => 'Vergrossern';
	@override String get zoomOut => 'Verkleinern';
	@override String get centerOnMe => 'Auf meine Position zentrieren';
	@override String get mapRegion => 'Wanderkarte';
	@override String get userPosition => 'Ihre Position';
	@override String stageMarker({required Object number}) => 'Etappe ${number}';
	@override String poiMarker({required Object name}) => 'Interessanter Punkt: ${name}';
	@override String markerCluster({required Object count}) => '${count} gruppierte Punkte';
	@override String trailCard({required Object name}) => 'Weg ${name}';
	@override String get startTracking => 'Aufzeichnung starten';
	@override String get pauseTracking => 'Aufzeichnung pausieren';
	@override String get resumeTracking => 'Aufzeichnung fortsetzen';
	@override String get stopTracking => 'Aufzeichnung beenden';
}

// Path: nav
class _Translations$nav$de extends Translations$nav$fr {
	_Translations$nav$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Start';
	@override String get map => 'Karte';
	@override String get stages => 'Etappen';
	@override String get planning => 'Planung';
	@override String get journal => 'Tagebuch';
	@override String get more => 'Mehr';
	@override String get checklist => 'Ausrüstungsliste';
	@override String get feasibility => 'Machbarkeit';
	@override String get tips => 'Trek-Tipps';
	@override String get emergency => 'Notfallkontakte';
	@override String get catalog => 'Wegekatalog';
	@override String get profile => 'Profil';
	@override String get settings => 'Einstellungen';
	@override String get trailSelection => 'Weg wechseln';
}

// Path: branding
class _Translations$branding$de extends Translations$branding$fr {
	_Translations$branding$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Ihr Trekking-Begleiter';
	@override String get subline => 'Vorbereiten, wandern, teilen';
}

// Path: hub
class _Translations$hub$de extends Translations$hub$fr {
	_Translations$hub$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String greeting({required Object name}) => 'Hallo, ${name}!';
	@override String get greetingFallback => 'Wanderer';
	@override String get infoTooltip => 'Über diesen Weg';
	@override String get profileTooltip => 'Mein Profil';
	@override String get infoSheetBody => 'Dieser Weg begleitet Sie bei jedem Schritt: Planen Sie Ihre Route, packen Sie Ihren Rucksack und starten Sie dann mit der GPS-Navigation. Jede Funktion ist von diesem Startbildschirm aus erreichbar.';
	@override late final _Translations$hub$trekCard$de trekCard = _Translations$hub$trekCard$de._(_root);
	@override late final _Translations$hub$weather$de weather = _Translations$hub$weather$de._(_root);
	@override String get startCta => 'Trek starten';
	@override late final _Translations$hub$sections$de sections = _Translations$hub$sections$de._(_root);
	@override late final _Translations$hub$cards$de cards = _Translations$hub$cards$de._(_root);
	@override late final _Translations$hub$fab$de fab = _Translations$hub$fab$de._(_root);
}

// Path: map
class _Translations$map$de extends Translations$map$fr {
	_Translations$map$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderkarte';
	@override String get loading => 'Strecke wird geladen...';
	@override String get noTrack => 'Keine Strecke verfÃ¼gbar';
	@override String get viewMap => 'Karte anzeigen';
}

// Path: stage
class _Translations$stage$de extends Translations$stage$fr {
	_Translations$stage$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$trail$de extends Translations$trail$fr {
	_Translations$trail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etappen';
	@override String get totalDistance => 'Gesamtstrecke';
	@override String get totalElevation => 'GesamthÃ¶henmeter';
}

// Path: poi
class _Translations$poi$de extends Translations$poi$fr {
	_Translations$poi$de._(TranslationsDe root) : this._root = root, super.internal(root);

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

// Path: accommodation
class _Translations$accommodation$de extends Translations$accommodation$fr {
	_Translations$accommodation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$accommodation$types$de types = _Translations$accommodation$types$de._(_root);
}

// Path: gps
class _Translations$gps$de extends Translations$gps$fr {
	_Translations$gps$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get permission => 'GPS-Berechtigung erforderlich';
	@override String get denied => 'Standortzugriff verweigert';
	@override String get disabled => 'Standortdienst deaktiviert';
	@override String get offTrack => 'Abseits der Strecke';
	@override String get centerOnMe => 'Auf meine Position zentrieren';
}

// Path: navAlert
class _Translations$navAlert$de extends Translations$navAlert$fr {
	_Translations$navAlert$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String offTrackBanner({required Object meters}) => 'Sie entfernen sich vom Weg — ${meters} m. Uberprufen Sie Ihre Position.';
	@override String get offTrackNotifTitle => 'Sie verlassen den Weg';
	@override String offTrackNotifBody({required Object meters}) => 'Sie entfernen sich vom Weg (${meters} m). Uberprufen Sie Ihre Position.';
}

// Path: planning
class _Translations$planning$de extends Translations$planning$fr {
	_Translations$planning$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$tracking$de extends Translations$tracking$fr {
	_Translations$tracking$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$checklist$de extends Translations$checklist$fr {
	_Translations$checklist$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$journal$de extends Translations$journal$fr {
	_Translations$journal$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$weather$de extends Translations$weather$fr {
	_Translations$weather$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$share$de extends Translations$share$fr {
	_Translations$share$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$diploma$de extends Translations$diploma$fr {
	_Translations$diploma$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$notifications$de extends Translations$notifications$fr {
	_Translations$notifications$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$settings$de extends Translations$settings$fr {
	_Translations$settings$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
	@override String get offTrackAlerts => 'Abseits-der-Strecke-Warnung';
	@override String get offTrackAlertsDesc => 'Benachrichtigung + Vibration, wenn Sie den Weg verlassen';
	@override String get version => 'Version';
	@override String get versionLabel => 'App-Version';
}

// Path: feedback
class _Translations$feedback$de extends Translations$feedback$fr {
	_Translations$feedback$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$auth$de extends Translations$auth$fr {
	_Translations$auth$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profil';
	@override String get anonymous => 'Wanderer ohne Konto';
	@override String get connectedVia => 'Verbunden über';
	@override String get signInGoogle => 'Mit Google anmelden';
	@override String get signInGoogleDesc => 'Um Ihren Fortschritt zu speichern';
	@override String get signOut => 'Abmelden';
	@override String get signOutDesc => 'Zurück zum Modus ohne Konto';
	@override String get signOutConfirm => 'Abmelden?';
	@override String get signOutMessage => 'Sie kehren zum Modus ohne Konto zurück. Ihre lokalen Daten bleiben erhalten.';
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
class _Translations$feasibility$de extends Translations$feasibility$fr {
	_Translations$feasibility$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$tips$de extends Translations$tips$fr {
	_Translations$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$goodies$de extends Translations$goodies$fr {
	_Translations$goodies$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Goodies-Shop';
	@override String get comingSoon => 'Dieses Modul kommt bald. Bleiben Sie dran!';
}

// Path: noData
class _Translations$noData$de extends Translations$noData$fr {
	_Translations$noData$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kein Weg heruntergeladen';
	@override String get subtitle => 'Laden Sie einen Weg herunter, um zu beginnen';
	@override String get offlineHint => 'Die Daten sind offline für Ihre Wanderung verfügbar.';
	@override String get browseCta => 'Wege durchsuchen';
}

// Path: catalog
class _Translations$catalog$de extends Translations$catalog$fr {
	_Translations$catalog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wegekatalog';
	@override String get enter => 'Öffnen';
	@override String get mustDownload => 'Laden Sie diesen Weg herunter, um ihn zu erkunden.';
	@override String get emptyTitle => 'Kein Weg verfügbar';
	@override String get emptySubtitle => 'Im Katalog wird noch kein Weg angeboten.';
	@override late final _Translations$catalog$a11y$de a11y = _Translations$catalog$a11y$de._(_root);
}

// Path: updates
class _Translations$updates$de extends Translations$updates$fr {
	_Translations$updates$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get readyTitle => 'Update bereit';
	@override String get readyBodyOne => 'Ein Weg wurde aktualisiert.';
	@override String readyBodyMany({required Object count}) => '${count} Wege wurden aktualisiert.';
}

// Path: follow
class _Translations$follow$de extends Translations$follow$fr {
	_Translations$follow$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live-Verfolgung';
	@override String get connecting => 'Verbinden…';
	@override String get live => 'Live';
	@override String get offline => 'Offline';
	@override String get invalidLink => 'Ungültiger Link';
	@override String get invalidLinkHint => 'Dieser Tracking-Link existiert nicht oder ist abgelaufen.';
}

// Path: cloud
class _Translations$cloud$de extends Translations$cloud$fr {
	_Translations$cloud$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get localModeTitle => 'Lokaler Modus';
	@override String get localModeBody => 'Diese Installation ist mit keinem Cloud-Dienst verbunden: Live-Verfolgung, Online-Sicherung und Konto sind deaktiviert. Ihre Daten bleiben auf dem Gerät.';
	@override String get statusSection => 'Cloud';
	@override String get statusActive => 'Online-Dienste aktiv';
	@override String get statusActiveDesc => 'Sicherung und Live-Verfolgung verfügbar.';
	@override String get statusLocal => 'Lokaler Modus (ohne Cloud)';
	@override String get statusLocalDesc => 'Es werden keine Daten online gesendet. Keine Cloud-Konfiguration vorhanden.';
}

// Path: onboarding
class _Translations$onboarding$de extends Translations$onboarding$fr {
	_Translations$onboarding$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Überspringen';
	@override String get next => 'Weiter';
	@override String get getStarted => 'Los geht\'s';
	@override String welcomeTitle({required Object appName}) => 'Willkommen bei ${appName}';
	@override String get welcomeSubtitle => 'Dein Offline-Wanderbegleiter: Karte, GPS-Navigation, Planung und Tourentagebuch.';
	@override String get languageTitle => 'Wähle deine Sprache';
	@override String get languageSubtitle => 'Du kannst sie jederzeit in den Einstellungen ändern.';
	@override String get downloadTitle => 'Lade deinen ersten Weg herunter';
	@override String get downloadSubtitle => 'Durchsuche den Katalog und lade einen Weg herunter, um ihn vollständig offline zu nutzen.';
	@override String get browseCatalog => 'Katalog durchsuchen';
}

// Path: monetization
class _Translations$monetization$de extends Translations$monetization$fr {
	_Translations$monetization$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get demoBanner => 'Demo-Modus — zum Freischalten tippen';
	@override String get paywallTitle => 'Diesen Trek freischalten';
	@override String get paywallBody => 'Im Gratis-Modus planen Sie Ihren Trek mit Werbung. Premium schaltet alles frei, werbefrei.';
	@override String get featureMap => 'Offline-Karte + GPS + Live-Tracking';
	@override String get featureJournal => 'Vollständiges Trek-Tagebuch';
	@override String get featureDiploma => 'Trek-Abschlussdiplom';
	@override String get featureFollowers => '2 kostenlose Follower';
	@override String get featureNoAds => 'Keine Werbung';
	@override String get buyCta => 'Diesen Trek freischalten';
	@override String buyCtaWithPrice({required Object price}) => 'Diesen Trek freischalten — ${price} €';
}

// Path: signalement
class _Translations$signalement$de extends Translations$signalement$fr {
	_Translations$signalement$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Melden';
	@override String get chooseType => 'Was möchten Sie melden?';
	@override late final _Translations$signalement$types$de types = _Translations$signalement$types$de._(_root);
	@override String get latencyBanner => 'Gespeichert. Für andere Wanderer sichtbar, sobald das Netzwerk synchronisiert.';
	@override String get confirm => 'Meldung bestätigen';
	@override String get noLocation => 'GPS-Position derzeit nicht verfügbar. Versuchen Sie es unter freiem Himmel erneut.';
	@override String get savedTitle => 'Meldung gespeichert';
	@override String get savedPendingSync => 'Sie wird geteilt, sobald das Netzwerk wieder da ist.';
	@override String pendingCount({required Object n}) => '${n} warten auf Synchronisierung';
	@override String get close => 'Schließen';
}

// Path: hebergement
class _Translations$hebergement$de extends Translations$hebergement$fr {
	_Translations$hebergement$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unterkünfte in der Nähe';
	@override String get facilitatorNote => 'StepWays verweist Sie an die Gastgeber. Die Buchung erfolgt auf deren Website: keine Zahlung in der App.';
	@override String detourAR({required Object km}) => 'Umweg hin und zurück: ${km} km';
	@override String get openSite => 'Website ansehen';
	@override String get cannotOpen => 'Dieser Link konnte auf diesem Gerät nicht geöffnet werden.';
	@override String get empty => 'Derzeit keine Unterkünfte in der Nähe gelistet.';
	@override late final _Translations$hebergement$types$de types = _Translations$hebergement$types$de._(_root);
}

// Path: training
class _Translations$training$de extends Translations$training$fr {
	_Translations$training$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Körperliche Vorbereitung';
	@override String get localNotice => 'Ihr Plan wird auf Ihrem Telefon berechnet und gespeichert. Erinnerungen sind lokale Benachrichtigungen, ohne Tracking.';
	@override String get reminderTitle => 'Heute Trainingseinheit';
	@override String get scheduleReminders => 'Erinnerungen planen';
	@override String remindersScheduled({required Object n}) => '${n} Erinnerung(en) geplant';
	@override String week({required Object n}) => 'Woche ${n}';
	@override String minutes({required Object n}) => '${n} Min';
	@override String progress({required Object done, required Object total}) => '${done}/${total} Einheiten erledigt';
	@override late final _Translations$training$types$de types = _Translations$training$types$de._(_root);
	@override late final _Translations$training$intensity$de intensity = _Translations$training$intensity$de._(_root);
}

// Path: eta
class _Translations$eta$de extends Translations$eta$fr {
	_Translations$eta$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Geschätzte Zeit';
	@override String get toNextWaypoint => 'Nächster Punkt';
	@override String get toStageEnd => 'Etappenende';
	@override String get confidenceHigh => 'Zuverlässige Schätzung';
	@override String get confidenceLow => 'Ungefähr (schwaches GPS)';
	@override String durationHm({required Object h, required Object m}) => '${h} Std ${m} Min';
	@override String durationM({required Object m}) => '${m} Min';
}

// Path: leaderboard
class _Translations$leaderboard$de extends Translations$leaderboard$fr {
	_Translations$leaderboard$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'König der Etappe';
	@override String get unavailable => 'Rangliste derzeit nicht verfügbar.';
	@override String get empty => 'Noch keine Rangliste für dieses Segment. Sei der Erste!';
	@override String get pseudonymNotice => 'Rangliste nach Gruppe, mit Pseudonymen. Es werden keine direkten personenbezogenen Daten angezeigt.';
	@override String trancheLabel({required Object tranche}) => 'Gruppe: ${tranche}';
	@override String get notEnoughParticipants => 'Nicht genug Teilnehmer, um diese Rangliste zu veröffentlichen.';
	@override String entrySemantics({required Object rank, required Object pseudonym, required Object time}) => 'Rang ${rank}, ${pseudonym}, Zeit ${time}';
}

// Path: social
class _Translations$social$de extends Translations$social$fr {
	_Translations$social$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get feedTitle => 'Aktivitätsverlauf';
	@override String get empty => 'Noch keine Aktivität.';
	@override String get kudos => 'Anfeuern';
	@override String kudosCount({required Object n}) => '${n} Kudos';
	@override String get report => 'Melden';
	@override String get reportTitle => 'Diesen Beitrag melden';
	@override String get reportReasonLabel => 'Grund der Meldung';
	@override String get reasonSpam => 'Spam oder Werbung';
	@override String get reasonAbuse => 'Missbräuchlicher oder hasserfüllter Inhalt';
	@override String get reasonOther => 'Andere';
	@override String get reportSend => 'Meldung senden';
	@override String get reportSent => 'Meldung gesendet. Unser Team prüft sie.';
	@override String get syncPending => 'Wartet auf Synchronisierung';
	@override String get synced => 'Synchronisiert';
	@override String get activitySegment => 'hat ein Segment absolviert';
	@override String get activityBadge => 'hat ein Abzeichen erhalten';
	@override String get activityDefi => 'hat bei einer Challenge Fortschritte gemacht';
}

// Path: gamification
class _Translations$gamification$de extends Translations$gamification$fr {
	_Translations$gamification$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get galleryTitle => 'Meine Abzeichen';
	@override String get obtained => 'Erhalten';
	@override String get locked => 'Gesperrt';
	@override String get tierDebutant => 'Anfänger';
	@override String get tierExpert => 'Experte';
	@override late final _Translations$gamification$badge$de badge = _Translations$gamification$badge$de._(_root);
	@override late final _Translations$gamification$defi$de defi = _Translations$gamification$defi$de._(_root);
}

// Path: shareVisibility
class _Translations$shareVisibility$de extends Translations$shareVisibility$fr {
	_Translations$shareVisibility$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Teilen und Sichtbarkeit';
	@override String get intro => 'Standardmäßig wird nichts geteilt. Aktiviere unten zweckweise, was du sichtbar machen möchtest.';
	@override String get consentLink => 'Meine Einwilligung verwalten (Datenschutz)';
	@override String get stageResults => 'Meine Etappenergebnisse teilen';
	@override String get stageResultsDesc => 'Eine pseudonyme Karte (keine direkten personenbezogenen Daten).';
	@override String get leaderboard => 'In Ranglisten erscheinen';
	@override String get leaderboardDesc => 'Rangliste nach Gruppe, mit einem Pseudonym.';
	@override String get activityFeed => 'Im Aktivitätsverlauf posten';
	@override String get activityFeedDesc => 'Deine Aktivitäten erscheinen im Verlauf, unter einem Pseudonym.';
	@override String get shareTitle => 'Diese Etappe teilen';
	@override String get shareButton => 'Teilen';
	@override String get privateNotice => 'Teilen ist aus. Aktiviere es unter Teilen und Sichtbarkeit.';
	@override String get shared => 'Karte bereit zum Teilen.';
}

// Path: waypoints
class _Translations$waypoints$de extends Translations$waypoints$fr {
	_Translations$waypoints$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$waypoints$types$de types = _Translations$waypoints$types$de._(_root);
	@override late final _Translations$waypoints$filters$de filters = _Translations$waypoints$filters$de._(_root);
	@override late final _Translations$waypoints$detail$de detail = _Translations$waypoints$detail$de._(_root);
	@override late final _Translations$waypoints$freshness$de freshness = _Translations$waypoints$freshness$de._(_root);
	@override late final _Translations$waypoints$contribution$de contribution = _Translations$waypoints$contribution$de._(_root);
}

// Path: packs
class _Translations$packs$de extends Translations$packs$fr {
	_Translations$packs$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wegpakete';
	@override String get subtitle => 'Lade ein Paket herunter, um 100% offline zu wandern.';
	@override String get alaCarteNote => 'A la carte: Kaufe nur das Paket, das du brauchst, kein Abo.';
	@override String size({required Object mo}) => '${mo} MB';
	@override late final _Translations$packs$states$de states = _Translations$packs$states$de._(_root);
	@override late final _Translations$packs$actions$de actions = _Translations$packs$actions$de._(_root);
	@override late final _Translations$packs$progress$de progress = _Translations$packs$progress$de._(_root);
	@override late final _Translations$packs$delete$de delete = _Translations$packs$delete$de._(_root);
	@override String get empty => 'Kein Paket für diesen Weg verfügbar.';
	@override late final _Translations$packs$a11y$de a11y = _Translations$packs$a11y$de._(_root);
	@override late final _Translations$packs$types$de types = _Translations$packs$types$de._(_root);
}

// Path: guides
class _Translations$guides$de extends Translations$guides$fr {
	_Translations$guides$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ortsführer';
	@override String get subtitle => 'Praktische Infos zu Städten und Dörfern, offline verfügbar.';
	@override String sectionsCount({required Object n}) => '${n} praktische Rubriken';
	@override String get empty => 'Kein Führer für diesen Weg verfügbar.';
	@override String get noItems => 'Noch keine Informationen in diesem Abschnitt.';
	@override String get facilitatorNote => 'StepWays verweist Sie an Anbieter. Buchung und Zahlung erfolgen auf deren Website: nichts in der App.';
	@override String get openSite => 'Website öffnen';
	@override String get cannotOpen => 'Dieser Link kann auf diesem Gerät nicht geöffnet werden.';
	@override late final _Translations$guides$categories$de categories = _Translations$guides$categories$de._(_root);
	@override late final _Translations$guides$intro$de intro = _Translations$guides$intro$de._(_root);
	@override late final _Translations$guides$a11y$de a11y = _Translations$guides$a11y$de._(_root);
}

// Path: trailSelection
class _Translations$trailSelection$de extends Translations$trailSelection$fr {
	_Translations$trailSelection$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weg wechseln';
	@override String get subtitle => 'Waehle den Weg zum Erkunden. Die ganze App (Karte, Etappen, Sehenswuerdigkeiten, Pakete, Reisefuehrer) folgt deiner Auswahl.';
	@override String get current => 'Aktiver Weg';
	@override String get select => 'Diesen Weg waehlen';
	@override String get selected => 'Ausgewaehlter Weg';
	@override String stagesDistance({required Object stages, required Object km}) => '${stages} Etappen - ${km} km';
	@override late final _Translations$trailSelection$a11y$de a11y = _Translations$trailSelection$a11y$de._(_root);
}

// Path: consent
class _Translations$consent$de extends Translations$consent$fr {
	_Translations$consent$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get onboardingTitle => 'Ihre Privatsphäre, Ihre Wahl';
	@override String get onboardingIntro => 'Standardmäßig ist nichts aktiviert. Wählen Sie Zweck für Zweck, was Sie erlauben. Sie können alles jederzeit in den Einstellungen ändern.';
	@override String get settingsTitle => 'Datenschutz und Einwilligung';
	@override String get settingsIntro => 'Verwalten Sie hier jede Berechtigung. Sie können eine Einwilligung jederzeit widerrufen, ohne Auswirkung auf den Rest.';
	@override String get settingsEntry => 'Datenschutz und Einwilligung';
	@override String get settingsEntryDesc => 'Meine Berechtigungen verwalten (Standort, Teilen, Gesundheit)';
	@override late final _Translations$consent$purposes$de purposes = _Translations$consent$purposes$de._(_root);
	@override String get healthBadge => 'Sensible Daten';
	@override String get healthWarning => 'Die Herzfrequenz ist ein Gesundheitsdatum (DSGVO Artikel 9). Diese Einwilligung wird separat erfragt und niemals mit den anderen gebündelt. Ihre Gesundheitsdaten werden nicht an unsere Server gesendet.';
	@override String get granted => 'Erlaubt';
	@override String get denied => 'Nicht erlaubt';
	@override String get grant => 'Erlauben';
	@override String get revoke => 'Widerrufen';
	@override String decidedOn({required Object date}) => 'Gewählt am ${date}';
	@override String get notDecided => 'Wartet auf Ihre Wahl';
	@override String get acceptSelected => 'Meine Auswahl bestätigen';
	@override String get declineAll => 'Alles ablehnen';
	@override String get continueLabel => 'Weiter';
	@override String get privacyPolicyLink => 'Datenschutzerklärung lesen';
	@override String get reviewNeeded => 'Unsere Richtlinie hat sich geändert: Bitte überprüfen Sie Ihre Auswahl.';
	@override late final _Translations$consent$a11y$de a11y = _Translations$consent$a11y$de._(_root);
}

// Path: moderation
class _Translations$moderation$de extends Translations$moderation$fr {
	_Translations$moderation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get reportTitle => 'Diesen Inhalt melden';
	@override String get reportIntro => 'Helfen Sie uns, die Community gesund zu halten. Geben Sie an, warum dieser Inhalt rechtswidrig erscheint. Ihre Meldung wird von einem Moderator geprüft.';
	@override String get reasonLabel => 'Grund der Meldung';
	@override late final _Translations$moderation$reasons$de reasons = _Translations$moderation$reasons$de._(_root);
	@override String get detailsLabel => 'Details hinzufügen (optional)';
	@override String get detailsHint => 'Fügen Sie einen Kommentar hinzu, um dem Moderator zu helfen.';
	@override String get contactLabel => 'Ihre E-Mail-Adresse';
	@override String get contactHint => 'Um Sie über die Bearbeitung zu informieren (Artikel 16).';
	@override String get goodFaithLabel => 'Ich erkläre nach bestem Wissen, dass diese Angaben zutreffen.';
	@override String get submit => 'Meldung senden';
	@override String get submitting => 'Wird gesendet…';
	@override String get sent => 'Meldung gesendet. Danke, ein Moderator wird sie prüfen.';
	@override String get errorRequired => 'Bitte Grund, E-Mail und die Erklärung in gutem Glauben ausfüllen.';
	@override String get errorGeneric => 'Die Meldung konnte nicht gesendet werden. Bitte erneut versuchen.';
	@override String get cancel => 'Abbrechen';
	@override String get reasonsTitle => 'Warum wurde dieser Inhalt eingeschränkt?';
	@override String get reasonsIntro => 'Gemäß Artikel 17 finden Sie hier den Grund für die Moderationsentscheidung zu Ihrem Inhalt.';
	@override String get decisionLabel => 'Entscheidung';
	@override late final _Translations$moderation$decisions$de decisions = _Translations$moderation$decisions$de._(_root);
	@override String get noStatement => 'Auf Ihre Inhalte wurde keine Einschränkung angewendet.';
	@override String get complaintAction => 'Diese Entscheidung anfechten';
	@override String get complaintTitle => 'Eine Entscheidung anfechten';
	@override String get complaintIntro => 'Sie können eine Moderationsentscheidung anfechten. Erklären Sie, warum die Entscheidung Ihrer Meinung nach ungerechtfertigt ist (Artikel 20).';
	@override String get complaintExposeLabel => 'Ihre Anfechtung';
	@override String get complaintExposeHint => 'Beschreiben Sie die Gründe für Ihre Anfechtung.';
	@override String get complaintSubmit => 'Anfechtung senden';
	@override String get complaintSent => 'Anfechtung erfasst. Sie wird geprüft.';
	@override String get complaintEmpty => 'Bitte erklären Sie Ihre Anfechtung.';
	@override late final _Translations$moderation$a11y$de a11y = _Translations$moderation$a11y$de._(_root);
}

// Path: hub.trekCard
class _Translations$hub$trekCard$de extends Translations$hub$trekCard$fr {
	_Translations$hub$trekCard$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get activeTitle => 'Trek läuft';
	@override String get distanceCovered => 'Zurückgelegte Strecke';
	@override String get elevationGain => 'Anstieg heute';
	@override String get duration => 'Gehzeit';
	@override String progressLabel({required Object percent}) => '${percent} % des Weges';
	@override String get resume => 'Navigation fortsetzen';
	@override String get noTrekTitle => 'Bereit loszugehen?';
	@override String get noTrekBody => 'Planen Sie Ihre Route und starten Sie Ihren Trek, wann immer Sie bereit sind.';
	@override String get plan => 'Meinen Trek planen';
}

// Path: hub.weather
class _Translations$hub$weather$de extends Translations$hub$weather$fr {
	_Translations$hub$weather$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wetter heute';
	@override String get stub => 'Das Wetter Ihrer Etappe kommt bald.';
	@override String get unavailable => 'Wetter derzeit nicht verfügbar.';
}

// Path: hub.sections
class _Translations$hub$sections$de extends Translations$hub$sections$fr {
	_Translations$hub$sections$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get prepare => 'Vorbereiten';
	@override String get hike => 'Wandern';
	@override String get info => 'Informationen';
	@override String get after => 'Nach dem Trek';
}

// Path: hub.cards
class _Translations$hub$cards$de extends Translations$hub$cards$fr {
	_Translations$hub$cards$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get feasibility => 'Machbarkeit';
	@override String get feasibilitySub => 'Bewerten Sie Ihr Niveau';
	@override String get itinerary => 'Route';
	@override String get itinerarySub => 'Der Wegverlauf';
	@override String get programme => 'Programm';
	@override String get programmeSub => 'Etappen aufteilen';
	@override String get checklist => 'Ausrüstung & Rucksack';
	@override String get checklistSub => 'Packen Sie Ihren Rucksack';
	@override String get training => 'Körperliche Vorbereitung';
	@override String get trainingSub => 'Ihr Trainingsprogramm';
	@override String get offline => 'Offline';
	@override String get offlineSub => 'Wege herunterladen';
	@override String get group => 'Meine Gruppe';
	@override String get groupSub => 'Ihre Begleiter verfolgen';
	@override String get navigation => 'Navigation';
	@override String get navigationSub => 'Karte und GPS-Tracking';
	@override String get journal => 'Tagebuch';
	@override String get journalSub => 'Ihre Notizen und Erinnerungen';
	@override String get accommodations => 'Unterkünfte';
	@override String get accommodationsSub => 'Übernachten in der Nähe';
	@override String get tips => 'Ratgeber';
	@override String get tipsSub => 'Unsere Trekking-Tipps';
	@override String get recap => 'Zusammenfassung';
	@override String get recapSub => 'Ihr Abenteuer in Kürze';
	@override String get diploma => 'Diplom';
	@override String get diplomaSub => 'Ihre Abschlussurkunde';
}

// Path: hub.fab
class _Translations$hub$fab$de extends Translations$hub$fab$fr {
	_Translations$hub$fab$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get feedback => 'Feedback geben';
	@override String get sos => 'SOS';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$de extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Leicht';
	@override String get moderate => 'Mittel';
	@override String get hard => 'Schwer';
	@override String get expert => 'Experte';
}

// Path: accommodation.types
class _Translations$accommodation$types$de extends Translations$accommodation$types$fr {
	_Translations$accommodation$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Berghütte';
	@override String get bergerie => 'Schäferhütte';
	@override String get gite => 'Herberge';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campingplatz';
	@override String get bivouac => 'Biwak';
}

// Path: checklist.categories
class _Translations$checklist$categories$de extends Translations$checklist$categories$fr {
	_Translations$checklist$categories$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$checklist$items$de extends Translations$checklist$items$fr {
	_Translations$checklist$items$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$feasibility$levels$de extends Translations$feasibility$levels$fr {
	_Translations$feasibility$levels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Not recommended';
	@override String get caution => 'Preparation needed';
	@override String get good => 'Feasible';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$de extends Translations$feasibility$categories$fr {
	_Translations$feasibility$categories$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$feasibility$questions$de extends Translations$feasibility$questions$fr {
	_Translations$feasibility$questions$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$feasibility$answers$de extends Translations$feasibility$answers$fr {
	_Translations$feasibility$answers$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
class _Translations$feasibility$recommendations$de extends Translations$feasibility$recommendations$fr {
	_Translations$feasibility$recommendations$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$de danger = _Translations$feasibility$recommendations$danger$de._(_root);
	@override late final _Translations$feasibility$recommendations$caution$de caution = _Translations$feasibility$recommendations$caution$de._(_root);
	@override late final _Translations$feasibility$recommendations$good$de good = _Translations$feasibility$recommendations$good$de._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$de excellent = _Translations$feasibility$recommendations$excellent$de._(_root);
}

// Path: catalog.a11y
class _Translations$catalog$a11y$de extends Translations$catalog$a11y$fr {
	_Translations$catalog$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String enterButton({required Object nom}) => 'Weg ${nom} öffnen';
}

// Path: signalement.types
class _Translations$signalement$types$de extends Translations$signalement$types$fr {
	_Translations$signalement$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get obstacle => 'Hindernis auf dem Weg';
	@override String get eauASec => 'Trockene Wasserstelle';
	@override String get danger => 'Gefahr';
}

// Path: hebergement.types
class _Translations$hebergement$types$de extends Translations$hebergement$types$fr {
	_Translations$hebergement$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Berghütte';
	@override String get gite => 'Gästehaus';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campingplatz';
	@override String get chambreHote => 'Pension';
}

// Path: training.types
class _Translations$training$types$de extends Translations$training$types$fr {
	_Translations$training$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get marche => 'Gehen';
	@override String get cardio => 'Cardio';
	@override String get renforcement => 'Kraft';
}

// Path: training.intensity
class _Translations$training$intensity$de extends Translations$training$intensity$fr {
	_Translations$training$intensity$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get faible => 'Niedrig';
	@override String get moderee => 'Mittel';
	@override String get elevee => 'Hoch';
}

// Path: gamification.badge
class _Translations$gamification$badge$de extends Translations$gamification$badge$fr {
	_Translations$gamification$badge$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$gamification$badge$firstStage$de firstStage = _Translations$gamification$badge$firstStage$de._(_root);
	@override late final _Translations$gamification$badge$firstTrek$de firstTrek = _Translations$gamification$badge$firstTrek$de._(_root);
	@override late final _Translations$gamification$badge$firstSegment$de firstSegment = _Translations$gamification$badge$firstSegment$de._(_root);
	@override late final _Translations$gamification$badge$elevation5000$de elevation5000 = _Translations$gamification$badge$elevation5000$de._(_root);
	@override late final _Translations$gamification$badge$tenStages$de tenStages = _Translations$gamification$badge$tenStages$de._(_root);
	@override late final _Translations$gamification$badge$challenger$de challenger = _Translations$gamification$badge$challenger$de._(_root);
}

// Path: gamification.defi
class _Translations$gamification$defi$de extends Translations$gamification$defi$fr {
	_Translations$gamification$defi$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Challenges';
	@override String get inProgress => 'Laufend';
	@override String progressLabel({required Object current, required Object target}) => 'Fortschritt: ${current} / ${target}';
	@override String get rankingTitle => 'Challenge-Rangliste';
	@override String get pseudonymNotice => 'Rangliste nach Gruppe, mit Pseudonymen. Es werden keine direkten personenbezogenen Daten angezeigt.';
	@override String get notEnoughParticipants => 'Nicht genug Teilnehmer, um diese Rangliste zu veröffentlichen.';
	@override String get noDefi => 'Derzeit keine laufende Challenge.';
}

// Path: waypoints.types
class _Translations$waypoints$types$de extends Translations$waypoints$types$fr {
	_Translations$waypoints$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get eau => 'Wasser';
	@override String get ravitaillement => 'Nachschub';
	@override String get danger => 'Gefahr';
	@override String get camp => 'Zeltplatz';
	@override String get connectivite => 'Konnektivitat';
	@override String get jonction => 'Kreuzung';
}

// Path: waypoints.filters
class _Translations$waypoints$filters$de extends Translations$waypoints$filters$fr {
	_Translations$waypoints$filters$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wegpunkte filtern';
	@override String get showAll => 'Alle anzeigen';
	@override String get hideAll => 'Alle ausblenden';
	@override String get recentConditionOnly => 'Nur aktueller Zustand';
}

// Path: waypoints.detail
class _Translations$waypoints$detail$de extends Translations$waypoints$detail$fr {
	_Translations$waypoints$detail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get conditionsTitle => 'Gelandezustand';
	@override String get noComments => 'Noch kein Zustand gemeldet.';
	@override String get commentsError => 'Zustand nicht verfugbar.';
	@override String get report => 'Melden';
	@override String get reportAck => 'Meldung gespeichert. Sie wird nach der Synchronisierung gepruft.';
	@override String get pendingSync => 'Warten auf Synchronisierung';
}

// Path: waypoints.freshness
class _Translations$waypoints$freshness$de extends Translations$waypoints$freshness$fr {
	_Translations$waypoints$freshness$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get justNow => 'gerade aktualisiert';
	@override String minutes({required Object n}) => 'vor ${n} Min aktualisiert';
	@override String hours({required Object n}) => 'vor ${n} Std aktualisiert';
	@override String days({required Object n}) => 'vor ${n} T aktualisiert';
}

// Path: waypoints.contribution
class _Translations$waypoints$contribution$de extends Translations$waypoints$contribution$fr {
	_Translations$waypoints$contribution$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titleWaypoint => 'Wegpunkt hinzufugen';
	@override String get titleComment => 'Zustand melden';
	@override String get chooseType => 'Wegpunkttyp';
	@override String get titleField => 'Titel des Wegpunkts';
	@override String get conditionPrompt => 'Beschreiben Sie den beobachteten Zustand';
	@override String get commentField => 'Ihre Beobachtung';
	@override String get conditionField => 'Zustand (optional)';
	@override String get conditionHelper => 'z. B. Wasser versiegt, Wasser fliesst, rutschige Stelle';
	@override String get latencyBanner => 'Wird bei der nachsten Synchronisierung veroffentlicht.';
	@override String get submit => 'Speichern';
	@override String get savedTitle => 'Beitrag gespeichert';
	@override String get savedPendingSync => 'Er wird veroffentlicht, sobald das Netz wieder da ist.';
	@override String pendingCount({required Object n}) => '${n} warten auf Synchronisierung';
	@override String get close => 'Schliessen';
	@override String get emptyTitle => 'Bitte einen Titel fur den Wegpunkt angeben.';
	@override String get emptyComment => 'Bitte Ihre Beobachtung eingeben.';
	@override String get noLocation => 'GPS-Position nicht verfugbar. Unter freiem Himmel erneut versuchen.';
	@override String get error => 'Speichern derzeit nicht moglich.';
}

// Path: packs.states
class _Translations$packs$states$de extends Translations$packs$states$fr {
	_Translations$packs$states$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get notDownloaded => 'Nicht heruntergeladen';
	@override String get downloaded => 'Heruntergeladen';
	@override String get updateAvailable => 'Update verfügbar';
}

// Path: packs.actions
class _Translations$packs$actions$de extends Translations$packs$actions$fr {
	_Translations$packs$actions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get download => 'Herunterladen';
	@override String get update => 'Aktualisieren';
	@override String get delete => 'Löschen';
	@override String get retry => 'Erneut versuchen';
	@override String get buy => 'Dieses Paket kaufen';
	@override String buyWithPrice({required Object price}) => 'Dieses Paket kaufen — ${price}';
}

// Path: packs.progress
class _Translations$packs$progress$de extends Translations$packs$progress$fr {
	_Translations$packs$progress$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String downloading({required Object done, required Object total}) => 'Wird heruntergeladen… ${done}/${total}';
	@override String get verifying => 'Integrität wird geprüft…';
	@override String get completed => 'Paket offline bereit';
	@override String get error => 'Download fehlgeschlagen';
}

// Path: packs.delete
class _Translations$packs$delete$de extends Translations$packs$delete$fr {
	_Translations$packs$delete$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => 'Dieses Paket löschen?';
	@override String get confirmBody => 'Das Paket wird vom Gerät entfernt, um Speicher freizugeben. Du kannst es später erneut herunterladen.';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'Löschen';
	@override String get freed => 'Speicher freigegeben.';
}

// Path: packs.a11y
class _Translations$packs$a11y$de extends Translations$packs$a11y$fr {
	_Translations$packs$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String packCard({required Object nom, required Object state}) => 'Paket ${nom}, ${state}';
	@override String downloadButton({required Object nom}) => 'Paket ${nom} herunterladen';
	@override String deleteButton({required Object nom}) => 'Paket ${nom} löschen';
}

// Path: packs.types
class _Translations$packs$types$de extends Translations$packs$types$fr {
	_Translations$packs$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$packs$types$nord$de nord = _Translations$packs$types$nord$de._(_root);
	@override late final _Translations$packs$types$sud$de sud = _Translations$packs$types$sud$de._(_root);
	@override late final _Translations$packs$types$complet$de complet = _Translations$packs$types$complet$de._(_root);
	@override late final _Translations$packs$types$mam$de mam = _Translations$packs$types$mam$de._(_root);
}

// Path: guides.categories
class _Translations$guides$categories$de extends Translations$guides$categories$fr {
	_Translations$guides$categories$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Verpflegung';
	@override String get hebergement => 'Unterkunft';
	@override String get transport => 'Transport';
	@override String get services => 'Dienstleistungen';
	@override String get eau => 'Wasser';
	@override String get sante => 'Gesundheit';
}

// Path: guides.intro
class _Translations$guides$intro$de extends Translations$guides$intro$fr {
	_Translations$guides$intro$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Wo man Vorräte auffüllt.';
	@override String get hebergement => 'Wo man an der Etappe schläft.';
	@override String get transport => 'Busse, Shuttles und Verbindungen.';
	@override String get services => 'Post, Bank, Wäscherei und mehr.';
	@override String get eau => 'Trinkwasserstellen.';
	@override String get sante => 'Apotheke und Versorgung in der Nähe.';
}

// Path: guides.a11y
class _Translations$guides$a11y$de extends Translations$guides$a11y$fr {
	_Translations$guides$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String guideCard({required Object lieu}) => 'Führer für ${lieu}';
	@override String section({required Object titre}) => 'Abschnitt ${titre}';
	@override String openSiteButton({required Object nom}) => 'Website von ${nom} öffnen';
}

// Path: trailSelection.a11y
class _Translations$trailSelection$a11y$de extends Translations$trailSelection$a11y$fr {
	_Translations$trailSelection$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String trailCard({required Object nom, required Object region}) => 'Weg ${nom}, ${region}';
	@override String get currentBadge => 'Aktuell aktiver Weg';
	@override String selectButton({required Object nom}) => 'Weg ${nom} aktivieren';
}

// Path: consent.purposes
class _Translations$consent$purposes$de extends Translations$consent$purposes$fr {
	_Translations$consent$purposes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get locationNavigation => 'Persönliche Navigation';
	@override String get locationNavigationDesc => 'Ihren Standort für die Karte und die Etappenverfolgung nutzen. Bleibt auf Ihrem Gerät.';
	@override String get socialSharing => 'Soziales Teilen';
	@override String get socialSharingDesc => 'Unter einem Pseudonym in Ranglisten und im Community-Feed erscheinen.';
	@override String get publicReporting => 'Öffentliche Meldungen';
	@override String get publicReportingDesc => 'Meldungen (Wasser, Gefahr, Bedingungen) veröffentlichen, die für andere Wanderer sichtbar sind.';
	@override String get healthData => 'Gesundheitsdaten';
	@override String get healthDataDesc => 'Ihre Herzfrequenz (Brustgurt oder Gesundheits-App) lesen, um Ihre Anstrengung genauer zu erfassen.';
}

// Path: consent.a11y
class _Translations$consent$a11y$de extends Translations$consent$a11y$fr {
	_Translations$consent$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String purposeToggle({required Object purpose, required Object state}) => '${purpose}, aktuell ${state}';
	@override String get healthSection => 'Bereich Gesundheitsdaten, verstärkte Einwilligung';
	@override String get policyButton => 'Datenschutzerklärung öffnen';
}

// Path: moderation.reasons
class _Translations$moderation$reasons$de extends Translations$moderation$reasons$fr {
	_Translations$moderation$reasons$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get illegal => 'Illegaler Inhalt';
	@override String get harassment => 'Belästigung oder Hass';
	@override String get spam => 'Spam oder Werbung';
	@override String get dangerous => 'Gefährliche oder irreführende Information';
	@override String get other => 'Sonstiges';
}

// Path: moderation.decisions
class _Translations$moderation$decisions$de extends Translations$moderation$decisions$fr {
	_Translations$moderation$decisions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get keep => 'Inhalt beibehalten';
	@override String get restrict => 'Inhalt eingeschränkt';
	@override String get remove => 'Inhalt entfernt';
}

// Path: moderation.a11y
class _Translations$moderation$a11y$de extends Translations$moderation$a11y$fr {
	_Translations$moderation$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get reportForm => 'Formular zur Inhaltsmeldung';
	@override String get reasonSelector => 'Auswahl des Meldegrunds';
	@override String goodFaithToggle({required Object state}) => 'Erklärung in gutem Glauben, ${state}';
	@override String get submitReport => 'Meldung senden';
	@override String get statementCard => 'Begründung der Moderationsentscheidung';
	@override String get complaintForm => 'Formular zur Anfechtung der Entscheidung';
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$de extends Translations$feasibility$recommendations$danger$fr {
	_Translations$feasibility$recommendations$danger$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unzureichende Vorbereitung';
	@override String get summary => 'Ihr Profil zeigt erhebliche Lücken. Wir raten vom Start ab.';
	@override late final _Translations$feasibility$recommendations$danger$tips$de tips = _Translations$feasibility$recommendations$danger$tips$de._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$de extends Translations$feasibility$recommendations$caution$fr {
	_Translations$feasibility$recommendations$caution$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vorbereitung verstärken';
	@override String get summary => 'Sie haben Grundlagen, aber einige Bereiche brauchen Aufmerksamkeit.';
	@override late final _Translations$feasibility$recommendations$caution$tips$de tips = _Translations$feasibility$recommendations$caution$tips$de._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$de extends Translations$feasibility$recommendations$good$fr {
	_Translations$feasibility$recommendations$good$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gute Vorbereitung';
	@override String get summary => 'Ihr Profil ist solide. Einige Anpassungen und Sie sind bereit.';
	@override late final _Translations$feasibility$recommendations$good$tips$de tips = _Translations$feasibility$recommendations$good$tips$de._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$de extends Translations$feasibility$recommendations$excellent$fr {
	_Translations$feasibility$recommendations$excellent$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Optimale Vorbereitung';
	@override String get summary => 'Sie sind perfekt vorbereitet. Genießen Sie die Wanderung!';
	@override late final _Translations$feasibility$recommendations$excellent$tips$de tips = _Translations$feasibility$recommendations$excellent$tips$de._(_root);
}

// Path: gamification.badge.firstStage
class _Translations$gamification$badge$firstStage$de extends Translations$gamification$badge$firstStage$fr {
	_Translations$gamification$badge$firstStage$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Erste Etappe';
	@override String get description => 'Du hast deine erste Etappe abgeschlossen.';
}

// Path: gamification.badge.firstTrek
class _Translations$gamification$badge$firstTrek$de extends Translations$gamification$badge$firstTrek$fr {
	_Translations$gamification$badge$firstTrek$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Erster Trek';
	@override String get description => 'Du hast deinen ersten vollständigen Trek beendet.';
}

// Path: gamification.badge.firstSegment
class _Translations$gamification$badge$firstSegment$de extends Translations$gamification$badge$firstSegment$fr {
	_Translations$gamification$badge$firstSegment$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Erstes Segment';
	@override String get description => 'Du hast dein erstes Segment absolviert.';
}

// Path: gamification.badge.elevation5000
class _Translations$gamification$badge$elevation5000$de extends Translations$gamification$badge$elevation5000$fr {
	_Translations$gamification$badge$elevation5000$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => '5000 m Höhenmeter';
	@override String get description => 'Du hast 5000 m Höhenmeter gesammelt.';
}

// Path: gamification.badge.tenStages
class _Translations$gamification$badge$tenStages$de extends Translations$gamification$badge$tenStages$fr {
	_Translations$gamification$badge$tenStages$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => '10 Etappen';
	@override String get description => 'Du hast 10 Etappen abgeschlossen.';
}

// Path: gamification.badge.challenger
class _Translations$gamification$badge$challenger$de extends Translations$gamification$badge$challenger$fr {
	_Translations$gamification$badge$challenger$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Herausforderer';
	@override String get description => 'Du hast deine erste saisonale Challenge gemeistert.';
}

// Path: packs.types.nord
class _Translations$packs$types$nord$de extends Translations$packs$types$nord$fr {
	_Translations$packs$types$nord$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Nord';
	@override String get description => 'Die nördliche Hälfte des Wegs, offline.';
}

// Path: packs.types.sud
class _Translations$packs$types$sud$de extends Translations$packs$types$sud$fr {
	_Translations$packs$types$sud$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Süd';
	@override String get description => 'Die südliche Hälfte des Wegs, offline.';
}

// Path: packs.types.complet
class _Translations$packs$types$complet$de extends Translations$packs$types$complet$fr {
	_Translations$packs$types$complet$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Komplett';
	@override String get description => 'Der ganze Weg, offline.';
}

// Path: packs.types.mam
class _Translations$packs$types$mam$de extends Translations$packs$types$mam$fr {
	_Translations$packs$types$mam$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare';
	@override String get description => 'Der Mare-a-Mare-Weg, offline.';
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$de extends Translations$feasibility$recommendations$danger$tips$fr {
	_Translations$feasibility$recommendations$danger$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Beginnen Sie mit kurzen Wanderungen';
	@override String get tip2 => 'Konsultieren Sie einen Arzt vor längerer Anstrengung';
	@override String get tip3 => 'Investieren Sie in geeignete Ausrüstung';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$de extends Translations$feasibility$recommendations$caution$tips$fr {
	_Translations$feasibility$recommendations$caution$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Verstärken Sie Ihr Training 6 bis 8 Wochen vorher';
	@override String get tip2 => 'Überprüfen und ergänzen Sie Ihre Ausrüstung';
	@override String get tip3 => 'Planen Sie Etappen, die Ihrem Niveau entsprechen';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$de extends Translations$feasibility$recommendations$good$tips$fr {
	_Translations$feasibility$recommendations$good$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Halten Sie Ihr Trainingstempo aufrecht';
	@override String get tip2 => 'Planen Sie Puffer in Ihrem Zeitplan ein';
	@override String get tip3 => 'Überprüfen Sie regelmäßig das Wetter';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$de extends Translations$feasibility$recommendations$excellent$tips$fr {
	_Translations$feasibility$recommendations$excellent$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

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
			'a11y.back' => 'Zuruck',
			'a11y.zoomIn' => 'Vergrossern',
			'a11y.zoomOut' => 'Verkleinern',
			'a11y.centerOnMe' => 'Auf meine Position zentrieren',
			'a11y.mapRegion' => 'Wanderkarte',
			'a11y.userPosition' => 'Ihre Position',
			'a11y.stageMarker' => ({required Object number}) => 'Etappe ${number}',
			'a11y.poiMarker' => ({required Object name}) => 'Interessanter Punkt: ${name}',
			'a11y.markerCluster' => ({required Object count}) => '${count} gruppierte Punkte',
			'a11y.trailCard' => ({required Object name}) => 'Weg ${name}',
			'a11y.startTracking' => 'Aufzeichnung starten',
			'a11y.pauseTracking' => 'Aufzeichnung pausieren',
			'a11y.resumeTracking' => 'Aufzeichnung fortsetzen',
			'a11y.stopTracking' => 'Aufzeichnung beenden',
			'nav.accueil' => 'Start',
			'nav.map' => 'Karte',
			'nav.stages' => 'Etappen',
			'nav.planning' => 'Planung',
			'nav.journal' => 'Tagebuch',
			'nav.more' => 'Mehr',
			'nav.checklist' => 'Ausrüstungsliste',
			'nav.feasibility' => 'Machbarkeit',
			'nav.tips' => 'Trek-Tipps',
			'nav.emergency' => 'Notfallkontakte',
			'nav.catalog' => 'Wegekatalog',
			'nav.profile' => 'Profil',
			'nav.settings' => 'Einstellungen',
			'nav.trailSelection' => 'Weg wechseln',
			'branding.tagline' => 'Ihr Trekking-Begleiter',
			'branding.subline' => 'Vorbereiten, wandern, teilen',
			'hub.greeting' => ({required Object name}) => 'Hallo, ${name}!',
			'hub.greetingFallback' => 'Wanderer',
			'hub.infoTooltip' => 'Über diesen Weg',
			'hub.profileTooltip' => 'Mein Profil',
			'hub.infoSheetBody' => 'Dieser Weg begleitet Sie bei jedem Schritt: Planen Sie Ihre Route, packen Sie Ihren Rucksack und starten Sie dann mit der GPS-Navigation. Jede Funktion ist von diesem Startbildschirm aus erreichbar.',
			'hub.trekCard.activeTitle' => 'Trek läuft',
			'hub.trekCard.distanceCovered' => 'Zurückgelegte Strecke',
			'hub.trekCard.elevationGain' => 'Anstieg heute',
			'hub.trekCard.duration' => 'Gehzeit',
			'hub.trekCard.progressLabel' => ({required Object percent}) => '${percent} % des Weges',
			'hub.trekCard.resume' => 'Navigation fortsetzen',
			'hub.trekCard.noTrekTitle' => 'Bereit loszugehen?',
			'hub.trekCard.noTrekBody' => 'Planen Sie Ihre Route und starten Sie Ihren Trek, wann immer Sie bereit sind.',
			'hub.trekCard.plan' => 'Meinen Trek planen',
			'hub.weather.title' => 'Wetter heute',
			'hub.weather.stub' => 'Das Wetter Ihrer Etappe kommt bald.',
			'hub.weather.unavailable' => 'Wetter derzeit nicht verfügbar.',
			'hub.startCta' => 'Trek starten',
			'hub.sections.prepare' => 'Vorbereiten',
			'hub.sections.hike' => 'Wandern',
			'hub.sections.info' => 'Informationen',
			'hub.sections.after' => 'Nach dem Trek',
			'hub.cards.feasibility' => 'Machbarkeit',
			'hub.cards.feasibilitySub' => 'Bewerten Sie Ihr Niveau',
			'hub.cards.itinerary' => 'Route',
			'hub.cards.itinerarySub' => 'Der Wegverlauf',
			'hub.cards.programme' => 'Programm',
			'hub.cards.programmeSub' => 'Etappen aufteilen',
			'hub.cards.checklist' => 'Ausrüstung & Rucksack',
			'hub.cards.checklistSub' => 'Packen Sie Ihren Rucksack',
			'hub.cards.training' => 'Körperliche Vorbereitung',
			'hub.cards.trainingSub' => 'Ihr Trainingsprogramm',
			'hub.cards.offline' => 'Offline',
			'hub.cards.offlineSub' => 'Wege herunterladen',
			'hub.cards.group' => 'Meine Gruppe',
			'hub.cards.groupSub' => 'Ihre Begleiter verfolgen',
			'hub.cards.navigation' => 'Navigation',
			'hub.cards.navigationSub' => 'Karte und GPS-Tracking',
			'hub.cards.journal' => 'Tagebuch',
			'hub.cards.journalSub' => 'Ihre Notizen und Erinnerungen',
			'hub.cards.accommodations' => 'Unterkünfte',
			'hub.cards.accommodationsSub' => 'Übernachten in der Nähe',
			'hub.cards.tips' => 'Ratgeber',
			'hub.cards.tipsSub' => 'Unsere Trekking-Tipps',
			'hub.cards.recap' => 'Zusammenfassung',
			'hub.cards.recapSub' => 'Ihr Abenteuer in Kürze',
			'hub.cards.diploma' => 'Diplom',
			'hub.cards.diplomaSub' => 'Ihre Abschlussurkunde',
			'hub.fab.feedback' => 'Feedback geben',
			'hub.fab.sos' => 'SOS',
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
			'accommodation.types.refuge' => 'Berghütte',
			'accommodation.types.bergerie' => 'Schäferhütte',
			'accommodation.types.gite' => 'Herberge',
			'accommodation.types.hotel' => 'Hotel',
			'accommodation.types.camping' => 'Campingplatz',
			'accommodation.types.bivouac' => 'Biwak',
			'gps.permission' => 'GPS-Berechtigung erforderlich',
			'gps.denied' => 'Standortzugriff verweigert',
			'gps.disabled' => 'Standortdienst deaktiviert',
			'gps.offTrack' => 'Abseits der Strecke',
			'gps.centerOnMe' => 'Auf meine Position zentrieren',
			'navAlert.offTrackBanner' => ({required Object meters}) => 'Sie entfernen sich vom Weg — ${meters} m. Uberprufen Sie Ihre Position.',
			'navAlert.offTrackNotifTitle' => 'Sie verlassen den Weg',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'Sie entfernen sich vom Weg (${meters} m). Uberprufen Sie Ihre Position.',
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
			'settings.offTrackAlerts' => 'Abseits-der-Strecke-Warnung',
			'settings.offTrackAlertsDesc' => 'Benachrichtigung + Vibration, wenn Sie den Weg verlassen',
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
			'auth.anonymous' => 'Wanderer ohne Konto',
			'auth.connectedVia' => 'Verbunden über',
			'auth.signInGoogle' => 'Mit Google anmelden',
			'auth.signInGoogleDesc' => 'Um Ihren Fortschritt zu speichern',
			'auth.signOut' => 'Abmelden',
			'auth.signOutDesc' => 'Zurück zum Modus ohne Konto',
			'auth.signOutConfirm' => 'Abmelden?',
			'auth.signOutMessage' => 'Sie kehren zum Modus ohne Konto zurück. Ihre lokalen Daten bleiben erhalten.',
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
			'noData.title' => 'Kein Weg heruntergeladen',
			'noData.subtitle' => 'Laden Sie einen Weg herunter, um zu beginnen',
			'noData.offlineHint' => 'Die Daten sind offline für Ihre Wanderung verfügbar.',
			'noData.browseCta' => 'Wege durchsuchen',
			'catalog.title' => 'Wegekatalog',
			'catalog.enter' => 'Öffnen',
			'catalog.mustDownload' => 'Laden Sie diesen Weg herunter, um ihn zu erkunden.',
			'catalog.emptyTitle' => 'Kein Weg verfügbar',
			'catalog.emptySubtitle' => 'Im Katalog wird noch kein Weg angeboten.',
			'catalog.a11y.enterButton' => ({required Object nom}) => 'Weg ${nom} öffnen',
			'updates.readyTitle' => 'Update bereit',
			'updates.readyBodyOne' => 'Ein Weg wurde aktualisiert.',
			'updates.readyBodyMany' => ({required Object count}) => '${count} Wege wurden aktualisiert.',
			'follow.title' => 'Live-Verfolgung',
			'follow.connecting' => 'Verbinden…',
			'follow.live' => 'Live',
			'follow.offline' => 'Offline',
			'follow.invalidLink' => 'Ungültiger Link',
			'follow.invalidLinkHint' => 'Dieser Tracking-Link existiert nicht oder ist abgelaufen.',
			'cloud.localModeTitle' => 'Lokaler Modus',
			'cloud.localModeBody' => 'Diese Installation ist mit keinem Cloud-Dienst verbunden: Live-Verfolgung, Online-Sicherung und Konto sind deaktiviert. Ihre Daten bleiben auf dem Gerät.',
			'cloud.statusSection' => 'Cloud',
			'cloud.statusActive' => 'Online-Dienste aktiv',
			'cloud.statusActiveDesc' => 'Sicherung und Live-Verfolgung verfügbar.',
			'cloud.statusLocal' => 'Lokaler Modus (ohne Cloud)',
			'cloud.statusLocalDesc' => 'Es werden keine Daten online gesendet. Keine Cloud-Konfiguration vorhanden.',
			'onboarding.skip' => 'Überspringen',
			'onboarding.next' => 'Weiter',
			'onboarding.getStarted' => 'Los geht\'s',
			'onboarding.welcomeTitle' => ({required Object appName}) => 'Willkommen bei ${appName}',
			'onboarding.welcomeSubtitle' => 'Dein Offline-Wanderbegleiter: Karte, GPS-Navigation, Planung und Tourentagebuch.',
			'onboarding.languageTitle' => 'Wähle deine Sprache',
			'onboarding.languageSubtitle' => 'Du kannst sie jederzeit in den Einstellungen ändern.',
			'onboarding.downloadTitle' => 'Lade deinen ersten Weg herunter',
			'onboarding.downloadSubtitle' => 'Durchsuche den Katalog und lade einen Weg herunter, um ihn vollständig offline zu nutzen.',
			'onboarding.browseCatalog' => 'Katalog durchsuchen',
			'monetization.demoBanner' => 'Demo-Modus — zum Freischalten tippen',
			'monetization.paywallTitle' => 'Diesen Trek freischalten',
			'monetization.paywallBody' => 'Im Gratis-Modus planen Sie Ihren Trek mit Werbung. Premium schaltet alles frei, werbefrei.',
			'monetization.featureMap' => 'Offline-Karte + GPS + Live-Tracking',
			'monetization.featureJournal' => 'Vollständiges Trek-Tagebuch',
			'monetization.featureDiploma' => 'Trek-Abschlussdiplom',
			'monetization.featureFollowers' => '2 kostenlose Follower',
			'monetization.featureNoAds' => 'Keine Werbung',
			'monetization.buyCta' => 'Diesen Trek freischalten',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Diesen Trek freischalten — ${price} €',
			'signalement.title' => 'Melden',
			'signalement.chooseType' => 'Was möchten Sie melden?',
			'signalement.types.obstacle' => 'Hindernis auf dem Weg',
			'signalement.types.eauASec' => 'Trockene Wasserstelle',
			'signalement.types.danger' => 'Gefahr',
			'signalement.latencyBanner' => 'Gespeichert. Für andere Wanderer sichtbar, sobald das Netzwerk synchronisiert.',
			'signalement.confirm' => 'Meldung bestätigen',
			'signalement.noLocation' => 'GPS-Position derzeit nicht verfügbar. Versuchen Sie es unter freiem Himmel erneut.',
			'signalement.savedTitle' => 'Meldung gespeichert',
			'signalement.savedPendingSync' => 'Sie wird geteilt, sobald das Netzwerk wieder da ist.',
			'signalement.pendingCount' => ({required Object n}) => '${n} warten auf Synchronisierung',
			'signalement.close' => 'Schließen',
			'hebergement.title' => 'Unterkünfte in der Nähe',
			'hebergement.facilitatorNote' => 'StepWays verweist Sie an die Gastgeber. Die Buchung erfolgt auf deren Website: keine Zahlung in der App.',
			'hebergement.detourAR' => ({required Object km}) => 'Umweg hin und zurück: ${km} km',
			'hebergement.openSite' => 'Website ansehen',
			'hebergement.cannotOpen' => 'Dieser Link konnte auf diesem Gerät nicht geöffnet werden.',
			'hebergement.empty' => 'Derzeit keine Unterkünfte in der Nähe gelistet.',
			'hebergement.types.refuge' => 'Berghütte',
			'hebergement.types.gite' => 'Gästehaus',
			'hebergement.types.hotel' => 'Hotel',
			'hebergement.types.camping' => 'Campingplatz',
			'hebergement.types.chambreHote' => 'Pension',
			'training.title' => 'Körperliche Vorbereitung',
			'training.localNotice' => 'Ihr Plan wird auf Ihrem Telefon berechnet und gespeichert. Erinnerungen sind lokale Benachrichtigungen, ohne Tracking.',
			'training.reminderTitle' => 'Heute Trainingseinheit',
			'training.scheduleReminders' => 'Erinnerungen planen',
			'training.remindersScheduled' => ({required Object n}) => '${n} Erinnerung(en) geplant',
			'training.week' => ({required Object n}) => 'Woche ${n}',
			'training.minutes' => ({required Object n}) => '${n} Min',
			'training.progress' => ({required Object done, required Object total}) => '${done}/${total} Einheiten erledigt',
			'training.types.marche' => 'Gehen',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Kraft',
			'training.intensity.faible' => 'Niedrig',
			'training.intensity.moderee' => 'Mittel',
			'training.intensity.elevee' => 'Hoch',
			'eta.title' => 'Geschätzte Zeit',
			'eta.toNextWaypoint' => 'Nächster Punkt',
			'eta.toStageEnd' => 'Etappenende',
			'eta.confidenceHigh' => 'Zuverlässige Schätzung',
			'eta.confidenceLow' => 'Ungefähr (schwaches GPS)',
			'eta.durationHm' => ({required Object h, required Object m}) => '${h} Std ${m} Min',
			'eta.durationM' => ({required Object m}) => '${m} Min',
			'leaderboard.title' => 'König der Etappe',
			'leaderboard.unavailable' => 'Rangliste derzeit nicht verfügbar.',
			'leaderboard.empty' => 'Noch keine Rangliste für dieses Segment. Sei der Erste!',
			'leaderboard.pseudonymNotice' => 'Rangliste nach Gruppe, mit Pseudonymen. Es werden keine direkten personenbezogenen Daten angezeigt.',
			_ => null,
		} ?? switch (path) {
			'leaderboard.trancheLabel' => ({required Object tranche}) => 'Gruppe: ${tranche}',
			'leaderboard.notEnoughParticipants' => 'Nicht genug Teilnehmer, um diese Rangliste zu veröffentlichen.',
			'leaderboard.entrySemantics' => ({required Object rank, required Object pseudonym, required Object time}) => 'Rang ${rank}, ${pseudonym}, Zeit ${time}',
			'social.feedTitle' => 'Aktivitätsverlauf',
			'social.empty' => 'Noch keine Aktivität.',
			'social.kudos' => 'Anfeuern',
			'social.kudosCount' => ({required Object n}) => '${n} Kudos',
			'social.report' => 'Melden',
			'social.reportTitle' => 'Diesen Beitrag melden',
			'social.reportReasonLabel' => 'Grund der Meldung',
			'social.reasonSpam' => 'Spam oder Werbung',
			'social.reasonAbuse' => 'Missbräuchlicher oder hasserfüllter Inhalt',
			'social.reasonOther' => 'Andere',
			'social.reportSend' => 'Meldung senden',
			'social.reportSent' => 'Meldung gesendet. Unser Team prüft sie.',
			'social.syncPending' => 'Wartet auf Synchronisierung',
			'social.synced' => 'Synchronisiert',
			'social.activitySegment' => 'hat ein Segment absolviert',
			'social.activityBadge' => 'hat ein Abzeichen erhalten',
			'social.activityDefi' => 'hat bei einer Challenge Fortschritte gemacht',
			'gamification.galleryTitle' => 'Meine Abzeichen',
			'gamification.obtained' => 'Erhalten',
			'gamification.locked' => 'Gesperrt',
			'gamification.tierDebutant' => 'Anfänger',
			'gamification.tierExpert' => 'Experte',
			'gamification.badge.firstStage.titre' => 'Erste Etappe',
			'gamification.badge.firstStage.description' => 'Du hast deine erste Etappe abgeschlossen.',
			'gamification.badge.firstTrek.titre' => 'Erster Trek',
			'gamification.badge.firstTrek.description' => 'Du hast deinen ersten vollständigen Trek beendet.',
			'gamification.badge.firstSegment.titre' => 'Erstes Segment',
			'gamification.badge.firstSegment.description' => 'Du hast dein erstes Segment absolviert.',
			'gamification.badge.elevation5000.titre' => '5000 m Höhenmeter',
			'gamification.badge.elevation5000.description' => 'Du hast 5000 m Höhenmeter gesammelt.',
			'gamification.badge.tenStages.titre' => '10 Etappen',
			'gamification.badge.tenStages.description' => 'Du hast 10 Etappen abgeschlossen.',
			'gamification.badge.challenger.titre' => 'Herausforderer',
			'gamification.badge.challenger.description' => 'Du hast deine erste saisonale Challenge gemeistert.',
			'gamification.defi.screenTitle' => 'Challenges',
			'gamification.defi.inProgress' => 'Laufend',
			'gamification.defi.progressLabel' => ({required Object current, required Object target}) => 'Fortschritt: ${current} / ${target}',
			'gamification.defi.rankingTitle' => 'Challenge-Rangliste',
			'gamification.defi.pseudonymNotice' => 'Rangliste nach Gruppe, mit Pseudonymen. Es werden keine direkten personenbezogenen Daten angezeigt.',
			'gamification.defi.notEnoughParticipants' => 'Nicht genug Teilnehmer, um diese Rangliste zu veröffentlichen.',
			'gamification.defi.noDefi' => 'Derzeit keine laufende Challenge.',
			'shareVisibility.title' => 'Teilen und Sichtbarkeit',
			'shareVisibility.intro' => 'Standardmäßig wird nichts geteilt. Aktiviere unten zweckweise, was du sichtbar machen möchtest.',
			'shareVisibility.consentLink' => 'Meine Einwilligung verwalten (Datenschutz)',
			'shareVisibility.stageResults' => 'Meine Etappenergebnisse teilen',
			'shareVisibility.stageResultsDesc' => 'Eine pseudonyme Karte (keine direkten personenbezogenen Daten).',
			'shareVisibility.leaderboard' => 'In Ranglisten erscheinen',
			'shareVisibility.leaderboardDesc' => 'Rangliste nach Gruppe, mit einem Pseudonym.',
			'shareVisibility.activityFeed' => 'Im Aktivitätsverlauf posten',
			'shareVisibility.activityFeedDesc' => 'Deine Aktivitäten erscheinen im Verlauf, unter einem Pseudonym.',
			'shareVisibility.shareTitle' => 'Diese Etappe teilen',
			'shareVisibility.shareButton' => 'Teilen',
			'shareVisibility.privateNotice' => 'Teilen ist aus. Aktiviere es unter Teilen und Sichtbarkeit.',
			'shareVisibility.shared' => 'Karte bereit zum Teilen.',
			'waypoints.types.eau' => 'Wasser',
			'waypoints.types.ravitaillement' => 'Nachschub',
			'waypoints.types.danger' => 'Gefahr',
			'waypoints.types.camp' => 'Zeltplatz',
			'waypoints.types.connectivite' => 'Konnektivitat',
			'waypoints.types.jonction' => 'Kreuzung',
			'waypoints.filters.title' => 'Wegpunkte filtern',
			'waypoints.filters.showAll' => 'Alle anzeigen',
			'waypoints.filters.hideAll' => 'Alle ausblenden',
			'waypoints.filters.recentConditionOnly' => 'Nur aktueller Zustand',
			'waypoints.detail.conditionsTitle' => 'Gelandezustand',
			'waypoints.detail.noComments' => 'Noch kein Zustand gemeldet.',
			'waypoints.detail.commentsError' => 'Zustand nicht verfugbar.',
			'waypoints.detail.report' => 'Melden',
			'waypoints.detail.reportAck' => 'Meldung gespeichert. Sie wird nach der Synchronisierung gepruft.',
			'waypoints.detail.pendingSync' => 'Warten auf Synchronisierung',
			'waypoints.freshness.justNow' => 'gerade aktualisiert',
			'waypoints.freshness.minutes' => ({required Object n}) => 'vor ${n} Min aktualisiert',
			'waypoints.freshness.hours' => ({required Object n}) => 'vor ${n} Std aktualisiert',
			'waypoints.freshness.days' => ({required Object n}) => 'vor ${n} T aktualisiert',
			'waypoints.contribution.titleWaypoint' => 'Wegpunkt hinzufugen',
			'waypoints.contribution.titleComment' => 'Zustand melden',
			'waypoints.contribution.chooseType' => 'Wegpunkttyp',
			'waypoints.contribution.titleField' => 'Titel des Wegpunkts',
			'waypoints.contribution.conditionPrompt' => 'Beschreiben Sie den beobachteten Zustand',
			'waypoints.contribution.commentField' => 'Ihre Beobachtung',
			'waypoints.contribution.conditionField' => 'Zustand (optional)',
			'waypoints.contribution.conditionHelper' => 'z. B. Wasser versiegt, Wasser fliesst, rutschige Stelle',
			'waypoints.contribution.latencyBanner' => 'Wird bei der nachsten Synchronisierung veroffentlicht.',
			'waypoints.contribution.submit' => 'Speichern',
			'waypoints.contribution.savedTitle' => 'Beitrag gespeichert',
			'waypoints.contribution.savedPendingSync' => 'Er wird veroffentlicht, sobald das Netz wieder da ist.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} warten auf Synchronisierung',
			'waypoints.contribution.close' => 'Schliessen',
			'waypoints.contribution.emptyTitle' => 'Bitte einen Titel fur den Wegpunkt angeben.',
			'waypoints.contribution.emptyComment' => 'Bitte Ihre Beobachtung eingeben.',
			'waypoints.contribution.noLocation' => 'GPS-Position nicht verfugbar. Unter freiem Himmel erneut versuchen.',
			'waypoints.contribution.error' => 'Speichern derzeit nicht moglich.',
			'packs.title' => 'Wegpakete',
			'packs.subtitle' => 'Lade ein Paket herunter, um 100% offline zu wandern.',
			'packs.alaCarteNote' => 'A la carte: Kaufe nur das Paket, das du brauchst, kein Abo.',
			'packs.size' => ({required Object mo}) => '${mo} MB',
			'packs.states.notDownloaded' => 'Nicht heruntergeladen',
			'packs.states.downloaded' => 'Heruntergeladen',
			'packs.states.updateAvailable' => 'Update verfügbar',
			'packs.actions.download' => 'Herunterladen',
			'packs.actions.update' => 'Aktualisieren',
			'packs.actions.delete' => 'Löschen',
			'packs.actions.retry' => 'Erneut versuchen',
			'packs.actions.buy' => 'Dieses Paket kaufen',
			'packs.actions.buyWithPrice' => ({required Object price}) => 'Dieses Paket kaufen — ${price}',
			'packs.progress.downloading' => ({required Object done, required Object total}) => 'Wird heruntergeladen… ${done}/${total}',
			'packs.progress.verifying' => 'Integrität wird geprüft…',
			'packs.progress.completed' => 'Paket offline bereit',
			'packs.progress.error' => 'Download fehlgeschlagen',
			'packs.delete.confirmTitle' => 'Dieses Paket löschen?',
			'packs.delete.confirmBody' => 'Das Paket wird vom Gerät entfernt, um Speicher freizugeben. Du kannst es später erneut herunterladen.',
			'packs.delete.cancel' => 'Abbrechen',
			'packs.delete.confirm' => 'Löschen',
			'packs.delete.freed' => 'Speicher freigegeben.',
			'packs.empty' => 'Kein Paket für diesen Weg verfügbar.',
			'packs.a11y.packCard' => ({required Object nom, required Object state}) => 'Paket ${nom}, ${state}',
			'packs.a11y.downloadButton' => ({required Object nom}) => 'Paket ${nom} herunterladen',
			'packs.a11y.deleteButton' => ({required Object nom}) => 'Paket ${nom} löschen',
			'packs.types.nord.nom' => 'Mare a Mare Nord',
			'packs.types.nord.description' => 'Die nördliche Hälfte des Wegs, offline.',
			'packs.types.sud.nom' => 'Mare a Mare Süd',
			'packs.types.sud.description' => 'Die südliche Hälfte des Wegs, offline.',
			'packs.types.complet.nom' => 'Mare a Mare Komplett',
			'packs.types.complet.description' => 'Der ganze Weg, offline.',
			'packs.types.mam.nom' => 'Mare a Mare',
			'packs.types.mam.description' => 'Der Mare-a-Mare-Weg, offline.',
			'guides.title' => 'Ortsführer',
			'guides.subtitle' => 'Praktische Infos zu Städten und Dörfern, offline verfügbar.',
			'guides.sectionsCount' => ({required Object n}) => '${n} praktische Rubriken',
			'guides.empty' => 'Kein Führer für diesen Weg verfügbar.',
			'guides.noItems' => 'Noch keine Informationen in diesem Abschnitt.',
			'guides.facilitatorNote' => 'StepWays verweist Sie an Anbieter. Buchung und Zahlung erfolgen auf deren Website: nichts in der App.',
			'guides.openSite' => 'Website öffnen',
			'guides.cannotOpen' => 'Dieser Link kann auf diesem Gerät nicht geöffnet werden.',
			'guides.categories.ravitaillement' => 'Verpflegung',
			'guides.categories.hebergement' => 'Unterkunft',
			'guides.categories.transport' => 'Transport',
			'guides.categories.services' => 'Dienstleistungen',
			'guides.categories.eau' => 'Wasser',
			'guides.categories.sante' => 'Gesundheit',
			'guides.intro.ravitaillement' => 'Wo man Vorräte auffüllt.',
			'guides.intro.hebergement' => 'Wo man an der Etappe schläft.',
			'guides.intro.transport' => 'Busse, Shuttles und Verbindungen.',
			'guides.intro.services' => 'Post, Bank, Wäscherei und mehr.',
			'guides.intro.eau' => 'Trinkwasserstellen.',
			'guides.intro.sante' => 'Apotheke und Versorgung in der Nähe.',
			'guides.a11y.guideCard' => ({required Object lieu}) => 'Führer für ${lieu}',
			'guides.a11y.section' => ({required Object titre}) => 'Abschnitt ${titre}',
			'guides.a11y.openSiteButton' => ({required Object nom}) => 'Website von ${nom} öffnen',
			'trailSelection.title' => 'Weg wechseln',
			'trailSelection.subtitle' => 'Waehle den Weg zum Erkunden. Die ganze App (Karte, Etappen, Sehenswuerdigkeiten, Pakete, Reisefuehrer) folgt deiner Auswahl.',
			'trailSelection.current' => 'Aktiver Weg',
			'trailSelection.select' => 'Diesen Weg waehlen',
			'trailSelection.selected' => 'Ausgewaehlter Weg',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} Etappen - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Weg ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Aktuell aktiver Weg',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Weg ${nom} aktivieren',
			'consent.onboardingTitle' => 'Ihre Privatsphäre, Ihre Wahl',
			'consent.onboardingIntro' => 'Standardmäßig ist nichts aktiviert. Wählen Sie Zweck für Zweck, was Sie erlauben. Sie können alles jederzeit in den Einstellungen ändern.',
			'consent.settingsTitle' => 'Datenschutz und Einwilligung',
			'consent.settingsIntro' => 'Verwalten Sie hier jede Berechtigung. Sie können eine Einwilligung jederzeit widerrufen, ohne Auswirkung auf den Rest.',
			'consent.settingsEntry' => 'Datenschutz und Einwilligung',
			'consent.settingsEntryDesc' => 'Meine Berechtigungen verwalten (Standort, Teilen, Gesundheit)',
			'consent.purposes.locationNavigation' => 'Persönliche Navigation',
			'consent.purposes.locationNavigationDesc' => 'Ihren Standort für die Karte und die Etappenverfolgung nutzen. Bleibt auf Ihrem Gerät.',
			'consent.purposes.socialSharing' => 'Soziales Teilen',
			'consent.purposes.socialSharingDesc' => 'Unter einem Pseudonym in Ranglisten und im Community-Feed erscheinen.',
			'consent.purposes.publicReporting' => 'Öffentliche Meldungen',
			'consent.purposes.publicReportingDesc' => 'Meldungen (Wasser, Gefahr, Bedingungen) veröffentlichen, die für andere Wanderer sichtbar sind.',
			'consent.purposes.healthData' => 'Gesundheitsdaten',
			'consent.purposes.healthDataDesc' => 'Ihre Herzfrequenz (Brustgurt oder Gesundheits-App) lesen, um Ihre Anstrengung genauer zu erfassen.',
			'consent.healthBadge' => 'Sensible Daten',
			'consent.healthWarning' => 'Die Herzfrequenz ist ein Gesundheitsdatum (DSGVO Artikel 9). Diese Einwilligung wird separat erfragt und niemals mit den anderen gebündelt. Ihre Gesundheitsdaten werden nicht an unsere Server gesendet.',
			'consent.granted' => 'Erlaubt',
			'consent.denied' => 'Nicht erlaubt',
			'consent.grant' => 'Erlauben',
			'consent.revoke' => 'Widerrufen',
			'consent.decidedOn' => ({required Object date}) => 'Gewählt am ${date}',
			'consent.notDecided' => 'Wartet auf Ihre Wahl',
			'consent.acceptSelected' => 'Meine Auswahl bestätigen',
			'consent.declineAll' => 'Alles ablehnen',
			'consent.continueLabel' => 'Weiter',
			'consent.privacyPolicyLink' => 'Datenschutzerklärung lesen',
			'consent.reviewNeeded' => 'Unsere Richtlinie hat sich geändert: Bitte überprüfen Sie Ihre Auswahl.',
			'consent.a11y.purposeToggle' => ({required Object purpose, required Object state}) => '${purpose}, aktuell ${state}',
			'consent.a11y.healthSection' => 'Bereich Gesundheitsdaten, verstärkte Einwilligung',
			'consent.a11y.policyButton' => 'Datenschutzerklärung öffnen',
			'moderation.reportTitle' => 'Diesen Inhalt melden',
			'moderation.reportIntro' => 'Helfen Sie uns, die Community gesund zu halten. Geben Sie an, warum dieser Inhalt rechtswidrig erscheint. Ihre Meldung wird von einem Moderator geprüft.',
			'moderation.reasonLabel' => 'Grund der Meldung',
			'moderation.reasons.illegal' => 'Illegaler Inhalt',
			'moderation.reasons.harassment' => 'Belästigung oder Hass',
			'moderation.reasons.spam' => 'Spam oder Werbung',
			'moderation.reasons.dangerous' => 'Gefährliche oder irreführende Information',
			'moderation.reasons.other' => 'Sonstiges',
			'moderation.detailsLabel' => 'Details hinzufügen (optional)',
			'moderation.detailsHint' => 'Fügen Sie einen Kommentar hinzu, um dem Moderator zu helfen.',
			'moderation.contactLabel' => 'Ihre E-Mail-Adresse',
			'moderation.contactHint' => 'Um Sie über die Bearbeitung zu informieren (Artikel 16).',
			'moderation.goodFaithLabel' => 'Ich erkläre nach bestem Wissen, dass diese Angaben zutreffen.',
			'moderation.submit' => 'Meldung senden',
			'moderation.submitting' => 'Wird gesendet…',
			'moderation.sent' => 'Meldung gesendet. Danke, ein Moderator wird sie prüfen.',
			'moderation.errorRequired' => 'Bitte Grund, E-Mail und die Erklärung in gutem Glauben ausfüllen.',
			'moderation.errorGeneric' => 'Die Meldung konnte nicht gesendet werden. Bitte erneut versuchen.',
			'moderation.cancel' => 'Abbrechen',
			'moderation.reasonsTitle' => 'Warum wurde dieser Inhalt eingeschränkt?',
			'moderation.reasonsIntro' => 'Gemäß Artikel 17 finden Sie hier den Grund für die Moderationsentscheidung zu Ihrem Inhalt.',
			'moderation.decisionLabel' => 'Entscheidung',
			'moderation.decisions.keep' => 'Inhalt beibehalten',
			'moderation.decisions.restrict' => 'Inhalt eingeschränkt',
			'moderation.decisions.remove' => 'Inhalt entfernt',
			'moderation.noStatement' => 'Auf Ihre Inhalte wurde keine Einschränkung angewendet.',
			'moderation.complaintAction' => 'Diese Entscheidung anfechten',
			'moderation.complaintTitle' => 'Eine Entscheidung anfechten',
			'moderation.complaintIntro' => 'Sie können eine Moderationsentscheidung anfechten. Erklären Sie, warum die Entscheidung Ihrer Meinung nach ungerechtfertigt ist (Artikel 20).',
			'moderation.complaintExposeLabel' => 'Ihre Anfechtung',
			'moderation.complaintExposeHint' => 'Beschreiben Sie die Gründe für Ihre Anfechtung.',
			'moderation.complaintSubmit' => 'Anfechtung senden',
			'moderation.complaintSent' => 'Anfechtung erfasst. Sie wird geprüft.',
			'moderation.complaintEmpty' => 'Bitte erklären Sie Ihre Anfechtung.',
			'moderation.a11y.reportForm' => 'Formular zur Inhaltsmeldung',
			'moderation.a11y.reasonSelector' => 'Auswahl des Meldegrunds',
			'moderation.a11y.goodFaithToggle' => ({required Object state}) => 'Erklärung in gutem Glauben, ${state}',
			'moderation.a11y.submitReport' => 'Meldung senden',
			'moderation.a11y.statementCard' => 'Begründung der Moderationsentscheidung',
			'moderation.a11y.complaintForm' => 'Formular zur Anfechtung der Entscheidung',
			_ => null,
		};
	}
}
