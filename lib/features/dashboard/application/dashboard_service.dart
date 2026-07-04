import 'package:guardian_portal/features/devices/data/device_repository.dart';
import 'package:guardian_portal/features/devices/domain/guardian_device.dart';

/// Camada de aplicação do dashboard — orquestra leitura read-only do Firestore.
class DashboardService {
  DashboardService({DeviceRepository? devices})
      : _devices = devices ?? DeviceRepository();

  final DeviceRepository _devices;

  Stream<GuardianDevice?> watchPrimaryDevice(String uid) =>
      _devices.watchPrimaryDevice(uid);
}
