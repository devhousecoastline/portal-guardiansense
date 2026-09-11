import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/locate/domain/location_history_point.dart';

/// Lê a trilha GPS gravada pelo app em `devices/{id}/locations`.
class LocationHistoryRepository {
  LocationHistoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Limite defensivo por consulta (UI avisa quando bate o teto).
  static const listenLimit = 200;

  Stream<List<LocationHistoryPoint>> watchHistory({
    required String uid,
    required String deviceId,
    required DateTime since,
    DateTime? until,
  }) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('users')
        .doc(uid)
        .collection('devices')
        .doc(deviceId)
        .collection('locations')
        .where(
          'recordedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(since),
        );

    if (until != null) {
      query = query.where(
        'recordedAt',
        isLessThanOrEqualTo: Timestamp.fromDate(until),
      );
    }

    return query
        .orderBy('recordedAt', descending: true)
        .limit(listenLimit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(LocationHistoryPoint.fromDoc)
              .where((p) => p.lat != 0 || p.lng != 0)
              .toList(growable: false),
        );
  }
}
