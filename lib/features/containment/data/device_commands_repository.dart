import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/containment/data/device_commands_purge.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';
import 'package:guardian_portal/features/dashboard/domain/protected_layer_summary.dart';

class DeviceCommandRateLimitException implements Exception {
  DeviceCommandRateLimitException(this.retryAfter);

  final Duration retryAfter;

  @override
  String toString() {
    final seconds = (retryAfter.inMilliseconds / 1000).ceil().clamp(1, 999);
    return seconds == 1
        ? 'Aguarde 1 segundo antes de enviar outro comando.'
        : 'Aguarde $seconds segundos antes de enviar outro comando.';
  }
}

/// Já existe um comando pendente na fila do aparelho.
class DeviceCommandAlreadyPendingException implements Exception {
  const DeviceCommandAlreadyPendingException();

  @override
  String toString() =>
      'Comando já enviado. Aguardando o celular aplicar.';
}

class DeviceCommandsRepository {
  DeviceCommandsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const minInterval = Duration(seconds: 30);
  static const stalePendingAfter = Duration(minutes: 5);

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
    _guardCommandSend(latest);

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

  Query<Map<String, dynamic>> _protectAppQuery(String uid, String deviceId) =>
      _commands(uid, deviceId)
          .where('type', isEqualTo: DeviceCommandType.protectApp.storageKey)
          .orderBy('createdAt', descending: true)
          .limit(10);

  Future<DeviceCommand> requestProtectApp({
    required String uid,
    required String deviceId,
    required String requestedBy,
    required String packageName,
    required String label,
    required String sectionId,
  }) async {
    final latest = await _latestProtectApp(uid, deviceId, packageName);
    _guardCommandSend(latest);

    final ref = _commands(uid, deviceId).doc();
    final now = DateTime.now();
    await ref.set({
      'type': DeviceCommandType.protectApp.storageKey,
      'status': DeviceCommandStatus.pending.storageKey,
      'reason': 'portal_remote',
      'packageName': packageName,
      'label': label,
      'sectionId': sectionId,
      'createdAt': Timestamp.fromDate(now),
      'requestedBy': requestedBy,
    });

    unawaited(
      DeviceCommandsPurge.purgeCollection(_commands(uid, deviceId))
          .catchError((_) => 0),
    );

    return DeviceCommand(
      id: ref.id,
      type: DeviceCommandType.protectApp,
      status: DeviceCommandStatus.pending,
      createdAt: now,
      requestedBy: requestedBy,
      reason: 'portal_remote',
      packageName: packageName,
      label: label,
      sectionId: sectionId,
    );
  }

  Future<DeviceCommand?> _latestProtectApp(
    String uid,
    String deviceId,
    String packageName,
  ) async {
    final snap = await _protectAppQuery(uid, deviceId).get();
    for (final doc in snap.docs) {
      final command = DeviceCommand.fromDoc(doc);
      if (command.packageName == packageName) return command;
    }
    return null;
  }

  Query<Map<String, dynamic>> _protectAppsQuery(String uid, String deviceId) =>
      _commands(uid, deviceId)
          .where('type', isEqualTo: DeviceCommandType.protectApps.storageKey)
          .orderBy('createdAt', descending: true)
          .limit(1);

  Future<DeviceCommand> requestProtectApps({
    required String uid,
    required String deviceId,
    required String requestedBy,
    required List<ProtectAppCommandTarget> apps,
  }) async {
    if (apps.isEmpty) {
      throw ArgumentError('Nenhum app elegível para proteção em massa');
    }

    final latest = await _latestProtectApps(uid, deviceId);
    _guardCommandSend(latest);

    final ref = _commands(uid, deviceId).doc();
    final now = DateTime.now();
    await ref.set({
      'type': DeviceCommandType.protectApps.storageKey,
      'status': DeviceCommandStatus.pending.storageKey,
      'reason': 'portal_remote',
      'apps': apps.map((app) => app.toFirestoreMap()).toList(),
      'appCount': apps.length,
      'createdAt': Timestamp.fromDate(now),
      'requestedBy': requestedBy,
    });

    unawaited(
      DeviceCommandsPurge.purgeCollection(_commands(uid, deviceId))
          .catchError((_) => 0),
    );

    return DeviceCommand(
      id: ref.id,
      type: DeviceCommandType.protectApps,
      status: DeviceCommandStatus.pending,
      createdAt: now,
      requestedBy: requestedBy,
      reason: 'portal_remote',
      apps: apps,
      appCount: apps.length,
    );
  }

  Future<DeviceCommand?> _latestProtectApps(String uid, String deviceId) async {
    final snap = await _protectAppsQuery(uid, deviceId).get();
    if (snap.docs.isEmpty) return null;
    return DeviceCommand.fromDoc(snap.docs.first);
  }

  void _guardCommandSend(DeviceCommand? latest) {
    if (latest == null) return;

    final age = DateTime.now().difference(latest.createdAt);

    if (latest.isPending) {
      if (age < stalePendingAfter) {
        throw const DeviceCommandAlreadyPendingException();
      }
      return;
    }

    if (age < minInterval) {
      throw DeviceCommandRateLimitException(minInterval - age);
    }
  }

  /// Limpeza manual (ex.: pull-to-refresh futuro). Best-effort.
  Future<int> purgeStaleCommands(String uid, String deviceId) {
    return DeviceCommandsPurge.purgeCollection(_commands(uid, deviceId));
  }
}
