/// L'ecran de carte et le cycle de vie de son controleur, cree puis libere par
/// son notifier plutot qu'a la main.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/analytics/screen_entry.dart';
import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/trace_point.dart';
import '../../../../core/map/test_inert_tile_provider.dart';
import '../../../../core/models/poi.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/attribution_osm.dart';
import '../../../../shared/widgets/demo_simulation_button.dart';
import '../../../../shared/widgets/grise_en_demo.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../journal/data/photo_service.dart';
import '../../../journal/journal_facade.dart' show journalScreenProvider;
import '../../../map/domain/stage_focus.dart';
import '../../../map/map_facade.dart'
    show
        OffTrackMessages,
        gpxTrackProvider,
        locationProvider,
        mapPoisProvider,
        offTrackMessagesProvider,
        simplifiedTrackProvider,
        stageDistanceCoveredProvider,
        supplyGapAlertProvider,
        trackPositionProvider;
import '../../../map/widgets/map_guide_sheet.dart';
import '../../../map/widgets/off_track_banner.dart';
import '../../../map/widgets/poi_filter_bar.dart';
import '../../../map/widgets/poi_popup.dart';
import '../../../map/widgets/stage_poi_checklist.dart';
import '../../../map/widgets/stage_progress_bar.dart';
import '../../../safety/presentation/sos_button.dart';
import '../../../trail/trail_facade.dart'
    show currentStageNumberProvider, stagesProvider;
import '../../../../domain/stage.dart';
import '../../providers/gps_providers.dart';
import '../../providers/live_trek_stats_provider.dart';
import '../../providers/tracking_providers.dart';
import 'controls/map_controls.dart';
import 'layers/trace_layer.dart';
import 'layers/trail_markers_layer.dart';
import 'layers/user_position_layer.dart';
import 'marker_overlap.dart';
import '../../../../core/branding/stepways_icons.dart';

part 'map_screen_controleur.dart';
part 'map_screen_view.dart';
part 'map_screen_contenu.dart';
part 'map_screen_alertes.dart';
part 'map_screen_barres.dart';
part 'map_screen_surcouches.dart';

/// LA MIETTE D'OBSERVABILITE DE LA CARTE (lot 645-09).
///
/// ELLE EST DECLAREE ICI ET POSEE DANS `map_screen_view.dart`, pour la meme
/// raison que la fiche medicale : le lot 645-06 a scinde cet ecran en sept
/// fichiers, et c'est le morceau `view` qui porte la classe `MapScreen` et son
/// etat. Cette racine, elle, ne porte que des imports et des `part` — et c'est
/// pourtant elle que l'audit 644 compte comme « ecran ». La miette declaree
/// ici est donc visible a la mesure, et posee la ou l'ecran entre vraiment.
///
/// LA CARTE EST L'ECRAN DE TERRAIN : celui ou le randonneur passe ses
/// journees, celui qui tient le GPS allume, et donc celui dont un rapport de
/// plantage a le plus besoin de contexte. Elle alimente `screen` et `trail`.
/// PAS `stage`, ET C'EST DELIBERE : le numero d'etape courante vit dans un
/// provider, et le lire a l'entree de l'ecran le ferait NAITRE une frame plus
/// tot qu'aujourd'hui. Le lot exige « comportement avant = apres » ; la cle
/// `stage` est donc alimentee par les quatre ecrans qui portent deja un numero
/// d'etape en champ (trail_stage_detail, trek_stage_detail,
/// accommodation_detail, weather), sans une seule lecture nouvelle.
const _breadcrumb = ScreenBreadcrumb.map;
