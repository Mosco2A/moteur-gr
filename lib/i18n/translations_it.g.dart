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
	@override late final _Translations$map$it map = _Translations$map$it._(_root);
	@override late final _Translations$stage$it stage = _Translations$stage$it._(_root);
	@override late final _Translations$trail$it trail = _Translations$trail$it._(_root);
	@override late final _Translations$poi$it poi = _Translations$poi$it._(_root);
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
			'share.title' => 'Condividi',
			'share.generating' => 'Generazione...',
			'share.share' => 'Condividi',
			'share.error' => 'Errore durante la generazione',
			'diploma.title' => 'Diploma di trekking',
			'diploma.yourName' => 'Il tuo nome',
			'diploma.namePlaceholder' => 'Inserisci il tuo nome...',
			'diploma.generatePdf' => 'Genera PDF',
			'diploma.certifies' => 'Certifica che',
			'diploma.completed' => 'ha percorso il',
			'notifications.morningReminder' => 'Promemoria mattutino',
			'notifications.weatherAlerts' => 'Allerte meteo',
			'notifications.countdown' => 'Promemoria G-2',
			'notifications.countdownDesc' => 'Notifica 2 giorni prima della partenza',
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
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Tipo di feedback',
			'feedback.bug' => 'Bug / Problema',
			'feedback.suggestion' => 'Suggerimento',
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
			_ => null,
		};
	}
}
