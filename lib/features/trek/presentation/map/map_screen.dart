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
import '../../../../shared/widgets/bouton_simulation_demo.dart';
import '../../../../shared/widgets/grise_en_demo.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../journal/data/photo_service.dart';
import '../../../journal/providers/journal_providers.dart';
import '../../../map/domain/stage_focus.dart';
import '../../../map/providers/gpx_track_provider.dart';
import '../../../map/providers/location_provider.dart';
import '../../../map/providers/map_pois_provider.dart';
import '../../../map/providers/off_track_provider.dart';
import '../../../map/providers/simplified_track_provider.dart';
import '../../../map/providers/supply_alert_provider.dart';
import '../../../map/providers/track_position_provider.dart';
import '../../../map/widgets/map_guide_sheet.dart';
import '../../../map/widgets/off_track_banner.dart';
import '../../../map/widgets/poi_filter_bar.dart';
import '../../../map/widgets/poi_popup.dart';
import '../../../map/widgets/stage_poi_checklist.dart';
import '../../../map/widgets/stage_progress_bar.dart';
import '../../../safety/presentation/sos_button.dart';
import '../../../trail/providers/progress_provider.dart';
import '../../../trail/providers/stages_provider.dart';
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
part 'map_screen_ecran.dart';
part 'map_screen_contenu.dart';
part 'map_screen_alertes.dart';
part 'map_screen_barres.dart';
part 'map_screen_surcouches.dart';
