import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

class EventsRepository {
  EventsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SecurityEvent>> watchRecent(String uid, {String? deviceId}) {
    if (deviceId != null && deviceId.isNotEmpty) {
      return _deviceEvents(uid, deviceId).snapshots().map(
            (snap) => snap.docs.map(SecurityEvent.fromDoc).toList(),
          );
    }

    return _legacyUserEvents(uid).snapshots().map(
          (snap) => snap.docs.map(SecurityEvent.fromDoc).toList(),
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
          .limit(50);

  Query<Map<String, dynamic>> _legacyUserEvents(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('events')
      .orderBy('occurredAt', descending: true)
      .limit(50);
}
