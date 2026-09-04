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
	@override late final _Translations$branding$es branding = _Translations$branding$es._(_root);
	@override late final _Translations$hub$es hub = _Translations$hub$es._(_root);
	@override late final _Translations$map$es map = _Translations$map$es._(_root);
	@override late final _Translations$stage$es stage = _Translations$stage$es._(_root);
	@override late final _Translations$trail$es trail = _Translations$trail$es._(_root);
	@override late final _Translations$poi$es poi = _Translations$poi$es._(_root);
	@override late final _Translations$accommodation$es accommodation = _Translations$accommodation$es._(_root);
	@override late final _Translations$gps$es gps = _Translations$gps$es._(_root);
	@override late final _Translations$navAlert$es navAlert = _Translations$navAlert$es._(_root);
	@override late final _Translations$planning$es planning = _Translations$planning$es._(_root);
	@override late final _Translations$itinerary$es itinerary = _Translations$itinerary$es._(_root);
	@override late final _Translations$tracking$es tracking = _Translations$tracking$es._(_root);
	@override late final _Translations$checklist$es checklist = _Translations$checklist$es._(_root);
	@override late final _Translations$journal$es journal = _Translations$journal$es._(_root);
	@override late final _Translations$weather$es weather = _Translations$weather$es._(_root);
	@override late final _Translations$share$es share = _Translations$share$es._(_root);
	@override late final _Translations$diploma$es diploma = _Translations$diploma$es._(_root);
	@override late final _Translations$notifications$es notifications = _Translations$notifications$es._(_root);
	@override late final _Translations$settings$es settings = _Translations$settings$es._(_root);
	@override late final _Translations$appearance$es appearance = _Translations$appearance$es._(_root);
	@override late final _Translations$feedback$es feedback = _Translations$feedback$es._(_root);
	@override late final _Translations$auth$es auth = _Translations$auth$es._(_root);
	@override late final _Translations$feasibility$es feasibility = _Translations$feasibility$es._(_root);
	@override late final _Translations$tips$es tips = _Translations$tips$es._(_root);
	@override late final _Translations$goodies$es goodies = _Translations$goodies$es._(_root);
	@override late final _Translations$noData$es noData = _Translations$noData$es._(_root);
	@override late final _Translations$catalog$es catalog = _Translations$catalog$es._(_root);
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
	@override late final _Translations$health$es health = _Translations$health$es._(_root);
	@override late final _Translations$trailSelection$es trailSelection = _Translations$trailSelection$es._(_root);
	@override late final _Translations$consent$es consent = _Translations$consent$es._(_root);
	@override late final _Translations$moderation$es moderation = _Translations$moderation$es._(_root);
	@override late final _Translations$bootstrap$es bootstrap = _Translations$bootstrap$es._(_root);
	@override late final _Translations$recap$es recap = _Translations$recap$es._(_root);
	@override late final _Translations$programme$es programme = _Translations$programme$es._(_root);
	@override late final _Translations$calendar$es calendar = _Translations$calendar$es._(_root);
	@override late final _Translations$nuitees$es nuitees = _Translations$nuitees$es._(_root);
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
	@override String get sos => 'Llamada de emergencia SOS';
	@override String get mapLayers => 'Capas del mapa';
}

// Path: nav
class _Translations$nav$es extends Translations$nav$fr {
	_Translations$nav$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get accueil => 'Inicio';
	@override String get map => 'Mapa';
	@override String get stages => 'Etapas';
	@override String get planning => 'Planificación';
	@override String get journal => 'Diario';
	@override String get more => 'Más';
	@override String get checklist => 'Equipo & Mochila';
	@override String get feasibility => 'Viabilidad';
	@override String get tips => 'Consejos trek';
	@override String get emergency => 'Contactos de emergencia';
	@override String get catalog => 'Catálogo de senderos';
	@override String get profile => 'Perfil';
	@override String get settings => 'Ajustes';
	@override String get trailSelection => 'Cambiar de sendero';
}

// Path: branding
class _Translations$branding$es extends Translations$branding$fr {
	_Translations$branding$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get tagline => 'Tu compañero de trekking';
	@override String get subline => 'Prepara, camina, comparte';
}

// Path: hub
class _Translations$hub$es extends Translations$hub$fr {
	_Translations$hub$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String greeting({required Object name}) => '¡Hola, ${name}!';
	@override String get greetingFallback => 'Senderista';
	@override String get infoTooltip => 'Acerca de este sendero';
	@override String get profileTooltip => 'Mi perfil';
	@override String get infoSheetBody => 'Este sendero te acompaña en cada paso: planifica tu itinerario, prepara tu mochila y luego sal con la navegación GPS. Cada función es accesible desde esta pantalla de inicio.';
	@override late final _Translations$hub$trekCard$es trekCard = _Translations$hub$trekCard$es._(_root);
	@override late final _Translations$hub$weather$es weather = _Translations$hub$weather$es._(_root);
	@override String get startCta => 'Iniciar el trek';
	@override late final _Translations$hub$sections$es sections = _Translations$hub$sections$es._(_root);
	@override late final _Translations$hub$cards$es cards = _Translations$hub$cards$es._(_root);
	@override late final _Translations$hub$fab$es fab = _Translations$hub$fab$es._(_root);
}

