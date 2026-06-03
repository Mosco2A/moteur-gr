///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$map$en map = Translations$map$en._(_root);
	late final Translations$stage$en stage = Translations$stage$en._(_root);
	late final Translations$trail$en trail = Translations$trail$en._(_root);
	late final Translations$poi$en poi = Translations$poi$en._(_root);
	late final Translations$gps$en gps = Translations$gps$en._(_root);
	late final Translations$planning$en planning = Translations$planning$en._(_root);
	late final Translations$tracking$en tracking = Translations$tracking$en._(_root);
	late final Translations$checklist$en checklist = Translations$checklist$en._(_root);
	late final Translations$journal$en journal = Translations$journal$en._(_root);
	late final Translations$weather$en weather = Translations$weather$en._(_root);
	late final Translations$share$en share = Translations$share$en._(_root);
	late final Translations$diploma$en diploma = Translations$diploma$en._(_root);
	late final Translations$notifications$en notifications = Translations$notifications$en._(_root);
	late final Translations$settings$en settings = Translations$settings$en._(_root);
	late final Translations$feedback$en feedback = Translations$feedback$en._(_root);
	late final Translations$auth$en auth = Translations$auth$en._(_root);
	late final Translations$feasibility$en feasibility = Translations$feasibility$en._(_root);
	late final Translations$tips$en tips = Translations$tips$en._(_root);
	late final Translations$goodies$en goodies = Translations$goodies$en._(_root);
}

// Path: map
class Translations$map$en {
	Translations$map$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trail map'
	String get title => 'Trail map';

	/// en: 'Loading track...'
	String get loading => 'Loading track...';

	/// en: 'No track available'
	String get noTrack => 'No track available';

	/// en: 'View map'
	String get viewMap => 'View map';
}

// Path: stage
class Translations$stage$en {
	Translations$stage$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Distance'
	String get distance => 'Distance';

	/// en: 'Elevation'
	String get elevation => 'Elevation';

	/// en: 'Elevation gain'
	String get elevationGain => 'Elevation gain';

	/// en: 'Elevation loss'
	String get elevationLoss => 'Elevation loss';

	/// en: 'Estimated duration'
	String get duration => 'Estimated duration';

	/// en: 'Description'
	String get description => 'Description';

	/// en: 'Coordinates'
	String get coordinates => 'Coordinates';

	/// en: 'Points of interest'
	String get pois => 'Points of interest';

	late final Translations$stage$difficulty$en difficulty = Translations$stage$difficulty$en._(_root);

	/// en: '{distance} km remaining'
	String get remaining => '{distance} km remaining';

	/// en: 'You have arrived!'
	String get arrived => 'You have arrived!';
}

// Path: trail
class Translations$trail$en {
	Translations$trail$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Stages'
	String get stages => 'Stages';

	/// en: 'Total distance'
	String get totalDistance => 'Total distance';

	/// en: 'Total elevation'
	String get totalElevation => 'Total elevation';
}

// Path: poi
class Translations$poi$en {
	Translations$poi$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Shelter'
	String get shelter => 'Shelter';

	/// en: 'Water source'
	String get water => 'Water source';

	/// en: 'Viewpoint'
	String get viewpoint => 'Viewpoint';

	/// en: 'Campsite'
	String get campsite => 'Campsite';

	/// en: 'Restaurant'
	String get restaurant => 'Restaurant';

	/// en: 'Emergency'
	String get emergency => 'Emergency';

	/// en: 'Danger'
	String get danger => 'Danger';

	/// en: 'Shop'
	String get shop => 'Shop';

	/// en: 'Filter points of interest'
	String get filter => 'Filter points of interest';

	/// en: 'Altitude'
	String get altitude => 'Altitude';

	/// en: 'Opening hours'
	String get hours => 'Opening hours';
}

// Path: gps
class Translations$gps$en {
	Translations$gps$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'GPS permission required'
	String get permission => 'GPS permission required';

	/// en: 'Location access denied'
	String get denied => 'Location access denied';

	/// en: 'Location service disabled'
	String get disabled => 'Location service disabled';

	/// en: 'Off track'
	String get offTrack => 'Off track';

	/// en: 'Center on my position'
	String get centerOnMe => 'Center on my position';
}

// Path: planning
class Translations$planning$en {
	Translations$planning$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Planning'
	String get title => 'Planning';

	/// en: 'Duration'
	String get duration => 'Duration';

	/// en: 'days'
	String get days => 'days';

	/// en: 'Day'
	String get day => 'Day';

	/// en: 'Rest day'
	String get restDay => 'Rest day';

	/// en: 'Total distance'
	String get totalDistance => 'Total distance';

	/// en: 'Total elevation'
	String get totalElevation => 'Total elevation';

	/// en: 'Estimated time'
	String get estimatedTime => 'Estimated time';

	/// en: 'Stages'
	String get stages => 'Stages';

	/// en: 'Plan'
	String get plan => 'Plan';
}

// Path: tracking
class Translations$tracking$en {
	Translations$tracking$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start'
	String get start => 'Start';

	/// en: 'Pause'
	String get pause => 'Pause';

	/// en: 'Resume'
	String get resume => 'Resume';

	/// en: 'Stop'
	String get stop => 'Stop';

	/// en: 'Distance'
	String get distance => 'Distance';

	/// en: 'Elevation'
	String get elevation => 'Elevation';

	/// en: 'Speed'
	String get speed => 'Speed';

	/// en: 'Time'
	String get time => 'Time';

	/// en: 'Stop tracking?'
	String get confirmStop => 'Stop tracking?';
}

// Path: checklist
class Translations$checklist$en {
	Translations$checklist$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Gear checklist'
	String get title => 'Gear checklist';

	/// en: 'Pack your backpack'
	String get subtitle => 'Pack your backpack';

	/// en: '{checked}/{total} packed'
	String get progress => '{checked}/{total} packed';

	/// en: 'Checklist complete!'
	String get complete => 'Checklist complete!';

	/// en: 'Reset'
	String get reset => 'Reset';

