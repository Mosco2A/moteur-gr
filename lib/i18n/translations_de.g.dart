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
	@override late final _Translations$itinerary$de itinerary = _Translations$itinerary$de._(_root);
	@override late final _Translations$tracking$de tracking = _Translations$tracking$de._(_root);
	@override late final _Translations$checklist$de checklist = _Translations$checklist$de._(_root);
	@override late final _Translations$journal$de journal = _Translations$journal$de._(_root);
	@override late final _Translations$weather$de weather = _Translations$weather$de._(_root);
	@override late final _Translations$share$de share = _Translations$share$de._(_root);
	@override late final _Translations$diploma$de diploma = _Translations$diploma$de._(_root);
	@override late final _Translations$notifications$de notifications = _Translations$notifications$de._(_root);
	@override late final _Translations$settings$de settings = _Translations$settings$de._(_root);
	@override late final _Translations$appearance$de appearance = _Translations$appearance$de._(_root);
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
	@override late final _Translations$health$de health = _Translations$health$de._(_root);
	@override late final _Translations$trailSelection$de trailSelection = _Translations$trailSelection$de._(_root);
	@override late final _Translations$consent$de consent = _Translations$consent$de._(_root);
	@override late final _Translations$moderation$de moderation = _Translations$moderation$de._(_root);
	@override late final _Translations$bootstrap$de bootstrap = _Translations$bootstrap$de._(_root);
	@override late final _Translations$recap$de recap = _Translations$recap$de._(_root);
	@override late final _Translations$programme$de programme = _Translations$programme$de._(_root);
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
	@override String get checklist => 'Ausrustung & Rucksack';
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
	@override String get noTrack => 'Keine Strecke verfügbar';
	@override String get viewMap => 'Karte anzeigen';
}

// Path: stage
class _Translations$stage$de extends Translations$stage$fr {
	_Translations$stage$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Entfernung';
	@override String get elevation => 'Höhenunterschied';
	@override String get elevationGain => 'Höhenmeter aufwärts';
	@override String get elevationLoss => 'Höhenmeter abwärts';
	@override String get duration => 'Geschätzte Dauer';
	@override String get description => 'Beschreibung';
	@override String get coordinates => 'Koordinaten';
	@override String get pois => 'Sehenswürdigkeiten';
	@override late final _Translations$stage$difficulty$de difficulty = _Translations$stage$difficulty$de._(_root);
	@override String get remaining => '{distance} km verbleibend';
	@override String get arrived => 'Sie sind angekommen!';
	@override String get altitudeProfile => 'Hohenprofil';
	@override String get statistics => 'Statistiken';
	@override String get loading => 'Laden...';
	@override String get loadingList => 'Etappen werden geladen...';
	@override String get dPlus => 'D+';
	@override String get dMinus => 'D-';
	@override String get difficultyLabel => 'Schwierigkeit';
}

// Path: trail
class _Translations$trail$de extends Translations$trail$fr {
	_Translations$trail$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etappen';
	@override String get totalDistance => 'Gesamtstrecke';
	@override String get totalElevation => 'Gesamthöhenmeter';
}

