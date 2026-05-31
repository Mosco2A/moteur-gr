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
	@override late final _Translations$map$en map = _Translations$map$en._(_root);
	@override late final _Translations$stage$en stage = _Translations$stage$en._(_root);
	@override late final _Translations$trail$en trail = _Translations$trail$en._(_root);
	@override late final _Translations$poi$en poi = _Translations$poi$en._(_root);
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
			'share.title' => 'Share',
			'share.generating' => 'Generating...',
			'share.share' => 'Share',
			'share.error' => 'Error during generation',
			'diploma.title' => 'Trek diploma',
			'diploma.yourName' => 'Your name',
			'diploma.namePlaceholder' => 'Enter your name...',
			'diploma.generatePdf' => 'Generate PDF',
			'diploma.certifies' => 'Certifies that',
			'diploma.completed' => 'completed the',
			'notifications.morningReminder' => 'Morning reminder',
			'notifications.weatherAlerts' => 'Weather alerts',
			'notifications.countdown' => 'D-2 reminder',
			'notifications.countdownDesc' => 'Notification 2 days before departure',
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
			'feedback.title' => 'Feedback',
			'feedback.type' => 'Feedback type',
			'feedback.bug' => 'Bug / Problem',
			'feedback.suggestion' => 'Suggestion',
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
			_ => null,
		};
	}
}
