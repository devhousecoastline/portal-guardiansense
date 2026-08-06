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

  /// Inclui ativos + histórico released (app mantém docs ao desvincular).
  static const deviceListenLimit = 20;

  Stream<List<GuardianDevice>> watchDevices(String uid) {
    return _devices(uid)
        .orderBy('lastSeen', descending: true)
        .limit(deviceListenLimit)
        .snapshots()
        .map((snap) => snap.docs.map(GuardianDevice.fromDoc).toList());
  }

  /// Lista deduplicada: ativos no plano + released + cota `deviceSwitches`.
  Stream<DeviceListSnapshot> watchDeviceList(String uid) {
    return _users.watchDevicesMeta(uid).asyncExpand((meta) {
      return watchDevices(uid).map(
        (devices) => DeviceRegistry.apply(
          devices,
          meta.plan,
          boundDeviceId: meta.boundDeviceId,
          switches: meta.switches,
        ),
      );
    });
  }

  Stream<GuardianDevice?> watchPrimaryDevice(String uid) {
    return watchDeviceList(uid).map((snapshot) => snapshot.primary);
  }
}
