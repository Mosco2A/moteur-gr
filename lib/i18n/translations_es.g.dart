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
	@override late final _Translations$a11y$es a11y = _Translations$a11y$es._(_root);
	@override late final _Translations$nav$es nav = _Translations$nav$es._(_root);
	@override late final _Translations$map$es map = _Translations$map$es._(_root);
	@override late final _Translations$stage$es stage = _Translations$stage$es._(_root);
	@override late final _Translations$trail$es trail = _Translations$trail$es._(_root);
	@override late final _Translations$poi$es poi = _Translations$poi$es._(_root);
	@override late final _Translations$accommodation$es accommodation = _Translations$accommodation$es._(_root);
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
	@override late final _Translations$feasibility$es feasibility = _Translations$feasibility$es._(_root);
	@override late final _Translations$tips$es tips = _Translations$tips$es._(_root);
	@override late final _Translations$goodies$es goodies = _Translations$goodies$es._(_root);
	@override late final _Translations$noData$es noData = _Translations$noData$es._(_root);
	@override late final _Translations$updates$es updates = _Translations$updates$es._(_root);
	@override late final _Translations$follow$es follow = _Translations$follow$es._(_root);
	@override late final _Translations$cloud$es cloud = _Translations$cloud$es._(_root);
	@override late final _Translations$onboarding$es onboarding = _Translations$onboarding$es._(_root);
	@override late final _Translations$monetization$es monetization = _Translations$monetization$es._(_root);
	@override late final _Translations$signalement$es signalement = _Translations$signalement$es._(_root);
	@override late final _Translations$hebergement$es hebergement = _Translations$hebergement$es._(_root);
	@override late final _Translations$training$es training = _Translations$training$es._(_root);
	@override late final _Translations$eta$es eta = _Translations$eta$es._(_root);
	@override late final _Translations$leaderboard$es leaderboard = _Translations$leaderboard$es._(_root);
	@override late final _Translations$social$es social = _Translations$social$es._(_root);
	@override late final _Translations$gamification$es gamification = _Translations$gamification$es._(_root);
	@override late final _Translations$shareVisibility$es shareVisibility = _Translations$shareVisibility$es._(_root);
	@override late final _Translations$waypoints$es waypoints = _Translations$waypoints$es._(_root);
	@override late final _Translations$packs$es packs = _Translations$packs$es._(_root);
	@override late final _Translations$guides$es guides = _Translations$guides$es._(_root);
	@override late final _Translations$trailSelection$es trailSelection = _Translations$trailSelection$es._(_root);
}

// Path: a11y
class _Translations$a11y$es extends Translations$a11y$fr {
	_Translations$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get back => 'Volver';
	@override String get zoomIn => 'Acercar';
	@override String get zoomOut => 'Alejar';
	@override String get centerOnMe => 'Centrar en mi posicion';
	@override String get mapRegion => 'Mapa del sendero';
	@override String get userPosition => 'Tu posicion';
	@override String stageMarker({required Object number}) => 'Etapa ${number}';
	@override String poiMarker({required Object name}) => 'Punto de interes: ${name}';
	@override String markerCluster({required Object count}) => '${count} puntos agrupados';
	@override String trailCard({required Object name}) => 'Sendero ${name}';
	@override String get startTracking => 'Iniciar seguimiento';
	@override String get pauseTracking => 'Pausar seguimiento';
	@override String get resumeTracking => 'Reanudar seguimiento';
	@override String get stopTracking => 'Detener seguimiento';
}

