import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';

class GuardianDevice {
  const GuardianDevice({
    required this.id,
    required this.status,
  });

  final String id;
  final DeviceStatus status;

  factory GuardianDevice.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return GuardianDevice(
      id: doc.id,
      status: DeviceStatus.fromFirestore(doc.id, doc.data() ?? {}),
    );
  }
}
