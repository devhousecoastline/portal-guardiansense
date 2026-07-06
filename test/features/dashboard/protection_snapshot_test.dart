import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_snapshot.dart';

void main() {
  test('evento recente usa resumo curto', () {
    final status = DeviceStatus(
      deviceId: 'd1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: DateTime.now().subtract(const Duration(minutes: 15)),
      lastEventSummary: 'ostra reaberta · usuário confirmou segurança',
      location: null,
      fingerprint: null,
      protectionSetupItems: const [],
    );

    final entries = ProtectionSnapshot.checklist(status);
    final event = entries.firstWhere(
      (e) => e.question.startsWith('Houve tentativa'),
    );

    expect(event.answer, contains('Ostra reaberta'));
    expect(event.answer, isNot(contains('usuário confirmou')));
  });
}