	/// en: 'Reset checklist?'
	String get resetConfirm => 'Reset checklist?';

	/// en: 'All items will be unchecked.'
	String get resetDescription => 'All items will be unchecked.';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Confirm'
	String get confirm => 'Confirm';

	late final Translations$checklist$categories$en categories = Translations$checklist$categories$en._(_root);
	late final Translations$checklist$items$en items = Translations$checklist$items$en._(_root);

	/// en: 'Essential'
	String get essential => 'Essential';
}

// Path: journal
class Translations$journal$en {
	Translations$journal$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trek journal'
	String get title => 'Trek journal';

	/// en: 'Your journal is empty'
	String get empty => 'Your journal is empty';

	/// en: 'Write down your trek impressions and memories'
	String get emptySubtitle => 'Write down your trek impressions and memories';

	/// en: 'New note'
	String get addNote => 'New note';

	/// en: 'Stage'
	String get stage => 'Stage';

	/// en: 'Your note'
	String get yourNote => 'Your note';

	/// en: 'Describe your hiking day...'
	String get placeholder => 'Describe your hiking day...';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Delete'
	String get delete => 'Delete';

	/// en: '3 photos per day limit reached'
	String get photoLimit => '3 photos per day limit reached';

	/// en: 'Photo too large (max 500 KB)'
	String get photoTooBig => 'Photo too large (max 500 KB)';
}

// Path: weather
class Translations$weather$en {
	Translations$weather$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Weather'
	String get title => 'Weather';

	/// en: 'Loading weather...'
	String get loading => 'Loading weather...';

	/// en: 'No connection. Weather data unavailable.'
	String get offline => 'No connection. Weather data unavailable.';

	/// en: 'Unable to load weather.'
	String get error => 'Unable to load weather.';

	/// en: 'Cached data'
	String get cached => 'Cached data';

	/// en: 'weather alerts'
	String get alerts => 'weather alerts';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'Temperature'
	String get temperature => 'Temperature';

	/// en: 'Precipitation'
	String get precipitation => 'Precipitation';

	/// en: 'Wind'
	String get wind => 'Wind';

	/// en: 'UV index'
	String get uv => 'UV index';

	/// en: 'Fire risk'
	String get fireRisk => 'Fire risk';

	/// en: 'High fire risk. Check safety instructions.'
	String get fireRiskDesc => 'High fire risk. Check safety instructions.';

	/// en: 'Fire safety tips'
	String get fireSafetyTips => 'Fire safety tips';

	/// en: 'alert'
	String get alertCount => 'alert';

	/// en: 'alerts'
	String get alertCountPlural => 'alerts';
}

// Path: share
class Translations$share$en {
	Translations$share$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Share'
	String get title => 'Share';

	/// en: 'Generating...'
	String get generating => 'Generating...';

	/// en: 'Share'
	String get share => 'Share';

	/// en: 'Error during generation'
	String get error => 'Error during generation';

	/// en: 'Error during sharing'
	String get errorShare => 'Error during sharing';

	/// en: 'Preview'
	String get preview => 'Preview';

	/// en: 'Choose a template'
	String get chooseTemplate => 'Choose a template';

	/// en: 'Statistics'
	String get templateStats => 'Statistics';

	/// en: 'Journey'
	String get templateJourney => 'Journey';

	/// en: 'Stage'
	String get templateStage => 'Stage';
}

// Path: diploma
class Translations$diploma$en {
	Translations$diploma$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trek diploma'
	String get title => 'Trek diploma';

	/// en: 'Your name'
	String get yourName => 'Your name';

	/// en: 'Enter your name...'
	String get namePlaceholder => 'Enter your name...';

	/// en: 'Generate PDF'
	String get generatePdf => 'Generate PDF';

	/// en: 'Certifies that'
	String get certifies => 'Certifies that';

	/// en: 'completed the'
	String get completed => 'completed the';

	/// en: 'DIPLOMA'
	String get pdfTitle => 'DIPLOMA';

	/// en: 'Certificate of achievement'
	String get pdfSubtitle => 'Certificate of achievement';

	/// en: '{count} stages'
	String get pdfStages => '{count} stages';

	/// en: '{km} km covered'
	String get pdfDistance => '{km} km covered';

	/// en: '{meters} m elevation gain'
	String get pdfElevation => '{meters} m elevation gain';

	/// en: 'in {days} days'
	String get pdfDuration => 'in {days} days';

	/// en: 'From'
	String get pdfFrom => 'From';

	/// en: 'to'
	String get pdfTo => 'to';

	/// en: 'Issued on {date}'
	String get pdfIssuedOn => 'Issued on {date}';

	/// en: 'Your adventure'
	String get recapTitle => 'Your adventure';

	/// en: 'Journal photos'
	String get recapJournalPhotos => 'Journal photos';

	/// en: 'No photos in journal'
	String get recapNoPhotos => 'No photos in journal';

	/// en: 'Statistics'
	String get recapStats => 'Statistics';

	/// en: '{count} stages completed'
	String get recapStages => '{count} stages completed';

	/// en: '{km} km covered'
	String get recapDistance => '{km} km covered';

	/// en: '{meters} m elevation'
	String get recapElevation => '{meters} m elevation';

	/// en: '{days} days of trekking'
	String get recapDuration => '{days} days of trekking';

	/// en: 'Route trace'
	String get recapMapTrace => 'Route trace';

	/// en: 'Trace not available'
	String get recapNoMap => 'Trace not available';

	/// en: '{count} journal entries'
	String get recapJournalEntries => '{count} journal entries';

	/// en: 'Download diploma PDF'
	String get downloadPdf => 'Download diploma PDF';
}

// Path: notifications
class Translations$notifications$en {
	Translations$notifications$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Morning reminder'
	String get morningReminder => 'Morning reminder';

	/// en: 'Weather alerts'
	String get weatherAlerts => 'Weather alerts';

	/// en: 'D-2 reminder'
	String get countdown => 'D-2 reminder';

