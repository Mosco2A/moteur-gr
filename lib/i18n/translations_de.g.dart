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
	@override late final _Translations$navPilote$de navPilote = _Translations$navPilote$de._(_root);
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
	@override late final _Translations$erasure$de erasure = _Translations$erasure$de._(_root);
	@override late final _Translations$moderation$de moderation = _Translations$moderation$de._(_root);
	@override late final _Translations$bootstrap$de bootstrap = _Translations$bootstrap$de._(_root);
	@override late final _Translations$recap$de recap = _Translations$recap$de._(_root);
	@override late final _Translations$programme$de programme = _Translations$programme$de._(_root);
	@override late final _Translations$calendar$de calendar = _Translations$calendar$de._(_root);
	@override late final _Translations$nuitees$de nuitees = _Translations$nuitees$de._(_root);
	@override late final _Translations$transport$de transport = _Translations$transport$de._(_root);
	@override late final _Translations$fireRisk$de fireRisk = _Translations$fireRisk$de._(_root);
	@override late final _Translations$shop$de shop = _Translations$shop$de._(_root);
	@override late final _Translations$summary$de summary = _Translations$summary$de._(_root);
	@override late final _Translations$import$de import = _Translations$import$de._(_root);
	@override late final _Translations$myTreks$de myTreks = _Translations$myTreks$de._(_root);
	@override late final _Translations$trekState$de trekState = _Translations$trekState$de._(_root);
	@override late final _Translations$hikerProfile$de hikerProfile = _Translations$hikerProfile$de._(_root);
	@override late final _Translations$walkTest$de walkTest = _Translations$walkTest$de._(_root);
	@override late final _Translations$pastHikes$de pastHikes = _Translations$pastHikes$de._(_root);
	@override late final _Translations$ffrando$de ffrando = _Translations$ffrando$de._(_root);
	@override late final _Translations$sos$de sos = _Translations$sos$de._(_root);
	@override late final _Translations$recovery$de recovery = _Translations$recovery$de._(_root);
	@override late final _Translations$common$de common = _Translations$common$de._(_root);
}

// Path: a11y
class _Translations$a11y$de extends Translations$a11y$fr {
	_Translations$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get back => 'Zurück';
	@override String get zoomIn => 'Vergrössern';
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
	@override String get sos => 'SOS-Notruf';
	@override String get mapLayers => 'Kartenebenen';
}

// Path: nav
class _Translations$nav$de extends Translations$nav$fr {
	_Translations$nav$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Start';
	@override String get map => 'Karte';
	@override String get stages => 'Etappen';
	@override String get currentStage => 'Aktuelle Etappe';
	@override String get planning => 'Planung';
	@override String get journal => 'Tagebuch';
	@override String get more => 'Mehr';
	@override String get checklist => 'Ausrüstung & Rucksack';
	@override String get feasibility => 'Machbarkeit';
	@override String get tips => 'Trek-Tipps';
	@override String get emergency => 'Notfallkontakte';
	@override String get catalog => 'Wegekatalog';
	@override String get profile => 'Profil';
	@override String get settings => 'Einstellungen';
	@override String get trailSelection => 'Weg wechseln';
	@override String get myTreks => 'Meine Touren';
	@override String get back => 'Zurück';
	@override String get home => 'Start';
}

