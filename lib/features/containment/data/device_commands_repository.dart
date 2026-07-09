import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/containment/data/device_commands_purge.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';

class DeviceCommandRateLimitException implements Exception {
  DeviceCommandRateLimitException(this.retryAfter);

  final Duration retryAfter;

  @override
  String toString() {
    return 'Aguarde ${retryAfter.inSeconds}s antes de enviar outro comando.';
  }
}

class DeviceCommandsRepository {
  DeviceCommandsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const minInterval = Duration(seconds: 30);

  CollectionReference<Map<String, dynamic>> _commands(
    String uid,
    String deviceId,
  ) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .collection('commands');

  Query<Map<String, dynamic>> _closeOysterQuery(String uid, String deviceId) =>
      _commands(uid, deviceId)
          .where('type', isEqualTo: DeviceCommandType.closeOyster.storageKey)
          .orderBy('createdAt', descending: true)
          .limit(1);

  Stream<DeviceCommand?> watchLatestCloseOyster(String uid, String deviceId) {
    return _closeOysterQuery(uid, deviceId).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return DeviceCommand.fromDoc(snap.docs.first);
    });
  }

  Future<DeviceCommand> requestCloseOyster({
    required String uid,
    required String deviceId,
    required String requestedBy,
  }) async {
    final latest = await _latestCloseOyster(uid, deviceId);
    if (latest != null) {
      if (latest.isPending) {
        throw DeviceCommandRateLimitException(minInterval);
      }
      final age = DateTime.now().difference(latest.createdAt);
      if (age < minInterval) {
        throw DeviceCommandRateLimitException(minInterval - age);
      }
    }

    final ref = _commands(uid, deviceId).doc();
    final now = DateTime.now();
    await ref.set({
      'type': DeviceCommandType.closeOyster.storageKey,
      'status': DeviceCommandStatus.pending.storageKey,
      'reason': 'portal_remote',
      'createdAt': Timestamp.fromDate(now),
      'requestedBy': requestedBy,
    });

    unawaited(
      DeviceCommandsPurge.purgeCollection(_commands(uid, deviceId))
          .catchError((_) => 0),
    );

    return DeviceCommand(
      id: ref.id,
      type: DeviceCommandType.closeOyster,
      status: DeviceCommandStatus.pending,
      createdAt: now,
      requestedBy: requestedBy,
      reason: 'portal_remote',
    );
  }

  Future<DeviceCommand?> _latestCloseOyster(String uid, String deviceId) async {
    final snap = await _closeOysterQuery(uid, deviceId).get();
    if (snap.docs.isEmpty) return null;
    return DeviceCommand.fromDoc(snap.docs.first);
  }

  /// Limpeza manual (ex.: pull-to-refresh futuro). Best-effort.
  Future<int> purgeStaleCommands(String uid, String deviceId) {
    return DeviceCommandsPurge.purgeCollection(_commands(uid, deviceId));
  }
}
