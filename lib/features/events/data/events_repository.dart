import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';
import 'package:guardian_portal/features/events/domain/events_deduplicator.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

class EventsRepository {
  EventsRepository({
    FirebaseFirestore? firestore,
    DeviceRepository? devices,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _devices = devices ?? DeviceRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final DeviceRepository _devices;

  /// Eventos do usuário logado, escopados ao aparelho físico (mesmo critério do app).
  Stream<List<SecurityEvent>> watchForUser(String uid) {
    return _devices.watchDevices(uid).asyncExpand((devices) {
      return _eventsStreamForDevices(uid, devices);
    });
  }

  Stream<List<SecurityEvent>> _eventsStreamForDevices(
    String uid,
    List<GuardianDevice> devices,
  ) {
    if (devices.isEmpty) {
      return _legacyUserEvents(uid).snapshots().map(_normalizeDocs);
    }

    final deviceIds = _relatedDeviceIds(devices);
    if (deviceIds.isEmpty) {
      return Stream.value(const []);
    }
    if (deviceIds.length == 1) {
      return _deviceEvents(uid, deviceIds.first)
          .snapshots()
          .map(_normalizeDocs);
    }
    return _mergedDeviceEvents(uid, deviceIds);
  }

  /// Mesmo aparelho físico pode ter docs órfãos (UUID antigo + fingerprint).
  static List<String> relatedDeviceIdsForTests(List<GuardianDevice> devices) =>
      _relatedDeviceIds(devices);

  static List<String> _relatedDeviceIds(List<GuardianDevice> devices) {
    if (devices.isEmpty) return [];

    final sorted = [...devices]
      ..sort((a, b) => _compareLastSeen(b.status.lastSeen, a.status.lastSeen));
    final primary = sorted.first;
    final fingerprint = primary.status.fingerprint;

    if (fingerprint != null && fingerprint.isNotEmpty) {
      return sorted
          .where((d) => d.status.fingerprint == fingerprint)
          .map((d) => d.id)
          .toSet()
          .toList();
    }

    final modelKey = _modelKey(primary.status);
    return sorted
        .where(
          (d) =>
              d.id == primary.id ||
              (d.status.fingerprint == null && _modelKey(d.status) == modelKey),
        )
        .map((d) => d.id)
        .toSet()
        .toList();
  }

  static String _modelKey(DeviceStatus status) =>
      '${status.platform}|${status.modelLabel}';

  static int _compareLastSeen(DateTime? a, DateTime? b) {
    final ta = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
  }

  Stream<List<SecurityEvent>> _mergedDeviceEvents(
    String uid,
    List<String> deviceIds,
  ) {
    final controller = StreamController<List<SecurityEvent>>();
    final latest = <String, List<SecurityEvent>>{};
    final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = latest.values.expand((events) => events).toList();
      controller.add(EventsDeduplicator.removeExactDuplicates(merged));
    }

    for (final deviceId in deviceIds) {
      final sub = _deviceEvents(uid, deviceId).snapshots().listen(
        (snap) {
          latest[deviceId] =
              snap.docs.map(SecurityEvent.fromDoc).toList(growable: false);
          emitMerged();
        },
        onError: controller.addError,
      );
      subscriptions.add(sub);
    }

    controller.onCancel = () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
    };

    return controller.stream;
  }

  List<SecurityEvent> _normalizeDocs(
    QuerySnapshot<Map<String, dynamic>> snap,
  ) {
    return EventsDeduplicator.removeExactDuplicates(
      snap.docs.map(SecurityEvent.fromDoc).toList(growable: false),
    );
  }

  Query<Map<String, dynamic>> _deviceEvents(String uid, String deviceId) =>
      _firestore
          .collection('users')
          .doc(uid)
          .collection('devices')
          .doc(deviceId)
          .collection('events')
          .orderBy('occurredAt', descending: true)
          .limit(100);

  Query<Map<String, dynamic>> _legacyUserEvents(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('events')
      .orderBy('occurredAt', descending: true)
      .limit(100);
}