	/// en: 'Notification 2 days before departure'
	String get countdownDesc => 'Notification 2 days before departure';

	/// en: 'Your trek is coming up!'
	String get schedulerCountdownTitle => 'Your trek is coming up!';

	/// en: 'Departure in 2 days. Check your checklist and the weather.'
	String get schedulerCountdownBody => 'Departure in 2 days. Check your checklist and the weather.';

	/// en: 'Have a great trek day!'
	String get schedulerDailyTitle => 'Have a great trek day!';

	/// en: 'Check the weather and prepare today's stage.'
	String get schedulerDailyBody => 'Check the weather and prepare today\'s stage.';

	/// en: 'Remember to download your trail!'
	String get downloadReminderTitle => 'Remember to download your trail!';

	/// en: 'Departure in 2 days. Download your trail for offline mode.'
	String get downloadReminderBody => 'Departure in 2 days. Download your trail for offline mode.';
}

// Path: settings
class Translations$settings$en {
	Translations$settings$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Settings'
	String get title => 'Settings';

	/// en: 'Language'
	String get language => 'Language';

	/// en: 'Units'
	String get units => 'Units';

	/// en: 'Distance'
	String get distance => 'Distance';

	/// en: 'Temperature'
	String get temperature => 'Temperature';

	/// en: 'Theme'
	String get theme => 'Theme';

	/// en: 'Dark'
	String get dark => 'Dark';

	/// en: 'Light'
	String get light => 'Light';

	/// en: 'System'
	String get system => 'System';

	/// en: 'Cache'
	String get cache => 'Cache';

	/// en: 'Cache enabled'
	String get cacheEnabled => 'Cache enabled';

	/// en: 'Data available offline'
	String get cacheDesc => 'Data available offline';

	/// en: 'Cache size'
	String get cacheSize => 'Cache size';

	/// en: 'Notifications'
	String get notifications => 'Notifications';

	/// en: 'Morning reminder'
	String get morningReminder => 'Morning reminder';

	/// en: 'Weather alerts'
	String get weatherAlerts => 'Weather alerts';

	/// en: 'Notified when dangerous conditions'
	String get weatherAlertsDesc => 'Notified when dangerous conditions';

	/// en: 'D-2 reminder'
	String get countdownReminder => 'D-2 reminder';

	/// en: 'Notification 2 days before departure'
	String get countdownDesc => 'Notification 2 days before departure';

	/// en: 'Version'
	String get version => 'Version';

	/// en: 'App version'
	String get versionLabel => 'App version';
}

// Path: feedback
class Translations$feedback$en {
	Translations$feedback$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Feedback'
	String get title => 'Feedback';

	/// en: 'Feedback type'
	String get type => 'Feedback type';

	/// en: 'Bug / Problem'
	String get bug => 'Bug / Problem';

	/// en: 'Suggestion'
	String get suggestion => 'Suggestion';

	/// en: 'Compliment'
	String get compliment => 'Compliment';

	/// en: 'Question'
	String get question => 'Question';

	/// en: 'Other'
	String get other => 'Other';

	/// en: 'Your message'
	String get message => 'Your message';

	/// en: 'Describe your feedback...'
	String get messagePlaceholder => 'Describe your feedback...';

	/// en: 'Satisfaction'
	String get satisfaction => 'Satisfaction';

	/// en: 'Send'
	String get send => 'Send';

	/// en: 'Sending...'
	String get sending => 'Sending...';

	/// en: 'Thank you for your feedback!'
	String get thanks => 'Thank you for your feedback!';

	/// en: 'pending'
	String get pending => 'pending';
}

// Path: auth
class Translations$auth$en {
	Translations$auth$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Profile'
	String get profile => 'Profile';

	/// en: 'Anonymous hiker'
	String get anonymous => 'Anonymous hiker';

	/// en: 'Connected via'
	String get connectedVia => 'Connected via';

	/// en: 'Sign in with Google'
	String get signInGoogle => 'Sign in with Google';

	/// en: 'To save your progress'
	String get signInGoogleDesc => 'To save your progress';

	/// en: 'Sign out'
	String get signOut => 'Sign out';

	/// en: 'Return to anonymous mode'
	String get signOutDesc => 'Return to anonymous mode';

	/// en: 'Sign out?'
	String get signOutConfirm => 'Sign out?';

	/// en: 'You will return to anonymous mode. Your local data is preserved.'
	String get signOutMessage => 'You will return to anonymous mode. Your local data is preserved.';

	/// en: 'Delete my account'
	String get deleteAccount => 'Delete my account';

	/// en: 'All your data will be erased'
	String get deleteAccountDesc => 'All your data will be erased';

	/// en: 'Delete your account?'
	String get deleteConfirm => 'Delete your account?';

	/// en: 'This action is irreversible. All your data, notes and progress will be erased.'
	String get deleteMessage => 'This action is irreversible. All your data, notes and progress will be erased.';

	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// en: 'Nickname'
	String get pseudonym => 'Nickname';

	/// en: 'Your hiker name'
	String get pseudonymHint => 'Your hiker name';

	/// en: 'Save'
	String get save => 'Save';

	/// en: 'Change avatar'
	String get changeAvatar => 'Change avatar';

	/// en: 'Choose an avatar'
	String get chooseAvatar => 'Choose an avatar';

	/// en: 'Loading error'
	String get errorLoading => 'Loading error';
}

// Path: feasibility
class Translations$feasibility$en {
	Translations$feasibility$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Feasibility'
	String get title => 'Feasibility';

	/// en: 'Assess your preparation'
	String get subtitle => 'Assess your preparation';

	/// en: 'Previous'
	String get previous => 'Previous';

	/// en: 'Start over'
	String get restart => 'Start over';

	/// en: 'Your result'
	String get resultTitle => 'Your result';

	/// en: 'Areas to improve'
	String get weakPointsTitle => 'Areas to improve';

	/// en: 'Strong points'
	String get strongPointsTitle => 'Strong points';

	/// en: '{current}/{total}'
	String get progress => '{current}/{total}';

