import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/containment/domain/device_command.dart';

void main() {
  test('parseia tipo e status do comando', () {
    expect(DeviceCommandType.parse('close_oyster'), DeviceCommandType.closeOyster);
    expect(DeviceCommandType.parse('protect_app'), DeviceCommandType.protectApp);
    expect(DeviceCommandStatus.parse('pending'), DeviceCommandStatus.pending);
    expect(DeviceCommandStatus.parse('applied'), DeviceCommandStatus.applied);
  });
}
