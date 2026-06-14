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
	@override late final _Translations$map$it map = _Translations$map$it._(_root);
	@override late final _Translations$stage$it stage = _Translations$stage$it._(_root);
	@override late final _Translations$trail$it trail = _Translations$trail$it._(_root);
	@override late final _Translations$poi$it poi = _Translations$poi$it._(_root);
	@override late final _Translations$accommodation$it accommodation = _Translations$accommodation$it._(_root);
	@override late final _Translations$gps$it gps = _Translations$gps$it._(_root);
	@override late final _Translations$planning$it planning = _Translations$planning$it._(_root);
	@override late final _Translations$tracking$it tracking = _Translations$tracking$it._(_root);
	@override late final _Translations$checklist$it checklist = _Translations$checklist$it._(_root);
	@override late final _Translations$journal$it journal = _Translations$journal$it._(_root);
	@override late final _Translations$weather$it weather = _Translations$weather$it._(_root);
	@override late final _Translations$share$it share = _Translations$share$it._(_root);
	@override late final _Translations$diploma$it diploma = _Translations$diploma$it._(_root);
	@override late final _Translations$notifications$it notifications = _Translations$notifications$it._(_root);
	@override late final _Translations$settings$it settings = _Translations$settings$it._(_root);
	@override late final _Translations$feedback$it feedback = _Translations$feedback$it._(_root);
	@override late final _Translations$auth$it auth = _Translations$auth$it._(_root);
	@override late final _Translations$feasibility$it feasibility = _Translations$feasibility$it._(_root);
	@override late final _Translations$tips$it tips = _Translations$tips$it._(_root);
	@override late final _Translations$goodies$it goodies = _Translations$goodies$it._(_root);
	@override late final _Translations$noData$it noData = _Translations$noData$it._(_root);
	@override late final _Translations$updates$it updates = _Translations$updates$it._(_root);
	@override late final _Translations$follow$it follow = _Translations$follow$it._(_root);
	@override late final _Translations$cloud$it cloud = _Translations$cloud$it._(_root);
	@override late final _Translations$onboarding$it onboarding = _Translations$onboarding$it._(_root);
	@override late final _Translations$monetization$it monetization = _Translations$monetization$it._(_root);
	@override late final _Translations$signalement$it signalement = _Translations$signalement$it._(_root);
	@override late final _Translations$hebergement$it hebergement = _Translations$hebergement$it._(_root);
	@override late final _Translations$training$it training = _Translations$training$it._(_root);
	@override late final _Translations$eta$it eta = _Translations$eta$it._(_root);
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
}

// Path: nav
class _Translations$nav$it extends Translations$nav$fr {
	_Translations$nav$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get map => 'Mappa';
	@override String get stages => 'Tappe';
	@override String get planning => 'Pianificazione';
	@override String get journal => 'Diario';
	@override String get more => 'Altro';
	@override String get checklist => 'Lista attrezzatura';
	@override String get feasibility => 'Fattibilità';
	@override String get tips => 'Consigli trek';
	@override String get emergency => 'Contatti emergenza';
	@override String get catalog => 'Catalogo sentieri';
	@override String get profile => 'Profilo';
	@override String get settings => 'Impostazioni';
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
}

// Path: checklist
class _Translations$checklist$it extends Translations$checklist$fr {
	_Translations$checklist$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
	@override late final _Translations$checklist$categories$it categories = _Translations$checklist$categories$it._(_root);
	@override late final _Translations$checklist$items$it items = _Translations$checklist$items$it._(_root);
	@override String get essential => 'Essenziale';
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
	@override String get version => 'Versione';
	@override String get versionLabel => 'Versione dell\'app';
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

// Path: stage.difficulty
class _Translations$stage$difficulty$it extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Facile';
	@override String get moderate => 'Moderato';
	@override String get hard => 'Difficile';
	@override String get expert => 'Esperto';
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
	@override String get equipment => 'Equipaggiamento';
	@override String get clothing => 'Abbigliamento';
	@override String get food => 'Alimentazione';
	@override String get safety => 'Sicurezza';
	@override String get documents => 'Documenti';
	@override String get hygiene => 'Igiene';
}

// Path: checklist.items
class _Translations$checklist$items$it extends Translations$checklist$items$fr {
	_Translations$checklist$items$it._(TranslationsIt root) : this._root = root, super.internal(root);