	late final Translations$feasibility$levels$en levels = Translations$feasibility$levels$en._(_root);
	late final Translations$feasibility$categories$en categories = Translations$feasibility$categories$en._(_root);
	late final Translations$feasibility$questions$en questions = Translations$feasibility$questions$en._(_root);
	late final Translations$feasibility$answers$en answers = Translations$feasibility$answers$en._(_root);

	/// en: 'See recommendations'
	String get seeRecommendations => 'See recommendations';

	/// en: 'Your profile'
	String get yourProfile => 'Your profile';

	/// en: 'Our tips'
	String get tipsTitle => 'Our tips';

	late final Translations$feasibility$recommendations$en recommendations = Translations$feasibility$recommendations$en._(_root);
}

// Path: tips
class Translations$tips$en {
	Translations$tips$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Trek tips'
	String get carouselTitle => 'Trek tips';

	/// en: 'All'
	String get allCategories => 'All';

	/// en: 'Swipe for more'
	String get swipeHint => 'Swipe for more';

	/// en: 'Tip detail'
	String get detailTitle => 'Tip detail';

	/// en: 'Read more'
	String get readMore => 'Read more';

	/// en: 'No tips available'
	String get noTips => 'No tips available';

	/// en: 'Preparation'
	String get categoryPreparation => 'Preparation';

	/// en: 'Equipment'
	String get categoryEquipment => 'Equipment';

	/// en: 'Nutrition'
	String get categoryNutrition => 'Nutrition';

	/// en: 'Safety'
	String get categorySafety => 'Safety';

	/// en: 'Nature'
	String get categoryNature => 'Nature';

	/// en: 'Recovery'
	String get categoryRecovery => 'Recovery';

	/// en: 'General'
	String get categoryGeneral => 'General';

	/// en: 'High priority'
	String get priorityHigh => 'High priority';

	/// en: 'Trail'
	String get scope => 'Trail';

	/// en: 'Season'
	String get season => 'Season';

	/// en: 'Min. altitude'
	String get altitude => 'Min. altitude';
}

// Path: goodies
class Translations$goodies$en {
	Translations$goodies$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Goodies Shop'
	String get title => 'Goodies Shop';

	/// en: 'This module is coming soon. Stay tuned!'
	String get comingSoon => 'This module is coming soon. Stay tuned!';
}

// Path: stage.difficulty
class Translations$stage$difficulty$en {
	Translations$stage$difficulty$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Easy'
	String get easy => 'Easy';

	/// en: 'Moderate'
	String get moderate => 'Moderate';

	/// en: 'Hard'
	String get hard => 'Hard';

	/// en: 'Expert'
	String get expert => 'Expert';
}

// Path: checklist.categories
class Translations$checklist$categories$en {
	Translations$checklist$categories$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Equipment'
	String get equipment => 'Equipment';

	/// en: 'Clothing'
	String get clothing => 'Clothing';

	/// en: 'Food'
	String get food => 'Food';

	/// en: 'Safety'
	String get safety => 'Safety';

	/// en: 'Documents'
	String get documents => 'Documents';

	/// en: 'Hygiene'
	String get hygiene => 'Hygiene';
}

// Path: checklist.items
class Translations$checklist$items$en {
	Translations$checklist$items$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Backpack'
	String get backpack => 'Backpack';

	/// en: 'Sleeping bag'
	String get sleepingBag => 'Sleeping bag';

	/// en: 'Sleeping pad'
	String get sleepingPad => 'Sleeping pad';

	/// en: 'Hiking poles'
	String get hikingPoles => 'Hiking poles';

	/// en: 'Headlamp'
	String get headlamp => 'Headlamp';

	/// en: 'Water bottle'
	String get waterBottle => 'Water bottle';

	/// en: 'Hiking boots'
	String get hikingBoots => 'Hiking boots';

	/// en: 'Rain jacket'
	String get rainJacket => 'Rain jacket';

	/// en: 'Warm layer'
	String get warmLayer => 'Warm layer';

	/// en: 'Hiking socks'
	String get hikingSocks => 'Hiking socks';

	/// en: 'Hat'
	String get hat => 'Hat';

	/// en: 'Gloves'
	String get gloves => 'Gloves';

	/// en: 'Trail snacks'
	String get trailSnacks => 'Trail snacks';

	/// en: 'Energy bars'
	String get energyBars => 'Energy bars';

	/// en: 'Water purification'
	String get waterPurification => 'Water purification';

	/// en: 'First aid kit'
	String get firstAidKit => 'First aid kit';

	/// en: 'Whistle'
	String get whistle => 'Whistle';

	/// en: 'Emergency blanket'
	String get emergencyBlanket => 'Emergency blanket';

	/// en: 'Sunscreen'
	String get sunscreen => 'Sunscreen';

	/// en: 'ID card'
	String get idCard => 'ID card';

	/// en: 'Insurance'
	String get insurance => 'Insurance';

	/// en: 'Trail map'
	String get trailMap => 'Trail map';

	/// en: 'Toilet paper'
	String get toiletPaper => 'Toilet paper';

	/// en: 'Hand sanitizer'
	String get handSanitizer => 'Hand sanitizer';

	/// en: 'Towel'
	String get towel => 'Towel';
}

// Path: feasibility.levels
class Translations$feasibility$levels$en {
	Translations$feasibility$levels$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Not recommended'
	String get danger => 'Not recommended';

	/// en: 'Preparation needed'
	String get caution => 'Preparation needed';

	/// en: 'Feasible'
	String get good => 'Feasible';

	/// en: 'Excellent'
	String get excellent => 'Excellent';
}

// Path: feasibility.categories
class Translations$feasibility$categories$en {
	Translations$feasibility$categories$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Physical fitness'
	String get fitness => 'Physical fitness';

	/// en: 'Experience'
	String get experience => 'Experience';

	/// en: 'Equipment'
	String get gear => 'Equipment';

	/// en: 'Weather'
	String get weather => 'Weather';

