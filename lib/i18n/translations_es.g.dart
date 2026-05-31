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
class TranslationsEs extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsEs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.es,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		super.$meta.setFlatMapFunction($meta.getTranslation); // copy base translations to super.$meta
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <es>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key) ?? super.$meta.getTranslation(key);

	late final TranslationsEs _root = this; // ignore: unused_field

	@override 
	TranslationsEs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsEs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$map$es map = _Translations$map$es._(_root);
	@override late final _Translations$stage$es stage = _Translations$stage$es._(_root);
	@override late final _Translations$trail$es trail = _Translations$trail$es._(_root);
	@override late final _Translations$poi$es poi = _Translations$poi$es._(_root);
	@override late final _Translations$gps$es gps = _Translations$gps$es._(_root);
	@override late final _Translations$planning$es planning = _Translations$planning$es._(_root);
	@override late final _Translations$tracking$es tracking = _Translations$tracking$es._(_root);
	@override late final _Translations$checklist$es checklist = _Translations$checklist$es._(_root);
	@override late final _Translations$journal$es journal = _Translations$journal$es._(_root);
	@override late final _Translations$weather$es weather = _Translations$weather$es._(_root);
	@override late final _Translations$share$es share = _Translations$share$es._(_root);
	@override late final _Translations$diploma$es diploma = _Translations$diploma$es._(_root);
	@override late final _Translations$notifications$es notifications = _Translations$notifications$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$feedback$es feedback = _Translations$feedback$es._(_root);
	@override late final _Translations$auth$es auth = _Translations$auth$es._(_root);
}

// Path: map
class _Translations$map$es extends Translations$map$fr {
	_Translations$map$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mapa del sendero';
	@override String get loading => 'Cargando el recorrido...';
	@override String get noTrack => 'NingÃºn recorrido disponible';
	@override String get viewMap => 'Ver el mapa';
}

// Path: stage
class _Translations$stage$es extends Translations$stage$fr {
	_Translations$stage$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distancia';
	@override String get elevation => 'Desnivel';
	@override String get elevationGain => 'Desnivel positivo';
	@override String get elevationLoss => 'Desnivel negativo';
	@override String get duration => 'DuraciÃ³n estimada';
	@override String get description => 'DescripciÃ³n';
	@override String get coordinates => 'Coordenadas';
	@override String get pois => 'Puntos de interÃ©s';
	@override late final _Translations$stage$difficulty$es difficulty = _Translations$stage$difficulty$es._(_root);
	@override String get remaining => '{distance} km restantes';
	@override String get arrived => 'Has llegado!';
}

// Path: trail
class _Translations$trail$es extends Translations$trail$fr {
	_Translations$trail$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get stages => 'Etapas';
	@override String get totalDistance => 'Distancia total';
	@override String get totalElevation => 'Desnivel total';
}

// Path: poi
class _Translations$poi$es extends Translations$poi$fr {
	_Translations$poi$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get shelter => 'Refugio';
	@override String get water => 'Fuente de agua';
	@override String get viewpoint => 'Mirador';
	@override String get campsite => 'Vivac';
	@override String get restaurant => 'Restaurante';
	@override String get emergency => 'Emergencia';
	@override String get danger => 'Peligro';
	@override String get shop => 'Tienda';
	@override String get filter => 'Filtrar puntos de interÃ©s';
	@override String get altitude => 'Altitud';
	@override String get hours => 'Horarios';
}

// Path: gps
class _Translations$gps$es extends Translations$gps$fr {
	_Translations$gps$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get permission => 'Permiso GPS requerido';
	@override String get denied => 'Acceso a la ubicacion denegado';
	@override String get disabled => 'Servicio de ubicacion desactivado';
	@override String get offTrack => 'Fuera del sendero';
	@override String get centerOnMe => 'Centrar en mi posicion';
}

// Path: planning
class _Translations$planning$es extends Translations$planning$fr {
	_Translations$planning$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Planificación';
	@override String get duration => 'Duración';
	@override String get days => 'días';
	@override String get day => 'Día';
	@override String get restDay => 'Día de descanso';
	@override String get totalDistance => 'Distancia total';
	@override String get totalElevation => 'Desnivel total';
	@override String get estimatedTime => 'Duración estimada';
	@override String get stages => 'Etapas';
	@override String get plan => 'Planificar';
}

