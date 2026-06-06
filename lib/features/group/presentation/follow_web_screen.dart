import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

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
  StreamSubscription<QuerySnapshot>? _positionSubscription;

  /// Vue monde neutre tant qu aucune position n est recue
  /// (aucune region codee en dur — la carte se centre sur le
  /// randonneur des la premiere position).
  static const _defaultCenter = LatLng(0, 0);
  static const _defaultZoom = 2.0;
  static const _positionZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Recherche la session par shareCode et ecoute les positions.
  Future<void> _startListening() async {
    final firebase = ref.read(firebaseServiceProvider);
    if (!firebase.isAvailable) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      return;
    }
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore
          .collection('follow_sessions')
          .where('shareCode', isEqualTo: widget.shareCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }
      final sessionId = snapshot.docs.first.id;
      setState(() {
        _sessionFound = true;
        _isLoading = false;
      });
      _positionSubscription = firestore
          .collection('follow_sessions')
          .doc(sessionId)
          .collection('positions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .snapshots()
          .listen(_onPositionUpdate, onError: (_) {});
    } catch (_) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  /// Callback quand une nouvelle position arrive de Firestore.
  void _onPositionUpdate(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return;
    final data = snapshot.docs.first.data() as Map<String, dynamic>;
    final lat = (data['lat'] as num?)?.toDouble();
    final lng = (data['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return;
    final newPosition = LatLng(lat, lng);
    DateTime? timestamp;
    final ts = data['timestamp'];
    if (ts is Timestamp) {
      timestamp = ts.toDate();
    }
    setState(() {
      _trekkerPosition = newPosition;
      _lastTimestamp = timestamp;
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
      body: Column(children: [
        _buildHeader(theme),
        Expanded(child: _buildMapOrStatus(theme)),
        if (_trekkerPosition != null) _buildInfoBar(theme),
      ]),
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
        child: Row(children: [
          Text(
            t.follow.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          _buildStatusBadge(theme),
        ]),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    final isLive = _sessionFound && _trekkerPosition != null;
    final dotColor = isLive ? AppTheme.vertFacile : AppTheme.rougeUrgence;
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: theme.textTheme.labelSmall),
      ]),
    );
  }

  Widget _buildMapOrStatus(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link_off, size: 48, color: AppTheme.rougeUrgence),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              t.follow.invalidLink,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppTheme.rougeUrgence),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.follow.invalidLinkHint,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
          ]),
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
          MarkerLayer(markers: [
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
          ]),
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
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppTheme.grisGranite),
          ),
        ],
      ),
    );
  }
}