// Path: map
class _Translations$map$es extends Translations$map$fr {
	_Translations$map$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mapa del sendero';
	@override String get loading => 'Cargando el recorrido...';
	@override String get noTrack => 'Ningún recorrido disponible';
	@override String get viewMap => 'Ver el mapa';
	@override String get layers => 'Capas';
	@override String get layersTitle => 'Capas del mapa';
	@override String get layersSubtitle => 'Elige que mostrar en el mapa';
	@override String stageRemaining({required Object km}) => '${km} km restantes';
	@override String get offTrackChip => 'Fuera de ruta';
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
	@override String get duration => 'Duración estimada';
	@override String get description => 'Descripción';
	@override String get coordinates => 'Coordenadas';
	@override String get pois => 'Puntos de interés';
	@override late final _Translations$stage$difficulty$es difficulty = _Translations$stage$difficulty$es._(_root);
	@override String get remaining => '{distance} km restantes';
	@override String get arrived => 'Has llegado!';
	@override String get altitudeProfile => 'Perfil altimetrico';
	@override String get statistics => 'Estadisticas';
	@override String get loading => 'Cargando...';
	@override String get loadingList => 'Cargando las etapas...';
	@override String get dPlus => 'D+';
	@override String get dMinus => 'D-';
	@override String get difficultyLabel => 'Dificultad';
	@override late final _Translations$stage$waterSources$es waterSources = _Translations$stage$waterSources$es._(_root);
	@override late final _Translations$stage$accommodation$es accommodation = _Translations$stage$accommodation$es._(_root);
	@override late final _Translations$stage$advice$es advice = _Translations$stage$advice$es._(_root);
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
	@override String get filter => 'Filtrar puntos de interés';
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

// Path: navAlert
class _Translations$navAlert$es extends Translations$navAlert$fr {
	_Translations$navAlert$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String offTrackBanner({required Object meters}) => 'Te estas alejando del sendero — ${meters} m. Comprueba tu posicion.';
	@override String get offTrackNotifTitle => 'Estas saliendo del sendero';
	@override String offTrackNotifBody({required Object meters}) => 'Te estas alejando del sendero (${meters} m). Comprueba tu posicion.';
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

// Path: itinerary
class _Translations$itinerary$es extends Translations$itinerary$fr {
	_Translations$itinerary$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Itinerario';
	@override String get subtitle => 'Tus etapas, dia a dia';
	@override String get empty => 'Ninguna etapa disponible';
	@override String get emptyHint => 'Los datos del sendero no estan cargados.';
	@override String get loading => 'Cargando itinerario...';
	@override String get error => 'No se puede cargar el itinerario';
	@override String get day => 'Dia';
	@override String get stage => 'Etapa';
	@override String get stages => 'Etapas';
	@override String get totalDistance => 'Distancia';
	@override String get totalElevation => 'D+';
	@override String get restDay => 'Dia de descanso';
	@override String get viewStage => 'Ver etapa';
	@override String get openMap => 'Ver en el mapa';
	@override String get stageCount => '{count} etapas';
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
	@override String get dPlus => 'D+';
	@override String get stopSaveProgress => 'Tu progreso se guardara.';
	@override String get cancel => 'Cancelar';
	@override String get stopButton => 'Detener';
}

// Path: checklist
class _Translations$checklist$es extends Translations$checklist$fr {
	_Translations$checklist$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Equipo & Mochila';
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
	@override late final _Translations$checklist$weight$es weight = _Translations$checklist$weight$es._(_root);
	@override late final _Translations$checklist$ui$es ui = _Translations$checklist$ui$es._(_root);
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
	@override String get today => 'Hoy';
	@override String get tomorrow => 'Mañana';
	@override String get dayPlus2 => 'Pasado mañana';
	@override String get allStages => 'Todas las etapas';
	@override String get noForecast => 'No hay previsión disponible.';
	@override String stageLabel({required Object number}) => 'Etapa ${number}';
	@override String get stormAlertsTitle => 'Alertas de tormenta';
	@override String get stormAlertsToggleOn => 'Alertas de tormenta activadas';
	@override String get stormAlertsToggleOff => 'Alertas de tormenta desactivadas';
	@override String lastUpdate({required Object date}) => 'Actualizado ${date}';
	@override String get guideTitle => 'Entender la meteorología';
	@override String get guideBody => 'Las previsiones cubren 7 días para cada etapa. Vigila las alertas de tormenta y viento: en la montaña el tiempo cambia rápido. Sin red se muestran los últimos datos guardados.';
	@override late final _Translations$weather$source$es source = _Translations$weather$source$es._(_root);
	@override late final _Translations$weather$recommendation$es recommendation = _Translations$weather$recommendation$es._(_root);
	@override late final _Translations$weather$alert$es alert = _Translations$weather$alert$es._(_root);
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
	@override String get lockedTitle => 'Diploma bloqueado';
	@override String get lockedMessage => 'Completa toda tu ruta para desbloquear tu diploma de finisher.';
	@override String get labelIntegral => 'Ruta integral';
	@override String get labelPartial => 'Ruta parcial';
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
	@override String get offTrackAlerts => 'Alerta fuera del sendero';
	@override String get offTrackAlertsDesc => 'Notificación + vibración si sales del sendero';
	@override String get version => 'Versión';
	@override String get versionLabel => 'Versión de la aplicación';
}

// Path: appearance
class _Translations$appearance$es extends Translations$appearance$fr {
	_Translations$appearance$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Apariencia';
	@override String get subtitle => 'Elige el aspecto de la aplicación';
	@override String get skinSentierVivant => 'Sendero Vivo';
	@override String get skinSentierVivantDesc => 'Moderno y colorido, el color del sendero como protagonista';
	@override String get skinTopographique => 'Topográfico';
	@override String get skinTopographiqueDesc => 'Estilo mapa topográfico, datos en primer plano';
	@override String get skinGrandAir => 'Aire Libre';
	@override String get skinGrandAirDesc => 'Fotos a pantalla completa, ambiente de diario de aventura';
	@override String get unavailableOnTrail => 'No disponible en este sendero';
	@override String get changeSkin => 'Cambiar aspecto';
	@override String get selected => 'Seleccionado';
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
	@override String get anonymous => 'Senderista sin cuenta';
	@override String get connectedVia => 'Conectado vía';
	@override String get signInGoogle => 'Iniciar sesión con Google';
	@override String get signInGoogleDesc => 'Para guardar tu progreso';
	@override String get signOut => 'Cerrar sesión';
	@override String get signOutDesc => 'Volver al modo sin cuenta';
	@override String get signOutConfirm => '¿Cerrar sesión?';
	@override String get signOutMessage => 'Volverás al modo sin cuenta. Tus datos locales se conservan.';
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

// Path: catalog
class _Translations$catalog$es extends Translations$catalog$fr {
	_Translations$catalog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Catálogo de senderos';
	@override String get enter => 'Entrar';
	@override String get mustDownload => 'Descarga este sendero para explorarlo.';
	@override String get emptyTitle => 'Ningún sendero disponible';
	@override String get emptySubtitle => 'Aún no hay ningún sendero en el catálogo.';
	@override late final _Translations$catalog$a11y$es a11y = _Translations$catalog$a11y$es._(_root);
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
	@override String get title => 'Guías de los pueblos';
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

// Path: health
class _Translations$health$es extends Translations$health$fr {
	_Translations$health$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Información de salud';
	@override String get privacyBanner => 'Estos datos permanecen en tu teléfono. Nunca se envían por internet.';
	@override late final _Translations$health$field$es field = _Translations$health$field$es._(_root);
	@override late final _Translations$health$hint$es hint = _Translations$health$hint$es._(_root);
	@override String get save => 'Guardar';
	@override String get saving => 'Guardando…';
	@override String get saved => 'Información guardada';
	@override String get emergencyHint => 'En caso de emergencia, muestra esta pantalla a los servicios de rescate.';
	@override String get entryTitle => 'Mi información de salud';
	@override String get entrySubtitle => 'Para mostrar a los servicios de rescate (permanece en el teléfono)';
	@override late final _Translations$health$a11y$es a11y = _Translations$health$a11y$es._(_root);
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

// Path: consent
class _Translations$consent$es extends Translations$consent$fr {
	_Translations$consent$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get onboardingTitle => 'Tu privacidad, tu elección';
	@override String get onboardingIntro => 'Nada está activado por defecto. Elige, finalidad por finalidad, lo que autorizas. Podrás cambiarlo todo en cualquier momento en los ajustes.';
	@override String get settingsTitle => 'Privacidad y consentimiento';
	@override String get settingsIntro => 'Gestiona aquí cada permiso. Puedes retirar un consentimiento en cualquier momento, sin afectar al resto.';
	@override String get settingsEntry => 'Privacidad y consentimiento';
	@override String get settingsEntryDesc => 'Gestionar mis permisos (ubicación, compartir, salud)';
	@override late final _Translations$consent$purposes$es purposes = _Translations$consent$purposes$es._(_root);
	@override String get healthBadge => 'Dato sensible';
	@override String get healthWarning => 'La frecuencia cardíaca es un dato de salud (artículo 9 del RGPD). Este consentimiento se solicita por separado y nunca se agrupa con los demás. Tus datos de salud no se envían a nuestros servidores.';
	@override String get granted => 'Autorizado';
	@override String get denied => 'No autorizado';
	@override String get grant => 'Autorizar';
	@override String get revoke => 'Retirar';
	@override String decidedOn({required Object date}) => 'Elegido el ${date}';
	@override String get notDecided => 'A la espera de tu elección';
	@override String get acceptSelected => 'Confirmar mis elecciones';
	@override String get declineAll => 'Rechazar todo';
	@override String get continueLabel => 'Continuar';
	@override String get privacyPolicyLink => 'Leer la política de privacidad';
	@override String get reviewNeeded => 'Nuestra política ha cambiado: revisa tus elecciones.';
	@override late final _Translations$consent$a11y$es a11y = _Translations$consent$a11y$es._(_root);
}

// Path: moderation
class _Translations$moderation$es extends Translations$moderation$fr {
	_Translations$moderation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get reportTitle => 'Denunciar este contenido';
	@override String get reportIntro => 'Ayúdanos a mantener una comunidad sana. Indica por qué este contenido te parece ilícito. Tu denuncia será examinada por un moderador.';
	@override String get reasonLabel => 'Motivo de la denuncia';
	@override late final _Translations$moderation$reasons$es reasons = _Translations$moderation$reasons$es._(_root);
	@override String get detailsLabel => 'Añade detalles (opcional)';
	@override String get detailsHint => 'Añade un comentario para ayudar al moderador.';
	@override String get contactLabel => 'Tu dirección de correo electrónico';
	@override String get contactHint => 'Para mantenerte informado sobre la gestión (artículo 16).';
	@override String get goodFaithLabel => 'Declaro de buena fe que esta información es exacta.';
	@override String get submit => 'Enviar denuncia';
	@override String get submitting => 'Enviando…';
	@override String get sent => 'Denuncia enviada. Gracias, un moderador la examinará.';
	@override String get errorRequired => 'Completa el motivo, tu correo y la declaración de buena fe.';
	@override String get errorGeneric => 'No se pudo enviar la denuncia. Inténtalo de nuevo.';
	@override String get cancel => 'Cancelar';
	@override String get reasonsTitle => '¿Por qué se ha restringido este contenido?';
	@override String get reasonsIntro => 'De conformidad con el artículo 17, aquí está el motivo de la decisión de moderación relativa a tu contenido.';
	@override String get decisionLabel => 'Decisión';
	@override late final _Translations$moderation$decisions$es decisions = _Translations$moderation$decisions$es._(_root);
	@override String get noStatement => 'No se ha aplicado ninguna restricción a tu contenido.';
	@override String get complaintAction => 'Impugnar esta decisión';
	@override String get complaintTitle => 'Impugnar una decisión';
	@override String get complaintIntro => 'Puedes impugnar una decisión de moderación. Explica por qué consideras la decisión injustificada (artículo 20).';
	@override String get complaintExposeLabel => 'Tu impugnación';
	@override String get complaintExposeHint => 'Describe los motivos de tu impugnación.';
	@override String get complaintSubmit => 'Enviar impugnación';
	@override String get complaintSent => 'Impugnación registrada. Será examinada.';
	@override String get complaintEmpty => 'Explica tu impugnación.';
	@override late final _Translations$moderation$a11y$es a11y = _Translations$moderation$a11y$es._(_root);
}

// Path: bootstrap
class _Translations$bootstrap$es extends Translations$bootstrap$fr {
	_Translations$bootstrap$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get loading => 'Preparando tu excursión…';
}

// Path: recap
class _Translations$recap$es extends Translations$recap$fr {
	_Translations$recap$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Mi aventura';
	@override String get lockedTitle => 'Disponible al final de la ruta';
	@override String get lockedMessage => 'Termina o abandona tu ruta para ver el resumen de tu aventura.';
	@override String get finisherTitle => 'Felicidades!';
	@override String get finisherSubtitle => 'Has completado tu ruta';
	@override String get partialTitle => 'Tu ruta parcial';
	@override String get partialSubtitle => 'Tu aventura queda registrada';
	@override String get statsSection => 'Estadisticas';
	@override String get traceSection => 'Tu trazado';
	@override String get noTrace => 'No hay trazado GPS disponible';
	@override String get stages => '{done} / {total} etapas recorridas';
	@override String get distance => '{km} km recorridos';
	@override String get elevation => '{meters} m de desnivel positivo';
	@override String get duration => '{days} dias';
	@override String get dates => 'Del {start} al {end}';
	@override String get viewDiploma => 'Ver mi diploma';
	@override String get noData => 'Aun no hay datos de ruta para mostrar.';
}

// Path: programme
class _Translations$programme$es extends Translations$programme$fr {
	_Translations$programme$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programa';
	@override String get helpTooltip => 'Ayuda';
	@override late final _Translations$programme$stats$es stats = _Translations$programme$stats$es._(_root);
	@override late final _Translations$programme$legend$es legend = _Translations$programme$legend$es._(_root);
	@override String get restDay => 'Día de descanso';
	@override String get restDayLabel => 'R';
	@override late final _Translations$programme$actions$es actions = _Translations$programme$actions$es._(_root);
	@override late final _Translations$programme$mergeBlocked$es mergeBlocked = _Translations$programme$mergeBlocked$es._(_root);
	@override String get replan => 'Replanificar';
	@override String get replanButton => 'REPLANIFICAR';
	@override late final _Translations$programme$replanDialog$es replanDialog = _Translations$programme$replanDialog$es._(_root);
	@override String get validate => 'CONFIRMAR MI PROGRAMA';
	@override late final _Translations$programme$empty$es empty = _Translations$programme$empty$es._(_root);
	@override late final _Translations$programme$info$es info = _Translations$programme$info$es._(_root);
}

// Path: calendar
class _Translations$calendar$es extends Translations$calendar$fr {
	_Translations$calendar$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Calendario';
	@override String get validate => 'CONFIRMAR FECHAS';
	@override String get departure => 'SALIDA';
	@override String get arrival => 'LLEGADA';
	@override String get chooseDate => 'Elegir una fecha';
	@override String get chooseDateAction => 'ELEGIR UNA FECHA';
	@override String get previousMonth => 'Mes anterior';
	@override String get nextMonth => 'Mes siguiente';
	@override String get dayLabel => 'D{n}';
	@override String get restDayLabel => 'R';
	@override String get adjustStages => 'AJUSTAR LAS ETAPAS';
	@override String get stageSingular => 'Etapa {n}';
	@override String get stagesPlural => 'Etapas {list}';
	@override String get splitStages => 'Separar las etapas';
	@override String get mergeWithNext => 'Agrupar con el día siguiente';
	@override late final _Translations$calendar$weekdays$es weekdays = _Translations$calendar$weekdays$es._(_root);
	@override late final _Translations$calendar$legend$es legend = _Translations$calendar$legend$es._(_root);
	@override late final _Translations$calendar$summary$es summary = _Translations$calendar$summary$es._(_root);
	@override late final _Translations$calendar$noDate$es noDate = _Translations$calendar$noDate$es._(_root);
	@override late final _Translations$calendar$empty$es empty = _Translations$calendar$empty$es._(_root);
}

// Path: nuitees
class _Translations$nuitees$es extends Translations$nuitees$fr {
	_Translations$nuitees$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Pernoctaciones';
	@override String get guideTooltip => 'Guía de pernoctaciones';
	@override String get infoBar => 'Reserva cada noche con antelación en temporada alta';
	@override late final _Translations$nuitees$types$es types = _Translations$nuitees$types$es._(_root);
	@override late final _Translations$nuitees$guide$es guide = _Translations$nuitees$guide$es._(_root);
	@override late final _Translations$nuitees$card$es card = _Translations$nuitees$card$es._(_root);
	@override late final _Translations$nuitees$summary$es summary = _Translations$nuitees$summary$es._(_root);
	@override late final _Translations$nuitees$empty$es empty = _Translations$nuitees$empty$es._(_root);
}

// Path: hub.trekCard
class _Translations$hub$trekCard$es extends Translations$hub$trekCard$fr {
	_Translations$hub$trekCard$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get activeTitle => 'Trek en curso';
	@override String get distanceCovered => 'Distancia recorrida';
	@override String get elevationGain => 'Desnivel de hoy';
	@override String get duration => 'Tiempo de marcha';
	@override String progressLabel({required Object percent}) => '${percent} % del sendero';
	@override String get resume => 'Reanudar la navegación';
	@override String get noTrekTitle => '¿Listo para salir?';
	@override String get noTrekBody => 'Planifica tu itinerario y luego inicia tu trek cuando estés listo.';
	@override String get plan => 'Planificar mi trek';
}

// Path: hub.weather
class _Translations$hub$weather$es extends Translations$hub$weather$fr {
	_Translations$hub$weather$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'El tiempo de hoy';
	@override String get stub => 'El tiempo de tu etapa llega pronto.';
	@override String get unavailable => 'El tiempo no está disponible ahora.';
	@override String get alertStorm => 'Alerta de tormenta';
	@override String tempRange({required Object min, required Object max}) => '${min}° / ${max}°';
}

// Path: hub.sections
class _Translations$hub$sections$es extends Translations$hub$sections$fr {
	_Translations$hub$sections$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get prepare => 'Preparar';
	@override String get hike => 'Caminar';
	@override String get info => 'Información';
	@override String get after => 'Después del trek';
}

// Path: hub.cards
class _Translations$hub$cards$es extends Translations$hub$cards$fr {
	_Translations$hub$cards$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get feasibility => 'Viabilidad';
	@override String get feasibilitySub => 'Evalúa tu nivel';
	@override String get itinerary => 'Itinerario';
	@override String get itinerarySub => 'Tus etapas en detalle';
	@override String get programme => 'Programa';
	@override String get programmeSub => 'Distribuye tus etapas';
	@override String get calendar => 'Calendario';
	@override String get calendarSub => 'Elige las fechas';
	@override String get nuitees => 'Pernoctaciones';
	@override String get nuiteesSub => 'Reserva tus noches';
	@override String get checklist => 'Equipo & Mochila';
	@override String get checklistSub => 'Prepara tu mochila';
	@override String get training => 'Preparación física';
	@override String get trainingSub => 'Tu programa de entrenamiento';
	@override String get offline => 'Descubrir senderos';
	@override String get offlineSub => 'Explora el catálogo';
	@override String get group => 'Mi grupo';
	@override String get groupSub => 'Sigue a tus compañeros';
	@override String get navigation => 'Navegación';
	@override String get navigationSub => 'Mapa y seguimiento GPS';
	@override String get journal => 'Diario';
	@override String get journalSub => 'Tus notas y recuerdos';
	@override String get accommodations => 'Alojamientos';
	@override String get accommodationsSub => 'Dónde dormir cerca';
	@override String get tips => 'Fichas de consejos';
	@override String get tipsSub => 'Nuestros consejos de trek';
	@override String get townGuides => 'Guías de los pueblos';
	@override String get townGuidesSub => 'Info práctica de las etapas';
	@override String get recap => 'Resumen';
	@override String get recapSub => 'Tu aventura resumida';
	@override String get diploma => 'Diploma';
	@override String get diplomaSub => 'Tu certificado final';
}

// Path: hub.fab
class _Translations$hub$fab$es extends Translations$hub$fab$fr {
	_Translations$hub$fab$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get feedback => 'Dar mi opinión';
	@override String get sos => 'SOS';
}

// Path: stage.difficulty
class _Translations$stage$difficulty$es extends Translations$stage$difficulty$fr {
	_Translations$stage$difficulty$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Fácil';
	@override String get moderate => 'Moderado';
	@override String get hard => 'Difícil';
	@override String get expert => 'Experto';
	@override String get extreme => 'Extremo';
}

// Path: stage.waterSources
class _Translations$stage$waterSources$es extends Translations$stage$waterSources$fr {
	_Translations$stage$waterSources$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Puntos de agua';
	@override String get count => '{n} fuente(s)';
	@override String get none => 'No hay ningun punto de agua indicado en esta etapa. Lleve al menos 3 L por persona.';
}

// Path: stage.accommodation
class _Translations$stage$accommodation$es extends Translations$stage$accommodation$fr {
	_Translations$stage$accommodation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Alojamientos';
	@override String get none => 'No hay ningun alojamiento indicado en esta etapa.';
}

// Path: stage.advice
class _Translations$stage$advice$es extends Translations$stage$advice$fr {
	_Translations$stage$advice$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Consejos';
	@override String get waterScarce => 'Pocos puntos de agua: salga con al menos 2,5 L.';
	@override String get waterAmple => 'Rellene las cantimploras en cada punto de agua que encuentre.';
	@override String get hardStage => 'Etapa tecnica: salga temprano para evitar el calor y las tormentas de la tarde.';
	@override String get earlyStart => 'Se recomienda salir antes de las 8 h para aprovechar el fresco matinal.';
	@override String get bigClimb => 'Fuerte desnivel positivo: dosifique el esfuerzo y haga pausas regulares.';
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
	@override String get carrying => 'Mochila & porte';
	@override String get sleeping => 'Descanso';
	@override String get clothing => 'Ropa';
	@override String get cooking => 'Cocina';
	@override String get foodWater => 'Comida & Agua';
	@override String get hygiene => 'Higiene';
	@override String get firstAid => 'Botiquin';
	@override String get electronics => 'Electronica';
	@override String get women => 'Mujer';
	@override String get men => 'Hombre';
	@override String get misc => 'Varios';
	@override String get dog => 'Perro';
}

// Path: checklist.items
class _Translations$checklist$items$es extends Translations$checklist$items$fr {
	_Translations$checklist$items$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get backpack => 'Mochila 35-45L';
	@override String get rainCover => 'Funda de lluvia mochila';
	@override String get dryBags => 'Bolsas estancas (dry bags)';
	@override String get sleepingBag => 'Saco de dormir (0-5C)';
	@override String get sleepingPad => 'Esterilla / colchoneta';
	@override String get sleepingLiner => 'Sabana saco / funda';
	@override String get pillow => 'Almohada hinchable';
	@override String get hikingPants => 'Pantalon de senderismo';
	@override String get rainPants => 'Pantalon de lluvia';
	@override String get shorts => 'Pantalon corto';
	@override String get techTshirt => 'Camiseta tecnica';
	@override String get fleece => 'Forro polar / plumas ligero';
	@override String get rainJacket => 'Chaqueta impermeable Gore-Tex';
	@override String get underwear => 'Ropa interior';
	@override String get hikingSocks => 'Calcetines de senderismo';
	@override String get gaiters => 'Polainas';
	@override String get hat => 'Sombrero / gorra';
	@override String get beanie => 'Gorro';
	@override String get buff => 'Buff / braga de cuello';
	@override String get lightGloves => 'Guantes ligeros';
	@override String get hikingBoots => 'Botas de senderismo (puestas)';
	@override String get campSandals => 'Sandalias de vivac';
	@override String get stove => 'Hornillo (PocketRocket)';
	@override String get gasCanister => 'Cartucho de gas';
	@override String get cookpot => 'Olla / cazuela';
	@override String get cutlery => 'Cubiertos (cuchara, cuchillo)';
	@override String get waterBottle => 'Cantimplora / bolsa 2L';
	@override String get knife => 'Navaja plegable';
	@override String get lighter => 'Mechero';
	@override String get energyBars => 'Barrita energetica';
	@override String get driedFruits => 'Frutos secos';
	@override String get freezeDriedMeal => 'Comida liofilizada';
	@override String get waterPurification => 'Pastillas potabilizadoras';
	@override String get electrolytes => 'Electrolitos';
	@override String get carriedWater => 'Agua transportada (1L = 1000g)';
	@override String get soap => 'Jabon biodegradable';
	@override String get toothbrush => 'Cepillo de dientes';
	@override String get toothpaste => 'Pasta de dientes';
	@override String get microfiberTowel => 'Toalla de microfibra';
	@override String get toiletPaper => 'Papel higienico';
	@override String get trashBag => 'Bolsa de basura';
	@override String get antiChafingCream => 'Crema antirozaduras';
	@override String get earplugs => 'Tapones para oidos';
	@override String get bandages => 'Tiritas surtidas';
	@override String get sterileCompresses => 'Compresas esteriles';
	@override String get elasticBandage => 'Venda elastica';
	@override String get disinfectant => 'Desinfectante (50ml)';
	@override String get painkillers => 'Paracetamol / Ibuprofeno';
	@override String get sunscreen => 'Crema solar SPF50';
	@override String get lipBalm => 'Barra labial SPF30';
	@override String get emergencyBlanket => 'Manta de supervivencia';
	@override String get tickRemover => 'Extractor de garrapatas';
	@override String get whistle => 'Silbato de emergencia';
	@override String get strapping => 'Esparadrapo / strapping';
	@override String get eyeDrops => 'Colirio';
	@override String get antiDiarrheal => 'Antidiarreico';
	@override String get antihistamine => 'Antihistaminico';
	@override String get kneeTape => 'Tape para rodillas';
	@override String get phone => 'Telefono';
	@override String get powerBank => 'Bateria externa 20000mAh';
	@override String get usbCable => 'Cable USB';
	@override String get headlamp => 'Linterna frontal';
	@override String get spareBatteries => 'Pilas de repuesto';
	@override String get periodProtection => 'Proteccion menstrual';
	@override String get sportsBra => 'Sujetador deportivo';
	@override String get intimateWipes => 'Toallitas intimas';
	@override String get peeCloth => 'Pee-cloth';
	@override String get razor => 'Maquinilla de afeitar';
	@override String get techBoxers => 'Boxers tecnicos';
	@override String get hikingPoles => 'Bastones de marcha (llevados)';
	@override String get sunglasses => 'Gafas de sol';
	@override String get trailMap => 'Mapa / guia topo';
	@override String get spareLaces => 'Cordones de repuesto';
	@override String get needleThread => 'Aguja + hilo';
	@override String get ductTape => 'Cinta adhesiva';
	@override String get ziplocBags => 'Bolsas ziploc';
	@override String get cord => 'Cordel';
	@override String get cash => 'Dinero en efectivo';
	@override String get dogBowl => 'Comedero plegable';
	@override String get dogLeash => 'Correa';
	@override String get dogKibble => 'Pienso (racion/dia)';
	@override String get dogBooties => 'Botines de proteccion';
	@override String get dogVaccineBook => 'Cartilla de vacunas';
	@override String get dogPoopBags => 'Bolsas para excrementos';
	@override String get swimsuit => 'Banador';
}

// Path: checklist.weight
class _Translations$checklist$weight$es extends Translations$checklist$weight$fr {
	_Translations$checklist$weight$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Peso de la mochila';
	@override String get total => 'Peso total';
	@override String get bodyWeight => 'Peso corporal:';
	@override String get ratio => 'Ratio mochila / cuerpo';
	@override String get perItem => 'Peso por articulo';
	@override String get edit => 'Editar el peso';
	@override String get grams => 'g';
	@override String get kilograms => 'kg';
	@override String get adviceUltraLight => 'Mochila ultraligera — ideal para el trekking';
	@override String get adviceLight => 'Mochila ultraligera — ideal para el trekking';
	@override String get adviceOk => 'Mochila bien equilibrada';
	@override String get adviceHeavy => 'Correcto pero pesado — considera aligerar';
	@override String get adviceTooHeavy => 'Cuidado rodillas! Aligera la mochila';
	@override String get adviceDanger => 'Riesgo de lesion — aligera ya!';
	@override String get itemWeight => 'Peso del articulo';
	@override String get cancel => 'Cancelar';
	@override String get save => 'Guardar';
	@override String get gaugeUltraLight => 'Ultraligero, perfecto!';
	@override String get gaugeOk => 'Bien, equilibrado';
	@override String get gaugeHeavy => 'Correcto pero pesado';
	@override String get gaugeWarn => 'Cuidado rodillas!';
	@override String get gaugeDanger => 'Riesgo de lesion!';
	@override String get percentOfWeight => '{pct}% del peso corporal';
	@override String get gaugeObjective => 'Objetivo max: < 15% en refugio, < 20% en autonomia';
	@override String get itemsChecked => '{checked} / {total} articulos marcados';
}

// Path: checklist.ui
class _Translations$checklist$ui$es extends Translations$checklist$ui$fr {
	_Translations$checklist$ui$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Equipo & Mochila';
	@override String get requirementRequired => 'Obligatorio';
	@override String get addItem => 'Anadir un articulo';
	@override String get addItemTitle => 'Anadir un articulo';
	@override String get fieldName => 'Nombre';
	@override String get fieldWeightGrams => 'Peso (gramos)';
	@override String get add => 'Anadir';
	@override String get editWeightTitle => 'Editar el peso';
	@override String get editCustomTitle => 'Editar articulo personalizado';
	@override String get modify => 'Editar';
	@override String get delete => 'Eliminar';
	@override String get deleteItemTitle => 'Eliminar este articulo?';
	@override String get deleteItemBody => 'El articulo "{name}" se eliminara definitivamente.';
	@override String get requiredWarnTitle => 'Equipo obligatorio';
	@override String get requiredWarnBody => 'Este equipo es obligatorio por seguridad (inspirado en el reglamento UTMB). Seguro que quieres quitarlo?';
	@override String get keep => 'Mantener';
	@override String get removeAnyway => 'Quitar de todos modos';
	@override String get reduceQuantity => 'Reducir cantidad';
	@override String get increaseQuantity => 'Aumentar cantidad';
	@override String get addToShoppingList => 'Anadir a la lista de la compra';
	@override String get removeFromShoppingList => 'Quitar de la lista';
	@override String get help => 'Ayuda';
	@override String get shoppingListTitle => 'Lista de la compra';
	@override String get shoppingListEmpty => 'Tu lista de la compra esta vacia. Anade articulos con el boton del carrito.';
	@override String get shoppingToBuy => 'Por comprar';
	@override String get shoppingPurchased => 'Ya comprado';
	@override String get share => 'COMPARTIR';
	@override String get infoTitle => 'Equipo & Mochila';
	@override String get infoCheckTitle => 'Marca los articulos';
	@override String get infoCheckBody => 'Marca lo que llevas — el peso se recalcula arriba.';
	@override String get infoRequiredTitle => 'Obligatorios';
	@override String get infoRequiredBody => 'Articulos con candado = reglamento (silbato, linterna, manta de supervivencia).';
	@override String get infoGaugeTitle => 'Indicador de peso';
	@override String get infoGaugeBody => 'Objetivo: mochila < 15% de tu peso. Verde = OK, Naranja = cuidado, Rojo = demasiado pesado.';
	@override String get infoAddTitle => 'Anadir';
	@override String get infoAddBody => 'El boton + al final de cada categoria para tus propios articulos.';
	@override String get infoValidateBody => 'Valida cuando tu mochila este lista — aparecera una marca en el inicio.';
	@override String get infoUnderstood => 'Entendido!';
	@override String get prepTitle => 'Preparacion de la mochila';
	@override String get prepCounter => '{prepared} / {total} articulos preparados';
	@override String get prepAllReady => 'Todo listo! Buen trek';
	@override String get preDepartureTitle => 'Checklist antes de salir';
	@override String get preDepartureCounter => '{checked}/{total} verificados';
	@override String get preDep1 => 'Comprobar el tiempo de los proximos dias';
	@override String get preDep2 => 'Cargar telefono + bateria externa';
	@override String get preDep3 => 'Avisar a un allegado de tu itinerario';
	@override String get preDep4 => 'Comprobar que la mochila este bien cerrada y estanca';
	@override String get preDep5 => 'Llenar las cantimploras (minimo 2L)';
	@override String get preDep6 => 'Aplicar crema solar y antirozaduras';
	@override String get preDep7 => 'Comprobar los cordones y el ajuste de las botas';
	@override String get preDep8 => 'Descargar los mapas offline';
	@override String get bagOk => 'MOCHILA OK — LISTA PARA SALIR';
	@override String get validateBag => 'VALIDAR MI MOCHILA';
	@override String get cancelValidation => 'ANULAR LA VALIDACION';
	@override String get shoppingListButton => 'LISTA DE COMPRA';
	@override String get shareGroup => 'COMPARTIR CON EL GRUPO';
	@override String get exportList => 'EXPORTAR LA LISTA';
	@override String get bagValidTitle => 'Mochila validada';
	@override String get bagValidBody => 'Los {total} articulos obligatorios estan en tu mochila.\n\nPeso total: {weight} kg ({pct}% del peso corporal)\n\nSeguro que tu mochila esta lista?';
	@override String get checkAgain => 'Comprobar de nuevo';
	@override String get yesBagOk => 'Si, mochila OK';
	@override String get bagValidatedSnack => 'Mochila validada!';
	@override String get validationCancelledSnack => 'Validacion anulada — puedes modificar tu equipo.';
	@override String get missingTitle => 'Equipo faltante';
	@override String get missingBody => '{checked}/{total} articulos obligatorios marcados.';
	@override String get missingList => 'Falta:';
	@override String get understood => 'Entendido';
	@override String get validateAnyway => 'Validar de todos modos';
	@override String get bagValidatedMissingSnack => 'Mochila validada (con articulos faltantes)!';
	@override String get shareGroupHint => 'Unete a un grupo para compartir tu checklist.';
}

// Path: weather.source
class _Translations$weather$source$es extends Translations$weather$source$fr {
	_Translations$weather$source$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get api => 'Datos en directo';
	@override String get cache => 'Datos guardados';
	@override String get offline => 'Sin conexión';
	@override String get demo => 'Datos de demostración';
}

// Path: weather.recommendation
class _Translations$weather$recommendation$es extends Translations$weather$recommendation$fr {
	_Translations$weather$recommendation$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get ok => 'Condiciones favorables';
	@override String get watch => 'Precaución recomendada';
	@override String get danger => 'Condiciones desfavorables';
}

// Path: weather.alert
class _Translations$weather$alert$es extends Translations$weather$alert$fr {
	_Translations$weather$alert$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$weather$alert$storm$es storm = _Translations$weather$alert$storm$es._(_root);
	@override late final _Translations$weather$alert$wind$es wind = _Translations$weather$alert$wind$es._(_root);
	@override late final _Translations$weather$alert$rain$es rain = _Translations$weather$alert$rain$es._(_root);
	@override late final _Translations$weather$alert$snow$es snow = _Translations$weather$alert$snow$es._(_root);
	@override late final _Translations$weather$alert$uv$es uv = _Translations$weather$alert$uv$es._(_root);
	@override late final _Translations$weather$alert$fire$es fire = _Translations$weather$alert$fire$es._(_root);
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

// Path: catalog.a11y
class _Translations$catalog$a11y$es extends Translations$catalog$a11y$fr {
	_Translations$catalog$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String enterButton({required Object nom}) => 'Entrar en el sendero ${nom}';
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

// Path: health.field
class _Translations$health$field$es extends Translations$health$field$fr {
	_Translations$health$field$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Grupo sanguíneo';
	@override String get allergies => 'Alergias';
	@override String get treatments => 'Tratamientos en curso';
	@override String get doctor => 'Médico de cabecera';
	@override String get insurance => 'N.º de seguro / mutua';
}

// Path: health.hint
class _Translations$health$hint$es extends Translations$health$hint$fr {
	_Translations$health$hint$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get bloodType => 'Ej.: A+, O-, AB+';
	@override String get allergies => 'Ej.: penicilina, cacahuetes';
	@override String get treatments => 'Ej.: Levothyrox 50 mg/día';
	@override String get doctor => 'Ej.: Dr. García +34 91 xxx xx xx';
	@override String get insurance => 'Ej.: tarjeta sanitaria europea';
}

// Path: health.a11y
class _Translations$health$a11y$es extends Translations$health$a11y$fr {
	_Translations$health$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get form => 'Formulario de información de salud';
	@override String get saveButton => 'Guardar la información de salud';
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

// Path: consent.purposes
class _Translations$consent$purposes$es extends Translations$consent$purposes$fr {
	_Translations$consent$purposes$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get locationNavigation => 'Navegación personal';
	@override String get locationNavigationDesc => 'Usar tu ubicación para el mapa y el seguimiento de tu etapa. Permanece en tu dispositivo.';
	@override String get socialSharing => 'Compartir social';
	@override String get socialSharingDesc => 'Aparecer en las clasificaciones y en el feed de la comunidad, con un seudónimo.';
	@override String get publicReporting => 'Avisos públicos';
	@override String get publicReportingDesc => 'Publicar avisos (agua, peligro, condiciones) visibles para otros senderistas.';
	@override String get healthData => 'Datos de salud';
	@override String get healthDataDesc => 'Leer tu frecuencia cardíaca (banda o app de salud) para enriquecer el seguimiento del esfuerzo.';
}

// Path: consent.a11y
class _Translations$consent$a11y$es extends Translations$consent$a11y$fr {
	_Translations$consent$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String purposeToggle({required Object purpose, required Object state}) => '${purpose}, actualmente ${state}';
	@override String get healthSection => 'Sección de datos de salud, consentimiento reforzado';
	@override String get policyButton => 'Abrir la política de privacidad';
}

// Path: moderation.reasons
class _Translations$moderation$reasons$es extends Translations$moderation$reasons$fr {
	_Translations$moderation$reasons$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get illegal => 'Contenido ilegal';
	@override String get harassment => 'Acoso u odio';
	@override String get spam => 'Spam o publicidad';
	@override String get dangerous => 'Información peligrosa o engañosa';
	@override String get other => 'Otro';
}

// Path: moderation.decisions
class _Translations$moderation$decisions$es extends Translations$moderation$decisions$fr {
	_Translations$moderation$decisions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get keep => 'Contenido mantenido';
	@override String get restrict => 'Contenido restringido';
	@override String get remove => 'Contenido retirado';
}

// Path: moderation.a11y
class _Translations$moderation$a11y$es extends Translations$moderation$a11y$fr {
	_Translations$moderation$a11y$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get reportForm => 'Formulario de denuncia de contenido';
	@override String get reasonSelector => 'Selector del motivo de la denuncia';
	@override String goodFaithToggle({required Object state}) => 'Declaración de buena fe, ${state}';
	@override String get submitReport => 'Enviar denuncia';
	@override String get statementCard => 'Motivación de la decisión de moderación';
	@override String get complaintForm => 'Formulario de impugnación de la decisión';
}

// Path: programme.stats
class _Translations$programme$stats$es extends Translations$programme$stats$fr {
	_Translations$programme$stats$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get distance => 'Distancia';
	@override String get elevation => 'Desnivel+';
	@override String get days => 'Días';
	@override String get stages => 'Etapas';
	@override String get restCount => '{count} descanso';
}

// Path: programme.legend
class _Translations$programme$legend$es extends Translations$programme$legend$fr {
	_Translations$programme$legend$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get easy => 'Fácil';
	@override String get moderate => 'Moderado';
	@override String get hard => 'Difícil';
	@override String get extreme => 'Extremo';
}

// Path: programme.actions
class _Translations$programme$actions$es extends Translations$programme$actions$fr {
	_Translations$programme$actions$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get merge => 'Agrupar';
	@override String get split => 'Separar';
	@override String get rest => 'Descanso';
	@override String get removeRest => 'Eliminar este día de descanso';
}

// Path: programme.mergeBlocked
class _Translations$programme$mergeBlocked$es extends Translations$programme$mergeBlocked$fr {
	_Translations$programme$mergeBlocked$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get noNext => 'No hay día siguiente';
	@override String get rest => 'No se puede agrupar con un día de descanso';
	@override String get tooLong => 'Demasiado largo: {hours}h (máx {max}h/día)';
}

// Path: programme.replanDialog
class _Translations$programme$replanDialog$es extends Translations$programme$replanDialog$fr {
	_Translations$programme$replanDialog$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Replanificar';
	@override String get message => 'La replanificación reiniciará tu programa.\nTus días de descanso se mantendrán en las mismas posiciones.';
	@override String get cancel => 'Cancelar';
	@override String get confirm => 'Replanificar';
}

// Path: programme.empty
class _Translations$programme$empty$es extends Translations$programme$empty$fr {
	_Translations$programme$empty$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura primero tu itinerario';
	@override String get message => 'Elige tu ruta y la duración para generar tu programa.';
	@override String get action => 'CONFIGURAR EL ITINERARIO';
}

// Path: programme.info
class _Translations$programme$info$es extends Translations$programme$info$fr {
	_Translations$programme$info$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Programa';
	@override late final _Translations$programme$info$days$es days = _Translations$programme$info$days$es._(_root);
	@override late final _Translations$programme$info$reorder$es reorder = _Translations$programme$info$reorder$es._(_root);
	@override late final _Translations$programme$info$rest$es rest = _Translations$programme$info$rest$es._(_root);
	@override late final _Translations$programme$info$mergeSplit$es mergeSplit = _Translations$programme$info$mergeSplit$es._(_root);
	@override late final _Translations$programme$info$colors$es colors = _Translations$programme$info$colors$es._(_root);
	@override String get note => 'El perfil altimétrico de abajo muestra el desnivel de cada día.';
	@override String get close => '¡Entendido!';
}

// Path: calendar.weekdays
class _Translations$calendar$weekdays$es extends Translations$calendar$weekdays$fr {
	_Translations$calendar$weekdays$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get mon => 'Lun';
	@override String get tue => 'Mar';
	@override String get wed => 'Mié';
	@override String get thu => 'Jue';
	@override String get fri => 'Vie';
	@override String get sat => 'Sáb';
	@override String get sun => 'Dom';
}

// Path: calendar.legend
class _Translations$calendar$legend$es extends Translations$calendar$legend$fr {
	_Translations$calendar$legend$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get start => 'Salida';
	@override String get walk => 'Marcha';
	@override String get rest => 'Descanso';
	@override String get arrival => 'Llegada';
}

// Path: calendar.summary
class _Translations$calendar$summary$es extends Translations$calendar$summary$fr {
	_Translations$calendar$summary$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get totalDays => 'Días total';
	@override String get walkDays => 'Días marcha';
	@override String get restDays => 'Días descanso';
}

// Path: calendar.noDate
class _Translations$calendar$noDate$es extends Translations$calendar$noDate$fr {
	_Translations$calendar$noDate$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Elige una fecha de salida';
	@override String get message => 'El calendario de tu trek aparecerá automáticamente con los días de marcha y de descanso.';
}

// Path: calendar.empty
class _Translations$calendar$empty$es extends Translations$calendar$empty$fr {
	_Translations$calendar$empty$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura primero tu itinerario';
	@override String get message => 'Elige tu ruta y la duración para poder configurar tus fechas.';
	@override String get action => 'CONFIGURAR EL ITINERARIO';
}

// Path: nuitees.types
class _Translations$nuitees$types$es extends Translations$nuitees$types$fr {
	_Translations$nuitees$types$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get refuge => 'Refugio';
	@override String get gite => 'Albergue';
	@override String get bivouac => 'Vivac';
	@override String get autreHebergement => 'Otro alojamiento';
}

// Path: nuitees.guide
class _Translations$nuitees$guide$es extends Translations$nuitees$guide$fr {
	_Translations$nuitees$guide$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Guía de pernoctaciones';
	@override String get refuge => 'Alojamiento de montaña, se recomienda reservar en temporada alta.';
	@override String get gite => 'Albergue de etapa privado, a menudo con comidas y duchas.';
	@override String get bivouac => 'Acampada en tienda, según la normativa local.';
	@override String get autre => 'Hotel, casa de huéspedes o camping fuera del sendero.';
	@override String get close => 'Entendido';
}

// Path: nuitees.card
class _Translations$nuitees$card$es extends Translations$nuitees$card$fr {
	_Translations$nuitees$card$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get dayLabel => 'D{n}';
	@override String get noPlace => 'Alojamiento';
	@override String get available => '{count} alojamientos disponibles';
	@override String get call => 'Llamar {phone}';
	@override String get lockedHint => 'Desmarca la noche para cambiar el tipo';
}

// Path: nuitees.summary
class _Translations$nuitees$summary$es extends Translations$nuitees$summary$fr {
	_Translations$nuitees$summary$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get remaining => '{count} noche(s) restante(s)';
	@override String get done => '{count} OK';
	@override String get allBooked => 'TODAS LAS NOCHES RESERVADAS';
}

// Path: nuitees.empty
class _Translations$nuitees$empty$es extends Translations$nuitees$empty$fr {
	_Translations$nuitees$empty$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Configura primero tu itinerario';
	@override String get message => 'Elige tu ruta y duración para preparar tus noches.';
	@override String get action => 'CONFIGURAR ITINERARIO';
}

// Path: weather.alert.storm
class _Translations$weather$alert$storm$es extends Translations$weather$alert$storm$fr {
	_Translations$weather$alert$storm$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Tormenta prevista';
	@override String desc({required Object condition}) => '${condition}. Evita las crestas y las zonas expuestas.';
}

// Path: weather.alert.wind
class _Translations$weather$alert$wind$es extends Translations$weather$alert$wind$fr {
	_Translations$weather$alert$wind$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Viento fuerte';
	@override String desc({required Object value}) => 'Rachas de hasta ${value} km/h. Precaución en los pasos expuestos.';
}

// Path: weather.alert.rain
class _Translations$weather$alert$rain$es extends Translations$weather$alert$rain$fr {
	_Translations$weather$alert$rain$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Fuertes precipitaciones';
	@override String desc({required Object value}) => '${value} mm previstos. Riesgo de senderos resbaladizos y torrentes.';
}

// Path: weather.alert.snow
class _Translations$weather$alert$snow$es extends Translations$weather$alert$snow$fr {
	_Translations$weather$alert$snow$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Nieve prevista';
	@override String desc({required Object condition}) => '${condition}. Se necesita equipo adecuado.';
}

// Path: weather.alert.uv
class _Translations$weather$alert$uv$es extends Translations$weather$alert$uv$fr {
	_Translations$weather$alert$uv$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'UV muy alto';
	@override String desc({required Object value}) => 'Índice UV ${value}. Se recomienda máxima protección solar.';
}

// Path: weather.alert.fire
class _Translations$weather$alert$fire$es extends Translations$weather$alert$fire$fr {
	_Translations$weather$alert$fire$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Riesgo de incendio';
	@override String desc({required Object value}) => '${value}°C previstos. Alto riesgo de incendio.';
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

// Path: programme.info.days
class _Translations$programme$info$days$es extends Translations$programme$info$days$fr {
	_Translations$programme$info$days$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Días de trek';
	@override String get body => 'Cada línea = un día. Pulsa para ver el detalle completo.';
}

// Path: programme.info.reorder
class _Translations$programme$info$reorder$es extends Translations$programme$info$reorder$fr {
	_Translations$programme$info$reorder$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Reordenar';
	@override String get body => 'Arrastra el asa de la derecha para cambiar el orden de los días.';
}

// Path: programme.info.rest
class _Translations$programme$info$rest$es extends Translations$programme$info$rest$fr {
	_Translations$programme$info$rest$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Día de descanso';
	@override String get body => 'Inserta un día de recuperación entre dos etapas.';
}

// Path: programme.info.mergeSplit
class _Translations$programme$info$mergeSplit$es extends Translations$programme$info$mergeSplit$fr {
	_Translations$programme$info$mergeSplit$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Agrupar / Separar';
	@override String get body => 'Combina o divide etapas según tu ritmo.';
}

// Path: programme.info.colors
class _Translations$programme$info$colors$es extends Translations$programme$info$colors$fr {
	_Translations$programme$info$colors$es._(TranslationsEs root) : this._root = root, super.internal(root);

