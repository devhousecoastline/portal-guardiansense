import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/events/domain/security_event.dart';

class EventsRepository {
  EventsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<SecurityEvent>> watchRecent(String uid, {String? deviceId}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('events')
        .orderBy('occurredAt', descending: true)
        .limit(50);

    if (deviceId != null) {
      query = query.where('deviceId', isEqualTo: deviceId);
    }

    return query.snapshots().map(
          (snap) => snap.docs.map(SecurityEvent.fromDoc).toList(),
        );
  }
}
