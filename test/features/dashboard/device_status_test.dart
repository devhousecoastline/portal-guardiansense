import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_portal/app/constants.dart';
import 'package:guardian_portal/features/dashboard/domain/device_status.dart';
import 'package:guardian_portal/features/dashboard/domain/protection_setup_item.dart';

DeviceStatus _status({
  DateTime? lastSeen,
  int? presenceIntervalSec,
  List<ProtectionSetupItem> protectionSetupItems = const [],
}) {
  return DeviceStatus(
    deviceId: 'dev-1',
    modelLabel: 'Samsung',
    platform: 'android',
    appVersion: '1.0',
    lastSeen: lastSeen,
    presenceIntervalSec: presenceIntervalSec,
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
    final probe = _status();
    final status = _status(
      lastSeen: DateTime.now().subtract(
        probe.onlineThreshold + const Duration(seconds: 5),
      ),
    );
    expect(status.isOnline, isFalse);
    expect(status.level, ProtectionLevel.offline);
    expect(status.protectionIndex, 0);
  });

  group('presença adaptativa', () {
    final now = DateTime(2026, 11, 10, 12);

    DevicePresence presenceAfter(Duration elapsed, {int? intervalSec}) =>
        _status(
          lastSeen: now.subtract(elapsed),
          presenceIntervalSec: intervalSec,
        ).presenceAt(now);

    test('sem presenceIntervalSec usa 180s', () {
      expect(_status().presenceInterval, AppConstants.presenceIntervalFallback);
      expect(_status().presenceInterval, const Duration(seconds: 180));
      expect(
        _status(presenceIntervalSec: 0).presenceInterval,
        const Duration(seconds: 180),
      );
    });

    test('ostra aberta (600s): 25 min online, até 60 min stale', () {
      const open = 600;
      expect(
        presenceAfter(const Duration(minutes: 24, seconds: 59), intervalSec: open),
        DevicePresence.online,
      );
      expect(
        presenceAfter(const Duration(minutes: 25), intervalSec: open),
        DevicePresence.stale,
      );
      expect(
        presenceAfter(const Duration(minutes: 60), intervalSec: open),
        DevicePresence.stale,
      );
      expect(
        presenceAfter(const Duration(minutes: 60, seconds: 1), intervalSec: open),
        DevicePresence.offline,
      );
    });

    test('ostra fechada (180s): 7,5 min online, até 20 min stale', () {
      const closed = 180;
      expect(
        presenceAfter(const Duration(minutes: 7, seconds: 29), intervalSec: closed),
        DevicePresence.online,
      );
      expect(
        presenceAfter(const Duration(minutes: 7, seconds: 30), intervalSec: closed),
        DevicePresence.stale,
      );
      expect(
        presenceAfter(const Duration(minutes: 20), intervalSec: closed),
        DevicePresence.stale,
      );
      expect(
        presenceAfter(const Duration(minutes: 20, seconds: 1), intervalSec: closed),
        DevicePresence.offline,
      );
    });

    test('APK antigo segue a faixa de 180s', () {
      expect(
        presenceAfter(const Duration(minutes: 7)),
        DevicePresence.online,
      );
      expect(
        presenceAfter(const Duration(minutes: 10)),
        DevicePresence.stale,
      );
      expect(
        presenceAfter(const Duration(minutes: 21)),
        DevicePresence.offline,
      );
    });

    test('stale não conta como online e mostra última comunicação', () {
      final status = _status(
        lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
        presenceIntervalSec: 600,
      );
      expect(status.presence, DevicePresence.stale);
      expect(status.isOnline, isFalse);
      expect(status.presenceLabel, 'Última comunicação há 30 min');
      expect(status.protectionLabel, 'Sem sinal');
    });

    test('fromFirestore lê presenceIntervalSec', () {
      final status = DeviceStatus.fromFirestore('dev-1', {
        'lastSeen': DateTime.now(),
        'presenceIntervalSec': 600,
      });
      expect(status.presenceIntervalSec, 600);
      expect(status.onlineThreshold, const Duration(minutes: 25));
      expect(status.offlineThreshold, const Duration(minutes: 60));
    });
  });

  test('isLocationReady segue o item location do checklist', () {
    final on = _status(
      lastSeen: DateTime.now(),
      protectionSetupItems: const [
        ProtectionSetupItem(id: 'location', label: 'Localização', done: true),
      ],
    );
    final off = _status(
      lastSeen: DateTime.now(),
      protectionSetupItems: const [
        ProtectionSetupItem(id: 'location', label: 'Localização', done: false),
      ],
    );
    expect(on.isOnline, isTrue);
    expect(on.isLocationReady, isTrue);
    expect(off.isOnline, isTrue);
    expect(off.isLocationReady, isFalse);
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