	final TranslationsEs _root; // ignore: unused_field

	// Translations
	@override String get title => 'Colores';
	@override String get body => 'Verde = fácil, Naranja = medio, Rojo = difícil (distancia + desnivel).';
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
			'a11y.sos' => 'Llamada de emergencia SOS',
			'a11y.mapLayers' => 'Capas del mapa',
			'nav.accueil' => 'Inicio',
			'nav.map' => 'Mapa',
			'nav.stages' => 'Etapas',
			'nav.planning' => 'Planificación',
			'nav.journal' => 'Diario',
			'nav.more' => 'Más',
			'nav.checklist' => 'Equipo & Mochila',
			'nav.feasibility' => 'Viabilidad',
			'nav.tips' => 'Consejos trek',
			'nav.emergency' => 'Contactos de emergencia',
			'nav.catalog' => 'Catálogo de senderos',
			'nav.profile' => 'Perfil',
			'nav.settings' => 'Ajustes',
			'nav.trailSelection' => 'Cambiar de sendero',
			'branding.tagline' => 'Tu compañero de trekking',
			'branding.subline' => 'Prepara, camina, comparte',
			'hub.greeting' => ({required Object name}) => '¡Hola, ${name}!',
			'hub.greetingFallback' => 'Senderista',
			'hub.infoTooltip' => 'Acerca de este sendero',
			'hub.profileTooltip' => 'Mi perfil',
			'hub.infoSheetBody' => 'Este sendero te acompaña en cada paso: planifica tu itinerario, prepara tu mochila y luego sal con la navegación GPS. Cada función es accesible desde esta pantalla de inicio.',
			'hub.trekCard.activeTitle' => 'Trek en curso',
			'hub.trekCard.distanceCovered' => 'Distancia recorrida',
			'hub.trekCard.elevationGain' => 'Desnivel de hoy',
			'hub.trekCard.duration' => 'Tiempo de marcha',
			'hub.trekCard.progressLabel' => ({required Object percent}) => '${percent} % del sendero',
			'hub.trekCard.resume' => 'Reanudar la navegación',
			'hub.trekCard.noTrekTitle' => '¿Listo para salir?',
			'hub.trekCard.noTrekBody' => 'Planifica tu itinerario y luego inicia tu trek cuando estés listo.',
			'hub.trekCard.plan' => 'Planificar mi trek',
			'hub.weather.title' => 'El tiempo de hoy',
			'hub.weather.stub' => 'El tiempo de tu etapa llega pronto.',
			'hub.weather.unavailable' => 'El tiempo no está disponible ahora.',
			'hub.weather.alertStorm' => 'Alerta de tormenta',
			'hub.weather.tempRange' => ({required Object min, required Object max}) => '${min}° / ${max}°',
			'hub.startCta' => 'Iniciar el trek',
			'hub.sections.prepare' => 'Preparar',
			'hub.sections.hike' => 'Caminar',
			'hub.sections.info' => 'Información',
			'hub.sections.after' => 'Después del trek',
			'hub.cards.feasibility' => 'Viabilidad',
			'hub.cards.feasibilitySub' => 'Evalúa tu nivel',
			'hub.cards.itinerary' => 'Itinerario',
			'hub.cards.itinerarySub' => 'Tus etapas en detalle',
			'hub.cards.programme' => 'Programa',
			'hub.cards.programmeSub' => 'Distribuye tus etapas',
			'hub.cards.calendar' => 'Calendario',
			'hub.cards.calendarSub' => 'Elige las fechas',
			'hub.cards.nuitees' => 'Pernoctaciones',
			'hub.cards.nuiteesSub' => 'Reserva tus noches',
			'hub.cards.checklist' => 'Equipo & Mochila',
			'hub.cards.checklistSub' => 'Prepara tu mochila',
			'hub.cards.training' => 'Preparación física',
			'hub.cards.trainingSub' => 'Tu programa de entrenamiento',
			'hub.cards.offline' => 'Descubrir senderos',
			'hub.cards.offlineSub' => 'Explora el catálogo',
			'hub.cards.group' => 'Mi grupo',
			'hub.cards.groupSub' => 'Sigue a tus compañeros',
			'hub.cards.navigation' => 'Navegación',
			'hub.cards.navigationSub' => 'Mapa y seguimiento GPS',
			'hub.cards.journal' => 'Diario',
			'hub.cards.journalSub' => 'Tus notas y recuerdos',
			'hub.cards.accommodations' => 'Alojamientos',
			'hub.cards.accommodationsSub' => 'Dónde dormir cerca',
			'hub.cards.tips' => 'Fichas de consejos',
			'hub.cards.tipsSub' => 'Nuestros consejos de trek',
			'hub.cards.townGuides' => 'Guías de los pueblos',
			'hub.cards.townGuidesSub' => 'Info práctica de las etapas',
			'hub.cards.recap' => 'Resumen',
			'hub.cards.recapSub' => 'Tu aventura resumida',
			'hub.cards.diploma' => 'Diploma',
			'hub.cards.diplomaSub' => 'Tu certificado final',
			'hub.fab.feedback' => 'Dar mi opinión',
			'hub.fab.sos' => 'SOS',
			'map.title' => 'Mapa del sendero',
			'map.loading' => 'Cargando el recorrido...',
			'map.noTrack' => 'Ningún recorrido disponible',
			'map.viewMap' => 'Ver el mapa',
			'map.layers' => 'Capas',
			'map.layersTitle' => 'Capas del mapa',
			'map.layersSubtitle' => 'Elige que mostrar en el mapa',
			'map.stageRemaining' => ({required Object km}) => '${km} km restantes',
			'map.offTrackChip' => 'Fuera de ruta',
			'stage.distance' => 'Distancia',
			'stage.elevation' => 'Desnivel',
			'stage.elevationGain' => 'Desnivel positivo',
			'stage.elevationLoss' => 'Desnivel negativo',
			'stage.duration' => 'Duración estimada',
			'stage.description' => 'Descripción',
			'stage.coordinates' => 'Coordenadas',
			'stage.pois' => 'Puntos de interés',
			'stage.difficulty.easy' => 'Fácil',
			'stage.difficulty.moderate' => 'Moderado',
			'stage.difficulty.hard' => 'Difícil',
			'stage.difficulty.expert' => 'Experto',
			'stage.difficulty.extreme' => 'Extremo',
			'stage.remaining' => '{distance} km restantes',
			'stage.arrived' => 'Has llegado!',
			'stage.altitudeProfile' => 'Perfil altimetrico',
			'stage.statistics' => 'Estadisticas',
			'stage.loading' => 'Cargando...',
			'stage.loadingList' => 'Cargando las etapas...',
			'stage.dPlus' => 'D+',
			'stage.dMinus' => 'D-',
			'stage.difficultyLabel' => 'Dificultad',
			'stage.waterSources.title' => 'Puntos de agua',
			'stage.waterSources.count' => '{n} fuente(s)',
			'stage.waterSources.none' => 'No hay ningun punto de agua indicado en esta etapa. Lleve al menos 3 L por persona.',
			'stage.accommodation.title' => 'Alojamientos',
			'stage.accommodation.none' => 'No hay ningun alojamiento indicado en esta etapa.',
			'stage.advice.title' => 'Consejos',
			'stage.advice.waterScarce' => 'Pocos puntos de agua: salga con al menos 2,5 L.',
			'stage.advice.waterAmple' => 'Rellene las cantimploras en cada punto de agua que encuentre.',
			'stage.advice.hardStage' => 'Etapa tecnica: salga temprano para evitar el calor y las tormentas de la tarde.',
			'stage.advice.earlyStart' => 'Se recomienda salir antes de las 8 h para aprovechar el fresco matinal.',
			'stage.advice.bigClimb' => 'Fuerte desnivel positivo: dosifique el esfuerzo y haga pausas regulares.',
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
			'poi.filter' => 'Filtrar puntos de interés',
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
			'navAlert.offTrackBanner' => ({required Object meters}) => 'Te estas alejando del sendero — ${meters} m. Comprueba tu posicion.',
			'navAlert.offTrackNotifTitle' => 'Estas saliendo del sendero',
			'navAlert.offTrackNotifBody' => ({required Object meters}) => 'Te estas alejando del sendero (${meters} m). Comprueba tu posicion.',
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
			'itinerary.title' => 'Itinerario',
			'itinerary.subtitle' => 'Tus etapas, dia a dia',
			'itinerary.empty' => 'Ninguna etapa disponible',
			'itinerary.emptyHint' => 'Los datos del sendero no estan cargados.',
			'itinerary.loading' => 'Cargando itinerario...',
			'itinerary.error' => 'No se puede cargar el itinerario',
			'itinerary.day' => 'Dia',
			'itinerary.stage' => 'Etapa',
			'itinerary.stages' => 'Etapas',
			'itinerary.totalDistance' => 'Distancia',
			'itinerary.totalElevation' => 'D+',
			'itinerary.restDay' => 'Dia de descanso',
			'itinerary.viewStage' => 'Ver etapa',
			'itinerary.openMap' => 'Ver en el mapa',
			'itinerary.stageCount' => '{count} etapas',
			'tracking.start' => 'Iniciar',
			'tracking.pause' => 'Pausa',
			'tracking.resume' => 'Reanudar',
			'tracking.stop' => 'Detener',
			'tracking.distance' => 'Distancia',
			'tracking.elevation' => 'Desnivel',
			'tracking.speed' => 'Velocidad',
			'tracking.time' => 'Tiempo',
			'tracking.confirmStop' => 'Detener el seguimiento?',
			'tracking.dPlus' => 'D+',
			'tracking.stopSaveProgress' => 'Tu progreso se guardara.',
			'tracking.cancel' => 'Cancelar',
			'tracking.stopButton' => 'Detener',
			'checklist.title' => 'Equipo & Mochila',
			'checklist.subtitle' => 'Prepara tu mochila',
			'checklist.progress' => '{checked}/{total} preparados',
			'checklist.complete' => 'Lista completa!',
			'checklist.reset' => 'Reiniciar',
			'checklist.resetConfirm' => 'Reiniciar la lista?',
			'checklist.resetDescription' => 'Todos los elementos serán desmarcados.',
			'checklist.cancel' => 'Cancelar',
			'checklist.confirm' => 'Confirmar',
			'checklist.categories.carrying' => 'Mochila & porte',
			'checklist.categories.sleeping' => 'Descanso',
			'checklist.categories.clothing' => 'Ropa',
			'checklist.categories.cooking' => 'Cocina',
			'checklist.categories.foodWater' => 'Comida & Agua',
			'checklist.categories.hygiene' => 'Higiene',
			'checklist.categories.firstAid' => 'Botiquin',
			'checklist.categories.electronics' => 'Electronica',
			'checklist.categories.women' => 'Mujer',
			'checklist.categories.men' => 'Hombre',
			'checklist.categories.misc' => 'Varios',
			'checklist.categories.dog' => 'Perro',
			'checklist.items.backpack' => 'Mochila 35-45L',
			'checklist.items.rainCover' => 'Funda de lluvia mochila',
			'checklist.items.dryBags' => 'Bolsas estancas (dry bags)',
			'checklist.items.sleepingBag' => 'Saco de dormir (0-5C)',
			'checklist.items.sleepingPad' => 'Esterilla / colchoneta',
			'checklist.items.sleepingLiner' => 'Sabana saco / funda',
			'checklist.items.pillow' => 'Almohada hinchable',
			'checklist.items.hikingPants' => 'Pantalon de senderismo',
			'checklist.items.rainPants' => 'Pantalon de lluvia',
			'checklist.items.shorts' => 'Pantalon corto',
			'checklist.items.techTshirt' => 'Camiseta tecnica',
			'checklist.items.fleece' => 'Forro polar / plumas ligero',
			'checklist.items.rainJacket' => 'Chaqueta impermeable Gore-Tex',
			'checklist.items.underwear' => 'Ropa interior',
			'checklist.items.hikingSocks' => 'Calcetines de senderismo',
			'checklist.items.gaiters' => 'Polainas',
			'checklist.items.hat' => 'Sombrero / gorra',
			'checklist.items.beanie' => 'Gorro',
			'checklist.items.buff' => 'Buff / braga de cuello',
			'checklist.items.lightGloves' => 'Guantes ligeros',
			'checklist.items.hikingBoots' => 'Botas de senderismo (puestas)',
			'checklist.items.campSandals' => 'Sandalias de vivac',
			'checklist.items.stove' => 'Hornillo (PocketRocket)',
			'checklist.items.gasCanister' => 'Cartucho de gas',
			'checklist.items.cookpot' => 'Olla / cazuela',
			'checklist.items.cutlery' => 'Cubiertos (cuchara, cuchillo)',
			'checklist.items.waterBottle' => 'Cantimplora / bolsa 2L',
			'checklist.items.knife' => 'Navaja plegable',
			'checklist.items.lighter' => 'Mechero',
			'checklist.items.energyBars' => 'Barrita energetica',
			'checklist.items.driedFruits' => 'Frutos secos',
			'checklist.items.freezeDriedMeal' => 'Comida liofilizada',
			'checklist.items.waterPurification' => 'Pastillas potabilizadoras',
			'checklist.items.electrolytes' => 'Electrolitos',
			'checklist.items.carriedWater' => 'Agua transportada (1L = 1000g)',
			'checklist.items.soap' => 'Jabon biodegradable',
			'checklist.items.toothbrush' => 'Cepillo de dientes',
			'checklist.items.toothpaste' => 'Pasta de dientes',
			'checklist.items.microfiberTowel' => 'Toalla de microfibra',
			'checklist.items.toiletPaper' => 'Papel higienico',
			'checklist.items.trashBag' => 'Bolsa de basura',
			'checklist.items.antiChafingCream' => 'Crema antirozaduras',
			'checklist.items.earplugs' => 'Tapones para oidos',
			'checklist.items.bandages' => 'Tiritas surtidas',
			'checklist.items.sterileCompresses' => 'Compresas esteriles',
			'checklist.items.elasticBandage' => 'Venda elastica',
			'checklist.items.disinfectant' => 'Desinfectante (50ml)',
			'checklist.items.painkillers' => 'Paracetamol / Ibuprofeno',
			'checklist.items.sunscreen' => 'Crema solar SPF50',
			'checklist.items.lipBalm' => 'Barra labial SPF30',
			'checklist.items.emergencyBlanket' => 'Manta de supervivencia',
			'checklist.items.tickRemover' => 'Extractor de garrapatas',
			'checklist.items.whistle' => 'Silbato de emergencia',
			'checklist.items.strapping' => 'Esparadrapo / strapping',
			'checklist.items.eyeDrops' => 'Colirio',
			'checklist.items.antiDiarrheal' => 'Antidiarreico',
			'checklist.items.antihistamine' => 'Antihistaminico',
			'checklist.items.kneeTape' => 'Tape para rodillas',
			'checklist.items.phone' => 'Telefono',
			'checklist.items.powerBank' => 'Bateria externa 20000mAh',
			'checklist.items.usbCable' => 'Cable USB',
			'checklist.items.headlamp' => 'Linterna frontal',
			'checklist.items.spareBatteries' => 'Pilas de repuesto',
			'checklist.items.periodProtection' => 'Proteccion menstrual',
			'checklist.items.sportsBra' => 'Sujetador deportivo',
			'checklist.items.intimateWipes' => 'Toallitas intimas',
			'checklist.items.peeCloth' => 'Pee-cloth',
			'checklist.items.razor' => 'Maquinilla de afeitar',
			'checklist.items.techBoxers' => 'Boxers tecnicos',
			'checklist.items.hikingPoles' => 'Bastones de marcha (llevados)',
			'checklist.items.sunglasses' => 'Gafas de sol',
			'checklist.items.trailMap' => 'Mapa / guia topo',
			'checklist.items.spareLaces' => 'Cordones de repuesto',
			'checklist.items.needleThread' => 'Aguja + hilo',
			'checklist.items.ductTape' => 'Cinta adhesiva',
			'checklist.items.ziplocBags' => 'Bolsas ziploc',
			'checklist.items.cord' => 'Cordel',
			'checklist.items.cash' => 'Dinero en efectivo',
			'checklist.items.dogBowl' => 'Comedero plegable',
			'checklist.items.dogLeash' => 'Correa',
			'checklist.items.dogKibble' => 'Pienso (racion/dia)',
			'checklist.items.dogBooties' => 'Botines de proteccion',
			'checklist.items.dogVaccineBook' => 'Cartilla de vacunas',
			'checklist.items.dogPoopBags' => 'Bolsas para excrementos',
			'checklist.items.swimsuit' => 'Banador',
			'checklist.essential' => 'Esencial',
			'checklist.weight.title' => 'Peso de la mochila',
			'checklist.weight.total' => 'Peso total',
			'checklist.weight.bodyWeight' => 'Peso corporal:',
			'checklist.weight.ratio' => 'Ratio mochila / cuerpo',
			'checklist.weight.perItem' => 'Peso por articulo',
			'checklist.weight.edit' => 'Editar el peso',
			'checklist.weight.grams' => 'g',
			'checklist.weight.kilograms' => 'kg',
			'checklist.weight.adviceUltraLight' => 'Mochila ultraligera — ideal para el trekking',
			'checklist.weight.adviceLight' => 'Mochila ultraligera — ideal para el trekking',
			'checklist.weight.adviceOk' => 'Mochila bien equilibrada',
			'checklist.weight.adviceHeavy' => 'Correcto pero pesado — considera aligerar',
			'checklist.weight.adviceTooHeavy' => 'Cuidado rodillas! Aligera la mochila',
			'checklist.weight.adviceDanger' => 'Riesgo de lesion — aligera ya!',
			'checklist.weight.itemWeight' => 'Peso del articulo',
			'checklist.weight.cancel' => 'Cancelar',
			'checklist.weight.save' => 'Guardar',
			'checklist.weight.gaugeUltraLight' => 'Ultraligero, perfecto!',
			'checklist.weight.gaugeOk' => 'Bien, equilibrado',
			'checklist.weight.gaugeHeavy' => 'Correcto pero pesado',
			'checklist.weight.gaugeWarn' => 'Cuidado rodillas!',
			'checklist.weight.gaugeDanger' => 'Riesgo de lesion!',
			'checklist.weight.percentOfWeight' => '{pct}% del peso corporal',
			'checklist.weight.gaugeObjective' => 'Objetivo max: < 15% en refugio, < 20% en autonomia',
			'checklist.weight.itemsChecked' => '{checked} / {total} articulos marcados',
			'checklist.ui.title' => 'Equipo & Mochila',
			'checklist.ui.requirementRequired' => 'Obligatorio',
			'checklist.ui.addItem' => 'Anadir un articulo',
			'checklist.ui.addItemTitle' => 'Anadir un articulo',
			'checklist.ui.fieldName' => 'Nombre',
			'checklist.ui.fieldWeightGrams' => 'Peso (gramos)',
			'checklist.ui.add' => 'Anadir',
			'checklist.ui.editWeightTitle' => 'Editar el peso',
			'checklist.ui.editCustomTitle' => 'Editar articulo personalizado',
			'checklist.ui.modify' => 'Editar',
			'checklist.ui.delete' => 'Eliminar',
			'checklist.ui.deleteItemTitle' => 'Eliminar este articulo?',
			'checklist.ui.deleteItemBody' => 'El articulo "{name}" se eliminara definitivamente.',
			'checklist.ui.requiredWarnTitle' => 'Equipo obligatorio',
			'checklist.ui.requiredWarnBody' => 'Este equipo es obligatorio por seguridad (inspirado en el reglamento UTMB). Seguro que quieres quitarlo?',
			'checklist.ui.keep' => 'Mantener',
			'checklist.ui.removeAnyway' => 'Quitar de todos modos',
			'checklist.ui.reduceQuantity' => 'Reducir cantidad',
			'checklist.ui.increaseQuantity' => 'Aumentar cantidad',
			'checklist.ui.addToShoppingList' => 'Anadir a la lista de la compra',
			'checklist.ui.removeFromShoppingList' => 'Quitar de la lista',
			'checklist.ui.help' => 'Ayuda',
			'checklist.ui.shoppingListTitle' => 'Lista de la compra',
			'checklist.ui.shoppingListEmpty' => 'Tu lista de la compra esta vacia. Anade articulos con el boton del carrito.',
			'checklist.ui.shoppingToBuy' => 'Por comprar',
			'checklist.ui.shoppingPurchased' => 'Ya comprado',
			'checklist.ui.share' => 'COMPARTIR',
			'checklist.ui.infoTitle' => 'Equipo & Mochila',
			'checklist.ui.infoCheckTitle' => 'Marca los articulos',
			'checklist.ui.infoCheckBody' => 'Marca lo que llevas — el peso se recalcula arriba.',
			'checklist.ui.infoRequiredTitle' => 'Obligatorios',
			'checklist.ui.infoRequiredBody' => 'Articulos con candado = reglamento (silbato, linterna, manta de supervivencia).',
			'checklist.ui.infoGaugeTitle' => 'Indicador de peso',
			'checklist.ui.infoGaugeBody' => 'Objetivo: mochila < 15% de tu peso. Verde = OK, Naranja = cuidado, Rojo = demasiado pesado.',
			'checklist.ui.infoAddTitle' => 'Anadir',
			'checklist.ui.infoAddBody' => 'El boton + al final de cada categoria para tus propios articulos.',
			'checklist.ui.infoValidateBody' => 'Valida cuando tu mochila este lista — aparecera una marca en el inicio.',
			'checklist.ui.infoUnderstood' => 'Entendido!',
			'checklist.ui.prepTitle' => 'Preparacion de la mochila',
			'checklist.ui.prepCounter' => '{prepared} / {total} articulos preparados',
			'checklist.ui.prepAllReady' => 'Todo listo! Buen trek',
			'checklist.ui.preDepartureTitle' => 'Checklist antes de salir',
			'checklist.ui.preDepartureCounter' => '{checked}/{total} verificados',
			'checklist.ui.preDep1' => 'Comprobar el tiempo de los proximos dias',
			'checklist.ui.preDep2' => 'Cargar telefono + bateria externa',
			'checklist.ui.preDep3' => 'Avisar a un allegado de tu itinerario',
			'checklist.ui.preDep4' => 'Comprobar que la mochila este bien cerrada y estanca',
			'checklist.ui.preDep5' => 'Llenar las cantimploras (minimo 2L)',
			'checklist.ui.preDep6' => 'Aplicar crema solar y antirozaduras',
			'checklist.ui.preDep7' => 'Comprobar los cordones y el ajuste de las botas',
			'checklist.ui.preDep8' => 'Descargar los mapas offline',
			'checklist.ui.bagOk' => 'MOCHILA OK — LISTA PARA SALIR',
			'checklist.ui.validateBag' => 'VALIDAR MI MOCHILA',
			'checklist.ui.cancelValidation' => 'ANULAR LA VALIDACION',
			'checklist.ui.shoppingListButton' => 'LISTA DE COMPRA',
			'checklist.ui.shareGroup' => 'COMPARTIR CON EL GRUPO',
			'checklist.ui.exportList' => 'EXPORTAR LA LISTA',
			'checklist.ui.bagValidTitle' => 'Mochila validada',
			'checklist.ui.bagValidBody' => 'Los {total} articulos obligatorios estan en tu mochila.\n\nPeso total: {weight} kg ({pct}% del peso corporal)\n\nSeguro que tu mochila esta lista?',
			'checklist.ui.checkAgain' => 'Comprobar de nuevo',
			'checklist.ui.yesBagOk' => 'Si, mochila OK',
			'checklist.ui.bagValidatedSnack' => 'Mochila validada!',
			'checklist.ui.validationCancelledSnack' => 'Validacion anulada — puedes modificar tu equipo.',
			'checklist.ui.missingTitle' => 'Equipo faltante',
			'checklist.ui.missingBody' => '{checked}/{total} articulos obligatorios marcados.',
			'checklist.ui.missingList' => 'Falta:',
			'checklist.ui.understood' => 'Entendido',
			'checklist.ui.validateAnyway' => 'Validar de todos modos',
			'checklist.ui.bagValidatedMissingSnack' => 'Mochila validada (con articulos faltantes)!',
			'checklist.ui.shareGroupHint' => 'Unete a un grupo para compartir tu checklist.',
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
			'weather.today' => 'Hoy',
			'weather.tomorrow' => 'Mañana',
			'weather.dayPlus2' => 'Pasado mañana',
			'weather.allStages' => 'Todas las etapas',
			'weather.noForecast' => 'No hay previsión disponible.',
			'weather.stageLabel' => ({required Object number}) => 'Etapa ${number}',
			'weather.stormAlertsTitle' => 'Alertas de tormenta',
			'weather.stormAlertsToggleOn' => 'Alertas de tormenta activadas',
			'weather.stormAlertsToggleOff' => 'Alertas de tormenta desactivadas',
			'weather.lastUpdate' => ({required Object date}) => 'Actualizado ${date}',
			'weather.guideTitle' => 'Entender la meteorología',
			'weather.guideBody' => 'Las previsiones cubren 7 días para cada etapa. Vigila las alertas de tormenta y viento: en la montaña el tiempo cambia rápido. Sin red se muestran los últimos datos guardados.',
			'weather.source.api' => 'Datos en directo',
			'weather.source.cache' => 'Datos guardados',
			'weather.source.offline' => 'Sin conexión',
			'weather.source.demo' => 'Datos de demostración',
			'weather.recommendation.ok' => 'Condiciones favorables',
			'weather.recommendation.watch' => 'Precaución recomendada',
			'weather.recommendation.danger' => 'Condiciones desfavorables',
			'weather.alert.storm.title' => 'Tormenta prevista',
			'weather.alert.storm.desc' => ({required Object condition}) => '${condition}. Evita las crestas y las zonas expuestas.',
			'weather.alert.wind.title' => 'Viento fuerte',
			'weather.alert.wind.desc' => ({required Object value}) => 'Rachas de hasta ${value} km/h. Precaución en los pasos expuestos.',
			'weather.alert.rain.title' => 'Fuertes precipitaciones',
			'weather.alert.rain.desc' => ({required Object value}) => '${value} mm previstos. Riesgo de senderos resbaladizos y torrentes.',
			'weather.alert.snow.title' => 'Nieve prevista',
			'weather.alert.snow.desc' => ({required Object condition}) => '${condition}. Se necesita equipo adecuado.',
			'weather.alert.uv.title' => 'UV muy alto',
			'weather.alert.uv.desc' => ({required Object value}) => 'Índice UV ${value}. Se recomienda máxima protección solar.',
			'weather.alert.fire.title' => 'Riesgo de incendio',
			'weather.alert.fire.desc' => ({required Object value}) => '${value}°C previstos. Alto riesgo de incendio.',
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
			'diploma.lockedTitle' => 'Diploma bloqueado',
			'diploma.lockedMessage' => 'Completa toda tu ruta para desbloquear tu diploma de finisher.',
			'diploma.labelIntegral' => 'Ruta integral',
			'diploma.labelPartial' => 'Ruta parcial',
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
			_ => null,
		} ?? switch (path) {
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
			'settings.offTrackAlerts' => 'Alerta fuera del sendero',
			'settings.offTrackAlertsDesc' => 'Notificación + vibración si sales del sendero',
			'settings.version' => 'Versión',
			'settings.versionLabel' => 'Versión de la aplicación',
			'appearance.title' => 'Apariencia',
			'appearance.subtitle' => 'Elige el aspecto de la aplicación',
			'appearance.skinSentierVivant' => 'Sendero Vivo',
			'appearance.skinSentierVivantDesc' => 'Moderno y colorido, el color del sendero como protagonista',
			'appearance.skinTopographique' => 'Topográfico',
			'appearance.skinTopographiqueDesc' => 'Estilo mapa topográfico, datos en primer plano',
			'appearance.skinGrandAir' => 'Aire Libre',
			'appearance.skinGrandAirDesc' => 'Fotos a pantalla completa, ambiente de diario de aventura',
			'appearance.unavailableOnTrail' => 'No disponible en este sendero',
			'appearance.changeSkin' => 'Cambiar aspecto',
			'appearance.selected' => 'Seleccionado',
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
			'auth.anonymous' => 'Senderista sin cuenta',
			'auth.connectedVia' => 'Conectado vía',
			'auth.signInGoogle' => 'Iniciar sesión con Google',
			'auth.signInGoogleDesc' => 'Para guardar tu progreso',
			'auth.signOut' => 'Cerrar sesión',
			'auth.signOutDesc' => 'Volver al modo sin cuenta',
			'auth.signOutConfirm' => '¿Cerrar sesión?',
			'auth.signOutMessage' => 'Volverás al modo sin cuenta. Tus datos locales se conservan.',
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
			'catalog.title' => 'Catálogo de senderos',
			'catalog.enter' => 'Entrar',
			'catalog.mustDownload' => 'Descarga este sendero para explorarlo.',
			'catalog.emptyTitle' => 'Ningún sendero disponible',
			'catalog.emptySubtitle' => 'Aún no hay ningún sendero en el catálogo.',
			'catalog.a11y.enterButton' => ({required Object nom}) => 'Entrar en el sendero ${nom}',
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
			'guides.title' => 'Guías de los pueblos',
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
			'health.title' => 'Información de salud',
			'health.privacyBanner' => 'Estos datos permanecen en tu teléfono. Nunca se envían por internet.',
			'health.field.bloodType' => 'Grupo sanguíneo',
			'health.field.allergies' => 'Alergias',
			'health.field.treatments' => 'Tratamientos en curso',
			'health.field.doctor' => 'Médico de cabecera',
			'health.field.insurance' => 'N.º de seguro / mutua',
			'health.hint.bloodType' => 'Ej.: A+, O-, AB+',
			'health.hint.allergies' => 'Ej.: penicilina, cacahuetes',
			'health.hint.treatments' => 'Ej.: Levothyrox 50 mg/día',
			'health.hint.doctor' => 'Ej.: Dr. García +34 91 xxx xx xx',
			'health.hint.insurance' => 'Ej.: tarjeta sanitaria europea',
			'health.save' => 'Guardar',
			'health.saving' => 'Guardando…',
			'health.saved' => 'Información guardada',
			'health.emergencyHint' => 'En caso de emergencia, muestra esta pantalla a los servicios de rescate.',
			'health.entryTitle' => 'Mi información de salud',
			'health.entrySubtitle' => 'Para mostrar a los servicios de rescate (permanece en el teléfono)',
			'health.a11y.form' => 'Formulario de información de salud',
			'health.a11y.saveButton' => 'Guardar la información de salud',
			'trailSelection.title' => 'Cambiar de sendero',
			'trailSelection.subtitle' => 'Elige el sendero a explorar. Toda la app (mapa, etapas, puntos de interes, packs, guias) sigue tu seleccion.',
			'trailSelection.current' => 'Sendero activo',
			'trailSelection.select' => 'Elegir este sendero',
			'trailSelection.selected' => 'Sendero seleccionado',
			'trailSelection.stagesDistance' => ({required Object stages, required Object km}) => '${stages} etapas - ${km} km',
			'trailSelection.a11y.trailCard' => ({required Object nom, required Object region}) => 'Sendero ${nom}, ${region}',
			'trailSelection.a11y.currentBadge' => 'Sendero actualmente activo',
			'trailSelection.a11y.selectButton' => ({required Object nom}) => 'Activar el sendero ${nom}',
			'consent.onboardingTitle' => 'Tu privacidad, tu elección',
			'consent.onboardingIntro' => 'Nada está activado por defecto. Elige, finalidad por finalidad, lo que autorizas. Podrás cambiarlo todo en cualquier momento en los ajustes.',
			'consent.settingsTitle' => 'Privacidad y consentimiento',
			'consent.settingsIntro' => 'Gestiona aquí cada permiso. Puedes retirar un consentimiento en cualquier momento, sin afectar al resto.',
			'consent.settingsEntry' => 'Privacidad y consentimiento',
			'consent.settingsEntryDesc' => 'Gestionar mis permisos (ubicación, compartir, salud)',
			'consent.purposes.locationNavigation' => 'Navegación personal',
			'consent.purposes.locationNavigationDesc' => 'Usar tu ubicación para el mapa y el seguimiento de tu etapa. Permanece en tu dispositivo.',
			'consent.purposes.socialSharing' => 'Compartir social',
			'consent.purposes.socialSharingDesc' => 'Aparecer en las clasificaciones y en el feed de la comunidad, con un seudónimo.',
			'consent.purposes.publicReporting' => 'Avisos públicos',
			'consent.purposes.publicReportingDesc' => 'Publicar avisos (agua, peligro, condiciones) visibles para otros senderistas.',
			'consent.purposes.healthData' => 'Datos de salud',
			'consent.purposes.healthDataDesc' => 'Leer tu frecuencia cardíaca (banda o app de salud) para enriquecer el seguimiento del esfuerzo.',
			'consent.healthBadge' => 'Dato sensible',
			'consent.healthWarning' => 'La frecuencia cardíaca es un dato de salud (artículo 9 del RGPD). Este consentimiento se solicita por separado y nunca se agrupa con los demás. Tus datos de salud no se envían a nuestros servidores.',
			'consent.granted' => 'Autorizado',
			'consent.denied' => 'No autorizado',
			'consent.grant' => 'Autorizar',
			'consent.revoke' => 'Retirar',
			'consent.decidedOn' => ({required Object date}) => 'Elegido el ${date}',
			'consent.notDecided' => 'A la espera de tu elección',
			'consent.acceptSelected' => 'Confirmar mis elecciones',
			'consent.declineAll' => 'Rechazar todo',
			'consent.continueLabel' => 'Continuar',
			'consent.privacyPolicyLink' => 'Leer la política de privacidad',
			'consent.reviewNeeded' => 'Nuestra política ha cambiado: revisa tus elecciones.',
			'consent.a11y.purposeToggle' => ({required Object purpose, required Object state}) => '${purpose}, actualmente ${state}',
			'consent.a11y.healthSection' => 'Sección de datos de salud, consentimiento reforzado',
			'consent.a11y.policyButton' => 'Abrir la política de privacidad',
			'moderation.reportTitle' => 'Denunciar este contenido',
			'moderation.reportIntro' => 'Ayúdanos a mantener una comunidad sana. Indica por qué este contenido te parece ilícito. Tu denuncia será examinada por un moderador.',
			'moderation.reasonLabel' => 'Motivo de la denuncia',
			'moderation.reasons.illegal' => 'Contenido ilegal',
			'moderation.reasons.harassment' => 'Acoso u odio',
			'moderation.reasons.spam' => 'Spam o publicidad',
			'moderation.reasons.dangerous' => 'Información peligrosa o engañosa',
			'moderation.reasons.other' => 'Otro',
			'moderation.detailsLabel' => 'Añade detalles (opcional)',
			'moderation.detailsHint' => 'Añade un comentario para ayudar al moderador.',
			'moderation.contactLabel' => 'Tu dirección de correo electrónico',
			'moderation.contactHint' => 'Para mantenerte informado sobre la gestión (artículo 16).',
			'moderation.goodFaithLabel' => 'Declaro de buena fe que esta información es exacta.',
			'moderation.submit' => 'Enviar denuncia',
			'moderation.submitting' => 'Enviando…',
			'moderation.sent' => 'Denuncia enviada. Gracias, un moderador la examinará.',
			'moderation.errorRequired' => 'Completa el motivo, tu correo y la declaración de buena fe.',
			'moderation.errorGeneric' => 'No se pudo enviar la denuncia. Inténtalo de nuevo.',
			'moderation.cancel' => 'Cancelar',
			'moderation.reasonsTitle' => '¿Por qué se ha restringido este contenido?',
			'moderation.reasonsIntro' => 'De conformidad con el artículo 17, aquí está el motivo de la decisión de moderación relativa a tu contenido.',
			'moderation.decisionLabel' => 'Decisión',
			'moderation.decisions.keep' => 'Contenido mantenido',
			'moderation.decisions.restrict' => 'Contenido restringido',
			'moderation.decisions.remove' => 'Contenido retirado',
			'moderation.noStatement' => 'No se ha aplicado ninguna restricción a tu contenido.',
			'moderation.complaintAction' => 'Impugnar esta decisión',
			'moderation.complaintTitle' => 'Impugnar una decisión',
			'moderation.complaintIntro' => 'Puedes impugnar una decisión de moderación. Explica por qué consideras la decisión injustificada (artículo 20).',
			'moderation.complaintExposeLabel' => 'Tu impugnación',
			'moderation.complaintExposeHint' => 'Describe los motivos de tu impugnación.',
			'moderation.complaintSubmit' => 'Enviar impugnación',
			'moderation.complaintSent' => 'Impugnación registrada. Será examinada.',
			'moderation.complaintEmpty' => 'Explica tu impugnación.',
			'moderation.a11y.reportForm' => 'Formulario de denuncia de contenido',
			'moderation.a11y.reasonSelector' => 'Selector del motivo de la denuncia',
			'moderation.a11y.goodFaithToggle' => ({required Object state}) => 'Declaración de buena fe, ${state}',
			'moderation.a11y.submitReport' => 'Enviar denuncia',
			'moderation.a11y.statementCard' => 'Motivación de la decisión de moderación',
			'moderation.a11y.complaintForm' => 'Formulario de impugnación de la decisión',
			'bootstrap.loading' => 'Preparando tu excursión…',
			_ => null,
		} ?? switch (path) {
			'recap.title' => 'Mi aventura',
			'recap.lockedTitle' => 'Disponible al final de la ruta',
			'recap.lockedMessage' => 'Termina o abandona tu ruta para ver el resumen de tu aventura.',
			'recap.finisherTitle' => 'Felicidades!',
			'recap.finisherSubtitle' => 'Has completado tu ruta',
			'recap.partialTitle' => 'Tu ruta parcial',
			'recap.partialSubtitle' => 'Tu aventura queda registrada',
			'recap.statsSection' => 'Estadisticas',
			'recap.traceSection' => 'Tu trazado',
			'recap.noTrace' => 'No hay trazado GPS disponible',
			'recap.stages' => '{done} / {total} etapas recorridas',
			'recap.distance' => '{km} km recorridos',
			'recap.elevation' => '{meters} m de desnivel positivo',
			'recap.duration' => '{days} dias',
			'recap.dates' => 'Del {start} al {end}',
			'recap.viewDiploma' => 'Ver mi diploma',
			'recap.noData' => 'Aun no hay datos de ruta para mostrar.',
			'programme.title' => 'Programa',
			'programme.helpTooltip' => 'Ayuda',
			'programme.stats.distance' => 'Distancia',
			'programme.stats.elevation' => 'Desnivel+',
			'programme.stats.days' => 'Días',
			'programme.stats.stages' => 'Etapas',
			'programme.stats.restCount' => '{count} descanso',
			'programme.legend.easy' => 'Fácil',
			'programme.legend.moderate' => 'Moderado',
			'programme.legend.hard' => 'Difícil',
			'programme.legend.extreme' => 'Extremo',
			'programme.restDay' => 'Día de descanso',
			'programme.restDayLabel' => 'R',
			'programme.actions.merge' => 'Agrupar',
			'programme.actions.split' => 'Separar',
			'programme.actions.rest' => 'Descanso',
			'programme.actions.removeRest' => 'Eliminar este día de descanso',
			'programme.mergeBlocked.noNext' => 'No hay día siguiente',
			'programme.mergeBlocked.rest' => 'No se puede agrupar con un día de descanso',
			'programme.mergeBlocked.tooLong' => 'Demasiado largo: {hours}h (máx {max}h/día)',
			'programme.replan' => 'Replanificar',
			'programme.replanButton' => 'REPLANIFICAR',
			'programme.replanDialog.title' => 'Replanificar',
			'programme.replanDialog.message' => 'La replanificación reiniciará tu programa.\nTus días de descanso se mantendrán en las mismas posiciones.',
			'programme.replanDialog.cancel' => 'Cancelar',
			'programme.replanDialog.confirm' => 'Replanificar',
			'programme.validate' => 'CONFIRMAR MI PROGRAMA',
			'programme.empty.title' => 'Configura primero tu itinerario',
			'programme.empty.message' => 'Elige tu ruta y la duración para generar tu programa.',
			'programme.empty.action' => 'CONFIGURAR EL ITINERARIO',
			'programme.info.title' => 'Programa',
			'programme.info.days.title' => 'Días de trek',
			'programme.info.days.body' => 'Cada línea = un día. Pulsa para ver el detalle completo.',
			'programme.info.reorder.title' => 'Reordenar',
			'programme.info.reorder.body' => 'Arrastra el asa de la derecha para cambiar el orden de los días.',
			'programme.info.rest.title' => 'Día de descanso',
			'programme.info.rest.body' => 'Inserta un día de recuperación entre dos etapas.',
			'programme.info.mergeSplit.title' => 'Agrupar / Separar',
			'programme.info.mergeSplit.body' => 'Combina o divide etapas según tu ritmo.',
			'programme.info.colors.title' => 'Colores',
			'programme.info.colors.body' => 'Verde = fácil, Naranja = medio, Rojo = difícil (distancia + desnivel).',
			'programme.info.note' => 'El perfil altimétrico de abajo muestra el desnivel de cada día.',
			'programme.info.close' => '¡Entendido!',
			'calendar.title' => 'Calendario',
			'calendar.validate' => 'CONFIRMAR FECHAS',
			'calendar.departure' => 'SALIDA',
			'calendar.arrival' => 'LLEGADA',
			'calendar.chooseDate' => 'Elegir una fecha',
			'calendar.chooseDateAction' => 'ELEGIR UNA FECHA',
			'calendar.previousMonth' => 'Mes anterior',
			'calendar.nextMonth' => 'Mes siguiente',
			'calendar.dayLabel' => 'D{n}',
			'calendar.restDayLabel' => 'R',
			'calendar.adjustStages' => 'AJUSTAR LAS ETAPAS',
			'calendar.stageSingular' => 'Etapa {n}',
			'calendar.stagesPlural' => 'Etapas {list}',
			'calendar.splitStages' => 'Separar las etapas',
			'calendar.mergeWithNext' => 'Agrupar con el día siguiente',
			'calendar.weekdays.mon' => 'Lun',
			'calendar.weekdays.tue' => 'Mar',
			'calendar.weekdays.wed' => 'Mié',
			'calendar.weekdays.thu' => 'Jue',
			'calendar.weekdays.fri' => 'Vie',
			'calendar.weekdays.sat' => 'Sáb',
			'calendar.weekdays.sun' => 'Dom',
			'calendar.legend.start' => 'Salida',
			'calendar.legend.walk' => 'Marcha',
			'calendar.legend.rest' => 'Descanso',
			'calendar.legend.arrival' => 'Llegada',
			'calendar.summary.totalDays' => 'Días total',
			'calendar.summary.walkDays' => 'Días marcha',
			'calendar.summary.restDays' => 'Días descanso',
			'calendar.noDate.title' => 'Elige una fecha de salida',
			'calendar.noDate.message' => 'El calendario de tu trek aparecerá automáticamente con los días de marcha y de descanso.',
			'calendar.empty.title' => 'Configura primero tu itinerario',
			'calendar.empty.message' => 'Elige tu ruta y la duración para poder configurar tus fechas.',
			'calendar.empty.action' => 'CONFIGURAR EL ITINERARIO',
			'nuitees.title' => 'Pernoctaciones',
			'nuitees.guideTooltip' => 'Guía de pernoctaciones',
			'nuitees.infoBar' => 'Reserva cada noche con antelación en temporada alta',
			'nuitees.types.refuge' => 'Refugio',
			'nuitees.types.gite' => 'Albergue',
			'nuitees.types.bivouac' => 'Vivac',
			'nuitees.types.autreHebergement' => 'Otro alojamiento',
			'nuitees.guide.title' => 'Guía de pernoctaciones',
			'nuitees.guide.refuge' => 'Alojamiento de montaña, se recomienda reservar en temporada alta.',
			'nuitees.guide.gite' => 'Albergue de etapa privado, a menudo con comidas y duchas.',
			'nuitees.guide.bivouac' => 'Acampada en tienda, según la normativa local.',
			'nuitees.guide.autre' => 'Hotel, casa de huéspedes o camping fuera del sendero.',
			'nuitees.guide.close' => 'Entendido',
			'nuitees.card.dayLabel' => 'D{n}',
			'nuitees.card.noPlace' => 'Alojamiento',
			'nuitees.card.available' => '{count} alojamientos disponibles',
			'nuitees.card.call' => 'Llamar {phone}',
			'nuitees.card.lockedHint' => 'Desmarca la noche para cambiar el tipo',
			'nuitees.summary.remaining' => '{count} noche(s) restante(s)',
			'nuitees.summary.done' => '{count} OK',
			'nuitees.summary.allBooked' => 'TODAS LAS NOCHES RESERVADAS',
			'nuitees.empty.title' => 'Configura primero tu itinerario',
			'nuitees.empty.message' => 'Elige tu ruta y duración para preparar tus noches.',
			'nuitees.empty.action' => 'CONFIGURAR ITINERARIO',
			_ => null,
		};
	}
}
