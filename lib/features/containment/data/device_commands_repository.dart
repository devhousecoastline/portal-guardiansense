import 'package:cloud_firestore/cloud_firestore.dart';
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
  static const listenLimit = 20;

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

  Stream<DeviceCommand?> watchLatestCloseOyster(String uid, String deviceId) {
    return _commands(uid, deviceId)
        .orderBy('createdAt', descending: true)
        .limit(listenLimit)
        .snapshots()
        .map((snap) {
      for (final doc in snap.docs) {
        final command = DeviceCommand.fromDoc(doc);
        if (command.type == DeviceCommandType.closeOyster) return command;
      }
      return null;
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
    final payload = {
      'type': DeviceCommandType.closeOyster.storageKey,
      'status': DeviceCommandStatus.pending.storageKey,
      'reason': 'portal_remote',
      'createdAt': Timestamp.fromDate(now),
      'requestedBy': requestedBy,
    };

    await ref.set(payload);
    final created = await ref.get();
    return DeviceCommand.fromDoc(created);
  }

  Future<DeviceCommand?> _latestCloseOyster(String uid, String deviceId) async {
    final snap = await _commands(uid, deviceId)
        .orderBy('createdAt', descending: true)
        .limit(listenLimit)
        .get();

    for (final doc in snap.docs) {
      final command = DeviceCommand.fromDoc(doc);
      if (command.type == DeviceCommandType.closeOyster) return command;
    }
    return null;
  }
}