// Path: navPilote
class _Translations$navPilote$de extends Translations$navPilote$fr {
	_Translations$navPilote$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get appTitle => 'StepWays';
	@override String get prepare => 'Vorbereiten';
	@override String get hike => 'Wandern';
	@override String get after => 'Danach';
	@override String get sos => 'SOS';
	@override String demoLockedTitle({required Object phase}) => '${phase} — nur für gekaufte Treks';
	@override String get demoLockedBody => 'Im Demomodus ist nur die Vorbereitung verfügbar. Schalten Sie diesen Trek frei, um zu wandern und Ihr Abenteuer zu erleben.';
	@override String get demoTrekMode => 'Trek-Modus simulieren (Demo)';
	@override String get exitTitle => 'App beenden?';
	@override String get exitMessage => 'Sie sind auf dem Startbildschirm. Möchten Sie die App schliessen?';
	@override String get exitConfirm => 'Beenden';
	@override String get exitCancel => 'Bleiben';
	@override String get startTrek => 'Trek starten';
	@override String get finishTrek => 'Trek beenden';
	@override String get reviewPrep => 'Vorbereitung ansehen';
	@override String get startGateSubtitle => 'Route, Datum und Programm abschließen, um zu starten';
	@override String get startAwayTitle => 'Trek starten';
	@override String startAwayBody({required Object distance}) => 'Du scheinst nicht am Startpunkt zu sein (${distance} m entfernt). Trotzdem starten?';
	@override String get startNoGpsBody => 'Standort nicht verfügbar. Trotzdem starten?';
	@override String get startConfirm => 'Trotzdem starten';
	@override String get startCancel => 'Abbrechen';
	@override String get phasePrepareSub => 'Bereiten Sie Ihren Trek vor dem Start vor';
	@override String get phaseHikeSub => 'Ihr Trek läuft';
	@override String phaseHikeInProgress({required Object trek}) => '${trek} läuft';
	@override String get phaseAfterSub => 'Erleben Sie Ihr Abenteuer noch einmal';
	@override String get phaseBanner => 'Aktuelle Phase';
	@override String get demoPreview => 'Phasenvorschau (Demo): Vorbereiten, Wandern, Danach';
	@override String get dominantHand => 'Dominante Hand';
	@override String get dominantHandDesc => 'Platziert SOS und Hauptbefehle auf Ihrer Handseite';
	@override String get dominantHandRight => 'Rechtshänder';
	@override String get dominantHandLeft => 'Linkshänder';
	@override String get weatherBannerTitle => 'Hier und jetzt';
	@override String get weatherBannerStages => 'Etappen-Wetter';
	@override String get weatherBannerUnavailable => 'Lokales Wetter nicht verfügbar';
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
	@override String get startGateHint => 'Schließe zuerst Route, Datum und Programm ab, um zu starten.';
	@override String get prepareExpand => 'Vorbereitung anzeigen';
	@override String get prepareCollapse => 'Einklappen';
	@override late final _Translations$hub$sections$de sections = _Translations$hub$sections$de._(_root);
	@override late final _Translations$hub$cards$de cards = _Translations$hub$cards$de._(_root);
	@override late final _Translations$hub$fab$de fab = _Translations$hub$fab$de._(_root);
	@override late final _Translations$hub$finishTrek$de finishTrek = _Translations$hub$finishTrek$de._(_root);
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
	@override String get layers => 'Ebenen';
	@override String get layersTitle => 'Kartenebenen';
	@override String get layersSubtitle => 'Wählen Sie, was auf der Karte angezeigt wird';
	@override String stageRemaining({required Object km}) => 'Noch ${km} km';
	@override String get offTrackChip => 'Abseits';
	@override late final _Translations$map$guide$de guide = _Translations$map$guide$de._(_root);
	@override String get supplyDismiss => 'Hinweis ausblenden';
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
	@override String get altitudeProfile => 'Höhenprofil';
	@override String get statistics => 'Statistiken';
	@override String get departureArrival => 'Von {from} nach {to}';
	@override String get loading => 'Laden...';
	@override String get loadingList => 'Etappen werden geladen...';
	@override String get dPlus => 'D+';
	@override String get dMinus => 'D-';
	@override String get difficultyLabel => 'Schwierigkeit';
	@override late final _Translations$stage$waterSources$de waterSources = _Translations$stage$waterSources$de._(_root);
	@override late final _Translations$stage$accommodation$de accommodation = _Translations$stage$accommodation$de._(_root);
	@override late final _Translations$stage$advice$de advice = _Translations$stage$advice$de._(_root);
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
	@override String get accommodation => 'Unterkunft';
	@override String get info => 'Information';
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
	@override String offTrackBanner({required Object meters}) => 'Sie entfernen sich vom Weg — ${meters} m. Überprüfen Sie Ihre Position.';
	@override String get offTrackNotifTitle => 'Sie verlassen den Weg';
	@override String offTrackNotifBody({required Object meters}) => 'Sie entfernen sich vom Weg (${meters} m). Überprüfen Sie Ihre Position.';
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
	@override String get subtitle => 'Ihre Etappen, Tag für Tag';
	@override late final _Translations$itinerary$direction$de direction = _Translations$itinerary$direction$de._(_root);
	@override String get empty => 'Keine Etappe verfügbar';
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
	@override String stageCount({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n,
		one: '${n} Etappe',
		other: '${n} Etappen',
	);
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
	@override String get elevation => 'Höhenmeter';
	@override String get speed => 'Geschwindigkeit';
	@override String get time => 'Zeit';
	@override String get confirmStop => 'Tracking stoppen?';
	@override String get dPlus => 'D+';
	@override String get stopSaveProgress => 'Ihr Fortschritt wird gespeichert.';
	@override String get cancel => 'Abbrechen';
	@override String get stopButton => 'Stopp';
	@override String get stopTitle => 'Aufzeichnung beenden?';
	@override String get stopBody => 'Dein Fortschritt wird gespeichert.';
	@override String get dMinus => 'D-';
	@override String get avgSpeed => 'Ø Geschw.';
	@override String get altitude => 'Höhe';
	@override String get total => 'Gesamt';
	@override String get covered => 'Zurückgelegt';
	@override late final _Translations$tracking$backgroundRationale$de backgroundRationale = _Translations$tracking$backgroundRationale$de._(_root);
}

// Path: checklist
class _Translations$checklist$de extends Translations$checklist$fr {
	_Translations$checklist$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ausrüstung & Rucksack';
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
	@override String seasonalBanner({required Object season}) => 'Rucksack an die Saison (${season}) und Ihren Weg angepasst.';
	@override late final _Translations$checklist$seasons$de seasons = _Translations$checklist$seasons$de._(_root);
	@override String get seasonalAdd => 'Hinzufügen';
	@override String get seasonalAdded => 'Hinzugefügt';
	@override String seasonalWeight({required Object g}) => '${g} g';
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
	@override String get addPhoto => 'Foto hinzufügen';
	@override String get photoAdded => 'Foto zum Tagebuch hinzugefügt';
	@override String get photoSource => 'Fotoquelle';
	@override String get camera => 'Kamera';
	@override String get gallery => 'Galerie';
	@override String get removePhoto => 'Foto entfernen';
	@override String get photoError => 'Foto konnte nicht hinzugefügt werden';
	@override String get dayNavPrevious => 'Vorheriger Tag';
	@override String get dayNavNext => 'Nächster Tag';
	@override String dayOfTrek({required Object day}) => 'Tag ${day}';
	@override String dayCounter({required Object index, required Object total}) => '${index} / ${total}';
	@override String get dayEmpty => 'Kein Eintrag für diesen Tag';
	@override String get entriesOfDay => 'Einträge des Tages';
	@override String get dayTrace => 'Strecke des Tages';
	@override String get dayTraceEmpty => 'Für diesen Tag wurde keine GPS-Strecke aufgezeichnet';
	@override String get daySummary => 'Tagesübersicht';
	@override String get sinceStart => 'Seit dem Start';
	@override String get distance => 'Distanz';
	@override String get elevationGain => 'Aufstieg';
	@override String get elevationLoss => 'Abstieg';
	@override String get duration => 'Dauer';
	@override String get maxAltitude => 'Höchste Höhe';
	@override String get share => 'Teilen';
	@override String get shareSubject => 'Mein Wandertagebuch';
	@override String get shareError => 'Teilen nicht möglich';
	@override String get lockedTitle => 'Das Tagebuch gehört zum Paket';
	@override String get lockedBody => 'Halten Sie Ihre Eindrücke fest, fügen Sie Fotos hinzu und lesen Sie jeden Wandertag nach. Das Tagebuch wird mit dem Weg freigeschaltet.';
	@override String get lockedUnlock => 'Freischalten';
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
	@override String get recapDistance => '{km} km zurückgelegt';
	@override String get recapElevation => '{meters} m Höhenunterschied';
	@override String get recapDuration => '{days} Tage Wanderung';
	@override String get recapMapTrace => 'Routenverlauf';
	@override String get recapNoMap => 'Verlauf nicht verfügbar';
	@override String get recapJournalEntries => '{count} Tagebucheinträge';
	@override String get downloadPdf => 'Diplom-PDF herunterladen';
	@override String get lockedTitle => 'Diplom gesperrt';
	@override String get lockedMessage => 'Absolviere deine gesamte Route, um dein Finisher-Diplom freizuschalten.';
	@override String get labelIntegral => 'Gesamte Route';
	@override String get labelPartial => 'Teilroute';
	@override String pdfSaved({required Object file}) => 'Diplom gespeichert: ${file}';
	@override String get pdfError => 'Das Diplom konnte nicht gespeichert werden';
	@override String finisherNumber({required Object number}) => 'Diplom Nr. ${number}';
	@override String get shareDiploma => 'Mein Diplom teilen';
	@override String get shareError => 'Teilen nicht möglich';
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
	@override String get schedulerCountdownBody => 'Abreise in 2 Tagen. Prüfen Sie Ihre Checkliste und das Wetter.';
	@override String get schedulerDailyTitle => 'Guten Trek-Tag!';
	@override String get schedulerDailyBody => 'Prüfen Sie das Wetter und bereiten Sie Ihre heutige Etappe vor.';
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
	@override String get noDateChosen => 'Kein Datum gewählt';
	@override String get departureDate => 'Startdatum';
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
	@override String appVersion({required Object version, required Object build}) => 'StepWays v${version} (build ${build})';
}

// Path: feasibility
class _Translations$feasibility$de extends Translations$feasibility$fr {
	_Translations$feasibility$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get restart => 'Start over';
	@override String get objectiveTitle => 'Machbarkeit für diesen Trek';
	@override String get objectiveIntro => 'Urteil auf Basis Ihres echten Profils, gekreuzt mit den Anforderungen des Treks.';
	@override String get openProfile => 'Meine Angaben';
	@override String get openWalkTest => '6-Minuten-Test';
	@override String get openPastHikes => 'Meine letzten 5 Touren';
	@override String get sourceObjective => 'Basierend auf Ihrem objektiven Profil';
	@override String get sourceFallback => 'Basierend auf dem Fragebogen (bis Ihr Profil gesetzt ist)';
	@override String get gapTooHigh => 'Zu grosse Abweichung';
	@override late final _Translations$feasibility$gaps$de gaps = _Translations$feasibility$gaps$de._(_root);
	@override late final _Translations$feasibility$formula$de formula = _Translations$feasibility$formula$de._(_root);
	@override late final _Translations$feasibility$flow$de flow = _Translations$feasibility$flow$de._(_root);
}

// Path: tips
class _Translations$tips$de extends Translations$tips$fr {
	_Translations$tips$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Trek-Tipps';
	@override String get allCategories => 'Alle';
	@override String get swipeHint => 'Wischen für mehr';
	@override String get detailTitle => 'Tipp-Detail';
	@override String get readMore => 'Mehr lesen';
	@override String get noTips => 'Keine Tipps verfügbar';
	@override String get categoryPreparation => 'Vorbereitung';
	@override String get categoryEquipment => 'Ausrüstung';
	@override String get categoryNutrition => 'Ernährung';
	@override String get categorySafety => 'Sicherheit';
	@override String get categoryNature => 'Natur';
	@override String get categoryRecovery => 'Erholung';
	@override String get categoryGeneral => 'Allgemein';
	@override String get priorityHigh => 'Hohe Priorität';
	@override String get scope => 'Wanderweg';
	@override String get season => 'Saison';
	@override String get scopeAll => 'Alle Wege';
	@override late final _Translations$tips$seasons$de seasons = _Translations$tips$seasons$de._(_root);
	@override String get altitude => 'Min. Höhe';
	@override String get screenTitle => 'Ratgeber';
	@override String get screenIntro => 'Alles für eine gelungene Wanderung';
	@override String get followUs => 'Folgen Sie uns:';
	@override String get viewOnFacebook => 'Auf Facebook ansehen';
	@override String get viewOnInstagram => 'Instagram';
	@override String get linkOffline => 'Link offline nicht verfügbar';
	@override String get emptyThemed => 'Kein Ratgeber für diesen Weg verfügbar.';
	@override String moreTips({required Object n}) => '+ ${n} Tipps';
	@override late final _Translations$tips$themes$de themes = _Translations$tips$themes$de._(_root);
}

// Path: goodies
class _Translations$goodies$de extends Translations$goodies$fr {
	_Translations$goodies$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Goodies-Shop';
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
	@override String get recoveryNudge => 'Denke daran, deinen Wiederherstellungscode zu notieren (in den Einstellungen): Er öffnet deine Daten auf einem anderen Telefon.';
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
	@override String get rewardedCta => 'Werbung ansehen (24 h werbefrei)';
	@override String get rewardedEarned => 'Danke! 24 h werbefrei.';
	@override String get rewardedUnavailable => 'Derzeit kein Video verfügbar.';
	@override String get walletTitle => 'Etappenkonto';
	@override String get walletSubtitle => 'Mit Ihren Etappen schalten Sie Wanderungen frei';
	@override String get walletUnit => 'Etappen';
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
	@override late final _Translations$signalement$water$de water = _Translations$signalement$water$de._(_root);
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
	@override String progress({required Object done, required Object total}) => '${done} von ${total} Einheiten erledigt';
	@override late final _Translations$training$types$de types = _Translations$training$types$de._(_root);
	@override late final _Translations$training$intensity$de intensity = _Translations$training$intensity$de._(_root);
	@override String get paywallTitle => 'Personalisierter Trainingsplan';
	@override String paywallIncludedIn({required Object trail}) => 'Im Paket « ${trail} » enthalten.';
	@override String get paywallSubtitle => 'Plan angepasst an Ihr Profil und Ihr Abreisedatum.';
	@override String get unlock => 'Freischalten';
	@override String effortIntro({required Object weeks, required Object km, required Object elevation}) => 'Ein progressiver ${weeks}-Wochen-Plan für die ${km} km und rund ${elevation} m Höhenmeter.';
	@override String countdown({required Object days}) => 'Abreise in ${days} Tagen';
	@override String planOverWeeks({required Object n}) => 'Plan über ${n} Wochen';
	@override String phaseWeeks({required Object start, required Object end, required Object title}) => 'Wochen ${start}-${end} · ${title}';
	@override String get objectiveTitle => 'Schlüsselziel';
	@override String get inviteSetDate => 'Legen Sie Ihr Abreisedatum im Kalender fest, um den Countdown zu aktivieren.';
	@override String get inviteFillProfile => 'Füllen Sie Ihr Datenblatt aus, um den Plan an Ihr Profil anzupassen.';
	@override String get cautionVerdictNotice => 'Ihre Machbarkeit mahnt zur Vorsicht: halten Sie die Progression ein und kurzen Sie die Vorbereitung nicht.';
	@override String departureTooClose({required Object days}) => 'Noch ${days} Tage: Plan auf die verfügbare Zeit verdichtet.';
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
	@override late final _Translations$health$error$de error = _Translations$health$error$de._(_root);
	@override String get save => 'Speichern';
	@override String get saving => 'Speichern…';
	@override String get saved => 'Informationen gespeichert';
	@override String get emergencyHint => 'Zeigen Sie diesen Bildschirm im Notfall den Rettungskräften.';
	@override String get entryTitle => 'Meine Gesundheitsdaten';
	@override String get entrySubtitle => 'Den Rettungskräften zeigen (bleiben auf dem Telefon)';
	@override late final _Translations$health$a11y$de a11y = _Translations$health$a11y$de._(_root);
	@override late final _Translations$health$delete$de delete = _Translations$health$delete$de._(_root);
	@override late final _Translations$health$consent$de consent = _Translations$health$consent$de._(_root);
}

// Path: trailSelection
class _Translations$trailSelection$de extends Translations$trailSelection$fr {
	_Translations$trailSelection$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weg wechseln';
	@override String get subtitle => 'Wähle den Weg zum Erkunden. Die ganze App (Karte, Etappen, Sehenswürdigkeiten, Pakete, Reiseführer) folgt deiner Auswahl.';
	@override String get current => 'Aktiver Weg';
	@override String get select => 'Diesen Weg wählen';
	@override String get selected => 'Ausgewählter Weg';
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
	@override String get healthDataMorphoNote => 'Umfasst Ihre Körperdaten (Alter, Grösse, Gewicht) für die Trek-Machbarkeit. Gesundheitsdaten, DSGVO Artikel 9, auf dem Gerät gehalten.';
	@override String get healthBackupNote => 'Ohne diese Einwilligung wird Ihr medizinisches Informationsblatt nicht gesichert: Sie können es auf einem anderen Telefon nicht wiederherstellen und den Rettungskräften von einem neuen Gerät nicht zeigen.';
}

// Path: erasure
class _Translations$erasure$de extends Translations$erasure$fr {
	_Translations$erasure$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get section => 'Meine Daten';
	@override String get entry => 'Meine Daten löschen';
	@override String get entryDesc => 'Endgültig löschen, was die App über Sie speichert';
	@override String get dialogTitle => 'Meine Daten löschen?';
	@override String get goesTitle => 'Was gelöscht wird';
	@override String get goes => 'Ihr Wanderprofil (Alter, Grösse, Gewicht, Gehtest), Ihr medizinisches Informationsblatt, Ihre vergangenen Wanderungen und Ihr Tagebuch, Ihre gegangenen Etappen, Ihre Übernachtungen, Ihre GPS-Aufzeichnungen, Ihre Einwilligungen und Ihr Wiederherstellungscode. Und Ihre gesamte Vorbereitungsarbeit: Ihr Programm und die von Ihnen gewählte Etappeneinteilung, Ihr Abreisedatum, Ihr Fortschritt der körperlichen Vorbereitung, was Sie unter Vorbereiten bereits abgeschlossen haben, Ihre Einstellungen für Teilen und Sichtbarkeit sowie die von Ihnen abgehakten Etappenpunkte.';
	@override String get staysTitle => 'Was bleibt';
	@override String get stays => 'Ihre Käufe: bezahlte Etappen, freigeschaltete Wege, werbefreier Zeitraum — wir nehmen Ihnen nicht zurück, was Sie bezahlt haben. Und Ihre Anzeigeeinstellungen (Sprache, Design, Einheiten), die nichts über Sie aussagen.';
	@override String get finalWarning => 'Das ist endgültig: weder Sie noch wir können diese Daten wiederherstellen.';
	@override String get confirmCheckbox => 'Ich habe das gelesen und möchte meine Daten löschen';
	@override String get confirm => 'Endgültig löschen';
	@override String get cancel => 'Abbrechen';
	@override String get done => 'Ihre Daten wurden gelöscht.';
	@override String get error => 'Die Löschung wurde nicht abgeschlossen. Versuchen Sie es erneut — was schon gelöscht ist, kommt nicht zurück.';
	@override late final _Translations$erasure$a11y$de a11y = _Translations$erasure$a11y$de._(_root);
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
	@override String get lockedTitle => 'Verfügbar am Ende der Tour';
	@override String get lockedMessage => 'Beende oder brich deine Route ab, um die Zusammenfassung deines Abenteuers zu sehen.';
	@override String get finisherTitle => 'Glückwunsch!';
	@override String get finisherSubtitle => 'Du hast deine Route abgeschlossen';
	@override String get partialTitle => 'Deine Teilroute';
	@override String get partialSubtitle => 'Dein Abenteuer bleibt gespeichert';
	@override String get statsSection => 'Statistiken';
	@override String get traceSection => 'Deine Spur';
	@override String get noTrace => 'Keine GPS-Spur verfügbar';
	@override String get stages => '{done} / {total} Etappen gelaufen';
	@override String get distance => '{km} km zurückgelegt';
	@override String get elevation => '{meters} m Höhenmeter';
	@override String get duration => '{days} Tage';
	@override String get dates => 'Vom {start} bis {end}';
	@override String get viewDiploma => 'Mein Diplom ansehen';
	@override String get viewJournal => 'Mein Tagebuch ansehen';
	@override String get noData => 'Noch keine Routendaten zum Anzeigen.';
	@override String elevationLoss({required Object meters}) => '${meters} m Abstieg';
	@override String get shareAdventure => 'Mein Abenteuer teilen';
	@override String shareHeadline({required Object trail}) => 'Mein Abenteuer auf dem ${trail}';
	@override String get shareError => 'Teilen nicht möglich';
	@override String get exportGpx => 'Strecke als GPX exportieren';
	@override String gpxExported({required Object file}) => 'Strecke exportiert: ${file}';
	@override String get gpxEmpty => 'Kein GPS-Punkt zum Exportieren';
	@override String get gpxError => 'Export nicht möglich';
	@override String get daysSection => 'Tag für Tag';
	@override String dayLabel({required Object day}) => 'Tag ${day}';
	@override String dayStages({required Object count}) => '${count} Etappe(n)';
	@override String get dayRest => 'An diesem Tag keine Etappe beendet';
	@override String get noDays => 'Kein per GPS aufgezeichneter Tag';
	@override String averageSpeed({required Object kmh}) => '${kmh} km/h im Durchschnitt';
}

// Path: programme
class _Translations$programme$de extends Translations$programme$fr {
	_Translations$programme$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programm';
	@override String get helpTooltip => 'Hilfe';
	@override late final _Translations$programme$duration$de duration = _Translations$programme$duration$de._(_root);
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
	@override String get validateNext => 'Bestätigen und Daten wählen';
	@override late final _Translations$programme$empty$de empty = _Translations$programme$empty$de._(_root);
	@override late final _Translations$programme$info$de info = _Translations$programme$info$de._(_root);
	@override late final _Translations$programme$splitBlocked$de splitBlocked = _Translations$programme$splitBlocked$de._(_root);
	@override String get reorderBlocked => 'Tour gestartet: die Reihenfolge der Etappen ändert sich nicht mehr';
	@override late final _Translations$programme$inTrek$de inTrek = _Translations$programme$inTrek$de._(_root);
}

// Path: calendar
class _Translations$calendar$de extends Translations$calendar$fr {
	_Translations$calendar$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kalender';
	@override String get validate => 'DATEN BESTÄTIGEN';
	@override String get departure => 'ABREISE';
	@override String get arrival => 'ANKUNFT';
	@override String get chooseDate => 'Datum wählen';
	@override String get chooseDateAction => 'DATUM WÄHLEN';
	@override String get previousMonth => 'Voriger Monat';
	@override String get nextMonth => 'Nächster Monat';
	@override String get dayLabel => 'T{n}';
	@override String get restDayLabel => 'R';
	@override String get adjustStages => 'ETAPPEN ANPASSEN';
	@override String get stageSingular => 'Etappe {n}';
	@override String get stagesPlural => 'Etappen {list}';
	@override String get splitStages => 'Etappen trennen';
	@override String get mergeWithNext => 'Mit dem nächsten Tag zusammenlegen';
	@override late final _Translations$calendar$weekdays$de weekdays = _Translations$calendar$weekdays$de._(_root);
	@override late final _Translations$calendar$legend$de legend = _Translations$calendar$legend$de._(_root);
	@override late final _Translations$calendar$summary$de summary = _Translations$calendar$summary$de._(_root);
	@override late final _Translations$calendar$noDate$de noDate = _Translations$calendar$noDate$de._(_root);
	@override late final _Translations$calendar$empty$de empty = _Translations$calendar$empty$de._(_root);
}

// Path: nuitees
class _Translations$nuitees$de extends Translations$nuitees$fr {
	_Translations$nuitees$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Übernachtungen';
	@override String get guideTooltip => 'Übernachtungs-Ratgeber';
	@override String get infoBar => 'Buchen Sie jede Nacht in der Hochsaison im Voraus';
	@override late final _Translations$nuitees$types$de types = _Translations$nuitees$types$de._(_root);
	@override late final _Translations$nuitees$guide$de guide = _Translations$nuitees$guide$de._(_root);
	@override late final _Translations$nuitees$card$de card = _Translations$nuitees$card$de._(_root);
	@override late final _Translations$nuitees$summary$de summary = _Translations$nuitees$summary$de._(_root);
	@override late final _Translations$nuitees$empty$de empty = _Translations$nuitees$empty$de._(_root);
}

// Path: transport
class _Translations$transport$de extends Translations$transport$fr {
	_Translations$transport$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Anreise';
	@override String get tabJoin => 'Zum Start';
	@override String tabJoinNamed({required Object name}) => 'Nach ${name}';
	@override String get tabLeave => 'Vom Ziel weg';
	@override String tabLeaveNamed({required Object name}) => 'Ab ${name}';
	@override String joinTitle({required Object name}) => 'Nach ${name}';
	@override String leaveTitle({required Object name}) => 'Ab ${name}';
	@override String get adviceTitle => 'Praktische Tipps';
	@override String get website => 'Website';
	@override late final _Translations$transport$a11y$de a11y = _Translations$transport$a11y$de._(_root);
}

// Path: fireRisk
class _Translations$fireRisk$de extends Translations$fireRisk$fr {
	_Translations$fireRisk$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Brandrisiko';
	@override String get refresh => 'Aktualisieren';
	@override String get refreshed => 'Daten aktualisiert';
	@override String get refreshError => 'Keine Verbindung';
	@override late final _Translations$fireRisk$update$de update = _Translations$fireRisk$update$de._(_root);
	@override late final _Translations$fireRisk$duration$de duration = _Translations$fireRisk$duration$de._(_root);
	@override String get fwiSource => 'Risikoindex basierend auf dem Fire Weather Index (FWI) von Open-Meteo (Modell Meteo-France). Der FWI ist der vom europäischen EFFIS-System zur Bewertung des Waldbrandrisikos verwendete Index.';
	@override late final _Translations$fireRisk$regulation$de regulation = _Translations$fireRisk$regulation$de._(_root);
	@override String get levelsTitle => 'Risikostufen';
	@override late final _Translations$fireRisk$level$de level = _Translations$fireRisk$level$de._(_root);
	@override String get stagesTitle => 'Risiko pro Etappe';
	@override String stageBadge({required Object number}) => 'E${number}';
	@override String levelBadge({required Object level}) => 'St. ${level}';
	@override String dayLevel({required Object level}) => 'St. ${level}';
	@override late final _Translations$fireRisk$day$de day = _Translations$fireRisk$day$de._(_root);
	@override String get noRisk => 'Derzeit kein Brandrisiko gemeldet';
	@override String get numbersTitle => 'Nützliche Nummern';
	@override late final _Translations$fireRisk$number$de number = _Translations$fireRisk$number$de._(_root);
	@override late final _Translations$fireRisk$empty$de empty = _Translations$fireRisk$empty$de._(_root);
	@override late final _Translations$fireRisk$a11y$de a11y = _Translations$fireRisk$a11y$de._(_root);
}

// Path: shop
class _Translations$shop$de extends Translations$shop$fr {
	_Translations$shop$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Verpflegung';
	@override String get filterAll => 'Alle';
	@override String get typeEpicerie => 'Lebensmittel';
	@override String get typeBar => 'Bar/Restaurant';
	@override String get typePharmacie => 'Apotheke';
	@override String get typeGaz => 'Gas/Ausrüstung';
	@override String get limitedTitle => 'Begrenzte Versorgungspunkte';
	@override String stageHeader({required Object n}) => 'Etappe ${n}';
	@override String stageBadge({required Object n}) => 'Etappe ${n}';
	@override String gapShort({required Object n}) => 'Letzte Versorgung vor ${n} Etappen ohne Geschäft';
	@override String gapLong({required Object n}) => 'Letzte Versorgung vor ${n} Etappen ohne Geschäft. Decken Sie sich ein!';
	@override String get sectionInfo => 'Informationen';
	@override String get sectionProducts => 'Verfügbare Produkte';
	@override String get fieldType => 'Typ';
	@override String get fieldStage => 'Etappe';
	@override String get fieldGps => 'GPS';
	@override String get fieldHours => 'Öffnungszeiten';
	@override String get website => 'Website';
	@override String get filterEmpty => 'Kein Geschäft für diesen Filter.';
	@override late final _Translations$shop$a11y$de a11y = _Translations$shop$a11y$de._(_root);
}

// Path: summary
class _Translations$summary$de extends Translations$summary$fr {
	_Translations$summary$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planübersicht';
	@override String configTitle({required Object name}) => 'Mein ${name}';
	@override String get direction => 'Richtung';
	@override String get duration => 'Dauer';
	@override String durationValue({required Object days}) => '${days} Wandertage';
	@override String durationValueWithRest({required Object days, required Object rest}) => '${days} Wandertage + ${rest} Ruhetage';
	@override String get startDate => 'Abreise';
	@override String get endDate => 'Ankunft';
	@override late final _Translations$summary$stats$de stats = _Translations$summary$stats$de._(_root);
	@override String get dayByDay => 'Tag für Tag';
	@override String dayLabel({required Object n}) => 'T${n}';
	@override String stageLabel({required Object n}) => 'Etappe ${n}';
	@override String get restDay => 'Ruhetag';
	@override String restDayTitle({required Object n}) => 'Ruhetag — T${n}';
	@override String restDayPlace({required Object place}) => 'Ort: ${place}';
	@override late final _Translations$summary$actions$de actions = _Translations$summary$actions$de._(_root);
	@override late final _Translations$summary$share$de share = _Translations$summary$share$de._(_root);
	@override late final _Translations$summary$empty$de empty = _Translations$summary$empty$de._(_root);
	@override late final _Translations$summary$a11y$de a11y = _Translations$summary$a11y$de._(_root);
}

// Path: import
class _Translations$import$de extends Translations$import$fr {
	_Translations$import$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'GPX importieren';
	@override String get headerTitle => 'Eine GPX-Datei importieren';
	@override String get headerBody => 'Importieren Sie einen mit einer anderen App (Strava, Garmin usw.) aufgezeichneten GPS-Track, um Ihre Zusammenfassung zu erstellen.';
	@override String get pickButton => 'GPX-DATEI AUSWÄHLEN';
	@override String get traceSection => 'Importierter Track';
	@override String get statsSection => 'Statistiken';
	@override String get statDistance => 'Distanz';
	@override String get statElevationGain => 'Aufstieg';
	@override String get statElevationLoss => 'Abstieg';
	@override String get statDuration => 'Dauer';
	@override String get statDirection => 'Richtung';
	@override String get statPoints => 'GPS-Punkte';
	@override String get directionNS => 'Nord-Süd';
	@override String get directionSN => 'Süd-Nord';
	@override String get stagesSection => 'Erkannte Etappen';
	@override String get stagesCount => '{done}/{total}';
	@override String get stageBadge => 'E{number}';
	@override String get warningsSection => 'Warnungen';
	@override String get warningOutOfBounds => '{count} Punkt(e) außerhalb des Gebiets ignoriert.';
	@override String get warningOffTrail => '{percent}% der Punkte sind weit vom Weg entfernt.';
	@override String get invalidTooFewPoints => 'GPX-Datei zu klein: {count} Punkte (mindestens 10).';
	@override String get invalidOutOfBounds => 'Der Track passt nicht zum Gebiet dieses Weges.';
	@override String get errorUnreadable => 'Datei kann nicht gelesen werden.';
	@override String get errorParsing => 'Die GPX-Datei konnte nicht gelesen werden.';
	@override String get validateButton => 'IMPORT BESTÄTIGEN';
	@override String get confirmTitle => 'Import bestätigen?';
	@override String get confirmBody => 'Dieser Track wird als Ihre Route importiert:\n\n- {points} GPS-Punkte\n- {km} km\n- {stages} erkannte Etappen\n- Richtung: {direction}';
	@override String get cancel => 'Abbrechen';
	@override String get validate => 'Bestätigen';
	@override String get importedSnack => 'GPX-Track importiert!';
}

// Path: myTreks
class _Translations$myTreks$de extends Translations$myTreks$fr {
	_Translations$myTreks$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meine Touren';
	@override String get sectionInProgress => 'Laufend';
	@override String get sectionPrepared => 'Vorbereitet';
	@override String get sectionCompleted => 'Abgeschlossen';
	@override String get emptyTitle => 'Noch keine Touren';
	@override String get empty => 'Noch keine Tour. Entdecke einen Weg, um zu beginnen.';
	@override String get discoverTitle => 'Wege entdecken';
	@override String get discoverSubtitle => 'Katalog durchsuchen';
	@override String get accountTitle => 'Mein Konto';
	@override String get accountSubtitle => 'Profil und Einstellungen';
	@override late final _Translations$myTreks$badge$de badge = _Translations$myTreks$badge$de._(_root);
	@override String progressLabel({required Object percent}) => '${percent} % des Weges';
	@override late final _Translations$myTreks$a11y$de a11y = _Translations$myTreks$a11y$de._(_root);
	@override String get settingsSubtitle => 'Sprache, Einheiten, Thema';
}

// Path: trekState
class _Translations$trekState$de extends Translations$trekState$fr {
	_Translations$trekState$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override late final _Translations$trekState$abandonDialog$de abandonDialog = _Translations$trekState$abandonDialog$de._(_root);
	@override late final _Translations$trekState$resumeOrphanDialog$de resumeOrphanDialog = _Translations$trekState$resumeOrphanDialog$de._(_root);
}

// Path: hikerProfile
class _Translations$hikerProfile$de extends Translations$hikerProfile$fr {
	_Translations$hikerProfile$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ihre Angaben';
	@override String get privacyBanner => 'Ihre Körperdaten sind sensible Daten. Sie bleiben auf Ihrem Gerät (und einer verschlüsselten Sicherung ohne Ihren Namen), um Ihre Machbarkeit zu berechnen.';
	@override String get fieldAge => 'Alter';
	@override String get hintAge => 'In Jahren';
	@override String get errorAge => 'Ungültiges Alter (18 bis 120 Jahre)';
	@override String get fieldHeight => 'Grösse';
	@override String get hintHeight => 'In Zentimetern';
	@override String get errorHeight => 'Ungültige Grösse (60 bis 255 cm)';
	@override String get fieldWeight => 'Gewicht';
	@override String get hintWeight => 'In Kilogramm';
	@override String get errorWeight => 'Ungültiges Gewicht (25 bis 200 kg)';
	@override String get errorCountry => 'Ungültiger Ländercode (z. B. FR)';
	@override String get errorEmpty => 'Leeres Profil: Geben Sie mindestens Alter, Grösse oder Gewicht an.';
	@override String get errorConsentRequired => 'Ohne Ihre Einwilligung wird nichts gespeichert: Alter, Grösse und Gewicht sind Gesundheitsdaten. Was gespeichert war, wurde soeben von diesem Gerät gelöscht. Aktivieren Sie oben die Zustimmung und speichern Sie erneut.';
	@override String get fieldSex => 'Geschlecht (optional)';
	@override String get sexFemale => 'Weiblich';
	@override String get sexMale => 'Männlich';
	@override String get sexUnspecified => 'Keine Angabe';
	@override String get fieldCountry => 'Land';
	@override String get countryUnspecified => 'Keine Angabe';
	@override String get hintCountry => 'Code (z. B. FR)';
	@override String get consentTitle => 'Körperdaten (DSGVO Artikel 9)';
	@override String get consentBody => 'Alter, Grösse und Gewicht sind Gesundheitsdaten. Sie bleiben auf Ihrem Gerät und einer Sicherung ohne Ihren Namen oder Ihre E-Mail, nie im Klartext gesendet. Diese Einwilligung wird separat erfragt.';
	@override String get consentToggle => 'Ich erlaube die Nutzung meiner Körperdaten für die Machbarkeit';
	@override String get save => 'Speichern';
	@override String get saved => 'Angaben gespeichert';
	@override String get morphoNotPrefilledHint => 'Nichts ist vorausgefüllt: Geben Sie Ihre echten Daten ein, es geht um Ihre Sicherheit.';
	@override String get seniorReminder => 'Ab 65 Jahren wird vor einem anspruchsvollen Trek eine ärztliche Untersuchung empfohlen.';
}

// Path: walkTest
class _Translations$walkTest$de extends Translations$walkTest$fr {
	_Translations$walkTest$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => '6-Minuten-Gehtest';
	@override String get intro => 'Gehen Sie in 6 Minuten so weit wie möglich auf ebenem Gelände. Das GPS misst die Distanz; wir vergleichen sie mit Normen für Alter und Geschlecht.';
	@override String get safetyWarning => 'Vermeiden Sie diese Anstrengung bei ungeklärten Herzproblemen. Hören Sie bei Unwohlsein auf.';
	@override String get start => 'Test starten';
	@override String get stop => 'Stoppen';
	@override String get cancel => 'Abbrechen';
	@override String get countdown => 'Machen Sie sich bereit...';
	@override String get running => 'Läuft';
	@override String get liveDistance => 'Distanz';
	@override String get timeLeft => 'Verbleibende Zeit';
	@override String get meters => 'm';
	@override String get resultTitle => 'Testergebnis';
	@override String get resultDistance => 'Zurückgelegte Distanz';
	@override String get resultLevel => 'Geschätztes Niveau';
	@override String resultDate({required Object date}) => 'Durchgeführt am ${date}';
	@override String get doneAgain => 'Test wiederholen';
	@override String get gpsNeeded => 'GPS wird benötigt, um die Distanz zu messen.';
	@override String get gpsDenied => 'Erlauben Sie den Standort, um den Test zu starten.';
	@override String get monthlyReminderOn => 'Monatliche Erinnerung aktiv';
	@override String get monthlyReminderBody => 'Jeden Monat wird eine Test-Erinnerung angeboten, um Ihre Form zu verfolgen.';
	@override String get notDoneYet => 'Test nicht durchgeführt';
	@override String get fallbackNotice => 'Bis zum Test wird Ihr Niveau aus Ihrem Fragebogen geschätzt.';
	@override late final _Translations$walkTest$levels$de levels = _Translations$walkTest$levels$de._(_root);
	@override String get absoluteScaleNotice => 'Dein Niveau wird auf der reinen Distanzskala gelesen: der Vergleich mit einem Referenzwert wurde für deinen Körperbau nicht erstellt, also wenden wir ihn nicht an. Dein Test selbst bleibt voll gültig.';
	@override String get ageClampNotice => 'Über 80 Jahre endet der Referenzwert des Tests: er wird wie mit 80 berechnet, und wir sagen es dir.';
}

// Path: pastHikes
class _Translations$pastHikes$de extends Translations$pastHikes$fr {
	_Translations$pastHikes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ihre letzten 5 Touren';
	@override String get intro => 'Fügen Sie bis zu 5 markante Touren hinzu. Wir leiten Ihr echtes Niveau ab (Tempo, Ausdauer, Höhengewöhnung) statt eines Etiketts.';
	@override String get addHike => 'Tour hinzufügen';
	@override String get empty => 'Noch keine Tour erfasst.';
	@override String get fieldDate => 'Datum';
	@override String get fieldDays => 'Anzahl Tage';
	@override String get fieldAvgHours => 'Gehzeit pro Tag (Std.)';
	@override String get fieldElevation => 'Gesamtanstieg (m)';
	@override String get fieldDistance => 'Gesamtdistanz (km)';
	@override String get errorDays => 'Ungültige Tageszahl (1 bis 60)';
	@override String get errorHours => 'Ungültige Dauer (0 bis 24 h)';
	@override String get errorElevation => 'Ungültiger Höhenunterschied (0 bis 5000 m)';
	@override String get errorDistance => 'Ungültige Distanz (0 bis 100 km)';
	@override String get errorEffort => 'Geben Sie mindestens Höhenmeter oder Distanz an';
	@override String get perDay => 'pro Tag';
	@override String get editHike => 'Tour bearbeiten';
	@override String get deleteHike => 'Löschen';
	@override String get save => 'Speichern';
	@override String get saved => 'Touren gespeichert';
	@override String get maxReached => 'Maximum von 5 Touren erreicht.';
	@override String get difficultiesTitle => 'Aufgetretene Schwierigkeiten';
	@override String get difficultiesHint => 'Ein Text für alle diese Touren: Blasen, Knie beim Abstieg, Atemnot in der Höhe, Hitzestress...';
	@override String get difficultiesSaved => 'Notiz gespeichert';
}

// Path: ffrando
class _Translations$ffrando$de extends Translations$ffrando$fr {
	_Translations$ffrando$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cotationTitle => 'FFRandonnee-Bewertung';
	@override String get effort => 'Anstrengung';
	@override String get technicite => 'Technik';
	@override String get risque => 'Risiko';
	@override String get ibpLabel => 'IBP-Index';
	@override String get effortScale => 'Anstrengung (1 bis 5)';
	@override String get techniciteScale => 'Technik (1 bis 5)';
	@override String get risqueScale => 'Risiko (1 bis 5)';
	@override String get notRated => 'Nicht bewertet';
	@override late final _Translations$ffrando$effortLevels$de effortLevels = _Translations$ffrando$effortLevels$de._(_root);
}

// Path: sos
class _Translations$sos$de extends Translations$sos$fr {
	_Translations$sos$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notruf absetzen?';
	@override String get body => 'Sie sind dabei, den Notruf 112 (europäischer Notruf) zu wählen.';
	@override String get positionTitle => 'Ihre aktuelle Position';
	@override String get positionUnavailable => 'GPS-Position nicht verfügbar';
	@override String get gpsAcquiring => 'GPS wird ermittelt…';
	@override String positionLine({required Object lat, required Object lng, required Object alt}) => 'Position: ${lat}, ${lng}  -  Höhe ${alt} m';
	@override String get noContacts => 'Kein Kontakt konfiguriert';
	@override String callContact({required Object name}) => '${name} anrufen';
	@override String get altitudeUnavailable => 'Höhe: nicht verfügbar';
	@override String get communicate => 'Teilen Sie den Rettungskräften diese Koordinaten mit.';
	@override String get cancel => 'Abbrechen';
	@override String get call => '112 anrufen';
	@override late final _Translations$sos$medicalId$de medicalId = _Translations$sos$medicalId$de._(_root);
}

// Path: recovery
class _Translations$recovery$de extends Translations$recovery$fr {
	_Translations$recovery$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get section => 'Konto und Wiederherstellung';
	@override String get sectionDesc => 'Meinen Wiederherstellungscode anzeigen';
	@override String get title => 'Mein Wiederherstellungscode';
	@override String get intro => 'Dieser Code öffnet deinen Tresor (Profil, persönliche Angaben und Etappen-Guthaben) auf einem anderen Telefon. Notiere ihn und bewahre ihn sicher auf: Er funktioniert wie ein Passwort.';
	@override String get codeLabel => 'Dein Code';
	@override String get copy => 'Code kopieren';
	@override String get copied => 'Code kopiert';
	@override String get warning => 'Niemand sonst kann deinen Tresor lesen, auch wir nicht. Wenn du diesen Code verlierst, sind deine Daten unwiederbringlich verloren.';
	@override String get error => 'Der Code kann derzeit nicht erzeugt werden.';
}

// Path: common
class _Translations$common$de extends Translations$common$fr {
	_Translations$common$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get cannotLoadStages => 'Etappen können nicht geladen werden';
	@override String get noStages => 'Keine Etappen verfügbar';
	@override String get cannotLoadStage => 'Diese Etappe kann nicht geladen werden';
	@override String get stageNotFound => 'Etappe nicht gefunden';
	@override String get cannotLoadTrack => 'Track kann nicht geladen werden';
	@override String get loadingTrack => 'Track wird geladen…';
	@override String get gpxEmpty => 'Die GPX-Datei enthält keine Punkte.';
	@override String get noPoiForStage => 'Kein interessanter Punkt für diese Etappe.';
	@override String get viewOnMap => 'Auf Karte anzeigen';
	@override String get error => 'Fehler';
	@override String pageNotFound({required Object path}) => 'Seite nicht gefunden: ${path}';
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
	@override String get completedTitle => 'Tour abgeschlossen';
}

// Path: hub.weather
class _Translations$hub$weather$de extends Translations$hub$weather$fr {
	_Translations$hub$weather$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wetter heute';
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
	@override String get calendar => 'Kalender';
	@override String get calendarSub => 'Daten wählen';
	@override String get transport => 'Anreise';
	@override String get transportSub => 'Hin & zurück';
	@override String get nuitees => 'Übernachtungen';
	@override String get nuiteesSub => 'Buchen Sie Ihre Nächte';
	@override String get checklist => 'Ausrüstung & Rucksack';
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
	@override String get importGpx => 'GPX-Import';
	@override String get importGpxSub => 'Einen GPS-Track importieren';
	@override String get diploma => 'Diplom';
	@override String get diplomaSub => 'Ihre Abschlussurkunde';
	@override String get resume => 'Zusammenfassung';
	@override String get resumeSub => 'Planübersicht';
	@override String get shop => 'Verpflegung';
	@override String get shopSub => 'Lebensmittel, Apotheken, Gas';
	@override String get weather => 'Wetter';
	@override String get weatherSub => 'Vorhersage pro Etappe';
	@override String get fire => 'Brand';
	@override String get fireSub => 'Risiken & Warnungen';
	@override String get adjust => 'Route anpassen';
	@override String get adjustSub => 'Meine kommenden Tage ändern';
}

// Path: hub.fab
class _Translations$hub$fab$de extends Translations$hub$fab$fr {
	_Translations$hub$fab$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get feedback => 'Feedback geben';
	@override String get sos => 'SOS';
}

// Path: hub.finishTrek
class _Translations$hub$finishTrek$de extends Translations$hub$finishTrek$fr {
	_Translations$hub$finishTrek$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get action => 'Tour beenden';
	@override String get confirmTitle => 'Tour beenden?';
	@override String get confirmBody => 'Die Tour wird als beendet markiert. Nicht gegangene Etappen werden nicht bestätigt. Du kannst dein Abenteuer weiterhin ansehen.';
	@override String get confirm => 'Beenden';
	@override String get cancel => 'Abbrechen';
}

// Path: map.guide
class _Translations$map$guide$de extends Translations$map$guide$fr {
	_Translations$map$guide$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get buttonsTitle => 'Schaltflächen';
	@override String get position => 'Ihre GPS-Position, beim Gehen aktualisiert. Verschwindet der Punkt, prüfen Sie, ob die Ortung für die App erlaubt ist.';
	@override String get track => 'Die Linie des Wegs, in seiner Farbe. Sie ist die Referenz für die Warnung bei Abweichung.';
	@override String get centerOnMe => 'Holt die Karte zu Ihrer Position zurück, nachdem Sie sie verschoben haben.';
	@override String get photo => 'Macht ein Foto und legt es ins Tagebuch des Tages, ohne die Karte zu verlassen.';
	@override String get sos => 'Öffnet den Notruf mit Ihren GPS-Koordinaten. Nur im echten Notfall zu benutzen.';
	@override String get currentStage => 'Was auf der laufenden Etappe noch zu gehen ist. Ein Strich bedeutet, dass die Wanderung noch nicht begonnen hat.';
	@override String get offTrack => 'Leuchtet auf, wenn Sie sich von der Linie entfernen. Kehren Sie zum Weg zurück, damit sie verschwindet.';
	@override late final _Translations$map$guide$poi$de poi = _Translations$map$guide$poi$de._(_root);
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

// Path: stage.waterSources
class _Translations$stage$waterSources$de extends Translations$stage$waterSources$fr {
	_Translations$stage$waterSources$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wasserstellen';
	@override String get count => '{n} Quelle(n)';
	@override String get none => 'Keine Wasserstelle für diese Etappe verzeichnet. Nehmen Sie mindestens 3 L pro Person mit.';
}

// Path: stage.accommodation
class _Translations$stage$accommodation$de extends Translations$stage$accommodation$fr {
	_Translations$stage$accommodation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Unterkünfte';
	@override String get none => 'Keine Unterkunft für diese Etappe verzeichnet.';
}

// Path: stage.advice
class _Translations$stage$advice$de extends Translations$stage$advice$fr {
	_Translations$stage$advice$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tipps';
	@override String get waterScarce => 'Wenige Wasserstellen: Starten Sie mit mindestens 2,5 L.';
	@override String get waterAmple => 'Füllen Sie Ihre Flaschen an jeder Wasserstelle auf.';
	@override String get hardStage => 'Anspruchsvolle Etappe: Brechen Sie früh auf, um Hitze und Nachmittagsgewitter zu vermeiden.';
	@override String get earlyStart => 'Aufbruch vor 8 Uhr empfohlen, um die morgendliche Kühle zu nutzen.';
	@override String get bigClimb => 'Grosser Aufstieg: Teilen Sie sich Ihre Kräfte ein und machen Sie regelmässige Pausen.';
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

// Path: itinerary.direction
class _Translations$itinerary$direction$de extends Translations$itinerary$direction$fr {
	_Translations$itinerary$direction$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderrichtung';
	@override String get from => 'Start';
	@override String get to => 'Ziel';
	@override String get reverse => 'Richtung umkehren';
}

// Path: tracking.backgroundRationale
class _Translations$tracking$backgroundRationale$de extends Translations$tracking$backgroundRationale$fr {
	_Translations$tracking$backgroundRationale$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Deine Route auch bei ausgeschaltetem Bildschirm aufzeichnen';
	@override String get body => 'Während der Wanderung zeichnet StepWays deine Route durchgehend auf, auch wenn das Telefon in der Tasche steckt. Android fragt dich, ob du den Standort „Immer“ zulassen willst: genau dafür ist das, und nur während einer laufenden Wanderung.';
	@override String get ifRefused => 'Wenn du ablehnst, startet die Wanderung trotzdem: die Route wird aufgezeichnet, solange die App auf dem Bildschirm bleibt.';
	@override String get allow => 'Anfrage anzeigen';
	@override String get later => 'Später';
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
	@override String get men => 'Männer';
	@override String get misc => 'Sonstiges';
	@override String get dog => 'Hund';
}

// Path: checklist.items
class _Translations$checklist$items$de extends Translations$checklist$items$fr {
	_Translations$checklist$items$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Rucksack 35-45L';
	@override String get rainCover => 'Rucksack-Regenhülle';
	@override String get dryBags => 'Packsäcke (dry bags)';
	@override String get sleepingBag => 'Schlafsack (0-5C)';
	@override String get sleepingPad => 'Isomatte / Unterlage';
	@override String get sleepingLiner => 'Hüttenschlafsack / Inlett';
	@override String get pillow => 'Aufblasbares Kissen';
	@override String get hikingPants => 'Wanderhose';
	@override String get rainPants => 'Regenhose';
	@override String get shorts => 'Shorts';
	@override String get techTshirt => 'Funktions-T-Shirt';
	@override String get fleece => 'Fleece / leichte Daune';
	@override String get rainJacket => 'Regenjacke Gore-Tex';
	@override String get underwear => 'Unterwäsche';
	@override String get hikingSocks => 'Wandersocken';
	@override String get gaiters => 'Gamaschen';
	@override String get hat => 'Hut / Kappe';
	@override String get beanie => 'Mütze';
	@override String get buff => 'Buff / Halstuch';
	@override String get lightGloves => 'Leichte Handschuhe';
	@override String get hikingBoots => 'Wanderschuhe (getragen)';
	@override String get campSandals => 'Camp-Sandalen';
	@override String get stove => 'Kocher (PocketRocket)';
	@override String get gasCanister => 'Gaskartusche';
	@override String get cookpot => 'Kochtopf / Geschirr';
	@override String get cutlery => 'Besteck (Löffel, Messer)';
	@override String get waterBottle => 'Trinkflasche / Blase 2L';
	@override String get knife => 'Klappmesser';
	@override String get lighter => 'Feuerzeug';
	@override String get energyBars => 'Energieriegel';
	@override String get driedFruits => 'Trockenfrüchte';
	@override String get freezeDriedMeal => 'Gefriergetrocknete Mahlzeit';
	@override String get waterPurification => 'Wasser-Entkeimungstabletten';
	@override String get electrolytes => 'Elektrolyte';
	@override String get carriedWater => 'Getragenes Wasser (1L = 1000g)';
	@override String get soap => 'Biologisch abbaubare Seife';
	@override String get toothbrush => 'Zahnbürste';
	@override String get toothpaste => 'Zahnpasta';
	@override String get microfiberTowel => 'Mikrofaser-Handtuch';
	@override String get toiletPaper => 'Toilettenpapier';
	@override String get trashBag => 'Müllbeutel';
	@override String get antiChafingCream => 'Anti-Scheuer-Creme';
	@override String get earplugs => 'Ohrstöpsel';
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
	@override String get intimateWipes => 'Intimtücher';
	@override String get peeCloth => 'Pee-Cloth';
	@override String get razor => 'Rasierer';
	@override String get techBoxers => 'Funktions-Boxershorts';
	@override String get hikingPoles => 'Wanderstöcke (getragen)';
	@override String get sunglasses => 'Sonnenbrille';
	@override String get trailMap => 'Karte / Topo-Guide';
	@override String get spareLaces => 'Ersatzschnürsenkel';
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
	@override String get seasonalMicrospikes => 'Leichte Steigeisen (Microspikes)';
	@override String get seasonalWarmGloves => 'Warme Handschuhe';
	@override String get seasonalThermalBase => 'Thermo-Unterschicht';
	@override String get seasonalExtraWater => 'Zusätzliches Wasser';
	@override String get seasonalSunHat => 'Sonnenhut';
	@override String get seasonalElectrolytesPlus => 'Elektrolyte (Hitze)';
	@override String get seasonalGaitersMud => 'Gamaschen (Frühjahrsmatsch)';
	@override String get seasonalHeadlampSpare => 'Ersatz-Stirnlampe (kurze Tage)';
	@override String get seasonalMamExtraWater => 'Verstärkter Wasservorrat (trockene Zonen)';
}

// Path: checklist.weight
class _Translations$checklist$weight$de extends Translations$checklist$weight$fr {
	_Translations$checklist$weight$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rucksackgewicht';
	@override String get recommended => 'Empfohlenes Gewicht';
	@override String get total => 'Gesamtgewicht';
	@override String get bodyWeight => 'Körpergewicht:';
	@override String get ratio => 'Rucksack / Körper';
	@override String get perItem => 'Gewicht pro Artikel';
	@override String get edit => 'Gewicht ändern';
	@override String get grams => 'g';
	@override String get kilograms => 'kg';
	@override String get adviceUltraLight => 'Ultraleichter Rucksack — ideal fürs Trekking';
	@override String get adviceOk => 'Gut ausbalancierter Rucksack';
	@override String get adviceHeavy => 'OK aber schwer — erwäge zu erleichtern';
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
	@override String get percentOfWeight => '{pct}% des Körpergewichts';
	@override String get gaugeObjective => 'Max. Ziel: < 15% in Hütten, < 20% autark';
	@override String get itemsChecked => '{checked} / {total} Artikel angehakt';
	@override String get percentOfReference => '{pct}% des Referenzgewichts';
	@override String get gaugeObjectiveReference => 'Maximalziel: < 15% in Hütten, < 20% autark — vom Referenzgewicht';
	@override String get referenceExplainer => 'Referenzgewicht für deine Größe: {kg} kg. Die Rucksack-Obergrenze wird darauf berechnet, nicht auf deinem tatsächlichen Gewicht.';
	@override String get referenceFallbackHeight => 'Die Obergrenze deines Rucksacks wird auf deinem tatsächlichen Gewicht berechnet: für deine Größe gibt es kein veröffentlichtes Referenzgewicht, auf das man sich stützen könnte. Wir sagen es dir lieber, als dir eine falsche Zahl zu zeigen.';
	@override String get descentAlertTitle => 'Abstiege: was du trägst';
	@override String get descentAlertBody => 'Zwei Gewichte gehen mit dir bergab: {pack} kg Rucksack und {above} kg über deinem Wohlfühlgewicht. Im Abstieg wirken bei jedem Schritt 3,46 mal das mitgehende Gewicht im Knie, gegenüber 2,61 in der Ebene. Nur der Rucksack lässt sich heute ändern: mach ihn leichter, das ist bei jedem Schritt weniger.';
	@override String get descentAlertBodyPackOnly => 'Du steigst mit {pack} kg Rucksack ab. Im Abstieg wirken bei jedem Schritt 3,46 mal das mitgehende Gewicht im Knie, gegenüber 2,61 in der Ebene: mach den Rucksack leichter, das ist bei jedem Schritt weniger.';
	@override String get descentStage => '{stage}: {loss} m Abstieg';
}

// Path: checklist.ui
class _Translations$checklist$ui$de extends Translations$checklist$ui$fr {
	_Translations$checklist$ui$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ausrüstung & Rucksack';
	@override String get requirementRequired => 'Pflicht';
	@override String get addItem => 'Artikel hinzufügen';
	@override String get addItemTitle => 'Artikel hinzufügen';
	@override String get fieldName => 'Name';
	@override String get fieldWeightGrams => 'Gewicht (Gramm)';
	@override String get errorWeightGrams => 'Ungültiges Gewicht (0 bis 50 000 g)';
	@override String get errorNameRequired => 'Name erforderlich';
	@override String get add => 'Hinzufügen';
	@override String get editWeightTitle => 'Gewicht ändern';
	@override String get editCustomTitle => 'Eigenen Artikel bearbeiten';
	@override String get modify => 'Bearbeiten';
	@override String get delete => 'Löschen';
	@override String get deleteItemTitle => 'Diesen Artikel löschen?';
	@override String get deleteItemBody => 'Der Artikel "{name}" wird endgültig gelöscht.';
	@override String get requiredWarnTitle => 'Pflichtausrüstung';
	@override String get requiredWarnBody => 'Diese Ausrüstung ist aus Sicherheitsgründen Pflicht (angelehnt an UTMB-Regeln). Wirklich entfernen?';
	@override String get keep => 'Behalten';
	@override String get removeAnyway => 'Trotzdem entfernen';
	@override String get reduceQuantity => 'Menge verringern';
	@override String get increaseQuantity => 'Menge erhohen';
	@override String get addToShoppingList => 'Zur Einkaufsliste hinzufügen';
	@override String get removeFromShoppingList => 'Von der Liste entfernen';
	@override String get help => 'Hilfe';
	@override String get shoppingListTitle => 'Einkaufsliste';
	@override String get shoppingListEmpty => 'Deine Einkaufsliste ist leer. Füge Artikel mit dem Warenkorb-Button hinzu.';
	@override String get shoppingToBuy => 'Zu kaufen';
	@override String get shoppingPurchased => 'Bereits gekauft';
	@override String get share => 'TEILEN';
	@override String get infoTitle => 'Ausrüstung & Rucksack';
	@override String get infoCheckTitle => 'Artikel anhaken';
	@override String get infoCheckBody => 'Hake an, was du mitnimmst — das Gewicht wird oben neu berechnet.';
	@override String get infoRequiredTitle => 'Pflicht';
	@override String get infoRequiredBody => 'Artikel mit Schloss = Vorschrift (Pfeife, Lampe, Rettungsdecke).';
	@override String get infoGaugeTitle => 'Gewichtsanzeige';
	@override String get infoGaugeBody => 'Ziel: Rucksack < 15% deines Gewichts. Grün = OK, Orange = Achtung, Rot = zu schwer.';
	@override String get infoAddTitle => 'Hinzufügen';
	@override String get infoAddBody => 'Der +-Button unten in jeder Kategorie für eigene Artikel.';
	@override String get infoValidateBody => 'Bestätige, wenn dein Rucksack fertig ist — ein Haken erscheint auf der Startseite.';
	@override String get infoUnderstood => 'Verstanden!';
	@override String get prepTitle => 'Rucksack packen';
	@override String get prepCounter => '{prepared} / {total} Artikel gepackt';
	@override String get prepAllReady => 'Alles bereit! Gute Tour';
	@override String get preDepartureTitle => 'Checkliste vor dem Start';
	@override String get preDepartureCounter => '{checked}/{total} geprüft';
	@override String get preDep1 => 'Wetter der nächsten Tage prüfen';
	@override String get preDep2 => 'Telefon + Powerbank laden';
	@override String get preDep3 => 'Eine nahestehende Person über die Route informieren';
	@override String get preDep4 => 'Prüfen, dass der Rucksack gut geschlossen und wasserdicht ist';
	@override String get preDep5 => 'Trinkflaschen füllen (mindestens 2L)';
	@override String get preDep6 => 'Sonnencreme und Anti-Scheuer-Creme auftragen';
	@override String get preDep7 => 'Schnürsenkel und Schuhsitz prüfen';
	@override String get preDep8 => 'Offline-Karten herunterladen';
	@override String get bagOk => 'RUCKSACK OK — STARTBEREIT';
	@override String get validateBag => 'RUCKSACK BESTÄTIGEN';
	@override String get cancelValidation => 'BESTÄTIGUNG AUFHEBEN';
	@override String get shoppingListButton => 'EINKAUFSLISTE';
	@override String get shareGroup => 'MIT DER GRUPPE TEILEN';
	@override String get exportList => 'LISTE EXPORTIEREN';
	@override String get bagValidTitle => 'Rucksack bestätigt';
	@override String get bagValidBody => 'Alle {total} Pflichtartikel sind im Rucksack.\n\nGesamtgewicht: {weight} kg ({pct}% des Referenzgewichts)\n\nBist du sicher, dass dein Rucksack fertig ist?';
	@override String get checkAgain => 'Nochmal prüfen';
	@override String get yesBagOk => 'Ja, Rucksack OK';
	@override String get bagValidatedSnack => 'Rucksack bestätigt!';
	@override String get validationCancelledSnack => 'Bestätigung aufgehoben — du kannst deine Ausrüstung ändern.';
	@override String get missingTitle => 'Fehlende Ausrüstung';
	@override String get missingBody => '{checked}/{total} Pflichtartikel angehakt.';
	@override String get missingList => 'Es fehlt:';
	@override String get understood => 'Verstanden';
	@override String get validateAnyway => 'Trotzdem bestätigen';
	@override String get bagValidatedMissingSnack => 'Rucksack bestätigt (mit fehlenden Artikeln)!';
	@override String get shareGroupHint => 'Tritt einer Gruppe bei, um deine Checkliste zu teilen.';
}

// Path: checklist.seasons
class _Translations$checklist$seasons$de extends Translations$checklist$seasons$fr {
	_Translations$checklist$seasons$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get winter => 'Winter';
	@override String get spring => 'Frühling';
	@override String get summer => 'Sommer';
	@override String get autumn => 'Herbst';
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

// Path: feasibility.gaps
class _Translations$feasibility$gaps$de extends Translations$feasibility$gaps$fr {
	_Translations$feasibility$gaps$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get elevationPerDay => 'Täglicher Anstieg zu hoch gegenüber Ihrer Gewohnheit';
	@override String get distancePerDay => 'Tägliche Distanz über Ihrer Erfahrung';
	@override String get consecutiveDays => 'Mehr aufeinanderfolgende Tage als je gemacht';
	@override String get technicity => 'Geländetechnik über Ihrem Niveau';
	@override String get risk => 'Hohes Risikoniveau für diesen Trek';
	@override String get fitness => 'Form beim 6-Minuten-Test unzureichend';
	@override String get effort => 'Gesamtanstrengung (IBP) über Ihrer Erfahrung';
}

// Path: feasibility.formula
class _Translations$feasibility$formula$de extends Translations$feasibility$formula$fr {
	_Translations$feasibility$formula$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Machbarkeit für diese Tour';
	@override String get intro => 'Wir vergleichen den Aufwand jedes Wandertags mit dem, was dein Profil schafft. Grün, Orange oder Rot.';
	@override String ceilingLabel({required Object value, required Object level}) => 'Empfohlene Obergrenze: ${value} Energie-km/Tag (${level})';
	@override String get stagesTitle => 'Tag für Tag';
	@override String stageEffort({required Object distance, required Object elevation, required Object effort}) => '${distance} km + ${elevation} m Aufstieg = ${effort} Energie-km';
	@override String get globalTitle => 'Gesamturteil';
	@override String hardestStage({required Object stage}) => 'Anspruchsvollster Tag: ${stage}';
	@override String daysOver({required Object count}) => '${count} Tag(e) über deiner Obergrenze';
	@override String get daysOverNone => 'Kein Tag über deiner Obergrenze';
	@override String limitingLabel({required Object factor}) => 'Begrenzender Faktor: ${factor}';
	@override String trainingReco({required Object weeks}) => 'Empfohlenes Training: ${weeks} Wochen vor dem Start';
	@override String get adviceTitle => 'Tipps für deinen Plan';
	@override String generateProgram({required Object days}) => 'Meinen Plan erstellen (${days} Tage)';
	@override String generateProgramDone({required Object days}) => 'Plan über ${days} Tage erstellt — passe ihn nach Wunsch an.';
	@override String get noStages => 'Noch kein Tag zu bewerten.';
	@override late final _Translations$feasibility$formula$levels$de levels = _Translations$feasibility$formula$levels$de._(_root);
	@override late final _Translations$feasibility$formula$verdicts$de verdicts = _Translations$feasibility$formula$verdicts$de._(_root);
	@override late final _Translations$feasibility$formula$limitingFactors$de limitingFactors = _Translations$feasibility$formula$limitingFactors$de._(_root);
	@override late final _Translations$feasibility$formula$advice$de advice = _Translations$feasibility$formula$advice$de._(_root);
	@override String retainedPlan({required Object days}) => 'Gewählte Aufteilung: ${days} Wandertage.';
	@override String retainedPlanNone({required Object days}) => 'Keine Aufteilung gewählt: die Tour bleibt bei ihren ${days} Standardtagen.';
	@override String get energyUnitNotice => '1 km in der Ebene entspricht 42 m Aufstieg: das ist der gemessene Aufwand des Bergaufgehens, keine Hausregel.';
	@override String get circuitTitle => 'Urteil zur Runde';
	@override String circuitScore({required Object value}) => 'Wert der Runde: ${value}';
	@override String get circuitIsWorstStage => 'Das Urteil zur Runde ist das deines härtesten Tages: nichts anderes macht es härter.';
	@override String restWindowWhole({required Object days}) => 'Ruhe über den ganzen Trek gemessen (${days} Tage).';
	@override String restWindowSlice({required Object start, required Object end}) => 'Ruhe über die schlechteste Woche gemessen: Tage ${start} bis ${end}.';
	@override String get restNotApplicable => 'Auf einem Weg von einem einzigen Tag lässt sich die Ruhe nicht berechnen: es gibt keine Verkettung zu messen. Die Bedingung wird als nicht anwendbar erklärt, sie wird nicht durch eine Zahl ersetzt.';
	@override String get restExtrapolation => 'Die Ruhe-Schwelle stammt aus einer Messung an Sportlern und wurde auf das Weitwandern übertragen. Es ist eine Übertragung, und sie wird als solche genannt.';
	@override String get restNotDecisive => 'Diese Zahl wird angezeigt und berät, sie entscheidet nie: dein Urteil bleibt das deines härtesten Tages.';
	@override String restAdvisedLine({required Object days}) => 'Empfehlung: ${days} über dein Programm verteilte Ruhetage bringen diese Zahl wieder unter ihre Schwelle.';
	@override String get restTwoDays => 'Bei gleich großen Tagen reicht ein Ruhetag pro Woche nicht: es braucht zwei.';
	@override String habitGap({required Object value}) => 'Abstand zu deiner Gewohnheit: ${value} (Richtwert 0,8 bis 1,3).';
	@override String get habitGapNotDecisive => 'Dieser Abstand wird angezeigt, ist aber nie entscheidend: keine Studie belegt, dass er irgendetwas verursacht.';
	@override String get conditionsTitle => 'Was in dieses Urteil eingeflossen ist';
	@override String floorActive({required Object value}) => 'Dein bester bereits durchgehaltener Tag (${value} Energie-km) liegt über der Obergrenze deiner Stufe: er dient als Basis. Dir wird nie gesagt, du könntest nicht, was du schon getan hast.';
	@override String altitudeApplied({required Object value, required Object pct}) => 'Höhe: ${value} m am höchsten Punkt, deine Tageskapazität sinkt um ${pct} %.';
	@override String altitudeBelowThreshold({required Object value}) => 'Höhe: ${value} m am höchsten Punkt, unter den 1 500 m, ab denen sie zählt. Sie ändert hier nichts.';
	@override String get altitudeMissing => 'Höhe: die Spur dieses Weges trägt keine. Sie ändert hier nichts mangels Daten — und nicht, weil sie ohne Wirkung wäre.';
	@override String get heatApplied => 'Aufbruch im Sommer: die aerobe Kapazität sinkt um 7 %, das ist gemessen.';
	@override String get seasonNoSource => 'Aufbruch im Frühling oder Herbst: keine veröffentlichte Messung erlaubt es, eine Wirkung zu beziffern. Die Jahreszeit ändert hier nichts, mangels Quelle.';
	@override String get seasonMissing => 'Kein Aufbruchsdatum gesetzt: die Jahreszeit ändert hier nichts, mangels Daten.';
	@override String get massNotCounted => 'Weder dein Gewicht noch das deines Rucksacks fließt in dieses Urteil ein, und das ist gewollt: es misst, was du nachweislich durchhältst. Mit 65 oder mit 95 kg erhält derselbe Mann dasselbe Urteil.';
	@override String get winterInvalid => 'Aufbruch im Winter: dieses Urteil hält nicht mehr. Wegbewertungen gelten nur bei gutem Wetter, trockenem Gelände und angepasster Schneelage. Wir verschärfen die Zahl nicht, wir sagen dir, dass sie nicht gilt.';
	@override String restDaysCounted({required Object count}) => 'In diesem Urteil gezählte Ruhetage: ${count}.';
	@override String get restDaysNone => 'In deinem Programm ist kein Ruhetag gesetzt: setze welche, und diese Zahl bewegt sich.';
	@override String averageLoad({required Object value, required Object worst}) => 'Mittlere Tageslast: ${value} (die härteste liegt bei ${worst}).';
	@override String get averageLoadInfo => 'Diese beiden Zahlen liest man zusammen: weit auseinander hat der Trek einen harten Tag; nahe beieinander ist er jeden Tag hart. Das wird angezeigt, es entscheidet nicht.';
	@override String durationStatement({required Object days, required Object done}) => 'Dieser Trek dauert ${days} Wandertage; deine längste zusammenhängende Tour beträgt ${done} Tage.';
	@override String get durationStatementInfo => 'Das wird angezeigt, es entscheidet nicht: keine veröffentlichte Messung sagt, ab wie vielen zusammenhängenden Tagen ein Wanderer einbricht. Beurteile es selbst.';
	@override String stageDominantFactor({required Object factor}) => 'Was an diesem Tag am schwersten wiegt: ${factor}';
}

// Path: feasibility.flow
class _Translations$feasibility$flow$de extends Translations$feasibility$flow$fr {
	_Translations$feasibility$flow$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bist du bereit für diese Tour?';
	@override String get intro => 'Beantworte 3 kurze Schritte: Wir ermitteln dein echtes Niveau und sagen dir, ob die Tour machbar ist.';
	@override String progress({required Object done, required Object total}) => '${done}/${total} Schritte erledigt';
	@override String get stepProfile => 'Dein Infoblatt';
	@override String get stepProfileSub => 'Alter, Größe, Gewicht (bleibt auf deinem Handy).';
	@override String get stepWalkTest => '6-Minuten-Gehtest';
	@override String get stepWalkTestSub => 'Misst deine aktuelle Form — verändert dein Ergebnis.';
	@override String get stepPastHikes => 'Deine letzten 5 Touren';
	@override String get stepPastHikesSub => 'Was du schon geschafft hast: Tempo, Distanz, Höhenmeter.';
	@override String get optionalTag => '(optional)';
	@override String get validate => 'Bestätigen und Ergebnis ansehen';
	@override String get partialNotice => 'Vorläufiges Ergebnis: der 6-Minuten-Gehtest wurde nicht gemacht. Dein Niveau wird standardmäßig geschätzt; mach den Test für ein genaueres Urteil.';
	@override String get missingTitle => 'Es fehlen noch Angaben';
	@override String get missingIntro => 'Das Urteil erscheint erst, wenn alle nötigen Kriterien ausgefüllt sind. Es fehlt noch:';
	@override String get missingProfile => 'Dein vollständiges Infoblatt: Alter, Größe und Gewicht';
	@override String get missingPastHikes => 'Mindestens eine deiner 5 letzten Touren';
	@override String get missingWalkTestNote => 'Der 6-Minuten-Test bleibt optional: ohne ihn wird dein Ergebnis als vorläufig angezeigt.';
	@override String get hintBlocked => 'Vervollständige die Kriterien oben: dort entscheidet sich dein Urteil.';
	@override String get hintReady => 'Alles da: du kannst dein Ergebnis ansehen.';
}

// Path: tips.seasons
class _Translations$tips$seasons$de extends Translations$tips$seasons$fr {
	_Translations$tips$seasons$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get all => 'Ganzjährig';
	@override String get winter => 'Winter';
	@override String get spring => 'Frühling';
	@override String get summer => 'Sommer';
	@override String get autumn => 'Herbst';
}

// Path: tips.themes
class _Translations$tips$themes$de extends Translations$tips$themes$fr {
	_Translations$tips$themes$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get gear => 'Ausrüstung';
	@override String get safety => 'Sicherheit';
	@override String get health => 'Gesundheit';
	@override String get weather => 'Wetter';
	@override String get refuge => 'Hüttenleben';
	@override String get nature => 'Natur';
	@override String get other => 'Sonstiges';
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

// Path: signalement.water
class _Translations$signalement$water$de extends Translations$signalement$water$fr {
	_Translations$signalement$water$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get reportAction => 'Zustand melden';
	@override String get reportCount => '{n} Meldung(en)';
	@override String get sheetTitle => 'Zustand der Wasserstelle?';
	@override String get latencyHint => 'Nach Netzwerk-Synchronisierung mit anderen Wanderern geteilt.';
	@override String get saved => 'Danke! Zustand gespeichert.';
	@override late final _Translations$signalement$water$states$de states = _Translations$signalement$water$states$de._(_root);
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
	@override String get connectivite => 'Konnektivität';
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
	@override String get conditionsTitle => 'Geländezustand';
	@override String get noComments => 'Noch kein Zustand gemeldet.';
	@override String get commentsError => 'Zustand nicht verfügbar.';
	@override String get report => 'Melden';
	@override String get reportAck => 'Meldung gespeichert. Sie wird nach der Synchronisierung geprüft.';
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
	@override String get titleWaypoint => 'Wegpunkt hinzufügen';
	@override String get titleComment => 'Zustand melden';
	@override String get chooseType => 'Wegpunkttyp';
	@override String get titleField => 'Titel des Wegpunkts';
	@override String get conditionPrompt => 'Beschreiben Sie den beobachteten Zustand';
	@override String get commentField => 'Ihre Beobachtung';
	@override String get conditionField => 'Zustand (optional)';
	@override String get conditionHelper => 'z. B. Wasser versiegt, Wasser fliesst, rutschige Stelle';
	@override String get latencyBanner => 'Wird bei der nächsten Synchronisierung veröffentlicht.';
	@override String get submit => 'Speichern';
	@override String get savedTitle => 'Beitrag gespeichert';
	@override String get savedPendingSync => 'Er wird veröffentlicht, sobald das Netz wieder da ist.';
	@override String pendingCount({required Object n}) => '${n} warten auf Synchronisierung';
	@override String get close => 'Schliessen';
	@override String get emptyTitle => 'Bitte einen Titel für den Wegpunkt angeben.';
	@override String get emptyComment => 'Bitte Ihre Beobachtung eingeben.';
	@override String get noLocation => 'GPS-Position nicht verfügbar. Unter freiem Himmel erneut versuchen.';
	@override String get error => 'Speichern derzeit nicht möglich.';
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

// Path: health.error
class _Translations$health$error$de extends Translations$health$error$fr {
	_Translations$health$error$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Ungültige Blutgruppe (A+, A-, B+, B-, AB+, AB-, O+, O-)';
}

// Path: health.a11y
class _Translations$health$a11y$de extends Translations$health$a11y$fr {
	_Translations$health$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get form => 'Formular für Gesundheitsinformationen';
	@override String get saveButton => 'Gesundheitsinformationen speichern';
}

// Path: health.delete
class _Translations$health$delete$de extends Translations$health$delete$fr {
	_Translations$health$delete$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get button => 'Meine Karte löschen';
	@override String get a11yButton => 'Meine Gesundheitskarte löschen — endgültige Aktion';
	@override String get confirmTitle => 'Gesundheitskarte löschen?';
	@override String get confirmBody => 'Endgültig und lokal. Deine Daten werden von diesem Telefon entfernt.';
	@override String get cancel => 'Abbrechen';
	@override String get confirm => 'Löschen';
	@override String get done => 'Gesundheitskarte gelöscht.';
}

// Path: health.consent
class _Translations$health$consent$de extends Translations$health$consent$fr {
	_Translations$health$consent$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get purpose => 'Diese Infos helfen den Rettungskräften. Sie bleiben auf deinem Telefon, werden nie ins Internet gesendet.';
	@override String get manage => 'Meine Gesundheits-Einwilligung verwalten';
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

// Path: erasure.a11y
class _Translations$erasure$a11y$de extends Translations$erasure$a11y$fr {
	_Translations$erasure$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get entry => 'Meine Daten löschen, öffnet eine Bestätigungsabfrage';
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

// Path: programme.duration
class _Translations$programme$duration$de extends Translations$programme$duration$fr {
	_Translations$programme$duration$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get label => 'Anzahl der Tage';
	@override String get days => '{count} T';
	@override String get daysWithRest => '{total} T (davon {rest} Ruhe)';
	@override String get splitNote => 'Mehr Tage = die härtesten Tage werden zweigeteilt, der schwerste zuerst. Ruhe ändert nicht, wie hart ein einzelner Tag ist.';
	@override String get splitExhausted => 'Alle Tage sind schon so kurz wie möglich geteilt: Der Regler entlastet das Urteil nicht weiter.';
	@override late final _Translations$programme$duration$difficulty$de difficulty = _Translations$programme$duration$difficulty$de._(_root);
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
	@override String get locked => 'Tag bereits gelaufen: nicht mehr änderbar';
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

// Path: programme.splitBlocked
class _Translations$programme$splitBlocked$de extends Translations$programme$splitBlocked$fr {
	_Translations$programme$splitBlocked$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get single => 'Teilen nicht möglich: An diesem Tag gibt es nichts zu teilen.';
	@override String get portion => 'Teilen nicht möglich: Diese Etappe ist bereits zweigeteilt.';
	@override String get locked => 'Tag bereits gelaufen: nicht mehr änderbar';
}

// Path: programme.inTrek
class _Translations$programme$inTrek$de extends Translations$programme$inTrek$fr {
	_Translations$programme$inTrek$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Route anpassen';
	@override String get intro => 'Gestalte den Rest deiner Tour neu. Bereits Gelaufenes ist fixiert, und die Reihenfolge der Etappen bleibt.';
	@override String get doneSection => 'Bereits gelaufen';
	@override String get upcomingSection => 'Noch vor dir';
	@override String get doneBadge => 'Erledigt';
	@override String get lockedDay => 'Tag bereits gelaufen, gesperrt';
	@override String get allDone => 'Du hast alle Tage gelaufen: es gibt nichts mehr anzupassen.';
	@override String get notStarted => 'Dieser Bildschirm ist für unterwegs: starte deine Tour, um den weiteren Verlauf anzupassen.';
	@override String get validate => 'Änderungen speichern';
	@override String get saved => 'Programm aktualisiert';
	@override late final _Translations$programme$inTrek$info$de info = _Translations$programme$inTrek$info$de._(_root);
	@override late final _Translations$programme$inTrek$empty$de empty = _Translations$programme$inTrek$empty$de._(_root);
}

// Path: calendar.weekdays
class _Translations$calendar$weekdays$de extends Translations$calendar$weekdays$fr {
	_Translations$calendar$weekdays$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get mon => 'Mo';
	@override String get tue => 'Di';
	@override String get wed => 'Mi';
	@override String get thu => 'Do';
	@override String get fri => 'Fr';
	@override String get sat => 'Sa';
	@override String get sun => 'So';
}

// Path: calendar.legend
class _Translations$calendar$legend$de extends Translations$calendar$legend$fr {
	_Translations$calendar$legend$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get start => 'Abreise';
	@override String get walk => 'Wandern';
	@override String get rest => 'Ruhe';
	@override String get arrival => 'Ankunft';
}

// Path: calendar.summary
class _Translations$calendar$summary$de extends Translations$calendar$summary$fr {
	_Translations$calendar$summary$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get totalDays => 'Tage gesamt';
	@override String get walkDays => 'Wandertage';
	@override String get restDays => 'Ruhetage';
}

// Path: calendar.noDate
class _Translations$calendar$noDate$de extends Translations$calendar$noDate$fr {
	_Translations$calendar$noDate$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wähle ein Abreisedatum';
	@override String get message => 'Dein Trek-Kalender wird automatisch mit Wander- und Ruhetagen angezeigt.';
}

// Path: calendar.empty
class _Translations$calendar$empty$de extends Translations$calendar$empty$fr {
	_Translations$calendar$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Richte zuerst deine Route ein';
	@override String get message => 'Wähle deine Route und Dauer, um deine Daten festzulegen.';
	@override String get action => 'ROUTE EINRICHTEN';
}

// Path: nuitees.types
class _Translations$nuitees$types$de extends Translations$nuitees$types$fr {
	_Translations$nuitees$types$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Berghütte';
	@override String get gite => 'Herberge';
	@override String get bivouac => 'Biwak';
	@override String get autreHebergement => 'Andere Unterkunft';
}

// Path: nuitees.guide
class _Translations$nuitees$guide$de extends Translations$nuitees$guide$fr {
	_Translations$nuitees$guide$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Übernachtungs-Ratgeber';
	@override String get refuge => 'Bergunterkunft, Reservierung in der Hochsaison empfohlen.';
	@override String get gite => 'Private Etappenherberge, oft mit Mahlzeiten und Duschen.';
	@override String get bivouac => 'Zeltcamping, je nach örtlicher Regelung.';
	@override String get autre => 'Hotel, Gästehaus oder Campingplatz abseits des Weges.';
	@override String get close => 'Verstanden';
}

// Path: nuitees.card
class _Translations$nuitees$card$de extends Translations$nuitees$card$fr {
	_Translations$nuitees$card$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get dayLabel => 'T{n}';
	@override String get noPlace => 'Unterkunft';
	@override String get available => '{count} Unterkünfte verfügbar';
	@override String get call => '{phone} anrufen';
	@override String get lockedHint => 'Nacht abwählen, um den Typ zu ändern';
	@override String get eveBadge => 'T-1';
	@override String get eveOfDeparture => 'Nacht vor dem Aufbruch';
}

// Path: nuitees.summary
class _Translations$nuitees$summary$de extends Translations$nuitees$summary$fr {
	_Translations$nuitees$summary$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get remaining => 'Noch {count} Nacht/Nächte';
	@override String get done => '{count} erledigt';
	@override String get allBooked => 'ALLE NÄCHTE GEBUCHT';
}

// Path: nuitees.empty
class _Translations$nuitees$empty$de extends Translations$nuitees$empty$fr {
	_Translations$nuitees$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Richten Sie zuerst Ihre Route ein';
	@override String get message => 'Wählen Sie Strecke und Dauer, um Ihre Nächte zu planen.';
	@override String get action => 'ROUTE EINRICHTEN';
}

// Path: transport.a11y
class _Translations$transport$a11y$de extends Translations$transport$a11y$fr {
	_Translations$transport$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String call({required Object label}) => '${label} anrufen';
	@override String get website => 'Website öffnen';
}

// Path: fireRisk.update
class _Translations$fireRisk$update$de extends Translations$fireRisk$update$fr {
	_Translations$fireRisk$update$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get live => 'Daten aktuell';
	@override String liveAt({required Object date}) => 'Akt.: ${date}';
	@override String cacheRecent({required Object duration}) => 'Aktualisiert vor ${duration}';
	@override String cacheOld({required Object date}) => 'Letzte Akt.: ${date}';
	@override String get never => 'Nie aktualisiert';
}

// Path: fireRisk.duration
class _Translations$fireRisk$duration$de extends Translations$fireRisk$duration$fr {
	_Translations$fireRisk$duration$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get seconds => 'einige Sekunden';
	@override String minutes({required Object n}) => '${n} Min';
	@override String hours({required Object n}) => '${n} Std';
	@override String days({required Object n}) => '${n} T';
}

// Path: fireRisk.regulation
class _Translations$fireRisk$regulation$de extends Translations$fireRisk$regulation$fr {
	_Translations$fireRisk$regulation$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vorschriften';
	@override String get decreeLink => 'Präfektorale Erlasse ansehen';
}

// Path: fireRisk.level
class _Translations$fireRisk$level$de extends Translations$fireRisk$level$fr {
	_Translations$fireRisk$level$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get none => 'Keine';
	@override String get low => 'Gering';
	@override String get moderate => 'Mäßig';
	@override String get high => 'Hoch';
	@override String get veryHigh => 'Sehr hoch';
	@override String get extreme => 'Extrem';
}

// Path: fireRisk.day
class _Translations$fireRisk$day$de extends Translations$fireRisk$day$fr {
	_Translations$fireRisk$day$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get today => 'Heute';
	@override String get tomorrow => 'Morgen';
	@override String plus({required Object n}) => 'T+${n}';
}

// Path: fireRisk.number
class _Translations$fireRisk$number$de extends Translations$fireRisk$number$fr {
	_Translations$fireRisk$number$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get firefighters => 'Feuerwehr';
	@override String get europeanEmergency => 'Europ. Notruf';
}

// Path: fireRisk.empty
class _Translations$fireRisk$empty$de extends Translations$fireRisk$empty$fr {
	_Translations$fireRisk$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Brandrisiko nicht verfügbar';
	@override String get message => 'Die zur Berechnung des Brandrisikos nötigen Wetterdaten sind derzeit nicht verfügbar. Versuchen Sie es erneut, sobald Sie verbunden sind.';
}

// Path: fireRisk.a11y
class _Translations$fireRisk$a11y$de extends Translations$fireRisk$a11y$fr {
	_Translations$fireRisk$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String call({required Object label, required Object number}) => '${label} unter ${number} anrufen';
	@override String get decree => 'Präfektorale Erlasse öffnen';
	@override String levelBadge({required Object level}) => 'Risikostufe ${level} von 5';
}

// Path: shop.a11y
class _Translations$shop$a11y$de extends Translations$shop$a11y$fr {
	_Translations$shop$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String openDetail({required Object name}) => 'Details zu ${name} anzeigen';
	@override String call({required Object label}) => '${label} anrufen';
	@override String get website => 'Website öffnen';
}

// Path: summary.stats
class _Translations$summary$stats$de extends Translations$summary$stats$fr {
	_Translations$summary$stats$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Statistiken';
	@override String get distance => 'Gesamtdistanz';
	@override String get elevationGain => 'Aufstieg gesamt';
	@override String get elevationLoss => 'Abstieg gesamt';
	@override String get duration => 'Geschätzte Zeit';
	@override String get stages => 'Etappen';
	@override String get restDays => 'Ruhetage';
}

// Path: summary.actions
class _Translations$summary$actions$de extends Translations$summary$actions$fr {
	_Translations$summary$actions$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get share => 'MEINEN PLAN TEILEN';
}

// Path: summary.share
class _Translations$summary$share$de extends Translations$summary$share$fr {
	_Translations$summary$share$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String titleLine({required Object name}) => 'Mein ${name}';
	@override String walkDays({required Object days}) => '${days} Wandertage';
	@override String walkDaysWithRest({required Object days, required Object rest}) => '${days} Wandertage + ${rest} Ruhetage';
	@override String distance({required Object km}) => 'Distanz: ${km} km';
	@override String elevationGain({required Object m}) => 'Aufstieg gesamt: ${m} m';
	@override String elevationLoss({required Object m}) => 'Abstieg gesamt: ${m} m';
	@override String duration({required Object h}) => 'Geschätzte Zeit: ~${h} h';
	@override String dates({required Object start, required Object end}) => 'Vom ${start} bis ${end}';
	@override String get planning => '--- Tagesplan ---';
	@override String dayRest({required Object n}) => 'T${n}: Ruhetag';
	@override String dayStages({required Object n, required Object stages}) => 'T${n}: ${stages}';
	@override String footer({required Object name}) => 'Geplant mit ${name}';
}

// Path: summary.empty
class _Translations$summary$empty$de extends Translations$summary$empty$fr {
	_Translations$summary$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Richten Sie zuerst Ihre Route ein';
	@override String get message => 'Wählen Sie Ihre Route und Dauer, um die Planübersicht zu sehen.';
	@override String get action => 'ROUTE EINRICHTEN';
}

// Path: summary.a11y
class _Translations$summary$a11y$de extends Translations$summary$a11y$fr {
	_Translations$summary$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String dayTile({required Object day}) => 'Details für Tag ${day} anzeigen';
	@override String restDayTile({required Object day}) => 'Details zum Ruhetag ${day}';
	@override String get share => 'Meinen Plan teilen';
}

// Path: myTreks.badge
class _Translations$myTreks$badge$de extends Translations$myTreks$badge$fr {
	_Translations$myTreks$badge$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get owned => 'Im Besitz';
	@override String get prepared => 'Vorbereitet';
	@override String get inProgress => 'Laufend';
	@override String get completed => 'Abgeschlossen';
}

// Path: myTreks.a11y
class _Translations$myTreks$a11y$de extends Translations$myTreks$a11y$fr {
	_Translations$myTreks$a11y$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String trekCard({required Object nom, required Object state}) => 'Tour ${nom}, ${state}';
	@override String openTrek({required Object nom}) => 'Tour ${nom} öffnen';
}

// Path: trekState.abandonDialog
class _Translations$trekState$abandonDialog$de extends Translations$trekState$abandonDialog$fr {
	_Translations$trekState$abandonDialog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Eine Tour läuft bereits';
	@override String get message => 'Du hast eine laufende Wanderung. Beende oder brich sie ab, bevor du eine neue startest.';
	@override String get finish => 'Beenden';
	@override String get abandon => 'Abbrechen';
	@override String get cancel => 'Zurück';
}

// Path: trekState.resumeOrphanDialog
class _Translations$trekState$resumeOrphanDialog$de extends Translations$trekState$resumeOrphanDialog$fr {
	_Translations$trekState$resumeOrphanDialog$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Wanderung fortsetzen?';
	@override String get message => 'Beim letzten Schließen der App lief noch eine Wanderung. Möchtest du sie fortsetzen oder abbrechen?';
	@override String get resume => 'Fortsetzen';
	@override String get abandon => 'Abbrechen';
}

// Path: walkTest.levels
class _Translations$walkTest$levels$de extends Translations$walkTest$levels$fr {
	_Translations$walkTest$levels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get low => 'Niedrig';
	@override String get moderate => 'Mittel';
	@override String get good => 'Gut';
	@override String get excellent => 'Ausgezeichnet';
}

// Path: ffrando.effortLevels
class _Translations$ffrando$effortLevels$de extends Translations$ffrando$effortLevels$fr {
	_Translations$ffrando$effortLevels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get k1 => 'Sehr leicht';
	@override String get k2 => 'Leicht';
	@override String get k3 => 'Mittel';
	@override String get k4 => 'Schwer';
	@override String get k5 => 'Sehr schwer';
}

// Path: sos.medicalId
class _Translations$sos$medicalId$de extends Translations$sos$medicalId$fr {
	_Translations$sos$medicalId$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get action => 'Notfallpass des Telefons';
	@override String get hint => 'Zeigen Sie den Rettungskräften Ihre Vitaldaten, auch im Sperrbildschirm.';
	@override String get unavailable => 'Öffnen Sie den Notfallpass in den Gesundheitseinstellungen Ihres Telefons.';
}

// Path: map.guide.poi
class _Translations$map$guide$poi$de extends Translations$map$guide$poi$fr {
	_Translations$map$guide$poi$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get water => 'Quelle oder Brunnen am Weg. Eine Quelle kann im Sommer trocken sein: verlassen Sie sich nicht ungeprüft darauf.';
	@override String get shelter => 'Hütte oder Schutzhütte auf der Route. Tippen Sie auf die Markierung für das Bekannte: Höhe, Leistungen, Kontakt.';
	@override String get accommodation => 'Unterkunft außer einer Hütte: Pension, Zimmer, Hotel. Die Buchung läuft über den Betrieb selbst.';
	@override String get campsite => 'Camping- oder Biwakplatz. Die Biwakregeln hängen vom Gebiet ab: erkundigen Sie sich, bevor Sie das Zelt aufstellen.';
	@override String get shop => 'Geschäft zum Auffüllen der Vorräte. Öffnungszeiten sind außerhalb der Saison nicht garantiert: planen Sie Reserve ein.';
	@override String get restaurant => 'Restaurant oder Gasttisch an oder nahe der Route.';
	@override String get viewpoint => 'Bemerkenswerter Aussichtspunkt. Ein Halt, keine Orientierungshilfe.';
	@override String get danger => 'Als heikel gemeldete Stelle. Werden Sie langsamer und schauen Sie sich das Gelände an, bevor Sie hineingehen.';
	@override String get emergency => 'Notfallpunkt: Station, Landeplatz oder Notrufsäule.';
	@override String get info => 'Informationstafel oder Infopunkt am Weg.';
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

// Path: feasibility.formula.levels
class _Translations$feasibility$formula$levels$de extends Translations$feasibility$formula$levels$fr {
	_Translations$feasibility$formula$levels$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get beginner => 'Anfänger';
	@override String get intermediate => 'Fortgeschritten';
	@override String get confirmed => 'Erfahren';
	@override String get expert => 'Experte';
}

// Path: feasibility.formula.verdicts
class _Translations$feasibility$formula$verdicts$de extends Translations$feasibility$formula$verdicts$fr {
	_Translations$feasibility$formula$verdicts$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get green => 'Aufteilung machbar';
	@override String get orange => 'Aufteilung fordernd';
	@override String get red => 'Aufteilung zu knapp';
}

// Path: feasibility.formula.limitingFactors
class _Translations$feasibility$formula$limitingFactors$de extends Translations$feasibility$formula$limitingFactors$fr {
	_Translations$feasibility$formula$limitingFactors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get distance => 'die Tagesdistanz';
	@override String get elevation => 'der Höhenunterschied';
	@override String get chaining => 'die Abfolge der Tage';
	@override String get none => 'keiner';
	@override String get altitude => 'die Höhe';
	@override String get heat => 'die Hitze der Jahreszeit';
}

// Path: feasibility.formula.advice
class _Translations$feasibility$formula$advice$de extends Translations$feasibility$formula$advice$fr {
	_Translations$feasibility$formula$advice$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get balancedOk => 'Dein Plan ist ausgewogen: Halte eine Reserve und höre auf deinen Körper.';
	@override String get balanced => 'Verteile die Etappen, um den Aufwand über die Tage zu glätten.';
	@override String optimalDays({required Object days, required Object current}) => 'Plane ${days} Wandertage (statt ${current}), um unter deiner Obergrenze zu bleiben.';
	@override String split({required Object stage}) => 'Teile Tag ${stage} in zwei: Er überschreitet deutlich deine Obergrenze.';
	@override String splitImpossible({required Object stage}) => 'Tag ${stage} liegt auch zweigeteilt über Ihren Möglichkeiten, und kürzer lässt er sich nicht teilen: Das ist keine Frage der Planung mehr. Trainieren Sie, warten Sie auf mildere Bedingungen, oder wählen Sie einen leichteren Weg.';
	@override String rest({required Object stages}) => 'Plane einen Ruhetag nach Tag ${stages}.';
	@override String training({required Object weeks}) => 'Trainiere ${weeks} Wochen vor dem Start (körperliche Vorbereitung).';
	@override String restAdvised({required Object days, required Object stages}) => 'Setze ${days} Ruhetag(e) ein, nach den Tagen ${stages}: sie gleichen sich zu sehr, als dass sich der Körper erholen könnte. Das ist ein Rat, er ändert dein Urteil nicht.';
}

// Path: signalement.water.states
class _Translations$signalement$water$states$de extends Translations$signalement$water$states$fr {
	_Translations$signalement$water$states$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get available => 'Wasser verfügbar';
	@override String get low => 'Geringer Durchfluss';
	@override String get dry => 'Trocken';
	@override String get unknown => 'Unbekannter Zustand';
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

// Path: programme.duration.difficulty
class _Translations$programme$duration$difficulty$de extends Translations$programme$duration$difficulty$fr {
	_Translations$programme$duration$difficulty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get comfortable => 'Gemütlich';
	@override String get standard => 'Standard';
	@override String get sporty => 'Sportlich';
	@override String get demanding => 'Sehr anspruchsvoll';
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
	@override String get body => 'Zusammenlegen verbindet zwei Tage zu einem; Teilen schneidet einen Tag in zwei — seine Etappen, wenn sie zusammengelegt waren, sonst die Etappe selbst in zwei Hälften gleicher Anstrengung. Das Urteil richtet sich nach Ihrem härtesten Tag: ihn zu teilen ist der einzige Weg, ihn zu entlasten, ein Ruhetag ändert daran nichts. Eine geteilte Etappe setzt einen Halt auf halber Strecke voraus: prüfen Sie, ob es dort eine Schlafmöglichkeit gibt.';
}

// Path: programme.info.colors
class _Translations$programme$info$colors$de extends Translations$programme$info$colors$fr {
	_Translations$programme$info$colors$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Farben';
	@override String get body => 'Grün = leicht, Orange = mittel, Rot = schwer (Distanz + Aufstieg).';
}

// Path: programme.inTrek.info
class _Translations$programme$inTrek$info$de extends Translations$programme$inTrek$info$fr {
	_Translations$programme$inTrek$info$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Route anpassen';
	@override late final _Translations$programme$inTrek$info$done$de done = _Translations$programme$inTrek$info$done$de._(_root);
	@override late final _Translations$programme$inTrek$info$upcoming$de upcoming = _Translations$programme$inTrek$info$upcoming$de._(_root);
	@override late final _Translations$programme$inTrek$info$order$de order = _Translations$programme$inTrek$info$order$de._(_root);
	@override String get close => 'Verstanden';
}

// Path: programme.inTrek.empty
class _Translations$programme$inTrek$empty$de extends Translations$programme$inTrek$empty$fr {
	_Translations$programme$inTrek$empty$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kein Programm zum Anpassen';
	@override String get message => 'Erstelle zuerst dein Programm in der Vorbereitung.';
}

// Path: programme.inTrek.info.done
class _Translations$programme$inTrek$info$done$de extends Translations$programme$inTrek$info$done$fr {
	_Translations$programme$inTrek$info$done$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Bereits gelaufene Tage';
	@override String get body => 'Sie sind ausgegraut und gesperrt: was gelaufen ist, bleibt.';
}

// Path: programme.inTrek.info.upcoming
class _Translations$programme$inTrek$info$upcoming$de extends Translations$programme$inTrek$info$upcoming$fr {
	_Translations$programme$inTrek$info$upcoming$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Kommende Tage';
	@override String get body => 'Fasse zusammen, teile auf oder füge einen Ruhetag im weiteren Verlauf ein.';
}

// Path: programme.inTrek.info.order
class _Translations$programme$inTrek$info$order$de extends Translations$programme$inTrek$info$order$fr {
	_Translations$programme$inTrek$info$order$de._(TranslationsDe root) : this._root = root, super.internal(root);

