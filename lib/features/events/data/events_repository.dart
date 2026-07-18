import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Histórico suficiente para filtros de 7/30 dias com quebra por data.
  static const eventsListenLimit = 120;

  /// Eventos de um aparelho específico (1 leitura por snapshot).
  Stream<List<SecurityEvent>> watchForDevice(String uid, String deviceId) {
    return _deviceEvents(uid, deviceId).snapshots().map(_normalizeDocs);
  }

  /// Eventos do dispositivo principal (mesmo doc que o app usa ao sincronizar).
  Stream<List<SecurityEvent>> watchForUser(String uid) {
    return _devices.watchDevices(uid).asyncExpand((devices) {
      final primaryId = _primaryDeviceId(devices);
      if (primaryId == null) {
        return Stream.value(const []);
      }

      return watchForDevice(uid, primaryId);
    });
  }

  static String? primaryDeviceIdForTests(List<GuardianDevice> devices) =>
      _primaryDeviceId(devices);

  static String? _primaryDeviceId(List<GuardianDevice> devices) {
    if (devices.isEmpty) return null;

    final sorted = [...devices]
      ..sort((a, b) => _compareLastSeen(b.status.lastSeen, a.status.lastSeen));
    return sorted.first.id;
  }

  static int _compareLastSeen(DateTime? a, DateTime? b) {
    final ta = a ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b ?? DateTime.fromMillisecondsSinceEpoch(0);
    return ta.compareTo(tb);
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
          .limit(eventsListenLimit);
}