// Path: poi
class _Translations$poi$de extends Translations$poi$fr {
	_Translations$poi$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Schutzhütte';
	@override String get water => 'Wasserquelle';
	@override String get viewpoint => 'Aussichtspunkt';
	@override String get campsite => 'Biwakplatz';
	@override String get restaurant => 'Restaurant';
	@override String get emergency => 'Notfall';
	@override String get danger => 'Gefahr';
	@override String get shop => 'Geschäft';
	@override String get filter => 'Sehenswürdigkeiten filtern';
	@override String get altitude => 'Höhe';
	@override String get hours => 'Öffnungszeiten';
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

// Path: itinerary
class _Translations$itinerary$de extends Translations$itinerary$fr {
	_Translations$itinerary$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Route';
	@override String get subtitle => 'Ihre Etappen, Tag fuer Tag';
	@override String get empty => 'Keine Etappe verfuegbar';
	@override String get emptyHint => 'Wegdaten sind nicht geladen.';
	@override String get loading => 'Route wird geladen...';
	@override String get error => 'Route kann nicht geladen werden';
	@override String get day => 'Tag';
	@override String get stage => 'Etappe';
	@override String get stages => 'Etappen';
	@override String get totalDistance => 'Distanz';
	@override String get totalElevation => 'D+';
	@override String get restDay => 'Ruhetag';
	@override String get viewStage => 'Etappe ansehen';
	@override String get openMap => 'Auf Karte ansehen';
	@override String get stageCount => '{count} Etappen';
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
	@override String get dPlus => 'D+';
	@override String get stopSaveProgress => 'Ihr Fortschritt wird gespeichert.';
	@override String get cancel => 'Abbrechen';
	@override String get stopButton => 'Stopp';
}

// Path: checklist
class _Translations$checklist$de extends Translations$checklist$fr {
	_Translations$checklist$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ausrustung & Rucksack';
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
	@override late final _Translations$checklist$weight$de weight = _Translations$checklist$weight$de._(_root);
	@override late final _Translations$checklist$ui$de ui = _Translations$checklist$ui$de._(_root);
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
	@override String get today => 'Heute';
	@override String get tomorrow => 'Morgen';
	@override String get dayPlus2 => 'Übermorgen';
	@override String get allStages => 'Alle Etappen';
	@override String get noForecast => 'Keine Vorhersage verfügbar.';
	@override String stageLabel({required Object number}) => 'Etappe ${number}';
	@override String get stormAlertsTitle => 'Gewitterwarnungen';
	@override String get stormAlertsToggleOn => 'Gewitterwarnungen aktiviert';
	@override String get stormAlertsToggleOff => 'Gewitterwarnungen deaktiviert';
	@override String lastUpdate({required Object date}) => 'Aktualisiert ${date}';
	@override String get guideTitle => 'Das Wetter verstehen';
	@override String get guideBody => 'Die Vorhersage umfasst 7 Tage für jede Etappe. Achten Sie auf Gewitter- und Windwarnungen: In den Bergen ändert sich das Wetter schnell. Ohne Netz werden die zuletzt gespeicherten Daten angezeigt.';
	@override late final _Translations$weather$source$de source = _Translations$weather$source$de._(_root);
	@override late final _Translations$weather$recommendation$de recommendation = _Translations$weather$recommendation$de._(_root);
	@override late final _Translations$weather$alert$de alert = _Translations$weather$alert$de._(_root);
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
	@override String get lockedTitle => 'Diplom gesperrt';
	@override String get lockedMessage => 'Absolviere deine gesamte Route, um dein Finisher-Diplom freizuschalten.';
	@override String get labelIntegral => 'Gesamte Route';
	@override String get labelPartial => 'Teilroute';
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

// Path: appearance
class _Translations$appearance$de extends Translations$appearance$fr {
	_Translations$appearance$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Erscheinungsbild';
	@override String get subtitle => 'Wähle das Design der App';
	@override String get skinSentierVivant => 'Lebendiger Pfad';
	@override String get skinSentierVivantDesc => 'Modern und farbenfroh, die Wegfarbe im Mittelpunkt';
	@override String get skinTopographique => 'Topografisch';
	@override String get skinTopographiqueDesc => 'Stil einer Wanderkarte, Daten im Vordergrund';
	@override String get skinGrandAir => 'Freiluft';
	@override String get skinGrandAirDesc => 'Bildschirmfüllende Fotos, Abenteuertagebuch-Look';
	@override String get unavailableOnTrail => 'Auf diesem Weg nicht verfügbar';
	@override String get changeSkin => 'Design wechseln';
	@override String get selected => 'Ausgewählt';
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

// Path: health
class _Translations$health$de extends Translations$health$fr {
	_Translations$health$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gesundheitsinformationen';
	@override String get privacyBanner => 'Diese Daten bleiben auf Ihrem Telefon. Sie werden niemals über das Internet gesendet.';
	@override late final _Translations$health$field$de field = _Translations$health$field$de._(_root);
	@override late final _Translations$health$hint$de hint = _Translations$health$hint$de._(_root);
	@override String get save => 'Speichern';
	@override String get saving => 'Speichern…';
	@override String get saved => 'Informationen gespeichert';
	@override String get emergencyHint => 'Zeigen Sie diesen Bildschirm im Notfall den Rettungskräften.';
	@override String get entryTitle => 'Meine Gesundheitsdaten';
	@override String get entrySubtitle => 'Den Rettungskräften zeigen (bleiben auf dem Telefon)';
	@override late final _Translations$health$a11y$de a11y = _Translations$health$a11y$de._(_root);
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

// Path: bootstrap
class _Translations$bootstrap$de extends Translations$bootstrap$fr {
	_Translations$bootstrap$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Ihre Wanderung wird vorbereitet…';
}

// Path: recap
class _Translations$recap$de extends Translations$recap$fr {
	_Translations$recap$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mein Abenteuer';
	@override String get lockedTitle => 'Verfugbar am Ende der Tour';
	@override String get lockedMessage => 'Beende oder brich deine Route ab, um die Zusammenfassung deines Abenteuers zu sehen.';
	@override String get finisherTitle => 'Gluckwunsch!';
	@override String get finisherSubtitle => 'Du hast deine Route abgeschlossen';
	@override String get partialTitle => 'Deine Teilroute';
	@override String get partialSubtitle => 'Dein Abenteuer bleibt gespeichert';
	@override String get statsSection => 'Statistiken';
	@override String get traceSection => 'Deine Spur';
	@override String get noTrace => 'Keine GPS-Spur verfugbar';
	@override String get stages => '{done} / {total} Etappen gelaufen';
	@override String get distance => '{km} km zuruckgelegt';
	@override String get elevation => '{meters} m Hohenmeter';
	@override String get duration => '{days} Tage';
	@override String get dates => 'Vom {start} bis {end}';
	@override String get viewDiploma => 'Mein Diplom ansehen';
	@override String get noData => 'Noch keine Routendaten zum Anzeigen.';
}

// Path: programme
class _Translations$programme$de extends Translations$programme$fr {
	_Translations$programme$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programm';
	@override String get helpTooltip => 'Hilfe';
	@override late final _Translations$programme$stats$de stats = _Translations$programme$stats$de._(_root);
	@override late final _Translations$programme$legend$de legend = _Translations$programme$legend$de._(_root);
	@override String get restDay => 'Ruhetag';
	@override String get restDayLabel => 'R';
	@override late final _Translations$programme$actions$de actions = _Translations$programme$actions$de._(_root);
	@override late final _Translations$programme$mergeBlocked$de mergeBlocked = _Translations$programme$mergeBlocked$de._(_root);
	@override String get replan => 'Neu planen';
	@override String get replanButton => 'NEU PLANEN';
	@override late final _Translations$programme$replanDialog$de replanDialog = _Translations$programme$replanDialog$de._(_root);
	@override String get validate => 'PROGRAMM BESTÄTIGEN';
	@override late final _Translations$programme$empty$de empty = _Translations$programme$empty$de._(_root);
	@override late final _Translations$programme$info$de info = _Translations$programme$info$de._(_root);
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
	@override String get alertStorm => 'Gewitterwarnung';
	@override String tempRange({required Object min, required Object max}) => '${min}° / ${max}°';
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
	@override String get itinerarySub => 'Ihre Etappen im Detail';
	@override String get programme => 'Programm';
	@override String get programmeSub => 'Etappen aufteilen';
	@override String get checklist => 'Ausrustung & Rucksack';
	@override String get checklistSub => 'Bereite deinen Rucksack vor';
	@override String get training => 'Körperliche Vorbereitung';
	@override String get trainingSub => 'Ihr Trainingsprogramm';
	@override String get offline => 'Wege entdecken';
	@override String get offlineSub => 'Katalog durchsuchen';
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
	@override String get townGuides => 'Ortsführer';
	@override String get townGuidesSub => 'Praktische Infos zu den Etappen';
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
	@override String get extreme => 'Extrem';
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
	@override String get carrying => 'Rucksack & Tragen';
	@override String get sleeping => 'Schlafen';
	@override String get clothing => 'Kleidung';
	@override String get cooking => 'Kochen';
	@override String get foodWater => 'Essen & Wasser';
	@override String get hygiene => 'Hygiene';
	@override String get firstAid => 'Erste-Hilfe-Set';
	@override String get electronics => 'Elektronik';
	@override String get women => 'Frauen';
	@override String get men => 'Manner';
	@override String get misc => 'Sonstiges';
	@override String get dog => 'Hund';
}

// Path: checklist.items
class _Translations$checklist$items$de extends Translations$checklist$items$fr {
	_Translations$checklist$items$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Rucksack 35-45L';
	@override String get rainCover => 'Rucksack-Regenhulle';
	@override String get dryBags => 'Packsacke (dry bags)';
	@override String get sleepingBag => 'Schlafsack (0-5C)';
	@override String get sleepingPad => 'Isomatte / Unterlage';
	@override String get sleepingLiner => 'Huttenschlafsack / Inlett';
	@override String get pillow => 'Aufblasbares Kissen';
	@override String get hikingPants => 'Wanderhose';
	@override String get rainPants => 'Regenhose';
	@override String get shorts => 'Shorts';
	@override String get techTshirt => 'Funktions-T-Shirt';
	@override String get fleece => 'Fleece / leichte Daune';
	@override String get rainJacket => 'Regenjacke Gore-Tex';
	@override String get underwear => 'Unterwasche';
	@override String get hikingSocks => 'Wandersocken';
	@override String get gaiters => 'Gamaschen';
	@override String get hat => 'Hut / Kappe';
	@override String get beanie => 'Mutze';
	@override String get buff => 'Buff / Halstuch';
	@override String get lightGloves => 'Leichte Handschuhe';
	@override String get hikingBoots => 'Wanderschuhe (getragen)';
	@override String get campSandals => 'Camp-Sandalen';
	@override String get stove => 'Kocher (PocketRocket)';
	@override String get gasCanister => 'Gaskartusche';
	@override String get cookpot => 'Kochtopf / Geschirr';
	@override String get cutlery => 'Besteck (Loffel, Messer)';
	@override String get waterBottle => 'Trinkflasche / Blase 2L';
	@override String get knife => 'Klappmesser';
	@override String get lighter => 'Feuerzeug';
	@override String get energyBars => 'Energieriegel';
	@override String get driedFruits => 'Trockenfruchte';
	@override String get freezeDriedMeal => 'Gefriergetrocknete Mahlzeit';
	@override String get waterPurification => 'Wasser-Entkeimungstabletten';
	@override String get electrolytes => 'Elektrolyte';
	@override String get carriedWater => 'Getragenes Wasser (1L = 1000g)';
	@override String get soap => 'Biologisch abbaubare Seife';
	@override String get toothbrush => 'Zahnburste';
	@override String get toothpaste => 'Zahnpasta';
	@override String get microfiberTowel => 'Mikrofaser-Handtuch';
	@override String get toiletPaper => 'Toilettenpapier';
	@override String get trashBag => 'Mullbeutel';
	@override String get antiChafingCream => 'Anti-Scheuer-Creme';
	@override String get earplugs => 'Ohrstopsel';
	@override String get bandages => 'Sortierte Pflaster';
	@override String get sterileCompresses => 'Sterile Kompressen';
	@override String get elasticBandage => 'Elastische Binde';
	@override String get disinfectant => 'Desinfektionsmittel (50ml)';
	@override String get painkillers => 'Paracetamol / Ibuprofen';
	@override String get sunscreen => 'Sonnencreme SPF50';
	@override String get lipBalm => 'Lippenbalsam SPF30';
	@override String get emergencyBlanket => 'Rettungsdecke';
	@override String get tickRemover => 'Zeckenzange';
	@override String get whistle => 'Notfallpfeife';
	@override String get strapping => 'Tapeverband / Strapping';
	@override String get eyeDrops => 'Augentropfen';
	@override String get antiDiarrheal => 'Durchfallmittel';
	@override String get antihistamine => 'Antihistaminikum';
	@override String get kneeTape => 'Knie-Tape';
	@override String get phone => 'Telefon';
	@override String get powerBank => 'Powerbank 20000mAh';
	@override String get usbCable => 'USB-Kabel';
	@override String get headlamp => 'Stirnlampe';
	@override String get spareBatteries => 'Ersatzbatterien';
	@override String get periodProtection => 'Periodenschutz';
	@override String get sportsBra => 'Sport-BH';
	@override String get intimateWipes => 'Intimtucher';
	@override String get peeCloth => 'Pee-Cloth';
	@override String get razor => 'Rasierer';
	@override String get techBoxers => 'Funktions-Boxershorts';
	@override String get hikingPoles => 'Wanderstocke (getragen)';
	@override String get sunglasses => 'Sonnenbrille';
	@override String get trailMap => 'Karte / Topo-Guide';
	@override String get spareLaces => 'Ersatzschnursenkel';
	@override String get needleThread => 'Nadel + Faden';
	@override String get ductTape => 'Klebeband';
	@override String get ziplocBags => 'Ziploc-Beutel';
	@override String get cord => 'Schnur';
	@override String get cash => 'Bargeld';
	@override String get dogBowl => 'Faltbarer Napf';
	@override String get dogLeash => 'Leine';
	@override String get dogKibble => 'Trockenfutter (Ration/Tag)';
	@override String get dogBooties => 'Schutzstiefel';
	@override String get dogVaccineBook => 'Impfpass';
	@override String get dogPoopBags => 'Kotbeutel';
	@override String get swimsuit => 'Badeanzug';
}

// Path: checklist.weight
class _Translations$checklist$weight$de extends Translations$checklist$weight$fr {
	_Translations$checklist$weight$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rucksackgewicht';
	@override String get total => 'Gesamtgewicht';
	@override String get bodyWeight => 'Korpergewicht:';
	@override String get ratio => 'Rucksack / Korper';
	@override String get perItem => 'Gewicht pro Artikel';
	@override String get edit => 'Gewicht andern';
	@override String get grams => 'g';
	@override String get kilograms => 'kg';
	@override String get adviceUltraLight => 'Ultraleichter Rucksack — ideal furs Trekking';
	@override String get adviceLight => 'Ultraleichter Rucksack — ideal furs Trekking';
	@override String get adviceOk => 'Gut ausbalancierter Rucksack';
	@override String get adviceHeavy => 'OK aber schwer — erwage zu erleichtern';
	@override String get adviceTooHeavy => 'Achtung Knie! Rucksack erleichtern';
	@override String get adviceDanger => 'Verletzungsgefahr — jetzt erleichtern!';
	@override String get itemWeight => 'Artikelgewicht';
	@override String get cancel => 'Abbrechen';
	@override String get save => 'Speichern';
	@override String get gaugeUltraLight => 'Ultraleicht, perfekt!';
	@override String get gaugeOk => 'Gut, ausbalanciert';
	@override String get gaugeHeavy => 'OK aber schwer';
	@override String get gaugeWarn => 'Achtung Knie!';
	@override String get gaugeDanger => 'Verletzungsgefahr!';
	@override String get percentOfWeight => '{pct}% des Korpergewichts';
	@override String get gaugeObjective => 'Max. Ziel: < 15% in Hutten, < 20% autark';
	@override String get itemsChecked => '{checked} / {total} Artikel angehakt';
}

// Path: checklist.ui
class _Translations$checklist$ui$de extends Translations$checklist$ui$fr {
	_Translations$checklist$ui$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ausrustung & Rucksack';
	@override String get requirementRequired => 'Pflicht';
	@override String get addItem => 'Artikel hinzufugen';
	@override String get addItemTitle => 'Artikel hinzufugen';
	@override String get fieldName => 'Name';
	@override String get fieldWeightGrams => 'Gewicht (Gramm)';
	@override String get add => 'Hinzufugen';
	@override String get editWeightTitle => 'Gewicht andern';
	@override String get editCustomTitle => 'Eigenen Artikel bearbeiten';
	@override String get modify => 'Bearbeiten';
	@override String get delete => 'Loschen';
	@override String get deleteItemTitle => 'Diesen Artikel loschen?';
	@override String get deleteItemBody => 'Der Artikel "{name}" wird endgultig geloscht.';
	@override String get requiredWarnTitle => 'Pflichtausrustung';
	@override String get requiredWarnBody => 'Diese Ausrustung ist aus Sicherheitsgrunden Pflicht (angelehnt an UTMB-Regeln). Wirklich entfernen?';
	@override String get keep => 'Behalten';
	@override String get removeAnyway => 'Trotzdem entfernen';
	@override String get reduceQuantity => 'Menge verringern';
	@override String get increaseQuantity => 'Menge erhohen';
	@override String get addToShoppingList => 'Zur Einkaufsliste hinzufugen';
	@override String get removeFromShoppingList => 'Von der Liste entfernen';
	@override String get help => 'Hilfe';
	@override String get shoppingListTitle => 'Einkaufsliste';
	@override String get shoppingListEmpty => 'Deine Einkaufsliste ist leer. Fuge Artikel mit dem Warenkorb-Button hinzu.';
	@override String get shoppingToBuy => 'Zu kaufen';
	@override String get shoppingPurchased => 'Bereits gekauft';
	@override String get share => 'TEILEN';
	@override String get infoTitle => 'Ausrustung & Rucksack';
	@override String get infoCheckTitle => 'Artikel anhaken';
	@override String get infoCheckBody => 'Hake an, was du mitnimmst — das Gewicht wird oben neu berechnet.';
	@override String get infoRequiredTitle => 'Pflicht';
	@override String get infoRequiredBody => 'Artikel mit Schloss = Vorschrift (Pfeife, Lampe, Rettungsdecke).';
	@override String get infoGaugeTitle => 'Gewichtsanzeige';
	@override String get infoGaugeBody => 'Ziel: Rucksack < 15% deines Gewichts. Grun = OK, Orange = Achtung, Rot = zu schwer.';
	@override String get infoAddTitle => 'Hinzufugen';
	@override String get infoAddBody => 'Der +-Button unten in jeder Kategorie fur eigene Artikel.';
	@override String get infoValidateBody => 'Bestatige, wenn dein Rucksack fertig ist — ein Haken erscheint auf der Startseite.';
	@override String get infoUnderstood => 'Verstanden!';
	@override String get prepTitle => 'Rucksack packen';
	@override String get prepCounter => '{prepared} / {total} Artikel gepackt';
	@override String get prepAllReady => 'Alles bereit! Gute Tour';
	@override String get preDepartureTitle => 'Checkliste vor dem Start';
	@override String get preDepartureCounter => '{checked}/{total} gepruft';
	@override String get preDep1 => 'Wetter der nachsten Tage prufen';
	@override String get preDep2 => 'Telefon + Powerbank laden';
	@override String get preDep3 => 'Eine nahestehende Person uber die Route informieren';
	@override String get preDep4 => 'Prufen, dass der Rucksack gut geschlossen und wasserdicht ist';
	@override String get preDep5 => 'Trinkflaschen fullen (mindestens 2L)';
	@override String get preDep6 => 'Sonnencreme und Anti-Scheuer-Creme auftragen';
	@override String get preDep7 => 'Schnursenkel und Schuhsitz prufen';
	@override String get preDep8 => 'Offline-Karten herunterladen';
	@override String get bagOk => 'RUCKSACK OK — STARTBEREIT';
	@override String get validateBag => 'RUCKSACK BESTATIGEN';
	@override String get cancelValidation => 'BESTATIGUNG AUFHEBEN';
	@override String get shoppingListButton => 'EINKAUFSLISTE';
	@override String get shareGroup => 'MIT DER GRUPPE TEILEN';
	@override String get exportList => 'LISTE EXPORTIEREN';
	@override String get bagValidTitle => 'Rucksack bestatigt';
	@override String get bagValidBody => 'Alle {total} Pflichtartikel sind im Rucksack.\n\nGesamtgewicht: {weight} kg ({pct}% des Korpergewichts)\n\nBist du sicher, dass dein Rucksack fertig ist?';
	@override String get checkAgain => 'Nochmal prufen';
	@override String get yesBagOk => 'Ja, Rucksack OK';
	@override String get bagValidatedSnack => 'Rucksack bestatigt!';
	@override String get validationCancelledSnack => 'Bestatigung aufgehoben — du kannst deine Ausrustung andern.';
	@override String get missingTitle => 'Fehlende Ausrustung';
	@override String get missingBody => '{checked}/{total} Pflichtartikel angehakt.';
	@override String get missingList => 'Es fehlt:';
	@override String get understood => 'Verstanden';
	@override String get validateAnyway => 'Trotzdem bestatigen';
	@override String get bagValidatedMissingSnack => 'Rucksack bestatigt (mit fehlenden Artikeln)!';
	@override String get shareGroupHint => 'Tritt einer Gruppe bei, um deine Checkliste zu teilen.';
}

// Path: weather.source
class _Translations$weather$source$de extends Translations$weather$source$fr {
	_Translations$weather$source$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get api => 'Live-Daten';
	@override String get cache => 'Gespeicherte Daten';
	@override String get offline => 'Offline';
	@override String get demo => 'Demodaten';
}

// Path: weather.recommendation
class _Translations$weather$recommendation$de extends Translations$weather$recommendation$fr {
	_Translations$weather$recommendation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get ok => 'Günstige Bedingungen';
	@override String get watch => 'Vorsicht geboten';
	@override String get danger => 'Ungünstige Bedingungen';
}

// Path: weather.alert
class _Translations$weather$alert$de extends Translations$weather$alert$fr {
	_Translations$weather$alert$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$weather$alert$storm$de storm = _Translations$weather$alert$storm$de._(_root);
	@override late final _Translations$weather$alert$wind$de wind = _Translations$weather$alert$wind$de._(_root);
	@override late final _Translations$weather$alert$rain$de rain = _Translations$weather$alert$rain$de._(_root);
	@override late final _Translations$weather$alert$snow$de snow = _Translations$weather$alert$snow$de._(_root);
	@override late final _Translations$weather$alert$uv$de uv = _Translations$weather$alert$uv$de._(_root);
	@override late final _Translations$weather$alert$fire$de fire = _Translations$weather$alert$fire$de._(_root);
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

// Path: health.field
class _Translations$health$field$de extends Translations$health$field$fr {
	_Translations$health$field$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Blutgruppe';
	@override String get allergies => 'Allergien';
	@override String get treatments => 'Aktuelle Behandlungen';
	@override String get doctor => 'Hausarzt';
	@override String get insurance => 'Versicherungsnr. / Krankenkasse';
}

// Path: health.hint
class _Translations$health$hint$de extends Translations$health$hint$fr {
	_Translations$health$hint$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'z. B. A+, O-, AB+';
	@override String get allergies => 'z. B. Penicillin, Erdnüsse';
	@override String get treatments => 'z. B. Levothyrox 50 mg/Tag';
	@override String get doctor => 'z. B. Dr. Müller +49 30 xxxx xxxx';
	@override String get insurance => 'z. B. Europäische Krankenversicherungskarte';
}

// Path: health.a11y
class _Translations$health$a11y$de extends Translations$health$a11y$fr {
	_Translations$health$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get form => 'Formular für Gesundheitsinformationen';
	@override String get saveButton => 'Gesundheitsinformationen speichern';
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

// Path: programme.stats
class _Translations$programme$stats$de extends Translations$programme$stats$fr {
	_Translations$programme$stats$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distanz';
	@override String get elevation => 'Aufstieg';
	@override String get days => 'Tage';
	@override String get stages => 'Etappen';
	@override String get restCount => '{count} Ruhe';
}

// Path: programme.legend
class _Translations$programme$legend$de extends Translations$programme$legend$fr {
	_Translations$programme$legend$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Leicht';
	@override String get moderate => 'Mittel';
	@override String get hard => 'Schwer';
	@override String get extreme => 'Extrem';
}

// Path: programme.actions
class _Translations$programme$actions$de extends Translations$programme$actions$fr {
	_Translations$programme$actions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get merge => 'Zusammenlegen';
	@override String get split => 'Aufteilen';
	@override String get rest => 'Ruhe';
	@override String get removeRest => 'Diesen Ruhetag entfernen';
}

// Path: programme.mergeBlocked
class _Translations$programme$mergeBlocked$de extends Translations$programme$mergeBlocked$fr {
	_Translations$programme$mergeBlocked$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get noNext => 'Kein Folgetag';
	@override String get rest => 'Zusammenlegen mit Ruhetag nicht möglich';
	@override String get tooLong => 'Zu lang: {hours}h (max. {max}h/Tag)';
}

// Path: programme.replanDialog
class _Translations$programme$replanDialog$de extends Translations$programme$replanDialog$fr {
	_Translations$programme$replanDialog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Neu planen';
	@override String get message => 'Die Neuplanung setzt Ihr Programm zurück.\nIhre Ruhetage bleiben an denselben Positionen erhalten.';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'Neu planen';
}

// Path: programme.empty
class _Translations$programme$empty$de extends Translations$programme$empty$fr {
	_Translations$programme$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Richten Sie zuerst Ihre Route ein';
	@override String get message => 'Wählen Sie Route und Dauer, um Ihr Programm zu erstellen.';
	@override String get action => 'ROUTE EINRICHTEN';
}

// Path: programme.info
class _Translations$programme$info$de extends Translations$programme$info$fr {
	_Translations$programme$info$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programm';
	@override late final _Translations$programme$info$days$de days = _Translations$programme$info$days$de._(_root);
	@override late final _Translations$programme$info$reorder$de reorder = _Translations$programme$info$reorder$de._(_root);
	@override late final _Translations$programme$info$rest$de rest = _Translations$programme$info$rest$de._(_root);
	@override late final _Translations$programme$info$mergeSplit$de mergeSplit = _Translations$programme$info$mergeSplit$de._(_root);
	@override late final _Translations$programme$info$colors$de colors = _Translations$programme$info$colors$de._(_root);
	@override String get note => 'Das Höhenprofil unten zeigt den Aufstieg jedes Tages.';
	@override String get close => 'Verstanden!';
}

// Path: weather.alert.storm
class _Translations$weather$alert$storm$de extends Translations$weather$alert$storm$fr {
	_Translations$weather$alert$storm$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Gewitter erwartet';
	@override String desc({required Object condition}) => '${condition}. Meiden Sie Grate und exponierte Bereiche.';
}

// Path: weather.alert.wind
class _Translations$weather$alert$wind$de extends Translations$weather$alert$wind$fr {
	_Translations$weather$alert$wind$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Starker Wind';
	@override String desc({required Object value}) => 'Böen bis ${value} km/h. Vorsicht an exponierten Stellen.';
}

// Path: weather.alert.rain
class _Translations$weather$alert$rain$de extends Translations$weather$alert$rain$fr {
	_Translations$weather$alert$rain$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Starke Niederschläge';
	@override String desc({required Object value}) => '${value} mm erwartet. Gefahr rutschiger Wege und Wildbäche.';
}

// Path: weather.alert.snow
class _Translations$weather$alert$snow$de extends Translations$weather$alert$snow$fr {
	_Translations$weather$alert$snow$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Schnee erwartet';
	@override String desc({required Object condition}) => '${condition}. Geeignete Ausrüstung erforderlich.';
}

// Path: weather.alert.uv
class _Translations$weather$alert$uv$de extends Translations$weather$alert$uv$fr {
	_Translations$weather$alert$uv$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sehr hohe UV-Strahlung';
	@override String desc({required Object value}) => 'UV-Index ${value}. Maximaler Sonnenschutz empfohlen.';
}

// Path: weather.alert.fire
class _Translations$weather$alert$fire$de extends Translations$weather$alert$fire$fr {
	_Translations$weather$alert$fire$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Brandgefahr';
	@override String desc({required Object value}) => '${value}°C erwartet. Hohe Brandgefahr.';
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

// Path: programme.info.days
class _Translations$programme$info$days$de extends Translations$programme$info$days$fr {
	_Translations$programme$info$days$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trektage';
	@override String get body => 'Jede Zeile = ein Tag. Tippen für die vollständigen Details.';
}

// Path: programme.info.reorder
class _Translations$programme$info$reorder$de extends Translations$programme$info$reorder$fr {
	_Translations$programme$info$reorder$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Neu ordnen';
	@override String get body => 'Ziehen Sie den Griff rechts, um die Reihenfolge der Tage zu ändern.';
}

// Path: programme.info.rest
class _Translations$programme$info$rest$de extends Translations$programme$info$rest$fr {
	_Translations$programme$info$rest$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ruhetag';
	@override String get body => 'Fügen Sie einen Erholungstag zwischen zwei Etappen ein.';
}

// Path: programme.info.mergeSplit
class _Translations$programme$info$mergeSplit$de extends Translations$programme$info$mergeSplit$fr {
	_Translations$programme$info$mergeSplit$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Zusammenlegen / Aufteilen';
	@override String get body => 'Fassen Sie Etappen zusammen oder teilen Sie sie nach Ihrem Tempo.';
}

// Path: programme.info.colors
class _Translations$programme$info$colors$de extends Translations$programme$info$colors$fr {
	_Translations$programme$info$colors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Farben';
	@override String get body => 'Grün = leicht, Orange = mittel, Rot = schwer (Distanz + Aufstieg).';
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
			'nav.checklist' => 'Ausrustung & Rucksack',
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
			'hub.weather.alertStorm' => 'Gewitterwarnung',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Trek starten',
			'hub.sections.prepare' => 'Vorbereiten',
			'hub.sections.hike' => 'Wandern',
			'hub.sections.info' => 'Informationen',
			'hub.sections.after' => 'Nach dem Trek',
			'hub.cards.feasibility' => 'Machbarkeit',
			'hub.cards.feasibilitySub' => 'Bewerten Sie Ihr Niveau',
			'hub.cards.itinerary' => 'Route',
			'hub.cards.itinerarySub' => 'Ihre Etappen im Detail',
			'hub.cards.programme' => 'Programm',
			'hub.cards.programmeSub' => 'Etappen aufteilen',
			'hub.cards.checklist' => 'Ausrustung & Rucksack',
			'hub.cards.checklistSub' => 'Bereite deinen Rucksack vor',
			'hub.cards.training' => 'Körperliche Vorbereitung',
			'hub.cards.trainingSub' => 'Ihr Trainingsprogramm',
			'hub.cards.offline' => 'Wege entdecken',
			'hub.cards.offlineSub' => 'Katalog durchsuchen',
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
			'hub.cards.townGuides' => 'Ortsführer',
			'hub.cards.townGuidesSub' => 'Praktische Infos zu den Etappen',
			'hub.cards.recap' => 'Zusammenfassung',
			'hub.cards.recapSub' => 'Ihr Abenteuer in Kürze',
			'hub.cards.diploma' => 'Diplom',
			'hub.cards.diplomaSub' => 'Ihre Abschlussurkunde',
			'hub.fab.feedback' => 'Feedback geben',
			'hub.fab.sos' => 'SOS',
			'map.title' => 'Wanderkarte',
			'map.loading' => 'Strecke wird geladen...',
			'map.noTrack' => 'Keine Strecke verfügbar',
			'map.viewMap' => 'Karte anzeigen',
			'stage.distance' => 'Entfernung',
			'stage.elevation' => 'Höhenunterschied',
			'stage.elevationGain' => 'Höhenmeter aufwärts',
			'stage.elevationLoss' => 'Höhenmeter abwärts',
			'stage.duration' => 'Geschätzte Dauer',
			'stage.description' => 'Beschreibung',
			'stage.coordinates' => 'Koordinaten',
			'stage.pois' => 'Sehenswürdigkeiten',
			'stage.difficulty.easy' => 'Leicht',
			'stage.difficulty.moderate' => 'Mittel',
			'stage.difficulty.hard' => 'Schwer',
			'stage.difficulty.expert' => 'Experte',
			'stage.difficulty.extreme' => 'Extrem',
			'stage.remaining' => '{distance} km verbleibend',
			'stage.arrived' => 'Sie sind angekommen!',
			'stage.altitudeProfile' => 'Hohenprofil',
			'stage.statistics' => 'Statistiken',
			'stage.loading' => 'Laden...',
			'stage.loadingList' => 'Etappen werden geladen...',
			'stage.dPlus' => 'D+',
			'stage.dMinus' => 'D-',
			'stage.difficultyLabel' => 'Schwierigkeit',
			'trail.stages' => 'Etappen',
			'trail.totalDistance' => 'Gesamtstrecke',
			'trail.totalElevation' => 'Gesamthöhenmeter',
			'poi.shelter' => 'Schutzhütte',
			'poi.water' => 'Wasserquelle',
			'poi.viewpoint' => 'Aussichtspunkt',
			'poi.campsite' => 'Biwakplatz',
			'poi.restaurant' => 'Restaurant',
			'poi.emergency' => 'Notfall',
			'poi.danger' => 'Gefahr',
			'poi.shop' => 'Geschäft',
			'poi.filter' => 'Sehenswürdigkeiten filtern',
			'poi.altitude' => 'Höhe',
			'poi.hours' => 'Öffnungszeiten',
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
			'itinerary.title' => 'Route',
			'itinerary.subtitle' => 'Ihre Etappen, Tag fuer Tag',
			'itinerary.empty' => 'Keine Etappe verfuegbar',
			'itinerary.emptyHint' => 'Wegdaten sind nicht geladen.',
			'itinerary.loading' => 'Route wird geladen...',
			'itinerary.error' => 'Route kann nicht geladen werden',
			'itinerary.day' => 'Tag',
			'itinerary.stage' => 'Etappe',
			'itinerary.stages' => 'Etappen',
			'itinerary.totalDistance' => 'Distanz',
			'itinerary.totalElevation' => 'D+',
			'itinerary.restDay' => 'Ruhetag',
			'itinerary.viewStage' => 'Etappe ansehen',
			'itinerary.openMap' => 'Auf Karte ansehen',
			'itinerary.stageCount' => '{count} Etappen',
			'tracking.start' => 'Starten',
			'tracking.pause' => 'Pause',
			'tracking.resume' => 'Fortsetzen',
			'tracking.stop' => 'Stoppen',
			'tracking.distance' => 'Entfernung',
			'tracking.elevation' => 'Hohenmeter',
			'tracking.speed' => 'Geschwindigkeit',
			'tracking.time' => 'Zeit',
			'tracking.confirmStop' => 'Tracking stoppen?',
			'tracking.dPlus' => 'D+',
			'tracking.stopSaveProgress' => 'Ihr Fortschritt wird gespeichert.',
			'tracking.cancel' => 'Abbrechen',
			'tracking.stopButton' => 'Stopp',
			'checklist.title' => 'Ausrustung & Rucksack',
			'checklist.subtitle' => 'Packen Sie Ihren Rucksack',
			'checklist.progress' => '{checked}/{total} gepackt',
			'checklist.complete' => 'Checkliste vollständig!',
			'checklist.reset' => 'Zurücksetzen',
			'checklist.resetConfirm' => 'Checkliste zurücksetzen?',
			'checklist.resetDescription' => 'Alle Elemente werden abgehakt.',
			'checklist.cancel' => 'Abbrechen',
			'checklist.confirm' => 'Bestätigen',
			'checklist.categories.carrying' => 'Rucksack & Tragen',
			'checklist.categories.sleeping' => 'Schlafen',
			'checklist.categories.clothing' => 'Kleidung',
			'checklist.categories.cooking' => 'Kochen',
			'checklist.categories.foodWater' => 'Essen & Wasser',
			'checklist.categories.hygiene' => 'Hygiene',
			'checklist.categories.firstAid' => 'Erste-Hilfe-Set',
			'checklist.categories.electronics' => 'Elektronik',
			'checklist.categories.women' => 'Frauen',
			'checklist.categories.men' => 'Manner',
			'checklist.categories.misc' => 'Sonstiges',
			'checklist.categories.dog' => 'Hund',
			'checklist.items.backpack' => 'Rucksack 35-45L',
			'checklist.items.rainCover' => 'Rucksack-Regenhulle',
			'checklist.items.dryBags' => 'Packsacke (dry bags)',
			'checklist.items.sleepingBag' => 'Schlafsack (0-5C)',
			'checklist.items.sleepingPad' => 'Isomatte / Unterlage',
			'checklist.items.sleepingLiner' => 'Huttenschlafsack / Inlett',
			'checklist.items.pillow' => 'Aufblasbares Kissen',
			'checklist.items.hikingPants' => 'Wanderhose',
			'checklist.items.rainPants' => 'Regenhose',
			'checklist.items.shorts' => 'Shorts',
			'checklist.items.techTshirt' => 'Funktions-T-Shirt',
			'checklist.items.fleece' => 'Fleece / leichte Daune',
			'checklist.items.rainJacket' => 'Regenjacke Gore-Tex',
			'checklist.items.underwear' => 'Unterwasche',
			'checklist.items.hikingSocks' => 'Wandersocken',
			'checklist.items.gaiters' => 'Gamaschen',
			'checklist.items.hat' => 'Hut / Kappe',
			'checklist.items.beanie' => 'Mutze',
			'checklist.items.buff' => 'Buff / Halstuch',
			'checklist.items.lightGloves' => 'Leichte Handschuhe',
			'checklist.items.hikingBoots' => 'Wanderschuhe (getragen)',
			'checklist.items.campSandals' => 'Camp-Sandalen',
			'checklist.items.stove' => 'Kocher (PocketRocket)',
			'checklist.items.gasCanister' => 'Gaskartusche',
			'checklist.items.cookpot' => 'Kochtopf / Geschirr',
			'checklist.items.cutlery' => 'Besteck (Loffel, Messer)',
			'checklist.items.waterBottle' => 'Trinkflasche / Blase 2L',
			'checklist.items.knife' => 'Klappmesser',
			'checklist.items.lighter' => 'Feuerzeug',
			'checklist.items.energyBars' => 'Energieriegel',
			'checklist.items.driedFruits' => 'Trockenfruchte',
			'checklist.items.freezeDriedMeal' => 'Gefriergetrocknete Mahlzeit',
			'checklist.items.waterPurification' => 'Wasser-Entkeimungstabletten',
			'checklist.items.electrolytes' => 'Elektrolyte',
			'checklist.items.carriedWater' => 'Getragenes Wasser (1L = 1000g)',
			'checklist.items.soap' => 'Biologisch abbaubare Seife',
			'checklist.items.toothbrush' => 'Zahnburste',
			'checklist.items.toothpaste' => 'Zahnpasta',
			'checklist.items.microfiberTowel' => 'Mikrofaser-Handtuch',
			'checklist.items.toiletPaper' => 'Toilettenpapier',
			'checklist.items.trashBag' => 'Mullbeutel',
			'checklist.items.antiChafingCream' => 'Anti-Scheuer-Creme',
			'checklist.items.earplugs' => 'Ohrstopsel',
			'checklist.items.bandages' => 'Sortierte Pflaster',
			'checklist.items.sterileCompresses' => 'Sterile Kompressen',
			'checklist.items.elasticBandage' => 'Elastische Binde',
			'checklist.items.disinfectant' => 'Desinfektionsmittel (50ml)',
			'checklist.items.painkillers' => 'Paracetamol / Ibuprofen',
			'checklist.items.sunscreen' => 'Sonnencreme SPF50',
			'checklist.items.lipBalm' => 'Lippenbalsam SPF30',
			'checklist.items.emergencyBlanket' => 'Rettungsdecke',
			'checklist.items.tickRemover' => 'Zeckenzange',
			'checklist.items.whistle' => 'Notfallpfeife',
			'checklist.items.strapping' => 'Tapeverband / Strapping',
			'checklist.items.eyeDrops' => 'Augentropfen',
			'checklist.items.antiDiarrheal' => 'Durchfallmittel',
			'checklist.items.antihistamine' => 'Antihistaminikum',
			'checklist.items.kneeTape' => 'Knie-Tape',
			'checklist.items.phone' => 'Telefon',
			'checklist.items.powerBank' => 'Powerbank 20000mAh',
			'checklist.items.usbCable' => 'USB-Kabel',
			'checklist.items.headlamp' => 'Stirnlampe',
			'checklist.items.spareBatteries' => 'Ersatzbatterien',
			'checklist.items.periodProtection' => 'Periodenschutz',
			'checklist.items.sportsBra' => 'Sport-BH',
			'checklist.items.intimateWipes' => 'Intimtucher',
			'checklist.items.peeCloth' => 'Pee-Cloth',
			'checklist.items.razor' => 'Rasierer',
			'checklist.items.techBoxers' => 'Funktions-Boxershorts',
			'checklist.items.hikingPoles' => 'Wanderstocke (getragen)',
			'checklist.items.sunglasses' => 'Sonnenbrille',
			'checklist.items.trailMap' => 'Karte / Topo-Guide',
			'checklist.items.spareLaces' => 'Ersatzschnursenkel',
			'checklist.items.needleThread' => 'Nadel + Faden',
			'checklist.items.ductTape' => 'Klebeband',
			'checklist.items.ziplocBags' => 'Ziploc-Beutel',
			'checklist.items.cord' => 'Schnur',
			'checklist.items.cash' => 'Bargeld',
			'checklist.items.dogBowl' => 'Faltbarer Napf',
			'checklist.items.dogLeash' => 'Leine',
			'checklist.items.dogKibble' => 'Trockenfutter (Ration/Tag)',
			'checklist.items.dogBooties' => 'Schutzstiefel',
			'checklist.items.dogVaccineBook' => 'Impfpass',
			'checklist.items.dogPoopBags' => 'Kotbeutel',
			'checklist.items.swimsuit' => 'Badeanzug',
			'checklist.essential' => 'Wesentlich',
			'checklist.weight.title' => 'Rucksackgewicht',
			'checklist.weight.total' => 'Gesamtgewicht',
			'checklist.weight.bodyWeight' => 'Korpergewicht:',
			'checklist.weight.ratio' => 'Rucksack / Korper',
			'checklist.weight.perItem' => 'Gewicht pro Artikel',
			'checklist.weight.edit' => 'Gewicht andern',
			'checklist.weight.grams' => 'g',
			'checklist.weight.kilograms' => 'kg',
			'checklist.weight.adviceUltraLight' => 'Ultraleichter Rucksack — ideal furs Trekking',
			'checklist.weight.adviceLight' => 'Ultraleichter Rucksack — ideal furs Trekking',
			'checklist.weight.adviceOk' => 'Gut ausbalancierter Rucksack',
			'checklist.weight.adviceHeavy' => 'OK aber schwer — erwage zu erleichtern',
			'checklist.weight.adviceTooHeavy' => 'Achtung Knie! Rucksack erleichtern',
			'checklist.weight.adviceDanger' => 'Verletzungsgefahr — jetzt erleichtern!',
			'checklist.weight.itemWeight' => 'Artikelgewicht',
			'checklist.weight.cancel' => 'Abbrechen',
			'checklist.weight.save' => 'Speichern',
			'checklist.weight.gaugeUltraLight' => 'Ultraleicht, perfekt!',
			'checklist.weight.gaugeOk' => 'Gut, ausbalanciert',
			'checklist.weight.gaugeHeavy' => 'OK aber schwer',
			'checklist.weight.gaugeWarn' => 'Achtung Knie!',
			'checklist.weight.gaugeDanger' => 'Verletzungsgefahr!',
			'checklist.weight.percentOfWeight' => '{pct}% des Korpergewichts',
			'checklist.weight.gaugeObjective' => 'Max. Ziel: < 15% in Hutten, < 20% autark',
			'checklist.weight.itemsChecked' => '{checked} / {total} Artikel angehakt',
			'checklist.ui.title' => 'Ausrustung & Rucksack',
			'checklist.ui.requirementRequired' => 'Pflicht',
			'checklist.ui.addItem' => 'Artikel hinzufugen',
			'checklist.ui.addItemTitle' => 'Artikel hinzufugen',
			'checklist.ui.fieldName' => 'Name',
			'checklist.ui.fieldWeightGrams' => 'Gewicht (Gramm)',
			'checklist.ui.add' => 'Hinzufugen',
			'checklist.ui.editWeightTitle' => 'Gewicht andern',
			'checklist.ui.editCustomTitle' => 'Eigenen Artikel bearbeiten',
			'checklist.ui.modify' => 'Bearbeiten',
			'checklist.ui.delete' => 'Loschen',
			'checklist.ui.deleteItemTitle' => 'Diesen Artikel loschen?',
			'checklist.ui.deleteItemBody' => 'Der Artikel "{name}" wird endgultig geloscht.',
			'checklist.ui.requiredWarnTitle' => 'Pflichtausrustung',
			'checklist.ui.requiredWarnBody' => 'Diese Ausrustung ist aus Sicherheitsgrunden Pflicht (angelehnt an UTMB-Regeln). Wirklich entfernen?',
			'checklist.ui.keep' => 'Behalten',
			'checklist.ui.removeAnyway' => 'Trotzdem entfernen',
			'checklist.ui.reduceQuantity' => 'Menge verringern',
			'checklist.ui.increaseQuantity' => 'Menge erhohen',
			'checklist.ui.addToShoppingList' => 'Zur Einkaufsliste hinzufugen',
			'checklist.ui.removeFromShoppingList' => 'Von der Liste entfernen',
			'checklist.ui.help' => 'Hilfe',
			'checklist.ui.shoppingListTitle' => 'Einkaufsliste',
			'checklist.ui.shoppingListEmpty' => 'Deine Einkaufsliste ist leer. Fuge Artikel mit dem Warenkorb-Button hinzu.',
			'checklist.ui.shoppingToBuy' => 'Zu kaufen',
			'checklist.ui.shoppingPurchased' => 'Bereits gekauft',
			'checklist.ui.share' => 'TEILEN',
			'checklist.ui.infoTitle' => 'Ausrustung & Rucksack',
			'checklist.ui.infoCheckTitle' => 'Artikel anhaken',
			'checklist.ui.infoCheckBody' => 'Hake an, was du mitnimmst — das Gewicht wird oben neu berechnet.',
			'checklist.ui.infoRequiredTitle' => 'Pflicht',
			'checklist.ui.infoRequiredBody' => 'Artikel mit Schloss = Vorschrift (Pfeife, Lampe, Rettungsdecke).',
			'checklist.ui.infoGaugeTitle' => 'Gewichtsanzeige',
			'checklist.ui.infoGaugeBody' => 'Ziel: Rucksack < 15% deines Gewichts. Grun = OK, Orange = Achtung, Rot = zu schwer.',
			'checklist.ui.infoAddTitle' => 'Hinzufugen',
			'checklist.ui.infoAddBody' => 'Der +-Button unten in jeder Kategorie fur eigene Artikel.',
			'checklist.ui.infoValidateBody' => 'Bestatige, wenn dein Rucksack fertig ist — ein Haken erscheint auf der Startseite.',
			'checklist.ui.infoUnderstood' => 'Verstanden!',
			'checklist.ui.prepTitle' => 'Rucksack packen',
			'checklist.ui.prepCounter' => '{prepared} / {total} Artikel gepackt',
			'checklist.ui.prepAllReady' => 'Alles bereit! Gute Tour',
			'checklist.ui.preDepartureTitle' => 'Checkliste vor dem Start',
			'checklist.ui.preDepartureCounter' => '{checked}/{total} gepruft',
			'checklist.ui.preDep1' => 'Wetter der nachsten Tage prufen',
			'checklist.ui.preDep2' => 'Telefon + Powerbank laden',
			'checklist.ui.preDep3' => 'Eine nahestehende Person uber die Route informieren',
			'checklist.ui.preDep4' => 'Prufen, dass der Rucksack gut geschlossen und wasserdicht ist',
			'checklist.ui.preDep5' => 'Trinkflaschen fullen (mindestens 2L)',
			'checklist.ui.preDep6' => 'Sonnencreme und Anti-Scheuer-Creme auftragen',
			'checklist.ui.preDep7' => 'Schnursenkel und Schuhsitz prufen',
			'checklist.ui.preDep8' => 'Offline-Karten herunterladen',
			'checklist.ui.bagOk' => 'RUCKSACK OK — STARTBEREIT',
			'checklist.ui.validateBag' => 'RUCKSACK BESTATIGEN',
			'checklist.ui.cancelValidation' => 'BESTATIGUNG AUFHEBEN',
			'checklist.ui.shoppingListButton' => 'EINKAUFSLISTE',
			'checklist.ui.shareGroup' => 'MIT DER GRUPPE TEILEN',
			'checklist.ui.exportList' => 'LISTE EXPORTIEREN',
			'checklist.ui.bagValidTitle' => 'Rucksack bestatigt',
			'checklist.ui.bagValidBody' => 'Alle {total} Pflichtartikel sind im Rucksack.\n\nGesamtgewicht: {weight} kg ({pct}% des Korpergewichts)\n\nBist du sicher, dass dein Rucksack fertig ist?',
			'checklist.ui.checkAgain' => 'Nochmal prufen',
			'checklist.ui.yesBagOk' => 'Ja, Rucksack OK',
			'checklist.ui.bagValidatedSnack' => 'Rucksack bestatigt!',
			'checklist.ui.validationCancelledSnack' => 'Bestatigung aufgehoben — du kannst deine Ausrustung andern.',
			'checklist.ui.missingTitle' => 'Fehlende Ausrustung',
			'checklist.ui.missingBody' => '{checked}/{total} Pflichtartikel angehakt.',
			'checklist.ui.missingList' => 'Es fehlt:',
			'checklist.ui.understood' => 'Verstanden',
			'checklist.ui.validateAnyway' => 'Trotzdem bestatigen',
			'checklist.ui.bagValidatedMissingSnack' => 'Rucksack bestatigt (mit fehlenden Artikeln)!',
			'checklist.ui.shareGroupHint' => 'Tritt einer Gruppe bei, um deine Checkliste zu teilen.',
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
			'weather.today' => 'Heute',
			'weather.tomorrow' => 'Morgen',
			'weather.dayPlus2' => 'Übermorgen',
			'weather.allStages' => 'Alle Etappen',
			'weather.noForecast' => 'Keine Vorhersage verfügbar.',
			'weather.stageLabel' => ({required Object number}) => 'Etappe ${number}',
			'weather.stormAlertsTitle' => 'Gewitterwarnungen',
			'weather.stormAlertsToggleOn' => 'Gewitterwarnungen aktiviert',
			'weather.stormAlertsToggleOff' => 'Gewitterwarnungen deaktiviert',
			'weather.lastUpdate' => ({required Object date}) => 'Aktualisiert ${date}',
			'weather.guideTitle' => 'Das Wetter verstehen',
			'weather.guideBody' => 'Die Vorhersage umfasst 7 Tage für jede Etappe. Achten Sie auf Gewitter- und Windwarnungen: In den Bergen ändert sich das Wetter schnell. Ohne Netz werden die zuletzt gespeicherten Daten angezeigt.',
			'weather.source.api' => 'Live-Daten',
			'weather.source.cache' => 'Gespeicherte Daten',
			'weather.source.offline' => 'Offline',
			'weather.source.demo' => 'Demodaten',
			'weather.recommendation.ok' => 'Günstige Bedingungen',
			'weather.recommendation.watch' => 'Vorsicht geboten',
			'weather.recommendation.danger' => 'Ungünstige Bedingungen',
			'weather.alert.storm.title' => 'Gewitter erwartet',
			'weather.alert.storm.desc' => ({required Object condition}) => '${condition}. Meiden Sie Grate und exponierte Bereiche.',
			'weather.alert.wind.title' => 'Starker Wind',
			'weather.alert.wind.desc' => ({required Object value}) => 'Böen bis ${value} km/h. Vorsicht an exponierten Stellen.',
			'weather.alert.rain.title' => 'Starke Niederschläge',
			'weather.alert.rain.desc' => ({required Object value}) => '${value} mm erwartet. Gefahr rutschiger Wege und Wildbäche.',
			'weather.alert.snow.title' => 'Schnee erwartet',
			'weather.alert.snow.desc' => ({required Object condition}) => '${condition}. Geeignete Ausrüstung erforderlich.',
			'weather.alert.uv.title' => 'Sehr hohe UV-Strahlung',
			'weather.alert.uv.desc' => ({required Object value}) => 'UV-Index ${value}. Maximaler Sonnenschutz empfohlen.',
			'weather.alert.fire.title' => 'Brandgefahr',
			'weather.alert.fire.desc' => ({required Object value}) => '${value}°C erwartet. Hohe Brandgefahr.',
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
			'diploma.lockedTitle' => 'Diplom gesperrt',
			'diploma.lockedMessage' => 'Absolviere deine gesamte Route, um dein Finisher-Diplom freizuschalten.',
			'diploma.labelIntegral' => 'Gesamte Route',
			'diploma.labelPartial' => 'Teilroute',
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
			'appearance.title' => 'Erscheinungsbild',
			'appearance.subtitle' => 'Wähle das Design der App',
			'appearance.skinSentierVivant' => 'Lebendiger Pfad',
			_ => null,
		} ?? switch (path) {
			'appearance.skinSentierVivantDesc' => 'Modern und farbenfroh, die Wegfarbe im Mittelpunkt',
			'appearance.skinTopographique' => 'Topografisch',
			'appearance.skinTopographiqueDesc' => 'Stil einer Wanderkarte, Daten im Vordergrund',
			'appearance.skinGrandAir' => 'Freiluft',
			'appearance.skinGrandAirDesc' => 'Bildschirmfüllende Fotos, Abenteuertagebuch-Look',
			'appearance.unavailableOnTrail' => 'Auf diesem Weg nicht verfügbar',
			'appearance.changeSkin' => 'Design wechseln',
			'appearance.selected' => 'Ausgewählt',
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
			'health.title' => 'Gesundheitsinformationen',
			'health.privacyBanner' => 'Diese Daten bleiben auf Ihrem Telefon. Sie werden niemals über das Internet gesendet.',
			'health.field.bloodType' => 'Blutgruppe',
			'health.field.allergies' => 'Allergien',
			'health.field.treatments' => 'Aktuelle Behandlungen',
			'health.field.doctor' => 'Hausarzt',
			'health.field.insurance' => 'Versicherungsnr. / Krankenkasse',
			'health.hint.bloodType' => 'z. B. A+, O-, AB+',
			'health.hint.allergies' => 'z. B. Penicillin, Erdnüsse',
			'health.hint.treatments' => 'z. B. Levothyrox 50 mg/Tag',
			'health.hint.doctor' => 'z. B. Dr. Müller +49 30 xxxx xxxx',
			'health.hint.insurance' => 'z. B. Europäische Krankenversicherungskarte',
			'health.save' => 'Speichern',
			'health.saving' => 'Speichern…',
			'health.saved' => 'Informationen gespeichert',
			'health.emergencyHint' => 'Zeigen Sie diesen Bildschirm im Notfall den Rettungskräften.',
			'health.entryTitle' => 'Meine Gesundheitsdaten',
			'health.entrySubtitle' => 'Den Rettungskräften zeigen (bleiben auf dem Telefon)',
			'health.a11y.form' => 'Formular für Gesundheitsinformationen',
			'health.a11y.saveButton' => 'Gesundheitsinformationen speichern',
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
			'bootstrap.loading' => 'Ihre Wanderung wird vorbereitet…',
			'recap.title' => 'Mein Abenteuer',
			'recap.lockedTitle' => 'Verfugbar am Ende der Tour',
			'recap.lockedMessage' => 'Beende oder brich deine Route ab, um die Zusammenfassung deines Abenteuers zu sehen.',
			'recap.finisherTitle' => 'Gluckwunsch!',
			'recap.finisherSubtitle' => 'Du hast deine Route abgeschlossen',
			'recap.partialTitle' => 'Deine Teilroute',
			'recap.partialSubtitle' => 'Dein Abenteuer bleibt gespeichert',
			'recap.statsSection' => 'Statistiken',
			'recap.traceSection' => 'Deine Spur',
			'recap.noTrace' => 'Keine GPS-Spur verfugbar',
			'recap.stages' => '{done} / {total} Etappen gelaufen',
			'recap.distance' => '{km} km zuruckgelegt',
			'recap.elevation' => '{meters} m Hohenmeter',
			'recap.duration' => '{days} Tage',
			'recap.dates' => 'Vom {start} bis {end}',
			'recap.viewDiploma' => 'Mein Diplom ansehen',
			'recap.noData' => 'Noch keine Routendaten zum Anzeigen.',
			'programme.title' => 'Programm',
			'programme.helpTooltip' => 'Hilfe',
			'programme.stats.distance' => 'Distanz',
			'programme.stats.elevation' => 'Aufstieg',
			'programme.stats.days' => 'Tage',
			_ => null,
		} ?? switch (path) {
			'programme.stats.stages' => 'Etappen',
			'programme.stats.restCount' => '{count} Ruhe',
			'programme.legend.easy' => 'Leicht',
			'programme.legend.moderate' => 'Mittel',
			'programme.legend.hard' => 'Schwer',
			'programme.legend.extreme' => 'Extrem',
			'programme.restDay' => 'Ruhetag',
			'programme.restDayLabel' => 'R',
			'programme.actions.merge' => 'Zusammenlegen',
			'programme.actions.split' => 'Aufteilen',
			'programme.actions.rest' => 'Ruhe',
			'programme.actions.removeRest' => 'Diesen Ruhetag entfernen',
			'programme.mergeBlocked.noNext' => 'Kein Folgetag',
			'programme.mergeBlocked.rest' => 'Zusammenlegen mit Ruhetag nicht möglich',
			'programme.mergeBlocked.tooLong' => 'Zu lang: {hours}h (max. {max}h/Tag)',
			'programme.replan' => 'Neu planen',
			'programme.replanButton' => 'NEU PLANEN',
			'programme.replanDialog.title' => 'Neu planen',
			'programme.replanDialog.message' => 'Die Neuplanung setzt Ihr Programm zurück.\nIhre Ruhetage bleiben an denselben Positionen erhalten.',
			'programme.replanDialog.cancel' => 'Abbrechen',
			'programme.replanDialog.confirm' => 'Neu planen',
			'programme.validate' => 'PROGRAMM BESTÄTIGEN',
			'programme.empty.title' => 'Richten Sie zuerst Ihre Route ein',
			'programme.empty.message' => 'Wählen Sie Route und Dauer, um Ihr Programm zu erstellen.',
			'programme.empty.action' => 'ROUTE EINRICHTEN',
			'programme.info.title' => 'Programm',
			'programme.info.days.title' => 'Trektage',
			'programme.info.days.body' => 'Jede Zeile = ein Tag. Tippen für die vollständigen Details.',
			'programme.info.reorder.title' => 'Neu ordnen',
			'programme.info.reorder.body' => 'Ziehen Sie den Griff rechts, um die Reihenfolge der Tage zu ändern.',
			'programme.info.rest.title' => 'Ruhetag',
			'programme.info.rest.body' => 'Fügen Sie einen Erholungstag zwischen zwei Etappen ein.',
			'programme.info.mergeSplit.title' => 'Zusammenlegen / Aufteilen',
			'programme.info.mergeSplit.body' => 'Fassen Sie Etappen zusammen oder teilen Sie sie nach Ihrem Tempo.',
			'programme.info.colors.title' => 'Farben',
			'programme.info.colors.body' => 'Grün = leicht, Orange = mittel, Rot = schwer (Distanz + Aufstieg).',
			'programme.info.note' => 'Das Höhenprofil unten zeigt den Aufstieg jedes Tages.',
			'programme.info.close' => 'Verstanden!',
			_ => null,
		};
	}
}
