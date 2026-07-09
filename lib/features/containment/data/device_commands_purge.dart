import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';

/// Remove comandos remotos antigos para reduzir leituras nos polls do app.
abstract final class DeviceCommandsPurge {
  static const retention = Duration(days: 7);
  static const batchSize = 20;

  static bool isEligibleForDeletion(
    Map<String, dynamic> data,
    DateTime cutoff,
  ) {
    final status = DeviceCommandStatus.parse(data['status'] as String?);
    if (status != DeviceCommandStatus.applied &&
        status != DeviceCommandStatus.failed) {
      return false;
    }

    final createdAt = _timestamp(data['createdAt']);
    if (createdAt == null) return false;
    return createdAt.isBefore(cutoff);
  }

  static Future<int> purgeCollection(
    CollectionReference<Map<String, dynamic>> commands, {
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final cutoff = DateTime.now().subtract(retention);
    var totalDeleted = 0;

    while (true) {
      final snap = await commands
          .where('status', whereIn: [
            DeviceCommandStatus.applied.storageKey,
            DeviceCommandStatus.failed.storageKey,
          ])
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoff))
          .orderBy('createdAt')
          .limit(batchSize)
          .get();

      if (snap.docs.isEmpty) break;

      final batch = db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      totalDeleted += snap.docs.length;

      if (snap.docs.length < batchSize) break;
    }

    return totalDeleted;
  }

  static DateTime? _timestamp(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