	final TranslationsIt _root; // ignore: unused_field

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
			'nav.map' => 'Mappa',
			'nav.stages' => 'Tappe',
			'nav.planning' => 'Pianificazione',
			'nav.journal' => 'Diario',
			'nav.more' => 'Altro',
			'nav.checklist' => 'Lista attrezzatura',
			'nav.feasibility' => 'Fattibilità',
			'nav.tips' => 'Consigli trek',
			'nav.emergency' => 'Contatti emergenza',
			'nav.catalog' => 'Catalogo sentieri',
			'nav.profile' => 'Profilo',
			'nav.settings' => 'Impostazioni',
			'map.title' => 'Mappa del sentiero',
			'map.loading' => 'Caricamento del tracciato...',
			'map.noTrack' => 'Nessun tracciato disponibile',
			'map.viewMap' => 'Vedi la mappa',
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
			'stage.remaining' => '{distance} km rimanenti',
			'stage.arrived' => 'Sei arrivato!',
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
			'tracking.start' => 'Avvia',
			'tracking.pause' => 'Pausa',
			'tracking.resume' => 'Riprendi',
			'tracking.stop' => 'Ferma',
			'tracking.distance' => 'Distanza',
			'tracking.elevation' => 'Dislivello',
			'tracking.speed' => 'Velocita',
			'tracking.time' => 'Tempo',
			'tracking.confirmStop' => 'Fermare il tracciamento?',
			'checklist.title' => 'Lista equipaggiamento',
			'checklist.subtitle' => 'Prepara lo zaino',
			'checklist.progress' => '{checked}/{total} preparati',
			'checklist.complete' => 'Lista completa!',
			'checklist.reset' => 'Reimposta',
			'checklist.resetConfirm' => 'Reimpostare la lista?',
			'checklist.resetDescription' => 'Tutti gli elementi saranno deselezionati.',
			'checklist.cancel' => 'Annulla',
			'checklist.confirm' => 'Conferma',
			'checklist.categories.equipment' => 'Equipaggiamento',
			'checklist.categories.clothing' => 'Abbigliamento',
			'checklist.categories.food' => 'Alimentazione',
			'checklist.categories.safety' => 'Sicurezza',
			'checklist.categories.documents' => 'Documenti',
			'checklist.categories.hygiene' => 'Igiene',
			'checklist.items.backpack' => 'Zaino',
			'checklist.items.sleepingBag' => 'Sacco a pelo',
			'checklist.items.sleepingPad' => 'Materassino',
			'checklist.items.hikingPoles' => 'Bastoncini da trekking',
			'checklist.items.headlamp' => 'Lampada frontale',
			'checklist.items.waterBottle' => 'Borraccia',
			'checklist.items.hikingBoots' => 'Scarpe da trekking',
			'checklist.items.rainJacket' => 'Giacca impermeabile',
			'checklist.items.warmLayer' => 'Strato caldo',
			'checklist.items.hikingSocks' => 'Calzini da trekking',
			'checklist.items.hat' => 'Cappello',
			'checklist.items.gloves' => 'Guanti',
			'checklist.items.trailSnacks' => 'Snack da sentiero',
			'checklist.items.energyBars' => 'Barrette energetiche',
			'checklist.items.waterPurification' => 'Purificazione dell\'acqua',
			'checklist.items.firstAidKit' => 'Kit di primo soccorso',
			'checklist.items.whistle' => 'Fischietto',
			'checklist.items.emergencyBlanket' => 'Coperta di emergenza',
			'checklist.items.sunscreen' => 'Protezione solare',
			'checklist.items.idCard' => 'Carta d\'identità',
			'checklist.items.insurance' => 'Assicurazione',
			'checklist.items.trailMap' => 'Mappa del sentiero',
			'checklist.items.toiletPaper' => 'Carta igienica',
			'checklist.items.handSanitizer' => 'Disinfettante mani',
			'checklist.items.towel' => 'Asciugamano',
			'checklist.essential' => 'Essenziale',
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
			'settings.version' => 'Versione',
			'settings.versionLabel' => 'Versione dell\'app',
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
			'auth.anonymous' => 'Escursionista anonimo',
			'auth.connectedVia' => 'Connesso tramite',
			'auth.signInGoogle' => 'Accedi con Google',
			'auth.signInGoogleDesc' => 'Per salvare i tuoi progressi',
			'auth.signOut' => 'Esci',
			'auth.signOutDesc' => 'Torna alla modalità anonima',
			'auth.signOutConfirm' => 'Disconnettersi?',
			'auth.signOutMessage' => 'Tornerai alla modalità anonima. I tuoi dati locali saranno conservati.',
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
			_ => null,
		};
	}
}