// Path: tracking
class _Translations$tracking$es extends Translations$tracking$fr {
	_Translations$tracking$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get start => 'Iniciar';
	@override String get pause => 'Pausa';
	@override String get resume => 'Reanudar';
	@override String get stop => 'Detener';
	@override String get distance => 'Distancia';
	@override String get elevation => 'Desnivel';
	@override String get speed => 'Velocidad';
	@override String get time => 'Tiempo';
	@override String get confirmStop => 'Detener el seguimiento?';
}

// Path: checklist
class _Translations$checklist$es extends Translations$checklist$fr {
	_Translations$checklist$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Lista de equipo';
	@override String get subtitle => 'Prepara tu mochila';
	@override String get progress => '{checked}/{total} preparados';
	@override String get complete => 'Lista completa!';
	@override String get reset => 'Reiniciar';
	@override String get resetConfirm => 'Reiniciar la lista?';
	@override String get resetDescription => 'Todos los elementos serán desmarcados.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Confirmar';
	@override late final _Translations$checklist$categories$es categories = _Translations$checklist$categories$es._(_root);
	@override late final _Translations$checklist$items$es items = _Translations$checklist$items$es._(_root);
	@override String get essential => 'Esencial';
}

// Path: journal
class _Translations$journal$es extends Translations$journal$fr {
	_Translations$journal$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diario de trekking';
	@override String get empty => 'Tu diario está vacío';
	@override String get emptySubtitle => 'Anota tus impresiones y recuerdos de trekking';
	@override String get addNote => 'Nueva nota';
	@override String get stage => 'Etapa';
	@override String get yourNote => 'Tu nota';
	@override String get placeholder => 'Describe tu día de senderismo...';
	@override String get save => 'Guardar';
	@override String get cancel => 'Cancelar';
	@override String get delete => 'Eliminar';
	@override String get photoLimit => 'Límite de 3 fotos por día alcanzado';
	@override String get photoTooBig => 'Foto demasiado grande (máx 500 KB)';
}

// Path: weather
class _Translations$weather$es extends Translations$weather$fr {
	_Translations$weather$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Meteorología';
	@override String get loading => 'Cargando meteorología...';
	@override String get offline => 'Sin conexión. Datos meteorológicos no disponibles.';
	@override String get error => 'No se pudo cargar la meteorología.';
	@override String get cached => 'Datos en caché';
	@override String get alerts => 'alertas meteorológicas';
	@override String get refresh => 'Actualizar';
	@override String get temperature => 'Temperatura';
	@override String get precipitation => 'Precipitación';
	@override String get wind => 'Viento';
	@override String get uv => 'Índice UV';
}

// Path: share
class _Translations$share$es extends Translations$share$fr {
	_Translations$share$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Compartir';
	@override String get generating => 'Generando...';
	@override String get share => 'Compartir';
	@override String get error => 'Error durante la generación';
}

// Path: diploma
class _Translations$diploma$es extends Translations$diploma$fr {
	_Translations$diploma$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Diploma de trekking';
	@override String get yourName => 'Tu nombre';
	@override String get namePlaceholder => 'Introduce tu nombre...';
	@override String get generatePdf => 'Generar PDF';
	@override String get certifies => 'Certifica que';
	@override String get completed => 'ha recorrido el';
}

// Path: notifications
class _Translations$notifications$es extends Translations$notifications$fr {
	_Translations$notifications$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get morningReminder => 'Recordatorio matutino';
	@override String get weatherAlerts => 'Alertas meteorológicas';
	@override String get countdown => 'Recordatorio D-2';
	@override String get countdownDesc => 'Notificación 2 días antes de la salida';
}

// Path: settings
class _Translations$settings$es extends Translations$settings$fr {
	_Translations$settings$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ajustes';
	@override String get language => 'Idioma';
	@override String get units => 'Unidades';
	@override String get distance => 'Distancia';
	@override String get temperature => 'Temperatura';
	@override String get theme => 'Tema';
	@override String get dark => 'Oscuro';
	@override String get light => 'Claro';
	@override String get system => 'Sistema';
	@override String get cache => 'Caché';
	@override String get cacheEnabled => 'Caché activada';
	@override String get cacheDesc => 'Datos disponibles sin conexión';
	@override String get cacheSize => 'Tamaño de caché';
	@override String get notifications => 'Notificaciones';
}