	/// en: 'Duration'
	String get duration => 'Duration';

	/// en: 'Companions'
	String get companion => 'Companions';

	/// en: 'Health'
	String get health => 'Health';

	/// en: 'Motivation'
	String get motivation => 'Motivation';
}

// Path: feasibility.questions
class Translations$feasibility$questions$en {
	Translations$feasibility$questions$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'What is your physical fitness level?'
	String get fitnessQuestion => 'What is your physical fitness level?';

	/// en: 'What is your hiking experience?'
	String get experienceQuestion => 'What is your hiking experience?';

	/// en: 'What is the state of your equipment?'
	String get gearQuestion => 'What is the state of your equipment?';

	/// en: 'Have you checked weather conditions?'
	String get weatherQuestion => 'Have you checked weather conditions?';

	/// en: 'How many days do you plan?'
	String get durationQuestion => 'How many days do you plan?';

	/// en: 'Are you hiking with others?'
	String get companionQuestion => 'Are you hiking with others?';

	/// en: 'Do you have any health concerns?'
	String get healthQuestion => 'Do you have any health concerns?';

	/// en: 'What is your motivation level?'
	String get motivationQuestion => 'What is your motivation level?';
}

// Path: feasibility.answers
class Translations$feasibility$answers$en {
	Translations$feasibility$answers$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Sedentary, no training'
	String get fitnessA => 'Sedentary, no training';

	/// en: 'Occasional physical activity'
	String get fitnessB => 'Occasional physical activity';

	/// en: 'Regular exercise (2-3x/week)'
	String get fitnessC => 'Regular exercise (2-3x/week)';

	/// en: 'Seasoned athlete, specifically trained'
	String get fitnessD => 'Seasoned athlete, specifically trained';

	/// en: 'No hiking experience'
	String get experienceA => 'No hiking experience';

	/// en: 'A few day hikes'
	String get experienceB => 'A few day hikes';

	/// en: 'Multi-day hikes completed'
	String get experienceC => 'Multi-day hikes completed';

	/// en: 'Experienced trekker, long trails done'
	String get experienceD => 'Experienced trekker, long trails done';

	/// en: 'Incomplete or unsuitable gear'
	String get gearA => 'Incomplete or unsuitable gear';

	/// en: 'Basic gear, some items missing'
	String get gearB => 'Basic gear, some items missing';

	/// en: 'Complete gear, good condition'
	String get gearC => 'Complete gear, good condition';

	/// en: 'Technical gear, tested and proven'
	String get gearD => 'Technical gear, tested and proven';

	/// en: 'Not checked, no idea'
	String get weatherA => 'Not checked, no idea';

	/// en: 'Briefly checked, uncertain conditions'
	String get weatherB => 'Briefly checked, uncertain conditions';

	/// en: 'Checked, fair conditions expected'
	String get weatherC => 'Checked, fair conditions expected';

	/// en: 'Thoroughly checked, favorable window'
	String get weatherD => 'Thoroughly checked, favorable window';

	/// en: 'No idea of the duration'
	String get durationA => 'No idea of the duration';

	/// en: 'Underestimated or too ambitious'
	String get durationB => 'Underestimated or too ambitious';

	/// en: 'Realistic plan with margins'
	String get durationC => 'Realistic plan with margins';

	/// en: 'Detailed plan, rest days included'
	String get durationD => 'Detailed plan, rest days included';

	/// en: 'Solo, no solo experience'
	String get companionA => 'Solo, no solo experience';

	/// en: 'Solo, but experienced'
	String get companionB => 'Solo, but experienced';

	/// en: 'In a group, mixed levels'
	String get companionC => 'In a group, mixed levels';

	/// en: 'In a group, all experienced'
	String get companionD => 'In a group, all experienced';

	/// en: 'Untreated health issues'
	String get healthA => 'Untreated health issues';

	/// en: 'Minor issues, under control'
	String get healthB => 'Minor issues, under control';

	/// en: 'Generally good health'
	String get healthC => 'Generally good health';

	/// en: 'Excellent health, recent checkup'
	String get healthD => 'Excellent health, recent checkup';

	/// en: 'Low motivation, hesitant'
	String get motivationA => 'Low motivation, hesitant';

	/// en: 'Motivated but anxious'
	String get motivationB => 'Motivated but anxious';

	/// en: 'Motivated and determined'
	String get motivationC => 'Motivated and determined';

	/// en: 'Absolute passion, long-time dream'
	String get motivationD => 'Absolute passion, long-time dream';
}

// Path: feasibility.recommendations
class Translations$feasibility$recommendations$en {
	Translations$feasibility$recommendations$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$feasibility$recommendations$danger$en danger = Translations$feasibility$recommendations$danger$en._(_root);
	late final Translations$feasibility$recommendations$caution$en caution = Translations$feasibility$recommendations$caution$en._(_root);
	late final Translations$feasibility$recommendations$good$en good = Translations$feasibility$recommendations$good$en._(_root);
	late final Translations$feasibility$recommendations$excellent$en excellent = Translations$feasibility$recommendations$excellent$en._(_root);
}

// Path: feasibility.recommendations.danger
class Translations$feasibility$recommendations$danger$en {
	Translations$feasibility$recommendations$danger$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Insufficient preparation'
	String get title => 'Insufficient preparation';

	/// en: 'Your profile shows significant gaps. We do not recommend starting in this state.'
	String get summary => 'Your profile shows significant gaps. We do not recommend starting in this state.';

	late final Translations$feasibility$recommendations$danger$tips$en tips = Translations$feasibility$recommendations$danger$tips$en._(_root);
}

// Path: feasibility.recommendations.caution
class Translations$feasibility$recommendations$caution$en {
	Translations$feasibility$recommendations$caution$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Preparation needs work'
	String get title => 'Preparation needs work';

	/// en: 'You have a foundation, but some areas need attention before departure.'
	String get summary => 'You have a foundation, but some areas need attention before departure.';

	late final Translations$feasibility$recommendations$caution$tips$en tips = Translations$feasibility$recommendations$caution$tips$en._(_root);
}

