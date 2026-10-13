/// La page que suivent les proches, atteignable par un code de partage : un
/// marqueur qui avance, et rien d'autre.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/attribution_osm.dart';
import '../data/suivi_public_depot.dart';
import '../../../core/branding/stepways_icons.dart';

/// Ecran web de suivi de position en temps reel (E4.12a).
///
/// Affiche une carte flutter_map avec un marqueur qui se deplace
/// en temps reel selon les positions publiees dans Firestore.
/// Accessible via la route /follow/{shareCode} (lien web ou deeplink).
/// Pas d authentification requise cote suiveur.
/// Textes via Slang (t.follow.*) — zero texte ni marque en dur.
///
/// E4.12a — Dependances: E4.11 (FollowService).
class FollowWebScreen extends ConsumerStatefulWidget {
  const FollowWebScreen({super.key, required this.shareCode});

  /// Code de partage a 6 caracteres (extrait de l URL).
  final String shareCode;

  @override
  ConsumerState<FollowWebScreen> createState() => _FollowWebScreenState();
}

class _FollowWebScreenState extends ConsumerState<FollowWebScreen> {
  final MapController _mapController = MapController();
  LatLng? _trekkerPosition;
  DateTime? _lastTimestamp;
  bool _sessionFound = false;
  bool _hasError = false;
  bool _isLoading = true;
  bool _isFirstPosition = true;
  StreamSubscription<PositionSuivie>? _positionSubscription;

  /// Vue monde neutre tant qu aucune position n est recue
  /// (aucune region codee en dur — la carte se centre sur le
  /// randonneur des la premiere position).
  static const _defaultCenter = LatLng(0, 0);
  static const _defaultZoom = 2.0;
  static const _positionZoom = 15.0;

  @override
  void initState() {
    super.initState();
    observeScreenEntry(ref, ScreenBreadcrumb.followWeb);
    _startListening();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Recherche la session par shareCode et ecoute les positions.
  ///
  /// L ECRAN NE PARLE PLUS A FIRESTORE (cas K2 du lot 645-05). La resolution du
  /// code de partage, le miroir public minimal, le TTL de 48 h et le garde
  /// `isAvailable` sont descendus dans `SuiviPublicDepot` (couche data du
  /// groupe) : c etait l unique endroit du depot ou la couche presentation
  /// importait `package:cloud_firestore` (ECR-25). Les trois cas que l ecran
  /// traitait de la meme facon — Firebase indisponible, aucune session active,
  /// session expiree — arrivent ici comme un `sessionId` nul, et affichent le
  /// meme ecran « lien invalide » qu avant.
  Future<void> _startListening() async {
    // LE TYPE EST NOMME, ET CE N EST PAS DE LA DECORATION : c est la seule
    // citation de `SuiviPublicDepot` hors de son propre fichier, et c est elle
    // qui dit, a la lecture de l ecran, de quoi il depend desormais — un depot
    // du groupe, pas Firestore.
    final SuiviPublicDepot depot = ref.read(suiviPublicDepotProvider);
    try {
      final sessionId = await depot.resoudreSession(widget.shareCode);
      if (sessionId == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _sessionFound = true;
        _isLoading = false;
      });
      _positionSubscription = depot
          .positions(sessionId)
          .listen(
            _onPositionUpdate,
            onError: (_) {
              // P1-4 audit #327 : erreur de flux (ex. session expiree refusee
              // par les regles) -> badge "hors ligne" au lieu d un faux "en
              // direct" fige sur la derniere position.
              if (mounted) setState(() => _sessionFound = false);
            },
          );
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Callback quand une nouvelle position arrive du depot de suivi.
  void _onPositionUpdate(PositionSuivie position) {
    final newPosition = LatLng(position.lat, position.lng);
    setState(() {
      _trekkerPosition = newPosition;
      _lastTimestamp = position.horodatage;
    });
    if (_isFirstPosition) {
      _mapController.move(newPosition, _positionZoom);
      _isFirstPosition = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildMapOrStatus(theme)),
          if (_trekkerPosition != null) _buildInfoBar(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      color: theme.colorScheme.surface,
      child: SafeArea(
        bottom: false,
        // DEBORDEMENT MESURE (tache 580, Y3) : 67 pixels coupes sur la droite,
        // sur un telephone courant. Le titre prenait sa largeur NATURELLE a
        // cote d'un badge d'etat lui aussi libre de s'etendre : des que la
        // somme des deux depasse la largeur de l'ecran, la fin du titre part
        // hors champ SANS lever d'exception visible a l'utilisateur. Le
        // titre devient [Flexible] : c'est lui qui cede, il se replie sur
        // deux lignes, et le badge — la seule information qui dit si le suivi
        // est vivant — reste entier. Rien n'est tronque, rien n'est deplace.
        child: Row(
          children: [
            Flexible(
              child: Text(
                t.follow.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            _buildStatusBadge(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isLive = _sessionFound && _trekkerPosition != null;
    final dotColor = isLive ? AppTheme.vertFacile : AppTheme.emergencyRed;
    final text = _isLoading
        ? t.follow.connecting
        : isLive
        ? t.follow.live
        : t.follow.offline;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _buildMapOrStatus(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StepIcon(
                StepwaysIcons.lienRompu,
                size: 48,
                color: AppTheme.emergencyRed,
              ),
              const SizedBox(height: AppTheme.spacingBase),
              Text(
                t.follow.invalidLink,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.emergencyRed,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                t.follow.invalidLinkHint,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _trekkerPosition ?? _defaultCenter,
        initialZoom: _trekkerPosition != null ? _positionZoom : _defaultZoom,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),
        if (_trekkerPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _trekkerPosition!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.vertFacile,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        // ODbL : les tuiles viennent d OpenStreetMap, la carte le dit
        // (integration 647).
        const AttributionOsm(),
      ],
    );
  }

  Widget _buildInfoBar(ThemeData theme) {
    final pos = _trekkerPosition!;
    final timeStr = _lastTimestamp != null
        ? TimeOfDay.fromDateTime(_lastTimestamp!).format(context)
        : '--';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      color: theme.colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${pos.latitude.toStringAsFixed(5)}, '
            '${pos.longitude.toStringAsFixed(5)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: AppTheme.vertFacile,
            ),
          ),
          Text(
            timeStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}