// Path: feedback
class _Translations$feedback$es extends Translations$feedback$fr {
	_Translations$feedback$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Comentarios';
	@override String get type => 'Tipo de comentario';
	@override String get bug => 'Error / Problema';
	@override String get suggestion => 'Sugerencia';
	@override String get question => 'Pregunta';
	@override String get other => 'Otro';
	@override String get message => 'Tu mensaje';
	@override String get messagePlaceholder => 'Describe tu comentario...';
	@override String get satisfaction => 'Satisfacción';
	@override String get send => 'Enviar';
	@override String get sending => 'Enviando...';
	@override String get thanks => '¡Gracias por tu comentario!';
	@override String get pending => 'pendiente';
}

// Path: auth
class _Translations$auth$es extends Translations$auth$fr {
	_Translations$auth$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get profile => 'Perfil';
	@override String get anonymous => 'Senderista anónimo';
	@override String get connectedVia => 'Conectado vía';
	@override String get signInGoogle => 'Iniciar sesión con Google';
	@override String get signInGoogleDesc => 'Para guardar tu progreso';
	@override String get signOut => 'Cerrar sesión';
	@override String get signOutDesc => 'Volver al modo anónimo';
	@override String get signOutConfirm => '¿Cerrar sesión?';
	@override String get signOutMessage => 'Volverás al modo anónimo. Tus datos locales se conservan.';
	@override String get deleteAccount => 'Eliminar mi cuenta';
	@override String get deleteAccountDesc => 'Todos tus datos serán borrados';
	@override String get deleteConfirm => '¿Eliminar tu cuenta?';
	@override String get deleteMessage => 'Esta acción es irreversible. Todos tus datos, notas y progreso serán eliminados.';
	@override String get cancel => 'Cancelar';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$es extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get easy => 'FÃ¡cil';
	@override String get moderate => 'Moderado';
	@override String get hard => 'DifÃ­cil';
	@override String get expert => 'Experto';
}

// Path: checklist.categories
class _Translations$checklist$categories$es extends Translations$checklist$categories$fr {
	_Translations$checklist$categories$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get equipment => 'Equipo';
	@override String get clothing => 'Ropa';
	@override String get food => 'Alimentación';
	@override String get safety => 'Seguridad';
	@override String get documents => 'Documentos';
	@override String get hygiene => 'Higiene';
}

