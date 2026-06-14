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
	@override late final _Translations$map$en map = _Translations$map$en._(_root);
	@override late final _Translations$stage$en stage = _Translations$stage$en._(_root);
	@override late final _Translations$trail$en trail = _Translations$trail$en._(_root);
	@override late final _Translations$poi$en poi = _Translations$poi$en._(_root);
	@override late final _Translations$accommodation$en accommodation = _Translations$accommodation$en._(_root);
	@override late final _Translations$gps$en gps = _Translations$gps$en._(_root);
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
	@override String get anonymous => 'Anonymous hiker';
	@override String get connectedVia => 'Connected via';
	@override String get signInGoogle => 'Sign in with Google';
	@override String get signInGoogleDesc => 'To save your progress';
	@override String get signOut => 'Sign out';
	@override String get signOutDesc => 'Return to anonymous mode';
	@override String get signOutConfirm => 'Sign out?';
	@override String get signOutMessage => 'You will return to anonymous mode. Your local data is preserved.';
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
			'noData.title' => 'No trail downloaded',
			'noData.subtitle' => 'Download a trail to get started',
			'noData.offlineHint' => 'Data will be available offline for your hike.',
			'noData.browseCta' => 'Browse trails',
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
			_ => null,
		};
	}
}
