import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

DeviceStatus _status({
  DateTime? lastSeen,
  List<ProtectionSetupItem> protectionSetupItems = const [],
}) {
  return DeviceStatus(
    deviceId: 'dev-1',
    modelLabel: 'Samsung',
    platform: 'android',
    appVersion: '1.0',
    lastSeen: lastSeen,
    storedProtectionIndex: 100,
    runtimeActive: true,
    oysterClosed: false,
    batteryLevel: null,
    lastAlertAt: null,
    lastAlertSummary: null,
    lastEventAt: null,
    lastEventSummary: null,
    location: null,
    fingerprint: 'fp',
    protectionSetupItems: protectionSetupItems,
    protectedLayers: const [],
  );
}

void main() {
  test('isOnline é true dentro do limiar de lastSeen', () {
    final status = _status(
      lastSeen: DateTime.now().subtract(const Duration(seconds: 30)),
    );
    expect(status.isOnline, isTrue);
    expect(status.level, ProtectionLevel.protected);
  });

  test('isOnline é false após o limiar sem nova sync', () {
    final status = _status(
      lastSeen: DateTime.now().subtract(
        AppConstants.deviceOnlineThreshold + const Duration(seconds: 5),
      ),
    );
    expect(status.isOnline, isFalse);
    expect(status.level, ProtectionLevel.offline);
    expect(status.protectionIndex, 0);
  });

  test('isOnline é false sem lastSeen', () {
    expect(_status().isOnline, isFalse);
  });

  test('legado sem verified aparece como verificado', () {
    expect(_status().isVerified, isTrue);
    expect(_status().isQrVerified, isFalse);
  });

  test('verified false bloqueia o portal', () {
    final status = DeviceStatus(
      deviceId: 'dev-1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1.0',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: null,
      lastEventSummary: null,
      location: null,
      fingerprint: 'fp',
      protectionSetupItems: const [],
      protectedLayers: const [],
      verified: false,
    );
    expect(status.isVerified, isFalse);
  });

  test('QR confirmado é ativo e verificado', () {
    final status = DeviceStatus(
      deviceId: 'dev-1',
      modelLabel: 'Samsung',
      platform: 'android',
      appVersion: '1.0',
      lastSeen: DateTime.now(),
      storedProtectionIndex: 100,
      runtimeActive: true,
      oysterClosed: false,
      batteryLevel: null,
      lastAlertAt: null,
      lastAlertSummary: null,
      lastEventAt: null,
      lastEventSummary: null,
      location: null,
      fingerprint: 'fp',
      protectionSetupItems: const [],
      protectedLayers: const [],
      verified: true,
      verifiedAt: DateTime.now(),
      verifiedVia: 'qr',
    );
    expect(status.isVerified, isTrue);
    expect(status.isQrVerified, isTrue);
  });

  test('appVersionLabel junta versão e build', () {
    expect(_status().appVersionLabel, '1.0');
    expect(
      DeviceStatus(
        deviceId: 'dev-1',
        modelLabel: 'Samsung',
        platform: 'android',
        appVersion: '1.0.0',
        appBuild: '2',
        lastSeen: DateTime.now(),
        storedProtectionIndex: 100,
        runtimeActive: true,
        oysterClosed: false,
        batteryLevel: null,
        lastAlertAt: null,
        lastAlertSummary: null,
        lastEventAt: null,
        lastEventSummary: null,
        location: null,
        fingerprint: 'fp',
        protectionSetupItems: const [],
        protectedLayers: const [],
      ).appVersionLabel,
      '1.0.0+2',
    );
    expect(
      DeviceStatus.fromFirestore('dev-1', {
        'appVersion': '1.0.0',
        'appBuild': '2',
        'lastSeen': DateTime.now(),
      }).appVersionLabel,
      '1.0.0+2',
    );
  });

  test('hasRecoveryConfigured exige item recovery done', () {
    expect(_status().hasRecoveryConfigured, isFalse);

    expect(
      _status(
        protectionSetupItems: const [
          ProtectionSetupItem(
            id: 'recovery',
            label: 'Recuperação por biometria/PIN',
            done: false,
          ),
        ],
      ).hasRecoveryConfigured,
      isFalse,
    );

    expect(
      _status(
        protectionSetupItems: const [
          ProtectionSetupItem(
            id: 'recovery',
            label: 'Recuperação por biometria/PIN',
            done: true,
          ),
        ],
      ).hasRecoveryConfigured,
      isTrue,
    );
  });
}