// Path: nav
class _Translations$nav$es extends Translations$nav$fr {
	_Translations$nav$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get map => 'Mapa';
	@override String get stages => 'Etapas';
	@override String get planning => 'Planificación';
	@override String get journal => 'Diario';
	@override String get more => 'Más';
	@override String get checklist => 'Lista de equipo';
	@override String get feasibility => 'Viabilidad';
	@override String get tips => 'Consejos trek';
	@override String get emergency => 'Contactos de emergencia';
	@override String get catalog => 'Catálogo de senderos';
	@override String get profile => 'Perfil';
	@override String get settings => 'Ajustes';
	@override String get trailSelection => 'Cambiar de sendero';
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

// Path: accommodation
class _Translations$accommodation$es extends Translations$accommodation$fr {
	_Translations$accommodation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$accommodation$types$es types = _Translations$accommodation$types$es._(_root);
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
	@override String get fireRisk => 'Riesgo de incendio';
	@override String get fireRiskDesc => 'Alto riesgo de incendio. Consulte las instrucciones de seguridad.';
	@override String get fireSafetyTips => 'Instrucciones contra incendios';
	@override String get alertCount => 'alerta';
	@override String get alertCountPlural => 'alertas';
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
	@override String get errorShare => 'Error al compartir';
	@override String get preview => 'Vista previa';
	@override String get chooseTemplate => 'Elegir plantilla';
	@override String get templateStats => 'Estadísticas';
	@override String get templateJourney => 'Recorrido';
	@override String get templateStage => 'Etapa';
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
	@override String get pdfTitle => 'DIPLOMA';
	@override String get pdfSubtitle => 'Certificado de logro';
	@override String get pdfStages => '{count} etapas';
	@override String get pdfDistance => '{km} km recorridos';
	@override String get pdfElevation => '{meters} m de desnivel positivo';
	@override String get pdfDuration => 'en {days} días';
	@override String get pdfFrom => 'Del';
	@override String get pdfTo => 'al';
	@override String get pdfIssuedOn => 'Emitido el {date}';
	@override String get recapTitle => 'Tu aventura';
	@override String get recapJournalPhotos => 'Fotos del diario';
	@override String get recapNoPhotos => 'Sin fotos en el diario';
	@override String get recapStats => 'Estadisticas';
	@override String get recapStages => '{count} etapas completadas';
	@override String get recapDistance => '{km} km recorridos';
	@override String get recapElevation => '{meters} m de desnivel';
	@override String get recapDuration => '{days} dias de trekking';
	@override String get recapMapTrace => 'Trazado del recorrido';
	@override String get recapNoMap => 'Trazado no disponible';
	@override String get recapJournalEntries => '{count} notas del diario';
	@override String get downloadPdf => 'Descargar diploma PDF';
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
	@override String get schedulerCountdownTitle => 'Tu trek se acerca!';
	@override String get schedulerCountdownBody => 'Salida en 2 dias. Revisa tu checklist y el tiempo.';
	@override String get schedulerDailyTitle => 'Buen dia de trek!';
	@override String get schedulerDailyBody => 'Consulta el tiempo y prepara la etapa del dia.';
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
	@override String get morningReminder => 'Recordatorio matutino';
	@override String get weatherAlerts => 'Alertas meteorológicas';
	@override String get weatherAlertsDesc => 'Notificado si hay condiciones peligrosas';
	@override String get countdownReminder => 'Recordatorio D-2';
	@override String get countdownDesc => 'Notificación 2 días antes de la salida';
	@override String get version => 'Versión';
	@override String get versionLabel => 'Versión de la aplicación';
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
	@override String get compliment => 'Cumplido';
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
	@override String get pseudonym => 'Seudónimo';
	@override String get pseudonymHint => 'Tu nombre de senderista';
	@override String get save => 'Guardar';
	@override String get changeAvatar => 'Cambiar avatar';
	@override String get chooseAvatar => 'Elegir un avatar';
	@override String get errorLoading => 'Error de carga';
}

// Path: feasibility
class _Translations$feasibility$es extends Translations$feasibility$fr {
	_Translations$feasibility$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Feasibility';
	@override String get subtitle => 'Assess your preparation';
	@override String get previous => 'Previous';
	@override String get restart => 'Start over';
	@override String get resultTitle => 'Your result';
	@override String get weakPointsTitle => 'Areas to improve';
	@override String get strongPointsTitle => 'Strong points';
	@override String get progress => '{current}/{total}';
	@override late final _Translations$feasibility$levels$es levels = _Translations$feasibility$levels$es._(_root);
	@override late final _Translations$feasibility$categories$es categories = _Translations$feasibility$categories$es._(_root);
	@override late final _Translations$feasibility$questions$es questions = _Translations$feasibility$questions$es._(_root);
	@override late final _Translations$feasibility$answers$es answers = _Translations$feasibility$answers$es._(_root);
	@override String get seeRecommendations => 'Ver recomendaciones';
	@override String get yourProfile => 'Su perfil';
	@override String get tipsTitle => 'Nuestros consejos';
	@override late final _Translations$feasibility$recommendations$es recommendations = _Translations$feasibility$recommendations$es._(_root);
}

// Path: tips
class _Translations$tips$es extends Translations$tips$fr {
	_Translations$tips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get carouselTitle => 'Consejos trek';
	@override String get allCategories => 'Todas';
	@override String get swipeHint => 'Desliza para ver mas';
	@override String get detailTitle => 'Detalle del consejo';
	@override String get readMore => 'Leer mas';
	@override String get noTips => 'No hay consejos disponibles';
	@override String get categoryPreparation => 'Preparacion';
	@override String get categoryEquipment => 'Equipamiento';
	@override String get categoryNutrition => 'Nutricion';
	@override String get categorySafety => 'Seguridad';
	@override String get categoryNature => 'Naturaleza';
	@override String get categoryRecovery => 'Recuperacion';
	@override String get categoryGeneral => 'General';
	@override String get priorityHigh => 'Prioridad alta';
	@override String get scope => 'Sendero';
	@override String get season => 'Temporada';
	@override String get altitude => 'Altitud min.';
}

// Path: goodies
class _Translations$goodies$es extends Translations$goodies$fr {
	_Translations$goodies$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tienda de Goodies';
	@override String get comingSoon => 'Este modulo llegara pronto. Mantente atento!';
}

// Path: noData
class _Translations$noData$es extends Translations$noData$fr {
	_Translations$noData$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Ningún sendero descargado';
	@override String get subtitle => 'Descarga un sendero para empezar';
	@override String get offlineHint => 'Los datos estarán disponibles sin conexión para tu caminata.';
	@override String get browseCta => 'Explorar senderos';
}

// Path: updates
class _Translations$updates$es extends Translations$updates$fr {
	_Translations$updates$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get readyTitle => 'Actualización lista';
	@override String get readyBodyOne => 'Un sendero ha sido actualizado.';
	@override String readyBodyMany({required Object count}) => '${count} senderos han sido actualizados.';
}

// Path: follow
class _Translations$follow$es extends Translations$follow$fr {
	_Translations$follow$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Seguimiento en directo';
	@override String get connecting => 'Conectando…';
	@override String get live => 'En directo';
	@override String get offline => 'Sin conexión';
	@override String get invalidLink => 'Enlace no válido';
	@override String get invalidLinkHint => 'Este enlace de seguimiento no existe o ha caducado.';
}

// Path: cloud
class _Translations$cloud$es extends Translations$cloud$fr {
	_Translations$cloud$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get localModeTitle => 'Modo local';
	@override String get localModeBody => 'Esta instalación no está conectada a un servicio en la nube: el seguimiento en directo, la copia de seguridad en línea y la cuenta están desactivados. Sus datos permanecen en el dispositivo.';
	@override String get statusSection => 'Nube';
	@override String get statusActive => 'Servicios en línea activos';
	@override String get statusActiveDesc => 'Copia de seguridad y seguimiento en directo disponibles.';
	@override String get statusLocal => 'Modo local (sin nube)';
	@override String get statusLocalDesc => 'No se envía ningún dato en línea. Falta la configuración de la nube.';
}

// Path: onboarding
class _Translations$onboarding$es extends Translations$onboarding$fr {
	_Translations$onboarding$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get skip => 'Saltar';
	@override String get next => 'Siguiente';
	@override String get getStarted => 'Empezar';
	@override String welcomeTitle({required Object appName}) => 'Bienvenido a ${appName}';
	@override String get welcomeSubtitle => 'Tu compañero de senderismo sin conexión: mapa, navegación GPS, planificación y diario de trek.';
	@override String get languageTitle => 'Elige tu idioma';
	@override String get languageSubtitle => 'Podrás cambiarlo en cualquier momento en los ajustes.';
	@override String get downloadTitle => 'Descarga tu primer sendero';
	@override String get downloadSubtitle => 'Explora el catálogo y descarga un sendero para usarlo completamente sin conexión.';
	@override String get browseCatalog => 'Explorar el catálogo';
}

// Path: monetization
class _Translations$monetization$es extends Translations$monetization$fr {
	_Translations$monetization$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get demoBanner => 'Modo demo — toca para desbloquear';
	@override String get paywallTitle => 'Desbloquea este trek';
	@override String get paywallBody => 'El modo gratuito permite preparar tu trek con publicidad. El premium lo desbloquea todo, sin anuncios.';
	@override String get featureMap => 'Mapa sin conexión + GPS + seguimiento en directo';
	@override String get featureJournal => 'Diario de ruta completo';
	@override String get featureDiploma => 'Diploma de fin de trek';
	@override String get featureFollowers => '2 seguidores gratuitos';
	@override String get featureNoAds => 'Cero publicidad';
	@override String get buyCta => 'Desbloquear este trek';
	@override String buyCtaWithPrice({required Object price}) => 'Desbloquear este trek — ${price} €';
}

// Path: signalement
class _Translations$signalement$es extends Translations$signalement$fr {
	_Translations$signalement$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Notificar';
	@override String get chooseType => '¿Qué quieres notificar?';
	@override late final _Translations$signalement$types$es types = _Translations$signalement$types$es._(_root);
	@override String get latencyBanner => 'Guardado. Visible para otros senderistas tras la sincronización de red.';
	@override String get confirm => 'Confirmar notificación';
	@override String get noLocation => 'Posición GPS no disponible ahora. Inténtalo de nuevo a cielo abierto.';
	@override String get savedTitle => 'Notificación guardada';
	@override String get savedPendingSync => 'Se compartirá en cuanto vuelva la red.';
	@override String pendingCount({required Object n}) => '${n} en espera de sincronización';
	@override String get close => 'Cerrar';
}

// Path: hebergement
class _Translations$hebergement$es extends Translations$hebergement$fr {
	_Translations$hebergement$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alojamientos cercanos';
	@override String get facilitatorNote => 'StepWays te dirige a los alojamientos. La reserva se hace en su sitio: ningún pago en la aplicación.';
	@override String detourAR({required Object km}) => 'Desvío ida y vuelta: ${km} km';
	@override String get openSite => 'Ver el sitio';
	@override String get cannotOpen => 'No se pudo abrir este enlace en este dispositivo.';
	@override String get empty => 'No hay alojamientos cerca por ahora.';
	@override late final _Translations$hebergement$types$es types = _Translations$hebergement$types$es._(_root);
}

// Path: training
class _Translations$training$es extends Translations$training$fr {
	_Translations$training$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparación física';
	@override String get localNotice => 'Tu plan se calcula y se guarda en tu teléfono. Los recordatorios son notificaciones locales, sin seguimiento.';
	@override String get reminderTitle => 'Sesión de entrenamiento hoy';
	@override String get scheduleReminders => 'Programar recordatorios';
	@override String remindersScheduled({required Object n}) => '${n} recordatorio(s) programado(s)';
	@override String week({required Object n}) => 'Semana ${n}';
	@override String minutes({required Object n}) => '${n} min';
	@override String progress({required Object done, required Object total}) => '${done}/${total} sesiones hechas';
	@override late final _Translations$training$types$es types = _Translations$training$types$es._(_root);
	@override late final _Translations$training$intensity$es intensity = _Translations$training$intensity$es._(_root);
}

// Path: eta
class _Translations$eta$es extends Translations$eta$fr {
	_Translations$eta$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tiempo estimado';
	@override String get toNextWaypoint => 'Próximo punto';
	@override String get toStageEnd => 'Fin de etapa';
	@override String get confidenceHigh => 'Estimación fiable';
	@override String get confidenceLow => 'Aproximado (GPS débil)';
	@override String durationHm({required Object h, required Object m}) => '${h} h ${m} min';
	@override String durationM({required Object m}) => '${m} min';
}

// Path: leaderboard
class _Translations$leaderboard$es extends Translations$leaderboard$fr {
	_Translations$leaderboard$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Rey de la etapa';
	@override String get unavailable => 'Clasificación no disponible por ahora.';
	@override String get empty => 'Aún no hay clasificación para este segmento. ¡Sé el primero en recorrerlo!';
	@override String get pseudonymNotice => 'Clasificación por grupo, con seudónimos. No se muestra ningún dato personal directo.';
	@override String trancheLabel({required Object tranche}) => 'Grupo: ${tranche}';
	@override String get notEnoughParticipants => 'No hay suficientes participantes para publicar esta clasificación.';
	@override String entrySemantics({required Object rank, required Object pseudonym, required Object time}) => 'Posición ${rank}, ${pseudonym}, tiempo ${time}';
}

// Path: social
class _Translations$social$es extends Translations$social$fr {
	_Translations$social$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get feedTitle => 'Registro de actividad';
	@override String get empty => 'Ninguna actividad por ahora.';
	@override String get kudos => 'Animar';
	@override String kudosCount({required Object n}) => '${n} ánimos';
	@override String get report => 'Denunciar';
	@override String get reportTitle => 'Denunciar esta publicación';
	@override String get reportReasonLabel => 'Motivo de la denuncia';
	@override String get reasonSpam => 'Spam o publicidad';
	@override String get reasonAbuse => 'Contenido abusivo o de odio';
	@override String get reasonOther => 'Otro';
	@override String get reportSend => 'Enviar denuncia';
	@override String get reportSent => 'Denuncia enviada. Nuestro equipo la revisará.';
	@override String get syncPending => 'Esperando sincronización';
	@override String get synced => 'Sincronizado';
	@override String get activitySegment => 'completó un segmento';
	@override String get activityBadge => 'obtuvo una insignia';
	@override String get activityDefi => 'avanzó en un reto';
}

// Path: gamification
class _Translations$gamification$es extends Translations$gamification$fr {
	_Translations$gamification$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get galleryTitle => 'Mis insignias';
	@override String get obtained => 'Obtenida';
	@override String get locked => 'Bloqueada';
	@override String get tierDebutant => 'Principiante';
	@override String get tierExpert => 'Experto';
	@override late final _Translations$gamification$badge$es badge = _Translations$gamification$badge$es._(_root);
	@override late final _Translations$gamification$defi$es defi = _Translations$gamification$defi$es._(_root);
}

// Path: shareVisibility
class _Translations$shareVisibility$es extends Translations$shareVisibility$fr {
	_Translations$shareVisibility$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Compartir y visibilidad';
	@override String get intro => 'Por defecto, no se comparte nada. Activa abajo, finalidad por finalidad, lo que quieras hacer visible.';
	@override String get consentLink => 'Gestionar mi consentimiento (privacidad)';
	@override String get stageResults => 'Compartir mis resultados de etapa';
	@override String get stageResultsDesc => 'Una tarjeta con seudónimo (sin datos personales directos).';
	@override String get leaderboard => 'Aparecer en las clasificaciones';
	@override String get leaderboardDesc => 'Clasificación por grupo, con un seudónimo.';
	@override String get activityFeed => 'Publicar en el registro de actividad';
	@override String get activityFeedDesc => 'Tus actividades aparecen en el registro, con un seudónimo.';
	@override String get shareTitle => 'Compartir esta etapa';
	@override String get shareButton => 'Compartir';
	@override String get privateNotice => 'Compartir está desactivado. Actívalo en Compartir y visibilidad.';
	@override String get shared => 'Tarjeta lista para compartir.';
}

// Path: waypoints
class _Translations$waypoints$es extends Translations$waypoints$fr {
	_Translations$waypoints$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$waypoints$types$es types = _Translations$waypoints$types$es._(_root);
	@override late final _Translations$waypoints$filters$es filters = _Translations$waypoints$filters$es._(_root);
	@override late final _Translations$waypoints$detail$es detail = _Translations$waypoints$detail$es._(_root);
	@override late final _Translations$waypoints$freshness$es freshness = _Translations$waypoints$freshness$es._(_root);
	@override late final _Translations$waypoints$contribution$es contribution = _Translations$waypoints$contribution$es._(_root);
}

// Path: packs
class _Translations$packs$es extends Translations$packs$fr {
	_Translations$packs$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Packs de sendero';
	@override String get subtitle => 'Descarga un pack para caminar 100% sin conexión.';
	@override String get alaCarteNote => 'A la carte: compra solo el pack que necesitas, sin suscripción.';
	@override String size({required Object mo}) => '${mo} MB';
	@override late final _Translations$packs$states$es states = _Translations$packs$states$es._(_root);
	@override late final _Translations$packs$actions$es actions = _Translations$packs$actions$es._(_root);
	@override late final _Translations$packs$progress$es progress = _Translations$packs$progress$es._(_root);
	@override late final _Translations$packs$delete$es delete = _Translations$packs$delete$es._(_root);
	@override String get empty => 'No hay pack disponible para este sendero.';
	@override late final _Translations$packs$a11y$es a11y = _Translations$packs$a11y$es._(_root);
	@override late final _Translations$packs$types$es types = _Translations$packs$types$es._(_root);
}

// Path: guides
class _Translations$guides$es extends Translations$guides$fr {
	_Translations$guides$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guías de etapa';
	@override String get subtitle => 'Información práctica de pueblos y aldeas, disponible sin conexión.';
	@override String sectionsCount({required Object n}) => '${n} secciones practicas';
	@override String get empty => 'No hay guía disponible para este sendero.';
	@override String get noItems => 'Aún no hay información en esta sección.';
	@override String get facilitatorNote => 'StepWays te orienta hacia los proveedores. La reserva y el pago se hacen en su sitio: nada en la aplicación.';
	@override String get openSite => 'Abrir el sitio';
	@override String get cannotOpen => 'No se puede abrir este enlace en este dispositivo.';
	@override late final _Translations$guides$categories$es categories = _Translations$guides$categories$es._(_root);
	@override late final _Translations$guides$intro$es intro = _Translations$guides$intro$es._(_root);
	@override late final _Translations$guides$a11y$es a11y = _Translations$guides$a11y$es._(_root);
}

// Path: trailSelection
class _Translations$trailSelection$es extends Translations$trailSelection$fr {
	_Translations$trailSelection$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Cambiar de sendero';
	@override String get subtitle => 'Elige el sendero a explorar. Toda la app (mapa, etapas, puntos de interes, packs, guias) sigue tu seleccion.';
	@override String get current => 'Sendero activo';
	@override String get select => 'Elegir este sendero';
	@override String get selected => 'Sendero seleccionado';
	@override String stagesDistance({required Object stages, required Object km}) => '${stages} etapas - ${km} km';
	@override late final _Translations$trailSelection$a11y$es a11y = _Translations$trailSelection$a11y$es._(_root);
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

// Path: accommodation.types
class _Translations$accommodation$types$es extends Translations$accommodation$types$fr {
	_Translations$accommodation$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Refugio';
	@override String get bergerie => 'Majada';
	@override String get gite => 'Albergue';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Camping';
	@override String get bivouac => 'Vivac';
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

// Path: feasibility.levels
class _Translations$feasibility$levels$es extends Translations$feasibility$levels$fr {
	_Translations$feasibility$levels$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get danger => 'Not recommended';
	@override String get caution => 'Preparation needed';
	@override String get good => 'Feasible';
	@override String get excellent => 'Excellent';
}

// Path: feasibility.categories
class _Translations$feasibility$categories$es extends Translations$feasibility$categories$fr {
	_Translations$feasibility$categories$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

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
class _Translations$feasibility$questions$es extends Translations$feasibility$questions$fr {
	_Translations$feasibility$questions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

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
class _Translations$feasibility$answers$es extends Translations$feasibility$answers$fr {
	_Translations$feasibility$answers$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

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
class _Translations$feasibility$recommendations$es extends Translations$feasibility$recommendations$fr {
	_Translations$feasibility$recommendations$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$feasibility$recommendations$danger$es danger = _Translations$feasibility$recommendations$danger$es._(_root);
	@override late final _Translations$feasibility$recommendations$caution$es caution = _Translations$feasibility$recommendations$caution$es._(_root);
	@override late final _Translations$feasibility$recommendations$good$es good = _Translations$feasibility$recommendations$good$es._(_root);
	@override late final _Translations$feasibility$recommendations$excellent$es excellent = _Translations$feasibility$recommendations$excellent$es._(_root);
}

// Path: signalement.types
class _Translations$signalement$types$es extends Translations$signalement$types$fr {
	_Translations$signalement$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get obstacle => 'Obstáculo en el sendero';
	@override String get eauASec => 'Punto de agua seco';
	@override String get danger => 'Peligro';
}

// Path: hebergement.types
class _Translations$hebergement$types$es extends Translations$hebergement$types$fr {
	_Translations$hebergement$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Refugio';
	@override String get gite => 'Casa rural';
	@override String get hotel => 'Hotel';
	@override String get camping => 'Camping';
	@override String get chambreHote => 'Casa de huéspedes';
}

// Path: training.types
class _Translations$training$types$es extends Translations$training$types$fr {
	_Translations$training$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get marche => 'Marcha';
	@override String get cardio => 'Cardio';
	@override String get renforcement => 'Fortalecimiento';
}

// Path: training.intensity
class _Translations$training$intensity$es extends Translations$training$intensity$fr {
	_Translations$training$intensity$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get faible => 'Baja';
	@override String get moderee => 'Moderada';
	@override String get elevee => 'Alta';
}

// Path: gamification.badge
class _Translations$gamification$badge$es extends Translations$gamification$badge$fr {
	_Translations$gamification$badge$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$gamification$badge$firstStage$es firstStage = _Translations$gamification$badge$firstStage$es._(_root);
	@override late final _Translations$gamification$badge$firstTrek$es firstTrek = _Translations$gamification$badge$firstTrek$es._(_root);
	@override late final _Translations$gamification$badge$firstSegment$es firstSegment = _Translations$gamification$badge$firstSegment$es._(_root);
	@override late final _Translations$gamification$badge$elevation5000$es elevation5000 = _Translations$gamification$badge$elevation5000$es._(_root);
	@override late final _Translations$gamification$badge$tenStages$es tenStages = _Translations$gamification$badge$tenStages$es._(_root);
	@override late final _Translations$gamification$badge$challenger$es challenger = _Translations$gamification$badge$challenger$es._(_root);
}

// Path: gamification.defi
class _Translations$gamification$defi$es extends Translations$gamification$defi$fr {
	_Translations$gamification$defi$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get screenTitle => 'Retos';
	@override String get inProgress => 'En curso';
	@override String progressLabel({required Object current, required Object target}) => 'Progreso: ${current} / ${target}';
	@override String get rankingTitle => 'Clasificación del reto';
	@override String get pseudonymNotice => 'Clasificación por grupo, con seudónimos. No se muestra ningún dato personal directo.';
	@override String get notEnoughParticipants => 'No hay suficientes participantes para publicar esta clasificación.';
	@override String get noDefi => 'Ningún reto en curso por ahora.';
}

// Path: waypoints.types
class _Translations$waypoints$types$es extends Translations$waypoints$types$fr {
	_Translations$waypoints$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get eau => 'Agua';
	@override String get ravitaillement => 'Avituallamiento';
	@override String get danger => 'Peligro';
	@override String get camp => 'Acampada';
	@override String get connectivite => 'Conectividad';
	@override String get jonction => 'Cruce';
}

// Path: waypoints.filters
class _Translations$waypoints$filters$es extends Translations$waypoints$filters$fr {
	_Translations$waypoints$filters$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Filtrar waypoints';
	@override String get showAll => 'Mostrar todo';
	@override String get hideAll => 'Ocultar todo';
	@override String get recentConditionOnly => 'Solo condicion reciente';
}

// Path: waypoints.detail
class _Translations$waypoints$detail$es extends Translations$waypoints$detail$fr {
	_Translations$waypoints$detail$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get conditionsTitle => 'Condiciones del terreno';
	@override String get noComments => 'Aun no se ha senalado ninguna condicion.';
	@override String get commentsError => 'Condiciones no disponibles.';
	@override String get report => 'Senalar';
	@override String get reportAck => 'Senalamiento guardado. Se revisara tras la sincronizacion.';
	@override String get pendingSync => 'Pendiente de sincronizacion';
}

// Path: waypoints.freshness
class _Translations$waypoints$freshness$es extends Translations$waypoints$freshness$fr {
	_Translations$waypoints$freshness$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get justNow => 'actualizado ahora mismo';
	@override String minutes({required Object n}) => 'actualizado hace ${n} min';
	@override String hours({required Object n}) => 'actualizado hace ${n} h';
	@override String days({required Object n}) => 'actualizado hace ${n} d';
}

// Path: waypoints.contribution
class _Translations$waypoints$contribution$es extends Translations$waypoints$contribution$fr {
	_Translations$waypoints$contribution$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titleWaypoint => 'Anadir un punto';
	@override String get titleComment => 'Senalar una condicion';
	@override String get chooseType => 'Tipo de punto';
	@override String get titleField => 'Titulo del punto';
	@override String get conditionPrompt => 'Describe la condicion observada';
	@override String get commentField => 'Tu observacion';
	@override String get conditionField => 'Estado (opcional)';
	@override String get conditionHelper => 'p. ej. agua agotada, agua corre, paso resbaladizo';
	@override String get latencyBanner => 'Se publicara en la proxima sincronizacion de red.';
	@override String get submit => 'Guardar';
	@override String get savedTitle => 'Contribucion guardada';
	@override String get savedPendingSync => 'Se publicara cuando vuelva la red.';
	@override String pendingCount({required Object n}) => '${n} pendientes de sincronizacion';
	@override String get close => 'Cerrar';
	@override String get emptyTitle => 'Indica un titulo para el punto.';
	@override String get emptyComment => 'Escribe tu observacion.';
	@override String get noLocation => 'Posicion GPS no disponible. Intentalo de nuevo a cielo abierto.';
	@override String get error => 'No se puede guardar ahora mismo.';
}

// Path: packs.states
class _Translations$packs$states$es extends Translations$packs$states$fr {
	_Translations$packs$states$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get notDownloaded => 'No descargado';
	@override String get downloaded => 'Descargado';
	@override String get updateAvailable => 'Actualización disponible';
}

// Path: packs.actions
class _Translations$packs$actions$es extends Translations$packs$actions$fr {
	_Translations$packs$actions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get download => 'Descargar';
	@override String get update => 'Actualizar';
	@override String get delete => 'Eliminar';
	@override String get retry => 'Reintentar';
	@override String get buy => 'Comprar este pack';
	@override String buyWithPrice({required Object price}) => 'Comprar este pack — ${price}';
}

// Path: packs.progress
class _Translations$packs$progress$es extends Translations$packs$progress$fr {
	_Translations$packs$progress$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String downloading({required Object done, required Object total}) => 'Descargando… ${done}/${total}';
	@override String get verifying => 'Verificando integridad…';
	@override String get completed => 'Pack listo sin conexión';
	@override String get error => 'Error de descarga';
}

// Path: packs.delete
class _Translations$packs$delete$es extends Translations$packs$delete$fr {
	_Translations$packs$delete$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get confirmTitle => '¿Eliminar este pack?';
	@override String get confirmBody => 'El pack se eliminará del dispositivo para liberar espacio. Podrás volver a descargarlo más tarde.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Eliminar';
	@override String get freed => 'Espacio liberado.';
}

// Path: packs.a11y
class _Translations$packs$a11y$es extends Translations$packs$a11y$fr {
	_Translations$packs$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String packCard({required Object nom, required Object state}) => 'Pack ${nom}, ${state}';
	@override String downloadButton({required Object nom}) => 'Descargar el pack ${nom}';
	@override String deleteButton({required Object nom}) => 'Eliminar el pack ${nom}';
}

// Path: packs.types
class _Translations$packs$types$es extends Translations$packs$types$fr {
	_Translations$packs$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$packs$types$nord$es nord = _Translations$packs$types$nord$es._(_root);
	@override late final _Translations$packs$types$sud$es sud = _Translations$packs$types$sud$es._(_root);
	@override late final _Translations$packs$types$complet$es complet = _Translations$packs$types$complet$es._(_root);
	@override late final _Translations$packs$types$mam$es mam = _Translations$packs$types$mam$es._(_root);
}

// Path: guides.categories
class _Translations$guides$categories$es extends Translations$guides$categories$fr {
	_Translations$guides$categories$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Avituallamiento';
	@override String get hebergement => 'Alojamiento';
	@override String get transport => 'Transporte';
	@override String get services => 'Servicios';
	@override String get eau => 'Agua';
	@override String get sante => 'Salud';
}

// Path: guides.intro
class _Translations$guides$intro$es extends Translations$guides$intro$fr {
	_Translations$guides$intro$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ravitaillement => 'Dónde abastecerse de provisiones.';
	@override String get hebergement => 'Dónde dormir en la etapa.';
	@override String get transport => 'Autobuses, lanzaderas y conexiones.';
	@override String get services => 'Correos, banco, lavandería y más.';
	@override String get eau => 'Puntos de agua potable.';
	@override String get sante => 'Farmacia y atención cercana.';
}

// Path: guides.a11y
class _Translations$guides$a11y$es extends Translations$guides$a11y$fr {
	_Translations$guides$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String guideCard({required Object lieu}) => 'Guía de ${lieu}';
	@override String section({required Object titre}) => 'Sección ${titre}';
	@override String openSiteButton({required Object nom}) => 'Abrir el sitio de ${nom}';
}

// Path: trailSelection.a11y
class _Translations$trailSelection$a11y$es extends Translations$trailSelection$a11y$fr {
	_Translations$trailSelection$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String trailCard({required Object nom, required Object region}) => 'Sendero ${nom}, ${region}';
	@override String get currentBadge => 'Sendero actualmente activo';
	@override String selectButton({required Object nom}) => 'Activar el sendero ${nom}';
}

// Path: feasibility.recommendations.danger
class _Translations$feasibility$recommendations$danger$es extends Translations$feasibility$recommendations$danger$fr {
	_Translations$feasibility$recommendations$danger$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparación insuficiente';
	@override String get summary => 'Su perfil muestra carencias importantes. No recomendamos partir.';
	@override late final _Translations$feasibility$recommendations$danger$tips$es tips = _Translations$feasibility$recommendations$danger$tips$es._(_root);
}

// Path: feasibility.recommendations.caution
class _Translations$feasibility$recommendations$caution$es extends Translations$feasibility$recommendations$caution$fr {
	_Translations$feasibility$recommendations$caution$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparación a reforzar';
	@override String get summary => 'Tiene una base, pero algunos puntos necesitan atención.';
	@override late final _Translations$feasibility$recommendations$caution$tips$es tips = _Translations$feasibility$recommendations$caution$tips$es._(_root);
}

// Path: feasibility.recommendations.good
class _Translations$feasibility$recommendations$good$es extends Translations$feasibility$recommendations$good$fr {
	_Translations$feasibility$recommendations$good$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Buena preparación';
	@override String get summary => 'Su perfil es sólido. Algunos ajustes y estará listo(a).';
	@override late final _Translations$feasibility$recommendations$good$tips$es tips = _Translations$feasibility$recommendations$good$tips$es._(_root);
}

// Path: feasibility.recommendations.excellent
class _Translations$feasibility$recommendations$excellent$es extends Translations$feasibility$recommendations$excellent$fr {
	_Translations$feasibility$recommendations$excellent$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Preparación óptima';
	@override String get summary => 'Está perfectamente preparado(a). Disfrute del trekking!';
	@override late final _Translations$feasibility$recommendations$excellent$tips$es tips = _Translations$feasibility$recommendations$excellent$tips$es._(_root);
}

// Path: gamification.badge.firstStage
class _Translations$gamification$badge$firstStage$es extends Translations$gamification$badge$firstStage$fr {
	_Translations$gamification$badge$firstStage$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Primera etapa';
	@override String get description => 'Has completado tu primera etapa.';
}

// Path: gamification.badge.firstTrek
class _Translations$gamification$badge$firstTrek$es extends Translations$gamification$badge$firstTrek$fr {
	_Translations$gamification$badge$firstTrek$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Primer trek';
	@override String get description => 'Has terminado tu primer trek completo.';
}

// Path: gamification.badge.firstSegment
class _Translations$gamification$badge$firstSegment$es extends Translations$gamification$badge$firstSegment$fr {
	_Translations$gamification$badge$firstSegment$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Primer segmento';
	@override String get description => 'Has recorrido tu primer segmento.';
}

// Path: gamification.badge.elevation5000
class _Translations$gamification$badge$elevation5000$es extends Translations$gamification$badge$elevation5000$fr {
	_Translations$gamification$badge$elevation5000$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => '5000 m de desnivel';
	@override String get description => 'Has acumulado 5000 m de desnivel positivo.';
}

// Path: gamification.badge.tenStages
class _Translations$gamification$badge$tenStages$es extends Translations$gamification$badge$tenStages$fr {
	_Translations$gamification$badge$tenStages$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => '10 etapas';
	@override String get description => 'Has completado 10 etapas.';
}

// Path: gamification.badge.challenger
class _Translations$gamification$badge$challenger$es extends Translations$gamification$badge$challenger$fr {
	_Translations$gamification$badge$challenger$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get titre => 'Retador';
	@override String get description => 'Has completado tu primer reto de temporada.';
}

// Path: packs.types.nord
class _Translations$packs$types$nord$es extends Translations$packs$types$nord$fr {
	_Translations$packs$types$nord$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Norte';
	@override String get description => 'La mitad norte del sendero, sin conexión.';
}

// Path: packs.types.sud
class _Translations$packs$types$sud$es extends Translations$packs$types$sud$fr {
	_Translations$packs$types$sud$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Sur';
	@override String get description => 'La mitad sur del sendero, sin conexión.';
}

// Path: packs.types.complet
class _Translations$packs$types$complet$es extends Translations$packs$types$complet$fr {
	_Translations$packs$types$complet$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare Completo';
	@override String get description => 'Todo el sendero, sin conexión.';
}

// Path: packs.types.mam
class _Translations$packs$types$mam$es extends Translations$packs$types$mam$fr {
	_Translations$packs$types$mam$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get nom => 'Mare a Mare';
	@override String get description => 'El sendero Mare a Mare, sin conexión.';
}

// Path: feasibility.recommendations.danger.tips
class _Translations$feasibility$recommendations$danger$tips$es extends Translations$feasibility$recommendations$danger$tips$fr {
	_Translations$feasibility$recommendations$danger$tips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Comience con caminatas cortas para evaluar su condición';
	@override String get tip2 => 'Consulte a un profesional de salud';
	@override String get tip3 => 'Invierta en equipamiento adecuado y pruébelo';
}

// Path: feasibility.recommendations.caution.tips
class _Translations$feasibility$recommendations$caution$tips$es extends Translations$feasibility$recommendations$caution$tips$fr {
	_Translations$feasibility$recommendations$caution$tips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Refuerce su entrenamiento 6 a 8 semanas antes';
	@override String get tip2 => 'Verifique y complete su equipamiento';
	@override String get tip3 => 'Planifique etapas adaptadas a su nivel';
}

// Path: feasibility.recommendations.good.tips
class _Translations$feasibility$recommendations$good$tips$es extends Translations$feasibility$recommendations$good$tips$fr {
	_Translations$feasibility$recommendations$good$tips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Mantenga su ritmo de entrenamiento';
	@override String get tip2 => 'Prevea márgenes en su planificación';
	@override String get tip3 => 'Consulte la meteorología regularmente';
}

// Path: feasibility.recommendations.excellent.tips
class _Translations$feasibility$recommendations$excellent$tips$es extends Translations$feasibility$recommendations$excellent$tips$fr {
	_Translations$feasibility$recommendations$excellent$tips$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tip1 => 'Escuche a su cuerpo durante el trekking';
	@override String get tip2 => 'Comparta su experiencia con otros senderistas';
	@override String get tip3 => 'Documente su aventura en el diario';
}

/// The flat map containing all translations for locale <es>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsEs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'a11y.back' => 'Volver',
			'a11y.zoomIn' => 'Acercar',
			'a11y.zoomOut' => 'Alejar',
			'a11y.centerOnMe' => 'Centrar en mi posicion',
			'a11y.mapRegion' => 'Mapa del sendero',
			'a11y.userPosition' => 'Tu posicion',
			'a11y.stageMarker' => ({required Object number}) => 'Etapa ${number}',
			'a11y.poiMarker' => ({required Object name}) => 'Punto de interes: ${name}',
			'a11y.markerCluster' => ({required Object count}) => '${count} puntos agrupados',
			'a11y.trailCard' => ({required Object name}) => 'Sendero ${name}',
			'a11y.startTracking' => 'Iniciar seguimiento',
			'a11y.pauseTracking' => 'Pausar seguimiento',
			'a11y.resumeTracking' => 'Reanudar seguimiento',
			'a11y.stopTracking' => 'Detener seguimiento',
			'nav.map' => 'Mapa',
			'nav.stages' => 'Etapas',
			'nav.planning' => 'Planificación',
			'nav.journal' => 'Diario',
			'nav.more' => 'Más',
			'nav.checklist' => 'Lista de equipo',
			'nav.feasibility' => 'Viabilidad',
			'nav.tips' => 'Consejos trek',
			'nav.emergency' => 'Contactos de emergencia',
			'nav.catalog' => 'Catálogo de senderos',
			'nav.profile' => 'Perfil',
			'nav.settings' => 'Ajustes',
			'nav.trailSelection' => 'Cambiar de sendero',
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
			'accommodation.types.refuge' => 'Refugio',
			'accommodation.types.bergerie' => 'Majada',
			'accommodation.types.gite' => 'Albergue',
			'accommodation.types.hotel' => 'Hotel',
			'accommodation.types.camping' => 'Camping',
			'accommodation.types.bivouac' => 'Vivac',
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
			'weather.fireRisk' => 'Riesgo de incendio',
			'weather.fireRiskDesc' => 'Alto riesgo de incendio. Consulte las instrucciones de seguridad.',
			'weather.fireSafetyTips' => 'Instrucciones contra incendios',
			'weather.alertCount' => 'alerta',
			'weather.alertCountPlural' => 'alertas',
			'share.title' => 'Compartir',
			'share.generating' => 'Generando...',
			'share.share' => 'Compartir',
			'share.error' => 'Error durante la generación',
			'share.errorShare' => 'Error al compartir',
			'share.preview' => 'Vista previa',
			'share.chooseTemplate' => 'Elegir plantilla',
			'share.templateStats' => 'Estadísticas',
			'share.templateJourney' => 'Recorrido',
			'share.templateStage' => 'Etapa',
			'diploma.title' => 'Diploma de trekking',
			'diploma.yourName' => 'Tu nombre',
			'diploma.namePlaceholder' => 'Introduce tu nombre...',
			'diploma.generatePdf' => 'Generar PDF',
			'diploma.certifies' => 'Certifica que',
			'diploma.completed' => 'ha recorrido el',
			'diploma.pdfTitle' => 'DIPLOMA',
			'diploma.pdfSubtitle' => 'Certificado de logro',
			'diploma.pdfStages' => '{count} etapas',
			'diploma.pdfDistance' => '{km} km recorridos',
			'diploma.pdfElevation' => '{meters} m de desnivel positivo',
			'diploma.pdfDuration' => 'en {days} días',
			'diploma.pdfFrom' => 'Del',
			'diploma.pdfTo' => 'al',
			'diploma.pdfIssuedOn' => 'Emitido el {date}',
			'diploma.recapTitle' => 'Tu aventura',
			'diploma.recapJournalPhotos' => 'Fotos del diario',
			'diploma.recapNoPhotos' => 'Sin fotos en el diario',
			'diploma.recapStats' => 'Estadisticas',
			'diploma.recapStages' => '{count} etapas completadas',
			'diploma.recapDistance' => '{km} km recorridos',
			'diploma.recapElevation' => '{meters} m de desnivel',
			'diploma.recapDuration' => '{days} dias de trekking',
			'diploma.recapMapTrace' => 'Trazado del recorrido',
			'diploma.recapNoMap' => 'Trazado no disponible',
			'diploma.recapJournalEntries' => '{count} notas del diario',
			'diploma.downloadPdf' => 'Descargar diploma PDF',
			'notifications.morningReminder' => 'Recordatorio matutino',
			'notifications.weatherAlerts' => 'Alertas meteorológicas',
			'notifications.countdown' => 'Recordatorio D-2',
			'notifications.countdownDesc' => 'Notificación 2 días antes de la salida',
			'notifications.schedulerCountdownTitle' => 'Tu trek se acerca!',
			'notifications.schedulerCountdownBody' => 'Salida en 2 dias. Revisa tu checklist y el tiempo.',
			'notifications.schedulerDailyTitle' => 'Buen dia de trek!',
			'notifications.schedulerDailyBody' => 'Consulta el tiempo y prepara la etapa del dia.',
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
			'settings.morningReminder' => 'Recordatorio matutino',
			'settings.weatherAlerts' => 'Alertas meteorológicas',
			'settings.weatherAlertsDesc' => 'Notificado si hay condiciones peligrosas',
			'settings.countdownReminder' => 'Recordatorio D-2',
			'settings.countdownDesc' => 'Notificación 2 días antes de la salida',
			'settings.version' => 'Versión',
			'settings.versionLabel' => 'Versión de la aplicación',
			'feedback.title' => 'Comentarios',
			'feedback.type' => 'Tipo de comentario',
			'feedback.bug' => 'Error / Problema',
			'feedback.suggestion' => 'Sugerencia',
			'feedback.compliment' => 'Cumplido',
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
			'auth.pseudonym' => 'Seudónimo',
			'auth.pseudonymHint' => 'Tu nombre de senderista',
			'auth.save' => 'Guardar',
			'auth.changeAvatar' => 'Cambiar avatar',
			'auth.chooseAvatar' => 'Elegir un avatar',
			'auth.errorLoading' => 'Error de carga',
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
			'feasibility.seeRecommendations' => 'Ver recomendaciones',
			'feasibility.yourProfile' => 'Su perfil',
			'feasibility.tipsTitle' => 'Nuestros consejos',
			'feasibility.recommendations.danger.title' => 'Preparación insuficiente',
			'feasibility.recommendations.danger.summary' => 'Su perfil muestra carencias importantes. No recomendamos partir.',
			'feasibility.recommendations.danger.tips.tip1' => 'Comience con caminatas cortas para evaluar su condición',
			'feasibility.recommendations.danger.tips.tip2' => 'Consulte a un profesional de salud',
			'feasibility.recommendations.danger.tips.tip3' => 'Invierta en equipamiento adecuado y pruébelo',
			'feasibility.recommendations.caution.title' => 'Preparación a reforzar',
			'feasibility.recommendations.caution.summary' => 'Tiene una base, pero algunos puntos necesitan atención.',
			'feasibility.recommendations.caution.tips.tip1' => 'Refuerce su entrenamiento 6 a 8 semanas antes',
			'feasibility.recommendations.caution.tips.tip2' => 'Verifique y complete su equipamiento',
			'feasibility.recommendations.caution.tips.tip3' => 'Planifique etapas adaptadas a su nivel',
			'feasibility.recommendations.good.title' => 'Buena preparación',
			'feasibility.recommendations.good.summary' => 'Su perfil es sólido. Algunos ajustes y estará listo(a).',
			'feasibility.recommendations.good.tips.tip1' => 'Mantenga su ritmo de entrenamiento',
			'feasibility.recommendations.good.tips.tip2' => 'Prevea márgenes en su planificación',
			'feasibility.recommendations.good.tips.tip3' => 'Consulte la meteorología regularmente',
			'feasibility.recommendations.excellent.title' => 'Preparación óptima',
			'feasibility.recommendations.excellent.summary' => 'Está perfectamente preparado(a). Disfrute del trekking!',
			'feasibility.recommendations.excellent.tips.tip1' => 'Escuche a su cuerpo durante el trekking',
			'feasibility.recommendations.excellent.tips.tip2' => 'Comparta su experiencia con otros senderistas',
			'feasibility.recommendations.excellent.tips.tip3' => 'Documente su aventura en el diario',
			'tips.carouselTitle' => 'Consejos trek',
			'tips.allCategories' => 'Todas',
			'tips.swipeHint' => 'Desliza para ver mas',
			'tips.detailTitle' => 'Detalle del consejo',
			'tips.readMore' => 'Leer mas',
			'tips.noTips' => 'No hay consejos disponibles',
			'tips.categoryPreparation' => 'Preparacion',
			'tips.categoryEquipment' => 'Equipamiento',
			'tips.categoryNutrition' => 'Nutricion',
			'tips.categorySafety' => 'Seguridad',
			'tips.categoryNature' => 'Naturaleza',
			'tips.categoryRecovery' => 'Recuperacion',
			'tips.categoryGeneral' => 'General',
			'tips.priorityHigh' => 'Prioridad alta',
			'tips.scope' => 'Sendero',
			'tips.season' => 'Temporada',
			'tips.altitude' => 'Altitud min.',
			'goodies.title' => 'Tienda de Goodies',
			'goodies.comingSoon' => 'Este modulo llegara pronto. Mantente atento!',
			'noData.title' => 'Ningún sendero descargado',
			'noData.subtitle' => 'Descarga un sendero para empezar',
			'noData.offlineHint' => 'Los datos estarán disponibles sin conexión para tu caminata.',
			'noData.browseCta' => 'Explorar senderos',
			'updates.readyTitle' => 'Actualización lista',
			'updates.readyBodyOne' => 'Un sendero ha sido actualizado.',
			'updates.readyBodyMany' => ({required Object count}) => '${count} senderos han sido actualizados.',
			'follow.title' => 'Seguimiento en directo',
			'follow.connecting' => 'Conectando…',
			'follow.live' => 'En directo',
			'follow.offline' => 'Sin conexión',
			'follow.invalidLink' => 'Enlace no válido',
			'follow.invalidLinkHint' => 'Este enlace de seguimiento no existe o ha caducado.',
			'cloud.localModeTitle' => 'Modo local',
			'cloud.localModeBody' => 'Esta instalación no está conectada a un servicio en la nube: el seguimiento en directo, la copia de seguridad en línea y la cuenta están desactivados. Sus datos permanecen en el dispositivo.',
			'cloud.statusSection' => 'Nube',
			'cloud.statusActive' => 'Servicios en línea activos',
			'cloud.statusActiveDesc' => 'Copia de seguridad y seguimiento en directo disponibles.',
			'cloud.statusLocal' => 'Modo local (sin nube)',
			'cloud.statusLocalDesc' => 'No se envía ningún dato en línea. Falta la configuración de la nube.',
			'onboarding.skip' => 'Saltar',
			'onboarding.next' => 'Siguiente',
			'onboarding.getStarted' => 'Empezar',
			'onboarding.welcomeTitle' => ({required Object appName}) => 'Bienvenido a ${appName}',
			'onboarding.welcomeSubtitle' => 'Tu compañero de senderismo sin conexión: mapa, navegación GPS, planificación y diario de trek.',
			'onboarding.languageTitle' => 'Elige tu idioma',
			'onboarding.languageSubtitle' => 'Podrás cambiarlo en cualquier momento en los ajustes.',
			'onboarding.downloadTitle' => 'Descarga tu primer sendero',
			'onboarding.downloadSubtitle' => 'Explora el catálogo y descarga un sendero para usarlo completamente sin conexión.',
			'onboarding.browseCatalog' => 'Explorar el catálogo',
			'monetization.demoBanner' => 'Modo demo — toca para desbloquear',
			'monetization.paywallTitle' => 'Desbloquea este trek',
			'monetization.paywallBody' => 'El modo gratuito permite preparar tu trek con publicidad. El premium lo desbloquea todo, sin anuncios.',
			'monetization.featureMap' => 'Mapa sin conexión + GPS + seguimiento en directo',
			'monetization.featureJournal' => 'Diario de ruta completo',
			'monetization.featureDiploma' => 'Diploma de fin de trek',
			'monetization.featureFollowers' => '2 seguidores gratuitos',
			'monetization.featureNoAds' => 'Cero publicidad',
			'monetization.buyCta' => 'Desbloquear este trek',
			'monetization.buyCtaWithPrice' => ({required Object price}) => 'Desbloquear este trek — ${price} €',
			'signalement.title' => 'Notificar',
			'signalement.chooseType' => '¿Qué quieres notificar?',
			'signalement.types.obstacle' => 'Obstáculo en el sendero',
			'signalement.types.eauASec' => 'Punto de agua seco',
			'signalement.types.danger' => 'Peligro',
			'signalement.latencyBanner' => 'Guardado. Visible para otros senderistas tras la sincronización de red.',
			'signalement.confirm' => 'Confirmar notificación',
			'signalement.noLocation' => 'Posición GPS no disponible ahora. Inténtalo de nuevo a cielo abierto.',
			'signalement.savedTitle' => 'Notificación guardada',
			'signalement.savedPendingSync' => 'Se compartirá en cuanto vuelva la red.',
			'signalement.pendingCount' => ({required Object n}) => '${n} en espera de sincronización',
			'signalement.close' => 'Cerrar',
			'hebergement.title' => 'Alojamientos cercanos',
			'hebergement.facilitatorNote' => 'StepWays te dirige a los alojamientos. La reserva se hace en su sitio: ningún pago en la aplicación.',
			'hebergement.detourAR' => ({required Object km}) => 'Desvío ida y vuelta: ${km} km',
			'hebergement.openSite' => 'Ver el sitio',
			'hebergement.cannotOpen' => 'No se pudo abrir este enlace en este dispositivo.',
			'hebergement.empty' => 'No hay alojamientos cerca por ahora.',
			'hebergement.types.refuge' => 'Refugio',
			'hebergement.types.gite' => 'Casa rural',
			'hebergement.types.hotel' => 'Hotel',
			'hebergement.types.camping' => 'Camping',
			'hebergement.types.chambreHote' => 'Casa de huéspedes',
			'training.title' => 'Preparación física',
			'training.localNotice' => 'Tu plan se calcula y se guarda en tu teléfono. Los recordatorios son notificaciones locales, sin seguimiento.',
			'training.reminderTitle' => 'Sesión de entrenamiento hoy',
			'training.scheduleReminders' => 'Programar recordatorios',
			'training.remindersScheduled' => ({required Object n}) => '${n} recordatorio(s) programado(s)',
			'training.week' => ({required Object n}) => 'Semana ${n}',
			'training.minutes' => ({required Object n}) => '${n} min',
			'training.progress' => ({required Object done, required Object total}) => '${done}/${total} sesiones hechas',
			'training.types.marche' => 'Marcha',
			'training.types.cardio' => 'Cardio',
			'training.types.renforcement' => 'Fortalecimiento',
			'training.intensity.faible' => 'Baja',
			'training.intensity.moderee' => 'Moderada',
			'training.intensity.elevee' => 'Alta',
			'eta.title' => 'Tiempo estimado',
			'eta.toNextWaypoint' => 'Próximo punto',
			'eta.toStageEnd' => 'Fin de etapa',
			'eta.confidenceHigh' => 'Estimación fiable',
			'eta.confidenceLow' => 'Aproximado (GPS débil)',
			'eta.durationHm' => ({required Object h, required Object m}) => '${h} h ${m} min',
			'eta.durationM' => ({required Object m}) => '${m} min',
			'leaderboard.title' => 'Rey de la etapa',
			'leaderboard.unavailable' => 'Clasificación no disponible por ahora.',
			'leaderboard.empty' => 'Aún no hay clasificación para este segmento. ¡Sé el primero en recorrerlo!',
			'leaderboard.pseudonymNotice' => 'Clasificación por grupo, con seudónimos. No se muestra ningún dato personal directo.',
			'leaderboard.trancheLabel' => ({required Object tranche}) => 'Grupo: ${tranche}',
			'leaderboard.notEnoughParticipants' => 'No hay suficientes participantes para publicar esta clasificación.',
			'leaderboard.entrySemantics' => ({required Object rank, required Object pseudonym, required Object time}) => 'Posición ${rank}, ${pseudonym}, tiempo ${time}',
			'social.feedTitle' => 'Registro de actividad',
			'social.empty' => 'Ninguna actividad por ahora.',
			'social.kudos' => 'Animar',
			'social.kudosCount' => ({required Object n}) => '${n} ánimos',
			'social.report' => 'Denunciar',
			'social.reportTitle' => 'Denunciar esta publicación',
			'social.reportReasonLabel' => 'Motivo de la denuncia',
			'social.reasonSpam' => 'Spam o publicidad',
			'social.reasonAbuse' => 'Contenido abusivo o de odio',
			'social.reasonOther' => 'Otro',
			'social.reportSend' => 'Enviar denuncia',
			'social.reportSent' => 'Denuncia enviada. Nuestro equipo la revisará.',
			'social.syncPending' => 'Esperando sincronización',
			'social.synced' => 'Sincronizado',
			'social.activitySegment' => 'completó un segmento',
			'social.activityBadge' => 'obtuvo una insignia',
			'social.activityDefi' => 'avanzó en un reto',
			'gamification.galleryTitle' => 'Mis insignias',
			'gamification.obtained' => 'Obtenida',
			'gamification.locked' => 'Bloqueada',
			'gamification.tierDebutant' => 'Principiante',
			'gamification.tierExpert' => 'Experto',
			'gamification.badge.firstStage.titre' => 'Primera etapa',
			'gamification.badge.firstStage.description' => 'Has completado tu primera etapa.',
			'gamification.badge.firstTrek.titre' => 'Primer trek',
			'gamification.badge.firstTrek.description' => 'Has terminado tu primer trek completo.',
			'gamification.badge.firstSegment.titre' => 'Primer segmento',
			'gamification.badge.firstSegment.description' => 'Has recorrido tu primer segmento.',
			'gamification.badge.elevation5000.titre' => '5000 m de desnivel',
			'gamification.badge.elevation5000.description' => 'Has acumulado 5000 m de desnivel positivo.',
			'gamification.badge.tenStages.titre' => '10 etapas',
			'gamification.badge.tenStages.description' => 'Has completado 10 etapas.',
			'gamification.badge.challenger.titre' => 'Retador',
			'gamification.badge.challenger.description' => 'Has completado tu primer reto de temporada.',
			'gamification.defi.screenTitle' => 'Retos',
			'gamification.defi.inProgress' => 'En curso',
			'gamification.defi.progressLabel' => ({required Object current, required Object target}) => 'Progreso: ${current} / ${target}',
			'gamification.defi.rankingTitle' => 'Clasificación del reto',
			'gamification.defi.pseudonymNotice' => 'Clasificación por grupo, con seudónimos. No se muestra ningún dato personal directo.',
			'gamification.defi.notEnoughParticipants' => 'No hay suficientes participantes para publicar esta clasificación.',
			'gamification.defi.noDefi' => 'Ningún reto en curso por ahora.',
			'shareVisibility.title' => 'Compartir y visibilidad',
			'shareVisibility.intro' => 'Por defecto, no se comparte nada. Activa abajo, finalidad por finalidad, lo que quieras hacer visible.',
			'shareVisibility.consentLink' => 'Gestionar mi consentimiento (privacidad)',
			'shareVisibility.stageResults' => 'Compartir mis resultados de etapa',
			'shareVisibility.stageResultsDesc' => 'Una tarjeta con seudónimo (sin datos personales directos).',
			'shareVisibility.leaderboard' => 'Aparecer en las clasificaciones',
			'shareVisibility.leaderboardDesc' => 'Clasificación por grupo, con un seudónimo.',
			'shareVisibility.activityFeed' => 'Publicar en el registro de actividad',
			'shareVisibility.activityFeedDesc' => 'Tus actividades aparecen en el registro, con un seudónimo.',
			'shareVisibility.shareTitle' => 'Compartir esta etapa',
			'shareVisibility.shareButton' => 'Compartir',
			'shareVisibility.privateNotice' => 'Compartir está desactivado. Actívalo en Compartir y visibilidad.',
			'shareVisibility.shared' => 'Tarjeta lista para compartir.',
			'waypoints.types.eau' => 'Agua',
			'waypoints.types.ravitaillement' => 'Avituallamiento',
			'waypoints.types.danger' => 'Peligro',
			'waypoints.types.camp' => 'Acampada',
			'waypoints.types.connectivite' => 'Conectividad',
			'waypoints.types.jonction' => 'Cruce',
			'waypoints.filters.title' => 'Filtrar waypoints',
			_ => null,
		} ?? switch (path) {
			'waypoints.filters.showAll' => 'Mostrar todo',
			'waypoints.filters.hideAll' => 'Ocultar todo',
			'waypoints.filters.recentConditionOnly' => 'Solo condicion reciente',
			'waypoints.detail.conditionsTitle' => 'Condiciones del terreno',
			'waypoints.detail.noComments' => 'Aun no se ha senalado ninguna condicion.',
			'waypoints.detail.commentsError' => 'Condiciones no disponibles.',
			'waypoints.detail.report' => 'Senalar',
			'waypoints.detail.reportAck' => 'Senalamiento guardado. Se revisara tras la sincronizacion.',
			'waypoints.detail.pendingSync' => 'Pendiente de sincronizacion',
			'waypoints.freshness.justNow' => 'actualizado ahora mismo',
			'waypoints.freshness.minutes' => ({required Object n}) => 'actualizado hace ${n} min',
			'waypoints.freshness.hours' => ({required Object n}) => 'actualizado hace ${n} h',
			'waypoints.freshness.days' => ({required Object n}) => 'actualizado hace ${n} d',
			'waypoints.contribution.titleWaypoint' => 'Anadir un punto',
			'waypoints.contribution.titleComment' => 'Senalar una condicion',
			'waypoints.contribution.chooseType' => 'Tipo de punto',
			'waypoints.contribution.titleField' => 'Titulo del punto',
			'waypoints.contribution.conditionPrompt' => 'Describe la condicion observada',
			'waypoints.contribution.commentField' => 'Tu observacion',
			'waypoints.contribution.conditionField' => 'Estado (opcional)',
			'waypoints.contribution.conditionHelper' => 'p. ej. agua agotada, agua corre, paso resbaladizo',
			'waypoints.contribution.latencyBanner' => 'Se publicara en la proxima sincronizacion de red.',
			'waypoints.contribution.submit' => 'Guardar',
			'waypoints.contribution.savedTitle' => 'Contribucion guardada',
			'waypoints.contribution.savedPendingSync' => 'Se publicara cuando vuelva la red.',
			'waypoints.contribution.pendingCount' => ({required Object n}) => '${n} pendientes de sincronizacion',
			'waypoints.contribution.close' => 'Cerrar',
			'waypoints.contribution.emptyTitle' => 'Indica un titulo para el punto.',
			'waypoints.contribution.emptyComment' => 'Escribe tu observacion.',
			'waypoints.contribution.noLocation' => 'Posicion GPS no disponible. Intentalo de nuevo a cielo abierto.',
			'waypoints.contribution.error' => 'No se puede guardar ahora mismo.',
			'packs.title' => 'Packs de sendero',
			'packs.subtitle' => 'Descarga un pack para caminar 100% sin conexión.',
			'packs.alaCarteNote' => 'A la carte: compra solo el pack que necesitas, sin suscripción.',
			'packs.size' => ({required Object mo}) => '${mo} MB',
			'packs.states.notDownloaded' => 'No descargado',
			'packs.states.downloaded' => 'Descargado',
			'packs.states.updateAvailable' => 'Actualización disponible',
			'packs.actions.download' => 'Descargar',
			'packs.actions.update' => 'Actualizar',
			'packs.actions.delete' => 'Eliminar',
			'packs.actions.retry' => 'Reintentar',
			'packs.actions.buy' => 'Comprar este pack',
			'packs.actions.buyWithPrice' => ({required Object price}) => 'Comprar este pack — ${price}',
			'packs.progress.downloading' => ({required Object done, required Object total}) => 'Descargando… ${done}/${total}',
			'packs.progress.verifying' => 'Verificando integridad…',
			'packs.progress.completed' => 'Pack listo sin conexión',
			'packs.progress.error' => 'Error de descarga',
			'packs.delete.confirmTitle' => '¿Eliminar este pack?',
			'packs.delete.confirmBody' => 'El pack se eliminará del dispositivo para liberar espacio. Podrás volver a descargarlo más tarde.',
			'packs.delete.cancel' => 'Cancelar',
			'packs.delete.confirm' => 'Eliminar',
			'packs.delete.freed' => 'Espacio liberado.',
			'packs.empty' => 'No hay pack disponible para este sendero.',
			'packs.a11y.packCard' => ({required Object nom, required Object state}) => 'Pack ${nom}, ${state}',
			'packs.a11y.downloadButton' => ({required Object nom}) => 'Descargar el pack ${nom}',
			'packs.a11y.deleteButton' => ({required Object nom}) => 'Eliminar el pack ${nom}',
			'packs.types.nord.nom' => 'Mare a Mare Norte',
			'packs.types.nord.description' => 'La mitad norte del sendero, sin conexión.',
			'packs.types.sud.nom' => 'Mare a Mare Sur',
			'packs.types.sud.description' => 'La mitad sur del sendero, sin conexión.',
			'packs.types.complet.nom' => 'Mare a Mare Completo',
			'packs.types.complet.description' => 'Todo el sendero, sin conexión.',
			'packs.types.mam.nom' => 'Mare a Mare',
			'packs.types.mam.description' => 'El sendero Mare a Mare, sin conexión.',
			'guides.title' => 'Guías de etapa',
			'guides.subtitle' => 'Información práctica de pueblos y aldeas, disponible sin conexión.',
			'guides.sectionsCount' => ({required Object n}) => '${n} secciones practicas',
			'guides.empty' => 'No hay guía disponible para este sendero.',
			'guides.noItems' => 'Aún no hay información en esta sección.',
			'guides.facilitatorNote' => 'StepWays te orienta hacia los proveedores. La reserva y el pago se hacen en su sitio: nada en la aplicación.',
			'guides.openSite' => 'Abrir el sitio',
			'guides.cannotOpen' => 'No se puede abrir este enlace en este dispositivo.',
			'guides.categories.ravitaillement' => 'Avituallamiento',
			'guides.categories.hebergement' => 'Alojamiento',
			'guides.categories.transport' => 'Transporte',
			'guides.categories.services' => 'Servicios',
			'guides.categories.eau' => 'Agua',
			'guides.categories.sante' => 'Salud',
			'guides.intro.ravitaillement' => 'Dónde abastecerse de provisiones.',
			'guides.intro.hebergement' => 'Dónde dormir en la etapa.',
			'guides.intro.transport' => 'Autobuses, lanzaderas y conexiones.',
			'guides.intro.services' => 'Correos, banco, lavandería y más.',
			'guides.intro.eau' => 'Puntos de agua potable.',
			'guides.intro.sante' => 'Farmacia y atención cercana.',
			'guides.a11y.guideCard' => ({required Object lieu}) => 'Guía de ${lieu}',
			'guides.a11y.section' => ({required Object titre}) => 'Sección ${titre}',
			'guides.a11y.openSiteButton' => ({required Object nom}) => 'Abrir el sitio de ${nom}',
			'trailSelection.title' => 'Cambiar de sendero',
			'trailSelection.subtitle' => 'Elige el sendero a explorar. Toda la app (mapa, etapas, puntos de interes, packs, guias) sigue tu seleccion.',
			'trailSelection.current' => 'Sendero activo',
			'trailSelection.select' => 'Elegir este sendero',
			'trailSelection.selected' => 'Sendero seleccionado',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} etapas - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Sendero ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Sendero actualmente activo',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Activar el sendero ${nom}',
			_ => null,
		};
	}
}
