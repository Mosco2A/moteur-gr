import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/firebase/firebase_service.dart';
import '../models/group_member.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const _codeLength = 6;

/// Service de localisation partagee en groupe.
/// Design #81460 : 2 mateurs gratuits, mode horaire + mode refuge.
class GroupTrackingService {
  GroupTrackingService({required this.firebaseService, FirebaseFirestore? firestore})
      : _firestore = firestore;

  final FirebaseService firebaseService;
  FirebaseFirestore? _firestore;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  final List<_PendingPosition> _hourlyBuffer = [];
  Timer? _hourlyTimer;
  String? _activeGroupCode;
  String? _currentUid;
  String? _lastStageId;

  Future<String?> createGroup(String trailId, {required String uid}) async {
    if (!firebaseService.isAvailable) return null;
    final code = _generateCode();
    _currentUid = uid;
    try {
      await firestore.collection('groups').doc(code).set({
        'groupCode': code, 'trailId': trailId, 'createdBy': uid,
        'maxFreeWatchers': 2, 'createdAt': FieldValue.serverTimestamp(),
        'members': [{'uid': uid, 'displayName': null, 'lastLat': 0.0, 'lastLng': 0.0,
            'lastUpdate': DateTime.now().toIso8601String(), 'currentStageId': null}],
      });
      _activeGroupCode = code;
      return code;
    } catch (e) { _log.e('[GroupTracking] Erreur create: $e'); return null; }
  }

  Future<bool> joinGroup(String groupCode, {required String uid, String? displayName}) async {
    if (!firebaseService.isAvailable) return false;
    _currentUid = uid;
    try {
      final docRef = firestore.collection('groups').doc(groupCode);
      final doc = await docRef.get();
      if (!doc.exists) return false;
      await docRef.update({
        'members': FieldValue.arrayUnion([{'uid': uid, 'displayName': displayName,
            'lastLat': 0.0, 'lastLng': 0.0,
            'lastUpdate': DateTime.now().toIso8601String(), 'currentStageId': null}]),
      });
      _activeGroupCode = groupCode;
      return true;
    } catch (e) { _log.e('[GroupTracking] Erreur join: $e'); return false; }
  }

  Future<void> leaveGroup() async {
    if (!firebaseService.isAvailable || _activeGroupCode == null) return;
    try {
      final docRef = firestore.collection('groups').doc(_activeGroupCode);
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final members = (data['members'] as List<dynamic>?) ?? [];
        final updated = members.where((m) => (m as Map<String, dynamic>)['uid'] != _currentUid).toList();
        await docRef.update({'members': updated});
      }
      _hourlyTimer?.cancel(); _hourlyBuffer.clear(); _activeGroupCode = null;
    } catch (e) { _log.e('[GroupTracking] Erreur leave: $e'); }
  }

  Future<void> sharePosition(double lat, double lng, {String? stageId}) async {
    if (!firebaseService.isAvailable || _activeGroupCode == null) return;
    if (stageId != null && stageId != _lastStageId) {
      _lastStageId = stageId;
      await _pushPosition(lat, lng, stageId: stageId);
      return;
    }
    _hourlyBuffer.add(_PendingPosition(lat: lat, lng: lng, stageId: stageId));
    _hourlyTimer ??= Timer.periodic(const Duration(hours: 1), (_) => _flushHourlyBuffer());
  }

  Stream<List<GroupMember>> membersStream(String groupCode) {
    if (!firebaseService.isAvailable) return const Stream.empty();
    return firestore.collection('groups').doc(groupCode).snapshots().map((snapshot) {
      if (!snapshot.exists) return <GroupMember>[];
      final data = snapshot.data()!;
      final members = (data['members'] as List<dynamic>?) ?? [];
      return members.map((m) => GroupMember.fromJson(m as Map<String, dynamic>)).toList();
    });
  }

  bool isFreeLimitReached(GroupInfo group) {
    final wc = group.members.where((m) => m.uid != group.createdBy).length;
    return wc >= group.maxFreeWatchers;
  }

  Future<void> _flushHourlyBuffer() async {
    if (_hourlyBuffer.isEmpty || _activeGroupCode == null) return;
    final last = _hourlyBuffer.last; _hourlyBuffer.clear();
    await _pushPosition(last.lat, last.lng, stageId: last.stageId);
  }

  Future<void> _pushPosition(double lat, double lng, {String? stageId}) async {
    if (_activeGroupCode == null || _currentUid == null) return;
    try {
      final docRef = firestore.collection('groups').doc(_activeGroupCode);
      final doc = await docRef.get();
      if (!doc.exists) return;
      final data = doc.data()!;
      final members = (data['members'] as List<dynamic>?) ?? [];
      final updated = members.map((m) {
        final member = m as Map<String, dynamic>;
        if (member['uid'] == _currentUid) {
          return {...member, 'lastLat': lat, 'lastLng': lng,
            'lastUpdate': DateTime.now().toIso8601String(),
            'currentStageId': stageId ?? member['currentStageId']};
        }
        return member;
      }).toList();
      await docRef.update({'members': updated});
    } catch (e) { _log.e('[GroupTracking] Erreur push: $e'); }
  }

  String _generateCode() {
    final random = Random.secure();
    return List.generate(_codeLength, (_) => _codeChars[random.nextInt(_codeChars.length)]).join();
  }

  void dispose() { _hourlyTimer?.cancel(); _hourlyBuffer.clear(); }
}

class _PendingPosition {
  const _PendingPosition({required this.lat, required this.lng, this.stageId});
  final double lat; final double lng; final String? stageId;
}

final groupTrackingServiceProvider = Provider<GroupTrackingService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  final service = GroupTrackingService(firebaseService: firebase);
  ref.onDispose(() => service.dispose());
  return service;
});
