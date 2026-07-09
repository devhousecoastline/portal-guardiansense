import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardian_portal/features/account/data/user_repository.dart';
import 'package:guardian_portal/features/devices/domain/device_registry.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Leitura de dispositivos em `users/{uid}/devices/{deviceId}`.
///
/// O portal **nunca** escreve estado de proteção — apenas lê o que o app sincroniza.
class DeviceRepository {
  DeviceRepository({
    FirebaseFirestore? firestore,
    UserRepository? users,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _users = users ?? UserRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final UserRepository _users;

  CollectionReference<Map<String, dynamic>> _devices(String uid) =>
      _firestore.collection('users').doc(uid).collection('devices');

  /// Limite alinhado ao máximo visível por plano — evita ler docs órfãos.
  static const deviceListenLimit = 5;

  Stream<List<GuardianDevice>> watchDevices(String uid) {
    return _devices(uid)
        .orderBy('lastSeen', descending: true)
        .limit(deviceListenLimit)
        .snapshots()
        .map((snap) => snap.docs.map(GuardianDevice.fromDoc).toList());
  }

  /// Lista deduplicada por aparelho físico, respeitando o limite do plano.
  Stream<DeviceListSnapshot> watchDeviceList(String uid) {
    return _users.watchPlan(uid).asyncExpand((plan) {
      return watchDevices(uid).map(
        (devices) => DeviceRegistry.apply(devices, plan),
      );
    });
  }

  Stream<GuardianDevice?> watchPrimaryDevice(String uid) {
    return watchDeviceList(uid).map((snapshot) {
      if (snapshot.visible.isEmpty) return null;
      return snapshot.visible.first;
    });
  }
}