	final TranslationsDe _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reihenfolge der Etappen';
	@override String get body => 'Unterwegs ändert sich die Reihenfolge nie: bereits begonnene Etappen werden nicht getauscht.';
}

/// The flat map containing all translations for locale <de>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsDe {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'a11y.back' => 'Zurück',
			'a11y.zoomIn' => 'Vergrössern',
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
			'a11y.sos' => 'SOS-Notruf',
			'a11y.mapLayers' => 'Kartenebenen',
			'nav.accueil' => 'Start',
			'nav.map' => 'Karte',
			'nav.stages' => 'Etappen',
			'nav.currentStage' => 'Aktuelle Etappe',
			'nav.planning' => 'Planung',
			'nav.journal' => 'Tagebuch',
			'nav.more' => 'Mehr',
			'nav.checklist' => 'Ausrüstung & Rucksack',
			'nav.feasibility' => 'Machbarkeit',
			'nav.tips' => 'Trek-Tipps',
			'nav.emergency' => 'Notfallkontakte',
			'nav.catalog' => 'Wegekatalog',
			'nav.profile' => 'Profil',
			'nav.settings' => 'Einstellungen',
			'nav.trailSelection' => 'Weg wechseln',
			'nav.myTreks' => 'Meine Touren',
			'nav.back' => 'Zurück',
			'nav.home' => 'Start',
			'navPilote.appTitle' => 'StepWays',
			'navPilote.prepare' => 'Vorbereiten',
			'navPilote.hike' => 'Wandern',
			'navPilote.after' => 'Danach',
			'navPilote.sos' => 'SOS',
			'navPilote.demoLockedTitle' => ({required Object phase}) => '${phase} — nur für gekaufte Treks',
			'navPilote.demoLockedBody' => 'Im Demomodus ist nur die Vorbereitung verfügbar. Schalten Sie diesen Trek frei, um zu wandern und Ihr Abenteuer zu erleben.',
			'navPilote.demoTrekMode' => 'Trek-Modus simulieren (Demo)',
			'navPilote.exitTitle' => 'App beenden?',
			'navPilote.exitMessage' => 'Sie sind auf dem Startbildschirm. Möchten Sie die App schliessen?',
			'navPilote.exitConfirm' => 'Beenden',
			'navPilote.exitCancel' => 'Bleiben',
			'navPilote.startTrek' => 'Trek starten',
			'navPilote.finishTrek' => 'Trek beenden',
			'navPilote.reviewPrep' => 'Vorbereitung ansehen',
			'navPilote.startGateSubtitle' => 'Route, Datum und Programm abschließen, um zu starten',
			'navPilote.startAwayTitle' => 'Trek starten',
			'navPilote.startAwayBody' => ({required Object distance}) => 'Du scheinst nicht am Startpunkt zu sein (${distance} m entfernt). Trotzdem starten?',
			'navPilote.startNoGpsBody' => 'Standort nicht verfügbar. Trotzdem starten?',
			'navPilote.startConfirm' => 'Trotzdem starten',
			'navPilote.startCancel' => 'Abbrechen',
			'navPilote.phasePrepareSub' => 'Bereiten Sie Ihren Trek vor dem Start vor',
			'navPilote.phaseHikeSub' => 'Ihr Trek läuft',
			'navPilote.phaseHikeInProgress' => ({required Object trek}) => '${trek} läuft',
			'navPilote.phaseAfterSub' => 'Erleben Sie Ihr Abenteuer noch einmal',
			'navPilote.phaseBanner' => 'Aktuelle Phase',
			'navPilote.demoPreview' => 'Phasenvorschau (Demo): Vorbereiten, Wandern, Danach',
			'navPilote.dominantHand' => 'Dominante Hand',
			'navPilote.dominantHandDesc' => 'Platziert SOS und Hauptbefehle auf Ihrer Handseite',
			'navPilote.dominantHandRight' => 'Rechtshänder',
			'navPilote.dominantHandLeft' => 'Linkshänder',
			'navPilote.weatherBannerTitle' => 'Hier und jetzt',
			'navPilote.weatherBannerStages' => 'Etappen-Wetter',
			'navPilote.weatherBannerUnavailable' => 'Lokales Wetter nicht verfügbar',
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
			'hub.trekCard.completedTitle' => 'Tour abgeschlossen',
			'hub.weather.title' => 'Wetter heute',
			'hub.weather.unavailable' => 'Wetter derzeit nicht verfügbar.',
			'hub.weather.alertStorm' => 'Gewitterwarnung',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Trek starten',
			'hub.startGateHint' => 'Schließe zuerst Route, Datum und Programm ab, um zu starten.',
			'hub.prepareExpand' => 'Vorbereitung anzeigen',
			'hub.prepareCollapse' => 'Einklappen',
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
			'hub.cards.calendar' => 'Kalender',
			'hub.cards.calendarSub' => 'Daten wählen',
			'hub.cards.transport' => 'Anreise',
			'hub.cards.transportSub' => 'Hin & zurück',
			'hub.cards.nuitees' => 'Übernachtungen',
			'hub.cards.nuiteesSub' => 'Buchen Sie Ihre Nächte',
			'hub.cards.checklist' => 'Ausrüstung & Rucksack',
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
			'hub.cards.importGpx' => 'GPX-Import',
			'hub.cards.importGpxSub' => 'Einen GPS-Track importieren',
			'hub.cards.diploma' => 'Diplom',
			'hub.cards.diplomaSub' => 'Ihre Abschlussurkunde',
			'hub.cards.resume' => 'Zusammenfassung',
			'hub.cards.resumeSub' => 'Planübersicht',
			'hub.cards.shop' => 'Verpflegung',
			'hub.cards.shopSub' => 'Lebensmittel, Apotheken, Gas',
			'hub.cards.weather' => 'Wetter',
			'hub.cards.weatherSub' => 'Vorhersage pro Etappe',
			'hub.cards.fire' => 'Brand',
			'hub.cards.fireSub' => 'Risiken & Warnungen',
			'hub.cards.adjust' => 'Route anpassen',
			'hub.cards.adjustSub' => 'Meine kommenden Tage ändern',
			'hub.fab.feedback' => 'Feedback geben',
			'hub.fab.sos' => 'SOS',
			'hub.finishTrek.action' => 'Tour beenden',
			'hub.finishTrek.confirmTitle' => 'Tour beenden?',
			'hub.finishTrek.confirmBody' => 'Die Tour wird als beendet markiert. Nicht gegangene Etappen werden nicht bestätigt. Du kannst dein Abenteuer weiterhin ansehen.',
			'hub.finishTrek.confirm' => 'Beenden',
			'hub.finishTrek.cancel' => 'Abbrechen',
			'map.title' => 'Wanderkarte',
			'map.loading' => 'Strecke wird geladen...',
			'map.noTrack' => 'Keine Strecke verfügbar',
			'map.viewMap' => 'Karte anzeigen',
			'map.layers' => 'Ebenen',
			'map.layersTitle' => 'Kartenebenen',
			'map.layersSubtitle' => 'Wählen Sie, was auf der Karte angezeigt wird',
			'map.stageRemaining' => ({required Object km}) => 'Noch ${km} km',
			'map.offTrackChip' => 'Abseits',
			'map.guide.buttonsTitle' => 'Schaltflächen',
			'map.guide.position' => 'Ihre GPS-Position, beim Gehen aktualisiert. Verschwindet der Punkt, prüfen Sie, ob die Ortung für die App erlaubt ist.',
			'map.guide.track' => 'Die Linie des Wegs, in seiner Farbe. Sie ist die Referenz für die Warnung bei Abweichung.',
			'map.guide.centerOnMe' => 'Holt die Karte zu Ihrer Position zurück, nachdem Sie sie verschoben haben.',
			'map.guide.photo' => 'Macht ein Foto und legt es ins Tagebuch des Tages, ohne die Karte zu verlassen.',
			'map.guide.sos' => 'Öffnet den Notruf mit Ihren GPS-Koordinaten. Nur im echten Notfall zu benutzen.',
			'map.guide.currentStage' => 'Was auf der laufenden Etappe noch zu gehen ist. Ein Strich bedeutet, dass die Wanderung noch nicht begonnen hat.',
			'map.guide.offTrack' => 'Leuchtet auf, wenn Sie sich von der Linie entfernen. Kehren Sie zum Weg zurück, damit sie verschwindet.',
			'map.guide.poi.water' => 'Quelle oder Brunnen am Weg. Eine Quelle kann im Sommer trocken sein: verlassen Sie sich nicht ungeprüft darauf.',
			'map.guide.poi.shelter' => 'Hütte oder Schutzhütte auf der Route. Tippen Sie auf die Markierung für das Bekannte: Höhe, Leistungen, Kontakt.',
			'map.guide.poi.accommodation' => 'Unterkunft außer einer Hütte: Pension, Zimmer, Hotel. Die Buchung läuft über den Betrieb selbst.',
			'map.guide.poi.campsite' => 'Camping- oder Biwakplatz. Die Biwakregeln hängen vom Gebiet ab: erkundigen Sie sich, bevor Sie das Zelt aufstellen.',
			'map.guide.poi.shop' => 'Geschäft zum Auffüllen der Vorräte. Öffnungszeiten sind außerhalb der Saison nicht garantiert: planen Sie Reserve ein.',
			'map.guide.poi.restaurant' => 'Restaurant oder Gasttisch an oder nahe der Route.',
			'map.guide.poi.viewpoint' => 'Bemerkenswerter Aussichtspunkt. Ein Halt, keine Orientierungshilfe.',
			'map.guide.poi.danger' => 'Als heikel gemeldete Stelle. Werden Sie langsamer und schauen Sie sich das Gelände an, bevor Sie hineingehen.',
			'map.guide.poi.emergency' => 'Notfallpunkt: Station, Landeplatz oder Notrufsäule.',
			'map.guide.poi.info' => 'Informationstafel oder Infopunkt am Weg.',
			'map.supplyDismiss' => 'Hinweis ausblenden',
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
			'stage.altitudeProfile' => 'Höhenprofil',
			'stage.statistics' => 'Statistiken',
			'stage.departureArrival' => 'Von {from} nach {to}',
			'stage.loading' => 'Laden...',
			'stage.loadingList' => 'Etappen werden geladen...',
			'stage.dPlus' => 'D+',
			'stage.dMinus' => 'D-',
			'stage.difficultyLabel' => 'Schwierigkeit',
			'stage.waterSources.title' => 'Wasserstellen',
			'stage.waterSources.count' => '{n} Quelle(n)',
			'stage.waterSources.none' => 'Keine Wasserstelle für diese Etappe verzeichnet. Nehmen Sie mindestens 3 L pro Person mit.',
			'stage.accommodation.title' => 'Unterkünfte',
			'stage.accommodation.none' => 'Keine Unterkunft für diese Etappe verzeichnet.',
			'stage.advice.title' => 'Tipps',
			'stage.advice.waterScarce' => 'Wenige Wasserstellen: Starten Sie mit mindestens 2,5 L.',
			'stage.advice.waterAmple' => 'Füllen Sie Ihre Flaschen an jeder Wasserstelle auf.',
			'stage.advice.hardStage' => 'Anspruchsvolle Etappe: Brechen Sie früh auf, um Hitze und Nachmittagsgewitter zu vermeiden.',
			'stage.advice.earlyStart' => 'Aufbruch vor 8 Uhr empfohlen, um die morgendliche Kühle zu nutzen.',
			'stage.advice.bigClimb' => 'Grosser Aufstieg: Teilen Sie sich Ihre Kräfte ein und machen Sie regelmässige Pausen.',
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
			'poi.accommodation' => 'Unterkunft',
			'poi.info' => 'Information',
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
			'navAlert.offTrackBanner' => ({required Object meters}) => 'Sie entfernen sich vom Weg — ${meters} m. Überprüfen Sie Ihre Position.',
			'navAlert.offTrackNotifTitle' => 'Sie verlassen den Weg',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'Sie entfernen sich vom Weg (${meters} m). Überprüfen Sie Ihre Position.',
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
			'itinerary.subtitle' => 'Ihre Etappen, Tag für Tag',
			'itinerary.direction.title' => 'Wanderrichtung',
			'itinerary.direction.from' => 'Start',
			'itinerary.direction.to' => 'Ziel',
			'itinerary.direction.reverse' => 'Richtung umkehren',
			'itinerary.empty' => 'Keine Etappe verfügbar',
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
			'itinerary.stageCount' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('de'))(n, one: '${n} Etappe', other: '${n} Etappen', ), 
			'tracking.start' => 'Starten',
			'tracking.pause' => 'Pause',
			'tracking.resume' => 'Fortsetzen',
			'tracking.stop' => 'Stoppen',
			'tracking.distance' => 'Entfernung',
			'tracking.elevation' => 'Höhenmeter',
			'tracking.speed' => 'Geschwindigkeit',
			'tracking.time' => 'Zeit',
			'tracking.confirmStop' => 'Tracking stoppen?',
			'tracking.dPlus' => 'D+',
			'tracking.stopSaveProgress' => 'Ihr Fortschritt wird gespeichert.',
			'tracking.cancel' => 'Abbrechen',
			'tracking.stopButton' => 'Stopp',
			'tracking.stopTitle' => 'Aufzeichnung beenden?',
			'tracking.stopBody' => 'Dein Fortschritt wird gespeichert.',
			'tracking.dMinus' => 'D-',
			'tracking.avgSpeed' => 'Ø Geschw.',
			'tracking.altitude' => 'Höhe',
			'tracking.total' => 'Gesamt',
			'tracking.covered' => 'Zurückgelegt',
			'tracking.backgroundRationale.title' => 'Deine Route auch bei ausgeschaltetem Bildschirm aufzeichnen',
			'tracking.backgroundRationale.body' => 'Während der Wanderung zeichnet StepWays deine Route durchgehend auf, auch wenn das Telefon in der Tasche steckt. Android fragt dich, ob du den Standort „Immer“ zulassen willst: genau dafür ist das, und nur während einer laufenden Wanderung.',
			'tracking.backgroundRationale.ifRefused' => 'Wenn du ablehnst, startet die Wanderung trotzdem: die Route wird aufgezeichnet, solange die App auf dem Bildschirm bleibt.',
			'tracking.backgroundRationale.allow' => 'Anfrage anzeigen',
			'tracking.backgroundRationale.later' => 'Später',
			'checklist.title' => 'Ausrüstung & Rucksack',
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
			'checklist.categories.men' => 'Männer',
			'checklist.categories.misc' => 'Sonstiges',
			'checklist.categories.dog' => 'Hund',
			'checklist.items.backpack' => 'Rucksack 35-45L',
			'checklist.items.rainCover' => 'Rucksack-Regenhülle',
			'checklist.items.dryBags' => 'Packsäcke (dry bags)',
			'checklist.items.sleepingBag' => 'Schlafsack (0-5C)',
			'checklist.items.sleepingPad' => 'Isomatte / Unterlage',
			'checklist.items.sleepingLiner' => 'Hüttenschlafsack / Inlett',
			'checklist.items.pillow' => 'Aufblasbares Kissen',
			'checklist.items.hikingPants' => 'Wanderhose',
			'checklist.items.rainPants' => 'Regenhose',
			'checklist.items.shorts' => 'Shorts',
			'checklist.items.techTshirt' => 'Funktions-T-Shirt',
			'checklist.items.fleece' => 'Fleece / leichte Daune',
			'checklist.items.rainJacket' => 'Regenjacke Gore-Tex',
			'checklist.items.underwear' => 'Unterwäsche',
			'checklist.items.hikingSocks' => 'Wandersocken',
			'checklist.items.gaiters' => 'Gamaschen',
			'checklist.items.hat' => 'Hut / Kappe',
			'checklist.items.beanie' => 'Mütze',
			'checklist.items.buff' => 'Buff / Halstuch',
			'checklist.items.lightGloves' => 'Leichte Handschuhe',
			'checklist.items.hikingBoots' => 'Wanderschuhe (getragen)',
			'checklist.items.campSandals' => 'Camp-Sandalen',
			'checklist.items.stove' => 'Kocher (PocketRocket)',
			'checklist.items.gasCanister' => 'Gaskartusche',
			'checklist.items.cookpot' => 'Kochtopf / Geschirr',
			'checklist.items.cutlery' => 'Besteck (Löffel, Messer)',
			'checklist.items.waterBottle' => 'Trinkflasche / Blase 2L',
			'checklist.items.knife' => 'Klappmesser',
			'checklist.items.lighter' => 'Feuerzeug',
			'checklist.items.energyBars' => 'Energieriegel',
			'checklist.items.driedFruits' => 'Trockenfrüchte',
			'checklist.items.freezeDriedMeal' => 'Gefriergetrocknete Mahlzeit',
			'checklist.items.waterPurification' => 'Wasser-Entkeimungstabletten',
			'checklist.items.electrolytes' => 'Elektrolyte',
			'checklist.items.carriedWater' => 'Getragenes Wasser (1L = 1000g)',
			'checklist.items.soap' => 'Biologisch abbaubare Seife',
			'checklist.items.toothbrush' => 'Zahnbürste',
			'checklist.items.toothpaste' => 'Zahnpasta',
			'checklist.items.microfiberTowel' => 'Mikrofaser-Handtuch',
			'checklist.items.toiletPaper' => 'Toilettenpapier',
			'checklist.items.trashBag' => 'Müllbeutel',
			'checklist.items.antiChafingCream' => 'Anti-Scheuer-Creme',
			'checklist.items.earplugs' => 'Ohrstöpsel',
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
			'checklist.items.intimateWipes' => 'Intimtücher',
			'checklist.items.peeCloth' => 'Pee-Cloth',
			'checklist.items.razor' => 'Rasierer',
			'checklist.items.techBoxers' => 'Funktions-Boxershorts',
			'checklist.items.hikingPoles' => 'Wanderstöcke (getragen)',
			'checklist.items.sunglasses' => 'Sonnenbrille',
			'checklist.items.trailMap' => 'Karte / Topo-Guide',
			'checklist.items.spareLaces' => 'Ersatzschnürsenkel',
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
			'checklist.items.seasonalMicrospikes' => 'Leichte Steigeisen (Microspikes)',
			'checklist.items.seasonalWarmGloves' => 'Warme Handschuhe',
			'checklist.items.seasonalThermalBase' => 'Thermo-Unterschicht',
			'checklist.items.seasonalExtraWater' => 'Zusätzliches Wasser',
			'checklist.items.seasonalSunHat' => 'Sonnenhut',
			'checklist.items.seasonalElectrolytesPlus' => 'Elektrolyte (Hitze)',
			'checklist.items.seasonalGaitersMud' => 'Gamaschen (Frühjahrsmatsch)',
			'checklist.items.seasonalHeadlampSpare' => 'Ersatz-Stirnlampe (kurze Tage)',
			'checklist.items.seasonalMamExtraWater' => 'Verstärkter Wasservorrat (trockene Zonen)',
			'checklist.essential' => 'Wesentlich',
			'checklist.weight.title' => 'Rucksackgewicht',
			'checklist.weight.recommended' => 'Empfohlenes Gewicht',
			'checklist.weight.total' => 'Gesamtgewicht',
			'checklist.weight.bodyWeight' => 'Körpergewicht:',
			'checklist.weight.ratio' => 'Rucksack / Körper',
			'checklist.weight.perItem' => 'Gewicht pro Artikel',
			'checklist.weight.edit' => 'Gewicht ändern',
			'checklist.weight.grams' => 'g',
			'checklist.weight.kilograms' => 'kg',
			'checklist.weight.adviceUltraLight' => 'Ultraleichter Rucksack — ideal fürs Trekking',
			'checklist.weight.adviceOk' => 'Gut ausbalancierter Rucksack',
			'checklist.weight.adviceHeavy' => 'OK aber schwer — erwäge zu erleichtern',
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
			'checklist.weight.percentOfWeight' => '{pct}% des Körpergewichts',
			'checklist.weight.gaugeObjective' => 'Max. Ziel: < 15% in Hütten, < 20% autark',
			'checklist.weight.itemsChecked' => '{checked} / {total} Artikel angehakt',
			'checklist.weight.percentOfReference' => '{pct}% des Referenzgewichts',
			'checklist.weight.gaugeObjectiveReference' => 'Maximalziel: < 15% in Hütten, < 20% autark — vom Referenzgewicht',
			'checklist.weight.referenceExplainer' => 'Referenzgewicht für deine Größe: {kg} kg. Die Rucksack-Obergrenze wird darauf berechnet, nicht auf deinem tatsächlichen Gewicht.',
			'checklist.weight.referenceFallbackHeight' => 'Die Obergrenze deines Rucksacks wird auf deinem tatsächlichen Gewicht berechnet: für deine Größe gibt es kein veröffentlichtes Referenzgewicht, auf das man sich stützen könnte. Wir sagen es dir lieber, als dir eine falsche Zahl zu zeigen.',
			'checklist.weight.descentAlertTitle' => 'Abstiege: was du trägst',
			'checklist.weight.descentAlertBody' => 'Zwei Gewichte gehen mit dir bergab: {pack} kg Rucksack und {above} kg über deinem Wohlfühlgewicht. Im Abstieg wirken bei jedem Schritt 3,46 mal das mitgehende Gewicht im Knie, gegenüber 2,61 in der Ebene. Nur der Rucksack lässt sich heute ändern: mach ihn leichter, das ist bei jedem Schritt weniger.',
			'checklist.weight.descentAlertBodyPackOnly' => 'Du steigst mit {pack} kg Rucksack ab. Im Abstieg wirken bei jedem Schritt 3,46 mal das mitgehende Gewicht im Knie, gegenüber 2,61 in der Ebene: mach den Rucksack leichter, das ist bei jedem Schritt weniger.',
			'checklist.weight.descentStage' => '{stage}: {loss} m Abstieg',
			'checklist.ui.title' => 'Ausrüstung & Rucksack',
			'checklist.ui.requirementRequired' => 'Pflicht',
			'checklist.ui.addItem' => 'Artikel hinzufügen',
			'checklist.ui.addItemTitle' => 'Artikel hinzufügen',
			'checklist.ui.fieldName' => 'Name',
			'checklist.ui.fieldWeightGrams' => 'Gewicht (Gramm)',
			'checklist.ui.errorWeightGrams' => 'Ungültiges Gewicht (0 bis 50 000 g)',
			'checklist.ui.errorNameRequired' => 'Name erforderlich',
			'checklist.ui.add' => 'Hinzufügen',
			'checklist.ui.editWeightTitle' => 'Gewicht ändern',
			'checklist.ui.editCustomTitle' => 'Eigenen Artikel bearbeiten',
			'checklist.ui.modify' => 'Bearbeiten',
			'checklist.ui.delete' => 'Löschen',
			'checklist.ui.deleteItemTitle' => 'Diesen Artikel löschen?',
			'checklist.ui.deleteItemBody' => 'Der Artikel "{name}" wird endgültig gelöscht.',
			'checklist.ui.requiredWarnTitle' => 'Pflichtausrüstung',
			'checklist.ui.requiredWarnBody' => 'Diese Ausrüstung ist aus Sicherheitsgründen Pflicht (angelehnt an UTMB-Regeln). Wirklich entfernen?',
			'checklist.ui.keep' => 'Behalten',
			'checklist.ui.removeAnyway' => 'Trotzdem entfernen',
			'checklist.ui.reduceQuantity' => 'Menge verringern',
			'checklist.ui.increaseQuantity' => 'Menge erhohen',
			'checklist.ui.addToShoppingList' => 'Zur Einkaufsliste hinzufügen',
			'checklist.ui.removeFromShoppingList' => 'Von der Liste entfernen',
			'checklist.ui.help' => 'Hilfe',
			'checklist.ui.shoppingListTitle' => 'Einkaufsliste',
			'checklist.ui.shoppingListEmpty' => 'Deine Einkaufsliste ist leer. Füge Artikel mit dem Warenkorb-Button hinzu.',
			'checklist.ui.shoppingToBuy' => 'Zu kaufen',
			'checklist.ui.shoppingPurchased' => 'Bereits gekauft',
			'checklist.ui.share' => 'TEILEN',
			'checklist.ui.infoTitle' => 'Ausrüstung & Rucksack',
			'checklist.ui.infoCheckTitle' => 'Artikel anhaken',
			'checklist.ui.infoCheckBody' => 'Hake an, was du mitnimmst — das Gewicht wird oben neu berechnet.',
			'checklist.ui.infoRequiredTitle' => 'Pflicht',
			'checklist.ui.infoRequiredBody' => 'Artikel mit Schloss = Vorschrift (Pfeife, Lampe, Rettungsdecke).',
			'checklist.ui.infoGaugeTitle' => 'Gewichtsanzeige',
			'checklist.ui.infoGaugeBody' => 'Ziel: Rucksack < 15% deines Gewichts. Grün = OK, Orange = Achtung, Rot = zu schwer.',
			'checklist.ui.infoAddTitle' => 'Hinzufügen',
			'checklist.ui.infoAddBody' => 'Der +-Button unten in jeder Kategorie für eigene Artikel.',
			'checklist.ui.infoValidateBody' => 'Bestätige, wenn dein Rucksack fertig ist — ein Haken erscheint auf der Startseite.',
			'checklist.ui.infoUnderstood' => 'Verstanden!',
			'checklist.ui.prepTitle' => 'Rucksack packen',
			'checklist.ui.prepCounter' => '{prepared} / {total} Artikel gepackt',
			'checklist.ui.prepAllReady' => 'Alles bereit! Gute Tour',
			'checklist.ui.preDepartureTitle' => 'Checkliste vor dem Start',
			'checklist.ui.preDepartureCounter' => '{checked}/{total} geprüft',
			'checklist.ui.preDep1' => 'Wetter der nächsten Tage prüfen',
			'checklist.ui.preDep2' => 'Telefon + Powerbank laden',
			'checklist.ui.preDep3' => 'Eine nahestehende Person über die Route informieren',
			'checklist.ui.preDep4' => 'Prüfen, dass der Rucksack gut geschlossen und wasserdicht ist',
			'checklist.ui.preDep5' => 'Trinkflaschen füllen (mindestens 2L)',
			'checklist.ui.preDep6' => 'Sonnencreme und Anti-Scheuer-Creme auftragen',
			'checklist.ui.preDep7' => 'Schnürsenkel und Schuhsitz prüfen',
			'checklist.ui.preDep8' => 'Offline-Karten herunterladen',
			'checklist.ui.bagOk' => 'RUCKSACK OK — STARTBEREIT',
			'checklist.ui.validateBag' => 'RUCKSACK BESTÄTIGEN',
			'checklist.ui.cancelValidation' => 'BESTÄTIGUNG AUFHEBEN',
			'checklist.ui.shoppingListButton' => 'EINKAUFSLISTE',
			'checklist.ui.shareGroup' => 'MIT DER GRUPPE TEILEN',
			'checklist.ui.exportList' => 'LISTE EXPORTIEREN',
			'checklist.ui.bagValidTitle' => 'Rucksack bestätigt',
			'checklist.ui.bagValidBody' => 'Alle {total} Pflichtartikel sind im Rucksack.\n\nGesamtgewicht: {weight} kg ({pct}% des Referenzgewichts)\n\nBist du sicher, dass dein Rucksack fertig ist?',
			'checklist.ui.checkAgain' => 'Nochmal prüfen',
			'checklist.ui.yesBagOk' => 'Ja, Rucksack OK',
			'checklist.ui.bagValidatedSnack' => 'Rucksack bestätigt!',
			'checklist.ui.validationCancelledSnack' => 'Bestätigung aufgehoben — du kannst deine Ausrüstung ändern.',
			'checklist.ui.missingTitle' => 'Fehlende Ausrüstung',
			'checklist.ui.missingBody' => '{checked}/{total} Pflichtartikel angehakt.',
			_ => null,
		} ?? switch (path) {
			'checklist.ui.missingList' => 'Es fehlt:',
			'checklist.ui.understood' => 'Verstanden',
			'checklist.ui.validateAnyway' => 'Trotzdem bestätigen',
			'checklist.ui.bagValidatedMissingSnack' => 'Rucksack bestätigt (mit fehlenden Artikeln)!',
			'checklist.ui.shareGroupHint' => 'Tritt einer Gruppe bei, um deine Checkliste zu teilen.',
			'checklist.seasonalBanner' => ({required Object season}) => 'Rucksack an die Saison (${season}) und Ihren Weg angepasst.',
			'checklist.seasons.winter' => 'Winter',
			'checklist.seasons.spring' => 'Frühling',
			'checklist.seasons.summer' => 'Sommer',
			'checklist.seasons.autumn' => 'Herbst',
			'checklist.seasonalAdd' => 'Hinzufügen',
			'checklist.seasonalAdded' => 'Hinzugefügt',
			'checklist.seasonalWeight' => ({required Object g}) => '${g} g',
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
			'journal.addPhoto' => 'Foto hinzufügen',
			'journal.photoAdded' => 'Foto zum Tagebuch hinzugefügt',
			'journal.photoSource' => 'Fotoquelle',
			'journal.camera' => 'Kamera',
			'journal.gallery' => 'Galerie',
			'journal.removePhoto' => 'Foto entfernen',
			'journal.photoError' => 'Foto konnte nicht hinzugefügt werden',
			'journal.dayNavPrevious' => 'Vorheriger Tag',
			'journal.dayNavNext' => 'Nächster Tag',
			'journal.dayOfTrek' => ({required Object day}) => 'Tag ${day}',
			'journal.dayCounter' => ({required Object index, required Object total}) => '${index} / ${total}',
			'journal.dayEmpty' => 'Kein Eintrag für diesen Tag',
			'journal.entriesOfDay' => 'Einträge des Tages',
			'journal.dayTrace' => 'Strecke des Tages',
			'journal.dayTraceEmpty' => 'Für diesen Tag wurde keine GPS-Strecke aufgezeichnet',
			'journal.daySummary' => 'Tagesübersicht',
			'journal.sinceStart' => 'Seit dem Start',
			'journal.distance' => 'Distanz',
			'journal.elevationGain' => 'Aufstieg',
			'journal.elevationLoss' => 'Abstieg',
			'journal.duration' => 'Dauer',
			'journal.maxAltitude' => 'Höchste Höhe',
			'journal.share' => 'Teilen',
			'journal.shareSubject' => 'Mein Wandertagebuch',
			'journal.shareError' => 'Teilen nicht möglich',
			'journal.lockedTitle' => 'Das Tagebuch gehört zum Paket',
			'journal.lockedBody' => 'Halten Sie Ihre Eindrücke fest, fügen Sie Fotos hinzu und lesen Sie jeden Wandertag nach. Das Tagebuch wird mit dem Weg freigeschaltet.',
			'journal.lockedUnlock' => 'Freischalten',
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
			'diploma.recapDistance' => '{km} km zurückgelegt',
			'diploma.recapElevation' => '{meters} m Höhenunterschied',
			'diploma.recapDuration' => '{days} Tage Wanderung',
			'diploma.recapMapTrace' => 'Routenverlauf',
			'diploma.recapNoMap' => 'Verlauf nicht verfügbar',
			'diploma.recapJournalEntries' => '{count} Tagebucheinträge',
			'diploma.downloadPdf' => 'Diplom-PDF herunterladen',
			'diploma.lockedTitle' => 'Diplom gesperrt',
			'diploma.lockedMessage' => 'Absolviere deine gesamte Route, um dein Finisher-Diplom freizuschalten.',
			'diploma.labelIntegral' => 'Gesamte Route',
			'diploma.labelPartial' => 'Teilroute',
			'diploma.pdfSaved' => ({required Object file}) => 'Diplom gespeichert: ${file}',
			'diploma.pdfError' => 'Das Diplom konnte nicht gespeichert werden',
			'diploma.finisherNumber' => ({required Object number}) => 'Diplom Nr. ${number}',
			'diploma.shareDiploma' => 'Mein Diplom teilen',
			'diploma.shareError' => 'Teilen nicht möglich',
			'notifications.morningReminder' => 'Morgenerinnerung',
			'notifications.weatherAlerts' => 'Wetterwarnungen',
			'notifications.countdown' => 'Erinnerung 2 Tage vorher',
			'notifications.countdownDesc' => 'Benachrichtigung 2 Tage vor Abreise',
			'notifications.schedulerCountdownTitle' => 'Ihr Trek steht bevor!',
			'notifications.schedulerCountdownBody' => 'Abreise in 2 Tagen. Prüfen Sie Ihre Checkliste und das Wetter.',
			'notifications.schedulerDailyTitle' => 'Guten Trek-Tag!',
			'notifications.schedulerDailyBody' => 'Prüfen Sie das Wetter und bereiten Sie Ihre heutige Etappe vor.',
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
			'settings.noDateChosen' => 'Kein Datum gewählt',
			'settings.departureDate' => 'Startdatum',
			'appearance.title' => 'Erscheinungsbild',
			'appearance.subtitle' => 'Wähle das Design der App',
			'appearance.skinSentierVivant' => 'Lebendiger Pfad',
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
			'auth.appVersion' => ({required Object version, required Object build}) => 'StepWays v${version} (build ${build})',
			'feasibility.restart' => 'Start over',
			'feasibility.objectiveTitle' => 'Machbarkeit für diesen Trek',
			'feasibility.objectiveIntro' => 'Urteil auf Basis Ihres echten Profils, gekreuzt mit den Anforderungen des Treks.',
			'feasibility.openProfile' => 'Meine Angaben',
			'feasibility.openWalkTest' => '6-Minuten-Test',
			'feasibility.openPastHikes' => 'Meine letzten 5 Touren',
			'feasibility.sourceObjective' => 'Basierend auf Ihrem objektiven Profil',
			'feasibility.sourceFallback' => 'Basierend auf dem Fragebogen (bis Ihr Profil gesetzt ist)',
			'feasibility.gapTooHigh' => 'Zu grosse Abweichung',
			'feasibility.gaps.elevationPerDay' => 'Täglicher Anstieg zu hoch gegenüber Ihrer Gewohnheit',
			'feasibility.gaps.distancePerDay' => 'Tägliche Distanz über Ihrer Erfahrung',
			'feasibility.gaps.consecutiveDays' => 'Mehr aufeinanderfolgende Tage als je gemacht',
			'feasibility.gaps.technicity' => 'Geländetechnik über Ihrem Niveau',
			'feasibility.gaps.risk' => 'Hohes Risikoniveau für diesen Trek',
			'feasibility.gaps.fitness' => 'Form beim 6-Minuten-Test unzureichend',
			'feasibility.gaps.effort' => 'Gesamtanstrengung (IBP) über Ihrer Erfahrung',
			'feasibility.formula.title' => 'Machbarkeit für diese Tour',
			'feasibility.formula.intro' => 'Wir vergleichen den Aufwand jedes Wandertags mit dem, was dein Profil schafft. Grün, Orange oder Rot.',
			'feasibility.formula.ceilingLabel' => ({required Object value, required Object level}) => 'Empfohlene Obergrenze: ${value} Energie-km/Tag (${level})',
			'feasibility.formula.stagesTitle' => 'Tag für Tag',
			'feasibility.formula.stageEffort' => ({required Object distance, required Object elevation, required Object effort}) => '${distance} km + ${elevation} m Aufstieg = ${effort} Energie-km',
			'feasibility.formula.globalTitle' => 'Gesamturteil',
			'feasibility.formula.hardestStage' => ({required Object stage}) => 'Anspruchsvollster Tag: ${stage}',
			'feasibility.formula.daysOver' => ({required Object count}) => '${count} Tag(e) über deiner Obergrenze',
			'feasibility.formula.daysOverNone' => 'Kein Tag über deiner Obergrenze',
			'feasibility.formula.limitingLabel' => ({required Object factor}) => 'Begrenzender Faktor: ${factor}',
			'feasibility.formula.trainingReco' => ({required Object weeks}) => 'Empfohlenes Training: ${weeks} Wochen vor dem Start',
			'feasibility.formula.adviceTitle' => 'Tipps für deinen Plan',
			'feasibility.formula.generateProgram' => ({required Object days}) => 'Meinen Plan erstellen (${days} Tage)',
			'feasibility.formula.generateProgramDone' => ({required Object days}) => 'Plan über ${days} Tage erstellt — passe ihn nach Wunsch an.',
			'feasibility.formula.noStages' => 'Noch kein Tag zu bewerten.',
			'feasibility.formula.levels.beginner' => 'Anfänger',
			'feasibility.formula.levels.intermediate' => 'Fortgeschritten',
			'feasibility.formula.levels.confirmed' => 'Erfahren',
			'feasibility.formula.levels.expert' => 'Experte',
			'feasibility.formula.verdicts.green' => 'Aufteilung machbar',
			'feasibility.formula.verdicts.orange' => 'Aufteilung fordernd',
			'feasibility.formula.verdicts.red' => 'Aufteilung zu knapp',
			'feasibility.formula.limitingFactors.distance' => 'die Tagesdistanz',
			'feasibility.formula.limitingFactors.elevation' => 'der Höhenunterschied',
			'feasibility.formula.limitingFactors.chaining' => 'die Abfolge der Tage',
			'feasibility.formula.limitingFactors.none' => 'keiner',
			'feasibility.formula.limitingFactors.altitude' => 'die Höhe',
			'feasibility.formula.limitingFactors.heat' => 'die Hitze der Jahreszeit',
			'feasibility.formula.advice.balancedOk' => 'Dein Plan ist ausgewogen: Halte eine Reserve und höre auf deinen Körper.',
			'feasibility.formula.advice.balanced' => 'Verteile die Etappen, um den Aufwand über die Tage zu glätten.',
			'feasibility.formula.advice.optimalDays' => ({required Object days, required Object current}) => 'Plane ${days} Wandertage (statt ${current}), um unter deiner Obergrenze zu bleiben.',
			'feasibility.formula.advice.split' => ({required Object stage}) => 'Teile Tag ${stage} in zwei: Er überschreitet deutlich deine Obergrenze.',
			'feasibility.formula.advice.splitImpossible' => ({required Object stage}) => 'Tag ${stage} liegt auch zweigeteilt über Ihren Möglichkeiten, und kürzer lässt er sich nicht teilen: Das ist keine Frage der Planung mehr. Trainieren Sie, warten Sie auf mildere Bedingungen, oder wählen Sie einen leichteren Weg.',
			'feasibility.formula.advice.rest' => ({required Object stages}) => 'Plane einen Ruhetag nach Tag ${stages}.',
			'feasibility.formula.advice.training' => ({required Object weeks}) => 'Trainiere ${weeks} Wochen vor dem Start (körperliche Vorbereitung).',
			'feasibility.formula.advice.restAdvised' => ({required Object days, required Object stages}) => 'Setze ${days} Ruhetag(e) ein, nach den Tagen ${stages}: sie gleichen sich zu sehr, als dass sich der Körper erholen könnte. Das ist ein Rat, er ändert dein Urteil nicht.',
			'feasibility.formula.retainedPlan' => ({required Object days}) => 'Gewählte Aufteilung: ${days} Wandertage.',
			'feasibility.formula.retainedPlanNone' => ({required Object days}) => 'Keine Aufteilung gewählt: die Tour bleibt bei ihren ${days} Standardtagen.',
			'feasibility.formula.energyUnitNotice' => '1 km in der Ebene entspricht 42 m Aufstieg: das ist der gemessene Aufwand des Bergaufgehens, keine Hausregel.',
			'feasibility.formula.circuitTitle' => 'Urteil zur Runde',
			'feasibility.formula.circuitScore' => ({required Object value}) => 'Wert der Runde: ${value}',
			'feasibility.formula.circuitIsWorstStage' => 'Das Urteil zur Runde ist das deines härtesten Tages: nichts anderes macht es härter.',
			'feasibility.formula.restWindowWhole' => ({required Object days}) => 'Ruhe über den ganzen Trek gemessen (${days} Tage).',
			'feasibility.formula.restWindowSlice' => ({required Object start, required Object end}) => 'Ruhe über die schlechteste Woche gemessen: Tage ${start} bis ${end}.',
			'feasibility.formula.restNotApplicable' => 'Auf einem Weg von einem einzigen Tag lässt sich die Ruhe nicht berechnen: es gibt keine Verkettung zu messen. Die Bedingung wird als nicht anwendbar erklärt, sie wird nicht durch eine Zahl ersetzt.',
			'feasibility.formula.restExtrapolation' => 'Die Ruhe-Schwelle stammt aus einer Messung an Sportlern und wurde auf das Weitwandern übertragen. Es ist eine Übertragung, und sie wird als solche genannt.',
			'feasibility.formula.restNotDecisive' => 'Diese Zahl wird angezeigt und berät, sie entscheidet nie: dein Urteil bleibt das deines härtesten Tages.',
			'feasibility.formula.restAdvisedLine' => ({required Object days}) => 'Empfehlung: ${days} über dein Programm verteilte Ruhetage bringen diese Zahl wieder unter ihre Schwelle.',
			'feasibility.formula.restTwoDays' => 'Bei gleich großen Tagen reicht ein Ruhetag pro Woche nicht: es braucht zwei.',
			'feasibility.formula.habitGap' => ({required Object value}) => 'Abstand zu deiner Gewohnheit: ${value} (Richtwert 0,8 bis 1,3).',
			'feasibility.formula.habitGapNotDecisive' => 'Dieser Abstand wird angezeigt, ist aber nie entscheidend: keine Studie belegt, dass er irgendetwas verursacht.',
			'feasibility.formula.conditionsTitle' => 'Was in dieses Urteil eingeflossen ist',
			'feasibility.formula.floorActive' => ({required Object value}) => 'Dein bester bereits durchgehaltener Tag (${value} Energie-km) liegt über der Obergrenze deiner Stufe: er dient als Basis. Dir wird nie gesagt, du könntest nicht, was du schon getan hast.',
			'feasibility.formula.altitudeApplied' => ({required Object value, required Object pct}) => 'Höhe: ${value} m am höchsten Punkt, deine Tageskapazität sinkt um ${pct} %.',
			'feasibility.formula.altitudeBelowThreshold' => ({required Object value}) => 'Höhe: ${value} m am höchsten Punkt, unter den 1 500 m, ab denen sie zählt. Sie ändert hier nichts.',
			'feasibility.formula.altitudeMissing' => 'Höhe: die Spur dieses Weges trägt keine. Sie ändert hier nichts mangels Daten — und nicht, weil sie ohne Wirkung wäre.',
			'feasibility.formula.heatApplied' => 'Aufbruch im Sommer: die aerobe Kapazität sinkt um 7 %, das ist gemessen.',
			'feasibility.formula.seasonNoSource' => 'Aufbruch im Frühling oder Herbst: keine veröffentlichte Messung erlaubt es, eine Wirkung zu beziffern. Die Jahreszeit ändert hier nichts, mangels Quelle.',
			'feasibility.formula.seasonMissing' => 'Kein Aufbruchsdatum gesetzt: die Jahreszeit ändert hier nichts, mangels Daten.',
			'feasibility.formula.massNotCounted' => 'Weder dein Gewicht noch das deines Rucksacks fließt in dieses Urteil ein, und das ist gewollt: es misst, was du nachweislich durchhältst. Mit 65 oder mit 95 kg erhält derselbe Mann dasselbe Urteil.',
			'feasibility.formula.winterInvalid' => 'Aufbruch im Winter: dieses Urteil hält nicht mehr. Wegbewertungen gelten nur bei gutem Wetter, trockenem Gelände und angepasster Schneelage. Wir verschärfen die Zahl nicht, wir sagen dir, dass sie nicht gilt.',
			'feasibility.formula.restDaysCounted' => ({required Object count}) => 'In diesem Urteil gezählte Ruhetage: ${count}.',
			'feasibility.formula.restDaysNone' => 'In deinem Programm ist kein Ruhetag gesetzt: setze welche, und diese Zahl bewegt sich.',
			'feasibility.formula.averageLoad' => ({required Object value, required Object worst}) => 'Mittlere Tageslast: ${value} (die härteste liegt bei ${worst}).',
			'feasibility.formula.averageLoadInfo' => 'Diese beiden Zahlen liest man zusammen: weit auseinander hat der Trek einen harten Tag; nahe beieinander ist er jeden Tag hart. Das wird angezeigt, es entscheidet nicht.',
			'feasibility.formula.durationStatement' => ({required Object days, required Object done}) => 'Dieser Trek dauert ${days} Wandertage; deine längste zusammenhängende Tour beträgt ${done} Tage.',
			'feasibility.formula.durationStatementInfo' => 'Das wird angezeigt, es entscheidet nicht: keine veröffentlichte Messung sagt, ab wie vielen zusammenhängenden Tagen ein Wanderer einbricht. Beurteile es selbst.',
			'feasibility.formula.stageDominantFactor' => ({required Object factor}) => 'Was an diesem Tag am schwersten wiegt: ${factor}',
			'feasibility.flow.title' => 'Bist du bereit für diese Tour?',
			'feasibility.flow.intro' => 'Beantworte 3 kurze Schritte: Wir ermitteln dein echtes Niveau und sagen dir, ob die Tour machbar ist.',
			'feasibility.flow.progress' => ({required Object done, required Object total}) => '${done}/${total} Schritte erledigt',
			'feasibility.flow.stepProfile' => 'Dein Infoblatt',
			'feasibility.flow.stepProfileSub' => 'Alter, Größe, Gewicht (bleibt auf deinem Handy).',
			'feasibility.flow.stepWalkTest' => '6-Minuten-Gehtest',
			'feasibility.flow.stepWalkTestSub' => 'Misst deine aktuelle Form — verändert dein Ergebnis.',
			'feasibility.flow.stepPastHikes' => 'Deine letzten 5 Touren',
			'feasibility.flow.stepPastHikesSub' => 'Was du schon geschafft hast: Tempo, Distanz, Höhenmeter.',
			'feasibility.flow.optionalTag' => '(optional)',
			'feasibility.flow.validate' => 'Bestätigen und Ergebnis ansehen',
			'feasibility.flow.partialNotice' => 'Vorläufiges Ergebnis: der 6-Minuten-Gehtest wurde nicht gemacht. Dein Niveau wird standardmäßig geschätzt; mach den Test für ein genaueres Urteil.',
			'feasibility.flow.missingTitle' => 'Es fehlen noch Angaben',
			'feasibility.flow.missingIntro' => 'Das Urteil erscheint erst, wenn alle nötigen Kriterien ausgefüllt sind. Es fehlt noch:',
			'feasibility.flow.missingProfile' => 'Dein vollständiges Infoblatt: Alter, Größe und Gewicht',
			'feasibility.flow.missingPastHikes' => 'Mindestens eine deiner 5 letzten Touren',
			'feasibility.flow.missingWalkTestNote' => 'Der 6-Minuten-Test bleibt optional: ohne ihn wird dein Ergebnis als vorläufig angezeigt.',
			'feasibility.flow.hintBlocked' => 'Vervollständige die Kriterien oben: dort entscheidet sich dein Urteil.',
			'feasibility.flow.hintReady' => 'Alles da: du kannst dein Ergebnis ansehen.',
			'tips.carouselTitle' => 'Trek-Tipps',
			'tips.allCategories' => 'Alle',
			'tips.swipeHint' => 'Wischen für mehr',
			'tips.detailTitle' => 'Tipp-Detail',
			'tips.readMore' => 'Mehr lesen',
			'tips.noTips' => 'Keine Tipps verfügbar',
			'tips.categoryPreparation' => 'Vorbereitung',
			'tips.categoryEquipment' => 'Ausrüstung',
			'tips.categoryNutrition' => 'Ernährung',
			'tips.categorySafety' => 'Sicherheit',
			'tips.categoryNature' => 'Natur',
			'tips.categoryRecovery' => 'Erholung',
			'tips.categoryGeneral' => 'Allgemein',
			'tips.priorityHigh' => 'Hohe Priorität',
			'tips.scope' => 'Wanderweg',
			'tips.season' => 'Saison',
			'tips.scopeAll' => 'Alle Wege',
			'tips.seasons.all' => 'Ganzjährig',
			'tips.seasons.winter' => 'Winter',
			'tips.seasons.spring' => 'Frühling',
			'tips.seasons.summer' => 'Sommer',
			'tips.seasons.autumn' => 'Herbst',
			'tips.altitude' => 'Min. Höhe',
			'tips.screenTitle' => 'Ratgeber',
			'tips.screenIntro' => 'Alles für eine gelungene Wanderung',
			'tips.followUs' => 'Folgen Sie uns:',
			'tips.viewOnFacebook' => 'Auf Facebook ansehen',
			'tips.viewOnInstagram' => 'Instagram',
			'tips.linkOffline' => 'Link offline nicht verfügbar',
			'tips.emptyThemed' => 'Kein Ratgeber für diesen Weg verfügbar.',
			'tips.moreTips' => ({required Object n}) => '+ ${n} Tipps',
			'tips.themes.gear' => 'Ausrüstung',
			'tips.themes.safety' => 'Sicherheit',
			'tips.themes.health' => 'Gesundheit',
			'tips.themes.weather' => 'Wetter',
			'tips.themes.refuge' => 'Hüttenleben',
			'tips.themes.nature' => 'Natur',
			'tips.themes.other' => 'Sonstiges',
			'goodies.title' => 'Goodies-Shop',
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
			'onboarding.recoveryNudge' => 'Denke daran, deinen Wiederherstellungscode zu notieren (in den Einstellungen): Er öffnet deine Daten auf einem anderen Telefon.',
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
			'monetization.rewardedCta' => 'Werbung ansehen (24 h werbefrei)',
			'monetization.rewardedEarned' => 'Danke! 24 h werbefrei.',
			'monetization.rewardedUnavailable' => 'Derzeit kein Video verfügbar.',
			'monetization.walletTitle' => 'Etappenkonto',
			'monetization.walletSubtitle' => 'Mit Ihren Etappen schalten Sie Wanderungen frei',
			'monetization.walletUnit' => 'Etappen',
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
			'signalement.water.reportAction' => 'Zustand melden',
			'signalement.water.reportCount' => '{n} Meldung(en)',
			'signalement.water.sheetTitle' => 'Zustand der Wasserstelle?',
			'signalement.water.latencyHint' => 'Nach Netzwerk-Synchronisierung mit anderen Wanderern geteilt.',
			'signalement.water.saved' => 'Danke! Zustand gespeichert.',
			'signalement.water.states.available' => 'Wasser verfügbar',
			'signalement.water.states.low' => 'Geringer Durchfluss',
			'signalement.water.states.dry' => 'Trocken',
			'signalement.water.states.unknown' => 'Unbekannter Zustand',
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
			'training.progress' => ({required Object done, required Object total}) => '${done} von ${total} Einheiten erledigt',
			'training.types.marche' => 'Gehen',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Kraft',
			'training.intensity.faible' => 'Niedrig',
			'training.intensity.moderee' => 'Mittel',
			'training.intensity.elevee' => 'Hoch',
			'training.paywallTitle' => 'Personalisierter Trainingsplan',
			'training.paywallIncludedIn' => ({required Object trail}) => 'Im Paket « ${trail} » enthalten.',
			'training.paywallSubtitle' => 'Plan angepasst an Ihr Profil und Ihr Abreisedatum.',
			'training.unlock' => 'Freischalten',
			'training.effortIntro' => ({required Object weeks, required Object km, required Object elevation}) => 'Ein progressiver ${weeks}-Wochen-Plan für die ${km} km und rund ${elevation} m Höhenmeter.',
			'training.countdown' => ({required Object days}) => 'Abreise in ${days} Tagen',
			'training.planOverWeeks' => ({required Object n}) => 'Plan über ${n} Wochen',
			'training.phaseWeeks' => ({required Object start, required Object end, required Object title}) => 'Wochen ${start}-${end} · ${title}',
			'training.objectiveTitle' => 'Schlüsselziel',
			'training.inviteSetDate' => 'Legen Sie Ihr Abreisedatum im Kalender fest, um den Countdown zu aktivieren.',
			'training.inviteFillProfile' => 'Füllen Sie Ihr Datenblatt aus, um den Plan an Ihr Profil anzupassen.',
			'training.cautionVerdictNotice' => 'Ihre Machbarkeit mahnt zur Vorsicht: halten Sie die Progression ein und kurzen Sie die Vorbereitung nicht.',
			'training.departureTooClose' => ({required Object days}) => 'Noch ${days} Tage: Plan auf die verfügbare Zeit verdichtet.',
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
			_ => null,
		} ?? switch (path) {
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
			'waypoints.types.connectivite' => 'Konnektivität',
			'waypoints.types.jonction' => 'Kreuzung',
			'waypoints.filters.title' => 'Wegpunkte filtern',
			'waypoints.filters.showAll' => 'Alle anzeigen',
			'waypoints.filters.hideAll' => 'Alle ausblenden',
			'waypoints.filters.recentConditionOnly' => 'Nur aktueller Zustand',
			'waypoints.detail.conditionsTitle' => 'Geländezustand',
			'waypoints.detail.noComments' => 'Noch kein Zustand gemeldet.',
			'waypoints.detail.commentsError' => 'Zustand nicht verfügbar.',
			'waypoints.detail.report' => 'Melden',
			'waypoints.detail.reportAck' => 'Meldung gespeichert. Sie wird nach der Synchronisierung geprüft.',
			'waypoints.detail.pendingSync' => 'Warten auf Synchronisierung',
			'waypoints.freshness.justNow' => 'gerade aktualisiert',
			'waypoints.freshness.minutes' => ({required Object n}) => 'vor ${n} Min aktualisiert',
			'waypoints.freshness.hours' => ({required Object n}) => 'vor ${n} Std aktualisiert',
			'waypoints.freshness.days' => ({required Object n}) => 'vor ${n} T aktualisiert',
			'waypoints.contribution.titleWaypoint' => 'Wegpunkt hinzufügen',
			'waypoints.contribution.titleComment' => 'Zustand melden',
			'waypoints.contribution.chooseType' => 'Wegpunkttyp',
			'waypoints.contribution.titleField' => 'Titel des Wegpunkts',
			'waypoints.contribution.conditionPrompt' => 'Beschreiben Sie den beobachteten Zustand',
			'waypoints.contribution.commentField' => 'Ihre Beobachtung',
			'waypoints.contribution.conditionField' => 'Zustand (optional)',
			'waypoints.contribution.conditionHelper' => 'z. B. Wasser versiegt, Wasser fliesst, rutschige Stelle',
			'waypoints.contribution.latencyBanner' => 'Wird bei der nächsten Synchronisierung veröffentlicht.',
			'waypoints.contribution.submit' => 'Speichern',
			'waypoints.contribution.savedTitle' => 'Beitrag gespeichert',
			'waypoints.contribution.savedPendingSync' => 'Er wird veröffentlicht, sobald das Netz wieder da ist.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} warten auf Synchronisierung',
			'waypoints.contribution.close' => 'Schliessen',
			'waypoints.contribution.emptyTitle' => 'Bitte einen Titel für den Wegpunkt angeben.',
			'waypoints.contribution.emptyComment' => 'Bitte Ihre Beobachtung eingeben.',
			'waypoints.contribution.noLocation' => 'GPS-Position nicht verfügbar. Unter freiem Himmel erneut versuchen.',
			'waypoints.contribution.error' => 'Speichern derzeit nicht möglich.',
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
			'health.error.bloodType' => 'Ungültige Blutgruppe (A+, A-, B+, B-, AB+, AB-, O+, O-)',
			'health.save' => 'Speichern',
			'health.saving' => 'Speichern…',
			'health.saved' => 'Informationen gespeichert',
			'health.emergencyHint' => 'Zeigen Sie diesen Bildschirm im Notfall den Rettungskräften.',
			'health.entryTitle' => 'Meine Gesundheitsdaten',
			'health.entrySubtitle' => 'Den Rettungskräften zeigen (bleiben auf dem Telefon)',
			'health.a11y.form' => 'Formular für Gesundheitsinformationen',
			'health.a11y.saveButton' => 'Gesundheitsinformationen speichern',
			'health.delete.button' => 'Meine Karte löschen',
			'health.delete.a11yButton' => 'Meine Gesundheitskarte löschen — endgültige Aktion',
			'health.delete.confirmTitle' => 'Gesundheitskarte löschen?',
			'health.delete.confirmBody' => 'Endgültig und lokal. Deine Daten werden von diesem Telefon entfernt.',
			'health.delete.cancel' => 'Abbrechen',
			'health.delete.confirm' => 'Löschen',
			'health.delete.done' => 'Gesundheitskarte gelöscht.',
			'health.consent.purpose' => 'Diese Infos helfen den Rettungskräften. Sie bleiben auf deinem Telefon, werden nie ins Internet gesendet.',
			'health.consent.manage' => 'Meine Gesundheits-Einwilligung verwalten',
			'trailSelection.title' => 'Weg wechseln',
			'trailSelection.subtitle' => 'Wähle den Weg zum Erkunden. Die ganze App (Karte, Etappen, Sehenswürdigkeiten, Pakete, Reiseführer) folgt deiner Auswahl.',
			'trailSelection.current' => 'Aktiver Weg',
			'trailSelection.select' => 'Diesen Weg wählen',
			'trailSelection.selected' => 'Ausgewählter Weg',
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
			'consent.healthDataMorphoNote' => 'Umfasst Ihre Körperdaten (Alter, Grösse, Gewicht) für die Trek-Machbarkeit. Gesundheitsdaten, DSGVO Artikel 9, auf dem Gerät gehalten.',
			'consent.healthBackupNote' => 'Ohne diese Einwilligung wird Ihr medizinisches Informationsblatt nicht gesichert: Sie können es auf einem anderen Telefon nicht wiederherstellen und den Rettungskräften von einem neuen Gerät nicht zeigen.',
			'erasure.section' => 'Meine Daten',
			'erasure.entry' => 'Meine Daten löschen',
			'erasure.entryDesc' => 'Endgültig löschen, was die App über Sie speichert',
			'erasure.dialogTitle' => 'Meine Daten löschen?',
			'erasure.goesTitle' => 'Was gelöscht wird',
			'erasure.goes' => 'Ihr Wanderprofil (Alter, Grösse, Gewicht, Gehtest), Ihr medizinisches Informationsblatt, Ihre vergangenen Wanderungen und Ihr Tagebuch, Ihre gegangenen Etappen, Ihre Übernachtungen, Ihre GPS-Aufzeichnungen, Ihre Einwilligungen und Ihr Wiederherstellungscode. Und Ihre gesamte Vorbereitungsarbeit: Ihr Programm und die von Ihnen gewählte Etappeneinteilung, Ihr Abreisedatum, Ihr Fortschritt der körperlichen Vorbereitung, was Sie unter Vorbereiten bereits abgeschlossen haben, Ihre Einstellungen für Teilen und Sichtbarkeit sowie die von Ihnen abgehakten Etappenpunkte.',
			'erasure.staysTitle' => 'Was bleibt',
			'erasure.stays' => 'Ihre Käufe: bezahlte Etappen, freigeschaltete Wege, werbefreier Zeitraum — wir nehmen Ihnen nicht zurück, was Sie bezahlt haben. Und Ihre Anzeigeeinstellungen (Sprache, Design, Einheiten), die nichts über Sie aussagen.',
			'erasure.finalWarning' => 'Das ist endgültig: weder Sie noch wir können diese Daten wiederherstellen.',
			'erasure.confirmCheckbox' => 'Ich habe das gelesen und möchte meine Daten löschen',
			'erasure.confirm' => 'Endgültig löschen',
			'erasure.cancel' => 'Abbrechen',
			'erasure.done' => 'Ihre Daten wurden gelöscht.',
			'erasure.error' => 'Die Löschung wurde nicht abgeschlossen. Versuchen Sie es erneut — was schon gelöscht ist, kommt nicht zurück.',
			'erasure.a11y.entry' => 'Meine Daten löschen, öffnet eine Bestätigungsabfrage',
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
			'recap.lockedTitle' => 'Verfügbar am Ende der Tour',
			'recap.lockedMessage' => 'Beende oder brich deine Route ab, um die Zusammenfassung deines Abenteuers zu sehen.',
			'recap.finisherTitle' => 'Glückwunsch!',
			'recap.finisherSubtitle' => 'Du hast deine Route abgeschlossen',
			'recap.partialTitle' => 'Deine Teilroute',
			'recap.partialSubtitle' => 'Dein Abenteuer bleibt gespeichert',
			'recap.statsSection' => 'Statistiken',
			'recap.traceSection' => 'Deine Spur',
			'recap.noTrace' => 'Keine GPS-Spur verfügbar',
			'recap.stages' => '{done} / {total} Etappen gelaufen',
			'recap.distance' => '{km} km zurückgelegt',
			'recap.elevation' => '{meters} m Höhenmeter',
			'recap.duration' => '{days} Tage',
			'recap.dates' => 'Vom {start} bis {end}',
			'recap.viewDiploma' => 'Mein Diplom ansehen',
			'recap.viewJournal' => 'Mein Tagebuch ansehen',
			'recap.noData' => 'Noch keine Routendaten zum Anzeigen.',
			'recap.elevationLoss' => ({required Object meters}) => '${meters} m Abstieg',
			'recap.shareAdventure' => 'Mein Abenteuer teilen',
			'recap.shareHeadline' => ({required Object trail}) => 'Mein Abenteuer auf dem ${trail}',
			'recap.shareError' => 'Teilen nicht möglich',
			'recap.exportGpx' => 'Strecke als GPX exportieren',
			'recap.gpxExported' => ({required Object file}) => 'Strecke exportiert: ${file}',
			'recap.gpxEmpty' => 'Kein GPS-Punkt zum Exportieren',
			'recap.gpxError' => 'Export nicht möglich',
			'recap.daysSection' => 'Tag für Tag',
			'recap.dayLabel' => ({required Object day}) => 'Tag ${day}',
			'recap.dayStages' => ({required Object count}) => '${count} Etappe(n)',
			'recap.dayRest' => 'An diesem Tag keine Etappe beendet',
			'recap.noDays' => 'Kein per GPS aufgezeichneter Tag',
			'recap.averageSpeed' => ({required Object kmh}) => '${kmh} km/h im Durchschnitt',
			'programme.title' => 'Programm',
			'programme.helpTooltip' => 'Hilfe',
			'programme.duration.label' => 'Anzahl der Tage',
			'programme.duration.days' => '{count} T',
			'programme.duration.daysWithRest' => '{total} T (davon {rest} Ruhe)',
			'programme.duration.splitNote' => 'Mehr Tage = die härtesten Tage werden zweigeteilt, der schwerste zuerst. Ruhe ändert nicht, wie hart ein einzelner Tag ist.',
			'programme.duration.splitExhausted' => 'Alle Tage sind schon so kurz wie möglich geteilt: Der Regler entlastet das Urteil nicht weiter.',
			'programme.duration.difficulty.comfortable' => 'Gemütlich',
			'programme.duration.difficulty.standard' => 'Standard',
			'programme.duration.difficulty.sporty' => 'Sportlich',
			'programme.duration.difficulty.demanding' => 'Sehr anspruchsvoll',
			'programme.stats.distance' => 'Distanz',
			'programme.stats.elevation' => 'Aufstieg',
			'programme.stats.days' => 'Tage',
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
			'programme.mergeBlocked.locked' => 'Tag bereits gelaufen: nicht mehr änderbar',
			'programme.replan' => 'Neu planen',
			'programme.replanButton' => 'NEU PLANEN',
			'programme.replanDialog.title' => 'Neu planen',
			'programme.replanDialog.message' => 'Die Neuplanung setzt Ihr Programm zurück.\nIhre Ruhetage bleiben an denselben Positionen erhalten.',
			'programme.replanDialog.cancel' => 'Abbrechen',
			'programme.replanDialog.confirm' => 'Neu planen',
			'programme.validate' => 'PROGRAMM BESTÄTIGEN',
			'programme.validateNext' => 'Bestätigen und Daten wählen',
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
			'programme.info.mergeSplit.body' => 'Zusammenlegen verbindet zwei Tage zu einem; Teilen schneidet einen Tag in zwei — seine Etappen, wenn sie zusammengelegt waren, sonst die Etappe selbst in zwei Hälften gleicher Anstrengung. Das Urteil richtet sich nach Ihrem härtesten Tag: ihn zu teilen ist der einzige Weg, ihn zu entlasten, ein Ruhetag ändert daran nichts. Eine geteilte Etappe setzt einen Halt auf halber Strecke voraus: prüfen Sie, ob es dort eine Schlafmöglichkeit gibt.',
			'programme.info.colors.title' => 'Farben',
			'programme.info.colors.body' => 'Grün = leicht, Orange = mittel, Rot = schwer (Distanz + Aufstieg).',
			'programme.info.note' => 'Das Höhenprofil unten zeigt den Aufstieg jedes Tages.',
			'programme.info.close' => 'Verstanden!',
			'programme.splitBlocked.single' => 'Teilen nicht möglich: An diesem Tag gibt es nichts zu teilen.',
			'programme.splitBlocked.portion' => 'Teilen nicht möglich: Diese Etappe ist bereits zweigeteilt.',
			'programme.splitBlocked.locked' => 'Tag bereits gelaufen: nicht mehr änderbar',
			'programme.reorderBlocked' => 'Tour gestartet: die Reihenfolge der Etappen ändert sich nicht mehr',
			'programme.inTrek.title' => 'Route anpassen',
			'programme.inTrek.intro' => 'Gestalte den Rest deiner Tour neu. Bereits Gelaufenes ist fixiert, und die Reihenfolge der Etappen bleibt.',
			'programme.inTrek.doneSection' => 'Bereits gelaufen',
			'programme.inTrek.upcomingSection' => 'Noch vor dir',
			'programme.inTrek.doneBadge' => 'Erledigt',
			'programme.inTrek.lockedDay' => 'Tag bereits gelaufen, gesperrt',
			'programme.inTrek.allDone' => 'Du hast alle Tage gelaufen: es gibt nichts mehr anzupassen.',
			'programme.inTrek.notStarted' => 'Dieser Bildschirm ist für unterwegs: starte deine Tour, um den weiteren Verlauf anzupassen.',
			'programme.inTrek.validate' => 'Änderungen speichern',
			'programme.inTrek.saved' => 'Programm aktualisiert',
			'programme.inTrek.info.title' => 'Route anpassen',
			'programme.inTrek.info.done.title' => 'Bereits gelaufene Tage',
			'programme.inTrek.info.done.body' => 'Sie sind ausgegraut und gesperrt: was gelaufen ist, bleibt.',
			'programme.inTrek.info.upcoming.title' => 'Kommende Tage',
			'programme.inTrek.info.upcoming.body' => 'Fasse zusammen, teile auf oder füge einen Ruhetag im weiteren Verlauf ein.',
			'programme.inTrek.info.order.title' => 'Reihenfolge der Etappen',
			'programme.inTrek.info.order.body' => 'Unterwegs ändert sich die Reihenfolge nie: bereits begonnene Etappen werden nicht getauscht.',
			'programme.inTrek.info.close' => 'Verstanden',
			'programme.inTrek.empty.title' => 'Kein Programm zum Anpassen',
			'programme.inTrek.empty.message' => 'Erstelle zuerst dein Programm in der Vorbereitung.',
			'calendar.title' => 'Kalender',
			'calendar.validate' => 'DATEN BESTÄTIGEN',
			'calendar.departure' => 'ABREISE',
			'calendar.arrival' => 'ANKUNFT',
			'calendar.chooseDate' => 'Datum wählen',
			'calendar.chooseDateAction' => 'DATUM WÄHLEN',
			'calendar.previousMonth' => 'Voriger Monat',
			'calendar.nextMonth' => 'Nächster Monat',
			'calendar.dayLabel' => 'T{n}',
			'calendar.restDayLabel' => 'R',
			'calendar.adjustStages' => 'ETAPPEN ANPASSEN',
			'calendar.stageSingular' => 'Etappe {n}',
			'calendar.stagesPlural' => 'Etappen {list}',
			'calendar.splitStages' => 'Etappen trennen',
			'calendar.mergeWithNext' => 'Mit dem nächsten Tag zusammenlegen',
			'calendar.weekdays.mon' => 'Mo',
			'calendar.weekdays.tue' => 'Di',
			'calendar.weekdays.wed' => 'Mi',
			'calendar.weekdays.thu' => 'Do',
			'calendar.weekdays.fri' => 'Fr',
			'calendar.weekdays.sat' => 'Sa',
			'calendar.weekdays.sun' => 'So',
			'calendar.legend.start' => 'Abreise',
			'calendar.legend.walk' => 'Wandern',
			'calendar.legend.rest' => 'Ruhe',
			'calendar.legend.arrival' => 'Ankunft',
			'calendar.summary.totalDays' => 'Tage gesamt',
			'calendar.summary.walkDays' => 'Wandertage',
			'calendar.summary.restDays' => 'Ruhetage',
			'calendar.noDate.title' => 'Wähle ein Abreisedatum',
			'calendar.noDate.message' => 'Dein Trek-Kalender wird automatisch mit Wander- und Ruhetagen angezeigt.',
			'calendar.empty.title' => 'Richte zuerst deine Route ein',
			'calendar.empty.message' => 'Wähle deine Route und Dauer, um deine Daten festzulegen.',
			'calendar.empty.action' => 'ROUTE EINRICHTEN',
			'nuitees.title' => 'Übernachtungen',
			'nuitees.guideTooltip' => 'Übernachtungs-Ratgeber',
			'nuitees.infoBar' => 'Buchen Sie jede Nacht in der Hochsaison im Voraus',
			'nuitees.types.refuge' => 'Berghütte',
			'nuitees.types.gite' => 'Herberge',
			'nuitees.types.bivouac' => 'Biwak',
			'nuitees.types.autreHebergement' => 'Andere Unterkunft',
			'nuitees.guide.title' => 'Übernachtungs-Ratgeber',
			'nuitees.guide.refuge' => 'Bergunterkunft, Reservierung in der Hochsaison empfohlen.',
			'nuitees.guide.gite' => 'Private Etappenherberge, oft mit Mahlzeiten und Duschen.',
			'nuitees.guide.bivouac' => 'Zeltcamping, je nach örtlicher Regelung.',
			'nuitees.guide.autre' => 'Hotel, Gästehaus oder Campingplatz abseits des Weges.',
			'nuitees.guide.close' => 'Verstanden',
			'nuitees.card.dayLabel' => 'T{n}',
			'nuitees.card.noPlace' => 'Unterkunft',
			'nuitees.card.available' => '{count} Unterkünfte verfügbar',
			'nuitees.card.call' => '{phone} anrufen',
			'nuitees.card.lockedHint' => 'Nacht abwählen, um den Typ zu ändern',
			'nuitees.card.eveBadge' => 'T-1',
			'nuitees.card.eveOfDeparture' => 'Nacht vor dem Aufbruch',
			'nuitees.summary.remaining' => 'Noch {count} Nacht/Nächte',
			'nuitees.summary.done' => '{count} erledigt',
			'nuitees.summary.allBooked' => 'ALLE NÄCHTE GEBUCHT',
			'nuitees.empty.title' => 'Richten Sie zuerst Ihre Route ein',
			'nuitees.empty.message' => 'Wählen Sie Strecke und Dauer, um Ihre Nächte zu planen.',
			'nuitees.empty.action' => 'ROUTE EINRICHTEN',
			'transport.title' => 'Anreise',
			'transport.tabJoin' => 'Zum Start',
			'transport.tabJoinNamed' => ({required Object name}) => 'Nach ${name}',
			'transport.tabLeave' => 'Vom Ziel weg',
			'transport.tabLeaveNamed' => ({required Object name}) => 'Ab ${name}',
			'transport.joinTitle' => ({required Object name}) => 'Nach ${name}',
			'transport.leaveTitle' => ({required Object name}) => 'Ab ${name}',
			'transport.adviceTitle' => 'Praktische Tipps',
			'transport.website' => 'Website',
			'transport.a11y.call' => ({required Object label}) => '${label} anrufen',
			'transport.a11y.website' => 'Website öffnen',
			'fireRisk.title' => 'Brandrisiko',
			'fireRisk.refresh' => 'Aktualisieren',
			'fireRisk.refreshed' => 'Daten aktualisiert',
			'fireRisk.refreshError' => 'Keine Verbindung',
			'fireRisk.update.live' => 'Daten aktuell',
			'fireRisk.update.liveAt' => ({required Object date}) => 'Akt.: ${date}',
			'fireRisk.update.cacheRecent' => ({required Object duration}) => 'Aktualisiert vor ${duration}',
			'fireRisk.update.cacheOld' => ({required Object date}) => 'Letzte Akt.: ${date}',
			'fireRisk.update.never' => 'Nie aktualisiert',
			'fireRisk.duration.seconds' => 'einige Sekunden',
			'fireRisk.duration.minutes' => ({required Object n}) => '${n} Min',
			'fireRisk.duration.hours' => ({required Object n}) => '${n} Std',
			'fireRisk.duration.days' => ({required Object n}) => '${n} T',
			'fireRisk.fwiSource' => 'Risikoindex basierend auf dem Fire Weather Index (FWI) von Open-Meteo (Modell Meteo-France). Der FWI ist der vom europäischen EFFIS-System zur Bewertung des Waldbrandrisikos verwendete Index.',
			'fireRisk.regulation.title' => 'Vorschriften',
			'fireRisk.regulation.decreeLink' => 'Präfektorale Erlasse ansehen',
			'fireRisk.levelsTitle' => 'Risikostufen',
			'fireRisk.level.none' => 'Keine',
			'fireRisk.level.low' => 'Gering',
			'fireRisk.level.moderate' => 'Mäßig',
			'fireRisk.level.high' => 'Hoch',
			'fireRisk.level.veryHigh' => 'Sehr hoch',
			'fireRisk.level.extreme' => 'Extrem',
			'fireRisk.stagesTitle' => 'Risiko pro Etappe',
			'fireRisk.stageBadge' => ({required Object number}) => 'E${number}',
			'fireRisk.levelBadge' => ({required Object level}) => 'St. ${level}',
			'fireRisk.dayLevel' => ({required Object level}) => 'St. ${level}',
			'fireRisk.day.today' => 'Heute',
			'fireRisk.day.tomorrow' => 'Morgen',
			'fireRisk.day.plus' => ({required Object n}) => 'T+${n}',
			'fireRisk.noRisk' => 'Derzeit kein Brandrisiko gemeldet',
			'fireRisk.numbersTitle' => 'Nützliche Nummern',
			'fireRisk.number.firefighters' => 'Feuerwehr',
			'fireRisk.number.europeanEmergency' => 'Europ. Notruf',
			'fireRisk.empty.title' => 'Brandrisiko nicht verfügbar',
			'fireRisk.empty.message' => 'Die zur Berechnung des Brandrisikos nötigen Wetterdaten sind derzeit nicht verfügbar. Versuchen Sie es erneut, sobald Sie verbunden sind.',
			'fireRisk.a11y.call' => ({required Object label, required Object number}) => '${label} unter ${number} anrufen',
			'fireRisk.a11y.decree' => 'Präfektorale Erlasse öffnen',
			'fireRisk.a11y.levelBadge' => ({required Object level}) => 'Risikostufe ${level} von 5',
			'shop.title' => 'Verpflegung',
			'shop.filterAll' => 'Alle',
			'shop.typeEpicerie' => 'Lebensmittel',
			'shop.typeBar' => 'Bar/Restaurant',
			'shop.typePharmacie' => 'Apotheke',
			'shop.typeGaz' => 'Gas/Ausrüstung',
			'shop.limitedTitle' => 'Begrenzte Versorgungspunkte',
			'shop.stageHeader' => ({required Object n}) => 'Etappe ${n}',
			'shop.stageBadge' => ({required Object n}) => 'Etappe ${n}',
			'shop.gapShort' => ({required Object n}) => 'Letzte Versorgung vor ${n} Etappen ohne Geschäft',
			'shop.gapLong' => ({required Object n}) => 'Letzte Versorgung vor ${n} Etappen ohne Geschäft. Decken Sie sich ein!',
			'shop.sectionInfo' => 'Informationen',
			'shop.sectionProducts' => 'Verfügbare Produkte',
			'shop.fieldType' => 'Typ',
			'shop.fieldStage' => 'Etappe',
			'shop.fieldGps' => 'GPS',
			'shop.fieldHours' => 'Öffnungszeiten',
			'shop.website' => 'Website',
			'shop.filterEmpty' => 'Kein Geschäft für diesen Filter.',
			'shop.a11y.openDetail' => ({required Object name}) => 'Details zu ${name} anzeigen',
			'shop.a11y.call' => ({required Object label}) => '${label} anrufen',
			'shop.a11y.website' => 'Website öffnen',
			'summary.title' => 'Planübersicht',
			'summary.configTitle' => ({required Object name}) => 'Mein ${name}',
			'summary.direction' => 'Richtung',
			'summary.duration' => 'Dauer',
			'summary.durationValue' => ({required Object days}) => '${days} Wandertage',
			'summary.durationValueWithRest' => ({required Object days, required Object rest}) => '${days} Wandertage + ${rest} Ruhetage',
			'summary.startDate' => 'Abreise',
			'summary.endDate' => 'Ankunft',
			'summary.stats.title' => 'Statistiken',
			'summary.stats.distance' => 'Gesamtdistanz',
			'summary.stats.elevationGain' => 'Aufstieg gesamt',
			'summary.stats.elevationLoss' => 'Abstieg gesamt',
			'summary.stats.duration' => 'Geschätzte Zeit',
			_ => null,
		} ?? switch (path) {
			'summary.stats.stages' => 'Etappen',
			'summary.stats.restDays' => 'Ruhetage',
			'summary.dayByDay' => 'Tag für Tag',
			'summary.dayLabel' => ({required Object n}) => 'T${n}',
			'summary.stageLabel' => ({required Object n}) => 'Etappe ${n}',
			'summary.restDay' => 'Ruhetag',
			'summary.restDayTitle' => ({required Object n}) => 'Ruhetag — T${n}',
			'summary.restDayPlace' => ({required Object place}) => 'Ort: ${place}',
			'summary.actions.share' => 'MEINEN PLAN TEILEN',
			'summary.share.titleLine' => ({required Object name}) => 'Mein ${name}',
			'summary.share.walkDays' => ({required Object days}) => '${days} Wandertage',
			'summary.share.walkDaysWithRest' => ({required Object days, required Object rest}) => '${days} Wandertage + ${rest} Ruhetage',
			'summary.share.distance' => ({required Object km}) => 'Distanz: ${km} km',
			'summary.share.elevationGain' => ({required Object m}) => 'Aufstieg gesamt: ${m} m',
			'summary.share.elevationLoss' => ({required Object m}) => 'Abstieg gesamt: ${m} m',
			'summary.share.duration' => ({required Object h}) => 'Geschätzte Zeit: ~${h} h',
			'summary.share.dates' => ({required Object start, required Object end}) => 'Vom ${start} bis ${end}',
			'summary.share.planning' => '--- Tagesplan ---',
			'summary.share.dayRest' => ({required Object n}) => 'T${n}: Ruhetag',
			'summary.share.dayStages' => ({required Object n, required Object stages}) => 'T${n}: ${stages}',
			'summary.share.footer' => ({required Object name}) => 'Geplant mit ${name}',
			'summary.empty.title' => 'Richten Sie zuerst Ihre Route ein',
			'summary.empty.message' => 'Wählen Sie Ihre Route und Dauer, um die Planübersicht zu sehen.',
			'summary.empty.action' => 'ROUTE EINRICHTEN',
			'summary.a11y.dayTile' => ({required Object day}) => 'Details für Tag ${day} anzeigen',
			'summary.a11y.restDayTile' => ({required Object day}) => 'Details zum Ruhetag ${day}',
			'summary.a11y.share' => 'Meinen Plan teilen',
			'import.title' => 'GPX importieren',
			'import.headerTitle' => 'Eine GPX-Datei importieren',
			'import.headerBody' => 'Importieren Sie einen mit einer anderen App (Strava, Garmin usw.) aufgezeichneten GPS-Track, um Ihre Zusammenfassung zu erstellen.',
			'import.pickButton' => 'GPX-DATEI AUSWÄHLEN',
			'import.traceSection' => 'Importierter Track',
			'import.statsSection' => 'Statistiken',
			'import.statDistance' => 'Distanz',
			'import.statElevationGain' => 'Aufstieg',
			'import.statElevationLoss' => 'Abstieg',
			'import.statDuration' => 'Dauer',
			'import.statDirection' => 'Richtung',
			'import.statPoints' => 'GPS-Punkte',
			'import.directionNS' => 'Nord-Süd',
			'import.directionSN' => 'Süd-Nord',
			'import.stagesSection' => 'Erkannte Etappen',
			'import.stagesCount' => '{done}/{total}',
			'import.stageBadge' => 'E{number}',
			'import.warningsSection' => 'Warnungen',
			'import.warningOutOfBounds' => '{count} Punkt(e) außerhalb des Gebiets ignoriert.',
			'import.warningOffTrail' => '{percent}% der Punkte sind weit vom Weg entfernt.',
			'import.invalidTooFewPoints' => 'GPX-Datei zu klein: {count} Punkte (mindestens 10).',
			'import.invalidOutOfBounds' => 'Der Track passt nicht zum Gebiet dieses Weges.',
			'import.errorUnreadable' => 'Datei kann nicht gelesen werden.',
			'import.errorParsing' => 'Die GPX-Datei konnte nicht gelesen werden.',
			'import.validateButton' => 'IMPORT BESTÄTIGEN',
			'import.confirmTitle' => 'Import bestätigen?',
			'import.confirmBody' => 'Dieser Track wird als Ihre Route importiert:\n\n- {points} GPS-Punkte\n- {km} km\n- {stages} erkannte Etappen\n- Richtung: {direction}',
			'import.cancel' => 'Abbrechen',
			'import.validate' => 'Bestätigen',
			'import.importedSnack' => 'GPX-Track importiert!',
			'myTreks.title' => 'Meine Touren',
			'myTreks.sectionInProgress' => 'Laufend',
			'myTreks.sectionPrepared' => 'Vorbereitet',
			'myTreks.sectionCompleted' => 'Abgeschlossen',
			'myTreks.emptyTitle' => 'Noch keine Touren',
			'myTreks.empty' => 'Noch keine Tour. Entdecke einen Weg, um zu beginnen.',
			'myTreks.discoverTitle' => 'Wege entdecken',
			'myTreks.discoverSubtitle' => 'Katalog durchsuchen',
			'myTreks.accountTitle' => 'Mein Konto',
			'myTreks.accountSubtitle' => 'Profil und Einstellungen',
			'myTreks.badge.owned' => 'Im Besitz',
			'myTreks.badge.prepared' => 'Vorbereitet',
			'myTreks.badge.inProgress' => 'Laufend',
			'myTreks.badge.completed' => 'Abgeschlossen',
			'myTreks.progressLabel' => ({required Object percent}) => '${percent} % des Weges',
			'myTreks.a11y.trekCard' => ({required Object nom, required Object state}) => 'Tour ${nom}, ${state}',
			'myTreks.a11y.openTrek' => ({required Object nom}) => 'Tour ${nom} öffnen',
			'myTreks.settingsSubtitle' => 'Sprache, Einheiten, Thema',
			'trekState.abandonDialog.title' => 'Eine Tour läuft bereits',
			'trekState.abandonDialog.message' => 'Du hast eine laufende Wanderung. Beende oder brich sie ab, bevor du eine neue startest.',
			'trekState.abandonDialog.finish' => 'Beenden',
			'trekState.abandonDialog.abandon' => 'Abbrechen',
			'trekState.abandonDialog.cancel' => 'Zurück',
			'trekState.resumeOrphanDialog.title' => 'Wanderung fortsetzen?',
			'trekState.resumeOrphanDialog.message' => 'Beim letzten Schließen der App lief noch eine Wanderung. Möchtest du sie fortsetzen oder abbrechen?',
			'trekState.resumeOrphanDialog.resume' => 'Fortsetzen',
			'trekState.resumeOrphanDialog.abandon' => 'Abbrechen',
			'hikerProfile.title' => 'Ihre Angaben',
			'hikerProfile.privacyBanner' => 'Ihre Körperdaten sind sensible Daten. Sie bleiben auf Ihrem Gerät (und einer verschlüsselten Sicherung ohne Ihren Namen), um Ihre Machbarkeit zu berechnen.',
			'hikerProfile.fieldAge' => 'Alter',
			'hikerProfile.hintAge' => 'In Jahren',
			'hikerProfile.errorAge' => 'Ungültiges Alter (18 bis 120 Jahre)',
			'hikerProfile.fieldHeight' => 'Grösse',
			'hikerProfile.hintHeight' => 'In Zentimetern',
			'hikerProfile.errorHeight' => 'Ungültige Grösse (60 bis 255 cm)',
			'hikerProfile.fieldWeight' => 'Gewicht',
			'hikerProfile.hintWeight' => 'In Kilogramm',
			'hikerProfile.errorWeight' => 'Ungültiges Gewicht (25 bis 200 kg)',
			'hikerProfile.errorCountry' => 'Ungültiger Ländercode (z. B. FR)',
			'hikerProfile.errorEmpty' => 'Leeres Profil: Geben Sie mindestens Alter, Grösse oder Gewicht an.',
			'hikerProfile.errorConsentRequired' => 'Ohne Ihre Einwilligung wird nichts gespeichert: Alter, Grösse und Gewicht sind Gesundheitsdaten. Was gespeichert war, wurde soeben von diesem Gerät gelöscht. Aktivieren Sie oben die Zustimmung und speichern Sie erneut.',
			'hikerProfile.fieldSex' => 'Geschlecht (optional)',
			'hikerProfile.sexFemale' => 'Weiblich',
			'hikerProfile.sexMale' => 'Männlich',
			'hikerProfile.sexUnspecified' => 'Keine Angabe',
			'hikerProfile.fieldCountry' => 'Land',
			'hikerProfile.countryUnspecified' => 'Keine Angabe',
			'hikerProfile.hintCountry' => 'Code (z. B. FR)',
			'hikerProfile.consentTitle' => 'Körperdaten (DSGVO Artikel 9)',
			'hikerProfile.consentBody' => 'Alter, Grösse und Gewicht sind Gesundheitsdaten. Sie bleiben auf Ihrem Gerät und einer Sicherung ohne Ihren Namen oder Ihre E-Mail, nie im Klartext gesendet. Diese Einwilligung wird separat erfragt.',
			'hikerProfile.consentToggle' => 'Ich erlaube die Nutzung meiner Körperdaten für die Machbarkeit',
			'hikerProfile.save' => 'Speichern',
			'hikerProfile.saved' => 'Angaben gespeichert',
			'hikerProfile.morphoNotPrefilledHint' => 'Nichts ist vorausgefüllt: Geben Sie Ihre echten Daten ein, es geht um Ihre Sicherheit.',
			'hikerProfile.seniorReminder' => 'Ab 65 Jahren wird vor einem anspruchsvollen Trek eine ärztliche Untersuchung empfohlen.',
			'walkTest.title' => '6-Minuten-Gehtest',
			'walkTest.intro' => 'Gehen Sie in 6 Minuten so weit wie möglich auf ebenem Gelände. Das GPS misst die Distanz; wir vergleichen sie mit Normen für Alter und Geschlecht.',
			'walkTest.safetyWarning' => 'Vermeiden Sie diese Anstrengung bei ungeklärten Herzproblemen. Hören Sie bei Unwohlsein auf.',
			'walkTest.start' => 'Test starten',
			'walkTest.stop' => 'Stoppen',
			'walkTest.cancel' => 'Abbrechen',
			'walkTest.countdown' => 'Machen Sie sich bereit...',
			'walkTest.running' => 'Läuft',
			'walkTest.liveDistance' => 'Distanz',
			'walkTest.timeLeft' => 'Verbleibende Zeit',
			'walkTest.meters' => 'm',
			'walkTest.resultTitle' => 'Testergebnis',
			'walkTest.resultDistance' => 'Zurückgelegte Distanz',
			'walkTest.resultLevel' => 'Geschätztes Niveau',
			'walkTest.resultDate' => ({required Object date}) => 'Durchgeführt am ${date}',
			'walkTest.doneAgain' => 'Test wiederholen',
			'walkTest.gpsNeeded' => 'GPS wird benötigt, um die Distanz zu messen.',
			'walkTest.gpsDenied' => 'Erlauben Sie den Standort, um den Test zu starten.',
			'walkTest.monthlyReminderOn' => 'Monatliche Erinnerung aktiv',
			'walkTest.monthlyReminderBody' => 'Jeden Monat wird eine Test-Erinnerung angeboten, um Ihre Form zu verfolgen.',
			'walkTest.notDoneYet' => 'Test nicht durchgeführt',
			'walkTest.fallbackNotice' => 'Bis zum Test wird Ihr Niveau aus Ihrem Fragebogen geschätzt.',
			'walkTest.levels.low' => 'Niedrig',
			'walkTest.levels.moderate' => 'Mittel',
			'walkTest.levels.good' => 'Gut',
			'walkTest.levels.excellent' => 'Ausgezeichnet',
			'walkTest.absoluteScaleNotice' => 'Dein Niveau wird auf der reinen Distanzskala gelesen: der Vergleich mit einem Referenzwert wurde für deinen Körperbau nicht erstellt, also wenden wir ihn nicht an. Dein Test selbst bleibt voll gültig.',
			'walkTest.ageClampNotice' => 'Über 80 Jahre endet der Referenzwert des Tests: er wird wie mit 80 berechnet, und wir sagen es dir.',
			'pastHikes.title' => 'Ihre letzten 5 Touren',
			'pastHikes.intro' => 'Fügen Sie bis zu 5 markante Touren hinzu. Wir leiten Ihr echtes Niveau ab (Tempo, Ausdauer, Höhengewöhnung) statt eines Etiketts.',
			'pastHikes.addHike' => 'Tour hinzufügen',
			'pastHikes.empty' => 'Noch keine Tour erfasst.',
			'pastHikes.fieldDate' => 'Datum',
			'pastHikes.fieldDays' => 'Anzahl Tage',
			'pastHikes.fieldAvgHours' => 'Gehzeit pro Tag (Std.)',
			'pastHikes.fieldElevation' => 'Gesamtanstieg (m)',
			'pastHikes.fieldDistance' => 'Gesamtdistanz (km)',
			'pastHikes.errorDays' => 'Ungültige Tageszahl (1 bis 60)',
			'pastHikes.errorHours' => 'Ungültige Dauer (0 bis 24 h)',
			'pastHikes.errorElevation' => 'Ungültiger Höhenunterschied (0 bis 5000 m)',
			'pastHikes.errorDistance' => 'Ungültige Distanz (0 bis 100 km)',
			'pastHikes.errorEffort' => 'Geben Sie mindestens Höhenmeter oder Distanz an',
			'pastHikes.perDay' => 'pro Tag',
			'pastHikes.editHike' => 'Tour bearbeiten',
			'pastHikes.deleteHike' => 'Löschen',
			'pastHikes.save' => 'Speichern',
			'pastHikes.saved' => 'Touren gespeichert',
			'pastHikes.maxReached' => 'Maximum von 5 Touren erreicht.',
			'pastHikes.difficultiesTitle' => 'Aufgetretene Schwierigkeiten',
			'pastHikes.difficultiesHint' => 'Ein Text für alle diese Touren: Blasen, Knie beim Abstieg, Atemnot in der Höhe, Hitzestress...',
			'pastHikes.difficultiesSaved' => 'Notiz gespeichert',
			'ffrando.cotationTitle' => 'FFRandonnee-Bewertung',
			'ffrando.effort' => 'Anstrengung',
			'ffrando.technicite' => 'Technik',
			'ffrando.risque' => 'Risiko',
			'ffrando.ibpLabel' => 'IBP-Index',
			'ffrando.effortScale' => 'Anstrengung (1 bis 5)',
			'ffrando.techniciteScale' => 'Technik (1 bis 5)',
			'ffrando.risqueScale' => 'Risiko (1 bis 5)',
			'ffrando.notRated' => 'Nicht bewertet',
			'ffrando.effortLevels.k1' => 'Sehr leicht',
			'ffrando.effortLevels.k2' => 'Leicht',
			'ffrando.effortLevels.k3' => 'Mittel',
			'ffrando.effortLevels.k4' => 'Schwer',
			'ffrando.effortLevels.k5' => 'Sehr schwer',
			'sos.title' => 'Notruf absetzen?',
			'sos.body' => 'Sie sind dabei, den Notruf 112 (europäischer Notruf) zu wählen.',
			'sos.positionTitle' => 'Ihre aktuelle Position',
			'sos.positionUnavailable' => 'GPS-Position nicht verfügbar',
			'sos.gpsAcquiring' => 'GPS wird ermittelt…',
			'sos.positionLine' => ({required Object lat, required Object lng, required Object alt}) => 'Position: ${lat}, ${lng}  -  Höhe ${alt} m',
			'sos.noContacts' => 'Kein Kontakt konfiguriert',
			'sos.callContact' => ({required Object name}) => '${name} anrufen',
			'sos.altitudeUnavailable' => 'Höhe: nicht verfügbar',
			'sos.communicate' => 'Teilen Sie den Rettungskräften diese Koordinaten mit.',
			'sos.cancel' => 'Abbrechen',
			'sos.call' => '112 anrufen',
			'sos.medicalId.action' => 'Notfallpass des Telefons',
			'sos.medicalId.hint' => 'Zeigen Sie den Rettungskräften Ihre Vitaldaten, auch im Sperrbildschirm.',
			'sos.medicalId.unavailable' => 'Öffnen Sie den Notfallpass in den Gesundheitseinstellungen Ihres Telefons.',
			'recovery.section' => 'Konto und Wiederherstellung',
			'recovery.sectionDesc' => 'Meinen Wiederherstellungscode anzeigen',
			'recovery.title' => 'Mein Wiederherstellungscode',
			'recovery.intro' => 'Dieser Code öffnet deinen Tresor (Profil, persönliche Angaben und Etappen-Guthaben) auf einem anderen Telefon. Notiere ihn und bewahre ihn sicher auf: Er funktioniert wie ein Passwort.',
			'recovery.codeLabel' => 'Dein Code',
			'recovery.copy' => 'Code kopieren',
			'recovery.copied' => 'Code kopiert',
			'recovery.warning' => 'Niemand sonst kann deinen Tresor lesen, auch wir nicht. Wenn du diesen Code verlierst, sind deine Daten unwiederbringlich verloren.',
			'recovery.error' => 'Der Code kann derzeit nicht erzeugt werden.',
			'common.cannotLoadStages' => 'Etappen können nicht geladen werden',
			'common.noStages' => 'Keine Etappen verfügbar',
			'common.cannotLoadStage' => 'Diese Etappe kann nicht geladen werden',
			'common.stageNotFound' => 'Etappe nicht gefunden',
			'common.cannotLoadTrack' => 'Track kann nicht geladen werden',
			'common.loadingTrack' => 'Track wird geladen…',
			'common.gpxEmpty' => 'Die GPX-Datei enthält keine Punkte.',
			'common.noPoiForStage' => 'Kein interessanter Punkt für diese Etappe.',
			'common.viewOnMap' => 'Auf Karte anzeigen',
			'common.error' => 'Fehler',
			'common.pageNotFound' => ({required Object path}) => 'Seite nicht gefunden: ${path}',
			_ => null,
		};
	}
}
