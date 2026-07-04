import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Leitura de dispositivos em `users/{uid}/devices/{deviceId}`.
///
/// O portal **nunca** escreve estado de proteção — apenas lê o que o app sincroniza.
class DeviceRepository {
  DeviceRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _devices(String uid) =>
      _firestore.collection('users').doc(uid).collection('devices');

  Stream<List<GuardianDevice>> watchDevices(String uid) {
    return _devices(uid)
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(GuardianDevice.fromDoc).toList());
  }

  Stream<GuardianDevice?> watchPrimaryDevice(String uid) {
    return watchDevices(uid).map((devices) {
      if (devices.isEmpty) return null;
      return devices.first;
    });
  }
}
