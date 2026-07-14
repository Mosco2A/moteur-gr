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
class TranslationsEn extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEn({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEn _root = this; // ignore: unused_field

	@override 
	TranslationsEn $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEn(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$a11y$en a11y = _Translations$a11y$en._(_root);
	@override late final _Translations$nav$en nav = _Translations$nav$en._(_root);
	@override late final _Translations$branding$en branding = _Translations$branding$en._(_root);
	@override late final _Translations$hub$en hub = _Translations$hub$en._(_root);
	@override late final _Translations$map$en map = _Translations$map$en._(_root);
	@override late final _Translations$stage$en stage = _Translations$stage$en._(_root);
	@override late final _Translations$trail$en trail = _Translations$trail$en._(_root);
	@override late final _Translations$poi$en poi = _Translations$poi$en._(_root);
	@override late final _Translations$accommodation$en accommodation = _Translations$accommodation$en._(_root);
	@override late final _Translations$gps$en gps = _Translations$gps$en._(_root);
	@override late final _Translations$navAlert$en navAlert = _Translations$navAlert$en._(_root);
	@override late final _Translations$planning$en planning = _Translations$planning$en._(_root);
	@override late final _Translations$tracking$en tracking = _Translations$tracking$en._(_root);
	@override late final _Translations$checklist$en checklist = _Translations$checklist$en._(_root);
	@override late final _Translations$journal$en journal = _Translations$journal$en._(_root);
	@override late final _Translations$weather$en weather = _Translations$weather$en._(_root);
	@override late final _Translations$share$en share = _Translations$share$en._(_root);
	@override late final _Translations$diploma$en diploma = _Translations$diploma$en._(_root);
	@override late final _Translations$notifications$en notifications = _Translations$notifications$en._(_root);
	@override late final _Translations$settings$en settings = _Translations$settings$en._(_root);
	@override late final _Translations$feedback$en feedback = _Translations$feedback$en._(_root);
	@override late final _Translations$auth$en auth = _Translations$auth$en._(_root);
	@override late final _Translations$feasibility$en feasibility = _Translations$feasibility$en._(_root);
	@override late final _Translations$tips$en tips = _Translations$tips$en._(_root);
	@override late final _Translations$goodies$en goodies = _Translations$goodies$en._(_root);
	@override late final _Translations$noData$en noData = _Translations$noData$en._(_root);
	@override late final _Translations$catalog$en catalog = _Translations$catalog$en._(_root);
	@override late final _Translations$updates$en updates = _Translations$updates$en._(_root);
	@override late final _Translations$follow$en follow = _Translations$follow$en._(_root);
	@override late final _Translations$cloud$en cloud = _Translations$cloud$en._(_root);
	@override late final _Translations$onboarding$en onboarding = _Translations$onboarding$en._(_root);
	@override late final _Translations$monetization$en monetization = _Translations$monetization$en._(_root);
	@override late final _Translations$signalement$en signalement = _Translations$signalement$en._(_root);
	@override late final _Translations$hebergement$en hebergement = _Translations$hebergement$en._(_root);
	@override late final _Translations$training$en training = _Translations$training$en._(_root);
	@override late final _Translations$eta$en eta = _Translations$eta$en._(_root);
	@override late final _Translations$leaderboard$en leaderboard = _Translations$leaderboard$en._(_root);
	@override late final _Translations$social$en social = _Translations$social$en._(_root);
	@override late final _Translations$gamification$en gamification = _Translations$gamification$en._(_root);
	@override late final _Translations$shareVisibility$en shareVisibility = _Translations$shareVisibility$en._(_root);
	@override late final _Translations$waypoints$en waypoints = _Translations$waypoints$en._(_root);
	@override late final _Translations$packs$en packs = _Translations$packs$en._(_root);
	@override late final _Translations$guides$en guides = _Translations$guides$en._(_root);
	@override late final _Translations$health$en health = _Translations$health$en._(_root);
	@override late final _Translations$trailSelection$en trailSelection = _Translations$trailSelection$en._(_root);
	@override late final _Translations$consent$en consent = _Translations$consent$en._(_root);
	@override late final _Translations$moderation$en moderation = _Translations$moderation$en._(_root);
}

// Path: a11y
class _Translations$a11y$en extends Translations$a11y$fr {
	_Translations$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get back => 'Back';
	@override String get zoomIn => 'Zoom in';
	@override String get zoomOut => 'Zoom out';
	@override String get centerOnMe => 'Center on my position';
	@override String get mapRegion => 'Trail map';
	@override String get userPosition => 'Your position';
	@override String stageMarker({required Object number}) => 'Stage ${number}';
	@override String poiMarker({required Object name}) => 'Point of interest: ${name}';
	@override String markerCluster({required Object count}) => '${count} grouped points';
	@override String trailCard({required Object name}) => 'Trail ${name}';
	@override String get startTracking => 'Start tracking';
	@override String get pauseTracking => 'Pause tracking';
	@override String get resumeTracking => 'Resume tracking';
	@override String get stopTracking => 'Stop tracking';
}

// Path: nav
class _Translations$nav$en extends Translations$nav$fr {
	_Translations$nav$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Home';
	@override String get map => 'Map';
	@override String get stages => 'Stages';
	@override String get planning => 'Planning';
	@override String get journal => 'Journal';
	@override String get more => 'More';
	@override String get checklist => 'Gear checklist';
	@override String get feasibility => 'Feasibility';
	@override String get tips => 'Trek tips';
	@override String get emergency => 'Emergency contacts';
	@override String get catalog => 'Trail catalog';
	@override String get profile => 'Profile';
	@override String get settings => 'Settings';
	@override String get trailSelection => 'Switch trail';
}

// Path: branding
class _Translations$branding$en extends Translations$branding$fr {
	_Translations$branding$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Your trekking companion';
	@override String get subline => 'Prepare, hike, share';
}

// Path: hub
class _Translations$hub$en extends Translations$hub$fr {
	_Translations$hub$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String greeting({required Object name}) => 'Hello, ${name}!';
	@override String get greetingFallback => 'Hiker';
	@override String get infoTooltip => 'About this trail';
	@override String get profileTooltip => 'My profile';
	@override String get infoSheetBody => 'This trail guides you every step of the way: plan your itinerary, pack your bag, then set off with GPS navigation. Every feature is reachable from this home screen.';
	@override late final _Translations$hub$trekCard$en trekCard = _Translations$hub$trekCard$en._(_root);
	@override late final _Translations$hub$weather$en weather = _Translations$hub$weather$en._(_root);
	@override String get startCta => 'Start the trek';
	@override late final _Translations$hub$sections$en sections = _Translations$hub$sections$en._(_root);
	@override late final _Translations$hub$cards$en cards = _Translations$hub$cards$en._(_root);
	@override late final _Translations$hub$fab$en fab = _Translations$hub$fab$en._(_root);
}

// Path: map
class _Translations$map$en extends Translations$map$fr {
	_Translations$map$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trail map';
	@override String get loading => 'Loading track...';
	@override String get noTrack => 'No track available';
	@override String get viewMap => 'View map';
}

// Path: stage
class _Translations$stage$en extends Translations$stage$fr {
	_Translations$stage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distance';
	@override String get elevation => 'Elevation';
	@override String get elevationGain => 'Elevation gain';
	@override String get elevationLoss => 'Elevation loss';
	@override String get duration => 'Estimated duration';
	@override String get description => 'Description';
	@override String get coordinates => 'Coordinates';
	@override String get pois => 'Points of interest';
	@override late final _Translations$stage$difficulty$en difficulty = _Translations$stage$difficulty$en._(_root);
	@override String get remaining => '{distance} km remaining';
	@override String get arrived => 'You have arrived!';
}

// Path: trail
class _Translations$trail$en extends Translations$trail$fr {
	_Translations$trail$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Stages';
	@override String get totalDistance => 'Total distance';
	@override String get totalElevation => 'Total elevation';
}

// Path: poi
class _Translations$poi$en extends Translations$poi$fr {
	_Translations$poi$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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

// Path: accommodation
class _Translations$accommodation$en extends Translations$accommodation$fr {
	_Translations$accommodation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$accommodation$types$en types = _Translations$accommodation$types$en._(_root);
}

// Path: gps
class _Translations$gps$en extends Translations$gps$fr {
	_Translations$gps$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get permission => 'GPS permission required';
	@override String get denied => 'Location access denied';
	@override String get disabled => 'Location service disabled';
	@override String get offTrack => 'Off track';
	@override String get centerOnMe => 'Center on my position';
}

// Path: navAlert
class _Translations$navAlert$en extends Translations$navAlert$fr {
	_Translations$navAlert$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String offTrackBanner({required Object meters}) => 'You are moving away from the trail — ${meters} m. Check your position.';
	@override String get offTrackNotifTitle => 'You are leaving the trail';
	@override String offTrackNotifBody({required Object meters}) => 'You are moving away from the trail (${meters} m). Check your position.';
}

// Path: planning
class _Translations$planning$en extends Translations$planning$fr {
	_Translations$planning$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$tracking$en extends Translations$tracking$fr {
	_Translations$tracking$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$checklist$en extends Translations$checklist$fr {
	_Translations$checklist$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
	@override late final _Translations$checklist$categories$en categories = _Translations$checklist$categories$en._(_root);
	@override late final _Translations$checklist$items$en items = _Translations$checklist$items$en._(_root);
	@override String get essential => 'Essential';
}

// Path: journal
class _Translations$journal$en extends Translations$journal$fr {
	_Translations$journal$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$weather$en extends Translations$weather$fr {
	_Translations$weather$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
	@override String get fireRisk => 'Fire risk';
	@override String get fireRiskDesc => 'High fire risk. Check safety instructions.';
	@override String get fireSafetyTips => 'Fire safety tips';
	@override String get alertCount => 'alert';
	@override String get alertCountPlural => 'alerts';
	@override String get today => 'Today';
	@override String get tomorrow => 'Tomorrow';
	@override String get dayPlus2 => 'In two days';
	@override String get allStages => 'All stages';
	@override String get noForecast => 'No forecast available.';
	@override String stageLabel({required Object number}) => 'Stage ${number}';
	@override String get stormAlertsTitle => 'Storm alerts';
	@override String get stormAlertsToggleOn => 'Storm alerts on';
	@override String get stormAlertsToggleOff => 'Storm alerts off';
	@override String lastUpdate({required Object date}) => 'Updated ${date}';
	@override String get guideTitle => 'Understanding the weather';
	@override String get guideBody => 'Forecasts cover 7 days for each stage. Watch storm and wind alerts: in the mountains, weather changes fast. When offline, the last saved data is shown.';
	@override late final _Translations$weather$source$en source = _Translations$weather$source$en._(_root);
	@override late final _Translations$weather$recommendation$en recommendation = _Translations$weather$recommendation$en._(_root);
	@override late final _Translations$weather$alert$en alert = _Translations$weather$alert$en._(_root);
}

// Path: share
class _Translations$share$en extends Translations$share$fr {
	_Translations$share$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Share';
	@override String get generating => 'Generating...';
	@override String get share => 'Share';
	@override String get error => 'Error during generation';
	@override String get errorShare => 'Error during sharing';
	@override String get preview => 'Preview';
	@override String get chooseTemplate => 'Choose a template';
	@override String get templateStats => 'Statistics';
	@override String get templateJourney => 'Journey';
	@override String get templateStage => 'Stage';
}

// Path: diploma
class _Translations$diploma$en extends Translations$diploma$fr {
	_Translations$diploma$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trek diploma';
	@override String get yourName => 'Your name';
	@override String get namePlaceholder => 'Enter your name...';
	@override String get generatePdf => 'Generate PDF';
	@override String get certifies => 'Certifies that';
	@override String get completed => 'completed the';
	@override String get pdfTitle => 'DIPLOMA';
	@override String get pdfSubtitle => 'Certificate of achievement';
	@override String get pdfStages => '{count} stages';
	@override String get pdfDistance => '{km} km covered';
	@override String get pdfElevation => '{meters} m elevation gain';
	@override String get pdfDuration => 'in {days} days';
	@override String get pdfFrom => 'From';
	@override String get pdfTo => 'to';
	@override String get pdfIssuedOn => 'Issued on {date}';
	@override String get recapTitle => 'Your adventure';
	@override String get recapJournalPhotos => 'Journal photos';
	@override String get recapNoPhotos => 'No photos in journal';
	@override String get recapStats => 'Statistics';
	@override String get recapStages => '{count} stages completed';
	@override String get recapDistance => '{km} km covered';
	@override String get recapElevation => '{meters} m elevation';
	@override String get recapDuration => '{days} days of trekking';
	@override String get recapMapTrace => 'Route trace';
	@override String get recapNoMap => 'Trace not available';
	@override String get recapJournalEntries => '{count} journal entries';
	@override String get downloadPdf => 'Download diploma PDF';
}

// Path: notifications
class _Translations$notifications$en extends Translations$notifications$fr {
	_Translations$notifications$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Morning reminder';
	@override String get weatherAlerts => 'Weather alerts';
	@override String get countdown => 'D-2 reminder';
	@override String get countdownDesc => 'Notification 2 days before departure';
	@override String get schedulerCountdownTitle => 'Your trek is coming up!';
	@override String get schedulerCountdownBody => 'Departure in 2 days. Check your checklist and the weather.';
	@override String get schedulerDailyTitle => 'Have a great trek day!';
	@override String get schedulerDailyBody => 'Check the weather and prepare today\'s stage.';
}

// Path: settings
class _Translations$settings$en extends Translations$settings$fr {
	_Translations$settings$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
	@override String get morningReminder => 'Morning reminder';
	@override String get weatherAlerts => 'Weather alerts';
	@override String get weatherAlertsDesc => 'Notified when dangerous conditions';
	@override String get countdownReminder => 'D-2 reminder';
	@override String get countdownDesc => 'Notification 2 days before departure';
	@override String get offTrackAlerts => 'Off-track alert';
	@override String get offTrackAlertsDesc => 'Notification + vibration if you leave the trail';
	@override String get version => 'Version';
	@override String get versionLabel => 'App version';
}

// Path: feedback
class _Translations$feedback$en extends Translations$feedback$fr {
	_Translations$feedback$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feedback';
	@override String get type => 'Feedback type';
	@override String get bug => 'Bug / Problem';
	@override String get suggestion => 'Suggestion';
	@override String get compliment => 'Compliment';
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
class _Translations$auth$en extends Translations$auth$fr {
	_Translations$auth$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Profile';
	@override String get anonymous => 'Hiker without account';
	@override String get connectedVia => 'Connected via';
	@override String get signInGoogle => 'Sign in with Google';
	@override String get signInGoogleDesc => 'To save your progress';
	@override String get signOut => 'Sign out';
	@override String get signOutDesc => 'Return to no-account mode';
	@override String get signOutConfirm => 'Sign out?';
	@override String get signOutMessage => 'You will return to no-account mode. Your local data is preserved.';
	@override String get deleteAccount => 'Delete my account';
	@override String get deleteAccountDesc => 'All your data will be erased';
	@override String get deleteConfirm => 'Delete your account?';
	@override String get deleteMessage => 'This action is irreversible. All your data, notes and progress will be erased.';
	@override String get cancel => 'Cancel';
	@override String get pseudonym => 'Nickname';
	@override String get pseudonymHint => 'Your hiker name';
	@override String get save => 'Save';
	@override String get changeAvatar => 'Change avatar';
	@override String get chooseAvatar => 'Choose an avatar';
	@override String get errorLoading => 'Loading error';
}

// Path: feasibility
class _Translations$feasibility$en extends Translations$feasibility$fr {
	_Translations$feasibility$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feasibility';
	@override String get subtitle => 'Assess your preparation';
	@override String get previous => 'Previous';
	@override String get restart => 'Start over';
	@override String get resultTitle => 'Your result';
	@override String get weakPointsTitle => 'Areas to improve';
	@override String get strongPointsTitle => 'Strong points';
	@override String get progress => '{current}/{total}';
	@override late final _Translations$feasibility$levels$en levels = _Translations$feasibility$levels$en._(_root);
	@override late final _Translations$feasibility$categories$en categories = _Translations$feasibility$categories$en._(_root);
	@override late final _Translations$feasibility$questions$en questions = _Translations$feasibility$questions$en._(_root);
	@override late final _Translations$feasibility$answers$en answers = _Translations$feasibility$answers$en._(_root);
	@override String get seeRecommendations => 'See recommendations';
	@override String get yourProfile => 'Your profile';
	@override String get tipsTitle => 'Our tips';
	@override late final _Translations$feasibility$recommendations$en recommendations = _Translations$feasibility$recommendations$en._(_root);
}

// Path: tips
class _Translations$tips$en extends Translations$tips$fr {
	_Translations$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Trek tips';
	@override String get allCategories => 'All';
	@override String get swipeHint => 'Swipe for more';
	@override String get detailTitle => 'Tip detail';
	@override String get readMore => 'Read more';
	@override String get noTips => 'No tips available';
	@override String get categoryPreparation => 'Preparation';
	@override String get categoryEquipment => 'Equipment';
	@override String get categoryNutrition => 'Nutrition';
	@override String get categorySafety => 'Safety';
	@override String get categoryNature => 'Nature';
	@override String get categoryRecovery => 'Recovery';
	@override String get categoryGeneral => 'General';
	@override String get priorityHigh => 'High priority';
	@override String get scope => 'Trail';
	@override String get season => 'Season';
	@override String get altitude => 'Min. altitude';
}

// Path: goodies
class _Translations$goodies$en extends Translations$goodies$fr {
	_Translations$goodies$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Goodies Shop';
	@override String get comingSoon => 'This module is coming soon. Stay tuned!';
}

// Path: noData
class _Translations$noData$en extends Translations$noData$fr {
	_Translations$noData$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'No trail downloaded';
	@override String get subtitle => 'Download a trail to get started';
	@override String get offlineHint => 'Data will be available offline for your hike.';
	@override String get browseCta => 'Browse trails';
}

// Path: catalog
class _Translations$catalog$en extends Translations$catalog$fr {
	_Translations$catalog$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trail catalog';
	@override String get enter => 'Enter';
	@override String get mustDownload => 'Download this trail to explore it.';
	@override String get emptyTitle => 'No trail available';
	@override String get emptySubtitle => 'No trail is offered in the catalog yet.';
	@override late final _Translations$catalog$a11y$en a11y = _Translations$catalog$a11y$en._(_root);
}

// Path: updates
class _Translations$updates$en extends Translations$updates$fr {
	_Translations$updates$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get readyTitle => 'Update ready';
	@override String get readyBodyOne => 'One trail has been updated.';
	@override String readyBodyMany({required Object count}) => '${count} trails have been updated.';
}

// Path: follow
class _Translations$follow$en extends Translations$follow$fr {
	_Translations$follow$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Live tracking';
	@override String get connecting => 'Connecting…';
	@override String get live => 'Live';
	@override String get offline => 'Offline';
	@override String get invalidLink => 'Invalid link';
	@override String get invalidLinkHint => 'This tracking link does not exist or has expired.';
}

// Path: cloud
class _Translations$cloud$en extends Translations$cloud$fr {
	_Translations$cloud$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get localModeTitle => 'Local mode';
	@override String get localModeBody => 'This installation is not connected to a cloud service: live tracking, online backup and account are disabled. Your data stays on this device.';
	@override String get statusSection => 'Cloud';
	@override String get statusActive => 'Online services active';
	@override String get statusActiveDesc => 'Backup and live tracking available.';
	@override String get statusLocal => 'Local mode (no cloud)';
	@override String get statusLocalDesc => 'No data is sent online. Cloud configuration absent.';
}

// Path: onboarding
class _Translations$onboarding$en extends Translations$onboarding$fr {
	_Translations$onboarding$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Skip';
	@override String get next => 'Next';
	@override String get getStarted => 'Get started';
	@override String welcomeTitle({required Object appName}) => 'Welcome to ${appName}';
	@override String get welcomeSubtitle => 'Your offline hiking companion: map, GPS navigation, planning and trek journal.';
	@override String get languageTitle => 'Choose your language';
	@override String get languageSubtitle => 'You can change it at any time in the settings.';
	@override String get downloadTitle => 'Download your first trail';
	@override String get downloadSubtitle => 'Browse the catalogue and download a trail to use it fully offline.';
	@override String get browseCatalog => 'Browse the catalogue';
}

// Path: monetization
class _Translations$monetization$en extends Translations$monetization$fr {
	_Translations$monetization$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get demoBanner => 'Demo mode — tap to unlock';
	@override String get paywallTitle => 'Unlock this trek';
	@override String get paywallBody => 'Free mode lets you plan your trek with ads. Premium unlocks everything, ad-free.';
	@override String get featureMap => 'Offline map + GPS + live tracking';
	@override String get featureJournal => 'Full trek journal';
	@override String get featureDiploma => 'End-of-trek diploma';
	@override String get featureFollowers => '2 free followers';
	@override String get featureNoAds => 'Zero ads';
	@override String get buyCta => 'Unlock this trek';
	@override String buyCtaWithPrice({required Object price}) => 'Unlock this trek — €${price}';
}

// Path: signalement
class _Translations$signalement$en extends Translations$signalement$fr {
	_Translations$signalement$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Report';
	@override String get chooseType => 'What do you want to report?';
	@override late final _Translations$signalement$types$en types = _Translations$signalement$types$en._(_root);
	@override String get latencyBanner => 'Saved. Visible to other hikers once the network syncs.';
	@override String get confirm => 'Confirm report';
	@override String get noLocation => 'GPS position unavailable right now. Try again under open sky.';
	@override String get savedTitle => 'Report saved';
	@override String get savedPendingSync => 'It will be shared as soon as the network is back.';
	@override String pendingCount({required Object n}) => '${n} awaiting sync';
	@override String get close => 'Close';
}

// Path: hebergement
class _Translations$hebergement$en extends Translations$hebergement$fr {
	_Translations$hebergement$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nearby accommodation';
	@override String get facilitatorNote => 'StepWays points you to the hosts. Booking happens on their website: no payment inside the app.';
	@override String detourAR({required Object km}) => 'Round-trip detour: ${km} km';
	@override String get openSite => 'View website';
	@override String get cannotOpen => 'Could not open this link on this device.';
	@override String get empty => 'No accommodation listed nearby for now.';
	@override late final _Translations$hebergement$types$en types = _Translations$hebergement$types$en._(_root);
}

// Path: training
class _Translations$training$en extends Translations$training$fr {
	_Translations$training$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Physical preparation';
	@override String get localNotice => 'Your plan is computed and kept on your phone. Reminders are local notifications, with no tracking.';
	@override String get reminderTitle => 'Training session today';
	@override String get scheduleReminders => 'Schedule reminders';
	@override String remindersScheduled({required Object n}) => '${n} reminder(s) scheduled';
	@override String week({required Object n}) => 'Week ${n}';
	@override String minutes({required Object n}) => '${n} min';
	@override String progress({required Object done, required Object total}) => '${done}/${total} sessions done';
	@override late final _Translations$training$types$en types = _Translations$training$types$en._(_root);
	@override late final _Translations$training$intensity$en intensity = _Translations$training$intensity$en._(_root);
}

// Path: eta
class _Translations$eta$en extends Translations$eta$fr {
	_Translations$eta$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Estimated time';
	@override String get toNextWaypoint => 'Next point';
	@override String get toStageEnd => 'Stage end';
	@override String get confidenceHigh => 'Reliable estimate';
	@override String get confidenceLow => 'Approximate (weak GPS)';
	@override String durationHm({required Object h, required Object m}) => '${h} h ${m} min';
	@override String durationM({required Object m}) => '${m} min';
}

// Path: leaderboard
class _Translations$leaderboard$en extends Translations$leaderboard$fr {
	_Translations$leaderboard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'King of the stage';
	@override String get unavailable => 'Leaderboard unavailable right now.';
	@override String get empty => 'No ranking for this segment yet. Be the first to run it!';
	@override String get pseudonymNotice => 'Ranking by group, using pseudonyms. No direct personal data is shown.';
	@override String trancheLabel({required Object tranche}) => 'Group: ${tranche}';
	@override String get notEnoughParticipants => 'Not enough participants to publish this ranking.';
	@override String entrySemantics({required Object rank, required Object pseudonym, required Object time}) => 'Rank ${rank}, ${pseudonym}, time ${time}';
}

// Path: social
class _Translations$social$en extends Translations$social$fr {
	_Translations$social$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get feedTitle => 'Activity feed';
	@override String get empty => 'No activity yet.';
	@override String get kudos => 'Give kudos';
	@override String kudosCount({required Object n}) => '${n} kudos';
	@override String get report => 'Report';
	@override String get reportTitle => 'Report this post';
	@override String get reportReasonLabel => 'Reason for reporting';
	@override String get reasonSpam => 'Spam or advertising';
	@override String get reasonAbuse => 'Abusive or hateful content';
	@override String get reasonOther => 'Other';
	@override String get reportSend => 'Send report';
	@override String get reportSent => 'Report sent. Our team will review it.';
	@override String get syncPending => 'Waiting for sync';
	@override String get synced => 'Synced';
	@override String get activitySegment => 'completed a segment';
	@override String get activityBadge => 'earned a badge';
	@override String get activityDefi => 'made progress on a challenge';
}

// Path: gamification
class _Translations$gamification$en extends Translations$gamification$fr {
	_Translations$gamification$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get galleryTitle => 'My badges';
	@override String get obtained => 'Earned';
	@override String get locked => 'Locked';
	@override String get tierDebutant => 'Beginner';
	@override String get tierExpert => 'Expert';
	@override late final _Translations$gamification$badge$en badge = _Translations$gamification$badge$en._(_root);
	@override late final _Translations$gamification$defi$en defi = _Translations$gamification$defi$en._(_root);
}

// Path: shareVisibility
class _Translations$shareVisibility$en extends Translations$shareVisibility$fr {
	_Translations$shareVisibility$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Sharing and visibility';
	@override String get intro => 'By default, nothing is shared. Turn on below, purpose by purpose, what you want to make visible.';
	@override String get consentLink => 'Manage my consent (privacy)';
	@override String get stageResults => 'Share my stage results';
	@override String get stageResultsDesc => 'A pseudonymous card (no direct personal data).';
	@override String get leaderboard => 'Appear in leaderboards';
	@override String get leaderboardDesc => 'Ranking by group, using a pseudonym.';
	@override String get activityFeed => 'Post to the activity feed';
	@override String get activityFeedDesc => 'Your activities appear in the feed, under a pseudonym.';
	@override String get shareTitle => 'Share this stage';
	@override String get shareButton => 'Share';
	@override String get privateNotice => 'Sharing is off. Turn it on in Sharing and visibility.';
	@override String get shared => 'Card ready to share.';
}

// Path: waypoints
class _Translations$waypoints$en extends Translations$waypoints$fr {
	_Translations$waypoints$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$waypoints$types$en types = _Translations$waypoints$types$en._(_root);
	@override late final _Translations$waypoints$filters$en filters = _Translations$waypoints$filters$en._(_root);
	@override late final _Translations$waypoints$detail$en detail = _Translations$waypoints$detail$en._(_root);
	@override late final _Translations$waypoints$freshness$en freshness = _Translations$waypoints$freshness$en._(_root);
	@override late final _Translations$waypoints$contribution$en contribution = _Translations$waypoints$contribution$en._(_root);
}

// Path: packs
class _Translations$packs$en extends Translations$packs$fr {
	_Translations$packs$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Trail packs';
	@override String get subtitle => 'Download a pack to hike 100% offline.';
	@override String get alaCarteNote => 'A la carte: buy only the pack you need, no subscription.';
	@override String size({required Object mo}) => '${mo} MB';
	@override late final _Translations$packs$states$en states = _Translations$packs$states$en._(_root);
	@override late final _Translations$packs$actions$en actions = _Translations$packs$actions$en._(_root);
	@override late final _Translations$packs$progress$en progress = _Translations$packs$progress$en._(_root);
	@override late final _Translations$packs$delete$en delete = _Translations$packs$delete$en._(_root);
	@override String get empty => 'No pack available for this trail.';
	@override late final _Translations$packs$a11y$en a11y = _Translations$packs$a11y$en._(_root);
	@override late final _Translations$packs$types$en types = _Translations$packs$types$en._(_root);
}

// Path: guides
class _Translations$guides$en extends Translations$guides$fr {
	_Translations$guides$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Town guides';
	@override String get subtitle => 'Practical info for towns and villages, available offline.';
	@override String sectionsCount({required Object n}) => '${n} practical sections';
	@override String get empty => 'No guide available for this trail.';
	@override String get noItems => 'No information in this section yet.';
	@override String get facilitatorNote => 'StepWays points you to providers. Booking and payment happen on their site: nothing in the app.';
	@override String get openSite => 'Open website';
	@override String get cannotOpen => 'Can\'t open this link on this device.';
	@override late final _Translations$guides$categories$en categories = _Translations$guides$categories$en._(_root);
	@override late final _Translations$guides$intro$en intro = _Translations$guides$intro$en._(_root);
	@override late final _Translations$guides$a11y$en a11y = _Translations$guides$a11y$en._(_root);
}

// Path: health
class _Translations$health$en extends Translations$health$fr {
	_Translations$health$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Health information';
	@override String get privacyBanner => 'This data stays on your phone. It is never sent over the internet.';
	@override late final _Translations$health$field$en field = _Translations$health$field$en._(_root);
	@override late final _Translations$health$hint$en hint = _Translations$health$hint$en._(_root);
	@override String get save => 'Save';
	@override String get saving => 'Saving…';
	@override String get saved => 'Information saved';
	@override String get emergencyHint => 'In an emergency, show this screen to the rescue team.';
	@override String get entryTitle => 'My health info';
	@override String get entrySubtitle => 'To show the rescue team (kept on the phone)';
	@override late final _Translations$health$a11y$en a11y = _Translations$health$a11y$en._(_root);
}

// Path: trailSelection
class _Translations$trailSelection$en extends Translations$trailSelection$fr {
	_Translations$trailSelection$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Switch trail';
	@override String get subtitle => 'Pick the trail to explore. The whole app (map, stages, points of interest, packs, guides) follows your selection.';
	@override String get current => 'Active trail';
	@override String get select => 'Choose this trail';
	@override String get selected => 'Selected trail';
	@override String stagesDistance({required Object stages, required Object km}) => '${stages} stages - ${km} km';
	@override late final _Translations$trailSelection$a11y$en a11y = _Translations$trailSelection$a11y$en._(_root);
}

// Path: consent
class _Translations$consent$en extends Translations$consent$fr {
	_Translations$consent$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get onboardingTitle => 'Your privacy, your choice';
	@override String get onboardingIntro => 'Nothing is enabled by default. Choose, purpose by purpose, what you allow. You can change everything at any time in the settings.';
	@override String get settingsTitle => 'Privacy and consent';
	@override String get settingsIntro => 'Manage each permission here. You can withdraw a consent at any time, with no effect on the rest.';
	@override String get settingsEntry => 'Privacy and consent';
	@override String get settingsEntryDesc => 'Manage my permissions (location, sharing, health)';
	@override late final _Translations$consent$purposes$en purposes = _Translations$consent$purposes$en._(_root);
	@override String get healthBadge => 'Sensitive data';
	@override String get healthWarning => 'Heart rate is health data (GDPR article 9). This consent is requested separately and is never bundled with the others. Your health data is not sent to our servers.';
	@override String get granted => 'Allowed';
	@override String get denied => 'Not allowed';
	@override String get grant => 'Allow';
	@override String get revoke => 'Withdraw';
	@override String decidedOn({required Object date}) => 'Chosen on ${date}';
	@override String get notDecided => 'Awaiting your choice';
	@override String get acceptSelected => 'Confirm my choices';
	@override String get declineAll => 'Decline all';
	@override String get continueLabel => 'Continue';
	@override String get privacyPolicyLink => 'Read the privacy policy';
	@override String get reviewNeeded => 'Our policy has changed: please review your choices.';
	@override late final _Translations$consent$a11y$en a11y = _Translations$consent$a11y$en._(_root);
}

// Path: moderation
class _Translations$moderation$en extends Translations$moderation$fr {
	_Translations$moderation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get reportTitle => 'Report this content';
	@override String get reportIntro => 'Help us keep the community healthy. Tell us why this content seems unlawful. Your report will be reviewed by a moderator.';
	@override String get reasonLabel => 'Reason for reporting';
	@override late final _Translations$moderation$reasons$en reasons = _Translations$moderation$reasons$en._(_root);
	@override String get detailsLabel => 'Add details (optional)';
	@override String get detailsHint => 'Add a comment to help the moderator.';
	@override String get contactLabel => 'Your email address';
	@override String get contactHint => 'To keep you informed about the handling (article 16).';
	@override String get goodFaithLabel => 'I declare in good faith that this information is accurate.';
	@override String get submit => 'Send report';
	@override String get submitting => 'Sending…';
	@override String get sent => 'Report sent. Thank you, a moderator will review it.';
	@override String get errorRequired => 'Please fill in the reason, your email and the good-faith declaration.';
	@override String get errorGeneric => 'The report could not be sent. Please try again.';
	@override String get cancel => 'Cancel';
	@override String get reasonsTitle => 'Why was this content restricted?';
	@override String get reasonsIntro => 'In accordance with article 17, here is the reason for the moderation decision regarding your content.';
	@override String get decisionLabel => 'Decision';
	@override late final _Translations$moderation$decisions$en decisions = _Translations$moderation$decisions$en._(_root);
	@override String get noStatement => 'No restriction has been applied to your content.';
	@override String get complaintAction => 'Challenge this decision';
	@override String get complaintTitle => 'Challenge a decision';
	@override String get complaintIntro => 'You can challenge a moderation decision. Explain why you believe the decision is unjustified (article 20).';
	@override String get complaintExposeLabel => 'Your challenge';
	@override String get complaintExposeHint => 'Describe the reasons for your challenge.';
	@override String get complaintSubmit => 'Send challenge';
	@override String get complaintSent => 'Challenge recorded. It will be reviewed.';
	@override String get complaintEmpty => 'Please explain your challenge.';
	@override late final _Translations$moderation$a11y$en a11y = _Translations$moderation$a11y$en._(_root);
}

// Path: hub.trekCard
class _Translations$hub$trekCard$en extends Translations$hub$trekCard$fr {
	_Translations$hub$trekCard$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get activeTitle => 'Trek in progress';
	@override String get distanceCovered => 'Distance covered';
	@override String get elevationGain => 'Today\'s ascent';
	@override String get duration => 'Walking time';
	@override String progressLabel({required Object percent}) => '${percent}% of the trail';
	@override String get resume => 'Resume navigation';
	@override String get noTrekTitle => 'Ready to go?';
	@override String get noTrekBody => 'Plan your itinerary, then start your trek whenever you\'re ready.';
	@override String get plan => 'Plan my trek';
}

// Path: hub.weather
class _Translations$hub$weather$en extends Translations$hub$weather$fr {
	_Translations$hub$weather$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Today\'s weather';
	@override String get stub => 'Your stage weather is coming soon.';
	@override String get unavailable => 'Weather unavailable right now.';
	@override String get alertStorm => 'Storm alert';
	@override String tempRange({required Object min, required Object max}) => '${min}° / ${max}°';
}

// Path: hub.sections
class _Translations$hub$sections$en extends Translations$hub$sections$fr {
	_Translations$hub$sections$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get prepare => 'Prepare';
	@override String get hike => 'Hike';
	@override String get info => 'Information';
	@override String get after => 'After the trek';
}

// Path: hub.cards
class _Translations$hub$cards$en extends Translations$hub$cards$fr {
	_Translations$hub$cards$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get feasibility => 'Feasibility';
	@override String get feasibilitySub => 'Assess your level';
	@override String get itinerary => 'Itinerary';
	@override String get itinerarySub => 'The trail route';
	@override String get programme => 'Programme';
	@override String get programmeSub => 'Spread out your stages';
	@override String get checklist => 'Gear & bag';
	@override String get checklistSub => 'Pack your backpack';
	@override String get training => 'Physical prep';
	@override String get trainingSub => 'Your training programme';
	@override String get offline => 'Discover trails';
	@override String get offlineSub => 'Browse the catalogue';
	@override String get group => 'My group';
	@override String get groupSub => 'Track your companions';
	@override String get navigation => 'Navigation';
	@override String get navigationSub => 'Map and GPS tracking';
	@override String get journal => 'Journal';
	@override String get journalSub => 'Your notes and memories';
	@override String get accommodations => 'Accommodation';
	@override String get accommodationsSub => 'Where to sleep nearby';
	@override String get tips => 'Tip sheets';
	@override String get tipsSub => 'Our trekking tips';
	@override String get townGuides => 'Town guides';
	@override String get townGuidesSub => 'Practical info for each stage';
	@override String get recap => 'Recap';
	@override String get recapSub => 'Your adventure summed up';
	@override String get diploma => 'Diploma';
	@override String get diplomaSub => 'Your finisher certificate';
}

// Path: hub.fab
class _Translations$hub$fab$en extends Translations$hub$fab$fr {
	_Translations$hub$fab$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get feedback => 'Give feedback';
	@override String get sos => 'SOS';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$en extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Easy';
	@override String get moderate => 'Moderate';
	@override String get hard => 'Hard';
	@override String get expert => 'Expert';
}

// Path: accommodation.types
class _Translations$accommodation$types$en extends Translations$accommodation$types$fr {
	_Translations$accommodation$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Mountain hut';
	@override String get bergerie => 'Shepherd\'s hut';
	@override String get gite => 'Lodge';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campsite';
	@override String get bivouac => 'Bivouac';
}

// Path: checklist.categories
class _Translations$checklist$categories$en extends Translations$checklist$categories$fr {
	_Translations$checklist$categories$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Equipment';
	@override String get clothing => 'Clothing';
	@override String get food => 'Food';
	@override String get safety => 'Safety';
	@override String get documents => 'Documents';
	@override String get hygiene => 'Hygiene';
}

// Path: checklist.items
class _Translations$checklist$items$en extends Translations$checklist$items$fr {
	_Translations$checklist$items$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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

// Path: weather.source
class _Translations$weather$source$en extends Translations$weather$source$fr {
	_Translations$weather$source$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get api => 'Live data';
	@override String get cache => 'Saved data';
	@override String get offline => 'Offline';
	@override String get demo => 'Demo data';
}

// Path: weather.recommendation
class _Translations$weather$recommendation$en extends Translations$weather$recommendation$fr {
	_Translations$weather$recommendation$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ok => 'Favourable conditions';
	@override String get watch => 'Caution advised';
	@override String get danger => 'Unfavourable conditions';
}

// Path: weather.alert
class _Translations$weather$alert$en extends Translations$weather$alert$fr {
	_Translations$weather$alert$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$weather$alert$storm$en storm = _Translations$weather$alert$storm$en._(_root);
	@override late final _Translations$weather$alert$wind$en wind = _Translations$weather$alert$wind$en._(_root);
	@override late final _Translations$weather$alert$rain$en rain = _Translations$weather$alert$rain$en._(_root);
	@override late final _Translations$weather$alert$snow$en snow = _Translations$weather$alert$snow$en._(_root);
	@override late final _Translations$weather$alert$uv$en uv = _Translations$weather$alert$uv$en._(_root);
	@override late final _Translations$weather$alert$fire$en fire = _Translations$weather$alert$fire$en._(_root);
}

// Path: feasibility.levels
class _Translations$feasibility$levels$en extends Translations$feasibility$levels$fr {
	_Translations$feasibility$levels$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Not recommended';
	@override String get caution => 'Preparation needed';
	@override String get good => 'Feasible';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$en extends Translations$feasibility$categories$fr {
	_Translations$feasibility$categories$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$feasibility$questions$en extends Translations$feasibility$questions$fr {
	_Translations$feasibility$questions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$feasibility$answers$en extends Translations$feasibility$answers$fr {
	_Translations$feasibility$answers$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

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
class _Translations$feasibility$recommendations$en extends Translations$feasibility$recommendations$fr {
	_Translations$feasibility$recommendations$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$en danger = _Translations$feasibility$recommendations$danger$en._(_root);
	@override late final _Translations$feasibility$recommendations$caution$en caution = _Translations$feasibility$recommendations$caution$en._(_root);
	@override late final _Translations$feasibility$recommendations$good$en good = _Translations$feasibility$recommendations$good$en._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$en excellent = _Translations$feasibility$recommendations$excellent$en._(_root);
}

// Path: catalog.a11y
class _Translations$catalog$a11y$en extends Translations$catalog$a11y$fr {
	_Translations$catalog$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String enterButton({required Object nom}) => 'Enter trail ${nom}';
}

// Path: signalement.types
class _Translations$signalement$types$en extends Translations$signalement$types$fr {
	_Translations$signalement$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get obstacle => 'Obstacle on the trail';
	@override String get eauASec => 'Dry water point';
	@override String get danger => 'Danger';
}

// Path: hebergement.types
class _Translations$hebergement$types$en extends Translations$hebergement$types$fr {
	_Translations$hebergement$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Mountain hut';
	@override String get gite => 'Lodge';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Campsite';
	@override String get chambreHote => 'Bed & breakfast';
}

// Path: training.types
class _Translations$training$types$en extends Translations$training$types$fr {
	_Translations$training$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get marche => 'Walking';
	@override String get cardio => 'Cardio';
	@override String get renforcement => 'Strength';
}

// Path: training.intensity
class _Translations$training$intensity$en extends Translations$training$intensity$fr {
	_Translations$training$intensity$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get faible => 'Low';
	@override String get moderee => 'Moderate';
	@override String get elevee => 'High';
}

// Path: gamification.badge
class _Translations$gamification$badge$en extends Translations$gamification$badge$fr {
	_Translations$gamification$badge$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$gamification$badge$firstStage$en firstStage = _Translations$gamification$badge$firstStage$en._(_root);
	@override late final _Translations$gamification$badge$firstTrek$en firstTrek = _Translations$gamification$badge$firstTrek$en._(_root);
	@override late final _Translations$gamification$badge$firstSegment$en firstSegment = _Translations$gamification$badge$firstSegment$en._(_root);
	@override late final _Translations$gamification$badge$elevation5000$en elevation5000 = _Translations$gamification$badge$elevation5000$en._(_root);
	@override late final _Translations$gamification$badge$tenStages$en tenStages = _Translations$gamification$badge$tenStages$en._(_root);
	@override late final _Translations$gamification$badge$challenger$en challenger = _Translations$gamification$badge$challenger$en._(_root);
}

// Path: gamification.defi
class _Translations$gamification$defi$en extends Translations$gamification$defi$fr {
	_Translations$gamification$defi$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Challenges';
	@override String get inProgress => 'In progress';
	@override String progressLabel({required Object current, required Object target}) => 'Progress: ${current} / ${target}';
	@override String get rankingTitle => 'Challenge ranking';
	@override String get pseudonymNotice => 'Ranking by group, using pseudonyms. No direct personal data is shown.';
	@override String get notEnoughParticipants => 'Not enough participants to publish this ranking.';
	@override String get noDefi => 'No challenge in progress right now.';
}

// Path: waypoints.types
class _Translations$waypoints$types$en extends Translations$waypoints$types$fr {
	_Translations$waypoints$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get eau => 'Water';
	@override String get ravitaillement => 'Resupply';
	@override String get danger => 'Danger';
	@override String get camp => 'Campsite';
	@override String get connectivite => 'Connectivity';
	@override String get jonction => 'Junction';
}

// Path: waypoints.filters
class _Translations$waypoints$filters$en extends Translations$waypoints$filters$fr {
	_Translations$waypoints$filters$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filter waypoints';
	@override String get showAll => 'Show all';
	@override String get hideAll => 'Hide all';
	@override String get recentConditionOnly => 'Recent condition only';
}

// Path: waypoints.detail
class _Translations$waypoints$detail$en extends Translations$waypoints$detail$fr {
	_Translations$waypoints$detail$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get conditionsTitle => 'Field conditions';
	@override String get noComments => 'No condition reported yet.';
	@override String get commentsError => 'Conditions unavailable.';
	@override String get report => 'Report';
	@override String get reportAck => 'Report saved. It will be reviewed after sync.';
	@override String get pendingSync => 'Pending synchronization';
}

// Path: waypoints.freshness
class _Translations$waypoints$freshness$en extends Translations$waypoints$freshness$fr {
	_Translations$waypoints$freshness$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get justNow => 'updated just now';
	@override String minutes({required Object n}) => 'updated ${n} min ago';
	@override String hours({required Object n}) => 'updated ${n} h ago';
	@override String days({required Object n}) => 'updated ${n} d ago';
}

// Path: waypoints.contribution
class _Translations$waypoints$contribution$en extends Translations$waypoints$contribution$fr {
	_Translations$waypoints$contribution$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titleWaypoint => 'Add a waypoint';
	@override String get titleComment => 'Report a condition';
	@override String get chooseType => 'Waypoint type';
	@override String get titleField => 'Waypoint title';
	@override String get conditionPrompt => 'Describe the observed condition';
	@override String get commentField => 'Your observation';
	@override String get conditionField => 'State (optional)';
	@override String get conditionHelper => 'e.g. water dried up, water flowing, slippery section';
	@override String get latencyBanner => 'Will be published at the next network sync.';
	@override String get submit => 'Save';
	@override String get savedTitle => 'Contribution saved';
	@override String get savedPendingSync => 'It will be published when the network is back.';
	@override String pendingCount({required Object n}) => '${n} pending synchronization';
	@override String get close => 'Close';
	@override String get emptyTitle => 'Please enter a title for the waypoint.';
	@override String get emptyComment => 'Please enter your observation.';
	@override String get noLocation => 'GPS position unavailable. Try again under open sky.';
	@override String get error => 'Cannot save right now.';
}

// Path: packs.states
class _Translations$packs$states$en extends Translations$packs$states$fr {
	_Translations$packs$states$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get notDownloaded => 'Not downloaded';
	@override String get downloaded => 'Downloaded';
	@override String get updateAvailable => 'Update available';
}

// Path: packs.actions
class _Translations$packs$actions$en extends Translations$packs$actions$fr {
	_Translations$packs$actions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get download => 'Download';
	@override String get update => 'Update';
	@override String get delete => 'Delete';
	@override String get retry => 'Retry';
	@override String get buy => 'Buy this pack';
	@override String buyWithPrice({required Object price}) => 'Buy this pack — ${price}';
}

// Path: packs.progress
class _Translations$packs$progress$en extends Translations$packs$progress$fr {
	_Translations$packs$progress$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String downloading({required Object done, required Object total}) => 'Downloading… ${done}/${total}';
	@override String get verifying => 'Verifying integrity…';
	@override String get completed => 'Pack ready offline';
	@override String get error => 'Download failed';
}

// Path: packs.delete
class _Translations$packs$delete$en extends Translations$packs$delete$fr {
	_Translations$packs$delete$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => 'Delete this pack?';
	@override String get confirmBody => 'The pack will be removed from the device to free up space. You can download it again later.';
	@override String get cancel => 'Cancel';
	@override String get confirm => 'Delete';
	@override String get freed => 'Space freed.';
}

// Path: packs.a11y
class _Translations$packs$a11y$en extends Translations$packs$a11y$fr {
	_Translations$packs$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String packCard({required Object nom, required Object state}) => 'Pack ${nom}, ${state}';
	@override String downloadButton({required Object nom}) => 'Download pack ${nom}';
	@override String deleteButton({required Object nom}) => 'Delete pack ${nom}';
}

// Path: packs.types
class _Translations$packs$types$en extends Translations$packs$types$fr {
	_Translations$packs$types$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override late final _Translations$packs$types$nord$en nord = _Translations$packs$types$nord$en._(_root);
	@override late final _Translations$packs$types$sud$en sud = _Translations$packs$types$sud$en._(_root);
	@override late final _Translations$packs$types$complet$en complet = _Translations$packs$types$complet$en._(_root);
	@override late final _Translations$packs$types$mam$en mam = _Translations$packs$types$mam$en._(_root);
}

// Path: guides.categories
class _Translations$guides$categories$en extends Translations$guides$categories$fr {
	_Translations$guides$categories$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Resupply';
	@override String get hebergement => 'Accommodation';
	@override String get transport => 'Transport';
	@override String get services => 'Services';
	@override String get eau => 'Water';
	@override String get sante => 'Health';
}

// Path: guides.intro
class _Translations$guides$intro$en extends Translations$guides$intro$fr {
	_Translations$guides$intro$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Where to stock up on supplies.';
	@override String get hebergement => 'Where to sleep at the stage.';
	@override String get transport => 'Buses, shuttles and connections.';
	@override String get services => 'Post office, bank, laundry and more.';
	@override String get eau => 'Drinking water points.';
	@override String get sante => 'Pharmacy and nearby care.';
}

// Path: guides.a11y
class _Translations$guides$a11y$en extends Translations$guides$a11y$fr {
	_Translations$guides$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String guideCard({required Object lieu}) => 'Guide for ${lieu}';
	@override String section({required Object titre}) => 'Section ${titre}';
	@override String openSiteButton({required Object nom}) => 'Open the website of ${nom}';
}

// Path: health.field
class _Translations$health$field$en extends Translations$health$field$fr {
	_Translations$health$field$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Blood type';
	@override String get allergies => 'Allergies';
	@override String get treatments => 'Current treatments';
	@override String get doctor => 'Family doctor';
	@override String get insurance => 'Insurance no. / health cover';
}

// Path: health.hint
class _Translations$health$hint$en extends Translations$health$hint$fr {
	_Translations$health$hint$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'e.g. A+, O-, AB+';
	@override String get allergies => 'e.g. penicillin, peanuts';
	@override String get treatments => 'e.g. Levothyrox 50 mg/day';
	@override String get doctor => 'e.g. Dr Smith +44 20 xxxx xxxx';
	@override String get insurance => 'e.g. European health card';
}

// Path: health.a11y
class _Translations$health$a11y$en extends Translations$health$a11y$fr {
	_Translations$health$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get form => 'Health information form';
	@override String get saveButton => 'Save health information';
}

// Path: trailSelection.a11y
class _Translations$trailSelection$a11y$en extends Translations$trailSelection$a11y$fr {
	_Translations$trailSelection$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String trailCard({required Object nom, required Object region}) => 'Trail ${nom}, ${region}';
	@override String get currentBadge => 'Currently active trail';
	@override String selectButton({required Object nom}) => 'Activate trail ${nom}';
}

// Path: consent.purposes
class _Translations$consent$purposes$en extends Translations$consent$purposes$fr {
	_Translations$consent$purposes$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get locationNavigation => 'Personal navigation';
	@override String get locationNavigationDesc => 'Use your location for the map and to track your stage. Stays on your device.';
	@override String get socialSharing => 'Social sharing';
	@override String get socialSharingDesc => 'Appear in leaderboards and the community feed, under a pseudonym.';
	@override String get publicReporting => 'Public reporting';
	@override String get publicReportingDesc => 'Post reports (water, hazard, conditions) visible to other hikers.';
	@override String get healthData => 'Health data';
	@override String get healthDataDesc => 'Read your heart rate (chest strap or health app) to enrich your effort tracking.';
}

// Path: consent.a11y
class _Translations$consent$a11y$en extends Translations$consent$a11y$fr {
	_Translations$consent$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String purposeToggle({required Object purpose, required Object state}) => '${purpose}, currently ${state}';
	@override String get healthSection => 'Health data section, reinforced consent';
	@override String get policyButton => 'Open the privacy policy';
}

// Path: moderation.reasons
class _Translations$moderation$reasons$en extends Translations$moderation$reasons$fr {
	_Translations$moderation$reasons$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get illegal => 'Illegal content';
	@override String get harassment => 'Harassment or hate';
	@override String get spam => 'Spam or advertising';
	@override String get dangerous => 'Dangerous or misleading information';
	@override String get other => 'Other';
}

// Path: moderation.decisions
class _Translations$moderation$decisions$en extends Translations$moderation$decisions$fr {
	_Translations$moderation$decisions$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get keep => 'Content kept';
	@override String get restrict => 'Content restricted';
	@override String get remove => 'Content removed';
}

// Path: moderation.a11y
class _Translations$moderation$a11y$en extends Translations$moderation$a11y$fr {
	_Translations$moderation$a11y$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get reportForm => 'Content reporting form';
	@override String get reasonSelector => 'Report reason selector';
	@override String goodFaithToggle({required Object state}) => 'Good-faith declaration, ${state}';
	@override String get submitReport => 'Send report';
	@override String get statementCard => 'Statement of reasons for the moderation decision';
	@override String get complaintForm => 'Decision challenge form';
}

// Path: weather.alert.storm
class _Translations$weather$alert$storm$en extends Translations$weather$alert$storm$fr {
	_Translations$weather$alert$storm$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Storm expected';
	@override String desc({required Object condition}) => '${condition}. Avoid ridges and exposed areas.';
}

// Path: weather.alert.wind
class _Translations$weather$alert$wind$en extends Translations$weather$alert$wind$fr {
	_Translations$weather$alert$wind$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Strong wind';
	@override String desc({required Object value}) => 'Gusts up to ${value} km/h. Take care on exposed sections.';
}

// Path: weather.alert.rain
class _Translations$weather$alert$rain$en extends Translations$weather$alert$rain$fr {
	_Translations$weather$alert$rain$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Heavy rainfall';
	@override String desc({required Object value}) => '${value} mm expected. Risk of slippery trails and torrents.';
}

// Path: weather.alert.snow
class _Translations$weather$alert$snow$en extends Translations$weather$alert$snow$fr {
	_Translations$weather$alert$snow$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Snow expected';
	@override String desc({required Object condition}) => '${condition}. Suitable gear required.';
}

// Path: weather.alert.uv
class _Translations$weather$alert$uv$en extends Translations$weather$alert$uv$fr {
	_Translations$weather$alert$uv$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Very high UV';
	@override String desc({required Object value}) => 'UV index ${value}. Maximum sun protection recommended.';
}

// Path: weather.alert.fire
class _Translations$weather$alert$fire$en extends Translations$weather$alert$fire$fr {
	_Translations$weather$alert$fire$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fire risk';
	@override String desc({required Object value}) => '${value}°C expected. High fire risk.';
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$en extends Translations$feasibility$recommendations$danger$fr {
	_Translations$feasibility$recommendations$danger$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Insufficient preparation';
	@override String get summary => 'Your profile shows significant gaps. We do not recommend starting in this state.';
	@override late final _Translations$feasibility$recommendations$danger$tips$en tips = _Translations$feasibility$recommendations$danger$tips$en._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$en extends Translations$feasibility$recommendations$caution$fr {
	_Translations$feasibility$recommendations$caution$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparation needs work';
	@override String get summary => 'You have a foundation, but some areas need attention before departure.';
	@override late final _Translations$feasibility$recommendations$caution$tips$en tips = _Translations$feasibility$recommendations$caution$tips$en._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$en extends Translations$feasibility$recommendations$good$fr {
	_Translations$feasibility$recommendations$good$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Good preparation';
	@override String get summary => 'Your profile is solid. A few adjustments and you will be ready.';
	@override late final _Translations$feasibility$recommendations$good$tips$en tips = _Translations$feasibility$recommendations$good$tips$en._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$en extends Translations$feasibility$recommendations$excellent$fr {
	_Translations$feasibility$recommendations$excellent$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get title => 'Optimal preparation';
	@override String get summary => 'You are perfectly prepared. Enjoy the trek with peace of mind!';
	@override late final _Translations$feasibility$recommendations$excellent$tips$en tips = _Translations$feasibility$recommendations$excellent$tips$en._(_root);
}

// Path: gamification.badge.firstStage
class _Translations$gamification$badge$firstStage$en extends Translations$gamification$badge$firstStage$fr {
	_Translations$gamification$badge$firstStage$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'First stage';
	@override String get description => 'You completed your first stage.';
}

// Path: gamification.badge.firstTrek
class _Translations$gamification$badge$firstTrek$en extends Translations$gamification$badge$firstTrek$fr {
	_Translations$gamification$badge$firstTrek$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'First trek';
	@override String get description => 'You finished your first full trek.';
}

// Path: gamification.badge.firstSegment
class _Translations$gamification$badge$firstSegment$en extends Translations$gamification$badge$firstSegment$fr {
	_Translations$gamification$badge$firstSegment$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'First segment';
	@override String get description => 'You ran your first segment.';
}

// Path: gamification.badge.elevation5000
class _Translations$gamification$badge$elevation5000$en extends Translations$gamification$badge$elevation5000$fr {
	_Translations$gamification$badge$elevation5000$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => '5000 m of elevation';
	@override String get description => 'You accumulated 5000 m of elevation gain.';
}

// Path: gamification.badge.tenStages
class _Translations$gamification$badge$tenStages$en extends Translations$gamification$badge$tenStages$fr {
	_Translations$gamification$badge$tenStages$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => '10 stages';
	@override String get description => 'You completed 10 stages.';
}

// Path: gamification.badge.challenger
class _Translations$gamification$badge$challenger$en extends Translations$gamification$badge$challenger$fr {
	_Translations$gamification$badge$challenger$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Challenger';
	@override String get description => 'You completed your first seasonal challenge.';
}

// Path: packs.types.nord
class _Translations$packs$types$nord$en extends Translations$packs$types$nord$fr {
	_Translations$packs$types$nord$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare North';
	@override String get description => 'The northern half of the trail, offline.';
}

// Path: packs.types.sud
class _Translations$packs$types$sud$en extends Translations$packs$types$sud$fr {
	_Translations$packs$types$sud$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare South';
	@override String get description => 'The southern half of the trail, offline.';
}

// Path: packs.types.complet
class _Translations$packs$types$complet$en extends Translations$packs$types$complet$fr {
	_Translations$packs$types$complet$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Full';
	@override String get description => 'The whole trail, offline.';
}

// Path: packs.types.mam
class _Translations$packs$types$mam$en extends Translations$packs$types$mam$fr {
	_Translations$packs$types$mam$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare';
	@override String get description => 'The Mare a Mare trail, offline.';
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$en extends Translations$feasibility$recommendations$danger$tips$fr {
	_Translations$feasibility$recommendations$danger$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Start with short hikes to assess your fitness level';
	@override String get tip2 => 'Consult a healthcare professional before prolonged effort';
	@override String get tip3 => 'Invest in proper equipment and test it beforehand';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$en extends Translations$feasibility$recommendations$caution$tips$fr {
	_Translations$feasibility$recommendations$caution$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Strengthen your physical training 6 to 8 weeks ahead';
	@override String get tip2 => 'Check and complete your equipment';
	@override String get tip3 => 'Plan stages suited to your level';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$en extends Translations$feasibility$recommendations$good$tips$fr {
	_Translations$feasibility$recommendations$good$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Maintain your training pace until departure';
	@override String get tip2 => 'Include margins in your planning';
	@override String get tip3 => 'Check the weather regularly before departure';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$en extends Translations$feasibility$recommendations$excellent$tips$fr {
	_Translations$feasibility$recommendations$excellent$tips$en._(TranslationsEn root) : this._root = root, super.internal(root);

	final TranslationsEn _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Listen to your body during the trek';
	@override String get tip2 => 'Share your experience with fellow hikers';
	@override String get tip3 => 'Consider documenting your adventure in the journal';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEn {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'a11y.back' => 'Back',
			'a11y.zoomIn' => 'Zoom in',
			'a11y.zoomOut' => 'Zoom out',
			'a11y.centerOnMe' => 'Center on my position',
			'a11y.mapRegion' => 'Trail map',
			'a11y.userPosition' => 'Your position',
			'a11y.stageMarker' => ({required Object number}) => 'Stage ${number}',
			'a11y.poiMarker' => ({required Object name}) => 'Point of interest: ${name}',
			'a11y.markerCluster' => ({required Object count}) => '${count} grouped points',
			'a11y.trailCard' => ({required Object name}) => 'Trail ${name}',
			'a11y.startTracking' => 'Start tracking',
			'a11y.pauseTracking' => 'Pause tracking',
			'a11y.resumeTracking' => 'Resume tracking',
			'a11y.stopTracking' => 'Stop tracking',
			'nav.accueil' => 'Home',
			'nav.map' => 'Map',
			'nav.stages' => 'Stages',
			'nav.planning' => 'Planning',
			'nav.journal' => 'Journal',
			'nav.more' => 'More',
			'nav.checklist' => 'Gear checklist',
			'nav.feasibility' => 'Feasibility',
			'nav.tips' => 'Trek tips',
			'nav.emergency' => 'Emergency contacts',
			'nav.catalog' => 'Trail catalog',
			'nav.profile' => 'Profile',
			'nav.settings' => 'Settings',
			'nav.trailSelection' => 'Switch trail',
			'branding.tagline' => 'Your trekking companion',
			'branding.subline' => 'Prepare, hike, share',
			'hub.greeting' => ({required Object name}) => 'Hello, ${name}!',
			'hub.greetingFallback' => 'Hiker',
			'hub.infoTooltip' => 'About this trail',
			'hub.profileTooltip' => 'My profile',
			'hub.infoSheetBody' => 'This trail guides you every step of the way: plan your itinerary, pack your bag, then set off with GPS navigation. Every feature is reachable from this home screen.',
			'hub.trekCard.activeTitle' => 'Trek in progress',
			'hub.trekCard.distanceCovered' => 'Distance covered',
			'hub.trekCard.elevationGain' => 'Today\'s ascent',
			'hub.trekCard.duration' => 'Walking time',
			'hub.trekCard.progressLabel' => ({required Object percent}) => '${percent}% of the trail',
			'hub.trekCard.resume' => 'Resume navigation',
			'hub.trekCard.noTrekTitle' => 'Ready to go?',
			'hub.trekCard.noTrekBody' => 'Plan your itinerary, then start your trek whenever you\'re ready.',
			'hub.trekCard.plan' => 'Plan my trek',
			'hub.weather.title' => 'Today\'s weather',
			'hub.weather.stub' => 'Your stage weather is coming soon.',
			'hub.weather.unavailable' => 'Weather unavailable right now.',
			'hub.weather.alertStorm' => 'Storm alert',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Start the trek',
			'hub.sections.prepare' => 'Prepare',
			'hub.sections.hike' => 'Hike',
			'hub.sections.info' => 'Information',
			'hub.sections.after' => 'After the trek',
			'hub.cards.feasibility' => 'Feasibility',
			'hub.cards.feasibilitySub' => 'Assess your level',
			'hub.cards.itinerary' => 'Itinerary',
			'hub.cards.itinerarySub' => 'The trail route',
			'hub.cards.programme' => 'Programme',
			'hub.cards.programmeSub' => 'Spread out your stages',
			'hub.cards.checklist' => 'Gear & bag',
			'hub.cards.checklistSub' => 'Pack your backpack',
			'hub.cards.training' => 'Physical prep',
			'hub.cards.trainingSub' => 'Your training programme',
			'hub.cards.offline' => 'Discover trails',
			'hub.cards.offlineSub' => 'Browse the catalogue',
			'hub.cards.group' => 'My group',
			'hub.cards.groupSub' => 'Track your companions',
			'hub.cards.navigation' => 'Navigation',
			'hub.cards.navigationSub' => 'Map and GPS tracking',
			'hub.cards.journal' => 'Journal',
			'hub.cards.journalSub' => 'Your notes and memories',
			'hub.cards.accommodations' => 'Accommodation',
			'hub.cards.accommodationsSub' => 'Where to sleep nearby',
			'hub.cards.tips' => 'Tip sheets',
			'hub.cards.tipsSub' => 'Our trekking tips',
			'hub.cards.townGuides' => 'Town guides',
			'hub.cards.townGuidesSub' => 'Practical info for each stage',
			'hub.cards.recap' => 'Recap',
			'hub.cards.recapSub' => 'Your adventure summed up',
			'hub.cards.diploma' => 'Diploma',
			'hub.cards.diplomaSub' => 'Your finisher certificate',
			'hub.fab.feedback' => 'Give feedback',
			'hub.fab.sos' => 'SOS',
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
			'accommodation.types.refuge' => 'Mountain hut',
			'accommodation.types.bergerie' => 'Shepherd\'s hut',
			'accommodation.types.gite' => 'Lodge',
			'accommodation.types.hotel' => 'Hotel',
			'accommodation.types.camping' => 'Campsite',
			'accommodation.types.bivouac' => 'Bivouac',
			'gps.permission' => 'GPS permission required',
			'gps.denied' => 'Location access denied',
			'gps.disabled' => 'Location service disabled',
			'gps.offTrack' => 'Off track',
			'gps.centerOnMe' => 'Center on my position',
			'navAlert.offTrackBanner' => ({required Object meters}) => 'You are moving away from the trail — ${meters} m. Check your position.',
			'navAlert.offTrackNotifTitle' => 'You are leaving the trail',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'You are moving away from the trail (${meters} m). Check your position.',
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
			'weather.today' => 'Today',
			'weather.tomorrow' => 'Tomorrow',
			'weather.dayPlus2' => 'In two days',
			'weather.allStages' => 'All stages',
			'weather.noForecast' => 'No forecast available.',
			'weather.stageLabel' => ({required Object number}) => 'Stage ${number}',
			'weather.stormAlertsTitle' => 'Storm alerts',
			'weather.stormAlertsToggleOn' => 'Storm alerts on',
			'weather.stormAlertsToggleOff' => 'Storm alerts off',
			'weather.lastUpdate' => ({required Object date}) => 'Updated ${date}',
			'weather.guideTitle' => 'Understanding the weather',
			'weather.guideBody' => 'Forecasts cover 7 days for each stage. Watch storm and wind alerts: in the mountains, weather changes fast. When offline, the last saved data is shown.',
			'weather.source.api' => 'Live data',
			'weather.source.cache' => 'Saved data',
			'weather.source.offline' => 'Offline',
			'weather.source.demo' => 'Demo data',
			'weather.recommendation.ok' => 'Favourable conditions',
			'weather.recommendation.watch' => 'Caution advised',
			'weather.recommendation.danger' => 'Unfavourable conditions',
			'weather.alert.storm.title' => 'Storm expected',
			'weather.alert.storm.desc' => ({required Object condition}) => '${condition}. Avoid ridges and exposed areas.',
			'weather.alert.wind.title' => 'Strong wind',
			'weather.alert.wind.desc' => ({required Object value}) => 'Gusts up to ${value} km/h. Take care on exposed sections.',
			'weather.alert.rain.title' => 'Heavy rainfall',
			'weather.alert.rain.desc' => ({required Object value}) => '${value} mm expected. Risk of slippery trails and torrents.',
			'weather.alert.snow.title' => 'Snow expected',
			'weather.alert.snow.desc' => ({required Object condition}) => '${condition}. Suitable gear required.',
			'weather.alert.uv.title' => 'Very high UV',
			'weather.alert.uv.desc' => ({required Object value}) => 'UV index ${value}. Maximum sun protection recommended.',
			'weather.alert.fire.title' => 'Fire risk',
			'weather.alert.fire.desc' => ({required Object value}) => '${value}°C expected. High fire risk.',
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
			'settings.offTrackAlerts' => 'Off-track alert',
			'settings.offTrackAlertsDesc' => 'Notification + vibration if you leave the trail',
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
			'auth.anonymous' => 'Hiker without account',
			'auth.connectedVia' => 'Connected via',
			'auth.signInGoogle' => 'Sign in with Google',
			'auth.signInGoogleDesc' => 'To save your progress',
			'auth.signOut' => 'Sign out',
			'auth.signOutDesc' => 'Return to no-account mode',
			'auth.signOutConfirm' => 'Sign out?',
			'auth.signOutMessage' => 'You will return to no-account mode. Your local data is preserved.',
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
			'noData.title' => 'No trail downloaded',
			'noData.subtitle' => 'Download a trail to get started',
			'noData.offlineHint' => 'Data will be available offline for your hike.',
			'noData.browseCta' => 'Browse trails',
			'catalog.title' => 'Trail catalog',
			'catalog.enter' => 'Enter',
			'catalog.mustDownload' => 'Download this trail to explore it.',
			'catalog.emptyTitle' => 'No trail available',
			'catalog.emptySubtitle' => 'No trail is offered in the catalog yet.',
			'catalog.a11y.enterButton' => ({required Object nom}) => 'Enter trail ${nom}',
			'updates.readyTitle' => 'Update ready',
			'updates.readyBodyOne' => 'One trail has been updated.',
			'updates.readyBodyMany' => ({required Object count}) => '${count} trails have been updated.',
			'follow.title' => 'Live tracking',
			'follow.connecting' => 'Connecting…',
			'follow.live' => 'Live',
			'follow.offline' => 'Offline',
			'follow.invalidLink' => 'Invalid link',
			'follow.invalidLinkHint' => 'This tracking link does not exist or has expired.',
			'cloud.localModeTitle' => 'Local mode',
			'cloud.localModeBody' => 'This installation is not connected to a cloud service: live tracking, online backup and account are disabled. Your data stays on this device.',
			'cloud.statusSection' => 'Cloud',
			'cloud.statusActive' => 'Online services active',
			'cloud.statusActiveDesc' => 'Backup and live tracking available.',
			'cloud.statusLocal' => 'Local mode (no cloud)',
			'cloud.statusLocalDesc' => 'No data is sent online. Cloud configuration absent.',
			'onboarding.skip' => 'Skip',
			'onboarding.next' => 'Next',
			'onboarding.getStarted' => 'Get started',
			'onboarding.welcomeTitle' => ({required Object appName}) => 'Welcome to ${appName}',
			'onboarding.welcomeSubtitle' => 'Your offline hiking companion: map, GPS navigation, planning and trek journal.',
			'onboarding.languageTitle' => 'Choose your language',
			'onboarding.languageSubtitle' => 'You can change it at any time in the settings.',
			'onboarding.downloadTitle' => 'Download your first trail',
			'onboarding.downloadSubtitle' => 'Browse the catalogue and download a trail to use it fully offline.',
			'onboarding.browseCatalog' => 'Browse the catalogue',
			'monetization.demoBanner' => 'Demo mode — tap to unlock',
			'monetization.paywallTitle' => 'Unlock this trek',
			'monetization.paywallBody' => 'Free mode lets you plan your trek with ads. Premium unlocks everything, ad-free.',
			'monetization.featureMap' => 'Offline map + GPS + live tracking',
			'monetization.featureJournal' => 'Full trek journal',
			'monetization.featureDiploma' => 'End-of-trek diploma',
			'monetization.featureFollowers' => '2 free followers',
			'monetization.featureNoAds' => 'Zero ads',
			'monetization.buyCta' => 'Unlock this trek',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Unlock this trek — €${price}',
			'signalement.title' => 'Report',
			'signalement.chooseType' => 'What do you want to report?',
			'signalement.types.obstacle' => 'Obstacle on the trail',
			'signalement.types.eauASec' => 'Dry water point',
			'signalement.types.danger' => 'Danger',
			'signalement.latencyBanner' => 'Saved. Visible to other hikers once the network syncs.',
			'signalement.confirm' => 'Confirm report',
			'signalement.noLocation' => 'GPS position unavailable right now. Try again under open sky.',
			'signalement.savedTitle' => 'Report saved',
			'signalement.savedPendingSync' => 'It will be shared as soon as the network is back.',
			'signalement.pendingCount' => ({required Object n}) => '${n} awaiting sync',
			'signalement.close' => 'Close',
			'hebergement.title' => 'Nearby accommodation',
			_ => null,
		} ?? switch (path) {
			'hebergement.facilitatorNote' => 'StepWays points you to the hosts. Booking happens on their website: no payment inside the app.',
			'hebergement.detourAR' => ({required Object km}) => 'Round-trip detour: ${km} km',
			'hebergement.openSite' => 'View website',
			'hebergement.cannotOpen' => 'Could not open this link on this device.',
			'hebergement.empty' => 'No accommodation listed nearby for now.',
			'hebergement.types.refuge' => 'Mountain hut',
			'hebergement.types.gite' => 'Lodge',
			'hebergement.types.hotel' => 'Hotel',
			'hebergement.types.camping' => 'Campsite',
			'hebergement.types.chambreHote' => 'Bed & breakfast',
			'training.title' => 'Physical preparation',
			'training.localNotice' => 'Your plan is computed and kept on your phone. Reminders are local notifications, with no tracking.',
			'training.reminderTitle' => 'Training session today',
			'training.scheduleReminders' => 'Schedule reminders',
			'training.remindersScheduled' => ({required Object n}) => '${n} reminder(s) scheduled',
			'training.week' => ({required Object n}) => 'Week ${n}',
			'training.minutes' => ({required Object n}) => '${n} min',
			'training.progress' => ({required Object done, required Object total}) => '${done}/${total} sessions done',
			'training.types.marche' => 'Walking',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Strength',
			'training.intensity.faible' => 'Low',
			'training.intensity.moderee' => 'Moderate',
			'training.intensity.elevee' => 'High',
			'eta.title' => 'Estimated time',
			'eta.toNextWaypoint' => 'Next point',
			'eta.toStageEnd' => 'Stage end',
			'eta.confidenceHigh' => 'Reliable estimate',
			'eta.confidenceLow' => 'Approximate (weak GPS)',
			'eta.durationHm' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'eta.durationM' => ({required Object m}) => '${m} min',
			'leaderboard.title' => 'King of the stage',
			'leaderboard.unavailable' => 'Leaderboard unavailable right now.',
			'leaderboard.empty' => 'No ranking for this segment yet. Be the first to run it!',
			'leaderboard.pseudonymNotice' => 'Ranking by group, using pseudonyms. No direct personal data is shown.',
			'leaderboard.trancheLabel' => ({required Object tranche}) => 'Group: ${tranche}',
			'leaderboard.notEnoughParticipants' => 'Not enough participants to publish this ranking.',
			'leaderboard.entrySemantics' => ({required Object rank, required Object pseudonym, required Object time}) => 'Rank ${rank}, ${pseudonym}, time ${time}',
			'social.feedTitle' => 'Activity feed',
			'social.empty' => 'No activity yet.',
			'social.kudos' => 'Give kudos',
			'social.kudosCount' => ({required Object n}) => '${n} kudos',
			'social.report' => 'Report',
			'social.reportTitle' => 'Report this post',
			'social.reportReasonLabel' => 'Reason for reporting',
			'social.reasonSpam' => 'Spam or advertising',
			'social.reasonAbuse' => 'Abusive or hateful content',
			'social.reasonOther' => 'Other',
			'social.reportSend' => 'Send report',
			'social.reportSent' => 'Report sent. Our team will review it.',
			'social.syncPending' => 'Waiting for sync',
			'social.synced' => 'Synced',
			'social.activitySegment' => 'completed a segment',
			'social.activityBadge' => 'earned a badge',
			'social.activityDefi' => 'made progress on a challenge',
			'gamification.galleryTitle' => 'My badges',
			'gamification.obtained' => 'Earned',
			'gamification.locked' => 'Locked',
			'gamification.tierDebutant' => 'Beginner',
			'gamification.tierExpert' => 'Expert',
			'gamification.badge.firstStage.titre' => 'First stage',
			'gamification.badge.firstStage.description' => 'You completed your first stage.',
			'gamification.badge.firstTrek.titre' => 'First trek',
			'gamification.badge.firstTrek.description' => 'You finished your first full trek.',
			'gamification.badge.firstSegment.titre' => 'First segment',
			'gamification.badge.firstSegment.description' => 'You ran your first segment.',
			'gamification.badge.elevation5000.titre' => '5000 m of elevation',
			'gamification.badge.elevation5000.description' => 'You accumulated 5000 m of elevation gain.',
			'gamification.badge.tenStages.titre' => '10 stages',
			'gamification.badge.tenStages.description' => 'You completed 10 stages.',
			'gamification.badge.challenger.titre' => 'Challenger',
			'gamification.badge.challenger.description' => 'You completed your first seasonal challenge.',
			'gamification.defi.screenTitle' => 'Challenges',
			'gamification.defi.inProgress' => 'In progress',
			'gamification.defi.progressLabel' => ({required Object current, required Object target}) => 'Progress: ${current} / ${target}',
			'gamification.defi.rankingTitle' => 'Challenge ranking',
			'gamification.defi.pseudonymNotice' => 'Ranking by group, using pseudonyms. No direct personal data is shown.',
			'gamification.defi.notEnoughParticipants' => 'Not enough participants to publish this ranking.',
			'gamification.defi.noDefi' => 'No challenge in progress right now.',
			'shareVisibility.title' => 'Sharing and visibility',
			'shareVisibility.intro' => 'By default, nothing is shared. Turn on below, purpose by purpose, what you want to make visible.',
			'shareVisibility.consentLink' => 'Manage my consent (privacy)',
			'shareVisibility.stageResults' => 'Share my stage results',
			'shareVisibility.stageResultsDesc' => 'A pseudonymous card (no direct personal data).',
			'shareVisibility.leaderboard' => 'Appear in leaderboards',
			'shareVisibility.leaderboardDesc' => 'Ranking by group, using a pseudonym.',
			'shareVisibility.activityFeed' => 'Post to the activity feed',
			'shareVisibility.activityFeedDesc' => 'Your activities appear in the feed, under a pseudonym.',
			'shareVisibility.shareTitle' => 'Share this stage',
			'shareVisibility.shareButton' => 'Share',
			'shareVisibility.privateNotice' => 'Sharing is off. Turn it on in Sharing and visibility.',
			'shareVisibility.shared' => 'Card ready to share.',
			'waypoints.types.eau' => 'Water',
			'waypoints.types.ravitaillement' => 'Resupply',
			'waypoints.types.danger' => 'Danger',
			'waypoints.types.camp' => 'Campsite',
			'waypoints.types.connectivite' => 'Connectivity',
			'waypoints.types.jonction' => 'Junction',
			'waypoints.filters.title' => 'Filter waypoints',
			'waypoints.filters.showAll' => 'Show all',
			'waypoints.filters.hideAll' => 'Hide all',
			'waypoints.filters.recentConditionOnly' => 'Recent condition only',
			'waypoints.detail.conditionsTitle' => 'Field conditions',
			'waypoints.detail.noComments' => 'No condition reported yet.',
			'waypoints.detail.commentsError' => 'Conditions unavailable.',
			'waypoints.detail.report' => 'Report',
			'waypoints.detail.reportAck' => 'Report saved. It will be reviewed after sync.',
			'waypoints.detail.pendingSync' => 'Pending synchronization',
			'waypoints.freshness.justNow' => 'updated just now',
			'waypoints.freshness.minutes' => ({required Object n}) => 'updated ${n} min ago',
			'waypoints.freshness.hours' => ({required Object n}) => 'updated ${n} h ago',
			'waypoints.freshness.days' => ({required Object n}) => 'updated ${n} d ago',
			'waypoints.contribution.titleWaypoint' => 'Add a waypoint',
			'waypoints.contribution.titleComment' => 'Report a condition',
			'waypoints.contribution.chooseType' => 'Waypoint type',
			'waypoints.contribution.titleField' => 'Waypoint title',
			'waypoints.contribution.conditionPrompt' => 'Describe the observed condition',
			'waypoints.contribution.commentField' => 'Your observation',
			'waypoints.contribution.conditionField' => 'State (optional)',
			'waypoints.contribution.conditionHelper' => 'e.g. water dried up, water flowing, slippery section',
			'waypoints.contribution.latencyBanner' => 'Will be published at the next network sync.',
			'waypoints.contribution.submit' => 'Save',
			'waypoints.contribution.savedTitle' => 'Contribution saved',
			'waypoints.contribution.savedPendingSync' => 'It will be published when the network is back.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} pending synchronization',
			'waypoints.contribution.close' => 'Close',
			'waypoints.contribution.emptyTitle' => 'Please enter a title for the waypoint.',
			'waypoints.contribution.emptyComment' => 'Please enter your observation.',
			'waypoints.contribution.noLocation' => 'GPS position unavailable. Try again under open sky.',
			'waypoints.contribution.error' => 'Cannot save right now.',
			'packs.title' => 'Trail packs',
			'packs.subtitle' => 'Download a pack to hike 100% offline.',
			'packs.alaCarteNote' => 'A la carte: buy only the pack you need, no subscription.',
			'packs.size' => ({required Object mo}) => '${mo} MB',
			'packs.states.notDownloaded' => 'Not downloaded',
			'packs.states.downloaded' => 'Downloaded',
			'packs.states.updateAvailable' => 'Update available',
			'packs.actions.download' => 'Download',
			'packs.actions.update' => 'Update',
			'packs.actions.delete' => 'Delete',
			'packs.actions.retry' => 'Retry',
			'packs.actions.buy' => 'Buy this pack',
			'packs.actions.buyWithPrice' => ({required Object price}) => 'Buy this pack — ${price}',
			'packs.progress.downloading' => ({required Object done, required Object total}) => 'Downloading… ${done}/${total}',
			'packs.progress.verifying' => 'Verifying integrity…',
			'packs.progress.completed' => 'Pack ready offline',
			'packs.progress.error' => 'Download failed',
			'packs.delete.confirmTitle' => 'Delete this pack?',
			'packs.delete.confirmBody' => 'The pack will be removed from the device to free up space. You can download it again later.',
			'packs.delete.cancel' => 'Cancel',
			'packs.delete.confirm' => 'Delete',
			'packs.delete.freed' => 'Space freed.',
			'packs.empty' => 'No pack available for this trail.',
			'packs.a11y.packCard' => ({required Object nom, required Object state}) => 'Pack ${nom}, ${state}',
			'packs.a11y.downloadButton' => ({required Object nom}) => 'Download pack ${nom}',
			'packs.a11y.deleteButton' => ({required Object nom}) => 'Delete pack ${nom}',
			'packs.types.nord.nom' => 'Mare a Mare North',
			'packs.types.nord.description' => 'The northern half of the trail, offline.',
			'packs.types.sud.nom' => 'Mare a Mare South',
			'packs.types.sud.description' => 'The southern half of the trail, offline.',
			'packs.types.complet.nom' => 'Mare a Mare Full',
			'packs.types.complet.description' => 'The whole trail, offline.',
			'packs.types.mam.nom' => 'Mare a Mare',
			'packs.types.mam.description' => 'The Mare a Mare trail, offline.',
			'guides.title' => 'Town guides',
			'guides.subtitle' => 'Practical info for towns and villages, available offline.',
			'guides.sectionsCount' => ({required Object n}) => '${n} practical sections',
			'guides.empty' => 'No guide available for this trail.',
			'guides.noItems' => 'No information in this section yet.',
			'guides.facilitatorNote' => 'StepWays points you to providers. Booking and payment happen on their site: nothing in the app.',
			'guides.openSite' => 'Open website',
			'guides.cannotOpen' => 'Can\'t open this link on this device.',
			'guides.categories.ravitaillement' => 'Resupply',
			'guides.categories.hebergement' => 'Accommodation',
			'guides.categories.transport' => 'Transport',
			'guides.categories.services' => 'Services',
			'guides.categories.eau' => 'Water',
			'guides.categories.sante' => 'Health',
			'guides.intro.ravitaillement' => 'Where to stock up on supplies.',
			'guides.intro.hebergement' => 'Where to sleep at the stage.',
			'guides.intro.transport' => 'Buses, shuttles and connections.',
			'guides.intro.services' => 'Post office, bank, laundry and more.',
			'guides.intro.eau' => 'Drinking water points.',
			'guides.intro.sante' => 'Pharmacy and nearby care.',
			'guides.a11y.guideCard' => ({required Object lieu}) => 'Guide for ${lieu}',
			'guides.a11y.section' => ({required Object titre}) => 'Section ${titre}',
			'guides.a11y.openSiteButton' => ({required Object nom}) => 'Open the website of ${nom}',
			'health.title' => 'Health information',
			'health.privacyBanner' => 'This data stays on your phone. It is never sent over the internet.',
			'health.field.bloodType' => 'Blood type',
			'health.field.allergies' => 'Allergies',
			'health.field.treatments' => 'Current treatments',
			'health.field.doctor' => 'Family doctor',
			'health.field.insurance' => 'Insurance no. / health cover',
			'health.hint.bloodType' => 'e.g. A+, O-, AB+',
			'health.hint.allergies' => 'e.g. penicillin, peanuts',
			'health.hint.treatments' => 'e.g. Levothyrox 50 mg/day',
			'health.hint.doctor' => 'e.g. Dr Smith +44 20 xxxx xxxx',
			'health.hint.insurance' => 'e.g. European health card',
			'health.save' => 'Save',
			'health.saving' => 'Saving…',
			'health.saved' => 'Information saved',
			'health.emergencyHint' => 'In an emergency, show this screen to the rescue team.',
			'health.entryTitle' => 'My health info',
			'health.entrySubtitle' => 'To show the rescue team (kept on the phone)',
			'health.a11y.form' => 'Health information form',
			'health.a11y.saveButton' => 'Save health information',
			'trailSelection.title' => 'Switch trail',
			'trailSelection.subtitle' => 'Pick the trail to explore. The whole app (map, stages, points of interest, packs, guides) follows your selection.',
			'trailSelection.current' => 'Active trail',
			'trailSelection.select' => 'Choose this trail',
			'trailSelection.selected' => 'Selected trail',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} stages - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Trail ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Currently active trail',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Activate trail ${nom}',
			'consent.onboardingTitle' => 'Your privacy, your choice',
			'consent.onboardingIntro' => 'Nothing is enabled by default. Choose, purpose by purpose, what you allow. You can change everything at any time in the settings.',
			'consent.settingsTitle' => 'Privacy and consent',
			'consent.settingsIntro' => 'Manage each permission here. You can withdraw a consent at any time, with no effect on the rest.',
			'consent.settingsEntry' => 'Privacy and consent',
			'consent.settingsEntryDesc' => 'Manage my permissions (location, sharing, health)',
			'consent.purposes.locationNavigation' => 'Personal navigation',
			'consent.purposes.locationNavigationDesc' => 'Use your location for the map and to track your stage. Stays on your device.',
			'consent.purposes.socialSharing' => 'Social sharing',
			'consent.purposes.socialSharingDesc' => 'Appear in leaderboards and the community feed, under a pseudonym.',
			'consent.purposes.publicReporting' => 'Public reporting',
			'consent.purposes.publicReportingDesc' => 'Post reports (water, hazard, conditions) visible to other hikers.',
			'consent.purposes.healthData' => 'Health data',
			'consent.purposes.healthDataDesc' => 'Read your heart rate (chest strap or health app) to enrich your effort tracking.',
			'consent.healthBadge' => 'Sensitive data',
			'consent.healthWarning' => 'Heart rate is health data (GDPR article 9). This consent is requested separately and is never bundled with the others. Your health data is not sent to our servers.',
			'consent.granted' => 'Allowed',
			'consent.denied' => 'Not allowed',
			'consent.grant' => 'Allow',
			'consent.revoke' => 'Withdraw',
			'consent.decidedOn' => ({required Object date}) => 'Chosen on ${date}',
			'consent.notDecided' => 'Awaiting your choice',
			'consent.acceptSelected' => 'Confirm my choices',
			'consent.declineAll' => 'Decline all',
			'consent.continueLabel' => 'Continue',
			'consent.privacyPolicyLink' => 'Read the privacy policy',
			'consent.reviewNeeded' => 'Our policy has changed: please review your choices.',
			'consent.a11y.purposeToggle' => ({required Object purpose, required Object state}) => '${purpose}, currently ${state}',
			'consent.a11y.healthSection' => 'Health data section, reinforced consent',
			'consent.a11y.policyButton' => 'Open the privacy policy',
			'moderation.reportTitle' => 'Report this content',
			'moderation.reportIntro' => 'Help us keep the community healthy. Tell us why this content seems unlawful. Your report will be reviewed by a moderator.',
			'moderation.reasonLabel' => 'Reason for reporting',
			'moderation.reasons.illegal' => 'Illegal content',
			'moderation.reasons.harassment' => 'Harassment or hate',
			'moderation.reasons.spam' => 'Spam or advertising',
			'moderation.reasons.dangerous' => 'Dangerous or misleading information',
			'moderation.reasons.other' => 'Other',
			'moderation.detailsLabel' => 'Add details (optional)',
			'moderation.detailsHint' => 'Add a comment to help the moderator.',
			'moderation.contactLabel' => 'Your email address',
			'moderation.contactHint' => 'To keep you informed about the handling (article 16).',
			'moderation.goodFaithLabel' => 'I declare in good faith that this information is accurate.',
			'moderation.submit' => 'Send report',
			'moderation.submitting' => 'Sending…',
			'moderation.sent' => 'Report sent. Thank you, a moderator will review it.',
			'moderation.errorRequired' => 'Please fill in the reason, your email and the good-faith declaration.',
			'moderation.errorGeneric' => 'The report could not be sent. Please try again.',
			'moderation.cancel' => 'Cancel',
			'moderation.reasonsTitle' => 'Why was this content restricted?',
			'moderation.reasonsIntro' => 'In accordance with article 17, here is the reason for the moderation decision regarding your content.',
			'moderation.decisionLabel' => 'Decision',
			'moderation.decisions.keep' => 'Content kept',
			'moderation.decisions.restrict' => 'Content restricted',
			'moderation.decisions.remove' => 'Content removed',
			'moderation.noStatement' => 'No restriction has been applied to your content.',
			'moderation.complaintAction' => 'Challenge this decision',
			'moderation.complaintTitle' => 'Challenge a decision',
			'moderation.complaintIntro' => 'You can challenge a moderation decision. Explain why you believe the decision is unjustified (article 20).',
			'moderation.complaintExposeLabel' => 'Your challenge',
			'moderation.complaintExposeHint' => 'Describe the reasons for your challenge.',
			'moderation.complaintSubmit' => 'Send challenge',
			'moderation.complaintSent' => 'Challenge recorded. It will be reviewed.',
			'moderation.complaintEmpty' => 'Please explain your challenge.',
			'moderation.a11y.reportForm' => 'Content reporting form',
			'moderation.a11y.reasonSelector' => 'Report reason selector',
			'moderation.a11y.goodFaithToggle' => ({required Object state}) => 'Good-faith declaration, ${state}',
			'moderation.a11y.submitReport' => 'Send report',
			'moderation.a11y.statementCard' => 'Statement of reasons for the moderation decision',
			'moderation.a11y.complaintForm' => 'Decision challenge form',
			_ => null,
		};
	}
}