// Path: feasibility.recommendations.good
class Translations$feasibility$recommendations$good$en {
	Translations$feasibility$recommendations$good$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Good preparation'
	String get title => 'Good preparation';

	/// en: 'Your profile is solid. A few adjustments and you will be ready.'
	String get summary => 'Your profile is solid. A few adjustments and you will be ready.';

	late final Translations$feasibility$recommendations$good$tips$en tips = Translations$feasibility$recommendations$good$tips$en._(_root);
}

// Path: feasibility.recommendations.excellent
class Translations$feasibility$recommendations$excellent$en {
	Translations$feasibility$recommendations$excellent$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Optimal preparation'
	String get title => 'Optimal preparation';

	/// en: 'You are perfectly prepared. Enjoy the trek with peace of mind!'
	String get summary => 'You are perfectly prepared. Enjoy the trek with peace of mind!';

	late final Translations$feasibility$recommendations$excellent$tips$en tips = Translations$feasibility$recommendations$excellent$tips$en._(_root);
}

// Path: feasibility.recommendations.danger.tips
class Translations$feasibility$recommendations$danger$tips$en {
	Translations$feasibility$recommendations$danger$tips$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start with short hikes to assess your fitness level'
	String get tip1 => 'Start with short hikes to assess your fitness level';

	/// en: 'Consult a healthcare professional before prolonged effort'
	String get tip2 => 'Consult a healthcare professional before prolonged effort';

	/// en: 'Invest in proper equipment and test it beforehand'
	String get tip3 => 'Invest in proper equipment and test it beforehand';
}

// Path: feasibility.recommendations.caution.tips
class Translations$feasibility$recommendations$caution$tips$en {
	Translations$feasibility$recommendations$caution$tips$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Strengthen your physical training 6 to 8 weeks ahead'
	String get tip1 => 'Strengthen your physical training 6 to 8 weeks ahead';

	/// en: 'Check and complete your equipment'
	String get tip2 => 'Check and complete your equipment';

	/// en: 'Plan stages suited to your level'
	String get tip3 => 'Plan stages suited to your level';
}

// Path: feasibility.recommendations.good.tips
class Translations$feasibility$recommendations$good$tips$en {
	Translations$feasibility$recommendations$good$tips$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Maintain your training pace until departure'
	String get tip1 => 'Maintain your training pace until departure';

	/// en: 'Include margins in your planning'
	String get tip2 => 'Include margins in your planning';

	/// en: 'Check the weather regularly before departure'
	String get tip3 => 'Check the weather regularly before departure';
}

// Path: feasibility.recommendations.excellent.tips
class Translations$feasibility$recommendations$excellent$tips$en {
	Translations$feasibility$recommendations$excellent$tips$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Listen to your body during the trek'
	String get tip1 => 'Listen to your body during the trek';

	/// en: 'Share your experience with fellow hikers'
	String get tip2 => 'Share your experience with fellow hikers';