// Path: checklist.items
class _Translations$checklist$items$es extends Translations$checklist$items$fr {
	_Translations$checklist$items$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Mochila';
	@override String get sleepingBag => 'Saco de dormir';
	@override String get sleepingPad => 'Esterilla';
	@override String get hikingPoles => 'Bastones de senderismo';
	@override String get headlamp => 'Linterna frontal';
	@override String get waterBottle => 'Botella de agua';
	@override String get hikingBoots => 'Botas de senderismo';
	@override String get rainJacket => 'Chaqueta impermeable';
	@override String get warmLayer => 'Capa de abrigo';
	@override String get hikingSocks => 'Calcetines de senderismo';
	@override String get hat => 'Sombrero';
	@override String get gloves => 'Guantes';
	@override String get trailSnacks => 'Snacks de sendero';
	@override String get energyBars => 'Barritas energéticas';
	@override String get waterPurification => 'Purificación de agua';
	@override String get firstAidKit => 'Botiquín';
	@override String get whistle => 'Silbato';
	@override String get emergencyBlanket => 'Manta de emergencia';
	@override String get sunscreen => 'Protector solar';
	@override String get idCard => 'Documento de identidad';
	@override String get insurance => 'Seguro';
	@override String get trailMap => 'Mapa del sendero';
	@override String get toiletPaper => 'Papel higiénico';
	@override String get handSanitizer => 'Gel desinfectante';
	@override String get towel => 'Toalla';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'map.title' => 'Mapa del sendero',
			'map.loading' => 'Cargando el recorrido...',
			'map.noTrack' => 'NingÃºn recorrido disponible',
			'map.viewMap' => 'Ver el mapa',
			'stage.distance' => 'Distancia',
			'stage.elevation' => 'Desnivel',
			'stage.elevationGain' => 'Desnivel positivo',
			'stage.elevationLoss' => 'Desnivel negativo',
			'stage.duration' => 'DuraciÃ³n estimada',
			'stage.description' => 'DescripciÃ³n',
			'stage.coordinates' => 'Coordenadas',
			'stage.pois' => 'Puntos de interÃ©s',
			'stage.difficulty.easy' => 'FÃ¡cil',
			'stage.difficulty.moderate' => 'Moderado',
			'stage.difficulty.hard' => 'DifÃ­cil',
			'stage.difficulty.expert' => 'Experto',
			'stage.remaining' => '{distance} km restantes',
			'stage.arrived' => 'Has llegado!',
			'trail.stages' => 'Etapas',
			'trail.totalDistance' => 'Distancia total',
			'trail.totalElevation' => 'Desnivel total',
			'poi.shelter' => 'Refugio',
			'poi.water' => 'Fuente de agua',
			'poi.viewpoint' => 'Mirador',
			'poi.campsite' => 'Vivac',
			'poi.restaurant' => 'Restaurante',
			'poi.emergency' => 'Emergencia',
			'poi.danger' => 'Peligro',
			'poi.shop' => 'Tienda',
			'poi.filter' => 'Filtrar puntos de interÃ©s',
			'poi.altitude' => 'Altitud',
			'poi.hours' => 'Horarios',
			'gps.permission' => 'Permiso GPS requerido',
			'gps.denied' => 'Acceso a la ubicacion denegado',
			'gps.disabled' => 'Servicio de ubicacion desactivado',
			'gps.offTrack' => 'Fuera del sendero',
			'gps.centerOnMe' => 'Centrar en mi posicion',
			'planning.title' => 'Planificación',
			'planning.duration' => 'Duración',
			'planning.days' => 'días',
			'planning.day' => 'Día',
			'planning.restDay' => 'Día de descanso',
			'planning.totalDistance' => 'Distancia total',
			'planning.totalElevation' => 'Desnivel total',
			'planning.estimatedTime' => 'Duración estimada',
			'planning.stages' => 'Etapas',
			'planning.plan' => 'Planificar',
			'tracking.start' => 'Iniciar',
			'tracking.pause' => 'Pausa',
			'tracking.resume' => 'Reanudar',
			'tracking.stop' => 'Detener',
			'tracking.distance' => 'Distancia',
			'tracking.elevation' => 'Desnivel',
			'tracking.speed' => 'Velocidad',
			'tracking.time' => 'Tiempo',
			'tracking.confirmStop' => 'Detener el seguimiento?',
			'checklist.title' => 'Lista de equipo',
			'checklist.subtitle' => 'Prepara tu mochila',
			'checklist.progress' => '{checked}/{total} preparados',
			'checklist.complete' => 'Lista completa!',
			'checklist.reset' => 'Reiniciar',
			'checklist.resetConfirm' => 'Reiniciar la lista?',
			'checklist.resetDescription' => 'Todos los elementos serán desmarcados.',
			'checklist.cancel' => 'Cancelar',
			'checklist.confirm' => 'Confirmar',
			'checklist.categories.equipment' => 'Equipo',
			'checklist.categories.clothing' => 'Ropa',
			'checklist.categories.food' => 'Alimentación',
			'checklist.categories.safety' => 'Seguridad',
			'checklist.categories.documents' => 'Documentos',
			'checklist.categories.hygiene' => 'Higiene',
			'checklist.items.backpack' => 'Mochila',
			'checklist.items.sleepingBag' => 'Saco de dormir',
			'checklist.items.sleepingPad' => 'Esterilla',
			'checklist.items.hikingPoles' => 'Bastones de senderismo',
			'checklist.items.headlamp' => 'Linterna frontal',
			'checklist.items.waterBottle' => 'Botella de agua',
			'checklist.items.hikingBoots' => 'Botas de senderismo',
			'checklist.items.rainJacket' => 'Chaqueta impermeable',
			'checklist.items.warmLayer' => 'Capa de abrigo',
			'checklist.items.hikingSocks' => 'Calcetines de senderismo',
			'checklist.items.hat' => 'Sombrero',
			'checklist.items.gloves' => 'Guantes',
			'checklist.items.trailSnacks' => 'Snacks de sendero',
			'checklist.items.energyBars' => 'Barritas energéticas',
			'checklist.items.waterPurification' => 'Purificación de agua',
			'checklist.items.firstAidKit' => 'Botiquín',
			'checklist.items.whistle' => 'Silbato',
			'checklist.items.emergencyBlanket' => 'Manta de emergencia',
			'checklist.items.sunscreen' => 'Protector solar',
			'checklist.items.idCard' => 'Documento de identidad',
			'checklist.items.insurance' => 'Seguro',
			'checklist.items.trailMap' => 'Mapa del sendero',
			'checklist.items.toiletPaper' => 'Papel higiénico',
			'checklist.items.handSanitizer' => 'Gel desinfectante',
			'checklist.items.towel' => 'Toalla',
			'checklist.essential' => 'Esencial',
			'journal.title' => 'Diario de trekking',
			'journal.empty' => 'Tu diario está vacío',
			'journal.emptySubtitle' => 'Anota tus impresiones y recuerdos de trekking',
			'journal.addNote' => 'Nueva nota',
			'journal.stage' => 'Etapa',
			'journal.yourNote' => 'Tu nota',
			'journal.placeholder' => 'Describe tu día de senderismo...',
			'journal.save' => 'Guardar',
			'journal.cancel' => 'Cancelar',
			'journal.delete' => 'Eliminar',
			'journal.photoLimit' => 'Límite de 3 fotos por día alcanzado',
			'journal.photoTooBig' => 'Foto demasiado grande (máx 500 KB)',
			'weather.title' => 'Meteorología',
			'weather.loading' => 'Cargando meteorología...',
			'weather.offline' => 'Sin conexión. Datos meteorológicos no disponibles.',
			'weather.error' => 'No se pudo cargar la meteorología.',
			'weather.cached' => 'Datos en caché',
			'weather.alerts' => 'alertas meteorológicas',
			'weather.refresh' => 'Actualizar',
			'weather.temperature' => 'Temperatura',
			'weather.precipitation' => 'Precipitación',
			'weather.wind' => 'Viento',
			'weather.uv' => 'Índice UV',
			'share.title' => 'Compartir',
			'share.generating' => 'Generando...',
			'share.share' => 'Compartir',
			'share.error' => 'Error durante la generación',
			'diploma.title' => 'Diploma de trekking',
			'diploma.yourName' => 'Tu nombre',
			'diploma.namePlaceholder' => 'Introduce tu nombre...',
			'diploma.generatePdf' => 'Generar PDF',
			'diploma.certifies' => 'Certifica que',
			'diploma.completed' => 'ha recorrido el',
			'notifications.morningReminder' => 'Recordatorio matutino',
			'notifications.weatherAlerts' => 'Alertas meteorológicas',
			'notifications.countdown' => 'Recordatorio D-2',
			'notifications.countdownDesc' => 'Notificación 2 días antes de la salida',
			'settings.title' => 'Ajustes',
			'settings.language' => 'Idioma',
			'settings.units' => 'Unidades',
			'settings.distance' => 'Distancia',
			'settings.temperature' => 'Temperatura',
			'settings.theme' => 'Tema',
			'settings.dark' => 'Oscuro',
			'settings.light' => 'Claro',
			'settings.system' => 'Sistema',
			'settings.cache' => 'Caché',
			'settings.cacheEnabled' => 'Caché activada',
			'settings.cacheDesc' => 'Datos disponibles sin conexión',
			'settings.cacheSize' => 'Tamaño de caché',
			'settings.notifications' => 'Notificaciones',
			'feedback.title' => 'Comentarios',
			'feedback.type' => 'Tipo de comentario',
			'feedback.bug' => 'Error / Problema',
			'feedback.suggestion' => 'Sugerencia',
			'feedback.question' => 'Pregunta',
			'feedback.other' => 'Otro',
			'feedback.message' => 'Tu mensaje',
			'feedback.messagePlaceholder' => 'Describe tu comentario...',
			'feedback.satisfaction' => 'Satisfacción',
			'feedback.send' => 'Enviar',
			'feedback.sending' => 'Enviando...',
			'feedback.thanks' => '¡Gracias por tu comentario!',
			'feedback.pending' => 'pendiente',
			'auth.profile' => 'Perfil',
			'auth.anonymous' => 'Senderista anónimo',
			'auth.connectedVia' => 'Conectado vía',
			'auth.signInGoogle' => 'Iniciar sesión con Google',
			'auth.signInGoogleDesc' => 'Para guardar tu progreso',
			'auth.signOut' => 'Cerrar sesión',
			'auth.signOutDesc' => 'Volver al modo anónimo',
			'auth.signOutConfirm' => '¿Cerrar sesión?',
			'auth.signOutMessage' => 'Volverás al modo anónimo. Tus datos locales se conservan.',
			'auth.deleteAccount' => 'Eliminar mi cuenta',
			'auth.deleteAccountDesc' => 'Todos tus datos serán borrados',
			'auth.deleteConfirm' => '¿Eliminar tu cuenta?',
			'auth.deleteMessage' => 'Esta acción es irreversible. Todos tus datos, notas y progreso serán eliminados.',
			'auth.cancel' => 'Cancelar',
			_ => null,
		};
	}
}
