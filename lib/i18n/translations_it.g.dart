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
class TranslationsIt extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsIt({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.it,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <it>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsIt _root = this; // ignore: unused_field

	@override 
	TranslationsIt $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsIt(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$a11y$it a11y = _Translations$a11y$it._(_root);
	@override late final _Translations$nav$it nav = _Translations$nav$it._(_root);
	@override late final _Translations$branding$it branding = _Translations$branding$it._(_root);
	@override late final _Translations$hub$it hub = _Translations$hub$it._(_root);
	@override late final _Translations$map$it map = _Translations$map$it._(_root);
	@override late final _Translations$stage$it stage = _Translations$stage$it._(_root);
	@override late final _Translations$trail$it trail = _Translations$trail$it._(_root);
	@override late final _Translations$poi$it poi = _Translations$poi$it._(_root);
	@override late final _Translations$accommodation$it accommodation = _Translations$accommodation$it._(_root);
	@override late final _Translations$gps$it gps = _Translations$gps$it._(_root);
	@override late final _Translations$navAlert$it navAlert = _Translations$navAlert$it._(_root);
	@override late final _Translations$planning$it planning = _Translations$planning$it._(_root);
	@override late final _Translations$itinerary$it itinerary = _Translations$itinerary$it._(_root);
	@override late final _Translations$tracking$it tracking = _Translations$tracking$it._(_root);
	@override late final _Translations$checklist$it checklist = _Translations$checklist$it._(_root);
	@override late final _Translations$journal$it journal = _Translations$journal$it._(_root);
	@override late final _Translations$weather$it weather = _Translations$weather$it._(_root);
	@override late final _Translations$share$it share = _Translations$share$it._(_root);
	@override late final _Translations$diploma$it diploma = _Translations$diploma$it._(_root);
	@override late final _Translations$notifications$it notifications = _Translations$notifications$it._(_root);
	@override late final _Translations$settings$it settings = _Translations$settings$it._(_root);
	@override late final _Translations$appearance$it appearance = _Translations$appearance$it._(_root);
	@override late final _Translations$feedback$it feedback = _Translations$feedback$it._(_root);
	@override late final _Translations$auth$it auth = _Translations$auth$it._(_root);
	@override late final _Translations$feasibility$it feasibility = _Translations$feasibility$it._(_root);
	@override late final _Translations$tips$it tips = _Translations$tips$it._(_root);
	@override late final _Translations$goodies$it goodies = _Translations$goodies$it._(_root);
	@override late final _Translations$noData$it noData = _Translations$noData$it._(_root);
	@override late final _Translations$catalog$it catalog = _Translations$catalog$it._(_root);
	@override late final _Translations$updates$it updates = _Translations$updates$it._(_root);
	@override late final _Translations$follow$it follow = _Translations$follow$it._(_root);
	@override late final _Translations$cloud$it cloud = _Translations$cloud$it._(_root);
	@override late final _Translations$onboarding$it onboarding = _Translations$onboarding$it._(_root);
	@override late final _Translations$monetization$it monetization = _Translations$monetization$it._(_root);
	@override late final _Translations$signalement$it signalement = _Translations$signalement$it._(_root);
	@override late final _Translations$hebergement$it hebergement = _Translations$hebergement$it._(_root);
	@override late final _Translations$training$it training = _Translations$training$it._(_root);
	@override late final _Translations$eta$it eta = _Translations$eta$it._(_root);
	@override late final _Translations$leaderboard$it leaderboard = _Translations$leaderboard$it._(_root);
	@override late final _Translations$social$it social = _Translations$social$it._(_root);
	@override late final _Translations$gamification$it gamification = _Translations$gamification$it._(_root);
	@override late final _Translations$shareVisibility$it shareVisibility = _Translations$shareVisibility$it._(_root);
	@override late final _Translations$waypoints$it waypoints = _Translations$waypoints$it._(_root);
	@override late final _Translations$packs$it packs = _Translations$packs$it._(_root);
	@override late final _Translations$guides$it guides = _Translations$guides$it._(_root);
	@override late final _Translations$health$it health = _Translations$health$it._(_root);
	@override late final _Translations$trailSelection$it trailSelection = _Translations$trailSelection$it._(_root);
	@override late final _Translations$consent$it consent = _Translations$consent$it._(_root);
	@override late final _Translations$moderation$it moderation = _Translations$moderation$it._(_root);
	@override late final _Translations$bootstrap$it bootstrap = _Translations$bootstrap$it._(_root);
	@override late final _Translations$recap$it recap = _Translations$recap$it._(_root);
	@override late final _Translations$programme$it programme = _Translations$programme$it._(_root);
	@override late final _Translations$calendar$it calendar = _Translations$calendar$it._(_root);
	@override late final _Translations$nuitees$it nuitees = _Translations$nuitees$it._(_root);
}

// Path: a11y
class _Translations$a11y$it extends Translations$a11y$fr {
	_Translations$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get back => 'Indietro';
	@override String get zoomIn => 'Ingrandisci';
	@override String get zoomOut => 'Riduci';
	@override String get centerOnMe => 'Centra sulla mia posizione';
	@override String get mapRegion => 'Mappa del sentiero';
	@override String get userPosition => 'La tua posizione';
	@override String stageMarker({required Object number}) => 'Tappa ${number}';
	@override String poiMarker({required Object name}) => 'Punto di interesse: ${name}';
	@override String markerCluster({required Object count}) => '${count} punti raggruppati';
	@override String trailCard({required Object name}) => 'Sentiero ${name}';
	@override String get startTracking => 'Avvia il monitoraggio';
	@override String get pauseTracking => 'Sospendi il monitoraggio';
	@override String get resumeTracking => 'Riprendi il monitoraggio';
	@override String get stopTracking => 'Ferma il monitoraggio';
	@override String get sos => 'Chiamata di emergenza SOS';
	@override String get mapLayers => 'Livelli della mappa';
}

// Path: nav
class _Translations$nav$it extends Translations$nav$fr {
	_Translations$nav$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Home';
	@override String get map => 'Mappa';
	@override String get stages => 'Tappe';
	@override String get planning => 'Pianificazione';
	@override String get journal => 'Diario';
	@override String get more => 'Altro';
	@override String get checklist => 'Attrezzatura & Zaino';
	@override String get feasibility => 'Fattibilità';
	@override String get tips => 'Consigli trek';
	@override String get emergency => 'Contatti emergenza';
	@override String get catalog => 'Catalogo sentieri';
	@override String get profile => 'Profilo';
	@override String get settings => 'Impostazioni';
	@override String get trailSelection => 'Cambia sentiero';
}

// Path: branding
class _Translations$branding$it extends Translations$branding$fr {
	_Translations$branding$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Il tuo compagno di trekking';
	@override String get subline => 'Prepara, cammina, condividi';
}

// Path: hub
class _Translations$hub$it extends Translations$hub$fr {
	_Translations$hub$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String greeting({required Object name}) => 'Ciao, ${name}!';
	@override String get greetingFallback => 'Escursionista';
	@override String get infoTooltip => 'Info sul sentiero';
	@override String get profileTooltip => 'Il mio profilo';
	@override String get infoSheetBody => 'Questo sentiero ti accompagna a ogni passo: pianifica il tuo itinerario, prepara lo zaino e parti con la navigazione GPS. Ogni funzione è raggiungibile da questa schermata iniziale.';
	@override late final _Translations$hub$trekCard$it trekCard = _Translations$hub$trekCard$it._(_root);
	@override late final _Translations$hub$weather$it weather = _Translations$hub$weather$it._(_root);
	@override String get startCta => 'Avvia il trek';
	@override late final _Translations$hub$sections$it sections = _Translations$hub$sections$it._(_root);
	@override late final _Translations$hub$cards$it cards = _Translations$hub$cards$it._(_root);
	@override late final _Translations$hub$fab$it fab = _Translations$hub$fab$it._(_root);
}

// Path: map
class _Translations$map$it extends Translations$map$fr {
	_Translations$map$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mappa del sentiero';
	@override String get loading => 'Caricamento del tracciato...';
	@override String get noTrack => 'Nessun tracciato disponibile';
	@override String get viewMap => 'Vedi la mappa';
	@override String get layers => 'Livelli';
	@override String get layersTitle => 'Livelli della mappa';
	@override String get layersSubtitle => 'Scegli cosa mostrare sulla mappa';
	@override String stageRemaining({required Object km}) => '${km} km rimanenti';
	@override String get offTrackChip => 'Fuori traccia';
}

// Path: stage
class _Translations$stage$it extends Translations$stage$fr {
	_Translations$stage$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distanza';
	@override String get elevation => 'Dislivello';
	@override String get elevationGain => 'Dislivello positivo';
	@override String get elevationLoss => 'Dislivello negativo';
	@override String get duration => 'Durata stimata';
	@override String get description => 'Descrizione';
	@override String get coordinates => 'Coordinate';
	@override String get pois => 'Punti di interesse';
	@override late final _Translations$stage$difficulty$it difficulty = _Translations$stage$difficulty$it._(_root);
	@override String get remaining => '{distance} km rimanenti';
	@override String get arrived => 'Sei arrivato!';
	@override String get altitudeProfile => 'Profilo altimetrico';
	@override String get statistics => 'Statistiche';
	@override String get loading => 'Caricamento...';
	@override String get loadingList => 'Caricamento delle tappe...';
	@override String get dPlus => 'D+';
	@override String get dMinus => 'D-';
	@override String get difficultyLabel => 'Difficolta';
	@override late final _Translations$stage$waterSources$it waterSources = _Translations$stage$waterSources$it._(_root);
	@override late final _Translations$stage$accommodation$it accommodation = _Translations$stage$accommodation$it._(_root);
	@override late final _Translations$stage$advice$it advice = _Translations$stage$advice$it._(_root);
}

// Path: trail
class _Translations$trail$it extends Translations$trail$fr {
	_Translations$trail$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Tappe';
	@override String get totalDistance => 'Distanza totale';
	@override String get totalElevation => 'Dislivello totale';
}

// Path: poi
class _Translations$poi$it extends Translations$poi$fr {
	_Translations$poi$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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

// Path: accommodation
class _Translations$accommodation$it extends Translations$accommodation$fr {
	_Translations$accommodation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$accommodation$types$it types = _Translations$accommodation$types$it._(_root);
}

// Path: gps
class _Translations$gps$it extends Translations$gps$fr {
	_Translations$gps$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get permission => 'Autorizzazione GPS richiesta';
	@override String get denied => 'Accesso alla posizione negato';
	@override String get disabled => 'Servizio di localizzazione disattivato';
	@override String get offTrack => 'Fuori tracciato';
	@override String get centerOnMe => 'Centra sulla mia posizione';
}

// Path: navAlert
class _Translations$navAlert$it extends Translations$navAlert$fr {
	_Translations$navAlert$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String offTrackBanner({required Object meters}) => 'Ti stai allontanando dal sentiero — ${meters} m. Controlla la tua posizione.';
	@override String get offTrackNotifTitle => 'Stai lasciando il sentiero';
	@override String offTrackNotifBody({required Object meters}) => 'Ti stai allontanando dal sentiero (${meters} m). Controlla la tua posizione.';
}

// Path: planning
class _Translations$planning$it extends Translations$planning$fr {
	_Translations$planning$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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

// Path: itinerary
class _Translations$itinerary$it extends Translations$itinerary$fr {
	_Translations$itinerary$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Itinerario';
	@override String get subtitle => 'Le tue tappe, giorno per giorno';
	@override String get empty => 'Nessuna tappa disponibile';
	@override String get emptyHint => 'I dati del sentiero non sono caricati.';
	@override String get loading => 'Caricamento itinerario...';
	@override String get error => 'Impossibile caricare l\'itinerario';
	@override String get day => 'Giorno';
	@override String get stage => 'Tappa';
	@override String get stages => 'Tappe';
	@override String get totalDistance => 'Distanza';
	@override String get totalElevation => 'D+';
	@override String get restDay => 'Giorno di riposo';
	@override String get viewStage => 'Vedi tappa';
	@override String get openMap => 'Vedi sulla mappa';
	@override String get stageCount => '{count} tappe';
}

// Path: tracking
class _Translations$tracking$it extends Translations$tracking$fr {
	_Translations$tracking$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
	@override String get dPlus => 'D+';
	@override String get stopSaveProgress => 'I tuoi progressi saranno salvati.';
	@override String get cancel => 'Annulla';
	@override String get stopButton => 'Stop';
}

// Path: checklist
class _Translations$checklist$it extends Translations$checklist$fr {
	_Translations$checklist$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Attrezzatura & Zaino';
	@override String get subtitle => 'Prepara lo zaino';
	@override String get progress => '{checked}/{total} preparati';
	@override String get complete => 'Lista completa!';
	@override String get reset => 'Reimposta';
	@override String get resetConfirm => 'Reimpostare la lista?';
	@override String get resetDescription => 'Tutti gli elementi saranno deselezionati.';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'Conferma';
	@override late final _Translations$checklist$categories$it categories = _Translations$checklist$categories$it._(_root);
	@override late final _Translations$checklist$items$it items = _Translations$checklist$items$it._(_root);
	@override String get essential => 'Essenziale';
	@override late final _Translations$checklist$weight$it weight = _Translations$checklist$weight$it._(_root);
	@override late final _Translations$checklist$ui$it ui = _Translations$checklist$ui$it._(_root);
}

// Path: journal
class _Translations$journal$it extends Translations$journal$fr {
	_Translations$journal$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
class _Translations$weather$it extends Translations$weather$fr {
	_Translations$weather$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
	@override String get fireRisk => 'Rischio incendio';
	@override String get fireRiskDesc => 'Rischio incendio elevato. Consultare le istruzioni di sicurezza.';
	@override String get fireSafetyTips => 'Istruzioni antincendio';
	@override String get alertCount => 'allerta';
	@override String get alertCountPlural => 'allerte';
	@override String get today => 'Oggi';
	@override String get tomorrow => 'Domani';
	@override String get dayPlus2 => 'Dopodomani';
	@override String get allStages => 'Tutte le tappe';
	@override String get noForecast => 'Nessuna previsione disponibile.';
	@override String stageLabel({required Object number}) => 'Tappa ${number}';
	@override String get stormAlertsTitle => 'Allerte temporali';
	@override String get stormAlertsToggleOn => 'Allerte temporali attive';
	@override String get stormAlertsToggleOff => 'Allerte temporali disattivate';
	@override String lastUpdate({required Object date}) => 'Aggiornato ${date}';
	@override String get guideTitle => 'Capire il meteo';
	@override String get guideBody => 'Le previsioni coprono 7 giorni per ogni tappa. Attenzione alle allerte temporali e vento: in montagna il tempo cambia in fretta. Senza rete vengono mostrati gli ultimi dati salvati.';
	@override late final _Translations$weather$source$it source = _Translations$weather$source$it._(_root);
	@override late final _Translations$weather$recommendation$it recommendation = _Translations$weather$recommendation$it._(_root);
	@override late final _Translations$weather$alert$it alert = _Translations$weather$alert$it._(_root);
}

// Path: share
class _Translations$share$it extends Translations$share$fr {
	_Translations$share$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Condividi';
	@override String get generating => 'Generazione...';
	@override String get share => 'Condividi';
	@override String get error => 'Errore durante la generazione';
	@override String get errorShare => 'Errore durante la condivisione';
	@override String get preview => 'Anteprima';
	@override String get chooseTemplate => 'Scegli un template';
	@override String get templateStats => 'Statistiche';
	@override String get templateJourney => 'Percorso';
	@override String get templateStage => 'Tappa';
}

// Path: diploma
class _Translations$diploma$it extends Translations$diploma$fr {
	_Translations$diploma$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diploma di trekking';
	@override String get yourName => 'Il tuo nome';
	@override String get namePlaceholder => 'Inserisci il tuo nome...';
	@override String get generatePdf => 'Genera PDF';
	@override String get certifies => 'Certifica che';
	@override String get completed => 'ha percorso il';
	@override String get pdfTitle => 'DIPLOMA';
	@override String get pdfSubtitle => 'Certificato di completamento';
	@override String get pdfStages => '{count} tappe';
	@override String get pdfDistance => '{km} km percorsi';
	@override String get pdfElevation => '{meters} m di dislivello positivo';
	@override String get pdfDuration => 'in {days} giorni';
	@override String get pdfFrom => 'Dal';
	@override String get pdfTo => 'al';
	@override String get pdfIssuedOn => 'Rilasciato il {date}';
	@override String get recapTitle => 'La tua avventura';
	@override String get recapJournalPhotos => 'Foto del diario';
	@override String get recapNoPhotos => 'Nessuna foto nel diario';
	@override String get recapStats => 'Statistiche';
	@override String get recapStages => '{count} tappe completate';
	@override String get recapDistance => '{km} km percorsi';
	@override String get recapElevation => '{meters} m di dislivello';
	@override String get recapDuration => '{days} giorni di trekking';
	@override String get recapMapTrace => 'Tracciato del percorso';
	@override String get recapNoMap => 'Tracciato non disponibile';
	@override String get recapJournalEntries => '{count} note del diario';
	@override String get downloadPdf => 'Scarica diploma PDF';
	@override String get lockedTitle => 'Diploma bloccato';
	@override String get lockedMessage => 'Completa l intero percorso per sbloccare il tuo diploma da finisher.';
	@override String get labelIntegral => 'Percorso integrale';
	@override String get labelPartial => 'Percorso parziale';
}

// Path: notifications
class _Translations$notifications$it extends Translations$notifications$fr {
	_Translations$notifications$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Promemoria mattutino';
	@override String get weatherAlerts => 'Allerte meteo';
	@override String get countdown => 'Promemoria G-2';
	@override String get countdownDesc => 'Notifica 2 giorni prima della partenza';
	@override String get schedulerCountdownTitle => 'Il tuo trek si avvicina!';
	@override String get schedulerCountdownBody => 'Partenza tra 2 giorni. Controlla la checklist e il meteo.';
	@override String get schedulerDailyTitle => 'Buona giornata di trek!';
	@override String get schedulerDailyBody => 'Controlla il meteo e prepara la tappa di oggi.';
}

// Path: settings
class _Translations$settings$it extends Translations$settings$fr {
	_Translations$settings$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
	@override String get morningReminder => 'Promemoria mattutino';
	@override String get weatherAlerts => 'Allerte meteo';
	@override String get weatherAlertsDesc => 'Avvisato in caso di condizioni pericolose';
	@override String get countdownReminder => 'Promemoria G-2';
	@override String get countdownDesc => 'Notifica 2 giorni prima della partenza';
	@override String get offTrackAlerts => 'Avviso fuori tracciato';
	@override String get offTrackAlertsDesc => 'Notifica + vibrazione se lasci il sentiero';
	@override String get version => 'Versione';
	@override String get versionLabel => 'Versione dell\'app';
}

// Path: appearance
class _Translations$appearance$it extends Translations$appearance$fr {
	_Translations$appearance$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Aspetto';
	@override String get subtitle => 'Scegli lo stile dell’app';
	@override String get skinSentierVivant => 'Sentiero Vivo';
	@override String get skinSentierVivantDesc => 'Moderno e colorato, il colore del sentiero in primo piano';
	@override String get skinTopographique => 'Topografico';
	@override String get skinTopographiqueDesc => 'Stile carta topografica, dati in evidenza';
	@override String get skinGrandAir => 'Grande Aria';
	@override String get skinGrandAirDesc => 'Foto a tutto schermo, atmosfera da diario d’avventura';
	@override String get unavailableOnTrail => 'Non disponibile su questo sentiero';
	@override String get changeSkin => 'Cambia aspetto';
	@override String get selected => 'Selezionato';
}

// Path: feedback
class _Translations$feedback$it extends Translations$feedback$fr {
	_Translations$feedback$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Tipo di feedback';
	@override String get bug => 'Bug / Problema';
	@override String get suggestion => 'Suggerimento';
	@override String get compliment => 'Complimento';
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
class _Translations$auth$it extends Translations$auth$fr {
	_Translations$auth$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profilo';
	@override String get anonymous => 'Escursionista senza account';
	@override String get connectedVia => 'Connesso tramite';
	@override String get signInGoogle => 'Accedi con Google';
	@override String get signInGoogleDesc => 'Per salvare i tuoi progressi';
	@override String get signOut => 'Esci';
	@override String get signOutDesc => 'Torna alla modalità senza account';
	@override String get signOutConfirm => 'Disconnettersi?';
	@override String get signOutMessage => 'Tornerai alla modalità senza account. I tuoi dati locali saranno conservati.';
	@override String get deleteAccount => 'Elimina il mio account';
	@override String get deleteAccountDesc => 'Tutti i tuoi dati saranno cancellati';
	@override String get deleteConfirm => 'Eliminare il tuo account?';
	@override String get deleteMessage => 'Questa azione è irreversibile. Tutti i tuoi dati, note e progressi saranno cancellati.';
	@override String get cancel => 'Annulla';
	@override String get pseudonym => 'Pseudonimo';
	@override String get pseudonymHint => 'Il tuo nome da escursionista';
	@override String get save => 'Salva';
	@override String get changeAvatar => 'Cambia avatar';
	@override String get chooseAvatar => 'Scegli un avatar';
	@override String get errorLoading => 'Errore di caricamento';
}

// Path: feasibility
class _Translations$feasibility$it extends Translations$feasibility$fr {
	_Translations$feasibility$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feasibility';
	@override String get subtitle => 'Assess your preparation';
	@override String get previous => 'Previous';
	@override String get restart => 'Start over';
	@override String get resultTitle => 'Your result';
	@override String get weakPointsTitle => 'Areas to improve';
	@override String get strongPointsTitle => 'Strong points';
	@override String get progress => '{current}/{total}';
	@override late final _Translations$feasibility$levels$it levels = _Translations$feasibility$levels$it._(_root);
	@override late final _Translations$feasibility$categories$it categories = _Translations$feasibility$categories$it._(_root);
	@override late final _Translations$feasibility$questions$it questions = _Translations$feasibility$questions$it._(_root);
	@override late final _Translations$feasibility$answers$it answers = _Translations$feasibility$answers$it._(_root);
	@override String get seeRecommendations => 'Vedi raccomandazioni';
	@override String get yourProfile => 'Il vostro profilo';
	@override String get tipsTitle => 'I nostri consigli';
	@override late final _Translations$feasibility$recommendations$it recommendations = _Translations$feasibility$recommendations$it._(_root);
}

// Path: tips
class _Translations$tips$it extends Translations$tips$fr {
	_Translations$tips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Consigli trek';
	@override String get allCategories => 'Tutte';
	@override String get swipeHint => 'Scorri per vedere altro';
	@override String get detailTitle => 'Dettaglio consiglio';
	@override String get readMore => 'Leggi di piu';
	@override String get noTips => 'Nessun consiglio disponibile';
	@override String get categoryPreparation => 'Preparazione';
	@override String get categoryEquipment => 'Attrezzatura';
	@override String get categoryNutrition => 'Nutrizione';
	@override String get categorySafety => 'Sicurezza';
	@override String get categoryNature => 'Natura';
	@override String get categoryRecovery => 'Recupero';
	@override String get categoryGeneral => 'Generale';
	@override String get priorityHigh => 'Priorita alta';
	@override String get scope => 'Sentiero';
	@override String get season => 'Stagione';
	@override String get altitude => 'Altitudine min.';
}

// Path: goodies
class _Translations$goodies$it extends Translations$goodies$fr {
	_Translations$goodies$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Negozio Goodies';
	@override String get comingSoon => 'Questo modulo arrivera presto. Resta connesso!';
}

// Path: noData
class _Translations$noData$it extends Translations$noData$fr {
	_Translations$noData$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nessun sentiero scaricato';
	@override String get subtitle => 'Scarica un sentiero per iniziare';
	@override String get offlineHint => 'I dati saranno disponibili offline per la tua escursione.';
	@override String get browseCta => 'Esplora i sentieri';
}

// Path: catalog
class _Translations$catalog$it extends Translations$catalog$fr {
	_Translations$catalog$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catalogo dei sentieri';
	@override String get enter => 'Entra';
	@override String get mustDownload => 'Scarica questo sentiero per esplorarlo.';
	@override String get emptyTitle => 'Nessun sentiero disponibile';
	@override String get emptySubtitle => 'Nessun sentiero è ancora proposto nel catalogo.';
	@override late final _Translations$catalog$a11y$it a11y = _Translations$catalog$a11y$it._(_root);
}

// Path: updates
class _Translations$updates$it extends Translations$updates$fr {
	_Translations$updates$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get readyTitle => 'Aggiornamento pronto';
	@override String get readyBodyOne => 'Un sentiero è stato aggiornato.';
	@override String readyBodyMany({required Object count}) => '${count} sentieri sono stati aggiornati.';
}

// Path: follow
class _Translations$follow$it extends Translations$follow$fr {
	_Translations$follow$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Localizzazione in diretta';
	@override String get connecting => 'Connessione…';
	@override String get live => 'In diretta';
	@override String get offline => 'Offline';
	@override String get invalidLink => 'Link non valido';
	@override String get invalidLinkHint => 'Questo link di localizzazione non esiste o è scaduto.';
}

// Path: cloud
class _Translations$cloud$it extends Translations$cloud$fr {
	_Translations$cloud$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get localModeTitle => 'Modalità locale';
	@override String get localModeBody => 'Questa installazione non è collegata a un servizio cloud: localizzazione in diretta, backup online e account sono disattivati. I tuoi dati restano sul dispositivo.';
	@override String get statusSection => 'Cloud';
	@override String get statusActive => 'Servizi online attivi';
	@override String get statusActiveDesc => 'Backup e localizzazione in diretta disponibili.';
	@override String get statusLocal => 'Modalità locale (senza cloud)';
	@override String get statusLocalDesc => 'Nessun dato viene inviato online. Configurazione cloud assente.';
}

// Path: onboarding
class _Translations$onboarding$it extends Translations$onboarding$fr {
	_Translations$onboarding$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Salta';
	@override String get next => 'Avanti';
	@override String get getStarted => 'Inizia';
	@override String welcomeTitle({required Object appName}) => 'Benvenuto su ${appName}';
	@override String get welcomeSubtitle => 'Il tuo compagno di trekking offline: mappa, navigazione GPS, pianificazione e diario di trek.';
	@override String get languageTitle => 'Scegli la tua lingua';
	@override String get languageSubtitle => 'Potrai modificarla in qualsiasi momento nelle impostazioni.';
	@override String get downloadTitle => 'Scarica il tuo primo sentiero';
	@override String get downloadSubtitle => 'Sfoglia il catalogo e scarica un sentiero per usarlo completamente offline.';
	@override String get browseCatalog => 'Sfoglia il catalogo';
}

// Path: monetization
class _Translations$monetization$it extends Translations$monetization$fr {
	_Translations$monetization$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get demoBanner => 'Modalità demo — tocca per sbloccare';
	@override String get paywallTitle => 'Sblocca questo trek';
	@override String get paywallBody => 'La modalità gratuita permette di preparare il trek con pubblicità. Il premium sblocca tutto, senza pubblicità.';
	@override String get featureMap => 'Mappa offline + GPS + localizzazione in diretta';
	@override String get featureJournal => 'Diario di viaggio completo';
	@override String get featureDiploma => 'Diploma di fine trek';
	@override String get featureFollowers => '2 follower gratuiti';
	@override String get featureNoAds => 'Zero pubblicità';
	@override String get buyCta => 'Sblocca questo trek';
	@override String buyCtaWithPrice({required Object price}) => 'Sblocca questo trek — ${price} €';
}

// Path: signalement
class _Translations$signalement$it extends Translations$signalement$fr {
	_Translations$signalement$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Segnala';
	@override String get chooseType => 'Cosa vuoi segnalare?';
	@override late final _Translations$signalement$types$it types = _Translations$signalement$types$it._(_root);
	@override String get latencyBanner => 'Salvato. Visibile agli altri escursionisti dopo la sincronizzazione di rete.';
	@override String get confirm => 'Conferma segnalazione';
	@override String get noLocation => 'Posizione GPS non disponibile al momento. Riprova sotto cielo aperto.';
	@override String get savedTitle => 'Segnalazione salvata';
	@override String get savedPendingSync => 'Sarà condivisa appena la rete sarà disponibile.';
	@override String pendingCount({required Object n}) => '${n} in attesa di sincronizzazione';
	@override String get close => 'Chiudi';
}

// Path: hebergement
class _Translations$hebergement$it extends Translations$hebergement$fr {
	_Translations$hebergement$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alloggi nelle vicinanze';
	@override String get facilitatorNote => 'StepWays ti indirizza agli alloggi. La prenotazione avviene sul loro sito: nessun pagamento nell\'app.';
	@override String detourAR({required Object km}) => 'Deviazione andata e ritorno: ${km} km';
	@override String get openSite => 'Vedi il sito';
	@override String get cannotOpen => 'Impossibile aprire questo link su questo dispositivo.';
	@override String get empty => 'Nessun alloggio elencato nelle vicinanze per ora.';
	@override late final _Translations$hebergement$types$it types = _Translations$hebergement$types$it._(_root);
}

// Path: training
class _Translations$training$it extends Translations$training$fr {
	_Translations$training$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparazione fisica';
	@override String get localNotice => 'Il tuo programma è calcolato e conservato sul telefono. I promemoria sono notifiche locali, senza tracciamento.';
	@override String get reminderTitle => 'Sessione di allenamento oggi';
	@override String get scheduleReminders => 'Programma i promemoria';
	@override String remindersScheduled({required Object n}) => '${n} promemoria programmato/i';
	@override String week({required Object n}) => 'Settimana ${n}';
	@override String minutes({required Object n}) => '${n} min';
	@override String progress({required Object done, required Object total}) => '${done}/${total} sessioni completate';
	@override late final _Translations$training$types$it types = _Translations$training$types$it._(_root);
	@override late final _Translations$training$intensity$it intensity = _Translations$training$intensity$it._(_root);
}

// Path: eta
class _Translations$eta$it extends Translations$eta$fr {
	_Translations$eta$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tempo stimato';
	@override String get toNextWaypoint => 'Prossimo punto';
	@override String get toStageEnd => 'Fine tappa';
	@override String get confidenceHigh => 'Stima affidabile';
	@override String get confidenceLow => 'Approssimativo (GPS debole)';
	@override String durationHm({required Object h, required Object m}) => '${h} h ${m} min';
	@override String durationM({required Object m}) => '${m} min';
}

// Path: leaderboard
class _Translations$leaderboard$it extends Translations$leaderboard$fr {
	_Translations$leaderboard$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Re della tappa';
	@override String get unavailable => 'Classifica non disponibile al momento.';
	@override String get empty => 'Nessuna classifica per questo segmento. Sii il primo a percorrerlo!';
	@override String get pseudonymNotice => 'Classifica per fascia, con pseudonimi. Nessun dato personale diretto viene mostrato.';
	@override String trancheLabel({required Object tranche}) => 'Fascia: ${tranche}';
	@override String get notEnoughParticipants => 'Partecipanti insufficienti per pubblicare questa classifica.';
	@override String entrySemantics({required Object rank, required Object pseudonym, required Object time}) => 'Posizione ${rank}, ${pseudonym}, tempo ${time}';
}

// Path: social
class _Translations$social$it extends Translations$social$fr {
	_Translations$social$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get feedTitle => 'Diario attività';
	@override String get empty => 'Nessuna attività al momento.';
	@override String get kudos => 'Incoraggia';
	@override String kudosCount({required Object n}) => '${n} incoraggiamenti';
	@override String get report => 'Segnala';
	@override String get reportTitle => 'Segnala questo post';
	@override String get reportReasonLabel => 'Motivo della segnalazione';
	@override String get reasonSpam => 'Spam o pubblicità';
	@override String get reasonAbuse => 'Contenuto offensivo o di odio';
	@override String get reasonOther => 'Altro';
	@override String get reportSend => 'Invia segnalazione';
	@override String get reportSent => 'Segnalazione inviata. Il nostro team la esaminerà.';
	@override String get syncPending => 'In attesa di sincronizzazione';
	@override String get synced => 'Sincronizzato';
	@override String get activitySegment => 'ha completato un segmento';
	@override String get activityBadge => 'ha ottenuto un distintivo';
	@override String get activityDefi => 'ha fatto progressi in una sfida';
}

// Path: gamification
class _Translations$gamification$it extends Translations$gamification$fr {
	_Translations$gamification$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get galleryTitle => 'I miei distintivi';
	@override String get obtained => 'Ottenuto';
	@override String get locked => 'Bloccato';
	@override String get tierDebutant => 'Principiante';
	@override String get tierExpert => 'Esperto';
	@override late final _Translations$gamification$badge$it badge = _Translations$gamification$badge$it._(_root);
	@override late final _Translations$gamification$defi$it defi = _Translations$gamification$defi$it._(_root);
}

// Path: shareVisibility
class _Translations$shareVisibility$it extends Translations$shareVisibility$fr {
	_Translations$shareVisibility$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Condivisione e visibilità';
	@override String get intro => 'Per impostazione predefinita, non viene condiviso nulla. Attiva qui sotto, finalità per finalità, ciò che vuoi rendere visibile.';
	@override String get consentLink => 'Gestisci il mio consenso (privacy)';
	@override String get stageResults => 'Condividi i miei risultati di tappa';
	@override String get stageResultsDesc => 'Una scheda con pseudonimo (senza dati personali diretti).';
	@override String get leaderboard => 'Apparire nelle classifiche';
	@override String get leaderboardDesc => 'Classifica per fascia, con uno pseudonimo.';
	@override String get activityFeed => 'Pubblica nel diario attività';
	@override String get activityFeedDesc => 'Le tue attività appaiono nel diario, con uno pseudonimo.';
	@override String get shareTitle => 'Condividi questa tappa';
	@override String get shareButton => 'Condividi';
	@override String get privateNotice => 'La condivisione è disattivata. Attivala in Condivisione e visibilità.';
	@override String get shared => 'Scheda pronta da condividere.';
}

// Path: waypoints
class _Translations$waypoints$it extends Translations$waypoints$fr {
	_Translations$waypoints$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$waypoints$types$it types = _Translations$waypoints$types$it._(_root);
	@override late final _Translations$waypoints$filters$it filters = _Translations$waypoints$filters$it._(_root);
	@override late final _Translations$waypoints$detail$it detail = _Translations$waypoints$detail$it._(_root);
	@override late final _Translations$waypoints$freshness$it freshness = _Translations$waypoints$freshness$it._(_root);
	@override late final _Translations$waypoints$contribution$it contribution = _Translations$waypoints$contribution$it._(_root);
}

// Path: packs
class _Translations$packs$it extends Translations$packs$fr {
	_Translations$packs$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pacchetti sentiero';
	@override String get subtitle => 'Scarica un pacchetto per camminare 100% offline.';
	@override String get alaCarteNote => 'A la carte: acquista solo il pacchetto che ti serve, nessun abbonamento.';
	@override String size({required Object mo}) => '${mo} MB';
	@override late final _Translations$packs$states$it states = _Translations$packs$states$it._(_root);
	@override late final _Translations$packs$actions$it actions = _Translations$packs$actions$it._(_root);
	@override late final _Translations$packs$progress$it progress = _Translations$packs$progress$it._(_root);
	@override late final _Translations$packs$delete$it delete = _Translations$packs$delete$it._(_root);
	@override String get empty => 'Nessun pacchetto disponibile per questo sentiero.';
	@override late final _Translations$packs$a11y$it a11y = _Translations$packs$a11y$it._(_root);
	@override late final _Translations$packs$types$it types = _Translations$packs$types$it._(_root);
}

// Path: guides
class _Translations$guides$it extends Translations$guides$fr {
	_Translations$guides$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guide delle città';
	@override String get subtitle => 'Info pratiche su città e paesi, consultabili offline.';
	@override String sectionsCount({required Object n}) => '${n} sezioni pratiche';
	@override String get empty => 'Nessuna guida disponibile per questo sentiero.';
	@override String get noItems => 'Ancora nessuna informazione in questa sezione.';
	@override String get facilitatorNote => 'StepWays ti indirizza ai fornitori. Prenotazione e pagamento avvengono sul loro sito: niente nell\'app.';
	@override String get openSite => 'Apri il sito';
	@override String get cannotOpen => 'Impossibile aprire questo link su questo dispositivo.';
	@override late final _Translations$guides$categories$it categories = _Translations$guides$categories$it._(_root);
	@override late final _Translations$guides$intro$it intro = _Translations$guides$intro$it._(_root);
	@override late final _Translations$guides$a11y$it a11y = _Translations$guides$a11y$it._(_root);
}

// Path: health
class _Translations$health$it extends Translations$health$fr {
	_Translations$health$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Informazioni sanitarie';
	@override String get privacyBanner => 'Questi dati restano sul tuo telefono. Non vengono mai inviati su internet.';
	@override late final _Translations$health$field$it field = _Translations$health$field$it._(_root);
	@override late final _Translations$health$hint$it hint = _Translations$health$hint$it._(_root);
	@override String get save => 'Salva';
	@override String get saving => 'Salvataggio…';
	@override String get saved => 'Informazioni salvate';
	@override String get emergencyHint => 'In caso di emergenza, mostra questa schermata ai soccorsi.';
	@override String get entryTitle => 'Le mie info sanitarie';
	@override String get entrySubtitle => 'Da mostrare ai soccorsi (restano sul telefono)';
	@override late final _Translations$health$a11y$it a11y = _Translations$health$a11y$it._(_root);
}

// Path: trailSelection
class _Translations$trailSelection$it extends Translations$trailSelection$fr {
	_Translations$trailSelection$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cambia sentiero';
	@override String get subtitle => 'Scegli il sentiero da esplorare. Tutta l app (mappa, tappe, punti di interesse, pacchetti, guide) segue la tua selezione.';
	@override String get current => 'Sentiero attivo';
	@override String get select => 'Scegli questo sentiero';
	@override String get selected => 'Sentiero selezionato';
	@override String stagesDistance({required Object stages, required Object km}) => '${stages} tappe - ${km} km';
	@override late final _Translations$trailSelection$a11y$it a11y = _Translations$trailSelection$a11y$it._(_root);
}

// Path: consent
class _Translations$consent$it extends Translations$consent$fr {
	_Translations$consent$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get onboardingTitle => 'La tua privacy, la tua scelta';
	@override String get onboardingIntro => 'Nulla è attivato per impostazione predefinita. Scegli, finalità per finalità, ciò che autorizzi. Potrai modificare tutto in qualsiasi momento nelle impostazioni.';
	@override String get settingsTitle => 'Privacy e consenso';
	@override String get settingsIntro => 'Gestisci qui ogni autorizzazione. Puoi revocare un consenso in qualsiasi momento, senza conseguenze sul resto.';
	@override String get settingsEntry => 'Privacy e consenso';
	@override String get settingsEntryDesc => 'Gestire le mie autorizzazioni (posizione, condivisione, salute)';
	@override late final _Translations$consent$purposes$it purposes = _Translations$consent$purposes$it._(_root);
	@override String get healthBadge => 'Dato sensibile';
	@override String get healthWarning => 'La frequenza cardiaca è un dato sulla salute (articolo 9 del GDPR). Questo consenso è richiesto separatamente e non viene mai raggruppato con gli altri. I tuoi dati sulla salute non vengono inviati ai nostri server.';
	@override String get granted => 'Autorizzato';
	@override String get denied => 'Non autorizzato';
	@override String get grant => 'Autorizza';
	@override String get revoke => 'Revoca';
	@override String decidedOn({required Object date}) => 'Scelto il ${date}';
	@override String get notDecided => 'In attesa della tua scelta';
	@override String get acceptSelected => 'Conferma le mie scelte';
	@override String get declineAll => 'Rifiuta tutto';
	@override String get continueLabel => 'Continua';
	@override String get privacyPolicyLink => 'Leggi l\'informativa sulla privacy';
	@override String get reviewNeeded => 'La nostra politica è cambiata: rivedi le tue scelte.';
	@override late final _Translations$consent$a11y$it a11y = _Translations$consent$a11y$it._(_root);
}

// Path: moderation
class _Translations$moderation$it extends Translations$moderation$fr {
	_Translations$moderation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get reportTitle => 'Segnala questo contenuto';
	@override String get reportIntro => 'Aiutaci a mantenere sana la community. Indica perché questo contenuto ti sembra illecito. La tua segnalazione sarà esaminata da un moderatore.';
	@override String get reasonLabel => 'Motivo della segnalazione';
	@override late final _Translations$moderation$reasons$it reasons = _Translations$moderation$reasons$it._(_root);
	@override String get detailsLabel => 'Aggiungi dettagli (facoltativo)';
	@override String get detailsHint => 'Aggiungi un commento per aiutare il moderatore.';
	@override String get contactLabel => 'Il tuo indirizzo e-mail';
	@override String get contactHint => 'Per tenerti informato sulla gestione (articolo 16).';
	@override String get goodFaithLabel => 'Dichiaro in buona fede che queste informazioni sono esatte.';
	@override String get submit => 'Invia segnalazione';
	@override String get submitting => 'Invio in corso…';
	@override String get sent => 'Segnalazione inviata. Grazie, un moderatore la esaminerà.';
	@override String get errorRequired => 'Compila il motivo, la tua e-mail e la dichiarazione di buona fede.';
	@override String get errorGeneric => 'Impossibile inviare la segnalazione. Riprova.';
	@override String get cancel => 'Annulla';
	@override String get reasonsTitle => 'Perché questo contenuto è stato limitato?';
	@override String get reasonsIntro => 'In conformità all\'articolo 17, ecco il motivo della decisione di moderazione relativa al tuo contenuto.';
	@override String get decisionLabel => 'Decisione';
	@override late final _Translations$moderation$decisions$it decisions = _Translations$moderation$decisions$it._(_root);
	@override String get noStatement => 'Nessuna restrizione è stata applicata ai tuoi contenuti.';
	@override String get complaintAction => 'Contestare questa decisione';
	@override String get complaintTitle => 'Contestare una decisione';
	@override String get complaintIntro => 'Puoi contestare una decisione di moderazione. Spiega perché ritieni la decisione ingiustificata (articolo 20).';
	@override String get complaintExposeLabel => 'La tua contestazione';
	@override String get complaintExposeHint => 'Descrivi i motivi della tua contestazione.';
	@override String get complaintSubmit => 'Invia contestazione';
	@override String get complaintSent => 'Contestazione registrata. Sarà esaminata.';
	@override String get complaintEmpty => 'Spiega la tua contestazione.';
	@override late final _Translations$moderation$a11y$it a11y = _Translations$moderation$a11y$it._(_root);
}

// Path: bootstrap
class _Translations$bootstrap$it extends Translations$bootstrap$fr {
	_Translations$bootstrap$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Preparazione della tua escursione…';
}

// Path: recap
class _Translations$recap$it extends Translations$recap$fr {
	_Translations$recap$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'La mia avventura';
	@override String get lockedTitle => 'Disponibile alla fine del trek';
	@override String get lockedMessage => 'Termina o abbandona il tuo percorso per rivedere il riepilogo della tua avventura.';
	@override String get finisherTitle => 'Congratulazioni!';
	@override String get finisherSubtitle => 'Hai completato il tuo percorso';
	@override String get partialTitle => 'Il tuo percorso parziale';
	@override String get partialSubtitle => 'La tua avventura resta registrata';
	@override String get statsSection => 'Statistiche';
	@override String get traceSection => 'La tua traccia';
	@override String get noTrace => 'Nessuna traccia GPS disponibile';
	@override String get stages => '{done} / {total} tappe percorse';
	@override String get distance => '{km} km percorsi';
	@override String get elevation => '{meters} m di dislivello positivo';
	@override String get duration => '{days} giorni';
	@override String get dates => 'Dal {start} al {end}';
	@override String get viewDiploma => 'Vedi il mio diploma';
	@override String get noData => 'Nessun dato di percorso da mostrare al momento.';
}

// Path: programme
class _Translations$programme$it extends Translations$programme$fr {
	_Translations$programme$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programma';
	@override String get helpTooltip => 'Aiuto';
	@override late final _Translations$programme$stats$it stats = _Translations$programme$stats$it._(_root);
	@override late final _Translations$programme$legend$it legend = _Translations$programme$legend$it._(_root);
	@override String get restDay => 'Giorno di riposo';
	@override String get restDayLabel => 'R';
	@override late final _Translations$programme$actions$it actions = _Translations$programme$actions$it._(_root);
	@override late final _Translations$programme$mergeBlocked$it mergeBlocked = _Translations$programme$mergeBlocked$it._(_root);
	@override String get replan => 'Ripianifica';
	@override String get replanButton => 'RIPIANIFICA';
	@override late final _Translations$programme$replanDialog$it replanDialog = _Translations$programme$replanDialog$it._(_root);
	@override String get validate => 'CONFERMA IL MIO PROGRAMMA';
	@override late final _Translations$programme$empty$it empty = _Translations$programme$empty$it._(_root);
	@override late final _Translations$programme$info$it info = _Translations$programme$info$it._(_root);
}

// Path: calendar
class _Translations$calendar$it extends Translations$calendar$fr {
	_Translations$calendar$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Calendario';
	@override String get validate => 'CONFERMA LE DATE';
	@override String get departure => 'PARTENZA';
	@override String get arrival => 'ARRIVO';
	@override String get chooseDate => 'Scegli una data';
	@override String get chooseDateAction => 'SCEGLI UNA DATA';
	@override String get previousMonth => 'Mese precedente';
	@override String get nextMonth => 'Mese successivo';
	@override String get dayLabel => 'G{n}';
	@override String get restDayLabel => 'R';
	@override String get adjustStages => 'REGOLA LE TAPPE';
	@override String get stageSingular => 'Tappa {n}';
	@override String get stagesPlural => 'Tappe {list}';
	@override String get splitStages => 'Separa le tappe';
	@override String get mergeWithNext => 'Unisci al giorno successivo';
	@override late final _Translations$calendar$weekdays$it weekdays = _Translations$calendar$weekdays$it._(_root);
	@override late final _Translations$calendar$legend$it legend = _Translations$calendar$legend$it._(_root);
	@override late final _Translations$calendar$summary$it summary = _Translations$calendar$summary$it._(_root);
	@override late final _Translations$calendar$noDate$it noDate = _Translations$calendar$noDate$it._(_root);
	@override late final _Translations$calendar$empty$it empty = _Translations$calendar$empty$it._(_root);
}

// Path: nuitees
class _Translations$nuitees$it extends Translations$nuitees$fr {
	_Translations$nuitees$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pernottamenti';
	@override String get guideTooltip => 'Guida ai pernottamenti';
	@override String get infoBar => 'Prenota ogni notte in anticipo in alta stagione';
	@override late final _Translations$nuitees$types$it types = _Translations$nuitees$types$it._(_root);
	@override late final _Translations$nuitees$guide$it guide = _Translations$nuitees$guide$it._(_root);
	@override late final _Translations$nuitees$card$it card = _Translations$nuitees$card$it._(_root);
	@override late final _Translations$nuitees$summary$it summary = _Translations$nuitees$summary$it._(_root);
	@override late final _Translations$nuitees$empty$it empty = _Translations$nuitees$empty$it._(_root);
}

// Path: hub.trekCard
class _Translations$hub$trekCard$it extends Translations$hub$trekCard$fr {
	_Translations$hub$trekCard$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get activeTitle => 'Trek in corso';
	@override String get distanceCovered => 'Distanza percorsa';
	@override String get elevationGain => 'Dislivello di oggi';
	@override String get duration => 'Tempo di cammino';
	@override String progressLabel({required Object percent}) => '${percent} % del sentiero';
	@override String get resume => 'Riprendi la navigazione';
	@override String get noTrekTitle => 'Pronto a partire?';
	@override String get noTrekBody => 'Pianifica il tuo itinerario, poi avvia il trek quando sei pronto.';
	@override String get plan => 'Pianifica il mio trek';
}

// Path: hub.weather
class _Translations$hub$weather$it extends Translations$hub$weather$fr {
	_Translations$hub$weather$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meteo di oggi';
	@override String get stub => 'Il meteo della tua tappa arriva presto.';
	@override String get unavailable => 'Meteo non disponibile al momento.';
	@override String get alertStorm => 'Allerta temporale';
	@override String tempRange({required Object min, required Object max}) => '${min}° / ${max}°';
}

// Path: hub.sections
class _Translations$hub$sections$it extends Translations$hub$sections$fr {
	_Translations$hub$sections$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get prepare => 'Preparare';
	@override String get hike => 'Camminare';
	@override String get info => 'Informazioni';
	@override String get after => 'Dopo il trek';
}

// Path: hub.cards
class _Translations$hub$cards$it extends Translations$hub$cards$fr {
	_Translations$hub$cards$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get feasibility => 'Fattibilità';
	@override String get feasibilitySub => 'Valuta il tuo livello';
	@override String get itinerary => 'Itinerario';
	@override String get itinerarySub => 'Le tue tappe in dettaglio';
	@override String get programme => 'Programma';
	@override String get programmeSub => 'Distribuisci le tappe';
	@override String get calendar => 'Calendario';
	@override String get calendarSub => 'Scegli le date';
	@override String get nuitees => 'Pernottamenti';
	@override String get nuiteesSub => 'Prenota le tue notti';
	@override String get checklist => 'Attrezzatura & Zaino';
	@override String get checklistSub => 'Prepara il tuo zaino';
	@override String get training => 'Preparazione fisica';
	@override String get trainingSub => 'Il tuo programma di allenamento';
	@override String get offline => 'Scopri i sentieri';
	@override String get offlineSub => 'Sfoglia il catalogo';
	@override String get group => 'Il mio gruppo';
	@override String get groupSub => 'Segui i tuoi compagni';
	@override String get navigation => 'Navigazione';
	@override String get navigationSub => 'Mappa e tracciamento GPS';
	@override String get journal => 'Diario';
	@override String get journalSub => 'Le tue note e i ricordi';
	@override String get accommodations => 'Alloggi';
	@override String get accommodationsSub => 'Dove dormire nelle vicinanze';
	@override String get tips => 'Schede consigli';
	@override String get tipsSub => 'I nostri consigli trek';
	@override String get townGuides => 'Guide delle città';
	@override String get townGuidesSub => 'Info pratiche delle tappe';
	@override String get recap => 'Riepilogo';
	@override String get recapSub => 'La tua avventura in sintesi';
	@override String get diploma => 'Diploma';
	@override String get diplomaSub => 'Il tuo certificato finale';
}

// Path: hub.fab
class _Translations$hub$fab$it extends Translations$hub$fab$fr {
	_Translations$hub$fab$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get feedback => 'Lascia un feedback';
	@override String get sos => 'SOS';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$it extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Facile';
	@override String get moderate => 'Moderato';
	@override String get hard => 'Difficile';
	@override String get expert => 'Esperto';
	@override String get extreme => 'Estremo';
}

// Path: stage.waterSources
class _Translations$stage$waterSources$it extends Translations$stage$waterSources$fr {
	_Translations$stage$waterSources$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Punti d\'acqua';
	@override String get count => '{n} sorgente/i';
	@override String get none => 'Nessun punto d\'acqua segnalato su questa tappa. Portate almeno 3 L a persona.';
}

// Path: stage.accommodation
class _Translations$stage$accommodation$it extends Translations$stage$accommodation$fr {
	_Translations$stage$accommodation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alloggi';
	@override String get none => 'Nessun alloggio segnalato su questa tappa.';
}

// Path: stage.advice
class _Translations$stage$advice$it extends Translations$stage$advice$fr {
	_Translations$stage$advice$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consigli';
	@override String get waterScarce => 'Pochi punti d\'acqua: partite con almeno 2,5 L.';
	@override String get waterAmple => 'Riempite le borracce a ogni punto d\'acqua incontrato.';
	@override String get hardStage => 'Tappa tecnica: partite presto per evitare il caldo e i temporali del pomeriggio.';
	@override String get earlyStart => 'Partenza consigliata prima delle 8 per approfittare del fresco mattutino.';
	@override String get bigClimb => 'Forte dislivello positivo: dosate lo sforzo e fate pause regolari.';
}

// Path: accommodation.types
class _Translations$accommodation$types$it extends Translations$accommodation$types$fr {
	_Translations$accommodation$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Rifugio';
	@override String get bergerie => 'Ovile';
	@override String get gite => 'Ostello';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campeggio';
	@override String get bivouac => 'Bivacco';
}

// Path: checklist.categories
class _Translations$checklist$categories$it extends Translations$checklist$categories$fr {
	_Translations$checklist$categories$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get carrying => 'Zaino & trasporto';
	@override String get sleeping => 'Riposo';
	@override String get clothing => 'Abbigliamento';
	@override String get cooking => 'Cucina';
	@override String get foodWater => 'Cibo & Acqua';
	@override String get hygiene => 'Igiene';
	@override String get firstAid => 'Kit di primo soccorso';
	@override String get electronics => 'Elettronica';
	@override String get women => 'Donna';
	@override String get men => 'Uomo';
	@override String get misc => 'Varie';
	@override String get dog => 'Cane';
}

// Path: checklist.items
class _Translations$checklist$items$it extends Translations$checklist$items$fr {
	_Translations$checklist$items$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Zaino 35-45L';
	@override String get rainCover => 'Coprizaino antipioggia';
	@override String get dryBags => 'Sacche stagne (dry bags)';
	@override String get sleepingBag => 'Sacco a pelo (0-5C)';
	@override String get sleepingPad => 'Materassino / stuoia';
	@override String get sleepingLiner => 'Lenzuolo per sacco a pelo';
	@override String get pillow => 'Cuscino gonfiabile';
	@override String get hikingPants => 'Pantaloni da trekking';
	@override String get rainPants => 'Pantaloni antipioggia';
	@override String get shorts => 'Pantaloncini';
	@override String get techTshirt => 'Maglietta tecnica';
	@override String get fleece => 'Pile / piumino leggero';
	@override String get rainJacket => 'Giacca impermeabile Gore-Tex';
	@override String get underwear => 'Biancheria intima';
	@override String get hikingSocks => 'Calze da trekking';
	@override String get gaiters => 'Ghette';
	@override String get hat => 'Cappello / berretto';
	@override String get beanie => 'Berretto di lana';
	@override String get buff => 'Buff / scaldacollo';
	@override String get lightGloves => 'Guanti leggeri';
	@override String get hikingBoots => 'Scarponi (indossati)';
	@override String get campSandals => 'Sandali da bivacco';
	@override String get stove => 'Fornello (PocketRocket)';
	@override String get gasCanister => 'Cartuccia gas';
	@override String get cookpot => 'Pentolino / gavetta';
	@override String get cutlery => 'Posate (cucchiaio, coltello)';
	@override String get waterBottle => 'Borraccia / sacca 2L';
	@override String get knife => 'Coltello pieghevole';
	@override String get lighter => 'Accendino';
	@override String get energyBars => 'Barretta energetica';
	@override String get driedFruits => 'Frutta secca';
	@override String get freezeDriedMeal => 'Pasto liofilizzato';
	@override String get waterPurification => 'Pastiglie depurazione acqua';
	@override String get electrolytes => 'Elettroliti';
	@override String get carriedWater => 'Acqua trasportata (1L = 1000g)';
	@override String get soap => 'Sapone biodegradabile';
	@override String get toothbrush => 'Spazzolino da denti';
	@override String get toothpaste => 'Dentifricio';
	@override String get microfiberTowel => 'Asciugamano in microfibra';
	@override String get toiletPaper => 'Carta igienica';
	@override String get trashBag => 'Sacco della spazzatura';
	@override String get antiChafingCream => 'Crema anti-sfregamento';
	@override String get earplugs => 'Tappi per orecchie';
	@override String get bandages => 'Cerotti assortiti';
	@override String get sterileCompresses => 'Compresse sterili';
	@override String get elasticBandage => 'Benda elastica';
	@override String get disinfectant => 'Disinfettante (50ml)';
	@override String get painkillers => 'Paracetamolo / Ibuprofene';
	@override String get sunscreen => 'Crema solare SPF50';
	@override String get lipBalm => 'Burrocacao SPF30';
	@override String get emergencyBlanket => 'Coperta di sopravvivenza';
	@override String get tickRemover => 'Leva-zecche';
	@override String get whistle => 'Fischietto di emergenza';
	@override String get strapping => 'Cerotto elastico / strapping';
	@override String get eyeDrops => 'Collirio';
	@override String get antiDiarrheal => 'Antidiarroico';
	@override String get antihistamine => 'Antistaminico';
	@override String get kneeTape => 'Tape per ginocchia';
	@override String get phone => 'Telefono';
	@override String get powerBank => 'Power bank 20000mAh';
	@override String get usbCable => 'Cavo USB';
	@override String get headlamp => 'Lampada frontale';
	@override String get spareBatteries => 'Batterie di ricambio';
	@override String get periodProtection => 'Protezioni mestruali';
	@override String get sportsBra => 'Reggiseno sportivo';
	@override String get intimateWipes => 'Salviette intime';
	@override String get peeCloth => 'Pee-cloth';
	@override String get razor => 'Rasoio';
	@override String get techBoxers => 'Boxer tecnici';
	@override String get hikingPoles => 'Bastoncini da trekking (portati)';
	@override String get sunglasses => 'Occhiali da sole';
	@override String get trailMap => 'Cartina / guida topo';
	@override String get spareLaces => 'Lacci di ricambio';
	@override String get needleThread => 'Ago + filo';
	@override String get ductTape => 'Nastro adesivo';
	@override String get ziplocBags => 'Sacchetti ziploc';
	@override String get cord => 'Cordino';
	@override String get cash => 'Contanti';
	@override String get dogBowl => 'Ciotola pieghevole';
	@override String get dogLeash => 'Guinzaglio';
	@override String get dogKibble => 'Crocchette (razione/giorno)';
	@override String get dogBooties => 'Scarpine protettive';
	@override String get dogVaccineBook => 'Libretto vaccinazioni';
	@override String get dogPoopBags => 'Sacchetti igienici';
	@override String get swimsuit => 'Costume da bagno';
}

// Path: checklist.weight
class _Translations$checklist$weight$it extends Translations$checklist$weight$fr {
	_Translations$checklist$weight$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Peso dello zaino';
	@override String get total => 'Peso totale';
	@override String get bodyWeight => 'Peso corporeo:';
	@override String get ratio => 'Rapporto zaino / corpo';
	@override String get perItem => 'Peso per articolo';
	@override String get edit => 'Modifica il peso';
	@override String get grams => 'g';
	@override String get kilograms => 'kg';
	@override String get adviceUltraLight => 'Zaino ultraleggero — ideale per il trekking';
	@override String get adviceLight => 'Zaino ultraleggero — ideale per il trekking';
	@override String get adviceOk => 'Zaino ben bilanciato';
	@override String get adviceHeavy => 'Discreto ma pesante — valuta di alleggerire';
	@override String get adviceTooHeavy => 'Attenzione ginocchia! Alleggerisci lo zaino';
	@override String get adviceDanger => 'Rischio infortunio — alleggerisci subito!';
	@override String get itemWeight => 'Peso dell\'articolo';
	@override String get cancel => 'Annulla';
	@override String get save => 'Salva';
	@override String get gaugeUltraLight => 'Ultraleggero, perfetto!';
	@override String get gaugeOk => 'Bene, bilanciato';
	@override String get gaugeHeavy => 'Discreto ma pesante';
	@override String get gaugeWarn => 'Attenzione ginocchia!';
	@override String get gaugeDanger => 'Rischio infortunio!';
	@override String get percentOfWeight => '{pct}% del peso corporeo';
	@override String get gaugeObjective => 'Obiettivo max: < 15% in rifugio, < 20% in autonomia';
	@override String get itemsChecked => '{checked} / {total} articoli spuntati';
}

// Path: checklist.ui
class _Translations$checklist$ui$it extends Translations$checklist$ui$fr {
	_Translations$checklist$ui$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Attrezzatura & Zaino';
	@override String get requirementRequired => 'Obbligatorio';
	@override String get addItem => 'Aggiungi un articolo';
	@override String get addItemTitle => 'Aggiungi un articolo';
	@override String get fieldName => 'Nome';
	@override String get fieldWeightGrams => 'Peso (grammi)';
	@override String get add => 'Aggiungi';
	@override String get editWeightTitle => 'Modifica il peso';
	@override String get editCustomTitle => 'Modifica articolo personalizzato';
	@override String get modify => 'Modifica';
	@override String get delete => 'Elimina';
	@override String get deleteItemTitle => 'Eliminare questo articolo?';
	@override String get deleteItemBody => 'L\'articolo "{name}" sara eliminato definitivamente.';
	@override String get requiredWarnTitle => 'Attrezzatura obbligatoria';
	@override String get requiredWarnBody => 'Questa attrezzatura e obbligatoria per la sicurezza (ispirata al regolamento UTMB). Vuoi davvero rimuoverla?';
	@override String get keep => 'Mantieni';
	@override String get removeAnyway => 'Rimuovi comunque';
	@override String get reduceQuantity => 'Riduci quantita';
	@override String get increaseQuantity => 'Aumenta quantita';
	@override String get addToShoppingList => 'Aggiungi alla lista della spesa';
	@override String get removeFromShoppingList => 'Rimuovi dalla lista';
	@override String get help => 'Aiuto';
	@override String get shoppingListTitle => 'Lista della spesa';
	@override String get shoppingListEmpty => 'La tua lista della spesa e vuota. Aggiungi articoli con il pulsante carrello.';
	@override String get shoppingToBuy => 'Da comprare';
	@override String get shoppingPurchased => 'Gia comprato';
	@override String get share => 'CONDIVIDI';
	@override String get infoTitle => 'Attrezzatura & Zaino';
	@override String get infoCheckTitle => 'Spunta gli articoli';
	@override String get infoCheckBody => 'Spunta cio che porti — il peso si ricalcola in alto.';
	@override String get infoRequiredTitle => 'Obbligatori';
	@override String get infoRequiredBody => 'Articoli con lucchetto = regolamento (fischietto, lampada, coperta di sopravvivenza).';
	@override String get infoGaugeTitle => 'Indicatore peso';
	@override String get infoGaugeBody => 'Obiettivo: zaino < 15% del tuo peso. Verde = OK, Arancione = attenzione, Rosso = troppo pesante.';
	@override String get infoAddTitle => 'Aggiungi';
	@override String get infoAddBody => 'Il pulsante + in fondo a ogni categoria per i tuoi articoli.';
	@override String get infoValidateBody => 'Conferma quando lo zaino e pronto — un segno di spunta appare sulla home.';
	@override String get infoUnderstood => 'Capito!';
	@override String get prepTitle => 'Preparazione dello zaino';
	@override String get prepCounter => '{prepared} / {total} articoli preparati';
	@override String get prepAllReady => 'Tutto pronto! Buon trekking';
	@override String get preDepartureTitle => 'Checklist prima della partenza';
	@override String get preDepartureCounter => '{checked}/{total} verificati';
	@override String get preDep1 => 'Controllare il meteo dei prossimi giorni';
	@override String get preDep2 => 'Caricare telefono + power bank';
	@override String get preDep3 => 'Avvisare una persona cara del tuo itinerario';
	@override String get preDep4 => 'Verificare che lo zaino sia ben chiuso e impermeabile';
	@override String get preDep5 => 'Riempire le borracce (minimo 2L)';
	@override String get preDep6 => 'Applicare crema solare e anti-sfregamento';
	@override String get preDep7 => 'Controllare lacci e serraggio degli scarponi';
	@override String get preDep8 => 'Scaricare le mappe offline';
	@override String get bagOk => 'ZAINO OK — PRONTO A PARTIRE';
	@override String get validateBag => 'CONFERMA IL MIO ZAINO';
	@override String get cancelValidation => 'ANNULLA LA CONFERMA';
	@override String get shoppingListButton => 'LISTA DELLA SPESA';
	@override String get shareGroup => 'CONDIVIDI CON IL GRUPPO';
	@override String get exportList => 'ESPORTA LA LISTA';
	@override String get bagValidTitle => 'Zaino confermato';
	@override String get bagValidBody => 'Tutti i {total} articoli obbligatori sono nello zaino.\n\nPeso totale: {weight} kg ({pct}% del peso corporeo)\n\nSei sicuro che lo zaino sia pronto?';
	@override String get checkAgain => 'Controlla ancora';
	@override String get yesBagOk => 'Si, zaino OK';
	@override String get bagValidatedSnack => 'Zaino confermato!';
	@override String get validationCancelledSnack => 'Conferma annullata — puoi modificare la tua attrezzatura.';
	@override String get missingTitle => 'Attrezzatura mancante';
	@override String get missingBody => '{checked}/{total} articoli obbligatori spuntati.';
	@override String get missingList => 'Manca:';
	@override String get understood => 'Capito';
	@override String get validateAnyway => 'Conferma comunque';
	@override String get bagValidatedMissingSnack => 'Zaino confermato (con articoli mancanti)!';
	@override String get shareGroupHint => 'Unisciti a un gruppo per condividere la tua checklist.';
}

// Path: weather.source
class _Translations$weather$source$it extends Translations$weather$source$fr {
	_Translations$weather$source$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get api => 'Dati in diretta';
	@override String get cache => 'Dati salvati';
	@override String get offline => 'Non in linea';
	@override String get demo => 'Dati dimostrativi';
}

// Path: weather.recommendation
class _Translations$weather$recommendation$it extends Translations$weather$recommendation$fr {
	_Translations$weather$recommendation$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get ok => 'Condizioni favorevoli';
	@override String get watch => 'Prudenza consigliata';
	@override String get danger => 'Condizioni sfavorevoli';
}

// Path: weather.alert
class _Translations$weather$alert$it extends Translations$weather$alert$fr {
	_Translations$weather$alert$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$weather$alert$storm$it storm = _Translations$weather$alert$storm$it._(_root);
	@override late final _Translations$weather$alert$wind$it wind = _Translations$weather$alert$wind$it._(_root);
	@override late final _Translations$weather$alert$rain$it rain = _Translations$weather$alert$rain$it._(_root);
	@override late final _Translations$weather$alert$snow$it snow = _Translations$weather$alert$snow$it._(_root);
	@override late final _Translations$weather$alert$uv$it uv = _Translations$weather$alert$uv$it._(_root);
	@override late final _Translations$weather$alert$fire$it fire = _Translations$weather$alert$fire$it._(_root);
}

// Path: feasibility.levels
class _Translations$feasibility$levels$it extends Translations$feasibility$levels$fr {
	_Translations$feasibility$levels$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Not recommended';
	@override String get caution => 'Preparation needed';
	@override String get good => 'Feasible';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$it extends Translations$feasibility$categories$fr {
	_Translations$feasibility$categories$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
class _Translations$feasibility$questions$it extends Translations$feasibility$questions$fr {
	_Translations$feasibility$questions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
class _Translations$feasibility$answers$it extends Translations$feasibility$answers$fr {
	_Translations$feasibility$answers$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
class _Translations$feasibility$recommendations$it extends Translations$feasibility$recommendations$fr {
	_Translations$feasibility$recommendations$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$it danger = _Translations$feasibility$recommendations$danger$it._(_root);
	@override late final _Translations$feasibility$recommendations$caution$it caution = _Translations$feasibility$recommendations$caution$it._(_root);
	@override late final _Translations$feasibility$recommendations$good$it good = _Translations$feasibility$recommendations$good$it._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$it excellent = _Translations$feasibility$recommendations$excellent$it._(_root);
}

// Path: catalog.a11y
class _Translations$catalog$a11y$it extends Translations$catalog$a11y$fr {
	_Translations$catalog$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String enterButton({required Object nom}) => 'Entra nel sentiero ${nom}';
}

// Path: signalement.types
class _Translations$signalement$types$it extends Translations$signalement$types$fr {
	_Translations$signalement$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get obstacle => 'Ostacolo sul sentiero';
	@override String get eauASec => 'Punto d\'acqua a secco';
	@override String get danger => 'Pericolo';
}

// Path: hebergement.types
class _Translations$hebergement$types$it extends Translations$hebergement$types$fr {
	_Translations$hebergement$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Rifugio';
	@override String get gite => 'Locanda';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campeggio';
	@override String get chambreHote => 'Bed & breakfast';
}

// Path: training.types
class _Translations$training$types$it extends Translations$training$types$fr {
	_Translations$training$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get marche => 'Camminata';
	@override String get cardio => 'Cardio';
	@override String get renforcement => 'Potenziamento';
}

// Path: training.intensity
class _Translations$training$intensity$it extends Translations$training$intensity$fr {
	_Translations$training$intensity$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get faible => 'Bassa';
	@override String get moderee => 'Moderata';
	@override String get elevee => 'Elevata';
}

// Path: gamification.badge
class _Translations$gamification$badge$it extends Translations$gamification$badge$fr {
	_Translations$gamification$badge$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$gamification$badge$firstStage$it firstStage = _Translations$gamification$badge$firstStage$it._(_root);
	@override late final _Translations$gamification$badge$firstTrek$it firstTrek = _Translations$gamification$badge$firstTrek$it._(_root);
	@override late final _Translations$gamification$badge$firstSegment$it firstSegment = _Translations$gamification$badge$firstSegment$it._(_root);
	@override late final _Translations$gamification$badge$elevation5000$it elevation5000 = _Translations$gamification$badge$elevation5000$it._(_root);
	@override late final _Translations$gamification$badge$tenStages$it tenStages = _Translations$gamification$badge$tenStages$it._(_root);
	@override late final _Translations$gamification$badge$challenger$it challenger = _Translations$gamification$badge$challenger$it._(_root);
}

// Path: gamification.defi
class _Translations$gamification$defi$it extends Translations$gamification$defi$fr {
	_Translations$gamification$defi$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Sfide';
	@override String get inProgress => 'In corso';
	@override String progressLabel({required Object current, required Object target}) => 'Progresso: ${current} / ${target}';
	@override String get rankingTitle => 'Classifica della sfida';
	@override String get pseudonymNotice => 'Classifica per fascia, con pseudonimi. Nessun dato personale diretto viene mostrato.';
	@override String get notEnoughParticipants => 'Partecipanti insufficienti per pubblicare questa classifica.';
	@override String get noDefi => 'Nessuna sfida in corso al momento.';
}

// Path: waypoints.types
class _Translations$waypoints$types$it extends Translations$waypoints$types$fr {
	_Translations$waypoints$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get eau => 'Acqua';
	@override String get ravitaillement => 'Rifornimento';
	@override String get danger => 'Pericolo';
	@override String get camp => 'Campeggio';
	@override String get connectivite => 'Connettivita';
	@override String get jonction => 'Bivio';
}

// Path: waypoints.filters
class _Translations$waypoints$filters$it extends Translations$waypoints$filters$fr {
	_Translations$waypoints$filters$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtra i waypoint';
	@override String get showAll => 'Mostra tutto';
	@override String get hideAll => 'Nascondi tutto';
	@override String get recentConditionOnly => 'Solo condizione recente';
}

// Path: waypoints.detail
class _Translations$waypoints$detail$it extends Translations$waypoints$detail$fr {
	_Translations$waypoints$detail$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get conditionsTitle => 'Condizioni del terreno';
	@override String get noComments => 'Nessuna condizione segnalata per ora.';
	@override String get commentsError => 'Condizioni non disponibili.';
	@override String get report => 'Segnala';
	@override String get reportAck => 'Segnalazione salvata. Sara esaminata dopo la sincronizzazione.';
	@override String get pendingSync => 'In attesa di sincronizzazione';
}

// Path: waypoints.freshness
class _Translations$waypoints$freshness$it extends Translations$waypoints$freshness$fr {
	_Translations$waypoints$freshness$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get justNow => 'aggiornato proprio ora';
	@override String minutes({required Object n}) => 'aggiornato ${n} min fa';
	@override String hours({required Object n}) => 'aggiornato ${n} h fa';
	@override String days({required Object n}) => 'aggiornato ${n} g fa';
}

// Path: waypoints.contribution
class _Translations$waypoints$contribution$it extends Translations$waypoints$contribution$fr {
	_Translations$waypoints$contribution$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titleWaypoint => 'Aggiungi un punto';
	@override String get titleComment => 'Segnala una condizione';
	@override String get chooseType => 'Tipo di punto';
	@override String get titleField => 'Titolo del punto';
	@override String get conditionPrompt => 'Descrivi la condizione osservata';
	@override String get commentField => 'La tua osservazione';
	@override String get conditionField => 'Stato (facoltativo)';
	@override String get conditionHelper => 'es. acqua esaurita, acqua scorre, passaggio scivoloso';
	@override String get latencyBanner => 'Sara pubblicato alla prossima sincronizzazione di rete.';
	@override String get submit => 'Salva';
	@override String get savedTitle => 'Contributo salvato';
	@override String get savedPendingSync => 'Sara pubblicato al ritorno della rete.';
	@override String pendingCount({required Object n}) => '${n} in attesa di sincronizzazione';
	@override String get close => 'Chiudi';
	@override String get emptyTitle => 'Inserisci un titolo per il punto.';
	@override String get emptyComment => 'Inserisci la tua osservazione.';
	@override String get noLocation => 'Posizione GPS non disponibile. Riprova sotto cielo aperto.';
	@override String get error => 'Impossibile salvare in questo momento.';
}

// Path: packs.states
class _Translations$packs$states$it extends Translations$packs$states$fr {
	_Translations$packs$states$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get notDownloaded => 'Non scaricato';
	@override String get downloaded => 'Scaricato';
	@override String get updateAvailable => 'Aggiornamento disponibile';
}

// Path: packs.actions
class _Translations$packs$actions$it extends Translations$packs$actions$fr {
	_Translations$packs$actions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get download => 'Scarica';
	@override String get update => 'Aggiorna';
	@override String get delete => 'Elimina';
	@override String get retry => 'Riprova';
	@override String get buy => 'Acquista questo pacchetto';
	@override String buyWithPrice({required Object price}) => 'Acquista questo pacchetto — ${price}';
}

// Path: packs.progress
class _Translations$packs$progress$it extends Translations$packs$progress$fr {
	_Translations$packs$progress$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String downloading({required Object done, required Object total}) => 'Scaricamento… ${done}/${total}';
	@override String get verifying => 'Verifica integrità…';
	@override String get completed => 'Pacchetto pronto offline';
	@override String get error => 'Scaricamento non riuscito';
}

// Path: packs.delete
class _Translations$packs$delete$it extends Translations$packs$delete$fr {
	_Translations$packs$delete$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => 'Eliminare questo pacchetto?';
	@override String get confirmBody => 'Il pacchetto verrà rimosso dal dispositivo per liberare spazio. Potrai riscaricarlo in seguito.';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'Elimina';
	@override String get freed => 'Spazio liberato.';
}

// Path: packs.a11y
class _Translations$packs$a11y$it extends Translations$packs$a11y$fr {
	_Translations$packs$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String packCard({required Object nom, required Object state}) => 'Pacchetto ${nom}, ${state}';
	@override String downloadButton({required Object nom}) => 'Scarica il pacchetto ${nom}';
	@override String deleteButton({required Object nom}) => 'Elimina il pacchetto ${nom}';
}

// Path: packs.types
class _Translations$packs$types$it extends Translations$packs$types$fr {
	_Translations$packs$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override late final _Translations$packs$types$nord$it nord = _Translations$packs$types$nord$it._(_root);
	@override late final _Translations$packs$types$sud$it sud = _Translations$packs$types$sud$it._(_root);
	@override late final _Translations$packs$types$complet$it complet = _Translations$packs$types$complet$it._(_root);
	@override late final _Translations$packs$types$mam$it mam = _Translations$packs$types$mam$it._(_root);
}

// Path: guides.categories
class _Translations$guides$categories$it extends Translations$guides$categories$fr {
	_Translations$guides$categories$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Rifornimento';
	@override String get hebergement => 'Alloggio';
	@override String get transport => 'Trasporti';
	@override String get services => 'Servizi';
	@override String get eau => 'Acqua';
	@override String get sante => 'Salute';
}

// Path: guides.intro
class _Translations$guides$intro$it extends Translations$guides$intro$fr {
	_Translations$guides$intro$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Dove fare scorta di provviste.';
	@override String get hebergement => 'Dove dormire alla tappa.';
	@override String get transport => 'Autobus, navette e collegamenti.';
	@override String get services => 'Posta, banca, lavanderia e altro.';
	@override String get eau => 'Punti d\'acqua potabile.';
	@override String get sante => 'Farmacia e cure nelle vicinanze.';
}

// Path: guides.a11y
class _Translations$guides$a11y$it extends Translations$guides$a11y$fr {
	_Translations$guides$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String guideCard({required Object lieu}) => 'Guida di ${lieu}';
	@override String section({required Object titre}) => 'Sezione ${titre}';
	@override String openSiteButton({required Object nom}) => 'Apri il sito di ${nom}';
}

// Path: health.field
class _Translations$health$field$it extends Translations$health$field$fr {
	_Translations$health$field$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Gruppo sanguigno';
	@override String get allergies => 'Allergie';
	@override String get treatments => 'Terapie in corso';
	@override String get doctor => 'Medico di base';
	@override String get insurance => 'N. assicurazione / mutua';
}

// Path: health.hint
class _Translations$health$hint$it extends Translations$health$hint$fr {
	_Translations$health$hint$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Es. A+, O-, AB+';
	@override String get allergies => 'Es. penicillina, arachidi';
	@override String get treatments => 'Es. Levothyrox 50 mg/giorno';
	@override String get doctor => 'Es. Dr. Rossi +39 06 xxxx xxxx';
	@override String get insurance => 'Es. tessera europea';
}

// Path: health.a11y
class _Translations$health$a11y$it extends Translations$health$a11y$fr {
	_Translations$health$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get form => 'Modulo informazioni sanitarie';
	@override String get saveButton => 'Salva le informazioni sanitarie';
}

// Path: trailSelection.a11y
class _Translations$trailSelection$a11y$it extends Translations$trailSelection$a11y$fr {
	_Translations$trailSelection$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String trailCard({required Object nom, required Object region}) => 'Sentiero ${nom}, ${region}';
	@override String get currentBadge => 'Sentiero attualmente attivo';
	@override String selectButton({required Object nom}) => 'Attiva il sentiero ${nom}';
}

// Path: consent.purposes
class _Translations$consent$purposes$it extends Translations$consent$purposes$fr {
	_Translations$consent$purposes$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get locationNavigation => 'Navigazione personale';
	@override String get locationNavigationDesc => 'Usare la tua posizione per la mappa e il monitoraggio della tappa. Resta sul tuo dispositivo.';
	@override String get socialSharing => 'Condivisione social';
	@override String get socialSharingDesc => 'Apparire nelle classifiche e nel feed della community, sotto pseudonimo.';
	@override String get publicReporting => 'Segnalazioni pubbliche';
	@override String get publicReportingDesc => 'Pubblicare segnalazioni (acqua, pericolo, condizioni) visibili agli altri escursionisti.';
	@override String get healthData => 'Dati sulla salute';
	@override String get healthDataDesc => 'Leggere la tua frequenza cardiaca (fascia o app salute) per arricchire il monitoraggio dello sforzo.';
}

// Path: consent.a11y
class _Translations$consent$a11y$it extends Translations$consent$a11y$fr {
	_Translations$consent$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String purposeToggle({required Object purpose, required Object state}) => '${purpose}, attualmente ${state}';
	@override String get healthSection => 'Sezione dati sulla salute, consenso rafforzato';
	@override String get policyButton => 'Apri l\'informativa sulla privacy';
}

// Path: moderation.reasons
class _Translations$moderation$reasons$it extends Translations$moderation$reasons$fr {
	_Translations$moderation$reasons$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get illegal => 'Contenuto illegale';
	@override String get harassment => 'Molestie o odio';
	@override String get spam => 'Spam o pubblicità';
	@override String get dangerous => 'Informazione pericolosa o ingannevole';
	@override String get other => 'Altro';
}

// Path: moderation.decisions
class _Translations$moderation$decisions$it extends Translations$moderation$decisions$fr {
	_Translations$moderation$decisions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get keep => 'Contenuto mantenuto';
	@override String get restrict => 'Contenuto limitato';
	@override String get remove => 'Contenuto rimosso';
}

// Path: moderation.a11y
class _Translations$moderation$a11y$it extends Translations$moderation$a11y$fr {
	_Translations$moderation$a11y$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get reportForm => 'Modulo di segnalazione del contenuto';
	@override String get reasonSelector => 'Selettore del motivo della segnalazione';
	@override String goodFaithToggle({required Object state}) => 'Dichiarazione di buona fede, ${state}';
	@override String get submitReport => 'Invia segnalazione';
	@override String get statementCard => 'Motivazione della decisione di moderazione';
	@override String get complaintForm => 'Modulo di contestazione della decisione';
}

// Path: programme.stats
class _Translations$programme$stats$it extends Translations$programme$stats$fr {
	_Translations$programme$stats$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distanza';
	@override String get elevation => 'Dislivello+';
	@override String get days => 'Giorni';
	@override String get stages => 'Tappe';
	@override String get restCount => '{count} riposo';
}

// Path: programme.legend
class _Translations$programme$legend$it extends Translations$programme$legend$fr {
	_Translations$programme$legend$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Facile';
	@override String get moderate => 'Moderato';
	@override String get hard => 'Difficile';
	@override String get extreme => 'Estremo';
}

// Path: programme.actions
class _Translations$programme$actions$it extends Translations$programme$actions$fr {
	_Translations$programme$actions$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get merge => 'Raggruppa';
	@override String get split => 'Dividi';
	@override String get rest => 'Riposo';
	@override String get removeRest => 'Rimuovi questo giorno di riposo';
}

// Path: programme.mergeBlocked
class _Translations$programme$mergeBlocked$it extends Translations$programme$mergeBlocked$fr {
	_Translations$programme$mergeBlocked$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get noNext => 'Nessun giorno successivo';
	@override String get rest => 'Impossibile raggruppare con un giorno di riposo';
	@override String get tooLong => 'Troppo lungo: {hours}h (max {max}h/giorno)';
}

// Path: programme.replanDialog
class _Translations$programme$replanDialog$it extends Translations$programme$replanDialog$fr {
	_Translations$programme$replanDialog$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ripianifica';
	@override String get message => 'La ripianificazione azzererà il tuo programma.\nI giorni di riposo saranno mantenuti nelle stesse posizioni.';
	@override String get cancel => 'Annulla';
	@override String get confirm => 'Ripianifica';
}

// Path: programme.empty
class _Translations$programme$empty$it extends Translations$programme$empty$fr {
	_Translations$programme$empty$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura prima il tuo itinerario';
	@override String get message => 'Scegli il percorso e la durata per generare il tuo programma.';
	@override String get action => 'CONFIGURA L\'ITINERARIO';
}

// Path: programme.info
class _Translations$programme$info$it extends Translations$programme$info$fr {
	_Translations$programme$info$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programma';
	@override late final _Translations$programme$info$days$it days = _Translations$programme$info$days$it._(_root);
	@override late final _Translations$programme$info$reorder$it reorder = _Translations$programme$info$reorder$it._(_root);
	@override late final _Translations$programme$info$rest$it rest = _Translations$programme$info$rest$it._(_root);
	@override late final _Translations$programme$info$mergeSplit$it mergeSplit = _Translations$programme$info$mergeSplit$it._(_root);
	@override late final _Translations$programme$info$colors$it colors = _Translations$programme$info$colors$it._(_root);
	@override String get note => 'Il profilo altimetrico in basso mostra il dislivello di ogni giorno.';
	@override String get close => 'Capito!';
}

// Path: calendar.weekdays
class _Translations$calendar$weekdays$it extends Translations$calendar$weekdays$fr {
	_Translations$calendar$weekdays$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get mon => 'Lun';
	@override String get tue => 'Mar';
	@override String get wed => 'Mer';
	@override String get thu => 'Gio';
	@override String get fri => 'Ven';
	@override String get sat => 'Sab';
	@override String get sun => 'Dom';
}

// Path: calendar.legend
class _Translations$calendar$legend$it extends Translations$calendar$legend$fr {
	_Translations$calendar$legend$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get start => 'Partenza';
	@override String get walk => 'Cammino';
	@override String get rest => 'Riposo';
	@override String get arrival => 'Arrivo';
}

// Path: calendar.summary
class _Translations$calendar$summary$it extends Translations$calendar$summary$fr {
	_Translations$calendar$summary$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get totalDays => 'Giorni totali';
	@override String get walkDays => 'Giorni cammino';
	@override String get restDays => 'Giorni riposo';
}

// Path: calendar.noDate
class _Translations$calendar$noDate$it extends Translations$calendar$noDate$fr {
	_Translations$calendar$noDate$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Scegli una data di partenza';
	@override String get message => 'Il calendario del tuo trek apparirà automaticamente con i giorni di cammino e di riposo.';
}

// Path: calendar.empty
class _Translations$calendar$empty$it extends Translations$calendar$empty$fr {
	_Translations$calendar$empty$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura prima il tuo itinerario';
	@override String get message => 'Scegli il percorso e la durata per poter configurare le tue date.';
	@override String get action => 'CONFIGURA L\'ITINERARIO';
}

// Path: nuitees.types
class _Translations$nuitees$types$it extends Translations$nuitees$types$fr {
	_Translations$nuitees$types$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Rifugio';
	@override String get gite => 'Ostello';
	@override String get bivouac => 'Bivacco';
	@override String get autreHebergement => 'Altro alloggio';
}

// Path: nuitees.guide
class _Translations$nuitees$guide$it extends Translations$nuitees$guide$fr {
	_Translations$nuitees$guide$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guida ai pernottamenti';
	@override String get refuge => 'Alloggio di montagna, prenotazione consigliata in alta stagione.';
	@override String get gite => 'Ostello di tappa privato, spesso con pasti e docce.';
	@override String get bivouac => 'Campeggio in tenda, secondo la normativa locale.';
	@override String get autre => 'Hotel, bed and breakfast o campeggio fuori dal sentiero.';
	@override String get close => 'Capito';
}

// Path: nuitees.card
class _Translations$nuitees$card$it extends Translations$nuitees$card$fr {
	_Translations$nuitees$card$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get dayLabel => 'G{n}';
	@override String get noPlace => 'Alloggio';
	@override String get available => '{count} alloggi disponibili';
	@override String get call => 'Chiama {phone}';
	@override String get lockedHint => 'Deseleziona la notte per cambiare il tipo';
}

// Path: nuitees.summary
class _Translations$nuitees$summary$it extends Translations$nuitees$summary$fr {
	_Translations$nuitees$summary$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get remaining => '{count} notte/i rimasta/e';
	@override String get done => '{count} OK';
	@override String get allBooked => 'TUTTE LE NOTTI PRENOTATE';
}

// Path: nuitees.empty
class _Translations$nuitees$empty$it extends Translations$nuitees$empty$fr {
	_Translations$nuitees$empty$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura prima il tuo itinerario';
	@override String get message => 'Scegli percorso e durata per preparare i tuoi pernottamenti.';
	@override String get action => 'CONFIGURA ITINERARIO';
}

// Path: weather.alert.storm
class _Translations$weather$alert$storm$it extends Translations$weather$alert$storm$fr {
	_Translations$weather$alert$storm$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Temporale previsto';
	@override String desc({required Object condition}) => '${condition}. Evita le creste e le zone esposte.';
}

// Path: weather.alert.wind
class _Translations$weather$alert$wind$it extends Translations$weather$alert$wind$fr {
	_Translations$weather$alert$wind$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Vento forte';
	@override String desc({required Object value}) => 'Raffiche fino a ${value} km/h. Prudenza nei passaggi esposti.';
}

// Path: weather.alert.rain
class _Translations$weather$alert$rain$it extends Translations$weather$alert$rain$fr {
	_Translations$weather$alert$rain$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Forti precipitazioni';
	@override String desc({required Object value}) => '${value} mm previsti. Rischio di sentieri scivolosi e torrenti.';
}

// Path: weather.alert.snow
class _Translations$weather$alert$snow$it extends Translations$weather$alert$snow$fr {
	_Translations$weather$alert$snow$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Neve prevista';
	@override String desc({required Object condition}) => '${condition}. Attrezzatura adeguata necessaria.';
}

// Path: weather.alert.uv
class _Translations$weather$alert$uv$it extends Translations$weather$alert$uv$fr {
	_Translations$weather$alert$uv$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'UV molto alto';
	@override String desc({required Object value}) => 'Indice UV ${value}. Massima protezione solare consigliata.';
}

// Path: weather.alert.fire
class _Translations$weather$alert$fire$it extends Translations$weather$alert$fire$fr {
	_Translations$weather$alert$fire$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rischio incendio';
	@override String desc({required Object value}) => '${value}°C previsti. Rischio incendio elevato.';
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$it extends Translations$feasibility$recommendations$danger$fr {
	_Translations$feasibility$recommendations$danger$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparazione insufficiente';
	@override String get summary => 'Il vostro profilo mostra lacune importanti. Sconsigliamo di partire.';
	@override late final _Translations$feasibility$recommendations$danger$tips$it tips = _Translations$feasibility$recommendations$danger$tips$it._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$it extends Translations$feasibility$recommendations$caution$fr {
	_Translations$feasibility$recommendations$caution$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparazione da rafforzare';
	@override String get summary => 'Avete le basi, ma alcuni punti richiedono attenzione.';
	@override late final _Translations$feasibility$recommendations$caution$tips$it tips = _Translations$feasibility$recommendations$caution$tips$it._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$it extends Translations$feasibility$recommendations$good$fr {
	_Translations$feasibility$recommendations$good$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Buona preparazione';
	@override String get summary => 'Il vostro profilo è solido. Qualche aggiustamento e sarete pronti.';
	@override late final _Translations$feasibility$recommendations$good$tips$it tips = _Translations$feasibility$recommendations$good$tips$it._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$it extends Translations$feasibility$recommendations$excellent$fr {
	_Translations$feasibility$recommendations$excellent$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparazione ottimale';
	@override String get summary => 'Siete perfettamente preparati. Godetevi il trekking!';
	@override late final _Translations$feasibility$recommendations$excellent$tips$it tips = _Translations$feasibility$recommendations$excellent$tips$it._(_root);
}

// Path: gamification.badge.firstStage
class _Translations$gamification$badge$firstStage$it extends Translations$gamification$badge$firstStage$fr {
	_Translations$gamification$badge$firstStage$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Prima tappa';
	@override String get description => 'Hai completato la tua prima tappa.';
}

// Path: gamification.badge.firstTrek
class _Translations$gamification$badge$firstTrek$it extends Translations$gamification$badge$firstTrek$fr {
	_Translations$gamification$badge$firstTrek$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Primo trek';
	@override String get description => 'Hai concluso il tuo primo trek completo.';
}

// Path: gamification.badge.firstSegment
class _Translations$gamification$badge$firstSegment$it extends Translations$gamification$badge$firstSegment$fr {
	_Translations$gamification$badge$firstSegment$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Primo segmento';
	@override String get description => 'Hai percorso il tuo primo segmento.';
}

// Path: gamification.badge.elevation5000
class _Translations$gamification$badge$elevation5000$it extends Translations$gamification$badge$elevation5000$fr {
	_Translations$gamification$badge$elevation5000$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => '5000 m di dislivello';
	@override String get description => 'Hai accumulato 5000 m di dislivello positivo.';
}

// Path: gamification.badge.tenStages
class _Translations$gamification$badge$tenStages$it extends Translations$gamification$badge$tenStages$fr {
	_Translations$gamification$badge$tenStages$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => '10 tappe';
	@override String get description => 'Hai completato 10 tappe.';
}

// Path: gamification.badge.challenger
class _Translations$gamification$badge$challenger$it extends Translations$gamification$badge$challenger$fr {
	_Translations$gamification$badge$challenger$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Sfidante';
	@override String get description => 'Hai completato la tua prima sfida stagionale.';
}

// Path: packs.types.nord
class _Translations$packs$types$nord$it extends Translations$packs$types$nord$fr {
	_Translations$packs$types$nord$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Nord';
	@override String get description => 'La metà nord del sentiero, offline.';
}

// Path: packs.types.sud
class _Translations$packs$types$sud$it extends Translations$packs$types$sud$fr {
	_Translations$packs$types$sud$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Sud';
	@override String get description => 'La metà sud del sentiero, offline.';
}

// Path: packs.types.complet
class _Translations$packs$types$complet$it extends Translations$packs$types$complet$fr {
	_Translations$packs$types$complet$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Completo';
	@override String get description => 'Tutto il sentiero, offline.';
}

// Path: packs.types.mam
class _Translations$packs$types$mam$it extends Translations$packs$types$mam$fr {
	_Translations$packs$types$mam$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare';
	@override String get description => 'Il sentiero Mare a Mare, offline.';
}

// Path: programme.info.days
class _Translations$programme$info$days$it extends Translations$programme$info$days$fr {
	_Translations$programme$info$days$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Giorni di trek';
	@override String get body => 'Ogni riga = un giorno. Tocca per vedere il dettaglio completo.';
}

// Path: programme.info.reorder
class _Translations$programme$info$reorder$it extends Translations$programme$info$reorder$fr {
	_Translations$programme$info$reorder$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Riordina';
	@override String get body => 'Trascina la maniglia a destra per cambiare l\'ordine dei giorni.';
}

// Path: programme.info.rest
class _Translations$programme$info$rest$it extends Translations$programme$info$rest$fr {
	_Translations$programme$info$rest$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Giorno di riposo';
	@override String get body => 'Inserisci un giorno di recupero tra due tappe.';
}

// Path: programme.info.mergeSplit
class _Translations$programme$info$mergeSplit$it extends Translations$programme$info$mergeSplit$fr {
	_Translations$programme$info$mergeSplit$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Raggruppa / Dividi';
	@override String get body => 'Unisci o dividi le tappe secondo il tuo ritmo.';
}

// Path: programme.info.colors
class _Translations$programme$info$colors$it extends Translations$programme$info$colors$fr {
	_Translations$programme$info$colors$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colori';
	@override String get body => 'Verde = facile, Arancione = medio, Rosso = difficile (distanza + dislivello).';
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$it extends Translations$feasibility$recommendations$danger$tips$fr {
	_Translations$feasibility$recommendations$danger$tips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Iniziate con escursioni brevi per valutare la condizione';
	@override String get tip2 => 'Consultate un professionista sanitario';
	@override String get tip3 => 'Investite in attrezzatura adeguata e testatela';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$it extends Translations$feasibility$recommendations$caution$tips$fr {
	_Translations$feasibility$recommendations$caution$tips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Rafforzate il vostro allenamento 6-8 settimane prima';
	@override String get tip2 => 'Verificate e completate la vostra attrezzatura';
	@override String get tip3 => 'Pianificate tappe adatte al vostro livello';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$it extends Translations$feasibility$recommendations$good$tips$fr {
	_Translations$feasibility$recommendations$good$tips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Mantenete il ritmo di allenamento';
	@override String get tip2 => 'Prevedete margini nella pianificazione';
	@override String get tip3 => 'Consultate le previsioni meteo regolarmente';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$it extends Translations$feasibility$recommendations$excellent$tips$fr {
	_Translations$feasibility$recommendations$excellent$tips$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Ascoltate il vostro corpo durante il trekking';
	@override String get tip2 => 'Condividete la vostra esperienza';
	@override String get tip3 => 'Documentate la vostra avventura nel diario';
}

/// The flat map containing all translations for locale <it>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsIt {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'a11y.back' => 'Indietro',
			'a11y.zoomIn' => 'Ingrandisci',
			'a11y.zoomOut' => 'Riduci',
			'a11y.centerOnMe' => 'Centra sulla mia posizione',
			'a11y.mapRegion' => 'Mappa del sentiero',
			'a11y.userPosition' => 'La tua posizione',
			'a11y.stageMarker' => ({required Object number}) => 'Tappa ${number}',
			'a11y.poiMarker' => ({required Object name}) => 'Punto di interesse: ${name}',
			'a11y.markerCluster' => ({required Object count}) => '${count} punti raggruppati',
			'a11y.trailCard' => ({required Object name}) => 'Sentiero ${name}',
			'a11y.startTracking' => 'Avvia il monitoraggio',
			'a11y.pauseTracking' => 'Sospendi il monitoraggio',
			'a11y.resumeTracking' => 'Riprendi il monitoraggio',
			'a11y.stopTracking' => 'Ferma il monitoraggio',
			'a11y.sos' => 'Chiamata di emergenza SOS',
			'a11y.mapLayers' => 'Livelli della mappa',
			'nav.accueil' => 'Home',
			'nav.map' => 'Mappa',
			'nav.stages' => 'Tappe',
			'nav.planning' => 'Pianificazione',
			'nav.journal' => 'Diario',
			'nav.more' => 'Altro',
			'nav.checklist' => 'Attrezzatura & Zaino',
			'nav.feasibility' => 'Fattibilità',
			'nav.tips' => 'Consigli trek',
			'nav.emergency' => 'Contatti emergenza',
			'nav.catalog' => 'Catalogo sentieri',
			'nav.profile' => 'Profilo',
			'nav.settings' => 'Impostazioni',
			'nav.trailSelection' => 'Cambia sentiero',
			'branding.tagline' => 'Il tuo compagno di trekking',
			'branding.subline' => 'Prepara, cammina, condividi',
			'hub.greeting' => ({required Object name}) => 'Ciao, ${name}!',
			'hub.greetingFallback' => 'Escursionista',
			'hub.infoTooltip' => 'Info sul sentiero',
			'hub.profileTooltip' => 'Il mio profilo',
			'hub.infoSheetBody' => 'Questo sentiero ti accompagna a ogni passo: pianifica il tuo itinerario, prepara lo zaino e parti con la navigazione GPS. Ogni funzione è raggiungibile da questa schermata iniziale.',
			'hub.trekCard.activeTitle' => 'Trek in corso',
			'hub.trekCard.distanceCovered' => 'Distanza percorsa',
			'hub.trekCard.elevationGain' => 'Dislivello di oggi',
			'hub.trekCard.duration' => 'Tempo di cammino',
			'hub.trekCard.progressLabel' => ({required Object percent}) => '${percent} % del sentiero',
			'hub.trekCard.resume' => 'Riprendi la navigazione',
			'hub.trekCard.noTrekTitle' => 'Pronto a partire?',
			'hub.trekCard.noTrekBody' => 'Pianifica il tuo itinerario, poi avvia il trek quando sei pronto.',
			'hub.trekCard.plan' => 'Pianifica il mio trek',
			'hub.weather.title' => 'Meteo di oggi',
			'hub.weather.stub' => 'Il meteo della tua tappa arriva presto.',
			'hub.weather.unavailable' => 'Meteo non disponibile al momento.',
			'hub.weather.alertStorm' => 'Allerta temporale',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Avvia il trek',
			'hub.sections.prepare' => 'Preparare',
			'hub.sections.hike' => 'Camminare',
			'hub.sections.info' => 'Informazioni',
			'hub.sections.after' => 'Dopo il trek',
			'hub.cards.feasibility' => 'Fattibilità',
			'hub.cards.feasibilitySub' => 'Valuta il tuo livello',
			'hub.cards.itinerary' => 'Itinerario',
			'hub.cards.itinerarySub' => 'Le tue tappe in dettaglio',
			'hub.cards.programme' => 'Programma',
			'hub.cards.programmeSub' => 'Distribuisci le tappe',
			'hub.cards.calendar' => 'Calendario',
			'hub.cards.calendarSub' => 'Scegli le date',
			'hub.cards.nuitees' => 'Pernottamenti',
			'hub.cards.nuiteesSub' => 'Prenota le tue notti',
			'hub.cards.checklist' => 'Attrezzatura & Zaino',
			'hub.cards.checklistSub' => 'Prepara il tuo zaino',
			'hub.cards.training' => 'Preparazione fisica',
			'hub.cards.trainingSub' => 'Il tuo programma di allenamento',
			'hub.cards.offline' => 'Scopri i sentieri',
			'hub.cards.offlineSub' => 'Sfoglia il catalogo',
			'hub.cards.group' => 'Il mio gruppo',
			'hub.cards.groupSub' => 'Segui i tuoi compagni',
			'hub.cards.navigation' => 'Navigazione',
			'hub.cards.navigationSub' => 'Mappa e tracciamento GPS',
			'hub.cards.journal' => 'Diario',
			'hub.cards.journalSub' => 'Le tue note e i ricordi',
			'hub.cards.accommodations' => 'Alloggi',
			'hub.cards.accommodationsSub' => 'Dove dormire nelle vicinanze',
			'hub.cards.tips' => 'Schede consigli',
			'hub.cards.tipsSub' => 'I nostri consigli trek',
			'hub.cards.townGuides' => 'Guide delle città',
			'hub.cards.townGuidesSub' => 'Info pratiche delle tappe',
			'hub.cards.recap' => 'Riepilogo',
			'hub.cards.recapSub' => 'La tua avventura in sintesi',
			'hub.cards.diploma' => 'Diploma',
			'hub.cards.diplomaSub' => 'Il tuo certificato finale',
			'hub.fab.feedback' => 'Lascia un feedback',
			'hub.fab.sos' => 'SOS',
			'map.title' => 'Mappa del sentiero',
			'map.loading' => 'Caricamento del tracciato...',
			'map.noTrack' => 'Nessun tracciato disponibile',
			'map.viewMap' => 'Vedi la mappa',
			'map.layers' => 'Livelli',
			'map.layersTitle' => 'Livelli della mappa',
			'map.layersSubtitle' => 'Scegli cosa mostrare sulla mappa',
			'map.stageRemaining' => ({required Object km}) => '${km} km rimanenti',
			'map.offTrackChip' => 'Fuori traccia',
			'stage.distance' => 'Distanza',
			'stage.elevation' => 'Dislivello',
			'stage.elevationGain' => 'Dislivello positivo',
			'stage.elevationLoss' => 'Dislivello negativo',
			'stage.duration' => 'Durata stimata',
			'stage.description' => 'Descrizione',
			'stage.coordinates' => 'Coordinate',
			'stage.pois' => 'Punti di interesse',
			'stage.difficulty.easy' => 'Facile',
			'stage.difficulty.moderate' => 'Moderato',
			'stage.difficulty.hard' => 'Difficile',
			'stage.difficulty.expert' => 'Esperto',
			'stage.difficulty.extreme' => 'Estremo',
			'stage.remaining' => '{distance} km rimanenti',
			'stage.arrived' => 'Sei arrivato!',
			'stage.altitudeProfile' => 'Profilo altimetrico',
			'stage.statistics' => 'Statistiche',
			'stage.loading' => 'Caricamento...',
			'stage.loadingList' => 'Caricamento delle tappe...',
			'stage.dPlus' => 'D+',
			'stage.dMinus' => 'D-',
			'stage.difficultyLabel' => 'Difficolta',
			'stage.waterSources.title' => 'Punti d\'acqua',
			'stage.waterSources.count' => '{n} sorgente/i',
			'stage.waterSources.none' => 'Nessun punto d\'acqua segnalato su questa tappa. Portate almeno 3 L a persona.',
			'stage.accommodation.title' => 'Alloggi',
			'stage.accommodation.none' => 'Nessun alloggio segnalato su questa tappa.',
			'stage.advice.title' => 'Consigli',
			'stage.advice.waterScarce' => 'Pochi punti d\'acqua: partite con almeno 2,5 L.',
			'stage.advice.waterAmple' => 'Riempite le borracce a ogni punto d\'acqua incontrato.',
			'stage.advice.hardStage' => 'Tappa tecnica: partite presto per evitare il caldo e i temporali del pomeriggio.',
			'stage.advice.earlyStart' => 'Partenza consigliata prima delle 8 per approfittare del fresco mattutino.',
			'stage.advice.bigClimb' => 'Forte dislivello positivo: dosate lo sforzo e fate pause regolari.',
			'trail.stages' => 'Tappe',
			'trail.totalDistance' => 'Distanza totale',
			'trail.totalElevation' => 'Dislivello totale',
			'poi.shelter' => 'Rifugio',
			'poi.water' => 'Fonte d\'acqua',
			'poi.viewpoint' => 'Punto panoramico',
			'poi.campsite' => 'Bivacco',
			'poi.restaurant' => 'Ristorante',
			'poi.emergency' => 'Emergenza',
			'poi.danger' => 'Pericolo',
			'poi.shop' => 'Negozio',
			'poi.filter' => 'Filtra i punti di interesse',
			'poi.altitude' => 'Altitudine',
			'poi.hours' => 'Orari',
			'accommodation.types.refuge' => 'Rifugio',
			'accommodation.types.bergerie' => 'Ovile',
			'accommodation.types.gite' => 'Ostello',
			'accommodation.types.hotel' => 'Hotel',
			'accommodation.types.camping' => 'Campeggio',
			'accommodation.types.bivouac' => 'Bivacco',
			'gps.permission' => 'Autorizzazione GPS richiesta',
			'gps.denied' => 'Accesso alla posizione negato',
			'gps.disabled' => 'Servizio di localizzazione disattivato',
			'gps.offTrack' => 'Fuori tracciato',
			'gps.centerOnMe' => 'Centra sulla mia posizione',
			'navAlert.offTrackBanner' => ({required Object meters}) => 'Ti stai allontanando dal sentiero — ${meters} m. Controlla la tua posizione.',
			'navAlert.offTrackNotifTitle' => 'Stai lasciando il sentiero',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'Ti stai allontanando dal sentiero (${meters} m). Controlla la tua posizione.',
			'planning.title' => 'Pianificazione',
			'planning.duration' => 'Durata',
			'planning.days' => 'giorni',
			'planning.day' => 'Giorno',
			'planning.restDay' => 'Giorno di riposo',
			'planning.totalDistance' => 'Distanza totale',
			'planning.totalElevation' => 'Dislivello totale',
			'planning.estimatedTime' => 'Durata stimata',
			'planning.stages' => 'Tappe',
			'planning.plan' => 'Pianificare',
			'itinerary.title' => 'Itinerario',
			'itinerary.subtitle' => 'Le tue tappe, giorno per giorno',
			'itinerary.empty' => 'Nessuna tappa disponibile',
			'itinerary.emptyHint' => 'I dati del sentiero non sono caricati.',
			'itinerary.loading' => 'Caricamento itinerario...',
			'itinerary.error' => 'Impossibile caricare l\'itinerario',
			'itinerary.day' => 'Giorno',
			'itinerary.stage' => 'Tappa',
			'itinerary.stages' => 'Tappe',
			'itinerary.totalDistance' => 'Distanza',
			'itinerary.totalElevation' => 'D+',
			'itinerary.restDay' => 'Giorno di riposo',
			'itinerary.viewStage' => 'Vedi tappa',
			'itinerary.openMap' => 'Vedi sulla mappa',
			'itinerary.stageCount' => '{count} tappe',
			'tracking.start' => 'Avvia',
			'tracking.pause' => 'Pausa',
			'tracking.resume' => 'Riprendi',
			'tracking.stop' => 'Ferma',
			'tracking.distance' => 'Distanza',
			'tracking.elevation' => 'Dislivello',
			'tracking.speed' => 'Velocita',
			'tracking.time' => 'Tempo',
			'tracking.confirmStop' => 'Fermare il tracciamento?',
			'tracking.dPlus' => 'D+',
			'tracking.stopSaveProgress' => 'I tuoi progressi saranno salvati.',
			'tracking.cancel' => 'Annulla',
			'tracking.stopButton' => 'Stop',
			'checklist.title' => 'Attrezzatura & Zaino',
			'checklist.subtitle' => 'Prepara lo zaino',
			'checklist.progress' => '{checked}/{total} preparati',
			'checklist.complete' => 'Lista completa!',
			'checklist.reset' => 'Reimposta',
			'checklist.resetConfirm' => 'Reimpostare la lista?',
			'checklist.resetDescription' => 'Tutti gli elementi saranno deselezionati.',
			'checklist.cancel' => 'Annulla',
			'checklist.confirm' => 'Conferma',
			'checklist.categories.carrying' => 'Zaino & trasporto',
			'checklist.categories.sleeping' => 'Riposo',
			'checklist.categories.clothing' => 'Abbigliamento',
			'checklist.categories.cooking' => 'Cucina',
			'checklist.categories.foodWater' => 'Cibo & Acqua',
			'checklist.categories.hygiene' => 'Igiene',
			'checklist.categories.firstAid' => 'Kit di primo soccorso',
			'checklist.categories.electronics' => 'Elettronica',
			'checklist.categories.women' => 'Donna',
			'checklist.categories.men' => 'Uomo',
			'checklist.categories.misc' => 'Varie',
			'checklist.categories.dog' => 'Cane',
			'checklist.items.backpack' => 'Zaino 35-45L',
			'checklist.items.rainCover' => 'Coprizaino antipioggia',
			'checklist.items.dryBags' => 'Sacche stagne (dry bags)',
			'checklist.items.sleepingBag' => 'Sacco a pelo (0-5C)',
			'checklist.items.sleepingPad' => 'Materassino / stuoia',
			'checklist.items.sleepingLiner' => 'Lenzuolo per sacco a pelo',
			'checklist.items.pillow' => 'Cuscino gonfiabile',
			'checklist.items.hikingPants' => 'Pantaloni da trekking',
			'checklist.items.rainPants' => 'Pantaloni antipioggia',
			'checklist.items.shorts' => 'Pantaloncini',
			'checklist.items.techTshirt' => 'Maglietta tecnica',
			'checklist.items.fleece' => 'Pile / piumino leggero',
			'checklist.items.rainJacket' => 'Giacca impermeabile Gore-Tex',
			'checklist.items.underwear' => 'Biancheria intima',
			'checklist.items.hikingSocks' => 'Calze da trekking',
			'checklist.items.gaiters' => 'Ghette',
			'checklist.items.hat' => 'Cappello / berretto',
			'checklist.items.beanie' => 'Berretto di lana',
			'checklist.items.buff' => 'Buff / scaldacollo',
			'checklist.items.lightGloves' => 'Guanti leggeri',
			'checklist.items.hikingBoots' => 'Scarponi (indossati)',
			'checklist.items.campSandals' => 'Sandali da bivacco',
			'checklist.items.stove' => 'Fornello (PocketRocket)',
			'checklist.items.gasCanister' => 'Cartuccia gas',
			'checklist.items.cookpot' => 'Pentolino / gavetta',
			'checklist.items.cutlery' => 'Posate (cucchiaio, coltello)',
			'checklist.items.waterBottle' => 'Borraccia / sacca 2L',
			'checklist.items.knife' => 'Coltello pieghevole',
			'checklist.items.lighter' => 'Accendino',
			'checklist.items.energyBars' => 'Barretta energetica',
			'checklist.items.driedFruits' => 'Frutta secca',
			'checklist.items.freezeDriedMeal' => 'Pasto liofilizzato',
			'checklist.items.waterPurification' => 'Pastiglie depurazione acqua',
			'checklist.items.electrolytes' => 'Elettroliti',
			'checklist.items.carriedWater' => 'Acqua trasportata (1L = 1000g)',
			'checklist.items.soap' => 'Sapone biodegradabile',
			'checklist.items.toothbrush' => 'Spazzolino da denti',
			'checklist.items.toothpaste' => 'Dentifricio',
			'checklist.items.microfiberTowel' => 'Asciugamano in microfibra',
			'checklist.items.toiletPaper' => 'Carta igienica',
			'checklist.items.trashBag' => 'Sacco della spazzatura',
			'checklist.items.antiChafingCream' => 'Crema anti-sfregamento',
			'checklist.items.earplugs' => 'Tappi per orecchie',
			'checklist.items.bandages' => 'Cerotti assortiti',
			'checklist.items.sterileCompresses' => 'Compresse sterili',
			'checklist.items.elasticBandage' => 'Benda elastica',
			'checklist.items.disinfectant' => 'Disinfettante (50ml)',
			'checklist.items.painkillers' => 'Paracetamolo / Ibuprofene',
			'checklist.items.sunscreen' => 'Crema solare SPF50',
			'checklist.items.lipBalm' => 'Burrocacao SPF30',
			'checklist.items.emergencyBlanket' => 'Coperta di sopravvivenza',
			'checklist.items.tickRemover' => 'Leva-zecche',
			'checklist.items.whistle' => 'Fischietto di emergenza',
			'checklist.items.strapping' => 'Cerotto elastico / strapping',
			'checklist.items.eyeDrops' => 'Collirio',
			'checklist.items.antiDiarrheal' => 'Antidiarroico',
			'checklist.items.antihistamine' => 'Antistaminico',
			'checklist.items.kneeTape' => 'Tape per ginocchia',
			'checklist.items.phone' => 'Telefono',
			'checklist.items.powerBank' => 'Power bank 20000mAh',
			'checklist.items.usbCable' => 'Cavo USB',
			'checklist.items.headlamp' => 'Lampada frontale',
			'checklist.items.spareBatteries' => 'Batterie di ricambio',
			'checklist.items.periodProtection' => 'Protezioni mestruali',
			'checklist.items.sportsBra' => 'Reggiseno sportivo',
			'checklist.items.intimateWipes' => 'Salviette intime',
			'checklist.items.peeCloth' => 'Pee-cloth',
			'checklist.items.razor' => 'Rasoio',
			'checklist.items.techBoxers' => 'Boxer tecnici',
			'checklist.items.hikingPoles' => 'Bastoncini da trekking (portati)',
			'checklist.items.sunglasses' => 'Occhiali da sole',
			'checklist.items.trailMap' => 'Cartina / guida topo',
			'checklist.items.spareLaces' => 'Lacci di ricambio',
			'checklist.items.needleThread' => 'Ago + filo',
			'checklist.items.ductTape' => 'Nastro adesivo',
			'checklist.items.ziplocBags' => 'Sacchetti ziploc',
			'checklist.items.cord' => 'Cordino',
			'checklist.items.cash' => 'Contanti',
			'checklist.items.dogBowl' => 'Ciotola pieghevole',
			'checklist.items.dogLeash' => 'Guinzaglio',
			'checklist.items.dogKibble' => 'Crocchette (razione/giorno)',
			'checklist.items.dogBooties' => 'Scarpine protettive',
			'checklist.items.dogVaccineBook' => 'Libretto vaccinazioni',
			'checklist.items.dogPoopBags' => 'Sacchetti igienici',
			'checklist.items.swimsuit' => 'Costume da bagno',
			'checklist.essential' => 'Essenziale',
			'checklist.weight.title' => 'Peso dello zaino',
			'checklist.weight.total' => 'Peso totale',
			'checklist.weight.bodyWeight' => 'Peso corporeo:',
			'checklist.weight.ratio' => 'Rapporto zaino / corpo',
			'checklist.weight.perItem' => 'Peso per articolo',
			'checklist.weight.edit' => 'Modifica il peso',
			'checklist.weight.grams' => 'g',
			'checklist.weight.kilograms' => 'kg',
			'checklist.weight.adviceUltraLight' => 'Zaino ultraleggero — ideale per il trekking',
			'checklist.weight.adviceLight' => 'Zaino ultraleggero — ideale per il trekking',
			'checklist.weight.adviceOk' => 'Zaino ben bilanciato',
			'checklist.weight.adviceHeavy' => 'Discreto ma pesante — valuta di alleggerire',
			'checklist.weight.adviceTooHeavy' => 'Attenzione ginocchia! Alleggerisci lo zaino',
			'checklist.weight.adviceDanger' => 'Rischio infortunio — alleggerisci subito!',
			'checklist.weight.itemWeight' => 'Peso dell\'articolo',
			'checklist.weight.cancel' => 'Annulla',
			'checklist.weight.save' => 'Salva',
			'checklist.weight.gaugeUltraLight' => 'Ultraleggero, perfetto!',
			'checklist.weight.gaugeOk' => 'Bene, bilanciato',
			'checklist.weight.gaugeHeavy' => 'Discreto ma pesante',
			'checklist.weight.gaugeWarn' => 'Attenzione ginocchia!',
			'checklist.weight.gaugeDanger' => 'Rischio infortunio!',
			'checklist.weight.percentOfWeight' => '{pct}% del peso corporeo',
			'checklist.weight.gaugeObjective' => 'Obiettivo max: < 15% in rifugio, < 20% in autonomia',
			'checklist.weight.itemsChecked' => '{checked} / {total} articoli spuntati',
			'checklist.ui.title' => 'Attrezzatura & Zaino',
			'checklist.ui.requirementRequired' => 'Obbligatorio',
			'checklist.ui.addItem' => 'Aggiungi un articolo',
			'checklist.ui.addItemTitle' => 'Aggiungi un articolo',
			'checklist.ui.fieldName' => 'Nome',
			'checklist.ui.fieldWeightGrams' => 'Peso (grammi)',
			'checklist.ui.add' => 'Aggiungi',
			'checklist.ui.editWeightTitle' => 'Modifica il peso',
			'checklist.ui.editCustomTitle' => 'Modifica articolo personalizzato',
			'checklist.ui.modify' => 'Modifica',
			'checklist.ui.delete' => 'Elimina',
			'checklist.ui.deleteItemTitle' => 'Eliminare questo articolo?',
			'checklist.ui.deleteItemBody' => 'L\'articolo "{name}" sara eliminato definitivamente.',
			'checklist.ui.requiredWarnTitle' => 'Attrezzatura obbligatoria',
			'checklist.ui.requiredWarnBody' => 'Questa attrezzatura e obbligatoria per la sicurezza (ispirata al regolamento UTMB). Vuoi davvero rimuoverla?',
			'checklist.ui.keep' => 'Mantieni',
			'checklist.ui.removeAnyway' => 'Rimuovi comunque',
			'checklist.ui.reduceQuantity' => 'Riduci quantita',
			'checklist.ui.increaseQuantity' => 'Aumenta quantita',
			'checklist.ui.addToShoppingList' => 'Aggiungi alla lista della spesa',
			'checklist.ui.removeFromShoppingList' => 'Rimuovi dalla lista',
			'checklist.ui.help' => 'Aiuto',
			'checklist.ui.shoppingListTitle' => 'Lista della spesa',
			'checklist.ui.shoppingListEmpty' => 'La tua lista della spesa e vuota. Aggiungi articoli con il pulsante carrello.',
			'checklist.ui.shoppingToBuy' => 'Da comprare',
			'checklist.ui.shoppingPurchased' => 'Gia comprato',
			'checklist.ui.share' => 'CONDIVIDI',
			'checklist.ui.infoTitle' => 'Attrezzatura & Zaino',
			'checklist.ui.infoCheckTitle' => 'Spunta gli articoli',
			'checklist.ui.infoCheckBody' => 'Spunta cio che porti — il peso si ricalcola in alto.',
			'checklist.ui.infoRequiredTitle' => 'Obbligatori',
			'checklist.ui.infoRequiredBody' => 'Articoli con lucchetto = regolamento (fischietto, lampada, coperta di sopravvivenza).',
			'checklist.ui.infoGaugeTitle' => 'Indicatore peso',
			'checklist.ui.infoGaugeBody' => 'Obiettivo: zaino < 15% del tuo peso. Verde = OK, Arancione = attenzione, Rosso = troppo pesante.',
			'checklist.ui.infoAddTitle' => 'Aggiungi',
			'checklist.ui.infoAddBody' => 'Il pulsante + in fondo a ogni categoria per i tuoi articoli.',
			'checklist.ui.infoValidateBody' => 'Conferma quando lo zaino e pronto — un segno di spunta appare sulla home.',
			'checklist.ui.infoUnderstood' => 'Capito!',
			'checklist.ui.prepTitle' => 'Preparazione dello zaino',
			'checklist.ui.prepCounter' => '{prepared} / {total} articoli preparati',
			'checklist.ui.prepAllReady' => 'Tutto pronto! Buon trekking',
			'checklist.ui.preDepartureTitle' => 'Checklist prima della partenza',
			'checklist.ui.preDepartureCounter' => '{checked}/{total} verificati',
			'checklist.ui.preDep1' => 'Controllare il meteo dei prossimi giorni',
			'checklist.ui.preDep2' => 'Caricare telefono + power bank',
			'checklist.ui.preDep3' => 'Avvisare una persona cara del tuo itinerario',
			'checklist.ui.preDep4' => 'Verificare che lo zaino sia ben chiuso e impermeabile',
			'checklist.ui.preDep5' => 'Riempire le borracce (minimo 2L)',
			'checklist.ui.preDep6' => 'Applicare crema solare e anti-sfregamento',
			'checklist.ui.preDep7' => 'Controllare lacci e serraggio degli scarponi',
			'checklist.ui.preDep8' => 'Scaricare le mappe offline',
			'checklist.ui.bagOk' => 'ZAINO OK — PRONTO A PARTIRE',
			'checklist.ui.validateBag' => 'CONFERMA IL MIO ZAINO',
			'checklist.ui.cancelValidation' => 'ANNULLA LA CONFERMA',
			'checklist.ui.shoppingListButton' => 'LISTA DELLA SPESA',
			'checklist.ui.shareGroup' => 'CONDIVIDI CON IL GRUPPO',
			'checklist.ui.exportList' => 'ESPORTA LA LISTA',
			'checklist.ui.bagValidTitle' => 'Zaino confermato',
			'checklist.ui.bagValidBody' => 'Tutti i {total} articoli obbligatori sono nello zaino.\n\nPeso totale: {weight} kg ({pct}% del peso corporeo)\n\nSei sicuro che lo zaino sia pronto?',
			'checklist.ui.checkAgain' => 'Controlla ancora',
			'checklist.ui.yesBagOk' => 'Si, zaino OK',
			'checklist.ui.bagValidatedSnack' => 'Zaino confermato!',
			'checklist.ui.validationCancelledSnack' => 'Conferma annullata — puoi modificare la tua attrezzatura.',
			'checklist.ui.missingTitle' => 'Attrezzatura mancante',
			'checklist.ui.missingBody' => '{checked}/{total} articoli obbligatori spuntati.',
			'checklist.ui.missingList' => 'Manca:',
			'checklist.ui.understood' => 'Capito',
			'checklist.ui.validateAnyway' => 'Conferma comunque',
			'checklist.ui.bagValidatedMissingSnack' => 'Zaino confermato (con articoli mancanti)!',
			'checklist.ui.shareGroupHint' => 'Unisciti a un gruppo per condividere la tua checklist.',
			'journal.title' => 'Diario di trekking',
			'journal.empty' => 'Il tuo diario è vuoto',
			'journal.emptySubtitle' => 'Annota le tue impressioni e ricordi di trekking',
			'journal.addNote' => 'Nuova nota',
			'journal.stage' => 'Tappa',
			'journal.yourNote' => 'La tua nota',
			'journal.placeholder' => 'Descrivi la tua giornata di trekking...',
			'journal.save' => 'Salva',
			'journal.cancel' => 'Annulla',
			'journal.delete' => 'Elimina',
			'journal.photoLimit' => 'Limite di 3 foto al giorno raggiunto',
			'journal.photoTooBig' => 'Foto troppo grande (max 500 KB)',
			'weather.title' => 'Meteo',
			'weather.loading' => 'Caricamento meteo...',
			'weather.offline' => 'Nessuna connessione. Dati meteo non disponibili.',
			'weather.error' => 'Impossibile caricare il meteo.',
			'weather.cached' => 'Dati nella cache',
			'weather.alerts' => 'allerte meteo',
			'weather.refresh' => 'Aggiorna',
			'weather.temperature' => 'Temperatura',
			'weather.precipitation' => 'Precipitazioni',
			'weather.wind' => 'Vento',
			'weather.uv' => 'Indice UV',
			'weather.fireRisk' => 'Rischio incendio',
			'weather.fireRiskDesc' => 'Rischio incendio elevato. Consultare le istruzioni di sicurezza.',
			'weather.fireSafetyTips' => 'Istruzioni antincendio',
			'weather.alertCount' => 'allerta',
			'weather.alertCountPlural' => 'allerte',
			'weather.today' => 'Oggi',
			'weather.tomorrow' => 'Domani',
			'weather.dayPlus2' => 'Dopodomani',
			'weather.allStages' => 'Tutte le tappe',
			'weather.noForecast' => 'Nessuna previsione disponibile.',
			'weather.stageLabel' => ({required Object number}) => 'Tappa ${number}',
			'weather.stormAlertsTitle' => 'Allerte temporali',
			'weather.stormAlertsToggleOn' => 'Allerte temporali attive',
			'weather.stormAlertsToggleOff' => 'Allerte temporali disattivate',
			'weather.lastUpdate' => ({required Object date}) => 'Aggiornato ${date}',
			'weather.guideTitle' => 'Capire il meteo',
			'weather.guideBody' => 'Le previsioni coprono 7 giorni per ogni tappa. Attenzione alle allerte temporali e vento: in montagna il tempo cambia in fretta. Senza rete vengono mostrati gli ultimi dati salvati.',
			'weather.source.api' => 'Dati in diretta',
			'weather.source.cache' => 'Dati salvati',
			'weather.source.offline' => 'Non in linea',
			'weather.source.demo' => 'Dati dimostrativi',
			'weather.recommendation.ok' => 'Condizioni favorevoli',
			'weather.recommendation.watch' => 'Prudenza consigliata',
			'weather.recommendation.danger' => 'Condizioni sfavorevoli',
			'weather.alert.storm.title' => 'Temporale previsto',
			'weather.alert.storm.desc' => ({required Object condition}) => '${condition}. Evita le creste e le zone esposte.',
			'weather.alert.wind.title' => 'Vento forte',
			'weather.alert.wind.desc' => ({required Object value}) => 'Raffiche fino a ${value} km/h. Prudenza nei passaggi esposti.',
			'weather.alert.rain.title' => 'Forti precipitazioni',
			'weather.alert.rain.desc' => ({required Object value}) => '${value} mm previsti. Rischio di sentieri scivolosi e torrenti.',
			'weather.alert.snow.title' => 'Neve prevista',
			'weather.alert.snow.desc' => ({required Object condition}) => '${condition}. Attrezzatura adeguata necessaria.',
			'weather.alert.uv.title' => 'UV molto alto',
			'weather.alert.uv.desc' => ({required Object value}) => 'Indice UV ${value}. Massima protezione solare consigliata.',
			'weather.alert.fire.title' => 'Rischio incendio',
			'weather.alert.fire.desc' => ({required Object value}) => '${value}°C previsti. Rischio incendio elevato.',
			'share.title' => 'Condividi',
			'share.generating' => 'Generazione...',
			'share.share' => 'Condividi',
			'share.error' => 'Errore durante la generazione',
			'share.errorShare' => 'Errore durante la condivisione',
			'share.preview' => 'Anteprima',
			'share.chooseTemplate' => 'Scegli un template',
			'share.templateStats' => 'Statistiche',
			'share.templateJourney' => 'Percorso',
			'share.templateStage' => 'Tappa',
			'diploma.title' => 'Diploma di trekking',
			'diploma.yourName' => 'Il tuo nome',
			'diploma.namePlaceholder' => 'Inserisci il tuo nome...',
			'diploma.generatePdf' => 'Genera PDF',
			'diploma.certifies' => 'Certifica che',
			'diploma.completed' => 'ha percorso il',
			'diploma.pdfTitle' => 'DIPLOMA',
			'diploma.pdfSubtitle' => 'Certificato di completamento',
			'diploma.pdfStages' => '{count} tappe',
			'diploma.pdfDistance' => '{km} km percorsi',
			'diploma.pdfElevation' => '{meters} m di dislivello positivo',
			'diploma.pdfDuration' => 'in {days} giorni',
			'diploma.pdfFrom' => 'Dal',
			'diploma.pdfTo' => 'al',
			'diploma.pdfIssuedOn' => 'Rilasciato il {date}',
			'diploma.recapTitle' => 'La tua avventura',
			'diploma.recapJournalPhotos' => 'Foto del diario',
			'diploma.recapNoPhotos' => 'Nessuna foto nel diario',
			'diploma.recapStats' => 'Statistiche',
			'diploma.recapStages' => '{count} tappe completate',
			'diploma.recapDistance' => '{km} km percorsi',
			'diploma.recapElevation' => '{meters} m di dislivello',
			'diploma.recapDuration' => '{days} giorni di trekking',
			'diploma.recapMapTrace' => 'Tracciato del percorso',
			'diploma.recapNoMap' => 'Tracciato non disponibile',
			'diploma.recapJournalEntries' => '{count} note del diario',
			'diploma.downloadPdf' => 'Scarica diploma PDF',
			'diploma.lockedTitle' => 'Diploma bloccato',
			'diploma.lockedMessage' => 'Completa l intero percorso per sbloccare il tuo diploma da finisher.',
			'diploma.labelIntegral' => 'Percorso integrale',
			'diploma.labelPartial' => 'Percorso parziale',
			'notifications.morningReminder' => 'Promemoria mattutino',
			'notifications.weatherAlerts' => 'Allerte meteo',
			'notifications.countdown' => 'Promemoria G-2',
			'notifications.countdownDesc' => 'Notifica 2 giorni prima della partenza',
			'notifications.schedulerCountdownTitle' => 'Il tuo trek si avvicina!',
			'notifications.schedulerCountdownBody' => 'Partenza tra 2 giorni. Controlla la checklist e il meteo.',
			'notifications.schedulerDailyTitle' => 'Buona giornata di trek!',
			'notifications.schedulerDailyBody' => 'Controlla il meteo e prepara la tappa di oggi.',
			'settings.title' => 'Impostazioni',
			'settings.language' => 'Lingua',
			'settings.units' => 'Unità',
			'settings.distance' => 'Distanza',
			_ => null,
		} ?? switch (path) {
			'settings.temperature' => 'Temperatura',
			'settings.theme' => 'Tema',
			'settings.dark' => 'Scuro',
			'settings.light' => 'Chiaro',
			'settings.system' => 'Sistema',
			'settings.cache' => 'Cache',
			'settings.cacheEnabled' => 'Cache attivata',
			'settings.cacheDesc' => 'Dati disponibili offline',
			'settings.cacheSize' => 'Dimensione cache',
			'settings.notifications' => 'Notifiche',
			'settings.morningReminder' => 'Promemoria mattutino',
			'settings.weatherAlerts' => 'Allerte meteo',
			'settings.weatherAlertsDesc' => 'Avvisato in caso di condizioni pericolose',
			'settings.countdownReminder' => 'Promemoria G-2',
			'settings.countdownDesc' => 'Notifica 2 giorni prima della partenza',
			'settings.offTrackAlerts' => 'Avviso fuori tracciato',
			'settings.offTrackAlertsDesc' => 'Notifica + vibrazione se lasci il sentiero',
			'settings.version' => 'Versione',
			'settings.versionLabel' => 'Versione dell\'app',
			'appearance.title' => 'Aspetto',
			'appearance.subtitle' => 'Scegli lo stile dell’app',
			'appearance.skinSentierVivant' => 'Sentiero Vivo',
			'appearance.skinSentierVivantDesc' => 'Moderno e colorato, il colore del sentiero in primo piano',
			'appearance.skinTopographique' => 'Topografico',
			'appearance.skinTopographiqueDesc' => 'Stile carta topografica, dati in evidenza',
			'appearance.skinGrandAir' => 'Grande Aria',
			'appearance.skinGrandAirDesc' => 'Foto a tutto schermo, atmosfera da diario d’avventura',
			'appearance.unavailableOnTrail' => 'Non disponibile su questo sentiero',
			'appearance.changeSkin' => 'Cambia aspetto',
			'appearance.selected' => 'Selezionato',
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Tipo di feedback',
			'feedback.bug' => 'Bug / Problema',
			'feedback.suggestion' => 'Suggerimento',
			'feedback.compliment' => 'Complimento',
			'feedback.question' => 'Domanda',
			'feedback.other' => 'Altro',
			'feedback.message' => 'Il tuo messaggio',
			'feedback.messagePlaceholder' => 'Descrivi il tuo feedback...',
			'feedback.satisfaction' => 'Soddisfazione',
			'feedback.send' => 'Invia',
			'feedback.sending' => 'Invio...',
			'feedback.thanks' => 'Grazie per il tuo feedback!',
			'feedback.pending' => 'in attesa',
			'auth.profile' => 'Profilo',
			'auth.anonymous' => 'Escursionista senza account',
			'auth.connectedVia' => 'Connesso tramite',
			'auth.signInGoogle' => 'Accedi con Google',
			'auth.signInGoogleDesc' => 'Per salvare i tuoi progressi',
			'auth.signOut' => 'Esci',
			'auth.signOutDesc' => 'Torna alla modalità senza account',
			'auth.signOutConfirm' => 'Disconnettersi?',
			'auth.signOutMessage' => 'Tornerai alla modalità senza account. I tuoi dati locali saranno conservati.',
			'auth.deleteAccount' => 'Elimina il mio account',
			'auth.deleteAccountDesc' => 'Tutti i tuoi dati saranno cancellati',
			'auth.deleteConfirm' => 'Eliminare il tuo account?',
			'auth.deleteMessage' => 'Questa azione è irreversibile. Tutti i tuoi dati, note e progressi saranno cancellati.',
			'auth.cancel' => 'Annulla',
			'auth.pseudonym' => 'Pseudonimo',
			'auth.pseudonymHint' => 'Il tuo nome da escursionista',
			'auth.save' => 'Salva',
			'auth.changeAvatar' => 'Cambia avatar',
			'auth.chooseAvatar' => 'Scegli un avatar',
			'auth.errorLoading' => 'Errore di caricamento',
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
			'feasibility.seeRecommendations' => 'Vedi raccomandazioni',
			'feasibility.yourProfile' => 'Il vostro profilo',
			'feasibility.tipsTitle' => 'I nostri consigli',
			'feasibility.recommendations.danger.title' => 'Preparazione insufficiente',
			'feasibility.recommendations.danger.summary' => 'Il vostro profilo mostra lacune importanti. Sconsigliamo di partire.',
			'feasibility.recommendations.danger.tips.tip1' => 'Iniziate con escursioni brevi per valutare la condizione',
			'feasibility.recommendations.danger.tips.tip2' => 'Consultate un professionista sanitario',
			'feasibility.recommendations.danger.tips.tip3' => 'Investite in attrezzatura adeguata e testatela',
			'feasibility.recommendations.caution.title' => 'Preparazione da rafforzare',
			'feasibility.recommendations.caution.summary' => 'Avete le basi, ma alcuni punti richiedono attenzione.',
			'feasibility.recommendations.caution.tips.tip1' => 'Rafforzate il vostro allenamento 6-8 settimane prima',
			'feasibility.recommendations.caution.tips.tip2' => 'Verificate e completate la vostra attrezzatura',
			'feasibility.recommendations.caution.tips.tip3' => 'Pianificate tappe adatte al vostro livello',
			'feasibility.recommendations.good.title' => 'Buona preparazione',
			'feasibility.recommendations.good.summary' => 'Il vostro profilo è solido. Qualche aggiustamento e sarete pronti.',
			'feasibility.recommendations.good.tips.tip1' => 'Mantenete il ritmo di allenamento',
			'feasibility.recommendations.good.tips.tip2' => 'Prevedete margini nella pianificazione',
			'feasibility.recommendations.good.tips.tip3' => 'Consultate le previsioni meteo regolarmente',
			'feasibility.recommendations.excellent.title' => 'Preparazione ottimale',
			'feasibility.recommendations.excellent.summary' => 'Siete perfettamente preparati. Godetevi il trekking!',
			'feasibility.recommendations.excellent.tips.tip1' => 'Ascoltate il vostro corpo durante il trekking',
			'feasibility.recommendations.excellent.tips.tip2' => 'Condividete la vostra esperienza',
			'feasibility.recommendations.excellent.tips.tip3' => 'Documentate la vostra avventura nel diario',
			'tips.carouselTitle' => 'Consigli trek',
			'tips.allCategories' => 'Tutte',
			'tips.swipeHint' => 'Scorri per vedere altro',
			'tips.detailTitle' => 'Dettaglio consiglio',
			'tips.readMore' => 'Leggi di piu',
			'tips.noTips' => 'Nessun consiglio disponibile',
			'tips.categoryPreparation' => 'Preparazione',
			'tips.categoryEquipment' => 'Attrezzatura',
			'tips.categoryNutrition' => 'Nutrizione',
			'tips.categorySafety' => 'Sicurezza',
			'tips.categoryNature' => 'Natura',
			'tips.categoryRecovery' => 'Recupero',
			'tips.categoryGeneral' => 'Generale',
			'tips.priorityHigh' => 'Priorita alta',
			'tips.scope' => 'Sentiero',
			'tips.season' => 'Stagione',
			'tips.altitude' => 'Altitudine min.',
			'goodies.title' => 'Negozio Goodies',
			'goodies.comingSoon' => 'Questo modulo arrivera presto. Resta connesso!',
			'noData.title' => 'Nessun sentiero scaricato',
			'noData.subtitle' => 'Scarica un sentiero per iniziare',
			'noData.offlineHint' => 'I dati saranno disponibili offline per la tua escursione.',
			'noData.browseCta' => 'Esplora i sentieri',
			'catalog.title' => 'Catalogo dei sentieri',
			'catalog.enter' => 'Entra',
			'catalog.mustDownload' => 'Scarica questo sentiero per esplorarlo.',
			'catalog.emptyTitle' => 'Nessun sentiero disponibile',
			'catalog.emptySubtitle' => 'Nessun sentiero è ancora proposto nel catalogo.',
			'catalog.a11y.enterButton' => ({required Object nom}) => 'Entra nel sentiero ${nom}',
			'updates.readyTitle' => 'Aggiornamento pronto',
			'updates.readyBodyOne' => 'Un sentiero è stato aggiornato.',
			'updates.readyBodyMany' => ({required Object count}) => '${count} sentieri sono stati aggiornati.',
			'follow.title' => 'Localizzazione in diretta',
			'follow.connecting' => 'Connessione…',
			'follow.live' => 'In diretta',
			'follow.offline' => 'Offline',
			'follow.invalidLink' => 'Link non valido',
			'follow.invalidLinkHint' => 'Questo link di localizzazione non esiste o è scaduto.',
			'cloud.localModeTitle' => 'Modalità locale',
			'cloud.localModeBody' => 'Questa installazione non è collegata a un servizio cloud: localizzazione in diretta, backup online e account sono disattivati. I tuoi dati restano sul dispositivo.',
			'cloud.statusSection' => 'Cloud',
			'cloud.statusActive' => 'Servizi online attivi',
			'cloud.statusActiveDesc' => 'Backup e localizzazione in diretta disponibili.',
			'cloud.statusLocal' => 'Modalità locale (senza cloud)',
			'cloud.statusLocalDesc' => 'Nessun dato viene inviato online. Configurazione cloud assente.',
			'onboarding.skip' => 'Salta',
			'onboarding.next' => 'Avanti',
			'onboarding.getStarted' => 'Inizia',
			'onboarding.welcomeTitle' => ({required Object appName}) => 'Benvenuto su ${appName}',
			'onboarding.welcomeSubtitle' => 'Il tuo compagno di trekking offline: mappa, navigazione GPS, pianificazione e diario di trek.',
			'onboarding.languageTitle' => 'Scegli la tua lingua',
			'onboarding.languageSubtitle' => 'Potrai modificarla in qualsiasi momento nelle impostazioni.',
			'onboarding.downloadTitle' => 'Scarica il tuo primo sentiero',
			'onboarding.downloadSubtitle' => 'Sfoglia il catalogo e scarica un sentiero per usarlo completamente offline.',
			'onboarding.browseCatalog' => 'Sfoglia il catalogo',
			'monetization.demoBanner' => 'Modalità demo — tocca per sbloccare',
			'monetization.paywallTitle' => 'Sblocca questo trek',
			'monetization.paywallBody' => 'La modalità gratuita permette di preparare il trek con pubblicità. Il premium sblocca tutto, senza pubblicità.',
			'monetization.featureMap' => 'Mappa offline + GPS + localizzazione in diretta',
			'monetization.featureJournal' => 'Diario di viaggio completo',
			'monetization.featureDiploma' => 'Diploma di fine trek',
			'monetization.featureFollowers' => '2 follower gratuiti',
			'monetization.featureNoAds' => 'Zero pubblicità',
			'monetization.buyCta' => 'Sblocca questo trek',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Sblocca questo trek — ${price} €',
			'signalement.title' => 'Segnala',
			'signalement.chooseType' => 'Cosa vuoi segnalare?',
			'signalement.types.obstacle' => 'Ostacolo sul sentiero',
			'signalement.types.eauASec' => 'Punto d\'acqua a secco',
			'signalement.types.danger' => 'Pericolo',
			'signalement.latencyBanner' => 'Salvato. Visibile agli altri escursionisti dopo la sincronizzazione di rete.',
			'signalement.confirm' => 'Conferma segnalazione',
			'signalement.noLocation' => 'Posizione GPS non disponibile al momento. Riprova sotto cielo aperto.',
			'signalement.savedTitle' => 'Segnalazione salvata',
			'signalement.savedPendingSync' => 'Sarà condivisa appena la rete sarà disponibile.',
			'signalement.pendingCount' => ({required Object n}) => '${n} in attesa di sincronizzazione',
			'signalement.close' => 'Chiudi',
			'hebergement.title' => 'Alloggi nelle vicinanze',
			'hebergement.facilitatorNote' => 'StepWays ti indirizza agli alloggi. La prenotazione avviene sul loro sito: nessun pagamento nell\'app.',
			'hebergement.detourAR' => ({required Object km}) => 'Deviazione andata e ritorno: ${km} km',
			'hebergement.openSite' => 'Vedi il sito',
			'hebergement.cannotOpen' => 'Impossibile aprire questo link su questo dispositivo.',
			'hebergement.empty' => 'Nessun alloggio elencato nelle vicinanze per ora.',
			'hebergement.types.refuge' => 'Rifugio',
			'hebergement.types.gite' => 'Locanda',
			'hebergement.types.hotel' => 'Hotel',
			'hebergement.types.camping' => 'Campeggio',
			'hebergement.types.chambreHote' => 'Bed & breakfast',
			'training.title' => 'Preparazione fisica',
			'training.localNotice' => 'Il tuo programma è calcolato e conservato sul telefono. I promemoria sono notifiche locali, senza tracciamento.',
			'training.reminderTitle' => 'Sessione di allenamento oggi',
			'training.scheduleReminders' => 'Programma i promemoria',
			'training.remindersScheduled' => ({required Object n}) => '${n} promemoria programmato/i',
			'training.week' => ({required Object n}) => 'Settimana ${n}',
			'training.minutes' => ({required Object n}) => '${n} min',
			'training.progress' => ({required Object done, required Object total}) => '${done}/${total} sessioni completate',
			'training.types.marche' => 'Camminata',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Potenziamento',
			'training.intensity.faible' => 'Bassa',
			'training.intensity.moderee' => 'Moderata',
			'training.intensity.elevee' => 'Elevata',
			'eta.title' => 'Tempo stimato',
			'eta.toNextWaypoint' => 'Prossimo punto',
			'eta.toStageEnd' => 'Fine tappa',
			'eta.confidenceHigh' => 'Stima affidabile',
			'eta.confidenceLow' => 'Approssimativo (GPS debole)',
			'eta.durationHm' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'eta.durationM' => ({required Object m}) => '${m} min',
			'leaderboard.title' => 'Re della tappa',
			'leaderboard.unavailable' => 'Classifica non disponibile al momento.',
			'leaderboard.empty' => 'Nessuna classifica per questo segmento. Sii il primo a percorrerlo!',
			'leaderboard.pseudonymNotice' => 'Classifica per fascia, con pseudonimi. Nessun dato personale diretto viene mostrato.',
			'leaderboard.trancheLabel' => ({required Object tranche}) => 'Fascia: ${tranche}',
			'leaderboard.notEnoughParticipants' => 'Partecipanti insufficienti per pubblicare questa classifica.',
			'leaderboard.entrySemantics' => ({required Object rank, required Object pseudonym, required Object time}) => 'Posizione ${rank}, ${pseudonym}, tempo ${time}',
			'social.feedTitle' => 'Diario attività',
			'social.empty' => 'Nessuna attività al momento.',
			'social.kudos' => 'Incoraggia',
			'social.kudosCount' => ({required Object n}) => '${n} incoraggiamenti',
			'social.report' => 'Segnala',
			'social.reportTitle' => 'Segnala questo post',
			'social.reportReasonLabel' => 'Motivo della segnalazione',
			'social.reasonSpam' => 'Spam o pubblicità',
			'social.reasonAbuse' => 'Contenuto offensivo o di odio',
			'social.reasonOther' => 'Altro',
			'social.reportSend' => 'Invia segnalazione',
			'social.reportSent' => 'Segnalazione inviata. Il nostro team la esaminerà.',
			'social.syncPending' => 'In attesa di sincronizzazione',
			'social.synced' => 'Sincronizzato',
			'social.activitySegment' => 'ha completato un segmento',
			'social.activityBadge' => 'ha ottenuto un distintivo',
			'social.activityDefi' => 'ha fatto progressi in una sfida',
			'gamification.galleryTitle' => 'I miei distintivi',
			'gamification.obtained' => 'Ottenuto',
			'gamification.locked' => 'Bloccato',
			'gamification.tierDebutant' => 'Principiante',
			'gamification.tierExpert' => 'Esperto',
			'gamification.badge.firstStage.titre' => 'Prima tappa',
			'gamification.badge.firstStage.description' => 'Hai completato la tua prima tappa.',
			'gamification.badge.firstTrek.titre' => 'Primo trek',
			'gamification.badge.firstTrek.description' => 'Hai concluso il tuo primo trek completo.',
			'gamification.badge.firstSegment.titre' => 'Primo segmento',
			'gamification.badge.firstSegment.description' => 'Hai percorso il tuo primo segmento.',
			'gamification.badge.elevation5000.titre' => '5000 m di dislivello',
			'gamification.badge.elevation5000.description' => 'Hai accumulato 5000 m di dislivello positivo.',
			'gamification.badge.tenStages.titre' => '10 tappe',
			'gamification.badge.tenStages.description' => 'Hai completato 10 tappe.',
			'gamification.badge.challenger.titre' => 'Sfidante',
			'gamification.badge.challenger.description' => 'Hai completato la tua prima sfida stagionale.',
			'gamification.defi.screenTitle' => 'Sfide',
			'gamification.defi.inProgress' => 'In corso',
			'gamification.defi.progressLabel' => ({required Object current, required Object target}) => 'Progresso: ${current} / ${target}',
			'gamification.defi.rankingTitle' => 'Classifica della sfida',
			'gamification.defi.pseudonymNotice' => 'Classifica per fascia, con pseudonimi. Nessun dato personale diretto viene mostrato.',
			'gamification.defi.notEnoughParticipants' => 'Partecipanti insufficienti per pubblicare questa classifica.',
			'gamification.defi.noDefi' => 'Nessuna sfida in corso al momento.',
			'shareVisibility.title' => 'Condivisione e visibilità',
			'shareVisibility.intro' => 'Per impostazione predefinita, non viene condiviso nulla. Attiva qui sotto, finalità per finalità, ciò che vuoi rendere visibile.',
			'shareVisibility.consentLink' => 'Gestisci il mio consenso (privacy)',
			'shareVisibility.stageResults' => 'Condividi i miei risultati di tappa',
			'shareVisibility.stageResultsDesc' => 'Una scheda con pseudonimo (senza dati personali diretti).',
			'shareVisibility.leaderboard' => 'Apparire nelle classifiche',
			'shareVisibility.leaderboardDesc' => 'Classifica per fascia, con uno pseudonimo.',
			'shareVisibility.activityFeed' => 'Pubblica nel diario attività',
			'shareVisibility.activityFeedDesc' => 'Le tue attività appaiono nel diario, con uno pseudonimo.',
			'shareVisibility.shareTitle' => 'Condividi questa tappa',
			'shareVisibility.shareButton' => 'Condividi',
			'shareVisibility.privateNotice' => 'La condivisione è disattivata. Attivala in Condivisione e visibilità.',
			'shareVisibility.shared' => 'Scheda pronta da condividere.',
			'waypoints.types.eau' => 'Acqua',
			'waypoints.types.ravitaillement' => 'Rifornimento',
			'waypoints.types.danger' => 'Pericolo',
			'waypoints.types.camp' => 'Campeggio',
			'waypoints.types.connectivite' => 'Connettivita',
			'waypoints.types.jonction' => 'Bivio',
			'waypoints.filters.title' => 'Filtra i waypoint',
			'waypoints.filters.showAll' => 'Mostra tutto',
			'waypoints.filters.hideAll' => 'Nascondi tutto',
			'waypoints.filters.recentConditionOnly' => 'Solo condizione recente',
			'waypoints.detail.conditionsTitle' => 'Condizioni del terreno',
			'waypoints.detail.noComments' => 'Nessuna condizione segnalata per ora.',
			'waypoints.detail.commentsError' => 'Condizioni non disponibili.',
			'waypoints.detail.report' => 'Segnala',
			'waypoints.detail.reportAck' => 'Segnalazione salvata. Sara esaminata dopo la sincronizzazione.',
			'waypoints.detail.pendingSync' => 'In attesa di sincronizzazione',
			'waypoints.freshness.justNow' => 'aggiornato proprio ora',
			'waypoints.freshness.minutes' => ({required Object n}) => 'aggiornato ${n} min fa',
			'waypoints.freshness.hours' => ({required Object n}) => 'aggiornato ${n} h fa',
			'waypoints.freshness.days' => ({required Object n}) => 'aggiornato ${n} g fa',
			'waypoints.contribution.titleWaypoint' => 'Aggiungi un punto',
			'waypoints.contribution.titleComment' => 'Segnala una condizione',
			'waypoints.contribution.chooseType' => 'Tipo di punto',
			'waypoints.contribution.titleField' => 'Titolo del punto',
			'waypoints.contribution.conditionPrompt' => 'Descrivi la condizione osservata',
			'waypoints.contribution.commentField' => 'La tua osservazione',
			'waypoints.contribution.conditionField' => 'Stato (facoltativo)',
			'waypoints.contribution.conditionHelper' => 'es. acqua esaurita, acqua scorre, passaggio scivoloso',
			'waypoints.contribution.latencyBanner' => 'Sara pubblicato alla prossima sincronizzazione di rete.',
			'waypoints.contribution.submit' => 'Salva',
			'waypoints.contribution.savedTitle' => 'Contributo salvato',
			'waypoints.contribution.savedPendingSync' => 'Sara pubblicato al ritorno della rete.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} in attesa di sincronizzazione',
			'waypoints.contribution.close' => 'Chiudi',
			'waypoints.contribution.emptyTitle' => 'Inserisci un titolo per il punto.',
			'waypoints.contribution.emptyComment' => 'Inserisci la tua osservazione.',
			'waypoints.contribution.noLocation' => 'Posizione GPS non disponibile. Riprova sotto cielo aperto.',
			'waypoints.contribution.error' => 'Impossibile salvare in questo momento.',
			'packs.title' => 'Pacchetti sentiero',
			'packs.subtitle' => 'Scarica un pacchetto per camminare 100% offline.',
			'packs.alaCarteNote' => 'A la carte: acquista solo il pacchetto che ti serve, nessun abbonamento.',
			'packs.size' => ({required Object mo}) => '${mo} MB',
			'packs.states.notDownloaded' => 'Non scaricato',
			'packs.states.downloaded' => 'Scaricato',
			'packs.states.updateAvailable' => 'Aggiornamento disponibile',
			'packs.actions.download' => 'Scarica',
			'packs.actions.update' => 'Aggiorna',
			'packs.actions.delete' => 'Elimina',
			'packs.actions.retry' => 'Riprova',
			'packs.actions.buy' => 'Acquista questo pacchetto',
			'packs.actions.buyWithPrice' => ({required Object price}) => 'Acquista questo pacchetto — ${price}',
			'packs.progress.downloading' => ({required Object done, required Object total}) => 'Scaricamento… ${done}/${total}',
			'packs.progress.verifying' => 'Verifica integrità…',
			'packs.progress.completed' => 'Pacchetto pronto offline',
			'packs.progress.error' => 'Scaricamento non riuscito',
			'packs.delete.confirmTitle' => 'Eliminare questo pacchetto?',
			'packs.delete.confirmBody' => 'Il pacchetto verrà rimosso dal dispositivo per liberare spazio. Potrai riscaricarlo in seguito.',
			'packs.delete.cancel' => 'Annulla',
			'packs.delete.confirm' => 'Elimina',
			'packs.delete.freed' => 'Spazio liberato.',
			'packs.empty' => 'Nessun pacchetto disponibile per questo sentiero.',
			'packs.a11y.packCard' => ({required Object nom, required Object state}) => 'Pacchetto ${nom}, ${state}',
			'packs.a11y.downloadButton' => ({required Object nom}) => 'Scarica il pacchetto ${nom}',
			'packs.a11y.deleteButton' => ({required Object nom}) => 'Elimina il pacchetto ${nom}',
			'packs.types.nord.nom' => 'Mare a Mare Nord',
			'packs.types.nord.description' => 'La metà nord del sentiero, offline.',
			'packs.types.sud.nom' => 'Mare a Mare Sud',
			'packs.types.sud.description' => 'La metà sud del sentiero, offline.',
			'packs.types.complet.nom' => 'Mare a Mare Completo',
			'packs.types.complet.description' => 'Tutto il sentiero, offline.',
			'packs.types.mam.nom' => 'Mare a Mare',
			'packs.types.mam.description' => 'Il sentiero Mare a Mare, offline.',
			'guides.title' => 'Guide delle città',
			'guides.subtitle' => 'Info pratiche su città e paesi, consultabili offline.',
			'guides.sectionsCount' => ({required Object n}) => '${n} sezioni pratiche',
			'guides.empty' => 'Nessuna guida disponibile per questo sentiero.',
			'guides.noItems' => 'Ancora nessuna informazione in questa sezione.',
			'guides.facilitatorNote' => 'StepWays ti indirizza ai fornitori. Prenotazione e pagamento avvengono sul loro sito: niente nell\'app.',
			'guides.openSite' => 'Apri il sito',
			'guides.cannotOpen' => 'Impossibile aprire questo link su questo dispositivo.',
			'guides.categories.ravitaillement' => 'Rifornimento',
			'guides.categories.hebergement' => 'Alloggio',
			'guides.categories.transport' => 'Trasporti',
			'guides.categories.services' => 'Servizi',
			'guides.categories.eau' => 'Acqua',
			'guides.categories.sante' => 'Salute',
			'guides.intro.ravitaillement' => 'Dove fare scorta di provviste.',
			'guides.intro.hebergement' => 'Dove dormire alla tappa.',
			'guides.intro.transport' => 'Autobus, navette e collegamenti.',
			'guides.intro.services' => 'Posta, banca, lavanderia e altro.',
			'guides.intro.eau' => 'Punti d\'acqua potabile.',
			'guides.intro.sante' => 'Farmacia e cure nelle vicinanze.',
			'guides.a11y.guideCard' => ({required Object lieu}) => 'Guida di ${lieu}',
			'guides.a11y.section' => ({required Object titre}) => 'Sezione ${titre}',
			'guides.a11y.openSiteButton' => ({required Object nom}) => 'Apri il sito di ${nom}',
			'health.title' => 'Informazioni sanitarie',
			'health.privacyBanner' => 'Questi dati restano sul tuo telefono. Non vengono mai inviati su internet.',
			'health.field.bloodType' => 'Gruppo sanguigno',
			'health.field.allergies' => 'Allergie',
			'health.field.treatments' => 'Terapie in corso',
			'health.field.doctor' => 'Medico di base',
			'health.field.insurance' => 'N. assicurazione / mutua',
			'health.hint.bloodType' => 'Es. A+, O-, AB+',
			'health.hint.allergies' => 'Es. penicillina, arachidi',
			'health.hint.treatments' => 'Es. Levothyrox 50 mg/giorno',
			'health.hint.doctor' => 'Es. Dr. Rossi +39 06 xxxx xxxx',
			'health.hint.insurance' => 'Es. tessera europea',
			'health.save' => 'Salva',
			'health.saving' => 'Salvataggio…',
			'health.saved' => 'Informazioni salvate',
			'health.emergencyHint' => 'In caso di emergenza, mostra questa schermata ai soccorsi.',
			'health.entryTitle' => 'Le mie info sanitarie',
			'health.entrySubtitle' => 'Da mostrare ai soccorsi (restano sul telefono)',
			'health.a11y.form' => 'Modulo informazioni sanitarie',
			'health.a11y.saveButton' => 'Salva le informazioni sanitarie',
			'trailSelection.title' => 'Cambia sentiero',
			'trailSelection.subtitle' => 'Scegli il sentiero da esplorare. Tutta l app (mappa, tappe, punti di interesse, pacchetti, guide) segue la tua selezione.',
			'trailSelection.current' => 'Sentiero attivo',
			'trailSelection.select' => 'Scegli questo sentiero',
			'trailSelection.selected' => 'Sentiero selezionato',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} tappe - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Sentiero ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Sentiero attualmente attivo',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Attiva il sentiero ${nom}',
			'consent.onboardingTitle' => 'La tua privacy, la tua scelta',
			'consent.onboardingIntro' => 'Nulla è attivato per impostazione predefinita. Scegli, finalità per finalità, ciò che autorizzi. Potrai modificare tutto in qualsiasi momento nelle impostazioni.',
			'consent.settingsTitle' => 'Privacy e consenso',
			'consent.settingsIntro' => 'Gestisci qui ogni autorizzazione. Puoi revocare un consenso in qualsiasi momento, senza conseguenze sul resto.',
			'consent.settingsEntry' => 'Privacy e consenso',
			'consent.settingsEntryDesc' => 'Gestire le mie autorizzazioni (posizione, condivisione, salute)',
			'consent.purposes.locationNavigation' => 'Navigazione personale',
			'consent.purposes.locationNavigationDesc' => 'Usare la tua posizione per la mappa e il monitoraggio della tappa. Resta sul tuo dispositivo.',
			'consent.purposes.socialSharing' => 'Condivisione social',
			'consent.purposes.socialSharingDesc' => 'Apparire nelle classifiche e nel feed della community, sotto pseudonimo.',
			'consent.purposes.publicReporting' => 'Segnalazioni pubbliche',
			'consent.purposes.publicReportingDesc' => 'Pubblicare segnalazioni (acqua, pericolo, condizioni) visibili agli altri escursionisti.',
			'consent.purposes.healthData' => 'Dati sulla salute',
			'consent.purposes.healthDataDesc' => 'Leggere la tua frequenza cardiaca (fascia o app salute) per arricchire il monitoraggio dello sforzo.',
			'consent.healthBadge' => 'Dato sensibile',
			'consent.healthWarning' => 'La frequenza cardiaca è un dato sulla salute (articolo 9 del GDPR). Questo consenso è richiesto separatamente e non viene mai raggruppato con gli altri. I tuoi dati sulla salute non vengono inviati ai nostri server.',
			'consent.granted' => 'Autorizzato',
			'consent.denied' => 'Non autorizzato',
			'consent.grant' => 'Autorizza',
			'consent.revoke' => 'Revoca',
			'consent.decidedOn' => ({required Object date}) => 'Scelto il ${date}',
			'consent.notDecided' => 'In attesa della tua scelta',
			'consent.acceptSelected' => 'Conferma le mie scelte',
			'consent.declineAll' => 'Rifiuta tutto',
			'consent.continueLabel' => 'Continua',
			'consent.privacyPolicyLink' => 'Leggi l\'informativa sulla privacy',
			'consent.reviewNeeded' => 'La nostra politica è cambiata: rivedi le tue scelte.',
			'consent.a11y.purposeToggle' => ({required Object purpose, required Object state}) => '${purpose}, attualmente ${state}',
			'consent.a11y.healthSection' => 'Sezione dati sulla salute, consenso rafforzato',
			'consent.a11y.policyButton' => 'Apri l\'informativa sulla privacy',
			'moderation.reportTitle' => 'Segnala questo contenuto',
			'moderation.reportIntro' => 'Aiutaci a mantenere sana la community. Indica perché questo contenuto ti sembra illecito. La tua segnalazione sarà esaminata da un moderatore.',
			'moderation.reasonLabel' => 'Motivo della segnalazione',
			'moderation.reasons.illegal' => 'Contenuto illegale',
			'moderation.reasons.harassment' => 'Molestie o odio',
			'moderation.reasons.spam' => 'Spam o pubblicità',
			'moderation.reasons.dangerous' => 'Informazione pericolosa o ingannevole',
			'moderation.reasons.other' => 'Altro',
			'moderation.detailsLabel' => 'Aggiungi dettagli (facoltativo)',
			'moderation.detailsHint' => 'Aggiungi un commento per aiutare il moderatore.',
			'moderation.contactLabel' => 'Il tuo indirizzo e-mail',
			'moderation.contactHint' => 'Per tenerti informato sulla gestione (articolo 16).',
			'moderation.goodFaithLabel' => 'Dichiaro in buona fede che queste informazioni sono esatte.',
			'moderation.submit' => 'Invia segnalazione',
			'moderation.submitting' => 'Invio in corso…',
			'moderation.sent' => 'Segnalazione inviata. Grazie, un moderatore la esaminerà.',
			'moderation.errorRequired' => 'Compila il motivo, la tua e-mail e la dichiarazione di buona fede.',
			'moderation.errorGeneric' => 'Impossibile inviare la segnalazione. Riprova.',
			'moderation.cancel' => 'Annulla',
			'moderation.reasonsTitle' => 'Perché questo contenuto è stato limitato?',
			'moderation.reasonsIntro' => 'In conformità all\'articolo 17, ecco il motivo della decisione di moderazione relativa al tuo contenuto.',
			'moderation.decisionLabel' => 'Decisione',
			'moderation.decisions.keep' => 'Contenuto mantenuto',
			'moderation.decisions.restrict' => 'Contenuto limitato',
			'moderation.decisions.remove' => 'Contenuto rimosso',
			'moderation.noStatement' => 'Nessuna restrizione è stata applicata ai tuoi contenuti.',
			'moderation.complaintAction' => 'Contestare questa decisione',
			'moderation.complaintTitle' => 'Contestare una decisione',
			'moderation.complaintIntro' => 'Puoi contestare una decisione di moderazione. Spiega perché ritieni la decisione ingiustificata (articolo 20).',
			'moderation.complaintExposeLabel' => 'La tua contestazione',
			'moderation.complaintExposeHint' => 'Descrivi i motivi della tua contestazione.',
			'moderation.complaintSubmit' => 'Invia contestazione',
			'moderation.complaintSent' => 'Contestazione registrata. Sarà esaminata.',
			'moderation.complaintEmpty' => 'Spiega la tua contestazione.',
			'moderation.a11y.reportForm' => 'Modulo di segnalazione del contenuto',
			'moderation.a11y.reasonSelector' => 'Selettore del motivo della segnalazione',
			'moderation.a11y.goodFaithToggle' => ({required Object state}) => 'Dichiarazione di buona fede, ${state}',
			'moderation.a11y.submitReport' => 'Invia segnalazione',
			'moderation.a11y.statementCard' => 'Motivazione della decisione di moderazione',
			'moderation.a11y.complaintForm' => 'Modulo di contestazione della decisione',
			'bootstrap.loading' => 'Preparazione della tua escursione…',
			_ => null,
		} ?? switch (path) {
			'recap.title' => 'La mia avventura',
			'recap.lockedTitle' => 'Disponibile alla fine del trek',
			'recap.lockedMessage' => 'Termina o abbandona il tuo percorso per rivedere il riepilogo della tua avventura.',
			'recap.finisherTitle' => 'Congratulazioni!',
			'recap.finisherSubtitle' => 'Hai completato il tuo percorso',
			'recap.partialTitle' => 'Il tuo percorso parziale',
			'recap.partialSubtitle' => 'La tua avventura resta registrata',
			'recap.statsSection' => 'Statistiche',
			'recap.traceSection' => 'La tua traccia',
			'recap.noTrace' => 'Nessuna traccia GPS disponibile',
			'recap.stages' => '{done} / {total} tappe percorse',
			'recap.distance' => '{km} km percorsi',
			'recap.elevation' => '{meters} m di dislivello positivo',
			'recap.duration' => '{days} giorni',
			'recap.dates' => 'Dal {start} al {end}',
			'recap.viewDiploma' => 'Vedi il mio diploma',
			'recap.noData' => 'Nessun dato di percorso da mostrare al momento.',
			'programme.title' => 'Programma',
			'programme.helpTooltip' => 'Aiuto',
			'programme.stats.distance' => 'Distanza',
			'programme.stats.elevation' => 'Dislivello+',
			'programme.stats.days' => 'Giorni',
			'programme.stats.stages' => 'Tappe',
			'programme.stats.restCount' => '{count} riposo',
			'programme.legend.easy' => 'Facile',
			'programme.legend.moderate' => 'Moderato',
			'programme.legend.hard' => 'Difficile',
			'programme.legend.extreme' => 'Estremo',
			'programme.restDay' => 'Giorno di riposo',
			'programme.restDayLabel' => 'R',
			'programme.actions.merge' => 'Raggruppa',
			'programme.actions.split' => 'Dividi',
			'programme.actions.rest' => 'Riposo',
			'programme.actions.removeRest' => 'Rimuovi questo giorno di riposo',
			'programme.mergeBlocked.noNext' => 'Nessun giorno successivo',
			'programme.mergeBlocked.rest' => 'Impossibile raggruppare con un giorno di riposo',
			'programme.mergeBlocked.tooLong' => 'Troppo lungo: {hours}h (max {max}h/giorno)',
			'programme.replan' => 'Ripianifica',
			'programme.replanButton' => 'RIPIANIFICA',
			'programme.replanDialog.title' => 'Ripianifica',
			'programme.replanDialog.message' => 'La ripianificazione azzererà il tuo programma.\nI giorni di riposo saranno mantenuti nelle stesse posizioni.',
			'programme.replanDialog.cancel' => 'Annulla',
			'programme.replanDialog.confirm' => 'Ripianifica',
			'programme.validate' => 'CONFERMA IL MIO PROGRAMMA',
			'programme.empty.title' => 'Configura prima il tuo itinerario',
			'programme.empty.message' => 'Scegli il percorso e la durata per generare il tuo programma.',
			'programme.empty.action' => 'CONFIGURA L\'ITINERARIO',
			'programme.info.title' => 'Programma',
			'programme.info.days.title' => 'Giorni di trek',
			'programme.info.days.body' => 'Ogni riga = un giorno. Tocca per vedere il dettaglio completo.',
			'programme.info.reorder.title' => 'Riordina',
			'programme.info.reorder.body' => 'Trascina la maniglia a destra per cambiare l\'ordine dei giorni.',
			'programme.info.rest.title' => 'Giorno di riposo',
			'programme.info.rest.body' => 'Inserisci un giorno di recupero tra due tappe.',
			'programme.info.mergeSplit.title' => 'Raggruppa / Dividi',
			'programme.info.mergeSplit.body' => 'Unisci o dividi le tappe secondo il tuo ritmo.',
			'programme.info.colors.title' => 'Colori',
			'programme.info.colors.body' => 'Verde = facile, Arancione = medio, Rosso = difficile (distanza + dislivello).',
			'programme.info.note' => 'Il profilo altimetrico in basso mostra il dislivello di ogni giorno.',
			'programme.info.close' => 'Capito!',
			'calendar.title' => 'Calendario',
			'calendar.validate' => 'CONFERMA LE DATE',
			'calendar.departure' => 'PARTENZA',
			'calendar.arrival' => 'ARRIVO',
			'calendar.chooseDate' => 'Scegli una data',
			'calendar.chooseDateAction' => 'SCEGLI UNA DATA',
			'calendar.previousMonth' => 'Mese precedente',
			'calendar.nextMonth' => 'Mese successivo',
			'calendar.dayLabel' => 'G{n}',
			'calendar.restDayLabel' => 'R',
			'calendar.adjustStages' => 'REGOLA LE TAPPE',
			'calendar.stageSingular' => 'Tappa {n}',
			'calendar.stagesPlural' => 'Tappe {list}',
			'calendar.splitStages' => 'Separa le tappe',
			'calendar.mergeWithNext' => 'Unisci al giorno successivo',
			'calendar.weekdays.mon' => 'Lun',
			'calendar.weekdays.tue' => 'Mar',
			'calendar.weekdays.wed' => 'Mer',
			'calendar.weekdays.thu' => 'Gio',
			'calendar.weekdays.fri' => 'Ven',
			'calendar.weekdays.sat' => 'Sab',
			'calendar.weekdays.sun' => 'Dom',
			'calendar.legend.start' => 'Partenza',
			'calendar.legend.walk' => 'Cammino',
			'calendar.legend.rest' => 'Riposo',
			'calendar.legend.arrival' => 'Arrivo',
			'calendar.summary.totalDays' => 'Giorni totali',
			'calendar.summary.walkDays' => 'Giorni cammino',
			'calendar.summary.restDays' => 'Giorni riposo',
			'calendar.noDate.title' => 'Scegli una data di partenza',
			'calendar.noDate.message' => 'Il calendario del tuo trek apparirà automaticamente con i giorni di cammino e di riposo.',
			'calendar.empty.title' => 'Configura prima il tuo itinerario',
			'calendar.empty.message' => 'Scegli il percorso e la durata per poter configurare le tue date.',
			'calendar.empty.action' => 'CONFIGURA L\'ITINERARIO',
			'nuitees.title' => 'Pernottamenti',
			'nuitees.guideTooltip' => 'Guida ai pernottamenti',
			'nuitees.infoBar' => 'Prenota ogni notte in anticipo in alta stagione',
			'nuitees.types.refuge' => 'Rifugio',
			'nuitees.types.gite' => 'Ostello',
			'nuitees.types.bivouac' => 'Bivacco',
			'nuitees.types.autreHebergement' => 'Altro alloggio',
			'nuitees.guide.title' => 'Guida ai pernottamenti',
			'nuitees.guide.refuge' => 'Alloggio di montagna, prenotazione consigliata in alta stagione.',
			'nuitees.guide.gite' => 'Ostello di tappa privato, spesso con pasti e docce.',
			'nuitees.guide.bivouac' => 'Campeggio in tenda, secondo la normativa locale.',
			'nuitees.guide.autre' => 'Hotel, bed and breakfast o campeggio fuori dal sentiero.',
			'nuitees.guide.close' => 'Capito',
			'nuitees.card.dayLabel' => 'G{n}',
			'nuitees.card.noPlace' => 'Alloggio',
			'nuitees.card.available' => '{count} alloggi disponibili',
			'nuitees.card.call' => 'Chiama {phone}',
			'nuitees.card.lockedHint' => 'Deseleziona la notte per cambiare il tipo',
			'nuitees.summary.remaining' => '{count} notte/i rimasta/e',
			'nuitees.summary.done' => '{count} OK',
			'nuitees.summary.allBooked' => 'TUTTE LE NOTTI PRENOTATE',
			'nuitees.empty.title' => 'Configura prima il tuo itinerario',
			'nuitees.empty.message' => 'Scegli percorso e durata per preparare i tuoi pernottamenti.',
			'nuitees.empty.action' => 'CONFIGURA ITINERARIO',
			_ => null,
		};
	}
}