	/// en: 'Consider documenting your adventure in the journal'
	String get tip3 => 'Consider documenting your adventure in the journal';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'map.title' => 'Trail map',
			'map.loading' => 'Loading track...',
			'map.noTrack' => 'No track available',
			'map.viewMap' => 'View map',
			'stage.distance' => 'Distance',
			'stage.elevation' => 'Elevation',
			'stage.elevationGain' => 'Elevation gain',
			'stage.elevationLoss' => 'Elevation loss',
			'stage.duration' => 'Estimated duration',
			'stage.description' => 'Description',
			'stage.coordinates' => 'Coordinates',
			'stage.pois' => 'Points of interest',
			'stage.difficulty.easy' => 'Easy',
			'stage.difficulty.moderate' => 'Moderate',
			'stage.difficulty.hard' => 'Hard',
			'stage.difficulty.expert' => 'Expert',
			'stage.remaining' => '{distance} km remaining',
			'stage.arrived' => 'You have arrived!',
			'trail.stages' => 'Stages',
			'trail.totalDistance' => 'Total distance',
			'trail.totalElevation' => 'Total elevation',
			'poi.shelter' => 'Shelter',
			'poi.water' => 'Water source',
			'poi.viewpoint' => 'Viewpoint',
			'poi.campsite' => 'Campsite',
			'poi.restaurant' => 'Restaurant',
			'poi.emergency' => 'Emergency',
			'poi.danger' => 'Danger',
			'poi.shop' => 'Shop',
			'poi.filter' => 'Filter points of interest',
			'poi.altitude' => 'Altitude',
			'poi.hours' => 'Opening hours',
			'gps.permission' => 'GPS permission required',
			'gps.denied' => 'Location access denied',
			'gps.disabled' => 'Location service disabled',
			'gps.offTrack' => 'Off track',
			'gps.centerOnMe' => 'Center on my position',
			'planning.title' => 'Planning',
			'planning.duration' => 'Duration',
			'planning.days' => 'days',
			'planning.day' => 'Day',
			'planning.restDay' => 'Rest day',
			'planning.totalDistance' => 'Total distance',
			'planning.totalElevation' => 'Total elevation',
			'planning.estimatedTime' => 'Estimated time',
			'planning.stages' => 'Stages',
			'planning.plan' => 'Plan',
			'tracking.start' => 'Start',
			'tracking.pause' => 'Pause',
			'tracking.resume' => 'Resume',
			'tracking.stop' => 'Stop',
			'tracking.distance' => 'Distance',
			'tracking.elevation' => 'Elevation',
			'tracking.speed' => 'Speed',
			'tracking.time' => 'Time',
			'tracking.confirmStop' => 'Stop tracking?',
			'checklist.title' => 'Gear checklist',
			'checklist.subtitle' => 'Pack your backpack',
			'checklist.progress' => '{checked}/{total} packed',
			'checklist.complete' => 'Checklist complete!',
			'checklist.reset' => 'Reset',
			'checklist.resetConfirm' => 'Reset checklist?',
			'checklist.resetDescription' => 'All items will be unchecked.',
			'checklist.cancel' => 'Cancel',
			'checklist.confirm' => 'Confirm',
			'checklist.categories.equipment' => 'Equipment',
			'checklist.categories.clothing' => 'Clothing',
			'checklist.categories.food' => 'Food',
			'checklist.categories.safety' => 'Safety',
			'checklist.categories.documents' => 'Documents',
			'checklist.categories.hygiene' => 'Hygiene',
			'checklist.items.backpack' => 'Backpack',
			'checklist.items.sleepingBag' => 'Sleeping bag',
			'checklist.items.sleepingPad' => 'Sleeping pad',
			'checklist.items.hikingPoles' => 'Hiking poles',
			'checklist.items.headlamp' => 'Headlamp',
			'checklist.items.waterBottle' => 'Water bottle',
			'checklist.items.hikingBoots' => 'Hiking boots',
			'checklist.items.rainJacket' => 'Rain jacket',
			'checklist.items.warmLayer' => 'Warm layer',
			'checklist.items.hikingSocks' => 'Hiking socks',
			'checklist.items.hat' => 'Hat',
			'checklist.items.gloves' => 'Gloves',
			'checklist.items.trailSnacks' => 'Trail snacks',
			'checklist.items.energyBars' => 'Energy bars',
			'checklist.items.waterPurification' => 'Water purification',
			'checklist.items.firstAidKit' => 'First aid kit',
			'checklist.items.whistle' => 'Whistle',
			'checklist.items.emergencyBlanket' => 'Emergency blanket',
			'checklist.items.sunscreen' => 'Sunscreen',
			'checklist.items.idCard' => 'ID card',
			'checklist.items.insurance' => 'Insurance',
			'checklist.items.trailMap' => 'Trail map',
			'checklist.items.toiletPaper' => 'Toilet paper',
			'checklist.items.handSanitizer' => 'Hand sanitizer',
			'checklist.items.towel' => 'Towel',
			'checklist.essential' => 'Essential',
			'journal.title' => 'Trek journal',
			'journal.empty' => 'Your journal is empty',
			'journal.emptySubtitle' => 'Write down your trek impressions and memories',
			'journal.addNote' => 'New note',
			'journal.stage' => 'Stage',
			'journal.yourNote' => 'Your note',
			'journal.placeholder' => 'Describe your hiking day...',
			'journal.save' => 'Save',
			'journal.cancel' => 'Cancel',
			'journal.delete' => 'Delete',
			'journal.photoLimit' => '3 photos per day limit reached',
			'journal.photoTooBig' => 'Photo too large (max 500 KB)',
			'weather.title' => 'Weather',
			'weather.loading' => 'Loading weather...',
			'weather.offline' => 'No connection. Weather data unavailable.',
			'weather.error' => 'Unable to load weather.',
			'weather.cached' => 'Cached data',
			'weather.alerts' => 'weather alerts',
			'weather.refresh' => 'Refresh',
			'weather.temperature' => 'Temperature',
			'weather.precipitation' => 'Precipitation',
			'weather.wind' => 'Wind',
			'weather.uv' => 'UV index',
			'weather.fireRisk' => 'Fire risk',
			'weather.fireRiskDesc' => 'High fire risk. Check safety instructions.',
			'weather.fireSafetyTips' => 'Fire safety tips',
			'weather.alertCount' => 'alert',
			'weather.alertCountPlural' => 'alerts',
			'share.title' => 'Share',
			'share.generating' => 'Generating...',
			'share.share' => 'Share',
			'share.error' => 'Error during generation',
			'share.errorShare' => 'Error during sharing',
			'share.preview' => 'Preview',
			'share.chooseTemplate' => 'Choose a template',
			'share.templateStats' => 'Statistics',
			'share.templateJourney' => 'Journey',
			'share.templateStage' => 'Stage',
			'diploma.title' => 'Trek diploma',
			'diploma.yourName' => 'Your name',
			'diploma.namePlaceholder' => 'Enter your name...',
			'diploma.generatePdf' => 'Generate PDF',
			'diploma.certifies' => 'Certifies that',
			'diploma.completed' => 'completed the',
			'diploma.pdfTitle' => 'DIPLOMA',
			'diploma.pdfSubtitle' => 'Certificate of achievement',
			'diploma.pdfStages' => '{count} stages',
			'diploma.pdfDistance' => '{km} km covered',
			'diploma.pdfElevation' => '{meters} m elevation gain',
			'diploma.pdfDuration' => 'in {days} days',
			'diploma.pdfFrom' => 'From',
			'diploma.pdfTo' => 'to',
			'diploma.pdfIssuedOn' => 'Issued on {date}',
			'diploma.recapTitle' => 'Your adventure',
			'diploma.recapJournalPhotos' => 'Journal photos',
			'diploma.recapNoPhotos' => 'No photos in journal',
			'diploma.recapStats' => 'Statistics',
			'diploma.recapStages' => '{count} stages completed',
			'diploma.recapDistance' => '{km} km covered',
			'diploma.recapElevation' => '{meters} m elevation',
			'diploma.recapDuration' => '{days} days of trekking',
			'diploma.recapMapTrace' => 'Route trace',
			'diploma.recapNoMap' => 'Trace not available',
			'diploma.recapJournalEntries' => '{count} journal entries',
			'diploma.downloadPdf' => 'Download diploma PDF',
			'notifications.morningReminder' => 'Morning reminder',
			'notifications.weatherAlerts' => 'Weather alerts',
			'notifications.countdown' => 'D-2 reminder',
			'notifications.countdownDesc' => 'Notification 2 days before departure',
			'notifications.schedulerCountdownTitle' => 'Your trek is coming up!',
			'notifications.schedulerCountdownBody' => 'Departure in 2 days. Check your checklist and the weather.',
			'notifications.schedulerDailyTitle' => 'Have a great trek day!',
			'notifications.schedulerDailyBody' => 'Check the weather and prepare today\'s stage.',
			'notifications.downloadReminderTitle' => 'Remember to download your trail!',
			'notifications.downloadReminderBody' => 'Departure in 2 days. Download your trail for offline mode.',
			'settings.title' => 'Settings',
			'settings.language' => 'Language',
			'settings.units' => 'Units',
			'settings.distance' => 'Distance',
			'settings.temperature' => 'Temperature',
			'settings.theme' => 'Theme',
			'settings.dark' => 'Dark',
			'settings.light' => 'Light',
			'settings.system' => 'System',
			'settings.cache' => 'Cache',
			'settings.cacheEnabled' => 'Cache enabled',
			'settings.cacheDesc' => 'Data available offline',
			'settings.cacheSize' => 'Cache size',
			'settings.notifications' => 'Notifications',
			'settings.morningReminder' => 'Morning reminder',
			'settings.weatherAlerts' => 'Weather alerts',
			'settings.weatherAlertsDesc' => 'Notified when dangerous conditions',
			'settings.countdownReminder' => 'D-2 reminder',
			'settings.countdownDesc' => 'Notification 2 days before departure',
			'settings.version' => 'Version',
			'settings.versionLabel' => 'App version',
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Feedback type',
			'feedback.bug' => 'Bug / Problem',
			'feedback.suggestion' => 'Suggestion',
			'feedback.compliment' => 'Compliment',
			'feedback.question' => 'Question',
			'feedback.other' => 'Other',
			'feedback.message' => 'Your message',
			'feedback.messagePlaceholder' => 'Describe your feedback...',
			'feedback.satisfaction' => 'Satisfaction',
			'feedback.send' => 'Send',
			'feedback.sending' => 'Sending...',
			'feedback.thanks' => 'Thank you for your feedback!',
			'feedback.pending' => 'pending',
			'auth.profile' => 'Profile',
			'auth.anonymous' => 'Anonymous hiker',
			'auth.connectedVia' => 'Connected via',
			'auth.signInGoogle' => 'Sign in with Google',
			'auth.signInGoogleDesc' => 'To save your progress',
			'auth.signOut' => 'Sign out',
			'auth.signOutDesc' => 'Return to anonymous mode',
			'auth.signOutConfirm' => 'Sign out?',
			'auth.signOutMessage' => 'You will return to anonymous mode. Your local data is preserved.',
			'auth.deleteAccount' => 'Delete my account',
			'auth.deleteAccountDesc' => 'All your data will be erased',
			'auth.deleteConfirm' => 'Delete your account?',
			'auth.deleteMessage' => 'This action is irreversible. All your data, notes and progress will be erased.',
			'auth.cancel' => 'Cancel',
			'auth.pseudonym' => 'Nickname',
			'auth.pseudonymHint' => 'Your hiker name',
			'auth.save' => 'Save',
			'auth.changeAvatar' => 'Change avatar',
			'auth.chooseAvatar' => 'Choose an avatar',
			'auth.errorLoading' => 'Loading error',
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
			'feasibility.seeRecommendations' => 'See recommendations',
			'feasibility.yourProfile' => 'Your profile',
			'feasibility.tipsTitle' => 'Our tips',
			'feasibility.recommendations.danger.title' => 'Insufficient preparation',
			'feasibility.recommendations.danger.summary' => 'Your profile shows significant gaps. We do not recommend starting in this state.',
			'feasibility.recommendations.danger.tips.tip1' => 'Start with short hikes to assess your fitness level',
			'feasibility.recommendations.danger.tips.tip2' => 'Consult a healthcare professional before prolonged effort',
			'feasibility.recommendations.danger.tips.tip3' => 'Invest in proper equipment and test it beforehand',
			'feasibility.recommendations.caution.title' => 'Preparation needs work',
			'feasibility.recommendations.caution.summary' => 'You have a foundation, but some areas need attention before departure.',
			'feasibility.recommendations.caution.tips.tip1' => 'Strengthen your physical training 6 to 8 weeks ahead',
			'feasibility.recommendations.caution.tips.tip2' => 'Check and complete your equipment',
			'feasibility.recommendations.caution.tips.tip3' => 'Plan stages suited to your level',
			'feasibility.recommendations.good.title' => 'Good preparation',
			'feasibility.recommendations.good.summary' => 'Your profile is solid. A few adjustments and you will be ready.',
			'feasibility.recommendations.good.tips.tip1' => 'Maintain your training pace until departure',
			'feasibility.recommendations.good.tips.tip2' => 'Include margins in your planning',
			'feasibility.recommendations.good.tips.tip3' => 'Check the weather regularly before departure',
			'feasibility.recommendations.excellent.title' => 'Optimal preparation',
			'feasibility.recommendations.excellent.summary' => 'You are perfectly prepared. Enjoy the trek with peace of mind!',
			'feasibility.recommendations.excellent.tips.tip1' => 'Listen to your body during the trek',
			'feasibility.recommendations.excellent.tips.tip2' => 'Share your experience with fellow hikers',
			'feasibility.recommendations.excellent.tips.tip3' => 'Consider documenting your adventure in the journal',
			'tips.carouselTitle' => 'Trek tips',
			'tips.allCategories' => 'All',
			'tips.swipeHint' => 'Swipe for more',
			'tips.detailTitle' => 'Tip detail',
			'tips.readMore' => 'Read more',
			'tips.noTips' => 'No tips available',
			'tips.categoryPreparation' => 'Preparation',
			'tips.categoryEquipment' => 'Equipment',
			'tips.categoryNutrition' => 'Nutrition',
			'tips.categorySafety' => 'Safety',
			'tips.categoryNature' => 'Nature',
			'tips.categoryRecovery' => 'Recovery',
			'tips.categoryGeneral' => 'General',
			'tips.priorityHigh' => 'High priority',
			'tips.scope' => 'Trail',
			'tips.season' => 'Season',
			'tips.altitude' => 'Min. altitude',
			'goodies.title' => 'Goodies Shop',
			'goodies.comingSoon' => 'This module is coming soon. Stay tuned!',
			_ => null,
		};
	}
}
